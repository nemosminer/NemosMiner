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
File:           include.ps1
Version:        4.3.2.1
Version date:   22 March 2023
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
    [Version]$CUDAVersion
    [Double]$ConfiguredPowerUsage = 0 # Workaround if device does not expose power usage
    [PSCustomObject]$CpuFeatures
    [Int]$Id
    [Int]$Index = 0
    [Int64]$Memory
    [String]$Model
    [Double]$MemoryGiB
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
    [Nullable[Double]]$DAGSizeGiB = $null
    [Boolean]$Disabled = $false
    [Double]$EarningsAdjustmentFactor = 1
    [Nullable[Int]]$Epoch = $null
    [Double]$Fee
    [String]$Host
    # [String[]]$Hosts # To be implemented for pool failover
    [String]$Name
    [String]$Pass
    $PoolPorts = @()
    [UInt16]$Port
    [UInt16]$PortSSL
    [Double]$Price
    [Double]$Price_Bias
    [String]$Protocol
    [String[]]$Reasons = @()
    [String]$Region
    [Boolean]$SendHashrate # If true miner will send hashrate to pool
    [Boolean]$SSLSelfSignedCertificate
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
    [DateTime]$Updated = (Get-Date).ToUniversalTime()
}

Enum MinerStatus { 
    Running
    DryRun
    Idle
    Failed
    Disabled
    Unavailable
}

Class Miner { 
    [Int]$Activated = 0
    [TimeSpan]$Active = [TimeSpan]::Zero
    [String[]]$Algorithms # derived from workers
    [String]$API
    [String]$Arguments
    [Boolean]$Available = $true
    [String]$BaseName
    [DateTime]$BeginTime
    [Boolean]$Benchmark = $false # derived from stats
    [Boolean]$Best = $false
    [String]$CommandLine
    [Int]$Cycle = 0 # Counter, miner has been running continously for n loops
    [Int]$DataCollectInterval = 5 # Seconds
    [String[]]$DeviceNames = @() # derived from devices
    [Device[]]$Devices = @()
    [Boolean]$Disabled = $false
    [Double]$Earning # derived from pool and stats
    [Double]$Earning_Bias # derived from pool and stats
    [Double]$Earning_Accuracy # derived from pool and stats
    [DateTime]$EndTime
    [String[]]$EnvVars = @()
    [DateTime]$ValidDataSampleTimestamp = 0
    [Double[]]$Hashrates_Live = @()
    [String]$Info
    [Boolean]$KeepRunning = $false # do not stop miner even if not best (MinInterval)
    [String]$LogFile
    [Boolean]$MeasurePowerUsage = $false
    [Int]$MinDataSample # for safe hashrate values
    [Int]$MinerSet
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
    [DateTime]$Updated # derived from stats
    [String]$URI
    [Worker[]]$Workers = @()
    [Worker[]]$WorkersRunning = @()
    [String]$Version
    [Int[]]$WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
    [String]$WindowStyle = "minimized"

    hidden [PSCustomObject[]]$Data = $null
    hidden [System.Management.Automation.Job]$DataReaderJob = $null
    hidden [System.Management.Automation.Job]$Process = $null

    [String[]]GetProcessNames() { 
        Return @(([IO.FileInfo]($this.Path | Split-Path -Leaf)).BaseName)
    }

    [String]GetCommandLineParameters() { 
        Return (Get-CommandLineParameter $this.Arguments)
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
            }
            Catch { 
                Return
            }
        }
        # Start Miner data reader
        $this | Add-Member -Force @{ DataReaderJob = Start-Job -Name "$($this.Name)_DataReader" -InitializationScript ([ScriptBlock]::Create("Set-Location('$(Get-Location)')")) -ScriptBlock $ScriptBlock -ArgumentList ($this.API), ($this | Select-Object -Property Algorithms, DataCollectInterval, Devices, Name, Path, Port, ReadPowerUsage, LogFile | ConvertTo-Json -WarningAction Ignore) }
    }

    hidden StopDataReader() { 
        # Before stopping read data
        If ($this.DataReaderJob.HasMoreData) { $this.Data += @($this.DataReaderJob | Receive-Job | Select-Object -Property Date, Hashrate, Shares, PowerUsage) }
        $this.DataReaderJob | Get-Job | Stop-Job | Receive-Job | Out-Null
        $this.DataReaderJob = $null
    }

    hidden RestartDataReader() { 
        $this.StopDataReader()
        $this.StartDataReader()
    }

    hidden StartMining() { 
        $this.Info = "{$(($this.Workers.Pool | ForEach-Object { $_.Algorithm, $_.Name -join '@' }) -join ' & ')}"
        If ($this.Arguments -and (Test-Json $this.Arguments)) { $this.CreateConfigFiles() }

        If ($this.Status -eq [MinerStatus]::DryRun) { 
            $this.StatusMessage = "Dry run $($this.Info)"
            Write-Message -Level Info "Dry run for miner '$($this.Name) $($this.Info)'..."
        }
        Else { 
            $this.StatusMessage = "Starting $($this.Info)"
            Write-Message -Level Info "Starting miner '$($this.Name) $($this.Info)'..."
            $this.Process = Invoke-CreateProcess -BinaryPath $this.Path -ArgumentList $this.GetCommandLineParameters() -WorkingDirectory (Split-Path $this.Path) -MinerWindowStyle $this.WindowStyle -Priority $this.ProcessPriority -EnvBlock $this.EnvVars -WindowTitle "$($this.Devices.Name -join ","): $($this.Name) $($this.Info)" -JobName $this.Name -LogFile $this.LogFile
        }
        $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }

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
            Cycle             = ""
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

        If ($this.Status -eq [MinerStatus]::DryRun) { 
            $this.Data = @()
            $this.StatStart = $this.BeginTime = (Get-Date).ToUniversalTime()
            $this.WorkersRunning = $this.Workers
        }
        Else { 
            0..50 | ForEach-Object { 
                If ($this.ProcessId = ($this.Process | Get-Job -ErrorAction SilentlyContinue | Receive-Job).ProcessId) { 
                    $this.Status = [MinerStatus]::Running
                    $this.StatusMessage = "Warming up $($this.Info)"
                    $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
                    $this.StatStart = $this.BeginTime = (Get-Date).ToUniversalTime()
                    $this.WorkersRunning = $this.Workers
                    $this.StartDataReader()
                    Break
                }
                Start-Sleep -Milliseconds 100
            }
            Else { 
                $this.Status = [MinerStatus]::Failed
                $this.StatusMessage = "Failed $($this.Info)"
                $this.Devices | ForEach-Object { $_.Status = "Failed" }
            }
        }
    }

    [MinerStatus]GetStatus() { 
        If ($this.Process.State -eq [MinerStatus]::Running -and $this.ProcessId -and (Get-Process -Id $this.ProcessId -ErrorAction Ignore).ProcessName) { # Use ProcessName, some crashed miners are dead but may still be found by their processId
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
            "DryRun" { 
                $this.Status = [MinerStatus]::DryRun
                $this.StartMining()
            }
            "Running" { 
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
        If ($this.Status -eq [MinerStatus]::Running -or $this.Status -eq [MinerStatus]::DryRun -or $this.StatusMessage -notlike "*$($this.Name)*") { 
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
            Stop-Process -Id $this.ProcessId -Force -ErrorAction SilentlyContinue
            $this.ProcessId = $null
        }

        If ($this.Process) { 
            If ($this.Process | Get-Job) { 
                $this.Process | Get-Job | Stop-Job | Receive-Job | Out-Null
                $this.Process | Get-Job | Remove-Job -Force
            }
            $this.Active += $this.Process.PSEndTime - $this.Process.PSBeginTime
            $this.Process = $null
        }

        $this.Status = If ($this.Status -eq [MinerStatus]::Running -or $this.Status -eq [MinerStatus]::DryRun) { [MinerStatus]::Idle } Else { [MinerStatus]::Failed }
        $this.Devices | ForEach-Object { $_.Status = $this.Status }
        $this.Devices | Where-Object { $_.State -eq [DeviceState]::Disabled } | ForEach-Object { $_.Status = "Disabled (ExcludeDeviceName: '$($_.Name)')" }

        # Log switching information to .\Logs\SwitchingLog
        [PSCustomObject]@{ 
            DateTime          = (Get-Date -Format o)
            Action            = If ($this.Status -eq [MinerStatus]::Idle) { "Stopped" } Else { "Failed" }
            Name              = $this.Name
            Accounts          = ($this.WorkersRunning.Pool.User | ForEach-Object { $_ -split "\." | Select-Object -First 1 } | Select-Object -Unique) -join "; "
            Algorithms        = $this.WorkersRunning.Pool.Algorithm -join "; "
            Benchmark         = $this.Benchmark
            CommandLine       = ""
            Cycle             = $this.Cycle
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
        ElseIf ($this.EndTime) { 
            Return $this.EndTime
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
        $TotalPowerUsage = [Double]0

        # Read power usage from HwINFO64 reg key, otherwise use hardconfigured value
        $RegistryData = Get-ItemProperty "HKCU:\Software\HWiNFO64\VSB"
        ForEach ($Device in $this.Devices) { 
            If ($RegistryEntry = $RegistryData.PSObject.Properties | Where-Object { ($_.Value -split " ") -contains $Device.Name }) { 
                $TotalPowerUsage += [Double]($RegistryData.($RegistryEntry.Name -replace "Label", "Value") -split ' ' | Select-Object -First 1)
            }
            Else { 
                $TotalPowerUsage += [Double]$Device.ConfiguredPowerUsage
            }
        }
        Remove-Variable Device
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
            If ($Hashrate_Samples.Count -lt 10 -or $Hashrate_Variance -gt 0.1) { 
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
            If ($PowerUsage_Samples.Count -lt 10 -or $PowerUsage_Variance -gt 0.1) { 
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
            If ($Stat = Get-Stat -Name "$($this.Name)_$($_.Pool.Algorithm)_Hashrate") { 
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

        If ($this.Workers[0].Hashrate -eq 0) { # Allow 0 hashrate on secondary algorithm
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

        $this.ReadPowerUsage = [Boolean]($this.Devices.ReadPowerUsage -notcontains $false)

        If ($CalculatePowerCost) { 
            If ($Stat = Get-Stat -Name "$($this.Name)$(If ($this.Workers.Count -eq 1) { "_$($this.Workers.Pool.Algorithm | Select-Object -First 1)" })_PowerUsage") { 
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
    $Variables.IdleRunspace = [runspacefactory]::CreateRunspace()
    # Set apartment state if available
    If ($Variables.IdleRunspace.ApartmentState) {
        $Variables.IdleRunspace.ApartmentState = "STA"
    }
    $Variables.IdleRunspace.ThreadOptions = "ReuseThread"      
    $Variables.IdleRunspace.Open()
    Get-Variable -Scope Global | Where-Object Name -in @("Config", "Variables") | ForEach-Object { 
        $Variables.IdleRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
    }
    $Variables.IdleRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath) | Out-Null
    $Variables.IdleRunspace | Add-Member MiningStatus "Running" -Force

    $PowerShell = [PowerShell]::Create()
    $PowerShell.Runspace = $Variables.IdleRunspace
    [Void]$PowerShell.AddScript(
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

                    $MiningStatusLabel.Text = "Idle | $($Variables.Branding.ProductLabel) $($Variables.Branding.Version)"
                    $MiningStatusLabel.ForeColor = [System.Drawing.Color]::Green
                }

                # System has been idle long enough, start mining
                If ($IdleSeconds -ge $Config.IdleSec -and $Variables.IdleRunspace.MiningStatus -ne "Running") { 
                    $Variables.IdleRunspace | Add-Member MiningStatus "Running" -Force

                    $MiningStatusLabel.Text = "Running | $($Variables.Branding.ProductLabel) $($Variables.Branding.Version)"
                    $MiningStatusLabel.ForeColor = [System.Drawing.Color]::Green
                }
                Start-Sleep -Seconds 1
            }
        }
    ) | Out-Null

    $Variables.IdleRunspace | Add-Member -Force @{ Name = "IdleRunspace"; Handle = $PowerShell.BeginInvoke(); PowerShell = $PowerShell; StartTime = (Get-Date).ToUniversalTime()}

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
        Write-Message -Level Info Write-Message -Level Verbose ($Variables.Summary -replace "<br>", " ")

        $Variables.Timer = $null
        $Variables.LastDonated = (Get-Date).AddDays(-1).AddHours(1)
        $Variables.Pools = [Pool[]]@()
        $Variables.Miners = [Miner[]]@()
        $Variables.MinersBest_Combo = [Miner[]]@()

        $Variables.CycleStarts = @()

        $Variables.CoreRunspace = [RunspaceFactory]::CreateRunspace()
        # Set apartment state if available
        If ($Variables.CoreRunspace.ApartmentState) {
            $Variables.CoreRunspace.ApartmentState = "STA"
        }
        $Variables.CoreRunspace.ThreadOptions = "ReuseThread"
        $Variables.CoreRunspace.Open()
        Get-Variable -Scope Global | Where-Object Name -in @("Config", "Stats", "Variables") | ForEach-Object { 
            $Variables.CoreRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
        }
        $Variables.CoreRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath) | Out-Null

        $PowerShell = [PowerShell]::Create()
        $PowerShell.Runspace = $Variables.CoreRunspace
        [Void]$PowerShell.AddScript("$($Variables.MainPath)\Includes\Core.ps1") | Out-Null

        $Variables.CoreRunspace | Add-Member -Force @{ Name = "CoreRunspace"; Handle = $PowerShell.BeginInvoke(); PowerShell = $PowerShell; StartTime = (Get-Date).ToUniversalTime()}

        $Variables.Summary = "Mining processes are running."
    }
}

Function Stop-Mining { 
    
    Param(
        [Parameter(Mandatory = $false)]
        [Switch]$Quick = $false
    )

    If ($Variables.CoreRunspace) { 
        $Variables.Summary = "Stopping mining processes..."
        # Give core loop time to shut down gracefully
        $Timestamp = (Get-Date).AddSeconds(30)
        While (-not $Quick -and ($Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running -or $_.Status -eq [MinerStatus]::DryRun }) -and (Get-Date) -le $Timestamp) { 
            Start-Sleep -Seconds 1
        }

        #Stop all running miners
        $Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running -or $_.Status -eq [MinerStatus]::DryRun } | ForEach-Object { 
            $_.SetStatus([MinerStatus]::Idle)
            $_.Info = ""
            $_.WorkersRunning = @()
        }

        $Variables.CoreRunspace.Close()
        If ($Variables.CoreRunspace.PowerShell) { $Variables.CoreRunspace.PowerShell.Dispose() }
        $Variables.CoreRunspace.Dispose()
        $Variables.Remove("CoreRunspace")
    }

    If ($Variables.NewMiningStatus -eq "Idle") { 
        $Variables.Pools = $Variables.PoolsBest = $Variables.PoolsNew = [Pool[]]@()
        $Variables.PoolsCount = 0
        $Variables.Miners = $Variables.MinersBest = $Variables.MinersBest_Combos = $Variables.MinersMostProfitable = $Variables.RunningMiners = [Miner[]]@()
    }
    $Variables.MinersBest_Combo = [Miner[]]@()
    $Variables.MiningEarning = $Variables.MiningProfit = $Variables.MiningPowerCost = [Double]::NaN
    $Variables.EndCycleTime = $null
    $Variables.WatchdogTimers = @()
    $Variables.CycleStarts = @()

    [System.GC]::GetTotalMemory("forcefullcollection") | Out-Null

    $Error.Clear()
}

Function Start-Brain { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Brains
    )

    If ($Brains -and (Test-Path -Path ".\Brains" -PathType Container)) { 

        # Starts Brains if necessary
        $BrainsStarted = @()
        $Brains | ForEach-Object { 
            If ($Config.PoolsConfig.$_.BrainConfig -and -not $Variables.Brains.$_) { 
                $BrainScript = ".\Brains\$($_).ps1"
                If (Test-Path -Path $BrainScript -PathType Leaf) { 
                    If (-not $Variables.BrainRunspacePool) { 

                        # https://stackoverflow.com/questions/38102068/sessionstateproxy-variable-with-runspace-pools
                        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

                        # Create the sessionstate variable entries
                        (Get-Variable -Scope Global | Where-Object Name -in @("Config", "Stats", "Variables")).Name | ForEach-Object { 
                            $InitialSessionState.Variables.Add((New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $_, (Get-Variable $_ -ValueOnly), $null))
                        }
                        $Variables.BrainRunspacePool = [RunspaceFactory]::CreateRunspacePool(1, (Get-Item -Path ".\Brains\*.ps1").Count, $InitialSessionState, $Host)
                        $Variables.BrainRunspacePool.Open()
                        $Variables.Brains = @{ }
                        $Variables.BrainData = [PSCustomObject]@{ }
                    }

                    $PowerShell = [PowerShell]::Create()
                    $PowerShell.RunspacePool = $Variables.BrainRunspacePool
                    [Void]$PowerShell.AddScript($BrainScript) | Out-Null
                    $Variables.Brains.$_ = @{ Name = $_; Handle = $PowerShell.BeginInvoke(); PowerShell = $PowerShell; StartTime = (Get-Date).ToUniversalTime()}
                    $BrainsStarted += $_
                }
            }
        }

        If ($BrainsStarted.Count -gt 0) { Write-Message -Level Info "Pool brain backgound job$(If ($BrainsStarted.Count -gt 1) { "s" }) for '$($BrainsStarted -join ", ")' started." }
    }
    Else {
        Write-Message -Level Error "Failed to start Pool brain backgound jobs. Directory '.\Brains' is missing."
    }
}

Function Stop-Brain { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Brains = $Variables.Brains.Keys
    )

    If ($Brains) { 

        $BrainsStopped = @()

        $Brains | Where-Object { $Variables.Brains.$_ } | ForEach-Object { 
            # Stop Brains
            $Variables.Brains.$_.PowerShell.Dispose()
            $Variables.Brains.Remove($_)
            $Variables.BrainData.PSObject.Properties.Remove($_)
            $BrainsStopped += $_
        }

        [System.GC]::GetTotalMemory("forcefullcollection") | Out-Null

        If ($BrainsStopped.Count -gt 0) { Write-Message -Level Info  "Pool brain backgound job$(If ($BrainsStopped.Count -gt 1) { "s" }) for '$(($BrainsStopped | Sort-Object) -join ", ")' stopped." }
    }

    If ($Variables.BrainRunspacePool -and -not $Variables.Brains.Keys.Count) { 
        $Variables.BrainRunspacePool.Close()
        $Variables.BrainRunspacePool.Dispose()
        $Variables.Remove("Brains")
        $Variables.Remove("BrainData")
        $Variables.Remove("BrainRunspacePool")

        [System.GC]::GetTotalMemory("forcefullcollection") | Out-Null
    }
}

