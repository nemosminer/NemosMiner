. .\Include.ps1

$Path = ".\Bin\NVIDIA-CryptoDredge\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.6.0/CryptoDredge_0.6.0.zip"

$Commands = [PSCustomObject]@{
    "allium" = " -d $SelGPUCC" #Allium(testing)
    "lyra2v2" = " -d $SelGPUCC" #Lyra2RE2(testing)
    "lyra2z" = " -d $SelGPUCC" #Lyra2z(testing)
    "neoscrypt" = " -d $SelGPUCC" #NeoScrypt(testing)
    "phi" = " -d $SelGPUCC" #Phi (testing)
    "phi2" = " -d $SelGPUCC" #Phi2 (testing)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = " -b 127.0.0.1:4444 -a $_ --no-watchdog -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API = "ccminer"
        Port = "4444"
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
