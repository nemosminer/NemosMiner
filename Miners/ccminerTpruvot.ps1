if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-Tpruvotv2.3cuda10\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerTpruvot/releases/download/v2.3-cuda10/ccminertpruvotx32.7z"

$Commands = [PSCustomObject]@{
    #"polytimos"  = " -d $($Config.SelGPUCC)" #Polytimos
    #"hsr" = " -d $($Config.SelGPUCC)" #Hsr
    "phi"        = " -d $($Config.SelGPUCC)" #Phi (testing)
    #"phi2"       = " -d $($Config.SelGPUCC)" #Phi2 (testing)
    "allium"     = " -d $($Config.SelGPUCC)" #Allium
    "bitcore"    = " -d $($Config.SelGPUCC)" #Bitcore(spmodbitcore faster)
    #"jha"        = " -d $($Config.SelGPUCC)" #Jha
    #"blake2s" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Blake2s
    #"x13" = " -d $($Config.SelGPUCC) -r 0 -i 20 -N 1" #X13
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = " -i 10 -d $($Config.SelGPUCC)" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl"    = " -d $($Config.SelGPUCC)" #Groestl
    "hmq1725"    = " -d $($Config.SelGPUCC)" #hmq1725
    #"keccakc"    = " -d $($Config.SelGPUCC) -i 29" #Keccakc
    #"keccak"     = " -d $($Config.SelGPUCC) -i 29" #Keccak
    #"lyra2v2"    = " -d $($Config.SelGPUCC)" #Lyra2RE2
    #"lyra2z"     = " -d $($Config.SelGPUCC) --submit-stale" #Lyra2z
    #"myr-gr"     = " -d $($Config.SelGPUCC)" #MyriadGroestl
    #"neoscrypt"  = " -d $($Config.SelGPUCC)" #NeoScrypt
    #"nist5" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    "sha256t"    = " -d $($Config.SelGPUCC) -i 29" #Sha256t
    #"sia" = "" #Sia
    #"sib"        = " -d $($Config.SelGPUCC)" #Sib
    "sonoa"      = " -d $($Config.SelGPUCC)" #Sonoa
    "skunk"      = " -d $($Config.SelGPUCC)" #Skunk
    "timetravel" = " -d $($Config.SelGPUCC)" #Timetravel
    #"tribus"     = " -d $($Config.SelGPUCC)" #Tribus
    #"c11"        = " -d $($Config.SelGPUCC)" #C11
    #"veltor" = "" #Veltor
    #"x11evo"     = " -d $($Config.SelGPUCC)" #X11evo (Alexis78 faster)
    #"x17"        = " -d $($Config.SelGPUCC)" #X17(Enemy1.03 faster)
    #"x16r"       = " -d $($Config.SelGPUCC)" #X16r
    #"x16s"       = " -d $($Config.SelGPUCC)" #X16s
    "exosis"     = " -d $($Config.SelGPUCC)" #Exosis
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 5 -b $($Variables.NVIDIAMinerAPITCPPort) -N 1 -R 1 -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