Function Start-BalancesTracker { 

    If (-not $Variables.BalancesTrackerRunspace) { 

        If (Test-Path -Path ".\Balances" -PathType Container) { 
            Try { 
                $Variables.Summary = "Starting Balances Tracker background process..."
                Write-Message -Level Verbose ($Variables.Summary -replace "<br>", " ")

                $Variables.BalancesTrackerRunspace = [runspacefactory]::CreateRunspace()
                $Variables.BalancesTrackerRunspace.Open()
                Get-Variable -Scope Global | Where-Object Name -in @("Config", "Variables") | ForEach-Object { 
                    $Variables.BalancesTrackerRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
                }
                $Variables.BalancesTrackerRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath) | Out-Null

                $PowerShell = [PowerShell]::Create()
                $PowerShell.Runspace = $Variables.BalancesTrackerRunspace
                [Void]$PowerShell.AddScript("$($Variables.MainPath)\Includes\BalancesTracker.ps1") | Out-Null

                $Variables.BalancesTrackerRunspace | Add-Member -Force @{ Name = "BalancesTrackerRunspace"; Handle = $PowerShell.BeginInvoke(); PowerShell = $PowerShell; StartTime = (Get-Date).ToUniversalTime()}

            }
            Catch { 
                Write-Message -Level Error "Failed to start Balances Tracker [$Error[0]]."
            }
        }
        Else { 
            Write-Message -Level Error "Failed to start Balances Tracker. Directory '.\Balances' is missing."
        }
    }
}

Function Stop-BalancesTracker { 

    If ($Variables.BalancesTrackerRunspace) { 

        $Variables.BalancesTrackerRunspace.Close()
        If ($Variables.BalancesTrackerRunspace.PowerShell) { $Variables.BalancesTrackerRunspace.PowerShell.Dispose() }
        $Variables.BalancesTrackerRunspace.Dispose()
        $Variables.Remove("BalancesTrackerRunspace")

        $Variables.Summary += "<br>Balances Tracker background process stopped."
        Write-Message -Level Info "Balances Tracker background process stopped."
    }
}

Function Initialize-Application { 
    # Verify donation data
    $Variables.DonationData = Get-Content -Path ".\Data\DonationData.json" | ConvertFrom-Json -NoEnumerate
    If (-not $Variables.DonationData) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\DonationData.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\DonationData.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Verify donation log
    $Variables.DonationLog = Get-Content -Path ".\Logs\DonateLog.json" | ConvertFrom-Json -NoEnumerate
    If (-not $Variables.DonationLog) { 
        $Variables.DonationLog = @()
    }
    # Load algorithm list
    $Variables.Algorithms = Get-Content -Path ".\Data\Algorithms.json" | ConvertFrom-Json
    If (-not $Variables.Algorithms) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\Algorithms.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\Algorithms.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load coin names
    $Global:CoinNames = Get-Content -Path ".\Data\CoinNames.json" | ConvertFrom-Json
    If (-not $Global:CoinNames) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\CoinNames.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\CoinNames.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load EquihashCoinPers data
    $Global:EquihashCoinPers = Get-Content -Path ".\Data\EquihashCoinPers.json" | ConvertFrom-Json
    If (-not $Global:EquihashCoinPers) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\EquihashCoinPers.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\EquihashCoinPers.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load currency algorithm data
    $Global:CurrencyAlgorithm = Get-Content -Path ".\Data\CurrencyAlgorithm.json" | ConvertFrom-Json
    If (-not $Global:CurrencyAlgorithm) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Start-Sleep -Seconds 10
        Exit
    }
    # Load regions list
    $Variables.Regions = Get-Content -Path ".\Data\Regions.json" | ConvertFrom-Json
    If (-not $Variables.Regions) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\Regions.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\Regions.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load FIAT currencies list
    $Variables.FIATcurrencies = Get-Content -Path ".\Data\FIATcurrencies.json" | ConvertFrom-Json
    If (-not $Variables.FIATcurrencies) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\FIATcurrencies.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\FIATcurrencies.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load DAG data, if not available it will get recreated
    $Variables.DAGdata = Get-Content ".\Data\DagData.json" | ConvertFrom-Json -AsHashtable

    # Load PoolsLastUsed data
    $Variables.PoolsLastUsed = Get-Content -Path ".\Data\PoolsLastUsed.json" | ConvertFrom-Json -AsHashtable
    If (-not $Variables.PoolsLastUsed.Keys) { $Variables.PoolsLastUsed = @{ } }

    # Load AlgorithmsLastUsed data
    $Variables.AlgorithmsLastUsed = Get-Content -Path ".\Data\AlgorithmsLastUsed.json" | ConvertFrom-Json -AsHashtable
    If (-not $Variables.AlgorithmsLastUsed.Keys) { $Variables.AlgorithmsLastUsed = @{ } }

    # Load EarningsChart data to make it available early in Web GUI
    If (Test-Path -Path ".\Data\EarningsChartData.json" -PathType Leaf) { $Variables.EarningsChartData = Get-Content ".\Data\EarningsChartData.json" | ConvertFrom-Json }

    # Keep only the last 10 files
    Get-ChildItem -Path ".\Logs\$($Variables.Branding.ProductLabel)_*.log" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path ".\Logs\SwitchingLog_*.csv" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path "$($Variables.ConfigFile)_*.backup" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse

    If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12 }

    If ($Config.Proxy -eq "") { $PSDefaultParameterValues.Remove("*:Proxy") }
    Else { $PSDefaultParameterValues["*:Proxy"] = $Config.Proxy }

    # Set process priority to BelowNormal to avoid hashrate drops on systems with weak CPUs
    (Get-Process -Id $PID).PriorityClass = "BelowNormal"
}

Function Get-DefaultAlgorithm { 

    If ($PoolsAlgos = Get-Content ".\Data\PoolsConfig-Recommended.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue) { 
        Return ($PoolsAlgos.PSObject.Properties.Name | Where-Object { $_ -in @(Get-PoolBaseName $Config.PoolName) } | ForEach-Object { $PoolsAlgos.$_.Algorithm }) | Sort-Object -Unique
    }
    Return
}

Function Get-CommandLineParameter { 
    Param(
        [Parameter(Mandatory = $false)]
        [String]$Arguments
    )

    If ($Arguments -and (Test-Json -Json $Arguments -ErrorAction Ignore)) { $Arguments = ($Arguments | ConvertFrom-Json).Arguments }
    Return $Arguments
}

