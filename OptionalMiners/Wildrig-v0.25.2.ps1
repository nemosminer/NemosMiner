using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\wildrig.exe"
$Uri = "https://github.com/andru-kun/wildrig-multi/releases/download/0.25.2/wildrig-multi-windows-0.25.2.7z"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "AstralHash";   Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo glt-astralhash" } #Profit very small
#   [PSCustomObject]@{ Algorithm = "BCD";          Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo bcd" } #Profit close to 0
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc";  Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";   Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo blake2b-glt" }
    [PSCustomObject]@{ Algorithm = "Bmw512";       Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo bmw512" }
    [PSCustomObject]@{ Algorithm = "Bitcore";      Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";          Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo c11" }
    [PSCustomObject]@{ Algorithm = "Dedal";        Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo dedal" }
    [PSCustomObject]@{ Algorithm = "Exosis";       Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo exosis" }
    [PSCustomObject]@{ Algorithm = "Geek";         Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "Hex";          Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo hex" }
    [PSCustomObject]@{ Algorithm = "Hmq1725";      Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo hmq1725" }
#   [PSCustomObject]@{ Algorithm = "Honeycomb";   Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo honeycomb" } #Algo broken
    [PSCustomObject]@{ Algorithm = "JeongHash";    Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo glt-jeonghash" }
    [PSCustomObject]@{ Algorithm = "KawPoW";       Fee = @(0.01); MinMemGB = 3; Type = "AMD";    Command = " --algo kawpow" }
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";     Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo lyra2v3" }
    [PSCustomObject]@{ Algorithm = "MTP";          Fee = @(0.01); MinMemGB = 3; Type = "AMD";    Command = " --algo mtp" }
    [PSCustomObject]@{ Algorithm = "MTPTrc";       Fee = @(0.01); MinMemGB = 3; Type = "AMD";    Command = " --algo mtp-trc" }
    [PSCustomObject]@{ Algorithm = "PadiHash";     Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";    Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo glt-pawelhash" }
    [PSCustomObject]@{ Algorithm = "Phi";          Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Polytimos";    Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "Sha256t";      Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo sha256t" }
    [PSCustomObject]@{ Algorithm = "Sha256q";      Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "Renesis";      Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo renesis" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";    Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo skunkhash" }
    [PSCustomObject]@{ Algorithm = "Sonoa";        Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo sonoa" }
    [PSCustomObject]@{ Algorithm = "Timetravel";   Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "Skein2";       Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo skein2" }
    [PSCustomObject]@{ Algorithm = "Tribus";       Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo tribus" }
    [PSCustomObject]@{ Algorithm = "X16r";         Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo x16r" }
#   [PSCustomObject]@{ Algorithm = "X16rt";        Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo x16rt" } #Profit very small
    [PSCustomObject]@{ Algorithm = "X16rv2";       Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo x16rv2" }
    [PSCustomObject]@{ Algorithm = "X16s";         Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo x16s" }
    [PSCustomObject]@{ Algorithm = "X17";          Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X21s";         Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo x21s" }
    [PSCustomObject]@{ Algorithm = "X22i";         Fee = @(0.01); MinMemGB = 2; Type = "AMD";    Command = " --algo x22i" }
#   [PSCustomObject]@{ Algorithm = "AstralHash";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo glt-astralhash" } #Profit very small
#   [PSCustomObject]@{ Algorithm = "BCD";          Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo bcd" } #Profit close to 0
    [PSCustomObject]@{ Algorithm = "Blake2bBtcc";  Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo blake2b-btcc" }
    [PSCustomObject]@{ Algorithm = "Blake2bGlt";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo blake2b-glt" }
    [PSCustomObject]@{ Algorithm = "Bmw512";       Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo bmw512" }
    [PSCustomObject]@{ Algorithm = "Bitcore";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo bitcore" }
    [PSCustomObject]@{ Algorithm = "C11";          Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo c11" }
    [PSCustomObject]@{ Algorithm = "Dedal";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo dedal" }
    [PSCustomObject]@{ Algorithm = "Exosis";       Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo exosis" }
    [PSCustomObject]@{ Algorithm = "Geek";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo geek" }
    [PSCustomObject]@{ Algorithm = "Hex";          Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo hex" }
    [PSCustomObject]@{ Algorithm = "Hmq1725";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo hmq1725" }
#   [PSCustomObject]@{ Algorithm = "Honeycomb";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo honeycomb" } #Algo broken
    [PSCustomObject]@{ Algorithm = "JeongHash";    Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo glt-jeonghash" }
    [PSCustomObject]@{ Algorithm = "KawPoW";       Fee = @(0.01); MinMemGB = 3; Type = "NVIDIA"; Command = " --algo kawpow" }
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";     Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo lyra2v3" }
    [PSCustomObject]@{ Algorithm = "MTP";          Fee = @(0.01); MinMemGB = 3; Type = "NVIDIA"; Command = " --algo mtp" }
    [PSCustomObject]@{ Algorithm = "MTPTrc";       Fee = @(0.01); MinMemGB = 3; Type = "NVIDIA"; Command = " --algo mtp-trc" }
    [PSCustomObject]@{ Algorithm = "PadiHash";     Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo glt-padihash" }
    [PSCustomObject]@{ Algorithm = "PawelHash";    Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo glt-pawelhash" }
    [PSCustomObject]@{ Algorithm = "Phi";          Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo phi" }
    [PSCustomObject]@{ Algorithm = "Polytimos";    Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo polytimos" }
    [PSCustomObject]@{ Algorithm = "Sha256t";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo sha256t" }
    [PSCustomObject]@{ Algorithm = "Sha256q";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo sha256q" }
    [PSCustomObject]@{ Algorithm = "Renesis";      Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo renesis" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";    Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo skunkhash" }
    [PSCustomObject]@{ Algorithm = "Sonoa";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo sonoa" }
    [PSCustomObject]@{ Algorithm = "Timetravel";   Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo timetravel" }
    [PSCustomObject]@{ Algorithm = "Skein2";       Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo skein2" }
    [PSCustomObject]@{ Algorithm = "Tribus";       Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo tribus" }
    [PSCustomObject]@{ Algorithm = "X16r";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x16r" }
#   [PSCustomObject]@{ Algorithm = "X16rt";        Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x16rt" } #Profit very small
    [PSCustomObject]@{ Algorithm = "X16rv2";       Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x16rv2" }
    [PSCustomObject]@{ Algorithm = "X16s";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x16s" }
    [PSCustomObject]@{ Algorithm = "X17";          Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x17" }
    [PSCustomObject]@{ Algorithm = "X21s";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x21s" }
    [PSCustomObject]@{ Algorithm = "X22i";         Fee = @(0.01); MinMemGB = 2; Type = "NVIDIA"; Command = " --algo x22i" }
)

$Devices | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object Type -eq $_.Type | Where-Object { $Pools.($_.Algorithm).Host } | ForEach-Object {
            $MinMemGB = $_.MinMemGB
            If ($Miner_Devices = @($SelectedDevices | Where-Object { ([math]::Round((10 * $_.Memory / 1GB), 0) / 10) -ge $MinMemGB })) {
                $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                [PSCustomObject]@{
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Path       = $Path
                    Arguments  = ("$($_.Command) --api-port=$($MinerAPIPort) --url=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --multiple-instance --opencl-threads auto --opencl-launch auto --opencl-platforms=$($Miner_Devices.PlatformId | Sort-Object -Unique) --opencl-devices=$(($Miner_Devices | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
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
