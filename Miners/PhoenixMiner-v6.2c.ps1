<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
Version:        5.0.0.4
Version date:   2023/09/22
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$URI = "https://phoenixminer.info/downloads/PhoenixMiner_6.2c_Windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("EtcHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 ExcludePools = @(@(), @()); Arguments = " -amd -eres 1 -coin ETC" } # GMiner-v3.41 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 ExcludePools = @(@(), @()); Arguments = " -amd -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("Ethash");             Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 ExcludePools = @(@(), @()); Arguments = " -amd -eres 1" } # GMiner-v3.41 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake2s");  Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 ExcludePools = @(@(), @()); Arguments = " -amd -eres 1 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("UbqHash");            Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                 ExcludePools = @(@(), @()); Arguments = " -amd -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake2s"); Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("RDNA1", "RDNA2"); ExcludePools = @(@(), @()); Arguments = " -amd -eres 1 -coin UBQ -dcoin blake2s" }
      
    [PSCustomObject]@{ Algorithms = @("EtcHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 0.77; Minerset = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 1 -coin ETC" } # GMiner-v3.41 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("Ethash");             Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 0.77; Minerset = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 1" } # GMiner-v3.41 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake2s");  Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 1 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("UbqHash");            Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 0.77; Minerset = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake2s"); Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 0.77; MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); ExcludePools = @(@(), @()); Arguments = " -nvidia -eres 1 -coin UBQ -dcoin blake2s" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms | Where-Object { -not $_.Algorithms[1] } | ForEach-Object { $_.Algorithms += "" }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]] } | Where-Object { $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]].BaseName -notin $_.ExcludePools[0] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[1][$_.Algorithms[1]].BaseName -notin $_.ExcludePools[1] }

If ($Algorithms) { 

    # Intensities for 2. algorithm
    $IntensityValues = [PSCustomObject]@{ 
        "Blake2s" = @(10, 20, 30, 40)
    }

    # Build command sets for intensities
    $Algorithms = $Algorithms | Where-Object { $_.Algorithms[1] } | ForEach-Object { 
        $Intensity = $_.Intensity
        $WarmupTimes = $_.WarmupTimes.PsObject.Copy()
        If ($_.Type -eq "NVIDIA" -and $Intensity) { $Intensity *= 5 } # Nvidia allows much higher intensity
        $_.PsObject.Copy()
        ForEach ($Intensity in ($IntensityValues.($_.Algorithms[1]) | Select-Object)) { 
            $_ | Add-Member Intensity $Intensity -Force
            # Allow extra time for auto tuning
            $_.WarmupTimes[1] = $WarmupTimes[1] + 45
            $_.PsObject.Copy()
        }
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool0 in ($MinerPools[0][$_.Algorithms[0]] | Where-Object BaseName -notin $_.ExcludePools[0] | Where-Object { $_.Epoch -lt 602 } | Where-Object { $_.Algorithm -ne "EtcHash" -or $_.Epoch -lt 302 })) { 
                ForEach ($Pool1 in ($MinerPools[1][$_.Algorithms[1]] | Where-Object BaseName -notin $ExcludePools[1])) { 

                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                    If ($Pool0.Algorithm -eq "EtcHash") { $MinMemGiB += $Pool0.DAGSizeGiB }
                    If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                        If ($_.Type -eq "AMD" -and $_.Algorithms[1]) { 
                            If ($_.MinMemGiB -gt 4) { Return } # AMD: doesn't support Blake2s dual mining with DAG larger 4GB
                            $AvailableMiner_Devices = $AvailableMiner_Devices | Where-Object { [Version]$_.CIM.DriverVersion -le [Version]"27.20.22023.1004" } # doesn't support Blake2s dual mining on drivers newer than 21.8.1 (27.20.22023.1004)
                        }

                        If ($AvailableMiner_Devices) { 

                            $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })$(If ($_.Intensity) { "-$($_.Intensity)" })"

                            $Arguments = $_.Arguments
                            $Arguments += " -pool $(If ($Pool0.PoolPorts[1]) { "ssl://" })$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1) -wal $($Pool0.User)"
                            $Arguments += Switch ($Pool0.Protocol) {
                                "ethproxy"     { " -proto 2" }
                                "minerproxy"   { " -proto 1" }
                                "ethstratum1"  { " -proto 4" }
                                "ethstratum2"  { " -proto 5" }
                                "ethstratumnh" { " -proto 5" }
                                "qtminer"      { " -proto 3" }
                                Default        { " -proto 1" }
                            }
                            If ($Pool0.PoolPorts[1]) { $Arguments += " -weakssl" }
                            If ($Pool0.WorkerName) { $Arguments += " -worker $($Pool0.WorkerName)" }
                            $Arguments += " -pass $($Pool0.Pass)"

                            If ($Pool0.DAGSizeGiB -gt 0) { 
                                If ($Pool0.BaseName -in @("MiningPoolHub", "ProHashing")) { $Arguments += " -proto 1" }
                                ElseIf ($Pool0.BaseName -eq "NiceHash") { $Arguments += " -proto 4" }
                            }

                            # kernel 3 does not support dual mining
                            If (($AvailableMiner_Devices.Memory | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum) / 1GB -ge 2 * $MinMemGiB -and -not $_.Algorithms[1]) { # Faster kernels require twice as much VRAM
                                If ($AvailableMiner_Devices.Vendor -eq "AMD") { $Arguments += " -clkernel 3" }
                                ElseIf ($AvailableMiner_Devices.Vendor -eq "NVIDIA") { $Arguments += " -nvkernel 3" }
                            }

                            If ($_.Algorithms[1]) { 
                                $Arguments += " -dpool $(If ($Pool1.PoolPorts[1]) { "ssl://" })$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1) -dwal $($Pool1.User) -dpass $($Pool1.Pass)"
                                # If ($Pool0.PoolPorts[1]) { $Arguments += " -dweakssl" } #https://bitcointalk.org/index.php?topic=2647654.msg60898131#msg60898131
                                If ($Pool1.WorkerName) { $Arguments += " -dworker $($Pool1.WorkerName)" }
                                If ($_.Intensity) { $Arguments += " -sci $($_.Intensity)" }
                            }

                            # Apply tuning parameters
                            If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = "$Arguments -vmdag 0 -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d}' -f ($_ + 1) }) -join ',')"
                                DeviceNames = $AvailableMiner_Devices.Name
                                Fee         = @($_.Fee) # Dev fee
                                MinerSet    = $_.MinerSet
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                Name        = $Miner_Name
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = $_.Type
                                URI         = $Uri
                                WarmupTimes = $WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @($Pool0, $Pool1 | Where-Object { $_ } | ForEach-Object { @{ Pool = $_ } })
                            }
                        }
                    }
                }
            }
        }
    }
}