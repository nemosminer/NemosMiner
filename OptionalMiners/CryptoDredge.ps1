if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-CryptoDredge\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.9.1/CryptoDredge_0.9.1_cuda_9.2_windows.zip"

$Commands = [PSCustomObject]@{
    "allium"            = " -a allium" #Allium (fastetst)
    "lyra2v2"           = " -a lyra2v2" #Lyra2RE2 (fastest)
    "lyra2z"            = " -a lyra2z" #Lyra2z (fastest)
    "neoscrypt"         = " -a neoscrypt" #NeoScrypt (fastest)
    "phi"               = " -a phi" #Phi
    "phi2"              = " -a phi2" #Phi2 (fastest)
    #"skein"     = "" #Skein
    #"skunk"     = "" #Skunk(trex faster)
    "cryptonightheavy"  = " -a cryptonightheavy" # CryptoNightHeavy(fastest)
    "cryptonightv7"     = " -a cryptonightv7" # CryptoNightV7(fastest)
    "cryptonightmonero" = " -a cryptonightv7" # Cryptonightmonero(fastest)
    "tribus"            = " -a tribus" #Tribus (fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = " --retry-pause 1 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) --no-watchdog -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_) -R 1 -q -N 1"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
