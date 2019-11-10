if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-XMRig461b\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v4.6.1-beta/xmrig-4.6.1-beta-win64.7z"

$Commands = [PSCustomObject]@{
    "cryptonightr"       = " --nicehash" #cryptonight/r (NiceHash)
    "cryptonight-monero" = "" #cryptonight/r (Mining Pool Hub)
}

$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-R 1 --threads=$($Config.SelGPUCC) --no-cpu --cuda --cuda-loader=xmrig-cuda.dll --no-nvml -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -a cryptonight/r -p $($Pools.($Algo).Pass)$($Commands.$_) --keepalive --http-port=$($Variables.NVIDIAMinerAPITCPPort) --donate-level 0"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "XMRig"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.($Algo).User
    }
}
