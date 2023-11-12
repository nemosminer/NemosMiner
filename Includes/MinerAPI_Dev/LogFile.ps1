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
File:           LogFile.ps1
Version:        4.0.1.1
Version date:   19 June 2022
#>

class LogFile : Miner { 
    [Object]GetMinerData () { 

        $Sample = [PSCustomObject]@{ }

        If (Test-Path $this.LogFile -PathType Leaf) { 

            $Lines = Get-Path $this.LogFile
            Remove-Item -Path $this.LogFile -Force

            $Lines | ForEach-Object { 

                $Line = $_ -replace '`n|`r'
                $Line_Simple = $Line -replace '\x1B\[[0-?]*[ -/]*[@-~]'

                If ($Line_Simple) { 

                    $HashRate = [PSCustomObject]@{ }
                    $Shares = [PSCustomObject]@{ }

                    $PowerUsage = 0
                    $HashRate_Name = ""

                    If ($Line_Simple -match '/s') { 
                        $Words = $Line_Simple -split " "

                        $Words -match '/s$' | ForEach-Object { 

                            If ($HashRate_Name -and ($this.Algorithms[1] -gt 1)) { $HashRate_Name = [String]$this.Algorithms[1] } Else { $HashRate_Name = [String]$this.Algorithms[0] }

                            If (($Words | Select-Object -Index $Words.IndexOf($_)) -match '^((?:\d*\.)?\d+)(.*)$') { 
                                $HashRate_Value = ($matches | Select-Object -Index 1) -as [Decimal]
                                $HashRate_Unit = ($matches | Select-Object -Index 2)
                            }
                            Else { 
                                $HashRate_Value = ($Words | Select-Object -Index ($Words.IndexOf($_) - 1)) -as [Decimal]
                                $HashRate_Unit = ($Words | Select-Object -Index $Words.IndexOf($_))
                            }

                            Switch -wildcard ($HashRate_Unit) { 
                                "kh/s*" { $HashRate_Value *= [Math]::Pow(1000, 1) }
                                "mh/s*" { $HashRate_Value *= [Math]::Pow(1000, 2) }
                                "gh/s*" { $HashRate_Value *= [Math]::Pow(1000, 3) }
                                "th/s*" { $HashRate_Value *= [Math]::Pow(1000, 4) }
                                "ph/s*" { $HashRate_Value *= [Math]::Pow(1000, 5) }
                            }
                            $Shares_Accepted = [Int64]0
                            $Shares_Rejected = [Int64]0

                            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
                            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }

                            If ($this.ReadPowerUsage) { 
                                $PowerUsage = $this.GetPowerUsage()
                            }
                        }
                    }

                    If ($HashRate.PSObject.Properties.Value -gt 0) { 
                        $Sample = [PSCustomObject]@{ 
                            Date       = ([DateTime]::Now).ToUniversalTime()
                            HashRate   = $HashRate
                            PowerUsage = $PowerUsage
                            Shares     = $Shares
                        }
                    }
                }
            }
        }
        Return $Sample
    }
}