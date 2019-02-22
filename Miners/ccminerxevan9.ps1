if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-ccminerxevan9\ccminer_x86.exe"
$Uri = "https://github.com/nemosminer/ccminer-xevan/releases/download/ccminer-xevan/ccminer_x86.7z"

$Commands = [PSCustomObject]@{
    "xevan" = " -i 21 -N 1 -d $($Config.SelGPUCC) " #Xevan(fastest on most 10series cards/enemyzealot faster on 1080ti's and 20 series)
    #"skein" = " -N 1 -d $($Config.SelGPUCC) -i 27" #Skein
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -R 1 -a $_ -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
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
