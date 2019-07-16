if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

#$Path = ".\Bin\CPU-JayDDee3954\cpuminer-zen.exe" 
$Path = ".\Bin\CPU-JayDDee3954\cpuminer-aes-sse42.exe"
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.9.5.4/cpuminer-opt-3.9.5.4-windows.zip"

$Commands = [PSCustomObject]@{
    "allium"        = "" #Allium
    "m7m"           = "" #m7m
    "yespower"      = "" #Yespower
    "yespowerr16"   = "" #YespowerR16
    "skein2"        = "" #Skein2
    "yescrypt"      = "" #Yescrypt
    "yescryptr8"    = "" #YescryptR8
    "yescryptr16"   = "" #YescryptR16
    "yescryptr32"   = "" #YescryptR32 
    "lyra2z330"     = "" #Lyra2z330 
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    switch ($_) {
        "m7m" { $ThreadCount = $Variables.ProcessorCount - 1 }
        default { $ThreadCount = $Variables.ProcessorCount - 2 }
    }

	   $Algo = Get-Algorithm($_)
    If ($Algo -eq "lyra2z330" -and $Pools.($Algo).Host -like "*zpool*") { return }
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "--cpu-affinity AAAA --hash-meter -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -a $_ -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day }
        API       = "ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
