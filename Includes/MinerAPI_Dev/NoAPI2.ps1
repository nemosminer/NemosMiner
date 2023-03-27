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
Version:        4.2.1.0
Version date:   02 September 2022
#>

class NoAPI : Miner { 
    [Object]GetMinerData () { 

        [Double]$HashRate_Value = 0

        $HashRateFile = [String]".\Data\StaticHashrates_$((($this.Name -split '-') | Select-Object -SkipLast 1) -Join '_').json"

        # This will 'fake' has rate data, VertMiner or SPMinerVerthash currently have no API to retrieve live stat information
        If ($StaticHashRates = Get-Content $HashRateFile | ConvertFrom-Json | Select-Object) { 

            $PowerUsage = [Double]0
            $Sample = [PSCustomObject]@{ }
            $HashRate = [PSCustomObject]@{ }
            $HashRate_Name = [String]$this.Algorithms[0]
            $HashRate_Value = [Double]$StaticHashRates.($this.Devices.Name -join ',')
            $HashRate | Add-Member @{ $HashRate_Name = $HashRate_Value }

            $Shares = [PSCustomObject]@{ }
            $Shares_Accepted = [Int64]0
            $Shares_Rejected = [Int64]0
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }

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
        }
        Else { 
                $Header = '// This file was initially generated by NemosMiner
// Manually enter hashrate in h/s for each available device (Device names separated by ',')
// This will report static hashrate data, miner currently has no API to retrieve live stat information
{ 
    // "GPU#00,GPU#01,GPU#02": 1000, // Same hashrate for GPU#00 - GPU#02
    // "GPU#00": 446000, // RX5700
    // "GPU#01": 744000, // GTX 1030
    // "GPU#02": 443000, // RX580 8GB
    // "GPU#03": 27400   // GTX 1660 Super'

                [String[]]$Definitions = @()
                $this.Device.Name | ForEach-Object { $Definitions += "`"$_`": 0, // $_.Model`n" }
                $Content += 
                $Content += "}"

                { 

}
' | Out-File -FilePath $HashRateFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            Start-Process "Notepad.exe" $HashRateFile
        }
        Return $null
    }
}