Function Get-Rate { 
    # Read exchange rates from min-api.cryptocompare.com, use stored data as fallback
    $RatesCacheFileName = "Cache\Rates.json"
    $RatesCache = Get-Content -Path $RatesCacheFileName -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue

    If (-not $RatesCache.Values) { $RatesCache = [PSCustomObject]@{ } }
    $RatesValues = $RatesCache.Values
    $AllCurrencies = $RatesCache.Currencies
    # Use stored currencies from last run
    If (-not $Variables.BalancesCurrencies -and $Config.BalancesTrackerPollInterval) { $Variables.BalancesCurrencies = $AllCurrencies }

    $Variables.AllCurrencies = @(@($Config.Currency) + @($Config.Wallets.Keys) + @($Config.ExtraCurrencies) + @($Variables.BalancesCurrencies)) -replace "mBTC", "BTC" | Sort-Object -Unique

    If (-not $Variables.Rates.BTC.($Config.Currency) -or (Compare-Object @($Variables.Rates.PSObject.Properties.Name | Select-Object) @($Variables.AllCurrencies | Select-Object) | Where-Object SideIndicator -eq "=>") -or ($Variables.RatesUpdated -lt (Get-Date).ToUniversalTime().AddMinutes(-(3, $Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum))) { 
        Try { 
            $RatesValues = [PSCustomObject]@{ BTC = [PSCustomObject]@{} }
            $TSymBatches = @()
            $TSyms = "BTC"
            $Variables.AllCurrencies | Where-Object { $_ -ne "mBTC" } | Select-Object -Unique | ForEach-Object { 
                If ($TSyms.Length -lt (100 - $_.length -1)) { 
                    $TSyms = "$TSyms,$($_)"
                }
                Else { 
                    $TSymBatches += $TSyms
                    $TSyms = "$_"
                }
            }
            $TSymBatches += $TSyms

            $TSymBatches | ForEach-Object { 
                (Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$($_)$($Config.CryptoCompareAPIKeyParam)&extraParams=$($Variables.Branding.BrandWebSite) Version $($Variables.Branding.Version)" -TimeoutSec 5 -ErrorAction Ignore).BTC | ForEach-Object { 
                    $_.PSObject.Properties | ForEach-Object { $RatesValues.BTC | Add-Member @{ "$($_.Name)" = ($_.Value) } }
                }
            }

            If ($RatesValues) { 
                $Currencies = ($RatesValues.BTC | Get-Member -MemberType NoteProperty).Name
                $Currencies | Select-Object | Where-Object { $_ -ne "BTC" } | ForEach-Object { 
                    $Currency = $_
                    $RatesValues | Add-Member $Currency ($RatesValues.BTC.PSObject.Copy()) -Force
                    ($RatesValues.$Currency | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
                        $RatesValues.$Currency | Add-Member $_ ([Double]$RatesValues.BTC.$_ / $RatesValues.BTC.$Currency) -Force
                    }
                }
                Write-Message -Level Info "Loaded currency exchange rates from 'min-api.cryptocompare.com'.$(If ($MissingCurrencies = Compare-Object $Currencies $Variables.AllCurrencies -PassThru) { " API does not provide rates for '$($MissingCurrencies -join ', ')'." })"
                $Variables.Rates = $RatesValues
                $Variables.RatesUpdated = (Get-Date).ToUniversalTime()

                $RatesCache | Add-Member @{ Currencies = $Variables.AllCurrencies } -Force
                $RatesCache | Add-Member @{ Values = $RatesValues } -Force
                $RatesCache | ConvertTo-Json -Depth 5 | Out-File -FilePath $RatesCacheFileName -Encoding utf8NoBOM -Force -ErrorAction SilentlyContinue
            }
        }
        Catch { 
            If ($RatesCache.PSObject.Properties.Name) { 
                $Variables.Rates = $RatesCache
                $Variables.RatesUpdated = "FromFile: $((Get-Item -Path $RatesCacheFileName).CreationTime.ToUniversalTime())"
                Write-Message -Level Warn "Could not load exchange rates from 'min-api.cryptocompare.com'. Using cached data from $((Get-Item -Path $RatesCacheFileName).LastWriteTime)."
            }
            Else { 
                Write-Message -Level Warn "Could not load exchange rates from 'min-api.cryptocompare.com'."
            }
        }
    }

    If ($Config.UsemBTC) { 
        # Add mBTC
        $Currencies = ($Variables.Rates.BTC | Get-Member -MemberType NoteProperty).Name
        $Currencies | ForEach-Object { 
            $Currency = $_
            $mCurrency = "m$($Currency)"
            # $Variables.Rates | Add-Member $mCurrency ($Variables.Rates.$Currency | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json)
            $Variables.Rates | Add-Member $mCurrency ($Variables.Rates.$Currency.PSObject.Copy()) -Force
            ($Variables.Rates.$mCurrency | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
                $Variables.Rates.$mCurrency | Add-Member $_ ([Double]$Variables.Rates.$Currency.$_ / 1000) -Force
            }
        }
        ($Variables.Rates | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
            $Currency = $_
            ($RatesValues | Get-Member -MemberType NoteProperty).Name | Where-Object { $_ -in $Currencies } | ForEach-Object { 
                $mCurrency = "m$($_)"
                $Variables.Rates.$Currency | Add-Member $mCurrency ([Double]$Variables.Rates.$Currency.$_ * 1000) -Force
            }
        }
    }
}

Function Write-Message { 

    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Message, 
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info", "Verbose", "Debug")]
        [String]$Level = "Info"
    )

    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Write to console
    Switch ($Level) { 
        "Error"   { Write-Host $Message -ForegroundColor "Red" }
        "Warn"    { Write-Host $Message -ForegroundColor "Magenta" }
        "Info"    { Write-Host $Message -ForegroundColor "White" }
        "Verbose" { Write-Host $Message -ForegroundColor "Yello" }
        "Debug"   { Write-Host $Message -ForegroundColor "Blue" }
    }

    $Message = "$Date $($Level.ToUpper()): $Message"

    Try { 
        # Ignore error when legacy GUI gets closed
        If ($Level -in $Config.LogToScreen) { 
            # Update status text box in legacy GUI, scroll to end if no text is selected
            If ($Variables.TextBoxSystemLog.AppendText) { 
                If ($SelectionLength = $Variables.TextBoxSystemLog.SelectionLength) { 
                    $SelectionStart = $Variables.TextBoxSystemLog.SelectionStart
                    $Variables.TextBoxSystemLog.Lines += $Message
                    $Variables.TextBoxSystemLog.Select($SelectionStart, $SelectionLength)
                    $Variables.TextBoxSystemLog.ScrollToCaret()
                }
                Else { 
                    $Variables.TextBoxSystemLog.AppendText("`r`n$Message")
                }
            }
        }

        If ($Level -in $Config.LogToFile) { 
            # Get mutex. Mutexes are shared across all threads and processes. 
            # This lets us ensure only one thread is trying to write to the file at a time. 
            $Mutex = New-Object System.Threading.Mutex($false, $Variables.Branding.ProductLabel)

            $Variables.LogFile = "$($Variables.MainPath)\Logs\$($Variables.Branding.ProductLabel)_$(Get-Date -Format "yyyy-MM-dd").log"

            # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, write to the log file and release mutex. Otherwise, display an error. 
            If ($Mutex.WaitOne(1000)) { 
                $Message | Out-File -FilePath $Variables.LogFile -Append -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                [Void]$Mutex.ReleaseMutex()
            }
            Else { 
                Write-Error -Message "Log file is locked, unable to write message to '$($LogFile)'."
            }
        }
    }
    Catch { }
}

Function Update-MonitoringData { 

    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip If server and user aren't filled out
    If (-not $Config.MonitoringServer) { Return }
    If (-not $Config.MonitoringUser) { Return }

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
        version = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version.ToString())"
        status  = $Variables.NewMiningStatus
        profit  = If ([Double]::IsNaN($Variables.MiningProfit)) { "n/a" } Else { [String]$Variables.MiningProfit } # Earnings is NOT profit! Needs to be changed in mining monitor server
        data    = ConvertTo-Json $Data
    }

    # Send the request
    Try { 
        $Response = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/report.php" -Method Post -Body $Body -TimeoutSec 10 -ErrorAction Stop
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

Function Read-MonitoringData { 

    If ($Config.ShowWorkerStatus -and $Config.MonitoringUser -and $Config.MonitoringServer -and $Variables.WorkersLastUpdated -lt (Get-Date).AddSeconds(-30)) { 
        Try { 
            $Workers = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/workers.php" -Method Post -Body @{ user = $Config.MonitoringUser } -TimeoutSec 10 -ErrorAction Stop
            # Calculate some additional properties and format others
            $Workers | ForEach-Object { 
                # Convert the unix timestamp to a datetime object, taking into account the local time zone
                $_ | Add-Member -Force @{ date = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.lastseen)) }

                # If a machine hasn't reported in for > 10 minutes, mark it as offline
                $TimeSince = New-TimeSpan -Start $_.date -End (Get-Date)
                If ($TimeSince.TotalMinutes -gt 10) { $_.status = "Offline" }
            }
            $Variables.Workers = $Workers
            $Variables.WorkersLastUpdated = (Get-Date)

            Write-Message -Level Verbose "Retrieved worker status from '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
        Catch { 
            Write-Message -Level Warn "Monitoring: Unable to retrieve worker data from '$($Config.MonitoringServer)' [ID $($Config.MonitoringUser)]."
        }
    }
}

Function Get-TimeSince { 

    # Show friendly time since in days, hours, minutes and seconds

    Param(
        [Parameter(Mandatory = $true)]
        [datetime]$TimeStamp
    )

    $TimeSpan = New-TimeSpan -Start $TimeStamp -End (Get-Date)
    $TimeSince= ""

    If ($TimeSpan.Days -ge 1) { $TimeSince += " {0:n0} day$(If ($TimeSpan.Days -ne 1) { "s" })" -f $TimeSpan.Days }
    If ($TimeSpan.Hours -ge 1) { $TimeSince += " {0:n0} hour$(If ($TimeSpan.Hours -ne 1) { "s" })" -f $TimeSpan.Hours }
    If ($TimeSpan.Minutes -ge 1) { $TimeSince += " {0:n0} minute$(If ($TimeSpan.Minutes -ne 1) { "s" })" -f $TimeSpan.Minutes }
    If ($TimeSpan.Seconds -ge 1) { $TimeSince += " {0:n0} second$(If ($TimeSpan.Seconds -ne 1) { "s" })" -f $TimeSpan.Seconds }
    If ($TimeSince) { $TimeSince += " ago" } Else { $TimeSince = "just now" }

    Return $TimeSince.Trim()
}

Function Merge-Hashtable { 
    Param(
        [Parameter(Mandatory = $true)]
        [Hashtable]$HT1, 
        [Parameter(Mandatory = $true)]
        [Hashtable]$HT2, 
        [Parameter(Mandatory = $false)]
        [Boolean]$Unique = $false
    )

    $HT2.Keys | ForEach-Object { 
        If ($HT1.$_ -is [Hashtable]) { 
            $HT1.$_ = Merge-Hashtable -HT1 $HT1.$_ -Ht2 $HT2.$_ -Unique $Unique
        }
        ElseIf ($HT1.$_ -is [Array]) { 
            If ($HT2.$_) { 
                $HT1.$_ += $HT2.$_
                If ($Unique) { $HT1.$_ = ($HT1.$_ | Sort-Object -Unique) -as [Array] }
            }
        }
        Else { 
            $HT1.$_ = $HT2.$_ -as $HT2.$_.GetType()
        }
    }
    Return $HT1
}

