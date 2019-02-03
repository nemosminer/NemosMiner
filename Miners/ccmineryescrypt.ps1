if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-CcminerKlausTyescrypt\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerKlausTyescrypt/releases/download/v10/ccminerKlausTyescryptv10.7z"

$Commands = [PSCustomObject]@{
    "yescrypt" = " -a yescrypt -i 12.5 -d $($Config.SelGPUCC)" #Yescrypt
    "yescryptR16" = " -a yescryptr16 -i 12.5 -d $($Config.SelGPUCC)" #YescryptR16
    "yescryptR16v2" = " -a yescryptr16v2 -i 12.5 -d $($Config.SelGPUCC)" #YescryptR16v2
    "yescryptR24" = " -a yescryptr24 -i 12.5 -d $($Config.SelGPUCC)" #YescryptR24 
    "yescryptR8" = " -a yescryptr8 -i 12.5 -d $($Config.SelGPUCC)" #YescryptR8

}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--cpu-priority 5 -b $($Variables.NVIDIAMinerAPITCPPort) -N 1 -R 1 -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API = "ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
