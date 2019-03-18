if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-miniZ12l\miniZ.exe"
$Uri = "https://nemosminer.com/data/optional/miniZv1.2lcuda10winx64.7z"
$Commands = [PSCustomObject]@{
    "equihash144"  = " --algo 144,5 --pers auto" #Equihash144 (testing)
    "zhash"        = " --algo 144,5 --pers auto" #Zhash (testing)
    "equihash192"  = " --algo 192,7 --pers auto" #Equihash192 (testing)
    "equihash-btg" = " --algo 144,5 --pers BgoldPoW " # Equihash-btg MPH (testing)
    "equihash96"   = " --algo 96,5  --pers auto" #Equihash96 (testing)
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--intensity 100 --latency --nocolor --tempunits C -cd $($Config.SelGPUDSTM) --telemetry $($Variables.NVIDIAMinerAPITCPPort) --url $($Pools.(Get-Algorithm($_)).User)@$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) --pass $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .98} # substract 2% devfee
        API       = "miniZ"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
