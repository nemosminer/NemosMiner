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
Version date:   2023/10/07
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -gt "5.0" } )) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.0" } { "https://github.com/TrailingStop/TT-Miner-release/releases/download/2023.4.1/TT-Miner-2023.4.1.zip" }
    Default           { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TT-Miner.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Blake3";           Fee = @(0.01); MinMemGiB = 2.00; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Blake3" }
    [PSCustomObject]@{ Algorithm = "EtcHash";          Fee = @(0.01); MinMemGiB = 1.42; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EtcHash" }
    [PSCustomObject]@{ Algorithm = "Ethash";           Fee = @(0.01); MinMemGiB = 1.00; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Ethash" }
    [PSCustomObject]@{ Algorithm = "EthashB3";         Fee = @(0.01); MinMemGiB = 1.00; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EthashB3" }
    [PSCustomObject]@{ Algorithm = "EvrProPow";        Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a EvrProgPow" }
    [PSCustomObject]@{ Algorithm = "FiroPow";          Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(90, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a FiroPow" }
    [PSCustomObject]@{ Algorithm = "FiroPowSCC";       Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(90, 0);   ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c SCC" }
    [PSCustomObject]@{ Algorithm = "Ghostrider";       Fee = @(0.01); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(180, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Ghostrider" }
    [PSCustomObject]@{ Algorithm = "KawPow";           Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(90, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a KawPow" }
    [PSCustomObject]@{ Algorithm = "Mike";             Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(180, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Mike" }
#   [PSCustomObject]@{ Algorithm = "MemeHash";         Fee = @(0.01); MinMemGiB = 1;    MinerSet = 0; WarmupTimes = @(120, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Memehash" } # Not yet working
    [PSCustomObject]@{ Algorithm = "ProgPowEpic";      Fee = @(0.05); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c EPIC" }
    [PSCustomObject]@{ Algorithm = "ProgPowSero";      Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c SERO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeil";      Fee = @(0.01); MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c VEIL" }
    [PSCustomObject]@{ Algorithm = "ProgPowZano";      Fee = @(0.01); MinMemGiB = 1.24; Minerset = 1; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -c ZANO" }
    [PSCustomObject]@{ Algorithm = "ProgPowVeriblock"; Fee = @(0.01); MinMemGiB = 1;    Minerset = 2; WarmupTimes = @(45, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a vProgPow" }
    [PSCustomObject]@{ Algorithm = "SHA256d";          Fee = @(0.01); MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA256D" }
    [PSCustomObject]@{ Algorithm = "SHA256dt";         Fee = @(0.01); MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA256DT" }
    [PSCustomObject]@{ Algorithm = "SHA3D";            Fee = @(0.01); MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a Sha3D" }
    [PSCustomObject]@{ Algorithm = "SHA512256d";       Fee = @(0.01); MinMemGiB = 1;    Minerset = 1; WarmupTimes = @(30, 30);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a SHA512256D" }
    [PSCustomObject]@{ Algorithm = "UbqHash";          Fee = @(0.01); MinMemGiB = 1.24; Minerset = 1; WarmupTimes = @(60, 15);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " -a UbqHash" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].PoolPorts[0] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object { $_.PoolPorts[0] } | Where-Object BaseName -notin $ExcludePools)) { 

                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    $Arguments = $_.Arguments
                    If ($AvailableMiner_Devices | Where-Object MemoryGiB -LE 2) { $Arguments = $Arguments -replace ' -intensity [0-9\.]+' }

                    If ($Pool.Currency -in @("AKA", "ALPH", "ALT", "ARL", "AVS", "BBC", "BCH", "BLACK", "BTC", "BTRM", "BUT", "CLO", "CLORE", "EGEM", "ELH", "EPIC", "ETC", "ETHF", "ETHO", "ETHW", "ETP", "EVOX", "EVR", "EXP", "FIRO", "FITA", "FRENS", "GRAMS", "GSPC", "HVQ", "JGC", "KAW", "LAB", "LTR", "MEWC", "NAPI", "NEOX", "NOVO", "OCTA", "PAPRY", "PRCO", "REDE", "RTM", "RVN", "RXD", "SATO", "SATOX", "SCC", "SERO", "THOON", "TTM", "UBQ", "VBK", "VEIL", "VKAX", "VTE", "XNA", "YERB", "ZANO", "ZELS", "ZIL")) { 
                        $Arguments = " -c $($Pool.Currency)"
                    }
                    $Arguments += " -P $(If ($Pool.Protocol -eq "ethproxy" -or $_.Algorithm -eq "ProgPowZano") { "stratum1" } Else { "stratum" })"
                    $Arguments += If ($Pool.PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                    $Arguments += "$($Pool.User)"
                    If ($Pool.WorkerName) { $Arguments += ".$($Pool.WorkerName)" }
                    $Arguments += ":$($Pool.Pass)"
                    $Arguments += "@$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1)"
                    If (-not $Pool.SendHashrate) { $Arguments += " -no-hashrate" }

                    [PSCustomObject]@{ 
                        # Algorithms  = @($_.Algorithm)
                        API         = "EthMiner"
                        Arguments   = "$Arguments -b 127.0.0.1:$($MinerAPIPort) -d $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
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
    }
}