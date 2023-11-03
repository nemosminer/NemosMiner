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
Version:        5.0.1.8
Version date:   2023/11/03
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -eq "AMD")) { Return }

$URI = "https://github.com/fancyIX/sgminer-phi2-branch/releases/download/0.9.4/sgminer-fancyIX-win64-0.9.4.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$($Name)\sgminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "0x10";          MinMemGiB = 2; Minerset = 2; WarmupTimes = @(60, 0); ExcludePools = @();           ExcludeGPUArchitecture = @();        Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel chainox" }
    [PSCustomObject]@{ Algorithm = "HeavyHash";     MinMemGiB = 2; Minerset = 1; WarmupTimes = @(60, 0); ExcludePools = @("ZergPool"); ExcludeGPUArchitecture = @("RDNA1"); Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 23 --kernel heavyhash" } # FPGA
    [PSCustomObject]@{ Algorithm = "Neoscrypt";     MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePools = @("ZergPool"); ExcludeGPUArchitecture = @();        Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel neoscrypt" } # FPGA
    [PSCustomObject]@{ Algorithm = "NeoscryptXaya"; MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePools = @("ZergPool"); ExcludeGPUArchitecture = @();        Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 17 --kernel neoscrypt-xaya" }
#   [PSCustomObject]@{ Algorithm = "YescryptR16";   MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePools = @();           ExcludeGPUArchitecture = @();        Arguments = " --scan-time 1 --gpu-threads 1 --worksize 256 --intensity 20 --pool-nfactor 100 --kernel yescryptr16" } # Invalid hash rate
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].PoolPorts[0] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

        $Algorithms | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object { $_.PoolPorts[0] } | Where-Object BaseName -notin $ExcludePools)) { 

                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    [PSCustomObject]@{ 
                        API         = "Xgminer"
                        Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" }) --pass $($Pool.Pass) --api-listen --api-port $MinerAPIPort --gpu-platform $($AvailableMiner_Devices.PlatformId | Sort-Object -Unique) --device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
                        DeviceNames = $AvailableMiner_Devices.Name
                        Fee         = @(0) # Dev fee
                        MinerSet    = $_.MinerSet
                        Name        = $Miner_Name
                        Path        = $Path
                        Port        = $MinerAPIPort
                        Type        = "AMD"
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                        Workers     = @(@{ Pool = $Pool })
                    }
                }
            }
        }
    }
}