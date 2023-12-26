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
Version:        5.0.2.5
Version date:   2023/12/20
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/RavenCommunity/kawpowminer/releases/download/1.2.4/kawpowminer-windows-cuda11-1.2.4.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\kawpowminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "KawPow"; MinMemGiB = 0.93; Minerset = 2; WarmupTimes = @(75, 10); ExcludePools = @(); Arguments = "" }
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

                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                            $Protocol = Switch ($Pool.Protocol) { 
                                "ethproxy"     { "stratum1" }
                                "ethstratum1"  { "stratum2" }
                                "ethstratum2"  { "stratum2" }
                                Default        { "stratum" }
                            }
                            $Protocol += If ($Pool.PoolPorts[1]) { "+ssl" } Else { "+tcp" }

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = "$($_.Arguments) --pool $($Protocol)://$([System.Web.HttpUtility]::UrlEncode("$($Pool.User)")):$([System.Web.HttpUtility]::UrlEncode($($Pool.Pass)))@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --farm-recheck 10000 --farm-retries 40 --work-timeout 100000 --response-timeout 720 --api-bind 127.0.0.1:-$($MinerAPIPort) --cuda --cuda-devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
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