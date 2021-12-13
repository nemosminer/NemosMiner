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
File:           NiceHash.ps1
Version:        4.0.0.8 (RC8)
Version date:   13 December 2021
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $PoolsConfig.$Name

If ($Config.NiceHashWalletIsInternal -eq $true) { 
    $PoolBaseName = "NiceHash Internal"
    $Fee = 0.02
}
Else { 
    $PoolBaseName = "NiceHash External"
    $Fee = 0.05
}

$PoolHost = "nicehash.com"
$PoolConfig = $PoolsConfig.$PoolBaseName

$PayoutCurrency = $PoolConfig.Wallets | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Select-Object -Index 0
$Wallet = $PoolConfig.Wallets.$PayoutCurrency

If ($Wallet) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -TimeoutSec $Config.PoolTimeout -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" }
        $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -TimeoutSec $Config.PoolTimeout -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" }
        $Request.miningAlgorithms | ForEach-Object { $Algo = $_.Algorithm; $_ | Add-Member -Force @{ algodetails = $RequestAlgodetails.miningAlgorithms | Where-Object { $_.Algorithm -eq $Algo } } }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $User = "$Wallet.$($($PoolConfig.WorkerName -replace "^ID="))"

    $Request.miningAlgorithms | Where-Object speed -GT 0 | Where-Object { $_.algodetails.order -gt 0 } | ForEach-Object { 
        $Algorithm = $_.Algorithm
        $PoolPort = $_.algodetails.port
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $DivisorMultiplier = 1000000000
        $Divisor = $DivisorMultiplier * [Double]$_.Algodetails.marketFactor
        $Divisor = 100000000

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$_.paying / $Divisor) -FaultDetection $false

        ForEach ($Region in $PoolConfig.Region) { 
            $Region_Norm = Get-Region $Region

            [PSCustomObject]@{ 
                BaseName                 = [String]$PoolBaseName
                Algorithm                = [String]$Algorithm_Norm
                Price                    = [Double]$Stat.Live
                StablePrice              = [Double]$Stat.Live # No fluctuation, always use live price
                MarginOfError            = [Double]0
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Host                     = "$Algorithm.$Region.$PoolHost".ToLower()
                Port                     = [UInt16]$PoolPort
                User                     = [String]$User
                Pass                     = "x"
                Region                   = [String]$Region_Norm
                SSL                      = [Boolean]$false
                Fee                      = [Decimal]$PoolConfig.Fee
                EstimateFactor           = [Decimal]1
            }
        }
    }
}
