If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\AMD-nbminer341\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v34.1/NBMiner_34.1_Win.zip"
$Commands = [PSCustomObject]@{ 
     "octopus"   = "-a octopus --fee 1 -o nicehash+tcp://" #octopus
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm ($_ -split '\+' | Select-Object -Index 0); $Algo2 = Get-Algorithm ($_ -split '\+' | Select-Object -Index 1); $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    switch ($_) { 
        "ethash" { $Fee = 0.0065 }
        "eaglesong_ethash" { $Fee = 0.01 }
        default { $Fee = 0.01 }
    }

    If ($Algo2) { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)-$Algo"
        $HashRates = [PSCustomObject]@{ $Algo2 = $Stats."$($Name)_$($Algo2)_HashRate".Week * (1 - $Fee); $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week * (1 - $Fee) }
        If ($Pools.$($Algo2).Name -eq "MPH") { 
            $Algo2Parameter = " -do nicehash+tcp://$($Pools.$($Algo2).Host):$($Pools.$($Algo2).Port) -du $($Pools.$($Algo2).User):$($Pools.$Algo2.Pass)"
        }
        Else { 
            $Algo2Parameter = " -do nicehash+tcp://$($Pools.$($Algo2).Host):$($Pools.$($Algo2).Port) -du $($Pools.$($Algo2).User):$($Pools.$Algo2.Pass)"
        }
        If ($Pools.$Algo2.SSL) { $Algo2Parameter = $Algo2Parameter -replace '\+tcp\://$', '+ssl://' }
    }
    Else { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
        $HashRates = [PSCustomObject]@{ $Algo = ($Stats."$($Name)_$($Algo)_HashRate".Week) * (1 - $Fee) }
        $Algo2Parameter = ""
    }

    If ($Pools.$Algo.SSL) { $_ = $_ -replace '\+tcp\://$', '+ssl://' }

    [PSCustomObject]@{ 
        Type      = "AMD"
        Name      = $Name
        Path      = $Path
        Arguments = "$($Commands.$_)$($Pools.$Algo.Host):$($Pools.$Algo.Port) --api 127.0.0.1:$($Variables.AMDMinerAPITCPPort) -d $($Config.SelGPUCC) -u $($Pools.$Algo.User):$($Pools.$Algo.Pass)$Algo2Parameter"
        HashRates = $HashRates
        API       = "nbminer"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
