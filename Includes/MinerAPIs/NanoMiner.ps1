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
File:           NanoMiner.ps1
Version:        4.3.1.2
Version date:   06 March 2023
#>

class NanoMiner : Miner { 
    CreateConfigFiles() { 
        $Parameters = $this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue

        Try { 
            $ConfigFile = "$(Split-Path $this.Path)\$($Parameters.ConfigFile.FileName)"
            #Write config files. Do not overwrite existing files to preserve optional manual customization
            If (-not (Test-Path -Path $ConfigFile -PathType Leaf)) { 
                $Parameters.ConfigFile.Content | Out-File -FilePath $ConfigFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            }
        }
        Catch { 
            Write-Message -Level Error "Creating miner config files for '$($this.Info)' failed [Error: '$($Error | Select-Object -First 1)']."
            Return
        }
    }

    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0

        $Request = "http://127.0.0.1:$($this.Port)/stats"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = $this.Algorithms[0]
        $HashRate_Value = [Double]0

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        $Data.Algorithms | ForEach-Object { ($_ | Get-Member -MemberType NoteProperty).Name } | Select-Object -Unique | ForEach-Object { 
            $HashRate_Value = [Double]($Data.Algorithms.$_.Total.Hashrate | Measure-Object -Sum).Sum
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

            $Shares_Accepted = [Int64]($Data.Algorithms.$_.Total.Accepted | Measure-Object -Sum).Sum
            $Shares_Rejected = [Int64]($Data.Algorithms.$_.Total.Denied | Measure-Object -Sum).Sum
            $Shares_Invalid = [Int64]0
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }
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

