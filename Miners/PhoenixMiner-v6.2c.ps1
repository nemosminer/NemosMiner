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
Version:        4.3.6.2
Version date:   2023/08/25
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$URI = "https://phoenixminer.info/downloads/PhoenixMiner_6.2c_Windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\PhoenixMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("EtcHash");                 Type = "AMD"; Fee = @(0.0065);   MinMemGiB = 2 * $AllMinerPools.Etchash.DAGSizeGiB + 0.77;  MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                  Arguments = " -amd -eres 1 -coin ETC" } # GMiner-v3.41 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake2s");      Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = 2 * $AllMinerPools.Etchash.DAGSizeGiB + 0.77;  MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                  Arguments = " -amd -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                  Type = "AMD"; Fee = @(0.0065);   MinMemGiB = $AllMinerPools.Ethash.DAGSizeGiB + 0.77;       MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                  Arguments = " -amd -eres 1" } # GMiner-v3.41 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake2s");       Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = $AllMinerPools.Ethash.DAGSizeGiB + 0.77;       MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                  Arguments = " -amd -eres 1 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("UbqHash");                 Type = "AMD"; Fee = @(0.0065);   MinMemGiB = $AllMinerPools.UbqHash.DAGSizeGiB + 0.77;      MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();                  Arguments = " -amd -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake2s");      Type = "AMD"; Fee = @(0.009, 0); MinMemGiB = $AllMinerPools.UbqHash.DAGSizeGiB + 0.77;      MinerSet = 0; Tuning = " -mi 12 -straps 1"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("RDNA1", "RDNA2");  Arguments = " -amd -eres 1 -coin UBQ -dcoin blake2s" }
      
    [PSCustomObject]@{ Algorithms = @("EtcHash");                 Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = 2 * $AllMinerPools.Etchash.DAGSizeGiB + 0.77;  Minerset = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin ETC" } # GMiner-v3.41 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake2s");      Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = 2 * $AllMinerPools.Etchash.DAGSizeGiB + 0.77;  MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin ETC -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                  Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = $AllMinerPools.Ethash.DAGSizeGiB + 0.77;       Minerset = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1" } # GMiner-v3.41 is just as fast, PhoenixMiner-v6.2c is maybe faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake2s");       Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = $AllMinerPools.Ethash.DAGSizeGiB + 0.77;       MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -dcoin blake2s" }
    [PSCustomObject]@{ Algorithms = @("UbqHash");                 Type = "NVIDIA"; Fee = @(0.0065);   MinMemGiB = $AllMinerPools.UbqHash.DAGSizeGiB + 0.77;      Minerset = 1; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin UBQ" }
    [PSCustomObject]@{ Algorithms = @("UbqHash", "Blake2s");      Type = "NVIDIA"; Fee = @(0.009, 0); MinMemGiB = $AllMinerPools.UbqHash.DAGSizeGiB + 0.77;      MinerSet = 0; Tuning = " -mi 12 -vmt1 15 -vmt2 12 -vmt3 0 -vmr 15 -mcdag 1"; WarmupTimes = @(45, 15); Arguments = " -nvidia -eres 1 -coin UBQ -dcoin blake2s" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).Epoch -le 602 }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0]."EtcHash".Epoch -lt 302 }

