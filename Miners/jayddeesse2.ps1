if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1;RegisterLoaded(".\Includes\include.ps1")}

$Path = ".\Bin\CPU-JayDDee3931\cpuminer-aes-sse42.exe"
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.9.3.1/cpuminer-opt-3.9.3.1-windows.zip"

$Commands = [PSCustomObject]@{
    "allium" = "" #Allium
    "argon2d-crds" = ",d=7 " #argon2d-crds
    "argon2d-dyn" = "" #argon2d-dyn
    "argon2d4096" = "" #argon2d4096 
    "cryptonightv7" = "" #Cryptonightv7
    "lyra2v3" = "" #Lyra2RE3
    "lyra2z" = "" #Lyra2z
    "m7m" = "" #m7m
    "sonoa" = "" #Sonoa
    "phi2" = "" #Phi2
    "yespower" = "" #Yespower
    "yespowerr16" = "" #YespowerR16
    "skein2" = "" #Skein2
    "yescrypt" = "" #Yescrypt
    "yescryptr8" = "" #YescryptR8
    "yescryptr16" = "" #YescryptR16
    "yescryptr32" = "" #YescryptR32
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    switch ($_) {
        "m7m" {$ThreadCount = $Variables.ProcessorCount - 1 }
        default {$ThreadCount = $Variables.ProcessorCount - 2 }
    }

	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "CPU"
        Path = $Path
        Arguments = "--cpu-affinity AAAA -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -a $_ -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API = "Ccminer"
        Port = $Variables.CPUMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
