if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-enemyzealot64120\z-enemy.exe"
$Uri = "http://nemos.dx.am/opt/nemos/z-enemy.1-20-cuda9.2_x64_v3.zip"

$Commands = [PSCustomObject]@{
#"aeriumx" = " -i 21" #AeriumX(x32120 faster)
#"hsr" = "" #Hsr
#"phi" = "" #Phi
#"phi2" = "" #Phi2 (cryptodredge faster)
#"poly" = "" #Polytimos(trex faster) 
#"bitcore" = "" #Bitcore (trex faster)
#"x16r" = "" #X16r (trex faster)
#"x16s" = "" #X16s (trex faster)
#"sonoa" = " -i 21" #SonoA (trex faster)
#"skunk" = "" #Skunk (trex faster)
#"timetravel" = "" #Timetravel (x32120 faster)
#"tribus" = "" #Tribus (cryptodredge faster)
#"c11" = "" #C11 (trex faster)
"xevan" = "" #Xevan (fastest on 1080ti rigs /ccminer7.5/9 faster on 1070ti rigs)
#"x17" = "" #X17 (trex faster)
"hex" = " -i 23" #Hex (x32120 faster)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -R 1 -q -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Week * .99} # substract 1% devfee
        API = "ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
