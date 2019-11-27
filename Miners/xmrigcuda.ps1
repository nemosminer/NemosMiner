if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-XMRig501\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v5.0.1/xmrig-5.0.1-msvc-cuda10_1-win64.7z"

$Commands = [PSCustomObject]@{
    #"randomx"            = " --coin=monero --nicehash" #RandomX
    #"randomx"            = " -a rx/0 --nicehash" #RandomX
    "cryptonightr"        = " -a cryptonight/r --nicehash" #cryptonight/r (NiceHash)
    "cryptonight-monero"  = " -a cryptonight/r" #cryptonight/r (Mining Pool Hub)
}

$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-R 1 --cuda-devices=$($Config.SelGPUCC) --no-cpu --cuda --cuda-loader=xmrig-cuda.dll --no-nvml -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_) --keepalive --http-port=$($Variables.NVIDIAMinerAPITCPPort) --donate-level 0"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "XMRig"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.$Algo.User
    }
}
