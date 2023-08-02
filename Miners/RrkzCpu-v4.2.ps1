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
Version:        4.3.6.0
Version date:   31 July 2023
#>

If (-not ($AvailableMiner_Devices = $Variables.EnabledDevices | Where-Object Type -EQ "CPU")) { Return }

$Uri = "https://github.com/RickillerZ/cpuminer-RKZ/releases/download/V4.2b/cpuminer-RKZ.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$()$Name)\cpuminer.exe"

$Algorithms = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "CpuPower"; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo cpupower" } # ASIC SRBMinerMulti-v2.3.1 is fastest, but has 0.85% miner fee
    [PSCustomObject]@{ Algorithm = "Power2b";  Minerset = 2; WarmupTimes = @(30, 0);  Arguments = " --algo power2b" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }

If ($Algorithms) { 

    $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices.Id | Sort-Object -Top 1) + 1)
    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

    $Algorithms | ForEach-Object { 

        $Arguments = $_Arguments

        # Get arguments for available miner devices
        # $Arguments = Get-ArgumentsPerDevice -Arguments $_ .Command -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Algorithms  = @($_.Algorithm)
            API         = "CcMiner"
            Arguments   = ("$($Arguments) --url $(If ($AllMinerPools.($_.Algorithm).PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($AllMinerPools.($_.Algorithm).User)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" }) --pass $($AllMinerPools.($_.Algorithm).Pass) --cpu-affinity AAAA --quiet --threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
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