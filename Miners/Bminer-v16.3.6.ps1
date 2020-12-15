using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\bminer.exe"
$Uri = "https://www.bminercontent.com/releases/bminer-v16.3.6-b37c2ec-amd64.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs 

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = @("BeamV3");              Type = "AMD"; Fee = @(0.02);      MinMemGB = 7.8; Protocol = @(" -uri beam");                         Command = "" } #Undefined but requested solver: beamhash3d
#   [PSCustomObject]@{ Algorithm = @("Ethash");              Type = "AMD"; Fee = @(0.0065);    MinMemGB = 4.0; Protocol = @(" -uri ethproxy");                     Command = "" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake"); Type = "AMD"; Fee = @(0.0065, 0); MinMemGB = 4.0; Protocol = @(" -uri ethproxy", " -uri2 handshake"); Command = "" }

#   [PSCustomObject]@{ Algorithm = @("BeamV3");        Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 6.0; Protocol = @(" -uri beam");                    Command = "" } #NBMiner-v34.5 is faster but has 2% fee
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29bfc"); Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 8.0; Protocol = @(" -uri bfc");                     Command = "" }
    [PSCustomObject]@{ Algorithm = @("CuckarooM29");   Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 4.0; Protocol = @(" -uri cuckaroo29m");             Command = "" }
#   [PSCustomObject]@{ Algorithm = @("CuckarooZ29");   Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 6.0; Protocol = @(" -uri cuckaroo29z");             Command = "" } #GMiner-v2.34 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");    Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0; Protocol = @(" -uri cuckatoo31");              Command = "" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");    Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0; Protocol = @(" -uri cuckatoo32");              Command = "" }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");      Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 6.0; Protocol = @(" -uri aeternity");               Command = "" }
#   [PSCustomObject]@{ Algorithm = @("Equihash1445");  Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; Protocol = @(" -pers auto -uri equihash1445"); Command = "" } #MiniZ-v1.6x is fastest
    [PSCustomObject]@{ Algorithm = @("EquihashBTG");   Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; Protocol = @(" -uri zhash");                   Command = "" }
#   [PSCustomObject]@{ Algorithm = @("Ethash");        Type = "NVIDIA"; Fee = @(0.0065); MinMemGB = 4.0; Protocol = @(" -uri ethproxy");                Command = "" }
#   [PSCustomObject]@{ Algorithm = @("Octopus");       Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; Protocol = @(" -uri conflux");                 Command = "" } #NBMiner-v34.5 is faster is faster but has 2% fee
#   [PSCustomObject]@{ Algorithm = @("Qitmeer");       Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 6.0; Protocol = @(" -uri qitmeer");                 Command = "" }
#   [PSCustomObject]@{ Algorithm = @("Raven");         Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; Protocol = @(" -uri raven");                   Command = "" }
#   [PSCustomObject]@{ Algorithm = @("Sero");          Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0; Protocol = @(" -uri sero");                    Command = "" }
)

If ($Commands = $Commands | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    # Does not seem to make any difference for Handshake
    # #Intensities for 2. algorithm
    # $Intensities = [PSCustomObject]@{ 
    #     "Handshake" = @(0, 10, 30, 60, 100, 150, 210) #0 = Auto-Intensity
    # }

    # # Build command sets for intensities
    # $Commands = $Commands | ForEach-Object { 
    #     $_.PsObject.Copy()
    #     ForEach ($Intensity in $Intensities.($_.Algorithm[1])) { 
    #         $_ | Add-Member Intensity ([Uint16]$Intensity) -Force
    #         $_.PsObject.Copy()
    #     }
    # }

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object { 

                If ($_.Algorithm[0] -eq "Ethash" -and $Pools.($_.Algorithm[0]).Name -match "^MPH*") { Return } #temp fix
                # If ($_.Algorithm[0] -eq "Ethash" -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^GTX1660SUPER\d+GB$')) { Return } #Ethash not supported GTX1660 Super
                If ($_.Algorithm[1] -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$|^GTX1660\d+GB$')) { Return } #Dual mining not supported on Navi or GTX1660

                $Command = $_.Command
                $MinMemGB = $_.MinMemGB

                #Add 512 MB when GPU with connected monitor
                If ($SelectedDevices | Where-Object { $_.CIM.CurrentRefreshRate }) { $MinMemGB += 0.5 }

                If ($_.Algorithm[0] -in @("EtcHash", "Ethash")) { 
                    $MinMemGB = ($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) / 1GB
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$Command = Get-CommandPerDevice -Command $Command -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Protocol = $_.Protocol[0]
                    If ($_.Algorithm[0] -eq "Ethash" -and $Pools.($_.Algorithm[0]).Name -like "NiceHash*") { $Protocol = $Protocol -replace "ethproxy", "ethstratum" }
                    If ($Pools.($_.Algorithm[0]).SSL) { $Protocol = "$($Protocol)+ssl" }

                    $Command += "$($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm[0]).User)):$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm[0]).Pass))@$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)"

                    If ($_.Algorithm[1]) { 
                        $Protocol2 = $_.Protocol[1]
                        If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { $Protocol2 = "$($Protocol2)+ssl" }
                        $Command += "$($Protocol2)://$([System.Web.HttpUtility]::UrlEncode($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User)):$([System.Web.HttpUtility]::UrlEncode($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass))@$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port)"
                        If ($_.Intensity) { $Command += " -dual-subsolver -1 -dual-intensity $($_.Intensity)" }
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
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
