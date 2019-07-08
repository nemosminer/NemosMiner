<#
Copyright (c) 2018-2019 Nemo & MrPlus


NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           include.ps1
version:        3.8.0.0
version date:   13 June 2019
#>
 
# New-Item -Path function: -Name ((Get-FileHash $MyInvocation.MyCommand.path).Hash) -Value {$true} -EA SilentlyContinue | out-null
# Get-Item function::"$((Get-FileHash $MyInvocation.MyCommand.path).Hash)" | Add-Member @{"File" = $MyInvocation.MyCommand.path} -EA SilentlyContinue


Function GetNVIDIADriverVersion {
    ((gwmi win32_VideoController) | select name, description, @{Name = "NVIDIAVersion" ; Expression = { ([regex]"[0-9.]{6}$").match($_.driverVersion).value.Replace(".", "").Insert(3, '.') } } | ? { $_.Description -like "*NVIDIA*" } | select -First 1).NVIDIAVersion
}
 
Function Global:RegisterLoaded ($File) {
    New-Item -Path function: -Name script:"$((Get-FileHash (Resolve-Path $File)).Hash)" -Value { $true } -EA SilentlyContinue | Add-Member @{"File" = (Resolve-Path $File).Path } -EA SilentlyContinue
    $Variables.StatusText = "File loaded - $($file) - $((Get-PSCallStack).Command[1])"
}
    
Function Global:IsLoaded ($File) {
    $Hash = (Get-FileHash (Resolve-Path $File).Path).hash
    If (Test-Path function::$Hash) {
        $True
    }
    else {
        ls function: | ? { $_.File -eq (Resolve-Path $File).Path } | Remove-Item
        $false
    }
}

Function Start-IdleTracking {
    # Function tracks how long the system has been idle and controls the paused state
    $Global:IdleRunspace = [runspacefactory]::CreateRunspace()
    $IdleRunspace.Open()
    $IdleRunspace.SessionStateProxy.SetVariable('Config', $Config)
    $IdleRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
    $IdleRunspace.SessionStateProxy.SetVariable('StatusText', $StatusText)
    $IdleRunspace.SessionStateProxy.Path.SetLocation((Split-Path $script:MyInvocation.MyCommand.Path))
    $Global:idlepowershell = [powershell]::Create()
    $idlePowershell.Runspace = $IdleRunspace
    $idlePowershell.AddScript( {
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
            # Start-Transcript ".\logs\IdleTracking.log" -Append -Force
            $ProgressPreference = "SilentlyContinue"
            . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")
            While ($True) {
                if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
                if (!(IsLoaded(".\Includes\Core.ps1"))) { . .\Includes\Core.ps1; RegisterLoaded(".\Includes\Core.ps1") }
                $IdleSeconds = [math]::Round(([PInvoke.Win32.UserInput]::IdleTime).TotalSeconds)

                # Only do anything if Mine only when idle is turned on
                If ($Config.MineWhenIdle) {
                    If ($Variables.Paused) {
                        # Check if system has been idle long enough to unpause
                        If ($IdleSeconds -gt $Config.IdleSec) {
                            $Variables.Paused = $False
                            $Variables.RestartCycle = $True
                            $Variables.StatusText = "System idle for $IdleSeconds seconds, starting mining..."
                        }
                    } 
                    else {
                        # Pause if system has become active
                        If ($IdleSeconds -lt $Config.IdleSec) {
                            $Variables.Paused = $True
                            $Variables.RestartCycle = $True
                            $Variables.StatusText = "System active, pausing mining..."
                        }
                    }
                }
                Start-Sleep 1
            }
        } ) | Out-Null
    $Variables | Add-Member -Force @{IdleRunspaceHandle = $idlePowershell.BeginInvoke() }
}

Function Update-Monitoring {
    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip if server and user aren't filled out
    if (!$Config.MonitoringServer) { return }
    if (!$Config.MonitoringUser) { return }

    If ($Config.ReportToServer) {
        $Version = "$($Variables.CurrentProduct) $($Variables.CurrentVersion.ToString())"
        $Status = If ($Variables.Paused) { "Paused" } else { "Running" }
        $RunningMiners = $Variables.ActiveMinerPrograms | Where-Object { $_.Status -eq "Running" }
        # Add the associated object from $Variables.Miners since we need data from that too
        $RunningMiners | Foreach-Object {
            $RunningMiner = $_
            $Miner = $Variables.Miners | Where-Object { $_.Name -eq $RunningMiner.Name -and $_.Path -eq $RunningMiner.Path -and $_.Arguments -eq $RunningMiner.Arguments }
            $_ | Add-Member -Force @{'Miner' = $Miner }
        }

        # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
        # reveal someone's windows username or other system information they might not want sent
        # For the ones that can be an array, comma separate them
        $Data = $RunningMiners | Foreach-Object {
            $RunningMiner = $_
            [pscustomobject]@{
                Name           = $RunningMiner.Name
                Path           = Resolve-Path -Relative $RunningMiner.Path
                Type           = $RunningMiner.Type -join ','
                Algorithm      = $RunningMiner.Algorithms -join ','
                Pool           = $RunningMiner.Miner.Pools.PSObject.Properties.Value.Name -join ','
                CurrentSpeed   = $RunningMiner.HashRate -join ','
                EstimatedSpeed = $RunningMiner.Miner.HashRates.PSObject.Properties.Value -join ','
                Profit         = $RunningMiner.Miner.Profit
            }
        }
        $DataJSON = ConvertTo-Json @($Data)
        # Calculate total estimated profit
        $Profit = [string]([Math]::Round(($data | Measure-Object Profit -Sum).Sum, 8))

        # Send the request
        $Body = @{user = $Config.MonitoringUser; worker = $Config.WorkerName; version = $Version; status = $Status; profit = $Profit; data = $DataJSON }
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
            $Workers = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/workers.php" -Method Post -Body @{user = $Config.MonitoringUser } -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            # Calculate some additional properties and format others
            $Workers | Foreach-Object {
                # Convert the unix timestamp to a datetime object, taking into account the local time zone
                $_ | Add-Member -Force @{date = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.lastseen)) }

                # If a machine hasn't reported in for > 10 minutes, mark it as offline
                $TimeSinceLastReport = New-TimeSpan -Start $_.date -End (Get-Date)
                If ($TimeSinceLastReport.TotalMinutes -gt 10) { $_.status = "Offline" }
                # Show friendly time since last report in seconds, minutes, hours or days
                If ($TimeSinceLastReport.Days -ge 1) {
                    $_ | Add-Member -Force @{timesincelastreport = '{0:N0} days ago' -f $TimeSinceLastReport.TotalDays }
                }
                elseif ($TimeSinceLastReport.Hours -ge 1) {
                    $_ | Add-Member -Force @{timesincelastreport = '{0:N0} hours ago' -f $TimeSinceLastReport.TotalHours }
                }
                elseif ($TimeSinceLastReport.Minutes -ge 1) {
                    $_ | Add-Member -Force @{timesincelastreport = '{0:N0} minutes ago' -f $TimeSinceLastReport.TotalMinutes }
                }
                else {
                    $_ | Add-Member -Force @{timesincelastreport = '{0:N0} seconds ago' -f $TimeSinceLastReport.TotalSeconds }
                }
            }

            $Variables | Add-Member -Force @{Workers = $Workers }
            $Variables | Add-Member -Force @{WorkersLastUpdated = (Get-Date) }
        }
        Catch {
            $Variables.StatusText = "Unable to retrieve worker data from $($Config.MonitoringServer)"
        }
    }
}

