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
File:           MiningPoolHub.ps1
Version:        4.3.1.0
Version date:   02 March 2023
#>
using module ..\Includes\Include.psm1

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$RetryCount = 3
$RetryDelay = 3

$Headers = @{ "Cache-Control" = "no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Config.MiningPoolHubAPIKey) { 

    Try { 

        $Url = "https://miningpoolhub.com/"
        $WebResponse = Invoke-WebRequest -Uri $Url -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore

        # PWSH 6+ no longer supports basic parsing -> parse text
        $CoinList = @()
        $InCoinList = $false

        If ($WebResponse.statuscode -eq 200) {
            ($WebResponse.Content -split "\n").Trim() | ForEach-Object { 
                If ($_ -like '<table id="coinList"*>') { 
                    $InCoinList = $true
                }
                If ($InCoinList) { 
                    If ($_ -like '</table>') { Return }
                    If ($_ -like '<td align="left"><a href="*') { 
                        $CoinList += $_ -replace '<td align="left"><a href="' -replace '" target="_blank">.+' -replace "^//" -replace ".miningpoolhub.com"
                    }
                }
            }
        }

        $GetUserAllBalances = ((Invoke-RestMethod "http://miningpoolhub.com/index.php?page=api&action=getuserallbalances&api_key=$($Config.MiningPoolHubAPIKey)" -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore).getuserallbalances).data | Where-Object { $_.confirmed -gt 0 -or $_.unconfirmed -gt 0 }

        If ($Config.LogBalanceAPIResponse) { 
            "$((Get-Date).ToUniversalTime())" | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            $Request | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            $APIResponse | ConvertTo-Json -Depth 10 >> ".\Logs\BalanceAPIResponse_$($Name).json"
        }

        If ($CoinList -and $GetUserAllBalances) { 
            $CoinList | ForEach-Object { 

                $CoinBalance = $null
                $RetryCount2 = 3

                While (-not ($CoinBalance) -and $RetryCount2 -gt 0) { 
                    $RetryCount2--
                    Try { 
                        $CoinBalance = ((Invoke-RestMethod "http://$($_).miningpoolhub.com/index.php?page=api&action=getuserbalance&api_key=$($Config.MiningPoolHubAPIKey)" -Headers $Headers -UserAgent $UserAgent -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore).getuserbalance).data

                        If ($Config.LogBalanceAPIResponse) { 
                            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Logs\CoinBalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                        }
                    }
                    Catch { 
                        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
                    }
                }

                If ($Balance = $GetUserAllBalances | Where-Object { $_.confirmed -eq $CoinBalance.confirmed -and $_.unconfirmed -eq $CoinBalance.unconfirmed }) { 
                    $Currency = ""
                    $RetryCount2 = 3
                    $GetPoolInfo = $null

                    While (-not ($GetPoolInfo) -and $RetryCount2 -gt 0) { 
                        $RetryCount2--
                        Try { 
                            $GetPoolInfo = ((Invoke-RestMethod "http://$($_).miningpoolhub.com/index.php?page=api&action=getpoolinfo&api_key=$($Config.MiningPoolHubAPIKey)" -Headers $Headers -UserAgent $UserAgent -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore).getpoolinfo).data

                            If ($Config.LogBalanceAPIResponse) { 
                                $APIResponse | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                            }
                            $Currency = $GetPoolInfo.currency
                        }
                        Catch { 
                            Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
                        }
                    }

                    If (-not $Currency) { 
                        Write-Message -Level Warn "Cannot determine balance for currency ($(If ($_) { $_ }  Else { "unknown" } )) - cannot convert some balances to BTC or other currencies."
                    }
                    Else { 
                        # Prefer custom payout threshold
                        $PayoutThreshold = $Config.PoolsConfig.$Name.PayoutThreshold.$Currency

                        If ((-not $PayoutThreshold) -and $Currency -eq "BTC" -and $Config.PoolsConfig.$Name.PayoutThreshold.mBTC) { $PayoutThreshold = $Config.PoolsConfig.$Name.PayoutThreshold.mBTC / 1000 }
                        If (-not $PayoutThreshold) { $PayoutThreshold = $GetPoolInfo.min_ap_threshold }

                        [PSCustomObject]@{ 
                            DateTime        = (Get-Date).ToUniversalTime()
                            Pool            = "$Name"
                            Currency        = $Currency
                            Wallet          = $Config.MiningPoolHubUserName
                            Pending         = [Double]$Balance.unconfirmed
                            Balance         = [Double]$Balance.confirmed
                            Unpaid          = [Double]($Balance.confirmed + $Balance.unconfirmed)
                            # Total           = [Double]($Balance.confirmed + $Balance.unconfirmed + $Balance.ae_confirmed + $Balance.ae_unconfirmed + $Balance.exchange)
                            PayoutThreshold = [Double]$PayoutThreshold
                            Url             = "https://$($_).miningpoolhub.com/index.php?page=account&action=pooledit"
                        }
                    }
                }
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }

    $RetryCount--
}
