<#
Copyright (c) 2018-2020 Nemo, MrPlus & UselessGuru

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
File:           ProHashing.ps1
Version:        3.9.9.21
Version date:   22 February 2021
#>

using module ..\Includes\Include.psm1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$Url = "https://prohashing.com/customer/dashboard"

Try { 
    $APIResponse = Invoke-RestMethod "https://prohashing.com/api/v1/wallet?apiKey=$($Config.ProHashingAPIKey)" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    If ($APIResponse.status -eq "success") { 
        $APIResponse.data.balances | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
            If ($APIResponse.data.balances.$_.balance -gt 0) { 
                [PSCustomObject]@{ 
                    DateTime = (Get-Date).ToUniversalTime()
                    Pool     = $Name
                    Currency = $APIResponse.data.balances.$_.abbreviation
                    Wallet   = $($Config.ProHashingAPIKey)
                    Pending  = [Double]($APIResponse.data.balances.$_.unsold)
                    Balance  = [Double]($APIResponse.data.balances.$_.balance)
                    Unpaid   = [Double]($APIResponse.data.balances.$_.unpaid) # Balance + unsold (pending)
                    # Paid     = [Double]($APIResponse.data.balances.$_.paid24h) # reset after payout
                    # Total    = [Double]($APIResponse.data.balances.$_.total) # total unpaid + total paid, reset after payout
                    Url      = "$($Url)"
                }
            }
        }
    }
}
Catch { }
