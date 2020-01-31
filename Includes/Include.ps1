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
File:           include.ps1
version:        3.8.1.3
version date:   29 January 2020
#>
 
# New-Item -Path function: -Name ((Get-FileHash $MyInvocation.MyCommand.path).Hash) -Value { $true} -ErrorAction SilentlyContinue | Out-Null
# Get-Item function::"$((Get-FileHash $MyInvocation.MyCommand.path).Hash)" | Add-Member @{ "File" = $MyInvocation.MyCommand.path} -ErrorAction SilentlyContinue

Function Get-Rates {
    # Read exchange rates from min-api.cryptocompare.com
    # Returned decimal values contain as many digits as the native currency
    $RatesBTC = (Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$($Config.Currency -join ",")&extraParams=http://nemosminer.com" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop).BTC
    If ($RatesBTC) {
        $Variables | Add-Member -Force @{ Rates = $RatesBTC }
    }
}

Function Write-Log { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message, 
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info", "Verbose", "Debug")]
        [string]$Level = "Info"
    )

    Begin { }
    Process { 
        # Inherit the same verbosity settings as the script importing this
        If (-not $PSBoundParameters.ContainsKey('InformationPreference')) { $InformationPreference = $PSCmdlet.GetVariableValue('InformationPreference') }
        If (-not $PSBoundParameters.ContainsKey('Verbose')) { $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference') }
        If (-not $PSBoundParameters.ContainsKey('Debug')) { $DebugPreference = $PSCmdlet.GetVariableValue('DebugPreference') }

        # Get mutex named MPMWriteLog. Mutexes are shared across all threads and processes. 
        # This lets us ensure only one thread is trying to write to the file at a time. 
        $Mutex = New-Object System.Threading.Mutex($false, "MPMWriteLog")

        $FileName = ".\Logs\NemosMiner_$(Get-Date -Format "yyyy-MM-dd").txt"
        $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        If (-not (Test-Path "Stats" -PathType Container)) { New-Item "Stats" -ItemType "directory" | Out-Null }

        Switch ($Level) { 
            'Error' { 
                $LevelText = 'ERROR:'
                Write-Warning -Message $Message
            }
            'Warn' { 
                $LevelText = 'WARNING:'
                Write-Warning -Message $Message
            }
            'Info' { 
                $LevelText = 'INFO:'
                Write-Information -MessageData $Message
            }
            'Verbose' { 
                $LevelText = 'VERBOSE:'
                Write-Verbose -Message $Message
            }
            'Debug' { 
                $LevelText = 'DEBUG:'
                Write-Debug -Message $Message
            }
        }

        # Attempt to aquire mutex, waiting up to 1 second If necessary.  If aquired, write to the log file and release mutex.  Otherwise, display an error. 
        If ($mutex.WaitOne(1000)) { 
            "$Date $LevelText $Message" | Out-File -FilePath $FileName -Append -Encoding utf8
            $Mutex.ReleaseMutex()
        }
        Else { 
            Write-Error -Message "Log file is locked, unable to write message to $FileName."
        }
    }
    End { }
}

Function GetNVIDIADriverVersion { 
    ((Get-CimInstance CIM_VideoController) | Select-Object name, description, @{ Name = "NVIDIAVersion" ; Expression = { ([regex]"[0-9.]{ 6}$").match($_.driverVersion).value.Replace(".", "").Insert(3, '.') } }  | Where-Object { $_.Description -like "*NVIDIA*" } | Select-Object -First 1).NVIDIAVersion
}

Function Global:RegisterLoaded ($File) { 
    New-Item -Path function: -Name script:"$((Get-FileHash (Resolve-Path $File)).Hash)" -Value { $true } -ErrorAction SilentlyContinue | Add-Member @{ "File" = (Resolve-Path $File).Path } -ErrorAction SilentlyContinue
    $Variables.StatusText = "File loaded - $($file) - $((Get-PSCallStack).Command[1])"
}

Function Global:IsLoaded ($File) { 
    $Hash = (Get-FileHash (Resolve-Path $File).Path).hash
    If (Test-Path function::$Hash) { 
        $True
    }
    Else { 
        Get-ChildItem function: | Where-Object { $_.File -eq (Resolve-Path $File).Path } | Remove-Item
        $false
    }
}

Function Start-IdleTracking { 
    # Function tracks how long the system has been idle and controls the paused state
    $IdleRunspace = [runspacefactory]::CreateRunspace()
    $IdleRunspace.Open()
    $IdleRunspace.SessionStateProxy.SetVariable('Config', $Config)
    $IdleRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
    $IdleRunspace.SessionStateProxy.SetVariable('StatusText', $StatusText)
    $IdleRunspace.SessionStateProxy.Path.SetLocation((Split-Path $script:MyInvocation.MyCommand.Path))
    $idlepowershell = [powershell]::Create()
    $idlePowershell.Runspace = $IdleRunspace
    $idlePowershell.AddScript(
        { 
            # No native way to check how long the system has been idle in powershell. Have to use .NET code.
            Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
namespace PInvoke.Win32 { 
    public static class UserInput { 
        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO { 
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput { 
            get { 
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }
        public static TimeSpan IdleTime { 
            get { 
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }
        public static int LastInputTicks { 
            get { 
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@
            # Start-Transcript ".\Logs\IdleTracking.log" -Append -Force
            $ProgressPreference = "SilentlyContinue"
            . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")
            While ($True) { 
                If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
                If (-not (IsLoaded(".\Includes\Core.ps1"))) { . .\Includes\Core.ps1; RegisterLoaded(".\Includes\Core.ps1") }
                $IdleSeconds = [math]::Round(([PInvoke.Win32.UserInput]::IdleTime).TotalSeconds)

                # Only do anything If Mine only when idle is turned on
                If ($Config.MineWhenIdle) { 
                    If ($Variables.Paused) { 
                        # Check If system has been idle long enough to unpause
                        If ($IdleSeconds -gt $Config.IdleSec) { 
                            $Variables.Paused = $False
                            $Variables.RestartCycle = $True
                            $Variables.StatusText = "System idle for $IdleSeconds seconds, starting mining..."
                        }
                    }
                    Else { 
                        # Pause If system has become active
                        If ($IdleSeconds -lt $Config.IdleSec) { 
                            $Variables.Paused = $True
                            $Variables.RestartCycle = $True
                            $Variables.StatusText = "System active, pausing mining..."
                        }
                    }
                }
                Start-Sleep  1
            }
        }
    ) | Out-Null
    $Variables | Add-Member -Force @{ IdleRunspaceHandle = $idlePowershell.BeginInvoke() }
}

Function Update-Monitoring { 
    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip If server and user aren't filled out
    If (!$Config.MonitoringServer) { return }
    If (!$Config.MonitoringUser) { return }

    If ($Config.ReportToServer) { 
        $Version = "$($Variables.CurrentProduct) $($Variables.CurrentVersion.ToString())"
        $Status = If ($Variables.Paused) { "Paused" } Else { "Running" }
        $RunningMiners = $Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Running" }
        # Add the associated object from $Variables.Miners since we need data from that too
        $RunningMiners | Foreach-Object { 
            $RunningMiner = $_
            $Miner = $Variables.Miners | Where-Object { $_.Name -eq $RunningMiner.Name -and $_.Path -eq $RunningMiner.Path -and $_.Arguments -eq $RunningMiner.Arguments }
            $_ | Add-Member -Force @{ 'Miner' = $Miner }
        }

        # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
        # reveal someone's windows username or other system information they might not want sent
        # For the ones that can be an array, comma separate them
        $Data = $RunningMiners | Foreach-Object { 
            $RunningMiner = $_
            [PSCustomObject]@{ 
                Name           = $RunningMiner.Name
                Path           = Resolve-Path -Relative $RunningMiner.Path
                Type           = $RunningMiner.Type -join ','
                Algorithm      = $RunningMiner.Algorithms -join ','
                Pool           = $RunningMiner.Miner.Pools.PSObject.Properties.Value.Name -join ','
                CurrentSpeed   = $RunningMiner.HashRates -join ','
                EstimatedSpeed = $RunningMiner.Miner.HashRates.PSObject.Properties.Value -join ','
                Profit         = $RunningMiner.Miner.Profit
            }
        }
        $DataJSON = ConvertTo-Json @($Data)
        # Calculate total estimated profit
        $Profit = [string]([Math]::Round(($data | Measure-Object Profit -Sum).Sum, 8))

        # Send the request
        $Body = @{ user = $Config.MonitoringUser; worker = $Config.WorkerName; version = $Version; status = $Status; profit = $Profit; data = $DataJSON }
        Try { 
            $Response = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/report.php" -Method Post -Body $Body -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            $Variables.StatusText = "Reporting status to server... $Response"
        }
        Catch { 
            $Variables.StatusText = "Unable to send status to $($Config.MonitoringServer)"
        }
    }

    If ($Config.ShowWorkerStatus) { 
        $Variables.StatusText = "Updating status of workers for $($Config.MonitoringUser)"
        Try { 
            $Workers = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/workers.php" -Method Post -Body @{ user = $Config.MonitoringUser } -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            # Calculate some additional properties and format others
            $Workers | Foreach-Object { 
                # Convert the unix timestamp to a datetime object, taking into account the local time zone
                $_ | Add-Member -Force @{ date = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.lastseen)) }

                # If a machine hasn't reported in for > 10 minutes, mark it as offline
                $TimeSinceLastReport = New-TimeSpan -Start $_.date -End (Get-Date)
                If ($TimeSinceLastReport.TotalMinutes -gt 10) { $_.status = "Offline" }
                # Show friendly time since last report in seconds, minutes, hours or days
                If ($TimeSinceLastReport.Days -ge 1) { 
                    $_ | Add-Member -Force @{ timesincelastreport = '{0:N0} days ago' -f $TimeSinceLastReport.TotalDays }
                }
                ElseIf ($TimeSinceLastReport.Hours -ge 1) { 
                    $_ | Add-Member -Force @{ timesincelastreport = '{0:N0} hours ago' -f $TimeSinceLastReport.TotalHours }
                }
                ElseIf ($TimeSinceLastReport.Minutes -ge 1) { 
                    $_ | Add-Member -Force @{ timesincelastreport = '{0:N0} minutes ago' -f $TimeSinceLastReport.TotalMinutes }
                }
                Else { 
                    $_ | Add-Member -Force @{ timesincelastreport = '{0:N0} seconds ago' -f $TimeSinceLastReport.TotalSeconds }
                }
            }

            $Variables | Add-Member -Force @{ Workers = $Workers }
            $Variables | Add-Member -Force @{ WorkersLastUpdated = (Get-Date) }
        }
        Catch { 
            $Variables.StatusText = "Unable to retrieve worker data from $($Config.MonitoringServer)"
        }
    }
}

Function Start-Mining { 
 
    $CycleRunspace = [runspacefactory]::CreateRunspace()
    $CycleRunspace.Open()
    $CycleRunspace.SessionStateProxy.SetVariable('Config', $Config)
    $CycleRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
    $CycleRunspace.SessionStateProxy.SetVariable('Stats', $Stats)
    $CycleRunspace.SessionStateProxy.SetVariable('StatusText', $StatusText)
    $CycleRunspace.SessionStateProxy.Path.SetLocation((Split-Path $script:MyInvocation.MyCommand.Path))
    $Powershell = [powershell]::Create()
    $Powershell.Runspace = $CycleRunspace
    $Powershell.AddScript(
        { 
            #Start the log
            Start-Transcript -Path ".\Logs\CoreCyle-$((Get-Date).ToString('yyyyMMdd')).log" -Append -Force
            # Purge Logs more than 10 days
            If ((Get-ChildItem ".\Logs\CoreCyle-*.log").Count -gt 10) { 
                Get-ChildItem ".\Logs\CoreCyle-*.log" | Where-Object { $_.name -notin (Get-ChildItem ".\Logs\CoreCyle-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 10).FullName } | Remove-Item -Force -Recurse
            }
            $ProgressPreference = "SilentlyContinue"
            . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")
            Update-Monitoring
            While ($true) { 
                If (-not (IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
                If (-not (IsLoaded(".\Includes\Core.ps1"))) { . .\Includes\Core.ps1; RegisterLoaded(".\Includes\Core.ps1") }
                $Variables.Paused | Out-Host
                If ($Variables.Paused) { 
                    # Run a dummy cycle to keep the UI updating.

                    # Keep updating exchange rate
                    Get-Rates

                    # Update the UI every 30 seconds, and the Last 1/6/24hr and text window every 2 minutes
                    For ($i = 0; $i -lt 4; $i++) { 
                        If ($i -eq 3) { 
                            $Variables | Add-Member -Force @{ EndLoop = $True }
                            Update-Monitoring
                        }
                        Else { 
                            $Variables | Add-Member -Force @{ EndLoop = $False }
                        }

                        $Variables.StatusText = "Mining paused"
                        Start-Sleep  30
                    }
                }
                Else { 
                    NPMCycle
                    Update-Monitoring
                    Start-Sleep $Variables.TimeToSleep
                }
            }
        }
    ) | Out-Null
    $Variables | Add-Member -Force @{ CycleRunspaceHandle = $Powershell.BeginInvoke() }
    $Variables | Add-Member -Force @{ LastDonated = (Get-Date).AddDays(-1).AddHours(1) }
}

Function Stop-Mining { 
  
    If ($Variables.ActiveMinerPrograms) { 
        $Variables.ActiveMinerPrograms | ForEach-Object { 
            [Array]$filtered = ($BestMiners_Combo | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments)
            If ($filtered.Count -eq 0) { 
                If ($_.Process -eq $null) { 
                    $_.Status = "Failed"
                }
                ElseIf ($_.Process.HasExited -eq $false) { 
                    $_.Active += (Get-Date) - $_.Process.StartTime
                    $_.Process.CloseMainWindow() | Out-Null
                    Start-Sleep 1
                    # simply "Kill with power"
                    Stop-Process $_.Process -Force | Out-Null
                    # try to kill any process with the same path, in case it is still running but the process handle is incorrect
                    $KillPath = $_.Path
                    Get-Process | Where-Object { $_.Path -eq $KillPath } | Stop-Process -Force
                    Write-Host -ForegroundColor Yellow "closing miner"
                    Start-Sleep 1
                    $_.Status = "Idle"
                }
            }
        }
    }

    If ($CycleRunspace) { $CycleRunspace.Close() }
    If ($Powershell) { $Powershell.Dispose() }
}

Function Update-Status ($Text) { 
    $Text | Out-Host
    # $Variables.StatusText = $Text 
    $LabelStatus.Lines += $Text
    If ($LabelStatus.Lines.Count -gt 20) { $LabelStatus.Lines = $LabelStatus.Lines[($LabelStatus.Lines.count - 10)..$LabelStatus.Lines.Count] }
    $LabelStatus.SelectionStart = $LabelStatus.TextLength;
    $LabelStatus.ScrollToCaret();
    $LabelStatus.Refresh | Out-Null
}

Function Update-Notifications ($Text) { 
    $LabelNotifications.Lines += $Text
    If ($LabelNotifications.Lines.Count -gt 20) { $LabelNotifications.Lines = $LabelNotifications.Lines[($LabelNotifications.Lines.count - 10)..$LabelNotifications.Lines.Count] }
    $LabelNotifications.SelectionStart = $LabelStatus.TextLength;
    $LabelNotifications.ScrollToCaret();
    $LabelStatus.Refresh | Out-Null
}

Function DetectGPUCount { 
    Update-Status("Fetching GPU Count")
    $DetectedGPU = @()
    Try { 
        $DetectedGPU += @(Get-CimInstance Win32_PnPEntity | Select-Object Name, Manufacturer, PNPClass, Availability, ConfigManagerErrorCode, ConfigManagerUserConfig | Where-Object { $_.Manufacturer -like "*NVIDIA*" -and $_.PNPClass -like "*display*" -and $_.ConfigManagerErrorCode -ne "22" } ) 
    }
    Catch { Update-Status("NVIDIA Detection failed") }
    Try { 
        $DetectedGPU += @(Get-CimInstance Win32_PnPEntity | Select-Object Name, Manufacturer, PNPClass, Availability, ConfigManagerErrorCode, ConfigManagerUserConfig | Where-Object { $_.Manufacturer -like "*Advanced Micro Devices*" -and $_.PNPClass -like "*display*" -and $_.ConfigManagerErrorCode -ne "22" } ) 
    }
    Catch { Update-Status("AMD Detection failed") }
    $DetectedGPUCount = $DetectedGPU.Count
    $i = 0
    $DetectedGPU | ForEach-Object { Update-Status("$($i): $($_.Name)") | Out-Null; $i++ }
    Update-Status("Found $($DetectedGPUCount) GPU(s)")
    $DetectedGPUCount
}

Function Load-Config { 
    param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )
    If (Test-Path $ConfigFile -PathType Leaf) { 
        $ConfigLoad = Get-Content $ConfigFile | ConvertFrom-json
        $ConfigLoad | ForEach-Object { $_.PSObject.Properties | Sort-Object Name | ForEach-Object { 
            $Config | Add-Member -Force @{$_.Name = $_.Value } }
        }
    }
}

Function Write-Config { 
    param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )
    If ($Config.ManualConfig) { Update-Status("Manual config mode - Not saving config"); return }
    If ($Config -is [Hashtable]) { 
        If (Test-Path $ConfigFile) { Copy-Item $ConfigFile "$($ConfigFile).backup" -force }
        $OrderedConfig = [PSCustomObject]@{ } ; ($Config | Select-Object -Property * -ExcludeProperty PoolsConfig) | ForEach-Object { $_.PSObject.Properties | Sort-Object Name | ForEach-Object { $OrderedConfig | Add-Member -Force @{ $_.Name = $_.Value } }  }
        $OrderedConfig | ConvertTo-Json | out-file $ConfigFile
        $PoolsConfig = Get-Content ".\Config\PoolsConfig.json" | ConvertFrom-Json
        $OrderedPoolsConfig = [PSCustomObject]@{ } ; $PoolsConfig | ForEach-Object { $_.PSObject.Properties | Sort-Object  Name | ForEach-Object { $OrderedPoolsConfig | Add-Member -Force @{ $_.Name = $_.Value } }  }
        $OrderedPoolsConfig.default | Add-Member -Force @{ Wallet = $Config.Wallet }
        $OrderedPoolsConfig.default | Add-Member -Force @{ UserName = $Config.UserName }
        $OrderedPoolsConfig.default | Add-Member -Force @{ WorkerName = $Config.WorkerName }
        $OrderedPoolsConfig.default | Add-Member -Force @{ APIKey = $Config.APIKey }
        $OrderedPoolsConfig | ConvertTo-Json | out-file ".\Config\PoolsConfig.json"
    }
}

Function Get-FreeTcpPort ($StartPort) { 
    # While ($Port -le ($StartPort + 10) -and !$PortFound) { Try { $Null = New-Object System.Net.Sockets.TCPClient -ArgumentList 127.0.0.1,$Port;$Port++} Catch { $Port;$PortFound=$True}}
    # $UsedPorts = (Get-NetTCPConnection | Where-Object { $_.state -eq "listen"}).LocalPort
    # While ($StartPort -in $UsedPorts) { 
    While (Get-NetTCPConnection -LocalPort $StartPort -ErrorAction SilentlyContinue) { $StartPort++ }
    $StartPort
}

Function Set-Stat { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name, 
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [DateTime]$Updated = (Get-Date), 
        [Parameter(Mandatory = $false)]
        [Bool]$FaultDetection = $false, 
        [Parameter(Mandatory = $false)]
        [Bool]$ChangeDetection = $false
    )

    $Updated = $Updated.ToUniversalTime()

    $Path = "Stats\$Name.txt"
    $SmallestValue = 1E-20

    $Stat = Get-Stat $Name

    If ($Stat) { 
        $ToleranceMin = $Value
        $ToleranceMax = $Value

        If ($FaultDetection) { 
            $ToleranceMin = $Stat.Week * (1 - [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
            $ToleranceMax = $Stat.Week * (1 + [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
        }

        If ($ChangeDetection -and [Decimal]$Value -eq [Decimal]$Stat.Live) { $Updated = $Stat.Updated }

        If ($Value -lt $ToleranceMin -or $Value -gt $ToleranceMax) { $Stat.ToleranceExceeded ++ }
        Else { $Stat | Add-Member ToleranceExceeded ([UInt16]0) -Force }

        If ($Value -and $Stat.ToleranceExceeded -gt 0 -and $Stat.ToleranceExceeded -lt 3) { #Update immediately If stat value is 0
            # If ($Name -match ".+_HashRate$") { 
            #     Write-Log -Level Warn "Stat file ($Name) was not updated because the value ($(($Value | ConvertTo-Hash) -replace '\s+', '')) is outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) [$($Stat.ToleranceExceeded) of 3 until enforced update]. "
            # }
            # Else { 
            #     Write-Log -Level Warn "Stat file ($Name) was not updated because the value ($($Value.ToString("N2"))W) is outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) [$($Stat.ToleranceExceeded) of 3 until enforced update]. "
            # }
        }
        Else { 
            If ($Value -eq 0 -or $Stat.ToleranceExceeded -gt 2) { #Update immediately If stat value is 0
                # If ($Value) { 
                #     If ($Name -match ".+_HashRate$") { 
                #         Write-Log -Level Warn "Stat file ($Name) was forcefully updated with value ($(($Value | ConvertTo-Hash) -replace '\s+', '')) because it was outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ')) to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) for $($Stat.ToleranceExceeded) times in a row. "
                #     }
                #     Else { 
                #         Write-Log -Level Warn "Stat file ($Name) was forcefully updated with value ($($Value.ToString("N2"))W) because it was outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) for $($Stat.ToleranceExceeded) times in a row. "
                #     }
                # }
                $Stat = [PSCustomObject]@{ 
                    Name                  = [String]$Name
                    Live                  = [Double]$Value
                    Minute                = [Double]$Value
                    Minute_Fluctuation    = [Double]0
                    Minute_5              = [Double]$Value
                    Minute_5_Fluctuation  = [Double]0
                    Minute_10             = [Double]$Value
                    Minute_10_Fluctuation = [Double]0
                    Hour                  = [Double]$Value
                    Hour_Fluctuation      = [Double]0
                    Day                   = [Double]$Value
                    Day_Fluctuation       = [Double]0
                    Week                  = [Double]$Value
                    Week_Fluctuation      = [Double]0
                    Updated               = [DateTime]$Updated
                    ToleranceExceeded     = [UInt16]0
                }
            }
            Else { 
                $Span_Minute = [Math]::Min(($Updated - $Stat.Updated).TotalMinutes, 1)
                $Span_Minute_5 = [Math]::Min((($Updated - $Stat.Updated).TotalMinutes / 5), 1)
                $Span_Minute_10 = [Math]::Min((($Updated - $Stat.Updated).TotalMinutes / 10), 1)
                $Span_Hour = [Math]::Min(($Updated - $Stat.Updated).TotalHours, 1)
                $Span_Day = [Math]::Min(($Updated - $Stat.Updated).TotalDays, 1)
                $Span_Week = [Math]::Min((($Updated - $Stat.Updated).TotalDays / 7), 1)
    
                $Stat = [PSCustomObject]@{ 
                    Name                  = $Name
                    Live                  = $Value
                    Minute                = ((1 - $Span_Minute) * $Stat.Minute) + ($Span_Minute * $Value)
                    Minute_Fluctuation    = ((1 - $Span_Minute) * $Stat.Minute_Fluctuation) + ($Span_Minute * ([Math]::Abs($Value - $Stat.Minute) / [Math]::Max([Math]::Abs($Stat.Minute), $SmallestValue)))
                    Minute_5              = ((1 - $Span_Minute_5) * $Stat.Minute_5) + ($Span_Minute_5 * $Value)
                    Minute_5_Fluctuation  = ((1 - $Span_Minute_5) * $Stat.Minute_5_Fluctuation) + ($Span_Minute_5 * ([Math]::Abs($Value - $Stat.Minute_5) / [Math]::Max([Math]::Abs($Stat.Minute_5), $SmallestValue)))
                    Minute_10             = ((1 - $Span_Minute_10) * $Stat.Minute_10) + ($Span_Minute_10 * $Value)
                    Minute_10_Fluctuation = ((1 - $Span_Minute_10) * $Stat.Minute_10_Fluctuation) + ($Span_Minute_10 * ([Math]::Abs($Value - $Stat.Minute_10) / [Math]::Max([Math]::Abs($Stat.Minute_10), $SmallestValue)))
                    Hour                  = ((1 - $Span_Hour) * $Stat.Hour) + ($Span_Hour * $Value)
                    Hour_Fluctuation      = ((1 - $Span_Hour) * $Stat.Hour_Fluctuation) + ($Span_Hour * ([Math]::Abs($Value - $Stat.Hour) / [Math]::Max([Math]::Abs($Stat.Hour), $SmallestValue)))
                    Day                   = ((1 - $Span_Day) * $Stat.Day) + ($Span_Day * $Value)
                    Day_Fluctuation       = ((1 - $Span_Day) * $Stat.Day_Fluctuation) + ($Span_Day * ([Math]::Abs($Value - $Stat.Day) / [Math]::Max([Math]::Abs($Stat.Day), $SmallestValue)))
                    Week                  = ((1 - $Span_Week) * $Stat.Week) + ($Span_Week * $Value)
                    Week_Fluctuation      = ((1 - $Span_Week) * $Stat.Week_Fluctuation) + ($Span_Week * ([Math]::Abs($Value - $Stat.Week) / [Math]::Max([Math]::Abs($Stat.Week), $SmallestValue)))
                    Updated               = $Updated
                    ToleranceExceeded     = [UInt16]0
                }
            }
        }
    }
    Else { 
        $Stat = [PSCustomObject]@{ 
            Name                  = [String]$Name
            Live                  = [Double]$Value
            Minute                = [Double]$Value
            Minute_Fluctuation    = [Double]0
            Minute_5              = [Double]$Value
            Minute_5_Fluctuation  = [Double]0
            Minute_10             = [Double]$Value
            Minute_10_Fluctuation = [Double]0
            Hour                  = [Double]$Value
            Hour_Fluctuation      = [Double]0
            Day                   = [Double]$Value
            Day_Fluctuation       = [Double]0
            Week                  = [Double]$Value
            Week_Fluctuation      = [Double]0
            Updated               = [DateTime]$Updated
            ToleranceExceeded     = [UInt16]0
        }
    }

    [PSCustomObject]@{ 
        Live                  = [Decimal]$Stat.Live
        Minute                = [Decimal]$Stat.Minute
        Minute_Fluctuation    = [Double]$Stat.Minute_Fluctuation
        Minute_5              = [Decimal]$Stat.Minute_5
        Minute_5_Fluctuation  = [Double]$Stat.Minute_5_Fluctuation
        Minute_10             = [Decimal]$Stat.Minute_10
        Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
        Hour                  = [Decimal]$Stat.Hour
        Hour_Fluctuation      = [Double]$Stat.Hour_Fluctuation
        Day                   = [Decimal]$Stat.Day
        Day_Fluctuation       = [Double]$Stat.Day_Fluctuation
        Week                  = [Decimal]$Stat.Week
        Week_Fluctuation      = [Double]$Stat.Week_Fluctuation
        Updated               = [DateTime]$Stat.Updated
    } | ConvertTo-Json | Set-Content $Path

    $Global:Stats | Add-Member $Name $Stat -Force

    $Stat
}

Function Get-AllStat { 
    [String[]]$Name = (Get-ChildItem "Stats" -ErrorAction Ignore | Select-Object -ExpandProperty BaseName)
    $Global:Stats | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $_ -notin $Name } | ForEach-Object { $Global:Stats.PSObject.Properties.Remove($_) }
    $Name
}

Function Get-Stat { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = (Get-AllStat)
    )

    $Name | Sort-Object -Unique | ForEach-Object { 
        $Stat_Name = $_
        If (-not $Global:Stats.$Stat_Name) { 
            If ($Global:Stats -isnot [PSCustomObject]) { 
                $Global:Stats = [PSCustomObject]@{ }
            }

            #Reduce number of errors
            If (-not (Test-Path "Stats\$Stat_Name.txt")) { 
                If (-not (Test-Path "Stats" -PathType Container)) { 
                    New-Item "Stats" -ItemType "directory" -Force | Out-Null
                }
                return
            }

            Try { 
                $Stat = Get-Content "Stats\$Stat_Name.txt" -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                $Global:Stats | Add-Member @{ 
                    $Stat_Name = [PSCustomObject]@{ 
                        Name                  = [String]$Stat_Name
                        Live                  = [Double]$Stat.Live
                        Minute                = [Double]$Stat.Minute
                        Minute_Fluctuation    = [Double]$Stat.Minute_Fluctuation
                        Minute_5              = [Double]$Stat.Minute_5
                        Minute_5_Fluctuation  = [Double]$Stat.Minute_5_Fluctuation
                        Minute_10             = [Double]$Stat.Minute_10
                        Minute_10_Fluctuation = [Double]$Stat.Minute_10_Fluctuation
                        Hour                  = [Double]$Stat.Hour
                        Hour_Fluctuation      = [Double]$Stat.Hour_Fluctuation
                        Day                   = [Double]$Stat.Day
                        Day_Fluctuation       = [Double]$Stat.Day_Fluctuation
                        Week                  = [Double]$Stat.Week
                        Week_Fluctuation      = [Double]$Stat.Week_Fluctuation
                        Updated               = [DateTime]$Stat.Updated
                        ToleranceExceeded     = [UInt16]0
                    }
                } -Force
            }
            Catch { 
                Write-Log -Level Warn "Stat file ($Stat_Name) is corrupt and will be reset. "
                Remove-Stat $Stat_Name
            }
        }

        $Global:Stats.$Stat_Name
    }
}

Function Remove-Stat { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @($Global:Stats.Keys | Select-Object) + @(Get-ChildItem "Stats" -ErrorAction Ignore | Select-Object -ExpandProperty BaseName)
    )

    $Name | Sort-Object -Unique | ForEach-Object { 
        If ($Global:Stats.$_) { $Global:Stats.Remove($_) }
        Remove-Item -Path  "Stats\$_.txt" -Force -Confirm:$false -ErrorAction SilentlyContinue
    }
}

Function Get-ChildItemContent { 
    param(
        [Parameter(Mandatory = $true)]
        [String]$Path,
        [Parameter(Mandatory = $false)]
        [Array]$Include = @()
    )

    $ChildItems = Get-ChildItem -Path $Path -Recurse -Include $Include | ForEach-Object { 
        $Name = $_.BaseName
        $Content = @()
        If ($_.Extension -eq ".ps1") { 
            $Content = &$_.FullName
        }
        Else { 
            Try { 
                $Content = $_ | Get-Content | ConvertFrom-Json
            }
            Catch [ArgumentException] { 
                $null
            }
        }
        $Content | ForEach-Object { 
            [PSCustomObject]@{ Name = $Name; Content = $_ }
        }
    }

    $ChildItems | Select-Object | ForEach-Object { 
        $Item = $_
        $ItemKeys = $Item.Content.PSObject.Properties.Name.Clone()
        $ItemKeys | ForEach-Object { 
            If ($Item.Content.$_ -is [String]) { 
                $Item.Content.$_ = Invoke-Expression "`"$($Item.Content.$_)`""
            }
            ElseIf ($Item.Content.$_ -is [PSCustomObject]) { 
                $Property = $Item.Content.$_
                $PropertyKeys = $Property.PSObject.Properties.Name
                $PropertyKeys | ForEach-Object { 
                    If ($Property.$_ -is [String]) { 
                        $Property.$_ = Invoke-Expression "`"$($Property.$_)`""
                    }
                }
            }
        }
    }
    $ChildItems
}
Function Invoke_TcpRequest { 
     
    param(
        [Parameter(Mandatory = $true)]
        [String]$Server = "localhost", 
        [Parameter(Mandatory = $true)]
        [String]$Port, 
        [Parameter(Mandatory = $true)]
        [String]$Request, 
        [Parameter(Mandatory = $true)]
        [Int]$Timeout = 10 #seconds
    )

    Try { 
        $Client = New-Object System.Net.Sockets.TcpClient $Server, $Port
        $Stream = $Client.GetStream()
        $Writer = New-Object System.IO.StreamWriter $Stream
        $Reader = New-Object System.IO.StreamReader $Stream
        $client.SendTimeout = $Timeout * 1000
        $client.ReceiveTimeout = $Timeout * 1000
        $Writer.AutoFlush = $true

        $Writer.WriteLine($Request)
        $Response = $Reader.ReadLine()
    }
    Catch { $Error.Remove($error[$Error.Count - 1]) }
    finally { 
        If ($Reader) { $Reader.Close() }
        If ($Writer) { $Writer.Close() }
        If ($Stream) { $Stream.Close() }
        If ($Client) { $Client.Close() }
    }

    $response
}

#************************************************************************************************************************************************************************************
#************************************************************************************************************************************************************************************
#************************************************************************************************************************************************************************************

Function Invoke_httpRequest { 
     
    param(
        [Parameter(Mandatory = $true)]
        [String]$Server = "localhost", 
        [Parameter(Mandatory = $true)]
        [String]$Port, 
        [Parameter(Mandatory = $false)]
        [String]$Request, 
        [Parameter(Mandatory = $true)]
        [Int]$Timeout = 10 #seconds
    )

    Try { 
        $response = Invoke-WebRequest "http://$($Server):$Port$Request" -UseBasicParsing -TimeoutSec $timeout
    }
    Catch { $Error.Remove($error[$Error.Count - 1]) }

    $response
}


#************************************************************************************************************************************************************************************
#************************************************************************************************************************************************************************************
#************************************************************************************************************************************************************************************

Function Get-HashRate { 
    param(
        [Parameter(Mandatory = $true)]
        [String]$API, 
        [Parameter(Mandatory = $true)]
        [Int]$Port, 
        [Parameter(Mandatory = $true)]
        [String[]]$Algorithms, 
        [Parameter(Mandatory = $false)]
        [Object]$Parameters = @{ }
    )

    $Server = "localhost"
    
    $Multiplier = 1000

    Try { 
        Switch ($API) { 

            "Dtsm" { 
                $Request = Invoke_TcpRequest $server $port "empty" 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request | ConvertFrom-Json | Select-Object  -ExpandProperty result 
                    $HashRate = [Double](($Data.sol_ps) | Measure-Object -Sum).Sum 
                }
            }

            "xgminer" { 
                $Message = @{ command = "summary"; parameter = "" } | ConvertTo-Json -Compress
                $Request = Invoke_TcpRequest $server $port $Message 5

                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request.Substring($Request.IndexOf("{ "), $Request.LastIndexOf("}") - $Request.IndexOf("{ ") + 1) -replace " ", "_" | ConvertFrom-Json

                    $HashRate = If ($Data.SUMMARY.HS_5s -ne $null) { [Double]$Data.SUMMARY.HS_5s * [math]::Pow($Multiplier, 0) }
                    ElseIf ($Data.SUMMARY.KHS_5s) { [Double]$Data.SUMMARY.KHS_5s * [Math]::Pow(1000, 1) }
                    ElseIf ($Data.SUMMARY.MHS_5s) { [Double]$Data.SUMMARY.MHS_5s * [Math]::Pow(1000, 2) }
                    ElseIf ($Data.SUMMARY.GHS_5s) { [Double]$Data.SUMMARY.GHS_5s * [Math]::Pow(1000, 3) }
                    ElseIf ($Data.SUMMARY.THS_5s) { [Double]$Data.SUMMARY.THS_5s * [Math]::Pow(1000, 4) }
                    ElseIf ($Data.SUMMARY.PHS_5s) { [Double]$Data.SUMMARY.PHS_5s * [Math]::Pow(1000, 5) }
                    ElseIf ($Data.SUMMARY.HS_30s) { [Double]$Data.SUMMARY.HS_30s * [Math]::Pow(1000, 0) }
                    ElseIf ($Data.SUMMARY.KHS_30s) { [Double]$Data.SUMMARY.KHS_30s * [Math]::Pow(1000, 1) }
                    ElseIf ($Data.SUMMARY.MHS_30s) { [Double]$Data.SUMMARY.MHS_30s * [Math]::Pow(1000, 2) }
                    ElseIf ($Data.SUMMARY.GHS_30s) { [Double]$Data.SUMMARY.GHS_30s * [Math]::Pow(1000, 3) }
                    ElseIf ($Data.SUMMARY.THS_30s) { [Double]$Data.SUMMARY.THS_30s * [Math]::Pow(1000, 4) }
                    ElseIf ($Data.SUMMARY.PHS_30s) { [Double]$Data.SUMMARY.PHS_30s * [Math]::Pow(1000, 5) }
                    ElseIf ($Data.SUMMARY.HS_av) { [Double]$Data.SUMMARY.HS_av * [Math]::Pow(1000, 0) }
                    ElseIf ($Data.SUMMARY.KHS_av) { [Double]$Data.SUMMARY.KHS_av * [Math]::Pow(1000, 1) }
                    ElseIf ($Data.SUMMARY.MHS_av) { [Double]$Data.SUMMARY.MHS_av * [Math]::Pow(1000, 2) }
                    ElseIf ($Data.SUMMARY.GHS_av) { [Double]$Data.SUMMARY.GHS_av * [Math]::Pow(1000, 3) }
                    ElseIf ($Data.SUMMARY.THS_av) { [Double]$Data.SUMMARY.THS_av * [Math]::Pow(1000, 4) }
                    ElseIf ($Data.SUMMARY.PHS_av) { [Double]$Data.SUMMARY.PHS_av * [Math]::Pow(1000, 5) }
                }
            }

            "palgin" { 
                $Request = Invoke_TcpRequest $server $port  "summary" 5
                $Data = $Request -split ";"
                $HashRate = [double]($Data[5] -split '=')[1] * 1000
            }

            "ccminer" { 
                $Request = Invoke_TcpRequest $server $port  "summary" 5
                $Data = $Request -split ";" | ConvertFrom-StringData
                $HashRate = If ([Double]$Data.KHS -ne 0 -or [Double]$Data.ACC -ne 0) { [Double]$Data.KHS * $Multiplier }
            }

            "zjazz" { 
                $Request = Invoke_TcpRequest $server $port  "summary" 10
                $Data = $Request -split ";" | ConvertFrom-StringData -ErrorAction Stop
                $HashRate = [Double]$Data.KHS * 2000000 #Temp fix for nlpool wrong hashrate
            }

            "excavator" { 
                $Message = @{ id = 1; method = "algorithm.list"; params = @() } | ConvertTo-Json -Compress
                $Request = Invoke_TcpRequest $server $port $message 5

                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = ($Request | ConvertFrom-Json).Algorithms
                    $HashRate = [Double](($Data.workers.speed) | Measure-Object -Sum).Sum
                }
            }

            "ewbf" { 
                $Message = @{ id = 1; method = "getstat" } | ConvertTo-Json -Compress
                $Request = Invoke_TcpRequest $server $port $message 5
                $Data = $Request | ConvertFrom-Json
                $HashRate = [Double](($Data.result.speed_sps) | Measure-Object -Sum).Sum
            }

            "gminer" { 
                $Message = @{ id = 1; method = "getstat" } | ConvertTo-Json -Compress
                $Request = Invoke_httpRequest $Server $Port "/stat" 5
                $Data = $Request | ConvertFrom-Json
                If (($Data.Algorithm -split '\+').Count -gt 1) { 
                    $HashRate = [Double]($Data.devices.speed2 | Measure-Object -Sum).Sum
                    $HashRate_Dual = [Double]($Data.devices.speed | Measure-Object -Sum).Sum
                }
                Else { 
                    $HashRate = [Double]($Data.devices.speed | Measure-Object -Sum).Sum
                }
            }

            "gminerdual" { 
                $Message = @{ id = 1; method = "getstat" } | ConvertTo-Json -Compress
                $Request = Invoke_httpRequest $Server $Port "/stat" 5
                $Data = $Request | ConvertFrom-Json
                $HashRate = [Double]($Data.devices.speed2 | Measure-Object -Sum).Sum
                $HashRate_Dual = [Double]($Data.devices.speed | Measure-Object -Sum).Sum
            }

            "claymore" { 
                $Request = Invoke_httpRequest $Server $Port "" 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request.Content.Substring($Request.Content.IndexOf("{ "), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{ ") + 1) | ConvertFrom-Json
                    $HashRate = [double]$Data.result[2].Split(";")[0] * $Multiplier
                    $HashRate_Dual = [double]$Data.result[4].Split(";")[0] * $Multiplier
                }
            }

            "nanominer" { 
                $Parameters = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
                $Request = Invoke_tcpRequest $Server $Port $Parameters 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [int](($Data.result[2] -split ';')[0]) #* 1000
                }
            }

            "ethminer" { 
                $Parameters = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
                $Request = Invoke_tcpRequest $Server $Port $Parameters 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [int](($Data.result[2] -split ';')[0]) * 1000
                }
            }

            "ClaymoreV2" { 
                $Request = Invoke_httpRequest $Server $Port "" 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request.Content.Substring($Request.Content.IndexOf("{ "), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{ ") + 1) | ConvertFrom-Json
                    $HashRate = [double]$Data.result[2].Split(";")[0] 
                }
            }

            "TTminer" { 
                $Parameters = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json  -Compress
                $Request = Invoke_tcpRequest $Server $Port $Parameters 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [int](($Data.result[2] -split ';')[0]) #* 1000
                }
            }

            "SRB" { 
                $Request = Invoke_httpRequest $Server $Port "" 5
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = @(
                        [double]$Data.HashRate_total_now
                        [double]$Data.HashRate_total_5min
                    ) | Where-Object { $_ -gt 0 } | Select-Object -First 1
                }
            }

            "prospector" { 
                $Request = Invoke_httpRequest $Server $Port "/api/v0/hashrates" 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [Double]($Data.rate | Measure-Object -Sum).sum
                }
            }

            "fireice" { 
                $Request = Invoke_httpRequest $Server $Port "/h" 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request.Content -split "</tr>" -match "total*" -split "<td>" -replace "<[^>]*>", ""
                    $HashRate = $Data[1]
                    If ($HashRate -eq "") { $HashRate = $Data[2] }
                    If ($HashRate -eq "") { $HashRate = $Data[3] }
                }
            }

            "miniZ" { 
                $Message = '{ "id":"0", "method":"getstat"}'
                $Request = Invoke_TcpRequest $server $port $message 5
                $Data = $Request | ConvertFrom-Json
                $HashRate = [Double](($Data.result.speed_sps) | Measure-Object -Sum).Sum
            }

            "wrapper" { 
                $HashRate = ""
                $wrpath = ".\Logs\energi.txt"
                $HashRate = If (Test-Path -Path $wrpath -PathType Leaf ) { 
                    Get-Content  $wrpath
                    $HashRate = ($HashRate -split ',')[0]
                    $HashRate = ($HashRate -split '.')[0]

                }
                Else { $hashrate = 0 }
            }

            "castXMR" { 
                $Request = Invoke_httpRequest $Server $Port "" 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request | ConvertFrom-Json 
                    $HashRate = [Double]($Data.devices.hash_rate | Measure-Object -Sum).Sum / 1000
                }
            }

            "XMrig" { 
                $Request = Invoke_httpRequest $Server $Port "/api.json" 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request | ConvertFrom-Json 
                    $HashRate = [Double]$Data.hashrate.total[0]
                }
            }

            "bminer" { 
                $Request = Invoke_httpRequest $Server $Port "/api/status" 5
                If ($Request -ne "" -and $request -ne $null) { 
                    $Data = $Request.content | ConvertFrom-Json 
                    $HashRate = 0
                    $Data.miners | Get-Member -MemberType NoteProperty | ForEach-Object { 
                        $HashRate += $Data.miners.($_.name).solver.solution_rate
                    }
                }
            }

            "GrinPro" { 
                $Request = Invoke_httpRequest $Server $Port "/api/status" 5
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [double](($Data.workers.graphsPerSecond) | Measure-Object -Sum).Sum
                }
            }

            "NBMiner" { 
                $Request = Invoke_httpRequest $Server $Port "/api/v1/status" 5
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [double]$Data.miner.total_hashrate_raw
                }
            }

            "NBMinerdual" { 
                $Request = Invoke_httpRequest $Server $Port "/api/v1/status" 5
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [double]$Data.miner.total_hashrate_raw
                    $HashRate_Dual = [double]$Data.miner.total_hashrate2_raw
                }
            }

            "LOL" { 
                $Request = Invoke_httpRequest $Server $Port "/summary" 5
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [Double]$data.Session.Performance_Summary
                }
            }

            "nheq" { 
                $Request = Invoke_TcpRequest $Server $Port "status" 5
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [Double]$Data.result.speed_ips * 1000000
                }
            }
        } #end switch

        @([double]$HashRate, [double]$HashRate_Dual)
    }
    Catch { }
}

