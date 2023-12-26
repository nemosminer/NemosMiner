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
File:           \Balances\ZergPool.ps1
Version:        5.0.2.5
Version date:   2023/12/20
#>

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIRetryInterval

$Config.PoolsConfig.$Name.Wallets.Keys.ForEach(
    { 
        $Currency = $_
        $Wallet = $Config.PoolsConfig.$Name.Wallets.$Currency

        $RetryCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount
        $Request = "https://zergpool.com/api/wallet?address=$Wallet"

        While (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

            Try { 

                $APIResponse = Invoke-RestMethod $Request -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore

                If ($Config.LogBalanceAPIResponse) { 
                    "$(([DateTime]::Now).ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                    $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                    $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                }

                If ($APIResponse.currency -and ($APIResponse.Unsold -or $APIResponse.Balance -or $APIResponse.Unpaid)) { 
                    [PSCustomObject]@{ 
                        DateTime        = ([DateTime]::Now).ToUniversalTime()
                        Pool            = $Name
                        Currency        = $APIResponse.Currency
                        Wallet          = $Wallet
                        Pending         = [Double]$APIResponse.Unsold
                        Balance         = [Double]$APIResponse.Balance
                        Unpaid          = [Double]$APIResponse.Unpaid
                        # Paid            = [Double]$APIResponse.PaidTotal
                        # Total           = [Double]$APIResponse.Unpaid + [Double]$APIResponse.PaidTotal
                        PayoutThreshold = [Double]($(If ($Config.PoolsConfig.$Name.PayoutThreshold.$Currency -gt $APIResponse.MinPay) { $Config.PoolsConfig.$Name.PayoutThreshold.$Currency } Else { $APIResponse.MinPay } ))
                        Url             = "https://zergpool.com/?address=$Wallet"
                    }
                }
                $APIResponse = $null
                $RetryCount = 0
            }
            Catch { 
                Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
            }

            $RetryCount--
        }
    }
)