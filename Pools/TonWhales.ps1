<#
Copyright (c) 2018-2022 Nemo, MrPlus & UselessGuru


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
File:           TonPool.ps1
Version:        4.0.0.39
Version date:   06 June 2022
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $PoolsConfig.(Get-PoolBaseName $Name)
$PriceField = $Variables.PoolData.$Name.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $Variables.PoolData.$Name.Variant.$PoolVariant.DivisorMultiplier
$PayoutCurrency = $PoolConfig.Wallets.Keys | Select-Object -First 1
$Wallet = $PoolConfig.Wallets.$PayoutCurrency

If ($DivisorMultiplier -and $PriceField -and $Wallet -and $Variables.Rates.BTC.TON) { 

    Try { 
        $Request = Invoke-RestMethod -Uri "https://ton-reports-24d2v.ondigitalocean.app/report/pool-profitability" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
    }
    Catch { Return }

    If (-not $Request) { Return }

    $HostSuffix = "whalestonpool.com"

    $Algorithm = "TonPoW"
    $Algorithm_Norm = Get-Algorithm $Algorithm
    $CoinName = "TonCoin"
    $Currency = "TON"
    $Divisor = $DivisorMultiplier * $Variables.Rates.BTC.TON
    $Fee = 0
    $PoolPort = 4001

    # Add coin name
    If ($CoinName -and $Currency -and -not (Get-CoinName $Currency)) { 
        Add-CoinName -Currency $Currency -CoinName $CoinName
    }

    $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$PriceField / $Divisor) -FaultDetection $false

    ForEach ($Region in $PoolConfig.Region) { 
        $Region_Norm = Get-Region $Region

        [PSCustomObject]@{ 
            Name                     = [String]$PoolVariant
            BaseName                 = [String]$Name
            Algorithm                = [String]$Algorithm_Norm
            Currency                 = [String]$Currency
            Price                    = [Double]$Stat.Live
            StablePrice              = [Double]$Stat.Week
            Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
            EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
            Host                     = $HostSuffix
            Port                     = [UInt16]$PoolPort
            User                     = [String]$Wallet
            Pass                     = "x"
            Region                   = [String]$Region_Norm
            SSL                      = $true
            Fee                      = [Decimal]$Fee
            Updated                  = [DateTime]$Stat.Updated
        }
    }
}
