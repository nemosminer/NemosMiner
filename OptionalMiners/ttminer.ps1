If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-TTMiner40\TT-Miner.exe"
$Uri = "https://tradeproject.de/download/Miner/TT-Miner.zip"
$Commands = [PSCustomObject]@{ 
    "mtp"        = " -a MTP" #mtp  
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    If ($Algo -eq "ethash" -and $Pools.$Algo.Host -like "*zergpool*") { return }
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-DSS -PP 4 --nvidia -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * .99 } # substract 1% devfee
        API       = "TTminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
