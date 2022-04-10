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
File:           include.ps1
Version:        4.0.0.25
Version date:   09 April 2022
#>

# Window handling
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class Win32 { 
    [DllImport("user32.dll")]
    public static extern int SetWindowText(IntPtr hWnd, string strTitle);

    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern int SetForegroundWindow(IntPtr hwnd);

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);
}
"@

$Global:PriorityNames = [PSCustomObject]@{ -2 = "Idle"; -1 = "BelowNormal"; 0 = "Normal"; 1 = "AboveNormal"; 2 = "High"; 3 = "RealTime" }

Class Device { 
    [String]$Name
    [String]$Model
    [String]$Vendor
    [Int64]$Memory
    [Double]$MemoryGB
    [String]$Type
    [PSCustomObject]$CIM
    [PSCustomObject]$PNP
    [PSCustomObject]$Reg
    [PSCustomObject]$CpuFeatures

    [String]$Status = "Idle"

    [Int]$Bus
    [Int]$Id
    [Int]$Type_Id
    [Int]$Vendor_Id
    [Int]$Type_Vendor_Id

    [Int]$Slot = 0
    [Int]$Type_Slot
    [Int]$Vendor_Slot
    [Int]$Type_Vendor_Slot

    [Int]$Index = 0
    [Int]$Type_Index
    [Int]$Type_Vendor_Index
    [Int]$Vendor_Index
    [Int]$Bus_Index
    [Int]$Bus_Type_Index
    [Int]$Bus_Vendor_Index

    [Int]$PlatformId = 0
    [Int]$PlatformId_Index
    [Int]$Type_PlatformId_Index
    [Int]$Bus_Platform_Index

    [PSCustomObject]$OpenCL = [PSCustomObject]@{ }
    [DeviceState]$State = [DeviceState]::Enabled
    [Boolean]$ReadPowerUsage = $false
    [Double]$ConfiguredPowerUsage = 0 # Workaround if device does not expose power usage
}

Enum DeviceState { 
    Enabled
    Disabled
    Unsupported
}

Class Pool { 
    # static [Credential[]]$Credentials = @()
    # [Credential[]]$Credential = @()

    [String]$Name
    [String]$BaseName
    [String]$Algorithm
    [Nullable[Int]]$BlockHeight = $null
    [Nullable[Int64]]$DAGsize = $null
    [Nullable[Int]]$Epoch = $null
    [String]$Currency = ""
    [String]$CoinName = ""
    [String]$Host
    # [String[]]$Hosts # To be implemented for pool failover
    [UInt16]$Port
    [String]$User
    [String]$Pass
    [String]$Region
    [Boolean]$SSL
    [Double]$Fee
    [Double]$EarningsAdjustmentFactor = 1
    [Double]$EstimateFactor = 1
    [DateTime]$Updated = (Get-Date).ToUniversalTime()
    [Nullable[Int]]$Workers
    [Boolean]$Available = $true
    [String[]]$Reason = @("")
    [Boolean]$Best = $false

    # Stats
    [Double]$Price
    [Double]$Price_Bias
    [Double]$StablePrice
    [Double]$Accuracy
}

Class Worker { 
    [Pool]$Pool
    [Double]$Fee
    [Double]$Speed
    [Double]$Earning
    [Double]$Earning_Bias
    [Double]$Earning_Accuracy
    [Boolean]$Disabled
    [TimeSpan]$TotalMiningDuration
}

Enum MinerStatus { 
    Running
    Idle
    Failed
    Disabled
}

Class Miner { 
    static [Pool[]]$Pools = @()
    [Worker[]]$Workers = @()
    [Worker[]]$WorkersRunning = @()
    [Device[]]$Devices = @()
    [String]$Type

    [String]$Name
    [String]$BaseName
    [String]$Version
    [String]$Path
    [String]$URI
    [String]$Arguments
    [String]$CommandLine
    [UInt16]$Port
    [String[]]$DeviceName = @() # derived from devices
    [String[]]$Algorithm = @() # derived from workers
    [String[]]$Pool = @() # derived from workers
    [Double[]]$Speed_Live = @()

    [Boolean]$Benchmark = $false # derived from stats

    [Double]$Earning # derived from pool and stats
    [Double]$Earning_Bias # derived from pool and stats
    [Double]$Earning_Accuracy # derived from pool and stats
    [Double]$Profit
    [Double]$Profit_Bias

    [Boolean]$ReadPowerUsage = $false
    [Boolean]$MeasurePowerUsage = $false
    [Boolean]$Prioritize = $false # derived from BalancesKeepAlive

    [Double]$PowerUsage
    [Double]$PowerUsage_Live
    [Double]$PowerCost

    [Boolean]$MostProfitable = $false
    [Boolean]$Best = $false
    [Boolean]$Available = $true
    [Boolean]$Disabled = $false
    [String[]]$Reason
    [Boolean]$Restart = $false 
    [Boolean]$KeepRunning = $false # do not stop miner even if not best (MinInterval)

    hidden [PSCustomObject[]]$Data = $null
    hidden [System.Management.Automation.Job]$DataReaderJob = $null
    hidden [System.Management.Automation.Job]$Process = $null
    hidden [TimeSpan]$Active = [TimeSpan]::Zero

    [Int32]$ProcessId = 0
    [Int]$ProcessPriority = -1

    [Int]$Activated = 0
    [MinerStatus]$Status = [MinerStatus]::Idle
    [String]$StatusMessage
    [String]$Info
    [DateTime]$StatStart
    [DateTime]$StatEnd
    [Int]$DataCollectInterval = 5 # Seconds
    [String]$WindowStyle = "minimized"
    [String[]]$EnvVars = @()
    [Int]$MinDataSamples # for safe hashrate values
    [PSCustomObject]$LastSample # last hash rate sample
    [Int[]]$WarmupTimes # First value: time (in seconds) until first hash rate sample is valid (default 0, accept first sample), second value: time (in seconds) the miner is allowed to warm up, e.g. to compile the binaries or to get the API ready and providing first data samples before it get marked as failed (default 15)
    [DateTime]$BeginTime
    [DateTime]$EndTime
    [TimeSpan]$TotalMiningDuration # derived from pool and stats

    [String]$API
    [String]$MinerUri
    [String]$LogFile

    [String[]]GetProcessNames() { 
        Return @(([IO.FileInfo]($this.Path | Split-Path -Leaf -ErrorAction Ignore)).BaseName)
    }

    [String]GetCommandLineParameters() { 
        Return (Get-CommandLineParameters $this.Arguments)
    }

    [String]GetCommandLine() { 
        Return "$($this.Path) $($this.GetCommandLineParameters())"
    }

    [Int32]GetProcessId() { 
        Return $this.ProcessId
    }

    hidden StartDataReader() { 
        $ScriptBlock = { 
            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script
            Try { 
                # Load miner API file
                . ".\Includes\MinerAPIs\$($args[0]).ps1"
                $Miner = ($args[1] | ConvertFrom-Json) -as $args[0]
                While ($true) { 
                    $NextLoop = (Get-Date).AddSeconds($Miner.DataCollectInterval)
                    $Miner.GetMinerData()
                    While ((Get-Date) -lt $NextLoop) { Start-Sleep -Milliseconds 50 }
                }
            }
            Catch { 
                Return $Error[0]
            }
        }
        # Start Miner data reader
        $this | Add-Member -Force @{ DataReaderJob = Start-ThreadJob -Name "$($this.Name)_DataReader" -ThrottleLimit 99 -InitializationScript ([ScriptBlock]::Create("Set-Location('$(Get-Location)')")) -ScriptBlock $ScriptBlock -ArgumentList ($this.API), ($this | Select-Object -Property Algorithm, DataCollectInterval, Devices, Name, Path, Port, ReadPowerUsage, LogFile | ConvertTo-Json -WarningAction Ignore) }
    }

    hidden StopDataReader() { 
        # Stop Miner data reader
        $this.DataReaderJob | Stop-Job -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore
    }

    hidden RestartDataReader() { 
        # Read data if available before restarting
        If ($this.DataReaderJob.HasMoreData) { $this.Data += @($this.DataReaderJob | Receive-Job | Select-Object) }
        $this.StopDataReader()
        $this.StartDataReader()
    }

    hidden StartMining() { 
        $this.Status = [MinerStatus]::Idle
        $this.Info = "{$(($this.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"
        $this.StatusMessage = "Starting $($this.Info)"
        $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
        $this.Activated++

        Write-Message "Starting miner '$($this.Name) $($this.Info)'..."

        If (Test-Json $this.Arguments -ErrorAction Ignore) { $this.CreateConfigFiles() }

        If ($this.Process) { 
            If ($this.Process | Get-Job -ErrorAction SilentlyContinue) { 
                $this.Process | Remove-Job -Force -ErrorAction Ignore
            }

            If (-not ($this.Process | Get-Job -ErrorAction SilentlyContinue)) { 
                $this.Active += $this.Process.PSEndTime - $this.Process.PSBeginTime
                $this.Process = $null
            }
        }

        If (-not $this.Process) { 
            If ($this.Benchmark -EQ $true -or $this.MeasurePowerUsage -EQ $true) { $this.Data = @() } # When benchmarking clear data on each miner start
            $this.Process = Invoke-CreateProcess -BinaryPath $this.Path -ArgumentList $this.GetCommandLineParameters() -WorkingDirectory (Split-Path $this.Path) -MinerWindowStyle $this.WindowStyle -Priority $this.ProcessPriority -EnvBlock $this.EnvVars -JobName $this.Name -LogFile $this.LogFile
            $this.Status = [MinerStatus]::Running
            Write-Message -Level Verbose $this.CommandLine

            # Log switching information to .\Logs\SwitchingLog.csv
            [PSCustomObject]@{ 
                DateTime          = (Get-Date -Format o)
                Action            = "Launched"
                Name              = $this.Name
                Device            = ($this.Devices.Name | Sort-Object) -join "; "
                Type              = $this.Type
                Account           = ($this.Workers.Pool.User | ForEach-Object { $_ -split "\." | Select-Object -First 1 } | Select-Object -Unique) -join "; "
                Pool              = ($this.Workers.Pool.Name | Select-Object -Unique) -join "; "
                Algorithm         = $this.Workers.Pool.Algorithm -join "; "
                Duration          = ""
                Earning           = $this.Earning
                Earning_Bias      = $this.Earning_Bias
                Profit            = $this.Profit
                Profit_Bias       = $this.Profit_Bias
                CommandLine       = $this.CommandLine
                Benchmark         = $this.Benchmark
                MeasurePowerUsage = $this.MeasurePowerUsage
                Reason            = ""
                LastDataSample    = $null
            } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation -ErrorAction Ignore

            If ($this.Process | Get-Job -ErrorAction SilentlyContinue) { 
                For ($WaitForPID = 0; $WaitForPID -le 20; $WaitForPID++) { 
                    If ($this.ProcessId = [Int32]((Get-CimInstance CIM_Process | Where-Object { $_.ExecutablePath -eq $this.Path -and $_.CommandLine -eq "$($this.Path) $($this.GetCommandLineParameters())" }).ProcessId)) { 
                        $this.StatusMessage = "Warming up $($this.Info)"
                        $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
                        $this.StatStart = $this.BeginTime = (Get-Date).ToUniversalTime()
                        $this.StartDataReader()
                        $this.Speed_Live = @($this.Algorithm | ForEach-Object { [Double]::NaN })
                        $this.WorkersRunning = $this.Workers
                        Break
                    }
                    Start-Sleep -Milliseconds 100
                }
            }
            Else { 
                $this.Status = [MinerStatus]::Failed
                $this.StatusMessage = "Failed $($this.Info)"
                $this.Devices | ForEach-Object { $_.Status = "Failed" }
            }
        }
    }

    [MinerStatus]GetStatus() { 
        If ($this.Process.State -eq [MinerStatus]::Running -and $this.ProcessId -and (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue).ProcessName) { # Use ProcessName, some crashed miners are dead, but may still be found by their processId
            Return [MinerStatus]::Running
        }
        ElseIf ($this.Status -eq [MinerStatus]::Running) { 
            Return [MinerStatus]::Failed
        }
        Else { 
            Return $this.Status
        }
    }

    SetStatus([MinerStatus]$Status) { 
        Switch ($Status) { 
            "Running" { 
                If ($Status -eq $this.GetStatus()) { Return }
                $this.StartMining()
            }
            "Idle" { 
                $this.StopMining()
            }
            Default { 
                $this.Status = [MinerStatus]::Failed
                $this.StopMining()
            }
        }
    }

    hidden StopMining() { 
        If ($this.Status -eq [MinerStatus]::Running) { 
            $this.StatusMessage = "Stopping miner '$($this.Name) $($this.Info)'..."
            Write-Message -Level INFO $this.StatusMessage
        }
        Else { 
            Write-Message -Level ERROR $this.StatusMessage
        }

        # Stop Miner data reader
        $this.StopDataReader()

        $this.EndTime = (Get-Date).ToUniversalTime()

        If ($this.ProcessId) { 
            If (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue) { 
                Stop-Process -Id $this.ProcessId -Force -ErrorAction Ignore
            }
            $this.ProcessId = $null
        }
        If ($this.Process) { 
            $this.Process | Remove-Job -Force -ErrorAction Ignore
            $this.Process = $null 
        }

        $this.Status = If ($this.Status -eq [MinerStatus]::Running) { [MinerStatus]::Idle } Else { [MinerStatus]::Failed }
        $this.Devices | ForEach-Object { $_.Status = $this.Status }
        $this.Devices | Where-Object { $_.State -eq [DeviceState]::Disabled} | ForEach-Object { $_.Status = "Disabled (ExcludeDeviceName: '$($_.Name)')" }

        # Log switching information to .\Logs\SwitchingLog
        [PSCustomObject]@{ 
            DateTime          = (Get-Date -Format o)
            Action            = If ($this.Status -eq [MinerStatus]::Idle) { "Stopped" } Else { "Failed" }
            Name              = $this.Name
            Device            = ($this.Devices.Name | Sort-Object) -join "; "
            Type              = $this.Type
            Account           = ($this.WorkersRunning.Pool.User | ForEach-Object { $_ -split "\." | Select-Object -First 1 } | Select-Object -Unique) -join "; "
            Pool              = ($this.WorkersRunning.Pool.Name | Select-Object -Unique) -join "; "
            Algorithm         = $this.WorkersRunning.Pool.Algorithm -join "; "
            Duration          = "{0:hh\:mm\:ss}" -f ($this.EndTime - $this.BeginTime)
            Earning           = $this.Earning
            Earning_Bias      = $this.Earning_Bias
            Profit            = $this.Profit
            Profit_Bias       = $this.Profit_Bias
            CommandLine       = ""
            Benchmark         = $this.Benchmark
            MeasurePowerUsage = $this.MeasurePowerUsage
            Reason            = If ($this.Status -eq [MinerStatus]::Failed) { $this.StatusMessage } Else { "" }
            LastDataSample    = $this.Data | Select-Object -Last 1 | ConvertTo-Json -Compress
        } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation -ErrorAction Ignore

        $this.StatusMessage = If ($this.Status -eq [MinerStatus]::Idle) { "Idle" } Else { "Failed $($this.Info)" }
    }

    [DateTime]GetActiveLast() { 
        If ($this.BeginTime -and $this.EndTime) { 
            Return $this.EndTime.ToUniversalTime()
        }
        ElseIf ($this.BeginTime) { 
            Return [DateTime]::Now.ToUniversalTime()
        }
        Else { 
            Return [DateTime]::MinValue.ToUniversalTime()
        }
    }

    [TimeSpan]GetActiveTime() { 
        If ($this.BeginTime -and $this.EndTime) { 
            Return $this.Active + $this.EndTime - $this.BeginTime
        }
        ElseIf ($this.BeginTime) { 
            Return $this.Active + ((Get-Date) - $this.BeginTime)
        }
        Else { 
            Return $this.Active
        }
    }

    [Double]GetPowerUsage() { 
        [Device]$Device = $null
        $RegistryData = [PSCustomObject]@{ }
        $RegistryEntry = [PSCustomObject]@{ }
        $RegistryHive = "HKCU:\Software\HWiNFO64\VSB"
        $TotalPowerUsage = [Double]0

        # Read power usage
        $RegistryData = Get-ItemProperty $RegistryHive -ErrorAction Ignore
        ForEach ($Device in $this.Devices) { 
            If ($RegistryEntry = $RegistryData.PSObject.Properties | Where-Object { ($_.Value -split " ") -contains $Device.Name }) { 
                $TotalPowerUsage += [Double]($RegistryData.($RegistryEntry.Name -replace "Label", "Value") -split ' ' | Select-Object -First 1)
            }
            Else { 
                $TotalPowerUsage += [Double]$Device.ConfiguredPowerUsage # Use configured value
            }
        }
        Return $TotalPowerUsage
    }

    [Double[]]CollectHashrate([String]$Algorithm = [String]$this.Algorithm, [Boolean]$Safe = $this.Benchmark) { 
        # Returns an array of two values (safe, unsafe)
        $Hashrate_Average = [Double]0
        $Hashrate_Variance = [Double]0

        $Hashrate_Samples = @($this.Data | Where-Object { $_.Hashrate.$Algorithm }) # Do not use 0 valued samples

        $Hashrate_Average = ($Hashrate_Samples.Hashrate.$Algorithm | Measure-Object -Average).Average
        $Hashrate_Variance = $Hashrate_Samples.Hashrate.$Algorithm | Measure-Object -Average -Minimum -Maximum | ForEach-Object { If ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } }

        If ($Safe) { 
            If ($Hashrate_Samples.Count -lt 3 -or $Hashrate_Variance -gt 0.1) { 
                Return @(0, $Hashrate_Average)
            }
            Else { 
                Return @(($Hashrate_Average * (1 + $Hashrate_Variance / 2)), $Hashrate_Average)
            }
        }
        Else { 
            Return @($Hashrate_Average, $Hashrate_Average)
        }
    }

    [Double[]]CollectPowerUsage([Boolean]$Safe = $this.MeasurePowerUsage) { 
        # Returns an array of two values (safe, unsafe)
        $PowerUsage_Average = [Double]0
        $PowerUsage_Variance = [Double]0

        $PowerUsage_Samples = @($this.Data | Where-Object PowerUsage) # Do not use 0 valued samples

        $PowerUsage_Average = ($PowerUsage_Samples.PowerUsage | Measure-Object -Average).Average
        $PowerUsage_Variance = $PowerUsage_Samples.PowerUsage | Measure-Object -Average -Minimum -Maximum | ForEach-Object { If ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } }

        If ($Safe) { 
            If ($PowerUsage_Samples.Count -lt 3 -or $PowerUsage_Variance -gt 0.1) { 
                Return @(0, $PowerUsage_Average)
            }
            Else { 
                Return @(($PowerUsage_Average * (1 + $PowerUsage_Variance / 2)), $PowerUsage_Average)
            }
        }
        Else { 
            Return @($PowerUsage_Average, $PowerUsage_Average)
        }
    }

    Refresh([Double]$PowerCostBTCperW, [Boolean]$CalculatePowerCost) { 
        $this.Reason = @()
        $this.Available = $true
        $this.Best = $false
        $this.Disabled = $false

        $this.Benchmark = $false

        $this.Earning = 0
        $this.Earning_Bias = 0
        $this.Earning_Accuracy = 0

        $this.MeasurePowerUsage = $false
        $this.Prioritize = $false

        $this.PowerUsage = [Double]::NaN
        $this.PowerCost = [Double]::NaN
        $this.Profit = [Double]::NaN
        $this.Profit_Bias = [Double]::NaN

        $this.Workers | ForEach-Object { 
            If ($Stat = Get-Stat "$($this.Name)_$($_.Pool.Algorithm)_Hashrate") { 
                $_.Speed = $Stat.Hour
                $Factor = [Double]($_.Speed * (1 - $_.Fee) * (1 - $_.Pool.Fee))
                $_.Earning = [Double]($_.Pool.Price * $Factor)
                $_.Earning_Bias = [Double]($_.Pool.Price_Bias * $Factor)
                $_.Earning_Accuracy = [Double]$_.Pool.Accuracy
                $_.TotalMiningDuration = $Stat.Duration
                $_.Disabled = $Stat.Disabled
                $this.Earning += $_.Earning
                $this.Earning_Bias += $_.Earning_Bias
            }
            Else { 
                $_.Disabled = $false
                $_.Speed = [Double]::NaN
            }
            If ($_.Pool.Reason -contains "Prioritized by BalancesKeepAlive") { $this.Prioritize = $true }
        }

        If ($this.Workers | Where-Object Disabled) { 
            $this.Status = [MinerStatus]::Disabled
            $this.Available = $false
            $this.Disabled = $true
        }
        ElseIf ($this.Workers | Where-Object { [Double]::IsNaN($_.Speed) }) { 
            $this.Benchmark = $true
            $this.Earning = [Double]::NaN
            $this.Earning_Bias = [Double]::NaN
            $this.Earning_Accuracy = [Double]::NaN
        }
        ElseIf ($this.Workers[0].Speed -EQ 0) { # Allow 0 hashrate on secondary algorithm
            $this.Status = [MinerStatus]::Failed
            $this.Available = $false
            $this.Disabled = $false
            $this.Earning = [Double]::NaN
            $this.Earning_Bias = [Double]::NaN
            $this.Earning_Accuracy = [Double]::NaN
        }
        Else { $this.Workers | ForEach-Object { $this.Earning_Accuracy += (($_.Earning_Accuracy * $_.Earning) / $this.Earning) } }
        If ($this.Earning -eq 0) { $this.Earning_Accuracy = 0 }

        $this.TotalMiningDuration = ($this.Workers.TotalMiningDuration | Measure-Object -Minimum).Minimum

        If ($CalculatePowerCost) { 
            If ($Stat = Get-Stat "$($this.Name)$(If ($this.Workers.Count -eq 1) { "_$($this.Workers.Pool.Algorithm | Select-Object -First 1)" })_PowerUsage") { 
                $this.PowerUsage = $Stat.Week
                $this.PowerCost = $this.PowerUsage * $PowerCostBTCperW
                $this.Profit = $this.Earning - $this.PowerCost
                $this.Profit_Bias = $this.Earning_Bias - $this.PowerCost
            }
            Else { 
                $this.MeasurePowerUsage = $true
            }
        }
    }
}
Function Start-IdleDetection { 

    # Function tracks how long the system has been idle and controls the paused state
    $IdleRunspace = [runspacefactory]::CreateRunspace()
    $IdleRunspace.Open()
    $IdleRunspace.SessionStateProxy.SetVariable('Config', $Config)
    $IdleRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
    $IdleRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

    $Variables.IdleRunspace = $IdleRunspace

    $PowerShell = [PowerShell]::Create()
    $PowerShell.Runspace = $IdleRunspace
    $PowerShell.AddScript(
        { 
            # Set the starting directory
            Set-Location (Split-Path $MyInvocation.MyCommand.Path)

            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script
            
            $Variables.IdleRunspace | Add-Member NewMiningStatus "Idle" -Force

            # No native way to check how long the system has been idle in PowerShell. Have to use .NET code.
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

            $ProgressPreference = "SilentlyContinue"
            $IdleSeconds = [Math]::Round(([PInvoke.Win32.UserInput]::IdleTime).TotalSeconds)

            Write-Message -Level Verbose "Started idle detection.$(If ($IdleSeconds -le $Config.IdleSec) { " $($Variables.CurrentProduct) will start mining when the system is idle for more than $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" })..." })"

            While ($true) { 
                $IdleSeconds = [Math]::Round(([PInvoke.Win32.UserInput]::IdleTime).TotalSeconds)

                # Activity detected, pause mining
                If ($IdleSeconds -lt $Config.IdleSec -and $Variables.IdleRunspace.NewMiningStatus -ne "Idle") { 
                    $Variables.IdleRunspace | Add-Member NewMiningStatus "Idle" -Force

                    $LabelMiningStatus.Text = "Idle | $($Variables.CurrentProduct) $($Variables.CurrentVersion)"
                    $LabelMiningStatus.ForeColor = [System.Drawing.Color]::Green
                }

                # System has been idle long enough, start mining
                If ($IdleSeconds -ge $Config.IdleSec -and $Variables.IdleRunspace.NewMiningStatus -ne "Mining") { 
                    $Variables.IdleRunspace | Add-Member NewMiningStatus "Mining" -Force

                    $LabelMiningStatus.Text = "Running | $($Variables.CurrentProduct) $($Variables.CurrentVersion)"
                    $LabelMiningStatus.ForeColor = [System.Drawing.Color]::Green
                }
                Start-Sleep -Seconds 1
            }
        }
    ) | Out-Null
    $PowerShell.BeginInvoke()

    $Variables.IdleRunspace | Add-Member -Force @{ PowerShell = $PowerShell }
}

