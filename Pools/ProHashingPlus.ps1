<#
Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru


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
Version:        4.0.0.5 (RC5)
Version date:   16 October 2021
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Name_Norm = $Name -replace "24hr$|Coins$|Plus$|CoinsPlus$"
$PoolConfig = $PoolsConfig.$Name_Norm

If ($PoolConfig.UserName) { 
    Try {
        $Request = Get-Content ((Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Brains\$($Name_Norm)\$($Name_Norm).json") | ConvertFrom-Json
    }
    Catch { Return }

    If (-not $Request) { Return }

    $PoolHost = "prohashing.com"
    # $PriceField = "actual_last24h"
    # $PriceField = "estimate_current"
    $PriceField = "Plus_Price"

    $Request | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { [Double]($Request.$_.estimate_current) -gt 0 } | ForEach-Object {
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $PoolPort = $Request.$_.port

        $Pass = @("a=$Algorithm", "n=$($PoolConfig.WorkerName)", "o=$($PoolConfig.UserName)")

        $Currency = $Request.$_.currency

        $Fee = $Request.$_."$($MiningMode)_fee"
        $Divisor = [Double]$Request.$_.mbtc_mh_factor

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$Request.$_.$PriceField / $Divisor) -FaultDetection $false

        ForEach ($Region in $PoolConfig.Region) { 
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{
                Algorithm                = [String]$Algorithm_Norm
                Currency                 = [String]$Currency
                Price                    = [Double]$Stat.Live
                StablePrice              = [Double]$Stat.Week
                MarginOfError            = [Double]$Stat.Week_Fluctuation
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Host                     = "$(If ($Region -eq "eu") { "eu." })$PoolHost"
                Port                     = [UInt16]$PoolPort
                User                     = [String]$PoolConfig.UserName
                Pass                     = [String]($Pass -join ',')
                Region                   = [String]$Region_Norm
                SSL                      = [Boolean]$false
                Fee                      = [Decimal]$Fee
                EstimateFactor           = [Decimal]1
            }
        }
    }
}
