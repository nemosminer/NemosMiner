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
Version:        5.0.1.9
Version date:   2023/11/04
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -ge "5.0" })) { Return } # Cuda error in func 'argon2d_hash_cuda' at line 89 : an illegal instruction was encountered on GTX 750

$URI = "https://github.com/nemosminer/Dynamic-GPU-Miner-Nvidia/releases/download/v1.0.2/ccminerdyn.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$($Name)\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Argon2d500"; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(90, 15); ExcludePools = @(); Arguments = " --algo argon2d" }
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

                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    [PSCustomObject]@{ 
                        API         = "CcMiner"
                        Arguments   = "$($_.Arguments) --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" }) --statsavg 1 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
                        DeviceNames = $AvailableMiner_Devices.Name
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
    }
}