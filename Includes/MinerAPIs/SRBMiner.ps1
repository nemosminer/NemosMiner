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
File:           SRBminer.ps1
Version:        4.0.0.13 (RC13)
Version date:   03 January 2022
#>

class SRBMiner : Miner { 

    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithm[0]
        $HashRate_Value = [Double]0
        If ($Data.algorithms) { $HashRate_Value = [Double]$Data.algorithms[0].hashrate.gpu.total }
        If (-not $HashRate_Value) { $HashRate_Value = [Double]$Data.algorithms[0].hashrate.cpu.total }
        If (-not $HashRate_Value) { $HashRate_Value = [Double]$Data.algorithms[0].hashrate.now }
        If (-not $HashRate_Value) { $HashRate_Value = [Double]$Data.hashrate_total_now }
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0
        If ($Data.algorithms) { 
            $Shares_Accepted = [Int64]$Data.algorithms[0].shares.accepted
            $Shares_Rejected = [Int64]$Data.algorithms[0].shares.rejected 
        }
        Else { 
            $Shares_Accepted = [Int64]$Data.shares.accepted
            $Shares_Rejected = [Int64]$Data.shares.rejected
        }
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
