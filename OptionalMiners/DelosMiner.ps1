. .\Include.ps1

$Path = ".\Bin\NVIDIA-DelosMiner\ccminer.exe"
$Uri = "http://nemos.dx.am/opt/nemos/DelosMiner1.3.0-x86-cuda91.7z"

$Commands = [PSCustomObject]@{
    "bitcore" = " -d $SelGPUCC" #Bitcore(fastest)
    #"c11" = " -d $SelGPUCC" #C11(Alexis78v1.2 faster)
    #"hmq1725" = " -d $SelGPUCC" #hmq1725(ccminerx16sv0.5 faster)
    #"hsr" = " -d $SelGPUCC" #Hsr(Alexis78v1.2 faster)
    #"lyra2v2" = " -d $SelGPUCC" #Lyra2RE2(Alexis78v1.2 faster)
    "phi" = " -d $SelGPUCC" #Phi(fastest)
    #"skein" = " -d $SelGPUCC" #Skein(Alexi78v1.2 faster)
    "skunk" = " -d $SelGPUCC" #Skunk(fastest)
    #"x16r" = " -d $SelGPUCC" #X16r(ccminerx16r faster)
    "x16s" = " -d $SelGPUCC" #X16s(fastest)
    "x17" = " -d $SelGPUCC" #X17(fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.MinerAPITCPPort) -R 1 -q --submit-stale -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API = "Ccminer"
        Port = $Variables.MinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
