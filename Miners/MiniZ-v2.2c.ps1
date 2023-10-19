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
Version:        5.0.1.4
Version date:   2023/10/19
#>

using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or $_.OpenCL.ComputeCapability -ge "5.0" } )) { Return }

$URI = "https://github.com/Minerx117/miners/releases/download/MiniZ/miniZ_v2.2c_win-x64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miniZ.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "BeamV3";           Type = "AMD"; Fee = @(0.02);   MinMemGiB = 4.0;  Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "GCN4", "RDNA1");          ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=beam3 --pers=Beam-Pow" } # Lots of bad shares
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 3.0;  Minerset = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                                          ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=125,4 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                                          ExcludePools = @(); AutoCoinPers = " --par=144,5"; Arguments = " --amd" } # FPGA
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 4.0;  MinerSet = 0; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                                          ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=150,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.3;  MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "GCN4", "RDNA1", "RDNA2"); ExcludePools = @(); AutoCoinPers = " --par=192,7"; Arguments = " --amd" } #FPGA
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("RDNA1");                                          ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=210,9 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash965";      Type = "AMD"; Fee = @(0.02);   MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=96,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=etcHash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=ethash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "EthashB3";         Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=ethashb3 --dag-fix" }
    [PSCustomObject]@{ Algorithm = "EvrProgPow";       Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --pers=EVRMORE-PROGPOW --dag-fix" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "AMD"; Fee = @(0.0075); MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --pers=firo" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "kHeavyHash";       Type = "AMD"; Fee = @(0.008);  MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=kaspa" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = 8.0;  Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "AMD"; Fee = @(0.01);   MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=VeriBlock" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Type = "AMD"; Fee = @(0.01);   MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @("GCN1", "GCN2", "GCN3", "RDNA1");                  ExcludePools = @(); AutoCoinPers = "";             Arguments = " --amd --par=progpow --pers=zano" }

    [PSCustomObject]@{ Algorithm = "BeamV3";           Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 4.0;  Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=beam3 --pers=Beam-Pow" } # Lots of bad shares
    [PSCustomObject]@{ Algorithm = "Equihash1254";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 3.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=125,4 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = " --par=144,5"; Arguments = " --nvidia" } # FPGA
    [PSCustomObject]@{ Algorithm = "Equihash1505";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 4.0;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=150,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.3;  MinerSet = 0; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = " --par=192,7"; Arguments = " --nvidia" } # FPGA
    [PSCustomObject]@{ Algorithm = "Equihash2109";     Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;  Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=210,9 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "Equihash965";      Type = "NVIDIA"; Fee = @(0.02);   MinMemGiB = 2.0;  Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=96,5 --smart-pers" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 1.08; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=etcHash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 1.08; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=ethash --dag-fix" }
    [PSCustomObject]@{ Algorithm = "EthashB3";         Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=ethashb3 --dag-fix" }
    [PSCustomObject]@{ Algorithm = "EvrProgPow";       Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --pers=EVRMORE-PROGPOW --dag-fix" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Type = "NVIDIA"; Fee = @(0.0075); MinMemGiB = 1.08; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --pers=firo" }
    [PSCustomObject]@{ Algorithm = "kHeavyHash";       Type = "NVIDIA"; Fee = @(0.008);  MinMemGiB = 1.08; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=kaspa" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 35); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --par=kawpow --dag-fix --pers=RAVENCOINKAWPOW" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 1.08; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --pers=sero" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 8.0;  Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --pers=veil" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 2.0;  Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(30, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --pers=VeriBlock" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Type = "NVIDIA"; Fee = @(0.01);   MinMemGiB = 0.80; Minerset = 2; Tuning = " --ocX"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();        ExcludePools = @(); AutoCoinPers = "";             Arguments = " --nvidia --pers=zano" }
)       

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }

If ($Algorithms) { 

    $Algorithms | ForEach-Object { 
        $_.MinMemGiB += $Pool.DAGSizeGiB
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object BaseName -notin $ExcludePools)) { 

                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    $Arguments = $_.Arguments
                    $Arguments += " --url=$(If ($Pool.PoolPorts[1]) { "ssl://" } )$($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" })@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                    $Arguments += " --pass=$($Pool.Pass)"
                    If ($Pool.WorkerName) { $Arguments += " --worker=$($Pool.WorkerName)" }
                    If ($_.AutoCoinPers) {$Arguments += $(Get-EquihashCoinPers -Command " --pers " -Currency $Pool.Currency -DefaultCommand $_.AutoCoinPers) }

                    # Apply tuning parameters
                    If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                    [PSCustomObject]@{ 
                        API          = "MiniZ"
                        Arguments    = "$Arguments --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int=10 --nohttpheaders --latency --all-shares --extra --tempunits=C --show-pers --fee-time=60 --telemetry $MinerAPIPort -cd $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d2}' -f $_ }) -join ' ')"
                        DeviceNames  = $AvailableMiner_Devices.Name
                        Fee          = $_.Fee # Dev fee
                        MinerSet     = $_.MinerSet
                        MinerUri     = "http://127.0.0.1:$($MinerAPIPort)"
                        Name         = $Miner_Name
                        Path         = $Path
                        Port         = $MinerAPIPort
                        Type         = $_.Type
                        URI          = $Uri
                        WarmupTimes  = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                        Workers     = @(@{ Pool = $Pool })
                    }
                }
            }
        }
    }
}