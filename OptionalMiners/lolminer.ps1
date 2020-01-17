if (!(IsLoaded(".\Include.ps1"))) { . .\Include.ps1; RegisterLoaded(".\Include.ps1") }
 
$Path = ".\Bin\NVIDIA-AMD-lolMiner0951\lolMiner.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/0.95/lolMiner_v0951_Win64.zip"

$Commands = [PSCustomObject]@{
    #"equihash96" = " --coin MNX" #Equihash 96,5
    #"equihash144" = " --coin AUTO144_5" #Equihash 144,5
    #"equihash192" = " --coin AUTO192_7" #Equihash 192,7
    #"beam" = " --coin BEAM" #Equihash 150,5
    #"cuckaroom" = " --coin --coin GRIN-C29M" #cuckaroom
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "AMD"
        Path      = $Path
        Arguments = "--user $($Pools.($Algo).User) --pool $($Pools.($Algo).Host) --port $($Pools.($Algo).Port) --devices $($Config.SelGPUCC) --apiport $($Variables.NVIDIAMinerAPITCPPort) --tls 0 --digits 2 --longstats 60 --shortstats 5 --connectattempts 3 --pass $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99 } # substract 1% devfee
        API       = "LOL"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