Function Get-RandomDonationPoolsConfig { 
    # Randomize donation data
    # Build pool config with available donation data, not all devs have the same set of wallets available

    $Variables.DonationRandom = $Variables.DonationData | Get-Random
    $DonationRandomPoolsConfig = [Ordered]@{ }
    (Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique | ForEach-Object { 
        $PoolConfig = $Config.PoolsConfig.$_ | ConvertTo-Json -Depth 99 -Compress | ConvertFrom-Json -AsHashTable
        $PoolConfig.EarningsAdjustmentFactor = 1
        $PoolConfig.Region = $Config.PoolsConfig.$_.Region
        $PoolConfig.WorkerName = "$($Variables.Branding.ProductLabel)-$($Variables.Branding.Version.ToString())-donate$($Config.Donation)"
        Switch -regex ($_) { 
            "^MiningDutch$|^MiningPoolHub$|^ProHashing$" { 
                If ($Variables.DonationRandom."$($_)UserName") { 
                    # not all devs have a known HashCryptos, MiningDutch or ProHashing account
                    $PoolConfig.UserName = $Variables.DonationRandom."$($_)UserName"
                    $PoolConfig.Variant = $Config.PoolsConfig.$_.Variant
                    $DonationRandomPoolsConfig.$_ = $PoolConfig
                }
                Break
            }
            Default { 
                # not all devs have a known ETC or ETH address
                If (Compare-Object @($Variables.PoolData.$_.GuaranteedPayoutCurrencies | Select-Object) @($Variables.DonationRandom.Wallets.PSObject.Properties.Name | Select-Object) -IncludeEqual -ExcludeDifferent) { 
                    $PoolConfig.Variant = If ($Config.PoolsConfig.$_.Variant) { $Config.PoolsConfig.$_.Variant } Else { $Config.PoolName -match $_ }
                    $PoolConfig.Wallets = $Variables.DonationRandom.Wallets | ConvertTo-Json | ConvertFrom-Json -AsHashtable
                    $DonationRandomPoolsConfig.$_ = $PoolConfig
                }
                Break
            }
        }
    }

    Return $DonationRandomPoolsConfig
}

Function Read-Config { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    Function Get-DefaultConfig { 

        $DefaultConfig = @{}

        $DefaultConfig.ConfigFileVersion = $Variables.Branding.Version.ToString()
        $Variables.FreshConfig = $true

        # Add default enabled pools
        If (Test-Path -Path ".\Data\PoolsConfig-Recommended.json" -PathType Leaf) { 
            $Temp = (Get-Content ".\Data\PoolsConfig-Recommended.json" | ConvertFrom-Json)
            $DefaultConfig.PoolName = $Temp.PSObject.Properties.Name | Where-Object { $_ -ne "Default" } | ForEach-Object { $Temp.$_.Variant.PSObject.Properties.Name }
        }

        # Add default config items
        $Variables.AllCommandLineParameters.Keys | Where-Object { $_ -notin $DefaultConfig.Keys } | ForEach-Object { 
            $Value = $Variables.AllCommandLineParameters.$_
            If ($Value -is [Switch]) { $Value = [Boolean]$Value }
            $DefaultConfig.$_ = $Value
        }
        # MinerInstancePerDeviceModel: Default to $true if more than one device model per vendor
        $DefaultConfig.MinerInstancePerDeviceModel = ($Variables.Devices | Group-Object Vendor | ForEach-Object { ($_.Group.Model | Sort-Object -Unique).Count } | Measure-Object -Maximum).Maximum -gt 1

        Return $DefaultConfig
    }

    # Load the configuration
    If (Test-Path -Path $ConfigFile -PathType Leaf) { 
        $Local:Config = Get-Content $ConfigFile | ConvertFrom-Json -AsHashtable -ErrorAction Ignore | Select-Object
        If ($Local:Config.Keys.Count -eq 0 -or $Local:Config -isnot [Hashtable]) { 
            $CorruptConfigFile = "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").corrupt"
            Move-Item -Path $ConfigFile $CorruptConfigFile -Force
            $Message = "Configuration file '$ConfigFile' is corrupt and was renamed to '$CorruptConfigFile'."
            Write-Message -Level Warn $Message
            $Local:Config = Get-DefaultConfig
            $Variables.FreshConfigText = "$Message`n`nUse the configuration editor ('http://127.0.0.1:$($Local:Config.APIPort)') to change your settings and apply the configuration.`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!"
        }
        Else { 
            $Variables.ConfigFileTimestamp = (Get-Item -Path $Variables.ConfigFile).LastWriteTime
            $Variables.AllCommandLineParameters.Keys | Sort-Object | ForEach-Object { 
                If ($_ -in $Local:Config.Keys) { 
                    # Upper / lower case conversion of variable keys (Web GUI is case sensitive)
                    $Value = $Local:Config.$_
                    $Local:Config.Remove($_)
                    If ($Variables.AllCommandLineParameters.$_ -is [Switch]) { 
                        $Local:Config.$_ = [Boolean]$Value
                    }
                    ElseIf ($Variables.AllCommandLineParameters.$_ -is [Array]) { 
                        $Local:Config.$_ = [Array]$Value
                    }
                    Else { 
                        $Local:Config.$_ = $Value -as $Variables.AllCommandLineParameters.$_.GetType().Name
                    }
                }
                Else { 
                    # Config parameter not in config file - use hardcoded value
                    $Local:Config.$_ = $Variables.AllCommandLineParameters.$_
                }
            }
        }
        If ($Local:Config.EarningsAdjustmentFactor -le 0 -or $Local:Config.EarningsAdjustmentFactor -gt 10) { 
            $Local:Config.EarningsAdjustmentFactor = 1
            Write-Message -Level Warn "Default Earnings adjustment factor (value: $($Local:Config.EarningsAdjustmentFactor)) is not within supported range (0 - 10); using default value $($Local:Config.EarningsAdjustmentFactor)."
        }
    }
    Else { 
        Write-Message -Level Warn "No valid configuration file '$ConfigFile' found."
        $Variables.FreshConfigText = "This is the first time you have started $($Variables.Branding.ProductLabel).`n`nUse the configuration editor to change your settings and apply the configuration.`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!"
        $Local:Config = Get-DefaultConfig
    }

    # Build in memory pool config
    $PoolsConfig = @{ }
    (Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique | ForEach-Object { 
        $PoolName = $_
        If ($DefaultPoolConfig = $Variables.PoolData.$PoolName) { 
            If ($PoolConfig = $Config.PoolsConfig.$PoolName) { 
                # Merge default config data with use pool config
                $PoolConfig = Merge-Hashtable -HT1 $DefaultPoolConfig -HT2 $PoolConfig -Unique $true
            }
            Else { 
                $PoolConfig = $DefaultPoolConfig
            }

            If (-not $PoolConfig.EarningsAdjustmentFactor) {
                 $PoolConfig.EarningsAdjustmentFactor = $Local:Config.EarningsAdjustmentFactor
            }
            If ($PoolConfig.EarningsAdjustmentFactor -le 0 -or $PoolConfig.EarningsAdjustmentFactor -gt 10) { 
                $PoolConfig.EarningsAdjustmentFactor = $Local:Config.EarningsAdjustmentFactor
                Write-Message -Level Warn "Earnings adjustment factor (value: $($PoolConfig.EarningsAdjustmentFactor)) for pool '$PoolName' is not within supported range (0 - 10); using configured value $($PoolConfig.EarningsAdjustmentFactor)."
            }

            If (-not $PoolConfig.WorkerName) { $PoolConfig.WorkerName = $Local:Config.WorkerName }
            If (-not $PoolConfig.BalancesKeepAlive) { $PoolConfig.BalancesKeepAlive = $PoolData.$PoolName.BalancesKeepAlive }

            $PoolConfig.Region = $DefaultPoolConfig.Region | Where-Object { (Get-Region $_) -notin @($PoolConfig.ExcludeRegion) }

            Switch ($PoolName) { 
                "Hiveon" { 
                    If (-not $PoolConfig.Wallets) { 
                        $PoolConfig.Wallets = [Ordered]@{ }
                        $Local:Config.Wallets.GetEnumerator().Name | Where-Object { $_ -in $PoolConfig.PayoutCurrencies } | ForEach-Object { 
                            $PoolConfig.Wallets.$_ = $Local:Config.Wallets.$_
                        }
                    }
                }
                "MiningDutch" { 
                    If ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $Local:Config.PayoutCurrency }
                    If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $Local:Config.MiningDutchUserName }
                    If (-not $PoolConfig.Wallets) { $PoolConfig.Wallets = @{ "$($PoolConfig.PayoutCurrency)" = $($Local:Config.Wallets.($PoolConfig.PayoutCurrency)) } }
                }
                "MiningPoolHub" { 
                    If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $Local:Config.MiningPoolHubUserName }
                }
                "NiceHash" { 
                    If (-not $PoolConfig.Variant."Nicehash Internal".Wallets.BTC) { 
                        If ($Local:Config.NiceHashWallet -and $Local:Config.NiceHashWalletIsInternal) { $PoolConfig.Variant."NiceHash Internal".Wallets = @{ "BTC" = $Local:Config.NiceHashWallet } }
                    }
                    If (-not $PoolConfig.Variant."Nicehash External".Wallets.BTC) { 
                        If ($Local:Config.NiceHashWallet -and -not $Local:Config.NiceHashWalletIsInternal) { $PoolConfig.Variant."NiceHash External".Wallets = @{ "BTC" = $Local:Config.NiceHashWallet } }
                        ElseIf ($Local:Config.Wallets.BTC) { $PoolConfig.Variant."NiceHash External".Wallets = @{ "BTC" = $Local:Config.Wallets.BTC } }
                    }
                }
                "ProHashing" { 
                    If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $Local:Config.ProHashingUserName }
                    If (-not $PoolConfig.MiningMode) { $PoolConfig.MiningMode = $Local:Config.ProHashingMiningMode }
                }
                Default { 
                    If ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $Local:Config.PayoutCurrency }
                    If (-not $PoolConfig.Wallets) { $PoolConfig.Wallets = @{ "$($PoolConfig.PayoutCurrency)" = $($Local:Config.Wallets.($PoolConfig.PayoutCurrency)) } }
                    $PoolConfig.Remove("PayoutCurrency")
                }
            }
            If ($PoolConfig.Algorithm) { $PoolConfig.Algorithm = @($PoolConfig.Algorithm -replace " " -split ",") }
            $PoolsConfig.$PoolName = $PoolConfig
        }
    }
    $Local:Config.PoolsConfig = $PoolsConfig
    # Must update existing thread safe variable. Reassignment breaks updates to instances in other threads
    $Local:Config.Keys | ForEach-Object { $Global:Config.$_ = $Local:Config.$_ }
}

Function Write-Config { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile, 
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    $Header = 
"// This file was generated by $($Variables.Branding.ProductLabel)
// $($Variables.Branding.ProductLabel) will automatically add / convert / rename / update new settings when updating to a new version
"
    If (Test-Path -Path $ConfigFile -PathType Leaf) { 
        Copy-Item -Path $ConfigFile -Destination "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").backup"
        Get-ChildItem -Path "$($ConfigFile)_*.backup" -File | Sort-Object LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
    }

    $Config.Remove("ConfigFile")
    "$Header$($Config | Get-SortedObject | ConvertTo-Json -Depth 10)" | Out-File -FilePath $ConfigFile -Force -Encoding utf8NoBOM
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
            [Win32]::GetWindowThreadProcessId([Win32]::GetForegroundWindow(), [ref]$FGWindowPid) | Out-Null
            $MainWindowHandle = (Get-Process -Id $NotepadProcess.ProcessId).MainWindowHandle
            If ($NotepadProcess.ProcessId -ne $FGWindowPid) {
                If ([Win32]::GetForegroundWindow() -ne $MainWindowHandle) { 
                    [Win32]::ShowWindowAsync($MainWindowHandle, 6) | Out-Null # SW_MINIMIZE 
                    [Win32]::ShowWindowAsync($MainWindowHandle, 9) | Out-Null # SW_RESTORE
                }
            }
            Start-Sleep -MilliSeconds 100
        }
        Catch { }
    }

    If ($FileWriteTime -ne (Get-Item -Path $FileName).LastWriteTime) { 
        Write-Message -Level Verbose "Saved '$FileName'. Changes will become active in next cycle."
        Return "Saved '$FileName'.`nChanges will become active in next cycle."
    }
    Else { 
        Return "No changes to '$FileName' made."
    }
}

Function Get-SortedObject { 

    Param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [Object]$Object
    )
    Try { 
        Switch -Regex ($Object.GetType().Name) { 
            "PSCustomObject" { 
                $SortedObject = [PSCustomObject]@{ }
                $Object.PSObject.Properties.Name | Sort-Object | ForEach-Object { 
                    If ($Object.$_ -is [Array]) { 
                        $SortedObject | Add-Member $_ @(Get-SortedObject $Object.$_)
                    }
                    Else { 
                        $SortedObject | Add-Member $_ (Get-SortedObject $Object.$_)
                    }
                }
            }
            "Hashtable|OrderedDictionary|SyncHashtable" { 
                $SortedObject = [Ordered]@{ }
                $Object.GetEnumerator().Name | Sort-Object | ForEach-Object { 
                    If ($Object.$_ -is [Array]) { 
                        $SortedObject.$_ = @(Get-SortedObject $Object.$_)
                    }
                    Else { 
                        $SortedObject.$_ = (Get-SortedObject $Object.$_)
                    }
                }
            }
            Default { 
                $SortedObject = $Object | Sort-Object
            }
        }
    }
    Catch {
    }

    Return $SortedObject
}

Function Enable-Stat { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    If ($Stat = Get-Stat -Name $Name) { 

        $Path = "Stats\$Name.txt"

        $Stat.Disabled = $false
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
    }
}

