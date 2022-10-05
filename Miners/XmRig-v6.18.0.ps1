using module ..\Includes\Include.psm1

$Devices = $Variables.EnabledDevices

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.6" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda11_6-win64.7z"; Break }
    { $_ -ge "11.5" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda11_5-win64.7z"; Break }
    { $_ -ge "11.4" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda11_4-win64.7z"; Break }
    { $_ -ge "11.3" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda11_3-win64.7z"; Break }
    { $_ -ge "11.2" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda11_2-win64.7z"; Break }
    { $_ -ge "11.1" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda11_1-win64.7z"; Break }
    { $_ -ge "11.0" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda11_0-win64.7z"; Break }
    { $_ -ge "10.2" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda10_2-win64.7z"; Break }
    { $_ -ge "10.1" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda10_1-win64.7z"; Break }
    { $_ -ge "10.0" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda10_0-win64.7z"; Break }
    { $_ -ge "9.2" }  { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda9_2-win64.7z"; Break }
    { $_ -ge "9.1" }  { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda9_1-win64.7z"; Break }
    { $_ -ge "9.0" }  { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda9_0-win64.7z"; Break }
    Default           { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.18.0-xmrig/xmrig-6.18.0-msvc-cuda8_0-win64.7z"; Break }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\xmrig.exe"
$DeviceEnumerator = "PlatformId_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/ccx" } # SRBMinerMulti-v1.1.0 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "AMD"; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "AMD"; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/half" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "AMD"; MinMemGB = 4;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "AMD"; MinMemGB = 4;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "AMD"; MinMemGB = 0.25;                            MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "AMD"; MinMemGB = 0.25;                            MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-pico/tlo" }
#   [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/r" } # Is never profitable
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyXhv";  Type = "AMD"; MinMemGB = 4;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/zls" } 
    [PSCustomObject]@{ Algorithm = "KawPoW";               Type = "AMD"; MinMemGB = $MinerPools[0].KawPoW.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(60, 15); Arguments = " --algo kawpow" } # NBMiner-v42.3 is fastest, but has 2% miner fee
#   [PSCustomObject]@{ Algorithm = "RandomX";              Type = "AMD"; MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/0" } # Not profitable at all
#   [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "AMD"; MinMemGB = 4;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/arq" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "AMD"; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/keva" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/loki" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "AMD"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/sfx" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "AMD"; MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/wow" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
    [PSCustomObject]@{ Algorithm = "Uplexa";               Type = "AMD"; MinMemGB = 0.25;                            MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/upx2" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway

    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";         Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo argon2/chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2ChukwaV2";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo argon2/chukwav2" }
    [PSCustomObject]@{ Algorithm = "Argon2Ninja";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo argon2/ninja" }
    [PSCustomObject]@{ Algorithm = "Argon2WRKZ";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo argon2/wrkz" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "CPU"; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo cn/double" } # XmrStak-v2.10.8 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/half" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-pico/tlo" }
#   [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/r" } # Is never profitable
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/upx2" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyXhv";  Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/zls" }
#   [PSCustomObject]@{ Algorithm = "RandomX";              Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/0" } # Not profitable at all
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/arq" } # SRBMinerMulti-v1.1.0 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/keva" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/sfx" } # SRBMinerMulti-v1.1.0 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/wow" }
    [PSCustomObject]@{ Algorithm = "Uplexa";               Type = "CPU"; MinMemGB = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/upx2" }

    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/ccx" } # CryptoDredge-v0.27.0 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "NVIDIA"; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "NVIDIA"; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/half" } # CryptoDredge-v0.27.0 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "NVIDIA"; MinMemGB = 4;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "NVIDIA"; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "NVIDIA"; MinMemGB = 0.25;                            MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "NVIDIA"; MinMemGB = 0.25;                            MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn-pico/tlo" }
#   [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/r" } # Is never profitable
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyXhv";  Type = "NVIDIA"; MinMemGB = 4;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo cn/zls" } 
    [PSCustomObject]@{ Algorithm = "KawPoW";               Type = "NVIDIA"; MinMemGB = $MinerPools[0].KawPoW.DAGSizeGB; MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo kawpow" } # Trex-v0.26.6 is fastest, but has 1% miner fee
#   [PSCustomObject]@{ Algorithm = "RandomX";              Type = "NVIDIA"; MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo rx/0" } # Not profitable at all
#   [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "NVIDIA"; MinMemGB = 4;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo rx/arq" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "NVIDIA"; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo rx/keva" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo rx/loki" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo rx/sfx" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "NVIDIA"; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo rx/wow" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "Uplexa";               Type = "NVIDIA"; MinMemGB = 0.5;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo rx/upx2" } # GPUs don't do RandomX and when they do it's a watt-wasting miracle anyway
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Select-Object | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.MemoryGB -gt $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' ' -replace ' '

                $Arguments = $_.Arguments

                If ($_.Type -eq "CPU") { $Arguments += " --threads=$($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1)" }
                Else { $Arguments += " --no-cpu --opencl --opencl-platform $($AvailableMiner_Devices.PlatformId) --opencl-devices=$(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" }

                # Optionally disable dev fee mining, requires change in source code
                # If ($Config.DisableMinerFee) { 
                #     $_.Arguments += " --donate-level 0"
                #     $_.Fee = 0
                # }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($Arguments) $(If ($MinerPools[0].($_.Algorithm).BaseName -eq "NiceHash") { " --nicehash" } )$(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { " --tls" } ) --url=$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Where-Object  { $_ -ne $null } | Select-Object -Last 1) --user=$($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass=$($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { " --rig-id $($MinerPools[0].($_.Algorithm).WorkerName)" }) --keepalive --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$($Config.WorkerName) --api-id=$($Miner_Name) --retries=90 --retry-pause=1" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    API         = "XmRig"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = 0.01
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                    MinerUri    = "http://workers.xmrig.info/worker?url=$([System.Web.HTTPUtility]::UrlEncode("http://localhost:$($MinerAPIPort)"))?Authorization=Bearer $([System.Web.HTTPUtility]::UrlEncode($Miner_Name))"
                }
            }
        }
    }
}
