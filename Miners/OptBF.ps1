if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1;RegisterLoaded(".\Includes\include.ps1")}
 
$Path = ".\Bin\CPU-cpuminerOptBF3812\cpuminer-aes-sse42.exe"
$Uri = "https://github.com/bellflower2015/cpuminer-opt/releases/download/v3.8.12-bf/cpuminer-opt-v3.8.12-bf-win64.zip"

$Commands = [PSCustomObject]@{
    "yespowerr16" = "" #YespowerR16
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    switch ($_) {
        "hodl" {$ThreadCount = $Variables.ProcessorCount}
        "binarium-v1" {$ThreadCount = $Variables.ProcessorCount}
        default {$ThreadCount = $Variables.ProcessorCount - 2}
    }

	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "CPU"
        Path = $Path
        Arguments = "--cpu-affinity AAAA -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -a $($Algo) -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Week * 0.68 } # Account for rejected share. Work with pool ops to fix.
        API = "Ccminer"
        Port = $Variables.CPUMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
