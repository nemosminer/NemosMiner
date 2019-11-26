if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
 
$Path = ".\Bin\NVIDIA-Ethminer0190a0\ethminer.exe"
$Uri = "https://github.com/ethereum-mining/ethminer/releases/download/v0.19.0-alpha.0/ethminer-0.19.0-alpha.0-cuda10.0-windows-amd64.zip"
$Commands = [PSCustomObject]@{
    #"ethash" = "" #Ethash
}

$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {

    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cuda-devices $($Config.SelGPUDSTM) --api-port -$Port -U -P stratum://$($Pools.$Algo.User):x@$($Pools.$Algo.Host):$($Pools.$Algo.Port)$($Commands.$_)"
        HashRates = [PSCustomObject]@{$Algo = $Stats."$($Name)_$($Algo)_HashRate".Day } 
        API       = "ethminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }
}
