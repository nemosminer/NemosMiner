using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { (($_.Type -eq "AMD" -and $_.Architecture -ne "Other") -or $_.OpenCL.ClVersion -ge "OpenCL C 2.0") -or $_.Type -eq "CPU" })) { Return }

$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.9.6/SRBMiner-Multi-0-9-6-win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$Miner_Devices = $Devices 
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "0x10";              Type = "AMD"; Fee = 0.085;  MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm 0x10" }
    [PSCustomObject]@{ Algorithm = "Argon2d16000";      Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2d_16000" }
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";        Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa2";     Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 45); Arguments = " --algorithm argon2id_chukwa2" }
    [PSCustomObject]@{ Algorithm = "Autolykos2";        Type = "AMD"; Fee = 0.015;  MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --algorithm autolykos2" }
    [PSCustomObject]@{ Algorithm = "Blake2b";           Type = "AMD"; Fee = 0;      MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Blake2s";           Type = "AMD"; Fee = 0;      MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "Blake3";            Type = "AMD"; Fee = 0.0085; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm blake3_alephium" }
    [PSCustomObject]@{ Algorithm = "CircCash";          Type = "AMD"; Fee = 00085;  MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightTalleo"; Type = "AMD"; Fee = 0;      MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algorithm cryptonight_talleo" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_upx" } # TeamRedMiner-v0.10.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_turtle" } # TeamRedMiner-v0.10.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_xhv" }
    # [PSCustomObject]@{ Algorithm = "DynamoCoin";        Type = "AMD"; Fee = 0.01;   MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
    [PSCustomObject]@{ Algorithm = "EtcHash";           Type = "AMD"; Fee = 0.0065; MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); Arguments = " --algorithm etchash --gpu-boost 50 --gpu-auto-tune 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";            Type = "AMD"; Fee = 0.0065; MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); Arguments = " --algorithm ethash --gpu-boost 50 --gpu-auto-tune 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem";      Type = "AMD"; Fee = 0.0065; MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); Arguments = " --algorithm ethash --gpu-boost 50 --gpu-auto-tune 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "FiroPoW";           Type = "AMD"; Fee = 0.0085; MinMemGB = 5;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 75); Arguments = " --algorithm firopow --gpu-boost 50 --gpu-auto-tune 2" }
    [PSCustomObject]@{ Algorithm = "FrkHash";           Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm frkhash" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";         Type = "AMD"; Fee = 0.01;   MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm heavyhash" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";        Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm k12" }
    [PSCustomObject]@{ Algorithm = "Kaspa";             Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm kaspa" }
    [PSCustomObject]@{ Algorithm = "KawPoW";            Type = "AMD"; Fee = 0.085;  MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(90, 75); Arguments = " --algorithm kawpow --gpu-boost 50 --gpu-auto-tune 2" }
    [PSCustomObject]@{ Algorithm = "Keccak";            Type = "AMD"; Fee = 0;      MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "Lyra2v2Webchain";   Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm lyra2v2_webchain" }
    [PSCustomObject]@{ Algorithm = "ProgPoWEpic";       Type = "AMD"; Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_epic" }
    [PSCustomObject]@{ Algorithm = "ProgPoWSero";       Type = "AMD"; Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_sero" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeil";       Type = "AMD"; Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_veil" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeriblock";  Type = "AMD"; Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_veriblock" }
    [PSCustomObject]@{ Algorithm = "ProgPoWZano";       Type = "AMD"; Fee = 0.0065; MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_zano" }
    [PSCustomObject]@{ Algorithm = "SHA3d";             Type = "CPU"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm sha3d" }
    [PSCustomObject]@{ Algorithm = "VerusHash";         Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "VertHash";          Type = "AMD"; Fee = 0.0125; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";          Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algorithm yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR8";        Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algorithm yescryptr8" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";       Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algorithm yescryptr16" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";       Type = "AMD"; Fee = 0.0085; MinMemGB = 1;                               MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algorithm yescryptr32" }

    [PSCustomObject]@{ Algorithm = "0x10";              Type = "CPU"; Fee = 0.085;  MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm 0x10" }
    [PSCustomObject]@{ Algorithm = "Argon2d16000";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algorithm argon2d_16000" }
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa2";     Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm argon2id_chukwa2" }
    [PSCustomObject]@{ Algorithm = "Autolykos2";        Type = "CPU"; Fee = 0.015;  MinerSet = 0; WarmupTimes = @(120, 15);  Arguments = " --algorithm autolykos2 --gpu-autolykos2-preload 3" }
    [PSCustomObject]@{ Algorithm = "Blake2b";           Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(90, 15);   Arguments = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Blake2s";           Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "Blake3";            Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm blake3_alephium" }
    [PSCustomObject]@{ Algorithm = "CircCash";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightTalleo"; Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm cryptonight_talleo" }
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm cryptonight_turtle" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm cryptonight_upx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = "Cosa";              Type = "CPU"; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(60, 15);   Arguments = " --algorithm cosa" }
    [PSCustomObject]@{ Algorithm = "CpuPower";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm cpupower" }
    [PSCustomObject]@{ Algorithm = "CurveHash";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);   Arguments = " --algorithm curvehash" }
    # [PSCustomObject]@{ Algorithm = "DynamoCoin";        Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
    # [PSCustomObject]@{ Algorithm = "EtcHash";           Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algorithm etchash" } # Not profitable with CPU
    # [PSCustomObject]@{ Algorithm = "Ethash";            Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algorithm ethash" } # Not profitable with CPU
    # [PSCustomObject]@{ Algorithm = "EthashLowMem";      Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algorithm ethash" } # Not profitable with CPU
    # [PSCustomObject]@{ Algorithm = "FiroPoW";           Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm firopow" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "FrkHash";           Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm frkhash" }
    [PSCustomObject]@{ Algorithm = "GhostRider";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm ghostrider" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";         Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm heavyhash" }
    [PSCustomObject]@{ Algorithm = "K12";               Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm K12" }
    # [PSCustomObject]@{ Algorithm = "KawPoW";            Type = "CPU"; Fee = 0.085;  MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm kawpow" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "Kaspa";             Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm kaspa" }
    [PSCustomObject]@{ Algorithm = "Keccak";            Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm keccak" }
    [PSCustomObject]@{ Algorithm = "Lyra2v2Webchain";   Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm lyra2v2_webchain" }
    [PSCustomObject]@{ Algorithm = "Minotaur";          Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm minotaur" }
    [PSCustomObject]@{ Algorithm = "Minotaurx";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm minotaurx" }
    [PSCustomObject]@{ Algorithm = "Panthera";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm panthera" }
    [PSCustomObject]@{ Algorithm = "ProgPoWEpic";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm progpow_epic" }
    [PSCustomObject]@{ Algorithm = "ProgPoWSero";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm progpow_sero" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeil";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm progpow_veil" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeriblock";  Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm progpow_veriblock" }
    [PSCustomObject]@{ Algorithm = "ProgPoWZano";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm progpow_zano" }
    [PSCustomObject]@{ Algorithm = "RandomxArq";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxEpic";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm randomepic" }
    [PSCustomObject]@{ Algorithm = "RandomGrft";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm randomgrft --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomHash2";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm randomarq --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomL";           Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm randoml --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomSfx";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm randomsfx --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomWow";         Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm randomwow --randomx-use-1gb-pages" }
    # [PSCustomObject]@{ Algorithm = "RandomX";           Type = "CPU"; Fee = 0.0085; MinerSet = 1; WarmupTimes = @(60, 0);  Arguments = " --algorithm randomx --randomx-use-1gb-pages" } # Not profitable at all
    [PSCustomObject]@{ Algorithm = "RandomxKeva";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm randomkeva --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomxL";          Type = "CPU"; Fee = 0;      MinerSet = 1; WarmupTimes = @(60, 0);  Arguments = " --algorithm randomxl --randomx-use-1gb-pages" } # XmRig-v6.17.0 is fastest
    [PSCustomObject]@{ Algorithm = "RandomYada";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm randomyada" }
    [PSCustomObject]@{ Algorithm = "ScryptN2";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm scryptn2" }
    [PSCustomObject]@{ Algorithm = "SHA3d";             Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm sha3d" }
    # [PSCustomObject]@{ Algorithm = "UbqHash";           Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(60, 0);  Arguments = " --algorithm ubqhash" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "VertHash";          Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithm = "VerusHash";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm verushash" }
    [PSCustomObject]@{ Algorithm = "Xdag";              Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm xdag" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yescryptr16" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yescryptr32" }
    [PSCustomObject]@{ Algorithm = "YescryptR8";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yescryptr8" }
    [PSCustomObject]@{ Algorithm = "Yespower";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespower" }
    [PSCustomObject]@{ Algorithm = "Yespower2b";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespower2b" }
    [PSCustomObject]@{ Algorithm = "YespowerARWN";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespowerarwn" }
    [PSCustomObject]@{ Algorithm = "YespowerIc";        Type = "CPU"; Fee = 0     ; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespoweric" }
    [PSCustomObject]@{ Algorithm = "YespowerIots";      Type = "CPU"; Fee = 0     ; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespoweriots" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";       Type = "CPU"; Fee = 0     ; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespoweritc" }
    [PSCustomObject]@{ Algorithm = "YespowerLitb";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespowerlitb" }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg";     Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespowerltncg" }
    [PSCustomObject]@{ Algorithm = "YespowerMgpc";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespowermgpc" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";       Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithm = "YespowerRes";       Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespowerr16" }
    [PSCustomObject]@{ Algorithm = "YespowerSugar";     Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespowersugar" }
    [PSCustomObject]@{ Algorithm = "YespowerTide";      Type = "CPU"; Fee = 0;      MinerSet = 1; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespowertide" }
    [PSCustomObject]@{ Algorithm = "YespowerUrx";       Type = "CPU"; Fee = 0;      MinerSet = 1; WarmupTimes = @(60, 0);  Arguments = " --algorithm yespowerurx" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algorithm yescrypt" }
    [PSCustomObject]@{ Algorithm = "Zentoshi";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm balloon_zentoshi" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB + $_.MemReserveGB

            If ($_.Algorithm -eq "VertHash") { 
                If (-not (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf )) { 
                    If (-not (Test-Path -Path ".\Cache" -PathType Container)) { New-Item -Path . -Name "Cache" -ItemType Directory | Out-Null }
                    $_.WarmupTimes[0] += 45 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat
                }
            }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or ($_.MemoryGB -gt $MinMemGB) }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algorithm") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If (($AvailableMiner_Devices.Type | Select-Object -Unique) -eq "CPU") { 
                    $DeviceArguments = " --cpu-threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --disable-gpu"
                }
                Else { 
                    $DeviceArguments = " --gpu-id $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',') --disable-cpu"
                }

                $_.Arguments += " --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --wallet $($Pools.($_.Algorithm).User) --worker $($Config.Workername)"
                $_.Arguments += " --password $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"

                If ($Pools.($_.Algorithm).SSL) { $_.Arguments += " --ssl true" }
                If ($Pools.($_.Algorithm).DAGsizeGB -ne $null -and $Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --nicehash true" }
                If ($Pools.($_.Algorithm).DAGsizeGB -ne $null -and $Pools.($_.Algorithm).BaseName -eq "ProHashing") { $_.Arguments += " --esm 1" }

                # If ($Pools.($_.Algorithm).BaseName -eq "MiningPoolHub") { $_.WarmupTimes[0] += 15 } # Allow extra seconds for MPH because of long connect issue

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --disable-workers-ramp-up --api-enable --api-port $MinerAPIPort$DeviceArguments" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "SRBMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee # Dev fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)/stats"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
