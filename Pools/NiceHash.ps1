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
Version:        4.0.0.35
Version date:   24 May 2022
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [PSCustomObject]$PoolsConfig,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $PoolsConfig.(Get-PoolBaseName $Name)
$Fee = $PoolConfig.Variant.$PoolVariant.Fee
$PayoutCurrency = $PoolConfig.Variant.$PoolVariant.PayoutCurrency
$Regions = If ($Config.UseAnycast -and $PoolConfig.Region -contains "N/A (Anycast)") { "N/A (Anycast)" } Else { $PoolConfig.Region | Where-Object { $_ -ne "N/A (Anycast)" }  }
$Wallet = $PoolConfig.Variant.$PoolVariant.Wallets.$PayoutCurrency
$User = "$Wallet.$($PoolConfig.WorkerName -replace "^ID=")"

If ($Wallet) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
        $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
        $Request.miningAlgorithms | ForEach-Object { $Algorithm = $_.Algorithm; $_ | Add-Member -Force @{ algodetails = $RequestAlgodetails.miningAlgorithms | Where-Object { $_.Algorithm -eq $Algorithm } } }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $HostSuffix = "nicehash.com"

    $Request.miningAlgorithms | Where-Object { $_.algodetails.enabled -and [Double]$_.paying -gt 0 -and [Double]$_.speed -gt 0 } | ForEach-Object { 
        $Algorithm = $_.Algorithm
        $Algorithm_Norm = Get-Algorithm $Algorithm

        $Currency = Switch -Regex ($Algorithm_Norm) {
            "Autolykos2"                { "ERG" }
            "BeamV3"                    { "BEAM" }
            "CuckooCycle"               { "AE" }
            "Cuckaroo29"                { "XBG" }
            "Cuckarood29"               { "MWC" }
            "^Cuckatoo31$|^Cuckatoo32$" { "GRIN" }
            "CryptonightR"              { "SUMO" }
            "Eaglesong"                 { "CKB" }
            "Equihash1254"              { "FLUX" }
            "EquihashBTG"               { "BTG" }
            "Ethash"                    { "ETH" }
            "Handshake"                 { "HNS" }
            "KawPoW"                    { "RVN" }
            "Lbry"                      { "LBC" }
            "Octopus"                   { "CFX" }
            "RandomX"                   { "XMR" }
            Default                     { "" }
        }

        $Divisor = 100000000

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)_Profit" -Value ([Double]$_.paying / $Divisor) -FaultDetection $false

        ForEach ($Region in $Regions) { 
            $Region_Norm = Get-Region $Region

            If ($Region -eq "N/A (Anycast)") { 
                $PoolHost = "$Algorithm.Auto.$HostSuffix"
                $PoolPort = 9200
            }
            Else { 
                $PoolHost = "$Algorithm.$Region.$HostSuffix"
                $PoolPort = $_.algodetails.port
            }

            [PSCustomObject]@{ 
                Name                     = [String]$PoolVariant
                BaseName                 = [String]$Name
                Algorithm                = [String]$Algorithm_Norm
                Currency                 = [String]$Currency
                Price                    = [Double]$Stat.Live
                StablePrice              = [Double]$Stat.Week
                Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Minute_5_Fluctuation), 1)) # Use short timespan to counter price peaks
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Host                     = [String]$PoolHost.ToLower()
                Port                     = [UInt16]$PoolPort
                User                     = [String]$User
                Pass                     = "x"
                Region                   = [String]$Region_Norm
                SSL                      = $false
                Fee                      = [Decimal]$Fee
                Updated                  = [DateTime]$Stat.Updated
            }
        }
    }
}
