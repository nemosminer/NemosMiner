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
File:           Core.ps1
Version:        4.2.0.2
Version date:   30 August 2022
#>

using module .\Include.psm1
using module .\API.psm1

$ProgressPreference = "Ignore"

Do { 
    Get-ChildItem -Path ".\Includes\MinerAPIs" -File | ForEach-Object { . $_.FullName }
    Try {

        $Error.Clear()

        $Variables.LogFile = "$($Variables.MainPath)\Logs\$($Variables.Branding.ProductLabel)_$(Get-Date -Format "yyyy-MM-dd").log"

        # Always get the latest config
        $Variables.PoolName = $Config.PoolName
        Read-Config -ConfigFile $Variables.ConfigFile

        If ($Config.IdleDetection) { 
            If (-not $Variables.IdleRunspace) { 
                Start-IdleDetection
            }
            If ($Variables.IdleRunspace.MiningStatus -eq "Idle") { 
                $Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { 
                    $_.SetStatus([MinerStatus]::Idle)
                    $_.Info = ""
                    $_.WorkersRunning = @()
                }
                $Variables.WatchdogTimers = @()
                $Variables.Summary = "Mining is suspended until system is idle<br>again for $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" })..."
                $Variables.IdleRunspace | Add-Member MiningStatus "Idle" -Force
                Write-Message -Level Verbose ($Variables.Summary -replace "<br>", " ")

                While ($Variables.NewMiningStatus -eq "Running" -and $Config.IdleDetection -and $Variables.IdleRunspace.MiningStatus -eq "Idle") { Start-Sleep -Seconds 1 }

                If ($Config.IdleDetection) { Write-Message -Level Info "Started new cycle (System was idle for $($Config.IdleSec) seconds)." }
            }
        }
        Else { 
            If ($Variables.IdleRunspace) { Stop-IdleDetection }
            Write-Message -Level Info "Started new cycle."
        }

        [System.GC]::Collect()
        $Miners = $Variables.Miners # Much faster

        If ($Variables.EnabledDevices = $Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | ConvertTo-Json -Depth 10 | ConvertFrom-Json) { 
            # For GPUs set type equal to vendor
            $Variables.EnabledDevices | Where-Object Type -EQ "GPU" | ForEach-Object { $_.Type = $_.Vendor }
            # Remove model information from devices -> will create only one miner instance
            If (-not $Config.MinerInstancePerDeviceModel) { $Variables.EnabledDevices | ForEach-Object { $_.Model = $_.Vendor } }

            #Much faster
            $Pools = $Variables.Pools

            # Skip stuff if previous cycle was shorter than half of what it should
            If ($Config.Pools -ne $Variables.Pools -or -not $Variables.Miners -or -not $Variables.Timer -or $Variables.Timer.AddSeconds([Int]($Config.Interval / 2)) -lt (Get-Date).ToUniversalTime() -or (Compare-Object @($Config.ExtraCurrencies | Select-Object) @($Variables.AllCurrencies | Select-Object) | Where-Object SideIndicator -eq "<=")) { 

                # Set master timer
                $Variables.Timer = (Get-Date).ToUniversalTime()
                $Variables.EndCycleTime = $Variables.Timer.AddSeconds($Config.Interval)

                $Variables.CycleStarts += $Variables.Timer
                $Variables.CycleStarts = @($Variables.CycleStarts | Select-Object -Last (3, ($Config.SyncWindow + 1) | Measure-Object -Maximum).Maximum)
                $Variables.SyncWindowDuration = (($Variables.CycleStarts | Select-Object -Last 1) - ($Variables.CycleStarts | Select-Object -First 1))

                # Set minimum Watchdog minimum count 3
                $Variables.WatchdogCount = (3, $Config.WatchdogCount | Measure-Object -Maximum).Maximum
                $Variables.WatchdogReset = $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Variables.WatchdogCount * $Config.Interval

                # Expire watchdog timers
                If ($Config.Watchdog) { $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $Config.WatchDog } | Where-Object Kicked -GE $Variables.Timer.AddSeconds( - $Variables.WatchdogReset)) }
                Else { $Variables.WatchdogTimers = @() }

                # Check for new version
                If ($Config.AutoUpdateCheckInterval -and $Variables.CheckedForUpdate -lt (Get-Date).ToUniversalTime().AddDays(-$Config.AutoUpdateCheckInterval)) { Get-NMVersion }

                # Use non-donate pool config
                $Variables.NiceHashWalletIsInternal = $Config.NiceHashWalletIsInternal
                $PoolNames = If ($Variables.NiceHashWalletIsInternal) { $Config.PoolName -replace "NiceHash", "NiceHash Internal" } Else { $Config.PoolName -replace "NiceHash", "NiceHash External" }
                $PoolsConfig = $Config.PoolsConfig

                If ($Config.Donate -gt 0) { 
                    # Re-Randomize donation start once per day, do not donate if remaing time for today is less than donation duration
                    If (($Variables.DonateStart).Date -ne (Get-Date).Date -and (Get-Date).AddMinutes($Config.Donate).Date -eq (Get-Date).Date) { 
                        $Variables.DonateStart = (Get-Date).AddMinutes((Get-Random -Minimum $Config.Donate -Maximum (1440 - $Config.Donate - (Get-Date).TimeOfDay.TotalMinutes))).ToUniversalTime()
                        $Variables.DonateEnd = $null
                    }

                    If ((Get-Date).ToUniversalTime() -ge $Variables.DonateStart -and $null -eq $Variables.DonateEnd) { 
                        # We get here only once per day, ensure full donation period
                        $Variables.DonateStart = (Get-Date).ToUniversalTime()
                        $Variables.DonateEnd = $Variables.DonateStart.AddMinutes($Config.Donate)

                        # Add pool config to config (in-memory only)
                        Get-DonationPoolConfig

                        # Clear all pools
                        $Variables.Pools = [Pool[]]@()
                    }
                }

                If ($Variables.DonateRandom) { 
                    If ((Get-Date).ToUniversalTime() -ge $Variables.DonateStart -and (Get-Date).ToUniversalTime() -lt $Variables.DonateEnd) { 
                        # Ensure full donation period
                        $Variables.EndCycleTime = $Variables.DonateEnd
                        # Activate donation
                        $PoolNames = $Variables.DonatePoolsConfig.Keys -replace "Nicehash", "NiceHash External"
                        $PoolsConfig = $Variables.DonatePoolsConfig
                        $Variables.NiceHashWalletIsInternal = $false
                        Write-Message -Level Info "Donation run: Mining for '$($Variables.DonateRandom.Name)' for the next $(If (($Config.Donate - ((Get-Date) - $Variables.DonateStart).Minutes) -gt 1) { "$($Config.Donate - ((Get-Date) - $Variables.DonateStart).Minutes) minutes" } Else { "minute" }). $($Variables.Branding.ProductLabel) will use these pools while donating: '$($PoolNames -join ', ')'."
                    }
                    ElseIf ((Get-Date).ToUniversalTime() -gt $Variables.DonateEnd) { 
                        $Variables.DonatePoolsConfig = $null
                        $Variables.DonateRandom = $null
                        Write-Message -Level Info "Donation run complete - thank you! Mining for you again. :-)"

                        # Clear all pools
                        $Variables.Pools = [Pool[]]@()
                    }
                }

                Stop-Brain @($Variables.Brains.Keys | Where-Object { $_ -notin (Get-PoolBaseName $PoolNames) })

                # Faster shutdown
                If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

                Start-Brain (Get-PoolBaseName $PoolNames)

                # Clear pools if pools config has changed to avoid double pools with different wallets/usernames
                If (($Config.PoolsConfig | ConvertTo-Json -Depth 10 -Compress) -ne ($PoolsConfig | ConvertTo-Json -Depth 10 -Compress)) { $Variables.Pools = [Miner]::Pools }

                # Load information about the pools
                If ($PoolNames) { 
                    If ($Variables.CycleStarts.Count -gt 1) { 
                        Write-Message -Level Verbose "Loading pool data from '$($PoolNames -join ', ')'..."
                    }
                    Else { 
                        If ($Variables.Brains.Keys) {
                            # Allow extra time for brains to get ready
                            $Variables.Summary = "Loading initial pool data from '$($PoolNames -join ', ')'.<br>This may take up to 60 seconds..."
                            Write-Message -Level Verbose ($Variables.Summary -replace "<br>", " ")
                            Do { 
                                Start-Sleep -Seconds 1
                            } While (($Variables.BrainData.PSObject.Properties).Name.Count -lt $Variables.Brains.Keys.Count -and $Variables.Timer.AddMinutes(1) -gt (Get-Date).ToUniversalTime())
                        }
                        Else { 
                            $Variables.Summary = "Loading pool data from '$($PoolNames -join ', ')'.<br>This wil take while..."
                            Write-Message -Level Verbose ($Variables.Summary -replace "<br>", " ")
                        }
                    }
                    $NewPools_Jobs = @(
                        $PoolNames | ForEach-Object { 
                            Get-ChildItemContent ".\Pools\$((Get-PoolBaseName $_) -replace "^NiceHash .*", "NiceHash").*" -Parameters @{ Config = $Config; PoolsConfig = $PoolsConfig; PoolVariant = $_; Variables = $Variables } -Threaded -Priority $(If ($Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | Where-Object Type -EQ "CPU") { "Normal" })
                        }
                    )
                }

                # Do do once every 24hrs or if unable to get data from all sources
                If (-not $Variables.DAGdata) { $Variables.DAGdata = [PSCustomObject][Ordered]@{ } }
                If (-not $Variables.DAGdata.Algorithm) { $Variables.DAGdata | Add-Member Algorithm ([Ordered]@{ }) -Force }
                If (-not $Variables.DAGdata.Currency) { $Variables.DAGdata | Add-Member Currency ([Ordered]@{ }) -Force }
                If (-not $Variables.DAGdata.Updated) { $Variables.DAGdata | Add-Member Updated ([Ordered]@{ }) -Force }

                $Url = "https://minerstat.com/dag-size-calculator"
                If ($Variables.DAGdata.Updated.$Url -lt (Get-Date).ToUniversalTime().AddDays(-1)) { 
                    # Get block data from Minerstat
                    Try { 
                        $Response = Invoke-WebRequest -Uri $Url -TimeoutSec 5 # PWSH 6+ no longer supports basic parsing -> parse text
                        If ($Response.statuscode -eq 200) {
                            $Response.Content -split '\n' -replace '"', "'" | Where-Object { $_ -like "<div class='block' title='Current block height of *" } | ForEach-Object { 

                                $Currency = $_ -replace "^<div class='block' title='Current block height of " -replace "'>.*$"
                                $BlockHeight = [Int]($_ -replace "^<div class='block' title='Current block height of $Currency'>" -replace "</div>")

                                If ($BlockHeight -and $Currency) { 
                                    $Variables.DAGdata.Currency.Remove($Currency)
                                    $Variables.DAGdata.Currency.Add($Currency, (Get-DAGdata -BlockHeight $BlockHeight -Currency $Currency))
                                }
                            }
                            $Variables.DAGdata.Updated.$Url = (Get-Date).ToUniversalTime()
                            Write-Message -Level Info "Loaded DAG data from '$Url'."
                        }
                        Else { 
                            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
                        }
                    }
                    Catch { 
                        Write-Message -Level Warn "Failed to load DAG data from '$Url'."
                    }
                }

                $Url = "https://prohashing.com/api/v1/currencies"
                If ($Variables.DAGdata.Updated.$Url -lt (Get-Date).ToUniversalTime().AddDays(-1)) { 
                    Try { 
                        # Get block data from ProHashing
                        $Response = Invoke-RestMethod -Uri $Url

                        If ($Response.code -eq 200) { 
                            $Response.data.PSObject.Properties.Name | Where-Object { $Response.data.$_.enabled -and $Response.data.$_.height -and ((Get-Algorithm $Response.data.$_.algo) -in @("Autolykos2", "EtcHash", "Ethash", "EthashLowMem", "KawPow", "Octopus", "UbqHash") -or $_ -in @($Variables.DAGdata.Currency.Keys))} | ForEach-Object { 
                                If ($Response.data.$_.height -gt $Variables.DAGdata.Currency.$_.BlockHeight) { 
                                    $Variables.DAGdata.Currency.Remove($_)
                                    $Variables.DAGdata.Currency.Add($_, (Get-DAGdata -BlockHeight $Response.data.$_.height -Currency $_))
                                    $Variables.DAGdata.Updated.$Url = (Get-Date).ToUniversalTime()
                                }
                            }
                            $Variables.EthashLowMemCurrency = $Response.data.PSObject.Properties.Name | Where-Object { $Response.data.$_.enabled -and $Response.data.$_.height -and $Response.data.$_.algo -eq "ethash-lowmemory" } | Sort-Object { $Response.data.$_.height } | Select-Object -First 1
                            Write-Message -Level Info "Loaded DAG data from '$Url'."
                        }
                        Else { 
                            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
                        }
                    }
                    Catch { 
                        Write-Message -Level Warn "Failed to load DAG data from '$Url'."
                    }
                }

                $Url = "https://whattomine.com/coins.json"
                If ($Variables.DAGdata.Updated.$Url -lt (Get-Date).ToUniversalTime().AddDays(-1)) { 
                    Try { 
                        # Get block data for from whattomine.com
                        $Response = Invoke-RestMethod -Uri $Url

                        If ($Response.coins) { 
                            ForEach ($CoinName in @("FIRO", "SERO", "ZANO")) { 
                                If ($Response.coins.$CoinName.last_block -ge $Variables.DAGdata.Currency.$CoinName.BlockHeight) { 
                                    $Variables.DAGdata.Currency.Remove($CoinName)
                                    $Variables.DAGdata.Currency.Add($CoinName, (Get-DAGdata -BlockHeight $Response.coins.$CoinName.last_block -Currency $CoinName))
                                    $Variables.DAGdata.Updated.$Url = (Get-Date).ToUniversalTime()
                                }
                            }
                            Write-Message -Level Info "Loaded DAG data from '$Url'."
                        }
                        Else { 
                            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
                        }
                    }
                    Catch { 
                        Write-Message -Level Warn "Failed to load DAG data from '$Url'."
                    }
                }

                # Get maximum DAG size per algorithm
                ForEach ($Algorithm in @($Variables.DAGdata.Currency.Keys | ForEach-Object { $Variables.DAGdata.Currency.$_.Algorithm } | Select-Object)) { 
                    $Variables.DAGdata.Algorithm.Remove($Algorithm)
                    $Variables.DAGdata.Algorithm.Add($Algorithm, [PSCustomObject]@{ 
                        BlockHeight = ($Variables.DAGdata.Currency.Keys | Where-Object { (Get-CurrencyAlgorithm $_) -eq $Algorithm } | ForEach-Object { $Variables.DAGdata.Currency.$_.BlockHeight } | Measure-Object -Maximum).Maximum
                        DAGsize     = ($Variables.DAGdata.Currency.Keys | Where-Object { (Get-CurrencyAlgorithm $_) -eq $Algorithm } | ForEach-Object { $Variables.DAGdata.Currency.$_.DAGsize } | Measure-Object -Maximum).Maximum
                        Epoch       = ($Variables.DAGdata.Currency.Keys | Where-Object { (Get-CurrencyAlgorithm $_) -eq $Algorithm } | ForEach-Object { $Variables.DAGdata.Currency.$_.Epoch } | Measure-Object -Maximum).Maximum
                    })
                    $Variables.DAGdata.Algorithm.$Algorithm | Add-Member CoinName ($Variables.DAGdata.Currency.Keys | Where-Object { $Variables.DAGdata.Currency.$_.DAGsize -eq $Variables.DAGdata.Algorithm.$Algorithm.DAGsize -and $Variables.DAGdata.Currency.$_.Algorithm -eq $Algorithm })
                }

                If (-not $Variables.DAGdata.Currency."*") { 
                    $BlockHeight = ((Get-Date) - [DateTime]"07/31/2015").Days * 6400
                    Write-Message -Level Warn "Cannot load ethash DAG size information from 'https://minerstat.com', using calculated block height $BlockHeight based on 6400 blocks per day since 30 July 2015."
                    $Variables.DAGdata.Currency.Add("*", (Get-DAGdata -BlockHeight $BlockHeight -Currency "ETH"))
                }

                If (($Variables.DAGdata.Updated.Values | Sort-Object | Select-Object -Last 1) -gt $Variables.Timer -and $Variables.DAGdata.Currency.Count -gt 1) { 
                    # Add default '*' (equal to highest)
                    $Variables.DAGdata.Currency.Remove("*")
                    $Variables.DAGdata.Currency.Add("*", [PSCustomObject]@{ 
                        BlockHeight = [Int]($Variables.DAGdata.Currency.Keys | ForEach-Object { $Variables.DAGdata.Currency.$_.BlockHeight } | Measure-Object -Maximum).Maximum
                        CoinName    = "*"
                        DAGsize     = [Int64]($Variables.DAGdata.Currency.Keys | ForEach-Object { $Variables.DAGdata.Currency.$_.DAGsize } | Measure-Object -Maximum).Maximum
                        Epoch       = [Int]($Variables.DAGdata.Currency.Keys | ForEach-Object { $Variables.DAGdata.Currency.$_.Epoch } | Measure-Object -Maximum).Maximum
                    })

                    $Variables.DAGdata = $Variables.DAGdata | Get-SortedObject 
                    $Variables.DAGdata | ConvertTo-Json | Out-File -FilePath ".\Data\DagData.json" -Force -Encoding utf8NoBOM
                }
                Remove-Variable BlockHeight, Currency, Response, Url -ErrorAction Ignore

                # Load currency exchange rates from min-api.cryptocompare.com
                Get-Rate

                # Power cost preparations
                $Variables.CalculatePowerCost = $Config.CalculatePowerCost # $Variables.CalculatePowerCost is an operational variable and not identical to $Config.CalculatePowerCost
                If ($Config.CalculatePowerCost -eq $true) { 
                    If ($Variables.EnabledDevices.Count -ge 1) { 
                        # HWiNFO64 verification
                        $RegKey = "HKCU:\Software\HWiNFO64\VSB"
                        If ($RegValue = Get-ItemProperty -Path $RegKey) { 
                            If ([String]$Variables.HWInfo64RegValue -eq [String]$RegValue) { 
                                Write-Message -Level Warn "Power usage info in registry has not been updated [HWiNFO64 not running???] - disabling power usage and profit calculations."
                                $Variables.CalculatePowerCost = $false
                            }
                            Else { 
                                $Hashtable = @{ }
                                $DeviceName = ""
                                $RegValue.PSObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @($Variables.EnabledDevices.Name | Select-Object) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                                    $DeviceName = ($_.Value -split ' ') | Select-Object -Last 1
                                    Try { 
                                        $Hashtable.Add($DeviceName, $RegValue.($_.Name -replace "Label", "Value"))
                                    }
                                    Catch { 
                                        Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [duplicate sensor for $DeviceName] - disabling power usage and profit calculations."
                                        $Variables.CalculatePowerCost = $false
                                    }
                                }
                                # Add configured power usage
                                $Config.PowerUsage.PSObject.Properties.Name | Where-Object { $Config.PowerUsage.$_ } | ForEach-Object { 
                                    If ($Config.PowerUsage.$_) { 
                                        If ($_ -in @($Variables.EnabledDevices.Name) -and -not $Hashtable.$_) { Write-Message -Level Warn "HWiNFO64 cannot read power usage from system for device ($_). Will use configured value of $([Double]$Config.PowerUsage.$_) W." }
                                        $Hashtable.$_ = "$Config.PowerUsage.$_ W"
                                        If ($Variables.EnabledDevices | Where-Object Name -EQ $_) { ($Variables.EnabledDevices | Where-Object Name -EQ $_).ConfiguredPowerUsage = [Double]$Config.PowerUsage.$_ }
                                    }
                                }

                                If ($DeviceNamesMissingSensor = Compare-Object @($Variables.EnabledDevices.Name) @($Hashtable.Keys) -PassThru | Where-Object SideIndicator -EQ "<=") { 
                                    Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [missing sensor config for $($DeviceNamesMissingSensor -join ', ')] - disabling power usage and profit calculations."
                                    $Variables.CalculatePowerCost = $false
                                }

                                # Enable read power usage for configured devices
                                $Variables.Devices | ForEach-Object { $_.ReadPowerUsage = $_.Name -in @($Hashtable.Keys) }

                                Remove-Variable DeviceName, DeviceNamesMissingSensor, Hashtable
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
                If (-not (($Config.PowerPricekWh | Get-Member -MemberType NoteProperty).Name)) { $Config.PowerPricekWh = [PSCustomObject]@{ "00:00" = 0 } }
                If ($null -eq $Config.PowerPricekWh."00:00") { 
                    # 00:00h power price is the same as the latest price of the previous day
                    $Config.PowerPricekWh | Add-Member "00:00" (($Config.PowerPricekWh.($Config.PowerPricekWh | Get-Member -MemberType NoteProperty).Name | Sort-Object | Select-Object -Last 1))
                }
                $Variables.PowerPricekWh = [Double]($Config.PowerPricekWh.(($Config.PowerPricekWh | Get-Member -MemberType NoteProperty).Name | Sort-Object | Where-Object { $_ -lt (Get-Date -Format HH:mm).ToString() } | Select-Object -Last 1))
                $Variables.PowerCostBTCperW = [Double](1 / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.Currency))
                $Variables.BasePowerCostBTC = [Double]($Config.PowerUsageIdleSystemW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.Currency))

                # Put here in case the port range has changed
                Initialize-API

                # Send data to monitoring server
                If ($Config.ReportToServer) { Update-MonitoringData }

                # Ensure we get the hashrate for running miners prior looking for best miner
                ForEach ($Miner in $Variables.MinersBest_Combo) { 
                    # Reduce data to MinDataSamples * 5
                    $Miner.Data = @($Miner.Data | Select-Object -Last ($Miner.MinDataSamples * 5))
                    If ($Miner.DataReaderJob.HasMoreData) { $Miner.Data += @($Miner.DataReaderJob | Receive-Job | Select-Object -Property Date, Hashrate, Shares, PowerUsage) }

                    If ($Miner.Status -eq [MinerStatus]::Running) { 
                        If ($Miner.GetStatus() -eq [MinerStatus]::Running) { 
                            If ($Config.Watchdog) { 
                                ForEach ($Worker in $Miner.WorkersRunning) { 
                                    If ($WatchdogTimer = $Variables.WatchdogTimers | Where-Object MinerName -EQ $Miner.Name | Where-Object PoolName -EQ $Worker.Pool.Name | Where-Object PoolRegion -EQ $Worker.Pool.Region | Where-Object Algorithm -EQ $Worker.Pool.Algorithm | Sort-Object Kicked | Select-Object -Last 1) { 
                                        #Update watchdog timers
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
                            }
                            If ($Config.BadShareRatioThreshold -gt 0) { 
                                $Miner.WorkersRunning.Pool.Algorithm | ForEach-Object { 
                                    $LastSharesData = ($Miner.Data | Select-Object -Last 1).Shares
                                    If ($LastSharesData.$_ -and $LastSharesData.$_[1] -gt 0 -and $LastSharesData.$_[2] -gt [Int](1 / $Config.BadShareRatioThreshold) -and $LastSharesData.$_[1] / $LastSharesData.$_[2] -gt $Config.BadShareRatioThreshold) { 
                                        $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' stopped. Reasons: Too many bad shares (Shares Total = $($LastSharesData.$_[2]), Rejected = $($LastSharesData.$_[1]))."
                                        $Miner.Data = @() # Clear data because it may be incorrect caused by miner problem
                                        $Miner.SetStatus([MinerStatus]::Failed)
                                    }
                                }
                            }
                        }
                        Else { 
                            $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' exited unexpectedly."
                            $Miner.SetStatus([MinerStatus]::Failed)
                        }
                    }

                    $Miner.Hashrates_Live = @()
                    $PowerUsage = [Double]::NaN
                    If ($Miner.Data.Count) { 
                        # Collect hashrate from miner, returns an array of two values (safe, unsafe)
                        $Miner_Hashrates = [Hashtable]@{ }
                        ForEach ($Algorithm in $Miner.Algorithms) { 
                            $CollectedHashrate = $Miner.CollectHashrate($Algorithm, (-not $Miner.Benchmark -and $Miner.Data.Count -lt $Miner.MinDataSamples))
                            $Miner.Hashrates_Live += [Double]($CollectedHashrate[1])
                            $Miner_Hashrates.$Algorithm = [Double]($CollectedHashrate[0])
                        }
                        If ($Miner.ReadPowerUsage) { 
                            # Collect power usage from miner, returns an array of two values (safe, unsafe)
                            $CollectedPowerUsage = $Miner.CollectPowerUsage(-not $Miner.MeasurePowerUsage -and $Miner.Data.Count -lt $Miner.MinDataSamples)
                            $Miner.PowerUsage_Live = [Double]($CollectedPowerUsage[1])
                            $PowerUsage = [Double]($CollectedPowerUsage[0])
                        }
                    }

                    # Do not save data if stat just got removed (Miner.Activated < 1, set by API)
                    If ($Miner.Activated -gt 0) { 
                        # We don't want to store hashrates if we have less than $MinDataSamples
                        If ($Miner.Data.Count -ge $Miner.MinDataSamples -or $Miner.Activated -gt $Variables.WatchdogCount) { 
                            $Miner.StatEnd = (Get-Date).ToUniversalTime()
                            $Stat_Span = [TimeSpan]($Miner.StatEnd - $Miner.StatStart)

                            ForEach ($Worker in $Miner.WorkersRunning) { 
                                $Algorithm = $Worker.Pool.Algorithm
                                $Factor = 1
                                $LastSharesData = ($Miner.Data | Select-Object -Last 1).Shares
                                If ($Miner.Data.Count -gt $Miner.MinDataSamples -and -not $Miner.Benchmark -and $Config.SubtractBadShares -and $LastSharesData.$Algorithm -gt 0) { # Need $Miner.MinDataSamples shares before adjusting hashrate
                                    $Factor = (1 - $LastSharesData.$Algorithm[1] / $LastSharesData.$Algorithm[2])
                                    $Miner_Hashrates.$Algorithm *= $Factor
                                }
                                $Stat_Name = "$($Miner.Name)_$($Algorithm)_Hashrate"
                                $Stat = Set-Stat -Name $Stat_Name -Value $Miner_Hashrates.$Algorithm -Duration $Stat_Span -FaultDetection ($Miner.Data.Count -ge $Miner.MinDataSamples) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                                If ($Stat.Updated -gt $Miner.StatStart) { 
                                    Write-Message -Level Info "Saved hashrate for '$($Stat_Name -replace '_Hashrate$')': $(($Miner_Hashrates.$Algorithm | ConvertTo-Hash) -replace ' ')$(If ($Factor -le 0.999) { " (adjusted by factor $($Factor.ToString('N3')) [Shares total: $($LastSharesData.$Algorithm[2]), rejected: $($LastSharesData.$Algorithm[1])])" })$(If ($Stat.Duration -eq $Stat_Span) { " [Benchmark done]" })."
                                    $Miner.StatStart = $Miner.StatEnd
                                    $Variables.AlgorithmsLastUsed.($Worker.Pool.Algorithm) = @{ Updated = $Stat.Updated; Benchmark = $Miner.Benchmark; MinerName = $Miner.Name }
                                    $Variables.PoolsLastUsed.(Get-PoolBaseName $Worker.Pool.Name) = $Stat.Updated # most likely this will count at the pool to keep balances alive
                                }
                                ElseIf ($Miner_Hashrates.$Algorithm -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($Miner_Hashrates.$Algorithm -gt $Stat.Week * 2 -or $Miner_Hashrates.$Algorithm -lt $Stat.Week / 2)) { # Stop miner if new value is outside ±200% of current value
                                    $Miner.StatusMessage = "$($Miner.Name) $($Miner.Info): Reported hashrate is unreal ($($Algorithm): $(($Miner_Hashrates.$Algorithm | ConvertTo-Hash) -replace ' ') is not within ±200% of stored value of $(($Stat.Week | ConvertTo-Hash) -replace ' '))."
                                    $Miner.SetStatus([MinerStatus]::Failed)
                                }
                            }
                        }
                        If ($Miner.ReadPowerUsage -eq $true -and ($Stat.Updated -gt $Miner.StatStart -or $Miner.Activatd -gt $Variables.WatchdogCount)) { 
                            If ([Double]::IsNaN($PowerUsage)) { $PowerUsage = 0 }
                            $Stat_Name = "$($Miner.Name)$(If ($Miner.Workers.Count -eq 1) { "_$($Miner.Workers.Pool.Algorithm | Select-Object -First 1)" })_PowerUsage"
                            $Stat = Set-Stat -Name $Stat_Name -Value $PowerUsage -Duration $Stat_Span -FaultDetection ($Miner.Data.Count -gt $Miner.MinDataSamples) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                            If ($Stat.Updated -gt $Miner.StatStart) { 
                                Write-Message -Level Info "Saved power usage for '$($Stat_Name -replace '_PowerUsage$')': $($Stat.Live.ToString("N2"))W$(If ($Stat.Duration -eq $Stat_Span) { " [Power usage measurement done]" })."
                            }
                            ElseIf ($PowerUsage -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($PowerUsage -gt $Stat.Week * 2 -or $PowerUsage -lt $Stat.Week / 2)) { 
                                # Stop miner if new value is outside ±200% of current value
                                $Miner.StatusMessage = "$($Miner.Name) $($Miner.Info): Reported power usage is unreal ($($PowerUsage.ToString("N2"))W is not within ±200% of stored value of $(([Double]$Stat.Week).ToString("N2"))W)."
                                $Miner.SetStatus([MinerStatus]::Failed)
                            }
                        }
                        Remove-Variable Factor, LastSharesData, Stat_Name, Stat_Span, Stat -ErrorAction Ignore
                    }
                }
                Remove-Variable Algorithm, CollectedHashrate, CollectPowerUsage, Miner, Miner_Hashrates, PowerUsage, WatchdogTimer, WatchdogTimers -ErrorAction Ignore

                If ($PoolNames) { 
                    # Load unprofitable algorithms
                    Try { 
                        If (-not $Variables.UnprofitableAlgorithms -or (Get-ChildItem -Path ".\Data\UnprofitableAlgorithms.json").LastWriteTime -gt $Variables.Timer.AddSeconds( - $Config.Interval)) { 
                            $Variables.UnprofitableAlgorithms = Get-Content -Path ".\Data\UnprofitableAlgorithms.json" | ConvertFrom-Json -ErrorAction Stop -AsHashtable | Select-Object | Get-SortedObject
                            Write-Message -Level Info "Loaded list of unprofitable algorithms ($($Variables.UnprofitableAlgorithms.Count) $(If ($Variables.UnprofitableAlgorithms.Count -ne 1) { "entries" } Else { "entry" }))."
                        }
                    }
                    Catch { 
                        Write-Message -Level Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file. Please restore it from your original download."
                        $Variables.UnprofitableAlgorithms = $null
                    }

                    # Read all stats, will remove those from memory that no longer exist as file
                    Get-Stat

                    # Retrieve collected pool data
                    Try { 
                        $Variables.PoolAPITimeout = [Int]$Config.PoolAPITimeout 
                        If ($Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | Where-Object Type -EQ "CPU") { $Variables.PoolAPITimeout * 2 } # Double allowed time if CPU miner is running to avoid timeouts
                        $Variables.NewPools = @($NewPools_Jobs | ForEach-Object { $_ | Get-Job | Wait-Job -Timeout $Variables.PoolAPITimeout | Receive-Job } | ForEach-Object { $_.Content -as [Pool] })
                        $NewPools_Jobs | ForEach-Object { $_ | Get-Job -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore }
                        Remove-Variable NewPools_Jobs

                        $Variables.NewPools | ForEach-Object { 
                            $_.CoinName = Get-CoinName $_.Currency
                            $_.Fee = If ($Config.IgnorePoolFee -or $_.Fee -lt 0 -or $_.Fee -gt 1) { 0 } Else { $_.Fee }
                            $Factor = $_.EarningsAdjustmentFactor * (1 - $_.Fee)
                            $_.Price = $_.Price * $Factor
                            $_.Price_Bias = $_.Price * $_.Accuracy
                            $_.StablePrice = $_.StablePrice * $Factor
                        }
                    }
                    Catch { 
                        ($_.Exception | Format-List -Force) >> "Logs\Error.txt"
                        ($_.InvocationInfo | Format-List -Force) >> "Logs\Error.txt"
                    }

                    If ($PoolNoData = @(Compare-Object @($PoolNames) @($Variables.NewPools.Name | Sort-Object -Unique) -PassThru)) { 
                        Write-Message -Level Warn "No data received from pool$(If ($PoolNoData.Count -gt 1) { "s" }) '$($PoolNoData -join ', ')'."
                    }
                    Remove-Variable PoolNoData
                    $Variables.PoolDataCollectedTimeStamp = (Get-Date).ToUniversalTime()

                    # Faster shutdown
                    If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

                    # Region or Anycast changed, remove all pools because best pool sort cannot handle anycast AND regional pools, also helps keeping total pool number down
                    If ($Variables.UseAnycast -ne $Config.UseAnycast -or $Variables.Region -ne $Config.Region) { 
                        $Pools = [Pool[]]@()
                    }
                    $Variables.UseAnycast = $Config.UseAnycast
                    $Variables.Region = $Config.Region

                    # Remove de-configured pools
                    $DeconfiguredPools = $Pools | Where-Object Name -notin $PoolNames
                    $Pools = @($Pools | Where-Object Name -in $PoolNames)

                    If ($ComparePools = @(Compare-Object -PassThru @($Variables.NewPools | Select-Object) @($Pools | Select-Object) -Property Name, Algorithm, Host, Port, PortSSL, WorkerName -IncludeEqual)) { 
                        # Find new pools
                        $Variables.AddedPools = @($ComparePools | Where-Object SideIndicator -eq "<=" | ForEach-Object { $_.PSObject.Properties.Remove('SideIndicator'); $_ })
                        $Variables.UpdatedPools = @($ComparePools | Where-Object SideIndicator -eq "==" | ForEach-Object { $_.PSObject.Properties.Remove('SideIndicator'); $_ })

                        $Variables.PoolsCount = $Pools.Count

                        # Add new pools
                        $Pools += $Variables.AddedPools

                        # Update existing pools
                        $Pools | Select-Object | ForEach-Object { 
                            $_.Available = $true
                            $_.Best = $false
                            $_.Reasons = $null

                            If ($Pool = $Variables.UpdatedPools | Where-Object Name -EQ $_.Name | Where-Object Algorithm -EQ $_.Algorithm | Select-Object -First 1) { 
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
                                $_.Region                   = $Pool.Region
                                $_.StablePrice              = $Pool.StablePrice
                                $_.Updated                  = $Pool.Updated
                                $_.User                     = $Pool.User
                                $_.Workers                  = $Pool.Workers
                                $_.WorkerName               = $Pool.WorkerName
                            }

                            If ($_.Algorithm -eq "EthashLowMem" -and $Variables.EthashLowMemCurrency) { 
                                $_.BlockHeight = $Variables.DAGdata.Currency.($Variables.EthashLowMemCurrency).BlockHeight
                                $_.Epoch       = $Variables.DAGdata.Currency.($Variables.EthashLowMemCurrency).Epoch
                                $_.DAGSizeGB   = $Variables.DAGdata.Currency.($Variables.EthashLowMemCurrency).DAGsize / 1GB 
                            }
                            ElseIf ($Variables.DAGdata.Currency.($_.Currency).BlockHeight) { 
                                $_.BlockHeight = $Variables.DAGdata.Currency.($_.Currency).BlockHeight
                                $_.Epoch       = $Variables.DAGdata.Currency.($_.Currency).Epoch
                                $_.DAGSizeGB   = $Variables.DAGdata.Currency.($_.Currency).DAGsize / 1GB 
                            }
                            ElseIf ($_.Algorithm -in $Variables.DAGdata.Algorithm.Keys) { 
                                $_.BlockHeight = $Variables.DAGdata.Algorithm.($_.Algorithm).BlockHeight
                                $_.Epoch       = $Variables.DAGdata.Algorithm.($_.Algorithm).Epoch
                                $_.DAGSizeGB   = $Variables.DAGdata.Algorithm.($_.Algorithm).DAGsize / 1GB
                            }

                            # Ports[0] = non-SSL, Port[1] = SSL
                            $_.PoolPorts = @($(If ($Config.SSL -ne "Always" -and $_.Port) { [UInt16]$_.Port } Else { $null }), $(If ($Config.SSL -ne "Never" -and $_.PortSSL) { [UInt16]$_.PortSSL } Else { $null }))
                        }
                        Remove-Variable Factor, Pool

                        # Pool data is older than earliest CycleStart, decay price
                        If ($Variables.CycleStarts.Count -ge $Config.SyncWindow) { 
                            $MaxPoolAge = $Config.SyncWindow * ($Variables.CycleStarts[-1] - $Variables.CycleStarts[0]).TotalMinutes
                            $Pools = $Pools | Where-Object { [Math]::Floor(($Variables.CycleStarts[-1] - $_.Updated).TotalMinutes) -le $MaxPoolAge * $Config.SyncWindow * $Config.SyncWindow }
                            $Pools | ForEach-Object { 
                                If ([Math]::Floor(($Variables.CycleStarts[-1] - $_.Updated).TotalMinutes) -gt $MaxPoolAge) { $_.Reasons += "Data too old" }
                                ElseIf ($_.Updated -lt $Variables.CycleStarts[0]) { $_.Price_Bias = $_.Price * $_.Accuracy * [Math]::Pow(0.9, ($Variables.CycleStarts[0] - $_.Updated).TotalMinutes) }
                            }
                            Remove-Variable MaxPoolAge
                        }

                        # Pool disabled by stat file
                        $Pools | Where-Object Disabled -EQ $true | ForEach-Object { $_.Reasons += "Disabled (by Stat file)" }
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
                            $Pools | Where-Object Price_Bias -GT 0 | Group-Object -Property Algorithm | ForEach-Object { 
                                If (($_.Group.BaseName | Sort-Object -Unique).Count -ge 3 -and ($PriceThreshold = @($_.Group.Price_Bias | Sort-Object -Unique)[-2] * $Config.UnrealPoolPriceFactor)) { 
                                    $_.Group | Where-Object { $_.BaseName -notmatch "NiceHash *|MiningPoolHub" } | Where-Object Price_Bias -GT $PriceThreshold | ForEach-Object { $_.Reasons += "Unreal price ($($Config.UnrealPoolPriceFactor)x higher than second highest price)" }
                                }
                            }
                        }
                        Remove-Variable PriceThreshold
                        # Algorithms disabled
                        $Pools | Where-Object { "-$($_.Algorithm)" -in $Config.Algorithm } | ForEach-Object { $_.Reasons += "Algorithm disabled (``-$($_.Algorithm)`` in generic config)" }
                        $Pools | Where-Object { "-$($_.Algorithm)" -in $PoolsConfig.$(Get-PoolBaseName $_.BaseName).Algorithm } | ForEach-Object { $_.Reasons += "Algorithm disabled (``-$($_.Algorithm)`` in $($_.BaseName) pool config)" }
                        # Algorithms not enabled
                        If ($Config.Algorithm -like "+*") { $Pools | Where-Object { "+$($_.Algorithm)" -notin $Config.Algorithm } | ForEach-Object { $_.Reasons += "Algorithm not enabled in generic config" } }
                        $Pools | Where-Object { $PoolsConfig.$($_.BaseName).Algorithm -like "+*" } | Where-Object { "+$($_.Algorithm)" -notin $PoolsConfig.$($_.BaseName).Algorithm } | ForEach-Object { $_.Reasons += "Algorithm not enabled in $($_.BaseName) pool config" }
                        # MinWorkers
                        $Pools | Where-Object { $null -ne $_.Workers -and $_.Workers -lt $PoolsConfig.$($_.BaseName).MinWorker } | ForEach-Object { $_.Reasons += "Not enough workers at pool (MinWorker ``$($PoolsConfig.$($_.BaseName).MinWorker)`` in $($_.BaseName) pool config)" }
                        $Pools | Where-Object { $null -ne $_.Workers -and $_.Workers -lt $Config.MinWorker } | ForEach-Object { $_.Reasons += "Not enough workers at pool (MinWorker ``$($Config.MinWorker)`` in generic config)" }
                        # SSL
                        If ($Config.SSL -eq "Never") { $Pools | Where-Object { $_.PoolPorts[1] } | ForEach-Object { $_.Reasons += "Non-SSL port not available (Config.SSL = 'Never')" } }
                        If ($Config.SSL -eq "Always") { $Pools | Where-Object { -not $_.PoolPorts[1] } | ForEach-Object { $_.Reasons += "SSL port not available (Config.SSL = 'Always')" } }
                        # Update pools last used, required for BalancesKeepAlive
                        If ($Variables.PoolsLastUsed) { $Variables.PoolsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -FilePath ".\Data\PoolsLastUsed.json" -Force -Encoding utf8NoBOM}
                        If ($Variables.AlgorithmsLastUsed) { $Variables.AlgorithmsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File -FilePath ".\Data\AlgorithmsLastUsed.json" -Force -Encoding utf8NoBOM}

                        # Apply watchdog to pools
                        If ($Config.Watchdog) { 
                            $Pools | Where-Object Available -EQ $true | Group-Object -Property Name | ForEach-Object { 
                                # Suspend pool if > 50% of all algorithms@pool failed
                                $PoolName = $_.Name
                                $WatchdogCount = ($Variables.WatchdogCount, ($Variables.WatchdogCount * $_.Group.Count / 2), (($Variables.Miners | Where-Object Best | Where-Object { $_.Workers.Pool.Name -eq $PoolName }).count) | Measure-Object -Maximum).Maximum
                                If ($PoolsToSuspend = $_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object PoolName -EQ $PoolName | Where-Object Kicked -LT $Variables.Timer).Count -gt $WatchdogCount }) { 
                                    $PoolsToSuspend | ForEach-Object { $_.Reasons += "Pool suspended by watchdog" }
                                    Write-Message -Level Warn "Pool '$($_.Name)' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object PoolName -EQ $_.Name | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -First 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                }
                            }
                            $Pools | Where-Object Available -EQ $true | Group-Object -Property Algorithm, Name | ForEach-Object { 
                                # Suspend algorithm@pool if > 50% of all possible miners for algorithm failed
                                $WatchdogCount = ($Variables.WatchdogCount, (($Variables.Miners | Where-Object Algorithm2 -contains $_.Group[0].Algorithm).Count / 2) | Measure-Object -Maximum).Maximum + 1
                                If ($PoolsToSuspend = $_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object Algorithm -EQ $_.Algorithm | Where-Object PoolName -EQ $_.Name | Where-Object Kicked -LT $Variables.CycleStarts[-2]).Count -gt $WatchdogCount }) { 
                                    $PoolsToSuspend | ForEach-Object { $_.Reasons += "Algorithm@Pool suspended by watchdog" }
                                    Write-Message -Level Warn "Algorithm@Pool '$($_.Group[0].Algorithm)@$($_.Group[0].Name)' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object Algorithm -EQ $_.Group[0].Algorithm | Where-Object PoolName -EQ $_.Group[0].Name | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -First 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                                }
                            }
                            Remove-Variable PoolName, PoolsToSuspend, WatchdogCount
                        }

                        # Make pools unavailable
                        $Pools | Where-Object Reasons | ForEach-Object { $_.Available = $false }

                        # Filter pools on miner set
                        If ($Config.MinerSet -lt 2) { 
                            $Pools | Where-Object { $Variables.UnprofitableAlgorithms.($_.Algorithm) -eq 1 } | ForEach-Object { $_.Reasons += "Unprofitable primary algorithm" }
                            $Pools | Where-Object { $Variables.UnprofitableAlgorithms.($_.Algorithm) -eq 2 } | ForEach-Object { $_.Reasons += "Unprofitable secondary algorithm" }
                        }

                        If ($Variables.Pools.Count -gt 0) { 
                            Write-Message -Level Info "Had $($Variables.PoolsCount + $DeconfiguredPools.Count) pool$(If (($Variables.PoolsCount + $DeconfiguredPools.Count) -ne 1) { "s" }),$(If ($DeconfiguredPools) { " removed $($DeconfiguredPools.Count) deconfigured pool$(If ($DeconfiguredPools.Count -ne 1) { "s" } )," }) updated $($Variables.UpdatedPools.Count) pool$(If ($Variables.UpdatedPools.Count -ne 1) { "s" }), found $($Variables.AddedPools.Count) new pool$(If ($Variables.AddedPools.Count -ne 1) { "s" }), filtered out $(@($Pools | Where-Object Available -NE $true).Count) pool$(If (@($Pools | Where-Object Available -NE $true).Count -ne 1) { "s" }). $(@($Pools | Where-Object Available -EQ $true).Count) available pool$(If (@($Pools | Where-Object Available -EQ $true).Count -ne 1) { "s" }) remain$(If (@($Pools | Where-Object Available -EQ $true).Count -eq 1) { "s" })."
                        }
                        Else { 
                            Write-Message -Level Info "Found $($Variables.NewPools.Count) pool$(If ($NewPools.Count -ne 1) { "s" }), filtered out $(@($Pools | Where-Object Available -NE $true).Count) pool$(If (@($Pools | Where-Object Available -NE $true).Count -ne 1) { "s" }). $(@($Pools | Where-Object Available -EQ $true).Count) available pool$(If (@($Pools | Where-Object Available -EQ $true).Count -ne 1) { "s" }) remain$(If (@($Pools | Where-Object Available -EQ $true).Count -eq 1) { "s" })."
                        }

                        # Keep pool balances alive; force mining at pool even if it is not the best for the algo
                        If ($Config.BalancesKeepAlive -and $Variables.BalancesTrackerRunspace -and $Variables.PoolsLastEarnings.Count -gt 0 -and $Variables.PoolsLastUsed) { 
                            $PoolNamesToKeepBalancesAlive = @()
                            ForEach ($Pool in @($Pools | Where-Object Name -notin $Config.BalancesTrackerIgnorePool | Sort-Object Name -Unique)) { 

                                $PoolName = Get-PoolBaseName $Pool.Name
                                If ($Variables.PoolsLastEarnings.$PoolName -and $PoolsConfig.$PoolName.BalancesKeepAlive -gt 0 -and ((Get-Date).ToUniversalTime() - $Variables.PoolsLastEarnings.$PoolName).Days -ge ($PoolsConfig.$PoolName.BalancesKeepAlive - 10)) { 
                                    $PoolNamesToKeepBalancesAlive += $Pool.Name
                                    Write-Message -Level Warn "Pool ($PoolName) prioritized to avoid forfeiting balance (pool would clear balance in 10 days)."
                                }
                            }
                            If ($PoolNamesToKeepBalancesAlive) { 
                                $Pools | ForEach-Object { 
                                    If ($_.Name -in $PoolNamesToKeepBalancesAlive) { $_.Available = $true; $_.Reasons = "Prioritized by BalancesKeepAlive" }
                                    Else { $_.Reasons += "BalancesKeepAlive prioritizes other pools" }
                                }
                            }
                            Remove-Variable Pool, PoolName
                        }

                        # Sort best pools
                        [Pool[]]$SortedAvailablePools = $Pools | Where-Object Available -EQ $true | Sort-Object { $_.Name -notin $PoolNamesToKeepBalancesAlive }, { - $_.StablePrice * $_.Accuracy }
                        (($SortedAvailablePools).Algorithm | Select-Object -Unique) | ForEach-Object { 
                            $SortedAvailablePools | Where-Object Algorithm -EQ $_ | Select-Object -First 1 | ForEach-Object { $_.Best = $true }
                        }
                    }
                    # Update data in API
                    $Variables.Pools = $Pools
                }
                Else { 
                    # No configuired pools, clear all pools
                    $Variables.Pools = [Pool[]]@()
                }

                $Variables.PoolsBest = $Variables.Pools | Where-Object Best -EQ $true
                Remove-Variable DeconfiguredPools, ComparePools, Pools, PoolNamesToKeepBalancesAlive, PoolsConfig, SortedAvailablePools

                # Tuning parameters require local admin rights
                $Variables.UseMinerTweaks = ($Variables.IsLocalAdmin -and $Config.UseMinerTweaks)
            }

            # Faster shutdown
            If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

            # Get new miners
            If ($Variables.PoolsBest) { 
                $AllPools = [PSCustomObject]@{ }
                $MinerPools = @([PSCustomObject]@{ }, [PSCustomObject]@{ })
                $Variables.PoolsBest | Sort-Object Algorithm | ForEach-Object { 
                    $AllPools | Add-Member $_.Algorithm $_
                    If ($_.Reasons -ne "Unprofitable primary algorithm")   { $MinerPools[0] | Add-Member $_.Algorithm $_ } # Allow unprofitable algos for primary algorithm
                    If ($_.Reasons -ne "Unprofitable secondary algorithm") { $MinerPools[1] | Add-Member $_.Algorithm $_ } # Allow unprofitable algos for secondary algorithm
                }
                $Variables.MinerPools = $MinerPools
            }
            If ($Variables.MinerPools) { 
                If (-not ($Variables.Pools -and $Variables.Miners)) { $Variables.Summary = "Loading miners.<br>This will take a while..." }
                Write-Message -Level Verbose "Loading miners..."
                $MinerPools = $Variables.MinerPools
                $NewMiners = [Miner[]]@()
                (Get-ChildItem -Path ".\Miners" -File -Include "*.ps1" -Recurse -ErrorAction SilentlyContinue | Sort-Object | ForEach-Object { 
                    & $_.FullName
                }) | ForEach-Object { 
                    $_ | Add-Member MinDataSamples  ([Int]($Config.MinDataSamples * (($_.Algorithm | ForEach-Object { $Config.MinDataSamplesAlgoMultiplier.$_ }), 1 | Measure-Object -Maximum).Maximum))
                    $_ | Add-Member ProcessPriority $(If ($_.Type -eq "CPU") { $Config.CPUMinerProcessPriority } Else { $Config.GPUMinerProcessPriority })
                    $_ | Add-Member Workers ([Worker[]]@(ForEach ($Algorithm in $_.Algorithms) { @{ Pool = $AllPools.$Algorithm; Fee = If ($Config.IgnoreMinerFee) { 0 } Else { $_.Fee | Select-Object -Index $_.Algorithms.IndexOf($Algorithm) } } }))
                    $_.PSObject.Properties.Remove("Fee")
                    $NewMiners += $_ -as $_.API
                }
                Remove-Variable MinerPools
            }

            # Remove miners from gone pools
            $Miners = $Miners | Select-Object | Where-Object { $_.Workers[0].Pool.Name -in $PoolNames -and ($_.Workers.Count -eq 1 -or $_.Workers[1].Pool.Name -in $PoolNames) }

            If ($NewMiners) { # Sometimes there are no miners loaded, keep existing
                $CompareMiners = Compare-Object -PassThru @($Miners | Select-Object) @($NewMiners | Select-Object) -Property Name, Algorithms -IncludeEqual
                # Properties that need to be set only once and which are not dependent on any config variables
                $CompareMiners | Where-Object SideIndicator -EQ "=>" | ForEach-Object { 
                    $_.BaseName = ($_.Name -split '-' | Select-Object -Index 0)
                    $_.Devices  = [Device[]]($Variables.Devices | Where-Object Name -In $_.DeviceNames)
                    $_.Path     = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_.Path)
                    $_.Version  = ($_.Name -split '-' | Select-Object -Index 1)
                }
                $Miners = $CompareMiners | Where-Object SideIndicator -NE "<="
            }
            Remove-Variable AllPools, DataCollectInterval, Pools, PoolsSecondaryAlgorithm, ReadPowerUsage -ErrorAction Ignore

            If ($Miners -and $Variables.PoolsBest) { 
                $AddSeconds = $Config.Interval * ($Config.MinInterval -1)
                $Miners | Select-Object | ForEach-Object { 
                    $_.KeepRunning = $_.Status -eq [MinerStatus]::Running -and -not ($_.Benchmark -or $_.MeasurePowerUsage -or $Variables.DonateRandom) -and $_.BeginTime.AddSeconds($AddSeconds) -gt $Variables.Timer # Minimum numbers of full cycles not yet reached

                    If (-not $_.KeepRunning) { 
                        If ($Miner = Compare-Object -PassThru @($NewMiners | Select-Object) @($_ | Select-Object) -Property Name, Algorithms -ExcludeDifferent | Select-Object -ExcludeProperty SideIndicator) { 
                            # Update existing miners
                            If ($_.Restart = $_.Arguments -ne $Miner.Arguments) { 
                                $_.Arguments = $Miner.Arguments
                                $_.DeviceNames = $Miner.DeviceNames
                                $_.Devices = [Device[]]($Variables.Devices | Where-Object Name -In $Miner.DeviceNames)
                                $_.Port = $Miner.Port
                                $_.Workers = $Miner.Workers
                            }
                            $_.PrerequisitePath = $Miner.PrerequisitePath
                            $_.PrerequisiteURI = $Miner.PrerequisiteURI
                            If (-not $_.CommandLine -or $_.Restart) { $_.CommandLine = $_.GetCommandLine().Replace("$(Convert-Path '.\')\", '') }
                        }
                    }
                    Else { 
                        $_.Restart = $false
                    }

                    $_.ReadPowerUsage = [Boolean]($_.Devices.ReadPowerUsage -notcontains $false)
                    $_.Refresh($Variables.PowerCostBTCperW, $Variables.CalculatePowerCost) # Needs to be done after ReadPowerUsage evaluation
                    $_.WindowStyle = If ($Config.MinerWindowStyleNormalWhenBenchmarking -and $_.Benchmark) { "normal" } Else { $Config.MinerWindowStyle }
                }

                # Filter miners
                $Miners | Where-Object Disabled -EQ $true | ForEach-Object { $_.Reasons += "Disabled by user" }
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
                            $_.Group | Where-Object Earning -GT $ReasonableEarning | ForEach-Object { $_.Reasons += "Unreal profit data (-gt $($Config.UnrealMinerEarningFactor)x higher than the next best miners available miners of the same device(s))" }
                        }
                    }
                }
                Remove-Variable ReasonableEarning -ErrorAction Ignore

                $Variables.MinersMissingBinary = @()
                $Miners | Where-Object { -not $_.Reasons -and -not (Test-Path -Path $_.Path -Type Leaf) } | ForEach-Object { 
                    $_.Reasons += "Binary missing"
                    $Variables.MinersMissingBinary += $_
                }
                $Variables.MinersMissingPrerequisite = @()
                $Miners | Where-Object { -not $_.Reasons -and $_.PrerequisitePath } | ForEach-Object { 
                    $_.Reasons += "Prerequisite missing ($(Split-Path -Path $_.PrerequisitePath -Leaf))"
                    $Variables.MinersMissingPrerequisite += $_
                }

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
                        Remove-Variable MinersToSuspend, WatchdogMinerCount
                    }
                    $Miners | Where-Object { -not $_.Reasons } | Where-Object { @($Variables.WatchdogTimers | Where-Object MinerName -EQ $_.Name | Where-Object DeviceNames -EQ $_.DeviceNames | Where-Object Algorithm -EQ $_.Algorithm | Where-Object Kicked -LT $Variables.Timer).Count -ge $Variables.WatchdogCount } | ForEach-Object { 
                        $_.Data = @() # Clear data because it may be incorrect caused by miner problem
                        $_.Reasons += "Miner suspended by watchdog (Algorithm $($_.Algorithm))"
                        Write-Message -Level Warn "Miner '$($_.Name) [$($_.Algorithm)]' is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object MinerName -EQ $_.Name | Where-Object DeviceNames -EQ $_.DeviceNames | Where-Object Algorithm -EQ $_.Algorithm | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -Last 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
                    }
                }

                $Miners | Where-Object Reasons | ForEach-Object { $_.Available = $false }

                $Variables.MinersNeedingBenchmark = @($Miners | Where-Object { $_.Available -eq $true -and  $_.Benchmark -eq $true })
                $Variables.MinersNeedingPowerUsageMeasurement = @($Miners | Where-Object { $_.Available -eq $true -and $_.MeasurePowerUsage -eq $true })

                Write-Message -Level Info "Loaded $($Miners.Count) miner$(If ($Miners.Count -ne 1) { "s" }), filtered out $(($Miners | Where-Object Available -NE $true).Count) miner$(If (($Miners | Where-Object Available -NE $true).Count -ne 1) { "s" }). $(($Miners | Where-Object Available -EQ $true).Count) available miner$(If (($Miners | Where-Object Available -EQ $true).Count -ne 1) { "s" }) remain$(If (($Miners | Where-Object Available -EQ $true).Count -eq 1) { "s" })."

                $DownloadList = @($Variables.MinersMissingPrerequisite | Select-Object @{ Name = "URI"; Expression = { $_.PrerequisiteURI } }, @{ Name = "Path"; Expression = { $_.PrerequisitePath } }, @{ Name = "Searchable"; Expression = { $false } }) + @($Variables.MinersMissingBinary | Select-Object URI, Path, @{ Name = "Searchable"; Expression = { $Miner = $_; ($Variables.Miners | Where-Object { (Split-Path $_.Path -Leaf) -eq (Split-Path $Miner.Path -Leaf) }).Count -eq 0 } }) | Select-Object * -Unique
                If ($DownloadList) { 
                    If ($Variables.Downloader.State -ne "Running") { 
                        # Download miner binaries
                        Write-Message -Level Info "Some miners binaries are missing ($($DownloadList.Count) item$(If ($DownloadList.Count -ne 1) { "s" })), starting downloader..."
                        $Downloader_Parameters = @{ 
                            Config = $Config
                            DownloadList = $DownloadList
                            Variables = $Variables
                        }
                        $Variables.Downloader = Start-ThreadJob -ThrottleLimit 99 -Name Downloader -InitializationScript ([scriptblock]::Create("Set-Location '$($Variables.MainPath)'")) -ArgumentList $Downloader_Parameters -FilePath ".\Includes\Downloader.ps1"
                        Remove-Variable Downloader_Parameters
                    }
                    ElseIf (-not ($Miners | Where-Object Available -EQ $true)) { 
                        Write-Message -Level Info "Waiting 30 seconds for downloader to install binaries..."
                    }
                }
                Remove-Variable DownloadList -ErrorAction Ignore

                # Open firewall ports for all miners
                If ($Config.OpenFirewallPorts) { 
                    If (Get-Command "Get-MpPreference") { 
                        $ProgressPreferenceBackup = $ProgressPreference
                        $ProgressPreference = "Ignore"
                        If ((Get-Command "Get-MpComputerStatus") -and (Get-MpComputerStatus)) { 
                            If (Get-Command "Get-NetFirewallRule") { 
                                If ($MinerFirewallRules = @((Get-NetFirewallApplicationFilter).Program)) { 
                                    If (Compare-Object $MinerFirewallRules @($Miners | Select-Object -ExpandProperty Path -Unique) | Where-Object SideIndicator -EQ "=>") { 
                                        Start-Process "pwsh" ("-Command Import-Module NetSecurity; ('$(Compare-Object $MinerFirewallRules @($Miners | Select-Object -ExpandProperty Path -Unique) | Where-Object SideIndicator -EQ '=>' | Select-Object -ExpandProperty InputObject | ConvertTo-Json -Compress)' | ConvertFrom-Json) | ForEach-Object { New-NetFirewallRule -DisplayName (Split-Path `$_ -leaf) -Program `$_ -Description 'Inbound rule added by $($Variables.Branding.ProductLabel) $($Variables.Branding.Version) on $((Get-Date).ToString())' -Group 'Cryptocurrency Miner' }" -replace '"', '\"') -Verb runAs
                                    }
                                }
                                Remove-Variable MinerFirewallRules -ErrorAction Ignore
                            }
                        }
                        $ProgressPreference = $ProgressPreferenceBackup
                        Remove-Variable ProgressPreferenceBackup
                    }
                }
            }
            Else { 
                $Miners | Select-Object | ForEach-Object { $_.Available = $false }
            }
            Remove-Variable AddSeconds, Miner, NewMiners -ErrorAction Ignore

            If ($Miners | Where-Object Available -EQ $true) { 
                Write-Message -Level Info "Selecting best miner$(If (@($Variables.EnabledDevices.Model | Select-Object -Unique).Count -gt 1) { "s" }) based on$(If ($Variables.CalculatePowerCost) { " profit (power cost $($Config.Currency) $($Variables.PowerPricekWh)/kW⋅h)" } Else { " earning" })..."

                If (($Miners | Where-Object Available -EQ $true).Count -eq 1) { 
                    $Variables.MinersBest_Combo = $Variables.MinersBest = $Variables.MostProfitableMiners = $Miners
                }
                Else { 
                    If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { $SortBy = "Profit" } Else { $SortBy = "Earning" }

                    # Add running miner bonus
                    $Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { $_."$($SortBy)_Bias" *= (1 + $Config.MinerSwitchingThreshold / 100) }

                    # Hack: temporarily make all bias positive, BestMiners_Combos(_Comparison) produces wrong sort order when earnings or profits are negative
                    $SmallestBias = [Double][Math]::Abs((($Miners | Where-Object Available -EQ $true | Where-Object { -not [Double]::IsNaN($_."$($SortBy)_Bias") })."$($SortBy)_Bias" | Measure-Object -Minimum).Minimum) * 2
                    $Miners | ForEach-Object { $_."$($SortBy)_Bias" += $SmallestBias }

                    # Get most best miner combination i.e. AMD+NVIDIA+CPU
                    $Variables.MostProfitableMiners = @($Miners | Where-Object Available -EQ $true | Group-Object { [String]$_.DeviceNames }, { [String]$_.Algorithms } | ForEach-Object { $_.Group | Sort-Object -Descending -Property Benchmark, MeasurePowerUsage, KeepRunning, Prioritize, "$($SortBy)_Bias", Activated, @{ Expression = { $_.WarmupTimes[0] }; Descending = $false }, @{ Expression = { $_.Name }; Descending = $false },  @{ Expression = { [String]($_.Algorithms) }; Descending = $false } | Select-Object -First 1 | ForEach-Object { $_.MostProfitable = $true; $_ } })
                    $Variables.MinersBest = @($Variables.MostProfitableMiners | Group-Object { [String]$_.DeviceNames } | ForEach-Object { $_.Group | Sort-Object -Descending -Property Benchmark, MeasurePowerUsage, KeepRunning, Prioritize, "$($SortBy)_Bias", Activated, @{ Expression = { $_.WarmupTimes[0] }; Descending = $false }, @{ Expression = { $_.Name }; Descending = $false },  @{ Expression = { [String]($_.Algorithms) }; Descending = $false } | Select-Object -First 1 })
                    $Variables.Miners_Device_Combos = @(Get-Combination @($Variables.MinersBest | Select-Object DeviceNames -Unique) | Where-Object { (Compare-Object ($_.Combination | Select-Object -ExpandProperty DeviceNames -Unique) ($_.Combination | Select-Object -ExpandProperty DeviceNames) | Measure-Object).Count -eq 0 })

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
                    $Variables.MinersBest_Combo = @(($Variables.MinersBest_Combos | Sort-Object -Descending { @($_.Combination | Where-Object { [Double]::IsNaN($_.$SortBy) }).Count }, { ($_.Combination | Measure-Object "$($SortBy)_Bias" -Sum).Sum }, { ($_.Combination | Where-Object { $_.$Sortby -ne 0 } | Measure-Object).Count } | Select-Object -First 1).Combination)
                    Remove-Variable Miner_Device_Combo, Miner_Device_Count, Miner_Device_Regex

                    # Hack part 2: reverse temporarily forced positive bias
                    $Miners | ForEach-Object { $_."$($SortBy)_Bias" -= $SmallestBias }

                    # Don't penalize active miners, revert running miner bonus
                    $Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { $_."$($SortBy)_Bias" /= (1 + $Config.MinerSwitchingThreshold / 100) }

                    Remove-Variable SmallestBias, SortBy
                }

                $Variables.MiningEarning = [Double]($Variables.MinersBest_Combo | Measure-Object Earning -Sum).Sum
                $Variables.MiningProfit = [Double]($Variables.MinersBest_Combo | Measure-Object Profit -Sum).Sum
                $Variables.MiningPowerCost = [Double]($Variables.MinersBest_Combo | Measure-Object PowerCost -Sum).Sum
                $Variables.MiningPowerUsage = [Double]($Variables.MinersBest_Combo | Measure-Object PowerUsage -Sum).Sum

                # ProfitabilityThreshold check - OK to run miners?
                If (-not $Variables.Rates -or -not $Variables.Rates.BTC.($Config.Currency) -or [Double]::IsNaN($Variables.MiningEarning) -or [Double]::IsNaN($Variables.MiningProfit) -or [Double]::IsNaN($Variables.MiningPowerCost) -or ($Variables.MiningEarning - $Variables.MiningPowerCost - $Variables.BasePowerCostBTC) -ge ($Config.ProfitabilityThreshold / $Variables.Rates.BTC.($Config.Currency)) -or $Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerUsageMeasurement) { 
                    $Variables.MinersBest_Combo | Select-Object | ForEach-Object { $_.Best = $true }
                }
                Else { 
                    Write-Message -Level Warn ("Mining profit ({0} {1:n$($Config.DecimalsMax)}) is below the configured threshold of {0} {2:n$($Config.DecimalsMax)}/day; mining is suspended until threshold is reached." -f $Config.Currency, (($Variables.MiningEarning - $Variables.MiningPowerCost - $Variables.BasePowerCostBTC) * $Variables.Rates."BTC".($Config.Currency)), $Config.ProfitabilityThreshold)
                }
            }
            Else { 
                $Variables.MostProfitableMiners = @()
                $Variables.MinersBest = @()
                $Variables.Miners_Device_Combos = @()
                $Variables.MinersBest_Combos = @()
                $Variables.MinersBest_Combo = @()

                $Variables.MiningEarning = $Variables.MiningProfit = $Variables.MiningPowerCost = $Variables.MiningPowerUsage = [Double]0
            }

            If ($Variables.Rates."BTC") { 
                If ($Variables.MinersNeedingBenchmark.Count) { 
                    $Variables.Summary = "Earning / day: n/a (Benchmarking: $($Variables.MinersNeedingBenchmark.Count) $(If ($Variables.MinersNeedingBenchmark.Count -eq 1) { "miner" } Else { "miners" }) left$(If (($Variables.EnabledDevices | Sort-Object -Property { $_.DeviceNames -join ', ' }).Count -gt 1) { " [$(($Variables.MinersNeedingBenchmark | Group-Object -Property { $_.DeviceNames -join ',' } | Sort-Object Name | ForEach-Object { "$($_.Name): $($_.Count)" }) -join '; ')]"}))"
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
                        $Variables.Summary += "Profit / day: n/a (Measuring power usage: $($Variables.MinersNeedingPowerUsageMeasurement.Count) $(If (($Variables.MinersNeedingPowerUsageMeasurement).Count -eq 1) { "miner" } Else { "miners" }) left$(If (($Variables.EnabledDevices | Sort-Object -Property { $_.DeviceNames -join ',' }).Count -gt 1) { " [$(($Variables.MinersNeedingPowerUsageMeasurement | Group-Object -Property { $_.DeviceNames -join ',' } | Sort-Object Name | ForEach-Object { "$($_.Name): $($_.Count)" }) -join '; ')]"}))"
                    }
                    ElseIf ($Variables.MiningPowerUsage -gt 0) { 
                        $Variables.Summary += "Profit / day: {0:n} {1}" -f (($Variables.MiningProfit - $Variables.BasePowerCostBTC) * $Variables.Rates."BTC".($Config.Currency)), $Config.Currency
                    }
                    Else { 
                        $Variables.Summary += "Profit / day: n/a (no power data)"
                    }

                    If ($Variables.BasePowerCostBTC -gt 0) { 
                        If ($Variables.Summary -ne "") { $Variables.Summary += "&ensp;&ensp;&ensp;" }

                        If ([Double]::IsNaN($Variables.MiningEarning) -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                            $Variables.Summary += "Power Cost / day: n/a&ensp;[Miner$(If ($Variables.MinersBest_Combo.Count -gt 1) { "s" }): n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Config.Currency, ($Variables.BasePowerCostBTC * $Variables.Rates."BTC".($Config.Currency)), $Config.PowerUsageIdleSystemW
                        }
                        ElseIf ($Variables.MiningPowerUsage -gt 0) { 
                            $Variables.Summary += "Power Cost / day: {1:n} {0}&ensp;[Miner$(If ($Variables.MinersBest_Combo.Count -gt 1) { "s" }): {2:n} {0} ({3:n2} W); Base: {4:n} {0} ({5:n2} W)]" -f $Config.Currency, (($Variables.MiningPowerCost + $Variables.BasePowerCostBTC) * $Variables.Rates."BTC".($Config.Currency)), ($Variables.MiningPowerCost * $Variables.Rates."BTC".($Config.Currency)), $Variables.MiningPowerUsage, ($Variables.BasePowerCostBTC * $Variables.Rates."BTC".($Config.Currency)), $Config.PowerUsageIdleSystemW
                        }
                        Else { 
                            $Variables.Summary += "Power Cost / day: n/a&ensp;[Miner: n/a; Base: {1:n} {0} ({2:n2} W)]" -f $Config.Currency, ($Variables.BasePowerCostBTC * $Variables.Rates.BTC.($Config.Currency)), $Config.PowerUsageIdleSystemW
                        }
                    }
                }
                If ($Variables.Summary -ne "") { $Variables.Summary += "<br>" }

                # Add currency conversion rates
                @(@(If ($Config.UsemBTC -eq $true) { "mBTC" } Else { "BTC" }) + @($Config.ExtraCurrencies)) | Select-Object -Unique | Where-Object { $Variables.Rates.$_.($Config.Currency) } | ForEach-Object { 
                    $Variables.Summary += "1 $_ = {0:N$(Get-DecimalsFromValue -Value $Variables.Rates.$_.($Config.Currency) -DecimalsMax $Config.DecimalsMax)} $($Config.Currency)&ensp;&ensp;&ensp;" -f $Variables.Rates.$_.($Config.Currency)
                }
            }
            Else { 
                $Variables.Summary = "Error:<br>Could not get BTC exchange rate from min-api.cryptocompare.com"
            }
        }

        # Stop running miners
        If (-not ($Variables.EnabledDevices -and $Variables.PoolsBest)) { 
            $Miners | Select-Object | ForEach-Object { $_.Best = $false }
        }
        ForEach ($Miner in @(@($Miners | Where-Object Info) + @($CompareMiners | Where-Object { $_.Info -and $_.SideIndicator -eq "<=" } <# miner object is gone #>))) { 
            If ($Miner.Status -eq [MinerStatus]::Failed) { 
                If ($Miner.ProcessID) {  # Stop miner (may be set as failed in miner.refresh() because of 0 hashrate)
                    $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' exited unexpectedly."
                    $Miner.SetStatus([MinerStatus]::Failed)
                }
                $Miner.Info = ""
                $Miner.WorkersRunning = @()
            }
            ElseIf ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
                $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' exited unexpectedly."
                $Miner.SetStatus([MinerStatus]::Failed)
                $Miner.Info = ""
                $Miner.WorkersRunning = @()
            }
            ElseIf ($Miner.Best -ne $true -or $Miner.Restart -eq $true -or $Miner.SideIndicator -eq "<=" -or $Variables.NewMiningStatus -ne "Running") { 
                ForEach ($Worker in $Miner.WorkersRunning) { 
                    If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -EQ $Miner.Name | Where-Object PoolName -EQ $Worker.Pool.Name | Where-Object PoolRegion -EQ $Worker.Pool.Region | Where-Object Algorithm -EQ $Worker.Pool.Algorithm | Where-Object DeviceNames -EQ $Miner.DeviceNames)) { 
                        # Remove Watchdog timers
                        $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })
                    }
                }
                $Miner.SetStatus([MinerStatus]::Idle)
                $Miner.Info = ""
                $Miner.WorkersRunning = @()
            }
        }
        Remove-Variable CompareMiners, Miner, WatchdogTimers -ErrorAction Ignore

        $Miners | Select-Object | ForEach-Object { $_.PSObject.Properties.Remove('SideIndicator') }

        # Kill stuck miners
        $Loops = 0
        While ($StuckMinerProcessIDs = @((Get-CimInstance CIM_Process | Where-Object ExecutablePath | Where-Object { @($Miners.Path | Sort-Object -Unique) -contains $_.ExecutablePath } | Where-Object { $Miners.ProcessID -notcontains $_.ProcessID }).ProcessID)) { 
            $StuckMinerProcessIDs | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction Ignore }
            Start-Sleep -MilliSeconds 500
            $Loops ++
            If ($Loops -gt 100) { 
                $Message = "Error stopping miner."
                If ($Config.AutoReboot) { 
                    Write-Message -Level Error "$Message Restarting computer in 30 seconds..."
                    shutdown.exe /r /t 30 /c "$($Variables.Branding.ProductLabel) detected stuck miner$(If ($StuckMinerProcessIDs.Count -gt 1) { "s" }) and will reboot the computer in 30 seconds."
                }
                Else { 
                    Write-Message -Level Error $Message
                    Start-Sleep -Seconds 30
                }
            }
        }
        Remove-Variable Loops, Message, StuckMinerProcessIDs

        If ($Variables.EnabledDevices -and ($Miners | Where-Object Available -EQ $true)) {
            # Update data in API
            $Variables.Miners = $Miners
        }
        Else { 
            $Variables.Miners = [Miner[]]@()
            If (-not $Variables.EnabledDevices) { 
                Write-Message -Level Warn "No enabled devices - retrying in 10 seconds..."
                Start-Sleep -Seconds 10
                Write-Message -Level Info "Ending cycle (No enabled devices)."
            }
            ElseIf (-not $PoolNames) { 
                Write-Message -Level Warn "No configured pools - retrying in 10 seconds..."
                Start-Sleep -Seconds 10
                Write-Message -Level Info "Ending cycle (No configured pools)."
            }
            ElseIf (-not $Variables.PoolsBest) { 
                Write-Message -Level Warn "No available pools - retrying in 10 seconds..."
                Start-Sleep -Seconds 10
                Write-Message -Level Info "Ending cycle (No available pools)."
            }
            Else { 
                Write-Message -Level Warn "No miners available - retrying in 10 seconds..."
                Start-Sleep -Seconds 10
                Write-Message -Level Info "Ending cycle (No miners available)."
            }
            Continue
        }

        Remove-Variable Miners, WatchdogTimer -ErrorAction Ignore

        # Faster shutdown
        If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

        # Optional delay to avoid blue screens
        Start-Sleep -Seconds $Config.Delay

        ForEach ($Miner in ($Variables.Miners | Where-Object Best -EQ $true)) { 

            If ($Miner.Benchmark -eq $true -or $Miner.MeasurePowerUsage -eq $true) { 
                $DataCollectInterval = 1
                $Miner.Data = @()
                $Miner.Hashrates_Live = @()
                $Miner.Earning = [Double]::NaN
                $Miner.Earning_Bias = [Double]::NaN
                If ($Miner.MeasurePowerUsage -eq $true) {
                    $Miner.Profit = [Double]::NaN
                    $Miner.Profit_Bias = [Double]::NaN
                    $Miner.PowerUsage = [Double]::NaN
                    $Miner.PowerUsage_Live = [Double]::NaN
                }
            }
            Else { 
                $DataCollectInterval = 5
            }

            If ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
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
                If ($Miner.Workers.Pool.DAGsizeGB -and ($Variables.Miners | Where-Object Best -EQ $true).Devices.Type -contains "CPU") { $Miner.WarmupTimes[0] += 15 <# seconds #>}

                $Miner.DataCollectInterval = $DataCollectInterval
                $Miner.SetStatus([MinerStatus]::Running)

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
                    Remove-Variable Worker
                }
            }
            ElseIf ($Miner.DataCollectInterval -ne $DataCollectInterval) {
                $Miner.DataCollectInterval = $DataCollectInterval
                $Miner.RestartDataReader()
            }

            If ($Miner.Activated -le 0) { $Miner.Activated = 1 } # Stat just got removed (Miner.Activated < 1, set by API)

            $Message = ""
            If ($Miner.Benchmark -eq $true) { $Message = "Benchmark " }
            If ($Miner.Benchmark -eq $true -and $Miner.MeasurePowerUsage -eq $true) { $Message = "$($Message)and " }
            If ($Miner.MeasurePowerUsage -eq $true) { $Message = "$($Message)Power usage measurement " }
            If ($Message) { Write-Message -Level Verbose "$($Message)for miner '$($Miner.Name) $($Miner.Info)' in progress [Attempt $($Miner.Activated) of $($Variables.WatchdogCount + 1); min. $($Miner.MinDataSamples) Samples]..." }
        }
        Remove-Variable AlgorithmPrerunName, DefaultPrerunName, Message, Miner, MinerAlgorithmPrerunName, WatchdogTimers

        $Variables.Miners | Where-Object Available -EQ $true | Group-Object { $_.DeviceNames -join ',' } | ForEach-Object { 
            $MinersDeviceGroup = $_.Group
            $MinersDeviceGroupNeedingBenchmark = $MinersDeviceGroup | Where-Object Benchmark -EQ $true
            $MinersDeviceGroupNeedingPowerUsageMeasurement = $MinersDeviceGroup | Where-Object MeasurePowerUsage -EQ $true

            # Display benchmarking progress
            If ($MinersDeviceGroupNeedingBenchmark) { 
                Write-Message -Level Verbose "Benchmarking for device$(If (($MinersDeviceGroupNeedingBenchmark.DeviceNames | Select-Object -Unique).Count -gt 1) { " group" }) '$(($MinersDeviceGroupNeedingBenchmark.DeviceNames | Sort-Object -Unique) -join '; ')' in progress: $($MinersDeviceGroupNeedingBenchmark.Count) miner$(If ($MinersDeviceGroupNeedingBenchmark.Count -gt 1) { 's' }) left to complete benchmark."
            }
            # Display power usage measurement progress
            If ($MinersDeviceGroupNeedingPowerUsageMeasurement) { 
                Write-Message -Level Verbose "Power usage measurement for device$(If (($MinersDeviceGroupNeedingPowerUsageMeasurement.DeviceNames | Select-Object -Unique).Count -gt 1) { " group" }) '$(($MinersDeviceGroupNeedingPowerUsageMeasurement.DeviceNames | Sort-Object -Unique) -join '; ')' in progress: $($MinersDeviceGroupNeedingPowerUsageMeasurement.Count) miner$(If ($MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 1) { 's' }) left to complete measuring."
            }
        }
        Remove-Variable MinersDeviceGroup, MinersDeviceGroupNeedingBenchmark, MinersDeviceGroupNeedingPowerUsageMeasurement

        Get-Job -State "Completed" -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore
        Get-Job -State "Stopped" -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore

        $Variables.RunningMiners = @($Variables.Miners | Where-Object Best | Sort-Object -Descending Benchmark, MeasurePowerUsage)
        $Variables.FailedMiners = @()

        If ($Variables.RunningMiners) { 
            $Variables.RefreshNeeded = $true
        }

        If ($Variables.RunningMiners -and (Get-Date).ToUniversalTime() -le $Variables.EndCycleTime) { 
            Write-Message -Level Info "Collecting miner data while waiting for next cycle..."
            $Variables.StatusText = "Waiting $($Variables.TimeToSleep) seconds... | Next refresh: $((Get-Date).AddSeconds($Variables.TimeToSleep).ToString('g'))"
            $Variables.EndCycleMessage = ""

            While ($Variables.NewMiningStatus -eq "Running" -and $Variables.IdleRunspace.MiningStatus -ne "Idle" -and ((Get-Date).ToUniversalTime() -le $Variables.EndCycleTime -or $Variables.BenchmarkingOrMeasuringMiners) -and -not $Variables.EndCycleMessage) { 
                # Exit loop when
                # - a miner crashed (and no other miners are benchmarking or measuring power usage)
                # - all benchmarking miners have collected enough samples
                # - WarmupTimes[0] is reached (no readout from miner)

                Start-Sleep -Milliseconds 250

                ForEach ($Miner in $Variables.RunningMiners) { 
                    Try { 
                        # Set window title
                        $WindowTitle = "$($Miner.Devices.Name -join ","): $($Miner.Name) $($Miner.Info)"
                        If ($Miner.Benchmark -eq $true -or $Miner.MeasurePowerUsage -eq $true) { 
                            $WindowTitle += " ("
                            If ($Miner.Benchmark -eq $true -and $Miner.MeasurePowerUsage -eq $false) { $WindowTitle += "Benchmarking" }
                            ElseIf ($Miner.Benchmark -eq $true -and $Miner.MeasurePowerUsage -eq $true) { $WindowTitle += "Benchmarking and measuring power usage" }
                            ElseIf ($Miner.Benchmark -eq $false -and $Miner.MeasurePowerUsage -eq $true) { $WindowTitle += "Measuring power usage" }
                            $WindowTitle += ")"
                        }
                        [Void][Win32]::SetWindowText((Get-Process -Id $Miner.ProcessId).mainWindowHandle, $WindowTitle)
                    } Catch {}

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
                    ElseIf ($Miner.DataReaderJob.HasMoreData) { 
                        # Set miner priority, some miners reset priority on their own
                        If ($Process = Get-Process | Where-Object Id -EQ $Miner.ProcessId) { $Process.PriorityClass = $Global:PriorityNames.($Miner.ProcessPriority) }

                        $Miner.Data += $Samples = @($Miner.DataReaderJob | Receive-Job | Select-Object)
                        $Sample = $Samples | Select-Object -Last 1

                        If ((Get-Date) -gt $Miner.Process.PSBeginTime.AddSeconds($Miner.WarmupTimes[0])) { 
                            # We must have data samples by now
                            If (($Miner.Data | Select-Object -Last 1).Date -lt $Miner.BeginTime) { 
                                # Miner has not provided first sample on time
                                $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' has not provided first data sample in $($Miner.WarmupTimes[0]) seconds."
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.FailedMiners += $Miner
                                Break
                            }
                            ElseIf (($Miner.Data | Select-Object -Last 1).Date.AddSeconds((($Miner.DataCollectInterval * 3.5), 10 | Measure-Object -Maximum).Maximum) -lt (Get-Date).ToUniversalTime()) { 
                                # Miner stuck - no sample received in last few data collect intervals
                                $Miner.StatusMessage = "Miner '$($Miner.Name) $($Miner.Info)' has not updated data for more than $((($Miner.DataCollectInterval * 3.5), 10 | Measure-Object -Maximum).Maximum) seconds."
                                $Miner.SetStatus([MinerStatus]::Failed)
                                $Variables.FailedMiners += $Miner
                                Break
                            }
                        }

                        If ($Sample.Hashrate) { 
                            $Miner.Hashrates_Live = $Sample.Hashrate.PSObject.Properties.Value
                            If (-not ($Miner.Data | Where-Object Date -GT $Miner.BeginTime.AddSeconds($Miner.WarmupTimes[1]))) { 
                                Write-Message -Level Verbose "$($Miner.Name) data sample discarded [$(($Miner.WorkersRunning.Pool.Algorithm | ForEach-Object { "$($_): $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.BadShareRatioThreshold) { " / Shares Total: $($Sample.Shares.$_[2]), Rejected: $($Sample.Shares.$_[1])" })" }) -join ' & ')$(If ($Sample.PowerUsage) { " / Power usage: $($Sample.PowerUsage.ToString("N2"))W" })] (miner is warming up)."
                                $Miner.Data = @($Miner.Data | Where-Object Date -LT $Miner.BeginTime)
                            }
                            Else { 
                                If ($Miner.StatusMessage -notlike "Mining *") { 
                                    $Miner.StatusMessage = "$(If ($Miner.Benchmark -eq $true -or $Miner.MeasurePowerUsage -eq $true) { "$($(If ($Miner.Benchmark -eq $true) { "Benchmarking" }), $(If ($Miner.Benchmark -eq $true -and $Miner.MeasurePowerUsage -eq $true) { "and" }), $(If ($Miner.MeasurePowerUsage -eq $true) { "Power usage measuring" }) -join ' ')" } Else { "Mining" }) {$(($Miner.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"
                                    $Miner.Devices | ForEach-Object { $_.Status = $Miner.StatusMessage }
                                }
                                Write-Message -Level Verbose "$($Miner.Name) data sample retrieved [$(($Miner.WorkersRunning.Pool.Algorithm | ForEach-Object { "$($_): $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.BadShareRatioThreshold) { " / Shares Total: $($Sample.Shares.$_[2]), Rejected: $($Sample.Shares.$_[1])" })" }) -join ' & ')$(If ($Sample.PowerUsage) { " / Power usage: $($Sample.PowerUsage.ToString("N2"))W" })] ($($Miner.Data.Count) sample$(If ($Miner.Data.Count -ne 1) { "s" }))."
                            }
                        }
                    }
                }
                $Variables.RunningMiners = @($Variables.RunningMiners | Where-Object { $_-notin $Variables.FailedMiners })
                $Variables.BenchmarkingOrMeasuringMiners = @($Variables.RunningMiners | Where-Object { $_.Benchmark -eq $true -or $_.MeasurePowerUsage -eq $true })

                If ($Variables.FailedMiners -and -not $Variables.BenchmarkingOrMeasuringMiners) { 
                    # A miner crashed and we're not benchmarking, end the loop now
                    $Variables.EndCycleMessage = " prematurely (Miner failed)"
                }
                ElseIf ($Variables.BenchmarkingOrMeasuringMiners -and (-not ($Variables.BenchmarkingOrMeasuringMiners | Where-Object { $_.Data.Count -lt (($Config.MinDataSamples, ($Variables.BenchmarkingOrMeasuringMiners.MinDataSamples | Measure-Object -Minimum).Minimum) | Measure-Object -Maximum).Maximum }))) { 
                    # Enough samples collected for this loop, exit loop immediately
                    $Variables.EndCycleMessage = " prematurely (All$(If ($Variables.BenchmarkingOrMeasuringMiners | Where-Object Benchmark -EQ $true) { " benchmarking" })$(If ($Variables.BenchmarkingOrMeasuringMiners | Where-Object { $_.Benchmark -eq $true -and $_.MeasurePowerUsage -eq $true }) { " and" })$(If ($Variables.BenchmarkingOrMeasuringMiners | Where-Object MeasurePowerUsage -EQ $true) { " power usage measuring" }) miners have collected enough samples for this cycle)"
                }
                ElseIf (-not $Variables.RunningMiners) { 
                    # No more running miners, end the loop now
                    $Variables.EndCycleMessage = " prematurely (No more running miners)"
                }
            }

            If (-not $Variables.EndCycleMessage -and $Variables.IdleRunspace.MiningStatus -eq "Idle") { $Variables.EndCycleMessage = " (System activity detected)" }
        }

        Write-Message -Level Info "Ending cycle$($Variables.EndCycleMessage)."

        Remove-Variable BenchmarkingOrMeasuringMiners, EndCycleMessage, FailedMiners, Interval, Message, Miner, Miners, NextLoop, PoolNames, Process, RunningMiners, Sample, Samples, Worker, WindowTitle -ErrorAction Ignore

        [System.GC]::Collect()
    }
    Catch { 
        ($_.Exception | Format-List -Force) >> "Logs\Error.txt"
        ($_.InvocationInfo | Format-List -Force) >> "Logs\Error.txt"
        Write-Message -Level Error "Error in core detected. Respawning core..."
        $Variables.MiningStatus = $null
        $Variables.RestartCycle = $true
    }

} While ($Variables.NewMiningStatus -eq "Running")

#Stop all running miners
$Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { 
    $_.SetStatus([MinerStatus]::Idle)
    $_.Info = ""
    $_.WorkersRunning = @()
}

[System.GC]::Collect()
