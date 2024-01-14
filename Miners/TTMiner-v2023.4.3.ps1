<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
Version:        5.0.2.6
Version date:   2023/12/28
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -gt "5.0" } ))) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.0" } { "https://github.com/TrailingStop/TT-Miner-release/releases/download/2023.4.3/TT-Miner-2023.4.3.zip" }
    Default           { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Blake3";           Fee = @(0.01); MinMemGiB = 2.00; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Blake3" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Fee = @(0.01); MinMemGiB = 1.42; Minerset = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EtcHash" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Fee = @(0.01); MinMemGiB = 1.00; Minerset = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Ethash" }
    [PSCustomObject]@{ Algorithm = "EthashB3";         Fee = @(0.01); MinMemGiB = 1.00; Minerset = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EthashB3" }
    [PSCustomObject]@{ Algorithm = "EvrProPow";        Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EvrProgPow" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a FiroPow" }
    [PSCustomObject]@{ Algorithm = "FiroPowSCC";       Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(30, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c SCC" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";       Fee = @(0.01); MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(180, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Ghostrider" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(60, 60);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a KawPow" }
#   [PSCustomObject]@{ Algorithm = "Mike";             Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(180, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Mike" } # Not working
#   [PSCustomObject]@{ Algorithm = "MemeHash";         Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Memehash" } # Not yet working
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";      Fee = @(0.02); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c EPIC" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c SERO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c VEIL" }
    [PSCustomObject]@{ Algorithm = "ProgPowZ";         Fee = @(0.01); MinMemGiB = 1.24; Minerset = 1; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c ZANO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Fee = @(0.01); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a vProgPow" }
#   [PSCustomObject]@{ Algorithm = "SHA256d";          Fee = @(0.01); MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA256D" } # ASIC
    [PSCustomObject]@{ Algorithm = "SHA256dt";         Fee = @(0.01); MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA256DT" }
    [PSCustomObject]@{ Algorithm = "SHA3D";            Fee = @(0.01); MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Sha3D" }
    [PSCustomObject]@{ Algorithm = "SHA512256d";       Fee = @(0.01); MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA512256D" }
    [PSCustomObject]@{ Algorithm = "SHA3Solidity";     Fee = @(0.01); MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA3SOL" }
    [PSCustomObject]@{ Algorithm = "UbqHash";          Fee = @(0.01); MinMemGiB = 1.24; Minerset = 1; WarmupTimes = @(30, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a UbqHash" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 

            $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
            $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $ExcludePools = $_.ExcludePools
                    ForEach ($Pool in ($MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools }))) { 

                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                            If ($Pool.Currency -in @("AKA", "ALPH", "ALT", "ARL", "AVS", "BBC", "BCH", "BLACK", "BTC", "BTRM", "BUT", "CLO", "CLORE", "EGEM", "ELH", "EPIC", "ETC", "ETI", "ETHF", "ETHO", "ETHW", "ETP", "EVOX", "EVR", "EXP", "FIRO", "FITA", "FRENS", "GRAMS", "GSPC", "HVQ", "JGC", "KAW", "KCN", "LAB", "LTR", "MEWC", "NAPI", "NEOX", "NOVO", "OCTA", "PAPRY", "PRCO", "REDE", "RTH", "RTM", "RVN", "SATO", "SATOX", "SCC", "SERO", "THOON", "TTM", "UBQ", "VBK", "VEIL", "VKAX", "VTE", "XD", "XNA", "YERB", "ZANO", "ZELS", "ZIL")) { 
                                $Arguments = " -c $($Pool.Currency)$($_.Arguments -replace ' -a \w+')"
                            }
                            Else { 
                                $Arguments = $_.Arguments
                            }
                            If ($AvailableMiner_Devices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace ' -intensity [0-9\.]+' }
                            $Arguments += " -P $(If ($Pool.Protocol -eq "ethproxy" -or $_.Algorithm -eq "ProgPowZ") { "stratum1" } Else { "stratum" })"
                            $Arguments += If ($Pool.PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                            $Arguments += "$($Pool.User)"
                            If ($Pool.WorkerName) { $Arguments += ".$($Pool.WorkerName)" }
                            $Arguments += ":$($Pool.Pass)@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                            If (-not $Pool.SendHashrate) { $Arguments += " -no-hashrate" }

                            [PSCustomObject]@{ 
                                # Algorithms  = @($_.Algorithm)
                                API         = "EthMiner"
                                Arguments   = "$Arguments -b 127.0.0.1:$($MinerAPIPort) -d $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMiner_Devices.Name
                                Fee         = $_.Fee # Dev fee
                                MinerSet    = $_.MinerSet
                                MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                                Name        = $Miner_Name
                                Path        = $Path
                                Port        = $MinerAPIPort
                                Type        = "NVIDIA"
                                URI         = $Uri
                                WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                                Workers     = @(@{ Pool = $Pool })
                            }
                        }
                    }
                }
            )
        }
    )
}
