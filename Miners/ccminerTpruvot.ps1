if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-Tpruvotv2.3cuda10\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerTpruvot/releases/download/v2.3-cuda10/ccminertpruvotx32.7z"

$Commands = [PSCustomObject]@{
    "phi"        = " -d $($Config.SelGPUCC)" #Phi (testing)
    "allium"     = " -d $($Config.SelGPUCC)" #Allium
    "bitcore"    = " -d $($Config.SelGPUCC)" #Bitcore(spmodbitcore faster)
    "hmq1725"    = " -d $($Config.SelGPUCC)" #hmq1725
    "sha256t"    = " -d $($Config.SelGPUCC) -i 29" #Sha256t
    "sonoa"      = " -d $($Config.SelGPUCC)" #Sonoa
    "skunk"      = " -d $($Config.SelGPUCC)" #Skunk
    "timetravel" = " -d $($Config.SelGPUCC)" #Timetravel
    "exosis"     = " -d $($Config.SelGPUCC)" #Exosis

}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cpu-priority 5 -b $($Variables.NVIDIAMinerAPITCPPort) -N 1 -R 1 -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
