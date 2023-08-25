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

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -and $_.OpenCL.ComputeCapability -lt "6.0" -and $_.Architecture -ne "Other" })) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "10.0" } { "https://github.com/KlausT/ccminer/releases/download/8.25/ccminer-825-cuda100-x64.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\ccminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "C11";       MinMemGiB = 2; Minerset = 1; WarmupTimes = @(60, 0);  Arguments = " --algo c11 --intensity 22" } # CcminerAlexis78-v1.5.2 is faster
#   [PSCustomObject]@{ Algorithm = "Keccak";    MinMemGiB = 2; Minerset = 3; WarmupTimes = @(30, 0);  Arguments = " --algo keccak --diff-multiplier 2 --intensity 29" } # ASIC
#   [PSCustomObject]@{ Algorithm = "Lyra2RE2";  MinMemGiB = 2; Minerset = 3; WarmupTimes = @(45, 0);  Arguments = " --algo lyra2v2" } # ASIC
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; MinMemGiB = 2; Minerset = 1; WarmupTimes = @(30, 10); Arguments = " --algo neoscrypt --intensity 15.5" } # FPGA
#   [PSCustomObject]@{ Algorithm = "Skein";     MinMemGiB = 2; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo skein" } # ASIC
    [PSCustomObject]@{ Algorithm = "Veltor";    MinMemGiB = 2; Minerset = 2; WarmupTimes = @(60, 15); Arguments = " --algo veltor --intensity 23" }
#   [PSCustomObject]@{ Algorithm = "Whirlpool"; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(60, 15); Arguments = " --algo whirlcoin" } # Cuda error in func 'whirlpool512_cpu_finalhash_64' at line 1795 : invalid argument.
#   [PSCustomObject]@{ Algorithm = "Whirlpool"; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(60, 15); Arguments = " --algo whirlpool" }
    [PSCustomObject]@{ Algorithm = "X11evo";    MinMemGiB = 2; Minerset = 2; WarmupTimes = @(60, 15); Arguments = " --algo x11evo --intensity 21" }
    [PSCustomObject]@{ Algorithm = "X17";       MinMemGiB = 2; Minerset = 2; WarmupTimes = @(60, 0);  Arguments = " --algo x17 --intensity 22" } # CcminerAlexis78-v1.5.2 is faster
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts[0] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGiB -LE 2) { $Arguments = $Arguments -replace " --intensity [0-9\.]+" }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "CcMiner"
                    Arguments   = ("$Arguments --url stratum+tcp://$($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts[0]) --user $($AllMinerPools.($_.Algorithm).User)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" }) --pass $($AllMinerPools.($_.Algorithm).Pass) --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
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