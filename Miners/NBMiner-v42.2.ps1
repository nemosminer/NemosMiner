using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "10.0" } { "https://github.com/NebuTech/NBMiner/releases/download/v42.2/NBMiner_42.2_Win.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nbminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "AMD"; Fee = 0.01; MinMemGB = $Pools."Autolykos2".DAGSizeGB;   MemReserveGB = 0;    AdditionalWin10MemGB = 0; MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo ergo --platform 2" }
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "AMD"; Fee = 0.01; MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.41; AdditionalWin10MemGB = 0; MinerSet = 1; WarmupTimes = @(45, 35); Arguments = " --algo etchash --platform 2 -enable-dag-cache" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; Fee = 0.01; MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.41; AdditionalWin10MemGB = 0; MinerSet = 1; WarmupTimes = @(60, 45); Arguments = " --algo ethash --platform 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; Fee = 0.01; MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; AdditionalWin10MemGB = 0; MinerSet = 1; WarmupTimes = @(60, 35); Arguments = " --algo ethash --platform 2 --enable-dag-cache" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "AMD"; Fee = 0.02; MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.41; AdditionalWin10MemGB = 0; MinerSet = 1; WarmupTimes = @(45, 15); Arguments = " --algo kawpow --platform 2" } # XmRig-v6.17.0 is almost as fast but has no fee
 
    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "NVIDIA"; Fee = 0.02; MinMemGB = $Pools."Autolykos2".DAGSizeGB;   MemReserveGB = 0;    AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -mt 1 --algo ergo --platform 1" }
    [PSCustomObject]@{ Algorithm = "BeamV3";       Type = "NVIDIA"; Fee = 0.02; MinMemGB = 3;                               MemReserveGB = 0;    AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -mt 1 --algo beamv3 --platform 1" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";     Type = "NVIDIA"; Fee = 0.02; MinMemGB = 5;                               MemReserveGB = 0;    AdditionalWin10MemGB = 1; MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(30, 0);  Arguments = " -mt 1 --algo cuckoo_ae --platform 1" } # GMiner-v3.01 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.41; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " -mt 1 --algo etchash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01; MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.41; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(60, 0);  Arguments = " -mt 1 --algo ethash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01; MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(60, 15); Arguments = " -mt 1 --algo ethash --platform 1 --enable-dag-cache" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; Fee = 0.02; MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.41; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " -mt 1 --algo kawpow --platform 1" } # XmRig-v6.17.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.03; MinMemGB = 6;                               MemReserveGB = 0.41; AdditionalWin10MemGB = 1; MinComputeCapability = 6.1; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " -mt 1 --algo octopus --platform 1" } # Trex-v0.26.4 is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinComputeCapability = $_.MinComputeCapability

            $MinMemGB = $_.MinMemGB + $_.MemReserveGB

            # Windows 10 requires more memory on some algos
            If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGB += $_.AdditionalWin10MemGB }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $MinMemGB | Where-Object { [Double]$_.OpenCL.ComputeCapability -ge $MinComputeCapability }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($_.Algorithm -match "^EtcHash$|^Ethash.*|^Cuck.*") { 
                    If ($Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash")) { 
                        $Protocol = "nicehash+tcp://"
                    }
                    Else { 
                        $Protocol = "ethproxy+tcp://"
                    }
                }
                Else { 
                    $Protocol = "stratum+tcp://"
                }
                If ($Pools.($_.Algorithm).SSL) { $Protocol = $Protocol -replace '\+tcp\://$', '+ssl://' }

                $_.Arguments += " --url $($Protocol)$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User)"
                $_.Arguments += " --password $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"

                # Optionally disable dev fee mining
                If ($Config.DisableMinerFee) { 
                    $_.Fee = 0
                    $_.Arguments += " --fee 0"
                }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --no-watchdog --api 127.0.0.1:$($MinerAPIPort) --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = $_.Algorithm
                    API         = "NBMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
