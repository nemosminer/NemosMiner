using module .\Includes\Include.psm1

<#
Copyright (c) 2018-2020 Nemo

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
File:           NemosMiner.ps1
Version:        3.9.9.0
Version date:   10 August 2020
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [String[]]$Algorithm = @(), #i.e. @("Ethash", "Equihash", "Cryptonight") etc.
    [Parameter(Mandatory = $false)]
    [Double]$AllowedBadShareRatio = 0.1, #Allowed ratio of bad shares (total / bad) as reported by the miner. If the ratio exceeds the configured threshold then the miner will marked as failed. Allowed values: 0.00 - 1.00. Default of 0 disables this check
    [Parameter(Mandatory = $false)]
    [Switch]$AutoStart = $false, #If true NemosMiner will start mining automatically
    [Parameter(Mandatory = $false)] 
    [String]$APILogfile = "", #API will log all requests to this file, to disable leave empty
    [Parameter(Mandatory = $false)]
    [Int]$APIPort = 3999, #TCP Port for API & Web GUI
    [Parameter(Mandatory = $false)]
    [Boolean]$AutoUpdate = $false, # Autoupdate
    [Parameter(Mandatory = $false)]
    [Switch]$BalancesTrackerEnableLog = $true, #If true NemosMiner will store all earning data in .\Logs\EarningTrackerLog.csv
    [Parameter(Mandatory = $false)]
    [UInt16]$BalancesTrackerPollInterval = 15, #minutes, Interval duration to trigger background task to collect pool balances & earnings dataset to 0 to disable
    [Parameter(Mandatory = $false)]
    [String]$ConfigFile = ".\Config\Config.json", #Config file name
    [Parameter(Mandatory = $false)]
    [String[]]$Currency = @("USD", "mBTC"), #i.e. GBP, USD, AUD, NZD ect., mBTC (milli BTC) is also valid
    [Parameter(Mandatory = $false)]
    [Int]$Delay = 1, #seconds between stop and start of miners, use only when getting blue screens on miner switches
    [Parameter(Mandatory = $false)]
    [Switch]$DisableMinerFees = $false, #Set to true to disable miner fees (Note: not all miners support turning off their built in fees, others will reduce the hashrate)
    [Parameter(Mandatory = $false)]
    [Int]$Donate = 13, #Minutes per Day
    [Parameter(Mandatory = $false)]
    [Switch]$EstimateCorrection = $false, #If true NemosMiner will multiply the algo price by estimate factor (actual_last24h / estimate_last24h) to counter pool overestimated prices
    [Parameter(Mandatory = $false)]
    [String[]]$ExcludeDeviceName = @(), #Will replace old device selection, e.g. @("CPU#00", "GPU#02") (work in progress)
    [Parameter(Mandatory = $false)]
    [Switch]$HideMinerWindow = $false, #if true all miners will run as a hidden background task (not recommended). Note that miners that use the 'Wrapper' API will always run hidden
    [Parameter(Mandatory = $false)]
    [Double]$IdlePowerUsageW = 60, #Powerusage of idle system in Watt. Part of profit calculation
    [Parameter(Mandatory = $false)]
    [Int]$IdleSec = 120, #seconds the system must be idle before mining starts (if MineWhenIdle -eq $true)
    [Parameter(Mandatory = $false)]
    [Switch]$IgnoreMinerFee = $false, #If true, NM will ignore miner fee for earning & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePoolFee = $false, #If true NM will ignore pool fee for earning & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePowerCost = $false, #If true, NM will ignore power cost in best miner selection, instead miners with best earnings will be selected
    [Parameter(Mandatory = $false)]
    [Switch]$IncludeOptionalMiners = $true, #If true, use the miners in the 'OptionalMiners' directory
    [Parameter(Mandatory = $false)]
    [Switch]$IncludeRegularMiners = $true, #If true, use the miners in the 'Miners' directory
    [Parameter(Mandatory = $false)]
    [Switch]$IncludeLegacyMiners = $true, #If true, use the miners in the 'LegacyMiners' directory (Miners based on the original MultiPoolMiner format)
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 240, #seconds before between cycles after the first has passed 
    [Parameter(Mandatory = $false)]
    [String[]]$LogToFile = @("Info", "Warn", "Error", "Verbose", "Debug"), #Log level detail to be written to log file, see Write-Message function
    [Parameter(Mandatory = $false)]
    [String[]]$LogToScreen = @("Info", "Warn", "Error", "Verbose", "Debug"), #Log level detail to be written to screen, see Write-Message function
    [Parameter(Mandatory = $false)]
    [Double]$MarginOfError = 0, #0.4, # knowledge about the past won't help us to predict the future so don't pretend that Week_Fluctuation means something real
    [Parameter(Mandatory = $false)]
    [String[]]$MinerName = @(), 
    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 1)]
    [Double]$MinAccuracy = 0.5, #Only pools with price accuracy greater than the configured value. Allowed values: 0.0 - 1.0 (0% - 100%)
    [Parameter(Mandatory = $false)]
    [Int]$MinDataSamples = 20, #Minimum number of hash rate samples required to store hash rate
    [Parameter(Mandatory = $false)]
    [Hashtable]$MinDataSamplesAlgoMultiplier = [Hashtable]@{ "X25r" = 3 }, #Per algo multiply MinDataSamples by this value
    [Parameter(Mandatory = $false)]
    [Switch]$MinerInstancePerDeviceModel = $true, #If true NemosMiner will create separate miner instances per device model. This will increase profitability. 
    [Parameter(Mandatory = $false)]
    [Switch]$MineWhenIdle = $false, #If true, NemosMiner will start mining only if system is idle for $IdleSec seconds
    [Parameter(Mandatory = $false)]
    [String]$MonitoringServer = "", #Monitoring server hostname, default "https://nemosminer.com"
    [Parameter(Mandatory = $false)]
    [String]$MonitoringUser = "", #Unique monitoring user ID 
    [Parameter(Mandatory = $false)]
    [String]$MPHAPIKey = "", #MPH API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$MPHUserName = "Nemo", #MPH UserName
    [Parameter(Mandatory = $false)]
    [String]$NiceHashAPIKey = "", #NiceHash API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$NiceHashAPISecret = "", #NiceHash API Secret (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [Switch]$NiceHashWalletIsInternal = $false, #Set to $true if NiceHashWallet is a NiceHash internal Wallet (lower pool fees)
    [Parameter(Mandatory = $false)]
    [String]$NiceHashWallet = "", #NiceHash wallet, if left empty $Wallet is used
    [Parameter(Mandatory = $false)]
    [String]$NiceHashOrganizationId = "", #NiceHash Organization Id (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [Switch]$NoDualAlgoMining = $false, #If true NemosMiner will not use any dual algo miners
    [Parameter(Mandatory = $false)]
    [Switch]$NoSingleAlgoMining = $false, #If true NemosMiner will not use any single algo miners
    [Parameter(Mandatory = $false)]
    [Switch]$OpenFirewallPorts = $true, #If true, NemosMiner will open firewall ports for all miners (requires admin rights!)
    [Parameter(Mandatory = $false)]
    [String]$PasswordCurrency = "BTC", #i.e. BTC, LTC, ZEC, ETH etc.
    [Parameter(Mandatory = $false)]
    [String[]]$PoolName = @("Blockmasters", "MPH", "NiceHash", "ZergPoolCoins", "ZPool"), 
    [Parameter(Mandatory = $false)]
    [String]$PoolsConfigFile = ".\Config\PoolsConfig.json", #PoolsConfig file name
    [Parameter(Mandatory = $false)]
    [Int]$PoolTimeout = 30, #Time (in seconds) until NemosMiner aborts the pool request (useful if a pool's API is stuck). Note: do not make this value too small or you will not get any pool data
    [Parameter(Mandatory = $false)]
    [Hashtable]$PowerPricekWh = [Hashtable]@{"00:00" = 0.26; "12:00" = 0.3 }, #Price of power per kW⋅h (in $Currency, e.g. CHF), valid from HH:mm (24hr format)
    [Parameter(Mandatory = $false)]
    [Double]$PricePenaltyFactor = 1, #Estimated profit as projected by pool will be multiplied by this facator. Allowed values: 0.0 - 1.0
    [Parameter(Mandatory = $false)]
    [Double]$ProfitabilityThreshold = -99, #Minimum profit threshold, if profit is less than the configured value (in $Currency, e.g. CHF) mining will stop (except for benchmarking & power usage measuring)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingAPIKey = "", #ProHashing API Key (required to retrieve balance information)
    [Parameter(Mandatory = $false)]
    [String]$ProHashingUserName = "nemos", #ProHashing UserName, if left empty then $UserName is used
    [Parameter(Mandatory = $false)]
    [String]$Proxy = "", #i.e http://192.0.0.1:8080 
    [Parameter(Mandatory = $false)]
    [Switch]$ReadPowerUsage = $true, #If true, power usage will be read from miners, required for true profit calculation
    [Parameter(Mandatory = $false)]
    [String]$Region = "Europe", #Used to determine pool nearest to you. Valid values are: Europe, US or Asia
    [Parameter(Mandatory = $false)]
    [Switch]$ReportToServer = $false, 
    [Parameter(Mandatory = $false)]
    [Double]$RunningMinerGainPct = 12, # percent of advantage that running miner has over candidates in term of earning/profit
    [Parameter(Mandatory = $false)]
    [Switch]$ShowAccuracy = $true, #Show pool data accuracy column in miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowAllMiners = $false, #Always show all miners in miner overview (if $false, only the best miners will be shown except when in benchmark / powerusage measurement)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowEarning = $true, #Show miner earning column in miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowEarningBias = $true, #Show miner earning bias column in miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowMinerFee = $true, #Show miner fee column in miner overview (if fees are available, t.b.d. in miner files, Property '[Double]Fee')
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPoolBalances = $true, # Display pool balances & earnings information in text window, requires BalancesTrackerPollInterval > 0
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPoolFee = $true, #Show pool fee column in miner overview
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPowerCost = $true, #Show Power cost column in miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowProfit = $true, #Show miner profit column in miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowProfitBias = $true, #Show miner profit bias column in miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowPowerUsage = $true, #Show Power usage column in miner overview (if power price is available, see PowerPricekWh)
    [Parameter(Mandatory = $false)]
    [Switch]$ShowWorkerStatus = $true, 
    [Parameter(Mandatory = $false)]
    [String]$SnakeTailExe = ".\Utils\SnakeTail.exe", #Path to optional external log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net], leave empty to disable
    [Parameter(Mandatory = $false)]
    [String]$SnakeTailConfig = ".\Utils\NemosMiner_LogReader.xml", #Path to SnakeTail session config file
    [Parameter(Mandatory = $false)]
    [Switch]$SSL = $false, #If true NemosMiner will only use pools which support SSL connections
    [Parameter(Mandatory = $false)]
    [Switch]$StartGUIMinimized = $true, 
    [Parameter(Mandatory = $false)]
    [Switch]$StartPaused = $false, #If true, NemosMiner will start background jobs (Earnings Tracker etc.), but will not mine
    [Parameter(Mandatory = $false)]
    [Int]$SyncWindow = 5, #Minutes. Current pool prices must all be all with 'SyncWindow' minutes, otherwise stable price will be used instead of the biased value and a warning will be shown
    [Parameter(Mandatory = $false)]
    [Switch]$Transcript = $false, # Enable to write PowerShell transcript files (for debugging)
    [Parameter(Mandatory = $false)]
    [String]$UIStyle = "Light", # Light or Full. Defines level of info displayed
    [Parameter(Mandatory = $false)]
    [String]$Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE", 
    [Parameter(Mandatory = $false)]
    [Int]$WarmupTime = 45, #Time the miner are allowed to warm up, e.g. to compile the binaries or to get the API reads before it get marked as failed. Default 30 (seconds). This is also a per miner config item that can be added to miner file too.
    [Parameter(Mandatory = $false)]
    [Switch]$Watchdog = $true, #if true NemosMiner will automatically put pools and/or miners temporarily on hold it they fail 3 times in row
    [Parameter(Mandatory = $false)]
    [Int]$WatchdogMinerAlgorithmCount = 3, #Number of watchdog timers with same miner name & algorithm until miner/algo combination gets suspended
    [Parameter(Mandatory = $false)]
    [Int]$WatchdogMinerCount = 6, #Number of watchdog timers with same miner name until miner gets suspended
    [Parameter(Mandatory = $false)]
    [Int]$WatchdogPoolAlgorithmCount = 3, #Number of watchdog timers with same pool name & algorithm until pool/algo combination gets suspended
    [Parameter(Mandatory = $false)]
    [Int]$WatchdogPoolCount = 7, #Number of watchdog timers with same pool name until pool gets suspended
    [Parameter(Mandatory = $false)]
    [Switch]$WebGUI = $true, #If true launch Web GUI (recommended)
    [Parameter(Mandatory = $false)]
    [String]$WorkerName = "ID=testing"
)

Set-Location (Split-Path $MyInvocation.MyCommand.Path)

@"
NemosMiner
Copyright (c) 2018-$((Get-Date).Year) Nemo, MrPlus & UselessGuru
This is free software, and you are welcome to redistribute it
under certain conditions.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE
"@
Write-Host -F Yellow "Copyright and license notices must be preserved."
@"
"@

