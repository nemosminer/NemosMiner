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
Version:        4.3.4.7
Version date:   13 May 2023
#>

Do {
    # Start transcript log
    If ($Config.Transcript) { Start-Transcript -Path ".\Logs\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_-$(Get-Date -Format "yyyy-MM-dd").log" -Append -Force | Out-Null }

    (Get-Process -Id $PID).PriorityClass = "BelowNormal"

    $Variables.BalanceData = @()
    $Earnings = @()

    # Get pools last earnings
    $Variables.PoolsLastEarnings = If (Test-Path -Path ".\Data\PoolsLastEarnings.json" -PathType Leaf) { Get-Content ".\Data\PoolsLastEarnings.json" | ConvertFrom-Json | Get-SortedObject } Else { @{ } }

    # Get pools data
    $PoolData = If (Test-Path -Path ".\Data\PoolData.json" -PathType Leaf) { Get-Content ".\Data\PoolData.json" | ConvertFrom-Json } Else { [PSCustomObject]@{ } }

    # Read existing earning data, use data from last file
    ForEach ($Filename in (Get-ChildItem ".\Data\BalancesTrackerData*.json" | Sort-Object -Descending)) { 
        $Variables.BalanceData = (Get-Content $Filename | ConvertFrom-Json)
        If ($Variables.BalanceData.Count -gt ($PoolData.Count / 2)) { Break }
    }
    Remove-Variable FileName -ErrorAction Ignore
    If ($Variables.BalanceData -isnot [Array]) { $Variables.BalanceData = @() }
    $Variables.BalanceData | ForEach-Object { $_.DateTime = [DateTime]$_.DateTime }

    # Read existing earning data, use data from last file
    ForEach($Filename in (Get-ChildItem ".\Data\DailyEarnings*.csv" | Sort-Object -Descending)) { 
        $Earnings = @(Import-Csv $FileName -ErrorAction SilentlyContinue)
        If ($Earnings.Count -gt $PoolData.Count / 2) { Break }
    }

    If ($Config.BalancesTrackerPollInterval -gt 0) { Write-Message -Level Info "Balances Tracker is running." }

    While ($Config.BalancesTrackerPollInterval -gt 0) { 

        $Balances = [Ordered]@{ }
        $BalanceObjects = @()

        If ($Now.Date -ne (Get-Date).Date) { 
            # Keep a copy on start & at date change
            If (Test-Path -Path ".\Data\BalancesTrackerData.json" -PathType Leaf) { Copy-Item -Path ".\Data\BalancesTrackerData.json" -Destination ".\Data\BalancesTrackerData_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").json" }
            If (Test-Path -Path ".\Data\DailyEarnings.csv" -PathType Leaf) { Copy-Item -Path ".\Data\DailyEarnings.csv" -Destination ".\Data\DailyEarnings_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").csv" }
            # Keep only the last 3 logs
            Get-ChildItem ".\Data\BalancesTrackerData_*.json" | Sort-Object | Select-Object -Skiplast 3 | Remove-Item -Force -Recurse
            Get-ChildItem ".\Data\DailyEarnings_*.csv" | Sort-Object | Select-Object -Skiplast 3 | Remove-Item -Force -Recurse
        }

        $Now = (Get-Date)

        # Get pools to track
        $PoolsToTrack = @(Get-PoolBaseName (Get-ChildItem ".\Balances\*.ps1" -File).BaseName) | Sort-Object | Where-Object { $_ -notin $Config.BalancesTrackerExcludePool }

        # Fetch balances data from pools
        If ($PoolsToTrack) { 
            Write-Message -Level Info "Balances Tracker is requesting data from pool$(If ($PoolsToTrack.Count -gt 1) { "s" }) '$($PoolsToTrack -join ', ')'..."
            $PoolsToTrack | ForEach-Object { $BalanceObjects += @(& ".\Balances\$($_).ps1") }

            # Keep most recent balance objects, keep empty balances for 7 days
            $BalanceObjects = @(@($BalanceObjects + $Variables.BalanceData) | Where-Object Pool -notin @($Config.BalancesTrackerExcludePool) | Where-Object { $_.Unpaid -gt 0 -or $_.DateTime -gt $Now.AddDays(-7) } | Where-Object { $_.Wallet } | Group-Object Pool, Currency, Wallet | ForEach-Object { $_.Group | Sort-Object DateTime -Bottom 1 })

            # Fix for pool reporting incorrect currency, e.g ZergPool ZER instead of BTC
            $BalanceObjects = @($BalanceObjects | Where-Object { $_.Pool -match "^MiningDutch.*|^MiningPoolHub.*|$|^ProHashing.*$" }) + @($BalanceObjects | Where-Object { $_.Pool -notmatch "^MiningDutch.*|^MiningPoolHub.*|$|^ProHashing.*$" } | Group-Object Pool, Wallet | ForEach-Object { $_.Group | Sort-Object DateTime -Bottom 1 })

            # Do not keep balances with 0
            $BalanceObjects = $BalanceObjects | Where-Object { $_.Balance -gt 0 }

            # Read exchange rates
            Get-Rate | Out-Null

            $BalanceObjects | ForEach-Object { 
                $PoolBalanceObject = $_

                $PoolBalanceObjects = @($Variables.BalanceData | Where-Object Pool -EQ $PoolBalanceObject.Pool | Where-Object Currency -EQ $PoolBalanceObject.Currency | Where-Object Wallet -EQ $PoolBalanceObject.Wallet | Sort-Object DateTime)

                # Get threshold currency and value
                $PayoutThreshold = $PoolBalanceObject.PayoutThreshold

                $PayoutThresholdCurrency = $PoolBalanceObject.Currency

                If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").Variant.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double] }
                If (-not $PayoutThreshold) { 
                    If ($Currency = $Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold."*".Keys) { 
                        $PayoutThreshold = ($Variables.Rates.$Currency.$PayoutThresholdCurrency * $Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold."*"."$Currency") -as [Double]
                    }
                    Else { 
                        $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold."*") -as [Double]
                    }
                }

                If (-not $PayoutThreshold -and $PoolBalanceObject.Currency -eq "BTC") { 
                    $PayoutThresholdCurrency = "mBTC"
                    If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").Variant.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                    If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                    If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool).PayoutThreshold.$PayoutThresholdCurrency) -as [Double] }
                    If (-not $PayoutThreshold) { $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold."*".$PayoutThresholdCurrency) -as [Double] }
                    If (-not $PayoutThreshold) { 
                        If ($Currency = $Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold."*".Keys) { 
                            $PayoutThreshold = ($Variables.Rates.$Currency.$PayoutThresholdCurrency * $Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold."*"."$Currency") -as [Double]
                        }
                        Else { 
                            $PayoutThreshold = ($Config.PoolsConfig.($PoolBalanceObject.Pool -replace " External$| Internal$").PayoutThreshold."*") -as [Double]
                        }
                    }
                }

                If ($PayoutThresholdCurrency -eq "mBTC") { 
                    $PayoutThresholdCurrency = "BTC"
                    $PayoutThreshold /= 1000
                }

                $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = $GrowthToday = $AvgHourlyGrowth = $AvgDailyGrowth = $AvgWeeklyGrowth = $Delta = $Payout = $HiddenPending = [Double]0

                If ($PoolBalanceObjects.Count -eq 0) { 
                    $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObject.Unpaid))
                    $PoolBalanceObject | Add-Member Payout ([Double]0)
                    $PoolBalanceObject | Add-Member Total ([Double]($PoolBalanceObject.Unpaid))
                    $PoolBalanceObject | Add-Member Delta ([Double]0)

                    $PoolBalanceObjects += $PoolBalanceObject
                    $Variables.BalanceData += $PoolBalanceObject

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
                        $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta + $HiddenPending + $Payout) -Force
                    }
                    ElseIf ($PoolBalanceObject.Pool -eq "MiningPoolHub") { 
                        # MiningHubPool never reduces earnings
                        $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects | Select-Object -Last 1).Unpaid
                        If ($Delta -lt 0) { 
                            # Payout occured
                            $Payout = -$Delta
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings) -Force
                        }
                        Else { 
                            $Payout = 0
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta) -Force
                        }
                    }
                    ElseIf ($PoolBalanceObject.Pool -match "^ProHashing.*") { 
                        # ProHashing never reduces earnings
                        $Delta = $PoolBalanceObject.Balance - ($PoolBalanceObjects | Select-Object -Last 1).Balance
                        If ($PoolBalanceObject.Unpaid -lt ($PoolBalanceObjects | Select-Object -Last 1).Unpaid) { 
                            # Payout occured
                            $Payout = ($PoolBalanceObjects | Select-Object -Last 1).Unpaid - $PoolBalanceObject.Unpaid
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $PoolBalanceObject.Unpaid) -Force
                        }
                        Else { 
                            $Payout = 0
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta) -Force
                        }
                    }
                    Else { 
                        # HashCryptos, Hiveon, MiningDutch, ZergPool, ZPool
                        $Delta = $PoolBalanceObject.Unpaid - ($PoolBalanceObjects | Select-Object -Last 1).Unpaid
                        # Current 'Unpaid' is smaller
                        If ($Delta -lt 0) { 
                            If (-$Delta -gt $PayoutThreshold * 0.5) { 
                                # Payout occured (delta > 50% of payout limit)
                                $Payout = -$Delta
                            }
                            Else { 
                                # Pool reduced earnings
                                $Payout = $Delta = 0
                            }
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings) -Force
                        }
                        Else { 
                            $Payout = 0
                            $PoolBalanceObject | Add-Member Earnings ([Double]($PoolBalanceObjects | Select-Object -Last 1).Earnings + $Delta) -Force
                        }
                    }
                    $PoolBalanceObject | Add-Member Payout ([Double]$Payout) -Force
                    $PoolBalanceObject | Add-Member Paid ([Double](($PoolBalanceObjects.Paid | Measure-Object -Maximum).Maximum + $Payout)) -Force
                    $PoolBalanceObject | Add-Member Delta ([Double]$Delta) -Force

                    If ((($Now - $PoolBalanceObjects[0].DateTime).TotalHours) -lt 1) { 
                        # Only calculate if current balance data
                        If ($PoolBalanceObject.DateTime -gt $Now.AddMinutes(-1)) { 
                            $Growth1 = $Growth6 = $Growth24 = $Growth168 = $Growth720 = [Double]($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings)
                        }
                    }
                    Else { 
                        # Only calculate if current balance data
                        If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-1) })   { $Growth1 =   [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-1) }   | Sort-Object Date -Top 1).Earnings) }
                        If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-6) })   { $Growth6 =   [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-6) }   | Sort-Object Date -Top 1).Earnings) }
                        If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-24) })  { $Growth24 =  [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-24) }  | Sort-Object Date -Top 1).Earnings) }
                        If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-168) }) { $Growth168 = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-168) } | Sort-Object Date -Top 1).Earnings) }
                        If ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-720) }) { $Growth720 = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours(-720) } | Sort-Object Date -Top 1).Earnings) }
                    }


                    $AvgHourlyGrowth = If ($PoolBalanceObjects | Where-Object { $_.DateTime -lt $Now.AddHours(-1) }) { [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - $PoolBalanceObjects[0].DateTime).TotalHours) }    Else { $Growth1 }
                    $AvgDailyGrowth =  If ($PoolBalanceObjects | Where-Object { $_.DateTime -lt $Now.AddDays(-1) })  { [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - $PoolBalanceObjects[0].DateTime).TotalDays) }     Else { $Growth24 }
                    $AvgWeeklyGrowth = If ($PoolBalanceObjects | Where-Object { $_.DateTime -lt $Now.AddDays(-7) })  { [Double](($PoolBalanceObject.Earnings - $PoolBalanceObjects[0].Earnings) / ($Now - $PoolBalanceObjects[0].DateTime).TotalDays * 7) } Else { $Growth168 }

                    If ($PoolBalanceObjects | Where-Object { $_.DateTime.Date -eq $Now.Date }) { 
                        $GrowthToday = [Double]($PoolBalanceObject.Earnings - ($PoolBalanceObjects | Where-Object { $_.DateTime.Date -eq $Now.Date } | Sort-Object Date | Select-Object -First 1).Earnings)
                        If ($GrowthToday -lt 0) { $GrowthToday = 0 } # to avoid negative numbers
                    }

                    $PoolBalanceObjects += $PoolBalanceObject
                    $Variables.BalanceData += $PoolBalanceObject
                }

                Try {
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
                        ProjectedPayDate        = If ($PayoutThreshold) { If ([Double]$PoolBalanceObject.Balance -lt $PayoutThreshold * $Variables.Rates.$PayoutThresholdCurrency.($PoolBalanceObject.Currency)) { If (($AvgDailyGrowth, $Growth24 | Measure-Object -Maximum).Maximum -gt 1E-7) { [DateTime]$Now.AddDays(($PayoutThreshold * $Variables.Rates.$PayoutThresholdCurrency.($PoolBalanceObject.Currency) - $PoolBalanceObject.Balance) / (($AvgDailyGrowth, $Growth24) | Measure-Object -Maximum).Maximum) } Else { "Unknown" } } Else { If ($PoolBalanceObject.NextPayout) { $PoolBalanceObject.NextPayout } Else { "Next pool payout" } } } Else { "Unknown" }
                        TrustLevel              = [Double]((($Now - $PoolBalanceObjects[0].DateTime).TotalHours / 168), 1 | Measure-Object -Minimum).Minimum
                        TotalHours              = [Double]($Now - $PoolBalanceObjects[0].DateTime).TotalHours
                        PayoutThreshold         = [Double]$PayoutThreshold
                        PayoutThresholdCurrency = $PayoutThresholdCurrency
                        Payout                  = [Double]$PoolBalanceObject.Payout
                        Uri                     = $PoolBalanceObject.Url
                        LastEarnings            = If ($Growth24 -gt 0) { $PoolBalanceObject.DateTime } Else { $PoolBalanceObjects[0].DateTime }
                    }
                }
                Catch {
                    Start-Sleep 0
                }
                If ($Config.BalancesTrackerLog) { 
                    $EarningsObject | Export-Csv -NoTypeInformation -Append ".\Logs\BalancesTrackerLog.csv" -Force
                }

                $PoolTodayEarning = $Earnings | Where-Object Pool -EQ $PoolBalanceObject.Pool | Where-Object Currency -EQ $PoolBalanceObject.Currency | Where-Object Wallet -EQ $PoolBalanceObject.Wallet | Select-Object -Last 1

                If ([String]$PoolTodayEarning.Date -eq $Now.ToString("yyyy-MM-dd")) { 
                    $PoolTodayEarning.DailyEarnings = [Double]$GrowthToday
                    $PoolTodayEarning.EndTime = $Now.ToString("T")
                    $PoolTodayEarning.EndValue = [Double]$PoolBalanceObject.Earnings
                    $PoolTodayEarning.Balance = [Double]$PoolBalanceObject.Balance
                    $PoolTodayEarning.Unpaid = [Double]$PoolBalanceObject.Unpaid
                    $PoolTodayEarning.Payout = [Double]$PoolTodayEarning.Payout + [Double]$PoolBalanceObject.Payout
                }
                Else { 
                    $Earnings += [PSCustomObject]@{ 
                        Date          = $Now.ToString("yyyy-MM-dd")
                        Pool          = $EarningsObject.Pool
                        Currency      = $EarningsObject.Currency
                        Wallet        = $PoolBalanceObject.Wallet
                        DailyEarnings = [Double]$GrowthToday
                        StartTime     = $Now.ToString("T")
                        StartValue    = If ($PoolTodayEarning) { [Double]$PoolTodayEarning.EndValue } Else { [Double]$EarningsObject.Earnings }
                        EndTime       = $Now.ToString("T")
                        EndValue      = [Double]$EarningsObject.Earnings
                        Balance       = [Double]$EarningsObject.Balance
                        Pending       = [Double]$EarningsObject.Pending
                        Unpaid        = [Double]$EarningsObject.Unpaid
                        Payout        = [Double]0
                    }
                }
            }
        }

        # Always keep pools sorted, even when new pools were added
        $Variables.Balances = [Ordered]@{ }
        $Balances.Keys | Where-Object { $Balances.$_.Pool -notin @($Config.BalancesTrackerExcludePool) } | Sort-Object | ForEach-Object { 
            $Variables.Balances.$_ = $Balances.$_
            $Variables.PoolsLastEarnings | Add-Member ($_ -replace ' \(.+') ($Variables.PoolsLastEarnings.($_ -replace ' \(.+'), $Balances.$_.LastEarnings | Measure-Object -Maximum).Maximum -Force
        }
        $Variables.BalancesCurrencies = @($Variables.Balances.Keys | ForEach-Object { $Variables.Balances.$_.Currency } | Sort-Object -Unique)

        $Variables.PoolsLastEarnings = $Variables.PoolsLastEarnings | Get-SortedObject
        $Variables.PoolsLastEarnings | ConvertTo-Json | Out-File -FilePath ".\Data\PoolsLastEarnings.json" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue

        # Build chart data (used in GUI) for last 30 days
        $PoolChartData = [PSCustomObject]@{ }
        $ChartData = $Earnings | Where-Object Pool -in $PoolsToTrack | Sort-Object Date | Group-Object -Property Date | Select-Object -Last 30 # days

        # One dataset per pool
        ($ChartData.Group | Where-Object { $_.DailyEarnings -gt 0 }).Pool | Sort-Object -Unique | ForEach-Object { 
            $PoolChartData | Add-Member @{ $_ = [Double[]]@() }
        }

        # Fill dataset
        ForEach ($PoolEarnings in $ChartData) { 
            $PoolChartData.PSObject.Properties.Name | ForEach-Object { 
                $PoolChartData.$_ += ($PoolEarnings.Group | Where-Object Pool -EQ $_ | ForEach-Object { [Double]$_.DailyEarnings * $Variables.Rates.($_.Currency).BTC } | Measure-Object -Sum).Sum
            }
        }
        Remove-Variable PoolEarnings -ErrorAction Ignore

        $EarningsChartData = [PSCustomObject]@{ 
            Labels = @(
                $ChartData.Group.Date | Sort-Object -Unique | ForEach-Object { 
                    [DateTime]::parseexact($_, "yyyy-MM-dd", $null).ToShortDateString()
                }
            )
            # Use dates for x-axis label
            Earnings = $PoolChartData
        }

        $Variables.EarningsChartData = $EarningsChartData 
        $Variables.EarningsChartData | ConvertTo-Json | Out-File -FilePath ".\Data\EarningsChartData.json" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue

        # Keep earnings for max. 1 year
        $OldestEarningsDate = (Get-Date).AddYears(-1).ToString("yyyy-MM-dd")
        $Earnings = $Earnings | Where-Object Date -ge $OldestEarningsDate

        # At least 31 days are needed for Growth720
        If ($Variables.BalanceData.Count -gt 1) { 
            $Variables.BalanceData = @(
                $Variables.BalanceData | Where-Object DateTime -GE $Now.AddDays(-31) | Group-Object Pool, Currency | ForEach-Object { 
                    $Record = $null
                    $_.Group | Sort-Object DateTime | ForEach-Object { 
                        If ($_.DateTime -ge $Now.AddDays(-1)) { $_ } # Keep all records for 1 day
                        ElseIf ($_.DateTime -ge $Now.AddDays(-7) -and $_.Delta -gt 0) { $_ } # Keep all records of the last 7 days with delta
                        ElseIf ($_.DateTime.Date -ne $Record.DateTime.Date) { $Record = $_; $_ } # Keep the newest one per day
                    }
                }
            ) | Sort-Object DateTime -Descending
        }

        Try { 
            $Earnings | Export-Csv ".\Data\DailyEarnings.csv" -NoTypeInformation -Force
        }
        Catch { 
            Write-Message -Level Warn "Balances Tracker failed to save earnings data to '.\Data\DailyEarnings.csv' (should have $($Earnings.count) entries)."
        }

        If ($Variables.BalanceData.Count -ge 1) { $Variables.BalanceData | ConvertTo-Json | Out-File -FilePath ".\Data\BalancesTrackerData.json" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue }

        # Sleep until next update (at least 1 minute, maximum 60 minutes)
        While ((Get-Date) -le $Now.AddMinutes((60, (1, [Int]$Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum | Measure-Object -Minimum).Minimum)) { Start-Sleep -Seconds 5 }

        [System.GC]::Collect() | Out-Null
        [System.GC]::WaitForPendingFinalizers() | Out-Null
        [System.GC]::GetTotalMemory("forcefullcollection") | Out-Null
    }

    If ($Now) { Write-Message -Level Info "Balances Tracker stopped." }

    [System.GC]::GetTotalMemory($true) | Out-Null

    While ($Config.BalancesTrackerPollInterval -eq 0) { Start-Sleep -Seconds 5 }

} While ($true)