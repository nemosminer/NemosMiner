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

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/2.75/gminer_2_75_windows64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Equihash1927"; Fee = 0.02; MinMemGiB = 2.8; Type = "AMD"; Tuning = ""; MinerSet = 0; WarmupTimes = @(30, 0); Arguments = " --algo equihash192_7 $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1927.Currency -DefaultCommand "--pers auto") --cuda 0 --opencl 1" } # FPGA

    [PSCustomObject]@{ Algorithm = "Equihash1927"; Fee = 0.02; MinMemGiB = 2.8; Type = "NVIDIA"; Tuning = ""; MinerSet = 1; WarmupTimes = @(30, 0); Arguments = " --algo equihash192_7 $(Get-EquihashCoinPers -Command "--pers " -Currency $MinerPools[0].Equihash1927.Currency -DefaultCommand "--pers auto") --cuda 0 --opencl 1" } # FPGA
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            # Windows 10 requires more memory on some algos
            If ($_.Algorithm -match "Cuckaroo.*|Cuckoo.*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $_.MinMemGiB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB) { 

                $Arguments = $_.Arguments
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "cuda", "opencl", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --server $($AllMinerPools.($_.Algorithm).Host):$($AllMinerPools.($_.Algorithm).PoolPorts | Select-Object -Last 1) --user $($AllMinerPools.($_.Algorithm).User)$(If ($AllMinerPools.($_.Algorithm).WorkerName) { ".$($AllMinerPools.($_.Algorithm).WorkerName)" })"

                If ($AllMinerPools.($_.Algorithm).DAGSizeGiB -ne $null -and $AllMinerPools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $Arguments += " --proto stratum" }
                If ($AllMinerPools.($_.Algorithm).PoolPorts[1]) { $Arguments += " --ssl 1" }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                # Contest ETH address (if ETH wallet is specified in config)
                # $Arguments += If ($Config.Wallets.ETH) { " --contest_wallet $($Config.Wallets.ETH)" } Else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "Gminer"
                    Arguments   = ("$($Arguments) --api $MinerAPIPort --watchdog 0 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    Fee         = $_.Fee
                    MinerSet    = $_.MinerSet
                    MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = $_.Type
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}