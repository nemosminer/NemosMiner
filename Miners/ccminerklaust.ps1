if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-CcminerKlausTv3\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminer-KlausT-8.21-mod-r18-src-fix/releases/download/v3/ccminerKlausT.7z"

$Commands = [PSCustomObject]@{
    #"neoscrypt" = " -a neoscrypt -d $($Config.SelGPUCC)" #NeoScrypt
    #"yescrypt" = " -a yescrypt -d $($Config.SelGPUCC)" #Yescrypt 
    #"yescryptR16" = " -i 13.25 -a yescryptr16 -d $($Config.SelGPUCC)" #YescryptR16
    #"yescryptR16v2" = " -a yescryptr16v2 -d $($Config.SelGPUCC)" #YescryptR16v2
    #"yescryptR24" = " -a yescryptr24 -d $($Config.SelGPUCC)" #YescryptR24
    #"yescryptR8" = " -a yescryptr8 -d $($Config.SelGPUCC)" #YescryptR8  
    "lyra2z330" = " -i 11.07 -a lyra2z330 -d $($Config.SelGPUCC)" #Lyra2z330
    "lyra2v3"   = " -i 24 -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2v3
    "lyra2rev3" = " -i 24 -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2rev3 
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 4 -b $($Variables.NVIDIAMinerAPITCPPort) -N 2 -R 1 -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
