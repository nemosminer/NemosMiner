If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\NVIDIA-ethminer19a1fix\ethminer.exe"
$Uri = "https://github.com/Minerx117/ethminer/releases/download/v0.19.0-alpha.1/ethminer-0.19.0-alpha.1-cuda10.0-windows-amd64.zip"
$Commands = [PSCustomObject]@{ 
    "ethash" = "" #ethash
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    If ($Algo -eq "ethash" -and $Pools.$Algo.Host -like "*zergpool*" -or $Pools.$Algo.Host -like "*nicehash*") { return }
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
