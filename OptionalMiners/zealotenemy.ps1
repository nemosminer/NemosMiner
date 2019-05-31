if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-zealotenemy200\z-enemy.exe"
$Uri = "https://github.com/Minerx117/ZEnemy-Miner/releases/download/v2.0.0/ZEnemy200cuda10.7z"

$Commands = [PSCustomObject]@{
    "aergo"     = " -i 23" #AeriumX
   #"bcd"        = "" #Bcd
   #"phi"        = " -i 22" #Phi 
   #"phi2"       = "" #Phi2 
   #"poly"       = "" #Polytimos
   #"bitcore"    = "" #Bitcore
   #"x16r"       = "" #X16r 
   #"x16s"       = "" #X16s 
   #"sonoa"      = "" #SonoA 
   "skunk"      = "" #Skunk 
   #"timetravel" = "" #Timetravel 
   #"tribus"     = "" #Tribus 
   #"c11"        = "" #C11 
    "xevan"       = " -i 22" #Xevan 
   #"x17"        = "" #X17
    "hex"         = " -i 24" #Hex 
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
