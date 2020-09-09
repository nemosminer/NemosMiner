using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/XmRig/XMRigv633.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstroBWT";             MinMemGB = 0.02; Type = "AMD"   ; Command = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          MinMemGB = 1;    Type = "AMD"   ; Command = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       MinMemGB = 1;    Type = "AMD"   ; Command = " --algo cn/ccx" } #SRBMminerMulti-v0.5. is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    MinMemGB = 1;    Type = "AMD"   ; Command = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      MinMemGB = 1;    Type = "AMD"   ; Command = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      MinMemGB = 1;    Type = "AMD"   ; Command = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    MinMemGB = 1;    Type = "AMD"   ; Command = " --algo cn-lite/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      MinMemGB = 1;    Type = "AMD"   ; Command = " --algo cn/half" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     MinMemGB = 1;    Type = "AMD"   ; Command = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; MinMemGB = 1;    Type = "AMD"   ; Command = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      MinMemGB = 0.25; Type = "AMD"   ; Command = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   MinMemGB = 0.25; Type = "AMD"   ; Command = " --algo cn-pico/tlo" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";         MinMemGB = 2;    Type = "AMD"   ; Command = " --algo cn/r" }
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       MinMemGB = 2;    Type = "AMD"   ; Command = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       MinMemGB = 2;    Type = "AMD"   ; Command = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        MinMemGB = 2;    Type = "AMD"   ; Command = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        MinMemGB = 2;    Type = "AMD"   ; Command = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       MinMemGB = 2;    Type = "AMD"   ; Command = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   MinMemGB = 4;    Type = "AMD"   ; Command = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       MinMemGB = 2;    Type = "AMD"   ; Command = " --algo cn/zls" } 
#   [PSCustomObject]@{ Algorithm = "KawPoW";               MinMemGB = 3;    Type = "AMD"   ; Command = " --algo kawpow" } #NBMiner-v31.1 is fastest
    [PSCustomObject]@{ Algorithm = "Randomx";              MinMemGB = 2;    Type = "AMD"   ; Command = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           MinMemGB = 2;    Type = "AMD"   ; Command = " --algo rx/arq" }
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          MinMemGB = 1;    Type = "AMD"   ; Command = " --algo rx/kev" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          MinMemGB = 2;    Type = "AMD"   ; Command = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           MinMemGB = 2;    Type = "AMD"   ; Command = " --algo rx/sfx" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";           MinMemGB = 2;    Type = "AMD"   ; Command = " --algo rx/wow" }

    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";         Type = "CPU"; Command = " --algo argon2/chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2WRKZ";           Type = "CPU"; Command = " --algo argon2/wrkz" }
    [PSCustomObject]@{ Algorithm = "AstroBWT";             Type = "CPU"; Command = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          Type = "CPU"; Command = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Type = "CPU"; Command = " --algo cn/ccx" }
#   [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Type = "CPU"; Command = " --algo cn/double" } #XmrStak-v2.10.8 is fastest
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
    [PSCustomObject]@{ Algorithm = "RandomxArq";           Type = "CPU"; Command = " --algo rx/arq" } #SRBMminerMulti-v0.5.1 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          Type = "CPU"; Command = " --algo rx/kev" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          Type = "CPU"; Command = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           Type = "CPU"; Command = " --algo rx/sfx" } #SRBMminerMulti-v0.5.1 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "RandomxWow";           Type = "CPU"; Command = " --algo rx/wow" }

    [PSCustomObject]@{ Algorithm = "AstroBWT";             MinMemGB = 0.02; Type = "NVIDIA"; Command = " --algo astrobwt" }
    [PSCustomObject]@{ Algorithm = "Cryptonight";          MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo cn/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo cn/ccx" } #CryptoDredge-v0.25.1 is fastest, keep enabled for IgnoreMinersWithFees
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo cn/double" }
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo cn/fast" }
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo cn-lite/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo cn-lite/1" }
#   [PSCustomObject]@{ Algorithm = "CryptonightHalf";      MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo cn/half" } #CryptoDredge-v0.25.1 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo cn-heavy/0" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo cn-heavy/tube" }
    [PSCustomObject]@{ Algorithm = "CryptonightPico";      MinMemGB = 0.25; Type = "NVIDIA"; Command = " --algo cn-pico" }
    [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   MinMemGB = 0.25; Type = "NVIDIA"; Command = " --algo cn-pico/tlo" }
    [PSCustomObject]@{ Algorithm = "CryptonightR";         MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo cn/r" }
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo cn/rto" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo cn/rwz" }
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo cn/1" }
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo cn/2" }
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo cn/xao" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   MinMemGB = 4;    Type = "NVIDIA"; Command = " --algo cn-heavy/xhv" }
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo cn/zls" } 
#   [PSCustomObject]@{ Algorithm = "KawPoW";               MinMemGB = 3;    Type = "NVIDIA"; Command = " --algo kawpow" } #NBMiner-v31.1 is fastest
    [PSCustomObject]@{ Algorithm = "Randomx";              MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo rx/0" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";           MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo rx/arq" }
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          MinMemGB = 1;    Type = "NVIDIA"; Command = " --algo rx/kev" }
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo rx/loki" }
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo rx/sfx" }
    [PSCustomObject]@{ Algorithm = "RandomxWow";           MinMemGB = 2;    Type = "NVIDIA"; Command = " --algo rx/wow" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    If ($_.Type -eq "AMD") { $_.Command += " --no-cpu --opencl --opencl-devices=$(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" }
                    If ($_.Type -eq "CPU") { $_.Command += " --threads=$($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --cpu-priority=1" }
                    If ($_.Type -eq "NVIDIA") { $_.Command += " --no-cpu --cuda --cuda-devices=$(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$($_.Command) $(If ($Pools.($_.Algorithm).Name -eq "NiceHash") { " --nicehash" } )$(If ($Pools.($_.Algorithm).SSL) { " --tls" } ) --url=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --keepalive --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$($Config.WorkerName) --api-id=$($Miner_Name) --donate-level 0 --retries=90 --retry-pause=1" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "XmRig"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        WarmupTime = 60 #seconds
                        MinerUri   = "http://workers.xmrig.info/worker?url=$([System.Web.HTTPUtility]::UrlEncode("http://localhost:$($MinerAPIPort)"))?Authorization=Bearer $([System.Web.HTTPUtility]::UrlEncode($Miner_Name))"
                    }
                }
            }
        }
    }
}
