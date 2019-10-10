if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\CPU-CPUPower2b100\cpuminer.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v1.0.0/cpuminer-opt-power2b-v1.0.0-w64.7z"

$Commands = [PSCustomObject]@{
    "power2b" = " -a power2b" #power2b
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    $ThreadCount = $Variables.ProcessorCount - 2
    

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
