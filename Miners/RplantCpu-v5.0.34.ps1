<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
Version:        5.0.2.3
Version date:   2023/12/20
#>

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "CPU" }))) { Return }

$URI = "https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.34/cpuminer-opt-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName

If ($AvailableMiner_Devices.CpuFeatures -match 'avx512')   { $Path = "$PWD\Bin\$Name\cpuminer-Avx512.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'avx2') { $Path = "$PWD\Bin\$Name\cpuminer-Avx2.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'avx')  { $Path = "$PWD\Bin\$Name\cpuminer-Avx.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'aes')  { $Path = "$PWD\Bin\$Name\cpuminer-Aes-Sse42.exe" }
ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'sse2') { $Path = "$PWD\Bin\$Name\cpuminer-Sse2.exe" }
Else { Return }

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Avian";         Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo avian" }
    [PSCustomObject]@{ Algorithm = "Allium";        MinerSet = 3; WarmupTimes = @(30, 0);   ExcludePools = @();        Arguments = " --algo allium" } # FPGA
    [PSCustomObject]@{ Algorithm = "Anime";         MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo anime" }
#   [PSCustomObject]@{ Algorithm = "Argon2ad";      Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo argon2ad" } # ASIC
    [PSCustomObject]@{ Algorithm = "Argon2d250";    Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo argon2d250" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";    Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo argon2d500" }
    [PSCustomObject]@{ Algorithm = "Argon2d4096";   Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo argon2d4096" }
    [PSCustomObject]@{ Algorithm = "Axiom";         Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo axiom" }
    [PSCustomObject]@{ Algorithm = "Balloon";       Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @("Zpool"); Arguments = " --algo balloon" }
    [PSCustomObject]@{ Algorithm = "Blake2b";       Minerset = 3; WarmupTimes = @(30, 30);  ExcludePools = @();        Arguments = " --algo blake2b" } # FPGA
    [PSCustomObject]@{ Algorithm = "Bmw";           Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo bmw" }
#   [PSCustomObject]@{ Algorithm = "Bmw512";        MinerSet = 0; WarmupTimes = @(30, 0);   ExcludePools = @();        Arguments = " --algo bmw512" } # ASIC
    [PSCustomObject]@{ Algorithm = "C11";           Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo c11" } # GPU
    [PSCustomObject]@{ Algorithm = "Circcash";      Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo circcash" }
#   [PSCustomObject]@{ Algorithm = "CpuPower";      Minerset = 3; WarmupTimes = @(60, 60);  ExcludePools = @();        Arguments = " --algo cpupower" } # ASIC
    [PSCustomObject]@{ Algorithm = "CryptoVantaA";  Minerset = 2; WarmupTimes = @(60, 60);  ExcludePools = @();        Arguments = " --algo cryptovantaa" }
#   [PSCustomObject]@{ Algorithm = "CurveHash";     Minerset = 2; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo curvehash" } # reported hashrates too high (https://github.com/rplant8/cpuminer-opt-rplant/issues/21)
#   [PSCustomObject]@{ Algorithm = "Decred";        Minerset = 3; WarmupTimes = @(60, 60);  ExcludePools = @();        Arguments = " --algo Decred" } # ASIC, No hashrate in time
#   [PSCustomObject]@{ Algorithm = "DMDGr";         Minerset = 3; WarmupTimes = @(60, 60);  ExcludePools = @();        Arguments = " --algo dmd-gr" } # ASIC
    [PSCustomObject]@{ Algorithm = "Ghostrider";    MinerSet = 0; WarmupTimes = @(180, 60); ExcludePools = @();        Arguments = " --algo gr" }
#   [PSCustomObject]@{ Algorithm = "Groestl";       Minerset = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo groestl" } # ASIC
    [PSCustomObject]@{ Algorithm = "HeavyHash";     MinerSet = 0; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo heavyhash" } # FPGA
    [PSCustomObject]@{ Algorithm = "Hex";           Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo hex" } # GPU
    [PSCustomObject]@{ Algorithm = "HMQ1725";       MinerSet = 3; WarmupTimes = @(30, 0);   ExcludePools = @();        Arguments = " --algo hmq1725" } # GPU
    [PSCustomObject]@{ Algorithm = "Hodl";          Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo hodl" }
    [PSCustomObject]@{ Algorithm = "Jha";           Minerset = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo jha" } # GPU
#   [PSCustomObject]@{ Algorithm = "Keccak";        Minerset = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo keccak" } # ASIC
#   [PSCustomObject]@{ Algorithm = "KeccakC";       MinerSet = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo keccakc" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lbry";          Minerset = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo lbry" } # ASIC
    [PSCustomObject]@{ Algorithm = "Lyra2h";        Minerset = 2; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo lyra2h" }
    [PSCustomObject]@{ Algorithm = "Lyra2a40";      Minerset = 0; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo lyra2a40" }
#   [PSCustomObject]@{ Algorithm = "Lyra2RE";       Minerset = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo lyra2re" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2RE2";      Minerset = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo lyra2rev2" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";      Minerset = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo lyra2rev3" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2Z";        MinerSet = 0; WarmupTimes = @(90, 0);   ExcludePools = @();        Arguments = " --algo lyra2z" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";     Minerset = 3; WarmupTimes = @(90, 25);  ExcludePools = @();        Arguments = " --algo lyra2z330" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "MemeHash";      MinerSet = 0; WarmupTimes = @(90, 35);  ExcludePools = @();        Arguments = " --algo memehashv2" }
    [PSCustomObject]@{ Algorithm = "Mike";          MinerSet = 3; WarmupTimes = @(90, 60);  ExcludePools = @();        Arguments = " --algo mike" } # GPU
    [PSCustomObject]@{ Algorithm = "Minotaur";      Minerset = 2; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo minotaur" }
    [PSCustomObject]@{ Algorithm = "MinotaurX";     MinerSet = 0; WarmupTimes = @(90, 0);   ExcludePools = @();        Arguments = " --algo minotaurx" }
#   [PSCustomObject]@{ Algorithm = "MyriadGroestl"; Minerset = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo myr-gr" } # ASIC
    [PSCustomObject]@{ Algorithm = "Neoscrypt";     MinerSet = 3; WarmupTimes = @(90, 20);  ExcludePools = @();        Arguments = " --algo neoscrypt" } # FPGA
#   [PSCustomObject]@{ Algorithm = "Nist5";         Minerset = 3; WarmupTimes = @(90, 15);  ExcludePools = @();        Arguments = " --algo nist5" } # ASIC
    [PSCustomObject]@{ Algorithm = "Pentablake";    Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo pentablake" } # GPU
    [PSCustomObject]@{ Algorithm = "Phi2";          Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo phi2" } # GPU
    [PSCustomObject]@{ Algorithm = "Phi5";          Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo phi5" } # GPU
    [PSCustomObject]@{ Algorithm = "Phi1612";       Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo phi1612" }
    [PSCustomObject]@{ Algorithm = "Phichox";       Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo phichox" } # GPU
    [PSCustomObject]@{ Algorithm = "Polytimos";     Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo polytimos" } # GPU
    [PSCustomObject]@{ Algorithm = "Pulsar";        Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo pulsar" }
    [PSCustomObject]@{ Algorithm = "QogeCoin";      Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo qogecoin" }
#   [PSCustomObject]@{ Algorithm = "Quark";         Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo quark" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Qubit";         Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo qubit" } # ASIC
    [PSCustomObject]@{ Algorithm = "Qureno";        Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo qureno" } # GPU
#   [PSCustomObject]@{ Algorithm = "X11";           Minerset = 3; WarmupTimes = @(30, 15);  ExcludePools = @();        Srguments = " --algo x11" } # ASIC, algorithm not supported
    [PSCustomObject]@{ Algorithm = "X22";           Minerset = 2; WarmupTimes = @(30, 15);  ExcludePools = @();        Arguments = " --algo x22" } 
    [PSCustomObject]@{ Algorithm = "Yescrypt";      MinerSet = 0; WarmupTimes = @(45, 10);  ExcludePools = @();        Arguments = " --algo yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR16";   MinerSet = 0; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yescryptr16" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    [PSCustomObject]@{ Algorithm = "YescryptR8";    Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yescryptr8" } # CcminerLyraYesscrypt-v8.21r18v5 is faster
    [PSCustomObject]@{ Algorithm = "YescryptR8g";   Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yescryptr8g" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";   MinerSet = 0; WarmupTimes = @(45, 15);  ExcludePools = @();        Arguments = " --algo yescryptr32" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "Yespower";      MinerSet = 0; WarmupTimes = @(45, 15);  ExcludePools = @();        Arguments = " --algo yespower" }
    [PSCustomObject]@{ Algorithm = "Yespower2b";    MinerSet = 0; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo power2b" }
    [PSCustomObject]@{ Algorithm = "YespowerARWN";  Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerarwn" }
    [PSCustomObject]@{ Algorithm = "YespowerIc";    Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerIC" }
    [PSCustomObject]@{ Algorithm = "YespowerIots";  Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerIOTS" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";   Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerITC" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerLitb";  Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerLITB" }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg"; Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerLTNCG" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";   Minerset = 2; WarmupTimes = @(60, 10);  ExcludePools = @();        Arguments = " --algo yespowerr16" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerRes";   Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerRes" }
    [PSCustomObject]@{ Algorithm = "YespowerSugar"; MinerSet = 1; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerSugar" } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerTIDE";  MinerSet = 0; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerTIDE" }
    [PSCustomObject]@{ Algorithm = "YespowerUrx";   Minerset = 2; WarmupTimes = @(45, 0);   ExcludePools = @();        Arguments = " --algo yespowerURX" } # JayddeeCpu-v23.15 is faster, SRBMminerMulti is fastest, but has 0.85% miner fee
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    $MinerAPIPort = $Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1
    $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

    $Algorithms.ForEach(
        { 
            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm].Where({ $_.Name -notin $ExcludePools }) | Select-Object -Last 1)) { 

                [PSCustomObject]@{ 
                    API         = "CcMiner"
                    Arguments   = "$($_.Arguments) --url $(If ($Pool.PoolPorts[1]) { "stratum+tcps" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User) --pass $($Pool.Pass)$(If ($Pool.WorkerName) { " --rig-id $($Pool.WorkerName)" }) --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)"
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = @(0) # Dev fee
                    MinerSet    = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "CPU"
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                    Workers     = @(@{ Pool = $Pool })
                }
            }
        }
    )
}