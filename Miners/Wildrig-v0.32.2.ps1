using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.Type -eq "NVIDIA"})) { Return }

$Uri = "https://github.com/andru-kun/wildrig-multi/releases/download/0.32.2/wildrig-multi-windows-0.32.2.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\wildrig.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "0x10";             Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 30); Arguments = " --algo 0x10" }
    [PSCustomObject]@{ Algorithm = "Aergo";            Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo aergo" }
    [PSCustomObject]@{ Algorithm = "Anime";            Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo anime" }
    [PSCustomObject]@{ Algorithm = "AstralHash";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo glt-astralhash" }
    [PSCustomObject]@{ Algorithm = "BCD";              Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo bcd" }
    [PSCustomObject]@{ Algorithm = "Bitcore";          Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo blake2b-glt" }
    [PSCustomObject]@{ Algorithm = "Bmw512";           Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 15); Arguments = " --algo bmw512" } # CcminerBmw512-v2.2.5 is fastest
    [PSCustomObject]@{ Algorithm = "Bitcore";          Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";              Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo c11" }
    [PSCustomObject]@{ Algorithm = "CurveHash";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo curvehash" }
    [PSCustomObject]@{ Algorithm = "Dedal";            Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo dedal" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";           Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo exosis" } 
    [PSCustomObject]@{ Algorithm = "FiroPoW";          Type = "AMD"; Fee = @(0.01); MinMemGB = $MinerPools[0]."FiroPoW".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(55, 45); Arguments = " --algo firopow" }
    [PSCustomObject]@{ Algorithm = "Geek";             Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo ghostrider" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo glt-globalhash" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo heavyhash" }
    [PSCustomObject]@{ Algorithm = "Hex";              Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo hex" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";          Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo hmq1725" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "JeongHash";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo glt-jeonghash" }
    [PSCustomObject]@{ Algorithm = "KawPoW";           Type = "AMD"; Fee = @(0.01); MinMemGB = $MinerPools[0]."KawPoW".DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo kawpow" } # TeamRedMiner-v0.10.2 is fastest on Navi
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo lyra2v3" } # TeamRedMiner-v0.10.2 is fastest
    [PSCustomObject]@{ Algorithm = "Lyra2TDC";         Type = "AMD"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo lyra2tdc" }
    [PSCustomObject]@{ Algorithm = "Lyra2vc0ban";      Type = "AMD"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo lyra2vc0ban" }
    [PSCustomObject]@{ Algorithm = "MegaBtx";          Type = "AMD"; Fee = @(0.02); MinMemGB = 1;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MegaMec";          Type = "AMD"; Fee = @(0.01); MinMemGB = 1;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo megamec" }
    [PSCustomObject]@{ Algorithm = "Mike";             Type = "AMD"; Fee = @(0.05); MinMemGB = 1;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo mike" }
    [PSCustomObject]@{ Algorithm = "Minotaur";         Type = "AMD"; Fee = @(0.05); MinMemGB = 1;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo minotaur" }
    [PSCustomObject]@{ Algorithm = "MTP";              Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo mtp" } # TeamRedMiner-v0.10.2 is fastest
    [PSCustomObject]@{ Algorithm = "MTPTcr";           Type = "AMD"; Fee = @(0.01); MinMemGB = 3;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo mtp-tcr" }
    [PSCustomObject]@{ Algorithm = "PadiHash";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo glt-pawelhash" }
    [PSCustomObject]@{ Algorithm = "Phi";              Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Phi5";             Type = "AMD"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo phi5" }
    [PSCustomObject]@{ Algorithm = "Polytimos";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "ProgPoWSero";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo progpow-sero" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeil";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo progpow-veil" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeriblock"; Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo vprogpow" }
    [PSCustomObject]@{ Algorithm = "ProgPoWZano";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo progpowz" }
    [PSCustomObject]@{ Algorithm = "Sha256csm";        Type = "AMD"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo sha256csm" }
#   [PSCustomObject]@{ Algorithm = "Sha256t";          Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo sha256t" } # Takes too long until it starts mining
    [PSCustomObject]@{ Algorithm = "Sha256q";          Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "Renesis";          Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo renesis" }
    [PSCustomObject]@{ Algorithm = "Skein2";           Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo skein2" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo skunkhash" }
    [PSCustomObject]@{ Algorithm = "Sonoa";            Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo sonoa" }
    [PSCustomObject]@{ Algorithm = "Timetravel";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "WildKeccak";       Type = "AMD"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo wildkeccak" }
    [PSCustomObject]@{ Algorithm = "X11k";             Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x11k" }
    [PSCustomObject]@{ Algorithm = "X16r";             Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo x16r" } # TeamRedMiner-v0.10.2 is fastest
    [PSCustomObject]@{ Algorithm = "X16rt";            Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x16rt" }
    [PSCustomObject]@{ Algorithm = "X16rv2";           Type = "AMD"; Fee = @(0.01); MinMemGB = 3;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo x16rv2" }
    [PSCustomObject]@{ Algorithm = "X16s";             Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x16s" }
    [PSCustomObject]@{ Algorithm = "X17";              Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X17r";             Type = "AMD"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x17r --protocol ufo2" }
    [PSCustomObject]@{ Algorithm = "X21s";             Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo x21s" } # TeamRedMiner-v0.10.2 is fastest
    [PSCustomObject]@{ Algorithm = "X22i";             Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo x22i" }
    [PSCustomObject]@{ Algorithm = "X33";              Type = "AMD"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x33" }
    [PSCustomObject]@{ Algorithm = "Xevan";            Type = "AMD"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo xevan" }
         
    [PSCustomObject]@{ Algorithm = "0x10";             Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo 0x10 --watchdog" }
    [PSCustomObject]@{ Algorithm = "Aergo";            Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo aergo --watchdog" }
    [PSCustomObject]@{ Algorithm = "Anime";            Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo anime --watchdog" }
    [PSCustomObject]@{ Algorithm = "AstralHash";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo glt-astralhash --watchdog" }
    [PSCustomObject]@{ Algorithm = "BCD";              Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo bcd --watchdog" }
    [PSCustomObject]@{ Algorithm = "Bitcore";          Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo bitcore --watchdog" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo blake2b-btcc --watchdog" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo blake2b-glt --watchdog" }
    [PSCustomObject]@{ Algorithm = "Bmw512";           Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 15); Arguments = " --algo bmw512 --watchdog" } # CcminerBmw512-v2.2.5 is fastest
    [PSCustomObject]@{ Algorithm = "C11";              Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo c11 --watchdog" }
    [PSCustomObject]@{ Algorithm = "CurveHash";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo curvehash --watchdog" }
    [PSCustomObject]@{ Algorithm = "Dedal";            Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo dedal --watchdog" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";           Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo exosis --watchdog" }
    [PSCustomObject]@{ Algorithm = "FiroPoW";          Type = "NVIDIA"; Fee = @(0.01); MinMemGB = $MinerPools[0]."FiroPoW".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(55, 45); Arguments = " --algo firopow --watchdog" }
    [PSCustomObject]@{ Algorithm = "Geek";             Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo geek --watchdog" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo ghostrider --watchdog" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo glt-globalhash --watchdog" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";        Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo heavyhash --watchdog" }
    [PSCustomObject]@{ Algorithm = "Hex";              Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo hex --watchdog" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";          Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 30); Arguments = " --algo hmq1725 --watchdog" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "JeongHash";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo glt-jeonghash --watchdog" } # Trex-v0.26.5 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";           Type = "NVIDIA"; Fee = @(0.01); MinMemGB = $MinerPools[0]."KawPoW".DAGSizeGB;  MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo kawpow --watchdog" } # NBMiner-v42.2 is fastest
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo lyra2v3 --watchdog" } # CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "Lyra2TDC";         Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo lyra2tdc --watchdog" }
    [PSCustomObject]@{ Algorithm = "Lyra2vc0ban";      Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo lyra2vc0ban --watchdog" }
    [PSCustomObject]@{ Algorithm = "MegaBtx";          Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 1;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --algo megabtx --watchdog" }
    [PSCustomObject]@{ Algorithm = "MegaMec";          Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 1;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo megamec --watchdog" }
    [PSCustomObject]@{ Algorithm = "Mike";             Type = "NVIDIA"; Fee = @(0.05); MinMemGB = 1;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo mike --watchdog" }
    [PSCustomObject]@{ Algorithm = "Minotaur";         Type = "NVIDIA"; Fee = @(0.05); MinMemGB = 1;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo minotaur --watchdog" }
    [PSCustomObject]@{ Algorithm = "MTP";              Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo mtp --watchdog" } # Trex-v0.26.5 is fastest
    [PSCustomObject]@{ Algorithm = "MTPTcr";           Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo mtp-tcr --watchdog" }
    [PSCustomObject]@{ Algorithm = "PadiHash";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo glt-padihash --watchdog" }
    [PSCustomObject]@{ Algorithm = "PawelHash";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo glt-pawelhash --watchdog" } # Trex-v0.26.5 is fastest
    [PSCustomObject]@{ Algorithm = "Phi";              Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo phi --watchdog" }
    [PSCustomObject]@{ Algorithm = "Phi5";             Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo phi5 --watchdog" }
    [PSCustomObject]@{ Algorithm = "Polytimos";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo polytimos --watchdog" }
    [PSCustomObject]@{ Algorithm = "ProgPoWSero";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo progpow-sero --watchdog" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeil";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo progpow-veil --watchdog" }
    [PSCustomObject]@{ Algorithm = "ProgPoWVeriblock"; Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo vprogpow --watchdog" }
    [PSCustomObject]@{ Algorithm = "ProgPoWZano";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo progpowz --watchdog" }
    [PSCustomObject]@{ Algorithm = "Sha256csm";        Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo sha256csm --watchdog" }
#   [PSCustomObject]@{ Algorithm = "Sha256t";          Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo sha256t --watchdog" } # Takes too long until it starts mining
    [PSCustomObject]@{ Algorithm = "Sha256q";          Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo sha256q --watchdog" }
    [PSCustomObject]@{ Algorithm = "Renesis";          Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo renesis --watchdog" }
    [PSCustomObject]@{ Algorithm = "Skein2";           Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(90, 15); Arguments = " --algo skein2 --watchdog" } # CcminerAlexis78-v1.5.2 is fastest
    [PSCustomObject]@{ Algorithm = "SkunkHash";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo skunkhash --watchdog" } # CryptoDredge-v0.27.0 is fastest
    [PSCustomObject]@{ Algorithm = "Sonoa";            Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 15); Arguments = " --algo sonoa --watchdog" } # Trex-v0.26.5 is fastest
    [PSCustomObject]@{ Algorithm = "Timetravel";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo timetravel --watchdog" }
    [PSCustomObject]@{ Algorithm = "Tribus";           Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo tribus --watchdog" }
    [PSCustomObject]@{ Algorithm = "WildKeccak";       Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo wildkecca --watchdog" }
    [PSCustomObject]@{ Algorithm = "X11k";             Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x11k --watchdog" }
    [PSCustomObject]@{ Algorithm = "X16r";             Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo x16r --watchdog" } # Trex-v0.26.5 is fastest
    [PSCustomObject]@{ Algorithm = "X16rt";            Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo x16rt --watchdog" }
    [PSCustomObject]@{ Algorithm = "X16rv2";           Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo x16rv2 --watchdog" }
    [PSCustomObject]@{ Algorithm = "X16s";             Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo x16s --watchdog" } # Trex-v0.26.5 is fastest
    [PSCustomObject]@{ Algorithm = "X17";              Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo x17 --watchdog" }
    [PSCustomObject]@{ Algorithm = "X17r";             Type = "NVIDIA"; Fee = @(0.02); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x17r --protocol ufo2 --watchdog" }
    [PSCustomObject]@{ Algorithm = "X21s";             Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo x21s --watchdog" } # Trex-v0.26.5 is fastest
#   [PSCustomObject]@{ Algorithm = "X22i";             Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 15); Arguments = " --algo x22i --watchdog" } # Algorithm is broken; Trex-v0.26.5 is fastest
    [PSCustomObject]@{ Algorithm = "X33";              Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2;                                  MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x33 --watchdog" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' ' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --api-port $MinerAPIPort --url stratum+tcp$(if ($MinerPools[0].$Algorithm_Norm.SSL) { "s" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).Port) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --multiple-instance --opencl-platforms $($AvailableMiner_Devices.PlatformId | Sort-Object -Unique) --opencl-devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    API         = "XmRig"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee # subtract devfee
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