Function Start-Mining {
 
    $Global:CycleRunspace = [runspacefactory]::CreateRunspace()
    $CycleRunspace.Open()
    $CycleRunspace.SessionStateProxy.SetVariable('Config', $Config)
    $CycleRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
    $CycleRunspace.SessionStateProxy.SetVariable('StatusText', $StatusText)
    $CycleRunspace.SessionStateProxy.Path.SetLocation((Split-Path $script:MyInvocation.MyCommand.Path))
    $Global:powershell = [powershell]::Create()
    $powershell.Runspace = $CycleRunspace
    $powershell.AddScript( {
            #Start the log
            Start-Transcript -Path ".\logs\CoreCyle-$((Get-Date).ToString('yyyyMMdd')).log" -Append -Force
            # Purge Logs more than 10 days
            If ((ls ".\logs\CoreCyle-*.log").Count -gt 10) {
                ls ".\logs\CoreCyle-*.log" | Where { $_.name -notin (ls ".\logs\CoreCyle-*.log" | sort LastWriteTime -Descending | select -First 10).FullName } | Remove-Item -Force -Recurse
            }
            $ProgressPreference = "SilentlyContinue"
            . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1")
            Update-Monitoring
            While ($True) {
                if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }
                if (!(IsLoaded(".\Includes\Core.ps1"))) { . .\Includes\Core.ps1; RegisterLoaded(".\Includes\Core.ps1") }
                $Variables.Paused | out-host
                If ($Variables.Paused) {
                    # Run a dummy cycle to keep the UI updating.

                    # Keep updating exchange rate
                    $Rates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=BTC" -TimeoutSec 15 -UseBasicParsing | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates
                    $Config.Currency | Where-Object { $Rates.$_ } | ForEach-Object { $Rates | Add-Member $_ ([Double]$Rates.$_) -Force }
                    $Variables | Add-Member -Force @{Rates = $Rates }

                    # Update the UI every 30 seconds, and the Last 1/6/24hr and text window every 2 minutes
                    for ($i = 0; $i -lt 4; $i++) {
                        if ($i -eq 3) {
                            $Variables | Add-Member -Force @{EndLoop = $True }
                            Update-Monitoring
                        }
                        else {
                            $Variables | Add-Member -Force @{EndLoop = $False }
                        }

                        $Variables.StatusText = "Mining paused"
                        Start-Sleep 30
                    }
                }
                else {
                    NPMCycle
                    Update-Monitoring
                    Sleep $Variables.TimeToSleep
                }
            }
        }) | Out-Null
    $Variables | add-Member -Force @{CycleRunspaceHandle = $powershell.BeginInvoke() }
    $Variables | Add-Member -Force @{LastDonated = (Get-Date).AddDays(-1).AddHours(1) }
}

Function Stop-Mining {
  
    If ($Variables.ActiveMinerPrograms) {
        $Variables.ActiveMinerPrograms | ForEach {
            [Array]$filtered = ($BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments)
            if ($filtered.Count -eq 0) {
                if ($_.Process -eq $null) {
                    $_.Status = "Failed"
                }
                elseif ($_.Process.HasExited -eq $false) {
                    $_.Active += (Get-Date) - $_.Process.StartTime
                    $_.Process.CloseMainWindow() | Out-Null
                    Sleep 1
                    # simply "Kill with power"
                    Stop-Process $_.Process -Force | Out-Null
                    # Try to kill any process with the same path, in case it is still running but the process handle is incorrect
                    $KillPath = $_.Path
                    Get-Process | Where-Object { $_.Path -eq $KillPath } | Stop-Process -Force
                    Write-Host -ForegroundColor Yellow "closing miner"
                    Sleep 1
                    $_.Status = "Idle"
                }
            }
        }
    }

    $Global:CycleRunspace.Close()
    $Global:powershell.Dispose()
}

