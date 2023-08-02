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

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.6" } { "https://github.com/xiaolin1579/radiator/releases/download/v1.0.0/Radiator1.0.0_cuda11.6_Win64.zip"; Break }
    { $_ -ge "11.2" } { "https://github.com/xiaolin1579/radiator/releases/download/v1.0.0/Radiator1.0.0_cuda11.2_Win64.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "SHA512256d"; MinMemGiB = 2; MinerSet = 1; WarmupTimes = @(90, 0); ExcludeGPUArchitecture = @(); Arguments = " --algo=rad" }
    [PSCustomObject]@{ Algorithm = "SHA256dt";   MinMemGiB = 2; MinerSet = 1; WarmupTimes = @(90, 0); ExcludeGPUArchitecture = @("Pascal"); Arguments = " --algo=novo" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGiB -le 2) { $Arguments = $Arguments -replace " --intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "CcMiner"
                    Arguments   = ("$($Arguments) --url stratum+tcp://$($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts[0]) --user $($AllMinerPools.($_.Algorithm).User)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" }) --pass $($AllMinerPools.($_.Algorithm).Pass) --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    MinerSet    = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "NVIDIA"
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}