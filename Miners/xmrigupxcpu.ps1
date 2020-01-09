if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\CPU-XMRigUPX020\xmrig.exe"
$Uri = "https://github.com/Minerx117/xmrig-upx/releases/download/0.2.0/xmrigupx.zip"
$Commands = [PSCustomObject]@{
  "cryptonight_upx" = " -a cryptonight-upx/2 --nicehash"
}
$ThreadCount = $Variables.ProcessorCount - 1
$Port = $Variables.CPUMinerAPITCPPort
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
  [PSCustomObject]@{
    Type      = "CPU"
    Path      = $Path
    Arguments = "-t $($ThreadCount) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_) --keepalive --api-port=$($Variables.CPUMinerAPITCPPort) --donate-level 0"
    HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day } #recomopiled 0% fee
    API       = "XMRig"
    Port      = $Variables.CPUMinerAPITCPPort
    Wrap      = $false
    URI       = $Uri    
    User      = $Pools.$Algo.User
  }
}
