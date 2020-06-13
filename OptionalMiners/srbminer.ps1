If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\cpu-SRBMiner-Multi-0-4-6/SRBMiner-MULTI.exe"
$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/0.4.6/SRBMiner-Multi-0-4-6-win64.zip"
$Commands = [PSCustomObject]@{ 
    "randomx"            = " --algorithm randomx --randomx-use-1gb-pages" #randomx 
    "randomarq"          = " --algorithm randomarq --randomx-use-1gb-pages" #randomarq  
    "randomsfx"          = " --algorithm randomsfx --randomx-use-1gb-pages" #randomsfx  
    "eaglesong"          = " --algorithm eaglesong" #eaglesong  
    "yescrypt"           = " --algorithm yescrypt" #yescrypt    
    "yescryptR16"        = " --algorithm yescryptR16" #yescryptR16  
    "yescryptR32"        = " --algorithm yescryptR32" #yescryptR32   
    "yespower"           = " --algorithm yespower" #yespower 
    "yespowerr16"        = " --algorithm yespowerr16" #yespowerr16 
    "cryptonight-monero" = " --algorithm randomx --randomx-use-1gb-pages" #randomx
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    switch ($_) { 
        default { $ThreadCount = $Variables.ProcessorCount - 1 }
    }

    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{ 
        Type      = "CPU"
        Path      = $Path
        Arguments = "--cpu-threads $($ThreadCount) --nicehash true --send-stales true --api-enable --api-port $($Variables.CPUMinerAPITCPPort) --disable-gpu --pool stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) --wallet $($Pools.$Algo.User) --password $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{$Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * .9915 } # substract 0.85% devfee}
        API       = "SRB"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
