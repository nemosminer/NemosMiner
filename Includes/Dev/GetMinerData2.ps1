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
File:           GetMinerData.ps1
Version:        4.2.1.0
Version date:   02 September 2022
#>

using module ".\Include.psm1"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Miner]$Miner
)

Try { 


    "$($Miner.name) Start" > "$($Miner.Name)_Debug.txt"

    $Miner.
    While ($true) { 
        "$($Miner.name) '$($Miner.DataCollectInterval)'" >> "$($Miner.Name)_Debug.txt"
        $NextLoop = (Get-Date).AddSeconds($Miner.DataCollectInterval)
        If ($Data = $Miner.GetMinerData()) { 
            $Miner.LastSample = $Data
            $Miner.Data += $Data
            $Data | ConvertTo-Json >> "$($Miner.name)_Data.txt"
        }

        While ((Get-Date) -lt $NextLoop) { Start-Sleep -Milliseconds 200 }
    }
}
Catch { 
    Return $Error[0]
}
