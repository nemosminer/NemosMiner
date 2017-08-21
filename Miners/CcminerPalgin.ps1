. .\Include.ps1

$Path = ".\Bin\NVIDIA-Palgin\ccminer.exe"
$Uri = "https://github.com/palginpav/ccminer/releases/download/1.1.1/palginmod_1.1_x86.zip"

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
