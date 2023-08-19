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
Version:        4.3.6.1
Version date:   2023/08/19
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$URI = "https://github.com/develsoftware/GMinerRelease/releases/download/3.41/gminer_3_41_windows64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithms = @("Autolykos2");   Type = "AMD"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = ""; Minerset = 2; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             Arguments = " --nvml 1 --algo autolykos2 --cuda 0 --opencl 1" } # Algorithm not yet supported
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo32");   Type = "AMD"; Fee = @(0.05);  MinMemGiB = 8.0;  Tuning = ""; Minerset = 3; WarmupTimes = @(30, 0);  ExcludePools = @(@(), @());             Arguments = " --nvml 1 --algo cuckatoo32 --cuda 0 --opencl 1" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Equihash1254"); Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1.8;  Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             Arguments = " --nvml 1 --algo equihash125_4 --cuda 0 --opencl 1" } # lolMiner-v1.76a is fastest
    [PSCustomObject]@{ Algorithms = @("Equihash1445"); Type = "AMD"; Fee = @(0.02);  MinMemGiB = 1.8;  Tuning = ""; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludePools = @(@("ProHashing"), @()); Arguments = " --nvml 1 --algo equihash144_5 $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1445.Currency -DefaultCommand "--pers auto") --cuda 0 --opencl 1" } # FPGA
    [PSCustomObject]@{ Algorithms = @("Equihash2109"); Type = "AMD"; Fee = @(0.02);  MinMemGiB = 2.8;  Tuning = ""; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             Arguments = " --nvml 1 --algo equihash210_9 --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash");       Type = "AMD"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = ""; Minerset = 1; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());             Arguments = " --nvml 1 --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("KawPow");       Type = "AMD"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = ""; Minerset = 2; WarmupTimes = @(45, 30); ExcludePools = @(@(), @());             Arguments = " --nvml 1 --algo kawpow --cuda 0 --opencl 1" }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.57; Tuning = " --mt 2"; Minerset = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo autolykos2 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "IronFish");     Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.57; Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo autolykos2 --dalgo ironfish --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "SHA512256d");   Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.57; Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo autolykos2 --dalgo radiant --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("BeamV3");                     Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 6.0;  Tuning = " --mt 2"; Minerset = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo beamhash --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo32");                 Type = "NVIDIA"; Fee = @(0.05);  MinMemGiB = 8.0;  Tuning = " --mt 2"; Minerset = 3; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo cuckatoo32 --cuda 1 --opencl 0" } # ASIC
    [PSCustomObject]@{ Algorithms = @("Cuckaroo30CTX");              Type = "NVIDIA"; Fee = @(0.05);  MinMemGiB = 8.0;  Tuning = " --mt 2"; Minerset = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo cortex --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Cuckoo29");                   Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 6.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo aeternity --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Equihash1254");               Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 3.0;  Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo equihash125_4 --cuda 1 --opencl 0" } # MiniZ-v2.1c is fastest
    [PSCustomObject]@{ Algorithms = @("Equihash1445");               Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 2.1;  Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@("ProHashing"), @()); Arguments = " --nvml 0 --algo equihash144_5 $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1445.Currency -DefaultCommand "--pers auto") --cuda 1 --opencl 0" } # FPGA
    [PSCustomObject]@{ Algorithms = @("Equihash2109");               Type = "NVIDIA"; Fee = @(0.02);  MinMemGiB = 1.0;  Tuning = " --mt 2"; Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo equihash210_9 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo etchash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "IronFish");        Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.57; Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo etchash --dalgo ironfish --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo etchash --dalgo kheavyhash --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA512256d");      Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.57; Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo etchash --dalgo radiant --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Ethash");                     Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo ethash --cuda 1 --opencl 0" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = " --mt 2"; Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo ethash --dalgo kheavyhash --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("FiroPow");                    Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.24; Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo firo --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("IronFish");                   Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo ironfish --cuda 1 --opencl 0" } # XmRig-v6.20.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithms = @("KawPow");                     Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.93; Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo kawpow --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 2.0;  Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo kaspa --cuda 1 --opencl 0" } # XmRig-v6.20.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithms = @("Octopus");                    Type = "NVIDIA"; Fee = @(0.03);  MinMemGiB = 0.88; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo octopus --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Octopus", "IronFish");        Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = " --mt 2"; Minerset = 0; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo octopus --dalgo ironfish --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Octopus", "kHeavyHash");      Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = " --mt 2"; Minerset = 0; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo octopus --dalgo kheavyhash --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("Octopus", "SHA512256d");      Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = " --mt 2"; Minerset = 0; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo octopus --dalgo radiant --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("ProgPowSero");                Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 0.88; Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo sero --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");                 Type = "NVIDIA"; Fee = @(0.01);  MinMemGiB = 1.0;  Tuning = " --mt 2"; Minerset = 1; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());             Arguments = " --nvml 0 --algo radiant --cuda 1 --opencl 0" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).BaseName -notin $_.ExcludePools[0] -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).BaseName -notin $_.ExcludePools[1]) }

If ($Algorithms) { 

    $Algorithms | ForEach-Object { 
        $_.MinMemGiB += $AllMinerPools.($_.Algorithms[0]).DAGSizeGiB
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })" -replace ' '

                $Arguments += " --server $($AllMinerPools.($_.Algorithms[0]).Host):$($AllMinerPools.($_.Algorithms[0]).PoolPorts | Select-Object -Last 1)"
                $Arguments += Switch ($AllMinerPools.($_.Algorithms[0]).Protocol) { 
                    "ethstratum1"  { " --proto stratum"; Break }
                    "ethstratum2"  { " --proto stratum"; Break }
                    "ethstratumnh" { " --proto stratum"; Break }
                    Default        { "" }
                }
                If ($AllMinerPools.($_.Algorithms[0]).PoolPorts[1]) { $Arguments += " --ssl 1" }
                $Arguments += " --user $($AllMinerPools.($_.Algorithms[0]).User)"
                $Arguments += " --pass $($AllMinerPools.($_.Algorithms[0]).Pass)"
                If ($AllMinerPools.($_.Algorithms[0]).WorkerName) { $Arguments += " --worker $($AllMinerPools.($_.Algorithms[0]).WorkerName)" }

                If (($_.Algorithms[1])) { 
                    $Arguments += " --dserver $($AllMinerPools.($_.Algorithms[1]).Host):$($AllMinerPools.($_.Algorithms[1]).PoolPorts | Select-Object -Last 1)"
                    If ($AllMinerPools.($_.Algorithms[1]).PoolPorts[1]) { $Arguments += " --dssl 1" }
                    $Arguments += " --duser $($AllMinerPools.($_.Algorithms[1]).User)"
                    $Arguments += " --dpass $($AllMinerPools.($_.Algorithms[1]).Pass)"
                    If ($AllMinerPools.($_.Algorithms[1]).WorkerName) { $Arguments += " --dworker $($AllMinerPools.($_.Algorithms[1]).WorkerName)" }
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                # Contest ETH address (if ETH wallet is specified in config)
                # $Arguments += If ($Config.Wallets.ETH) { " --contest_wallet $($Config.Wallets.ETH)" } Else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithms | Select-Object)
                    API         = "Gminer"
                    Arguments   = ("$Arguments --api $MinerAPIPort --watchdog 0 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = $_.Type
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}