using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "10.0" } { "https://github.com/NebuTech/NBMiner/releases/download/v40.1/NBMiner_40.1_Win.zip"; Break }
    Default { Return }
}
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v40.1/NBMiner_40.1_Win.zip"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nbminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "AMD"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 3.0; MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo ergo --platform 2" }
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "AMD"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 4.0; MinerSet = 1; WarmupTimes = @(45, 35); Arguments = " --algo etchash --platform 2 -enable-dag-cache" } # PhoenixMiner-v6.0c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; Fee = 0.01; MinMemGB = 5.0; MinMemGBWin10 = 6.0; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " --algo ethash --platform 2 --enable-dag-cache" } # PhoenixMiner-v6.0c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 2.0; MinerSet = 1; WarmupTimes = @(60, 35); Arguments = " --algo ethash --platform 2 --enable-dag-cache" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "AMD"; Fee = 0.02; MinMemGB = 3.0; MinMemGBWin10 = 3.0; MinerSet = 1; WarmupTimes = @(45, 15); Arguments = " --algo kawpow --platform 2" } # XmRig-v6.16.3 is almost as fast but has no fee
 
    [PSCustomObject]@{ Algorithm = "BeamV3";       Type = "NVIDIA"; Fee = 0.02; MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -mt 1 --algo beamv3 --platform 1" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";     Type = "NVIDIA"; Fee = 0.02; MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(30, 0);  Arguments = " -mt 1 --algo cuckoo_ae --platform 1" } # GMiner-v2.86 is fastest
    [PSCustomObject]@{ Algorithm = "Ergo";         Type = "NVIDIA"; Fee = 0.02; MinMemGB = 5.0; MinMemGBWin10 = 5.0;  MinComputeCapability = 6.0; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " -mt 1 --algo ergo --platform 1" }
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " -mt 1 --algo etchash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.0c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01; MinMemGB = 5.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " -mt 1 --algo ethash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.0c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01; MinMemGB = 3.0; MinMemGBWin10 = 2.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(60, 15); Arguments = " -mt 1 --algo ethash --platform 1 --enable-dag-cache" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; Fee = 0.02; MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " -mt 1 --algo kawpow --platform 1" } # XmRig-v6.16.3 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.03; MinMemGB = 6.0; MinMemGBWin10 = 5.0;  MinComputeCapability = 6.1; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " -mt 1 --algo octopus --platform 1" } # Trex-v0.25.8 is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 
            If ($Pools.($_.Algorithm).DAGsize -gt 0 -and (($Miner_Devices.Model | Sort-Object -Unique) -join '' -match '^Radeon RX (5300|5500|5600|5700).*\d.*GB$')) { Return } # Ethash on Navi is slow

            $MinComputeCapability = $_.MinComputeCapability

            # Windows 10 requires more memory on some algos
            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $_.MinMemGBWin10 } Else { $_.MinMemGB } }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB } | Where-Object { [Double]$_.OpenCL.ComputeCapability -ge $MinComputeCapability }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($_.Algorithm -match "^EtcHash$|^Ethash.*|^Cuck.*") { 
                    If ($Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { 
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
                $_.Arguments += " --password $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" })"

                # Optionally disable dev fee mining
                If ($Config.DisableMinerFee) { 
                    $_.Fee = 0
                    $_.Arguments += " --fee 0"
                }

                If ($Pools.($_.Algorithm).BaseName -eq "MiningPoolHub") { $_.WarmupTimes[0] += 15; $_.WarmupTimes[1] += 15 } # Seconds longer for MPH because of long connect issue

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $_.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --no-watchdog --api 127.0.0.1:$($MinerAPIPort) --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
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
