using module ..\Includes\Include.psm1

#$Path = ".\Bin\CPU-JayDDe3143\cpuminer-zen.exe" #AMD
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" #Intel
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.14.3/cpuminer-opt-3.14.3-windows.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")

If ($Miner_Devices.CpuFeatures -match "avx2")     { $Path = ".\Bin\$($Name)\cpuminer-Avx2.exe" }
ElseIf ($Miner_Devices.CpuFeatures -match "avx")  { $Path = ".\Bin\$($Name)\cpuminer-Avx.exe" }
ElseIf ($Miner_Devices.CpuFeatures -match "aes")  { $Path = ".\Bin\$($Name)\cpuminer-Aes-Sse42.exe" }
ElseIf ($Miner_Devices.CpuFeatures -match "sse2") { $Path = ".\Bin\$($Name)\cpuminer-Sse2.exe" }
Else { Return }

$Commands = [PSCustomObject]@{ 
    "Lyra2z330" = " --algo lyra2z330"
    "Sha3d"     = " --algo sha3d"
    "ScryptN11" = " --algo scrypt:2048"
    "m7m"       = " --algo m7m"
}

$Miner_Devices | Select-Object Model -Unique | ForEach-Object { 
    $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

    $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.$_.Host } | ForEach-Object {

        #Get commands for active miner devices
        #$Commands.$_ = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo") -DeviceIDs $Devices.$DeviceEnumerator

        Switch ($_) { 
            "C11" { $WarmupTime = 60 }
            Default { $WarmupTime = 30 }
        }

        [PSCustomObject]@{ 
            Name       = $Miner_Name
            DeviceName = $Miner_Devices.Name
            Path       = $Path
            Arguments  = ("$($Commands.$_) --url $($Pools.$_.Protocol)://$($Pools.$_.Host):$($Pools.$_.Port) --user $($Pools.$_.User) --pass $($Pools.$_.Pass) --hash-meter --quiet --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            Algorithm  = $_
            API        = "Ccminer"
            Port       = $MinerAPIPort
            URI        = $Uri
            WarmupTime = $WarmupTime #seconds
        }
    }
}
