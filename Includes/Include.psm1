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

Function Get-NMVersion { 
    # Check if new version is available
    Write-Message "Checking version..."
    Try { 
        $Version = Invoke-WebRequest "https://nemosminer.com/data/version.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
    }
    Catch { $Version = Get-Content ".\Config\version.json" | ConvertFrom-Json }
    If ($Version -ne $null) { $Version | ConvertTo-Json | Out-File ".\Config\version.json" }
    If ($Version.Product -eq $Variables.CurrentProduct -and [Version]$Version.Version -gt $Variables.CurrentVersion -and $Version.Update) { 
        Write-Message "Version $($Version.Version) available. (You are running $($Variables.CurrentVersion))"
        # If ([Version](Get-NVIDIADriverVersion) -ge [Version]$Version.MinNVIDIADriverVersion){ 
        $LabelNotifications.ForeColor = [System.Drawing.Color]::Green
        $LabelNotifications.Lines += "Version $([Version]$Version.Version) available"
        $LabelNotifications.Lines += $Version.Message
        If ($Config.Autoupdate -and ! $Config.ManualConfig) { Initialize-Autoupdate }
        # } Else { 
        # Write-Message "Version $($Version.Version available. Please update NVIDIA driver. Will not Autoupdate"
        # $LabelNotifications.ForeColor = "Red"
        # $LabelNotifications.Lines += "Driver update required. Version $([Version]$Version.Version) available"
        # }
    }
}

Function Get-HashRate { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,
        [Parameter(Mandatory = $true)]
        [String]$Algorithm,
        [Parameter(Mandatory = $false)]
        [Boolean]$Safe = $Miner.New
    )

    $HashRates_Devices = @($Data | Where-Object Device | Select-Object -ExpandProperty Device -Unique)
    If (-not $HashRates_Devices) { $HashRates_Devices = @("Device") }

    $HashRates_Counts = @{ }
    $HashRates_Averages = @{ }
    $HashRates_Variances = @{ }

    $Hashrates_Samples = @($Data | Where-Object { $_.HashRate.$Algorithm } | Sort-Object { $_.HashRate.$Algorithm }) #Do not use 0 valued samples

    #During benchmarking strip some of the lowest and highest sample values
    If ($Safe) { 
        If ($Miner.IntervalMultiplier -le 1) { $SkipSamples = [math]::Round($HashRates_Samples.Count * 0.1) }
        Else { $SkipSamples = [math]::Round($HashRates_Samples.Count * 0.2) }
    }
    Else { $SkipSamples = 0 }

    $Hashrates_Samples | Select-Object -Skip $SkipSamples | Select-Object -SkipLast $SkipSamples | ForEach-Object { 
        $Data_Devices = $_.Device
        If (-not $Data_Devices) { $Data_Devices = $HashRates_Devices }

        $Data_HashRates = [Double]($_.HashRate.$Algorithm)

        $Data_Devices | ForEach-Object { $HashRates_Counts.$_++ }
        $Data_Devices | ForEach-Object { $HashRates_Averages.$_ += @(($Data_HashRates | Measure-Object -Sum | Select-Object -ExpandProperty Sum) / $Data_Devices.Count) }
        $HashRates_Variances."$($Data_Devices | ConvertTo-Json)" += @($Data_HashRates | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
    }

    $HashRates_Count = $HashRates_Counts.Values | ForEach-Object { $_ } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
    $HashRates_Average = ($HashRates_Averages.Values | ForEach-Object { $_ } | Measure-Object -Average | Select-Object -ExpandProperty Average) * $HashRates_Averages.Keys.Count
    $HashRates_Variance = $HashRates_Variances.Keys | ForEach-Object { $_ } | ForEach-Object { $HashRates_Variances.$_ | Measure-Object -Average -Minimum -Maximum } | ForEach-Object { If ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

    If ($Safe) { 
        If ($HashRates_Count -lt 3 -or $HashRates_Variance -gt 0.05) { 
            Return 0
        }
        Else { 
            Return $HashRates_Average * (1 + ($HashRates_Variance / 2))
        }
    }
    Else { 
        Return $HashRates_Average
    }
}

Function Get-PowerUsage { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Data,
        [Parameter(Mandatory = $false)]
        [Boolean]$Safe = $Miner.New
    )

    $PowerUsages_Devices = @($Data | Where-Object Device | Select-Object -ExpandProperty Device -Unique)
    If (-not $PowerUsages_Devices) { $PowerUsages_Devices = @("Device") }

    $PowerUsages_Counts = @{ }
    $PowerUsages_Averages = @{ }
    $PowerUsages_Variances = @{ }

    $PowerUsages_Samples = @($Data | Where-Object PowerUsage) #Do not use 0 valued samples

    #During power measuring strip some of the lowest and highest sample values
    If ($Safe) { 
        If ($Miner.IntervalMultiplier -le 1) { $SkipSamples = [math]::Round($PowerUsages_Samples.Count * 0.1) }
        Else { $SkipSamples = [math]::Round($PowerUsages_Samples.Count * 0.2) }
    }
    Else { $SkipSamples = 0 }

    $PowerUsages_Samples | Sort-Object PowerUsage | Select-Object -Skip $SkipSamples | Select-Object -SkipLast $SkipSamples | ForEach-Object { 
        $Data_Devices = $_.Device
        If (-not $Data_Devices) { $Data_Devices = $PowerUsages_Devices }

        $Data_PowerUsages = $_.PowerUsage

        $Data_Devices | ForEach-Object { $PowerUsages_Counts.$_++ }
        $Data_Devices | ForEach-Object { $PowerUsages_Averages.$_ += @(($Data_PowerUsages | Measure-Object -Sum | Select-Object -ExpandProperty Sum) / $Data_Devices.Count) }
        $PowerUsages_Variances."$($Data_Devices | ConvertTo-Json)" += @($Data_PowerUsages | Measure-Object -Sum | Select-Object -ExpandProperty Sum)
    }

    $PowerUsages_Count = $PowerUsages_Counts.Values | ForEach-Object { $_ } | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
    $PowerUsages_Average = ($PowerUsages_Averages.Values | ForEach-Object { $_ } | Measure-Object -Average | Select-Object -ExpandProperty Average) * $PowerUsages_Averages.Keys.Count
    $PowerUsages_Variance = $PowerUsages_Variances.Keys | ForEach-Object { $_ } | ForEach-Object { $PowerUsages_Variances.$_ | Measure-Object -Average -Minimum -Maximum } | ForEach-Object { if ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

    If ($Safe) { 
        If ($PowerUsages_Count -lt 3 -or $PowerUsages_Variance -gt 0.1) { 
            Return 0
        }
        Else { 
            Return $PowerUsages_Average * (1 + ($PowerUsages_Variance / 2))
        }
    }
    Else { 
        Return $PowerUsages_Average
    }
}

Function Start-MinerDataReader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Miner,
        [Parameter(Mandatory = $false)]
        [Boolean]$ReadPowerUsage = $false,
        [Parameter(Mandatory = $false)]
        [Int]$Interval = 2 #Seconds
    )

    $Parameters = @{ 
        Miner          = $Miner
        ReadPowerUsage = $ReadPowerUsage
        Interval       = $Interval
    }

    $Miner | Add-Member -Force @{ 
        DataReaderJob = Start-Job -InitializationScript ([scriptblock]::Create("Set-Location('$(Get-Location)')")) -ArgumentList $Parameters -ScriptBlock { 
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true)]
                [Hashtable]$Parameters
            )

            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

            $Parameters.Keys | ForEach-Object { Set-Variable $_ $Parameters.$_ }

            Try { 
                While ($Miner) { 
                    Start-Sleep -Seconds $Interval
                    Get-MinerData -Miner $Miner -ReadPowerUsage $ReadPowerUsage
                }
            }
            Catch { }

            Exit
        }
    }
}

Function Get-CommandLineParameters { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Arguments
    )

    If ($Arguments -match "^{.+}$") { 
        Return ($Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue).Commands
    }
    Else { 
        Return $Arguments
    }
}

