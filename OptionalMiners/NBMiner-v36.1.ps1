using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v36.1/NBMiner_36.1_Win.zip"
$DeviceEnumerator = "Bus"
$DevicesBus = @(($Devices | Select-Object).Bus | Sort-Object)
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash"; Type = "AMD"; Fee = 0.0065; MinMemGB = 4.0; MinMemGBWin10 = 4.0; MinerSet = 1; Arguments = " --algo etchash" } # PhoenixMiner-v5.5c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";  Type = "AMD"; Fee = 0.0065; MinMemGB = 4.0; MinMemGBWin10 = 4.0; MinerSet = 1; Arguments = " --algo ethash" } # BMiner-v16.3.7 & PhoenixMiner-v5.5c are fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";  Type = "AMD"; Fee = 0.01;   MinMemGB = 3.0; MinMemGBWin10 = 3.0; MinerSet = 1; Arguments = " --algo kawpow --fee 1" } # XmRig-v6.7.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = "Octopus"; Type = "AMD"; Fee = 0.03;   MinMemGB = 5.0; MinMemGBWin10 = 5.0; MinerSet = 0; Arguments = " --algo octopus --fee 1" }

    [PSCustomObject]@{ Algorithm = "BeamV3";        Type = "NVIDIA"; Fee = 0.01;   MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; MinerSet = 0; Arguments = " -mt 1 --algo beamv3 --fee 1" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29bfc"; Type = "NVIDIA"; Fee = 0.01;   MinMemGB = 5.0; MinMemGBWin10 = 6.1;  MinComputeCapability = 6.0; MinerSet = 0; Arguments = " -mt 1 --algo bfc --fee 1" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29";   Type = "NVIDIA"; Fee = 0.01;   MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; MinerSet = 1; Arguments = " -mt 1 --algo cuckarood --fee 1" } # GMiner-v2.44 is fastest
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    Type = "NVIDIA"; Fee = 0.01;   MinMemGB = 8.0; MinMemGBWin10 = 10.0; MinComputeCapability = 6.0; MinerSet = 0; Arguments = " -mt 1 --algo cuckatoo32 --fee 1" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      Type = "NVIDIA"; Fee = 0.01;   MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; MinerSet = 1; Arguments = " -mt 1 --algo cuckoo_ae --fee 1" } # GMiner-v2.44 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "NVIDIA"; Fee = 0.0065; MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; MinerSet = 1; Arguments = " -mt 1 --algo etchash" } # PhoenixMiner-v5.5c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "NVIDIA"; Fee = 0.0065; MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; MinerSet = 1; Arguments = " -mt 1 --algo ethash" } # BMiner-v16.3.7 & TTMiner-v5.0.3 are fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";        Type = "NVIDIA"; Fee = 0.01;   MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; MinerSet = 1; Arguments = " -mt 1 --algo kawpow --fee 1" } # XmRig-v6.7.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = "Sero";          Type = "NVIDIA"; Fee = 0.01;   MinMemGB = 2.0; MinMemGBWin10 = 2.0;  MinComputeCapability = 6.0; MinerSet = 0; Arguments = " -mt 1 --algo progpow_sero --fee 1" }
    [PSCustomObject]@{ Algorithm = "Octopus";       Type = "NVIDIA"; Fee = 0.03;   MinMemGB = 5.0; MinMemGBWin10 = 5.0;  MinComputeCapability = 6.1; MinerSet = 1; Arguments = " -mt 1 --algo octopus --fee 1" } # Trex-v0.19.11 is fastest
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 
        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 
                # If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -match "^MiningPoolHub(|Coins)$") { Return } # Temp fix
                If ($_.Algorithm -in @("EtcHash", "Ethash", "KawPow") -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$')) { Return } # Ethash on Navi is slow

                $Arguments = $_.Arguments
                $MinComputeCapability = $_.MinComputeCapability

                # Windows 10 requires more memory on some algos
                If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGB = $_.MinMemGBWin10 } Else { $MinMemGB = $_.MinMemGB }

                If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                    $WaitForData = 60 # Seconds, max. wait time until first data sample
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }
                ElseIf ($_.Algorithm -eq "Octopus") { $WaitForData = 45 }# Seconds, max. wait time until first data sample
                Else { $WaitForData = 15 }# Seconds, max. wait time until first data sample

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB } | Where-Object { $_.OpenCL.ComputeCapability -ge $MinComputeCapability })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Command $Arguments -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($_.Algorithm -match "^EtcHash|^Ethash|^Cuck*") { 
                        If ($Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$") { 
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

                    $Arguments += " --url $($Protocol)$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User):$($Pools.($_.Algorithm).Pass)"

                    # Optionally disable dev fee mining
                    If ($Config.DisableMinerFee) { 
                        $_.Fee = 0
                    }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$Arguments --no-watchdog --api 127.0.0.1:$($MinerAPIPort) --devices $(($Miner_Devices.$DeviceEnumerator | Sort-Object | ForEach-Object { '{0:x}' -f $DevicesBus.IndexOf([Int]$_) }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = $_.Algorithm
                        API         = "NBMiner"
                        Port        = $MinerAPIPort
                        Wrap        = $false
                        URI         = $Uri
                        Fee         = $_.Fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)"
                        WaitForData = $WaitForData
                    }
                }
            }
        }
    }
}
