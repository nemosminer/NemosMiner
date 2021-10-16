<#
Copyright (c) 2018-2021 Nemo, MrPlus & UselessGuru


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
Version:        4.0.0.5 (RC5)
Version date:   16 October 2021
#>

using module .\Include.psm1

Function Start-Cycle { 
    $Variables.LogFile = "$($Variables.MainPath)\Logs\NemosMiner_$(Get-Date -Format "yyyy-MM-dd").log"

    # Always get the latest config
    Read-Config -ConfigFile $Variables.ConfigFile
    # Prepare devices
    $EnabledDevices = $Variables.Devices | Where-Object { $_.State -EQ [DeviceState]::Enabled } | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    # For GPUs set type AMD or NVIDIA
    $EnabledDevices | Where-Object Type -EQ "GPU" | ForEach-Object { $_.Type = $_.Vendor }
    If (-not $Config.MinerInstancePerDeviceModel) { $EnabledDevices | ForEach-Object { $_.Model = $_.Vendor } } # Remove Model information from devices -> will create only one miner instance

    #Much faster
    $Pools = [Pool[]]$Variables.Pools

    # Skip stuff if previous cycle was shorter than half of what it should
    If (-not $Variables.Timer -or $Variables.Timer.AddSeconds([Int]($Config.Interval / 2)) -lt (Get-Date).ToUniversalTime()) { 

        Write-Message "Started new cycle."

        # Set master timer
        $Variables.Timer = (Get-Date).ToUniversalTime()

        $Variables.CycleStarts += $Variables.Timer
        $Variables.CycleStarts = @($Variables.CycleStarts | Select-Object -Last (3, ($Config.SyncWindow + 1) | Measure-Object -Maximum).Maximum)
        $Variables.SyncWindowDuration = (($Variables.CycleStarts | Select-Object -Last 1) - ($Variables.CycleStarts | Select-Object -Index 0))

        $Variables.EndLoopTime = (Get-Date).AddSeconds($Config.Interval)

        # Set minimum Watchdog minimum count 3
        $Variables.WatchdogCount = (3, $Config.WatchdogCount | Measure-Object -Maximum).Maximum
        $Variables.WatchdogReset = $Variables.WatchdogCount * ($Variables.WatchdogCount + 1) * $Config.Interval

        # Expire watchdog timers
        $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $Config.WatchDog } | Where-Object Kicked -GE $Variables.Timer.AddSeconds(-$Variables.WatchdogReset))

        If (-not $Variables.DAGdata) { $Variables.DAGdata = [PSCustomObject][Ordered]@{ } }
        If (-not $Variables.DAGdata.Currency) { $Variables.DAGdata | Add-Member Currency ([Ordered]@{ }) -Force }

        # Do do once every 24hrs or if unable to get data from all sources
        If ($Variables.DAGdata.Updated_Minerstat -lt (Get-Date).AddDays(-1)) { 
            Try { 
                $Page = Invoke-WebRequest -Uri "https://minerstat.com/dag-size-calculator" -TimeoutSec 5 # PWSH 6+ no longer supports basic parsing -> parse text
                $Page.Content -split '\n' -replace '"', "'" | Where-Object { $_ -like "<div class='block' title='Current block height of *" } | ForEach-Object { 

                    $BlockHeight, $Currency, $DAGsize, $Epoch = $null

                    $Currency = $_ -replace "^<div class='block' title='Current block height of " -replace "'>.*$"
                    $BlockHeight = [Int]($_ -replace "^<div class='block' title='Current block height of $Currency'>" -replace "</div>")
                    $DAGsize = [Int64](Get-DAGsize $BlockHeight $Currency)
                    # Epoch for EtcHash is twice as long
                    If ($Currency -eq "ETC") { 
                        $Epoch = [Math]::Floor($BlockHeight / 60000)
                    }
                    Else { 
                        $Epoch = [Math]::Floor($BlockHeight / 30000)
                    }

                    If ($BlockHeight -and $Currency -and $DAGsize -and $Epoch) { 
                        $Data = [PSCustomObject]@{ 
                            BlockHeight = $BlockHeight
                            DAGsize     = $DAGsize
                            Epoch       = $Epoch
                        }
                        $Variables.DAGdata.Currency.Remove($Currency)
                        $Variables.DAGdata.Currency.Add($Currency, $Data)
                    }
                }
                $Variables.DAGdata | Add-Member Updated_Minerstat (Get-Date).ToUniversalTime() -Force
                Write-Message -Level Info "Loaded DAG block data from 'https://minerstat.com'."
            }
            Catch { 
                Write-Message -Level Warn "Cannot load DAG block data from 'https://minerstat.com'."
            }
        }

        If ($Variables.DAGdata.Updated_RavenCoin -lt (Get-Date).AddDays(-1)) {
            Try { 
                # Get RVN block data
                $Request = "https://api.ravencoin.org/api/status"

                If ($BlockHeight = (Invoke-RestMethod -Uri $Request -TimeoutSec 5).Info.blocks) { 
                    $Data = [PSCustomObject][Ordered]@{ 
                        BlockHeight = [Int]($BlockHeight)
                        DAGsize     = [Int64](Get-DAGSize -Block $BlockHeight -Coin "RVN")
                        Epoch       = [Int]([Math]::Floor($BlockHeight / 7500))
                    }
                    $Variables.DAGdata.Currency.Remove("RVN")
                    $Variables.DAGdata.Currency.Add("RVN", $Data)
                    $Variables.DAGdata | Add-Member Updated_Ravencoin (Get-Date).ToUniversalTime() -Force
                    Write-Message -Level Info "Loaded RVN DAG block data from 'https://api.ravencoin.org'."
                }
            }
            Catch { 
                Write-Message -Level Warn "Cannot load RVN DAG block data from 'https://api.ravencoin.org'."
            }
        }

        # Add default '*' (equal to highest)
        If ($Variables.DAGdata.Currency.Count -gt 1) { 
            $Data = [PSCustomObject][Ordered]@{ 
                BlockHeight = [Int]($Variables.DAGdata.Currency.Keys | ForEach-Object { $Variables.DAGdata.Currency.$_.BlockHeight } | Measure-Object -Maximum).Maximum
                DAGsize     = [Int64]($Variables.DAGdata.Currency.Keys | ForEach-Object { $Variables.DAGdata.Currency.$_.DAGsize } | Measure-Object -Maximum).Maximum
                Epoch       = [Int]($Variables.DAGdata.Currency.Keys | ForEach-Object { $Variables.DAGdata.Currency.$_.Epoch } | Measure-Object -Maximum).Maximum
            }
            $Variables.DAGdata.Currency.Remove("*")
            $Variables.DAGdata.Currency.Add("*", $Data)
            $Variables.DAGdata | ConvertTo-Json -ErrorAction Ignore | Out-File ".\Data\DagData.json" -Encoding UTF8 -Force
        }
        ElseIf ((Get-ChildItem -Path ".\Data\DagData.json" -ErrorAction Ignore).LastWriteTime.AddDays(1) -gt (Get-Date)) { 
            # Read from file
            $Variables.DAGdata = Get-Content ".\Data\DagData.json" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore
            If ($Variables.DAGdata) { Write-Message -Level Verbose "Loaded DAG block data from cached file '.\Data\DagData.json'." }
        }

        If (-not $Variables.DAGdata.Currency."*") {
            If (-not $Variables.DAGdata.Currency) { 
                $Variables.DAGdata = [PSCustomObject][Ordered]@{ }
                $Variables.DAGdata | Add-Member Currency ([Ordered]@{ })
            }

            $BlockHeight = ((Get-Date) - [DateTime]"07/31/2015").Days * 6400
            Write-Message -Level Warn "Cannot load ethash DAG size information from 'https://minerstat.com', calculated block height $BlockHeight based on 6400 blocks per day since 30 July 2015."
            $Data = [PSCustomObject]@{ 
                BlockHeight = [Int]$BlockHeight
                DAGsize     = [Int64](Get-DAGSize $BlockHeight)
                Epoch       = [Int][Math]::Floor($BlockHeight / 30000)
            }
            $Variables.DAGdata.Currency.Add("*", $Data)
        }
        Remove-Variable BlockHeight, Data, DAGSize, Epoch, DAGdata, Page, Table -ErrorAction Ignore

        # Use non-donate pool config
        $PoolNames = $Config.PoolName
        $PoolsConfig = $Config.PoolsConfig

        If ($Config.Donate -gt 0) { 
            # Re-Randomize donation start once per day, do not donate if remaing time for today is less than donation duration
            If (($Variables.DonateStart).Date -ne (Get-Date).Date -and (Get-Date).AddMinutes($Config.Donate).Date -eq (Get-Date).Date) { 
                $Variables.DonateStart = (Get-Date).AddMinutes((Get-Random -Minimum $Config.Donate -Maximum (1440 - $Config.Donate - (Get-Date).TimeOfDay.TotalMinutes)))
                $Variables.DonateEnd = $null
            }

            If ((Get-Date) -ge $Variables.DonateStart -and $null -eq $Variables.DonateEnd) { 
                # We get here only once per day, ensure full donation period
                $Variables.DonateStart = (Get-Date)
                $Variables.DonateEnd = $Variables.DonateStart.AddMinutes($Config.Donate)
                $Variables.DonateRandom = $Variables.DonationData | Get-Random
                $Variables.DonatePoolNames = @((Get-ChildItem .\Pools\*.ps1 -File).BaseName -replace "24hr$|Coins$|Plus$|CoinsPlus$" | Sort-Object -Unique)

                # Add pool config to config (in-memory only)
                $Variables.DonatePoolsConfig = [Ordered]@{ }
                $Variables.DonatePoolNames | ForEach-Object { 
                    $PoolConfig = [PSCustomObject]@{ }
                    $PoolConfig | Add-Member EarningsAdjustmentFactor 1
                    $PoolConfig | Add-Member WorkerName "NemosMiner-$($Variables.CurrentVersion.ToString())-donate$($Config.Donate)" -Force
                    Switch ($_) { 
                        "MiningPoolHub" { 
                            $PoolConfig | Add-Member UserName $Variables.DonateRandom.MiningPoolHubUserName
                        }
                        "ProHashing" { 
                            If ($Variables.DonateRandom.ProHashingUserName) { $PoolConfig | Add-Member UserName $Variables.DonateRandom.ProHashingUserName } # not all devs have a known ProHashing account
                        }
                        Default { 
                            $PoolConfig | Add-Member Wallets $Variables.DonateRandom.Wallets
                        }
                    }
                    If ($PoolConfig.Username -or $PoolConfig.Wallets) { $Variables.DonatePoolsConfig.$_ = $PoolConfig }
                }

                # Clear all pools
                $Variables.Pools = [Pool[]]@()
            }

            If ($Variables.DonateRandom) { 
                If ((Get-Date) -ge $Variables.DonateStart -and (Get-Date) -lt $Variables.DonateEnd) { 
                    # Ensure full donation period
                    $Variables.EndLoopTime = $Variables.DonateEnd
                    # Activate donation
                    $PoolNames = $Variables.DonatePoolNames
                    $PoolsConfig = $Variables.DonatePoolsConfig
                    Write-Message "Donation run: Mining for '$($Variables.DonateRandom.Name)' for the next $(If (($Config.Donate - ((Get-Date) - $Variables.DonateStart).Minutes) -gt 1) { "$($Config.Donate - ((Get-Date) - $Variables.DonateStart).Minutes) minutes" } Else { "minute" }). NemosMiner will use all pools while donating."
                }
                ElseIf ((Get-Date) -gt $Variables.DonateEnd) { 
                    $Variables.DonatePoolNames = $null
                    $Variables.DonatePoolsConfig = $null
                    $Variables.DonateRandom = $null
                    Write-Message "Donation run complete - thank you! Mining for you. :-)"

                    # Clear all pools
                    $Variables.Pools = [Pool[]]@()
                }
            }
        }

        # Stop BrainJobs for deconfigured pools
        Stop-BrainJob @($Variables.BrainJobs.Keys | Where-Object { $_ -notin ($PoolNames -replace "24hr$|Coins$|Coins24hr$|CoinsPlus$|Plus$")})

        # Faster shutdown
        If ($Variables.NewMiningStatus -ne "Running") { Return }

        # Start Brain jobs (will pick up all newly added pools)
        Start-BrainJob

        # Load currency exchange rates from min-api.cryptocompare.com
        $Variables.BalancesCurrencies = @($Variables.Balances.Keys | ForEach-Object { $Variables.Balances.$_.Currency } | Sort-Object -Unique)
        $Variables.AllCurrencies = @((@($Config.Currency) + @($Config.ExtraCurrencies) + @($Variables.BalancesCurrencies)) | Select-Object -Unique)
        If (-not $Variables.Rates.BTC.($Config.Currency) -or $Config.BalancesTrackerPollInterval -lt 1) { 
            Get-Rate
        }

        # Power cost preparations
        $Variables.CalculatePowerCost = $Config.CalculatePowerCost # $Variables.CalculatePowerCost is an operational variable and not identical to $Config.CalculatePowerCost
        If ($Config.CalculatePowerCost -eq $true) { 
            If ($EnabledDevices.Count -ge 1) { 
                # HWiNFO64 verification
                $RegKey = "HKCU:\Software\HWiNFO64\VSB"
                If ($RegistryValue = Get-ItemProperty -Path $RegKey -ErrorAction SilentlyContinue) { 
                    If ([String]$Variables.HWInfo64RegistryValue -eq [String]$RegistryValue) { 
                        Write-Message -Level Warn "Power usage info in registry has not been updated [HWiNFO64 not running???] - disabling power usage calculations."
                        $Variables.CalculatePowerCost = $false
                    }
                    Else { 
                        $Hashtable = @{ }
                        $DeviceName = ""
                        $RegistryValue.PSObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @(($Variables.Devices).Name | Select-Object) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                            $DeviceName = ($_.Value -split ' ') | Select-Object -Last 1
                            Try { 
                                $Hashtable.Add($DeviceName, $RegistryValue.($_.Name -replace "Label", "Value"))
                            }
                            Catch { 
                                Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [duplicate sensor for $DeviceName] - disabling power usage calculations."
                                $Variables.CalculatePowerCost = $false
                            }
                        }
                        # Add configured power usage
                        $Config.PowerUsage.PSObject.Properties.Name | Where-Object { $Config.PowerUsage.$_ } | ForEach-Object { 
                            If ($Config.PowerUsage.$_) { 
                                If ($_ -in @($EnabledDevices.Name) -and -not $Hashtable.$_ ) { Write-Message -Level Warn "HWiNFO64 cannot read power usage from system for device ($_). Will use configured value of $([Double]$Config.PowerUsage.$_) W." }
                                $Hashtable.$_ = "$Config.PowerUsage.$_ W"
                                If ($Variables.Devices | Where-Object Name -EQ $_) { ($Variables.Devices | Where-Object Name -EQ $_).ConfiguredPowerUsage = [Double]$Config.PowerUsage.$_ }
                            }
                        }

                        If ($DeviceNamesMissingSensor = Compare-Object @($EnabledDevices.Name) @($Hashtable.Keys) -PassThru | Where-Object SideIndicator -EQ "<=") { 
                            Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [missing sensor config for $($DeviceNamesMissingSensor -join ', ')] - disabling power usage calculations."
                            $Variables.CalculatePowerCost = $false
                        }

                        # Read power usage from device supported?
                        $Variables.Devices | ForEach-Object { $_.ReadPowerUsage = $_.Name -in @($Hashtable.Keys) }

                        Remove-Variable DeviceName, Hashtable
                    }
                    $Variables.HWInfo64RegistryValue = [String]$RegistryValue
                }
                Else { 
                    Write-Message -Level Warn "Cannot read power usage info from registry [Key '$RegKey' does not exist - HWiNFO64 not running???] - disabling power usage calculations."
                    $Variables.CalculatePowerCost = $false
                }
            }
            Else { $Variables.CalculatePowerCost = $false }
        }
        If (-not $Variables.CalculatePowerCost) { 
            $Variables.Devices | ForEach-Object { $_.ReadPowerUsage = $false }
        }

        # Power price
        If (-not ($Config.PowerPricekWh | Sort-Object | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) { $Config.PowerPricekWh = [PSCustomObject]@{ "00:00" = 0 } }
        If ($null -eq $Config.PowerPricekWh."00:00") { 
            # 00:00h power price is the same as the latest price of the previous day
            $Config.PowerPricekWh | Add-Member "00:00" ($Config.PowerPricekWh.($Config.PowerPricekWh | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Sort-Object | Select-Object -Last 1))
        }
        $Variables.PowerPricekWh = [Double]($Config.PowerPricekWh.($Config.PowerPricekWh | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Sort-Object | Where-Object { $_ -lt (Get-Date -Format HH:mm).ToString() } | Select-Object -Last 1))
        $Variables.PowerCostBTCperW = [Double](1 / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.Currency))
        $Variables.BasePowerCostBTC = [Double]($Config.IdlePowerUsageW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.Currency))

        # Clear pools if pools config has changed to avoid double pools with different wallets/usernames
        If (($Config.PoolsConfig | ConvertTo-Json -Depth 10 -Compress) -ne ($Variables.PoolsConfigCached | ConvertTo-Json -Depth 10 -Compress)) { $Variables.Pools = [Miner]::Pools }

        # Load unprofitable algorithms
        If (Test-Path -Path ".\Data\UnprofitableAlgorithms.json" -PathType Leaf -ErrorAction Ignore) { 
            $Variables.UnprofitableAlgorithms = Get-Content ".\Data\UnprofitableAlgorithms.json" | ConvertFrom-Json -ErrorAction SilentlyContinue -AsHashtable | Get-SortedObject
            Write-Message "Loaded list of unprofitable algorithms ($($Variables.UnprofitableAlgorithms.Count) $(If ($Variables.UnprofitableAlgorithms.Count -ne 1) { "entries" } Else { "entry" } ))."
        }
        Else {
            $Variables.UnprofitableAlgorithms = $null
        }

        # Load information about the pools
        If ($PoolNames -and (Test-Path -Path ".\Pools" -PathType Container -ErrorAction Ignore)) { 
            Write-Message -Level Verbose "Waiting for pool data ($($PoolNames -join ', '))..."
            $NewPools_Jobs = @(
                $PoolNames | ForEach-Object { 
                    Get-ChildItemContent ".\Pools\$($_).*" -Parameters @{ Config = $Config; PoolsConfig = $PoolsConfig; Variables = $Variables } -Threaded -Priority $(If ($Variables.Miners | Where-Object Best -EQ $true | Where-Object { $_.Status -eq [MinerStatus]::Running } | Where-Object Type -EQ "CPU") { "Normal" })
                }
            )

            # Retrieve collected pool data
            $NewPools = @($NewPools_Jobs | ForEach-Object { $_ | Get-Job | Wait-Job -Timeout ([Int]$Config.PoolTimeout) | Receive-Job } | ForEach-Object { If (-not $_.Content.Name) { $_.Content | Add-Member Name $_.Name -Force }; $_.Content -as [Pool] } )
            $NewPools_Jobs | ForEach-Object { $_ | Get-Job | Remove-Job -Force }
            Remove-Variable NewPools_Jobs

            If ($PoolNoData = @($PoolNames | ForEach-Object { If (-not ($NewPools | Where-Object Name -EQ $_ )) { $_ } })) { 
                Write-Message -Level Warn "No data received from pool$(If ($PoolNoData.Count -gt 1) { "s" } ) ($($PoolNoData -join ', '))." -Console
            }
            Remove-Variable PoolNoData
        }
        Else { 
            Write-Message -Level Warn "No configured pools - retrying in 10 seconds..."
            Start-Sleep -Seconds 10
            Continue
        }

        # Faster shutdown
        If ($Variables.NewMiningStatus -ne "Running") { Return }

        # Remove de-configured pools
        $Pools = @($Pools | Where-Object Name -in $PoolNames)

        # Find new pools
        $ComparePools = Compare-Object -PassThru @($Pools | Select-Object) @($NewPools | Select-Object) -Property Name, Algorithm, Host, Port, SSL | Where-Object SideIndicator -EQ "=>" | Select-Object -Property * -ExcludeProperty SideIndicator
        $ComparePools | Select-Object | Where-Object { -not $_.BaseName } | ForEach-Object { $_ | Add-Member BaseName ($_.Name -replace "24hr$|Coins$|Coins24hr$|CoinsPlus$|Plus$") -Force }
        $Variables.PoolsCount = $Pools.Count

        # Add new pools
        If ($ComparePools) { $Pools += [Pool[]]$ComparePools }

        # Update existing pools
        $Pools | Select-Object | ForEach-Object { 
            $_.Available = $true
            $_.Best = $false
            $_.Reason = $null

            If ($Pool = $NewPools | Where-Object Name -EQ $_.Name | Where-Object Algorithm -EQ $_.Algorithm | Where-Object Host -EQ $_.Host | Where-Object Port -EQ $_.Port | Where-Object SSL -EQ $_.SSL | Select-Object -First 1) { 
                $_.EstimateFactor = If (-not $Config.EstimateCorrection -or $Pool.EstimateFactor -le 0 -or $Pool.EstimateFactor -gt 1) { 1 } Else { $Pool.EstimateFactor }
                $_.Fee = If ($Config.IgnorePoolFee -or $Pool.Fee -lt 0 -or $Pool.Fee -gt 1) { 0 } Else { $Pool.Fee }
                $Factor = $_.EstimateFactor * $_.EarningsAdjustmentFactor * (1 - $_.Fee)
                $_.EarningsAdjustmentFactor = $Pool.EarningsAdjustmentFactor
                $_.Price = $Pool.Price * $Factor
                $_.StablePrice = $Pool.StablePrice * $Factor
                $_.MarginOfError = $Pool.MarginOfError
                $_.Pass = $Pool.Pass
                $_.Updated = $Pool.Updated
                $_.User = $Pool.User
                $_.Workers = $Pool.Workers
                $_.CoinName = $Pool.CoinName
            }

            $_.CoinName = Get-CoinName $_.Currency

            If ($_.Algorithm -in @("EtcHash", "Ethash", "EthashLowMem",  "KawPoW", "ProgPoW", "UbqHash")) { 
                If ($Variables.DAGdata.Currency.($_.Currency).BlockHeight) { 
                    $_.BlockHeight = [Int]($Variables.DAGdata.Currency.($_.Currency).BlockHeight + 30000)
                    $_.Epoch = [Int]($Variables.DAGdata.Currency.($_.Currency).Epoch + 1)
                    $_.DAGSize = [Int64]($Variables.DAGdata.Currency.($_.Currency).DAGsize + [Math]::Pow(2, 23))
                }
                ElseIf ($_.Algorithm -eq "EthashLowMem") { 
                    # Dummy values for EthashLowMem
                    $_.BlockHeight = 0
                    $_.Epoch = 0
                    $_.DAGSize = 0
                }
                Else {
                    $_.BlockHeight = [Int]($Variables.DAGdata.Currency."*".BlockHeight + 30000)
                    $_.Epoch = [Int]($Variables.DAGdata.Currency."*".Epoch + 1)
                    $_.DAGSize = [Int64]($Variables.DAGdata.Currency."*".DAGsize + [Math]::Pow(2, 23))
                }
            }
            $_.Price_Bias = $_.Price * (1 - $_.MarginOfError)
        }
        Remove-Variable Factor, Pool -ErrorAction Ignore

        # Pool data is older than earliest CycleStart, decay price
        If ($Variables.CycleStarts.Count -ge $Config.SyncWindow) { 
            $MaxPoolAge = $Config.SyncWindow * ($Variables.CycleStarts[-1] - $Variables.CycleStarts[0]).TotalMinutes
            $Pools = $Pools | Where-Object { [Math]::Floor(($Variables.CycleStarts[-1] - $_.Updated).TotalMinutes) -le $MaxPoolAge * $Config.SyncWindow }
            $Pools | ForEach-Object { 
                If ([Math]::Floor(($Variables.CycleStarts[-1] - $_.Updated).TotalMinutes) -gt $MaxPoolAge) { $_.Available = $false; $_.Reason += "Data too old" }
                ElseIf ($_.Updated -lt $Variables.CycleStarts[0]) { $_.Price_Bias = $_.Price * (1 - $_.MarginOfError) * [Math]::Pow(0.9, ($Variables.CycleStarts[0] - $_.Updated).TotalMinutes) }
            }
            Remove-Variable MaxPoolAge -ErrorAction Ignore
        }

        # much faster
        $PoolsConfig = $Config.PoolsConfig

        # Filter Algorithms based on Per Pool Config
        # Pool disabled by stat file
        $Pools | Where-Object Disabled -EQ $true | ForEach-Object { $_.Available = $false; $_.Reason += "Disabled (by Stat file)" }
        # SSL filter
        If ($Config.SSL -ne "Preferred") { $Pools | Where-Object { $_.SSL -ne [Boolean]$Config.SSL } | ForEach-Object { $_.Available = $false; $_.Reason += "Config item SSL -ne $([Boolean]$Config.SSL)" } }
        # Min accuracy exceeded
        $Pools | Where-Object MarginOfError -GT (1 - $Config.MinAccuracy) | ForEach-Object { $_.Available = $false; $_.Reason += "MinAccuracy ($($Config.MinAccuracy * 100)%) exceeded" }
        # Filter pools on miner set
        If ($Config.MinerSet -lt 2) {
            $Pools | Where-Object { $Variables.UnprofitableAlgorithms.($_.Algorithm) -eq "*" } | ForEach-Object { $_.Available = $false; $_.Reason += "Unprofitable Algorithm" }
            $Pools | Where-Object { $Variables.UnprofitableAlgorithms.($_.Algorithm) -eq 1 } | ForEach-Object { $_.Reason += "Unprofitable Primary Algorithm" } # Keep available
            $Pools | Where-Object { $Variables.UnprofitableAlgorithms.($_.Algorithm) -eq 2 } | ForEach-Object { $_.Reason += "Unprofitable Secondary Algorithm" } # Keep available
        }
        # Pool not configured
        $Pools | Where-Object { $_.Name -notin $PoolNames } | ForEach-Object { $_.Available = $false; $_.Reason += "Pool not configured" }
        # Pool price 0
        $Pools | Where-Object Price -EQ 0 | ForEach-Object { $_.Available = $false; $_.Reason += "Price -eq 0" }
        # No price data
        $Pools | Where-Object Price -EQ [Double]::NaN | ForEach-Object { $_.Available = $false; $_.Reason += "No price data" }
        #Estimate factor exceeded
        If ($Config.EstimateCorrection -eq $true ) { $Pools | Where-Object EstimateFactor -LT 0.5 | ForEach-Object { $_.Available = $false; $_.Reason += "EstimateFactor -lt 50%" } }
        # Ignore pool if price is more than $Config.UnrealPoolPriceFactor higher than average price of all other pools with same algorithm & currency, NiceHash & MPH are always right
        If ($Config.UnrealPoolPriceFactor -gt 1) { 
            $Pools | Where-Object Price -GT 0 | Where-Object { $_.Name -notmatch "^NiceHash$|^MiningPoolHub(|Coins)$" } | Group-Object -Property Algorithm | ForEach-Object { 
                If (($_.Group.Price_Bias | Sort-Object -Unique).Count -gt 2 -and ($PriceThreshold = ($_.Group.Price_Bias | Sort-Object -Unique | Select-Object -SkipLast 1 | Measure-Object -Average).Average * $Config.UnrealPoolPriceFactor)) { 
                    $_.Group | Where-Object Price_Bias -GT $PriceThreshold | ForEach-Object { 
                        $_.Available = $false
                        $_.Reason += "Unreal profit ($($Config.UnrealPoolPriceFactor)x higher than average price of all other pools)"
                    }
                }
            }
        }
        Remove-Variable PriceThreshold -ErrorAction SilentlyContinue
        # Algorithms disabled
        $Pools | Where-Object { "-$($_.Algorithm)" -in $Config.Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm disabled (``-$($_.Algorithm)`` in generic config)" }
        $Pools | Where-Object { "-$($_.Algorithm)" -in $PoolsConfig.($_.BaseName).Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm disabled (``-$($_.Algorithm)`` in $($_.BaseName) pool config)" }
        # Algorithms not enabled
        If ($Config.Algorithm -like "+*") { $Pools | Where-Object { "+$($_.Algorithm)" -notin $Config.Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm not enabled (in generic config)" } }
        $Pools | Where-Object { $PoolsConfig.($_.BaseName).Algorithm -like "+*" } | Where-Object { "+$($_.Algorithm)" -notin $PoolsConfig.($_.BaseName).Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm not enabled (``-$($_.Algorithm)``in $($_.BaseName) pool config)" }
        # Region exclusions
        $Pools | Where-Object { $Config.Pools.($_.BaseName).ExcludeRegion -and (Compare-Object @($Config.Pools.$($_.BaseName).ExcludeRegion | Select-Object) @($_.Region) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { $_.Available = $false; $_.Reason += "Region excluded (in $($_.BaseName) pool config)" }
        # MinWorkers
        $Pools | Where-Object { $null -ne $_.Workers -and $_.Workers -lt $Variables.PoolsConfigData.($_.BaseName).MinWorker } | ForEach-Object { $_.Available = $false; $_.Reason += "Not enough workers at pool (MinWorker ``$($Config.PoolsConfig.($_.BaseName).MinWorker)`` in $($_.BaseName) pool config)" }
        $Pools | Where-Object { $null -ne $_.Workers -and $_.Workers -lt $Config.MinWorker -and $null -eq $Variables.PoolsConfigData.($_.BaseName).MinWorker } | ForEach-Object { $_.Available = $false; $_.Reason += "Not enough workers at pool (MinWorker ``$($Config.MinWorker)`` in generic config)" }

        Write-Message -Level Verbose "Had $($Variables.PoolsCount) pool$(If ($Variables.PoolsCount -ne 1) { "s" }), found $($ComparePools.Count) new pool$(If ($ComparePools.Count -ne 1) { "s" }). $(@($Pools | Where-Object Available -EQ $true).Count) pool$(If (@($Pools | Where-Object Available -EQ $true).Count -ne 1) { "s" }) remain$(If (@($Pools | Where-Object Available -EQ $true).Count -eq 1) { "s" }) (filtered out $(@($Pools | Where-Object Available -NE $true).Count) pool$(If (@($Pools | Where-Object Available -NE $true).Count -ne 1) { "s" }))."
        Remove-Variable ComparePools
    }

    # Update pools last used, required for BalancesKeepAlive
    If ($Variables.PoolsLastUsed) { $Variables.PoolsLastUsed | Get-SortedObject | ConvertTo-Json | Out-File ".\Data\PoolsLastUsed.json" -Force }

    # Apply watchdog to pools
    If ($Config.Watchdog) { 
        $Pools | Where-Object Available -EQ $true | Group-Object -Property Name | ForEach-Object { 
            # Suspend pool if > 50% of all algos@pool failed
            $PoolName = $_.Name
            $WatchdogCount = ($Variables.WatchdogCount, ($Variables.WatchdogCount * $_.Group.Count / 2), (($Variables.Miners | Where-Object Best | Where-Object { $_.WorkersRunning.Pool.Name -eq $PoolName }).count) | Measure-Object -Maximum).Maximum
            If ($PoolsToSuspend = $_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object PoolName -EQ $PoolName | Where-Object Kicked -LT $Variables.Timer).Count -gt $WatchdogCount }) { 
                $PoolsToSuspend | ForEach-Object {
                    $_.Available = $false
                    $_.Price = $_.Price_Bias = $_.StablePrice = $_.MarginOfError = [Double]::NaN
                    $_.Reason += "Pool suspended by watchdog"
                }
                Write-Message -Level Warn "Pool ($($_.Name)) is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object PoolName -EQ $_.Name | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -First 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
            }
        }
        $Pools | Where-Object Available -EQ $true | Group-Object -Property Algorithm, Name | ForEach-Object { 
            # Suspend algorithm@pool if > 50% of all possible miners for algorithm failed
            $WatchdogCount = ($Variables.WatchdogCount, ($Variables.WatchdogCount * $_.Group.Count / 2) | Measure-Object -Maximum).Maximum + 1
            If ($PoolsToSuspend = $_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object Algorithm -EQ $_.Algorithm | Where-Object PoolName -EQ $_.Name | Where-Object { ($_.MinerName | Select-Object -Unique).Count -gt 1 } | Where-Object Kicked -LT $Variables.Timer).Count -gt $WatchdogCount }) { 
                $PoolsToSuspend | ForEach-Object { 
                    $_.Available = $false
                    $_.Price = $_.Price_Bias = $_.StablePrice = $_.MarginOfError = [Double]::NaN
                    $_.Reason += "Algorithm@Pool suspended by watchdog"
                }
                Write-Message -Level Warn "Algorithm@Pool ($($_.Group[0].Algorithm)@$($_.Group[0].Name)) is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object Algorithm -EQ $_.Group[0].Algorithm | Where-Object PoolName -EQ $_.Group[0].Name | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -First 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
            }
        }
        Remove-Variable PoolName, WatchdogCount, PoolsToSuspend -ErrorAction Ignore
    }

    If ($Config.PoolBalancesUpdateInterval -gt 0 -and $Config.BalancesKeepAlive -eq $true) { 
        # Keep pool balances alive; force mining at pool even if it is not the best for the algo
        $PoolsToKeepBalancesAlive = @()
        ForEach ($Pool in ($Pools | Where-Object Available -EQ $true | Where-Object { $Variables.PoolsLastEarnings.($_.Basename) } | Sort-Object { $_.BaseName } -Unique)) { 

            $PoolBaseName = If ($Pool.BaseName -eq "NiceHash") { If ($Config.NiceHashWalletIsInternal -eq $true) { "NiceHash Internal" } Else { "NiceHash External" } } Else { $Pool.BaseName }

            $BalancesKeepAliveDays = $PoolsConfig.($Pool.Basename).BalancesKeepAlive

            If ($BalancesKeepAliveDays -gt 0 -and $Variables.PoolsLastEarnings.$PoolBaseName -and (((Get-Date).TouniversalTime() - $Variables.PoolsLastEarnings.$PoolBaseName).Days) -ge $BalancesKeepAliveDays) { 
                If (-not $Variables.PoolsLastUsed.$PoolBaseName) { 
                    $PoolsToKeepBalancesAlive += $Pool.Name
                    Write-Message -Level Warn "Pool ($($Pool.Name)) priorized to avoid forfeiting balance (pool would clear balance after $($BalancesKeepAliveDays) days of inactivity)."
                }
                ElseIf (((Get-Date).ToUniversalTime() - $Variables.PoolsLastUsed.$PoolBaseName).Days -ge $BalancesKeepAliveDays - 1) { 
                    $PoolsToKeepBalancesAlive += $Pool.Name
                    Write-Message -Level Warn "Pool ($($Pool.Name)) priorized to avoid forfeiting balance (pool would clear balance tomorrow)."
                }
            }
        }
        If ($PoolsToKeepBalancesAlive) { 
            $Pools | ForEach-Object { 
                If ($_.Name -in $PoolsToKeepBalancesAlive) { $_.Available = $true; $_.Reason = "Prioritized by BalancesKeepAlive" }
                Else { $_.Available = $false; $_.Reason += "BalancesKeepAlive prioritizes other pools" }
            }
        }
        Remove-Variable PoolName, PoolBaseName, BalancesKeepAlive, PoolsToKeepBalancesAlive -ErrorAction Ignore
    }

    # Sort best pools
    [Pool[]]$Pools = $Pools | Sort-Object { $_.Available }, { - $_.StablePrice * (1 - $_.MarginOfError) }, { $_.SSL -ne $Config.SSL }, { $Variables.Regions.($Config.Region).IndexOf($_.Region) }
    (($Pools | Where-Object Available -EQ $true).Algorithm | Select-Object -Unique) | ForEach-Object { 
        $Pools | Where-Object Available -EQ $true | Where-Object Algorithm -EQ $_ | Select-Object -First 1 | ForEach-Object { $_.Best = $true }
    }

    # For legacy miners
    $AllPools = [PSCustomObject]@{ }
    $PoolsPrimaryAlgorithm = [PSCustomObject]@{ }
    $PoolsSecondaryAlgorithm = [PSCustomObject]@{ }
    $Pools | Where-Object Best -EQ $true | Sort-Object Algorithm | ForEach-Object { 
        $AllPools | Add-Member $_.Algorithm $_
        If ($_.Reason -ne "Unprofitable Primary Algorithm") { $PoolsPrimaryAlgorithm | Add-Member $_.Algorithm $_ } # Allow unprofitable algos for primary algorithm
        If ($_.Reason -ne "Unprofitable Secondary Algorithm") { $PoolsSecondaryAlgorithm | Add-Member $_.Algorithm $_ } # Allow unprofitable algos for secondary algorithm
    }

    # Update data in API
    $Variables.Pools = $Pools
    Remove-Variable Pools

    # Faster shutdown
    If ($Variables.NewMiningStatus -ne "Running") { Return }

    # Get new miners
    Write-Message -Level Verbose "Loading miners..."
    $Miners = $Variables.Miners
    $NewMiners_Jobs = @(
        If ($Config.IncludeRegularMiners -and (Test-Path -Path ".\Miners" -PathType Container)) { Get-ChildItemContent ".\Miners" -Parameters @{ Pools = $PoolsPrimaryAlgorithm; PoolsSecondaryAlgorithm = $PoolsSecondaryAlgorithm; Config = $Config; Devices = $EnabledDevices } -Threaded -Priority $(If ($Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | Where-Object { $_.DeviceName -like "CPU#*" }) { "Normal" }) }
        If ($Config.IncludeOptionalMiners -and (Test-Path -Path ".\OptionalMiners" -PathType Container)) { Get-ChildItemContent ".\OptionalMiners" -Parameters @{ Pools = $PoolsPrimaryAlgorithm; PoolsSecondaryAlgorithm = $PoolsSecondaryAlgorithm; Config = $Config; Devices = $EnabledDevices } -Threaded -Priority $(If ($Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | Where-Object { $_.DeviceName -like "CPU#*" }) { "Normal" }) }
        If (Test-Path -Path ".\CustomMiners" -PathType Container) { Get-ChildItemContent ".\CustomMiners" -Parameters @{ Pools = $PoolsPrimaryAlgorithm; PoolsSecondaryAlgorithm = $PoolsSecondaryAlgorithm; Config = $Config; Devices = $EnabledDevices } -Threaded -Priority $(If ($Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | Where-Object { $_.DeviceName -like "CPU#*" }) { "Normal" }) }
    )

    # Ensure we get the hashrate for running miners prior looking for best miner
    ForEach ($Miner in ($Variables.Miners | Where-Object Best)) { 
        If ($Miner.DataReaderJob.HasMoreData) { 
            # Reduce data to MinDataSamples * 5
            $Miner.Data = @($Miner.Data | Select-Object -Last ($Miner.MinDataSamples * 5))
            $Miner.Data += @($Miner.DataReaderJob | Receive-Job | Select-Object -Property Date, HashRate, Shares, PowerUsage)
        }

        If ($Miner.Status -eq [MinerStatus]::Running) { 
            If ($Miner.GetStatus() -eq [MinerStatus]::Running) { 
                ForEach ($Worker in $Miner.WorkersRunning) { 
                    If ($WatchdogTimer = $Variables.WatchdogTimers | Where-Object MinerName -EQ $Miner.Name | Where-Object PoolName -EQ $Worker.Pool.Name | Where-Object Algorithm -EQ $Worker.Pool.Algorithm | Select-Object -Last 1) { 
                        #Update watchdog timers
                        $WatchdogTimer.Kicked = $Variables.Timer
                    }
                    ElseIf ($Config.Watchdog) { 
                        # Create watchdog timer
                        $Variables.WatchdogTimers += [PSCustomObject]@{ 
                            MinerName     = $Miner.Name
                            MinerBaseName = $Miner.BaseName
                            MinerVersion  = $Miner.Version
                            PoolName      = $Worker.Pool.Name
                            Algorithm     = $Worker.Pool.Algorithm
                            DeviceName    = [String[]]$Miner.DeviceName
                            Kicked        = $Variables.Timer
                        }
                    }
                }
                If ($Config.AllowedBadShareRatio -gt 0) { 
                    $Miner.WorkersRunning.Pool.Algorithm | ForEach-Object { 
                        $LastSharesData = ($Miner.Data | Select-Object -Last 1).Shares
                        If ($LastSharesData -and $LastSharesData.$_[1] -gt 0 -and $LastSharesData.$_[2] -gt [Int](1 / $Config.AllowedBadShareRatio) -and $LastSharesData.$_[1] / $LastSharesData.$_[2] -gt $Config.AllowedBadShareRatio) { 
                            Write-Message -Level Error "Miner '$($Miner.Info)' stopped. Reason: Too many bad shares (Shares Total = $($LastSharesData.$_[2]), Rejected = $($LastSharesData.$_[1]))." 
                            $Miner.SetStatus([MinerStatus]::Failed)
                            $Miner.StatusMessage = "too many bad shares."
                        }
                    }
                }
            }
            Else { 
                Write-Message -Level Error "Miner '$($Miner.Info)' exited unexpectedly."
                $Miner.SetStatus([MinerStatus]::Failed)
                $Miner.StatusMessage = "Error: {$(($Miner.WorkersRunning.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')} exited unexpectedly"
            }
        }

        $Miner.Speed_Live = @()
        $PowerUsage = [Double]::NaN
        If ($Miner.Data.Count) { 
            # Collect hashrate from miner
            $Miner_Speeds = [Hashtable]@{ }
            ForEach ($Algorithm in $Miner.Algorithm) { 
                $CollectedHashRate = $Miner.CollectHashRate($Algorithm, ($Miner.New -and $Miner.Data.Count -lt $Miner.MinDataSamples))
                $Miner.Speed_Live += [Double]($CollectedHashRate[1])
                $Miner_Speeds.$Algorithm = [Double]($CollectedHashRate[0])
            }
            If ($Miner.ReadPowerUsage) {
                # Collect power usage from miner
                $CollectedPowerUsage = $Miner.CollectPowerUsage($Miner.New -and $Miner.Data.Count -lt $Miner.MinDataSamples)
                $Miner.PowerUsage_Live = [Double]($CollectedPowerUsage[1])
                $PowerUsage = [Double]($CollectedPowerUsage[0])
            }
        }

        # We don't want to store hashrates if we have less than $MinDataSamples
        If ($Miner.Data.Count -ge $Miner.MinDataSamples -or ($Miner.New -and $Miner.Activated -ge 3)) { 
            $Miner.New = $false
            $Miner.StatEnd = (Get-Date).ToUniversalTime()
            $Miner.Intervals = @($Miner.Intervals | Select-Object -Last ($Miner.MinDataSamples * 5)) # Only keep the last MinDataSamples * 5
            $Miner.Intervals += $Stat_Span = [TimeSpan]($Miner.StatEnd - $Miner.StatStart)

            ForEach ($Worker in $Miner.Workers) { 
                $Algorithm = $Worker.Pool.Algorithm
                $Stat_Name = "$($Miner.Name)_$($Algorithm)_HashRate"
                # Do not save data if stat just got removed (Miner.Activated < 1, set by API)
                If (($Stat = Get-Stat $Stat_Name) -or $Miner.Activated -gt 0) {
                    $LastSharesData = ($Miner.Data | Select-Object -Last 1).Shares
                    If ($Config.IgnoreRejectedShares -and $LastSharesData -and $LastSharesData.$Algorithm[1] -gt 0) { 
                        $Factor = $(1 - $LastSharesData.$Algorithm[1] / $LastSharesData.$Algorithm[2])
                        Write-Message -Level Verbose "Hashrate for $($Algorithm) adjusted by factor $Factor (Shares total: $($LastSharesData.$Algorithm[2]), Rejected: $($LastSharesData.$Algorithm[1]))."
                        $Miner_Speeds.$Algorithm *= $Factor
                    }
                    $Stat = Set-Stat -Name $Stat_Name -Value $Miner_Speeds.$Algorithm -Duration $Stat_Span -FaultDetection ($Miner.Data.Count -ge $Miner.MinDataSamples) -ToleranceExceeded ($Variables.WatchdogCount + 1)
                    If ($Stat.Updated -gt $Miner.StatStart) { 
                        Write-Message "Saved hash rate ($($Stat_Name -replace '_Hashrate$'): $(($Stat.Live | ConvertTo-Hash) -replace ' '))$(If ($Stat.Duration -eq $Stat_Span) { " [Benchmark done]" })."
                        $Miner.StatStart = $Miner.StatEnd
                        $Variables.PoolsLastUsed.($Worker.Pool.BaseName) = $Stat.Updated # most likely this will count at the pool to keep balances alive
                    }
                    ElseIf ($Miner_Speeds.$Algorithm -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($Miner_Speeds.$Algorithm -gt $Stat.Week * 2 -or $Miner_Speeds.$Algorithm -lt $Stat.Week / 2)) { # Stop miner if new value is outside ±200% of current value
                        Write-Message -Level Warn "$($Miner.Info): Reported hashrate is unreal ($($Algorithm): $(($Miner_Speeds.$Algorithm | ConvertTo-Hash) -replace ' ') is not within ±200% of stored value of $(($Stat.Week | ConvertTo-Hash) -replace ' ')). Stopping miner..."
                        $Miner.SetStatus([MinerStatus]::Failed)
                    }
                    If ($Stat.Week -eq 0) { $PowerUsage = 0 } # Save 0 instead of measured power usage when stat contains no data
                }
            }

            If ($Miner.ReadPowerUsage -eq $true -and $Stat.Updated -gt $Miner.StatStart) { 
                $Stat_Name = "$($Miner.Name)$(If ($Miner.Workers.Count -eq 1) { "_$($Miner.Workers.Pool.Algorithm | Select-Object -Index 0)" })_PowerUsage"
                # Do not save data if stat just got removed (Miner.Activated < 1, set by API)
                If (($Stat = Get-Stat $Stat_Name) -or $Miner.Activated -gt 0) {
                    If ([Double]::IsNaN($PowerUsage)) { $PowerUsage = 0 }
                    If ($Stat.Updated -gt $Miner.StatStart) { 
                        Write-Message "Saved power usage ($($Stat_Name -replace '_PowerUsage$'): $($Stat.Live.ToString("N2"))W)$(If ($Stat.Duration -eq $Stat_Span) { " [Power usage measurement done]" })."
                    }
                    ElseIf ($PowerUsage -gt 0 -and $Miner.Status -eq [MinerStatus]::Running -and $Stat.Week -and ($PowerUsage -gt $Stat.Week * 2 -or $PowerUsage -lt $Stat.Week / 2)) { 
                        # Stop miner if new value is outside ±200% of current value
                        Write-Message -Level Warn "$($Miner.Info): Reported power usage is unreal ($($PowerUsage.ToString("N2"))W is not within ±200% of stored value of $(([Double]$Stat.Week).ToString("N2"))W). Stopping miner..."
                        $Miner.SetStatus([MinerStatus]::Failed)
                    }
                    $Stat = Set-Stat -Name $Stat_Name -Value $PowerUsage -Duration $Stat_Span -FaultDetection ($Miner.Data.Count -gt $Miner.MinDataSamples) -ToleranceExceeded ($Variables.WatchdogCount + 1)

                }
            }
            Remove-Variable Factor, LastSharesData, Stat_Name, Stat_Span, Stat -ErrorAction Ignore
        }
    }
    Remove-Variable Miner, Miner_Speeds, PowerUsage, Algorithm, CollectedHashRate, CollectPowerUsage -ErrorAction Ignore

    # Faster shutdown
    If ($Variables.NewMiningStatus -ne "Running") { Return }

    # Retrieve collected miner objects
    $NewMiners = @(
        $NewMiners_Jobs | ForEach-Object { $_ | Get-Job | Wait-Job -Timeout 30 | Receive-Job } | Where-Object { $_.Content.API } | ForEach-Object { 
            [Miner]$Miner = [PSCustomObject]@{ 
                Name        = [String]$_.Content.Name
                BaseName    = [String]($_.Content.Name -split '-' | Select-Object -Index 0)
                Version     = [String]($_.Content.Name -split '-' | Select-Object -Index 1)
                Path        = [String]$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_.Content.Path)
                Algorithm   = [String[]]$_.Content.Algorithm
                Workers     = [Worker[]]@(ForEach ($Algorithm in $_.Content.Algorithm) { @{ Pool = $AllPools.$Algorithm; Fee = If ($Config.IgnoreMinerFee) { 0 } Else { [Double]($_.Content.Fee | Select-Object -Index ($_.Content.Algorithm.IndexOf($Algorithm))) } } })
                Arguments   = [String]$_.Content.Arguments
                DeviceName  = [String[]]$_.Content.DeviceName
                Devices     = [Device[]]($Variables.Devices | Where-Object Name -In $_.Content.DeviceName)
                Type        = [String]$_.Content.Type
                Port        = [UInt16]$_.Content.Port
                URI         = [String]$_.Content.URI
                WarmupTimes = [Int[]]$_.Content.WarmupTimes
                MinerUri    = [String]$_.Content.MinerUri
                LogFile     = [String]$_.Content.LogFile
                API         = [String]$_.Content.API
            } -as "$($_.Content.API)"

            $Miner.CommandLine = $Miner.GetCommandLine().Replace("$(Convert-Path ".\")\", "") # Requires miner class
            $Miner
        }
    )

    $CompareMiners = [Miner[]](Compare-Object -PassThru @($Miners | Select-Object) @($NewMiners | Select-Object) -Property Name, Algorithm -IncludeEqual)

    $NewMiners_Jobs | ForEach-Object { $_ | Remove-Job -Force }

    Remove-Variable PoolsPrimaryAlgorithm, PoolsSecondaryAlgorithm, NewMiners_Jobs -ErrorAction Ignore

    If ($CompareMiners | Where-Object SideIndicator -NE "<=") { # sometimes there are no new miners, still investigating
        # Remove gone miners
        $Miners = @($CompareMiners | Where-Object SideIndicator -NE "<=" | ForEach-Object { $_.PSObject.Properties.Remove('SideIndicator'); $_ })
    }

    $Miners | ForEach-Object { 
        If ($Miner = Compare-Object -PassThru @($NewMiners | Select-Object) @($_ | Select-Object) -Property Name, Algorithm -ExcludeDifferent | Select-Object -ExcludeProperty SideIndicator) {
            # Update existing miners
            $_.KeepRunning = $false
            $_.Restart = $_.Arguments -ne $Miner.Arguments

            If ($_.Status -eq [MinerStatus]::Running -and $_.Restart -eq $true -and $_.BeginTime.AddSeconds($Config.Interval * ($Config.MinInterval -1)) -gt $Variables.Timer -and -not $Variables.DonateRandom) { 
                # Minimum numbers of full cycles not yet reached
                $_.KeepRunning = $true
                $_.Restart = $false
            }
            ElseIf ($_.Restart) { 
                $_.Arguments = $Miner.Arguments
                $_.Devices = $Miner.Devices
                $_.DeviceName = $Miner.DeviceName
                $_.Port = $Miner.Port
                $_.Workers = $Miner.Workers
            }
            $_.MinerUri = $Miner.MinerUri
            $_.WarmupTimes = $Miner.WarmupTimes
        }

        $ReadPowerUsage = $_.ReadPowerUsage
        $_.ReadPowerUsage = [Boolean]($_.Devices.ReadPowerUsage -notcontains $false)

        $_.Refresh($Variables.PowerCostBTCperW) # Needs to be done after ReadPowerUsage and before DataCollectInterval evaluation

        $DataCollectInterval = If ($_.Benchmark -eq $true -or $_.MeasurePowerUsage -eq $true) { 1 } Else { 5 }

        If ($_.Status -eq [MinerStatus]::Running) { 
            If ($_.Activated -eq 0) { 
                # Re-benchmark triggered in Web GUI
                $_.Restart = $true
                $_.Data = @()
                $_.DataCollectInterval = $DataCollectInterval
                $_.RestartDataReader()
            }
            ElseIf ($_.DataCollectInterval -ne $DataCollectInterval) { 
                # DataCollect interval changes, e.g. benchmark or power usage measurement status changed
                $_.DataCollectInterval = $DataCollectInterval
                $_.RestartDataReader()
            }
            ElseIf ($_.ReadPowerUsage -ne $ReadPowerUsage) { 
                # Power readout status changed, e.g. HwINFO no longer responding
                $_.DataCollectInterval = $DataCollectInterval
                $_.RestartDataReader()
            }
        }
        $_.DataCollectInterval = $DataCollectInterval

        $_.MinDataSamples = [Int]($Config.MinDataSamples * (1, ($_.Algorithm | Where-Object { $Config.MinDataSamplesAlgoMultiplier.$_ } | ForEach-Object { $Config.MinDataSamplesAlgoMultiplier.$_ }) | Measure-Object -Maximum).Maximum)
        $_.ProcessPriority = If ($_.Type -eq "CPU") { $Config.CPUMinerProcessPriority } Else { $Config.GPUMinerProcessPriority }
        $_.WindowStyle = If ($_.Benchmark -eq $true -and $Config.MinerWindowStyleNormalWhenBenchmarking -eq $true) { "normal" } Else { $Config.MinerWindowStyle }

        $_.WarmupTimes[0] += $Config.WarmupTimes[0]
        $_.WarmupTimes[1] += $Config.WarmupTimes[1]
    }
    Remove-Variable Miner, NewMiners -ErrorAction Ignore

    # Faster shutdown
    If ($Variables.NewMiningStatus -ne "Running") { Return }

    # Update data in API
    $Variables.Miners = $Miners

    $Miners | Where-Object Disabled -EQ $true | ForEach-Object { $_.Available = $false; $_.Reason += "0 H/s Stat file" }
    $Miners | Where-Object { $Config.ExcludeMinerName.Count -and (Compare-Object $Config.ExcludeMinerName @($_.BaseName, "$($_.BaseName)-$($_.Version)", $_.Name | Select-Object -Unique) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | ForEach-Object { $_.Available = $false; $_.Reason += "ExcludeMinerName ($($Config.ExcludeMinerName -Join '; '))" }
    $Miners | Where-Object { $Config.ExcludeDeviceName.Count -and (Compare-Object $Config.ExcludeDeviceName @($_.DeviceName | Select-Object) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | ForEach-Object { $_.Available = $false; $_.Reason += "ExcludeDeviceName ($($Config.ExcludeDeviceName -Join '; '))" }
    $Miners | Where-Object Disabled -NE $true | Where-Object Earning -EQ 0 | ForEach-Object { $_.Available = $false; $_.Reason += "Earning -eq 0" }
    $Miners | Where-Object { $Config.DisableMinersWithFee -and $_.Fee -gt 0 } | ForEach-Object { $_.Available = $false; $_.Reason += "Config.DisableMinersWithFee" }
    $Miners | Where-Object { $Config.DisableDualAlgoMining -and $_.Workers.Count -eq 2 } | ForEach-Object { $_.Available = $false; $_.Reason += "Config.DisableDualAlgoMining" }
    $Miners | Where-Object { $Config.DisableSingleAlgoMining -and $_.Workers.Count -eq 1 } | ForEach-Object { $_.Available = $false; $_.Reason += "Config.DisableSingleAlgoMining" }

    $Variables.MinersNeedingBenchmark = @($Miners | Where-Object Disabled -NE $true | Where-Object Benchmark -EQ $true)
    $Variables.MinersNeedingPowerUsageMeasurement = @($Miners | Where-Object Disabled -NE $true | Where-Object MeasurePowerUsage -EQ $true)

    # Detect miners with unreal earning (> x times higher than the next best 10% miners, error in data provided by pool?)
    If ($Config.UnrealMinerEarningFactor -gt 1) { 
        $Miners | Where-Object Available -EQ $true | Group-Object { $_.DeviceName } | ForEach-Object {
            If ($ReasonableEarning = [Double]($_.Group | Sort-Object -Descending Earning | Select-Object -Skip 1 -First ([Int]($_.Group.Count / 10 )) | Measure-Object Earning -Average).Average * $Config.UnrealMinerEarningFactor) { 
                $_.Group | Where-Object Earning -GT $ReasonableEarning | ForEach-Object { 
                    $_.Available = $false
                    $_.Reason += "Unreal profit data (-gt $($Config.UnrealMinerEarningFactor)x higher than the next best 10% available miners of the same device(s))"
                }
            }
        }
    }
    Remove-Variable ReasonableEarning -ErrorAction Ignore

    $Variables.MinersMissingBinary = @()
    $Miners | Where-Object Available -EQ $true | Where-Object { -not (Test-Path $_.Path -Type Leaf -ErrorAction Ignore) } | ForEach-Object { 
        $_.Available = $false
        $_.Reason += "Binary missing"
        $Variables.MinersMissingBinary += $_
    }

    # Apply watchdog to miners
    If ($Config.Watchdog) { 
        $Miners | Where-Object Available -EQ $true | Group-Object -Property { "$($_.BaseName)-$($_.Version)" } | ForEach-Object { 
            # Suspend miner if > 50% of all available algorithms failed
            $WatchdogMinerCount = ($Variables.WatchdogCount, [Math]::Ceiling($Variables.WatchdogCount * $_.Group.Count / 2) | Measure-Object -Maximum).Maximum
            If ($MinersToSuspend = @($_.Group | Where-Object { @($Variables.WatchdogTimers | Where-Object MinerBaseName -EQ $_.BaseName | Where-Object MinerVersion -EQ $_.Version | Where-Object Kicked -LT $Variables.Timer).Count -gt $WatchdogMinerCount })) { 
                $MinersToSuspend | ForEach-Object { 
                    $_.Available = $false
                    $_.Data = @() # Clear data because it may be incorrect caused by miner problem
                    $_.Reason += "Miner suspended by watchdog (all algorithms)"
                }
                Write-Message -Level Warn "Miner ($($_.Group[0].BaseName)-$($_.Group[0].Version) [all algorithms]) is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object MinerBaseName -EQ $_.Group[0].BaseName | Where-Object MinerVersion -EQ $_.Group[0].Version | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -Last 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
            }
            Remove-Variable MinersToSuspend
        }
        $Miners | Where-Object Available -EQ $true | Where-Object { @($Variables.WatchdogTimers | Where-Object MinerName -EQ $_.Name | Where-Object DeviceName -EQ $_.DeviceName | Where-Object Algorithm -EQ $_.Algorithm | Where-Object Kicked -LT $Variables.Timer).Count -ge $Variables.WatchdogCount } | ForEach-Object {
            $_.Available = $false
            $_.Data = @() # Clear data because it may be incorrect caused by miner problem
            $_.Reason += "Miner suspended by watchdog (Algorithm $($_.Algorithm))"
            Write-Message -Level Warn "Miner ($($_.Name) [$($_.Algorithm)]) is suspended by watchdog until $((($Variables.WatchdogTimers | Where-Object MinerName -EQ $_.Name | Where-Object DeviceName -EQ $_.DeviceName | Where-Object Algorithm -EQ $_.Algorithm | Where-Object Kicked -LT $Variables.Timer).Kicked | Sort-Object | Select-Object -Last 1).AddSeconds($Variables.WatchdogReset).ToLocalTime().ToString("T"))."
        }
    }

    # Update data in API
    $Variables.Miners = $Miners

    Write-Message "Found $($Miners.Count) miner$(If ($Miners.Count -ne 1) { "s" }), $(($Miners | Where-Object Available -EQ $true).Count) miner$(If (($Miners | Where-Object Available -EQ $true).Count -ne 1) { "s" }) remain$(If (($Miners | Where-Object Available -EQ $true).Count -eq 1) { "s" }) (filtered out $(($Miners | Where-Object Available -NE $true).Count) miner$(If (($Miners | Where-Object Available -NE $true).Count -ne 1) { "s" }))."

    If ($Variables.MinersMissingBinary) { 
        # Download miner binaries
        If ($Variables.Downloader.State -ne [MinerStatus]::Running) { 
            Write-Message "Some miners binaries are missing, starting downloader..."
            $Downloader_Parameters = @{
                Logfile      = $Variables.Logfile
                DownloadList = @($Variables.MinersMissingBinary | Select-Object URI, Path, @{ Name = "Searchable"; Expression = { $Miner = $_; @($Miners | Where-Object { (Split-Path $_.Path -Leaf) -eq (Split-Path $Miner.Path -Leaf) }).Count -eq 0 } }) | Select-Object * -Unique
            }
            $Variables.Downloader = Start-ThreadJob -ThrottleLimit 99 -Name Downloader -InitializationScript ([scriptblock]::Create("Set-Location '$($Variables.MainPath)'")) -ArgumentList $Downloader_Parameters -FilePath ".\Includes\Downloader.ps1"
            Remove-Variable Downloader_Parameters
        }
        ElseIf (-not ($Miners | Where-Object Available -EQ $true)) { 
            Write-Message "Waiting 30 seconds for downloader to install binaries..."
        }
    }

    # Open firewall ports for all miners
    If ($Config.OpenFirewallPorts) { 
        If (Get-Command "Get-MpPreference" -ErrorAction Ignore) { 
            $ProgressPreferenceBackup = $ProgressPreference
            $ProgressPreference = "SilentlyContinue"
            If ((Get-Command "Get-MpComputerStatus" -ErrorAction Ignore) -and (Get-MpComputerStatus -ErrorAction Ignore)) { 
                If (Get-Command "Get-NetFirewallRule" -ErrorAction Ignore) { 
                    $MinerFirewallRules = @(Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program)
                    If (Compare-Object $MinerFirewallRules @($Miners | Select-Object -ExpandProperty Path -Unique) | Where-Object SideIndicator -EQ "=>") { 
                        Start-Process "pwsh" ("-Command Import-Module NetSecurity; ('$(Compare-Object $MinerFirewallRules @($Miners | Select-Object -ExpandProperty Path -Unique) | Where-Object SideIndicator -EQ '=>' | Select-Object -ExpandProperty InputObject | ConvertTo-Json -Compress)' | ConvertFrom-Json) | ForEach-Object { New-NetFirewallRule -DisplayName (Split-Path `$_ -leaf) -Program `$_ -Description 'Inbound rule added by NemosMiner $($Variables.CurrentVersion) on $((Get-Date).ToString())' -Group 'Cryptocurrency Miner' }" -replace '"', '\"') -Verb runAs
                    }
                    Remove-Variable MinerFirewallRules
                }
            }
            $ProgressPreference = $ProgressPreferenceBackup
            Remove-Variable ProgressPreferenceBackup
        }
    }

    If ($Miners | Where-Object Available -EQ $true) { 
        Write-Message "Selecting best miner$(If (@($EnabledDevices.Model | Select-Object -Unique).Count -gt 1) { "s" }) based on earning$(If ($Variables.PowerPricekWh) { " and profit (power cost $($Config.Currency) $($Variables.PowerPricekWh)/kW⋅h)" })..."

        If (($Miners | Where-Object Available -EQ $true) -eq 1) { 
            $Variables.BestMiners_Combo = $Variables.BestMiners = $Variables.MostProfitableMiners = $Miners
        }
        Else { 
            If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { $SortBy = "Profit" } Else { $SortBy = "Earning" }

            # Add running miner bonus
            $Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { $_."$($SortBy)_Bias" *= (1 + $Config.RunningMinerGainPct / 100) }

            # Hack: temporarily make all bias positive, BestMiners_Combos(_Comparison) produces wrong sort order when earnings or profits are negative
            $SmallestBias = [Double][Math]::Abs((($Miners | Where-Object Available -EQ $true | Where-Object { -not [Double]::IsNaN($_."$($SortBy)_Bias" ) })."$($SortBy)_Bias"  | Measure-Object -Minimum).Minimum) * 2
            $Miners | ForEach-Object { $_."$($SortBy)_Bias" += $SmallestBias }

            # Get most profitable miner combination i.e. AMD+NVIDIA+CPU
            $Variables.SortedMiners = @($Miners | Where-Object Available -EQ $true | Sort-Object -Descending -Property Benchmark, MeasurePowerUsage, KeepRunning, "$($SortBy)_Bias") # pre-sort
            $Variables.MostProfitableMiners = @($Variables.SortedMiners | Select-Object DeviceName, Algorithm -Unique | ForEach-Object { $Miner = $_; $Variables.SortedMiners | Where-Object { -not (Compare-Object $Miner $_ -Property DeviceName, Algorithm) } | Select-Object -First 1 | ForEach-Object { $_.Fastest = $true; $_ } }) # use a smaller subset of miners
            $Variables.BestMiners = @($Variables.MostProfitableMiners | Select-Object DeviceName -Unique | ForEach-Object { $Miner = $_; $Variables.MostProfitableMiners | Where-Object { (Compare-Object $Miner.DeviceName $_.DeviceName).Count -eq 0 } | Select-Object -First 1 })

            $Variables.Miners_Device_Combos = @(Get-Combination @($Variables.BestMiners | Select-Object DeviceName -Unique) | Where-Object { (Compare-Object ($_.Combination | Select-Object -ExpandProperty DeviceName -Unique) ($_.Combination | Select-Object -ExpandProperty DeviceName) | Measure-Object).Count -eq 0 })

            $Variables.BestMiners_Combos = @(
                $Variables.Miners_Device_Combos | ForEach-Object { 
                    $Miner_Device_Combo = $_.Combination
                    [PSCustomObject]@{ 
                        Combination = $Miner_Device_Combo | ForEach-Object { 
                            $Miner_Device_Count = $_.DeviceName.Count
                            [Regex]$Miner_Device_Regex = "^(" + (($_.DeviceName | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ")$"
                            $Variables.BestMiners | Where-Object { ([Array]$_.DeviceName -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.DeviceName -match $Miner_Device_Regex).Count -eq $Miner_Device_Count }
                        }
                    }
                }
            )
            $Variables.BestMiners_Combo = @($Variables.BestMiners_Combos | Sort-Object -Descending { @($_.Combination | Where-Object { [Double]::IsNaN($_.$SortBy) }).Count }, { ($_.Combination | Measure-Object "$($SortBy)_Bias" -Sum).Sum }, { ($_.Combination | Where-Object { $_.$Sortby -ne 0 } | Measure-Object).Count } | Select-Object -Index 0 | Select-Object -ExpandProperty Combination)
            Remove-Variable Miner_Device_Combo -ErrorAction Ignore

            # Hack part 2: reverse temporarily forced positive bias
            $Miners | ForEach-Object { $_."$($SortBy)_Bias" -= $SmallestBias }

            # Don't penalize active miners, revert running miner bonus
            $Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | ForEach-Object { $_."$($SortBy)_Bias" /= (1 + $Config.RunningMinerGainPct / 100) }

            Remove-Variable SmallestBias, SortBy
        }

        # Update data in API
        $Variables.Miners = $Miners

        $Variables.MiningEarning = [Double]($Variables.BestMiners_Combo | Measure-Object Earning -Sum).Sum
        $Variables.MiningProfit = [Double]($Variables.BestMiners_Combo | Measure-Object Profit -Sum).Sum
        $Variables.MiningPowerCost = [Double]($Variables.BestMiners_Combo | Measure-Object PowerCost -Sum).Sum
        $Variables.MiningPowerUsage = [Double]($Variables.BestMiners_Combo | Measure-Object PowerUsage -Sum).Sum

        # ProfitabilityThreshold check - OK to run miners?
        If (-not $Variables.Rates -or -not $Variables.Rates.BTC.($Config.Currency) -or [Double]::IsNaN($Variables.MiningEarning) -or [Double]::IsNaN($Variables.MiningProfit) -or [Double]::IsNaN($Variables.MiningPowerCost) -or ($Variables.MiningEarning - $Variables.MiningPowerCost - $Variables.BasePowerCostBTC) -ge ($Config.ProfitabilityThreshold / $Variables.Rates.BTC.($Config.Currency)) -or $Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerUsageMeasurement) { 
            $Variables.BestMiners_Combo | Select-Object | ForEach-Object { $_.Best = $true }
        }
        Else { 
            Write-Message -Level Warn "Mining profit ($($Config.Currency) $(ConvertTo-LocalCurrency -Value ($Variables.MiningEarning - $Variables.MiningPowerCost - $Variables.BasePowerCostBTC) -Rate $Variables.Rates."BTC".($Config.Currency) -Offset 1)) is below the configured threshold of $($Config.Currency) $($Config.ProfitabilityThreshold.ToString("N$((Get-Culture).NumberFormat.CurrencyDecimalDigits)"))/day; mining is suspended until threshold is reached."
        }
    }
    Else { 
        $Variables.SortedMiners = @()
        $Variables.MostProfitableMiners = @()
        $Variables.BestMiners = @()
        $Variables.Miners_Device_Combos = @()
        $Variables.BestMiners_Combos = @()
        $Variables.BestMiners_Combo = @()

        $Variables.MiningEarning = $Variables.MiningProfit = $Variables.MiningPowerCost = $Variables.MiningPowerUsage = [Double]0
    }

    If ($Variables.Rates."BTC") { 
        $Variables.Summary = ""
        If ([Double]::IsNaN($Variables.MiningEarning)) { 
            $Variables.Summary += "Earning / day: n/a (benchmarking)"
        }
        ElseIf ($Variables.MiningEarning -gt 0) { 
            $Variables.Summary += "Earning / day: {1:N} {0}" -f $Config.Currency, ($Variables.MiningEarning * $Variables.Rates."BTC".($Config.Currency))
        }

        If ($Variables.CalculatePowerCost -eq $true) {
            If ($Variables.Summary -ne "") { $Variables.Summary += "&ensp;&ensp;&ensp;" }

            If ([Double]::IsNaN($Variables.MiningEarning) -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                $Variables.Summary += "Profit / day: n/a (measuring)"
            }
            ElseIf ($Variables.MiningPowerUsage -gt 0) { 
                $Variables.Summary += "Profit / day: {1:N} {0}" -f $Config.Currency, (($Variables.MiningProfit - $Variables.BasePowerCostBTC) * $Variables.Rates."BTC".($Config.Currency))
            }
            Else { 
                $Variables.Summary += "Profit / day: n/a (no power data)"
            }

            If ($Variables.BasePowerCostBTC -gt 0) { 
                If ($Variables.Summary -ne "") { $Variables.Summary += "&ensp;&ensp;&ensp;" }

                If ([Double]::IsNaN($Variables.MiningEarning) -or [Double]::IsNaN($Variables.MiningPowerCost)) { 
                    $Variables.Summary += "Power Cost / day: n/a&ensp;(Miner$(If ($Variables.BestMiners_Combo.Count -gt 1) { "s" } ): n/a; Base: {1:N} {0} [{2:0}W])" -f $Config.Currency, ($Variables.BasePowerCostBTC * $Variables.Rates."BTC".($Config.Currency)), $Config.IdlePowerUsageW
                }
                ElseIf ($Variables.MiningPowerUsage -gt 0) { 
                    $Variables.Summary += "Power Cost / day: {1:N} {0}&ensp;(Miner$(If ($Variables.BestMiners_Combo.Count -gt 1) { "s" } ): {2:N} {0} [{3:0} W]; Base: {4:N} {0} [{5:0} W])" -f $Config.Currency, (($Variables.MiningPowerCost + $Variables.BasePowerCostBTC) * $Variables.Rates."BTC".($Config.Currency)), ($Variables.MiningPowerCost * $Variables.Rates."BTC".($Config.Currency)), $Variables.MiningPowerUsage, ($Variables.BasePowerCostBTC * $Variables.Rates."BTC".($Config.Currency)), $Config.IdlePowerUsageW
                }
                Else { 
                    $Variables.Summary += "Power Cost / day: n/a&ensp;(Miner: n/a; Base: {1:N} {0} [{2:0} W])" -f $Config.Currency, ($Variables.BasePowerCostBTC * $Variables.Rates.BTC.($Config.Currency)), $Config.IdlePowerUsageW
                }
            }
        }
        If ($Variables.Summary -ne "") { $Variables.Summary += "<br>" }

        # Add currency conversion rates
        @(@(If ($Config.UsemBTC -eq $true) { "mBTC" } Else { "BTC" }) + @($Config.ExtraCurrencies)) | Select-Object -Unique | Where-Object { $Variables.Rates.$_.($Config.Currency) } | ForEach-Object { 
            $Variables.Summary += "1 $_ = {0:N} $($Config.Currency)&ensp;&ensp;&ensp;" -f $Variables.Rates.$_.($Config.Currency)
        }
    }
    Else { 
        $Variables.Summary = "Error: Could not get BTC exchange rate from min-api.cryptocompare.com"
    }

    # Stop running miners
    ForEach ($Miner in @((@($Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | Where-Object { $_.Best -eq $false -or $_.Restart -eq $true} ) + @($CompareMiners | Where-Object { $_.SideIndicator -EQ "<=" -and $_.Status -eq [MinerStatus]::Running } <# miner object is gone #> )))) { 
        If ($Miner.GetStatus() -eq [MinerStatus]::Running) { 
            ForEach ($Worker in $Miner.WorkersRunning) { 
                If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -EQ $Miner.Name | Where-Object PoolName -EQ $Worker.Pool.Name | Where-Object Algorithm -EQ $Worker.Pool.Algorithm | Where-Object DeviceName -EQ $Miner.DeviceName)) { 
                    # Remove watchdog timers
                    $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })
                }
                Remove-Variable WatchdogTimers
            }

            $Miner.SetStatus([MinerStatus]::Idle)
            If ($Miner.ProcessId) { Stop-Process -Id $Miner.ProcessId -Force -ErrorAction Ignore }
        }
        Else { 
            Write-Message -Level Error "Miner '$($Miner.Info)' exited unexpectedly."
            $Miner.SetStatus([MinerStatus]::Failed)
            $Miner.StatusMessage = "Error: {$(($Miner.WorkersRunning.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')} exited unexpectedly"
        }
        $Miner.WorkersRunning = @()
        $Miner.Info = ""
    }
    Remove-Variable CompareMiners, Miners -ErrorAction Ignore

    # Kill stray miners
    $Loops = 0
    While ($StrayMiners = @(Get-CimInstance CIM_Process | Where-Object ExecutablePath | Where-Object { @($Variables.Miners.Path | Sort-Object -Unique) -contains $_.ExecutablePath } | Where-Object { $Variables.Miners.ProcessID -notcontains $_.ProcessID } | Select-Object -ExpandProperty ProcessID)) { 
        $StrayMiners | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction Ignore }
        Start-Sleep -MilliSeconds 100
        $Loops ++
        If ($Loops -gt 100) { 
            Write-Message -Level Warn "Error stopping stray miner$(If($StrayMiners.Count -gt 1) { "s" }): $($StrayMiners.Name -join '; ')."
            Return
        }
    }
    Remove-Variable Loops, StrayMiners

    If (-not ($Variables.Miners | Where-Object Available -EQ $true)) { 
        Write-Message -Level Warn "No miners available - retrying in 10 seconds..."
        Start-Sleep -Seconds 10
        Continue
    }

    # Optional delay to avoid blue screens
    Start-Sleep -Seconds $Config.Delay -ErrorAction Ignore

    # Put here in case the port range has changed
    Initialize-API

    ForEach ($Miner in ($Variables.Miners | Where-Object Best -EQ $true)) { 
        If ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
            # Launch prerun if exists
            If ($Miner.Type -eq "AMD" -and (Test-Path -Path ".\Utils\Prerun\AMDPrerun.bat" -PathType Leaf)) { 
                Start-Process ".\Utils\Prerun\AMDPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
            }
            If ($Miner.Type -eq "NVIDIA" -and (Test-Path -Path ".\Utils\Prerun\NVIDIAPrerun.bat" -PathType Leaf)) { 
                Start-Process ".\Utils\Prerun\NVIDIAPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
            }
            If ($Miner.Type -eq "CPU" -and (Test-Path -Path ".\Utils\Prerun\CPUPrerun.bat" -PathType Leaf)) { 
                Start-Process ".\Utils\Prerun\CPUPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
            }
            If ($Miner.Type -ne "CPU") { 
                $MinerAlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Name)$(If ($Miner.Algorithm.Count -eq 1) { "_$($Miner.Algorithm[0])" }).bat"
                $AlgorithmPrerunName = ".\Utils\Prerun\$($Miner.Algorithm).bat"
                $DefaultPrerunName = ".\Utils\Prerun\default.bat"
                If (Test-Path $MinerAlgorithmPrerunName -PathType Leaf) { 
                    Write-Message "Launching Prerun: $MinerAlgorithmPrerunName"
                    Start-Process $MinerAlgorithmPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    Start-Sleep -Seconds 2
                }
                ElseIf (Test-Path $AlgorithmPrerunName -PathType Leaf) { 
                    Write-Message "Launching Prerun: $AlgorithmPrerunName"
                    Start-Process $AlgorithmPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    Start-Sleep -Seconds 2
                }
                ElseIf (Test-Path $DefaultPrerunName -PathType Leaf) { 
                    Write-Message "Launching Prerun: $DefaultPrerunName"
                    Start-Process $DefaultPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    Start-Sleep -Seconds 2
                }
            }
            # Add extra time when CPU mining and miner requires DAG creation
            If ($Miner.Type -ne "CPU" -and $Miner.Workers.Pool.DAGsize -and ($Variables.Miners | Where-Object Best -EQ $true).Devices.Type -contains "CPU") { $Miner.WarmupTimes[1] += 15 <# seconds #>} 

            $Miner.SetStatus([MinerStatus]::Running)

            # Add watchdog timer
            If ($Config.Watchdog) { 
                ForEach ($Worker in $Miner.Workers) { 
                    $Variables.WatchdogTimers += [PSCustomObject]@{ 
                        MinerName     = $Miner.Name
                        MinerBaseName = $Miner.BaseName
                        MinerVersion  = $Miner.Version
                        PoolName      = $Worker.Pool.Name
                        Algorithm     = $Worker.Pool.Algorithm
                        DeviceName    = [String[]]$Miner.DeviceName
                        Kicked        = $Variables.Timer
                    }
                }
            }
        }

        # Set window title
        $WindowTitle = "$(($Miner.Devices.Name | Sort-Object) -join "; "): $($Miner.Info)"
        If ($Miner.Benchmark -eq $true -or $Miner.MeasurePowerUsage -eq $true) { 
            $WindowTitle += " ("
            If ($Miner.Benchmark -eq $true) { $WindowTitle += "Benchmarking" }
            If ($Miner.Benchmark -eq $true -and $Miner.MeasurePowerUsage -eq $true) { $WindowTitle += " and " }
            If ($Miner.MeasurePowerUsage -eq $true) { $WindowTitle += "Measuring Power Usage" }
            $WindowTitle += ")"
        }
        [Void][Win32]::SetWindowText((Get-Process -Id $Miner.ProcessId).mainWindowHandle, $WindowTitle)
        Remove-Variable WindowTitle

        $Message = ""
        If ($Miner.Benchmark -eq $true) { $Message = "Benchmark " }
        If ($Miner.Benchmark -eq $true -and $Miner.MeasurePowerUsage -eq $true) { $Message = "$($Message)and " }
        If ($Miner.MeasurePowerUsage -eq $true) { $Message = "$($Message)Power usage measurement " }
        If ($Message) { Write-Message -Level Verbose "$($Message)for miner '$($Miner.Info)' in progress [Attempt $($Miner.Activated) of 3; min. $($Miner.MinDataSamples) Samples]..." }
    }
    Remove-Variable Message -ErrorAction Ignore

    $Variables.Miners | Where-Object Available -EQ $true | Group-Object { $_.DeviceName -join ';' } | ForEach-Object { 
        $MinersDeviceGroup = $_.Group
        $MinersDeviceGroupNeedingBenchmark = $MinersDeviceGroup | Where-Object Benchmark -EQ $true
        $MinersDeviceGroupNeedingPowerUsageMeasurement = $MinersDeviceGroup | Where-Object MeasurePowerUsage -EQ $true

        # Display benchmarking progress
        If ($MinersDeviceGroupNeedingBenchmark) { 
            Write-Message -Level Verbose "Benchmarking for device$(If (($MinersDeviceGroupNeedingBenchmark.DeviceName | Select-Object -Unique).Count -gt 1) { " group" }) ($(($MinersDeviceGroupNeedingBenchmark.DeviceName | Sort-Object -Unique) -join '; ')) in progress: $($MinersDeviceGroupNeedingBenchmark.Count) miner$(If ($MinersDeviceGroupNeedingBenchmark.Count -gt 1){ 's' }) left to complete benchmark."
        }
        # Display power usage measurement progress
        If ($MinersDeviceGroupNeedingPowerUsageMeasurement) { 
            Write-Message -Level Verbose "Power usage measurement for device$(If (($MinersDeviceGroupNeedingPowerUsageMeasurement.DeviceName | Select-Object -Unique).Count -gt 1) { " group" }) ($(($MinersDeviceGroupNeedingPowerUsageMeasurement.DeviceName | Sort-Object -Unique) -join '; ')) in progress: $($MinersDeviceGroupNeedingPowerUsageMeasurement.Count) miner$(If ($MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 1) { 's' }) left to complete measuring."
        }
    }

    $Error.Clear()

    Get-Job -State "Completed" | Remove-Job -Force -ErrorAction Ignore
    Get-Job -State "Stopped" | Remove-Job -Force -ErrorAction Ignore

    # Cache pools config for next cycle
    $Variables.PoolsConfigCached = $Config.PoolsConfig

    If ($Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running }) { Write-Message "Collecting miner data while waiting for next cycle..." }
    $Variables.StatusText = "Waiting $($Variables.TimeToSleep) seconds... | Next refresh: $((Get-Date).AddSeconds($Variables.TimeToSleep).ToString('g'))"
}

$ProgressPreference = "SilentlyContinue"

If (Test-Path -Path ".\Includes\MinerAPIs" -PathType Container -ErrorAction Ignore) { Get-ChildItem -Path ".\Includes\MinerAPIs" -File | ForEach-Object { . $_.FullName } }

While ($Variables.NewMiningStatus -eq "Running") { 
    Start-Cycle

    $Variables.EndLoop = $true
    $Variables.RefreshNeeded = $true

    # End loop when
    # - a miner crashed (and no other miners are benchmarking)
    # - all benchmarking miners have collected enough samples
    # - WarmupTimes[1] is reached (no readout from miner)
    $RunningMiners = @($Variables.Miners | Where-Object Best -EQ $true | Sort-Object -Descending Benchmark, MeasurePowerUsage)
    $Interval = ($RunningMiners.DataCollectInterval | Measure-Object -Minimum).Minimum
    $BenchmarkingOrMeasuringMiners = @($RunningMiners | Where-Object { $_.Benchmark -eq $true -or $_.MeasurePowerUsage -eq $true })

    While ($Variables.NewMiningStatus -eq "Running" -and ((Get-Date) -le $Variables.EndLoopTime -or $BenchmarkingOrMeasuringMiners)) {
        $NextLoop = (Get-Date).AddSeconds($Interval)
        ForEach ($Miner in $RunningMiners) { 
            If ($GetMinerData) { 
                $Miner.GetMinerData()
            }
            If ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
                # Miner crashed
                Write-Message -Level Error "Miner '$($Miner.Info)' exited unexpectedly."
                $Miner.SetStatus([MinerStatus]::Failed)
                $Miner.StatusMessage = "Error: {$(($Miner.WorkersRunning.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')} exited unexpectedly"
            }
            ElseIf ($Miner.DataReaderJob.State -ne [MinerStatus]::Running) { 
                # Miner data reader process failed
                Write-Message -Level Error "Miner data reader '$($Miner.Info)' exited unexpectedly."
                $Miner.SetStatus([MinerStatus]::Failed)
                $Miner.StatusMessage = "Error: {$(($Miner.WorkersRunning.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')} Miner data reader exited unexpectedlye"
            }
            ElseIf ($Miner.DataReaderJob.HasMoreData) { 
                # Set miner priority
                If ($Process = Get-Process | Where-Object Id -EQ $Miner.ProcessId) { 
                    $MinerProcessPriority = If ($Miner.Type -eq "CPU") { $PriorityNames.($Config.CPUMinerProcessPriority) } Else { $PriorityNames.($Config.GPUMinerProcessPriority) }
                    If ($Process.PriorityClass -ne $MinerProcessPriority) { $Process.PriorityClass = $MinerProcessPriority }
                }
                $Miner.Data += $Samples = @($Miner.DataReaderJob | Receive-Job | Select-Object)
                $Sample = $Samples | Select-Object -Last 1

                If ((Get-Date) -gt $Miner.Process.PSBeginTime.AddSeconds($Miner.WarmupTimes[1])) { 
                    # We must have data samples by now
                    If (($Miner.Data | Select-Object -Last 1).Date -lt $Miner.Process.PSBeginTime.ToUniversalTime()) { 
                        # Miner has not provided first sample on time
                        Write-Message -Level Error "Miner '$($Miner.Info)' got stopped because it has not updated data for $($Miner.WarmupTimes[1]) seconds."
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Miner.StatusMessage = "Has not updated data for $($Miner.WarmupTimes[1]) seconds"
                        Break
                    }
                    ElseIf (($Miner.Data | Select-Object -Last 1).Date.AddSeconds($Config.WarmupTimes[1]) -lt (Get-Date).ToUniversalTime()) { 
                        # Miner stuck - no sample for > $Config.WarmupTimes[1] seconds
                        Write-Message -Level Error "Miner '$($Miner.Info)' got stopped because it has not updated data for $($Config.WarmupTimes[1]) seconds."
                        $Miner.SetStatus([MinerStatus]::Failed)
                        $Miner.StatusMessage = "Has not updated data for $($Config.WarmupTimes[1]) seconds"
                        Break
                    }
                }

                If ($Sample.HashRate) { 
                    $Miner.Speed_Live = $Sample.Hashrate.PSObject.Properties.Value
                    If (-not ($Miner.Data | Where-Object Date -GT $Miner.Process.PSBeginTime.ToUniversalTime().AddSeconds($Miner.WarmupTimes[0]))) { 
                        Write-Message -Level Verbose "$($Miner.Name) data sample discarded [$(($Miner.WorkersRunning.Pool.Algorithm | ForEach-Object { "$_ = $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.AllowedBadShareRatio) { " / Shares Total = $($Sample.Shares.$_[2]), Rejected = $($Sample.Shares.$_[1])" })" }) -join ' & ')$(If ($Sample.PowerUsage) { " / Power = $($Sample.PowerUsage.ToString("N2"))W" })] (miner is warming up)."
                        $Miner.Data = @($Miner.Data | Where-Object Date -LT $Miner.Process.PSBeginTime.ToUniversalTime())
                    }
                    Else { 
                        If ($Miner.StatusMessage -notlike "Mining *") { 
                            $Miner.StatusMessage = "$(If ($Miner.Benchmark -EQ $true -or $Miner.MeasurePowerUsage -EQ $true) { "$($(If ($Miner.Benchmark -eq $true) { "Benchmarking" }), $(If ($Miner.Benchmark -eq $true -and $Miner.MeasurePowerUsage -eq $true) { "and" }), $(If ($Miner.MeasurePowerUsage -eq $true) { "Power usage measuring" }) -join ' ')" } Else { "Mining" }) {$(($Miner.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"
                            $Miner.Devices | ForEach-Object { $_.Status = $Miner.StatusMessage }
                        }
                        Write-Message -Level Verbose "$($Miner.Name) data sample retrieved [$(($Miner.WorkersRunning.Pool.Algorithm | ForEach-Object { "$($_): $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Config.AllowedBadShareRatio) { " / Shares Total: $($Sample.Shares.$_[2]), Rejected: $($Sample.Shares.$_[1])" })" }) -join ' & ')$(If ($Sample.PowerUsage) { " / Power usage: $($Sample.PowerUsage.ToString("N2"))W" })] ($($Miner.Data.Count) sample$(If ($Miner.Data.Count -ne 1) { "s" } ))."
                    }
                }
            }
        }

        $FailedMiners = @($RunningMiners | Where-Object { $_.Status -ne [MinerStatus]::Running })
        $RunningMiners = @($RunningMiners | Where-Object { $_.Status -eq [MinerStatus]::Running })
        $BenchmarkingOrMeasuringMiners = @($RunningMiners | Where-Object { $_.Benchmark -eq $true -or $_.MeasurePowerUsage -eq $true })

        If ($FailedMiners -and -not $BenchmarkingOrMeasuringMiners) { 
            # A miner crashed and we're not benchmarking, end the loop now
            $Message = "Miner failed. "
            Break
        }
        ElseIf ($BenchmarkingOrMeasuringMiners -and (-not ($BenchmarkingOrMeasuringMiners | Where-Object { $_.Data.Count -lt (($Config.MinDataSamples, ($BenchmarkingOrMeasuringMiners.MinDataSamples | Measure-Object -Minimum).Minimum) | Measure-Object -Maximum).Maximum }))) { 
            # Enough samples collected for this loop, exit loop immediately
            $Message = "All$(If ($BenchmarkingOrMeasuringMiners | Where-Object Benchmark -EQ $true) { " benchmarking" })$(If ($BenchmarkingOrMeasuringMiners | Where-Object { $_.Benchmark -eq $true -and $_.MeasurePowerUsage -eq $true }) { " and" } )$(If ($BenchmarkingOrMeasuringMiners | Where-Object MeasurePowerUsage -EQ $true) { " power usage measuring" }) miners have collected enough samples for this cycle. "
            Break
        }
        ElseIf (-not $RunningMiners) { 
            # No more running miners, end the loop now
            $Message = "No more running miners. "
            Break
        }

        While ((Get-Date) -le $NextLoop) { Start-Sleep -Milliseconds 100 }
    }

    If ($Variables.NewMiningStatus -eq "Running") { Write-Message -Level Info "$($Message)Ending cycle." }

    Remove-Variable Message, RunningMiners, FailedMiners, BenchmarkingMiners -ErrorAction SilentlyContinue
    Send-MonitoringData
}
