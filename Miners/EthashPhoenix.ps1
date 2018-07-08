if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\\Bin\\Ethash-Phoenix\\PhoenixMiner.exe"
$Uri = "http://nemos.dx.am/opt/nemos/PhoenixMiner_3.0c.7z"

$Commands = [PSCustomObject]@{
    "ethash" = "" #Ethash(fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
		Arguments = "-pool $($Pools.Ethash.Protocol)://$($Pools.Ethash.Host):$($Pools.Ethash.Port) -wal $($Pools.Ethash.User) -pass $($Pools.Ethash.Pass) -wdog 0 -proto 1 -cdmport $($Variables.NVIDIAMinerAPITCPPort) -nvidia -eres 1 -log 0 -gsi 15 $($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .9935} # substract 0.65% devfee
        API = "Claymore"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
		User = $Pools.(Get-Algorithm($_)).User
    }
}
