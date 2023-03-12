If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -eq "NVIDIA")) { Return }

$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v1.0.3/ninjarig_v1.0.3.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\ninjarig.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Chukwa"; Minerset = 2; WarmupTimes = @(30, 0); Arguments = " -a argon2/chukwa" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $AvailableMiner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($AvailableMiner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

        $Algorithms | ForEach-Object { 

            $Arguments = $_.Arguments

            # Get arguments for available miner devices
            # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $Devices.$DeviceEnumerator

            If ($MinerPools[0].($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $Arguments += " --nicehash" } 
            If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { $Arguments += " --tls" }

            [PSCustomObject]@{ 
                Algorithms  = @($_.Algorithm)
                API         = "XmRig"
                Arguments   = ("$($Arguments) --url stratum+tcp://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" }) --pass $($MinerPools[0].($_.Algorithm).Pass) --keepalive --api-port=$MinerAPIPort --donate-level 0 -R 1 --use-gpu=CUDA -t $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                DeviceNames = $AvailableMiner_Devices.Name
                MinerSet    = $_.MinerSet
                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                Name        = $Miner_Name
                Path        = $Path
                Port        = $MinerAPIPort
                Type        = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                URI         = $Uri
                WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
            }
        }
    }
}

$Error.Clear()