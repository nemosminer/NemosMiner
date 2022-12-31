If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://phoenixminer.info/downloads/PhoenixMiner_6.2c_Windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("EtcHash");                 Type = "AMD"; Fee = @(0.0065);   MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;      MinerSet = 1; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 Arguments = " -amd -eres 1 -coin ETC" } # GMiner-v3.20 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake2s");      Type = "AMD"; Fee = @(0.009, 0); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;      MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 Arguments = " -amd -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                  Type = "AMD"; Fee = @(0.0065);   MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       MinerSet = 1; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 Arguments = " -amd -eres 1 -coin ETH" } # GMiner-v3.20 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake2s");       Type = "AMD"; Fee = @(0.009, 0); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 Arguments = " -amd -eres 1 -coin ETH -dcoin blake2s" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.42; MinerSet = 1; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                  Arguments = " -amd -eres 1 -coin ETH" } # GMiner-v3.10 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.42; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("RDNA1", "RDNA2");  Arguments = " -amd -eres 1 -coin ETH -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("UbqHash");                 Type = "AMD"; Fee = @(0.0065);   MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB + 0.42;      MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 Arguments = " -amd -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake2s");      Type = "AMD"; Fee = @(0.009, 0); MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB + 0.42;      MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("RDNA1", "RDNA2"); Arguments = " -amd -eres 1 -coin UBQ -dcoin blake2s" }
      
    [PSCustomObject]@{ Algorithms = @("EtcHash");                 Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;      MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin ETC" } # GMiner-v3.20 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake2s");      Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB + 0.42;      MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                  Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin ETH" } # GMiner-v3.20 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake2s");       Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin ETH -dcoin blake2s" }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.42; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin ETH" } # TTMiner-v5.0.3 is fastest
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.42; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin ETH -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("UbqHash");                 Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB + 0.42;      MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake2s");      Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB + 0.42;      MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin UBQ -dcoin blake2s" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }) { 

    # Intensities for 2. algorithm
    $IntensityValues = [PSCustomObject]@{ 
        "Blake2s" = @(10, 20, 30, 40)
    }

    # Build command sets for intensities
    $Algorithms = $Algorithms | ForEach-Object { 
        $_.PsObject.Copy()
        ForEach ($Intensity in ($IntensityValues.($_.Algorithms[1]) | Select-Object)) { 
            $_ | Add-Member Intensity $Intensity -Force
            $_.PsObject.Copy()
        }
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $Arguments = $_.Arguments
            $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
            $Intensity = $_.Intensity
            $WarmupTimes = $_.WarmupTimes.PSObject.Copy() 

            $AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $_.MinMemGB | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }
            If ($_.Type -eq "AMD" -and $_.Algorithms[1]) { 
                If ($_.MinMemGB -gt 4) { Return } # AMD: doesn't support Blake2s dual mining with DAG above 4GB
                $AvailableMiner_Devices = $AvailableMiner_Devices | Where-Object { [Version]$_.CIM.DriverVersion -le [Version]"27.20.22023.1004" } # doesn't support Blake2s dual mining on drivers newer than 21.8.1 (27.20.22023.1004)
            }

            If ($AvailableMiner_Devices) { 

                If ($_.Type -eq "NVIDIA" -and $Intensity) { $Intensity *= 5 } # Nvidia allows much higher intensity

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithms[1]) { "$($_.Algorithms[0])&$($_.Algorithms[1])" }) + @($Intensity) | Select-Object) -join '-' -replace ' '

                If (-not $Intensity) { 
                    $WarmupTimes[1] += 45
                 } # Allow extra time for auto tuning

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("amd", "eres", "nvidia") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " -pool $(If ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1]) { "ssl://" })$($MinerPools[0].($_.Algorithms[0]).Host):$($MinerPools[0].($_.Algorithms[0]).PoolPorts | Select-Object -Last 1) -wal $($MinerPools[0].($_.Algorithms[0]).User)"
                If ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1]) { $Arguments += " -weakssl" }
                If ($MinerPools[0].($_.Algorithms[0]).WorkerName) { $Arguments += " -worker $($MinerPools[0].($_.Algorithms[0]).WorkerName)" }
                $Arguments += " -pass $($MinerPools[0].($_.Algorithms[0]).Pass)$(If ($MinerPools[0].($_.Algorithms[0]).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGB - $MinerPools[0].($_.Algorithm).DAGSizeGB))" })"

                If ($MinerPools[0].($_.Algorithms[0]).DAGsizeGB -gt 0) { 
                    If ($MinerPools[0].($_.Algorithms[0]).BaseName -in @("MiningPoolHub", "ProHashing")) { $Arguments += " -proto 1" }
                    ElseIf ($MinerPools[0].($_.Algorithms[0]).BaseName -eq "NiceHash") { $Arguments += " -proto 4" }
                }

                # kernel 3 does not support dual mining
                If (($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum / 1GB -ge 2 * $MinMemGB -and -not $_.Algorithms[1]) { # Faster kernels require twice as much VRAM
                    If ($AvailableMiner_Devices.Vendor -eq "AMD") { $Arguments += " -clkernel 3" }
                    ElseIf ($AvailableMiner_Devices.Vendor -eq "NVIDIA") { $Arguments += " -nvkernel 3" }
                }

                If ($_.Algorithms[1]) { 
                    $Arguments += " -dpool $(If ($MinerPools[1].($_.Algorithms[1]).PoolPorts[1]) { "ssl://" })$($MinerPools[1].($_.Algorithms[1]).Host):$($MinerPools[0].($_.Algorithms[1]).PoolPorts | Select-Object -Last 1) -dwal $($MinerPools[1].($_.Algorithms[1]).User) -dpass $($MinerPools[1].($_.Algorithms[1]).Pass)"
                    # If ($MinerPools[1].($_.Algorithms[0]).PoolPorts[1]) { $Arguments += " -dweakssl" } #https://bitcointalk.org/index.php?topic=2647654.msg60898131#msg60898131
                    If ($MinerPools[1].($_.Algorithms[1]).WorkerName) { $Arguments += " -dworker $($MinerPools[1].($_.Algorithms[1]).WorkerName)" }
                    If ($Intensity) { $Arguments += " -sci $Intensity" }
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = ($AvailableMiner_Devices.Type | Select-Object -unique)
                    Path        = $Path
                    Arguments   = ("$($Arguments) -vmdag 0 -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d}' -f ($_ + 1) }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithms[0], $_.Algorithms[1] | Select-Object)
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee # Dev fee
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    WarmupTimes = $WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
