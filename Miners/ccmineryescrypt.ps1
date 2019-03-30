if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-Ccmineryescrypt9\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerKlausTyescrypt/releases/download/v9/ccminerKlausTyescryptv9.7z"

$Commands = [PSCustomObject]@{
    "yescrypt" = " -d $($Config.SelGPUCC)" #Yescrypt
    "yescryptR16" = " -i 13.25 -d $($Config.SelGPUCC)" #YescryptR16
    "yescryptR16v2" = " -d $($Config.SelGPUCC)" #YescryptR16v2
    "yescryptR24" = " -d $($Config.SelGPUCC)" #YescryptR24 
    "yescryptR8" = " -d $($Config.SelGPUCC)" #YescryptR8
    "yescryptR32" = " -i 12.49 -d $($Config.SelGPUCC)" #YescryptR32
}
    switch ($_) {
        "yescryptR32" {$Fee = 0.14} # account for 14% stale shares
              default {$Fee = 0.00}
    }

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--cpu-priority 4 -b $($Variables.NVIDIAMinerAPITCPPort) -N 2 -R 1 -a $_ -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee)} # account for 14% stale shares yescryptR32
        API = "ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
