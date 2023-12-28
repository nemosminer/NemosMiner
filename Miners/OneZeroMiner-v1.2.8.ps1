<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
Version:        5.0.2.6
Version date:   2023/12/28
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "NVIDIA" -and $_.OpenCL.DriverVersion -ge [Version]"450.80.02" }))) { Return }

$URI = "https://github.com/OneZeroMiner/onezerominer/releases/download/v1.2.8/onezerominer-win64-1.2.8.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\onezerominer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @( 
    [PSCustomObject]@{ Algorithm = "DynexSolve"; Fee = @(0.03); MinMemGiB = 2; Minerset = 0; WarmupTimes = @(180, 0); ExcludeGPUArchitecture = @(); ExcludePools = @("ZergPool"); Arguments = @(" --algo dynex") }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            $Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model) 
            $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $ExcludePools = $_.ExcludePools
                    ForEach ($Pool in ($MinerPools[0][$_.Algorithm].Where({ $_.Name -notin $ExcludePools }))) { 

                        $ExcludeArchitecture = $_.ExcludeArchitecture
                        $MinMemGiB = $_.MinMemGiB
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notin $ExcludeArchitecture })) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                            [PSCustomObject]@{ 
                                API         = "OneZero"
                                Arguments   = "$($_.Arguments) --pool $(If ($Pool.PoolPorts[1]) { "ssl://"} )$($Pool.Host):$($Pool.PoolPorts[0] | Select-Object -Last 1) --wallet $($Pool.User) --pass $($Pool.Pass)$(If ($Pool.PoolPorts[1] -and $Config.SSLAllowSelfSignedCertificate) { " --no-cert-validation" } ) --api-port $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMiner_Devices.Name
                                Fee         = $_.Fee # Dev fee
                                MinerSet    = $_.MinerSet
                                Name        = $Miner_Name
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "NVIDIA"
                                URI         = $Uri
                                WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}