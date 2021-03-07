<#
Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru

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
File:           ZergPool.ps1
Version:        3.9.9.24
Version date:   07 March 2021
#>

using module ..\Includes\Include.psm1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PayoutCurrency = $Config.PoolsConfig.$Name.Wallets.Keys | Select-Object -Index 0
$Wallet = $Config.PoolsConfig.$Name.Wallets.$PayoutCurrency
$Url = "http://zergpool.com/?address=$Wallet"

Try { 
    $APIResponse = Invoke-RestMethod "http://www.zergpool.com:8080/api/wallet?address=$Wallet" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    If ($APIResponse.currency) { 
        [PSCustomObject]@{ 
            DateTime = (Get-Date).ToUniversalTime()
            Pool     = $Name
            Currency = $APIResponse.Currency
            Wallet   = $Wallet
            Pending  = [Double]($APIResponse.Unsold) # Pending
            Balance  = [Double]($APIResponse.Balance)
            Unpaid   = [Double]($APIResponse.Unpaid) # Balance + unsold (pending)
            # Paid     = [Double]($APIResponse.PaidTotal)
            # Total    = [Double]($APIResponse.Unpaid) + $APIResponse.PaidTotal
            Url      = $Url
        }
    }
}
Catch { }
