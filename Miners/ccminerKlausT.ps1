if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-CcminerKlausTv3\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminer-KlausT-8.21-mod-r18-src-fix/releases/download/v3/ccminerKlausT.7z"

$Commands = [PSCustomObject]@{
    "neoscrypt" = " -a neoscrypt -d $($Config.SelGPUCC)" #NeoScrypt (CryptoDredge slighty faster)
    "yescrypt" = " -a yescrypt -d $($Config.SelGPUCC)" #Yescrypt (fastest)
    "yescryptR16" = " -i 13.25 -a yescryptr16 -d $($Config.SelGPUCC)" #YescryptR16 (fastest)
    "yescryptR16v2" = " -a yescryptr16v2 -d $($Config.SelGPUCC)" #YescryptR16v2 (fastest)
    "yescryptR24" = " -a yescryptr24 -d $($Config.SelGPUCC)" #YescryptR24 (fastest)
    "yescryptR8" = " -a yescryptr8 -d $($Config.SelGPUCC)" #YescryptR8 (fastest)
    "lyra2v3" = " -i 24 -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2v3 NICEHASH(fastest)
    "lyra2rev3" = " -i 24 -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2rev3 YIIMP(fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--cpu-priority 4 -b $($Variables.NVIDIAMinerAPITCPPort) -N 1 -R 1 -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
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
