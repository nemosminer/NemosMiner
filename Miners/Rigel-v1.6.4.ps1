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

$Uri = "https://github.com/rigelminer/rigel/releases/download/1.6.4/rigel-1.6.4-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\Rigel.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Fee = @(0.01);         MinMemGiB = 0.77; Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm autolykos2" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "kHeavyHash");   Fee = @(0.01, 0.01);   MinMemGiB = 0.77; Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm autolykos2+kheavyhash" }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "SHA512256d");   Fee = @(0.01, 0.01);   MinMemGiB = 0.77; Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm autolykos2+sha512256d" }
    [PSCustomObject]@{ Algorithms = @("Blake3");                     Fee = @(0.007);        MinMemGiB = 2.0;  Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm alephium" }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                    Fee = @(0.007);        MinMemGiB = 0.77; Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");          Fee = @(0.007, 0.007); MinMemGiB = 0.41; Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash+alephium" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "IronFish");        Fee = @(0.007, 0.007); MinMemGiB = 0.41; Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash+ironfish" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Fee = @(0.007, 0.007); MinMemGiB = 0.41; Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm etchash+kheavyhash" } # https://github.com/rigelminer/rigel/issues/73#issuecomment-1619760643
    [PSCustomObject]@{ Algorithms = @("Ethash");                     Fee = @(0.007);        MinMemGiB = 0.77; Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(55, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");           Fee = @(0.007, 0.007); MinMemGiB = 0.77; Tuning = " --mt2"; Minerset = 2; WarmupTimes = @(55, 25); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash+alephium" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "IronFish");         Fee = @(0.007, 0.007); MinMemGiB = 0.77; Tuning = " --mt2"; Minerset = 2; WarmupTimes = @(55, 25); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash+ironfish" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Fee = @(0.007, 0.007); MinMemGiB = 0.77; Tuning = " --mt2"; Minerset = 2; WarmupTimes = @(55, 25); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ethash+kheavyhash" }
    [PSCustomObject]@{ Algorithms = @("Flora");                      Fee = @(0.007);        MinMemGiB = 0.77; Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm flora" }
    [PSCustomObject]@{ Algorithms = @("IronFish");                   Fee = @(0.007);        MinMemGiB = 2.0;  Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm ironfish" }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Fee = @(0.007);        MinMemGiB = 2.0;  Tuning = " --mt2"; MinerSet = 0; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm kheavyhash" }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                    Fee = @(0.02);         MinMemGiB = 3.0;  Tuning = " --mt2"; Minerset = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm nexapow" }
    [PSCustomObject]@{ Algorithms = @("OctaSpace");                  Fee = @(0.007);        MinMemGiB = 0.77; Tuning = " --mt2"; Minerset = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm octa" }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "Blake3");        Fee = @(0.007, 0.007); MinMemGiB = 0.77; Tuning = " --mt2"; Minerset = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm octa+alephium" }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "IronFish");      Fee = @(0.007, 0.007); MinMemGiB = 0.77; Tuning = " --mt2"; Minerset = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm octa+ironfish" }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "kHeavyHash");    Fee = @(0.007, 0.007); MinMemGiB = 0.77; Tuning = " --mt2"; Minerset = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm octa+kheavyhash" }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");                 Fee = @(0.01);         MinMemGiB = 1.0;  Tuning = " --mt2"; Minerset = 1; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @("Other"); ExcludePools = @(@(), @()); Arguments = " --algorithm sha512256d" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).BaseName -notin $_.ExcludePools[0] -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).BaseName -notin $_.ExcludePools[1]) }

If ($Algorithms) { 

    $Algorithms | ForEach-Object { 
        $_.MinMemGiB += $MinerPools[0].($_.Algorithms[0]).DAGSizeGiB
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | ForEach-Object { 

            # Windows 10 requires more memory on some algos
            # If ($_.Algorithms[0] -match "Cuckaroo.*|Cuckoo.*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $_.MinMemGiB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "cuda", "opencl", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Index = 0
                ForEach ($Algorithm in $_.Algorithms) { 
                    Switch ($AllMinerPools.$Algorithm.Protocol) { 
                        "ethproxy"     { $Arguments += " --url [$($Index + 1)]ethproxy"; Break }
                        "ethstratum1"  { $Arguments += " --url [$($Index + 1)]ethstratum"; Break }
                        "ethstratum2"  { $Arguments += " --url [$($Index + 1)]ethstratum"; Break }
                        "ethstratumnh" { $Arguments += " --url [$($Index + 1)]ethstratum"; Break }
                        Default        { $Arguments += " --url [$($Index + 1)]stratum" }
                    }
                    $Arguments += If ($AllMinerPools.$Algorithm.PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                    $Arguments += "$($AllMinerPools.$Algorithm.Host):$($AllMinerPools.$Algorithm.PoolPorts | Select-Object -Last 1)"
                    $Arguments += " --username [$($Index + 1)]$($AllMinerPools.$Algorithm.User -replace "\.$($Config.Workername)$", '')"
                    $Arguments += " --password [$($Index + 1)]$($AllMinerPools.$Algorithm.Pass)"
                    $Arguments += " --worker [$($Index + 1)]$($Config.WorkerName)"
                    $Index ++
                }
                Remove-Variable Algorithm
                $Arguments += If ($AllMinerPools.($_.Algorithms[0]).PoolPorts[1] -or ($_.Algorithms[1] -and $AllMinerPools.($_.Algorithms[1]).PoolPorts[1])) { " --no-strict-ssl" } # Parameter cannot be used multiple times

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithms | Select-Object)
                    API         = "Rigel"
                    Arguments   = ("$($Arguments) --api-bind 127.0.0.1:$($MinerAPIPort) --no-watchdog --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Fee         = $_.Fee
                    DeviceNames = $AvailableMiner_Devices.Name
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
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