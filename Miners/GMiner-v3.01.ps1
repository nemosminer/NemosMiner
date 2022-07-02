using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.Type -eq"NVIDIA" })) { Return }

$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/3.01/gminer_3_01_windows64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Equihash1254";              Type = "AMD"; Fee = @(0.02);  MinMemGB = 1.8;                             MemReserveGB = 0;    Tuning = ""; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash125_4 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.52a is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1445";              Type = "AMD"; Fee = @(0.02);  MinMemGB = 1.8;                             MemReserveGB = 0;    Tuning = ""; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash144_5 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.52a is fastest
    [PSCustomObject]@{ Algorithm = "Equihash2109";              Type = "AMD"; Fee = @(0.02);  MinMemGB = 2.8;                             MemReserveGB = 0;    Tuning = ""; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash210_9 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.52a is fastest
    [PSCustomObject]@{ Algorithm = "EquihashBTG";               Type = "AMD"; Fee = @(0.02);  MinMemGB = 3.0;                             MemReserveGB = 0;    Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo equihash144_5 --pers BgoldPoW --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = "EtcHash";                   Type = "AMD"; Fee = @(0.01);  MinMemGB = $Pools."Etchash".DAGSizeGB;      MemReserveGB = 0.41; Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo etchash --cuda 0 --opencl 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";                    Type = "AMD"; Fee = @(0.01);  MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.41; Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem";              Type = "AMD"; Fee = @(0.01);  MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "KawPoW";                    Type = "AMD"; Fee = @(0.01);  MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.41; Tuning = ""; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo kawpow --cuda 0 --opencl 1" }

    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX";             Type = "NVIDIA"; Fee = @(0.05);  MinMemGB = 8.0;                             MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo cortex --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "Equihash1254";              Type = "NVIDIA"; Fee = @(0.02);  MinMemGB = 3.0;                             MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo equihash125_4 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.8z3 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1445";              Type = "NVIDIA"; Fee = @(0.02);  MinMemGB = 2.1;                             MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo equihash144_5 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.8z3 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash2109";              Type = "NVIDIA"; Fee = @(0.02);  MinMemGB = 1.0;                             MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo equihash210_9 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";               Type = "NVIDIA"; Fee = @(0.02);  MinMemGB = 3.0;                             MemReserveGB = 0;    Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo equihash144_5 --pers BgoldPoW --cuda 1 --opencl 0" } # MiniZ-v1.8z3 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";                   Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $Pools."Etchash".DAGSizeGB;      MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo etchash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";                    Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo ethash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem";              Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo ethash --cuda 1 --opencl 0" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";                    Type = "NVIDIA"; Fee = @(0.01);  MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.41; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo kawpow --cuda 1 --opencl 0" } # XmRig-v6.18.0 is almost as fast but has no fee
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            # Windows 10 requires more memory on some algos
            If ($_.Algorithm -match "Cuckaroo.*|Cuckoo.*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $_.MinMemGB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "cuda", "opencl", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --server $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)"
                If ($Pools.($_.Algorithm).DAGsizeGB -ne $null -and $Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash")) { $_.Arguments += " --proto stratum" }
                If ($Pools.($_.Algorithm).SSL) { $_.Arguments += " --ssl 1" }
                $_.Arguments += " --user $($Pools.($_.Algorithm).User)"
                $_.Arguments += " --pass $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                If ($Pools.($_.Algorithm).WorkerName) { $_.Arguments += " --worker $($Pools.($_.Algorithm).WorkerName)" }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                # Contest ETH address (if ETH wallet is specified in config)
                # $_.Arguments += If ($Config.Wallets.ETH) { " --contest_wallet $($Config.Wallets.ETH)" } Else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --api $MinerAPIPort --watchdog 0 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithms  = $_.Algorithm
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