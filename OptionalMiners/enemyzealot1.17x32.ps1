if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-enemyz1.17x32\z-enemy.exe"
$Uri = "http://nemos.dx.am/opt/nemos/z-enemy.1-17-cuda9.2_x32.7z"

$Commands = [PSCustomObject]@{
"aeriumx" = " -i 21" #AeriumX(fastest)
#"hsr" = "" #Hsr
#"phi" = "" #Phi
#"phi2" = "" #Phi2 (cryptodredge faster)
"poly" = "" #Polytimos(fastest)
#"bitcore" = "" #Bitcore (t-rex faster)
#"x16r" = "" #X16r (t-rex faster)
#"x16s" = "" #X16s(t-rex faster)
"sonoa" = " -i 21" #SonoA (t-rex faster)
#"skunk" = "" #Skunk(cryptodredge faster)
#"timetravel" = "" #Timetravel(fastest)
#"tribus" = "" #Tribus(trex,cryptodredge faster)
#"c11" = "" #C11(Alexis78 faster)
#"xevan" = "" #Xevan(xevan75/9 faster)
#"x17" = "" #X17(Trex faster)
"hex" = " -i 23" #Hex(fastest)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -R 1 -q -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API = "Ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
