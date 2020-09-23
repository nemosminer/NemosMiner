using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\bminer.exe"
$Uri = "https://www.bminercontent.com/releases/bminer-v16.3.1-135666e-amd64.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = @("BeamV3");              Protocol = @(" -uri beam");                         Fee = @(0.02);      MinMemGB = 7.8; Type = "AMD"; Command = "" } #Undefined but requested solver: beamhash3d
    [PSCustomObject]@{ Algorithm = @("Ethash");              Protocol = @(" -uri ethproxy");                     Fee = @(0.0065);    MinMemGB = 4.0; Type = "AMD"; Command = "" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake"); Protocol = @(" -uri ethproxy", " -uri2 handshake"); Fee = @(0.0065, 0); MinMemGB = 4.0; Type = "AMD"; Command = "" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Tensority"); Protocol = @(" -uri ethproxy", " -uri2 tensority"); Fee = @(0.0065, 0); MinMemGB = 4.0; Type = "AMD"; Command = "" }

#   [PSCustomObject]@{ Algorithm = @("BeamV3");              Protocol = @(" -uri beam");                         Fee = @(0.02);      MinMemGB = 6.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("Cuckaroo29bfc");       Protocol = @(" -uri bfc");                          Fee = @(0.02);      MinMemGB = 8.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("CuckarooM29");         Protocol = @(" -uri cuckaroo29m");                  Fee = @(0.01);      MinMemGB = 4.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("CuckarooZ29");         Protocol = @(" -uri cuckaroo29z");                  Fee = @(0.02);      MinMemGB = 6.0; Type = "NVIDIA"; Command = " --fast 4" } #GMiner-v2.23 is fastest
#   [PSCustomObject]@{ Algorithm = @("Cuckatoo31");          Protocol = @(" -uri cuckatoo31");                   Fee = @(0.01);      MinMemGB = 8.0; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");          Protocol = @(" -uri cuckatoo32");                   Fee = @(0.01);      MinMemGB = 8.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("Cuckoo29");            Protocol = @(" -uri aeternity");                    Fee = @(0.01);      MinMemGB = 6.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("Equihash1445");        Protocol = @(" -pers auto -uri equihash1445");      Fee = @(0.02);      MinMemGB = 2.0; Type = "NVIDIA"; Command = " --fast 4" } #MiniZ-v1.6v6 ist fastest
#   [PSCustomObject]@{ Algorithm = @("EquihashBTG");         Protocol = @(" -uri zhash");                        Fee = @(0.02);      MinMemGB = 2.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("Ethash");              Protocol = @(" -uri ethproxy");                     Fee = @(0.0065);    MinMemGB = 4.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("Ethash", "Tensority"); Protocol = @(" -uri ethproxy", " -uri2 tensority"); Fee = @(0.0065, 0); MinMemGB = 4.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("Qitmeer");             Protocol = @(" -uri qitmeer");                      Fee = @(0.02);      MinMemGB = 6.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("Raven");               Protocol = @(" -uri raven");                        Fee = @(0.02);      MinMemGB = 2.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("Sero");                Protocol = @(" -uri sero");                         Fee = @(0.02);      MinMemGB = 2.0; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("Tensority");           Protocol = @(" -uri tensority");                    Fee = @(0.02);      MinMemGB = 2.0; Type = "NVIDIA"; Command = " --fast 4" }
)

If ($Commands = $Commands | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    #Intensities for 2. algorithm
    $Intensities2 = [PSCustomObject]@{ 
        "Tensority" = @($null, 10, 30, 60, 100, 150) # $null = Auto-Intensity
        "Handshake" = @($null, 10, 30, 60, 100, 150) # $null = Auto-Intensity
    }

    # Build command sets for intensities
    $Commands = $Commands | ForEach-Object { 
        $Command= $_ 
        If ($_.Algorithm[1]) { 
            $Intensities2.($_.Algorithm[1]) | Select-Object | ForEach-Object { 
                $Command | Add-Member Intensity2 $_ -Force
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

                If ($_.Algorithm[1] -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$')) { Return } #Dual mining not supported on Navi
                If ($_.Algorithm[0] -eq "Ethash" -and $Pools.($_.Algorithm[0]).Name -like "MPH*") { Return } #temp fix

                $Command = $_.Command
                $MinMemGB = $_.MinMemGB

                #Add 1GB when GPU with connected monitor
                If ($_.Algorithm[0] -eq "BeamV3" -and ($SelectedDevices | Where-Object { $_.CIM.CurrentRefreshRate })) { $MinMemGB += 1 }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($_.Algorithm[1]) + @($_.Intensity2) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$Command = Get-CommandPerDevice -Command $Command -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Protocol = $_.Protocol[0]
                    If ($Pools.($_.Algorithm[0]).SSL) { $Protocol = "$($Protocol)+ssl" }
                    $Command += "$($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm[0]).User)):$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm[0]).Pass))@$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)"
                    If ($_.Algorithm[0] -like "Cuck*") { 
                        $WarmupTime = 90
                    }
                    Else { 
                        $WarmupTime = 60
                    }

                    If ($_.Algorithm[1]) { 
                        $Protocol2 = $_.Protocol[1]
                        If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { $Protocol2 = "$($Protocol2)+ssl" }
                        $Command += "$($Protocol2)://$([System.Web.HttpUtility]::UrlEncode($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User)):$([System.Web.HttpUtility]::UrlEncode($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass))@$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port)$(If($_.Intensity2) { " -dual-intensity $([Double]$_.Intensity2)" })"
                        $WarmupTime = 120
                    }

                    #Optionally disable dev fee mining
                    If ($Config.DisableMinerFees) { 
                        $Command += " -nofee"
                        $_.Fee = @(0) * ($_.Algorithm | Select-Object).count
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$Command -watchdog=false -api 127.0.0.1:$($MinerAPIPort) -devices $(If ($Miner_Devices.Vendor -eq "AMD") { "amd:" })$(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API        = "Bminer"
                        Port       = $MinerAPIPort
                        URI        = $URI
                        Fee        = $_.Fee
                        WarmupTime = $WarmupTime #seconds
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
