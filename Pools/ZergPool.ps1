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
File:           ZergPool.ps1
Version:        4.0.1.3
Version date:   28 June 2022
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
$Regions = If ($Config.UseAnycast -and $PoolConfig.Region -contains "n/a (Anycast)") { "n/a (Anycast)" } Else { $PoolConfig.Region | Where-Object { $_ -ne "n/a (Anycast)" }  }
$Wallet = $PoolConfig.Wallets.$PayoutCurrency

If ($DivisorMultiplier -and $Regions -and $Wallet) {

    $PayoutThreshold = $PoolConfig.PayoutThreshold.$PayoutCurrency
    If (-not $PayoutThreshold -and $PoolConfig.PayoutThreshold.mBTC) { $PayoutThreshold = $PoolConfig.PayoutThreshold.mBTC / 1000 }
    $PayoutThresholdParameter = ",pl=$([Double]$PayoutThreshold)"

    Try { 
        $Request = Get-Content ((Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Brains\$($Name)\$($Name).json") -ErrorAction Stop | ConvertFrom-Json
    }
    Catch { Return }

    If (-not $Request) { Return }

    $HostSuffix = "mine.zergpool.com"

    $Request.PSObject.Properties.Name | Where-Object { [Double]$Request.$_.$PriceField -gt 0 } | Where-Object { $Request.$_.noautotrade -ne 1 -or $PayoutCurrency -eq "$($Request.$_.currency)".Trim() } | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$_.currency)".Trim()
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = $Request.$_.Fees / 100
        $PoolPort = $Request.$_.port
        $Updated = $Request.$_.Updated
        $Workers = $Request.$_.workers

        # Add coin name
        If ($Request.$_.CoinName -and $Currency -and -not (Get-CoinName $Currency)) { 
            Add-CoinName -Currency $Currency -CoinName $Request.$_.CoinName
        }

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor) -FaultDetection $false

        ForEach ($Region in $Regions) { 

            $PoolHost = If ($Region -eq "n/a (Anycast)") { "$Algorithm.$HostSuffix" } Else { "$Algorithm.$Region.$HostSuffix" }

            [PSCustomObject]@{ 
                Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
                Algorithm                = [String]$Algorithm_Norm
                BaseName                 = [String]$Name
                Currency                 = [String]$Currency
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Fee                      = [Decimal]$Fee
                Host                     = [String]$PoolHost
                Name                     = [String]$PoolVariant
                Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency$PayoutThresholdParameter"
                Port                     = [UInt16]$PoolPort
                Price                    = [Double]$Stat.Live
                Region                   = "$(Get-Region $Region)"
                SSL                      = $false
                StablePrice              = [Double]$Stat.Week
                Updated                  = [DateTime]$Updated
                User                     = [String]$Wallet
                Workers                  = [Int]$Workers
                WorkerName               = ""
            }
        }
    }
}
