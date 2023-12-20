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
File:           \Includes\MinerAPIs\SRBminer.ps1
Version:        5.0.2.4
Version date:   2023/12/20
#>

Class SRBMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $Type = If ($Data.total_cpu_workers -gt 0) { "cpu" } Else { "gpu" }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithms[0]
        $HashRate_Value = [Double]$Data.algorithms[0].hashrate.$Type.total
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]$Data.algorithms[0].shares.accepted
        $Shares_Rejected = [Int64]$Data.algorithms[0].shares.rejected
        $Shares_Invalid = [Int64]0
        $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }

        If ($HashRate_Name = [String]($this.Algorithms -ne $HashRate_Name)) { 
            $HashRate_Name = [String]$this.Algorithms[1]
            $HashRate_Value = [Double]$Data.algorithms[1].hashrate.$Type.total
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

            $Shares_Accepted = [Int64]$Data.algorithms[1].shares.accepted
            $Shares_Rejected = [Int64]$Data.algorithms[1].shares.rejected 
            $Shares_Invalid = [Int64]0
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }
        }

        $PowerConsumption = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = [Double]($Data.gpu_devices | Measure-Object asic_power -Sum | Select-Object -ExpandProperty Sum)
                If (-not $PowerConsumption) { 
                    $PowerConsumption = $this.GetPowerConsumption()
                }
            }

            Return [PSCustomObject]@{ 
                Date             = ([DateTime]::Now).ToUniversalTime()
                HashRate         = $HashRate
                PowerConsumption = $PowerConsumption
                Shares           = $Shares
            }
        }
        Return $null
    }
}