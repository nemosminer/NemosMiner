if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-enemyzealot64123\z-enemy.exe"
$Uri = "https://nemosminer.com/data/optional/z-enemy.1-23-cuda10.0_x64.7z"

$Commands = [PSCustomObject]@{
"aeriumx" = " -i 20" #AeriumX(RTX)
"bcd" = " -i 20" #Bcd(RTX)
#"hsr" = "" #Hsr
#"phi" = "" #Phi
"phi2" = "" #Phi2 (RTX)
"poly" = " -i 20" #Polytimos(RTX) 
"bitcore" = " -i 20" #Bitcore (RTX)
"x16r" = " -i 20" #X16r (RTX)
"x16s" = " -i 20" #X16s (RTX)
"sonoa" = " -i 20" #SonoA (RTX)
"skunk" = " -i 20" #Skunk (RTX)
"timetravel" = " -i 20" #Timetravel (RTX)
"tribus" = "" #Tribus (RTX)
"c11" = " -i 20" #C11 (RTX)
"xevan" = " -i 20" #Xevan (RTX)
"x17" = " -i 20" #X17(RTX)
"hex" = " -i 20" #Hex (RTX)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -R 1 -q -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day * .99} # substract 1% devfee
        API = "ccminer"
        Port = $Variables.NVIDIAMinerAPITCPPort
        Wrap = $false
        URI = $Uri
        User = $Pools.(Get-Algorithm($_)).User
    }
}
