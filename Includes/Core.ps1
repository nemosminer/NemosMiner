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
File:           Core.ps1
Version:        4.3.4.4
Version date:   26 April 2023
#>

using module .\Include.psm1
using module .\API.psm1

$Global:ProgressPreference = "Ignore"
$Global:InformationPreference = "Ignore"

Do { 
    $LegacyGUIForm.Text = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version) - Runtime: {0:dd} days {0:hh} hrs {0:mm} mins - Path: $($Variables.Mainpath)" -f [TimeSpan]((Get-Date).ToUniversalTime() - $Variables.ScriptStartTime)

    Try {
        $Error.Clear()
        Get-ChildItem -Path ".\Includes\MinerAPIs" -File | ForEach-Object { . $_.FullName }

        # Internet connection check
        Try { 
            $Variables.MyIP = (Get-NetIPAddress -InterfaceIndex (Get-NetRoute | Where-Object DestinationPrefix -eq "0.0.0.0/0" | Get-NetIPInterface | Where-Object ConnectionState -eq "Connected").ifIndex -AddressFamily IPV4).IPAddress
        }
        Catch { 
            $Variables.MyIP = $null
            Write-Message -Level Error "No internet connection - will retry in 60 seconds..."
            #Stop all running miners
            $Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { 
                $_.SetStatus([MinerStatus]::Idle)
                $_.Info = ""
                $_.WorkersRunning = @()
            }
            $Variables.MinersBest_Combo = $Variables.MinersBest_Combos = [Pool[]]@()
            Start-Sleep -Seconds 60
            Continue
        }

        # Read config only if config files have changed
        If ($Variables.ConfigFileTimestamp -ne (Get-Item -Path $Variables.ConfigFile).LastWriteTime -or $Variables.PoolsConfigFileTimestamp -ne (Get-Item -Path $Variables.PoolsConfigFile).LastWriteTime) { 
            Write-Message -Level Debug "Activating changed configuration..."
            Read-Config -ConfigFile $Variables.ConfigFile
        }
        $Variables.PoolsConfig = $Config.PoolsConfig | ConvertTo-Json -depth 99 -Compress | ConvertFrom-Json -AsHashTable

        If ($Config.WebGUI) { Start-APIServer } Else { Stop-APIServer }

        If ($Config.IdleDetection) { 
            If (-not $Variables.IdleRunspace) { 
                Start-IdleDetection
            }
            If ($Variables.IdleRunspace.MiningStatus -eq "Idle") { 
                $Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { 
                    $_.SetStatus([MinerStatus]::Idle)
                    $_.Info = ""
                    $_.WorkersRunning = [Worker[]]@()
                }
                $Variables.WatchdogTimers = @()
                $Variables.Summary = "Mining is suspended until system is idle<br>again for $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" })..."
                Write-Message -Level Verbose ($Variables.Summary -replace "<br>", " ")
                $Variables.IdleRunspace | Add-Member MiningStatus "Idle" -Force

                While ($Variables.NewMiningStatus -eq "Running" -and $Config.IdleDetection -and $Variables.IdleRunspace.MiningStatus -eq "Idle") { Start-Sleep -Seconds 1 }

                If ($Config.IdleDetection) { Write-Message -Level Info "Started new cycle (System was idle for $($Config.IdleSec) seconds)." }
            }
        }
        Else { 
            If ($Variables.IdleRunspace) { Stop-IdleDetection }
            Write-Message -Level Info "Started new cycle."
        }

        If (Compare-Object @($Variables.EnabledDevices.Name | Select-Object) @(($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName).Name | Select-Object)) { 
            $Variables.EnabledDevices = [Device[]]@($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | ForEach-Object { Copy-Object $_ })
            # For GPUs set type equal to vendor
            $Variables.EnabledDevices | Where-Object Type -EQ "GPU" | ForEach-Object { $_.Type = $_.Vendor }
        }

        If ($Variables.EnabledDevices) { 
            # Remove model information from devices -> will create only one miner instance
            If ($Config.MinerInstancePerDeviceModel) { $Variables.EnabledDevices | ForEach-Object { $_.Model = ($Variables.Devices | Where-Object Name -eq $_.Name).Model } }
            Else { $Variables.EnabledDevices | Where-Object Type -EQ "GPU" | ForEach-Object { $_.Model = $_.Vendor } }

            If ($Variables.EndCycleTime) { 
                $Variables.BeginCycleTime = $Variables.EndCycleTime
                $Variables.EndCycleTime = $Variables.EndCycleTime.AddSeconds($Config.Interval)
            }

            # Skip stuff if previous cycle was shorter than half of what it should
            If ((Compare-Object @($Config.PoolName | Select-Object) @($Variables.PoolName | Select-Object)) -or -not $Variables.Timer -or -not $Variables.Miners -or $Variables.Timer.AddSeconds([Int]($Config.Interval / 2)) -lt (Get-Date).ToUniversalTime() -or (Compare-Object @($Config.ExtraCurrencies | Select-Object) @($Variables.AllCurrencies | Select-Object) | Where-Object SideIndicator -eq "<=")) { 

                # Set master timer
                $Variables.Timer = (Get-Date).ToUniversalTime()
                If ($Variables.EndCycleTime -lt $Variables.Timer) { 
                    $Variables.BeginCycleTime = $Variables.Timer
                    $Variables.EndCycleTime = $Variables.Timer.AddSeconds($Config.Interval)
                }

                $Variables.CycleStarts += $Variables.Timer
                $Variables.CycleStarts = @($Variables.CycleStarts | Select-Object -Last (3, ($Config.SyncWindow + 1) | Measure-Object -Maximum).Maximum)
                $Variables.SyncWindowDuration = ($Variables.CycleStarts | Select-Object -Last 1) - ($Variables.CycleStarts | Select-Object -First 1)

                # Set minimum Watchdog count 3
                $Variables.WatchdogCount = (3, $Config.WatchdogCount | Measure-Object -Maximum).Maximum
                $Variables.WatchdogReset = $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Config.Interval

                # Expire watchdog timers
                If ($Config.Watchdog) { $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object Kicked -GE $Variables.Timer.AddSeconds( - $Variables.WatchdogReset)) }
                Else { $Variables.WatchdogTimers = @() }

                # Check for new version
                If ($Config.AutoUpdateCheckInterval -and $Variables.CheckedForUpdate -lt (Get-Date).AddDays(-$Config.AutoUpdateCheckInterval)) { Get-NMVersion }

                # Use non-donate pool config
                $Variables.PoolName = $Config.PoolName
                $Variables.NiceHashWalletIsInternal = $Config.NiceHashWalletIsInternal
                $Variables.PoolTimeout = [Int]$Config.PoolTimeout

                If ($Config.Donation -gt 0) { 
                    # Re-Randomize donation start once per day, do not donate if remaing time for today is less than donation duration
                    If (($Variables.DonationLog.Start | Sort-Object | Select-Object -Last 1).Date -ne (Get-Date).Date) { 
                        If (-not $Variables.DonationStart) { 
                            If ($Config.Donation -ge (1440 - [Int](Get-Date).TimeOfDay.TotalMinutes)) { 
                                $Variables.DonationStart = (Get-Date)
                            }
                            Else { 
                                $Variables.DonationStart = (Get-Date).AddMinutes((Get-Random -Minimum 0 -Maximum (1440 - $Config.Donation - [Int](Get-Date).TimeOfDay.TotalMinutes)))
                            }
                            $Variables.DonationEnd = $null
                        }

                        If ((Get-Date) -ge $Variables.DonationStart -and -not $Variables.DonationEnd) { 
                            # Add pool config to config (in-memory only)
                            If ($Variables.DonationRandomPoolsConfig = Get-RandomDonationPoolsConfig) { 
                                # We get here only once per day, ensure full donation period
                                $Variables.DonationStart = Get-Date
                                $Variables.DonationEnd = $Variables.DonationStart.AddMinutes($Config.Donation)
                            }
                        }
                    }

                    If ((Get-Date) -ge $Variables.DonationStart -and (Get-Date) -le $Variables.DonationEnd) { 
                        # Ensure full donation period
                        $Variables.EndCycleTime = ($Variables.DonationEnd).ToUniversalTime()
                        $Variables.DonationRunning = $true
                        # Activate donation
                        $Variables.PoolName = $Variables.DonationRandomPoolsConfig.Keys
                        $Variables.PoolsConfig = $Variables.DonationRandomPoolsConfig
                        $Variables.NiceHashWalletIsInternal = $false
                        Write-Message -Level Info "Donation run: Mining for '$($Variables.DonationRandom.Name)' for the next $(If (($Config.Donation - ((Get-Date) - $Variables.DonationStart).Minutes) -gt 1) { "$($Config.Donation - ((Get-Date) - $Variables.DonationStart).Minutes) minutes" } Else { "minute" }). $($Variables.Branding.ProductLabel) will use these pools while donating: '$($Variables.PoolName -join ', ')'."
                    }
                }

                If ($Variables.DonationRunning -and (Get-Date) -gt $Variables.DonationEnd) { 
                    [Array]$Variables.DonationLog += [PSCustomObject]@{ 
                        Start = $Variables.DonationStart
                        End   = $Variables.DonationEnd
                        Name  = $Variables.DonationRandom.Name
                    }
                    $Variables.DonationLog = $Variables.DonationLog | Select-Object -Last 365 # Keep data for one year
                    $Variables.DonationLog | ConvertTo-Json | Out-File -FilePath ".\Logs\DonateLog.json" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                    $Variables.DonationRandomPoolsConfig = $null
                    $Variables.DonationRandom = $null
                    $Variables.DonationEnd = $null
                    $Variables.DonationRunning = $false
                    Write-Message -Level Info "Donation run complete - thank you! Mining for you again. :-)"
                }

                # Stop / Start brain background jobs
                Stop-Brain @($Variables.Brains.Keys | Where-Object { $_ -notin @(Get-PoolBaseName $Variables.PoolName) })
                Start-Brain @(Get-PoolBaseName $Variables.PoolName)

                # Get pool data
                If ($Variables.PoolName) { 
                    If ($Variables.Brains.Keys | Where-Object { $Variables.Brains.$_.StartTime -gt $Variables.Timer.AddSeconds(- $Config.Interval) }) {
                        # Newly started brains, allow extra time for brains to get ready
                        $Variables.PoolTimeout = $WaitForBrainData = 60
                        $Variables.Summary = "Loading initial pool data from '$((Get-PoolBaseName $Variables.PoolName) -join ', ')'...<br>This may take up to $($WaitForBrainData) seconds."
                        Write-Message -Level Info ($Variables.Summary -replace "<br>", " ")
                        $Variables.RefreshNeeded = $true
                    }
                    ElseIf (-not $Variables.PoolsCount) { 
                        $Variables.Summary = "Loading initial pool data from '$((Get-PoolBaseName $Variables.PoolName) -join ', ')'...<br>This may take while."
                        Write-Message -Level Info ($Variables.Summary -replace "<br>", " ")
                        $Variables.RefreshNeeded = $true
                    }
                    Else { 
                        Write-Message -Level Info "Loading pool data from '$((Get-PoolBaseName $Variables.PoolName) -join ', ')'..."
                    }
                }

                # Get DAG data
                Update-DAGdata

                # Faster shutdown
                If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

                # For debug only
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                # Load currency exchange rates from min-api.cryptocompare.com
                Get-Rate | Out-Null

                # Power cost preparations
                $Variables.CalculatePowerCost = $Config.CalculatePowerCost
                If ($Config.CalculatePowerCost) { 
                    If ($Variables.EnabledDevices.Count -ge 1) { 
                        # HWiNFO64 verification
                        $RegKey = "HKCU:\Software\HWiNFO64\VSB"
                        If ($RegValue = Get-ItemProperty -Path $RegKey -ErrorAction Ignore) { 
                            If ([String]$Variables.HWInfo64RegValue -eq [String]$RegValue) { 
                                Write-Message -Level Warn "Power usage info in registry has not been updated [HWiNFO64 not running???] - disabling power usage and profit calculations."
                                $Variables.CalculatePowerCost = $false
                            }
                            Else { 
                                $PowerUsageData = @{ }
                                $DeviceName = ""
                                $RegValue.PSObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @($Variables.EnabledDevices.Name) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                                    $DeviceName = ($_.Value -split ' ') | Select-Object -Last 1
                                    Try { 
                                        $PowerUsageData[$DeviceName] = $RegValue.($_.Name -replace "Label", "Value")
                                    }
                                    Catch { 
                                        Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [duplicate sensor for $DeviceName] - disabling power usage and profit calculations."
                                        $Variables.CalculatePowerCost = $false
                                    }
                                }
                                # Add configured power usage
                                $Config.PowerUsage.GetEnumerator() | Where-Object { $Config.PowerUsage.$_ } | ForEach-Object { 
                                    If ($Config.PowerUsage.$_) { 
                                        If ($_ -in @($Variables.EnabledDevices.Name) -and -not $PowerUsageData.$_) { Write-Message -Level Warn "HWiNFO64 cannot read power usage from system for device ($_). Will use configured value of $([Double]$Config.PowerUsage.$_) W." }
                                        $PowerUsageData.$_ = "$Config.PowerUsage.$_ W"
                                        If ($Variables.EnabledDevices | Where-Object Name -EQ $_) { ($Variables.EnabledDevices | Where-Object Name -EQ $_).ConfiguredPowerUsage = [Double]$Config.PowerUsage.$_ }
                                    }
                                }

                                If ($DeviceNamesMissingSensor = Compare-Object @($Variables.EnabledDevices.Name) @($PowerUsageData.Keys) -PassThru | Where-Object SideIndicator -EQ "<=") { 
                                    Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [missing sensor config for $($DeviceNamesMissingSensor -join ', ')] - disabling power usage and profit calculations."
                                    $Variables.CalculatePowerCost = $false
                                }

                                # Enable read power usage for configured devices
                                $Variables.Devices | ForEach-Object { $_.ReadPowerUsage = $_.Name -in @($PowerUsageData.Keys) }
                            }
                            $Variables.HWInfo64RegValue = [String]$RegValue
                        }
                        Else { 
                            Write-Message -Level Warn "Cannot read power usage info from registry [Key '$RegKey' does not exist - HWiNFO64 not running???] - disabling power usage and profit calculations."
                            $Variables.CalculatePowerCost = $false
                        }
                        Remove-Variable RegKey, RegValue
                    }
                    Else { $Variables.CalculatePowerCost = $false }
                }
                If (-not $Variables.CalculatePowerCost) { 
                    $Variables.Devices | ForEach-Object { $_.ReadPowerUsage = $false }
                }

                # Power price
                If (-not $Config.PowerPricekWh.Keys) { $Config.PowerPricekWh."00:00" = 0 }
                ElseIf ($null -eq $Config.PowerPricekWh."00:00") { 
                    # 00:00h power price is the same as the latest price of the previous day
                    $Config.PowerPricekWh."00:00" = $Config.PowerPricekWh.($Config.PowerPricekWh.Keys | Sort-Object | Select-Object -Last 1)
                }
                $Variables.PowerPricekWh = [Double]($Config.PowerPricekWh.($Config.PowerPricekWh.Keys | Sort-Object | Where-Object { $_ -le (Get-Date -Format HH:mm).ToString() } | Select-Object -Last 1))
                $Variables.PowerCostBTCperW = [Double](1 / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.Currency))

                # Ensure we get the hashrate for running miners prior looking for best miner
                ForEach ($Miner in $Variables.MinersBest_Combo) { 
                    If ($Miner.DataReaderJob.HasMoreData) { 
                        $Miner.Data = @($Miner.Data | Select-Object -Last ($Miner.MinDataSample * 5)) # Reduce data to MinDataSample * 5
                        $Miner.Data += @($Miner.DataReaderJob | Receive-Job | Select-Object)
                    }

                    If ($Miner.Status -eq [MinerStatus]::DryRun -or $Miner.Status -eq [MinerStatus]::Running) { 
                        If ($Miner.Status -eq [MinerStatus]::DryRun -or $Miner.GetStatus() -eq [MinerStatus]::Running) { 
                            $Miner.Cycle ++
                            If ($Config.Watchdog) { 
                                ForEach ($Worker in $Miner.WorkersRunning) { 
                                    If ($WatchdogTimer = $Variables.WatchdogTimers | Where-Object MinerName -EQ $Miner.Name | Where-Object PoolName -EQ $Worker.Pool.Name | Where-Object PoolRegion -EQ $Worker.Pool.Region | Where-Object Algorithm -EQ $Worker.Pool.Algorithm | Sort-Object Kicked | Select-Object -Last 1) { 
                                        # Update watchdog timers
                                        $WatchdogTimer.Kicked = (Get-Date).ToUniversalTime()
                                    }
                                    Else {
                                        # Create watchdog timer
                                        $Variables.WatchdogTimers += [PSCustomObject]@{ 
                                            Algorithm     = $Worker.Pool.Algorithm
                                            DeviceNames   = $Miner.DeviceNames
                                            Kicked        = (Get-Date).ToUniversalTime()
                                            MinerBaseName = $Miner.BaseName
                                            MinerName     = $Miner.Name
                                            MinerVersion  = $Miner.Version
                                            PoolName      = $Worker.Pool.Name
                                            PoolBaseName  = $Worker.Pool.BaseName
                                            PoolRegion    = $Worker.Pool.Region
                                        }
                                    }
                                }
                                Remove-Variable Worker -ErrorAction Ignore
                            }
                            If ($Config.BadShareRatioThreshold -gt 0) { 
                                $Miner.WorkersRunning.Pool.Algorithm | ForEach-Object { 
                                    If ($LatestMinerSharesData = ($Miner.Data | Select-Object -Last 1 -ErrorAction Ignore).Shares) { 
                                        If ($LatestMinerSharesData.$_[1] -gt 0 -and $LatestMinerSharesData.$_[3] -gt [Int](1 / $Config.BadShareRatioThreshold) -and $LatestMinerSharesData.$_[1] / $LatestMinerSharesData.$_[3] -gt $Config.BadShareRatioThreshold) { 
                                            $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' stopped. Reasons: Too many bad shares (Shares Total = $($LatestMinerSharesData.$_[3]), Rejected = $($LatestMinerSharesData.$_[1]))."
                                            $Miner.SetStatus([MinerStatus]::Failed)
                                            $Miner.Data = @() # Clear data because it may be incorrect caused by miner problem
                                        }
                                    }
                                }
                            }
                        }
                        Else { 
                            $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' exited unexpectedly."
                            $Miner.SetStatus([MinerStatus]::Failed)
                        }
                    }

                    $Miner_Hashrates = @{ }
                    If ($Miner.Data.Count) { 
                        # Collect hashrate from miner, returns an array of two values (safe, unsafe)
                        $Miner.Hashrates_Live = @()
                        ForEach ($Algorithm in $Miner.Algorithms) { 
                            $CollectedHashrate = $Miner.CollectHashrate($Algorithm, (-not $Miner.Benchmark -and $Miner.Data.Count -lt $Miner.MinDataSample))
                            $Miner.Hashrates_Live += [Double]($CollectedHashrate[1])
                            $Miner_Hashrates.$Algorithm = [Double]($CollectedHashrate[0])
                        }
                        Remove-Variable Algorithm
                        If ($Miner.ReadPowerUsage) { 
                            # Collect power usage from miner, returns an array of two values (safe, unsafe)
                            $CollectedPowerUsage = $Miner.CollectPowerUsage(-not $Miner.MeasurePowerUsage -and $Miner.Data.Count -lt $Miner.MinDataSample)
                            $Miner.PowerUsage_Live = [Double]($CollectedPowerUsage[1])
                            $PowerUsage = [Double]($CollectedPowerUsage[0])
                        }
                    }

                    # Do not save data if stat just got removed (Miner.Activated < 1, set by API)
                    If ($Miner.Activated -gt 0 -and ($Miner.Benchmark -or $Miner.MeasurePowerUsage -or -not $Config.DryRun)) { 
                        # We don't want to store hashrates if we have less than $MinDataSample
                        If ($Miner.Data.Count -ge $Miner.MinDataSample -or $Miner.Activated -gt $Variables.WatchdogCount) { 
                            $Miner.StatEnd = (Get-Date).ToUniversalTime()
                            $Stat_Span = [TimeSpan]($Miner.StatEnd - $Miner.StatStart)

                            ForEach ($Worker in $Miner.WorkersRunning) { 
                                $Algorithm = $Worker.Pool.Algorithm
                                $Factor = 1
                                $LatestMinerSharesData = ($Miner.Data | Select-Object -Last 1 -ErrorAction Ignore).Shares
                                If ($Miner.Data.Count -gt $Miner.MinDataSample -and -not $Miner.Benchmark -and $Config.SubtractBadShares -and $LatestMinerSharesData.$Algorithm -gt 0) { # Need $Miner.MinDataSample shares before adjusting hashrate
                                    $Factor = (1 - $LatestMinerSharesData.$Algorithm[1] / $LatestMinerSharesData.$Algorithm[3])
                                    $Miner_Hashrates.$Algorithm *= $Factor
                                }
                                $Stat_Name = "$($Miner.Name)_$($Algorithm)_Hashrate"
                                $Stat = Set-Stat -Name $Stat_Name -Value $Miner_Hashrates.$Algorithm -Duration $Stat_Span -FaultDetection ($Miner.Data.Count -ge $Miner.MinDataSample) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                                If ($Stat.Updated -gt $Miner.StatStart) { 
                                    Write-Message -Level Info "Saved hashrate for '$($Stat_Name -replace '_Hashrate$')': $(($Miner_Hashrates.$Algorithm | ConvertTo-Hash) -replace ' ')$(If ($Factor -le 0.999) { " (adjusted by factor $($Factor.ToString('N3')) [Shares total: $($LatestMinerSharesData.$Algorithm[2]), rejected: $($LatestMinerSharesData.$Algorithm[1])])" })$(If ($Stat.Duration -eq $Stat_Span) { " [Benchmark done]" })."
                                    $Miner.StatStart = $Miner.StatEnd
                                    $Variables.AlgorithmsLastUsed.($Worker.Pool.Algorithm) = @{ Updated = $Stat.Updated; Benchmark = $Miner.Benchmark; MinerName = $Miner.Name }
                                    $Variables.PoolsLastUsed.($Worker.Pool.BaseName) = $Stat.Updated # most likely this will count at the pool to keep balances alive
                                }
                                ElseIf ($Miner_Hashrates.$Algorithm -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($Miner_Hashrates.$Algorithm -gt $Stat.Week * 2 -or $Miner_Hashrates.$Algorithm -lt $Stat.Week / 2)) { # Stop miner if new value is outside ±200% of current value
                                    $Miner.StatusMessage = "$($Miner.Name) $($Miner.Info): Reported hashrate is unreal ($($Algorithm): $(($Miner_Hashrates.$Algorithm | ConvertTo-Hash) -replace ' ') is not within ±200% of stored value of $(($Stat.Week | ConvertTo-Hash) -replace ' '))."
                                    $Miner.SetStatus([MinerStatus]::Failed)
                                }
                            }
                            Remove-Variable Worker -ErrorAction Ignore
                        }
                        # We don't want to store power usage if we have less than $MinDataSample, store even when fluctuating hash rates were recorded
                        If ($Miner.Data.Count -ge $Miner.MinDataSample -and $Miner.ReadPowerUsage -and ($Miner.Hashrates_Live -gt 0 -or $Miner.Activated -gt $Variables.WatchdogCount)) { 
                            If ([Double]::IsNaN($PowerUsage)) { $PowerUsage = 0 }
                            $Stat_Name = "$($Miner.Name)$(If ($Miner.Workers.Count -eq 1) { "_$($Miner.Workers.Pool.Algorithm | Select-Object -First 1)" })_PowerUsage"
                            $Stat = Set-Stat -Name $Stat_Name -Value $PowerUsage -Duration $Stat_Span -FaultDetection ($Miner.Data.Count -gt $Miner.MinDataSample) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                            If ($PowerUsage) { 
                                If ($Stat.Updated -gt $Miner.StatStart) { 
                                    Write-Message -Level Info "Saved power usage for '$($Stat_Name -replace '_PowerUsage$')': $($Stat.Live.ToString("N2"))W$(If ($Stat.Duration -eq $Stat_Span) { " [Power usage measurement done]" })."
                                }
                                ElseIf ($PowerUsage -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($PowerUsage -gt $Stat.Week * 2 -or $PowerUsage -lt $Stat.Week / 2)) { 
                                    # Stop miner if new value is outside ±200% of current value
                                    $Miner.StatusMessage = "$($Miner.Name) $($Miner.Info): Reported power usage is unreal ($($PowerUsage.ToString("N2"))W is not within ±200% of stored value of $(([Double]$Stat.Week).ToString("N2"))W)."
                                    $Miner.SetStatus([MinerStatus]::Failed)
                                }
                            }
                        }
                    }
                }
                Remove-Variable Miner -ErrorAction Ignore

                # Send data to monitoring server
                If ($Config.ReportToServer) { Write-MonitoringData }

                # Load unprofitable algorithms
                Try { 
                    If (-not $Variables.UnprofitableAlgorithms -or (Get-ChildItem -Path ".\Data\UnprofitableAlgorithms.json").LastWriteTime -gt $Variables.Timer.AddSeconds( - $Config.Interval)) { 
                        $Variables.UnprofitableAlgorithms = Get-Content -Path ".\Data\UnprofitableAlgorithms.json" | ConvertFrom-Json -ErrorAction Stop -AsHashtable | Get-SortedObject
                        Write-Message -Level Info "Loaded list of unprofitable algorithms ($($Variables.UnprofitableAlgorithms.Count) $(If ($Variables.UnprofitableAlgorithms.Count -ne 1) { "entries" } Else { "entry" }))."
                    }
                }
                Catch { 
                    Write-Message -Level Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file. Please restore it from your original download."
                    $Variables.UnprofitableAlgorithms = $null
                }

                # Faster shutdown
                If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

                # For debug only
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                $PoolTimeStamp = If ($Variables.PoolDataCollectedTimeStamp) { $Variables.PoolDataCollectedTimeStamp } Else { $Variables.ScriptStartTime }

                # Wait for all brains
                While (($Variables.Brains.Keys | Where-Object { $Variables.Brains.$_.Updated -ge $PoolTimeStamp }).Count -lt $Variables.Brains.Keys.Count -and (Get-Date).ToUniversalTime() -lt $Variables.Timer.AddSeconds($Variables.PoolTimeout)) { 
                    Start-Sleep -Seconds 1
                }

                # Collect pool data
                $Variables.PoolsCount = $Variables.Pools.Count
                $PoolsNew = [Pool[]]@()
                If ($Variables.PoolName) { 
                    $Variables.PoolName | ForEach-Object { 
                        $PoolBaseName = Get-PoolBaseName $_
                        & ".\Pools\$($PoolBaseName).ps1" -Config $Config -PoolVariant $_ -Variables $Variables
                    } | ForEach-Object { 
                        $Pool = [Pool]$_
                        $Pool.CoinName = Get-CoinName $_.Currency
                        $Pool.Fee = If ($Config.IgnorePoolFee -or $Pool.Fee -lt 0 -or $Pool.Fee -gt 1) { 0 } Else { $Pool.Fee }
                        $Factor = $_.EarningsAdjustmentFactor * (1 - $Pool.Fee)
                        $Pool.Price *= $Factor
                        $Pool.Price_Bias = $Pool.Price * $Pool.Accuracy
                        $Pool.StablePrice *= $Factor
                        $PoolsNew += $Pool
                    }
                    $Variables.PoolsNew = $PoolsNew

                    If ($PoolNoData = @(Compare-Object @($Variables.PoolName) @($PoolsNew.Name | Sort-Object -Unique) -PassThru)) { 
                        Write-Message -Level Warn "No data received from pool$(If ($PoolNoData.Count -gt 1) { "s" }) '$($PoolNoData -join ', ')'."
                    }
                    $Variables.PoolDataCollectedTimeStamp = (Get-Date).ToUniversalTime()

                    # Faster shutdown
                    If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

                    # Remove de-configured pools
                    $PoolsDeconfigured = @($Variables.Pools | Where-Object Name -notin $Variables.PoolName)
                    $Pools = @($Variables.Pools | Where-Object Name -in $Variables.PoolName)
                    $Pools | ForEach-Object { $_.Reasons = @() }

                    If ($ComparePools = @(Compare-Object -PassThru $PoolsNew $Pools -Property Name, Algorithm -IncludeEqual)) { 
                        # Find added & updated pools
                        $Variables.PoolsAdded = @($ComparePools | Where-Object SideIndicator -EQ "<=")
                        $Variables.PoolsUpdated = @($ComparePools | Where-Object SideIndicator -EQ "==")
                        $Pools += $Variables.PoolsAdded

                        $ComparePools | ForEach-Object { $_.PSObject.Properties.Remove("SideIndicator") }

                        # Update existing pools
                        $Pools | ForEach-Object { 
                            $_.Available = $true
                            $_.Best = $false

                            If ($Pool = $Variables.PoolsUpdated | Where-Object Name -EQ $_.Name | Where-Object Algorithm -EQ $_.Algorithm | Select-Object -First 1) { 
                                $_.Accuracy                 = $Pool.Accuracy
                                $_.CoinName                 = $Pool.CoinName
                                $_.Currency                 = $Pool.Currency
                                $_.Disabled                 = $Pool.Disabled
                                $_.EarningsAdjustmentFactor = $Pool.EarningsAdjustmentFactor
                                $_.Fee                      = $Pool.Fee
                                $_.Host                     = $Pool.Host
                                $_.Pass                     = $Pool.Pass
                                $_.Port                     = $Pool.Port
                                $_.PortSSL                  = $Pool.PortSSL
                                $_.Price                    = $Pool.Price
                                $_.Price_Bias               = $Pool.Price_Bias
                                $_.Protocol                 = $Pool.Protocol
                                $_.Reasons                  = $Pool.Reasons
                                $_.Region                   = $Pool.Region
                                $_.SendHashrate             = $Pool.SendHashrate
                                $_.SSLSelfSignedCertificate = $Pool.SSLSelfSignedCertificate
                                $_.StablePrice              = $Pool.StablePrice
                                $_.Updated                  = $Pool.Updated
                                $_.User                     = $Pool.User
                                $_.Workers                  = $Pool.Workers
                                $_.WorkerName               = $Pool.WorkerName
                            }
                            If ($Variables.DAGdata.Currency.($_.Currency).BlockHeight) { 
                                $_.BlockHeight = $Variables.DAGdata.Currency.($_.Currency).BlockHeight
                                $_.Epoch       = $Variables.DAGdata.Currency.($_.Currency).Epoch
                                $_.DAGSizeGiB  = $Variables.DAGdata.Currency.($_.Currency).DAGsize / 1GB 
                            }
                            ElseIf ($Variables.DAGdata.Algorithm.($_.Algorithm).BlockHeight) { 
                                $_.BlockHeight = $Variables.DAGdata.Algorithm.($_.Algorithm).BlockHeight
                                $_.Epoch       = $Variables.DAGdata.Algorithm.($_.Algorithm).Epoch
                                $_.DAGSizeGiB  = $Variables.DAGdata.Algorithm.($_.Algorithm).DAGsize / 1GB
                            }

                            # Ports[0] = non-SSL, Port[1] = SSL
                            $_.PoolPorts = @($(If ($Config.SSL -ne "Always" -and $_.Port) { [UInt16]$_.Port } Else { $null }), $(If ($Config.SSL -ne "Never" -and $_.PortSSL) { [UInt16]$_.PortSSL } Else { $null }))
                        }

                        # Pool data is older than earliest CycleStart, decay price
                        If ($Variables.CycleStarts.Count -ge $Config.SyncWindow) { 
                            $Pools = @($Pools | Where-Object { $_.Updated -gt (Get-Date).AddDays(-1) }) # Remove Pools that have not been updated for 1 day
                            $MaxPoolAge = $Config.SyncWindow * $Config.SyncWindow * $Config.SyncWindow * ($Variables.CycleStarts[-1] - $Variables.CycleStarts[0]).TotalMinutes
                            $Pools | ForEach-Object { 
                                If ([Math]::Floor(($Variables.CycleStarts[-1] - $_.Updated).TotalMinutes) -gt $MaxPoolAge) { $_.Reasons += "Data too old" }
                                ElseIf ($_.Updated -lt $Variables.CycleStarts[0]) { $_.Price_Bias = $_.Price * $_.Accuracy * [Math]::Pow(0.9, ($Variables.CycleStarts[0] - $_.Updated).TotalMinutes) }
                            }
                        }

                        # No username or wallet
                        $Pools | Where-Object { -not $_.User } | ForEach-Object { $_.Reasons += "No username or wallet" }
                        # Pool disabled by stat file
                        $Pools | Where-Object Disabled | ForEach-Object { $_.Reasons += "Disabled (by Stat file)" }
                        # Min accuracy not reached
                        $Pools | Where-Object Accuracy -LT $Config.MinAccuracy | ForEach-Object { $_.Reasons += "MinAccuracy ($($Config.MinAccuracy * 100)%) not reached" }
                        # Filter unavailable algorithms
                        If ($Config.MinerSet -lt 2) { $Pools | Where-Object { $Variables.UnprofitableAlgorithms.($_.Algorithm) -eq "*" } | ForEach-Object { $_.Reasons += "Unprofitable Algorithm" } }
                        # Pool price 0
                        $Pools | Where-Object Price -EQ 0 | ForEach-Object { $_.Reasons += "Price -eq 0" }
                        # No price data
                        $Pools | Where-Object Price -EQ [Double]::NaN | ForEach-Object { $_.Reasons += "No price data" }
                        # Ignore pool if price is more than $Config.UnrealPoolPriceFactor higher than second highest price of all other pools with same algorithm; NiceHash & MiningPoolHub are always right
                        If ($Config.UnrealPoolPriceFactor -gt 1 -and ($Pools.BaseName | Sort-Object -Unique).Count -gt 1) { 
                            $Pools | Where-Object Price_Bias -gt 0 | Group-Object -Property Algorithm | Where-Object { $_.Count -ge 2 } | ForEach-Object { 
                                If ($PriceThreshold = @($_.Group.Price_Bias | Sort-Object -Unique)[-2] * $Config.UnrealPoolPriceFactor) { 
                                    $_.Group | Where-Object { $_.BaseName -notmatch "NiceHash|MiningPoolHub" } | Where-Object Price_Bias -GT $PriceThreshold | ForEach-Object { $_.Reasons += "Unreal price ($($Config.UnrealPoolPriceFactor)x higher than second highest price)" }
                                }
                            }
                        }
                        # Algorithms disabled
                        $Pools | Where-Object { "-$($_.Algorithm)" -in $Config.Algorithm } | ForEach-Object { $_.Reasons += "Algorithm disabled (``-$($_.Algorithm)`` in generic config)" }
                        $Pools | Where-Object { "-$($_.Algorithm)" -in $Variables.PoolsConfig.$($_.BaseName).Algorithm } | ForEach-Object { $_.Reasons += "Algorithm disabled (``-$($_.Algorithm)`` in $($_.BaseName) pool config)" }
                        # Algorithms not enabled
                        If ($Config.Algorithm -like "+*") { $Pools | Where-Object { "+$($_.Algorithm)" -notin $Config.Algorithm } | ForEach-Object { $_.Reasons += "Algorithm not enabled in generic config" } }
                        $Pools | Where-Object { $Variables.PoolsConfig.$($_.BaseName).Algorithm -like "+*" } | Where-Object { "+$($_.Algorithm)" -notin $Variables.PoolsConfig.$($_.BaseName).Algorithm } | ForEach-Object { $_.Reasons += "Algorithm not enabled in $($_.BaseName) pool config" }
                        # MinWorkers
                        $Pools | Where-Object { $null -ne $_.Workers -and $_.Workers -lt $Variables.PoolsConfig.$($_.BaseName).MinWorker } | ForEach-Object { $_.Reasons += "Not enough workers at pool (MinWorker ``$($Variables.PoolsConfig.$($_.BaseName).MinWorker)`` in $($_.BaseName) pool config)" }
                        $Pools | Where-Object { $null -ne $_.Workers -and $_.Workers -lt $Config.MinWorker } | ForEach-Object { $_.Reasons += "Not enough workers at pool (MinWorker ``$($Config.MinWorker)`` in generic config)" }
                        # SSL
                        If ($Config.SSL -eq "Never") { $Pools | Where-Object { $_.PoolPorts[1] } | ForEach-Object { $_.Reasons += "Non-SSL port not available (Config.SSL -eq 'Never')" } }
                        If ($Config.SSL -eq "Always") { $Pools | Where-Object { -not $_.PoolPorts[1] } | ForEach-Object { $_.Reasons += "SSL port not available (Config.SSL -eq 'Always')" } }
                        # SSL Allow selfsigned certificate
                        If (-not $Config.SSLAllowSelfSignedCertificate) { $Pools | Where-Object SSLSelfSignedCertificate | ForEach-Object { $_.Reasons += "Pool uses self signed certificate (Config.SSLAllowSelfSignedCertificate -eq '`$false')" } }
                        # Update pools last used, required for BalancesKeepAlive
                        If ($Variables.PoolsLastUsed) { $Variables.PoolsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -FilePath ".\Data\PoolsLastUsed.json" -Force -Encoding utf8NoBOM}
                        If ($Variables.AlgorithmsLastUsed) { $Variables.AlgorithmsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -FilePath ".\Data\AlgorithmsLastUsed.json" -Force -Encoding utf8NoBOM}

                        # Apply watchdog to pools
                        If ($Config.Watchdog) { 
                            $Pools | Where-Object Available | Group-Object -Property Name | ForEach-Object { 
                                # Suspend pool if > 50% of all algorithms@pool failed
                                $PoolName = $_.Name
                                $WatchdogCount = ($Variables.WatchdogCount, ($Variables.WatchdogCount * $_.Group.Count / 2), (($Variables.Miners | Where-Object Best | Where-Object { $_.Workers.Pool.Name -eq $PoolName }).count) | Measure-Object -Maximum).Maximum
                                If ($PoolsToSuspend = $_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object PoolName -EQ $PoolName | Where-Object Kicked -LT $Variables.Timer).Count -gt $WatchdogCount }) { 
                                    $PoolsToSuspend | ForEach-Object { 
                                        $_.Available = $false
                                        $_.Reasons += "Pool suspended by watchdog"
                                    }
                                    Write-Message -Level Warn "Pool '$($_.Name)' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object PoolName -EQ $_.Name | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -First 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                }
                            }
                            $Pools | Where-Object Available | Group-Object -Property Algorithm, Name | ForEach-Object { 
                                # Suspend algorithm@pool if > 50% of all possible miners for algorithm failed
                                $WatchdogCount = ($Variables.WatchdogCount, (($Variables.Miners | Where-Object Algorithm2 -contains $_.Group[0].Algorithm).Count / 2) | Measure-Object -Maximum).Maximum + 1
                                If ($PoolsToSuspend = $_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object Algorithm -EQ $_.Algorithm | Where-Object PoolName -EQ $_.Name | Where-Object Kicked -LT $Variables.CycleStarts[-2]).Count -gt $WatchdogCount }) { 
                                    $PoolsToSuspend | ForEach-Object { $_.Reasons += "Algorithm@Pool suspended by watchdog" }
                                    Write-Message -Level Warn "Algorithm@Pool '$($_.Group[0].Algorithm)@$($_.Group[0].Name)' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object Algorithm -EQ $_.Group[0].Algorithm | Where-Object PoolName -EQ $_.Group[0].Name | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -First 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                }
                            }
                        }

                        # Make pools unavailable
                        $Pools | Where-Object Reasons | ForEach-Object { $_.Available = $false }

                        # Filter pools on miner set
                        If ($Config.MinerSet -lt 2) { 
                            $Pools | Where-Object { $Variables.UnprofitableAlgorithms.($_.Algorithm) -eq 1 } | ForEach-Object { $_.Reasons += "Unprofitable primary algorithm" }
                            $Pools | Where-Object { $Variables.UnprofitableAlgorithms.($_.Algorithm) -eq 2 } | ForEach-Object { $_.Reasons += "Unprofitable secondary algorithm" }
                        }

                        If ($Variables.Pools.Count -gt 0) { 
                            Write-Message -Level Info "Had $($Variables.PoolsCount) pool$(If ($Variables.PoolsCount -ne 1) { "s" }),$(If ($PoolsDeconfigured) { " removed $($PoolsDeconfigured.Count) deconfigured pool$(If ($PoolsDeconfigured.Count -ne 1) { "s" } )," }) found $($Variables.PoolsAdded.Count) new pool$(If ($Variables.PoolsAdded.Count -ne 1) { "s" }), updated $($Variables.PoolsUpdated.Count) pool$(If ($Variables.PoolsUpdated.Count -ne 1) { "s" }), filtered out $(@($Pools | Where-Object Available -NE $true).Count) pool$(If (@($Pools | Where-Object Available -NE $true).Count -ne 1) { "s" }). $(@($Pools | Where-Object Available).Count) available pool$(If (@($Pools | Where-Object Available).Count -ne 1) { "s" }) remain$(If (@($Pools | Where-Object Available).Count -eq 1) { "s" })."
                        }
                        Else { 
                            Write-Message -Level Info "Found $($PoolsNew.Count) pool$(If ($PoolsNew.Count -ne 1) { "s" }), filtered out $(@($Pools | Where-Object Available -NE $true).Count) pool$(If (@($Pools | Where-Object Available -NE $true).Count -ne 1) { "s" }). $(@($Pools | Where-Object Available).Count) available pool$(If (@($Pools | Where-Object Available).Count -ne 1) { "s" }) remain$(If (@($Pools | Where-Object Available).Count -eq 1) { "s" })."
                        }

                        # Keep pool balances alive; force mining at pool even if it is not the best for the algo
                        If ($Config.BalancesKeepAlive -and $Variables.BalancesTrackerRunspace -and $Variables.PoolsLastEarnings.Count -gt 0 -and $Variables.PoolsLastUsed) { 
                            $Variables.PoolNameToKeepBalancesAlive = @()
                            ForEach ($Pool in @($Pools | Where-Object Name -notin $Config.BalancesTrackerExcludePool | Sort-Object Name -Unique)) { 
                                If ($Variables.PoolsLastEarnings.$($Pool.BaseName) -and $Variables.PoolsConfig.$($Pool.BaseName).BalancesKeepAlive -gt 0 -and ((Get-Date).ToUniversalTime() - $Variables.PoolsLastEarnings.$($Pool.BaseName)).Days -ge ($Variables.PoolsConfig.$($Pool.BaseName).BalancesKeepAlive - 10)) { 
                                    $Variables.PoolNameToKeepBalancesAlive += $PoolName
                                    Write-Message -Level Warn "Pool '$($Pool.BaseName)' prioritized to avoid forfeiting balance (pool would clear balance in 10 days)."
                                }
                            }
                            If ($Variables.PoolNameToKeepBalancesAlive) { 
                                $Pools | ForEach-Object { 
                                    If ($_.BaseName -in $Variables.PoolNameToKeepBalancesAlive) { $_.Available = $true; $_.Reasons = "Prioritized by BalancesKeepAlive" }
                                    Else { $_.Reasons += "BalancesKeepAlive prioritizes other pools" }
                                }
                            }
                        }

                        # Sort best pools
                        $SortedAvailablePools = $Pools | Where-Object Available | Sort-Object { $_.Name -notin $Variables.PoolNameToKeepBalancesAlive }, { - $_.StablePrice * $_.Accuracy }
                        $SortedAvailablePools.Algorithm | Select-Object -Unique | ForEach-Object { 
                            $SortedAvailablePools | Where-Object Algorithm -EQ $_ | Select-Object -First 1 | ForEach-Object { $_.Best = $true }
                        }
                    }
                    # Update GUIs as soon as possible
                    If (-not $Variables.Pools) { $Variables.RefreshNeeded = $true }

                    # Update data in API
                    $Variables.Pools = $Pools
                }
                Else { 
                    # No configuired pools, clear all pools
                    $Variables.Pools = [Pool[]]@()
                }

                Remove-Variable Pools, PoolsDeconfigured, PoolsNew -ErrorAction Ignore
                [System.GC]::Collect()

                $Variables.PoolsBest = $Variables.Pools | Where-Object Best | Sort-Object Algorithm

                # Tuning parameters require local admin rights
                $Variables.UseMinerTweaks = ($Variables.IsLocalAdmin -and $Config.UseMinerTweaks)
            }

            # Faster shutdown
            If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

            # For debug only
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Get new miners
            $Miners = $Variables.Miners.Clone() # Much faster
            If ($Variables.PoolsBest) { 
                $AllPools = @{ }
                $MinerPools = @(@{ }, @{ })
                $Variables.PoolsBest | ForEach-Object { 
                    $AllPools[$_.Algorithm] = $_
                    If ($_.Reasons -notcontains "Unprofitable primary algorithm") { $MinerPools[0][$_.Algorithm] = $_ } # Allow unprofitable algos for primary algorithm
                    If ($_.Reasons -notcontains "Unprofitable secondary algorithm") { $MinerPools[1][$_.Algorithm] = $_ } # Allow unprofitable algos for secondary algorithm
                }
                $Variables.MinerPools = $MinerPools

                If ($MinerPools[0].Keys) { 
                    If (-not ($Variables.Pools -and $Variables.Miners)) { $Variables.Summary = "Loading miners.<br>This will take a while..." }
                    Remove-Variable NewMiners -ErrorAction Ignore
                    [System.GC]::Collect()
                    Write-Message -Level Info "Loading miners..."
                    $NewMiners = [Miner[]]@()
                    Get-ChildItem -Path ".\Miners\*.ps1" | ForEach-Object { 
                        & $_
                    } | ForEach-Object { 
                        Try { 
                            $_ | Add-Member MinDataSample  ([Int]($Config.MinDataSample * (($_.Algorithms | Select-Object | ForEach-Object { $Config.MinDataSampleAlgoMultiplier.$_ }), 1 | Measure-Object -Maximum).Maximum))
                            $_ | Add-Member ProcessPriority $(If ($_.Type -eq "CPU") { $Config.CPUMinerProcessPriority } Else { $Config.GPUMinerProcessPriority })
                            $_ | Add-Member Workers ([Worker[]]@(ForEach ($Algorithm in $_.Algorithms) { @{ Pool = $AllPools.$Algorithm; Fee = If ($Config.IgnoreMinerFee) { 0 } Else { $_.Fee | Select-Object -Index $_.Algorithms.IndexOf($Algorithm) } } }))
                            $_.PSObject.Properties.Remove("Fee")
                            $NewMiners += $_ -as $_.API
                        }
                        Catch { 
                            Write-Message -Level Error "Failed to add Miner '$($_.Name)' as '$($_.API)' ($($_ | ConvertTo-Json -Compress))"
                        }
                    }
                    Remove-Variable Algorithm -ErrorAction Ignore

                    If ($NewMiners) { # Sometimes there are no miners loaded, keep existing
                        $CompareMiners = Compare-Object -PassThru $Miners $NewMiners -Property Name, Algorithms -IncludeEqual
                        # Properties that need to be set only once and which are not dependent on any config variables
                        $CompareMiners | Where-Object SideIndicator -EQ "=>" | ForEach-Object { 
                            $_.BaseName = $_.Name -split '-' | Select-Object -Index 0
                            $_.Devices  = [Device[]]($Variables.Devices | Where-Object Name -in $_.DeviceNames)
                            $_.Path     = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_.Path)
                            $_.Version  = $_.Name -split '-' | Select-Object -Index 1
                        }
                        $Miners = $CompareMiners | Where-Object SideIndicator -NE "<="
                    }
                }
            }

            If ($Miners -and $Variables.PoolsBest) { 
                $Miners | ForEach-Object { 
                    If ($_.KeepRunning = ($_.Status -eq [MinerStatus]::Running -or $_.Status -eq [MinerStatus]::DryRun) -and -not ($_.Benchmark -or $_.MeasurePowerUsage -or $Variables.DonationRandom) -and $_.Cycle -lt $Config.MinCycle) { # Minimum numbers of full cycles not yet reached
                        $_.Restart = $false
                    }
                    Else { 
                        If ($Miner = Compare-Object -PassThru $NewMiners $_ -Property Name, Algorithms -ExcludeDifferent | Select-Object) { 
                            # Update existing miners
                            If ($_.Restart = $_.Arguments -ne $Miner.Arguments) { 
                                $_.Arguments = $Miner.Arguments
                                $_.Port = $Miner.Port
                                $_.Workers = $Miner.Workers
                            }
                            $_.CommandLine = $_.GetCommandLine().Replace("$(Convert-Path '.\')\", "").Replace("^\.\\", "")
                            $_.PrerequisitePath = $Miner.PrerequisitePath
                            $_.PrerequisiteURI = $Miner.PrerequisiteURI
                            $_.WarmupTimes = $Miner.WarmupTimes
                        }
                    }
                    $_.Refresh($Variables.PowerCostBTCperW, $Variables.CalculatePowerCost)
                    $_.WindowStyle = If ($Config.MinerWindowStyleNormalWhenBenchmarking -and $_.Benchmark) { "normal" } Else { $Config.MinerWindowStyle }
                }

                # Faster shutdown
                If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

                # For debug only
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                # Filter miners
                $Miners | Where-Object Disabled | ForEach-Object { $_.Reasons += "Disabled by user"; $_.Status = [MinerStatus]::Disabled }
                $Miners | Where-Object { $_.Workers[0].Hashrate -eq 0 } | ForEach-Object { $_.Reasons += "0 H/s Stat file" } # Allow 0 hashrate for secondary algorithm
                If ($Config.ExcludeMinerName.Count) { $Miners | Where-Object { (Compare-Object $Config.ExcludeMinerName @($_.BaseName, "$($_.BaseName)-$($_.Version)", $_.Name | Select-Object -Unique) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | ForEach-Object { $_.Reasons += "ExcludeMinerName ($($Config.ExcludeMinerName -Join ', '))" } }
                $Miners | Where-Object Earning -EQ 0 | ForEach-Object { $_.Reasons += "Earning -eq 0" }
                If ($Config.DisableMinersWithFee) { $Miners | Where-Object { $_.Workers.Fee } | ForEach-Object { $_.Reasons += "Config.DisableMinersWithFee" } }
                If ($Config.DisableDualAlgoMining) { $Miners | Where-Object { $_.Workers.Count -eq 2 } | ForEach-Object { $_.Reasons += "Config.DisableDualAlgoMining" } }
                ElseIf ($Config.DisableSingleAlgoMining) { $Miners | Where-Object { $_.Workers.Count -eq 1 } | ForEach-Object { $_.Reasons += "Config.DisableSingleAlgoMining" } }

                # Detect miners with unreal earning (> x times higher than average of the next best 10% or at least 5 miners)
                If ($Config.UnrealMinerEarningFactor -gt 1) { 
                    $Miners | Where-Object { -not $_.Reasons } | Group-Object { $_.DeviceNames } | ForEach-Object { 
                        If ($ReasonableEarning = [Double]($_.Group | Sort-Object -Descending Earning | Select-Object -Skip 1 -First (5, [Int]($_.Group.Count / 10) | Measure-Object -Maximum).Maximum | Measure-Object Earning -Average).Average * $Config.UnrealMinerEarningFactor) { 
                            $_.Group | Where-Object Earning -GT $ReasonableEarning | ForEach-Object { $_.Reasons += "Unreal profit data (-gt $($Config.UnrealMinerEarningFactor)x higher than the next best miners available miners)" }
                        }
                    }
                }

                $Variables.MinersMissingBinary = @()
                $Miners | Where-Object { -not $_.Reasons -and -not (Test-Path -Path $_.Path -Type Leaf) } | ForEach-Object { $_.Reasons += "Binary missing"; $Variables.MinersMissingBinary += $_ }

                $Variables.MinersMissingPrerequisite = @()
                $Miners | Where-Object { -not $_.Reasons -and $_.PrerequisitePath } | ForEach-Object { $_.Reasons += "Prerequisite missing ($(Split-Path -Path $_.PrerequisitePath -Leaf))"; $Variables.MinersMissingPrerequisite += $_ }

                # Apply watchdog to miners
                If ($Config.Watchdog) { 
                    $Miners | Where-Object { -not $_.Reasons } | Group-Object -Property { "$($_.BaseName)-$($_.Version)" } | ForEach-Object { 
                        # Suspend miner if > 50% of all available algorithms failed
                        $WatchdogMinerCount = ($Variables.WatchdogCount, [Math]::Ceiling($Variables.WatchdogCount * $_.Group.Count / 2) | Measure-Object -Maximum).Maximum
                        If ($MinersToSuspend = @($_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object MinerBaseName -EQ $_.BaseName | Where-Object MinerVersion -EQ $_.Version | Where-Object Kicked -LT $Variables.Timer).Count -gt $WatchdogMinerCount })) { 
                            $MinersToSuspend | ForEach-Object { 
                                $_.Data = @() # Clear data because it may be incorrect caused by miner problem
                                $_.Reasons += "Miner suspended by watchdog (all algorithms)"
                            }
                            Write-Message -Level Warn "Miner '$($_.Group[0].BaseName)-$($_.Group[0].Version) [all algorithms]' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object MinerBaseName -EQ $_.Group[0].BaseName | Where-Object MinerVersion -EQ $_.Group[0].Version | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -Last 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                        }
                    }
                    $Miners | Where-Object { -not $_.Reasons } | Where-Object { @($Variables.WatchdogTimers | Where-Object MinerName -EQ $_.Name | Where-Object DeviceNames -EQ $_.DeviceNames | Where-Object Algorithm -EQ $_.Algorithm | Where-Object Kicked -LT $Variables.Timer).Count -ge $Variables.WatchdogCount } | ForEach-Object { 
                        $_.Data = @() # Clear data because it may be incorrect caused by miner problem
                        $_.Reasons += "Miner suspended by watchdog (Algorithm $($_.Algorithm))"
                        Write-Message -Level Warn "Miner '$($_.Name) [$($_.Algorithm)]' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object MinerName -EQ $_.Name | Where-Object DeviceNames -EQ $_.DeviceNames | Where-Object Algorithm -EQ $_.Algorithm | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -Last 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                    }
                }

                $Miners | Where-Object Reasons | ForEach-Object { $_.Available = $false }

                $Variables.MinersNeedingBenchmark = @($Miners | Where-Object { $_.Available -and  $_.Benchmark })
                $Variables.MinersNeedingPowerUsageMeasurement = @($Miners | Where-Object { $_.Available -and $_.MeasurePowerUsage })

                Write-Message -Level Info "Loaded $($Miners.Count) miner$(If ($Miners.Count -ne 1) { "s" }), filtered out $(($Miners | Where-Object Available -NE $true).Count) miner$(If (($Miners | Where-Object Available -NE $true).Count -ne 1) { "s" }). $(($Miners | Where-Object Available).Count) available miner$(If (($Miners | Where-Object Available).Count -ne 1) { "s" }) remain$(If (($Miners | Where-Object Available).Count -eq 1) { "s" })."

                $DownloadList = @($Variables.MinersMissingPrerequisite | Select-Object @{ Name = "URI"; Expression = { $_.PrerequisiteURI } }, @{ Name = "Path"; Expression = { $_.PrerequisitePath } }, @{ Name = "Searchable"; Expression = { $false } }) + @($Variables.MinersMissingBinary | Select-Object URI, Path, @{ Name = "Searchable"; Expression = { $false } }) | Select-Object * -Unique
                If ($DownloadList) { 
                    If ($Variables.Downloader.State -ne "Running") { 
                        # Download miner binaries
                        Write-Message -Level Info "Some miners binaries are missing ($($DownloadList.Count) item$(If ($DownloadList.Count -ne 1) { "s" })), starting downloader..."
                        $Downloader_Parameters = @{ 
                            Config = $Global:Config
                            DownloadList = $DownloadList
                            Variables = $Variables
                        }
                        $Variables.Downloader = Start-ThreadJob -Name Downloader -InitializationScript ([scriptblock]::Create("Set-Location '$($Variables.MainPath)'")) -ArgumentList $Downloader_Parameters -FilePath ".\Includes\Downloader.ps1"
                    }
                    ElseIf (-not ($Miners | Where-Object Available)) { 
                        Write-Message -Level Info "Waiting 30 seconds for downloader to install binaries..."
                    }
                }

                # Open firewall ports for all miners
                If ($Config.OpenFirewallPorts) { 
                    If (Get-Command "Get-MpPreference") { 
                        If ((Get-Command "Get-MpComputerStatus") -and (Get-MpComputerStatus)) { 
                            If (Get-Command "Get-NetFirewallRule") { 
                                If ($MissingMinerFirewallRules = Compare-Object @((Get-NetFirewallApplicationFilter).Program) @($Miners | Select-Object -ExpandProperty Path -Unique) -PassThru | Where-Object SideIndicator -EQ "=>") { 
                                    Start-Process "pwsh" ("-Command Import-Module NetSecurity; ('$($MissingMinerFirewallRules | ConvertTo-Json -Compress)' | ConvertFrom-Json) | ForEach-Object { New-NetFirewallRule -DisplayName (Split-Path `$_ -leaf) -Program `$_ -Description 'Inbound rule added by $($Variables.Branding.ProductLabel) $($Variables.Branding.Version) on $((Get-Date).ToString())' -Group 'Cryptocurrency Miner' }" -replace '"', '\"') -Verb runAs
                                }
                            }
                        }
                    }
                }
            }
            Else { 
                $Miners | ForEach-Object { $_.Available = $false }
            }
            $Variables.MinersMostProfitable = $Variables.MinersBest = $Variables.Miners_Device_Combos = $Variables.MinersBest_Combos = $Variables.MinersBest_Combo = [Miner[]]@()

            If ($Miners | Where-Object Available) { 
                Write-Message -Level Info "Selecting best miner$(If (@($Variables.EnabledDevices.Model | Select-Object -Unique).Count -gt 1) { "s" }) based on$(If ($Variables.CalculatePowerCost) { " profit (power cost $($Config.Currency) $($Variables.PowerPricekWh)/kW⋅h)" } Else { " earning" })..."

                If (($Miners | Where-Object Available).Count -eq 1) { 
                    $Variables.MinersBest_Combo = $Variables.MinersBest = $Variables.MinersMostProfitable = $Miners
                }
                Else { 
                    If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { $Bias = "Profit_Bias" } Else { $Bias = "Earning_Bias" }

                    # Hack: temporarily make all bias positive, BestMiners_Combos(_Comparison) produces wrong sort order when earnings or profits are negative
                    $SmallestBias = [Double][Math]::Abs((($Miners | Where-Object Available | Where-Object { -not [Double]::IsNaN($_.$Bias) }).$Bias | Measure-Object -Minimum).Minimum) * 2
                    $Miners | ForEach-Object { $_.$Bias += $SmallestBias }

                    # Add running miner bonus
                    $RunningMinerBonusFactor = (1 + $Config.MinerSwitchingThreshold / 100)
                    $Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { $_.$Bias *= $RunningMinerBonusFactor}

                    # Get best miners per algorithm and device
                    $Variables.MinersMostProfitable = @($Miners | Where-Object Available | Group-Object { [String]$_.DeviceNames }, { [String]$_.Algorithms } | ForEach-Object { $_.Group | Sort-Object -Descending -Property Benchmark, MeasurePowerUsage, KeepRunning, Prioritize, $Bias, Activated, @{ Expression = { $_.WarmupTimes[1] + $_.MinDataSample }; Descending = $true }, Name, @{ Expression = { [String]($_.Algorithms) }; Descending = $false } -Top 1 | ForEach-Object { $_.MostProfitable = $true; $_ } })
                    $Variables.MinersBest = @($Variables.MinersMostProfitable | Group-Object { [String]$_.DeviceNames } | ForEach-Object { $_.Group | Sort-Object -Descending -Property Benchmark, MeasurePowerUsage, KeepRunning, Prioritize, $Bias, Activated, @{ Expression = { $_.WarmupTimes[1] + $_.MinDataSample }; Descending = $true }, Name -Top 1 })
                    $Variables.Miners_Device_Combos = @(Get-Combination @($Variables.MinersBest | Select-Object DeviceNames -Unique) | Where-Object { (Compare-Object ($_.Combination | Select-Object -ExpandProperty DeviceNames -Unique) ($_.Combination | Select-Object -ExpandProperty DeviceNames) | Measure-Object).Count -eq 0 })

                    # Get most best miner combination i.e. AMD+NVIDIA+CPU
                    $Variables.MinersBest_Combos = @(
                        $Variables.Miners_Device_Combos | ForEach-Object { 
                            $Miner_Device_Combo = $_.Combination
                            [PSCustomObject]@{ 
                                Combination = $Miner_Device_Combo | ForEach-Object { 
                                    $Miner_Device_Count = $_.DeviceNames.Count
                                    [Regex]$Miner_Device_Regex = "^(" + (($_.DeviceNames | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ")$"
                                    $Variables.MinersBest | Where-Object { ([Array]$_.DeviceNames -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.DeviceNames -match $Miner_Device_Regex).Count -eq $Miner_Device_Count }
                                }
                            }
                        }
                    )
                    $Variables.MinersBest_Combo = @(($Variables.MinersBest_Combos | Sort-Object -Descending { @($_.Combination | Where-Object { [Double]::IsNaN($_.$Bias) }).Count }, { ($_.Combination | Measure-Object $Bias -Sum).Sum }, { ($_.Combination | Where-Object { $_.$Bias -ne 0 } | Measure-Object).Count } -Top 1).Combination)

                    # Revert running miner bonus
                    $Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { $_.$Bias /= $RunningMinerBonusFactor }

                    # Hack part 2: reverse temporarily forced positive bias
                    $Miners | ForEach-Object { $_.$Bias -= $SmallestBias }
                }

                $Variables.PowerUsageIdleSystemW = (($Config.PowerUsageIdleSystemW - ($Variables.MinersBest_Combo | Where-Object Type -eq "CPU" | Measure-Object PowerUsage -Sum).Sum), 0 | Measure-Object -Maximum).Maximum

                $Variables.BasePowerCostBTC = [Double]($Variables.PowerUsageIdleSystemW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.Currency))

                $Variables.MiningEarning = [Double]($Variables.MinersBest_Combo | Measure-Object Earning -Sum).Sum
                $Variables.MiningPowerCost = [Double]($Variables.MinersBest_Combo | Measure-Object PowerCost -Sum).Sum
                $Variables.MiningPowerUsage = [Double]($Variables.MinersBest_Combo | Measure-Object PowerUsage -Sum).Sum
                $Variables.MiningProfit = [Double](($Variables.MinersBest_Combo | Measure-Object Profit -Sum).Sum - $Variables.BasePowerCostBTC)
            }
            Else { 
                $Variables.MiningEarning = $Variables.MiningProfit = $Variables.MiningPowerCost = $Variables.MiningPowerUsage = [Double]0
            }
        }

        # ProfitabilityThreshold check - OK to run miners?
        If ($Variables.DonationRunning -or (-not $Config.CalculatePowerCost -and $Variables.MiningEarning -ge ($Config.ProfitabilityThreshold / $Variables.Rates.BTC.($Config.Currency))) -or ($Config.CalculatePowerCost -and $Variables.MiningProfit -ge ($Config.ProfitabilityThreshold / $Variables.Rates.BTC.($Config.Currency))) -or $Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerUsageMeasurement) { 
            $Variables.MinersBest_Combo | ForEach-Object { $_.Best = $true }
            If ($Variables.Rates."BTC") { 
                If ($Variables.MinersNeedingBenchmark.Count) { 
                    $Variables.Summary = "Earning / day: n/a (Benchmarking: $($Variables.MinersNeedingBenchmark.Count) $(If ($Variables.MinersNeedingBenchmark.Count -eq 1) { "miner" } Else { "miners" }) left$(If (($Variables.EnabledDevices | Sort-Object -Property { $_.DeviceNames -join ', ' }).Count -gt 1) { " [$(($Variables.MinersNeedingBenchmark | Group-Object -Property { $_.DeviceNames -join ',' } | Sort-Object Name | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')]"}))"
                }
                ElseIf ($Variables.MiningEarning -gt 0) { 
                    $Variables.Summary = "Earning / day: {0:n} {1}" -f ($Variables.MiningEarning * $Variables.Rates."BTC".($Config.Currency)), $Config.Currency
                }
                Else { 
                    $Variables.Summary = ""
                }

                If ($Variables.CalculatePowerCost -and $Variables.PoolsBest) { 
                    If ($Variables.Summary -ne "") { $Variables.Summary += "&ensp;&ensp;&ensp;" }

                    If ($Variables.MinersNeedingPowerUsageMeasurement.Count -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                        $Variables.Summary += "Profit / day: n/a (Measuring power usage: $($Variables.MinersNeedingPowerUsageMeasurement.Count) $(If (($Variables.MinersNeedingPowerUsageMeasurement).Count -eq 1) { "miner" } Else { "miners" }) left$(If (($Variables.EnabledDevices | Sort-Object -Property { $_.DeviceNames -join ',' }).Count -gt 1) { " [$(($Variables.MinersNeedingPowerUsageMeasurement | Group-Object -Property { $_.DeviceNames -join ',' } | Sort-Object Name | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')]"}))"
                    }
                    ElseIf ($Variables.MinersNeedingBenchmark.Count) { 
                        $Variables.Summary += "Profit / day: n/a"
                    }
                    ElseIf ($Variables.MiningPowerUsage -gt 0) { 
                        $Variables.Summary += "Profit / day: {0:n} {1}" -f ($Variables.MiningProfit * $Variables.Rates."BTC".($Config.Currency)), $Config.Currency
                    }
                    Else { 
                        $Variables.Summary += "Profit / day: n/a (no power data)"
                    }

                    If ($Variables.CalculatePowerCost) { 
                        If ($Variables.Summary -ne "") { $Variables.Summary += "&ensp;&ensp;&ensp;" }

                        If ([Double]::IsNaN($Variables.MiningEarning) -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                            $Variables.Summary += "Power Cost / day: n/a&ensp;[Miner$(If ($Variables.MinersBest_Combo.Count -gt 1) { "s" }): n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Config.Currency, ($Variables.BasePowerCostBTC * $Variables.Rates."BTC".($Config.Currency)), $Variables.PowerUsageIdleSystemW
                        }
                        ElseIf ($Variables.MiningPowerUsage -gt 0) { 
                            $Variables.Summary += "Power Cost / day: {1:n} {0}&ensp;[Miner$(If ($Variables.MinersBest_Combo.Count -gt 1) { "s" }): {2:n} {0} ({3:n2} W); Base: {4:n} {0} ({5:n2} W)]" -f $Config.Currency, (($Variables.MiningPowerCost + $Variables.BasePowerCostBTC) * $Variables.Rates."BTC".($Config.Currency)), ($Variables.MiningPowerCost * $Variables.Rates."BTC".($Config.Currency)), $Variables.MiningPowerUsage, ($Variables.BasePowerCostBTC * $Variables.Rates."BTC".($Config.Currency)), $Variables.PowerUsageIdleSystemW
                        }
                        Else { 
                            $Variables.Summary += "Power Cost / day: n/a&ensp;[Miner: n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Config.Currency, ($Variables.BasePowerCostBTC * $Variables.Rates.BTC.($Config.Currency)), $Variables.PowerUsageIdleSystemW
                        }
                    }
                }
                If ($Variables.Summary -ne "") { $Variables.Summary += "<br>" }

                # Add currency conversion rates
                @(@(If ($Config.UsemBTC) { "mBTC" } Else { "BTC" }) + @($Config.ExtraCurrencies)) | Select-Object -Unique | Where-Object { $Variables.Rates.$_.($Config.Currency) } | ForEach-Object { 
                    $Variables.Summary += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Variables.Rates.$_.($Config.Currency) -DecimalsMax $Config.DecimalsMax)} $($Config.Currency)&ensp;&ensp;&ensp;" -f $Variables.Rates.$_.($Config.Currency)
                }
            }
            Else { 
                $Variables.Summary = "Error:<br>Could not get BTC exchange rate from min-api.cryptocompare.com"
            }
        }
        Else { 
            # Mining earning/profit is below threshold
            $Variables.MinersBest_Combo = [Miner[]]@()
            If ($Config.CalculatePowerCost) { 
                $Variables.Summary = "Mining profit {0} {1:n$($Config.DecimalsMax)} / day is below the configured threshold of {0} {2:n$($Config.DecimalsMax)} / day. Mining is suspended until threshold is reached." -f $Config.Currency, (($Variables.MiningEarning - $Variables.MiningPowerCost - $Variables.BasePowerCostBTC) * $Variables.Rates."BTC".($Config.Currency)), $Config.ProfitabilityThreshold
            }
            Else { 
                $Variables.Summary = "Mining earning {0} {1:n$($Config.DecimalsMax)} / day is below the configured threshold of {0} {2:n$($Config.DecimalsMax)} / day. Mining is suspended until threshold is reached." -f $Config.Currency, ($Variables.MiningEarning * $Variables.Rates."BTC".($Config.Currency)), $Config.ProfitabilityThreshold
            }
            Write-Message -Level Warn ($Variables.Summary -replace '<br>', ' ' -replace ' / day', '/day')
            If ($Variables.Rates) { 
                # Add currency conversion rates
                If ($Variables.Summary -ne "") { $Variables.Summary += "<br>" }
                @(@(If ($Config.UsemBTC) { "mBTC" } Else { "BTC" }) + @($Config.ExtraCurrencies)) | Select-Object -Unique | Where-Object { $Variables.Rates.$_.($Config.Currency) } | ForEach-Object { 
                    $Variables.Summary += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Variables.Rates.$_.($Config.Currency) -DecimalsMax $Config.DecimalsMax)} $($Config.Currency)&ensp;&ensp;&ensp;" -f $Variables.Rates.$_.($Config.Currency)
                }
            }
        }

        If (-not $Variables.MinersBest_Combo) { $Miners | ForEach-Object { $_.Best = $false } }

        # Stop running miners
        ForEach ($Miner in @(@($Miners | Where-Object Info) + @($CompareMiners | Where-Object { $_.Info -and $_.SideIndicator -eq "<=" } <# miner object is gone #>))) { 
            If ($Miner.Status -eq [MinerStatus]::Failed) { 
                $Miner.Info = ""
                $Miner.WorkersRunning = @()
            }
            ElseIf ($Miner.GetStatus() -ne [MinerStatus]::DryRun -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' exited unexpectedly."
                $Miner.SetStatus([MinerStatus]::Failed)
                $Miner.Info = ""
                $Miner.WorkersRunning = @()
            }
            Else { 
                If ($Miner.GetStatus() -eq [MinerStatus]::Running -and $Config.DryRun) { $Miner.Restart = $true }
                If ($Miner.GetStatus() -eq [MinerStatus]::DryRun -and -not $Config.DryRun) { $Miner.Restart = $true }
                If ($Miner.Benchmark -or $Miner.MeasurePowerUsage) { $Miner.Restart = $true }
                If ($Miner.Best -ne $true -or $Miner.Restart -or $Miner.SideIndicator -eq "<=" -or $Variables.NewMiningStatus -ne "Running") { 
                    ForEach ($Worker in $Miner.WorkersRunning) { 
                        If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -EQ $Miner.Name | Where-Object PoolName -EQ $Worker.Pool.Name | Where-Object PoolRegion -EQ $Worker.Pool.Region | Where-Object Algorithm -EQ $Worker.Pool.Algorithm | Where-Object DeviceNames -EQ $Miner.DeviceNames)) { 
                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })
                        }
                    }
                    Remove-Variable Worker -ErrorAction Ignore
                    $Miner.SetStatus([MinerStatus]::Idle)
                    $Miner.Info = ""
                    $Miner.WorkersRunning = @()
                }
            }
        }
        Remove-Variable Miner -ErrorAction Ignore

        # Remove miners from gone pools
        $Miners = $Miners | Where-Object { $_.Workers[0].Pool.BaseName -in @(Get-PoolBaseName $Variables.PoolName) -and ($_.Workers.Count -eq 1 -or $_.Workers[1].Pool.BaseName -in @(Get-PoolBaseName $Variables.PoolName)) }
        $Miners | ForEach-Object { $_.PSObject.Properties.Remove("SideIndicator") }

        # Kill stuck miners
        $Loops = 0
        While ($StuckMinerProcessIDs = @((Get-CimInstance CIM_Process | Where-Object ExecutablePath | Where-Object { @($Miners.Path | Sort-Object -Unique) -contains $_.ExecutablePath } | Where-Object { $Miners.ProcessID -notcontains $_.ProcessID }).ProcessID)) { 
            $StuckMinerProcessIDs | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction Ignore }
            Start-Sleep -Milliseconds 500
            $Loops ++
            If ($Loops -gt 100) { 
                $Message = "Cannot stop all miners graciously."
                If ($Config.AutoReboot) { 
                    Write-Message -Level Error "$Message Restarting computer in 30 seconds..."
                    shutdown.exe /r /t 30 /c "$($Variables.Branding.ProductLabel) detected stuck miner$(If ($StuckMinerProcessIDs.Count -gt 1) { "s" }) and will reboot the computer in 30 seconds."
                    Start-Sleep -Seconds 60
                }
                Else { 
                    Write-Message -Level Error $Message
                    Start-Sleep -Seconds 30
                }
            }
        }

        $Miners | ForEach-Object { 
            If ($_.Reasons -and $_.Status -ne [MinerStatus]::Disabled) { 
                $_.Status = "Unavailable"
                $_.StatusMessage = $null
            }
            ElseIf ($_.Status -eq "Unavailable")  { 
                $_.Status = "Idle"
                $_.StatusMessage = $null
            }
        }

        If ($Variables.EnabledDevices -and ($Miners | Where-Object Available)) {
            # Update data in API
            $Variables.Miners = $Miners
        }
        Else { 
            $Variables.Miners = [Miner[]]@()
            If (-not $Variables.EnabledDevices) { 
                Write-Message -Level Warn "No enabled devices - retrying in $($Config.Interval) seconds..."
                Start-Sleep -Seconds $Config.Interval
                Write-Message -Level Info "Ending cycle (No enabled devices)."
            }
            ElseIf (-not $Variables.PoolName) { 
                Write-Message -Level Warn "No configured pools - retrying in $($Config.Interval) seconds..."
                Start-Sleep -Seconds $Config.Interval
                Write-Message -Level Info "Ending cycle (No configured pools)."
            }
            ElseIf (-not $Variables.PoolsBest) { 
                Write-Message -Level Warn "No available pools - retrying in $($Config.Interval) seconds..."
                Start-Sleep -Seconds $Config.Interval
                Write-Message -Level Info "Ending cycle (No available pools)."
            }
            Else { 
                Write-Message -Level Warn "No available miners - retrying in $($Config.Interval) seconds..."
                Start-Sleep -Seconds $Config.Interval
                Write-Message -Level Info "Ending cycle (No available miners)."
            }
            Continue
        }

        If (-not $Variables.MinersBest_Combo) { 
            $Variables.RefreshNeeded = $true
            Start-Sleep -Seconds $Config.Interval
            $Variables.Miners | ForEach-Object { $_.Status = [MinerStatus]::Idle; $_.StatusMessage = "" }
            $Variables.EnabledDevices | ForEach-Object { $_.Status = [MinerStatus]::Idle }
            Write-Message -Level Info "Ending cycle."
            Continue
        }

        # Faster shutdown
        If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

        # For debug only
        While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

        # Optional delay to avoid blue screens
        Start-Sleep -Seconds $Config.Delay

        ForEach ($Miner in $Variables.MinersBest_Combo) { 

            If ($Miner.Benchmark -or $Miner.MeasurePowerUsage) { 
                $DataCollectInterval = 1
                $Miner.Earning = [Double]::NaN
                $Miner.Earning_Bias = [Double]::NaN
                $Miner.ValidDataSampleTimestamp = [DateTime]0
                If ($Miner.MeasurePowerUsage) {
                    $Miner.Profit = [Double]::NaN
                    $Miner.Profit_Bias = [Double]::NaN
                    $Miner.PowerUsage = [Double]::NaN
                    $Miner.PowerUsage_Live = [Double]::NaN
                }
                $Miner.Hashrates_Live = @($Miner.Workers | ForEach-Object { [Double]::NaN })
            }
            Else { 
                $DataCollectInterval = 5
            }

            If ($Miner.Status -ne [MinerStatus]::DryRun -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                # Launch prerun if exists
                If ($Miner.Type -eq "AMD" -and (Test-Path -Path ".\Utils\Prerun\AMDPrerun.bat" -PathType Leaf)) { 
                    Start-Process ".\Utils\Prerun\AMDPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                }
                ElseIf ($Miner.Type -eq "NVIDIA" -and (Test-Path -Path ".\Utils\Prerun\NVIDIAPrerun.bat" -PathType Leaf)) { 
                    Start-Process ".\Utils\Prerun\NVIDIAPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                }
                ElseIf ($Miner.Type -eq "CPU" -and (Test-Path -Path ".\Utils\Prerun\CPUPrerun.bat" -PathType Leaf)) { 
                    Start-Process ".\Utils\Prerun\CPUPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                }
                If ($Miner.Type -ne "CPU") { 
                    $MinerAlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Name)$(If ($Miner.Algorithm.Count -eq 1) { "_$($Miner.Algorithm[0])" }).bat"
                    $AlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Algorithm).bat"
                    $DefaultPrerunName = ".\Utils\Prerun\default.bat"
                    If (Test-Path -Path $MinerAlgorithmPrerunName -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: $MinerAlgorithmPrerunName"
                        Start-Process $MinerAlgorithmPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    ElseIf (Test-Path -Path $AlgorithmPrerunName -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: $AlgorithmPrerunName"
                        Start-Process $AlgorithmPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    ElseIf (Test-Path -Path $DefaultPrerunName -PathType Leaf) { 
                        Write-Message -Level Info "Launching Prerun: $DefaultPrerunName"
                        Start-Process $DefaultPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                }
                # Add extra time when CPU mining and miner requires DAG creation
                If ($Miner.Workers.Pool.DAGSizeGiB -and $Variables.MinersBest_Combo.Devices.Type -contains "CPU") { $Miner.WarmupTimes[0] += 15 <# seconds #>}

                $Miner.DataCollectInterval = $DataCollectInterval
                $Miner.Activated ++
                $Miner.Cycle = 0
                $Miner.PowerUsage = [Double]::NaN
                $Miner.Hashrates_Live = @($Miner.Workers | ForEach-Object { [Double]::NaN })
                $Miner.PowerUsage_Live = [Double]::NaN

                If ($Miner.Benchmark -or $Miner.MeasurePowerUsage) { 
                    $Miner.Data = @() # When benchmarking clear data on each miner start
                    $Miner.SetStatus([MinerStatus]::Running)
                }
                ElseIf ($Config.DryRun) {
                    $Miner.SetStatus([MinerStatus]::DryRun)
                }
                Else { 
                    $Miner.SetStatus([MinerStatus]::Running)
                }

                # Add watchdog timer
                If ($Config.Watchdog) { 
                    ForEach ($Worker in $Miner.Workers) { 
                        $Variables.WatchdogTimers += [PSCustomObject]@{ 
                            Algorithm     = $Worker.Pool.Algorithm
                            DeviceNames   = $Miner.DeviceNames
                            Kicked        = (Get-Date).ToUniversalTime()
                            MinerBaseName = $Miner.BaseName
                            MinerName     = $Miner.Name
                            MinerVersion  = $Miner.Version
                            PoolName      = $Worker.Pool.Name
                            PoolBaseName  = $Worker.Pool.BaseName
                            PoolRegion    = $Worker.Pool.Region
                        }
                    }
                    Remove-Variable Worker -ErrorAction Ignore
                }
            }
            ElseIf ($Miner.DataCollectInterval -ne $DataCollectInterval -or $Config.CalculatePowerCost -ne $Variables.CalculatePowerCost) {
                $Miner.DataCollectInterval = $DataCollectInterval
                $Miner.RestartDataReader()
            }

            If ($Miner.Activated -le 0) { $Miner.Activated = 1 } # Stat just got removed (Miner.Activated < 1, set by API)

            $Message = ""
            If ($Miner.Benchmark) { $Message = "Benchmark " }
            If ($Miner.Benchmark -and $Miner.MeasurePowerUsage) { $Message = "$($Message)and " }
            If ($Miner.MeasurePowerUsage) { $Message = "$($Message)Power usage measurement " }
            If ($Message) { Write-Message -Level Verbose "$($Message)for miner '$($Miner.Name) $($Miner.Info)' in progress [Attempt $($Miner.Activated) of $($Variables.WatchdogCount + 1); min. $($Miner.MinDataSample) Samples]..." }
        }
        Remove-Variable Miner

        $Variables.Miners | Where-Object Available | Group-Object { $_.DeviceNames -join ',' } | ForEach-Object { 
            $MinersDeviceGroup = $_.Group
            $MinersDeviceGroupNeedingBenchmark = $MinersDeviceGroup | Where-Object Benchmark
            $MinersDeviceGroupNeedingPowerUsageMeasurement = $MinersDeviceGroup | Where-Object MeasurePowerUsage

            # Display benchmarking progress
            If ($MinersDeviceGroupNeedingBenchmark) { 
                Write-Message -Level Verbose "Benchmarking for '$(($MinersDeviceGroupNeedingBenchmark.DeviceNames | Sort-Object -Unique) -join ', ')' in progress: $($MinersDeviceGroupNeedingBenchmark.Count) miner$(If ($MinersDeviceGroupNeedingBenchmark.Count -gt 1) { 's' }) left to complete benchmark."
            }
            # Display power usage measurement progress
            If ($MinersDeviceGroupNeedingPowerUsageMeasurement) { 
                Write-Message -Level Verbose "Power usage measurement for '$(($MinersDeviceGroupNeedingPowerUsageMeasurement.DeviceNames | Sort-Object -Unique) -join ', ')' in progress: $($MinersDeviceGroupNeedingPowerUsageMeasurement.Count) miner$(If ($MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 1) { 's' }) left to complete measuring."
            }
        }

        Get-Job -State "Completed" -ErrorAction Ignore | Receive-Job -ErrorAction Ignore | Out-Null
        Get-Job -State "Completed" -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore
        Get-Job -State "Stopped" -ErrorAction Ignore | Receive-Job -ErrorAction Ignore | Out-Null
        Get-Job -State "Stopped" -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore

        If ($Variables.CycleStarts.Count -eq 1) { 
            # Ensure a full cycle on first loop
            $Variables.EndCycleTime = (Get-Date).ToUniversalTime().AddSeconds($Config.Interval)
        }

        $Variables.RunningMiners = @($Variables.MinersBest_Combo | Sort-Object -Descending Benchmark, MeasurePowerUsage)
        $Variables.FailedMiners = @()

        $Variables.EndCycleMessage = ""

        $Variables.RefreshTimestamp = (Get-Date).ToUniversalTime()
        $Variables.StatusText = "Waiting $($Variables.TimeToSleep) seconds... | Next refresh: $((Get-Date).AddSeconds($Variables.TimeToSleep).ToString('g'))"
        $Variables.RefreshNeeded = $true

        Write-Message -Level Info "Collecting miner data while waiting for next cycle..."

        Start-Sleep -Milliseconds 250

        Do { 
            $Variables.RunningMiners | Select-Object | ForEach-Object { 
                $Miner = $_
                If ($Miner.Status -ne [MinerStatus]::DryRun) { 
                    If ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
                        # Miner crashed
                        $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' exited unexpectedly."
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.FailedMiners += $Miner
                    }
                    ElseIf ($Miner.DataReaderJob.State -ne [MinerStatus]::Running) { 
                        # Miner data reader process failed
                        $Miner.StatusMessage = "Miner data reader '$($Miner.Name) $($Miner.Info)' exited unexpectedly."
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.FailedMiners += $Miner
                    }
                    Else { 
                        If ($Process = Get-Process | Where-Object Id -EQ $Miner.ProcessId) { 
                            # Set miner priority, some miners reset priority on their own
                            $Process.PriorityClass = $Global:PriorityNames.($Miner.ProcessPriority)
                            # Set window title
                            $WindowTitle = "$($Miner.Devices.Name -join ","): $($Miner.Name) $($Miner.Info)"
                            If ($Miner.Benchmark -and -not $Miner.MeasurePowerUsage) { $WindowTitle += " (Benchmarking)" }
                            ElseIf ($Miner.Benchmark -and $Miner.MeasurePowerUsage) { $WindowTitle += " (Benchmarking and measuring power usage)" }
                            ElseIf (-not $Miner.Benchmark -and $Miner.MeasurePowerUsage) { $WindowTitle += " (Measuring power usage)" }
                            [Win32]::SetWindowText($Process.MainWindowHandle, $WindowTitle) | Out-Null
                        }
                        If ($Samples = @($Miner.DataReaderJob | Receive-Job | Select-Object)) { 
                            $Sample = $Samples | Select-Object -Last 1
                            $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                            If ($Miner.ValidDataSampleTimestamp -eq [DateTime]0) { $Miner.ValidDataSampleTimestamp = $Sample.Date.AddSeconds($Miner.WarmupTimes[1])}
                            If ([Int]($Sample.Date - $Miner.ValidDataSampleTimestamp).TotalSeconds -ge 0) { 
                                $Miner.Data += $Samples
                                $Miner.StatusMessage = "$(If ($Miner.Benchmark -or $Miner.MeasurePowerUsage) { "$($(If ($Miner.Benchmark) { "Benchmarking" }), $(If ($Miner.Benchmark -and $Miner.MeasurePowerUsage) { " and " }), $(If ($Miner.MeasurePowerUsage) { "Measuring power usage" }) -join '')" } Else { "Mining " }) {$(($Miner.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"
                                $Miner.Devices | ForEach-Object { $_.Status = $Miner.StatusMessage }
                                Write-Message -Level Verbose "$($Miner.Name) data sample retrieved [$(($Sample.Hashrate.PSObject.Properties.Name | ForEach-Object { "$($_): $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.BadShareRatioThreshold) { " / Shares Total: $($Sample.Shares.$_[3]), Rejected: $($Sample.Shares.$_[1]), Ignored: $($Sample.Shares.$_[2])" })" }) -join ' & ')$(If ($Sample.PowerUsage) { " / Power usage: $($Sample.PowerUsage.ToString("N2"))W" })] ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))."
                            }
                            Else { 
                                Write-Message -Level Verbose "$($Miner.Name) data sample discarded [$(($Sample.Hashrate.PSObject.Properties.Name | ForEach-Object { "$($_): $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.BadShareRatioThreshold) { " / Shares Total: $($Sample.Shares.$_[3]), Rejected: $($Sample.Shares.$_[1]), Ignored: $($Sample.Shares.$_[2])" })" }) -join ' & ')$(If ($Sample.PowerUsage) { " / Power usage: $($Sample.PowerUsage.ToString("N2"))W" })] (Miner is warming up [$(((Get-Date).ToUniversalTime() - $Miner.ValidDataSampleTimestamp).TotalSeconds.ToString("0")) sec])."
                            }
                        }
                        ElseIf ((Get-Date).ToUniversalTime() -gt $Miner.BeginTime.AddSeconds($Miner.WarmupTimes[0])) { 
                            # We must have some hash speed by now (cannot rely on data samples, these might have been discarded while benchmarking)
                            If ($Miner.Hashrates_Live | Where-Object { [Double]::IsNaN($_) }) { 
                                # Stop miner, it has not provided hash rate on time
                                $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' has not provided first data sample in $($Miner.WarmupTimes[0]) seconds."
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.FailedMiners += $Miner
                                Break
                            }
                            ElseIf ($Miner.Data.Count -ge 2 -and ($Miner.Data | Select-Object -Last 1).Date.AddSeconds((($Miner.DataCollectInterval * 3.5), 10 | Measure-Object -Maximum).Maximum) -lt (Get-Date).ToUniversalTime()) { 
                                # Miner stuck - no sample received in last few data collect intervals
                                $Miner.GetMinerData()
                                $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' has not updated data for more than $((($Miner.DataCollectInterval * 3.5), 10 | Measure-Object -Maximum).Maximum) seconds."
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.FailedMiners += $Miner
                                Break
                            }
                        }
                    }
                }
            }
            Remove-Variable Miner -ErrorAction Ignore

            $Variables.RunningMiners = @($Variables.RunningMiners | Where-Object { $_-notin $Variables.FailedMiners })
            $Variables.BenchmarkingOrMeasuringMiners = @($Variables.RunningMiners | Where-Object { $_.Activated -gt 0 -and ($_.Benchmark -or $_.MeasurePowerUsage) })

            If ($Variables.FailedMiners -and -not $Variables.BenchmarkingOrMeasuringMiners) { 
                # A miner crashed and we're not benchmarking, exit loop immediately
                $Variables.EndCycleMessage = " prematurely (Miner failed)"
            }
            ElseIf ($Variables.BenchmarkingOrMeasuringMiners -and (($Variables.BenchmarkingOrMeasuringMiners | ForEach-Object { $_.Data.Count }) | Measure-Object -Minimum).Minimum -ge ($Variables.BenchmarkingOrMeasuringMiners.MinDataSample | Measure-Object -Maximum).Maximum) { 
                # Enough samples collected for this loop, exit loop immediately
                $Variables.EndCycleMessage = " (All$(If ($Variables.BenchmarkingOrMeasuringMiners | Where-Object Benchmark) { " benchmarking" })$(If ($Variables.BenchmarkingOrMeasuringMiners | Where-Object { $_.Benchmark -and $_.MeasurePowerUsage }) { " and" })$(If ($Variables.BenchmarkingOrMeasuringMiners | Where-Object MeasurePowerUsage) { " power usage measuring" }) miners have collected enough samples for this cycle)"
            }

            # For debug only
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Exit loop when
            # - a miner crashed (and no other miners are benchmarking or measuring power usage)
            # - all benchmarking miners have collected enough samples
            # - WarmupTimes[0] is reached (no readout from miner)
            # - Interval time is over
        } While (-not $Variables.EndCycleMessage -and $Variables.NewMiningStatus -eq "Running" -and $Variables.IdleRunspace.MiningStatus -ne "Idle" -and ((Get-Date).ToUniversalTime() -le $Variables.EndCycleTime -or $Variables.BenchmarkingOrMeasuringMiners))

        If ($Variables.IdleRunspace.MiningStatus -eq "Idle") { $Variables.EndCycleMessage = " (System activity detected)" }

        $Error.Clear()
        [System.GC]::Collect() | Out-Null
        [System.GC]::WaitForPendingFinalizers() | Out-Null
        [System.GC]::GetTotalMemory("forcefullcollection") | Out-Null

        Write-Message -Level Info "Ending cycle$($Variables.EndCycleMessage)."
    }
    Catch { 
        Write-Message -Level Error "Error in file $(($_.InvocationInfo.ScriptName -Split "\\" | Select-Object -Last 2) -join "\") line $($_.InvocationInfo.ScriptLineNumber) detected. Respawning core..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Error.txt"
        $_.Exception | Format-List -Force >> "Logs\Error.txt"
        $_.InvocationInfo | Format-List -Force >> "Logs\Error.txt"
        $Variables.EndCycleTime = $Variables.StartCycleTime.AddSeconds($Config.Interval) # Reset timers
    }
    $Variables.RestartCycle = $true
} While ($Variables.NewMiningStatus -eq "Running")

If ($Variables.NewMiningStatus -ne "Running")  { 
    #Stop all running miners
    $Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running -or $_.Status -eq [MinerStatus]::DryRun } | ForEach-Object { 
        $_.SetStatus([MinerStatus]::Idle)
        $_.Info = ""
        $_.WorkersRunning = @()
    }
}

$Variables.RestartCycle = $true