If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $Variables.DriverVersion.CIM.AMD -le "20.45.01.28") -or $_.Type -eq "NVIDIA" })) { Return } # Only supports AMD drivers until 20.12.1

$Uri = "https://github.com/just-a-miner/moreepochs/releases/download/v2.7/MoreEpochs_Mod_of_Claymore_ETH_Miner_v15Win_by_JustAMiner_v2.7.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\EthDcrMiner64.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; Fee = 0.006; MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.77;       MinerSet = 1; Tuning = " -rxboost 1"; WarmupTimes = @(45, 0); Arguments = " -platform 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; Fee = 0.006; MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.77; MinerSet = 1; Tuning = " -rxboost 1"; WarmupTimes = @(45, 0); Arguments = " -platform 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool

    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.006; MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.77;       MinerSet = 1; Tuning = " -strap 1"; WarmupTimes = @(45, 0); Arguments = " -platform 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.006; MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.77; MinerSet = 1; Tuning = " -strap 1"; WarmupTimes = @(45, 0); Arguments = " -platform 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($MinerPools[0].($_.Algorithm).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { 
                    $Arguments += " -esm 3"
                    $Arguments += If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { " -epool stratum+ssl://" } Else { " -epool stratum+tcp://" }
                }
                Else { 
                    $Arguments += If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { " -epool ssl://" } Else { " -epool " }
                }
                $Arguments += "$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) -ewal $($MinerPools[0].($_.Algorithm).User)"
                $Arguments += " -epsw $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGB - $MinerPools[0].($_.Algorithm).DAGSizeGB))" })"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " -eworker $($MinerPools[0].($_.Algorithm).WorkerName)" }
                If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { $Arguments += " -checkcert 0" }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = ($AvailableMiner_Devices.Type | Select-Object -unique)
                    Path        = $Path
                    Arguments   = ("$($Arguments) -dbg -1 -wd 0 -retrydelay 3 -allpools 1 -allcoins 1 -mport -$MinerAPIPort -di $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee # Dev fee
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
