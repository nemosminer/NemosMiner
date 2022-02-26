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
File:           lolMiner.ps1
Version:        4.0.0.19 (RC19)
Version date:   25 February 2022
#>

class lolMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/summary"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithm[0]
        $HashRate_Unit = [Int64]1
        Switch ($Data.Algorithms[0].Performance_Unit) { 
            "kh/s"  { $HashRate_Unit = [Math]::Pow(10,3) }
            "Mh/s"  { $HashRate_Unit = [Math]::Pow(10,6) }
            "GH/s"  { $HashRate_Unit = [Math]::Pow(10,9) }
            "TH/s"  { $HashRate_Unit = [Math]::Pow(10,12) }
            "PH/s"  { $HashRate_Unit = [Math]::Pow(10,15) }
            "EH/s"  { $HashRate_Unit = [Math]::Pow(10,18) }
            "ZH/s"  { $HashRate_Unit = [Math]::Pow(10,21) }
            "YH/s"  { $HashRate_Unit = [Math]::Pow(10,24) }
            Default { $HashRate_Unit = 1 }
        }
        $HashRate_Value = [Double]($Data.Algorithms[0].Total_Performance * $HashRate_Unit)
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]$Data.Algorithms[0].Total_Accepted
        $Shares_Rejected = [Int64]$Data.Algorithms[0].Total_Rejected
        $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }

        If ($this.Algorithm[1]) { 
            $HashRate_Name = [String]$this.Algorithm[1]
            $HashRate_Unit = [Int64]1
            Switch ($Data.Algorithms[1].Performance_Unit) { 
                "kh/s"  { $HashRate_Unit = [Math]::Pow(10,3) }
                "Mh/s"  { $HashRate_Unit = [Math]::Pow(10,6) }
                "GH/s"  { $HashRate_Unit = [Math]::Pow(10,9) }
                "TH/s"  { $HashRate_Unit = [Math]::Pow(10,12) }
                "PH/s"  { $HashRate_Unit = [Math]::Pow(10,15) }
                "EH/s"  { $HashRate_Unit = [Math]::Pow(10,18) }
                "ZH/s"  { $HashRate_Unit = [Math]::Pow(10,21) }
                "YH/s"  { $HashRate_Unit = [Math]::Pow(10,24) }
                Default { $HashRate_Unit = 1 }
            }
            $HashRate_Value = [Double]($Data.Algorithms[1].Total_Performance * $HashRate_Unit)
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

            $Shares = [PSCustomObject]@{ }
            $Shares_Accepted = [Int64]$Data.Algorithms[1].Total_Accepted
            $Shares_Rejected = [Int64]$Data.Algorithms[1].Total_Rejected
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
        }

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
