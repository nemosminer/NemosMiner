if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-Alexis78v1.4\ccminer.exe"
$Uri = "https://github.com/nemosminer/ccminerAlexis78/releases/download/Alexis78-v1.4/ccminerAlexis78v1.4x64.7z"

$Commands = [PSCustomObject]@{
    #"hsr" = " -N 1 -d $($Config.SelGPUCC)" #Hsr(testing)
    "poly"    = " -N 1 -d $($Config.SelGPUCC)" #polytimos
    #"veltor" = " -i 23 -d $($Config.SelGPUCC)" #Veltor(fastest)
    #"keccak" = " -N 1 -m 2 -i 29 -d $($Config.SelGPUCC)" #Keccak
    "keccakc" = " -N 1 -i 29 -d $($Config.SelGPUCC)" #Keccakc
    #"lyra2v2" = " -d $($Config.SelGPUCC) -N 1" #Lyra2RE2
    #"myr-gr" = " -d $($Config.SelGPUCC) -N 1" #MyriadGroestl
    #"neoscrypt" = " -i 15 -d $($Config.SelGPUCC)" #NeoScrypt
    #"sib" = " -i 21 -d $($Config.SelGPUCC)" #Sib
    #"skein" = " -i 28 -N 1 -d $($Config.SelGPUCC)" #Skein
    "x11evo"  = " -N 1 -i 21 -d $($Config.SelGPUCC) " #X11evo
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-b $($Variables.NVIDIAMinerAPITCPPort) -R 1 -a $_ -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
