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
File:           ZPool.ps1
Version:        4.3.1.0
Version date:   02 March 2023
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
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$HostSuffix = "mine.zpool.ca"
$PayoutCurrency = $PoolConfig.Wallets.Keys | Select-Object -First 1
$Wallet = $PoolConfig.Wallets.$PayoutCurrency
$TransferFile = (Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Data\BrainData_" + (Get-Item $MyInvocation.MyCommand.Path).BaseName + ".json"

If ($DivisorMultiplier -and $PriceField -and $Wallet) { 

    Try { 
        If ($Variables.BrainData.$Name) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = Get-Content $TransferFile -ErrorAction Stop | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Request.PSObject.Properties.Name | Where-Object { $Request.$_.$PriceField -gt 0 } | ForEach-Object { 
        $Algorithm = $_
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$_.currency)".Trim()

        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = $Request.$_.Fees / 100

        If ($Algorithm_Norm -eq "FiroPow" -and $Currency -eq "SCC") { $Algorithm_Norm = "FiroPowSCC" } # SCC firo variant

        # Add coin name
        If ($Request.$_.CoinName -and $Currency) { 
            $CoinName = $Request.$_.CoinName.Trim()
            Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $CoinName
        }
        Else { 
            $CoinName = ""
        }

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ($Request.$_.$PriceField / $Divisor) -FaultDetection $false

        ForEach ($Region_Norm in $Variables.Regions.($Config.Region)) { 
            If ($Region = $PoolConfig.Region | Where-Object { (Get-Region $_) -eq $Region_Norm }) { 

                [PSCustomObject]@{ 
                    Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
                    Algorithm                = [String]$Algorithm_Norm
                    BaseName                 = [String]$Name
                    CoinName                 = [String]$CoinName
                    Currency                 = [String]$Currency
                    Disabled                 = [Boolean]$Stat.Disabled
                    EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                    Fee                      = [Decimal]$Fee
                    Host                     = "$($Algorithm).$($Region).$($HostSuffix)"
                    Name                     = [String]$PoolVariant
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency"
                    Port                     = If ($PoolConfig.SSL -eq "Always") { 0 } Else { [UInt16]$Request.$_.port }
                    PortSSL                  = If ($PoolConfig.SSL -eq "Never") { 0 } Else { [UInt16]("5$([String]$Request.$_.port)") }
                    Price                    = [Double]$Stat.Live
                    Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethproxy" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Region                   = [String]$Region_Norm
                    SendHashrate             = $false
                    SSLSelfSignedCertificate = $true
                    StablePrice              = [Double]$Stat.Week
                    Updated                  = [DateTime]$Request.$_.Updated
                    User                     = [String]$Wallet
                    WorkerName               = ""
                    Workers                  = [Int]$Request.$_.workers
                }
                Break
            }
        }
    }
}

$Error.Clear()