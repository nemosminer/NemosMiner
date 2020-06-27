using module ..\Includes\Include.psm1

$Path = ".\Bin\CPU-XMRigv622\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v6.2.2/XMRigv622.7z"
$Commands = [PSCustomObject]@{ 
     "kawpow" = " -a kawpow --nicehash" #kawpow
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type       = "NVIDIA"
        Path       = $Path
        Arguments  = "-R 1 --cuda-devices=$($Config.SelGPUCC) --no-cpu --cuda --cuda-loader=xmrig-cuda.dll --no-nvml -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_) --keepalive --http-port=$($Variables.NVIDIAMinerAPITCPPort) --donate-level 0"
        Algorithm  = $Algo
        API        = "XMRig"
        Port       = $Variables.NVIDIAMinerAPITCPPort
        Wrap       = $false
        URI        = $Uri
        WarmupTime = 60 #seconds
    }
}
