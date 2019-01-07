if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-Ethminer017a1\ethminer.exe"
$Uri = "https://github.com/ethereum-mining/ethminer/releases/download/v0.17.0-alpha.1/ethminer-0.17.0-alpha.1-cuda10.0-windows-amd64.zip"
$Commands = [PSCustomObject]@{
    "ethash" = "" #Ethash(fastest)
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cuda-devices $($Config.SelGPUDSTM) --api-port -$Port -U -P stratum://$($Pools.(Get-Algorithm($_)).User):x@$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day} 
        API       = "ethminer"
        Port      = $Port
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
