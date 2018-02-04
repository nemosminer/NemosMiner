. .\Include.ps1

$Path = ".\Bin\NVIDIA-ccminerpolytimos\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerpolytimos/releases/download/Alexis78-1.0/ccminer-polytimos.7z"

$Commands = [PSCustomObject]@{
    #"hsr" = " -d $SelGPUCC" #Hsr
    #"bitcore" = "" #Bitcore
    "blake2s" = " -d $SelGPUCC" #Blake2s
    #"blakecoin" = " -d $SelGPUCC" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = "" #Cryptonight
    "veltor" = " -i 23 -d $SelGPUCC" #Veltor
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    "poly" = " -d $SelGPUCC" #polytimos
    #"ethash" = "" #Ethash
    #"groestl" = "" #Groestl
    #"hmq1725" = "" #hmq1725
    "keccak" = " -m 2 -i 29 -d $SelGPUCC" #Keccak
    "lbry" = " -d $SelGPUCC" #Lbry
    "lyra2v2" = " -d $SelGPUCC" #Lyra2RE2
    #"lyra2z" = "" #Lyra2z
    #"myr-gr" = " -d $SelGPUCC" #MyriadGroestl
    #"neoscrypt" = " -i 15 -d $SelGPUCC" #NeoScrypt
    "nist5" = " -d $SelGPUCC" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    #"sib" = " -i 21 -d $SelGPUCC" #Sib
    #"X11Gost" = " -i 21 -d $SelGPUCC" #X11Gost
    "skein" = " -d $SelGPUCC" #Skein
    #"timetravel" = "" #Timetravel
    "c11" = " -i 21 -d $SelGPUCC" #C11
    #"x11evo" = "" #X11evo
    "x17" = " -i 21  -d $SelGPUCC" #X17
    

}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Live}
        API = "Ccminer"
        Port = 4068
        Wrap = $false
        URI = $Uri
    }
}