Function Stop-IdleDetection { 

    If ($Variables.IdleRunspace) { 
        $Variables.IdleRunspace.Close()
        If ($Variables.IdleRunspace.PowerShell) { $Variables.IdleRunspace.PowerShell.Dispose() }
        $Variables.Remove("IdleRunspace")
        Write-Message -Level Verbose "Stopped idle detection."
    }
}

Function Start-Mining { 

    If (-not $Variables.CoreRunspace) { 
        $Variables.Summary = "Starting mining processes..."
        Write-Message -Level Info $Variables.Summary

        $Variables.Timer = $null
        $Variables.LastDonated = (Get-Date).AddDays(-1).AddHours(1)
        $Variables.Pools = $null
        $Variables.Miners = $null

        $CoreRunspace = [RunspaceFactory]::CreateRunspace()
        $CoreRunspace.Open()
        $CoreRunspace.SessionStateProxy.SetVariable('Config', $Config)
        $CoreRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
        $CoreRunspace.SessionStateProxy.SetVariable('Stats', $Stats)
        $CoreRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

        $Variables.CoreRunspace = $CoreRunspace

        $PowerShell = [PowerShell]::Create()
        $PowerShell.Runspace = $CoreRunspace
        $PowerShell.AddScript("$($Variables.MainPath)\Includes\Core.ps1")
        $PowerShell.BeginInvoke()

        $Variables.CoreRunspace | Add-Member -Force @{ PowerShell = $PowerShell }

        $Variables.Summary = "Mining processes are running."
        Write-Host $Variables.Summary
    }
}

Function Stop-Mining { 

    If ($Variables.CoreRunspace) { 

        If ($Variables.MiningStatus -eq "Running") { Write-Message -Level Info "Exiting cycle." }

        Stop-MiningProcess

        $Variables.CoreRunspace.Close()
        If ($Variables.CoreRunspace.PowerShell) { $Variables.CoreRunspace.PowerShell.Dispose() }
        $Variables.Remove("Timer")
        $Variables.Remove("CoreRunspace")

        $Variables.Summary = "Mining processes stopped."
        Write-Host $Variables.Summary
    }
}

Function Stop-MiningProcess { 

    If ($Variables.Miners | Where-Object ProcessID) { 
        $Variables.Summary = "Stopping mining processes..."
        Write-Message -Level Info $Variables.Summary

        # Give core loop time to shut down gracefully
        $Timestamp = (Get-Date).AddSeconds(30)
        While (($Variables.CoreRunspace.MiningStatus -eq "Running" -and -not $Variables.IdleRunspace) -and (Get-Date) -le $Timestamp) { 
            Start-Sleep -Seconds 1
        }
        $Variables.Miners | Where-Object ProcessID | ForEach-Object { 
            $_.Info = ""
            $_.Best = $false
            $_.SetStatus([MinerStatus]::Idle)
        }
        $Variables.WatchdogTimers = @()
    }
}

Function Start-BrainJob { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Jobs
    )

    # Starts Brains if necessary
    $JobNames = @()

    $Jobs | ForEach-Object { 
        If (-not $Variables.BrainJobs.$_) { 
            $BrainPath = "$($Variables.MainPath)\Brains\$(Get-PoolBaseName $_)"
            $BrainName = "$BrainPath\Brains.ps1"
            If (Test-Path $BrainName -PathType Leaf) { 
                $Variables.BrainJobs.$_ = Start-ThreadJob -Name "BrainJob_$($_)" -ThrottleLimit 99 -FilePath $BrainName -ArgumentList @($BrainPath, $_)
                $JobNames += $_
            }
        }
    }
    If ($JobNames.Count -gt 0) { Write-Message -Level Verbose "Pool Brain Job$(If ($JobNames.Count -gt 1) { "s" }) for '$(($JobNames | Sort-Object) -join ", ")' running." }
}

Function Stop-BrainJob { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Jobs = $Variables.BrainJobs.Keys
    )

    If ($Jobs) { 
        $JobNames = @()

        # Stop Brains if necessary
        $Jobs | ForEach-Object { 
            $Variables.BrainJobs.$_ | Stop-Job -PassThru -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore
            $Variables.BrainJobs.Remove($_)
            $JobNames += $_
        }

        If ($JobNames.Count -gt 0) { Write-Message -Level Verbose  "Pool Brain Job$(If ($JobNames.Count -gt 1) { "s" }) for '$(($JobNames | Sort-Object) -join ", ")' stopped." }
    }
}

Function Start-BalancesTracker { 

    If (-not $Variables.BalancesTrackerRunspace) { 

        Try { 
            $Variables.Summary = "Starting Balances Tracker..."
            Write-Message -Level Info $Variables.Summary

            $BalancesTrackerRunspace = [runspacefactory]::CreateRunspace()
            $BalancesTrackerRunspace.Open()
            $BalancesTrackerRunspace.SessionStateProxy.SetVariable('Config', $Config)
            $BalancesTrackerRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
            $BalancesTrackerRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $BalancesTrackerRunspace
            $PowerShell.AddScript("$($Variables.MainPath)\Includes\BalancesTracker.ps1")
            $PowerShell.BeginInvoke()

            $Variables.BalancesTrackerRunspace = $BalancesTrackerRunspace
            $Variables.BalancesTrackerRunspace | Add-Member -Force @{ PowerShell = $PowerShell }

            Write-Host "Balances Tracker is running."
        }
        Catch { 
            Write-Message -Level Error "Failed to start Balances Tracker [$Error[0]]."
        }
    }
}

Function Stop-BalancesTracker { 

    If ($Variables.BalancesTrackerRunspace) { 
        $Variables.Summary += "\nStopping Balances Tracker..."
        Write-Message -Level Info "Stopping Balances Tracker..."

        $Variables.BalancesTrackerRunspace.Close()
        If ($Variables.BalancesTrackerRunspace.PowerShell) { $Variables.BalancesTrackerRunspace.PowerShell.Dispose() }

        $Variables.Remove("BalancesTrackerRunspace")
    }
}

Function Initialize-Application { 

    # Keep only the last 10 files
    Get-ChildItem -Path ".\Logs\$($Variables.CurrentProduct)_*.log" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path ".\Logs\SwitchingLog_*.csv" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path "$($Variables.ConfigFile)_*.backup" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse

    $Variables.ScriptStartDate = (Get-Date).ToUniversalTime()
    If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12 }

    # Set process priority to BelowNormal to avoid hash rate drops on systems with weak CPUs
    (Get-Process -Id $PID).PriorityClass = "BelowNormal"

    If ($Config.Proxy -eq "") { $PSDefaultParameterValues.Remove("*:Proxy") }
    Else { $PSDefaultParameterValues["*:Proxy"] = $Config.Proxy }
}

Function Get-DefaultAlgorithm { 

    # Try { 
    #     $PoolsAlgos = (Invoke-WebRequest -Uri "https://nemosminer.com/data/PoolsAlgos.json" -TimeoutSec 15 -UseBasicParsing -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" }).Content | ConvertFrom-Json
    #     $PoolsAlgos | ConvertTo-Json | Out-File -FilePath ".\Config\PoolsAlgos.json" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    # }
    # Catch { 
        If (Test-Path -Path ".\Config\PoolsAlgos.json" -PathType Leaf) { 
            $PoolsAlgos = Get-Content ".\Config\PoolsAlgos.json" | ConvertFrom-Json -ErrorAction Ignore
        }
    # }
    If ($PoolsAlgos = $PoolsAlgos.PSObject.Properties | Where-Object Name -in @(Get-PoolBaseName $Config.PoolName)) { Return $PoolsAlgos.Value | Sort-Object -Unique }
    Return
}

