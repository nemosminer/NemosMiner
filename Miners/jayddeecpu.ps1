using module ..\Includes\Include.psm1
#$Path = ".\Bin\CPU-JayDDe31311\cpuminer-zen.exe" #AMD
$Path = ".\Bin\CPU-JayDDee31311\cpuminer-aes-sse42.exe" #Intel
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.13.1.1/cpuminer-opt-3.13.1.1-windows.zip"
$Commands = [PSCustomObject]@{ 
    "lyra2z330" = " -a lyra2z330" #Lyra2z330
    "sha3d"     = " -a sha3d" #sha3d
    "scryptn11" = " -a scrypt:2048" #scryptn11 
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    $ThreadCount = $Variables.ProcessorCount - 1
    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = "--hash-meter -q -t $($ThreadCount) --api-bind=$($Variables.CPUMinerAPITCPPort) -o $($Pools.$Algo.Protocol)://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
        API       = "ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
