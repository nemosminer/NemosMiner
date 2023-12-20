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
Version:        5.0.2.3
Version date:   2023/12/20
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.0" }))) { Return }

$URI = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
#   [PSCustomObject]@{ Algorithm = "Eaglesong";    MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -algo EAGLESONG" } # ASIC
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGiB = 1.22; Minerset = 0; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -algo ETHASH -intensity 15" }
    [PSCustomObject]@{ Algorithm = "KawPow";       MinMemGiB = 1.22; Minerset = 2; WarmupTimes = @(90, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -algo KAWPOW" }
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";     MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -algo LYRA2V3" } # ASIC
    [PSCustomObject]@{ Algorithm = "MTP";          MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -algo MTP -intensity 21" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";  MinMemGiB = 1.22; Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -coin EPIC" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";  MinMemGiB = 1.22; Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -coin SERO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";  MinMemGiB = 1.22; Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -coin VEIL" }
    [PSCustomObject]@{ Algorithm = "ProgPowZ";     MinMemGiB = 1.22; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -coin ZANO" }
    [PSCustomObject]@{ Algorithm = "UbqHash";      MinMemGiB = 1.22; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -algo UBQHASH -intensity 15" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })
$Algorithms = $Algorithms.Where({ $_.Algorithm -ne "Ethash" -or $MinerPools[0][$_.Algorithm].Epoch -le 384 }) # Miner supports Ethash up to epoch 384
$Algorithms = $Algorithms.Where({ $_.Algorithm -ne "KawPow" -or $MinerPools[0][$_.Algorithm].DAGSizeGiB -lt "4" }) # Miner supports Kawpow up to 4GB

If ($Algorithms) { 

    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
            $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $ExcludePools = $_.ExcludePools
                    ForEach ($Pool in ($MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools -and ($_.Algorithm -notin @("Ethash", "KawPow") -or (<# Miner supports Ethash up to epoch 384 #>$_.Algorithm -eq "Ethash" -and $_.Epoch -le 384) -or (<# Miner supports Kawpow up to 4GB #>$_.Algorithm -eq "KawPow" -and $_.DAGSizeGiB -lt 4)) }))) { 

                        $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                        $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notin $ExcludeGPUArchitecture }) ) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                            $Arguments = $_.Arguments
                            If ($Pool.Currency -in @("CLO", "ETC", "ETH", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZANO", "ZCOIN", "ZELS")) { 
                                $Arguments = " -coin $($Pool.Currency)$($_.Arguments -replace ' -algo \w+')"
                            }
                            If ($AvailableMiner_Devices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace ' -intensity [0-9\.]+' }

                            $Arguments += If ($Pool.Protocol -like "ethproxy*" -or $_.Algorithm -eq "ProgPowZ") { " -pool stratum1+tcp://" } Else { " -pool stratum+tcp://" }
                            $Arguments += "$($Pool.Host):$($Pool.PoolPorts[0]) -user $($Pool.User)"
                            If ($Pool.WorkerName) { $Arguments += " -worker $($Pool.WorkerName)" }
                            $Arguments += " -pass $($Pool.Pass)"

                            [PSCustomObject]@{ 
                                API         = "EthMiner"
                                Arguments   = "$Arguments -PRT 1 -PRS 0 -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
                                DeviceNames = $AvailableMiner_Devices.Name
                                Fee         = @(0) # Dev fee
                                MinerSet    = $_.MinerSet
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