Function Disable-Stat { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    If (-not $Stat) { $Stat = (Set-Stat -Name $Name -Value 0) }

    $Path = "Stats\$Name.txt"

    $Stat.Disabled = $true
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
    $Stat = Get-Stat -Name $Name

    If ($Stat -is [Hashtable] -and $Stat.IsSynchronized -and -not [Double]::IsNaN($Stat.Minute_Fluctuation)) { 
        If (-not $Stat.Timer) { $Stat.Timer = $Stat.Updated.AddMinutes(-1) }
        If (-not $Duration) { $Duration = $Updated - $Stat.Timer }
        If ($Duration -le 0) { Return $Stat }

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
            If (-not $Stat.Disabled -and ($Value -eq 0 -or $Stat.ToleranceExceeded -ge $ToleranceExceeded -or $Stat.Week_Fluctuation -ge 1)) { 
                If ($Value -gt 0 -and $Stat.ToleranceExceeded -ge $ToleranceExceeded) { 
                    If ($Name -match ".+_Hashrate$") { 
                        Write-Message -Level Warn "Hashrate '$($Name -replace '_Hashrate$')' was forcefully updated. $(($Value | ConvertTo-Hash) -replace '\s+', ' ') was outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' '))$(If ($Stat.Week_Fluctuation -lt 1) { " for $($Stats.($Stat.Name).ToleranceExceeded) times in a row." })"
                    }
                    ElseIf ($Name -match ".+_PowerUsage$") { 
                        Write-Message -Level Warn "Power usage for '$($Name -replace '_PowerUsage$')' was forcefully updated. $($Value.ToString("N2"))W was outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W)$(If ($Stat.Week_Fluctuation -lt 1) { " for $($Stats.($Stat.Name).ToleranceExceeded) times in a row." })"
                    }
                }

                Remove-Stat -Name $Name | Out-Null
                $Stat = Set-Stat -Name $Name -Value $Value
            }
            Else { 
                $Span_Minute = [Math]::Min($Duration.TotalMinutes / [Math]::Min($Stat.Duration.TotalMinutes, 1), 1)
                $Span_Minute_5 = [Math]::Min(($Duration.TotalMinutes / 5) / [Math]::Min(($Stat.Duration.TotalMinutes / 5), 1), 1)
                $Span_Minute_10 = [Math]::Min(($Duration.TotalMinutes / 10) / [Math]::Min(($Stat.Duration.TotalMinutes / 10), 1), 1)
                $Span_Hour = [Math]::Min($Duration.TotalHours / [Math]::Min($Stat.Duration.TotalHours, 1), 1)
                $Span_Day = [Math]::Min($Duration.TotalDays / [Math]::Min($Stat.Duration.TotalDays, 1), 1)
                $Span_Week = [Math]::Min(($Duration.TotalDays / 7) / [Math]::Min(($Stat.Duration.TotalDays / 7), 1), 1)

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
                Disabled              = [Boolean]$false
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

    Return $Stat
}

Function Get-Stat { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name
    )

    If ($Global:Stats -isnot [Hashtable] -or -not $Global:Stats.IsSynchronized) { 
        $Global:Stats = [Hashtable]::Synchronized(@{ })
    }

    If (-not (Test-Path -Path "Stats" -PathType Container)) { 
        New-Item "Stats" -ItemType Directory -Force | Out-Null
    }

    If (-not $Name) { 
        [String[]]$Name = ((Get-ChildItem -Path "Stats" -File).BaseName | Sort-Object -Unique)
        ($Global:Stats.Keys | Select-Object | Where-Object { $_ -notin $Name }) | ForEach-Object { $Global:Stats.Remove($_) } # Remove stat if deleted on disk
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
                Remove-Stat $Stat_Name | Out-Null
            }
        }

        Return $Global:Stats.$Stat_Name
    }
}

Function Remove-Stat { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @($Global:Stats.Keys | Select-Object) + @((Get-ChildItem -Path "Stats" -Directory ).BaseName)
    )

    $Name | Sort-Object -Unique | ForEach-Object { 
        Remove-Item -Path "Stats\$_.txt" -Force -Confirm:$false -ErrorAction SilentlyContinue
        $Global:Stats.Remove($_)
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
        $TokenSeparator = ""
        $ValueSeparator = ""
        $Values = ""

        If ($Token -match "(?:^\s[-=]+)" <#supported prefix characters are listed in brackets [-=]#>) { 
            $Prefix = $Matches[0]
            $Token = $Token -split $Matches[0] | Select-Object -Last 1

            If ($Token -match "(?:[ =]+)" <#supported separators are listed in brackets [ =]#>) { 
                $TokenSeparator = $Matches[0]
                $Parameter = $Token -split $TokenSeparator | Select-Object -First 1
                $Values = $Token.Substring(("$Parameter$($TokenSeparator)").length)

                If ($Parameter -notin $ExcludeArguments -and $Values -match "(?:[,; ]{1})" <#supported separators are listed in brackets [,; ]#>) { 
                    $ValueSeparator = $Matches[0]
                    $RelevantValues = @()
                    $DeviceIDs | ForEach-Object { 
                        $RelevantValues += ($Values.Split($ValueSeparator) | Select-Object -Index $_)
                    }
                    $ArgumentsPerDevice += "$Prefix$Parameter$TokenSeparator$($RelevantValues -join $ValueSeparator)"
                }
                Else { $ArgumentsPerDevice += "$Prefix$Parameter$TokenSeparator$Values" }
            }
            Else { $ArgumentsPerDevice += "$Prefix$Token" }
        }
        Else { $ArgumentsPerDevice += $Token }
    }

    Return $ArgumentsPerDevice
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
        Return Start-ThreadJob -Name "Get-ChildItemContent_$($Path -replace '\.\\|\.\*' -replace '\\', '_')" -StreamingHost $null -ScriptBlock $ScriptBlock -ArgumentList $Path, $Parameters, $Priority
    }
    Else { 
        Return & $ScriptBlock -Path $Path -Parameters $Parameters
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
        $Client = [Net.Sockets.TcpClient]::new()
        $Client.SendTimeout = $Client.ReceiveTimeout = $Timeout * 1000
        $Client.Connect($Server, $Port)
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

    Return $Response
}

Function Get-CpuId { 

    # Brief : gets CPUID (CPU name and registers)

    # OS Features
    # $OS_x64 = "" # not implemented
    # $OS_AVX = "" # not implemented
    # $OS_AVX512 = "" # not implemented

    # Vendor
    $Vendor = "" # not implemented

    $Info = [CpuID]::Invoke(0)
    # Convert 16 bytes to 4 ints for compatibility with existing code
    $Info = [Int[]]@(
        [BitConverter]::ToInt32($Info, 0 * 4)
        [BitConverter]::ToInt32($Info, 1 * 4)
        [BitConverter]::ToInt32($Info, 2 * 4)
        [BitConverter]::ToInt32($Info, 3 * 4)
    )

    $nIds = $Info[0]

    $Info = [CpuID]::Invoke(0x80000000)
    $nExIds = [BitConverter]::ToUInt32($Info, 0 * 4) # Not sure as to why 'nExIds' is unsigned; may not be necessary
    # Convert 16 bytes to 4 ints for compatibility with existing code
    $Info = [Int[]]@(
        [BitConverter]::ToInt32($Info, 0 * 4)
        [BitConverter]::ToInt32($Info, 1 * 4)
        [BitConverter]::ToInt32($Info, 2 * 4)
        [BitConverter]::ToInt32($Info, 3 * 4)
    )

    # Detect Features
    $Features = @{ }
    If ($nIds -ge 0x00000001) { 

        $Info = [CpuID]::Invoke(0x00000001)
        # convert 16 bytes to 4 ints for compatibility with existing code
        $Info = [Int[]]@(
            [BitConverter]::ToInt32($Info, 0 * 4)
            [BitConverter]::ToInt32($Info, 1 * 4)
            [BitConverter]::ToInt32($Info, 2 * 4)
            [BitConverter]::ToInt32($Info, 3 * 4)
        )

        $Features.MMX = ($Info[3] -band ([Int]1 -shl 23)) -ne 0
        $Features.SSE = ($Info[3] -band ([Int]1 -shl 25)) -ne 0
        $Features.SSE2 = ($Info[3] -band ([Int]1 -shl 26)) -ne 0
        $Features.SSE3 = ($Info[2] -band ([Int]1 -shl 00)) -ne 0

        $Features.SSSE3 = ($Info[2] -band ([Int]1 -shl 09)) -ne 0
        $Features.SSE41 = ($Info[2] -band ([Int]1 -shl 19)) -ne 0
        $Features.SSE42 = ($Info[2] -band ([Int]1 -shl 20)) -ne 0
        $Features.AES = ($Info[2] -band ([Int]1 -shl 25)) -ne 0

        $Features.AVX = ($Info[2] -band ([Int]1 -shl 28)) -ne 0
        $Features.FMA3 = ($Info[2] -band ([Int]1 -shl 12)) -ne 0

        $Features.RDRAND = ($Info[2] -band ([Int]1 -shl 30)) -ne 0
    }

    If ($nIds -ge 0x00000007) { 

        $Info = [CpuID]::Invoke(0x00000007)
        # Convert 16 bytes to 4 ints for compatibility with existing code
        $Info = [Int[]]@(
            [BitConverter]::ToInt32($Info, 0 * 4)
            [BitConverter]::ToInt32($Info, 1 * 4)
            [BitConverter]::ToInt32($Info, 2 * 4)
            [BitConverter]::ToInt32($Info, 3 * 4)
        )

        $Features.AVX2 = ($Info[1] -band ([Int]1 -shl 05)) -ne 0

        $Features.BMI1 = ($Info[1] -band ([Int]1 -shl 03)) -ne 0
        $Features.BMI2 = ($Info[1] -band ([Int]1 -shl 08)) -ne 0
        $Features.ADX = ($Info[1] -band ([Int]1 -shl 19)) -ne 0
        $Features.MPX = ($Info[1] -band ([Int]1 -shl 14)) -ne 0
        $Features.SHA = ($Info[1] -band ([Int]1 -shl 29)) -ne 0
        $Features.RDSEED = ($Info[1] -band ([Int]1 -shl 18)) -ne 0
        $Features.PREFETCHWT1 = ($Info[2] -band ([Int]1 -shl 00)) -ne 0
        $Features.RDPID = ($Info[2] -band ([Int]1 -shl 22)) -ne 0

        $Features.AVX512_F = ($Info[1] -band ([Int]1 -shl 16)) -ne 0
        $Features.AVX512_CD = ($Info[1] -band ([Int]1 -shl 28)) -ne 0
        $Features.AVX512_PF = ($Info[1] -band ([Int]1 -shl 26)) -ne 0
        $Features.AVX512_ER = ($Info[1] -band ([Int]1 -shl 27)) -ne 0

        $Features.AVX512_VL = ($Info[1] -band ([Int]1 -shl 31)) -ne 0
        $Features.AVX512_BW = ($Info[1] -band ([Int]1 -shl 30)) -ne 0
        $Features.AVX512_DQ = ($Info[1] -band ([Int]1 -shl 17)) -ne 0

        $Features.AVX512_IFMA = ($Info[1] -band ([Int]1 -shl 21)) -ne 0
        $Features.AVX512_VBMI = ($Info[2] -band ([Int]1 -shl 01)) -ne 0

        $Features.AVX512_VPOPCNTDQ = ($Info[2] -band ([Int]1 -shl 14)) -ne 0
        $Features.AVX512_4FMAPS = ($Info[3] -band ([Int]1 -shl 02)) -ne 0
        $Features.AVX512_4VNNIW = ($Info[3] -band ([Int]1 -shl 03)) -ne 0

        $Features.AVX512_VNNI = ($Info[2] -band ([Int]1 -shl 11)) -ne 0

        $Features.AVX512_VBMI2 = ($Info[2] -band ([Int]1 -shl 06)) -ne 0
        $Features.GFNI = ($Info[2] -band ([Int]1 -shl 08)) -ne 0
        $Features.VAES = ($Info[2] -band ([Int]1 -shl 09)) -ne 0
        $Features.AVX512_VPCLMUL = ($Info[2] -band ([Int]1 -shl 10)) -ne 0
        $Features.AVX512_BITALG = ($Info[2] -band ([Int]1 -shl 12)) -ne 0
    }

    If ($nExIds -ge 0x80000001) { 

        $Info = [CpuID]::Invoke(0x80000001)
        # Convert 16 bytes to 4 ints for compatibility with existing code
        $Info = [Int[]]@(
            [BitConverter]::ToInt32($Info, 0 * 4)
            [BitConverter]::ToInt32($Info, 1 * 4)
            [BitConverter]::ToInt32($Info, 2 * 4)
            [BitConverter]::ToInt32($Info, 3 * 4)
        )

        $Features.x64 = ($Info[3] -band ([Int]1 -shl 29)) -ne 0
        $Features.ABM = ($Info[2] -band ([Int]1 -shl 05)) -ne 0
        $Features.SSE4a = ($Info[2] -band ([Int]1 -shl 06)) -ne 0
        $Features.FMA4 = ($Info[2] -band ([Int]1 -shl 16)) -ne 0
        $Features.XOP = ($Info[2] -band ([Int]1 -shl 11)) -ne 0
        $Features.PREFETCHW = ($Info[2] -band ([Int]1 -shl 08)) -ne 0
    }

    # Wrap data into PSObject
    Return [PSCustomObject]@{ 
        Vendor   = $Vendor
        Name     = $name
        Features = $Features.Keys.ForEach{ If ($Features.$_) { $_ } }
    }
}

