if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\CPU-XMRig462b\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v4.6.2-beta/xmrig-4.6.2-beta-msvc-cuda10_1-win64.7z"

$Commands = [PSCustomObject]@{
    "cryptonightr"       = " -a cryptonight/r --nicehash" #cryptonight/r (NiceHash)
    "cryptonight-monero" = " -a cryptonight/r" #cryptonight/r (Mining Pool Hub)
}

$ThreadCount = $ThreadCount = $Variables.ProcessorCount - 1
$Port = $Variables.CPUMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "-t $($ThreadCount) -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_) --keepalive --http-port=$($Variables.CPUMinerAPITCPPort) --donate-level 0"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "XMRig"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.($Algo).User
    }
}