Function Get-CommandLineParameters { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Arguments
    )

    If (Test-Json $Arguments -ErrorAction Ignore) { Return ($Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue).Arguments }
    Return $Arguments
}

Function Get-Rate { 
    # Read exchange rates from min-api.cryptocompare.com, use cached data as fallback

    $RatesFile = "Data\Rates.json"

    Try { 
        If ($Rates = Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$((@("BTC") + @($Variables.AllCurrencies | Where-Object { $_ -ne "mBTC" }) | Select-Object -Unique) -join ',')&extraParams=http://nemosminer.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json) { 
            $Currencies = ($Rates.BTC | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name
            $Currencies | Where-Object { $_ -ne "BTC" } | ForEach-Object { 
                $Currency = $_
                $Rates | Add-Member $Currency ($Rates.BTC | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json) -ErrorAction Ignore
                ($Rates.$Currency | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name | ForEach-Object { 
                    $Rates.$Currency | Add-Member $_ ([Double]$Rates.BTC.$_ / $Rates.BTC.$Currency) -Force
                }
            }
            # Add mBTC
            $Currencies | ForEach-Object { 
                $Currency = $_
                $mCurrency = "m$($Currency)"
                $Rates | Add-Member $mCurrency ($Rates.$Currency | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json)
                ($Rates.$mCurrency | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name | ForEach-Object { 
                    $Rates.$mCurrency | Add-Member $_ ([Double]$Rates.$Currency.$_ / 1000) -Force
                }
            }
            ($Rates | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name | ForEach-Object { 
                $Currency = $_
                ($Rates | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name | Where-Object { $_ -in $Currencies } | ForEach-Object { 
                    $mCurrency = "m$($_)"
                    $Rates.$Currency | Add-Member $mCurrency ([Double]$Rates.$Currency.$_ * 1000)
                }
            }
            Write-Message "Loaded currency exchange rates from 'min-api.cryptocompare.com'."
            $Rates | ConvertTo-Json -Depth 5 | Out-File -FilePath $RatesFile -Encoding utf8NoBOM -Force -ErrorAction SilentlyContinue
            $Variables.Rates = $Rates
            $Variables.RatesUpdated = (Get-Date).ToUniversalTime()
        }
        Else { 
            If (Test-Path -Path $RatesFile) { 
                $Variables.Rates = (Get-Content -Path $RatesFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
                $Variables.Updated = "Cached: $((Get-Item -Path $RatesFile).CreationTime.ToUniversalTime())"
                Write-Message -Level Warn "Could not load exchange rates from CryptoCompare. Using cached data from $((Get-Item -Path $RatesFile).CreationTime)."
            }
            Else { 
                Write-Message -Level Warn "Could not load exchange rates from CryptoCompare."
            }
        }
    }
    Catch { 
        If (Test-Path -Path $RatesFile) { 
            $Variables.Rates = (Get-Content -Path $RatesFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
            $Variables.Updated = "Cached: $((Get-Item -Path $RatesFile).CreationTime.ToUniversalTime())"
            Write-Message -Level Warn "Could not load exchange rates from CryptoCompare. Using cached data from $((Get-Item -Path $RatesFile).CreationTime)."
        }
        Else { 
            Write-Message -Level Warn "Could not load exchange rates from CryptoCompare."
        }
    }
}

Function Write-Message { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Message, 
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info", "Verbose", "Debug")]
        [String]$Level = "Info", 
        [Parameter(Mandatory = $false)]
        [Switch]$Console = $false
    )

    If ($Level -in $Config.LogToScreen) { 
        # Update status text box in GUI
        If ($Variables.LabelStatus) { 
            $Variables.LabelStatus.Lines += $Message

            # Keep only 100 lines, more lines impact performance
            $Variables.LabelStatus.Lines = @($Variables.LabelStatus.Lines | Select-Object -Last 100)

            $Variables.LabelStatus.SelectionStart = $Variables.LabelStatus.TextLength
            $Variables.LabelStatus.ScrollToCaret()
            $Variables.LabelStatus.Refresh()
        }

        # Write to console
        Switch ($Level) { 
            "Error"   { Write-Host $Message -ForegroundColor "Red" }
            "Warn"    { Write-Host $Message -ForegroundColor "Magenta" }
            "Info"    { Write-Host $Message -ForegroundColor "White" }
            "Verbose" { Write-Host $Message -ForegroundColor "Yello" }
            "Debug"   { Write-Host $Message -ForegroundColor "Blue" }
        }
    }

    If ($Variables.LogFile -and $Config.LogToFile -and $Level -in $Config.LogToFile) { 
        # Get mutex named $($Variables.CurrentProduct)WriteLog. Mutexes are shared across all threads and processes. 
        # This lets us ensure only one thread is trying to write to the file at a time. 
        $Mutex = New-Object System.Threading.Mutex($false, "$($Variables.CurrentProduct)WriteMessage")

        # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, write to the log file and release mutex. Otherwise, display an error. 
        If ($Mutex.WaitOne(1000)) { 

            $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

            "$Date $($Level.ToUpper()): $Message" | Out-File -FilePath $Variables.LogFile -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            $Mutex.ReleaseMutex()
        }
        Else { 
            Write-Error -Message "Log file is locked, unable to write message to $($Variables.LogFile)."
        }
    }
}

Function Send-MonitoringData { 

    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip If server and user aren't filled out
    If (-not $Config.MonitoringServer) { Return }
    If (-not $Config.MonitoringUser) { Return }

    $Version = "$($Variables.CurrentProduct) $($Variables.CurrentVersion.ToString())"
    $Status = $Variables.NewMiningStatus
    $RunningMiners = $Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running }

    # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
    # reveal someone's windows username or other system information they might not want sent
    # For the ones that can be an array, comma separate them
    $Data = @(
        $RunningMiners | Sort-Object DeviceName | ForEach-Object { 
            [PSCustomObject]@{ 
                Name           = $_.Name
                Path           = Resolve-Path -Relative $_.Path
                Type           = $_.Type -join ','
                Algorithm      = $_.Algorithm -join ','
                Pool           = $_.WorkersRunning.Pool.Name -join ','
                CurrentSpeed   = $_.Speed_Live
                EstimatedSpeed = $_.Workers.Speed
                Earning        = $_.Earning
                Profit         = $_.Profit
                Currency       = $Config.Currency
            }
        }
    )

    $Body = @{ 
        user    = $Config.MonitoringUser
        worker  = $Config.WorkerName
        version = $Version
        status  = $Status
        profit  = [String][Math]::Round(($data | Measure-Object Earning -Sum).Sum, 8) # Earnings is NOT profit! Needs to be changed in mining monitor server
        data    = ConvertTo-Json $Data
    }

    # Send the request
    Try { 
        $Response = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/report.php" -Method Post -Body $Body -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        If ($Response -eq "Success") { 
            Write-Message -Level Verbose "Reported worker status to monitoring server '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
        Else { 
            Write-Message -Level Verbose "Reporting worker status to monitoring server '$($Config.MonitoringServer)' failed: [$($Response)]."
        }
    }
    Catch { 
        Write-Message -Level Warn "Monitoring: Unable to send status to '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
    }
}

Function Receive-MonitoringData { 

    If ($Config.ShowWorkerStatus -and $Config.MonitoringUser -and $Config.MonitoringServer) { 
        Try { 
            $Workers = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/workers.php" -Method Post -Body @{ user = $Config.MonitoringUser } -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            # Calculate some additional properties and format others
            $Workers | ForEach-Object { 
                # Convert the unix timestamp to a datetime object, taking into account the local time zone
                $_ | Add-Member -Force @{ date = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.lastseen)) }

                # If a machine hasn't reported in for > 10 minutes, mark it as offline
                $TimeSinceLastReport = New-TimeSpan -Start $_.date -End (Get-Date)
                If ($TimeSinceLastReport.TotalMinutes -gt 10) { $_.status = "Offline" }
            }
            $Variables | Add-Member -Force @{ Workers = $Workers }
            $Variables | Add-Member -Force @{ WorkersLastUpdated = (Get-Date) }

            Remove-Variable Workers

            Write-Message -Level Verbose "Retrieved worker status from '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
        Catch { 
            Write-Message -Level Warn "Monitoring: Unable to retrieve worker data from '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
    }
}

Function Merge-Hashtable { 
    Param(
        [Parameter(Mandatory = $true)]
        [Hashtable]$HT1, 
        [Parameter(Mandatory = $true)]
        [Hashtable]$HT2, 
        [Parameter(Mandatory = $false)]
        [Boolean]$Unique = $false, 
        [Parameter(Mandatory = $false)]
        [String[]]$Replace = @() # Replace, not merge property
    )

    $HT2.Keys | ForEach-Object { 
        If ($HT1.$_ -is [Hashtable]) { 
            $HT1.$_ = Merge-Hashtable -HT1 $HT1.$_ -Ht2 $HT2.$_ -Unique $Unique -replace $Replace
        }
        ElseIf ($HT1.$_ -is [Array] -and $_ -notin $NoMerge) { 
            $HT1.$_ += $HT2.$_
            If ($Unique) { $HT1.$_ = $HT1.$_ | Sort-Object -Unique }
        }
        ElseIf ($HT2.$_) { 
            $HT1.$_ = $HT2.$_
        }
    }
    $HT1
}

Function Get-DonationPoolConfig { 
    # Randomize donation data
    # Build pool config with available donation data, not all devs have the same set of wallets available

    $Variables.DonateRandom = $Variables.DonationData | Get-Random
    $Variables.DonatePoolsConfig = [Ordered]@{ }
    (Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique | ForEach-Object { 
        $PoolConfig = @{ }
        $PoolConfig.EarningsAdjustmentFactor = 1
        $PoolConfig.Region = $Config.PoolsConfig.$_.Region
        $PoolConfig.WorkerName = "$($Variables.CurrentProduct)-$($Variables.CurrentVersion.ToString())-donate$($Config.Donate)"
        Switch -regex ($_) { 
            "^MiningPoolHub$|^ProHashing$" { 
                If ($Variables.DonateRandom."$($_)UserName") { # not all devs have a known ProHashing account
                    $PoolConfig.UserName = $Variables.DonateRandom."$($_)UserName"
                    $PoolConfig.Variant = $Config.PoolsConfig.$_.Variant
                    $Variables.DonatePoolsConfig.$_ = $PoolConfig
                }
                Break
            }
            Default { 
                If ($Variables.DonateRandom.Wallets) { 
                    # not all devs have a known ETC or ETH address
                    If ($Config.PoolName -match $_ -and (Compare-Object @($Variables.PoolData.$_.GuaranteedPayoutCurrencies) @($Variables.DonateRandom.Wallets.PSObject.Properties.Name) -IncludeEqual -ExcludeDifferent)) { 
                        $PoolConfig.Variant = If ($Config.PoolsConfig.$_.Variant) { $Config.PoolsConfig.$_.Variant } Else { $Config.PoolName -match $_ }
                        $PoolConfig.Wallets = $Variables.DonateRandom.Wallets | ConvertTo-Json | ConvertFrom-Json -AsHashtable
                        $Variables.DonatePoolsConfig.$_ = $PoolConfig
                    }
                }
                Break
            }
        }
    }
}

Function Read-Config { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    # Load the configuration
    If (Test-Path -PathType Leaf $ConfigFile) { 
        $Config_Tmp = Get-Content $ConfigFile | ConvertFrom-Json -ErrorAction Ignore | Select-Object
        If ($Config_Tmp.PSObject.Properties.Count -eq 0 -or $Config_Tmp -isnot [PSCustomObject]) { 
            Copy-Item -Path $ConfigFile "$($ConfigFile).corrupt" -Force
            Write-Message -Level Warn "Configuration file '$($ConfigFile)' is corrupt."
            $Config.ConfigFileVersionCompatibility = $null
        }
        Else { 
            # Fix upper / lower case (Web GUI is case sensitive)
            $Config_Tmp.PSObject.Properties.Name | ForEach-Object { 
                $Config.Remove($_)
                $Config.$_ = $Config_Tmp.$_ 
            }
        }
        Remove-Variable Config_Tmp
    }
    Else { 
        Write-Message -Level Warn "No valid configuration file found."

        $Variables.FreshConfig = $true
        If (Test-Path -Path ".\Data\PoolsConfig-Recommended.json" -PathType Leaf) { 
            # Add default enabled pools
            $Temp = (Get-Content ".\Data\PoolsConfig-Recommended.json" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore)
            $Config.PoolName = $Temp.PSObject.Properties.Name | Where-Object { $_ -ne "Default" } | ForEach-Object { $Temp.$_.Variant.PSObject.Properties.Name }
            Remove-Variable Temp
        }

        # Add config items
        $Variables.AllCommandLineParameters.Keys | Where-Object { $_ -notin $Config.Keys } | Sort-Object | ForEach-Object { 
            $Value = $Variables.AllCommandLineParameters.$_
            If ($Value -is [Switch]) { $Value = [Boolean]$Value }
            $Config.$_ = $Value
        }

        # MinerInstancePerDeviceModel: Default to $true if more than one device model per vendor
        $Config.MinerInstancePerDeviceModel = ($Variables.Devices | Group-Object Vendor  | ForEach-Object { ($_.Group.Model | Sort-Object -Unique).Count } | Measure-Object -Maximum).Maximum -gt 1

        $Config.ConfigFileVersion = $Variables.CurrentVersion.ToString()
    }

    # Ensure parameter format
    $Variables.AllCommandLineParameters.Keys | ForEach-Object { 
        If ($Variables.AllCommandLineParameters.$_ -is [Array] -and $Config.$_ -isnot [Array]) { $Config.$_ = @($Config.$_ -replace " " -split ",") } # Enforce array
    }

    $DefaultPoolData = $Variables.PoolData

    # Build custom pools configuration, create case insensitive hashtable (https://stackoverflow.com/questions/24054147/powershell-hash-tables-double-key-error-a-and-a)
    If ($Variables.PoolsConfigFile -and (Test-Path -PathType Leaf $Variables.PoolsConfigFile)) { 
        $CustomPoolsConfig = [Ordered]@{ }
        Try { 
            $Temp = (Get-Content $Variables.PoolsConfigFile -ErrorAction Ignore | ConvertFrom-Json -NoEnumerate -AsHashTable -ErrorAction Ignore)
            $Temp.Keys | Sort-Object | ForEach-Object { $CustomPoolsConfig += @{ $_ = $Temp.$_ } }
            $Variables.PoolsConfigData = $CustomPoolsConfig
        }
        Catch { 
            Write-Message -Level Warn "Pools configuration file '$($Variables.PoolsConfigFile)' is corrupt and will be ignored."
        }
    }

    # Build in memory pool config
    $PoolsConfig = [Ordered]@{ }
    (Get-PoolBasename $Config.PoolName) -replace " Internal$| External$" | ForEach-Object { 
        $PoolName = $_
        If ($PoolConfig = $DefaultPoolData.$PoolName) { 
            # Merge default pool data with custom pool config
            If ($CustomPoolConfig = $CustomPoolsConfig.$PoolName) { $PoolConfig = Merge-Hashtable -HT1 $PoolConfig -HT2 $CustomPoolConfig -Unique $true }

            If (-not $PoolConfig.EarningsAdjustmentFactor) { $PoolConfig.EarningsAdjustmentFactor = $Config.EarningsAdjustmentFactor }
            If (-not $PoolConfig.WorkerName) { $PoolConfig.WorkerName = $Config.WorkerName }
            If (-not $PoolConfig.BalancesKeepAlive) { $PoolConfig.BalancesKeepAlive = $PoolData.$PoolName.BalancesKeepAlive }

            Switch ($PoolName) { 
                "HiveON" { 
                    If (-not $PoolConfig.Wallets) { 
                        $PoolConfig.Wallets = [PSCustomObject]@{ }
                        ($Config.Wallets | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name | Where-Object { $_ -in $PoolConfig.PayoutCurrencies } | ForEach-Object { 
                            $PoolConfig.Wallets | Add-Member $_ ($Config.Wallets.$_)
                        }
                    }
                }
                "MiningPoolHub" { 
                    If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $Config.MiningPoolHubUserName }
                }
                "NiceHash" { 
                    If (-not $PoolConfig.Variant."Nicehash Internal".Wallets.BTC) { 
                        If ($Config.NiceHashWallet -and $Config.NiceHashWalletIsInternal) { $PoolConfig.Variant."NiceHash Internal".Wallets = @{ "BTC" = $Config.NiceHashWallet } }
                    }
                    If (-not $PoolConfig.Variant."Nicehash External".Wallets.BTC) { 
                        If ($Config.NiceHashWallet -and -not $Config.NiceHashWalletIsInternal) { $PoolConfig.Variant."NiceHash External".Wallets = @{ "BTC" = $Config.NiceHashWallet } }
                        ElseIf ($Config.Wallets.BTC) { $PoolConfig.Variant."NiceHash External".Wallets = @{ "BTC" = $Config.Wallets.BTC } }
                    }
                }
                "ProHashing" { 
                    If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $Config.ProHashingUserName }
                    If (-not $PoolConfig.MiningMode) { $PoolConfig.MiningMode = $Config.ProHashingMiningMode }
                }
                Default { 
                    If ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $Config.PayoutCurrency }
                    If (-not $PoolConfig.Wallets) { $PoolConfig.Wallets = @{ "$($PoolConfig.PayoutCurrency)" = $($Config.Wallets.($PoolConfig.PayoutCurrency)) } }
                    $PoolConfig.Remove("PayoutCurrency")
                }
            }
            If ($PoolConfig.EarningsAdjustmentFactor -le 0 -or $PoolConfig.EarningsAdjustmentFactor -gt 1) { $PoolConfig.EarningsAdjustmentFactor = 1 }
            If ($PoolConfig.Algorithm) { $PoolConfig.Algorithm = @($PoolConfig.Algorithm -replace " " -split ",") }
        }
        $PoolsConfig.$PoolName = $PoolConfig
    }
    $Config.PoolsConfig = $PoolsConfig
}

Function Write-Config { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile, 
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$NewConfig = $Config
    )

    $Header = 
"// This file was initially generated by $($Variables.CurrentProduct)
// It should still be usable in newer versions, but newer versions might have additional
// settings or changes

// $($Variables.CurrentProduct) will automatically add / convert / rename / update new settings when updating to a new version
"
    If (Test-Path $ConfigFile -PathType Leaf) { 
        Copy-Item -Path $ConfigFile -Destination "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
        Get-ChildItem -Path "$($ConfigFile)_*.backup" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
    }

    $SortedConfig = $NewConfig | Get-SortedObject
    $ConfigTmp = [Ordered]@{ }
    $SortedConfig.Keys | Where-Object { $_ -notin @("ConfigFile", "PoolsConfig") } | ForEach-Object { 
        $ConfigTmp[$_] = $SortedConfig.$_
    }
    "$Header$($ConfigTmp | ConvertTo-Json -Depth 10)" | Out-File -FilePath $ConfigFile -Force -Encoding utf8NoBOM -ErrorAction Ignore
}
Function Edit-File { 

    # Opens file in notepad. Notepad will remain in foreground until notepad is closed.

    Param(
        [Parameter(Mandatory = $false)]
        [String]$FileName
    )

    If ($FileWriteTime = (Get-Item -Path $FileName -ErrorAction Ignore).LastWriteTime) { 
        If (-not ($NotepadProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -Like "*\Notepad.exe* $($FileName)"))) { 
            Notepad.exe $FileName
        }
        If ($NotepadProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -Like "*\Notepad.exe* $($FileName)")) { 
            # Check if the window is not already in foreground
            While ($NotepadProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -Like "*\Notepad.exe* $($FileName)")) { 
                $FGWindowPid  = [IntPtr]::Zero
                [Void][Win32]::GetWindowThreadProcessId([Win32]::GetForegroundWindow(), [ref]$FGWindowPid)
                $MainWindowHandle = (Get-Process -Id $NotepadProcess.ProcessId).MainWindowHandle
                If ($NotepadProcess.ProcessId -ne $FGWindowPid) {
                    If ([Win32]::GetForegroundWindow() -ne $MainWindowHandle) { 
                        [Void][Win32]::ShowWindowAsync($MainWindowHandle, 6) # SW_MINIMIZE 
                        [Void][Win32]::ShowWindowAsync($MainWindowHandle, 9) # SW_RESTORE
                    }
                }
                Start-Sleep -MilliSeconds 100
            }
        }

        If ($FileWriteTime -ne (Get-Item -Path $FileName -ErrorAction Ignore).LastWriteTime) { 
            Write-Message -Level Verbose "Saved '$(($FileName))'. Changes will become active in next cycle."
            Return "Saved '$(($FileName))'`nChanges will become active in next cycle."
        }
        Else { 
            Return "No changes to '$(($FileName))' made."
        }
    }
    Return "Cannot locate config file '$(($FileName))'."
}

