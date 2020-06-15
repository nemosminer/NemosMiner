using module ..\Includes\Include.psm1

$Path = ".\Bin\NVIDIA-TTMiner503\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$Commands = [PSCustomObject]@{ 
    #"mtp"    = " -a MTP -i 21" #Mtp  
    "ethash" = " -a ETHASH" #Ethash
    "kawpow" = " -a KAWPOW" #Kawpow
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
     If ($Algo -eq "kawpow" -and $Pools.$Algo.Host -like "*miningpoolhub*") { return }
     If ($Algo -eq "ethash" -and $Pools.$Algo.Host -like "*zergpool*") { return }
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--nvidia -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        Algorithm = $Algo
        API       = "TTminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
