if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-CcminerKlausTv10\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerKlausTyescrypt/releases/download/v10/ccminerKlausTyescryptv10.7z"

$Commands = [PSCustomObject]@{
    "yescrypt"      = " -i 12.5 -d $($Config.SelGPUCC)" #Yescrypt
    "yescryptR8"    = " -i 12.5 -d $($Config.SelGPUCC)" #YescryptR8
    "yescryptR16"   = " -i 12.5 -d $($Config.SelGPUCC)" #YescryptR16
    "yescryptR24"   = " -i 12.5 -d $($Config.SelGPUCC)" #YescryptR24 
    #"yescryptR32" = " -i 12.5 -d $($Config.SelGPUCC)" #YescryptR32 
    "yescryptR16v2" = " -i 12.5 -d $($Config.SelGPUCC)" #YescryptR16v2
    "neoscrypt"     = " -i 17 -d $($Config.SelGPUCC)" #NeoScrypt
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
