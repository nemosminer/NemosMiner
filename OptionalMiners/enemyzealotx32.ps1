if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-enemyzealot32120\z-enemy.exe"
$Uri = "http://nemos.dx.am/opt/nemos/z-enemy.1-20-cuda9.2_x32_v2.zip"

$Commands = [PSCustomObject]@{
"aeriumx" = " -i 21" #AeriumX(testing)
#"hsr" = "" #Hsr
#"phi" = "" #Phi
"phi2" = "" #Phi2 (testing 1.20)
"poly" = "" #Polytimos(testing 1.20) 
"bitcore" = "" #Bitcore (testing 1.20)
"x16r" = "" #X16r (testing 1.20)
"x16s" = "" #X16s (testing 1.20)
"sonoa" = " -i 21" #SonoA (testing 1.20)
"skunk" = "" #Skunk (testing 1.20)
"timetravel" = "" #Timetravel (testing 1.20)
"tribus" = "" #Tribus (testing 1.20)
"c11" = "" #C11 (testing 1.20)
"xevan" = "" #Xevan (testing 1.20)
"x17" = "" #X17 (testing 1.20)
"hex" = " -i 23" #Hex (testing 1.20)
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
