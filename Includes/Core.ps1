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
Version:        5.0.2.0
Version date:   2023/11/12
#>

using module .\Include.psm1
using module .\APIServer.psm1

If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

Do { 
    Try { 
        # Set master timer
        $Variables.Timer = ([DateTime]::Now).ToUniversalTime()

        Get-ChildItem -Path ".\Includes\MinerAPIs" -File | ForEach-Object { . $_.FullName }

        # Internet connection check when no new pools
        If (-not $Variables.PoolsNew) { 
            Try { 
                $IfIndex = (Get-NetRoute | Where-Object DestinationPrefix -eq "0.0.0.0/0" | Get-NetIPInterface | Where-Object ConnectionState -eq "Connected").ifIndex
                $Variables.MyIP = (Get-NetIPAddress -InterfaceIndex $IfIndex -AddressFamily IPV4).IPAddress
                Remove-Variable IfIndex
            }
            Catch { 
                $Variables.MyIP = $null
                Write-Message -Level Error "No internet connection - will retry in 60 seconds..."
                #Stop all miners
                ForEach ($Miner in ($Variables.Miners | Where-Object { $_.Status -ne [MinerStatus]::Idle })) { 
                    $Miner.SetStatus([MinerStatus]::Idle)
                    $Miner.WorkersRunning = [Worker[]]@()
                    $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }
                }
                $Variables.RunningMiners = [Miner[]]@()
                $Variables.BenchmarkingOrMeasuringMiners = [Miner[]]@()
                $Variables.FailedMiners = [Miner[]]@()
                Remove-Variable Miner -ErrorAction Ignore
                $Variables.MinersBest_Combo = $Variables.MinersBest_Combos = [Miner[]]@()
                Start-Sleep -Seconds 60
                Continue
            }
        }

        # Read config only if config files have changed
        If ($Variables.ConfigFileTimestamp -ne (Get-Item -Path $Variables.ConfigFile).LastWriteTime -or $Variables.PoolsConfigFileTimestamp -ne (Get-Item -Path $Variables.PoolsConfigFile).LastWriteTime) { 
            Write-Message -Level Verbose "Activating changed configuration..."
            [Void](Read-Config -ConfigFile $Variables.ConfigFile)
        }
        $Variables.PoolsConfig = $Config.PoolsConfig.Clone()

        If ($Config.BalancesTrackerPollInterval -gt 0) { Start-BalancesTracker } Else { Stop-BalancesTracker }
        If ($Config.WebGUI) { Start-APIServer } Else { Stop-APIServer }

        If ($Config.IdleDetection) { 
            If (-not $Variables.IdleRunspace) { 
                Start-IdleDetection
            }
            If ($Variables.IdleRunspace.MiningStatus -eq "Idle") { 
                # Stop all miners
                ForEach ($Miner in ($Variables.Miners | Where-Object { $_.Status -ne [MinerStatus]::Idle })) { 
                    $Miner.SetStatus([MinerStatus]::Idle)
                    $Miner.StatusInfo = "Waiting for system to become idle '$($Miner.Info)'"
                    $Miner.WorkersRunning = [Worker[]]@()
                    $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }
                }
                $Variables.RunningMiners = [Miner[]]@()
                $Variables.BenchmarkingOrMeasuringMiners = [Miner[]]@()
                $Variables.FailedMiners = [Miner[]]@()
                Remove-Variable Miner -ErrorAction Ignore
                $Variables.Summary = "Mining is suspended until system is idle<br>again for $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" })..."
                Write-Message -Level Verbose ($Variables.Summary -replace '<br>', ' ')
                $Variables.IdleRunspace | Add-Member MiningStatus "Idle" -Force

                While ($Variables.NewMiningStatus -eq "Running" -and $Config.IdleDetection -and $Variables.IdleRunspace.MiningStatus -eq "Idle") { Start-Sleep -Seconds 1 }

                If ($Config.IdleDetection) { Write-Message -Level Info "Started new cycle (System was idle for $($Config.IdleSec) seconds)." }
            }
        }
        Else { 
            If ($Variables.IdleRunspace) { Stop-IdleDetection }
            Write-Message -Level Info "Started new cycle."
        }

        # Use values from config
        $Variables.PoolName = $Config.PoolName
        $Variables.NiceHashWalletIsInternal = $Config.NiceHashWalletIsInternal
        $Variables.PoolTimeout = [Math]::Floor($Config.PoolTimeout)

        # Update enabled devices
        $Variables.EnabledDevices = [Device[]]@($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -notin $Config.ExcludeDeviceName | ForEach-Object { Copy-Object $_ })

        If ($Variables.EnabledDevices) { 
            $Variables.EnabledDevices | ForEach-Object { 
                # Miner name must not contain spaces
                $_.Model = $_.Model -replace ' '
                If ($_.Type -eq "GPU") { 
                    # For GPUs set type equal to vendor
                    $_.Type = $_.Vendor
                    # Remove model information from devices -> will create only one miner instance
                    If (-not $Config.MinerInstancePerDeviceModel) { $_.Model = $_.Vendor }
                }
            }

            # Skip some stuff when previous cycle was shorter than half of what it should
            If ($Variables.BenchmarkingOrMeasuringMiners -or -not $Variables.Miners -or (Compare-Object @($Config.PoolName | Select-Object) @($Variables.PoolName | Select-Object)) -or -not $Variables.BeginCycleTime -or $Variables.BeginCycleTime.AddSeconds([Math]::Floor($Config.Interval / 2)) -lt ([DateTime]::Now).ToUniversalTime() -or (Compare-Object @($Config.ExtraCurrencies | Select-Object) @($Variables.AllCurrencies | Select-Object) | Where-Object SideIndicator -eq "<=")) { 
                $Variables.BeginCycleTime = $Variables.Timer
                $Variables.EndCycleTime = $Variables.Timer.AddSeconds($Config.Interval)

                $Variables.CycleStarts += $Variables.Timer
                $Variables.CycleStarts = @($Variables.CycleStarts | Sort-Object -Bottom (3, ($Config.SyncWindow + 1) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum))

                # Set minimum Watchdog count 3
                $Variables.WatchdogCount = (3, $Config.WatchdogCount | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
                $Variables.WatchdogReset = $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Config.Interval

                # Expire watchdog timers
                If ($Config.Watchdog) { $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object Kicked -GE $Variables.Timer.AddSeconds( - $Variables.WatchdogReset)) }
                Else { $Variables.WatchdogTimers = @() }

                # Check for new version
                If ($Config.AutoUpdateCheckInterval -and $Variables.CheckedForUpdate -lt ([DateTime]::Now).AddDays(-$Config.AutoUpdateCheckInterval)) { Get-NMVersion }

                If ($Config.Donation -gt 0) { 
                    If (-not $Variables.DonationStart) { 
                        # Re-Randomize donation start once per day, do not donate if remaing time for today is less than donation duration
                        If (($Variables.DonationLog.Start | Sort-Object -Bottom 1).Date -ne [DateTime]::Today) { 
                            If ($Config.Donation -lt (1440 - [Math]::Floor(([DateTime]::Now).TimeOfDay.TotalMinutes))) { 
                                $Variables.DonationStart = ([DateTime]::Now).AddMinutes((Get-Random -Minimum 0 -Maximum (1440 - [Math]::Floor(([DateTime]::Now).TimeOfDay.TotalMinutes) - $Config.Donation)))
                            }
                        }
                    }
                    If ($Variables.DonationStart -and ([DateTime]::Now) -ge $Variables.DonationStart) { 
                        If (-not $Variables.DonationEnd) { 
                            $Variables.DonationStart = Get-Date
                            # Ensure full donation period
                            $Variables.DonationEnd = $Variables.DonationStart.AddMinutes($Config.Donation)
                            $Variables.EndCycleTime = ($Variables.DonationEnd).ToUniversalTime()
                            # Add pool config to config (in-memory only)
                            $Variables.DonationRandomPoolsConfig = Get-RandomDonationPoolsConfig
                            # Activate donation
                            $Variables.PoolName = $Variables.DonationRandomPoolsConfig.psBase.Keys
                            $Variables.PoolsConfig = $Variables.DonationRandomPoolsConfig
                            $Variables.NiceHashWalletIsInternal = $false
                            Write-Message -Level Info "Donation run: Mining for '$($Variables.DonationRandom.Name)' for the next $(If (($Config.Donation - (([DateTime]::Now) - $Variables.DonationStart).Minutes) -gt 1) { "$($Config.Donation - (([DateTime]::Now) - $Variables.DonationStart).Minutes) minutes" } Else { "minute" }). While donating $($Variables.Branding.ProductLabel) will use pools '$($Variables.PoolName -join ', ')'."
                            $Variables.DonationRunning = $true
                        }
                    }
                }

                If ($Variables.DonationRunning -and ([DateTime]::Now) -gt $Variables.DonationEnd) { 
                    $Variables.DonationLog = $Variables.DonationLog | Select-Object -Last 365 # Keep data for one year
                    [Array]$Variables.DonationLog += [PSCustomObject]@{ 
                        Start = $Variables.DonationStart
                        End   = $Variables.DonationEnd
                        Name  = $Variables.DonationRandom.Name
                    }
                    $Variables.DonationLog | ConvertTo-Json | Out-File -FilePath ".\Logs\DonateLog.json" -Force -ErrorAction Ignore
                    $Variables.DonationRandomPoolsConfig = $null
                    $Variables.DonationStart = $null
                    $Variables.DonationEnd = $null
                    $Variables.PoolsConfig = $Config.PoolsConfig.Clone()
                    Write-Message -Level Info "Donation run complete - thank you! Mining for you again. :-)"
                    $Variables.DonationRunning = $false
                }

                # Stop / Start brain background jobs
                [Void](Stop-Brain @($Variables.Brains.psBase.Keys | Where-Object { $_ -notin @(Get-PoolBaseName $Variables.PoolName) }))
                [Void](Start-Brain @(Get-PoolBaseName $Variables.PoolName))

                # Wait for pool data messaage
                If ($Variables.PoolName) { 
                    If ($Variables.Brains.psBase.Keys | Where-Object { $Variables.Brains[$_].StartTime -gt $Variables.Timer.AddSeconds(- $Config.Interval) }) {
                        # Newly started brains, allow extra time for brains to get ready
                        $Variables.PoolTimeout = 60
                        Write-Message -Level Info "Requesting initial pool data from '$((Get-PoolBaseName $Variables.PoolName) -join ', ')'...<br>This may take up to $($Variables.PoolTimeout) seconds."
                    }
                    Else { 
                        Write-Message -Level Info "Requesting pool data from '$((Get-PoolBaseName $Variables.PoolName) -join ', ')'..."
                    }
                }

                # Core suspended with <Ctrl><Alt>P in MainLoop
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                # Remove stats that have been deleted from disk
                If ($StatFiles = [String[]](Get-ChildItem -Path "Stats" -File).Name) { 
                    If ($Keys = [String[]]($Global:Stats.psBase.Keys)) { 
                        Compare-Object $StatFiles $Keys -PassThru | Where-Object SideIndicator -EQ "=>" | ForEach-Object { 
                            # Remove stat if deleted on disk
                            $Global:Stats.Remove($_)
                        }
                    }
                }
                Remove-Variable Keys, StatFiles -ErrorAction Ignore

                # Load currency exchange rates
                [Void](Get-Rate)

                # Get DAG data
                [Void](Update-DAGdata)

                # Faster shutdown
                If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

                # Core suspended with <Ctrl><Alt>P in MainLoop
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                # Power cost preparations
                $Variables.CalculatePowerCost = $Config.CalculatePowerCost
                If ($Config.CalculatePowerCost) { 
                    If ($Variables.EnabledDevices.Count -ge 1) { 
                        # HWiNFO64 verification
                        $RegKey = "HKCU:\Software\HWiNFO64\VSB"
                        If ($RegValue = Get-ItemProperty -Path $RegKey -ErrorAction Ignore) { 
                            If ([String]$Variables.HWInfo64RegValue -eq [String]$RegValue) { 
                                Write-Message -Level Warn "Power usage data in registry has not been updated [HWiNFO64 not running???] - disabling power usage and profit calculations."
                                $Variables.CalculatePowerCost = $false
                            }
                            Else { 
                                $PowerUsageData = @{ }
                                $DeviceName = ""
                                $RegValue.PSObject.Properties | Where-Object { $_.Name -match '^Label[0-9]+$' -and (Compare-Object @($_.Value -split ' ' | Select-Object) @($Variables.EnabledDevices.Name) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                                    $DeviceName = ($_.Value -split ' ') | Select-Object -Last 1
                                    Try { 
                                        $PowerUsageData[$DeviceName] = $RegValue.($_.Name -replace 'Label', 'Value')
                                    }
                                    Catch { 
                                        Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [duplicate sensor for $DeviceName] - disabling power usage and profit calculations."
                                        $Variables.CalculatePowerCost = $false
                                    }
                                }
                                # Add configured power usage
                                $Variables.Devices.Name | ForEach-Object { 
                                    If ($ConfiguredPowerUsage = $Config.PowerUsage.$_ -as [Double]) { 
                                        If ($_ -in @($Variables.EnabledDevices.Name) -and -not $PowerUsageData.$_) { Write-Message -Level Warn "HWiNFO64 cannot read power usage data for device ($_). Using configured value of $ConfiguredPowerUsage) W." }
                                        $PowerUsageData[$_] = "$ConfiguredPowerUsage W"
                                    }
                                    $Variables.EnabledDevices | Where-Object Name -EQ $_ | ForEach-Object { $_.ConfiguredPowerUsage = $ConfiguredPowerUsage }
                                    $Variables.Devices | Where-Object Name -EQ $_ | ForEach-Object { $_.ConfiguredPowerUsage = $ConfiguredPowerUsage }
                                }

                                If ($DeviceNamesMissingSensor = Compare-Object @($Variables.EnabledDevices.Name) @($PowerUsageData.psBase.Keys) -PassThru | Where-Object SideIndicator -EQ "<=") { 
                                    Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [missing sensor configuration for $($DeviceNamesMissingSensor -join ', ')] - disabling power usage and profit calculations."
                                    $Variables.CalculatePowerCost = $false
                                }
                                Remove-Variable DeviceNamesMissingSensor

                                # Enable read power usage for configured devices
                                $Variables.EnabledDevices | ForEach-Object { $_.ReadPowerUsage = $_.Name -in @($PowerUsageData.psBase.Keys) }
                                Remove-Variable ConfiguredPowerUsage, DeviceName, PowerUsageData -ErrorAction Ignore
                            }
                        }
                        Else { 
                            Write-Message -Level Warn "Cannot read power usage data from registry [Key '$RegKey' does not exist - HWiNFO64 not running???] - disabling power usage and profit calculations."
                            $Variables.CalculatePowerCost = $false
                        }
                        Remove-Variable RegKey, RegValue -ErrorAction Ignore
                    }
                    Else { $Variables.CalculatePowerCost = $false }
                }
                If (-not $Variables.CalculatePowerCost) { 
                    $Variables.EnabledDevices | ForEach-Object { $_.ReadPowerUsage = $false }
                }

                # Power price
                If (-not $Config.PowerPricekWh.psBase.Keys) { $Config.PowerPricekWh."00:00" = 0 }
                ElseIf ($null -eq $Config.PowerPricekWh."00:00") { 
                    # 00:00h power price is the same as the latest price of the previous day
                    $Config.PowerPricekWh."00:00" = $Config.PowerPricekWh.($Config.PowerPricekWh.psBase.Keys | Sort-Object -Bottom 1)
                }
                $Variables.PowerPricekWh = [Double]($Config.PowerPricekWh.($Config.PowerPricekWh.psBase.Keys | Where-Object { $_ -le (Get-Date -Format HH:mm).ToString() } | Sort-Object -Bottom 1))
                $Variables.PowerCostBTCperW = [Double](1 / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.MainCurrency))

                # Load unprofitable algorithms
                Try { 
                    If (-not $Variables.UnprofitableAlgorithms -or (Get-ChildItem -Path ".\Data\UnprofitableAlgorithms.json").LastWriteTime -gt $Variables.Timer.AddSeconds( - $Config.Interval)) { 
                        $Variables.UnprofitableAlgorithms = Get-Content -Path ".\Data\UnprofitableAlgorithms.json" | ConvertFrom-Json -ErrorAction Stop -AsHashtable | Get-SortedObject
                        Write-Message -Level Info "Loaded list of unprofitable algorithms ($($Variables.UnprofitableAlgorithms.Count) $(If ($Variables.UnprofitableAlgorithms.Count -ne 1) { "entries" } Else { "entry" }))."
                    }
                }
                Catch { 
                    Write-Message -Level Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file. Please restore it from your original download."
                    $Variables.UnprofitableAlgorithms = @{ }
                }

                # Faster shutdown
                If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

                # Core suspended with <Ctrl><Alt>P in MainLoop
                While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

                $PoolTimeStamp = If ($Variables.MinerDataCollectedTimeStamp) { $Variables.MinerDataCollectedTimeStamp } Else { $Variables.ScriptStartTime }

                # Wait for all brains
                While (($Variables.Brains.psBase.Keys | Where-Object { $Variables.Brains[$_] -and $Variables.Brains[$_].Updated -lt $PoolTimeStamp }) -and ([DateTime]::Now).ToUniversalTime() -lt $Variables.Timer.AddSeconds($Variables.PoolTimeout)) { 
                    Start-Sleep -Seconds 1
                }

                # Collect pool data
                $Variables.PoolsCount = $Variables.Pools.Count
                $PoolsNew = [Pool[]]@()
                If ($Variables.PoolName) { 
                    $Variables.PoolName | ForEach-Object { 
                        $PoolName = Get-PoolBaseName $_
                        If (Test-Path -Path ".\Pools\$($PoolName).ps1") { 
                            Try { 
                                & ".\Pools\$($PoolName).ps1" -Config $Config -PoolVariant $_ -Variables $Variables
                            }
                            Catch { 
                                Write-Message -Level Error "Error in pool file '$($PoolName).ps1'."
                                "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Error.txt"
                                $_.Exception | Format-List -Force >> "Logs\Error.txt"
                                $_.InvocationInfo | Format-List -Force >> "Logs\Error.txt"
                            }
                        }
                    } | Where-Object { 
                        $_.Updated -gt $PoolTimeStamp 
                    } | ForEach-Object { 
                        Try { 
                            $Pool = [Pool]$_
                            $Pool.Fee = If ($Config.IgnorePoolFee -or $Pool.Fee -lt 0 -or $Pool.Fee -gt 1) { 0 } Else { $Pool.Fee }
                            $Factor = $_.EarningsAdjustmentFactor * (1 - $Pool.Fee)
                            $Pool.Price *= $Factor
                            $Pool.Price_Bias = $Pool.Price * $Pool.Accuracy
                            $Pool.StablePrice *= $Factor
                            $Pool.CoinName = $Variables.CoinNames[$Pool.Currency]
                            $PoolsNew += $Pool
                        }
                        Catch { 
                            Write-Message -Level Error "Failed to add pool '$($Pool.Variant) [$($Pool.Algorithm)]' ($($Pool | ConvertTo-Json -Compress))"
                        }
                    } | Out-Null

                    $Variables.PoolsNew = $PoolsNew

                    If ($Variables.PoolNoData = @(Compare-Object @($Variables.PoolName) @($PoolsNew.Variant | Sort-Object -Unique) -PassThru)) { 
                        Write-Message -Level Warn "No data received from pool$(If ($Variables.PoolNoData.Count -ne 1) { "s" }) '$($Variables.PoolNoData -join ', ')'."
                    }

                    # Faster shutdown
                    If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

                    # Remove de-configured pools
                    $PoolsDeconfigured = @($Variables.Pools | Where-Object Variant -notin $Variables.PoolName)
                    $Pools = @($Variables.Pools | Where-Object Variant -in $Variables.PoolName)

                    If ($ComparePools = @(Compare-Object @($PoolsNew | Select-Object) @($Pools | Select-Object) -Property Algorithm, Currency, Variant -IncludeEqual -PassThru)) { 
                        # Find added & updated pools
                        $Variables.PoolsAdded = @($ComparePools | Where-Object SideIndicator -EQ "<=")
                        $Variables.PoolsUpdated = @($ComparePools | Where-Object SideIndicator -EQ "==")
                        # Clear reasons for gone pools
                        $ComparePools | Where-Object SideIndicator -EQ "=>" | ForEach-Object { $_.Reasons = [System.Collections.Generic.List[String]]@() }
                        $Pools += $Variables.PoolsAdded
                        Remove-Variable ComparePools

                        # Update all pools, ake smaller groups for faster update
                        $PoolsGroups = $Variables.PoolsUpdated | Group-Object -Property Name 
                        $Pools | Group-Object -Property Name | ForEach-Object { 
                            $PoolsGroup = ($PoolsGroups | Where-Object Name -eq $_.Name).Group
                            $_.Group | ForEach-Object { 
                                $_.Available = $true
                                $_.Best = $false
                                $_.Prioritize = $false

                                # Update existing pools
                                If ($Pool = $PoolsGroup | Where-Object Algorithm -EQ $_.Algorithm | Where-Object Currency -EQ $_.Currency) { 
                                    $_.Accuracy                 = $Pool.Accuracy
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
                                If (-not $Variables.PoolData.($_.Name).ProfitSwitching -and $Variables.DAGdata.Currency.($_.Currency).BlockHeight) { 
                                    $_.BlockHeight = $Variables.DAGdata.Currency.($_.Currency).BlockHeight
                                    $_.Epoch       = $Variables.DAGdata.Currency.($_.Currency).Epoch
                                    $_.DAGSizeGiB  = $Variables.DAGdata.Currency.($_.Currency).DAGsize / 1GB 
                                }
                                ElseIf ($Variables.DAGdata.Algorithm.($_.Algorithm).BlockHeight) { 
                                    $_.BlockHeight = $Variables.DAGdata.Algorithm.($_.Algorithm).BlockHeight
                                    $_.Epoch       = $Variables.DAGdata.Algorithm.($_.Algorithm).Epoch
                                    $_.DAGSizeGiB  = $Variables.DAGdata.Algorithm.($_.Algorithm).DAGsize / 1GB
                                }

                                # PoolPorts[0] = non-SSL, PoolPorts[1] = SSL
                                $_.PoolPorts = @($(If ($Config.SSL -ne "Always" -and $_.Port) { [UInt16]$_.Port } Else { $null }), $(If ($Config.SSL -ne "Never" -and $_.PortSSL) { [UInt16]$_.PortSSL } Else { $null }))
                            }
                        }
                        Remove-Variable Pool, PoolsGroup, PoolsGroups -ErrorAction Ignore

                        If ($Variables.CycleStarts.Count -ge $Config.SyncWindow) { 
                            # Remove Pools that have not been updated for 1 day
                            $Pools = @($Pools | Where-Object { $_.Updated -ge ([DateTime]::Now).ToUniversalTime().AddDays(-1) })

                            $MaxPoolAgeMinutes = $Config.SyncWindow * $Config.SyncWindow * $Config.SyncWindow * ($Variables.CycleStarts[-1] - $Variables.CycleStarts[0]).TotalMinutes
                            $Pools | Where-Object { $_.Updated -lt $Variables.CycleStarts[0] } | ForEach-Object { 
                                # Pool data is older than earliest CycleStart
                                If ([Math]::Floor(($Variables.CycleStarts[-1] - $_.Updated).TotalMinutes) -gt $MaxPoolAgeMinutes) { $_.Reasons.Add("Data too old") }
                                Else { $_.Price_Bias *= [Math]::Pow(0.9, ($Variables.CycleStarts[0] - $_.Updated).TotalMinutes) }
                            }
                            Remove-Variable MaxPoolAgeMinutes
                        }

                        # No username or wallet
                        $Pools | Where-Object { -not $_.User } | ForEach-Object { $_.Reasons.Add("No username or wallet") }
                        # Pool disabled by stat file
                        $Pools | Where-Object Disabled | ForEach-Object { $_.Reasons.Add("Disabled (by Stat file)") }
                        # Min accuracy not reached
                        $Pools | Where-Object Accuracy -LT $Config.MinAccuracy | ForEach-Object { $_.Reasons.Add("MinAccuracy ($($Config.MinAccuracy * 100)%) not reached") }
                        # Filter unavailable algorithms
                        If ($Config.MinerSet -lt 3) { $Pools | Where-Object { $Variables.UnprofitableAlgorithms[$_.Algorithm] -eq "*" } | ForEach-Object { $_.Reasons.Add("Unprofitable Algorithm") } }
                        # Pool price 0
                        $Pools | Where-Object Price -EQ 0 | ForEach-Object { $_.Reasons.Add("Price -eq 0") }
                        # No price data
                        $Pools | Where-Object Price -EQ [Double]::NaN | ForEach-Object { $_.Reasons.Add("No price data") }
                        # Ignore pool if price is more than $Config.UnrealPoolPriceFactor higher than average of all pools with same algorithm & currency; NiceHash & MiningPoolHub are always right
                        If ($Config.UnrealPoolPriceFactor -gt 1 -and ($Pools.Name | Sort-Object -Unique).Count -gt 1) { 
                            $Pools | Where-Object Price_Bias -gt 0 | Group-Object -Property Algorithm, Currency | Where-Object { $_.Count -ge 2 } | ForEach-Object { 
                                If ($PriceThreshold = (($_.Group.Price_Bias | Measure-Object -Average | Select-Object -ExpandProperty Average) * $Config.UnrealPoolPriceFactor)) { 
                                    $_.Group | Where-Object { $_.Name -notmatch "NiceHash|MiningPoolHub" } | Where-Object Price_Bias -GT $PriceThreshold | ForEach-Object { $_.Reasons.Add("Unreal price ($($Config.UnrealPoolPriceFactor)x higher than average price)") }
                                }
                            }
                            Remove-Variable PriceThreshold
                        }
                        If ($Config.Algorithm -like "+*") { 
                            # Filter non-enabled algorithms
                            $Pools | Where-Object { $Variables.PoolsConfig[$_.Name].Currency -notcontains "+$($_.Algorithm)" } | ForEach-Object { $_.Reasons.Add("Algorithm not enabled in generic config") }
                            $Pools | Where-Object { $Variables.PoolsConfig[$_.Name].Algorithm -like "+*" } | Where-Object { $Variables.PoolsConfig.$($_.Name).Algorithm -notcontains "+$($_.Algorithm)" } | ForEach-Object { $_.Reasons.Add("Algorithm not enabled in $($_.Name) pool config") }
                        }
                        Else { 
                            # Filter disabled algorithms
                            $Pools | Where-Object { $Config.Algorithm -contains "-$($_.Algorithm)" } | ForEach-Object { $_.Reasons.Add("Algorithm disabled (``-$($_.Algorithm)`` in generic config)") }
                            $Pools | Where-Object { $Variables.PoolsConfig[$_.Name].Algorithm -contains "-$($_.Algorithm)" } | ForEach-Object { $_.Reasons.Add("Algorithm disabled (``-$($_.Algorithm)`` in $($_.Name) pool config)") }
                        }
                        If ($Config.Currency -like "+*") { 
                            # Filter non-enabled currencies
                            $Pools | Where-Object { $Config.Currency -notcontains "+$($_.Currency)" } | ForEach-Object { $_.Reasons.Add("Currency not enabled in generic config") }
                            $Pools | Where-Object { $Variables.PoolsConfig[$_.Name].Currency -like "+*" } | Where-Object { $Variables.PoolsConfig.$($_.Name).Currency -notcontains "+$($_.Currency)" } | ForEach-Object { $_.Reasons.Add("Currency not enabled in $($_.Name) pool config") }
                        }
                        Else {
                            # Filter disabled currencies
                            $Pools | Where-Object { $Config.Currency -contains "-$($_.Currency)" } | ForEach-Object { $_.Reasons.Add("Currency disabled (``-$($_.Currency)`` in generic config)") }
                            $Pools | Where-Object { $Variables.PoolsConfig[$_.Name].Currency -contains "-$($_.Currency)" } | ForEach-Object { $_.Reasons.Add("Currency disabled (``-$($_.Currency)`` in $($_.Name) pool config)") }
                        }
                        # MinWorkers
                        $Pools | Where-Object { $null -ne $_.Workers -and $_.Workers -lt $Variables.PoolsConfig[$_.Name].MinWorker } | ForEach-Object { $_.Reasons.Add("Not enough workers at pool (MinWorker ``$($Variables.PoolsConfig[$_.Name].MinWorker)`` in $($_.BaseName) pool config)") }
                        $Pools | Where-Object { $null -ne $_.Workers -and $_.Workers -lt $Config.MinWorker } | ForEach-Object { $_.Reasons.Add("Not enough workers at pool (MinWorker ``$($Config.MinWorker)`` in generic config)") }
                        # SSL
                        If ($Config.SSL -eq "Never") { $Pools | Where-Object { -not $_.PoolPorts[0] } | ForEach-Object { $_.Reasons.Add("Non-SSL port not available (Config.SSL -eq 'Never')") } }
                        If ($Config.SSL -eq "Always") {$Pools | Where-Object { -not $_.PoolPorts[1] } | ForEach-Object { $_.Reasons.Add("SSL port not available (Config.SSL -eq 'Always')") } }
                        # SSL Allow selfsigned certificate
                        If (-not $Config.SSLAllowSelfSignedCertificate) { $Pools | Where-Object SSLSelfSignedCertificate | ForEach-Object { $_.Reasons.Add("Pool uses self signed certificate (Config.SSLAllowSelfSignedCertificate -eq '`$false')") } }

                        # Update pools last used, required for BalancesKeepAlive
                        If ($Variables.PoolsLastUsed) { $Variables.PoolsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -FilePath ".\Data\PoolsLastUsed.json" -Force}
                        If ($Variables.AlgorithmsLastUsed) { $Variables.AlgorithmsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -FilePath ".\Data\AlgorithmsLastUsed.json" -Force}

                        # Apply watchdog to pools
                        If ($Config.Watchdog) { 
                            $Pools | Where-Object Available | Group-Object -Property Name | ForEach-Object { 
                                # Suspend pool if more than 50% of all algorithms@pool failed
                                $PoolName = $_.Name
                                $WatchdogCount = ($Variables.WatchdogCount, ($Variables.WatchdogCount * $_.Group.Count / 2), (($Variables.Miners | Where-Object Best | Where-Object { $_.Workers.Pool.Name -eq $PoolName }).count) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
                                If ($PoolsToSuspend = $_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object PoolName -EQ $PoolName | Where-Object Kicked -LT $Variables.Timer).Count -gt $WatchdogCount }) { 
                                    $PoolsToSuspend | ForEach-Object { 
                                        $_.Available = $false
                                        $_.Reasons.Add("Pool suspended by watchdog")
                                    }
                                    Write-Message -Level Warn "Pool '$($_.Name)' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object PoolName -EQ $_.Name | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                }
                            }
                            $Pools | Where-Object Available | Group-Object -Property Algorithm, Name | ForEach-Object { 
                                # Suspend algorithm@pool if more than 50% of all possible miners for algorithm failed
                                $WatchdogCount = ($Variables.WatchdogCount, (($Variables.Miners | Where-Object Algorithm -contains $_.Group[0].Algorithm).Count / 2) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) + 1
                                If ($PoolsToSuspend = $_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object Algorithm -EQ ($_.Algorithm -replace '-\dGiB$') | Where-Object PoolName -EQ $_.Name | Where-Object Kicked -LT $Variables.CycleStarts[-2]).Count -gt $WatchdogCount }) { 
                                    $PoolsToSuspend | ForEach-Object { $_.Reasons.Add("Algorithm@Pool suspended by watchdog") }
                                    Write-Message -Level Warn "Algorithm@Pool '$($_.Group[0].Algorithm)@$($_.Group[0].Name)' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object Algorithm -EQ $_.Group[0].Algorithm | Where-Object PoolName -EQ $_.Group[0].Name | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object -Top 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                }
                            }
                            Remove-Variable PoolName, PoolsToSuspend, WatchdogCount -ErrorAction Ignore
                        }

                        # Make pools unavailable
                        $Pools | Where-Object Reasons | ForEach-Object { $_.Available = $false }

                        # Filter pools on miner set
                        If ($Config.MinerSet -lt 2) { 
                            $Pools | Where-Object { $Variables.UnprofitableAlgorithms[$_.Algorithm] -eq 1 } | ForEach-Object { $_.Reasons.Add("Unprofitable primary algorithm") }
                            $Pools | Where-Object { $Variables.UnprofitableAlgorithms[$_.Algorithm] -eq 2 } | ForEach-Object { $_.Reasons.Add("Unprofitable secondary algorithm") }
                        }
                        $Pools | Where-Object Reasons | ForEach-Object { $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Sort-Object -Unique) }

                        If ($Variables.Pools.Count -gt 0) { 
                            Write-Message -Level Info "Had $($Variables.PoolsCount) pool$(If ($Variables.PoolsCount -ne 1) { "s" })$(If ($PoolsDeconfigured) { ", removed $($PoolsDeconfigured.Count) deconfigured pool$(If ($PoolsDeconfigured.Count -ne 1) { "s" } )" })$(If ($Variables.PoolsAdded.Count) { ", found $($Variables.PoolsAdded.Count) new pool$(If ($Variables.PoolsAdded.Count -ne 1) { "s" })" }), updated $($Variables.PoolsUpdated.Count) pool$(If ($Variables.PoolsUpdated.Count -ne 1) { "s" })$(If ($Pools | Where-Object Available -NE $true) { ", filtered out $(@($Pools | Where-Object Available -NE $true).Count) pool$(If (@($Pools | Where-Object Available -NE $true).Count -ne 1) { "s" })" }). $(@($Pools | Where-Object Available).Count) available pool$(If (@($Pools | Where-Object Available).Count -ne 1) { "s" }) remain$(If (@($Pools | Where-Object Available).Count -eq 1) { "s" })."
                        }
                        Else { 
                            Write-Message -Level Info "Found $($PoolsNew.Count) pool$(If ($PoolsNew.Count -ne 1) { "s" }), filtered out $(@($Pools | Where-Object Available -NE $true).Count) pool$(If (@($Pools | Where-Object Available -NE $true).Count -ne 1) { "s" }). $(@($Pools | Where-Object Available).Count) available pool$(If (@($Pools | Where-Object Available).Count -ne 1) { "s" }) remain$(If (@($Pools | Where-Object Available).Count -eq 1) { "s" })."
                        }

                        # Keep pool balances alive; force mining at pool even if it is not the best for the algo
                        If ($Config.BalancesKeepAlive -and $Variables.BalancesTrackerRunspace -and $Variables.PoolsLastEarnings.Count -gt 0 -and $Variables.PoolsLastUsed) { 
                            $Variables.PoolNamesToKeepBalancesAlive = @()
                            ForEach ($Pool in @($Pools | Where-Object Name -notin $Config.BalancesTrackerExcludePool | Sort-Object -Property Name -Unique)) { 
                                If ($Variables.PoolsLastEarnings[$Pool.Name] -and $Variables.PoolsConfig[$Pool.Name].BalancesKeepAlive -gt 0 -and (([DateTime]::Now).ToUniversalTime() - $Variables.PoolsLastEarnings[$Pool.Name]).Days -ge ($Variables.PoolsConfig[$Pool.Name].BalancesKeepAlive - 10)) { 
                                    $Variables.PoolNamesToKeepBalancesAlive += $PoolName
                                    Write-Message -Level Warn "Pool '$($Pool.Name)' prioritized to avoid forfeiting balance (pool would clear balance in 10 days)."
                                }
                            }
                            If ($Variables.PoolNamesToKeepBalancesAlive) { 
                                $Pools | ForEach-Object { 
                                    If ($_.Name -in $Variables.PoolNamesToKeepBalancesAlive) { $_.Available = $true; $_.Prioritize = $true; $_.Reasons = [System.Collections.Generic.List[String]]@("Prioritized by BalancesKeepAlive") }
                                    Else { $_.Reasons.Add("BalancesKeepAlive prioritizes other pools") }
                                }
                            }
                        }

                        # Mark best pools, allow all DAG pools (optimal pool might not fit in GPU memory)
                        $Pools | Where-Object Available | Group-Object Algorithm | ForEach-Object { $_.Group | Sort-Object { $_.Prioritize }, { $_.Price_Bias } -Bottom $(If ($_.Group.Algorithm -match $Variables.RegexAlgoHasDAG) { $_.Group.Count } Else { 1 }) | ForEach-Object { $_.Best = $true } }
                    }

                    # Update data in API
                    $Variables.Pools = $Pools

                    # Core suspended with <Ctrl><Alt>P in MainLoop
                    While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }
                }
                Else { 
                    # No configuired pools, clear all pools
                    $Variables.Pools = [Pool[]]@()
                }
                Remove-Variable Pools, PoolsDeconfigured, PoolsNew, PoolTimeStamp -ErrorAction Ignore

                $Variables.PoolsBest = $Variables.Pools | Where-Object Best | Sort-Object -Property Algorithm

                # Tuning parameters require local admin rights
                $Variables.UseMinerTweaks = [Boolean]($Variables.IsLocalAdmin -and $Config.UseMinerTweaks)
            }
            Else { 
                $Variables.EndCycleTime = $Variables.EndCycleTime.AddSeconds([Math]::Floor($Config.Interval / 2))
            }

            # Ensure we get the hashrate for running miners prior looking for best miner
            ForEach ($Miner in $Variables.MinersBest_Combo | Sort-Object { ($_.Name -Split '-')[2] }) { 
                If ($Miner.DataReaderJob.HasMoreData -and $Miner.Status -ne [MinerStatus]::DryRun) { 
                    $Miner.Data = @($Miner.Data | Select-Object -Last ($Miner.MinDataSample * 5)) # Reduce data to MinDataSample * 5
                    If ($Samples = @($Miner.DataReaderJob | Receive-Job | Select-Object)) { 
                        $Sample = $Samples | Select-Object -Last 1
                        $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                        # Hashrate from primary algorithm is relevant
                        If ($Sample.Hashrate.($Miner.Algorithms[0])) { 
                            $Miner.DataSampleTimestamp = $Sample.Date
                        }
                    }
                    Remove-Variable Sample, Samples -ErrorAction Ignore
                }

                If ($Miner.Status -in @([MinerStatus]::Running, [MinerStatus]::DryRun)) { 
                    If ($Miner.GetStatus() -eq [MinerStatus]::Running -or $Miner.Status -eq [MinerStatus]::DryRun) { 
                        $Miner.ContinousCycle ++
                        If ($Config.Watchdog) { 
                            ForEach ($Worker in $Miner.WorkersRunning) { 
                                If ($WatchdogTimer = $Variables.WatchdogTimers | Where-Object MinerName -EQ $Miner.Name | Where-Object PoolName -EQ $Worker.Pool.Name | Where-Object PoolRegion -EQ $Worker.Pool.Region | Where-Object Algorithm -EQ $Miner.Algorithms[$Miner.WorkersRunning.IndexOf($Worker)] | Sort-Object -Property Kicked -Bottom 1) { 
                                    # Update watchdog timers
                                    $WatchdogTimer.Kicked = ([DateTime]::Now).ToUniversalTime()
                                }
                                Else {
                                    # Create watchdog timer
                                    $Variables.WatchdogTimers += [PSCustomObject]@{ 
                                        Algorithm     = $Miner.Algorithms[$Miner.WorkersRunning.IndexOf($Worker)]
                                        DeviceNames   = $Miner.DeviceNames
                                        Kicked        = ([DateTime]::Now).ToUniversalTime()
                                        MinerBaseName = $Miner.BaseName
                                        MinerName     = $Miner.Name
                                        MinerVersion  = $Miner.Version
                                        PoolName      = $Worker.Pool.Name
                                        PoolRegion    = $Worker.Pool.Region
                                        PoolVariant   = $Worker.Pool.Variant
                                    }
                                }
                            }
                            Remove-Variable Worker -ErrorAction Ignore
                        }
                        If ($Config.BadShareRatioThreshold -gt 0) { 
                            $Miner.Algorithms | ForEach-Object { 
                                If ($LatestMinerSharesData = ($Miner.Data | Select-Object -Last 1 -ErrorAction Ignore).Shares) { 
                                    If ($LatestMinerSharesData.$_[1] -gt 0 -and $LatestMinerSharesData.$_[3] -gt [Math]::Floor(1 / $Config.BadShareRatioThreshold) -and $LatestMinerSharesData.$_[1] / $LatestMinerSharesData.$_[3] -gt $Config.BadShareRatioThreshold) { 
                                        $Miner.StatusInfo = "Error: '$($Miner.Info)' stopped. Too many bad shares (Shares Total = $($LatestMinerSharesData.$_[3]), Rejected = $($LatestMinerSharesData.$_[1]))"
                                        $Miner.SetStatus([MinerStatus]::Failed)
                                        $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }
                                    }
                                }
                            }
                        }
                    }
                    Else { 
                        $Miner.StatusInfo = "Error: '$($Miner.Info)' exited unexpectedly"
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }
                    }
                }

                If ($Miner.Activated -gt 0) { 
                    $Miner_Hashrates = @{ }
                    If ($Miner.Data.Count) { 
                        # Collect hashrate from miner, returns an array of two values (safe, unsafe)
                        $Miner.Hashrates_Live = @()
                        ForEach ($Algorithm in $Miner.Algorithms) { 
                            $CollectedHashrate = $Miner.CollectHashrate($Algorithm, (-not $Miner.Benchmark -and $Miner.Data.Count -lt $Miner.MinDataSample))
                            $Miner.Hashrates_Live += [Double]($CollectedHashrate[1])
                            $Miner_Hashrates.$Algorithm = [Double]($CollectedHashrate[0])
                        }
                        If ($Miner.ReadPowerUsage) { 
                            # Collect power usage from miner, returns an array of two values (safe, unsafe)
                            $CollectedPowerUsage = $Miner.CollectPowerUsage(-not $Miner.MeasurePowerUsage -and $Miner.Data.Count -lt $Miner.MinDataSample)
                            $Miner.PowerUsage_Live = [Double]($CollectedPowerUsage[1])
                            $Miner_PowerUsage = [Double]($CollectedPowerUsage[0])
                        }
                    }

                    # Do not save data if stat just got removed (Miner.Activated < 1, set by API)
                    If ($Miner.Activated -ge 1 -and $Miner.Status -ne [MinerStatus]::DryRun) { 
                        # We don't want to store hashrates if we have less than $MinDataSample
                        If ($Miner.Data.Count -ge $Miner.MinDataSample -or $Miner.Activated -gt $Variables.WatchdogCount) { 
                            $Miner.StatEnd = ([DateTime]::Now).ToUniversalTime()
                            $Stat_Span = [TimeSpan]($Miner.StatEnd - $Miner.StatStart)

                            ForEach ($Worker in $Miner.WorkersRunning) { 
                                $Algorithm = $Miner.Algorithms[$Miner.WorkersRunning.IndexOf($Worker)]
                                $Factor = 1
                                $LatestMinerSharesData = ($Miner.Data | Select-Object -Last 1 -ErrorAction Ignore).Shares
                                If ($Miner.Data.Count -gt $Miner.MinDataSample -and -not $Miner.Benchmark -and $Config.SubtractBadShares -and $LatestMinerSharesData.$Algorithm -gt 0) { # Need $Miner.MinDataSample shares before adjusting hashrate
                                    $Factor = (1 - $LatestMinerSharesData.$Algorithm[1] / $LatestMinerSharesData.$Algorithm[3])
                                    $Miner_Hashrates.$Algorithm *= $Factor
                                }
                                # $Stat_Name = "$($Miner.Name)_$($Algorithm)_Hashrate"
                                $Stat_Name = "$($Miner.Name)_$($Algorithm)_Hashrate"
                                $Stat = Set-Stat -Name $Stat_Name -Value $Miner_Hashrates.$Algorithm -Duration $Stat_Span -FaultDetection ($Miner.Data.Count -lt $Miner.MinDataSample -or $Miner.Activated -lt $Variables.WatchdogCount) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                                If ($Stat.Updated -gt $Miner.StatStart) { 
                                    Write-Message -Level Info "Saved hashrate for '$($Stat_Name -replace '_Hashrate$')': $(($Miner_Hashrates.$Algorithm | ConvertTo-Hash) -replace ' ')$(If ($Factor -le 0.999) { " (adjusted by factor $($Factor.ToString('N3')) [Shares total: $($LatestMinerSharesData.$Algorithm[2]), rejected: $($LatestMinerSharesData.$Algorithm[1])])" })$(If ($Miner.Benchmark) { " [Benchmark done] ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))" })."
                                    $Miner.StatStart = $Miner.StatEnd
                                    $Variables.AlgorithmsLastUsed.($Worker.Pool.Algorithm) = @{ Updated = $Stat.Updated; Benchmark = $Miner.Benchmark; MinerName = $Miner.Name }
                                    $Variables.PoolsLastUsed.($Worker.Pool.Name) = $Stat.Updated # most likely this will count at the pool to keep balances alive
                                }
                                ElseIf ($Miner_Hashrates.$Algorithm -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($Miner_Hashrates.$Algorithm -gt $Stat.Week * 2 -or $Miner_Hashrates.$Algorithm -lt $Stat.Week / 2)) { # Stop miner if new value is outside ±200% of current value
                                    $Miner.StatusInfo = "Error: '$($Miner.Info)'' Reported hashrate is unreal ($($Algorithm): $(($Miner_Hashrates.$Algorithm | ConvertTo-Hash) -replace ' ') is not within ±200% of stored value of $(($Stat.Week | ConvertTo-Hash) -replace ' '))"
                                    $Miner.SetStatus([MinerStatus]::Failed)
                                    $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }
                                }
                            }
                            Remove-Variable Factor -ErrorAction Ignore
                        }
                        If ($Miner.ReadPowerUsage) { 
                            # We don't want to store power usage if we have less than $MinDataSample, store even when fluctuating hash rates were recorded
                            If ($Miner.Data.Count -ge $Miner.MinDataSample -or $Miner.Activated -gt $Variables.WatchdogCount) { 
                                If ([Double]::IsNaN($Miner_PowerUsage )) { $Miner_PowerUsage = 0 }
                                $Stat_Name = "$($Miner.Name)$(If ($Miner.Workers.Count -eq 1) { "_$($Miner.Algorithms[0])" })_PowerUsage"
                                # Always update power usage when benchmarking
                                $Stat = Set-Stat -Name $Stat_Name -Value $Miner_PowerUsage -Duration $Stat_Span -FaultDetection (-not $Miner.Benchmark -and ($Miner.Data.Count -lt $Miner.MinDataSample -or $Miner.Activated -lt $Variables.WatchdogCount)) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                                If ($Stat.Updated -gt $Miner.StatStart) { 
                                    Write-Message -Level Info "Saved power usage for '$($Stat_Name -replace '_PowerUsage$')': $($Stat.Live.ToString("N2"))W$(If ($Miner.MeasurePowerUsage) { " [Power usage measurement done] ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))" })."
                                }
                                ElseIf ($Miner_PowerUsage -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($Miner_PowerUsage -gt $Stat.Week * 2 -or $Miner_PowerUsage -lt $Stat.Week / 2)) { 
                                    # Stop miner if new value is outside ±200% of current value
                                    $Miner.StatusInfo = "Error: '$($Miner.Info)' Reported power usage is unreal ($($PowerUsage.ToString("N2"))W is not within ±200% of stored value of $(([Double]$Stat.Week).ToString("N2"))W)"
                                    $Miner.SetStatus([MinerStatus]::Failed)
                                    $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }
                                }
                            }
                        }
                    }
                    Remove-Variable Algorithm, CollectedHashrateFactor, CollectedPowerUsage, LatestMinerSharesData, Miner_Hashrates, Miner_PowerUsage, Stat, Stat_Name, Stat_Span, Worker -ErrorAction Ignore
                }
            }
            Remove-Variable Miner -ErrorAction Ignore

            # Send data to monitoring server
            If ($Config.ReportToServer) { Write-MonitoringData }

            # Faster shutdown
            If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

            # Core suspended with <Ctrl><Alt>P in MainLoop
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Much faster
            $Miners = $Variables.Miners.Clone()

            # Get new miners
            If ($AvailablelMinerPools = If ($Config.MinerUseBestPoolsOnly) { $Variables.Pools | Where-Object Available | Where-Object { $_.Best -or $_.Prioritize } } Else { $Variables.Pools | Where-Object Available }) { 
                $MinerPools = @([Ordered]@{ }, [Ordered]@{ } )
                $AvailablelMinerPools | Where-Object { $_.Reasons -notcontains "Unprofitable primary algorithm"} | Group-Object Algorithm | ForEach-Object { $MinerPools[0][($_.Group.Algorithm | Sort-Object -Unique)] = @($_.Group | Sort-Object Price_Bias) }
                $AvailablelMinerPools | Where-Object { $_.Reasons -notcontains "Unprofitable secondary algorithm"} | Group-Object Algorithm | ForEach-Object { $MinerPools[1][($_.Group.Algorithm | Sort-Object -Unique)] = @($_.Group | Sort-Object Price_Bias) }
                $MinerPools[0]."" = $MinerPools[1]."" = ""
                Remove-Variable AvailablelMinerPools, NewMiners -ErrorAction Ignore

                Write-Message -Level Info "Loading miners...$(If (-not $Variables.Miners) { "<br>This may take a while." })"

                $MinersNew = [Miner[]]@()
                $MinerDevices = @($Variables.EnabledDevices | Select-Object -Property Bus, ConfiguredPowerUsage, Name, ReadPowerUsage, Status)
                Get-ChildItem -Path ".\Miners\*.ps1" | ForEach-Object -Parallel { 
                    $MinerPools = $using:MinerPools
                    $Config = $using:Config
                    $Variables = $using:Variables
                    & $_.FullName
                } -ThrottleLimit 5 | ForEach-Object { 
                    Try { 
                        $Miner = $_
                        $Miner | Add-Member MinDataSample $Config.MinDataSample
                        $Miner | Add-Member ProcessPriority $(If ($_.Type -eq "CPU") { $Config.CPUMinerProcessPriority } Else { $Config.GPUMinerProcessPriority })
                        ForEach ($Algorithm in $Miner.Workers.Pool.Algorithm) { 
                            $Miner.Workers[$Miner.Workers.Pool.Algorithm.IndexOf($Algorithm)].Fee = If ($Config.IgnoreMinerFee) { 0 } Else { $Miner.Fee[$Miner.Workers.Pool.Algorithm.IndexOf($Algorithm)] }
                        }
                        $Miner.PSObject.Properties.Remove("Fee")

                        $Miner | Add-Member Algorithms @(
                            $Miner.Workers.Pool | ForEach-Object { 
                                # Rename algoritm based on DAG size
                                "$($_.Algorithm)$(If ($_.DAGSizeGiB) { "-$([Math]::Ceiling($_.DAGSizeGiB))GiB" })"
                            }
                        )
                        $Algorithm_Pool = "{$(($Miner.Workers | ForEach-Object { "$($Miner.Algorithms[$Miner.Workers.IndexOf($_)])$(If ($_.Pool.Currency) { "[$($_.Pool.Currency)]" })", $_.Pool.Name -join '@' }) -join ' & ')}"
                        $Miner | Add-Member Key "$($Miner.Name) $Algorithm_Pool"
                        $Miner | Add-Member Info "$(($Miner.Name -split '-')[0..2] -join '-') $Algorithm_Pool"
                        $MinersNew += $Miner -as $_.API
                    }
                    Catch { 
                        Write-Message -Level Error "Failed to add Miner '$($Miner.Name)' as '$($Miner.API)' ($($Miner | ConvertTo-Json -Compress))"
                        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Error.txt"
                        $_.Exception | Format-List -Force >> "Logs\Error.txt"
                        $_.InvocationInfo | Format-List -Force >> "Logs\Error.txt"
                    }
                } | Out-Null
                Remove-Variable Algorithm, Algorithm_Pool, Miner, MinerFileName, MinerPools -ErrorAction Ignore
            }

            $CompareMiners = Compare-Object @($Miners | Select-Object) @($MinersNew | Select-Object) -Property DeviceNames, Key -IncludeEqual -PassThru
            # Properties that need to be set only once because they are not dependent on any config or pool information
            ForEach ($Miner in ($CompareMiners | Where-Object SideIndicator -EQ "=>")) { 
                $Miner.BaseName, $Miner.Version, $null = $Miner.Name -split '-'
                $Miner.Devices = @($MinerDevices | Where-Object Name -in $Miner.DeviceNames)
            }
            Remove-Variable Miner, MinerDevices -ErrorAction Ignore
            $Miners = [Miner[]]@($CompareMiners | Where-Object SideIndicator -NE "<=")

            # Faster shutdown
            If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

            # Make smaller groups for faster update
            $MinersGroups = $MinersNew | Group-Object -Property Name
            $Miners | Group-Object -Property Name | ForEach-Object { 
                $MinersGroup = ($MinersGroups | Where-Object Name -eq $_.Name).Group
                $_.Group | ForEach-Object { 
                    If ($_.KeepRunning = ($_.Status -in @([MinerStatus]::Running, [MinerStatus]::DryRun)) -and -not ($_.Benchmark -or $_.MeasurePowerUsage -or $Variables.DonationRunning) -and $_.ContinousCycle -lt $Config.MinCycle ) { # Minimum numbers of full cycles not yet reached
                        $_.Restart = $false
                    }
                    Else { 
                        If ($Miner = $MinersGroup | Where-Object Key -eq $_.Key) { 
                            # Update existing miners
                            If ($_.Restart = $_.Arguments -ne $Miner.Arguments) { 
                                $_.Arguments = $Miner.Arguments
                                $_.Port = $Miner.Port
                            }
                            $_.CommandLine = $_.GetCommandLine().Replace("$($PWD)\", "")
                            $_.PrerequisitePath = $Miner.PrerequisitePath
                            $_.PrerequisiteURI = $Miner.PrerequisiteURI
                            $_.WarmupTimes = $Miner.WarmupTimes
                        }
                    }
                    $_.Refresh($Variables.PowerCostBTCperW, $Variables.CalculatePowerCost)
                    $_.WindowStyle = If ($Config.MinerWindowStyleNormalWhenBenchmarking -and $_.Benchmark) { "normal" } Else { $Config.MinerWindowStyle }
                }
            }
            Remove-Variable Miner, MinersGroup, MinersGroup, MinersNew -ErrorAction Ignore

            $Variables.MinerDataCollectedTimeStamp = ([DateTime]::Now).ToUniversalTime()

            # Faster shutdown
            If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

            # Core suspended with <Ctrl><Alt>P in MainLoop
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            If ($Miners) { 
                # Filter miners
                $Miners | Where-Object Disabled | ForEach-Object { $_.Reasons.Add("Disabled by user"); $_.Status = [MinerStatus]::Disabled }
                $Miners | Where-Object { $_.Workers[0].Hashrate -eq 0 } | ForEach-Object { $_.Reasons.Add("0 H/s Stat file") } # Allow 0 hashrate for secondary algorithm
                If ($Config.ExcludeMinerName.Count) { $Miners | Where-Object { (Compare-Object @($Config.ExcludeMinerName | Select-Object) @($_.BaseName, "$($_.BaseName)-$($_.Version)", $_.Name | Select-Object -Unique) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | ForEach-Object { $_.Reasons.Add("ExcludeMinerName ($($Config.ExcludeMinerName -join ', '))") } }
                $Miners | Where-Object Earning -EQ 0 | ForEach-Object { $_.Reasons.Add("Earning -eq 0") }
                If ($Config.DisableMinersWithFee) { $Miners | Where-Object { $_.Workers.Fee } | ForEach-Object { $_.Reasons.Add("Config.DisableMinersWithFee") } }
                If ($Config.DisableDualAlgoMining) { $Miners | Where-Object { $_.Workers.Count -eq 2 } | ForEach-Object { $_.Reasons.Add("Config.DisableDualAlgoMining") } }
                ElseIf ($Config.DisableSingleAlgoMining) { $Miners | Where-Object { $_.Workers.Count -eq 1 } | ForEach-Object { $_.Reasons.Add("Config.DisableSingleAlgoMining") } }

                # Disable CPU miners when running on battery
                If ($Config.DisableCpuMiningOnBattery -and (Get-CimInstance Win32_Battery).BatteryStatus -eq 1) { $Miners | Where-Object Type -EQ "CPU" | ForEach-Object { $_.Reasons.Add("Config.DisableCpuMiningOnBattery") } }

                # Detect miners with unreal earning (> x times higher than average of the next best 10% or at least 5 miners)
                If ($Config.UnrealMinerEarningFactor -gt 1) { 
                    $Miners | Where-Object { -not $_.Reasons } | Group-Object { [String]$_.DeviceNames } | ForEach-Object { 
                        If ($ReasonableEarning = [Double]($_.Group | Sort-Object -Descending -Property Earning | Select-Object -Skip 1 -First (5, [Math]::Floor($_.Group.Count / 10) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) | Measure-Object Earning -Average).Average * $Config.UnrealMinerEarningFactor) { 
                            $_.Group | Where-Object Earning -GT $ReasonableEarning | ForEach-Object { $_.Reasons.Add("Unreal profit data (-gt $($Config.UnrealMinerEarningFactor)x higher than the next best miners available miners)") }
                        }
                    }
                }

                $Variables.MinersMissingBinary = @()
                $Miners | Where-Object { -not $_.Reasons -and -not (Test-Path -Path $_.Path -Type Leaf) } | ForEach-Object { $_.Reasons.Add("Binary missing"); $Variables.MinersMissingBinary += $_ }

                $Variables.MinersMissingPrerequisite = @()
                $Miners | Where-Object { -not $_.Reasons -and $_.PrerequisitePath } | ForEach-Object { $_.Reasons.Add("Prerequisite missing ($(Split-Path -Path $_.PrerequisitePath -Leaf))"); $Variables.MinersMissingPrerequisite += $_ }

                # Apply watchdog to miners
                If ($Config.Watchdog) { 
                    $Miners | Where-Object { -not $_.Reasons } | Group-Object -Property { "$($_.BaseName)-$($_.Version)" } | ForEach-Object { 
                        # Suspend miner if more than 50% of all available algorithms failed
                        $WatchdogMinerCount = ($Variables.WatchdogCount, [Math]::Floor($Variables.WatchdogCount * $_.Group.Count / 2) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
                        If ($MinersToSuspend = @($_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object MinerBaseName -EQ $_.BaseName | Where-Object MinerVersion -EQ $_.Version | Where-Object Kicked -LT $Variables.Timer).Count -gt $WatchdogMinerCount })) { 
                            $MinersToSuspend | ForEach-Object { 
                                $_.Reasons.Add("Miner suspended by watchdog (all algorithms)")
                            }
                            Write-Message -Level Warn "Miner '$($_.Group[0].BaseName)-$($_.Group[0].Version) [all algorithms]' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object MinerBaseName -EQ $_.Group[0].BaseName | Where-Object MinerVersion -EQ $_.Group[0].Version | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object -Bottom 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                        }
                        Remove-Variable MinersToSuspend, WatchdogMinerCount
                    }
                    $Miners | Where-Object { -not $_.Reasons } | Where-Object { @($Variables.WatchdogTimers | Where-Object MinerName -EQ $_.Name | Where-Object DeviceNames -EQ $_.DeviceNames | Where-Object Algorithm -EQ ($_.Algorithm -replace '-\dGiB$') | Where-Object Kicked -LT $Variables.Timer).Count -ge $Variables.WatchdogCount } | ForEach-Object { 
                        $_.Reasons.Add("Miner suspended by watchdog (Algorithm $($_.Algorithm))")
                        Write-Message -Level Warn "Miner '$($_.Name) [$($_.Algorithm)]' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object MinerName -EQ $_.Name | Where-Object DeviceNames -EQ $_.DeviceNames | Where-Object Algorithm -EQ ($_.Algorithm -replace '-\dGiB$') | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object -Bottom 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                    }
                }

                $Miners | Where-Object Reasons | ForEach-Object { $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Sort-Object -Unique); $_.Available = $false }

                Write-Message -Level Info "Loaded $($Miners.Count) miner$(If ($Miners.Count -ne 1) { "s" }), filtered out $(($Miners | Where-Object Available -NE $true).Count) miner$(If (($Miners | Where-Object Available -NE $true).Count -ne 1) { "s" }). $(($Miners | Where-Object Available).Count) available miner$(If (($Miners | Where-Object Available).Count -ne 1) { "s" }) remain$(If (($Miners | Where-Object Available).Count -eq 1) { "s" })."

                $DownloadList = @($Variables.MinersMissingPrerequisite | Select-Object @{ Name = "URI"; Expression = { $_.PrerequisiteURI } }, @{ Name = "Path"; Expression = { $_.PrerequisitePath } }, @{ Name = "Searchable"; Expression = { $false } }) + @($Variables.MinersMissingBinary | Select-Object URI, Path, @{ Name = "Searchable"; Expression = { $false } }) | Select-Object * -Unique
                If ($DownloadList) { 
                    If ($Variables.Downloader.State -ne "Running") { 
                        # Download miner binaries
                        Write-Message -Level Info "Some miners binaries are missing ($($DownloadList.Count) item$(If ($DownloadList.Count -ne 1) { "s" })), starting downloader..."
                        $Downloader_Parameters = @{ 
                            Config = $Config
                            DownloadList = $DownloadList
                            Variables = $Variables
                        }
                        $Variables.Downloader = Start-ThreadJob -Name Downloader -StreamingHost $null -FilePath ".\Includes\Downloader.ps1" -InitializationScript ([scriptblock]::Create("Set-Location '$($Variables.MainPath)'")) -ArgumentList $Downloader_Parameters
                        Remove-Variable Downloader_Parameters
                    }
                    ElseIf (-not ($Miners | Where-Object Available)) { 
                        Write-Message -Level Info "Waiting 30 seconds for downloader to install binaries..."
                    }
                }
                Remove-Variable DownloadList

                # Open firewall ports for all miners
                If ($Config.OpenFirewallPorts) { 
                    If (Get-Command "Get-MpPreference") { 
                        If ((Get-Command "Get-MpComputerStatus") -and (Get-MpComputerStatus)) { 
                            If (Get-Command "Get-NetFirewallRule") { 
                                If ($MissingMinerFirewallRules = Compare-Object @(Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program -Unique) @($Miners | Select-Object -ExpandProperty Path -Unique) -PassThru | Where-Object SideIndicator -EQ "=>") { 
                                    Start-Process "pwsh" ("-Command Import-Module NetSecurity; ('$($MissingMinerFirewallRules | ConvertTo-Json -Compress)' | ConvertFrom-Json) | ForEach-Object { New-NetFirewallRule -DisplayName (Split-Path `$_ | Split-Path -leaf) -Program `$_ -Description 'Inbound rule added by $($Variables.Branding.ProductLabel) $($Variables.Branding.Version) on $(([DateTime]::Now).ToString())' -Group '$($Variables.Branding.ProductLabel)' }" -replace '"', '\"') -Verb runAs
                                }
                                Remove-Variable MissingMinerFirewallRules
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
                Write-Message -Level Info "Selecting best miner$(If (@($Variables.EnabledDevices.Model | Select-Object -Unique).Count -gt 1) { "s" }) based on$(If ($Variables.CalculatePowerCost) { " profit (power cost $($Config.MainCurrency) $($Variables.PowerPricekWh)/kW⋅h)" } Else { " earning" })..."

                If (($Miners | Where-Object Available).Count -eq 1) { 
                    $Variables.MinersBest_Combo = $Variables.MinersBest = $Variables.MinersMostProfitable = $Miners
                }
                Else { 
                    $Bias = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit_Bias" } Else { "Earning_Bias" }

                    # Add running miner bonus
                    $RunningMinerBonusFactor = 1 + $Config.MinerSwitchingThreshold / 100
                    $Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { $_.$Bias *= $RunningMinerBonusFactor }

                    # Get best miners per algorithm and device
                    $Variables.MinersMostProfitable = @($Miners | Where-Object Available | Group-Object { [String]$_.DeviceNames }, { [String]$_.Algorithms } | ForEach-Object { $_.Group | Sort-Object -Descending -Property Benchmark, MeasurePowerUsage, KeepRunning, Prioritize, $Bias, Activated, @{ Expression = { $_.WarmupTimes[1] + $_.MinDataSample }; Descending = $true }, Name, @{ Expression = { [String]$_.Algorithms }; Descending = $false } -Top 1 | ForEach-Object { $_.MostProfitable = $true; $_ } })
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
                    $Variables.MinersBest_Combo = @(($Variables.MinersBest_Combos | Sort-Object -Descending { @($_.Combination | Where-Object { [Double]::IsNaN($_.$Bias) }).Count }, { ($_.Combination | Measure-Object $Bias -Sum | Select-Object -ExpandProperty Sum) }, { ($_.Combination | Where-Object { $_.$Bias -ne 0 } | Measure-Object).Count } -Top 1).Combination)

                    # Revert running miner bonus
                    $Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { $_.$Bias /= $RunningMinerBonusFactor }
                    Remove-Variable Bias, Miner_Device_Combo, Miner_Device_Count, Miner_Device_Regex, RunningMinerBonusFactor -ErrorAction Ignore
                }

                $Variables.PowerUsageIdleSystemW = (($Config.PowerUsageIdleSystemW - ($Variables.MinersBest_Combo | Where-Object Type -eq "CPU" | Measure-Object PowerUsage -Sum | Select-Object -ExpandProperty Sum)), 0 | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)

                $Variables.BasePowerCost = [Double]($Variables.PowerUsageIdleSystemW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.MainCurrency))

                $Variables.MiningEarning = [Double]($Variables.MinersBest_Combo | Measure-Object Earning -Sum | Select-Object -ExpandProperty Sum)
                $Variables.MiningPowerCost = [Double]($Variables.MinersBest_Combo | Measure-Object PowerCost -Sum | Select-Object -ExpandProperty Sum)
                $Variables.MiningPowerUsage = [Double]($Variables.MinersBest_Combo | Measure-Object PowerUsage -Sum | Select-Object -ExpandProperty Sum)
                $Variables.MiningProfit = [Double](($Variables.MinersBest_Combo | Measure-Object Profit -Sum | Select-Object -ExpandProperty Sum) - $Variables.BasePowerCost)
            }
            Else { 
                $Variables.MiningEarning = $Variables.MiningProfit = $Variables.MiningPowerCost = $Variables.MiningPowerUsage = [Double]0
            }
        }

        $Variables.MinersNeedingBenchmark = @($Miners | Where-Object { $_.Available -and $_.Benchmark } | Sort-Object -Property { [String]$_.Algorithms, $_.Name } -Unique)
        $Variables.MinersNeedingPowerUsageMeasurement = @($Miners | Where-Object { $_.Available -and $_.MeasurePowerUsage } | Sort-Object -Property { [String]$_.Algorithms, $_.Name } -Unique)

        # ProfitabilityThreshold check - OK to run miners?
        If ($Variables.DonationRunning -or (-not $Config.CalculatePowerCost -and $Variables.MiningEarning -ge ($Config.ProfitabilityThreshold / $Variables.Rates.BTC.($Config.MainCurrency))) -or ($Config.CalculatePowerCost -and $Variables.MiningProfit -ge ($Config.ProfitabilityThreshold / $Variables.Rates.BTC.($Config.MainCurrency))) -or $Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerUsageMeasurement) { 
            $Variables.MinersBest_Combo | ForEach-Object { $_.Best = $true }
            If ($Variables.Rates."BTC") { 
                If ($Variables.MinersNeedingBenchmark.Count) { 
                    $Variables.Summary = "Earning / day: n/a (Benchmarking: $($Variables.MinersNeedingBenchmark.Count) $(If ($Variables.MinersNeedingBenchmark.Count -eq 1) { "miner" } Else { "miners" }) left$(If (($Variables.EnabledDevices | Sort-Object -Property { $_.DeviceNames }).Count -gt 1) { " [$(($Variables.MinersNeedingBenchmark | Group-Object -Property { $_.DeviceNames } | Sort-Object -Property Name | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')]"}))"
                }
                ElseIf ($Variables.MiningEarning -gt 0) { 
                    $Variables.Summary = "Earning / day: {0:n} {1}" -f ($Variables.MiningEarning * $Variables.Rates."BTC".($Config.MainCurrency)), $Config.MainCurrency
                }
                Else { 
                    $Variables.Summary = ""
                }

                If ($Variables.CalculatePowerCost -and $Variables.PoolsBest) { 
                    If ($Variables.Summary -ne "") { $Variables.Summary += "&ensp;&ensp;&ensp;" }

                    If ($Variables.MinersNeedingPowerUsageMeasurement.Count -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                        $Variables.Summary += "Profit / day: n/a (Measuring power usage: $($Variables.MinersNeedingPowerUsageMeasurement.Count) $(If ($Variables.MinersNeedingPowerUsageMeasurement.Count -eq 1) { "miner" } Else { "miners" }) left$(If (($Variables.EnabledDevices | Sort-Object -Property { $_.DeviceNames }).Count -gt 1) { " [$(($Variables.MinersNeedingPowerUsageMeasurement | Group-Object -Property { $_.DeviceNames } | Sort-Object -Property Name | ForEach-Object { "$($_.Name): $($_.Count)" }) -join ', ')]"}))"
                    }
                    ElseIf ($Variables.MinersNeedingBenchmark.Count) { 
                        $Variables.Summary += "Profit / day: n/a"
                    }
                    ElseIf ($Variables.MiningPowerUsage -gt 0) { 
                        $Variables.Summary += "Profit / day: {0:n} {1}" -f ($Variables.MiningProfit * $Variables.Rates."BTC".($Config.MainCurrency)), $Config.MainCurrency
                    }
                    Else { 
                        $Variables.Summary += "Profit / day: n/a (no power data)"
                    }

                    If ($Variables.CalculatePowerCost) { 
                        If ($Variables.Summary -ne "") { $Variables.Summary += "&ensp;&ensp;&ensp;" }

                        If ([Double]::IsNaN($Variables.MiningEarning) -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                            $Variables.Summary += "Power Cost / day: n/a&ensp;[Miner$(If ($Variables.MinersBest_Combo.Count -ne 1) { "s" }): n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Config.MainCurrency, ($Variables.BasePowerCost * $Variables.Rates."BTC".($Config.MainCurrency)), $Variables.PowerUsageIdleSystemW
                        }
                        ElseIf ($Variables.MiningPowerUsage -gt 0) { 
                            $Variables.Summary += "Power Cost / day: {1:n} {0}&ensp;[Miner$(If ($Variables.MinersBest_Combo.Count -ne 1) { "s" }): {2:n} {0} ({3:n2} W); Base: {4:n} {0} ({5:n2} W)]" -f $Config.MainCurrency, (($Variables.MiningPowerCost + $Variables.BasePowerCost) * $Variables.Rates."BTC".($Config.MainCurrency)), ($Variables.MiningPowerCost * $Variables.Rates."BTC".($Config.MainCurrency)), $Variables.MiningPowerUsage, ($Variables.BasePowerCost * $Variables.Rates."BTC".($Config.MainCurrency)), $Variables.PowerUsageIdleSystemW
                        }
                        Else { 
                            $Variables.Summary += "Power Cost / day: n/a&ensp;[Miner: n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Config.MainCurrency, ($Variables.BasePowerCost * $Variables.Rates.BTC.($Config.MainCurrency)), $Variables.PowerUsageIdleSystemW
                        }
                    }
                }
                If ($Variables.Summary -ne "") { $Variables.Summary += "<br>" }

                # Add currency conversion rates
                @(@(If ($Config.UsemBTC) { "mBTC" } Else { "BTC" }) + @($Config.ExtraCurrencies)) | Select-Object -Unique | Where-Object { $Variables.Rates.$_.($Config.MainCurrency) } | ForEach-Object { 
                    $Variables.Summary += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Variables.Rates.$_.($Config.MainCurrency) -DecimalsMax $Config.DecimalsMax)} $($Config.MainCurrency)&ensp;&ensp;&ensp;" -f $Variables.Rates.$_.($Config.MainCurrency)
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
                $Variables.Summary = "Mining profit {0} {1:n$($Config.DecimalsMax)} / day is below the configured threshold of {0} {2:n$($Config.DecimalsMax)} / day. Mining is suspended until threshold is reached." -f $Config.MainCurrency, (($Variables.MiningEarning - $Variables.MiningPowerCost - $Variables.BasePowerCost) * $Variables.Rates."BTC".($Config.MainCurrency)), $Config.ProfitabilityThreshold
            }
            Else { 
                $Variables.Summary = "Mining earning {0} {1:n$($Config.DecimalsMax)} / day is below the configured threshold of {0} {2:n$($Config.DecimalsMax)} / day. Mining is suspended until threshold is reached." -f $Config.MainCurrency, ($Variables.MiningEarning * $Variables.Rates."BTC".($Config.MainCurrency)), $Config.ProfitabilityThreshold
            }
            Write-Message -Level Warn ($Variables.Summary -replace '<br>', ' ' -replace ' / day', '/day')
            If ($Variables.Rates) { 
                # Add currency conversion rates
                If ($Variables.Summary -ne "") { $Variables.Summary += "<br>" }
                @(@(If ($Config.UsemBTC) { "mBTC" } Else { "BTC" }) + @($Config.ExtraCurrencies)) | Select-Object -Unique | Where-Object { $Variables.Rates.$_.($Config.MainCurrency) } | ForEach-Object { 
                    $Variables.Summary += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Variables.Rates.$_.($Config.MainCurrency) -DecimalsMax $Config.DecimalsMax)} $($Config.MainCurrency)&ensp;&ensp;&ensp;" -f $Variables.Rates.$_.($Config.MainCurrency)
                }
            }
        }

        If (-not $Variables.MinersBest_Combo -and $Miners) { $Miners | ForEach-Object { $_.Best = $false } }

        # Stop running miners
        ForEach ($Miner in @($CompareMiners | Where-Object WorkersRunning | Sort-Object { ($_.Name -Split '-')[2] })) { 
            If ($Miner.Status -eq [MinerStatus]::Failed) { 
                $Miner.WorkersRunning = [Worker[]]@()
            }
            ElseIf ($Miner.Status -ne [MinerStatus]::DryRun -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                $Miner.StatusInfo = "Error: '$($Miner.Info)' exited unexpectedly"
                $Miner.SetStatus([MinerStatus]::Failed)
                $Miner.WorkersRunning = [Worker[]]@()
            }
            Else { 
                If ($Miner.GetStatus() -eq [MinerStatus]::Running -and $Config.DryRun) { $Miner.Restart = $true }
                If ($Miner.Status -eq [MinerStatus]::DryRun -and -not $Config.DryRun) { $Miner.Restart = $true }
                If ($Miner.Benchmark -or $Miner.MeasurePowerUsage) { $Miner.Restart = $true }
                If ($Miner.Best -ne $true -or $Miner.Restart -or $Miner.SideIndicator -eq "<=" -or $Variables.NewMiningStatus -ne "Running") { 
                    ForEach ($Worker in $Miner.WorkersRunning) { 
                        If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -EQ $Miner.Name | Where-Object PoolName -EQ $Worker.Pool.Name | Where-Object PoolRegion -EQ $Worker.Pool.Region | Where-Object Algorithm -EQ $Miner.Algorithms[$Miner.WorkersRunning.IndexOf($Worker)] | Where-Object DeviceNames -EQ $Miner.DeviceNames)) { 
                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })
                        }
                    }
                    Remove-Variable WatchdogTimers, Worker -ErrorAction Ignore
                    $Miner.SetStatus([MinerStatus]::Idle)
                    $Miner.WorkersRunning = [Worker[]]@()
                }
            }
            $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }
        }
        Remove-Variable CompareMiners, Miner, WatchdogTimers, Worker -ErrorAction Ignore

        # Kill stuck miners on subsequent cycles when not in dry run mode
        If ($Variables.CycleStarts.Count -eq 1 -or -not $Config.DryRun) { 
            $Loops = 0
            While ($StuckMinerProcessIDs = @(Get-CimInstance CIM_Process | Where-Object ExecutablePath | Where-Object { ($Miners.Path | Sort-Object -Unique) -contains $_.ExecutablePath } | Where-Object { $Miners.ProcessID -notcontains $_.ProcessID } | Select-Object -ExpandProperty ProcessID)) { 
                $StuckMinerProcessIDs | ForEach-Object { 
                    If ($Miner = $Miners | Where-Object ProcessID -EQ $_) { Write-Message -Level Verbose "Killing stuck miner '$($Miner.Name)'." }
                    Stop-Process -Id $_ -Force -ErrorAction Ignore
                }
                Start-Sleep -Milliseconds 500
                $Loops ++
                If ($Loops -gt 100) { 
                    $Message = "Cannot stop all miners graciously."
                    If ($Config.AutoReboot) { 
                        Write-Message -Level Error "$Message Restarting computer in 30 seconds..."
                        shutdown.exe /r /t 30 /c "$($Variables.Branding.ProductLabel) detected stuck miner$(If ($StuckMinerProcessIDs.Count -ne 1) { "s" }) and will reboot the computer in 30 seconds."
                        Start-Sleep -Seconds 60
                    }
                    Else { 
                        Write-Message -Level Error $Message
                        Start-Sleep -Seconds 30
                    }
                }
            }
            Remove-Variable Loops, Message, Miner, StuckMinerProcessIDs -ErrorAction Ignore
        }

        $Miners | ForEach-Object { 
            $_.PSObject.Properties.Remove("SideIndicator")
            If ($_.Reasons -and $_.Status -ne [MinerStatus]::Disabled) { 
                $_.Status = "Unavailable"
                $_.SubStatus = "Unavailable"
            }
            ElseIf ($_.Status -eq [MinerStatus]::Idle) { 
                $_.SubStatus = "Idle"
            }
        }

        If (-not ($Variables.EnabledDevices -and ($Miners | Where-Object Available))) {
            $Variables.Miners | ForEach-Object { $_.Status = [MinerStatus]::Idle; $_.StatusInfo = "Idle" }
            $Variables.Devices | Where-Object { $_.State -eq [DeviceState]::Enabled } | ForEach-Object { $_.Status = [MinerStatus]::Idle; $_.StatusInfo = "Idle" }
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
        ElseIf (-not $Variables.MinersBest_Combo) { 
            $Variables.Miners | ForEach-Object { $_.Status = [MinerStatus]::Idle; $_.StatusInfo = "Idle" }
            $Variables.Devices | Where-Object { $_.State -eq [DeviceState]::Enabled } | ForEach-Object { $_.Status = [MinerStatus]::Idle; $_.StatusInfo = "Idle" }
            Write-Message -Level Warn "No profitable miners - retrying in $($Config.Interval) seconds..."
            Start-Sleep -Seconds $Config.Interval
            Write-Message -Level Info "Ending cycle (No profitable miners)."
            Continue
        }

        # Update data in API
        $Variables.Miners = $Miners
        Remove-Variable Miners

        # Core suspended with <Ctrl><Alt>P in MainLoop
        While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

        # Faster shutdown
        If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

        # Optional delay to avoid blue screens
        Start-Sleep -Seconds $Config.Delay

        ForEach ($Miner in ($Variables.MinersBest_Combo | Sort-Object { ($_.Name -Split '-')[2] })) { 

            If ($Miner.GetStatus() -ne [MinerStatus]::Running -and $Miner.Status -ne [MinerStatus]::DryRun) { 
                If ($Miner.Status -ne [MinerStatus]::DryRun) { 
                    # Launch prerun if exists
                    If ($Miner.Type -eq "AMD" -and (Test-Path -Path ".\Utils\Prerun\AMDPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\AMDPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    ElseIf ($Miner.Type -eq "CPU" -and (Test-Path -Path ".\Utils\Prerun\CPUPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\CPUPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    ElseIf ($Miner.Type -eq "INTEL" -and (Test-Path -Path ".\Utils\Prerun\INTELPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\INTELPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    ElseIf ($Miner.Type -eq "NVIDIA" -and (Test-Path -Path ".\Utils\Prerun\NVIDIAPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\NVIDIAPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    $MinerAlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Name)$(If ($Miner.Algorithms.Count -eq 1) { "_$($Miner.Algorithms[0])" }).bat"
                    $AlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Algorithms -join '-').bat"
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
                    Remove-Variable AlgorithmPrerunName, DefaultPrerunName, MinerAlgorithmPrerunName -ErrorAction Ignore
                }

                # Add extra time when CPU mining and miner requires DAG creation
                If ($Miner.Workers.Pool.DAGSizeGiB -and $Variables.MinersBest_Combo.Type -contains "CPU") { $Miner.WarmupTimes[0] += 15 <# seconds #>}
                # Add extra time when notebook runs on battery
                If ($Miner.Workers.Pool.DAGSizeGiB -and (Get-CimInstance Win32_Battery).BatteryStatus -eq 1) { $Miner.WarmupTimes[0] += 90 <# seconds #>}

                # Stat just got removed (Miner.Activated < 1, set by API)
                If ($Miner.Activated -le 0) { $Miner.Activated = 0 }

                $Miner.Activated ++
                $Miner.ContinousCycle = 0
                $Miner.DataSampleTimestamp = [DateTime]0
                $Miner.Hashrates_Live = @($Miner.Workers | ForEach-Object { [Double]::NaN })
                $Miner.PowerUsage = [Double]::NaN
                $Miner.PowerUsage_Live = [Double]::NaN
                $Miner.ValidDataSampleTimestamp = [DateTime]0

                If ($Miner.Benchmark -or $Miner.MeasurePowerUsage) { 
                    $Miner.Earning = [Double]::NaN
                    $Miner.Earning_Bias = [Double]::NaN
                    If ($Miner.MeasurePowerUsage) {
                        $Miner.Profit = [Double]::NaN
                        $Miner.Profit_Bias = [Double]::NaN
                        $Miner.PowerUsage = [Double]::NaN
                        $Miner.PowerUsage_Live = [Double]::NaN
                    }
                    $Miner.Hashrates_Live = @($Miner.Workers | ForEach-Object { [Double]::NaN })
                }
                $Miner.DataCollectInterval = If ($Miner.Benchmark -or $Miner.MeasurePowerUsage) { 1 } Else { 5 }

                If (-not $Miner.Benchmark -and -not $Miner.MeasurePowerUsage -and $Config.DryRun) {
                    $Miner.SetStatus([MinerStatus]::DryRun)
                }
                Else { 
                    $Miner.SetStatus([MinerStatus]::Running)
                }
                $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }

                # Add watchdog timer
                If ($Config.Watchdog) { 
                    ForEach ($Worker in $Miner.Workers) { 
                        $Variables.WatchdogTimers += [PSCustomObject]@{ 
                            Algorithm     = $Miner.Algorithms[$Miner.Workers.IndexOf($Worker)]
                            DeviceNames   = $Miner.DeviceNames
                            Kicked        = ([DateTime]::Now).ToUniversalTime()
                            MinerBaseName = $Miner.BaseName
                            MinerName     = $Miner.Name
                            MinerVersion  = $Miner.Version
                            PoolName      = $Worker.Pool.Name
                            PoolRegion    = $Worker.Pool.Region
                            PoolVariant   = $Worker.Pool.Variant
                            CommandLine   = $Miner.CommandLine
                        }
                    }
                    Remove-Variable Worker -ErrorAction Ignore
                }
            }
            Else { 
                $DataCollectInterval = If ($Miner.Benchmark -or $Miner.MeasurePowerUsage) { 1 } Else { 5 }
                If ($Miner.DataCollectInterval -ne $DataCollectInterval) {
                    $Miner.DataCollectInterval = $DataCollectInterval
                    $Miner.RestartDataReader()
                }
            }

            $Message = "$(If ($Miner.Benchmark) { "Benchmark" })$(If ($Miner.Benchmark -and $Miner.MeasurePowerUsage) { " and " })$(If($Miner.MeasurePowerUsage) { "Power usage measurement" })"
            If ($Message) { Write-Message -Level Verbose "$($Message) for miner '$($Miner.Info)' in progress [Attempt $($Miner.Activated) of $($Variables.WatchdogCount + 1); min. $($Miner.MinDataSample) samples]..." }
        }
        Remove-Variable Miner, Message -ErrorAction Ignore

        $Variables.Miners | Where-Object Available | Group-Object { ($_.Name -Split '-')[2] } | ForEach-Object { 
            $MinersDeviceGroupNeedingBenchmark = $_.Group | Where-Object Benchmark
            $MinersDeviceGroupNeedingPowerUsageMeasurement = $_.Group | Where-Object MeasurePowerUsage

            # Display benchmarking progress
            If ($MinersDeviceGroupNeedingBenchmark) { 
                Write-Message -Level Verbose "Benchmarking for '$(($MinersDeviceGroupNeedingBenchmark[0].Name -Split '-')[2])' in progress. $(($MinersDeviceGroupNeedingBenchmark | Select-Object -Property { [String]$_.Algorithms, $_.Name } -Unique).Count) miner$(If (($MinersDeviceGroupNeedingBenchmark | Select-Object -Property { [String]$_.Algorithms, $_.Name } -Unique).Count -gt 1) { 's' }) left to complete benchmark."
            }
            # Display power usage measurement progress
            If ($MinersDeviceGroupNeedingPowerUsageMeasurement) { 
                Write-Message -Level Verbose "Power usage measurement for '$(($MinersDeviceGroupNeedingPowerUsageMeasurement[0].Name -Split '-')[2])' in progress. $(($MinersDeviceGroupNeedingPowerUsageMeasurement | Select-Object -Property { [String]$_.Algorithms, $_.Name } -Unique).Count) miner$(If (($MinersDeviceGroupNeedingPowerUsageMeasurement | Select-Object -Property { [String]$_.Algorithms, $_.Name } -Unique).Count -gt 1) { 's' }) left to complete measuring."
            }
        }
        Remove-Variable MinersDeviceGroupNeedingBenchmark, MinersDeviceGroupNeedingPowerUsageMeasurement -ErrorAction Ignore

        Get-Job -State "Completed" | Receive-Job | Out-Null
        Get-Job -State "Completed" | Remove-Job -Force -ErrorAction Ignore
        Get-Job -State "Failed" | Receive-Job | Out-Null
        Get-Job -State "Failed" | Remove-Job -Force -ErrorAction Ignore
        Get-Job -State "Stopped" | Receive-Job | Out-Null
        Get-Job -State "Stopped" | Remove-Job -Force -ErrorAction Ignore

        If ($Variables.CycleStarts.Count -eq 1) { 
            # Ensure a full cycle on first loop
            $Variables.EndCycleTime = ([DateTime]::Now).ToUniversalTime().AddSeconds($Config.Interval)
        }

        $Variables.RunningMiners = @($Variables.MinersBest_Combo | Sort-Object -Descending -Property Benchmark, MeasurePowerUsage)
        $Variables.BenchmarkingOrMeasuringMiners = [Miner[]]@()
        $Variables.FailedMiners = [Miner[]]@()

        # Core suspended with <Ctrl><Alt>P in MainLoop
        While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

        $Variables.EndCycleMessage = ""
        $Variables.RefreshTimestamp = ([DateTime]::Now).ToUniversalTime()
        $Variables.RefreshNeeded = $true

        Write-Message -Level Info "Collecting miner data while waiting for next cycle..."

        Do { 
            Start-Sleep -Milliseconds 100
            ForEach ($Miner in ($Variables.RunningMiners | Where-Object { $_.Status -ne [MinerStatus]::DryRun })) { 
                Try { 
                    If ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
                        # Miner crashed
                        $Miner.StatusInfo = "Error: '$($Miner.Info)' exited unexpectedly"
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.FailedMiners += $Miner
                    }
                    ElseIf ($Miner.DataReaderJob.State -eq [MinerStatus]::Failed) { 
                        # Miner data reader process failed
                        $Miner.StatusInfo = "Error: '$($Miner.Info)' Miner data reader exited unexpectedly"
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Variables.FailedMiners += $Miner
                    }
                    Else { 
                        # Set miner priority, some miners reset priority on their own
                        $Miner.Process.PriorityClass = $Global:PriorityNames.($Miner.ProcessPriority)

                        If ($Samples = @($Miner.DataReaderJob | Receive-Job | Select-Object)) { 
                            $Sample = $Samples | Select-Object -Last 1
                            $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                            If ($Miner.ReadPowerUsage) { $Miner.PowerUsage_Live = $Sample.PowerUsage }
                            If ($Sample.Hashrate) { 
                                If ($Sample.Hashrate -notcontains 0) { 
                                    # Need hashrates for all algorithms to count as a valid sample
                                    $Miner.DataSampleTimestamp = $Sample.Date
                                    If ($Miner.ValidDataSampleTimestamp -eq [DateTime]0) { 
                                        $Miner.ValidDataSampleTimestamp = $Sample.Date.AddSeconds($Miner.WarmupTimes[1])
                                    }
                                }
                                If ([Math]::Floor(($Sample.Date - $Miner.ValidDataSampleTimestamp).TotalSeconds) -ge 0) { 
                                    $Miner.Data += $Samples
                                    Write-Message -Level Verbose "$($Miner.Name) data sample retrieved [$(($Sample.Hashrate.PSObject.Properties.Name | ForEach-Object { "$($_): $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.BadShareRatioThreshold) { " / Shares Total: $($Sample.Shares.$_[3]), Rejected: $($Sample.Shares.$_[1]), Ignored: $($Sample.Shares.$_[2])" })" }) -join ' & ')$(If ($Sample.PowerUsage) { " / Power usage: $($Sample.PowerUsage.ToString("N2"))W" })] ($($Miner.Data.Count) Sample$(If ($Miner.Data.Count -ne 1) { "s" }))"
                                    If ($Miner.Benchmark -or $Miner.MeasurePowerUsage) { 
                                        $Miner.SubStatus = "Benchmarking"
                                        $Miner.StatusInfo = "$($(If ($Miner.Benchmark) { "Benchmarking" }), $(If ($Miner.Benchmark -and $Miner.MeasurePowerUsage) { " and " }), $(If ($Miner.MeasurePowerUsage) { "Measuring power usage" }) -join '') '$($Miner.Info)'"
                                    }
                                    Else {
                                        $Miner.SubStatus = "Running"
                                        $Miner.StatusInfo = "Mining '$($Miner.Info)'"
                                    }
                                }
                                Else { 
                                    Write-Message -Level Verbose "$($Miner.Name) data sample discarded [$(($Sample.Hashrate.PSObject.Properties.Name | ForEach-Object { "$($_): $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.BadShareRatioThreshold) { " / Shares Total: $($Sample.Shares.$_[3]), Rejected: $($Sample.Shares.$_[1]), Ignored: $($Sample.Shares.$_[2])" })" }) -join ' & ')$(If ($Sample.PowerUsage) { " / Power usage: $($Sample.PowerUsage.ToString("N2"))W" })] (Miner is warming up [$((([DateTime]::Now).ToUniversalTime() - $Miner.ValidDataSampleTimestamp).TotalSeconds.ToString("0")) sec])"
                                    $Miner.SubStatus = "WarmingUp"
                                    $Miner.StatusInfo = "Warming up '$($Miner.Info)'"
                                }
                            }
                        }
                        Else { 
                            # Stop miner, it has not provided hash rate on time
                            If ($Miner.DataSampleTimestamp -eq [DateTime]0 -and ([DateTime]::Now).ToUniversalTime() -gt $Miner.BeginTime.AddSeconds($Miner.WarmupTimes[0])) { 
                                $Miner.StatusInfo = "Error: '$($Miner.Info)' has not provided first data sample in $($Miner.WarmupTimes[0]) seconds"
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.FailedMiners += $Miner
                            }
                            # Miner stuck - no sample received in last few data collect intervals
                            ElseIf ($Miner.ValidDataSampleTimestamp -gt [DateTime]0 -and ([DateTime]::Now).ToUniversalTime() -gt $Miner.DataSampleTimestamp.AddSeconds((($Miner.DataCollectInterval * 5), 10 | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) * $Miner.Algorithms.Count)) { 
                                $Miner.StatusInfo = "Error: '$($Miner.Info)' has not updated data for more than $((($Miner.DataCollectInterval * 5), 10 | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) * $Miner.Algorithms.Count) seconds"
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.FailedMiners += $Miner
                            }
                        }

                        # Set window title
                        If ($Miner.Process.MainWindowHandle) { [Void][Win32]::SetWindowText($Miner.Process.MainWindowHandle, $Miner.StatusInfo) }
                    }
                    $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }
                }
                Catch { 
                    "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Error.txt"
                    $_.Exception | Format-List -Force >> "Logs\Error.txt"
                    $_.InvocationInfo | Format-List -Force >> "Logs\Error.txt"
                }
            }
            Remove-Variable Miner, Sample, Samples -ErrorAction Ignore

            $Variables.RunningMiners = @($Variables.RunningMiners | Where-Object { $_ -notin $Variables.FailedMiners })
            $Variables.BenchmarkingOrMeasuringMiners = @($Variables.RunningMiners | Where-Object { $_.Activated -gt 0 -and ($_.Benchmark -or $_.MeasurePowerUsage) })

            If ($Variables.FailedMiners -and -not $Variables.BenchmarkingOrMeasuringMiners) { 
                # A miner crashed and we're not benchmarking, exit loop immediately
                $Variables.EndCycleMessage = " prematurely (Miner failed)"
            }
            ElseIf ($Variables.BenchmarkingOrMeasuringMiners -and -not ($Variables.BenchmarkingOrMeasuringMiners | Where-Object { $_.Data.Count -lt $_.MinDataSample })) { 
                # Enough samples collected for this loop, exit loop immediately
                $Variables.EndCycleMessage = " (All running$(If ($Variables.BenchmarkingOrMeasuringMiners | Where-Object Benchmark) { " benchmarking" })$(If ($Variables.BenchmarkingOrMeasuringMiners | Where-Object { $_.Benchmark -and $_.MeasurePowerUsage }) { " and" })$(If ($Variables.BenchmarkingOrMeasuringMiners | Where-Object MeasurePowerUsage) { " power usage measuring" }) miners have collected enough samples for this cycle)"
            }

            # Core suspended with <Ctrl><Alt>P in MainLoop
            While ($Variables.SuspendCycle) { Start-Sleep -Seconds 1 }

            # Exit loop when
            # - a miner crashed (and no other miners are benchmarking or measuring power usage)
            # - all benchmarking miners have collected enough samples
            # - WarmupTimes[0] is reached (no readout from miner)
            # - Interval time is over
        } While (-not $Variables.EndCycleMessage -and $Variables.NewMiningStatus -eq "Running" -and $Variables.IdleRunspace.MiningStatus -ne "Idle" -and (([DateTime]::Now).ToUniversalTime() -le $Variables.EndCycleTime -or $Variables.BenchmarkingOrMeasuringMiners))

        If ($Variables.IdleRunspace.MiningStatus -eq "Idle") { $Variables.EndCycleMessage = " (System activity detected)" }

        # Expire brains loop to collect data
        $Variables.EndCycleTime = ([DateTime]::Now).ToUniversalTime()
    }
    Catch { 
        Write-Message -Level Error "Error in file $(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\") line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting core..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Error.txt"
        $_.Exception | Format-List -Force >> "Logs\Error.txt"
        $_.InvocationInfo | Format-List -Force >> "Logs\Error.txt"
        $Variables.EndCycleTime = $Variables.StartCycleTime.AddSeconds($Config.Interval) # Reset timers
        Continue
    }

    $Error.Clear()
    [System.GC]::Collect()

    Write-Message -Level Info "Ending cycle$($Variables.EndCycleMessage)."
    $Variables.RestartCycle = $true

} While ($Variables.NewMiningStatus -eq "Running")

# Stop all running miners
ForEach ($Miner in ($Variables.Miners | Where-Object { $_.Status -ne [MinerStatus]::Idle })) { 
    $Miner.SetStatus([MinerStatus]::Idle)
    $Miner.WorkersRunning = [Worker[]]@()
    $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo; $_.SubStatus = $Miner.SubStatus }
}
$Variables.RunningMiners = [Miner[]]@()
$Variables.BenchmarkingOrMeasuringMiners = [Miner[]]@()
$Variables.FailedMiners = [Miner[]]@()
Remove-Variable Miner -ErrorAction Ignore

$Variables.RestartCycle = $true