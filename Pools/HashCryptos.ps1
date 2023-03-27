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
File:           HashCryptos.ps1
Version:        4.3.3.0
Version date:   27 March 2023
#>

using module ..\Includes\Include.psm1

param(
    [PSCustomObject]$Config,
    [String]$PoolVariant,
    [Hashtable]$Variables
)

$ProgressPreference = "SilentlyContinue"

$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$PoolConfig = $Variables.PoolsConfig.$Name
$PriceField = $PoolConfig.Variant.$PoolVariant.PriceField
$DivisorMultiplier = $PoolConfig.Variant.$PoolVariant.DivisorMultiplier
$Hostsuffix = "hashcryptos.com"
$PayoutCurrency = $PoolConfig.Wallets.Keys | Select-Object -First 1
$Wallet = $PoolConfig.Wallets.$PayoutCurrency
$TransferFile = (Split-Path -Parent (Get-Item $MyInvocation.MyCommand.Path).Directory) + "\Data\BrainData_" + (Get-Item $MyInvocation.MyCommand.Path).BaseName + ".json"

If ($DivisorMultiplier -and $PriceField -and $Wallet) { 

    Try { 
        If ($Variables.BrainData.$Name) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = Get-Content $TransferFile -ErrorAction Stop | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request) { Return }

    $Request.PSObject.Properties.Name | Where-Object { $Request.$_.$PriceField -gt 0 } | ForEach-Object { 
        $Algorithm = $_
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$_.currency)".Trim()
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = $Request.$_.Fees / 100

        # Add coin name
        If ($Request.$_.CoinName -and $Currency) { 
            $CoinName = $Request.$_.CoinName.Trim()
            Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $CoinName
        }
        Else { 
            $CoinName = ""
        }

        $HostPrefix = Switch ($Algorithm_Norm) { 
            "Blake2s"       { "stratum3." }
            "C11"           { "" }
            "Cryptonight"   { "" }
            "Equihash2009"  { "stratum4." }
            "Equihash1927"  { "stratum4." }
            "Groestl"       { "stratum3." }
            "KawPow"        { "stratum4." }
            "Keccak"        { "stratum3." }
            "Lbry"          { "stratum4." }
            "Lyra2RE2"      { "stratum3." }
            "Lyra2RE3"      { "" }
            "MyriadGroestl" { "stratum3." }
            "Neoscrypt"     { "stratum1." }
            "Nist5"         { "" }
            "Odocrypt"      { "stratum2." }
            "Phi2"          { "" }
            "Quark"         { "stratum3." }
            "Qubit"         { "stratum3." }
            "Scrypt"        { "stratum2." }
            "SHA256"        { "stratum1." }
            "Skein"         { "stratum3." }
            "SkunkHash"     { "" }
            "Tribus"        { "stratum4." }
            "VertHash"      { "stratum3." }
            "X11"           { "stratum1." }
            "X11Ghost"      { "stratum3." }
            "X13"           { "stratum3." }
            "X13bcd"        { "" }
            "X16r"          { "" }
            "X16s"          { "" }
            "X17"           { "" }
            "Yescrypt"      { "stratum4." }
            "YescryptR16"   { "stratum4." }
            "YescryptR32"   { "stratum4." }
            "Yespower"      { "stratum4." }
            "YespowerR16"   { "stratum4." }
            Default         { "" }
        }

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ($Request.$_.$PriceField / $Divisor) -FaultDetection $false

        If ($HostPrefix) { 

            [PSCustomObject]@{ 
                Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
                Algorithm                = [String]$Algorithm_Norm
                BaseName                 = [String]$Name
                CoinName                 = [String]$CoinName
                Currency                 = [String]$Currency
                Disabled                 = [Boolean]$Stat.Disabled
                EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                Fee                      = [Decimal]$Fee
                Host                     = [String]"$($HostPrefix)$($HostSuffix)"
                Name                     = [String]$PoolVariant
                Pass                     = [String]$PoolConfig.WorkerName
                Port                     = [UInt16]$Request.$_.port
                PortSSL                  = $null
                Price                    = [Double]$Stat.Live
                Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratum1" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                Region                   = [String]$PoolConfig.Region
                SendHashrate             = $false
                SSLSelfSignedCertificate = $true
                StablePrice              = [Double]$Stat.Week
                Updated                  = [DateTime]$Request.$_.Updated
                User                     = [String]"$($Wallet).$($PoolConfig.WorkerName)"
                WorkerName               = ""
                Workers                  = [Int]$Request.$_.workers
            }
        }
    }
}

$Error.Clear()