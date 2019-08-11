if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-nanominer153\cmdline_launcher.bat"
$Uri = "https://github.com/nanopool/nanominer/releases/download/v1.5.3/nanominer-windows-1.5.3.zip"

$Commands = [PSCustomObject]@{
    "cryptonightr"       = "cryptonightr" #cryptonight/r (NiceHash)
    "cryptonight-monero" = "cryptonightr" #monero (Mining Pool Hub)
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $Algo = Get-Algorithm($_)
    
    switch ($_) {
        "grincuckaroo29" { $Fee = 0.02 } # substract devfee
        default { $Fee = 0.01 } # substract devfee
    }

    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-mport -$($Variables.NVIDIAMinerAPITCPPort) -algo $($Commands.$_) -wallet $($Pools.($Algo).User) -rigName $($Pools.($Algo).Pass) -pool1 $($Pools.($Algo).Host):$($Pools.($Algo).Port) -devices $($Config.SelGPUCC)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee) } # substract devfee
        API       = "nanominer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
