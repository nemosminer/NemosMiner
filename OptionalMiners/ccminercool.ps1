. .\Include.ps1

$Path = ".\Bin\NVIDIA-ccminercool\coolMiner-x64.exe"
$Uri = "http://nemos.dx.am/opt/nemos/coolMiner-x64-v1-4.7z"

$Commands = [PSCustomObject]@{
    "lyra2z" = " -i 20.5 -d $SelGPUCC" #Lyra2z(fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b 4068 -R 1 -q --submit-stale -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API = "Ccminer"
        Port = 4068
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
