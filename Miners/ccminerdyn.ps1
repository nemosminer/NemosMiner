if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-ccminerdyn10\ccminer.exe"
$Uri = "https://nemosminer.com/data/optional/ccminerdyn.7z"

$Commands = [PSCustomObject]@{
    "argon2d-dyn" = "" #argon2d-dyn (fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -o stratum+tcp://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -a argon2d -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
