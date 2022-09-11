using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Vendor -ne "CPU" -and ($_.Type -eq "AMD" -or $_.CUDAVersion -ge "10.2") })) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/Kudaraidee/kudaraidee-v1.2.0a-win64.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\Multiminer.exe"
$DeviceEnumerator = @{ AMD = "Type_Index"; NVIDIA = "Type_Vendor_Index" }

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = @("Argon2d250");   Type = "AMD"; MinMemGB = 2; Blocksize = 250;   MinerSet = 1; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d250 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = @("Argon2d8192");  Type = "AMD"; MinMemGB = 2; Blocksize = 8192;  MinerSet = 0; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d8192 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = @("Argon2d500");   Type = "AMD"; MinMemGB = 2; Blocksize = 500;   MinerSet = 0; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d500 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = @("Argon2d4096");  Type = "AMD"; MinMemGB = 2; Blocksize = 4096;  MinerSet = 0; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d4096 --use-gpu OpenCL" }
    [PSCustomObject]@{ Algorithm = @("Argon2d16000"); Type = "AMD"; MinMemGB = 2; Blocksize = 16000; MinerSet = 0; WarmupTimes = @(60, 45); ExcludePool = @(); Arguments = " --algo argon2d16000 --use-gpu OpenCL" }

    [PSCustomObject]@{ Algorithm = @("Argon2d250");   Type = "NVIDIA"; MinMemGB = 2; Blocksize = 250;   MinerSet = 0; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d250 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = @("Argon2d8192");  Type = "NVIDIA"; MinMemGB = 2; Blocksize = 8192;  MinerSet = 0; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d8192 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = @("Argon2d500");   Type = "NVIDIA"; MinMemGB = 2; Blocksize = 500;   MinerSet = 0; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d500 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = @("Argon2d4096");  Type = "NVIDIA"; MinMemGB = 2; Blocksize = 4096;  MinerSet = 0; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d4096 --use-gpu CUDA" }
    [PSCustomObject]@{ Algorithm = @("Argon2d16000"); Type = "NVIDIA"; MinMemGB = 2; Blocksize = 16000; MinerSet = 0; WarmupTimes = @(60, 60); ExcludePool = @(); Arguments = " --algo argon2d16000 --use-gpu CUDA" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).Host } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } | Where-Object Type -eq $_.Type | ForEach-Object { 

            $Blocksize = $_.Blocksize / 0.866

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $BatchSize = [Math]::Floor(($AvailableMiner_Devices | ForEach-Object { $_.MemoryGB / $Blocksize } | Measure-Object -Minimum).Minimum * 1000000)
                $Threads = 1

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url stratum+tcp://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) --user $($MinerPools[0].($_.Algorithm).User) --pass $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --gpu-batchsize $BatchSize --threads $Threads --retry-pause 1 --api-bind 127.0.0.1:$($MinerAPIPort) --gpu-id $(($AvailableMiner_Devices.($DeviceEnumerator.($AvailableMiner_Devices.Type)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f ($_ + 1)}) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    API         = "Ccminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
