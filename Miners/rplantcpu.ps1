using module ..\Includes\Include.psm1

$Path = ".\Bin\CPU-Opt4511\cpuminer-sse42.exe" #Intel
#$Path = ".\Bin\CPU-Opt455\cpuminer-ryzen.exe" #AMD
$Uri = "https://github.com/rplant8/cpuminer-opt-rplant/releases/download/4.5.11/cpuminer-opt-win.zip"
$Commands = [PSCustomObject]@{ 
    "yespoweriots" = " -a yespoweriots" #yespoweriots
    "yespower"     = " -a yespower" #yespower
    "yespowerr16"  = " -a yespowerr16" #yespowerR16
    "yescryptr8"   = " -a yescryptr8" #YescryptR8 
    "yescryptr8g"  = " -a yescryptr8g" #YescryptR8g  
    "yescrypt"     = " -a yescrypt" #Yescrypt
    "yescryptr32"  = " -a yescryptr32" #YescryptR32
    "yespoweritc"  = " -a yespoweritc" #Yespoweritc  
    "lyra2z330"    = " -a lyra2z330" #lyra2z330
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    $ThreadCount = $Variables.ProcessorCount - 1 
    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = "--cpu-affinity AAAA -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -o $($Pools.$Algo.Protocol)://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        Algorithm = $Algo
        API       = "ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
