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
Version:        5.0.2.5
Version date:   2023/12/20
#>

If (-not ($Devices = $Variables.EnabledDevices.Where({ $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAVersion -ge [Version]"11.6") }))) { Return }

$URI = "https://github.com/sp-hash/TeamBlackMiner/releases/download/V2.16/TeamBlackMiner_2_16_cuda_12_0.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$Name\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; INTEL = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = @{ AMD = "Type_Vendor_Id"; INTEL = "Type_Vendor_Index"; NVIDIA = "Type_Vendor_Index" } # Device numeration seems to be mixed up with OpenCL

$Algorithms = @(
    [PSCustomObject]@{ Algorithms = @("EtcHash");              Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "EthashB3");  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = ""; WarmupTimes = @(45, 45);  ExcludeGPUArchitecture = @("RDNA1"); ExcludePools = @(@(), @()); Arguments = " --algo etc+ethb3" } # https://github.com/sp-hash/TeamBlackMiner/issues/428
    [PSCustomObject]@{ Algorithms = @("EtcHash", "FiroPow");   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = ""; WarmupTimes = @(45, 45);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo etc+firo" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "KawPow");    Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = ""; WarmupTimes = @(90, 45);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo etc+rvn" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash");  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 1; Tuning = ""; WarmupTimes = @(120, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" } # 120 Seconds; https://github.com/sp-hash/TeamBlackMiner/issues/427
    [PSCustomObject]@{ Algorithms = @("Ethash");               Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "EthashB3");   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = ""; WarmupTimes = @(45, 15);  ExcludeGPUArchitecture = @("RDNA1"); ExcludePools = @(@(), @()); Arguments = " --algo eth+ethb3" } # https://github.com/sp-hash/TeamBlackMiner/issues/428
    [PSCustomObject]@{ Algorithms = @("Ethash", "FiroPow");    Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = ""; WarmupTimes = @(45, 15);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo eth+firo" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");     Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = ""; WarmupTimes = @(90, 45);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo eth+rvn" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 1; Tuning = ""; WarmupTimes = @(120, 15); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" } # 120 Secs; https://github.com/sp-hash/TeamBlackMiner/issues/427
    [PSCustomObject]@{ Algorithms = @("EthashB3");             Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo ethashb3" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "FiroPow");  Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 1; Tuning = ""; WarmupTimes = @(45, 30);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo ethb3+firo" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "KawPow");   Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = ""; WarmupTimes = @(90, 45);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo ethb3+rvn" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "VertHash"); Type = "AMD"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 1; Tuning = ""; WarmupTimes = @(120, 30); ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo ethb3+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" } # 120 Seconds; https://github.com/sp-hash/TeamBlackMiner/issues/427
    [PSCustomObject]@{ Algorithms = @("FiroPow");              Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo firopow" }
    [PSCustomObject]@{ Algorithms = @("KawPow");               Type = "AMD"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 2; Tuning = ""; WarmupTimes = @(45, 15);  ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo kawpow" }
    [PSCustomObject]@{ Algorithms = @("VertHash");             Type = "AMD"; Fee = @(0.005);        MinMemGiB = 3.0;  Minerset = 1; Tuning = ""; WarmupTimes = @(30, 0);   ExcludeGPUArchitecture = @();        ExcludePools = @(@(), @()); Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }
 
    [PSCustomObject]@{ Algorithms = @("EtcHash");              Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "EthashB3");  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo etc+ethb3" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "FiroPow");   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo etc+firo" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "KawPow");    Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo etc+rvn" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash");  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("Ethash");               Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "EthashB3");   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo eth+ethb3" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "FiroPow");    Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo eth+firo" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");     Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo eth+rvn" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("EthashB3");             Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo ethashb3" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "FiroPow");  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo ethb3+firo" }
    
    [PSCustomObject]@{ Algorithms = @("EthashB3", "KawPow");   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.51; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo ethb3+rvn" }
    [PSCustomObject]@{ Algorithms = @("EthashB3", "VertHash"); Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.70; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo ethb3+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("FiroPow");              Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo firopow" }
    [PSCustomObject]@{ Algorithms = @("KawPow");               Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 1.24; Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo kawpow" }
    [PSCustomObject]@{ Algorithms = @("VertHash");             Type = "NVIDIA"; Fee = @(0.005);        MinMemGiB = 3.0;  MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(30, 0);  ExcludeGPUArchitecture = @(); ExcludePools = @(@(), @()); Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }
)

$Algorithms = $Algorithms.Where({ $_.MinerSet -le $Config.MinerSet })
$Algorithms.Where({ -not $_.Algorithms[1] }) | ForEach-Object { $_.Algorithms += "" }
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]] -and ($_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]]) })
$Algorithms = $Algorithms.Where({ $MinerPools[0][$_.Algorithms[0]].Name -notin $_.ExcludePools[0] })
$Algorithms = $Algorithms.Where({ $MinerPools[1][$_.Algorithms[1]].Name -notin $_.ExcludePools[1] })

