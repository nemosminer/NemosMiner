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

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "NVIDIA" -and $_.OpenCL.DriverVersion -ge "450.80.02" })) { Return }

$Uri = "https://github.com/OneZeroMiner/onezerominer/releases/download/v1.2.2/onezerominer-win64-1.2.2.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\onezerominer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "DynexSolve"; Fee = @(0.03); MinMemGiB = 2; Minerset = 2; WarmupTimes = @(120, 0); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = @(" --algo dynex") }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }

If ($Algorithms) { 
    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model) 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            $Arguments = $_.Arguments

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    API         = "OneZero"
                    Arguments   = ("$($Arguments) --pool $($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts[0]) --wallet $($AllMinerPools.($_.Algorithm).User)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" }) --pass $($AllMinerPools.($_.Algorithm).Pass) --api-port $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
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