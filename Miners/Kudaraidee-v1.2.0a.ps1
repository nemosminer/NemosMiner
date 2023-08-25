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

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Vendor -ne "CPU" -or $_.CUDAVersion -ge "10.2" })) { Return }

$URI = "https://github.com/Minerx117/miners/releases/download/Kudaraidee/kudaraidee-v1.2.0a-win64.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\Multiminer.exe"
$DeviceEnumerator = @{ AMD = "Type_Index"; NVIDIA = "Type_Vendor_Index" }

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Argon2d250";   Type = "AMD"; MinMemGiB = 2; Blocksize = 250;   Minerset = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d250 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = "Argon2d8192";  Type = "AMD"; MinMemGiB = 2; Blocksize = 8192;  Minerset = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d8192 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";   Type = "AMD"; MinMemGiB = 2; Blocksize = 500;   Minerset = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d500 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = "Argon2d4096";  Type = "AMD"; MinMemGiB = 2; Blocksize = 4096;  Minerset = 2; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d4096 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = "Argon2d16000"; Type = "AMD"; MinMemGiB = 2; Blocksize = 16000; Minerset = 1; WarmupTimes = @(60, 45); ExcludePools = @(); Arguments = " --algo argon2d16000 --use-gpu OpenCL" }

    [PSCustomObject]@{ Algorithm = "Argon2d250";   Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 250;   Minerset = 2; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d250 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = "Argon2d8192";  Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 8192;  Minerset = 2; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d8192 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";   Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 500;   Minerset = 2; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d500 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = "Argon2d4096";  Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 4096;  Minerset = 2; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d4096 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = "Argon2d16000"; Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 16000; MinerSet = 0; WarmupTimes = @(60, 60); ExcludePools = @(); Arguments = " --algo argon2d16000 --use-gpu CUDA" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePools }

If ($Algorithms) { 
 
    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -eq $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

                $BlockSize = $_.BlockSize
                # 1 GB memory reserve, then 1 thread per 4GB
                $Threads = [Math]::Ceiling(($AvailableMiner_Devices | ForEach-Object { ($_.MemoryGiB - 1) / 4 } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum))

                # Reserve 250KB for AMD driver, for NVIDIA
                $GPUmemory = ($AvailableMiner_Devices | ForEach-Object { $_.MemoryGiB } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)
                If ($_.Type -eq "AMD") { $GPUmemory -= 0.25 } Else {$GPUmemory = $GPUmemory * 0.95 - 0.4 }
                $BatchSize = [Math]::Floor(($GPUmemory * 0.5MB / $Blocksize / $Threads) * 2)

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "CcMiner"
                    Arguments   = ("$($_.Arguments) --url stratum+tcp://$($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts[0]) --user $($AllMinerPools.($_.Algorithm).User) --pass $($AllMinerPools.($_.Algorithm).Pass)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" }) --gpu-batchsize $BatchSize --threads $Threads --retry-pause 1 --api-bind 127.0.0.1:$($MinerAPIPort) --gpu-id $(($AvailableMiner_Devices.($DeviceEnumerator.($AvailableMiner_Devices.Type | Select-Object -Unique)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f ($_ + 1)}) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    MinerSet     = $_.MinerSet
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