. .\Include.ps1

$Path = ".\Bin\NVIDIA-DelosMiner\ccminer.exe"
$Uri = "http://nemos.dx.am/opt/nemos/DelosMiner1.3.0-x86-cuda91.7z"

$Commands = [PSCustomObject]@{
    #"polytimos" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Polytimos
    "hsr" = " -d $SelGPUCC -r 0" #Hsr
    "phi" = " -d $SelGPUCC -r 0" #Phi
    "bitcore" = " -r 0 -d $SelGPUCC" #Bitcore
    #"jha" = " -r 0 -d $SelGPUCC" #Jha
    #"blake2s" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Blake2s
    #"blakecoin" = " -d $SelGPUCC" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = " -i 10 -d $SelGPUCC" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Groestl
    "hmq1725" = " -r 0 -d $SelGPUCC" #hmq1725
    #"keccakc" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Keccakc
    #"lbry" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Lbry
    "lyra2v2" = " -d $SelGPUCC -r 0" #Lyra2RE2
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
    "skein" = " -d $SelGPUCC -r 0" #Skein
    "skunk" = " -d $SelGPUCC -r 0" #Skunk
    #"timetravel" = " -r 0 -d $SelGPUCC" #Timetravel
    "tribus" = " -r 0 -d $SelGPUCC" #Tribus
    "c11" = " -d $SelGPUCC -r 0" #C11
    #"veltor" = "" #Veltor
    #"x11evo" = " -d $SelGPUCC" #X11evo
    "x17" = " -d $SelGPUCC -r 0" #X17
    "x16r" = " -d $SelGPUCC -r 0" #X16r
    "x16s" = " -d $SelGPUCC -r 0" #X16s
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.MinerAPITCPPort) -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API = "Ccminer"
        Port = $Variables.MinerAPITCPPort
        Wrap = $false
        URI = $Uri
		User = $Pools.(Get-Algorithm($_)).User
    }
}
