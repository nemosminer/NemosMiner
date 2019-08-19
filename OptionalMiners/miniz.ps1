if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-miniZ15p\miniZ.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v1.5p/miniZ_v1.5p_cuda10_win-x64.7z"
$Commands = [PSCustomObject]@{
    #"equihash144"  = " --par=144,5 --pers auto" #Equihash144
    #"equihash125"  = " --par=125,4" #Equihash125
    #"zhash"        = " --par=144,5 --pers auto" #Zhash
    #"beamv2"       = " --par=beam2" #Beam
    #"equihash192"  = " --par=192,7 --pers auto" #Equihash192
    #"equihash-btg" = " --par=144,5 --pers BgoldPoW " # Equihash-btg MPH
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--stat-int 30 --nonvml --latency --nocolor --extra --tempunits C -cd $($Config.SelGPUDSTM) --telemetry $($Variables.NVIDIAMinerAPITCPPort) --url $($Pools.($Algo).User)@$($Pools.($Algo).Host):$($Pools.($Algo).Port) --pass $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .98 } # substract 2% devfee
        API       = "miniZ"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
