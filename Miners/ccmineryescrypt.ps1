if (!(IsLoaded(".\Include.ps1"))) { . .\Include.ps1; RegisterLoaded(".\Include.ps1") }

$Path = ".\Bin\NVIDIA-Ccmineryescryptv9\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerKlausTyescrypt/releases/download/v9/ccminerKlausTyescryptv9.7z"

$Commands = [PSCustomObject]@{
    "yescrypt" = " -d $($Config.SelGPUCC)" #Yescrypt
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 4 -b $($Variables.NVIDIAMinerAPITCPPort) -R 1 -a $_ -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
