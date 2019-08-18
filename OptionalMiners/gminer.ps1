if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
 
$Path = ".\Bin\NVIDIA-Gminer156\miner.exe"
$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/1.56/gminer_1_56_windows64.zip"
$Commands = [PSCustomObject]@{
   #"beam"         = " --devices $($Config.SelGPUDSTM) -a beamhash" #Equihash150 (NiceHash)
    "beamv2"       = " --devices $($Config.SelGPUDSTM) -a beamhashII" #Equihash150 (NiceHash)
   #"equihash125"  = " --devices $($Config.SelGPUDSTM) -a 125_4" #Equihash125
    "equihash144"  = " --devices $($Config.SelGPUDSTM) -a 144_5 --pers auto" #Equihash144
    "equihash96"   = " --devices $($Config.SelGPUDSTM) -a 96_5 --pers auto" #Equihash144
    "zhash"        = " --devices $($Config.SelGPUDSTM) -a 144_5 --pers auto" #Zhash
    "equihash192"  = " --devices $($Config.SelGPUDSTM) -a 192_7 --pers auto" #Equihash192
    "equihash-btg" = " --devices $($Config.SelGPUDSTM) -a 144_5 --pers BgoldPoW " # Equihash-btg MPH
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--watchdog 0 --pec 0 --nvml 0 --api $($Variables.NVIDIAMinerAPITCPPort) --server $($Pools.($Algo).Host) --port $($Pools.($Algo).Port) --user $($Pools.($Algo).User) --pass $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .98 } # substract 2% devfee
        API       = "gminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
