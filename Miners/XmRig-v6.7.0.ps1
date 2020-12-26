using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\xmrig.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/xmrig/xmrig-6.7.0.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "AMD"; MinMemGB = 0.02; Command = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "AMD"; MinMemGB = 1;    Command = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "AMD"; MinMemGB = 1;    Command = " --algo cn/ccx" } # SRBMminerMulti-v0.60 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "AMD"; MinMemGB = 1;    Command = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "AMD"; MinMemGB = 1;    Command = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "AMD"; MinMemGB = 1;    Command = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "AMD"; MinMemGB = 1;    Command = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "AMD"; MinMemGB = 1;    Command = " --algo cn/half" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "AMD"; MinMemGB = 1;    Command = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "AMD"; MinMemGB = 1;    Command = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "AMD"; MinMemGB = 0.25; Command = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "AMD"; MinMemGB = 0.25; Command = " --algo cn-pico/tlo" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "AMD"; MinMemGB = 2;    Command = " --algo cn/r" }
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "AMD"; MinMemGB = 2;    Command = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "AMD"; MinMemGB = 2;    Command = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "AMD"; MinMemGB = 2;    Command = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "AMD"; MinMemGB = 2;    Command = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "AMD"; MinMemGB = 2;    Command = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   Type = "AMD"; MinMemGB = 4;    Command = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "AMD"; MinMemGB = 2;    Command = " --algo cn/zls" } 
    [PSCustomObject]@{ Algorithm = "KawPoW";               Type = "AMD"; MinMemGB = 3;    Command = " --algo kawpow" } # NBMiner-v34.5 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "Randomx";              Type = "AMD"; MinMemGB = 2;    Command = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "AMD"; MinMemGB = 2;    Command = " --algo rx/arq" }
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "AMD"; MinMemGB = 1;    Command = " --algo rx/kev" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "AMD"; MinMemGB = 2;    Command = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "AMD"; MinMemGB = 2;    Command = " --algo rx/sfx" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "AMD"; MinMemGB = 2;    Command = " --algo rx/wow" }

    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";         Type = "CPU"; Command = " --algo argon2/chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2WRKZ";           Type = "CPU"; Command = " --algo argon2/wrkz" }
    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "CPU"; Command = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "CPU"; Command = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "CPU"; Command = " --algo cn/ccx" }
#   [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "CPU"; Command = " --algo cn/double" } # XmrStak-v2.10.8 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "CPU"; Command = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "CPU"; Command = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "CPU"; Command = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "CPU"; Command = " --algo cn/half" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "CPU"; Command = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "CPU"; Command = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "CPU"; Command = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "CPU"; Command = " --algo cn-pico/tlo" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "CPU"; Command = " --algo cn/r" }
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "CPU"; Command = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "CPU"; Command = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "CPU"; Command = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "CPU"; Command = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "CPU"; Command = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   Type = "CPU"; Command = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "CPU"; Command = " --algo cn/zls" }
    [PSCustomObject]@{ Algorithm = "Randomx";              Type = "CPU"; Command = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "CPU"; Command = " --algo rx/arq" } # SRBMminerMulti-v0.60 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "CPU"; Command = " --algo rx/kev" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "CPU"; Command = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "CPU"; Command = " --algo rx/sfx" } # SRBMminerMulti-v0.60 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "CPU"; Command = " --algo rx/wow" }

    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "NVIDIA"; MinMemGB = 0.02; Command = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo cn/ccx" } # CryptoDredge-v0.25.1 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo cn/half" } # CryptoDredge-v0.25.1 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      Type = "NVIDIA"; MinMemGB = 0.25; Command = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   Type = "NVIDIA"; MinMemGB = 0.25; Command = " --algo cn-pico/tlo" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";         Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo cn/r" }
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   Type = "NVIDIA"; MinMemGB = 4;    Command = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo cn/zls" } 
    [PSCustomObject]@{ Algorithm = "KawPoW";               Type = "NVIDIA"; MinMemGB = 3;    Command = " --algo kawpow" } # Trex-v0.19.5 is fastest, but has 1% miner fee
    [PSCustomObject]@{ Algorithm = "Randomx";              Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo rx/arq" }
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "NVIDIA"; MinMemGB = 1;    Command = " --algo rx/kev" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo rx/sfx" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "NVIDIA"; MinMemGB = 2;    Command = " --algo rx/wow" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object {

                $Command = $_.Command
                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    If ($_.Type -eq "AMD") { $Command += " --no-cpu --opencl --opencl-devices=$(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" }
                    If ($_.Type -eq "CPU") { $Command += " --threads=$($Miner_Devices.CIM.NumberOfLogicalProcessors -1)" }
                    If ($_.Type -eq "NVIDIA") { $Command += " --no-cpu --cuda --cuda-devices=$(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$Command $(If ($Pools.($_.Algorithm).Name -eq "NiceHash") { " --nicehash" } )$(If ($Pools.($_.Algorithm).SSL) { " --tls" } ) --url=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --keepalive --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$($Config.WorkerName) --api-id=$($Miner_Name) --donate-level 0 --retries=90 --retry-pause=1" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "XmRig"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        WarmupTime = 30 # seconds extra to allow for JIT compilation
                        MinerUri   = "http://workers.xmrig.info/worker?url=$([System.Web.HTTPUtility]::UrlEncode("http://localhost:$($MinerAPIPort)"))?Authorization=Bearer $([System.Web.HTTPUtility]::UrlEncode($Miner_Name))"
                    }
                }
            }
        }
    }
}
