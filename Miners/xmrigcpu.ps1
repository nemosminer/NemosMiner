if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\CPU-XMRig540\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.4.0/xmrig-5.4.0-msvc-cuda10_1-win64.7z"

$Commands = [PSCustomObject]@{
    "randomxmonero"      = " -a rx/0 --nicehash" #RandomX
    "randomx"            = " -a rx/0 --nicehash" #RandomX
    "cryptonight_heavyx" = " -a cn/double --nicehash" #cryptonight_heavyx
    "cryptonight_saber"  = " -a cn-heavy/tube --nicehash" #cryptonight_heavyx
    "cryptonightv7"      = " -a cn/1 --nicehash" #cryptonightv7
    "randomsfx"          = " -a rx/sfx --nicehash" #Randomsfx
    "cryptonight_fast"   = " -a cn/half --nicehash" #cryptonightFast
    "cryptonight_haven"  = " -a cn-heavy/xhv --nicehash" #cryptonightFast
}

$ThreadCount = $Variables.ProcessorCount - 1
$Port = $Variables.CPUMinerAPITCPPort
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "-t $($ThreadCount) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_) --keepalive --http-port=$($Variables.CPUMinerAPITCPPort) --donate-level 0"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "XMRig"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.$Algo.User
    }
}
