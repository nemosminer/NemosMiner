if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-CcminerKlaustcuda10\ccminer.exe"
$Uri = "https://github.com/KlausT/ccminer/releases/download/8.23/ccminer-823-cuda10-x64.zip"

$Commands = [PSCustomObject]@{
    #"bitcore" = "" #Bitcore
    #"blake2s" = "" #Blake2s
    #"blakecoin" = " -d $($Config.SelGPUCC)" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = "" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -r 0 -d $($Config.SelGPUCC)" #Groestl(fastest)
    #"hmq1725" = "" #hmq1725
    #"keccak" = " -d $($Config.SelGPUCC)" #Keccak
    #"lbry" = "" #Lbry
    "lyra2v2" = " -d $($Config.SelGPUCC)" #Lyra2RE2
    #"lyra2z" = "" #Lyra2z
    #"myr-gr" = " -d $($Config.SelGPUCC)" #MyriadGroestl
    #"nist5" = " -d $($Config.SelGPUCC)" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    #"sib" = "" #Sib
    "skein" = " -d $($Config.SelGPUCC)" #Skein
    #"timetravel" = "" #Timetravel
    #"x11" = "" #X11
    #"veltor" = "" #Veltor
    #"x11evo" = "" #X11evo
    #"c11" = " -d $($Config.SelGPUCC)" #C11
    "neoscrypt" = " -d $($Config.SelGPUCC)" #Neoscrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -N 1 -R 1 -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
