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
Version:        5.0.1.8
Version date:   2023/11/03
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAVersion -ge "11.6") })) { Return }

$URI = "https://github.com/sp-hash/TeamBlackMiner/releases/download/v2.07/TeamBlackMiner_2_07_cuda_12_2.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$($Name)\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; INTEL = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = @{ AMD = "Type_Vendor_Id"; INTEL = "Type_Vendor_Index"; NVIDIA = "Type_Vendor_Index" } # Device numeration seems to be mixed up with OpenCL

$Algorithms = @(
    [PSCustomObject]@{ Algorithms = @("EtcHash");             Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());                                                                        Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "KawPow");   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.24; Minerset = 2; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @("RDNA1"); ExcludePools = @(@(), @());                                                                        Arguments = " --algo etc+rvn" } # https://github.com/sp-hash/TeamBlackMiner/issues/403
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash"); Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 1; Tuning = ""; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());                                                                        Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" } # https://github.com/sp-hash/TeamBlackMiner/issues/402
    [PSCustomObject]@{ Algorithms = @("Ethash");              Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());                                                                        Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");    Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.24; Minerset = 2; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @("RDNA1"); ExcludePools = @(@(), @());                                                                        Arguments = " --algo eth+rvn" } # https://github.com/sp-hash/TeamBlackMiner/issues/403
#   [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 1; Tuning = ""; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());                                                                        Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" } # https://github.com/sp-hash/TeamBlackMiner/issues/402
    [PSCustomObject]@{ Algorithms = @("KawPow");              Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 2; Tuning = ""; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();        ExcludePools = @(@("HashCryptos", "MiningDutch", "MiningPoolHub", "NiceHash", "ProHashing"), @()); Arguments = " --algo kawpow" } # https://github.com/sp-hash/TeamBlackMiner/issues/405
#   [PSCustomObject]@{ Algorithms = @("VertHash");            Type = "AMD"; Fee = @(0.005);        MinMemGiB = 3.0;  Minerset = 1; Tuning = ""; WarmupTimes = @(60, 0);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @());                                                                        Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" } # https://github.com/sp-hash/TeamBlackMiner/issues/402

    [PSCustomObject]@{ Algorithms = @("EtcHash");             Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();         ExcludePools = @(@(), @());                                                                        Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Ethash3B"); Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.24; Minerset = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();         ExcludePools = @(@(), @());                                                                        Arguments = " --algo etc+ethb3" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "KawPow");   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.24; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @("Turing"); ExcludePools = @(@(), @("HashCryptos", "MiningDutch", "MiningPoolHub", "NiceHash", "ProHashing")); Arguments = " --algo etc+rvn" } # https://github.com/sp-hash/TeamBlackMiner/issues/396 & https://github.com/sp-hash/TeamBlackMiner/issues/405
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash"); Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();         ExcludePools = @(@(), @());                                                                        Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" } # https://github.com/sp-hash/TeamBlackMiner/issues/402
    [PSCustomObject]@{ Algorithms = @("Ethash");              Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();         ExcludePools = @(@(), @());                                                                        Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "Ethash3B");  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.24; Minerset = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();         ExcludePools = @(@(), @());                                                                        Arguments = " --algo eth+ethb3" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");    Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.24; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @("Turing"); ExcludePools = @(@(), @("HashCryptos", "MiningDutch", "MiningPoolHub", "NiceHash", "ProHashing")); Arguments = " --algo eth+rvn" } # https://github.com/sp-hash/TeamBlackMiner/issues/400 & https://github.com/sp-hash/TeamBlackMiner/issues/405
#   [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();         ExcludePools = @(@(), @());                                                                        Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" } # https://github.com/sp-hash/TeamBlackMiner/issues/402
    [PSCustomObject]@{ Algorithms = @("Ethash3B");            Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @();         ExcludePools = @(@(), @());                                                                        Arguments = " --algo ethash3b" }
    [PSCustomObject]@{ Algorithms = @("KawPow");              Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @("Turing"); ExcludePools = @(@("HashCryptos", "MiningDutch", "MiningPoolHub", "NiceHash", "ProHashing"), @()); Arguments = " --algo kawpow" } # https://github.com/sp-hash/TeamBlackMiner/issues/400 & https://github.com/sp-hash/TeamBlackMiner/issues/405
