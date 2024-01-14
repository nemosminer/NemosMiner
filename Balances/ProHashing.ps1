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
File:           \Balances\ProHashing.ps1
Version:        5.0.2.6
Version date:   2023/12/28
#>

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Url = "https://prohashing.com/customer/dashboard"

$RetryCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount
$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIRetryInterval

$Request = "https://prohashing.com/api/v1/wallet?apiKey=$($Config.ProHashingAPIKey)"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Config.ProHashingAPIKey) { 

    Try { 
        $APIResponse = Invoke-RestMethod $Request -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore

        If ($Config.LogBalanceAPIResponse) { 
            "$(([DateTime]::Now).ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }

        If ($APIResponse.status -eq "success") { 
            If (($APIResponse.data.balances | Get-Member -MemberType NoteProperty).Name) { 
                ($APIResponse.data.balances | Get-Member -MemberType NoteProperty).Name.ForEach(
                    { 
                        [PSCustomObject]@{ 
                            DateTime = ([DateTime]::Now).ToUniversalTime()
                            Pool            = $Name
                            Currency        = $APIResponse.data.balances.$_.abbreviation
                            Wallet          = $Config.ProHashingUserName
                            Pending         = 0
                            Balance         = [Double]$APIResponse.data.balances.$_.balance
                            Unpaid          = [Double]$APIResponse.data.balances.$_.unpaid
                            Paid            = [Double]$APIResponse.data.balances.$_.paid24h
                            PayoutThreshold = [Double]$APIResponse.data.balances.$_.payoutThreshold
                            # Total           = [Double]$APIResponse.data.balances.$_.total # total unpaid + total paid, reset after payout
                            Url             = $Url
                        }
                    }
                )
            }
            Else { 
                # Remove non present (paid) balances
                $Variables.BalancesData = $Variables.BalancesData.Where({ $_.Pool -ne $Name })
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $Retryinterval # Pool might not like immediate requests
    }

    $RetryCount--
}