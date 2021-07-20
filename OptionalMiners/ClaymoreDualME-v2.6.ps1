using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\EthDcrMiner64.exe"
$Uri = "https://github.com/just-a-miner/moreepochs/releases/download/v2.6/MoreEpochs_Mod_of_Claymore_ETH_Miner_v15Win_by_JustAMiner_v2.6.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.006; MinMemGB = 5; Type = "AMD"; MinerSet = 1; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -platform 1" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.006; MinMemGB = 2; Type = "AMD"; MinerSet = 1; Tuning = " -rxboost 1"; WarmupTimes = @(0, 20); Arguments = " -platform 1" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool

    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.006; MinMemGB = 5; Type = "NVIDIA"; MinerSet = 1; Tuning = " -strap 1"; WarmupTimes = @(0, 30); Arguments = " -platform 2" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.006; MinMemGB = 2; Type = "NVIDIA"; MinerSet = 1; Tuning = " -strap 1"; WarmupTimes = @(0, 20); Arguments = " -platform 2" } # PhoenixMiner-v5.6d may be faster, but I see lower speed at the pool
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $Arguments = $_.Arguments
                $WarmupTimes = $_.WarmupTimes
                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { $MinMemGB = ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB }

                $Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })

                If ($Miner_Devices) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($Pools.($_.Algorithm).SSL) {
                        $Arguments += " -checkcert 0"
                        If ($Pools.($_.Algorithm).DAGsize -ne $null -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$|^ProHashing.*$") { 
                            $Arguments += " -esm 3"
                            $Protocol = "stratum+ssl://"
                        }
                        Else { 
                            $Protocol = "ssl://"
                        }
                    }
                    Else { 
                        If ($Pools.($_.Algorithm).DAGsize -ne $null -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$|^ProHashing.*$") { 
                            $Arguments += " -esm 3"
                            $Protocol = "stratum+tcp://"
                        }
                        Else { 
                            $Protocol = ""
                        }
                    }

                    # Optionally disable dev fee mining
                    If ($Config.DisableMinerFee) { 
                        $Arguments += " -nofee 1"
                        $_.Fee = 0
                    }

                    $Pass = $($Pools.($_.Algorithm).Pass)
                    If ($Pools.($_.Algorithm).Name -match "^ProHashing.*$" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$((($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum -$DAGmemReserve) / 1GB)" }

                    If (-not $_.Intensity) { $WarmupTimes[0] += 15; $WarmupTimes[1] += 15 } # Allow extra seconds for auto-tuning

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("-epool $Protocol$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -ewal $($Pools.($_.Algorithm).User) -epsw $Pass$Arguments -dbg -1 -wd 0 -allpools 1 -allcoins 1 -mport -$MinerAPIPort -di $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "EthMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee # Dev fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes = $WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
