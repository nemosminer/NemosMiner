if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1;RegisterLoaded(".\Includes\include.ps1")}

$Path = ".\Bin\NVIDIA-nbminer233\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v23.3/NBMiner_23.3_Win.zip"

$Commands = [PSCustomObject]@{
    #"grincuckatoo31" = " -a cuckatoo -o stratum+tcp://" #grincuckatoo31 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
     "grincuckaroo29" = " -a cuckaroo -o stratum+tcp://" #grincuckaroo29
    #"cuckoocycle" = " -a cuckoo_ae -o stratum+tcp://" #cuckoocycle  
    #"ethash" = " -a ethash -o ethnh+tcp://" #ethash
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
     switch ($_) {
        "ethash" {$Fee = 0.0065}
        default {$Fee = 0.02}
    }
    If ($Pools.($Algo).Host -notlike "*nicehash*") {return}
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "$($Commands.$_)$($Pools.($Algo).Host):$($Pools.($Algo).Port) --cuckoo-intensity 0 --api 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -u $($Pools.($Algo).User):$($Pools.($Algo).Pass)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee)} # substract devfee
        API       = "NBMiner"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
