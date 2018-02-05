. .\Include.ps1

$Path = ".\\Bin\\Ethash-Phoenix\\EthDcrMiner64.exe"
$Uri = "https://github.com/nemosminer/Claymores-Dual-Ethereum/releases/download/10.6/Claymore.s.Dual.Ethereum.Decred_Siacoin_Lbry_Pascal.AMD.NVIDIA.GPU.Miner.v10.6.zip"

$Commands = [PSCustomObject]@{
    "ethash" = "" #Ethash
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-rmode 0 -cdmport 3333 -cdm 1 -pool $($Pools.Ethash.Host):$($Pools.Ethash.Port) -wal $($Pools.Ethash.User) -pass $($Pools.Ethash.Pass) -proto 4 -coin auto -nvidia"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Live}
        API = "Claymore"
        Port = 3333
        Wrap = $false
        URI = $Uri
    }
}
