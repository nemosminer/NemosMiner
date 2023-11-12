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
File:           BMiner.ps1
Version:        4.3.4.6
Version date:   03 May 2023
#>

class BMiner : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0

        $Request = "http://127.0.0.1:$($this.Port)/api/v1/status/solver"
        $Request2 = "http://127.0.0.1:$($this.Port)/api/v1/status/stratum"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not (($Data.devices | Get-Member -MemberType NoteProperty).Name | ForEach-Object { $Data.devices.$_.solvers })) { Return $null }

        #Read stratum info from API
        Try { 
            $Data | Add-Member stratums (Invoke-RestMethod -Uri $Request2 -TimeoutSec $Timeout).stratums
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = ""
        $HashRate_Value = [Double]0

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0
        $Shares_Invalid = [Int64]0

        [Int]$Index = 0

        $this.Algorithms | ForEach-Object { 
            $Index = $this.Algorithms.IndexOf($_)
            $HashRate_Name = $_
            $HashRate_Value = [Double]((($Data.devices | Get-Member -MemberType NoteProperty).Name | ForEach-Object { $Data.devices.$_.solvers[$Index] }).speed_info.hash_rate | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
            If (-not $HashRate_Value) { $HashRate_Value = [Double]((($Data.devices | Get-Member -MemberType NoteProperty).Name | ForEach-Object { $Data.devices.$_.solvers[$Index] }).speed_info.solution_rate | Measure-Object -Sum | Select-Object -ExpandProperty Sum)}
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

            $Shares_Accepted = [Int64]$Data.stratums.(($Data.stratums | Get-Member -MemberType NoteProperty).Name | Where-Object { (Get-Algorithm $_) -eq $HashRate_Name }).accepted_shares
            $Shares_Rejected = [Int64]$Data.stratums.(($Data.stratums | Get-Member -MemberType NoteProperty).Name | Where-Object { (Get-Algorithm $_) -eq $HashRate_Name }).rejected_shares
            $Shares_Invalid = [Int64]0
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }
        }

        If ($this.ReadPowerUsage) { 
            $PowerUsage = $this.GetPowerUsage()
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            Return [PSCustomObject]@{ 
                Date       = ([DateTime]::Now).ToUniversalTime()
                HashRate   = $HashRate
                PowerUsage = $PowerUsage
                Shares     = $Shares
            }
        }
        Return $null
    }
}
