if (!(IsLoaded(".\Includes\include.ps1"))) {. .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")}
 
$Path = ".\Bin\NVIDIA-Bminer1553\bminer.exe"
$Uri = "https://www.bminercontent.com/releases/bminer-lite-v15.5.3-747d98e-amd64.zip"
$Commands = [PSCustomObject]@{
   #"equihashBTG" = " -uri zhash://" #EquihashBTG
   #"equihash144" = " -pers auto -uri equihash1445://" #Equihash144
   #"zhash" = " -pers auto -uri equihash1445://" #Zhash
    "ethash" = " -uri ethstratum://" #Ethash 
   #"cuckoocycle" = " -uri aeternity://" #aeternity
    "beam" = " -uri beam://" #beam
    "grincuckaroo29" = " -uri cuckaroo29://" #grincuckaroo29 
   #"grincuckatoo31" = " -uri cuckatoo31://" #grincuckatoo31 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    $Pass = If ($Pools.($Algo).Pass -like "*,*") {$Pools.($Algo).Pass.ToString().replace(',','%2C')} else {$Pools.($Algo).Pass}
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "$($Commands.$_)$($Pools.($Algo).User):$($Pass)@$($Pools.($Algo).Host):$($Pools.($Algo).Port) --fast -max-temperature 94 -nofee -devices $($Config.SelGPUCC) -api 127.0.0.1:$Port"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API       = "bminer"
        Port      = $Port
        Wrap      = $false
        URI       = $Uri    
        User = $Pools.($Algo).User
        Host = $Pools.($Algo).Host
        Coin = $Pools.($Algo).Coin
    }
}
