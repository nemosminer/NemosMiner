. .\Include.ps1

$Path = ".\\Bin\\Ethash-Claymore\\EthDcrMiner64.exe"
$Uri = "https://github.com/nemosminer/Claymores-Dual-Ethereum/releases/download/V11.5/Claymore.s.Dual.Ethereum.NVIDIA.GPU.Miner.v11.5.zip"
$Commands = [PSCustomObject]@{
    "ethash" = " -di $($SelGPUCC.Replace(',',''))" #Ethash
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = " -esm 3 -allpools 1 -allcoins 1 -platform 3 -mport -$($Variables.MinerAPITCPPort) -epool $($Pools.Ethash.Host):$($Pools.Ethash.Port) -ewal $($Pools.Ethash.User) -epsw $($Pools.Ethash.Pass)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Live * .99} # substract 1% devfee
        API = "Claymore"
        Port = $Variables.MinerAPITCPPort #3333
        Wrap = $false
        URI = $Uri
		User = $Pools.(Get-Algorithm($_)).User
    }
}