Filter ConvertTo-Hash { 
    [CmdletBinding()]
    $Units = " kMGTPEZY" #k(ilo) in small letters, see https://en.wikipedia.org/wiki/Metric_prefix
    $Base1000 = [Math]::Truncate([Math]::Log([Math]::Abs($_), [Math]::Pow(1000, 1)))
    $Base1000 = [Math]::Max([Double]0, [Math]::Min($Base1000, $Units.Length - 1))
    "{0:n2} $($Units[$Base1000])H" -f ($_ / [Math]::Pow(1000, $Base1000))
}

Function Get-Combination { 
    param(
        [Parameter(Mandatory = $true)]
        [Array]$Value, 
        [Parameter(Mandatory = $false)]
        [Int]$SizeMax = $Value.Count, 
        [Parameter(Mandatory = $false)]
        [Int]$SizeMin = 1
    )

    $Combination = [PSCustomObject]@{ }

    For ($i = 0; $i -lt $Value.Count; $i++) { 
        $Combination | Add-Member @{ [Math]::Pow(2, $i) = $Value[$i] }
    }

    $Combination_Keys = $Combination | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

    For ($i = $SizeMin; $i -le $SizeMax; $i++) { 
        $x = [Math]::Pow(2, $i) - 1

        While ($x -le [Math]::Pow(2, $Value.Count) - 1) { 
            [PSCustomObject]@{ Combination = $Combination_Keys | Where-Object { $_ -band $x } | ForEach-Object { $Combination.$_ } }
            $smallest = ($x -band - $x)
            $ripple = $x + $smallest
            $new_smallest = ($ripple -band - $ripple)
            $ones = (($new_smallest / $smallest) -shr 1) - 1
            $x = $ripple -bor $ones
        }
    }
}