# Load Branding
$Global:Branding = [PSCustomObject]@{ 
    LogoPath     = "https://raw.githubusercontent.com/Minerx117/UpDateData/master/NM.png"
    BrandName    = "NemosMiner"
    BrandWebSite = "https://nemosminer.com"
    ProductLabel = "NemosMiner"
    Version      = [System.Version]"3.9.9.0"
}

Try { 
    Add-Type -Path ".\Includes\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Stop
}
Catch { 
    Remove-Item ".\Includes\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll" -Force -ErrorAction Ignore
    Add-Type -Path ".\Includes\OpenCL\*.cs" -OutputAssembly ".\Includes\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
    Add-Type -Path ".\Includes\~OpenCL_$($PSVersionTable.PSVersion.ToString()).dll"
}

Try { 
    Add-Type -Path ".\Includes\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -ErrorAction Stop
}
Catch { 
    Remove-Item ".\Includes\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll" -Force -ErrorAction Ignore
    Add-Type -Path ".\Includes\CPUID.cs" -OutputAssembly ".\Includes\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
    Add-Type -Path ".\Includes\~CPUID_$($PSVersionTable.PSVersion.ToString()).dll"
}

#Get command line parameters
$AllCommandLineParameters = [Ordered]@{ }
$MyInvocation.MyCommand.Parameters.Keys | Where-Object { $_ -notin @("ConfigFile", "PoolsConfigFile", "BalancesTrackerConfigFile", "Verbose", "Debug", "ErrorAction", "WarningAction", "InformationAction", "ErrorVariable", "WarningVariable", "InformationVariable", "OutVariable", "OutBuffer", "PipelineVariable") } | Sort-Object | ForEach-Object { 
    $AllCommandLineParameters.$_ = Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue
    If ($AllCommandLineParameters.$_ -is [Switch]) { $AllCommandLineParameters.$_ = [Boolean]$AllCommandLineParameters.$_ }
}

#Create directories
If (-not (Test-Path -Path ".\Config" -PathType Container)) { New-Item  -Path . -Name "Config" -ItemType Directory | Out-Null }
If (-not (Test-Path -Path ".\Logs" -PathType Container)) { New-Item  -Path . -Name "Logs" -ItemType Directory | Out-Null }

#Initialize global variables
New-Variable Config ([Hashtable]::Synchronized( @{ } )) -Scope "Global" -Force -ErrorAction Stop
New-Variable PoolsConfig ([Hashtable]::Synchronized( @{ } )) -Scope "Global" -Force -ErrorAction Stop
New-Variable Stats ([Hashtable]::Synchronized( @{ } )) -Scope "Global" -Force -ErrorAction Stop
New-Variable Variables ([Hashtable]::Synchronized( @{ } )) -Scope "Global" -Force -ErrorAction Stop

#Expand paths
$Variables.ConfigFile = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ConfigFile))"
$Variables.PoolsConfigFile = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($PoolsConfigFile))"
$Variables.BalancesTrackerConfigFile = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.BalancesTrackerConfigFile))"
$Variables.LogFile = "$($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(".\Logs\NemosMiner_$(Get-Date -Format "yyyy-MM-dd").log"))"

If (Test-Path ".\Config\Version.json" -PathType Leaf) { 
    $Variables.CurrentProduct = (Get-Content .\Config\Version.json -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore).Product
    $Variables.CurrentVersion = [Version](Get-Content .\Config\Version.json -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore).Version
    $Variables.CurrentVersionAutoupdated = (Get-Content .\Config\Version.json -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore).Autoupdated.Value
}
Else { 
    $Variables.CurrentVersion = $Branding.Version
}

#Get command line parameters, required in Read-Config
$AllCommandLineParameters = [Ordered]@{ }
$MyInvocation.MyCommand.Parameters.Keys | Where-Object { $_ -notin @("ConfigFile", "PoolsConfigFile", "BalancesTrackerConfigFile", "Verbose", "Debug", "ErrorAction", "WarningAction", "InformationAction", "ErrorVariable", "WarningVariable", "InformationVariable", "OutVariable", "OutBuffer", "PipelineVariable") } | Sort-Object | ForEach-Object { 
    $AllCommandLineParameters.$_ = Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue
    If ($AllCommandLineParameters.$_ -is [Switch]) { $AllCommandLineParameters.$_ = [Boolean]$AllCommandLineParameters.$_ }
}

#Read configuration
Read-Config -Parameters $AllCommandLineParameters
Read-PoolsConfig

#Start transcript log
If ($Config.Transcript -EQ $true) { Start-Transcript ".\Logs\NemosMiner_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

Write-Message "Starting $($Branding.ProductLabel)® v$($Variables.CurrentVersion) © 2017-$((Get-Date).Year) Nemo, MrPlus and UselessGuru"
If (-not $Variables.FreshConfig) { Write-Message "Using configuration file '$($Variables.ConfigFile)'." }

#Update config file to include all new config items
If (-not $Config.ConfigFileVersion -or [System.Version]::Parse($Config.ConfigFileVersion) -lt $Variables.CurrentVersion) { 
    #Changed config items
    $Changed_Config_Items = $Config.Keys | Where-Object { $_ -notin @(@($AllCommandLineParameters.Keys) + @("PoolsConfig")) }
    $Changed_Config_Items | ForEach-Object { 
        Switch ($_) { 
            "ActiveMinergain" { $Config.RunningMinerGainPct = $Config.$_; $Config.Remove($_) }
            "APIKEY" { 
                $Config.MPHAPIKey = $Config.$_
                $Config.ProHashingAPIKey = $Config.$_
                $Config.Remove($_)
            }
            "EnableEarningsTrackerLog" { $Config.EnableBalancesTrackerLog = $Config.$_; $Config.Remove($_) }
            "Location" { $Config.Region = $Config.$_; $Config.Remove($_) }
            "SelGPUCC" { $Config.Remove($_) }
            "SelGPUDSTM" { $Config.Remove($_) }
            "ShowMinerWindow" { $Config.HideMinerWindow = (-not $Config.$_); $Config.Remove($_) }
            "UserName" { 
                If (-not $Config.MPHUserName) { $Config.MPHUserName = $Config.$_ }
                If (-not $Config.ProHashingUserName) { $Config.ProHashingUserName = $Config.$_ }
                $Config.Remove($_)
            }
            Default { $Config.Remove($_) } #Remove unsupported config item
        }
    }
    Remove-Variable Changed_Config_Items -ErrorAction Ignore

    #Add new config items
    If ($New_Config_Items = $AllCommandLineParameters.Keys | Where-Object { $_ -notin $Config.Keys }) { 
        $New_Config_Items | Sort-Object Name | ForEach-Object { 
            $Value = Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue
            If ($Value -is [Switch]) { $Value = [Boolean]$Value }
            $Global:Config.$_ = $Value
        }
        Remove-Variable Value -ErrorAction Ignore
    }
    $Config.ConfigFileVersion = $Variables.CurrentVersion.ToString()
    Write-Config $Variables.ConfigFile
    Write-Message "Updated configuration file '$($Variables.ConfigFile)' to version $($Variables.CurrentVersion.ToString())."
    Remove-Variable New_Config_Items -ErrorAction Ignore
}

#Start Log reader (SnakeTail) [https://github.com/snakefoot/snaketail-net]
If ((Test-Path $Config.SnakeTailExe -PathType Leaf -ErrorAction Ignore) -and (Test-Path $Config.SnakeTailConfig -PathType Leaf -ErrorAction Ignore)) { 
    $Variables.SnakeTailConfig = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.SnakeTailConfig)
    $Variables.SnakeTailExe = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config.SnakeTailExe)
    If (-not (Get-CIMInstance CIM_Process | Where-Object ExecutablePath -EQ $Variables.SnakeTailExe)) { 
        & "$($Variables.SnakeTailExe)" $Variables.SnakeTailConfig
    }
}

Write-Host "Loading device information..." -F Yellow
$Variables.Devices = [Device[]](Get-Device -Refresh)

Write-Host "Setting variables..." -F Yellow
$Variables.BrainJobs = @{ }
$Variables.IsLocalAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
$Variables.MainPath = (Split-Path $MyInvocation.MyCommand.Path)
$Variables.Miners = [Miner[]]@()
$Variables.Pools = [Pool[]]@()
$Variables.ScriptStartTime = (Get-Date).ToUniversalTime()
$Variables.SupportedVendors = @("AMD", "INTEL", "NVIDIA")
$Variables.AvailableCommandLineParameters = @($AllCommandLineParameters.Keys | Sort-Object)

If ($env:CUDA_DEVICE_ORDER -ne 'PCI_BUS_ID') { $env:CUDA_DEVICE_ORDER = 'PCI_BUS_ID' } # Align CUDA id with nvidia-smi order
If ($env:GPU_FORCE_64BIT_PTR -ne 1) { $env:GPU_FORCE_64BIT_PTR = 1 }                   # For AMD
If ($env:GPU_MAX_HEAP_SIZE -ne 100) { $env:GPU_MAX_HEAP_SIZE = 100 }                   # For AMD
If ($env:GPU_USE_SYNC_OBJECTS -ne 1) { $env:GPU_USE_SYNC_OBJECTS = 1 }                 # For AMD
If ($env:GPU_MAX_ALLOC_PERCENT -ne 100) { $env:GPU_MAX_ALLOC_PERCENT = 100 }           # For AMD
If ($env:GPU_SINGLE_ALLOC_PERCENT -ne 100) { $env:GPU_SINGLE_ALLOC_PERCENT = 100 }     # For AMD
If ($env:GPU_MAX_WORKGROUP_SIZE -ne 256) { $env:GPU_MAX_WORKGROUP_SIZE = 256 }         # For AMD

If ($Config.AutoStart) { 
    If ($Config.StartPaused) { 
        $Variables.NewMiningStatus = "Paused"
    }
    Else { 
        $Variables.NewMiningStatus = "Running"
    }
    #Trigger start mining in TimerUITick
    $Variables.RestartCycle = $true
}

Write-Host "Importing modules..." -F Yellow
Import-Module NetSecurity -ErrorAction SilentlyContinue
Import-Module Defender -ErrorAction SilentlyContinue
Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\NetSecurity\NetSecurity.psd1" -ErrorAction SilentlyContinue
Import-Module "$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1" -ErrorAction SilentlyContinue

