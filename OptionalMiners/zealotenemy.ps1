if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-zealotenemy128\z-enemy.exe"
$Uri = "https://nemosminer.com/data/optional/z-enemy.1-28-cuda10.0.7z"

$Commands = [PSCustomObject]@{
    "aeriumx"    = "" #AeriumX(RTX)
    "bcd"        = "" #Bcd(RTX)
    "hsr"        = "" #Hsr
    "phi"        = "" #Phi (RTX)
    "phi2"       = "" #Phi2 (RTX)
    "poly"       = "" #Polytimos(RTX) 
    "bitcore"    = "" #Bitcore (RTX)
    "x16r"       = "" #X16r (RTX)
    "x16s"       = "" #X16s (RTX)
    "sonoa"      = "" #SonoA (RTX)
    "skunk"      = "" #Skunk (RTX)
    "timetravel" = "" #Timetravel (RTX)
    "tribus"     = "" #Tribus (RTX)
    "c11"        = "" #C11 (RTX)
    "xevan"      = "" #Xevan (RTX)
    "x17"        = "" #X17(RTX)
    "hex"        = "" #Hex (RTX)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -R 1 -q -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .99} # substract 1% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
