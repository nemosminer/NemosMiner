<#
Copyright (c) 2018-2020 Nemo & MrPlus

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           Core.ps1
version:        3.8.1.3
version date:   11 February 2020
#>



Function Start-NPMCycle { 
    $CycleTime = Measure-Command -Expression { 

        Set-Location $Variables.MainPath

        $Variables | Add-Member -Force @{ EndLoop = $False }

        Get-Config $Variables.ConfigFile

        Write-Message "Starting Cycle"
        $DecayExponent = [Int](((Get-Date).ToUniversalTime() - $Variables.DecayStart).TotalSeconds / $Variables.DecayPeriod)

        #Select configured devices
        $Variables | Add-Member -Force @{ ConfiguredDevices = @($Variables.Devices | Where-Object { $_.Type -in $Config.Type -or $_.Vendor -in $Config.Type }) }

        # Read stats
        Get-Stat

        #Activate or deactivate donation
        If ((Get-Date).AddDays(-1).AddMinutes($Config.Donate) -ge $Variables.LastDonated -and $Variables.DonateRandom.wallet -eq $Null) { 
            # Get donation addresses randomly from agreed developers list
            # This will fairly distribute donations to Developers
            # Developers list and wallets is publicly available at: https://nemosminer.com/data/devlist.json & https://raw.githubusercontent.com/Minerx117/UpDateData/master/devlist.json
            Try { 
                $Donation = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/UpDateData/master/devlist.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
            }
            Catch { 
                $Donation = @([PSCustomObject]@{ Name = "nemo"; Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"; UserName = "nemo" }, [PSCustomObject]@{ Name = "mrplus"; Wallet = "134bw4oTorEJUUVFhokDQDfNqTs7rBMNYy"; UserName = "mrplus" })
            }
            If ($Donation -ne $null) { 
                If ($Config.Donate -lt 3) { $Config.Donate = (0, (3..8)) | Get-Random }
                $Variables.DonateRandom = $Donation | Get-Random
                $Config | Add-Member -Force @{ PoolsConfig = [PSCustomObject]@{ default = [PSCustomObject]@{ Wallet = $Variables.DonateRandom.Wallet; UserName = $Variables.DonateRandom.UserName; WorkerName = "$($Variables.CurrentProduct)$($Variables.CurrentVersion.ToString().replace('.',''))"; PricePenaltyFactor = 1 } } }
            }
        }
        If (((Get-Date).AddDays(-1) -ge $Variables.LastDonated -and $Variables.DonateRandom.Wallet -ne $Null) -or (-not $Config.PoolsConfig)) { 
            $Config | Add-Member -Force -MemberType ScriptProperty -Name "PoolsConfig" -Value { 
                If (Test-Path ".\Config\PoolsConfig.json" -PathType Leaf) { 
                    Get-Content ".\Config\PoolsConfig.json" | ConvertFrom-Json
                }
                Else { 
                    [PSCustomObject]@{ default = [PSCustomObject]@{ 
                            Wallet      = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"
                            UserName    = "nemo"
                            WorkerName  = "NemosMinerNoCfg"
                            PoolPenalty = 1
                        }
                    }
                }
            }
            $Variables.LastDonated = Get-Date
            $Variables.DonateRandom = [PSCustomObject]@{ }
        }

        Write-Message "Loading BTC rate from 'min-api.cryptocompare.com'..."
        Get-Rates

        #Power cost preparations
        $Variables | Add-Member -Force @{ MeasurePowerUsage = $false } #$MeasurePowerUsage is an operational variable and not identical to $Config.MeasurePowerUsage
        If (($Variables.ConfiguredDevices).Count -and $Config.MeasurePowerUsage) { 
            #HWiNFO64 verification
            $RegKey = "HKCU:\Software\HWiNFO64\VSB"
            $OldRegistryValue = $RegistryValue
            If ($RegistryValue = Get-ItemProperty -Path $RegKey -ErrorAction SilentlyContinue) { 
                If ([String]$OldRegistryValue -eq [String]$RegistryValue) { 
                    Write-Message -Level Warn "Power usage info in registry has not been updated [HWiNFO64 not running???] - power cost calculation is not available. "
                    $Variables.MeasurePowerUsage = $false
                }
                Else { 
                    $Variables.MeasurePowerUsage = $true
                    $Hashtable = @{ }
                    $Device = ""
                    $RegistryValue.PsObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @(($Variables.ConfiguredDevices).Name | Select-Object) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                        $Device = ($_.Value -split ' ') | Select-Object -last 1
                        Try { 
                            $Hashtable.Add($Device, $RegistryValue.($_.Name -replace "Label", "Value"))
                        }
                        Catch { 
                            Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [duplicate sensor for $Device] - disabling power usage calculations."
                            $Variables.MeasurePowerUsage = $false
                        }
                    }
                    If (($Variables.ConfiguredDevices).Name | Where-Object { $Hashtable.$_ -eq $null }) { 
                        Write-Message -Level Warn "HWiNFO64 sensor naming is invalid [missing sensor config for $((($Variables.AllDevices).Name | Where-Object { $Hashtable.$_ -eq $null }) -join ', ')] - disabling power usage calculations."
                        $Variables.MeasurePowerUsage = $false
                    }
                    Remove-Variable Device
                    Remove-Variable HashTable
                }
            }
            Else { 
                Write-Message -Level Warn "Cannot read power usage info from registry [Key '$($RegKey)' does not exist - HWiNFO64 not running???] - disabling power usage calculations."
                $Variables.MeasurePowerUsage = $false
            }
        }
        If ($Config.MeasurePowerUsage -and -not ($Variables.MeasurePowerUsage)) { 
            Write-Message -Level Warn "Realtime power usage cannot be read from system. Will use static values where available."
        }

        #Power price
        If (-not ($Config.PowerPricekWh | Sort-Object | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) { 
            $Config | Add-Member @{ PowerPricekWh = [PSCustomObject]@{ "00:00" = 0 } }
        }
        If ($null -eq $Config.PowerPricekWh."00:00") { 
            #00:00h power price is the same as the latest price of the previous day
            $Config.PowerPricekWh | Add-Member "00:00" ($Config.PowerPricekWh.($Config.PowerPricekWh | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Sort-Object | Select-Object -Last 1))
        }
        $Variables | Add-Member -Force @{ PowerPricekWh = [Double]($Config.PowerPricekWh.($Config.PowerPricekWh | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Sort-Object | Where-Object { $_ -lt (Get-Date -Format HH:mm).ToString() } | Select-Object -Last 1)) }
        $Variables | Add-Member -Force @{ PowerCostBTCperW = [Double](1 / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates.($Config.Currency | Select-Object -Index 0)) }
        $Variables | Add-Member -Force @{ BasePowerCost = [Double]($Config.IdlePowerUsageW / 1000 * 24 * $Variables.PowerPricekWh / $Variables.Rates.($Config.Currency | Select-Object -Index 0)) }

        #Get pool data
        $PoolFilter = @()
        $Config.PoolName | ForEach-Object { $PoolFilter += ($_ += ".*") }
        Write-Message "Loading stats for pool$(If ($PoolFilter.Count -ne 1) { "s" }) $(($Config.PoolName | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) }) -join ', ')..."
        Do {
            $AllPools = If (Test-Path ".\Pools" -PathType Container) { 
                Get-ChildItemContent ".\Pools" -Include $PoolFilter | ForEach-Object { $_.Content | Add-Member @{Name = $_.Name } -PassThru } | Where-Object { 
                    $_.SSL -EQ $Config.SSL -and 
                    ($Config.PoolName.Count -eq 0 -or ($_.Name -in $Config.PoolName)) -and 
                    (-not $Config.Algorithm -or ((-not ($Config.Algorithm | Where-Object { $_ -like "+*" }) -or $_.Algorithm -in ($Config.Algorithm | Where-Object { $_ -like "+*" }).Replace("+", "")) -and (-not ($Config.Algorithm | Where-Object { $_ -like "-*" }) -or $_.Algorithm -notin ($Config.Algorithm | Where-Object { $_ -like "-*" }).Replace("-", ""))) )
                }
            }
            If ($AllPools.Count -eq 0) { 
                Write-Message "Error contacting pool retrying in 30 seconds..."
                Start-Sleep -Seconds 30
            }
        } While ($AllPools.Count -eq 0)

        Write-Message "Computing pool stats..."
        # Use location as preference and not the only one
        $LocPools = @($AllPools | Where-Object { $_.Location -eq $Config.Location })
        $AllPools = $LocPools + @($AllPools | Where-Object { $_.name -notin $LocPools.name })
        Remove-Variable LocPools

        # Filter Algo based on Per Pool Config
        $PoolsConf = $Config.PoolsConfig
        $AllPools = $AllPools | Where-Object { $_.Name -notin ($PoolsConf | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -or ($_.Name -in ($PoolsConf | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) -and ((-not ( $PoolsConf.($_.Name).Algorithm | Where-Object { $_ -like "+*" }) -or ("+$($_.Algorithm)" -in $PoolsConf.($_.Name).Algorithm)) -and ("-$($_.Algorithm)" -notin $PoolsConf.($_.Name).Algorithm))) }

# Debug/dev only!
# $AllPools | Foreach-Object { 
#     $_ | Add-Member -Force Fee (Get-Random  -Minimum 0 -Maximum 0.07)
#     $_ | Add-Member -Force Coin "BlaCoin"
# }

        $Variables.AllPools = $AllPools

        $Global:Pools = [PSCustomObject]@{ }
        $Global:Pools_Comparison = [PSCustomObject]@{ }
        $AllPools.Algorithm | Sort-Object -Unique | ForEach-Object { 
            $Pools | Add-Member $_ ($AllPools | Where-Object Algorithm -EQ $_ | Sort-Object Price -Descending | Select-Object -First 1)
            $Pools_Comparison | Add-Member $_ ($AllPools | Where-Object Algorithm -EQ $_ | Sort-Object StablePrice -Descending | Select-Object -First 1)
        }

        $Variables | Add-Member -Force @{ StatEnd = (Get-Date).ToUniversalTime() }

        # Ensure we get the hashrate for running miners prior looking for best miner
        $Variables.ActiveMiners | ForEach-Object { 
            $Miner = $_
            If ($_.Process -eq $null -or $_.Process.HasExited) { 
                If ($_.Status -eq "Running") { $_.Status = "Failed" }
            }
            Else { 
                If ($Miner.DataReaderJob.HasMoreData) { 
                    $Miner.Data += @($Miner.DataReaderJob | Receive-Job)
                }
                If (($Miner.Data).Count) { 
                    #Read hashrate from miner
                    $Miner.HashRates = @()
                    $Miner.Pools.PSObject.Properties.Value.Algorithm | ForEach-Object { 
                        $Miner.HashRates += @{ $_ = (Get-HashRate -Data $Miner.Data -Algorithm $_ -Safe ($Miner.New -and ($Miner.Data).Count -lt ($Config.MinHashRateSamples * $Miner.IntervalMultiplier))) }
                    }
                    #Read power usage from miner
                    $Miner | Add-Member -Force PowerUsage (Get-PowerUsage -Data $Miner.Data -Safe ($Miner.New -and ($Miner.Data).Count -lt ($Config.MinHashRateSamples * $Miner.IntervalMultiplier)))
                }
                $Miner.Intervals ++

                # we don't want to store hashrates if we have less than $MinHashRateSamples
                If (($Miner.Data).Count -ge ($Config.MinHashRateSamples * $Miner.IntervalMultiplier) -or $Miner.DataReaderJob.State -ne "Running" -or $Miner.Intervals -ge $Miner.IntervalMultiplier) { 
                    If ($Miner.New) { $Miner.Benchmarked++ }
                    $Miner.Pools.PSObject.Properties.Value.Algorithm | ForEach-Object { 
                        Write-Message "Saving hash rate ($($Miner.Name)_$($_)_HashRate: $(($Miner.HashRates.$_ | ConvertTo-Hash) -replace ' '))$(If (-not $Stats."$($Miner.Name)_$($_)_HashRate") { " [Benchmark done]" })."
                        $Stat = Set-Stat -Name "$($Miner.Name)_$($_)_HashRate" -Value $Miner.HashRates.$_ -Duration ((Get-Date).ToUniversalTime() - $Miner.StatStart) -FaultDetection $true
                    }

                    If ($Miner.PowerUsage) { 
                        Write-Message "Saving power usage ($($Miner.Name -split '-' | Select-Object -Index 0)_$($Miner.Pools.PSObject.Properties.Value.Algorithm -join '-')_PowerUsage: $($Miner.PowerUsage.ToString("N2"))W)$(If (-not $Stats."$($_.Name -split '-' | Select-Object -Index 0)_$($Miner.Pools.PSObject.Properties.Value.Algorithm -join '-')_PowerUsage") { " [Power usage measurement done]" })."
                        $Stat = Set-Stat -Name "$($Miner.Name -split '-' | Select-Object -Index 0)_$($Miner.Pools.PSObject.Properties.Value.Algorithm -join '-')_PowerUsage" -Value $Miner.PowerUsage -Duration ((Get-Date).ToUniversalTime() - $Miner.StatStart) -FaultDetection $true
                    }

                    $Miner.New = $false
                    $Miner.StatStart = (Get-Date).ToUniversalTime()
                    $Miner.Hashrate_Gathered = $true
                }
            }
        }

        If ((Test-Path ".\Config\MinersHash.json" -PathType Leaf) -and (Test-Path .\Miners -PathType Container)) { 
            Write-Message "Looking for miner files changes..."
            $MinersHash = Get-Content ".\Config\MinersHash.json" | ConvertFrom-Json
            Compare-Object @($MinersHash | Select-Object) @(Get-ChildItem .\Miners\ -filter "*.ps1" | Get-FileHash | Select-Object) -Property "Hash", "Path" | Sort-Object "Path" -Unique | ForEach-Object { 
                If (Test-Path $_.Path -PathType Leaf) { 
                    Write-Message "Miner Updated: $($_.Path)"
                    $UpdatedMiner = &$_.path
                    $UpdatedMiner | Add-Member -Force @{ Name = (Get-Item $_.Path).BaseName }
                    $Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" -and $_.Path -eq (Resolve-Path $UpdatedMiner.Path) } | ForEach-Object { 
                        $Miner = $_
                        [Array]$Filtered = ($BestMiners_Combo | Where-Object Path -EQ $Miner.Path | Where-Object Arguments -EQ $Miner.Arguments)
                        If ($Filtered.Count -eq 0) { 
                            If ($_.Process -eq $null) { 
                                $_.Status = "Failed"
                            }
                            ElseIf ($_.Process.HasExited -eq $false) { 
                                Write-Message "Stopping miner ($($Miner.Name)) {$(($Miner.Pools.PSObject.Properties.Value | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join '; ')} for update."
                                $_.Process.CloseMainWindow() | Out-Null
                                Start-Sleep 1
                                # simply "Kill with power"
                                Stop-Process $_.Process -Force | Out-Null
                                Start-Sleep 1
                                $_.Status = "Idle"
                            }
                            #Restore Bias for non-active miners
                            $Variables.Miners | Where-Object Path -EQ $Miner.Path | Where-Object Arguments -EQ $Miner.Arguments | ForEach-Object { $_.Earning_Bias = $_.Earning_Bias_Orig; $_.Profit_Bias = $_.Profit_Bias_Orig }

                            # Stop data reader 
                            $Miner.DataReaderJob | Stop-Job -ErrorAction Ignore | Remove-Job -ErrorAction Ignore
                        }
                    }
                    Get-ChildItem -path ".\Stats\" -filter "$($UpdatedMiner.Name)_*.txt" | Remove-Item -Force -Recurse
                    Remove-Item -Force -Recurse (Split-Path $UpdatedMiner.Path)
                }
                $MinersHash = Get-ChildItem .\Miners\ -filter "*.ps1" | Get-FileHash
                $MinersHash | ConvertTo-Json | Out-File ".\Config\MinersHash.json"
            }
        }

        Write-Message "Loading miners..."
        $Variables | Add-Member -Force @{ Miners = @() }
        $Variables.Miners = @(
            If ($Config.IncludeRegularMiners -and (Test-Path ".\Miners" -PathType Container)) { Get-ChildItemContent ".\Miners" }
            If ($Config.IncludeOptionalMiners -and (Test-Path ".\OptionalMiners" -PathType Container)) { Get-ChildItemContent ".\OptionalMiners" }
            If (Test-Path ".\CustomMiners" -PathType Container) { Get-ChildItemContent ".\CustomMiners" }
        ) | Select-Object | ForEach-Object { $_.Content | Add-Member @{ Name = $_.Name } -ErrorAction SilentlyContinue; $_.Content } | 
        Where-Object { $Config.Type.Count -eq 0 -or (Compare-Object $Config.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | 
        Where-Object { -not ($Config.Algorithm | Where-Object { $_.StartsWith("+") }) -or (Compare-Object (($Config.Algorithm | Where-Object { $_.StartsWith("+") }).Replace("+", "")) $_.HashRates.PSObject.Properties.Name -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 } | 
        Where-Object { $Config.MinerName.Count -eq 0 -or (Compare-Object $Config.MinerName ($_.Name -split '-' | Select-Object -Index 0) -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 }

        #Download miner binaries
        If (($Variables.Miners | Where-Object {-not (Test-Path $_.Path -Type Leaf -ErrorAction Ignore) }) -and $Downloader.State -ne "Running") { 
            Write-Message -Level Warn "Some miners binaries are missing, starting downloader..."
            $Downloader = Start-Job -Name Downloader -InitializationScript ([scriptblock]::Create("Set-Location '$($Variables.MainPath)'")) -ArgumentList (@($Variables.Miners | Where-Object { $_.PrerequisitePath -and -not (Test-Path $_.PrerequisitePath -PathType Leaf -ErrorAction Ignore) } | Select-Object @{ Name = "URI"; Expression = { $_.PrerequisiteURI } }, @{ Name = "Path"; Expression = { $_.PrerequisitePath } }, @{ Name = "Searchable"; Expression = { $false } }) + @($Variables.Miners | Where-Object { -not (Test-Path $_.Path -PathType Leaf -ErrorAction Ignore) } | Select-Object URI, Path, @{ Name = "Searchable"; Expression = { $Miner = $_; ($Variables.Miners | Where-Object { (Split-Path $_.Path -Leaf) -eq (Split-Path $Miner.Path -Leaf) -and $_.URI -ne $Miner.URI }).Count -eq 0 } }) | Select-Object * -Unique) -FilePath ".\Includes\Downloader.ps1"
        }

        #Only keep miners that are present in \Bin directory
        $Variables.Miners = $Variables.Miners | Where-Object { Test-Path $_.Path -Type Leaf }

        If ($Variables.Miners.Count -eq 0) { 
            Write-Message "No Miners - waiting for downloader to install binaries!"
            Start-Sleep -Seconds 10
            continue
        }

        If ($Variables.Miners) { Write-Message "Calculating earning$(If ($Variables.PowerPricekWh) { " and profit" }) for each miner$(If ($Variables.PowerPricekWh) { " (power cost $($Config.Currency | Select-Object -Index 0) $($Variables.PowerPricekWh)/kW⋅h)"})..." }

        $Variables.Miners | ForEach-Object { 
            $Miner = $_
            $Miner_HashRates = [PSCustomObject]@{ }
            $Miner_Fees = [PSCustomObject]@{ }
            $Miner_Pools = [PSCustomObject]@{ }
            $Miner_Pools_Comparison = [PSCustomObject]@{ }
            $Miner_Earnings = [PSCustomObject]@{ }
            $Miner_Earnings_Comparison = [PSCustomObject]@{ }
            $Miner_Earnings_Bias = [PSCustomObject]@{ }

            $Miner_Types = $Miner.Type | Select-Object -Unique
            $Miner_Indexes = $Miner.Index | Select-Object -Unique

            $Miner.HashRates.PSObject.Properties.Name | ForEach-Object { #temp fix, must use 'PSObject.Properties' to preserve order
#                $Miner_HashRates | Add-Member $_ ([Double]$Miner.HashRates.$_)
                $Miner_HashRates | Add-Member $_ ([Double]$Stats."$($Miner.Name)_$($_)_HashRate".Week) #Read true hashrate
                $Miner_Fees | Add-Member $_ ([Double]$Miner.Fees.$_)
                $Miner_Pools | Add-Member $_ ([PSCustomObject]$Pools.$_)
                $Miner_Pools_Comparison | Add-Member $_ ([PSCustomObject]$Pools_Comparison.$_)

                if ($Config.IgnoreMinerFee) { $Miner_Fee_Factor = 1 } else { $Miner_Fee_Factor = 1 - $Miner.Fees.$_ }

                $Miner_Earnings | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.Price * $Miner_Fee_Factor)
                $Miner_Earnings_Comparison | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.StablePrice * $Miner_Fee_Factor)
                $Miner_Earnings_Bias | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.Price * (1 - ($Config.MarginOfError * [Math]::Pow($Variables.DecayBase, $DecayExponent))))
            }

            #Earning calculation
            $Miner_Earning = [Double]($Miner_Earnings.PSObject.Properties.Value | Measure-Object -Sum).Sum
            $Miner_Earning_Comparison = [Double]($Miner_Earnings_Comparison.PSObject.Properties.Value | Measure-Object -Sum).Sum
            $Miner_Earning_Bias = [Double]($Miner_Earnings_Bias.PSObject.Properties.Value | Measure-Object -Sum).Sum

            $Miner.HashRates.PSObject.Properties.Name | ForEach-Object { #temp fix, must use 'PSObject.Properties' to preserve order 
                If (-not [String]$Miner.HashRates.$_) { 
                    $Miner_HashRates.$_ = $null
                    $Miner_Earnings.$_ = $null
                    $Miner_Earnings_Comparison.$_ = $null
                    $Miner_Earnings_Bias.$_ = $null
                    $Miner_Earning = $null
                    $Miner_Earning_Comparison = $null
                    $Miner_Earning_Bias = $null
                }
            }

            If ($Miner_Types -eq $null) { $Miner_Types = $Variables.Miners.Type | Select-Object -Unique }
            If ($Miner_Indexes -eq $null) { $Miner_Indexes = $Variables.Miners.Index | Select-Object -Unique }
            If ($Miner_Types -eq $null) { $Miner_Types = "" }
            If ($Miner_Indexes -eq $null) { $Miner_Indexes = 0 }

            $Miner.HashRates = $Miner_HashRates
            $Miner | Add-Member Pools $Miner_Pools
            $Miner | Add-Member Earnings $Miner_Earnings
            $Miner | Add-Member Earnings_Comparison $Miner_Earnings_Comparison
            $Miner | Add-Member Earnings_Bias $Miner_Earnings_Bias
            $Miner | Add-Member Earning $Miner_Earning
            $Miner | Add-Member Earning_Comparison $Miner_Earning_Comparison
            $Miner | Add-Member Earning_Bias $Miner_Earning_Bias
            $Miner | Add-Member Earning_Bias_Orig $Miner_Earning_Bias

            $Miner | Add-Member Type $Miner_Types -Force
            $Miner | Add-Member Index $Miner_Indexes -Force

            $Miner | Add-Member -Force PowerUsage ($Stats."$($_.Name -split '-' | Select-Object -Index 0)_$($_.HashRates.PSObject.Properties.Name -join '-')_PowerUsage".Week)

            if ($Miner.Arguments -isnot [String]) { $Miner.Arguments = $Miner.Arguments | ConvertTo-Json -Depth 10 -Compress }

            $Miner.Path = Convert-Path $Miner.Path
            If ($Miner.PrerequisitePath) { $Miner.PrerequisitePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Miner.PrerequisitePath) }

# Debug/dev only!
#$Miner | Add-Member Fee (Get-Random -Minimum 0 -Maximum 0.08)

            # If ($Miner_Devices -eq $null) { $Miner.DeviceNames | Select-Object -Unique } 
            # If ($Miner_Devices -eq $null) { $Miner_Devices = ($Variables.Miners | Where-Object { (Compare-Object $Miner.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure-Object).Count -gt 0 }).DeviceNames | Select-Object -Unique }
            If ($Miner_Devices -eq $null) { $Miner_Devices = ($Variables.ConfiguredDevices | Where-Object { $_.Type -in @($Miner.Type) -or $_.Vendor -in @($Miner.Type) }).Name }
            # If ($Miner_Devices -eq $null) { $Miner_Devices = $Miner.Type } 

            $Miner | Add-Member DeviceNames @($Miner_Devices) -Force
        }

#Debug/dev only! Dual algo miners only
#$Variables.Miners = $Variables.Miners | Where-Object { @($_.HashRates.PSObject.Properties.Name).Count -gt 1 }
#Debug/dev only! Single algo miners only
#$Variables.Miners = $Variables.Miners | Where-Object { @($_.HashRates.PSObject.Properties.Name).Count -eq 1 }

        # Remove miners when no estimation info from pools or 0BTC. Avoids mining when algo down at pool or benchmarking for ever
        $Variables.Miners = $Variables.Miners | Where-Object { ($_.Pools.PSObject.Properties.Value.Price -ne $null) -and ($_.Pools.PSObject.Properties.Value.Price -gt 0) }

        #Open firewall ports for all miners
        #temp fix, needs removing from loop as it requires admin rights
        $ProgressPreferenceBackup = $ProgressPreference
        $ProgressPreference = "SilentlyContinue"
        If ($Config.OpenFirewallPorts -and (Get-Command "Get-MpPreference" -ErrorAction Ignore)) { 
            If ((Get-Command "Get-MpComputerStatus" -ErrorAction Ignore) -and (Get-MpComputerStatus -ErrorAction Ignore)) { 
                If (Get-Command "Get-NetFirewallRule" -ErrorAction Ignore) { 
                    $MinerFirewalls = Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program
                    If (@($Variables.Miners | Select-Object -ExpandProperty Path -Unique) | Compare-Object @($MinerFirewalls) | Where-Object SideIndicator -EQ "=>") { 
                        Start-Process (@{desktop = "powershell"; core = "pwsh" }.$PSEdition) ("-Command Import-Module '$env:Windir\System32\WindowsPowerShell\v1.0\Modules\NetSecurity\NetSecurity.psd1'; ('$(@($Variables.Miners | Select-Object -ExpandProperty Path -Unique) | Compare-Object @($MinerFirewalls) | Where-Object SideIndicator -EQ '=>' | Select-Object -ExpandProperty InputObject | ConvertTo-Json -Compress)' | ConvertFrom-Json) | ForEach-Object {New-NetFirewallRule -DisplayName (Split-Path `$_ -leaf) -Program `$_ -Description 'Inbound rule added by NemosMiner $($Variables.CurrentVersion) on $((Get-Date).ToString())' -Group 'Cryptocurrency Miner'}" -replace '"', '\"') -Verb runAs
                        Remove-Variable MinerFirewalls
                    }
                }
            }
        }
        $ProgressPreference = $ProgressPreferenceBackup

        #Detect miners with unreal earning (> 5x higher than the next best 10% miners, error in data provided by pool?)
        $ReasonableEarning = [Double]($Variables.Miners | Sort-Object -Descending Earning | Select-Object -Skip 1 -First ([Int]($Variables.Miners.Count / 10 )) | Measure-Object Earning -Average).Average * 5
        $Variables.Miners = @($Variables.Miners | Where-Object { $_.Earning -le $ReasonableEarning -or $_.HashRates.PSObject.Properties.Value -contains $null -or ($Variables.MeasurePowerUsage -and $_.PowerUsage -ne $null) })
        Remove-Variable ReasonableEarning

        #Profit calculation
        $Variables.Miners | ForEach-Object { 
            $_ | Add-Member -Force PowerCost ($_.PowerUsage * $Variables.PowerCostBTCperW)
            If ([String]$Miner.HashRates) { 
                $_ | Add-Member -Force Profit ($_.Earning - $_.PowerCost)
                $_ | Add-Member -Force Profit_Comparison ($_.Earning_Comparison - $_.PowerCost)
                $_ | Add-Member -Force Profit_Bias ($_.Earning_Bias - $_.PowerCost)
                $_ | Add-Member -Force Profit_Bias_Orig ($_.Earning_Bias - $_.PowerCost)
            }
            Else { 
                $_ | Add-Member -Force Profit $null
                $_ | Add-Member -Force Profit_Comparison $null
                $_ | Add-Member -Force Profit_Bias $null
                $_ | Add-Member -Force Profit_Bias_Orig $null
            }
        }

        $Variables | Add-Member -Force @{ MinersNeedingBenchmark = @($Variables.Miners | Where-Object { $_.HashRates.PSObject.Properties.Value -contains $null }) }
        $Variables | Add-Member -Force @{ MinersNeedingPowerUsageMeasurement = @($(if ($Config.MeasurePowerUsage) { $Variables.Miners | Where-Object PowerUsage -eq $null })) }

        #Don't penalize active miners. Miner could switch a little bit later and we will restore its bias in this case
        $Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" } | ForEach-Object { $Variables.Miners | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments | ForEach-Object { $_.Earning_Bias = $_.Earning * (1 + $Config.ActiveMinerGainPct / 100); $_.Profit_Bias = $_.Earning * (1 + $Config.ActiveMinerGainPct / 100) - $_.PowerCost } }

        #Hack: temporarily make all earnings & Earnings positive, BestMiners_Combos(_Comparison) produces wrong sort order when earnings or Earnings are negative
        $SmallestEarningBias = ([Double][Math]::Abs(($Variables.Miners | Sort-Object Earning_Bias | Select-Object -Index 0).Earning_Bias)) * 2
        $SmallestEarningComparison = ([Double][Math]::Abs(($Variables.Miners | Sort-Object Earning_Comparison | Select-Object -Index 0).Earning_Comparison)) * 2
        $SmallestProfitBias = ([Double][Math]::Abs(($Variables.Miners | Sort-Object Profit_Bias | Select-Object -Index 0).Profit_Bias)) * 2
        $SmallestProfitComparison = ([Double][Math]::Abs(($Variables.Miners | Sort-Object Profit_Comparison | Select-Object -Index 0).Profit_Comparison)) * 2
        $Variables.Miners | Where-Object { $_.Earning_Bias -ne $null } | ForEach-Object { $_.Earning_Bias += $SmallestEarningBias; $_.Earning_Comparison += $SmallestEarningComparison; $_.Profit_Bias += $SmallestProfitBias; $_.Profit_Comparison += $SmallestProfitComparison }

        If ($Variables.Miners.Count -eq 1) { 
            $BestMiners_Combo_Comparison = $BestMiners_Combo = @($Variables.Miners)
        }
        Else { 
            #Get most profitable miner combination i.e. AMD+NVIDIA+CPU
            If ($Variables.MeasurePowerUsage -and (-not $Config.IgnorePowerCost)) { $SortBy = "Profit" } Else { $SortBy = "Earning" }
            $BestMiners = @($Variables.Miners | Select-Object DeviceNames -Unique | ForEach-Object { $Miner_GPU = $_; ($Variables.Miners | Where-Object { (Compare-Object $Miner_GPU.DeviceNames $_.DeviceNames | Measure-Object).Count -eq 0 -and $_.Earning -ne 0 } | Sort-Object -Descending { ($_ | Where-Object { $_.HashRates.PSObject.Properties.Value -contains $null } | Measure-Object).Count }, { $(if ($_.HashRates.PSObject.Properties.Value -contains $null) { $_.Intervals.Count, $_.IntervalMultiplier } else { 0, 0 }) }, { $Variables.MeasurePowerUsage -and $_.PowerUsage -le 0 }, { $_."$($SortBy)_Bias" } | Select-Object -Index 0) })
            $BestMiners_Comparison = @($Variables.Miners | Select-Object DeviceNames -Unique | ForEach-Object { $Miner_GPU = $_; ($Variables.Miners | Where-Object { (Compare-Object $Miner_GPU.DeviceNames $_.DeviceNames | Measure-Object).Count -eq 0 -and $_.Earning -ne 0 } | Sort-Object -Descending { ($_ | Where-Object { $_.HashRates.PSObject.Properties.Value -contains $null } | Measure-Object).Count }, { $(if ($_.HashRates.PSObject.Properties.Value -contains $null) { $_.Intervals.Count, $_.IntervalMultiplier } else { 0, 0 }) }, { $Variables.MeasurePowerUsage -and $_.PowerUsage -le 0 }, { $_."$($SortBy)__Comparison" } | Select-Object -Index 0) })
            Remove-Variable SortBy

            $Miners_Device_Combos = @(Get-Combination ($Variables.Miners | Select-Object DeviceNames -Unique) | Where-Object { (Compare-Object ($_.Combination | Select-Object -ExpandProperty DeviceNames -Unique) ($_.Combination | Select-Object -ExpandProperty DeviceNames) | Measure-Object).Count -eq 0 })

            $BestMiners_Combos = @(
                $Miners_Device_Combos | ForEach-Object { 
                    $Miner_Device_Combo = $_.Combination
                    [PSCustomObject]@{ 
                        Combination = $Miner_Device_Combo | ForEach-Object { 
                            $Miner_Device_Count = $_.DeviceNames.Count
                            [Regex]$Miner_Device_Regex = "^(" + (($_.DeviceNames | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ")$"
                            $BestMiners | Where-Object { ([Array]$_.DeviceNames -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.DeviceNames -match $Miner_Device_Regex).Count -eq $Miner_Device_Count }
                        }
                    }
                }
            )
            $BestMiners_Combos_Comparison = @(
                $Miners_Device_Combos | ForEach-Object { 
                    $Miner_Device_Combo = $_.Combination
                    [PSCustomObject]@{ 
                        Combination = $Miner_Device_Combo | ForEach-Object { 
                            $Miner_Device_Count = $_.DeviceNames.Count
                            [Regex]$Miner_Device_Regex = "^(" + (($_.DeviceNames | ForEach-Object { [Regex]::Escape($_) }) -join '|') + ")$"
                            $BestMiners_Comparison | Where-Object { ([Array]$_.DeviceNames -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.DeviceNames -match $Miner_Device_Regex).Count -eq $Miner_Device_Count }
                        }
                    }
                }
            )
            If ($Variables.MeasurePowerUsage -and (-not $Config.IgnorePowerCost)) { 
                $BestMiners_Combo = @($BestMiners_Combos | Sort-Object -Descending { ($_.Combination | Where-Object Profit -EQ $null | Measure-Object).Count }, { ($_.Combination | Measure-Object Profit_Bias -Sum).Sum }, { ($_.Combination | Where-Object Profit -NE 0 | Measure-Object).Count } | Select-Object -Index 0 | Select-Object -ExpandProperty Combination)
                $BestMiners_Combo_Comparison = @($BestMiners_Combos_Comparison | Sort-Object -Descending { ($_.Combination | Where-Object Profit -EQ $null | Measure-Object).Count }, { ($_.Combination | Measure-Object Profit_Comparison -Sum).Sum }, { ($_.Combination | Where-Object Profit -NE 0 | Measure-Object).Count } | Select-Object -Index 0 | Select-Object -ExpandProperty Combination)
            }
            Else { 
                $BestMiners_Combo = @($BestMiners_Combos | Sort-Object -Descending { ($_.Combination | Where-Object Earning -EQ $null | Measure-Object).Count }, { ($_.Combination | Measure-Object Earning_Bias -Sum).Sum }, { ($_.Combination | Where-Object Earning -NE 0 | Measure-Object).Count } | Select-Object -Index 0 | Select-Object -ExpandProperty Combination)
                $BestMiners_Combo_Comparison = @($BestMiners_Combos_Comparison | Sort-Object -Descending { ($_.Combination | Where-Object Earning -EQ $null | Measure-Object).Count }, { ($_.Combination | Measure-Object Earning_Comparison -Sum).Sum }, { ($_.Combination | Where-Object Earning -NE 0 | Measure-Object).Count } | Select-Object -Index 0 | Select-Object -ExpandProperty Combination)
            }
            Remove-Variable Miner_Device_Combo
            Remove-Variable Miners_Device_Combos
            Remove-Variable BestMiners
            Remove-Variable BestMiners_Comparison
        }
        #ProfitabilityThreshold check
        $Variables | Add-Member -Force @{ MiningEarning = ($BestMiners_Combo | Measure-Object Earning -Sum).Sum }
        $Variables | Add-Member -Force @{ MiningCost = ($BestMiners_Combo | Measure-Object PowerCost -Sum).Sum + $Variables.BasePowerCost }

        #OK to run miners?
        If (-not (($Variables.MiningEarning - $Variables.MiningCost) -ge ($Config.ProfitabilityThreshold / $Variables.Rates.($Config.Currency | Select-Object -Index 0)) -or  $Variables.MinersNeedingBenchmark -or $Variables.MinersNeedingPowerUsageMeasurement)) { 
#           $BestMiners_Combo = $null
            $BestMiners_Combo_Comparison = $null
        }

        #Hack part 2: reverse temporarily forced positive earnings & Earnings
        $Variables.Miners | Where-Object { $_.Earning_Bias -ne $null } | ForEach-Object { $_.Earning_Bias -= $SmallestEarningBias; $_.Earning_Comparison -= $SmallestEarningComparison; $_.Profit_Bias -= $SmallestProfitBias; $_.Profit_Comparison -= $SmallestProfitComparison }
        Remove-Variable SmallestEarningBias
        Remove-Variable SmallestEarningComparison
        Remove-Variable SmallestProfitBias
        Remove-Variable SmallestProfitComparison

        # No CPU mining if GPU miner prevents it
        If ($BestMiners_Combo.PreventCPUMining -contains $true) { 
            $BestMiners_Combo = $BestMiners_Combo | Where-Object { $_.type -ne "CPU" }
            Write-Message "Miner prevents CPU mining"
        }

        # Ban miners if too many failures as defined by MaxMinerFailure
        # 0 means no ban
        # Int value means ban after x failures
        # defaults to 3 if no value in config
        # ** Ban is not persistent across sessions **
        #Ban Failed Miners code by @MrPlusGH
        If ($Config.MaxMinerFailure -gt 0) { 
            $Config | Add-Member -Force @{ MaxMinerFailure = If ($Config.MaxMinerFailure) { $Config.MaxMinerFailure } Else { 3 } }
            $BannedMiners = $Variables.ActiveMiners | Where-Object { $_.Status -eq "Failed" -and $_.FailedCount -ge $Config.MaxMinerFailure }
            # $BannedMiners | ForEach { Write-Message "BANNED: $($_.Name) / $($_.Algorithms). Too many failures. Consider Algo exclusion in config." }
            $BannedMiners | ForEach-Object { "BANNED: $($_.Name) / $($_.Algorithms). Too many failures. Consider Algo exclusion in config." | Out-Host }
            $Variables.Miners = $Variables.Miners | Where-Object { $_.Path -notin $BannedMiners.Path -and $_.Arguments -notin $BannedMiners.Arguments }
        }

        #Add the most profitable miners to the active list
        $BestMiners_Combo | ForEach-Object { 
            If (($Variables.ActiveMiners | Select-Object | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments).Count -eq 0) { 
                $Variables.ActiveMiners += [PSCustomObject]@{ 
                    Type               = [String]($_.Type)
                    Name               = [String]($_.Name)
                    Path               = [String]($_.Path)
                    Arguments          = [String]($_.Arguments)
                    Wrap               = [Boolean]($_.Wrap)
                    Process            = [System.Management.Automation.Job]$null
                    API                = [String]($_.API)
                    Port               = [Int16]($_.Port)
                    New                = [Boolean]$false
                    Active             = [TimeSpan]0
                    TotalActive        = [TimeSpan]0
                    Activated          = [Int]0
                    Status             = [String]"Idle"
                    HashRates          = [Hashtable[]]@()
                    Benchmarked        = [Int]0
                    Hashrate_Gathered  = [Boolean]($_.HashRates.PSObject.Properties.Value -ne $null)
                    Pools              = [PSCustomObject]($_.Pools)
                    DeviceNames        = [String[]]$_.DeviceNames
                    Fee                = [Double]($_.Fee)
                    PowerUsage         = [Double]0
                    Data               = [Hashtable[]]@()
                    IntervalMultiplier = [Int16]1
                    StatStart          = [DateTime]0
                    StatEnd            = [DateTime]0
                    Intervals          = [Int]0
                }
            }
        }
        #Stop or start miners in the active list depending on if they are the most profitable
        # We have to stop processes first or the port would be busy
        $Variables.ActiveMiners | Select-Object | ForEach-Object { 
            $Miner = $_
            $Filtered = @($BestMiners_Combo | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments)
            If ($Filtered.Count -eq 0) { 
                If ($Miner.Process -eq $null) { 
                    $Miner.Status = "Failed"
                }
                ElseIf ($Miner.Process.HasExited -eq $false) { 
                    Write-Message "Stopping miner ($($Miner.Name)) {$(($Miner.Pools.PSObject.Properties.Value | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join '; ')}."
                    $Miner.Process.CloseMainWindow() | Out-Null
                    Start-Sleep 1
                    # simply "Kill with power"
                    Stop-Process $Miner.Process -Force | Out-Null
                    # try to kill any process with the same path, in case it is still running but the process handle is incorrect
                    $KillPath = $Miner.Path
                    If (Get-Process | Where-Object { $_.Path -eq $KillPath } | Stop-Process -Force) { 
                        Start-Sleep 1
                    }
                    $Miner.Status = "Idle"
                    $Miner.TotalActive += (-$Miner.Active + ($Miner.Active = (Get-Date) - $Miner.Process.StartTime))
                }
                #Restore Bias for non-active miners
                $Variables.Miners | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments | ForEach-Object { $_.Earning_Bias = $_.Earning_Bias_Orig; $_.Profit_Bias = $_.Profit_Bias_Orig }

                # Stop data reader 
                $Miner.DataReaderJob | Stop-Job -ErrorAction Ignore | Remove-Job -ErrorAction Ignore
            }
        }

        $NewMiner = $false
        $Variables.ActiveMiners | Select-Object | ForEach-Object { 
            $Filtered = @($BestMiners_Combo | Select-Object | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments)
            If ($Filtered.Count -gt 0) { 
                $Miner = $_
                If ($Miner.Process -eq $null -or $Miner.Process.HasExited -ne $false) { 
                    # Log switching information to .\Logs\switching.log
                    [PSCustomObject]@{ Date = (Get-Date); "Type" = $Miner.Type; "Algo(s)" = (($Miner.Pools.PSObject.Properties.Value.Algorithm | Select-Object -Unique) -join ';'); "Wallet(s)" = (($Miner.Pools.PSObject.Properties.Value.User | Select-Object -Unique) -join ';') ;  "Username" = $Config.UserName ; "Host(s)" = (($Miner.Pools.PSObject.Properties.Value.Host | Select-Object -Unique) -join ';') } | Export-Csv .\Logs\switching.log -Append -NoTypeInformation

                    # Launch prerun if exists
                    If ($Miner.Type -ne "AMD" -and (Test-Path ".\Utils\Prerun\AMDPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\AMDPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    If ($Miner.Type -ne "NVIDIA" -and (Test-Path ".\Utils\Prerun\NVIDIAPrerun.bat" -PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\NVIDIAPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    If ($Miner.Type -ne "CPU" -and (Test-Path ".\Utils\Prerun\CPUPrerun.bat"-PathType Leaf)) { 
                        Start-Process ".\Utils\Prerun\CPUPrerun.bat" -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                    }
                    If ($Miner.Type -ne "CPU") { 
                        $PrerunName = ".\Utils\Prerun\" + $Miner.Algorithms + ".bat"
                        $DefaultPrerunName = ".\Utils\Prerun\default.bat"
                        If (Test-Path $PrerunName -PathType Leaf) { 
                            Write-Message "Launching Prerun: $PrerunName"
                            Start-Process $PrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                            Start-Sleep 2
                        }
                        ElseIf (Test-Path $DefaultPrerunName -PathType Leaf) { 
                            Write-Message "Launching Prerun: $DefaultPrerunName"
                            Start-Process $DefaultPrerunName -WorkingDirectory ".\Utils\Prerun" -WindowStyle hidden
                            Start-Sleep 2
                        }
                    }

                    Start-Sleep $Config.Delay #Wait to prevent BSOD
                    Write-Message "$(If ($Miner.Hashrate_Gathered) { "Starting" } Else { "Benchmarking" } ) miner ($($Miner.Name)) {$(($Miner.Pools.PSObject.Properties.Value | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join '; ')}."
 
                    $Variables.DecayStart = (Get-Date).ToUniversalTime()
                    $Miner.New = $true
                    $Miner.Activated++
                    $Arguments = $Miner.Arguments
                    If ($Arguments -match "^{.+}$") { 
                        $Parameters = $Arguments | ConvertFrom-Json

                        #Write config files. Keep separate files, do not overwrite to preserve optional manual customization
                        If (-not (Test-Path "$(Split-Path $Miner.Path)\$($Parameters.ConfigFile.FileName)" -PathType Leaf)) { $Parameters.ConfigFile.Content | Set-Content "$(Split-Path $Miner.Path)\$($Parameters.ConfigFile.FileName)" -ErrorAction Ignore }
                        $Arguments = $Parameters.Commands
                    }

                    If ($Miner.Process -ne $null) { $Miner.Active = [TimeSpan]0 }
                    If ($Miner.Wrap) { $Miner.Process = Start-Process -FilePath "PowerShell" -ArgumentList "-executionpolicy bypass -command . '$(Convert-Path ".\Includes\Wrapper.ps1")' -ControllerProcessID $PID -Id '$($Miner.Port)' -FilePath '$($Miner.Path)' -ArgumentList '$Arguments' -WorkingDirectory '$(Split-Path $_.Path)'" -PassThru }
                    Else { $Miner.Process = Start-SubProcess -FilePath $Miner.Path -ArgumentList $Arguments -WorkingDirectory (Split-Path $Miner.Path) }
                    If ($Miner.Process -eq $null) { $_.Status = "Failed" }
                    Else { 
                        $Miner.Status = "Running"
                        $Miner.StatStart = (Get-Date).ToUniversalTime()

                        $NewMiner = $true
                        #Newly started miner should look better than others in the first run too
                        $Variables.Miners | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $Arguments | ForEach-Object { $_.Earning_Bias = $_.Earning * (1 + $Config.ActiveMinerGainPct / 100); $_.Profit_Bias = $_.Earning * (1 + $Config.ActiveMinerGainPct / 100) - $Miner.PowerCost }

                        #Starting Miner Data reader
                        Start-MinerDataReader -Miner $Miner -ReadPowerUsage $Variables.MeasurePowerUsage -Interval $(If ($Miner.Hashrate_Gathered) { 2 } Else { 0 } )
                    }
                }
                Else { 
                    $Miner.TotalActive += (-$Miner.Active + ($Miner.Active = (Get-Date) - $Miner.Process.StartTime))
                }
            }
        }
        #Set idle duration a few seconds as to not overload the APIs
        $Variables.TimeToSleep = $Config.Interval
        "--------------------------------------------------------------------------------" | Out-Host

        $Variables.ActiveMiners | Where-Object { $_.Status -ne "Running" } | ForEach-Object { $_.process = $_.process | Select-Object HasExited, StartTime, ExitTime }
        $ActiveMinersCOPY = @()
        $Variables.ActiveMiners | ForEach-Object { $ActiveMinerCOPY = [PSCustomObject]@{ }; $_.PSObject.Properties | Sort-Object Name | ForEach-Object { $ActiveMinerCOPY | Add-Member -Force @{ $_.Name = $_.Value } }; $ActiveMinersCOPY += $ActiveMinerCOPY }
        $Variables.ActiveMiners = $ActiveMinersCOPY
        Remove-Variable ActiveMinersCOPY
        Remove-Variable ActiveMinerCOPY
    
        $Error.Clear()
    
        Get-Job | Where-Object { $_.State -eq "Completed" } | Remove-Job
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

        Write-Message "Waiting for next cycle..."

        # Mostly used for debug. Will execute code found in .\EndLoopCode.ps1 if exists.
        If (Test-Path ".\EndLoopCode.ps1" -PathType Leaf) { Invoke-Expression (Get-Content ".\EndLoopCode.ps1" -Raw) }
    }

    "Cycle Time (seconds): $($CycleTime.TotalSeconds)" | Out-Host
    $Variables.StatusText = "Waiting $($Variables.TimeToSleep) seconds... | Next refresh: $((Get-Date).AddSeconds($Variables.TimeToSleep).ToString('g'))"
    $Variables | Add-Member -Force @{ EndLoop = $True }
}
#Stop the log
# Stop-Transcript
