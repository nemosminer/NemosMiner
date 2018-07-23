if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-EWBFv2\\miner.exe"
$Uri = "http://nemos.dx.am/opt/nemos/EWBFEquihashminerv0.4.7z"

$Commands = [PSCustomObject]@{
    "equihash144" = " --cuda_devices $($Config.SelGPUDSTM) --algo 144_5 --pers sngemPoW" #Equihash144
    "equihash192" = " --cuda_devices $($Config.SelGPUDSTM) --algo 192_7 --pers ZERO_PoW" #Equihash192
    "equihash144btcz" = " --cuda_devices $($Config.SelGPUDSTM) --algo 144_5 --pers BitcoinZ" #Equihash144btcz
    "equihash144zel" = " --cuda_devices $($Config.SelGPUDSTM) --algo 144_5 --pers ZelProof" #Equihash144zel
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--api 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) --server $($Pools.(Get-Algorithm($_)).Host) --port $($Pools.(Get-Algorithm($_)).Port) --fee 0 --eexit 1 --user $($Pools.(Get-Algorithm($_)).User) --pass $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_) --intensity 64"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week}
        API = "EWBF"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
    
    }
}
