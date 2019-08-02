if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-Phoenix45c\PhoenixMiner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/4.5c/PhoenixMiner_4.5c_Windows.7z"
$Commands = [PSCustomObject]@{
    "ethash"  = " -di $($($Config.SelGPUCC).Replace(',',''))" #Ethash
    "progpow" = " -coin bci -di $($($Config.SelGPUCC).Replace(',',''))" #Progpow 
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-nvdo 1 -esm 3 -allpools 1 -allcoins 1 -platform 2 -mport -$($Variables.NVIDIAMinerAPITCPPort) -epool $($Pools.($Algo).Host):$($Pools.($Algo).Port) -ewal $($Pools.($Algo).User) -epsw $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .9935 } # substract 0.65% devfee
        API       = "ethminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #3333
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
