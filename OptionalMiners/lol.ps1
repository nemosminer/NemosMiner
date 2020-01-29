if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") } 
 
$Path = ".\Bin\NVIDIA-lolMiner081\lolMiner.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/0.96/lolMiner_v0961_Win64.zip"

$Commands = [PSCustomObject]@{
    #"grincuckatoo32" = " --coin GRIN-AT32" #grincuckatoo31
}
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--user $($Pools.($Algo).User) --pool $($Pools.($Algo).Host) --port $($Pools.($Algo).Port) --devices $($Config.SelGPUCC) --apiport $($Variables.NVIDIAMinerAPITCPPort) --tls 0 --digits 2 --longstats 60 --shortstats 5 --connectattempts 3 --pass $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .98 } # substract 2% devfee
        API       = "LOL"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
