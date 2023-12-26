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
File:           \Balances\MiningDutch.ps1
Version:        5.0.2.5
Version date:   2023/12/20
#>

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIRetryInterval
$PoolAPITimeout = $Config.PoolsConfig.$Name.PoolAPITimeout
$RetryCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount

$Headers = @{"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"}
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Config.MiningDutchAPIKey) { 

    Try { 
        (Invoke-RestMethod "https://www.mining-dutch.nl/api/v1/public/pooldata/?method=poolstats&algorithm=all&id=$($Config.MiningDutchUserName)" -UserAgent $Useragent -Headers $Headers -TimeoutSec $PoolAPITimeout -ErrorAction Ignore).result.Where({ $_.tag -notlike "*_*" }).ForEach(
            { 
                $RetryCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount
                $Currency = $_.tag
                $CoinName = $_.currency

                $APIResponse = $null
                While (-not $APIResponse -and $RetryCount -gt 0) { 
                    Try { 
                        If ($APIResponse = ((Invoke-RestMethod "https://www.mining-dutch.nl/pools/$($CoinName.ToLower()).php?page=api&action=getuserbalance&api_key=$($Config.MiningDutchAPIKey)" -UserAgent $Useragent -Headers $Headers -TimeoutSec $PoolAPITimeout -ErrorAction Ignore).getuserbalance).data) { 
                            $RetryCount = $Config.PoolsConfig.$Name.PoolAPIAllowedFailureCount

                            If ($Config.LogBalanceAPIResponse) { 
                                "$(([DateTime]::Now).ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                                $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                                $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                            }

                            [PSCustomObject]@{ 
                                DateTime        = ([DateTime]::Now).ToUniversalTime()
                                Pool            = $Name
                                Currency        = $Currency
                                Wallet          = $Config.MiningDutchUserName
                                Pending         = [Double]$APIResponse.unconfirmed
                                Balance         = [Double]$APIResponse.confirmed
                                Unpaid          = [Double]$APIResponse.confirmed + [Double]$APIResponse.unconfirmed
                                Url             = "https://www.mining-dutch.nl//index.php?page=earnings"
                            }
                        }
                    }
                    Catch { 
                        $RetryCount--
                        Start-Sleep -Seconds $Config.PoolsConfig.$Name.PoolAPIRetryInterval # Pool might not like immediate requests
                    }
                }
            }
        )
    }
    Catch { 
        $RetryCount--
        Start-Sleep -Seconds $Config.PoolsConfig.$Name.PoolAPIRetryInterval # Pool might not like immediate requests
    }

    $RetryCount--
}