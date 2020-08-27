using module .\Include.psm1

<#
Copyright (c) 2018 MrPlus
BalancesTrackerJob.ps1 Written by MrPlusGH https://github.com/MrPlusGH

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           BalancesTrackerJob.ps1
version:        3.9.9.0
version date:   20 August 2020
#>

#Start the log
If ($Config.Transcript) { Start-Transcript -Path ".\Logs\BalancesTracker-$(Get-Date -Format "yyyy-MM-dd").log" -Append -Force | Out-Null }

(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$TrustLevel = 0
$Variables.Earnings = [Ordered]@{ }
$LastAPIUpdateTime = (Get-Date).ToUniversalTime()

While ($true) { 
    If ($Config.BalancesTrackerPollInterval -gt 0) { 

        #Only on first run
        If (-not $Now) { 
            Write-Message "Balances Tracker started."
            # Read existing earning data
            If (Test-Path -Path ".\Logs\BalancesTrackerData.json" -PathType Leaf) { $AllBalanceObjects = @(Get-Content ".\logs\BalancesTrackerData.json" | ConvertFrom-Json) } Else { $AllBalanceObjects = @() }
            If (Test-Path -Path ".\Logs\DailyEarnings.csv" -PathType Leaf) { $DailyEarnings = @(Import-Csv ".\Logs\DailyEarnings.csv" -ErrorAction SilentlyContinue) } Else { $DailyEarnings = @() }
        }

        $Now = Get-Date
        $Date = $Now.ToString("yyyy-MM-dd")
        $CurDateUxFormat = ([DateTimeOffset]$Now.Date).ToUnixTimeMilliseconds()

        # Get pools api ref
        If (-not $PoolAPI -or ($LastAPIUpdateTime -le (Get-Date).ToUniversalTime().AddDays(-1))) { 
            # Try { 
            #     $PoolAPI = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/UpDateData/master/poolapidata.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
            #     $LastAPIUpdateTime = $Now
            #     $PoolAPI | ConvertTo-Json | Out-File ".\Config\PoolApiData.json" -Force
            # }
            # Catch { 
                If (-not $PoolAPI) { $PoolAPI = Get-Content ".\Config\PoolApiData.json" | ConvertFrom-Json }
            # }
        }

        #Get pools to track
        $PoolsToTrack = @($Config.PoolName | Where-Object { ($_ -replace "24hr" -replace "Coins") -in @($PoolAPI | Where-Object EarnTrackSupport -EQ "yes").Name })

        Write-Message "Requesting balances data ($(($PoolAPI.Name | Where-Object { $_ -in $PoolsToTrack }) -join ', '))."

        $PoolsToTrack | ForEach-Object { 
            $Pool = $_
            $PoolNorm = $_ -replace "24hr" -replace "Coins"
            $API = $PoolAPI | Where-Object Name -EQ $PoolNorm
            $APIUri = $API.WalletUri
            $PayoutThreshold = $API.PayoutThreshold
            $BalanceData = [PSCustomObject]@{ }
            $BalanceJson = $API.Balance
            $TotalJson = $API.Total
            $PoolAccountUri = $API.AccountUri
            $PoolConfig = $Config.PoolsConfig.$PoolNorm

            Switch ($PoolNorm) { 
                "MPH" { 
                    Try { 
                        $Wallet = $Config.MPHAPIKey
                        $BalanceData = (((Invoke-RestMethod -Uri "$APIUri$Wallet" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }).getuserallbalances).data | Where-Object { $_.coin -eq "bitcoin" })
                        $BalanceData | Add-Member Currency "BTC" -ErrorAction Ignore
                        If ($PoolConfig.PayoutThreshold) { $PayoutThreshold = $PoolConfig.PayoutThreshold }
                    }
                    Catch { }
                }

                "ProHashing" { 
                    Try { 
                        $Wallet = $Config.ProHashingAPIKey
                        $BalanceData = (Invoke-RestMethod -Uri "$APIUri$Wallet" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }).data.balances."BTC"
                        $BalanceData | Add-Member "total_unpaid" $BalanceData.Unpaid -Force
                        $BalanceData | Add-Member Currency $PoolConfig.PayoutCurrency -ErrorAction Ignore
                        If ($PoolConfig.PayoutThreshold) { $PayoutThreshold = $PoolConfig.PayoutThreshold }
                    }
                    Catch { }
                }
                Default { 
                    Try { 
                        $Wallet = $PoolConfig.Wallet
                        $PayoutCurrency = $PoolConfig.PayoutCurrency
                        $BalanceData = Invoke-RestMethod -Uri "$APIUri$Wallet" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }
                        $PoolAccountUri = "$($PoolAccountUri -replace '\[currency\]', $PayoutCurrency)$Wallet"
                        $BalanceData | Add-Member Currency $PayoutCurrency -ErrorAction Ignore
                        If ($PoolConfig.PayoutThreshold) { $PayoutThreshold = $PoolConfig.PayoutThreshold }
                    }
                    Catch { }
                }
            }
            If ($BalanceData.$TotalJson -gt 0) { 
                $AllBalanceObjects += $BalanceObject = [PSCustomObject]@{ 
                    Pool         = $PoolNorm
                    DateTime     = $Now
                    Balance      = $BalanceData.$BalanceJson
                    Unsold       = $BalanceData.unsold
                    Total_unpaid = $BalanceData.total_unpaid
                    Total_paid   = $BalanceData.total_paid
                    Total_earned = ($BalanceData.$BalanceJson, $BalanceData.$TotalJson | Measure-Object -Minimum).Minimum # Pool reduced balance!
                    Currency     = $BalanceData.Currency
                }

                $PoolBalanceObjects = @($AllBalanceObjects | Where-Object Pool -EQ $PoolNorm | Sort-Object Date)

                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalMinutes) -eq 0) { $Now = $Now.AddMinutes(1) }

                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) -lt 1) { 
                    $Growth1 = (($BalanceObject.total_earned - $PoolBalanceObjects[0].total_earned) / ($Now - ($PoolBalanceObjects[0].DateTime)).TotalMinutes) * 60
                }
                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) -lt 6) { 
                    $Growth6 = (($BalanceObject.total_earned - $PoolBalanceObjects[0].total_earned) / ($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) * 6
                }
                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalDays) -ge 1) { 
                    $Growth24 = $BalanceObject.total_earned - (($PoolBalanceObjects | Where-Object { $_.Date -ge $Now.AddDays(-1) }).total_earned | Measure-Object -Minimum).Minimum
                }

                $AvgBaseCurrencyHour = If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) -ge 1) { (($BalanceObject.total_earned - $PoolBalanceObjects[0].total_earned) / ($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) } Else { $Growth1 }

                $Variables.Earnings.$PoolNorm = $BalanceObject = [PSCustomObject]@{ 
                    Pool                    = $PoolNorm
                    Wallet                  = $Wallet
                    Uri                     = $PoolAccountUri
                    Date                    = $Date
                    StartTime               = $PoolBalanceObjects[0].DateTime.ToString("T")
                    Balance                 = [Double]$BalanceObject.balance
                    Unsold                  = [Double]$BalanceObject.unsold
                    Total_unpaid            = [Double]$BalanceObject.total_unpaid
                    Total_paid              = [Double]$BalanceObject.total_paid
                    Total_earned            = [Double]$BalanceObject.total_earned
                    Currency                = $BalanceObject.currency
                    PayoutThresholdCurrency = If ($Config.PoolsConfig.$PoolNorm.PayoutThresholdCurrency) { $Config.PoolsConfig.$PoolNorm.PayoutThresholdCurrency } Else { $BalanceObject.currency }
                    GrowthSinceStart        = $BalanceObject.total_earned - $PoolBalanceObjects[0].total_earned
                    Growth1                 = [Double]$Growth1
                    Growth6                 = [Double]$Growth6
                    Growth24                = [Double]$Growth24
                    AvgHourlyGrowth         = [Double]$AvgBaseCurrencyHour
                    DailyGrowth             = [Double]$AvgBaseCurrencyHour * 24
                    EstimatedEndDayGrowth   = If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) -ge 1) { [Double]($AvgBaseCurrencyHour * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) } Else { [Double]($Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) }
                    EstimatedPayDate        = If ($PayoutThreshold) { If ($BalanceObject.balance -lt $PayoutThreshold) { If ($AvgBaseCurrencyHour -gt 0) { $Now.AddHours(($PayoutThreshold - $BalanceObject.balance) / $AvgBaseCurrencyHour) } Else { "Unknown" } } Else { "Next Payout !" } } Else { "Unknown" }
                    TrustLevel              = $((($Now - ($PoolBalanceObjects[0].DateTime)).TotalMinutes / 360), 1 | Measure-Object -Minimum).Minimum
                    PayoutThreshold         = [Double]$PayoutThreshold
                    TotalHours              = ($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours
                    LastUpdated             = $Now
                }

                If ($BalancesTrackerConfig.EnableLog) { $Variables.Earnings.$PoolNorm | Export-Csv -NoTypeInformation -Append ".\Logs\BalancesTrackerLog.csv" }

                If ($PoolDailyEarning = $DailyEarnings | Where-Object Pool -EQ $PoolNorm | Where-Object Date -EQ $Date ) {
                    # pool may have reduced estimated balance, use new balance as start value to avoid negative values
                    $PoolDailyEarning.StartValue = ($PoolDailyEarning.StartValue, $BalanceObject.total_earned | Measure-Object -Minimum).Minimum
                    $PoolDailyEarning.DailyEarnings = $BalanceObject.total_earned - $PoolDailyEarning.StartValue
                    $PoolDailyEarning.EndTime = $Now.ToString("T")
                    $PoolDailyEarning.EndValue = $BalanceObject.total_earned
                    If ($BalanceObject.total_earned -lt ($PoolBalanceObjects[$PoolBalanceObjects.Count - 2].total_earned / 2)) { 
                        $PoolDailyEarning.PrePaymentDayValue = $PoolBalanceObjects[$PoolBalanceObjects.Count - 2].total_earned
                        If ($PoolDailyEarning.PrePaymentDayValue -gt 0) { 
                            #Payment occured
                            $PoolDailyEarning.DailyEarnings += $PoolDailyEarning.PrePaymentDayValue
                        }
                    }
                    $PoolDailyEarning.Balance = $BalanceObject.balance
                    $PoolDailyEarning.DailyGrowth = $BalanceObject.Growth24

                    Remove-Variable PoolDailyEarning
                }
                Else { 
                    $DailyEarnings += [PSCustomObject]@{ 
                        Date               = $Date
                        Pool               = $PoolNorm
                        DailyEarnings      = [Double]0
                        StartTime          = $Now.ToString("T")
                        StartValue         = [Double]$BalanceObject.total_earned
                        EndTime            = $Now.ToString("T")
                        EndValue           = [Double]$BalanceObject.total_earned
                        PrePaymentDayValue = [Double]0
                        Balance            = [Double]$BalanceObject.Balance
                        DailyGrowth        = [Double]$BalanceObject.Growth24
                    }
                }

                # Some pools do reset "Total" after payment (zpool)
                # Results in showing bad negative earnings
                # Detecting if current is more than 50% less than previous and reset history if so
                If ($BalanceObject -and $BalanceObject.total_earned -lt ($PoolBalanceObjects[$PoolBalanceObjects.Count - 2].total_earned / 2)) { 
                    $AllBalanceObjects = $AllBalanceObjects | Where-Object { $_.Pool -ne $PoolNorm }
                    $AllBalanceObjects += $BalanceObject
                }

                Remove-Variable BalanceData
                Remove-Variable BalanceObject
            }
        }

        $Variables.Earnings = $Variables.Earnings | Sort-Object Pools

        $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Force

        #Write chart data file (used in Web GUI)
        $ChartData = $DailyEarnings | Sort-Object StartTime | Group-Object -Property Date | Select-Object -Last 30 # days

        #One dataset per pool
        $PoolData = [PSCustomObject]@{}
        $ChartData.Group.Pool | Sort-Object -Unique | ForEach-Object { 
            $PoolData | Add-Member @{ $_ = [Double[]]@() }
        }

        $CumulatedEarnings = [Double[]]@()
        #Fill dataset
        ForEach ($PoolDailyEarning in $ChartData) { 
            $CumulatedEarnings += ([Double]($PoolDailyEarning.Group | Measure-Object DailyEarnings -Sum).Sum)
            $PoolData | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                $PoolData.$_ += [Double]($PoolDailyEarning.Group | Where-Object Pool -EQ $_).DailyEarnings
            }
        }
        
        [PSCustomObject]@{
            CumulatedEarnings = $CumulatedEarnings #Dataset for cumulated earnings
            Currency = ($Config.Currency | Select-Object -Index 0)
            Labels = @(
                $ChartData.Group.Date | Sort-Object -Unique | ForEach-Object { 
                    [DateTime]::parseexact($_, "yyyy-MM-dd", $null).ToShortDateString()
                }
            )
            #Use dates for x-axis label
            Pools = $PoolData
        } | ConvertTo-Json | Out-File ".\Logs\EarningsChartData.json" -Encoding UTF8

        #Keep only last 7 days
        If ($AllBalanceObjects.Count -gt 1) { $AllBalanceObjects = $AllBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddDays(-7) } }
        If ($AllBalanceObjects.Count -ge 1) { $AllBalanceObjects | ConvertTo-Json | Out-File ".\Logs\BalancesTrackerData.json" }

    }

    # Sleep until next update (at least 3 minutes)
    Start-Sleep -Seconds (60 * (1, $Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum)
}

Write-Message "Balances Tracker stopped."
