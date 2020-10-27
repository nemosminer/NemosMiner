using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v32.1/NBMiner_32.1_Win.zip"
$DeviceEnumerator = "Type_Slot"
$EthashMemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Eaglesong");           Fee = @(0.01);       MinMemGB = 0.1; MinMemGBWin10 = 0.1; Type = "AMD";    Command = " --algo eaglesong --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Eaglesong"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0; Type = "AMD";    Command = " --algo eaglesong_ethash --fee 1" }
#   [PSCustomObject]@{ Algorithm = @("Ethash");              Fee = @(0.0065);     MinMemGB = 4.0; MinMemGBWin10 = 4.0; Type = "AMD";    Command = " --algo ethash" } #BMiner-v16.3.1 & PhoenixMiner-v5.1c are fastest
    [PSCustomObject]@{ Algorithm = @("Handshake");           Fee = @(0.01);       MinMemGB = 0.1; MinMemGBWin10 = 0.1; Type = "AMD";    Command = " --algo hns --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0; Type = "AMD";    Command = " --algo hns_ethash --fee 1" }
#   [PSCustomObject]@{ Algorithm = @("KawPoW");              Fee = @(0.01);       MinMemGB = 3.0; MinMemGBWin10 = 3.0; Type = "AMD";    Command = " --algo kawpow --fee 1" } #Wildrig-v0.28.1 is fastest

#   [PSCustomObject]@{ Algorithm = @("BeamV3");              Fee = @(0.01);       MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo beamv3 --fee 1" } #MiniZ-v1.6w is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29bfc");       Fee = @(0.01);       MinMemGB = 5.0; MinMemGBWin10 = 6.1;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo bfc --fee 1" }
#   [PSCustomObject]@{ Algorithm = @("CuckarooD29");         Fee = @(0.01);       MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo cuckarood --fee 1" } #GMiner-v2.29 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29s");         Fee = @(0.01);       MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo cuckaroo_swap --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");          Fee = @(0.01);       MinMemGB = 8.0; MinMemGBWin10 = 10.0; MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo cuckatoo --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");          Fee = @(0.01);       MinMemGB = 6.0; MinMemGBWin10 = 8.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo cuckatoo32 --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");            Fee = @(0.01);       MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo cuckoo_ae --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Eaglesong");           Fee = @(0.01);       MinMemGB = 0.1; MinMemGBWin10 = 0.1;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo eaglesong --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Eaglesong"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo eaglesong_ethash --fee 1" }
#   [PSCustomObject]@{ Algorithm = @("Ethash");              Fee = @(0.0065);     MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo ethash" } #BMiner-v16.3.1 & PhoenixMiner-v5.1c are fastest
#   [PSCustomObject]@{ Algorithm = @("Handshake");           Fee = @(0.01)      ; MinMemGB = 0.1; MinMemGBWin10 = 0.1;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo hns --fee 1" } #SRBMminerMulti-v0.5.4 is fastest
    [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo hns_ethash --fee 1" }
    [PSCustomObject]@{ Algorithm = @("KawPoW");              Fee = @(0.01)      ; MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo kawpow --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Sero");                Fee = @(0.01)      ; MinMemGB = 2.0; MinMemGBWin10 = 2.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo progpow_sero --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Sipc");                Fee = @(0.01)      ; MinMemGB = 1.0; MinMemGBWin10 = 1.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " -mt 1 --algo sipc --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Tensority");           Fee = @(0.01)      ; MinMemGB = 0.1; MinMemGBWin10 = 0.1;  MinComputeCapability = 6.1; Type = "NVIDIA"; Command = " -mt 1 --algo tensority --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Tensority"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.1; Type = "NVIDIA"; Command = " -mt 1 --algo tensority_ethash --fee 1" }
)

If ($Commands = $Commands | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    #Intensities for 2. algorithm
    $Intensities = [PSCustomObject]@{ 
        "Eaglesong" = @(1..10)
        "Handshake" = @(1..10)
        "Tensority" = @(1..10)
    }

    # Build command sets for intensities
    $Commands = $Commands | ForEach-Object { 
        $_.PsObject.Copy()
        ForEach ($Intensity in $Intensities.($_.Algorithm[1])) { 
            $_ | Add-Member Intensity $Intensity -Force
            $_.PsObject.Copy()
        }
    }

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 
        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object { 
                If ($_.Algorithm[0] -eq "Ethash" -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$')) { Return } #Ethash on Navi is slow

                $Command = $_.Command
                $MinComputeCapability = $_.MinComputeCapability

                #Windows 10 requires more memory on some algos
                If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGB = $_.MinMemGBWin10 } Else { $MinMemGB = $_.MinMemGB }
                If ($_.Algorithm[0] -eq "Ethash") { 
                    $MinMemGB = ($Pools.($_.Algorithm[0]).EthashDAGSize + $EthashMemReserve) / 1GB
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB } | Where-Object { $_.OpenCL.ComputeCapability -ge $MinComputeCapability })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($_.Algorithm[1]) + @($_.Intensity) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$Command = Get-CommandPerDevice -Command $Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($_.Algorithm[0] -match "^Ethash*|^Cuck*") { 
                        If ($Pools.($_.Algorithm[0]).Name -match "^MPH*|^NiceHash*") { 
                            $Protocol = "nicehash+tcp://"
                        }
                        Else { 
                            $Protocol = "ethproxy+tcp://"
                        }
                    }
                    Else { 
                        $Protocol = "stratum+tcp://"
                    }
                    If ($Pools.($_.Algorithm[0]).SSL) { $Protocol = $Protocol -replace '\+tcp\://$', '+ssl://' }

                    If ($_.Algorithm[1]) { 
                        If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { 
                            $Protocol2 = "stratum+ssl://"
                        }
                        Else { 
                            $Protocol2 = "stratum+tcp://"
                        }
                        $Command += " --url $($Protocol2)$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) --user $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass) --secondary-url $($Protocol)$($Pools.$($_.Algorithm[0]).Host):$($Pools.$($_.Algorithm[0]).Port) --secondary-user $($Pools.$($_.Algorithm[0]).User):$($Pools.($_.Algorithm[0]).Pass)"
                        If ($_.Intensity -ge 0) { $Command += " --secondary-intensity $($_.Intensity)" }
                    }
                    Else { 
                        $Command += " --url $($Protocol)$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) --user $($Pools.($_.Algorithm[0]).User):$($Pools.($_.Algorithm[0]).Pass)"
                    }

                    #Optionally disable dev fee mining
                    If ($Config.DisableMinerFees) { 
                        $_.Fee = @(0) * ($_.Algorithm | Select-Object).count
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$Command --no-watchdog --api 127.0.0.1:$($MinerAPIPort) --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API        = "NBMiner"
                        Port       = $MinerAPIPort
                        Wrap       = $false
                        URI        = $Uri
                        Fee        = $_.Fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
