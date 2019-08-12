if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
 
$Path = ".\Bin\NVIDIA-lolMiner086\lolMiner.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/0.8.6/lolMiner_v086_Win64.zip"

$Commands = [PSCustomObject]@{
    "Equihash21x9" = "--coin AION" #Equihash 210,9
    "equihash144"  = " --coin AUTO144_5" #Equihash 144,5
    "equihash125"  = " --coin ZEL" #Equihash 125,4
    "beam"         = " --coin BEAM" #Equihash 150,5
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--user $($Pools.($Algo).User) --pool $($Pools.($Algo).Host) --port $($Pools.($Algo).Port) --devices $($Config.SelGPUCC) --apiport $($Variables.NVIDIAMinerAPITCPPort) --tls 0 --digits 2 --longstats 240 --shortstats 60 --connectattempts 5 --pass $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * 0.99 } # 1% dev fee
        API       = "LOL"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }

    [PSCustomObject]@{
        Type      = "AMD"
        Path      = $Path
        Arguments = "--user $($Pools.($Algo).User) --pool $($Pools.($Algo).Host) --port $($Pools.($Algo).Port) --devices $($Config.SelGPUCC) --apiport $($Variables.AMDMinerAPITCPPort) --tls 0 --digits 2 --longstats 240 --shortstats 60 --connectattempts 5 --pass $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * 0.99 } # 1% dev fee
        API       = "LOL"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }

}