#Unblock files
If (Get-Command "Unblock-File" -ErrorAction SilentlyContinue) { Get-ChildItem . -Recurse | Unblock-File }
If ((Get-Command "Get-MpPreference" -ErrorAction Ignore) -and (Get-MpComputerStatus -ErrorAction Ignore) -and (Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) { 
    Start-Process (@{ desktop = "PowerShell"; core = "pwsh" }.$PSEdition) "-Command Import-Module '$env:Windir\System32\WindowsPowerShell\v1.0\Modules\Defender\Defender.psd1'; Add-MpPreference -ExclusionPath '$(Convert-Path .)'" -Verb runAs
}

If ($Config.WebGUI -eq $true) { Initialize-API }

Function Global:TimerUITick { 
    $TimerUI.Enabled = $false

    # If something (pause button, idle timer) has set the RestartCycle flag, stop and start mining to switch modes immediately
    If ($Variables.RestartCycle) { 
        If ($Variables.NewMiningStatus -eq "Stopped") { 
            $ButtonStop.Enabled = $false
            $ButtonStart.Enabled = $true
            $ButtonPause.Enabled = $true
            Stop-Mining
            Stop-IdleMining
            Stop-BrainJob
            Stop-BalancesTracker

            $LabelBTCD.Text = "Stopped | $($Branding.ProductLabel) $($Variables.CurrentVersion)"
            Write-Message "$($Branding.ProductLabel) is idle."
        }
        ElseIf ($Variables.NewMiningStatus -eq "Paused") { 
            If ($Variables.MiningStatus -ne "Paused") { 
                $ButtonStop.Enabled = $true
                $ButtonStart.Enabled = $true
                $ButtonPause.Enabled = $false
                If ($Variables.MiningStatus -eq "Running") { 
                    Stop-Mining
                    Stop-IdleMining
                }
                Else { 
                    Initialize-Application
                    Start-BrainJob
                    Start-BalancesTracker
                }
                Write-Message "Mining is paused. BrainPlus and Earning tracker running."
                $LabelBTCD.Text = "Mining Paused | $($Branding.ProductLabel) $($Variables.CurrentVersion)"
                $EarningsDGV.DataSource = [System.Collections.ArrayList]@()
                $RunningMinersDGV.DataSource = [System.Collections.ArrayList]@()
                $WorkersDGV.DataSource = [System.Collections.ArrayList]@()
                $LabelBTCD.ForeColor = [System.Drawing.Color]::Red
                $TimerUI.Stop
            }
        }
        ElseIf ($Variables.NewMiningStatus -eq "Running") {
            $ButtonStop.Enabled = $true
            $ButtonStart.Enabled = $false
            $ButtonPause.Enabled = $true
            If ($Variables.MiningStatus -ne "Running") { 
                Initialize-Application
                Start-BrainJob
                Start-BalancesTracker
            }
            If ($Config.MineWhenIdle) { 
                Stop-Mining
                If (-not $Variables.IdleRunspace) { Start-IdleMining }
            }
            Else { 

                Stop-IdleMining
                Start-Mining
            }
            $Variables.MiningStatus -eq "Running"
        }
        $Variables.RestartCycle = $false
        $Variables.MiningStatus = $Variables.NewMiningStatus
    }

    If ($Variables.RefreshNeeded -and $Variables.MiningStatus -eq "Running") { 
        $LabelBTCD.ForeColor = [System.Drawing.Color]::Green

        If (($Items = Compare-Object -ReferenceObject $CheckedListBoxPools.Items -DifferenceObject ((Get-ChildItem ".\Pools" -File).BaseName | Sort-Object -Unique) | Where-Object { $_.SideIndicator -eq "=>" }) | Where-Object InputObject -gt 0) { 
            $Items | ForEach-Object { 
                If ($_ -ne $null) { 
                    $CheckedListBoxPools.Items.AddRange($_)
                }
            }
            $Config.PoolName | ForEach-Object { $CheckedListBoxPools.SetItemChecked($CheckedListBoxPools.Items.IndexOf($_), $true) }
        }
        $host.UI.RawUI.WindowTitle = $MainForm.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion) Runtime: {0:dd} days {0:hh} hrs {0:mm} mins Path: $($Variables.Mainpath)" -f ([TimeSpan]((Get-Date).ToUniversalTime() - $Variables.ScriptStartTime))

        If ($Variables.EndLoop) { 

            #Refresh selected tab
            Switch ($TabControl.SelectedTab.Text) { 
                "Earnings"  { Get-Chart }
                "Switching" { CheckBoxSwitching_Click }
            }

            If ($Variables.Earnings -and $Config.ShowPoolBalances) { 
                $DisplayEarnings = [System.Collections.ArrayList]@(
                    $Variables.Earnings.Values | Select-Object @(
                        @{ Name = "Pool"; Expression = { $_.Pool } }, 
                        @{ Name = "Trust"; Expression = { "{0:P0}" -f $_.TrustLevel } }, 
                        @{ Name = "Balance"; Expression = { [decimal]$_.Balance } }, 
                        @{ Name = "BTC/day"; Expression = { "{0:N8}" -f ($_.BTCD) } }, 
                        @{ Name = "m$([char]0x20BF) in 1h"; Expression = { "{0:N6}" -f ($_.Growth1 * 1000 * 24) } }, 
                        @{ Name = "m$([char]0x20BF) in 6h"; Expression = { "{0:N6}" -f ($_.Growth6 * 1000 * 4) } }, 
                        @{ Name = "m$([char]0x20BF) in 24h"; Expression = { "{0:N6}" -f ($_.Growth24 * 1000) } }, 
                        @{ Name = "Est. Pay Date"; Expression = { If ($_.EstimatedPayDate -is 'DateTime') { $_.EstimatedPayDate.ToShortDateString() } Else { $_.EstimatedPayDate } } }, 
                        @{ Name = "PaymentThreshold"; Expression = { "$($_.PaymentThreshold) ($('{0:P0}' -f $($_.Balance / $_.PaymentThreshold)))" }
                    }
                ) | Sort-Object "m$([char]0x20BF) in 1h", "m$([char]0x20BF) in 6h", "m$([char]0x20BF) in 24h" -Descending)
                $EarningsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEarnings)
                $EarningsDGV.ClearSelection()
            }

            If ($Variables.Miners) { 
                $DisplayEstimations = [System.Collections.ArrayList]@(
                    $Variables.Miners | Where-Object Available -EQ $true | Select-Object @(
                        @{ Name = "Miner"; Expression = { $_.Name } }, 
                        @{ Name = "Algorithm(s)"; Expression = { $_.Algorithm -join ' & ' } }, 
                        @{ Name = "PowerUsage"; Expression = { If ($_.MeasurePowerUsage) { "Measuring" } Else {"$($_.PowerUsage.ToString("N3")) W"} } }, 
                        @{ Name = "Speed(s)"; Expression = { ($_.Speed | ForEach-Object { If (-not [Double]::IsNaN($_)) { "$($_ | ConvertTo-Hash)/s" -replace '\s+', ' ' } Else { "Benchmarking" } }) -join ' & ' } }, 
                        @{ Name = "mBTC/day"; Expression = { ($_.Workers | ForEach-Object { If (-not [Double]::IsNaN($_.Earning)) { ($_.Earning * 1000).ToString("N3") } Else { "Unknown" } }) -join ' + ' } }, 
                        @{ Name = "$($Config.Currency | Select-Object -Index 0)/Day"; Expression = { ($_.Workers | ForEach-Object { If (-not [Double]::IsNaN($_.Earning)) { ($_.Earning * ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0))).ToString("N3") } Else { "Unknown" } }) -join ' + ' } }, 
                        @{ Name = "BTC/GH/day"; Expression = { ($_.Workers.Pool.Price | ForEach-Object { ($_ * 1000000000).ToString("N5") }) -join ' + ' } }, 
                        @{ Name = "Pool(s)"; Expression = { ($_.Workers.Pool | ForEach-Object { (@(@($_.Name | Select-Object) + @($_.Coin | Select-Object))) -join '-' }) -join ' & ' }
                    }
                ) | Sort-Object "mBTC/day" -Descending)
                $EstimationsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEstimations)
            }
            $EstimationsDGV.ClearSelection()

            $SwitchingDGV.ClearSelection()

            If ($Variables.Workers -and $Config.ShowWorkerStatus) { 
                $DisplayWorkers = [System.Collections.ArrayList]@(
                    $Variables.Workers | Select-Object @(
                        @{ Name = "Worker"; Expression = { $_.worker } }, 
                        @{ Name = "Status"; Expression = { $_.status } }, 
                        @{ Name = "Last seen"; Expression = { "$($_.timesincelastreport.SubString(1))" } }, 
                        @{ Name = "Version"; Expression = { $_.version } }, 
                        # @{ Name = "Est. Earning mBTC/day"; Expression = { [decimal]($_.Earning * 1000)} }, 
                        # @{ Name = "Est. Earning $($Config.Currency | Select-Object -Index 0)/day"; Expression = { [decimal]($_.Earning * ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0))) } }, 
                        @{ Name = "Est. Profit mBTC/day"; Expression = { [decimal]($_.Profit * 1000)} }, 
                        @{ Name = "Est. Profit $($Config.Currency | Select-Object -Index 0)/day"; Expression = { [decimal]($_.Profit * ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0))) } }, 
                        @{ Name = "Miner"; Expression = { $_.data.name -join ',' } }, 
                        @{ Name = "Pool(s)"; Expression = { $_.data.pool -join ',' } }, 
                        @{ Name = "Algo(s)"; Expression = { $_.data.algorithm -join ',' } }, 
                        @{ Name = "Speed(s)"; Expression = { If ($_.data.currentspeed) { ($_.data.currentspeed | ConvertTo-Hash) -join ',' } Else { "" } } }, 
                        @{ Name = "Benchmark Speed(s)"; Expression = { If ($_.data.estimatedspeed) { ($_.data.estimatedspeed | ConvertTo-Hash) -join ',' } Else { "" } }
                    }
                ) | Sort-Object "Worker Name")
                $WorkersDGV.DataSource = [System.Collections.ArrayList]@($DisplayWorkers)

                # Set row color
                $WorkersDGV.Rows | ForEach-Object { 
                    If ($_.DataBoundItem.Status -eq "Offline") { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 213, 142, 176)
                    }
                    ElseIf ($_.DataBoundItem.Status -eq "Paused") { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 247, 252, 168)
                    }
                    ElseIf ($_.DataBoundItem.Status -eq "Running") { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 127, 191, 144)
                    }
                    Else { 
                        $_.DefaultCellStyle.Backcolor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
                    }
                }

                $WorkersDGV.ClearSelection()
                $LabelMonitoringWorkers.Text = "Worker Status - Updated $($Variables.WorkersLastUpdated.ToString())"
            }

            If ($Variables.Miners) { 
                $RunningMinersDGV.DataSource = [System.Collections.ArrayList]@($Variables.Miners | Where-Object { $_.Status -eq "Running" } | Select-Object  @{ Name = "Type"; Expression = { $_.Type -join " & " } }, @{ Name = "Miner"; Expression = { $_.Info } }, @{ Name = "Account(s)"; Expression = { ($_.Workers.Pool.User | ForEach-Object { $_ -split '\.' | Select-Object -Index 0 } | Select-Object -Unique) -join '; '} }, @{ Name = "HashRate(s)"; Expression = { If ($_.Speed_Live -contains $null) { "$($_.Speed_Live | ConvertTo-Hash)/s" -join ' & ' } Else { "$($_.Speed | ConvertTo-Hash)/s" -join ' & ' } } }, @{ Name = "Active"; Expression = { "{0:%h}:{0:mm}:{0:ss}" -f $_.Active } }, @{ Name = "Total Active"; Expression = { "{0:%h}:{0:mm}:{0:ss}" -f $_.GetActiveTime() } } | Sort-Object Type)
                $RunningMinersDGV.ClearSelection()

                If (-not ($Variables.Miners | Where-Object { $_.Status -eq "Running" })) { 
                    Write-Message "No miners running. Waiting for next cycle."
                }
            }
            $LabelBTCPrice.Text = If ($Variables.Rates."BTC"."BTC".$($Config.Currency | Select-Object -Index 0) -gt 0) { "1 BTC = $(($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)).ToString('n')) $($Config.Currency | Select-Object -Index 0)" }

            If ($null -ne $Variables.Earnings.Values) { 
                $LabelBTCD.Text = "Avg: $($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value (($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 3) = m$([char]0x20BF) {0:N3}/day" -f (($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000)
                $LabelEarningsDetails.Lines = @()
                $TrendSign = Switch ([Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 1000 * 24), 3) - [Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth6 -Sum).sum * 1000 * 4), 3)) { 
                    { $_ -eq 0 } { "=" }
                    { $_ -gt 0 } { ">" }
                    { $_ -lt 0 } { "<" }
                }
                $LabelEarningsDetails.Lines += "Last  1h: $($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value ((($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 24)) -BTCRate $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0) -Offset 3) = m$([char]0x20BF) {0:N3}/day $TrendSign" -f (($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 1000 * 24)
                $TrendSign = Switch ([Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth6 -Sum).sum * 1000 * 4), 3) - [Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000), 3)) { 
                    { $_ -eq 0 } { "=" }
                    { $_ -gt 0 } { ">" }
                    { $_ -lt 0 } { "<" }
                }
                $LabelEarningsDetails.Lines += "Last  6h: $($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value ((($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 4)) -BTCRate $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0) -Offset 3) = m$([char]0x20BF) {0:N3}/day $TrendSign" -f (($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 1000 * 4)
                $TrendSign = Switch ([Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000), 3) - [Math]::Round((($Variables.Earnings.Values | Measure-Object -Property BTCD -Sum).sum * 1000 * 0.96), 3)) { 
                    { $_ -eq 0 } { "=" }
                    { $_ -gt 0 } { ">" }
                    { $_ -lt 0 } { "<" }
                }
                $LabelEarningsDetails.Lines += "Last 24h: $($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value ((($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum)) -BTCRate $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0) -Offset 3) = m$([char]0x20BF) {0:N3}/day $TrendSign" -f (($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 1000)
                Remove-Variable TrendSign
            }
            Else { 
                $LabelBTCD.Text = "Waiting data from pools."
                $LabelEarningsDetails.Lines = @()
            }

            $Variables | Add-Member -Force @{ CurrentProduct = (Get-Content .\Version.json | ConvertFrom-Json).Product }
            $Variables | Add-Member -Force @{ CurrentVersion = [Version](Get-Content .\Version.json | ConvertFrom-Json).Version }
            $Variables | Add-Member -Force @{ Autoupdated = (Get-Content .\Version.json | ConvertFrom-Json).Autoupdated.Value }
            If ((Test-Path ".\Version.json" -PathType Leaf -ErrorAction Ignore) -and (Get-Content ".\Version.json" | ConvertFrom-Json -ErrorAction Ignore).Autoupdated -and $LabelNotifications.Lines[$LabelNotifications.Lines.Count - 1] -ne "Auto Updated on $($Variables.CurrentVersionAutoupdated)") { 
                $LabelNotifications.ForeColor = [System.Drawing.Color]::Green
                Update-Notifications("Running $($Variables.CurrentProduct) Version $([Version]$Variables.CurrentVersion)")
                Update-Notifications("Auto Updated on $($Variables.CurrentVersionAutoupdated)")
            }

            #Display mining information
            If ($host.UI.RawUI.KeyAvailable) { 
                $KeyPressed = $host.UI.RawUI.ReadKey("NoEcho, IncludeKeyDown, IncludeKeyUp"); Start-Sleep -Milliseconds 300; $host.UI.RawUI.FlushInputBuffer()
                If ($KeyPressed.KeyDown) { 
                    Switch ($KeyPressed.Character) { 
                        "s" { If ($Config.UIStyle -eq "Light") { $Config.UIStyle = "Full" } Else { $Config.UIStyle = "Light" } }
                        "e" { $Config.ShowPoolBalances = -not $Config.ShowPoolBalances }
                    }
                }
            }

            Clear-Host
            If ($Config.UIStyle -eq "Full" -and ([Array]$ProcessesIdle = $Variables.Miners | Where-Object { $_.Status -eq "Running" })) { 
                Write-Host "Run Miners: " $ProcessesIdle.Count
                $ProcessesIdle | Sort-Object { If ($null -eq $_.Process) { (Get-Date) } Else { $_.Process.ExitTime } } | Format-Table -Wrap (
                    @{ Label = "Run  "; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                    @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $($_.GetCommandLineParameters())" } }  
                ) | Out-Host
            }

            Write-Host "Exchange Rate: 1 BTC = $($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0).ToString('n')) $($Config.Currency | Select-Object -Index 0)"
            # Get and display earnings stats
            If ($Variables.Earnings -and $Config.ShowPoolBalances) { 
                $Variables.Earnings.Values | Sort-Object { $_.Pool } | ForEach-Object { 
                    Write-Host "+++++" $_.Wallet -B DarkBlue -F DarkGray -NoNewline; Write-Host " $($_.Pool)"
                    Write-Host "Trust Level:                $(($_.TrustLevel).ToString('P0'))" -NoNewline; Write-Host -F darkgray " (based on data from $(([DateTime]::parseexact($_.Date, "yyyy-MM-dd", $null) - [DateTime]$_.StartTime).ToString('%d\ \d\a\y\s\ hh\ \h\r\s\ mm\ \m\i\n\s')))"
                    Write-Host "Average mBTC/Hour:          $(($_.AvgHourlyGrowth * 1000).ToString('N6'))"
                    Write-Host "Average mBTC/Day:" -NoNewline; Write-Host "           $(($_.BTCD * 1000).ToString('N6'))" -F Yellow
                    Write-Host "Balance BTC:                $(($_.Balance).ToString('N6')) ($(($_.Balance / $_.PaymentThreshold).ToString('P0')) of $(($_.PaymentThreshold).ToString('N3')) BTC payment threshold)"
                    Write-Host "Balance $($Config.Currency | Select-Object -Index 0):                $(($_.Balance * $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)).ToString('N6')) ($(($_.Balance / $_.PaymentThreshold).ToString('P0')) of $(($_.PaymentThreshold * $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)).ToString('n')) $($Config.Currency | Select-Object -Index 0) payment threshold)"
                    Write-Host "Estimated Pay Date:         $(if ($_.EstimatedPayDate -is [DateTime]) { ($_.EstimatedPayDate).ToShortDateString() } Else { "$($_.EstimatedPayDate)" })"
                }
            }

            If ($Variables.MinersMissingBinary -or $Variables.MinersMissingPreRequisite) { 
                Write-Host "`n"
                Write-Host "Some miners binaries are missing, downloader is installing miner binaries..." -F Yellow
            }

            If ($Variables.Miners | Where-Object Available -EQ $true | Where-Object { $_.Benchmark -eq $true -or $_.MeasurePowerUsage -eq $true }) { $Config.UIStyle = "Full" }

            #Display available miners list
            [System.Collections.ArrayList]$Miner_Table = @(
                @{ Label = "Miner"; Expression = { $_.Name } }, 
                @{ Label = "Algorithm(s)"; Expression = { $_.Workers.Pool.Algorithm } }
            )
            If ($Config.ShowMinerFee -and ($Variables.Miners.Workers.Fee )) { 
                $Miner_Table.AddRange(
                    @( <#Miner fees#>
                        @{ Label = "Fee(s)"; Expression = { $_.Workers.Fee | ForEach-Object { "{0:P2}" -F [Double]$_ } } }
                    )
                )
            }
            $Miner_Table.AddRange(
                @( <#Miner speed#>
                    @{ Label = "Speed(s)"; Expression = { If (-not $_.Benchmark) { $_.Workers | ForEach-Object { "$($_.Speed | ConvertTo-Hash)/s" } } Else { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } }; Align = 'right' }
                )
            )
            If ($Config.ShowEarning) { 
                $Miner_Table.AddRange(
                    @( <#Miner Earning#>
                            @{ Label = "Earning"; Expression = { If (-not [Double]::IsNaN($_.Earning)) { ConvertTo-LocalCurrency -Value ($_.Earning) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                    )
                )
            }
            If ($Config.ShowEarningBias) { 
                $Miner_Table.AddRange(
                    @( <#Miner EarningsBias#>
                            @{ Label = "EarningBias"; Expression = { If (-not [Double]::IsNaN($_.Earning_Bias)) { ConvertTo-LocalCurrency -Value ($_.Earning_Bias) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                    )
                )
            }
            If ($Config.ShowPowerUsage) { 
                $Miner_Table.AddRange(
                    @( <#Power Usage#>
                        @{ Label = "PowerUsage"; Expression = { If (-not $_.MeasurePowerUsage) { "$($_.PowerUsage.ToString("N2")) W" } Else { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } }; Align = "right" }
                    )
                )
            }
            If ($Config.ShowPowerCost -and ($Variables.Miners.PowerCost )) { 
                $Miner_Table.AddRange(
                    @( <#PowerCost#>
                        @{ Label = "PowerCost"; Expression = { If ($Variables.PowerPricekWh -eq 0) { (0).ToString("N$(Get-DigitsFromValue -Value $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0) -Offset 1)") } Else { If (-not [Double]::IsNaN($_.PowerUsage)) { "-$(ConvertTo-LocalCurrency -Value ($_.PowerCost) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 1)" } Else { "Unknown" } } }; Align = "right" }
                    )
                )
            }
            If ($Config.ShowProfit -and $Variables.PowerPricekWh) { 
                $Miner_Table.AddRange(
                    @( <#Mining Profit#>
                        @{ Label = "Profit"; Expression = { If (-not [Double]::IsNaN($_.Profit)) { ConvertTo-LocalCurrency -Value ($_.Profit) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                    )
                )
            }
            If ($Config.ShowProfitBias -and $Variables.PowerPricekWh) { 
                $Miner_Table.AddRange(
                    @( <#Mining ProfitBias#>
                        @{ Label = "ProfitBias"; Expression = { If (-not [Double]::IsNaN($_.Profit_Bias)) { ConvertTo-LocalCurrency -Value ($_.Profit_Bias) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                    )
                )
            }
            If ($Config.ShowAccuracy) { 
                $Miner_Table.AddRange(
                    @( <#Accuracy#>
                        @{ Label = "Accuracy"; Expression = { $_.Workers.Pool.MarginOfError | ForEach-Object { "{0:P0}" -f [Double](1 - $_) } }; Align = 'right' }
                    )
                )
            }
            $Miner_Table.AddRange(
                @( <#Pools#>
                    @{ Label = "Pool(s)"; Expression = { $_.Workers.Pool.Name | ForEach-Object { $_ } } }
                )
            )
            If ($Config.ShowPoolFee -and ($Variables.Miners.Workers.Pool.Fee )) { 
                $Miner_Table.AddRange(
                    @( <#Show pool fees#>
                        @{ Label = "Fee(s)"; Expression = { $_.Workers.Pool.Fee | ForEach-Object { "{0:P2}" -F [Double]$_ } } }
                    )
                )
            }
            If ($Variables.Miners.Workers.Pool.Coin) { 
                $Miner_Table.AddRange(
                    @( <#Coin#>
                        @{ Label = "Coin(s)"; Expression = { $_.Workers.Pool.Coin | Foreach-Object { [String]$_ } } }
                    )
                )
            }
            If ($Variables.Miners.Workers.Pool.CoinName) { 
                $Miner_Table.AddRange(
                    @( <#CoinName#>
                        @{ Label = "CoinName(s)"; Expression = { $_.Workers.Pool.CoinName | Foreach-Object { [String]$_ } } }
                    )
                )
            }
            If ($Config.IgnorePowerCost) { $SortBy = "Earning" } Else { $SortBy = "Profit" }
            $Variables.Miners | Where-Object Available -EQ $true | Group-Object -Property { $_.DeviceName } | ForEach-Object { 
                $MinersDeviceGroup = @($_.Group)
                $MinersDeviceGroupNeedingBenchmark = @($MinersDeviceGroup | Where-Object Benchmark -EQ $true)
                $MinersDeviceGroupNeedingPowerUsageMeasurement = @($MinersDeviceGroup | Where-Object Enabled -EQ $True | Where-Object MeasurePowerUsage -EQ $true)
                $MinersDeviceGroup = @($MinersDeviceGroup | Where-Object { $Config.ShowAllMiners -or $_.Fastest -EQ $true -or $MinersDeviceGroupNeedingBenchmark.Count -gt 0 -or $MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 0 } )
                $MinersDeviceGroup | Where-Object { 
                    $Config.ShowAllMiners -or <#List all miners#>
                    $_.$SortBy -ge ($MinersDeviceGroup.$SortBy | Sort-Object -Descending | Select-Object -Index 4) -or <#Always list at least the top 5 miners per device group#>
                    $_.$SortBy -ge (($MinersDeviceGroup.$SortBy | Sort-Object -Descending | Select-Object -Index 0) * 0.5) -or <#Always list the better 50% miners per device group#>
                    $MinersDeviceGroupNeedingBenchmark.Count -gt 0 -or <#List all miners when benchmarking#>
                    $MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 0 <#List all miners when measuring power usage#>
                } | Sort-Object DeviceName, @{ Expression = { $_.$SortBy } ; Descending = $true }, @{ Expression = { $_.Workers.Pool.Name } } | Format-Table $Miner_Table -GroupBy @{ Name = "Device$(If (@($_).Count -ne 1) { "s" })"; Expression = { "$($_.DeviceName -join ', ') [$(($Variables.Devices | Where-Object Name -eq $_.DeviceName).Model -join ', ')]" } } | Out-Host

                #Display benchmarking progress
                If ($MinersDeviceGroupNeedingBenchmark) { 
                    "Benchmarking for device$(If (($MinersDeviceGroup | Select-Object -Unique).Count -ne 1) { " group" } ) ($(($MinersDeviceGroup.DeviceName | Select-Object -Unique ) -join '; ')) in progress: $($MinersDeviceGroupNeedingBenchmark.Count) miner$(If ($MinersDeviceGroupNeedingBenchmark.Count -gt 1){ 's' }) left to complete benchmark." | Out-host
                }
                #Display power usage measurement progress
                If ($MinersDeviceGroupNeedingPowerUsageMeasurement) { 
                    "Power usage measurement for device$(If (($MinersDeviceGroup | Select-Object -Unique).Count -ne 1) { " group" } ) ($(($MinersDeviceGroup.DeviceName | Select-Object -Unique ) -join '; ')) in progress: $($MinersDeviceGroupNeedingPowerUsageMeasurement.Count) miner$(If ($MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 1) { 's' }) left to complete measuring." | Out-Host
                }
            }

            Write-Host "`n"

            If ($ProcessesRunning = @($Variables.Miners | Where-Object { $_.Status -eq "Running" })) { 
                Write-Host "Running miner$(If ($ProcessesRunning.Count -ne 1) { "s"}): $($ProcessesRunning.Count)" 
                $ProcessesRunning | Sort-Object { If ($null -eq $_.Process) { [DateTime]0 } Else { $_.Process.StartTime } } | Format-Table -Wrap (
                    @{ Label = "Speed(s)"; Expression = { If ($_.Speed_Live) { (($_.Speed_Live | ForEach-Object { "$($_ | ConvertTo-Hash)/s" }) -join ' & ' ) -replace '\s+', ' ' } Else { "n/a" } }; Align = 'right' }, 
                    @{ Label = "PowerUsage"; Expression = { If ($_.PowerUsage_Live) { "$($_.PowerUsage_Live.ToString("N2")) W" } Else { "n/a" } }; Align = 'right' }, 
                    @{ Label = "Active (this run)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f ($_.Active) } }, 
                    @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f ($_.GetActiveTime()) } }, 
                    @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                    @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                ) | Out-Host
            }

            If ($Config.UIStyle -eq "Full") { 
                If ($ProcessesIdle = @($Variables.Miners | Where-Object { $_.Activated -and $_.Status -eq "Idle" })) { 
                    Write-Host "Previously executed miner$(If ($ProcessesIdle.Count -ne 1) { "s"}):"
                    $ProcessesIdle | Sort-Object { $_.Process.StartTime } -Descending | Select-Object -First ($MinersDeviceGroup.Count * 3) | Format-Table -Wrap (
                        @{ Label = "Speed(s)"; Expression = { (($_.Workers.Speed | ForEach-Object { If (-not [Double]::IsNaN($_)) { "$($_ | ConvertTo-Hash)/s" } Else { "n/a" } }) -join ' & ' ) -replace '\s+', ' ' }; Align = 'right' }, 
                        @{ Label = "PowerUsage"; Expression = { If (-not [Double]::IsNaN($_.PowerUsage)) { "$($_.PowerUsage.ToString("N2")) W" } Else { "n/a" } }; Align = 'right' }, 
                        @{ Label = "Time since run"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $((Get-Date) - $_.GetActiveLast().ToLocalTime()) } }, 
                        @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $_.GetActiveTime() } }, 
                        @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                        @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                    ) | Out-Host
                }

                If ($ProcessesFailed = @($Variables.Miners | Where-Object { $_.Activated -and $_.Status -eq "Failed" })) { 
                    Write-Host -ForegroundColor Red "Failed miner$(If ($ProcessesFailed.Count -ne 1) { "s"}): $($ProcessesFailed.Count)"
                    $ProcessesFailed | Sort-Object { If ($null -eq $_.Process) { [DateTime]0 } Else { $_.Process.StartTime } } | Format-Table -Wrap (
                        @{ Label = "Speed(s)"; Expression = { (($_.Workers.Speed | ForEach-Object { If (-not [Double]::IsNaN($_)) { "$($_ | ConvertTo-Hash)/s" } Else { "n/a" } }) -join ' & ' ) -replace '\s+', ' ' }; Align = 'right' }, 
                        @{ Label = "PowerUsage"; Expression = { If (-not [Double]::IsNaN($_.PowerUsage)) { "$($_.PowerUsage.ToString("N2")) W" } Else { "n/a" } }; Align = 'right' }, 
                        @{ Label = "Time since fail"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $((Get-Date) - $_.GetActiveLast().ToLocalTime()) } }, 
                        @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $_.GetActiveTime() } }, 
                        @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                        @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                    ) | Out-Host
                }
            }

            Remove-Variable SortBy
            Remove-Variable MinersDeviceGroup -ErrorAction SilentlyContinue
            Remove-Variable MinersDeviceGroupNeedingBenchmark -ErrorAction SilentlyContinue
            Remove-Variable MinersDeviceGroupNeedingPowerUsageMeasurement -ErrorAction SilentlyContinue
            Remove-Variable Miner_Table -ErrorAction SilentlyContinue

            If ($Config.Watchdog -eq $true) { 
                Write-Host "Watchdog Timers"
                #Display watchdog timers
                $Variables.WatchdogTimers | Where-Object Kicked -GT $Variables.Timer.AddSeconds( -$Variables.WatchdogReset) | Format-Table -Wrap (
                    @{Label = "Miner"; Expression = { $_.MinerName } }, 
                    @{Label = "Pool"; Expression = { $_.PoolName } }, 
                    @{Label = "Algorithm"; Expression = { $_.Algorithm } }, 
                    @{Label = "Device(s)"; Expression = { $_.DeviceName } }, 
                    @{Label = "Last Updated"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec ago" -f ((Get-Date).ToUniversalTime() - $_.Kicked) }; Align = 'right' }
                ) | Out-Host
            }

            If (-not $Variables.Paused) { 
                Write-Host "Profit, Earning & Power cost are in $($Config.Currency | Select-Object -Index 0)/day. Power cost: $($Config.Currency | Select-Object -Index 0) $(($Variables.PowerPricekWh).ToString("N$(Get-DigitsFromValue -Value $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0) -Offset 1)"))/kWh; Mining power cost: $($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value ($Variables.MiningPowerCost) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 1)/day; Base power cost: $($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value ($Variables.BasePowerCost) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 1)/day."

                If ($Variables.Miners | Where-Object Available -EQ $true | Where-Object { $_.Benchmark -eq $false -or $_.MeasurePowerUsage -eq $false }) { 
                    If ($Variables.MiningEarning -lt $Variables.MiningPowerCost) { 
                        #Mining causes a loss
                        Write-Host -ForegroundColor Red "Mining is currently NOT profitable and causes a loss of $($Config.Currency | Select-Object -Index 0) $((($Variables.MiningProfit - $Variables.BasePowerCost) * $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)).ToString("N$(Get-DigitsFromValue -Value $Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0) -Offset 1)"))/day (including Base Power Cost)."
                    }
                    If (($Variables.MiningEarning - $Variables.MiningPowerCost) -lt $Config.ProfitabilityThreshold) { 
                        #Mining profit is below the configured threshold
                        Write-host -ForegroundColor Blue "Mining profit ($($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value ($Variables.MiningProfit - $Variables.BasePowerCost) -BTCRate ($Variables.Rates."BTC".($Config.Currency | Select-Object -Index 0)) -Offset 1)) is below the configured threshold of $($Config.Currency | Select-Object -Index 0) $($Config.ProfitabilityThreshold.ToString("N$((Get-Culture).NumberFormat.CurrencyDecimalDigits)"))/day; mining is suspended until threshold is reached."
                    }
                }
            }

            Write-Host "--------------------------------------------------------------------------------"
            Write-Host -ForegroundColor Yellow "Last refresh: $((Get-Date).ToString('G'))   |   Next refresh: $(($Variables.EndLoopTime).ToString('G'))"
        }

        If (Test-Path "..\EndUIRefresh.ps1" -PathType Leaf) { Invoke-Expression (Get-Content "..\EndUIRefresh.ps1" -Raw) }
        $Variables.RefreshNeeded = $false
    }
    $TimerUI.Start()
}

Function Form_Load { 
    $MainForm.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion)"
    $LabelBTCD.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion)"
    $MainForm.Number = 0
    $TimerUI.Add_Tick(
        { 
            # Timer never disposes objects until it is disposed
            $MainForm.Number += 1
            $TimerUI.Stop()
            TimerUITick
            If ($MainForm.Number -gt 6000) { 
                $MainForm.Number = 0
                $TimerUI.Remove_Tick({ TimerUITick })
                $TimerUI.Dispose()
                $TimerUI = New-Object System.Windows.Forms.Timer
                $TimerUI.Add_Tick({ TimerUITick })
            }
            $TimerUI.Start()
        }
    )
    $TimerUI.Interval = 50
    $TimerUI.Stop()
        
    If ($CheckBoxConsole.Checked) { 
        $null = $ShowWindow::ShowWindowAsync($ConsoleHandle, 0)
        Write-Message "Console window hidden"
    }
    Else { 
        $null = $ShowWindow::ShowWindowAsync($ConsoleHandle, 8)
        # Write-Message "Console window shown"
    }
    $TimerUI.Enabled = $true
}

