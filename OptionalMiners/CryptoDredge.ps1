if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-CryptoDredge0152\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.15.2/CryptoDredge_0.15.2_cuda_10.0_windows.zip"

$Commands = [PSCustomObject]@{
    "allium"            = " -a allium" #Allium (fastest)
    #"lyra2v2"           = " -a lyra2v2" #Lyra2RE2 (Asic)
    "lyrarev3"          = " -a lyra2v3" #Lyra2REv3 (Not Asic :)
    "lyra2v3"           = " -a lyra2v3" #Lyra2v3 (Not Asic :)
    #"lyra2z"            = " -a lyra2z" #Lyra2z (Asic)
    "neoscrypt"         = " -a neoscrypt" #NeoScrypt (fastest)
    "phi"               = " -a phi" #Phi (fastest)
    #"blake2s"           = " -a blake2s" #Blake2s (not profitable)
    "phi2"              = " -a phi2" #Phi2 (fastest)
    "lbk3"              = " -a lbk3" #Lbk3(fastest)
    "lyra2vc0ban"       = " -a lyra2vc0ban" #Lyra2vc0banHash (fastest)
    "cryptonightheavy"  = " -a cryptonightheavy" # CryptoNightHeavy(fastest)
    #"x22i"              = " -a x22i" # X22i (trex faster)
    #"tribus"            = " -a tribus" #Tribus (not profitable)
    "cnv8"              = " -a cnv8" #CryptoNightv8 (fastest)
    "cryptonightmonero" = " -a cnv8" # Cryptonightmonero (fastest)
    #"c11"               = " -a c11" #C11 (trex faster)
    #"polytimos "        = " -a polytimos" #Polytimos (zealotenemyfaster)
    "skunk"             = " -a skunk" #Skunk (fastest)
    "mtp"               = " -a mtp" #Mtp (not Asic :)
    #"bcd"               = " -a bcd" #Bcd (trex faster)
    #"x16r"              = " -a x16r" #X16r (trex faster)
    "x21s"              = " -a x21s" #X21s (fastest)
    #"x16s"              = " -a x16s" #X16s (trex faster)
    #"x17"               = " -a x17" #X17 (trex faster)
    #"bitcore"           = " -a bitcore" #Bitcore (trex faster)
    "hmq1725"           = " -a hmq1725" #Hmq1725 (fastest)
    "dedal"             = " -a dedal" #Dedal (trex faster second place)
    "pipe"              = " -a pipe" #Pipe (fastest)
    "exosis"            = " -a exosis" #Exosis (fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = " --api-type ccminer-tcp --no-color --intensity 6 --cpu-priority 5 --no-crashreport --no-watchdog -r -1 -R 1 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .99} # substract 1% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