Function Start-ChildJobs { 
    # Starts Brains if necessary
    $Config.PoolName | ForEach-Object { 
        If ($_ -notin $Variables.BrainJobs.PoolName) { 
            $BrainPath = "$($Variables.MainPath)\Brains\$($_)"
            $BrainName = (".\Brains\" + $_ + "\Brains.ps1")
            If (Test-Path $BrainName -PathType Leaf) { 
                Write-Message "Starting Brains for $($_)..."
                $BrainJob = Start-Job -FilePath $BrainName -ArgumentList @($BrainPath)
                $BrainJob | Add-Member -Force @{ PoolName = $_ }
                $Variables.BrainJobs += $BrainJob
                Remove-Variable BrainJob
            }
        }
    }
    # Starts Earnings Tracker Job if necessary
    $StartDelay = 0

    If ((Test-Path -PathType Leaf ".\Includes\EarningsTrackerJob.ps1") -and ($Config.TrackEarnings) -and (-not ($Variables.EarningsTrackerJobs))) { 
        $Params = @{ 
            WorkingDirectory = $Variables.MainPath
            PoolsConfig      = $Config.PoolsConfig
        }
        $EarningsJob = Start-Job -FilePath ".\Includes\EarningsTrackerJob.ps1" -ArgumentList $Params
        If ($EarningsJob) { 
            Write-Message "Starting Earnings Tracker..."
            $Variables.EarningsTrackerJobs += $EarningsJob
            Remove-Variable EarningsJob
        }
    }
}

Function Initialize-Application { 
    $Variables | Add-Member -Force @{ SourcesHash = @() }
    $Variables | Add-Member -Force @{ ProcessorCount = (Get-CimInstance -class win32_processor).NumberOfLogicalProcessors }

    Set-Location $Variables.MainPath

    $Variables | Add-Member -Force @{ ScriptStartDate = (Get-Date).ToUniversalTime() }
    If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { 
        [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
    }

    If ($env:CUDA_DEVICE_ORDER -ne 'PCI_BUS_ID') { $env:CUDA_DEVICE_ORDER = 'PCI_BUS_ID' } # Align CUDA id with nvidia-smi order
    If ($env:GPU_FORCE_64BIT_PTR -ne 1) { $env:GPU_FORCE_64BIT_PTR = 1 }                   # For AMD
    If ($env:GPU_MAX_HEAP_SIZE -ne 100) { $env:GPU_MAX_HEAP_SIZE = 100 }                   # For AMD
    If ($env:GPU_USE_SYNC_OBJECTS -ne 1) { $env:GPU_USE_SYNC_OBJECTS = 1 }                 # For AMD
    If ($env:GPU_MAX_ALLOC_PERCENT -ne 100) { $env:GPU_MAX_ALLOC_PERCENT = 100 }           # For AMD
    If ($env:GPU_SINGLE_ALLOC_PERCENT -ne 100) { $env:GPU_SINGLE_ALLOC_PERCENT = 100 }     # For AMD
    If ($env:GPU_MAX_WORKGROUP_SIZE -ne 256) { $env:GPU_MAX_WORKGROUP_SIZE = 256 }         # For AMD

    #Set process priority to BelowNormal to avoid hash rate drops on systems with weak CPUs
    (Get-Process -Id $PID).PriorityClass = "BelowNormal"

    Import-Module NetSecurity -ErrorAction SilentlyContinue
    Import-Module Defender -ErrorAction SilentlyContinue
    Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\NetSecurity\NetSecurity.psd1" -ErrorAction SilentlyContinue
    Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1" -ErrorAction SilentlyContinue
    If ($PSEdition -eq 'core') { Import-Module -SkipEditionCheck NetTCPIP -ErrorAction SilentlyContinue }

    If (Get-Command "Unblock-File" -ErrorAction SilentlyContinue) { Get-ChildItem . -Recurse | Unblock-File }
    If ((Get-Command "Get-MpPreference" -ErrorAction SilentlyContinue) -and (Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { 
        Start-Process (@{ desktop = "powershell"; core = "pwsh" }.$PSEdition) "-Command Import-Module '$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1'; Add-MpPreference -ExclusionPath '$(Convert-Path .)'" -Verb runAs
    }

    If ($Proxy -eq "") { $PSDefaultParameterValues.Remove("*:Proxy") }
    Else { $PSDefaultParameterValues["*:Proxy"] = $Proxy }
    Write-Message "Initializing Variables..."
    $Variables | Add-Member -Force @{ DecayStart = (Get-Date).ToUniversalTime() }
    $Variables | Add-Member -Force @{ DecayPeriod = 120 } #seconds
    $Variables | Add-Member -Force @{ DecayBase = 1 - 0.1 } #decimal percentage
    $Variables | Add-Member -Force @{ ActiveMiners = @() }
    $Variables | Add-Member -Force @{ Miners = @() }
    #Start the log
    Start-Transcript -Path ".\Logs\miner-$((Get-Date).ToString('yyyyMMdd')).log" -Append -Force
    # Purge Logs more than 10 days
    If ((Get-ChildItem ".\Logs\miner-*.log").Count -gt 10) { 
        Get-ChildItem ".\Logs\miner-*.log" | Where-Object { $_.name -notin (Get-ChildItem ".\Logs\miner-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 10).FullName } | Remove-Item -Force -Recurse
    }
    #Update stats with missing data and set to today's date/time
    $Variables.StatusText = "Preparing stats data..."
    Get-Stat; $Now = (Get-Date).ToUniversalTime(); if ($Stats ) { $Stats | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Stats.$_.Updated = $Now } }
    #Set donation parameters
    $Variables | Add-Member -Force @{ DonateRandom = [PSCustomObject]@{ } }
    $Variables | Add-Member -Force @{ LastDonated = (Get-Date).AddDays(-1).AddHours(1) }
    If ($Config.Donate -lt 1) { $Config.Donate = (0, (0..0)) | Get-Random }
    $Variables | Add-Member -Force @{ WalletBackup = $Config.Wallet }
    $Variables | Add-Member -Force @{ UserNameBackup = $Config.UserName }
    $Variables | Add-Member -Force @{ WorkerNameBackup = $Config.WorkerName }
    $Variables | Add-Member -Force @{ EarningsPool = "" }
    $Variables | Add-Member -Force @{ BrainJobs = @() }
    $Variables | Add-Member -Force @{ EarningsTrackerJobs = @() }
    $Variables | Add-Member -Force @{ Earnings = @{ } }

    $Variables | Add-Member -Force @{ StartPaused = $False }
    $Variables | Add-Member -Force @{ Started = $False }
    $Variables | Add-Member -Force @{ Paused = $False }
    $Variables | Add-Member -Force @{ RestartCycle = $False }

    $Location = $Config.Location
 
    
    #Load information about the devices
    $Variables | Add-Member -Force Devices @(Get-Device | Select-Object)

    # Find available TCP Ports
    $StartPort = 4068
    $Config.Type | Sort-Object | ForEach-Object { 
        Write-Message "Finding available TCP Port for $($_)"
        $Port = Get-FreeTcpPort($StartPort)
        $Variables | Add-Member -Force @{ "$($_)MinerAPITCPPort" = $Port }
        Write-Message "Miners API Port: $($Port)"
        $StartPort = $Port + 1
    }
    Start-Sleep 2
}

Function Get-Rates {
    # Read exchange rates from min-api.cryptocompare.com
    # Returned decimal values contain as many digits as the native currency
    $RatesBTC = (Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$($Config.Currency -join ",")&extraParams=http://nemosminer.com" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop).BTC
    If ($RatesBTC) {
        $Variables | Add-Member -Force @{ Rates = $RatesBTC }
    }
}

Function Write-Message { 
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

        #Update status text box in GUI
        If ($Variables.LabelStatus) { 
            $Variables.LabelStatus.Lines += $Message
            $Variables.LabelStatus.SelectionStart = $Variables.LabelStatus.TextLength
            $Variables.LabelStatus.ScrollToCaret()
            $Variables.LabelStatus.Refresh()
        }

        If ((-not $Config) -or $Level -in $Config.LogLevel) { 

            # Inherit the same verbosity settings as the script importing this
            If (-not $PSBoundParameters.ContainsKey('InformationPreference')) { $InformationPreference = $PSCmdlet.GetVariableValue('InformationPreference') }
            If (-not $PSBoundParameters.ContainsKey('Verbose')) { $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference') }
            If (-not $PSBoundParameters.ContainsKey('Debug')) { $DebugPreference = $PSCmdlet.GetVariableValue('DebugPreference') }

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

            If ($Variables.LogFile) { 
                # Get mutex named NemosMinerWriteLog. Mutexes are shared across all threads and processes. 
                # This lets us ensure only one thread is trying to write to the file at a time. 
                $Mutex = New-Object System.Threading.Mutex($false, "NemosMinerWriteLog")

                $Filename = $Variables.LogFile
                $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                # Attempt to aquire mutex, waiting up to 1 second If necessary.  If aquired, write to the log file and release mutex.  Otherwise, display an error. 
                If ($Mutex.WaitOne(1000)) { 
                    "$Date $LevelText $Message" | Out-File -FilePath $FileName -Append -Encoding UTF8
                    $Mutex.ReleaseMutex()
                }
                Else { 
                    Write-Error -Message "Log file is locked, unable to write message to $FileName."
                }
            }
        }
    }
    End { }
}

Function Get-NVIDIADriverVersion { 
    ((Get-CimInstance CIM_VideoController) | Select-Object name, description, @{ Name = "NVIDIAVersion" ; Expression = { ([regex]"[0-9.]{ 6}$").match($_.driverVersion).value.Replace(".", "").Insert(3, '.') } } | Where-Object { $_.Description -like "*NVIDIA*" } | Select-Object -First 1).NVIDIAVersion
}

# Function Global:RegisterLoaded ($File) { 
#     New-Item -Path function: -Name script:"$((Get-FileHash (Resolve-Path $File)).Hash)" -Value { $true } -ErrorAction SilentlyContinue | Add-Member @{ "File" = (Resolve-Path $File).Path } -ErrorAction SilentlyContinue
# }

# Function Global:IsLoaded ($File) { 
#     $Hash = (Get-FileHash (Resolve-Path $File).Path).hash
#     If (Test-Path function::$Hash) { 
#         $True
#     }
#     Else { 
#         Get-ChildItem function: | Where-Object { $_.File -eq (Resolve-Path $File).Path } | Remove-Item
#         $false
#     }
# }

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

            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script
            $ScriptBody = "using module .\Includes\Core.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

            While ($True) { 
                $IdleSeconds = [Math]::Round(([PInvoke.Win32.UserInput]::IdleTime).TotalSeconds)

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
    If (-not $Config.MonitoringServer) { return }
    If (-not $Config.MonitoringUser) { return }

    If ($Config.ReportToServer) { 
        $Version = "$($Variables.CurrentProduct) $($Variables.CurrentVersion.ToString())"
        $Status = If ($Variables.Paused) { "Paused" } Else { "Running" }
        $RunningMiners = $Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" }
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
    $CycleRunspace.SessionStateProxy.SetVariable('LabelStatus', $Variables.LabelStatus)
    $CycleRunspace.SessionStateProxy.Path.SetLocation((Split-Path $script:MyInvocation.MyCommand.Path))
    $Powershell = [powershell]::Create()
    $Powershell.Runspace = $CycleRunspace
    $Powershell.AddScript(
        { 
            Set-Location $Variables.MainPath

            $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script
            $ScriptBody = "using module .\Includes\Core.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

            #Start the log
            Start-Transcript -Path ".\Logs\CoreCyle-$((Get-Date).ToString('yyyyMMdd')).log" -Append -Force
            # Purge Logs more than 10 days
            If ((Get-ChildItem ".\Logs\CoreCyle-*.log").Count -gt 10) { 
                Get-ChildItem ".\Logs\CoreCyle-*.log" | Where-Object { $_.name -notin (Get-ChildItem ".\Logs\CoreCyle-*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 10).FullName } | Remove-Item -Force -Recurse
            }
            $ProgressPreference = "SilentlyContinue"

            Update-Monitoring
            While ($true) { 
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
                    Start-NPMCycle
                    Update-Monitoring
                    $EndLoop = (Get-Date).AddSeconds($Variables.TimeToSleep)
                    # On crashed miner start next loop immediately
                    While ((Get-Date) -lt $EndLoop -and ($RunningMiners = $Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" } | Where-Object { -not $_.Process.HasExited } | Where-Object { $_.DataReaderJob.State -eq "Running" })) {
                        Start-Sleep -Seconds 1

                        If ($BenchmarkingMiners = @($RunningMiners | Where-Object { (-not $_.Hashrate_Gathered) -or ($Variables.MeasurePowerUsage -and (-not $_.PowerUsage))})) {
                            #Exit loop when enought samples
                            While ($BenchmarkingMinersNeedingMoreSamples = @($BenchmarkingMiners | Where-Object { ($_.Data).Count -lt ($_.IntervalMultiplier * $Config.MinHashRateSamples) })) { 
                                #Get more miner data
                                $RunningMiners | Where-Object { $_.DataReaderJob.HasMoreData } | ForEach-Object { 
                                    $_.Data += $Samples = @($_.DataReaderJob | Receive-Job ) 
                                    $Sample = @($Samples) | Select-Object -Last 1
                                    If ($Sample) { Write-Message -Level Verbose "$($_.Name) data sample retrieved: [$(($Sample.Hashrate.PSObject.Properties.Name | ForEach-Object { "$_ = $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(if ($Miner.AllowedBadShareRatio) { ", Shares Total = $($Sample.Shares.$_[2]), Rejected = $($Sample.Shares.$_[1])" })" }) -join '; ')$(if ($Sample.PowerUsage) { " / Power = $($Sample.PowerUsage.ToString("N2"))W" })]" }
                                }
                                Start-Sleep -Seconds 1
                            }
                            $EndLoop = (Get-Date)
                            Remove-Variable BenchmarkingMinersNeedingMoreSamples
                            Remove-variable BenchmarkingMiners
                        }
                        Else { 
                            $RunningMiners | Where-Object { $_.DataReaderJob.HasMoreData } | ForEach-Object { 
                                $_.Data += $Samples = @($_.DataReaderJob | Receive-Job ) 
                                $Sample = @($Samples) | Select-Object -Last 1
                                If ($Sample) { Write-Message -Level Verbose "$($_.Name) data sample retrieved: [$(($Sample.Hashrate.PSObject.Properties.Name | ForEach-Object { "$_ = $(($Sample.Hashrate.$_ | ConvertTo-Hash) -replace ' ')$(if ($Miner.AllowedBadShareRatio) { ", Shares Total = $($Sample.Shares.$_[2]), Rejected = $($Sample.Shares.$_[1])" })" }) -join '; ')$(if ($Sample.PowerUsage) { " / Power = $($Sample.PowerUsage.ToString("N2"))W" })]" }
                            }
                        }
                    }
                }
            }
        }
    ) | Out-Null
    $Variables | Add-Member -Force @{ CycleRunspaceHandle = $Powershell.BeginInvoke() }
    $Variables | Add-Member -Force @{ LastDonated = (Get-Date).AddDays(-1).AddHours(1) }
}

Function Stop-Mining { 
  
    If ($Variables.ActiveMiners) { 
        $Variables.ActiveMiners | ForEach-Object { 
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
                    Start-Sleep -Seconds 1
                    $_.Status = "Idle"
                }
            }
        }
    }

    If ($CycleRunspace) { $CycleRunspace.Close() }
    If ($Powershell) { $Powershell.Dispose() }
}

Function Update-Notifications ($Text) { 
    $LabelNotifications.Lines += $Text
    If ($LabelNotifications.Lines.Count -gt 20) { $LabelNotifications.Lines = $LabelNotifications.Lines[($LabelNotifications.Lines.count - 10)..$LabelNotifications.Lines.Count] }
    $LabelNotifications.SelectionStart = $Variables.LabelStatus.TextLength;
    $LabelNotifications.ScrollToCaret();
    $Variables.LabelStatus.Refresh | Out-Null
}

Function Get-GPUCount { 
    Write-Message "Fetching GPU Count"
    $DetectedGPU = @()
    Try { 
        $DetectedGPU += @(Get-CimInstance Win32_PnPEntity | Select-Object Name, Manufacturer, PNPClass, Availability, ConfigManagerErrorCode, ConfigManagerUserConfig | Where-Object { $_.Manufacturer -like "*NVIDIA*" -and $_.PNPClass -like "*display*" -and $_.ConfigManagerErrorCode -ne "22" }) 
    }
    Catch { Write-Message "NVIDIA Detection failed" }
    Try { 
        $DetectedGPU += @(Get-CimInstance Win32_PnPEntity | Select-Object Name, Manufacturer, PNPClass, Availability, ConfigManagerErrorCode, ConfigManagerUserConfig | Where-Object { $_.Manufacturer -like "*Advanced Micro Devices*" -and $_.PNPClass -like "*display*" -and $_.ConfigManagerErrorCode -ne "22" }) 
    }
    Catch { Write-Message "AMD Detection failed" }
    $DetectedGPUCount = $DetectedGPU.Count
    $i = 0
    $DetectedGPU | ForEach-Object { Write-Message "$($i): $($_.Name)" | Out-Null; $i++ }
    Write-Message "Found $($DetectedGPUCount) GPU(s)"
    $DetectedGPUCount
}

Function Get-Config { 
    param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )
    If ($Global:Config -isnot [Hashtable]) { 
        New-Variable Config ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
    }
    If (Test-Path $ConfigFile -PathType Leaf) { 
        Get-Content $ConfigFile | ConvertFrom-Json | ForEach-Object { 
            $_.PSObject.Properties | Sort-Object Name | ForEach-Object { 
                $Global:Config | Add-Member -Force @{ $_.Name = $_.Value }
            }
        }
    }
}

Function Write-Config { 
    param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )
    If ($Global:Config.ManualConfig) { Write-Message "Manual config mode - Not saving config"; return }
    If ($Global:Config -is [Hashtable]) { 
        If (Test-Path $ConfigFile) { Copy-Item $ConfigFile "$($ConfigFile).backup" -force }
        $OrderedConfig = [PSCustomObject]@{ }
        $Global:Config | ConvertTo-Json | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty PoolsConfig | ForEach-Object { 
            $_.PSObject.Properties | Sort-Object Name | ForEach-Object { 
                $OrderedConfig | Add-Member -Force @{ $_.Name = $_.Value } 
            } 
        }
        $OrderedConfig | ConvertTo-Json | Out-File $ConfigFile
        $PoolsConfig = Get-Content ".\Config\PoolsConfig.json" | ConvertFrom-Json
        $OrderedPoolsConfig = [PSCustomObject]@{ } ; $PoolsConfig | ForEach-Object { $_.PSObject.Properties | Sort-Object  Name | ForEach-Object { $OrderedPoolsConfig | Add-Member -Force @{ $_.Name = $_.Value } } }
        $OrderedPoolsConfig.default | Add-Member -Force @{ Wallet = $Config.Wallet }
        $OrderedPoolsConfig.default | Add-Member -Force @{ UserName = $Config.UserName }
        $OrderedPoolsConfig.default | Add-Member -Force @{ WorkerName = $Config.WorkerName }
        $OrderedPoolsConfig.default | Add-Member -Force @{ APIKey = $Config.APIKey }
        $OrderedPoolsConfig | ConvertTo-Json | Out-File ".\Config\PoolsConfig.json"
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
        [TimeSpan]$Duration, 
        [Parameter(Mandatory = $false)]
        [Bool]$FaultDetection = $true, 
        [Parameter(Mandatory = $false)]
        [Bool]$ChangeDetection = $false,
        [Parameter(Mandatory = $false)]
        [Int]$ToleranceExceeded = 3
    )

    $Timer = $Updated = $Updated.ToUniversalTime()

    $Path = "Stats\$Name.txt"
    $SmallestValue = 1E-20

    $Stat = Get-Stat $Name

    If ($Stat -is [Hashtable] -and $Stat.IsSynchronized) { 
        If (-not $Stat.Timer) { $Stat.Timer = $Stat.Updated.AddMinutes(-1) }
        If (-not $Duration) { $Duration = $Updated - $Stat.Timer }
        If ($Duration -le 0) { Return $Stat }

        $ToleranceMin = $Value
        $ToleranceMax = $Value

        If ($FaultDetection) { 
            $ToleranceMin = $Stat.Week * (1 - [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
            $ToleranceMax = $Stat.Week * (1 + [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
        }

        If ($ChangeDetection -and [Decimal]$Value -eq [Decimal]$Stat.Live) { $Updated = $Stat.Updated }

        If ($Value -lt $ToleranceMin -or $Value -gt $ToleranceMax) { $Stat.ToleranceExceeded ++ }
        Else { $Stat | Add-Member ToleranceExceeded ([UInt16]0) -Force }

        If ($Value -and $Stat.ToleranceExceeded -gt 0 -and $Stat.ToleranceExceeded -lt $ToleranceExceeded) { 
            #Update immediately if stat value is 0
            If ($Name -match ".+_HashRate$") { 
                Write-Message -Level Warn "Stat file ($Name) was not updated because the value ($(($Value | ConvertTo-Hash) -replace '\s+', '')) is outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) [$($Stat.ToleranceExceeded) of 3 until enforced update]."
            }
            ElseIf ($Name -match ".+_PowerUsage") { 
                Write-Message -Level Warn "Stat file ($Name) was not updated because the value ($($Value.ToString("N2"))W) is outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) [$($Stat.ToleranceExceeded) of 3 until enforced update]."
            }
        }
        Else { 
            If ($Value -eq 0 -or $Stat.ToleranceExceeded -eq $ToleranceExceeded) { 
                #Update immediately if stat value is 0
                If ($Value) { 
                    If ($Name -match ".+_HashRate$") { 
                        Write-Message -Level Warn "Stat file ($Name) was forcefully updated with value ($(($Value | ConvertTo-Hash) -replace '\s+', '')) because it was outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ')) to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) for $($Stat.ToleranceExceeded) times in a row."
                    }
                    ElseIf ($Name -match ".+_PowerUage$") { 
                        Write-Message -Level Warn "Stat file ($Name) was forcefully updated with value ($($Value.ToString("N2"))W) because it was outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) for $($Stat.ToleranceExceeded) times in a row."
                    }
                }

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
                        Duration              = [TimeSpan]::FromMinutes(1)
                        Updated               = [DateTime]$Updated
                        ToleranceExceeded     = [UInt16]0
                        Timer                 = [DateTime]$Timer
                    }
                )
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
                ToleranceExceeded     = [UInt16]0
                Timer                 = [DateTime]$Timer
            }
        )
    }

    @{ 
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
        Duration              = [String]$Stat.Duration
        Updated               = [DateTime]$Stat.Updated
    } | ConvertTo-Json | Set-Content $Path

    $Stat
}

Function Get-Stat { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = (
            & {
                [String[]]$StatFiles = (Get-ChildItem "Stats" -ErrorAction Ignore | Select-Object -ExpandProperty BaseName)
                ($Global:Stats.Keys | Select-Object | Where-Object { $_ -notin $StatFiles }) | ForEach-Object { $Global:Stats.Remove($_) } # Remove stat if deleted on disk
                $StatFiles
            }
        )
    )

    $Name | Sort-Object -Unique | ForEach-Object { 
        $Stat_Name = $_
        If ($Global:Stats.$Stat_Name -isnot [Hashtable] -or -not $Global:Stats.$Stat_Name.IsSynchronized) { 
            If ($Global:Stats -isnot [Hashtable] -or -not $Global:Stats.IsSynchronized) { 
                $Global:Stats = [Hashtable]::Synchronized(@{ })
            }

            #Reduce number of errors
            If (-not (Test-Path "Stats\$Stat_Name.txt" -PathType Leaf)) { 
                If (-not (Test-Path "Stats" -PathType Container)) { 
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
                        ToleranceExceeded     = [UInt16]0
                    }
                )
            }
            Catch { 
                Write-Message -Level Warn "Stat file ($Stat_Name) is corrupt and will be reset. "
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
                $Content = $_ | Get-Content | Where-Object { $_ -notmatch "^#.+" } | ConvertFrom-Json -ErrorAction SilentlyContinue
            }
            Catch [ArgumentException] { 
                $null
            }
        }
        $Content | Select-Object | ForEach-Object { 
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
Function Invoke-TcpRequest { 
     
    param(
        [Parameter(Mandatory = $true)]
        [String]$Server = "localhost", 
        [Parameter(Mandatory = $true)]
        [String]$Port, 
        [Parameter(Mandatory = $true)]
        [String]$Request, 
        [Parameter(Mandatory = $true)]
        [Int]$Timeout = 30 #seconds
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

Function Invoke-HttpRequest { 
     
    param(
        [Parameter(Mandatory = $true)]
        [String]$Server = "localhost", 
        [Parameter(Mandatory = $true)]
        [String]$Port, 
        [Parameter(Mandatory = $false)]
        [String]$Request, 
        [Parameter(Mandatory = $true)]
        [Int]$Timeout = 30 #seconds
    )

    Try { 
        $response = Invoke-WebRequest "http://$($Server):$Port$Request" -UseBasicParsing -TimeoutSec $timeout
    }
    Catch { $Error.Remove($error[$Error.Count - 1]) }

    $response
}

Function Get-MinerData { 
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Miner,
        [Parameter(Mandatory = $true)]
        [Boolean]$ReadPowerUsage = $false
    )

    $API = [String]$Miner.API
    $Port = [Int16]$Miner.Port
    $Server = "localhost"
    $Timeout = [Int16]45 #Seconds
    $Algorithms = [String[]]$Miner.Pools.PSObject.Properties.Name
    $DeviceNames = [String[]]$Miner.DeviceNames

    $RegistryHive = "HKCU:\Software\HWiNFO64\VSB"

    Try { 
        If ($ReadPowerUsage) {
            #read power usage

            If ((Test-Path $RegistryHive) -and $DeviceNames) { 
                $RegistryData = Get-ItemProperty $RegistryHive
                $RegistryData.PSObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @($DeviceNames | Select-Object) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                    $PowerUsage += [Double]($RegistryData.($_.Name -replace "Label", "Value") -split ' ' | Select-Object -Index 0)
                }
            }
        }

        Switch ($Miner.API) { 
            "bminer" { 
                $Request = Invoke-HttpRequest $Server $Port "/api/v1/status/solver" $Timeout
                If ($Request) { 
                    $Data = $Request.content | ConvertFrom-Json 
                    $Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                        if ($Data.devices.$_.solvers[0].speed_info.hash_rate) { $HashRate_Value += [Double]$Data.devices.$_.solvers[0].speed_info.hash_rate }
                        else { $HashRate_Value += [Double]$Data.devices.$_.solvers[0].speed_info.solution_rate }
                        if ($Data.devices.$_.solvers[1].speed_info.hash_rate) { $HashRateDual_Value += [Double]$Data.devices.$_.solvers[1].speed_info.hash_rate }
                        else { $HashRateDual_Value += [Double]$Data.devices.$_.solvers[1].speed_info.solution_rate }
                    }
                }
            }

            "castxmr" { 
                $Request = Invoke-HttpRequest $Server $Port "" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json 
                    $HashRate_Value = [Double]($Data.devices.hash_rate | Measure-Object -Sum).Sum / 1000
                }
            }

            "ccminer" { 
                $Request = Invoke-TcpRequest $Server $Port "summary" $Timeout
                If ($Request) { 
                    $Data = $Request -split ";" | ConvertFrom-StringData
                    $HashRate_Value = If ([Double]$Data.KHS -ne 0 -or [Double]$Data.ACC -ne 0) { [Double]$Data.KHS * 1000 }
                }
            }

            "claymore" { 
                $Request = Invoke-HttpRequest $Server $Port "" $Timeout
                If ($Request) { 
                    $Data = $Request.Content.Substring($Request.Content.IndexOf("{ "), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{ ") + 1) | ConvertFrom-Json
                    $HashRate_Value = [Double]$Data.result[2].Split(";")[0] * 1000
                    $HashRateDual_Value = [Double]$Data.result[4].Split(";")[0] * 1000
                }
            }

            "claymorev2" { 
                $Request = Invoke-HttpRequest $Server $Port "" $Timeout
                If ($Request -ne "" -and $Request -ne $null) { 
                    $Data = $Request.Content.Substring($Request.Content.IndexOf("{ "), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{ ") + 1) | ConvertFrom-Json
                    $HashRate_Value = [Double]$Data.result[2].Split(";")[0] 
                }
            }

            "dtsm" { 
                $Request = Invoke-TcpRequest $Server $Port "empty" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json | Select-Object  -ExpandProperty result 
                    $HashRate_Value = [Double](($Data.sol_ps) | Measure-Object -Sum).Sum 
                }
            }

            "ethminer" { 
                $Parameters = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
                $Request = Invoke-TcpRequest $Server $Port $Parameters $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.result[2] -split ';')[0]) * 1000
                }
            }

            "ewbf" { 
                $Message = @{ id = 1; method = "getstat" } | ConvertTo-Json -Compress
                $Request = Invoke-TcpRequest $Server $Port $message $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.result.speed_sps) | Measure-Object -Sum).Sum
                }
            }

            "fireice" { 
                $Request = Invoke-HttpRequest $Server $Port "/h" $Timeout
                If ($Request) { 
                    $Data = $Request.Content -split "</tr>" -match "total*" -split "<td>" -replace "<[^>]*>", ""
                    $HashRate_Value = $Data[1]
                    If (-not $HashRate_Value) { $HashRate_Value = $Data[2] }
                    If (-not $HashRate_Value) { $HashRate_Value = $Data[3] }
                }
            }

            "gminer" { 
                $Request = Invoke-HttpRequest $Server $Port "/stat" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]($Data.devices.speed | Measure-Object -Sum).Sum
                    $HashRateDual_Value = [Double]($Data.devices.speed2 | Measure-Object -Sum).Sum
                }
            }

            "gminerdual" { 
                $Request = Invoke-HttpRequest $Server $Port "/stat" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]($Data.devices.speed2 | Measure-Object -Sum).Sum
                    $HashRateDual_Value = [Double]($Data.devices.speed | Measure-Object -Sum).Sum
                }
            }

            "grinpro" { 
                $Request = Invoke-HttpRequest $Server $Port "/api/status" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.workers.graphsPerSecond) | Measure-Object -Sum).Sum
                }
            }

            "lol" { 
                $Request = Invoke-HttpRequest $Server $Port "/summary" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]$data.Session.Performance_Summary
                }
            }

            "miniz" { 
                $Message = '{ "id":"0", "method":"getstat"}'
                $Request = Invoke-TcpRequest $Server $Port $message $Timeout
                if ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.result.speed_sps) | Measure-Object -Sum).Sum
                }
            }

            "nanominer" { 
                $Request = Invoke-HttpRequest $Server $Port "/stat" $Timeout
                if ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $Data.Statistics.Devices | ForEach-Object { 
                        $DeviceData = $_
                        Switch ($DeviceData.Hashrates[0].unit) { 
                            "KH/s" { $HashRate_Value += ($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 1)) }
                            "MH/s" { $HashRate_Value += ($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 2)) }
                            "GH/s" { $HashRate_Value += ($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 3)) }
                            "TH/s" { $HashRate_Value += ($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 4)) }
                            "PH/s" { $HashRate_Value += ($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 5)) }
                            default { $HashRate_Value += ($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 0)) }
                        }
                    }
                }
            }

            "nbminer" { 
                $Request = Invoke-HttpRequest $Server $Port "/api/v1/status" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    If ($Algorithms.Count -eq 2) { 
                        $HashRate_Value = [Double]$Data.miner.total_hashrate2_raw
                        $HashRateDual_Value = [Double]$Data.miner.total_hashrate_raw
                    }
                    else { 
                        $HashRate_Value = [Double]$Data.miner.total_hashrate_raw
                    }
                }
            }

            "nbminerdual" { 
                $Request = Invoke-HttpRequest $Server $Port "/api/v1/status" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    If ($Algorithms.Count -eq 2) { 
                        $HashRate_Value = [Double]$Data.miner.total_hashrate2_raw
                        $HashRateDual_Value = [Double]$Data.miner.total_hashrate_raw
                    }
                    else { 
                        $HashRate_Value = [Double]$Data.miner.total_hashrate2_raw
                    }
                }
            }

            "nheq" { 
                $Request = Invoke-TcpRequest $Server $Port "status" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]$Data.result.speed_ips * 1000000
                }
            }

            "palgin" { 
                $Request = Invoke-TcpRequest $Server $Port  "summary" $Timeout
                if ($Request) { 
                    $Data = $Request -split ";"
                    $HashRate_Value = [Double]($Data[5] -split '=')[1] * 1000
                }
            }

            "prospector" { 
                $Request = Invoke-HttpRequest $Server $Port "/api/v0/hashrates" $Timeout
                if ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]($Data.rate | Measure-Object -Sum).sum
                }
            }

            "srb" { 
                $Request = Invoke-HttpRequest $Server $Port "" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = @(
                        [Double]$Data.HashRate_total_now
                        [Double]$Data.HashRate_total_5min
                    ) | Where-Object { $_ -gt 0 } | Select-Object -First 1
                }
            }

            "ttminer" { 
                $Parameters = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json  -Compress
                $Request = Invoke-TcpRequest $Server $Port $Parameters $Timeout
                if ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.result[2] -split ';')[0]) #* 1000
                }
            }

            "xgminer" { 
                $Message = @{ command = "summary"; parameter = "" } | ConvertTo-Json -Compress
                $Request = Invoke-TcpRequest $Server $Port $Message $Timeout

                if ($Request) { 
                    $Data = $Request.Substring($Request.IndexOf("{ "), $Request.LastIndexOf("}") - $Request.IndexOf("{ ") + 1) -replace " ", "_" | ConvertFrom-Json

                    $HashRate_Value = If ($Data.SUMMARY.HS_5s -ne $null) { [Double]$Data.SUMMARY.HS_5s * [math]::Pow(1000, 0) }
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

            "xmrig" { 
                $Request = Invoke-HttpRequest $Server $Port "/api.json" $Timeout
                if ($Request) { 
                    $Data = $Request | ConvertFrom-Json 
                    $HashRate_Value = [Double]$Data.hashrate.total[0]
                }
            }

            "wrapper" { 
                $HashRate_Value = ""
                $wrpath = ".\Logs\energi.txt"
                $HashRate_Value = If (Test-Path -Path $wrpath -PathType Leaf ) { 
                    Get-Content $wrpath
                    $HashRate_Value = ($HashRate_Value-split ',')[0]
                    If (-not $HashRate_Value) { $HashRate_Value = ($HashRate_Value-split '.')[0] }

                }
                Else { $HashRate_Value = 0 }
            }

            "zjazz" { 
                $Request = Invoke-TcpRequest $Server $Port  "summary" $Timeout
                if ($Request) { 
                    $Data = $Request -split ";" | ConvertFrom-StringData -ErrorAction Stop
                    $HashRate_Value = [Double]$Data.KHS * 2000000 #Temp fix for nlpool wrong hashrate
                }
            }
        } #end Switch

        If ($ReadPowerUsage) {
            #read power usage
            If ((Test-Path $RegistryHive) -and $DeviceNames) { 
                $RegistryData = Get-ItemProperty $RegistryHive
                $RegistryData.PSObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @($DeviceNames | Select-Object) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                    $PowerUsage += [Double]($RegistryData.($_.Name -replace "Label", "Value") -split ' ' | Select-Object -Index 0)
                }
            }
        }

        $HashRate = [PSCustomObject]@{}
        $HashRate | Add-Member @{ $Algorithms[0] = $HashRate_Value }
        If ($Algorithms.Count -eq 2) { 
            $HashRate | Add-Member @{ $Algorithms[1] = $HashRateDual_Value }
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            [PSCustomObject]@{
                Date       = (Get-Date).ToUniversalTime()
                HashRate   = $HashRate
                #Shares     = $Shares
                PowerUsage = $PowerUsage / 2
            }
        }
    }
    Catch { }
}

