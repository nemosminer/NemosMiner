using module ..\Includes\Include.psm1

$Path = ".\Bin\NVIDIA-kawpowminer123\kawpowminer.exe"
$Uri = "https://github.com/RavenCommunity/kawpowminer/releases/download/1.2.3/kawpowminer-windows-1.2.3.zip"
$Commands = [PSCustomObject]@{ 
     #"kawpow" = "" #kawpow
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    If ($Algo) { 
        $AlgoParameter = " -P stratum+tcp://$($Pools.$Algo.User):$($Pools.$Algo.Pass)@$($Pools.$Algo.Host):$($Pools.$Algo.Port)"
        [PSCustomObject]@{ 
            Type      = "NVIDIA"
            Path      = $Path
            Arguments = "--farm-recheck 10000 --farm-retries 40 --work-timeout 100000 --response-timeout 720 --cuda-devices $($Config.SelGPUDSTM) --api-port -$($Variables.NVIDIAMinerAPITCPPort) -U $AlgoParameter$($Commands.$_)"
            Algorithm = $Algo
            API       = "ethminer"
            Port      = $Variables.NVIDIAMinerAPITCPPort #4068
            Wrap      = $false
            URI       = $Uri
        }
    }
}
