<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

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
Version:        4.3.4.6
Version date:   03 May 2023
#>

Function Start-APIServer { 

    $APIVersion = "0.5.2.0"

    If ($Variables.APIRunspace.AsyncObject.IsCompleted -or $Config.APIPort -ne $Variables.APIRunspace.APIPort) { 
        Stop-APIServer
        $Variables.Remove("APIVersion")
    }

    # Initialize API & Web GUI
    If ($Config.APIPort -and -not $Variables.APIRunspace.APIPort) { 

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
            If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): API ($APIVersion) started." | Out-File $Config.APILogFile -Encoding utf8NoBOM -Force }

            # Setup runspace to launch the API webserver in a separate thread
            $Variables.APIRunspace = [RunspaceFactory]::CreateRunspace()
            $Variables.APIRunspace.Open()
            Get-Variable -Scope Global | Where-Object Name -in @("Config", "Stats", "Variables") | ForEach-Object { 
                $Variables.APIRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
            }
            $Variables.APIRunspace.SessionStateProxy.SetVariable("APIVersion", $APIVersion)
            $Variables.APIRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath) | Out-Null

            $Variables.APIRunspace | Add-Member -Force @{ APIPort = $Config.APIPort }

            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $Variables.APIRunspace
            [Void]$PowerShell.AddScript(
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
                    $Server.Prefixes.Add("http://localhost:$($Config.APIPort)/")
                    $Server.Start()

                    While ($Server.IsListening) { 
                        $Context = $Server.GetContext()
                        $Request = $Context.Request

                        # Determine the requested resource and parse query strings
                        $Path = $Request.Url.LocalPath

                        If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url)" | Out-File $Config.APILogFile -Append -Encoding utf8NoBOM -ErrorAction Ignore}

                        If ($Request.HttpMethod -eq "GET") { 
                            # Parse any parameters in the URL - $Request.Url.Query looks like "+ ?a=b&c=d&message=Hello%20world"
                            # Decode any url escaped characters in the key and value
                            $Parameters = @{ }
                            $Request.Url.Query -replace "\?", "" -split "&" | Foreach-Object { 
                                $Key, $Value = $_ -split "="
                                # Decode any url escaped characters in the key and value
                                $Key = [URI]::UnescapeDataString($Key)
                                $Value = [URI]::UnescapeDataString($Value)
                                If ($Key -and $Value) { 
                                    $Parameters.$Key = $Value
                                    If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") GET: '$($Key)': '$($Value)'" | Out-File $Config.APILogFile -Append -Encoding utf8NoBOM -ErrorAction Ignore}
                                }
                            }
                        }
                        ElseIf ($Request.HttpMethod -eq "POST") { 
                            $Length = $Request.contentlength64
                            $Buffer = New-object "byte[]" $Length

                            [Void]$Request.inputstream.read($Buffer, 0, $Length)
                            $Body = [System.Text.Encoding]::ascii.getstring($Buffer)

                            $Parameters = @{ }
                            $Body -split "&" | ForEach-Object { 
                                $Key, $Value = $_ -split "="
                                # Decode any url escaped characters in the key and value
                                $Key = [URI]::UnescapeDataString($Key)
                                $Value = [URI]::UnescapeDataString($Value)
                                If ($Key -and $Value) { 
                                    $Parameters.$Key = $Value
                                    If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") POST: '$($Key)': '$($Value)'" | Out-File $Config.APILogFile -Append -Encoding utf8NoBOM -ErrorAction Ignore}
                                }
                            }
                        }

                        # Create a new response and the defaults for associated settings
                        $Response = $Context.Response
                        $ContentType = "application/json"
                        $StatusCode = 200
                        $Data = ""

                        # Set the proper content type, status code and data for each resource
                        Switch ($Path) { 
                            "/functions/algorithm/disable" { 
                                # Disable algorithm@pool in poolsconfig.json
                                $PoolBaseNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).BaseName
                                $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).Algorithm
                                If ($Pools = @($Variables.Pools | Where-Object { $_.BaseName -in $PoolBaseNames -and $_.Algorithm -in $Algorithms })) { 
                                    $PoolsConfig = Get-Content -Path $Config.PoolsConfigFile | ConvertFrom-Json
                                    ForEach ($Pool in $Pools) { 
                                        If ($PoolsConfig.($Pool.BaseName).Algorithm -like "-*") { 
                                            $PoolsConfig.($Pool.BaseName).Algorithm = @($PoolsConfig.($Pool.BaseName).Algorithm += "-$($Pool.Algorithm)" | Sort-Object -Unique)
                                            $Pool.Reasons = @($Pool.Reasons += "Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.BaseName) pool config)" | Sort-Object -Unique)
                                        }
                                        Else { 
                                            $PoolsConfig.($Pool.BaseName).Algorithm = @($PoolsConfig.($Pool.BaseName).Algorithm | Where-Object { $_ -ne "+$($Pool.Algorithm)" } | Sort-Object -Unique)
                                            $Pool.Reasons = @($Pool.Reasons += "Algorithm not enabled in $($Pool.BaseName) pool config" | Sort-Object -Unique)
                                        }
                                        $Pool.Available = $false
                                        $Data += "$($Pool.Algorithm)@$($Pool.BaseName)`n"
                                    }
                                    Remove-Variable Pool
                                    $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" }) disabled."
                                    Write-Message -Level Verbose "Web GUI: $Message"
                                    $Data += "`n$Message"
                                    $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $Variables.PoolsConfigFile -Force -Encoding utf8NoBOM
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/algorithm/enable" { 
                                # Enable algorithm@pool in poolsconfig.json
                                $PoolBaseNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).BaseName
                                $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).Algorithm
                                If ($Pools = @($Variables.Pools | Where-Object { $_.BaseName -in $PoolBaseNames -and $_.Algorithm -in $Algorithms })) { 
                                    $PoolsConfig = Get-Content -Path $Config.PoolsConfigFile | ConvertFrom-Json
                                    ForEach ($Pool in $Pools) { 
                                        If ($PoolsConfig.($Pool.BaseName).Algorithm -like "+*") { 
                                            $PoolsConfig.($Pool.BaseName).Algorithm = @($PoolsConfig.($Pool.BaseName).Algorithm += "+$($Pool.Algorithm)" | Sort-Object -Unique)
                                            $Pool.Reasons = @($Pool.Reasons | Where-Object { $_ -ne "Algorithm not enabled in $($Pool.BaseName) pool config" } | Sort-Object -Unique)
                                        }
                                        Else { 
                                            $PoolsConfig.($Pool.BaseName).Algorithm = @($PoolsConfig.($Pool.BaseName).Algorithm | Where-Object { $_ -ne "-$($Pool.Algorithm)" } | Sort-Object -Unique)
                                            $Pool.Reasons = @($Pool.Reasons | Where-Object { $_ -ne "Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.BaseName) pool config)" } | Sort-Object -Unique)
                                        }
                                        If (-not $Pool.Reasons) { $Pool.Available = $true }
                                        $Data += "$($Pool.Algorithm)@$($Pool.BaseName)`n"
                                    }
                                    Remove-Variable Pool
                                    $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" }) enabled."
                                    Write-Message -Level Verbose "Web GUI: $Message"
                                    $Data += "`n$Message"
                                    $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $Variables.PoolsConfigFile -Force -Encoding utf8NoBOM
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/api/stop" { 
                                Write-Message -Level Verbose "API: API stopped!"
                                Return
                            }
                            "/functions/balancedata/remove" { 
                                If ($Parameters.Data) { 
                                    $BalanceDataEntries = $Variables.BalanceData
                                    $Variables.BalanceData = @((Compare-Object $Variables.BalanceData @($Parameters.Data | ConvertFrom-Json -ErrorAction SilentlyContinue) -PassThru -Property DateTime, Pool, Currency, Wallet) | Where-Object SideIndicator -eq "<=" | Select-Object -ExcludeProperty SideIndicator)
                                    $Variables.BalanceData | ConvertTo-Json | Out-File ".\Data\BalancesTrackerData.json"
                                    $RemovedEntriesCount = $BalanceDataEntries.Count - $Variables.BalanceData.Count
                                    If ($RemovedEntriesCount-gt 0) { 
                                        $Message = "$RemovedEntriesCount $(If ($RemovedEntriesCount -eq 1) { "balance data entry" } Else { "balance data entries" }) removed."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = $Message
                                    }
                                    Else { 
                                        $Data = "No matching entries found."
                                    }
                                    $Data = "<pre>$Data</pre>"
                                    Break
                                }
                            }
                            "/functions/config/device/disable" { 
                                ForEach ($Key in $Parameters.Keys) {
                                    If ($Values = @($Parameters.$Key -split ',' | Where-Object { $_ -notin $Config.ExcludeDeviceName })) { 
                                        Try { 
                                            $ExcludeDeviceName = $Config.ExcludeDeviceName
                                            $Config.ExcludeDeviceName = @((@($Config.ExcludeDeviceName) + $Values) | Sort-Object -Unique)
                                            Write-Config -ConfigFile $Variables.ConfigFile -Config $Config
                                            $Data = "Device configuration changed`n`nOld values:"
                                            $Data += "`nExcludeDeviceName: '[$($ExcludeDeviceName -join ', ')]'"
                                            $Data += "`n`nNew values:"
                                            $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                            $Data += "`n`nConfiguration saved to '$($Variables.ConfigFile)'.`nIt will become active in next cycle."
                                            ForEach ($DeviceName in $Values) { 
                                                $Variables.Devices | Where-Object Name -EQ $DeviceName | ForEach-Object { 
                                                    $_.State = [DeviceState]::Disabled
                                                    If ($_.Status -like "* {*@*}") { $_.Status = "$($_.Status); will get disabled at end of cycle" }
                                                    Else { $_.Status = "Disabled (ExcludeDeviceName: '$($_.Name)')" }
                                                }
                                            }
                                            Remove-Variable DeviceName
                                            Write-Message -Level Verbose "Web GUI: Device$(If ($Values.Count -ne 1) { "s" } ) '$($Values -join ', ')' disabled. Configuration file '$($Variables.ConfigFile)' updated."
                                        }
                                        Catch { 
                                            $Data = "Error saving configuration file '$($Variables.ConfigFile)'.`n`n[ $($_) ]"
                                        }
                                    }
                                    Else { 
                                        $Data = "No configuration change"
                                    }
                                }
                                Remove-Variable Key
                                $Data = "<pre>$Data</pre>"
                                Break
                            }
                            "/functions/config/device/enable" { 
                                ForEach ($Key in $Parameters.Keys) {
                                    If ($Values = @($Parameters.$Key -split ',' | Where-Object { $_ -in $Config.ExcludeDeviceName })) { 
                                        Try { 
                                            $ExcludeDeviceName = $Config.ExcludeDeviceName
                                            $Config.ExcludeDeviceName = @($Config.ExcludeDeviceName | Where-Object { $_ -notin $Values } | Sort-Object -Unique)
                                            Write-Config -ConfigFile $Variables.ConfigFile -Config $Config
                                            $Data = "Device configuration changed`n`nOld values:"
                                            $Data += "`nExcludeDeviceName: '[$($ExcludeDeviceName -join ', ')]'"
                                            $Data += "`n`nNew values:"
                                            $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                            $Data += "`n`nConfiguration saved to '$($Variables.ConfigFile)'.`nIt will become active in next cycle."
                                            $Variables.Devices | Where-Object Name -in $Values | ForEach-Object { 
                                                $_.State = [DeviceState]::Enabled
                                                If ($_.Status -like "* {*@*}; will get disabled at end of cycle") { $_.Status = $_.Status -replace "; will get disabled at end of cycle" }
                                                Else { $_.Status = "Idle" }
                                            }
                                            Write-Message -Level Verbose "Web GUI: Device$(If ($Values.Count -ne 1) { "s" } ) '$($Values -join ', ')' enabled. Configuration file '$($Variables.ConfigFile)' updated."
                                        }
                                        Catch { 
                                            $Data = "Error saving configuration file '$($Variables.ConfigFile)'.`n`n[ $($_) ]"
                                        }
                                    }
                                    Else {
                                        $Data = "No configuration change"
                                    }
                                }
                                Remove-Variable Key
                                $Data = "<pre>$Data</pre>"
                                Break
                            }
                            "/functions/config/set" { 
                                Try { 
                                    Write-Config -ConfigFile $Variables.ConfigFile -Config ($Key | ConvertFrom-Json -AsHashtable)
                                    $TempConfig = ($Key | ConvertFrom-Json -AsHashtable)
                                    $TempConfig.Keys | ForEach-Object { $Config.$_ = $TempConfig.$_ }

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

                                    Write-Message -Level Verbose "Web GUI: Configuration saved. It will become fully active in next cycle."
                                    $Data = "Configuration saved to '$($Variables.ConfigFile)'.`nIt will become fully active in next cycle."
                                }
                                Catch { 
                                    $Data = "Error saving configuration file '$($Variables.ConfigFile)'.`n`n[ $($_) ]"
                                }
                                $Data = "<pre>$Data</pre>"
                                Break
                            }
                            "/functions/file/edit" {
                                $Data = Edit-File $Parameters.FileName
                                Break
                            }
                            "/functions/file/showcontent" {
                                $Data = (Get-Content -Path $Parameters.FileName -Raw)
                                # $Data = (Get-Content -Path $Parameters.FileName -Raw) -replace "(?<!\x0d)\x0a", "<br>"
                                $ContentType = "text/html"
                                Break
                            }
                            "/functions/log/get" { 
                                $Lines = If ([Int]$Parameters.Lines) { [Int]$Parameters.Lines } Else { 100 }
                                $Data = "$(Get-Content -Path $Variables.LogFile -Tail $Lines | ForEach-Object { "$($_)`n" } )"
                                Break
                            }
                            "/functions/mining/getstatus" { 
                                $Data = $Variables.NewMiningStatus | ConvertTo-Json
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
                                    $Data = "$($Variables.Branding.ProductLabel) is stopping...`n"
                                    $Variables.RestartCycle = $true
                                }
                                $Data = "<pre>$Data</pre>"
                                Break
                            }
                            "/functions/querypoolapi" { 
                                If (-not $Config.PoolsConfig.$($Parameters.Pool).BrainConfig.$($Parameters.Type)) { 
                                    $Data = "No pool configuration data for '/functions/querypoolapi?Pool=$($Parameters.Pool)&Type=$($Parameters.Type)'"
                                }
                                ElseIf (-not ($Data = (Invoke-RestMethod -Uri $Config.PoolsConfig.$($Parameters.Pool).BrainConfig.$($Parameters.Type) -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec 5) | ConvertTo-Json)) {
                                    $Data = "No data for '/functions/querypoolapi?Pool=$($Parameters.Pool)&Type=$($Parameters.Type)'"
                                }
                                break
                            }
                            "/functions/removeorphanedminerstats" { 
                                If ($StatNames = Remove-ObsoleteMinerStats) { 
                                    $Data = $StatNames | ConvertTo-Json
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/stat/disable" { 
                                If ($Parameters.Pools) { 
                                    $Names = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).Name
                                    $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).Algorithm
                                    $Currencies = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).Currency
                                    If ($Pools = @($Variables.Pools | Select-Object | Where-Object { $_.Name -in $Names -and $_.Algorithm -in $Algorithms -and $_.Currency -in $Currencies })) { 
                                        $Pools | ForEach-Object { 
                                            $Stat_Name = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                                            $Data += "$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })@$($_.Name)`n"
                                            Disable-Stat -Name "$($Stat_Name)_Profit"
                                            $_.Disabled = $false
                                            $_.Reasons += "Disabled by user"
                                            $_.Reasons = $_.Reasons | Sort-Object -Unique
                                            $_.Available = $false
                                        }
                                        $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" }) disabled."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data += "`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching pool stats found."
                                    }
                                    Break
                                }
                                ElseIf ($Parameters.Miners) { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithms)) { 
                                        $Miners | Sort-Object Name, Algorithms | ForEach-Object { 
                                            $Data += "$($_.Name) ($($_.Algorithms -join " & "))`n"
                                            ForEach ($Worker in $_.Workers) { 
                                                Disable-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                                $W
                                                orker.Hashrate = [Double]::NaN
                                            }
                                            Remove-Variable Worker
                                            $_.Disabled = $true
                                            $_.Reasons += "Disabled by user"
                                            $_.Reasons = $_.Reasons | Sort-Object -Unique
                                            $_.Available = $false
                                        }
                                        $Message = "$($Miners.Count) $(If ($Miners.Count -eq 1) { "Miner" } Else { "Miners" }) disbled."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data += "`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching miner stats found."
                                    }
                                    Break
                                }
                            }
                            "/functions/stat/enable" { 
                                If ($Parameters.Pools) { 
                                    $Names = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).Name
                                    $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).Algorithm
                                    $Currencies = @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue).Currency
                                    If ($Pools = @($Variables.Pools | Select-Object | Where-Object { $_.Name -in $Names -and $_.Algorithm -in $Algorithms -and $_.Currency -in $Currencies})) { 
                                        $Pools | ForEach-Object { 
                                            $Stat_Name = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                                            $Data += "$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })@$($_.Name)`n"
                                            Enable-Stat -Name "$($Stat_Name)_Profit"
                                            $_.Disabled = $false
                                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Where-Object { $_ -notlike "Disabled by user" })
                                            $_.Reasons = $_.Reasons | Sort-Object -Unique
                                            If (-not $_.Reasons) { $_.Available = $true }
                                        }
                                        $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "Pool" } Else { "pools" }) enabled."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data += "`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching pool stats found."
                                    }
                                    Break
                                }
                                ElseIf ($Parameters.Miners) { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithms)) { 
                                        $Miners | Sort-Object Name, Algorithms | ForEach-Object { 
                                            $Data += "$($_.Name) ($($_.Algorithms -join " & "))`n"
                                            ForEach ($Worker in $_.Workers) { 
                                                Enable-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                                $Worker.Hashrate = [Double]::NaN
                                            }
                                            Remove-Variable Worker
                                            $_.Disabled = $false
                                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Where-Object { $_ -ne "Disabled by user" })
                                            $_.Reasons = $_.Reasons | Sort-Object -Unique
                                            If (-not $_.Reasons) { $_.Available = $true }
                                        }
                                        $Message = "$($Miners.Count) $(If ($Miners.Count -eq 1) { "Miner" } Else { "Miners" }) enabled."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data += "`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching miner stats found."
                                    }
                                    Break
                                }
                            }
                            "/functions/stat/get" { 
                                $TempStats = @(If ($null -ne $Parameters.Value) { @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | Where-Object { $Stats.$_.Live -eq $Parameters.Value } | ForEach-Object { $Stats.$_ }) } Else { @($Stats) })

                                If ($TempStats) { 
                                    If ($null -ne $Parameters.Value) { 
                                        $TempStats | Sort-Object Name | ForEach-Object { $Data += "$($_.Name -replace "_$($Parameters.Type)")`n" }
                                        If ($Parameters.Type -eq "Hashrate") { $Data += "`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)H/s hashrate." }
                                        ElseIf ($Parameters.Type -eq "PowerUsage") { $Data += "`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)W power usage." }
                                    }
                                    Else { 
                                        $Data = $TempStats | ConvertTo-Json
                                    }
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/stat/remove" { 
                                If ($Parameters.Pools) { 
                                    If ($Pools = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Pools | Select-Object) @($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Algorithm, Currency, Name)) { 
                                        $Pools | Sort-Object Name | ForEach-Object { 
                                            $Stat_Name = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                                            $Data += "$($Stat_Name)`n"
                                            Remove-Stat -Name "$($Stat_Name)_Profit"
                                            $_.Reasons = [String[]]@()
                                            $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                                            $_.Available = $true
                                            $_.Disabled = $false
                                        }
                                        $Message = "Reset pool stats for $($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" })."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data += "`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching pool stats found."
                                    }
                                    Break
                                }
                                ElseIf ($Parameters.Miners -and $Parameters.Type -eq "Hashrate") { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithms)) { 
                                        $Miners | Sort-Object Name, Algorithms | ForEach-Object { 
                                            $_.Activated = 0 # To allow 3 attempts
                                            $_.Available = $true
                                            $_.Benchmark = $true
                                            $_.Earning_Accuracy = [Double]::NaN
                                            $_.Disabled = $false
                                            $Data += "$($_.Name) ($($_.Algorithms -join " & "))`n"
                                            ForEach ($Worker in $_.Workers) { 
                                                Remove-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                                $Worker.Hashrate = [Double]::NaN
                                            }
                                            Remove-Variable Worker
                                            # Also clear power usage
                                            Remove-Stat -Name "$($_.Name)$(If ($_.Algorithms.Count -eq 1) { "_$($_.Algorithms[1])" })_PowerUsage"
                                            $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN

                                            $_.Reasons = @($_.Reasons | Where-Object { $_ -ne "Disabled by user" })
                                            $_.Reasons = @($_.Reasons | Where-Object { $_ -ne "0 H/s Stat file" })
                                            $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Unreal profit data *" })
                                            If (-not $_.Reasons) { $_.Available = $true }
                                            If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                                        }
                                        Write-Message -Level Verbose "Web GUI: Re-benchmark triggered for $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" })."
                                        $Data += "`n$(If ($Miners.Count -eq 1) { "The miner" } Else { "$($Miners.Count) miners" }) will re-benchmark."
                                    }
                                    Else { 
                                        $Data = "No matching hashrate stats found."
                                    }
                                    Break
                                }
                                ElseIf ($Parameters.Miners -and $Parameters.Type -eq "PowerUsage") { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithms)) { 
                                        $Miners | Sort-Object Name, Algorithms | ForEach-Object { 
                                            If ($_.Earning -eq 0) { $_.Available = $true }
                                            If ($Variables.CalculatePowerCost) { 
                                                $_.MeasurePowerUsage = $true
                                                $_.Activated = 0 # To allow 3 attempts
                                            }
                                            $_.PowerUsage = [Double]::NaN
                                            $Stat_Name = "$($_.Name)$(If ($_.Algorithms.Count -eq 1) { "_$($_.Algorithms)" })"
                                            $Data += "$Stat_Name`n"
                                            Remove-Stat -Name "$($Stat_Name)_PowerUsage"
                                            $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                                            If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                                        }
                                        Write-Message -Level Verbose "Web GUI: Re-measure power usage triggered for $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" })."
                                        $Data += "`n$(If ($Miners.Count -eq 1) { "The miner" } Else { "$($Miners.Count) miners" }) will re-measure power usage."
                                    }
                                    Else { 
                                        $Data = "No matching power usage stats found."
                                    }
                                    Break
                                }
                                If ($Parameters.Value) { $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | Where-Object { $Stats.$_.Live -eq $Parameters.Value } | ForEach-Object { $Stats.$_ }) }
                                Else { $TempStats = @($Stats.Keys | Where-Object { $_ -like "*$($Parameters.Type)" } | ForEach-Object { $Stats.$_ }) } 
                                If ($TempStats) {
                                    $TempStats | Sort-Object Name | ForEach-Object { 
                                        Remove-Stat -Name $_.Name
                                        $Data += "$($_.Name -replace "_$($Parameters.Type)")`n"
                                    }
                                    Write-Message -Level Info "Web GUI: Removed $($TempStats.Count) $($Parameters.Type) stat file$(If ($TempStats.Count -ne 1) { "s" })."
                                    If ($Parameters.Type -eq "Hashrate") { $Data += "`nReset $($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)H/s $($Parameters.Type)." }
                                    ElseIf ($Parameters.Type -eq "PowerUsage") { $Data += "`nReset $($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)W $($Parameters.Type)." }
                                    ElseIf ($Parameters.Type -eq "Profit") { $Data += "`nReset $($TempStats.Count) pool stat file$(if ($TempStats.Count -ne 1) { "s" })." }
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/stat/set" { 
                                If ($Parameters.Miners -and $Parameters.Type -eq "Hashrate" -and $null -ne $Parameters.Value) { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithms)) {
                                        $Miners | Sort-Object Name, Algorithms | ForEach-Object {
                                            $_.Data = @()
                                            If ($Parameters.Value -le 0 -and $Parameters.Type -eq "Hashrate") { $_.Available = $false; $_.Disabled = $true }
                                            $Data += "$($_.Name) ($($_.Algorithms -join " & "))`n"
                                            ForEach ($Algorithm in $_.Algorithms) { 
                                                $Stat_Name = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                                                If ($Parameters.Value -eq 0) { # Miner failed
                                                    Remove-Stat -Name $Stat_Name
                                                    $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = $_.Earning_Accuracy = [Double]::NaN
                                                    $_.Available = $false
                                                    $_.Disabled = $false
                                                    $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Disabled by user" })
                                                    If ($_.Reasons -notcontains "0 H/s Stat file" ) { $_.Reasons += "0 H/s Stat file" }
                                                    $_.Status = [MinerStatus]::Failed
                                                    Set-Stat -Name $Stat_Name -Value $Parameters.Value -FaultDetection $false | Out-Null
                                                }
                                            }
                                            Remove-Variable Algorithm
                                        }
                                        Write-Message -Level Verbose "Web GUI: Marked $($Miners.Count) $(If ($Miners.Count -eq 1) { "miner" } Else { "miners" }) as failed."
                                        $Data += "`n$(If ($Miners.Count -eq 1) { "The miner is" } Else { "$($Miners.Count) miners are" }) $(If ($Parameters.Value -eq 0) { "marked as failed" } ElseIf ($Parameters.Value -eq -1) { "disabled" } Else { "set to value $($Parameters.Value)" } )." 
                                    }
                                    Else { 
                                        $Data = "No matching miners found."
                                    }
                                    Break
                                }
                            }
                            "/functions/switchinglog/clear" { 
                                Get-ChildItem -Path ".\Logs\switchinglog.csv" -File | Remove-Item -Force
                                $Data = "Switching log '.\Logs\switchinglog.csv' cleared."
                                Write-Message -Level Verbose "Web GUI: $Data"
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
                                ForEach ($Miner in ($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue)) { 
                                    If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -EQ $Miner.Name | Where-Object { $_.Algorithm -in $Miner.Algorithms })) {
                                        # Remove Watchdog timers
                                        $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })

                                        # Update miner
                                        $Variables.Miners | Where-Object Name -EQ $Miner.Name | Where-Object { [String]$_.Algorithms -eq [String]$Miner.Algorithm } | ForEach-Object { 
                                            $Data += "$($Miner.Name) {$($Miner.Algorithms -join ', ')}`n"
                                            $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Miner suspended by watchdog *" })
                                            If (-not $_.Reasons) { $_.Available = $true }
                                        }
                                    }
                                }
                                Remove-Variable Miner
                                ForEach ($Pool in ($Parameters.Pools | ConvertFrom-Json -ErrorAction SilentlyContinue)) { 
                                    If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object PoolName -EQ $Pool.Name | Where-Object Algorithm -EQ $Pool.Algorithm)) {
                                        # Remove Watchdog timers
                                        $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })

                                        # Update pool
                                        $Variables.Pools | Where-Object Name -EQ $Pool.Name | Where-Object Algorithm -EQ $Pool.Algorithm | ForEach-Object { 
                                            $Data += "$($Pool.Name) {$($Pool.Algorithm)}`n"
                                            $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Algorithm@Pool suspended by watchdog" })
                                            $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Pool suspended by watchdog*" })
                                            If (-not $_.Reasons) { $_.Available = $true }
                                        }
                                    }
                                }
                                Remove-Variable Pool
                                $Data = $Data | Sort-Object -Unique
                                If ($WatchdogTimers) { 
                                    $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "watchdog timer" } Else { "watchdog timers" }) removed."
                                    Write-Message -Level Verbose "Web GUI: $Message"
                                    $Data += "`n$Message"
                                }
                                Else { 
                                    $Data = "No matching watchdog timers found."
                                }
                                Break
                            }
                            "/functions/watchdogtimers/reset" { 
                                $Variables.WatchDogTimers = @()
                                $Variables.Miners | ForEach-Object { $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Miner suspended by watchdog *" }); $_ } | Where-Object { -not $_.Reasons } | ForEach-Object { $_.Available = $true }
                                $Variables.Pools | ForEach-Object { $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "*Pool suspended by watchdog" }); $_ } | Where-Object { -not $_.Reasons } | ForEach-Object { $_.Available = $true }
                                Write-Message -Level Verbose "Web GUI: All watchdog timers reset."
                                $Data = "Watchdog timers will be recreated in next cycle."
                                Break
                            }
                            "/algorithms" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Algorithms | Select-Object)
                                Break
                            }
                            "/algorithms/lastused" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.AlgorithmsLastUsed
                                Break
                            }
                            "/allcurrencies" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.AllCurrencies)
                                break
                            }
                            "/apiversion" { 
                                $Data = $APIVersion
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
                                $Data = $Variables.Rates.BTC.($Config.Currency)
                                Break
                            }
                            "/balancescurrencies" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.BalancesCurrencies)
                                break
                            }
                            "/braindata" { 
                                $Data = ConvertTo-Json -Depth 2 ($Variables.BrainData | Get-SortedObject)
                                Break
                            }
                            "/brainjobs" { 
                                $Data = ConvertTo-Json -Depth 2 ($Variables.BrainJobs | Select-Object)
                                Break
                            }
                            "/coinnames" { 
                                $Data = Get-Content -Path ".\Data\CoinNames.json"
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
                                $Data = $Variables.ConfigFile
                                break
                            }
                            "/configrunning" {
                                $Data = ConvertTo-Json -Depth 10 ($Config | Get-SortedObject)
                                Break
                            }
                            "/currency" { 
                                $Data = $Config.Currency
                                Break
                            }
                            "/currencyalgorithm" { 
                                $Data = Get-Content -Path ".\Data\CurrencyAlgorithm.json"
                                Break
                            }
                            "/dagdata" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.DAGdata | Select-Object)
                                Break
                            }
                            "/devices" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Sort-Object Name | Select-Object | Sort-Object Name)
                                Break
                            }
                            "/devices/enabled" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Where-Object State -EQ "Enabled" | Select-Object | Sort-Object Name)
                                Break
                            }
                            "/devices/disabled" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Where-Object State -EQ "Disabled" | Select-Object | Sort-Object Name)
                                Break
                            }
                            "/devices/unsupported" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Where-Object State -EQ "Unsupported" | Select-Object | Sort-Object Name)
                                Break
                            }
                            "/defaultalgorithm" { 
                                $Data = ConvertTo-Json -Depth 10 (Get-DefaultAlgorithm)
                                Break
                            }
                            "/donationdata" { 
                                $Data =  ConvertTo-Json $Variables.DonationData
                                Break
                            }
                            "/donationlog" { 
                                $Data =  ConvertTo-Json $Variables.DonationLog
                                Break
                            }
                            "/driverversion" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.DriverVersion | Select-Object)
                                Break
                            }
                            "/earningschartdata" { 
                                $Data =  ConvertTo-Json $Variables.EarningsChartData
                                Break
                            }
                            "/equihashcoinpers" { 
                                $Data = Get-Content -Path ".\Data\EquihashCoinPers.json"
                                Break
                            }
                            "/extracurrencies" { 
                                $Data = ConvertTo-Json -Depth 10 $Config.ExtraCurrencies
                                break
                            }
                            "/fiatcurrencies" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.FIATcurrencies | Select-Object)
                                Break
                            }
                            "/miners" { 
                                $Data = ConvertTo-Json -Depth 4 -Compress @($Variables.Miners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator | ConvertTo-Json -Depth 4 | ConvertFrom-Json | ForEach-Object { If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ } | Select-Object -Property * -ExcludeProperty WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, DeviceNames, Name)
                                Break
                            }
                            "/miners/available" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object Available | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator | Sort-Object Name)
                                Break
                            }
                            "/miners/best" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersBest | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator | ConvertTo-Json -Depth 4 | ConvertFrom-Json | ForEach-Object { If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ } | Select-Object -Property * -ExcludeProperty WorkersRunning | Sort-Object DeviceName)
                                Break
                            }
                            "/miners/best_combo" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersBest_Combo | Sort-Object DeviceNames | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator)
                                Break
                            }
                            "/miners/best_combos" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersBest_Combos | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator)
                                Break
                            }
                            "/miners/disabled" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object { $_.Status -EQ [MinerStatus]::Disabled } | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator | Sort-Object DeviceNames, EndTime)
                                Break
                            }
                            "/miners/failed" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object { $_.Status -EQ [MinerStatus]::Failed } | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator | Sort-Object DeviceNames, EndTime)
                                Break
                            }
                            "/miners/launched" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersBest_Combo | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator | ConvertTo-Json -Depth 4 | ConvertFrom-Json | ForEach-Object { $_.Workers = $_.WorkersRunning; $_ } | Select-Object -Property * -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/mostprofitable" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersMostProfitable | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, DeviceNames, @{Expression = "Earning_Bias"; Descending = $True })
                                Break
                            }
                            "/miners/running" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object { $_.Status -EQ [MinerStatus]::Running } | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator | ConvertTo-Json -Depth 4 | ConvertFrom-Json | ForEach-Object { $_.Workers = $_.WorkersRunning; $_ } | Select-Object -Property * -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/unavailable" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners | Where-Object Available -NE $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator | Sort-Object DeviceNames, Name, Algorithm)
                                Break
                            }
                            "/miners/device_combos" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners_Device_Combos | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, Devices, Process, SideIndicator)
                                Break
                            }
                            "/miningpowercost" { 
                                $Data = $Variables.MiningPowerCost
                                Break
                            }
                            "/miningearning" { 
                                $Data = $Variables.MiningEarning
                                Break
                            }
                            "/miningprofit" { 
                                $Data = $Variables.MiningProfit
                                Break
                            }
                            "/poolname" { 
                                $Data = ConvertTo-Json -Depth 10 $Config.PoolName
                                break
                            }
                            "/pooldata" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.PoolData
                                break
                            }
                            "/poolsconfig" { 
                                $Data = ConvertTo-Json -Depth 10 ($Config.PoolsConfig | Select-Object)
                                Break
                            }
                            "/poolsconfigfile" { 
                                $Data = $Config.PoolsConfigFile
                                Break
                            }
                            "/pools" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Select-Object | Sort-Object Algorithm, Name, Region)
                                Break
                            }
                            "/pools/added" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsAdded | Select-Object | Sort-Object Algorithm, Name, Region)
                                Break
                            }
                            "/pools/available" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Where-Object Available | Select-Object | Sort-Object Algorithm, Name, Region)
                                Break
                            }
                            "/pools/best" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsBest | Select-Object | Sort-Object Algorithm, Name, Region)
                                Break
                            }
                            "/pools/new" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsNew | Select-Object | Sort-Object Algorithm, Name, Region)
                                Break
                            }
                            "/pools/minersprimaryalgorithm" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.MinerPools[0] | Select-Object)
                                Break
                            }
                            "/pools/minerssecondaryalgorithm" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.MinerPools[1] | Select-Object)
                                Break
                            }
                            "/pools/lastearnings" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.PoolsLastEarnings
                                Break
                            }
                            "/pools/lastused" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.PoolsLastUsed
                                Break
                            }
                            "/pools/unavailable" { 
                                $Data = ConvertTo-Json -Depth 10  @($Variables.Pools | Where-Object Available -NE $true | Select-Object | Sort-Object Algorithm, Name, Region)
                                Break
                            }
                            "/pools/updated" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsUpdated | Select-Object | Sort-Object Algorithm, Name, Region)
                                Break
                            }
                            "/poolreasons" { 
                                $Data = ConvertTo-Json -Depth 10 (($Variables.Pools | Where-Object Available -NE $true).Reasons | Sort-Object -Unique)
                                Break
                            }
                            "/poolvariants" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.PoolVariants
                                break
                            }
                            "/rates" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.Rates | Select-Object)
                                Break
                            }
                            "/refreshtimestamp" { 
                                $Data = $Variables.RefreshTimestamp | ConvertTo-Json
                                break
                            }
                            "/regions" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Regions.PSObject.Properties.Value | Sort-Object -Unique)
                                Break
                            }
                            "/regionsdata" { 
                                $Data = ConvertTo-Json -Depth 10 $Variables.Regions
                                Break
                            }
                            "/stats" { 
                                $Data = ConvertTo-Json -Depth 10 ($Stats | Select-Object)
                                Break
                            }
                            "/summary" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Summary | Select-Object)
                                Break
                            }
                            "/switchinglog" { 
                                $Data = ConvertTo-Json -Depth 10 @(Get-Content ".\Logs\switchinglog.csv" | ConvertFrom-Csv | Select-Object -Last 1000 | Sort-Object DateTime -Descending)
                                Break
                            }
                            "/unprofitablealgorithms" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.UnprofitableAlgorithms | Select-Object)
                                Break
                            }
                            "/version" { 
                                $Data = ConvertTo-Json @("$($Variables.Branding.ProductLabel) Version: $($Variables.Branding.Version)", "API Version: $($Variables.APIVersion)", "PWSH Version: $($PSVersionTable.PSVersion.ToString())")
                                Break
                            }
                            "/watchdogtimers" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.WatchdogTimers | Select-Object)
                                Break
                            }
                            "/wallets" { 
                                $Data = ConvertTo-Json -Depth 10 ($Config.Wallets | Select-Object)
                                Break
                            }
                            "/watchdogexpiration" { 
                                $Data = $Variables.WatchdogReset
                                Break
                            }
                            "/workers" { 
                                If ($Config.ShowWorkerStatus -and $Config.MonitoringUser -and $Config.MonitoringServer -and $Variables.WorkersLastUpdated -lt (Get-Date).AddSeconds(-30)) { 
                                    Read-MonitoringData
                                }
                                $Workers = [System.Collections.ArrayList]@(
                                    $Variables.Workers | Select-Object @(
                                        @{ Name = "Algorithm"; Expression = { ($_.data | ForEach-Object { $_.Algorithm -split "," -join " & " }) -join "<br/>" } }, 
                                        @{ Name = "Benchmark Hashrate"; Expression = { ($_.data | ForEach-Object { ($_.EstimatedSpeed | ForEach-Object { If ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } Else { "-" } }) -join " & " }) -join "<br>" } }, 
                                        @{ Name = "Currency"; Expression = { $_.Data.Currency | Select-Object -Unique } }, 
                                        @{ Name = "EstimatedEarning"; Expression = { [Decimal](($_.Data.Earning | Measure-Object -Sum).Sum * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } }, 
                                        @{ Name = "EstimatedProfit"; Expression = { [Decimal]($_.Profit * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } }, 
                                        @{ Name = "LastSeen"; Expression = { "$($_.date)" } }, 
                                        @{ Name = "Live Hashrate"; Expression = { ($_.data | ForEach-Object { ($_.CurrentSpeed | ForEach-Object { If ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } Else { "-" } }) -join " & " }) -join "<br>" } }, 
                                        @{ Name = "Miner"; Expression = { $_.data.name -join '<br/>'} }, 
                                        @{ Name = "Pool"; Expression = { ($_.data | ForEach-Object { ($_.Pool -split "," | ForEach-Object { $_ -replace "Internal$", " (Internal)" -replace "External", " (External)" }) -join " & "}) -join "<br/>" } }, 
                                        @{ Name = "Status"; Expression = { $_.status } }, 
                                        @{ Name = "Version"; Expression = { $_.version } }, 
                                        @{ Name = "Worker"; Expression = { $_.worker } }
                                    ) | Sort-Object "Worker Name"
                                )
                                $Data = ConvertTo-Json @($Workers | Select-Object)
                                Break
                            }
                            Default { 
                                # Set index page
                                If ($Path -eq "/") { $Path = "/index.html" }

                                # Check if there is a file with the requested path
                                $Filename = "$BasePath$Path"
                                If (Test-Path -Path $Filename -PathType Leaf) { 
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
                                                If (Test-Path -Path $IncludeFile -PathType Leaf) { 
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
                    }
                    # Only gets here if something is wrong and the server couldn't start or stops listening
                    $Server.Stop()
                    $Server.Close()
                }
            ) | Out-Null # End of $APIServer

            $Variables.APIRunspace | Add-Member -Force @{ Name = ""; PowerShell = $PowerShell; Handle = $PowerShell.BeginInvoke(); StartTime = $((Get-Date).ToUniversalTime()) }

            # Wait for API to get ready
            $RetryCount = 3
            While (-not ($Variables.APIVersion) -and $RetryCount -gt 0) { 
                Try {
                    If ($Variables.APIVersion = (Invoke-RestMethod "http://localhost:$($Variables.APIRunspace.APIPort)/apiversion" -TimeoutSec 1 -ErrorAction Stop)) { 
                        Write-Message -Level Info "Web GUI and API (version $($Variables.APIVersion)) running on http://localhost:$($Variables.APIRunspace.APIPort)."
                        # Start Web GUI (show configuration edit if no existing config)
                        If ($Config.WebGUI) { Start-Process "http://localhost:$($Variables.APIRunspace.APIPort)/$(If ($Variables.FreshConfig) { "configedit.html" })" }
                        Break
                    }
                }
                Catch { }
                $RetryCount--
                Start-Sleep -Seconds 1
            }
            If (-not $Variables.APIVersion) { Write-Message -Level Error "Error initializing API & Web GUI on port $($Config.APIPort)." }
        }
        $TCPClient.Close()
    }
}

Function Stop-APIServer {
    If ($Variables.APIRunspace) { 
        If ($Variables.APIRunspace.APIServer) { 
            If ($Variables.APIRunspace.APIServer.IsListening) { $Variables.APIRunspace.APIServer.Stop() }
            $Variables.APIRunspace.APIServer.Close()
        }
        If ($Variables.APIRunspace.APIPort) { $Variables.APIRunspace.APIPort = $null }
        If ($Variables.APIRunspace.PowerShell) { $Variables.APIRunspace.PowerShell.Dispose() }
        $Variables.APIRunspace.Close()
        $Variables.Remove("APIRunspace")
    }
    [System.GC]::GetTotalMemory("forcefullcollection") | Out-Null
}
