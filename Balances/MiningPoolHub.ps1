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
File:           \Balances\MiningPoolHub.ps1
Version:        5.0.2.4
Version date:   2023/12/20
#>

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$RetryInterval = $Config.PoolsConfig.$Name.PoolAPIRetryInterval
$PoolAPITimeout = $Config.PoolsConfig.$Name.PoolAPITimeout
$RetryCount = $Config.PoolsConfig.$Name.PoolAPIRetryInterval

$Headers = @{ "Cache-Control" = "no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While (-not $UserAllBalances -and $RetryCount -gt 0 -and $Config.MiningPoolHubAPIKey) { 
    Try { 
        $Url = "https://miningpoolhub.com/"
        $WebResponse = Invoke-WebRequest -Uri $Url -TimeoutSec $PoolAPITimeout -ErrorAction Ignore

        # PWSH 6+ no longer supports basic parsing -> parse text
        $CoinList = [System.Collections.Generic.List[PSCustomObject]]@()
        $InCoinList = $false

        If ($WebResponse.statuscode -eq 200) {
            ($WebResponse.Content -split "\n" -replace ' \s+' -replace ' $').ForEach(
                { 
                    If ($_ -like '<table id="coinList"*>') { 
                        $InCoinList = $true
                    }
                    If ($InCoinList) { 
                        If ($_ -like '</table>') { Return }
                        If ($_ -like '<td align="left"><a href="*') { 
                            $CoinList.Add($_ -replace '<td align="left"><a href="' -replace '" target="_blank">.+' -replace '^//' -replace '.miningpoolhub.com')
                        }
                    }
                }
            )
        }
        $CoinList = $CoinList | Sort-Object

        $UserAllBalances = ((Invoke-RestMethod "http://miningpoolhub.com/index.php?page=api&action=getuserallbalances&api_key=$($Config.MiningPoolHubAPIKey)" -Headers $Headers -TimeoutSec $PoolAPITimeout -ErrorAction Ignore).getuserallbalances).data | Where-Object { $_.confirmed -gt 0 -or $_.unconfirmed -gt 0 }

        If ($Config.LogBalanceAPIResponse) { 
            "$(([DateTime]::Now).ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $UserAllBalances | ConvertTo-Json -Depth 10 >> ".\Logs\BalanceAPIResponse_$Name.json"
        }

        If ($CoinList -and $UserAllBalances) { 
            $CoinList.ForEach(
                { 
                    $CoinBalance = $null
                    $RetryCount2 = $Config.PoolsConfig.$Name.PoolAPIRetryInterval

                    While (-not ($CoinBalance) -and $RetryCount2 -gt 0) { 
                        $RetryCount2--
                        Try { 
                            $CoinBalance = ((Invoke-RestMethod "http://$($_).miningpoolhub.com/index.php?page=api&action=getuserbalance&api_key=$($Config.MiningPoolHubAPIKey)" -Headers $Headers -UserAgent $UserAgent -TimeoutSec $PoolAPITimeout -ErrorAction Ignore).getuserbalance).data
                            If ($Config.LogBalanceAPIResponse) { 
                                $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\CoinBalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                            }
                        }
                        Catch { 
                            Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
                        }
                    }

                    If ($Balance = $UserAllBalances | Where-Object { $_.confirmed -eq $CoinBalance.confirmed -and $_.unconfirmed -eq $CoinBalance.unconfirmed }) { 
                        $Currency = ""
                        $RetryCount2 = $Config.PoolsConfig.$Name.PoolAPIRetryInterval
                        $PoolInfo = $null

                        While (-not ($PoolInfo) -and $RetryCount2 -gt 0) { 
                            $RetryCount2--
                            Try { 
                                $PoolInfo = ((Invoke-RestMethod "http://$($_).miningpoolhub.com/index.php?page=api&action=getpoolinfo&api_key=$($Config.MiningPoolHubAPIKey)" -Headers $Headers -UserAgent $UserAgent -TimeoutSec $PoolAPITimeout -ErrorAction Ignore).getpoolinfo).data
                                If ($Config.LogBalanceAPIResponse) { 
                                    $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
                                }
                                $Currency = $PoolInfo.currency
                            }
                            Catch { 
                                Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
                            }
                        }

                        If (-not $Currency) { 
                            Write-Message -Level Warn "$($Name): Cannot determine balance for currency '$(If ($_) { $_ }  Else { "unknown" } )' - cannot convert some balances to BTC or other currencies."
                        }
                        Else { 
                            # Prefer custom payout threshold
                            $PayoutThreshold = $Config.PoolsConfig.$Name.PayoutThreshold.$Currency

                            If ((-not $PayoutThreshold) -and $Currency -eq "BTC" -and $Config.PoolsConfig.$Name.PayoutThreshold.mBTC) { $PayoutThreshold = $Config.PoolsConfig.$Name.PayoutThreshold.mBTC / 1000 }
                            If (-not $PayoutThreshold) { $PayoutThreshold = $PoolInfo.min_ap_threshold }

                            [PSCustomObject]@{ 
                                DateTime        = ([DateTime]::Now).ToUniversalTime()
                                Pool            = $Name
                                Currency        = $Currency
                                Wallet          = $Config.MiningPoolHubUserName
                                Pending         = [Double]$CoinBalance.unconfirmed
                                Balance         = [Double]$CoinBalance.confirmed
                                Unpaid          = [Double]($CoinBalance.confirmed + $CoinBalance.unconfirmed)
                                # Total           = [Double]($CoinBalance.confirmed + $CoinBalance.unconfirmed + $CoinBalance.ae_confirmed + $CoinBalance.ae_unconfirmed + $CoinBalance.exchange)
                                PayoutThreshold = [Double]$PayoutThreshold
                                Url             = "https://$($_).miningpoolhub.com/index.php?page=account&action=pooledit"
                            }
                        }
                    }
                }
            )
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryInterval # Pool might not like immediate requests
    }

    $RetryCount--
}