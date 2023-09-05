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
Version:        5.0.0.0
Version date:   2023/09/05
#>

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$URI = "https://github.com/fireworm71/veriumMiner/releases/download/v1.4/cpuminer_1.4_windows_x64_O2_GCC7.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\cpuminer.exe" 
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "ScryptN2"; MinerSet = 0; WarmupTimes = @(90, 30); ExcludePools = @(); Arguments = "" } # Empty command
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].PoolPorts[0] }

If ($Algorithms) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1)
    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

    $Algorithms | ForEach-Object { 

        $ExcludePools = $_.ExcludePools
        ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object { $_.PoolPorts[0] } | Where-Object BaseName -notin $ExcludePools)) { 

            [PSCustomObject]@{ 
                API         = "CcMiner"
                Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" }) --pass $($Pool.Pass) --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --retry-pause 1 --api-bind $MinerAPIPort"
                DeviceNames = $AvailableMiner_Devices.Name
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