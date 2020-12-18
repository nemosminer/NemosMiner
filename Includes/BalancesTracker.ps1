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
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           BalancesTracker.ps1
version:        3.9.9.8
version date:   18 November 2020
#>

# Start the log
If ($Config.Transcript) { Start-Transcript -Path ".\Logs\BalancesTracker-$(Get-Date -Format "yyyy-MM-dd").log" -Append -Force | Out-Null }

(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$TrustLevel = 0
$Variables.Earnings = [Ordered]@{ }
$LastAPIUpdateTime = (Get-Date).ToUniversalTime()

While ($true) { 
    If ($Config.BalancesTrackerPollInterval -gt 0) { 

        # Only on first run
        If (-not $Now) { 
            Write-Message "Balances Tracker started."
            # Read existing earning data
            If (Test-Path -Path ".\Logs\BalancesTrackerData.json" -PathType Leaf) { 
                $AllBalanceObjects = ((Get-Content ".\logs\BalancesTrackerData.json" | ConvertFrom-Json ) | Where-Object Balance -NE $null | ForEach-Object { $_.DateTime = ([DateTime]($_.DateTime)).ToUniversalTime(); $_ })
            } Else { 
                $AllBalanceObjects = @()
            }
            If (Test-Path -Path ".\Logs\DailyEarnings.csv" -PathType Leaf) {
                $DailyEarnings = @(Import-Csv ".\Logs\DailyEarnings.csv" -ErrorAction SilentlyContinue)
                Write-Message -Level Info "Balances Tracker loaded $($DailyEarnings.count) earnings data entries from '.\Logs\DailyEarnings.csv'."
                Copy-Item -Path ".\Logs\DailyEarnings.csv" -Destination ".\Logs\DailyEarnings_$(Get-Date -Format "yyyy-MM-dd_hh-mm-ss").csv"
            } Else { 
                $DailyEarnings = @()
            }
            # Keep only the last 10 logs 
            Get-ChildItem ".\Logs\DailyEarnings_*.csv" | Sort-Object LastWriteTime | Select-Object -Skiplast 10 | Remove-Item -Force -Recurse
        }

        $Now = Get-Date
        $Date = $Now.ToString("yyyy-MM-dd")
        $CurDateUxFormat = ([DateTimeOffset]$Now.Date).ToUnixTimeMilliseconds()

        # Get pools api ref
        If (-not $PoolAPI -or ($LastAPIUpdateTime -le $Now.AddDays(-1))) { 
            # Try { 
            #     $PoolAPI = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/UpDateData/master/poolapidata.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
            #     $LastAPIUpdateTime = $Now
            #     $PoolAPI | ConvertTo-Json | Out-File ".\Config\PoolApiData.json" -Force
            # }
            # Catch { 
                If (-not $PoolAPI) { $PoolAPI = Get-Content ".\Config\PoolApiData.json" | ConvertFrom-Json }
            # }
        }

        # Get pools to track
        $PoolsToTrack = @((Get-ChildItem .\Pools\*.ps1 -File).BaseName -replace "24hr$" -replace "Coins$" | Sort-Object -Unique | Where-Object { 
            $_ -in @($PoolAPI | Where-Object EarnTrackSupport -EQ "yes").Name
        })

        Write-Message "Balances Tracker requesting data ($($PoolsToTrack -join ', '))."

        $PoolsToTrack | ForEach-Object { 
            $PoolName = $_
            $API = $PoolAPI | Where-Object Name -EQ $PoolName
            $APIUri = $API.WalletUri
            $BalanceData = [PSCustomObject]@{ }
            $BalanceJson = $API.Balance
            $TotalJson = $API.Total
            $PoolAccountUri = $API.AccountUri
            $PoolConfig = $Config.PoolsConfig.$PoolName
            If ($PoolName -eq "NiceHash") { 
                If ($Config.NiceHashWalletIsInternal) { 
                    $PoolName = "NiceHashInternal"
                }
                Else { 
                    $PoolName = "NiceHashExternal"
                }
            }

            $PayoutThresholdCurrency = $PoolConfig.PayoutThresholdCurrency
            If (-not $PayoutThresholdCurrency) { $PayoutThresholdCurrency = $PoolConfig.PayoutCurrency }
            If (-not $PayoutThresholdCurrency) { $PayoutThresholdCurrency = $API.PayoutCurrency }

            $PayoutThreshold = $PoolConfig.PayoutThreshold.$PayoutThresholdCurrency
            If (-not $PayoutThreshold -and ($PoolConfig.PayoutThreshold."m$($PayoutThresholdCurrency)" -ne $null)) { 
                $PayoutThresholdCurrency = "m$($PayoutThresholdCurrency)"
                $PayoutThreshold = $PoolConfig.PayoutThreshold.$PayoutThresholdCurrency
            }
            If (-not $PayoutThreshold) { $PayoutThreshold = $API.PayoutThreshold.$PayoutThresholdCurrency }
            If (-not $PayoutThreshold -and ($API.PayoutThreshold."m$($PayoutThresholdCurrency)" -ne $null)) { 
                $PayoutThresholdCurrency = "m$($PayoutThresholdCurrency)"
                $PayoutThreshold = $API.PayoutThreshold.$PayoutThresholdCurrency
            }
            If (-not $PayoutThreshold) { $PayoutThreshold = $API.PayoutThreshold."*" }

            Try { 
                Switch ($PoolName) { 
                    "MPH" { 
                        $Wallet = $Config.MPHAPIKey
                        $BalanceData = (((Invoke-RestMethod -Uri "$APIUri$Wallet" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }).getuserallbalances).data | Where-Object { $_.coin -eq "bitcoin" })
                    }
                    "NiceHashInternal" { 
                        $Wallet = "OrgID $($Config.NicehashOrganizationID)"
                        $Request_Balance = [PSCustomObject]@{ }

                        If ($Config.NicehashAPIKey -and $Config.NicehashAPISecret -and $Config.NicehashOrganizationID) { 

                            $EndPoint = "/main/api/v2/accounting/account2/BTC/"
                            $Key = $Config.NicehashAPIKey
                            $Method = "GET"
                            $OrganizationID = $Config.NicehashOrganizationID
                            $Secret = $Config.NicehashAPISecret

                            $Uuid = [string]([guid]::NewGuid())
                            $Timestamp = ([DateTimeOffset](Get-Date).ToUniversalTime()).ToUnixTimeMilliseconds()

                            $Str = "$Key`0$Timestamp`0$Uuid`0`0$Organizationid`0`0$($Method.ToUpper())`0$Endpoint`0"
                            $Sha = [System.Security.Cryptography.KeyedHashAlgorithm]::Create("HMACSHA256")
                            $Sha.Key = [System.Text.Encoding]::UTF8.Getbytes($Secret)
                            $Sign = [System.BitConverter]::ToString($Sha.ComputeHash([System.Text.Encoding]::UTF8.Getbytes(${str})))
                            $Headers = [Hashtable]@{
                                'X-Time'            = $Timestamp
                                'X-Nonce'           = $Uuid
                                'X-Organization-Id' = $OrganizationId
                                'X-Auth'            = "$($Key):$(($Sign -replace '\-').ToLower())"
                                'Cache-Control'     = 'no-cache'
                            }
                            $BalanceData = Invoke-RestMethod "https://api2.nicehash.com$EndPoint" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop -Method $Method -Headers $Headers
                        }
                    }
                    "NiceHashExternal" { 
                        $TempBalance = 0
                        $Wallet = $PoolConfig.Wallet
                        $PayoutCurrency = "BTC"
                        $NicehashData = ((Invoke-RestMethod -Uri "$APIUri$Wallet/rigs/stats/unpaid/" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }).Data | Where-Object { $_[0] -gt $CurDateUxFormat } | Sort-Object { $_[0] } | Group-Object { $_[2] }).group
                        $NHTotalBalance = -$NicehashData[0][2]
                        $NicehashData | ForEach-Object {
                            # Nicehash continously transfers balances to wallet
                            If ($_[2] -gt $TempBalance) {
                                $TempBalance = $_[2]
                            }
                            Else { 
                                $NHTotalBalance += $TempBalance
                                $TempBalance = $_[2]
                            }
                        }
                        $NHTotalBalance += $TempBalance
                        $BalanceData | Add-Member -NotePropertyName $BalanceJson -NotePropertyValue $NHTotalBalance -Force
                        $BalanceData | Add-Member -NotePropertyName $TotalJson -NotePropertyValue $NHTotalBalance -Force
                    }
                    "ProHashing" { 
                        $Wallet = $Config.ProHashingAPIKey
                        $BalanceData = (Invoke-RestMethod -Uri "$APIUri$Wallet" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }).data.balances."BTC"
                        $BalanceData | Add-Member "total_unpaid" $BalanceData.Unpaid -Force
                    }
                    Default { 
                        $Wallet = $PoolConfig.Wallet
                        $BalanceData = Invoke-RestMethod -Uri "$APIUri$Wallet" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }
                        $PoolAccountUri = "$($PoolAccountUri -replace '\[currency\]', $PayoutCurrency)$Wallet"
                    }
                }
            }
            Catch { }

            If ($Variables.Rates.($PoolConfig.PayoutCurrency).BTC -and $BalanceData.$BalanceJson) { 

                $AllBalanceObjects += $BalanceObject = [PSCustomObject]@{ 
                    Pool         = $PoolName
                    DateTime     = $Now
                    Balance      = $Variables.Rates.($PoolConfig.PayoutCurrency).BTC * $BalanceData.$BalanceJson
                    Unsold       = $Variables.Rates.($PoolConfig.PayoutCurrency).BTC * $BalanceData.unsold
                    Total_unpaid = $Variables.Rates.($PoolConfig.PayoutCurrency).BTC * $BalanceData.total_unpaid
                    Total_paid   = $Variables.Rates.($PoolConfig.PayoutCurrency).BTC * $BalanceData.total_paid
                    Total_earned = ($BalanceData.$BalanceJson, $BalanceData.$TotalJson | Measure-Object -Minimum).Minimum * $Variables.Rates.($PoolConfig.PayoutCurrency).BTC # Pool reduced balance!
                    Currency     = $PoolConfig.PayoutCurrency
                }
            }

            $Growth1 = $Growth6 = $Growth24 = $Growth168 = [Double]0

            If ($BalanceObject) { 

                $BalanceObjects = @($AllBalanceObjects | Where-Object Pool -EQ $PoolName | Where-Object Currency -EQ $PoolConfig.PayoutCurrency | Sort-Object DateTime)

                If ((($Now - ($BalanceObjects[0].DateTime)).TotalMinutes) -eq 0) { $Now = $Now.AddMinutes(1) }

                If ((($Now - ($BalanceObjects[0].DateTime)).TotalHours) -lt 1) { 
                    If ($BalanceObjects[0].total_earned) { 
                        $Growth1 = [Double]((($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($Now - ($BalanceObjects[0].DateTime)).TotalMinutes) * 60)
                    }
                    $AvgHourlyGrowth = $Growth1
                }
                ElseIf ((($Now - ($BalanceObjects[0].DateTime)).TotalHours) -lt 6) { 
                    $Growth1 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -1 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $Growth6 = [Double]((($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($Now - ($BalanceObjects[0].DateTime)).TotalHours) * 6)
                    $AvgHourlyGrowth = [Double]($Growth6 / ($Now - ($BalanceObjects[0].DateTime)).TotalHours)
                }
                ElseIf ((($Now - ($BalanceObjects[0].DateTime)).TotalHours) -lt 24) { 
                    $Growth1 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -1 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $Growth6 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -6 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $Growth24 = [Double]((($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($Now - ($BalanceObjects[0].DateTime)).TotalHours) * 24)
                    $AvgHourlyGrowth = [Double]($Growth24 / ($Now - ($BalanceObjects[0].DateTime)).TotalHours)
                }
                ElseIf ((($Now - ($BalanceObjects[0].DateTime)).TotalHours) -lt 168) { 
                    $Growth1 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -1 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $Growth6 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -6 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $Growth24 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -24 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $Growth168 = [Double]((($BalanceObject.total_earned - $BalanceObjects[0].total_earned) / ($Now - ($BalanceObjects[0].DateTime)).TotalHours) * 168)
                    $AvgHourlyGrowth = [Double]($Growth168 / ($Now - ($BalanceObjects[0].DateTime)).TotalHours)
                }
                Else { 
                    $Growth1 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -1 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $Growth6 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -6 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $Growth24 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -24 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $Growth168 = [Double]($BalanceObject.total_earned - (($BalanceObjects | Where-Object { $_.DateTime -ge $Now.AddHours( -168 ) }).total_earned | Measure-Object -Minimum).Minimum)
                    $AvgHourlyGrowth = [Double]($Growth168 / ($Now - ($BalanceObjects[0].DateTime)).TotalHours)
                }

                $Variables.Earnings.$PoolName = $EarningsObject = [PSCustomObject]@{ 
                    Pool                    = $PoolName
                    Wallet                  = $Wallet
                    Uri                     = $PoolAccountUri
                    Date                    = $Date
                    StartTime               = $BalanceObjects[0].DateTime.ToString("T")
                    Balance                 = [Double]$BalanceObject.balance
                    Unsold                  = [Double]$BalanceObject.unsold
                    Total_unpaid            = [Double]$BalanceObject.total_unpaid
                    Total_paid              = [Double]$BalanceObject.total_paid
                    Total_earned            = [Double]$BalanceObject.total_earned
                    Currency                = $PoolConfig.PayoutCurrency
                    GrowthSinceStart        = ($BalanceObject.total_earned - $BalanceObjects[0].total_earned)
                    Growth1                 = $Growth1
                    Growth6                 = $Growth6
                    Growth24                = $Growth24
                    Growth168               = $Growth168
                    AvgHourlyGrowth         = $AvgHourlyGrowth
                    AvgDailyGrowth          = $AvgHourlyGrowth * 24
                    AvgWeeklyGrowth         = $AvgHourlyGrowth * 168
                    EstimatedEndDayGrowth   = If ((($Now - ($BalanceObjects[0].DateTime)).TotalHours) -ge 1) { [Double]($AvgHourlyGrowth * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) } Else { [Double]($Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) }
                    EstimatedPayDate        = If ($PayoutThreshold) { If ($BalanceObject.balance -lt ($PayoutThreshold * $Variables.Rates.$PayoutThresholdCurrency.BTC)) { If (($AvgHourlyGrowth, $Growth24 | Measure-Object -Maximum).Maximum -gt 1E-8) { [DateTime]($Now.AddDays(($PayoutThreshold * $Variables.Rates.$PayoutThresholdCurrency.BTC - $BalanceObject.Balance) / ((($AvgDailyGrowth, $Growth24) | Measure-Object -Maximum).Maximum))) } Else { "Unknown" } } Else { "Next Payout!" } } Else { "Unknown" }
                    TrustLevel              = [Double](((($Now - ($BalanceObjects[0].DateTime)).TotalHours / 168), 1 | Measure-Object -Minimum).Minimum)
                    TotalHours              = ($Now - ($BalanceObjects[0].DateTime)).TotalHours
                    PayoutThresholdCurrency = $PayoutThresholdCurrency
                    PayoutThreshold         = [Double]$PayoutThreshold
                    Updated                 = $BalanceObject.DateTime
                }

                If ($BalancesTrackerConfig.EnableLog) { $Variables.Earnings.$PoolName | Export-Csv -NoTypeInformation -Append ".\Logs\BalancesTrackerLog.csv" -ErrorAction Ignore }

                If ($PoolDailyEarning = $DailyEarnings | Where-Object Pool -EQ $PoolName | Where-Object Date -EQ $Date ) { 
                    # Pool may have reduced estimated balance, use new balance as start value to avoid negative values
                    If ($EarningsObject.total_earned -gt 0) { 
                        $PoolDailyEarning.StartValue = ($PoolDailyEarning.StartValue, $EarningsObject.total_earned | Measure-Object -Minimum).Minimum
                    }
                    Else { 
                        $PoolDailyEarning.StartValue = $PoolDailyEarning.StartValue
                    }
                    $PoolDailyEarning.DailyEarnings = (($EarningsObject.total_earned - $PoolDailyEarning.StartValue), 0 | Measure-Object -Maximum).Maximum
                    $PoolDailyEarning.EndTime = $Now.ToString("T")
                    $PoolDailyEarning.EndValue = $EarningsObject.total_earned
                    # Payment occured?
                    If ($EarningsObject.total_earned -lt ($BalanceObjects[$BalanceObjects.Count - 2].total_earned / 2)) { 
                        $PoolDailyEarning.PrePaymentDayValue = $BalanceObjects[$BalanceObjects.Count - 2].total_earned
                        If ($PoolDailyEarning.PrePaymentDayValue -gt 0) { 
                            # Payment occured
                            $PoolDailyEarning.DailyEarnings += $PoolDailyEarning.PrePaymentDayValue
                        }
                    }
                    $PoolDailyEarning.Balance = $EarningsObject.balance
                    $PoolDailyEarning.DailyGrowth = $EarningsObject.Growth24

                    Remove-Variable PoolDailyEarning
                }
                Else { 
                    $DailyEarnings += [PSCustomObject]@{ 
                        Date               = $Date
                        Pool               = $PoolName
                        DailyEarnings      = [Double]0
                        StartTime          = $Now.ToString("T")
                        StartValue         = [Double]$EarningsObject.total_earned
                        EndTime            = $Now.ToString("T")
                        EndValue           = [Double]$EarningsObject.total_earned
                        PrePaymentDayValue = [Double]0
                        Balance            = [Double]$EarningsObject.balance
                        DailyGrowth        = [Double]$EarningsObject.Growth24
                    }
                }

                # Some pools do reset "Total" after payment (zpool)
                # Results in showing bad negative earnings
                # Detecting if current is more than 50% less than previous and reset history if so
                If ($EarningsObject -and $EarningsObject.total_earned -lt ($BalanceObjects[$BalanceObjects.Count - 2].total_earned / 2)) { 
                    $AllBalanceObjects = $AllBalanceObjects | Where-Object Pool -ne $PoolName
                    $AllBalanceObjects += $EarningsObject
                }

                Remove-Variable BalanceData
                Remove-Variable BalanceObject
                Remove-Variable EarningsObject
            }
            Remove-Variable Wallet -ErrorAction Ignore

        }

        # Always keep pools sorted, even when new pools were added
        $TempEarnings = $Variables.Earnings
        $Variables.Earnings = [Ordered]@{ }
        $TempEarnings.Keys | Sort-Object | ForEach-Object { 
            $Variables.Earnings.$_ = $TempEarnings.$_
        }

        Try { 
            $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Force -ErrorAction Ignore
        }
        Catch { 
            Write-Message -Level Warn "Balances Tracker failed to save earnings data to '.\Logs\DailyEarnings.csv' (should have $($DailyEarnings.count) entries)."
        }

        # Write chart data file (used in Web GUI)
        $ChartData = $DailyEarnings | Sort-Object Date | Group-Object -Property Date | Select-Object -Last 30 # days

        # One dataset per pool
        $PoolData = [PSCustomObject]@{}
        $ChartData.Group.Pool | Sort-Object -Unique | ForEach-Object { 
            $PoolData | Add-Member @{ $_ = [Double[]]@() }
        }

        # $CumulatedEarnings = [Double[]]@()
        # Fill dataset
        ForEach ($PoolDailyEarning in $ChartData) { 
            # $CumulatedEarnings += ([Double]($PoolDailyEarning.Group | Measure-Object DailyEarnings -Sum).Sum)
            $PoolData | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                $PoolData.$_ += [Double]($PoolDailyEarning.Group | Where-Object Pool -EQ $_).DailyEarnings
            }
        }

        [PSCustomObject]@{
            # CumulatedEarnings = $CumulatedEarnings # Dataset for cumulated earnings
            Currency = ($Config.Currency | Select-Object -Index 0)
            Labels = @(
                $ChartData.Group.Date | Sort-Object -Unique | ForEach-Object { 
                    [DateTime]::parseexact($_, "yyyy-MM-dd", $null).ToShortDateString()
                }
            )
            # Use dates for x-axis label
            Pools = $PoolData
        } | ConvertTo-Json | Out-File ".\Logs\EarningsChartData.json" -Encoding UTF8 -ErrorAction Ignore

        # Keep only last 14 days
        If ($AllBalanceObjects.Count -gt 1) { $AllBalanceObjects = @($AllBalanceObjects | Where-Object { $_.DateTime -ge $Now.AddDays( -14 ) }) }
        If ($AllBalanceObjects.Count -ge 1) { $AllBalanceObjects | ConvertTo-Json | Out-File ".\Logs\BalancesTrackerData.json" -ErrorAction Ignore }
        $Variables.BalanceData = $AllBalanceObjects

    }

    # Sleep until next update (at least 1 minute, maximum 60 minutes)
    Start-Sleep -Seconds (60 * (60, (1, $Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum | Measure-Object -Minimum).Minimum)
}

Write-Message "Balances Tracker stopped."
