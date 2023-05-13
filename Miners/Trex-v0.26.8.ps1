If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.26.8/t-rex-0.26.8-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\t-rex.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");           Fee = @(0.02);       MinMemGiB = $MinerPools[0].Autolykos2.DAGSizeGiB + 1.08;   MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(45, 0);   Arguments = " --algo autolykos2 --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("Blake3");               Fee = @(0.01);       MinMemGiB = 2;                                             Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(45, 0);   Arguments = " --algo blake3 --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");              Fee = @(0.01);       MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 1.08;      Minerset = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 5);   Arguments = " --algo etchash --intensity 25" } # GMiner-v3.40 is fastest
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");    Fee = @(0.01, 0.01); MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + 1.08;      Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo etchash --dual-algo blake3 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash");               Fee = @(0.01);       MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.08;       Minerset = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --intensity 25" } # GMiner-v3.40 is fastest
    [PSCustomObject]@{ Algorithms = @("Ethash", "Autolykos2"); Fee = @(0.01, 0.02); MinMemGiB = 8;                                             Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --dual-algo autolykos2 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");     Fee = @(0.01, 0.01); MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.08;       Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --dual-algo blake3 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "FiroPow");    Fee = @(0.01, 0.01); MinMemGiB = 10;                                            Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(255, 15); Arguments = " --algo ethash --dual-algo firopow --lhr-tune -1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");     Fee = @(0.01, 0.01); MinMemGiB = 10;                                            Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(255, 15); Arguments = " --algo ethash --dual-algo kawpow --lhr-tune -1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Octopus");    Fee = @(0.01, 0.02); MinMemGiB = 8;                                             Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --dual-algo octopus --lhr-tune -1" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");         Fee = @(0.01);       MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 1.08; Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --intensity 25" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithms = @("FiroPow");              Fee = @(0.01);       MinMemGiB = $MinerPools[0].FiroPow.DAGSizeGiB + 1.08;      Minerset = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 30);  Arguments = " --algo firopow --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("KawPow");               Fee = @(0.01);       MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 1.08;       Minerset = 1; Tuning = " --mt 3"; WarmupTimes = @(45, 20);  Arguments = " --algo kawpow --intensity 25" } # XmRig-v6.18.1 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithms = @("MTP");                  Fee = @(0.01);       MinMemGiB = 3;                                             Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo mtp --intensity 21" } # Algorithm is dead
    [PSCustomObject]@{ Algorithms = @("MTPTcr");               Fee = @(0.01);       MinMemGiB = 3;                                             Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo mtp-tcr --intensity 21" }
    [PSCustomObject]@{ Algorithms = @("Multi");                Fee = @(0.01);       MinMemGiB = 2;                                             Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo multi --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("Octopus");              Fee = @(0.02);       MinMemGiB = $MinerPools[0].Octopus.DAGSizeGiB + 1.08;      Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo octopus" } # 6GB is not enough
    [PSCustomObject]@{ Algorithms = @("ProgPowSero");          Fee = @(0.01);       MinMemGiB = $MinerPools[0].ProgPowSero.DAGSizeGiB + 1.08;  Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo progpow --coin sero" }
    [PSCustomObject]@{ Algorithms = @("ProgPowVeil");          Fee = @(0.01);       MinMemGiB = $MinerPools[0].ProgPowVeil.DAGSizeGiB + 1.08;  Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo progpow-veil --intensity 24" }
    [PSCustomObject]@{ Algorithms = @("ProgPowVeriblock");     Fee = @(0.01);       MinMemGiB = 2;                                             Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo progpow-veriblock" }
    [PSCustomObject]@{ Algorithms = @("ProgPowZano");          Fee = @(0.01);       MinMemGiB = $MinerPools[0].ProgPowZano.DAGSizeGiB + 1.08;  MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo progpowz --intensity 25" }
#   [PSCustomObject]@{ Algorithms = @("Tensority");            Fee = @(0.01);       MinMemGiB = 2;                                             Minerset = 3; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo tensority --intensity 25" } # ASIC
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                $Algorithm0 = $_.Algorithms[0]
                $Algorithm1 = $_.Algorithms[1]
                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)$(If ($Algorithm1) { "-$($Algorithm0)&$($Algorithm1)" })" -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGiB -le 2) { $Arguments = $Arguments -replace " --intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "dual-algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += Switch ($MinerPools[0].$Algorithm0.Protocol) { 
                    "ethstratum1"  { " --url stratum2"; Break }
                    "ethstratum2"  { " --url stratum2"; Break }
                    "ethstratumnh" { " --url stratum2"; Break }
                    Default        { " --url stratum"; Break }
                }
                $Arguments += If ($MinerPools[0].$Algorithm0.PoolPorts[1]) { "+ssl" } Else { "+tcp" }
                $Arguments += "://$($MinerPools[0].$Algorithm0.Host):$($MinerPools[0].$Algorithm0.PoolPorts | Select-Object -Last 1)"
                $Arguments += " --user $($MinerPools[0].$Algorithm0.User)"
                $Arguments += " --pass $($MinerPools[0].$Algorithm0.Pass)$(If ($MinerPools[0].$Algorithm0.BaseName -eq "ProHashing" -and $_.Algorithms -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].$Algorithm0.DAGSizeGiB))" })"
                If ($MinerPools[0].$Algorithm0.WorkerName) { $Arguments += " --worker $($MinerPools[0].$Algorithm0.WorkerName)" }

                If ($MinerPools[0].$Algorithm0.Currency -in @("CLO", "ETC", "ETH", "ETHW", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZCOIN", "ZELS")) { 
                    $Arguments += " --coin $($MinerPools[0].$Algorithm0.Currency)"
                }

                If ($Algorithm1) { 
                    $Arguments += Switch ($MinerPools[1].$Algorithm1.Protocol) { 
                        "ethstratum1"  { " --url2 stratum2"; Break }
                        "ethstratum2"  { " --url2 stratum2"; Break }
                        "ethstratumnh" { " --url2 stratum2"; Break }
                    }
                    $Arguments += If ($MinerPools[1].$Algorithm1.PoolPorts[1]) { "ssl" } Else { "+tcp" }
                    $Arguments += "://$($MinerPools[1].$Algorithm1.Host):$($MinerPools[1].$Algorithm1.PoolPorts | Select-Object -Last 1)"
                    $Arguments += " --user2 $($MinerPools[1].$Algorithm1.User)"
                    $Arguments += " --pass2 $($MinerPools[1].$Algorithm1.Pass)$(If ($MinerPools[1].$Algorithm1.BaseName -eq "ProHashing" -and $_.Algorithms -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].$Algorithm1.DAGSizeGiB))" })"
                    If ($MinerPools[1].$Algorithm1.WorkerName) { $Arguments += " --worker2 $($MinerPools[1].$Algorithm1.WorkerName)" }
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                If ($Arguments -notmatch "--kernel [0-9]") { $_.WarmupTimes[0] += 15 } # Allow extra seconds for kernel auto tuning

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithms | Select-Object)
                    API         = "Trex"
                    Arguments   = ("$($Arguments) --no-strict-ssl --no-watchdog --gpu-report-interval 5 --quiet --retry-pause 1 --timeout 50000 --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-read-only --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee # Dev fee
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)/trex"
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