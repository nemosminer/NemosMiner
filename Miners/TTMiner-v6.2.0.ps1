If ($Config.MinerInstancePerDeviceModel -and ($Devices.Model | Select-Object -Unique).Count -gt 1) { Return } # Error 'No cuda shared libraries found' if more than one active instance

$Uri = "https://github.com/Minerx117/miners/releases/download/TT-Miner/TT-Miner-v6.2.0.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";      Fee = 0.01; MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;      MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " -algo ETHASH -coin ETC -intensity 15" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.01; MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.01; MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.41; MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "KawPow";       Fee = 0.01; MinMemGB = $MinerPools[0].KawPow.DAGSizeGB + 0.42;       MinerSet = 1; WarmupTimes = @(60, 30); Arguments = " -algo KAWPOW -intensity 15" } # Trex-v0.26.8 is fastest
#   [PSCustomObject]@{ Algorithm = "MTP";          Fee = 0.01; MinMemGB = 3;                                            MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " -algo MTP -intensity 21" } # Algo is dead
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";  Fee = 0.01; MinMemGB = $MinerPools[0].ProgPowEpic.DAGSizeGB + 0.42;  MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " -algo PROGPOW -coin EPIC" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";  Fee = 0.01; MinMemGB = $MinerPools[0].ProgPowSero.DAGSizeGB + 0.42;  MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " -algo PROGPOW -coin SERO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";  Fee = 0.01; MinMemGB = $MinerPools[0].ProgPowVeil.DAGSizeGB + 0.42;  MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " -algo PROGPOW -coin VEIL" }
#   [PSCustomObject]@{ Algorithm = "ProgPowZ";     Fee = 0.01; MinMemGB = $MinerPools[0].ProgPowZ.DAGSizeGB + 0.42;     MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " -algo PROGPOWZ -coin ZANO" } # Error 'Error(-1): 'Invalid method'
    [PSCustomObject]@{ Algorithm = "UbqHash";      Fee = 0.01; MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB + 0.42;      MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " -algo UBQHASH -intensity 15" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGB -le 2) { $Arguments = $Arguments -replace " -intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($MinerPools[0].($_.Algorithm).Currency -in @("CLO", "ETC", "ETH", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZCOIN", "ZELS")) { 
                    $Arguments += " -coin $($MinerPools[0].($_.Algorithm).Currency)"
                }

                $Arguments += " -pool stratum+tcp://$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) -user $($MinerPools[0].($_.Algorithm).User)"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " -worker $($MinerPools[0].($_.Algorithm).WorkerName)" }
                $Arguments += " -pass $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGB - $MinerPools[0].($_.Algorithm).DAGSizeGB))" })"

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = ($AvailableMiner_Devices.Type | Select-Object -unique)
                    Path        = $Path
                    Arguments   = ("$($Arguments) -PRT 1 -PRS 0 -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
