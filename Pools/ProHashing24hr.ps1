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
File:           ProHashing24hr.ps1
Version:        4.0.0.13 (RC13)
Version date:   03 January 2022
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Name_Norm = Get-PoolName $Name
$PoolConfig = $PoolsConfig.$Name_Norm

If ($PoolConfig.UserName) { 
    Try { 
        $Request = Get-Content ((Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Brains\$($Name_Norm)\$($Name_Norm).json") -ErrorAction Stop | ConvertFrom-Json
    }
    Catch { Return }

    If (-not $Request) { Return }

    $PoolHost = "prohashing.com"
    $PriceField = "estimate_last24h"
    # $PriceField = "estimate_current"
    # $PriceField = "Plus_Price"
    $DivisorMultiplier = 0.001

    $Request.PSObject.Properties.Name | Where-Object { [Double]($Request.$_.estimate_current) -gt 0 } | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$_.currency)".Trim()
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = $Request.$_."$($PoolConfig.MiningMode)_fee"
        $Pass = @("a=$($Algorithm.ToLower())", "n=$($PoolConfig.WorkerName)", "o=$($PoolConfig.UserName)") -join ','
        $PoolPort = $Request.$_.port

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor) -FaultDetection $false

        Try { $EstimateFactor = $Request.$_.actual_last24h * 1000 / $Request.$_.$PriceField }
        Catch { $EstimateFactor = 1 }

        $Regions = If ($Algorithm_Norm -in @("Chia", "Etchash", "Ethash", "EthashLowMem")) { "US" } Else { $PoolConfig.Region }

        ForEach ($Region in $Regions) { 
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{ 
                Name                     = [String]$Name
                BaseName                 = [String]$Name_Norm
                Algorithm                = [String]$Algorithm_Norm
                Currency                 = [String]$Currency
                Price                    = [Double]$Stat.Live
                StablePrice              = [Double]$Stat.Week
                MarginOfError            = [Double]$Stat.Week_Fluctuation
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Host                     = "$(If ($Region -eq "EU") { "eu." })$PoolHost"
                Port                     = [UInt16]$PoolPort
                User                     = [String]$PoolConfig.UserName
                Pass                     = [String]$Pass
                Region                   = [String]$Region_Norm
                SSL                      = $false
                Fee                      = [Decimal]$Fee
                EstimateFactor           = [Decimal]$EstimateFactor
            }
        }
    }
}
