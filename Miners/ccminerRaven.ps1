. .\Include.ps1

$Path = ".\Bin\NVIDIA-ccminerRaven\ccminer.exe"
$Uri = "https://github.com/RavencoinProject/RavencoinMiner/releases/download/v3.0/Ravencoin.Miner.v3.0.win32.zip"

$Commands = [PSCustomObject]@{
    "x16r" = " -r 0 -d $SelGPUCC -i 20" #X16r(testing)
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName
$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.MinerAPITCPPort) -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
        API = "Ccminer"
        Port = $Variables.MinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
