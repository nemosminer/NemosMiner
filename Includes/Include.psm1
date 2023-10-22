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
File:           \Includes\include.ps1
Version:        5.0.1.5
Version date:   2023/10/22
#>

$Global:DebugPreference = "SilentlyContinue"
$Global:ErrorActionPreference = "SilentlyContinue"
$Global:InformationPreference = "SilentlyContinue"
$Global:ProgressPreference = "SilentlyContinue"
$Global:WarningPreference = "SilentlyContinue"
$Global:VerbosePreference = "SilentlyContinue"

# Fix TLS Version erroring
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

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

# .Net methods for hiding/showing the console in the background
# https://stackoverflow.com/questions/40617800/opening-powershell-script-and-hide-command-prompt-but-not-the-gui
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

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
    [DeviceState]$State = [DeviceState]::Enabled
    [String]$Status = "Idle"
    [String]$StatusInfo = ""
    [String]$SubStatus
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
    $PoolPorts = @() # Cannot define nullable array
    [UInt16]$Port
    [UInt16]$PortSSL
    [Double]$Price
    [Double]$Price_Bias
    [String]$Protocol
    [System.Collections.Generic.List[String]]$Reasons = @()
    [String]$Region
    [Boolean]$SendHashrate # If true miner will send hashrate to pool
    [Boolean]$SSLSelfSignedCertificate
    [Double]$StablePrice
    [DateTime]$Updated = ([DateTime]::Now).ToUniversalTime()
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
    [DateTime]$Updated = ([DateTime]::Now).ToUniversalTime()
}

