If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.29/cpuminer-opt-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName

If ($AvailableMiner_Devices.CpuFeatures -match "avx512")   { $Path = ".\Bin\$($Name)\cpuminer-Avx512.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx2") { $Path = ".\Bin\$($Name)\cpuminer-Avx2.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx")  { $Path = ".\Bin\$($Name)\cpuminer-Avx.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match "aes")  { $Path = ".\Bin\$($Name)\cpuminer-Aes-Sse42.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match "sse2") { $Path = ".\Bin\$($Name)\cpuminer-Sse2.exe" }
Else { Return }

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Avian";         Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo avian" }
    [PSCustomObject]@{ Algorithm = "Allium";        MinerSet = 3; WarmupTimes = @(30, 0);  Arguments = " --algo allium" } # FPGA
    [PSCustomObject]@{ Algorithm = "Anime";         MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo anime" }
#   [PSCustomObject]@{ Algorithm = "Argon2ad";      Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo argon2ad" } # ASIC
    [PSCustomObject]@{ Algorithm = "Argon2d250";    Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo argon2d250" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";    Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo argon2d500" }
    [PSCustomObject]@{ Algorithm = "Argon2d4096";   Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo argon2d4096" }
    [PSCustomObject]@{ Algorithm = "Axiom";         Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo axiom" }
    [PSCustomObject]@{ Algorithm = "Balloon";       Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo balloon" }
    [PSCustomObject]@{ Algorithm = "Blake2b";       Minerset = 3; WarmupTimes = @(30, 30); Arguments = " --algo blake2b" } # FPGA
    [PSCustomObject]@{ Algorithm = "Bmw";           Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo bmw" }
#   [PSCustomObject]@{ Algorithm = "Bmw512";        MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo bmw512" } # ASIC
    [PSCustomObject]@{ Algorithm = "C11";           Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo c11" } # GPU
    [PSCustomObject]@{ Algorithm = "Circcash";      Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo circcash" }
#   [PSCustomObject]@{ Algorithm = "CpuPower";      Minerset = 3; WarmupTimes = @(60, 60); Arguments = " --algo cpupower" } # ASIC
    [PSCustomObject]@{ Algorithm = "CryptoVantaA";  Minerset = 2; WarmupTimes = @(60, 60); Arguments = " --algo cryptovantaa" }
#   [PSCustomObject]@{ Algorithm = "CurveHash";     Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --algo curvehash" } # reported hashrates too high (https://github.com/rplant8/cpuminer-opt-rplant/issues/21)
#   [PSCustomObject]@{ Algorithm = "Decred";        Minerset = 3; WarmupTimes = @(60, 60); Arguments = " --algo Decred" } # ASIC, No hashrate in time
#   [PSCustomObject]@{ Algorithm = "DMDGr";         Minerset = 3; WarmupTimes = @(60, 60); Arguments = " --algo dmd-gr" } # ASIC
    [PSCustomObject]@{ Algorithm = "Ghostrider";    MinerSet = 0; WarmupTimes = @(90, 10); Arguments = " --algo gr" }
#   [PSCustomObject]@{ Algorithm = "Groestl";       Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --algo groestl" } # ASIC
    [PSCustomObject]@{ Algorithm = "HeavyHash";     MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo heavyhash" } # FPGA
    [PSCustomObject]@{ Algorithm = "Hex";           Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo hex" } # GPU
    [PSCustomObject]@{ Algorithm = "HMQ1725";       MinerSet = 3; WarmupTimes = @(30, 0);  Arguments = " --algo hmq1725" } # GPU
    [PSCustomObject]@{ Algorithm = "Hodl";          Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo hodl" }
    [PSCustomObject]@{ Algorithm = "Jha";           Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --algo jha" } # GPU
#   [PSCustomObject]@{ Algorithm = "Keccak";        Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --algo keccak" } # ASIC
#   [PSCustomObject]@{ Algorithm = "KeccakC";       MinerSet = 3; WarmupTimes = @(90, 15); Arguments = " --algo keccakc" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lbry";          Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --algo lbry" } # ASIC
    [PSCustomObject]@{ Algorithm = "Lyra2h";        Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --algo lyra2h" }
#   [PSCustomObject]@{ Algorithm = "Lyra2RE";       Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --algo lyra2re" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2RE2";      Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --algo lyra2rev2" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";      Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --algo lyra2rev3" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2Z";        MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algo lyra2z" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";     Minerset = 3; WarmupTimes = @(90, 25); Arguments = " --algo lyra2z330" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "Mike";          MinerSet = 3; WarmupTimes = @(90, 35); Arguments = " --algo mike" } # GPU
    [PSCustomObject]@{ Algorithm = "Minotaur";      Minerset = 2; WarmupTimes = @(90, 15); Arguments = " --algo minotaur" }
    [PSCustomObject]@{ Algorithm = "MinotaurX";     MinerSet = 0; WarmupTimes = @(90, 0);  Arguments = " --algo minotaurx" }
#   [PSCustomObject]@{ Algorithm = "MyriadGroestl"; Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --algo myr-gr" } # ASIC
    [PSCustomObject]@{ Algorithm = "Neoscrypt";     MinerSet = 3; WarmupTimes = @(90, 20); Arguments = " --algo neoscrypt" } # FPGA
#   [PSCustomObject]@{ Algorithm = "Nist5";         Minerset = 3; WarmupTimes = @(90, 15); Arguments = " --algo nist5" } # ASIC
    [PSCustomObject]@{ Algorithm = "Pentablake";    Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo pentablake" } # GPU
    [PSCustomObject]@{ Algorithm = "Phi2";          Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo phi2" } # GPU
    [PSCustomObject]@{ Algorithm = "Phi5";          Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo phi5" } # GPU
    [PSCustomObject]@{ Algorithm = "Phi1612";       Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo phi1612" }
    [PSCustomObject]@{ Algorithm = "Phichox";       Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo phichox" } # GPU
    [PSCustomObject]@{ Algorithm = "Polytimos";     Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo polytimos" } # GPU
    [PSCustomObject]@{ Algorithm = "Pulsar";        Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo pulsar" }
    [PSCustomObject]@{ Algorithm = "QogeCoin";      Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo qogecoin" }
#   [PSCustomObject]@{ Algorithm = "Quark";         Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo quark" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Qubit";         Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo qubit" } # ASIC
    [PSCustomObject]@{ Algorithm = "Qureno";        Minerset = 3; WarmupTimes = @(30, 15); Arguments = " --algo qureno" } # GPU
#   [PSCustomObject]@{ Algorithm = "X11";           Minerset = 3; WarmupTimes = @(30, 15); Srguments = " --algo x11" } # ASIC, algorithm not supported
    [PSCustomObject]@{ Algorithm = "X22";           Minerset = 2; WarmupTimes = @(30, 15); Arguments = " --algo x22" } 
    [PSCustomObject]@{ Algorithm = "Yescrypt";      MinerSet = 0; WarmupTimes = @(45, 10); Arguments = " --algo yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";   MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yescryptr16" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    [PSCustomObject]@{ Algorithm = "YescryptR8";    Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yescryptr8" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    [PSCustomObject]@{ Algorithm = "YescryptR8g";   Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yescryptr8g" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";   MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --algo yescryptr32" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "Yespower";      MinerSet = 0; WarmupTimes = @(45, 15); Arguments = " --algo yespower" }
    [PSCustomObject]@{ Algorithm = "Yespower2b";    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo power2b" }
    [PSCustomObject]@{ Algorithm = "YespowerARWN";  Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerarwn" }
    [PSCustomObject]@{ Algorithm = "YespowerIc";    Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerIC" }
    [PSCustomObject]@{ Algorithm = "YespowerIots";  Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerIOTS" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";   Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerITC" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerLitb";  Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerLITB" }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg"; Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerLTNCG" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";   Minerset = 2; WarmupTimes = @(60, 10); Arguments = " --algo yespowerr16" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerRes";   Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerRes" }
    [PSCustomObject]@{ Algorithm = "YespowerSugar"; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerSugar" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerTIDE";  MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerTIDE" }
    [PSCustomObject]@{ Algorithm = "YespowerUrx";   Minerset = 2; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerURX" } # JayddeeCpu-v3.22.2 is faster, SRBMminerMulti is fastest, but has 0.85% miner fee
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }

If ($Algorithms) { 
    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1)
    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)" -replace ' '

    $Algorithms | ForEach-Object { 

        $Arguments = $_.Arguments

        # Get arguments for available miner devices
        # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Algorithms  = @($_.Algorithm)
            API         = "Ccminer"
            Arguments   = ("$($Arguments) --url $(If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "stratum+tcps" } Else { "stratum+tcp" })://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { " --rig-id $($MinerPools[0].($_.Algorithm).WorkerName)" }) --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            DeviceNames = $AvailableMiner_Devices.Name
            MinerSet    = $_.MinerSet
            Name        = $Miner_Name
            Path        = $Path
            Port        = $MinerAPIPort
            Type        = "CPU"
            URI         = $Uri
            WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
        }
    }
}