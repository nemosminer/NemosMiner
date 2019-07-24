if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-Ccminerklaustv3\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminer-KlausT-8.21-mod-r18-src-fix/releases/download/v3/ccminerKlausT.7z"

$Commands = [PSCustomObject]@{
    "lyra2z330" = " -i 10 -t 1 -a lyra2z330" #Lyra2z330 single GPU only, needs work for multicards rigs
    "lyra2v3"   = " -i 24 -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2v3
    "lyra2rev3" = " -i 24 -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2rev3 
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
     $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 4 -b $($Variables.NVIDIAMinerAPITCPPort) -R 1 -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
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
