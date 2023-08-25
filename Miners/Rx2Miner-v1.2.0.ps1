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
Version:        4.3.6.2
Version date:   2023/08/25
#>

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return } 

$URI = "https://github.com/LUX-Core/rx2-cpuminer/releases/download/1.2.0-alpha/cpminer-msr.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\cpuminer.exe"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Rx2"; Minerset = 2; WarmupTimes = @(105, 15); Arguments = " --algo rx2" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }

If ($Algorithms) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1)
    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

    $Algorithms | ForEach-Object { 

        [PSCustomObject]@{ 
            Algorithms  = @($_.Algorithm)
            API         = "CcMiner"
            Arguments   = ("$($_.Arguments) --url $(If ($AllMinerPools.($_.Algorithm).PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($AllMinerPools.($_.Algorithm).User)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" }) --pass $($AllMinerPools.($_.Algorithm).Pass) --retry-pause 1 --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
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