Function Update-Status ($Text) {
    $Text | out-host
    # $Variables.StatusText = $Text 
    $LabelStatus.Lines += $Text
    If ($LabelStatus.Lines.Count -gt 20) { $LabelStatus.Lines = $LabelStatus.Lines[($LabelStatus.Lines.count - 10)..$LabelStatus.Lines.Count] }
    $LabelStatus.SelectionStart = $LabelStatus.TextLength;
    $LabelStatus.ScrollToCaret();
    $LabelStatus.Refresh | out-null
}

Function Update-Notifications ($Text) {
    $LabelNotifications.Lines += $Text
    If ($LabelNotifications.Lines.Count -gt 20) { $LabelNotifications.Lines = $LabelNotifications.Lines[($LabelNotifications.Lines.count - 10)..$LabelNotifications.Lines.Count] }
    $LabelNotifications.SelectionStart = $LabelStatus.TextLength;
    $LabelNotifications.ScrollToCaret();
    $LabelStatus.Refresh | out-null
}

Function DetectGPUCount {
    Update-Status("Fetching GPU Count")
    $DetectedGPU = @()
    try {
        $DetectedGPU += @(Get-WmiObject Win32_PnPEntity | Select Name, Manufacturer, PNPClass, Availability, ConfigManagerErrorCode, ConfigManagerUserConfig | Where { $_.Manufacturer -like "*NVIDIA*" -and $_.PNPClass -like "*display*" -and $_.ConfigManagerErrorCode -ne "22" }) 
    }
    catch { Update-Status("NVIDIA Detection failed") }
    try {
        $DetectedGPU += @(Get-WmiObject Win32_PnPEntity | Select Name, Manufacturer, PNPClass, Availability, ConfigManagerErrorCode, ConfigManagerUserConfig | Where { $_.Manufacturer -like "*Advanced Micro Devices*" -and $_.PNPClass -like "*display*" -and $_.ConfigManagerErrorCode -ne "22" }) 
    }
    catch { Update-Status("AMD Detection failed") }
    $DetectedGPUCount = $DetectedGPU.Count
    $i = 0
    $DetectedGPU | foreach { Update-Status("$($i): $($_.Name)") | Out-Null; $i++ }
    Update-Status("Found $($DetectedGPUCount) GPU(s)")
    $DetectedGPUCount
}

Function Load-Config {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )
    If (Test-Path $ConfigFile) {
        $ConfigLoad = Get-Content $ConfigFile | ConvertFrom-json
        $Config = [hashtable]::Synchronized(@{ }); $configLoad | % { $_.psobject.properties | sort Name | % { $Config | Add-Member -Force @{$_.Name = $_.Value } } }
        $Config
    }
}

Function Write-Config {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config,
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )
    If ($Config.ManualConfig) { Update-Status("Manual config mode - Not saving config"); return }
    If ($Config -ne $null) {
        if (Test-Path $ConfigFile) { Copy-Item $ConfigFile "$($ConfigFile).backup" }
        $OrderedConfig = [PSCustomObject]@{ }; ($config | select -Property * -ExcludeProperty PoolsConfig) | % { $_.psobject.properties | sort Name | % { $OrderedConfig | Add-Member -Force @{$_.Name = $_.Value } } }
        $OrderedConfig | ConvertTo-json | out-file $ConfigFile
        $PoolsConfig = Get-Content ".\Config\PoolsConfig.json" | ConvertFrom-Json
        $OrderedPoolsConfig = [PSCustomObject]@{ }; $PoolsConfig | % { $_.psobject.properties | sort Name | % { $OrderedPoolsConfig | Add-Member -Force @{$_.Name = $_.Value } } }
        $OrderedPoolsConfig.default | Add-member -Force @{Wallet = $Config.Wallet }
        $OrderedPoolsConfig.default | Add-member -Force @{UserName = $Config.UserName }
        $OrderedPoolsConfig.default | Add-member -Force @{WorkerName = $Config.WorkerName }
        $OrderedPoolsConfig.default | Add-member -Force @{APIKey = $Config.APIKey }
        $OrderedPoolsConfig | ConvertTo-json | out-file ".\Config\PoolsConfig.json"
    }
}

Function Get-FreeTcpPort ($StartPort) {
    # While ($Port -le ($StartPort + 10) -and !$PortFound) {try{$Null = New-Object System.Net.Sockets.TCPClient -ArgumentList 127.0.0.1,$Port;$Port++} catch {$Port;$PortFound=$True}}
    # $UsedPorts = (Get-NetTCPConnection | ? {$_.state -eq "listen"}).LocalPort
    # While ($StartPort -in $UsedPorts) {
    While (Get-NetTCPConnection -LocalPort $StartPort -EA SilentlyContinue) { $StartPort++ }
    $StartPort
}

