if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-zealotenemy128\z-enemy.exe"
$Uri = "https://nemosminer.com/data/optional/z-enemy.1-28-cuda10.0.7z"

$Commands = [PSCustomObject]@{
    #"aergo"     = " -i 23" #AeriumX(fastest)
    #"bcd"        = "" #Bcd(trex faster)
    #"phi"        = "" #Phi (CryptoDredge faster)
    #"phi2"       = "" #Phi2 (CryptoDredge faster)
    #"poly"       = "" #Polytimos(fastest) 
    #"bitcore"    = "" #Bitcore (trex faster)
    #"x16r"       = "" #X16r (trex faster)
    #"x16s"       = "" #X16s (trex faster)
    #"sonoa"      = "" #SonoA (trex faster)
    #"skunk"      = "" #Skunk (CryptoDredge faster)
    #"timetravel" = "" #Timetravel (trex faster)
    #"tribus"     = "" #Tribus (not profitable atm)
    #"c11"        = "" #C11 (trex faster)
    "xevan"       = " -i 22" #Xevan (fastest)
    #"x17"        = "" #X17(trex faster)
    "hex"         = " -i 24" #Hex (fastest)
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
