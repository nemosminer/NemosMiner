if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-progpowminer016\progpowminer-cuda.exe"
$Uri = "https://nemosminer.com/data/optional/progpowminer0.16-FinalCuda10.7z"

$Commands = [PSCustomObject]@{
       #"progpow"  = " -a PROGPOW-100" # (progpowminer faster + 0% fee)
       #"mtp"      = " -a MTP-100 " # (ccminer faster + 0% fee)
       #"ethash"   = " -a ETHASH-100 "# (Bminer/Ethminer faster + 0% fee)
       #"ubqhash"  = " -a UBQHASH-100 "
       #"myr-gr"   = " -a MYRGR-100 " 
       #"lyra2v3"  = " -a LYRA2V3-100 " # (ccminer faster + 0%fee)
 
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
	$Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--cuda-devices $($Config.SelGPUDSTM) --api-port -$($Variables.NVIDIAMinerAPITCPPort) -U -P stratum://$($Pools.($Algo).User):x@$($Pools.($Algo).Host):$($Pools.($Algo).Port)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API = "ethminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
