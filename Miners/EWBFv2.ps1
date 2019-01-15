if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-EWBF0.6\\miner.exe"
$Uri = "https://nemosminer.com/data/optional/EWBFEquihashminerv0.6.7z"
$Commands = [PSCustomObject]@{
    "equihash144"  = " --cuda_devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Equihash144 (miniZ faster)
    "zhash"        = " --cuda_devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Zhash (miniZ faster)
    "equihash192"  = " --cuda_devices $($Config.SelGPUDSTM) --algo 192_7 --pers ZERO_PoW" #Equihash192 (miniZ faster)
    "equihash-btg" = " --cuda_devices $($Config.SelGPUDSTM) --algo 144_5 --pers BgoldPoW" # Equihash-btg (miniZ faster)
    "equihash96"   = " --cuda_devices $($Config.SelGPUDSTM) --algo 96_5 --pers auto" #Equihash96 (miniZ faster)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--templimit 95 --api 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) --server $($Pools.(Get-Algorithm($_)).Host) --port $($Pools.(Get-Algorithm($_)).Port) --eexit 1 --user $($Pools.(Get-Algorithm($_)).User) --pass $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_) --fee 0 --intensity 64"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
        API       = "ewbf"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
        Host      = $Pools.(Get-Algorithm $_).Host
        Coin      = $Pools.(Get-Algorithm $_).Coin
    }
}
