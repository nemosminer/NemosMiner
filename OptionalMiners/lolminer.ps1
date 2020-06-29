using module ..\Includes\Include.psm1

$Path = ".\Bin\AMD-lolminer101\lolMiner.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.01/lolMiner_v1.01_Win64.zip"
$Commands = [PSCustomObject]@{ 
     "grincuckatoo31"    = " -a C31" #grincuckatoo31
     "grincuckatoo32"    = " -a C32" #grincuckatoo32
     "equihash144"       = " -c AUTO144_5"  #equihash144
     "equihash125"       = " -c ZEL"  #equihash125
     "equihash192"       = " -c AUTO192_7"  #equihash192
    #"grincuckarood29"   = " -c MWC-C29D"  #grincuckarood29
     "cuckaroom"         = " -c GRIN-C29M"  #cuckaroom
     "beamv3"            = " -a BEAM-III"  #beamv3
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "AMD"
        Path      = $Path
        Arguments = "--tls 0 --devices AMD --longstats 120 --shortstats 10 --apiport $($Variables.AMDMinerAPITCPPort) --pool $($Pools.$Algo.Host):$($Pools.$Algo.Port) --user $($Pools.$Algo.User) --pass $($Pools.$Algo.Pass)$($Commands.$_)" #
        Algorithm = $Algo
        API       = "lol"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        Fee       = 0.02 #Dev fee
    }
}
