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

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAVersion -ge [Version]"9.1") }))) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.6" } { "https://github.com/Minerx117/miners/releases/download/EthMiner/ethminer-0.19.0-18-cuda11.6-windows-vs2019-amd64.zip"; Break }
    { $_ -ge "10.0" } { "https://github.com/Minerx117/miners/releases/download/EthMiner/ethminer-0.19.0-18-cuda10.0-windows-amd64.zip"; Break }
    Default           { "https://github.com/Minerx117/miners/releases/download/EthMiner/ethminer-0.19.0-18-cuda9.1-windows-amd64.zip" }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\ethminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# AMD miners may need https://github.com/ethereum-mining/ethminer/issues/2001
# NVIDIA Enable Hardware-Accelerated GPU Scheduling

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Ethash"; Type = "AMD"; MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(); Arguments = " --opencl --opencl-devices" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool

    [PSCustomObject]@{ Algorithm = "Ethash"; Type = "NVIDIA"; MinMemGiB = 1.24; MinerSet = 0; WarmupTimes = @(45, 10); ExcludePools = @(); Arguments = " --cuda --cuda-devices" } # PhoenixMiner-v6.2c is fastest but has dev fee
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -LE $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })

If ($Algorithms) { 

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
            $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

            ($Algorithms | Where-Object Type -eq $_.Type).ForEach(
                { 
                    $ExcludePools = $_.ExcludePools
                    ForEach ($Pool in ($MinerPools[0][$_.Algorithm].Where({ $_.Name -notin $ExcludePools }))) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                            $Pass = "$($Pool.Pass)"

                            $Protocol = Switch ($Pool.Protocol) { 
                                "ethstratum1"  { "stratum2"; Break }
                                "ethstratum2"  { "stratum3"; Break }
                                "ethstratumnh" { "stratum2"; Break }
                                Default        { "stratum" }
                            }
                            $Protocol += If ($Pool.PoolPorts[1]) { "+tls" } Else { "+tcp" }

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = " --pool $($Protocol)://$([System.Web.HttpUtility]::UrlEncode("$($Pool.User)")):$([System.Web.HttpUtility]::UrlEncode($Pass))@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --exit --api-port -$MinerAPIPort $($_.Arguments) $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ' ')"
                                DeviceNames = $AvailableMiner_Devices.Name
                                EnvVars     = @("SSL_NOVERIFY=TRUE")
                                Fee         = @(0) # Dev fee
                                MinerSet    = $_.MinerSet
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                Name        = $Miner_Name
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = $_.Type
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