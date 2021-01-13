using module ..\Includes\Include.psm1

$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/PhoenixMiner/PhoenixMiner_5.4c_Windows.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "AMD"; Fee = @(0.0065);   MinerSet = 1; Arguments = " -amd -eres 1 -mi 12 -coin ETC" } # GMiner-v2.42 is just as fast, PhoenixMiner-v5.4c is maybe faster, bit I see lower sppeed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "AMD"; Fee = @(0.0065);   MinerSet = 1; Arguments = " -amd -eres 1 -mi 12" } # GMiner-v2.42 is just as fast, PhoenixMiner-v5.4c is maybe faster, bit I see lower sppeed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "AMD"; Fee = @(0.009, 0); MinerSet = 0; Arguments = " -amd -eres 1 -mi 12 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinerSet = 0; Arguments = " -amd -eres 1 -mi 12 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "AMD"; Fee = @(0.0065);   MinerSet = 0; Arguments = " -amd -eres 1 -mi 12 -coin UBQ" }

    [PSCustomObject]@{ Algorithm = @("EtcHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinerSet = 1; Arguments = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -coin ETC" } # GMiner-v2.42 is just as fast, PhoenixMiner-v5.4c is maybe faster, bit I see lower sppeed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash");             Type = "NVIDIA"; Fee = @(0.0065);   MinerSet = 1; Arguments = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15" } # GMiner-v2.42 is just as fast, PhoenixMiner-v5.4c is maybe faster, bit I see lower sppeed at the pool
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinerSet = 0; Arguments = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s");  Type = "NVIDIA"; Fee = @(0.009, 0); MinerSet = 0; Arguments = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinerSet = 1; Arguments = " -nvidia -eres 1 -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -coin UBQ" } # TTMiner-v5.0.3 is fastest
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

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $Arguments = $_.Arguments
                $MinMemGB = (3GB, ($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                If ($Pools.($_.Algorithm[0]).Epoch -gt 384 -and $_.Algorithm[1] -and $_.Type -eq "AMD") { Return } # Temp fix, dual mininig with AMD is broken (https://bitcointalk.org/index.php?topic=2647654.msg56002212#msg56002212)

                $Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })
                If ($_.Algorithm[1]) { $Miner_Devices = @($Miner_Devices | Where-Object { $_.OpenCL.Name -notmatch "$AMD Radeon RX 5[0-9]{3}.*" }) } # Dual mining not supported on Navi

                If ($Miner_Devices) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $Arguments = Get-ArgumentsPerDevice -Command $Arguments -ExcludeParameters @("amd", "eres", "nvidia") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Arguments += " -pool $(If ($Pools.($_.Algorithm[0]).SSL) { "ssl://" })$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -wal $($Pools.($_.Algorithm[0]).User) -pass $($Pools.($_.Algorithm[0]).Pass)"
                    If ($_.Algorithm[0] -in @("EtcHash", "Ethash", "UbqHash")) {
                        If ($Pools.($_.Algorithm[0]).Name -match "^NiceHash$|^MPH(|Coins)$") { 
                            $Arguments += " -proto 4"
                        }
                    }

                    If ($Miner_Devices.Vendor -eq "AMD") { 
                        If (($_.OpenCL.GlobalMemSize / 1GB) -ge (2 * $MinMemGB)) { 
                            # Faster AMD "turbo" kernels require twice as much VRAM
                            $Arguments += " -clkernel 3"
                        }
                    }

                    If ($_.Algorithm[1]) { 
                        $Arguments += " -dpool $(If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { "ssl://" })$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) -dwal $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) -dpass $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass)"
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$Arguments -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator + 1) }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API        = "EthMiner"
                        Port       = $MinerAPIPort
                        Wrap       = $false
                        URI        = $Uri
                        Fee        = $_.Fee # Dev fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                        WarmupTime = If ($Pools.($_.Algorithm[0]).Name -match "^MPH*") { 30 } Else { 0 } # Seconds, longer for MPH because of long connect issue
                    }
                }
            }
        }
    }
}
