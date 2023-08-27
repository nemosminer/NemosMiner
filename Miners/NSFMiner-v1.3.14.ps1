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

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAVersion -ge "9.1") } )) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.3" } { "https://github.com/Minerx117/miners/releases/download/NSFMiner/nsfminer_1.3.14-windows_10-cuda_11.3-opencl.zip"; Break }
    { $_ -ge "11.2" } { "hhttps://github.com/Minerx117/miners/releases/download/NSFMiner/nsfminer_1.3.13-windows_10-cuda_11.2-opencl.zip"; Break }
    Default           { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nsfminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# AMD miners may need https://github.com/ethereum-mining/ethminer/issues/2001
# NVIDIA Enable Hardware-Accelerated GPU Scheduling

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Ethash"; Type = "AMD"; MinMemGiB = 0.87; MinerSet = 0; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --opencl --devices" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool

    [PSCustomObject]@{ Algorithm = "Ethash"; Type = "NVIDIA"; MinMemGiB = 0.87; MinerSet = 0; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --cuda --devices" } # PhoenixMiner-v6.2c is fastest but has dev fee
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePools }

If ($Algorithms) { 

    $Algorithms | ForEach-Object { 
        $_.MinMemGiB += $AllMinerPools.($_.Algorithm).DAGSizeGiB
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -eq $_.Type | ForEach-Object { 

            $MinMemGiB = $_.MinMemGiB + $_.MemReserveGiB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $MinMemGiB) { 

                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

                $Pass = "$($AllMinerPools.($_.Algorithm).Pass)"

                $Protocol = Switch ($AllMinerPools.($_.Algorithm).Protocol) { 
                    "ethstratum1"  { "stratum2"; Break }
                    "ethstratum2"  { "stratum3"; Break }
                    "ethstratumnh" { "stratum2"; Break }
                    Default        { "stratum" }
                }
                $Protocol += If ($AllMinerPools.($_.Algorithm).PoolPorts[1]) { "+ssl" } Else { "+tcp" }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Arguments   = ("--pool $($Protocol)://$([System.Web.HttpUtility]::UrlEncode("$($AllMinerPools.($_.Algorithm).User)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" })")):$([System.Web.HttpUtility]::UrlEncode($Pass))@$($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts | Select-Object -Last 1) --exit --api-port -$MinerAPIPort $($_.Arguments) $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    EnvVars     = If ($Miner_Devices.Type -eq "AMD") { @("GPU_FORCE_64BIT_PTR=0") } Else { @() }
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = $_.Type
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}