if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-spmodskunkv8\ccminer.exe"
$Uri = "http://nemos.dx.am/opt/nemos/ccminer-skunkhash-sp-mod_v8.7z"

$Commands = [PSCustomObject]@{
    #"polytimos" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Polytimos
    #"hsr" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Hsr
    #"phi" = " -d $($Config.SelGPUCC) -i 20" #Phi
    #"bitcore" = " -d $($Config.SelGPUCC)" #Bitcore
    #"x16r" = " -d $($Config.SelGPUCC) -N 180 -i 20" #X16r
    #"x16s" = " -d $($Config.SelGPUCC) -N 180 -i 20" #X16s
    #"blake2s" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Blake2s
    #"blakecoin" = " -d $($Config.SelGPUCC)" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = " -i 10 -d $($Config.SelGPUCC)" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Groestl
    #"hmq1725" = " -d $($Config.SelGPUCC)" #hmq1725
    #"keccakc" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Keccakc
    #"lbry" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Lbry
    #"lyra2v2" = " -N 1 -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Lyra2RE2
    #"lyra2z" = "  -d $($Config.SelGPUCC) --api-remote --api-allow=0/0 --submit-stale" #Lyra2z
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = " -d $($Config.SelGPUCC)" #NeoScrypt
    #"nist5" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sha256t" = " -d $($Config.SelGPUCC)" #Sha256t
    #"sia" = "" #Sia
    #"sib" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Sib
    #"skein" = "" #Skein
    "skunk" = " -d $($Config.SelGPUCC) -i 24" #Skunk(fastest)
    #"timetravel" = " -d $($Config.SelGPUCC)" #Timetravel
    #"tribus" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Tribus
    #"c11" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #C11
    #"veltor" = "" #Veltor
    #"x11evo" = " -d $($Config.SelGPUCC)" #X11evo
    #"x17" = " -N 1 -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #X17
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "Ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
		User = $Pools.(Get-Algorithm($_)).User
    }
}
