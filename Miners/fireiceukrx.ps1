If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\cpu-FireIce104\xmr-stak-rx.exe"
$Uri = "https://github.com/fireice-uk/xmr-stak/releases/download/1.0.4-rx/xmr-stak-rx-win64-1.0.4.7z"
$Commands = [PSCustomObject]@{ 
    #"randomxmonero"      = " --currency monero --use-nicehash" #RandomX
    #"randomx"            = " --currency monero --use-nicehash" #RandomX 
    #"cryptonight-monero" = " --currency monero --use-nicehash" #Cryptonight-Monero
}
$ThreadCount = $Variables.ProcessorCount - 1
$Port = $Variables.CPUMinerAPITCPPort
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = "--noNVIDIA  --noAMD --noTest --noUAC -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_) -i $($Variables.CPUMinerAPITCPPort) --noDevSupport"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week } 
        API       = "fireice"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
    }
}
