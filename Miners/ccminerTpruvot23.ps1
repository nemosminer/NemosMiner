. .\Include.ps1

$Path = ".\Bin\NVIDIA-TPruvot23\ccminer-x64.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.3-tpruvot/ccminer-2.3-cuda9.7z"

$Commands = [PSCustomObject]@{
    #"polytimos" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Polytimos
    "hsr" = " -d $SelGPUCC" #Hsr
    "allium" = " -N 1 -i 22.125 -d $SelGPUCC" #Allium
    #"bitcore" = " -r 0 -d $SelGPUCC" #Bitcore(spmodbitcore faster)
    #"jha" = " -r 0 -d $SelGPUCC" #Jha
    #"blake2s" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Blake2s
    #"x13" = " -d $SelGPUCC -r 0 -i 20 -N 1" #X13
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = " -i 10 -d $SelGPUCC" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Groestl
    #"graft" = " -d $SelGPUCC"
    "keccak" = " -i 29 -d $SelGPUCC" #Keccakc
    "keccakc" = " -i 29 -d $SelGPUCC" #Keccakc
    #"lbry" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Lbry
    #"lyra2v2" = " -N 1 -d $SelGPUCC --api-remote --api-allow=0/0" #Lyra2RE2
    "lyra2z" = "  -N 1 -d $SelGPUCC -i 20.50" #Lyra2z
    #"monero" = " -d $SelGPUCC"
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = " -d $SelGPUCC" #NeoScrypt
    #"nist5" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Nist5
    #"pascal" = "" #Pascal
    "phi" = " -d $SelGPUCC" #Phi (testing)
    "phi2" = " -N 1 -d $SelGPUCC" #Phi (testing)
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    "sha256t" = " -i 29 -r 0 -d $SelGPUCC" #Sha256t
    #"sia" = "" #Sia
    #"sib" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Sib
    #"skein" = "" #Skein
    #"skunk" = " -d $SelGPUCC" #Skunk
    #"sonoa"	= " -d $SelGPUCC"
    #"stellite" = " -d $SelGPUCC"
    #"timetravel" = " -r 0 -d $SelGPUCC" #Timetravel
    #"tribus" = " -r 0 -d $SelGPUCC" #Tribus
    #"c11" = " -d $SelGPUCC --api-remote --api-allow=0/0" #C11
    #"veltor" = "" #Veltor
    #"x11evo" = " -d $SelGPUCC" #X11evo (Alexis78 faster)
    #"x17" = " -N 1 -d $SelGPUCC" #X17(Enemy1.03 faster)
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.MinerAPITCPPort) -R 1 -q -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "Ccminer"
        Port = $Variables.MinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