Function Get-GPUArchitectureAMD { 

    [CmdLetBinding()]
    param(
        [string]$Model,
        [string]$Architecture = ""
    )

    $Model = $Model -replace "[^A-Z0-9]"
    $Architecture = $Architecture -replace ":.+$" -replace "[^A-Za-z0-9]+"

    Try { 
        $GPUArchitectureDB_AMD = Get-Content "Data\GPUArchitectureAMD.json" | ConvertFrom-Json -ErrorAction Ignore

        ForEach($GPUArchitecture in $GPUArchitectureDB_AMD.PSObject.Properties) { 
            $Arch_Match = $GPUArchitecture.Value -join "|"
            If ($Architecture -match $Arch_Match) { 
                Return $GPUArchitecture.Name
            }
        }
        ForEach($GPUArchitecture in $GPUArchitectureDB_AMD.PSObject.Properties) { 
            $Arch_Match = $GPUArchitecture.Value -join "|"
            If ($Model -match $Arch_Match) { 
                Return $GPUArchitecture.Name
            }
        }
    } 
    Catch { 
        If ($Error.Count) { $Error.RemoveAt(0) }
        Write-Message -Level Warn "Cannot determine architecture for AMD $($Model)/$($Architecture)"
    }

    Return Architecture
}

Function Get-GPUArchitectureNvidia { 

    [CmdLetBinding()]
    param(
        [string]$Model,
        [string]$ComputeCapability = ""
    )

    $Model = $Model -replace "[^A-Z0-9]"
    $ComputeCapability = $ComputeCapability -replace "[^\d\.]"

    Try { 
        $GPUArchitectureDB_Nvidia = Get-Content "Data\GPUArchitectureNvidia.json" | ConvertFrom-Json -ErrorAction Ignore

        ForEach ($GPUArchitecture in $GPUArchitectureDB_Nvidia.PSObject.Properties) { 
            If ($ComputeCapability -in $GPUArchitecture.Value.Compute) { 
                Return $GPUArchitecture.Name
            }
        }
        Remove-Variable GPUArchitecture

        ForEach ($GPUArchitecture in $GPUArchitectureDB_Nvidia.PSObject.Properties) { 
            $Model_Match = $GPUArchitecture.Value.Model -join "|"
            If ($Model -match $Model_Match) {
                Return $GPUArchitecture.Name
            }
        }
        Remove-Variable GPUArchitecture
    } 
    Catch { 
        If ($Error.Count) { $Error.RemoveAt(0) }
        Write-Message -Level Warn "Cannot determine architecture for Nvidia $($Model)/$($ComputeCapability)"
    }

    Return "Other"
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

    If (-not $Variables.Devices -or $Refresh) { 
        $Variables.Devices = @()

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
                            Default { $Device_CIM.Manufacturer -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel' -replace '[^A-Z0-9]' -replace '\s+', ' ' }
                        }
                    )
                    Memory = $null
                    MemoryGiB = $null
                }

                $Device | Add-Member @{ 
                    Id             = [Int]$Id
                    Type_Id        = [Int]$Type_Id.($Device.Type)
                    Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                    Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                }

                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor) -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel' -replace '[^ A-Z0-9\.]' -replace '\s+', ' ').Trim()

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
                            Default { $Device_CIM.AdapterCompatibility -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel' -replace '[^A-Z0-9]' -replace '\s+', ' ' }
                        }
                    )
                    Memory = [Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize'))
                    MemoryGiB = [Double]([Math]::Round([Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize')) / 0.05GB) / 20) # Round to nearest 50MB
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
                $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB" -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel' -replace '[^ A-Z0-9\.]' -replace '\s+', ' ').Trim()

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
                                Default { [String]$Device_OpenCL.Type -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel' -replace '[^A-Z0-9]' -replace '\s+', ' ' }
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
                                Default { [String]$Device_OpenCL.Vendor -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel' -replace '[^A-Z0-9]' -replace '\s+', ' ' }
                            }
                        )
                        Memory = [UInt64]$Device_OpenCL.GlobalMemSize
                        MemoryGiB = [Double]([Math]::Round($Device_OpenCL.GlobalMemSize / 0.05GB) / 20) # Round to nearest 50MB
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
                    $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel' -replace '[^A-Z0-9 ]' -replace '\s+', ' '

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
                        $_ | Add-Member "Architecture" (Get-GPUArchitectureNvidia -Model $_.Model -ComputeCapability $_.OpenCL.DeviceCapability)
                    } 
                    ElseIf ($_.Vendor -eq "AMD") {
                        $_ | Add-Member "Architecture" (Get-GPUArchitectureAMD -Model $_.Model -Architecture $_.OpenCL.Architecture)
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
        $Device = $_

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

Function Get-DecimalsFromValue { 

    # Used to limit absolute length of number
    # The larger the value, the less decimal digits are returned
    # Maximal $DecimalsMax decimals are returned

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $true)]
        [Int]$DecimalsMax
    )

    $Decimals = 1 + $DecimalsMax - [math]::Floor([math]::Abs($Value)).ToString().Length
    If ($Decimals -gt $DecimalsMax) { $Decimals = 0 }

    Return $Decimals
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

    For ($I = 0; $I -lt $Value.Count; $I++) { 
        $Combination | Add-Member @{ [Math]::Pow(2, $I) = $Value[$I] }
    }

    $Combination_Keys = ($Combination | Get-Member -MemberType NoteProperty).Name

    For ($I = $SizeMin; $I -le $SizeMax; $I++) { 
        $X = [Math]::Pow(2, $I) - 1

        While ($X -le [Math]::Pow(2, $Value.Count) - 1) { 
            [PSCustomObject]@{ Combination = $Combination_Keys | Where-Object { $_ -band $X } | ForEach-Object { $Combination.$_ } }
            $Smallest = ($X -band - $X)
            $Ripple = $X + $Smallest
            $New_Smallest = ($Ripple -band - $Ripple)
            $Ones = (($New_Smallest / $Smallest) -shr 1) - 1
            $X = $Ripple -bor $Ones
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
        [String]$WindowTitle, 
        [Parameter(Mandatory = $false)]
        [String]$JobName, 
        [Parameter(Mandatory = $false)]
        [String]$LogFile
    )

    $Job = Start-ThreadJob -Name $JobName -StreamingHost $Null -ArgumentList $BinaryPath, $ArgumentList, $WorkingDirectory, $WindowTitle, $EnvBlock, $CreationFlags, $MinerWindowStyle, $StartF, $PID { 
    # $Job = Start-Job -Name $JobName -ArgumentList $BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $MinerWindowStyle, $StartF, $PID { 
        Param($BinaryPath, $ArgumentList, $WorkingDirectory, $WindowTitle, $EnvBlock, $CreationFlags, $MinerWindowStyle, $StartF, $ControllerProcessID)

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
    public uint cb; public string lpReserved; public string lpDesktop; [MarshalAs(UnmanagedType.LPWStr)] public string lpTitle;
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
        # $StartupInfo.lpTitle = [System.Runtime.InteropServices.Marshal]::StringToBSTR($WindowTitle)
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
            Return [PSCustomObject]@{ ProcessId = $null }
        }

        [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle }

        Do { 
            If ($ControllerProcess.WaitForExit(1000)) { 
                $null = $Process.CloseMainWindow()
                [System.GC]::GetTotalMemory("forcefullcollection") | Out-Null
            }
        } While (-not $Process.HasExited)
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

    Return Start-ThreadJob -StreaminHost $Null ([ScriptBlock]::Create($ScriptBlock))
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
    Invoke-WebRequest -Uri $Uri -OutFile $FileName -TimeoutSec 5

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
        $Global:Algorithms = Get-Content ".\Data\Algorithms.json" | ConvertFrom-Json -ErrorAction Stop
    }

    $Algorithm = $Algorithm -replace "[^a-z0-9]+"

    If ($Global:Algorithms.$Algorithm) { Return $Global:Algorithms.$Algorithm }
    Else { Return (Get-Culture).TextInfo.ToTitleCase($Algorithm.ToLower()) }
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

    If ($List) { Return $Global:Regions.$Region }
    ElseIf ($Global:Regions.$Region) { Return $($Global:Regions.$Region | Select-Object -First 1) }
    Else { Return $Region }
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
                $Global:CurrencyAlgorithm = Get-Content -Path ".\Data\CurrencyAlgorithm.json" | ConvertFrom-Json -AsHashtable | Get-SortedObject
                $Global:CurrencyAlgorithm | Add-Member $Currency $Algorithm -Force
                $Global:CurrencyAlgorithm | ConvertTo-Json | Out-File -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction SilentlyContinue -Encoding utf8NoBOM -Force
            }
            If (-not $Global:CoinNames.$Currency) { 
                $Global:CoinNames = Get-Content -Path ".\Data\CoinNames.json" | ConvertFrom-Json -AsHashtable | Get-SortedObject
                $Global:CoinNames | Add-Member $Currency ((Get-Culture).TextInfo.ToTitleCase($CoinName.Trim().ToLower()) -replace '[^A-Z0-9\$\.]' -replace 'coin$', 'Coin' -replace 'bitcoin$', 'Bitcoin') -Force
                $Global:CoinNames | ConvertTo-Json | Out-File -Path ".\Data\CoinNames.json" -ErrorAction SilentlyContinue -Encoding utf8NoBOM -Force
            }
            [Void]$Mutex.ReleaseMutex()
        }
    }
}

Function Get-CoinName { 

    Param(
        [Parameter(Mandatory = $false)]
        [String]$Currency
    )

    If ($Currency) { 
        If ($Global:CoinNames.$Currency) { 
            Return $Global:CoinNames.$Currency
        }

        $Global:CoinNames = Get-Content -Path ".\Data\CoinNames.json" | ConvertFrom-Json
        If ($Global:CoinNames.$Currency) { 
            Return $Global:CoinNames.$Currency
        }
    }
    Return $null
}

Function Get-EquihashCoinPers {

    Param(
        [Parameter(Mandatory = $false)]
        [String]$Command = "",
        [Parameter(Mandatory = $false)]
        [String]$Currency = "",
        [Parameter(Mandatory = $false)]
        [String]$DefaultCommand = ""
    )

    If ($Currency) { 
        If ($Global:EquihashCoinPers.$Currency) { 
            Return "$($Command)$($Global:EquihashCoinPers.$Currency)"
        }

        $Global:EquihashCoinPers = Get-Content -Path ".\Data\EquihashCoinPers.json" | ConvertFrom-Json
        If ($Global:EquihashCoinPers.$Currency) { 
            Return "$($Command)$($Global:EquihashCoinPers.$Currency)"
        }
    }
    Return $DefaultCommand
}