Function CheckedListBoxPools_Click ($Control) { 
    If ($Control.SelectedItem -in $Control.CheckedItems) { 
        $Control.CheckedItems | Where-Object { $_ -ne $Control.SelectedItem -and ($_ -replace "24hr" -replace "Coins") -like "$($Control.SelectedItem -replace "24hr" -replace "Coins")" } | ForEach-Object { 
            $Control.SetItemChecked($Control.Items.IndexOf($_), $false)
        }
    }
}

Function PrepareWriteConfig { 
    If ($Config.ManualConfig) {
        Write-Message "Manual config mode - not saving config."
        Return
    }
    If ($Config -isnot [Hashtable]) { 
        New-Variable Config ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
    }
    $Config.Wallet = $TBAddress.Text
    $Config.WorkerName = $TBWorkerName.Text
    $ConfigPageControls | Where-Object { (($_.GetType()).Name -eq "CheckBox") } | ForEach-Object { 
        $Config.($_.Tag) = $_.Checked
    }
    $ConfigPageControls | Where-Object { (($_.GetType()).Name -eq "NumericUpDown") } | ForEach-Object { 
        $Config.($_.Tag) = [Int]$_.Text -as $Config.($_.Tag).GetType()
    }
    $ConfigPageControls | Where-Object { (($_.GetType()).Name -eq "TextBox") } | ForEach-Object { 
        $Config.($_.Tag) = $_.Text
    }
    $ConfigPageControls | Where-Object { (($_.GetType()).Name -eq "TextBox") -and ($_.Tag -eq "Algorithm") } | ForEach-Object { 
        $Config.($_.Tag) = @($_.Text -split ",")
    }
    $Config.($CheckedListBoxPools.Tag) = $CheckedListBoxPools.CheckedItems
    $Config.Currency = @($Config.Currency -replace ' ' -split ',')
    $Config.Region = $LBRegion.Text

    $MonitoringSettingsControls | Where-Object { (($_.GetType()).Name -eq "CheckBox") } | ForEach-Object { $Config.($_.Tag) = $_.Checked }
    $MonitoringSettingsControls | Where-Object { (($_.GetType()).Name -eq "TextBox") } | ForEach-Object { $Config.($_.Tag) = $_.Text }

    $Variables.FreshConfig = $false

    $MainForm.Refresh
    # [System.Windows.Forms.Messagebox]::show("Please restart NemosMiner",'Config saved','ok','Information') | Out-Null
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$MainForm = New-Object System.Windows.Forms.Form
$NMIcon = New-Object system.drawing.icon ("$($PWD)\Includes\NM.ICO")
$MainForm.Icon = $NMIcon
$MainForm.ClientSize = [System.Drawing.Size]::new(740, 463) # best to keep under 800,600
$MainForm.Text = "Form"
$MainForm.TopMost = $false
$MainForm.FormBorderStyle = 'Fixed3D'
$MainForm.MaximizeBox = $false
If ($Config.StartGUIMinimized) { $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized }

$MainForm.Add_Shown(
    { 
        # Check if new version is available
        Get-NMVersion

        # TimerCheckVersion
        $TimerCheckVersion = New-Object System.Windows.Forms.Timer
        $TimerCheckVersion.Enabled = $true
        $TimerCheckVersion.Interval = 700 * 60 * 1000
        $TimerCheckVersion.Add_Tick(
            { 
                Get-NMVersion
            }
        )
    }
)

$MainForm.Add_FormClosing(
    { 
        $TimerUI.Stop()

        Stop-Mining
        Stop-IdleMining
        Stop-BrainJob
        Stop-BalancesTracker
    }
)

$MainForm | Add-Member -Name "Variables" -Value $Variables -MemberType NoteProperty -Force

$Variables.StatusText = "Idle"
$RunPage = New-Object System.Windows.Forms.TabPage
$RunPage.Text = "Run"
$Global:EarningsPage = New-Object System.Windows.Forms.TabPage
$Global:EarningsPage.Text = "Earnings"
$SwitchingPage = New-Object System.Windows.Forms.TabPage
$SwitchingPage.Text = "Switching"
$ConfigPage = New-Object System.Windows.Forms.TabPage
$ConfigPage.Text = "Config"
$MonitoringPage = New-Object System.Windows.Forms.TabPage
$MonitoringPage.Text = "Monitoring"
$EstimationsPage = New-Object System.Windows.Forms.TabPage
$EstimationsPage.Text = "Benchmarks"

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.DataBindings.DefaultDataSourceUpdateMode = 0
$TabControl.Location = [System.Drawing.Point]::new(10, 91)
$TabControl.Name = "TabControl"
$TabControl.Width = 722
$TabControl.Height = 363
$TabControl.Controls.AddRange(@($RunPage, $Global:EarningsPage, $SwitchingPage, $ConfigPage, $MonitoringPage, $EstimationsPage))
If ($Variables.FreshConfig -eq $true) { $TabControl.SelectedIndex = 3 } #Show config tab

$TabControl_SelectedIndexChanged = {
    Switch ($TabControl.SelectedTab.Text) { 
        "Earnings"  { Get-Chart }
        "Switching" { CheckBoxSwitching_Click }
    }
}
$TabControl.Add_SelectedIndexChanged($TabControl_SelectedIndexChanged)

$MainForm.Controls.Add($TabControl)

# Form Controls
$MainFormControls = @()

#tooltip
$ToolTip = New-Object System.Windows.Forms.ToolTip
$ShowHelp = { 
    #display popup help
    #each value is the name of a control on the form. 
    Switch ($this) {
        $CheckedListBoxPools { $Hint = "You cannot select multiple variants of the same pool" }
        $LabelCurrency { $Hint = "You can define multiple currencies, if so separate values with commas." }
        $TBCurrency { $Hint = "You can define multiple currencies, if so separate values with commas." }
        $NumudDonate { $Hint = "Donation duration in minutes per day. Donation start time is randomized.`nLeaving donation on helps to the developers to further support this project." }
        $LabelDonate { $Hint = "Donation duration in minutes per day. Donation start time is randomized.`nLeaving donation on helps to the developers to further support this project." }
    }
    $ToolTip.SetToolTip($this, $Hint)
} #end ShowHelp

# $Logo = [System.Drawing.Image]::Fromfile('.\config\logo.png')
$PictureBoxLogo = New-Object Windows.Forms.PictureBox
$PictureBoxLogo.Width = 47 #$img.Size.Width
$PictureBoxLogo.Height = 47 #$img.Size.Height
# $PictureBoxLogo.Image = $Logo
$PictureBoxLogo.SizeMode = 1
$PictureBoxLogo.ImageLocation = $Branding.LogoPath
$MainFormControls += $PictureBoxLogo

$LabelEarningsDetails = New-Object System.Windows.Forms.TextBox
$LabelEarningsDetails.Tag = ""
$LabelEarningsDetails.MultiLine = $true
$LabelEarningsDetails.Text = ""
$LabelEarningsDetails.AutoSize = $false
$LabelEarningsDetails.Width = 332
$LabelEarningsDetails.Height = 47 #62
$LabelEarningsDetails.Location = [System.Drawing.Point]::new(57, 2)
$LabelEarningsDetails.Font = [System.Drawing.Font]::new("Lucida Console", 10)
$LabelEarningsDetails.BorderStyle = 'None'
$LabelEarningsDetails.BackColor = [System.Drawing.SystemColors]::Control
$LabelEarningsDetails.ForeColor = [System.Drawing.Color]::Green
$LabelEarningsDetails.Visible = $true
$MainFormControls += $LabelEarningsDetails

$LabelBTCD = New-Object System.Windows.Forms.Label
$LabelBTCD.Text = "BTC/day"
$LabelBTCD.AutoSize = $false
$LabelBTCD.Width = 473
$LabelBTCD.Height = 35
$LabelBTCD.Location = [System.Drawing.Point]::new(247, 2)
$LabelBTCD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 14)
$LabelBTCD.TextAlign = "MiddleRight"
$LabelBTCD.ForeColor = [System.Drawing.Color]::Green
$LabelBTCD.BackColor = [System.Drawing.Color]::Transparent
$MainFormControls += $LabelBTCD

