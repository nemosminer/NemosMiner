if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-EWBF06\\miner.exe"
$Uri = "https://nemosminer.com/data/optional/EWBFEquihashminerv0.6.7z"
$Commands = [PSCustomObject]@{
     "equihash144"  = " --cuda_devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Equihash144 
     "zhash"        = " --cuda_devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Zhash 
     "equihash192"  = " --cuda_devices $($Config.SelGPUDSTM) --algo 192_7 --pers ZERO_PoW" #Equihash192 
     "equihash-btg" = " --cuda_devices $($Config.SelGPUDSTM) --algo 144_5 --pers BgoldPoW" # Equihash-btg 
     "equihash96"   = " --cuda_devices $($Config.SelGPUDSTM) --algo 96_5 --pers auto" #Equihash96
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--templimit 95 --api 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) --server $($Pools.($Algo).Host) --port $($Pools.($Algo).Port) --eexit 1 --user $($Pools.($Algo).User) --pass $($Pools.($Algo).Pass)$($Commands.$_) --fee 0 --intensity 64"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API       = "ewbf"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