Function Get-SortedObject { 

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Object]$Object
    )

    $Object = $Object | ConvertTo-Json -Depth 20 | ConvertFrom-Json -NoEnumerate -ErrorAction Ignore

    # Build an ordered hashtable of the property-value pairs.
    $SortedObject = [Ordered]@{ }

    Switch -Regex ($Object.GetType().Name) { 
        "PSCustomObject" { 
            Get-Member -Type NoteProperty -InputObject $Object | Sort-Object Name | ForEach-Object { 
                # Upper / lower case conversion (Web GUI is case sensitive)
                $Property = $_.Name
                $Property = $Variables.AvailableCommandLineParameters | Where-Object { $_ -eq $Property }
                If (-not $PropertyName) { $Property = $_.Name }

                If ($Object.$Property -is [Hashtable] -or $Object.$Property -is [PSCustomObject]) { $SortedObject[$Property] = Get-SortedObject $Object.$Property }
                ElseIf ($Object.$Property -is [Array]) { $SortedObject[$Property] = $Object.$Property -as $Object.$Property.GetType().Name }
                Else { $SortedObject[$Property] = $Object.$Property }
            }
        }
        "Hashtable|SyncHashtable" { 
           $Object.Keys | Sort-Object | ForEach-Object { 
                # Upper / lower case conversion (Web GUI is case sensitive)
                $Key = $_
                $Key = $Variables.AvailableCommandLineParameters | Where-Object { $_ -eq $Key }
                If (-not $Key) { $Key = $_ }

                $SortedObject[$Key] = If ($Object.$Key -is [Hashtable] -or $Object.$Key -is [PSCustomObject]) { Get-SortedObject $Object.$Key } Else { $Object.$Key }
            }
        }
        Default { 
            $SortedObject = $Object
        }
    }

    $SortedObject
}

Function Set-Stat { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Name, 
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [DateTime]$Updated = (Get-Date), 
        [Parameter(Mandatory = $false)]
        [TimeSpan]$Duration, 
        [Parameter(Mandatory = $false)]
        [Boolean]$FaultDetection = $true, 
        [Parameter(Mandatory = $false)]
        [Boolean]$ChangeDetection = $false, 
        [Parameter(Mandatory = $false)]
        [Int]$ToleranceExceeded = 3
    )

    $Timer = $Updated = $Updated.ToUniversalTime()

    $Path = "Stats\$Name.txt"
    $SmallestValue = 1E-20
    $Disabled = $Value -eq -1
    $Stat = Get-Stat -Name $Name

    If ($Stat -is [Hashtable] -and $Stat.IsSynchronized -and -not [Double]::IsNaN($Stat.Minute_Fluctuation)) { 
        If (-not $Stat.Timer) { $Stat.Timer = $Stat.Updated.AddMinutes(-1) }
        If (-not $Duration) { $Duration = $Updated - $Stat.Timer }
        If ($Duration -le 0) { Return $Stat }

        If ($Disabled) { $Value = [Decimal]$Stat.Live }

        If ($ChangeDetection -and [Decimal]$Value -eq [Decimal]$Stat.Live) { $Updated = $Stat.Updated }

        If ($FaultDetection) { 
            $FaultFactor = If ($Name -match ".+_Hashrate$") { 0.1 } Else { 0.2 }
            $ToleranceMin = $Stat.Week * (1 - $FaultFactor)
            $ToleranceMax = $Stat.Week * (1 + $FaultFactor)
        }
        Else { 
            $ToleranceMin = $ToleranceMax = $Value
        }

        If ($Value -lt $ToleranceMin -or $Value -gt $ToleranceMax) { $Stat.ToleranceExceeded ++ }
        Else { $Stat | Add-Member ToleranceExceeded ([UInt16]0) -Force }

        If ($Value -gt 0 -and $Stat.ToleranceExceeded -gt 0 -and $Stat.ToleranceExceeded -lt $ToleranceExceeded -and $Stat.Week -gt 0) { 
            If ($Name -match ".+_Hashrate$") { 
                Write-Message -Level Warn "Error saving hash rate for '$($Name -replace '_Hashrate$')'. $(($Value | ConvertTo-Hash) -replace '\s+', '') is outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) [Iteration $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            ElseIf ($Name -match ".+_PowerUsage") { 
                Write-Message -Level Warn "Error saving power usage for '$($Name -replace '_PowerUsage$')'. $($Value.ToString("N2"))W is outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) [Iteration $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            Return
        }
        Else { 
            If ($Value -eq 0 -or $Stat.ToleranceExceeded -ge $ToleranceExceeded -or $Stat.Week_Fluctuation -ge 1) { 
                If ($Value -gt 0 -and $Stat.ToleranceExceeded -ge $ToleranceExceeded) { 
                    If ($Name -match ".+_Hashrate$") { 
                        Write-Message -Level Warn "Hashrate '$($Name -replace '_Hashrate$')' was forcefully updated. $(($Value | ConvertTo-Hash) -replace '\s+', ' ') was outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' '))$(If ($Stat.Week_Fluctuation -lt 1) { " for $($Stats.($Stat.Name).ToleranceExceeded) times in a row." })"
                    }
                    ElseIf ($Name -match ".+_PowerUsage$") { 
                        Write-Message -Level Warn "Power usage for '$($Name -replace '_PowerUsage$')' was forcefully updated. $($Value.ToString("N2"))W was outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W)$(If ($Stat.Week_Fluctuation -lt 1) { " for $($Stats.($Stat.Name).ToleranceExceeded) times in a row." })"
                    }
                }

                Remove-Stat -Name $Name
                $Stat = Set-Stat -Name $Name -Value $Value
            }
            Else { 
                $Span_Minute = [Math]::Min($Duration.TotalMinutes / [Math]::Min($Stat.Duration.TotalMinutes, 1), 1)
                $Span_Minute_5 = [Math]::Min(($Duration.TotalMinutes / 5) / [Math]::Min(($Stat.Duration.TotalMinutes / 5), 1), 1)
                $Span_Minute_10 = [Math]::Min(($Duration.TotalMinutes / 10) / [Math]::Min(($Stat.Duration.TotalMinutes / 10), 1), 1)
                $Span_Hour = [Math]::Min($Duration.TotalHours / [Math]::Min($Stat.Duration.TotalHours, 1), 1)
                $Span_Day = [Math]::Min($Duration.TotalDays / [Math]::Min($Stat.Duration.TotalDays, 1), 1)
                $Span_Week = [Math]::Min(($Duration.TotalDays / 7) / [Math]::Min(($Stat.Duration.TotalDays / 7), 1), 1)

                $Stat.Name = $Name
                $Stat.Live = $Value
                $Stat.Minute_Fluctuation = ((1 - $Span_Minute) * $Stat.Minute_Fluctuation) + ($Span_Minute * ([Math]::Abs($Value - $Stat.Minute) / [Math]::Max([Math]::Abs($Stat.Minute), $SmallestValue)))
                $Stat.Minute = ((1 - $Span_Minute) * $Stat.Minute) + ($Span_Minute * $Value)
                $Stat.Minute_5_Fluctuation = ((1 - $Span_Minute_5) * $Stat.Minute_5_Fluctuation) + ($Span_Minute_5 * ([Math]::Abs($Value - $Stat.Minute_5) / [Math]::Max([Math]::Abs($Stat.Minute_5), $SmallestValue)))
                $Stat.Minute_5 = ((1 - $Span_Minute_5) * $Stat.Minute_5) + ($Span_Minute_5 * $Value)
                $Stat.Minute_10_Fluctuation = ((1 - $Span_Minute_10) * $Stat.Minute_10_Fluctuation) + ($Span_Minute_10 * ([Math]::Abs($Value - $Stat.Minute_10) / [Math]::Max([Math]::Abs($Stat.Minute_10), $SmallestValue)))
                $Stat.Minute_10 = ((1 - $Span_Minute_10) * $Stat.Minute_10) + ($Span_Minute_10 * $Value)
                $Stat.Hour_Fluctuation = ((1 - $Span_Hour) * $Stat.Hour_Fluctuation) + ($Span_Hour * ([Math]::Abs($Value - $Stat.Hour) / [Math]::Max([Math]::Abs($Stat.Hour), $SmallestValue)))
                $Stat.Hour = ((1 - $Span_Hour) * $Stat.Hour) + ($Span_Hour * $Value)
                $Stat.Day_Fluctuation = ((1 - $Span_Day) * $Stat.Day_Fluctuation) + ($Span_Day * ([Math]::Abs($Value - $Stat.Day) / [Math]::Max([Math]::Abs($Stat.Day), $SmallestValue)))
                $Stat.Day = ((1 - $Span_Day) * $Stat.Day) + ($Span_Day * $Value)
                $Stat.Week_Fluctuation = ((1 - $Span_Week) * $Stat.Week_Fluctuation) + ($Span_Week * ([Math]::Abs($Value - $Stat.Week) / [Math]::Max([Math]::Abs($Stat.Week), $SmallestValue)))
                $Stat.Week = ((1 - $Span_Week) * $Stat.Week) + ($Span_Week * $Value)
                $Stat.Duration = $Stat.Duration + $Duration
                $Stat.Updated = $Updated
                $Stat.Disabled = $Disabled
                $Stat.Timer = $Timer
                $Stat.ToleranceExceeded = [UInt16]0
            }
        }
    }
    Else { 
        If (-not $Duration) { $Duration = [TimeSpan]::FromMinutes(1) }

        $Global:Stats.$Name = $Stat = [Hashtable]::Synchronized(
            @{ 
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
                Duration              = [TimeSpan]$Duration
                Updated               = [DateTime]$Updated
                Disabled              = [Boolean]$Disabled
                ToleranceExceeded     = [UInt16]0
                Timer                 = [DateTime]$Timer
            }
        )
    }

    @{ 
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
        Duration              = [String]$Stat.Duration
        Updated               = [DateTime]$Stat.Updated
        Disabled              = [Boolean]$Stat.Disabled
    } | ConvertTo-Json | Out-File -FilePath $Path -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue

    $Stat
}