$LabelBTCPrice = New-Object System.Windows.Forms.Label
$LabelBTCPrice.Text = If ($Variables.Rates."BTC".$Currency -gt 0) { "BTC/$($Config.Currency | Select-Object -Index 0) $($Variables.Rates."BTC".$Currency)" }
$LabelBTCPrice.AutoSize = $false
$LabelBTCPrice.Width = 400
$LabelBTCPrice.Height = 20
$LabelBTCPrice.Location = [System.Drawing.Point]::new(510, 39)
$LabelBTCPrice.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 8)
$MainFormControls += $LabelBTCPrice

$ButtonStart = New-Object System.Windows.Forms.Button
$ButtonStart.Text = "Start"
$ButtonStart.Width = 60
$ButtonStart.Height = 30
$ButtonStart.Location = [System.Drawing.Point]::new(550, 62)
$ButtonStart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonStart.Visible = $true
$ButtonStart.Enabled = (-not $Config.Autostart)
$MainFormControls += $ButtonStart

$ButtonPause = New-Object System.Windows.Forms.Button
$ButtonPause.Text = "Pause"
$ButtonPause.Width = 60
$ButtonPause.Height = 30
$ButtonPause.Location = [System.Drawing.Point]::new(610, 62)
$ButtonPause.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonPause.Visible = $true
$ButtonPause.Enabled = $Config.Autostart
$MainFormControls += $ButtonPause

