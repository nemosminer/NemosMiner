using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.19.3/t-rex-0.19.3-win-cuda10.0.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs 

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstralHash"; Fee = 0.01; MinMemGB = 2; Command = " --algo astralhash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Balloon";    Fee = 0.01; MinMemGB = 2; Command = " --algo balloon --intensity 23" }
    [PSCustomObject]@{ Algorithm = "BCD";        Fee = 0.01; MinMemGB = 2; Command = " --algo bcd --intensity 24" }
    [PSCustomObject]@{ Algorithm = "Bitcore";    Fee = 0.01; MinMemGB = 2; Command = " --algo bitcore --intensity 25" }
    [PSCustomObject]@{ Algorithm = "C11";        Fee = 0.01; MinMemGB = 2; Command = " --algo c11 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "Dedal";      Fee = 0.01; MinMemGB = 2; Command = " --algo dedal --intensity 23" }
   [PSCustomObject]@{ Algorithm = "EtcHash";    Fee = 0.01; MinMemGB = 4; Command = " --algo etchash" } #PhoenixMiner-v5.3b is fastest
   [PSCustomObject]@{ Algorithm = "Ethash";     Fee = 0.01; MinMemGB = 4; Command = " --algo ethash" } #PhoenixMiner-v5.3b is fastest
    [PSCustomObject]@{ Algorithm = "Geek";       Fee = 0.01; MinMemGB = 2; Command = " --algo geek --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Honeycomb";  Fee = 0.01; MinMemGB = 2; Command = " --algo honeycomb --intensity 26" }
    [PSCustomObject]@{ Algorithm = "JeongHash";  Fee = 0.01; MinMemGB = 2; Command = " --algo jeonghash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "KawPoW";     Fee = 0.01; MinMemGB = 3; Command = " --algo kawpow" } #NBMiner-v34.5 is fastest but has optional 1% fee
    [PSCustomObject]@{ Algorithm = "MegaBtx";    Fee = 0.01; MinMemGB = 2; Command = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MTP";        Fee = 0.01; MinMemGB = 2; Command = " --algo mtp --intensity 21" }
   [PSCustomObject]@{ Algorithm = "Octopus";    Fee = 0.02; MinMemGB = 5; Command = " --algo octopus --intensity 25" } #NBMiner-v34.5 is fastest
    [PSCustomObject]@{ Algorithm = "PadiHash";   Fee = 0.01; MinMemGB = 2; Command = " --algo padihash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "PawelHash";  Fee = 0.01; MinMemGB = 2; Command = " --algo pawelhash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Polytimos";  Fee = 0.01; MinMemGB = 2; Command = " --algo polytimos --intensity 25" }
    [PSCustomObject]@{ Algorithm = "ProgPoW";    Fee = 0.01; MinMemGB = 2; Command = " --algo progpow --intensity 21 --mt 2" } #Sero, Zano
    [PSCustomObject]@{ Algorithm = "Sha256t";    Fee = 0.01; MinMemGB = 2; Command = " --algo sha256t --intensity 26" }
    [PSCustomObject]@{ Algorithm = "Sha256q";    Fee = 0.01; MinMemGB = 2; Command = " --algo sha256q --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Sonoa";      Fee = 0.01; MinMemGB = 2; Command = " --algo sonoa --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Tensority";  Fee = 0.03; MinMemGB = 2; Command = " --algo tensority" }
    [PSCustomObject]@{ Algorithm = "Timetravel"; Fee = 0.01; MinMemGB = 2; Command = " --algo timetravel --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Tribus";     Fee = 0.01; MinMemGB = 2; Command = " --algo tribus --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Veil";       Fee = 0.01; MinMemGB = 2; Command = " --algo x16rt --intensity 24" }
    [PSCustomObject]@{ Algorithm = "VeriBlock";  Fee = 0.01; MinMemGB = 2; Command = " --algo progpow-veriblock" }
    [PSCustomObject]@{ Algorithm = "X17";        Fee = 0.01; MinMemGB = 2; Command = " --algo x17 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16s";       Fee = 0.01; MinMemGB = 2; Command = " --algo x16s --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16r";       Fee = 0.01; MinMemGB = 2; Command = " --algo x16r --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16rv2";     Fee = 0.01; MinMemGB = 2; Command = " --algo x16rv2 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16rt";      Fee = 0.01; MinMemGB = 2; Command = " --algo x16rt --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X21s";       Fee = 0.01; MinMemGB = 2; Command = " --algo x21s --intensity 23" }
    [PSCustomObject]@{ Algorithm = "X22i";       Fee = 0.01; MinMemGB = 2; Command = " --algo x22i --intensity 23" }
    [PSCustomObject]@{ Algorithm = "X25x";       Fee = 0.01; MinMemGB = 2; Command = " --algo x25x --intensity 21" }
    [PSCustomObject]@{ Algorithm = "X33";        Fee = 0.01; MinMemGB = 2; Command = " --algo x33" }
    [PSCustomObject]@{ Algorithm = "Zano";       Fee = 0.01; MinMemGB = 2; Command = " --algo progpowz" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | ForEach-Object {

                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -in @("EtcHash", "Ethash")) { 
                    $MinMemGB = ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MPH(|Coins)$") { 
                        $Stratum = "stratum2"
                    }
                    Else {
                        $Stratum = "stratum"
                    }
                    If ($Pools.($_.Algorithm).SSL -eq $true) { $Stratum += "+ssl://" } Else { $Stratum += "+tcp://" }

                    If ($_.Algorithm -eq "ProgPoW") { 
                        If ($Pools.($_.Algorithm).Currency -in @("SERO", "ZANO")) { 
                            $Coin = " --coin $($Pools.($_.Algorithm).Currency)"
                        }
                        Else { 
                            $Coin = ""
                            Return
                        }
                    }

                    #(ethash, kawpow, progpow) Worker name is not being passed for some mining pools
                    #From now on the username (-u) for these algorithms is no longer parsed as <wallet_address>.<worker_name>
                    If ($_.Algorithm -in @("Ethash", "KawPow", "ProgPoW") -and ($Pools.($_.Algorithm).User -split "\.").Count -eq 2) { 
                        $User = " --user $($Pools.($_.Algorithm).User) --worker $($Pools.($_.Algorithm).User -split "\." | Select-Object -Index 1)"
                    }
                    Else { 
                        $User = " --user $($Pools.($_.Algorithm).User)"
                    }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$($_.Command) --url $Stratum$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)$User --pass $($Pools.($_.Algorithm).Pass) --no-strict-ssl$(If ($Variables.IsLocalAdmin -eq $true) { " --mt 3" })$Coin --no-watchdog --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-bind-telnet 0 --api-read-only --gpu-report-interval 5 --quiet --retry-pause 1 --timeout 50000 --cpu-priority 4 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "Trex"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee #Dev fee
                        MinerUri        = "http://localhost:$($MinerAPIPort)/trex"
                        PowerUsageInAPI = $true
                    }
                }
            }
        }
    }
}