function Set-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name, 
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [DateTime]$Date = (Get-Date)
    )

    $Path = "Stats\$Name.txt"
    $Date = $Date.ToUniversalTime()
    $SmallestValue = 1E-20

    $Stat = [PSCustomObject]@{
        Live                  = $Value
        Minute                = $Value
        Minute_Fluctuation    = 1 / 2
        Minute_5              = $Value
        Minute_5_Fluctuation  = 1 / 2
        Minute_10             = $Value
        Minute_10_Fluctuation = 1 / 2
        Hour                  = $Value
        Hour_Fluctuation      = 1 / 2
        Day                   = $Value
        Day_Fluctuation       = 1 / 2
        Week                  = $Value
        Week_Fluctuation      = 1 / 2
        Updated               = $Date
    }

    if (Test-Path $Path) { $Stat = Get-Content $Path | ConvertFrom-Json }

    $Stat = [PSCustomObject]@{
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
    }
    
    $Span_Minute = [Math]::Min(($Date - $Stat.Updated).TotalMinutes, 1)
    $Span_Minute_5 = [Math]::Min((($Date - $Stat.Updated).TotalMinutes / 5), 1)
    $Span_Minute_10 = [Math]::Min((($Date - $Stat.Updated).TotalMinutes / 10), 1)
    $Span_Hour = [Math]::Min(($Date - $Stat.Updated).TotalHours, 1)
    $Span_Day = [Math]::Min(($Date - $Stat.Updated).TotalDays, 1)
    $Span_Week = [Math]::Min((($Date - $Stat.Updated).TotalDays / 7), 1)

    $Stat = [PSCustomObject]@{
        Live                  = $Value
        Minute                = ((1 - $Span_Minute) * $Stat.Minute) + ($Span_Minute * $Value)
        Minute_Fluctuation    = ((1 - $Span_Minute) * $Stat.Minute_Fluctuation) + 
        ($Span_Minute * ([Math]::Abs($Value - $Stat.Minute) / [Math]::Max([Math]::Abs($Stat.Minute), $SmallestValue)))
        Minute_5              = ((1 - $Span_Minute_5) * $Stat.Minute_5) + ($Span_Minute_5 * $Value)
        Minute_5_Fluctuation  = ((1 - $Span_Minute_5) * $Stat.Minute_5_Fluctuation) + 
        ($Span_Minute_5 * ([Math]::Abs($Value - $Stat.Minute_5) / [Math]::Max([Math]::Abs($Stat.Minute_5), $SmallestValue)))
        Minute_10             = ((1 - $Span_Minute_10) * $Stat.Minute_10) + ($Span_Minute_10 * $Value)
        Minute_10_Fluctuation = ((1 - $Span_Minute_10) * $Stat.Minute_10_Fluctuation) + 
        ($Span_Minute_10 * ([Math]::Abs($Value - $Stat.Minute_10) / [Math]::Max([Math]::Abs($Stat.Minute_10), $SmallestValue)))
        Hour                  = ((1 - $Span_Hour) * $Stat.Hour) + ($Span_Hour * $Value)
        Hour_Fluctuation      = ((1 - $Span_Hour) * $Stat.Hour_Fluctuation) + 
        ($Span_Hour * ([Math]::Abs($Value - $Stat.Hour) / [Math]::Max([Math]::Abs($Stat.Hour), $SmallestValue)))
        Day                   = ((1 - $Span_Day) * $Stat.Day) + ($Span_Day * $Value)
        Day_Fluctuation       = ((1 - $Span_Day) * $Stat.Day_Fluctuation) + 
        ($Span_Day * ([Math]::Abs($Value - $Stat.Day) / [Math]::Max([Math]::Abs($Stat.Day), $SmallestValue)))
        Week                  = ((1 - $Span_Week) * $Stat.Week) + ($Span_Week * $Value)
        Week_Fluctuation      = ((1 - $Span_Week) * $Stat.Week_Fluctuation) + 
        ($Span_Week * ([Math]::Abs($Value - $Stat.Week) / [Math]::Max([Math]::Abs($Stat.Week), $SmallestValue)))
        Updated               = $Date
    }

    if (-not (Test-Path "Stats")) { New-Item "Stats" -ItemType "directory" }
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

    $Stat
}

function Get-Stat {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )
    
    if (-not (Test-Path "Stats")) { New-Item "Stats" -ItemType "directory" }
    Get-ChildItem "Stats" | Where-Object Extension -NE ".ps1" | Where-Object BaseName -EQ $Name | Get-Content | ConvertFrom-Json
}

