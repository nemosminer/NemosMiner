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
Version:        4.2.1.0
Version date:   02 September 2022
#>

Set-Location (".\Bin\SPminerVertHash-v4")

$LogFile = Get-ChildItem -Path . -Filter ".\*.txt" | Sort-Object CreationTime | Select-Object -Last 1

Get-Content $LogFile | ForEach-Object { 
    $Line = $_ -replace '`n|`r'
    $Line_Simple = $Line -replace '\x1B\[[0-?]*[ -/]*[@-~]'

    If ($TimeStamp = ([DateTime](($Line_Simple -split ']  ' | Select-Object -First 1) -replace '\[' -replace '\]  ')).ToUniversalTime()) { 

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithms
        $HashRate_Name = "VertHash"
        $HashRates = 0
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0
        $Shares_Total = [Int64]0

        $Line_Data = $Line_Simple -split ']  ' | Select-Object -Index 1

        If ($Line_Data -match '^GPU[0-9]+\d\.\d. ( |k|m)H/s') { 
            $Line_Data -split 'GPU\d ' | Where-Object { $_ } | ForEach-Object { 
                $HashRate_Value = ($_ -split ' ' | Select-Object -First 1) -as [Decimal]
                $HashRate_Unit = ($_ -split ' ' | Select-Object -Index 1)

                Switch -wildcard ($HashRate_Unit.ToLower()) { 
                    "kh/s*" { $HashRate_Value *= [Math]::Pow(1000, 1) }
                    "mh/s*" { $HashRate_Value *= [Math]::Pow(1000, 2) }
                    "gh/s*" { $HashRate_Value *= [Math]::Pow(1000, 3) }
                    "th/s*" { $HashRate_Value *= [Math]::Pow(1000, 4) }
                    "ph/s*" { $HashRate_Value *= [Math]::Pow(1000, 5) }
                }
                $Hashrates += $HashRate_Value
            }

            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRates }
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }

            If ($this.ReadPowerUsage) { 
                $PowerUsage = $this.GetPowerUsage()
            }
        }
        ElseIf ($Line_Data -match '^(accepted|rejected): [0-9]+/[0-9]+ \([0-9]+\.[0-9]+%\), [0-9]+\.[0-9]+ ( |k|m)H/s') { 
            $HashRate_Value = (($Line_Data -split ', ' | Select-Object -Index 1) -split ' ' | Select-Object -First 1) -as [Decimal]
            $HashRate_Unit = (($Line_Data -split ', ' | Select-Object -Index 1) -split ' ' | Select-Object -Index 1)

            Switch -wildcard ($HashRate_Unit.ToLower()) { 
                "kh/s*" { $HashRate_Value *= [Math]::Pow(1000, 1) }
                "mh/s*" { $HashRate_Value *= [Math]::Pow(1000, 2) }
                "gh/s*" { $HashRate_Value *= [Math]::Pow(1000, 3) }
                "th/s*" { $HashRate_Value *= [Math]::Pow(1000, 4) }
                "ph/s*" { $HashRate_Value *= [Math]::Pow(1000, 5) }
            }

            $Shares_Accepted = [Int64](($Line_Data -split ' ' | Select-Object -Index 1) -split '\/' | Select-Object -First 1)
            $Shares_Total    = [Int64](($Line_Data -split ' ' | Select-Object -Index 1) -split '\/' | Select-Object -Index 1)
            $Shares_Rejected = $Shares_Total - $Shares_Accepted

            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Total) }

            If ($this.ReadPowerUsage) { 
                $PowerUsage = $this.GetPowerUsage()
            }
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            $Sample = [PSCustomObject]@{ 
                Date       = $TimeStamp
                HashRate   = $HashRate
                PowerUsage = $PowerUsage
                Shares     = $Shares
            }
        }
    }
}