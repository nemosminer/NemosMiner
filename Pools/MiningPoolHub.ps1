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
File:           MiningPoolHub.ps1
Version:        3.9.9.63
Version date:   14 August 2021
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Name_Norm = $Name -replace "24hr$|Coins$|Plus$"
$PoolConfig = $PoolsConfig.$Name_Norm
$PoolRegions = $PoolConfig.Region

If ($PoolConfig.UserName) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics" -Headers @{ "Cache-Control" = "no-cache" } -TimeoutSec $Config.PoolTimeout
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Divisor = 1000000000

    $User = "$($PoolConfig.UserName).$($($PoolConfig.WorkerName -replace "^ID="))"

    $Request.return | Where-Object profit | ForEach-Object { 
        $Current = $_
        $Algorithm = $_.algo -replace "-"
        $Algorithm_Norm = Get-Algorithm $Algorithm

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Decimal]$_.profit / $Divisor)

        If ($Algorithm_Norm -in @("VertHash")) {

            # Temp fix
            If ($Algorithm_Norm -eq "VertHash") { $Port = 20534 }
            Else { $Port = $Current.port }

            [PSCustomObject]@{ 
                Algorithm                = [String]$Algorithm_Norm
                Currency                 = [String]$Current.current_mining_coin_symbol
                Price                    = [Double](($Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1))) + ($Stat.Day * (0 + [Math]::Min($Stat.Day_Fluctuation, 1))))
                StablePrice              = [Double]$Stat.Week
                MarginOfError            = [Double]$Stat.Week_Fluctuation
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Host                     = [String]$Current.Host
                Port                     = [UInt16]$Port
                User                     = [String]$User
                Pass                     = "x"
                Region                   = [String]$Config.Region
                SSL                      = [Bool]$false
                Fee                      = [Decimal]$PoolConfig.Fee
                EstimateFactor           = [Decimal]1
            }
        }
        Else { 
            If ($Algorithm_Norm -eq "Ethash") { $PoolRegions = $PoolConfig.Region | Where-Object { $_ -in @("Asia", "US") } } # temp fix

            ForEach ($Region in $PoolRegions) { 
                $Region_Norm = Get-Region $Region

                [PSCustomObject]@{ 
                    Algorithm                = [String]$Algorithm_Norm
                    CoinName                 = [String]$CoinName
                    Currency                 = [String]$Current.current_mining_coin_symbol
                    Price                    = [Double](($Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1))) + ($Stat.Day * (0 + [Math]::Min($Stat.Day_Fluctuation, 1))))
                    StablePrice              = [Double]$Stat.Week
                    MarginOfError            = [Double]$Stat.Week_Fluctuation
                    EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                    Host                     = [String]($Current.all_host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                    Port                     = [UInt16]$Current.algo_switch_port
                    User                     = [String]$User
                    Pass                     = "x"
                    Region                   = [String]$Region_Norm
                    SSL                      = [Bool]$false
                    Fee                      = [Decimal]$PoolConfig.Fee
                    EstimateFactor           = [Decimal]1
                }
            }
        }
    }
}
