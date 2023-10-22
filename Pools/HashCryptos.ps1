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
Version:        5.0.1.5
Version date:   2023/10/22
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
$PayoutCurrency = $PoolConfig.Wallets.psBase.Keys | Select-Object -First 1
$Wallet = $PoolConfig.Wallets.$PayoutCurrency

$BrainDataFile = (Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Data\BrainData_" + (Get-Item $MyInvocation.MyCommand.Path).BaseName + ".json"

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

    $Request.PSObject.Properties.Name | Where-Object { $Request.$_.Updated -ge $Variables.Brains.$Name."Updated" } | ForEach-Object { 
        $Algorithm = $_
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$_.currency)" -replace ' \s+'
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = $Request.$_.Fees / 100

        # Add coin name
        If ($Request.$_.CoinName -and $Currency) { 
            [Void](Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $Request.$_.CoinName)
        }

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ($Request.$_.$PriceField / $Divisor) -FaultDetection $false

        $Reasons = [System.Collections.Generic.List[String]]@()
        If ($Request.$_.hashrate -eq 0 -or $Request.$_.hashrate_last24h -eq 0) { $Reasons.Add("No hashrate at pool") }

        [PSCustomObject]@{ 
            Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
            Algorithm                = [String]$Algorithm_Norm
            BaseName                 = [String]$Name
            Currency                 = [String]$Currency
            Disabled                 = [Boolean]$Stat.Disabled
            EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
            Fee                      = [Decimal]$Fee
            Host                     = [String]$HostSuffix
            Name                     = [String]$PoolVariant
            Pass                     = [String]$PoolConfig.WorkerName
            Port                     = [UInt16]($Request.$_.port -split ' ')[0]
            PortSSL                  = If (($Request.$_.port -split ' ')[2]) { ($Request.$_.port -split ' ')[2] } Else { $null }
            Price                    = [Double]$Stat.Live
            Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
            Reasons                  = $Reasons
            Region                   = [String]$PoolConfig.Region
            SendHashrate             = $false
            SSLSelfSignedCertificate = $true
            StablePrice              = [Double]$Stat.Week
            Updated                  = [DateTime]$Request.$_.Updated
            User                     = [String]"$($Wallet).$($PoolConfig.WorkerName)"
            WorkerName               = ""
            Workers                  = [Int]$Request.$_.workers
        }
    }
}

$Error.Clear()