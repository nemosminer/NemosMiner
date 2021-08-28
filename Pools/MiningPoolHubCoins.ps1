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
File:           MiningPoolHubCoins.ps1
Version:        3.9.9.66
Version date:   28 August 2021
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
$PoolRegions = $PoolConfig.Region

If ($PoolConfig.UserName) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getminingandprofitsstatistics" -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" } -TimeoutSec $Config.PoolTimeout
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Divisor = 1000000000

    $User = "$($PoolConfig.UserName).$($($PoolConfig.WorkerName -replace "^ID="))"

    $Request.return | Where-Object profit | ForEach-Object { 
        $Current = $_
        $Algorithm = $_.algo -replace "-"
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Fee = [Decimal]($_.Fee / 100)

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)-$($_.symbol)_Profit" -Value ([Decimal]$_.profit / $Divisor)

        $Price = (($Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1))) + ($Stat.Day * (0 + [Math]::Min($Stat.Day_Fluctuation, 1))))

        If ($Algorithm_Norm -in @("VertHash")) {
            [PSCustomObject]@{ 
                Algorithm                = [String]$Algorithm_Norm
                Currency                 = [String]$Current.symbol
                Price                    = [Double]$Price
                StablePrice              = [Double]$Stat.Week
                MarginOfError            = [Double]$Stat.Week_Fluctuation
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Host                     = [String]$Current.host
                Port                     = [UInt16]$Current.port
                User                     = [String]$User
                Pass                     = "x"
                Region                   = [String]$Config.Region
                SSL                      = [Bool]$false
                Fee                      = $Fee
                EstimateFactor           = [Decimal]1
            }
        }
        Else { 
            If ($Algorithm_Norm -eq "Ethash") { $PoolRegions = $PoolConfig.Region | Where-Object { $_ -in @("Asia", "US") } } # temp fix
    
            ForEach ($Region in $PoolRegions) { 
                $Region_Norm = Get-Region $Region

                [PSCustomObject]@{ 
                    Algorithm                = [String]$Algorithm_Norm
                    Currency                 = [String]$Current.symbol
                    Price                    = [Double]$Price
                    StablePrice              = [Double]$Stat.Week
                    MarginOfError            = [Double]$Stat.Week_Fluctuation
                    EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                    Host                     = [String]($Current.host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                    Port                     = [UInt16]$Current.port
                    User                     = [String]$User
                    Pass                     = "x"
                    Region                   = [String]$Region_Norm
                    SSL                      = [Bool]$false
                    Fee                      = $Fee
                    EstimateFactor           = [Decimal]1
                }
            }
        }
    }
}
