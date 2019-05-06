
if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\Ethash-Phoenix42c\PhoenixMiner.exe"
$Uri = "https://nemosminer.com/data/optional/PhoenixMiner_4.2c_Windows.7z"
$Commands = [PSCustomObject]@{
     "ethash" = " -di $($($Config.SelGPUCC).Replace(',',''))" #Ethashc #fastest and Epoch 267 ready
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-nvdo 1 -esm 3 -allpools 1 -allcoins 1 -platform 2 -mport -$($Variables.NVIDIAMinerAPITCPPort) -epool $($Pools.Ethash.Host):$($Pools.Ethash.Port) -ewal $($Pools.Ethash.User) -epsw $($Pools.Ethash.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .9935} # substract 0.65% devfee
        API       = "ethminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #3333
        Wrap      = $false
        URI       = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
