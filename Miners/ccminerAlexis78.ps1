if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-Alexis78\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerAlexis78/releases/download/Alexis78-v1.2/ccminerAlexis78v1.2x32.7z"

$Commands = [PSCustomObject]@{
    "hsr" = " -N 1 -d $($Config.SelGPUCC)" #Hsr(testing)
    "poly" = " -N 1 -d $($Config.SelGPUCC)" #polytimos(trex faster)
    #"bitcore" = "" #Bitcore
    #"blake2s" = " -r 0 -d $($Config.SelGPUCC)" #Blake2s
    #"x13" = " -d $($Config.SelGPUCC) -i 20 -N 1" #X13
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = "" #Cryptonight
    "veltor" = " -i 23 -d $($Config.SelGPUCC)" #Veltor(fastest)
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = "" #Groestl
    #"hmq1725" = "" #hmq1725
    #"keccak" = " -N 1 -m 2 -i 29 -d $($Config.SelGPUCC)" #Keccak
    "keccakc" = " -N 1 -i 29 -d $($Config.SelGPUCC)" #Keccakc
    #"lbry" = " -d $($Config.SelGPUCC)" #Lbry
    "lyra2v2" = " -d $($Config.SelGPUCC) -N 1" #Lyra2RE2(fastest open source/cryptodredge faster) 
    #"lyra2z" = "" #Lyra2z
    "myr-gr" = " -d $($Config.SelGPUCC) -N 1" #MyriadGroestl
    #"neoscrypt" = " -i 15 -d $($Config.SelGPUCC)" #NeoScrypt
    #"nist5" = " -r 0 -d $($Config.SelGPUCC)" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    #"sib" = " -i 21 -d $($Config.SelGPUCC)" #Sib
    "skein" = " -N 1 -d $($Config.SelGPUCC)" #Skein(fastest)
    #"timetravel" = "" #Timetravel
    #"c11" = " -N 1 -i 21 -d $($Config.SelGPUCC)" #C11(spmodgit10 & trex faster)
    "x11evo" = " -N 1 -i 21 -d $($Config.SelGPUCC) " #X11evo(fastest)
    #"x11gost" = " -i 21 -d $($Config.SelGPUCC) --api-remote" #X11gost
    #"x17" = " -N 1 -i 20 -d $($Config.SelGPUCC)" #X17(trex faster)
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -R 1 -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
