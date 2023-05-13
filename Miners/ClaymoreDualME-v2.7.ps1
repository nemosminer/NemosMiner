If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $Variables.DriverVersion.CIM.AMD -le "20.45.01.28") -or $_.Type -eq "NVIDIA" })) { Return } # Only supports AMD drivers until 20.12.1

$Uri = "https://github.com/just-a-miner/moreepochs/releases/download/v2.7/MoreEpochs_Mod_of_Claymore_ETH_Miner_v15Win_by_JustAMiner_v2.7.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\EthDcrMiner64.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; Fee = 0.006; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.77;       Minerset = 2; Tuning = " -rxboost 1"; WarmupTimes = @(45, 0); Arguments = " -platform 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; Fee = 0.006; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.77; Minerset = 2; Tuning = " -rxboost 1"; WarmupTimes = @(45, 0); Arguments = " -platform 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool

    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.006; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.77;       Minerset = 2; Tuning = " -strap 1"; WarmupTimes = @(45, 0); Arguments = " -platform 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.006; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.77; Minerset = 2; Tuning = " -strap 1"; WarmupTimes = @(45, 0); Arguments = " -platform 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += Switch ($MinerPools[0].($_.Algorithm).Protocol) { 
                    "ethproxy"     { " -esm 1" }
                    "ethstratum"   { " -esm 0" }
                    "ethstratum1"  { " -esm 4" }
                    "ethstratum2"  { " -esm 4" }
                    "ethstratumnh" { " -esm 4" }
                    Default        { " -esm 0" }
                }
                $Arguments += If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { " -epool stratum+ssl" } Else { " -epool stratum+tcp" }
                $Arguments += "://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) -ewal $($MinerPools[0].($_.Algorithm).User)"
                $Arguments += " -epsw $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].($_.Algorithm).DAGSizeGiB))" })"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " -eworker $($MinerPools[0].($_.Algorithm).WorkerName)" }
                If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { $Arguments += " -checkcert 0" }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Arguments   = ("$($Arguments) -dbg -1 -wd 0 -retrydelay 3 -allpools 1 -allcoins 1 -mport -$MinerAPIPort -di $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee # Dev fee
                    MinerSet     = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = $_.Type
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}