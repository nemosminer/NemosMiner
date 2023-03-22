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
File:           NiceHash.ps1
Version:        4.3.2.1
Version date:   22 March 2023
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $Variables.PoolsConfig.$Name
$PoolVariant = If ($Variables.NiceHashWalletIsInternal) { "NiceHash Internal" } Else { "NiceHash External" }
$Fee = $PoolConfig.Variant.$PoolVariant.Fee
$PayoutCurrency = $PoolConfig.Variant.$PoolVariant.PayoutCurrency
$PoolHost = "auto.nicehash.com"
$Wallet = $PoolConfig.Variant.$PoolVariant.Wallets.$PayoutCurrency
$User = "$Wallet.$($PoolConfig.WorkerName -replace "^ID=")"

If ($Wallet) { 

    Do {
        Try { 
            If (-not $Request) { $Request = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/public/simplemultialgo/info/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec 3 }
            If (-not $RequestAlgodetails) { $RequestAlgodetails = Invoke-RestMethod -Uri "https://api2.nicehash.com/main/api/v2/mining/algorithms/" -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec 3 }
            $Request.miningAlgorithms | ForEach-Object { $Algorithm = $_.Algorithms; $_ | Add-Member -Force @{ algodetails = $RequestAlgodetails.miningAlgorithms | Where-Object { $_.Algorithms -eq $Algorithm } } }
        }
        Catch { 
            $APICallFails++
            Start-Sleep -Seconds ($APICallFails * 3)
        }
    } While (-not $Request -and $APICallFails -lt 3)

    If (-not $Request) { Return }

    $Request.miningAlgorithms | Where-Object speed -GT 0 | Where-Object { $_.algodetails.order -gt 0 } | ForEach-Object { 
        $Algorithm = $_.Algorithm
        $Algorithm_Norm = Get-Algorithm $Algorithm

        $Currency = Switch ($Algorithm) {
            "AUTOLYKOS"      { "ERG" }
            "BEAMV3"         { "BEAM" }
            "CUCKOOCYCLE"    { "AE" }
            "EAGLESONG"      { "CKB" }
            "ETCHASH"        { "ETC" }
            "GRINCUCKATOO31" { "GRIN" }
            "GRINCUCKATOO32" { "GRIN" }
            "HANDSHAKE"      { "HNS" }
            "KAWPOW"         { "RVN" }
            "LBRY"           { "LBC" }
            "OCTOPUS"        { "CFX" }
            "RandomxMONERO"  { "XMR" }
            "ZELHASH"        { "FLUX" }
            "ZHASH"          { "BTG" }
            Default          { "" }
        }

        $Divisor = 100000000

        $Stat = Set-Stat -Name "$($Name)_$($Algorithm_Norm)_Profit" -Value ([Double]$_.paying / $Divisor) -FaultDetection $false

        [PSCustomObject]@{ 
            Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Minute_5_Fluctuation), 1)) # Use short timespan to counter price spikes
            Algorithm                = [String]$Algorithm_Norm
            BaseName                 = [String]$Name
            Currency                 = [String]$Currency
            Disabled                 = [Boolean]$Stat.Disabled
            EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
            Fee                      = [Decimal]$Fee
            Host                     = "$Algorithm.$PoolHost".ToLower()
            Name                     = [String]$Name
            Pass                     = "x"
            Port                     = If ($PoolConfig.SSL -eq "Always") { 0 } Else { 9200 }
            PortSSL                  = If ($PoolConfig.SSL -eq "Never") { 0 } Else { 443 }
            Price                    = [Double]$Stat.Live
            Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratumnh" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
            Region                   = [String]$PoolConfig.Region
            SendHashrate             = $false
            SSLSelfSignedCertificate = $false
            StablePrice              = [Double]$Stat.Week
            Updated                  = [DateTime]$Stat.Updated
            User                     = "$Wallet.$($PoolConfig.WorkerName)"
            WorkerName               = ""
        }
    }
}

$Error.Clear()