If ($Algorithms) { 

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

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $Algorithm0 = $_.Algorithms[0]
            $Algorithm1 = $_.Algorithms[1]
            $Arguments = $_.Arguments
            $Intensity = $_.Intensity
            $WarmupTimes = $_.WarmupTimes.PSObject.Copy() 

            $AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture
            If ($_.Type -eq "AMD" -and $Algorithm1) { 
                If ($_.MinMemGiB -gt 4) { Return } # AMD: doesn't support Blake2s dual mining with DAG larger 4GB
                $AvailableMiner_Devices = $AvailableMiner_Devices | Where-Object { [Version]$_.CIM.DriverVersion -le [Version]"27.20.22023.1004" } # doesn't support Blake2s dual mining on drivers newer than 21.8.1 (27.20.22023.1004)
            }

            If ($AvailableMiner_Devices) { 

                If ($_.Type -eq "NVIDIA" -and $Intensity) { $Intensity *= 5 } # Nvidia allows much higher intensity

                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($Algorithm1) { "-$($Algorithm0)&$($Algorithm1)" })$(If ($Intensity) { "-$Intensity" })" -replace ' '

                If ($Algorithm1 -and -not $Intensity) { 
                    # Allow extra time for auto tuning
                    $WarmupTimes[1] += 45
                }

                $Arguments += " -pool $(If ($AllMinerPools.$Algorithm0.PoolPorts[1]) { "ssl://" })$($AllMinerPools.$Algorithm0.Host):$($AllMinerPools.$Algorithm0.PoolPorts | Select-Object -Last 1) -wal $($AllMinerPools.$Algorithm0.User)"
                $Arguments += Switch ($AllMinerPools.$Algorithm0.Protocol) {
                    "ethproxy"     { " -proto 2"; Break }
                    "minerproxy"   { " -proto 1"; Break }
                    "ethstratum1"  { " -proto 4"; Break }
                    "ethstratum2"  { " -proto 5"; Break }
                    "ethstratumnh" { " -proto 5"; Break }
                    "qtminer"      { " -proto 3"; Break }
                    Default        { " -proto 1" }
                }
                If ($AllMinerPools.$Algorithm0.PoolPorts[1]) { $Arguments += " -weakssl" }
                If ($AllMinerPools.$Algorithm0.WorkerName) { $Arguments += " -worker $($AllMinerPools.$Algorithm0.WorkerName)" }
                $Arguments += " -pass $($AllMinerPools.$Algorithm0.Pass)"

                If ($AllMinerPools.$Algorithm0.DAGSizeGiB -gt 0) { 
                    If ($AllMinerPools.$Algorithm0.BaseName -in @("MiningPoolHub", "ProHashing")) { $Arguments += " -proto 1" }
                    ElseIf ($AllMinerPools.$Algorithm0.BaseName -eq "NiceHash") { $Arguments += " -proto 4" }
                }

                # kernel 3 does not support dual mining
                If (($AvailableMiner_Devices.Memory | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum) / 1GB -ge 2 * $MinMemGiB -and -not $Algorithm1) { # Faster kernels require twice as much VRAM
                    If ($AvailableMiner_Devices.Vendor -eq "AMD") { $Arguments += " -clkernel 3" }
                    ElseIf ($AvailableMiner_Devices.Vendor -eq "NVIDIA") { $Arguments += " -nvkernel 3" }
                }

                If ($Algorithm1) { 
                    $Arguments += " -dpool $(If ($AllMinerPools.$Algorithm1.PoolPorts[1]) { "ssl://" })$($AllMinerPools.$Algorithm1.Host):$($AllMinerPools.$Algorithm1.PoolPorts | Select-Object -Last 1) -dwal $($AllMinerPools.$Algorithm1.User) -dpass $($AllMinerPools.$Algorithm1.Pass)"
                    # If ($AllMinerPools.$Algorithm0.PoolPorts[1]) { $Arguments += " -dweakssl" } #https://bitcointalk.org/index.php?topic=2647654.msg60898131#msg60898131
                    If ($AllMinerPools.$Algorithm1.WorkerName) { $Arguments += " -dworker $($AllMinerPools.$Algorithm1.WorkerName)" }
                    If ($Intensity) { $Arguments += " -sci $Intensity" }
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithms | Select-Object)
                    API         = "EthMiner"
                    Arguments   = ("$Arguments -vmdag 0 -log 0 -wdog 0 -cdmport $MinerAPIPort -gpus $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d}' -f ($_ + 1) }) -join ',')" -replace "\s+", " ").trim()
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
                }
            }
        }
    }
}