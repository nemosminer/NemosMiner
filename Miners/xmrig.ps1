if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-XMRig2145\xmrig-nvidia.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v2.14.5/xmrig-nvidia-2.14.5-msvc-win64.7z"

$Commands = [PSCustomObject]@{
    "cryptonightr"       = " --nicehash" #cryptonight/r (NiceHash)
    "cryptonight-monero" = "" #cryptonight/r (Mining Pool Hub)
}
$Port = 4068 #2222
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-R 1 --cuda-devices=$($Config.SelGPUCC) -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_) -a cryptonight/r --keepalive --api-port=$($Variables.NVIDIAMinerAPITCPPort) --donate-level=0"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "XMRig"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