Enum MinerStatus { 
    Disabled
    DryRun
    Failed
    Idle
    Running
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
    [DateTime]$BeginTime # UniversalTime
    [Boolean]$Benchmark = $false # derived from stats
    [Boolean]$Best = $false
    [String]$CommandLine
    [Int]$ContinousCycle = 0 # Counter, miner has been running continously for n loops
    [Int]$DataCollectInterval = 5 # Seconds
    [DateTime]$DataSampleTimestamp = 0 # Newest sample
    [String[]]$DeviceNames = @() # derived from devices
    [PSCustomObject[]]$Devices = @()
    [Boolean]$Disabled = $false
    [Double]$Earning # derived from pool and stats
    [Double]$Earning_Bias # derived from pool and stats
    [Double]$Earning_Accuracy # derived from pool and stats
    [DateTime]$EndTime # UniversalTime
    [String[]]$EnvVars = @()
    [Double[]]$Hashrates_Live = @()
    [String]$Info
    [Boolean]$KeepRunning = $false # do not stop miner even if not best (MinInterval)
    [String]$Key
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
    [UInt32]$ProcessId = 0
    [Int]$ProcessPriority = -1
    [Double]$Profit
    [Double]$Profit_Bias
    [Boolean]$ReadPowerUsage = $false
    [System.Collections.Generic.List[String]]$Reasons # Why is a miner unavailable?
    [Boolean]$Restart = $false 
    hidden [DateTime]$StatStart
    hidden [DateTime]$StatEnd
    [MinerStatus]$Status = [MinerStatus]::Idle
    [String]$StatusInfo
    [String]$SubStatus
    [TimeSpan]$TotalMiningDuration # derived from pool and stats
    [String]$Type
    [DateTime]$Updated # derived from stats
    [String]$URI
    [DateTime]$ValidDataSampleTimestamp = 0
    [String]$Version
    [Int[]]$WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
    [String]$WindowStyle = "minimized"
    [Worker[]]$Workers = @()
    [Worker[]]$WorkersRunning = @()

    hidden [PSCustomObject[]]$Data = $null
    hidden [System.Management.Automation.Job]$DataReaderJob = $null
    hidden [System.Management.Automation.Job]$ProcessJob = $null
    hidden [System.Diagnostics.Process]$Process = $null
 
    [String[]]GetProcessNames() { 
        Return @(([IO.FileInfo]($this.Path | Split-Path -Leaf)).BaseName)
    }

    [String]GetCommandLineParameters() { 
        If ($this.Arguments -and (Test-Json -Json $this.Arguments -ErrorAction Ignore)) { 
            Return ($this.Arguments | ConvertFrom-Json).Arguments
        }
        Else { 
            Return $this.Arguments
        }
    }

    [String]GetCommandLine() { 
        Return "$($this.Path)$($this.GetCommandLineParameters())"
    }

    [Void]hidden StartDataReader() { 
        $ScriptBlock = { 
            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

            Try { 
                # Load miner API file
                . ".\Includes\MinerAPIs\$($args[0]).ps1"
                $ProgressPreference = "SilentlyContinue"
                $Miner = ($args[1] | ConvertFrom-Json) -as $args[0]
                Start-Sleep -Seconds 2

                While ($true) { 
                    # Start-Sleep -Seconds 60
                    $NextLoop = ([DateTime]::Now).AddSeconds($Miner.DataCollectInterval)
                    $Miner.GetMinerData()
                    While (([DateTime]::Now) -lt $NextLoop) { Start-Sleep -Milliseconds 50 }
                }
            }
            Catch { 
                Return
            }
        }

        # Start Miner data reader
        $this.DataReaderJob = Start-Job -Name "$($this.Name)_DataReader" -InitializationScript ([ScriptBlock]::Create("Set-Location('$(Get-Location)')")) -ScriptBlock $ScriptBlock -ArgumentList ($this.API), ($this | Select-Object -Property Algorithms, DataCollectInterval, Devices, Name, Path, Port, ReadPowerUsage, LogFile | ConvertTo-Json -WarningAction Ignore)

        Remove-Variable ScriptBlock -ErrorAction Ignore
    }

    [Void]hidden StopDataReader() { 
        If ($this.DataReaderJob) { 
            $this.DataReaderJob | Stop-Job
            # Get data before removing read data
            If ($this.Status -eq [MinerStatus]::Running -and $this.DataReaderJob.HasMoreData) { $this.Data += @($this.DataReaderJob | Receive-Job | Select-Object) }
            $this.DataReaderJob | Remove-Job -Force -ErrorAction Ignore
            $this.DataReaderJob = $null
        }
    }

    [Void]hidden RestartDataReader() { 
        $this.StopDataReader()
        $this.StartDataReader()
    }

    [Void] hidden StartMining() { 
        If ($this.Arguments -and (Test-Json $this.Arguments -ErrorAction Ignore)) { $this.CreateConfigFiles() }

        If ($this.Status -eq [MinerStatus]::DryRun) { 
            $this.StatusInfo = "Dry run '$($this.Info)'"
            Write-Message -Level Info "Dry run for miner '$($this.Info)'..."
            $this.StatStart = $this.BeginTime = ([DateTime]::Now).ToUniversalTime()
        }
        Else { 
            $this.StatusInfo = "Starting '$($this.Info)'"
            Write-Message -Level Info "Starting miner '$($this.Info)'..."
        }

        Write-Message -Level Verbose $this.CommandLine

        # Log switching information to .\Logs\SwitchingLog.csv
        [PSCustomObject]@{ 
            DateTime          = (Get-Date -Format o)
            Action            = If ($this.Status -eq [MinerStatus]::DryRun) { "DryRun" } Else { "Launched" }
            Name              = $this.Name
            Accounts          = ($this.Workers.Pool.User | ForEach-Object { $_ -replace '\.*' } | Select-Object -Unique) -join "; "
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

        If ($this.Status -ne [MinerStatus]::DryRun) { 

            $this.ProcessJob = Invoke-CreateProcess -BinaryPath $this.Path -ArgumentList $this.GetCommandLineParameters() -WorkingDirectory (Split-Path $this.Path) -WindowStyle $this.WindowStyle -EnvBlock $this.EnvVars -JobName $this.Name -LogFile $this.LogFile

            # Sometimes the process cannot be found instantly
            $Loops = 100
            Do { 
                If ($this.ProcessId = ($this.ProcessJob | Receive-Job | Select-Object -ExpandProperty ProcessId)) { 
                    $this.DataSampleTimestamp = [DateTime]0
                    $this.Status = [MinerStatus]::Running
                    $this.SubStatus = "Starting"
                    $this.StatStart = $this.BeginTime = ([DateTime]::Now).ToUniversalTime()
                    $this.Process = Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue
                    $this.StartDataReader()
                    Break
                }
                $Loops --
                Start-Sleep -Milliseconds 50
            } While ($Loops -gt 0)
            Remove-Variable Loops
        }
        $this.WorkersRunning = $this.Workers

    }

    [Void]hidden StopMining() { 
        If ($this.Status -in @([MinerStatus]::Running, [MinerStatus]::DryRun)) { 
            $this.StatusInfo = "Stopping miner '$($this.Info)'..."
            Write-Message -Level Info $this.StatusInfo
        }
        Else { 
            $this.SubStatus = [MinerStatus]::Failed
            Write-Message -Level Error $this.StatusInfo
        }

        $this.StopDataReader()

        $this.EndTime = ([DateTime]::Now).ToUniversalTime()

        If ($this.Process) { 
            $this.Process.CloseMainWindow()
            $this.Process = $null
        }

        If ($this.ProcessId) { 
            If (Get-Process -Id $this.ProcessId -ErrorAction Ignore) { Stop-Process -Id $this.ProcessId -Force -ErrorAction Ignore }
            $this.ProcessId = $null
        }

        If ($this.ProcessJob) { 
            $this.ProcessJob | Get-Job -ErrorAction Ignore | Stop-Job -ErrorAction Ignore | Receive-Job -ErrorAction Ignore
            $this.ProcessJob | Remove-Job -ErrorAction Ignore -Force
            $this.Active += $this.ProcessJob.PSEndTime - $this.ProcessJob.PSBeginTime
            $this.ProcessJob = $null
        }

        $this.Status = If ($this.Status -in @([MinerStatus]::Running, [MinerStatus]::DryRun)) { [MinerStatus]::Idle } Else { [MinerStatus]::Failed }

        # Log switching information to .\Logs\SwitchingLog
        [PSCustomObject]@{ 
            DateTime          = (Get-Date -Format o)
            Action            = If ($this.Status -eq [MinerStatus]::Idle) { "Stopped" } Else { "Failed" }
            Name              = $this.Name
            Accounts          = ($this.WorkersRunning.Pool.User | ForEach-Object { $_ -replace '\.*' } | Select-Object -Unique) -join "; "
            Algorithms        = $this.WorkersRunning.Pool.Algorithm -join "; "
            Benchmark         = $this.Benchmark
            CommandLine       = $this.CommandLine
            Cycle             = $this.ContinousCycle
            DeviceNames       = $this.DeviceNames -join "; "
            Duration          = "{0:hh\:mm\:ss}" -f ($this.EndTime - $this.BeginTime)
            Earning           = $this.Earning
            Earning_Bias      = $this.Earning_Bias
            LastDataSample    = $this.Data | Select-Object -Last 1 -ErrorAction Ignore | ConvertTo-Json -Compress
            MeasurePowerUsage = $this.MeasurePowerUsage
            Pools             = ($this.WorkersRunning.Pool.Name | Select-Object -Unique) -join "; "
            Profit            = $this.Profit
            Profit_Bias       = $this.Profit_Bias
            Reason            = If ($this.Status -eq [MinerStatus]::Failed) { $this.StatusInfo -replace "'$($this.StatusInfo)' " } Else { "" }
            Type              = $this.Type
        } | Export-Csv -Path ".\Logs\SwitchingLog.csv" -Append -NoTypeInformation

        If ($this.Status -eq [MinerStatus]::Idle) { 
            $this.StatusInfo = "Idle"
            $this.SubStatus = $this.Status
        }
        $this.Data = @()
    }

    [MinerStatus]GetStatus() { 
        if ($this.ProcessJob.State -eq "Running" -and $this.ProcessId -and (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName)) { 
            # Use ProcessName, some crashed miners are dead, but may still be found by their processId
            Return [MinerStatus]::Running
        }
        ElseIf ($this.Status -eq [MinerStatus]::Running) { 
            Return [MinerStatus]::Failed
        }
        Else { 
            Return $this.Status
        }
    }

    [Void]SetStatus([MinerStatus]$Status) { 
        Switch ($Status) { 
            "DryRun" { 
                $this.Status = [MinerStatus]::DryRun
                $this.StartMining()
                Break
            }
            "Idle" { 
                $this.StopMining()
                Break
            }
            "Running" { 
                $this.StartMining()
                Break
            }
            Default { 
                $this.Status = [MinerStatus]::Failed
                $this.StopMining()
            }
        }
    }

    [DateTime]GetActiveLast() { 
        If ($this.Process.BeginTime -and $this.Process.EndTime) { 
            Return $this.Process.EndTime
        }
        ElseIf ($this.Process.BeginTime) { 
            Return ([DateTime]::Now).ToUniversalTime()
        }
        ElseIf ($this.EndTime) { 
            Return $this.EndTime
        }
        Else { 
            Return [DateTime]::MinValue
        }
    }

    [TimeSpan]GetActiveTime() { 
        If ($this.Process.BeginTime -and $this.Process.EndTime) { 
            Return $this.Active + ($this.Process.EndTime - $this.Process.BeginTime)
        }
        ElseIf ($this.Process.BeginTime) { 
            Return $this.Active + ([DateTime]::Now - $this.Process.BeginTime)
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
                $TotalPowerUsage += [Double]($RegistryData.($RegistryEntry.Name -replace 'Label', 'Value') -split ' ' | Select-Object -First 1)
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

        $Hashrate_Average = ($Hashrate_Samples.Hashrate.$Algorithm | Measure-Object -Average | Select-Object -ExpandProperty Average)
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

        $PowerUsage_Average = ($PowerUsage_Samples.PowerUsage | Measure-Object -Average | Select-Object -ExpandProperty Average)
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

    [Void]Refresh([Double]$PowerCostBTCperW, [Boolean]$CalculatePowerCost) { 
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
        $this.Reasons = [System.Collections.Generic.List[String]]@()

        $this.Workers | ForEach-Object { 
            If ($Stat = Get-Stat -Name "$($this.Name)_$($this.Algorithms[$this.Workers.IndexOf($_)])_Hashrate") { 
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

        $this.Earning = ($this.Workers.Earning | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
        $this.Earning_Bias = ($this.Workers.Earning_Bias | Measure-Object -Sum | Select-Object -ExpandProperty Sum)

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

        $this.TotalMiningDuration = ($this.Workers.TotalMiningDuration | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)
        $this.Updated = ($this.Workers.Updated | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)

        $this.ReadPowerUsage = [Boolean]($this.Devices.ReadPowerUsage -notcontains $false)

        If ($CalculatePowerCost) { 
            If ($Stat = Get-Stat -Name "$($this.Name)$(If ($this.Algorithms.Count -eq 1) { "_$($this.Algorithms | Select-Object -Index 0)" })_PowerUsage") { 
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
    $Variables.IdleRunspace = [RunspaceFactory]::CreateRunspace()
    $Variables.IdleRunspace.ApartmentState = "STA"
    $Variables.IdleRunspace.Name = "IdleRunspace"
    $Variables.IdleRunspace.ThreadOptions = "ReuseThread"
    $Variables.IdleRunspace.Open()
    Get-Variable -Scope Global | Where-Object Name -in @("Config", "Variables") | ForEach-Object { 
        $Variables.IdleRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
    }
    [Void]$Variables.IdleRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath) | Out-Null
    $Variables.IdleRunspace | Add-Member MiningStatus "Running" -Force

    $PowerShell = [PowerShell]::Create()
    $PowerShell.Runspace = $Variables.IdleRunspace
    [Void]$Powershell.AddScript(
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

                    $MiningStatusLabel.Text = "$($Variables.Branding.ProductLabel) is idle"
                    $MiningStatusLabel.ForeColor = [System.Drawing.Color]::Green
                }

                # System has been idle long enough, start mining
                If ($IdleSeconds -ge $Config.IdleSec -and $Variables.IdleRunspace.MiningStatus -ne "Running") { 
                    $Variables.IdleRunspace | Add-Member MiningStatus "Running" -Force

                    $MiningStatusLabel.Text = "$($Variables.Branding.ProductLabel) is running"
                    $MiningStatusLabel.ForeColor = [System.Drawing.Color]::Green
                }
                Start-Sleep -Seconds 1
            }
        }
    )

    $Variables.IdleRunspace | Add-Member @{ PowerShell = $PowerShell; StartTime = ([DateTime]::Now).ToUniversalTime() }
    $Powershell.BeginInvoke() | Out-Null
}

Function Stop-IdleDetection { 

    If ($Variables.IdleRunspace) { 
        $Variables.IdleRunspace.Close()
        If ($Variables.IdleRunspace.PowerShell) { $Variables.IdleRunspace.PowerShell.Dispose() }
        $Variables.IdleRunspace.Dispose()
        $Variables.Remove("IdleRunspace")
        Write-Message -Level Verbose "Stopped idle detection."
    }

    [System.GC]::Collect()
}

Function Start-Core { 

    If (-not $Global:CoreRunspace) { 
        $Variables.Summary = "Starting mining processes..."
        Write-Message -Level Verbose ($Variables.Summary -replace '<br>', ' ')

        $Variables.Timer = $null
        $Variables.LastDonated = ([DateTime]::Now).AddDays(-1).AddHours(1)
        $Variables.Pools = [Pool[]]@()
        $Variables.Miners = [Miner[]]@()
        $Variables.MinersBest_Combo = [Miner[]]@()

        $Variables.CycleStarts = @()

        $Runspace = [RunspaceFactory]::CreateRunspace()
        $Runspace.ApartmentState = "STA"
        $Runspace.Name = "Core"
        $Runspace.ThreadOptions = "ReuseThread"
        $Runspace.Open()
        Get-Variable -Scope Global | Where-Object Name -in @("Config", "Stats", "Variables") | ForEach-Object { 
            $Runspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
        }
        [Void]$Runspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

        $PowerShell = [PowerShell]::Create()
        $PowerShell.Runspace = $Runspace
        [Void]$Powershell.AddScript("$($Variables.MainPath)\Includes\Core.ps1")

        $Global:CoreRunspace = @{ PowerShell = $PowerShell; StartTime = ([DateTime]::Now).ToUniversalTime() }

        $Powershell.BeginInvoke() | Out-Null

        $Variables.Summary = "Mining processes are running."
    }
}

Function Stop-Core { 

    Param(
        [Parameter(Mandatory = $false)]
        [Switch]$Quick = $false
    )

    If ($Global:CoreRunspace) { 
        $Variables.Summary = "Stopping mining processes..."
        Write-Message -Level Verbose ($Variables.Summary -replace '<br>', ' ')

        # Give core loop time to shut down gracefully
        $Timestamp = ([DateTime]::Now).AddSeconds(30)
        While (-not $Quick -and ($Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::Running }) -and ([DateTime]::Now) -le $Timestamp) { 
            Start-Sleep -Seconds 1
        }
        $Global:CoreRunspace.PowerShell.Runspace.Dispose()

        #Stop all running miners
        ForEach ($Miner in ($Variables.Miners | Where-Object { $_.Status -ne [MinerStatus]::Idle })) { 
            $Miner.SetStatus([MinerStatus]::Idle)
            $Miner.WorkersRunning = [Worker[]]@()
            $Variables.Devices | Where-Object Name -in $Miner.DeviceNames | ForEach-Object { $_.Status = $Miner.Status; $_.StatusInfo = $Miner.StatusInfo }
        }
        $Variables.RunningMiners = [Miner[]]@()
        $Variables.BenchmarkingOrMeasuringMiners = [Miner[]]@()
        $Variables.FailedMiners = [Miner[]]@()
        Remove-Variable CoreRunspace -Scope Global -ErrorAction Ignore
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

    [System.GC]::Collect()
}

Function Start-Brain { 

    Param(
        [Parameter(Mandatory = $true)]
        [String[]]$Brains
    )

    If (Test-Path -Path ".\Brains" -PathType Container) { 

        # Starts Brains if necessary
        $BrainsStarted = @()
        $Brains | ForEach-Object { 
            If ($Config.PoolsConfig.$_.BrainConfig -and -not $Variables.Brains.$_) { 
                $BrainScript = ".\Brains\$($_).ps1"
                If (Test-Path -Path $BrainScript -PathType Leaf) { 

                    $Runspace = [RunspaceFactory]::CreateRunspace()
                    $Runspace.ApartmentState = "STA"
                    $Runspace.Name = "Brain_$($_)"
                    $Runspace.ThreadOptions = "ReuseThread"
                    $Runspace.Open()
                    Get-Variable -Scope Global | Where-Object Name -in @("Config", "Stats", "Variables") | ForEach-Object { 
                        $Runspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
                    }
                    [Void]$Runspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
                    $PowerShell = [PowerShell]::Create()
                    $PowerShell.Runspace = $Runspace
                    $Powershell.AddScript($BrainScript)

                    $Variables.Brains.$_ = @{ PowerShell = $PowerShell; StartTime = ([DateTime]::Now).ToUniversalTime() }

                    $PowerShell.BeginInvoke() | Out-Null

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
        [String[]]$Brains = $Variables.Brains.psBase.Keys
    )

    If ($Brains) { 

        $BrainsStopped = @()

        $Brains | Where-Object { $Variables.Brains.$_ } | ForEach-Object { 
            # Stop Brains
            $Variables.Brains[$_].PowerShell.Runspace.Dispose() | Out-Null
            $Variables.Brains.Remove($_)
            $Variables.BrainData.Remove($_)
            $BrainsStopped += $_
        }

        If ($BrainsStopped.Count -gt 0) { Write-Message -Level Info  "Pool brain backgound job$(If ($BrainsStopped.Count -gt 1) { "s" }) for '$(($BrainsStopped | Sort-Object) -join ", ")' stopped." }
    }

    [System.GC]::Collect()
}

Function Start-BalancesTracker { 

    If (-not $Variables.BalancesTrackerRunspace) { 

        If (Test-Path -Path ".\Balances" -PathType Container) { 
            Try { 
                $Variables.Summary = "Starting Balances Tracker background process..."
                Write-Message -Level Verbose ($Variables.Summary -replace '<br>', ' ')

                $Runspace = [RunspaceFactory]::CreateRunspace()
                $Runspace.ApartmentState = "STA"
                $Runspace.Name = "BalancesTracker"
                $Runspace.ThreadOptions = "ReuseThread"
                $Runspace.Open()
                Get-Variable -Scope Global | Where-Object Name -in @("Config", "Variables") | ForEach-Object { 
                    $Runspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
                }
                [Void]$Runspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

                $PowerShell = [PowerShell]::Create()
                $PowerShell.Runspace = $Runspace
                [Void]$Powershell.AddScript("$($Variables.MainPath)\Includes\BalancesTracker.ps1")
                $Variables.BalancesTrackerRunspace = @{ PowerShell = $PowerShell; StartTime = ([DateTime]::Now).ToUniversalTime() }

                $Powershell.BeginInvoke() | Out-Null
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

        $Variables.BalancesTrackerRunspace.PowerShell.Runspace.Dispose()
        $Variables.Remove("BalancesTrackerRunspace")

        [System.GC]::Collect()

        $Variables.Summary += "<br>Balances Tracker background process stopped."
        Write-Message -Level Info "Balances Tracker background process stopped."
    }
}

Function Initialize-Application { 
    # Verify donation data
    $Variables.DonationData = Get-Content -Path ".\Data\DonationData.json" -ErrorAction Ignore | ConvertFrom-Json -NoEnumerate
    If (-not $Variables.DonationData) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\DonationData.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\DonationData.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Verify donation log
    $Variables.DonationLog = Get-Content -Path ".\Logs\DonateLog.json" -ErrorAction Ignore | ConvertFrom-Json -NoEnumerate
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
    # Load unprofitable algorithms
    Try { 
        If (-not $Variables.UnprofitableAlgorithms -or (Get-ChildItem -Path ".\Data\UnprofitableAlgorithms.json").LastWriteTime -gt $Variables.Timer.AddSeconds( - $Config.Interval)) { 
            $Variables.UnprofitableAlgorithms = Get-Content -Path ".\Data\UnprofitableAlgorithms.json" | ConvertFrom-Json -ErrorAction Stop -AsHashtable | Get-SortedObject
            Write-Message -Level Info "Loaded list of unprofitable algorithms ($($Variables.UnprofitableAlgorithms.Count) $(If ($Variables.UnprofitableAlgorithms.Count -ne 1) { "entries" } Else { "entry" }))."
        }
    }
    Catch { 
        Write-Message -Level Error "Error loading list of unprofitable algorithms. File '.\Data\UnprofitableAlgorithms.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\UnprofitableAlgorithms.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load coin names
    $Variables.CoinNames = [Ordered]@{ } # as case insensitive hash table
    (Get-Content -Path ".\Data\CoinNames.json" -ErrorAction Stop | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Variables.CoinNames[$_.Name] = $_.Value }
    If (-not $Variables.CoinNames) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\CoinNames.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\CoinNames.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load EquihashCoinPers data
    $Variables.EquihashCoinPers = [Ordered]@{ } # as case insensitive hash table
    (Get-Content -Path ".\Data\EquihashCoinPers.json" -ErrorAction Stop | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Variables.EquihashCoinPers[$_.Name] = $_.Value }
    If (-not $Variables.EquihashCoinPers) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\EquihashCoinPers.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\EquihashCoinPers.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load currency algorithm data
    $Variables.CurrencyAlgorithm = [Ordered]@{ } # as case insensitive hash table
    (Get-Content -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction Stop | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Variables.CurrencyAlgorithm[$_.Name] = $_.Value }
    If (-not $Variables.CurrencyAlgorithm) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\CurrencyAlgorithm.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Start-Sleep -Seconds 10
        Exit
    }
    # Load regions list
    $Variables.Regions = [Ordered]@{ } # as case insensitive hash table
    (Get-Content -Path ".\Data\Regions.json" -ErrorAction Stop | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Variables.Regions[$_.Name] = @($_.Value) }
    If (-not $Variables.Regions) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\Regions.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\Regions.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load FIAT currencies list
    $Variables.FIATcurrencies = Get-Content -Path ".\Data\FIATcurrencies.json" | ConvertFrom-Json -AsHashtable
    If (-not $Variables.FIATcurrencies) { 
        Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\FIATcurrencies.json' is not a valid JSON file. Please restore it from your original download."
        $WscriptShell.Popup("File '.\Data\FIATcurrencies.json' is not a valid JSON file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
        Exit
    }
    # Load DAG data, if not available it will get recreated
    $Variables.DAGdata = Get-Content ".\Data\DAGdata.json" -ErrorAction Ignore | ConvertFrom-Json -AsHashtable

    # Load PoolsLastUsed data
    $Variables.PoolsLastUsed = Get-Content -Path ".\Data\PoolsLastUsed.json" -ErrorAction Ignore | ConvertFrom-Json -AsHashtable
    If (-not $Variables.PoolsLastUsed.psBase.Keys) { $Variables.PoolsLastUsed = @{ } }

    # Load AlgorithmsLastUsed data
    $Variables.AlgorithmsLastUsed = Get-Content -Path ".\Data\AlgorithmsLastUsed.json" -ErrorAction Ignore | ConvertFrom-Json -AsHashtable
    If (-not $Variables.AlgorithmsLastUsed.psBase.Keys) { $Variables.AlgorithmsLastUsed = @{ } }

    # Load EarningsChart data to make it available early in GUI
    If (Test-Path -Path ".\Data\EarningsChartData.json" -PathType Leaf) { $Variables.EarningsChartData = Get-Content ".\Data\EarningsChartData.json" | ConvertFrom-Json }

    # Load Balances data to make it available early in GUI
    If (Test-Path -Path ".\Data\Balances.json" -PathType Leaf) { $Variables.Balances = Get-Content ".\Data\Balances.json" | ConvertFrom-Json }
    $Variables.BalancesCurrencies = @($variables.Balances.PSObject.Properties.Name | ForEach-Object { $Variables.Balances.$_.Currency })

    # Keep only the last 10 files
    Get-ChildItem -Path ".\Logs\$($Variables.Branding.ProductLabel)_*.log" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path ".\Logs\SwitchingLog_*.csv" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse
    Get-ChildItem -Path "$($Variables.ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse

    If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12 }

    If ($Config.Proxy -eq "") { $PSDefaultParameterValues.Remove("*:Proxy") }
    Else { $PSDefaultParameterValues["*:Proxy"] = $Config.Proxy }

    # Set process priority to BelowNormal to avoid hashrate drops on systems with weak CPUs
    (Get-Process -Id $PID).PriorityClass = "BelowNormal"
   
    [Void](Get-Rate)

}

Function Get-DefaultAlgorithm { 

    If ($PoolsAlgos = Get-Content ".\Data\PoolsConfig-Recommended.json" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore) { 
        Return ($PoolsAlgos.PSObject.Properties.Name | Where-Object { $_ -in @(Get-PoolBaseName $Config.PoolName) } | ForEach-Object { $PoolsAlgos.$_.Algorithm }) | Sort-Object -Unique
    }
    Return
}

Function Get-Rate { 

    $RatesCacheFileName = "$($Variables.MainPath)\Cache\Rates.json"

    # Use stored currencies from last run
    If (-not $Variables.BalancesCurrencies -and $Config.BalancesTrackerPollInterval) { $Variables.BalancesCurrencies = $Variables.Rates.PSObject.Properties.Name | Where-Object { $_ -eq  ($_ -replace '^m') } }

    $Variables.AllCurrencies = @(@(@($Config.MainCurrency) + @($Config.Wallets.psBase.Keys) + @($Config.ExtraCurrencies) + @($Variables.BalancesCurrencies) | Select-Object) -replace 'mBTC', 'BTC' | Sort-Object -Unique)

    If (-not $Variables.Rates.BTC.($Config.MainCurrency) -or (Compare-Object @(@($Variables.Rates.PSObject.Properties.Name | Select-Object) + @($Variables.RatesMissingCurrencies | Select-Object)) @($Variables.AllCurrencies | Select-Object) | Where-Object SideIndicator -eq "=>") -or ($Variables.RatesUpdated -lt ([DateTime]::Now).ToUniversalTime().AddMinutes(-(3, ($Config.BalancesTrackerPollInterval, 15 | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)))) { 
        Try { 
            $TSymBatches = @()
            $TSyms = "BTC"
            $Variables.AllCurrencies | Where-Object { $_ -ne "BTC" } | ForEach-Object { 
                If (($TSyms.Length + $_.Length) -lt 99) {
                    $TSyms = "$TSyms,$($_)"
                }
                Else { 
                    $TSymBatches += $TSyms
                    $TSyms = $_
                }
            }
            $TSymBatches += $TSyms

            $Rates = [PSCustomObject]@{ BTC = [PSCustomObject]@{ } }
            $TSymBatches | ForEach-Object { 
                $Response = Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$($_)$(If ($Config.CryptoCompareAPIKeyParam) { "&api_key=$($Config.CryptoCompareAPIKeyParam)" })&extraParams=$($Variables.Branding.BrandWebSite) Version $($Variables.Branding.Version)" -TimeoutSec 5 -ErrorAction Ignore
                If ($Response.BTC) { 
                    $Response.BTC | ForEach-Object { 
                        $_.PSObject.Properties | Select-Object | ForEach-Object { $Rates.BTC | Add-Member @{ "$($_.Name)" = $_.Value } -Force }
                    }
                }
                Else { 
                    If ($Response.Message -eq "You are over your rate limit please upgrade your account!") { 
                        Write-Message -Level Error "min-api.cryptocompare.com API rate exceeded. You need to register an account with cryptocompare.com and add the API key as 'CryptoCompareAPIKeyParam' to the configuration file '$($Variables.ConfigFile)'."
                     }
                }
            }

            If ($Currencies = $Rates.BTC.PSObject.Properties.Name) { 
                $Currencies | Select-Object | Where-Object { $_ -ne "BTC" } | ForEach-Object { 
                    $Currency = $_
                    $Rates | Add-Member $Currency ($Rates.BTC | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json) -Force
                    $Rates.$Currency.PSObject.Properties.Name | ForEach-Object { 
                        $Rates.$Currency | Add-Member $_ (($Rates.BTC.$_ / $Rates.BTC.$Currency) -as [Double]) -Force
                    }
                }

                # Add mBTC
                If ($Config.UsemBTC) { 
                    $Currencies | ForEach-Object { 
                        $Currency = $_
                        $mCurrency = "m$($Currency)"
                        $Rates | Add-Member $mCurrency ($Rates.$Currency | ConvertTo-Json -WarningAction SilentlyContinue | ConvertFrom-Json) -Force
                        $Rates.$mCurrency.PSOBject.Properties.Name | ForEach-Object { 
                            $Rates.$mCurrency | Add-Member $_ ([Double]$Rates.$Currency.$_ / 1000) -Force
                        }
                    }
                    $Rates.PSOBject.Properties.Name | ForEach-Object { 
                        $Currency = $_
                        $Rates.PSOBject.Properties.Name | Where-Object { $_ -in $Currencies } | ForEach-Object { 
                            $mCurrency = "m$($_)"
                            $Rates.$Currency | Add-Member $mCurrency ([Double]$Rates.$Currency.$_ * 1000) -Force
                        }
                    }
                }
                Write-Message -Level Info "Loaded currency exchange rates from 'min-api.cryptocompare.com'.$(If ($Variables.RatesMissingCurrencies = Compare-Object @($Currencies | Select-Object) @($Variables.AllCurrencies | Select-Object) -PassThru) { " API does not provide rates for '$($Variables.RatesMissingCurrencies -join ', ')'." })"
                $Variables.Rates = $Rates
                $Variables.RatesUpdated = ([DateTime]::Now).ToUniversalTime()

                $Variables.Rates | ConvertTo-Json -Depth 5 | Out-File -FilePath $RatesCacheFileName -Force -ErrorAction Ignore
            }
        }
        Catch { 
            # Read exchange rates from min-api.cryptocompare.com, use stored data as fallback
            $RatesCache = (Get-Content -Path $RatesCacheFileName -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore)
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
}

Function Write-Message { 

    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]$Message, 
        [Parameter(Mandatory = $false)]
        [String]$Level = "Info"
    )

    $Message = $Message -replace '<br>', ' ' -replace '&ensp;', ' '

    # Make sure we are in main script
    If ($Host.Name -eq "ConsoleHost") { 
        # Write to console
        Switch ($Level) { 
            "Error"   { Write-Host $Message -ForegroundColor "Red" }
            "Warn"    { Write-Host $Message -ForegroundColor "Magenta" }
            "Info"    { Write-Host $Message -ForegroundColor "White" }
            "Verbose" { Write-Host $Message -ForegroundColor "Yello" }
            "Debug"   { Write-Host $Message -ForegroundColor "Blue" }
        }
    }

    $Message = "$(Get-Date -Format "yyyy-MM-dd HH:mm:ss") $($Level.ToUpper()): $Message"

    If (-not $Config.Keys -or $Level -in $Config.LogToScreen) { 
        # Ignore error when legacy GUI gets closed
        Try { 
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
        Catch { }
    }

    If (-not $Config.Keys -or $Level -in $Config.LogToFile) { 
        # Get mutex. Mutexes are shared across all threads and processes. 
        # This lets us ensure only one thread is trying to write to the file at a time. 
        $Mutex = New-Object System.Threading.Mutex($false, $Variables.Branding.ProductLabel)

        $LogFile = "$($Variables.MainPath)\Logs\$($Variables.Branding.ProductLabel)_$(Get-Date -Format "yyyy-MM-dd").log"
        If ($Variables.LogFile -ne $LogFile) { $Variables.LogFile = $LogFIle }

        # Attempt to aquire mutex, waiting up to 1 second if necessary
        If ($Mutex.WaitOne(1000)) { 
            $Message | Out-File -FilePath $LogFile -Append -ErrorAction Ignore
            [Void]$Mutex.ReleaseMutex()
        }
    }
}

Function Write-MonitoringData { 

    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip If server and user aren't filled out
    If (-not $Config.MonitoringServer) { Return }
    If (-not $Config.MonitoringUser) { Return }

    # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
    # reveal someone's windows username or other system information they might not want sent
    # For the ones that can be an array, comma separate them
    $Data = @(
        $Variables.Miners | Where-Object { $_.Status -eq [MinerStatus]::DryRun -or $_.Status -eq [MinerStatus]::Running } | Sort-Object { [String]$_.DeviceNames } | ForEach-Object { 
            [PSCustomObject]@{ 
                Algorithm      = $_.WorkersRunning.Pool.Algorithm -join ','
                Currency       = $Config.MainCurrency
                CurrentSpeed   = $_.Hashrates_Live
                Earning        = ($_.WorkersRunning.Earning | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
                EstimatedSpeed = $_.WorkersRunning.Hashrate
                Name           = $_.Name
                Path           = Resolve-Path -Relative $_.Path
                Pool           = $_.WorkersRunning.Pool.Name -join ','
                Profit         = If ($_.Profit) { $_.Profit } ElseIf ($Variables.CalculatePowerCost) { ($_.WorkersRunning.Profit | Measure-Object -Sum | Select-Object -ExpandProperty Sum) - ($_.PowerUsage_Live * $Variables.PowerCostBTCperW) } Else { [Double]::Nan }
                Type           = $_.Type
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

    If ($Config.ShowWorkerStatus -and $Config.MonitoringUser -and $Config.MonitoringServer -and $Variables.WorkersLastUpdated -lt ([DateTime]::Now).AddSeconds(-30)) { 
        Try { 
            $Workers = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/workers.php" -Method Post -Body @{ user = $Config.MonitoringUser } -TimeoutSec 10 -ErrorAction Stop
            # Calculate some additional properties and format others
            $Workers | ForEach-Object { 
                # Convert the unix timestamp to a datetime object, taking into account the local time zone
                $_ | Add-Member @{ date = [TimeZone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($_.lastseen)) } -Force

                # If a machine hasn't reported in for more than 10 minutes, mark it as offline
                If ((New-TimeSpan -Start $_.date -End ([DateTime]::Now)).TotalMinutes -gt 10) { $_.status = "Offline" }
            }
            $Variables.Workers = $Workers
            $Variables.WorkersLastUpdated = ([DateTime]::Now)

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
        [DateTime]$TimeStamp
    )

    $TimeSpan = New-TimeSpan -Start $TimeStamp -End ([DateTime]::Now)
    $TimeSince = ""

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

    $HT2.psBase.Keys | ForEach-Object { 
        If ($HT1.$_ -is [Hashtable]) { 
            $HT1[$_] = Merge-Hashtable -HT1 $HT1[$_] -Ht2 $HT2.$_ -Unique $Unique
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
        $PoolConfig = $Config.PoolsConfig[$_] | ConvertTo-Json -Depth 99 -Compress | ConvertFrom-Json -AsHashTable
        $PoolConfig.EarningsAdjustmentFactor = 1
        $PoolConfig.Region = $Config.PoolsConfig[$_].Region
        $PoolConfig.WorkerName = "$($Variables.Branding.ProductLabel)-$($Variables.Branding.Version.ToString())-donate$($Config.Donation)"
        Switch -regex ($_) { 
            "^MiningDutch$|^MiningPoolHub$|^ProHashing$" { 
                If ($Variables.DonationRandom."$($_)UserName") { 
                    # not all devs have a known HashCryptos, MiningDutch or ProHashing account
                    $PoolConfig.UserName = $Variables.DonationRandom."$($_)UserName"
                    $PoolConfig.Variant = $Config.PoolsConfig[$_].Variant
                    $DonationRandomPoolsConfig.$_ = $PoolConfig
                }
                Break
            }
            Default { 
                # not all devs have a known ETC or ETH address
                If (Compare-Object @($Variables.PoolData.$_.GuaranteedPayoutCurrencies | Select-Object) @($Variables.DonationRandom.Wallets.PSObject.Properties.Name | Select-Object) -IncludeEqual -ExcludeDifferent) { 
                    $PoolConfig.Variant = If ($Config.PoolsConfig[$_].Variant) { $Config.PoolsConfig[$_].Variant } Else { $Config.PoolName -match $_ }
                    $PoolConfig.Wallets = $Variables.DonationRandom.Wallets | ConvertTo-Json | ConvertFrom-Json -AsHashtable
                    $DonationRandomPoolsConfig.$_ = $PoolConfig
                }
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

        $DefaultConfig = @{ }

        $DefaultConfig.ConfigFileVersion = $Variables.Branding.Version.ToString()
        $Variables.FreshConfig = $true

        # Add default enabled pools
        If (Test-Path -Path ".\Data\PoolsConfig-Recommended.json" -PathType Leaf) { 
            $Temp = (Get-Content ".\Data\PoolsConfig-Recommended.json" | ConvertFrom-Json)
            $DefaultConfig.PoolName = $Temp.PSObject.Properties.Name | Where-Object { $_ -ne "Default" } | ForEach-Object { $Temp.$_.Variant.PSObject.Properties.Name }
        }

        # Add default config items
        $Variables.AllCommandLineParameters.psBase.Keys | Where-Object { $_ -notin $DefaultConfig.psBase.Keys } | ForEach-Object { 
            $Value = $Variables.AllCommandLineParameters.$_
            If ($Value -is [Switch]) { $Value = [Boolean]$Value }
            $DefaultConfig.$_ = $Value
        }
        # MinerInstancePerDeviceModel: Default to $true if more than one device model per vendor
        $DefaultConfig.MinerInstancePerDeviceModel = ($Variables.Devices | Group-Object Vendor | ForEach-Object { ($_.Group.Model | Sort-Object -Unique).Count } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) -gt 1

        Return $DefaultConfig
    }

    Function Get-PoolsConfig { 

        # Load pool data
        If (-not $Variables.PoolData) { 
            $Variables.PoolData = Get-Content -Path ".\Data\PoolData.json" | ConvertFrom-Json -AsHashtable | Get-SortedObject
            $Variables.PoolVariants = @(($Variables.PoolData.psBase.Keys | ForEach-Object { $Variables.PoolData.$_.Variant.psBase.Keys -replace ' External$| Internal$' }) | Sort-Object -Unique)
            If (-not $Variables.PoolVariants) { 
                Write-Message -Level Error "Terminating Error - Cannot continue! File '.\Data\PoolData.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file. Please restore it from your original download."
                $WscriptShell.Popup("File '.\Data\PoolData.json' is not a valid $($Variables.Branding.ProductLabel) JSON data file.`nPlease restore it from your original download.", 0, "Terminating error - Cannot continue!", 4112) | Out-Null
                Exit
            }
        }

        # Build in memory pool config
        $PoolsConfig = @{ }
        (Get-ChildItem .\Pools\*.ps1 -File).BaseName | Sort-Object -Unique | ForEach-Object { 
            $PoolName = $_
            If ($PoolConfig = $Variables.PoolData.$PoolName) { 
                If ($CustomPoolConfig = $Variables.PoolsConfigData.$PoolName) { 
                    # Merge default config data with custom pool config
                    $PoolConfig = Merge-Hashtable -HT1 $PoolConfig -HT2 $CustomPoolConfig -Unique $true
                }

                If (-not $PoolConfig.EarningsAdjustmentFactor) {
                     $PoolConfig.EarningsAdjustmentFactor = $ConfigFromFile.EarningsAdjustmentFactor
                }
                If ($PoolConfig.EarningsAdjustmentFactor -le 0 -or $PoolConfig.EarningsAdjustmentFactor -gt 10) { 
                    $PoolConfig.EarningsAdjustmentFactor = $ConfigFromFile.EarningsAdjustmentFactor
                    Write-Message -Level Warn "Earnings adjustment factor (value: $($PoolConfig.EarningsAdjustmentFactor)) for pool '$PoolName' is not within supported range (0 - 10); using default value $($PoolConfig.EarningsAdjustmentFactor)."
                }

                If (-not $PoolConfig.WorkerName) { $PoolConfig.WorkerName = $ConfigFromFile.WorkerName }
                If (-not $PoolConfig.BalancesKeepAlive) { $PoolConfig.BalancesKeepAlive = $PoolData.$PoolName.BalancesKeepAlive }

                $PoolConfig.Region = $PoolConfig.Region | Where-Object { (Get-Region $_) -notin @($PoolConfig.ExcludeRegion) }

                Switch ($PoolName) { 
                    "Hiveon" { 
                        If (-not $PoolConfig.Wallets) { 
                            $PoolConfig.Wallets = [Ordered]@{ }
                            $ConfigFromFile.Wallets.GetEnumerator().Name | Where-Object { $_ -in $PoolConfig.PayoutCurrencies } | ForEach-Object { 
                                $PoolConfig.Wallets.$_ = $ConfigFromFile.Wallets.$_
                            }
                        }
                        Break
                    }
                    "MiningDutch" { 
                        If ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $ConfigFromFile.PayoutCurrency }
                        If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.MiningDutchUserName }
                        If (-not $PoolConfig.Wallets) { $PoolConfig.Wallets = @{ "$($PoolConfig.PayoutCurrency)" = $($ConfigFromFile.Wallets.($PoolConfig.PayoutCurrency)) } }
                        Break
                    }
                    "MiningPoolHub" { 
                        If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.MiningPoolHubUserName }
                        Break
                    }
                    "NiceHash" { 
                        If (-not $PoolConfig.Variant."Nicehash Internal".Wallets.BTC) { 
                            If ($ConfigFromFile.NiceHashWallet -and $ConfigFromFile.NiceHashWalletIsInternal) { $PoolConfig.Variant."NiceHash Internal".Wallets = @{ "BTC" = $ConfigFromFile.NiceHashWallet } }
                        }
                        If (-not $PoolConfig.Variant."Nicehash External".Wallets.BTC) { 
                            If ($ConfigFromFile.NiceHashWallet -and -not $ConfigFromFile.NiceHashWalletIsInternal) { $PoolConfig.Variant."NiceHash External".Wallets = @{ "BTC" = $ConfigFromFile.NiceHashWallet } }
                            ElseIf ($ConfigFromFile.Wallets.BTC) { $PoolConfig.Variant."NiceHash External".Wallets = @{ "BTC" = $ConfigFromFile.Wallets.BTC } }
                        }
                        Break
                    }
                    "ProHashing" { 
                        If (-not $PoolConfig.UserName) { $PoolConfig.UserName = $ConfigFromFile.ProHashingUserName }
                        If (-not $PoolConfig.MiningMode) { $PoolConfig.MiningMode = $ConfigFromFile.ProHashingMiningMode }
                        Break
                    }
                    Default { 
                        If ((-not $PoolConfig.PayoutCurrency) -or $PoolConfig.PayoutCurrency -eq "[Default]") { $PoolConfig.PayoutCurrency = $ConfigFromFile.PayoutCurrency }
                        If (-not $PoolConfig.Wallets) { $PoolConfig.Wallets = @{ "$($PoolConfig.PayoutCurrency)" = $($ConfigFromFile.Wallets.($PoolConfig.PayoutCurrency)) } }
                        $PoolConfig.Remove("PayoutCurrency")
                    }
                }
                If ($PoolConfig.Algorithm) { $PoolConfig.Algorithm = @($PoolConfig.Algorithm -replace ' ' -split ',') }
            }
            $PoolsConfig.$PoolName = $PoolConfig
        }

        Return $PoolsConfig
    }

    # Load the configuration
    $ConfigFromFile = @{ }
    If (Test-Path -Path $ConfigFile -PathType Leaf) { 
        $ConfigFromFile = Get-Content -Path $ConfigFile | ConvertFrom-Json -AsHashtable | Get-SortedObject
        If ($ConfigFromFile.psBase.Keys.Count -eq 0) { 
            $CorruptConfigFile = "$($ConfigFile)_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").corrupt"
            Move-Item -Path $ConfigFile $CorruptConfigFile -Force
            $Message = "Configuration file '$ConfigFile' is corrupt and was renamed to '$CorruptConfigFile'."
            Write-Message -Level Warn $Message
            $ConfigFromFile = Get-DefaultConfig
            $Variables.FreshConfigText = "$Message`n`nUse the configuration editor ('http://127.0.0.1:$($ConfigFromFile.APIPort)') to change your settings and apply the configuration.`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!"
        }
        Else { 
            $Variables.ConfigFileTimestamp = (Get-Item -Path $Variables.ConfigFile).LastWriteTime
            $Variables.AllCommandLineParameters.psBase.Keys | Sort-Object | ForEach-Object { 
                If ($_ -in $ConfigFromFile.psBase.Keys) { 
                    # Upper / lower case conversion of variable keys (Web GUI is case sensitive)
                    $Value = $ConfigFromFile.$_
                    $ConfigFromFile.Remove($_)
                    If ($Variables.AllCommandLineParameters.$_ -is [Switch]) { 
                        $ConfigFromFile.$_ = [Boolean]$Value
                    }
                    ElseIf ($Variables.AllCommandLineParameters.$_ -is [Array]) { 
                        $ConfigFromFile.$_ = [Array]$Value
                    }
                    Else { 
                        $ConfigFromFile.$_ = $Value -as $Variables.AllCommandLineParameters.$_.GetType().Name
                    }
                }
                Else { 
                    # Config parameter not in config file - use hardcoded value
                    $Value = $Variables.AllCommandLineParameters.$_
                    If ($Value -is [Switch]) { $Value = [Boolean]$Value }
                    $ConfigFromFile.$_ = $Value
                }
            }
        }
        If ($ConfigFromFile.EarningsAdjustmentFactor -le 0 -or $ConfigFromFile.EarningsAdjustmentFactor -gt 10) { 
            $ConfigFromFile.EarningsAdjustmentFactor = 1
            Write-Message -Level Warn "Default Earnings adjustment factor (value: $($ConfigFromFile.EarningsAdjustmentFactor)) is not within supported range (0 - 10); using default value $($ConfigFromFile.EarningsAdjustmentFactor)."
        }
    }
    Else { 
        Write-Message -Level Warn "No valid configuration file '$ConfigFile' found."
        $Variables.FreshConfigText = "This is the first time you have started $($Variables.Branding.ProductLabel).`n`nUse the configuration editor to change your settings and apply the configuration.`n`n`Start making money by clicking 'Start mining'.`n`nHappy Mining!"
        $ConfigFromFile = Get-DefaultConfig
    }

    # Build custom pools configuration, create case insensitive hashtable (https://stackoverflow.com/questions/24054147/powershell-hash-tables-double-key-error-a-and-a)
    If ($Variables.PoolsConfigFile -and (Test-Path -Path $Variables.PoolsConfigFile -PathType Leaf)) { 
        Try { 
            $Variables.PoolsConfigData = Get-Content $Variables.PoolsConfigFile | ConvertFrom-Json -AsHashTable | Get-SortedObject
            $Variables.PoolsConfigFileTimestamp = (Get-Item -Path $Variables.PoolsConfigFile).LastWriteTime
        }
        Catch { 
            $Variables.PoolsConfigData = [Ordered]@{ }
            Write-Message -Level Warn "Pools configuration file '$($Variables.PoolsConfigFile)' is corrupt and will be ignored."
        }
    }

    $ConfigFromFile.PoolsConfig = Get-PoolsConfig

    # Must update existing thread safe variable. Reassignment breaks updates to instances in other threads
    $ConfigFromFile.psBase.Keys | ForEach-Object { $Global:Config.$_ = $ConfigFromFile.$_ }

    If (-not $Config.ShowConsole) { Hide-Console }

    $Variables.ShowAccuracy = $Config.ShowAccuracy
    $Variables.ShowAllMiners = $Config.ShowAllMiners
    $Variables.ShowEarning = $Config.ShowEarning
    $Variables.ShowEarningBias = $Config.ShowEarningBias
    $Variables.ShowMinerFee = $Config.ShowMinerFee
    $Variables.ShowPool = $Config.ShowPool
    $Variables.ShowPoolBalances = $Config.ShowPoolBalances
    $Variables.ShowPoolFee = $Config.ShowPoolFee
    $Variables.ShowPowerCost = $Config.ShowPowerCost
    $Variables.ShowPowerUsage = $Config.ShowPowerUsage
    $Variables.ShowProfit = $Config.ShowProfit
    $Variables.ShowProfitBias = $Config.ShowProfitBias
    $Variables.ShowCoinName = $Config.ShowCoinName
    $Variables.ShowCurrency = $Config.ShowCurrency
    $Variables.ShowUser = $Config.ShowUser
    $Variables.UIStyle = $Config.UIStyle
}

Function Update-ConfigFile { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    # Changed config items
    $Config.GetEnumerator().Name | Sort-Object | ForEach-Object { 
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
            "BalancesTrackerIgnorePool"  { $Config.BalancesTrackerExcludePools = $Config.$_; $Config.Remove($_) }
            "DeductRejectedShares" { $Config.SubtractBadShares = $Config.$_; $Config.Remove($_) }
            "Donate" { $Config.Donation = $Config.$_; $Config.Remove($_) }
            "EnableEarningsTrackerLog" { $Config.EnableBalancesLog = $Config.$_; $Config.Remove($_) }
            "EstimateCorrection" { $Config.Remove($_) }
            "Location" { $Config.Region = $Config.$_; $Config.Remove($_) }
            "IdlePowerUsageW" { $Config.PowerUsageIdleSystemW = $Config.$_; $Config.Remove($_) }
            "Currency" { 
                If (-not $Config.MainCurrency -or $Config.MainCurrency -eq $Config.Currency) { $Config.MainCurrency = $Config.$_ }
                $Config.Remove($_)
            }
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
            Default { If ($_ -notin @(@($Variables.AllCommandLineParameters.psBase.Keys) + @("CryptoCompareAPIKeyParam") + @("DryRun") + @("PoolsConfig"))) { $Config.Remove($_) } } # Remove unsupported config items
        }
    }

    # Change currency names, remove mBTC
    If ($Config.MainCurrency -is [Array]) { 
        $Config.MainCurrency = $Config.MainCurrency | Select-Object -First 1
        $Config.ExtraCurrencies = @($Config.MainCurrency | Select-Object -Skip 1 | Where-Object { $_ -ne "mBTC" } | Select-Object)
    }

    # Move [PayoutCurrency] wallet to wallets
    If ($PoolsConfig = Get-Content $Variables.PoolsConfigFile | ConvertFrom-Json) { 
        ($PoolsConfig | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
            If (-not $PoolsConfig.$_.Wallets -and $PoolsConfig.$_.Wallet) { 
                $PoolsConfig.$_ | Add-Member Wallets @{ "$($PoolsConfig.$_.PayoutCurrency)" = $PoolsConfig.$_.Wallet }
                $PoolsConfig.$_.PSObject.Members.Remove("Wallet")
            }
        }
        $PoolsConfig | ConvertTo-Json | Out-File -FilePath $Variables.PoolsConfigFile -Force -ErrorAction Ignore
    }

    # Rename MPH to MiningPoolHub
    $Config.PoolName = $Config.PoolName -replace 'MPH', 'MiningPoolHub'
    $Config.PoolName = $Config.PoolName -replace 'MPHCoins', 'MiningPoolHub'

    # *Coins pool no longer exists
    $OldPoolName = $Config.PoolName
    $Config.PoolName = $Config.PoolName -replace 'Coins$' -replace 'CoinsPlus$'
    If (Compare-Object @($OldPoolName | Select-Object) @($Config.PoolName | Select-Object)) { 
        Write-Message -Level Info "Pool configuration has changed ($($OldPoolName -join ', ') -> $($Config.PoolName -join ', ')). Please verify your configuration."
    }
    # Available regions have changed
    If (-not ($Config.Region -in (Get-Region $Config.Region -List))) { 
        $OldRegion = $Config.Region
        # Write message about new mining regions
        $Config.Region = Switch ($OldRegion) { 
            "Brazil"       { "USA West" }
            "Europe East"  { "Europe" }
            "Europe North" { "Europe" }
            "India"        { "Asia" }
            "US"           { "USA West" }
            Default        { "Europe" }
        }
        Write-Message -Level Warn "Available mining locations have changed ($OldRegion -> $($Config.Region)). Please verify your configuration."
    }
    # Extend MinDataSampleAlgoMultiplier
    If ($Config.MinDataSampleAlgoMultiplier.DynexSolve -eq 3) { $Config.MinDataSampleAlgoMultiplier.Remove("DynexSolve") }
    If ($null -eq $Config.MinDataSampleAlgoMultiplier.Ghostrider) { $Config.MinDataSampleAlgoMultiplier | Add-Member "GhostRider" 3 }
    If ($null -eq $Config.MinDataSampleAlgoMultiplier.Mike) { $Config.MinDataSampleAlgoMultiplier | Add-Member "Mike" 3 }
    # Remove AHashPool config data
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "AhashPool*" }
    Remove-Item -Path ".\Stats\AhashPool*.txt" -Force
    # Remove BlockMasters config data
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "BlockMasters*" }
    Remove-Item -Path ".\Stats\BlockMasters*.txt" -Force
    # Remove MiningPoolHubCoins config data
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "MiningPoolHubCoins" }
    Remove-Item -Path ".\Stats\MiningPoolHub_*.txt" -Force
    Get-ChildItem -Path ".\Stats\MiningPoolHubCoins_*.txt" | Rename-Item -NewName { $_.Name -replace '^MiningPoolHubCoins_', 'MiningPoolHub_' }
    # Remove BlockMasters config data
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "NLPool*" }
    Remove-Item -Path ".\Stats\NLPool*.txt" -Force
    # Remove TonPool config
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "TonPool" }
    # Remove TonWhales config
    $Config.PoolName = $Config.PoolName | Where-Object { $_ -notlike "TonWhales" }

    $Config.ConfigFileVersion = $Variables.Branding.Version.ToString()
    Write-Config -ConfigFile $ConfigFile -Config $Config
    Write-Message -Level Verbose "Updated configuration file '$($ConfigFile)' to version $($Variables.Branding.Version.ToString())."
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
        Get-ChildItem -Path "$($ConfigFile)_*.backup" -File | Sort-Object -Property LastWriteTime | Select-Object -SkipLast 10 | Remove-Item -Force -Recurse # Keep 10 backup copies
    }

    $Config.Remove("ConfigFile")
    $Config.Remove("PoolsConfig")
    "$Header$($Config | Get-SortedObject | ConvertTo-Json -Depth 10)" | Out-File -FilePath $ConfigFile -Force

    If ($Config.ShowConsole) { 
        If ($Variables.Summary) { Show-Console }
    } 
    Else { Hide-Console }

    $Variables.ShowAccuracy = $Config.ShowAccuracy
    $Variables.ShowAllMiners = $Config.ShowAllMiners
    $Variables.ShowEarning = $Config.ShowEarning
    $Variables.ShowEarningBias = $Config.ShowEarningBias
    $Variables.ShowMinerFee = $Config.ShowMinerFee
    $Variables.ShowPool = $Config.ShowPool
    $Variables.ShowPoolBalances = $Config.ShowPoolBalances
    $Variables.ShowPoolFee = $Config.ShowPoolFee
    $Variables.ShowPowerCost = $Config.ShowPowerCost
    $Variables.ShowPowerUsage = $Config.ShowPowerUsage
    $Variables.ShowProfit = $Config.ShowProfit
    $Variables.ShowProfitBias = $Config.ShowProfitBias
    $Variables.ShowCoinName = $Config.ShowCoinName
    $Variables.ShowCurrency = $Config.ShowCurrency
    $Variables.ShowUser = $Config.ShowUser
    $Variables.UIStyle = $Config.UIStyle
}

Function Edit-File { 
    # Opens file in notepad. Notepad will remain in foreground until closed.

    Param(
        [Parameter(Mandatory = $false)]
        [String]$FileName
    )

    $FileWriteTime = (Get-Item -Path $FileName).LastWriteTime
    If (-not $FileWriteTime) { 
        If ($FileName -eq $Variables.PoolsConfigFile -and (Test-Path -Path ".\Data\PoolsConfig-Template.json" -PathType Leaf)) { 
            Copy-Item ".\Data\PoolsConfig-Template.json" $FileName
        }
    }

    If (-not ($NotepadProcess = (Get-CimInstance CIM_Process | Where-Object CommandLine -Like "*\Notepad.exe* $($FileName)"))) { 
        $NotepadProcess = Start-Process -FilePath Notepad.exe -ArgumentList $FileName -PassThru
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
            Start-Sleep -Milliseconds 100
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
                Break
            }
            "Hashtable|OrderedDictionary|SyncHashtable" { 
                $SortedObject = [Ordered]@{ }
                $Object.GetEnumerator().Name | Sort-Object | ForEach-Object { 
                    If ($Object[$_] -is [Array]) { 
                        $SortedObject.Add($_, @(Get-SortedObject $Object[$_]))
                    }
                    Else { 
                        $SortedObject.Add($_, (Get-SortedObject $Object[$_]))
                    }
                }
                Break
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
        } | ConvertTo-Json | Out-File -FilePath $Path -Force
    }
}

Function Disable-Stat { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    $Path = "Stats\$Name.txt"
    If (-not $Stat) { $Stat = Set-Stat -Name $Name -Value 0 }
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
    } | ConvertTo-Json | Out-File -FilePath $Path -Force
}

Function Set-Stat { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Name, 
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $false)]
        [DateTime]$Updated = ([DateTime]::Now), 
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
            $FaultFactor = If ($Name -match '.+_Hashrate$') { 0.1 } Else { 0.2 }
            $ToleranceMin = $Stat.Week * (1 - $FaultFactor)
            $ToleranceMax = $Stat.Week * (1 + $FaultFactor)
        }
        Else { 
            $ToleranceMin = $ToleranceMax = $Value
        }

        If ($Value -lt $ToleranceMin -or $Value -gt $ToleranceMax) { $Stat.ToleranceExceeded ++ }
        Else { $Stat.ToleranceExceeded = [UInt16]0 }
        # Else { $Stat | Add-Member ToleranceExceeded ([UInt16]0) -Force }

        If ($Value -gt 0 -and $Stat.ToleranceExceeded -gt 0 -and $Stat.ToleranceExceeded -lt $ToleranceExceeded -and $Stat.Week -gt 0) { 
            If ($Name -match '.+_Hashrate$') { 
                Write-Message -Level Warn "Error saving hashrate for '$($Name -replace '_Hashrate$')'. $(($Value | ConvertTo-Hash) -replace '\s+', ' ') is outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) [Iteration $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            ElseIf ($Name -match '.+_PowerUsage') { 
                Write-Message -Level Warn "Error saving power usage for '$($Name -replace '_PowerUsage$')'. $($Value.ToString("N2"))W is outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) [Iteration $($Stats.($Stat.Name).ToleranceExceeded) of $ToleranceExceeded until enforced update]."
            }
            Return
        }
        Else { 
            If (-not $Stat.Disabled -and ($Value -eq 0 -or $Stat.ToleranceExceeded -ge $ToleranceExceeded -or $Stat.Week_Fluctuation -ge 1)) { 
                If ($Value -gt 0 -and $Stat.ToleranceExceeded -ge $ToleranceExceeded) { 
                    If ($Name -match '.+_Hashrate$') { 
                        Write-Message -Level Warn "Hashrate '$($Name -replace '_Hashrate$')' was forcefully updated. $(($Value | ConvertTo-Hash) -replace '\s+', ' ') was outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' '))$(If ($Stat.Week_Fluctuation -lt 1) { " for $($Stats.($Stat.Name).ToleranceExceeded) times in a row." })"
                    }
                    ElseIf ($Name -match '.+_PowerUsage$') { 
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

        $Global:Stats[$Name] = $Stat = [Hashtable]::Synchronized(
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
                Timer                 = [DateTime]$Timer
                ToleranceExceeded     = [UInt16]0
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
    } | ConvertTo-Json | Out-File -FilePath $Path -Force

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
        $Name = [String[]]((Get-ChildItem -Path "Stats" -File).BaseName)
        If ($Keys = [String[]]($Global:Stats.psBase.Keys)) { 
            Compare-Object $Name $Keys -PassThru | Where-Object SideIndicator -EQ "=>" | ForEach-Object { 
                # Remove stat if deleted on disk
                $Global:Stats.Remove($_)
            }
        }
        Remove-Variable Keys
    }

    $Name | Select-Object | ForEach-Object { 
        $Stat_Name = $_

        If ($Global:Stats[$Stat_Name] -isnot [Hashtable] -or -not $Global:Stats[$Stat_Name].IsSynchronized) { 
            # # Reduce number of errors
            If (-not (Test-Path -Path "Stats\$Stat_Name.txt" -PathType Leaf)) { 
                Return
            }

            Try { 
                $Stat = Get-Content "Stats\$Stat_Name.txt" -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                $Global:Stats[$Stat_Name] = [Hashtable]::Synchronized(
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

        Return $Global:Stats[$Stat_Name]
    }
}

Function Remove-Stat { 

    Param(
        [Parameter(Mandatory = $true)]
        [String[]]$Name
    )

    $Name | ForEach-Object { 
        Remove-Item -Path "Stats\$_.txt" -Force -Confirm:$false -ErrorAction Ignore
        $Global:Stats.Remove($_)
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
        Features = $Features.psBase.Keys.ForEach{ If ($Features.$_) { $_ } }
    }
}

Function Get-GPUArchitectureAMD { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Model,
        [Parameter(Mandatory = $false)]
        [String]$Architecture = ""
    )

    $Model = $Model -replace '[^A-Z0-9]'
    $Architecture = $Architecture -replace ':.+$' -replace '[^A-Za-z0-9]+'

    ForEach($GPUArchitecture in $Variables.GPUArchitectureDbAMD.PSObject.Properties) { 
        If ($Architecture -match $GPUArchitecture.Value) { 
            Return $GPUArchitecture.Name
        }
    }
    Return $Architecture
}

Function Get-GPUArchitectureNvidia { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Model,
        [Parameter(Mandatory = $false)]
        [String]$ComputeCapability = ""
    )

    $Model = $Model -replace '[^A-Z0-9]'
    $ComputeCapability = $ComputeCapability -replace '[^\d\.]'

    ForEach ($GPUArchitecture in $Variables.GPUArchitectureDbNvidia.PSObject.Properties) { 
        If ($ComputeCapability -in $GPUArchitecture.Value.Compute) { 
            Return $GPUArchitecture.Name
        }
    }

    ForEach ($GPUArchitecture in $GPUArchitectureDbNvidia.PSObject.Properties) { 
        If ($Model -match $GPUArchitecture.Value.Model) {
            Return $GPUArchitecture.Name
        }
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
                $Device.Model = (($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor) -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel' -replace '[^ A-Z0-9\.]' -replace ' \s+' -replace ' $'

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id ++
                $Vendor_Id.($Device.Vendor) ++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                If ($Device.Vendor -in $Variables."Supported$($Device.Type)DeviceVendors") { $Type_Id.($Device.Type) ++ }

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
                    $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID ++)"
                }
                Else { 
                    $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID ++)"
                }
                $Device.Model = (($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB" -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce|Radeon|Intel' -replace '[^ A-Z0-9\.]' -replace ' \s+' -replace ' $'

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id ++
                $Vendor_Id.($Device.Vendor) ++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                If ($Device.Vendor -in $Variables."Supported$($Device.Type)DeviceVendors") { $Type_Id.($Device.Type) ++ }

                # Add raw data
                $Device | Add-Member @{ 
                    CIM = $Device_CIM
                    # PNP = $Device_PNP
                    # Reg = $Device_Reg
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
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedCPUVendorID ++)"
                    }
                    Else { 
                        $Device.Name = "$($Device.Type)#$('{0:D2}' -f $UnsupportedGPUVendorID ++)"
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

                        $Id ++
                        $Vendor_Id.($Device.Vendor) ++
                        $Type_Vendor_Id.($Device.Type).($Device.Vendor) ++
                        $Type_Id.($Device.Type) ++
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

                    $Index ++
                    $Type_Index.($Device.Type) ++
                    $Vendor_Index.($Device.Vendor) ++
                    $Type_Vendor_Index.($Device.Type).($Device.Vendor) ++
                    $PlatformId_Index.($PlatformId) ++
                    $Type_PlatformId_Index.($Device.Type).($PlatformId) ++
                }

                $PlatformId ++
            }

            $Variables.Devices | Where-Object Model -ne "Remote Display Adapter 0GB" | Where-Object Vendor -ne "CitrixSystemsInc" | Where-Object Bus -Is [Int64] | Sort-Object -Property Bus | ForEach-Object { 
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

                $Slot ++
                $Type_Slot.($_.Type) ++
                $Vendor_Slot.($_.Vendor) ++
                $Type_Vendor_Slot.($_.Type).($_.Vendor) ++
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

    $Decimals = 1 + $DecimalsMax - [Math]::Floor([math]::Abs($Value)).ToString().Length
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

    For ($I = 0; $I -lt $Value.Count; $I ++) { 
        $Combination | Add-Member @{ [Math]::Pow(2, $I) = $Value[$I] }
    }

    $Combination_Keys = ($Combination | Get-Member -MemberType NoteProperty).Name

    For ($I = $SizeMin; $I -le $SizeMax; $I ++) { 
        $X = [Math]::Pow(2, $I) - 1

        While ($X -le [Math]::Pow(2, $Value.Count) - 1) { 
            [PSCustomObject]@{ 
                Combination = $Combination_Keys | Where-Object { $_ -band $X } | ForEach-Object { $Combination.$_ }
            }
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
        [String]$ArgumentList = "", 
        [Parameter(Mandatory = $false)]
        [String]$WorkingDirectory = "", 
        [Parameter(Mandatory = $false)]
        [String[]]$EnvBlock,
        [Parameter(Mandatory = $false)]
        [String]$CreationFlags = 0x00000010, # CREATE_NEW_CONSOLE
        [Parameter(Mandatory = $false)]
        [String]$WindowStyle = "minimized", 
        [Parameter(Mandatory = $false)]
        [String]$StartF = 0x00000081, # STARTF_USESHOWWINDOW, STARTF_FORCEOFFFEEDBACK
        [Parameter(Mandatory = $false)]
        [String]$JobName, 
        [Parameter(Mandatory = $false)]
        [String]$LogFile
    )

    # $Job = Start-ThreadJob -Name $JobName -StreamingHost $null -ArgumentList $BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $WindowStyle, $StartF, $PID { 
    $Job = Start-Job -Name $JobName -ArgumentList $BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $WindowStyle, $StartF, $PID { 
        Param($BinaryPath, $ArgumentList, $WorkingDirectory, $EnvBlock, $CreationFlags, $WindowStyle, $StartF, $ControllerProcessID)

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

        $ShowWindow = Switch ($WindowStyle) { 
            "hidden" { "0x0000" } # SW_HIDE
            "normal" { "0x0001" } # SW_SHOWNORMAL
            Default  { "0x0007" } # SW_SHOWMINNOACTIVE
        }

        # Set local environment
        $EnvBlock | Select-Object | ForEach-Object { Set-Item -Path "Env:$($_ -split '=' | Select-Object -Index 0)" "$($_ -split '=' | Select-Object -Index 1)" -Force }

        # StartupInfo Struct
        $StartupInfo = New-Object STARTUPINFO
        $StartupInfo.dwFlags = $StartF # StartupInfo.dwFlag
        $StartupInfo.wShowWindow = $ShowWindow # StartupInfo.ShowWindow
        $StartupInfo.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($StartupInfo) # Struct Size

        # SECURITY_ATTRIBUTES Struct (Process & Thread)
        $SecAttr = New-Object SECURITY_ATTRIBUTES
        $SecAttr.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($SecAttr)

        # CreateProcess --> lpCurrentDirectory
        If (-not $WorkingDirectory) { $WorkingDirectory = [IntPtr]::Zero }

        # ProcessInfo Struct
        $ProcessInfo = New-Object PROCESS_INFORMATION

        # Call CreateProcess
        [Void][Kernel32]::CreateProcess($BinaryPath, "$BinaryPath $ArgumentList", [ref]$SecAttr, [ref]$SecAttr, $false, $CreationFlags, [IntPtr]::Zero, $WorkingDirectory, [ref]$StartupInfo, [ref]$ProcessInfo)
        $Process = Get-Process -Id $ProcessInfo.dwProcessId
        If ($null -eq $Process) { 
            [PSCustomObject]@{ ProcessId = $null }
            Return 
        }

        $ControllerProcess.Handle | Out-Null
        $Process.Handle | Out-Null

        [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle }

        Do { 
            If ($ControllerProcess.WaitForExit(200)) { 
                $Process.CloseMainWindow() | Out-Null
            }
        } While ($Process.HasExited -eq $false)
    }

    Return $Job
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
    Invoke-WebRequest -Uri $Uri -OutFile $FileName -TimeoutSec 5

    If (".msi", ".exe" -contains ([IO.FileInfo](Split-Path $Uri -Leaf)).Extension) { 
        Start-Process $FileName "-qb" -Wait | Out-Null
    }
    Else { 
        $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
        $Path_New = Split-Path $Path

        If (Test-Path -Path $Path_Old -PathType Container) { Remove-Item $Path_Old -Recurse -Force }
        Start-Process ".\Utils\7z" "x `"$([IO.Path]::GetFullPath($FileName))`" -o`"$([IO.Path]::GetFullPath($Path_Old))`" -y -spe" -Wait -WindowStyle Hidden | Out-Null

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

    If (-not (Test-Path -Path Variable:Global:Algorithms -ErrorAction Ignore)) { 
        $Global:Algorithms = Get-Content ".\Data\Algorithms.json" | ConvertFrom-Json -ErrorAction Stop
    }

    $Algorithm = $Algorithm -replace '[^a-z0-9]+'

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

    If (-not (Test-Path -Path Variable:Global:Regions -ErrorAction Ignore)) { 
        $Global:Regions = @{ }
        (Get-Content -Path ".\Data\Regions.json" -ErrorAction Stop | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Global:Regions[$_.Name] = @($_.Value) }
    }

    If ($List) { Return $Global:Regions[$Region] }
    ElseIf ($Global:Regions[$Region]) { Return $($Global:Regions[$Region] | Select-Object -First 1) }
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

    If (-not ($Variables.CoinNames[$Currency] -and $Variables.CurrencyAlgorithm[$Currency])) { 
        # Get mutex. Mutexes are shared across all threads and processes. 
        # This lets us ensure only one thread is trying to write to the file at a time. 
        $Mutex = New-Object System.Threading.Mutex($false, "$($PWD -replace '[^A-Z0-9]')_Add-CoinName")

        # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the coin names file and release mutex
        If ($Mutex.WaitOne(1000)) { 
            If (-not $Variables.CurrencyAlgorithm[$Currency]) { 
                $Variables.CurrencyAlgorithm[$Currency] = Get-Algorithm $Algorithm
                $Variables.CurrencyAlgorithm | Get-SortedObject | ConvertTo-Json | Out-File -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction Ignore -Force
            }
            If (-not $Variables.CoinNames[$Currency]) { 
                If ($CoinName = ((Get-Culture).TextInfo.ToTitleCase($CoinName.Trim().ToLower()) -replace '[^A-Z0-9\$\.]' -replace 'coin$', 'Coin' -replace 'bitcoin$', 'Bitcoin')) { 
                    $Variables.CoinNames[$Currency] = $CoinName
                    $Variables.CoinNames | Get-SortedObject | ConvertTo-Json | Out-File -Path ".\Data\CoinNames.json" -ErrorAction Ignore -Force
                }
            }
            [Void]$Mutex.ReleaseMutex()
        }
    }
}

Function Add-CurrcencyAlgorithm { 

    Param(
        [Parameter(Mandatory = $true)]
        [String]$Algorithm,
        [Parameter(Mandatory = $true)]
        [String]$Currency
    )

    If (-not ($Variables.CoinNames[$Currency] -and $Variables.CurrencyAlgorithm[$Currency])) { 
        # Get mutex. Mutexes are shared across all threads and processes. 
        # This lets us ensure only one thread is trying to write to the file at a time. 
        $Mutex = New-Object System.Threading.Mutex($false, "$($PWD -replace '[^A-Z0-9]')_Add-CoinName")

        # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, update the coin names file and release mutex
        If ($Mutex.WaitOne(1000)) { 
            If (-not $Variables.CurrencyAlgorithm[$Currency]) { 
                $Variables.CurrencyAlgorithm[$Currency] = Get-Algorithm $Algorithm
                $Variables.CurrencyAlgorithm | Get-SortedObject | ConvertTo-Json | Out-File -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction Ignore -Force
            }
        }
        [Void]$Mutex.ReleaseMutex()
    }
}

Function Get-AlgorithmFromCurrency { 

    Param(
        [Parameter(Mandatory = $false)]
        [String]$Currency
    )

    If ($Currency -and $Currency -ne "*") { 
        If ($Variables.CurrencyAlgorithm[$Currency]) { 
            Return $Variables.CurrencyAlgorithm[$Currency]
        }

        $Variables.CurrencyAlgorithm = [Ordered]@{ } # as case insensitive hash table
        (Get-Content -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction Stop | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Variables.CurrencyAlgorithm[$_.Name] = $_.Value }
        If ($Variables.CurrencyAlgorithm[$Currency]) { 
            Return $Variables.CurrencyAlgorithm[$Currency]
        }
    }
    Return $null
}

Function Get-CurrencyFromAlgorithm { 

    Param(
        [Parameter(Mandatory = $false)]
        [String]$Algorithm
    )

    If ($Algorithm) { 
        If ($Currencies = @($Variables.CurrencyAlgorithm.psBase.Keys | Where-Object { $Variables.CurrencyAlgorithm[$_] -eq $Algorithm } )) { 
            Return $Currencies
        }

        $Variables.CurrencyAlgorithm = [Ordered]@{ } # as case insensitive hash table
        (Get-Content -Path ".\Data\CurrencyAlgorithm.json" -ErrorAction Stop | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Variables.CurrencyAlgorithm[$_.Name] = $_.Value }
        If ($Currencies = @($Variables.CurrencyAlgorithm.psBase.Keys | Where-Object { $Variables.CurrencyAlgorithm[$_] -eq $Algorithm } )) { 
            Return $Currencies
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
        If ($Variables.EquihashCoinPers[$Currency]) { 
            Return "$($Command)$($Variables.EquihashCoinPers[$Currency])"
        }

        $Variables.EquihashCoinPers = [Ordered]@{ } # as case insensitive hash table
        (Get-Content -Path ".\Data\EquihashCoinPers.json" -ErrorAction Stop | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Variables.EquihashCoinPers[$_.Name] = $_.Value }

        If ($Variables.EquihashCoinPers[$Currency]) { 
            Return "$($Command)$($Variables.EquihashCoinPers[$Currency])"
        }
    }
    Return $DefaultCommand
}


Function Get-PoolBaseName { 

    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$PoolNames
    )

    Return ($PoolNames -replace '24hr$|Coins$|Plus$')
}

Function Get-NMVersion { 
    # Updater always logs all messages
    $ConfigLogToFile = $Config.LogToFile
    $ConfigLogToScreen = $Config.LogToScreen
    $Config.LogToFile = $Config.LogToScreen = @("Info", "Warn", "Error", "Verbose", "Debug")

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
    $Config.LogToFile = $ConfigLogToFile
    $Config.LogToScreen = $ConfigLogToScreen
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

    Set-Location $Variables.MainPath
    If (-not (Test-Path -Path ".\AutoUpdate" -PathType Container)) { New-Item -Path . -Name "AutoUpdate" -ItemType Directory | Out-Null }
    If (-not (Test-Path -Path ".\Logs" -PathType Container)) { New-Item -Path . -Name "Logs" -ItemType Directory | Out-Null }

    $UpdateScriptURL = "https://github.com/Minerx117/miners/releases/download/AutoUpdate/Autoupdate.ps1"
    $UpdateScript = ".\AutoUpdate\AutoUpdate.ps1"
    $UpdateLog = ".\Logs\AutoUpdateLog_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").txt"

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
            [Void](Invoke-CreateProcess -BinaryPath $Variables.LogViewerExe -ArgumentList $Variables.LogViewerConfig -WorkingDirectory (Split-Path $Variables.LogViewerExe) -WindowStyle "Normal" -EnvBlock $null -JobName "Snaketail" -LogFile $null)
        }
    }
}

Function Get-ObsoleteMinerStats { 

    [Void](Get-Stat)

    $MinerNames = @(Get-ChildItem ".\Miners\*.ps1").BaseName

    Return @($Global:Stats.psBase.Keys | Where-Object { $_ -match '_Hashrate$|_PowerUsage$' } | Where-Object { (($_ -split '-' | Select-Object -First 2) -join "-") -notin $MinerNames})
}

Function Test-Prime { 

    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Number
    )

    For ([Int64]$i = 2; $i -lt [Int64][Math]::Pow($Number, 0.5); $i ++) { If ($Number % $i -eq 0) { Return $false } }

    Return $true
}

Function Update-DAGdata { 
    # Update on script start, once every 24hrs or if unable to get data from all sources
    If (-not $Variables.DAGdata) { $Variables.DAGdata = [Ordered]@{ } }
    If (-not $Variables.DAGdata["Algorithm"]) { $Variables.DAGdata["Algorithm"] = [Ordered]@{ } }
    If (-not $Variables.DAGdata["Currency"]) { $Variables.DAGdata["Currency"] = [Ordered]@{ } }
    If (-not $Variables.DAGdata["Updated"]) { $Variables.DAGdata["Updated"] = [Ordered]@{ } }

    $Url = "https://whattomine.com/coins.json"
    If ($Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt ([DateTime]::Now).ToUniversalTime().AddDays(-1)) { 
        # Get block data for from whattomine.com
        Try { 
            $DAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 5

            If ($DAGdataResponse.coins.PSObject.Properties.Name) { 
                $DAGdataResponse.coins.PSObject.Properties.Name | Where-Object { $DAGdataResponse.coins.$_.tag -ne "NICEHASH" } | ForEach-Object { 
                    $Currency = $DAGdataResponse.coins.$_.tag
                    Add-CurrcencyAlgorithm -Algorithm $DAGdataResponse.coins.$_.algorithm -Currency $Currency
                    If (-not $Variables.CoinNames[$Currency]) { [Void](Add-CoinName -Algorithm (Get-Algorithm $DAGdataResponse.coins.$_.algorithm) -Currency $Currency -CoinName $_) }
                    If ((Get-Algorithm $DAGdataResponse.coins.$_.algorithm) -match $Variables.RegexAlgoHasDAG) { 
                        If ($DAGdataResponse.coins.$_.last_block -ge $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                            $DAGdata = Get-DAGdata -BlockHeight $DAGdataResponse.coins.$_.last_block -Currency $Currency -EpochReserve 2
                            If ($DAGdata.Algorithm -match $Variables.RegexAlgoHasDAG) { 
                                $DAGdata.Date = ([DateTime]::Now).ToUniversalTime()
                                $DAGdata.Url = $Url
                                $Variables.DAGdata.Currency[$Currency] = $DAGdata
                            }
                        }
                    }
                }
                $Variables.DAGdata.Updated.$Url = ([DateTime]::Now).ToUniversalTime()
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

    # Faster shutdown
    If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

    $Url = "https://minerstat.com/dag-size-calculator"
    If ($Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt ([DateTime]::Now).ToUniversalTime().AddDays(-1)) { 
        # Get block data from Minerstat
        Try { 
            $DAGdataResponse = Invoke-WebRequest -Uri $Url -TimeoutSec 5 # PWSH 6+ no longer supports basic parsing -> parse text
            If ($DAGdataResponse.statuscode -eq 200) {
                $DAGdataResponse.Content -split '\n' -replace '"', "'" | Where-Object { $_ -like "<div class='block' title='Current block height of *" } | ForEach-Object { 
                    $Currency = $_ -replace "^<div class='block' title='Current block height of " -replace "'>.*$"
                    $BlockHeight = [Int]($_ -replace "^<div class='block' title='Current block height of $Currency'>" -replace "</div>")
                    If ($BlockHeight -ge $Variables.DAGdata.Currency.$Currency.BlockHeight -and $Currency) { 
                        $DAGdata = Get-DAGdata -BlockHeight $BlockHeight -Currency $Currency -EpochReserve 2
                        If ($DAGdata.Algorithm -match $Variables.RegexAlgoHasDAG) { 
                            $DAGdata.Date = ([DateTime]::Now).ToUniversalTime()
                            $DAGdata.Url = $Url
                            $Variables.DAGdata.Currency[$Currency] = $DAGdata
                        }
                    }
                }
                $Variables.DAGdata.Updated.$Url = ([DateTime]::Now).ToUniversalTime()
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

    # Faster shutdown
    If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

    $Url = "https://prohashing.com/api/v1/currencies"
    If ($Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt ([DateTime]::Now).ToUniversalTime().AddDays(-1)) { 
        # Get block data from ProHashing
        Try { 
            $DAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 5

            If ($DAGdataResponse.code -eq 200) { 
                $DAGdataResponse.data.PSObject.Properties.Name | Where-Object { $DAGdataResponse.data.$_.enabled -and $DAGdataResponse.data.$_.height -and ((Get-Algorithm $DAGdataResponse.data.$_.algo) -in @("Autolykos2", "EtcHash", "Ethash", "KawPow", "Octopus", "UbqHash") -or $_ -in @($Variables.DAGdata.Currency.psBase.Keys))} | ForEach-Object { 
                    If ($DAGdataResponse.data.$_.height -gt $Variables.DAGdata.Currency.$_.BlockHeight) { 
                        $DAGdata = Get-DAGdata -BlockHeight $DAGdataResponse.data.$_.height -Currency $_ -EpochReserve 2
                        If ($DAGdata.Algorithm -match $Variables.RegexAlgoHasDAG) { 
                            $DAGdata.Date = ([DateTime]::Now).ToUniversalTime()
                            $DAGdata.Url = $Url
                            $Variables.DAGdata.Currency[$_] = $DAGdata
                        }
                    }
                }
                $Variables.DAGdata.Updated.$Url = ([DateTime]::Now).ToUniversalTime()
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

    # Faster shutdown
    If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace.MiningStatus -eq "Idle") { Continue }

    If ("ZergPool" -notin @(Get-PoolBaseName $Variables.PoolName)) { 
        # ZergPool also supplies Evr DAG data
        $Url = "https://evr.cryptoscope.io/api/getblockcount"
        If (-not $Variables.DAGdata.Currency.EVR.BlockHeight -or $Variables.DAGdata.Updated.$Url -lt $Variables.ScriptStartTime -or $Variables.DAGdata.Updated.$Url -lt ([DateTime]::Now).ToUniversalTime().AddDays(-1)) { 
            # Get block data from EVR block explorer
            Try { 
                $DAGdataResponse = Invoke-RestMethod -Uri $Url -TimeoutSec 5

                If ($DAGdataResponse.blockcount -gt $Variables.DAGdata.Currency.EVR.BlockHeight) { 
                    $DAGdata = Get-DAGdata -BlockHeight $DAGdataResponse.blockcount -Currency "EVR" -EpochReserve 2
                    If ($DAGdata.Algorithm -match $Variables.RegexAlgoHasDAG) { 
                        $DAGdata.Date = ([DateTime]::Now).ToUniversalTime()
                        $DAGdata.Url = $Url
                        $Variables.DAGdata.Currency[$Currency] = $DAGdata
                        $Variables.DAGdata.Updated.$Url = ([DateTime]::Now).ToUniversalTime()
                        Write-Message -Level Info "Loaded DAG data from '$Url'."
                    }
                }
                Else { 
                    Write-Message -Level Warn "Failed to load DAG data from '$Url'."
                }
            }
            Catch { 
                Write-Message -Level Warn "Failed to load DAG data from '$Url'."
            }
        }
    }

    If ($Variables.DAGdata.Updated.Values -gt $Variables.Timer) { 
        #At least one DAG was updated, get maximum DAG size per algorithm
        $DAGdataKeys = @($Variables.DAGdata.Currency.psBase.Keys) # Store as array to avoid error 'An error occurred while enumerating through a collection: Collection was modified; enumeration operation may not execute..'

        ForEach ($Algorithm in @($DAGdataKeys | ForEach-Object { $Variables.DAGdata.Currency.$_.Algorithm } | Select-Object -Unique)) { 
            $Variables.DAGdata.Algorithm.$Algorithm = @{ 
                BlockHeight = [Int](($Variables.DAGdata.Currency | ForEach-Object { $_.psBase.Values | Where-Object Algorithm -eq $Algorithm }).Blockheight | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
                DAGsize     = [Int64](($Variables.DAGdata.Currency | ForEach-Object { $_.psBase.Values | Where-Object Algorithm -eq $Algorithm }).DAGsize | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
                Epoch       = [Int](($Variables.DAGdata.Currency | ForEach-Object { $_.psBase.Values | Where-Object Algorithm -eq $Algorithm }).Epoch | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
            }
            $Variables.DAGdata.Algorithm.$Algorithm | Add-Member CoinName ($DAGdataKeys | Where-Object { $Variables.DAGdata.Currency.$_.DAGsize -eq $Variables.DAGdata.Algorithm.$Algorithm.DAGsize -and $Variables.DAGdata.Currency.$_.Algorithm -eq $Algorithm }) -Force
        }

        # SCC firo variant
        If ($Variables.DAGdata.Algorithm["FiroPow"]) { 
            $Variables.DAGdata.Algorithm["FiroPowSCC"] = $Variables.DAGdata.Algorithm.FiroPow.PSObject.Copy()
        }
        # SCC firo variant
        If ($Variables.DAGdata.Currency["FIRO"]) { 
            $Variables.DAGdata.Currency["SCC"] = $Variables.DAGdata.Currency["FIRO"].PSObject.Copy()
            $Variables.DAGdata.Currency["SCC"].Algorithm = "FiroPowSCC"
            $Variables.DAGdata.Currency["SCC"].CoinName = "StakeCubeCoin"
        }
        Remove-Variable Algorithm

        # Add default '*' (equal to highest)
        $Variables.DAGdata.Currency."*" = @{ 
            BlockHeight = [Int]($DAGdataKeys | ForEach-Object { $Variables.DAGdata.Currency.$_.BlockHeight } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
            CoinName    = "*"
            DAGsize     = [Int64]($DAGdataKeys | ForEach-Object { $Variables.DAGdata.Currency.$_.DAGsize } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
            Epoch       = [Int]($DAGdataKeys | ForEach-Object { $Variables.DAGdata.Currency.$_.Epoch } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum)
        }

        $Variables.DAGdata = $Variables.DAGdata | Get-SortedObject
        $Variables.DAGdata | ConvertTo-Json | Out-File -FilePath ".\Data\DAGdata.json" -Force
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
            Break
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
            Break
        }
        "EVR" { 
            $Dataset_Bytes_Init = 3 * [Math]::Pow(2, 30) # 3GB
            $Dataset_Bytes_Growth = [Math]::Pow(2, 23) # 8MB
            $Mix_Bytes = 128
            $Size = ($Dataset_Bytes_Init + $Dataset_Bytes_Growth * $Epoch) - $Mix_Bytes
            While (-not (Test-Prime ($Size / $Mix_Bytes))) { 
                $Size -= 2 * $Mix_Bytes
            }
            Break
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
        Default { Return 30000 }
    }
}

Function Get-DAGdata { 

    Param(
        [Parameter(Mandatory = $false)]
        [Double]$Blockheight = (([DateTime]::Now) - [DateTime]"07/31/2015").Days * 6400,
        [Parameter(Mandatory = $false)]
        [String]$Currency = "ETH",
        [Parameter(Mandatory = $false)]
        [Int16]$EpochReserve = 0
    )

    $Epoch = (Get-Epoch -BlockHeight $BlockHeight -Currency $Currency) + $EpochReserve

    Return [Ordered]@{ 
        Algorithm   = Get-AlgorithmFromCurrency $Currency
        BlockHeight = [Int]$BlockHeight
        CoinName    = [String]$Variables.CoinNames[$Currency]
        DAGsize     = Get-DAGSize -Epoch $Epoch -Currency $Currency
        Epoch       = $Epoch
    }
}

Function Out-DataTable { 
    # based on http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx

    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$InputObject
    )

    Begin { 
        $DataTable = New-Object Data.DataTable
        $First = $true
    }
    Process { 
        ForEach ($Object in $InputObject) { 
            $DataRow = $DataTable.NewRow()
            ForEach ($Property in $Object.PSObject.Properties) { 
                If ($First) { 
                    $Col = New-Object Data.DataColumn
                    $Col.ColumnName = $Property.Name.ToString()
                    $DataTable.Columns.Add($Col)
                }
                $DataRow.Item($Property.Name) = $Property.Value
            }
            $DataTable.Rows.Add($DataRow)
            $First = $false
        }
    }
    End { 
        Return @(, $DataTable)
    }
}

Function Get-Median { 

    param (
      [Parameter(Mandatory = $true)]
      [Double[]]$Numbers
    )

    $Numbers = $Numbers | Sort-Object
    $Length = $Numbers.Length

    If ($Length % 2 -eq 0) { 
        # Even number of elements, so the median is the average of the two middle elements.
        Return (($Numbers[$Length / 2] + $Numbers[$Length / 2 - 1]) / 2)
    }
    Else { 
        # Odd number of elements, so the median is the middle element.
        Return $Numbers[$Length / 2]
    }
}

Function Show-Console {
    # Based on https://www.reddit.com/r/PowerShell/comments/a0jj6m/startprocess_hidden/
    If ($ConsolePtr = [Console.Window]::GetConsoleWindow()) { 

        # Hide = 0,
        # ShowNormal = 1,
        # ShowMinimized = 2,
        # ShowMaximized = 3,
        # Maximize = 3,
        # ShowNormalNoActivate = 4,
        # Show = 5,
        # Minimize = 6,
        # ShowMinNoActivate = 7,
        # ShowNoActivate = 8,
        # Restore = 9,
        # ShowDefault = 10,
        # ForceMinimized = 11

        [Console.Window]::ShowWindow($ConsolePtr, 9)
    }
}

Function Hide-Console {
    # Based on https://www.reddit.com/r/PowerShell/comments/a0jj6m/startprocess_hidden/
    If ($ConsolePtr = [Console.Window]::GetConsoleWindow()) { 
        #0 hide
        [Console.Window]::ShowWindow($ConsolePtr, 0)
    }
}

Function Get-MemoryUsage { 

    $MemUsageByte = [System.GC]::GetTotalMemory("forcefullcollection")
    $MemUsageMB = $MemUsageByte / 1MB
    $DiffBytes = $MemUsageByte - $Script:LastMemoryUsageByte
    $DiffText = ""
    $Sign = ""

    If ( $Script:LastMemoryUsageByte -ne 0 ) { 
        If ($DiffBytes -ge 0) {
            $Sign = "+"
        }
        $DiffText = ", $Sign$DiffBytes"
    }

    # Save last value in script global variable
    $Script:LastMemoryUsageByte = $MemUsageByte

    Return ("Memory usage {0:n1} MB ({1:n0} Bytes{2})" -f $MemUsageMB, $MemUsageByte, $Difftext)
}