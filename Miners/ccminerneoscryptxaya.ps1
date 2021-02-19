If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-neoscryptxaya01\ccminer-64bit.exe"
$Uri = "https://github.com/xaya/ccminer/releases/download/v0.1/ccminer-64bit.exe"
$Commands = [PSCustomObject]@{ 
    "neoscrypt-xaya" = " -a neoscrypt-xaya" #neoscrypt-xaya 8gb and above gpu's can use -i 21 for 35-45% performance increase over default -i 13
 }
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 4 -T 50000 -R 1 -i 19 -b $($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://neoscrypt-xaya.mine.zergpool.com:4238 -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
    }
}
