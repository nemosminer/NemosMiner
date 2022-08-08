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
Version:        4.0.2.6
Version date:   07 August 2022
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
    [String]$Architecture
    [Int]$Bus
    [Int]$Bus_Index
    [Int]$Bus_Type_Index
    [Int]$Bus_Platform_Index
    [Int]$Bus_Vendor_Index
    [PSCustomObject]$CIM
    [Double]$ConfiguredPowerUsage = 0 # Workaround if device does not expose power usage
    [PSCustomObject]$CpuFeatures
    [Int]$Id
    [Int]$Index = 0
    [Int64]$Memory
    [String]$Model
    [Double]$MemoryGB
    [String]$Name
    [PSCustomObject]$OpenCL = [PSCustomObject]@{ }
    [Int]$PlatformId = 0
    [Int]$PlatformId_Index
    [PSCustomObject]$PNP
    [Boolean]$ReadPowerUsage = $false
    [PSCustomObject]$Reg
    [Int]$Slot = 0
    [String]$Status = "Idle"
    [DeviceState]$State = [DeviceState]::Enabled
    [String]$Type
    [Int]$Type_Id
    [Int]$Type_Index
    [Int]$Type_PlatformId_Index
    [Int]$Type_Slot
    [Int]$Type_Vendor_Id
    [Int]$Type_Vendor_Index
    [Int]$Type_Vendor_Slot
    [String]$Vendor
    [Int]$Vendor_Id
    [Int]$Vendor_Index
    [Int]$Vendor_Slot
}

Enum DeviceState { 
    Enabled
    Disabled
    Unsupported
}

Class Pool { 
    [Double]$Accuracy
    [String]$Algorithm
    [Boolean]$Available = $true
    [String]$BaseName
    [Boolean]$Best = $false
    [Nullable[Int64]]$BlockHeight = $null
    [String]$CoinName
    [String]$Currency
    [Nullable[Double]]$DAGsizeGB = $null
    [Double]$EarningsAdjustmentFactor = 1
    [Nullable[Int]]$Epoch = $null
    [Double]$Fee
    [String]$Host
    # [String[]]$Hosts # To be implemented for pool failover
    [String]$Name
    [String]$Pass
    [UInt16]$Port
    [Double]$Price
    [Double]$Price_Bias
    [String[]]$Reasons = @()
    [String]$Region
    [Boolean]$SSL
    [Double]$StablePrice
    [DateTime]$Updated = (Get-Date).ToUniversalTime()
    [String]$User
    [String]$WorkerName = ""
    [Nullable[Int]]$Workers
}

Class Worker { 
    [Boolean]$Disabled
    [Double]$Earning
    [Double]$Earning_Bias
    [Double]$Earning_Accuracy
    [Double]$Fee
    [Double]$Hashrate
    [Pool]$Pool
    [TimeSpan]$TotalMiningDuration
    [DateTime]$Updated
}

Enum MinerStatus { 
    Running
    Idle
    Failed
    Disabled
}

