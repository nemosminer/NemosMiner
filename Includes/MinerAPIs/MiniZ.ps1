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
File:           \Includes\MinerAPIs\MiniZ.ps1
Version:        5.0.1.8
Version date:   2023/11/03
#>

Class MiniZ : Miner { 
    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $Request = '{ "id":"0", "method":"getstat" }'
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest 127.0.0.1 -Port $this.Port -Request $Request -Timeout $Timeout -ReadToEnd $true -ErrorAction Stop
            $Data = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithms[0]
        $HashRate_Value = [Double]($Data.result.speed_sps | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        If (-not $HashRate_Value) { $HashRate_Value = [Double]($Data.result.sol_ps | Measure-Object -Sum | Select-Object -ExpandProperty Sum) } #fix
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]($Data.result.accepted_shares | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        $Shares_Rejected = [Int64]($Data.result.rejected_shares | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        $Shares_Invalid = [Int64]0
        $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }

        $PowerUsage = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerUsage) { 
                $PowerUsage = [Double]($Data.result | Measure-Object gpu_power_usage -Sum | Select-Object -ExpandProperty Sum)
                If (-not $PowerUsage) { 
                    $PowerUsage = $this.GetPowerUsage()
                }
            }

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