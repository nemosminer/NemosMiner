if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-CryptoDredge010\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.10.0/CryptoDredge_0.10.0_cuda_10.0_windows.zip"

$Commands = [PSCustomObject]@{
    "allium"            = " -a allium" #Allium (fastetst)
    "lyra2v2"           = " -a lyra2v2" #Lyra2RE2 (fastest)
    "lyra2z"            = " -a lyra2z" #Lyra2z (fastest)
    "neoscrypt"         = " -a neoscrypt" #NeoScrypt (fastest)
    "phi"               = " -a phi" #Phi
    "phi2"              = " -a phi2" #Phi2 (fastest)
    "lbk3"              = " -a lbk3" #Lbk3(test)
    #"skein"             = " -a skein" #Skein(slow)
    "cryptonightheavy"  = " -a cryptonightheavy" # CryptoNightHeavy(fastest)
    "cryptonightv7"     = " -a cryptonightv7" # CryptoNightV7(fastest)
    "x22i"              = " -a x22i" # X22i
    "tribus"            = " -a tribus" #Tribus (fastest)
    "cnv8"              = " -a cnv8" #CryptoNightv8 
    "cryptonightmonero" = " -a cnv8" # Cryptonightmonero
    "c11"               = " -a c11" #C11
    "polytimos "        = " -a polytimos " #Polytimos 
    "skunk"             = " -a skunk" #Skunk
    "bcd"               = " -a bcd" #Bcd
    "x17"               = " -a x17" #X17
    "bitcore"           = " -a bitcore" #Bitcore
    "hmq1725"           = " -a hmq1725" #Hmq1725
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
