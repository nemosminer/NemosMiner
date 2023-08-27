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

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -in @("AMD", "INTEL") -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge "460.27.03" ) })) { Return }

$URI = "https://github.com/bzminer/bzminer/releases/download/v16.0.2/bzminer_v16.0.2_windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\bzminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Autolykos2"); Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a ergo") }
    [PSCustomObject]@{ Algorithms = @("Blake3");     Type = "AMD"; Fee = 0.005; MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");    Type = "AMD"; Fee = 0.005; MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("GCN4"); ExcludePools = @(@(), @());           Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("Ethash");     Type = "AMD"; Fee = 0.005; MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("GCN4"); ExcludePools = @(@(), @());           Arguments = @(" -a ethash") }
    [PSCustomObject]@{ Algorithms = @("Ethash3B");   Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a rethereum") }
    [PSCustomObject]@{ Algorithms = @("IronFish");   Type = "AMD"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();       ExcludePools = @(@("Nicehash"), @()); Arguments = @(" -a ironfish") }# https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("KawPow");     Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("GCN4"); ExcludePools = @(@(), @());           Arguments = @(" -a rvn") } # https://github.com/bzminer/bzminer/issues/264
    [PSCustomObject]@{ Algorithms = @("kHeavyHash"); Type = "AMD"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a kaspa") }
    [PSCustomObject]@{ Algorithms = @("NexaPow");    Type = "AMD"; Fee = 0.02;  MinMemGiB = 3;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a nexa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace");  Type = "AMD"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a octa") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d"); Type = "AMD"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA256dt");   Type = "AMD"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a novo") }
    [PSCustomObject]@{ Algorithms = @("SHA3d");      Type = "AMD"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a kylacoin") }
    [PSCustomObject]@{ Algorithms = @("Skein2");     Type = "AMD"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludePools = @(@(), @());           Arguments = @(" -a woodcoin") }

    [PSCustomObject]@{ Algorithms = @("EtcHash"); Type = "INTEL"; Fee = 0.005;  MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("Ethash");  Type = "INTEL"; Fee = 0.005;  MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ethash") }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");               Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a ergo") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "kHeavyHash"); Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a ergo", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "SHA512256d"); Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a ergo", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Blake3");                   Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                  Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");        Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a etchash", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "IronFish");      Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @("Nicehash")); Arguments = @(" -a etchash", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a etchash", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA512256d");    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a etchash", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Ethash");                   Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a ethash") }
    [PSCustomObject]@{ Algorithms = @("Ethash3B");                 Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a rethereum") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");         Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a ethash", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "IronFish");       Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @("Nicehash")); Arguments = @(" -a ethash", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");     Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a ethash", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "SHA512256d");     Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a ethash", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("IronFish");                 Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@("Nicehash"), @()); Arguments = @(" -a ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("KawPow");                   Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a rvn") }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");               Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a kaspa") }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                  Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = 3;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a nexa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace");                Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a octa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "Blake3");      Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a octa", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "IronFish");    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @("Nicehash")); Arguments = @(" -a octa", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "kHeavyHash");  Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a octa", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "SHA512256d");  Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a octa", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");               Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA256dt");                 Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a novo") }
    [PSCustomObject]@{ Algorithms = @("SHA3d");                    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a kylacoin") }
    [PSCustomObject]@{ Algorithms = @("Skein2");                   Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @());           Arguments = @(" -a woodcoin") }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }
$Algorithms = $Algorithms | Where-Object { $Config.SSL -ne "Always" -or ($MinerPools[0].($_.Algorithms[0]).SSLSelfSignedCertificate -eq $false -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).SSLSelfSignedCertificate -eq $false)) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).BaseName -notin $_.ExcludePools[0] -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).BaseName -notin $_.ExcludePools[1]) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0]."Ethash".Epoch -gt 0 }

