if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
 
$Path = ".\Bin\CPU-bubasikBinarium\cpuminer-aes-sse42.exe"
$Uri = "https://github.com/bubasik/cpuminer-easy-binarium/releases/download/1.0/cpuminer-easy-binarium-win_x64.zip"

$Commands = [PSCustomObject]@{
    "binarium-v1" = " -a Binarium_hash_v1" #binarium-v1
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    $ThreadCount = $Variables.ProcessorCount - 1 
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "--cpu-affinity AAAA -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "Ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
