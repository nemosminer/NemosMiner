using module ..\Includes\Include.psm1

$Path = ".\Bin\NVIDIA-CcmineryescryptrV5\ccminer.exe"
$Path = ".\Bin\$($Name)\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccminer/releases/download/8.21-r18-v5/ccmineryescryptrV5.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject]@{ 
    "Lyra2RE3"     = " --algo lyra2v3 --intensity 24"
    "Lyra2z330"    = " --algo lyra2z330 --timeout=1"
    "YescryptR16"  = " --algo yescryptr16 --intensity 13.2"
    "YescryptR32"  = " --algo yescryptr32 --intensity 12.23"
#   "YescryptR8"   = " --algo yescryptr8" #profit very small
    "YescryptR8g"  = " --algo yescrypt"
}

$Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.$_.Host } | Where-Object { -not $Pools.$_.SSL } | ForEach-Object {

            If ($_ -eq "Lyra2RE3" -and $Pools.$_.Name -like "MPH*") { Return } #Temp fix

            #Get commands for active miner devices
            #$Commands.$_ = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo", "timeout") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Path       = $Path
                Arguments  = ("$($Commands.$_) --url stratum+tcp://$($Pools.$_.Host):$($Pools.$_.Port) --user $($Pools.$_.User) --pass $($Pools.$_.Pass) --cpu-priority 4 --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ',')" -replace "\s+", " ").trim()
                Algorithm  = $_
                API        = "Ccminer"
                Port       = $MinerAPIPort
                URI        = $Uri
                WarmupTime = 60 #seconds
            }
        }
    }
}
