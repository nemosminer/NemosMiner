using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v32.0/NBMiner_32.0_Win.zip"
$DeviceEnumerator = "Type_Slot"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Eaglesong");           Fee = @(0.01);       MinMemGB = 0.1; MinMemGBWin10 = 0.1; Type = "AMD";    Command = " --algo eaglesong --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Eaglesong"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0; Type = "AMD";    Command = " --algo eaglesong_ethash --fee 1" }
#   [PSCustomObject]@{ Algorithm = @("Ethash");              Fee = @(0.0065);     MinMemGB = 4.0; MinMemGBWin10 = 4.0; Type = "AMD";    Command = " --algo ethash" } #BMiner-v16.3.1 & PhoenixMiner-v5.1c are fastest
    [PSCustomObject]@{ Algorithm = @("Handshake");           Fee = @(0.01);       MinMemGB = 0.1; MinMemGBWin10 = 0.1; Type = "AMD";    Command = " --algo hns --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0; Type = "AMD";    Command = " --algo hns_ethash --fee 1" }
#   [PSCustomObject]@{ Algorithm = @("KawPoW");              Fee = @(0.01);       MinMemGB = 3.0; MinMemGBWin10 = 3.0; Type = "AMD";    Command = " --algo kawpow --fee 1" } #Wildrig-v0.27.6 is fastest

    [PSCustomObject]@{ Algorithm = @("BeamV3");              Fee = @(0.01);       MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo beamv3 --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29bfc");       Fee = @(0.01);       MinMemGB = 5.0; MinMemGBWin10 = 6.1;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo bfc --fee 1" }
#   [PSCustomObject]@{ Algorithm = @("CuckarooD29");         Fee = @(0.01);       MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo cuckarood --fee 1" } #GMiner-v2.26 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29s");         Fee = @(0.01);       MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo cuckaroo_swap --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");          Fee = @(0.01);       MinMemGB = 8.0; MinMemGBWin10 = 10.0; MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo cuckatoo --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");          Fee = @(0.01);       MinMemGB = 6.0; MinMemGBWin10 = 8.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo cuckatoo32 --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");            Fee = @(0.01);       MinMemGB = 5.0; MinMemGBWin10 = 6.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo cuckoo_ae --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Eaglesong");           Fee = @(0.01);       MinMemGB = 0.1; MinMemGBWin10 = 0.1;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo eaglesong --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Eaglesong"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo eaglesong_ethash --fee 1" }
#   [PSCustomObject]@{ Algorithm = @("Ethash");              Fee = @(0.0065);     MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo ethash" } #BMiner-v16.3.1 & PhoenixMiner-v5.1c are fastest
#   [PSCustomObject]@{ Algorithm = @("Handshake");           Fee = @(0.01)      ; MinMemGB = 0.1; MinMemGBWin10 = 0.1;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo hns --fee 1" } #SRBMminerMulti-v0.5.2 is fastest
    [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo hns_ethash --fee 1" }
    [PSCustomObject]@{ Algorithm = @("KawPoW");              Fee = @(0.01)      ; MinMemGB = 3.0; MinMemGBWin10 = 3.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo kawpow --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Sero");                Fee = @(0.01)      ; MinMemGB = 2.0; MinMemGBWin10 = 2.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo progpow_sero --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Sipc");                Fee = @(0.01)      ; MinMemGB = 1.0; MinMemGBWin10 = 1.0;  MinComputeCapability = 6.0; Type = "NVIDIA"; Command = " --algo sipc --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Tensority");           Fee = @(0.01)      ; MinMemGB = 0.1; MinMemGBWin10 = 0.1;  MinComputeCapability = 6.1; Type = "NVIDIA"; Command = " --algo tensority --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Tensority"); Fee = @(0.01, 0.01); MinMemGB = 4.0; MinMemGBWin10 = 4.0;  MinComputeCapability = 6.1; Type = "NVIDIA"; Command = " --algo tensority_ethash --fee 1" }
)

If ($Commands = $Commands | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    #Intensities for 2. algorithm
    $Intensities2 = [PSCustomObject]@{ 
        "Eaglesong" = @(1, 2, 3, 4, 5, 6, 7, 8) #default 6
        "Handshake" = @(1, 2, 3, 4, 5, 6, 7, 8) #default 6
        "Tensority" = @(1, 2, 3, 4, 5, 6, 7, 8) #default 6
    }

    # Build command sets for intensities
    $Commands = $Commands | ForEach-Object { 
        $Command = $_
        If ($_.Algorithm[1]) { 
            $Intensities2.($_.Algorithm[1]) | Select-Object | ForEach-Object { 
                $Command | Add-Member Intensity2 ([Uint16]$_) -Force
                $Command | ConvertTo-Json | ConvertFrom-Json
            }
        }
        Else { 
            $Command
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

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB } | Where-Object { $_.OpenCL.ComputeCapability -ge $MinComputeCapability })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($_.Algorithm[1]) + @($_.Intensity2) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$Command = Get-CommandPerDevice -Command $Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($_.Algorithm[0] -match "^Ethash*|^Cuck*") { 
                        $Protocol = If ($Pools.($_.Algorithm[0]).Name -match "^MPH*|^NiceHash*") { "nicehash+tcp://" } Else { "ethproxy+tcp://" }
                    }
                    Else { $Protocol = "stratum+tcp://" }
                    If ($Pools.($_.Algorithm[0]).SSL) { $Protocol = $Protocol -replace '\+tcp\://$', '+ssl://' }

                    If ($_.Algorithm[1]) { 
                        If ($_.Algorithm[1] -match "^Ethash*|^Cuck*") { 
                            $Protocol2 = If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Name -match "MPH*|NiceHash*") { "nicehash+tcp://" } Else { "ethproxy+tcp://" }
                        }
                        Else { $Protocol2 = "stratum+tcp://" }
                        If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { $Protocol2 = $Protocol2 -replace '\+tcp\://$', '+ssl://' }

                        $Command += " --url $($Protocol2)$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) --user $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass) --secondary-url $($Protocol)$($Pools.$($_.Algorithm[0]).Host):$($Pools.$($_.Algorithm[0]).Port) --secondary-user $($Pools.$($_.Algorithm[0]).User):$($Pools.($_.Algorithm[0]).Pass)$(If($_.Intensity2 -ge 0) { " --secondary-intensity $($_.Intensity2)" })"
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
