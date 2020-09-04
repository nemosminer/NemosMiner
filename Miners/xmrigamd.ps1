If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\AMD-XMRigv633\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v6.3.3/XMRigv633.7z"
$Commands = [PSCustomObject]@{ 
    "kawpow"              = " -a kawpow --nicehash" #kawpow
    "cryptonight_conceal" = " -a cn/ccx --nicehash" #cryptonight_conceal
}
$Port = $Variables.AMDMinerAPITCPPort
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
   [PSCustomObject]@{ 
        Type      = "AMD"
        Path      = $Path
        Arguments = "-R 1 --no-cpu --opencl -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_) --keepalive --http-port=$($Variables.AMDMinerAPITCPPort) --donate-level 0"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week } #Recompiled 0% fee
        API       = "XMRig"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
    }
}