Function Get-CpuId { 

    # Brief : gets CPUID (CPU name and registers)

    #OS Features
    $OS_x64 = "" #not implemented
    $OS_AVX = "" #not implemented
    $OS_AVX512 = "" #not implemented

    #Vendor
    $vendor = "" #not implemented

    If ($vendor -eq "GenuineIntel") { 
        $Vendor_Intel = $true;
    }
    ElseIf ($vendor -eq "AuthenticAMD") { 
        $Vendor_AMD = $true;
    }

    $info = [CpuID]::Invoke(0)
    #convert 16 bytes to 4 ints for compatibility with existing code
    $info = [int[]]@(
        [BitConverter]::ToInt32($info, 0 * 4)
        [BitConverter]::ToInt32($info, 1 * 4)
        [BitConverter]::ToInt32($info, 2 * 4)
        [BitConverter]::ToInt32($info, 3 * 4)
    )

    $nIds = $info[0]

    $info = [CpuID]::Invoke(0x80000000)
    $nExIds = [BitConverter]::ToUInt32($info, 0 * 4) #not sure as to why 'nExIds' is unsigned; may not be necessary
    #convert 16 bytes to 4 ints for compatibility with existing code
    $info = [int[]]@(
        [BitConverter]::ToInt32($info, 0 * 4)
        [BitConverter]::ToInt32($info, 1 * 4)
        [BitConverter]::ToInt32($info, 2 * 4)
        [BitConverter]::ToInt32($info, 3 * 4)
    )

    #Detect Features
    $features = @{ }
    If ($nIds -ge 0x00000001) { 

        $info = [CpuID]::Invoke(0x00000001)
        #convert 16 bytes to 4 ints for compatibility with existing code
        $info = [int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $features.MMX = ($info[3] -band ([int]1 -shl 23)) -ne 0
        $features.SSE = ($info[3] -band ([int]1 -shl 25)) -ne 0
        $features.SSE2 = ($info[3] -band ([int]1 -shl 26)) -ne 0
        $features.SSE3 = ($info[2] -band ([int]1 -shl 00)) -ne 0

        $features.SSSE3 = ($info[2] -band ([int]1 -shl 09)) -ne 0
        $features.SSE41 = ($info[2] -band ([int]1 -shl 19)) -ne 0
        $features.SSE42 = ($info[2] -band ([int]1 -shl 20)) -ne 0
        $features.AES = ($info[2] -band ([int]1 -shl 25)) -ne 0

        $features.AVX = ($info[2] -band ([int]1 -shl 28)) -ne 0
        $features.FMA3 = ($info[2] -band ([int]1 -shl 12)) -ne 0

        $features.RDRAND = ($info[2] -band ([int]1 -shl 30)) -ne 0
    }

    If ($nIds -ge 0x00000007) { 

        $info = [CpuID]::Invoke(0x00000007)
        #convert 16 bytes to 4 ints for compatibility with existing code
        $info = [int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $features.AVX2 = ($info[1] -band ([int]1 -shl 05)) -ne 0

        $features.BMI1 = ($info[1] -band ([int]1 -shl 03)) -ne 0
        $features.BMI2 = ($info[1] -band ([int]1 -shl 08)) -ne 0
        $features.ADX = ($info[1] -band ([int]1 -shl 19)) -ne 0
        $features.MPX = ($info[1] -band ([int]1 -shl 14)) -ne 0
        $features.SHA = ($info[1] -band ([int]1 -shl 29)) -ne 0
        $features.PREFETCHWT1 = ($info[2] -band ([int]1 -shl 00)) -ne 0

        $features.AVX512_F = ($info[1] -band ([int]1 -shl 16)) -ne 0
        $features.AVX512_CD = ($info[1] -band ([int]1 -shl 28)) -ne 0
        $features.AVX512_PF = ($info[1] -band ([int]1 -shl 26)) -ne 0
        $features.AVX512_ER = ($info[1] -band ([int]1 -shl 27)) -ne 0
        $features.AVX512_VL = ($info[1] -band ([int]1 -shl 31)) -ne 0
        $features.AVX512_BW = ($info[1] -band ([int]1 -shl 30)) -ne 0
        $features.AVX512_DQ = ($info[1] -band ([int]1 -shl 17)) -ne 0
        $features.AVX512_IFMA = ($info[1] -band ([int]1 -shl 21)) -ne 0
        $features.AVX512_VBMI = ($info[2] -band ([int]1 -shl 01)) -ne 0
    }

    if ($nExIds -ge 0x80000001) { 

        $info = [CpuID]::Invoke(0x80000001)
        #convert 16 bytes to 4 ints for compatibility with existing code
        $info = [int[]]@(
            [BitConverter]::ToInt32($info, 0 * 4)
            [BitConverter]::ToInt32($info, 1 * 4)
            [BitConverter]::ToInt32($info, 2 * 4)
            [BitConverter]::ToInt32($info, 3 * 4)
        )

        $features.x64 = ($info[3] -band ([int]1 -shl 29)) -ne 0
        $features.ABM = ($info[2] -band ([int]1 -shl 05)) -ne 0
        $features.SSE4a = ($info[2] -band ([int]1 -shl 06)) -ne 0
        $features.FMA4 = ($info[2] -band ([int]1 -shl 16)) -ne 0
        $features.XOP = ($info[2] -band ([int]1 -shl 11)) -ne 0
    }

    # wrap data into PSObject
    [PSCustomObject]@{ 
        Vendor   = $vendor
        Name     = $name
        Features = $features.Keys.ForEach{ if ($features.$_) { $_ } }
    }
}

Function Get-Device { 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @(), 
        [Parameter(Mandatory = $false)]
        [String[]]$ExcludeName = @(), 
        [Parameter(Mandatory = $false)]
        [Switch]$Refresh = $false
    )

    If ($Name) { 
        $DeviceList = Get-Content ".\Includes\Devices.txt" | ConvertFrom-Json
        $Name_Devices = $Name | ForEach-Object { 
            $Name_Split = $_ -split '#'
            $Name_Split = @($Name_Split | Select-Object -Index 0) + @($Name_Split | Select-Object -Skip 1 | ForEach-Object { [Int]$_ })
            $Name_Split += @("*") * (100 - $Name_Split.Count)

            $Name_Device = $DeviceList.("{0}" -f $Name_Split) | Select-Object *
            $Name_Device | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Name_Device.$_ = $Name_Device.$_ -f $Name_Split }

            $Name_Device
        }
    }

    If ($ExcludeName) { 
        If (-not $DeviceList) { $DeviceList = Get-Content ".\Includes\Devices.txt" | ConvertFrom-Json }
        $ExcludeName_Devices = $ExcludeName | ForEach-Object { 
            $ExcludeName_Split = $_ -split '#'
            $ExcludeName_Split = @($ExcludeName_Split | Select-Object -Index 0) + @($ExcludeName_Split | Select-Object -Skip 1 | ForEach-Object { [Int]$_ })
            $ExcludeName_Split += @("*") * (100 - $ExcludeName_Split.Count)

            $ExcludeName_Device = $DeviceList.("{0}" -f $ExcludeName_Split) | Select-Object *
            $ExcludeName_Device | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $ExcludeName_Device.$_ = $ExcludeName_Device.$_ -f $ExcludeName_Split }

            $ExcludeName_Device
        }
    }

    If ($Variables.Devices -isnot [Array] -or $Refresh) { 
        $Variables | Add-Member -Force @{ Devices = @() }

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

        #Get WDDM data
        Try { 
            Get-CimInstance CIM_Processor | ForEach-Object { 
                $Device_CIM = $_ | ConvertTo-Json | ConvertFrom-Json

                #Add normalised values
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
                            default { $Device_CIM.Manufacturer -replace '\(R\)|\(TM\)|\(C\)' -replace '[^A-Z0-9]' }
                        }
                    )
                    Memory = $null
                }

                $Device | Add-Member @{ 
                    Id             = [Int]$Id
                    Type_Id        = [Int]$Type_Id.($Device.Type)
                    Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                    Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                }

                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                $Device.Model = (($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor) -join ' ' -replace '\(R\)|\(TM\)|\(C\)' -replace '[^A-Z0-9]'

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id++
                $Vendor_Id.($Device.Vendor)++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                $Type_Id.($Device.Type)++

                #Read CPU features
#                $Device | Add-member CpuFeatures ((Get-CpuId).Features | Sort-Object)

                # #Add raw data
                # $Device | Add-Member @{ 
                #     CIM = $Device_CIM
                # }
            }

            Get-CimInstance CIM_VideoController | ForEach-Object { 
                $Device_CIM = $_ | ConvertTo-Json | ConvertFrom-Json

                $Device_PNP = [PSCustomObject]@{ }
                Get-PnpDevice $Device_CIM.PNPDeviceID | Get-PnpDeviceProperty | ForEach-Object { $Device_PNP | Add-Member $_.KeyName $_.Data }
                $Device_PNP = $Device_PNP | ConvertTo-Json | ConvertFrom-Json

                $Device_Reg = Get-ItemProperty "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\$($Device_PNP.DEVPKEY_Device_Driver)" | ConvertTo-Json | ConvertFrom-Json

                #Add normalised values
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
                            default { $Device_CIM.AdapterCompatibility -replace '\(R\)|\(TM\)|\(C\)' -replace '[^A-Z0-9]' }
                        }
                    )
                    Memory = [Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize'))
                }

                $Device | Add-Member @{ 
                    Id             = [Int]$Id
                    Type_Id        = [Int]$Type_Id.($Device.Type)
                    Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                    Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                }

                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join ' ' -replace '\(R\)|\(TM\)|\(C\)' -replace '[^A-Z0-9]'

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id++
                $Vendor_Id.($Device.Vendor)++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                $Type_Id.($Device.Type)++

                # #Add raw data
                # $Device | Add-Member @{ 
                #      CIM = $Device_CIM
                #      PNP = $Device_PNP
                #      Reg = $Device_Reg
                #  }
            }
        }
        Catch { 
            Write-Message -Level Warn "WDDM device detection has failed. "
        }

        # #Get OpenCL data
        # Try { 
        #     [OpenCl.Platform]::GetPlatformIDs() | ForEach-Object { 
        #         [OpenCl.Device]::GetDeviceIDs($_, [OpenCl.DeviceType]::All) | ForEach-Object { 
        #             $Device_OpenCL = $_ | ConvertTo-Json | ConvertFrom-Json

        #             #Add normalised values
        #             $Device = [PSCustomObject]@{ 
        #                 Name   = $null
        #                 Model  = $Device_OpenCL.Name
        #                 Type   = $(
        #                     Switch -Regex ([String]$Device_OpenCL.Type) { 
        #                         "CPU" { "CPU" }
        #                         "GPU" { "GPU" }
        #                         default { [String]$Device_OpenCL.Type -replace '\(R\)|\(TM\)|\(C\)' -replace '[^A-Z0-9]' }
        #                     }
        #                 )
        #                 Bus    = $(
        #                     If ($Device_OpenCL.PCIBus -is [Int64] -or $Device_OpenCL.PCIBus -is [Int32]) { 
        #                         [Int64]$Device_OpenCL.PCIBus
        #                     }
        #                 )
        #                 Vendor = $(
        #                     Switch -Regex ([String]$Device_OpenCL.Vendor) { 
        #                         "Advanced Micro Devices" { "AMD" }
        #                         "Intel" { "INTEL" }
        #                         "NVIDIA" { "NVIDIA" }
        #                         "AMD" { "AMD" }
        #                         default { [String]$Device_OpenCL.Vendor -replace '\(R\)|\(TM\)|\(C\)' -replace '[^A-Z0-9]' }
        #                     }
        #                 )
        #                 Memory = [UInt64]$Device_OpenCL.GlobalMemSize
        #             }

        #             $Device | Add-Member @{ 
        #                 Id             = [Int]$Id
        #                 Type_Id        = [Int]$Type_Id.($Device.Type)
        #                 Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
        #                 Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
        #             }

        #             $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
        #             $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join ' ' -replace '\(R\)|\(TM\)|\(C\)' -replace '[^A-Z0-9]'

        #             If ($Variables.Devices | Where-Object Type -EQ $Device.Type | Where-Object Bus -EQ $Device.Bus) { 
        #                 $Device = $Variables.Devices | Where-Object Type -EQ $Device.Type | Where-Object Bus -EQ $Device.Bus
        #             }
        #             ElseIf ($Device.Type -eq "GPU" -and ($Device.Vendor -eq "AMD" -or $Device.Vendor -eq "NVIDIA")) { 
        #                 $Variables.Devices += $Device

        #                 If (-not $Type_Vendor_Id.($Device.Type)) { 
        #                     $Type_Vendor_Id.($Device.Type) = @{ }
        #                 }
        
        #                 $Id++
        #                 $Vendor_Id.($Device.Vendor)++
        #                 $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
        #                 $Type_Id.($Device.Type)++
        #             }

        #             #Add OpenCL specific data
        #             $Device | Add-Member @{ 
        #                 Index                 = [Int]$Index
        #                 Type_Index            = [Int]$Type_Index.($Device.Type)
        #                 Vendor_Index          = [Int]$Vendor_Index.($Device.Vendor)
        #                 Type_Vendor_Index     = [Int]$Type_Vendor_Index.($Device.Type).($Device.Vendor)
        #                 PlatformId            = [Int]$PlatformId
        #                 PlatformId_Index      = [Int]$PlatformId_Index.($PlatformId)
        #                 Type_PlatformId_Index = [Int]$Type_PlatformId_Index.($Device.Type).($PlatformId)
        #             }

        #             #Add raw data
        #             $Device | Add-Member @{ 
        #                 OpenCL = $Device_OpenCL
        #             }

        #             If (-not $Type_Vendor_Index.($Device.Type)) { 
        #                 $Type_Vendor_Index.($Device.Type) = @{ }
        #             }
        #             If (-not $Type_PlatformId_Index.($Device.Type)) { 
        #                 $Type_PlatformId_Index.($Device.Type) = @{ }
        #             }

        #             $Index++
        #             $Type_Index.($Device.Type)++
        #             $Vendor_Index.($Device.Vendor)++
        #             $Type_Vendor_Index.($Device.Type).($Device.Vendor)++
        #             $PlatformId_Index.($PlatformId)++
        #             $Type_PlatformId_Index.($Device.Type).($PlatformId)++
        #         }

        #         $PlatformId++
        #     }

        #     $Variables.Devices | Where-Object Bus -Is [Int64] | Sort-Object Bus | ForEach-Object { 
        #         $_ | Add-Member @{ 
        #             Slot             = [Int]$Slot
        #             Type_Slot        = [Int]$Type_Slot.($_.Type)
        #             Vendor_Slot      = [Int]$Vendor_Slot.($_.Vendor)
        #             Type_Vendor_Slot = [Int]$Type_Vendor_Slot.($_.Type).($_.Vendor)
        #         }

        #         If (-not $Type_Vendor_Slot.($_.Type)) { 
        #             $Type_Vendor_Slot.($_.Type) = @{ }
        #         }

        #         $Slot++
        #         $Type_Slot.($_.Type)++
        #         $Vendor_Slot.($_.Vendor)++
        #         $Type_Vendor_Slot.($_.Type).($_.Vendor)++
        #     }
        # }
        # Catch { 
        #     Write-Message -Level Warn "OpenCL device detection has failed. "
        # }
    }

    $Variables.Devices | ForEach-Object { 
        $Device = $_
        If (-not $Name -or ($Name_Devices | Where-Object { ($Device | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) -like ($_ | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) })) { 
            If (-not $ExcludeName -or -not ($ExcludeName_Devices | Where-Object { ($Device | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) -like ($_ | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) })) { 
                $Device
            }
        }
    }
}

