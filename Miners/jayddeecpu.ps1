if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1;RegisterLoaded(".\Includes\include.ps1")}

$Path = ".\Bin\CPU-JayDDee395\cpuminer-aes-sse42.exe"
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.9.5/cpuminer-opt-3.9.5-windows.zip"

$Commands = [PSCustomObject]@{
    "allium" = "" #Allium
    "argon2d-crds" = ",d=7 " #argon2d-crds
    "argon2d-dyn" = "" #argon2d-dyn
    "argon2d4096" = "" #argon2d4096 
    "cryptonightv7" = "" #Cryptonightv7
    "x16r" = "" #X16r
    "lyra2v3" = "" #Lyra2RE3
    "quark" = "" #Quark
    "lyra2z" = "" #Lyra2z
    "m7m" = "" #m7m
    "sonoa" = "" #Sonoa
    "phi2" = "" #Phi2
    "yespower" = "" #Yespower
    "yespowerr16" = "" #YespowerR16
    "skein2" = "" #Skein2
    "skein" = "" #Skein
    "yescrypt" = "" #Yescrypt
    "yescryptr8" = "" #YescryptR8
    "yescryptr16" = "" #YescryptR16
    "yescryptr32" = "" #YescryptR32 
    "lyra2z330" = "" #Lyra2z330 
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    switch ($_) {
        "m7m" {$ThreadCount = $Variables.ProcessorCount - 1 }
        default {$ThreadCount = $Variables.ProcessorCount - 2 }
    }

	   $Algo = Get-Algorithm($_)
           If ($Algo -eq "lyra2z330" -and $Pools.($Algo).Host -like "*zpool*") {return}
    [PSCustomObject]@{
        Type = "CPU"
        Path = $Path
        Arguments = "--cpu-affinity AAAA -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -a $_ -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API = "ccminer"
        Port = $Variables.CPUMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
