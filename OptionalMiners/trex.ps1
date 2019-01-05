if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-trex089\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.8.9/t-rex-0.8.9-win-cuda10.0.zip"

$Commands = [PSCustomObject]@{
"balloon" = "" #Balloon(fastest)
"astralhash" = "" #Astralhash
"jeonghash" = "" #Jeonghash
"padihash" = "" #Padihash
"pawelhash" = "" #Pawelhash
"polytimos" = "" #Poly 
"bcd" = "" #Bcd (fastest)
#"skunk" = "" #Skunk (CryptoDredge faster)
"bitcore" = "" #Bitcore( fastest)
"geek"= "" #Geekcash
#"lyra2z" = "" #Lyra2z (Asic)
#"tribus" = "" #Tribus (not profitable atm)
"c11" = "" #C11 (fastest)
"x17" = "" #X17 (fastest)
"x16s" = "" #X16s (fastest)
"x16r" = "" #X16r (fastest)
"sonoa" = "" #SonoA (fastest)
"hmq1725" = "" #Hmq1725 (recommened)
"dedal" = "" #Dedal (fastest)
"sha256t" = "" #Sha256t (fastest)
"x21s" = "" #X21s (fastest)
"x22i" = "" #X22i (fastest)
"timetravel" = "" #Timetravel (fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_) --quiet -r 10 --cpu-priority 5"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .99} # substract 1% devfee
        API = "ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
