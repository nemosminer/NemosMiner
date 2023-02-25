If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Eaglesong";    MinMemGiB = 2;                                             Minerset = 3; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo EAGLESONG" } # ASIC
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 0.62;       Minerset = 0; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo ETHASH -intensity 15" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 0.61; Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo ETHASH -intensity 15" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "KawPow";       MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 0.62;       Minerset = 2; WarmupTimes = @(90, 60); ExcludeGPUArchitecture = @(); ExcludePool = @("HashCryptos", "MiningDutch", "ProHashing"); Arguments = " -algo KAWPOW" }
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";     MinMemGiB = 2;                                             Minerset = 2; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo LYRA2V3" } # ASIC
    [PSCustomObject]@{ Algorithm = "MTP";          MinMemGiB = 3;                                             Minerset = 2; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo MTP -intensity 21" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";  MinMemGiB = $MinerPools[0].ProgPowEpic.DAGSizeGiB + 0.62;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo PROGPOW -coin EPIC" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";  MinMemGiB = $MinerPools[0].ProgPowSero.DAGSizeGiB + 0.62;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo PROGPOW -coin SERO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";  MinMemGiB = $MinerPools[0].ProgPowVeil.DAGSizeGiB + 0.62;  Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo PROGPOW -coin VEIL" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";  MinMemGiB = $MinerPools[0].ProgPowZano.DAGSizeGiB + 0.62;  MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo PROGPOWZ -coin ZANO" }
    [PSCustomObject]@{ Algorithm = "UbqHash";      MinMemGiB = $MinerPools[0].UbqHash.DAGSizeGiB + 0.62;      MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo UBQHASH -intensity 15" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] } | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object { $_.Algorithm -ne "Ethash" -or $MinerPools[0].Ethash.Epoch -le 384 <# Miner supports Ethash up to epoch 384 #> } | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture ) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGiB -le 2) { $Arguments = $Arguments -replace " -intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($MinerPools[0].($_.Algorithm).Currency -in @("CLO", "ETC", "ETH", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZCOIN", "ZELS")) { 
                    $Arguments += " -coin $($MinerPools[0].($_.Algorithm).Currency)"
                }
                $Arguments += If ($MinerPools[0].($_.Algorithm).Protocol -like "ethproxy*" -or $_.Algorithm -eq "ProgPowZano") { " -pool stratum1+tcp://" } Else { " -pool stratum+tcp://" }
                $Arguments += "$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) -user $($MinerPools[0].($_.Algorithm).User)"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " -worker $($MinerPools[0].($_.Algorithm).WorkerName)" }
                $Arguments += " -pass $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].($_.Algorithm).DAGSizeGiB))" })"

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Arguments   = ("$($Arguments) -PRT 1 -PRS 0 -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = 0
                    MinerSet    = $_.MinerSet
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
}
