using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\teamredminer.exe"
$Uri = "https://github.com/todxx/teamredminer/releases/download/v0.9.0/teamredminer-v0.9.0-win.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";           Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=autolykos2" }
    [PSCustomObject]@{ Algorithm = "Chukwa";               Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=trtl_chukwa" }
    [PSCustomObject]@{ Algorithm = "Chukwa2";              Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=trtl_chukwa2" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Fee = 0.025; MinMemGB = 2.1; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cn_conceal --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" } # SRBMinerMulti-v0.8.7 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Fee = 0.025; MinMemGB = 2.1; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cn_heavy --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightHaven";     Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cn_haven --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cn_saber --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" }
    # [PSCustomObject]@{ Algorithm = "CryptonightR";         Fee = 0.025; MinMemGB = 2.0; MinerSet = 1; WarmupTimes = @(60, 60); Arguments = " --algo=cnr --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" } # Not profitable at all
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cnv8 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Fee = 0.025; MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cnv8_dbl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" } # XmRig-v6.16.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cnv8_half --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle";    Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cnv8_trtl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cnv8_rwz --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";       Fee = 0.025; MinMemGB = 3.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cnv8_upx2 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29";          Fee = 0.025; MinMemGB = 2.1; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=cuckarood29_grin" } # 2GB is not enough
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";           Fee = 0.025; MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(60, 60); Arguments = " --algo=cuckatoo31_grin" } # lolMiner-v1.34 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";              Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(60, 60); Arguments = " --algo=etchash" } # PhoenixMiner-v5.9d is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";               Fee = 0.01;  MinMemGB = 5.0; MinerSet = 1; WarmupTimes = @(65, 65); Arguments = " --algo=ethash" } # PhoenixMiner-v5.9d is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem";         Fee = 0.01;  MinMemGB = 2.0; MinerSet = 1; WarmupTimes = @(60, 60); Arguments = " --algo=ethash" }
    [PSCustomObject]@{ Algorithm = "FiroPoW";              Fee = 0.02;  MinMemGB = 3.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=firopow" } # Wildrig-v0.31.2 is fastest on Polaris
    [PSCustomObject]@{ Algorithm = "KawPoW";               Fee = 0.02;  MinMemGB = 3.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=kawpow" } # Wildrig-v0.31.2 is fastest on Polaris
    [PSCustomObject]@{ Algorithm = "Lyra2z";               Fee = 0.03;  MinMemGB = 2.0; MinerSet = 1; WarmupTimes = @(60, 60); Arguments = " --algo=lyra2z" } # XmRig-v6.16.2 is faster
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";             Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=lyra2rev3" }
    [PSCustomObject]@{ Algorithm = "MTP";                  Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algo=mtp" }
    [PSCustomObject]@{ Algorithm = "Nimiq";                Fee = 0.025; MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=nimiq" }
    [PSCustomObject]@{ Algorithm = "Phi2";                 Fee = 0.03;  MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=phi2" }
    [PSCustomObject]@{ Algorithm = "VertHash";             Fee = 0.025; MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=verthash --verthash_file=..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithm = "X16r";                 Fee = 0.025; MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=x16r" }
    [PSCustomObject]@{ Algorithm = "X16rv2";               Fee = 0.025; MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=x16rv2" }
    [PSCustomObject]@{ Algorithm = "X16s";                 Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=x16s" }
    [PSCustomObject]@{ Algorithm = "X16rt";                Fee = 0.025; MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo=x16rt" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "AMD" | Select-Object Model -Unique | ForEach-Object { 

        If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

                $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

                $AvailableMiner_Devices = @($Miner_Devices | Where-Object { [Uint]($_.OpenCL.GlobalMemSize / 0.99GB) -ge $MinMemGB -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0" })
                If ($_.Algorithm -notin @("Autolykos2", "EtcHash", "Ethash", "Kawpow", "Nimiq", "MTP", "VertHash")) { $AvailableMiner_Devices = @($AvailableMiner_Devices | Where-Object { $_.Model -notmatch "^Radeon RX 5[0-9]{3}.*" }) } # Navi is not supported by other algorithms
                If ($AvailableMiner_Devices) { 

                    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                    # Get arguments for available miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "autotune") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                    If ($Pools.($_.Algorithm).DAGsize -ne $null -and $Pools.($_.Algorithm).BaseName -match "^NiceHash$|^MiningPoolHub$") { $_.Arguments += " --eth_stratum_mode=nicehash" }

                    If ($Pools.($_.Algorithm).SSL) { $Protocol = "stratum+ssl" } Else { $Protocol = "stratum+tcp" }

                    If ($_.Algorithm -eq "VertHash") { 
                        If (-not (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf )) { 
                            If (-not (Test-Path -Path ".\Cache" -PathType Container)) { New-Item -Path . -Name "Cache" -ItemType Directory | Out-Null }
                            $WarmupTime[1] += 45 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat
                        }
                    }

                    $Pass = " --pass $($Pools.($_.Algorithm).Pass)"
                    If ($Pools.($_.Algorithm).BaseName -match "^ProHashing$" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum -$DAGmemReserve) / 1GB)" }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $AvailableMiner_Devices.Name
                        Type        = "AMD"
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) --url $($Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User)$Pass --watchdog_script --no_gpu_monitor --init_style=3 --hardware=gpu --platform $($AvailableMiner_Devices.PlatformId | Sort-Object -Unique) --api_listen=127.0.0.1:$MinerAPIPort --devices $(($AvailableMiner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:d}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "Xgminer"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
