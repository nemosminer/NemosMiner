  
If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\AMD-nsfminer138\nsfminer.exe"
$Uri = "https://github.com/no-fee-ethereum-mining/nsfminer/releases/download/v1.3.8/nsfminer_1.3.8-windows_10-cuda_11.2-opencl.zip"
$Commands = [PSCustomObject]@{ 
    "ethash" = "" #ethash
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    If ($Algo) { 
        If ($Pools.$($Algo).Name -eq "MPH") { 
            $AlgoParameter = "-P stratum+tcp://$($Pools.$Algo.User):$($Pools.$Algo.Pass)@$($Pools.$Algo.Host):$($Pools.$Algo.Port)"
        }
        Else { 
            $AlgoParameter = "-P stratum2+tcp://$($Pools.$Algo.User):$($Pools.$Algo.Pass)@$($Pools.$Algo.Host):$($Pools.$Algo.Port)"
        }
        [PSCustomObject]@{ 
            Type      = "AMD"
            Path      = $Path
            Arguments = "-v 4 --devices $($Config.SelGPUDSTM) --api-port -$($Variables.AMDMinerAPITCPPort) -G $AlgoParameter$($Commands.$_)"
            HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
            API       = "ethminer"
            Port      = $Variables.AMDMinerAPITCPPort #4068
            Wrap      = $false
            URI       = $Uri
        }
    }
}
