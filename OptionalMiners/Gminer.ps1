if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-Gminer114\miner.exe"
$Uri = "https://nemosminer.com/data/optional/gminer_1_14_minimal_windows64.7z"
$Commands = [PSCustomObject]@{
    #"zhash" = "" #Zhash(disabled working on 10series/not 20series, miniZ same speed works with both)
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--watchdog 0 --devices $($Config.SelGPUDSTM) --api $($Variables.NVIDIAMinerAPITCPPort) --algo 144_5 --pers auto --server $($Pools.(Get-Algorithm($_)).Host) --port $($Pools.(Get-Algorithm($_)).Port) --user $($Pools.(Get-Algorithm($_)).User) --pass $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .98} # substract 2% devfee
        API       = "gminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
