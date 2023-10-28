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
Version:        5.0.1.6
Version date:   2023/10/06
#>

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$URI = "https://github.com/Raptor3um/cpuminer-opt/releases/download/v2.0/cpuminer-take2-windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$($Name)\cpuminer-aes-sse42.exe" # Intel

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Ghostrider"; Minerset = 1; WarmupTimes = @(180, 60); ExcludePools = @(); Arguments = " --algo gr" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].PoolPorts[0] }

If ($Algorithms) { 

    If ($AvailableMiner_Devices.CpuFeatures -match 'avx2')     { $Path = "$PWD\Bin\$($Name)\cpuminer-avx2.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'avx')  { $Path = "$PWD\Bin\$($Name)\cpuminer-avx.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'aes')  { $Path = "$PWD\Bin\$($Name)\cpuminer-aes-sse42.exe" }
    ElseIf ($AvailableMiner_Devices.CpuFeatures -match 'sse2') { $Path = "$PWD\Bin\$($Name)\cpuminer-sse2.exe" }
    Else { Return }

    $MinerAPIPort = $Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1
    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

    $Algorithms | ForEach-Object { 

        $ExcludePools = $_.ExcludePools
        ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object BaseName -notin $ExcludePools | Select-Object -Last 1)) {  

            [PSCustomObject]@{ 
                API         = "CcMiner"
                Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" }) --pass $($Pool.Pass) --hash-meter --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)"
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
}