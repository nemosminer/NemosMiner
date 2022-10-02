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
File:           MiningPoolHub.ps1
Version:        4.2.1.7
Version date:   02 October 2022
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

$Headers = @{ "Cache-Control" = "no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

If ($PoolConfig.UserName) { 
    If ($PoolVariant -match "Coins$") { 
        Try { 
            $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getminingandprofitsstatistics" -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -TimeoutSec $Config.PoolAPITimeout
        }
        Catch { Return }

        If (-not $Request) { Return }

        $Divisor = 1000000000

        $Request.return | Where-Object profit | ForEach-Object { 
            $Current = $_

            $Algorithm_Norm = Get-Algorithm $_.algo
            $Currency = "$($Current.symbol)".Trim()
            $Fee = [Decimal]($_.Fee / 100)
            $Port = $Current.port

            # Add coin name
            If ($Current.coin_name -and $Currency) { [Void](Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $Current.coin_name) }

            $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)-$($Currency)_Profit" -Value ($_.profit / $Divisor) -FaultDetection $false

            # Temp fix
            $Regions = If ($Current.host_list.split(";").count -eq 1) { @("n/a") } Else { $PoolConfig.Region }

            # Temp fix for pool API errors
            Switch ($Algorithm_Norm) { 
                # "Ethash"   { $Regions = @($PoolConfig.Region | Where-Object { $_ -in @("asia", "us-east") }) }
                "KawPoW"    { $Regions = @($PoolConfig.Region | Where-Object { $_ -notin @("europe") }) }
                # "Lyra2RE2"  { $Current.host_list = $Current.host }
                "Neoscrypt" { $Current.host_list = $Current.host }
                # "Skein"     { $Current.host_list = $Current.host }
                "VertHash"    { $Current.host_list = $Current.host; $Port = 20534 }
                # Default     { $Port = $Current.port }
            }

            ForEach ($Region_Norm in $Variables.Regions.($Config.Region)) { 
                If ($Region = $Regions | Where-Object { $_ -eq "n/a" -or (Get-Region $_) -eq $Region_Norm }) { 

                    If ($Region -eq "n/a") { $Region_Norm = $Region }

                    [PSCustomObject]@{ 
                        Accuracy                 = [Double](1 - $Stat.Week_Fluctuation)
                        Algorithm                = [String]$Algorithm_Norm
                        BaseName                 = [String]$Name
                        Currency                 = [String]$Currency
                        EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                        Fee                      = $Fee
                        Host                     = [String]($Current.host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                        Name                     = [String]$PoolVariant
                        Pass                     = "x"
                        Port                     = [UInt16]$Port
                        PortSSL                  = $null
                        Price                    = [Double]$Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1)) + $Stat.Day * [Math]::Min($Stat.Day_Fluctuation, 1)
                        Region                   = [String]$Region_Norm
                        StablePrice              = [Double]$Stat.Week
                        User                     = "$($PoolConfig.UserName).$($PoolConfig.WorkerName)"
                        WorkerName               = ""
                    }
                    Break
                }
            }
        }
    }
    Else { 
        Try { 
            $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics" -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -TimeoutSec $Config.PoolAPITimeout 
        }
        Catch { Return }

        If (-not $Request) { Return }

        $Divisor = 1000000000

        $Request.return | Where-Object profit | ForEach-Object { 
            $Current = $_

            $Algorithm_Norm = Get-Algorithm $_.algo
            $Port = $Current.algo_switch_port

            $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)_Profit" -Value ([Decimal]$_.profit / $Divisor) -FaultDetection $false

            $Regions = If ($Current.all_host_list.split(";").count -eq 1) { @("n/a") } Else { $PoolConfig.Region }

            # Temp fix for pool API errors
            Switch ($Algorithm_Norm) { 
                # "Ethash"   { $Regions = @($PoolConfig.Region | Where-Object { $_ -in @("asia", "us-east") }) }
                "KawPoW"     { $Regions = @($PoolConfig.Region | Where-Object { $_ -notin @("europe") }) }
                "Neoscrypt" { $Current.host_list = $Current.host }
                "VertHash"   { $Port = 20534 }
                # Default    { $Port = $Current.algo_switch_port }
            }

            ForEach ($Region_Norm in $Variables.Regions.($Config.Region)) { 
                If ($Region = $Regions | Where-Object { $_ -eq "n/a" -or (Get-Region $_) -eq $Region_Norm }) { 

                    If ($Region -eq "n/a") { $Region_Norm = $Region }

                    [PSCustomObject]@{ 
                        Accuracy                 = [Double](1 - [Math]::Min([Math]::Abs($Stat.Week_Fluctuation), 1))
                        Algorithm                = [String]$Algorithm_Norm
                        BaseName                 = [String]$Name
                        Currency                 = [String]$Current.current_mining_coin_symbol
                        Disabled                 = [Boolean]$Stat.Disabled
                        EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                        Fee                      = [Decimal]$PoolConfig.Fee
                        Host                     = [String]($Current.all_host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                        Name                     = [String]$PoolVariant
                        Pass                     = "x"
                        Port                     = [UInt16]$Port
                        PortSSL                  = $null
                        Price                    = [Double]($Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1)) + $Stat.Day * (0 + [Math]::Min($Stat.Day_Fluctuation, 1)))
                        Region                   = [String]$Region_Norm
                        StablePrice              = [Double]$Stat.Week
                        User                     = "$($PoolConfig.UserName).$($PoolConfig.WorkerName)"
                        WorkerName               = ""
                    }
                    Break
                }
            }
        }
    }
}
