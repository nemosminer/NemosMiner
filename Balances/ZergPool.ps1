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
File:           ZergPool.ps1
Version:        4.0.0.12 (RC12)
Version date:   01 January 2022
#>

using module ..\Includes\Include.psm1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PayoutCurrency = $Config.PoolsConfig.$Name.Wallets | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Select-Object -Index 0
$Wallet = $Config.PoolsConfig.$Name.Wallets.$PayoutCurrency
$Url = "http://zergpool.com/?address=$Wallet"

$RetryCount = 3
$RetryDelay = 10
While (-not ($APIResponse) -and $RetryCount -gt 0 -and $Wallet) { 
    $RetryCount--
    Try { 
        $APIResponse = Invoke-RestMethod "http://www.zergpool.com:8080/api/wallet?address=$Wallet" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop

        If ($Config.LogBalanceAPIResponse -eq $true) { 
            $APIResponse | Add-Member DateTime ((Get-Date).ToUniversalTime()) -Force
            $APIResponse | ConvertTo-Json -Depth 10 >> ".\Logs\BalanceAPIResponse_$($Name).json"
        }

        If ($APIResponse.currency) { 
            [PSCustomObject]@{ 
                DateTime        = (Get-Date).ToUniversalTime()
                Pool            = $Name
                Currency        = $APIResponse.Currency
                Wallet          = $Wallet
                Pending         = [Double]$APIResponse.Unsold
                Balance         = [Double]$APIResponse.Balance
                Unpaid          = [Double]$APIResponse.Unpaid
                # Paid            = [Double]$APIResponse.PaidTotal
                # Total           = [Double]$APIResponse.Unpaid + [Double]$APIResponse.PaidTotal
                PayoutThreshold = [Double]($(If ($Config.PoolsConfig.$Name.PayoutThreshold.$PayoutCurrency -gt $APIResponse.MinPay) { $Config.PoolsConfig.$Name.PayoutThreshold.$PayoutCurrency } Else { $APIResponse.MinPay } ))
                Url             = $Url
            }
        }
    }
    Catch { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }
}
