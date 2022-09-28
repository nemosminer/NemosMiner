using module ..\Includes\Include.psm1  

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "NVIDIA" -and [Double]$_.OpenCL.ComputeCapability -ge 5.0 })) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.4" } { "https://github.com/CryptoDredge/miner/releases/download/v0.27.0/CryptoDredge_0.27.0_cuda_11.4_windows.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\CryptoDredge.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Argon2d250";        Fee = 0.01; MinMemGB = 2;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo argon2d250 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Argon2d4096";       Fee = 0.01; MinMemGB = 2;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algo argon2d4096 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Argon2dDyn";        Fee = 0.01; MinMemGB = 2;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(60, 0);  Arguments = " --algo argon2d-dyn --intensity 6" }
    [PSCustomObject]@{ Algorithm = "Argon2dNim";        Fee = 0.01; MinMemGB = 2;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo argon2d-nim --intensity 6" }
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";      Fee = 0.01; MinMemGB = 1;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo chukwa --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Argon2ChukwaV2";    Fee = 0.01; MinMemGB = 1;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo chukwa2 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightXeq";    Fee = 0.01; MinMemGB = 1;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo cngpu --intensity 8" } # CryptonightGPU (XEQ Zergpool)
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";    Fee = 0.01; MinMemGB = 1;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo cnconceal --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";  Fee = 0.01; MinMemGB = 1;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo cnheavy --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle"; Fee = 0.01; MinMemGB = 1;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo cnturtle --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";    Fee = 0.01; MinMemGB = 2;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo cnupx2 --intensity 8" }
    [PSCustomObject]@{ Algorithm = "CryptonightXhv";    Fee = 0.01; MinMemGB = 1;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(75, 15); Arguments = " --algo cnhaven --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Ethash";            Fee = 0.01; MinMemGB = ($Pools."Ethash".DAGSize + 0.95GB) / 1GB; ExcludePool = @("MiningPoolHub", "NiceHash"); MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo ethash" }
    [PSCustomObject]@{ Algorithm = "FiroPoW";           Fee = 0.01; MinMemGB = 5;                                        ExcludePool = @();                            MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo firopow" }
    [PSCustomObject]@{ Algorithm = "KawPoW";            Fee = 0.01; MinMemGB = ($Pools."KawPoW".DAGSize + 0.95GB) / 1GB; ExcludePool = @();                            MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo kawpow --intensity 8" } # TTMiner-v5.0.3 is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | Where-Object { $Pools.($_.Algorithm).BaseName -notin $_.ExcludePool } | ForEach-Object { 

            $MinComputeCapability = $_.MinComputeCapability

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB | Where-Object { [Double]$_.OpenCL.ComputeCapability -ge $MinComputeCapability }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "intensity") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --url stratum+$(If ($Pools.($_.Algorithm).SSL) { "ssl" } Else { "tcp" } )://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --cpu-priority $($Config.GPUMinerProcessPriority + 2) --no-watchdog --no-crashreport --retries 1 --retry-pause 1 --api-type ccminer-tcp --api-bind=127.0.0.1:$($MinerAPIPort) --device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
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
