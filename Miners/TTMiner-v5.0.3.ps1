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
Version:        4.3.6.0
Version date:   31 July 2023
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.0.3/ttminer503.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Eaglesong";    MinMemGiB = 2;    Minerset = 3; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo EAGLESONG" } # ASIC
    [PSCustomObject]@{ Algorithm = "Ethash";       MinMemGiB = 0.82; Minerset = 0; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo ETHASH -intensity 15" }
    [PSCustomObject]@{ Algorithm = "KawPow";       MinMemGiB = 0.82; Minerset = 2; WarmupTimes = @(90, 60); ExcludeGPUArchitecture = @(); ExcludePool = @("HashCryptos", "MiningDutch", "ProHashing"); Arguments = " -algo KAWPOW" }
#   [PSCustomObject]@{ Algorithm = "Lyra2RE3";     MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo LYRA2V3" } # ASIC
    [PSCustomObject]@{ Algorithm = "MTP";          MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(30, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo MTP -intensity 21" } # Algorithm is dead
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";  MinMemGiB = 0.82; Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo PROGPOW -coin EPIC" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";  MinMemGiB = 0.82; Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo PROGPOW -coin SERO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";  MinMemGiB = 0.82; Minerset = 2; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo PROGPOW -coin VEIL" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";  MinMemGiB = 0.82; MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo PROGPOWZ -coin ZANO" }
    [PSCustomObject]@{ Algorithm = "UbqHash";      MinMemGiB = 0.82; MinerSet = 0; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludePool = @();                                           Arguments = " -algo UBQHASH -intensity 15" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool }

If ($Algorithms) { 

    $Algorithms |  ForEach-Object { 
        $_.MinMemGiB += $AllMinerPools.($_.Algorithm).DAGSizeGiB
    }

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object { $_.Algorithm -ne "Ethash" -or $AllMinerPools.Ethash.Epoch -le 384 <# Miner supports Ethash up to epoch 384 #> } | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture ) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGiB -le 2) { $Arguments = $Arguments -replace " -intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($AllMinerPools.($_.Algorithm).Currency -in @("CLO", "ETC", "ETH", "ETP", "EXP", "MUSIC", "PIRL", "RVN", "TCR", "UBQ", "VBK", "ZCOIN", "ZELS")) { 
                    $Arguments += " -coin $($AllMinerPools.($_.Algorithm).Currency)"
                }
                $Arguments += If ($AllMinerPools.($_.Algorithm).Protocol -like "ethproxy*" -or $_.Algorithm -eq "ProgPowZano") { " -pool stratum1+tcp://" } Else { " -pool stratum+tcp://" }
                $Arguments += "$($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts[0]) -user $($AllMinerPools.($_.Algorithm).User)"
                If ($AllMinerPools.($_.Algorithm).WorkerName) { $Arguments += " -worker $($AllMinerPools.($_.Algorithm).WorkerName)" }
                $Arguments += " -pass $($AllMinerPools.($_.Algorithm).Pass)"

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Arguments   = ("$($Arguments) -PRT 1 -PRS 0 -api-bind 127.0.0.1:$($MinerAPIPort) -device $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = 0
                    MinerSet    = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = "NVIDIA"
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}