Class Miner { 
    [Int]$Activated = 0
    [String[]]$Algorithms # derived from workers
    [String]$API
    [String]$Arguments
    [Boolean]$Available = $true
    [String]$BaseName
    [DateTime]$BeginTime
    [Boolean]$Benchmark = $false # derived from stats
    [Boolean]$Best = $false
    [String]$CommandLine
    [Int]$DataCollectInterval = 5 # Seconds
    [String[]]$DeviceNames = @() # derived from devices
    [Device[]]$Devices = @()
    [Boolean]$Disabled = $false
    [Double]$Earning # derived from pool and stats
    [Double]$Earning_Bias # derived from pool and stats
    [Double]$Earning_Accuracy # derived from pool and stats
    [DateTime]$EndTime
    [String[]]$EnvVars = @()
    [Double[]]$Hashrates_Live = @()
    [String]$Info
    [Boolean]$KeepRunning = $false # do not stop miner even if not best (MinInterval)
    [String]$LogFile
    [Boolean]$MeasurePowerUsage = $false
    [Int]$MinDataSamples # for safe hashrate values
    [String]$MinerUri
    [Bool]$MostProfitable
    [String]$Name
    [String]$Path
    [String]$PrerequisitePath
    [String]$PrerequisiteURI
    [UInt16]$Port
    [Double]$PowerCost
    [Double]$PowerUsage
    [Double]$PowerUsage_Live = [Double]::NaN
    [Boolean]$Prioritize = $false # derived from BalancesKeepAlive
    [Int32]$ProcessId = 0
    [Int]$ProcessPriority = -1
    [Double]$Profit
    [Double]$Profit_Bias
    [Boolean]$ReadPowerUsage = $false
    [String[]]$Reasons # Why is a miner unavailable?
    [Boolean]$Restart = $false 
    hidden [DateTime]$StatStart
    hidden [DateTime]$StatEnd
    [MinerStatus]$Status = [MinerStatus]::Idle
    [String]$StatusMessage
    [TimeSpan]$TotalMiningDuration # derived from pool and stats
    [String]$Type
    [DateTime]$Updated
    [String]$URI
    [Worker[]]$Workers = @()
    [Worker[]]$WorkersRunning = @()
    [String]$Version
    [Int[]]$WarmupTimes # First value: time (in seconds) until first hashrate sample is valid (default 0, accept first sample), second value: time (in seconds) the miner is allowed to warm up, e.g. to compile the binaries or to get the API ready and providing first data samples before it get marked as failed (default 15)
    [String]$WindowStyle = "minimized"

    hidden [PSCustomObject[]]$Data = $null
    hidden [System.Management.Automation.Job]$DataReaderJob = $null
    hidden [System.Management.Automation.Job]$Process = $null
    hidden [TimeSpan]$Active = [TimeSpan]::Zero

    [String[]]GetProcessNames() { 
        Return @(([IO.FileInfo]($this.Path | Split-Path -Leaf)).BaseName)
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
                $ProgressPreference = "SilentlyContinue"
                $Miner = ($args[1] | ConvertFrom-Json) -as $args[0]
                Start-Sleep -Seconds 2
                While ($true) { 
                    $NextLoop = (Get-Date).AddSeconds($Miner.DataCollectInterval)
                    $Miner.GetMinerData()
                    While ((Get-Date) -lt $NextLoop) { Start-Sleep -Milliseconds 50 }
                }
                Remove-Variable Miner, NextLoop
            }
            Catch { 
                Return $Error[0]
            }
        }
        # Start Miner data reader
        $this | Add-Member -Force @{ DataReaderJob = Start-ThreadJob -Name "$($this.Name)_DataReader" -ThrottleLimit 99 -InitializationScript ([ScriptBlock]::Create("Set-Location('$(Get-Location)')")) -ScriptBlock $ScriptBlock -ArgumentList ($this.API), ($this | Select-Object -Property Algorithms, DataCollectInterval, Devices, Name, Path, Port, ReadPowerUsage, LogFile | ConvertTo-Json -WarningAction Ignore) }
    }

    hidden StopDataReader() { 
        # Before stopping read data
        If ($this.DataReaderJob.HasMoreData) { $this.Data += @($this.DataReaderJob | Receive-Job | Select-Object) }
        $this.DataReaderJob | Stop-Job | Remove-Job -Force
    }

    hidden RestartDataReader() { 
        $this.StopDataReader()
        $this.StartDataReader()
    }

    hidden StartMining() { 
        $this.Status = [MinerStatus]::Idle
        $this.Info = "{$(($this.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"
        $this.StatusMessage = "Starting $($this.Info)"
        $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
        $this.Activated++

        Write-Message -Level Info "Starting miner '$($this.Name) $($this.Info)'..."

        If (Test-Json $this.Arguments -ErrorAction Ignore) { $this.CreateConfigFiles() }

        If ($this.Process) { 
            If ($this.Process | Get-Job -ErrorAction SilentlyContinue) { 
                $this.Process | Remove-Job -Force
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
                Accounts          = ($this.Workers.Pool.User | ForEach-Object { $_ -split "\." | Select-Object -First 1 } | Select-Object -Unique) -join "; "
                Algorithms        = $this.Workers.Pool.Algorithm -join "; "
                Benchmark         = $this.Benchmark
                CommandLine       = $this.CommandLine
                DeviceNames       = $this.DeviceNames -join "; "
                Duration          = ""
                Earning           = $this.Earning
                Earning_Bias      = $this.Earning_Bias
                LastDataSample    = $null
                MeasurePowerUsage = $this.MeasurePowerUsage
                Pools              = ($this.Workers.Pool.Name | Select-Object -Unique) -join "; "
                Profit            = $this.Profit
                Profit_Bias       = $this.Profit_Bias
                Reason            = ""
                Type              = $this.Type
            } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation

            If ($this.Process | Get-Job -ErrorAction SilentlyContinue) { 
                0..20 | ForEach-Object { 
                        If ($this.ProcessId = [Int32]((Get-CimInstance CIM_Process | Where-Object { $_.ExecutablePath -eq $this.Path -and $_.CommandLine -eq "$($this.Path) $($this.GetCommandLineParameters())" }).ProcessId)) { 
                        $this.StatusMessage = "Warming up $($this.Info)"
                        $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
                        $this.StatStart = $this.BeginTime = (Get-Date).ToUniversalTime()
                        $this.Hashrates_Live = @($this.Workers | ForEach-Object { [Double]::NaN })
                        $this.WorkersRunning = $this.Workers
                        $this.StartDataReader()
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
            Write-Message -Level Info $this.StatusMessage
        }
        Else { 
            Write-Message -Level Error $this.StatusMessage
        }

        # Stop Miner data reader
        $this.StopDataReader()

        $this.EndTime = (Get-Date).ToUniversalTime()

        If ($this.ProcessId) { 
            If (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue) { 
                Stop-Process -Id $this.ProcessId -Force
            }
            $this.ProcessId = $null
        }
        If ($this.Process) { 
            $this.Process | Remove-Job -Force
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
            Accounts          = ($this.WorkersRunning.Pool.User | ForEach-Object { $_ -split "\." | Select-Object -First 1 } | Select-Object -Unique) -join "; "
            Algorithms        = $this.WorkersRunning.Pool.Algorithm -join "; "
            Benchmark         = $this.Benchmark
            CommandLine       = ""
            DeviceNames       = $this.DeviceNames -join "; "
            Duration          = "{0:hh\:mm\:ss}" -f ($this.EndTime - $this.BeginTime)
            Earning           = $this.Earning
            Earning_Bias      = $this.Earning_Bias
            LastDataSample    = $this.Data | Select-Object -Last 1 | ConvertTo-Json -Compress
            MeasurePowerUsage = $this.MeasurePowerUsage
            Pools             = ($this.WorkersRunning.Pool.Name | Select-Object -Unique) -join "; "
            Profit            = $this.Profit
            Profit_Bias       = $this.Profit_Bias
            Reason            = If ($this.Status -eq [MinerStatus]::Failed) { $this.StatusMessage } Else { "" }
            Type              = $this.Type
        } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation

        $this.StatusMessage = If ($this.Status -eq [MinerStatus]::Idle) { "Idle" } Else { "Failed $($this.Info)" }
    }

    [DateTime]GetActiveLast() { 
        If ($this.Process.PSBeginTime -and $this.Process.PSEndTime) { 
            Return $this.Process.PSEndTime
        }
        ElseIf ($this.Process.PSBeginTime) { 
            Return [DateTime]::Now
        }
        Else { 
            Return [DateTime]::MinValue
        }
    }

    [TimeSpan]GetActiveTime() { 
        If ($this.Process.PSBeginTime -and $this.Process.PSEndTime) { 
            Return $this.Active + ($this.Process.PSEndTime - $this.Process.PSBeginTime)
        }
        ElseIf ($this.Process.PSBeginTime) { 
            Return $this.Active + ([DateTime]::Now - $this.Process.PSBeginTime)
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

        # Read power usage from HwINFO64 reg key, otherwise use hardconfigured value
        $RegistryData = Get-ItemProperty $RegistryHive
        ForEach ($Device in $this.Devices) { 
            If ($RegistryEntry = $RegistryData.PSObject.Properties | Where-Object { ($_.Value -split " ") -contains $Device.Name }) { 
                $TotalPowerUsage += [Double]($RegistryData.($RegistryEntry.Name -replace "Label", "Value") -split ' ' | Select-Object -First 1)
            }
            Else { 
                $TotalPowerUsage += [Double]$Device.ConfiguredPowerUsage
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
        $this.Available = $true
        $this.Benchmark = $false
        $this.Best = $false
        $this.Disabled = $false
        $this.Earning = [Double]::NaN
        $this.Earning_Accuracy = 0
        $this.Earning_Bias = [Double]::NaN
        $this.MeasurePowerUsage = $false
        $this.PowerCost = [Double]::NaN
        $this.PowerUsage = [Double]::NaN
        $this.Prioritize = $false
        $this.Profit = [Double]::NaN
        $this.Profit_Bias = [Double]::NaN
        $this.Reasons = @()

        $this.Workers | ForEach-Object { 
            If ($Stat = Get-Stat "$($this.Name)_$($_.Pool.Algorithm)_Hashrate") { 
                $_.Hashrate = $Stat.Hour
                $Factor = $_.Hashrate * (1 - $_.Fee - $_.Pool.Fee)
                $_.Disabled = $Stat.Disabled
                $_.Earning = $_.Pool.Price * $Factor
                $_.Earning_Accuracy = $_.Pool.Accuracy
                $_.Earning_Bias = $_.Pool.Price_Bias * $Factor
                $_.TotalMiningDuration = $Stat.Duration
                $_.Updated = $Stat.Updated
            }
            Else { 
                $_.Disabled = $false
                $_.Hashrate = [Double]::NaN
            }
            If ($_.Pool.Reasons -contains "Prioritized by BalancesKeepAlive") { $this.Prioritize = $true }
        }

        $this.Earning = ($this.Workers.Earning | Measure-Object -Sum).Sum
        $this.Earning_Bias = ($this.Workers.Earning_Bias | Measure-Object -Sum).Sum

        If ($this.Workers[0].Hashrate -EQ 0) { # Allow 0 hashrate on secondary algorithm
            $this.Status = [MinerStatus]::Failed
            $this.Available = $false
            $this.Earning = [Double]::NaN
            $this.Earning_Bias = [Double]::NaN
            $this.Earning_Accuracy = [Double]::NaN
        }
        ElseIf ($this.Workers | Where-Object { [Double]::IsNaN($_.Hashrate) }) { 
            $this.Benchmark = $true
            $this.Earning = [Double]::NaN
            $this.Earning_Bias = [Double]::NaN
            $this.Earning_Accuracy = [Double]::NaN
        }
        ElseIf ($this.Earning -eq 0) { $this.Earning_Accuracy = 0 }
        Else { $this.Workers | ForEach-Object { $this.Earning_Accuracy += ($_.Earning_Accuracy * $_.Earning / $this.Earning) } }

        If ($this.Workers | Where-Object Disabled) { 
            $this.Status = [MinerStatus]::Disabled
            $this.Available = $false
            $this.Disabled = $true
        }

        $this.TotalMiningDuration = ($this.Workers.TotalMiningDuration | Measure-Object -Minimum).Minimum
        $this.Updated = ($this.Workers.Updated | Measure-Object -Minimum).Minimum

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
        Remove-Variable Factor, Stat -ErrorAction Ignore
    }
}
Function Start-IdleDetection { 

    # Function tracks how long the system has been idle and controls the paused state
    $Variables.IdleRunspace = [runspacefactory]::CreateRunspace()
    $Variables.IdleRunspace.Open()
    $Variables.IdleRunspace.SessionStateProxy.SetVariable('Config', $Config)
    $Variables.IdleRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
    $Variables.IdleRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
    $Variables.IdleRunspace | Add-Member MiningStatus "Running" -Force

    $PowerShell = [PowerShell]::Create()
    $PowerShell.Runspace = $Variables.IdleRunspace
    $PowerShell.AddScript(
        { 
            # Set the starting directory
            Set-Location (Split-Path $MyInvocation.MyCommand.Path)

            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

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

            $Variables.IdleRunspace | Add-Member NewMiningStatus "Idle" -Force

            Write-Message -Level Verbose "Started idle detection."

            While ($true) { 
                $IdleSeconds = [Math]::Round(([PInvoke.Win32.UserInput]::IdleTime).TotalSeconds)

                # Activity detected, pause mining
                If ($IdleSeconds -lt $Config.IdleSec -and $Variables.IdleRunspace.MiningStatus -ne "Idle") { 
                    $Variables.IdleRunspace | Add-Member MiningStatus "Idle" -Force

                    $LabelMiningStatus.Text = "Idle | $($Variables.Branding.ProductLabel) $($Variables.Branding.Version)"
                    $LabelMiningStatus.ForeColor = [System.Drawing.Color]::Green
                }

                # System has been idle long enough, start mining
                If ($IdleSeconds -ge $Config.IdleSec -and $Variables.IdleRunspace.MiningStatus -ne "Running") { 
                    $Variables.IdleRunspace | Add-Member MiningStatus "Running" -Force

                    $LabelMiningStatus.Text = "Running | $($Variables.Branding.ProductLabel) $($Variables.Branding.Version)"
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
        $Variables.IdleRunspace.Dispose()
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

        $Variables.CoreRunspace = [RunspaceFactory]::CreateRunspace()
        $Variables.CoreRunspace.Open()
        $Variables.CoreRunspace.SessionStateProxy.SetVariable('Config', $Config)
        $Variables.CoreRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
        $Variables.CoreRunspace.SessionStateProxy.SetVariable('Stats', $Stats)
        $Variables.CoreRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

        $PowerShell = [PowerShell]::Create()
        $PowerShell.Runspace = $Variables.CoreRunspace
        $PowerShell.AddScript("$($Variables.MainPath)\Includes\Core.ps1")
        $PowerShell.BeginInvoke()

        $Variables.CoreRunspace | Add-Member -Force @{ PowerShell = $PowerShell }

        $Variables.Summary = "Mining processes are running."
        Write-Host $Variables.Summary
    }
}

Function Stop-Mining { 

    If ($Variables.CoreRunspace) { 
        # Give core loop time to shut down gracefully
        $Timestamp = (Get-Date).AddSeconds(30)
        While (($Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running }) -and (Get-Date) -le $Timestamp) { 
            Start-Sleep -Seconds 1
        }
        $Variables.MinersBest_Combo = @()
        $Variables.Miners = @()
        $Variables.WatchdogTimers = @()
    
        $Variables.CoreRunspace.Close()
        If ($Variables.CoreRunspace.PowerShell) { $Variables.CoreRunspace.PowerShell.Dispose() }
        $Variables.CoreRunspace.Dispose()
        $Variables.Remove("Timer")
        $Variables.Remove("CoreRunspace")

        $Variables.MiningStatus = "Idle"

        $Variables.Summary = "Mining processes stopped."
        Write-Host $Variables.Summary
    }
}

Function Start-Brain { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Brains
    )

    If (-not $Variables.BrainRunspacePool) { 

        # https://stackoverflow.com/questions/38102068/sessionstateproxy-variable-with-runspace-pools
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

        # Create the sessionstate variable entries
        @("Config", "Variables") | ForEach-Object { 
            $InitialSessionState.Variables.Add((New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $_, (Get-Variable $_ -ValueOnly), $Null))
        }

        $Variables.BrainRunspacePool = [RunspaceFactory]::CreateRunspacePool(1, (Get-Item -Path ".\Brains\*.ps1").Count, $InitialSessionState, $Host)
        $Variables.BrainRunspacePool.Open()
        $Variables.Brains = @{ }
        $Variables.BrainData = [PSCustomObject]@{ }
        Remove-Variable InitialSessionState
    }

    # Starts Brains if necessary
    $BrainsStarted = @()
    $Brains | Select-Object | ForEach-Object { 
        If ($Config.PoolsConfig.$_.BrainConfig -and -not $Variables.Brains.$_) { 
            $BrainScript = ".\Brains\$($_).ps1"
            If (Test-Path -Path $BrainScript -PathType Leaf) {  
                $PowerShell = [powershell]::Create()
                $PowerShell.RunspacePool = $Variables.BrainRunspacePool
                $PowerShell.AddScript($BrainScript)
                $Variables.Brains.$_ = @{ Handle = $PowerShell.BeginInvoke(); PowerShell = $PowerShell }
                $BrainsStarted += $_
            }
        }
    }

    If ($BrainsStarted.Count -gt 0) { Write-Message -Level Info "Pool Brain Job$(If ($BrainsStarted.Count -gt 1) { "s" }) for '$(($BrainsStarted | Sort-Object) -join ", ")' started." }

    Remove-Variable BrainsStarted, PowerShell
}

Function Stop-Brain { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Brains = $Variables.Brains.Keys
    )

    If ($Brains) { 
        $BrainsStopped = @()

        $Brains | ForEach-Object { 
            # Stop Brains
            $Variables.Brains.$_.PowerShell.Dispose()
            $Variables.Brains.Remove($_)
            $BrainsStopped += $_
        }

        [System.GC]::Collect()

        If ($BrainsStopped.Count -gt 0) { Write-Message -Level Info  "Pool Brain Job$(If ($BrainsStopped.Count -gt 1) { "s" }) for '$(($BrainsStopped | Sort-Object) -join ", ")' stopped." }

        Remove-Variable BrainsStopped
    }

    If ($Variables.BrainRunspacePool -and -not $Variables.Brains) { 
        $Variables.BrainRunspacePool.Close()
        $Variables.BrainRunspacePool.Dispose()
        $Variables.Remove("Brains")
        $Variables.Remove("BrainData")

        [System.GC]::Collect()
    }
}

Function Start-BrainJob { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Jobs
    )

    # Starts Brains if necessary
    $JobNames = @()

    $Jobs | Select-Object | ForEach-Object { 
        $BrainName = Get-PoolBaseName $_
        If ($Config.PoolsConfig.$BrainName.BrainConfig -and -not $Variables.BrainJobs.$_) { 
            $BrainScript = ".\Brains\$($BrainName).ps1"
            If (Test-Path -Path $BrainScript -PathType Leaf) { 
                $Variables.BrainJobs.$_ = Start-ThreadJob -Name "BrainJob_$($_)" -ThrottleLimit 99 -FilePath $BrainScript -ArgumentList $BrainName, $_, $Config.PoolsConfig.$BrainName.BrainConfig
                $JobNames += $_
            }
        }
    }

    If ($JobNames.Count -gt 0) { Write-Message -Level Info "Pool Brain Job$(If ($JobNames.Count -gt 1) { "s" }) for '$(($JobNames | Sort-Object) -join ", ")' running." }
}

Function Stop-BrainJob { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Jobs = $Variables.BrainJobs.Keys
    )

    If ($Jobs) { 
        $JobNames = @()

        # Stop Brains if necessary
        $Jobs | Select-Object | ForEach-Object { 
            $Variables.BrainJobs.$_ | Stop-Job -PassThru -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore
            $Variables.BrainJobs.Remove($_)
            $JobNames += $_
        }

        If ($JobNames.Count -gt 0) { Write-Message -Level Info  "Pool Brain Job$(If ($JobNames.Count -gt 1) { "s" }) for '$(($JobNames | Sort-Object) -join ", ")' stopped." }
    }
}

Function Start-BalancesTracker { 

    If (-not $Variables.BalancesTrackerRunspace) { 

        Try { 
            $Variables.Summary = "Starting Balances Tracker background process..."
            Write-Message -Level Info $Variables.Summary

            $Variables.BalancesTrackerRunspace = [runspacefactory]::CreateRunspace()
            $Variables.BalancesTrackerRunspace.Open()
            $Variables.BalancesTrackerRunspace.SessionStateProxy.SetVariable('Config', $Config)
            $Variables.BalancesTrackerRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
            $Variables.BalancesTrackerRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $Variables.BalancesTrackerRunspace
            $PowerShell.AddScript("$($Variables.MainPath)\Includes\BalancesTracker.ps1")
            $PowerShell.BeginInvoke()

            $Variables.BalancesTrackerRunspace | Add-Member -Force @{ PowerShell = $PowerShell }
        }
        Catch { 
            Write-Message -Level Error "Failed to start Balances Tracker [$Error[0]]."
        }

        Remove-Variable PowerShell
    }
}

Function Stop-BalancesTracker { 

    If ($Variables.BalancesTrackerRunspace) { 

        $Variables.BalancesTrackerRunspace.Close()
        If ($Variables.BalancesTrackerRunspace.PowerShell) { $Variables.BalancesTrackerRunspace.PowerShell.Dispose() }

        $Variables.Remove("BalancesTrackerRunspace")
        $Variables.Summary += "<br>Balances Tracker background process stopped."
        Write-Message -Level Info "Balances Tracker background process stopped."
    }
}

Function Initialize-Application { 

    # Keep only the last 10 files
    Get-ChildItem -Path ".\Logs\$($Variables.Branding.ProductLabel)_*.log" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path ".\Logs\SwitchingLog_*.csv" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path "$($Variables.ConfigFile)_*.backup" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse

    If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12 }

    # Set process priority to BelowNormal to avoid hashrate drops on systems with weak CPUs
    (Get-Process -Id $PID).PriorityClass = "BelowNormal"

    If ($Config.Proxy -eq "") { $PSDefaultParameterValues.Remove("*:Proxy") }
    Else { $PSDefaultParameterValues["*:Proxy"] = $Config.Proxy }
}

Function Get-DefaultAlgorithm { 

    If ($PoolsAlgos = Get-Content ".\Data\PoolsConfig-Recommended.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue) { Return ($PoolsAlgos.PSObject.Properties.Name | Where-Object { $_ -in @(Get-PoolBaseName $Config.PoolName) } | ForEach-Object {$PoolsAlgos.$_.Algorithm }) | Sort-Object -Unique }
    Return
}

Function Get-CommandLineParameters { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Arguments
    )

    If (Test-Json $Arguments) { Return ($Arguments | ConvertFrom-Json).Arguments }
    Return $Arguments
}

Function Get-Rate { 
    # Read exchange rates from min-api.cryptocompare.com, use stored data as fallback

    $RatesFileName = "Data\Rates.json"
    $RatesCache = Get-Content -Path $RatesFileName -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue

    $Variables.BalancesCurrencies = @($Variables.Balances.Keys | ForEach-Object { $Variables.Balances.$_.Currency } | Sort-Object -Unique)

    Try { 
        If (-not $Variables.AllCurrencies -and $RatesCache.PSObject.Properties.Name) { 
            $Variables.AllCurrencies = @($RatesCache.PSObject.Properties.Name)
        }
        Else { 
            $Variables.AllCurrencies = @(@($Config.Currency) + @($Config.Wallets.PSObject.Properties.Name) + @($Config.ExtraCurrencies) + @($Variables.BalancesCurrencies) | Sort-Object -Unique)
        }
        $Variables.AllCurrencies = @($Variables.AllCurrencies | Where-Object { $_ -replace "mBTC", "BTC" } | Sort-Object -Unique)
        If (-not $Variables.Rates.BTC.($Config.Currency) -or (Compare-Object @($Variables.Rates.PSObject.Properties.Name | Select-Object) @($Variables.AllCurrencies | Select-Object) | Where-Object SideIndicator -eq "=>") -or ($Variables.RatesUpdated -lt (Get-Date).ToUniversalTime().AddMinutes(-(3, $Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum))) { 
            If ($Rates = Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$((@("BTC") + @($Variables.AllCurrencies | Where-Object { $_ -ne "mBTC" }) | Select-Object -Unique) -join ',')&extraParams=$($Variables.Branding.BrandWebSite)" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json) { 
                $Currencies = ($Rates.BTC | Get-Member -MemberType NoteProperty).Name
                $Currencies | Where-Object { $_ -ne "BTC" } | ForEach-Object { 
                    $Currency = $_
                    $Rates | Add-Member $Currency ($Rates.BTC | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json)
                    ($Rates.$Currency | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
                        $Rates.$Currency | Add-Member $_ ([Double]$Rates.BTC.$_ / $Rates.BTC.$Currency) -Force
                    }
                }
                Write-Message -Level Info "Loaded currency exchange rates from 'min-api.cryptocompare.com'.$(If ($MissingCurrencies = Compare-Object $Currencies $Variables.AllCurrencies -PassThru) { " Warning: Could not get rates for '$($MissingCurrencies -join ', ')'." })"
                $Rates | ConvertTo-Json -Depth 5 | Out-File -FilePath $RatesFileName -Encoding utf8NoBOM -Force -ErrorAction SilentlyContinue
                $Variables.Rates = $Rates
                $Variables.RatesUpdated = (Get-Date).ToUniversalTime()
                # Add mBTC
                $Currencies | ForEach-Object { 
                    $Currency = $_
                    $mCurrency = "m$($Currency)"
                    $Rates | Add-Member $mCurrency ($Rates.$Currency | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json)
                    ($Rates.$mCurrency | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
                        $Rates.$mCurrency | Add-Member $_ ([Double]$Rates.$Currency.$_ / 1000) -Force
                    }
                }
                ($Rates | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
                    $Currency = $_
                    ($Rates | Get-Member -MemberType NoteProperty).Name | Where-Object { $_ -in $Currencies } | ForEach-Object { 
                        $mCurrency = "m$($_)"
                        $Rates.$Currency | Add-Member $mCurrency ([Double]$Rates.$Currency.$_ * 1000)
                    }
                }
            }
            Else { 
                If ($RatesCache.PSObject.Properties.Name) { 
                    $Variables.Rates = $RatesCache
                    Write-Message -Level Warn "Could not load exchange rates from CryptoCompare. Using stored data from $((Get-Item -Path $RatesFileName).CreationTime)."
                }
                Else { 
                    Write-Message -Level Warn "Could not load exchange rates from CryptoCompare."
                }
            }
        }
    }
    Catch { 
        If ($RatesCache.PSObject.Properties.Name) { 
            $Variables.Rates = $RatesCache
            $Variables.RatesUpdated = "FromFile: $((Get-Item -Path $RatesFileName).CreationTime.ToUniversalTime())"
            Write-Message -Level Warn "Could not load exchange rates from CryptoCompare. Using cached data from $((Get-Item -Path $RatesFileName).CreationTime)."
        }
        Else { 
            Write-Message -Level Warn "Could not load exchange rates from CryptoCompare."
        }
    }

    Remove-Variable Currency, mCurrency, RatesCache, RatesFileName
}

Function Write-Message { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Message, 
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info", "Verbose", "Debug")]
        [String]$Level = "Info"
    )

    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    If ($Config.LogToScreen -and $Level -in $Config.LogToScreen) { 
        # Update status text box in GUI
        If ($Variables.LabelStatus) { 
            $Variables.LabelStatus.Lines += "$Date $($Level.ToUpper()): $Message"

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
        # Get mutex. Mutexes are shared across all threads and processes. 
        # This lets us ensure only one thread is trying to write to the file at a time. 
        $Mutex = New-Object System.Threading.Mutex($false, "$($Variables.LogFile -replace '[^A-Z0-9]')")

        # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, write to the log file and release mutex. Otherwise, display an error. 
        If ($Mutex.WaitOne(1000)) { 


            "$Date $($Level.ToUpper()): $Message" | Out-File -FilePath $Variables.LogFile -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            [void]$Mutex.ReleaseMutex()
        }
        Else { 
            Write-Error -Message "Log file is locked, unable to write message to $($Variables.LogFile)."
        }

        Remove-Variable Date, Mutex
    }
}

Function Update-MonitoringData { 

    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip If server and user aren't filled out
    If (-not $Config.MonitoringServer) { Return }
    If (-not $Config.MonitoringUser) { Return }

    $Version = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version.ToString())"
    $Status = $Variables.NewMiningStatus

    # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
    # reveal someone's windows username or other system information they might not want sent
    # For the ones that can be an array, comma separate them
    $Data = @(
        $Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running } | Sort-Object DeviceName | ForEach-Object { 
            [PSCustomObject]@{ 
                Algorithm      = $_.WorkersRunning.Pool.Algorithm -join ','
                Currency       = $Config.Currency
                CurrentSpeed   = $_.Hashrates_Live
                Earning        = $_.Earning
                EstimatedSpeed = $_.Workers.Hashrate
                Name           = $_.Name
                Path           = Resolve-Path -Relative $_.Path
                Pool           = $_.WorkersRunning.Pool.Name -join ','
                Profit         = $_.Profit
                Type           = $_.Type -join ','
            }
        }
    )

    $Body = @{ 
        user    = $Config.MonitoringUser
        worker  = $Config.WorkerName
        version = $Version
        status  = $Status
        profit  = If ([Double]::IsNaN($Variables.MiningProfit)) { "n/a" } Else { [String]($Variables.MiningProfit - $Variables.BasePowerCostBTC) } # Earnings is NOT profit! Needs to be changed in mining monitor server
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

    Remove-Variable Body, Data, Response, Status, Version
}

Function Read-MonitoringData { 

    If ($Config.ShowWorkerStatus -and $Config.MonitoringUser -and $Config.MonitoringServer -and $Variables.WorkersLastUpdated -lt (Get-Date).AddSeconds(-30)) { 
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
            $Variables.Workers = $Workers
            $Variables.WorkersLastUpdated = (Get-Date)

            Write-Message -Level Verbose "Retrieved worker status from '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
        Catch { 
            Write-Message -Level Warn "Monitoring: Unable to retrieve worker data from '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
    }

    Remove-Variable Workers -ErrorAction Ignore
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
        $PoolConfig.WorkerName = "$($Variables.Branding.ProductLabel)-$($Variables.Branding.Version.ToString())-donate$($Config.Donate)"
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

    Remove-Variable PoolConfig
}

Function Read-Config { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    Function Get-DefaultConfig { 
        $Config.ConfigFileVersion = $Variables.Branding.Version.ToString()
        $Variables.FreshConfig = $true

        # Add default enabled pools
        If (Test-Path -Path ".\Data\PoolsConfig-Recommended.json" -PathType Leaf) { 
            $Temp = (Get-Content ".\Data\PoolsConfig-Recommended.json" | ConvertFrom-Json)
            $Config.PoolName = $Temp.PSObject.Properties.Name | Where-Object { $_ -ne "Default" } | ForEach-Object { $Temp.$_.Variant.PSObject.Properties.Name }
            Remove-Variable Temp
        }

        # Add default config items
        $Variables.AllCommandLineParameters.Keys | Where-Object { $_ -notin $Config.Keys } | Sort-Object | ForEach-Object { 
            $Value = $Variables.AllCommandLineParameters.$_
            If ($Value -is [Switch]) { $Value = [Boolean]$Value }
            $Config.$_ = $Value
        }
        # MinerInstancePerDeviceModel: Default to $true if more than one device model per vendor
        $Config.MinerInstancePerDeviceModel = ($Variables.Devices | Group-Object Vendor  | ForEach-Object { ($_.Group.Model | Sort-Object -Unique).Count } | Measure-Object -Maximum).Maximum -gt 1

        Write-Message -Level Warn "Use the configuration editor ('http://localhost:$($Config.APIPort)') to create a new configuration file."

        Return $Config
    }

    # Load the configuration
    If (Test-Path -Path $ConfigFile -PathType Leaf) { 
        $Config_Tmp = Get-Content $ConfigFile | ConvertFrom-Json | Select-Object
        If ($Config_Tmp.PSObject.Properties.Count -eq 0 -or $Config_Tmp -isnot [PSCustomObject]) { 
            $CorruptConfigFile = "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").corrupt"
            Move-Item -Path $ConfigFile $CorruptConfigFile -Force
            $Message = "Configuration file '$ConfigFile' is corrupt and was renamed to '$CorruptConfigFile'."
            Write-Message -Level Warn $Message
            $Variables.FreshConfigText = "$Message`n`nUse the configuration editor to change your settings and apply the configuration.`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!"
            $Config = Get-DefaultConfig
        }
        Else { 
            # Fix upper / lower case (Web GUI is case sensitive)
            $Config_Tmp.PSObject.Properties.Name | ForEach-Object { 
                $Config.Remove($_)
                $Config.$_ = $Config_Tmp.$_ 

                # Enforce array
                If ($Variables.AllCommandLineParameters.$_ -is [Array] -and $Config.$_ -isnot [Array]) { $Config.$_ = @($Config.$_ -replace " " -split ",") }
            }
        }
        Remove-Variable Config_Tmp
    }
    Else { 
        Write-Message -Level Warn "No valid configuration file '$ConfigFile' found."
        $Variables.FreshConfigText = "This is the first time you have started $($Variables.Branding.ProductLabel).`n`nUse the configuration editor to change your settings and apply the configuration.`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!"
        $Config = Get-DefaultConfig
    }

    $Variables.PoolData = Get-Content -Path ".\Data\PoolData.json" | ConvertFrom-Json -AsHashtable | Get-SortedObject

    # Build custom pools configuration, create case insensitive hashtable (https://stackoverflow.com/questions/24054147/powershell-hash-tables-double-key-error-a-and-a)
    If ($Variables.PoolsConfigFile -and (Test-Path -Path $Variables.PoolsConfigFile -PathType Leaf)) { 
        $CustomPoolsConfig = [Ordered]@{ }
        Try { 
            $Temp = (Get-Content $Variables.PoolsConfigFile | ConvertFrom-Json -NoEnumerate -AsHashTable)
            $Temp.Keys | Sort-Object | ForEach-Object { $CustomPoolsConfig += @{ $_ = $Temp.$_ } }
            $Variables.PoolsConfigData = $CustomPoolsConfig
        }
        Catch { 
            Write-Message -Level Warn "Pools configuration file '$($Variables.PoolsConfigFile)' is corrupt and will be ignored."
        }
    }

    # Build in memory pool config
    $PoolsConfig = [Ordered]@{ }
    (Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique | ForEach-Object { 
        $PoolName = $_
        If ($PoolConfig = $Variables.PoolData.$PoolName) { 
            # Merge default pool data with custom pool config
            If ($CustomPoolConfig = $CustomPoolsConfig.$PoolName) { $PoolConfig = Merge-Hashtable -HT1 $PoolConfig -HT2 $CustomPoolConfig -Unique $true }

            If (-not $PoolConfig.EarningsAdjustmentFactor) { $PoolConfig.EarningsAdjustmentFactor = $Config.EarningsAdjustmentFactor }
            If (-not $PoolConfig.WorkerName) { $PoolConfig.WorkerName = $Config.WorkerName }
            If (-not $PoolConfig.BalancesKeepAlive) { $PoolConfig.BalancesKeepAlive = $PoolData.$PoolName.BalancesKeepAlive }

            Switch ($PoolName) { 
                "HiveON" { 
                    If (-not $PoolConfig.Wallets) { 
                        $PoolConfig.Wallets = [PSCustomObject]@{ }
                        ($Config.Wallets | Get-Member -MemberType NoteProperty).Name | Where-Object { $_ -in $PoolConfig.PayoutCurrencies } | ForEach-Object { 
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

    Remove-Variable Config_Tmp, CustomPoolsConfig, PoolConfig, PoolName, Temp -ErrorAction Ignore
}

Function Write-Config { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile, 
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$NewConfig = $Config
    )

    $Header = 
"// This file was generated by $($Variables.Branding.ProductLabel)
// $($Variables.Branding.ProductLabel) will automatically add / convert / rename / update new settings when updating to a new version
"
    If (Test-Path -Path $ConfigFile -PathType Leaf) { 
        Copy-Item -Path $ConfigFile -Destination "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
        Get-ChildItem -Path "$($ConfigFile)_*.backup" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
    }

    $SortedConfig = $NewConfig | Get-SortedObject
    $ConfigTmp = [Ordered]@{ }
    $SortedConfig.Keys | Where-Object { $_ -notin @("ConfigFile", "PoolsConfig") } | ForEach-Object { 
        $ConfigTmp[$_] = $SortedConfig.$_
    }
    "$Header$($ConfigTmp | ConvertTo-Json -Depth 10)" | Out-File -FilePath $ConfigFile -Force -Encoding utf8NoBOM
}
Function Edit-File { 

    # Opens file in notepad. Notepad will remain in foreground until notepad is closed.

    Param(
        [Parameter(Mandatory = $false)]
        [String]$FileName
    )

    $FileWriteTime = (Get-Item -Path $FileName).LastWriteTime

    If (-not ($NotepadProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -Like "*\Notepad.exe* $($FileName)"))) { 
        Notepad.exe $FileName
    }
    # Check if the window is not already in foreground
    While ($NotepadProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -Like "*\Notepad.exe* $($FileName)")) { 
        Try { 
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
        Catch { }
    }

    If ($FileWriteTime -ne (Get-Item -Path $FileName).LastWriteTime) { 
        Write-Message -Level Verbose "Saved '$(($FileName))'. Changes will become active in next cycle."
        Return "Saved '$(($FileName))'`nChanges will become active in next cycle."
    }
    Else { 
        Return "No changes to '$(($FileName))' made."
    }

    Remove-Variable FileWriteTime, NotepadProcess -ErrorAction Ignore
}

Function Get-SortedObject { 

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Object]$Object
    )

    $Object = $Object | ConvertTo-Json -Depth 99 | ConvertFrom-Json -NoEnumerate

    # Build an ordered hashtable of the property-value pairs.
    $SortedObject = [Ordered]@{ }

    Switch -Regex ($Object.GetType().Name) { 
        "PSCustomObject" { 
            Get-Member -Type NoteProperty -InputObject $Object | Sort-Object Name | ForEach-Object { 
                # Upper / lower case conversion (Web GUI is case sensitive)
                $Property = $_.Name
                $Property = $Variables.AvailableCommandLineParameters | Where-Object { $_ -eq $Property }
                If (-not $Property) { $Property = $_.Name }

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

    Remove-Variable Key, Object, Property -ErrorAction Ignore
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
                Write-Message -Level Warn "Error saving hashrate for '$($Name -replace '_Hashrate$')'. $(($Value | ConvertTo-Hash) -replace '\s+', '') is outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) [Iteration $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            ElseIf ($Name -match ".+_PowerUsage") { 
                Write-Message -Level Warn "Error saving power usage for '$($Name -replace '_PowerUsage$')'. $($Value.ToString("N2"))W is outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) [Iteration $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            Return
        }
        Else { 
            If (-not $Disabled -and ($Value -eq 0 -or $Stat.ToleranceExceeded -ge $ToleranceExceeded -or $Stat.Week_Fluctuation -ge 1)) { 
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
    } | ConvertTo-Json | Out-File -FilePath $Path -Force -Encoding utf8NoBOM

    Remove-Variable ChangeDetection, Disabled, Duration, FaultDetection, FaultFactor, Name, Path, SmallesValue, Timer, ToleranceMax, ToleranceMin, Value -ErrorAction Ignore

    $Stat
}

Function Get-Stat { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = (
            & { 
                [String[]]$StatFiles = ((Get-ChildItem -Path "Stats" -File).BaseName | Sort-Object -Unique)
                ($Global:Stats.Keys | Select-Object | Where-Object { $_ -notin $StatFiles }) | ForEach-Object { $Global:Stats.Remove($_) } # Remove stat if deleted on disk
                $StatFiles
            }
        )
    )

    If ($Global:Stats -isnot [Hashtable] -or -not $Global:Stats.IsSynchronized) { 
        $Global:Stats = [Hashtable]::Synchronized(@{ })
    }

    If (-not (Test-Path -Path "Stats" -PathType Container)) { 
        New-Item "Stats" -ItemType "directory" -Force | Out-Null
    }

    $Name | ForEach-Object { 
        $Stat_Name = $_

        If ($Stats.$Stat_Name -isnot [Hashtable] -or -not $Global:Stats.$Stat_Name.IsSynchronized) { 
            # Reduce number of errors
            If (-not (Test-Path -Path "Stats\$Stat_Name.txt" -PathType Leaf)) { 
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

    Remove-Variable Stat, StatFiles, Stat_Name -ErrorAction Ignore
}

Function Remove-Stat { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @($Global:Stats.Keys | Select-Object) + @((Get-ChildItem -Path "Stats" -Directory ).BaseName)
    )

    $Name | Sort-Object -Unique | ForEach-Object { 
        Remove-Item -Path "Stats\$_.txt" -Force -Confirm:$false -ErrorAction SilentlyContinue
        If ($Global:Stats.$_) { $Global:Stats.Remove($_) }
    }

    Remove-Variable Name -ErrorAction Ignore
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

    Remove-Variable Content, Expression, Parameters, Priority, ScriptBlock, Threaded, Name -ErrorAction Ignore
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

    Remove-Variable Client, Port, Reader, Response, Server, Stream, Writer -ErrorAction Ignore
}

Function Get-CpuId { 

    # Brief : gets CPUID (CPU name and registers)

    # OS Features
    # $OS_x64 = "" # not implemented
    # $OS_AVX = "" # not implemented
    # $OS_AVX512 = "" # not implemented

    # Vendor
    $vendor = "" # not implemented

    $Info = [CpuID]::Invoke(0)
    # Convert 16 bytes to 4 ints for compatibility with existing code
    $Info = [Int[]]@(
        [BitConverter]::ToInt32($info, 0 * 4)
        [BitConverter]::ToInt32($info, 1 * 4)
        [BitConverter]::ToInt32($info, 2 * 4)
        [BitConverter]::ToInt32($info, 3 * 4)
    )

    $nIds = $info[0]

    $Info = [CpuID]::Invoke(0x80000000)
    $nExIds = [BitConverter]::ToUInt32($info, 0 * 4) # Not sure as to why 'nExIds' is unsigned; may not be necessary
    # Convert 16 bytes to 4 ints for compatibility with existing code
    $Info = [Int[]]@(
        [BitConverter]::ToInt32($info, 0 * 4)
        [BitConverter]::ToInt32($info, 1 * 4)
        [BitConverter]::ToInt32($info, 2 * 4)
        [BitConverter]::ToInt32($info, 3 * 4)
    )

    # Detect Features
    $features = @{ }
    If ($nIds -ge 0x00000001) { 

        $Info = [CpuID]::Invoke(0x00000001)
        # convert 16 bytes to 4 ints for compatibility with existing code
        $Info = [Int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $Features.MMX = ($info[3] -band ([Int]1 -shl 23)) -ne 0
        $Features.SSE = ($info[3] -band ([Int]1 -shl 25)) -ne 0
        $Features.SSE2 = ($info[3] -band ([Int]1 -shl 26)) -ne 0
        $Features.SSE3 = ($info[2] -band ([Int]1 -shl 00)) -ne 0

        $Features.SSSE3 = ($info[2] -band ([Int]1 -shl 09)) -ne 0
        $Features.SSE41 = ($info[2] -band ([Int]1 -shl 19)) -ne 0
        $Features.SSE42 = ($info[2] -band ([Int]1 -shl 20)) -ne 0
        $Features.AES = ($info[2] -band ([Int]1 -shl 25)) -ne 0

        $Features.AVX = ($info[2] -band ([Int]1 -shl 28)) -ne 0
        $Features.FMA3 = ($info[2] -band ([Int]1 -shl 12)) -ne 0

        $Features.RDRAND = ($info[2] -band ([Int]1 -shl 30)) -ne 0
    }

    If ($nIds -ge 0x00000007) { 

        $Info = [CpuID]::Invoke(0x00000007)
        # Convert 16 bytes to 4 ints for compatibility with existing code
        $Info = [Int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $Features.AVX2 = ($info[1] -band ([Int]1 -shl 05)) -ne 0

        $Features.BMI1 = ($info[1] -band ([Int]1 -shl 03)) -ne 0
        $Features.BMI2 = ($info[1] -band ([Int]1 -shl 08)) -ne 0
        $Features.ADX = ($info[1] -band ([Int]1 -shl 19)) -ne 0
        $Features.MPX = ($info[1] -band ([Int]1 -shl 14)) -ne 0
        $Features.SHA = ($info[1] -band ([Int]1 -shl 29)) -ne 0
        $Features.RDSEED = ($info[1] -band ([Int]1 -shl 18)) -ne 0
        $Features.PREFETCHWT1 = ($info[2] -band ([Int]1 -shl 00)) -ne 0
        $Features.RDPID = ($info[2] -band ([Int]1 -shl 22)) -ne 0

        $Features.AVX512_F = ($info[1] -band ([Int]1 -shl 16)) -ne 0
        $Features.AVX512_CD = ($info[1] -band ([Int]1 -shl 28)) -ne 0
        $Features.AVX512_PF = ($info[1] -band ([Int]1 -shl 26)) -ne 0
        $Features.AVX512_ER = ($info[1] -band ([Int]1 -shl 27)) -ne 0

        $Features.AVX512_VL = ($info[1] -band ([Int]1 -shl 31)) -ne 0
        $Features.AVX512_BW = ($info[1] -band ([Int]1 -shl 30)) -ne 0
        $Features.AVX512_DQ = ($info[1] -band ([Int]1 -shl 17)) -ne 0

        $Features.AVX512_IFMA = ($info[1] -band ([Int]1 -shl 21)) -ne 0
        $Features.AVX512_VBMI = ($info[2] -band ([Int]1 -shl 01)) -ne 0

        $Features.AVX512_VPOPCNTDQ = ($info[2] -band ([Int]1 -shl 14)) -ne 0
        $Features.AVX512_4FMAPS = ($info[3] -band ([Int]1 -shl 02)) -ne 0
        $Features.AVX512_4VNNIW = ($info[3] -band ([Int]1 -shl 03)) -ne 0

        $Features.AVX512_VNNI = ($info[2] -band ([Int]1 -shl 11)) -ne 0

        $Features.AVX512_VBMI2 = ($info[2] -band ([Int]1 -shl 06)) -ne 0
        $Features.GFNI = ($info[2] -band ([Int]1 -shl 08)) -ne 0
        $Features.VAES = ($info[2] -band ([Int]1 -shl 09)) -ne 0
        $Features.AVX512_VPCLMUL = ($info[2] -band ([Int]1 -shl 10)) -ne 0
        $Features.AVX512_BITALG = ($info[2] -band ([Int]1 -shl 12)) -ne 0
    }

    If ($nExIds -ge 0x80000001) { 

        $Info = [CpuID]::Invoke(0x80000001)
        # Convert 16 bytes to 4 ints for compatibility with existing code
        $Info = [Int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $Features.x64 = ($info[3] -band ([Int]1 -shl 29)) -ne 0
        $Features.ABM = ($info[2] -band ([Int]1 -shl 05)) -ne 0
        $Features.SSE4a = ($info[2] -band ([Int]1 -shl 06)) -ne 0
        $Features.FMA4 = ($info[2] -band ([Int]1 -shl 16)) -ne 0
        $Features.XOP = ($info[2] -band ([Int]1 -shl 11)) -ne 0
        $Features.PREFETCHW = ($info[2] -band ([Int]1 -shl 08)) -ne 0
    }

    # Wrap data into PSObject
    [PSCustomObject]@{ 
        Vendor   = $vendor
        Name     = $name
        Features = $Features.Keys.ForEach{ If ($Features.$_) { $_ } }
    }
}

Function Get-NvidiaArchitecture {

    [CmdLetBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Model,
        [Parameter(Mandatory = $true)]
        [String]$ComputeCapability = ""
    )

    $ComputeCapability = $ComputeCapability -replace "[^\d\.]"
    If     ($ComputeCapability -in @("8.0", "8.6") -or $Model -match "^RTX30\d{2}" -or $Model -match "^RTXA\d{4}"  -or $Model -match "^AM") {"Ampere"}
    ElseIf ($ComputeCapability -in @("7.5")        -or $Model -match "^RTX20\d{2}" -or $Model -match "^GTX16\d{2}" -or $Model -match "^TU") {"Turing"}
    ElseIf ($ComputeCapability -in @("6.0", "6.1") -or $Model -match "^GTX10\d{2}" -or $Model -match "^GTXTitanX"  -or $Model -match "^GP" -or $Model -match "^P" -or $Model -match "^GT1030") {"Pascal"}
    Else   {"Other"}
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
            ($Name_Device | Get-Member -MemberType NoteProperty).Name | ForEach-Object { $Name_Device.$_ = $Name_Device.$_ -f $Name_Split }

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
            ($ExcludeName_Device | Get-Member -MemberType NoteProperty).Name | ForEach-Object { $ExcludeName_Device.$_ = $ExcludeName_Device.$_ -f $ExcludeName_Split }

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
                $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor) -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^ A-Z0-9\.]' -replace '\s+', ' ').Trim()

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

                $Device_PNP = [PSCustomObject]@{ }
                Get-PnpDevice $Device_CIM.PNPDeviceID | Get-PnpDeviceProperty | ForEach-Object { $Device_PNP | Add-Member $_.KeyName $_.Data }
                $Device_PNP = $Device_PNP | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

                $Device_Reg = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\$($Device_PNP.DEVPKEY_Device_Driver)" | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json

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

                $Device | Add-Member @{ 
                    Id             = [Int]$Id
                    Type_Id        = [Int]$Type_Id.($Device.Type)
                    Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                    Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                }
                #Unsupported devices start with DeviceID 100 (to not disrupt device order when running in a Citrix or RDP session)
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
                    #Unsupported devices get DeviceID 100 (to not disrupt device order when running in a Citrix or RDP session)
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

            $Variables.Devices | Where-Object Model -ne "Remote Display Adapter 0GB" | Where-Object Vendor -ne "CitrixSystemsInc" | Where-Object Bus -Is [Int64] | Sort-Object Bus | ForEach-Object { 
                If ($_.Type -eq "GPU") { 
                    If ($_.Vendor -eq "NVIDIA") { 
                        $_ | Add-Member "Architecture" (Get-NvidiaArchitecture $_.Model $_.OpenCL.DeviceCapability)
                    } 
                    ElseIf ($_.Vendor -eq "AMD") {
                        $_ | Add-Member "Architecture" $(
                            Switch -Regex ($_.Reg.InfSection -replace "ati2mtag_") { 
                                "Lexa.*"      { "CGN4" }
                                "Ellesmere.*" { "CGN4" }
                                "Polaris.*"   { "CGN4" }
                                "Vega.*"      { "CGN5" }
                                "Navi1.*"     { "RDNA" }
                                "Nav12.*"     { "RDNA2" }
                                Default       { "Other" }
                            }
                        )
                    }
                    Else { 
                        $_ | Add-Member "Architecture" "Other"
                    }
                }

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

        If (-not $Name -or ($Name_Devices | Where-Object { ($Device | Select-Object (($_ | Get-Member -MemberType NoteProperty).Name)) -like ($_ | Select-Object (($_ | Get-Member -MemberType NoteProperty).Name)) })) { 
            If (-not $ExcludeName -or -not ($ExcludeName_Devices | Where-Object { ($Device | Select-Object (($_ | Get-Member -MemberType NoteProperty).Name)) -like ($_ | Select-Object (($_ | Get-Member -MemberType NoteProperty).Name)) })) { 
                $Device
            }
        }
    }
}

Filter ConvertTo-Hash { 

    $Units = " kMGTPEZY" # k(ilo) in small letters, see https://en.wikipedia.org/wiki/Metric_prefix

    If ( $_ -eq $null -or [Double]::IsNaN($_)) { Return 'n/a' }
    $Base1000 = [Math]::Truncate([Math]::Log([Math]::Abs([Double]$_), [Math]::Pow(1000, 1)))
    $Base1000 = [Math]::Max([Double]0, [Math]::Min($Base1000, $Units.Length - 1))
    $UnitValue = $_ / [Math]::Pow(1000, $Base1000)
    $Digits = If ($UnitValue -lt 10 ) { 3 } Else { 2 }
    "{0:n$($Digits)} $($Units[$Base1000])H" -f $UnitValue
}

Function Get-DigitsFromValue { 

    # The bigger the number, the more decimal digits

    # Output will have as many digits as the integer value is to the power of 10
    # e.g. Rate is between 100 and 999, then Digits is 3

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $true)]
        [Int]$MaxDigits
    )

    $Digits = [math]::Floor($Value).ToString().Length
    If ($Digits -lt 0) { $Digits = 0 }
    If ($Digits -gt $MaxDigits) { $Digits = $MaxDigits }

    $Digits
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
        [String]$StartF = 0x00000081, # STARTF_USESHOWWINDOW, STARTF_FORCEOFFFEEDBACK
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

        Do { 
            If ($ControllerProcess.WaitForExit(1000)) { $Process.CloseMainWindow() | Out-Null }
        } While ($Process.HasExited -eq $false)
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

    If (Test-Path -Path $FileName -PathType Leaf) { Remove-Item $FileName }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Uri -OutFile $FileName -TimeoutSec 5 -UseBasicParsing

    If (".msi", ".exe" -contains ([IO.FileInfo](Split-Path $Uri -Leaf)).Extension) { 
        Start-Process $FileName "-qb" -Wait
    }
    Else { 
        $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
        $Path_New = Split-Path $Path

        If (Test-Path -Path $Path_Old -PathType Container) { Remove-Item $Path_Old -Recurse -Force }
        Start-Process ".\Utils\7z" "x `"$([IO.Path]::GetFullPath($FileName))`" -o`"$([IO.Path]::GetFullPath($Path_Old))`" -y -spe" -Wait -WindowStyle Hidden

        If (Test-Path -Path $Path_New -PathType Container) { Remove-Item $Path_New -Recurse -Force }

        # use first (topmost) directory, some miners, e.g. ClaymoreDual_v11.9, contain multiple miner binaries for different driver versions in various sub dirs
        $Path_Old = (Get-ChildItem -Path $Path_Old -File -Recurse | Where-Object { $_.Name -EQ $(Split-Path $Path -Leaf) }).Directory | Select-Object -First 1

        If ($Path_Old) { 
            Move-Item $Path_Old $Path_New -PassThru | ForEach-Object -Process { $_.LastWriteTime = Get-Date }
            $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
            If (Test-Path -Path $Path_Old -PathType Container) { Remove-Item -Path $Path_Old -Recurse -Force }
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

    If (-not (Test-Path -Path Variable:Global:Algorithms -ErrorAction SilentlyContinue)) { 
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

    If (-not (Test-Path -Path Variable:Global:Regions -ErrorAction SilentlyContinue)) { 
        $Global:Regions = Get-Content -Path ".\Data\Regions.json" -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }

    If ($List) { $Global:Regions.$Region }
    ElseIf ($Global:Regions.$Region) { $($Global:Regions.$Region | Select-Object -First 1) }
    Else { $Region }

    Remove-Variable List, Region -ErrorAction Ignore
}

Function Add-CoinName { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Algorithm,
        [Parameter(Mandatory = $true)]
        [String]$Currency,
        [Parameter(Mandatory = $true)]
        [String]$CoinName
    )

    If (-not (Test-Path -Path Variable:Global:CoinNames -ErrorAction SilentlyContinue)) { 
        $Global:CoinNames = Get-Content -Path ".\Data\CoinNames.json" | ConvertFrom-Json
    }
    If (-not (Test-Path -Path Variable:Global:CurrencyAlgorithm -ErrorAction SilentlyContinue)) { 
        $Global:CurrencyAlgorithm = Get-Content -Path ".\Data\CurrencyAlgorithm.json" | ConvertFrom-Json
    }

    If ($Global:CoinNames.$Currency -and $Global:CurrencyAlgorithm.$Currency) { 
       Return
    }
    Else { 

        # Get mutex. Mutexes are shared across all threads and processes. 
        # This lets us ensure only one thread is trying to write to the file at a time. 
        $Mutex = New-Object System.Threading.Mutex($false, "$($PWD -replace '[^A-Z0-9]')_CoinData")

        # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the coin names file and release mutex. Otherwise, display an error. 
        If ($Mutex.WaitOne(1000)) { 

            If (-not $Global:CurrencyAlgorithm.$Currency) { 
                $Global:CurrencyAlgorithm = Get-Content -Path ".\Data\CurrencyAlgorithm.json" | ConvertFrom-Json
                $Global:CurrencyAlgorithm | Add-Member $Currency $Algorithm -Force
                $Global:CurrencyAlgorithm | Get-SortedObject | ConvertTo-Json | Out-File -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction SilentlyContinue -Encoding utf8NoBOM -Force
            }
            If (-not $Global:CoinNames.$Currency) { 
                $Global:CoinNames = Get-Content -Path ".\Data\CoinNames.json" | ConvertFrom-Json
                $Global:CoinNames | Add-Member $Currency ((Get-Culture).TextInfo.ToTitleCase($CoinName.Trim().ToLower()) -replace '[^A-Z0-9\$\.]' -replace 'coin$', 'Coin' -replace 'bitcoin$', 'Bitcoin') -Force
                $Global:CoinNames | Get-SortedObject | ConvertTo-Json | Out-File -Path ".\Data\CoinNames.json" -ErrorAction SilentlyContinue -Encoding utf8NoBOM -Force
            }
 
            [void]$Mutex.ReleaseMutex()
        }

        Remove-Variable Mutex
    }
}

Function Get-CoinName { 

    Param(
        [Parameter(Mandatory = $false)]
        [String]$Currency
    )

    If (-not (Test-Path -Path Variable:Global:CoinNames -ErrorAction SilentlyContinue)) { 
        $Global:CoinNames = Get-Content -Path ".\Data\CoinNames.json" | ConvertFrom-Json
    }

    If ($Global:CoinNames.$Currency) { 
       Return $Global:CoinNames.$Currency
    }
    If ($Currency) { 
        $Global:CoinNames = Get-Content -Path ".\Data\CoinNames.json" | ConvertFrom-Json
        If ($Global:CoinNames.$Currency) { 
            Return $Global:CoinNames.$Currency
        }
    }
    Return $null
}

Function Get-CurrencyAlgorithm { 

    Param(
        [Parameter(Mandatory = $false)]
        [String]$Currency
    )

    If (-not (Test-Path -Path Variable:Global:CurrencyAlgorithm -ErrorAction SilentlyContinue)) { 
        $Global:CurrencyAlgorithm = Get-Content -Path ".\Data\CurrencyAlgorithm.json" | ConvertFrom-Json
    }

    If ($Global:CurrencyAlgorithm.$Currency) { 
       Return $Global:CurrencyAlgorithm.$Currency
    }
    If ($Currency) { 
        $Global:CurrencyAlgorithm = Get-Content -Path ".\Data\CurrencyAlgorithm.json" | ConvertFrom-Json
        If ($Global:CurrencyAlgorithm.$Currency) { 
            Return $Global:CurrencyAlgorithm.$Currency
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
        $UpdateVersion = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Minerx117/NemosMiner/master/Version.txt" -TimeoutSec 15 -UseBasicParsing -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" }).Content | ConvertFrom-Json

        $Variables.CheckedForUpdate = (Get-Date).ToUniversalTime()

        If ($UpdateVersion.Product -eq $Variables.Branding.ProductLabel -and [Version]$UpdateVersion.Version -gt $Variables.Branding.Version) { 
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
            If ($Config.ShowChangeLog) { 
                Start-Process "https://github.com/Minerx117/NemosMiner/releases/tag/v$($UpdateVersion.Version)"
            }
        }
        Else { 
            Write-Message -Level Verbose "Version checker: $($Variables.Branding.ProductLabel) $($Variables.Branding.Version) is current - no update available."
        }
    }
    Catch { 
        Write-Message -Level Warn "Version checker could not contact update server."
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

    $NemosMinerFileHash = (Get-FileHash ".\$($Variables.Branding.ProductLabel).ps1").Hash

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

    If ($Variables.Branding.Version -le [System.Version]"3.9.9.17" -and $UpdateVersion.Version -ge [System.Version]"3.9.9.17") { 
        # Balances & earnings files are no longer compatible
        Write-Message -Level Warn "Balances & Earnings files are no longer compatible and will be reset."
    }

    # Stop processes
    $Variables.NewMiningStatus = "Idle"

    If ($Config.BackupOnAutoUpdate) { 
        # Backup current version folder in zip file; exclude existing zip files and download folder
        "Backing up current version as '.\$($BackupFile)'..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        Start-Process ".\Utils\7z" "a $($BackupFile) .\* -x!*.zip -x!downloads -x!logs -x!cache -x!$UpdateLog -xr!VertHash.dat -bb1 -bd" -RedirectStandardOutput "$($UpdateLog)_tmp" -Wait -WindowStyle Hidden
        Add-Content $UpdateLog (Get-Content -Path "$($UpdateLog)_tmp")
        Remove-Item -Path "$($UpdateLog)_tmp" -Force

        If (-not (Test-Path .\$BackupFile -PathType Leaf)) { 
            "Backup failed. Cannot complete auto-update :-(" | Tee-Object $UpdateLog -Append | Write-Message -Level Error
            Return
        }
    }

    #Stop all background processes
    Stop-Mining
    Stop-BrainJob
    Stop-IdleDetection
    Stop-BalancesTracker

    If ($Variables.Branding.Version -le [System.Version]"3.9.9.17" -and $UpdateVersion -ge [System.Version]"3.9.9.17") { 
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
    If (Test-Path -Path ".\Miners") { Get-ChildItem -Path ".\Miners" -File | ForEach-Object { Remove-Item -Recurse -Path $_.FullName -Force; "Removed '$_'" | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue } }
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
            Copy-Item -Path $_ -Destination $DestPath -Force
            "Copied '$($_.Name)' to '$Destpath'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        }
    }

    # Start Log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net]
    Start-LogReader

    # Remove obsolete miner stat files; must be done after new miner files have been unpacked
    If ($ObsoleteMinerStats = Get-ObsoleteMinerStats) { 
        "Removing obsolete stat files from miners that no longer exist..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        $ObsoleteMinerStats | ForEach-Object { 
            Remove-Item -Path ".\Stats\$($_).txt" -Force
            "Removed '$_'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        }
    }
    Remove-Variable ObsoleteMinerStats

    "Cleaning up old files..." | Tee-Object -FilePath $UpdateLog -Append | Write-Message -Level Verbose
    # Remove all TON stat files
    (Get-ChildItem -Path ".\Stats" | Where-Object { $_.Name -match '^.+_SHA256ton_.+\.txt$' }).Name | ForEach-Object { 
        Remove-Item -Path "\Stats\$_" -Force
        "Removed '$_'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    }
    (Get-ChildItem -Path ".\Stats" | Where-Object { $_.Name -match '^TonPool*_.+\.txt$' }).Name | ForEach-Object { 
        Remove-Item -Path "\Stats\$_" -Force
        "Removed '$_'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    }
    (Get-ChildItem -Path ".\Stats" | Where-Object { $_.Name -match '^TonWhales*_.+\.txt$' }).Name | ForEach-Object { 
        Remove-Item -Path "\Stats\$_" -Force
        "Removed '$_'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    }

    # Remove old miner binaries
    Get-ChildItem -Path ".\Bin" -Directory | ForEach-Object { 
        If (-not (Test-Path -Path ".\Miners\$($_.Name).ps1" -PathType Leaf)) { 
            Remove-Item -Path ".\Bin\$($_.Name)" -Recurse -Force
            "Removed '\Bin\$($_.Name)'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        }
    }

    # Remove temporary files
    Remove-Item .\$UpdateFileName -Force -Recurse
    Remove-Item ".\$($UpdateFileName).zip" -Force
    If (Test-Path -Path ".\PreUpdateActions.ps1" -PathType Leaf) { 
        Remove-Item ".\PreUpdateActions.ps1" -Force
        "Removed '.\PreUpdateActions.ps1'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    }
    If (Test-Path -Path ".\PostUpdateActions.ps1" -PathType Leaf) { 
        Remove-Item ".\PostUpdateActions.ps1" -Force
        "Removed '.\PostUpdateActions.ps1'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
    }
    # Keep only 3 file generations
    Get-ChildItem -Path "AutoupdateBackup_*.zip" -File | Where-Object { $_.name -ne $BackupFile } | Sort-Object LastWriteTime -Descending | Select-Object -SkipLast 2 | ForEach-Object { Remove-Item -Path $_ -Force -Recurse; "Removed '$_'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue }
    Get-ChildItem -Path ".\Logs\AutoupdateBackup_*.zip" -File | Where-Object { $_.name -ne $UpdateLog } | Sort-Object LastWriteTime -Descending | Select-Object -SkipLast 2 | ForEach-Object { Remove-Item -Path $_ -Force -Recurse; "Removed '$_'." | Out-File -FilePath $UpdateLog -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue }

    # Start new instance
    If ($UpdateVersion.RequireRestart -or $NemosMinerFileHash -ne (Get-FileHash ".\$($Variables.Branding.ProductLabel).ps1").Hash) { 
        "Starting updated version..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        $StartCommand = (Get-Process -Id $PID).CommandLine
        $NewKid = Invoke-CimMethod -ClassName Win32_Process -MethodName "Create" -Arguments @{ CommandLine = "$StartCommand"; CurrentDirectory = $Variables.MainPath }
        Start-Sleep 5

        # Giving 10 seconds for process to start
        $Waited = 0
        While (-not (Get-Process -Id $NewKid.ProcessId -ErrorAction SilentlyContinue) -and ($waited -le 10)) { Start-Sleep -Seconds 1; $waited++ }
        If (-not (Get-Process -Id $NewKid.ProcessId -ErrorAction SilentlyContinue)) { 
            "Failed to start new instance of $($Variables.Branding.ProductLabel)." | Tee-Object $UpdateLog -Append | Write-Message -Level Error
            Return
        }
    }

    $VersionTable = (Get-Content -Path ".\Version.txt").trim() | ConvertFrom-Json -AsHashtable
    $VersionTable | Add-Member @{ AutoUpdated = ((Get-Date).DateTime) } -Force
    $VersionTable | Add-Member @{ Version = $UpdateVersion.Version } -Force
    $VersionTable | ConvertTo-Json | Out-File -FilePath ".\Version.txt" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue

    "Successfully updated $($UpdateVersion.Product) to version $($UpdateVersion.Version)." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose

    # Display changelog
    If ($Config.ShowChangeLog) { Notepad .\ChangeLog.txt }

    If ($NewKid.ProcessId) { 
        # Kill old instance
        "Killing old instance..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose
        Start-Sleep -Seconds 2
        If (Get-Process -Id $NewKid.ProcessId) { Stop-Process -Id $PID }
    }
}

Function Start-LogReader { 

    If ((Test-Path -Path $Config.SnakeTailExe -PathType Leaf) -and (Test-Path -Path $Config.SnakeTailConfig -PathType Leaf)) { 
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
            "AllowedBadShareRatio" { $Config.BadShareRatioThreshold = $Config.$_; $Config.Remove($_) }
            "APIKEY" { $Config.MiningPoolHubAPIKey = $Config.$_; $Config.Remove($_) }
            "BalancesTrackerConfigFile" { $Config.Remove($_) }
            "DeductRejectedShares" { $Config.SubtractBadShares = $Config.$_; $Config.Remove($_) }
            "EnableEarningsTrackerLog" { $Config.EnableBalancesLog = $Config.$_; $Config.Remove($_) }
            "EstimateCorrection" { $Config.Remove($_) }
            "EthashLowMemMinMemGB" { $Config.Remove($_) }
            "Location" { $Config.Region = $Config.$_; $Config.Remove($_) }
            "IdleDetection" { $Config.IdleDetection = $Config.$_; $Config.Remove($_) }
            "IdlePowerUsageW" { $Config.PowerUsageIdleSystemW = $Config.$_; $Config.Remove($_) }
            "MPHAPIKey" { $Config.MiningPoolHubAPIKey = $Config.$_; $Config.Remove($_) }
            "MPHUserName"  { $Config.MiningPoolHubUserName = $Config.$_; $Config.Remove($_) }
            "NoDualAlgoMining" { $Config.DisableDualAlgoMining = $Config.$_; $Config.Remove($_) }
            "NoSingleAlgoMining" { $Config.DisableSingleAlgoMining = $Config.$_; $Config.Remove($_) }
            "PasswordCurrency" { $Config.PayoutCurrency = $Config.$_; $Config.Remove($_) }
            "PoolBalancesUpdateInterval" { 
                If ($Config.$_) { $Config.PoolBalancesUpdateInterval = $Config.$_ }
                $Config.Remove($_)
            }
            "PricePenaltyFactor" { $Config.EarningsAdjustmentFactor = $Config.$_; $Config.Remove($_) }
            "ReadPowerUsage" { $Config.CalculatePowerCost = $Config.$_; $Config.Remove($_) }
            "RunningMinerGainPct" { $Config.MinerSwitchingThreshold = $Config.$_; $Config.Remove($_) }
            "ShowMinerWindows" { $Config.MinerWindowStyle = $Config.$_; $Config.Remove($_) }
            "ShowMinerWindowsNormalWhenBenchmarking" { $Config.MinerWindowStyleNormalWhenBenchmarking = $Config.$_; $Config.Remove($_) }
            "SSL" { $Config.Remove($_) }
            "UIStyle" { $Config.$_ = $Config.$_.ToLower() }
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
        Remove-Variable Value
    }

    # Change currency names, remove mBTC
    If ($Config.Currency -is [Array]) { 
        $Config.Currency = $Config.Currency | Select-Object -First 1
        $Config.ExtraCurrencies = @($Config.Currency | Select-Object -Skip 1 | Where-Object { $_ -ne "mBTC" } | Select-Object)
    }

    # Move [PayoutCurrency] wallet to wallets
    If ($PoolsConfig = Get-Content .\Config\PoolsConfig.json | ConvertFrom-Json) { 
        ($PoolsConfig | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
            If (-not $PoolsConfig.$_.Wallets -and $PoolsConfig.$_.Wallet) { 
                $PoolsConfig.$_ | Add-Member Wallets @{ "$($PoolsConfig.$_.PayoutCurrency)" = $PoolsConfig.$_.Wallet }
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
        $OldRegion = $Config.Region
        # Write message about new mining regions
        $Config.Region = Switch ($Config.Region) { 
            "Brazil"       { "USA West" }
            "Europe East"  { "Europe" }
            "Europe North" { "Europe" }
            "HongKong"     { "Asia" }
            "India"        { "Asia" }
            "Japan"        { "Japan" }
            "Russia"       { "Russia" }
            "US"           { "USA West" }
            Default        { "Europe" }
        }
        Write-Message -Level Warn "Available mining locations have changed ($OldRegion -> $($Config.Region)). Please verify your configuration."
        Remove-Variable OldRegion
    }

    # Remove AHashPool config & stat data
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "AhashPool*" }
    Remove-Item ".\Stats\AhashPool*.txt" -Force
    # Remove TonPool config
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "TonPool" }
    # Remove TonWhales config
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "TonWhales" }

    $Config | Add-Member ConfigFileVersion ($Variables.Branding.Version.ToString()) -Force
    Write-Config -ConfigFile $ConfigFile
    "Updated configuration file '$($ConfigFile)' to version $($Variables.Branding.Version.ToString())." | Write-Message -Level Verbose 
    Remove-Variable New_Config_Items
}

Function Get-ObsoleteMinerStats { 

    Get-Stat | Out-Null

    $MinerNames = @(Get-ChildItem ".\Miners\*.ps1").BaseName
    @($Global:Stats.Keys | Where-Object { $_ -match "_Hashrate$|_PowerUsage$" } | Where-Object { (($_ -split "-" | Select-Object -First 2) -join "-") -notin $MinerNames})
}

Function Test-Prime { 

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Number
    )

    For ([Int64]$i = 2; $i -lt [Int64][Math]::Pow($Number, 0.5); $i++) { If ($Number % $i -eq 0) { Return $false } }

    Return $true
}

Function Get-DAGdata { 

    Param(
        [Parameter(Mandatory = $false)]
        [Double]$Blockheight = ((Get-Date) - [DateTime]"07/31/2015").Days * 6400,
        [Parameter(Mandatory = $false)]
        [String]$Currency = "ETH"
    )
        Function Get-DAGsize { 

        Param(
            [Parameter(Mandatory = $true)]
            [Double]$Epoch,
            [Parameter(Mandatory = $true)]
            [String]$Currency
        )

        Switch ($Currency) { 
            "ERG" { 
                $Size = [Math]::Pow(2, 26)
                $Blockheight = [Math]::Min($Blockheight, 4198400)
                If ($Blockheight -ge 614400) { 
                    $P = [Math]::Floor(($Blockheight - 614400) / 51200) + 1
                    While ($P-- -gt 0) {
                        $Size = [Math]::Floor($Size / 100) * 105
                    }
                }
                $Size *= 31
            }
            Default { 
                $Dataset_Bytes_Init = [Math]::Pow(2, 30) # 1GB
                $Dataset_Bytes_Growth = [Math]::Pow(2, 23) # 8MB
                $Mix_Bytes = 128
                $Size = ($Dataset_Bytes_Init + $Dataset_Bytes_Growth * $Epoch) - $Mix_Bytes
                While (-not (Test-Prime ($Size / $Mix_Bytes))) { 
                    $Size -= 2 * $Mix_Bytes
                }
            }
        }

        Return [Int64]$Size
    }

    Function Get-Epoch { 

        Param(
            [Parameter(Mandatory = $true)]
            [Double]$Blockheight,
            [Parameter(Mandatory = $true)]
            [String]$Currency
        )

        Switch ($Currency) { 
            "ERG"   { $Blockheight -= 416768 } # Epoch 0 starts @ 417792
            Default { }
        }

        Return [Int][Math]::Floor($Blockheight / (Get-EpochLength -Blockheight $Blockheight -Currency $Currency))
    }

    Function Get-EpochLength { 

        Param(
            [Parameter(Mandatory = $true)]
            [Double]$Blockheight,
            [Parameter(Mandatory = $true)]
            [String]$Currency
        )

        Switch ($Currency) { 
            "ERG"   { Return 1024 }
            "ETC"   { If ($Blockheight -ge 11700000 ) { Return 60000 } Else { Return 30000 } }
            "FIRO"  { Return 1300 }
            "RVN"   { Return 7500 }
            Default { return 30000 }
        }
    }

    $Epoch = Get-Epoch -BlockHeight $BlockHeight -Currency $Currency

    [PSCustomObject]@{ 
        BlockHeight = [Int]$BlockHeight
        CoinName    = Get-CoinName $Currency
        DAGsize     = Get-DAGSize -Epoch $Epoch -Currency $Currency
        Epoch       = $Epoch
    }
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
    $DataTable = Get-psdrive| Out-DataTable
    This example creates a DataTable from the properties of Get-psdrive and assigns output to $DataTable variable
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
        $DataTable = New-Object Data.datatable
        $First = $true
    }
    Process { 
        ForEach ($Object in $InputObject) { 
            $DataRow = $DataTable.NewRow()
            ForEach ($Property in $Object.PSObject.Properties) { 
                If ($First) { 
                    $Col = New-Object Data.DataColumn
                    $Col.ColumnName = $Property.Name.ToString()
                    If ($Property.Value) { 
                        If ($Property.Value -isnot [System.DBNull]) { 
                            $Col.DataType = [System.Type]::GetType($Property.TypeNameOfValue).Name
                        }
                    }
                    $DataTable.Columns.Add($Col)
                }
                $DataRow.Item($Property.Name) = If ($Property.GetType().IsArray) { $Property.Value | ConvertTo-Xml -As String -NoTypeInformation -Depth 1 } Else { $Property.Value }
            }
            $DataTable.Rows.Add($DataRow)
            $First = $false
        }
    }

    End { 
        Write-Output @(,($DataTable))
    }
}

Function Get-Median { 
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Double[]]
        $Number
    )

    $NumberSeries += @()
    $NumberSeries += $Number
    $SortedNumbers = @($NumberSeries | Sort-Object)
    If ($NumberSeries.Count % 2) { 
        $SortedNumbers[($SortedNumbers.Count / 2) - 1]
    }
    Else { 
        ($SortedNumbers[($SortedNumbers.Count / 2)] + $SortedNumbers[($SortedNumbers.Count / 2) - 1]) / 2
    }
}
