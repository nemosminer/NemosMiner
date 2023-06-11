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
File:           Zpool.ps1
Version:        4.3.4.10
Version date:   11 June 2023
#>

using module ..\Includes\Include.psm1

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PayoutCurrency = $Config.PoolsConfig.$Name.Wallets.Keys | Select-Object -First 1
$Wallet = $Config.PoolsConfig.$Name.Wallets.$PayoutCurrency
$RetryCount = 3
$RetryDelay = 10

$Request = "https://www.hashcryptos.com/api/wallet/?address=$Wallet"

$Headers = @{"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"}
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

    Try { 
        $APIResponse = Invoke-RestMethod $Request -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck

        If ($Config.LogBalanceAPIResponse) { 
            "$((Get-Date).ToUniversalTime())" | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            $Request | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        }

        If ($APIResponse.symbol) { 
            Return [PSCustomObject]@{ 
                DateTime = (Get-Date).ToUniversalTime()
                Pool     = $Name
                Currency = $APIResponse.symbol
                Wallet   = $Wallet
                Pending  = [Double]($APIResponse.unsold) # Pending
                Balance  = [Double]($APIResponse.balance)
                Unpaid   = [Double]($APIResponse.unpaid) # Balance + unsold (pending)
                # Paid     = [Double]($APIResponse.total) # Reset after payout
                # Total    = [Double]($APIResponse.unpaid + $APIResponse.total) # Reset after payout
                Url      = "https://www.hashcryptos.com/?address=$Wallet"
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }

    $RetryCount--
}