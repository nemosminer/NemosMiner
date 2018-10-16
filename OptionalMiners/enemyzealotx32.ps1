if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1;RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-enemyzealot32122\z-enemy.exe"
$Uri = "https://nemosminer.com/data/optional/z-enemy.1-22-cuda10.0_x32.7z"

$Commands = [PSCustomObject]@{
"aeriumx" = " -i 20" #AeriumX(2080)
"bcd" = " -i 20" #Bcd(2080)
#"hsr" = "" #Hsr
#"phi" = "" #Phi
#"phi2" = "" #Phi2 (cryptodredge faster)
"poly" = " -i 20" #Polytimos(2080) 
"bitcore" = " -i 20" #Bitcore (2080)
#"x16r" = " -i 20" #X16r (x64)
#"x16s" = " -i 20" #X16s (x64)
"sonoa" = " -i 20" #SonoA (2080)
#"skunk" = " -i 20" #Skunk (trex)
#"timetravel" = " -i 20" #Timetravel (x64120 faster)
#"tribus" = "" #Tribus (cryptodredge faster)
"c11" = " -i 20" #C11 (2080)
"xevan" = " -i 20" #Xevan (x64120 faster)
"x17" = " -i 20" #X17 (2080)
"hex" = " -i 20" #Hex (2080)
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
