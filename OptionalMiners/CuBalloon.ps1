. .\Include.ps1

$Path = ".\Bin\NVIDIA-CuBalloon\cuballoon.exe"
$Uri = "https://github.com/Belgarion/cuballoon/files/2143221/CuBalloon.1.0.2.Windows.zip"

$Commands = [PSCustomObject]@{
    "balloon" = " --cuda-devices $SelGPUCC --cuda-threads 64 --cuda-blocks 48 --cuda-sync 0 -t 0" #DEFT
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.MinerAPITCPPort) -R 1 -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_) -q"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .96} # substract about 3% fee
        API = "Ccminer"
        Port = $Variables.MinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
