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
File:           \Includes\APIServer.psm1
Version:        5.0.2.6
Version date:   2023/12/28
#>

Function Start-APIServer { 

    $APIVersion = "0.5.3.12"

    If ($Variables.APIRunspace.AsyncObject.IsCompleted -or $Config.APIPort -ne $Variables.APIRunspace.APIPort) { 
        Stop-APIServer
        $Variables.Remove("APIVersion")
    }

    # Initialize API & Web GUI
    If ($Config.APIPort -and -not $Variables.APIRunspace.APIPort) { 

        Write-Message -Level Verbose "Initializing API & Web GUI on 'http://localhost:$($Config.APIPort)'..."

        $TCPclient = New-Object -TypeName System.Net.Sockets.TCPClient
        $AsyncResult = $TCPclient.BeginConnect("127.0.0.1", $Config.APIPort, $null, $null)
        If ($AsyncResult.AsyncWaitHandle.WaitOne(100)) { 
            Write-Message -Level Error "Error initializing API & Web GUI on port $($Config.APIPort). Port is in use."
            [Void]$TCPclient.EndConnect($AsyncResult)
            [Void]$TCPclient.Dispose()
        }
        Else { 
            [Void]$TCPclient.Dispose()

            # Start API server
            If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): API ($APIVersion) started." | Out-File $Config.APILogFile -Force -ErrorAction Ignore}

            # Setup runspace to launch the API server in a separate thread
            $Variables.APIRunspace = [RunspaceFactory]::CreateRunspace()
            $Variables.APIRunspace.ApartmentState = "STA"
            $Variables.APIRunspace.Name = "APIServer"
            $Variables.APIRunspace.ThreadOptions = "ReuseThread"
            $Variables.APIRunspace.Open()
            (Get-Variable -Scope Global).Where({ $_.Name -in @("Config", "Stats", "Variables") }).ForEach(
                { 
                    $Variables.APIRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
                }
            )
            $Variables.APIRunspace.SessionStateProxy.SetVariable("APIVersion", $APIVersion)
            $Variables.APIRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
            $Variables.APIRunspace | Add-Member -Force @{ APIPort = $Config.APIPort }

            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $Variables.APIRunspace
            $Powershell.AddScript(
                { 
                    $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script
                    
                    (Get-Process -Id $PID).PriorityClass = "Normal"

                    # Set the starting directory
                    $BasePath = "$PWD\web"

                    If ($Config.Transcript) { Start-Transcript -Path ".\Debug\APIServer-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

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

                        If ($Request.HttpMethod -eq "GET") { 
                            # Parse any parameters in the URL - $Request.Url.Query looks like "+ ?a=b&c=d&message=Hello%20world"
                            # Decode any url escaped characters in the key and value
                            $Parameters = @{ }
                            $Request.Url.Query -replace '\?' -split "&" | Foreach-Object { 
                                $Key, $Value = $_ -split "="
                                # Decode any url escaped characters in the key and value
                                $Key = [URI]::UnescapeDataString($Key)
                                $Value = [URI]::UnescapeDataString($Value)
                                If ($Key -and $Value) { 
                                    $Parameters.$Key = $Value
                                }
                            }
                            If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url)" | Out-File $Config.APILogFile -Append -ErrorAction Ignore }

                        }
                        ElseIf ($Request.HttpMethod -eq "POST") { 
                            $Length = $Request.contentlength64
                            $Buffer = New-object "byte[]" $Length

                            [Void]$Request.inputstream.read($Buffer, 0, $Length)
                            $Body = [System.Text.Encoding]::ascii.getstring($Buffer)

                            If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss"): $($Request.Url) POST:$Body" | Out-File $Config.APILogFile -Append -ErrorAction Ignore }

                            $Parameters = @{ }
                            $Body -split "&" | ForEach-Object { 
                                $Key, $Value = $_ -split "="
                                # Decode any url escaped characters in the key and value
                                $Key = [System.Web.HttpUtility]::UrDecode($Key)
                                $Value = [System.Web.HttpUtility]::UrlDecode($Value)
                                If ($Key -and $Value) { 
                                    $Parameters.$Key = $Value
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
                                $PoolNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Name
                                $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Algorithm
                                If ($Pools = @($Variables.Pools.Where({ $_.Name -in $PoolNames -and $_.Algorithm -in $Algorithms }))) { 
                                    $PoolsConfig = Get-Content -Path $Config.PoolsConfigFile | ConvertFrom-Json
                                    ForEach ($Pool in $Pools) { 
                                        If ($PoolsConfig.($Pool.Name).Algorithm -like "-*") { 
                                            $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm += "-$($Pool.Algorithm)" | Sort-Object -Unique)
                                            $Pool.Reasons = [System.Collections.Generic.List[String]]@($Pool.Reasons.Add("Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.Name) pool config)") | Sort-Object -Unique)
                                        }
                                        Else { 
                                            $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm.Where({ $_ -ne "+$($Pool.Algorithm)" }) | Sort-Object -Unique)
                                            $Pool.Reasons = [System.Collections.Generic.List[String]]@($Pool.Reasons.Add("Algorithm not enabled in $($Pool.Name) pool config") | Sort-Object -Unique)
                                        }
                                        $Pool.Available = $false
                                        $Data += "$($Pool.Algorithm)@$($Pool.Name)`n"
                                    }
                                    Remove-Variable Pool
                                    $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" }) disabled."
                                    Write-Message -Level Verbose "Web GUI: $Message"
                                    $Data += "`n$Message"
                                    $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $Variables.PoolsConfigFile -Force
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/algorithm/enable" { 
                                # Enable algorithm@pool in poolsconfig.json
                                $PoolNames = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Name
                                $Algorithms = @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore).Algorithm
                                If ($Pools = @($Variables.Pools.Where({ $_.Name -in $PoolNames -and $_.Algorithm -in $Algorithms }))) { 
                                    $PoolsConfig = Get-Content -Path $Config.PoolsConfigFile | ConvertFrom-Json
                                    ForEach ($Pool in $Pools) { 
                                        If ($PoolsConfig.($Pool.Name).Algorithm -like "+*") { 
                                            $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm += "+$($Pool.Algorithm)" | Sort-Object -Unique)
                                            $Pool.Reasons = [System.Collections.Generic.List[String]]@($Pool.Reasons.Where({ $_ -ne "Algorithm not enabled in $($Pool.Name) pool config" }) | Sort-Object -Unique)
                                        }
                                        Else { 
                                            $PoolsConfig.($Pool.Name).Algorithm = @($PoolsConfig.($Pool.Name).Algorithm.Where({ $_ -ne "-$($Pool.Algorithm)" }) | Sort-Object -Unique)
                                            $Pool.Reasons = [System.Collections.Generic.List[String]]@($Pool.Reasons.Where({ $_ -ne "Algorithm disabled (`-$($Pool.Algorithm)` in $($Pool.Name) pool config)" }) | Sort-Object -Unique)
                                        }
                                        If (-not $Pool.Reasons) { $Pool.Available = $true }
                                        $Data += "$($Pool.Algorithm)@$($Pool.Name)`n"
                                    }
                                    Remove-Variable Pool
                                    $Message = "$($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" }) enabled."
                                    Write-Message -Level Verbose "Web GUI: $Message"
                                    $Data += "`n$Message"
                                    $PoolsConfig | Get-SortedObject | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $Variables.PoolsConfigFile -Force
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
                                    $BalanceDataEntries = $Variables.BalancesData
                                    $Variables.BalancesData = @((Compare-Object $Variables.BalancesData @($Parameters.Data | ConvertFrom-Json -ErrorAction Ignore) -PassThru -Property DateTime, Pool, Currency, Wallet).Where({ $_.SideIndicator -eq "<=" }) | Select-Object -ExcludeProperty SideIndicator)
                                    $Variables.BalancesData | ConvertTo-Json | Out-File ".\Data\BalancesTrackerData.json"
                                    $RemovedEntriesCount = $BalanceDataEntries.Count - $Variables.BalancesData.Count
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
                                    If ($Values = @(($Parameters.$Key -split ',').Where({ $_ -notin $Config.ExcludeDeviceName }))) { 
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
                                                $Variables.Devices.Where({ $_.Name -eq $DeviceName }) | ForEach-Object { 
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
                                    If ($Values = @(($Parameters.$Key -split ',').Where({ $_ -in $Config.ExcludeDeviceName }))) { 
                                        Try { 
                                            $ExcludeDeviceName = $Config.ExcludeDeviceName
                                            $Config.ExcludeDeviceName = @($Config.ExcludeDeviceName.Where({ $_ -notin $Values }) | Sort-Object -Unique)
                                            Write-Config -ConfigFile $Variables.ConfigFile -Config $Config
                                            $Data = "Device configuration changed`n`nOld values:"
                                            $Data += "`nExcludeDeviceName: '[$($ExcludeDeviceName -join ', ')]'"
                                            $Data += "`n`nNew values:"
                                            $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                            $Data += "`n`nConfiguration saved to '$($Variables.ConfigFile)'.`nIt will become active in next cycle."
                                            $Variables.Devices.Where({ $_.Name -in $Values }).ForEach(
                                                { 
                                                    $_.State = [DeviceState]::Enabled
                                                    If ($_.Status -like "* {*@*}; will get disabled at end of cycle") { $_.Status = $_.Status -replace '; will get disabled at end of cycle' }
                                                    Else { $_.Status = "Idle" }
                                                }
                                            )
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

                                    $Variables.Devices.Where({ $_.State -ne [DeviceState]::Unsupported }) | ForEach-Object { 
                                        If ($_.Name -in @($Config.ExcludeDeviceName)) { 
                                            $_.State = [DeviceState]::Disabled
                                            If ($_.Status -like "Mining *}") { $_.Status = "$($_.Status); will get disabled at end of cycle" }
                                        }
                                        Else { 
                                            $_.State = [DeviceState]::Enabled
                                            If ($_.Status -like "*; will get disabled at end of cycle") { $_.Status = $_.Status -replace '; will get disabled at end of cycle' } 
                                            If ($_.Status -like "Disabled *") { $_.Status = "Idle" }
                                        }
                                    }
                                    $Variables.RestartCycle = $true
                                    Write-Message -Level Verbose "Web GUI: Configuration saved. It will become fully active in the next cycle."
                                    $Data = "Configuration saved to '$($Variables.ConfigFile)'.`nIt will become fully active in the next cycle."
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
                                    $Data = "Mining is being paused...`n$(If ($Variables.BalancesTrackerPollInterval -gt 0) { If ($Variables.BalancesTrackerRunning) { "Balances Tracker running." } Else { "Balances Tracker starting..." } })"
                                    $Variables.RestartCycle = $true
                                }
                                $Data = "<pre>$Data</pre>"
                                Break
                            }
                            "/functions/mining/start" { 
                                If ($Variables.MiningStatus -ne "Running") { 
                                    $Variables.NewMiningStatus = "Running"
                                    $Data = "Mining processes starting...`n$(If ($Variables.BalancesTrackerPollInterval -gt 0) { If ($Variables.BalancesTrackerRunning) { "Balances Tracker running." } Else { "Balances Tracker starting..." } })"
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
                            "/functions/getminerdetail" { 
                                $Miner = $Variables.Miners.Where({ $_.Info -eq $Key})
                                If ($Miner) { 
                                    $Data = $Miner | ConvertTo-Json -Depth 10
                                }
                                Else { 
                                    $Data = "Miner with key '$Key' not found."
                                }
                                Break
                            }
                            "/functions/stat/disable" { 
                                If ($Parameters.Miners) { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) { 
                                        $Data = @()
                                        $Miners | ForEach-Object { 
                                            $Data += "$($_.Name) ($($_.Algorithms -join ' & '))"
                                            ForEach ($Worker in $_.Workers) { 
                                                Remove-Stat -Name "$($_.Name)_$($Worker.Pool.AlgorithmVariant)_Hashrate"
                                                $Worker.Hashrate = [Double]::NaN
                                            }
                                            Remove-Variable Worker
                                            $_.Disabled = $true
                                            $_.Reasons = [System.Collections.Generic.List[String]]@("Disabled by user")
                                            $_.Available = $false
                                        }
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "Miner" } Else { "Miners" }) disbled."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching miner stats found."
                                    }
                                    Break
                                }
                            }
                            "/functions/stat/enable" { 
                                If ($Parameters.Miners) { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) { 
                                        $Data = @()
                                        $Miners | ForEach-Object { 
                                            $Data += "$($_.Name) ($($_.Algorithms -join ' & '))"
                                            ForEach ($Worker in $_.Workers) { 
                                                Remove-Stat -Name "$($_.Name)_$($Worker.Pool.AlgorithmVariant)_Hashrate"
                                                $Worker.Hashrate = [Double]::NaN
                                            }
                                            Remove-Variable Worker
                                            $_.Disabled = $false
                                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Where-Object { $_ -ne "Disabled by user" } | Sort-Object -Unique)
                                            If (-not $_.Reasons) { $_.Available = $true }
                                        }
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "Miner" } Else { "Miners" }) enabled."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching miner stats found."
                                    }
                                    Break
                                }
                            }
                            "/functions/stat/get" { 
                                $TempStats = @(If ($null -ne $Parameters.Value) { @($Stats.psBase.Keys.Where({ $_ -like "*$($Parameters.Type)" -and $Stats[$_].Live -eq $Parameters.Value }).ForEach({ $Stats[$_] })) } Else { @($Stats) })
                                If ($TempStats) { 
                                    If ($null -ne $Parameters.Value) { 
                                        ($TempStats | Sort-Object -Property Name).ForEach({ $Data += "$($_.Name -replace "_$($Parameters.Type)")`n" })
                                        If ($Parameters.Type -eq "Hashrate") { $Data += "`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)H/s hashrate." }
                                        ElseIf ($Parameters.Type -eq "PowerConsumption") { $Data += "`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)W power consumption." }
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
                                    If ($Pools = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Pools | Select-Object) @($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Algorithm, Currency, Name)) { 
                                        $Data = @()
                                        $Pools | Sort-Object -Property Name, Algorithm, Currency | ForEach-Object { 
                                            $Stat_Name = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                                            $Data += $Stat_Name
                                            Remove-Stat -Name "$($Stat_Name)_Profit"
                                            $_.Reasons = [System.Collections.Generic.List[String]]@()
                                            $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                                            $_.Available = $true
                                            $_.Disabled = $false
                                        }
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "Reset pool stats for $($Pools.Count) $(If ($Pools.Count -eq 1) { "pool" } Else { "pools" })."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching pool stats found."
                                    }
                                    Break
                                }
                                ElseIf ($Parameters.Miners -and $Parameters.Type -eq "Hashrate") { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) { 
                                        $Data = @()
                                        $Miners | ForEach-Object { 
                                            $_.Activated = 0 # To allow 3 attempts
                                            $_.Available = $true
                                            $_.Benchmark = $true
                                            $_.Earning_Accuracy = [Double]::NaN
                                            $_.Disabled = $false
                                            $Data += "$($_.Name) ($($_.Algorithms -join ' & '))"
                                            ForEach ($Worker in $_.Workers) { 
                                                Remove-Stat -Name "$($_.Name)_$($Worker.Pool.AlgorithmVariant)_Hashrate"
                                                $Worker.Hashrate = [Double]::NaN
                                            }
                                            Remove-Variable Worker
                                            # Also clear power consumption
                                            Remove-Stat -Name "$($_.Name)$(If ($_.Algorithms.Count -eq 1) { "_$($_.Algorithms[0])" })_PowerConsumption"
                                            $_.PowerConsumption = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN

                                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Where-Object { $_ -ne "Disabled by user" })
                                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Where-Object { $_ -ne "0 H/s Stat file" })
                                            $_.Reasons = [System.Collections.Generic.List[String]] @($_.Reasons | Where-Object { $_ -notlike "Unreal profit data *" } | Sort-Object -Unique)
                                            If (-not $_.Reasons) { $_.Available = $true }
                                            If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                                        }
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "Re-benchmark triggered for $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching hashrate stats found."
                                    }
                                    Break
                                }
                                ElseIf ($Parameters.Miners -and $Parameters.Type -eq "PowerConsumption") { 
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) { 
                                        $Data = @()
                                        $Miners | ForEach-Object { 
                                            If ($_.Earning -eq 0) { $_.Available = $true }
                                            If ($Variables.CalculatePowerCost) { 
                                                $_.MeasurePowerConsumption = $true
                                                $_.Activated = 0 # To allow 3 attempts
                                            }
                                            $_.PowerConsumption = [Double]::NaN
                                            $Stat_Name = "$($_.Name)$(If ($_.Workers.Count -eq 1) { "_$($_.Workers[0].Pool.Algorithm)" })"
                                            $Data += $Stat_Name
                                            Remove-Stat -Name "$($Stat_Name)_PowerConsumption"
                                            $_.PowerConsumption = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                                            If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                                        }
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "Re-measure power consumption triggered for $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message"
                                    }
                                    Else { 
                                        $Data = "No matching power consumption stats found."
                                    }
                                    Break
                                }
                                If ($Parameters.Value) { $TempStats = @($Stats.psBase.Keys.Where({ $_ -like "*_$($Parameters.Type)" -and  $Stats[$_].Live -eq $Parameters.Value }).ForEach({ $Stats[$_] })) }
                                Else { $TempStats = @( (Get-ChildItem -Path ".\Stats\*_$($Parameters.Type).txt").BaseName | ForEach-Object { $Stats[$_] }) }
                                If ($TempStats) { 
                                    $Data = @()
                                    $TempStats | Sort-Object -Property Name | ForEach-Object { 
                                        Remove-Stat -Name $_.Name
                                        $Data += "$($_.Name -replace "_$($Parameters.Type)")"
                                    }
                                    $Data = $Data | Sort-Object -Unique
                                    If ($Parameters.Type -eq "Hashrate") { $Message = "Reset $($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value) H/s hashrate." }
                                    ElseIf ($Parameters.Type -eq "PowerConsumption") { $Message = "Reset $($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value) W power consumption." }
                                    ElseIf ($Parameters.Type -eq "Profit") { $Message = "Reset $($TempStats.Count) pool stat file$(if ($TempStats.Count -ne 1) { "s" })." }
                                    Write-Message -Level Info "Web GUI: $Message"
                                    $Data = "$($Data -join "`n")`n`n$Message"
                                }
                                Else { 
                                    $Data = "No matching stats found."
                                }
                                Break
                            }
                            "/functions/stat/set" { 
                                If ($Parameters.Miners -and $Parameters.Type -eq "Hashrate" -and $null -ne $Parameters.Value) { 
                                    $Data = @()
                                    If ($Miners = @(Compare-Object -PassThru -IncludeEqual -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore | Select-Object) -Property Info)) {
                                        $Miners | ForEach-Object { 
                                            If ($Parameters.Value -le 0 -and $Parameters.Type -eq "Hashrate") { $_.Available = $false; $_.Disabled = $true }
                                            $Data += "$($_.Name) ($($_.Algorithms -join ' & '))"
                                            ForEach ($Algorithm in $_.Algorithms) { 
                                                $Stat_Name = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                                                If ($Parameters.Value -eq 0) { # Miner failed
                                                    Remove-Stat -Name $Stat_Name
                                                    $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = $_.Earning_Accuracy = [Double]::NaN
                                                    $_.Available = $false
                                                    $_.Disabled = $false
                                                    If ($_.Reasons -notcontains "0 H/s Stat file" ) { $_.Reasons.Add("0 H/s Stat file") }
                                                    $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons | Where-Object { $_ -notlike "Disabled by user" } | Sort-Object -Unique)
                                                    $_.Status = [MinerStatus]::Failed
                                                    Set-Stat -Name $Stat_Name -Value $Parameters.Value -FaultDetection $false | Out-Null
                                                }
                                            }
                                            Remove-Variable Algorithm
                                        }
                                        $Data = $Data | Sort-Object -Unique
                                        $Message = "$(If ($Data.Count -eq 1) { "The miner is" } Else { "$($Data.Count) miners are" }) $(If ($Parameters.Value -eq 0) { "marked as failed" } ElseIf ($Parameters.Value -eq -1) { "disabled" } Else { "set to value $($Parameters.Value)" } )." 
                                        Write-Message -Level Verbose "Web GUI: $Message"
                                        $Data = "$($Data -join "`n")`n`n$Message" 
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
                                    $Data = $Variables.($Key -replace '\\|/', '.' -split '\.' | Select-Object -Last 1) | Get-SortedObject | ConvertTo-Json -Depth 10
                                }
                                Else { 
                                    $Data = $Variables.psBase.Keys | Sort-Object | ConvertTo-Json -Depth 1
                                }
                                Break
                            }
                            "/functions/watchdogtimers/remove" { 
                                ForEach ($Miner in ($Parameters.Miners | ConvertFrom-Json -ErrorAction Ignore)) { 
                                    If ($WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_.MinerName -eq $Miner.Name -and $_.Algorithm -in $Miner.Workers.Pool.Algorithm }))) {
                                        # Remove Watchdog timers
                                        $Variables.WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_ -notin $WatchdogTimers }))

                                        # Update miner
                                        $Variables.Miners.Where({ $_.Name -eq $Miner.Name -and [String]$_.Algorithms -eq [String]$Miner.Algorithms }) | ForEach-Object { 
                                            $Data += "`n$($_.Info)"
                                            $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Miner suspended by watchdog *" }) | Sort-Object -Unique)
                                            If (-not $_.Reasons) { $_.Available = $true }
                                        }
                                    }
                                }
                                Remove-Variable Miner
                                ForEach ($Pool in ($Parameters.Pools | ConvertFrom-Json -ErrorAction Ignore)) { 
                                    If ($WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_.PoolName -eq $Pool.Name -and $_.Algorithm -EQ $Pool.Algorithm}))) {
                                        # Remove Watchdog timers
                                        $Variables.WatchdogTimers = @($Variables.WatchdogTimers.Where({ $_ -notin $WatchdogTimers }))

                                        # Update pool
                                        $Variables.Pools.Where({ $_.PoolName -eq $Pool.Name -and $_.Algorithm -eq $Pool.Algorithm }).ForEach(
                                            { 
                                                $Data += "`n$($_.Key) ($($_.Region))"
                                                $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Algorithm@Pool suspended by watchdog" }))
                                                $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Pool suspended by watchdog*" }) | Sort-Object -Unique)
                                                If (-not $_.Reasons) { $_.Available = $true }
                                            }
                                        )
                                    }
                                }
                                Remove-Variable Pool
                                $Data = $Data | Sort-Object -Unique
                                If ($WatchdogTimers) { 
                                    $Message = "$($Data.Count) watchdog $(If ($Data.Count -eq 1) { "timer" } Else { "timers" }) removed."
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
                                $Variables.Miners.ForEach(
                                    { 
                                        $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "Miner suspended by watchdog *" }) | Sort-Object -Unique)
                                        $_.Where({ -not $_.Reasons }).ForEach({ $_.Available = $true })
                                    }
                                )
                                $Variables.Pools.ForEach(
                                    { 
                                        $_.Reasons = [System.Collections.Generic.List[String]]@($_.Reasons.Where({ $_ -notlike "*Pool suspended by watchdog" }) | Sort-Object -Unique)
                                        $_.Where({ -not $_.Reasons }).ForEach({ $_.Available = $true })
                                    }
                                )
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
                                $Data = ConvertTo-Json -Depth 10 ($Variables.Balances | Sort-Object -Property DateTime -Bottom 10000 | Select-Object)
                                Break
                            }
                            "/balancedata" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.BalancesData | Sort-Object -Property DateTime -Descending)
                                Break
                            }
                            "/btc" { 
                                $Data = $Variables.Rates.BTC.($Config.MainCurrency)
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
                                    $Data = ConvertTo-Json -Depth 10 ($Config | Select-Object -ExcludeProperty PoolsConfig)
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
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices | Select-Object | Sort-Object -Property Name)
                                Break
                            }
                            "/devices/enabled" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices.Where({ $_.State -eq "Enabled" }) | Sort-Object -Property Name)
                                Break
                            }
                            "/devices/disabled" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices.Where({ $_.State -eq "Disabled" }) | Sort-Object -Property Name)
                                Break
                            }
                            "/devices/unsupported" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Devices.Where({ $_.State -eq "Unsupported" }) | Sort-Object -Property Name)
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
                                $Data = ConvertTo-Json -Depth 4 -Compress @($Variables.Miners | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | ForEach-Object { If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ } | Select-Object -ExcludeProperty WorkersRunning | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, DeviceNames, Name)
                                Break
                            }
                            "/miners/available" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners.Where({ $_.Available }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | Sort-Object -Property Name)
                                Break
                            }
                            "/miners/bestperdevice" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersBestPerDevice | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | ForEach-Object { If ($_.WorkersRunning) { $_.Workers = $_.WorkersRunning }; $_ } | Select-Object -ExcludeProperty WorkersRunning | Sort-Object -Property DeviceName)
                                Break
                            }
                            "/miners/best_combo" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersBestPerDevice_Combo | Sort-Object DeviceNames | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, StatEnd, StatStart, SideIndicator, ValidDataSampleTimestamp)
                                Break
                            }
                            "/miners/best_combos" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersBestPerDevice_Combos | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, SideIndicator, ValidDataSampleTimestamp)
                                Break
                            }
                            "/miners/disabled" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners.Where({ $_.Status -EQ [MinerStatus]::Disabled }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | Sort-Object -Property DeviceNames, EndTime)
                                Break
                            }
                            "/miners/failed" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners.Where({ $_.Status -EQ [MinerStatus]::Failed }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | Sort-Object -Property DeviceNames, EndTime)
                                Break
                            }
                            "/miners/launched" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersBestPerDevice_Combo | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | ForEach-Object { $_.Workers = $_.WorkersRunning; $_ } | Select-Object -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/mostprofitable" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.MinersMostProfitable | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, DeviceNames, @{Expression = "Earning_Bias"; Descending = $true })
                                Break
                            }
                            "/miners/running" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners.Where({ $_.Status -eq [MinerStatus]::Running }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | ForEach-Object { $_.Workers = $_.WorkersRunning; $_ } | Select-Object -ExcludeProperty WorkersRunning)
                                Break
                            }
                            "/miners/unavailable" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners.Where({ $_.Available -NE $true }) | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp | Sort-Object -Property DeviceNames, Name, Algorithm)
                                Break
                            }
                            "/miners/device_combos" { 
                                $Data = ConvertTo-Json -Depth 4 @($Variables.Miners_Device_Combos | Select-Object -ExcludeProperty Arguments, Data, DataReaderJob, DataSampleTimestamp, Devices, EnvVars, PoolNames, Process, ProcessJob, SideIndicator, StatEnd, StatStart, ValidDataSampleTimestamp)
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
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Select-Object | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/added" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsAdded | Select-Object | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/available" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Where-Object Available | Select-Object | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/best" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsBest | Select-Object | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/new" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsNew | Select-Object | Sort-Object -Property Algorithm, Name, Region)
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
                                $Data = ConvertTo-Json -Depth 10  @($Variables.Pools.Where({ -not $_.Available }) | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/pools/updated" { 
                                $Data = ConvertTo-Json -Depth 10 @($Variables.PoolsUpdated | Select-Object | Sort-Object -Property Algorithm, Name, Region)
                                Break
                            }
                            "/poolreasons" { 
                                $Data = ConvertTo-Json -Depth 10 ($Variables.Pools.Where({ -not $_.Available }).Reasons | Sort-Object -Unique)
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
                                $Data = ConvertTo-Json -Depth 10 @($Variables.Regions[0] | Sort-Object)
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
                                $Data = ConvertTo-Json -Depth 10 @(Get-Content ".\Logs\switchinglog.csv" | ConvertFrom-Csv | Select-Object -Last 1000 | Sort-Object -Property DateTime -Descending)
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
                                If ($Config.ShowWorkerStatus -and $Config.MonitoringUser -and $Config.MonitoringServer -and $Variables.WorkersLastUpdated -lt ([DateTime]::Now).AddSeconds(-30)) { 
                                    Read-MonitoringData
                                }
                                $Workers = [System.Collections.ArrayList]@(
                                    $Variables.Workers | Select-Object @(
                                        @{ Name = "Algorithm"; Expression = { ($_.data | ForEach-Object { $_.Algorithm -split ',' -join ' & ' }) -join '<br>' } }, 
                                        @{ Name = "Benchmark Hashrate"; Expression = { ($_.data | ForEach-Object { ($_.EstimatedSpeed | ForEach-Object { If ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace '\s+', ' ' } Else { "-" } }) -join ' & ' }) -join '<br>' } }, 
                                        @{ Name = "Currency"; Expression = { $_.Data.Currency | Select-Object -Unique } }, 
                                        @{ Name = "EstimatedEarning"; Expression = { [Decimal](($_.Data.Earning | Measure-Object -Sum | Select-Object -ExpandProperty Sum) * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } }, 
                                        @{ Name = "EstimatedProfit"; Expression = { [Decimal]($_.Profit * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } }, 
                                        @{ Name = "LastSeen"; Expression = { "$($_.date)" } }, 
                                        @{ Name = "Live Hashrate"; Expression = { ($_.data | ForEach-Object { ($_.CurrentSpeed | ForEach-Object { If ([Double]$_ -gt 0) { "$($_ | ConvertTo-Hash)/s" -replace '\s+', ' ' } Else { '-' } }) -join ' & ' }) -join '<br>' } }, 
                                        @{ Name = "Miner"; Expression = { $_.data.name -join '<br/>'} }, 
                                        @{ Name = "Pool"; Expression = { ($_.data | ForEach-Object { ($_.Pool -split "," | ForEach-Object { $_ -replace 'Internal$', ' (Internal)' -replace 'External', ' (External)' }) -join ' & '}) -join '<br>' } }, 
                                        @{ Name = "Status"; Expression = { $_.status } }, 
                                        @{ Name = "Version"; Expression = { $_.version } }, 
                                        @{ Name = "Worker"; Expression = { $_.worker } }
                                    ) | Sort-Object -Property "Worker"
                                )
                                $Data = ConvertTo-Json @($Workers | Select-Object) -Depth 4
                                Break
                            }
                            Default { 
                                # Set index page
                                If ($Path -eq "/") { $Path = "/index.html" }

                                # Check if there is a file with the requested path
                                $Filename = "$BasePath$Path"
                                If (Test-Path -LiteralPath $Filename -PathType Leaf) { 
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
                                                If (Test-Path -LiteralPath $IncludeFile -PathType Leaf) { 
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
                        # If ($Config.APILogFile) { "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") Response: $Data" | Out-File $Config.APILogFile -Append -ErrorAction Ignore }
                        $Response.OutputStream.Write($ResponseBuffer, 0, $ResponseBuffer.Length)
                        $Response.Close()
                    }
                    # Only gets here if something is wrong and the server couldn't start or stops listening
                    $Server.Stop()
                    $Server.Close()
                }
            ) # End of $APIServer

            $Variables.APIRunspace | Add-Member -Force @{ PowerShell = $PowerShell; StartTime = $(([DateTime]::Now).ToUniversalTime()) }

            $Powershell.BeginInvoke() | Out-Null

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

        $Error.Clear()

        [System.GC]::Collect()
    }
}