$ButtonStop = New-Object System.Windows.Forms.Button
$ButtonStop.Text = "Stop"
$ButtonStop.Width = 60
$ButtonStop.Height = 30
$ButtonStop.Location = [System.Drawing.Point]::new(670, 62)
$ButtonStop.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonStop.Visible = $true
$ButtonStop.Enabled = $Config.Autostart
$MainFormControls += $ButtonStop

$LabelNotifications = New-Object System.Windows.Forms.TextBox
$LabelNotifications.Tag = ""
$LabelNotifications.MultiLine = $true
$LabelNotifications.Text = ""
$LabelNotifications.AutoSize = $false
$LabelNotifications.Width = 280
$LabelNotifications.Height = 18
$LabelNotifications.Location = [System.Drawing.Point]::new(10, 49)
$LabelNotifications.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LabelNotifications.BorderStyle = 'None'
$LabelNotifications.BackColor = [System.Drawing.SystemColors]::Control
$LabelNotifications.Visible = $true
$MainFormControls += $LabelNotifications

$LabelAddress = New-Object System.Windows.Forms.Label
$LabelAddress.Text = "Wallet Address"
$LabelAddress.AutoSize = $false
$LabelAddress.Width = 100
$LabelAddress.Height = 20
$LabelAddress.Location = [System.Drawing.Point]::new(10, 68)
$LabelAddress.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MainFormControls += $LabelAddress

$TBAddress = New-Object System.Windows.Forms.TextBox
$TBAddress.Tag = "Wallet"
$TBAddress.MultiLine = $false
$TBAddress.Text = $Config.Wallet
$TBAddress.AutoSize = $false
$TBAddress.Width = 285
$TBAddress.Height = 20
$TBAddress.Location = [System.Drawing.Point]::new(115, 68)
$TBAddress.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MainFormControls += $TBAddress

# Run Page Controls
$RunPageControls = @()

$Variables | Add-Member @{ LabelStatus = New-Object System.Windows.Forms.TextBox }
$Variables.LabelStatus.MultiLine = $true
$Variables.LabelStatus.Scrollbars = "Vertical" 
$Variables.LabelStatus.Text = ""
$Variables.LabelStatus.AutoSize = $true
$Variables.LabelStatus.Width = 708
$Variables.LabelStatus.Height = 202
$Variables.LabelStatus.Location = [System.Drawing.Point]::new(2, 2)
$Variables.LabelStatus.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$RunPageControls += $Variables.LabelStatus

$LabelCopyright = New-Object System.Windows.Forms.LinkLabel
$LabelCopyright.Location = New-Object System.Drawing.Size(220, 214)
$LabelCopyright.Size = New-Object System.Drawing.Size(490, 16)
$LabelCopyright.LinkColor = [System.Drawing.Color]::Blue
$LabelCopyright.ActiveLinkColor = [System.Drawing.Color]::Blue
$LabelCopyright.TextAlign = "MiddleRight"
$LabelCopyright.Text = "Copyright (c) 2018-$((Get-Date).Year) Nemo, MrPlus && UselessGuru"
$LabelCopyright.Add_Click( { Start-Process "https://github.com/Minerx117/NemosMiner/blob/master/LICENSE" })
$RunPageControls += $LabelCopyright

$LabelRunningMiners = New-Object System.Windows.Forms.Label
$LabelRunningMiners.Text = "Running Miners"
$LabelRunningMiners.AutoSize = $false
$LabelRunningMiners.Width = 202
$LabelRunningMiners.Height = 16
$LabelRunningMiners.Location = [System.Drawing.Point]::new(2, 213)
$LabelRunningMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RunPageControls += $LabelRunningMiners

$RunningMinersDGV = New-Object System.Windows.Forms.DataGridView
$RunningMinersDGV.Width = 708
$RunningMinersDGV.Height = 100
$RunningMinersDGV.Location = [System.Drawing.Point]::new(2, 232)
$RunningMinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$RunningMinersDGV.AutoSizeColumnsMode = "Fill"
$RunningMinersDGV.RowHeadersVisible = $false
$RunningMinersDGV.AutoSizeColumnsMode = "AllCells"
$RunPageControls += $RunningMinersDGV

# Earnings Page Controls
$EarningsPageControls = @()

$LabelEarnings = New-Object System.Windows.Forms.Label
$LabelEarnings.Text = "Earnings statistics per pool"
$LabelEarnings.AutoSize = $false
$LabelEarnings.Width = 202
$LabelEarnings.Height = 16
$LabelEarnings.Location = [System.Drawing.Point]::new(2, 149)
$LabelEarnings.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$EarningsPageControls += $LabelEarnings

$EarningsDGV = New-Object System.Windows.Forms.DataGridView
$EarningsDGV.Width = 708
$EarningsDGV.Height = 165
$EarningsDGV.Location = [System.Drawing.Point]::new(2, 167)
$EarningsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EarningsDGV.AutoSizeColumnsMode = "Fill"
$EarningsDGV.RowHeadersVisible = $false
$EarningsPageControls += $EarningsDGV

# Switching Page Controls
$SwitchingPageControls = @()

$CheckShowSwitchingCPU = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingCPU.Tag = "CPU"
$CheckShowSwitchingCPU.Text = "CPU"
$CheckShowSwitchingCPU.AutoSize = $false
$CheckShowSwitchingCPU.Width = 60
$CheckShowSwitchingCPU.Height = 20
$CheckShowSwitchingCPU.Location = [System.Drawing.Point]::new(2, 2)
$CheckShowSwitchingCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$SwitchingPageControls += $CheckShowSwitchingCPU
$CheckShowSwitchingCPU | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingNVIDIA = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingNVIDIA.Tag = "NVIDIA"
$CheckShowSwitchingNVIDIA.Text = "NVIDIA"
$CheckShowSwitchingNVIDIA.AutoSize = $false
$CheckShowSwitchingNVIDIA.Width = 70
$CheckShowSwitchingNVIDIA.Height = 20
$CheckShowSwitchingNVIDIA.Location = [System.Drawing.Point]::new(62, 2)
$CheckShowSwitchingNVIDIA.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$SwitchingPageControls += $CheckShowSwitchingNVIDIA
$CheckShowSwitchingNVIDIA | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingAMD = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingAMD.Tag = "AMD"
$CheckShowSwitchingAMD.Text = "AMD"
$CheckShowSwitchingAMD.AutoSize = $false
$CheckShowSwitchingAMD.Width = 100
$CheckShowSwitchingAMD.Height = 20
$CheckShowSwitchingAMD.Location = [System.Drawing.Point]::new(137, 2)
$CheckShowSwitchingAMD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$SwitchingPageControls += $CheckShowSwitchingAMD
$CheckShowSwitchingAMD | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($this) }) }

Function CheckBoxSwitching_Click { 
    If (-not $SwitchingDGV.DataSource) { 
        $CheckShowSwitchingAMD.Checked = ($Variables.Devices | Where-Object { $_.State -EQ [DeviceState]::Enabled } | Where-Object Type -EQ "GPU" | Where-Object Vendor -EQ "AMD")
        $CheckShowSwitchingCPU.Checked = ($Variables.Devices | Where-Object { $_.State -EQ [DeviceState]::Enabled } | Where-Object Name -like "CPU#*")
        $CheckShowSwitchingNVIDIA.Checked = ($Variables.Devices | Where-Object { $_.State -EQ [DeviceState]::Enabled } | Where-Object Type -EQ "GPU"| Where-Object Vendor -EQ "NVIDIA")
    }
    $SwitchingDisplayTypes = @()
    $SwitchingPageControls | ForEach-Object { If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } }
    If (Test-Path ".\Logs\switching.log") { $Variables.SwitchingLog = @(Get-Content ".\Logs\switching.log" | ConvertFrom-Csv | Select-Object -Last 1000); [Array]::Reverse($Variables.SwitchingLog) }
    $SwitchingDGV.DataSource = [System.Collections.ArrayList]($Variables.SwitchingLog | Where-Object { $_.Type -in $SwitchingDisplayTypes })
}

$SwitchingDGV = New-Object System.Windows.Forms.DataGridView
$SwitchingDGV.Width = 708
$SwitchingDGV.Height = 310
$SwitchingDGV.Location = [System.Drawing.Point]::new(2, 22)
$SwitchingDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$SwitchingDGV.AutoSizeColumnsMode = "Fill"
$SwitchingDGV.RowHeadersVisible = $false
$SwitchingDGV.AutoSizeColumnsMode = "DisplayedCells"
$SwitchingPageControls += $SwitchingDGV

# Estimations Page Controls
$EstimationsDGV = New-Object System.Windows.Forms.DataGridView
$EstimationsDGV.Width = 708
$EstimationsDGV.Height = 330
$EstimationsDGV.Location = [System.Drawing.Point]::new(2, 2)
$EstimationsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EstimationsDGV.AutoSizeColumnsMode = "Fill"
$EstimationsDGV.RowHeadersVisible = $false
$EstimationsDGV.ColumnHeadersVisible = $true
$EstimationsDGV.AutoSizeColumnsMode = "DisplayedCells"

# Config Page Controls
$ConfigPageControls = @()

$LabelWorkerName = New-Object System.Windows.Forms.Label
$LabelWorkerName.Text = "Worker Name"
$LabelWorkerName.AutoSize = $false
$LabelWorkerName.Width = 132
$LabelWorkerName.Height = 20
$LabelWorkerName.Location = [System.Drawing.Point]::new(2, 2)
$LabelWorkerName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelWorkerName

$TBWorkerName = New-Object System.Windows.Forms.TextBox
$TBWorkerName.Tag = "WorkerName"
$TBWorkerName.MultiLine = $false
$TBWorkerName.Text = $Config.WorkerName
$TBWorkerName.AutoSize = $false
$TBWorkerName.Width = 285
$TBWorkerName.Height = 20
$TBWorkerName.Location = [System.Drawing.Point]::new(135, 2)
$TBWorkerName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBWorkerName

$LabelMPHUserName = New-Object System.Windows.Forms.Label
$LabelMPHUserName.Text = "MPH UserName"
$LabelMPHUserName.AutoSize = $false
$LabelMPHUserName.Width = 132
$LabelMPHUserName.Height = 20
$LabelMPHUserName.Location = [System.Drawing.Point]::new(2, 25)
$LabelMPHUserName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelMPHUserName

$TBMPHUserName = New-Object System.Windows.Forms.TextBox
$TBMPHUserName.Tag = "UserName"
$TBMPHUserName.MultiLine = $false
$TBMPHUserName.Text = $Config.MPHUserName
$TBMPHUserName.AutoSize = $false
$TBMPHUserName.Width = 285
$TBMPHUserName.Height = 20
$TBMPHUserName.Location = [System.Drawing.Point]::new(135, 25)
$TBMPHUserName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBMPHUserName

$LabelMPHAPIKey = New-Object System.Windows.Forms.Label
$LabelMPHAPIKey.Text = "MPH API Key"
$LabelMPHAPIKey.AutoSize = $false
$LabelMPHAPIKey.Width = 132
$LabelMPHAPIKey.Height = 20
$LabelMPHAPIKey.Location = [System.Drawing.Point]::new(2, 48)
$LabelMPHAPIKey.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelMPHAPIKey

$TBMPHAPIKey = New-Object System.Windows.Forms.TextBox
$TBMPHAPIKey.Tag = "MPHAPIKey"
$TBMPHAPIKey.MultiLine = $false
$TBMPHAPIKey.Text = $Config.MPHAPIKey
$TBMPHAPIKey.AutoSize = $false
$TBMPHAPIKey.Width = 285
$TBMPHAPIKey.Height = 20
$TBMPHAPIKey.Location = [System.Drawing.Point]::new(135, 48)
$TBMPHAPIKey.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBMPHAPIKey

$LabelInterval = New-Object System.Windows.Forms.Label
$LabelInterval.Text = "Interval"
$LabelInterval.AutoSize = $false
$LabelInterval.Width = 132
$LabelInterval.Height = 20
$LabelInterval.Location = [System.Drawing.Point]::new(2, 71)
$LabelInterval.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelInterval

