if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-ccminermtp11161\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerMTP/releases/download/v1.1.16.1/ccminerMTP1.1.16.1.7z"

$Commands = [PSCustomObject]@{
    "mtp" = " -d $($Config.SelGPUCC)" #mtp (requires 6gb+ system ram to run, 4gb is not enough)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
        $Algo = Get-Algorithm($_)
        If ($Algo -eq "mtp" -and $Pools.($Algo).Host -like "*nicehash*") {return}
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 4 -i 21.15 -N 2 -R 1 -b $($Variables.NVIDIAMinerAPITCPPort) -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -a $Algo -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
