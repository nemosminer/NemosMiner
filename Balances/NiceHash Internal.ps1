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
Version:        4.0.0.25
Version date:   09 April 2022
#>

using module ..\Includes\Include.psm1

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PayoutCurrency = $Config.PoolsConfig.NiceHash.Variant.$Name.PayoutCurrency
$Wallet = $Config.PoolsConfig.NiceHash.Variant.$Name.Wallets.$PayoutCurrency
$Key = $Config.NiceHashAPIKey
$OrganizationID = $Config.NiceHashOrganizationID
$Secret = $Config.NiceHashAPISecret
$Url = "https://www.nicehash.com/my/mining/rigs/$($Config.PoolsConfig.NiceHash.WorkerName)"

Function Get-NiceHashRequest { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$EndPoint = "", 
        [Parameter(Mandatory = $true)]
        [String]$Method = "",
        [Parameter(Mandatory = $true)]
        [String]$Key = "",
        [Parameter(Mandatory = $true)]
        [String]$OrganizationID = "",
        [Parameter(Mandatory = $true)]
        [String]$Secret = ""
    )

    $Uuid = [String]([guid]::NewGuid())
    $Timestamp = ([DateTimeOffset](Get-Date).ToUniversalTime()).ToUnixTimeMilliseconds()

    $Str = "$Key`0$Timestamp`0$Uuid`0`0$Organizationid`0`0$($Method.ToUpper())`0$Endpoint`0extendedResponse=true"
    $Sha = [System.Security.Cryptography.KeyedHashAlgorithm]::Create("HMACSHA256")
    $Sha.Key = [System.Text.Encoding]::UTF8.Getbytes($Secret)
    $Sign = [System.BitConverter]::ToString($Sha.ComputeHash([System.Text.Encoding]::UTF8.Getbytes(${str})))
    $Headers = [Hashtable]@{ 
        "X-Time"            = $Timestamp
        "X-Nonce"           = $Uuid
        "X-Organization-Id" = $OrganizationId
        "X-Auth"            = "$($Key):$(($Sign -replace '\-').ToLower())"
        "Cache-Control"     = "no-cache"
    }
    Return Invoke-RestMethod "https://api2.nicehash.com$($EndPoint)?extendedResponse=true" -TimeoutSec 5 -ErrorAction Stop -Method $Method -Headers $Headers
}

$RetryCount = 3
$RetryDelay = 15

$Method = "GET"
$EndPoint = "/main/api/v2/accounting/account2/BTC/"

$Request = "https://api2.nicehash.com$($EndPoint)?extendedResponse=true"

While (-not $APIResponse -and $RetryCount -gt 0 -and $Config.NiceHashAPIKey -and $Config.NiceHashAPISecret -and $Config.NiceHashOrganizationID) { 

    $APIResponse = Get-NiceHashRequest -EndPoint $EndPoint -Method $Method -Key $Key -OrganizationID $OrganizationID -Secret $Secret

    If ($Config.LogBalanceAPIResponse -eq $true) { 
        "$((Get-Date).ToUniversalTime())" | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        $Request | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        $APIResponse | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Logs\BalanceAPIResponse_$($Name).json" -Append -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    }

    If ($APIResponse.active) { 
        [PSCustomObject]@{ 
            DateTime   = (Get-Date).ToUniversalTime()
            Pool       = $Name
            Currency   = $PayoutCurrency
            Wallet     = $Wallet
            Pending    = [Double]($APIResponse.pending)
            Balance    = [Double]($APIResponse.available)
            Unpaid     = [Double]($APIResponse.totalBalance)
            Withdrawal = [Double]($APIResponse.pendingDetails.withdrawal)
            #Total      = [Double]($APIResponse.pendingDetails.totalBalance)
            Url        = $Url
        }
    }
    Else { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
    }

    $RetryCount--
}
