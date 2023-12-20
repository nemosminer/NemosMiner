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
File:           \Pools\ZPool.ps1
Version:        5.0.2.4
Version date:   2023/12/20
#>

param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$HostSuffix = "mine.zpool.ca"

$PoolConfig = $Variables.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

If ($PriceField) { 

    Try { 
        If ($Variables.Brains.$Name) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = Get-Content $BrainDataFile -ErrorAction Stop | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request.PSObject.Properties.Name) { Return }

    ForEach ($Algorithm in $Request.PSObject.Properties.Name.Where({ $Request.$_.Updated -ge $Variables.Brains.$Name."Updated" })) { 
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = $Request.$Algorithm.currency
        $Divisor = $DivisorMultiplier * [Double]$Request.$Algorithm.mbtc_mh_factor
        $PayoutCurrency = If ($Currency -and $PoolConfig.Wallets.$Currency -and -not $PoolConfig.ProfitSwitching) { $Currency } Else { $PoolConfig.PayoutCurrency }

        $Key = "$($PoolVariant)_$($Algorithm_Norm)"
        $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.$Algorithm.$PriceField / $Divisor) -FaultDetection $false

        $Reasons = [System.Collections.Generic.List[String]]@()
        If ($Request.$Algorithm.conversion_disabled -eq 1 -and $Currency -ne $PayoutCurrency) { $Reasons.Add("Conversion disabled at pool, no wallet address for '$Currency' configured") }
        # If ($Request.$Algorithm.error) { $Reasons.Add($Request.$Algorithm.error) }
        If ($Request.$Algorithm.hashrate_last24h -eq 0) { $Reasons.Add("No hashrate at pool") }

        ForEach ($Region_Norm in $Variables.Regions[$Config.Region]) { 
            If ($Region = $PoolConfig.Region.Where({ (Get-Region $_) -eq $Region_Norm })) { 

                [PSCustomObject]@{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                    Algorithm                = [String]$Algorithm_Norm
                    CoinName                 = [String]$CoinName
                    Currency                 = [String]$Currency
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Request.$Algorithm.Fees / 100
                    Host                     = "$($Algorithm).$($Region).$($HostSuffix)"
                    Key                      = [String]$Key
                    MiningCurrency           = If ($Currency -eq $PayoutCurrency) { $Currency } Else { "" }
                    Name                     = [String]$Name
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency$(If ($Currency -eq $PayoutCurrency) { ",zap=$Currency" })"
                    Port                     = [UInt16]$Request.$Algorithm.port
                    PortSSL                  = [UInt16]("5$([String]$Request.$Algorithm.port)")
                    PoolUri                  = "https://zpool.ca/algo/$($Algorithm)"
                    Price                    = $Stat.Live
                    Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethproxy" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Reasons                  = $Reasons
                    Region                   = [String]$Region_Norm
                    SendHashrate             = $false
                    SSLSelfSignedCertificate = $true
                    StablePrice              = $Stat.Week
                    Updated                  = [DateTime]$Request.$Algorithm.Updated
                    User                     = [String]$PoolConfig.Wallets.$PayoutCurrency
                    WorkerName               = ""
                    Workers                  = [Int]$Request.$Algorithm.workers
                    Variant                  = [String]$PoolVariant
                }
                Break
            }
        }
    }
}

$Error.Clear()