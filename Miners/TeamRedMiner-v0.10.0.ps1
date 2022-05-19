using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0" })) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/TeamRedMiner/teamredminer-v0.10.0-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\teamredminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Autolykos2");           Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=autolykos2" }
    [PSCustomObject]@{ Algorithm = @("Chukwa");               Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=trtl_chukwa" }
    [PSCustomObject]@{ Algorithm = @("Chukwa2");              Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=trtl_chukwa2" }
    [PSCustomObject]@{ Algorithm = @("CryptonightCcx");       Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cn_conceal --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" } # SRBMinerMulti-v0.9.4 is fastest
    [PSCustomObject]@{ Algorithm = @("CryptonightHeavy");     Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cn_heavy --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = @("CryptonightHaven");     Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cn_haven --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = @("CryptonightHeavyTube"); Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cn_saber --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" }
    # [PSCustomObject]@{ Algorithm = @("CryptonightR");         Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 15);   Arguments = " --algo=cnr --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" } # Not profitable at all
    [PSCustomObject]@{ Algorithm = @("CryptonightV1");        Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cnv8 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = @("CryptonightDouble");    Fee = @(0.025); MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cnv8_dbl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" } # XmRig-v6.17.0 is fastest
    [PSCustomObject]@{ Algorithm = @("CryptonightHalf");      Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cnv8_half --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = @("CryptonightTurtle");    Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cnv8_trtl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = @("CryptonightRwz");       Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cnv8_rwz --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = @("CryptonightUpx");       Fee = @(0.025); MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cnv8_upx2 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id=$($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = @("CuckarooD29");          Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=cuckarood29_grin" } # 2GB is not enough
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");           Fee = @(0.025); MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 15);   Arguments = " --algo=cuckatoo31_grin" } # lolMiner-v1.51 is fastest
    [PSCustomObject]@{ Algorithm = @("EtcHash");              Fee = @(0.01);  MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(45, 75);   Arguments = " --algo=etchash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = @("Ethash");               Fee = @(0.01);  MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(150, 150); Arguments = " --algo=ethash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = @("Ethash", "SHA256ton");  Fee = @(0.01);  MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 90);   Arguments = " --algo=ethash" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");         Fee = @(0.01);  MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(45, 75);   Arguments = " --algo=ethash" }
    [PSCustomObject]@{ Algorithm = @("FiroPoW");              Fee = @(0.02);  MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 75);   Arguments = " --algo=firopow" } # Wildrig-v0.31.3 is fastest on Polaris
    [PSCustomObject]@{ Algorithm = @("KawPoW");               Fee = @(0.02);  MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(60, 75);   Arguments = " --algo=kawpow" } # Wildrig-v0.31.3 is fastest on Polaris
    [PSCustomObject]@{ Algorithm = @("Lyra2z");               Fee = @(0.03);  MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 15);   Arguments = " --algo=lyra2z" } # XmRig-v6.17.0 is faster
    [PSCustomObject]@{ Algorithm = @("Lyra2RE3");             Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=lyra2rev3" }
    [PSCustomObject]@{ Algorithm = @("MTP");                  Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 45);   Arguments = " --algo=mtp" }
    [PSCustomObject]@{ Algorithm = @("Nimiq");                Fee = @(0.025); MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=nimiq --nimiq_worker=$($Config.Workername)" }
    [PSCustomObject]@{ Algorithm = @("Phi2");                 Fee = @(0.03);  MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=phi2" }
    [PSCustomObject]@{ Algorithm = @("SHA256ton");            Fee = @(0.01);  MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=ton" }
    [PSCustomObject]@{ Algorithm = @("VertHash");             Fee = @(0.025); MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(75, 15);   Arguments = " --algo=verthash --verthash_file=..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithm = @("X16r");                 Fee = @(0.025); MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=x16r" }
    [PSCustomObject]@{ Algorithm = @("X16rv2");               Fee = @(0.025); MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=x16rv2" }
    [PSCustomObject]@{ Algorithm = @("X16s");                 Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=x16s" }
    [PSCustomObject]@{ Algorithm = @("X16rt");                Fee = @(0.025); MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algo=x16rt" }
) 

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm[0]).Host -and (-not $_.Algorithm[1] -or $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)

            If ($_.Algorithm -notin @("Autolykos2", "EtcHash", "Ethash", "Kawpow", "Nimiq", "MTP", "VertHash")) { $AvailableMiner_Devices = $AvailableMiner_Devices | Where-Object { $_.Model -notmatch "^Radeon RX 5[0-9]{3}.*" } } # Navi is not supported by other algorithms

            If ($AvailableMiner_Devices) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "autotune", "rig_id") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($_.Algorithm -eq "VertHash") { 
                    If (-not (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf )) { 
                        If (-not (Test-Path -Path ".\Cache" -PathType Container)) { New-Item -Path . -Name "Cache" -ItemType Directory | Out-Null }
                        $WarmupTime[1] += 45 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat
                    }
                }

                If ($_.Algorithm[0] -eq "SHA256ton") { 
                    If ($Pools.($_.Algorithm[0]).BaseName -eq "TonWhales") { 
                        $_.Arguments += " --url=stratum+tcp://tcp.$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)"
                    }
                    Else { 
                        $_.Arguments += " --url=stratum+tcp://$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)"
                    }
                }
                Else { 
                    $_.Arguments += " --url=$(If ($Pools.($_.Algorithm[0]).SSL) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)"
                    If ($Pools.($_.Algorithm[0]).DAGsizeGB -ne $null -and $Pools.($_.Algorithm[0]).BaseName -in @("MiningPoolHub", "NiceHash")) { $_.Arguments += " --eth_stratum_mode=nicehash" }

                    If ($_.Algorithm[0] -match "^Et(c)hash.+" -and $AvailableMiner_Devices.Model -notmatch "^Radeon RX [0-9]{3} ") { $_.Fee = @(0.0075) } # Polaris cards 0.75%
                }
                $_.Arguments += " --user=$($Pools.($_.Algorithm[0]).User) --pass=$($Pools.($_.Algorithm[0]).Pass)$(If ($Pools.($_.Algorithm[0]).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$(((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB) * 1GB / 1000000000)" })"

                If ($_.Algorithm[1] -eq "SHA256ton") { 
                    If ($Pools.($_.Algorithm[1]).BaseName -eq "TonWhales") { 
                        $_.Arguments += " --ton_start --url=stratum+tcp://tcp.$($Pools.($_.Algorithm[1]).Host):$($Pools.($_.Algorithm[1]).Port) --user=$($Pools.($_.Algorithm[1]).User) --pass=$($Pools.($_.Algorithm[1]).pass) --api2_listen=127.0.0.1:$($MinerAPIPort + 1) --ton_end"
                    }
                    Else { 
                        $_.Arguments += " --ton_start --url=stratum+tcp://$($Pools.($_.Algorithm[1]).Host):$($Pools.($_.Algorithm[1]).Port) --user=$($Pools.($_.Algorithm[1]).User) --pass=$($Pools.($_.Algorithm[1]).pass) --api2_listen=127.0.0.1:$($MinerAPIPort + 1) --ton_end"
                    }
                }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --watchdog_script --no_gpu_monitor --init_style=3 --hardware=gpu --platform=$($AvailableMiner_Devices.PlatformId | Sort-Object -Unique) --api_listen=127.0.0.1:$MinerAPIPort --devices=$(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                    API         = "Xgminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
