if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")}
 
$Path = ".\Bin\AMD-SgminerFancyIX0600\sgminer.exe"
$Uri = "https://github.com/fancyIX/sgminer-phi2-branch/releases/download/5.6.1.3.b6/sgminer-phi2-fancyIX-win64-0.6.0.0.zip"

$Commands = [PSCustomObject]@{
    "allium" = " --kernel allium --gpu-threads 1 --worksize 256 -I 20"
    "argon2d-dyn" = " --kernel argon2d --gpu-threads 2 --worksize 64"
    "lyra2v3" = " --kernel lyra2v3 --gpu-threads 1 --worksize 256 -I 24"
    "lyra2z" = " --kernel lyra2z --gpu-threads 1 --worksize 256 -I 22"
    "lyra2zz" = " --kernel lyra2zz --gpu-threads 1 --worksize 256 -I 22"
    "mtp" = " --kernel mtp -I 18"
    "phi2" = " --kernel phi2 --gpu-threads 1 --worksize 256 -I 22"
    "x22i" = " --kernel x22i --gpu-threads 2 --worksize 256 -I 22"
    "x25x" = " --kernel x25x --gpu-threads 1 --worksize 256 -I 22"
    }
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {

	$Algo = Get-Algorithm($_)
        [PSCustomObject]@{
        Type      = "AMD"
        Path      = $Path
        Arguments = "--api-port $($Variables.AMDMinerAPITCPPort) --api-listen -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day} 
        API       = "Xgminer"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }

}
