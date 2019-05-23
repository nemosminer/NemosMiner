if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\Ethash-Claymore145b\EthDcrMiner64.exe"
$Uri = "https://github.com/Minerx117/Claymore-s-Dual-Ethereum/releases/download/v14.5b/ClaymoresEthereumv14.5cuda10.7z"

$Commands = [PSCustomObject]@{
     "ethash" = " -di $($($Config.SelGPUCC).Replace(',',''))" #Ethash -strap 1 -strap 2 -strap 3 -strap 4 -strap 5 -strap 6
} 

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-wd 0 -esm 3 -allpools 1 -allcoins 1 -platform 2 -mode 1 -mport -$($Variables.NVIDIAMinerAPITCPPort) -epool $($Pools.($Algo).Host):$($Pools.($Algo).Port) -ewal $($Pools.($Algo).User) -epsw $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Week * .99} # substract 1% devfee
        API       = "ethminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #3333
        Wrap      = $false
        URI       = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
