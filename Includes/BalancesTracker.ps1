using module .\Include.psm1

<#
Copyright (c) 2018 Nemos, MrPlus & UselessGuru
BalancesTrackerJob.ps1 Written by MrPlusGH https://github.com/MrPlusGH & UseLessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           BalancesTracker.ps1
Version:        4.0.0.23
Version date:   14 March 2022
#>

# Start transcript log
If ($Config.Transcript) { Start-Transcript -Path ".\Logs\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_-$(Get-Date -Format "yyyy-MM-dd").log" -Append -Force | Out-Null }

(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$Balances = [Ordered]@{ }
$BalanceObjects = @()
$AllBalanceObjects = @()
$Earnings = @()

# Get pools last earnings
$Variables.PoolsLastEarnings = If (Test-Path -Path ".\Data\PoolsLastEarnings.json" -PathType Leaf) { Get-Content ".\Data\PoolsLastEarnings.json" | ConvertFrom-Json | Get-SortedObject } Else { [Ordered]@{ } }

# Get pools data
$PoolData = If (Test-Path -Path ".\Data\PoolData.json" -PathType Leaf) { Get-Content ".\Data\PoolData.json" | ConvertFrom-Json } Else { [PSCustomObject]@{ } }

# Read existing earning data, use data from last file
ForEach ($Filename in (Get-ChildItem ".\Data\BalancesTrackerData*.json" | Sort-Object -Descending)) { 
    $AllBalanceObjects = (Get-Content $Filename | ConvertFrom-Json) | Where-Object Balance -NE $null
    If ($AllBalanceObjects.Count -gt ($PoolData.Count / 2)) { 
        $Variables.BalanceData = $AllBalanceObjects
        Break
    }
}
If ($AllBalanceObjects -isnot [Array]) { $AllBalanceObjects = @() }
Else { $AllBalanceObjects | ForEach-Object { $_.DateTime = [DateTime]$_.DateTime } }

# Read existing earning data, use data from last file
ForEach($Filename in (Get-ChildItem ".\Data\DailyEarnings*.csv" | Sort-Object -Descending)) { 
    $Earnings = @(Import-Csv $FileName -ErrorAction SilentlyContinue)
    If ($Earnings.Count -gt $PoolData.Count / 2) { Break }
}
Remove-Variable FileName -ErrorAction Ignore

While ($true) { 

    If ($Config.BalancesTrackerPollInterval -gt 0) { 

        If ($Now.Date -ne (Get-Date).Date) { 
            # Keep a copy on start & at date change
            If (Test-Path -Path ".\Data\BalancesTrackerData.json" -PathType Leaf) { Copy-Item -Path ".\Data\BalancesTrackerData.json" -Destination ".\Data\BalancesTrackerData_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").json" }
            If (Test-Path -Path ".\Data\DailyEarnings.csv" -PathType Leaf) { Copy-Item -Path ".\Data\DailyEarnings.csv" -Destination ".\Data\DailyEarnings_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").csv" }
            # Keep only the last 3 logs
            Get-ChildItem ".\Data\BalancesTrackerData_*.json" | Sort-Object | Select-Object -Skiplast 3 | Remove-Item -Force -Recurse
            Get-ChildItem ".\Data\DailyEarnings_*.csv" | Sort-Object | Select-Object -Skiplast 3 | Remove-Item -Force -Recurse
        }

        $Now = (Get-Date).ToUniversalTime()

        # Get pools to track
        $PoolsToTrack = @(Get-PoolBaseName (Get-ChildItem ".\Balances\*.ps1" -File).BaseName) | Sort-Object -Unique | Where-Object { $_ -notin $Config.BalancesTrackerIgnorePool }

        # Fetch balances data from pools
        $BalanceObjects = @($BalanceObjects | Where-Object { $_.Pool -ne "ProHashing" -or $_.DateTime -gt $Now.AddHours((Get-TimeZone -ID "Eastern Standard Time").BaseUtcOffset.totalhours).Date }) # ProHashing does not send balance if all is paid -> remove from balances
        If ($PoolsToTrack) { Write-Message "Balances Tracker is requesting data from pool$(If ($PoolsToTrack.Count -gt 1) { "s" }) '$($PoolsToTrack -join ', ')'..." }
        $PoolsToTrack | ForEach-Object { $BalanceObjects += @(& ".\Balances\$($_).ps1") }

        # Keep most recent balance objects, keep empty balances for 7 days
        $BalanceObjects = @(@($BalanceObjects + $AllBalanceObjects) | Where-Object Pool -notin @($Config.BalancesTrackerIgnorePool) | Where-Object { $_.Unpaid -gt 0 -or (($_.Pending -gt 0 -or $_.Balance -gt 0) -and $_.DateTime -gt $Now.AddDays(-7)) } | Where-Object { $_.Wallet } | Group-Object Pool, Currency, Wallet | ForEach-Object { $_.Group | Sort-Object DateTime | Select-Object -Last 1 })

        # Fix for pool reporting incorrect currency, e.g ZergPool ZER instead of BTC
        $BalanceObjects = @($BalanceObjects | Where-Object { $_.Pool -match "^MiningPoolHub(|Coins)$|^ProHashing(|24h)$" }) + @($BalanceObjects | Where-Object { $_.Pool -notmatch "^MiningPoolHub(|Coins)$|^ProHashing(|24h)$" } | Group-Object Pool, Wallet | ForEach-Object { $_.Group | Sort-Object DateTime | Select-Object -Last 1 })

        # Read exchange rates
        $Variables.BalancesCurrencies = @($BalanceObjects.Currency | Select-Object -Unique)
        $Variables.AllCurrencies = @((@($Config.Currency) + @($Config.Wallets.PSObject.Properties.Name) + @($Config.ExtraCurrencies) + @($Variables.BalancesCurrencies)) | Select-Object -Unique)
        If (-not $Variables.Rates.BTC.($Config.Currency) -or $Config.ExtraCurrencies -ne $Variables.ExtraCurrencies -or $Config.BalancesTrackerPollInterval -lt 1 -or ($Variables.RatesUpdated -lt (Get-Date).ToUniversalTime().AddMinutes(-3))) { Get-Rate }

        $BalanceObjects | Where-Object { $_.DateTime -gt $Now } | ForEach-Object { 
            $PoolBalanceObject = $_

            $PoolBalanceObjects = @($AllBalanceObjects | Where-Object Pool -EQ $PoolBalanceObject.Pool | Where-Object Currency -EQ $PoolBalanceObject.Currency | Where-Object Wallet -EQ $PoolBalanceObject.Wallet | Sort-Object DateTime)

            # Get threshold currency and value
            $PayoutThresholdCurrency = $PoolBalanceObject.Currency
            $PayoutThreshold = $PoolBalanceObject.PayoutThreshold

            If (-not $PayoutThreshold) { $PayoutThreshold = [Double]($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").Variant.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) }
            If (-not $PayoutThreshold) { $PayoutThreshold = [Double]($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold.$PayoutThresholdCurrency) }
            If (-not $PayoutThreshold) { $PayoutThreshold = [Double]($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) }

            If (-not $PayoutThreshold -and $PoolBalanceObject.Currency -eq "BTC") { 
                $PayoutThresholdCurrency = "mBTC"
                If (-not $PayoutThreshold) { $PayoutThreshold = [Double]($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").Variant.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) }
                If (-not $PayoutThreshold) { $PayoutThreshold = [Double]($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold.$PayoutThresholdCurrency) }
                If (-not $PayoutThreshold) { $PayoutThreshold = [Double]($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) }
            }

            If (-not $PayoutThreshold) { 
                $PayoutThreshold = If ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*" -like "* *") { [Double](($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*" -split ' ' | Select-Object -First 1) * $Variables.Rates.$PayoutThresholdCurrency.($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold."*" -split ' ' | Select-Object -Index 1)) } Else { [Double]($PoolConfig.PayoutThreshold."*") }
            }

            If ($PayoutThresholdCurrency -eq "BTC" -and $Config.UsemBTC -eq $true) { 
                $PayoutThresholdCurrency = "mBTC"
                $PayoutThreshold *= 1000
            }

            $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = $GrowthToday = $AvgHourlyGrowth = $AvgDailyGrowth = $AvgWeeklyGrowth = $Delta = $Payout = $HiddenPending = [Double]0

            If ($PoolBalanceObjects.Count -eq 0) { 
                $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObject.Unpaid))
                $PoolBalanceObject | Add-Member Payout ([Double](0))
                $PoolBalanceObject | Add-Member Total ([Double]($PoolBalanceObject.Unpaid))
                $PoolBalanceObject | Add-Member Delta ([Double]0)

                $PoolBalanceObjects += $PoolBalanceObject
                $AllBalanceObjects += $PoolBalanceObject

                $AvgHourlyGrowth = $AvgDailyGrowth = $AvgWeeklyGrowth = 0
            }
            Else { 
                If ($PoolBalanceObject.Pool -like "NiceHash*") { 
                    If ($PoolBalanceObject.Withdrawal -gt 0) { 
                        # NiceHash temporarily reduces 'Balance' value before paying out
                        $PoolBalanceObject.Balance += $PoolBalanceObject.Withdrawal
                        $Payout = 0
                    }
                    ElseIf (($PoolBalanceObjects | Select-Object -Last 1).Withdrawal -gt 0 -and $PoolBalanceObject.Withdrawal -eq 0) { 
                        # Payout occurred
                        $Payout = ($PoolBalanceObjects | Select-Object -Last 1).Withdrawal
                    }
                    ElseIf ($PoolBalanceObject.Withdrawal -eq 0) { 
                        # NiceHash temporarily hides some 'pending' value while processing payouts
                        If ($PoolBalanceObject.Pending -lt ($PoolBalanceObjects | Select-Object -Last 1).Pending) { 
                            $HiddenPending = ($PoolBalanceObjects | Select-Object -Last 1).Pending - $PoolBalanceObject.Pending
                            $PoolBalanceObject | Add-Member HiddenPending ([Double]$HiddenPending)
                        }
                        # When payouts are processed the hidden pending value gets added to the balance
                        If (($PoolBalanceObjects | Select-Object -Last 1).HiddenPending -gt 0) { 
                            If ($PoolBalanceObject.Balance -eq (($PoolBalanceObjects | Select-Object -Last 1).Balance)) { 
                                # Payout processing complete
                                $HiddenPending *= -1
                            }
                            Else { 
                                # Still processing payouts
                                $HiddenPending = ($PoolBalanceObjects | Select-Object -Last 1).HiddenPending
                                $PoolBalanceObject | Add-Member HiddenPending ([Double]$HiddenPending)
                            }
                        }
                        If (($PoolBalanceObjects | Select-Object -Last 1).Unpaid -gt $PoolBalanceObject.Unpaid) { 
                            $Payout = ($PoolBalanceObjects | Select-Object -Last 1).Unpaid - $PoolBalanceObject.Unpaid
                        }
                        Else { 
                            $Payout = 0
                        }
                    }
                    $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects | Select-Object -Last 1).Unpaid
                    $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta + $HiddenPending + $Payout)
                }
                ElseIf ($PoolBalanceObject.Pool -match "^MiningPoolHub(|Coins)$") { 
                    # MiningHubPool never reduces earnings
                    $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects | Select-Object -Last 1).Unpaid
                    If ($Delta -lt 0) { 
                        # Payout occured
                        $Payout = $Delta * -1
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings)
                    }
                    Else { 
                        $Payout = 0
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta)
                    }
                }
                ElseIf ($PoolBalanceObject.Pool -match "^ProHashing.*") { 
                    # ProHashing never reduces earnings
                    $Delta = $PoolBalanceObject.Balance - ($PoolBalanceObjects | Select-Object -Last 1).Balance
                    If ($PoolBalanceObject.Unpaid -lt ($PoolBalanceObjects | Select-Object -Last 1).Unpaid) { 
                        # Payout occured
                        $Payout = ($PoolBalanceObjects | Select-Object -Last 1).Unpaid - $PoolBalanceObject.Unpaid
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $PoolBalanceObject.Unpaid)
                    }
                    Else { 
                        $Payout = 0
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta)
                    }
                }
                Else { 
                    # BlockMasters, BlazePool, HiveON, NLPool, ZergPool, ZPool
                    $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects | Select-Object -Last 1).Unpaid
                    # Current 'Unpaid' is smaller
                    If ($Delta -lt 0) { 
                        If (($Delta * -1) -gt $(If ($PayoutThresholdCurrency -eq "mBTC") { $PayoutThreshold / 1000 } Else { $PayoutThreshold }) * 0.5) { 
                            # Payout occured (delta > 50% of payout limit)
                            $Payout = $Delta * -1
                        }
                        Else { 
                            # Pool reduced earnings
                            $Payout = $Delta = 0
                        }
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings)
                    }
                    Else { 
                        $Payout = 0
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta)
                    }
                }
                $PoolBalanceObject | Add-Member Payout ([Double]$Payout)
                $PoolBalanceObject | Add-Member Paid ([Double](($PoolBalanceObjects.Paid | Measure-Object -Maximum).Maximum + $Payout)) -Force
                $PoolBalanceObject | Add-Member Delta ([Double]$Delta)

                If ((($Now - $PoolBalanceObjects[0].DateTime).TotalHours) -lt 1) { 
                    # Only calculate if current balance data
                    If ($PoolBalanceObject.DateTime -gt $Now.AddMinutes(-1)) { 
                        $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = [Double]($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings)
                    }
                }
                Else { 
                    # Only calculate if current balance data
                    If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-1) })   { $Growth1 =   [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-1) } | Sort-Object Date | Select-Object -First 1).Earnings) }
                    If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-6) })   { $Growth6 =   [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-6) } | Sort-Object Date | Select-Object -First 1).Earnings) }
                    If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-24) })  { $Growth24 =  [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-24) } | Sort-Object Date | Select-Object -First 1).Earnings) }
                    If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-168) }) { $Growth168 = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-168) } | Sort-Object Date | Select-Object -First 1).Earnings) }
                    If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-720) }) { $Growth720 = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-720) } | Sort-Object Date | Select-Object -First 1).Earnings) }
                }


                $AvgHourlyGrowth = If ($PoolBalanceObjects | Where-Object { $_.DateTime -lt $Now.AddHours(-1) }) { [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - $PoolBalanceObjects[0].DateTime).TotalHours) } Else { $Growth1 }
                $AvgDailyGrowth = If ($PoolBalanceObjects | Where-Object { $_.DateTime -lt $Now.AddDays(-1) }) { [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - $PoolBalanceObjects[0].DateTime).TotalDays) } Else { $Growth24 }
                $AvgWeeklyGrowth = If ($PoolBalanceObjects | Where-Object { $_.DateTime -lt $Now.AddDays(-7) } ) { [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - $PoolBalanceObjects[0].DateTime).TotalDays * 7) } Else { $Growth168 }

                If ($PoolBalanceObjects | Where-Object { $_.DateTime.Date -eq $Now.Date }) { 
                    $GrowthToday = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime.Date -eq $Now.Date } | Sort-Object Date | Select-Object -First 1).Earnings)
                    If ($GrowthToday -lt 0) { $GrowthToday = 0 } # to avoid negative numbers
                }

                $PoolBalanceObjects += $PoolBalanceObject
                $AllBalanceObjects += $PoolBalanceObject
            }

            $Balances."$($PoolBalanceObject.Pool) ($($PoolBalanceObject.Currency):$($PoolBalanceObject.Wallet))" = $EarningsObject = [PSCustomObject]@{ 
                Pool                    = $PoolBalanceObject.Pool
                Wallet                  = $PoolBalanceObject.Wallet
                Currency                = $PoolBalanceObject.Currency
                Start                   = $PoolBalanceObjects[0].DateTime
                LastUpdated             = $PoolBalanceObject.DateTime
                Pending                 = [Double]$PoolBalanceObject.Pending
                Balance                 = [Double]$PoolBalanceObject.Balance
                Unpaid                  = [Double]$PoolBalanceObject.Unpaid
                Earnings                = [Double]$PoolBalanceObject.Earnings
                Delta                   = [Double]$PoolBalanceObject.Delta
                Growth1                 = [Double]$Growth1
                Growth6                 = [Double]$Growth6
                Growth24                = [Double]$Growth24
                Growth168               = [Double]$Growth168
                Growth720               = [Double]$Growth720
                GrowthToday             = [Double]$GrowthToday
                AvgHourlyGrowth         = [Double]$AvgHourlyGrowth
                AvgDailyGrowth          = [Double]$AvgDailyGrowth
                AvgWeeklyGrowth         = [Double]$AvgWeeklyGrowth
                ProjectedEndDayGrowth   = If (($Now - $PoolBalanceObjects[0].DateTime).TotalHours -ge 1) { [Double]($AvgHourlyGrowth * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) } Else { [Double]($Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) }
                ProjectedPayDate        = If ($PayoutThreshold) { If ([Double]$PoolBalanceObject.Balance -lt $PayoutThreshold * $Variables.Rates.$PayoutThresholdCurrency.($PoolBalanceObject.Currency)) { If (($AvgDailyGrowth, $Growth24 | Measure-Object -Maximum).Maximum -gt 1E-7) { [DateTime]$Now.AddDays(($PayoutThreshold * $Variables.Rates.$PayoutThresholdCurrency.($PoolBalanceObject.Currency) - $PoolBalanceObject.Balance) / (($AvgDailyGrowth, $Growth24) | Measure-Object -Maximum).Maximum) } Else { "Unknown" } } Else { If ($PoolBalanceObject.NextPayout) { $PoolBalanceObject.NextPayout } Else { "Next Payout!" } } } Else { "Unknown" }
                TrustLevel              = [Double]((($Now - $PoolBalanceObjects[0].DateTime).TotalHours / 168), 1 | Measure-Object -Minimum).Minimum
                TotalHours              = [Double]($Now - $PoolBalanceObjects[0].DateTime).TotalHours
                PayoutThresholdCurrency = $PayoutThresholdCurrency
                PayoutThreshold         = [Double]$PayoutThreshold
                Payout                  = [Double]$PoolBalanceObject.Payout
                Uri                     = $PoolBalanceObject.Url
                LastEarnings            = If ($Growth24 -gt 0) { $PoolBalanceObject.DateTime } Else { $PoolBalanceObjects[0].DateTime }
            }

            If ($Config.BalancesTrackerLog -eq $true) { 
                $EarningsObject | Export-Csv -NoTypeInformation -Append ".\Logs\BalancesTrackerLog.csv" -Force -ErrorAction Ignore
            }

            $PoolTodayEarning = $Earnings | Where-Object Pool -EQ $PoolBalanceObject.Pool | Where-Object Currency -EQ $PoolBalanceObject.Currency | Where-Object Wallet -EQ $PoolBalanceObject.Wallet | Select-Object -Last 1

            If ([String]$PoolTodayEarning.Date -eq $Now.ToLocalTime().ToString("yyyy-MM-dd")) { 
                $PoolTodayEarning.DailyEarnings = [Double]$GrowthToday
                $PoolTodayEarning.EndTime = $Now.ToLocalTime().ToString("T")
                $PoolTodayEarning.EndValue = [Double]$PoolBalanceObject.Earnings
                $PoolTodayEarning.Balance = [Double]$PoolBalanceObject.Balance
                $PoolTodayEarning.Unpaid = [Double]$PoolBalanceObject.Unpaid
                $PoolTodayEarning.Payout = [Double]$PoolTodayEarning.Payout + [Double]$PoolBalanceObject.Payout
            }
            Else { 
                $Earnings += [PSCustomObject]@{ 
                    Date          = $Now.ToLocalTime().ToString("yyyy-MM-dd")
                    Pool          = $EarningsObject.Pool
                    Currency      = $EarningsObject.Currency
                    Wallet        = $PoolBalanceObject.Wallet
                    DailyEarnings = [Double]$GrowthToday
                    StartTime     = $Now.ToLocalTime().ToString("T")
                    StartValue    = If ($PoolTodayEarning) { [Double]$PoolTodayEarning.EndValue } Else { [Double]$EarningsObject.Earnings }
                    EndTime       = $Now.ToLocalTime().ToString("T")
                    EndValue      = [Double]$EarningsObject.Earnings
                    Balance       = [Double]$EarningsObject.Balance
                    Pending       = [Double]$EarningsObject.Pending
                    Unpaid        = [Double]$EarningsObject.Unpaid
                    Payout        = [Double]0
                }
            }

            Remove-Variable PoolTodayEarning, EarningsObject -ErrorAction Ignore
        }

        # Always keep pools sorted, even when new pools were added
        $Variables.Balances = [Ordered]@{ }
        $Balances.Keys | Where-Object { $Balances.$_.Pool -notin @($Config.BalancesTrackerIgnorePool) } | Sort-Object | ForEach-Object { 
            $Variables.Balances.$_ = $Balances.$_
            $Variables.PoolsLastEarnings.($_ -replace ' \(.+') = ($Variables.PoolsLastEarnings.($_ -replace ' \(.+'), $Balances.$_.LastEarnings | Measure-Object -Maximum).Maximum
        }
        $Variables.PoolsLastEarnings = $Variables.PoolsLastEarnings | Get-SortedObject
        $Variables.PoolsLastEarnings | ConvertTo-Json | Out-File -FilePath ".\Data\PoolsLastEarnings.json" -Force -Encoding utf8 -ErrorAction SilentlyContinue

        # Build chart data (used in Web GUI) for last 30 days
        $PoolChartData = [PSCustomObject]@{ }
        $ChartData = $Earnings | Where-Object Pool -in $PoolsToTrack | Sort-Object Date | Group-Object -Property Date | Select-Object -Last 30 # days

        # One dataset per pool
        $ChartData.Group.Pool | Sort-Object -Unique | ForEach-Object { 
            $PoolChartData | Add-Member @{ $_ = [Double[]]@() }
        }

        # Fill dataset
        ForEach ($PoolEarnings in $ChartData) { 
            $PoolChartData.PSObject.Properties.Name | ForEach-Object { 
                $PoolChartData.$_ += ($PoolEarnings.Group | Where-Object Pool -EQ $_ | ForEach-Object { [Double]$_.DailyEarnings * $Variables.Rates.($_.Currency).BTC } | Measure-Object -Sum).Sum
            }
        }

        $Variables.EarningsChartData = [PSCustomObject]@{ 
            # CumulatedEarnings = $CumulatedEarnings 
            Currency = $Config.Currency
            BTCrate = [Double]$Variables.Rates.BTC.($Config.Currency)
            Labels = @(
                $ChartData.Group.Date | Sort-Object -Unique | ForEach-Object { 
                    [DateTime]::parseexact($_, "yyyy-MM-dd", $null).ToShortDateString()
                }
            )
            # Use dates for x-axis label
            Earnings = $PoolChartData
        }

        $Variables.EarningsChartData | ConvertTo-Json | Out-File -FilePath ".\Data\EarningsChartData.json" -Force -Encoding utf8 -ErrorAction SilentlyContinue

        # At least 31 days are needed for Growth720
        If ($AllBalanceObjects.Count -gt 1) { 
            $AllBalanceObjects = @(
                $AllBalanceObjects | Where-Object DateTime -GE $Now.AddDays(-31) | Sort-Object DateTime | ForEach-Object { 
                    If ($_.Delta -ne 0 -or $_.DateTime.Date -eq $Now.Date) { $_ } # keep with delta <> 0
                    ElseIf ($Record -and $_.DateTime.Date -ne $Record.DateTime.Date) { $_ } # keep the newest one per day
                    $Record = $_
                }
            ) | Sort-Object DateTime -Descending
        }

        Try { 
            $Earnings | Export-Csv ".\Data\DailyEarnings.csv" -NoTypeInformation -Force -ErrorAction Ignore
        }
        Catch { 
            Write-Message -Level Warn "Balances Tracker failed to save earnings data to '.\Data\DailyEarnings.csv' (should have $($Earnings.count) entries)."
        }

        If ($AllBalanceObjects.Count -ge 1) { $AllBalanceObjects | ConvertTo-Json | Out-File -FilePath ".\Data\BalancesTrackerData.json" -Force -Encoding utf8 -ErrorAction SilentlyContinue }
        $Variables.BalanceData = $AllBalanceObjects

        If ($ReadBalances) { Return } # Debug stuff

        # Sleep until next update (at least 1 minute, maximum 60 minutes)
        While ((Get-Date).ToUniversalTime() -le $Now.AddMinutes((60, (1, [Int]$Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum | Measure-Object -Minimum).Minimum)) { Start-Sleep -Seconds 5 }
    }
}

Write-Message -Level INFO "Balances Tracker stopped."
