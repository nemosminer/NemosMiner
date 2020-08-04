using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v31.1/NBMiner_31.1_Win.zip"
$DeviceEnumerator = "Type_Slot"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @($null, "Cuckatoo31");   Fee = @(0.01);       MinMemGB = 8; Type = "AMD"   ; Command = " --algo cuckatoo --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Cuckatoo32");   Fee = @(0.01);       MinMemGB = 8; Type = "AMD"   ; Command = " --algo cuckatoo32 --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "CuckarooD29");  Fee = @(0.01);       MinMemGB = 4; Type = "AMD"   ; Command = " --algo cuckarood --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Cuckaroo29s");  Fee = @(0.01);       MinMemGB = 4; Type = "AMD"   ; Command = " --algo cuckaroo_swap --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "CuckooCycle");  Fee = @(0.01);       MinMemGB = 4; Type = "AMD"   ; Command = " --algo cuckoo_ae --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Ethash");       Fee = @(0.0065);     MinMemGB = 4; Type = "AMD"   ; Command = " --algo ethash" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Eaglesong"); Fee = @(0.01, 0.01); MinMemGB = 4; Type = "AMD"   ; Command = " --algo eaglesong_ethash --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake"); Fee = @(0.01, 0.01); MinMemGB = 4; Type = "AMD"   ; Command = " --algo hns_ethash --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Tensority"); Fee = @(0.01, 0.01); MinMemGB = 4; Type = "AMD"   ; Command = " --algo tensority_ethash --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Handshake");    Fee = @(0.01);       MinMemGB = 4; Type = "AMD"   ; Command = " --algo hns --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "KawPoW");       Fee = @(0.01);       MinMemGB = 4; Type = "AMD"   ; Command = " --algo kawpow --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Tensority");    Fee = @(0.01);       MinMemGB = 4; Type = "AMD"   ; Command = " --algo tensority --fee 1" }

    [PSCustomObject]@{ Algorithm = @($null, "Cuckatoo31");   Fee = @(0.01);       MinMemGB = 8; Type = "NVIDIA"; Command = " --algo cuckatoo --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Cuckatoo32");   Fee = @(0.01);       MinMemGB = 8; Type = "NVIDIA"; Command = " --algo cuckatoo32 --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "CuckarooD29");  Fee = @(0.01);       MinMemGB = 4; Type = "NVIDIA"; Command = " --algo cuckarood --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Cuckaroo29s");  Fee = @(0.01);       MinMemGB = 4; Type = "NVIDIA"; Command = " --algo cuckaroo_swap --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "CuckooCycle");  Fee = @(0.01);       MinMemGB = 4; Type = "NVIDIA"; Command = " --algo cuckoo_ae --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Ethash");       Fee = @(0.0065);     MinMemGB = 4; Type = "NVIDIA"; Command = " --algo ethash" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Eaglesong"); Fee = @(0.01, 0.01); MinMemGB = 4; Type = "NVIDIA"; Command = " --algo eaglesong_ethash --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake"); Fee = @(0.01, 0.01); MinMemGB = 4; Type = "NVIDIA"; Command = " --algo hns_ethash --fee 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Tensority"); Fee = @(0.01, 0.01); MinMemGB = 4; Type = "NVIDIA"; Command = " --algo tensority_ethash --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Handshake");    Fee = @(0.01)      ; MinMemGB = 4; Type = "NVIDIA"; Command = " --algo hns --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "KawPoW");       Fee = @(0.01)      ; MinMemGB = 4; Type = "NVIDIA"; Command = " --algo kawpow --fee 1" }
    [PSCustomObject]@{ Algorithm = @($null, "Tensority");    Fee = @(0.01)      ; MinMemGB = 4; Type = "NVIDIA"; Command = " --algo tensority --fee 1" })

$Intensities2 = [PSCustomObject]@{ 
    "Eaglesong" = @(1, 2, 3, 4, 5, 6, 7, 8) #default 6
    "Handshake" = @(1, 2, 3, 4, 5, 6, 7, 8) #default 6
}

# Build command sets for intensities
$Commands = $Commands | ForEach-Object { 
    $Command = $_ 
    If ($_.Algorithm | Select-Object -Index 1) { 
        $Intensities2.($_.Algorithm | Select-Object -Index 1) | Select-Object | ForEach-Object { 
            $Command | Add-Member Intensity2 ([Uint16]$_) -Force
            $Command | ConvertTo-Json | ConvertFrom-Json
        }
    }
    Else { 
        $Command
    }
}

$Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object Type -eq $_.Type | ForEach-Object { $Algo = $_.Algorithm | Select-Object -Index 1; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
            $MinMemGB = $_.MinMemGB
            
            #Cuckatoo3? on windows 10 requires 3.5 GB extra
            If ($Algo -match "Cuckatoo31", "Cuckatoo32" -and [System.Version]$PSVersionTable.BuildVersion -ge "10.0.0.0") { $MinMemGB += 3.5 }

            If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                If ($Pools.$Algo.Name -match "MPH*|NiceHash*") { $Protocol = "nicehash+tcp://" }
                ElseIf ($Algo -like "Ethash*") { $Protocol = "ethproxy+tcp://" } 
                Else { $Protocol = "stratum+tcp://" }
                If ($Pools.$Algo.SSL) { $_.Command = $_.Command -replace '\+tcp\://$', '+ssl://' }

                $_.Command += " --url $($Pools.$Algo.Host):$($Pools.$Algo.Port) --user $($Pools.$Algo.User):$($Pools.$Algo.Pass)"

                If ($Algo2 = $_.Algorithm | Select-Object -Index 0) { 
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($Algo) + @($_.Intensity2) | Select-Object) -join '-'

                    If ($Pools.$Algo2.Name -match "MPH*|NiceHash*") { $Protocol = "nicehash+tcp://" }
                    ElseIf ($Algo -like "Ethash*") { $Protocol = "ethproxy+tcp://" } 
                    Else { $Protocol = "stratum+tcp://" }
                    If ($Pools.$Algo2.SSL) { $_.Command = $_.Command -replace '\+tcp\://$', '+ssl://' }

                    $_.Command += " --secondary-url nicehash+tcp://$($Pools.$($Algo2).Host):$($Pools.$($Algo2).Port) --secondary-user $($Pools.$($Algo2).User):$($Pools.$Algo2.Pass)$(If($_.Intensity2 -ge 0) { " --secondary-intensity $($_.Intensity2)" })"
                }
                Else { 
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'
                }

                If ($null -eq ($_.Algorithm | Select-Object -Index 0) -or $Pools.$Algo2.Host) { 
                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$($_.Command) --no-watchdog --api 127.0.0.1:$($MinerAPIPort) --devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($Algo2, $Algo) | Select-Object
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
