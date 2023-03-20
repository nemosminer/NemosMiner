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
File:           ProHashing.ps1
Version:        4.3.2.0
Version date:   18 March 2023
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
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$HostSuffix = "mining.prohashing.com"
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$TransferFile = (Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Data\BrainData_" + (Get-Item $MyInvocation.MyCommand.Path).BaseName + ".json"

If ($DivisorMultiplier -and $PriceField -and $PoolConfig.UserName) { 

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

    $Request.PSObject.Properties.Name | Where-Object { $Request.$_.$PriceField -gt 0 } -ErrorAction Stop | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = $Request.$_.currency
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = If ($Currency) { $Request.$_."$($PoolConfig.MiningMode)_fee" } Else { $Request.$_."pps_fee" }
        $Pass = "a=$($Algorithm.ToLower()),e=off,n=$($PoolConfig.WorkerName),o=$($PoolConfig.UserName)$(If ($Algorithm_Norm -ne "Ethash" -and $Config.ProHashingMiningMode -eq "PPLNS" -and $Request.$_.CoinName) { ",m=pplns,c=$($Request.$_.CoinName.ToLower())" })"

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
                    Host                     = "$($Region.ToLower()).$HostSuffix"
                    Name                     = [String]$PoolVariant
                    Pass                     = [String]$Pass
                    Port                     = [UInt16]$Request.$_.port
                    PortSSL                  = $null
                    Price                    = [Double]$Stat.Live
                    Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Region                   = [String]$Region_Norm
                    SendHashrate             = $false
                    SSLSelfSignedCertificate = $true
                    StablePrice              = [Double]$Stat.Week
                    Updated                  = [DateTime]$Stat.Updated
                    User                     = [String]$PoolConfig.UserName
                    WorkerName               = ""
                }
                Break
            }
        }
    }
}

$Error.Clear()