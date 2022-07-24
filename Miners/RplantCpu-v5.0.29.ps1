using module ..\Includes\Include.psm1

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.29/cpuminer-opt-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\cpuminer-sse42.exe"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Avian";         MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo avian" }
    [PSCustomObject]@{ Algorithm = "Allium";        MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo allium" }
    [PSCustomObject]@{ Algorithm = "Anime";         MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo anime" }
    [PSCustomObject]@{ Algorithm = "Argon2ad";      MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo argon2ad" }
    [PSCustomObject]@{ Algorithm = "Argon2d250";    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo argon2d250" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo argon2d500" }
    [PSCustomObject]@{ Algorithm = "Argon2d4096";   MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo argon2d4096" }
    [PSCustomObject]@{ Algorithm = "Axiom";         MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo axiom" }
    [PSCustomObject]@{ Algorithm = "Balloon";       MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo balloon" }
    [PSCustomObject]@{ Algorithm = "Blake2b";       MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo blake2b" }
    [PSCustomObject]@{ Algorithm = "Bmw";           MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo bmw" }
    [PSCustomObject]@{ Algorithm = "Bmw512";        MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo bmw512" }
#   [PSCustomObject]@{ Algorithm = "C11";           MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo c11" } # ASIC
    [PSCustomObject]@{ Algorithm = "Circcash";      MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo circcash" }
    [PSCustomObject]@{ Algorithm = "CpuPower";      MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo cpupower" }
    [PSCustomObject]@{ Algorithm = "CryptoVantaA";  MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo cryptovantaa" }
#   [PSCustomObject]@{ Algorithm = "CurveHash";     MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo curvehash" } # reported hashrates too high (https://github.com/rplant8/cpuminer-opt-rplant/issues/21)
#   [PSCustomObject]@{ Algorithm = "Decred";        MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo Decred" } # ASIC
    [PSCustomObject]@{ Algorithm = "DMDGr";         MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo dmd-gr" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";    MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo gr" }
#   [PSCustomObject]@{ Algorithm = "Groestl";       MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo groestl" } # ASIC
    [PSCustomObject]@{ Algorithm = "HeavyHash";     MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo heavyhash" }
    [PSCustomObject]@{ Algorithm = "Hex";           MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo hex" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";       MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo hmq1725" }
    [PSCustomObject]@{ Algorithm = "Hodl";          MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo hodl" }
    [PSCustomObject]@{ Algorithm = "Jha";           MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo jha" }
#   [PSCustomObject]@{ Algorithm = "Lbry";          MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo lbry" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Keccak";        MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo keccak" } # ASIC
#   [PSCustomObject]@{ Algorithm = "KeccakC";       MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo keccakc" } # ASIC
    [PSCustomObject]@{ Algorithm = "Lyra2h";        MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo lyra2h" }
#   [PSCustomObject]@{ Algorithm = "Lyra2re";       MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo lyra2re" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2REv2";     MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo lyra2rev2" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";      MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo lyra2rev3" } # ASIC
    [PSCustomObject]@{ Algorithm = "Lyra2z";        MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo lyra2z" }
    [PSCustomObject]@{ Algorithm = "Lyra2z330";     MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo lyra2z330" }
    [PSCustomObject]@{ Algorithm = "Mike";          MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo mike" }
    [PSCustomObject]@{ Algorithm = "Minotaur";      MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo minotaur" }
    [PSCustomObject]@{ Algorithm = "MinotaurX";     MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo minotaurx" }
#   [PSCustomObject]@{ Algorithm = "MyriadGroestl"; MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo myr-gr" } # ASIC
    [PSCustomObject]@{ Algorithm = "Neoscrypt";     MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo neoscrypt" }
#   [PSCustomObject]@{ Algorithm = "Nist5";         MinerSet = 0; WarmupTimes = @(90, 15); Arguments = " --algo nist5" } # ASIC
    [PSCustomObject]@{ Algorithm = "Pentablake";    MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo pentablake" }
    [PSCustomObject]@{ Algorithm = "Phi2";          MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo phi2" }
    [PSCustomObject]@{ Algorithm = "Phi5";          MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo phi5" }
    [PSCustomObject]@{ Algorithm = "Phi1612";       MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo phi1612" }
    [PSCustomObject]@{ Algorithm = "Phichox";       MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo phichox" }
    [PSCustomObject]@{ Algorithm = "Polytimos";     MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "Pulsar";        MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo pulsar" }
    [PSCustomObject]@{ Algorithm = "QogeCoin";      MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo qogecoin" }
#   [PSCustomObject]@{ Algorithm = "Quark";         MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo quark" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Qubit";         MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo qubit" } # ASIC
    [PSCustomObject]@{ Algorithm = "Qureno";        MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo qureno" }
    [PSCustomObject]@{ Algorithm = "Qureno";        MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo qureno" }
#   [PSCustomObject]@{ Algorithm = "X11";           MinerSet = 0; WarmupTimes = @(30, 15); Srguments = " --algo x11" } # ASIC
    [PSCustomObject]@{ Algorithm = "X22";           MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo x22" } 
    [PSCustomObject]@{ Algorithm = "Yescrypt";      MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";   MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo yescryptr16" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    [PSCustomObject]@{ Algorithm = "YescryptR8";    MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo yescryptr8" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    [PSCustomObject]@{ Algorithm = "YescryptR8g";   MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yescryptr8g" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";   MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yescryptr32" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "Yespower";      MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespower" }
    [PSCustomObject]@{ Algorithm = "Yespower2b";    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo power2b" }
    [PSCustomObject]@{ Algorithm = "YespowerARWN";  MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerarwn" }
    [PSCustomObject]@{ Algorithm = "YespowerIc";    MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerIC" }
    [PSCustomObject]@{ Algorithm = "YespowerIots";  MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerIOTS" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";   MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerITC" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerLitb";  MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerLITB" }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerLTNCG" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";   MinerSet = 0; WarmupTimes = @(60, 15); Arguments = " --algo yespowerr16" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerRes";   MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerRes" }
    [PSCustomObject]@{ Algorithm = "YespowerSugar"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerSugar" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerTIDE";  MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerTIDE" }
    [PSCustomObject]@{ Algorithm = "YespowerUrx";   MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo yespowerURX" } # JayddeeCpu-v3.20.0 is faster, SRBMminerMulti is fastest, but has 0.85% miner fee
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    If ($AvailableMiner_Devices.CpuFeatures -match "avx512")   { $Path = ".\Bin\$($Name)\cpuminer-Avx512.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx2") { $Path = ".\Bin\$($Name)\cpuminer-Avx2.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "avx")  { $Path = ".\Bin\$($Name)\cpuminer-Avx.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "aes")  { $Path = ".\Bin\$($Name)\cpuminer-Aes-Sse42.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match "sse2") { $Path = ".\Bin\$($Name)\cpuminer-Sse2.exe" }
    Else { Return }

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

    $Algorithms | ForEach-Object { 

        # Get arguments for available miner devices
        # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Name        = $Miner_Name
            DeviceNames = $AvailableMiner_Devices.Name
            Type        = $AvailableMiner_Devices.Type
            Path        = $Path
            Arguments   = ("$($_.Arguments) --url $(If ($Pools.($_.Algorithm).SSL) { "stratum+tcps" } Else { "stratum+tcp" })://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User)$(If ($Pools.($_.Algorithm).WorkerName) { ".$($Pools.($_.Algorithm).WorkerName)" }) --pass $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).WorkerName) { " --rig-id $($Pools.($_.Algorithm).WorkerName)" }) --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            Algorithms  = @($_.Algorithm)
            API         = "Ccminer"
            Port        = $MinerAPIPort
            URI         = $Uri
            WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
        }
    }
}
