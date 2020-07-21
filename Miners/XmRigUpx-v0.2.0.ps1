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

    $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.($_.Algorithm).Host } | ForEach-Object { 

        #Get commands for active miner devices
        #$Commands.$_ = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

        [PSCustomObject]@{ 
            Name       = $Miner_Name
            DeviceName = $Miner_Devices.Name
            Path       = $Path
            Arguments  = "$($Commands.$_) -o stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -u $($Pools.($_.Algorithm).User) -p $($Pools.($_.Algorithm).Pass) -t $($Variables.ProcessorCount - 1) --keepalive --api-port=$($MinerAPIPort) --donate-level 0"
            Algorithm  = $Algo
            API        = "XmRig"
            Port       = $MinerAPIPort
            URI        = $Uri    
        }
    }
}
