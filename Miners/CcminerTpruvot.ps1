. .\Include.ps1

$Path = ".\Bin\NVIDIA-TPruvot\ccminer-x64.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/v2.2-tpruvot/ccminer-x64-2.2.7z"

$Commands = [PSCustomObject]@{
    "bitcore" = " -d $SelGPUCC" #Bitcore
    "jha" = " -d $SelGPUCC" #Jha
    "blake2s" = " -d $SelGPUCC" #Blake2s
    "blakecoin" = " -d $SelGPUCC" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = "" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = "" #Groestl
    "hmq1725" = " -d $SelGPUCC" #hmq1725
    #"keccak" = "" #Keccak
    "lbry" = " -d $SelGPUCC" #Lbry
    #"lyra2v2" = "" #Lyra2RE2
    #"lyra2z" = "" #Lyra2z
    #"myr-gr" = "" #MyriadGroestl
    "neoscrypt" = " -d $SelGPUCC" #NeoScrypt
    #"nist5" = "" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    #"sib" = "" #Sib
    #"skein" = "" #Skein
    "skunk" = " -i 26 -d $SelGPUCC" #Skunk
    "timetravel" = " -d $SelGPUCC" #Timetravel
    "tribus" = " -d $SelGPUCC" #Tribus
    #"x11" = "" #X11
    #"veltor" = "" #Veltor
    "x11evo" = " -d $SelGPUCC" #X11evo
    "x17" = " -d $SelGPUCC" #X17
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $Wallet -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        Wrap = $false
        URI = $Uri
    }
}