If ($Algorithms) { 

    # # Intensities for 2. algorithm
    # $IntensityValues = [PSCustomObject]@{ 
    #     "EthashB3" = @(8, 12, 16, 20, 24, 32)
    #     "FiroPow"  = @(8, 12, 16, 20, 24, 32)
    #     "KawPow"   = @(8, 12, 16, 20, 24, 32)
    #     "VertHash" = @(8, 12, 16, 20, 24, 32)
    # }

    # # Build command sets for intensities
    # $Algorithms = $Algorithms.ForEach(
    #     { 
    #         If ($_.Algorithms[1] -and $IntensityValues.($_.Algorithms[1])) { 
    #             $Intensity = $_.Intensity
    #             ForEach ($Intensity in ($IntensityValues.($_.Algorithms[1]) | Select-Object)) { 
    #                 $_ | Add-Member Intensity $Intensity -Force
    #                 $_.PsObject.Copy()
    #             }
    #         }
    #         Else { 
    #             $_.PsObject.Copy()
    #         }
    #     }
    # )

    ($Devices | Select-Object Type, Model -Unique).ForEach(
        { 
            $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
            $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

            ($Algorithms | Where-Object Type -EQ $_.Type).ForEach(
                { 
                    $ExcludePools = $_.ExcludePools
                    ForEach ($Pool0 in ($MinerPools[0][$_.Algorithms[0]].Where({ $_.Name -notin $ExcludePools[0] }))) { 
                        ForEach ($Pool1 in ($MinerPools[1][$_.Algorithms[1]].Where({ $_.Name -notin $ExcludePools[1] }))) { 

                            # Dual algorithm mining: Both pools must support same protocol (SSL or non-SSL) :-(
                            If (-not $_.Algorithms[1] -or ($Pool0.PoolPorts[0] -and $Pool1.PoolPorts[0]) -or ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1])) { 

                                $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture
                                $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                                If ($AvailableMiner_Devices = $Miner_Devices.Where({ $_.MemoryGiB -ge $MinMemGiB -and $_.Architecture -notin $ExcludeGPUArchitecture })) { 

                                    $Miner_Name = "$Name-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })$(If ($_.Intensity) { "-$($_.Intensity)" })"

                                    $Arguments = $_.Arguments
                                    $Arguments += " --hostname $($Pool0.Host)"
                                    $Arguments += " --wallet $($Pool0.User)"
                                    $Arguments += If (($Pool0.PoolPorts[1] -and -not $_.Algorithms[1]) -or ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1])) { " --ssl --ssl-verify-none --ssl-port $($Pool0.PoolPorts[1])" } Else { " --port $($Pool0.PoolPorts[0])"}
                                    If ($Pool0.Pass) { $Arguments += " --server-passwd $($Pool0.Pass)" }

                                    $SecondAlgo = Switch ($_.Algorithms[1]) { 
                                        "EthashB3" { "ethb3" }
                                        "FiroPow"  { "firo" }
                                        "KawPow"   { "rvn" }
                                        "VertHash" { "vtc" }
                                        Default    { "" }
                                    }
                                    If ($SecondAlgo) { 
                                        $Arguments += " --$($SecondAlgo)-hostname $($Pool1.Host) --$($SecondAlgo)-wallet $($Pool1.User) --$($SecondAlgo)-passwd $($Pool1.Pass)"
                                        $Arguments += If ($Pool0.PoolPorts[1] -and $Pool1.PoolPorts[1]) { " --$($SecondAlgo)-port $($Pool1.PoolPorts[1])" } Else { " --$($SecondAlgo)-port $($Pool1.PoolPorts[0])" }
                                        If ($_.Intensity) { $Arguments += " --dual-xintensity $($_.Intensity)" }
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
                                        Workers          = @(($Pool0, $Pool1).Where({ $_ }) | ForEach-Object { @{ Pool = $_ } })
                                    }
                                }
                            }
                        }
                    }
                }
            )
        }
    )
}