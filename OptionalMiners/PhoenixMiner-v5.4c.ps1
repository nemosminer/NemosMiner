using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/PhoenixMiner/PhoenixMiner_5.4c_Windows.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = 3.9; Command = " -amd -eres 1 -mi 12 -coin ETC" }
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "AMD"; Fee = @(0.0065);   MinMemGB = 3.9; Command = " -amd -eres 1 -mi 12" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 3.9; Command = " -amd -eres 1 -mi 12 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 3.9; Command = " -amd -eres 1 -mi 12 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = 3.9; Command = " -amd -eres 1 -mi 12 -coin ubq" }

    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 4.0; Command = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -coin ETC" }
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 4.0; Command = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15" }
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 4.0; Command = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 4.0; Command = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 4.0; Command = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -coin ubq" }
)

If ($Commands = $Commands | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    # Intensities for 2. algorithm
    $Intensities = [PSCustomObject]@{ 
        "Blake2s" = @($null, 10, 20, 30, 40) # $null is for auto-tuning
    }

    # Build command sets for intensities
    $Commands = $Commands | ForEach-Object { 
        $_.PsObject.Copy()
        ForEach ($Intensity in $Intensities.($_.Algorithm[1])) { 
            $_ | Add-Member Intensity $Intensity -Force
            $_.PsObject.Copy()
        }
    }

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $Command = $_.Command
                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm[0] -in @("EtcHash", "Ethash")) { 
                    $MinMemGB = ($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) / 1GB
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 
                    If ($_.Algorithm[1] -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$')) { Return } # Dual mining not supported on Navi

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-'

                    # Get commands for active miner devices
                    # $Command = Get-CommandPerDevice -Command $Command -ExcludeParameters @("amd", "eres", "nvidia") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Command += " -pool $(If ($Pools.($_.Algorithm[0]).SSL) { "ssl://" })$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -wal $($Pools.($_.Algorithm[0]).User) -pass $($Pools.($_.Algorithm[0]).Pass)"
                    If ($_.Algorithm[0] -in @("EtcHash", "Ethash")) {
                        If ($Pools.($_.Algorithm[0]).Name -match "^NiceHash$|^MPH(|Coins)$") { 
                            $Command += " -proto 4"
                        }
                    }

                    If ($Miner_Devices.Vendor -eq "AMD") { 
                        If (($_.OpenCL.GlobalMemSize / 1GB) -ge (2 * $MinMemGB)) { 
                            # Faster AMD "turbo" kernels require twice as much VRAM
                            $Command += " -clkernel 3"
                        }
                        If (($Miner_Devices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$') { 
                            # Extra Speed for Navi cards
                            # $Command += " -openclLocalWork 128 -openclGlobalMultiplier 4096" # Does not work, lots of bad shares :-(
                        }
                        If (($Miner_Devices.OpenCL.CodeName | Sort-Object -unique) -join '' -eq 'Ellesmere') { 
                            # Extra Speed for Ellesmere cards
                            # $Command += " -openclLocalWork 128 -openclGlobalMultiplier 4096" # Does not work, lots of bad shares :-(
                        }
                    }

                    If ($_.Algorithm[1]) { 
                        $Command += " -dpool $(If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { "ssl://" })$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) -dwal $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) -dpass $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass) -sci $([Int]$_.Intensity)"
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$Command -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator + 1) }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API        = "EthMiner"
                        Port       = $MinerAPIPort
                        Wrap       = $false
                        URI        = $Uri
                        Fee        = $_.Fee # Dev fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                        WarmupTime = If ($Pools.($_.Algorithm[0]).Name -match "^MPH*") { 30 } Else { 0 } # Seconds, longer for MPH because of long connect issue
                    }
                }
            }
        }
    }
}
