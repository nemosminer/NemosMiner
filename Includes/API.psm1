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
File:           API.psm1
version:        3.9.9.1
version date:   25 August 2020
#>

Function Start-APIServer { 

    If ($Variables.APIRunspace) { 
        If ($Config.APIPort -ne $Variables.APIRunspace.APIPort -and $Variables.APIRunspace.AsyncObject.IsCompleted -ne $true) { 
            $null = Invoke-RestMethod "http://localhost:$($Variables.APIRunspace.APIPort)/functions/api/stop" -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop
            Start-Sleep -Seconds 2
        }
        If ($Variables.APIRunspace.AsyncObject.IsCompleted -eq $true) { 
            $Variables.APIRunspace.Close()
            $Variables.APIRunspace.PowerShell.EndInvoke($Variables.APIRunspace.AsyncObject)
            $Variables.APIRunspace.Dispose()
            $Variables.Remove("APIRunspace")
            $Variables.Remove("APIVersion")
            Start-Sleep -Seconds 2
        }
    }

    $APIVersion = "0.2.9.1"

    # Setup runspace to launch the API webserver in a separate thread
    $APIRunspace = [RunspaceFactory]::CreateRunspace()
    $APIRunspace.Open()
    Get-Variable -Scope Global | ForEach-Object { 
        Try { 
            $APIRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
        }
        Catch { }
    }
    $APIRunspace.SessionStateProxy.SetVariable("APIVersion", $APIVersion)
    $APIRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
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

            # Listening on anything other than localhost requires admin privileges
            $Server.Prefixes.Add("http://localhost:$($Config.APIPort)/")
            $Server.Start()

            While ($Server.IsListening) { 
                $Context = $Server.GetContext()
                $Request = $Context.Request
                $URL = $Request.Url.OriginalString

                # Determine the requested resource and parse query strings
                $Path = $Request.Url.LocalPath

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
                        If ($Variables.APIRunspace) { 
                            Write-Message "Web GUI: Stopping API."
                            $Response.Headers.Add("Content-Type", $ContentType)
                            $Response.StatusCode = $StatusCode
                            $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($Data)
                            $Response.ContentLength64 = $ResponseBuffer.Length
                            $Response.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
                            $Response.Close()
                            $Server.Stop()
                            $Server.Close()
                        }
                        Break
                    }
                    "/functions/config/set" { 
                        Try { 
                            Set-Content -Path $Variables.ConfigFile -Value ($Key | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty PoolsConfig | Get-SortedObject | ConvertTo-Json) -Encoding UTF8 #Out-File produces emtpy {} file
                            # $Key | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty PoolsConfig | Get-SortedObject | ConvertTo-Json | Out-File -FilePath $Variables.ConfigFile -Encoding UTF8
                            $Variables.RestartCycle = $true
                            $Data = "<pre>Config saved to `n'$($Variables.ConfigFile)'.</pre>"
                        }
                        Catch { 
                            $Data = "<pre>Error saving config file`n'$($Variables.ConfigFile)'.</pre>"
                        }
                        Break
                    }
                    "/functions/log/get" { 
                        If ([Int]$Parameters.Lines) { 
                            $Lines = [Int]$Parameters.Lines
                        }
                        Else { 
                            $Lines = 100
                        }
                        $Data = " $(Get-Content -Path $Variables.LogFile -Tail $Lines | ForEach-Object { "$($_)`n" } )"
                        Break
                    }
                    "/functions/mining/getstatus" { 
                        $Data = ConvertTo-Json ($Variables.MiningStatus)
                        Break
                    }
                    "/functions/mining/pause" { 
                        If ($Variables.MiningStatus -ne "Paused") { 
                            $Variables.NewMiningStatus = "Paused"
                        }
                        $Variables.RestartCycle = $true
                        $Data = "Mining is paused. BrainPlus and Balances Tracker running."
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/mining/start" { 
                        If ($Variables.MiningStatus -ne "Running") { 
                            $Variables.NewMiningStatus = "Running"
                        }
                        $Variables.RestartCycle = $true
                        $Data = "Mining processes started."
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/mining/stop" { 
                        If ($Variables.MiningStatus -ne "Stopped") { 
                            $Variables.NewMiningStatus = "Stopped"
                        }
                        $Variables.RestartCycle = $true
                        $Data = "NemosMiner is idle.`n"
                        If ($Variables.MiningStatus -eq "Running") { $Data += "`nMining stopped." }
                        $Data += "`nStopped Balances Tracker and Brain jobs."
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/log/clear" { 
                        If ($Parameters.Path) { 
                            #Get-ChildItem $Parameters.Path | Remove-Item -Force
                            $Data = "<pre>Log ($Parameters.Path) cleared.</pre>"
                        }
                        Break
                    }
                    "/functions/stat/get" { 
                        If ($null -eq $Parameters.Value) {
                            $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | ForEach-Object { $Stats.$_ })
                        }
                        Else {
                            $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | Where-Object { $Stats.$_.Minute -eq $Parameters.Value } | ForEach-Object { $Stats.$_ })
                        }
                        $TempStats | Sort-Object Name | ForEach-Object { $Data += "`n$($_.Name -replace "_$($Parameters.Type)")" }
                        If ($TempStats.Count -gt 0) { 
                            If ($Parameters.Value -eq 0) { $Data += "`n`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)$($Parameters.Unit) $($Parameters.Type)." }
                            $Data = "<pre>$Data</pre>"
                        }
                        Break
                    }
                    "/functions/stat/remove" { 
                        If ($Parameters.Pools) { 
                            $Pools = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Pools | Select-Object) @(($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue) | Select-Object) -Property Name, Algorithm
                            $Pools | Sort-Object Name | ForEach-Object { 
                                If ($_.Name -like "*Coins") { 
                                    $StatName = "$($_.Name)_$($_.Algorithm)-$($_.Currency)"
                                }
                                Else { 
                                    $StatName = "$($_.Name)_$($_.Algorithm)"
                                }
                                $Data += "`n$($StatName)"
                                Remove-Stat -Name "$($StatName)_Profit"
                                $_.Reason = [String[]]@()
                                $_.Price = $_.Price_Bias = $_.StablePrice = $_.MarginOfError = [Double]::Nan
                            }
                            If ($Pools.Count -gt 0) { 
                                $Message = "Pool data reset for $($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" })."
                                Write-Message "Web GUI: $Message"
                                $Data += "`n`n$Message"
                                $Data = "<pre>$Data</pre>"
                            }
                            Break
                        }
                        If ($Parameters.Miners -and $Parameters.Type -eq "HashRate") { 
                            $Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @(($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue) | Select-Object) -Property Name, Algorithm
                            $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                                If ($_.Status -EQ [MinerStatus]::Running) { 
                                    $Variables.EndLoopTime = Get-Date
                                    $Variables.EndLoop = $true
                                }
                                If ($_.Earning -eq 0) { 
                                    $_.Available = $true
                                }
                                $_.Activated = -1 #To allow 3 attempts
                                $_.Benchmark = $true
                                $_.Data = @()
                                $_.Speed = @()
                                $_.SpeedLive = @()
                                $Data += "`n$($_.Name) ($($_.Algorithm -join " & "))"
                                ForEach ($Algorithm in $_.Algorithm) { 
                                    Remove-Stat -Name "$($_.Name)_$($Algorithm)_Hashrate"
                                }
                                #Also clear power usage
                                Remove-Stat -Name "$($_.Name)$(If ($_.Algorithm.Count -eq 1) { "_$($_.Algorithm)" })_PowerUsage"
                                $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                            }
                            If ($Miners.Count -gt 0) { 
                                Write-Message "Web GUI: Re-benchmark triggered for $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" })."
                                $Data += "`n`nThe listed $(If ($Miners.Count -eq 1) { "miner" } Else { "$($Miners.Count) miners" }) will re-benchmark."
                                $Data = "<pre>$Data</pre>"
                            }
                            Break
                        }
                        If ($Parameters.Miners -and $Parameters.Type -eq "PowerUsage") { 
                            $Miners = Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @(($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue) | Select-Object) -Property Name, Algorithm
                            $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                                If ($_.Status -EQ [MinerStatus]::Running) { 
                                    $_.Data = @()
                                    $Variables.EndLoopTime = Get-Date
                                }
                                If ($_.Earning -eq 0) { 
                                    $_.Available = $true
                                }
                                $_.PowerUsage = [Double]::Nan
                                $_.MeasurePowerUsage = $true
                                $_.Activated = -1 #To allow 3 attempts
                                $_.Accuracy = 1
                                $_. Benchmark = $true
                                $StatName = "$($_.Name)$(If ($_.Algorithm.Count -eq 1) { "_$($_.Algorithm)" })"
                                $Data += "`nStatName"
                                Remove-Stat -Name "$($StatName)_PowerUsage"
                                $_.PowerUsage = $_.PowerCost = [Double]::Nan
                            }
                            If ($Miners.Count -gt 0) { 
                                Write-Message "Web GUI: Re-measure power usage triggered for $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" })."
                                $Data += "`n`nThe listed $(If ($Miners.Count -eq 1) { "miner" } Else { "$($Miners.Count) miners" }) will re-measure power usage."
                                $Data = "<pre>$Data</pre>"
                            }
                            Break
                        }
                        If ($null -eq $Parameters.Value) {
                            $TempStats = $Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | ForEach-Object { $Stats.$_ }
                        }
                        Else {
                            $TempStats = $Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | Where-Object { $Stats.$_.Minute -eq $Parameters.Value } | ForEach-Object { $Stats.$_ }
                        }
                        $TempStats | Sort-Object Name | ForEach-Object { 
                            Remove-Stat -Name $_.Name
                            $Data += "`n$($_.Name -replace "_$($Parameters.Type)")"
                        }
                        If ($TempStats.Count -gt 0) {
                            Write-Message "Web GUI: Removed $($TempStats.Count) $($Parameters.Type) stat file$(If ($TempStats.Count -ne 1) { "s" })."
                            $Data += "`n`nRemoved $($TempStats.Count) $($Parameters.Type) stat file$(If ($TempStats.Count -ne 1) { "s" })."
                            $Data = "<pre>$Data</pre>"
                        }
                        Break
                    }
                    "/functions/stat/set" { 
                        If ($Parameters.Miners -and $Parameters.Type -eq "HashRate" -and $Parameters.Value -ne $null) { 
                            $Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object | ForEach-Object { 
                                $Miners = @($Variables.Miners | Where-Object Name -EQ $_.Name | Where-Object Algorithm -EQ $_.Algorithm)
                                $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                                    $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = $Parameters.Value
                                    $_.Speed = [Double]::Nan
                                    $_.Data = @()
                                    $Data += "`n$($_.Name) ($($_.Algorithm -join " & "))"
                                    ForEach ($Algorithm in $_.Algorithm) { 
                                        $StatName = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                                        #Set stat value
                                        Set-Stat -Name $StatName -Value ($Parameters.Value) -Duration 0
                                    }
                                }
                            }
                            If ($Miners.Count -gt 0) {
                                Write-Message "Web GUI: Disabled $(If ($Miners.Count -eq 1) { "miner" } else { "$($Miners.Count) miners" })."
                                $Data += "`n`nThe listed $(If ($Miners.Count -eq 1) { "miner is" } else { "$($Miners.Count) miners are" }) $(If ($Parameters.Value -eq 0) { "disabled" } else { "set to value $($Parameters.Value)" } )." 
                                $Data = "<pre>$Data</pre>"
                            }
                            Break
                        }
                    }
                    "/functions/config/device/disable" { 
                        $Parameters.Keys | ForEach-Object {
                            $Key = $_
                            If ($Values = @($Parameters.$Key -split ',' | Where-Object { $_ -notin $Config.ExcludeDeviceName })) { 
                
                                $Data = "`nDevice configuration changed`n`nOld values:"
                                $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                $Config.ExcludeDeviceName = @((@($Config.ExcludeDeviceName) + $Values) | Sort-Object -Unique)
                                $Data += "`n`nNew values:"
                                $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                $Data += "`n`nUpdated configFile`n$($Variables.ConfigFile)"
                                Write-Config -ConfigFile $Variables.ConfigFile
                                $Values | ForEach-Object { 
                                    $DeviceName = $_
                                    $Variables.Devices | Where-Object Name -EQ $DeviceName | ForEach-Object { 
                                        $_.State = [DeviceState]::Disabled
                                        $_.Status = "Disabled (ExcludeDeviceName: '$DeviceName')"
                                        If ($_.Status -EQ [DeviceState]::Running) { Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore }
                                    }
                                }
                                Write-Message "Web GUI: Device '$($Values -join '; ')' disabled. Config file '$($Variables.ConfigFile)' updated."
                            }
                            Else { 
                                $Data = "No configuration change"
                            }
                        }
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/config/device/enable" { 
                        $Parameters.Keys | ForEach-Object {
                            $Key = $_
                            If ($Values = @($Parameters.$Key -split ',' | Where-Object { $_ -in $Config.ExcludeDeviceName })) { 
                                $Data = "`nDevice configuration changed`n`nOld values:"
                                $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                $Config.ExcludeDeviceName = @($Config.ExcludeDeviceName | Where-Object { $_ -notin $Values } | Sort-Object -Unique)
                                $Data += "`n`nNew values:"
                                $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                $Data += "`n`nUpdated configFile`n$($Variables.ConfigFile)"
                                Write-Config -ConfigFile $Variables.ConfigFile
                                $Variables.Devices | Where-Object Name -in $Values | ForEach-Object { $_.State = [DeviceState]::Enabled; $_.Status = "Idle" }
                                Write-Message "Web GUI: Device $($Values -join '; ') enabled. Config file '$($Variables.ConfigFile)' updated."
                            }
                            Else {
                                $Data = "No configuration change"
                            }
                        }
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/switchinglog/clear" { 
                        Get-ChildItem ".\Logs\switching2.log" | Remove-Item -Force
                        $Data = "<pre>Switching log cleared.</pre>"
                        Break
                    }
                    "/functions/watchdogtimers/reset" { 
                        $Variables.WatchdogTimersReset = $true
                        $Variables.WatchDogTimers = @()
                        $Data = $Variables.WatchdogTimersReset | ConvertTo-Json
                        Break
                    }
                    "/allrates" { 
                        $Data = ConvertTo-Json ($Variables.Rates | Select-Object)
                        Break
                    }
                    "/apiversion" { 
                        $Data = ConvertTo-Json -Depth 10 @($APIVersion | Select-Object)
                        Break
                    }
                    "/btcratefirstcurrency" { 
                        $Data = ConvertTo-Json @($Variables.Rates.BTC.($Config.Currency | Select-Object -Index 0) | Select-Object)
                        Break
                    }
                    "/brainjobs" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.BrainJobs | Select-Object)
                        Break
                    }
                    "/compareminers" { 
                        $Data = ConvertTo-Json @($Variables.CompareMiners | Select-Object)
                        Break
                    }
                    "/comparepools" { 
                        $Data = ConvertTo-Json @($Variables.ComparePools | Select-Object)
                        Break
                    }
                    "/config" {
                        # If (Test-Path $Variables.ConfigFile -PathType Leaf -ErrorAction Ignore) { 
                        #     $Data = Get-Content $Variables.ConfigFile -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore | Select-Object -Property * | Get-SortedObject | ConvertTo-Json -Depth 10
                        # }
                        # Else { 
                            $Data = $Config | Select-Object -Property * | Get-SortedObject | ConvertTo-Json -Depth 10
                        # }
                        Break
                    }
                    "/configfile" { 
                        $Data = $Variables.ConfigFile | ConvertTo-Json -Depth 10
                        break
                    }
                    "/currencies" { 
                        $Data = $Config.Currencies | ConvertTo-Json -Depth 10
                        break
                    }
                    "/devices" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Select-Object)
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
                    "/earnings" { 
                        $Data = ConvertTo-Json -Depth 10 ($Variables.Earnings | Select-Object)
                        Break
                    }
                    "/earningschartdata" { 
                        $ChartData = Get-Content ".\Logs\EarningsChartData.json" | ConvertFrom-Json
                        #Add BTC rate to avoid blocking NaN errors
                        $ChartData | Add-Member BTCrate ([Double]($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)))
                        $Data = $ChartData | ConvertTo-Json
                        Break
                    }
                    "/earningstrackerjob" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.EarningsTrackerJob | Select-Object -Property * -ExcludeProperty ChildJobs, Command, Process)
                        Break
                    }
                    "/firstcurrency" { 
                        $Data = ConvertTo-Json -Depth 10 @($Config.Currency | Select-Object -Index 0)
                        Break
                    }
                    "/miners" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Devices, Process, SideIndicator | Sort-Object Status, DeviceName, Name)
                        Break
                    }
                    "/miners/best" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Best -EQ $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Devices, Process, SideIndicator | Sort-Object Status, DeviceName, @{Expression = "Earning_Bias"; Descending = $True } )
                        Break
                    }
                    "/miners/available" { 
                        $Data = ConvertTo-Json -Depth 10  @($Variables.Miners | Where-Object Available -EQ $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Devices, Process, SideIndicator)
                        Break
                    }
                    "/miners/failed" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Status -EQ [MinerStatus]::Failed | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Devices, Process, SideIndicator | SortObject DeviceName, EndTime)
                        Break
                    }
                    "/miners/fastest" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Fastest -EQ $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Devices, Process, SideIndicator | Sort-Object Status, DeviceName, @{Expression = "Earning_Bias"; Descending = $True } )
                        Break
                    }
                    "/miners/idle" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Status -EQ [MinerStatus]::Idle | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Devices, Process, SideIndicator)
                        Break
                    }
                    "/miners/running" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Available -EQ $true | Where-Object Status -EQ "Running" | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Devices, Process, SideIndicator)
                        Break
                    }
                    "/miners/unavailable" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Available -NE $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Devices, Process, SideIndicator)
                        Break
                    }
                    "/miningcost" { 
                        $Data = ConvertTo-Json @($Variables.MiningCost | Select-Object)
                        Break
                    }
                    "/miningearning" { 
                        $Data = ConvertTo-Json @($Variables.MiningEarning | Select-Object)
                        Break
                    }
                    "/miningprofit" { 
                        $Data = ConvertTo-Json @($Variables.MiningProfit | Select-Object)
                        Break
                    }
                    "/newminers" { 
                        $Data = ConvertTo-Json @($Variables.NewMiners | Select-Object)
                        Break
                    }
                    "/newpools" { 
                        $Data = ConvertTo-Json @($Variables.NewPools | Select-Object)
                        Break
                    }
                    "/poolsconfig" { 
                        $Data = ConvertTo-Json -Depth 10 @($Config.PoolsConfig | Select-Object)
                        Break
                    }
                    "/poolnames" { 
                        $Data = ConvertTo-Json -Depth 10 @((Get-ChildItem ".\Pools" -File).BaseName | Sort-Object -Unique)
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
                    "/pools/unavailable" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Where-Object Available -NE $true | Select-Object | Sort-Object Name, Algorithm)
                        Break
                    }
                    "/rates" { 
                        $Rates = [PSCustomObject]@{ }
                        $Rates | Add-Member BTC ($Variables.Rates.BTC | ConvertTo-Json | ConvertFrom-Json)
                        $Rates.BTC | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $_ -notin (@($Config.Currency) + @("BTC"))  } | ForEach-Object { $Rates.BTC.PSObject.Properties.remove($_) }
                        $Data = ConvertTo-Json ($Rates | Select-Object)
                        Break
                    }
                    "/regions" { 
                        $Data = ConvertTo-Json ((Get-Content .\Includes\Regions.txt | ConvertFrom-Json).PSObject.Properties.Value | Sort-Object -Unique)
                        Break
                    }
                    "/stats" { 
                        $Data = ConvertTo-Json -Depth 10 @($Stats | Select-Object)
                        Break
                    }
                    "/summary" { 
                        $Data = ConvertTo-Json @($Variables.Summary | Select-Object)
                        Break
                    }
                    "/switchinglog" { 
                        $Data = ConvertTo-Json -Depth 10 @(Get-Content ".\Logs\switching2.log" | ConvertFrom-Csv | Select-Object -Last 1000)
                        Break
                    }
                    "/watchdogtimers" { 
                        $Data = ConvertTo-Json @($Variables.WatchdogTimers | Select-Object)
                        Break
                    }
                    "/variables" { 
                        $Data = ConvertTo-Json -Depth 5 $Variables | Select-Object
                        break
                    }
                    "/version" { 
                        $Data = @("NemosMiner Version: $($Variables.CurrentVersion)", "API Version: $($Variables.APIVersion)") | ConvertTo-Json
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
                                        if (Test-Path $IncludeFile -PathType Leaf) { 
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

                # Send the response
                $Response.Headers.Add("Content-Type", $ContentType)
                $Response.StatusCode = $StatusCode
                $ResponseBuffer = [System.Text.Encoding]::UTF8.GetBytes($Data)
                $Response.ContentLength64 = $ResponseBuffer.Length
                $Response.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
                $Response.Close()

            }
            # Only gets here if something is wrong and the server couldn't start or stops listening
            $Server.Stop()
            $Server.Close()
        }
    ) #end of $APIServer
    $AsyncObject = $PowerShell.BeginInvoke()

    $Variables.APIRunspace = $APIRunspace
    $Variables.APIRunspace | Add-Member -Force @{ 
        PowerShell = $PowerShell
        AsyncObject = $AsyncObject
    }
    If ($Variables.APIRunspace.AsyncObject.IsCompleted -ne $true) { 
        $Variables.APIRunspace | Add-Member -Force @{ APIPort = $Config.APIPort }
    }
}
