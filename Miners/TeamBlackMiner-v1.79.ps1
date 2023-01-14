If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or ($_.Type -eq "NVIDIA" -and $_.CUDAVersion -ge "11.6") })) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "12.0" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.79/TeamBlackMiner_1_79_cuda_12.7z"; Break }
    Default { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.79/TeamBlackMiner_1_79_cuda_11_6.7z" }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; INTEL = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = @{ AMD = "Type_Vendor_Id"; INTEL = "Type_Vendor_Index"; NVIDIA = "Type_Vendor_Index" } # Device numeration seems to be mixed up with OpenCL

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB+ 0.41;       ExcludePool = @(); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 0); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB+ 0.41;        ExcludePool = @(); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 0); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; Fee = 0.005; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.41; ExcludePool = @(); Minerset = 2; Tuning = ""; WarmupTimes = @(45, 0); Arguments = " --algo ethash" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "VertHash";     Type = "AMD"; Fee = 0.01;  MinMemGiB = 2.0;                                           ExcludePool = @(); Minerset = 1; Tuning = ""; WarmupTimes = @(60, 0); Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }

    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 0.41;      ExcludePool = @(); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 0); Arguments = " --algo etchash" }
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.41;       ExcludePool = @(); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 0); Arguments = " --algo ethash" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "INTEL"; Fee = 0.005; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.41; ExcludePool = @(); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 0); Arguments = " --algo ethash" }
    [PSCustomObject]@{ Algorithm = "KawPow";       Type = "INTEL"; Fee = 0.01;  MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.41;       ExcludePool = @(); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(60, 0); Arguments = " --algo kawpow" }
    [PSCustomObject]@{ Algorithm = "VertHash";     Type = "INTEL"; Fee = 0.01;  MinMemGiB = 2.0;                                           ExcludePool = @(); MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(60, 0); Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }

    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 0.41;      ExcludePool = @(); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 0); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.41;       ExcludePool = @(); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 0); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.005; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.41; ExcludePool = @(); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 0); Arguments = " --algo ethash" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPow";       Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.41;       ExcludePool = @(); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(60, 0); Arguments = " --algo kawpow" }
    [PSCustomObject]@{ Algorithm = "VertHash";     Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 2.0;                                           ExcludePool = @(); MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(60, 0); Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Where-Object Type -in @($Algorithms.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "cl-devices", "cuda-devices", "tweak") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --hostname $($MinerPools[0].($_.Algorithm).Host) --wallet $($MinerPools[0].($_.Algorithm).User)"
                $Arguments += If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { " --ssl --ssl-verify-none --ssl-port $($MinerPools[0].($_.Algorithm).PoolPorts[1])" } Else { " --port $($MinerPools[0].($_.Algorithm).PoolPorts[0])"}
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " --worker-name $($MinerPools[0].($_.Algorithm).WorkerName)" }
                If ($MinerPools[0].($_.Algorithm).Pass) { $Arguments += " --server-passwd $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].($_.Algorithm).DAGSizeGiB))" })" }
                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $Arguments += $_.Tuning }

                If ($_.Algorithm -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath).length -ne 1283457024) { 
                    $PrerequisitePath = $Variables.VerthashDatPath
                    $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                }
                Else { 
                    $PrerequisitePath = ""
                    $PrerequisiteURI = ""
                }

                [PSCustomObject]@{ 
                    Algorithms       = @($_.Algorithm)
                    API              = "TeamBlackMiner"
                    Arguments        = ("$($Arguments) --no-ansi --api --api-port $MinerAPIPort$($DeviceSelector.($AvailableMiner_Devices.Type | Select-Object -Unique)) [$(($AvailableMiner_Devices.($DeviceEnumerator.($AvailableMiner_Devices.Type | Select-Object -Unique)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')]" -replace "\s+", " ").trim()
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Fee              = $_.Fee
                    MinerSet         = $_.MinerSet
                    MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/threads"
                    Name             = $Miner_Name
                    Path             = $Path
                    Port             = $MinerAPIPort
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                    Type             = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                    URI              = $Uri
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
