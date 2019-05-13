if (!(IsLoaded(".\Include.ps1"))) { . .\Include.ps1; RegisterLoaded(".\Include.ps1") }

$Path = ".\Bin\NVIDIA-CryptoDredge0191\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.19.1/CryptoDredge_0.19.1_cuda_10.1_windows.zip"

$Commands = [PSCustomObject]@{
    "argon2d250"  = " --intensity 8 -a argon2d250" #argon2d250
    "argon2d4096" = " --intensity 8 -a argon2d4096" #argon2d4096
    #"argon2d-uis"    = " --intensity 8 -a argon2d4096" #argon2d4096
    "argon2ddyn"  = " --intensity 6 -a argon2d-dyn" #Argon2d-dyn
    "allium"      = " --intensity 8 -a allium" #Allium
    #"lyra2v3"     = " --intensity 8 -a lyra2v3" #Lyra2v3
    #"lyra2REv3"   = " --intensity 8 -a lyra2v3" #lyra2REv3
    "lyra2zz "    = " --intensity 8 -a lyra2zz" #Lyra2zz
    "neoscrypt"   = " --intensity 6 -a neoscrypt"
    "phi2"        = " --intensity 8 -a phi2" #Phi2 
    "lyra2vc0ban" = " --intensity 8 -a lyra2vc0ban" #Lyra2vc0banHash
    #"cryptonightheavy"  = " --intensity 8 -a cryptonightheavy" # CryptoNightHeavy
    #"x22i"              = " --intensity 8 -a x22i" # X22i 
    #"tribus"            = " --intensity 8 -a tribus" #Tribus 
    #"cnv8"              = " --intensity 8 -a cnv8" #CryptoNightv8
    #"c11"               = " --intensity 8 -a c11" #C11 
    "skunk"       = " --intensity 8 -a skunk" #Skunk 
    "mtp"         = " --intensity 8 -a mtp" #Mtp
    #"bcd"               = " --intensity 8 -a bcd" #Bcd 
    #"x16rt"             = " --intensity 8 -a x16rt" #X16rt
    #"x21s"              = " --intensity 8 -a x21s" #X21s 
    #"x16s"              = " --intensity 8 -a x16s" #X16s 
    #"x17"               = " --intensity 8 -a x17" #X17 
    #"bitcore"           = " --intensity 8 -a bitcore" #Bitcore 
    "hmq1725"     = " --intensity 8 -a hmq1725" #Hmq1725
    #"dedal"             = " --intensity 8 -a dedal" #Dedal
    "pipe"        = " --intensity 8 -a pipe" #Pipe 
    #"x16r"              = " --intensity 8 -a x16r" #x16r
    #"grincuckaroo29" = " --intensity 8 -a cuckaroo29" #Grincuckaroo29  
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
    $Algo = Get-Algorithm($_)
    If ($Algo -eq "phi2" -and $Pools.($Algo).Host -like "*zergpool*") { return }
    switch ($_) {
        "mtp" { $Fee = 0.02 } # substract devfee
        default { $Fee = 0.01 } # substract devfee
    }

    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--timeout 60 --api-type ccminer-tcp --cpu-priority 4 --no-watchdog -r -1 -R 1 -b 127.0.0.1:$($Variables.NVIDIAMinerAPITCPPort) -d $($Config.SelGPUCC) -o stratum+tcp://$($Pools.($Algo).Host):$($Pools.($Algo).Port) -u $($Pools.($Algo).User) -p $($Pools.($Algo).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee) } # substract devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
