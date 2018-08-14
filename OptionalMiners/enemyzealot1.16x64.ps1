if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-enemyz1.15a64\z-enemy.exe"
$Uri = "http://nemos.dx.am/opt/nemos/z-enemy.1-16-cuda9.2_x64.7z"

$Commands = [PSCustomObject]@{
    #"aeriumx" = " -i 20" #Aolytimos(not tested)
    #"polytimos" = " -i 20" #Polytimos(not tested)
    #"hsr" = " -i 20 " #Hsr
    #"phi2" = " -i 20" #Phi2
    #"bitcore" = " -r 0 -d $SelGPUCC -i 20" #Bitcore(sp-mod, delos faster)
    #"x16r" = " -i 20" #X16r(ccminerx16r faster/very close)
    #"x16s" = " -i 20" #X16s(delos faster)
    #"blake2s" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Blake2s
    #"blakecoin" = " -d $SelGPUCC" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = " -i 10 -d $SelGPUCC" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Groestl
    #"hmq1725" = " -d $SelGPUCC" #hmq1725
    #"keccakc" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Keccakc
    #"lbry" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Lbry
    #"lyra2v2" = " -N 1 -d $SelGPUCC --api-remote --api-allow=0/0" #Lyra2RE2
    #"lyra2z" = "  -d $SelGPUCC --api-remote --api-allow=0/0 --submit-stale" #Lyra2z
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = " -d $SelGPUCC" #NeoScrypt
    #"nist5" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sha256t" = " -d $SelGPUCC" #Sha256t
    #"sia" = "" #Sia
    #"sib" = " -d $SelGPUCC --api-remote --api-allow=0/0" #Sib
    #"skein" = "" #Skein
    #"skunk" = " -r 0 -d $SelGPUCC -i 20" #Skunk(Delos faster)
    "timetravel" = " -i 24" #Timetravel(fastest)
    #"tribus" = " -i 20" #Tribus(trex,cryptodredge faster)
    #"c11" = " -i 20" #C11(Alexis78v1.2 faster)
    #"xevan" = " -i 20" #Xevan(fastest Alexis78Xevan very cose)
    #"x11evo" = " -d $SelGPUCC" #X11evo
    #"x17" = " -i 20" #X17(Alexis78,Delos,enemy1.03 faster)
    #"vitalium" = " -i 20" #Vitalium(not testest)
    #"yescrypt" = "" #Yescrypt
    #"hex" = " -i 21" #Hex(not testest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -R 1 -q -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API = "Ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
