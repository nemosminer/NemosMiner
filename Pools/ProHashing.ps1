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
File:           ProHashing.ps1
Version:        4.0.2.5
Version date:   27 July 2022
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $PoolsConfig.(Get-PoolBaseName $Name)
$PriceField = $Variables.PoolData.$Name.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $Variables.PoolData.$Name.Variant.$PoolVariant.DivisorMultiplier
$TransferFile = (Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Data\BrainData_" + (Get-Item $MyInvocation.MyCommand.Path).BaseName + ".json"

If ($DivisorMultiplier -and $PriceField -and $PoolConfig.UserName) { 
    Try { 
        $Request = Get-Content $TransferFile -ErrorAction Stop | ConvertFrom-Json
    }
    Catch { Return }

    If (-not $Request) { Return }

    $PoolHost = "prohashing.com"

    $Request.PSObject.Properties.Name | Where-Object { $Request.$_.$PriceField -gt 0 } -ErrorAction Stop | ForEach-Object { 
        $Algorithm = $Request.$_.name
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$_.currency)".Trim()
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = $Request.$_."$($PoolConfig.MiningMode)_fee"
        $Pass = @("a=$($Algorithm.ToLower())", "n=$($PoolConfig.WorkerName)", "o=$($PoolConfig.UserName)") -join ','
        $PoolPort = $Request.$_.port

        # Add coin name
        If ($Request.$_.CoinName -and $Currency) { Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $Request.$_.CoinName }

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ($Request.$_.$PriceField / $Divisor) -FaultDetection $false


        $Regions = If ($Algorithm_Norm -in @("Chia", "Etchash", "Ethash", "EthashLowMem")) { "US" } Else { $PoolConfig.Region }

        ForEach ($Region in $Regions) { 
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{ 
                Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
                Algorithm                = [String]$Algorithm_Norm
                BaseName                 = [String]$Name
                Currency                 = [String]$Currency
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Fee                      = [Decimal]$Fee
                Host                     = "$(If ($Region -eq "EU") { "eu." })$PoolHost"
                Name                     = [String]$PoolVariant
                Pass                     = [String]$Pass
                Port                     = [UInt16]$PoolPort
                Price                    = [Double]$Stat.Live
                Region                   = [String]$Region_Norm
                SSL                      = $false
                StablePrice              = [Double]$Stat.Week
                Updated                  = [DateTime]$Stat.Updated
                User                     = [String]$PoolConfig.UserName
                WorkerName               = ""
            }
        }
    }
}
