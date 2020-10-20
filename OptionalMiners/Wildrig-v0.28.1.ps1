using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\wildrig.exe"
$Uri = "https://github.com/andru-kun/wildrig-multi/releases/download/0.28.1/wildrig-multi-windows-0.28.1.7z"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstralHash";  Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo glt-astralhash" }
    [PSCustomObject]@{ Algorithm = "BCD";         Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo bcd" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc"; Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";  Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo blake2b-glt" }
#   [PSCustomObject]@{ Algorithm = "Bmw512";      Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo bmw512" } #CcminerBmw512-v2.2.5 is fastest
    [PSCustomObject]@{ Algorithm = "Bitcore";     Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";         Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo c11" }
#   [PSCustomObject]@{ Algorithm = "Dedal";       Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo dedal" } # CryptoDredge-v0.25.1 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";      Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo exosis" } 
    [PSCustomObject]@{ Algorithm = "Geek";        Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";  Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo glt-globalhash" }
    [PSCustomObject]@{ Algorithm = "Hex";         Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo hex" }
    [PSCustomObject]@{ Algorithm = "Hmq1725";     Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo hmq1725" } #CryptoDredge-v0.25.1 is fastest
#   [PSCustomObject]@{ Algorithm = "Honeycomb";   Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo honeycomb" } #Algo broken
    [PSCustomObject]@{ Algorithm = "JeongHash";   Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo glt-jeonghash" }
    [PSCustomObject]@{ Algorithm = "KawPoW";      Fee = @(0.01); MinMemGB = 3; Type = "AMD"; Command = " --algo kawpow" } #TeamRed-v0.7.14 is fastest on Navi
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";    Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo lyra2v3" } #TeamRed-v0.7.14 is fastest
    [PSCustomObject]@{ Algorithm = "MegaBtx";     Fee = @(0.01); MinMemGB = 1; Type = "AMD"; Command = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MegaMec";     Fee = @(0.01); MinMemGB = 1; Type = "AMD"; Command = " --algo megamec" }
    [PSCustomObject]@{ Algorithm = "Minotaur";    Fee = @(0.01); MinMemGB = 1; Type = "AMD"; Command = " --algo minotaur" }
#   [PSCustomObject]@{ Algorithm = "MTP";         Fee = @(0.01); MinMemGB = 3; Type = "AMD"; Command = " --algo mtp" } #TeamRed-v0.7.14 is fastest
    [PSCustomObject]@{ Algorithm = "MTPTrc";      Fee = @(0.01); MinMemGB = 3; Type = "AMD"; Command = " --algo mtp-trc" }
    [PSCustomObject]@{ Algorithm = "PadiHash";    Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";   Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo glt-pawelhash" }
    [PSCustomObject]@{ Algorithm = "Phi";         Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Polytimos";   Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "Sha256csm";   Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo sha256csm" }
    [PSCustomObject]@{ Algorithm = "Sha256t";     Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo sha256t" }
    [PSCustomObject]@{ Algorithm = "Sha256q";     Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "Renesis";     Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo renesis" }
    [PSCustomObject]@{ Algorithm = "Skein2";      Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo skein2" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";   Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo skunkhash" }
    [PSCustomObject]@{ Algorithm = "Sonoa";       Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo sonoa" }
    [PSCustomObject]@{ Algorithm = "Timetravel";  Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "Tribus";      Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo tribus" }
    [PSCustomObject]@{ Algorithm = "X11k";        Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x11k" }
#   [PSCustomObject]@{ Algorithm = "X16r";        Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x16r" } #TeamRed-v0.7.14 is fastest
    [PSCustomObject]@{ Algorithm = "X16rt";       Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x16rt" }
#   [PSCustomObject]@{ Algorithm = "X16rv2";      Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x16rv2" } #TeamRed-v0.7.14 is fastest
    [PSCustomObject]@{ Algorithm = "X16s";        Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x16s" }
    [PSCustomObject]@{ Algorithm = "X17";         Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X17r";        Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x17r --protocol ufo2" }
#   [PSCustomObject]@{ Algorithm = "X21s";        Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x21s" } #TeamRed-v0.7.14 is fastest
    [PSCustomObject]@{ Algorithm = "X22i";        Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x22i" }
    [PSCustomObject]@{ Algorithm = "X33";         Fee = @(0.01); MinMemGB = 2; Type = "AMD"; Command = " --algo x33" }

    [PSCustomObject]@{ Algorithm = "AstralHash";  Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo glt-astralhash" }
    [PSCustomObject]@{ Algorithm = "BCD";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo bcd" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc"; Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";  Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo blake2b-glt" }
#   [PSCustomObject]@{ Algorithm = "Bmw512";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo bmw512" } #CcminerBmw512-v2.2.5 is fastest
    [PSCustomObject]@{ Algorithm = "Bitcore";     Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo c11" }
#   [PSCustomObject]@{ Algorithm = "Dedal";       Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo dedal" } #CryptoDredge-v0.25.1 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo exosis" }
    [PSCustomObject]@{ Algorithm = "Geek";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";  Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo glt-globalhash" }
    [PSCustomObject]@{ Algorithm = "Hex";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo hex" }
#   [PSCustomObject]@{ Algorithm = "Hmq1725";     Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo hmq1725" } #CryptoDredge-v0.25.1 is fastest
#   [PSCustomObject]@{ Algorithm = "Honeycomb";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo honeycomb" } #Algo broken
    [PSCustomObject]@{ Algorithm = "JeongHash";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo glt-jeonghash" } #Trex-v0.18.2 is fastest
#   [PSCustomObject]@{ Algorithm = "KawPoW";      Fee = @(0.01); MinMemGB = 3; Type = "NVIDIA"; Command = " --algo kawpow" } #NBMiner-v32.1 is fastest
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";    Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo lyra2v3" } #CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "MegaBtx";     Fee = @(0.01); MinMemGB = 1; Type = "NVIDIA"; Command = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MegaMec";     Fee = @(0.01); MinMemGB = 1; Type = "NVIDIA"; Command = " --algo megamec" }
    [PSCustomObject]@{ Algorithm = "Minotaur";    Fee = @(0.01); MinMemGB = 1; Type = "NVIDIA"; Command = " --algo minotaur" }
#   [PSCustomObject]@{ Algorithm = "MTP";         Fee = @(0.01); MinMemGB = 3; Type = "NVIDIA"; Command = " --algo mtp" } #Trex-v0.18.2 is fastest
    [PSCustomObject]@{ Algorithm = "MTPTrc";      Fee = @(0.01); MinMemGB = 3; Type = "NVIDIA"; Command = " --algo mtp-trc" }
    [PSCustomObject]@{ Algorithm = "PadiHash";    Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo glt-pawelhash" } #Trex-v0.18.2 is fastest
    [PSCustomObject]@{ Algorithm = "Phi";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Polytimos";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "Sha256csm";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo sha256csm" }
    [PSCustomObject]@{ Algorithm = "Sha256t";     Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo sha256t" }
    [PSCustomObject]@{ Algorithm = "Sha256q";     Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "Renesis";     Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo renesis" }
#   [PSCustomObject]@{ Algorithm = "Skein2";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo skein2" } #CcminerAlexis78-v1.5.2 is fastest
#   [PSCustomObject]@{ Algorithm = "SkunkHash";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo skunkhash" } #CryptoDredge-v0.25.1 is fastest
#   [PSCustomObject]@{ Algorithm = "Sonoa";       Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo sonoa" } #Trex-v0.18.2 is fastest
    [PSCustomObject]@{ Algorithm = "Timetravel";  Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "Tribus";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo tribus" }
    [PSCustomObject]@{ Algorithm = "X11k";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x11k" }
#   [PSCustomObject]@{ Algorithm = "X16r";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x16r" } #Trex-v0.18.2 is fastest
    [PSCustomObject]@{ Algorithm = "X16rt";       Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x16rt" }
#   [PSCustomObject]@{ Algorithm = "X16rv2";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x16rv2" } #Trex-v0.18.2 is fastest
#   [PSCustomObject]@{ Algorithm = "X16s";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x16s" } #Trex-v0.18.2 is fastest
#   [PSCustomObject]@{ Algorithm = "X17";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X17r";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x17r --protocol ufo2" }
#   [PSCustomObject]@{ Algorithm = "X21s";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x21s" } #Trex-v0.18.2 is fastest
#   [PSCustomObject]@{ Algorithm = "X22i";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x22i" } #Trex-v0.18.2 is fastest
    [PSCustomObject]@{ Algorithm = "X33";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x33" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) {

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$($_.Command) --api-port=$($MinerAPIPort) --url=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --multiple-instance --opencl-threads auto --opencl-launch auto --opencl-platforms=$($Miner_Devices.PlatformId | Sort-Object -Unique) --opencl-devices=$(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "XmRig"
                        Port       = $MinerAPIPort
                        Wrap       = $false
                        URI        = $Uri
                        Fee        = $_.Fee #subtract devfee
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
