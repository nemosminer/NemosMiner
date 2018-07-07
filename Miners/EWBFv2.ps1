. .\Include.ps1

$Path = ".\Bin\NVIDIA-EWBFv2\\miner.exe"
$Uri = "http://nemos.dx.am/opt/nemos/EWBFEquihashv0.3.7z"

$Commands = [PSCustomObject]@{
    #"bitcore" = "" #Bitcore
    #"blake2s" = "" #Blake2s
    #"blakecoin" = "" #Blakecoin
    #"vanilla" = "" #BlakeVanilla
    #"cryptonight" = "" #Cryptonight
    #"decred" = "" #Decred
    "equihash192" = " --cuda_devices $SelGPUDSTM" #Equihash192
    #"ethash" = "" #Ethash
    #"groestl" = "" #Groestl
    #"hmq1725" = "" #hmq1725
    #"keccak" = "" #Keccak
    #"lbry" = "" #Lbry
    #"lyra2v2" = "" #Lyra2RE2
    #"lyra2z" = "" #Lyra2z
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = "" #NeoScrypt
    #"nist5" = "" #Nist5
    #"pascal" = "" #Pascal
    #"qubit" = "" #Qubit
    #"scrypt" = "" #Scrypt
    #"sia" = "" #Sia
    #"sib" = "" #Sib
    #"skein" = "" #Skein
    #"timetravel" = "" #Timetravel
    #"x11" = "" #X11
    #"x11evo" = "" #X11evo
    #"x17" = "" #X17
    #"yescrypt" = "" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--api 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) --algo 192_7 --pers ZERO_PoW --server $($Pools.(Get-Algorithm($_)).Host) --port $($Pools.(Get-Algorithm($_)).Port) --fee 0 --eexit 1 --user $($Pools.(Get-Algorithm($_)).User) --pass $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_) --intensity 64"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "EWBF"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
    
    }
}