function Get-ChildItemContent {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Path,
        [Parameter(Mandatory = $false)]
        [Array]$Include = @()
    )

    $ChildItems = Get-ChildItem -Recurse -Path $Path -Include $Include | ForEach-Object {
        $Name = $_.BaseName
        $Content = @()
        if ($_.Extension -eq ".ps1") {
            $Content = &$_.FullName
        }
        else {
            $Content = $_ | Get-Content | ConvertFrom-Json
        }
        $Content | ForEach-Object {
            [PSCustomObject]@{Name = $Name; Content = $_ }
        }
    }
    
    $ChildItems | ForEach-Object {
        $Item = $_
        $ItemKeys = $Item.Content.PSObject.Properties.Name.Clone()
        $ItemKeys | ForEach-Object {
            if ($Item.Content.$_ -is [String]) {
                $Item.Content.$_ = Invoke-Expression "`"$($Item.Content.$_)`""
            }
            elseif ($Item.Content.$_ -is [PSCustomObject]) {
                $Property = $Item.Content.$_
                $PropertyKeys = $Property.PSObject.Properties.Name
                $PropertyKeys | ForEach-Object {
                    if ($Property.$_ -is [String]) {
                        $Property.$_ = Invoke-Expression "`"$($Property.$_)`""
                    }
                }
            }
        }
    }
    
    $ChildItems
}
function Invoke_TcpRequest {
     
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

    try {
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
    catch { $Error.Remove($error[$Error.Count - 1]) }
    finally {
        if ($Reader) { $Reader.Close() }
        if ($Writer) { $Writer.Close() }
        if ($Stream) { $Stream.Close() }
        if ($Client) { $Client.Close() }
    }

    $response
    
}



#************************************************************************************************************************************************************************************
#************************************************************************************************************************************************************************************
#************************************************************************************************************************************************************************************



function Invoke_httpRequest {
     
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

    try {

        $response = Invoke-WebRequest "http://$($Server):$Port$Request" -UseBasicParsing -TimeoutSec $timeout
    }
    catch { $Error.Remove($error[$Error.Count - 1]) }
  

    $response
    
}


#************************************************************************************************************************************************************************************
#************************************************************************************************************************************************************************************
#************************************************************************************************************************************************************************************

function Get-HashRate {
    param(
        [Parameter(Mandatory = $true)]
        [String]$API, 
        [Parameter(Mandatory = $true)]
        [Int]$Port, 
        [Parameter(Mandatory = $false)]
        [Object]$Parameters = @{ } 

    )
    
    $Server = "localhost"
    
    $Multiplier = 1000
    #$Delta = 0.05
    #$Interval = 5
    #$HashRates = @()
    #$HashRates_Dual = @()

    try {
        switch ($API) {

            "Dtsm" {
                $Request = Invoke_TcpRequest $server $port "empty" 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request | ConvertFrom-Json | Select-Object  -ExpandProperty result 
                    $HashRate = [Double](($Data.sol_ps) | Measure-Object -Sum).Sum 
                }

            }

            "xgminer" {
                $Message = @{command = "summary"; parameter = "" } | ConvertTo-Json -Compress
                $Request = Invoke_TcpRequest $server $port $Message 5

                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request.Substring($Request.IndexOf("{"), $Request.LastIndexOf("}") - $Request.IndexOf("{") + 1) -replace " ", "_" | ConvertFrom-Json

                    $HashRate = if ($Data.SUMMARY.HS_5s -ne $null) { [Double]$Data.SUMMARY.HS_5s * [math]::Pow($Multiplier, 0) }
                    elseif ($Data.SUMMARY.KHS_5s -ne $null) { [Double]$Data.SUMMARY.KHS_5s * [math]::Pow($Multiplier, 1) }
                    elseif ($Data.SUMMARY.MHS_5s -ne $null) { [Double]$Data.SUMMARY.MHS_5s * [math]::Pow($Multiplier, 2) }
                    elseif ($Data.SUMMARY.GHS_5s -ne $null) { [Double]$Data.SUMMARY.GHS_5s * [math]::Pow($Multiplier, 3) }
                    elseif ($Data.SUMMARY.THS_5s -ne $null) { [Double]$Data.SUMMARY.THS_5s * [math]::Pow($Multiplier, 4) }
                    elseif ($Data.SUMMARY.PHS_5s -ne $null) { [Double]$Data.SUMMARY.PHS_5s * [math]::Pow($Multiplier, 5) }

                    if ($HashRate -eq $null) {
                        $HashRate = if ($Data.SUMMARY.HS_av -ne $null) { [Double]$Data.SUMMARY.HS_av * [math]::Pow($Multiplier, 0) }
                        elseif ($Data.SUMMARY.KHS_av -ne $null) { [Double]$Data.SUMMARY.KHS_av * [math]::Pow($Multiplier, 1) }
                        elseif ($Data.SUMMARY.MHS_av -ne $null) { [Double]$Data.SUMMARY.MHS_av * [math]::Pow($Multiplier, 2) }
                        elseif ($Data.SUMMARY.GHS_av -ne $null) { [Double]$Data.SUMMARY.GHS_av * [math]::Pow($Multiplier, 3) }
                        elseif ($Data.SUMMARY.THS_av -ne $null) { [Double]$Data.SUMMARY.THS_av * [math]::Pow($Multiplier, 4) }
                        elseif ($Data.SUMMARY.PHS_av -ne $null) { [Double]$Data.SUMMARY.PHS_av * [math]::Pow($Multiplier, 5) }
                    }
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
                $HashRate = if ([Double]$Data.KHS -ne 0 -or [Double]$Data.ACC -ne 0) { [Double]$Data.KHS * $Multiplier }
            }

            "zjazz" {
                $Request = Invoke_TcpRequest $server $port  "summary" 10
                $Data = $Request -split ";" | ConvertFrom-StringData -ErrorAction Stop
                $HashRate = [Double]$Data.KHS * 2000000 #Temp fix for nlpool wrong hashrate
            }

            "excavator" {
                $Message = @{id = 1; method = "algorithm.list"; params = @() } | ConvertTo-Json -Compress
                $Request = Invoke_TcpRequest $server $port $message 5

                if ($Request -ne "" -and $request -ne $null) {
                    $Data = ($Request | ConvertFrom-Json).Algorithms
                    $HashRate = [Double](($Data.workers.speed) | Measure-Object -Sum).Sum
                }
            }

            "ewbf" {
                $Message = @{id = 1; method = "getstat" } | ConvertTo-Json -Compress
                $Request = Invoke_TcpRequest $server $port $message 5
                $Data = $Request | ConvertFrom-Json
                $HashRate = [Double](($Data.result.speed_sps) | Measure-Object -Sum).Sum
            }

            "gminer" {
                $Message = @{id = 1; method = "getstat" } | ConvertTo-Json -Compress
                $Request = Invoke_httpRequest $Server $Port "/stat" 5
                $Data = $Request | ConvertFrom-Json
                $HashRate = [Double]($Data.devices.speed | Measure-Object -Sum).Sum
            }

            "claymore" {
                $Request = Invoke_httpRequest $Server $Port "" 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request.Content.Substring($Request.Content.IndexOf("{"), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{") + 1) | ConvertFrom-Json
                    $HashRate = [double]$Data.result[2].Split(";")[0] * $Multiplier
                    $HashRate_Dual = [double]$Data.result[4].Split(";")[0] * $Multiplier
                }
            }
	    
            "nanominer" {
                $Parameters = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
                $Request = Invoke_tcpRequest $Server $Port $Parameters 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [int](($Data.result[2] -split ';')[0]) #* 1000
                }
            }
	    
            "ethminer" {
                $Parameters = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
                $Request = Invoke_tcpRequest $Server $Port $Parameters 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [int](($Data.result[2] -split ';')[0]) * 1000
                }
            }

            "ClaymoreV2" {
                $Request = Invoke_httpRequest $Server $Port "" 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request.Content.Substring($Request.Content.IndexOf("{"), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{") + 1) | ConvertFrom-Json
                    $HashRate = [double]$Data.result[2].Split(";")[0] 
                }
            }
	    
            "TTminer" {

                $Parameters = @{id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json  -Compress
                $Request = Invoke_tcpRequest $Server $Port $Parameters 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [int](($Data.result[2] -split ';')[0]) #* 1000
                }
            }

            "prospector" {
                $Request = Invoke_httpRequest $Server $Port "/api/v0/hashrates" 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [Double]($Data.rate | Measure-Object -Sum).sum
                }
            }

            "fireice" {
                $Request = Invoke_httpRequest $Server $Port "/h" 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request.Content -split "</tr>" -match "total*" -split "<td>" -replace "<[^>]*>", ""
                    $HashRate = $Data[1]
                    if ($HashRate -eq "") { $HashRate = $Data[2] }
                    if ($HashRate -eq "") { $HashRate = $Data[3] }
                }
            }

            "miniZ" {
                $Message = '{"id":"0", "method":"getstat"}'
                $Request = Invoke_TcpRequest $server $port $message 5
                $Data = $Request | ConvertFrom-Json
                $HashRate = [Double](($Data.result.speed_sps) | Measure-Object -Sum).Sum
            }

            "wrapper" {
                $HashRate = ""
                $wrpath = ".\Logs\energi.txt"
                $HashRate = if (test-path -path $wrpath ) {
                    Get-Content  $wrpath
                    $HashRate = ($HashRate -split ',')[0]
                    $HashRate = ($HashRate -split '.')[0]

                }
                else { $hashrate = 0 }
            }

            "castXMR" {
                $Request = Invoke_httpRequest $Server $Port "" 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request | ConvertFrom-Json 
                    $HashRate = [Double]($Data.devices.hash_rate | Measure-Object -Sum).Sum / 1000
                }
            }

            "XMrig" {
                $Request = Invoke_httpRequest $Server $Port "/api.json" 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request | ConvertFrom-Json 
                    $HashRate = [Double]$Data.hashrate.total[0]
                }
            }

            "bminer" { 
                $Request = Invoke_httpRequest $Server $Port "/api/status" 5
                if ($Request -ne "" -and $request -ne $null) {
                    $Data = $Request.content | ConvertFrom-Json 
                    $HashRate = 0
                    $Data.miners | Get-Member -MemberType NoteProperty | ForEach-Object {
                        $HashRate += $Data.miners.($_.name).solver.solution_rate
                    }
                }
            }

            "GrinPro" {
                $Request = Invoke_httpRequest $Server $Port "/api/status" 5
                if ($Request) {
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [double](($Data.workers.graphsPerSecond) | Measure-Object -Sum).Sum
                }
            }

            "NBMiner" {
                $Request = Invoke_httpRequest $Server $Port "/api/v1/status" 5
                if ($Request) {
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [double]$Data.miner.total_hashrate_raw
                }
            }

            "LOL" {
                $Request = Invoke_httpRequest $Server $Port "/summary" 5
                if ($Request) {
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [Double]$data.Session.Performance_Summary
                }
            }

            "nheq" {
                $Request = Invoke_TcpRequest $Server $Port "status" 5
                if ($Request) {
                    $Data = $Request | ConvertFrom-Json
                    $HashRate = [Double]$Data.result.speed_ips * 1000000
                }
            }
            
        } #end switch
        
        $HashRates = @()
        $HashRates += [double]$HashRate
        $HashRates += [double]$HashRate_Dual

        $HashRates
    }
    catch { }
}