Function Start-SubProcess { 
    param(
        [Parameter(Mandatory = $true)]
        [String]$FilePath, 
        [Parameter(Mandatory = $false)]
        [String]$ArgumentList = "", 
        [Parameter(Mandatory = $false)]
        [String]$WorkingDirectory = ""
    )

    $Job = Start-Job -ArgumentList $PID, $FilePath, $ArgumentList, $WorkingDirectory { 
        param($ControllerProcessID, $FilePath, $ArgumentList, $WorkingDirectory)

        $ControllerProcess = Get-Process -Id $ControllerProcessID
        If ($ControllerProcess -eq $null) { return }

        Add-Type -TypeDefinition @"
            // http://www.daveamenta.com/2013-08/powershell-start-process-without-taking-focus/

            using System;
            using System.Diagnostics;
            using System.Runtime.InteropServices;
             
            [StructLayout(LayoutKind.Sequential)]
            public struct PROCESS_INFORMATION { 
                public IntPtr hProcess;
                public IntPtr hThread;
                public uint dwProcessId;
                public uint dwThreadId;
            }
             
            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            public struct STARTUPINFO { 
                public uint cb;
                public string lpReserved;
                public string lpDesktop;
                public string lpTitle;
                public uint dwX;
                public uint dwY;
                public uint dwXSize;
                public uint dwYSize;
                public uint dwXCountChars;
                public uint dwYCountChars;
                public uint dwFillAttribute;
                public STARTF dwFlags;
                public ShowWindow wShowWindow;
                public short cbReserved2;
                public IntPtr lpReserved2;
                public IntPtr hStdInput;
                public IntPtr hStdOutput;
                public IntPtr hStdError;
            }
             
            [StructLayout(LayoutKind.Sequential)]
            public struct SECURITY_ATTRIBUTES { 
                public int length;
                public IntPtr lpSecurityDescriptor;
                public bool bInheritHandle;
            }
             
            [Flags]
            public enum CreationFlags : int { 
                NONE = 0,
                DEBUG_PROCESS = 0x00000001,
                DEBUG_ONLY_THIS_PROCESS = 0x00000002,
                CREATE_SUSPENDED = 0x00000004,
                DETACHED_PROCESS = 0x00000008,
                CREATE_NEW_CONSOLE = 0x00000010,
                CREATE_NEW_PROCESS_GROUP = 0x00000200,
                CREATE_UNICODE_ENVIRONMENT = 0x00000400,
                CREATE_SEPARATE_WOW_VDM = 0x00000800,
                CREATE_SHARED_WOW_VDM = 0x00001000,
                CREATE_PROTECTED_PROCESS = 0x00040000,
                EXTENDED_STARTUPINFO_PRESENT = 0x00080000,
                CREATE_BREAKAWAY_FROM_JOB = 0x01000000,
                CREATE_PRESERVE_CODE_AUTHZ_LEVEL = 0x02000000,
                CREATE_DEFAULT_ERROR_MODE = 0x04000000,
                CREATE_NO_WINDOW = 0x08000000,
            }
             
            [Flags]
            public enum STARTF : uint { 
                STARTF_USESHOWWINDOW = 0x00000001,
                STARTF_USESIZE = 0x00000002,
                STARTF_USEPOSITION = 0x00000004,
                STARTF_USECOUNTCHARS = 0x00000008,
                STARTF_USEFILLATTRIBUTE = 0x00000010,
                STARTF_RUNFULLSCREEN = 0x00000020,  // ignored for non-x86 platforms
                STARTF_FORCEONFEEDBACK = 0x00000040,
                STARTF_FORCEOFFFEEDBACK = 0x00000080,
                STARTF_USESTDHANDLES = 0x00000100,
            }
             
            public enum ShowWindow : short { 
                SW_HIDE = 0,
                SW_SHOWNORMAL = 1,
                SW_NORMAL = 1,
                SW_SHOWMINIMIZED = 2,
                SW_SHOWMAXIMIZED = 3,
                SW_MAXIMIZE = 3,
                SW_SHOWNOACTIVATE = 4,
                SW_SHOW = 5,
                SW_MINIMIZE = 6,
                SW_SHOWMINNOACTIVE = 7,
                SW_SHOWNA = 8,
                SW_RESTORE = 9,
                SW_SHOWDEFAULT = 10,
                SW_FORCEMINIMIZE = 11,
                SW_MAX = 11
            }
             
            public static class Kernel32 { 
                [DllImport("kernel32.dll", SetLastError=true)]
                public static extern bool CreateProcess(
                    string lpApplicationName, 
                    string lpCommandLine, 
                    ref SECURITY_ATTRIBUTES lpProcessAttributes, 
                    ref SECURITY_ATTRIBUTES lpThreadAttributes,
                    bool bInheritHandles, 
                    CreationFlags dwCreationFlags, 
                    IntPtr lpEnvironment,
                    string lpCurrentDirectory, 
                    ref STARTUPINFO lpStartupInfo, 
                    out PROCESS_INFORMATION lpProcessInformation);
            }
"@
        $lpApplicationName = $FilePath;
        $lpCommandLine = '"' + $FilePath + '"' #Windows paths cannot contain ", so there is no need to escape
        If ($ArgumentList -ne "") { $lpCommandLine += " " + $ArgumentList }
        $lpProcessAttributes = New-Object SECURITY_ATTRIBUTES
        $lpProcessAttributes.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($lpProcessAttributes)
        $lpThreadAttributes = New-Object SECURITY_ATTRIBUTES
        $lpThreadAttributes.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($lpThreadAttributes)
        $bInheritHandles = $false
        $dwCreationFlags = [CreationFlags]::CREATE_NEW_CONSOLE
        $lpEnvironment = [IntPtr]::Zero
        If ($WorkingDirectory -ne "") { $lpCurrentDirectory = $WorkingDirectory } Else { $lpCurrentDirectory = $pwd }

        $lpStartupInfo = New-Object STARTUPINFO
        $lpStartupInfo.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($lpStartupInfo)
        $lpStartupInfo.wShowWindow = [ShowWindow]::SW_SHOWMINNOACTIVE
        $lpStartupInfo.dwFlags = [STARTF]::STARTF_USESHOWWINDOW
        $lpProcessInformation = New-Object PROCESS_INFORMATION

        $CreateProcessExitCode = [Kernel32]::CreateProcess($lpApplicationName, $lpCommandLine, [ref] $lpProcessAttributes, [ref] $lpThreadAttributes, $bInheritHandles, $dwCreationFlags, $lpEnvironment, $lpCurrentDirectory, [ref] $lpStartupInfo, [ref] $lpProcessInformation)
        $x = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Host "CreateProcessExitCode: $CreateProcessExitCode"
        Write-Host "Last error $x"
        Write-Host $lpCommandLine
        Write-Host "lpProcessInformation.dwProcessID: $($lpProcessInformation.dwProcessID)"

        If ($CreateProcessExitCode) { 
            Write-Host "lpProcessInformation.dwProcessID - WHEN TRUE: $($lpProcessInformation.dwProcessID)"

            $Process = Get-Process -Id $lpProcessInformation.dwProcessID

            # Dirty workaround
            # Need to investigate. lpProcessInformation sometimes comes null even If process started
            # So getting process with the same FilePath If so
            $Tries = 0
            While ($Process -eq $null -and $Tries -le 5) { 
                Write-Host "Can't get process - $Tries"
                $Tries++
                Start-Sleep 1
                $Process = (Get-Process | Where-Object { $_.Path -eq $FilePath } )[0]
                Write-Host "Process= $($Process.Handle)"
            }

            If ($Process -eq $null) { 
                Write-Host "Case 2 - Failed Get-Process"
                [PSCustomObject]@{ ProcessId = $null }
                return
            }
        }
        Else { 
            Write-Host "Case 1 - Failed CreateProcess"
            [PSCustomObject]@{ ProcessId = $null }
            return
        }

        [PSCustomObject]@{ ProcessId = $Process.Id; ProcessHandle = $Process.Handle }

        $ControllerProcess.Handle | Out-Null
        $Process.Handle | Out-Null

        Do { If ($ControllerProcess.WaitForExit(1000)) { $Process.CloseMainWindow() | Out-Null } }
        While ($Process.HasExited -eq $false)
    }

    Do { Start-Sleep  1; $JobOutput = Receive-Job $Job }
    While ($JobOutput -eq $null)

    $Process = Get-Process | Where-Object Id -EQ $JobOutput.ProcessId
    $Process.Handle | Out-Null
    $Process
}


