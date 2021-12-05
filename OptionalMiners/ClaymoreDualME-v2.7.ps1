using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\EthDcrMiner64.exe"
$Uri = "https://github.com/just-a-miner/moreepochs/releases/download/v2.7/MoreEpochs_Mod_of_Claymore_ETH_Miner_v15Win_by_JustAMiner_v2.7.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.006; MinMemGB = 5; Type = "AMD"; MinerSet = 1; Tuning = " -rxboost 1"; WarmupTimes = @(0, 30); Arguments = " -platform 1" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.006; MinMemGB = 2; Type = "AMD"; MinerSet = 1; Tuning = " -rxboost 1"; WarmupTimes = @(0, 20); Arguments = " -platform 1" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool

    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.006; MinMemGB = 5; Type = "NVIDIA"; MinerSet = 1; Tuning = " -strap 1"; WarmupTimes = @(0, 30); Arguments = " -platform 2" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.006; MinMemGB = 2; Type = "NVIDIA"; MinerSet = 1; Tuning = " -strap 1"; WarmupTimes = @(0, 20); Arguments = " -platform 2" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($Miner_Devices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

                $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

                If ($AvailableMiner_Devices = @($Miner_Devices | Where-Object { [Uint]($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                    # Get arguments for available miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                    If ($Pools.($_.Algorithm).DAGsize -ne $null -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$|^ProHashing.*$") { 
                        $_.Arguments += " -esm 3"
                        $Protocol = If ($Pools.($_.Algorithm).SSL) { "stratum+ssl://" } Else { "stratum+tcp://" }
                    }
                    Else { 
                        $Protocol = If ($Pools.($_.Algorithm).SSL) { "ssl://" } Else { "" }
                    }
                    If ($Pools.($_.Algorithm).SSL) { $_.Arguments += " -checkcert 0" }

                    # Optionally disable dev fee mining
                    # If ($Config.DisableMinerFee) { 
                    #     $_.Arguments += " -nofee 1"
                    #     $_.Fee = 0
                    # }

                    $Pass = "$($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).Name -match "^ProHashing.*$" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum -$DAGmemReserve) / 1GB)" })"

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $AvailableMiner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("-epool $Protocol$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -ewal $($Pools.($_.Algorithm).User) -epsw $Pass$($_.Arguments) -dbg -1 -wd 0 -retrydelay 3 -allpools 1 -allcoins 1 -mport -$MinerAPIPort -di $(($AvailableMiner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "EthMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee # Dev fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
