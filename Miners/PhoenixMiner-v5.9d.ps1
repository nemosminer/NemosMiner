using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://phoenixminer.info/downloads/PhoenixMiner_5.9d_Windows.zip"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = 3.0; MinerSet = 1; Tuning = " -mi 12"; WarmupTimes = @(45, 0); Arguments = " -amd -eres 1 -coin ETC" } # GMiner-v2.75 is just as fast, PhoenixMiner-v5.9d is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 3.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(45, 0); Arguments = " -amd -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "AMD"; Fee = @(0.0065);   MinMemGB = 5.0; MinerSet = 1; Tuning = " -mi 12"; WarmupTimes = @(45, 0); Arguments = " -amd -eres 1" } # GMiner-v2.75 is just as fast, PhoenixMiner-v5.9d is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");       Type = "AMD"; Fee = @(0.0065);   MinMemGB = 2.0; MinerSet = 1; Tuning = " -mi 12"; WarmupTimes = @(45, 0); Arguments = " -amd -eres 1" } # GMiner-v2.75 is just as fast, PhoenixMiner-v5.9d is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 5.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(45, 0); Arguments = " -amd -eres 1 -coin ETH -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGB = 4.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(45, 0); Arguments = " -amd -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGB = 4.0; MinerSet = 0; Tuning = " -mi 12"; WarmupTimes = @(45, 0); Arguments = " -amd -eres 1 -coin UBQ -dcoin blake2s" }

    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 3.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin ETC" } # GMiner-v2.75 is just as fast, PhoenixMiner-v5.9d is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 3.0; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 5.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1" } # GMiner-v2.75 is just as fast, PhoenixMiner-v5.9d is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 5.0; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");       Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 2.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGB = 4.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGB = 4.0; MinerSet = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 0); Arguments = " -nvidia -eres 1 -coin UBQ -dcoin blake2s" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    # Intensities for 2. algorithm
    $Intensities = [PSCustomObject]@{ 
        "Blake2s" = @($null, 10, 20, 30, 40) # $null is for auto-tuning
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

            $MinMemGB = If ($Pools.($_.Algorithm[0]).DAGSize -gt 0) { ((($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            $AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }

            If ($_.Type -eq "AMD" -and $_.Algorithm[1]) { 
                If ((($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) / 1GB) -gt 4) { Return } # AMD: doesn't support Blake2s dual mining with DAG above 4GB
                $AvailableMiner_Devices = $AvailableMiner_Devices | Where-Object { $_.Model -notmatch "^Radeon RX (5|6)[0-9]{3}.*" } # Dual mining not supported on Navi(2)
                $AvailableMiner_Devices = $AvailableMiner_Devices | Where-Object { [Version]$_.CIM.DriverVersion -le [Version]"27.20.22023.1004" } # doesn't support Blake2s dual mining on drivers newer than 21.8.1 (27.20.22023.1004)
            }
            If ($_.Type -eq "NVIDIA" -and $_.Intensity) { $_.Intensity *= 5 } # Nvidia allows much higher intensity

            If ($AvailableMiner_Devices) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("amd", "eres", "nvidia") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Pass = If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { "$($Pools.($_.Algorithm[0]).Pass),l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" } Else { $($Pools.($_.Algorithm[0]).Pass) }

                $_.Arguments += " -pool $(If ($Pools.($_.Algorithm[0]).SSL) { "ssl://" })$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -wal $($Pools.($_.Algorithm[0]).User) -pass $Pass"

                If ($Pools.($_.Algorithm[0]).DAGsize -gt 0) { 
                    If ($Pools.($_.Algorithm[0]).BaseName -eq "MiningPoolHub") { $_.Arguments += " -proto 1" }
                    If ($Pools.($_.Algorithm[0]).BaseName -eq "NiceHash") { $_.Arguments += " -proto 4" }
                }

                If (($AvailableMiner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum / 1GB -ge 2 * $MinMemGB) { # Faster kernels require twice as much VRAM
                    # clkernel 3 does not support dual mining
                    If ($AvailableMiner_Devices.Vendor -eq "AMD" -and -not $_.Algorithm[1]) { $_.Arguments += " -clkernel 3" }
                    # Miner will switch to nvKernel 2 if unsuported
                    ElseIf ($AvailableMiner_Devices.Vendor -eq "NVIDIA") { $_.Arguments += " -nvkernel 3" }
                }

                If ($_.Algorithm[1]) { $_.Arguments += " -dpool $(If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { "ssl://" })$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) -dwal $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) -dpass $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass)" }

                If ($Config.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                If (-not $_.Intensity) { $_.WarmupTimes[1] += 45 } # Allow extra seconds for auto-tuning
                If ($Pools.($_.Algorithm[0]).BaseName -eq "MiningPoolHub") { $_.WarmupTimes[0] += 15; $_.WarmupTimes[1] += 15 } # Allow extra seconds for MPH because of long connect issue

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $_.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d}' -f ($_ + 1) }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
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
