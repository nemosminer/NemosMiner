<#
Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru

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
Version:        3.9.9.25
Version date:   14 March 2021
#>

using module ..\Includes\Include.psm1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName

If (-not $Config.MiningPoolHubAPIKey) { 
    Write-Message -Level Verbose "Cannot get balance on pool ($Name) - no API key specified."
    Return
}

$RetryCount = 3
$RetryDelay = 2
While (-not ($APIResponse) -and $RetryCount -gt 0) { 
    Try { 
        If (-not $APIResponse) { $APIResponse = Invoke-RestMethod "http://miningpoolhub.com/index.php?page=api&action=getuserallbalances&api_key=$($Config.MiningPoolHubAPIKey)" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop} 
    }
    Catch { }
    If (-not $APIResponse) { 
        Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
        $RetryCount--
    }
}

If (-not $APIResponse) { 
    Return
}

If (($APIResponse.getuserallbalances.data | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) { 
    Return
}

$APIResponse.getuserallbalances.data | Where-Object coin | Where-Object confirmed -gt 0 | ForEach-Object { 
    $Currency = ""
    $RetryCount = 3
    $RetryDelay = 2
    while (-not ($Currency) -and $RetryCount -gt 0) { 
        Try { 
            $Currency = Invoke-RestMethod "http://$($_.coin).miningpoolhub.com/index.php?page=api&action=getpoolinfo&api_key=$($Config.MiningPoolHubAPIKey)" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop | Select-Object -ExpandProperty getpoolinfo | Select-Object -ExpandProperty data | Select-Object -ExpandProperty currency
        }
        Catch { 
            Start-Sleep -Seconds $RetryDelay # Pool might not like immediate requests
        }
        $RetryCount--
    }

    If (-not $Currency) { 
        Write-Message -Level Warn "Cannot determine balance for currency ($(If ($_.coin) { $_.coin }  Else { "unknown"} )) - cannot convert some balances to BTC or other currencies."
    }
    Else { 
        [PSCustomObject]@{ 
            DateTime = (Get-Date).ToUniversalTime()
            Pool     = "$Name"
            Currency = $Currency
            Wallet   = $Config.MiningPoolHubUserName
            Pending  = [Double]($_.unconfirmed)
            Balance  = [Double]($_.confirmed)
            Unpaid   = [Double]($_.confirmed + $_.unconfirmed)
            # Total    = [Double]($_.confirmed + $_.unconfirmed + $_.ae_confirmed + $_.ae_unconfirmed + $_.exchange)
            Url      = "https://$($_.coin).miningpoolhub.com/index.php?page=account&action=pooledit"
        }
    }
}
