if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-Ethminer\ethminer.exe"
$Uri = "https://github.com/ethereum-mining/ethminer/releases/download/v0.16.0/ethminer-0.16.0rc1.commit.68ca5dcf-windows-amd64.zip"
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
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week} 
        API       = "ethminer"
        Port      = $Port
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
