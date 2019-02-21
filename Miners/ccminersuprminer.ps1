if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-ccminersuprminer20\ccminer.exe"
$Uri = "https://github.com/ocminer/suprminer/releases/download/2.0/suprminer-2.0.7z"

$Commands = [PSCustomObject]@{
    #"c11" = " -d $($Config.SelGPUCC)" #C11 (trex faster/ fastest open source)
    #"x16r"  = " -a x16r -d $($Config.SelGPUCC)" #X16r(testing)
    #"x16rt" = " -a x16rt -d $($Config.SelGPUCC)" #X16rt (testing)
    #"veil"  = " -a x16rt -d $($Config.SelGPUCC)" #Veil (testing)
    #"bitcore" = " -d $($Config.SelGPUCC)" #Bitcore
    #"blake2s" = " -d $($Config.SelGPUCC)" #Blake2s
    #"blakecoin" = " -d $($Config.SelGPUCC)" #Blakecoin
    #"cryptonight" = " -i 10.5 -l 8x120 --bfactor=8 -d $($Config.SelGPUCC) --api-remote" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = " -d $($Config.SelGPUCC)" #Groestl
    #"hmq1725" = " -d $($Config.SelGPUCC)" #hmq1725
    #"jha" = " -d $($Config.SelGPUCC)" #Jha
    #"keccak" = "" #Keccak
    #"lbry" = " -d $($Config.SelGPUCC)" #Lbry
    #"lyra2v2" = "" #Lyra2RE2
    #"lyra2z" = " -d $($Config.SelGPUCC) --api-remote --api-allow=0/0 --submit-stale" #Lyra2z
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = " -d $($Config.SelGPUCC)" #NeoScrypt
    #"nist5" = "" #Nist5
    #"pascal" = "" #Pascal
    #"phi" = " -d $($Config.SelGPUCC)" #Phi
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    #"sib" = "" #Sib
    #"skein" = "" #Skein
    #"skunk" = " -d $($Config.SelGPUCC)" #Skunk
    #"timetravel" = " -d $($Config.SelGPUCC)" #Timetravel
    #"tribus" = " -d $($Config.SelGPUCC)" #Tribus
    #"vanilla" = "" #BlakeVanilla
    #"veltor" = "" #Veltor
    #"x11evo" = " -d $($Config.SelGPUCC)" #X11evo
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -R 1 -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
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
