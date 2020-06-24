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
version:        3.9.9.0
version date:   12 June 2020
#>

Function Start-APIServer { 

    $APIVersion = "0.2.2.2"

    # Setup runspace to launch the API webserver in a separate thread
    $APIRunspace = [runspacefactory]::CreateRunspace()
    $APIRunspace.Open()

    Get-Variable -Scope Global | ForEach-Object { 
        Try { 
            $APIRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
        }
        Catch { }
    }
    $APIRunspace.SessionStateProxy.SetVariable("APIVersion", $APIVersion)

    $APIServer = [PowerShell]::Create().AddScript(
        { 
            # Set the starting directory
            Set-Location (Split-Path $MyInvocation.MyCommand.Path)
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

            #Server is running. OK to add port to variables
            $Variables.APIPort = $Config.APIPort

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
                    if ($Key -and $Value) { 
                        $Parameters.$Key = $Value
                    }
                }

                # Create a new response and the defaults for associated settings
                $Response = $Context.Response
                $ContentType = "application/json"
                $StatusCode = 200
                $Data = ""

                # Set the proper content type, status code and data for each resource
                Switch ($Path) { 
                    "/functions/log/get" { 
                        $Data = Get-Content -Path $Variables.LogFile -Tail 100 | ForEach-Object { "$($_)`n" }
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
                        If ($Parameters.Value -eq 0) { $Data += "`n`n$($TempStats.Count) stat file$(if ($TempStats.Count -ne 1) { "s" }) with $($Parameters.Value)$($Parameters.Unit) $($Parameters.Type)." }
                        If ($Parameters.Value -eq -1) { $Data += "`n`n$($TempStats.Count) disabled miner$(if ($TempStats.Count -ne 1) { "s" })." }
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/stat/remove" { 
                        If ($Parameters.Miners -and $Parameters.Type -eq "HashRate") { 
                            $Miners = Compare-Object -PassThru -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithm
                            $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                                $_.Profit = $_.Profit_Comparison = $_.Profit_Bias = $_.Earning = $_.Earning_Comparison = $_.Earning_Bias = [Double]::NaN
                                $_.Activated = 0
                                $Data += "`n$($_.Name) ($($_.Algorithm -join " & "))"
                                ForEach ($Algorithm in $_.Algorithm) { 
                                    $StatName = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                                    Remove-Stat -Name $StatName
                                }
                            }
                            $Data += "`n`nThe listed $(if ($Miners.Count -eq 1) { "miner" } Else { "$($Miners.Count) miners" }) will re-benchmark."
                            $Data = "<pre>$Data</pre>"
                            Break
                        }
                        If ($Parameters.Miners -and $Parameters.Type -eq "PowerUsage") { 
                            $Miners = Compare-Object -PassThru -ExcludeDifferent @($Variables.Miners | Select-Object) @($Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object) -Property Name, Algorithm
                            $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                                $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Comparison = $_.Profit_Bias = [Double]::NaN
                                $_.Activated = 0
                                $StatName = "$($_.Name)$(If ($_.Algorithm.Count -eq 1) { "_$($_.Algorithm)" })_$($Parameters.Type)"
                                $Data += "`n$($_.Name)$(If ($_.Algorithm.Count -eq 1) { " ($($_.Algorithm))" })"
                                Remove-Stat -Name $StatName
                            }
                            $Data += "`n`nThe listed $(if ($Miners.Count -eq 1) { "miner" } Else { "$($Miners.Count) miners" }) will re-measure power usage."
                            $Data = "<pre>$Data</pre>"
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
                        $Data += "`n`nRemoved $($TempStats.Count) $($Parameters.Type) stat file$(if ($TempStats.Count -ne 1) { "s" })."
                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/functions/stat/set" { 
                        If ($Parameters.Miners -and $Parameters.Type -eq "HashRate" -and $Parameters.Value -ne $null) { 
                            $Parameters.Miners | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object | ForEach-Object { 
                                $Miners = @($Variables.Miners | Where-Object Name -EQ $_.Name | Where-Object Algorithm -EQ $_.Algorithm)
                                $Miners | Sort-Object Name, Algorithm | ForEach-Object { 
                                    $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                                    $Data += "`n$($_.Name) ($($_.Algorithm -join " & "))"
                                    ForEach ($Algorithm in $_.Algorithm) { 
                                        $StatName = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                                        #Set stat value
                                        Set-Stat -Name $StatName -Value ($Parameters.Value) -Duration 0
                                    }
                                }
                            }
                            $Data += "`n`nThe listed $(if ($Miners.Count -eq 1) { "miner is"} else { "$($Miners.Count) miners are" }) $(if ($Parameters.Value -eq 0) { " marked as failed" } else { "disabled" } )." 
                            $Data = "<pre>$Data</pre>"
                            Break
                        }
                    }
                    "/functions/config/device/disable" { 
                        $Parameters.Keys | ForEach-Object {
                            $Key = $_
                            If ($Values = @($Parameters.$Key -split ',' | Where-Object { $_ -notin $Config.ExcludeDeviceName })) { 

                                $Data = "`nDevice configuration changed`n`nOld values:"
                                $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                $Data += "`nDeviceName:        '[$($Config."DeviceName" -join ', ')]'"
                    
                                $Config.ExcludeDeviceName = @((@($Config.ExcludeDeviceName) + $Values) | Sort-Object -Unique)
                                $Config.DeviceName = @($Config.DeviceName | Where-Object { $_ -notin $Config.ExcludeDeviceName } | Sort-Object -Unique)

                                $Data += "`n`nNew values:"
                                $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                $Data += "`nDeviceName:        '[$($Config."DeviceName" -join ', ')]'"
                                $Data += "`n`nConfigFile:`n$($Variables.ConfigFile)"

                                Write-Config -ConfigFile $Variables.ConfigFile

                                $Values | ForEach-Object { 
                                    $DeviceName = $_
                                    $Variables.Miners | Where-Object { $DeviceName -in $_.DeviceName } | ForEach-Object { 
                                        If ($_.Status -EQ "Running") { Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore }
                                        $_.Devices | ForEach-Object { $_.State = [DeviceState]::Disabled; $_.Status = "Disabled (ExcludeDeviceName: '$DeviceName')" }
                                    }
                                }
                                Write-Message "Disabled device $($Values -join ';') in web GUI. Config file '$($Variables.ConfigFile)' updated."
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
                            If ($Values = @($Parameters.$Key -split ',' | Where-Object { $_ -notin $Config.DeviceName })) { 
                                $Data = "`nDevice configuration changed`n`nOld values:"
                                $Data += "`nDeviceName:        '[$($Config."DeviceName" -join ', ')]'"
                                $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ',')]'"

                                $Config.DeviceName = @(@($Config.DeviceName) + $Values | Sort-Object -Unique)
                                $Config.ExcludeDeviceName = @($Config.ExcludeDeviceName | Where-Object { $_ -notin $Config.DeviceName } | Sort-Object -Unique)

                                $Data += "`n`nNew values:"
                                $Data += "`nDeviceName:        '[$($Config."DeviceName" -join ', ')]'"
                                $Data += "`nExcludeDeviceName: '[$($Config."ExcludeDeviceName" -join ', ')]'"
                                $Data += "`n`nConfigFile:`n$($Variables.ConfigFile)"

                                Write-Config -ConfigFile $Variables.ConfigFile

                                $Variables.Devices | Where-Object Name -in $Values | ForEach-Object { $_.State = [DeviceState]::Enabled; $_.Status = "Idle" }
                                Write-Message "Enabled device $($Values -join ';') in web GUI. Config file '$($Variables.ConfigFile)' updated."
                            }
                            Else {
                                $Data = "No configuration change"
                            }
                        }

                        $Data = "<pre>$Data</pre>"
                        Break
                    }
                    "/apiversion" { 
                        $Data = ConvertTo-Json -Depth 10 @($APIVersion | Select-Object)
                        Break
                    }
                    "/btcratefirstcurrency" { 
                        $Data = ConvertTo-Json @($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0) | Select-Object)
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
                        $Data = $Config | ConvertTo-Json -Depth 10
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
                    "/earnings" { 
                        $Data = ConvertTo-Json -Depth 10 ($Variables.Earnings | Select-Object)
                        Break
                    }
                    "/earningstrackerjobs" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.EarningsTrackerJobs | Select-Object -Property * -ExcludeProperty ChildJobs, Command, Process)
                        Break
                    }
                    "/firstcurrency" { 
                        $Data = ConvertTo-Json -Depth 10 @($Config.Currency | Select-Object -Index 0)
                        Break
                    }
                    "/miners" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Process, SideIndicator)
                        Break
                    }
                    "/miners/best" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Best -EQ $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Process, SideIndicator)
                        Break
                    }
                    "/miners/enabled" { 
                        $Data = ConvertTo-Json -Depth 10  @($Variables.Miners | Where-Object Enabled -EQ $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Process, SideIndicator)
                        Break
                    }
                    "/miners/disabled" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object { -not $_.Enabled } | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Process, SideIndicator)
                        Break
                    }
                    "/miners/failed" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Status -EQ "Failed" | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Process, SideIndicator)
                        Break
                    }
                    "/miners/fastest" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Fastest -EQ $true | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Process, SideIndicator)
                        Break
                    }
                    "/miners/idle" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Status -EQ "Idle" | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Process, SideIndicator)
                        Break
                    }
                    "/miners/running" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Miners | Where-Object Enabled -EQ $true | Where-Object Status -EQ "Running" | Select-Object -Property * -ExcludeProperty Data, DataReaderJob, DataReaderProcess, Process, SideIndicator)
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
                    "/pools" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Select-Object)
                        Break
                    }
                    "/pools/best" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Where-Object Best | Select-Object)
                        Break
                    }
                    "/pools/enabled" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Where-Object Enabled | Select-Object)
                        Break
                    }
                    "/pools/disabled" { 
                        $Data = ConvertTo-Json -Depth 10 @($Variables.Pools | Where-Object { -not $_.Enabled } | Select-Object)
                        Break
                    }
                    "/rates" { 
                        $Data = ConvertTo-Json @($Variables.Rates | Select-Object)
                        Break
                    }
                    "/stats" { 
                        $Data = ConvertTo-Json -Depth 10 @($Stats | Select-Object)
                        Break
                    }
                    "/switchinglog" { 
                        $Data = ConvertTo-Json -Depth 10 ($Variables.SwitchingLog | Select-Object)
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

    $APIServer.Runspace = $APIRunspace
    $APIServer.BeginInvoke()
}
