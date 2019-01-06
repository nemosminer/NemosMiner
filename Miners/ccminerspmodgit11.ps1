if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-ccminerspmodgit11\ccminer.exe"
$Uri = "https://github.com/sp-hash/suprminer/releases/download/spmod-git11/spmodgit11.7z"

$Commands = [PSCustomObject]@{
    "c11"  = " -d $($Config.SelGPUCC)" #C11 (trex faster/ fastest open source)
    "x17"  = " -d $($Config.SelGPUCC)" #X17 (trex faster/ fastest open source)
    "x16r" = " -d $($Config.SelGPUCC)" #X16r(trex faster/ fastest open source)
    "x16s" = " -d $($Config.SelGPUCC)" #X16s (trex faster/ fastest open source)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -R 1 -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
