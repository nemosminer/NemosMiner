using module ..\Includes\Include.psm1

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
    [PSCustomObject]@{ Algorithm = "Allium";    Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @("Other"); Arguments = " --algo allium --intensity 8" } # CryptoDredge v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo exosis --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Dedal";     Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo dedal --intensity 8" }
    [PSCustomObject]@{ Algorithm = "HMQ1725";   Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(60, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo hmq1725 --intensity 8" } # CryptoDredge v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo neoscrypt --intensity 6" } # CryptoDredge v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Phi";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo phi --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Phi2";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo phi2 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Pipe";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); ExcludeGPUArchitecture = @();        Arguments = " --algo pipe --intensity 8" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }) { 

                $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "intensity") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --url stratum+$(If ($Pools.($_.Algorithm).SSL) { "ssl" } Else { "tcp" } )://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User)"
                If ($Pools.($_.Algorithm).WorkerName) { $_.Arguments += ".$($Pools.($_.Algorithm).WorkerName)" }
                $_.Arguments += " --pass $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --cpu-priority $($Config.GPUMinerProcessPriority + 2) --no-watchdog --no-crashreport --retries 1 --retry-pause 1 --api-type ccminer-tcp --api-bind=127.0.0.1:$($MinerAPIPort) --device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = $_.Algorithm
                    API         = "Ccminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee # Dev fee
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
