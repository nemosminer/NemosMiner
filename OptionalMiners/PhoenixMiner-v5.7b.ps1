using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$Uri = "https://phoenixminer.info/downloads/beta/PhoenixMiner_5.7b_Windows.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = 3.0; MinerSet = 1; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1 -coin ETC" } # GMiner-v2.70 is just as fast, PhoenixMiner-v5.7b is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 3.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "AMD"; Fee = @(0.0065);   MinMemGB = 5.0; MinerSet = 1; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1" } # GMiner-v2.70 is just as fast, PhoenixMiner-v5.7b is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");       Type = "AMD"; Fee = @(0.0065);   MinMemGB = 2.0; MinerSet = 1; Tuning = " -mi 12"; WarmupTimes = @(0, 20); Arguments = " -amd -eres 1" } # GMiner-v2.70 is just as fast, PhoenixMiner-v5.7b is maybe faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 5.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1 -coin ETH -dcoin blake2s" } # Dual mininig ETH with AMD is broken (https://bitcointalk.org/index.php?topic=2647654.msg57622839#msg57622839)
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = 4.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1 -coin UBQ" }
    # [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 4.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(0, 30); Arguments = " -amd -eres 1 -coin UBQ -dcoin blake2s" } # Dual mininig UBQ with AMD is broken (https://bitcointalk.org/index.php?topic=2647654.msg57622839#msg57622839)

    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 3.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1 -coin ETC" } # GMiner-v2.70 is just as fast, PhoenixMiner-v5.7b is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 3.0; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 5.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1" } # GMiner-v2.70 is just as fast, PhoenixMiner-v5.7b is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 5.0; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");       Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 2.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 4.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 4.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(0, 30); Arguments = " -nvidia -eres 1 -coin UBQ -dcoin blake2s" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    # Intensities for 2. algorithm
    $Intensities = [PSCustomObject]@{ 
        "Blake2s" = @($null, 10, 20, 30, 40) # $null is for auto-tuning
    }

    # Build command sets for intensities
    $AlgorithmDefinitions = $AlgorithmDefinitions | ForEach-Object { 
        $_.PsObject.Copy()
        $Arguments = $_.Arguments
        ForEach ($Intensity in ($Intensities.($_.Algorithm[1]) | Select-Object)) { 
            $_ | Add-Member Arguments "$Arguments -sci $Intensity" -Force
            $_ | Add-Member Intensity $Intensity -Force
            $_.PsObject.Copy()
        }
    }

    $Devices | Where-Object Type -in @($AlgorithmDefinitions.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($Miner_Devices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

                $MinMemGB = If ($Pools.($_.Algorithm[0]).DAGSize -gt 0) { ((($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

                $AvailableMiner_Devices = @($Miner_Devices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })

                If ($_.Algorithm[1]) { $AvailableMiner_Devices = @($AvailableMiner_Devices | Where-Object { $_.Model -notmatch "^Radeon RX (5|6)[0-9]{3}.*" }) } # Dual mining not supported on Navi

                If ($AvailableMiner_Devices) { 

                    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-'

                    # Get arguments for available miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("amd", "eres", "nvidia") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                    $Pass = If ($Pools.($_.Algorithm).Name -match "^ProHashing.*$" -and $_.Algorithm -eq "EthashLowMem") { "$($Pools.($_.Algorithm[0]).Pass),l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" } Else { $($Pools.($_.Algorithm[0]).Pass) }

                    $_.Arguments += " -pool $(If ($Pools.($_.Algorithm[0]).SSL) { "ssl://" })$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -wal $($Pools.($_.Algorithm[0]).User) -pass $Pass"

                    If ($Pools.($_.Algorithm[0]).DAGsize -gt 0) {
                        If ($Pools.($_.Algorithm[0]).Name -match "^MiningPoolHub(|Coins)$") { 
                            $_.Arguments += " -proto 1"
                        }
                        If ($Pools.($_.Algorithm[0]).Name -match "^NiceHash$") { 
                            $_.Arguments += " -proto 4"
                        }
                    }

                    If (($AvailableMiner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB -ge 2 * $MinMemGB) { # Faster kernels require twice as much VRAM
                        If ($AvailableMiner_Devices.Vendor -eq "AMD" -and -not $_.Algorithm[1]) { # Dual mining on AMD not supported
                            $_.Arguments += " -clkernel 3"
                        }
                        ElseIf ($AvailableMiner_Devices.Vendor -eq "NVIDIA") { 
                            $_.Arguments += " -nvkernel 3" # Miner will switch to nvKernel 2 if unsuported
                        }
                    }

                    If ($_.Algorithm[1]) { 
                        $_.Arguments += " -dpool $(If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { "ssl://" })$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) -dwal $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) -dpass $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass)"
                    }

                    If ($Config.UseMinerTweaks -eq $true) { 
                        $_.Arguments += $_.Tuning
                    }

                    If (-not $_.Intensity) { $_.WarmupTimes[0] += 45; $_.WarmupTimes[1] += 45 } # Allow extra seconds for auto-tuning
                    If ($Pools.($_.Algorithm[0]).Name -match "^MiningPoolHub(|Coins)$") { $_.WarmupTimes[0] += 15; $_.WarmupTimes[1] += 15 } # Allow extra seconds for MPH because of long connect issue

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name -replace " "
                        DeviceName  = $AvailableMiner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = ("$($_.Arguments) -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($AvailableMiner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:d}' -f ($_.$DeviceEnumerator + 1) }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm   = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API         = "EthMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee # Dev fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)"
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
