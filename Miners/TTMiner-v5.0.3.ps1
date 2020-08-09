using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject]@{ 
    "MTP"       = " -algo MTP -i 21"
    "Eaglesong" = " -algo EAGLESONG"
#   "Ethash"    = " -algo ETHASH" #Bminer-v16.2.12 is faster
    "KawPoW"    = " -algo KAWPOW"
}

$Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.$_.Host } | ForEach-Object {
            If ($_ -eq "KawPoW" -and $Pools.$_.Name -like "MPH*") { Return }
            If ($_ -eq "Ethash" -and $Pools.$_.Name -like "ZergPool*") { Return }

            #Get commands for active miner devices
            #$Commands.$_ = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Type       = "NVIDIA"
                Path       = $Path
                Arguments  = ("$($Commands.$_) --pool stratum+tcp://$($Pools.$_.Host):$($Pools.$_.Port) -work-timeout 500000 -user $($Pools.$_.User) -pass $($Pools.$_.Pass) --api-bind 127.0.0.1:$($MinerAPIPort) -device $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ' ')" -replace "\s+", " ").trim()
                Algorithm  = $_
                API        = "EthMiner"
                Port       = $MinerAPIPort
                URI        = $Uri
            }
        }
    }
}
