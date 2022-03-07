using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = Switch ($DriverVersion.CUDA) { 
    { $_ -ge "10.0" } { "https://github.com/Minerx117/miners/releases/download/CryptoDredge/CryptoDredge_0.16.0_cuda_10.0_windows.zip"; Break }
    Default { Return }
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\CryptoDredge.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Allium";    Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(45, 0); Arguments = " --algo allium --intensity 8" } # CryptoDredge v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo exosis --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Dedal";     Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo dedal --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Hmq1725";   Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(60, 0); Arguments = " --algo hmq1725 --intensity 8" } # CryptoDredge v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(30, 0); Arguments = " --algo neoscrypt --intensity 6" } # CryptoDredge v0.26.0 is fastest
    [PSCustomObject]@{ Algorithm = "Phi";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(45, 0); Arguments = " --algo phi --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Phi2";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo phi2 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Pipe";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo pipe --intensity 8" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | ForEach-Object { 

#             If ($_.Algorithm -eq "Phi2" -and $Pools.($_.Algorithm).Name -like "ZergPool*") { Return }

            $MinMemGB = $_.MinMemGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 
                $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "intensity") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = "NVIDIA"
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --no-watchdog --no-crashreport --timeout 180 --cpu-priority $($Config.GPUMinerProcessPriority + 2) --retries 1 --retry-pause 1 --api-type ccminer-tcp --api-bind=127.0.0.1:$($MinerAPIPort) --device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
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