Function Get-Stat { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = (
            & { 
                [String[]]$StatFiles = ((Get-ChildItem -Path "Stats" -File -ErrorAction Ignore).BaseName | Sort-Object -Unique)
                ($Global:Stats.Keys | Select-Object | Where-Object { $_ -notin $StatFiles }) | ForEach-Object { $Global:Stats.Remove($_) } # Remove stat if deleted on disk
                $StatFiles
            }
        )
    )

    $Name | ForEach-Object { 
        $Stat_Name = $_

        If ($Stats.$Stat_Name -isnot [Hashtable] -or -not $Global:Stats.$Stat_Name.IsSynchronized) { 
            If ($Global:Stats -isnot [Hashtable] -or -not $Global:Stats.IsSynchronized) { 
                $Global:Stats = [Hashtable]::Synchronized(@{ })
            }

            # Reduce number of errors
            If (-not (Test-Path -Path "Stats\$Stat_Name.txt" -PathType Leaf)) { 
                If (-not (Test-Path -Path "Stats" -PathType Container)) { 
                    New-Item "Stats" -ItemType "directory" -Force | Out-Null
                }
                Return
            }

            Try { 
                $Stat = Get-Content "Stats\$Stat_Name.txt" -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                $Global:Stats.$Stat_Name = [Hashtable]::Synchronized(
                    @{ 
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
                        Duration              = [TimeSpan]$Stat.Duration
                        Updated               = [DateTime]$Stat.Updated
                        Disabled              = [Boolean]$Stat.Disabled
                        ToleranceExceeded     = [UInt16]0
                    }
                )
            }
            Catch { 
                Write-Message -Level Warn "Stat file ($Stat_Name) is corrupt and will be reset."
                Remove-Stat $Stat_Name
            }
        }

        $Global:Stats.$Stat_Name
    }
}

Function Remove-Stat { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @($Global:Stats.Keys | Select-Object) + @((Get-ChildItem -Path "Stats" -Directory -ErrorAction Ignore ).BaseName)
    )

    $Name | Sort-Object -Unique | ForEach-Object { 
        Remove-Item -Path "Stats\$_.txt" -Force -Confirm:$false -ErrorAction SilentlyContinue
        If ($Global:Stats.$_) { $Global:Stats.Remove($_) }
    }
}

Function Get-ArgumentsPerDevice { 

    # filters the arguments to contain only argument values for selected devices
    # if an argument has multiple values, only the values for the available devices are included
    # arguments with a single value are valid for all devices and remain untouched
    # excluded arguments are passed unmodified

    Param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]$Arguments, 
        [Parameter(Mandatory = $false)]
        [String[]]$ExcludeArguments = "", 
        [Parameter(Mandatory = $false)]
        [Int[]]$DeviceIDs
    )

    $ArgumentsPerDevice = ""

    " $($Arguments.TrimStart().TrimEnd())" -split "(?=\s+[-]{1,2})" | ForEach-Object { 
        $Token = $_
        $Prefix = ""
        $ParameterSeparator = ""
        $ValueSeparator = ""
        $Values = ""

        If ($Token -match "(?:^\s[-=]+)" <#supported prefix characters are listed in brackets [-=]#>) { 
            $Prefix = $Matches[0]
            $Token = $Token -split $Matches[0] | Select-Object -Last 1

            If ($Token -match "(?:[ =]+)" <#supported separators are listed in brackets [ =]#>) { 
                $ParameterSeparator = $Matches[0]
                $Parameter = $Token -split $ParameterSeparator | Select-Object -First 1
                $Values = $Token.Substring(("$Parameter$($ParameterSeparator)").length)

                If ($Parameter -notin $ExcludeArguments -and $Values -match "(?:[,; ]{1})" <#supported separators are listed in brackets [,; ]#>) { 
                    $ValueSeparator = $Matches[0]
                    $RelevantValues = @()
                    $DeviceIDs | ForEach-Object { 
                        $RelevantValues += ($Values.Split($ValueSeparator) | Select-Object -Index $_)
                    }
                    $ArgumentsPerDevice += "$Prefix$Parameter$ParameterSeparator$($RelevantValues -join $ValueSeparator)"
                }
                Else { $ArgumentsPerDevice += "$Prefix$Parameter$ParameterSeparator$Values" }
            }
            Else { $ArgumentsPerDevice += "$Prefix$Token" }
        }
        Else { $ArgumentsPerDevice += $Token }
    }
    $ArgumentsPerDevice
}

