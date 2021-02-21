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
File:           BlazePool.ps1
Version:        3.9.9.20
Version date:   21 February 2021
#>

using module ..\Includes\Include.psm1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$Url = "http://blazepool.com/wallet.html?"

Try { 
    $APIResponse = Invoke-RestMethod "http://api.blazepool.com/wallet/$($Config.PoolsConfig.$Name.Wallet)" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    If ($APIResponse.currency) { 
        [PSCustomObject]@{ 
            DateTime = (Get-Date).ToUniversalTime()
            Pool     = $Name
            Currency = $APIResponse.currency
            Wallet   = $($Config.PoolsConfig.$Name.Wallet)
            Pending  = [Double]($APIResponse.total_unpaid - $APIResponse.balance) # Pending
            Balance  = [Double]($APIResponse.balance)
            Unpaid   = [Double]($APIResponse.total_unpaid) # Balance + unsold (pending)
            # Paid     = [Double]($APIResponse.total_paid)
            # Total    = [Double]($APIResponse.total_earned) # total unpaid + total paid
            Url      = "$($Url)$($Config.PoolsConfig.$Name.Wallet)"
        }
    }
}
Catch { }
