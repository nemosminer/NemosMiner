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
Version:        5.0.0.1
Version date:   2023/09/05
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAVersion -ge "10.0") } )) { Return }

$URI = "https://github.com/NebuTech/NBMiner/releases/download/v42.3/NBMiner_42.3_Win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nbminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2"; Type = "AMD"; Fee = 0.01; MinMemGiB = 0.77; AdditionalWin10MemGB = 0; MinerSet = 0; WarmupTimes = @(30, 0);  ExcludePools = @(); Arguments = " --algo ergo --platform 2" }
    [PSCustomObject]@{ Algorithm = "EtcHash";    Type = "AMD"; Fee = 0.01; MinMemGiB = 0.77; AdditionalWin10MemGB = 0; Minerset = 1; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo etchash --platform 2 -enable-dag-cache" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";     Type = "AMD"; Fee = 0.01; MinMemGiB = 0.77; AdditionalWin10MemGB = 0; Minerset = 2; WarmupTimes = @(45, 40); ExcludePools = @(); Arguments = " --algo ethash --platform 2" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "KawPow";     Type = "AMD"; Fee = 0.02; MinMemGiB = 0.77; AdditionalWin10MemGB = 0; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo kawpow --platform 2" } # XmRig-v6.17.0 is almost as fast but has no fee
 
    [PSCustomObject]@{ Algorithm = "BeamV3";     Type = "NVIDIA"; Fee = 0.02; MinMemGiB = 3;    AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; MinerSet = 0; Tuning = " -mt 1"; WarmupTimes = @(30, 40); ExcludePools = @(); Arguments = " --algo beamv3 --platform 1" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";   Type = "NVIDIA"; Fee = 0.02; MinMemGiB = 5;    AdditionalWin10MemGB = 1; MinComputeCapability = 6.0; Minerset = 1; Tuning = " -mt 1"; WarmupTimes = @(30, 30); ExcludePools = @(); Arguments = " --algo cuckoo_ae --platform 1" } # GMiner-v3.41 is fastest
    [PSCustomObject]@{ Algorithm = "Autolykos2"; Type = "NVIDIA"; Fee = 0.02; MinMemGiB = 0.77; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; Minerset = 1; Tuning = " -mt 1"; WarmupTimes = @(30, 0);  ExcludePools = @(); Arguments = " --algo ergo --platform 1" }
    [PSCustomObject]@{ Algorithm = "EtcHash";    Type = "NVIDIA"; Fee = 0.01; MinMemGiB = 0.77; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; Minerset = 2; Tuning = " -mt 1"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo etchash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";     Type = "NVIDIA"; Fee = 0.01; MinMemGiB = 0.77; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; Minerset = 2; Tuning = " -mt 1"; WarmupTimes = @(60, 0);  ExcludePools = @(); Arguments = " --algo ethash --platform 1 --enable-dag-cache" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "KawPow";     Type = "NVIDIA"; Fee = 0.02; MinMemGiB = 0.77; AdditionalWin10MemGB = 0; MinComputeCapability = 6.0; Minerset = 2; Tuning = " -mt 1"; WarmupTimes = @(45, 10); ExcludePools = @(); Arguments = " --algo kawpow --platform 1" } # XmRig-v6.17.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = "Octopus";    Type = "NVIDIA"; Fee = 0.03; MinMemGiB = 0.77; AdditionalWin10MemGB = 1; MinComputeCapability = 6.1; Minerset = 2; Tuning = " -mt 1"; WarmupTimes = @(45, 0);  ExcludePools = @(); Arguments = " --algo octopus --platform 1" } # Trex-v0.26.8 is fastest
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object BaseName -notin $ExcludePools)) { 

                $MinComputeCapability = $_.MinComputeCapability
                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                # Windows 10 requires more memory on some algos
                If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGiB += $_.AdditionalWin10MemGB }
                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $MinMemGiB | Where-Object { [Double]$_.OpenCL.ComputeCapability -ge $MinComputeCapability }) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    $Arguments = $_.Arguments
                    $Arguments += Switch ($Pool.Protocol) { 
                        "ethstratum1"  { " --url stratum"; Break }
                        "ethstratum2"  { " --url nicehash"; Break }
                        "ethstratumnh" { " --url nicehash"; Break }
                        Default        { " --url stratum" }
                    }
                    $Arguments += If ($Pool.PoolPorts[1]) { "+ssl://" } Else  { "+tcp://" }
                    $Arguments += "$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" })"
                    $Arguments += " --password $($Pool.Pass)"

                    # Optionally disable dev fee mining
                    If ($Config.DisableMinerFee) { 
                        $_.Fee = 0
                        $Arguments += " --fee 0"
                    }

                    # Apply tuning parameters
                    If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                    [PSCustomObject]@{ 
                        API         = "NBMiner"
                        Arguments   = "$Arguments --no-watchdog --api 127.0.0.1:$($MinerAPIPort) --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
                        DeviceNames = $AvailableMiner_Devices.Name
                        Fee         = @($_.Fee) # Dev fee
                        MinerSet    = $_.MinerSet
                        MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                        Name        = $Miner_Name
                        Path        = $Path
                        Port        = $MinerAPIPort
                        Type        = $_.Type
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                        Workers     = @(@{ Pool = $Pool })
                    }
                }
            }
        }
    }
}