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

using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.OpenCL.ComputeCapability -ge "5.0" })) { Return }

$URI = "https://github.com/Minerx117/miners/releases/download/GMiner/GMiner2.75.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$($Name)\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Equihash1927"; Fee = @(0.02); MinMemGiB = 2.8; Type = "AMD"; Tuning = ""; MinerSet = 0; WarmupTimes = @(30, 0); ExcludePools = @(); AutoCoinPers = " --pers auto"; Arguments = " --algo equihash192_7 --cuda 0 --opencl 1" } # FPGA

    [PSCustomObject]@{ Algorithm = "Equihash1927"; Fee = @(0.02); MinMemGiB = 2.8; Type = "NVIDIA"; Tuning = ""; MinerSet = 1; WarmupTimes = @(30, 0); ExcludePools = @(); AutoCoinPers = " --pers auto"; Arguments = " --algo equihash192_7  --cuda 0 --opencl 1" } # FPGA
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object BaseName -notin $ExcludePools)) { 

                $MinMemGiB = $_.MinMemGiB + $Pool.DAGSizeGiB
                # Windows 10 requires more memory on some algos
                If ($_.Algorithm -match 'Cuckaroo.*|Cuckoo.*' -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGiB += 1 }

                If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $MinMemGiB) { 

                    $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                    $Arguments = $_.Arguments
                    $Arguments += " --server $($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) --user $($Pool.User)$(If ($Pool.WorkerName) { ".$($Pool.WorkerName)" })"

                    If ($Pool.DAGSizeGiB -ne $null -and $Pool.BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $Arguments += " --proto stratum" }
                    If ($Pool.PoolPorts[1]) { $Arguments += " --ssl 1" }
                    If ($_.AutoCoinPers) {$Arguments += $(Get-EquihashCoinPers -Command " --pers " -Currency $Pool.Currency -DefaultCommand $_.AutoCoinPers) }

                    # Apply tuning parameters
                    If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                    # Contest ETH address (if ETH wallet is specified in config)
                    # $Arguments += If ($Config.Wallets.ETH) { " --contest_wallet $($Config.Wallets.ETH)" } Else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                    [PSCustomObject]@{ 
                        API         = "Gminer"
                        Arguments   = "$Arguments --api $MinerAPIPort --watchdog 0 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')"
                        DeviceNames = $AvailableMiner_Devices.Name
                        Fee         = $_.Fee # Dev fee
                        MinerSet    = $_.MinerSet
                        MinerUri    = "http://127.0.0.1:$($MinerAPIPort)"
                        Name        = $Miner_Name
                        Path        = $Path
                        Port        = $MinerAPIPort
                        Type        = $_.Type
                        URI         = $Uri
                        WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                        Workers     = @(@{ Pool = $Pool })
                    }
                }
            }
        }
    }
}