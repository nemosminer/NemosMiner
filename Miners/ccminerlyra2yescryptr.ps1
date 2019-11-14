if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-CcminerLyra2yescrypt821v3\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccminer-KlausT-8.21-mod-r18-src-fix/releases/download/8.21-v3/ccminerLyra2yescrypt-8.21-v3.7z"

$Commands = [PSCustomObject]@{
    "lyra2z330"   = " -i 10 -t 1 -a lyra2z330" #Lyra2z330 single GPU only, needs work for multicards rigs
    "lyra2v3"     = " -i 24 -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2v3
    "lyra2rev3"   = " -i 24 -a lyra2v3 -d $($Config.SelGPUCC)" #Lyra2rev3
    "yescryptr8"  = " -a yescryptr8 -d $($Config.SelGPUCC)" #YescryptR8
    "yescryptr16" = " -i 13.2 -a yescryptr16 -d $($Config.SelGPUCC)" #YescryptR16
    "yescryptr32" = " -i 12.49 -a yescryptr32 -d $($Config.SelGPUCC)" #YescryptR32
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 4 -b $($Variables.NVIDIAMinerAPITCPPort) -T 50000 -R 1 -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }
}
