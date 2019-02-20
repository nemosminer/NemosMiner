if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-TTMiner2111b\TT-Miner.exe"
$Uri = "https://tradeproject.de/download/Miner/TT-Miner-2.1.11-beta7.zip"

$Commands = [PSCustomObject]@{  
    "mtp"     = "-A MTP-100" #(Supports NiceHash)  
    #"ethash"  = "-A ETHASH-100" #(Supports NiceHash)
    #"progpow" = "-A PROGPOW-100" #(Supports NiceHash)
    #"lyra2v3" = "-A LYRA2V3-100" #(Supports NiceHash)
}
 
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "$($Commands.$_) -d $($Config.SelGPUDSTM) --api-bind 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -P $($Pools.($Algo).User):x@$($Pools.($Algo).Host):$($Pools.($Algo).Port)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".day * .98} # substract 2% devfee
        API       = "TTminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
