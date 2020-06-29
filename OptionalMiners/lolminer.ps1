If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\AMD-lolminer101\lolMiner.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.01/lolMiner_v1.01_Win64.zip"
$Commands = [PSCustomObject]@{ 
    "grincuckatoo31"  = " -a C31" #grincuckatoo31
    "grincuckatoo32"  = " -a C32" #grincuckatoo32
    "equihash144"     = " -a EQUI144_5 -c AUTO144_5"  #equihash144
    "equihash125"     = " --coin ZEL"  #equihash125
    "equihash192"     = " -a EQUI192_7 --coin AUTO192_7"  #equihash192
    "grincuckarood29" = " -a C29D"  #grincuckarood29
    "cuckaroom"       = " -a C29M"  #cuckaroom
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "AMD"
        Path      = $Path
        Arguments = "--devices AMD --longstats 120 --shortstats 10 --apiport $($Variables.AMDMinerAPITCPPort) -p $($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) --pass $($Pools.$Algo.Pass)$($Commands.$_)" #
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * .99 } # substract 2% devfee
        API       = "lol"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
