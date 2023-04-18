If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/rigelminer/rigel/releases/download/1.4.1/rigel-1.4.1-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\Rigel.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Blake3");                     Fee = @(0.007); MinMemGiB = 2.0;                                           Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm alephium" }
    [PSCustomObject]@{ Algorithms = @("Blake3IronFish");             Fee = @(0.007); MinMemGiB = 2.0;                                           Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ironfish" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Fee = @(0.007); MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 0.77;      Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Fee = @(0.007); MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB+ 0.41;       Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash+kheavyhash" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                     Fee = @(0.007); MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.77;       Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(55, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Fee = @(0.007); MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.77;       Tuning = " --mt2"; Minerset = 2; WarmupTimes = @(55, 25); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash+kheavyhash" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");               Fee = @(0.007); MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.77; Tuning = " --mt2"; Minerset = 2; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "kHeavyHash"); Fee = @(0.007); MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.77; Tuning = " --mt2"; Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash+kheavyhash" }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Fee = @(0.007); MinMemGiB = 2.0;                                           Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm kheavyhash" }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                    Fee = @(0.02);  MinMemGiB = 3.0;                                           Tuning = " --mt2"; Minerset = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm nexapow" }
    [PSCustomObject]@{ Algorithms = @("OctaSpace");                  Fee = @(0.02);  MinMemGiB = 3.0;                                           Tuning = " --mt2"; Minerset = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm octa" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).BaseName -notin $_.ExcludePools[0] -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).BaseName -notin $_.ExcludePools[1]) }

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            # Windows 10 requires more memory on some algos
            # If ($_.Algorithms[0] -match "Cuckaroo.*|Cuckoo.*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $_.MinMemGiB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "cuda", "opencl", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Index = 0
                ForEach ($Algorithm in $_.Algorithms) { 
                    $Arguments += Switch ($MinerPools[$Index].$Algorithm.Protocol) { 
                        "ethproxy"     { " --url [$($Index + 1)]ethproxy"; Break }
                        "ethstratum1"  { " --url [$($Index + 1)]ethstratum"; Break }
                        "ethstratum2"  { " --url [$($Index + 1)]stratum"; Break }
                        "ethstratumnh" { " --url [$($Index + 1)]ethstratum"; Break }
                        Default        { " --url [$($Index + 1)]stratum" }
                    }
                    $Arguments += If ($MinerPools[$Index].$Algorithm.PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                    $Arguments += "$($MinerPools[$Index].$Algorithm.Host):$($MinerPools[$Index].$Algorithm.PoolPorts | Select-Object -Last 1)"
                    $Arguments += " --username [$($Index + 1)]$($MinerPools[$Index].$Algorithm.User)"
                    $Arguments += " --password [$($Index + 1)]$($MinerPools[$Index].$Algorithm.Pass)$(If ($MinerPools[$Index].$Algorithm.BaseName -eq "ProHashing" -and $_.Algorithms[$Index] -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[$Index].$Algorithm.DAGSizeGiB))" })"
                    If ($MinerPools[$Index].$Algorithm.WorkerName) { $Arguments += " --worker [$($Index + 1)]$($MinerPools[$Index].$Algorithm.WorkerName)" }
                    $Index ++
                }
                Remove-Variable Algorithm
                $Arguments += If ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1] -or ($_.Algorithms[1] -and $MinerPools[1].($_.Algorithms[1]).PoolPorts[1])) { " --no-strict-ssl" } # Parameter cannot be used multiple times

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithms | Select-Object)
                    API         = "Rigel"
                    Arguments   = ("$($Arguments) --api-bind 127.0.0.1:$($MinerAPIPort) --no-watchdog --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Fee         = $_.Fee
                    DeviceNames = $AvailableMiner_Devices.Name
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "NVIDIA"
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}