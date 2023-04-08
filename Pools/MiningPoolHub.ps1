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
File:           MiningPoolHub.ps1
Version:        4.3.4.0
Version date:   08 April 2023
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

$Headers = @{ "Cache-Control" = "no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

If ($PoolConfig.UserName) { 
    If ($PoolVariant -match "Coins$") { 
        $APICallFails = 0

        Do {
            Try { 
                $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getminingandprofitsstatistics" -Headers $Headers -SkipCertificateCheck -TimeoutSec 5 # -UserAgent $UserAgent 
            }
            Catch { 
                $APICallFails++
                Start-Sleep -Seconds ($APICallFails * 3)
            }
        } While (-not $Request -and $APICallFails -lt 3)

        If (-not $Request) { Return }

        $Divisor = 1000000000

        $Request.return | Select-Object | ForEach-Object { 
            $Current = $_

            $Algorithm_Norm = Get-Algorithm $_.algo
            $Currency = "$($Current.symbol)".Trim()
            $Fee = [Decimal]($_.Fee / 100)
            $Port = $Current.port

            # Add coin name
            If ($Current.coin_name -and $Currency) { 
                $CoinName = (Get-Culture).TextInfo.ToTitleCase($Current.coin_name.ToLower())
                Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $CoinName
            }
            Else { 
                $CoinName = ""
            }

            # Temp fix
            $Regions = If ($Current.host_list.split(";").count -eq 1) { @("n/a") } Else { $PoolConfig.Region }

            $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)-$($Currency)_Profit" -Value ($_.profit / $Divisor) -FaultDetection $false

            $Reasons = @()
            # Temp fix
            If ($Algorithm_Norm -match "Neoscrypt|Skein|Verthash" ) { $Reasons += "Connection issue at pool" }

            ForEach ($Region_Norm in $Variables.Regions.($Config.Region)) { 
                If ($Region = $Regions | Where-Object { $_ -eq "n/a" -or (Get-Region $_) -eq $Region_Norm }) { 

                    If ($Region -eq "n/a") { $Region_Norm = $Region }

                    [PSCustomObject]@{ 
                        Accuracy                 = [Double](1 - $Stat.Week_Fluctuation)
                        Algorithm                = [String]$Algorithm_Norm
                        BaseName                 = [String]$Name
                        CoinName                 = [String]$CoinName
                        Currency                 = [String]$Currency
                        EarningsAdjustmentFactor = [Double]$PoolConfig.EarningsAdjustmentFactor
                        Fee                      = $Fee
                        Host                     = [String]($Current.host_list.split(";") | Sort-Object -Descending { $_ -ilike "$Region*" } | Select-Object -First 1)
                        Name                     = [String]$PoolVariant
                        Pass                     = "x"
                        Port                     = [UInt16]$Port
                        PortSSL                  = $null
                        Price                    = [Double]$Stat.Live * (1 - [Math]::Min($Stat.Day_Fluctuation, 1)) + $Stat.Day * [Math]::Min($Stat.Day_Fluctuation, 1)
                        Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratumnh" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                        Reasons                  = $Reasons
                        Region                   = [String]$Region_Norm
                        SendHashrate             = $false
                        SSLSelfSignedCertificate = $true
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
        $APICallFails = 0

        Do {
            Try { 
                $Request = Invoke-RestMethod -Uri "https://miningpoolhub.com/index.php?page=api&action=getautoswitchingandprofitsstatistics" -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -TimeoutSec 5
            }
            Catch { 
                $APICallFails++
                Start-Sleep -Seconds ($APICallFails * 3)
            }
        } While (-not $Request -and $APICallFails -lt 3)

        If (-not $Request) { Return }

        $Divisor = 1000000000

        $Request.return | Select-Object | ForEach-Object { 
            $Current = $_

            $Algorithm_Norm = Get-Algorithm $_.algo
            $Port = $Current.algo_switch_port

            $Regions = If ($Current.all_host_list.split(";").count -eq 1) { @("n/a") } Else { $PoolConfig.Region }

            $Stat = Set-Stat -Name "$($PoolVariant)_$($Algorithm_Norm)_Profit" -Value ([Decimal]$_.profit / $Divisor) -FaultDetection $false

            $Reasons = @()
            # Temp fix
            If ($Algorithm_Norm -match "Neoscrypt|Skein|Verthash" ) { $Reasons += "Connection issue at pool" }

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
                        Protocol                 = If ($Algorithm_Norm -match $Variables.RegexAlgoIsEthash) { "ethstratumnh" } ElseIf ($Algorithm_Norm -match $Variables.RegexAlgoIsProgPow) { "stratum" } Else { "" }
                        Reasons                  = $Reasons
                        Region                   = [String]$Region_Norm
                        StablePrice              = [Double]$Stat.Week
                        SSLSelfSignedCertificate = $true
                        User                     = "$($PoolConfig.UserName).$($PoolConfig.WorkerName)"
                        WorkerName               = ""
                    }
                    Break
                }
            }
        }
    }
}

$Error.Clear()