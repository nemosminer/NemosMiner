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

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/EvrmoreOrg/evrprogpowminer/releases/download/v1.3.0-a66d921b/evrprogpowminer-windows64-v1p3p0-a66d921b.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\evrprogpowminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "EvrProgPow"; MinMemGiB = $MinerPools[0].EvrProgPow.DAGSizeGiB + 0.77; Minerset = 2; WarmupTimes = @(75, 10); ExcludePools = @(); Arguments = "" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -LE $Config.MinerSet })
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

                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        $MinMemGiB  = $_.MinMemGiB 
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                            $Protocol = Switch ($Pool.Protocol) { 
                                "ethproxy"     { "stratum1"; Break }
                                "ethstratum1"  { "stratum2"; Break }
                                "ethstratum2"  { "stratum2"; Break }
                                Default        { "stratum" }
                            }
                            $Protocol += If ($Pool.PoolPorts[1]) { "+tls" } Else { "+tcp" }

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = "$($_.Arguments) --pool $($Protocol)://$([System.Web.HttpUtility]::UrlEncode("$($Pool.User)")):$([System.Web.HttpUtility]::UrlEncode($($Pool.Pass)))@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --farm-recheck 10000 --farm-retries 40 --work-timeout 100000 --response-timeout 720 --api-port -$($MinerAPIPort) --cuda --cuda-devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMiner_Devices.Name
                                EnvVars     = @("SSL_NOVERIFY=TRUE")
                                Fee         = @(0) # Dev fee
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