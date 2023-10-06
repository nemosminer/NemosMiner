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
Version:        5.0.1.1
Version date:   2023/10/06
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$URI = "https://github.com/trexminer/T-Rex/releases/download/0.26.8/t-rex-0.26.8-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\t-rex.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");           Fee = @(0.02);       MinMemGiB = 1.08; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(45, 0);   ExcludePools = @(@(), @()); Arguments = " --algo autolykos2 --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("Blake3");               Fee = @(0.01);       MinMemGiB = 2;    Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(45, 0);   ExcludePools = @(@(), @()); Arguments = " --algo blake3 --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");              Fee = @(0.01);       MinMemGiB = 1.08; Minerset = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 5);   ExcludePools = @(@(), @()); Arguments = " --algo etchash --intensity 25" } # GMiner-v3.41 is fastest
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");    Fee = @(0.01, 0.01); MinMemGiB = 1.08; Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo etchash --dual-algo blake3 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash");               Fee = @(0.01);       MinMemGiB = 1.08; Minerset = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo ethash --intensity 25" } # GMiner-v3.41 is fastest
    [PSCustomObject]@{ Algorithms = @("Ethash", "Autolykos2"); Fee = @(0.01, 0.02); MinMemGiB = 8;    Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo autolykos2 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");     Fee = @(0.01, 0.01); MinMemGiB = 1.08; Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo blake3 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "FiroPow");    Fee = @(0.01, 0.01); MinMemGiB = 10;   Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(255, 15); ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo firopow --lhr-tune -1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");     Fee = @(0.01, 0.01); MinMemGiB = 10;   Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(255, 15); ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo kawpow --lhr-tune -1" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Octopus");    Fee = @(0.01, 0.02); MinMemGiB = 8;    Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo ethash --dual-algo octopus --lhr-tune -1" }
    [PSCustomObject]@{ Algorithms = @("FiroPow");              Fee = @(0.01);       MinMemGiB = 1.08; Minerset = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 30);  ExcludePools = @(@(), @()); Arguments = " --algo firopow --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("KawPow");               Fee = @(0.01);       MinMemGiB = 1.08; Minerset = 1; Tuning = " --mt 3"; WarmupTimes = @(45, 20);  ExcludePools = @(@(), @()); Arguments = " --algo kawpow --intensity 25" } # XmRig-v6.20.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithms = @("MTP");                  Fee = @(0.01);       MinMemGiB = 3;    Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo mtp --intensity 21" } # Algorithm is dead
    [PSCustomObject]@{ Algorithms = @("MTPTcr");               Fee = @(0.01);       MinMemGiB = 3;    Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo mtp-tcr --intensity 21" }
    [PSCustomObject]@{ Algorithms = @("Multi");                Fee = @(0.01);       MinMemGiB = 2;    Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = " --algo multi --intensity 25" }
    [PSCustomObject]@{ Algorithms = @("Octopus");              Fee = @(0.02);       MinMemGiB = 1.08; Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  ExcludePools = @(@(), @()); Arguments = " --algo octopus" } # 6GB is not enough
    [PSCustomObject]@{ Algorithms = @("ProgPowSero");          Fee = @(0.01);       MinMemGiB = 1.08; Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo progpow --coin sero" }
    [PSCustomObject]@{ Algorithms = @("ProgPowVeil");          Fee = @(0.01);       MinMemGiB = 1.08; Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo progpow-veil --intensity 24" }
    [PSCustomObject]@{ Algorithms = @("ProgPowVeriblock");     Fee = @(0.01);       MinMemGiB = 2;    Minerset = 2; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo progpow-veriblock" }
    [PSCustomObject]@{ Algorithms = @("ProgPowZano");          Fee = @(0.01);       MinMemGiB = 1.08; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  ExcludePools = @(@(), @()); Arguments = " --algo progpowz --intensity 25" }
#   [PSCustomObject]@{ Algorithms = @("Tensority");            Fee = @(0.01);       MinMemGiB = 2;    Minerset = 3; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   ExcludePools = @(@(), @()); Arguments = " --algo tensority --intensity 25" } # ASIC
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms | Where-Object { -not $_.Algorithms[1] } | ForEach-Object { $_.Algorithms += "" }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]] } | Where-Object { $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] }
$Algorithms = $Algorithms | Where-Object { $Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLSelfSignedCertificate -eq $false -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLSelfSignedCertificate -ne $true)) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]].BaseName -notin $_.ExcludePools[0] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[1][$_.Algorithms[1]].BaseName -notin $_.ExcludePools[1] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool0 in ($MinerPools[0][$_.Algorithms[0]] | Where-Object BaseName -notin $ExcludePools[0] | Where-Object { $Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true })) { 
                ForEach ($Pool1 in ($MinerPools[1][$_.Algorithms[1]] | Where-Object BaseName -notin $ExcludePools[1] | Where-Object { $Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true })) { 

                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB

                    If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $MinMemGiB) { 

                        $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })"

                        If ($AvailableMiner_Devices | Where-Object MemoryGiB -LE 2) { $Arguments = $Arguments -replace ' --intensity [0-9\.]+' }

                        $Arguments = $_.Arguments
                        $Arguments += Switch ($Pool0.Protocol) { 
                            "ethstratum1"  { " --url stratum2" }
                            "ethstratum2"  { " --url stratum2" }
                            "ethstratumnh" { " --url stratum2" }
                            Default        { " --url stratum" }
                        }
                        $Arguments += If ($Pool0.PoolPorts[1]) { "+ssl" } Else { "+tcp" }
                        $Arguments += "://$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                        $Arguments += " --user $($Pool0.User)"
                        $Arguments += " --pass $($Pool0.Pass)"
                        If ($Pool0.WorkerName) { $Arguments += " --worker $($Pool0.WorkerName)" }

                        If ($Pool0.Currency -in @("CLO", "ETC", "ETH", "ETHW", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZCOIN", "ZELS")) { 
                            $Arguments += " --coin $($Pool0.Currency)"
                        }

                        If ($Algorithm1) { 
                            $Arguments += Switch ($Pool1.Protocol) { 
                                "ethstratum1"  { " --url2 stratum2" }
                                "ethstratum2"  { " --url2 stratum2" }
                                "ethstratumnh" { " --url2 stratum2" }
                                Default        { " --url2 stratum" }
                            }
                            $Arguments += If ($Pool1.PoolPorts[1]) { "+ssl" } Else { "+tcp" }
                            $Arguments += "://$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                            $Arguments += " --user2 $($Pool1.User)"
                            $Arguments += " --pass2 $($Pool1.Pass)"
                            If ($Pool1.WorkerName) { $Arguments += " --worker2 $($Pool1.WorkerName)" }
                        }

                        # Apply tuning parameters
                        If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                        If ($Arguments -notmatch "--kernel [0-9]") { $_.WarmupTimes[0] += 15 } # Allow extra seconds for kernel auto tuning

                        [PSCustomObject]@{ 
                            API         = "Trex"
                            Arguments   = "$Arguments --no-strict-ssl --no-watchdog --gpu-report-interval 5 --quiet --retry-pause 1 --timeout 50000 --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-read-only --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
                            DeviceNames = $AvailableMiner_Devices.Name
                            Fee         = $_.Fee # Dev fee
                            MinerSet    = $_.MinerSet
                            MinerUri    = "http://127.0.0.1:$($MinerAPIPort)/trex"
                            Name        = $Miner_Name
                            Path        = $Path
                            Port        = $MinerAPIPort
                            Type        = "NVIDIA"
                            URI         = $Uri
                            WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                            Workers          = @($Pool0, $Pool1 | Where-Object { $_ } | ForEach-Object { @{ Pool = $_ } })
                        }
                    }
                }
            }
        }
    }
}