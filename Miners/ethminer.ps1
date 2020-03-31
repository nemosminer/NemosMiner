If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-ethminer0190a2\ethminer.exe"
$Uri = "https://github.com/Minerx117/ethminer/releases/download/v0.19.0-alpha.2/ethminer-0.19.0-alpha.2-cuda10.0-windows-amd64.zip"
$Commands = [PSCustomObject]@{ 
    "ethash" = "" #ethash
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    If ($Algo) { 
        If ($Pools.$($Algo).Name -eq "MPH") { 
            $AlgoParameter = " -P stratum+tcp://$($Pools.$Algo.User):$($Pools.$Algo.Pass)@$($Pools.$Algo.Host):$($Pools.$Algo.Port)"
        }
        Else { 
            $AlgoParameter = " -P stratum2+tcp://$($Pools.$Algo.User):$($Pools.$Algo.Pass)@$($Pools.$Algo.Host):$($Pools.$Algo.Port)"
        }
        [PSCustomObject]@{ 
            Type      = "NVIDIA"
            Path      = $Path
            Arguments = "--farm-recheck 5000 --farm-retries 40 --work-timeout 920 --response-timeout 360 --cuda-devices $($Config.SelGPUDSTM) --api-port -$($Variables.NVIDIAMinerAPITCPPort) -U $AlgoParameter$($Commands.$_)"
            HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
            API       = "ethminer"
            Port      = $Variables.NVIDIAMinerAPITCPPort #4068
            Wrap      = $false
            URI       = $Uri
        }
    }
}
