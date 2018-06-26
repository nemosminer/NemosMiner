. .\Include.ps1

$Path = ".\Bin\NVIDIA-Alexis78\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerAlexis78/releases/download/Alexis78-v1.2/ccminerAlexis78v1.2x32.7z"

$Commands = [PSCustomObject]@{
    "hsr" = " -N 1 -d $SelGPUCC" #Hsr(fastest)
    "poly" = " -N 1 -d $SelGPUCC" #polytimos(fastest)
    #"bitcore" = "" #Bitcore
    #"blake2s" = " -r 0 -d $SelGPUCC" #Blake2s(fastest)
    "x13" = " -d $SelGPUCC -i 20 -N 1" #X13
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = "" #Cryptonight
    "veltor" = " -i 23 -d $SelGPUCC" #Veltor(fastest)
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = "" #Groestl
    #"hmq1725" = "" #hmq1725
    "keccak" = " -N 1 -m 2 -i 29 -d $SelGPUCC" #Keccak(fastest)
    "keccakc" = " -N 1 -i 29 -d $SelGPUCC" #Keccakc(fastest)
    "lbry" = " -d $SelGPUCC" #Lbry
    "lyra2v2" = " -d $SelGPUCC -N 1" #Lyra2RE2(fastest) 
    #"lyra2z" = "" #Lyra2z
    "myr-gr" = " -d $SelGPUCC -N 1" #MyriadGroestl
    #"neoscrypt" = " -i 15 -d $SelGPUCC" #NeoScrypt
    #"nist5" = " -r 0 -d $SelGPUCC" #Nist5(fastest)
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    #"sib" = " -i 21 -d $SelGPUCC" #Sib(fastest)
    "skein" = " -N 1 -d $SelGPUCC" #Skein(fastest)
    #"timetravel" = "" #Timetravel
    "c11" = " -N 1 -i 21 -d $SelGPUCC" #C11(fastest)
    "x11evo" = " -N 1 -i 21 -d $SelGPUCC " #X11evo(fastest)
    #"x11gost" = " -i 21 -d $SelGPUCC --api-remote" #X11gost
    "x17" = " -N 1 -i 20 -d $SelGPUCC" #X17(fastest)
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
        Port = $Variables.MinerAPITCPPort #4068
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
