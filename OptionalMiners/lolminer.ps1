if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-AMD-lolMiner07\lolMiner.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/0.7/lolMiner_v07_Win64.zip"

$Commands = [PSCustomObject]@{
    #"equihash96" = " --coin MNX" #Equihash 96,5
    #"Equihash21x9" = "--coin AION" #Equihash 210,9
    #"equihash144" = " --coin AUTO144_5" #Equihash 144,5
    #"beam" = " --coin BEAM" #Equihash 150,5
    }
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments =  "--user $($Pools.($Algo).User) --pool $($Pools.($Algo).Host) --port $($Pools.($Algo).Port) --devices $($Config.SelGPUCC) --apiport $($Variables.NVIDIAMinerAPITCPPort) --tls 0 --digits 2 --longstats 60 --shortstats 5 --connectattempts 3 --pass $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99} # substract 1% devfee
        API       = "LOL"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}


