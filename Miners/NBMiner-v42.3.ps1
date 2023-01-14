If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or ($_.Type -eq "NVIDIA" -and $_.CUDAVersion -ge "10.0") } )) { Return }

$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v42.3/NBMiner_42.3_Win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nbminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "AMD"; Fee = 0.01; MinMemGiB = $MinerPools[0].Autolykos2.DAGSizeGiB + 0.42;   AdditionalWin10MemGB = 0; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo ergo --platform 2" }
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "AMD"; Fee = 0.01; MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 0.41;      AdditionalWin10MemGB = 0; Minerset = 1; WarmupTimes = @(45, 30); Arguments = " --algo etchash --platform 2 -enable-dag-cache" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; Fee = 0.01; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.41;       AdditionalWin10MemGB = 0; Minerset = 2; WarmupTimes = @(45, 30); Arguments = " --algo ethash --platform 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; Fee = 0.01; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.41; AdditionalWin10MemGB = 0; Minerset = 2; WarmupTimes = @(45, 35); Arguments = " --algo ethash --platform 2 --enable-dag-cache" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPow";       Type = "AMD"; Fee = 0.02; MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.41;       AdditionalWin10MemGB = 0; Minerset = 2; WarmupTimes = @(45, 15); Arguments = " --algo kawpow --platform 2" } # XmRig-v6.17.0 is almost as fast but has no fee
 
    [PSCustomObject]@{ Algorithm = "BeamV3";       Type = "NVIDIA"; Fee = 0.02; MinMemGiB = 3;                                             AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 0; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  Arguments = " --algo beamv3 --platform 1" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";     Type = "NVIDIA"; Fee = 0.02; MinMemGiB = 5;                                             AdditionalWin10MemGB = 1; MinComputeCapability = 6.0; Minerset = 1; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  Arguments = " --algo cuckoo_ae --platform 1" } # GMiner-v3.22 is fastest
    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "NVIDIA"; Fee = 0.02; MinMemGiB = $MinerPools[0].Autolykos2.DAGSizeGiB + 0.42;   AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; Minerset = 1; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  Arguments = " --algo ergo --platform 1" }
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGiB = $MinerPools[0].Etchash.DAGSizeGiB + 0.41;      AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; Minerset = 2; Tuning = " -mt 1"; WarmupTimes = @(45, 0);  Arguments = " --algo etchash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01; MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.41;       AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; Minerset = 2; Tuning = " -mt 1"; WarmupTimes = @(60, 0);  Arguments = " --algo ethash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.41; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; Minerset = 2; Tuning = " -mt 1"; WarmupTimes = @(60, 15); Arguments = " --algo ethash --platform 1 --enable-dag-cache" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPow";       Type = "NVIDIA"; Fee = 0.02; MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.41;       AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; Minerset = 2; Tuning = " -mt 1"; WarmupTimes = @(45, 0);  Arguments = " --algo kawpow --platform 1" } # XmRig-v6.17.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.03; MinMemGiB = $MinerPools[0].Octopus.DAGSizeGiB + 0.41;      AdditionalWin10MemGB = 1; MinComputeCapability = 6.1; Minerset = 2; Tuning = " -mt 1"; WarmupTimes = @(45, 0);  Arguments = " --algo octopus --platform 1" } # Trex-v0.26.8 is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $MinComputeCapability = $_.MinComputeCapability
            $MinMemGiB = $_.MinMemGiB

            # Windows 10 requires more memory on some algos
            If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGiB += $_.AdditionalWin10MemGB }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $MinMemGiB | Where-Object { [Double]$_.OpenCL.ComputeCapability -ge $MinComputeCapability }) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($_.Algorithm -match "^Cuck.*|^EtcHash$|^Ethash.*|^KawPow$") { 
                    If ($MinerPools[0].($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash")) { 
                        $Arguments += " --url nicehash"
                    }
                    Else { 
                        $Arguments += " --url ethproxy"
                    }
                }
                Else { 
                    $Arguments += " --url stratum"
                }
                $Arguments += If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "+ssl://" } Else  { "+tcp://" }
                $Arguments += "$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" })"
                $Arguments += " --password $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].($_.Algorithm).DAGSizeGiB))" })"

                # Optionally disable dev fee mining
                If ($Config.DisableMinerFee) { 
                    $_.Fee = 0
                    $Arguments += " --fee 0"
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "NBMiner"
                    Arguments   = ("$($Arguments) --no-watchdog --api 127.0.0.1:$($MinerAPIPort) --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
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
