. .\Include.ps1

$Path = ".\Bin\NVIDIA-Alexis-1.0\ccminer.exe"
$Uri = "https://github.com/GTANAdam/ccminer-Alexis78-1.0/releases/download/1.0/ccminer-alexis78-vs2013-cuda7.5-32bit.zip"

$Commands = [PSCustomObject]@{
    #"bitcore" = "" #Bitcore
    "blake2s" = " -d $SelGPUCC" #Blake2s
    #"blakecoin" = "" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = "" #Cryptonight
    "decred" = " -d $SelGPUCC" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    "groestl" = " -d $SelGPUCC" #Groestl
    #"hmq1725" = "" #hmq1725
    "keccak" = " -d $SelGPUCC" #Keccak
    "lbry" = "" #Lbry
    "lyra2v2" = " -d $SelGPUCC" #Lyra2RE2
    #"lyra2z" = "" #Lyra2z
    "myr-gr" = " -d $SelGPUCC" #MyriadGroestl
    "neoscrypt" = " -d $SelGPUCC" #NeoScrypt
    "nist5" = " -d $SelGPUCC" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    "sib" = " -d $SelGPUCC" #Sib
    "skein" = " -d $SelGPUCC" #Skein
    "skunk" = " -d $SelGPUCC" #Skunk
    #"timetravel" = "" #Timetravel
    #"x11" = "" #X11
    #"veltor" = "" #Veltor
    #"x11evo" = "" #X11evo
    #"x17" = "" #X17
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        Wrap = $false
        URI = $Uri
    }
}
