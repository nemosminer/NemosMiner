<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru


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
File:           \Pools\Hiveon.ps1
Version:        5.0.2.5
Version date:   2023/12/20
#>

param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolConfig = $Variables.PoolsConfig.$Name

If ($PoolConfig.Wallets) { 

    $APICallFails = 0

    Do {
        Try { 
            $Request = Invoke-RestMethod -Uri "https://Hiveon.net/api/v1/stats/pool" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPITimeout
        }
        Catch { 
            $APICallFails ++
            Start-Sleep -Seconds ($APICallFails * $PoolConfig.PoolAPIRetryInterval)
        }
    } While (-not $Request -and $APICallFails -lt 3)

    If (-not $Request) { Return }

    ForEach ($Pool in $Request.cryptoCurrencies.Where({ $Variables.Rates.($_.name).BTC })) { 
        $Currency = $Pool.name -replace ' \s+'
        If ($Algorithm_Norm = Get-AlgorithmFromCurrency $Currency) { 
            $Divisor = [Double]$Pool.profitPerPower

            # Add coin name
            If ($_.title -and $Currency) { 
                [Void](Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $Pool.title.Trim().ToLower())
            }

            $Key = "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$Currency" })"
            $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.stats.($Pool.name).expectedReward24H * $Variables.Rates.($Pool.name).BTC / $Divisor) -FaultDetection $false

            $Reasons = [System.Collections.Generic.List[String]]@()
            If ($Request.stats.($_.name).hashrate -eq 0) { $Reasons.Add("No hashrate at pool") }
            If (-not $PoolConfig.Wallets.$Currency) { $Reasons.Add("No wallet address for '$Currency' configured") }

            [PSCustomObject]@{ 
                Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                Algorithm                = [String]$Algorithm_Norm
                Currency                 = [String]$Currency
                Disabled                 = $Stat.Disabled
                EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                Fee                      = 0.03
                Host                     = [String]$Pool.servers[0].host
                Key                      = [String]$Key
                MiningCurrency           = ""
                Name                     = [String]$Name
                Pass                     = "x"
                Port                     = [UInt16]$Pool.servers[0].ports[0]
                PortSSL                  = [UInt16]$Pool.servers[0].ssl_ports[0]
                PoolUri                  = "https://hiveon.net/$($Currency.ToLower())"
                Price                    = $Stat.Live
                Protocol                 = "ethproxy"
                Reasons                  = $Reasons
                Region                   = [String]$PoolConfig.Region
                SendHashrate             = $false
                SSLSelfSignedCertificate = $false
                StablePrice              = $Stat.Week
                Updated                  = [DateTime]$Stat.Updated
                User                     = If ($PoolConfig.Wallets.$Currency) { [String]$PoolConfig.Wallets.$Currency } Else { "" }
                Workers                  = [Int]$Request.stats.($Pool.name).workers
                WorkerName               = [String]$PoolConfig.WorkerName
                Variant                  = [String]$PoolVariant
            }
        }
    }
}

$Error.Clear()