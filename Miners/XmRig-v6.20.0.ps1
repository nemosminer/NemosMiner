<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
Version:        5.0.1.8
Version date:   2023/11/03
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -in @("AMD", "CPU") -or $_.OpenCL.ComputeCapability -gt "5.0" })) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.8" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda11_8-win64.7z"; Break }
    { $_ -ge "11.7" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda11_7-win64.7z"; Break }
    { $_ -ge "11.6" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda11_6-win64.7z"; Break }
    { $_ -ge "11.5" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda11_5-win64.7z"; Break }
    { $_ -ge "11.4" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda11_4-win64.7z"; Break }
    { $_ -ge "11.3" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda11_3-win64.7z"; Break }
    { $_ -ge "11.2" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda11_2-win64.7z"; Break }
    { $_ -ge "11.1" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda11_1-win64.7z"; Break }
    { $_ -ge "11.0" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda11_0-win64.7z"; Break }
    { $_ -ge "10.2" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda10_2-win64.7z"; Break }
    { $_ -ge "10.1" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda10_1-win64.7z"; Break }
    { $_ -ge "10.0" } { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda10_0-win64.7z"; Break }
    { $_ -ge "9.2" }  { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda9_2-win64.7z"; Break }
    { $_ -ge "9.1" }  { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda9_1-win64.7z"; Break }
    { $_ -ge "9.0" }  { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda9_0-win64.7z"; Break }
    Default           { "https://github.com/RainbowMiner/miner-binaries/releases/download/v6.20.0-xmrig/xmrig-6.20.0-msvc-cuda8_0-win64.7z"; Break }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$($Name)\xmrig.exe"
$DeviceEnumerator = "PlatformId_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/ccx" } # SRBMinerMulti-v2.3.9 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "AMD"; MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "AMD"; MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/half" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "AMD"; MinMemGiB = 4;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "AMD"; MinMemGiB = 4;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "AMD"; MinMemGiB = 0.25; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "AMD"; MinMemGiB = 0.25; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico/tlo" }
#   [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "AMD"; MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyXhv";  Type = "AMD"; MinMemGiB = 4;    Minerset = 1; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/zls" } 
    [PSCustomObject]@{ Algorithm = "KawPow";               Type = "AMD"; MinMemGiB = 0.77; Minerset = 1; WarmupTimes = @(60, 15); ExcludePools = @(); Arguments = " --algo kawpow" } # NBMiner-v42.3 is fastest, but has 2% miner fee
#   [PSCustomObject]@{ Algorithm = "Randomx";              Type = "AMD"; MinMemGiB = 3;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/0" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "AMD"; MinMemGiB = 4;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/arq" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "AMD"; MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/keva" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/loki" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "AMD"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/sfx" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "AMD"; MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/wow" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
    [PSCustomObject]@{ Algorithm = "Uplexa";               Type = "AMD"; MinMemGiB = 0.25; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/upx2" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway

    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";         Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo argon2/chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2ChukwaV2";       Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo argon2/chukwav2" }
    [PSCustomObject]@{ Algorithm = "Argon2Ninja";          Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo argon2/ninja" }
    [PSCustomObject]@{ Algorithm = "Argon2WRKZ";           Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo argon2/wrkz" }
#   [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/0" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/ccx" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/double" }  # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/fast" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-lite/0" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-lite/1" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/half" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 20);  ExcludePools = @(); Arguments = " --algo cn-heavy/0" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-heavy/tube" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-pico" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-pico/tlo" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "CPU"; Minerset = 3; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
#   [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/rto" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/rwz" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightUpx";       Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/upx2" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/1" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/2" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/xao" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightHeavyXhv";  Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo cn/zls" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = "Randomx";              Type = "CPU"; Minerset = 3; WarmupTimes = @(45, 20);  ExcludePools = @(); Arguments = " --algo rx/0" } # ASIC
    [PSCustomObject]@{ Algorithm = "Ghostrider";           Type = "CPU"; Minerset = 0; WarmupTimes = @(180, 60); ExcludePools = @(); Arguments = " --algo gr" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/arq" } # FPGA
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/keva" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/sfx" } # SRBMinerMulti-v2.3.9 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "CPU"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/wow" }
    [PSCustomObject]@{ Algorithm = "Uplexa";               Type = "CPU"; Minerset = 0; WarmupTimes = @(45, 0);   ExcludePools = @(); Arguments = " --algo rx/upx2" }

    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/ccx" } # CryptoDredge-v0.27.0 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "NVIDIA"; MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "NVIDIA"; MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/half" } # CryptoDredge-v0.27.0 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "NVIDIA"; MinMemGiB = 4;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "NVIDIA"; MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "NVIDIA"; MinMemGiB = 0.25; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "NVIDIA"; MinMemGiB = 0.25; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-pico/tlo" }
#   [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/r" } # ASIC
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyXhv";  Type = "NVIDIA"; MinMemGiB = 4;    Minerset = 1; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo cn/zls" } 
#   [PSCustomObject]@{ Algorithm = "KawPow";               Type = "NVIDIA"; MinMemGiB = 0.77; Minerset = 3; WarmupTimes = @(60, 15); ExcludePools = @(); Arguments = " --algo kawpow" } # Trex-v0.26.8 is fastest, but has 1% miner fee (Broken: https://github.com/RainbowMiner/RainbowMiner/issues/2224)
#   [PSCustomObject]@{ Algorithm = "Randomx";              Type = "NVIDIA"; MinMemGiB = 3;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/0" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "NVIDIA"; MinMemGiB = 4;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/arq" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "NVIDIA"; MinMemGiB = 1;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/keva" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/loki" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/sfx" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "NVIDIA"; MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/wow" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
#   [PSCustomObject]@{ Algorithm = "Uplexa";               Type = "NVIDIA"; MinMemGiB = 0.5;  Minerset = 3; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo rx/upx2" } # GPUs don't do Randomx and when they do it's a watt-wasting miracle anyway
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object BaseName -notin $ExcludePools | Select-Object -Last $(If ($_.Type -eq "CPU") { 1 } Else { $MinerPools[0][$_.Algorithm].Count }))) { 

                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $MemoryGiB -gt $MinMemGiB }) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    $Arguments = $_.Arguments
                    If ($_.Type -eq "CPU") { $Arguments += " --threads=$($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1)" }
                    Else { $Arguments += " --no-cpu --opencl --opencl-platform $($AvailableMiner_Devices.PlatformId) --opencl-devices=$(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" }

                    # Optionally disable dev fee mining, requires change in source code
                    # If ($Config.DisableMinerFee) { 
                    #     $Arguments += " --donate-level 0"
                    #     $_.Fee = 0
                    # }

                    [PSCustomObject]@{ 
                        API         = "XmRig"
                        Arguments   = "$Arguments $(If ($Pool.BaseName -eq "NiceHash") { " --nicehash" } )$(If ($Pool.PoolPorts[1]) { " --tls" } ) --url=$($Pool.Host):$($Pool.PoolPorts | Where-Object  { $_ -ne $null } | Select-Object -Last 1) --user=$($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" }) --pass=$($Pool.Pass)$(If ($Pool.WorkerName) { " --rig-id $($Pool.WorkerName)" }) --keepalive --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$($Config.WorkerName) --api-id=$($Miner_Name) --retries=90 --retry-pause=1"
                        DeviceNames = $AvailableMiner_Devices.Name
                        Fee         = @(0.01) # Dev fee
                        MinerSet    = $_.MinerSet
                        MinerUri    = "http://workers.xmrig.info/worker?url=$([System.Web.HTTPUtility]::UrlEncode("http://127.0.0.1:$($MinerAPIPort)"))?Authorization=Bearer $([System.Web.HTTPUtility]::UrlEncode($Miner_Name))"
                        Name        = $Miner_Name
                        Path        = $Path
                        Port        = $MinerAPIPort
                        Type        = $_.Type
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                        Workers     = @(@{ Pool = $Pool })
                    }
                }
            }
        }
    }
}