Function Expand-WebRequest { 
    param(
        [Parameter(Mandatory = $true)]
        [String]$Uri, 
        [Parameter(Mandatory = $true)]
        [String]$Path
    )

    $FolderName_Old = ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName
    $FolderName_New = Split-Path $Path -Leaf
    $FileName = "$FolderName_New$(([IO.FileInfo](Split-Path $Uri -Leaf)).Extension)"

    If (Test-Path $FileName -PathType Leaf) { Remove-Item $FileName }
    If (Test-Path "$(Split-Path $Path)\$FolderName_New" -PathType Container) { Remove-Item "$(Split-Path $Path)\$FolderName_New" -Recurse -Force }
    If (Test-Path "$(Split-Path $Path)\$FolderName_Old" -PathType Container) { Remove-Item "$(Split-Path $Path)\$FolderName_Old" -Recurse -Force }

    Invoke-WebRequest $Uri -OutFile $FileName -TimeoutSec 15 -UseBasicParsing
    Start-Process ".\Utils\7z" "x $FileName -o$(Split-Path $Path)\$FolderName_Old -y -spe" -Wait
    If (Get-ChildItem "$(Split-Path $Path)\$FolderName_Old" | Where-Object PSIsContainer -EQ $false) { 
        Rename-Item "$(Split-Path $Path)\$FolderName_Old" "$FolderName_New"
    }
    Else { 
        Get-ChildItem "$(Split-Path $Path)\$FolderName_Old" | Where-Object PSIsContainer -EQ $true | ForEach-Object { Move-Item "$(Split-Path $Path)\$FolderName_Old\$_" "$(Split-Path $Path)\$FolderName_New" }
        Remove-Item "$(Split-Path $Path)\$FolderName_Old"
    }
    Remove-item $FileName
}

