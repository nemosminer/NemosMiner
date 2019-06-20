if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")}
 
$Path = ".\Bin\NVIDIA-Gminer146\miner.exe"
$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/1.46/gminer_1_46_windows64.zip"
$Commands = [PSCustomObject]@{
     "equihash125"    = " --devices $($Config.SelGPUDSTM) --algo 125_4 --pers auto" #Equihash125
     "equihash144"    = " --devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Equihash144
     "zhash"          = " --devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Zhash
     "equihash192"    = " --devices $($Config.SelGPUDSTM) --algo 192_7 --pers auto" #Equihash192
     "equihash-btg"   = " --devices $($Config.SelGPUDSTM) --algo 144_5 --pers BgoldPoW " # Equihash-btg MPH
     "equihash96"     = " --devices $($Config.SelGPUDSTM) --algo 96_5 --pers auto" #Equihash96
     "beam"           = " --devices $($Config.SelGPUDSTM) --algo 150_5 --pers auto" #Equihash150
     "grincuckaroo29" = " --devices $($Config.SelGPUDSTM) --algo grin29 --pers auto" #Grincuckaroo29
    #"cuckoocycle"    = " --devices $($Config.SelGPUDSTM) --algo aeternity --pers auto" #Aeternity 
    #"grincuckatoo31" = " --devices $($Config.SelGPUDSTM) --algo grin31 --pers auto" #Grincuckatoo31 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
 
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--intensity 100 --watchdog 0 --api $($Variables.NVIDIAMinerAPITCPPort) --server $($Pools.($Algo).Host) --port $($Pools.($Algo).Port) --user $($Pools.($Algo).User) --pass $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .98} # substract 2% devfee
        API       = "gminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
