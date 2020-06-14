using module ..\Includes\Include.psm1

$Path = ".\Bin\NVIDIA-Bminer1621\bminer.exe"
$Uri = "https://www.bminercontent.com/releases/bminer-lite-v16.2.1-ae15079-amd64.zip" #working on win10 only not 8.1, may require nvml.dll to be added
$Commands = [PSCustomObject]@{ 
    #"equihashBTG"      = "-uri zhash://" #EquihashBTG
    #"equihash144"      = "-pers auto -uri equihash1445://" #Equihash144
    #"zhash"            = "-pers auto -uri equihash1445://" #Zhash
    #"ethash"           = "-uri ethstratum://" #Ethash
    #"cuckoocycle"      = "-uri aeternity://" #aeternity
    #"beamv2"           = "-uri beamhash2://" #beam
    #"grincuckarood29"  = "-uri cuckaroo29d://" #grincuckaroo29 
    #"grincuckatoo31"   = "-uri cuckatoo31://" #grincuckatoo31 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram) 
    #"grincuckatoo32"   = "-uri cuckatoo31://" #grincuckatoo32 (8gb cards work win7,8, 8.1 & Linux. Win10 requires 10gb+vram)
    #"cuckaroom"        = "-uri cuckaroo29m://" #cuckaroo29m 
    #"tensority"        = "-uri ethstratum://" #Tensority
    #"kawpow"           = "-uri raven://" #Kawpow
}
$Port = $Variables.NVIDIAMinerAPITCPPort
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm ($_ -split '\+' | Select-Object -Index 0); $Algo2 = Get-Algorithm ($_ -split '\+' | Select-Object -Index 1); $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
If ($Algo -eq "ethash" -and $Pools.$Algo.Host -like "*zergpool*") { return }

    If ($Pools.$Algo.SSL) { $_ = $_ -replace '\://$', '+ssl://' }

    If ($Algo2) { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)-$Algo2"
        $Algo2Parameter = " -uri2 $($_ -split '\+' | Select-Object -Index 1)$(If ($Pools.$Algo2.SSL) { '+ssl' })://$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo2.User)):$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo2.Pass))@$($Pools.$Algo2.Host):$($Pools.$Algo2.Port)"
    }
    Else { 
        $Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
        $Algo2Parameter = ""
        $Algo2 = $null
    }

    [PSCustomObject]@{ 
        Type      = "NVIDIA"
        Name      = $Name
        Path      = $Path
        Arguments = "$($Commands.$_)$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo.User)):$([System.Web.HttpUtility]::UrlEncode($Pools.$Algo.Pass))@$($Pools.$Algo.Host):$($Pools.$Algo.Port) -max-temperature 94 -nofee -devices $($Config.SelGPUCC) -api 127.0.0.1:$Port$Algo2Parameter"
        Algorithm = ($Algo2, $Algo) | Select-Object
        API       = "bminer"
        Port      = $Port
        Wrap      = $false
        URI       = $Uri
    }
}
