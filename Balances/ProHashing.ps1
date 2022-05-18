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
File:           ProHashing.ps1
Version:        4.0.0.33
Version date:   18 May 2022
#>

using module ..\Includes\Include.psm1

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Url = "https://prohashing.com/customer/dashboard"

$RetryCount = 3
$RetryDelay = 15

$Request = "https://prohashing.com/api/v1/wallet?apiKey=$($Config.ProHashingAPIKey)"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Config.ProHashingAPIKey) { 

    $APIResponse = Invoke-RestMethod $Request -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop

    If ($Config.LogBalanceAPIResponse -eq $true) { 
        "$((Get-Date).ToUniversalTime())" | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        $Request | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        $APIResponse | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    }

    If ($APIResponse.status -eq "success") { 
        ($APIResponse.data.balances | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
            If ($APIResponse.data.balances.$_.balance -gt 0) { 
                [PSCustomObject]@{ 
                    DateTime = (Get-Date).ToUniversalTime()
                    Pool     = $Name
                    Currency = $APIResponse.data.balances.$_.abbreviation
                    Wallet   = $Config.ProHashingUserName
                    Pending  = 0
                    Balance  = [Double]($APIResponse.data.balances.$_.balance)
                    Unpaid   = [Double]($APIResponse.data.balances.$_.Unpaid)
                    Paid     = [Double]($APIResponse.data.balances.$_.paid24h)
                    # Total    = [Double]($APIResponse.data.balances.$_.total) # total unpaid + total paid, reset after payout
                    Url      = $Url
                }
            }
        }
    }
    Else { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }

    $RetryCount--
}
