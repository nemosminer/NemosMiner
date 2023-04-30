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
Version:        4.3.4.5
Version date:   30 April 2023
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

    $StartTime = (Get-Date)
    Write-Message -Level Debug "Pool '$($Name) (Variant $($PoolVariant))': Start loop"

    Try { 
        If ($Variables.Brains.$Name) { 
            $Request = $Variables.BrainData.$Name
        }
        Else { 
            $Request = Get-Content $TransferFile -ErrorAction Stop | ConvertFrom-Json
        }
    }
    Catch { Return }

    If (-not $Request.PSObject.Properties.Name) { Return }

    $Request.PSObject.Properties.Name | ForEach-Object { 
        $Algorithm = $_
        $Algorithm_Norm = Get-Algorithm $Algorithm
        $Currency = "$($Request.$_.currency)".Trim()
        $Divisor = $DivisorMultiplier * [Double]$Request.$_.mbtc_mh_factor
        $Fee = $Request.$_.Fees / 100

        # Add coin name
        If ($Request.$_.CoinName -and $Currency) { 
            Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $Request.$_.CoinName
        }

        $HostPrefix = Switch ($Algorithm_Norm) { 
            "Blake2s"       { "stratum3."; Break }
            "C11"           { ""; Break }
            "Cryptonight"   { ""; Break }
            "Equihash2009"  { "stratum4."; Break }
            "Equihash1927"  { "stratum4."; Break }
            "Groestl"       { "stratum3."; Break }
            "KawPow"        { "stratum4."; Break }
            "Keccak"        { "stratum3."; Break }
            "Lbry"          { "stratum4."; Break }
            "Lyra2RE2"      { "stratum3."; Break }
            "Lyra2RE3"      { ""; Break }
            "MyriadGroestl" { "stratum3."; Break }
            "Neoscrypt"     { "stratum1."; Break }
            "Nist5"         { ""; Break }
            "Odocrypt"      { "stratum2."; Break }
            "Phi2"          { ""; Break }
            "Quark"         { "stratum3."; Break }
            "Qubit"         { "stratum3."; Break }
            "Scrypt"        { "stratum2."; Break }
            "SHA256"        { "stratum1."; Break }
            "Skein"         { "stratum3."; Break }
            "SkunkHash"     { ""; Break }
            "Tribus"        { "stratum4."; Break }
            "VertHash"      { "stratum3."; Break }
            "X11"           { "stratum1."; Break }
            "X11Ghost"      { "stratum3."; Break }
            "X13"           { "stratum3."; Break }
            "X13bcd"        { ""; Break }
            "X16r"          { ""; Break }
            "X16s"          { ""; Break }
            "X17"           { ""; Break }
            "Yescrypt"      { "stratum4."; Break }
            "YescryptR16"   { "stratum4."; Break }
            "YescryptR32"   { "stratum4." ; Break}
            "Yespower"      { "stratum4."; Break }
            "YespowerR16"   { "stratum4."; Break }
            Default         { "" }
        }

        $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)$(If ($Currency) { "-$($Currency)" })_Profit" -Value ($Request.$_.$PriceField / $Divisor) -FaultDetection $false

        $Reasons = [System.Collections.Generic.List[String]]@()
        If ($Request.$_.hashrate -eq 0) { $Reasons.Add("No hashrate at pool") }
        If ($Request.$_.hashrate_last24h -eq 0) { $Reasons.Add("No hashrate at pool") }
        If ($PoolVariant -match ".+Plus$" -and $Request.$_.$PriceField -eq 0) { $Reasons.Add("Plus price -eq 0")}

        If ($HostPrefix) { 

            [PSCustomObject]@{ 
                Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
                Algorithm                = [String]$Algorithm_Norm
                BaseName                 = [String]$Name
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
                Reasons                  = $Reasons
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

    Write-Message -Level Debug "Pool '$($Name) (Variant $($PoolVariant))': End loop (Duration: $(((Get-Date) - $StartTime).TotalSeconds) sec.)"
}

$Error.Clear()