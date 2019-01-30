if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-trex\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.9.1/t-rex-0.9.1-win-cuda10.0.zip"

$Commands = [PSCustomObject]@{
    "balloon"    = "" #Balloon(fastest)
    "astralhash" = "" #Astralhash
    "jeonghash"  = "" #Jeonghash
    "padihash"   = "" #Padihash
    "pawelhash"  = "" #Pawelhash
    "polytimos"  = " -i 25" #Poly (fastest) 
    "bcd"        = " -i 24" #Bcd (fastest)
    #"skunk" = "" #Skunk (CryptoDredge faster)
    "bitcore"    = " -i 25" #Bitcore( fastest)
    "geek"       = "" #Geekcash
    #"lyra2z" = "" #Lyra2z (Asic)
    #"tribus" = "" #Tribus (not profitable atm)
    "c11"        = " -i 24" #C11 (fastest)
    "x17"        = " -i 24" #X17 (fastest)
    "x16s"       = " -i 24" #X16s (fastest)
    "x16r"       = " -i 24" #X16r (fastest)
    "x16rt"      = " -i 24" #X16rt (fastest)
    "sonoa"      = " -i 23" #Sonoa (fastest)
    #"hmq1725" = " -i 23" #Hmq1725 (CryptoDredge faster)
    "dedal"      = "" #Dedal (fastest)
    "sha256t"    = " -i 26" #Sha256t (fastest)
    "sha256q"    = "" #Sha256q (testing)
    "x21s"       = ",d=16 " #X21s (fastest)
    "x22i"       = " -i 23" #X22i (fastest)
    "timetravel" = " -i 25" #Timetravel (fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--no-nvml -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -a $_ -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_) --quiet -r 10 --cpu-priority 5"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99} # substract 1% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
