If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "10.0" } { "https://github.com/Minerx117/miners/releases/download/CryptoDredge/CryptoDredge_0.16.0_cuda_10.0_windows.zip"; Break }
    { $_ -ge "9.2" } { "https://github.com/Minerx117/miners/releases/download/CryptoDredge/CryptoDredge_0.16.0_cuda_9.2_windows.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\CryptoDredge.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Allium";    Fee = 0.01; MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @("Other"); Arguments = " --algo allium --intensity 8" } # FPGA
    [PSCustomObject]@{ Algorithm = "Exosis";    Fee = 0.01; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo exosis --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Dedal";     Fee = 0.01; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo dedal --intensity 8" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";   Fee = 0.01; MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(60, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo hmq1725 --intensity 8" } # CryptoDredge v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; Fee = 0.01; MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo neoscrypt --intensity 6" } # FPGA
#   [PSCustomObject]@{ Algorithm = "Phi";       Fee = 0.01; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo phi --intensity 8" } # ASIC
    [PSCustomObject]@{ Algorithm = "Phi2";      Fee = 0.01; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo phi2 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Pipe";      Fee = 0.01; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo pipe --intensity 8" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "intensity") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --url stratum+tcp://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) --user $($MinerPools[0].($_.Algorithm).User)"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += ".$($MinerPools[0].($_.Algorithm).WorkerName)" }
                $Arguments += " --pass $($MinerPools[0].($_.Algorithm).Pass)"

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "Ccminer"
                    Arguments   = ("$($Arguments) --cpu-priority $($Config.GPUMinerProcessPriority + 2) --no-watchdog --no-crashreport --retries 1 --retry-pause 1 --api-type ccminer-tcp --api-bind=127.0.0.1:$($MinerAPIPort) --device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee # Dev fee
                    MinerSet    = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "NVIDIA"
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}