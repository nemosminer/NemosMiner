if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-Gminer192\miner.exe"
$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/1.92/gminer_1_92_windows64.zip"
$Commands = [PSCustomObject]@{
    #"beamv2"         = " --devices $($Config.SelGPUDSTM) -a BeamHashII" #Equihash150 (NiceHash)
    #"equihash125"  = " --devices $($Config.SelGPUDSTM) -a 125_4" #Equihash125
    #"equihash144"  = " --devices $($Config.SelGPUDSTM) -a 144_5 --pers auto" #Equihash144
    "equihash96"      = " --devices $($Config.SelGPUDSTM) -a 96_5 --pers auto" #Equihash144
    #"zhash"        = " --devices $($Config.SelGPUDSTM) -a 144_5 --pers auto" #Zhash
    #"equihash192"  = " --devices $($Config.SelGPUDSTM) -a 192_7 --pers auto" #Equihash192
    #"equihash-btg" = " --devices $($Config.SelGPUDSTM) -a 144_5 --pers BgoldPoW " # Equihash-btg MPH
    "grincuckaroo29"  = " --devices $($Config.SelGPUDSTM) --algo cuckaroo29 --pers auto" #Grincuckaroo29
    "grincuckarood29" = " --devices $($Config.SelGPUDSTM) --algo cuckarood29 --pers auto" #Grincuckarood29
    "cuckoocycle"     = " --devices $($Config.SelGPUDSTM) --algo aeternity --pers auto" #Aeternity 
    #"grincuckatoo31" = " --devices $($Config.SelGPUDSTM) --algo grin31 --pers auto" #Grincuckatoo31(8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    "ethash"          = " --devices $($Config.SelGPUDSTM) --algo ethash --proto stratum" #Ethash
    "eaglesong"       = " --devices $($Config.SelGPUDSTM) --algo eaglesong" #eaglesong
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    switch ($_) {
        "ethash" { $Fee = 0.0065 }
        default { $Fee = 0.02 }
    }
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--watchdog 0 --pec 0 --nvml 0 --api $($Variables.NVIDIAMinerAPITCPPort) --server $($Pools.$Algo.Host) --port $($Pools.$Algo.Port) --user $($Pools.$Algo.User) --pass $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee) } # substract devfee
        API       = "gminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }
}