filter ConvertTo-Hash { 
    $Hash = $_
    switch ([math]::truncate([math]::log($Hash, [Math]::Pow(1000, 1)))) {
        "-Infinity" { "0  H" }
        0 { "{0:n2}  H" -f ($Hash / [Math]::Pow(1000, 0)) }
        1 { "{0:n2} KH" -f ($Hash / [Math]::Pow(1000, 1)) }
        2 { "{0:n2} MH" -f ($Hash / [Math]::Pow(1000, 2)) }
        3 { "{0:n2} GH" -f ($Hash / [Math]::Pow(1000, 3)) }
        4 { "{0:n2} TH" -f ($Hash / [Math]::Pow(1000, 4)) }
        Default { "{0:n2} PH" -f ($Hash / [Math]::Pow(1000, 5)) }
    }
}

function Get-Combination {
    param(
        [Parameter(Mandatory = $true)]
        [Array]$Value, 
        [Parameter(Mandatory = $false)]
        [Int]$SizeMax = $Value.Count, 
        [Parameter(Mandatory = $false)]
        [Int]$SizeMin = 1
    )

    $Combination = [PSCustomObject]@{ }

    for ($i = 0; $i -lt $Value.Count; $i++) {
        $Combination | Add-Member @{[Math]::Pow(2, $i) = $Value[$i] }
    }

    $Combination_Keys = $Combination | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name

    for ($i = $SizeMin; $i -le $SizeMax; $i++) {
        $x = [Math]::Pow(2, $i) - 1

        while ($x -le [Math]::Pow(2, $Value.Count) - 1) {
            [PSCustomObject]@{Combination = $Combination_Keys | Where-Object { $_ -band $x } | ForEach-Object { $Combination.$_ } }
            $smallest = ($x -band - $x)
            $ripple = $x + $smallest
            $new_smallest = ($ripple -band - $ripple)
            $ones = (($new_smallest / $smallest) -shr 1) - 1
            $x = $ripple -bor $ones
        }
    }
}

