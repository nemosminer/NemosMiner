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

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.OpenCL.ComputeCapability -ge "5.1" }))) { Return }

$URI = "https://github.com/Minerx117/ccmineralexis78/releases/download/v1.5.2/ccmineralexis78.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "C11";       MinMemGiB = 3; Minerset = 1; WarmupTimes = @(60, 0); ExcludePools = @(); Arguments = " --algo c11 --intensity 22" }
#   [PSCustomObject]@{ Algorithm = "Keccak";    MinMemGiB = 3; Minerset = 3; WarmupTimes = @(45, 0); ExcludePools = @(); Arguments = " --algo keccak --diff-multiplier 2 --intensity 29" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2RE2";  MinMemGiB = 3; Minerset = 3; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo lyra2v2" } # ASIC
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; MinMemGiB = 3; MinerSet = 1; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo neoscrypt --intensity 15.5" } # FPGA
#   [PSCustomObject]@{ Algorithm = "Skein";     MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo skein" } # ASIC
    [PSCustomObject]@{ Algorithm = "Skein2";    MinMemGiB = 3; MinerSet = 0; WarmupTimes = @(60, 0); ExcludePools = @(); Arguments = " --algo skein2 --intensity 31.9" }
    [PSCustomObject]@{ Algorithm = "Veltor";    MinMemGiB = 2; Minerset = 2; WarmupTimes = @(40, 0); ExcludePools = @(); Arguments = " --algo veltor --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Whirlcoin"; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo whirlcoin" }
    [PSCustomObject]@{ Algorithm = "Whirlpool"; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(40, 0); ExcludePools = @(); Arguments = " --algo whirlpool" }
    [PSCustomObject]@{ Algorithm = "X11evo";    MinMemGiB = 2; Minerset = 2; WarmupTimes = @(40, 0); ExcludePools = @(); Arguments = " --algo x11evo --intensity 21" }
    [PSCustomObject]@{ Algorithm = "X17";       MinMemGiB = 3; MinerSet = 1; WarmupTimes = @(30, 0); ExcludePools = @(); Arguments = " --algo x17 --intensity 22" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm] })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].Name -notin $_.ExcludePools })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithm].PoolPorts[0] })


If ($Algorithms) { 
    
    ($Devices | Select-Object Model -Unique).ForEach(
        { 
            $Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)
            $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

            $Algorithms.ForEach(
                { 
                    $ExcludePools = $_.ExcludePools
                    ForEach ($Pool in ($MinerPools[0][$_.Algorithm].Where({ $_.PoolPorts[0] -and $_.Name -notin $ExcludePools }))) { 

                        $MinMemGiB = $_.MinMemGiB
                        If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB })) { 

                            $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                            $Arguments = $_.Arguments
                            If ($AvailableMiner_Devices.Where({ $_.MemoryGiB -le 2 })) { $Arguments = $Arguments -replace ' --intensity [0-9\.]+' }

                            [PSCustomObject]@{ 
                                API         = "CcMiner"
                                Arguments   = "$Arguments --url stratum+tcp://$($Pool.Host):$($Pool.PoolPorts[0]) --user $($Pool.User) --pass $($Pool.Pass) --retry-pause 1 --api-bind $MinerAPIPort --cuda-schedule 2 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique).ForEach({ '{0:x}' -f $_ }) -join ',')"
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