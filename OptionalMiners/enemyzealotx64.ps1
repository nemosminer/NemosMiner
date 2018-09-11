if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-enemyzealotx64\z-enemy.exe"
$Uri = "http://nemos.dx.am/opt/nemos/z-enemy.1-19-cuda9.2_x64.zip"

$Commands = [PSCustomObject]@{
"aeriumx" = " -i 21" #AeriumX(testing)
#"hsr" = "" #Hsr
#"phi" = "" #Phi
"phi2" = "" #Phi2 (testing)
"poly" = "" #Polytimos(testing) 
"bitcore" = "" #Bitcore (testing)
"x16r" = "" #X16r (testing)
"x16s" = "" #X16s (testing)
"sonoa" = " -i 21" #SonoA (testing)
"skunk" = "" #Skunk (testing)
"timetravel" = "" #Timetravel (testing)
"tribus" = "" #Tribus (testing)
"c11" = "" #C11 (testing)
"xevan" = "" #Xevan (testing)
"x17" = "" #X17 (testing)
"hex" = " -i 23" #Hex (testing)

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
