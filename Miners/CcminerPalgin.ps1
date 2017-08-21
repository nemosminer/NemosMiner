. .\Include.ps1

$Path = ".\Bin\NVIDIA-Palgin\ccminer.exe"
$Uri = "https://github.com/palginpav/ccminer/r. .\Include.ps1

$Path = ".\Bin\NVIDIA-Alexis78\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminer-Alexis78/releases/download/ccminer-alexis78/ccminer-alexis78-ms2013-cuda7.5.7z"

$Commands = [PSCustomObject]@{
    #"bitcore" = "" #Bitcore
    #"blake2s" = " -d $SelGPUCC" #Blake2s
    #"blakecoin" = " -d $SelGPUCC" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = "" #Cryptonight
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = "" #Groestl
    #"hmq1725" = "" #hmq1725
    "keccak" = " -i 29" #Keccak
    #"lbry" = " -d $SelGPUCC" #Lbry
    #"lyra2v2" = " -d $SelGPUCC" #Lyra2RE2
    #"lyra2z" = "" #Lyra2z
    "myr-gr" = " -d $SelGPUCC" #MyriadGroestl
    #"neoscrypt" = " -i 15 -d $SelGPUCC" #NeoScrypt
    "nist5" = "" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    "sib" = " -i 21 -d $SelGPUCC" #Sib
    "X11Gost" = " -i 21 -d $SelGPUCC" #X11Gost
    "skein" = " -d $SelGPUCC" #Skein
    #"timetravel" = "" #Timetravel
    "c11" = " -i 21 -d $SelGPUCC" #C11
    #"x11evo" = "" #X11evo
    "x17" = " -i 21 -d $SelGPUCC" #X17
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $Wallet -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        Wrap = $false
        URI = $Uri
    }
}
eleases/download/1.1.1/palginmod_1.1_x86.zip"

$Commands = [PSCustomObject]@{
    "bastion" = ""

    "bitcore" = " -d $SelGPUCC" 
    #"blake" = ""
    "blake2s" = " -d $SelGPUCC" 
    #"blakecoin" = "" 
    "bmw" = ""
    "c11" = " -d $SelGPUCC" 
    #"cryptolight" = ""
    #"cryptonight" = ""  
    #"decred" = "" 
    "deep" = ""
    "dmd-gr" = "" 
    #"equihash" = "" 
    "fresh" = ""
    "fugue256" = ""
    "groestl" = " -d $SelGPUCC" 
    "heavy" = "" 
    #"hmq1725" = "" 
    "jackpot" = "" 
    #"jha" = ""
    #"keccak" = "" 
    "lbry" = " -d $SelGPUCC" 
    "luffa" = ""
    "lyra2" = ""
    "lyra2v2" = " -d $SelGPUCC" 
    #"lyra2z" = "" 
    #"m7m" = "" 
    "mjollnir" = "" 
    "myr-gr" = " -d $SelGPUCC" 
    #"neoscrypt" = "" 
    #"nist5" = "" 
    #"pascal" = "" 
    "penta" = ""
    "quark" = "" 
    "qubit" = "" 
    "s3" = "" 
    #"scrypt" = "" 
    #"sia" = ""  
    "sib" = " -d $SelGPUCC -i 21 " 
    "skein" = " -d $SelGPUCC" 
    "skein2" = ""
    #"skunk" = "" 
    "timetravel" = " -d $SelGPUCC" 
    "timetravel10" = "" 
    #"tribus" = "" 
    "vanilla" = "" 
    "veltor" = " -d $SelGPUCC -i 23 " 
    "whirlpool" = ""
    "wildkeccak" = ""
    "x11" = " -i 21 " 
    "x11evo" = " -i 21 " 
    #"x11gost" = ""
    #"x13" = "" 
    "x14" = " -i 21 " 
    "x15" = "" 
    "x17" = " -i 21 " 
    #"xevan" = "" 
    #"yescrypt" = "" 
    "zr5" = ""
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = " -R 5 -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $Wallet -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "Ccminer"
        Port = 4068
        Wrap = $false
        URI = $Uri
    }
}