If ($Algorithms) { 

    $Algorithms | Where-Object MinMemGiB | ForEach-Object { 
        $_.MinMemGiB += $MinerPools[0].($_.Algorithms[0]).DAGSizeGiB
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $MinMemGiB = $_.MinMemGiB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Arguments = "$($_.Arguments[0])"
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })$(If ($_.DualMiningIntensity -gt 0) { "-$($_.DualMiningIntensity)" })" -replace ' '

                If ($Algorithm1 -and -not $_.DualMiningIntensity) { 
                    # Allow extra time for auto tuning
                    $_.WarmupTimes[1] = 60
                }

                Switch ($AllMinerPools.($_.Algorithms[0]).Protocol) { 
                    "ethproxy"     { $Arguments += " -p ethproxy"; Break }
                    "ethstratum1"  { $Arguments += " -p ethstratum"; Break }
                    "ethstratum2"  { $Arguments += " -p ethstratum2"; Break }
                    "ethstratumnh" { $Arguments += " -p ethstratum"; Break }
                    Default        { $Arguments += " -p stratum"}
                }
                $Arguments += If ($AllMinerPools.($_.Algorithms[0]).PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                $Arguments += "$($AllMinerPools.($_.Algorithms[0]).Host):$($AllMinerPools.($_.Algorithms[0]).PoolPorts | Select-Object -Last 1)"
                $Arguments += " -w $($AllMinerPools.($_.Algorithms[0]).User)"
                $Arguments += " --pool_password $($AllMinerPools.($_.Algorithms[0]).Pass)"
                $Arguments += " -r $($Config.WorkerName)"

                If ($_.Algorithms[1]) {
                    $Arguments += "$($_.Arguments[1])"
                    Switch ($AllMinerPools.($_.Algorithms[1]).Protocol) { 
                        "ethproxy"     { $Arguments += " --p2 ethproxy"; Break }
                        "ethstratum1"  { $Arguments += " --p2 ethstratum"; Break }
                        "ethstratum2"  { $Arguments += " --p2 ethstratum2"; Break }
                        "ethstratumnh" { $Arguments += " --p2 ethstratum"; Break }
                        Default        { $Arguments += " --p2 stratum" }
                    }
                    $Arguments += If ($AllMinerPools.($_.Algorithms[1]).PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                    $Arguments += "$($AllMinerPools.($_.Algorithms[1]).Host):$($AllMinerPools.($_.Algorithms[1]).PoolPorts | Select-Object -Last 1)"
                    $Arguments += " --w2 $($AllMinerPools.($_.Algorithms[1]).User)"
                    $Arguments += " --pool_password2 $($AllMinerPools.($_.Algorithms[1]).Pass)"
                    $Arguments += " --r2 $($Config.WorkerName)"
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Algorithms       = @($_.Algorithms | Select-Object)
                    API              = "BzMiner"
                    Arguments        = ("$Arguments --nc 1 --no_watchdog --http_enabled 1 --http_port $MinerAPIPort $(If ($Devices | Where-Object { $_.State -ne [DeviceState]::Unsupported } | Where-Object { $_.Type -in @("AMD", "INTEL", "NVIDIA") } | Where-Object { $_ -notin $AvailableMiner_Devices }) { "--disable $((($Devices | Where-Object { $_.State -ne [DeviceState]::Unsupported } | Where-Object { $_.Type -in @("AMD", "INTEL", "NVIDIA") } | Where-Object { $_ -notin $AvailableMiner_Devices }).$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0}:0' -f $_ }) -join ' ')" }) " -replace "\s+", " ").trim()
                    # Arguments        = ("$Arguments --no_watchdog --http_enabled 1 --http_port $MinerAPIPort --enable $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0}:0' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Fee              = @($_.Fee) # Dev fee
                    MinerSet         = $_.MinerSet
                    MinerUri         = "http://127.0.0.1:$($MinerAPIPort)"
                    Name             = $Miner_Name
                    Path             = $Path
                    Port             = $MinerAPIPort
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                    Type             = $_.Type
                    URI              = $Uri
                    WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}