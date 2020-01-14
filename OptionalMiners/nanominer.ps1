if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\CPU-nanominer170\cmdline_launcher.bat"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/1.7.0/nanominer-windows-1.7.0.zip"
$Commands = [PSCustomObject]@{
    #"randomx" = "-algo randomx" #RandomX
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {  
    switch ($_) {
        "randomx" { $Fee = 0.02 } # substract devfee
        default { $Fee = 0.01 } # substract devfee
    }
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "-mport -$($Variables.CPUMinerAPITCPPort) $($Commands.$_) -wallet $($Pools.$Algo.User) -pool1 $($Pools.$Algo.Host):$($Pools.$Algo.Port) -rigName $($Pools.$Algo.Pass)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee) } # substract devfee
        API       = "nanominer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }
}