Function Get-ChildItemContent { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Path, 
        [Parameter(Mandatory = $false)]
        [Hashtable]$Parameters = @{ }, 
        [Parameter(Mandatory = $false)]
        [Switch]$Threaded = $false, 
        [Parameter(Mandatory = $false)]
        [String]$Priority
    )

    If ($Priority) { ([System.Diagnostics.Process]::GetCurrentProcess()).PriorityClass = $Priority } Else { $Priority = ([System.Diagnostics.Process]::GetCurrentProcess()).PriorityClass }

    $ScriptBlock = { 
        Param(
            [Parameter(Mandatory = $true)]
            [String]$Path, 
            [Parameter(Mandatory = $false)]
            [Hashtable]$Parameters = @{ }, 
            [Parameter(Mandatory = $false)]
            [String]$Priority = "BelowNormal"
        )

        ([System.Diagnostics.Process]::GetCurrentProcess()).PriorityClass = $Priority

        Function Invoke-ExpressionRecursive ($Expression) { 
            If ($Expression -is [String]) { 
                If ($Expression -match '\$') { 
                    Try { $Expression = Invoke-Expression $Expression }
                    Catch { $Expression = Invoke-Expression "`"$Expression`"" }
                }
            }
            ElseIf ($Expression -is [PSCustomObject]) { 
                $Expression.PSObject.Properties.Name | ForEach-Object { 
                    $Expression.$_ = Invoke-ExpressionRecursive $Expression.$_
                }
            }
            Return $Expression
        }

        Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue | ForEach-Object { 
            $Name = $_.BaseName
            $Content = @()
            If ($_.Extension -eq ".ps1") { 
                $Content = & { 
                    $Parameters.Keys | ForEach-Object { Set-Variable $_ $Parameters.$_ }
                    & $_.FullName @Parameters
                }
            }
            Else { 
                $Content = & { 
                    $Parameters.Keys | ForEach-Object { Set-Variable $_ $Parameters.$_ }
                    Try { 
                        ($_ | Get-Content | ConvertFrom-Json) | ForEach-Object { Invoke-ExpressionRecursive $_ }
                    }
                    Catch [ArgumentException] { 
                        $null
                    }
                }
                If ($null -eq $Content) { $Content = $_ | Get-Content }
            }
            $Content | ForEach-Object { 
                [PSCustomObject]@{ Name = $Name; Content = $_ }
            }
        }
    }

    If ($Threaded) { 
        Return (Start-ThreadJob -Name "Get-ChildItemContent_$($Path -replace '\.\\|\.\*' -replace '\\', '_')" -ThrottleLimit 99 -ScriptBlock $ScriptBlock -ArgumentList $Path, $Parameters, $Priority)
    }
    Else { 
        Return (& $ScriptBlock -Path $Path -Parameters $Parameters)
    }
}

Function Invoke-TcpRequest { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Server, 
        [Parameter(Mandatory = $true)]
        [String]$Port, 
        [Parameter(Mandatory = $true)]
        [String]$Request, 
        [Parameter(Mandatory = $true)]
        [Int]$Timeout, # seconds
        [Parameter(Mandatory = $false)]
        [Boolean]$ReadToEnd = $false
    )

    Try { 
        $Client = [Net.Sockets.TcpClient]::new($Server, $Port)
        $Client.SendTimeout = $Client.ReceiveTimeout = $Timeout * 1000
        $Stream = $Client.GetStream()
        $Writer = [IO.StreamWriter]::new($Stream)
        $Reader = [IO.StreamReader]::new($Stream)
        $Writer.AutoFlush = $true
        $Writer.WriteLine($Request)
        $Response = If ($ReadToEnd) { $Reader.ReadToEnd() } Else { $Reader.ReadLine() }
    }
    Catch { $Error.Remove($error[$Error.Count - 1]) }
    Finally { 
        If ($Reader) { $Reader.Close() }
        If ($Writer) { $Writer.Close() }
        If ($Stream) { $Stream.Close() }
        If ($Client) { $Client.Close() }
    }

    $Response
}

Function Get-CpuId { 

    # Brief : gets CPUID (CPU name and registers)

    # OS Features
    # $OS_x64 = "" # not implemented
    # $OS_AVX = "" # not implemented
    # $OS_AVX512 = "" # not implemented

    # Vendor
    $vendor = "" # not implemented

    $info = [CpuID]::Invoke(0)
    # convert 16 bytes to 4 ints for compatibility with existing code
    $info = [Int[]]@(
        [BitConverter]::ToInt32($info, 0 * 4)
        [BitConverter]::ToInt32($info, 1 * 4)
        [BitConverter]::ToInt32($info, 2 * 4)
        [BitConverter]::ToInt32($info, 3 * 4)
    )

    $nIds = $info[0]

    $info = [CpuID]::Invoke(0x80000000)
    $nExIds = [BitConverter]::ToUInt32($info, 0 * 4) # not sure as to why 'nExIds' is unsigned; may not be necessary
    # convert 16 bytes to 4 ints for compatibility with existing code
    $info = [Int[]]@(
        [BitConverter]::ToInt32($info, 0 * 4)
        [BitConverter]::ToInt32($info, 1 * 4)
        [BitConverter]::ToInt32($info, 2 * 4)
        [BitConverter]::ToInt32($info, 3 * 4)
    )

    # Detect Features
    $features = @{ }
    If ($nIds -ge 0x00000001) { 

        $info = [CpuID]::Invoke(0x00000001)
        # convert 16 bytes to 4 ints for compatibility with existing code
        $info = [Int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $features.MMX = ($info[3] -band ([Int]1 -shl 23)) -ne 0
        $features.SSE = ($info[3] -band ([Int]1 -shl 25)) -ne 0
        $features.SSE2 = ($info[3] -band ([Int]1 -shl 26)) -ne 0
        $features.SSE3 = ($info[2] -band ([Int]1 -shl 00)) -ne 0

        $features.SSSE3 = ($info[2] -band ([Int]1 -shl 09)) -ne 0
        $features.SSE41 = ($info[2] -band ([Int]1 -shl 19)) -ne 0
        $features.SSE42 = ($info[2] -band ([Int]1 -shl 20)) -ne 0
        $features.AES = ($info[2] -band ([Int]1 -shl 25)) -ne 0

        $features.AVX = ($info[2] -band ([Int]1 -shl 28)) -ne 0
        $features.FMA3 = ($info[2] -band ([Int]1 -shl 12)) -ne 0

        $features.RDRAND = ($info[2] -band ([Int]1 -shl 30)) -ne 0
    }

    If ($nIds -ge 0x00000007) { 

        $info = [CpuID]::Invoke(0x00000007)
        # convert 16 bytes to 4 ints for compatibility with existing code
        $info = [Int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $features.AVX2 = ($info[1] -band ([Int]1 -shl 05)) -ne 0

        $features.BMI1 = ($info[1] -band ([Int]1 -shl 03)) -ne 0
        $features.BMI2 = ($info[1] -band ([Int]1 -shl 08)) -ne 0
        $features.ADX = ($info[1] -band ([Int]1 -shl 19)) -ne 0
        $features.MPX = ($info[1] -band ([Int]1 -shl 14)) -ne 0
        $features.SHA = ($info[1] -band ([Int]1 -shl 29)) -ne 0
        $features.PREFETCHWT1 = ($info[2] -band ([Int]1 -shl 00)) -ne 0

        $features.AVX512_F = ($info[1] -band ([Int]1 -shl 16)) -ne 0
        $features.AVX512_CD = ($info[1] -band ([Int]1 -shl 28)) -ne 0
        $features.AVX512_PF = ($info[1] -band ([Int]1 -shl 26)) -ne 0
        $features.AVX512_ER = ($info[1] -band ([Int]1 -shl 27)) -ne 0
        $features.AVX512_VL = ($info[1] -band ([Int]1 -shl 31)) -ne 0
        $features.AVX512_BW = ($info[1] -band ([Int]1 -shl 30)) -ne 0
        $features.AVX512_DQ = ($info[1] -band ([Int]1 -shl 17)) -ne 0
        $features.AVX512_IFMA = ($info[1] -band ([Int]1 -shl 21)) -ne 0
        $features.AVX512_VBMI = ($info[2] -band ([Int]1 -shl 01)) -ne 0
    }

    If ($nExIds -ge 0x80000001) { 

        $info = [CpuID]::Invoke(0x80000001)
        # convert 16 bytes to 4 ints for compatibility with existing code
        $info = [Int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $features.x64 = ($info[3] -band ([Int]1 -shl 29)) -ne 0
        $features.ABM = ($info[2] -band ([Int]1 -shl 05)) -ne 0
        $features.SSE4a = ($info[2] -band ([Int]1 -shl 06)) -ne 0
        $features.FMA4 = ($info[2] -band ([Int]1 -shl 16)) -ne 0
        $features.XOP = ($info[2] -band ([Int]1 -shl 11)) -ne 0
    }

    # wrap data into PSObject
    [PSCustomObject]@{ 
        Vendor   = $vendor
        Name     = $name
        Features = $features.Keys.ForEach{ If ($features.$_) { $_ } }
    }
}

Function Get-Device { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @(), 
        [Parameter(Mandatory = $false)]
        [String[]]$ExcludeName = @(), 
        [Parameter(Mandatory = $false)]
        [Switch]$Refresh = $false
    )

    If ($Name) { 
        $DeviceList = Get-Content ".\Data\Devices.json" | ConvertFrom-Json
        $Name_Devices = $Name | ForEach-Object { 
            $Name_Split = $_ -split '#'
            $Name_Split = @($Name_Split | Select-Object -First 1) + @($Name_Split | Select-Object -Skip 1 | ForEach-Object { [Int]$_ })
            $Name_Split += @("*") * (100 - $Name_Split.Count)

            $Name_Device = $DeviceList.("{0}" -f $Name_Split) | Select-Object *
            ($Name_Device | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name | ForEach-Object { $Name_Device.$_ = $Name_Device.$_ -f $Name_Split }

            $Name_Device
        }
    }

    If ($ExcludeName) { 
        If (-not $DeviceList) { $DeviceList = Get-Content -Path ".\Data\Devices.json" | ConvertFrom-Json }
        $ExcludeName_Devices = $ExcludeName | ForEach-Object { 
            $ExcludeName_Split = $_ -split '#'
            $ExcludeName_Split = @($ExcludeName_Split | Select-Object -First 1) + @($ExcludeName_Split | Select-Object -Skip 1 | ForEach-Object { [Int]$_ })
            $ExcludeName_Split += @("*") * (100 - $ExcludeName_Split.Count)

            $ExcludeName_Device = $DeviceList.("{0}" -f $ExcludeName_Split) | Select-Object *
            ($ExcludeName_Device | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name | ForEach-Object { $ExcludeName_Device.$_ = $ExcludeName_Device.$_ -f $ExcludeName_Split }

            $ExcludeName_Device
        }
    }

    If ($Variables.Devices -isnot [Device[]] -or $Refresh) { 
        [Device[]]$Variables.Devices = @()

        $Id = 0
        $Type_Id = @{ }
        $Vendor_Id = @{ }
        $Type_Vendor_Id = @{ }

        $Slot = 0
        $Type_Slot = @{ }
        $Vendor_Slot = @{ }
        $Type_Vendor_Slot = @{ }

        $Index = 0
        $Type_Index = @{ }
        $Vendor_Index = @{ }
        $Type_Vendor_Index = @{ }
        $PlatformId = 0
        $PlatformId_Index = @{ }
        $Type_PlatformId_Index = @{ }

        $UnsupportedCPUVendorID = 100
        $UnsupportedGPUVendorID = 100

        # Get WDDM data
        Try { 
            Get-CimInstance CIM_Processor | ForEach-Object { 
                $Device_CIM = $_ | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                # Add normalised values
                $Variables.Devices += $Device = [PSCustomObject]@{ 
                    Name   = $null
                    Model  = $Device_CIM.Name
                    Type   = "CPU"
                    Bus    = $null
                    Vendor = $(
                        Switch -Regex ($Device_CIM.Manufacturer) { 
                            "Advanced Micro Devices" { "AMD" }
                            "Intel" { "INTEL" }
                            "NVIDIA" { "NVIDIA" }
                            "AMD" { "AMD" }
                            Default { $Device_CIM.Manufacturer -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' -replace '\s+', ' ' }
                        }
                    )
                    Memory = $null
                    MemoryGB = $null
                }

                $Device | Add-Member @{ 
                    Id             = [Int]$Id
                    Type_Id        = [Int]$Type_Id.($Device.Type)
                    Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                    Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                }

                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB" -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^ A-Z0-9\.]' -replace '\s+', ' ').Trim()

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id++
                $Vendor_Id.($Device.Vendor)++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                If ($Device.Vendor -in $Variables."Supported$($Device.Type)DeviceVendors") { $Type_Id.($Device.Type)++ }

                # Read CPU features
                $Device | Add-Member CpuFeatures ((Get-CpuId).Features | Sort-Object)

                # Add raw data
                $Device | Add-Member @{ 
                    CIM = $Device_CIM
                }
            }

            Get-CimInstance CIM_VideoController | ForEach-Object { 
                $Device_CIM = $_ | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { 
                    $Device_PNP = [PSCustomObject]@{ }
                    Get-PnpDevice $Device_CIM.PNPDeviceID | Get-PnpDeviceProperty | ForEach-Object { $Device_PNP | Add-Member $_.KeyName $_.Data }
                    $Device_PNP = $Device_PNP | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                    $Device_Reg = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\$($Device_PNP.DEVPKEY_Device_Driver)" -ErrorAction Ignore | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                    # Add normalised values
                    $Variables.Devices += $Device = [PSCustomObject]@{ 
                        Name   = $null
                        Model  = $Device_CIM.Name
                        Type   = "GPU"
                        Bus    = $(
                            If ($Device_PNP.DEVPKEY_Device_BusNumber -is [Int64] -or $Device_PNP.DEVPKEY_Device_BusNumber -is [Int32]) { 
                                [Int64]$Device_PNP.DEVPKEY_Device_BusNumber
                            }
                        )
                        Vendor = $(
                            Switch -Regex ([String]$Device_CIM.AdapterCompatibility) { 
                                "Advanced Micro Devices" { "AMD" }
                                "Intel" { "INTEL" }
                                "NVIDIA" { "NVIDIA" }
                                "AMD" { "AMD" }
                                Default { $Device_CIM.AdapterCompatibility -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' -replace '\s+', ' ' }
                            }
                        )
                        Memory = [Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize'))
                        MemoryGB = [Double]([Math]::Round([Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize')) / 0.05GB) / 20) # Round to nearest 50MB
                    }
                }
                Else { 
                    # Add normalised values
                    $Variables.Devices += $Device = [PSCustomObject]@{ 
                        Name   = $null
                        Model  = $Device_CIM.Name
                        Type   = "GPU"
                        Vendor = $(
                            Switch -Regex ([String]$Device_CIM.AdapterCompatibility) { 
                                "Advanced Micro Devices" { "AMD" }
                                "Intel" { "INTEL" }
                                "NVIDIA" { "NVIDIA" }
                                "AMD" { "AMD" }
                                Default { $Device_CIM.AdapterCompatibility -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' -replace '\s+', ' '}
                            }
                        )
                        Memory = [Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize'))
                        MemoryGB = [Double]([Math]::Round([Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize')) / 0.05GB) / 20) # Round to nearest 50MB
                    }
                }

                $Device | Add-Member @{ 
                    Id             = [Int]$Id
                    Type_Id        = [Int]$Type_Id.($Device.Type)
                    Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                    Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                }
                #Unsupported devices start with DeviceID 100 (to not disrupt device order when running in a Citrix / RDP session)
                If ($Device.Vendor -in $Variables."Supported$($Device.Type)DeviceVendors") { 
                    $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                }
                ElseIf ($Device.Type -eq "CPU") { 
                    $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID++)"
                }
                Else { 
                    $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID++)"
                }
                $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB" -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^ A-Z0-9\.]' -replace '\s+', ' ').Trim()

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id++
                $Vendor_Id.($Device.Vendor)++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                If ($Device.Vendor -in $Variables."Supported$($Device.Type)DeviceVendors") { $Type_Id.($Device.Type)++ }

                # Add raw data
                $Device | Add-Member @{ 
                    CIM = $Device_CIM
                    PNP = $Device_PNP
                    Reg = $Device_Reg
                }
            }
        }
        Catch { 
            Write-Message -Level Warn "WDDM device detection has failed. "
        }

        # Get OpenCL data
        Try { 
            [OpenCl.Platform]::GetPlatformIDs() | ForEach-Object { 
                [OpenCl.Device]::GetDeviceIDs($_, [OpenCl.DeviceType]::All) | ForEach-Object { $_ | ConvertTo-Json -WarningAction SilentlyContinue } | Select-Object -Unique | ForEach-Object { 
                    $Device_OpenCL = $_ | ConvertFrom-Json

                    # Add normalised values
                    $Device = [PSCustomObject]@{ 
                        Name   = $null
                        Model  = $Device_OpenCL.Name
                        Type   = $(
                            Switch -Regex ([String]$Device_OpenCL.Type) { 
                                "CPU" { "CPU" }
                                "GPU" { "GPU" }
                                Default { [String]$Device_OpenCL.Type -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' -replace '\s+', ' ' }
                            }
                        )
                        Bus    = $(
                            If ($Device_OpenCL.PCIBus -is [Int64] -or $Device_OpenCL.PCIBus -is [Int32]) { 
                                [Int64]$Device_OpenCL.PCIBus
                            }
                        )
                        Vendor = $(
                            Switch -Regex ([String]$Device_OpenCL.Vendor) { 
                                "Advanced Micro Devices" { "AMD" }
                                "Intel" { "INTEL" }
                                "NVIDIA" { "NVIDIA" }
                                "AMD" { "AMD" }
                                Default { [String]$Device_OpenCL.Vendor -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' -replace '\s+', ' ' }
                            }
                        )
                        Memory = [UInt64]$Device_OpenCL.GlobalMemSize
                        MemoryGB = [Double]([Math]::Round($Device_OpenCL.GlobalMemSize / 0.05GB) / 20) # Round to nearest 50MB
                    }

                    $Device | Add-Member @{ 
                        Id             = [Int]$Id
                        Type_Id        = [Int]$Type_Id.($Device.Type)
                        Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                        Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                    }
                    #Unsupported devices get DeviceID 100 (to not disrupt device order when running in a Citrix / RDP session)
                    If ($Device.Vendor -in $Variables."Supported$($Device.Type)DeviceVendors") { 
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                    }
                    ElseIf ($Device.Type -eq "CPU") { 
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID++)"
                    }
                    Else { 
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID++)"
                    }
                    $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9 ]' -replace '\s+', ' '

                    If (-not $Type_Vendor_Id.($Device.Type)) { 
                        $Type_Vendor_Id.($Device.Type) = @{ }
                    }

                    If ($Variables.Devices | Where-Object Type -EQ $Device.Type | Where-Object Bus -EQ $Device.Bus) { 
                        $Device = $Variables.Devices | Where-Object Type -EQ $Device.Type | Where-Object Bus -EQ $Device.Bus
                    }
                    ElseIf ($Device.Type -eq "GPU" -and ($Device.Vendor -eq "AMD" -or $Device.Vendor -eq "NVIDIA")) { 
                        $Variables.Devices += $Device

                        If (-not $Type_Vendor_Index.($Device.Type)) { 
                            $Type_Vendor_Index.($Device.Type) = @{ }
                        }

                        $Id++
                        $Vendor_Id.($Device.Vendor)++
                        $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                        $Type_Id.($Device.Type)++
                    }

                    # Add OpenCL specific data
                    $Device | Add-Member @{ 
                        Index                 = [Int]$Index
                        Type_Index            = [Int]$Type_Index.($Device.Type)
                        Vendor_Index          = [Int]$Vendor_Index.($Device.Vendor)
                        Type_Vendor_Index     = [Int]$Type_Vendor_Index.($Device.Type).($Device.Vendor)
                        PlatformId            = [Int]$PlatformId
                        PlatformId_Index      = [Int]$PlatformId_Index.($PlatformId)
                        Type_PlatformId_Index = [Int]$Type_PlatformId_Index.($Device.Type).($PlatformId)
                    } -Force

                    # Add raw data
                    $Device | Add-Member @{ 
                        OpenCL = $Device_OpenCL
                    } -Force

                   
                    If (-not $Type_Vendor_Index.($Device.Type)) { 
                        $Type_Vendor_Index.($Device.Type) = @{ }
                    }
                    If (-not $Type_PlatformId_Index.($Device.Type)) { 
                        $Type_PlatformId_Index.($Device.Type) = @{ }
                    }

                    $Index++
                    $Type_Index.($Device.Type)++
                    $Vendor_Index.($Device.Vendor)++
                    $Type_Vendor_Index.($Device.Type).($Device.Vendor)++
                    $PlatformId_Index.($PlatformId)++
                    $Type_PlatformId_Index.($Device.Type).($PlatformId)++
                }

                $PlatformId++
            }

            $Variables.Devices | Where-Object Vendor -ne "CitrixSystemsInc" | Where-Object Bus -Is [Int64] | Sort-Object Bus | ForEach-Object { 
                $_ | Add-Member @{ 
                    Slot             = [Int]$Slot
                    Type_Slot        = [Int]$Type_Slot.($_.Type)
                    Vendor_Slot      = [Int]$Vendor_Slot.($_.Vendor)
                    Type_Vendor_Slot = [Int]$Type_Vendor_Slot.($_.Type).($_.Vendor)
                }

                If (-not $Type_Vendor_Slot.($_.Type)) { 
                    $Type_Vendor_Slot.($_.Type) = @{ }
                }

                $Slot++
                $Type_Slot.($_.Type)++
                $Vendor_Slot.($_.Vendor)++
                $Type_Vendor_Slot.($_.Type).($_.Vendor)++
            }
        }
        Catch { 
            Write-Message -Level Warn "OpenCL device detection has failed. "
        }
    }

    $Variables.Devices | ForEach-Object { 
        [Device]$Device = $_

        $Device.Bus_Index = @($Variables.Devices.Bus | Sort-Object).IndexOf([Int]$Device.Bus)
        $Device.Bus_Type_Index = @(($Variables.Devices | Where-Object Type -EQ $Device.Type).Bus | Sort-Object).IndexOf([Int]$Device.Bus)
        $Device.Bus_Vendor_Index = @(($Variables.Devices | Where-Object Vendor -EQ $Device.Vendor).Bus | Sort-Object).IndexOf([Int]$Device.Bus)
        $Device.Bus_Platform_Index = @(($Variables.Devices | Where-Object Platform -EQ $Device.Platform).Bus | Sort-Object).IndexOf([Int]$Device.Bus)

        If (-not $Name -or ($Name_Devices | Where-Object { ($Device | Select-Object (($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name)) -like ($_ | Select-Object (($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name)) })) { 
            If (-not $ExcludeName -or -not ($ExcludeName_Devices | Where-Object { ($Device | Select-Object (($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name)) -like ($_ | Select-Object (($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore).Name)) })) { 
                $Device
            }
        }
    }
}

Filter ConvertTo-Hash { 

    $Units = " kMGTPEZY " # k(ilo) in small letters, see https://en.wikipedia.org/wiki/Metric_prefix
    $Base1000 = [Math]::Truncate([Math]::Log([Math]::Abs([Double]$_), [Math]::Pow(1000, 1)))
    $Base1000 = [Math]::Max([Double]0, [Math]::Min($Base1000, $Units.Length - 1))
    "{0:n2} $($Units[$Base1000])H" -f ($_ / [Math]::Pow(1000, $Base1000))
}

Function Get-DigitsFromValue { 

    # To get same numbering scheme regardless of value base currency value (size) to determine formatting

    # Length is calculated as follows:
    # Output will have as many digits as the integer value is to the power of 10
    # e.g. Rate is between 100 -and 999, then Digits is 3
    # The bigger the number, the more decimal digits
    # Use $Offset to add/remove decimal places

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [Int]$Offset = 0
    )

    $Digits = [math]::Floor($Value).ToString().Length + $Offset
    If ($Digits -lt 0) { $Digits = 0 }
    If ($Digits -gt 10) { $Digits = 10 }

    $Digits
}

Function ConvertTo-LocalCurrency { 

    # To get same numbering scheme regardless of value
    # Use $Offset to add/remove decimal places

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $true)]
        [Double]$Rate, 
        [Parameter(Mandatory = $false)]
        [Int]$Offset
    )

    $Digits = ([math]::truncate(10 - $Offset - [math]::log($Rate, 10)))
    If ($Digits -lt 0) { $Digits = 0 }
    If ($Digits -gt 10) { $Digits = 10 }

    ($Value * $Rate).ToString("N$($Digits)")
}

Function Get-Combination { 

    Param(
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

    $Combination_Keys = ($Combination | Get-Member -MemberType NoteProperty).Name

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

Function Invoke-CreateProcess { 

    # Based on https://github.com/FuzzySecurity/PowerShell-Suite/blob/master/Invoke-CreateProcess.ps1

    Param (
        [Parameter(Mandatory = $true)]
        [String]$BinaryPath, 
        [Parameter(Mandatory = $false)]
        [String]$ArgumentList = $null, 
        [Parameter(Mandatory = $false)]
        [String]$WorkingDirectory = "", 
        [Parameter(Mandatory = $false)]
        [ValidateRange(-2, 3)]
        [Int]$Priority = 0, # NORMAL
        [Parameter(Mandatory = $false)]
        [String[]]$EnvBlock = "", 
        [Parameter(Mandatory = $false)]
        [String]$CreationFlags = 0x00000010, # CREATE_NEW_CONSOLE
        [Parameter(Mandatory = $false)]
        [String]$MinerWindowStyle = "minimized", 
        [Parameter(Mandatory = $false)]
        [String]$StartF = 0x00000001, # STARTF_USESHOWWINDOW
        [Parameter(Mandatory = $false)]
        [String]$JobName, 
        [Parameter(Mandatory = $false)]
        [String]$LogFile
    )

    $Job = Start-ThreadJob -Name $JobName -ThrottleLimit 99 -ArgumentList $BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $MinerWindowStyle, $StartF, $PID { 
        Param($BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $MinerWindowStyle, $StartF, $ControllerProcessID)

        $ControllerProcess = Get-Process -Id $ControllerProcessID
        If ($null -eq $ControllerProcess) { Return }

        # Define all the structures for CreateProcess
        Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct PROCESS_INFORMATION
{ 
    public IntPtr hProcess; public IntPtr hThread; public uint dwProcessId; public uint dwThreadId;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct STARTUPINFO
{ 
    public uint cb; public string lpReserved; public string lpDesktop; public string lpTitle;
    public uint dwX; public uint dwY; public uint dwXSize; public uint dwYSize; public uint dwXCountChars;
    public uint dwYCountChars; public uint dwFillAttribute; public uint dwFlags; public short wShowWindow;
    public short cbReserved2; public IntPtr lpReserved2; public IntPtr hStdInput; public IntPtr hStdOutput;
    public IntPtr hStdError;
}

[StructLayout(LayoutKind.Sequential)]
public struct SECURITY_ATTRIBUTES
{ 
    public int length; public IntPtr lpSecurityDescriptor; public bool bInheritHandle;
}

public static class Kernel32
{ 
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CreateProcess(
        string lpApplicationName, string lpCommandLine, ref SECURITY_ATTRIBUTES lpProcessAttributes, 
        ref SECURITY_ATTRIBUTES lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, 
        IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, 
        out PROCESS_INFORMATION lpProcessInformation);
}
"@

        $ShowWindow = $(
            Switch ($MinerWindowStyle) { 
                "hidden" { "0x0000" } # SW_HIDE
                "normal" { "0x0001" } # SW_SHOWNORMAL
                Default  { "0x0007" } # SW_SHOWMINNOACTIVE
            }
        )
        # Set local environment
        $EnvBlock | Select-Object | ForEach-Object { Set-Item -Path "Env:$($_ -split '=' | Select-Object -First 1)" "$($_ -split '=' | Select-Object -Index 1)" -Force }

        # StartupInfo Struct
        $StartupInfo = New-Object STARTUPINFO
        $StartupInfo.dwFlags = $StartF # StartupInfo.dwFlag
        $StartupInfo.wShowWindow = $ShowWindow # StartupInfo.ShowWindow
        $StartupInfo.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($StartupInfo) # Struct Size

        # ProcessInfo Struct
        $ProcessInfo = New-Object PROCESS_INFORMATION

        # SECURITY_ATTRIBUTES Struct (Process & Thread)
        $SecAttr = New-Object SECURITY_ATTRIBUTES
        $SecAttr.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($SecAttr)

        # CreateProcess --> lpCurrentDirectory
        If (-not $WorkingDirectory) { $WorkingDirectory = [IntPtr]::Zero }

        # Call CreateProcess
        [Kernel32]::CreateProcess($BinaryPath, "$BinaryPath $ArgumentList", [ref]$SecAttr, [ref]$SecAttr, $false, $CreationFlags, [IntPtr]::Zero, $WorkingDirectory, [ref]$StartupInfo, [ref]$ProcessInfo) | Out-Null

        $Process = Get-Process -Id $ProcessInfo.dwProcessId
        If ($null -eq $Process) { 
            [PSCustomObject]@{ ProcessId = $null }
            Return
        }

        [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle }

        Do { If ($ControllerProcess.WaitForExit(1000)) { $Process.CloseMainWindow() | Out-Null } }
        While ($Process.HasExited -eq $false)
    }

    Return $Job
}

Function Start-SubProcess { 

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$FilePath, 
        [Parameter(Mandatory = $false)]
        [String]$ArgumentList = "", 
        [Parameter(Mandatory = $false)]
        [String]$LogPath = "", 
        [Parameter(Mandatory = $false)]
        [String]$WorkingDirectory = "", 
        [ValidateRange(-2, 3)]
        [Parameter(Mandatory = $false)]
        [Int]$Priority = 0, 
        [Parameter(Mandatory = $false)]
        [String[]]$EnvBlock
    )

    If ($EnvBlock) { $EnvBlock | ForEach-Object { Set-Item -Path "Env:$($_ -split '=' | Select-Object -First 1)" "$($_ -split '=' | Select-Object -Index 1)" -Force } }

    $ScriptBlock = "Set-Location '$WorkingDirectory'; (Get-Process -Id `$PID).PriorityClass = '$(@{-2 = "Idle"; -1 = "BelowNormal"; 0 = "Normal"; 1 = "AboveNormal"; 2 = "High"; 3 = "RealTime"}[$Priority])'; "
    $ScriptBlock += "& '$FilePath'"
    If ($ArgumentList) { $ScriptBlock += " $ArgumentList" }
    $ScriptBlock += " *>&1"
    $ScriptBlock += " | Write-Output"
    If ($LogPath) { $ScriptBlock += " | Tee-Object '$LogPath'" }

    Start-ThreadJob -ThrottleLimit 99 ([ScriptBlock]::Create($ScriptBlock))
}

Function Expand-WebRequest { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Uri, 
        [Parameter(Mandatory = $false)]
        [String]$Path = ""
    )

    # Set current path used by .net methods to the same as the script's path
    [Environment]::CurrentDirectory = $ExecutionContext.SessionState.Path.CurrentFileSystemLocation

    If (-not $Path) { $Path = Join-Path ".\Downloads" ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName }
    If (-not (Test-Path -Path ".\Downloads" -PathType Container)) { New-Item "Downloads" -ItemType "directory" | Out-Null }
    $FileName = Join-Path ".\Downloads" (Split-Path $Uri -Leaf)

    If (Test-Path $FileName -PathType Leaf) { Remove-Item $FileName }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Uri -OutFile $FileName -TimeoutSec 5 -UseBasicParsing

    If (".msi", ".exe" -contains ([IO.FileInfo](Split-Path $Uri -Leaf)).Extension) { 
        Start-Process $FileName "-qb" -Wait
    }
    Else { 
        $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
        $Path_New = Split-Path $Path

        If (Test-Path $Path_Old -PathType Container) { Remove-Item $Path_Old -Recurse -Force }
        Start-Process ".\Utils\7z" "x `"$([IO.Path]::GetFullPath($FileName))`" -o`"$([IO.Path]::GetFullPath($Path_Old))`" -y -spe" -Wait -WindowStyle Hidden

        If (Test-Path $Path_New -PathType Container) { Remove-Item $Path_New -Recurse -Force }

        # use first (topmost) directory, some miners, e.g. ClaymoreDual_v11.9, contain multiple miner binaries for different driver versions in various sub dirs
        $Path_Old = (Get-ChildItem -Path $Path_Old -File -Recurse | Where-Object { $_.Name -EQ $(Split-Path $Path -Leaf) }).Directory | Select-Object -First 1

        If ($Path_Old) { 
            Move-Item $Path_Old $Path_New -PassThru | ForEach-Object -Process { $_.LastWriteTime = Get-Date }
            $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
            If (Test-Path $Path_Old -PathType Container) { Remove-Item -Path $Path_Old -Recurse -Force }
        }
        Else { 
            Throw "Error: Cannot find '$Path'."
        }
    }
}

Function Get-Algorithm { 

    Param(
        [Parameter(Mandatory = $false)]
        [String]$Algorithm
    )

    If (-not (Test-Path Variable:Global:Algorithms -ErrorAction SilentlyContinue)) { 
        $Global:Algorithms = Get-Content ".\Data\Algorithms.json" | ConvertFrom-Json
    }

    $Algorithm = (Get-Culture).TextInfo.ToTitleCase($Algorithm.ToLower() -replace '-|_|/| ')

    If ($Global:Algorithms.$Algorithm) { $Global:Algorithms.$Algorithm }
    Else { $Algorithm }
}

Function Get-Region { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Region,
        [Parameter(Mandatory = $false)]
        [Switch]$List = $false
    )

    If (-not (Test-Path Variable:Global:Regions -ErrorAction SilentlyContinue)) { 
        $Global:Regions = Get-Content ".\Data\Regions.json" | ConvertFrom-Json
    }

    If ($List) { $Global:Regions.$Region }
    ElseIf ($Global:Regions.$Region) { $($Global:Regions.$Region | Select-Object -First 1) }
    Else { $Region }
}

Function Get-CoinName { 

    Param(
        [Parameter(Mandatory = $false)]
        [String]$Currency
    )

    If (-not (Test-Path Variable:Global:CoinNames -ErrorAction SilentlyContinue)) { 
        $Global:CoinNames = Get-Content ".\Data\CoinNames.json" | ConvertFrom-Json
    }

    If ($Global:CoinNames.$Currency) { 
       Return $Global:CoinNames.$Currency
    }
    If ($Currency) { 
        $Global:CoinNames = Get-Content ".\Data\CoinNames.json" | ConvertFrom-Json
        If ($Global:CoinNames.$Currency) { 
            Write-Message -Level INFO "CoinName '$($Global:CoinNames.$Currency)' added for Currency '$Currency' to CoinNames.json."
            Return $Global:CoinNames.$Currency
        }
    }
    Return $null
}

Function Get-PoolBaseName { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$PoolNames
    )

    $PoolNames -replace "24hr$|Coins$|Coins24hr$|CoinsPlus$|Plus$"
}

