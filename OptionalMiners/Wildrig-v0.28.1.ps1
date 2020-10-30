using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\wildrig.exe"
$Uri = "https://github.com/andru-kun/wildrig-multi/releases/download/0.28.1/wildrig-multi-windows-0.28.1.7z"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstralHash";  Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-astralhash" }
    [PSCustomObject]@{ Algorithm = "BCD";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo bcd" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc"; Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";  Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo blake2b-glt" }
#   [PSCustomObject]@{ Algorithm = "Bmw512";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo bmw512" } #CcminerBmw512-v2.2.5 is fastest
    [PSCustomObject]@{ Algorithm = "Bitcore";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo c11" }
#   [PSCustomObject]@{ Algorithm = "Dedal";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo dedal" } # CryptoDredge-v0.25.1 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo exosis" } 
    [PSCustomObject]@{ Algorithm = "Geek";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";  Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-globalhash" }
    [PSCustomObject]@{ Algorithm = "Hex";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo hex" }
    [PSCustomObject]@{ Algorithm = "Hmq1725";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo hmq1725" } #CryptoDredge-v0.25.1 is fastest
#   [PSCustomObject]@{ Algorithm = "Honeycomb";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo honeycomb" } #Algo broken
    [PSCustomObject]@{ Algorithm = "JeongHash";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-jeonghash" }
    [PSCustomObject]@{ Algorithm = "KawPoW";      Type = "AMD"; Fee = @(0.01); MinMemGB = 3; Command = " --algo kawpow" } #TeamRed-v0.7.16b is fastest on Navi
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";    Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo lyra2v3" } #TeamRed-v0.7.16b is fastest
    [PSCustomObject]@{ Algorithm = "MegaBtx";     Type = "AMD"; Fee = @(0.01); MinMemGB = 1; Command = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MegaMec";     Type = "AMD"; Fee = @(0.01); MinMemGB = 1; Command = " --algo megamec" }
    [PSCustomObject]@{ Algorithm = "Minotaur";    Type = "AMD"; Fee = @(0.01); MinMemGB = 1; Command = " --algo minotaur" }
#   [PSCustomObject]@{ Algorithm = "MTP";         Type = "AMD"; Fee = @(0.01); MinMemGB = 3; Command = " --algo mtp" } #TeamRed-v0.7.16b is fastest
    [PSCustomObject]@{ Algorithm = "MTPTrc";      Type = "AMD"; Fee = @(0.01); MinMemGB = 3; Command = " --algo mtp-trc" }
    [PSCustomObject]@{ Algorithm = "PadiHash";    Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-pawelhash" }
    [PSCustomObject]@{ Algorithm = "Phi";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Polytimos";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "Sha256csm";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo sha256csm" }
    [PSCustomObject]@{ Algorithm = "Sha256t";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo sha256t" }
    [PSCustomObject]@{ Algorithm = "Sha256q";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "Renesis";     Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo renesis" }
    [PSCustomObject]@{ Algorithm = "Skein2";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo skein2" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";   Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo skunkhash" }
    [PSCustomObject]@{ Algorithm = "Sonoa";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo sonoa" }
    [PSCustomObject]@{ Algorithm = "Timetravel";  Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "Tribus";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo tribus" }
    [PSCustomObject]@{ Algorithm = "X11k";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x11k" }
#   [PSCustomObject]@{ Algorithm = "X16r";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x16r" } #TeamRed-v0.7.16b is fastest
    [PSCustomObject]@{ Algorithm = "X16rt";       Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x16rt" }
#   [PSCustomObject]@{ Algorithm = "X16rv2";      Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x16rv2" } #TeamRed-v0.7.16b is fastest
    [PSCustomObject]@{ Algorithm = "X16s";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x16s" }
    [PSCustomObject]@{ Algorithm = "X17";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X17r";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x17r --protocol ufo2" }
#   [PSCustomObject]@{ Algorithm = "X21s";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x21s" } #TeamRed-v0.7.16b is fastest
    [PSCustomObject]@{ Algorithm = "X22i";        Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x22i" }
    [PSCustomObject]@{ Algorithm = "X33";         Type = "AMD"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x33" }

    [PSCustomObject]@{ Algorithm = "AstralHash";  Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-astralhash" }
    [PSCustomObject]@{ Algorithm = "BCD";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo bcd" }
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc"; Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";  Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo blake2b-glt" }
#   [PSCustomObject]@{ Algorithm = "Bmw512";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo bmw512" } #CcminerBmw512-v2.2.5 is fastest
    [PSCustomObject]@{ Algorithm = "Bitcore";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo c11" }
#   [PSCustomObject]@{ Algorithm = "Dedal";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo dedal" } #CryptoDredge-v0.25.1 is fastest
    [PSCustomObject]@{ Algorithm = "Exosis";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo exosis" }
    [PSCustomObject]@{ Algorithm = "Geek";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "GlobalHash";  Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-globalhash" }
    [PSCustomObject]@{ Algorithm = "Hex";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo hex" }
#   [PSCustomObject]@{ Algorithm = "Hmq1725";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo hmq1725" } #CryptoDredge-v0.25.1 is fastest
#   [PSCustomObject]@{ Algorithm = "Honeycomb";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo honeycomb" } #Algo broken
    [PSCustomObject]@{ Algorithm = "JeongHash";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-jeonghash" } #Trex-v0.18.5 is fastest
#   [PSCustomObject]@{ Algorithm = "KawPoW";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3; Command = " --algo kawpow" } #NBMiner-v32.1 is fastest
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";    Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo lyra2v3" } #CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "MegaBtx";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 1; Command = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MegaMec";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 1; Command = " --algo megamec" }
    [PSCustomObject]@{ Algorithm = "Minotaur";    Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 1; Command = " --algo minotaur" }
#   [PSCustomObject]@{ Algorithm = "MTP";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3; Command = " --algo mtp" } #Trex-v0.18.5 is fastest
    [PSCustomObject]@{ Algorithm = "MTPTrc";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 3; Command = " --algo mtp-trc" }
    [PSCustomObject]@{ Algorithm = "PadiHash";    Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo glt-pawelhash" } #Trex-v0.18.5 is fastest
    [PSCustomObject]@{ Algorithm = "Phi";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Polytimos";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "Sha256csm";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo sha256csm" }
    [PSCustomObject]@{ Algorithm = "Sha256t";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo sha256t" }
    [PSCustomObject]@{ Algorithm = "Sha256q";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "Renesis";     Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo renesis" }
#   [PSCustomObject]@{ Algorithm = "Skein2";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo skein2" } #CcminerAlexis78-v1.5.2 is fastest
#   [PSCustomObject]@{ Algorithm = "SkunkHash";   Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo skunkhash" } #CryptoDredge-v0.25.1 is fastest
#   [PSCustomObject]@{ Algorithm = "Sonoa";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo sonoa" } #Trex-v0.18.5 is fastest
    [PSCustomObject]@{ Algorithm = "Timetravel";  Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "Tribus";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo tribus" }
    [PSCustomObject]@{ Algorithm = "X11k";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x11k" }
#   [PSCustomObject]@{ Algorithm = "X16r";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x16r" } #Trex-v0.18.5 is fastest
    [PSCustomObject]@{ Algorithm = "X16rt";       Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x16rt" }
#   [PSCustomObject]@{ Algorithm = "X16rv2";      Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x16rv2" } #Trex-v0.18.5 is fastest
#   [PSCustomObject]@{ Algorithm = "X16s";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x16s" } #Trex-v0.18.5 is fastest
#   [PSCustomObject]@{ Algorithm = "X17";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X17r";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x17r --protocol ufo2" }
#   [PSCustomObject]@{ Algorithm = "X21s";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x21s" } #Trex-v0.18.5 is fastest
#   [PSCustomObject]@{ Algorithm = "X22i";        Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x22i" } #Trex-v0.18.5 is fastest
    [PSCustomObject]@{ Algorithm = "X33";         Type = "NVIDIA"; Fee = @(0.01); MinMemGB = 2; Command = " --algo x33" }
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
