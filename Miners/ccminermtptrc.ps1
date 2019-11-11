if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-ccminermtptrc126\ccminer.exe"
$Uri = "https://github.com/tecracoin/ccminer/releases/download/1.2.6/ccminer.exe"

$Commands = [PSCustomObject]@{
    "mtp-trc" = " -d $($Config.SelGPUCC)" #mtp-trc
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 4 -R 1 -b $($Variables.NVIDIAMinerAPITCPPort) -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -a $Algo -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
