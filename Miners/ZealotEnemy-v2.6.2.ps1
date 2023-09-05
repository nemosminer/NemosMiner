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
Version:        5.0.0.0
Version date:   2023/09/05
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.OpenCL.ComputeCapability -gt "5.0" })) { Return }

$URI = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.1" } { Return } # Use 2.6.3
    { $_ -ge "10.1" } { "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda10.1.zip"; Break }
    { $_ -ge "10.0" } { "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda10.0.zip"; Break }
    { $_ -ge "9.2" }  { "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda9.2.zip"; Break }
    { $_ -ge "9.1" }  { "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda9.1.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\z-enemy.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Aergo";      MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo aergo --intensity 23 --statsavg 5" }
#   [PSCustomObject]@{ Algorithm = "BCD";        MinMemGiB = 3;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo bcd --statsavg 5" } # ASIC
    [PSCustomObject]@{ Algorithm = "Bitcore";    MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(90, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo bitcore --intensity 22 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "C11";        MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(60, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo c11 --intensity 24 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Hex";        MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo hex --intensity 24 --statsavg 5" }
#   [PSCustomObject]@{ Algorithm = "KawPow";     MinMemGiB = 0.77; Minerset = 2; WarmupTimes = @(60, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo kawpow --statsavg 1 --diff-factor 5" } # No hashrate in time
#   [PSCustomObject]@{ Algorithm = "Phi";        MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo phi --statsavg 5" } # ASIC
    [PSCustomObject]@{ Algorithm = "Phi2";       MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(60, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo phi2 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "Polytimos";  MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo poly --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";  MinMemGiB = 3;    Minerset = 3; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo skunk --statsavg 1" } # No hashrate in time for old cards
#   [PSCustomObject]@{ Algorithm = "Sonoa";      MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(90, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo sonoa --statsavg 1" } # No hashrate in time
    [PSCustomObject]@{ Algorithm = "Timetravel"; MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo timetravel --statsavg 5" }
#   [PSCustomObject]@{ Algorithm = "Tribus";     MinMemGiB = 3;    MinerSet = 0; WarmupTimes = @(90, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo tribus --statsavg 1" } # ASIC
#   [PSCustomObject]@{ Algorithm = "X16r";       MinMemGiB = 3;    Minerset = 3; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo x16r --statsavg 1" } # ASIC
    [PSCustomObject]@{ Algorithm = "X16rv2";     MinMemGiB = 3;    MinerSet = 0; WarmupTimes = @(60, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo x16rv2 --statsavg 5" }
    [PSCustomObject]@{ Algorithm = "X16s";       MinMemGiB = 3;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo x16s --statsavg 5" } # FPGA
    [PSCustomObject]@{ Algorithm = "X17";        MinMemGiB = 2;    MinerSet = 0; WarmupTimes = @(120, 0); ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo x17 --statsavg 1" }
#   [PSCustomObject]@{ Algorithm = "Xevan";      MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(90, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(); Arguments = " --algo xevan --intensity 26 --diff-factor 1 --statsavg 1" } # No hashrate in time
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object BaseName -notin $ExcludePools)) { 

                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    $Arguments = $_.Arguments
                    If ($AvailableMiner_Devices | Where-Object MemoryGiB -LE 2) { $Arguments = $Arguments -replace ' --intensity [0-9\.]+' }

                    [PSCustomObject]@{ 
                        API         = "Trex"
                        Arguments   = "$Arguments $(If ($Pool.PoolPorts[1]) { "--no-cert-verify --url stratum+ssl" } Else { "--url stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" }) --pass $($Pool.Pass) --api-bind 0 --api-bind-http $MinerAPIPort --retry-pause 1 --quiet --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
                        DeviceNames = $AvailableMiner_Devices.Name
                        Fee         = 0.01 # dev fee
                        MinerSet    = $_.MinerSet
                        MinerUri    = "" # "http://127.0.0.1:$($MinerAPIPort)" # Always offline
                        Name        = $Miner_Name
                        Path        = $Path
                        Port        = $MinerAPIPort
                        Type        = "NVIDIA"
                        URI         = $Uri
                        WarmupTimes = @($_.WarmupTimes) # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                        Workers     = @(@{ Pool = $Pool })
                    }
                }
            }
        }
    }
}