using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\bminer.exe"
$Uri = "https://www.bminercontent.com/releases/bminer-v16.2.11-4ecd066-amd64.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = @("BeamV3", $null);       Protocol = @(" -uri beam");                           Fee = @(0.02);      MinMemGB = 8; Type = "AMD"; Command = "" }
    [PSCustomObject]@{ Algorithm = @("Ethash", $null);       Protocol = @(" -uri ethstratum");                     Fee = @(0.0065);    MinMemGB = 4; Type = "AMD"; Command = "" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake"); Protocol = @(" -uri ethstratum", " -uri2 handshake"); Fee = @(0.0065, 0); MinMemGB = 4; Type = "AMD"; Command = "" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Tensority"); Protocol = @(" -uri ethstratum", " -uri2 tensority"); Fee = @(0.0065, 0); MinMemGB = 4; Type = "AMD"; Command = "" }

#   [PSCustomObject]@{ Algorithm = @("BeamV3", $null);        Protocol = @(" -uri beam");                           Fee = @(0.02);      MinMemGB = 8; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29bfc", $null); Protocol = @(" -uri bfc");                            Fee = @(0.02);      MinMemGB = 8; Type = "NVIDIA"; Command = " --fast 4" }
#   [PSCustomObject]@{ Algorithm = @("CuckarooM29", $null);   Protocol = @(" -uri cuckaroo29m");                    Fee = @(0.01);      MinMemGB = 4; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31", $null);    Protocol = @(" -uri cuckatoo31");                     Fee = @(0.01);      MinMemGB = 8; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32", $null);    Protocol = @(" -uri cuckatoo32");                     Fee = @(0.01);      MinMemGB = 8; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("CuckooCycle", $null);   Protocol = @(" -uri aeternity");                      Fee = @(0.01);      MinMemGB = 2; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Equihash1445", $null);  Protocol = @(" -pers auto -uri equihash1445");        Fee = @(0.02);      MinMemGB = 2; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("EquihashBTG", $null);   Protocol = @(" -uri zhash");                          Fee = @(0.02);      MinMemGB = 2; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Ethash", $null);        Protocol = @(" -uri ethstratum");                     Fee = @(0.0065);    MinMemGB = 4; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Tensority");  Protocol = @(" -uri ethstratum", " -uri2 tensority"); Fee = @(0.0065, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Qitmeer", $null);       Protocol = @(" -uri qitmeer");                        Fee = @(0.02);      MinMemGB = 6; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Raven", $null);         Protocol = @(" -uri raven");                          Fee = @(0.02);      MinMemGB = 2; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Sero", $null);          Protocol = @(" -uri sero");                           Fee = @(0.02);      MinMemGB = 2; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Tensority", $null);     Protocol = @(" -uri tensority");                      Fee = @(0.02);      MinMemGB = 2; Type = "NVIDIA"; Command = " --fast 4" }
    [PSCustomObject]@{ Algorithm = @("Cuckarooz29", $null);   Protocol = @(" -uri cuckaroo29z");                    Fee = @(0.02);      MinMemGB = 4; Type = "NVIDIA"; Command = " --fast 4" }
)
#Intensities for 2. algorithm
$Intensities2 = [PSCustomObject]@{ 
    "Decred"    = @(0) # 0 = Auto-Intensity
    "Blake2s"   = @(20, 40, 60) # 0 = Auto-Intensity not working with Blake2s
    "Tensority" = @(0) # 0 = Auto-Intensity
    "Vblake"    = @(0) # 0 = Auto-Intensity
}

# Build command sets for intensities
$Commands = $Commands | ForEach-Object { 
    $Command= $_ 
    If ($_.Algorithm | Select-Object -Index 1) { 
        $Intensities2.($_.Algorithm | Select-Object -Index 1) | Select-Object | ForEach-Object { 
            $Command| Add-Member Intensity2 ([Uint16]$_) -Force
            $Command| ConvertTo-Json | ConvertFrom-Json
        }
    }
    Else { 
        $Command
    }
}

$Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object Type -eq $_.Type | ForEach-Object { $Algo = $_.Algorithm | Select-Object -Index 0; $_ } | ForEach-Object { 
            $MinMemGB = $_.MinMemGB
            
            #Cuckatoo3? on windows 10 requires 3.5 GB extra
            If ($Algo -match "Cuckaroo*|Cuckoo*" -and [System.Version]$PSVersionTable.BuildVersion -ge "10.0.0.0") { $MinMemGB += 3.5 }

            If ($Miner_Devices = @($SelectedDevices | Where-Object { ([math]::Round((10 * $_.OpenCL.GlobalMemSize / 1GB), 0) / 10) -ge $MinMemGB })) { 
                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -DeviceIDs $Miner_Devices.$DeviceEnumerator

                $Protocol = $_.Protocol | Select-Object -Index 0
                If ($Pools.$Algo.SSL) { $Protocol = "$($Protocol)+ssl" }
                #If ($Pools.$Algo.SSL -and $Protocol -notmatch "*aeternity|*ethstratum") { $Protocol = "$($Protocol)+ssl" }
                $_.Command += "$($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo.User)):$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo.Pass))@$($Pools.$Algo.Host):$($Pools.$Algo.Port)"
                $WarmupTime = 60

                If ($Algo2 = $_.Algorithm | Select-Object -Index 1) { 
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($Algo2) + @($_.Intensity2) | Select-Object) -join '-'
                    $Protocol2 = $_.Protocol | Select-Object -Index 1
                    If ($Pools.$Algo2.SSL) { $Protocol2 = "$($Protocol2)+ssl" }
                    $_.Command += "$($Protocol2)://$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo2.User)):$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo2.Pass))@$($Pools.$Algo2.Host):$($Pools.$Algo2.Port)$(If($_.Intensity2 -ge 0) { " -dual-intensity $($_.Intensity2)" })"
                    $WarmupTime = 120
                }
                Else {
                    $Algo2 = $null
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'
                }

                #Optionally disable dev fee mining
                If ($Config.DisableMinerFees) { 
                    $_.Command += " -nofee"
                    $_.Fee = @(0) * ($_.Algorithm | Select-Object).count
                }

                If ($null -eq ($_.Algorithm | Select-Object -Index 1) -or $Pools.$Algo2.Host) { 
                    [PSCustomObject]@{ 
                        Name               = $Miner_Name
                        DeviceName         = $Miner_Devices.Name
                        Path               = $Path
                        Arguments          = ("$($_.Command) -watchdog=false -api 127.0.0.1:$($MinerAPIPort) -devices $(If ($Miner_Devices.Vendor -eq "AMD") { "amd:" })$(($Miner_Devices | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm          = ($Algo, $Algo2) | Select-Object
                        API                = "Bminer"
                        Port               = $MinerAPIPort
                        URI                = $URI
                        Fee                = $_.Fee
                        WarmupTime         = $WarmupTime #seconds
                        MinerUri           = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
