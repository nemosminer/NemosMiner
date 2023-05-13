If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or $_.CUDAVersion -ge "11.6" })) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    # { $_ -ge "12.0" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.84/TeamBlackMiner_1_84_cuda_12.7z"; Break }
    { $_ -ge "11.6" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.94/TeamBlackMiner_1_94_cuda_12.7z"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; INTEL = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = @{ AMD = "Type_Vendor_Id"; INTEL = "Type_Vendor_Index"; NVIDIA = "Type_Vendor_Index" } # Device numeration seems to be mixed up with OpenCL

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("EtcHash");             Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + 1.21;                             ExcludePools = @(@(), @());         Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "KawPow");   Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + $MinerPools[1].KawPow.DAGSizeGiB; ExcludePools = @(@("HiveOn"), @()); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 45); Arguments = " --algo etc+rvn" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash"); Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + 1.21;                             ExcludePools = @(@("HiveOn"), @()); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 45); Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("Ethash");              Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.21;                              ExcludePools = @(@(), @());         Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");    Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + $MinerPools[1].KawPow.DAGSizeGiB;  ExcludePools = @(@("HiveOn"), @()); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 45); Arguments = " --algo eth+rvn" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");  Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.21;                              ExcludePools = @(@("HiveOn"), @()); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 45); Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");        Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 1.21;                        ExcludePools = @(@(), @());         Minerset = 2; Tuning = ""; WarmupTimes = @(45, 15); Arguments = " --algo ethash" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithms = @("VertHash");            Type = "AMD"; Fee = 0.01;  MinMemGiB = 3.0;                                                                  ExcludePools = @(@(), @());         Minerset = 1; Tuning = ""; WarmupTimes = @(60, 0);  Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }

    [PSCustomObject]@{ Algorithms = @("EtcHash");             Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + 1.21;                             ExcludePools = @(@(), @());         Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo etchash" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "KawPow");   Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + $MinerPools[1].KawPow.DAGSizeGiB; ExcludePools = @(@("HiveOn"), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo etc+rvn" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash"); Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + 1.21;                             ExcludePools = @(@("HiveOn"), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("Ethash");              Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.21;                              ExcludePools = @(@(), @());         Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo ethash" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");    Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + $MinerPools[1].KawPow.DAGSizeGiB;  ExcludePools = @(@("HiveOn"), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo eth+rvn " }
    [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");  Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.21;                              ExcludePools = @(@("HiveOn"), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");        Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 1.21;                        ExcludePools = @(@(), @());         Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo ethash" }
    [PSCustomObject]@{ Algorithms = @("KawPow");              Type = "INTEL"; Fee = 0.01;  MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 1.21;                              ExcludePools = @(@(), @());         Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(60, 45); Arguments = " --algo kawpow" }
    [PSCustomObject]@{ Algorithms = @("VertHash");            Type = "INTEL"; Fee = 0.01;  MinMemGiB = 3.0;                                                                  ExcludePools = @(@(), @());         MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(60, 60); Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }

    [PSCustomObject]@{ Algorithms = @("EtcHash");             Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 1.21;                             ExcludePools = @(@(), @());         Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "KawPow");   Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + $MinerPools[1].KawPow.DAGSizeGiB; ExcludePools = @(@("HiveOn"), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo etc+rvn" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash"); Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + 1.21;                             ExcludePools = @(@("HiveOn"), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("Ethash");              Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.21;                              ExcludePools = @(@(), @());         Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");    Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + $MinerPools[1].KawPow.DAGSizeGiB;  ExcludePools = @(@("HiveOn"), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo eth+rvn" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");  Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.21;                              ExcludePools = @(@("HiveOn"), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");        Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 1.21;                        ExcludePools = @(@(), @());         Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo ethash" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithms = @("KawPow");              Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 1.21;                              ExcludePools = @(@(), @());         Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(75, 45); Arguments = " --algo kawpow" }
    [PSCustomObject]@{ Algorithms = @("VertHash");            Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3.0;                                                                  ExcludePools = @(@(), @());         MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(60, 60); Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).BaseName -notin $_.ExcludePools[0] -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).BaseName -notin $_.ExcludePools[1]) }

# Dual algorithm mining: Both pools must use same protocol (SSL or non-SSL) :-(
$Algorithms = $Algorithms | Where-Object { -not $_.Algorithms[1] -or ($MinerPools[0].($_.Algorithms[0]).PoolPorts[0] -and $MinerPools[1].($_.Algorithms[1]).PoolPorts[0]) -or ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1] -and $MinerPools[1].($_.Algorithms[1]).PoolPorts[1])}

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "cl-devices", "cuda-devices", "tweak") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --hostname $($MinerPools[0].($_.Algorithms[0]).Host)"
                $Arguments += " --wallet $($MinerPools[0].($_.Algorithms[0]).User)"
                $Arguments += If ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1]) { " --ssl-port $($MinerPools[0].($_.Algorithms[0]).PoolPorts[1])" } Else { " --port $($MinerPools[0].($_.Algorithms[0]).PoolPorts[0])"}
                If ($MinerPools[0].($_.Algorithms[0]).Pass) { $Arguments += " --server-passwd $($MinerPools[0].($_.Algorithms[0]).Pass)$(If ($MinerPools[0].($_.Algorithms[0]).BaseName -eq "ProHashing" -and $_.Algorithms[0] -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].($_.Algorithms[0]).DAGSizeGiB))" })" }

                $SecondAlgo = Switch ($_.Algorithms[1]) { 
                    "KawPow"   { "rvn"; Break }
                    "VertHash" { "vtc"; Break }
                    Default    { "" }
                }
                If ($SecondAlgo) { 
                    $Arguments += " --$($SecondAlgo)-hostname $($MinerPools[1].($_.Algorithms[1]).Host) --$($SecondAlgo)-wallet $($MinerPools[1].($_.Algorithms[1]).User) "
                    $Arguments += If ($MinerPools[1].($_.Algorithms[1]).PoolPorts[1]) { " --$($SecondAlgo)-port $($MinerPools[1].($_.Algorithms[1]).PoolPorts[1])" } Else { " --$($SecondAlgo)-port $($MinerPools[1].($_.Algorithms[1]).PoolPorts[0])" }
                }
                $Arguments += If ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1]) { " --ssl --ssl-verify-none"}

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                If ($_.Algorithms[0] -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                    $PrerequisitePath = $Variables.VerthashDatPath
                    $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                }
                Else { 
                    $PrerequisitePath = ""
                    $PrerequisiteURI = ""
                }

                [PSCustomObject]@{ 
                    Algorithms       = @($_.Algorithms | Select-Object)
                    API              = "TeamBlackMiner"
                    Arguments        = ("$($Arguments) --api --api-version 1.4 --api-port $MinerAPIPort$($DeviceSelector.($AvailableMiner_Devices.Type | Select-Object -Unique)) [$(($AvailableMiner_Devices.($DeviceEnumerator.($AvailableMiner_Devices.Type | Select-Object -Unique)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')]" -replace "\s+", " ").trim()
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Fee              = $_.Fee
                    MinerSet         = $_.MinerSet
                    MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/threads"
                    Name             = $Miner_Name
                    Path             = $Path
                    Port             = $MinerAPIPort
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                    Type             = $_.Type
                    URI              = $Uri
                    WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}