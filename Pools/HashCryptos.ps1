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
File:           \Pools\HashCryptos.ps1
Version:        5.0.2.1
Version date:   2023/12/09
#>

param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Hostsuffix = "stratum1.hashcryptos.com"

$PoolConfig = $Variables.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$PayoutCurrency = $PoolConfig.PayoutCurrency
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
        If ($Request.$Algorithm.hashrate -eq 0 -or $Request.$Algorithm.hashrate_last24h -eq 0) { $Reasons.Add("No hashrate at pool") }

        [PSCustomObject]@{ 
            Accuracy                 = 1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1)
            Algorithm                = [String]$Algorithm_Norm
            Currency                 = [String]$Currency
            Disabled                 = $Stat.Disabled
            EarningsAdjustmentFactor = $PoolConfig.EarningsAdjustmentFactor
            Fee                      = $Request.$Algorithm.Fees / 100
            Host                     = [String]$HostSuffix
            Key                      = [String]$Key
            MiningCurrency           = ""
            Name                     = [String]$Name
            Pass                     = "x"
            Port                     = [UInt16]($Request.$Algorithm.port -split ' ')[0]
            PortSSL                  = If (($Request.$Algorithm.port -split ' ')[2]) { ($Request.$Algorithm.port -split ' ')[2] } Else { $null }
            Price                    = $Stat.Live
            Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
            Reasons                  = $Reasons
            Region                   = [String]$PoolConfig.Region
            SendHashrate             = $false
            SSLSelfSignedCertificate = $true
            StablePrice              = $Stat.Week
            Updated                  = [DateTime]$Request.$Algorithm.Updated
            User                     = [String]$Wallet
            WorkerName               = [String]$PoolConfig.WorkerName
            Workers                  = [Int]$Request.$Algorithm.workers
            Variant                  = [String]$PoolVariant
        }
    }
}

$Error.Clear()