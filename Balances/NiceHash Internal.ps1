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
$Wallet = $PoolConfig.Variant.$Name.Wallets.$PayoutCurrency
$Key = $Config.NiceHashAPIKey
$OrganizationID = $Config.NiceHashOrganizationID
$Secret = $Config.NiceHashAPISecret

$RetryCount = $PoolConfig.PoolAPIAllowedFailureCount
$RetryInterval = $PoolConfig.PoolAPIRetryInterval

Function Get-NiceHashRequest { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$EndPoint, 
        [Parameter(Mandatory = $true)]
        [String]$Method,
        [Parameter(Mandatory = $true)]
        [String]$Key,
        [Parameter(Mandatory = $true)]
        [String]$OrganizationID,
        [Parameter(Mandatory = $true)]
        [String]$Secret
    )

    $Uuid = [String]([guid]::NewGuid())
    $Timestamp = ([DateTimeOffset]([DateTime]::Now).ToUniversalTime()).ToUnixTimeMilliseconds()

    $Str = "$Key`0$Timestamp`0$Uuid`0`0$Organizationid`0`0$($Method.ToUpper())`0$Endpoint`0extendedResponse=true"
    $Sha = [System.Security.Cryptography.KeyedHashAlgorithm]::Create("HMACSHA256")
    $Sha.Key = [System.Text.Encoding]::UTF8.Getbytes($Secret)
    $Sign = [System.BitConverter]::ToString($Sha.ComputeHash([System.Text.Encoding]::UTF8.Getbytes($str)))
    $Headers = [Hashtable]@{ 
        "X-Time"            = $Timestamp
        "X-Nonce"           = $Uuid
        "X-Organization-Id" = $OrganizationId
        "X-Auth"            = "$($Key):$(($Sign -replace '\-').ToLower())"
        "Cache-Control"     = "no-cache"
    }
    Return Invoke-RestMethod "https://api2.nicehash.com$($EndPoint)?extendedResponse=true" -TimeoutSec $Config.PoolAPITimeout -ErrorAction Stop -Method $Method -Headers $Headers
}

$Method = "GET"
$EndPoint = "/main/api/v2/accounting/account2/BTC/"

$Request = "https://api2.nicehash.com$($EndPoint)?extendedResponse=true"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Config.NiceHashAPIKey -and $Config.NiceHashAPISecret -and $Config.NiceHashOrganizationID) { 

    Try { 
        $APIResponse = Get-NiceHashRequest -EndPoint $EndPoint -Method $Method -Key $Key -OrganizationID $OrganizationID -Secret $Secret

        If ($Config.LogBalanceAPIResponse) { 
            "$(([DateTime]::Now).ToUniversalTime())" | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $Request | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
            $APIResponse | ConvertTo-Json -Depth 10 | Out-File -LiteralPath ".\Logs\BalanceAPIResponse_$Name.json" -Append -Force -ErrorAction Ignore
        }

        If ($APIResponse.active) { 
            Return [PSCustomObject]@{ 
                DateTime   = ([DateTime]::Now).ToUniversalTime()
                Pool       = $Name
                Currency   = $PayoutCurrency
                Wallet     = $Wallet
                Pending    = [Double]$APIResponse.pending
                Balance    = [Double]$APIResponse.available
                Unpaid     = [Double]$APIResponse.totalBalance
                Withdrawal = [Double]$APIResponse.pendingDetails.withdrawal
                #Total      = [Double]$APIResponse.pendingDetails.totalBalance
                Url        = "https://www.nicehash.com/my/mining/rigs/$($PoolConfig.WorkerName)"
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