if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\CPU-nosuch\cpuminer-aes-sse2.exe"
$Uri = "https://github.com/patrykwnosuch/cpuminer-3.8.8.1-nosuch/releases/download/3.8.8.1-m2/cpuminer-nosuch-m2-win64.7z"

$Commands = [PSCustomObject]@{
    "m7m"         = " -a m7m" #M7m
    "binarium-v1" = " -a Binarium_hash_v1" #Binarium-v1
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    switch ($_) {
        "binarium-v1" { $ThreadCount = $Variables.ProcessorCount - 1 }
        default { $ThreadCount = $Variables.ProcessorCount - 1 }
    }

    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "--cpu-affinity AAAA -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
