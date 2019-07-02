if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1;RegisterLoaded(".\Includes\include.ps1")}

$Path = ".\Bin\NVIDIA-nanominer141\cmdline_launcher.bat"
$Uri = "https://github.com/nanopool/nanominer/releases/download/v1.4.1/nanominer-windows-1.4.1.zip"

$Commands = [PSCustomObject]@{
    "cryptonightr" = "" #cryptonight/r (NiceHash)
    "cryptonight-monero" = "" #monero (Mining Pool Hub)
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-mport -$($Variables.NVIDIAMinerAPITCPPort) -algo cryptonightr -wallet $($Pools.($Algo).User) -rigName $($Pools.($Algo).Pass) -pool1 $($Pools.($Algo).Host):$($Pools.($Algo).Port)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99 } # substract 1% devfee
        API       = "nanominer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
