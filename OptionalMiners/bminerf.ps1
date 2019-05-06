if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}
 
$Path = ".\Bin\NVIDIA-Bminerf1531\bminer.exe"
$Uri = "https://www.bminercontent.com/releases/bminer-lite-v15.3.1-8887ee1-amd64.zip"
$Commands = [PSCustomObject]@{
   #"equihashBTG" = " -uri zhash://" #EquihashBTG
   #"equihash144" = " -pers auto -uri equihash1445://" #Equihash144
   #"zhash" = " -pers auto -uri equihash1445://" #Zhash
   #"ethash" = " -uri ethstratum://" #Ethash 
   #"cuckoocycle" = " -uri aeternity://" #aeternity
    "beam" = " -uri beam://" #beam
    "grincuckaroo29" = " -uri cuckaroo29://" #grincuckaroo29 
   #"grincuckatoo31" = " -uri cuckatoo31://" #grincuckatoo31 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
        switch ($_) {
        "ethash" {$Fee = 0.0065} # substract devfee
        "grincuckaroo29" {$Fee = 0.01} # substract devfee
        "grincuckatoo31" {$Fee = 0.01} # substract devfee
        default {$Fee = 0.02} # substract devfee
    }
    $Pass = If ($Pools.($Algo).Pass -like "*,*") {$Pools.($Algo).Pass.ToString().replace(',','%2C')} else {$Pools.($Algo).Pass}
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "$($Commands.$_)$($Pools.($Algo).User):$($Pass)@$($Pools.($Algo).Host):$($Pools.($Algo).Port) -max-temperature 94 -devices $($Config.SelGPUCC) -api 127.0.0.1:$Port"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day * (1 - $Fee)} # substract devfee
        API       = "bminer"
        Port      = $Port
        Wrap      = $false
        URI       = $Uri    
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
