if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\CPU-cpuminerOptBF\cpuminer-aes-sse42.exe"
$Uri = "https://github.com/bellflower2015/cpuminer-opt/releases/download/v3.8.11-bf/cpuminer-opt-v3.8.11-bf-win64.zip"

$Commands = [PSCustomObject]@{
    # "allium" = "" #Allium
    #"bitcore" = "" #Bitcore
    #"blake2s" = "" #Blake2s
    #"blakecoin" = "" #Blakecoin
    "yespowerr16" = "" #YespowerR16
    #"vanilla" = "" #BlakeVanilla
    #"c11" = "" #C11
    # "cryptonight" = "" #CryptoNight
    #"cryptonightv7" = "" #cryptonightv7
    #"decred" = "" #Decred
    #"equihash" = "" #Equihash
    #"ethash" = "" #Ethash
    #"groestl" = "" #Groestl
    # "hmq1725" = "" #HMQ1725
    # "hodl" = "" #Hodl
    #"jha" = "" #JHA
    #"keccak" = "" #Keccak
    #"lbry" = "" #Lbry
    #"lyra2v2" = "" #Lyra2RE2
    # "lyra2z" = "" #Lyra2z
    # "m7m" = "" #m7m
    #"myr-gr" = "" #MyriadGroestl
    #"neoscrypt" = "" #NeoScrypt
    #"nist5" = "" #Nist5
    #"pascal" = "" #Pascal
    #"sib" = "" #Sib
    #"skein" = "" #Skein
    #"skunk" = "" #Skunk
    #"timetravel" = "" #Timetravel
    #"tribus" = "" #Tribus
    #"veltor" = "" #Veltor
    #"x11evo" = "" #X11evo
    #"x17" = "" #X17
    # "x16r" = "" #X16r
    # "yescrypt" = "" #Yescrypt
    # "yespower" = "" #Yespower
    # "yescryptr16" = "" #YescryptR16
    # "yescryptr32" = "" #YescryptR32
}

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {

    switch ($_) {
        "hodl" {$ThreadCount = $Variables.ProcessorCount}
        "binarium-v1" {$ThreadCount = $Variables.ProcessorCount}
        default {$ThreadCount = $Variables.ProcessorCount - 2}
    }

	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "CPU"
        Path = $Path
        Arguments = "--cpu-affinity AAAA -q -t $($ThreadCount) -b $($Variables.CPUMinerAPITCPPort) -a $($Algo) -o $($Pools.($Algo).Protocol)://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Week * 0.68 } # Account for rejected share. Work with pool ops to fix.
        API = "Ccminer"
        Port = $Variables.CPUMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
