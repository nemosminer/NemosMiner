using module ..\Includes\Include.psm1

$Path = ".\Bin\AMD-WildRigMulti0252b\wildrig.exe"
$Uri = "https://github.com/andru-kun/wildrig-multi/releases/download/0.25.2/wildrig-multi-windows-0.25.2.7z"

$Commands = [PSCustomObject]@{
    "bcd"           = " --algo bcd" #BitcoinDiamond
    "bmw512"        = " --algo bmw512" #bmw512
    "bitcore"       = " --algo bitcore" #Bitcore
    "c11"           = " --algo c11" #C11
    "dedal"         = " --algo dedal" #Dedal
    "exosis"        = " --algo exosis" #Exosis
    "geek"          = " --algo geek" #GeekCash
    "hex"           = " --algo hex" #XDNA
    "hmq1725"       = " --algo hmq1725" #Hmq1725
    "blake2b-btcc"  = " --algo blake2b-btcc" #Blake2b-BTCC
    "blake2b-glt"   = " --algo blake2b-glt" #Blake2b-GLT
    "lyra2v3"       = " --algo lyra2v3"
    "phi"           = " --algo phi" #Phi
    "polytimos"     = " --algo polytimos"
    "sha256t"       = " --algo sha256t"
    "sha256q"       = " --algo sha256q"
    "renesis"       = " --algo renesis" #renesis
    "skunkhash"     = " --algo skunkhash" #Skunk
    "sonoa"         = " --algo sonoa" #sonoa
    "timetravel"    = " --algo timetravel" #timetravel
    "skein2"        = " --algo skein2" #Skein2
    "tribus"        = " --algo tribus" #Tribus
    "x16r"          = " --algo x16r" #x16r
    "x16rt"         = " --algo x16rt"
    "x16s"          = " --algo x16s" #x16s
    "x17"           = " --algo x17" #x17
    "x21s"          = " --algo x21s" #x21s
    "x22i"          = " --algo x22i" #x22i
    "pawelhash"     = " --algo glt-pawelhash" #powelhash
    "jeonghash"     = " --algo glt-jeonghash" #Jeonghash
    "astralhash"    = " --algo glt-astralhash" #Astralhash
    "padihash"      = " --algo glt-padihash" #Padihash
    #"honeycomb"     = " --algo honeycomb" #Honeycomb 
    "x16rv2"        = " --algo x16rv2" #X16rv2
    "mtp"           = " --algo mtp" #Mtp
    "mtp-trc"       = " --algo mtp-trc" #Mtp-trc
    "kawpow"        = " --algo kawpow" #KawPow
    #"progpow"       = " --algo progpow" #ProPOW?
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{
        Type      = "AMD"
        Path      = $Path
        Arguments = "--api-port=$($Variables.AMDMinerAPITCPPort) --url=$($Pools.$Algo.Host):$($Pools.$Algo.Port) --multiple-instance --opencl-platforms=amd  --opencl-threads auto --opencl-launch auto --user=$($Pools.$Algo.User) --pass=$($Pools.$Algo.Pass)$($Commands.$_)"
        Algorithm = $Algo
        API       = "Xmrig"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
        Fee       = 0.01 #substract 1% devfee
    }
}