function Start-SubProcess {
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
        if ($ControllerProcess -eq $null) { return }




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
        if ($ArgumentList -ne "") { $lpCommandLine += " " + $ArgumentList }
        $lpProcessAttributes = New-Object SECURITY_ATTRIBUTES
        $lpProcessAttributes.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($lpProcessAttributes)
        $lpThreadAttributes = New-Object SECURITY_ATTRIBUTES
        $lpThreadAttributes.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($lpThreadAttributes)
        $bInheritHandles = $false
        $dwCreationFlags = [CreationFlags]::CREATE_NEW_CONSOLE
        $lpEnvironment = [IntPtr]::Zero
        if ($WorkingDirectory -ne "") { $lpCurrentDirectory = $WorkingDirectory } else { $lpCurrentDirectory = $pwd }

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
            # Need to investigate. lpProcessInformation sometimes comes null even if process started
            # So getting process with the same FilePath if so
            $Tries = 0
            While ($Process -eq $null -and $Tries -le 5) {
                Write-Host "Can't get process - $Tries"
                $Tries++
                Sleep 1
                $Process = (Get-Process | ? { $_.Path -eq $FilePath })[0]
                Write-Host "Process= $($Process.Handle)"
            }

            if ($Process -eq $null) {
                Write-Host "Case 2 - Failed Get-Process"
                [PSCustomObject]@{ProcessId = $null }
                return
            }
        }
        else {
            Write-Host "Case 1 - Failed CreateProcess"
            [PSCustomObject]@{ProcessId = $null }
            return
        }

        [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle }

        $ControllerProcess.Handle | Out-Null
        $Process.Handle | Out-Null

        do { if ($ControllerProcess.WaitForExit(1000)) { $Process.CloseMainWindow() | Out-Null } }
        while ($Process.HasExited -eq $false)
    }

    do { Start-Sleep 1; $JobOutput = Receive-Job $Job }
    while ($JobOutput -eq $null)

    $Process = Get-Process | Where-Object Id -EQ $JobOutput.ProcessId
    $Process.Handle | Out-Null
    $Process
}


function Expand-WebRequest {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Uri, 
        [Parameter(Mandatory = $true)]
        [String]$Path
    )

    $FolderName_Old = ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName
    $FolderName_New = Split-Path $Path -Leaf
    $FileName = "$FolderName_New$(([IO.FileInfo](Split-Path $Uri -Leaf)).Extension)"

    if (Test-Path $FileName) { Remove-Item $FileName }
    if (Test-Path "$(Split-Path $Path)\$FolderName_New") { Remove-Item "$(Split-Path $Path)\$FolderName_New" -Recurse -Force }
    if (Test-Path "$(Split-Path $Path)\$FolderName_Old") { Remove-Item "$(Split-Path $Path)\$FolderName_Old" -Recurse -Force }

    Invoke-WebRequest $Uri -OutFile $FileName -TimeoutSec 15 -UseBasicParsing
    Start-Process ".\Utils\7z" "x $FileName -o$(Split-Path $Path)\$FolderName_Old -y -spe" -Wait
    if (Get-ChildItem "$(Split-Path $Path)\$FolderName_Old" | Where-Object PSIsContainer -EQ $false) {
        Rename-Item "$(Split-Path $Path)\$FolderName_Old" "$FolderName_New"
    }
    else {
        Get-ChildItem "$(Split-Path $Path)\$FolderName_Old" | Where-Object PSIsContainer -EQ $true | ForEach-Object { Move-Item "$(Split-Path $Path)\$FolderName_Old\$_" "$(Split-Path $Path)\$FolderName_New" }
        Remove-Item "$(Split-Path $Path)\$FolderName_Old"
    }
    Remove-item $FileName
}

function Get-Algorithm {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Algorithm
    )
    
    $Algorithms = Get-Content ".\Includes\Algorithms.txt" | ConvertFrom-Json

    $Algorithm = (Get-Culture).TextInfo.ToTitleCase(($Algorithm -replace "-", " " -replace "_", " ")) -replace " "

    if ($Algorithms.$Algorithm) { $Algorithms.$Algorithm }
    else { $Algorithm }
}

