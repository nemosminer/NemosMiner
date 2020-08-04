using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\z-enemy.exe"
$Uri = "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda10.1.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject]@{ 
    "Aergo"  = " --algo aergo --intensity 23" #AeriumX
    "Xevan"  = " --algo xevan --intensity 22" #Xevan 
    "Hex"    = " --algo --intensity 24" #Hex 
    "KawPoW" = " --algo kawpow" #--intensity 22 no result
}

$Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 
    If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model | Sort-Object $DeviceEnumerator)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.$_.Host } | ForEach-Object {

            #Get commands for active miner devices
            #$_.Command = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            If ($_ -eq "KawPoW") { $WarmupTime = 90 }
            Else { $WarmupTime = $Config.WarmupTime }

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Type       = "NVIDIA"
                Path       = $Path
                Arguments  = ("$($Commands.$_) --url stratum+tcp://$($Pools.$_.Host):$($Pools.$_.Port) --user $($Pools.$_.User) --pass $($Pools.$_.Pass) --api-bind 0 --api-bind-http $MinerAPIPort --retry-pause 1 --quiet --devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ',')" -replace "\s+", " ").trim()
                Algorithm  = $_
                API        = "Trex"
                Port       = $MinerAPIPort
                Wrap       = $false
                URI        = $Uri
                Fee        = 0.01 #dev fee
                MinerUri   = "http://localhost:$($MinerAPIPort)"
                WarmupTime = $WarmupTime # Seconds
            }
        }
    }
}
