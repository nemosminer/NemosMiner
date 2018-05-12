. .\Include.ps1

$Path = ".\Bin\NVIDIA-enemyz1.09\z-enemy.exe"
$Uri = "http://nemos.dx.am/opt/nemos/z-enemy.109a-release.7z"

$Commands = [PSCustomObject]@{
    #"polytimos" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Polytimos
    #"hsr" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Hsr
    "phi" = " -d $SelGPUCC -i 20" #Phi(sp-mod faster)
    "bitcore" = " -d $SelGPUCC -i 20" #Bitcore(sp-mod faster)
    "x16r" = " -d $SelGPUCC -i 20" #X16r(sp-hash faster/very close)
    "x16s" = " -d $SelGPUCC -i 20" #X16s(fastest)
    "xevan" = " -d $SelGPUCC -i 20" #Xevan(Alexis/krnlx faster)
    #"blake2s" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Blake2s
    #"blakecoin" = " -d $SelGPUCC" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = " -i 10 -d $SelGPUCC" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Groestl
    #"hmq1725" = " -d $SelGPUCC" #hmq1725
    #"keccakc" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Keccakc
    #"lbry" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Lbry
    #"lyra2v2" = " -N 1 -d $SelGPUCC --api-remote --api-allow=0/0" #Lyra2RE2
    #"lyra2z" = "  -d $SelGPUCC --api-remote --api-allow=0/0 --submit-stale" #Lyra2z
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = " -d $SelGPUCC" #NeoScrypt
    #"nist5" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sha256t" = " -d $SelGPUCC" #Sha256t
    #"sia" = "" #Sia
    #"sib" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Sib
    #"skein" = "" #Skein
    #"skunk" = " -d $SelGPUCC" #Skunk
    #"timetravel" = " -d $SelGPUCC" #Timetravel
    #"tribus" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Tribus
    #"c11" = " -d $SelGPUCC --api-remote --api-allow=0/0" #C11
    #"veltor" = "" #Veltor
    #"x11evo" = " -d $SelGPUCC" #X11evo
    "x17" = " -i 20 -d $SelGPUCC" #X17(Alexis78 and enemy 1.03 faster)
    "vitalium" = " -d $SelGPUCC" #Vitalium
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.MinerAPITCPPort) -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .99} # substract 1% devfee
        API = "Ccminer"
        Port = $Variables.MinerAPITCPPort
        Wrap = $false
        URI = $Uri
		User = $Pools.(Get-Algorithm($_)).User
    }
}
