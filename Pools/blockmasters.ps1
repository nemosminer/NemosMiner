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
File:           Blockmasters.ps1
Version:        4.0.0.29
Version date:   07 May 2022
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

If ($DivisorMultiplier -and $PriceField -and $Wallet) { 

    Try { 
        $Request = Get-Content ((Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Brains\$($Name)\$($Name).json") -ErrorAction Stop | ConvertFrom-Json
    }
    Catch { Return }

    If (-not $Request) { Return }

    $HostSuffix = "blockmasters.co"

    $Request.PSObject.Properties.Name | Where-Object { $Request.$_.$PriceField -gt 0 } | ForEach-Object { 
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
                Host                     = "$($Region).$($HostSuffix)" -replace "^us\."
                Port                     = [UInt16]$PoolPort
                User                     = [String]$Wallet
                Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency"
                Region                   = [String]$Region_Norm
                SSL                      = $false
                Fee                      = [Decimal]$Fee
                Updated                  = [DateTime]$Updated
                Workers                  = [Int]$Workers
            }
        }
    }
}
