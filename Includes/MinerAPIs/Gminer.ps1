<#
Copyright (c) 2018-2022 Nemo, MrPlus & UselessGuru

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
File:           GMiner.ps1
Version:        4.2.2.2
Version date:   16 October 2022
#>

class Gminer : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0

        $Request = "http://localhost:$($this.Port)/stat"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithms[0]
        $HashRate_Value = [Double]($Data.devices.speed | Measure-Object -Sum).Sum
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]$Data.total_accepted_shares
        $Shares_Rejected = [Int64]$Data.total_rejected_shares
        $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }

        If ($HashRate_Name = [String]($this.Algorithms -ne $HashRate_Name)) {
            $HashRate_Value = [Double]($Data.devices.speed2 | Measure-Object -Sum).Sum
            $Shares_Accepted = [Int64]$Data.total_accepted_shares2
            $Shares_Rejected = [Int64]$Data.total_rejected_shares2
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }

            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
        }

        If ($this.ReadPowerUsage) { 
            $PowerUsage = $this.GetPowerUsage()
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            Return [PSCustomObject]@{ 
                Date       = (Get-Date).ToUniversalTime()
                HashRate   = $HashRate
                PowerUsage = $PowerUsage
                Shares     = $Shares
            }
        }
        Return $null
    }
}

