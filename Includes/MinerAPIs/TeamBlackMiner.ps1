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
File:           \Includes\MinerAPIs\lolMiner.ps1
Version:        5.0.2.6
Version date:   2023/12/28
#>

Class TeamBlackMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = "http://127.0.0.1:$($this.Port)/summary"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]""
        $HashRate_Value = [Double]0

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0
        $Shares_Invalid = [Int64]0

        ForEach ($Algorithm in $this.Algorithms) { 
            $Data.pool.PSObject.Properties.Name | ForEach-Object { 
                If ($Data.pool.$_.Algo -eq ($Algorithm -replace '-\dGiB$')) { 
                    $HashRate_Name = [String]$Algorithm
                    $HashRate_Value = [Double]($Data.pool.$_.total_hashrate)
                    $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

                    $Shares_Accepted = [Int64]($Data.pool.$_.total_accepted)
                    $Shares_Rejected = [Int64]($Data.pool.$_.total_rejected)
                    $Shares_Invalid =  [Int64]($Data.pool.$_.total_stale)
                    $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }
                }
            }
        }

        $PowerConsumption = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerConsumption) { 
                $Data.Devices | ForEach-Object { $PowerConsumption += [Double]$_.PSObject.Properties.Value.watt }
                $PowerConsumption = [Double]($Data.result | Measure-Object gpu_power_usage -Sum | Select-Object -ExpandProperty Sum)
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