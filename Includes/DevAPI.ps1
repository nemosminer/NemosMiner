$Request = '2021-05-20 23:35:36: http://localhost:3999/functions/pool/disable?Pools=%5B{"Name"%3A"NLPool"%2C"Algorithm"%3A"Allium" }%2C{"Name"%3A"ZergPool24hr"%2C"Algorithm"%3A"Allium" }%2C{"Name"%3A"ZergPool24hr"%2C"Algorithm"%3A"Allium" }%2C{"Name"%3A"ZPool"%2C"Algorithm"%3A"Allium" }%2C{"Name"%3A"ZPool"%2C"Algorithm"%3A"Allium" }%2C{"Name"%3A"ZPool"%2C"Algorithm"%3A"Allium" }%2C{"Name"%3A"ZPool"%2C"Algorithm"%3A"Allium" }%2C{"Name"%3A"ZPool"%2C"Algorithm"%3A"ArcticHash" }%5D'


Set-Location("c:\Users\Stephan\Desktop\NemosMiner\")
$ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

$Parameters = @{ }
$Variables = [Ordered]@{ }
# $Variables.Miners = Get-Content .\Debug\Miners.json | ConvertFrom-Json
$Variables.Pools = Get-Content .\Debug\Pools.json | ConvertFrom-Json
$Variables.ConfigFile = ".\Config\config.json"
$Variables.PoolsConfigFile = ".\Config\PoolsConfig.json"
$Variables.Earnings = Get-Content .\Debug\Earnings.json | ConvertFrom-Json
$Variables.AvailableCommandLineParameters = @("Algorithm")
$Variables.WatchdogTimers = Get-Content .\Debug\WatchdogTimers.json | ConvertFrom-Json
$Variables.BalanceData = Get-Content "C:\Users\Stephan\Desktop\NemosMiner\Logs\BalancesTrackerData.json" | ConvertFrom-Json

# Load stats, required for stat management
Get-Stat | Out-Null

Read-Config -ConfigFile $Variables.ConfigFile

$Request = $Request.Substring(42)
$Path = $Request -replace "\?.+"

$Request -replace ".+\?", "" -split '&' | Foreach-Object { 
    $Key, $Value = $_ -split '='
    # Decode any url escaped characters in the key and value
    $Key = [URI]::UnescapeDataString($Key)
    $Value = [URI]::UnescapeDataString($Value)
    If ($Key -and $Value) { $Parameters.$Key = $Value }
}

# Create a new response and the defaults for associated settings
$Response = $Context.Response
$ContentType = "application/json"
$StatusCode = 200
$Data = ""

# Set the proper content type, status code and data for each resource
Switch ($Path) { 
    "/functions/api/stop" { 
        Stop-APIServer
    }
    "/functions/balancedata/remove" { 
        If ($Parameters.Data) { 
            $BalanceDataEntries = ($Parameters.Data | ConvertFrom-Json -ErrorAction SilentlyContinue)
            $Variables.BalanceData = @((Compare-Object $Variables.BalanceData $BalanceDataEntries -PassThru -Property DateTime, Pool, Currency, Wallet) | Select-Object -ExcludeProperty SideIndicator)
            $Variables.BalanceData | ConvertTo-Json | Out-File -FilePath ".\Logs\BalancesTrackerData.json" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            If ($BalanceDataEntries.Count -gt 0) { 
                $Variables.BalanceData | ConvertTo-Json | Out-File -FilePath ".\Logs\BalancesTrackerData.json" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                $Message = "$($BalanceDataEntries.Count) $(If ($BalanceDataEntries.Count -eq 1) { "balance data entry" } Else { "balance data entries" }) removed."
                Write-Message -Level Verbose "Web GUI: $Message"
                $Data += "`n`n$Message"
            }
            Else { 
                $Data = "`nNo matching entries found."
            }
            $Data = "<pre>$Data</pre>"
            Break
        }
    }
    "/functions/config/device/disable" { 
        ForEach ($Key in $Parameters.Keys) { 
            If ($Values = @($Parameters.$Key -split ',' | Where-Object { $_ -notin $Config.ExcludeDeviceName })) { 
                Try { 
                    $Data = "`nDevice configuration changed`n`nOld values:"
                    $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                    $Config.ExcludeDeviceName = @((@($Config.ExcludeDeviceName) + $Values) | Sort-Object -Unique)
                    $Data += "`n`nNew values:"
                    $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                    $Data += "`n`nUpdated configFile`n$($Variables.ConfigFile)"
                    Write-Config -ConfigFile $Variables.ConfigFile -NewConfig $Config
                    ForEach ($DeviceName in $Values) { 
                        $Variables.Devices | Where-Object Name -EQ $DeviceName | ForEach-Object { 
                            $_.State = [DeviceState]::Disabled
                            If ($_.Status -like "* {*@*}") { $_.Status = "$($_.Status); will get disabled at end of cycle" }
                            Else { $_.Status = "Disabled (ExcludeDeviceName: '$($_.Name)')" }
                        }
                    }
                    Write-Message -Level Verbose "Web GUI: Device '$($Values -join '; ')' disabled. Config file '$($Variables.ConfigFile)' updated."
                }
                Catch { 
                    $Data = "<pre>Error saving config file`n'$($Variables.ConfigFile) $($Error[0])'.</pre>"
                }
            }
            Else { 
                $Data = "No configuration change"
            }
        }
        $Data = "<pre>$Data</pre>"
        Break
    }
    "/functions/config/device/enable" { 
        ForEach ($Key in $Parameters.Keys) { 
            If ($Values = @($Parameters.$Key -split ',' | Where-Object { $_ -in $Config.ExcludeDeviceName })) { 
                Try { 
                    $Data = "`nDevice configuration changed`n`nOld values:"
                    $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                    $Config.ExcludeDeviceName = @($Config.ExcludeDeviceName | Where-Object { $_ -notin $Values } | Sort-Object -Unique)
                    $Data += "`n`nNew values:"
                    $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                    $Data += "`n`nUpdated configFile`n$($Variables.ConfigFile)"
                    Write-Config -ConfigFile $Variables.ConfigFile -NewConfig $Config
                    $Variables.Devices | Where-Object Name -in $Values | ForEach-Object { 
                        $_.State = [DeviceState]::Enabled
                        If ($_.Status -like "* {*@*}; will get disabled at end of cycle") { $_.Status = $_.Status -replace "; will get disabled at end of cycle" }
                        Else { $_.Status = "Idle" }
                    }
                    Write-Message -Level Verbose "Web GUI: Device $($Values -join '; ') enabled. Config file '$($Variables.ConfigFile)' updated."
                }
                Catch { 
                    $Data = "<pre>Error saving config file`n'$($Variables.ConfigFile) $($Error[0])'.</pre>"
                }
            }
            Else { 
                $Data = "No configuration change"
            }
        }
        $Data = "<pre>$Data</pre>"
        Break
    }
    "/functions/config/set" { 
        Try { 
            Write-Config -ConfigFile $Variables.ConfigFile -NewConfig ($Key | ConvertFrom-Json)
            Read-Config -ConfigFile $Variables.ConfigFile
            $Variables.Devices | Select-Object | Where-Object { $_.State -ne [DeviceState]::Unsupported } | ForEach-Object { 
                If ($_.Name -in @($Config.ExcludeDeviceName)) { 
                    $_.State = [DeviceState]::Disabled
                    If ($_.Status -like "Mining *}") { $_.Status = "$($_.Status); will get disabled at end of cycle" }
                }
                Else { 
                    $_.State = [DeviceState]::Enabled
                    If ($_.Status -like "*; will get disabled at end of cycle") { $_.Status = $_.Status -replace "; will get disabled at end of cycle" } 
                    If ($_.Status -like "Disabled *") { $_.Status = "Idle" }
                }
            }
            $Variables.RestartCycle = $true

            # Set operational values for text window
            $Variables.ShowAccuracy = $Config.ShowAccuracy
            $Variables.ShowAllMiners = $Config.ShowAllMiners
            $Variables.ShowEarning = $Config.ShowEarning
            $Variables.ShowEarningBias = $Config.ShowEarningBias
            $Variables.ShowMinerFee = $Config.ShowMinerFee
            $Variables.ShowPoolBalances = $Config.ShowPoolBalances
            $Variables.ShowPoolFee = $Config.ShowPoolFee
            $Variables.ShowPowerCost = $Config.ShowPowerCost
            $Variables.ShowPowerUsage = $Config.ShowPowerUsage
            $Variables.ShowProfit = $Config.ShowProfit
            $Variables.ShowProfitBias = $Config.ShowProfitBias

            Write-Message -Level Verbose "Web GUI: Configuration applied."
            $Data = "Config saved to '$($Variables.ConfigFile)'. It will become active in next cycle."
        }
        Catch { 
            $Data = "Error saving config file`n'$($Variables.ConfigFile)'."
        }
        $Data = "<pre>$Data</pre>"
        Break
    }
    "/functions/log/get" { 
        $Lines = If ([Int]$Parameters.Lines) { [Int]$Parameters.Lines } Else { 100 }
        $Data = " $(Get-Content -Path $Variables.LogFile -Tail $Lines | ForEach-Object { "$($_)`n" } )"
        Break
    }
    "/functions/mining/getstatus" { 
        $Data = If ($Variables.MiningStatus -eq $Variables.NewMiningStatus) {  ConvertTo-Json ($Variables.MiningStatus) } Else { ConvertTo-Json ($Variables.NewMiningStatus) }
        Break
    }
    "/functions/mining/pause" { 
        If ($Variables.MiningStatus -ne "Paused") { 
            $Variables.NewMiningStatus = "Paused"
            $Data = "Mining is paused.`n$(If ($Variables.MiningStatus -ne "Running" -and $Config.RigMonitorPollInterval) { "Rig Monitor" } )$(If ($Variables.MiningStatus -ne "Running" -and $Config.RigMonitorPollInterval -and $Config.BalancesTrackerPollInterval) { " and " } )$( If ($Variables.MiningStatus -ne "Running" -and $Config.BalancesTrackerPollInterval) { "Balances Tracker" } )$(If ($Variables.MiningStatus -ne "Running" -and $Config.RigMonitorPollInterval -or $Config.BalancesTrackerPollInterval) { " running." } )"
        }
        $Variables.RestartCycle = $true
        $Data = "<pre>$Data</pre>"
        Break
    }
    "/functions/mining/start" { 
        If ($Variables.MiningStatus -ne "Running") { 
            $Variables.NewMiningStatus = "Running"
            $Data = "Mining processes started.`n$(If ($Variables.RigMonitorRunspace) { "Rig Monitor" } )$(If ($Variables.RigMonitorRunspace -and $Variables.BalancesTrackerRunspace) { " and " } )$( If ($Variables.BalancesTrackerRunspace) { "Balances Tracker" } )$(If ($Variables.RigMonitorRunspace -or $Variables.BalancesTrackerRunspace) { " running." } )"
        }
        $Variables.RestartCycle = $true
        $Data = "<pre>$Data</pre>"
        Break
    }
    "/functions/mining/stop" { 
        If ($Variables.MiningStatus -ne "Idle") { 
            $Variables.NewMiningStatus = "Idle"
            $Data = "NemosMiner is idle.`n$(If ($Variables.RigMonitorRunspace) { "Rig Monitor" } )$(If ($Variables.RigMonitorRunspace -and $Variables.BalancesTrackerRunspace) { " and " } )$( If ($Variables.BalancesTrackerRunspace) { "Balances Tracker" } )$(If ($Variables.RigMonitorRunspace -or $Variables.BalancesTrackerRunspace) { " stopped." } )"
        }
        $Variables.RestartCycle = $true
        $Data = "<pre>$Data</pre>"
        Break
    }
    "/functions/pool/disable" { 
        If ($Parameters.Pools) { 
            $PoolsConfig = Get-Content -Path $Variables.PoolsConfigFile -ErrorAction Ignore | ConvertFrom-Json
            $Pools = ($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue) | Sort-Object Name, Algorithm -Unique
            $Pools | Group-Object Name | ForEach-Object { 
                $PoolName = $_.Name

                $PoolConfig = If ($PoolsConfig.$PoolName) { $PoolsConfig.$PoolName } Else { [PSCustomObject]@{ } }
                [System.Collections.ArrayList]$AlgorithmList = @(($PoolConfig.Algorithm -replace " ") -split ',')

                ForEach ($Algorithm in $_.Group.Algorithm) { 
                    $AlgorithmList.Remove("+$Algorithm")
                    If (-not ($AlgorithmList -match "\+.+") -and $AlgorithmList -notcontains "-$Algorithm") { $AlgorithmList += "-$Algorithm" }

                    $Reason = "Algorithm disabled (``-$($Algorithm)`` in $PoolName pool config)"
                    $Variables.Pools | Where-Object BaseName -EQ $PoolName | Where-Object Algorithm -EQ $Algorithm | ForEach-Object { 
                        $_.Reason = @($_.Reason | Where-Object { $_ -notmatch $Reason })
                        $_.Reason += $Reason
                        $_.Available = $false
                    }
                    $Data += "`n$Algorithm@$PoolName ($((($Variables.Pools | Where-Object BaseName -EQ $PoolName | Where-Object Algorithm -EQ $Algorithm).Region | Sort-Object -Unique) -join ', '))"
                }

                If ($AlgorithmList) { $PoolConfig | Add-Member Algorithm (($AlgorithmList | Sort-Object) -join ',' -replace "^,+") -Force } Else { $PoolConfig.PSObject.Properties.Remove('Algorithm') }
                If ($PoolConfig | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) { $PoolsConfig | Add-Member $PoolName $PoolConfig -Force } Else { $PoolsConfig.PSObject.Properties.Remove($PoolName) }
            }
            $DisabledPoolsCount = $Pools.Count
            If ($DisabledPoolsCount -gt 0) { 
                # Write PoolsConfig
                $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $Variables.PoolsConfigFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                $Message = "$DisabledPoolsCount $(If ($DisabledPoolsCount -eq 1) { "algorithm" } Else { "algorithms" }) disabled."
                Write-Message -Level Verbose "Web GUI: $Message"
                $Data += "`n`n$Message"
            }
            Break
        }
    }
    "/functions/pool/enable" { 
        If ($Parameters.Pools) { 
            $PoolsConfig = Get-Content -Path $Variables.PoolsConfigFile -ErrorAction Ignore | ConvertFrom-Json
            $Pools = ($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue) | Sort-Object Name, Algorithm -Unique
            $Pools | Group-Object Name | ForEach-Object { 
                $PoolName = $_.Name

                $PoolConfig = If ($PoolsConfig.$PoolName) { $PoolsConfig.$PoolName } Else { [PSCustomObject]@{ } }
                [System.Collections.ArrayList]$AlgorithmList = @(($PoolConfig.Algorithm -replace " ") -split ',')

                ForEach ($Algorithm in $_.Group.Algorithm) { 
                    $AlgorithmList.Remove("-$Algorithm")
                    If ($AlgorithmList -match "\+.+" -and $AlgorithmList -notcontains "+$Algorithm") { $AlgorithmList += "+$Algorithm" }

                    $Reason = "Algorithm disabled (``-$($Algorithm)`` in $PoolName pool config)"
                    $Variables.Pools | Where-Object BaseName -EQ $PoolName | Where-Object Algorithm -EQ $Algorithm | ForEach-Object { 
                        $_.Reason = @($_.Reason | Where-Object { $_ -ne $Reason })
                        If (-not $_.Reason) { $_.Available = $true }
                    }
                    $Data += "`n$Algorithm@$PoolName ($((($Variables.Pools | Where-Object BaseName -EQ $PoolName | Where-Object Algorithm -EQ $Algorithm).Region | Sort-Object -Unique) -join ', '))"
                }

                If ($AlgorithmList) { $PoolConfig | Add-Member Algorithm (($AlgorithmList | Sort-Object) -join ',' -replace "^,+") -Force } Else { $PoolConfig.PSObject.Properties.Remove('Algorithm') }
                If ($PoolConfig | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name) { $PoolsConfig | Add-Member $PoolName $PoolConfig -Force } Else { $PoolsConfig.PSObject.Properties.Remove($PoolName) }
            }
            $EnabledPoolsCount = $Pools.Count
            If ($EnabledPoolsCount -gt 0) { 
                # Write PoolsConfig
                $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $Variables.PoolsConfigFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                $Message = "$EnabledPoolsCount $(If ($EnabledPoolsCount -eq 1) { "algorithm" } Else { "algorithms" }) enabled."
                Write-Message -Level Verbose "Web GUI: $Message"
                $Data += "`n`n$Message"
            }
            Break
        }
    }
    "/functions/poolsconfig/edit" { 
        $PoolsConfigFileWriteTime = (Get-Item -Path $Variables.PoolsConfigFile -ErrorAction Ignore).LastWriteTime
        If (-not ($NotepadProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -Like "*\Notepad.exe* $($Variables.PoolsConfigFile)"))) { 
            Notepad.exe $Variables.PoolsConfigFile
        }
        If ($NotepadProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -Like "*\Notepad.exe* $($Variables.PoolsConfigFile)")) { 
            $NotepadMainWindowHandle = (Get-Process -Id $NotepadProcess.ProcessId).MainWindowHandle
            # Check if the window isn't already in foreground
            While ($NotepadProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -Like "*\Notepad.exe* $($Variables.PoolsConfigFile)")) { 
                $FGWindowPid  = [IntPtr]::Zero
                [Void][Win32]::GetWindowThreadProcessId([Win32]::GetForegroundWindow(), [ref]$FGWindowPid)
                If ($NotepadProcess.ProcessId -ne $FGWindowPid) { 
                    If ([Win32]::GetForegroundWindow() -ne $NotepadMainWindowHandle) { 
                        [Void][Win32]::ShowWindowAsync($NotepadMainWindowHandle, 6)
                        [Void][Win32]::ShowWindowAsync($NotepadMainWindowHandle, 9)
                    }
                }
                Start-Sleep -MilliSeconds 100
            }
        }
        If ($PoolsConfigFileWriteTime -ne (Get-Item -Path $Variables.PoolsConfigFile -ErrorAction Ignore).LastWriteTime) { 
            $Data = "Saved '$(($Variables.PoolsConfigFile))'`nChanges will become active in next cycle."
            Write-Message -Level Verbose "Web GUI: Saved '$(($Variables.PoolsConfigFile))'. Changes will become active in next cycle."
        }
        Else { 
            $Data = ""
        }
        Remove-Variable NotepadProcess, NotepadMainWindowHandle, PoolsConfigFileWriteTime -ErrorAction Ignore
        Break
    }
    "/functions/stat/get" { 
        If ($Parameters.Value) { $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | Where-Object { $Stats.$_.Minute -eq $Parameters.Value } | ForEach-Object { $Stats.$_ }) }
        Else { $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | ForEach-Object { $Stats.$_ }) } 

        If ($TempStats) { 
            $TempStats | Sort-Object Name | ForEach-Object { $Data += "`n$($_.Name -replace "_$($Parameters.Type)")" }
            $Data += "`n`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)$($Parameters.Unit) $($Parameters.Type)."
        }
        Else { 
            $Data = "`nNo matching stats found."
        }
    Break
    }
    "/functions/stat/remove" { 
        If ($Parameters.Pools) { 
            If ($Pools = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Pools | Select-Object) @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithm) { 
                $Pools | Sort-Object Name | ForEach-Object { 
                    $StatName = If ($_.Name -like "*Coins") { "$($_.Name)_$($_.Algorithm)-$($_.Currency)" } Else { "$($_.Name)_$($_.Algorithm)" }
                    $Data += "`n$($StatName)"
                    Remove-Stat -Name "$($StatName)_Profit"
                    $_.Reason = [String[]]@()
                    $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                }
                $Message = "Pool data reset for $($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" })."
                Write-Message -Level Verbose "Web GUI: $Message"
                $Data += "`n`n$Message"
            }
            Else { 
                $Data = "`nNo matching stats found."
            }
            Break
        }
        If ($Parameters.Miners -and $Parameters.Type -eq "HashRate") { 
            If ($Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithm) { 
                $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                    If ($_.Status -EQ [MinerStatus]::Running) { 
                        $Variables.EndLoopTime = Get-Date # End loop immediately
                    }
                    If ($_.Earning -eq 0) { $_.Available = $true }
                    $_.Earning_Accuracy = [Double]::NaN
                    $_.Activated = 0 # To allow 3 attempts
                    $_.Disabled = $false
                    $_.Benchmark = $true
                    $_.Data = @()
                    $_.Speed = @()
                    $_.SpeedLive = @()
                    $_.Workers | ForEach-Object { $_.Speed = [Double]::NaN }
                    $Data += "`n$($_.Name) ($($_.Algorithm -join " & "))"
                    ForEach ($Algorithm in $_.Algorithm) { 
                        Remove-Stat -Name "$($_.Name)_$($Algorithm)_Hashrate"
                        If ($_.Status -eq [MinerStatus]::Disabled) { 
                            $_.Disabled = $false
                            $_.Status = [MinerStatus]::Idle
                            $_.Reason = @($_.Reason | Where-Object { $_ -ne "Disabled by user" })
                        }
                        ElseIf ($_.Status -eq [MinerStatus]::Failed) { 
                            $_.Status = [MinerStatus]::Idle
                            $_.Reason = @($_.Reason | Where-Object { $_ -ne "0 H/s Stat file" })
                        }
                        If (-not $_.Reason) { $_.Available = $true }
                    }
                    # Also clear power usage
                    Remove-Stat -Name "$($_.Name)$(If ($_.Algorithm.Count -eq 1) { "_$($_.Algorithm)" })_PowerUsage"
                    $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                }
                Write-Message -Level Verbose "Web GUI: Re-benchmark triggered for $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" })."
                $Data += "`n`n$(If ($Miners.Count -eq 1) { "The miner" } Else { "$($Miners.Count) miners" }) will re-benchmark."
            }
            Else { 
                $Data = "`nNo matching stats found."
            }
            Break
        }
        If ($Parameters.Miners -and $Parameters.Type -eq "PowerUsage") { 
            If ($Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithm) { 
                $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                    If ($_.Status -EQ [MinerStatus]::Running) { $_.Data = @() }
                    If ($_.Earning -eq 0) { $_.Available = $true }
                    If ($Variables.CalculatePowerCost) { 
                        $_.MeasurePowerUsage = $true
                        $_.Activated = 0 # To allow 3 attempts
                        If ($_.Status -EQ [MinerStatus]::Running) { 
                            $Variables.EndLoopTime = Get-Date # End loop immediately
                        }
                    }
                    $StatName = "$($_.Name)$(If ($_.Algorithm.Count -eq 1) { "_$($_.Algorithm)" })"
                    $Data += "`n$StatName"
                    Remove-Stat -Name "$($StatName)_PowerUsage"
                    $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = [Double]::NaN
                }
                Write-Message -Level Verbose "Web GUI: Re-measure power usage triggered for $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" })." -Verbose
                $Data += "`n`n$(If ($Miners.Count -eq 1) { "The miner" } Else { "$($Miners.Count) miners" }) will re-measure power usage."
            }
            Else { 
                $Data = "`nNo matching stats found."
            }
            Break
        }
        If ($Parameters.Value) { $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | Where-Object { $Stats.$_.Minute -eq $Parameters.Value } | ForEach-Object { $Stats.$_ }) }
        Else { $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | ForEach-Object { $Stats.$_ }) } 
        If ($TempStats) { 
            $TempStats | Sort-Object Name | ForEach-Object { 
                Remove-Stat -Name $_.Name
                $Data += "`n$($_.Name -replace "_$($Parameters.Type)")"
            }
            Write-Message -Level Info "Web GUI: Removed $($TempStats.Count) $($Parameters.Type) stat file$(If ($TempStats.Count -ne 1) { "s" })."
            $Data += "`n`nRemoved $($TempStats.Count) $($Parameters.Type) stat file$(If ($TempStats.Count -ne 1) { "s" } with $($Parameters.Value)$($Parameters.Unit) $($Parameters.Type))."
        }
        Else { 
            $Data = "`nNo matching stats found."
        }
        Break
    }
    "/functions/stat/set" { 
        If ($Parameters.Miners -and $Parameters.Type -eq "HashRate" -and $null -ne $Parameters.Value) { 
            If ($Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithm) { 
                $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                    $_.Data = @()
                    If ($Parameters.Value -le 0 -and $Parameters.Type -eq "Hashrate") { $_.Available = $false; $_.Disabled = $true }
                    $Data += "`n$($_.Name) ($($_.Algorithm -join " & "))"
                    ForEach ($Algorithm in $_.Algorithm) { 
                        $StatName = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                        # Remove & set stat value
                        Remove-Stat -Name $StatName
                        If ($Parameters.Value -eq 0) { # Miner failed
                            $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = $_.Earning_Accuracy = [Double]::NaN
                            $_.Available = $false
                            $_.Disabled = $false
                            $_.Reason = @($_.Reason | Where-Object { $_ -notlike "Disabled by user" })
                            If ($_.Reason -notcontains "0 H/s Stat file" ) { $_.Reason += "0 H/s Stat file" }
                            $_.Status = [MinerStatus]::Failed
                        }
                        ElseIf ($Parameters.Value -eq -1) { # Miner disabled
                            $_.Available = $false
                            $_.Disabled = $true
                            $_.Reason = @($_.Reason | Where-Object { $_ -notlike "0 H/s Stat file" })
                            If ($_.Reason -notcontains "Disabled by user") { $_.Reason += "Disabled by user" }
                            $_.Status = [MinerStatus]::Disabled
                        }
                        $Stat = Set-Stat -Name $StatName -Value $Parameters.Value -FaultDetection $false
                    }
                }
                Write-Message -Level Verbose "Web GUI: Disabled $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" })." -Verbose
                $Data += "`n`n$(If ($Miners.Count -eq 1) { "The miner is" } Else { "$($Miners.Count) miners are" }) $(If ($Parameters.Value -eq 0) { "marked as failed" } ElseIf ($Parameters.Value -eq -1) { "disabled" } Else { "set to value $($Parameters.Value)" } )." 
            }
            Break
        }
    }
    "/functions/switchinglog/clear" { 
        Get-ChildItem -Path ".\Logs\switchinglog.csv" -File | Remove-Item -Force
        $Data = "<pre>Switching log '.\Logs\switchinglog.csv' cleared.</pre>"
        Break
    }
    "/functions/variables/get" { 
        If ($Key) { 
            $Data = $Variables.($Key -replace '\\|/','.' -split '\.' | Select-Object -Last 1) | Get-SortedObject | ConvertTo-Json -Depth 10
        }
        Else { 
            $Data = $Variables.Keys | Sort-Object | ConvertTo-Json -Depth 1
        }
        Break
    }
    "/functions/watchdogtimers/remove" { 
        $Data = @()
        ForEach ($WatchdogTimer in ($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue)) { 
            If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -EQ $WatchdogTimer.Name | Where-Object { $_.Algorithm -eq $WatchdogTimer.Algorithm -or $WatchdogTimer.Reason -eq "Miner suspended by watchdog (all algorithms)" })) { 
                # Remove Watchdog timers
                $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })
                $Data += "`n$($WatchdogTimer.Name) {$($WatchdogTimer.Algorithm -join '; ')}"

                # Update miner
                $Variables.Miners | Where-Object Name -EQ $WatchdogTimer.Name | Where-Object Algorithm -EQ $WatchdogTimer.Algorithm | ForEach-Object { 
                    $_.Reason = @($_.Reason | Where-Object { $_ -notlike "Miner suspended by watchdog *" })
                    If (-not $_.Reason) { $_.Available = $true }
                }
            }
        }
        ForEach ($WatchdogTimer in ($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue)) { 
            If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object PoolName -EQ $WatchdogTimer.Name | Where-Object { $_.Algorithm -EQ $WatchdogTimer.Algorithm -or $WatchdogTimer.Reason -eq "Pool suspended by watchdog" })) { 
                # Remove Watchdog timers
                $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })
                $Data += "`n$($WatchdogTimer.Name) {$($WatchdogTimer.Algorithm -join '; ')}"

                # Update pool
                $Variables.Pools | Where-Object Name -EQ $WatchdogTimer.Name | Where-Object Algorithm -EQ $WatchdogTimer.Algorithm | ForEach-Object { 
                    $_.Reason = @($_.Reason | Where-Object { $_ -notlike "Algorithm@Pool suspended by watchdog" })
                    $_.Reason = @($_.Reason | Where-Object { $_ -notlike "Pool suspended by watchdog*" })
                    If (-not $_.Reason) { $_.Available = $true }
                }
            }
        }
        If ($WatchdogTimers) { 
            $Message = "$($Data.Count) watchdog $(If ($Data.Count -eq 1) { "timer" } Else { "timers" }) removed."
            Write-Message -Level Verbose "Web GUI: $Message"
            $Data += "`n`n$Message"
        }
        Else { 
            $Data = "`nNo matching watchdog timers found."
        }
        Break
    }
    "/functions/watchdogtimers/reset" { 
        $Variables.WatchDogTimers = @()
        $Variables.Miners | Where-Object { $_.Reason -like "Miner suspended by watchdog *" } | ForEach-Object { $_.Reason = @($_.Reason | Where-Object { $_ -notlike "Miner suspended by watchdog *" }); $_ } | Where-Object { -not $_.Rason } | ForEach-Object { $_.Available = $true }
        $Variables.Pools | Where-Object { $_.Reason -like "*Pool suspended by watchdog" } | ForEach-Object { $_.Reason = @($_.Reason | Where-Object { $_ -notlike "*Pool suspended by watchdog" }); $_ } | Where-Object { -not $_.Rason } | ForEach-Object { $_.Available = $true }
        Write-Message -Level Verbose "Web GUI: All watchdog timers reset."
        $Data = "`nThe watchdog timers will be recreated on next cycle."
        Break
    }
    "/algorithms" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Algorithms | Select-Object)
        Break
    }
    "/allcurrencies" { 
        $Data = ConvertTo-Json -Depth 10 ($Variables.AllCurrencies)
        break
    }
    "/apiversion" { 
        $Data = ConvertTo-Json -Depth 10 @($APIVersion | Select-Object)
        Break
    }
    "/balances" { 
        $Data = ConvertTo-Json -Depth 10 ($Variables.Balances | Select-Object)
        Break
    }
    "/balancedata" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.BalanceData | Sort-Object DateTime -Descending)
        Break
    }
    "/btc" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Rates.BTC.($Config.Currency) | Select-Object)
        Break
    }
    "/balancescurrencies" { 
        $Data = ConvertTo-Json -Depth 10 ($Variables.BalancesCurrencies)
        break
    }
    "/brainjobs" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.BrainJobs | Select-Object)
        Break
    }
    "/coinnames" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.CoinNames | Select-Object)
        Break
    }
    "/config" { 
        $Data = ConvertTo-Json -Depth 10 (Get-Content -Path $Variables.ConfigFile | ConvertFrom-Json -Depth 10 | Get-SortedObject)
        If (-not ($Data | ConvertFrom-Json).ConfigFileVersion) { 
            $Data = ConvertTo-Json -Depth 10 ($Config | Select-Object -Property * -ExcludeProperty PoolsConfig)
        }
        Break
    }
    "/configfile" { 
        $Data = ConvertTo-Json -Depth 10 ($Variables.ConfigFile)
        break
    }
    "/configrunning" { 
        $Data = ConvertTo-Json -Depth 10 ($Config | Get-SortedObject)
        Break
    }
    "/currency" { 
        $Data = ConvertTo-Json -Depth 10 @($Config.Currency)
        Break
    }
    "/dagdata" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.DAGdata | Select-Object)
        Break
    }
    "/devices" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Sort-Object Name | Select-Object)
        Break
    }
    "/devices/enabled" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Where-Object State -EQ "Enabled" | Select-Object)
        Break
    }
    "/devices/disabled" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Where-Object State -EQ "Disabled" | Select-Object)
        Break
    }
    "/devices/unsupported" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Where-Object State -EQ "Unsupported" | Select-Object)
        Break
    }
    "/defaultalgorithm" { 
        $Data = ConvertTo-Json -Depth 10 (Get-DefaultAlgorithm)
        Break
    }
    "/displayworkers" { 
        If ($Config.ReportToServer -and $Config.MonitoringUser -and $Config.MonitoringServer) { 
            Receive-MonitoringData
            $DisplayWorkers = [System.Collections.ArrayList]@(
                $Variables.Workers | Select-Object @(
                    @{ Name = "Worker"; Expression = { $_.worker } }, 
                    @{ Name = "Status"; Expression = { $_.status } }, 
                    @{ Name = "LastSeen"; Expression = { "$($_.date)" } }, 
                    @{ Name = "Version"; Expression = { $_.version } }, 
                    @{ Name = "EstimatedEarning"; Expression = { [Decimal](($_.Data.Earning | Measure-Object -Sum).Sum) * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique) } }, 
                    @{ Name = "EstimatedProfit"; Expression = { [Decimal](($_.Data.Profit | Measure-Object -Sum).Sum) * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique) } }, 
                    @{ Name = "Currency"; Expression = { $_.Data.Currency | Select-Object -Unique } }, 
                    @{ Name = "Miner"; Expression = { $_.data.name -join '<br/>'} }, 
                    @{ Name = "Pool"; Expression = { ($_.data | ForEach-Object { ($_.Pool -split "," | ForEach-Object { $_ -replace "Internal$", " (Internal)" -replace "External", " (External)" }) -join " & "}) -join "<br/>" } }, 
                    @{ Name = "Algorithm"; Expression = { ($_.data | ForEach-Object { $_.Algorithm -split "," -join " & " }) -join "<br/>" } }, 
                    @{ Name = "Live Hashrate"; Expression = { If ($_.data.CurrentSpeed) { ($_.data | ForEach-Object { ($_.CurrentSpeed | ForEach-Object { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " }) -join " & " }) -join "<br/>" } Else { "" } } }, 
                    @{ Name = "Benchmark Hashrate"; Expression = { If ($_.data.EstimatedSpeed) { ($_.data | ForEach-Object { ($_.EstimatedSpeed | ForEach-Object { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " }) -join " & " }) -join "<br/>" } Else { "" } } }
                    ) | Sort-Object "Worker Name"
            )
            $Data = ConvertTo-Json @($DisplayWorkers | Select-Object)
        }
        Else { 
            $Data = $null
        }
        Break
    }
    "/earningschartdata" { 
        $Data = $Variables.EarningsChartData | ConvertTo-Json
        Break
    }
    "/earningschartdata24hr" { 
        $Data = $Variables.EarningsChartData24hr | ConvertTo-Json
        Break
    }
    "/extracurrencies" { 
        $Data = ConvertTo-Json -Depth 10 ($Config.ExtraCurrencies)
        break
    }
    "/miners" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, intervals | ConvertTo-Json -Depth 4 | ConvertFrom-Json | ForEach-Object { If ($_.WorkersRunning) { $_ | Add-Member Workers $_.WorkersRunning -Force }; $_ } | Select-Object -Property * -ExcludeProperty WorkersRunning | Sort-Object Status, DeviceName, Name)
        Break
    }
    "/minersmin" { 
        # Remove as much data as possible. bootstrap table data-url='/miners' fails to process large datasets (approx. more than 1.4MB)
        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, intervals | ConvertTo-Json -Depth 4 | ConvertFrom-Json | ForEach-Object { 
            If ($_.WorkersRunning) { $_ | Add-Member Workers $_.WorkersRunning -Force }
            $Pool = $_.Workers[0].Pool
            $_.Workers[0].PSObject.Properties.Remove("Disabled")
            $_.Workers[0].PSObject.Properties.Remove("Pool")
            $_.Workers[0].PSObject.Properties.Remove("TotalMiningDuration")
            $_.Workers[0].PSObject.Properties.Remove("Earning")
            $_.Workers[0].PSObject.Properties.Remove("Earning_Bias")
            $_.Workers[0].PSObject.Properties.Remove("Earning_Accuracy")
            $_.Workers[0] | Add-Member Pool @{ Name = $Pool.Name; Fee = $Pool.Fee }
            If ($_.Workers[1]) { 
                $_.Workers[1].PSObject.Properties.Remove("Disabled")
                $_.Workers[1].PSObject.Properties.Remove("Pool")
                $_.Workers[1].PSObject.Properties.Remove("TotalMiningDuration")
                $_.Workers[1].PSObject.Properties.Remove("Earning")
                $_.Workers[1].PSObject.Properties.Remove("Earning_Bias")
                $_.Workers[1].PSObject.Properties.Remove("Earning_Accuracy")
                $_.Workers[1] | Add-Member Pool @{ Name = $Pool.Name; Fee = $Pool.Fee }
            }
            $_
        } | Select-Object -Property * -ExcludeProperty Arguments, BeginTime, EndTime, Info, KeepRunning, LastSample, MeasurePowerUsage, StatEnd, StatStart, StatusMessage, Speed_Live, PowerUsage_Live, ReadPowerUsage, URI, WorkersRunning | Sort-Object Status, DeviceName, Name)
        Break
    }
    "/miners/available" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object Available -EQ $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process)
        Break
    }
    "/miners/best" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.BestMiners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process | ConvertTo-Json -Depth 4 | ConvertFrom-Json | ForEach-Object { If ($_.WorkersRunning) { $_ | Add-Member Workers $_.WorkersRunning -Force }; $_ } | Select-Object -Property * -ExcludeProperty WorkersRunning | Sort-Object Status, DeviceName, @{Expression = "Earning_Bias"; Descending = $True })
        Break
    }
    "/miners/bestminers_combo" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.BestMiners_Combo | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process)
        Break
    }
    "/miners/bestminers_combos" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.BestMiners_Combos | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process)
        Break
    }
    "/miners/failed" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object Status -EQ [MinerStatus]::Failed | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process  | SortObject DeviceName, EndTime)
        Break
    }
    "/miners/mostprofitable" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.MostProfitableMiners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process | Sort-Object Status, DeviceName, @{Expression = "Earning_Bias"; Descending = $True })
        Break
    }
    "/miners/running" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object Available -EQ $true | Where-Object Status -EQ "Running" | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, Workers | ConvertTo-Json -Depth 4 | ConvertFrom-Json | ForEach-Object { $_ | Add-Member Workers $_.WorkersRunning; $_ } | Select-Object -Property * -ExcludeProperty WorkersRunning)
        Break
    }
    "/miners/sorted" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.SortedMiners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process)
        Brea
    }
    "/miners/unavailable" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object Available -NE $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process)
        Break
    }
    "/miners_device_combos" { 
        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners_Device_Combos | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process)
        Break
    }
    "/miningpowercost" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.MiningPowerCost | Select-Object)
        Break
    }
    "/miningearning" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.MiningEarning | Select-Object)
        Break
    }
    "/miningprofit" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.MiningProfit | Select-Object)
        Break
    }
    "/newminers" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.NewMiners | Select-Object)
        Break
    }
    "/newpools" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.NewPools | Select-Object)
        Break
    }
    "/poolsconfig" { 
        $Data = ConvertTo-Json -Depth 10 @($Config.PoolsConfig | Select-Object)
        Break
    }
    "/poolsconfigfile" { 
        $Data = ConvertTo-Json -Depth 10 ($Variables.PoolsConfigFile)
        Break
    }
    "/poolnames" { 
        $Data = ConvertTo-Json -Depth 10 @((Get-ChildItem -Path ".\Pools" -File).BaseName | Sort-Object -Unique)
        Break
    }
    "/pools" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Select-Object | Sort-Object Name, Algorithm)
        Break
    }
    "/pools/available" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Where-Object Available -EQ $true | Select-Object | Sort-Object Name, Algorithm)
        Break
    }
    "/pools/best" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Where-Object Best -EQ $true | Select-Object | Sort-Object Best, Name, Algorithm)
        Break
    }
    "/pools/lastearnings" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsLastEarnings)
        Break
    }
    "/pools/lastused" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsLastUsed)
        Break
    }
    "/pools/unavailable" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Where-Object Available -NE $true | Select-Object | Sort-Object Name, Algorithm)
        Break
    }
    "/poolreasons" { 
        $Data = ConvertTo-Json -Depth 10 @(($Variables.Pools | Where-Object Available -NE $true).Reason | Sort-Object -Unique)
        Break
    }
    "/rates" { 
        $Data = ConvertTo-Json -Depth 10 ($Variables.Rates | Select-Object)
        Break
    }
    "/regions" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Regions.PSObject.Properties.Value | Sort-Object -Unique)
        Break
    }
    "/regionsdata" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Regions)
        Break
    }
    "/stats" { 
        $Data = ConvertTo-Json -Depth 10 @($Stats | Select-Object)
        Break
    }
    "/summary" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.Summary | Select-Object)
        Break
    }
    "/switchinglog" { 
        $Data = ConvertTo-Json -Depth 10 @(Get-Content ".\Logs\switchinglog.csv" | ConvertFrom-Csv | Select-Object -Last 1000)
        Break
    }
    "/unprofitablealgorithms" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.UnprofitableAlgorithms | Select-Object)
        Break
    }
    "/watchdogtimers" { 
        $Data = ConvertTo-Json -Depth 10 @($Variables.WatchdogTimers | Select-Object)
        Break
    }
    "/watchdogexpiration" { 
        $Data = ConvertTo-Json -Depth 10 @("$([math]::Floor($Variables.WatchdogReset / 60)) minutes $($Variables.WatchdogRest % 60) second$(If ($Variables.WatchdogRest % 60 -ne 1) { "s" })")
        Break
    }
    "/version" { 
        $Data = @("NemosMiner Version: $($Variables.Branding.Version)", "API Version: $($Variables.APIVersion)", "PWSH Version: $($PSVersionTable.PSVersion.ToString())") | ConvertTo-Json
        Break
    }
    Default { 
        # Set index page
        If ($Path -eq "/") { 
            $Path = "/index.html"
        }

        # Check if there is a file with the requested path
        $Filename = "$BasePath$Path"
        If (Test-Path $Filename -PathType Leaf -ErrorAction SilentlyContinue) { 
            # If the file is a PowerShell script, execute it and return the output. A $Parameters parameter is sent built from the query string
            # Otherwise, just return the contents of the file
            $File = Get-ChildItem $Filename -File

            If ($File.Extension -eq ".ps1") { 
                $Data = & $File.FullName -Parameters $Parameters
            }
            Else { 
                $Data = Get-Content $Filename -Raw

                # Process server side includes for html files
                # Includes are in the traditional '<!-- #include file="/path/filename.html" -->' format used by many web servers
                If ($File.Extension -eq ".html") { 
                    $IncludeRegex = [regex]'<!-- *#include *file="(.*)" *-->'
                    $IncludeRegex.Matches($Data) | Foreach-Object { 
                        $IncludeFile = $BasePath + '/' + $_.Groups[1].Value
                        If (Test-Path $IncludeFile -PathType Leaf) { 
                            $IncludeData = Get-Content $IncludeFile -Raw
                            $Data = $Data -replace $_.Value, $IncludeData
                        }
                    }
                }
            }

            # Set content type based on file extension
            If ($MIMETypes.ContainsKey($File.Extension)) { 
                $ContentType = $MIMETypes[$File.Extension]
            }
            Else { 
                # If it's an unrecognized file type, prompt for download
                $ContentType = "application/octet-stream"
            }
        }
        Else { 
            $StatusCode = 404
            $ContentType = "text/html"
            $Data = "URI '$Path' is not a valid resource."
        }
    }
}

# If $Data is null, the API will just return whatever data was in the previous request.  Instead, show an error
# This happens if the script just started and hasn't filled all the properties in yet. 
If ($Data -eq $null) { 
    $Data = @{ "Error" = "API data not available" } | ConvertTo-Json
}

# Fix for Powershell 5.1, cannot handle NaN in Json
If ($PSVersionTable.PSVersion -lt [Version]"6.0.0.0" ) { $Data = $Data -replace '":\s*NaN,', '":  "-",' }

$Data