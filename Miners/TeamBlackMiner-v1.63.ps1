using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or ($_.Type -eq "NVIDIA" -and $_.OpenCl.ComputeCapability -ge "5.0") })) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    # { $_ -ge "11.6" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.58/TeamBlackMiner_1_58_cuda_11_6.7z"; Break }
    { $_ -ge "11.5" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.63/TeamBlackMiner_1_63_cuda_11_5.7z"; Break }
    { $_ -ge "11.4" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.63/TeamBlackMiner_1_63_cuda_11_4.7z"; Break }
    { $_ -ge "11.3" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.63/TeamBlackMiner_1_63_cuda_11_3.7z"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = @{ AMD = "Type_Vendor_Id"; NVIDIA = "Type_Vendor_Index" } # Device numeration seems to be mixed up with OpenCL

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "AMD"; Fee = 0.005; MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.41; MinerSet = 0; Tuning = ""; WarmupTimes = @(45, 30); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; Fee = 0.005; MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.41; MinerSet = 0; Tuning = ""; WarmupTimes = @(45, 30); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; Fee = 0.005; MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; MinerSet = 1; Tuning = ""; WarmupTimes = @(45, 30); Arguments = " --algo ethash"} # TTMiner-v5.0.3 is fastest
    # [PSCustomObject]@{ Algorithm = "VertHash";     Type = "AMD"; Fee = 0.01;  MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 180); Arguments = " --algo vertcoin" }

    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.005; MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.41; MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.005; MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.41; MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.005; MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); Arguments = " --algo ethash" } # TTMiner-v5.0.3 is fastest
    # [PSCustomObject]@{ Algorithm = "VertHash";     Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 180); Arguments = " --algo vertcoin" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($Algorithms.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "cl-devices", "cuda-devices", "tweak") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --hostname $($Pools.($_.Algorithm).Host) --port $($Pools.($_.Algorithm).Port) --wallet $($Pools.($_.Algorithm).User -split '\.' | Select-Object -First 1) --worker-name $($Config.Workername)"
                $_.Arguments += " --server-passwd $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"

                If ($Pools.($_.Algorithm).SSL) { $_.Arguments += " --ssl" }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --api --api-port $MinerAPIPort$($DeviceSelector.($_.Type)) [$(($AvailableMiner_Devices.($DeviceEnumerator.($_.Type)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')]" -replace "\s+", " ").trim()
                    Algorithms  = $_.Algorithm
                    API         = "TeamBlackMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)/threads"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
