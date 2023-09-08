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
File:           \Balances\Zpool.ps1
Version:        5.0.0.2
Version date:   2023/09/08
#>

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PayoutCurrency = $Config.PoolsConfig.$Name.Wallets.psBase.Keys | Select-Object -First 1
$Wallet = $Config.PoolsConfig.$Name.Wallets.$PayoutCurrency
$RetryCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount
$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIRetryInterval

$Request = "https://zpool.ca/api/wallet?address=$Wallet"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

    Try { 
        $APIResponse = Invoke-RestMethod $Request -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore

        If ($Config.LogBalanceAPIResponse) { 
            "$((Get-Date).ToUniversalTime())" | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction Ignore
            $Request | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction Ignore
            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction Ignore
        }

        If ($APIResponse.currency) { 
            Return [PSCustomObject]@{ 
                DateTime = (Get-Date).ToUniversalTime()
                Pool     = $Name
                Currency = $APIResponse.currency
                Wallet   = $Wallet
                Pending  = [Double]$APIResponse.unsold # Pending
                Balance  = [Double]$APIResponse.balance
                Unpaid   = [Double]$APIResponse.unpaid # Balance + unsold (pending)
                # Paid     = [Double]$APIResponse.total # Reset after payout
                # Total    = [Double]$APIResponse.unpaid + [Double]$APIResponse.total # Reset after payout
                Url      = "https://zpool.ca/wallet/$Wallet"
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
    }

    $RetryCount--
}