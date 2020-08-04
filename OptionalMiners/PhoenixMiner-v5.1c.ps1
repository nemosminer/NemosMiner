using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/PhoenixMiner/PhoenixMiner_5.1c.zip"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Ethash", $null);          Fee = @(0.0065);   MinMemGB = 4;   WarmupTime = 45; Type = "AMD";    Command = " -amd -eres 1 -mi 12" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");      Fee = @(0.009, 0); MinMemGB = 2.4; WarmupTime = 60; Type = "AMD";    Command = " -amd -eres 1 -mi 12" }
    [PSCustomObject]@{ Algorithm = @("ProgPoW", $null);         Fee = @(0.009, 0); MinMemGB = 2.4; WarmupTime = 45; Type = "AMD";    Command = " -amd -eres 1 -mi 12" }
#   [PSCustomObject]@{ Algorithm = @("BitcoinInterest", $null); Fee = @(0.009, 0); MinMemGB = 2;   WarmupTime = 45; Type = "AMD";    Command = " -coin BCI -amd -eres 1 -mi 12" } #Profit very small

    [PSCustomObject]@{ Algorithm = @("Ethash", $null);          Fee = @(0.0065);   MinMemGB = 4;   WarmupTime = 45; Type = "NVIDIA"; Command = " -nvidia -eres 1 -mi 12 -straps 4" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");      Fee = @(0.009, 0); MinMemGB = 2.4; WarmupTime = 60; Type = "NVIDIA"; Command = " -nvidia -eres 1 -mi 12 -straps 4" }
    [PSCustomObject]@{ Algorithm = @("ProgPoW", $null);         Fee = @(0.009, 0); MinMemGB = 2.4; WarmupTime = 45; Type = "NVIDIA"; Command = " -nvidia -eres 1 -mi 12 -straps 4" }
)

$Intensities2 = [PSCustomObject]@{ 
    "Blake2s" = @($null, 30, 60, 90, 120) # $null is for auto-tuning
}

# Build command sets for intensities
$Commands = $Commands | ForEach-Object { 
    $Command = $_ 
    If ($_.Algorithm | Select-Object -Index 1) { 
        $Intensities2.($_.Algorithm | Select-Object -Index 1) | Select-Object | ForEach-Object { 
            $Command | Add-Member Intensity2 ([Uint16]$_) -Force
            $Command | ConvertTo-Json | ConvertFrom-Json
        }
    }
    Else { 
        $Command
    }
}

$Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object Type -eq $_.Type | ForEach-Object { $Algo = $_.Algorithm | Select-Object -Index 0; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
            $MinMemGB = $_.MinMemGB

            If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("amd", "eres", "nvidia") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                $_.Command += " -pool $(If ($Pools.$Algo.SSL) { "ssl://" })$($Pools.$Algo.Host):$($Pools.$Algo.Port) -wal $($Pools.$Algo.User) -pass $($Pools.$Algo.Pass)"
                If ($Algo -like "Ethash*") {
                    If ($Pools.$Algo.Name -like "ZergPool*") { Return }
                    If ($Pools.$Algo.Name -like "NiceHash*" -or $Pools.$Algo.Name -like "MPH*") { 
                        $_.Command += " -proto 4"
                    }
                } 

                If ($Miner_Devices.Vendor -eq "AMD" -and ([math]::Round((10 * ($s.OpenCL | Measure-Object GlobalMemSize -Minimum).Minimum / 1GB), 0) / 10) -ge (2 * $MinMemGB)) { 
                    #Faster AMD "turbo" kernels require twice as much VRAM
                    $_.Command += " -clkernel 3"
                }

                If ($Algo2 = $_.Algorithm | Select-Object -Index 1) { 
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($Algo2) + @($_.Intensity2) | Select-Object) -join '-'
                    $_.Command += " -dcoin $($Algo2.toLower()) -dpool $(If ($Pools.$Algo2.SSL) { "ssl://" })$($Pools.$Algo2.Host):$($Pools.$Algo2.Port) -dwal $($Pools.$Algo2.User) -dpass $($Pools.$Algo2.Pass)"

                    If ($_.Intensity2 -eq $null) { 
                        $_.Command += " -gt 0" #Enable auto-tuning
                    }
                    Else { 
                        $_.Command += " -sci $($_.Intensity2)"
                    }
                }
                Else {
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'
                }

                If ($null -eq ($_.Algorithm | Select-Object -Index 1) -or $Pools.$Algo2.Host) { 

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$($_.Command) -log 0 -wdog 0 -mport $($MinerAPIPort) -gpus $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator + 1) }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($Algo, $Algo2) | Select-Object
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