$NumudInterval = New-Object System.Windows.Forms.NumericUpDown
$NumudInterval.DecimalPlaces = 0
$NumudInterval.Minimum = 30
$NumudInterval.Maximum = 3600
$NumudInterval.Tag = "Interval"
$NumudInterval.Text = $Config.Interval
$NumudInterval.AutoSize = $false
$NumudInterval.Width = 285
$NumudInterval.Height = 20
$NumudInterval.Location = [System.Drawing.Point]::new(135, 71)
$NumudInterval.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $NumudInterval

$LabelLocation = New-Object System.Windows.Forms.Label
$LabelLocation.Text = "Region"
$LabelLocation.AutoSize = $false
$LabelLocation.Width = 132
$LabelLocation.Height = 20
$LabelLocation.Location = [System.Drawing.Point]::new(2, 94)
$LabelLocation.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelLocation

$LBRegion = New-Object System.Windows.Forms.ListBox
$LBRegion.Tag = "Region"
$Regions = (Get-Content ".\Includes\Regions.txt" | ConvertFrom-Json).PSObject.Properties.Value | Sort-Object -Unique 
$Regions | ForEach-Object { 
    [void] $LBRegion.Items.Add($_)
}
$LBRegion.SelectedItem = $Config.Region
$LBRegion.AutoSize = $false
$LBRegion.Sorted = $true
$LBRegion.Width = 285
$LBRegion.Height = 20
$LBRegion.Location = [System.Drawing.Point]::new(135, 94)
$LBRegion.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LBRegion

$LabelAlgos = New-Object System.Windows.Forms.Label
$LabelAlgos.Text = "Algorithm"
$LabelAlgos.AutoSize = $false
$LabelAlgos.Width = 132
$LabelAlgos.Height = 20
$LabelAlgos.Location = [System.Drawing.Point]::new(2, 117)
$LabelAlgos.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelAlgos

$TBAlgos = New-Object System.Windows.Forms.TextBox
$TBAlgos.Tag = "Algorithm"
$TBAlgos.MultiLine = $false
$TBAlgos.Text = $Config.Algorithm -Join ","
$TBAlgos.AutoSize = $false
$TBAlgos.Width = 285
$TBAlgos.Height = 20
$TBAlgos.Location = [System.Drawing.Point]::new(135, 117)
$TBAlgos.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBAlgos

$LabelCurrency = New-Object System.Windows.Forms.Label
$LabelCurrency.Text = "Currencies"
$LabelCurrency.AutoSize = $false
$LabelCurrency.Width = 132
$LabelCurrency.Height = 20
$LabelCurrency.Location = [System.Drawing.Point]::new(2, 140)
$LabelCurrency.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LabelCurrency.Add_MouseHover($ShowHelp)
$ConfigPageControls += $LabelCurrency

$TBCurrency = New-Object System.Windows.Forms.TextBox
$TBCurrency.Tag = "Currency"
$TBCurrency.MultiLine = $false
$TBCurrency.Text = @($Config.Currency -join ', ')
$TBCurrency.AutoSize = $false
$TBCurrency.Width = 285
$TBCurrency.Height = 20
$TBCurrency.Location = [System.Drawing.Point]::new(135, 140)
$TBCurrency.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$TBCurrency.Add_MouseHover($ShowHelp)
$ConfigPageControls += $TBCurrency

$LabelPwdCurrency = New-Object System.Windows.Forms.Label
$LabelPwdCurrency.Text = "Password Currency"
$LabelPwdCurrency.AutoSize = $false
$LabelPwdCurrency.Width = 132
$LabelPwdCurrency.Height = 20
$LabelPwdCurrency.Location = [System.Drawing.Point]::new(2, 163)
$LabelPwdCurrency.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelPwdCurrency

$TBPwdCurrency = New-Object System.Windows.Forms.TextBox
$TBPwdCurrency.Tag = "PasswordCurrency"
$TBPwdCurrency.MultiLine = $false
$TBPwdCurrency.Text = $Config.PasswordCurrency
$TBPwdCurrency.AutoSize = $false
$TBPwdCurrency.Width = 285
$TBPwdCurrency.Height = 20
$TBPwdCurrency.Location = [System.Drawing.Point]::new(135, 163)
$TBPwdCurrency.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBPwdCurrency

$LabelDonate = New-Object System.Windows.Forms.Label
$LabelDonate.Text = "Donate"
$LabelDonate.AutoSize = $false
$LabelDonate.Width = 132
$LabelDonate.Height = 20
$LabelDonate.Location = [System.Drawing.Point]::new(2, 186)
$LabelDonate.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LabelDonate.Add_MouseHover($ShowHelp)
$ConfigPageControls += $LabelDonate

$NumudDonate = New-Object System.Windows.Forms.NumericUpDown
$NumudDonate.DecimalPlaces = 0
$NumudDonate.Minimum = 0
$NumudDonate.Maximum = 1440
$NumudDonate.Tag = "Donate"
$NumudDonate.Text = $Config.Donate
$NumudDonate.AutoSize = $false
$NumudDonate.Width = 285
$NumudDonate.Height = 20
$NumudDonate.Location = [System.Drawing.Point]::new(135, 186)
$NumudDonate.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$NumudDonate.Add_MouseHover($ShowHelp)
$ConfigPageControls += $NumudDonate

$LabelProxy = New-Object System.Windows.Forms.Label
$LabelProxy.Text = "Proxy"
$LabelProxy.AutoSize = $false
$LabelProxy.Width = 132
$LabelProxy.Height = 20
$LabelProxy.Location = [System.Drawing.Point]::new(2, 209)
$LabelProxy.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelProxy

$TBProxy = New-Object System.Windows.Forms.TextBox
$TBProxy.Tag = "Proxy"
$TBProxy.MultiLine = $false
$TBProxy.Text = $Config.Proxy
$TBProxy.AutoSize = $false
$TBProxy.Width = 285
$TBProxy.Height = 20
$TBProxy.Location = [System.Drawing.Point]::new(135, 209)
$TBProxy.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBProxy

$LabelRunningMinerGainPct = New-Object System.Windows.Forms.Label
$LabelRunningMinerGainPct.Text = "RunningMinerGain%"
$LabelRunningMinerGainPct.AutoSize = $false
$LabelRunningMinerGainPct.Width = 132
$LabelRunningMinerGainPct.Height = 20
$LabelRunningMinerGainPct.Location = [System.Drawing.Point]::new(2, 232)
$LabelRunningMinerGainPct.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelRunningMinerGainPct

$NumudRunningMinerGainPct = New-Object System.Windows.Forms.NumericUpDown
$NumudRunningMinerGainPct.DecimalPlaces = 0
$NumudRunningMinerGainPct.Minimum = 0
$NumudRunningMinerGainPct.Maximum = 100
$NumudRunningMinerGainPct.Tag = "RunningMinerGainPct"
$NumudRunningMinerGainPct.Text = $Config.RunningMinerGainPct
$NumudRunningMinerGainPct.AutoSize = $false
$NumudRunningMinerGainPct.Width = 285
$NumudRunningMinerGainPct.Height = 20
$NumudRunningMinerGainPct.Location = [System.Drawing.Point]::new(135, 232)
$NumudRunningMinerGainPct.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $NumudRunningMinerGainPct

$LabelMinersTypes = New-Object System.Windows.Forms.Label
$LabelMinersTypes.Text = "Mining Devices"
$LabelMinersTypes.AutoSize = $false
$LabelMinersTypes.Width = 132
$LabelMinersTypes.Height = 20
$LabelMinersTypes.Location = [System.Drawing.Point]::new(2, 258)
$LabelMinersTypes.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelMinersTypes

$LabelGuiDevices = New-Object System.Windows.Forms.LinkLabel
$LabelGuiDevices.Location = New-Object System.Drawing.Size(2, 281)
$LabelGuiDevices.Size = New-Object System.Drawing.Size(370, 20)
$LabelGuiDevices.LinkColor = [System.Drawing.Color]::Blue
$LabelGuiDevices.ActiveLinkColor = [System.Drawing.Color]::Blue
$LabelGuiDevices.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LabelGuiDevices.TextAlign = "MiddleLeft"
$LabelGuiDevices.Text = "To enable / disable mining devices use the Web GUI"
$LabelGuiDevices.Add_Click( { Start-Process "http://localhost:$($Config.APIPort)/devices.html" })
$ConfigPageControls += $LabelGuiDevices

$CheckBoxAutostart = New-Object System.Windows.Forms.CheckBox
$CheckBoxAutostart.Tag = "Autostart"
$CheckBoxAutostart.Text = "Auto Start"
$CheckBoxAutostart.AutoSize = $false
$CheckBoxAutostart.Width = 100
$CheckBoxAutostart.Height = 20
$CheckBoxAutostart.Location = [System.Drawing.Point]::new(560, 2)
$CheckBoxAutostart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxAutostart.Checked = $Config.AutoStart
$ConfigPageControls += $CheckBoxAutostart

$CheckBoxStartPaused = New-Object System.Windows.Forms.CheckBox
$CheckBoxStartPaused.Tag = "StartPaused"
$CheckBoxStartPaused.Text = "Pause on Auto Start"
$CheckBoxStartPaused.AutoSize = $false
$CheckBoxStartPaused.Width = 160
$CheckBoxStartPaused.Height = 20
$CheckBoxStartPaused.Location = [System.Drawing.Point]::new(560, 24)
$CheckBoxStartPaused.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxStartPaused.Checked = $Config.StartPaused
$CheckBoxStartPaused.Enabled = $CheckBoxAutoStart.Checked
$ConfigPageControls += $CheckBoxStartPaused

$CheckBoxAutoStart.Add_Click(
    { 
        # Disable CheckBoxStartPaused and mine when idle when Auto Start is unchecked
        If ($CheckBoxAutoStart.Checked) { 
            $CheckBoxStartPaused.Enabled = $true
            $CheckBoxMineWhenIdle.Enabled = $true
            If ($CheckBoxMineWhenIdle.Checked) { 
                $NumudIdleSec.Enabled = $true
            }
            Else { 
                $NumudIdleSec.Enabled = $false
            }
        }
        Else { 
            $CheckBoxStartPaused.Checked = $false
            $CheckBoxStartPaused.Enabled = $false
            $CheckBoxMineWhenIdle.Checked = $false
            $CheckBoxMineWhenIdle.Enabled = $false
            $NumudIdleSec.Enabled = $false
        }
    }
)

$CheckBoxMineWhenIdle = New-Object System.Windows.Forms.CheckBox
$CheckBoxMineWhenIdle.Tag = "MineWhenIdle"
$CheckBoxMineWhenIdle.Text = "Mine only when idle"
$CheckBoxMineWhenIdle.AutoSize = $false
$CheckBoxMineWhenIdle.Width = 160
$CheckBoxMineWhenIdle.Height = 20
$CheckBoxMineWhenIdle.Location = [System.Drawing.Point]::new(560, 46)
$CheckBoxMineWhenIdle.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxMineWhenIdle.Checked = $Config.MineWhenIdle
$CheckBoxMineWhenIdle.Enabled = $CheckBoxAutoStart.Checked
$ConfigPageControls += $CheckBoxMineWhenIdle

$LabelIdleSec = New-Object System.Windows.Forms.Label
$LabelIdleSec.Text = "seconds"
$LabelIdleSec.AutoSize = $false
$LabelIdleSec.Width = 60
$LabelIdleSec.Height = 20
$LabelIdleSec.Location = [System.Drawing.Point]::new(630, 68)
$LabelIdleSec.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelIdleSec

If ($Config.IdleSec -lt 0) { $Config.IdleSec = [Int]120 }
$NumudIdleSec = New-Object System.Windows.Forms.NumericUpDown
$NumudIdleSec.DecimalPlaces = 0
$NumudIdleSec.Minimum = 5
$NumudIdleSec.Maximum = 3600
$NumudIdleSec.Tag = "IdleSec"
$NumudIdleSec.Text = $Config.IdleSec
$NumudIdleSec.AutoSize = $false
$NumudIdleSec.Width = 50
$NumudIdleSec.Height = 20
$NumudIdleSec.Location = [System.Drawing.Point]::new(580, 68)
$NumudIdleSec.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$NumudIdleSec.Enabled = $CheckBoxMineWhenIdle.Checked
$ConfigPageControls += $NumudIdleSec

$CheckBoxMineWhenIdle.Add_Click(
    { 
        If ($CheckBoxMineWhenIdle.Checked) { 
            $NumudIdleSec.Enabled = $true
        }
        Else { 
            $NumudIdleSec.Enabled = $false
        }
    }
)

$CheckBoxEarningTrackerLogs = New-Object System.Windows.Forms.CheckBox
$CheckBoxEarningTrackerLogs.Tag = "EnableBalancesTrackerLog"
$CheckBoxEarningTrackerLogs.Text = "Earnings Tracker Logs"
$CheckBoxEarningTrackerLogs.AutoSize = $false
$CheckBoxEarningTrackerLogs.Width = 160
$CheckBoxEarningTrackerLogs.Height = 20
$CheckBoxEarningTrackerLogs.Location = [System.Drawing.Point]::new(560, 100)
$CheckBoxEarningTrackerLogs.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxEarningTrackerLogs.Checked = $Config.EnableBalancesTrackerLog
$ConfigPageControls += $CheckBoxEarningTrackerLogs

