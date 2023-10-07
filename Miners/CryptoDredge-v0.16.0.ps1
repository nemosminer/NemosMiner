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
Version:        5.0.1.1
Version date:   2023/10/07
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "10.0" } { "https://github.com/Minerx117/miners/releases/download/CryptoDredge/CryptoDredge_0.16.0_cuda_10.0_windows.zip"; Break }
    { $_ -ge "9.2" } { "https://github.com/Minerx117/miners/releases/download/CryptoDredge/CryptoDredge_0.16.0_cuda_9.2_windows.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\CryptoDredge.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Allium";    Fee = @(0.01); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(); Arguments = " --algo allium --intensity 8" } # FPGA
    [PSCustomObject]@{ Algorithm = "Exosis";    Fee = @(0.01); MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        ExcludePools = @(); Arguments = " --algo exosis --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Dedal";     Fee = @(0.01); MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        ExcludePools = @(); Arguments = " --algo dedal --intensity 8" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";   Fee = @(0.01); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 0); ExcludeGPUArchitecture = @();        ExcludePools = @(); Arguments = " --algo hmq1725 --intensity 8" } # CryptoDredge v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; Fee = @(0.01); MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();        ExcludePools = @(); Arguments = " --algo neoscrypt --intensity 6" } # FPGA
#   [PSCustomObject]@{ Algorithm = "Phi";       Fee = @(0.01); MinMemGiB = 2; Minerset = 2; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();        ExcludePools = @(); Arguments = " --algo phi --intensity 8" } # ASIC
    [PSCustomObject]@{ Algorithm = "Phi2";      Fee = @(0.01); MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        ExcludePools = @(); Arguments = " --algo phi2 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Pipe";      Fee = @(0.01); MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        ExcludePools = @(); Arguments = " --algo pipe --intensity 8" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].PoolPorts[0] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object { $_.PoolPorts[0] } | Where-Object BaseName -notin $ExcludePools)) { 

                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    $Arguments = $_.Arguments
                    $Arguments += " --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User)"
                    If ($Pool.WorkerName) { $Arguments += ".$($Pool.WorkerName)" }
                    $Arguments += " --pass $($Pool.Pass)"

                    [PSCustomObject]@{ 
                        API         = "CcMiner"
                        Arguments   = "$Arguments --cpu-priority $($Config.GPUMinerProcessPriority + 2) --no-watchdog --no-crashreport --retries 1 --retry-pause 1 --api-type ccminer-tcp --api-bind=127.0.0.1:$($MinerAPIPort) --device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
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
    }
}