Function Get-Algorithm { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String]$Algorithm = ""
    )

    If (-not (Test-Path Variable:Script:Algorithms -ErrorAction SilentlyContinue)) {
        $Script:Algorithms = Get-Content ".\Includes\Algorithms.txt" | ConvertFrom-Json
    }

    $Algorithm = (Get-Culture).TextInfo.ToTitleCase(($Algorithm.ToLower() -replace "-", " " -replace "_", " " -replace "/", " ")) -replace " "

    If ($Script:Algorithms.$Algorithm) { $Script:Algorithms.$Algorithm }
    Else { $Algorithm }
}

Function Get-Region { 
    param(
        [Parameter(Mandatory = $true)]
        [String]$Region
    )

    If (-not (Test-Path Variable:Script:Locations -ErrorAction SilentlyContinue)) { 
        $Script:Regions = Get-Content ".\Includes\Locations.txt" | ConvertFrom-Json
    }

    $Region = (Get-Culture).TextInfo.ToTitleCase(($Region -replace "-", " " -replace "_", " ")) -replace " "

    If ($Script:Regions.$Region) { $Script:Regions.$Region }
    Else { $Region }
}

Function Autoupdate { 
    # GitHub Supporting only TLSv1.2 on feb 22 2018
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    Write-host (Split-Path $script:MyInvocation.MyCommand.Path)
    Update-Status("Checking AutoUpdate")
    Update-Notifications("Checking AutoUpdate")
    # write-host "Checking autoupdate"
    $NemosMinerFileHash = (Get-FileHash ".\NemosMiner.ps1").Hash
    Try { 
        $AutoUpdateVersion = Invoke-WebRequest "https://nemosminer.com/data/autoupdate.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
    }
    Catch { $AutoUpdateVersion = Get-content ".\Config\AutoUpdateVersion.json" | Convertfrom-json }
    If ($AutoUpdateVersion -ne $null) { $AutoUpdateVersion | ConvertTo-Json | Out-File ".\Config\AutoUpdateVersion.json" }
    If ($AutoUpdateVersion.Product -eq $Variables.CurrentProduct -and [Version]$AutoUpdateVersion.Version -gt $Variables.CurrentVersion -and $AutoUpdateVersion.AutoUpdate) { 
        Update-Status("Version $($AutoUpdateVersion.Version) available. (You are running $($Variables.CurrentVersion))")
        # Write-host "Version $($AutoUpdateVersion.Version) available. (You are running $($Variables.CurrentVersion))"
        $LabelNotifications.ForeColor = "Green"
        $LabelNotifications.Lines += "Version $([Version]$AutoUpdateVersion.Version) available"

        If ($AutoUpdateVersion.Autoupdate) { 
            $LabelNotifications.Lines += "Starting Auto Update"
            # Setting autostart to true
            If ($Variables.Started) { $Config.autostart = $true }
            Write-Config -ConfigFile $ConfigFile -Config $Config
            
            # Download update file
            $UpdateFileName = ".\$($AutoUpdateVersion.Product)-$($AutoUpdateVersion.Version)"
            Update-Status("Downloading version $($AutoUpdateVersion.Version)")
            Update-Notifications("Downloading version $($AutoUpdateVersion.Version)")
            Try { 
                Invoke-WebRequest $AutoUpdateVersion.Uri -OutFile "$($UpdateFileName).zip" -TimeoutSec 15 -UseBasicParsing
            }
            Catch { Update-Status("Update download failed"); Update-Notifications("Update download failed"); $LabelNotifications.ForeColor = "Red"; return }
            If (-not (Test-Path ".\$($UpdateFileName).zip" -PathType Leaf)) { 
                Update-Status("Cannot find update file")
                Update-Notifications("Cannot find update file")
                $LabelNotifications.ForeColor = "Red"
                return
            }

            # Backup current version folder in zip file
            Update-Status("Backing up current version...")
            Update-Notifications("Backing up current version...")
            $BackupFileName = ("AutoupdateBackup-$(Get-Date -Format u).zip").replace(" ", "_").replace(":", "")
            Start-Process ".\Utils\7z" "a $($BackupFileName) .\* -x!*.zip" -Wait -WindowStyle hidden
            If (-not (Test-Path .\$BackupFileName -PathType Leaf)) { Update-Status("Backup failed"); return }

            # Pre update specific actions If any
            # Use PreUpdateActions.ps1 in new release to place code
            If (Test-Path ".\$UpdateFileName\PreUpdateActions.ps1" -PathType Leaf) { 
                Invoke-Expression (get-content ".\$UpdateFileName\PreUpdateActions.ps1" -Raw)
            }

            # Empty OptionalMiners - Get rid of Obsolete ones
            Get-ChildItem .\OptionalMiners\ | ForEach-Object { Remove-Item -Recurse -Force $_.FullName }

            # unzip in child folder excluding config
            Update-Status("Unzipping update...")
            Start-Process ".\Utils\7z" "x $($UpdateFileName).zip -o.\ -y -spe -xr!config" -Wait -WindowStyle hidden

            # copy files 
            Update-Status("Copying files...")
            Copy-Item .\$UpdateFileName\* .\ -force -Recurse

            # Remove any obsolete Optional miner file (ie. Not in new version OptionalMiners)
            Get-ChildItem .\OptionalMiners\ | Where-Object { $_.name -notin (Get-ChildItem .\$UpdateFileName\OptionalMiners\).name } | ForEach-Object { Remove-Item -Recurse -Force $_.FullName }

            # Update Optional Miners to Miners If in use
            Get-ChildItem .\OptionalMiners\ | Where-Object { $_.name -in (Get-ChildItem .\Miners\).name } | ForEach-Object { Copy-Item -Force $_.FullName .\Miners\ }

            # Remove any obsolete miner file (ie. Not in new version Miners or OptionalMiners)
            Get-ChildItem .\Miners\ | Where-Object { $_.name -notin (Get-ChildItem .\$UpdateFileName\Miners\).name -and $_.name -notin (Get-ChildItem .\$UpdateFileName\OptionalMiners\).name } | ForEach-Object { Remove-Item -Recurse -Force $_.FullName }

            # Post update specific actions If any
            # Use PostUpdateActions.ps1 in new release to place code
            If (Test-Path ".\$UpdateFileName\PostUpdateActions.ps1" -PathType Leaf) { 
                Invoke-Expression (get-content ".\$UpdateFileName\PostUpdateActions.ps1" -Raw)
            }

            #Remove temp files
            Update-Status("Removing temporary files...")
            Remove-Item .\$UpdateFileName -Force -Recurse
            Remove-Item ".\$($UpdateFileName).zip" -Force
            If (Test-Path ".\PreUpdateActions.ps1" -PathType Leaf) { Remove-Item ".\PreUpdateActions.ps1" -Force }
            If (Test-Path ".\PostUpdateActions.ps1" -PathType Leaf) { Remove-Item ".\PostUpdateActions.ps1" -Force }
            Get-ChildItem "AutoupdateBackup-*.zip" | Where-Object { $_.name -notin (Get-ChildItem "AutoupdateBackup-*.zip" | Sort-Object  LastWriteTime -Descending | Select-Object -First 2).name } | Remove-Item -Force -Recurse
            
            # Start new instance (Wait and confirm start)
            # Kill old instance
            If ($AutoUpdateVersion.RequireRestart -or ($NemosMinerFileHash -ne (Get-FileHash ".\NemosMiner.ps1").Hash)) { 
                Update-Status("Starting my brother")
                $StartCommand = ((Get-CimInstance win32_process -filter "ProcessID=$PID" | Select-Object commandline).CommandLine)
                $NewKid = Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList @($StartCommand, (Split-Path $script:MyInvocation.MyCommand.Path))
                # Giving 10 seconds for process to start
                $Waited = 0
                Start-Sleep 10
                While (-not (Get-Process -id $NewKid.ProcessId -ErrorAction silentlycontinue) -and ($waited -le 10)) { Start-Sleep 1; $waited++ }
                If (-not (Get-Process -id $NewKid.ProcessId -ErrorAction silentlycontinue)) { 
                    Update-Status("Failed to start new instance of $($Variables.CurrentProduct)")
                    Update-Notifications("$($Variables.CurrentProduct) auto updated to version $($AutoUpdateVersion.Version) but failed to restart.")
                    $LabelNotifications.ForeColor = "Red"
                    return
                }

                $TempVerObject = (Get-Content .\Version.json | ConvertFrom-Json)
                $TempVerObject | Add-Member -Force @{ AutoUpdated = (Get-Date) }
                $TempVerObject | ConvertTo-Json | Out-File .\Version.json
                
                Update-Status("$($Variables.CurrentProduct) successfully updated to version $($AutoUpdateVersion.Version)")
                Update-Notifications("$($Variables.CurrentProduct) successfully updated to version $($AutoUpdateVersion.Version)")

                Update-Status("Killing myself")
                If (Get-Process -id $NewKid.ProcessId) { Stop-process -id $PID }
            }
            Else { 
                $TempVerObject = (Get-Content .\Version.json | ConvertFrom-Json)
                $TempVerObject | Add-Member -Force @{ AutoUpdated = (Get-Date) }
                $TempVerObject | ConvertTo-Json | Out-File .\Version.json
                
                Update-Status("Successfully updated to version $($AutoUpdateVersion.Version)")
                Update-Notifications("Successfully updated to version $($AutoUpdateVersion.Version)")
                $LabelNotifications.ForeColor = "Green"
            }
        }
        ElseIf (-not ($Config.Autostart)) { 
            UpdateStatus("Cannot autoupdate as autostart not selected")
            Update-Notifications("Cannot autoupdate as autostart not selected")
            $LabelNotifications.ForeColor = "Red"
        }
        Else { 
            UpdateStatus("$($AutoUpdateVersion.Product)-$($AutoUpdateVersion.Version). Not candidate for Autoupdate")
            Update-Notifications("$($AutoUpdateVersion.Product)-$($AutoUpdateVersion.Version). Not candidate for Autoupdate")
            $LabelNotifications.ForeColor = "Red"
        }
    }
    Else { 
        Update-Status("$($AutoUpdateVersion.Product)-$($AutoUpdateVersion.Version). Not candidate for Autoupdate")
        Update-Notifications("$($AutoUpdateVersion.Product)-$($AutoUpdateVersion.Version). Not candidate for Autoupdate")
        $LabelNotifications.ForeColor = "Green"
    }
}