Filter ConvertTo-Hash { 
    [CmdletBinding()]
    $Units = " kMGTPEZY" #k(ilo) in small letters, see https://en.wikipedia.org/wiki/Metric_prefix
    $Base1000 = [Math]::Truncate([Math]::Log([Math]::Abs($_), [Math]::Pow(1000, 1)))
    $Base1000 = [Math]::Max([Double]0, [Math]::Min($Base1000, $Units.Length - 1))
    "{0:n2} $($Units[$Base1000])H" -f ($_ / [Math]::Pow(1000, $Base1000))
}

Function Get-DigitsFromValue { 
    # To get same numbering scheme regardless of value BTC value (size) to determine formatting

    # Length is calculated as follows:
    # Output will have as many digits as the integer value is to the power of 10
    # e.g. Rate is between 100 -and 999, then Digits is 3
    # The bigger the number, the more decimal digits
    # Use $Offset to add/remove decimal places

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Double]$Value,
        [Parameter(Mandatory = $false)]
        [Int]$Offset = 0
    )

    $Digits = [math]::Floor($Value).ToString().Length
    If ($Digits -lt 0) { $Digits = 0 }
    If ($Digits -gt 10) { $Digits = 10 }

    $Digits
}

Function ConvertTo-LocalCurrency { 

    # To get same numbering scheme regardless of value BTC value (size) to determine formatting
    # Use $Offset to add/remove decimal places

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Double]$Value, 
        [Parameter(Mandatory = $true)]
        [Double]$BTCRate, 
        [Parameter(Mandatory = $false)]
        [Int]$Offset
    )

    $Digits = ([math]::truncate(10 - $Offset - [math]::log($BTCRate, 10)))
    If ($Digits -lt 0) { $Digits = 0 }
    If ($Digits -gt 10) { $Digits = 10 }

    ($Value * $BTCRate).ToString("N$($Digits)")
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
                $Process = (Get-Process | Where-Object { $_.Path -eq $FilePath })[0]
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$Uri, 
        [Parameter(Mandatory = $false)]
        [String]$Path = ""
    )

    # Set current path used by .net methods to the same as the script's path
    [Environment]::CurrentDirectory = $ExecutionContext.SessionState.Path.CurrentFileSystemLocation

    If (-not $Path) { $Path = Join-Path ".\Downloads" ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName }
    If (-not (Test-Path ".\Downloads" -PathType Container)) { New-Item "Downloads" -ItemType "directory" | Out-Null }
    $FileName = Join-Path ".\Downloads" (Split-Path $Uri -Leaf)

    If (Test-Path $FileName -PathType Leaf) { Remove-Item $FileName }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest $Uri -OutFile $FileName -UseBasicParsing

    If (".msi", ".exe" -contains ([IO.FileInfo](Split-Path $Uri -Leaf)).Extension) { 
        Start-Process $FileName "-qb" -Wait
    }
    Else { 
        $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
        $Path_New = Split-Path $Path

        If (Test-Path $Path_Old -PathType Container) { Remove-Item $Path_Old -Recurse -Force }
        Start-Process ".\Utils\7z" "x `"$([IO.Path]::GetFullPath($FileName))`" -o`"$([IO.Path]::GetFullPath($Path_Old))`" -y -spe" -Wait -WindowStyle Hidden

        If (Test-Path $Path_New -PathType Container) { Remove-Item $Path_New -Recurse -Force }

        #use first (topmost) directory in case, e.g. ClaymoreDual_v11.9, contain multiple miner binaries for different driver versions in various sub dirs
        $Path_Old = (Get-ChildItem $Path_Old -File -Recurse | Where-Object { $_.Name -EQ $(Split-Path $Path -Leaf) }).Directory | Select-Object -Index 0

        If ($Path_Old) { 
            Move-Item $Path_Old $Path_New -PassThru | ForEach-Object -Process { $_.LastWriteTime = Get-Date }
            $Path_Old = (Join-Path (Split-Path (Split-Path $Path)) ([IO.FileInfo](Split-Path $Uri -Leaf)).BaseName)
            If (Test-Path $Path_Old -PathType Container) { Remove-Item $Path_Old -Recurse -Force }
        }
        Else { 
            Throw "Error: Cannot find $($Path). "
        }
    }
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