Function Get-AlgorithmFromCurrency { 

    Param(
        [Parameter(Mandatory = $false)]
        [String]$Currency
    )

    If ($Currency) { 
        If ($Global:CurrencyAlgorithm.$Currency) { 
            Return $Global:CurrencyAlgorithm.$Currency
        }

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

    Return ($PoolNames -replace "24hr$|Coins$|Plus$")
}

Function Get-NMVersion { 

    # Updater always logs all messages to screen
    $Config.LogToScreen = @("Info", "Warn", "Error", "Verbose", "Debug")

    # GitHub only supports TLSv1.2 since feb 22 2018
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

    Try { 
        $UpdateVersion = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Minerx117/NemosMiner/master/Version.txt" -TimeoutSec 15 -SkipCertificateCheck -Headers @{ "Cache-Control" = "no-cache" }).Content | ConvertFrom-Json

        $Variables.CheckedForUpdate = Get-Date

        If ($UpdateVersion.Product -eq $Variables.Branding.ProductLabel -and [Version]$UpdateVersion.Version -gt $Variables.Branding.Version) { 
            If ($UpdateVersion.AutoUpdate) { 
                If ($Config.AutoUpdate) { 
                    Write-Message -Level Verbose "Version checker: New Version $($UpdateVersion.Version) found. Starting update..."
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

Function Copy-Object { 
    Param(
        [Parameter(Mandatory = $true)]
        [Object]$Object
    )

    $Copy = @()
    $Object.ForEach({
        $CurrentObject = $_
        $CurrentObjectCopy = New-Object $CurrentObject.GetType().Name
        $CurrentObjectCopy.PSObject.Properties.ForEach({
            $_.Value = $CurrentObject.PSObject.Properties[($_.Name)].Value
        })
        $Copy += $CurrentObjectCopy
    })

    Return $Copy
}

Function Initialize-Autoupdate { 

    Param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UpdateVersion
    )

    # GitHub only supports TLSv1.2 since feb 22 2018
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

    Set-Location $Variables.MainPath
    If (-not (Test-Path -Path ".\AutoUpdate" -PathType Container)) { New-Item -Path . -Name "AutoUpdate" -ItemType Directory | Out-Null }
    If (-not (Test-Path -Path ".\Logs" -PathType Container)) { New-Item -Path . -Name "Logs" -ItemType Directory | Out-Null }

    $UpdateScriptURL = "https://github.com/Minerx117/miners/releases/download/AutoUpdate/Autoupdate.ps1"
    $UpdateScript = ".\AutoUpdate\AutoUpdate.ps1"
    $UpdateLog = ".\Logs\AutoUpdateLog_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt"
    $BackupFile = ".\AutoUpdate\Backup_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").zip"

    # Download update script
    "Downloading update script..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose 
    Try { 
        Invoke-WebRequest -Uri $UpdateScriptURL -OutFile $UpdateScript -TimeoutSec 15
        "Executing update script..." | Tee-Object $UpdateLog -Append | Write-Message -Level Verbose 
        . $UpdateScript
    }
    Catch { 
        "Downloading update script failed. Cannot complete auto-update :-(" | Tee-Object $UpdateLog -Append | Write-Message -Level Error
    }
}

Function Start-LogReader { 

    If ((Test-Path -Path $Config.LogViewerExe -PathType Leaf) -and (Test-Path -Path $Config.LogViewerConfig -PathType Leaf)) { 
        $Variables.LogViewerConfig = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.LogViewerConfig)
        $Variables.LogViewerExe = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.LogViewerExe)
        If ($SnaketailProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -EQ "$($Variables.LogViewerExe) $($Variables.LogViewerConfig)")) { 
            # Activate existing Snaketail window
            $LogViewerMainWindowHandle = (Get-Process -Id $SnaketailProcess.ProcessId).MainWindowHandle
            If (@($LogViewerMainWindowHandle).Count -eq 1) { 
                Try { 
                    [Win32]::ShowWindowAsync($LogViewerMainWindowHandle, 6) | Out-Null # SW_MINIMIZE 
                    [Win32]::ShowWindowAsync($LogViewerMainWindowHandle, 9) | Out-Null # SW_RESTORE
                }
                Catch {}
            }
        }
        Else { 
            [Void](Invoke-CreateProcess -BinaryPath $Variables.LogViewerExe -ArgumentList $Variables.LogViewerConfig -WorkingDirectory (Split-Path $Variables.LogViewerExe) -MinerWindowStyle "Normal" -Priority "-2" -EnvBlock $null -LogFile $null -JobName "Snaketail")
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
                If ($Config.$_) { 
                    If ($Config.StartPaused) { $Config.StartupMode = "Paused" }
                    Else { $Config.StartupMode = "Running" }
                }
                Else { $Config.StartupMode = "Idle" }
                $Config.Remove($_)
                $Config.Remove("StartPaused")
            }
            "AllowedBadShareRatio" { $Config.BadShareRatioThreshold = $Config.$_; $Config.Remove($_) }
            "APIKEY" { $Config.MiningPoolHubAPIKey = $Config.$_; $Config.Remove($_) }
            "BalancesTrackerConfigFile" { $Config.Remove($_) }
            "BalancesTrackerIgnorePool"  { $Config.BalancesTrackerExcludePool = $Config.$_; $Config.Remove($_) }
            "DeductRejectedShares" { $Config.SubtractBadShares = $Config.$_; $Config.Remove($_) }
            "Donate" { $Config.Donation = $Config.$_; $Config.Remove($_) }
            "EnableEarningsTrackerLog" { $Config.EnableBalancesLog = $Config.$_; $Config.Remove($_) }
            "EstimateCorrection" { $Config.Remove($_) }
            "EthashLowMemMinMemGiB" { $Config.Remove($_) }
            "Location" { $Config.Region = $Config.$_; $Config.Remove($_) }
            "IdlePowerUsageW" { $Config.PowerUsageIdleSystemW = $Config.$_; $Config.Remove($_) }
            "MineWhenIdle" { $Config.IdleDetection = $Config.$_; $Config.Remove($_) }
            "MinInterval" { $Config.MinCycle = $Config.$_; $Config.Remove($_) }
            "MinDataSamples" { $Config.MinDataSample = $Config.$_; $Config.Remove($_) }
            "MinDataSamplesAlgoMultiplier" { $Config.MinDataSampleAlgoMultiplier = $Config.$_; $Config.Remove($_) }
            "MPHAPIKey" { $Config.MiningPoolHubAPIKey = $Config.$_; $Config.Remove($_) }
            "MPHUserName"  { $Config.MiningPoolHubUserName = $Config.$_; $Config.Remove($_) }
            "NoDualAlgoMining" { $Config.DisableDualAlgoMining = $Config.$_; $Config.Remove($_) }
            "NoSingleAlgoMining" { $Config.DisableSingleAlgoMining = $Config.$_; $Config.Remove($_) }
            "PasswordCurrency" { $Config.PayoutCurrency = $Config.$_; $Config.Remove($_) }
            "PoolBalancesUpdateInterval" { 
                If ($Config.$_) { $Config.PoolBalancesUpdateInterval = $Config.$_ }
                $Config.Remove($_)
            }
            "PoolsConfigFile" { 
                $Config.PoolsConfig = Get-Content $Config.$_ | ConvertFrom-Json -AsHashtable -ErrorAction Ignore | Select-Object
                $Config.Remove($_)
            }
            "PricePenaltyFactor" { $Config.EarningsAdjustmentFactor = $Config.$_; $Config.Remove($_) }
            "ReadPowerUsage" { $Config.CalculatePowerCost = $Config.$_; $Config.Remove($_) }
            "RunningMinerGainPct" { $Config.MinerSwitchingThreshold = $Config.$_; $Config.Remove($_) }
            "ShowMinerWindows" { $Config.MinerWindowStyle = $Config.$_; $Config.Remove($_) }
            "ShowMinerWindowsNormalWhenBenchmarking" { $Config.MinerWindowStyleNormalWhenBenchmarking = $Config.$_; $Config.Remove($_) }
            "SnakeTailConfig" { $Config.LogViewerConfig = $Config.$_; $Config.Remove($_) }
            "SnakeTailExe" { $Config.LogViewerExe = $Config.$_; $Config.Remove($_) }
            "StartGUIMinimized" { $Config.LegacyGUI = $Config.$_; $Config.Remove($_) }
            "StartGUI" { $Config.LegacyGUIStartMinimized = $Config.$_; $Config.Remove($_) }
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
            "WebGUIUseColor" { $Config.UseColorForMinerStatus = $Config.$_; $Config.Remove($_) }
            Default { If ($_ -notin @(@($Variables.AllCommandLineParameters.Keys) + @("CryptoCompareAPIKeyParam") + @("DryRun") + @("PoolsConfig") + @("UsePoolJobs"))) { $Config.Remove($_) } } # Remove unsupported config items
        }
    }

    # Change currency names, remove mBTC
    If ($Config.Currency -is [Array]) { 
        $Config.Currency = $Config.Currency | Select-Object -First 1
        $Config.ExtraCurrencies = @($Config.Currency | Select-Object -Skip 1 | Where-Object { $_ -ne "mBTC" } | Select-Object)
    }

    # Move [PayoutCurrency] wallet to wallets
    If ($PoolsConfig = Get-Content $Variables.PoolsConfigFile | ConvertFrom-Json) { 
        ($PoolsConfig | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
            If (-not $PoolsConfig.$_.Wallets -and $PoolsConfig.$_.Wallet) { 
                $PoolsConfig.$_ | Add-Member Wallets @{ "$($PoolsConfig.$_.PayoutCurrency)" = $PoolsConfig.$_.Wallet }
                $PoolsConfig.$_.PSObject.Members.Remove("Wallet")
            }
        }
    }

    # Rename MPH to MiningPoolHub
    $Config.PoolName = $Config.PoolName -replace "MPH", "MiningPoolHub"
    $Config.PoolName = $Config.PoolName -replace "MPHCoins", "MiningPoolHubCoins"

    # *Coins pool no longer exists
    $OldPoolName = $Config.PoolName
    $Config.PoolName = $Config.PoolName -replace 'Coins$', '' -replace 'CoinsPlus$', 'Plus'
    If (Compare-Object @($OldPoolName | Select-Object) @($Config.PoolName | Select-Object)) { 
        Write-Message -Level Info "Pool configuration has changed ($($OldPoolName -join ', ') -> $($Config.PoolName -join ', ')). Please verify your configuration."
    }
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
            "Russia"       { "Europe" }
            "US"           { "USA West" }
            Default        { "Europe" }
        }
        Write-Message -Level Warn "Available mining locations have changed ($OldRegion -> $($Config.Region)). Please verify your configuration."
    }
    # Extend MinDataSampleAlgoMultiplier
    If ($Config.MinDataSampleAlgoMultiplier.DynexSolve -eq $null) { $Config.MinDataSampleAlgoMultiplier | Add-Member "DynexSolve" 3 }
    If ($Config.MinDataSampleAlgoMultiplier.Ghostrider -eq $null) { $Config.MinDataSampleAlgoMultiplier | Add-Member "GhostRider" 3 }
    If ($Config.MinDataSampleAlgoMultiplier.Mike -eq $null) { $Config.MinDataSampleAlgoMultiplier | Add-Member "Mike" 3 }
    # Remove AHashPool config data
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "AhashPool*" }
    Remove-Item ".\Stats\AhashPool*.txt" -Force
    # Remove BlockMasters config data
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "BlockMasters*" }
    Remove-Item ".\Stats\BlockMasters*.txt" -Force
    # Remove BlockMasters config data
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "NLPool*" }
    Remove-Item ".\Stats\NLPool*.txt" -Force
    # Remove TonPool config
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "TonPool" }
    # Remove TonWhales config
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "TonWhales" }

    $Config.ConfigFileVersion = $Variables.Branding.Version.ToString()
    Write-Config -ConfigFile $ConfigFile -Config $Config
    Write-Message -Level Verbose "Updated configuration file '$($ConfigFile)' to version $($Variables.Branding.Version.ToString())."
}

Function Get-ObsoleteMinerStats { 

    Get-Stat | Out-Null

    $MinerNames = @(Get-ChildItem ".\Miners\*.ps1").BaseName

    Return @($Global:Stats.Keys | Where-Object { $_ -match "_Hashrate$|_PowerUsage$" } | Where-Object { (($_ -split "-" | Select-Object -First 2) -join "-") -notin $MinerNames})
}

Function Test-Prime { 

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Number
    )

    For ([Int64]$i = 2; $i -lt [Int64][Math]::Pow($Number, 0.5); $i++) { If ($Number % $i -eq 0) { Return $false } }

    Return $true
}

