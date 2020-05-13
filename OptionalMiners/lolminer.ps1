If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-lolminer098\lolMiner.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/0.98/lolMiner_v098_Win64.zip"
$Commands = [PSCustomObject]@{ 
    "grincuckatoo31" = " --coin GRIN-AT31" #grincuckatoo31
    "grincuckatoo32" = " --coin GRIN-AT32" #grincuckatoo32
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--tls 0 --digits 2 --longstats 60 --shortstats 5 --connectattempts 3 --devices $($Config.SelGPUCC) --apiport $($Variables.NVIDIAMinerAPITCPPort) --pool $($Pools.$Algo.Host) --port $($Pools.$Algo.Port) --user $($Pools.$Algo.User) --pass $($Pools.$Algo.Pass)$($Commands.$_)" #
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * .99 } # substract 2% devfee
        API       = "lol"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
