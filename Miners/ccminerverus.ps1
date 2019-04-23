if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-Ccminerverus3.4\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerverus/releases/download/v3.4/ccminerverus3.4.7z"

$Commands = [PSCustomObject]@{
     "verushash" = " -a verus -i 18.75 -d $($Config.SelGPUCC)" #verus
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--cpu-priority 4 -b $($Variables.NVIDIAMinerAPITCPPort) -N 2 -R 1 -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
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
