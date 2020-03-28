If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-nbminer277\nbminer.exe"
$Uri = "https://github.com/NebuTech/NBMiner/releases/download/v27.7/NBMiner_27.7_Win.zip"
$Commands = [PSCustomObject]@{ 
    #"grincuckatoo31"   = "-a cuckatoo --fee 1 -o nicehash+tcp://" #grincuckatoo31 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    #"grincuckarood29"  = "-a cuckarood --fee 1 -o nicehash+tcp://" #grincuckaroo29
    #"grincuckaroo29"   = "-a cuckaroo --fee 1 -o nicehash+tcp://" #grincuckaroo29
    #"cuckoocycle"      = "-a cuckoo_ae --fee 1 --cuckoo-intensity 0 -o nicehash+tcp://" #cuckoocycle
    "eaglesong+ethash" = "-a eaglesong_ethash --fee 1 -di 24 -o stratum+tcp://" #eaglesong + ethash
    #"ethash"           = "-a ethash -o stratum+tcp://" #ethash (ZergPool Yiimp Auto Exchange) 
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
        # Ethash: use ethproxy for all non-nicehash pools (nicehash+tcp on zergpool does not produce any shares)
        If ($Pools.$($Algo2).Name -eq "NiceHash") { 
            $Algo2Parameter = " -do nicehash+tcp://$($Pools.$($Algo2).Host):$($Pools.$($Algo2).Port) -du $($Pools.$($Algo2).User)"
        }
        Else { 
            $Algo2Parameter = " -do ethproxy+tcp://$($Pools.$($Algo2).Host):$($Pools.$($Algo2).Port) -du $($Pools.$($Algo2).User)"
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
        Type      = "NVIDIA"
        Name      = $Name
        Path      = $Path
        Arguments = "$($Commands.$_)$($Pools.$Algo.Host):$($Pools.$Algo.Port) -no-nvml --api 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -u $($Pools.$Algo.User):$($Pools.$Algo.Pass)$Algo2Parameter"
        HashRates = $HashRates
        API       = "nbminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
    }
}
