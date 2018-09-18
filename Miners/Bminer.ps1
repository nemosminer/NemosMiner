if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-Bminer1020\bminer.exe"
$Uri = "https://www.bminercontent.com/releases/bminer-lite-v10.2.0-c698b5f-amd64.zip"
$Commands = [PSCustomObject]@{
    "equihashBTG" = " -uri zhash://" #EquihashBTG(EWBFv2 faster)
    "equihash" = " -uri stratum://" #Equihash(fastest)
    #"ethash" = " -uri ethstratum://" #Ethash(Ethminer faster)
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "$($Commands.$_)$($Pools.(Get-Algorithm($_)).User):$($Pools.(Get-Algorithm($_)).Pass.ToString().replace(',','%2C'))@$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -max-temperature 94 -devices $($Config.SelGPUCC) -api 127.0.0.1:$Port -nofee"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week} 
        API = "bminer"
        Port = $Port
        Wrap = $false
        URI = $Uri    
        User = $Pools.(Get-Algorithm($_)).User
    }
}
