if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\CPU-nheqVerus072\nheqminer.exe"
$Uri = "https://github.com/VerusCoin/nheqminer/releases/download/0.7.2/nheqminer-Windows-v0.7.2.zip"

$Commands = [PSCustomObject]@{
    "verus" = "" #Verushash
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    switch ($_) {
        "hodl" { $ThreadCount = $Variables.ProcessorCount }
        default { $ThreadCount = $Variables.ProcessorCount - 2 }
    }

    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "-t $($ThreadCount) -a $($Variables.CPUMinerAPITCPPort) -v -l $($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "nheq"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
