if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")}

$Path = ".\Bin\NVIDIA-TTMiner225\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/TTMiner/releases/download/v2.2.5/TTMiner2.2.5.7z"

$Commands = [PSCustomObject]@{
        "progpow"    = " -a PROGPOW" 
       #"mtp"        = " -a MTP" 
       #"ethash"     = " -a ETHASH"
        "ubqhash"    = " -a UBQHASH"
       #"myr-gr"     = " -a MYRGR " 
       #"lyra2v3"    = " -a LYRA2V3" 
       #"lyra2rev3"  = " -a LYRA2V3" 
}
 
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-d $($Config.SelGPUDSTM) --api-bind 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * .99} # substract 1% devfee
        API       = "TTminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
