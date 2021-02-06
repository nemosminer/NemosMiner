If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
$Path = ".\Bin\AMD-VertHash062\VerthashMiner.exe"
$Uri = "https://github.com/CryptoGraphics/VerthashMiner/releases/download/0.6.2/VerthashMiner-0.6.2-CUDA11-windows.zip"

$DatPath = "$($Variables.MainPath)\Bin\AMD-VertHash062\Verthash.dat"
If (-not (Test-Path $DatPath) -and (Test-Path $Path)) {
    $Variables.StatusText = "Downloading verthash.dat... 1.2Gb !"
    Invoke-WebRequest -OutFile $DatPath -Uri "https://vtc.suprnova.cc/verthash.dat"
}

$Commands = [PSCustomObject]@{ 
     "verthash" = " --verthash-data ""$($DatPath)""" #verthash
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 
    [PSCustomObject]@{ 
        Type      = "AMD"
        Path      = $Path
        Arguments = "-d $($Config.SelGPUCC) -a $_ -o stratum+tcp://$($Pools.$Algo.Host):$($Pools.$Algo.Port) -u $($Pools.$Algo.User) -p $($Pools.$Algo.Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Week }
        API       = "wrapper"
        Port      = $Variables.AMDMinerAPITCPPort
        Wrap      = $true
        URI       = $Uri
    }
}
