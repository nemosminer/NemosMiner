using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/PhoenixMiner/PhoenixMiner_5.1c.zip"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.0065);   MinMemGB = 4;   WarmupTime = 45; Type = "AMD"; Command = " -amd -eres 1 -mi 12" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.009, 0); MinMemGB = 4;   WarmupTime = 60; Type = "AMD"; Command = " -dcoin blake2s -amd -eres 1 -mi 12" }
    [PSCustomObject]@{ Algorithm = @("ProgPoW");           Fee = @(0.009);    MinMemGB = 2.4; WarmupTime = 45; Type = "AMD"; Command = " -amd -eres 1 -mi 12" }
#   [PSCustomObject]@{ Algorithm = @("BitcoinInterest");   Fee = @(0.009);    MinMemGB = 2;   WarmupTime = 45; Type = "AMD"; Command = " -coin BCI -amd -eres 1 -mi 12" } #Does not work

    [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.0065);   MinMemGB = 4;   WarmupTime = 45; Type = "NVIDIA"; Command = " -nvidia -eres 1 -mi 12 -vmt1 20 -vmt2 16 -vmt3 0 -vmr 25" } #-straps 4"
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.009);    MinMemGB = 4;   WarmupTime = 60; Type = "NVIDIA"; Command = " -dcoin blake2s -nvidia -eres 1 -mi 12 -vmt1 20 -vmt2 16 -vmt3 0 -vmr 25" } #-straps 4"
    [PSCustomObject]@{ Algorithm = @("ProgPoW");           Fee = @(0.009);    MinMemGB = 2.4; WarmupTime = 45; Type = "NVIDIA"; Command = " -nvidia -eres 1 -mi 12 -vmt1 20 -vmt2 16 -vmt3 0 -vmr 25" } #-straps 4"
)

If ($Commands = $Commands | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($PoolsSecondaryAlgorithm.($_.Algorithm[0]).Host -and $Pools.($_.Algorithm[1]).Host) }) { 

    #Intensities for 2. algorithm
    $Intensities2 = [PSCustomObject]@{ 
        "Blake2s" = @($null, 10, 20, 30, 40) #$null is for auto-tuning
    }

    # Build command sets for intensities
    $Commands = $Commands | ForEach-Object { 
        $Command = $_ 
        If ($_.Algorithm[1]) { 
            $Intensities2.($_.Algorithm[1]) | ForEach-Object { 
                $Command | Add-Member Intensity2 $_ -Force
                $Command | ConvertTo-Json | ConvertFrom-Json
            }
        }
        Else { 
            $Command
        }
    }

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($_.Algorithm[1]) + @($_.Intensity2) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("amd", "eres", "nvidia") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $_.Command += " -pool $(If ($Pools.($_.Algorithm[0]).SSL) { "ssl://" })$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -wal $($Pools.($_.Algorithm[0]).User) -pass $($Pools.($_.Algorithm[0]).Pass)"
                    If ($_.Algorithm[0] -like "Ethash*") {
                        If ($Pools.($_.Algorithm[0]).Name -like "NiceHash*" -or $Pools.($_.Algorithm[0]).Name -like "MPH*") { 
                            $_.Command += " -proto 4"
                        }
                    } 

                    If ($Miner_Devices.Vendor -eq "AMD" -and (($_.OpenCL.GlobalMemSize / 1GB) -ge (2 * $MinMemGB))) { 
                        #Faster AMD "turbo" kernels require twice as much VRAM
                        $_.Command += " -clkernel 3"
                    }

                    If ($_.Algorithm[1]) { 
                        $_.Command += " -dpool $(If ($Pools.($_.Algorithm[1]).SSL) { "ssl://" })$($Pools.($_.Algorithm[1]).Host):$($Pools.($_.Algorithm[1]).Port) -dwal $($Pools.($_.Algorithm[1]).User) -dpass $($Pools.($_.Algorithm[1]).Pass)"

                        If ($_.Intensity2 -eq $null) { 
                            $_.Command += " -gt 0" #Enable auto-tuning
                        }
                        Else { 
                            $_.Command += " -sci $($_.Intensity2)"
                        }
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$($_.Command) -log 0 -wdog 0 -mport $($MinerAPIPort) -gpus $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator + 1) }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API        = "EthMiner"
                        Port       = $MinerAPIPort
                        Wrap       = $false
                        URI        = $Uri
                        Fee        = $_.Fee # Dev fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
