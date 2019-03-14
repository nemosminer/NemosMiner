if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-Gminer136b\miner.exe"
$Uri = "https://github.com/develsoftware/GMinerBetaRelease/releases/download/1.36/gminer_1_36_minimal_windows64.zip"
$Commands = [PSCustomObject]@{
    "equihash144"  = " --devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Equihash144 (fastest)
    "zhash"        = " --devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Zhash (fastest)
    "equihash192"  = " --devices $($Config.SelGPUDSTM) --algo 192_7 --pers auto" #Equihash192 (fastest)
    "equihash-btg" = " --devices $($Config.SelGPUDSTM) --algo 144_5 --pers BgoldPoW " # Equihash-btg MPH (fastest)
    "equihash96"   = " --devices $($Config.SelGPUDSTM) --algo 96_5 --pers auto" #Equihash96 (fastest)
    #"beam"         = " --devices $($Config.SelGPUDSTM) --algo 150_5 --pers auto" #Equihash150 (Bminer faster)
    "grincuckaroo29"  = " --devices $($Config.SelGPUDSTM) --algo grin29 --pers auto" #Grincuckaroo29 (fastest)
   #"grincuckatoo31"  = " --devices $($Config.SelGPUDSTM) --algo grin31 --pers auto" #Grincuckatoo31 8gb + vram cards only remove # from #"grincuckatoo31 to enable
 
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--intensity 100 test--watchdog 0 --api $($Variables.NVIDIAMinerAPITCPPort) --server $($Pools.($Algo).Host) --port $($Pools.($Algo).Port) --user $($Pools.($Algo).User) --pass $($Pools.($Algo).Pass)$($Commands.$_)"
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
