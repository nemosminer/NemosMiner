using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { (($_.Type -eq "AMD" -and $_.Architecture -ne "Other") -or $_.OpenCL.ClVersion -ge "OpenCL C 2.0") -or $_.Type -eq "CPU" })) { Return }

$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/1.1.0/SRBMiner-Multi-1-1-0-win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
     [PSCustomObject]@{ Algorithms = @("0x10");                      Type = "AMD"; Fee = @(0.0085);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm 0x10" }
     [PSCustomObject]@{ Algorithms = @("Argon2d16000");              Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm argon2d_16000" }
     [PSCustomObject]@{ Algorithms = @("Argon2d500");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm argon2d_dynamic" }
     [PSCustomObject]@{ Algorithms = @("Argon2Chukwa");              Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm argon2id_chukwa" }
     [PSCustomObject]@{ Algorithms = @("Argon2Chukwa2");             Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm argon2id_chukwa2" }
     [PSCustomObject]@{ Algorithms = @("Autolykos2");                Type = "AMD"; Fee = @(0.01);         MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm autolykos2" }
#    [PSCustomObject]@{ Algorithms = @("Autolykos2", "HeavyHash");   Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm autolykos2 --algorithm heavyhash" }
     [PSCustomObject]@{ Algorithms = @("Blake2b");                   Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @("Zpool")    ; Arguments = " --algorithm blake2b" } # Algorithm broken
     [PSCustomObject]@{ Algorithms = @("Blake2s");                   Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm blake2s" }
     [PSCustomObject]@{ Algorithms = @("Blake3");                    Type = "AMD"; Fee = @(0.0085);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm blake3_alephium" }
     [PSCustomObject]@{ Algorithms = @("CircCash");                  Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm circcash" }
     [PSCustomObject]@{ Algorithms = @("CryptonightCcx");            Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm cryptonight_ccx" }
     [PSCustomObject]@{ Algorithms = @("CryptonightGpu");            Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm cryptonight_gpu" }
     [PSCustomObject]@{ Algorithms = @("CryptonightTalleo");         Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm cryptonight_talleo" }
     [PSCustomObject]@{ Algorithms = @("CryptonightUpx");            Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm cryptonight_upx" }
     [PSCustomObject]@{ Algorithms = @("CryptonightTurtle");         Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm cryptonight_turtle" } # TeamRedMiner-v0.10.4.1 is fastest
     [PSCustomObject]@{ Algorithms = @("CryptonightHeavyXhv");       Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm cryptonight_xhv" }
     [PSCustomObject]@{ Algorithms = @("CurveHash");                 Type = "AMD"; Fee = @(0.0085);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm curvehash" }
     [PSCustomObject]@{ Algorithms = @("DynamoCoin");                Type = "AMD"; Fee = @(0.01);         MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
     [PSCustomObject]@{ Algorithms = @("EtcHash");                   Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#    [PSCustomObject]@{ Algorithms = @("EtcHash", "HeavyHash");      Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm etchash --algorithm heavyhash --gpu-auto-tune 2" }
     [PSCustomObject]@{ Algorithms = @("Ethash");                    Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludeGPUArchitecture = @();        ExcludePool = @()           ; Arguments = " --algorithm ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#    [PSCustomObject]@{ Algorithms = @("Ethash", "Heavyhash");       Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm ethash --algorithm heavyhash --gpu-auto-tune 2" }
     [PSCustomObject]@{ Algorithms = @("EthashLowMem");              Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludeGPUArchitecture = @();        ExcludePool = @("ProHashing"); Arguments = " --algorithm ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#    [PSCustomObject]@{ Algorithms = @("EthashLowMem", "HeavyHash"); Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm ethash --algorithm heavyhash --gpu-auto-tune 2" }
     [PSCustomObject]@{ Algorithms = @("FiroPoW");                   Type = "AMD"; Fee = @(0.0085);       MinMemGB = $MinerPools[0].FiroPoW.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(60, 75); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm firopow" }
     [PSCustomObject]@{ Algorithms = @("FrkHash");                   Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm frkhash" }
     [PSCustomObject]@{ Algorithms = @("HeavyHash");                 Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm heavyhash" }
     [PSCustomObject]@{ Algorithms = @("Kangaroo12");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm k12" }
     [PSCustomObject]@{ Algorithms = @("kHeavyHash");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm kaspa" }
     [PSCustomObject]@{ Algorithms = @("KawPoW");                    Type = "AMD"; Fee = @(0.0085);       MinMemGB = $MinerPools[0].KawPoW.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(90, 75); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm kawpow" }
#    [PSCustomObject]@{ Algorithms = @("Keccak");                    Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm keccak" } # ASIC
     [PSCustomObject]@{ Algorithms = @("Lyra2v2Webchain");           Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm lyra2v2_webchain" }
     [PSCustomObject]@{ Algorithms = @("ProgPoWEpic");               Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPoWEpic.DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm progpow_epic" }
     [PSCustomObject]@{ Algorithms = @("ProgPoWSero");               Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPoWSero.DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm progpow_sero" }
     [PSCustomObject]@{ Algorithms = @("ProgPoWVeil");               Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPoWVeil.DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm progpow_veil" }
     [PSCustomObject]@{ Algorithms = @("ProgPoWVeriblock");          Type = "AMD"; Fee = @(0.0065);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm progpow_veriblock" }
     [PSCustomObject]@{ Algorithms = @("ProgPoWZ");                  Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPoWZ.DAGSizeGB;     MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm progpow_zano" }
     [PSCustomObject]@{ Algorithms = @("Pufferfish2BMB");            Type = "AMD"; Fee = @(0.01);         MinMemGB = 8;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePool = @()            ; Arguments = " --algorithm pufferfish2bmb" }
     [PSCustomObject]@{ Algorithms = @("SHA512256d");                Type = "AMD"; Fee = @(0.01);         MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm sha512_256d_radiant" }
     [PSCustomObject]@{ Algorithms = @("SHA3d");                     Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm sha3d" }
     [PSCustomObject]@{ Algorithms = @("VerusHash");                 Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm verushash" }
     [PSCustomObject]@{ Algorithms = @("VertHash");                  Type = "AMD"; Fee = @(0.0125);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
     [PSCustomObject]@{ Algorithms = @("Yescrypt");                  Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm yescrypt" }
     [PSCustomObject]@{ Algorithms = @("YescryptR8");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm yescryptr8" }
     [PSCustomObject]@{ Algorithms = @("YescryptR16");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm yescryptr16" }
     [PSCustomObject]@{ Algorithms = @("YescryptR32");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 30); ExcludeGPUArchitecture = @();        ExcludePool = @()            ; Arguments = " --algorithm yescryptr32" }

    [PSCustomObject]@{ Algorithms = @("0x10");                 Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm 0x10" }
    [PSCustomObject]@{ Algorithms = @("Argon2d16000");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePool = @()       ; Arguments = " --algorithm argon2d_16000" }
    [PSCustomObject]@{ Algorithms = @("Argon2d500");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePool = @()       ; Arguments = " --algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithms = @("Argon2Chukwa");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithms = @("Argon2Chukwa2");        Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm argon2id_chukwa2" }
#   [PSCustomObject]@{ Algorithms = @("Autolykos2");           Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(120, 15); ExcludePool = @()       ; Arguments = " --algorithm autolykos2 --gpu-autolykos2-preload 3" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithms = @("Blake2b");              Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(90, 15);  ExcludePool = @("Zpool"); Arguments = " --algorithm blake2b" } # Algo broken
    [PSCustomObject]@{ Algorithms = @("Blake2s");              Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithms = @("Blake3");               Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm blake3_alephium" }
    [PSCustomObject]@{ Algorithms = @("CircCash");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithms = @("CryptonightCcx");       Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithms = @("CryptonightGpu");       Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithms = @("CryptonightTalleo");    Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_talleo" }
    [PSCustomObject]@{ Algorithms = @("CryptonightTurtle");    Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_turtle" }
    [PSCustomObject]@{ Algorithms = @("CryptonightUpx");       Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_upx" }
    [PSCustomObject]@{ Algorithms = @("CryptonightHeavyxXhv"); Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithms = @("Cosa");                 Type = "CPU"; Fee = @(0.02);   MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePool = @()       ; Arguments = " --algorithm cosa" }
    [PSCustomObject]@{ Algorithms = @("CpuPower");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cpupower" }
    [PSCustomObject]@{ Algorithms = @("CurveHash");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm curvehash" }
#   [PSCustomObject]@{ Algorithms = @("DynamoCoin");           Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
#   [PSCustomObject]@{ Algorithms = @("EtcHash");              Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm etchash" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("Ethash");               Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm ethash" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");         Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm ethash" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithms = @("FiroPoW");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm firopow" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithms = @("FrkHash");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm frkhash" }
    [PSCustomObject]@{ Algorithms = @("GhostRider");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm ghostrider" }
    [PSCustomObject]@{ Algorithms = @("HeavyHash");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm heavyhash" }
    [PSCustomObject]@{ Algorithms = @("K12");                  Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm K12" }
#   [PSCustomObject]@{ Algorithms = @("KawPoW");               Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm kawpow" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm kaspa" }
#   [PSCustomObject]@{ Algorithms = @("Keccak");               Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm keccak" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Lyra2v2Webchain");      Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm lyra2v2_webchain" }
    [PSCustomObject]@{ Algorithms = @("Mike");                 Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm mike" }
    [PSCustomObject]@{ Algorithms = @("Minotaur");             Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm minotaur" }
    [PSCustomObject]@{ Algorithms = @("Minotaurx");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm minotaurx" }
    [PSCustomObject]@{ Algorithms = @("Panthera");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm panthera" }
    [PSCustomObject]@{ Algorithms = @("ProgPoWEpic");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_epic" }
    [PSCustomObject]@{ Algorithms = @("ProgPoWSero");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_sero" }
    [PSCustomObject]@{ Algorithms = @("ProgPoWVeil");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_veil" }
    [PSCustomObject]@{ Algorithms = @("ProgPoWVeriblock");     Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_veriblock" }
    [PSCustomObject]@{ Algorithms = @("ProgPoWZ");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_zano" }
    [PSCustomObject]@{ Algorithms = @("Pufferfish2BMB");       Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm pufferfish2bmb" }    
    [PSCustomObject]@{ Algorithms = @("SHA512256d");           Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 30);  ExcludePool = @()       ; Arguments = " --algorithm sha512_256d_radiant" }
    [PSCustomObject]@{ Algorithms = @("RandomxArq");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithms = @("RandomxEpic");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomepic" }
    [PSCustomObject]@{ Algorithms = @("RandomGrft");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomgrft --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithms = @("RandomHash2");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithms = @("RandomL");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randoml --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithms = @("RandomSfx");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomsfx --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithms = @("RandomWow");            Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomwow --randomx-use-1gb-pages" }
#   [PSCustomObject]@{ Algorithms = @("RandomX");              Type = "CPU"; Fee = @(0.0085); MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomx --randomx-use-1gb-pages" } # Not profitable at all
    [PSCustomObject]@{ Algorithms = @("RandomxKeva");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomkeva --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithms = @("RandomxL");             Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomxl --randomx-use-1gb-pages" } # XmRig-v6.18.0 is fastest
    [PSCustomObject]@{ Algorithms = @("RandomYada");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomyada" }
    [PSCustomObject]@{ Algorithms = @("ScryptN2");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm scryptn2" }
    [PSCustomObject]@{ Algorithms = @("SHA3d");                Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm sha3d" }
#   [PSCustomObject]@{ Algorithms = @("UbqHash");              Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm ubqhash" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithms = @("VertHash");             Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithms = @("VerusHash");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithms = @("Xdag");                 Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm xdag" }
    [PSCustomObject]@{ Algorithms = @("YescryptR16");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yescryptr16" }
    [PSCustomObject]@{ Algorithms = @("YescryptR32");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yescryptr32" }
    [PSCustomObject]@{ Algorithms = @("YescryptR8");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yescryptr8" }
    [PSCustomObject]@{ Algorithms = @("Yespower");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespower" }
    [PSCustomObject]@{ Algorithms = @("Yespower2b");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespower2b" }
    [PSCustomObject]@{ Algorithms = @("YespowerARWN");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerarwn" }
    [PSCustomObject]@{ Algorithms = @("YespowerIc");           Type = "CPU"; Fee = @(0)     ; MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespoweric" }
    [PSCustomObject]@{ Algorithms = @("YespowerIots");         Type = "CPU"; Fee = @(0)     ; MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespoweriots" }
    [PSCustomObject]@{ Algorithms = @("YespowerItc");          Type = "CPU"; Fee = @(0)     ; MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespoweritc" }
    [PSCustomObject]@{ Algorithms = @("YespowerLitb");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerlitb" }
    [PSCustomObject]@{ Algorithms = @("YespowerLtncg");        Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerltncg" }
    [PSCustomObject]@{ Algorithms = @("YespowerMgpc");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowermgpc" }
    [PSCustomObject]@{ Algorithms = @("YespowerR16");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithms = @("YespowerRes");          Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithms = @("YespowerSugar");        Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowersugar" }
    [PSCustomObject]@{ Algorithms = @("YespowerTide");         Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowertide" }
    [PSCustomObject]@{ Algorithms = @("YespowerUrx");          Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerurx" }
    [PSCustomObject]@{ Algorithms = @("Yescrypt");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(90, 0);   ExcludePool = @()       ; Arguments = " --algorithm yescrypt" }
    [PSCustomObject]@{ Algorithms = @("Zentoshi");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm balloon_zentoshi" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } | Select-Object | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
            $MinMemGB = $_.MinMemGB + $_.MemReserveGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or ($_.MemoryGB -gt $MinMemGB) } | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithms[1]) { "$($_.Algorithms[0])&$($_.Algorithms[1])" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algorithm") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --pool $($MinerPools[0].($_.Algorithms[0]).Host):$($MinerPools[0].($_.Algorithms[0]).PoolPorts | Select-Object -Last 1) --wallet $($MinerPools[0].($_.Algorithms[0]).User)"
                If ($MinerPools[0].($_.Algorithms[0]).WorkerName) { " --worker $($MinerPools[0].($_.Algorithms[0]).WorkerName)" }
                $_.Arguments += " --password $($MinerPools[0].($_.Algorithms[0]).Pass)$(If ($MinerPools[0].($_.Algorithms[0]).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                If ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1]) { $_.Arguments += " --tls true" }
                If ($MinerPools[0].($_.Algorithms[0]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithms[0]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --nicehash true" }
                If ($MinerPools[0].($_.Algorithms[0]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithms[0]).BaseName -eq "ProHashing") { $_.Arguments += " --esm 1" }

                If ($_.Algorithms[1]) { 
                    $_.Arguments += " --pool $($MinerPools[0].($_.Algorithms[1]).Host):$($MinerPools[0].($_.Algorithms[1]).PoolPorts | Select-Object -Last 1) --wallet $($MinerPools[0].($_.Algorithms[1]).User)"
                    If ($MinerPools[0].($_.Algorithms[1]).WorkerName) { $_.Arguments += " --worker $($MinerPools[0].($_.Algorithms[1]).WorkerName)" }
                    $_.Arguments += " --password $($MinerPools[0].($_.Algorithms[1]).Pass)"
                    If ($MinerPools[0].($_.Algorithms[1]).PoolPorts[1]) { $_.Arguments += " --tls true" }
                    If ($MinerPools[0].($_.Algorithms[1]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithms[1]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --nicehash true" }
                    If ($MinerPools[0].($_.Algorithms[1]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithms[1]).BaseName -eq "ProHashing") { $_.Arguments += " --esm 1" }
                }

                If (($AvailableMiner_Devices.Type | Select-Object -Unique) -eq "CPU") { 
                    $_.Arguments += " --cpu-threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --disable-gpu"
                }
                Else { 
                    $_.Arguments += " --gpu-auto-tune 2 --gpu-id $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',') --disable-cpu"
                }

                $PrerequisitePath = ""
                $PrerequisiteURI = ""
                If ($_.Algorithm -eq "VertHash" -and -not (Test-Path -Path ".\Bin\$($Name)\VertHash.dat" -ErrorAction SilentlyContinue)) { 
                    If ((Get-Item -Path $Variables.VerthashDatPath).length -eq 1283457024) { 
                        If (Test-Path -Path .\Bin\$($Name) -PathType Container) { 
                            [void](New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath)
                        }
                    }
                    Else { 
                        $PrerequisitePath = $Variables.VerthashDatPath
                        $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                    }
                }

                [PSCustomObject]@{ 
                    Name             = $Miner_Name
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Type             = $AvailableMiner_Devices.Type
                    Path             = $Path
                    Arguments        = ("$($_.Arguments) --disable-workers-ramp-up --api-rig-name $($Config.WorkerName) --api-enable --api-port $MinerAPIPort" -replace "\s+", " ").trim()
                    Algorithms       = @($_.Algorithms[0], $_.Algorithms[1] | Select-Object)
                    API              = "SRBMiner"
                    Port             = $MinerAPIPort
                    URI              = $Uri
                    Fee              = $_.Fee # Dev fee
                    MinerUri         = "http://localhost:$($MinerAPIPort)/stats"
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                }
            }
        }
    }
}