#   [PSCustomObject]@{ Algorithms = @("VertHash");            Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 3.0;  MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();         ExcludePools = @(@(), @());                                                                        Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" } # https://github.com/sp-hash/TeamBlackMiner/issues/402
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms | Where-Object { -not $_.Algorithms[1] } | ForEach-Object { $_.Algorithms += "" }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]] } | Where-Object { $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]].BaseName -notin $_.ExcludePools[0] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[1][$_.Algorithms[1]].BaseName -notin $_.ExcludePools[1] }

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool0 in ($MinerPools[0][$_.Algorithms[0]] | Where-Object BaseName -notin $ExcludePools[0])) { 
                ForEach ($Pool1 in ($MinerPools[1][$_.Algorithms[1]] | Where-Object BaseName -notin $ExcludePools[1])) { 

                    # Dual algorithm mining: Both pools must support same protocol (SSL or non-SSL) :-(
                    If (-not $_.Algorithms[1] -or ($Pool0.PoolPorts[0] -and $Pool1.PoolPorts[0]) -or ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1])) { 

                        $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                        If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                            $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })"

                            $Arguments = $_.Arguments
                            $Arguments += " --hostname $($Pool0.Host)"
                            $Arguments += " --wallet $($Pool0.User)"
                            $Arguments += If (($Pool0.PoolPorts[1] -and -not $_.Algorithms[1]) -or ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1])) { " --ssl --ssl-verify-none --ssl-port $($Pool0.PoolPorts[1])" } Else { " --port $($Pool0.PoolPorts[0])"}
                            # Temp fix for https://github.com/sp-hash/TeamBlackMiner/issues/404
                            # If ($Pool0.Pass) { $Arguments += " --server-passwd $($Pool0.Pass)" }
                            If ($Pool0.Pass) { $Arguments += " --server-passwd $(If ($_.Algorithms[0] -match $Variables.RegexAlgoHasDAG) { $Pool0.Pass -replace ',mc=\w+' } Else { $Pool0.Pass })" }
                            If ($Pool0.Pass) { $Arguments += " --server-passwd $(If ($_.Algorithms[0] -match $Variables.RegexAlgoHasDAG) { $Pool0.Pass -replace ',mc=\w+' } Else { $Pool0.Pass })" }

                            $SecondAlgo = Switch ($_.Algorithms[1]) { 
                                "Ethash3B" { "ethb3" }
                                "KawPow"   { "rvn" }
                                "VertHash" { "vtc" }
                                Default    { "" }
                            }
                            If ($SecondAlgo) { 
                                # Temp fix for https://github.com/sp-hash/TeamBlackMiner/issues/404
                                # $Arguments += " --$($SecondAlgo)-hostname $($Pool1.Host) --$($SecondAlgo)-wallet $($Pool1.User) --$($SecondAlgo)-passwd $($Pool1.Pass)"
                                $Arguments += " --$($SecondAlgo)-hostname $($Pool1.Host) --$($SecondAlgo)-wallet $($Pool1.User) --$($SecondAlgo)-passwd $(If ($_.Algorithms[1] -match $Variables.RegexAlgoHasDAG) { $Pool1.Pass -replace ',mc=\w+' } Else { $Pool1.Pass })"
                                $Arguments += If ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1]) { " --$($SecondAlgo)-port $($Pool1.PoolPorts[1])" } Else { " --$($SecondAlgo)-port $($Pool1.PoolPorts[0])" }
                            }

                            # Apply tuning parameters
                            If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                            If ($_.Algorithms -contains "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                                $PrerequisitePath = $Variables.VerthashDatPath
                                $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                            }
                            Else { 
                                $PrerequisitePath = ""
                                $PrerequisiteURI = ""
                            }

                            [PSCustomObject]@{ 
                                API              = "TeamBlackMiner"
                                Arguments        = "$Arguments --api --api-version 1.4 --api-port $MinerAPIPort$($DeviceSelector.($AvailableMiner_Devices.Type | Select-Object -Unique)) [$(($AvailableMiner_Devices.($DeviceEnumerator.($AvailableMiner_Devices.Type | Select-Object -Unique)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')]"
                                DeviceNames      = $AvailableMiner_Devices.Name
                                Fee              = $_.Fee # Dev fee
                                MinerSet         = $_.MinerSet
                                MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/summary"
                                Name             = $Miner_Name
                                Path             = $Path
                                Port             = $MinerAPIPort
                                PrerequisitePath = $PrerequisitePath
                                PrerequisiteURI  = $PrerequisiteURI
                                Type             = $_.Type
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