if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}


$Path = ".\Bin\NVIDIA-ccminermtp117/ccmier.exe
$Uri = "https://github.com/nemosminer/djm34mtpccminer/releases/download/1.1.7/ccminerMTPkrnlx.7z"

$Commands = [PSCustomObject]@{
    "mtp= "" #MTP
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-d $($Config.SelGPUCC) -i 16 --quite -b $($Variables.NVIDIAMinerAPITCPPort) -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day
        API = "Ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
	User = $Pools.(Get-Algorithm($_)).User
    }
}
