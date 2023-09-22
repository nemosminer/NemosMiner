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
Version:        5.0.0.4
Version date:   2023/09/22
#>

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$URI = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.23.1/cpuminer-opt-3.23.1-windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" # Intel

If     ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx512", "sha", "vaes") -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = ".\Bin\$($Name)\cpuminer-avx512-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx2", "sha", "vaes")   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 3) { $Path = ".\Bin\$($Name)\cpuminer-avx2-sha-vaes.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx512")                -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = ".\Bin\$($Name)\cpuminer-avx512.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx2", "sha")           -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = ".\Bin\$($Name)\cpuminer-avx2-sha.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx2")                  -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = ".\Bin\$($Name)\cpuminer-avx2.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("avx")                   -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 1) { $Path = ".\Bin\$($Name)\cpuminer-avx.exe" }
ElseIf ((Compare-Object $AvailableMiner_Devices.CpuFeatures @("aes", "sse42")          -ExcludeDifferent -IncludeEqual -PassThru).Count -eq 2) { $Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" }
Else { Return }

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Blake2b";       MinerSet = 3; WarmupTimes = @(45, 30); ExcludePools = @(); Arguments = " --algo blake2b" } # FPGA
    [PSCustomObject]@{ Algorithm = "HMQ1725";       Minerset = 3; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = " --algo hmq1725" } # GPU
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";     MinerSet = 3; WarmupTimes = @(45, 45); ExcludePools = @(); Arguments = " --algo lyra2z330" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "m7m";           Minerset = 1; WarmupTimes = @(45, 80); ExcludePools = @(); Arguments = " --algo m7m" } # NosuchCpu-v3.8.8.1 is fastest
    [PSCustomObject]@{ Algorithm = "SHA3d";         MinerSet = 3; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo SHA3d" } # FPGA
    [PSCustomObject]@{ Algorithm = "ScryptN11";     Minerset = 3; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo scrypt(N,1,1)" } # GPU
    [PSCustomObject]@{ Algorithm = "ScryptN2";      Minerset = 1; WarmupTimes = @(90, 60); ExcludePools = @(); Arguments = " --algo scrypt --param-n 1048576" }
    [PSCustomObject]@{ Algorithm = "VertHash";      MinerSet = 0; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo verthash --data-file ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithm = "YespowerARWN";  Minerset = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "ARWN"' } # Arrowana
    [PSCustomObject]@{ Algorithm = "YespowerIc";    Minerset = 2; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "IsotopeC"' }
    [PSCustomObject]@{ Algorithm = "YespowerIots";  Minerset = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-key "Iots is committed to the development of IOT"' }
    [PSCustomObject]@{ Algorithm = "YespowerLitb";  Minerset = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LITBpower: The number of LITB working or available for proof-of-work mini"' }
    [PSCustomObject]@{ Algorithm = "YespowerLtncg"; Minerset = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "LTNCGYES"' }
    [PSCustomObject]@{ Algorithm = "YespowerMGPC";  Minerset = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Magpies are birds of the Corvidae family."' } # Magpiecoin
    [PSCustomObject]@{ Algorithm = "YespowerSugar"; Minerset = 1; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "Satoshi Nakamoto 31/Oct/2008 Proof-of-work is essentially one-CPU-one-vote"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "YespowerTIDE";  Minerset = 1; WarmupTimes = @(45, 55); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 8' } # TDC tidecoin
    [PSCustomObject]@{ Algorithm = "YespowerUrx";   MinerSet = 0; WarmupTimes = @(45, 60); ExcludePools = @(); Arguments = ' --algo yespower --param-n 2048 --param-r 32 --param-key "UraniumX"' } # SRBMminerMulti is fastest, but has 0.85% miner fee
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }

If ($Algorithms) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1)
    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

    $Algorithms | ForEach-Object { 

        $ExcludePools = $_.ExcludePools
        ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object BaseName -notin $ExcludePools | Select-Object -Last 1)) { 

            If ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                $PrerequisitePath = $Variables.VerthashDatPath
                $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
            }
            Else { 
                $PrerequisitePath = ""
                $PrerequisiteURI = ""
            }

            [PSCustomObject]@{ 
                API              = "CcMiner"
                Arguments        = "$($_.Arguments) --url $(If ($Pool.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" }) --pass $($Pool.Pass) --hash-meter --stratum-keepalive --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)"
                DeviceNames      = $AvailableMiner_Devices.Name
                MinerSet         = $_.MinerSet
                Name             = $Miner_Name
                Path             = $Path
                Port             = $MinerAPIPort
                PrerequisitePath = $PrerequisitePath
                PrerequisiteURI  = $PrerequisiteURI
                Type             = "CPU"
                URI              = $Uri
                WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                Workers          = @(@{ Pool = $Pool })
            }
        }
    }
}