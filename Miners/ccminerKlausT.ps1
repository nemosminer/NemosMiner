if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-CcminerKlausTv2\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminer-KlausT-8.21-mod-r18-src-fix/releases/download/v2/ccminerKlausT.7z"

$Commands = [PSCustomObject]@{
    "neoscrypt" = " -a neoscrypt -d $($Config.SelGPUCC)" #NeoScrypt
    "yescrypt" = " -a yescrypt -d $($Config.SelGPUCC)" #Yescrypt
    "yescryptR16" = " -i 13.25 -a yescryptr16 -d $($Config.SelGPUCC)" #YescryptR16
    "yescryptR16v2" = " -a yescryptr16v2 -d $($Config.SelGPUCC)" #YescryptR16v2
    "yescryptR24" = " -a yescryptr24 -d $($Config.SelGPUCC)" #YescryptR24 
    "yescryptR8" = " -a yescryptr8 -d $($Config.SelGPUCC)" #YescryptR8
    #"bitcore" = "" #Bitcore
    #"blake2s" = "" #Blake2s
    #"blakecoin" = " -d $($Config.SelGPUCC)" #Blakecoin
    #"c11" = " -d $($Config.SelGPUCC)" #C11
    #"cryptonight" = "" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -r 0 -d $($Config.SelGPUCC)" #Groestl(fastest)
    #"hmq1725" = "" #hmq1725
    #"keccak" = " -d $($Config.SelGPUCC)" #Keccak
    #"lbry" = "" #Lbry
    "lyra2v3" = " -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2v3 -i 24 max
    "lyra2rev3" = " -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2rev3 -i 24 max
    #"lyra2z" = "" #Lyra2z
    #"myr-gr" = " -d $($Config.SelGPUCC)" #MyriadGroestl
    #"nist5" = " -d $($Config.SelGPUCC)" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    #"sib" = "" #Sib
    #"skein" = " -i 28 -d $($Config.SelGPUCC)" #Skein
    #"timetravel" = "" #Timetravel
    #"vanilla" = "" #BlakeVanilla
    #"veltor" = "" #Veltor
    #"x11" = "" #X11
    #"x11evo" = "" #X11evo
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--cpu-priority 4 -b $($Variables.NVIDIAMinerAPITCPPort) -N 1 -R 1 -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API = "ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
