using module ..\Includes\Include.psm1

$Path = ".\Bin\AMD-Phoenix50e\PhoenixMiner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0e/PhoenixMiner_5.0e_Windows.7z"
$Commands = [PSCustomObject]@{ 
    "ethash"  = "" #Ethash
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "AMD"
        Path      = $Path
        Arguments = "-proto 4 -amd -mport -$($Variables.AMDMinerAPITCPPort) -epool $($Pools.$Algo.Host):$($Pools.$Algo.Port) -ewal $($Pools.$Algo.User) -epsw $($Pools.$Algo.Pass)$($Commands.$_)"
        Algorithm = $Algo
        API       = "ethminer"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        Fee       = 0.0065 # Dev fee
    }
}
