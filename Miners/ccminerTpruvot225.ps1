. .\Include.ps1

$Path = ".\Bin\NVIDIA-TPruvot\ccminer.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.5-tpruvot/ccminer-x86-2.2.5-cuda9.7z"

$Commands = [PSCustomObject]@{
    #"polytimos" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Polytimos
    #"hsr" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Hsr
    "phi" = " -N 1 -d $SelGPUCC" #Phi
    "bitcore" = " -d $SelGPUCC" #Bitcore(spmodbitcore faster)
    "jha" = " -d $SelGPUCC" #Jha
    #"blake2s" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Blake2s
    #"x13" = " -d $SelGPUCC -r 0 -i 20 -N 1" #X13
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = " -i 10 -d $SelGPUCC" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Groestl
    "hmq1725" = " -d $SelGPUCC" #hmq1725
    #"keccakc" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Keccakc
    #"lbry" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Lbry
    #"lyra2v2" = " -N 1 -d $SelGPUCC --api-remote --api-allow=0/0" #Lyra2RE2
    "lyra2z" = " -d $SelGPUCC --submit-stale -N 1 -i 20.50" #Lyra2z
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = " -d $SelGPUCC" #NeoScrypt
    #"nist5" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    "sha256t" = " -d $SelGPUCC" #Sha256t
    #"sia" = "" #Sia
    #"sib" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Sib
    #"skein" = "" #Skein
    #"skunk" = " -d $SelGPUCC" #Skunk
    "timetravel" = " -d $SelGPUCC" #Timetravel
    "tribus" = " -d $SelGPUCC" #Tribus
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
        Arguments = "-b $($Variables.MinerAPITCPPort) -R 1 -q --submit-stale -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "Ccminer"
        Port = $Variables.MinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
