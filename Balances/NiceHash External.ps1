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
File:           NiceHash Internal.ps1
Version:        4.2.2.0
Version date:   09 October 2022
#>

using module ..\Includes\Include.psm1

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PayoutCurrency = $Config.PoolsConfig.NiceHash.Variant.$Name.PayoutCurrency
$Wallet = $Config.PoolsConfig.NiceHash.Variant.$Name.Wallets.$PayoutCurrency
$RetryCount = 3
$RetryDelay = 3

$Request = "https://api2.nicehash.com/main/api/v2/mining/external/$($Wallet)/rigs2"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Wallet) { 

    Try { 
        $APIResponse = Invoke-RestMethod $Request -UseBasicParsing -TimeoutSec $Config.PoolAPITimeout -ErrorAction Ignore

        If ($Config.LogBalanceAPIResponse -eq $true) { 
            "$((Get-Date).ToUniversalTime())" | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            $Request | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        }

        $Sum = [Double]($APIResponse.unpaidAmount) + [Double]($APIResponse.externalBalance)

        If ($Sum -gt 0) { 
            Return [PSCustomObject]@{ 
                DateTime   = (Get-Date).ToUniversalTime()
                Pool       = $Name
                Currency   = $PayoutCurrency
                Wallet     = $($Wallet)
                Pending    = [Double]($APIResponse.unpaidAmount)
                Balance    = [Double]($APIResponse.externalBalance)
                Unpaid     = $Sum
                #Total      = $Sum
                Url        = "https://www.nicehash.com/my/miner/$Wallet"
                NextPayout = $APIResponse.NextPayoutTimeStamp
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }

    $RetryCount--
}
