<#
Copyright (c) 2018-2022 Nemo, MrPlus & UselessGuru

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
File:           Zpool.ps1
Version:        4.0.0.28
Version date:   24 April 2022
#>

using module ..\Includes\Include.psm1

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PayoutCurrency = $Config.PoolsConfig.$Name.Wallets.Keys | Select-Object -First 1
$Wallet = $Config.PoolsConfig.$Name.Wallets.$PayoutCurrency
$Url = "https://zpool.ca/wallet/$Wallet"

$RetryCount = 3
$RetryDelay = 15

$Request = "https://zpool.ca/api/wallet?address=$Wallet"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

    $APIResponse = Invoke-RestMethod $Request -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop

    If ($Config.LogBalanceAPIResponse -eq $true) { 
        "$((Get-Date).ToUniversalTime())" | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        $Request | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        $APIResponse | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    }

    If ($APIResponse.currency) { 
        [PSCustomObject]@{ 
            DateTime = (Get-Date).ToUniversalTime()
            Pool     = $Name
            Currency = $APIResponse.currency
            Wallet   = $Wallet
            Pending  = [Double]($APIResponse.unsold) # Pending
            Balance  = [Double]($APIResponse.balance)
            Unpaid   = [Double]($APIResponse.unpaid) # Balance + unsold (pending)
            # Paid     = [Double]($APIResponse.total) # Reset after payout
            # Total    = [Double]($APIResponse.unpaid + $APIResponse.total) # Reset after payout
            Url      = $Url
        }
    }
    Else { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }

    $RetryCount--
}
