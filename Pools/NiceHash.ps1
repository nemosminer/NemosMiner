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
File:           NiceHash.ps1
Version:        4.0.0.12 (RC12)
Version date:   01 January 2022
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName

If ($Variables.NiceHashWalletIsInternal -eq $true) { 
    $PoolName = "NiceHash Internal"
    $Fee = 0.02
}
Else { 
    $PoolName = "NiceHash External"
    $Fee = 0.05
}

$PoolHost = "nicehash.com"
$PoolConfig = $PoolsConfig.$PoolName

$PayoutCurrency = $PoolConfig.Wallets.PSObject.Properties.Name | Select-Object -Index 0
$Wallet = $PoolConfig.Wallets.$PayoutCurrency

If ($Wallet) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
        $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
        $Request.miningAlgorithms | ForEach-Object { $Algo = $_.Algorithm; $_ | Add-Member -Force @{ algodetails = $RequestAlgodetails.miningAlgorithms | Where-Object { $_.Algorithm -eq $Algo } } }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $User = "$Wallet.$($($PoolConfig.WorkerName -replace "^ID="))"

    $Request.miningAlgorithms | Where-Object speed -GT 0 | Where-Object { $_.algodetails.order -gt 0 } | ForEach-Object { 
        $Algorithm = $_.Algorithm
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Port = $_.algodetails.port
        # $DivisorMultiplier = 1000000000
        # $Divisor = $DivisorMultiplier * [Double]$_.Algodetails.priceFactor
        $Divisor = 100000000

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$_.paying / $Divisor) -FaultDetection $false

        ForEach ($Region in $PoolConfig.Region) { 
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{ 
                Name                     = [String]$PoolName
                BaseName                 = [String]$Name
                Algorithm                = [String]$Algorithm_Norm
                Price                    = [Double]$Stat.Live
                StablePrice              = [Double]$Stat.Week
                MarginOfError            = [Double]$Stat.Week_Fluctuation
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Host                     = "$Algorithm.$Region.$PoolHost".ToLower()
                Port                     = [UInt16]$Port
                User                     = [String]$User
                Pass                     = "x"
                Region                   = [String]$Region_Norm
                SSL                      = $false
                Fee                      = [Decimal]$PoolConfig.Fee
                EstimateFactor           = [Decimal]1
            }
        }
    }
}
