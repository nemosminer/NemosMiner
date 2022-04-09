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
Version:        4.0.0.25
Version date:   09 April 2022
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
        $Request = Invoke-RestMethod -Uri "https://next.ton-pool.com/stats" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
    }
    Catch { Return }

    If (-not $Request) { Return }

    $HostSuffix = "1.stratum.ton-pool.com/stratum"

    $Algorithm = "TonPoW"
    $Algorithm_Norm = Get-Algorithm $Algorithm
    $CoinName = "TonCoin"
    $Currency = "TON"
    $Divisor = $DivisorMultiplier * $Variables.Rates.BTC.TON
    $Fee = 0.05
    $PoolPort = 443

    # Add coin name to ".\Data\CoinNames.json"
    If ($CoinName -and -not (Get-CoinName $Currency)) { 
        $Global:CoinNames | Add-Member $Currency "$($CoinName)".Trim() -Force
        $Global:CoinNames | Get-SortedObject | ConvertTo-Json | Out-File ".\Data\CoinNames.json" -Encoding utf8NoBOM -Force
    }

    $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.income.$PriceField / $Divisor) -FaultDetection $false

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
            Host                     = "$($Region)$($HostSuffix)"
            Port                     = [UInt16]$PoolPort
            User                     = [String]$Wallet
            Pass                     = "x"
            Region                   = [String]$Region_Norm
            SSL                      = $true
            Fee                      = [Decimal]$Fee
            EstimateFactor           = [Decimal]1
            Updated                  = [DateTime]$Stat.Updated
        }
    }
}
