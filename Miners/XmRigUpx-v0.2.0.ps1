using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v0.2.0/xmrig-upx-v0.2.0-win64.zip"

$Commands = [PSCustomObject]@{ 
    "CryptonightUpx" = " -a cryptonight-upx/2 --nicehash" #cryptonightupx
}

If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 
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
            Arguments  = ("$($Commands.$_) --url stratum+tcp://$($Pools.$_.Host):$($Pools.$_.Port) --user $($Pools.$_.User) --pass $($Pools.$_.Pass) --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --keepalive --api-port=$($MinerAPIPort) --donate-level 0").trim()
            Algorithm  = $_
            API        = "XmRig"
            Port       = $MinerAPIPort
            URI        = $Uri
            WarmupTime = 60 #seconds
        }
    }
}
