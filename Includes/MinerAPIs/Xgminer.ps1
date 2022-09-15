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
File:           Xgminer.ps1
Version:        4.2.1.3
Version date:   15 September 2022
#>

class Xgminer : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0

        $Request = @{ command = "summary$(If ($this.Algorithms[1]) { "+summary2" } )"; parameter = "" } | ConvertTo-Json -Compress
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest -Server "localhost" -Port $this.Port -Request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response -replace ": ", ":" -replace " ", "_" | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }

        $DataSummary = If ($this.Algorithms[1]) { $Data.summary.SUMMARY[0] } Else { $Data.SUMMARY }
        $HashRate_Name = [String]$this.Algorithms[0]
        $HashRate_Value = If ($DataSummary.HS_5s) { [Double]$DataSummary.HS_5s * [Math]::Pow(1000, 0) }
        ElseIf ($DataSummary.KHS_5s) { [Double]$DataSummary.KHS_5s * [Math]::Pow(1000, 1) }
        ElseIf ($DataSummary.MHS_5s) { [Double]$DataSummary.MHS_5s * [Math]::Pow(1000, 2) }
        ElseIf ($DataSummary.GHS_5s) { [Double]$DataSummary.GHS_5s * [Math]::Pow(1000, 3) }
        ElseIf ($DataSummary.THS_5s) { [Double]$DataSummary.THS_5s * [Math]::Pow(1000, 4) }
        ElseIf ($DataSummary.PHS_5s) { [Double]$DataSummary.PHS_5s * [Math]::Pow(1000, 5) }
        ElseIf ($DataSummary.KHS_30s) { [Double]$DataSummary.KHS_30s * [Math]::Pow(1000, 1) }
        ElseIf ($DataSummary.MHS_30s) { [Double]$DataSummary.MHS_30s * [Math]::Pow(1000, 2) }
        ElseIf ($DataSummary.GHS_30s) { [Double]$DataSummary.GHS_30s * [Math]::Pow(1000, 3) }
        ElseIf ($DataSummary.THS_30s) { [Double]$DataSummary.THS_30s * [Math]::Pow(1000, 4) }
        ElseIf ($DataSummary.PHS_30s) { [Double]$DataSummary.PHS_30s * [Math]::Pow(1000, 5) }
        ElseIf ($DataSummary.HS_av) { [Double]$DataSummary.HS_av * [Math]::Pow(1000, 0) }
        ElseIf ($DataSummary.KHS_av) { [Double]$DataSummary.KHS_av * [Math]::Pow(1000, 1) }
        ElseIf ($DataSummary.MHS_av) { [Double]$DataSummary.MHS_av * [Math]::Pow(1000, 2) }
        ElseIf ($DataSummary.GHS_av) { [Double]$DataSummary.GHS_av * [Math]::Pow(1000, 3) }
        ElseIf ($DataSummary.THS_av) { [Double]$DataSummary.THS_av * [Math]::Pow(1000, 4) }
        ElseIf ($DataSummary.PHS_av) { [Double]$DataSummary.PHS_av * [Math]::Pow(1000, 5) }
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]$DataSummary.accepted
        $Shares_Rejected = [Int64]$DataSummary.rejected
        $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }

        If ($HashRate_Name = [String]($this.Algorithms -ne $HashRate_Name)) { # Dual algo mining
            $DataSummary = $Data.summary2.SUMMARY[0]
            $HashRate_Value = If ($DataSummary.HS_5s) { [Double]$DataSummary.HS_5s * [Math]::Pow(1000, 0) }
            ElseIf ($DataSummary.KHS_5s) { [Double]$DataSummary.KHS_5s * [Math]::Pow(1000, 1) }
            ElseIf ($DataSummary.MHS_5s) { [Double]$DataSummary.MHS_5s * [Math]::Pow(1000, 2) }
            ElseIf ($DataSummary.GHS_5s) { [Double]$DataSummary.GHS_5s * [Math]::Pow(1000, 3) }
            ElseIf ($DataSummary.THS_5s) { [Double]$DataSummary.THS_5s * [Math]::Pow(1000, 4) }
            ElseIf ($DataSummary.PHS_5s) { [Double]$DataSummary.PHS_5s * [Math]::Pow(1000, 5) }
            ElseIf ($DataSummary.KHS_30s) { [Double]$DataSummary.KHS_30s * [Math]::Pow(1000, 1) }
            ElseIf ($DataSummary.MHS_30s) { [Double]$DataSummary.MHS_30s * [Math]::Pow(1000, 2) }
            ElseIf ($DataSummary.GHS_30s) { [Double]$DataSummary.GHS_30s * [Math]::Pow(1000, 3) }
            ElseIf ($DataSummary.THS_30s) { [Double]$DataSummary.THS_30s * [Math]::Pow(1000, 4) }
            ElseIf ($DataSummary.PHS_30s) { [Double]$DataSummary.PHS_30s * [Math]::Pow(1000, 5) }
            ElseIf ($DataSummary.HS_av) { [Double]$DataSummary.HS_av * [Math]::Pow(1000, 0) }
            ElseIf ($DataSummary.KHS_av) { [Double]$DataSummary.KHS_av * [Math]::Pow(1000, 1) }
            ElseIf ($DataSummary.MHS_av) { [Double]$DataSummary.MHS_av * [Math]::Pow(1000, 2) }
            ElseIf ($DataSummary.GHS_av) { [Double]$DataSummary.GHS_av * [Math]::Pow(1000, 3) }
            ElseIf ($DataSummary.THS_av) { [Double]$DataSummary.THS_av * [Math]::Pow(1000, 4) }
            ElseIf ($DataSummary.PHS_av) { [Double]$DataSummary.PHS_av * [Math]::Pow(1000, 5) }
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
    
            $Shares_Accepted = [Int64]$DataSummary.accepted
            $Shares_Rejected = [Int64]$DataSummary.rejected
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
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

