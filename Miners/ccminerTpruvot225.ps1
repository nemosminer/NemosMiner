if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-Tpruvot225\ccminer.exe"
$Uri = "https://github.com/tpruvot/ccminer/releases/download/2.2.5-tpruvot/ccminer-x86-2.2.5-cuda9.7z"

$Commands = [PSCustomObject]@{
    #"polytimos" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Polytimos
    #"hsr" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Hsr
    #"phi" = " -N 1 -d $($Config.SelGPUCC)" #Phi
    "bitcore" = " -d $($Config.SelGPUCC)" #Bitcore(spmodbitcore faster)
    "jha" = " -d $($Config.SelGPUCC)" #Jha
    #"blake2s" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Blake2s
    #"x13" = " -d $($Config.SelGPUCC) -r 0 -i 20 -N 1" #X13
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
    #"lyra2z" = " -d $($Config.SelGPUCC) --submit-stale -N 1 -i 20.50" #Lyra2z
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = " -d $($Config.SelGPUCC)" #NeoScrypt
    #"nist5" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    "sha256t" = " -d $($Config.SelGPUCC)" #Sha256t
    #"sia" = "" #Sia
    #"sib" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Sib
    #"skein" = "" #Skein
    #"skunk" = " -d $($Config.SelGPUCC)" #Skunk
    "timetravel" = " -d $($Config.SelGPUCC)" #Timetravel
    "tribus" = " -d $($Config.SelGPUCC)" #Tribus
    #"c11" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #C11
    #"veltor" = "" #Veltor
    #"x11evo" = " -d $($Config.SelGPUCC)" #X11evo (Alexis78 faster)
    #"x17" = " -N 1 -d $($Config.SelGPUCC)" #X17(Enemy1.03 faster)
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
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
