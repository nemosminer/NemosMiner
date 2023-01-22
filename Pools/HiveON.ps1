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
Version:        4.2.3.5
Version date:   22 January 2023
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $Variables.PoolsConfig.$Name

If ($PoolConfig.Wallets) { 
    Do {
        Try { 
            $Request = Invoke-RestMethod -Uri "https://hiveon.net/api/v1/stats/pool" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec 3
        }
        Catch { 
            $APICallFails++
            Start-Sleep -Seconds ($APICallFails * 3)
        }
    } While (-not $Request -and $APICallFails -lt 3)

    If (-not $Request) { Return }

    $Request.cryptoCurrencies | Where-Object { $PoolConfig.Wallets.($_.Name) -and $Variables.Rates.($_.name).BTC } | ForEach-Object { 
        $Currency = "$($_.name)".Trim()
        $Algorithm_Norm = Get-Algorithm $Currency
        $Divisor = [Double]$_.profitPerPower

        # Add coin name
        If ($_.title -and $Currency) { 
            $CoinName = $_.title
            Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $CoinName
        }
        Else { 
            $CoinName = ""
        }

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ($Request.stats.($_.name).expectedReward24H * $Variables.Rates.($_.name).BTC / $Divisor) -FaultDetection $false

        [PSCustomObject]@{ 
            Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
            Algorithm                = [String]$Algorithm_Norm
            BaseName                 = [String]$Name
            CoinName                 = [String]$CoinName
            Currency                 = [String]$Currency
            Disabled                 = [Boolean]$Stat.Disabled
            EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
            Fee                      = 0
            Host                     = [String]$_.servers[0].host
            Name                     = [String]$PoolVariant
            Pass                     = "x"
            Port                     = If ($PoolConfig.SSL -eq "Always") { 0 } Else { [UInt16]$_.servers[0].ports[0] }
            PortSSL                  = If ($PoolConfig.SSL -eq "Never") { 0 } Else { [UInt16]$_.servers[0].ssl_ports[0] }
            Price                    = [Double]$Stat.Live
            Region                   = [String]$PoolConfig.Region
            StablePrice              = [Double]$Stat.Week
            Updated                  = [DateTime]$Stat.Updated
            User                     = "$($PoolConfig.Wallets.$Currency).$($PoolConfig.WorkerName)"
            Workers                  = [Int]$Request.stats.($_.name).workers
            WorkerName               = ""
        }
    }
}
