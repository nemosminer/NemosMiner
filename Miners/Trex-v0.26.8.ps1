using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.26.8/t-rex-0.26.8-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\t-rex.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");           Fee = @(0.02);       MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(45, 30);  Arguments = " --algo autolykos2 --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("Blake3");               Fee = @(0.01);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(45, 0);   Arguments = " --algo blake3 --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");              Fee = @(0.01);       MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo etchash --intensity 25" } # GMiner-v3.10 is fastest
    [PSCustomObject]@{ Algorithms = @("Ethash");               Fee = @(0.01);       MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --intensity 25" } # GMiner-v3.10 is fastest
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");    Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].EtcHash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo etchash --dual-algo blake3 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Autolykos2"); Fee = @(0.01, 0.02); MinMemGB = 8;                                     MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --dual-algo autolykos2 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");     Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --dual-algo blake3 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "FiroPoW");    Fee = @(0.01, 0.01); MinMemGB = 10;                                    MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(255, 15); Arguments = " --algo ethash --dual-algo firopow --lhr-tune -1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPoW");     Fee = @(0.01, 0.01); MinMemGB = 10;                                    MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(255, 15); Arguments = " --algo ethash --dual-algo kawpow --lhr-tune -1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Octopus");    Fee = @(0.01, 0.02); MinMemGB = 8;                                     MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --dual-algo octopus --lhr-tune -1" }
    [PSCustomObject]@{ Algorithms = @("EthashLowMem");         Fee = @(0.01);       MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --intensity 25" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithms = @("FiroPoW");              Fee = @(0.01);       MinMemGB = $MinerPools[0].FiroPoW.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo firopow --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("KawPoW");               Fee = @(0.01);       MinMemGB = $MinerPools[0].KawPoW.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(45, 0);   Arguments = " --algo kawpow --intensity 25" } # XmRig-v6.18.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithms = @("MTP");                  Fee = @(0.01);       MinMemGB = 3;                                     MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo mtp --intensity 21" }
    [PSCustomObject]@{ Algorithms = @("MTPTcr");               Fee = @(0.01);       MinMemGB = 3;                                     MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo mtp-tcr --intensity 21" }
    [PSCustomObject]@{ Algorithms = @("Multi");                Fee = @(0.01);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo multi --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("Octopus");              Fee = @(0.02);       MinMemGB = $MinerPools[0].Octopus.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo octopus" } # 6GB is not enough
    [PSCustomObject]@{ Algorithms = @("ProgPoWSero");          Fee = @(0.01);       MinMemGB = $MinerPools[0].ProgPoWSero.DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo progpow --coin sero" }
    [PSCustomObject]@{ Algorithms = @("ProgPoWVeil");          Fee = @(0.01);       MinMemGB = $MinerPools[0].ProgPoWVeil.DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo progpow-veil --intensity 24" }
    [PSCustomObject]@{ Algorithms = @("ProgPoWVeriblock");     Fee = @(0.01);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo progpow-veriblock" }
    [PSCustomObject]@{ Algorithms = @("ProgPoWZ");             Fee = @(0.01);       MinMemGB = $MinerPools[0].ProgPoWZ.DAGSizeGB;     MemReserveGB = 0.42; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo progpowz --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("Tensority");            Fee = @(0.01);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo tensority --intensity 25" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithms[1]) { "$($_.Algorithms[0])&$($_.Algorithms[1])" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGB -le 2) { $Arguments = $Arguments -replace " --intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "dual-algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --url $(If ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1]) { "stratum+ssl" } Else { If ($MinerPools[0].($_.Algorithms[0]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithms[0]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { "stratum2+tcp" } Else { "stratum+tcp" } })://$($MinerPools[0].($_.Algorithms[0]).Host):$($MinerPools[0].($_.Algorithms[0]).PoolPorts | Select-Object -Last 1)"
                $Arguments += " --user $($MinerPools[0].($_.Algorithms[0]).User)"
                $Arguments += " --pass $($MinerPools[0].($_.Algorithms[0]).Pass)$(If ($MinerPools[0].($_.Algorithms[0]).BaseName -eq "ProHashing" -and $_.Algorithms -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                If ($MinerPools[0].($_.Algorithms[0]).WorkerName) { $Arguments += " --worker $($MinerPools[0].($_.Algorithms[0]).WorkerName)" }

                If ($MinerPools[0].($_.Algorithms[0]).Currency -in @("CLO", "ETC", "ETH", "ETHW", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZCOIN", "ZELS")) { 
                    $Arguments += " --coin $($MinerPools[0].($_.Algorithms[0]).Currency)"
                }

                If ($_.Algorithms[1]) { 
                    $Arguments += " --url2 $(If ($MinerPools[1].($_.Algorithms[1]).PoolPorts[1]) { "stratum+ssl" } Else { If ($MinerPools[1].($_.Algorithms[1]).DAGsizeGB -ne $null -and $MinerPools[1].($_.Algorithms[1]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { "stratum2+tcp" } Else { "stratum+tcp" } })://$($MinerPools[1].($_.Algorithms[1]).Host):$($MinerPools[1].($_.Algorithms[1]).PoolPorts | Select-Object -Last 1)"
                    $Arguments += " --user2 $($MinerPools[1].($_.Algorithms[1]).User)"
                    $Arguments += " --pass2 $($MinerPools[1].($_.Algorithms[1]).Pass)$(If ($MinerPools[1].($_.Algorithms[1]).BaseName -eq "ProHashing" -and $_.Algorithms -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                    If ($MinerPools[1].($_.Algorithms[1]).WorkerName) { $Arguments += " --worker2 $($MinerPools[1].($_.Algorithms[1]).WorkerName)" }
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $Arguments += $_.Tuning }

                If ($Arguments -notmatch "--kernel [0-9]") { $_.WarmupTimes[0] += 15 } # Allow extra seconds for kernel auto tuning

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($Arguments) --no-strict-ssl --no-watchdog --gpu-report-interval 5 --quiet --retry-pause 1 --timeout 50000 --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-read-only --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithms[0], $_.Algorithms[1] | Select-Object)
                    API         = "Trex"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee # Dev fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)/trex"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
