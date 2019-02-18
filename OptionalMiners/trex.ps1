if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-trex092\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.9.2/t-rex-0.9.2-win-cuda10.0.zip"

$Commands = [PSCustomObject]@{
    "balloon"    = " -a balloon -i 23" #Balloon(fastest)
    "astralhash" = " -a astralhash -i 23" #Astralhash
    "jeonghash"  = " -a jeonghash -i 23" #Jeonghash
    "padihash"   = " -a padihash -i 23" #Padihash
    "pawelhash"  = " -a pawelhash -i 23" #Pawelhash
    "polytimos"  = " -a polytimos -i 25" #Poly (fastest) 
    "bcd"        = " -a bcd -i 24" #Bcd (fastest)
    #"skunk"     = "" #Skunk (CryptoDredge faster)
    "bitcore"    = " -a bitcore -i 25" #Bitcore( fastest)
    "geek"       = " -a geek -i 23" #Geekcash
    #"lyra2z"    = "" #Lyra2z (Asic)
    #"tribus"    = "" #Tribus (not profitable atm)
    "c11"        = " -a c11 -i 24" #C11 (fastest)
    "x17"        = " -a x17 -i 24" #X17 (fastest)
    "x16s"       = " -a x16s -i 24" #X16s (fastest)
    "x16r"       = " -a x16r -i 24" #X16r (fastest)
    "x16rt"      = " -a x16rt -i 24" #X16rt (fastest)
    "sonoa"      = " -a sonoa -i 23" #Sonoa (fastest)
    #"hmq1725"   = " -i 23" #Hmq1725 (CryptoDredge faster)
    "dedal"      = " -a dedal -i 23" #Dedal (fastest)
    "sha256t"    = " -a sha256t -i 26" #Sha256t (fastest)
    "sha256q"    = " -a sha256q -i 23" #Sha256q (testing)
    "x21s"       = " -a x21s -i 23 " #X21s (fastest)
    "x22i"       = " -a x22i -i 23" #X22i (fastest)
    "timetravel" = " -a timetravel-i 25" #Timetravel (fastest)
    #"veil"      = " -a x16rt -i 24" #Veil  (re testing)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--no-nvml -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_) --quiet -r 10 --cpu-priority 5"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99} # substract 1% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
