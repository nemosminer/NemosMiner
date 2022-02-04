using module ..\Includes\Include.psm1

$Uri = "https://github.com/xmrig/xmrig/releases/download/v6.16.3/xmrig-6.16.3-msvc-win64.zip"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\xmrig.exe"
$DeviceEnumerator = "PlatformId_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "AMD"; MinMemGB = 0.02; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/ccx" } # SRBMinerMulti-v0.8.9 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/half" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "AMD"; MinMemGB = 4;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "AMD"; MinMemGB = 4;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "AMD"; MinMemGB = 0.25; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "AMD"; MinMemGB = 0.25; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-pico/tlo" }
    # [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/r" } # Is never profitable
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   Type = "AMD"; MinMemGB = 4;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo cn/zls" } 
    [PSCustomObject]@{ Algorithm = "KawPoW";               Type = "AMD"; MinMemGB = 3;    MinerSet = 2; WarmupTimes = @(60, 15); Arguments = " --algo kawpow" } # NBMiner-v40.1 is fastest, but has 2% miner fee
    # [PSCustomObject]@{ Algorithm = "Randomx";              Type = "AMD"; MinMemGB = 3;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/0" } # Not profitable at all
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "AMD"; MinMemGB = 4;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/arq" }
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "AMD"; MinMemGB = 1;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/keva" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "AMD"; MinMemGB = 2;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/sfx" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "AMD"; MinMemGB = 3;    MinerSet = 2; WarmupTimes = @(45, 0); Arguments = " --algo rx/wow" }
    [PSCustomObject]@{ Algorithm = "Uplexa";               Type = "AMD"; MinMemGB = 0.25; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/upx2" }

    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";         Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo argon2/chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2ChukwaV2";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo argon2/chukwav2" }
    [PSCustomObject]@{ Algorithm = "Argon2Ninja";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo argon2/ninja" }
    [PSCustomObject]@{ Algorithm = "Argon2WRKZ";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo argon2/wrkz" }
    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo astrobwt" }
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
    # [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/r" } # Is never profitable
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/upx2" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/zls" }
    [PSCustomObject]@{ Algorithm = "Randomx";              Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/arq" } # SRBMinerMulti-v0.8.9 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/keva" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/sfx" } # SRBMinerMulti-v0.8.9 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "CPU"; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/wow" }
    [PSCustomObject]@{ Algorithm = "Uplexa";               Type = "CPU"; MinMemGB = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/upx2" }

    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "NVIDIA"; MinMemGB = 0.02; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/ccx" } # CryptoDredge-v0.26.0 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/half" } # CryptoDredge-v0.26.0 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "NVIDIA"; MinMemGB = 4;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "NVIDIA"; MinMemGB = 0.25; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "NVIDIA"; MinMemGB = 0.25; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-pico/tlo" }
    # [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/r" } # Is never profitable
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   Type = "NVIDIA"; MinMemGB = 4;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo cn/zls" } 
    [PSCustomObject]@{ Algorithm = "KawPoW";               Type = "NVIDIA"; MinMemGB = 3;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo kawpow" } # Trex-v0.25.2 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "Randomx";              Type = "NVIDIA"; MinMemGB = 3;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "NVIDIA"; MinMemGB = 4;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/arq" }
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "NVIDIA"; MinMemGB = 1;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/keva" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/sfx" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "NVIDIA"; MinMemGB = 2;    MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/wow" }
    [PSCustomObject]@{ Algorithm = "Uplexa";               Type = "NVIDIA"; MinMemGB = 0.5;  MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo rx/upx2" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' ' -replace ' '

                $Arguments = $_.Arguments

                If ($_.Type -eq "CPU") { $Arguments += " --threads=$($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1)" }
                Else { $Arguments += " --no-cpu --opencl --opencl-platform $($AvailableMiner_Devices.PlatformId) --opencl-devices=$(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" }

                # Optionally disable dev fee mining, requires chenge in source code
                # If ($Config.DisableMinerFee) { 
                #     $_.Arguments += " --donate-level 0"
                #     $_.Fee = 0
                # }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $_.Type
                    Path        = $Path
                    Arguments   = ("$($Arguments) $(If ($Pools.($_.Algorithm).BaseName -eq "NiceHash") { " --nicehash" } )$(If ($Pools.($_.Algorithm).SSL) { " --tls" } ) --url=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --rig-id $($Pools.($_.Algorithm).User -split "\." | Select-Object -Index 1) --keepalive --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$($Config.WorkerName) --api-id=$($Miner_Name) --retries=90 --retry-pause=1" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
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
