using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/PhoenixMiner/PhoenixMiner_5.1c.zip"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.0065);   MinMemGB = 3.9; WarmupTime = 45; Type = "AMD"; Command = " -amd -eres 1 -mi 12" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.009, 0); MinMemGB = 3.9; WarmupTime = 60; Type = "AMD"; Command = " -amd -eres 1 -mi 12 -dcoin blake2s" }

    [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.0065);   MinMemGB = 4;   WarmupTime = 45; Type = "NVIDIA"; Command = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.009, 0); MinMemGB = 4;   WarmupTime = 60; Type = "NVIDIA"; Command = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -dcoin blake2s" }
    # [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.0065);   MinMemGB = 4;   WarmupTime = 45; Type = "NVIDIA"; Command = " -nvidia -eres 1 -mi 12 -vmt1 20 -vmt2 16 -vmt3 0 -vmr 25" }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.009, 0); MinMemGB = 4;   WarmupTime = 60; Type = "NVIDIA"; Command = " -nvidia -eres 1 -mi 12 -vmt1 20 -vmt2 16 -vmt3 0 -vmr 25 -dcoin blake2s" }
)

If ($Commands = $Commands | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

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

                $Command = $_.Command
                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 
                    If ($_.Algorithm[1] -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$|^GTX1660.*GB$')) { Return } #Dual mining not supported on Navi or GTX 1660

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($_.Algorithm[1]) + @($_.Intensity2) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$Command = Get-CommandPerDevice -Command $Command -ExcludeParameters @("amd", "eres", "nvidia") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Command += " -pool $(If ($Pools.($_.Algorithm[0]).SSL) { "ssl://" })$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -wal $($Pools.($_.Algorithm[0]).User) -pass $($Pools.($_.Algorithm[0]).Pass)"
                    If ($_.Algorithm[0] -like "Ethash*") {
                        If ($Pools.($_.Algorithm[0]).Name -match "^NiceHash*|^MPH*") { 
                            $Command += " -proto 4"
                        }
                    }

                    If ($Miner_Devices.Vendor -eq "AMD") { 
                        If (($_.OpenCL.GlobalMemSize / 1GB) -ge (2 * $MinMemGB)) { 
                            #Faster AMD "turbo" kernels require twice as much VRAM
                            $Command += " -clkernel 3"
                        }
                        If (($Miner_Devices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$') { 
                            #Extra Speed for Navi cards
                            # $Command += " -openclLocalWork 128 -openclGlobalMultiplier 4096" #Does not work, lots of bad shares :-(
                        }
                        If (($Miner_Devices.OpenCL.CodeName | Sort-Object -unique) -join '' -eq 'Ellesmere') { 
                            #Extra Speed for Ellesmere cards
                            #$Command += " -openclLocalWork 128 -openclGlobalMultiplier 4096" #Does not work, lot's of bad shares :-(
                        }
                    }

                    If ($_.Algorithm[1]) { 
                        $Command += " -dpool $(If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { "ssl://" })$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) -dwal $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) -dpass $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass) -sci $([Int]$_.Intensity2)"
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$Command -log 0 -wdog 0 -mport $MinerAPIPort -gpus $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator + 1) }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API        = "EthMiner"
                        Port       = $MinerAPIPort
                        Wrap       = $false
                        URI        = $Uri
                        Fee        = $_.Fee # Dev fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                        WarmupTime = 60 #Seconds
                    }
                }
            }
        }
    }
}
