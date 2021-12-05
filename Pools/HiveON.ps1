<#
Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru


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
Version:        4.0.0.7 (RC7)
Version date:   05 December 2021
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Name_Norm = $Name -replace "24hr$|Coins$|Plus$|CoinsPlus$"
$PoolConfig = $PoolsConfig.$Name_Norm

If ($Config.Wallets) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://hiveon.net/api/v1/stats/pool" -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" } -TimeoutSec $Config.PoolTimeout
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Request.cryptoCurrencies | Where-Object { $Config.Wallets.($_.Name) } | ForEach-Object { 

        $Currency = $_.name
        $Algorithm_Norm = Get-Algorithm $Currency

        $Divisor = [Double]$_.profitPerPower

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.stats.$Currency.expectedReward24H * $Variables.Rates.$Currency.BTC / $Divisor) -FaultDetection $false

        Try { $EstimateFactor = [Decimal]($Request.stats.$Currency.expectedReward24H / $Request.stats.$Currency.meanExpectedReward24H) }
        Catch { $EstimateFactor = 1 }

        ForEach ($Server in ($_.Servers | Where-Object { $_.Region -in $PoolConfig.Region } )) {
            $Region_Norm = Get-Region $Server.Region

            [PSCustomObject]@{ 
                Algorithm                = [String]$Algorithm_Norm
                Currency                 = [String]$Currency
                Price                    = [Double]$Stat.Live
                StablePrice              = [Double]$Stat.Week
                MarginOfError            = [Double]$Stat.Week_Fluctuation
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Host                     = [String]$Server.host
                Port                     = [UInt16]$Server.ports[0]
                User                     = "$($Config.Wallets.$Currency).$($PoolConfig.WorkerName)"
                Pass                     = "x"
                Region                   = [String]$Region_Norm
                SSL                      = [Boolean]$false
                Fee                      = [Decimal]0
                EstimateFactor           = [Decimal]$EstimateFactor
            }
        }
    }
}
