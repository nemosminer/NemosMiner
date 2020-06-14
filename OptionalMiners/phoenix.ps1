using module ..\Includes\Include.psm1

$Path = ".\Bin\NVIDIA-Phoenix50d\PhoenixMiner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0d/PhoenixMiner_5.0d_Windows.zip"
$Commands = [PSCustomObject]@{ 
   #"ethash"  = " -di $($($Config.SelGPUCC).Replace(',',''))" #Ethash
   #"progpow" = " -coin bci -di $($($Config.SelGPUCC).Replace(',',''))" #Progpow 
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-gbase 0 -nvdo 1 -esm 3 -allpools 1 -allcoins 1 -platform 2 -mport -$($Variables.NVIDIAMinerAPITCPPort) -epool $($Pools.$Algo.Host):$($Pools.$Algo.Port) -ewal $($Pools.$Algo.User) -epsw $($Pools.$Algo.Pass)$($Commands.$_)"
        Algorithm = $Algo
        API       = "ethminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        Fee       = 0.0065 # Dev fee
    }
}
