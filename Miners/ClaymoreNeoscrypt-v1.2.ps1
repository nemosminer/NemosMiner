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
Version:        5.0.1.10
Version date:   2023/11/06
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -and $Variables.DriverVersion.CIM.AMD -lt "26.20.15011.10003" })) { Return }

$URI = "https://github.com/Minerx117/miners/releases/download/ClaymoreNeoscrypt/claymore_neoscrypt_1.2.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = "$PWD\Bin\$($Name)\NeoScryptMiner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

$Algorithms = @(
    [PSCustomObject]@{ Algorithm = "Neoscrypt"; MinMemGiB = 2; Minerset = 2; WarmupTimes = @(45, 0); ExcludeGPUArchitecture = @("RDNA1", "RDNA2", "RDNA3"); ExcludePools = @(); Arguments = "" } # FPGA
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].BaseName -notin $_.ExcludePools }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithm].PoolPorts[0] }

If ($Algorithms) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        If ($Miner_Devices = $Devices | Where-Object Model -EQ $_.Model) { 

            $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

            $Algorithms | ForEach-Object { 

                $ExcludePools = $_.ExcludePools
                ForEach ($Pool in ($MinerPools[0][$_.Algorithm] | Where-Object { $_.PoolPorts[0] } | Where-Object BaseName -notin $ExcludePools)) { 

                    If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                        $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)"

                        $Fee = If ($Pool.PoolPorts[1]) { @(2.5) } Else { @(2) }

                        # Disable dev fee mining
                        If ($Config.DisableMinerFee) { 
                            $Arguments += " --nofee 1"
                            $Fee = @(0)
                        }

                        [PSCustomObject]@{ 
                            API         = "EthMiner"
                            Arguments   = "$($_.Arguments) -pool $(If ($Pool.PoolPorts[1]) { "stratum+ssl" } Else { "stratum+tcp" })://$($Pool.Host):$($Pool.PoolPorts | Select-Object -Last 1) -wal $($Pool.User)$(If ($Pool.Pass) { " -psw $($Pool.Pass)" }) -mport -$MinerAPIPort -di $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')"
                            DeviceNames = $AvailableMiner_Devices.Name
                            Fee         = $Fee # Dev fee
                            MinerSet    = $_.MinerSet
                            Name        = $Miner_Name
                            Path        = $Path
                            Port        = $MinerAPIPort
                            Type        = "AMD"
                            URI         = $Uri
                            WarmupTimes = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                            Workers     = @(@{ Pool = $Pool })
                        }
                    }
                }
            }
        }
    }
}