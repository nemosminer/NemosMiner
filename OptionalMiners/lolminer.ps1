if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
 
$Path = ".\Bin\NVIDIA-lolMiner091hf\lolMiner.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-preview/releases/download/0.9.1hotfix/lolMiner_v091_hotfix_Win64.zip"

$Commands = [PSCustomObject]@{
     "equihash144"    = " --coin AUTO144_5" #Equihash 144,5
     "equihash192"    = " --coin AUTO192_7" #Equihash 144,5
     "equihash96"     = " --coin AUTO96_5" #Equihash 144,5
     "equihash125"    = " --coin AUTO125_4" #Equihash 125,4
     "beamv2"         = " --coin BEAM-II" #Equihash 150,5 (NiceHash)
    #"grincuckatoo31" = " --coin GRIN-AT31" 
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {

    [PSCustomObject]@{
        Type      = "AMD"
        Path      = $Path
        Arguments = "--user $($Pools.$Algo.User) --pool $($Pools.$Algo.Host) --port $($Pools.$Algo.Port) --devices $($Config.SelGPUCC) --apiport $($Variables.AMDMinerAPITCPPort) --tls 0 --digits 2 --longstats 240 --shortstats 60 --connectattempts 5 --pass $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day * 0.99 } # 1% dev fee
        API       = "LOL"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }

}
