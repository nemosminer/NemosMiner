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
File:           MiningDutch.ps1
Version:        4.2.0.0
Version date:   28 August 2022
#>

using module ..\Includes\Include.psm1

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$RetryCount = 3
$RetryDelay = 3 

$Headers = @{"Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8"}
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Config.MiningDutchAPIKey) { 

    Try { 
        $Config.PoolsConfig.$Name.PayoutCurrencies.Keys | ForEach-Object { 
            $Currency = $_
            $CoinName = $Config.PoolsConfig.$Name.PayoutCurrencies.$_

            $RetryCount2 = 3
            $APIResponse = $null

            While (-not ($APIResponse) -and $RetryCount2 -gt 0) { 
                $RetryCount2--
                Try { 
                    $APIResponse = ((Invoke-RestMethod "https://www.mining-dutch.nl/pools/$($CoinName.ToLower()).php?page=api&action=getuserbalance&api_key=$($Config.MiningDutchAPIKey)" -UserAgent $Useragent -Headers $Headers -UseBasicParsing -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore).getuserbalance).data

                    If ($Config.LogBalanceAPIResponse -eq $true) { 
                        @{ $Currency = $APIResponse }  | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name)_$($CoinName).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                    }
                }
                Catch { 
                    Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
                }
            }

            [PSCustomObject]@{ 
                DateTime        = (Get-Date).ToUniversalTime()
                Pool            = $Name
                Currency        = $Currency
                Wallet          = $Config.MiningDutchUserName
                Pending         = [Double]$APIResponse.unconfirmed
                Balance         = [Double]$APIResponse.confirmed
                Unpaid          = ([Double]$APIResponse.confirmed + [Double]$APIResponse.unconfirmed)
                Url             = "https://www.mining-dutch.nl//index.php?page=earnings"
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }

    $RetryCount--
}
