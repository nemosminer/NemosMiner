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
File:           \Pools\MiningDutch.ps1
Version:        5.0.2.3
Version date:   2023/12/20
#>

param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Hostsuffix = "mining-dutch.nl"

$PoolConfig = $Variables.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$PayoutCurrency = $PoolConfig.Wallets.psBase.Keys | Select-Object -First 1
$Wallet = $PoolConfig.Wallets.$PayoutCurrency
$BrainDataFile = "$PWD\Data\BrainData_$Name.json"

If ($DivisorMultiplier -and $PriceField -and $Wallet) { 

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
        $Currency = "$($Request.$Algorithm.currency)" -replace ' \s+'
        $Divisor = $DivisorMultiplier * [Double]$Request.$Algorithm.mbtc_mh_factor

        # Add coin name
        If ($Request.$Algorithm.CoinName -and $Currency) { 
            [Void](Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $Request.$Algorithm.CoinName)
        }

        $Key = "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$Currency" })"
        $Stat = Set-Stat -Name "$($Key)_Profit" -Value ($Request.$Algorithm.$PriceField / $Divisor) -FaultDetection $false

        $Reasons = [System.Collections.Generic.List[String]]@()
        # Temp Fix: Sometimes pool returns $null hashrate for all algorithms
        If ($Request.$Algorithm.hashrate -eq 0 -and $Algorithm.hashrate_last24h -ne $null) { 
            $Reasons.Add("No hashrate at pool") 
        }
        # If ($Algorithm.hashrate -eq 0 ) { $Reasons.Add("No hashrate at pool") }

        ForEach ($Region_Norm in $Variables.Regions[$Config.Region]) { 
            If ($Region = $PoolConfig.Region.Where({ (Get-Region $_) -eq $Region_Norm })) { 

                [PSCustomObject]@{ 
                    Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
                    Algorithm                = [String]$Algorithm_Norm
                    Currency                 = [String]$Currency
                    Disabled                 = $Stat.Disabled
                    EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
                    Fee                      = $Request.$Algorithm.Fees / 100
                    Host                     = "$($Region).$($HostSuffix)"
                    Key                      = [String]$Key
                    MiningCurrency           = ""
                    Name                     = [String]$Name
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency"
                    Port                     = [UInt16]$Request.$Algorithm.port
                    PortSSL                  = 0
                    PoolUri                  = "https://www.mining-dutch.nl/?page=pools"
                    Price                    = $Stat.Live
                    Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Reasons                  = $Reasons
                    Region                   = [String]$Region_Norm
                    SendHashrate             = $false
                    SSLSelfSignedCertificate = $true
                    StablePrice              = $Stat.Week
                    Updated                  = [DateTime]$Request.$Algorithm.Updated
                    User                     = "$($PoolConfig.UserName).$($PoolConfig.WorkerName)"
                    Workers                  = [Int]$Algorithm.workers
                    WorkerName               = ""
                    Variant                  = [String]$PoolVariant
                }
                Break
            }
        }
    }
}

$Error.Clear()