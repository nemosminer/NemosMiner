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
Version:        5.0.2.0
Version date:   2023/11/12
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 2.0" })) { Return }

$URI = "https://github.com/Minerx117/miners/releases/download/TeamRedMiner/teamredminer-v0.10.14-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$($Name)\teamredminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Fee = @(0.025);        MinMemGiB = 0.77; Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2");                            Arguments = " --algo=autolykos2" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "kHeavyHash");   Fee = @(0.025, 0.025); MinMemGiB = 0.77; Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2");                            Arguments = " --algo=autolykos2" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "IronFish");     Fee = @(0.025, 0.025); MinMemGiB = 0.77; Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2");                            Arguments = " --algo=autolykos2" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    [PSCustomObject]@{ Algorithms = @("Chukwa");                     Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=trtl_chukwa" }
    [PSCustomObject]@{ Algorithms = @("Chukwa2");                    Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=trtl_chukwa2" }
    [PSCustomObject]@{ Algorithms = @("CryptonightCcx");             Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_conceal --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # SRBMinerMulti-v2.3.9 is fastest
    [PSCustomObject]@{ Algorithms = @("CryptonightHeavy");           Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_heavy --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightHaven");           Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_haven --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightHeavyTube");       Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cn_saber --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
#   [PSCustomObject]@{ Algorithms = @("CryptonightR");               Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 3; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnr --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # ASIC
    [PSCustomObject]@{ Algorithms = @("CryptonightV1");              Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightDouble");          Fee = @(0.025);        MinMemGiB = 4.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_dbl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" } # XmRig-v6.20.0 is fastest
    [PSCustomObject]@{ Algorithms = @("CryptonightHalf");            Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_half --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightTurtle");          Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_trtl --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightRwz");             Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_rwz --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CryptonightUpx");             Fee = @(0.025);        MinMemGiB = 3.0;  Minerset = 1; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cnv8_upx2 --auto_tune=QUICK --auto_tune_runs=2 --allow_large_alloc --no_lean" }
    [PSCustomObject]@{ Algorithms = @("CuckarooD29");                Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cuckarood29_grin" } # 2GB is not enough
#   [PSCustomObject]@{ Algorithms = @("Cuckatoo31");                 Fee = @(0.025);        MinMemGiB = 3.0;  Minerset = 3; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=cuckatoo31_grin" } # ASIC
    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Fee = @(0.01);         MinMemGiB = 0.77; Minerset = 1; WarmupTimes = @(45, 60);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2");                            Arguments = " --algo=etchash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithms = @("Ethash");                     Fee = @(0.01);         MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2");                            Arguments = " --algo=ethash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Fee = @(0.01, 0.01);   MinMemGiB = 0.77; Minerset = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2");                            Arguments = " --algo=ethash" } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithms = @("Ethash", "IronFish");         Fee = @(0.01, 0.01);   MinMemGiB = 0.77; Minerset = 2; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2");                            Arguments = " --algo=ethash" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    [PSCustomObject]@{ Algorithms = @("FiroPow");                    Fee = @(0.02);         MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA3");                   Arguments = " --algo=firopow" } # Wildrig-v0.38.3 is fastest on Polaris
    [PSCustomObject]@{ Algorithms = @("IronFish");                   Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2");                            Arguments = " --algo=ironfish" } # Pools with support at this time are Herominers, Flexpool and Kryptex
    [PSCustomObject]@{ Algorithms = @("KawPow");                     Fee = @(0.02);         MinMemGiB = 0.77; MinerSet = 0; WarmupTimes = @(60, 60);  ExcludePools = @(@("MiningPoolHub"), @()); ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA3");                   Arguments = " --algo=kawpow" } # Wildrig-v0.38.3 is fastest on Polaris
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Fee = @(0.01);         MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2");                            Arguments = " --algo=kas" }
#   [PSCustomObject]@{ Algorithms = @("Lyra2Z");                     Fee = @(0.03);         MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=lyra2z" } # ASIC
#   [PSCustomObject]@{ Algorithms = @("Lyra2RE3");                   Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=lyra2rev3" } # ASIC
    [PSCustomObject]@{ Algorithms = @("MTP");                        Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(45, 45);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA3");                   Arguments = " --algo=mtp" } # Algorithm is dead
    [PSCustomObject]@{ Algorithms = @("Nimiq");                      Fee = @(0.025);        MinMemGiB = 4.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA3");                   Arguments = " --algo=nimiq" }
    [PSCustomObject]@{ Algorithms = @("Phi2");                       Fee = @(0.03);         MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=phi2" }
    [PSCustomObject]@{ Algorithms = @("VertHash");                   Fee = @(0.025);        MinMemGiB = 4.0;  Minerset = 1; WarmupTimes = @(75, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA3");                   Arguments = " --algo=verthash --verthash_file=..\.$($Variables.VerthashDatPath)" }
#   [PSCustomObject]@{ Algorithms = @("X16r");                       Fee = @(0.025);        MinMemGiB = 4.0;  Minerset = 3; WarmupTimes = @(60, 60);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16r" } # ASIC
    [PSCustomObject]@{ Algorithms = @("X16rv2");                     Fee = @(0.025);        MinMemGiB = 4.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16rv2" }
    [PSCustomObject]@{ Algorithms = @("X16s");                       Fee = @(0.025);        MinMemGiB = 2.0;  Minerset = 2; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16s" }
    [PSCustomObject]@{ Algorithms = @("X16rt");                      Fee = @(0.025);        MinMemGiB = 2.0;  MinerSet = 0; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @());                ExcludeGPUArchitecture = @("GCN1", "GCN2", "RDNA1", "RDNA2", "RDNA3"); Arguments = " --algo=x16rt" } # FPGA
) 

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms | Where-Object { -not $_.Algorithms[1] } | ForEach-Object { $_.Algorithms += "" }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]] } | Where-Object { $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] }
$Algorithms = $Algorithms | Where-Object { $Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLSelfSignedCertificate -eq $false -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLSelfSignedCertificate -ne $true)) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]].Name -notin $_.ExcludePools[0] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[1][$_.Algorithms[1]].Name -notin $_.ExcludePools[1] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

        $Algorithms | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool0 in ($MinerPools[0][$_.Algorithms[0]] | Where-Object Name -notin $ExcludePools[0] | Where-Object { $Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true })) { 
                ForEach ($Pool1 in ($MinerPools[1][$_.Algorithms[1]] | Where-Object Name -notin $ExcludePools[1] | Where-Object { $Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true })) { 

                    # Temp fix: SSL is broken @ ZergPool
                    If ($Pool0.BaseName -eq "ZergPool") { 
                        $Pool0.PoolPorts[1] = $null
                    }
                    If ($Pool1.BaseName -eq "ZergPool") { 
                        $Pool1.PoolPorts[1] = $null
                    }
                    If (($Pool0.BaseName -ne "ZergPool" -or $Pool0.PoolPorts[0]) -or ($Pool1.BaseName -ne "ZergPool" -or $Pool1.PoolPorts[0])) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                        If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                            $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })"

                            $Arguments = $_.Arguments
                            $Arguments += " --pool_force_ensub --url=$(If ($Pool0.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                            $Arguments += Switch ($Pool0.Protocol) { 
                                "ethstratumnh" { " --eth_stratum_mode=nicehash" }
                            }
                            $Arguments += " --user=$($Pool0.User)$(If ($Pool0.WorkerName -and $Pool0.User -notlike "*.$($Pool0.WorkerName)*") { ".$($Pool0.WorkerName)" })"
                            $Arguments += " --pass=$($Pool0.Pass)"

                            If ($_.Algorithms[1] -eq "IronFish") { $Arguments += " --iron" }
                            If ($_.Algorithms[1] -eq "kHeavyHash") { $Arguments += " --kas" }
                            If ($_.Algorithms[1]) { 
                                $Arguments += " --url=$(If ($Pool1.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                                $Arguments += " --user=$($Pool1.User)$(If ($Pool1.WorkerName -and $Pool1.User -notlike "*.$($Pool1.WorkerName)*") { ".$($Pool1.WorkerName)" })"
                                $Arguments += " --pass=$($Pool1.Pass)"
                            }
                            If ($_.Algorithms[1] -eq "IronFish") { $Arguments += " --iron_end" }
                            If ($_.Algorithms[1] -eq "kHeavyHash") { $Arguments += " --kas_end" }

                            If ($_.Algorithms[0] -match '^Et(c)hash.+' -and $AvailableMiner_Devices.Model -notmatch "^Radeon RX [0-9]{3} ") { $_.Fee = @(0.0075) } # Polaris cards 0.75%

                            If ($_.Algorithms -contains "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                                $PrerequisitePath = $Variables.VerthashDatPath
                                $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                            }
                            Else { 
                                $PrerequisitePath = ""
                                $PrerequisiteURI = ""
                            }

                            [PSCustomObject]@{ 
                                API              = "Xgminer"
                                Arguments        = "$Arguments --watchdog_script --no_gpu_monitor --init_style=3 --hardware=gpu --platform=$($AvailableMiner_Devices.PlatformId | Sort-Object -Unique) --api_listen=127.0.0.1:$MinerAPIPort --devices=$(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:d}' -f $_ }) -join ',')"
                                DeviceNames      = $AvailableMiner_Devices.Name
                                Fee              = $_.Fee # Dev fee
                                MinerSet         = $_.MinerSet
                                Name             = $Miner_Name
                                Path             = $Path
                                Port             = $MinerAPIPort
                                PrerequisitePath = $PrerequisitePath
                                PrerequisiteURI  = $PrerequisiteURI
                                Type             = "AMD"
                                URI              = $Uri
                                WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers          = @($Pool0, $Pool1 | Where-Object { $_ } | ForEach-Object { @{ Pool = $_ } })
                            }
                        }
                    }
                }
            }
        }
    }
}