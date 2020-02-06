If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\CPU-nanominer180\cmdline_launcher.bat"
$Uri = "https://github.com/nanopool/nanominer/releases/download/v1.8.0/nanominer-windows-1.8.0.zip"
$Commands = [PSCustomObject]@{ 
    #"randomhash" = "-algo RandomHash2" #RandomX
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    switch ($_) { 
        "randomhash" { $Fee = 0.05 } # substract devfee
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
    }
}
