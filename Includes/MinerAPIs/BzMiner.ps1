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
File:           BzMiner.ps1
Version:        4.3.4.12
Version date:   27 June 2023
#>
class BzMiner : Miner {
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }

        $Request = "http://127.0.0.1:$($this.Port)/status"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $Devices = $Data.devices | Where-Object { $_.pci_bus_id -in $this.Devices.Bus }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithms[0]
        $HashRate_Value = [Double]($Devices | ForEach-Object { $_.hashrate[0] } | Measure-Object -Sum).Sum
        $HashRate | Add-Member @{$HashRate_Name = [Double]$HashRate_Value}

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]($Devices | ForEach-Object { $_.valid_solutions[0] } | Measure-Object -Sum).Sum
        $Shares_Rejected = [Int64]($Devices | ForEach-Object { $_.rejected_solutions[0] } | Measure-Object -Sum).Sum
        $Shares_Invalid = [Int64]($Devices | ForEach-Object { $_.stale_solutions[0] } | Measure-Object -Sum).Sum
        $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }

        If ($HashRate_Name = [String]($this.Algorithms -ne $HashRate_Name)) {
            $HashRate_Value = [Double]($Devices | ForEach-Object { $_.hashrate[1] } | Measure-Object -Sum).Sum
            $HashRate | Add-Member @{$HashRate_Name = [Double]$HashRate_Value}

            $Shares_Accepted = [Int64]($Devices | ForEach-Object { $_.valid_solutions[1] } | Measure-Object -Sum).Sum
            $Shares_Rejected = [Int64]($Devices | ForEach-Object { $_.rejected_solutions[1] } | Measure-Object -Sum).Sum
            $Shares_Invalid = [Int64]($Devices | ForEach-Object { $_.stale_solutions[1] } | Measure-Object -Sum).Sum
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }
        }

        $PowerUsage = [Double]0
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