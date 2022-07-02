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
File:           HiveOn.ps1
Version:        4.0.2.0
Version date:   02 July 2022
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $PoolsConfig.(Get-PoolBaseName $Name)

If ($PoolConfig.Wallets) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://hiveon.net/api/v1/stats/pool" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Request.cryptoCurrencies | Where-Object { $PoolConfig.Wallets.($_.Name) -and $Variables.Rates.($_.name).BTC } | ForEach-Object { 
        $Currency = "$($_.name)".Trim()
        $Algorithm_Norm = Get-Algorithm $Currency
        $Divisor = [Double]$_.profitPerPower
        $Workers = $Request.stats.($_.name).workers
        $_.Servers | ForEach-Object { $_.Region = $_.Region -replace 'all', 'n/a' }

        # Add coin name
        If ($_.title -and $Currency) { Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $_.title }

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ($Request.stats.($_.name).expectedReward24H * $Variables.Rates.($_.name).BTC / $Divisor) -FaultDetection $false

        ForEach ($Server in ($_.Servers | Where-Object { $_.Region -in $PoolConfig.Region -or  $_.Region -eq "n/a" } )) { 
            $Region_Norm = Get-Region $Server.Region

            [PSCustomObject]@{ 
                Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
                Algorithm                = [String]$Algorithm_Norm
                BaseName                 = [String]$Name
                Currency                 = [String]$Currency
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Fee                      = [Decimal]0
                Host                     = [String]$Server.host
                Name                     = [String]$PoolVariant
                Pass                     = "x"
                Port                     = [UInt16]$Server.ports[0]
                Price                    = [Double]$Stat.Live
                Region                   = [String]$Region_Norm
                SSL                      = $false
                StablePrice              = [Double]$Stat.Week
                Updated                  = [DateTime]$Stat.Updated
                User                     = "$($PoolConfig.Wallets.$Currency).$($PoolConfig.WorkerName)"
                Workers                  = [Int]$Workers
                WorkerName               = ""
            }
        }
    }
}
