If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "CPU" -or ($_.Type -eq "AMD" -and $_.Architecture -ne "Other") -or ($_.Type -eq "NVIDIA" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0") })) { Return }

$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/1.1.3/SRBMiner-Multi-1-1-3-win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
#   [PSCustomObject]@{ Algorithms = @("0x10");                     Type = "AMD"; Fee = @(0.0085);       MinMemGB = 2;                                           MinerSet = 0; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm 0x10") }
#   [PSCustomObject]@{ Algorithms = @("Argon2d16000");             Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm argon2d_16000") }
#   [PSCustomObject]@{ Algorithms = @("Argon2d500");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm argon2d_dynamic") }
#   [PSCustomObject]@{ Algorithms = @("Argon2Chukwa");             Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm argon2id_chukwa") }
#   [PSCustomObject]@{ Algorithms = @("Argon2Chukwa2");            Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm argon2id_chukwa2") }
#   [PSCustomObject]@{ Algorithms = @("Autolykos2");               Type = "AMD"; Fee = @(0.01);         MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB + 0.42;  MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm autolykos2") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "HeavyHash");  Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB + 0.42;  MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm autolykos2", " --algorithm heavyhash") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "kHeavyHash"); Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB + 0.42;  MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm autolykos2", " --algorithm kaspa") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "SHA256dt");   Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB + 0.42;  MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm autolykos2", " --algorithm sha256dt") }
#   [PSCustomObject]@{ Algorithms = @("Blake2b");                  Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm blake2b") } # Algorithm broken
#   [PSCustomObject]@{ Algorithms = @("Blake2s");                  Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm blake2s") } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Blake3");                   Type = "AMD"; Fee = @(0.0085);       MinMemGB = 2;                                           MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm blake3_alephium") }
#   [PSCustomObject]@{ Algorithms = @("CircCash");                 Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm circcash") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightCcx");           Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm cryptonight_ccx") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightGpu");           Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm cryptonight_gpu") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightTalleo");        Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm cryptonight_talleo") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightUpx");           Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 1; WarmupTimes = @(60, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm cryptonight_upx") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightTurtle");        Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm cryptonight_turtle") } # TeamRedMiner-v0.10.7 is fastest
#   [PSCustomObject]@{ Algorithms = @("CryptonightHeavyXhv")       Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm cryptonight_xhv") }
#   [PSCustomObject]@{ Algorithms = @("CurveHash");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 2;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm curvehash") }
#   [PSCustomObject]@{ Algorithms = @("DynamoCoin");               Type = "AMD"; Fee = @(0.01);         MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm dynamo") } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
#   [PSCustomObject]@{ Algorithms = @("EtcHash");                  Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;     MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm etchash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHash");     Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;     MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm etchash", " --algorithm heavyhash") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");    Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;     MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm etchash", " --algorithm kaspa") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA256dt");      Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;     MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm etchash", " --algorithm sha256dt") }
#   [PSCustomObject]@{ Algorithms = @("Ethash");                   Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;      MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@("ZergPool"), @()); Arguments = @(" --algorithm ethash") } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "Heavyhash");      Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;      MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm ethash", " --algorithm heavyhash") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyhash");     Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;      MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm ethash", " --algorithm kaspa") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "SHA256dt");       Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;      MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm ethash", " --algorithm sha256dt") }
#   [PSCustomObject]@{ Algorithms = @("EvrProgPow");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = $MinerPools[0].EvrProgPow.DAGSizeGB + 0.42;  MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm evrprogpow") }
#   [PSCustomObject]@{ Algorithms = @("FiroPow");                  Type = "AMD"; Fee = @(0.0085);       MinMemGB = $MinerPools[0].FiroPow.DAGSizeGB + 0.42;     MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm firopow") }
#   [PSCustomObject]@{ Algorithms = @("FrkHash");                  Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm frkhash") }
#   [PSCustomObject]@{ Algorithms = @("HeavyHash");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm heavyhash") }
    [PSCustomObject]@{ Algorithms = @("HeavyHash", "Autolykos2");  Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[1].Autolykos2.DAGSizeGB + 0.42;  MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm heavyhash", " --algorithm autolykos2") }
    [PSCustomObject]@{ Algorithms = @("HeavyHash", "EtcHash");     Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[1].Etchash.DAGSizeGB + 0.42;     MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm heavyhash", " --algorithm etchash") }
    [PSCustomObject]@{ Algorithms = @("Heavyhash", "Ethash");      Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[1].Ethash.DAGSizeGB + 0.42;      MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm heavyhash", " --algorithm ethash") }
#   [PSCustomObject]@{ Algorithms = @("Kangaroo12");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm k12") }
#   [PSCustomObject]@{ Algorithms = @("kHeavyHash");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm kaspa") }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash", "Autolykos2"); Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[1].Autolykos2.DAGSizeGB + 0.42;  MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm kaspa", " --algorithm autolykos2") }
    [PSCustomObject]@{ Algorithms = @("kHeavyhash", "EtcHash");    Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[1].EtcHash.DAGSizeGB + 0.42;     MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm kaspa", " --algorithm etchash") }
    [PSCustomObject]@{ Algorithms = @("kHeavyhash", "Ethash");     Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[1].Ethash.DAGSizeGB + 0.42;      MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm kaspa", " --algorithm ethash") }
#   [PSCustomObject]@{ Algorithms = @("KawPow");                   Type = "AMD"; Fee = @(0.0085);       MinMemGB = $MinerPools[0].KawPow.DAGSizeGB + 0.42;      MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm kawpow") }
#   [PSCustomObject]@{ Algorithms = @("Keccak");                   Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm keccak") } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Lyra2v2Webchain");          Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm lyra2v2_webchain") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowEpic");              Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPowEpic.DAGSizeGB + 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm progpow_epic") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowSero");              Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPowSero.DAGSizeGB + 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm progpow_sero") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowVeil");              Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPowVeil.DAGSizeGB + 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm progpow_veil") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowVeriblock");         Type = "AMD"; Fee = @(0.0065);       MinMemGB = 2;                                           MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm progpow_veriblock") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowZ");                 Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPowZ.DAGSizeGB + 0.42;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm progpow_zano") }
#   [PSCustomObject]@{ Algorithms = @("Pufferfish2BMB");           Type = "AMD"; Fee = @(0.01);         MinMemGB = 8;                                           MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm pufferfish2bmb") }
#   [PSCustomObject]@{ Algorithms = @("SHA3d");                    Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm sha3d") }
#   [PSCustomObject]@{ Algorithms = @("SHA256dt");                 Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm sha256dt") }
#   [PSCustomObject]@{ Algorithms = @("SHA512256d");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm sha512_256d_radiant") }
#   [PSCustomObject]@{ Algorithms = @("VerusHash");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm verushash") }
#   [PSCustomObject]@{ Algorithms = @("VertHash");                 Type = "AMD"; Fee = @(0.0125);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat") }
#   [PSCustomObject]@{ Algorithms = @("Yescrypt");                 Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(90, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm yescrypt") }
#   [PSCustomObject]@{ Algorithms = @("YescryptR8");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(90, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm yescryptr8") }
#   [PSCustomObject]@{ Algorithms = @("YescryptR16");              Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(90, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm yescryptr16") }
#   [PSCustomObject]@{ Algorithms = @("YescryptR32");              Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                           MinerSet = 0; WarmupTimes = @(90, 30); ExcludeGPUArchitecture = @("RDNA3"); ExcludePools = @(@(), @());           Arguments = @(" --algorithm yescryptr32") }

#   [PSCustomObject]@{ Algorithms = @("0x10");                 Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm 0x10") }
#   [PSCustomObject]@{ Algorithms = @("Argon2d16000");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm argon2d_16000") }
#   [PSCustomObject]@{ Algorithms = @("Argon2d500");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm argon2d_dynamic") }
#   [PSCustomObject]@{ Algorithms = @("Argon2Chukwa");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm argon2id_chukwa") }
#   [PSCustomObject]@{ Algorithms = @("Argon2Chukwa2");        Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm argon2id_chukwa2") }
#   [PSCustomObject]@{ Algorithms = @("Autolykos2");           Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(120, 15); ExcludePools = @(@(), @()); Arguments = @(" --algorithm autolykos2 --gpu-autolykos2-preload 3)" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("Blake2b");              Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(90, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm blake2b") } # Algo broken
#   [PSCustomObject]@{ Algorithms = @("Blake2s");              Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm blake2s") } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Blake3");               Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm blake3_alephium") }
#   [PSCustomObject]@{ Algorithms = @("CircCash");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm circcash") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightCcx");       Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm cryptonight_ccx") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightGpu");       Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm cryptonight_gpu") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightTalleo");    Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm cryptonight_talleo") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightTurtle");    Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm cryptonight_turtle") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightUpx");       Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm cryptonight_upx") }
#   [PSCustomObject]@{ Algorithms = @("CryptonightHeavyxXhv"); Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm cryptonight_xhv") }
#   [PSCustomObject]@{ Algorithms = @("Cosa");                 Type = "CPU"; Fee = @(0.02);   MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm cosa") }
#   [PSCustomObject]@{ Algorithms = @("CpuPower");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm cpupower") }
#   [PSCustomObject]@{ Algorithms = @("CurveHash");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm curvehash") }
#   [PSCustomObject]@{ Algorithms = @("DynamoCoin");           Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm dynamo") } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
#   [PSCustomObject]@{ Algorithms = @("EtcHash");              Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm etchash") } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("Ethash");               Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm ethash") } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("EvrProgPow");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm evrprogpow") } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("FiroPow");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm firopow") } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("FrkHash");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm frkhash") }
#   [PSCustomObject]@{ Algorithms = @("Ghostrider");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm ghostrider") }
#   [PSCustomObject]@{ Algorithms = @("HeavyHash");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm heavyhash") }
#   [PSCustomObject]@{ Algorithms = @("K12");                  Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm K12") }
#   [PSCustomObject]@{ Algorithms = @("KawPow");               Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm kawpow") } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("kHeavyHash");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm kaspa") }
#   [PSCustomObject]@{ Algorithms = @("Keccak");               Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm keccak") } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Lyra2v2Webchain");      Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm lyra2v2_webchain") }
#   [PSCustomObject]@{ Algorithms = @("Mike");                 Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm mike") }
#   [PSCustomObject]@{ Algorithms = @("Minotaur");             Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm minotaur") }
#   [PSCustomObject]@{ Algorithms = @("Minotaurx");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm minotaurx") }
#   [PSCustomObject]@{ Algorithms = @("Panthera");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm panthera") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowEpic");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm progpow_epic") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowSero");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm progpow_sero") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowVeil");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm progpow_veil") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowVeriblock");     Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm progpow_veriblock") }
#   [PSCustomObject]@{ Algorithms = @("ProgPowZ");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm progpow_zano") }
#   [PSCustomObject]@{ Algorithms = @("Pufferfish2BMB");       Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm pufferfish2bmb") }
#   [PSCustomObject]@{ Algorithms = @("SHA256d");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 30);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm sha256dt") }
#   [PSCustomObject]@{ Algorithms = @("SHA512256d");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 30);  ExcludePools = @(@(), @()); Arguments = @(" --algorithm sha512_256d_radiant") }
#   [PSCustomObject]@{ Algorithms = @("RandomxArq");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomarq --randomx-use-1gb-pages") }
#   [PSCustomObject]@{ Algorithms = @("RandomxEpic");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomepic") }
#   [PSCustomObject]@{ Algorithms = @("RandomGrft");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomgrft --randomx-use-1gb-pages") }
#   [PSCustomObject]@{ Algorithms = @("RandomHash2");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomarq --randomx-use-1gb-pages") }
#   [PSCustomObject]@{ Algorithms = @("RandomL");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randoml --randomx-use-1gb-pages") }
#   [PSCustomObject]@{ Algorithms = @("RandomSfx");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomsfx --randomx-use-1gb-pages") }
#   [PSCustomObject]@{ Algorithms = @("RandomWow");            Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomwow --randomx-use-1gb-pages") }
#   [PSCustomObject]@{ Algorithms = @("RandomX");              Type = "CPU"; Fee = @(0.0085); MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomx --randomx-use-1gb-pages") } # Not profitable at all
#   [PSCustomObject]@{ Algorithms = @("RandomxKeva");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomkeva --randomx-use-1gb-pages") }
#   [PSCustomObject]@{ Algorithms = @("RandomxL");             Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomxl --randomx-use-1gb-pages") } # XmRig-v6.18.1 is fastest
#   [PSCustomObject]@{ Algorithms = @("RandomYada");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm randomyada") }
#   [PSCustomObject]@{ Algorithms = @("ScryptN2");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm scryptn2") }
#   [PSCustomObject]@{ Algorithms = @("SHA3d");                Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm sha3d") }
#   [PSCustomObject]@{ Algorithms = @("UbqHash");              Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm ubqhash") } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("VertHash");             Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat") }
#   [PSCustomObject]@{ Algorithms = @("VerusHash");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm verushash") }
#   [PSCustomObject]@{ Algorithms = @("Xdag");                 Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm xdag") }
#   [PSCustomObject]@{ Algorithms = @("YescryptR16");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yescryptr16") }
#   [PSCustomObject]@{ Algorithms = @("YescryptR32");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yescryptr32") }
#   [PSCustomObject]@{ Algorithms = @("YescryptR8");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yescryptr8") }
#   [PSCustomObject]@{ Algorithms = @("Yespower");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespower") }
#   [PSCustomObject]@{ Algorithms = @("Yespower2b");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespower2b") }
#   [PSCustomObject]@{ Algorithms = @("YespowerARWN");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespowerarwn") }
#   [PSCustomObject]@{ Algorithms = @("YespowerIc");           Type = "CPU"; Fee = @(0)     ; MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespoweric") }
#   [PSCustomObject]@{ Algorithms = @("YespowerIots");         Type = "CPU"; Fee = @(0)     ; MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespoweriots") }
#   [PSCustomObject]@{ Algorithms = @("YespowerItc");          Type = "CPU"; Fee = @(0)     ; MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespoweritc") }
#   [PSCustomObject]@{ Algorithms = @("YespowerLitb");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespowerlitb") }
#   [PSCustomObject]@{ Algorithms = @("YespowerLtncg");        Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespowerltncg") }
#   [PSCustomObject]@{ Algorithms = @("YespowerMgpc");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespowermgpc") }
#   [PSCustomObject]@{ Algorithms = @("YespowerR16");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespowerr16") }
#   [PSCustomObject]@{ Algorithms = @("YespowerRes");          Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespoweres") }
#   [PSCustomObject]@{ Algorithms = @("YespowerSugar");        Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespowersugar") }
#   [PSCustomObject]@{ Algorithms = @("YespowerTide");         Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespowertide") }
#   [PSCustomObject]@{ Algorithms = @("YespowerUrx");          Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yespowerurx") }
#   [PSCustomObject]@{ Algorithms = @("Yescrypt");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(90, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm yescrypt") }
#   [PSCustomObject]@{ Algorithms = @("Zentoshi");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePools = @(@(), @()); Arguments = @(" --algorithm balloon_zentoshi") }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) } | Where-Object { -not $_.ExcludePools[0] -or $MinerPools[0].($_.Algorithms[0]).BaseName -notin $_.ExcludePools[0] } | Where-Object { -not $_.ExcludePools[1] -or $MinerPools[1].($_.Algorithms[1]).BaseName -notin $_.ExcludePools[1] } ) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $MinMemGB = $_.MinMemGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.MemoryGB -gt $MinMemGB } | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithms[1]) { "$($_.Algorithms[0])&$($_.Algorithms[1])" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algorithm") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments = ""
                For ($AlgoIndex = 0; $AlgoIndex -lt $_.Algorithms.Count; $AlgoIndex ++) { 
                    $Arguments += "$($_.Arguments[$AlgoIndex]) --pool $($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).Host):$($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).PoolPorts | Select-Object -Last 1) --wallet $($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).User)"
                    $Arguments += " --password $($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).Pass)$(If ($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).BaseName -eq "ProHashing" -and $_.Algorithms[$AlgoIndex] -eq "Ethash") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGB - $MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).DAGSizeGB))" })"
                    If ($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).WorkerName) { " --worker $($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).WorkerName)" }
                    $Arguments += If ($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).PoolPorts[1]) { " --tls true" } Else { " --tls false" }
                    $Arguments += If ($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).DAGsizeGB -ne $null -and $MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { " --nicehash true" } Else { " --nicehash false" }
                    If ($MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).DAGsizeGB -ne $null -and $MinerPools[$AlgoIndex].($_.Algorithms[$AlgoIndex]).BaseName -eq "ProHashing") { $Arguments += " --esm 1" }
                }

                If (($AvailableMiner_Devices.Type | Select-Object -Unique) -eq "CPU") { 
                    $Arguments += " --cpu-threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --disable-gpu"
                }
                Else { 
                    $Arguments += " --gpu-id $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',') --disable-cpu"
                }

                $PrerequisitePath = ""
                $PrerequisiteURI = ""
                If ($_.Algorithm -eq "VertHash" -and -not (Test-Path -Path ".\Bin\$($Name)\VertHash.dat" -ErrorAction SilentlyContinue)) { 
                    If ((Get-Item -Path $Variables.VerthashDatPath).length -eq 1283457024) { 
                        If (Test-Path -Path .\Bin\$($Name) -PathType Container) { 
                            New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath | Out-Null
                        }
                    }
                    Else { 
                        $PrerequisitePath = $Variables.VerthashDatPath
                        $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                    }
                }

                If ($Variables.UseMinerTweaks -and $_.Type -eq "CPU") { 
                    $Arguments += " --force-msr-tweaks"
                }

                [PSCustomObject]@{ 
                    Name             = $Miner_Name
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Type             = ($AvailableMiner_Devices.Type | Select-Object -unique)
                    Path             = $Path
                    Arguments        = ("$($Arguments) --gpu-auto-tune 2 --api-rig-name $($Config.WorkerName) --api-enable --api-port $MinerAPIPort" -replace "\s+", " ").trim()
                    Algorithms       = @($_.Algorithms[0], $_.Algorithms[1] | Select-Object)
                    API              = "SRBMiner"
                    Port             = $MinerAPIPort
                    URI              = $Uri
                    Fee              = $_.Fee # Dev fee
                    MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/stats"
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                }
            }
        }
    }
}
