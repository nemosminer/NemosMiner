if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-Gminer120\miner.exe"
$Uri = "https://nemosminer.com/data/optional/gminer_1_20_minimal_windows64.7z"
$Commands = [PSCustomObject]@{
    #"cuckroo"      = " --devices $($Config.SelGPUDSTM) --algo grin29 --pers auto" #Equihash Cuckaroo29/GRIN (testing)
    "equihash144"  = " --devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Equihash144 (fastest)
    "zhash"        = " --devices $($Config.SelGPUDSTM) --algo 144_5 --pers auto" #Zhash (fastest)
    "equihash192"  = " --devices $($Config.SelGPUDSTM) --algo 192_7 --pers ZERO_PoW" #Equihash192 (fastest)
    "equihash-btg" = " --devices $($Config.SelGPUDSTM) --algo 144_5 --pers BgoldPoW" # Equihash-btg (fastest)
    "equihash96"   = " --devices $($Config.SelGPUDSTM) --algo 96_5 --pers auto" #Equihash96 (fastest)
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--watchdog 0 --api $($Variables.NVIDIAMinerAPITCPPort) --server $($Pools.(Get-Algorithm($_)).Host) --port $($Pools.(Get-Algorithm($_)).Port) --user $($Pools.(Get-Algorithm($_)).User) --pass $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .98} # substract 2% devfee
        API       = "gminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
