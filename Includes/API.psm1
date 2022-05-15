<#
Copyright (c) 2018-2022 Nemo, MrPlus & UselessGuru

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
File:           API.psm1
Version:        4.0.0.32
Version date:   15 May 2022
#>

Function Initialize-API { 

    If ($Variables.APIRunspace.AsyncObject.IsCompleted -eq $true) { 
        Stop-APIServer
        $Variables.Remove("APIVersion")
    }

    If ($Config.APIPort) { 

        # Initialize API & Web GUI
        If ($Config.APIPort -ne $Variables.APIRunspace.APIPort) { 

            Write-Message -Level Verbose "Initializing API & Web GUI on 'http://localhost:$($Config.APIPort)'..."

            $TCPClient = New-Object System.Net.Sockets.TCPClient
            $AsyncResult = $TCPClient.BeginConnect("localhost", $Config.APIPort, $null, $null)
            If ($AsyncResult.AsyncWaitHandle.WaitOne(100)) { 
                Write-Message -Level Error "Error initializing API & Web GUI on port $($Config.APIPort). Port is in use."
                Try { $TCPClient.EndConnect($AsyncResult) = $null }
                Catch { }
            }
            Else { 
                # Start API server
                Start-APIServer -Port $Config.APIPort

                # Wait for API to get ready
                $RetryCount = 3
                While (-not ($Variables.APIVersion) -and $RetryCount -gt 0) { 
                    Try {
                        If ($Variables.APIVersion = (Invoke-RestMethod "http://localhost:$($Variables.APIRunspace.APIPort)/apiversion" -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop)) { 
                            Write-Message -Level Info "Web GUI and API (version $($Variables.APIVersion)) running on http://localhost:$($Variables.APIRunspace.APIPort)."
                            # Start Web GUI (show config edit if no existing config)
                            If ($Config.WebGui) { Start-Process "http://localhost:$($Variables.APIRunspace.APIPort)/$(If ($Variables.FreshConfig -eq $true) { "configedit.html" })" }
                            Break
                        }
                    }
                    Catch { }
                    $RetryCount--
                    Start-Sleep -Seconds 1
                }
                If (-not $Variables.APIVersion) { Write-Message -Level Error "Error initializing API & Web GUI on port $($Config.APIPort)." }
                Remove-Variable RetryCount
            }
            $TCPClient.Close()
            Remove-Variable AsyncResult
            Remove-Variable TCPClient
        }
    }
}
Function Start-APIServer { 

    Param(
        [Parameter(Mandatory = $true)]
        [Int]$Port
    )

    Stop-APIServer

    $APIVersion = "0.4.5.3"

    If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): API ($APIVersion) started." | Out-File $Config.APILogFile -Encoding utf8NoBOM -Force }

    # Setup runspace to launch the API webserver in a separate thread
    $APIRunspace = [RunspaceFactory]::CreateRunspace()
    $APIRunspace.Open()
    Get-Variable -Scope Global | Where-Object Name -in @("Config", "Stats", "Variables") | ForEach-Object { 
        Try { 
            $APIRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
        }
        Catch { }
    }

    $Variables.APIRunspace = $APIRunspace
    $Variables.APIRunspace | Add-Member -Force @{ APIPort = $Port }

    $Variables.APIRunspace.SessionStateProxy.SetVariable("APIVersion", $APIVersion)
    $Variables.APIRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

    $PowerShell = [PowerShell]::Create()
    $PowerShell.Runspace = $APIRunspace
    $PowerShell.AddScript(
        { 
            (Get-Process -Id $PID).PriorityClass = "Normal"

            # Set the starting directory
            $BasePath = "$PWD\web"

            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

            # List of possible mime types for files
            $MIMETypes = @{ 
                ".js"   = "application/x-javascript"
                ".html" = "text/html"
                ".htm"  = "text/html"
                ".json" = "application/json"
                ".css"  = "text/css"
                ".txt"  = "text/plain"
                ".ico"  = "image/x-icon"
                ".ps1"  = "text/html" # ps1 files get executed, assume their response is html
            }

            # Setup the listener
            $Server = New-Object System.Net.HttpListener
            $Variables.APIRunspace | Add-Member -Force @{ APIServer = $Server }

            # Listening on anything other than localhost requires admin privileges
            $Server.Prefixes.Add("http://localhost:$($Variables.APIRunspace.APIPort)/")
            $Server.Start()

            While ($Server.IsListening) { 
                $Context = $Server.GetContext()
                $Request = $Context.Request

                # Determine the requested resource and parse query strings
                $Path = $Request.Url.LocalPath

                If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url)$($Request.Url.Query)" | Out-File $Config.APILogFile -Append -Encoding utf8NoBOM }

                # Parse any parameters in the URL - $Request.Url.Query looks like "+ ?a=b&c=d&message=Hello%20world"
                $Parameters = @{ }
                $Request.Url.Query -replace "\?", "" -split '&' | Foreach-Object { 
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
                        Write-Message -Level Verbose "API: API stopped!"
                        Return
                    }
                    "/functions/balancedata/remove" { 
                        If ($Parameters.Data) { 
                            $BalanceDataEntries = ($Parameters.Data | ConvertFrom-Json -ErrorAction SilentlyContinue)
                            $Variables.BalanceData = @((Compare-Object $Variables.BalanceData $BalanceDataEntries -PassThru -Property DateTime, Pool, Currency, Wallet) | Select-Object -ExcludeProperty SideIndicator)
                            $Variables.BalanceData | ConvertTo-Json | Out-File ".\Logs\BalancesTrackerData.json" -ErrorAction Ignore
                            If ($BalanceDataEntries.Count -gt 0) { 
                                $Variables.BalanceData | ConvertTo-Json | Out-File ".\Logs\BalancesTrackerData.json" -ErrorAction Ignore
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
                                    Write-Message -Level Verbose "Web GUI: Device$(If ($Values.Count -ne 1) { "s" } ) '$($Values -join '; ')' disabled. Config file '$($Variables.ConfigFile)' updated."
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
                                    Write-Message -Level Verbose "Web GUI: Device$(If ($Values.Count -ne 1) { "s" } ) '$($Values -join '; ')' enabled. Config file '$($Variables.ConfigFile)' updated."
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

                            Read-Config -ConfigFile $Variables.ConfigFile

                            Write-Message -Level Verbose "Web GUI: Configuration applied."
                            $Data = "Config saved to '$($Variables.ConfigFile)'. It will become active in next cycle."
                        }
                        Catch { 
                            $Data = "Error saving config file`n'$($Variables.ConfigFile)'."
                        }
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/file/edit" {
                        $Data = Edit-File $Parameters.FileName
                        Break
                    }
                    "/functions/file/showcontent" {
                        $Data = (Get-Content -Path $Parameters.FileName -Raw -ErrorAction Ignore)  -replace "(?<!\x0d)\x0a", "<br>"
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
                            $Data = "Mining is being paused...`n$(If ($Variables.BalancesTrackerPollInterval -gt 0) { If (-not $Variables.BalancesTrackerRunspace) { "Balances Tracker starting..." } Else { "Balances Tracker running." } })"
                            $Variables.RestartCycle = $true
                        }
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/mining/start" { 
                        If ($Variables.MiningStatus -ne "Running") { 
                            $Variables.NewMiningStatus = "Running"
                            $Data = "Mining processes starting...`n$(If ($Variables.BalancesTrackerPollInterval -gt 0) { If (-not $Variables.BalancesTrackerRunspace) { "Balances Tracker starting..." } Else { "Balances Tracker running." } })"
                            $Variables.RestartCycle = $true
                        }
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/mining/stop" { 
                        If ($Variables.MiningStatus -ne "Idle") { 
                            $Variables.NewMiningStatus = "Idle"
                            $Data = "$($Variables.Branding.ProductLabel) is getting idle...`n"
                            $Variables.RestartCycle = $true
                        }
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/pool/disable" { 
                        If ($Parameters.Pools) { 
                            $PoolsConfig = Get-Content -Path $Variables.PoolsConfigFile -ErrorAction Ignore | ConvertFrom-Json
                            $Pools = @(($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue) | Sort-Object Name, Algorithm -Unique)
                            $Pools | Group-Object Name | ForEach-Object { 
                                $PoolName = $_.Name -replace " External$| Internal$"
                                $PoolBaseName = (Get-PoolBaseName $PoolName)

                                $PoolConfig = If ($PoolsConfig.$PoolBaseName) { $PoolsConfig.$PoolBaseName } Else { [PSCustomObject]@{ } }
                                [System.Collections.ArrayList]$AlgorithmList = @(($PoolConfig.Algorithm -replace " ") -split ',')

                                ForEach ($Algorithm in $_.Group.Algorithm) { 
                                    $AlgorithmList.Remove("+$Algorithm")
                                    If (-not ($AlgorithmList -match "\+.+") -and $AlgorithmList -notcontains "-$Algorithm") { $AlgorithmList += "-$Algorithm" }

                                    $Reason = "Algorithm disabled (``-$($Algorithm)`` in $PoolBaseName pool config)"
                                    $Variables.Pools | Where-Object BaseName -EQ $PoolName | Where-Object Algorithm -EQ $Algorithm | ForEach-Object { 
                                        $_.Reason = @($_.Reason | Where-Object { $_ -notmatch $Reason })
                                        $_.Reason += $Reason
                                        $_.Available = $false
                                    }
                                    $Data += "`n$Algorithm@$PoolName ($((($Variables.Pools | Where-Object Name -EQ $PoolName | Where-Object Algorithm -EQ $Algorithm).Region | Sort-Object -Unique) -join ', '))"
                                }

                                If ($AlgorithmList) { $PoolConfig | Add-Member Algorithm (($AlgorithmList | Sort-Object) -join ',' -replace "^,+") -Force } Else { $PoolConfig.PSObject.Properties.Remove('Algorithm') }
                                If (($PoolConfig | Get-Member -MemberType NoteProperty).Name) { $PoolsConfig | Add-Member $PoolBaseName $PoolConfig -Force } Else { $PoolsConfig.PSObject.Properties.Remove($PoolName) }
                            }
                            $DisabledPoolsCount = $Pools.Count
                            If ($DisabledPoolsCount -gt 0) { 
                                # Write PoolsConfig
                                $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Set-Content -Path $Variables.PoolsConfigFile -Force -ErrorAction Ignore
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
                            $Pools = @(($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue) | Sort-Object Name, Algorithm -Unique)
                            $Pools | Group-Object Name | ForEach-Object { 
                                $PoolName = $_.Name -replace " External$| Internal$"
                                $PoolBaseName = (Get-PoolBaseName $PoolName)

                                $PoolConfig = If ($PoolsConfig.$PoolBaseName) { $PoolsConfig.$PoolBaseName } Else { [PSCustomObject]@{ } }
                                [System.Collections.ArrayList]$AlgorithmList = @(($PoolConfig.Algorithm -replace " ") -split ',')

                                ForEach ($Algorithm in $_.Group.Algorithm) { 
                                    $AlgorithmList.Remove("-$Algorithm")
                                    If ($AlgorithmList -match "\+.+" -and $AlgorithmList -notcontains "+$Algorithm") { $AlgorithmList += "+$Algorithm" }

                                    $Reason = "Algorithm disabled (``-$($Algorithm)`` in $PoolBaseName pool config)"
                                    $Variables.Pools | Where-Object BaseName -EQ $PoolName | Where-Object Algorithm -EQ $Algorithm | ForEach-Object { 
                                        $_.Reason = @($_.Reason | Where-Object { $_ -ne $Reason })
                                        If (-not $_.Reason) { $_.Available = $true }
                                    }
                                    $Data += "`n$Algorithm@$PoolName ($((($Variables.Pools | Where-Object Name -EQ $PoolName | Where-Object Algorithm -EQ $Algorithm).Region | Sort-Object -Unique) -join ', '))"
                                }

                                If ($AlgorithmList) { $PoolConfig | Add-Member Algorithm (($AlgorithmList | Sort-Object) -join ',' -replace "^,+") -Force } Else { $PoolConfig.PSObject.Properties.Remove('Algorithm') }
                                If (($PoolConfig | Get-Member -MemberType NoteProperty).Name) { $PoolsConfig | Add-Member $PoolBaseName $PoolConfig -Force } Else { $PoolsConfig.PSObject.Properties.Remove($PoolName) }
                            }
                            $EnabledPoolsCount = $Pools.Count
                            If ($EnabledPoolsCount -gt 0) { 
                                # Write PoolsConfig
                                $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Set-Content -Path $Variables.PoolsConfigFile -Force -ErrorAction Ignore
                                $Message = "$EnabledPoolsCount $(If ($EnabledPoolsCount -eq 1) { "algorithm" } Else { "algorithms" }) enabled."
                                Write-Message -Level Verbose "Web GUI: $Message"
                                $Data += "`n`n$Message"
                            }
                            Break
                        }
                    }
                    "/functions/stat/get" { 
                        $TempStats = @(If ($null -ne $Parameters.Value) { @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | Where-Object { $Stats.$_.Live -eq $Parameters.Value } | ForEach-Object { $Stats.$_ }) } Else { @($Stats) })

                        If ($TempStats) { 
                            If ($null -ne $Parameters.Value) { 
                                $TempStats | Sort-Object Name | ForEach-Object { $Data += "`n$($_.Name -replace "_$($Parameters.Type)")" }
                                If ($Parameters.Type -eq "Hashrate") { $Data += "`n`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)H/s $($Parameters.Type)." }
                                ElseIf ($Parameters.Type -eq "PowerUsage") { $Data += "`n`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)W $($Parameters.Type)." }
                            }
                            Else { 
                                $Data = $TempStats | ConvertTo-Json
                            }
                        }
                        Else { 
                            $Data = "`nNo matching stats found."
                        }
                        Break
                    }
                    "/functions/removeorphanedminerstats" { 
                        If ($StatNames = Remove-OrphanedMinerStats) { 
                            $Data = $StatNames | ConvertTo-Json
                        }
                        Else { 
                            $Data = "`nNo matching stats found."
                        }
                        Break
                    }
                    "/functions/stat/remove" { 
                        If ($Parameters.Pools) { 
                            If ($Pools = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Pools | Select-Object) @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Algorithm, Currency, Name, Region)) { 
                                $Pools | Sort-Object Name | ForEach-Object { 
                                    $Stat_Name = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                                    $Data += "`n$($Stat_Name) ($($_.Region))"
                                    Remove-Stat -Name "$($Stat_Name)_Profit"
                                    $_.Reason = [String[]]@()
                                    $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                                    $_.Available = $true
                                    $_.Disabled = $false
                                }
                                $Message = "Reset pool stats for $($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" })."
                                Write-Message -Level Verbose "Web GUI: $Message"
                                $Data += "`n`n$Message"
                            }
                            Else { 
                                $Data = "`nNo matching pool stats found."
                            }
                            Break
                        }
                        ElseIf ($Parameters.Miners -and $Parameters.Type -eq "HashRate") { 
                            If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithm)) { 
                                $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                                    If ($_.Earning -eq 0) { $_.Available = $true }
                                    $_.Earning_Accuracy = [Double]::NaN
                                    $_.Activated = 0 # To allow 3 attempts
                                    $_.Disabled = $false
                                    $_.Benchmark = $true
                                    $_.Restart = $true
                                    $_.Workers | ForEach-Object { $_.Speed = [Double]::NaN }
                                    $Data += "`n$($_.Name) ($($_.Algorithm -join " & "))"
                                    ForEach ($Algorithm in $_.Algorithm) { 
                                        Remove-Stat -Name "$($_.Name)_$($Algorithm)_Hashrate"
                                        $_.Disabled = $false
                                    }
                                    # Also clear power usage
                                    Remove-Stat -Name "$($_.Name)$(If ($_.Algorithm.Count -eq 1) { "_$($_.Algorithm)" })_PowerUsage"
                                    $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN

                                    $_.Reason = @($_.Reason | Where-Object { $_ -ne "Disabled by user" })
                                    $_.Reason = @($_.Reason | Where-Object { $_ -ne "0 H/s Stat file" })
                                    If (-not $_.Reason) { $_.Available = $true }

                                    If ($_.Status -eq "Running") { $Variables.EndLoopTime = (Get-Date).ToUniversalTime() } # End loop immediately
                                }
                                Write-Message -Level Verbose "Web GUI: Re-benchmark triggered for $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" })."
                                $Data += "`n`n$(If ($Miners.Count -eq 1) { "The miner" } Else { "$($Miners.Count) miners" }) will re-benchmark."
                            }
                            Else { 
                                $Data = "`nNo matching hashrate stats found."
                            }
                            Break
                        }
                        ElseIf ($Parameters.Miners -and $Parameters.Type -eq "PowerUsage") { 
                            If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithm)) { 
                                $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                                    If ($_.Earning -eq 0) { $_.Available = $true }
                                    If ($Variables.CalculatePowerCost) { 
                                        $_.MeasurePowerUsage = $true
                                        $_.Activated = 0 # To allow 3 attempts
                                    }
                                    $Stat_Name = "$($_.Name)$(If ($_.Algorithm.Count -eq 1) { "_$($_.Algorithm)" })"
                                    $Data += "`n$Stat_Name"
                                    Remove-Stat -Name "$($Stat_Name)_PowerUsage"
                                    $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN

                                    If ($_.Status -eq "Running") { $Variables.EndLoopTime = (Get-Date).ToUniversalTime() } # End loop immediately
                                }
                                Write-Message -Level Verbose "Web GUI: Re-measure power usage triggered for $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" })." -Verbose
                                $Data += "`n`n$(If ($Miners.Count -eq 1) { "The miner" } Else { "$($Miners.Count) miners" }) will re-measure power usage."
                            }
                            Else { 
                                $Data = "`nNo matching power usage stats found."
                            }
                            Break
                        }
                        If ($Parameters.Value) { $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | Where-Object { $Stats.$_.Live -eq $Parameters.Value } | ForEach-Object { $Stats.$_ }) }
                        Else { $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | ForEach-Object { $Stats.$_ }) } 
                        If ($TempStats) {
                            $TempStats | Sort-Object Name | ForEach-Object { 
                                Remove-Stat -Name $_.Name
                                $Data += "`n$($_.Name -replace "_$($Parameters.Type)")"
                            }
                            Write-Message -Level Info "Web GUI: Removed $($TempStats.Count) $($Parameters.Type) stat file$(If ($TempStats.Count -ne 1) { "s" })."
                            If ($Parameters.Type -eq "Hashrate") { $Data += "`n`nReset $($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)H/s $($Parameters.Type)." }
                            ElseIf ($Parameters.Type -eq "PowerUsage") { $Data += "`n`nReset $($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)W $($Parameters.Type)." }
                            ElseIf ($Parameters.Type -eq "Profit") { $Data += "`n`nReset $($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" })." }
                        }
                        Else { 
                            $Data = "`nNo matching stats found."
                        }
                        Break
                    }
                    "/functions/stat/set" { 
                        If ($Parameters.Miners -and $Parameters.Type -eq "HashRate" -and $null -ne $Parameters.Value) { 
                            If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithm)) {
                                $Miners | Sort-Object Name, Algorithm | ForEach-Object {
                                    $_.Data = @()
                                    If ($Parameters.Value -le 0 -and $Parameters.Type -eq "Hashrate") { $_.Available = $false; $_.Disabled = $true }
                                    $Data += "`n$($_.Name) ($($_.Algorithm -join " & "))"
                                    ForEach ($Algorithm in $_.Algorithm) { 
                                        $Stat_Name = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                                        If ($Parameters.Value -eq 0) { # Miner failed
                                            Remove-Stat -Name $Stat_Name
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
                                        Set-Stat -Name $Stat_Name -Value $Parameters.Value -FaultDetection $false | Out-Null
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
                            $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "watchdog timer" } Else { "watchdog timers" }) removed."
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
                        $Variables.Miners | ForEach-Object { $_.Reason = @($_.Reason | Where-Object { $_ -notlike "Miner suspended by watchdog *" }); $_ } | Where-Object { -not $_.Reason } | ForEach-Object { $_.Available = $true }
                        $Variables.Pools | ForEach-Object { $_.Reason = @($_.Reason | Where-Object { $_ -notlike "*Pool suspended by watchdog" }); $_ } | Where-Object { -not $_.Reason } | ForEach-Object { $_.Available = $true }
                        Write-Message -Level Verbose "Web GUI: All watchdog timers reset."
                        $Data = "`nWatchdog timers will be recreated in next cycle."
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
                        $Data = ConvertTo-Json -Depth 2 @($Variables.BrainJobs | Select-Object)
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
                    "/dagdata2" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.DAGdata.Currency | Select-Object)
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
                        If ($Config.MonitoringServer -and $Config.MonitoringUser -and $Config.ShowWorkerStatus) { 
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
                    "/driverversion" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.DriverVersion | Select-Object)
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
                        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, intervals | ForEach-Object { If ($_.WorkersRunning) { $_ | Add-Member Workers $_.WorkersRunning -Force }; $_ } | Select-Object -Property * -ExcludeProperty WorkersRunning | Sort-Object Status, DeviceName, Name)
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
                    "/miners/disabled" { 
                        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object { $_.Status -EQ [MinerStatus]::Disabled } | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process  | Sort-Object DeviceName, EndTime)
                        Break
                    }
                    "/miners/failed" { 
                        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object { $_.Status -EQ [MinerStatus]::Failed } | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process  | Sort-Object DeviceName, EndTime)
                        Break
                    }
                    "/miners/mostprofitable" { 
                        $Data = ConvertTo-Json -Depth 4 @($Variables.MostProfitableMiners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process | Sort-Object Status, DeviceName, @{Expression = "Earning_Bias"; Descending = $True })
                        Break
                    }
                    "/miners/running" { 
                        $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object Available -EQ $true | Where-Object { $_.Status -EQ [MinerStatus]::Running } | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, Workers | ConvertTo-Json -Depth 4 | ConvertFrom-Json | ForEach-Object { $_ | Add-Member Workers $_.WorkersRunning; $_ } | Select-Object -Property * -ExcludeProperty WorkersRunning)
                        Break
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
                    "/pooldata" { 
                        $Data = ConvertTo-Json -Depth 10 ($Variables.PoolData)
                        break
                    }
                    "/pooldata" { 
                        $Data = ConvertTo-Json -Depth 10 ($Variables.PoolData)
                        break
                    }
                    "/poolnames" { 
                        $Data = ConvertTo-Json -Depth 10 ($Variables.PoolNames)
                        break
                    }
                    "/pools" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Select-Object | Sort-Object Name, Algorithm)
                        Break
                    }
                    "/pools/added" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.AddedPools | Select-Object | Sort-Object Name, Algorithm)
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
                    "/pools/new" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.NewPools | Select-Object | Sort-Object Name, Algorithm)
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
                    "/pools/updated" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.UpdatedPools | Select-Object | Sort-Object Name, Algorithm)
                        Break
                    }
                    "/poolreasons" { 
                        $Data = ConvertTo-Json -Depth 10 @(($Variables.Pools | Where-Object Available -NE $true).Reason | Sort-Object -Unique)
                        Break
                    }
                    "/poolvariants" { 
                        $Data = ConvertTo-Json -Depth 10 ($Variables.PoolVariants)
                        break
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
                    "/wallets" { 
                        $Data = ConvertTo-Json -Depth 10 @($Config.Wallets | Select-Object)
                        Break
                    }
                    "/watchdogexpiration" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.WatchdogReset)
                        Break
                    }
                    "/version" { 
                        $Data = @("$($Variables.Branding.ProductLabel) Version: $($Variables.Branding.Version)", "API Version: $($Variables.APIVersion)", "PWSH Version: $($PSVersionTable.PSVersion.ToString())") | ConvertTo-Json
                        Break
                    }
                    Default { 
                        # Set index page
                        If ($Path -eq "/") { $Path = "/index.html" }

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

                # If $Data is null, the API will just return whatever data was in the previous request. Instead, show an error
                # This happens if the script just started and hasn't filled all the properties in yet. 
                If ($null -eq $Data) { 
                    $Data = @{ "Error" = "API data not available" } | ConvertTo-Json
                }

                # Send the response
                $Response.Headers.Add("Content-Type", $ContentType)
                $Response.StatusCode = $StatusCode
                $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($Data)
                $Response.ContentLength64 = $ResponseBuffer.Length
                $Response.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
                $Response.Close()

                Remove-Variable AlgorithmList, BalanceDataEntries, ContentType, Data, DisabledPoolsCount, EnabledPoolsCount, File, DisplayWorkers, IncludeData, IncludeFile, IncludeRegex, Key, Lines, Message, MinerNames, Miners, Path, PoolConfig, PoolBaseName, PoolName, Pools, Reason, ResponseBuffer, Stat_Name, StatusCode, TempStats, Value, Values, WatchdogTimer, WatchdogTimers -ErrorAction SilentlyContinue
            }
            # Only gets here if something is wrong and the server couldn't start or stops listening
            $Server.Stop()
            $Server.Close()
        }
    ) # End of $APIServer
    $AsyncObject = $PowerShell.BeginInvoke()

    $Variables.APIRunspace | Add-Member -Force @{ 
        PowerShell = $PowerShell
        AsyncObject = $AsyncObject
    }
}

Function Stop-APIServer {
    If ($Variables.APIRunspace) { 
        If ($Variables.APIRunspace.APIServer) { 
            If ($Variables.APIRunspace.APIServer.IsListening) { $Variables.APIRunspace.APIServer.Stop() }
            $Variables.APIRunspace.APIServer.Close()
        }
        $Variables.APIRunspace.APIPort = $null
        $Variables.APIRunspace.Close()
        If ($Variables.APIRunspace.PowerShell) { $Variables.APIRunspace.PowerShell.Dispose() }
        $Variables.Remove("APIRunspace")
    }
}
