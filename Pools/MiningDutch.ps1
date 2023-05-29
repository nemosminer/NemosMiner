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
File:           MiningDutch.ps1
Version:        4.3.4.9
Version date:   21 May 2023
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
$Hostsuffix = "mining-dutch.nl"
$PayoutCurrency = $PoolConfig.Wallets.Keys | Select-Object -First 1
$Wallet = $PoolConfig.Wallets.$PayoutCurrency
$TransferFile = (Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Data\BrainData_" + (Get-Item $MyInvocation.MyCommand.Path).BaseName + ".json"

If ($DivisorMultiplier -and $PriceField -and $Wallet) { 

    $StartTime = (Get-Date)
    Write-Message -Level Debug "Pool '$($Name) (Variant $($PoolVariant))': Start loop"

    Try { 
        If ($Variables.Brains.$Name) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = Get-Content $TransferFile -ErrorAction Stop | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request.PSObject.Properties.Name) { Return }

    $PoolConfig.Region_Norm = ($PoolConfig.Region | ForEach-Object { Get-Region $_ })

    $Request.PSObject.Properties.Name | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$_.currency)".Trim()
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = $Request.$_.Fees / 100

        # Add coin name
        If ($Request.$_.CoinName -and $Currency) { 
            Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $Request.$_.CoinName
        }

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ($Request.$_.$PriceField / $Divisor) -FaultDetection $false

        $Reasons = [System.Collections.Generic.List[String]]@()
        If ($Request.$_.hashrate -eq 0 -and $Request.$_.hashrate_last24h -ne $null) { $Reasons.Add("No hashrate at pool") } # Temp Fix: Sometimes pool retuns $null hashrate for all algorithms
        # If ($Request.$_.hashrate -eq 0 ) { $Reasons.Add("No hashrate at pool") }
        If ($PoolVariant -match ".+Plus$" -and $Request.$_.$PriceField -eq 0) { $Reasons.Add("Plus price -eq 0")}

        ForEach ($Region_Norm in $Variables.Regions.($Config.Region)) { 
            If ($Region = $PoolConfig.Region | Where-Object { (Get-Region $_) -eq $Region_Norm }) { 

                [PSCustomObject]@{ 
                    Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
                    Algorithm                = [String]$Algorithm_Norm
                    BaseName                 = [String]$Name
                    Currency                 = [String]$Currency
                    Disabled                 = [Boolean]$Stat.Disabled
                    EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                    Fee                      = [Decimal]$Fee
                    Host                     = "$($Region).$($HostSuffix)"
                    Name                     = [String]$PoolVariant
                    Pass                     = "$($PoolConfig.WorkerName),c=$PayoutCurrency"
                    Port                     = [UInt16]$Request.$_.port
                    PortSSL                  = $null
                    Price                    = [Double]$Stat.Live
                    Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                    Reasons                  = $Reasons
                    Region                   = [String]$Region_Norm
                    SendHashrate             = $false
                    SSLSelfSignedCertificate = $true
                    StablePrice              = [Double]$Stat.Week
                    Updated                  = [DateTime]$Request.$_.Updated
                    User                     = "$($PoolConfig.UserName).$($PoolConfig.WorkerName)"
                    Workers                  = [Int]$Request.$_.workers
                    WorkerName               = ""
                }
                Break
            }
        }
    }
    
    Write-Message -Level Debug "Pool '$($Name) (Variant $($PoolVariant))': End loop (Duration: $(((Get-Date) - $StartTime).TotalSeconds) sec.)"
}

$Error.Clear()