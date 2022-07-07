using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://phoenixminer.info/downloads/PhoenixMiner_6.2c_Windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("EtcHash");                 Type = "AMD"; Fee = @(0.0065);   MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();                Arguments = " -amd -eres 1 -coin ETC" } # GMiner-v3.03 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s");      Type = "AMD"; Fee = @(0.009, 0); MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();                Arguments = " -amd -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("Ethash");                  Type = "AMD"; Fee = @(0.0065);   MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();                Arguments = " -amd -eres 1 -coin ETH" } # GMiner-v3.03 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");       Type = "AMD"; Fee = @(0.009, 0); MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();                Arguments = " -amd -eres 1 -coin ETH -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();                Arguments = " -amd -eres 1 -coin ETH" } # GMiner-v3.03 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @("RDNA", "RDNA2"); Arguments = " -amd -eres 1 -coin ETH -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");                 Type = "AMD"; Fee = @(0.0065);   MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @();                Arguments = " -amd -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake2s");      Type = "AMD"; Fee = @(0.009, 0); MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @("RDNA", "RDNA2"); Arguments = " -amd -eres 1 -coin UBQ -dcoin blake2s" }
      
    [PSCustomObject]@{ Algorithm = @("EtcHash");                 Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin ETC" } # GMiner-v3.03 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s");      Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("Ethash");                  Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin ETH" } # GMiner-v3.03 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");       Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin ETH -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin ETH" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin ETH -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");                 Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake2s");      Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin UBQ -dcoin blake2s" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm[0]).Host -and (-not $_.Algorithm[1] -or $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    # Intensities for 2. algorithm
    $Intensities = [PSCustomObject]@{ 
        "Blake2s" = @(10, 20, 30, 40)
    }

    # Build command sets for intensities
    $Algorithms = $Algorithms | ForEach-Object { 
        $_.PsObject.Copy()
        $Arguments = $_.Arguments
        ForEach ($Intensity in ($Intensities.($_.Algorithm[1]) | Select-Object)) { 
            $_ | Add-Member Arguments "$Arguments -sci $Intensity" -Force
            $_ | Add-Member Intensity $Intensity -Force
            $_.PsObject.Copy()
        }
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB + $_.MemReserveGB
            $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
            $AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $MinMemGB | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }

            If ($_.Type -eq "AMD" -and $_.Algorithm[1]) { 
                If ($_.MinMemGB -gt 4) { Return } # AMD: doesn't support Blake2s dual mining with DAG above 4GB
                $AvailableMiner_Devices = $AvailableMiner_Devices | Where-Object { [Version]$_.CIM.DriverVersion -le [Version]"27.20.22023.1004" } # doesn't support Blake2s dual mining on drivers newer than 21.8.1 (27.20.22023.1004)
            }

            If ($AvailableMiner_Devices) { 

                If ($_.Type -eq "NVIDIA" -and $_.Intensity) { $_.Intensity *= 5 } # Nvidia allows much higher intensity

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("amd", "eres", "nvidia") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " -pool $(If ($Pools.($_.Algorithm[0]).SSL) { "ssl://" })$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -wal $($Pools.($_.Algorithm[0]).User)"
                If ($Pools.($_.Algorithm[0]).WorkerName) { $_.Arguments += " -worker $($Pools.($_.Algorithm[0]).WorkerName)" }
                $_.Arguments += " -pass $($Pools.($_.Algorithm[0]).Pass)$(If ($Pools.($_.Algorithm[0]).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"

                If ($Pools.($_.Algorithm[0]).DAGsizeGB -gt 0) { 
                    If ($Pools.($_.Algorithm[0]).BaseName -in @("MiningPoolHub", "ProHashing")) { $_.Arguments += " -proto 1" }
                    ElseIf ($Pools.($_.Algorithm[0]).BaseName -eq "NiceHash") { $_.Arguments += " -proto 4" }
                }

                # kernel 3 does not support dual mining
                If (($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum / 1GB -ge 2 * $MinMemGB -and -not $_.Algorithm[1]) { # Faster kernels require twice as much VRAM
                    If ($AvailableMiner_Devices.Vendor -eq "AMD") { $_.Arguments += " -clkernel 3" }
                    ElseIf ($AvailableMiner_Devices.Vendor -eq "NVIDIA") { $_.Arguments += " -nvkernel 3" }
                }

                If ($_.Algorithm[1]) { 
                    $_.Arguments += " -dpool $(If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { "ssl://" })$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) -dwal $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) -dpass $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass)"
                    If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).WorkerName) { $_.Arguments += " -dworker $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).WorkerName)" }
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                If (-not $_.Intensity) { $_.WarmupTimes[1] += 45 } # Allow extra seconds for auto-tuning

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) -vmdag 0 -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d}' -f ($_ + 1) }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee # Dev fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
