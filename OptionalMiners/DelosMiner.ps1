. .\Include.ps1

$Path = ".\Bin\NVIDIA-DelosMiner\ccminer.exe"
$Uri = "http://nemos.dx.am/opt/nemos/DelosMiner1.3.0-x86-cuda91.7z"

$Commands = [PSCustomObject]@{
    #"polytimos" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Polytimos
    #"hsr" = " -d $SelGPUCC -r 0" #Hsr(Alexis78v1.2 faster)
    "phi" = " -d $SelGPUCC" #Phi(fastest)
    "bitcore" = " -d $SelGPUCC" #Bitcore(fastest)
    #"jha" = " -r 0 -d $SelGPUCC" #Jha
    #"blake2s" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Blake2s
    #"blakecoin" = " -d $SelGPUCC" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = " -i 10 -d $SelGPUCC" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Groestl
    #"hmq1725" = " -r 0 -d $SelGPUCC" #hmq1725(ccminerx16sv0.5 faster)
    #"keccakc" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Keccakc
    #"lbry" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Lbry
    #"lyra2v2" = " -d $SelGPUCC -r 0" #Lyra2RE2(Alexis78v1.2 faster)
    #"lyra2z" = "  -r 0 -d $SelGPUCC --submit-stale" #Lyra2z
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = " -d $SelGPUCC" #NeoScrypt
    #"nist5" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sha256t" = " -r 0 -d $SelGPUCC" #Sha256t
    #"sia" = "" #Sia
    #"sib" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Sib
    #"skein" = " -d $SelGPUCC -r 0" #Skein(Alexi78v1.2 faster)
    "skunk" = " -d $SelGPUCC" #Skunk(fastest)
    #"timetravel" = " -r 0 -d $SelGPUCC" #Timetravel
    #"tribus" = " -r 0 -d $SelGPUCC" #Tribus(close but spmodtribusv2 is slighty faster + no dev fee)
    #"c11" = " -d $SelGPUCC -r 0" #C11(Alexis78v1.2 faster)
    #"veltor" = "" #Veltor
    #"x11evo" = " -d $SelGPUCC" #X11evo
    "x17" = " -d $SelGPUCC" #X17(fastest)
    #"x16r" = " -d $SelGPUCC -r 0" #X16r(ccminerx16r faster)
    "x16s" = " -d $SelGPUCC" #X16s(fastest)
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.MinerAPITCPPort) -R 1 -q --submit-stale -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API = "Ccminer"
        Port = $Variables.MinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
