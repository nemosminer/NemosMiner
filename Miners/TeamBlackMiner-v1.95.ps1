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
Version:        4.3.6.1
Version date:   2023/08/19
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.CUDAVersion -ge "11.6") })) { Return }

$URI = "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.95/TeamBlackMiner_1_95_cuda_12.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; INTEL = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = @{ AMD = "Type_Vendor_Id"; INTEL = "Type_Vendor_Index"; NVIDIA = "Type_Vendor_Index" } # Device numeration seems to be mixed up with OpenCL

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("EtcHash");             Type = "AMD"; Fee = 0.005; MinMemGiB = 1.21; ExcludePools = @(@(), @()); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash"); Type = "AMD"; Fee = 0.005; MinMemGiB = 1.21; ExcludePools = @(@(), @()); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 45); Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("Ethash");              Type = "AMD"; Fee = 0.005; MinMemGiB = 1.21; ExcludePools = @(@(), @()); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 15); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");  Type = "AMD"; Fee = 0.005; MinMemGiB = 1.21; ExcludePools = @(@(), @()); Minerset = 1; Tuning = ""; WarmupTimes = @(45, 45); Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("VertHash");            Type = "AMD"; Fee = 0.01;  MinMemGiB = 3.0;  ExcludePools = @(@(), @()); Minerset = 1; Tuning = ""; WarmupTimes = @(60, 0);  Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }

    [PSCustomObject]@{ Algorithms = @("EtcHash");             Type = "INTEL"; Fee = 0.005; MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo etchash" }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "KawPow");   Type = "INTEL"; Fee = 0.005; MinMemGiB = 0.21 + $MinerPools[1].KawPow.DAGSizeGiB; ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo etc+rvn" } # https://github.com/sp-hash/TeamBlackMiner/issues/376
    [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash"); Type = "INTEL"; Fee = 0.005; MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("Ethash");              Type = "INTEL"; Fee = 0.005; MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo ethash" }
    [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");    Type = "INTEL"; Fee = 0.005; MinMemGiB = 0.21 + $MinerPools[1].KawPow.DAGSizeGiB; ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo eth+rvn " } # https://github.com/sp-hash/TeamBlackMiner/issues/376
    [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");  Type = "INTEL"; Fee = 0.005; MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("KawPow");              Type = "INTEL"; Fee = 0.01;  MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(60, 45); Arguments = " --algo kawpow" }
    [PSCustomObject]@{ Algorithms = @("VertHash");            Type = "INTEL"; Fee = 0.01;  MinMemGiB = 3.0;                                     ExcludePools = @(@(), @()); MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(60, 60); Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }

    [PSCustomObject]@{ Algorithms = @("EtcHash");             Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithms = @("EtcHash", "KawPow");   Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 0.21 + $MinerPools[1].KawPow.DAGSizeGiB; ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo etc+rvn" } # Broken (https://github.com/sp-hash/TeamBlackMiner/issues/377). Use 1.94 instead
    [PSCustomObject]@{ Algorithms = @("EtcHash", "VertHash"); Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo etc+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
    [PSCustomObject]@{ Algorithms = @("Ethash");              Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 15); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
#   [PSCustomObject]@{ Algorithms = @("Ethash", "KawPow");    Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 0.21 + $MinerPools[1].KawPow.DAGSizeGiB; ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo eth+rvn" } # Broken (https://github.com/sp-hash/TeamBlackMiner/issues/377). Use 1.94 instead
    [PSCustomObject]@{ Algorithms = @("Ethash", "VertHash");  Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(45, 45); Arguments = " --algo eth+vtc --verthash-data ..\.$($Variables.VerthashDatPath)" }
#   [PSCustomObject]@{ Algorithms = @("KawPow");              Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.21;                                    ExcludePools = @(@(), @()); Minerset = 2; Tuning = " --tweak 2"; WarmupTimes = @(75, 45); Arguments = " --algo kawpow" } # Broken (https://github.com/sp-hash/TeamBlackMiner/issues/377). Use 1.94 instead
    [PSCustomObject]@{ Algorithms = @("VertHash");            Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3.0;                                     ExcludePools = @(@(), @()); MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(60, 60); Arguments = " --algo verthash --verthash-data ..\.$($Variables.VerthashDatPath)" }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).BaseName -notin $_.ExcludePools[0] -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).BaseName -notin $_.ExcludePools[1]) }

# Dual algorithm mining: Both pools must use same protocol (SSL or non-SSL) :-(
$Algorithms = $Algorithms | Where-Object { -not $_.Algorithms[1] -or ($MinerPools[0].($_.Algorithms[0]).PoolPorts[0] -and $MinerPools[1].($_.Algorithms[1]).PoolPorts[0]) -or ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1] -and $MinerPools[1].($_.Algorithms[1]).PoolPorts[1])}

If ($Algorithms) { 

    $Algorithms | ForEach-Object { 
        $_.MinMemGiB += $AllMinerPools.($_.Algorithms[0]).DAGSizeGiB
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })" -replace ' '

                $Arguments += " --hostname $($AllMinerPools.($_.Algorithms[0]).Host)"
                $Arguments += " --wallet $($AllMinerPools.($_.Algorithms[0]).User)"
                $Arguments += If ($AllMinerPools.($_.Algorithms[0]).PoolPorts[1]) { " --ssl-port $($AllMinerPools.($_.Algorithms[0]).PoolPorts[1])" } Else { " --port $($AllMinerPools.($_.Algorithms[0]).PoolPorts[0])"}
                If ($AllMinerPools.($_.Algorithms[0]).Pass) { $Arguments += " --server-passwd $($AllMinerPools.($_.Algorithms[0]).Pass)" }

                $SecondAlgo = Switch ($_.Algorithms[1]) { 
                    "KawPow"   { "rvn"; Break }
                    "VertHash" { "vtc"; Break }
                    Default    { "" }
                }
                If ($SecondAlgo) { 
                    $Arguments += " --$($SecondAlgo)-hostname $($AllMinerPools.($_.Algorithms[1]).Host) --$($SecondAlgo)-wallet $($AllMinerPools.($_.Algorithms[1]).User) "
                    $Arguments += If ($AllMinerPools.($_.Algorithms[1]).PoolPorts[1]) { " --$($SecondAlgo)-port $($AllMinerPools.($_.Algorithms[1]).PoolPorts[1])" } Else { " --$($SecondAlgo)-port $($AllMinerPools.($_.Algorithms[1]).PoolPorts[0])" }
                }
                $Arguments += If ($AllMinerPools.($_.Algorithms[0]).PoolPorts[1]) { " --ssl --ssl-verify-none"}

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                If ($_.Algorithms[0] -eq "VertHash" -and (Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -ne 1283457024) { 
                    $PrerequisitePath = $Variables.VerthashDatPath
                    $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                }
                Else { 
                    $PrerequisitePath = ""
                    $PrerequisiteURI = ""
                }

                [PSCustomObject]@{ 
                    Algorithms       = @($_.Algorithms | Select-Object)
                    API              = "TeamBlackMiner"
                    Arguments        = ("$Arguments --api --api-version 1.4 --api-port $MinerAPIPort$($DeviceSelector.($AvailableMiner_Devices.Type | Select-Object -Unique)) [$(($AvailableMiner_Devices.($DeviceEnumerator.($AvailableMiner_Devices.Type | Select-Object -Unique)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')]" -replace "\s+", " ").trim()
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Fee              = $_.Fee
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
                }
            }
        }
    }
}