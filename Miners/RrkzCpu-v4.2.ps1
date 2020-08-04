using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$()$Name)\cpuminer.exe"
$Uri = "https://github.com/RickillerZ/cpuminer-RKZ/releases/download/V4.2b/cpuminer-RKZ.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject]@{ 
    "Cpupower" = " --algo cpupower"
    "Power2b"  = " --algo power2b"
}

$Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")
$Miner_Devices | Select-Object Model -Unique | ForEach-Object { 
    $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

    $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.$_.Host } | ForEach-Object {

        #Get commands for active miner devices
        #$Commands.$_ = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Name       = $Miner_Name
            DeviceName = $Miner_Devices.Name
            Type       = "CPU"
            Path       = $Path
            Arguments  = ("$($Commands.$_) --url $($Pools.$_.Protocol)://$($Pools.$_.Host):$($Pools.$_.Port) --user $($Pools.$_.User) --pass $($Pools.$_.Pass) --cpu-affinity AAAA --quiet --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
            Algorithm  = $_
            API        = "Ccminer"
            Port       = $MinerAPIPort
            URI        = $Uri
        }
    }
}
