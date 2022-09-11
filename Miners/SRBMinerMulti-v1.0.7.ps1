using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { (($_.Type -eq "AMD" -and $_.Architecture -ne "Other") -or $_.OpenCL.ClVersion -ge "OpenCL C 2.0") -or $_.Type -eq "CPU" })) { Return }

$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/1.0.7/SRBMiner-Multi-1-0-7-win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
     [PSCustomObject]@{ Algorithm = @("0x10");                      Type = "AMD"; Fee = @(0.0085);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); ExcludePool = @()       ; Arguments = " --algorithm 0x10" }
     [PSCustomObject]@{ Algorithm = @("Argon2d16000");              Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); ExcludePool = @()       ; Arguments = " --algorithm argon2d_16000" }
     [PSCustomObject]@{ Algorithm = @("Argon2d500");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); ExcludePool = @()       ; Arguments = " --algorithm argon2d_dynamic" }
     [PSCustomObject]@{ Algorithm = @("Argon2Chukwa");              Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); ExcludePool = @()       ; Arguments = " --algorithm argon2id_chukwa" }
     [PSCustomObject]@{ Algorithm = @("Argon2Chukwa2");             Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); ExcludePool = @()       ; Arguments = " --algorithm argon2id_chukwa2" }
#    [PSCustomObject]@{ Algorithm = @("Autolykos2");                Type = "AMD"; Fee = @(0.01);         MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm autolykos2" } # Hashrate far too high
#    [PSCustomObject]@{ Algorithm = @("Autolykos2", "HeavyHash");   Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm autolykos2 --algorithm heavyhash " }
     [PSCustomObject]@{ Algorithm = @("Blake2b");                   Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @("Zpool"); Arguments = " --algorithm blake2b" } # Algorithm broken
     [PSCustomObject]@{ Algorithm = @("Blake2s");                   Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludePool = @()       ; Arguments = " --algorithm blake2s" }
     [PSCustomObject]@{ Algorithm = @("Blake3");                    Type = "AMD"; Fee = @(0.0085);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm blake3_alephium" }
     [PSCustomObject]@{ Algorithm = @("CircCash");                  Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm circcash" }
     [PSCustomObject]@{ Algorithm = @("CryptonightCcx");            Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm cryptonight_ccx" }
     [PSCustomObject]@{ Algorithm = @("CryptonightGpu");            Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 30); ExcludePool = @()       ; Arguments = " --algorithm cryptonight_gpu" }
     [PSCustomObject]@{ Algorithm = @("CryptonightTalleo");         Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 30); ExcludePool = @()       ; Arguments = " --algorithm cryptonight_talleo" }
    #  [PSCustomObject]@{ Algorithm = @("CryptonightUpx");            Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 30); ExcludePool = @()       ; Arguments = " --algorithm cryptonight_upx" } # SSL not working @ ZergPool
     [PSCustomObject]@{ Algorithm = @("CryptonightTurtle");         Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm cryptonight_turtle" } # TeamRedMiner-v0.10.2 is fastest
     [PSCustomObject]@{ Algorithm = @("CryptonightHeavyXhv");       Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm cryptonight_xhv" }
     [PSCustomObject]@{ Algorithm = @("CurveHash");                 Type = "AMD"; Fee = @(0.0085);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm curvehash" }
#    [PSCustomObject]@{ Algorithm = @("DynamoCoin");                Type = "AMD"; Fee = @(0.01);         MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
     [PSCustomObject]@{ Algorithm = @("EtcHash");                   Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludePool = @()       ; Arguments = " --algorithm etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#    [PSCustomObject]@{ Algorithm = @("EtcHash", "HeavyHash");      Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludePool = @()       ; Arguments = " --algorithm etchash --algorithm heavyhash --gpu-dual-max-loss 5 --gpu-auto-tune 2" }
     [PSCustomObject]@{ Algorithm = @("Ethash");                    Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludePool = @()       ; Arguments = " --algorithm ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#    [PSCustomObject]@{ Algorithm = @("Ethash", "Heavyhash");       Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludePool = @()       ; Arguments = " --algorithm ethash --algorithm heavyhash --gpu-dual-max-loss 5 --gpu-auto-tune 2" }
     [PSCustomObject]@{ Algorithm = @("EthashLowMem");              Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludePool = @()       ; Arguments = " --algorithm ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "HeavyHash"); Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludePool = @()       ; Arguments = " --algorithm ethash --algorithm heavyhash --gpu-dual-max-loss 5 --gpu-auto-tune 2" }
     [PSCustomObject]@{ Algorithm = @("FiroPoW");                   Type = "AMD"; Fee = @(0.0085);       MinMemGB = $MinerPools[0].FiroPoW.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(60, 75); ExcludePool = @()       ; Arguments = " --algorithm firopow" }
     [PSCustomObject]@{ Algorithm = @("FrkHash");                   Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm frkhash" }
     [PSCustomObject]@{ Algorithm = @("HeavyHash");                 Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 15); ExcludePool = @()       ; Arguments = " --algorithm heavyhash" }
     [PSCustomObject]@{ Algorithm = @("Kangaroo12");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm k12" }
     [PSCustomObject]@{ Algorithm = @("Kaspa");                     Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm kaspa" }
     [PSCustomObject]@{ Algorithm = @("KawPoW");                    Type = "AMD"; Fee = @(0.0085);       MinMemGB = $MinerPools[0].KawPoW.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(90, 75); ExcludePool = @()       ; Arguments = " --algorithm kawpow" }
#    [PSCustomObject]@{ Algorithm = @("Keccak");                    Type = "AMD"; Fee = @(0);            MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm keccak" } # ASIC
     [PSCustomObject]@{ Algorithm = @("Lyra2v2Webchain");           Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm lyra2v2_webchain" }
     [PSCustomObject]@{ Algorithm = @("ProgPoWEpic");               Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPoWEpic.DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm progpow_epic" }
     [PSCustomObject]@{ Algorithm = @("ProgPoWSero");               Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPoWSero.DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm progpow_sero" }
     [PSCustomObject]@{ Algorithm = @("ProgPoWVeil");               Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPoWVeil.DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm progpow_veil" }
     [PSCustomObject]@{ Algorithm = @("ProgPoWVeriblock");          Type = "AMD"; Fee = @(0.0065);       MinMemGB = 2;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm progpow_veriblock" }
     [PSCustomObject]@{ Algorithm = @("ProgPoWZ");                  Type = "AMD"; Fee = @(0.0065);       MinMemGB = $MinerPools[0].ProgPoWZ.DAGSizeGB;     MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @()       ; Arguments = " --algorithm progpow_zano" }
     [PSCustomObject]@{ Algorithm = @("Pufferfish2BMB");            Type = "AMD"; Fee = @(0.01);         MinMemGB = 8;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  ExcludePool = @()       ; Arguments = " --algorithm pufferfish2bmb" }
     [PSCustomObject]@{ Algorithm = @("SHA3d");                     Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm sha3d" }
     [PSCustomObject]@{ Algorithm = @("VerusHash");                 Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm verushash" }
     [PSCustomObject]@{ Algorithm = @("VertHash");                  Type = "AMD"; Fee = @(0.0125);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); ExcludePool = @()       ; Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
     [PSCustomObject]@{ Algorithm = @("Yescrypt");                  Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 30); ExcludePool = @()       ; Arguments = " --algorithm yescrypt" }
     [PSCustomObject]@{ Algorithm = @("YescryptR8");                Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 30); ExcludePool = @()       ; Arguments = " --algorithm yescryptr8" }
     [PSCustomObject]@{ Algorithm = @("YescryptR16");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 30); ExcludePool = @()       ; Arguments = " --algorithm yescryptr16" }
     [PSCustomObject]@{ Algorithm = @("YescryptR32");               Type = "AMD"; Fee = @(0.0085);       MinMemGB = 1;                                     MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 30); ExcludePool = @()       ; Arguments = " --algorithm yescryptr32" }

    [PSCustomObject]@{ Algorithm = @("0x10");                 Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm 0x10" }
    [PSCustomObject]@{ Algorithm = @("Argon2d16000");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePool = @()       ; Arguments = " --algorithm argon2d_16000" }
    [PSCustomObject]@{ Algorithm = @("Argon2d500");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePool = @()       ; Arguments = " --algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithm = @("Argon2Chukwa");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = @("Argon2Chukwa2");        Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm argon2id_chukwa2" }
#   [PSCustomObject]@{ Algorithm = @("Autolykos2");           Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(120, 15); ExcludePool = @()       ; Arguments = " --algorithm autolykos2 --gpu-autolykos2-preload 3" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = @("Blake2b");              Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(90, 15);  ExcludePool = @("Zpool"); Arguments = " --algorithm blake2b" } # Algo broken
    [PSCustomObject]@{ Algorithm = @("Blake2s");              Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = @("Blake3");               Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm blake3_alephium" }
    [PSCustomObject]@{ Algorithm = @("CircCash");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithm = @("CryptonightCcx");       Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = @("CryptonightGpu");       Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = @("CryptonightTalleo");    Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_talleo" }
    [PSCustomObject]@{ Algorithm = @("CryptonightTurtle");    Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_turtle" }
    # [PSCustomObject]@{ Algorithm = @("CryptonightUpx");       Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_upx" } # SSL not working @ ZergPool
    [PSCustomObject]@{ Algorithm = @("CryptonightHeavyxXhv"); Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = @("Cosa");                 Type = "CPU"; Fee = @(0.02);   MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePool = @()       ; Arguments = " --algorithm cosa" }
    [PSCustomObject]@{ Algorithm = @("CpuPower");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm cpupower" }
    [PSCustomObject]@{ Algorithm = @("CurveHash");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm curvehash" }
#   [PSCustomObject]@{ Algorithm = @("DynamoCoin");           Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
#   [PSCustomObject]@{ Algorithm = @("EtcHash");              Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm etchash" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = @("Ethash");               Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm ethash" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = @("EthashLowMem");         Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(30, 15);  ExcludePool = @()       ; Arguments = " --algorithm ethash" } # Not profitable with CPU
#   [PSCustomObject]@{ Algorithm = @("FiroPoW");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm firopow" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = @("FrkHash");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm frkhash" }
    [PSCustomObject]@{ Algorithm = @("GhostRider");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm ghostrider" }
    [PSCustomObject]@{ Algorithm = @("HeavyHash");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm heavyhash" }
    [PSCustomObject]@{ Algorithm = @("K12");                  Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm K12" }
#   [PSCustomObject]@{ Algorithm = @("KawPoW");               Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm kawpow" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = @("Kaspa");                Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm kaspa" }
#   [PSCustomObject]@{ Algorithm = @("Keccak");               Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm keccak" } # ASIC
    [PSCustomObject]@{ Algorithm = @("Lyra2v2Webchain");      Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm lyra2v2_webchain" }
    [PSCustomObject]@{ Algorithm = @("Mike");                 Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm mike" }
    [PSCustomObject]@{ Algorithm = @("Minotaur");             Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm minotaur" }
    [PSCustomObject]@{ Algorithm = @("Minotaurx");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm minotaurx" }
    [PSCustomObject]@{ Algorithm = @("Panthera");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm panthera" }
    [PSCustomObject]@{ Algorithm = @("ProgPoWEpic");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_epic" }
    [PSCustomObject]@{ Algorithm = @("ProgPoWSero");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_sero" }
    [PSCustomObject]@{ Algorithm = @("ProgPoWVeil");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_veil" }
    [PSCustomObject]@{ Algorithm = @("ProgPoWVeriblock");     Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_veriblock" }
    [PSCustomObject]@{ Algorithm = @("ProgPoWZ");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm progpow_zano" }
    [PSCustomObject]@{ Algorithm = @("Pufferfish2BMB");       Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm pufferfish2bmb" }    
    [PSCustomObject]@{ Algorithm = @("RandomxArq");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = @("RandomxEpic");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomepic" }
    [PSCustomObject]@{ Algorithm = @("RandomGrft");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomgrft --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = @("RandomHash2");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = @("RandomL");              Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randoml --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = @("RandomSfx");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomsfx --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = @("RandomWow");            Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomwow --randomx-use-1gb-pages" }
#   [PSCustomObject]@{ Algorithm = @("RandomX");              Type = "CPU"; Fee = @(0.0085); MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomx --randomx-use-1gb-pages" } # Not profitable at all
    [PSCustomObject]@{ Algorithm = @("RandomxKeva");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomkeva --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = @("RandomxL");             Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomxl --randomx-use-1gb-pages" } # XmRig-v6.18.0 is fastest
    [PSCustomObject]@{ Algorithm = @("RandomYada");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm randomyada" }
    [PSCustomObject]@{ Algorithm = @("ScryptN2");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm scryptn2" }
    [PSCustomObject]@{ Algorithm = @("SHA3d");                Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm sha3d" }
#   [PSCustomObject]@{ Algorithm = @("UbqHash");              Type = "CPU"; Fee = @(0.0065); MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm ubqhash" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = @("VertHash");             Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithm = @("VerusHash");            Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePool = @()       ; Arguments = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = @("Xdag");                 Type = "CPU"; Fee = @(0.01);   MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm xdag" }
    [PSCustomObject]@{ Algorithm = @("YescryptR16");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yescryptr16" }
    [PSCustomObject]@{ Algorithm = @("YescryptR32");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yescryptr32" }
    [PSCustomObject]@{ Algorithm = @("YescryptR8");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yescryptr8" }
    [PSCustomObject]@{ Algorithm = @("Yespower");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespower" }
    [PSCustomObject]@{ Algorithm = @("Yespower2b");           Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespower2b" }
    [PSCustomObject]@{ Algorithm = @("YespowerARWN");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerarwn" }
    [PSCustomObject]@{ Algorithm = @("YespowerIc");           Type = "CPU"; Fee = @(0)     ; MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespoweric" }
    [PSCustomObject]@{ Algorithm = @("YespowerIots");         Type = "CPU"; Fee = @(0)     ; MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespoweriots" }
    [PSCustomObject]@{ Algorithm = @("YespowerItc");          Type = "CPU"; Fee = @(0)     ; MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespoweritc" }
    [PSCustomObject]@{ Algorithm = @("YespowerLitb");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerlitb" }
    [PSCustomObject]@{ Algorithm = @("YespowerLtncg");        Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerltncg" }
    [PSCustomObject]@{ Algorithm = @("YespowerMgpc");         Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowermgpc" }
    [PSCustomObject]@{ Algorithm = @("YespowerR16");          Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithm = @("YespowerRes");          Type = "CPU"; Fee = @(0);      MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithm = @("YespowerSugar");        Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowersugar" }
    [PSCustomObject]@{ Algorithm = @("YespowerTide");         Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowertide" }
    [PSCustomObject]@{ Algorithm = @("YespowerUrx");          Type = "CPU"; Fee = @(0);      MinerSet = 1; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm yespowerurx" }
    [PSCustomObject]@{ Algorithm = @("Yescrypt");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(90, 0);   ExcludePool = @()       ; Arguments = " --algorithm yescrypt" }
    [PSCustomObject]@{ Algorithm = @("Zentoshi");             Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(60, 0);   ExcludePool = @()       ; Arguments = " --algorithm balloon_zentoshi" }
)

If ($MinerPools[0].CryptonightUpx.BaseName -ne "ZergPool" -or ($MinerPools[0].CryptonightUpx.PoolPort -and -not $MinerPools[0].CryptonightUpx.PoolPort[1])) {  # SSL not working @ ZergPool, https://github.com/doktor83/SRBMiner-Multi/issues/135
    $Algorithms += [PSCustomObject]@{ Algorithm = @("CryptonightUpx"); Type = "AMD"; Fee = @(0.0085); MinMemGB = 1; MemReserveGB = 0; MinerSet = 1; WarmupTimes = @(60, 30); ExcludePool = @(); Arguments = " --algorithm cryptonight_upx" }
    $Algorithms += [PSCustomObject]@{ Algorithm = @("CryptonightUpx"); Type = "CPU"; Fee = @(0.0085); MinerSet = 0; WarmupTimes = @(30, 15); ExcludePool = @(); Arguments = " --algorithm cryptonight_upx" }
}

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm[0]).PoolPorts -and (-not $_.Algorithm[1] -or $MinerPools[1].($_.Algorithm[1]).PoolPorts) }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } | Select-Object | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB + $_.MemReserveGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or ($_.MemoryGB -gt $MinMemGB) }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algorithm") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --pool $($MinerPools[0].($_.Algorithm[0]).Host):$($MinerPools[0].($_.Algorithm[0]).PoolPorts | Select-Object -Last 1) --wallet $($MinerPools[0].($_.Algorithm[0]).User)"
                If ($MinerPools[0].($_.Algorithm[0]).WorkerName) { " --worker $($MinerPools[0].($_.Algorithm[0]).WorkerName)" }
                $_.Arguments += " --password $($MinerPools[0].($_.Algorithm[0]).Pass)$(If ($MinerPools[0].($_.Algorithm[0]).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                If ($MinerPools[0].($_.Algorithm[0]).PoolPorts[1]) { $_.Arguments += " --tls true" }
                If ($MinerPools[0].($_.Algorithm[0]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm[0]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --nicehash true" }
                If ($MinerPools[0].($_.Algorithm[0]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm[0]).BaseName -eq "ProHashing") { $_.Arguments += " --esm 1" }

                If ($_.Algorithm[1]) { 
                    $_.Arguments += " --pool $($MinerPools[0].($_.Algorithm[1]).Host):$($MinerPools[0].($_.Algorithm[1]).PoolPorts | Select-Object -Last 1) --wallet $($MinerPools[0].($_.Algorithm[1]).User)"
                    If ($MinerPools[0].($_.Algorithm[1]).WorkerName) { " --worker $($MinerPools[0].($_.Algorithm[1]).WorkerName)" }
                    $_.Arguments += " --password $($MinerPools[0].($_.Algorithm[1]).Pass)"
                    If ($MinerPools[0].($_.Algorithm[1]).PoolPorts[1]) { $_.Arguments += " --tls true" }
                    If ($MinerPools[0].($_.Algorithm[1]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm[1]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --nicehash true" }
                    If ($MinerPools[0].($_.Algorithm[1]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm[1]).BaseName -eq "ProHashing") { $_.Arguments += " --esm 1" }
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
                            New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath | Out-Null
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
                    Algorithms       = @($_.Algorithm[0], $_.Algorithm[1] | Select-Object)
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
