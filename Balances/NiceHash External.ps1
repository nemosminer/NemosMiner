<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           \Balances\NiceHash Internal.ps1
Version:        5.0.2.6
Version date:   2023/12/28
#>

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $Config.PoolsConfig.NiceHash
$PayoutCurrency = $PoolConfig.Variant.$Name.PayoutCurrency
$Wallet = $Config.PoolsConfig.NiceHash.Variant.$Name.Wallets.$PayoutCurrency
$RetryCount = $PoolConfig.PoolAPIAllowedFailureCount
$RetryInterval = $PoolConfig.PoolAPIRetryInterval

$Request = "https://api2.nicehash.com/main/api/v2/mining/external/$Wallet/rigs2"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

    Try { 
        $APIResponse = Invoke-RestMethod $Request -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore

        If ($Config.LogBalanceAPIResponse) { 
            "$(([DateTime]::Now).ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }

        If ($Sum = [Double]$APIResponse.unpaidAmount + [Double]$APIResponse.externalBalance) { 
            Return [PSCustomObject]@{ 
                DateTime   = ([DateTime]::Now).ToUniversalTime()
                Pool       = $Name
                Currency   = $PayoutCurrency
                Wallet     = $Wallet
                Pending    = [Double]$APIResponse.unpaidAmount
                Balance    = [Double]$APIResponse.externalBalance
                Unpaid     = $Sum
                #Total      = $Sum
                Url        = "https://www.nicehash.com/my/miner/$Wallet"
                NextPayout = $APIResponse.NextPayoutTimeStamp
            }
        }
        Else { 
            Return
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
    }

    $RetryCount--
}