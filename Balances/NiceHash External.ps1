<#
Copyright (c) 2018-2020 Nemo, MrPlus & UselessGuru

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
Version:        3.9.9.20
Version date:   21 February 2021
#>

using module ..\Includes\Include.psm1

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$Url = "https://www.nicehash.com/my/miner/"

Try {
    # NiceHash External balance
    If ($Config.PoolsConfig.NiceHash.NiceHashWalletIsInternal -eq $true) { 
        $Wallet = $Config.Wallet
    }
    Else { 
        $Wallet = $Config.PoolsConfig.NiceHash.Wallet
    }

    $APIResponse = Invoke-RestMethod "https://api2.nicehash.com/main/api/v2/mining/external/$($Wallet)/rigs2" -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
    $Sum = [Double]($APIResponse.unpaidAmount) + [Double]($APIResponse.externalBalance)

    If ($Sum -gt 0) { 
        [PSCustomObject]@{ 
            DateTime   = (Get-Date).ToUniversalTime()
            Pool       = "NiceHash External"
            Currency   = "BTC"
            Wallet     = $($Wallet)
            Pending    = [Double]($APIResponse.unpaidAmount)
            Balance    = [Double]($APIResponse.externalBalance)
            Unpaid     = $Sum
            #Total      = $Sum
            Url        = "$($Url)$($Wallet)"
            NextPayout = $APIResponse.NextPayoutTimeStamp
        }
    }
}
Catch { }
