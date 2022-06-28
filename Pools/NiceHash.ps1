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
Version:        4.0.1.3
Version date:   19 June 2022
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
$Wallet = $PoolConfig.Variant.$PoolVariant.Wallets.$PayoutCurrency

If ($Wallet) { 
    Try { 
        $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
        $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $Config.PoolTimeout
        $Request.miningAlgorithms | ForEach-Object { $Algorithm = $_.Algorithm; $_ | Add-Member -Force @{ algodetails = $RequestAlgodetails.miningAlgorithms | Where-Object { $_.Algorithm -eq $Algorithm } } }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $HostSuffix = "auto.nicehash.com"

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

        [PSCustomObject]@{ 
            Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Minute_5_Fluctuation), 1)) # Use short timespan to counter price peaks
            Algorithm                = [String]$Algorithm_Norm
            BaseName                 = [String]$Name
            Currency                 = [String]$Currency
            EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
            Fee                      = [Decimal]$Fee
            Host                     = "$Algorithm.$HostSuffix".ToLower()
            Name                     = [String]$PoolVariant
            Pass                     = "x"
            Port                     = [UInt16]9200
            Price                    = [Double]$Stat.Live
            Region                   = [String]$PoolConfig.Region
            SSL                      = $false
            StablePrice              = [Double]$Stat.Week
            Updated                  = [DateTime]$Stat.Updated
            User                     = "$Wallet.$($PoolConfig.WorkerName)"
            WorkerName               = ""
        }
    }
}
