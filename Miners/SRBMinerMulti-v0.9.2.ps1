using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0") -or $_.Type -eq "CPU" })) { Return }

$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.9.2/SRBMiner-Multi-0-9-2-win64.zip"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$Miner_Devices = $Devices 
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs 

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Argon2d16000";      Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algorithm argon2d_16000 --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";        Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algorithm argon2d_dynamic --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm argon2id_chukwa --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa2";     Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm argon2id_chukwa2 --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Argon2idNinja";     Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm argon2id_ninja --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Autolykos2";        Type = "AMD"; Fee = 0.02;   MinMemGB = 1; MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --algorithm autolykos2 --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Blake2b";           Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm blake2b --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Blake2s";           Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm blake2s --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Blake3";            Type = "AMD"; Fee = 0.01;   MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm blake3_alephium --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CircCash";          Type = "AMD"; Fee = 00085;  MinMemGB = 1; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm circcash --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_ccx --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algorithm cryptonight_gpu --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CryptonightTalleo"; Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algorithm cryptonight_talleo --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 1; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_upx --gpu-intensity 31 --gpu-boost 50" } # TeamRedMiner-v0.9.2.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 1; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_turtle --gpu-intensity 31 --gpu-boost 50" } # TeamRedMiner-v0.9.2.2 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm cryptonight_xhv --gpu-intensity 31 --gpu-boost 50" }
    # [PSCustomObject]@{ Algorithm = "DynamoCoin";        Type = "AMD"; Fee = 0.01;   MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
    [PSCustomObject]@{ Algorithm = "EtcHash";           Type = "AMD"; Fee = 0.0065; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(40, 30); Arguments = " --algorithm etchash --gpu-boost 50 --gpu-auto-tune 2" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";            Type = "AMD"; Fee = 0.0065; MinMemGB = 4; MinerSet = 1; WarmupTimes = @(40, 30); Arguments = " --algorithm ethash --gpu-boost 50 --gpu-auto-tune 2" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem";      Type = "AMD"; Fee = 0.0065; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(40, 30); Arguments = " --algorithm ethash --gpu-boost 50 --gpu-auto-tune 2" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "FiroPoW";           Type = "AMD"; Fee = 0.0085; MinMemGB = 5; MinerSet = 0; WarmupTimes = @(40, 30); Arguments = " --algorithm firopow --gpu-boost 50 --gpu-auto-tune 2" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";         Type = "AMD"; Fee = 0.01;   MinMemGB = 1; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm heavyhash --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Kangaroo12";        Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm k12 --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "KawPoW";            Type = "AMD"; Fee = 0.085;  MinMemGB = 4; MinerSet = 0; WarmupTimes = @(40, 15); Arguments = " --algorithm kawpow --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Keccak";            Type = "AMD"; Fee = 0;      MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm keccak --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "Lyra2v2Webchain";   Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm lyra2v2_webchain --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "ProgPoWEpic";       Type = "AMD"; Fee = 0.0065; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_epic --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "ProgPoWSero";       Type = "AMD"; Fee = 0.0065; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_sero --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeil";       Type = "AMD"; Fee = 0.0065; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_veil --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeriblock";  Type = "AMD"; Fee = 0.0065; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_veriblock --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "ProgPoWZano";       Type = "AMD"; Fee = 0.0065; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algorithm progpow_zano --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "VerusHash";         Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm verushash --gpu-intensity 31 --gpu-boost 50" }
    [PSCustomObject]@{ Algorithm = "VertHash";          Type = "AMD"; Fee = 0.0125; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm verthash --verthash-dat-path ..\..\Cache\VertHash.dat" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";          Type = "AMD"; Fee = 0.0085; MinMemGB = 1; MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algorithm yescrypt --gpu-intensity 31 --gpu-boost 50" }

    [PSCustomObject]@{ Algorithm = "Argon2d16000";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 15);  Arguments = " --algorithm argon2d_16000" }
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 15);  Arguments = " --algorithm argon2d_dynamic" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm argon2id_chukwa" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa2";     Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm argon2id_chukwa2" }
    [PSCustomObject]@{ Algorithm = "Argon2idNinja";     Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm argon2id_ninja" }
    [PSCustomObject]@{ Algorithm = "AstroBWT";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 15);  rguments = " --algorithm astrobwt" }
    # [PSCustomObject]@{ Algorithm = "Autolykos2";        Type = "CPU"; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(120, 15);  Arguments = " --algorithm autolykos2" } # CPU Fails to create DAG in time
    [PSCustomObject]@{ Algorithm = "Blake2b";           Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(90, 15);  Arguments = " --algorithm blake2b" }
    [PSCustomObject]@{ Algorithm = "Blake2s";           Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm blake2s" }
    [PSCustomObject]@{ Algorithm = "Blake3";            Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm blake3_alephium" }
    [PSCustomObject]@{ Algorithm = "CircCash";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm circcash" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm cryptonight_ccx" }
    [PSCustomObject]@{ Algorithm = "CryptonightGpu";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm cryptonight_gpu" }
    [PSCustomObject]@{ Algorithm = "CryptonightTalleo"; Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm cryptonight_talleo" }
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm cryptonight_turtle" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm cryptonight_upx" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm cryptonight_xhv" }
    [PSCustomObject]@{ Algorithm = "Cosa";              Type = "CPU"; Fee = 0.02;   MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm cosa" }
    [PSCustomObject]@{ Algorithm = "CpuPower";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm cpupower" }
    [PSCustomObject]@{ Algorithm = "CurveHash";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm curvehash" }
    # [PSCustomObject]@{ Algorithm = "DynamoCoin";        Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(30, 15);  Arguments = " --algorithm dynamo" } # Algorithm 'dynamo' supports only 'pool' mode (yiimp stratum compatibility removed)
    # [PSCustomObject]@{ Algorithm = "EtcHash";           Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(30, 15);  Arguments = " --algorithm etchash" } # Not profitable with CPU
    # [PSCustomObject]@{ Algorithm = "Ethash";            Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(30, 15);  Arguments = " --algorithm ethash" } # Not profitable with CPU
    # [PSCustomObject]@{ Algorithm = "EthashLowMem";      Type = "CPU"; Fee = 0.0065; MinerSet = 1; WarmupTimes = @(30, 15);  Arguments = " --algorithm ethash" } # Not profitable with CPU
    # [PSCustomObject]@{ Algorithm = "FiroPoW";           Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm firopow" } # Not profitable with CPU
    [PSCustomObject]@{ Algorithm = "GhostRider";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm ghostrider" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";         Type = "CPU"; Fee = 0.01;   MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm heavyhash" }
    [PSCustomObject]@{ Algorithm = "K12";               Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm K12" }
    # [PSCustomObject]@{ Algorithm = "KawPoW";            Type = "CPU"; Fee = 0.085;  MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm kawpow" } # Not profitable with CPU
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
    [PSCustomObject]@{ Algorithm = "RandomKeva";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm randomkeva --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomL";           Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm randoml --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomSfx";         Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm randomsfx --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "RandomWow";         Type = "CPU"; Fee = 0;      MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm randomwow --randomx-use-1gb-pages" }
    [PSCustomObject]@{ Algorithm = "Randomx";           Type = "CPU"; Fee = 0.0085; MinerSet = 1; WarmupTimes = @(60, 0);  Arguments = " --algorithm randomx --randomx-use-1gb-pages" } # XmRig-v6.16.3 is fastest
    [PSCustomObject]@{ Algorithm = "RandomxL";          Type = "CPU"; Fee = 0;      MinerSet = 1; WarmupTimes = @(60, 0);  Arguments = " --algorithm randomxl --randomx-use-1gb-pages" } # XmRig-v6.16.3 is fastest
    [PSCustomObject]@{ Algorithm = "RandomYada";        Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algorithm randomyada" }
    [PSCustomObject]@{ Algorithm = "ScryptN2";          Type = "CPU"; Fee = 0.0085; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algorithm scryptn2" }
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

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            If ($_.Algorithm -eq "VertHash") { 
                If (-not (Test-Path -Path ".\Cache\VertHash.dat" -PathType Leaf )) { 
                    If (-not (Test-Path -Path ".\Cache" -PathType Container)) { New-Item -Path . -Name "Cache" -ItemType Directory | Out-Null }
                    $_.WarmupTimes[0] += 45 # Seconds, max. wait time until first data sample, allow extra time to build verthash.dat
                }
            }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 

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
                $_.Arguments += " --password $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum -$DAGmemReserve) / 1GB)" })"

                If ($Pools.($_.Algorithm).SSL) { $_.Arguments += " --ssl true" }
                If ($Pools.($_.Algorithm).DAGsize -ne $null -and $Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --nicehash true" }
                If ($Pools.($_.Algorithm).DAGsize -ne $null -and $Pools.($_.Algorithm).BaseName -eq "ProHashing") { $_.Arguments += " --esm 1" }

                If ($Pools.($_.Algorithm).BaseName -eq "MiningPoolHub") { $_.WarmupTimes[0] += 15 } # Allow extra seconds for MPH because of long connect issue

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $_.Type
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