Function Update-DAGData { 
    # Update once every 24hrs or if unable to get data from all sources
    If (-not $Variables.DAGdata) { $Variables.DAGdata = [PSCustomObject][Ordered]@{ } }
    If (-not $Variables.DAGdata.Algorithm) { $Variables.DAGdata | Add-Member Algorithm ([Ordered]@{ }) -Force }
    If (-not $Variables.DAGdata.Currency) { $Variables.DAGdata | Add-Member Currency ([Ordered]@{ }) -Force }
    If (-not $Variables.DAGdata.Updated) { $Variables.DAGdata | Add-Member Updated ([Ordered]@{ }) -Force }

    $Url = "https://whattomine.com/coins.json"
    If ($Variables.DAGdata.Updated.$Url -lt (Get-Date).ToUniversalTime().AddDays(-1)) { 
        # Get block data for from whattomine.com
        Try { 
            $DAGDataResponse = Invoke-RestMethod -Uri $Url

            If ($DAGDataResponse.coins.PSObject.Properties.Name) { 
                $DAGDataResponse.coins.PSObject.Properties.Name | Where-Object { $DAGDataResponse.coins.$_.tag -ne "NICEHASH" } | ForEach-Object { 
                    $Currency = $DAGDataResponse.coins.$_.tag
                    If (-not (Get-CoinName -Currency $Currency)) { Add-CoinName -Algorithm (Get-Algorithm $DAGDataResponse.coins.$_.algorithm) -Currency $Currency -CoinName $_ }
                    If ((Get-Algorithm $DAGDataResponse.coins.$_.algorithm) -in @("Autolykos2", "EtcHash", "Ethash", "FiroPow", "KawPow", "Octopus", "ProgPow", "ProgPowZano", "UbqHash")) { 
                        If ($DAGDataResponse.coins.$_.last_block -ge $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                            $DAGData = Get-DAGdata -BlockHeight $DAGDataResponse.coins.$_.last_block -Currency $Currency -EpochReserve 2
                            If ($DAGData.Algorithm) { 
                                $Variables.DAGdata.Currency.$Currency = $DAGData
                                $Variables.DAGdata.Updated.$Url = (Get-Date).ToUniversalTime()
                            }
                        }
                    }
                }
                Write-Message -Level Info "Loaded DAG data from '$Url'."
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
        }
    }

    $Url = "https://minerstat.com/dag-size-calculator"
    If ($Variables.DAGdata.Updated.$Url -lt (Get-Date).ToUniversalTime().AddDays(-1)) { 
        # Get block data from Minerstat
        Try { 
            $DAGDataResponse = Invoke-WebRequest -Uri $Url -TimeoutSec 5 # PWSH 6+ no longer supports basic parsing -> parse text
            If ($DAGDataResponse.statuscode -eq 200) {
                $DAGDataResponse.Content -split '\n' -replace '"', "'" | Where-Object { $_ -like "<div class='block' title='Current block height of *" } | ForEach-Object { 

                    $Currency = $_ -replace "^<div class='block' title='Current block height of " -replace "'>.*$"
                    $BlockHeight = [Int]($_ -replace "^<div class='block' title='Current block height of $Currency'>" -replace "</div>")

                    If ($BlockHeight -and $Currency) { 
                        $DAGData = Get-DAGdata -BlockHeight $BlockHeight -Currency $Currency -EpochReserve 2
                        If ($DAGData.Algorithm) { 
                            $Variables.DAGdata.Currency.$Currency = $DAGData
                            $Variables.DAGdata.Updated.$Url = (Get-Date).ToUniversalTime()
                        }
                    }
                }
                Write-Message -Level Info "Loaded DAG data from '$Url'."
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
        }
    }

    $Url = "https://prohashing.com/api/v1/currencies"
    If ($Variables.DAGdata.Updated.$Url -lt (Get-Date).ToUniversalTime().AddDays(-1)) { 
        # Get block data from ProHashing
        Try { 
            $DAGDataResponse = Invoke-RestMethod -Uri $Url

            If ($DAGDataResponse.code -eq 200) { 
                $DAGDataResponse.data.PSObject.Properties.Name | Where-Object { $DAGDataResponse.data.$_.enabled -and $DAGDataResponse.data.$_.height -and ((Get-Algorithm $DAGDataResponse.data.$_.algo) -in @("Autolykos2", "EtcHash", "Ethash", "KawPow", "Octopus", "UbqHash") -or $_ -in @($Variables.DAGdata.Currency.Keys))} | ForEach-Object { 
                    If ($DAGDataResponse.data.$_.height -gt 0 -and $DAGDataResponse.data.$_.height -gt $Variables.DAGdata.Currency.$_.BlockHeight) { 
                        $DAGData = Get-DAGdata -BlockHeight $DAGDataResponse.data.$_.height -Currency $_ -EpochReserve 2
                        If ($DAGData.Algorithm) { 
                            $Variables.DAGdata.Currency.$_ = $DAGData
                            $Variables.DAGdata.Updated.$Url = (Get-Date).ToUniversalTime()
                        }
                    }
                }
                $Variables.EthashLowMemCurrency = $DAGDataResponse.data.PSObject.Properties.Name | Where-Object { $DAGDataResponse.data.$_.enabled -and $DAGDataResponse.data.$_.height -and $DAGDataResponse.data.$_.algo -eq "ethash" } | Sort-Object { $DAGDataResponse.data.$_.height } | Select-Object -First 1
                Write-Message -Level Info "Loaded DAG data from '$Url'."
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
        }
    }

    $Url = "https://evr.cryptoscope.io/api/getblockcount"
    If ($Variables.DAGdata.Updated.$Url -lt (Get-Date).ToUniversalTime().AddDays(-1)) { 
        # Get block data from EVR block explorer
        Try { 
            $DAGDataResponse = Invoke-RestMethod -Uri $Url

            If ($DAGDataResponse.blockcount -gt 0) { 
                $Variables.DAGdata.Currency."EVR" = (Get-DAGdata -BlockHeight $DAGDataResponse.blockcount -Currency "EVR" -EpochReserve 2)
                $Variables.DAGdata.Updated.$Url = (Get-Date).ToUniversalTime()
                Write-Message -Level Info "Loaded DAG data from '$Url'."
            }
            Else { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
        Catch { 
            Write-Message -Level Warn "Failed to load DAG data from '$Url'."
        }
    }

    If ($Variables.DAGdata.Updated.Values -gt $Variables.Timer) { 
        #At least one DAG was updated, get maximum DAG size per algorithm

        If ($Variables.DAGdata.Currency.FIRO) { # SCC firo variant
            $Variables.DAGdata.Currency.SCC = $Variables.DAGdata.Currency.FIRO.Clone()
            $Variables.DAGdata.Currency.SCC.Algorithm = "FiroPowSSC"
            $Variables.DAGdata.Currency.SCC.CoinName = "StakeCubeCoin"
        }

        $DagDataKeys = @($Variables.DAGdata.Currency.Keys) # Store as array to avoid error 'An error occurred while enumerating through a collection: Collection was modified; enumeration operation may not execute..'

        ForEach ($Algorithm in @($DagDataKeys | ForEach-Object { $Variables.DAGdata.Currency.$_.Algorithm } | Select-Object)) { 
            $Variables.DAGdata.Algorithm.$Algorithm = @{ 
                BlockHeight = [Int]($DagDataKeys | Where-Object { (Get-AlgorithmFromCurrency $_) -eq $Algorithm } | ForEach-Object { $Variables.DAGdata.Currency.$_.BlockHeight } | Measure-Object -Maximum).Maximum
                DAGsize     = [Int64]($DagDataKeys | Where-Object { (Get-AlgorithmFromCurrency $_) -eq $Algorithm } | ForEach-Object { $Variables.DAGdata.Currency.$_.DAGsize } | Measure-Object -Maximum).Maximum
                Epoch       = [Int]($DagDataKeys | Where-Object { (Get-AlgorithmFromCurrency $_) -eq $Algorithm } | ForEach-Object { $Variables.DAGdata.Currency.$_.Epoch } | Measure-Object -Maximum).Maximum
            }

            $Variables.DAGdata.Algorithm.$Algorithm | Add-Member CoinName ($DagDataKeys | Where-Object { $Variables.DAGdata.Currency.$_.DAGsize -eq $Variables.DAGdata.Algorithm.$Algorithm.DAGsize -and $Variables.DAGdata.Currency.$_.Algorithm -eq $Algorithm }) -Force

            If ($Variables.EthashLowMemCurrency) { 
                $Variables.DAGdata.Algorithm.EthashLowMem = @{ 
                    BlockHeight = [Int]($Variables.DAGdata.Currency.($Variables.EthashLowMemCurrency).BlockHeight)
                    CoinName    = $Variables.DAGdata.Currency.($Variables.EthashLowMemCurrency).CoinName
                    DAGsize     = [Int64]($Variables.DAGdata.Currency.($Variables.EthashLowMemCurrency).DAGsize)
                    Epoch       = [Int]($Variables.DAGdata.Currency.($Variables.EthashLowMemCurrency).Epoch)
                }
            }
        }
        Remove-Variable Algorithm

        # Add default '*' (equal to highest)
        $Variables.DAGdata.Currency."*" = @{ 
            BlockHeight = [Int]($DagDataKeys | ForEach-Object { $Variables.DAGdata.Currency.$_.BlockHeight } | Measure-Object -Maximum).Maximum
            CoinName    = "*"
            DAGsize     = [Int64]($DagDataKeys | ForEach-Object { $Variables.DAGdata.Currency.$_.DAGsize } | Measure-Object -Maximum).Maximum
            Epoch       = [Int]($DagDataKeys | ForEach-Object { $Variables.DAGdata.Currency.$_.Epoch } | Measure-Object -Maximum).Maximum
        }

        $Variables.DAGdata | Get-SortedObject | ConvertTo-Json | Out-File -FilePath ".\Data\DagData.json" -Force -Encoding utf8NoBOM
    }
}

Function Get-DAGsize { 

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Epoch,
        [Parameter(Mandatory = $true)]
        [String]$Currency
    )

    Switch ($Currency) { 
        "CFX" { 
            $Dataset_Bytes_Init = 4294967296
            $Dataset_Bytes_Growth = 16777216
            $Mix_Bytes = 256
            $Size = ($Dataset_Bytes_Init + $Dataset_Bytes_Growth * $Epoch) - $Mix_Bytes
            While (-not (Test-Prime ($Size / $Mix_Bytes))) { 
                $Size -= 2 * $Mix_Bytes
            }
        }
        "ERG" { 
            # https://github.com/RainbowMiner/RainbowMiner/issues/2102
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
        "EVR" { 
            $Dataset_Bytes_Init = 3 * [Math]::Pow(2, 30) # 3GB
            $Dataset_Bytes_Growth = [Math]::Pow(2, 23) # 8MB
            $Mix_Bytes = 128
            $Size = ($Dataset_Bytes_Init + $Dataset_Bytes_Growth * $Epoch) - $Mix_Bytes
            While (-not (Test-Prime ($Size / $Mix_Bytes))) { 
                $Size -= 2 * $Mix_Bytes
            }
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
        "CFX"   { Return 524288 }
        "ERG"   { Return 1024 }
        "ETC"   { If ($Blockheight -ge 11700000 ) { Return 60000 } Else { Return 30000 } }
        "EVR"   { Return 12000 }
        "FIRO"  { Return 1300 }
        "RVN"   { Return 7500 }
        Default { return 30000 }
    }

}

Function Get-DAGdata { 

    Param(
        [Parameter(Mandatory = $false)]
        [Double]$Blockheight = ((Get-Date) - [DateTime]"07/31/2015").Days * 6400,
        [Parameter(Mandatory = $false)]
        [String]$Currency = "ETH",
        [Parameter(Mandatory = $false)]
        [Int16]$EpochReserve = 0
    )

    $Epoch = (Get-Epoch -BlockHeight $BlockHeight -Currency $Currency) + $EpochReserve

    Return @{ 
        Algorithm   = Get-AlgorithmFromCurrency $Currency
        BlockHeight = [Int]$BlockHeight
        CoinName    = Get-CoinName $Currency
        DAGsize     = Get-DAGSize -Epoch $Epoch -Currency $Currency
        Epoch       = $Epoch
    }
}

Function Out-DataTable { 

    # based on http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx

    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true )]
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
            Remove-Variable Property
            $DataTable.Rows.Add($DataRow)
            $First = $false
        }
        Remove-Variable Object
    }
    End { 
        Return @(,($DataTable))
    }
}

Function Get-Median { 

    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Double[]]$Number
    )

    $NumberSeries += @()
    $NumberSeries += $Number
    $SortedNumbers = @($NumberSeries | Sort-Object)
    If ($NumberSeries.Count % 2) { 
        Return $SortedNumbers[($SortedNumbers.Count / 2) - 1]
    }
    Else { 
        Return ($SortedNumbers[($SortedNumbers.Count / 2)] + $SortedNumbers[($SortedNumbers.Count / 2) - 1]) / 2
    }
}

Function Get-MemoryUsage {

    $MemUsageByte = [System.GC]::GetTotalMemory("forcefullcollection")
    $MemUsageMB = $MemUsageByte / 1MB
    $DiffBytes = $MemUsageByte - $Script:last_memory_usage_byte
    $BiffText = ""
    $Sign = ""
    If ( $Script:last_memory_usage_byte -ne 0 ) { 
        If ($DiffBytes -ge 0) {
            $Sign = "+"
        }
        $DiffText = ", $Sign$DiffBytes"
    }

    # save last value in script global variable
    $Script:last_memory_usage_byte = $MemUsageByte

    Return ("Memory usage {0:n1} MB ({1:n0} Bytes{2})" -f $MemUsageMB, $MemUsageByte, $Difftext)
}
