if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")}

$Path = ".\Bin\NVIDIA-zealotenemy21\z-enemy.exe"
$Uri = "https://github.com/Minerx117/ZEnemy-Miner/releases/download/v2.1/zealotenemy21cuda10.7z"

$Commands = [PSCustomObject]@{
    "aergo"       = " -i 23" #AeriumX
    "xevan"       = " -i 22" #Xevan 
    "hex"         = " -i 24" #Hex 
    "c11"         = " -i 22" #C11
    "timetravel"  = " -i 22" #TimeTravel
    "x16s"        = " -i 22" #X16s
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -R 1 -q -a $_ -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99} # substract 1% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
