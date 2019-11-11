if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

#$Path = ".\Bin\CPU-JayDDee3991\cpuminer-zen.exe" #AMD
$Path = ".\Bin\CPU-JayDDee3991\cpuminer-aes-sse42.exe" #Intel
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.9.9.1/cpuminer-opt-3.9.9.1-windows.zip"

$Commands = [PSCustomObject]@{
    "allium"      = " -a allium" #Allium
    "yespowerr16" = " -a yespowerr16" #YespowerR16
    "skein2"      = " -a skein2" #Skein2
    "x21s"        = " -a x21s" #X21s
    "hex"         = " -a hex" #Hex
    "blake2b"     = " -a blake2b" #blake2b
    "lyra2z330"   = " -a lyra2z330" #Lyra2z330 
    "bmw512"      = " -a bmw512" #Bmw512 
    "x16rt"       = " -a x16rt" #X16rt 
    "x12"         = " -a x12" #X12
    "veil"        = " -a veil" #Veil 
    "phi2"        = " -a phi2" #Phi2 
    "x16rv2"      = " -a x16rv2" #X16rv2
    "phi2-lux"    = " -a phi2" #Phi-lux
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    $ThreadCount = $Variables.ProcessorCount - 2
    

    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "CPU"
        Path      = $Path
        Arguments = "--cpu-affinity AAAA --hash-meter -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
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