Function Initialize-Autoupdate { 
    # GitHub Supporting only TLSv1.2 on feb 22 2018
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    Write-host (Split-Path $script:MyInvocation.MyCommand.Path)
    Write-Message "Checking Autoupdate"
    Update-Notifications("Checking Auto Update")
    # write-host "Checking Autoupdate"
    $NemosMinerFileHash = (Get-FileHash ".\NemosMiner.ps1").Hash
    Try { 
        $AutoupdateVersion = Invoke-WebRequest "https://nemosminer.com/data/Initialize-Autoupdate.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
    }
    Catch { $AutoupdateVersion = Get-content ".\Config\Initialize-AutoupdateVersion.json" | Convertfrom-json }
    If ($AutoupdateVersion -ne $null) { $AutoupdateVersion | ConvertTo-Json | Out-File ".\Config\Initialize-AutoupdateVersion.json" }
    If ($AutoupdateVersion.Product -eq $Variables.CurrentProduct -and [Version]$AutoupdateVersion.Version -gt $Variables.CurrentVersion -and $AutoupdateVersion.Autoupdate) { 
        Write-Message "Version $($AutoupdateVersion.Version) available. (You are running $($Variables.CurrentVersion))"
        $LabelNotifications.ForeColor = "Green"
        $LabelNotifications.Lines += "Version $([Version]$AutoupdateVersion.Version) available"

        If ($AutoupdateVersion.Autoupdate) { 
            $LabelNotifications.Lines += "Starting Auto Update"
            # Setting autostart to true
            If ($Variables.Started) { $Config.autostart = $true }
            Write-Config -ConfigFile $ConfigFile
            
            # Download update file
            $UpdateFileName = ".\$($AutoupdateVersion.Product)-$($AutoupdateVersion.Version)"
            Write-Message "Downloading version $($AutoupdateVersion.Version)"
            Update-Notifications("Downloading version $($AutoupdateVersion.Version)")
            Try { 
                Invoke-WebRequest $AutoupdateVersion.Uri -OutFile "$($UpdateFileName).zip" -TimeoutSec 15 -UseBasicParsing
            }
            Catch { 
                Write-Message "Update download failed"
                Update-Notifications("Update download failed")
                $LabelNotifications.ForeColor = "Red"
                Return
            }
            If (-not (Test-Path ".\$($UpdateFileName).zip" -PathType Leaf)) { 
                Write-Message "Cannot find update file"
                Update-Notifications("Cannot find update file")
                $LabelNotifications.ForeColor = "Red"
                return
            }

            # Backup current version folder in zip file
            Write-Message "Backing up current version..."
            Update-Notifications("Backing up current version...")
            $BackupFileName = ("Initialize-AutoupdateBackup-$(Get-Date -Format u).zip").replace(" ", "_").replace(":", "")
            Start-Process ".\Utils\7z" "a $($BackupFileName) .\* -x!*.zip" -Wait -WindowStyle hidden
            If (-not (Test-Path .\$BackupFileName -PathType Leaf)) { 
                Write-Message "Backup failed"
                Return
            }

            # Pre update specific actions If any
            # Use PreUpdateActions.ps1 in new release to place code
            If (Test-Path ".\$UpdateFileName\PreUpdateActions.ps1" -PathType Leaf) { 
                Invoke-Expression (get-content ".\$UpdateFileName\PreUpdateActions.ps1" -Raw)
            }

            # Empty OptionalMiners - Get rid of Obsolete ones
            Get-ChildItem .\OptionalMiners\ | ForEach-Object { Remove-Item -Recurse -Force $_.FullName }

            # unzip in child folder excluding config
            Write-Message "Unzipping update..."
            Start-Process ".\Utils\7z" "x $($UpdateFileName).zip -o.\ -y -spe -xr!config" -Wait -WindowStyle hidden

            # copy files 
            Write-Message "Copying files..."
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
            Write-Message "Removing temporary files..."
            Remove-Item .\$UpdateFileName -Force -Recurse
            Remove-Item ".\$($UpdateFileName).zip" -Force
            If (Test-Path ".\PreUpdateActions.ps1" -PathType Leaf) { Remove-Item ".\PreUpdateActions.ps1" -Force }
            If (Test-Path ".\PostUpdateActions.ps1" -PathType Leaf) { Remove-Item ".\PostUpdateActions.ps1" -Force }
            Get-ChildItem "Initialize-AutoupdateBackup-*.zip" | Where-Object { $_.name -notin (Get-ChildItem "Initialize-AutoupdateBackup-*.zip" | Sort-Object  LastWriteTime -Descending | Select-Object -First 2).name } | Remove-Item -Force -Recurse
            
            # Start new instance (Wait and confirm start)
            # Kill old instance
            If ($AutoupdateVersion.RequireRestart -or ($NemosMinerFileHash -ne (Get-FileHash ".\NemosMiner.ps1").Hash)) { 
                Write-Message "Starting my brother"
                $StartCommand = ((Get-CimInstance win32_process -filter "ProcessID=$PID" | Select-Object commandline).CommandLine)
                $NewKid = Invoke-WmiMethod -Class Win32_Process -Name Create -ArgumentList @($StartCommand, (Split-Path $script:MyInvocation.MyCommand.Path))
                # Giving 10 seconds for process to start
                $Waited = 0
                Start-Sleep 10
                While (-not (Get-Process -id $NewKid.ProcessId -ErrorAction silentlycontinue) -and ($waited -le 10)) { Start-Sleep 1; $waited++ }
                If (-not (Get-Process -id $NewKid.ProcessId -ErrorAction silentlycontinue)) { 
                    Write-Message "Failed to start new instance of $($Variables.CurrentProduct)"
                    Update-Notifications("$($Variables.CurrentProduct) auto updated to version $($AutoupdateVersion.Version) but failed to restart.")
                    $LabelNotifications.ForeColor = "Red"
                    return
                }

                $TempVerObject = (Get-Content .\Version.json | ConvertFrom-Json)
                $TempVerObject | Add-Member -Force @{ Autoupdated = (Get-Date) }
                $TempVerObject | ConvertTo-Json | Out-File .\Version.json
                
                Write-Message "$($Variables.CurrentProduct) successfully updated to version $($AutoupdateVersion.Version)"
                Update-Notifications("$($Variables.CurrentProduct) successfully updated to version $($AutoupdateVersion.Version)")

                Write-Message "Killing myself"
                If (Get-Process -id $NewKid.ProcessId) { Stop-process -id $PID }
            }
            Else { 
                $TempVerObject = (Get-Content .\Version.json | ConvertFrom-Json)
                $TempVerObject | Add-Member -Force @{ Autoupdated = (Get-Date) }
                $TempVerObject | ConvertTo-Json | Out-File .\Version.json
                
                Write-Message "Successfully updated to version $($AutoupdateVersion.Version)"
                Update-Notifications("Successfully updated to version $($AutoupdateVersion.Version)")
                $LabelNotifications.ForeColor = "Green"
            }
        }
        ElseIf (-not ($Config.Autostart)) { 
            UpdateStatus("Cannot Auto Update as autostart not selected")
            Update-Notifications("Cannot Auto Update as autostart not selected")
            $LabelNotifications.ForeColor = "Red"
        }
        Else { 
            UpdateStatus("$($AutoupdateVersion.Product)-$($AutoupdateVersion.Version). Not candidate for Auto Update")
            Update-Notifications("$($AutoupdateVersion.Product)-$($AutoupdateVersion.Version). Not candidate for Auto Update")
            $LabelNotifications.ForeColor = "Red"
        }
    }
    Else { 
        Write-Message "$($AutoupdateVersion.Product)-$($AutoupdateVersion.Version). Not candidate for Auto Update"
        Update-Notifications("$($AutoupdateVersion.Product)-$($AutoupdateVersion.Version). Not candidate for Auto Update")
        $LabelNotifications.ForeColor = "Green"
    }
}
