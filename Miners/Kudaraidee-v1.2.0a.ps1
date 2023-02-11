If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Vendor -ne "CPU" -or $_.CUDAVersion -ge "10.2" })) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/Kudaraidee/kudaraidee-v1.2.0a-win64.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\Multiminer.exe"
$DeviceEnumerator = @{ AMD = "Type_Index"; NVIDIA = "Type_Vendor_Index" }

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Argon2d250";   Type = "AMD"; MinMemGiB = 2; Blocksize = 250;   Minerset = 2; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d250 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = "Argon2d8192";  Type = "AMD"; MinMemGiB = 2; Blocksize = 8192;  Minerset = 2; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d8192 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";   Type = "AMD"; MinMemGiB = 2; Blocksize = 500;   Minerset = 2; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d500 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = "Argon2d4096";  Type = "AMD"; MinMemGiB = 2; Blocksize = 4096;  Minerset = 2; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d4096 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = "Argon2d16000"; Type = "AMD"; MinMemGiB = 2; Blocksize = 16000; Minerset = 1; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d16000 --use-gpu OpenCL" }

    [PSCustomObject]@{ Algorithm = "Argon2d250";   Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 250;   Minerset = 2; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d250 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = "Argon2d8192";  Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 8192;  Minerset = 2; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d8192 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = "Argon2d500";   Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 500;   Minerset = 2; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d500 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = "Argon2d4096";  Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 4096;  Minerset = 2; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d4096 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = "Argon2d16000"; Type = "NVIDIA"; MinMemGiB = 2; Blocksize = 16000; MinerSet = 0; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d16000 --use-gpu CUDA" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] } | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -eq $_.Type | ForEach-Object { 

            $Blocksize = $_.Blocksize / 0.866

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $BatchSize = [Math]::Floor(($AvailableMiner_Devices | ForEach-Object { $_.MemoryGiB / $Blocksize } | Measure-Object -Minimum).Minimum * 1000000)
                $Threads = 1

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "Ccminer"
                    Arguments   = ("$($Arguments) --url stratum+tcp://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) --user $($MinerPools[0].($_.Algorithm).User) --pass $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --gpu-batchsize $BatchSize --threads $Threads --retry-pause 1 --api-bind 127.0.0.1:$($MinerAPIPort) --gpu-id $(($AvailableMiner_Devices.($DeviceEnumerator.($AvailableMiner_Devices.Type | Select-Object -Unique)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f ($_ + 1)}) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    MinerSet     = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