function Get-Location {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Location
    )
    
    $Locations = Get-Content "Locations.txt" | ConvertFrom-Json

    $Location = (Get-Culture).TextInfo.ToTitleCase(($Location -replace "-", " " -replace "_", " ")) -replace " "

    if ($Locations.$Location) { $Locations.$Location }
    else { $Location }
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
    try {
        $AutoUpdateVersion = Invoke-WebRequest "https://nemosminer.com/data/autoupdate.json" -TimeoutSec 15 -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json
    }
    catch { $AutoUpdateVersion = Get-content ".\Config\AutoUpdateVersion.json" | Convertfrom-json }
    If ($AutoUpdateVersion -ne $null) { $AutoUpdateVersion | ConvertTo-json | Out-File ".\Config\AutoUpdateVersion.json" }
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
            try {
                Invoke-WebRequest $AutoUpdateVersion.Uri -OutFile "$($UpdateFileName).zip" -TimeoutSec 15 -UseBasicParsing
            }
            catch { Update-Status("Update download failed"); Update-Notifications("Update download failed"); $LabelNotifications.ForeColor = "Red"; return }
            If (!(test-path ".\$($UpdateFileName).zip")) {
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
            If (!(test-path .\$BackupFileName)) { Update-Status("Backup failed"); return }
            
            # Pre update specific actions if any
            # Use PreUpdateActions.ps1 in new release to place code
            If (Test-Path ".\$UpdateFileName\PreUpdateActions.ps1") {
                Invoke-Expression (get-content ".\$UpdateFileName\PreUpdateActions.ps1" -Raw)
            }
            
            # Empty OptionalMiners - Get rid of Obsolete ones
            ls .\OptionalMiners\ | % { Remove-Item -Recurse -Force $_.FullName }
            
            # unzip in child folder excluding config
            Update-Status("Unzipping update...")
            Start-Process ".\Utils\7z" "x $($UpdateFileName).zip -o.\ -y -spe -xr!config" -Wait -WindowStyle hidden
            
            # copy files 
            Update-Status("Copying files...")
            Copy-Item .\$UpdateFileName\* .\ -force -Recurse

            # Remove any obsolete Optional miner file (ie. Not in new version OptionalMiners)
            ls .\OptionalMiners\ | ? { $_.name -notin (ls .\$UpdateFileName\OptionalMiners\).name } | % { Remove-Item -Recurse -Force $_.FullName }

            # Update Optional Miners to Miners if in use
            ls .\OptionalMiners\ | ? { $_.name -in (ls .\Miners\).name } | % { Copy-Item -Force $_.FullName .\Miners\ }

            # Remove any obsolete miner file (ie. Not in new version Miners or OptionalMiners)
            ls .\Miners\ | ? { $_.name -notin (ls .\$UpdateFileName\Miners\).name -and $_.name -notin (ls .\$UpdateFileName\OptionalMiners\).name } | % { Remove-Item -Recurse -Force $_.FullName }

            # Post update specific actions if any
            # Use PostUpdateActions.ps1 in new release to place code
            If (Test-Path ".\$UpdateFileName\PostUpdateActions.ps1") {
                Invoke-Expression (get-content ".\$UpdateFileName\PostUpdateActions.ps1" -Raw)
            }
            
            #Remove temp files
            Update-Status("Removing temporary files...")
            Remove-Item .\$UpdateFileName -Force -Recurse
            Remove-Item ".\$($UpdateFileName).zip" -Force -Recurse
            If (Test-Path ".\PreUpdateActions.ps1") { Remove-Item ".\PreUpdateActions.ps1" -Force -Recurse }
            If (Test-Path ".\PostUpdateActions.ps1") { Remove-Item ".\PostUpdateActions.ps1" -Force -Recurse }
            ls "AutoupdateBackup-*.zip" | Where { $_.name -notin (ls "AutoupdateBackup-*.zip" | sort LastWriteTime -Descending | select -First 2).name } | Remove-Item -Force -Recurse
            
            # Start new instance (Wait and confirm start)
            # Kill old instance
            If ($AutoUpdateVersion.RequireRestart -or ($NemosMinerFileHash -ne (Get-FileHash ".\NemosMiner.ps1").Hash)) {
                Update-Status("Starting my brother")
                $StartCommand = ((gwmi win32_process -filter "ProcessID=$PID" | select commandline).CommandLine)
                $NewKid = Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList @($StartCommand, (Split-Path $script:MyInvocation.MyCommand.Path))
                # Giving 10 seconds for process to start
                $Waited = 0
                sleep 10
                While (!(Get-Process -id $NewKid.ProcessId -EA silentlycontinue) -and ($waited -le 10)) { sleep 1; $waited++ }
                If (!(Get-Process -id $NewKid.ProcessId -EA silentlycontinue)) {
                    Update-Status("Failed to start new instance of $($Variables.CurrentProduct)")
                    Update-Notifications("$($Variables.CurrentProduct) auto updated to version $($AutoUpdateVersion.Version) but failed to restart.")
                    $LabelNotifications.ForeColor = "Red"
                    return
                }
                
                $TempVerObject = (Get-Content .\Version.json | ConvertFrom-Json)
                $TempVerObject | Add-Member -Force @{AutoUpdated = (Get-Date) }
                $TempVerObject | ConvertTo-Json | Out-File .\Version.json
                
                Update-Status("$($Variables.CurrentProduct) successfully updated to version $($AutoUpdateVersion.Version)")
                Update-Notifications("$($Variables.CurrentProduct) successfully updated to version $($AutoUpdateVersion.Version)")

                Update-Status("Killing myself")
                If (Get-Process -id $NewKid.ProcessId) { Stop-process -id $PID }
            }
            else {
                $TempVerObject = (Get-Content .\Version.json | ConvertFrom-Json)
                $TempVerObject | Add-Member -Force @{AutoUpdated = (Get-Date) }
                $TempVerObject | ConvertTo-Json | Out-File .\Version.json
                
                Update-Status("Successfully updated to version $($AutoUpdateVersion.Version)")
                Update-Notifications("Successfully updated to version $($AutoUpdateVersion.Version)")
                $LabelNotifications.ForeColor = "Green"
            }
        }
        elseif (!($Config.Autostart)) {
            UpdateStatus("Cannot autoupdate as autostart not selected")
            Update-Notifications("Cannot autoupdate as autostart not selected")
            $LabelNotifications.ForeColor = "Red"
        }
        else {
            UpdateStatus("$($AutoUpdateVersion.Product)-$($AutoUpdateVersion.Version). Not candidate for Autoupdate")
            Update-Notifications("$($AutoUpdateVersion.Product)-$($AutoUpdateVersion.Version). Not candidate for Autoupdate")
            $LabelNotifications.ForeColor = "Red"
        }
    }
    else {
        Update-Status("$($AutoUpdateVersion.Product)-$($AutoUpdateVersion.Version). Not candidate for Autoupdate")
        Update-Notifications("$($AutoUpdateVersion.Product)-$($AutoUpdateVersion.Version). Not candidate for Autoupdate")
        $LabelNotifications.ForeColor = "Green"
    }
}
