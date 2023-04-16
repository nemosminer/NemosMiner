If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0" })) { Return }

$Uri = "https://github.com/todxx/teamredminer/releases/download/v0.10.9/teamredminer-v0.10.9-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\teamredminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Fee = @(0.025); MinMemGiB = $MinerPools[0].Autolykos2.DAGSizeGiB + 0.77;   Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2");                            Arguments = " --algo=autolykos2" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "kHeavyHash");   Fee = @(0.025); MinMemGiB = $MinerPools[0].Autolykos2.DAGSizeGiB + 0.77;   Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2");                            Arguments = " --algo=autolykos2" }
    [PSCustomObject]@{ Algorithms = @("Chukwa");                     Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=trtl_chukwa" }
    [PSCustomObject]@{ Algorithms = @("Chukwa2");                    Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=trtl_chukwa2" }
    [PSCustomObject]@{ Algorithms = @("CryptonightCcx");             Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_conceal --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # SRBMinerMulti-v2.2.4 is fastest
    [PSCustomObject]@{ Algorithms = @("CryptonightHeavy");           Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_heavy --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightHaven");           Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_haven --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightHeavyTube");       Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_saber --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
#   [PSCustomObject]@{ Algorithms = @("CryptonightR");               Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 3; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnr --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # ASIC
    [PSCustomObject]@{ Algorithms = @("CryptonightV1");              Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightDouble");          Fee = @(0.025); MinMemGiB = 4.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_dbl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # XmRig-v6.18.1 is fastest
    [PSCustomObject]@{ Algorithms = @("CryptonightHalf");            Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_half --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightTurtle");          Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_trtl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightRwz");             Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_rwz --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightUpx");             Fee = @(0.025); MinMemGiB = 3.0;                                           Minerset = 1; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_upx2 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CuckarooD29");                Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cuckarood29_grin" } # 2GB is not enough
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo31");                 Fee = @(0.025); MinMemGiB = 3.0;                                           Minerset = 3; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cuckatoo31_grin" } # ASIC
    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Fee = @(0.01);  MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 0.77;      Minerset = 1; WarmupTimes = @(45, 65);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2");                            Arguments = " --algo=etchash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithms = @("Ethash");                     Fee = @(0.01);  MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.77;       MinerSet = 0; WarmupTimes = @(60, 65);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2");                            Arguments = " --algo=ethash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Fee = @(0.01);  MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.77;       Minerset = 2; WarmupTimes = @(60, 65);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2");                            Arguments = " --algo=ethash" } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");               Fee = @(0.01);  MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.77; Minerset = 2; WarmupTimes = @(45, 65);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2");                            Arguments = " --algo=ethash" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "kHeavyHash"); Fee = @(0.01);  MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.77; Minerset = 2; WarmupTimes = @(45, 65);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2");                            Arguments = " --algo=ethash" }
    [PSCustomObject]@{ Algorithms = @("FiroPow");                    Fee = @(0.02);  MinMemGiB = $MinerPools[0].FiroPow.DAGSizeGiB + 0.77;      MinerSet = 0; WarmupTimes = @(60, 65);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA3");                   Arguments = " --algo=firopow" } # Wildrig-v0.36.6bis fastest on Polaris
    [PSCustomObject]@{ Algorithms = @("KawPow");                     Fee = @(0.02);  MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.77;       MinerSet = 0; WarmupTimes = @(60, 65);  ExcludePools = @(@("MiningPoolHub"), @()); ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA3");                   Arguments = " --algo=kawpow" } # Wildrig-v0.36.6bis fastest on Polaris
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Fee = @(0.01);  MinMemGiB = 2.0;                                           MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2");                            Arguments = " --algo=kas" }
#   [PSCustomObject]@{ Algorithms = @("Lyra2Z");                     Fee = @(0.03);  MinMemGiB = 2.0;                                           MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=lyra2z" } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Lyra2RE3");                   Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=lyra2rev3" } # ASIC
    [PSCustomObject]@{ Algorithms = @("MTP");                        Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(45, 45);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA3");                   Arguments = " --algo=mtp" } # Algorithm is dead
    [PSCustomObject]@{ Algorithms = @("Nimiq");                      Fee = @(0.025); MinMemGiB = 4.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA3");                   Arguments = " --algo=nimiq" }
    [PSCustomObject]@{ Algorithms = @("Phi2");                       Fee = @(0.03);  MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=phi2" }
    [PSCustomObject]@{ Algorithms = @("VertHash");                   Fee = @(0.025); MinMemGiB = 4.0;                                           Minerset = 1; WarmupTimes = @(75, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA3");                   Arguments = " --algo=verthash --verthash_file=..\.$($Variables.VerthashDatPath)" }
#   [PSCustomObject]@{ Algorithms = @("X16r");                       Fee = @(0.025); MinMemGiB = 4.0;                                           Minerset = 3; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16r" } # ASIC
    [PSCustomObject]@{ Algorithms = @("X16rv2");                     Fee = @(0.025); MinMemGiB = 4.0;                                           MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16rv2" }
    [PSCustomObject]@{ Algorithms = @("X16s");                       Fee = @(0.025); MinMemGiB = 2.0;                                           Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16s" }
    [PSCustomObject]@{ Algorithms = @("X16rt");                      Fee = @(0.025); MinMemGiB = 2.0;                                           MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("CGN1", "CGN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16rt" } # FPGA
) 

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).BaseName -notin $_.ExcludePools[0] -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).BaseName -notin $_.ExcludePools[1]) }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Algorithm0 = $_.Algorithms[0]
                $Algorithm1 = $_.Algorithms[1]
                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)$(If ($Algorithm1) { "-$($Algorithm0)&$($Algorithm1)" })" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "autotune", "rig_id") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --pool_force_ensub --url=$(If ($MinerPools[0].$Algorithm0.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($MinerPools[0].$Algorithm0.Host):$($MinerPools[0].$Algorithm0.PoolPorts | Select-Object -Last 1)"
                $Arguments += Switch ($MinerPools[0].$Algorithm0.Protocol) { 
                    "ethstratumnh" { " --eth_stratum_mode=nicehash" }
                }
                $Arguments += " --user=$($MinerPools[0].$Algorithm0.User)$(If ($MinerPools[0].$Algorithm0.WorkerName) { ".$($MinerPools[0].$Algorithm0.WorkerName)" })"
                $Arguments += " --pass=$($MinerPools[0].$Algorithm0.Pass)$(If ($MinerPools[0].$Algorithm0.BaseName -eq "ProHashing" -and $Algorithm0 -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].$Algorithm0.DAGSizeGiB))" })"

                If ($Algorithm1 -eq "kHeavyHash") { 
                    $Arguments += " --kas" 
                    $Arguments += " --url=$(If ($MinerPools[1].$Algorithm1.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($MinerPools[1].$Algorithm1.Host):$($MinerPools[1].$Algorithm1.PoolPorts | Select-Object -Last 1)"
                    $Arguments += " --user=$($MinerPools[1].$Algorithm1.User)$(If ($MinerPools[1].$Algorithm1.WorkerName) { ".$($MinerPools[1].$Algorithm1.WorkerName)" })"
                    $Arguments += " --pass=$($MinerPools[1].$Algorithm1.Pass)"
                    $Arguments += " --kas_end"
                }

                If ($Algorithm0 -match "^Et(c)hash.+" -and $AvailableMiner_Devices.Model -notmatch "^Radeon RX [0-9]{3} ") { $_.Fee = @(0.0075) } # Polaris cards 0.75%

                If ($Algorithm1 -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath).length -ne 1283457024) { 
                    $PrerequisitePath = $Variables.VerthashDatPath
                    $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                }
                Else { 
                    $PrerequisitePath = ""
                    $PrerequisiteURI = ""
                }

                [PSCustomObject]@{ 
                    Algorithms       = @($_.Algorithms | Select-Object)
                    API              = "Xgminer"
                    Arguments        = ("$($Arguments) --watchdog_script --no_gpu_monitor --init_style=3 --hardware=gpu --platform=$($AvailableMiner_Devices.PlatformId | Sort-Object -Unique) --api_listen=127.0.0.1:$MinerAPIPort --devices=$(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Fee              = $_.Fee
                    MinerSet         = $_.MinerSet
                    Name             = $Miner_Name
                    Path             = $Path
                    Port             = $MinerAPIPort
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                    Type             = "AMD"
                    URI              = $Uri
                    WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}