$CheckBoxGUIMinimized = New-Object System.Windows.Forms.CheckBox
$CheckBoxGUIMinimized.Tag = "StartGUIMinimized"
$CheckBoxGUIMinimized.Text = "Start UI minimized"
$CheckBoxGUIMinimized.AutoSize = $false
$CheckBoxGUIMinimized.Width = 160
$CheckBoxGUIMinimized.Height = 20
$CheckBoxGUIMinimized.Location = [System.Drawing.Point]::new(560, 122)
$CheckBoxGUIMinimized.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxGUIMinimized.Checked = $Config.StartGUIMinimized
$ConfigPageControls += $CheckBoxGUIMinimized

$CheckBoxAutoupdate = New-Object System.Windows.Forms.CheckBox
$CheckBoxAutoupdate.Tag = "Autoupdate"
$CheckBoxAutoupdate.Text = "Auto Update"
$CheckBoxAutoupdate.AutoSize = $true
$CheckBoxAutoupdate.Width = 100
$CheckBoxAutoupdate.Height = 20
$CheckBoxAutoupdate.Location = [System.Drawing.Point]::new(560, 144)
$CheckBoxAutoupdate.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxAutoupdate.Checked = $Config.Autoupdate
$ConfigPageControls += $CheckBoxAutoupdate

$CheckBoxIncludeRegularMiners = New-Object System.Windows.Forms.CheckBox
$CheckBoxIncludeRegularMiners.Tag = "IncludeRegularMiners"
$CheckBoxIncludeRegularMiners.Text = "Regular Miners"
$CheckBoxIncludeRegularMiners.AutoSize = $false
$CheckBoxIncludeRegularMiners.Width = 160
$CheckBoxIncludeRegularMiners.Height = 20
$CheckBoxIncludeRegularMiners.Location = [System.Drawing.Point]::new(560, 166)
$CheckBoxIncludeRegularMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxIncludeRegularMiners.Checked = $Config.IncludeRegularMiners
$ConfigPageControls += $CheckBoxIncludeRegularMiners

$CheckBoxIncludeOptionalMiners = New-Object System.Windows.Forms.CheckBox
$CheckBoxIncludeOptionalMiners.Tag = "IncludeOptionalMiners"
$CheckBoxIncludeOptionalMiners.Text = "Optional Miners"
$CheckBoxIncludeOptionalMiners.AutoSize = $false
$CheckBoxIncludeOptionalMiners.Width = 160
$CheckBoxIncludeOptionalMiners.Height = 20
$CheckBoxIncludeOptionalMiners.Location = [System.Drawing.Point]::new(560, 188)
$CheckBoxIncludeOptionalMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxIncludeOptionalMiners.Checked = $Config.IncludeOptionalMiners
$ConfigPageControls += $CheckBoxIncludeOptionalMiners

$ButtonLoadDefaultPoolsAlgos = New-Object System.Windows.Forms.Button
$ButtonLoadDefaultPoolsAlgos.Text = "Load default algos for selected pools"
$ButtonLoadDefaultPoolsAlgos.Width = 250
$ButtonLoadDefaultPoolsAlgos.Height = 30
$ButtonLoadDefaultPoolsAlgos.Location = [System.Drawing.Point]::new(358, 300)
$ButtonLoadDefaultPoolsAlgos.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $ButtonLoadDefaultPoolsAlgos

$ButtonLoadDefaultPoolsAlgos.Add_Click(
    { 
        $TBAlgos.Text = (Get-DefaultAlgorithm | ForEach-Object { "+$($_)" }) -Join ","
    }
)

$ButtonWriteConfig = New-Object System.Windows.Forms.Button
$ButtonWriteConfig.Text = "Save Config"
$ButtonWriteConfig.Width = 100
$ButtonWriteConfig.Height = 30
$ButtonWriteConfig.Location = [System.Drawing.Point]::new(610, 300)
$ButtonWriteConfig.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $ButtonWriteConfig

$ButtonWriteConfig.Add_Click( { 
    PrepareWriteConfig
    Write-Config -ConfigFile $Variables.ConfigFile
    $Variables.RestartCycle = $true
})

$LabelPoolsSelect = New-Object System.Windows.Forms.Label
$LabelPoolsSelect.Text = "Poolnames"
$LabelPoolsSelect.AutoSize = $false
$LabelPoolsSelect.Width = 130
$LabelPoolsSelect.Height = 20
$LabelPoolsSelect.Location = [System.Drawing.Point]::new(425, 2)
$LabelPoolsSelect.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LabelPoolsSelect.TextAlign = 'MiddleCenter'
$LabelPoolsSelect.BorderStyle = 'FixedSingle'
$ConfigPageControls += $LabelPoolsSelect

$CheckedListBoxPools = New-Object System.Windows.Forms.CheckedListBox
$CheckedListBoxPools.Tag = "PoolName"
$CheckedListBoxPools.Height = 230
$CheckedListBoxPools.Width = 130
$CheckedListBoxPools.Text = "Pools"
$CheckedListBoxPools.Location = [System.Drawing.Point]::new(425, 25)
$CheckedListBoxPools.CheckOnClick = $true
$CheckedListBoxPools.BackColor = [System.Drawing.SystemColors]::Control
$CheckedListBoxPools.Items.Clear()
$CheckedListBoxPools.Items.AddRange(((Get-ChildItem -File ".\Pools").BaseName | Sort-Object -Unique))
$CheckedListBoxPools.Add_MouseHover($ShowHelp)
$CheckedListBoxPools.Add_SelectedIndexChanged({ CheckedListBoxPools_Click($this) })
$Config.PoolName | Where-Object { $_ -in $CheckedListBoxPools.Items } | ForEach-Object { $CheckedListBoxPools.SetItemChecked((($CheckedListBoxPools.Items).ToUpper()).IndexOf($_.ToUpper()), $true) }

$ConfigPageControls += $CheckedListBoxPools

# Monitoring Page Controls
$MonitoringPageControls = @()
$MonitoringSettingsControls = @()

$LabelMonitoringWorkers = New-Object System.Windows.Forms.Label
$LabelMonitoringWorkers.Text = "Worker Status"
$LabelMonitoringWorkers.AutoSize = $false
$LabelMonitoringWorkers.Width = 708
$LabelMonitoringWorkers.Height = 18
$LabelMonitoringWorkers.Location = [System.Drawing.Point]::new(2, 4)
$LabelMonitoringWorkers.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringPageControls += $LabelMonitoringWorkers

$WorkersDGV = New-Object System.Windows.Forms.DataGridView
$WorkersDGV.Width = 708
$WorkersDGV.Height = 236
$WorkersDGV.Location = [System.Drawing.Point]::new(2, 22)
$WorkersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$WorkersDGV.AutoSizeColumnsMode = "AllCells"
$WorkersDGV.RowHeadersVisible = $false
$MonitoringPageControls += $WorkersDGV

$GroupMonitoringSettings = New-Object System.Windows.Forms.GroupBox
$GroupMonitoringSettings.Height = 70
$GroupMonitoringSettings.Width = 708
$GroupMonitoringSettings.Text = "Monitoring Settings"
$GroupMonitoringSettings.Location = [System.Drawing.Point]::new(1, 264)
$GroupMonitoringSettings.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringPageControls += $GroupMonitoringSettings

$LabelMonitoringServer = New-Object System.Windows.Forms.Label
$LabelMonitoringServer.Text = "Server"
$LabelMonitoringServer.AutoSize = $false
$LabelMonitoringServer.Width = 60
$LabelMonitoringServer.Height = 20
$LabelMonitoringServer.Location = [System.Drawing.Point]::new(2, 21)
$LabelMonitoringServer.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $LabelMonitoringServer

$TBMonitoringServer = New-Object System.Windows.Forms.TextBox
$TBMonitoringServer.Tag = "MonitoringServer"
$TBMonitoringServer.MultiLine = $false
$TBMonitoringServer.Text = $Config.MonitoringServer
$TBMonitoringServer.AutoSize = $false
$TBMonitoringServer.Width = 260
$TBMonitoringServer.Height = 20
$TBMonitoringServer.Location = [System.Drawing.Point]::new(62, 21)
$TBMonitoringServer.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $TBMonitoringServer

$CheckBoxReportToServer = New-Object System.Windows.Forms.CheckBox
$CheckBoxReportToServer.Tag = "ReportToServer"
$CheckBoxReportToServer.Text = "Report to server"
$CheckBoxReportToServer.AutoSize = $false
$CheckBoxReportToServer.Width = 130
$CheckBoxReportToServer.Height = 20
$CheckBoxReportToServer.Location = [System.Drawing.Point]::new(324, 21)
$CheckBoxReportToServer.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxReportToServer.Checked = $Config.ReportToServer
$MonitoringSettingsControls += $CheckBoxReportToServer

$CheckBoxShowWorkerStatus = New-Object System.Windows.Forms.CheckBox
$CheckBoxShowWorkerStatus.Tag = "ShowWorkerStatus"
$CheckBoxShowWorkerStatus.Text = "Show other workers"
$CheckBoxShowWorkerStatus.AutoSize = $false
$CheckBoxShowWorkerStatus.Width = 145
$CheckBoxShowWorkerStatus.Height = 20
$CheckBoxShowWorkerStatus.Location = [System.Drawing.Point]::new(456, 21)
$CheckBoxShowWorkerStatus.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxShowWorkerStatus.Checked = $Config.ShowWorkerStatus
$MonitoringSettingsControls += $CheckBoxShowWorkerStatus

$LabelMonitoringUser = New-Object System.Windows.Forms.Label
$LabelMonitoringUser.Text = "User ID"
$LabelMonitoringUser.AutoSize = $false
$LabelMonitoringUser.Width = 60
$LabelMonitoringUser.Height = 20
$LabelMonitoringUser.Location = [System.Drawing.Point]::new(2, 44)
$LabelMonitoringUser.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $LabelMonitoringUser

$TBMonitoringUser = New-Object System.Windows.Forms.TextBox
$TBMonitoringUser.Tag = "MonitoringUser"
$TBMonitoringUser.MultiLine = $false
$TBMonitoringUser.Text = $Config.MonitoringUser
$TBMonitoringUser.AutoSize = $false
$TBMonitoringUser.Width = 260
$TBMonitoringUser.Height = 20
$TBMonitoringUser.Location = [System.Drawing.Point]::new(62, 44)
$TBMonitoringUser.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $TBMonitoringUser

$ButtonGenerateMonitoringUser = New-Object System.Windows.Forms.Button
$ButtonGenerateMonitoringUser.Text = "Generate New User ID"
$ButtonGenerateMonitoringUser.Width = 160
$ButtonGenerateMonitoringUser.Height = 20
$ButtonGenerateMonitoringUser.Location = [System.Drawing.Point]::new(324, 44)
$ButtonGenerateMonitoringUser.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonGenerateMonitoringUser.Enabled = ($TBMonitoringUser.Text -eq "")
$MonitoringSettingsControls += $ButtonGenerateMonitoringUser

$ButtonGenerateMonitoringUser.Add_Click( { $TBMonitoringUser.Text = [GUID]::NewGuid() })
# Only enable the generate button when user is blank.
$TBMonitoringUser.Add_TextChanged( { $ButtonGenerateMonitoringUser.Enabled = ($TBMonitoringUser.Text -eq "") })

$ButtonMonitoringWriteConfig = New-Object System.Windows.Forms.Button
$ButtonMonitoringWriteConfig.Text = "Save Config"
$ButtonMonitoringWriteConfig.Width = 100
$ButtonMonitoringWriteConfig.Height = 30
$ButtonMonitoringWriteConfig.Location = [System.Drawing.Point]::new(600, 21)
$ButtonMonitoringWriteConfig.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $ButtonMonitoringWriteConfig
$ButtonMonitoringWriteConfig.Add_Click({ $ButtonWriteConfig.Add_Click() })

$MainForm | Add-Member -Name Number -Value 0 -MemberType NoteProperty

$TimerUI = New-Object System.Windows.Forms.Timer
$TimerUI.Enabled = $false

$ButtonPause.Add_Click(
    { 
        $Variables.NewMiningStatus = "Paused"
        $Variables.RestartCycle = $true
    }
)

$ButtonStop.Add_Click(
    { 
        $Variables.NewMiningStatus = "Stopped"
        $Variables.RestartCycle = $true
    }
)

$ButtonStart.Add_Click(
    { 
        $Variables.NewMiningStatus = "Running"
        $Variables.RestartCycle = $true
    }
)

$ShowWindow = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);' -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
$ParentPID = (Get-CimInstance -Class Win32_Process -Filter "ProcessID = $pid").ParentProcessId
$ConsoleHandle = (Get-Process -Id $ParentPID).MainWindowHandle
$ConsoleHandle = (Get-Process -Id $pid).MainWindowHandle

$MainForm.Controls.AddRange($MainFormControls)
$RunPage.Controls.AddRange(@($RunPageControls))
$Global:EarningsPage.Controls.AddRange(@($EarningsPageControls))
$SwitchingPage.Controls.AddRange(@($SwitchingPageControls))
$EstimationsPage.Controls.AddRange(@($EstimationsDGV))
$ConfigPage.Controls.AddRange($ConfigPageControls)
$GroupMonitoringSettings.Controls.AddRange($MonitoringSettingsControls)
$MonitoringPage.Controls.AddRange($MonitoringPageControls)

$MainForm.Add_Load(
    { 
        Form_Load
    }
)

[Void]$MainForm.ShowDialog()
