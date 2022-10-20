using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.Type -eq"NVIDIA" })) { Return }

$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/3.10/gminer_3_10_windows64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Equihash1254"); Type = "AMD"; Fee = @(0.02);  MinMemGB = 1.8;                                   MemReserveGB = 0;    Tuning = ""; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash125_4 --cuda 0 --opencl 1" } # lolMiner-v1.61 is fastest
    [PSCustomObject]@{ Algorithms = @("Equihash1445"); Type = "AMD"; Fee = @(0.02);  MinMemGB = 1.8;                                   MemReserveGB = 0;    Tuning = ""; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash144_5 $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1445.Currency -DefaultCommand "--pers auto") --cuda 0 --opencl 1" } # lolMiner-v1.61 is fastest
    [PSCustomObject]@{ Algorithms = @("Equihash2109"); Type = "AMD"; Fee = @(0.02);  MinMemGB = 2.8;                                   MemReserveGB = 0;    Tuning = ""; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash210_9 --cuda 0 --opencl 1" } # lolMiner-v1.61 is fastest
    [PSCustomObject]@{ Algorithms = @("Ethash");       Type = "AMD"; Fee = @(0.01);  MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.41; Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EthashLowMem"); Type = "AMD"; Fee = @(0.01);  MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.41; Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("KawPoW");       Type = "AMD"; Fee = @(0.01);  MinMemGB = $MinerPools[0].KawPoW.DAGSizeGB;       MemReserveGB = 0.41; Tuning = ""; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo kawpow --cuda 0 --opencl 1" }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo autolykos2 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo autolykos2 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Cuckaroo30CTX");              Type = "NVIDIA"; Fee = @(0.05);  MinMemGB = 8.0;                                   MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo cortex --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Cuckoo29");                   Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = 6.0;                                   MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo aeternity --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Equihash1254");               Type = "NVIDIA"; Fee = @(0.02);  MinMemGB = 3.0;                                   MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo equihash125_4 --cuda 1 --opencl 0" } # MiniZ-v1.9z3 is fastest
    [PSCustomObject]@{ Algorithms = @("Equihash1445");               Type = "NVIDIA"; Fee = @(0.02);  MinMemGB = 2.1;                                   MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo equihash144_5 $(Get-EquihashCoinPers -Command "--pers "  -Currency $MinerPools[0].Equihash1445.Currency -DefaultCommand "--pers auto") --cuda 1 --opencl 0" } # MiniZ-v1.9z3 is fastest
    [PSCustomObject]@{ Algorithms = @("Equihash2109");               Type = "NVIDIA"; Fee = @(0.02);  MinMemGB = 1.0;                                   MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo equihash210_9 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo etchash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo etchash --dalgo kheavyhash --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                     Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo ethash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo ethash --dalgo kheavyhash --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("EthashLowMem");               Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo ethash --cuda 1 --opencl 0" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithms = @("EthashLowMem", "kHeavyHash"); Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo ethash --dalgo kheavyhash --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("KawPoW");                     Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $MinerPools[0].KawPoW.DAGSizeGB;       MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo kawpow --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = 2.0;                                   MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo kaspa --cuda 1 --opencl 0" } # XmRig-v6.18.0 is almost as fast but has no fee
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            # Windows 10 requires more memory on some algos
            # If ($_.Algorithms[0] -match "Cuckaroo.*|Cuckoo.*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $_.MinMemGB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "cuda", "opencl", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --server $($MinerPools[0].($_.Algorithms[0]).Host):$($MinerPools[0].($_.Algorithms[0]).PoolPorts | Select-Object -Last 1)"
                If ($MinerPools[0].($_.Algorithms[0]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithms[0]).BaseName -in @("MiningPoolHub", "NiceHash")) { $Arguments += " --proto stratum" }
                If ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1]) { $Arguments += " --ssl 1" }
                $Arguments += " --user $($MinerPools[0].($_.Algorithms[0]).User)"
                $Arguments += " --pass $($MinerPools[0].($_.Algorithms[0]).Pass)$(If ($MinerPools[0].($_.Algorithms[0]).BaseName -eq "ProHashing" -and $_.Algorithms[0] -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                If ($MinerPools[0].($_.Algorithms[0]).WorkerName) { $Arguments += " --worker $($MinerPools[0].($_.Algorithms[0]).WorkerName)" }
                IF ($MinerPools[0].($_.Algorithms[0]).CoinName) { }

                If ($_.Algorithms[1]) { 
                    $Arguments += " --dserver $($MinerPools[0].($_.Algorithms[1]).Host):$($MinerPools[0].($_.Algorithms[1]).PoolPorts | Select-Object -Last 1)"
                    If ($MinerPools[0].($_.Algorithms[1]).PoolPorts[1]) { $Arguments += " --dssl 1" }
                    $Arguments += " --duser $($MinerPools[0].($_.Algorithms[1]).User)"
                    $Arguments += " --dpass $($MinerPools[0].($_.Algorithms[1]).Pass)"
                    If ($MinerPools[0].($_.Algorithms[1]).WorkerName) { $Arguments += " --dworker $($MinerPools[0].($_.Algorithms[1]).WorkerName)" }
                    IF ($MinerPools[0].($_.Algorithms[1]).CoinName) { }
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $Arguments += $_.Tuning }

                # Contest ETH address (if ETH wallet is specified in config)
                # $Arguments += If ($Config.Wallets.ETH) { " --contest_wallet $($Config.Wallets.ETH)" } Else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($Arguments) --api $MinerAPIPort --watchdog 0 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithms[0], $_.Algorithms[1] | Select-Object)
                    API         = "Gminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
