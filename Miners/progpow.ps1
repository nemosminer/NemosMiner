If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-progpowminer016\progpowminer-cuda.exe"
$Uri = "https://nemosminer.com/data/optional/progpowminer0.16-FinalCuda10.7z"
$Commands = [PSCustomObject]@{ 
    "progpow" = "" #progpow
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cuda-devices $($Config.SelGPUDSTM) --api-port -$($Variables.NVIDIAMinerAPITCPPort) -U -P stratum+tcp://$($Pools.$Algo.User):$($Pools.$Algo.Pass)@$($Pools.$Algo.Host):$($Pools.$Algo.Port)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Week }
        API       = "ethminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
    }
}