Function Get-NMVersion { 

    # Check if new version is available
    Try { 
        $UpdateVersion = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Minerx117/NemosMiner/testing/Version.txt" -TimeoutSec 15 -UseBasicParsing -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json

        If ($UpdateVersion.Product -eq $Variables.CurrentProduct -and [Version]$UpdateVersion.Version -gt $Variables.CurrentVersion) { 
            If ($UpdateVersion.AutoUpdate -eq $true) { 
                If ($Config.AutoUpdate) { 
                    Initialize-Autoupdate -UpdateVersion $UpdateVersion
                }
                Else { 
                    Write-Message -Level Verbose "Version checker: New Version $($UpdateVersion.Version) found. Auto Update is disabled in config - You must update manually."
                }
            }
            Else { 
                Write-Message -Level Verbose "Version checker: New Version is available. $($UpdateVersion.Version) does not support auto-update. You must update manually."
            }
        }
        Else { 
            Write-Message -Level Verbose "Version checker: $($Variables.CurrentProduct) $($Variables.CurrentVersion) is current - no update available."
        }
    }
    Catch { 
        Write-Message -Level Warn "Version checker could not contact update server. $($Variables.CurrentProduct) will automatically retry with 24hrs."
    }
}

Function Initialize-Autoupdate { 

    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UpdateVersion
    )

    Set-Location $Variables.MainPath
    $UpdateLog = "$($Variables.MainPath)\Logs\AutoupdateLog_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt"
    $BackupFile = "AutoupdateBackup_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").zip"

    # GitHub only suppors TLSv1.2 since feb 22 2018
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

    $NemosMinerFileHash = (Get-FileHash ".\$($Variables.CurrentProduct).ps1").Hash

    "Version checker: New version $($UpdateVersion.Version) found. " | Tee-Object $UpdateLog | Write-Message -Level Verbose
    "Starting auto update - Logging changes to '.\$($UpdateLog.Replace("$(Convert-Path '.\')\", ''))'." | Tee-Object $UpdateLog | Write-Message -Level Verbose

    # Setting autostart to true
    If ($Variables.MiningStatus -eq [MinerStatus]::Running) { $Config.AutoStart = $true }

    # Download update file
    $UpdateFileName = ".\$($UpdateVersion.Product)-$($UpdateVersion.Version)"
    "Downloading new version..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose 
    Try { 
        Invoke-WebRequest -Uri $UpdateVersion.Uri -OutFile "$($UpdateFileName).zip" -TimeoutSec 15 -UseBasicParsing
    }
    Catch { 
        "Downloading failed. Cannot complete auto-update :-(" | Tee-Object $UpdateLog -Append | Write-Message -Level Error
        Return
    }
    If (-not (Test-Path -Path ".\$($UpdateFileName).zip" -PathType Leaf)) { 
        Write-Message -Level Error "Cannot find update file. Cannot complete auto-update :-("
        Return
    }

    If ($Variables.CurrentVersion -le [System.Version]"3.9.9.17" -and $UpdateVersion.Version -ge [System.Version]"3.9.9.17") { 
        # Balances & earnings files are no longer compatible
        Write-Message -Level Warn "Balances & Earnings files are no longer compatible and will be reset."
    }

    # Stop processes
    $Variables.NewMiningStatus = "Idle"

    # Backup current version folder in zip file; exclude existing zip files and download folder
    "Backing up current version as '.\$($BackupFile)'..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
    Start-Process ".\Utils\7z" "a $($BackupFile) .\* -x!*.zip -x!downloads -x!logs -x!cache -x!$UpdateLog -bb1 -bd" -RedirectStandardOutput "$($UpdateLog)_tmp" -Wait -WindowStyle Hidden
    Add-Content $UpdateLog (Get-Content -Path "$($UpdateLog)_tmp")
    Remove-Item -Path "$($UpdateLog)_tmp" -Force

    If (-not (Test-Path .\$BackupFile -PathType Leaf)) { 
        "Backup failed. Cannot complete auto-update :-(" | Tee-Object $UpdateLog -Append | Write-Message -Level Error
        Return
    }

    #Stop all background processes
    Stop-Mining
    Stop-BrainJob
    Stop-IdleDetection
    Stop-BalancesTracker

    If ($Variables.CurrentVersion -le [System.Version]"3.9.9.17" -and $UpdateVersion -ge [System.Version]"3.9.9.17") { 
        # Remove balances & earnings files that are no longer compatible
        If (Test-Path -Path ".\Logs\BalancesTrackerData*.*") { Get-ChildItem -Path ".\Logs\BalancesTrackerData*.*" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue} }
        If (Test-Path -Path ".\Logs\DailyEarnings*.*") { Get-ChildItem -Path ".\Logs\DailyEarnings*.*" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue } }
    }

    # Move data files from '\Logs' to '\Data'
    If (Test-Path -Path ".\Logs\BalancesTrackerData*.json" -PathType Leaf) { Move-Item ".\Logs\BalancesTrackerData*.json" ".\Data" -Force }
    If (Test-Path -Path ".\Logs\EarningsChartData.json" -PathType Leaf) { Move-Item ".\Logs\EarningsChartData.json" ".\Data" -Force }
    If (Test-Path -Path ".\Logs\DailyEarnings*.csv" -PathType Leaf) { Move-Item ".\Logs\DailyEarnings*.csv" ".\Data" -Force }
    If (Test-Path -Path ".\Logs\PoolsLastUsed.json" -PathType Leaf) { Move-Item ".\Logs\PoolsLastUsed.json" ".\Data" -Force }

    # Pre update specific actions if any
    # Use PreUpdateActions.ps1 in new release to place code
    # If (Test-Path -Path ".\$UpdateFilePath\PreUpdateActions.ps1" -PathType Leaf) { 
    #     Invoke-Expression (Get-Content ".\$UpdateFilePath\PreUpdateActions.ps1" -Raw)
    # }

    # Empty folders
    If (Test-Path -Path ".\Balances") { Get-ChildItem -Path ".\Balances" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue } }
    If (Test-Path -Path ".\Brains") { Get-ChildItem -Path ".\Brains" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue } }
    If (Test-Path -Path ".\Pools") { Get-ChildItem -Path ".\Pools\" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue } }
    If (Test-Path -Path ".\Web") { Get-ChildItem -Path ".\Web" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue } }

    # Unzip in child folder excluding config
    "Unzipping update..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
    Start-Process ".\Utils\7z" "x $($UpdateFileName).zip -o.\$($UpdateFileName) -y -spe -xr!config -bb1 -bd" -RedirectStandardOutput "$($UpdateLog)_tmp" -Wait -WindowStyle Hidden
    Add-Content $UpdateLog (Get-Content -Path "$($UpdateLog)_tmp")
    Remove-Item -Path "$($UpdateLog)_tmp" -Force

    #Update files are in a subdirectory
    $UpdateFilePath = $UpdateFileName
    If ((Get-ChildItem -Path $UpdateFileName -Directory).Count -eq 1) { 
        $UpdateFilePath = "$UpdateFileName\$((Get-ChildItem -Path $UpdateFileName -Directory).Name)"
    }

    # Stop Snaketail
    If (Get-CimInstance CIM_Process | Where-Object ExecutablePath -EQ $Variables.SnakeTailExe) { 
        "Stopping SnakeTail..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        (Get-CimInstance CIM_Process | Where-Object ExecutablePath -EQ $Variables.SnakeTailExe).ProcessId | ForEach-Object { Stop-Process -Id $_ }
    }

    # Copy files
    "Copying new files..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
    Get-ChildItem -Path ".\$UpdateFilePath\*" -Recurse | ForEach-Object { 
        $DestPath = $_.FullName.Replace($UpdateFilePath -replace "^\.", "")
        If ($_.Attributes -eq "Directory") { 
            If (-not (Test-Path -Path $DestPath -PathType Container)) { 
                New-Item -Path $DestPath -ItemType Directory -Force
                "Created directory '$DestPath'."
            }
        }
        Else { 
            Copy-Item -Path $_ -Destination $DestPath -Force -ErrorAction Ignore
            "Copied '$($_.Name)' to '$Destpath'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        }
    }

    # Remove OrphanedMinerStats; must be done after new miner files habe veen unpacked
    Remove-OrphanedMinerStats | Out-Null

    # Start Log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net]
    Start-LogReader

    # Post update actions
    If (Test-Path  -Path ".\OptionalMiners" -PathType Container) { 
        # Remove any obsolete Optional miner file (ie. not in new version OptionalMiners)
        Get-ChildItem -Path ".\OptionalMiners" -File | Where-Object { $_.name -notin (Get-ChildItem -Path ".\$UpdateFilePath\OptionalMiners" -File).name } | ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue }
        # Update Optional Miners to Miners If in use
        Get-ChildItem -Path ".\OptionalMiners" -File | Where-Object { $_.name -in (Get-ChildItem -Path ".\Miners" -File).name } | ForEach-Object { Copy-Item -Path $_.FullName -Destination ".\Miners" -Force; "Copied $($_.Name) to '.\Miners'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue }
    }

    # Remove any obsolete miner file (ie. not in new version Miners or OptionalMiners)
    If (Test-Path -Path ".\Miners" -PathType Container) { Get-ChildItem -Path ".\Miners" -File | Where-Object { $_.name -notin (Get-ChildItem -Path ".\$UpdateFilePath\Miners" -File).name -and $_.name -notin (Get-ChildItem -Path ".\$UpdateFilePath\OptionalMiners" -File).name } | ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue } }

    # Get all miner names and remove obsolete stat files from miners that no longer exist
    $MinerNames = @( )
    If (Test-Path -Path ".\Miners" -PathType Container) { Get-ChildItem -Path ".\Miners" -File | ForEach-Object { $MinerNames += $_.Name -replace $_.Extension } }
    If (Test-Path -Path ".\OptionalMiners" -PathType Container) { Get-ChildItem -Path ".\OptionalMiners" -File | ForEach-Object { $MinerNames += $_.Name -replace $_.Extension } }
    If (Test-Path -Path ".\Stats" -PathType Container) { 
        Get-ChildItem -Path ".\Stats\*_Hashrate.txt" -File | Where-Object { (($_.name -Split '-' | Select-Object -First 2) -Join '-') -notin $MinerNames } | ForEach-Object { Remove-Item -Path $_ -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue }
        Get-ChildItem -Path ".\Stats\*_PowerUsage.txt" -File | Where-Object { (($_.name -Split '-' | Select-Object -First 2) -Join '-') -notin $MinerNames } | ForEach-Object { Remove-Item -Path $_ -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue }
    }

    If ($ObsoleteStatFiles.Count -gt 0) { 
        "Removing obsolete stat files from miners that no longer exist..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        $ObsoleteStatFiles | ForEach-Object { 
            Remove-Item -Path $_ -Force
            "Removed '$_'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        }
    }

    # Remove temp files
    "Removing temporary files..." | Tee-Object -FilePath $UpdateLog -Append | Write-Message -Level Verbose
    Remove-Item .\$UpdateFileName -Force -Recurse
    Remove-Item ".\$($UpdateFileName).zip" -Force
    If (Test-Path -Path ".\PreUpdateActions.ps1" -PathType Leaf) { 
        Remove-Item ".\PreUpdateActions.ps1" -Force
        "Removed '.\PreUpdateActions.ps1'."
    }
    If (Test-Path -Path ".\PostUpdateActions.ps1" -PathType Leaf) { 
        Remove-Item ".\PostUpdateActions.ps1" -Force
        "Removed '.\PostUpdateActions.ps1'."
    }
    Get-ChildItem -Path "AutoupdateBackup_*.zip" -File | Where-Object { $_.name -ne $BackupFile } | Sort-Object LastWriteTime -Descending | Select-Object -SkipLast 2 | ForEach-Object { Remove-Item -Path $_ -Force -Recurse; "Removed '$_'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue }
    Get-ChildItem -Path ".\Logs\AutoupdateBackup_*.zip" -File | Where-Object { $_.name -ne $UpdateLog } | Sort-Object LastWriteTime -Descending | Select-Object -SkipLast 2 | ForEach-Object { Remove-Item -Path $_ -Force -Recurse; "Removed '$_'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue }

    # Start new instance
    If ($UpdateVersion.RequireRestart -or $NemosMinerFileHash -ne (Get-FileHash ".\$($Variables.CurrentProduct).ps1").Hash) { 
        "Starting updated version..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        $StartCommand = (Get-Process -Id $PID).CommandLine
        $NewKid = Invoke-CimMethod -ClassName Win32_Process -MethodName "Create" -Arguments @{ CommandLine = "$StartCommand"; CurrentDirectory = $Variables.MainPath }
        Start-Sleep 5

        # Giving 10 seconds for process to start
        $Waited = 0
        While (-not (Get-Process -Id $NewKid.ProcessId -ErrorAction SilentlyContinue) -and ($waited -le 10)) { Start-Sleep -Seconds 1; $waited++ }
        If (-not (Get-Process -Id $NewKid.ProcessId -ErrorAction SilentlyContinue)) { 
            "Failed to start new instance of $($Variables.CurrentProduct)." | Tee-Object $UpdateLog -Append | Write-Message -Level Error
            Return
        }
    }

    $VersionTable = (Get-Content -Path ".\Version.txt").trim() | ConvertFrom-Json -AsHashtable
    $VersionTable | Add-Member @{ AutoUpdated = ((Get-Date).DateTime) } -Force
    $VersionTable | ConvertTo-Json | Out-File -FilePath ".\Version.txt" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue

    "Successfully updated $($UpdateVersion.Product) to version $($UpdateVersion.Version)." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose

    # Display changelog
    Notepad .\ChangeLog.txt

    If ($NewKid.ProcessId) { 
        # Kill old instance
        "Killing old instance..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        Start-Sleep -Seconds 2
        If (Get-Process -Id $NewKid.ProcessId) { Stop-Process -Id $PID }
    }
}

Function Start-LogReader { 

    If ((Test-Path $Config.SnakeTailExe -PathType Leaf -ErrorAction Ignore) -and (Test-Path $Config.SnakeTailConfig -PathType Leaf -ErrorAction Ignore)) { 
        $Variables.SnakeTailConfig = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.SnakeTailConfig)
        $Variables.SnakeTailExe = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.SnakeTailExe)
        If ($SnaketailProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -EQ "$($Variables.SnakeTailExe) $($Variables.SnakeTailConfig)")) { 
            # Activate existing Snaketail window
            $MainWindowHandle = (Get-Process -Id $SnaketailProcess.ProcessId).MainWindowHandle
            If (@($SnaketailMainWindowHandle).Count -eq 1) { 
                [Void][Win32]::ShowWindowAsync($MainWindowHandle, 6) # SW_MINIMIZE 
                [Void][Win32]::ShowWindowAsync($MainWindowHandle, 9) # SW_RESTORE
            }
        }
        Else { 
            [Void](Invoke-CreateProcess -BinaryPath $Variables.SnakeTailExe -ArgumentList $Variables.SnakeTailConfig -WorkingDirectory (Split-Path $Variables.SnakeTailExe) -MinerWindowStyle "Normal" -Priority "-2" -EnvBlock $null -LogFile $null -JobName "Snaketail")
        }
    }
}

