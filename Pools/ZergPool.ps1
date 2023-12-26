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
File:           \Pools\ZergPool.ps1
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
$HostSuffix = "mine.zergpool.com"

$PoolConfig = $Variables.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$Regions = If ($Config.UseAnycast -and $PoolConfig.Region -contains "n/a (Anycast)") { "n/a (Anycast)" } Else { $PoolConfig.Region | Where-Object { $_ -ne "n/a (Anycast)" } }
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

If ($DivisorMultiplier -and $Regions) {

    Try { 
        If ($Variables.BrainData.$Name.PSObject.Properties) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = Get-Content $BrainDataFile -ErrorAction Stop | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request.PSObject.Properties.Name) { Return }

    ForEach ($Pool in $Request.PSObject.Properties.Name.Where({ $Request.$_.Updated -ge $Variables.Brains.$Name."Updated" })) { 
        $Algorithm = $Request.$Pool.algo
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = $Request.$Pool.Currency
        $Divisor = $DivisorMultiplier * [Double]$Request.$Pool.mbtc_mh_factor

        $PayoutCurrency = If ($Currency -and $PoolConfig.Wallets.$Pool -and -not $PoolConfig.ProfitSwitching) { $Currency } Else { $PoolConfig.PayoutCurrency }

        $Key = "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })"
        $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.$Pool.$PriceField / $Divisor) -FaultDetection $false

        $PayoutThreshold = $PoolConfig.PayoutThreshold.$PayoutCurrency
        If ($PayoutThreshold -gt $Request.$Pool.minpay) { $PayoutThreshold = $Request.$Pool.minpay }
        If (-not $PayoutThreshold -and $PayoutCurrency -eq "BTC" -and $PoolConfig.PayoutThreshold.mBTC) { $PayoutThreshold = $PoolConfig.PayoutThreshold.mBTC / 1000 }
        If ($PayoutThreshold) { $PayoutThresholdParameter = ",pl=$([Double]$PayoutThreshold)" }

        $Reasons = [System.Collections.Generic.List[String]]@()
        If ($Request.$Pool.noautotrade -eq 1 -and $Pool -ne $PayoutCurrency) { $Reasons.Add("Conversion disabled at pool, no wallet address for '$Pool' configured") }
        If ($Request.$Pool.hashrate_shared -eq 0) { $Reasons.Add("No hashrate at pool") }

        ForEach ($Region_Norm in $Variables.Regions[$Config.Region]) { 
            If ($Region = $Regions.Where({ $_ -eq "n/a (Anycast)" -or (Get-Region $_) -eq $Region_Norm })) { 

                If ($Region -eq "n/a (Anycast)") { 
                    $PoolHost = "$Algorithm.$HostSuffix"
                    $Region_Norm = $Region
                }
                Else { 
                    $PoolHost = "$Algorithm.$Region.$HostSuffix"
                }

                [PSCustomObject]@{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                    Algorithm                = [String]$Algorithm_Norm
                    Currency                 = [String]$Currency
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Request.$Pool.Fees / 100
                    Host                     = [String]$PoolHost
                    Key                      = [String]$Key
                    MiningCurrency           = If ($Currency) { $Currency } Else { "" }
                    Name                     = [String]$Name
                    Pass                     = "c=$PayoutCurrency$(If ($Currency) { ",mc=$Currency" }),ID=$($PoolConfig.WorkerName -replace '^ID=')$PayoutThresholdParameter" # Pool profit switching breaks Option 2 (static coin), instead it will still send DAG data for any coin
                    Port                     = [UInt16]$Request.$Pool.port
                    PortSSL                  = [UInt16]$Request.$Pool.tls_port
                    PoolUri                  = "https://zergpool.com/site/mining?algo=$($Algorithm)"
                    Price                    = $Stat.Live
                    Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratum2" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Reasons                  = $Reasons
                    Region                   = [String]$Region_Norm
                    SendHashrate             = $false
                    SSLSelfSignedCertificate = $false
                    StablePrice              = $Stat.Week
                    Updated                  = [DateTime]$Request.$Pool.Updated
                    User                     = [String]$PoolConfig.Wallets.$PayoutCurrency
                    Workers                  = [Int]$Request.$Pool.workers_shared
                    WorkerName               = ""
                    Variant                  = [String]$PoolVariant
                }
                Break
            }
        }
    }
}

$Error.Clear()