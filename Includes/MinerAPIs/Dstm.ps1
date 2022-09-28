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
File:           Dstm.ps1
Version:        4.0.0.28
Version date:   24 April 2022
#>

class Dstm : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = @{ id = 1; method = "getstat" } | ConvertTo-Json -Compress
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest -Server "localhost" -Port $this.Port -request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithm[0]
        $HashRate_Value = [Double]($Data.result.speed_sps | Measure-Object -Sum).Sum
        If (-not $HashRate_Value) { $HashRate_Value = [Double]($Data.result.sol_ps | Measure-Object -Sum).Sum } #fix
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]($Data.result.accepted_shares | Measure-Object -Sum).Sum
        $Shares_Rejected = [Int64]($Data.result.rejected_shares | Measure-Object -Sum).Sum
        $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }

        If ($this.ReadPowerUsage) { 
            $PowerUsage = $this.GetPowerUsage()
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            $Sample = [PSCustomObject]@{ 
                Date       = (Get-Date).ToUniversalTime()
                HashRate   = $HashRate
                PowerUsage = $PowerUsage
                Shares     = $Shares
            }
            Return $Sample
        }
        Return $null
    }
}