Function Update-ConfigFile { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    # Changed config items
    $Config.GetEnumerator().Name | ForEach-Object { 
        Switch ($_) { 
            "ActiveMinergain" { $Config.MinerSwitchingThreshold = $Config.$_; $Config.Remove($_) }
            "AutoStart" { 
                If ($Config.$_ -eq $true) { 
                    If ($Config.StartPaused -eq $true) { $Config.StartupMode = "Paused" }
                    Else { $Config.StartupMode = "Running" }
                }
                Else { $Config.StartupMode = "Idle" }
                $Config.Remove($_)
                $Config.Remove("StartPaused")
            }
            "APIKEY" { $Config.MiningPoolHubAPIKey = $Config.$_; $Config.Remove($_) }
            "BalancesTrackerConfigFile" { $Config.Remove($_) }
            "EnableEarningsTrackerLog" { $Config.EnableBalancesLog = $Config.$_; $Config.Remove($_) }
            "IgnoreRejectedShares" { $Config.DeductRejectedShares = $Config.$_; $Config.Remove($_) }
            "Location" { $Config.Region = $Config.$_; $Config.Remove($_) }
            "MPHAPIKey" { $Config.MiningPoolHubAPIKey = $Config.$_; $Config.Remove($_) }
            "MPHUserName"  { $Config.MiningPoolHubUserName = $Config.$_; $Config.Remove($_) }
            "NoDualAlgoMining" { $Config.DisableDualAlgoMining = $Config.$_; $Config.Remove($_) }
            "NoSingleAlgoMining" { $Config.DisableSingleAlgoMining = $Config.$_; $Config.Remove($_) }
            "PasswordCurrency" { $Config.PayoutCurrency = $Config.$_; $Config.Remove($_) }
            "PricePenaltyFactor" { $Config.EarningsAdjustmentFactor = $Config.$_; $Config.Remove($_) }
            "ReadPowerUsage" { $Config.CalculatePowerCost = $Config.$_; $Config.Remove($_) }
            "RunningMinerGainPct" { $Config.MinerSwitchingThreshold = $Config.$_; $Config.Remove($_) }
            "ShowMinerWindows" { $Config.MinerWindowStyle = $Config.$_; $Config.Remove($_) }
            "ShowMinerWindowsNormalWhenBenchmarking" { $Config.MinerWindowStyleNormalWhenBenchmarking = $Config.$_; $Config.Remove($_) }
            "SSL" { $Config.Remove($_) }
            "UserName" { 
                If (-not $Config.MiningPoolHubUserName) { $Config.MiningPoolHubUserName = $Config.$_ }
                If (-not $Config.ProHashingUserName) { $Config.ProHashingUserName = $Config.$_ }
                $Config.Remove($_)
            }
            "Wallet" { 
                If (-not $Config.Wallets) { $Config | Add-Member @{ Wallets = $Variables.AllCommandLineParameters.Wallets } }
                $Config.Wallets.BTC = $Config.$_
                $Config.Remove($_)
            }
            "WaitForMinerData" { $Config.Remove($_) }
            "WarmupTime" { $Config.Remove($_) }
            Default { If ($_ -notin @(@($Variables.AllCommandLineParameters.Keys) + @("PoolsConfig"))) { $Config.Remove($_) } } # Remove unsupported config item
        }
    }

    # Add new config items
    If ($New_Config_Items = $Variables.AllCommandLineParameters.Keys | Where-Object { $_ -notin $Config.Keys }) { 
        $New_Config_Items | Sort-Object Name | ForEach-Object { 
            $Value = $Variables.AllCommandLineParameters.$_
            If ($Value -is [Switch]) { $Value = [Boolean]$Value }
            $Config.$_ = $Value
        }
        Remove-Variable Value -ErrorAction Ignore
    }

    # Change currency names, remove mBTC
    If ($Config.Currency -is [Array]) { 
        $Config.Currency = $Config.Currency | Select-Object -First 1
        $Config.ExtraCurrencies = @($Config.Currency | Select-Object -Skip 1 | Where-Object { $_ -ne "mBTC" } | Select-Object)
    }

    # Move [PayoutCurrency] wallet to wallets
    If ($PoolsConfig = Get-Content .\Config\PoolsConfig.json -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore) { 
        ($PoolsConfig | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
            If (-not $PoolsConfig.$_.Wallets -and $PoolsConfig.$_.Wallet) { 
                $PoolsConfig.$_ | Add-Member Wallets @{ "$($PoolsConfig.$_.PayoutCurrency)" = $PoolsConfig.$_.Wallet } -ErrorAction Ignore
                $PoolsConfig.$_.PSObject.Members.Remove("Wallet")
            }
        }
        $PoolsConfig | ConvertTo-Json | Out-File -FilePath .\Config\PoolsConfig.json -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    }

    # Rename MPH to MiningPoolHub
    $Config.PoolName = $Config.PoolName -replace "MPH", "MiningPoolHub"
    $Config.PoolName = $Config.PoolName -replace "MPHCoins", "MiningPoolHubCoins"

    # Available regions have changed
    If (-not (Get-Region $Config.Region -List)) { 
        # Write message about new mining regions
        Switch ($Config.Region) { 
            "Brazil"   { $Config.Region = "USA West" }
            "Europe"   { $Config.Region = "Europe West" }
            "HongKong" { $Config.Region = "Asia" }
            "India"    { $Config.Region = "Asia" }
            "Japan"    { $Config.Region = "Japan" }
            "Russia"   { $Config.Region = "Russia" }
            "US"       { $Config.Region = "USA West" }
            Default    { $Config.Region = "Europe West" }
        }
        Write-Message -Level Warn "Available mining locations have changed. Please verify your configuration."
    }

    # Remove AHashPool
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "AhashPool*" }

    $Config | Add-Member ConfigFileVersion ($Variables.CurrentVersion.ToString()) -Force
    Write-Config -ConfigFile $ConfigFile
    "Updated configuration file '$($ConfigFile)' to version $($Variables.CurrentVersion.ToString())." | Write-Message -Level Verbose 
    Remove-Variable New_Config_Items -ErrorAction Ignore
}

Function Remove-OrphanedMinerStats { 

    $MinerNames = @(Get-ChildItem ".\Miners\*.ps1").BaseName
    $TempStatNames = @($Stats.Keys | Where-Object { $_ -match "_Hashrate$|_PowerUsage$" } | Where-Object { (($_ -split "-" | Select-Object -First 2) -join "-") -notin $MinerNames})
    If ($TempStatNames) { $TempStatNames | ForEach-Object { Remove-Stat $_ } }

    $TempStatNames
}

Function Test-Prime { 

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Number
    )

    For ([Int64]$i = 2; $i -lt [Int64][Math]::Pow($Number, 0.5); $i++) { If ($Number % $i -eq 0) { Return $false } }

    Return $true
}

Function Get-DAGsize { 

    Param(
        [Parameter(Mandatory = $false)]
        [Double]$Block = ((Get-Date) - [DateTime]"07/31/2015").Days * 6400,
        [Parameter(Mandatory = $false)]
        [String]$Coin
    )

    Switch ($Coin) { 
        "ETC"   { $Epoch_Length = If ($Block -ge 11700000 ) { 60000 } Else { 30000 } }
        "RVN"   { $Epoch_Length = 7500 }
        Default { $Epoch_Length = 30000 }
    }

    $DATASET_BYTES_INIT = [Math]::Pow(2, 30)
    $DATASET_BYTES_GROWTH = [Math]::Pow(2, 23)
    $MIX_BYTES = 128

    $Size = $DATASET_BYTES_INIT + $DATASET_BYTES_GROWTH * [Math]::Floor($Block / $EPOCH_LENGTH)
    $Size -= $MIX_BYTES
    While (-not (Test-Prime ($Size / $MIX_BYTES))) { $Size -= 2 * $MIX_BYTES }

    Return [Int64]$Size
}

Function Out-DataTable { 

    <#
    .SYNOPSIS
    Creates a DataTable for an object
    .DESCRIPTION
    Creates a DataTable based on an objects properties.
    .INPUTS
    Object
        Any object can be piped to Out-DataTable
    .OUTPUTS
       System.Data.DataTable
    .EXAMPLE
    $dt = Get-psdrive| Out-DataTable
    This example creates a DataTable from the properties of Get-psdrive and assigns output to $dt variable
    .NOTES
    Adapted from script by Marc van Orsouw see link
    Version History
    v1.0 - Chad Miller - Initial Release
    v1.1 - Chad Miller - Fixed Issue with Properties
    v1.2 - Chad Miller - Added setting column datatype by property as suggested by emp0
    v1.3 - Chad Miller - Corrected issue with setting datatype on empty properties
    v1.4 - Chad Miller - Corrected issue with DBNull
    v1.5 - Chad Miller - Updated example
    v1.6 - Chad Miller - Added column datatype logic with default to string
    v1.7 - Chad Miller - Fixed issue with IsArray
    .LINK
    http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx
    #>

    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0, 
            Mandatory = $true, 
            ValueFromPipeline = $true
        )]
        [PSObject[]]$InputObject
    )

    Begin { 
        $DT = New-Object Data.datatable
        $First = $true
    }
    Process { 
        ForEach ($Object in $InputObject) { 
            $DR = $DT.NewRow()
            ForEach ($Property in $Object.PSObject.Properties) { 
                If ($First) { 
                    $Col = New-Object Data.DataColumn
                    $Col.ColumnName = $Property.Name.ToString()
                    If ($Property.Value) { 
                        If ($Property.Value -isnot [System.DBNull]) { 
                            $Col.DataType = [System.Type]::GetType($Property.TypeNameOfValue).Name
                        }
                    }
                    $DT.Columns.Add($Col)
                }
                If ($Property.GetType().IsArray) { 
                    $DR.Item($Property.Name) = $Property.Value | ConvertTo-Xml -As String -NoTypeInformation -Depth 1
                }
                Else { 
                    $DR.Item($Property.Name) = $Property.Value
                }
            }
            $DT.Rows.Add($DR)
            $First = $false
        }
    }

    End { 
        Write-Output @(,($dt))
    }
}
