. .\Include.ps1

$Path = ".\Bin\NVIDIA-Alexis78sib\ccminer-alexis.exe"
$Uri = "http://ccminer.org/preview/ccminer-hsr-alexis-x86-cuda8.7z"

$Commands = [PSCustomObject]@{
    #"hsr" = " -d $SelGPUCC --api-remote" #Hsr
    #"bitcore" = "" #Bitcore
    #"blake2s" = " -d $SelGPUCC --api-remote" #Blake2s
    #"blakecoin" = " -d $SelGPUCC --api-remote" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = "" #Cryptonight
    #"veltor" = " -i 23 -d $SelGPUCC --api-remote" #Veltor
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = "" #Groestl
    #"hmq1725" = "" #hmq1725
    #"keccak" = " -m 2 -i 29" #Keccak
    #"lbry" = " -d $SelGPUCC" #Lbry
    #"lyra2v2" = " -d $SelGPUCC --api-remote" #Lyra2RE2
    #"lyra2z" = "" #Lyra2z
    #"myr-gr" = " -d $SelGPUCC --api-remote" #MyriadGroestl
    #"neoscrypt" = " -i 15 -d $SelGPUCC" #NeoScrypt
    #"nist5" = " -d $SelGPUCC --api-remote" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    "x11gost" = " -i 21 -d $SelGPUCC --api-remote" #X11gost
    #"skein" = " -d $SelGPUCC --api-remote" #Skein
    #"timetravel" = "" #Timetravel
    #"c11" = " -i 21 -d $SelGPUCC --api-remote" #C11
    #"x11evo" = "" #X11evo
    #"x17" = " -i 21 -d $SelGPUCC --api-remote" #X17
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a sib -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Live}
        API = "Ccminer"
        Port = 4068
        Wrap = $false
        URI = $Uri
    }
}
