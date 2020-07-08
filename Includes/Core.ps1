using module .\Include.psm1

Function Start-Cycle { 
    $Variables.CycleTime = Measure-Command -Expression {
        Write-Message "Started new cycle."

        #Set master timer
        $Variables.Timer = (Get-Date).ToUniversalTime()
        $Variables.StatStart = $Variables.StatEnd
        $Variables.StatEnd = $Variables.Timer.AddSeconds($Config.Interval)
        $Variables.StatSpan = New-TimeSpan $Variables.StatStart $Variables.StatEnd
        $Variables.WatchdogInterval = ($Variables.WatchdogInterval / $Variables.Strikes * ($Variables.Strikes - 1)) + $StatSpan.TotalSecond
        $Variables.WatchdogReset = ($Variables.WatchdogReset / ($Variables.Strikes * $Variables.Strikes * $Variables.Strikes) * (($Variables.Strikes * $Variables.Strikes * $Variables.Strikes) - 1)) + $StatSpan.TotalSecond
    
        #Always get the latest config
        Get-Config $Variables.ConfigFile

        $Variables.EndLoopTime = ((Get-Date).AddSeconds($Config.Interval))
        $DecayExponent = [Int](((Get-Date).ToUniversalTime() - $Variables.DecayStart).TotalSeconds / $Variables.DecayPeriod)

        #Activate or deactivate donation
        If ((-not ($Config.PoolsConfig)) -or $Config.Donate -gt 0) { 
            If (($Variables.DonateTime).DayOfYear -ne (Get-Date).DayOfYear) { 
                #Re-Randomize donation start once per day
                $Variables.DonateTime = (Get-Date).AddMinutes((Get-Random -Minimum $Config.Donate -Maximum (1440 - $Config.Donate - (Get-Date).TimeOfDay.TotalMinutes)))
            }
            If ((-not ($Config.PoolsConfig)) -or ((Get-Date) -gt $Variables.DonateTime -and ((Get-Date).AddMinutes(-$Config.Donate) -lt $Variables.DonateTime))) {

                If (-not $Variables.DonateRandom) { $Variables.DonateStart = (Get-Date) }
                $Variables.EndLoopTime = ($Variables.DonateStart).AddMinutes($Config.Donate).AddSeconds(-$Variables.CycleTime.Seconds)
                Write-Message "EndLoopTime: $($Variables.EndLoopTime)"

                Write-Message "Donation run: Mining to donation address for the next $((($Variables.EndLoopTime).AddSeconds($Variables.CycleTime.Seconds + 30) - (Get-Date)).Minutes) minute$(If (((($Variables.EndLoopTime).AddSeconds($Variables.CycleTime.Seconds + 30) - (Get-Date)).Minutes) -ne 1) { "s" })."

                # Get donation addresses randomly from agreed developers list
                # This will fairly distribute donations to Developers
                # Developers list and wallets is publicly available at: https://nemosminer.com/data/devlist.json & https://raw.githubusercontent.com/Minerx117/UpDateData/master/devlist.json
                Try { 
                    $Donation = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/UpDateData/master/devlist.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
                }
                Catch { 
                    $Donation = @(
                        [PSCustomObject]@{ Name = "MrPlus";      Wallet = "134bw4oTorEJUUVFhokDQDfNqTs7rBMNYy"; UserName = "MrPlus"; PasswordCurrency = "BTC" }, 
                        [PSCustomObject]@{ Name = "Nemo";        Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"; UserName = "nemo"; PasswordCurrency = "BTC" }, 
                        [PSCustomObject]@{ Name = "aaronsace";   Wallet = "1Q24z7gHPDbedkaWDTFqhMF8g7iHMehsCb"; UserName = "aaronsace"; PasswordCurrency = "BTC" }, 
                        [PSCustomObject]@{ Name = "grantemsley"; Wallet = "16Qf1mEk5x2WjJ1HhfnvPnqQEi2fvCeity"; UserName = "grantemsley"; PasswordCurrency = "BTC" }, 
                        [PSCustomObject]@{ Name = "uselessguru"; Wallet = "1GPSq8txFnyrYdXL8t6S94mYdF8cGqVQJF"; UserName = "uselessguru"; PasswordCurrency = "BTC" }
                    )
                }

                If (-not $Variables.DonateRandom) { $Variables.DonateRandom = $Donation | Get-Random } #Use same donation data for the entire donation period to reduce switching
                $Config.PoolsConfig = [PSCustomObject]@{ 
                    default = [PSCustomObject]@{ 
                        Wallet = $Variables.DonateRandom.Wallet
                        UserName = $Variables.DonateRandom.UserName
                        WorkerName = "$($Variables.CurrentProduct)$($Variables.CurrentVersion.ToString() -replace '\.'))"
                        EstimateCorrection = 1
                    }
                }
            }
            ElseIf ($Variables.DonateRandom) { 
                Write-Message "Donation run complete. Mining for you."
                $Variables.DonateRandom = $null
            }
        }

        Write-Message "Loading BTC rate from 'min-api.cryptocompare.com'..."
        Get-Rates

        #Power cost preparations
        $Variables.OldReadPowerUsage = $Variables.ReadPowerUsage #To trigger an eventual miner restart
        If ($Config.ReadPowerUsage) { 
            If (($Variables.Devices).Count -lt 1) { 
                Write-Message -Level Warn "No configured miner devices. Cannot read power usage info - disabling power usage calculations."
                $Variables.ReadPowerUsage = $false
            }
            Else { 
                #$Variables.ReadPowerUsage is an operational variable and not identical to $Config.ReadPowerUsage
                $Variables.ReadPowerUsage = $true

                #HWiNFO64 verification
                $RegKey = "HKCU:\Software\HWiNFO64\VSB"
                If ($RegistryValue = Get-ItemProperty -Path $RegKey -ErrorAction SilentlyContinue) { 
                    If ([String]$Variables.HWInfo64RegistryValue -eq [String]$RegistryValue) { 
                        Write-Message -Level Warn "Power usage info in registry has not been updated [HWiNFO64 not running???] - power cost calculation is not available. "
                        $Variables.ReadPowerUsage = $false
                    }
                    Else { 
                        $Hashtable = @{ }
                        $Device = ""
                        $RegistryValue.PsObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @(($Variables.Devices).Name | Select-Object) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                            $Device = ($_.Value -split ' ') | Select-Object -last 1
                            Try { 
                                $Hashtable.Add($Device, $RegistryValue.($_.Name -replace "Label", "Value"))
                            }
                            Catch { 
                                Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [duplicate sensor for $Device] - disabling power usage calculations."
                                $Variables.ReadPowerUsage = $false
                            }
                        }
                        If ($Variables.Devices | Where-Object State -EQ "Enabled" | Where-Object { $null -eq $Hashtable.($_.Name) }) { 
                            Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [missing sensor config for $((($Variables.Devices).Name | Where-Object { $null -eq $Hashtable.$_ }) -join ', ')] - disabling power usage calculations."
                            $Variables.ReadPowerUsage = $false
                        }
                        Remove-Variable Device
                        Remove-Variable HashTable
                    }
                    $Variables.HWInfo64RegistryValue = [String]$RegistryValue
                }
                Else { 
                    Write-Message -Level Warn "Cannot read power usage info from registry [Key '$($RegKey)' does not exist - HWiNFO64 not running???] - disabling power usage calculations."
                    $Variables.ReadPowerUsage = $false
                }
            }
            If ($Config.ReadPowerUsage -and -not ($Variables.ReadPowerUsage)) { 
                Write-Message -Level Warn "Realtime power usage cannot be read from system. Will display static values where available."
            }
        }

        #Power price
        If (-not ($Config.PowerPricekWh | Sort-Object | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) { 
            $Config.PowerPricekWh = [PSCustomObject]@{ "00:00" = 0 }
        }
        If ($null -eq $Config.PowerPricekWh."00:00") { 
            #00:00h power price is the same as the latest price of the previous day
            $Config.PowerPricekWh | Add-Member "00:00" ($Config.PowerPricekWh.($Config.PowerPricekWh | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Sort-Object | Select-Object -Last 1))
        }
        $Variables.PowerPricekWh = [Double]($Config.PowerPricekWh.($Config.PowerPricekWh | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Sort-Object | Where-Object { $_ -lt (Get-Date -Format HH:mm).ToString() } | Select-Object -Last 1))
        $Variables.PowerCostBTCperW = [Double](1 / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0))
        $Variables.BasePowerCost = [Double]($Config.IdlePowerUsageW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0))

        #Clear pools if pools config has changed to avoid double pools with different wallets/usernames
        If (($Config.PoolsConfig | ConvertTo-Json -Compress) -ne ($Variables.PoolsConfigCached | ConvertTo-Json -Compress)) { 
            $Variables.Pools = [Miner]::Pools
        }

        #Load information about the pools
        $Variables.NewPools_Jobs = @()
        If ((Test-Path "Pools" -PathType Container -ErrorAction Ignore) -and ($Config.PoolName)) { 
            Write-Message "Requesting pool information ($(@($Config.PoolName) -join '; ')) - this can take up to $($Config.PoolTimeout) second$(If ($Config.PoolTimeout -ne 1) { "s" } )..."
            $Variables.NewPools_Jobs = @(
                $Config.PoolName | ForEach-Object { 
                    Get-ChildItemContentJob "Pools\$($_).*" -Parameters @{ PoolsConfig = $Config.PoolsConfig } -Threaded -Priority $(If ($Variables.Miners | Where-Object Status -EQ "Running" | Where-Object { $_.DeviceName -like "CPU#*" }) { "Normal" })
                } | Select-Object
            )

            #Retrieve collected pool data
            $Variables.NewPools_Jobs | Wait-Job -Timeout $Config.PoolTimeout | Out-Null
            [Pool[]]$NewPools = $Variables.NewPools_Jobs | Where-Object State -EQ "Completed" | Receive-Job | ForEach-Object { If (-not $_.Content.Name) { $_.Content | Add-Member Name $_.Name -Force }; $_.Content }
            [Pool[]]$Variables.NewPools = $NewPools
        }
        Else { 
            Write-Message -Level WARN "No configured pools - retrying in 30 seconds..."
            Start-Sleep -Seconds 10
            Continue
        }

        #Remove de-configured pools
        [Pool[]]$Variables.Pools = $Variables.Pools | Where-Object Name -in $Config.PoolName

        #Find new pools
        [Pool[]]$ComparePools = Compare-Object -PassThru @($Variables.Pools | Select-Object) @($NewPools | Select-Object) -Property Name, Algorithm, CoinName, Currency, Protocol, Host, Port, User, Pass, SSL, PayoutScheme | Where-Object SideIndicator -EQ "=>" | Select-Object -Property * -ExcludeProperty SideIndicator
        
        [Pool[]]$Variables.CommparePools = $ComparePools
        $Variables.PoolsCount = $Variables.Pools.Count

        #Add new pools
        If ($ComparePools) { 
            [Pool[]]$Variables.Pools += $ComparePools
        }

        #Update existing pools
        $Variables.Pools | ForEach-Object { 
            [Pool]$Pool = $null

            $_.Available = $true
            $_.Best = $false
            $_.Reason = $null

            $Pool = $NewPools | 
            Where-Object Name -eq $_.Name | 
            Where-Object Algorithm -eq $_.Algorithm | 
            Where-Object CoinName -eq $_.CoinName | 
            Where-Object Currency -eq $_.Currency | 
            Where-Object Protocol -eq $_.Protocol | 
            Where-Object Host -eq $_.Host | 
            Where-Object Port -eq $_.Port | 
            Where-Object User -eq $_.User | 
            Where-Object Pass -eq $_.Pass | 
            Where-Object SSL -eq $_.SSL | 
            Where-Object PayoutScheme -eq $_.PayoutScheme | 
            Select-Object -First 1

            If ($Pool) { 
                If ($Pool.EstimateCorrection -gt 0 -and $Pool.EstimateCorrection -lt 1) { $_.EstimateCorrection = $Pool.EstimateCorrection } Else { $_.EstimateCorrection = 1 } 
                If ($Config.IgnorePoolFee -or $Pool.Fee -lt 0 -or $PoolFee -gt 1) { $_.Fee = 0 } Else { $_.Fee = $Pool.Fee }
                $_.Price = $Pool.Price * $_.EstimateCorrection
                $_.Price_Bias = $Pool.Price * (1 - ($Pool.MarginOfError * $(If ($_.PayoutScheme -eq "PPLNS") { 1 } Else { 1 + $Config.RunningMinerGainPct }) * (1 - $Pool.Fee) * [Math]::Pow($Variables.DecayBase, $DecayExponent)))
                $_.Price_Unbias = $Pool.Price * (1 - $Pool.Fee)
                $_.StablePrice = $Pool.StablePrice
                $_.MarginOfError = $Pool.MarginOfError
                $_.Updated = $Pool.Updated
            }
        }
        Remove-Variable Pool

        # Filter Algo based on Per Pool Config
        $PoolsConfig = $Config.PoolsConfig #much faster
        $Variables.Pools | Where-Object Disabled -EQ $true | ForEach-Object { $_.Available = $false; $_.Reason += "Disabled (by Stat file)" }
        $Variables.Pools | Where-Object { $Config.SSL -NE "Preferred" -and $_.SSL -NE [Boolean]$Config.SSL } | ForEach-Object { $_.Available = $false; $_.Reason += "Config item SSL=$([Boolean]$Config.SSL)" }
        $Variables.Pools | Where-Object MarginOfError -gt (1 -$Config.MinAccuracy) | ForEach-Object { $_.Available = $false; $_.Reason += "MinAccuracy > $($Config.MinAccuracy)" }
        $Variables.Pools | Where-Object { $_.Name -notin $Config.PoolName } | ForEach-Object { $_.Available = $false; $_.Reason += "Pool not configured" }

        $Variables.Pools | Where-Object { "-$($_.Algorithm)" -in $Config.Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm disabled (-$($_.Algorithm)) in generic config" }
        $Variables.Pools | Where-Object { "-$($_.Algorithm)" -in $PoolsConfig.($_.Name).Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm disabled (-$($_.Algorithm)) in $($_.Name) pool config" }
        $Variables.Pools | Where-Object { "-$($_.Algorithm)" -in $PoolsConfig.Default.Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm disabled (-$($_.Algorithm)) in default pool config)" }
        $Variables.Pools | Where-Object { $Config.Algorithm -like "+*" } | Where-Object { "+$($_.Algorithm)" -notin $Config.Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm not Available in generic config" }
        $Variables.Pools | Where-Object { $PoolsConfig.($_.Name).Algorithm -like "+*" } | Where-Object { "+$($_.Algorithm)" -notin $PoolsConfig.($_.Name).Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm not Available in $($_.Name) pool config" }
        $Variables.Pools | Where-Object { $PoolsConfig.Default.Algorithm -like "+*" } | Where-Object { "+$($_.Algorithm)" -notin $PoolsConfig.Default.Algorithm } | ForEach-Object { $_.Available = $false; $_.Reason += "Algorithm not Available in default pool config" }

        $Variables.Pools | Where-Object { $Config.Pools.$($_.Name).ExcludeRegion -and (Compare-Object @($Config.Pools.$($_.Name).ExcludeRegion | Select-Object) @($_.Region) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { $_.Available = $false; $_.Reason += "Region excluded in $($_.Name) pool config" } 

        # Where-Object { -not $Config.PoolName -or (Compare-Object @($Config.PoolName | Select-Object) @($(for ($i = ($_.Name -split "-").Length; $i -ge 1; $i--) { ($_.Name -split "-" | Select-Object -First $i) -join "-" }) | Select-Object) -IncludeEqual -ExcludeDifferent) } | 
        # Where-Object { -not $Config.ExcludePoolName -or -not (Compare-Object @($Config.ExcludePoolName | Select-Object) @($(for ($i = ($_.Name -split "-").Length; $i -ge 1; $i--) { ($_.Name -split "-" | Select-Object -First $i) -join "-" }) | Select-Object) -IncludeEqual -ExcludeDifferent) } | 

        # Where-Object { -not $Config.CoinName -or (Compare-Object @($Config.CoinName | Select-Object) @($_.CoinName | Select-Object) -IncludeEqual -ExcludeDifferent) } | 
        # Where-Object { -not $Config.Pools.$($_.Name).CoinName -or (Compare-Object @($Config.Pools.$($_.Name).CoinName | Select-Object) @($_.CoinName | Select-Object) -IncludeEqual -ExcludeDifferent) } | 
        # Where-Object { -not $Config.ExcludeCoinName -or -not (Compare-Object @($Config.ExcludeCoinName | Select-Object) @($_.CoinName | Select-Object) -IncludeEqual -ExcludeDifferent) } | 
        # Where-Object { -not $Config.Pools.$($_.Name).ExcludeCoinName -or -not (Compare-Object @($Config.Pools.$($_.Name).ExcludeCoinName | Select-Object) @($_.CoinName | Select-Object) -IncludeEqual -ExcludeDifferent) } | 
        # Where-Object { -not $Config.CurrencySymbol -or (Compare-Object @($Config.CurrencySymbol | Select-Object) @($_.CurrencySymbol | Select-Object) -IncludeEqual -ExcludeDifferent) } | 
        # Where-Object { -not $Config.Pools.$($_.Name).CurrencySymbol -or (Compare-Object @($Config.Pools.$($_.Name).CurrencySymbol | Select-Object) @($_.CurrencySymbol | Select-Object) -IncludeEqual -ExcludeDifferent) } | 
        # Where-Object { -not $Config.ExcludeCurrencySymbol -or -not (Compare-Object @($Config.ExcludeCurrencySymbol | Select-Object) @($_.CurrencySymbol | Select-Object) -IncludeEqual -ExcludeDifferent) } | 
        # Where-Object { -not $Config.Pools.$($_.Name).ExcludeCurrencySymbol -or -not (Compare-Object @($Config.Pools.$($_.Name).ExcludeCurrencySymbol | Select-Object) @($_.CurrencySymbol | Select-Object) -IncludeEqual -ExcludeDifferent) } | 

        # Use location as preference and not the only one
        [Pool[]]$ThisRegionPools = $Variables.Pools | Where-Object { $_.Region -eq $Config.Region }
        $Variables.Pools = $ThisRegionPools + ($Variables.Pools | Where-Object { $_ -notin $ThisRegionPools })
        Remove-Variable ThisRegionPools

        Write-Message -Level VERBOSE "Had $($Variables.PoolsCount) pool$( If ($Variables.PoolsCount -ne 1) { "s" }), found $($ComparePools.Count) new pool$( If ($ComparePools.Count -ne 1) { "s" }). $(@($Variables.Pools | Where-Object Available -EQ $true).Count) pool$(If (@($Variables.Pools | Where-Object Available -EQ $true).Count -ne 1) { "s" }) remain$(If (@($Variables.Pools | Where-Object Available -EQ $true).Count -eq 1) { "s" }) (filtered out $(@($Variables.Pools | Where-Object Available -NE $true).Count) pool$(If (@($Variables.Pools | Where-Object Available -NE $true).Count -ne 1) { "s" }))."

        #If not all the live pool prices represent the same period of time then use historic pricing for the same period
        If (($Variables.Pools | Where-Object Available -EQ $true | Where-Object Price_Bias | Select-Object -ExpandProperty Name -Unique | ForEach-Object { $Variables.Pools | Where-Object Name -EQ $_ | Measure-Object Updated -Maximum | Select-Object -ExpandProperty Maximum } | Select-Object -Unique | Measure-Object -Minimum -Maximum | ForEach-Object { $_.Maximum - $_.Minimum }).TotalMinutes -gt $Config.SyncWindow) { 
            Write-Message -Level Warn "Pool prices are out of sync ($([Int]($Variables.Pools | Where-Object Price_Bias | Select-Object -ExpandProperty Name -Unique | ForEach-Object { $Variables.Pools | Where-Object Name -EQ $_ | Measure-Object Updated -Maximum | Select-Object -ExpandProperty Maximum} | Select-Object -Unique | Measure-Object -Minimum -Maximum | ForEach-Object { $_.Maximum - $_.Minimum }).TotalMinutes) minutes). "
            $Variables.Pools | Where-Object Price_Bias | ForEach-Object { $_.Price_Bias = $_.StablePrice }
        }

        # #Apply watchdog to pools
        # $Variables.Pools | Where-Object { ($WatchdogTimers | Where-Object PoolName -EQ $_.Name | Where-Object Kicked -LT $Timer.AddSeconds( - $WatchdogInterval) | Where-Object Kicked -GT $Timer.AddSeconds( - $WatchdogReset) | Measure-Object | Select-Object -ExpandProperty Count) -ge <#stage#>3 } | ForEach-Object { $_.Price_Bias = 0 }
        # $Variables.Pools | Where-Object { ($WatchdogTimers | Where-Object PoolName -EQ $_.Name | Where-Object Kicked -LT $Timer.AddSeconds( - $WatchdogInterval) | Where-Object Kicked -GT $Timer.AddSeconds( - $WatchdogReset) | Where-Object Algorithm -EQ $_.Algorithm | Measure-Object | Select-Object -ExpandProperty Count) -ge <#statge#>2 } | ForEach-Object { $_.Price_Bias = 0 }

        #Pre-sort all pools
        [Pool[]]$Variables.Pools = $Variables.Pools | Sort-Object -Descending { -not $_.Available }, { $_.StablePrice * (1 - $_.MarginOfError) }, { $_.Region -EQ $Config.Region }, { $_.SSL -EQ $Config.SSL }

        # Ensure we get the hashrate for running miners prior looking for best miner
        $Variables.Miners | Where-Object Best | ForEach-Object { 
            $Miner = $_
            If ($Miner.DataReaderJob.HasMoreData) { 
                $Miner.Data += @($Miner.DataReaderJob | Receive-Job | Select-Object -Property Date, HashRate, Shares, PowerUsage)
            }
            If ($Miner.Best -eq $true -and $Miner.GetStatus() -ne [MinerStatus]::Running -and $Miner.GetStatus() -ne $Miner.Status) { 
                Write-Message -Level ERROR "Miner '$($Miner.Info)' exited unexpectedly." 
                $Miner.SetStatus([MinerStatus]::Failed)
                $Miner.StatusMessage = "Exited unexpectedly."
            }
            If (($Miner.Data).Count) { 
                $Miner.Speed_Live = [Double[]]@()
                $PowerUsage = 0
                #Collect hashrate from miner
                $Miner_Speeds = [Hashtable]@{}
                $Miner.Algorithm | ForEach-Object { 
                    $Miner.Speed_Live += [Double]($Miner.CollectHashRate($_, $false))
                    $Miner_Speeds.$_ = ([Double]($Miner.CollectHashRate($_, ($Miner.New -and ($Miner.Data).Count -lt ($Miner.MinDataSamples)))))
                }
                If ($Variables.ReadPowerUsage) {
                    #Collect power usage from miner
                    $Miner.PowerUsage_Live = ([Double]($Miner.CollectPowerUsage($false)))
                    $PowerUsage = [Double]($Miner.CollectPowerUsage($Miner.New -and ($Miner.Data).Count -lt ($Miner.MinDataSamples)))
                }
                #Reduce data to MinDataSamples * 5
                If (($Miner.Data).Count -gt ($Miner.MinDataSamples * 5)) { 
                    Write-Message -Level VERBOSE "Reducing data samples for miner ($($Miner.Name)). Keeping the latest $($Miner.MinDataSamples * 5) samples."
                    $Miner.Data = $Miner.Data | Select-Object -Last ($Miner.MinDataSamples * 5)
                }
            }

            #We don't want to store hashrates if we have less than $MinDataSamples
            If (($Miner.Data).Count -ge $Miner.MinDataSamples -or ($Miner.New -and $Miner.Activated -ge 3)) { 
                $Miner.StatEnd = (Get-Date).ToUniversalTime()
                $Miner.Algorithm | ForEach-Object { 
                    $Miner_Algorithm = $_
                    $Stat_Name = "$($Miner.Name)_$($_)_HashRate"
                    If ($Miner.Activated -gt 0 -or $Stats.$Stat_Name) { #Do not save data if stat just got removed
                        Write-Message "Saving hash rate ($($Stat_Name): $(($Miner_Speeds.$Miner_Algorithm | ConvertTo-Hash) -replace ' '))$(If (-not $Stats.$Stat_Name) { " [Benchmark done]" })."
                        $Stat = Set-Stat -Name $Stat_Name -Value $Miner_Speeds.$Miner_Algorithm -Duration ($Miner.StatEnd - $Miner.StatStart) -FaultDetection (($Miner.Data).Count -lt $Miner.MinDataSamples)
                    }
                }

                If ($Variables.ReadPowerUsage -and $Variables.OldReadPowerUsage -eq $Variables.ReadPowerUsage) {
                    $Stat_Name = "$($Miner.Name)$(If ($Miner.Algorithm.Count -eq 1) { "_$($Miner.Algorithm | Select-Object -Index 0)" })_PowerUsage"
                    If ($Miner.Activated -gt 0 -or $Stats.$Stat_Name) { #Do not save data if stat just got removed
                        Write-Message "Saving power usage ($($Stat_Name): $(([Double]$PowerUsage).ToString("N2"))W)$(If (-not $Stats.$Stat_Name) { " [Power usage measurement done]" })."
                        $Stat = Set-Stat -Name $Stat_Name -Value $PowerUsage -Duration ($Miner.StatEnd - $Miner.StatStart) -FaultDetection (($Miner.Data).Count -lt $Miner.MinDataSamples)
                    }
                }
                Remove-Variable Stat_Name
                $Miner.Intervals += [TimeSpan]($Miner.StatEnd - $Miner.StatStart)
                $Miner.New = $false
                $Miner.StatStart = $Miner.StatEnd
                Remove-Variable Stat -ErrorAction Ignore
            }
        }

        If ((Test-Path .\Miners -PathType Container) -and (Test-Path ".\Config\MinersHash.json" -PathType Leaf)) { 
            Write-Message "Looking for miner files changes..."
            $Variables.MinersHash = Get-Content ".\Config\MinersHash.json" | ConvertFrom-Json
            Compare-Object @($Variables.MinersHash | Select-Object) @(Get-ChildItem .\Miners\ -filter "*.ps1" | Get-FileHash | Select-Object) -Property "Hash", "Path" | Sort-Object "Path" -Unique | ForEach-Object { 
                If (Test-Path $_.Path -PathType Leaf) { 
                    Write-Message "Miner Updated: $($_.Path)"
                    $UpdatedMiner = &$_.path
                    $UpdatedMiner.Name = (Get-Item $_.Path).BaseName
                    $Variables.Miners | Where-Object { $_.Path -eq (Resolve-Path $UpdatedMiner.Path) } | ForEach-Object { 
                        $Miner = $_
                        If ($Miner.Status -eq [MinerStatus]::Running -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                            Write-Message -Level ERROR "Miner '$Miner.Info' exited unexpectedly." 
                            $Miner.SetStatus([MinerStatus]::Failed)
                        }
                        Else { 
                            Write-Message "Stopping miner '$Miner.Info' for update..."
                            $Miner.SetStatus([MinerStatus]::Idle)
                        }
                    }
                    #Remove old binaries
                    Remove-Item -Force -Recurse (Split-Path $UpdatedMiner.Path)
                    #Trigger benchmark
                    Get-ChildItem -path ".\Stats\" -filter "$($UpdatedMiner.Name)_*.txt" | ForEach-Object { Remove-Stat ($_ -replace ".txt") } 
                }
                $Variables.MinersHash = Get-ChildItem .\Miners\ -filter "*.ps1" | Get-FileHash
                $Variables.MinersHash | ConvertTo-Json | Out-File ".\Config\MinersHash.json"
            }
        }

        #Get new miners
        Write-Message "Loading miners..."
        $Variables.Miners | ForEach-Object { 
            $_.CachedBenchmark = $_.Benchmark
            $_.CachedMeasurePowerUsage = $_.MeasurePowerusage
            $_.Reason = $null
        }

        $Pools = [PSCustomObject]@{ }
        #For leagacy miners
        Get-Stat | Out-Null
        $Variables.Pools | Where-Object Available -EQ $true | Select-Object -ExpandProperty Algorithm -Unique | ForEach-Object { $_.ToLower() } | Select-Object -Unique | ForEach-Object { 
            $BestAlgoPool = $Variables.Pools | Where-Object Available -EQ $true | Where-Object Algorithm -EQ $_ | Select-Object -First 1
            $Pools | Add-Member $_ $BestAlgoPool
            $BestAlgoPool.Best = $true
        }

        #Prepare devices
        $EnabledDevices = @($Variables.Devices | Where-Object { $_.State -EQ [DeviceState]::Enabled } | ConvertTo-Json -Depth 10 | ConvertFrom-Json)
        If (-not $Config.MinerInstancePerDeviceModel) { $EnabledDevices | ForEach-Object { $_.Model = $_.Vendor } } #Replace Model information from devices -> will create only one miner instance

        #Load miners
        $NewMiners = @()
        If ($Config.IncludeRegularMiners -and (Test-Path ".\Miners" -PathType Container)) { $NewMiners += Get-ChildItemContent ".\Miners" -Parameters @{ Pools = $Pools; Config = $Config; Variables = $Variables; Devices = $EnabledDevices } -Priority $(If ($Variables.Miners | Where-Object Status -EQ "Running" | Where-Object { $_.DeviceName -like "CPU#*" }) { "Normal" }) }
        If ($Config.IncludeOptionalMiners -and (Test-Path ".\OptionalMiners" -PathType Container)) { $NewMiners += Get-ChildItemContent ".\OptionalMiners" -Parameters @{ Pools = $Pools; Config = $Config; Variables = $Variables; Devices = $EnabledDevices } -Priority $(If ($Variables.Miners | Where-Object Status -EQ "Running" | Where-Object { $_.DeviceName -like "CPU#*" }) { "Normal" }) }
        If (Test-Path ".\CustomMiners" -PathType Container) { $NewMiners +=  Get-ChildItemContent ".\CustomMiners" -Parameters @{Pools = $Pools; Config = $Config; Variables = $Variables; Devices = $EnabledDevices } -Priority $(If ($Variables.Miners | Where-Object Status -EQ "Running" | Where-Object { $_.DeviceName -like "CPU#*" }) { "Normal" }) }

        If ($Config.IncludeLegacyMiners -and (Test-Path ".\LegacyMiners" -PathType Container)) { $NewMiners += Get-ChildItemContent ".\LegacyMiners" -Parameters @{Pools = $Pools; Stats = $Stats; Config = $Config; Devices = $EnabledDevices } -Priority $(If ($Variables.Miners | Where-Object Status -EQ "Running" | Where-Object { $_.DeviceName -like "CPU#*" }) { "Normal" }) }

        $NewMiners = $NewMiners | Select-Object  | Where-Object { $_.Content.Arguments } | ForEach-Object { 
            $Miner_Name = $(If ($_.Content.Name) { $_.Content.Name } Else { $_.Name })
            $Miner_Name = $Miner_Name -replace "^.", "$($Miner_Name[0])".ToUpper()
            If (-not $_.Content.Algorithm) { $_.Content | Add-Member Algorithm $_.Content.HashRates.PSObject.Properties.Name }
            If ($Config.IgnoreMinerFee) { $Miner_Fees = @($_.Content.HashRates.Count * @(0)) } Else { $Miner_Fees = @($_.Content.Fee) }
            [Worker[]]$Workers = @()
            $_.Content.Algorithm | ForEach-Object { 
                $Workers += @{
                    Pool = [Pool]$Pools.$_
                    Fee  = [Double]($Miner_Fees | Select-Object -Index $Workers.Count)
                }
            }
            $API = $_.Content.API

            [PSCustomObject]@{ 
                Name             = [String]$Miner_Name
                BaseName         = [String]($Miner_Name -split '-' | Select-Object -Index 0)
                Version          = [String]($Miner_Name -split '-' | Select-Object -Index 1)
                Path             = [String]$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($_.Content.Path)
                Algorithm        = [String[]]$_.Content.Algorithm
                Workers          = [Worker[]]$Workers
                Arguments        = $(If ($_.Content.Arguments -isnot [String]) { [String]($_.Content.Arguments | ConvertTo-Json -Depth 10 -Compress) } Else { [String]$_.Content.Arguments })
                DeviceName       = $(If ($_.Content.DeviceName) { [String[]]$_.Content.DeviceName } Else { [String[]]($_.Content.Type | ForEach-Object { Switch ($_) { "CPU" { ($Variables.Devices | Where-Object Type -EQ $_).Name } "AMD" { ($Variables.Devices | Where-Object Vendor -EQ $_).Name } "NVIDIA" { ($Variables.Devices | Where-Object Vendor -EQ $_).Name } } }) })
                Devices          = $(If ($_.Content.DeviceName) { [Device[]]($Variables.Devices | Where-Object Name -in $_.Content.DeviceName) } Else { [Device[]]($_.Content.Type | ForEach-Object { Switch ($_) { "CPU" { $Variables.Devices | Where-Object Type -EQ $_} "AMD" { $Variables.Devices | Where-Object Vendor -EQ $_ } "NVIDIA" { $Variables.Devices | Where-Object Vendor -EQ $_ } } }) })
                Port             = [UInt16]$_.Content.Port
                ShowMinerWindow  = [Boolean]($_.Content.API -ne "Wrapper" -and $Config.ShowMinerWindow) #Miner can be forced to be hidden, but not to be shown (wrapper)  
                Type             = $(If ($_.Content.Type) { [String[]]($_.Content.Type | Select-Object -Unique) } Else { ($_.Content.DeviceName | ForEach-Object { If ($_ -like "CPU*") { "CPU" } Else { ($Variables.Devices | Where-Object Name -eq $_).Vendor } }) })
                URI              = [String]$_.Content.URI
                PrerequisitePath = [String]$_.Content.PrerequisitePath
                WarmupTime       = $(If ($_.Content.WarmupTime -lt $Config.WarmupTime) { [Int]$Config.WarmupTime } Else { [Int]$_.Content.WarmupTime })
            } | Where-Object { ($Workers.Pool -notcontains $null) }
        } | ForEach-Object { $_ -as $API }
        Remove-Variable Pools

        $Variables.NewMiners = $NewMiners
        If (-not ($NewMiners)) { 
            Write-Message -Level Warn "No miners found."
            $Variables.EndLoop = $true
            Start-Sleep -Seconds 10
            Continue
        }

        $Variables.CompareMiners = Compare-Object -PassThru @($Variables.Miners | Select-Object) @($NewMiners | Select-Object) -Property Name, Path, Algorithm -IncludeEqual

        #Stop runing miners where miner file is gone
        $Variables.Miners | Where-Object { $_.SideIndicator -EQ "<=" -and $_.GetStatus() -eq [MinerStatus]::Running } | ForEach-Object { 
            Write-Message "Stopped miner '$($_.Info)'."
            $_.SetStatus([MinerStatus]::Idle)
        }

        #Remove gone miners
        [Miner[]]$Variables.Miners = $Variables.Miners | Where-Object SideIndicator -EQ "=="

        #Add new miners
        [Miner[]]$Variables.Miners += $Variables.CompareMiners | Where-Object SideIndicator -EQ "=>"

        #Update existing miners
        $Variables.Miners | ForEach-Object { 
            $_.Available = $false
            If ($Miner = Compare-Object -PassThru @($NewMiners | Select-Object) @($_ | Select-Object) -Property Name, Path, Algorithm -ExcludeDifferent) { 
                $_.Restart = [Boolean]($_.Arguments -ne $Miner.Arguments -or $_.Port -ne $Miner.Port -or $_.ShowMinerWindow -ne $Miner.ShowMinerWindow -or $Variables.OldReadPowerUsage -ne $Variables.ReadPowerUsage)
                $_.Arguments = $Miner.Arguments
                $_.Workers = $Miner.Workers
                $_.Port = $Miner.Port
                $_.ShowMinerWindow = $Miner.ShowMinerWindow
                $_.WarmupTime = $Miner.WarmupTime
                $_.Available = $true
            }
            $_.ReadPowerUsage = $Variables.ReadPowerUsage
            $_.Refresh($Stats, $Variables.PowerCostBTCperW)
            $_.MinDataSamples = $Config.MinDataSamples * (1, @($_.Algorithm | ForEach-Object { $Config.MinDataSamplesAlgoMultiplier.$_ }) | Measure-Object -Maximum).maximum
            $_.MeasurePowerUsage = [Boolean]($Variables.ReadPowerUsage -eq $true -and [Double]::IsNaN($_.PowerUsage))
            $_.AllowedBadShareRatio = $Config.AllowedBadShareRatio
        }
        Remove-Variable Miner

        $Variables.Miners | Where-Object Disabled -EQ $true | ForEach-Object { $_.Available = $false; $_.Reason += "Disabled (by Stat file)" }
        $Variables.Miners | Where-Object { $Config.Type.Count -gt 0 -and (Compare-Object @($Config.Type | Select-Object) @($_.Type | Select-Object) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -eq 0 } | ForEach-Object { $_.Available = $false; $_.Reason += "Type ($($_.Type)) not configured" }

        $Variables.Miners | Where-Object { $Config.ExcludeMinerName.Count -and (Compare-Object @($Config.ExcludeMinerName | Select-Object) @($_.BaseName, "$($_.BaseName)_$($_.Version)", $_.Name | Select-Object -Unique) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | ForEach-Object { $_.Available = $false; $_.Reason += "ExcludeMinerName: ($($Config.ExcludeMinerName -Join '; '))" }    
        $Variables.Miners | Where-Object { $Config.ExcludeDeviceName.Count -and (Compare-Object @($Config.ExcludeDeviceName | Select-Object) @($_.DeviceName | Select-Object)-IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | ForEach-Object { $_.Available = $false; $_.Reason += "ExcludeDeviceName: ($($Config.ExcludeDeviceName -Join '; '))" }

        $Variables.Miners | Where-Object { -not $_.PoolName } | ForEach-Object { $_.Available = $false; $_.Reason += "No pool for algorithm" }
        $Variables.Miners | Where-Object { $_.Earning -eq 0 } | ForEach-Object { $_.Available = $false; $_.Reason += "Earning = 0" }
        $Variables.Miners | Where-Object { ($Config.Algorithm | Where-Object { $_.StartsWith("+") }) -and (Compare-Object (($Config.Algorithm | Where-Object { $_.StartsWith("+") }).Replace("+", "")) $_.Algorithm -IncludeEqual -ExcludeDifferent | Measure-Object).Count -eq 0 } | ForEach-Object { $_.Available = $false; $_.Reason += "Config.ExcludeAlgorithm ($($_.Algorithm -join " & "))" }
        $Variables.Miners | Where-Object { $Config.NoSingleAlgoMining -and $_.Workers.Count -eq 1 } | ForEach-Object { $_.Available = $false; $_.Reason += "Config.NoSingleAlgoMining" }
        $Variables.Miners | Where-Object { $Config.NoDualAlgoMining -and $_.Workers.Count -eq 2 } | ForEach-Object { $_.Available = $false; $_.Reason += "Config.NoDualAlgoMining" }

        $Variables.MinersNeedingBenchmark = $Variables.Miners | Where-Object Benchmark -EQ $true
        $Variables.MinersNeedingPowerUsageMeasurement = $Variables.Miners | Where-Object MeasurePowerUsage -EQ $true

        If (-not ($Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerUsageMeasurement)) { 
            #Detect miners with unreal earning (> 5x higher than the next best 10% miners, error in data provided by pool?)
            $Variables.Miners | Group-Object -Property { $_.DeviceName } | ForEach-Object {
                $ReasonableEarning = [Double]($_.Group | Sort-Object -Descending Earning | Select-Object -Skip 1 -First ([Int]($VMiners.Count / 10 )) | Measure-Object Earning -Average).Average * 5
                $_.Group | Where-Object { $ReasonableEarning -gt 0 -and $_.Earning -le $ReasonableEarning } | Foreach-Object { $_.Available = $false; $_.Reason += "Unreal profit data"}
            }
            Remove-Variable ReasonableEarning -ErrorAction Ignore
        }

        $Variables.Miners | Where-Object { $_.Available -eq $true -and -not (Test-Path $_.Path -Type Leaf -ErrorAction Ignore) } | ForEach-Object { $_.Available = $false; $_.Reason += "Binary missing" }
        $Variables.Miners | Where-Object { $_.Available -eq $true -and $_.PrerequisitePath -and -not (Test-Path $_.PrerequisitePath -PathType Leaf -ErrorAction Ignore) } | ForEach-Object { $_.Available = $false; $_.Reason += "PreRequisite missing" }

        $Variables.MinersMissingBinary = $Variables.Miners | Where-Object Reason -contains "Binary missing"
        $Variables.MinersMissingPreRequisite = $Variables.Miners | Where-Object Reason -contains "PreRequisite missing"

        Get-Job | Where-Object { $_.State -eq "Completed" } | Remove-Job
        If ($Variables.MinersMissingBinary -or $Variables.MinersMissingPreRequisite) { 
            #Download miner binaries
            If ($Variables.Downloader.State -ne "Running") { 
                Write-Message -Level Warn "Some miners binaries are missing, starting downloader..."
                $Downloader_Parameters = @{
                    Logfile = $Variables.Logfile
                    DownloadList = @($Variables.MinersMissingPreRequisite | Select-Object @{ Name = "URI"; Expression = { $_.PrerequisiteURI } }, @{ Name = "Path"; Expression = { $_.PrerequisitePath } }, @{ Name = "Searchable"; Expression = { $false } }) + @($Variables.MinersMissingBinary | Select-Object URI, Path, @{ Name = "Searchable"; Expression = { $Miner = $_; ($Variables.Miners | Where-Object { (Split-Path $_.Path -Leaf) -eq (Split-Path $Miner.Path -Leaf) }).Count -eq 0 } }) | Select-Object * -Unique
                }
                $Variables.Downloader = Start-Job -Name Downloader -InitializationScript ([scriptblock]::Create("Set-Location '$($Variables.MainPath)'")) -ArgumentList $Downloader_Parameters -FilePath ".\Includes\Downloader.ps1"
                Remove-Variable Downloader_Parameters
            }
            ElseIf (-not ($Variables.Miners | Where-Object Available -EQ $true)) { 
                Write-Message "Waiting 30 seconds for downloader to install binaries..."
            }
        }

        If (-not ($Variables.Miners | Where-Object Available -EQ $true)) { 
            Write-Message -Level Warn "No miners available."
            $Variables.EndLoop = $true
            Start-Sleep -Seconds 30
            Continue
        }

        Write-Message -Level VERBOSE "Found $(($Variables.Miners).Count) miner$(If (($Variables.Miners).Count -ne 1) { "s" }), $(($Variables.Miners | Where-Object Available -EQ $true).Count) miner$(If (($Variables.Miners | Where-Object Available -EQ $true).Count -ne 1) { "s" }) remain$(If (($Variables.Miners | Where-Object Available -EQ $true).Count -eq 1) { "s" }) (filtered out $(($Variables.Miners | Where-Object Available -NE $true).Count) miner$(If (($Variables.Miners | Where-Object Available -NE $true).Count -ne 1) { "s" }))."

        If ($Config.OpenFirewallPorts) { 
            #Open firewall ports for all miners
            #temp fix, needs removing from loop as it requires admin rights
            If (Get-Command "Get-MpPreference" -ErrorAction Ignore) { 
                $ProgressPreferenceBackup = $ProgressPreference
                $ProgressPreference = "SilentlyContinue"
                If ((Get-Command "Get-MpComputerStatus" -ErrorAction Ignore) -and (Get-MpComputerStatus -ErrorAction Ignore)) { 
                    If (Get-Command "Get-NetFirewallRule" -ErrorAction Ignore) { 
                        $MinerFirewalls = Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program
                        If (@($Variables.Miners | Select-Object -ExpandProperty Path -Unique) | Compare-Object @($MinerFirewalls) | Where-Object SideIndicator -EQ "=>") { 
                            Start-Process (@{desktop = "powershell"; core = "pwsh" }.$PSEdition) ("-Command Import-Module '$env:Windir\System32\WindowsPowerShell\v1.0\Modules\NetSecurity\NetSecurity.psd1'; ('$(@($Variables.Miners | Select-Object -ExpandProperty Path -Unique) | Compare-Object @($MinerFirewalls) | Where-Object SideIndicator -EQ '=>' | Select-Object -ExpandProperty InputObject | ConvertTo-Json -Compress)' | ConvertFrom-Json) | ForEach-Object {New-NetFirewallRule -DisplayName (Split-Path `$_ -leaf) -Program `$_ -Description 'Inbound rule added by NemosMiner $($Variables.CurrentVersion) on $((Get-Date).ToString())' -Group 'Cryptocurrency Miner'}" -replace '"', '\"') -Verb runAs
                        }
                        Remove-Variable MinerFirewalls
                    }
                }
                $ProgressPreference = $ProgressPreferenceBackup
            }
        }

        Write-Message "Calculating earning$(If ($Variables.PowerPricekWh) { " and profit" }) for each miner$(If ($Variables.PowerPricekWh) { " (power cost $($Config.Currency | Select-Object -Index 0) $($Variables.PowerPricekWh)/kW⋅h)"})..."

        #Don't penalize active miners
        $Variables.Miners | Where-Object { $_.GetStatus() -eq [MinerStatus]::Running } | ForEach-Object { 
            $_.Earning_Bias = $_.Earning_Unbias
            $_.Profit_Bias = $_.Profit_Unbias
        }

        #Hack: temporarily make all earnings & Earnings positive, BestMiners_Combos(_Comparison) produces wrong sort order when earnings or Earnings are negative
        $SmallestEarningBias = [Double][Math]::Abs((($Variables.Miners | Where-Object Available -EQ $true | Where-Object { -not [Double]::IsNaN($_.Earning_Bias) }).Earning_Bias | Measure-Object -Minimum).minimum) * 2
        $SmallestProfitBias = [Double][Math]::Abs((($Variables.Miners | Where-Object Available -EQ $true | Where-Object { -not [Double]::IsNaN($_.Profit_Bias) }).Profit_Bias | Measure-Object -Minimum).minimum) * 2
        $Variables.Miners | Where-Object Available -EQ $true | ForEach-Object { $_.Earning_Bias += $SmallestEarningBias; $_.Profit_Bias += $SmallestProfitBias }

        If ($Variables.Miners.Count -eq 1) { 
            $BestMiners_Combo = @($Variables.Miners)
        }
        Else { 
            #Get most profitable miner combination i.e. AMD+NVIDIA+CPU
            If ($Variables.ReadPowerUsage -and (-not $Config.IgnorePowerCost)) { $SortBy = "Profit" } Else { $SortBy = "Earning" }
            $SortedMiners = $Variables.Miners | Where-Object Available -EQ $true | Sort-Object -Descending { $_.Benchmark -eq $true }, { $_.MeasurePowerUsage -eq $true }, { $_."$($SortBy)_Bias" }, { $_.Data.Count }, { $_.MinDataSamples } #pre-sort
            $FastestMiners = $SortedMiners | Select-Object DeviceName, Algorithm -Unique | ForEach-Object { $Miner = $_; ($SortedMiners | Where-Object { -not (Compare-Object $Miner $_ -Property DeviceName, Algorithm) } | Select-Object -First 1) } #use a smaller subset of miners
            $BestMiners = $FastestMiners | Select-Object DeviceName -Unique | ForEach-Object { $Miner = $_; ($FastestMiners | Where-Object { -not (Compare-Object $Miner $_ -Property DeviceName) } | Select-Object -First 1) }
            Remove-Variable SortBy

            $Miners_Device_Combos = Get-Combination ($Variables.Miners | Where-Object Available -EQ $true | Select-Object DeviceName -Unique) | Where-Object { (Compare-Object ($_.Combination | Select-Object -ExpandProperty DeviceName -Unique) ($_.Combination | Select-Object -ExpandProperty DeviceName) | Measure-Object).Count -eq 0 }

            $BestMiners_Combos = @(
                $Miners_Device_Combos | ForEach-Object { 
                    $Miner_Device_Combo = $_.Combination
                    [PSCustomObject]@{ 
                        Combination = $Miner_Device_Combo | ForEach-Object { 
                            $Miner_Device_Count = $_.DeviceName.Count
                            [Regex]$Miner_Device_Regex = "^(" + (($_.DeviceName | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ")$"
                            $BestMiners | Where-Object { ([Array]$_.DeviceName -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.DeviceName -match $Miner_Device_Regex).Count -eq $Miner_Device_Count }
                        }
                    }
                }
            )

            If ($Config.ReadPowerUsage -and (-not $Config.IgnorePowerCost)) { $SortBy = "Profit" } Else { $SortBy = "Earning" }
            $BestMiners_Combo = $BestMiners_Combos | Sort-Object -Descending { ($_.Combination | Where-Object { $_."$($Sortby)" -Like ([Double]::NaN) } | Measure-Object).Count }, { ($_.Combination | Measure-Object "$($SortBy)_Bias" -Sum).Sum },       { ($_.Combination | Where-Object { $_.SortBy -ne 0 } | Measure-Object).Count } | Select-Object -Index 0 | Select-Object -ExpandProperty Combination
            Remove-Variable SortBy
       
            Remove-Variable Miner_Device_Combo
            Remove-Variable Miners_Device_Combos
            Remove-Variable BestMiners
        }
        #Hack part 2: reverse temporarily forced positive earnings & Earnings
        $Variables.Miners | Where-Object Available -EQ $true | ForEach-Object { $_.Earning_Bias -= $SmallestEarningBias; $_.Profit_Bias -= $SmallestProfitBias }
        Remove-Variable SmallestEarningBias
        Remove-Variable SmallestProfitBias

        # No CPU mining if GPU miner prevents it
        If ($BestMiners_Combo.PreventCPUMining -contains $true) { 
            $BestMiners_Combo = $BestMiners_Combo | Where-Object { $_.Type -ne "CPU" }
            Write-Message "Miner prevents CPU mining"
        }

        $Variables.MiningProfit = [Double]($BestMiners_Combo | Measure-Object Profit -Sum).Sum
        $Variables.MiningEarning = [Double]($BestMiners_Combo | Measure-Object Earning -Sum).Sum
        $Variables.MiningPowerCost = [Double]($BestMiners_Combo | Measure-Object PowerCost -Sum).Sum

        #ProfitabilityThreshold check - OK to run miners?
        If ([Double]::IsNaN($Variables.MiningPowerCost) -or ($Variables.MiningEarning - $Variables.MiningPowerCost) -ge ($Config.ProfitabilityThreshold / $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -or $Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerUsageMeasurement) { 
            $BestMiners_Combo | ForEach-Object { $_.Best = $true }
        }
        Else { 
            Write-Message "Mining profit ($($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value [Double]($Variables.MiningEarning - $Variables.MiningPowerCost) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 1)) is below the configured threshold of $($Config.Currency | Select-Object -Index 0) $($Config.ProfitabilityThreshold.ToString("N$((Get-Culture).NumberFormat.CurrencyDecimalDigits)"))/day; mining is suspended until threshold is reached."
        }

        If ([Double]::IsNaN($Variables.MiningEarning)) { 
            $Variables.Summary = "1 BTC=$($Variables.Rates.BTC.$($Config.Currency | Select-Object -Index 0)) $($Config.Currency | Select-Object -Index 0)"
        }
        Else { 
            $Variables.Summary = "Estimated $(If (-not [Double]::IsNaN($Variables.MiningPowerCost)) { "Profit/day: $($Variables.MiningProfit * ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)))          " } )Earning/day: $($Variables.MiningEarning * ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)))          1 BTC=$($Variables.Rates."BTC".$($Config.Currency | Select-Object -Index 0)) $($Config.Currency | Select-Object -Index 0)"
        }

        #Also restart running miners (stop & start) when 
        # Data collector has died
        # Benchmark state changed
        # MeasurePowerUsage state changed
        # ReadPowerusage -> true -> done (to change data poll interval)
        $BestMiners_Combo | ForEach-Object { 
            If ($_.Activated -EQ -1) { 
                $_.Restart = $true
                $_.Data = @()
                $_.Activated = 0
            }
            If ($_.DataReaderJob.State -ne $_.GetStatus()) { $_.Restart = $true }
            If ($_.Benchmark -ne $_.CachedBenchmark) { $_.Restart = $true }
            If ($_.MeasurePowerUsage -ne $_.CachedMeasurePowerUsage) { $_.Restart = $true }
            If ($_.ReadPowerUsage -eq $false -and -$Variables.ReadPowerUsage) { $_.Restart = $true }
        }

        #Stop running miners
        $Variables.Miners | Where-Object Status -EQ "Running" | Where-Object { $_.Best -eq $false -or $_.Restart -eq $true } | ForEach-Object { 
            $Miner = $_
            If ($Miner.Status -eq [MinerStatus]::Running -and $Miner.GetStatus() -ne [MinerStatus]::Running) { 
                Write-Message -Level ERROR "Miner '$($Miner.Info)' exited unexpectedly." 
                $Miner.SetStatus([MinerStatus]::Failed)
            }
            Else { 
                Write-Message "Stopped miner '$($Miner.Info)'."
                $Miner.SetStatus([MinerStatus]::Idle)
                If ($Miner.ProcessId -and -not ($Variables.Miners | Where-Object { $_.Best -and $_.API -EQ $Miner.API })) { Stop-Process -Id $Miner.ProcessId -Force -ErrorAction Ignore } #temp fix

                #Remove watchdog timer
                $Miner.Algorithm | ForEach-Object { 
                    $Miner_Algorithm = $_
                    $WatchdogTimer = $Variables.WatchdogTimers | Where-Object { $_.MinerName -eq $Miner.Name -and $_.PoolName -eq $Variables.Pools.$Miner_Algorithm.Name -and $_.Algorithm -eq $Miner_Algorithm }
                    If ($WatchdogTimer) { 
                        If ($WatchdogTimer.Kicked -lt $Variables.Timer.AddSeconds( - $WatchdogInterval)) { 
                            $Miner.SetStatus([MinerStatus]::Failed)
                            $Miner.StatusMessage = " was temporarily disabled by watchdog"
                            Write-Message -Level Warn "Watchdog: Miner '$Miner_Info' temporarily disabled."
                        }
                        Else { 
                            $Variables.WatchdogTimers = @($Variables.WatchdogTimers -notmatch $WatchdogTimer)
                        }
                    }
                }
            }
        }

        #Kill stray miners
        Get-CIMInstance CIM_Process | Where-Object ExecutablePath | Where-Object { [String[]]($Variables.Miners.Path | Sort-Object -Unique) -contains $_.ExecutablePath } | Where-Object { ($Variables.Miners).ProcessID -notcontains $_.ProcessID } | Select-Object -ExpandProperty ProcessID | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction Ignore }

        #Put here in case the port range has changed
        Initialize-API

        $Variables.Miners | Where-Object Best -EQ $true | ForEach-Object { 
            $Miner = $_
            If ($Miner.GetStatus() -ne [MinerStatus]::Running) { 
                # Launch prerun if exists
                If ($Miner.Type -eq "AMD" -and (Test-Path ".\Utils\Prerun\AMDPrerun.bat" -PathType Leaf)) { 
                    Start-Process ".\Utils\Prerun\AMDPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                }
                If ($Miner.Type -eq "NVIDIA" -and (Test-Path ".\Utils\Prerun\NVIDIAPrerun.bat" -PathType Leaf)) { 
                    Start-Process ".\Utils\Prerun\NVIDIAPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                }
                If ($Miner.Type -eq "CPU" -and (Test-Path ".\Utils\Prerun\CPUPrerun.bat"-PathType Leaf)) { 
                    Start-Process ".\Utils\Prerun\CPUPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                }
                If ($Miner.Type -eq "CPU") { 
                    $PrerunName = ".\Utils\Prerun\$($Miner.Algorithm).bat"
                    $DefaultPrerunName = ".\Utils\Prerun\default.bat"
                    If (Test-Path $PrerunName -PathType Leaf) { 
                        Write-Message "Launching Prerun: $PrerunName"
                        Start-Process $PrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                    ElseIf (Test-Path $DefaultPrerunName -PathType Leaf) { 
                        Write-Message "Launching Prerun: $DefaultPrerunName"
                        Start-Process $DefaultPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                        Start-Sleep -Seconds 2
                    }
                }
                $Miner.SetStatus([MinerStatus]::Running)   
                Write-Message "Started miner '$($Miner.Info)'."
                Write-Message -Level Verbose $Miner.GetCommandLine().Replace("$(Convert-Path '.\')\", "")

                # Log switching information to .\Logs\switching.log
                [PSCustomObject]@{ Date = (Get-Date); "Type" = $($Miner.Type -join " & "); "Miner" = $Miner.Info; "Account" = (($Miner.Workers.Pool.User | ForEach-Object { $_ -split '\.' | Select-Object -Index 0 } | Select-Object -Unique) -join '; '); "CommandLine" = $Miner.GetCommandLine() } | Export-Csv .\Logs\switching.log -Append -NoTypeInformation
                [PSCustomObject]@{ Date = [String](Get-Date -Format s); "Device" = $(($Miner.Devices.Name | Sort-Object)-join "; "); "Miner" = $Miner.Info; "Account" = (($Miner.Workers.Pool.User | ForEach-Object { $_ -split '\.' | Select-Object -Index 0 } | Select-Object -Unique) -join '; '); "Earning" = ($_.Earning); "Profit" = ($_.Profit); "CommandLine" = $Miner.GetCommandLine() } | Export-Csv .\Logs\switching2.log -Append -NoTypeInformation
            }
        }

        $Variables.Miners | Where-Object Best -eq $true | ForEach-Object { 
            $Message = ""
            If ($_.Benchmark -eq $true) { $Message = "Benchmark " }
            If ($_.Benchmark -eq $true -and $_.MeasurePowerUsage -eq $true) { $Message = "$($Message)and "}
            If ($_.MeasurePowerUsage -eq $true) { $Message = "$($Message)Power usage measurement " }
            If ($Message) { Write-Message -Level  Verbose "$($Message)for miner '$($_.Info)' in progress [Attempt $($Miner.Activated)/3]..." }
        }

        "--------------------------------------------------------------------------------" | Out-Host

        $Error.Clear()

        Get-Job | Where-Object State -EQ "Completed" | Remove-Job

        If ($Variables.BrainJobs.count -gt 0) { 
            $Variables.BrainJobs | ForEach-Object { $_.ChildJobs | ForEach-Object { $_.Error.Clear() } }
            $Variables.BrainJobs | ForEach-Object { $_.ChildJobs | ForEach-Object { $_.Progress.Clear() } }
            $Variables.BrainJobs.ChildJobs | ForEach-Object { $_.Output.Clear() }
        }
        If ($Variables.EarningsTrackerJobs.count -gt 0) { 
            $Variables.EarningsTrackerJobs | ForEach-Object { $_.ChildJobs | ForEach-Object { $_.Error.Clear() } }
            $Variables.EarningsTrackerJobs | ForEach-Object { $_.ChildJobs | ForEach-Object { $_.Progress.Clear() } }
            $Variables.EarningsTrackerJobs.ChildJobs | ForEach-Object { $_.Output.Clear() }
        }

        If ($Variables.Miners | Where-Object Status -EQ "Running") { Write-Message "Collecting miner data while waiting for next cycle..." }

        #Cache pools config for next cycle
        $Variables.PoolsConfigCached = $Config.PoolsConfig

        # Mostly used for debug. Will execute code found in .\EndLoopCode.ps1 if exists.
        If (Test-Path ".\EndLoopCode.ps1" -PathType Leaf) { Invoke-Expression (Get-Content ".\EndLoopCode.ps1" -Raw) }
    }

    $Variables.StatusText = "Waiting $($Variables.TimeToSleep) seconds... | Next refresh: $((Get-Date).AddSeconds($Variables.TimeToSleep).ToString('g'))"
    $Variables.EndLoop = $true
    TimerUITick
}

$ProgressPreference = "SilentlyContinue"

If (Test-Path ".\Includes\APIs" -PathType Container -ErrorAction Ignore) { Get-ChildItem ".\Includes\APIs" -File | ForEach-Object { . $_.FullName } }

While ($true) { 
    If ($Variables.Paused) { 
        # Run a dummy cycle to keep the UI updating.
        $Variables.EndLoopTime = ((Get-Date).AddSeconds($Config.Interval))

        # Keep updating exchange rate
        Get-Rates
        $Variables.Summary = "1 BTC=$($Variables.Rates.BTC.$($Config.Currency | Select-Object -Index 0)) $($Config.Currency | Select-Object -Index 0)"

        # Update the UI every 30 seconds, and the Last 1/6/24hr and text window every 2 minutes
        For ($i = 0; $i -lt 4; $i++) { 
            If ($i -eq 3) { 
                $Variables.EndLoop = $true
                Update-Monitoring
            }
            Else { 
                $Variables.EndLoop = $false
            }

            $Variables.StatusText = "Mining paused"
            Start-Sleep -Seconds 30
        }
    }
    Else { 
        # Purge logs more than 10 days
        Get-ChildItem ".\Logs\CoreCyle-*.log" | Sort-Object LastWriteTime | Select-Object -Skip 10 | Remove-Item -Force -Recurse

        Start-Cycle
        Update-Monitoring

        TimerUITick

        #End loop when
        # - a miner crashed
        # - all benchmarking miners have collected enough samples
        # - warmuptime is up
        # - timeout is reached (no readout from miner)
        $InitialActiveMiners = $ActiveMiners = $Variables.Miners | Where-Object Best -EQ $true | Sort-Object -Descending { $_.Benchmark }, { $_.MeasurePowerUsage }
        $BenchmarkingOrMeasuringMiners = @($ActiveMiners | Where-Object { $_.Benchmark -eq $true -or $_.MeasurePowerUsage -eq $true })
        If ($BenchmarkingOrMeasuringMiners) { $Interval = 2 } Else { $Interval = 5 }

        While ((Get-Date) -lt $Variables.EndLoopTime -or ($BenchmarkingOrMeasuringMiners | Where-Object Activated -GT 0)) {
            $NextLoop = (Get-Date).AddSeconds($Interval)
            $ActiveMiners | ForEach-Object { 
                $Miner = $_
                If ($_.DataReaderJob.HasMoreData) { 
                    $_.Data += $Samples = @($_.DataReaderJob | Receive-Job | Select-Object) 
                    $Sample = @($Samples) | Select-Object -Last 1
                    If ($Sample) { Write-Message -Level Verbose "$($_.Name) data sample retrieved: [$(($Sample.Hashrate.PSObject.Properties.Name | ForEach-Object { "$_ = $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(If ($Miner.AllowedBadShareRatio) { ", Shares Total = $($Sample.Shares.$_[2]), Rejected = $($Sample.Shares.$_[1])" })" }) -join ' & ')$(If ($Sample.PowerUsage) { " / Power = $($Sample.PowerUsage.ToString("N2"))W" })] ($(($_.Data).Count) sample$(If (($_.Data).Count -ne 1) { "s"} ))" }
                }
                If ($_.GetStatus() -ne [MinerStatus]::Running) { 
                    #Miner crashed
                    Write-Message -Level ERROR "Miner '$($_.Info)' exited unexpectedly." 
                    $_.SetStatus([MinerStatus]::Failed)
                    $_.StatusMessage = "Exited unexpectedly."
                }
                ElseIf ($_.DataReaderJob.State -ne [MinerStatus]::Running) { 
                    #Miner data reader process failed
                    Write-Message -Level ERROR "Miner data reader '$($_.Info)' exited unexpectedly." 
                    $_.SetStatus([MinerStatus]::Failed)
                    $_.StatusMessage = "Miner data reader exited unexpectedly."
                }
                ElseIf (((Get-Date) - $_.Process.PSBeginTime).TotalSeconds -gt $_.WarmupTime -and ($_.Data.Date | Select-Object -Last 1) -lt (Get-Date).AddSeconds(-$_.WarmupTime).ToUniversalTime()) { 
                    #Miner is stuck - no data for > $WarmupTime seconds
                    Write-Message -Level ERROR "Miner '$($_.Info)' got stopped because it has not updated data for $($_.WarmupTime) seconds."
                    $_.SetStatus([MinerStatus]::Failed)
                    $_.StatusMessage = "Has not updated data for $($_.WarmupTime) seconds"
                }
            }

            $FailedMiners = $ActiveMiners | Where-Object { $_.GetStatus() -ne [MinerStatus]::Running }
            $ActiveMiners = $ActiveMiners | Where-Object { $_.GetStatus() -eq [MinerStatus]::Running }
            $BenchmarkingOrMeasuringMiners = @($BenchmarkingOrMeasuringMiners | Where-Object { $_.GetStatus() -eq [MinerStatus]::Running })

            If ($FailedMiners -and -not $BenchmarkingOrMeasuringMiners) { 
                #A miner crashed and we're not benchmarking, end the loop now
                $Variables.EndLoop = $true
                $Message = "Miner failed. "
                Break
            }
            ElseIf ($BenchmarkingOrMeasuringMiners -and (-not ($BenchmarkingOrMeasuringMiners | Where-Object { ($_.Data).Count -lt ($Config.MinDataSamples) }))) { 
                #Enough samples collected for this loop, exit loop immediately
                $Message = "All$(If ($BenchmarkingOrMeasuringMiners | Where-Object Benchmark -EQ $true) { " benchmarking" })$(If ($BenchmarkingOrMeasuringMiners | Where-Object { $_.Benchmark -eq $true -and $_.MeasurePowerUsage -eq $true }) { " and" } )$(If ($BenchmarkingOrMeasuringMiners | Where-Object MeasurePowerUsage -EQ $true) { " power usage measuring" }) miners have collected enough samples for this cycle. "
                Break
            }
            ElseIf ($InitialActiveMiners -and (-not $ActiveMiners)) { 
                #No more running miners, end the loop now
                $Variables.EndLoop = $true
                $Message = "No more running miners. "
                Break
            }

            While ((Get-Date) -lt $NextLoop) { Start-Sleep -Milliseconds 200 }
        }
        Write-Message -Level VERBOSE "$($Message)Ending cycle."
        Remove-Variable Message -ErrorAction SilentlyContinue
        Remove-Variable ActiveMiners -ErrorAction SilentlyContinue
        Remove-Variable InitialActiveMiners -ErrorAction SilentlyContinue
        Remove-Variable FailedMiners -ErrorAction SilentlyContinue
        Remove-Variable BenchmarkingMiners -ErrorAction SilentlyContinue
        Update-Monitoring
    }
}
