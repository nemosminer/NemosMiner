<#
Copyright (c) 2018-2020 Nemo, MrPlus & UselessGuru


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
version:        3.9.9.5
version date:   04 October 2020
#>
 
New-Item -Path function: -Name ((Get-FileHash $MyInvocation.MyCommand.path).Hash) -Value { $true } -ErrorAction SilentlyContinue | Out-Null
Get-Item function::"$((Get-FileHash $MyInvocation.MyCommand.path).Hash)" | Add-Member @{ "File" = $MyInvocation.MyCommand.path} -ErrorAction SilentlyContinue

Class Device { 
    [String]$Name
    [String]$Model
    [String]$Vendor
    [Int64]$Memory
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
    [Int]$Vendor_Index
    [Int]$Type_Vendor_Index

    [Int]$PlatformId = 0
    [Int]$PlatformId_Index
    [Int]$Type_PlatformId_Index

    [PSCustomObject]$OpenCL = [PSCustomObject]@{ }
    [DeviceState]$State = [DeviceState]::Enabled
}

enum DeviceState {
    Enabled
    Disabled
    Unsupported
}

Class Pool { 
    # static [Credential[]]$Credentials = @()
    # [Credential[]]$Credential = @()

    [String]$Name
    [String]$Algorithm
    [String]$Currency = ""
    [String]$CoinName = ""
    [String]$Protocol
    [String]$Host
    [UInt16]$Port
    [String]$User
    [String]$Pass
    [String]$Region
    [Boolean]$SSL
    [Double]$Fee
    [Double]$PricePenaltyfactor = 1
    [Double]$EstimateFactor = 1
    [DateTime]$Updated = (Get-Date).ToUniversalTime()
    [Int]$Workers
    [Boolean]$Available = $true
    [Boolean]$Disabled = $false
    [String[]]$Reason = @("")
    [Boolean]$Best

    #Stats
    [Double]$Price
    [Double]$Price_Bias
    [Double]$StablePrice
    [Double]$MarginOfError
}

Class Worker { 
    [Pool]$Pool
    [Double]$Fee
    [Double]$Speed
    [Double]$Earning
    [Double]$Earning_Bias
    [Double]$Earning_Accuracy
    [Boolean]$Disabled = $false
    [TimeSpan]$TotalMiningDuration
}

enum MinerStatus { 
    Running
    Idle
    Failed
}

Class Miner { 
    static [Pool[]]$Pools = @()
    [Worker[]]$Workers = @()
    [Device[]]$Devices = @()

    [String[]]$Type

    [String]$Name
    [String]$BaseName
    [String]$Version
    [String]$Path
    [String]$PrerequisitePath
    [String]$URI
    [String]$Arguments
    [UInt16]$Port
    [String[]]$DeviceName = @() #derived from devices

    [Double[]]$Speed = @() #derived from stats
    [Double[]]$Speed_Live = @()
    [Boolean]$Benchmark = $false #derived from stats
    [Boolean]$CachedBenchmark = $false

    [Double]$PowerUsage
    [Double]$PowerUsage_Live
    [Double]$PowerCost
    [Boolean]$CalculatePowerCost = $false
    [Boolean]$MeasurePowerUsage = $false
    [Boolean]$CachedMeasurePowerUsage = $false
    [Boolean]$PowerUsageInAPI = $false #If true miner must expose power usage in its API

    [Boolean]$Fastest = $false
    [Boolean]$Best = $false
    [Boolean]$New = $false
    [Boolean]$Available = $true
    [Boolean]$Disabled = $false
    [String[]]$Reason
    [Boolean]$Restart = $false #stop and start miner even if best

    hidden [PSCustomObject[]]$Data = $null
    hidden [System.Management.Automation.Job]$DataReaderJob = $null
    hidden [System.Diagnostics.Process]$Process = $null
    [Int]$Activated = 0
    [MinerStatus]$Status = [MinerStatus]::Idle
    [String]$StatusMessage
    [String]$Info
    [DateTime]$StatStart
    [DateTime]$StatEnd
    [TimeSpan[]]$Intervals = @()
    [String]$LogFile
    [String]$ShowMinerWindows = "minimized"
    [String[]]$Environment = @()
    [Int]$MinDataSamples #for safe hashrate values
    [Int]$WarmupTime
    [DateTime]$BeginTime
    [DateTime]$EndTime
    [TimeSpan]$TotalMiningDuration

    [Double]$Earning #derived from pool and stats
    [Double]$Earning_Bias #derived from pool and stats
    [Double]$Earning_Accuracy #derived from pool and stats

    [Double]$Profit #derived from pool and stats
    [Double]$Profit_Bias #derived from pool and stats

    [String[]]$Algorithm = @() #derived from pool
    #[String[]]$Algorithm_Base = @() #derived from pool
    [String[]]$PoolName = @() #derived from pool
    #[String[]]$PoolName_Base = @() #derived from pool
    [Double[]]$PoolFee = @() #derived from pool
    [Double[]]$PoolPrice = @() #derived from pool
    [Double[]]$Fee = @() #derived from miner
    [Double]$AllowedBadShareRatio = 0
    [String]$MinerUri = ""

    [Int32]$ProcessId = (Get-CimInstance CIM_Process | Where-Object CommandLine -EQ $this.GetCommandLine() | Select-Object -ExpandProperty ProcessId)

    [String[]]GetProcessNames() { 
        Return @(([IO.FileInfo]($this.Path | Split-Path -Leaf -ErrorAction Ignore)).BaseName)
    }

    [String]GetCommandLineParameters() { 
        If ($this.Arguments -match "^{.+}$") { 
            Return ($this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue).Commands
        }
        Else { 
            Return $this.Arguments
        }
    }

    [String]GetCommandLine() { 
        Return "$($this.Path) $($this.GetCommandLineParameters())"
    }

    [Int32]GetProcessId() { 
        Return $this.ProcessId
    }

    hidden StartMining() { 
        $this.Status = [MinerStatus]::Failed
        $this.StatusMessage = "Launching..."
        $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
        $this.New = $true
        $this.Activated++
        $this.Intervals = @()

        $this.Info = "$($this.Name) {$(($this.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"

        If ($this.Arguments -match "^{.+}$") { 
            $this.CreateConfigFiles()
        }

        If ($this.ProcessId) { 
            If (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue) { 
                Stop-Process -Id $this.ProcessId -Force -ErrorAction Ignore
            }
            $this.ProcessId = $null
        }

        If ($this.Process) { $this.Process = $null }

        If (-not $this.Process) { 
            $this.Process = Invoke-CreateProcess -Binary $this.Path -ArgumentList $this.GetCommandLineParameters() -WorkingDirectory (Split-Path $this.Path) -ShowMinerWindows $this.ShowMinerWindows -Priority ($this.Device.Name | ForEach-Object { If ($_ -like "CPU#*") { -2 } Else { -1 } } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) -EnvBlock $this.Environment

            If ($this.Benchmark -EQ $true -or $this.MeasurePowerUsage -EQ $true) { $this.Data = $null } #When benchmarking clear data on each miner start
            #Starting Miner Data reader
            $this | Add-Member -Force @{ DataReaderJob = Start-Job -InitializationScript ([ScriptBlock]::Create("Set-Location('$(Get-Location)')")) -Name "$($this.Name)_DataReader" -ScriptBlock { .\Includes\GetMinerData.ps1 $args[0] $args[1] } -ArgumentList ([String]$this.GetType()), ($this | Select-Object -Property * -ExcludeProperty Active, DataReaderJob, Devices, Process, SideIndicator, TotalMiningDuration, Type, Workers | ConvertTo-Json) }

            If ($this.ProcessId = [Int32]((Get-CIMInstance CIM_Process | Where-Object { $_.ExecutablePath -eq $this.Path -and $_.CommandLine -like "*$($this.Path)*$($this.GetCommandLineParameters())*" }).ProcessId)) { 
                $this.Status = [MinerStatus]::Running
                $this.StatStart = $this.BeginTime = (Get-Date).ToUniversalTime()
                $this.Info = "$($this.Name) {$(($this.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"
                $this.StatusMessage = "$(If ($this.Benchmark -EQ $true -or $this.MeasurePowerUsage -EQ $true) { "$($(If ($this.Benchmark -eq $true) { "Benchmarking" }), $(If ($this.Benchmark -eq $true -and $this.MeasurePowerUsage -eq $true) { "and" }), $(If ($this.MeasurePowerUsage -eq $true) { "Power usage measuring" }) -join ' ')" } Else { "Mining" }) {$(($this.Workers.Pool | ForEach-Object { (($_.Algorithm | Select-Object), ($_.Name | Select-Object)) -join '@' }) -join ' & ')}"
                $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
                $this.StatStart = (Get-Date).ToUniversalTime()
            }
        }
    }

    hidden StopMining() { 
        $this.Status = [MinerStatus]::Failed
        $this.StatusMessage = "Stopping..."
        $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
        $this.EndTime = (Get-Date).ToUniversalTime()
        If ($this.ProcessId) { 
            If (Get-Process -Id $this.ProcessId -ErrorAction SilentlyContinue) { 
                Stop-Process -Id $this.ProcessId -Force -ErrorAction Ignore
            }
            $this.ProcessId = $null
        }

        If ($this.Process) { 
            $this.Process = $null
            $this.Status = [MinerStatus]::Idle
        }

        #Stop Miner data reader
        Get-Job | Where-Object Name -EQ "$($this.Name)_DataReader" | Stop-Job -ErrorAction Ignore | Remove-Job -Force -ErrorAction Ignore
        $this.StatusMessage = "Idle"
        $this.Devices | ForEach-Object { $_.Status = $this.StatusMessage }
        $this.Info = ""
    }

    [DateTime]GetActiveLast() { 
        If ($this.Process.StartTime -and $this.Process.ExitTime) { 
            Return $this.Process.PSEndTime.ToUniversalTime()
        }
        # ElseIf ($this.Process.PSBeginTime) { 
        ElseIf ($this.Process.StartTime) { 
            Return [DateTime]::Now.ToUniversalTime()
        }
        Else { 
            Return [DateTime]::MinValue.ToUniversalTime()
        }
    }

    [Int]GetActivateCount() { 
        Return $this.Activated
    }

    [MinerStatus]GetStatus() { 
        If ($this.Process.HasExited -eq $false) { 
            Return [MinerStatus]::Running
        }
        ElseIf ($this.Status -eq "Running") { 
            $this.ProcessId = $null
            #Stop Miner data reader
            Get-Job | Where-Object Name -EQ "$($this.Name)_DataReader" | Stop-Job -ErrorAction Ignore
            Get-Job | Where-Object Name -EQ "$($this.Name)_DataReader" | Remove-Job -Force -ErrorAction Ignore
            $this.Status = [MinerStatus]::Failed
            Return $this.Status
        }
        Else { 
            Return $this.Status
        }
    }

    [Double]GetPowerUsage() { 

        $PowerUsage_Value = [Double]0
        $RegistryHive = "HKCU:\Software\HWiNFO64\VSB"
        $RegistryData = [PSCustomObject]@{ }

        #Read power usage
        If ((Test-Path $RegistryHive) -and $this.DeviceName) { 
            $RegistryData = Get-ItemProperty $RegistryHive
            $RegistryData.PSObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @($this.DeviceName | Select-Object) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                $PowerUsage_Value += [Double]($RegistryData.($_.Name -replace "Label", "Value") -split ' ' | Select-Object -Index 0)
            }
        }
        Return $PowerUsage_Value
    }

    SetStatus([MinerStatus]$Status) { 
        If ($Status -eq $this.GetStatus()) { Return }

        Switch ($Status) { 
            "Running" { 
                $this.StartMining()
            }
            "Idle" { 
                $this.StopMining()
            }
            Default { 
                $this.StopMining()
                $this.Status = $Status
            }
        }
    }

    [String[]]UpdateMinerData () { 
        $Lines = @()

        If ($this.Process.HasMoreData) { 
            $Date = (Get-Date).ToUniversalTime()

            $this.Process | Receive-Job | ForEach-Object { 
                $Line = $_ -replace "`n|`r", ""
                $Line_Simple = $Line -replace "\x1B\[[0-?]*[ -/]*[@-~]", ""

                If ($Line_Simple) { 
                    $HashRates = @()
                    $Devices = @()

                    If ($Line_Simple -match "/s") { 
                        $Words = $Line_Simple -split " "

                        $Words -match "/s$" | ForEach-Object { 
                            If (($Words | Select-Object -Index $Words.IndexOf($_)) -match "^((?:\d*\.)?\d+)(.*)$") { 
                                $HashRate = ($matches | Select-Object -Index 1) -as [Decimal]
                                $HashRate_Unit = ($matches | Select-Object -Index 2)
                            }
                            Else { 
                                $HashRate = ($Words | Select-Object -Index ($Words.IndexOf($_) - 1)) -as [Decimal]
                                $HashRate_Unit = ($Words | Select-Object -Index $Words.IndexOf($_))
                            }

                            switch -wildcard ($HashRate_Unit) { 
                                "kh/s*" { $HashRate *= [Math]::Pow(1000, 1) }
                                "mh/s*" { $HashRate *= [Math]::Pow(1000, 2) }
                                "gh/s*" { $HashRate *= [Math]::Pow(1000, 3) }
                                "th/s*" { $HashRate *= [Math]::Pow(1000, 4) }
                                "ph/s*" { $HashRate *= [Math]::Pow(1000, 5) }
                            }

                            $HashRates += $HashRate
                        }
                    }

                    If ($Line_Simple -match "gpu|cpu|device") { 
                        $Words = $Line_Simple -replace "#", "" -replace ":", "" -split " "

                        $Words -match "^gpu|^cpu|^device" | ForEach-Object { 
                            If (($Words | Select-Object -Index $Words.IndexOf($_)) -match "^(.*)((?:\d*\.)?\d+)$") { 
                                $Device = ($matches | Select-Object -Index 2) -as [Int]
                                $Device_Type = ($matches | Select-Object -Index 1)
                            }
                            Else { 
                                $Device = ($Words | Select-Object -Index ($Words.IndexOf($_) + 1)) -as [Int]
                                $Device_Type = ($Words | Select-Object -Index $Words.IndexOf($_))
                            }

                            $Devices += "{0}#{1:d2}" -f $Device_Type, $Device
                        }
                    }

                    If ($HashRate.PSObject.Properties.Value -gt 0) { 
                        $Sample = [PSCustomObject]@{ 
                            Date       = (Get-Date).ToUniversalTime()
                            HashRate   = $HashRate
                            PowerUsage = $PowerUsage
                            Shares     = $Shares
                        }
                        Return $Sample
                    }
                }
            }
        }
        Return $null
    }

    [Double]CollectHashRate([String]$Algorithm = [String]$this.Algorithm, [Boolean]$Safe = $this.New) { 
        $HashRates_Devices = @($this.Data | Where-Object Devices | Select-Object -ExpandProperty Device -Unique)
        If (-not $HashRates_Devices) { $HashRates_Devices = @("Device") }

        $HashRates_Counts = @{ }
        $HashRates_Averages = @{ }
        $HashRates_Variances = @{ }

        $Hashrates_Samples = @($this.Data | Where-Object { $_.HashRate.$Algorithm } | Sort-Object { $_.HashRate.$Algorithm }) #Do not use 0 valued samples

        #During benchmarking strip some of the lowest and highest sample values
        If ($Safe) { 
            $SkipSamples = [math]::Floor($HashRates_Samples.Count) * 0.1
        }
        Else { $SkipSamples = 0 }

        $Hashrates_Samples | Select-Object -Skip $SkipSamples | Select-Object -SkipLast $SkipSamples | ForEach-Object { 
            $Data_Devices = $_.Device
            If (-not $Data_Devices) { $Data_Devices = $HashRates_Devices }

            $Data_HashRates = $_.HashRate.$Algorithm

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

    [Double]CollectPowerUsage([Boolean]$Safe = $this.New) { 
        $PowerUsages_Devices = @($this.Data | Where-Object Devices | Select-Object -ExpandProperty Device -Unique)
        If (-not $PowerUsages_Devices) { $PowerUsages_Devices = @("Device") }

        $PowerUsages_Counts = @{ }
        $PowerUsages_Averages = @{ }
        $PowerUsages_Variances = @{ }

        $PowerUsages_Samples = @($this.Data | Where-Object PowerUsage) #Do not use 0 valued samples

        #During power measuring strip some of the lowest and highest sample values
        If ($Safe) { 
            $SkipSamples = [math]::Round($PowerUsages_Samples.Count * 0.1)
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
        $PowerUsages_Variance = $PowerUsages_Variances.Keys | ForEach-Object { $_ } | ForEach-Object { $PowerUsages_Variances.$_ | Measure-Object -Average -Minimum -Maximum } | ForEach-Object { If ($_.Average) { ($_.Maximum - $_.Minimum) / $_.Average } } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

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

    Refresh([Double]$PowerCostBTCperW) { 
        $this.Available = $true
        $this.Benchmark = $false
        $this.Best = $false
        $this.Reason = [String[]]@()

        $this.Workers | ForEach-Object { 
            If ($Stat = Get-Stat "$($this.Name)_$($_.Pool.Algorithm)_HashRate") { 
                $_.Speed = $Stat.Hour
                $Factor = [Double]($_.Speed * (1 - $_.Fee) * (1 - $_.Pool.Fee))
                $_.Earning = [Double]($_.Pool.Price * $Factor)
                $_.Earning_Bias = [Double]($_.Pool.Price_Bias * $Factor)
                $_.Earning_Accuracy = [Double](1 - $_.Pool.MarginOfError)
                $_.TotalMiningDuration = $Stat.Duration
            }
            Else { 
                $this.Benchmark = $true
                $_.Speed = [Double]::NaN
                $_.Earning = [Double]::NaN
                $_.Earning_Bias = [Double]::NaN
                $_.Earning_Accuracy = [Double]::Nan
                $_.TotalMiningDuration = New-TimeSpan
            }
        }

        $this.PoolName = $this.Workers.Pool | Select-Object -ExpandProperty Name
        $this.PoolFee = $this.Workers.Pool | Select-Object -ExpandProperty Fee
        $this.PoolPrice = $this.Workers.Pool | Select-Object -ExpandProperty Price
        $this.Fee = $this.Workers | Select-Object -ExpandProperty Fee
        $this.Speed = $this.Workers | Select-Object -ExpandProperty Speed

        $this.Disabled = $this.Workers | Where-Object Speed -EQ 0

        $this.Earning = 0
        $this.Earning_Bias = 0
        $this.Earning_Accuracy = 0

        $this.Workers | ForEach-Object { 
            $this.Earning += $_.Earning
            $this.Earning_Bias += $_.Earning_Bias
        }

        If ($this.Earning -eq 0) { 
            $this.Earning_Accuracy = 1
        }
        Else { 
            $this.Workers | ForEach-Object { 
                $this.Earning_Accuracy += (($_.Earning_Accuracy * $_.Earning) / $this.Earning)
            }
        }

        $this.TotalMiningDuration = ($this.Workers.TotalMiningDuration | Measure-Object -Minimum).Minimum

        If ($this.CalculatePowerCost) { 
            If ($Stat = Get-Stat "$($this.Name)$(If ($this.Algorithm.Count -eq 1) { "_$($this.Algorithm | Select-Object -Index 0)" })_PowerUsage") { 
                $this.PowerUsage = $Stat.Week
                $this.PowerCost = $this.PowerUsage * $PowerCostBTCperW
                $this.Profit = $this.Earning - $this.PowerCost
                $this.Profit_Bias = $this.Earning_Bias - $this.PowerCost
            }
            Else { 
                $this.MeasurePowerUsage = $true
                $this.PowerUsage = [Double]::NaN
                $this.PowerCost = [Double]::NaN
                $this.Profit = [Double]::NaN
                $this.Profit_Bias = [Double]::NaN
            }
        }
    }
}

Function Get-DefaultAlgorithm {
    Try { 
        $PoolsAlgos = (Invoke-WebRequest "https://nemosminer.com/data/PoolsAlgos.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" }).Content | ConvertFrom-Json
        $PoolsAlgos | ConvertTo-Json | Out-File ".\Config\PoolsAlgos.json" 
    }
    Catch { $PoolsAlgos = Get-Content ".\Config\PoolsAlgos.json" | ConvertFrom-Json }
    If ($PoolsAlgos) { 
        $PoolsAlgos = $PoolsAlgos.PSObject.Properties | Where-Object { $_.Name -in $Config.PoolName }
        Return  $PoolsAlgos.Value | Sort-Object -Unique
    }
}

Function Get-NextColor {
    Param(
        [Parameter(Mandatory = $true)]
        [Byte[]]$Colors, 
        [Parameter(Mandatory = $true)]
        [Int[]]$Factors
    )
    # Apply change Factor
    0, 1, 2, 3 | ForEach-Object { 
        $Colors[$_] = [math]::Abs(($Colors[$_] + $Factors[$_]) % 256)
    }
    $Colors
}

Function Get-TrendSign { 
    Param(
        [Parameter(Mandatory = $true)]
        [Double]$Value
    )

    If ($PSVersionTable.PSVersion -ge 6.0.0.0) { 
        Switch ($Value) { 
            { $_ -eq 0 } { "`u{21D2}" }
            { $_ -gt 0 } { "`u{21D7}" }
            { $_ -lt 0 } { "`u{21D8}" }
        }
    }
    Else { 
        Switch ($Value) { 
            { $_ -eq 0 } { "=" }
            { $_ -gt 0 } { ">" }
            { $_ -lt 0 } { "<" }
        }
    }
}

Function Get-Chart { 
    If ((Test-Path ".\Logs\DailyEarnings.csv" -PathType Leaf) -and (Test-Path ".\Includes\Charting.ps1" -PathType Leaf)) { 
        $Chart1 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'Front7DaysEarnings' -Width 505 -Height 150"
        $Chart1.top = 2
        $Chart1.left = 0
        $Global:EarningsPage.Controls.Add($Chart1)
        $Chart1.BringToFront()

        $Chart2 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'DayPoolSplit' -Width 200 -Height 150"
        $Chart2.top = 2
        $Chart2.left = 500
        $Global:EarningsPage.Controls.Add($Chart2)
        $Chart2.BringToFront()

        $Global:EarningsPage.Controls | Where-Object { ($_.GetType()).name -eq "Chart" -and $_ -ne $Chart1 -and $_ -ne $Chart2 } | ForEach-Object { $Global:EarningsPage.Controls[$Global:EarningsPage.Controls.IndexOf($_)].Dispose(); $Global:EarningsPage.Controls.Remove($_) }
    }
}

Function Get-NMVersion { 
    # Check if new version is available
    Write-Message "Checking version..."
    Try { 
        $Version = Invoke-WebRequest "https://nemosminer.com/data/version.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
    }
    Catch { 
        $Version = Get-Content ".\Config\version.json" | ConvertFrom-Json
    }
    If ($Version.Version -gt $Variables.CurrentVersion) { $Version | ConvertTo-Json | Out-File ".\Config\version.json" }
    If ($Version.Product -eq $Variables.CurrentProduct -and [Version]$Version.Version -gt $Variables.CurrentVersion -and $Version.Update) { 
        Write-Message "Version $($Version.Version) available. (You are running $($Variables.CurrentVersion))"
        # If ([Version](Get-NVIDIADriverVersion) -ge [Version]$Version.MinNVIDIADriverVersion){ 
        $LabelNotifications.ForeColor = [System.Drawing.Color]::Green
        $LabelNotifications.Lines += "Version $([Version]$Version.Version) available"
        $LabelNotifications.Lines += $Version.Message
        If ($Config.Autoupdate -and (-not $Config.ManualConfig)) { Initialize-Autoupdate }
    }
}

Function Get-CommandLineParameters { 
    [CmdletBinding()]
    Param(
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

Function Start-BrainJob { 

    # Starts Brains if necessary
    $JobNames = @()

    $Config.PoolName | Select-Object | ForEach-Object { 
        If (-not $Variables.BrainJobs.$_) { 
            $BrainPath = "$($Variables.MainPath)\Brains\$($_)"
            $BrainName = (".\Brains\" + $_ + "\Brains.ps1")
            If (Test-Path $BrainName -PathType Leaf) { 
                $Variables.BrainJobs.$_ = (Start-Job -FilePath $BrainName -ArgumentList @($BrainPath))
                If ($Variables.BrainJobs.$_.State -EQ "Running") { 
                    $JobNames += $_
                }
            }
        }
    }
    If ($JobNames -gt 0) { Write-Message "Started Brain Job$(If ($JobNames.Count -gt 1) { "s" } ) ($($JobNames -join ', '))." }
}

Function Stop-BrainJob { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Jobs = $Variables.BrainJobs.Keys
    )

    $JobNames = @()

    #Stop Brains if necessary
    $Jobs | ForEach-Object { 
        $Variables.BrainJobs.$_ | Stop-Job -PassThru -ErrorAction Ignore | Remove-Job -ErrorAction Ignore
        $Variables.BrainJobs.Remove($_)
        $JobNames += $_
    }

    If ($JobNames -gt 0) { Write-Message "Stopped Brain Job$(If ($JobNames.Count -gt 1) { "s" } ) ($($JobNames -join ', '))." }
}


Function Start-BalancesTracker { 
    
    If (-not $Variables.CycleRunspace) { 

        Try { 
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
        }
        Catch { 
            Write-Message -Level ERROR "Failed to start Balances Tracker [$Error[0]]."
        }
    }
}


Function Stop-BalancesTracker { 
    If ($Variables.BalancesTrackerRunspace) { 
        $Variables.BalancesTrackerRunspace.Close()
        If ($Variables.BalancesTrackerRunspace.PowerShell) { $Variables.BalancesTrackerRunspace.PowerShell.Dispose() }
        $Variables.Remove("BalancesTrackerRunspace")
        Write-Message "Stopped Balances Tracker."
    }
}

Function Initialize-API { 

    If ($Variables.APIRunspace.AsyncObject.IsCompleted -eq $true) { 
        $Variables.Remove("APIVersion")
    }

    #Initialize API & Web GUI
    If ($Config.APIPort -and ($Config.APIPort -ne $Variables.APIRunspace.APIPort)) { 
        If (Test-Path -Path .\Includes\API.psm1 -PathType Leaf) { 
            If ($Variables.APIRunspace) { 
                $Variables.APIRunspace.Close()
                If ($Variables.APIRunspace.PowerShell) { $Variables.APIRunspace.PowerShell.Dispose() }
                $Variables.Remove("APIRunspace")
            }

            $TCPClient = New-Object System.Net.Sockets.TCPClient
            $AsyncResult = $TCPClient.BeginConnect("localhost", $Config.APIPort, $null, $null)
            If ($AsyncResult.AsyncWaitHandle.WaitOne(100)) { 
                Write-Message -Level Error "Error starting Web GUI and API on port $($Config.APIPort). Port is in use."
                Try { $TCPClient.EndConnect($AsyncResult) = $null }
                Catch { }
            }
            Else { 
                Import-Module .\Includes\API.psm1

                #Required for stat management
                Get-Stat | Out-Null

                #Start API server
                Start-APIServer -Port $Config.APIPort

                #Wait for API to get ready
                $RetryCount = 3
                While (-not ($Variables.APIVersion) -and $RetryCount -gt 0) { 
                    Start-Sleep -Seconds 1
                    Try {
                        If ($Variables.APIVersion = (Invoke-RestMethod "http://localhost:$($Variables.APIRunspace.APIPort)/apiversion" -UseBasicParsing -TimeoutSec 1 -ErrorAction Stop)) { 
                            Write-Message "Web GUI and API (version $($Variables.APIVersion)) running on http://localhost:$($Variables.APIRunspace.APIPort)."
                            If ($Config.WebGui) { Start-Process "http://localhost:$($Variables.APIRunspace.APIPort)/$(If ($Variables.FreshConfig -eq $true) { "configedit.html" })" } # Start web gui
                            Break
                        }
                    }
                    Catch { 
                        $RetryCount--
                    }
                }
                If (-not $Variables.APIVersion) { Write-Message -Level Error "Error starting Web GUI and API on port $($Config.APIPort)." }
                Remove-Variable RetryCount
            }
            Remove-Variable AsyncResult
            Remove-Variable TCPClient
        }
    }
}

Function Initialize-Application { 
    Write-Message "Initializing mining environment..."

    $Variables.Devices | Where-Object { $_.Vendor -notin $Variables.SupportedVendors } | ForEach-Object { $_.State = [DeviceState]::Unsupported; $_.Status = "Disabled (Unsupported Vendor: '$($_.Vendor)')" }
    $Variables.Devices | Where-Object Name -in $Config.ExcludeDeviceName | ForEach-Object { $_.State = [DeviceState]::Disabled; $_.Status = "Disabled (ExcludeDeviceName: '$($_.Name)')" }

    $Variables.ScriptStartDate = (Get-Date).ToUniversalTime()
    If ([Net.ServicePointManager]::SecurityProtocol -notmatch [Net.SecurityProtocolType]::Tls12) { 
        [Net.ServicePointManager]::SecurityProtocol += [Net.SecurityProtocolType]::Tls12
    }

    #Set process priority to BelowNormal to avoid hash rate drops on systems with weak CPUs
    (Get-Process -Id $PID).PriorityClass = "BelowNormal"

    If ($Proxy -eq "") { $PSDefaultParameterValues.Remove("*:Proxy") }
    Else { $PSDefaultParameterValues["*:Proxy"] = $Proxy }
    $Variables.DecayStart = (Get-Date).ToUniversalTime()
    $Variables.DecayPeriod = 60 #seconds
    $Variables.DecayBase = 1 - 0.1 #decimal percentage

    $Variables.Strikes = 3
    $Variables.WatchdogTimers = @()

    # Purge Logs more than 10 days
    Get-ChildItem ".\Logs\miner-*.log" | Sort-Object LastWriteTime | Select-Object -Skip 10 | Remove-Item -Force -Recurse
}

Function Get-Rate {
    # Read exchange rates from min-api.cryptocompare.com
    # Returned decimal values contain as many digits as the native currency
    Try { 
        $Currencies = (@("BTC") + @($Config.PoolsConfig.Keys | ForEach-Object { $Config.PoolsConfig.$_.PayoutCurrency | Select-Object }) + @($Config.PoolsConfig.Keys | ForEach-Object { $Config.PoolsConfig.$_.PaymentThresholdCurrency }) + @($Config.Currency | ForEach-Object { $_ } )) | Select-Object | ForEach-Object { $_ -replace "^m" } | Sort-Object -Unique
        $NewRates = Invoke-RestMethod "https://min-api.cryptocompare.com/data/pricemulti?fsyms=BTC&tsyms=$($Currencies -join ",")&extraParams=http://nemosminer.com" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    }
    Catch { 
        Write-Message -Level Warn "CryptoCompare is down. "
    }

    If ($NewRates) { 
        $Rates = $NewRates | ConvertTo-Json | ConvertFrom-Json
        $Currencies = $Rates.BTC | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name

        $Currencies | Where-Object { $_ -ne "BTC" } | ForEach-Object { 
            $Currency = $_
            $Rates | Add-Member $Currency ($Rates.BTC | ConvertTo-Json | ConvertFrom-Json) -ErrorAction Ignore
            $Rates.$Currency | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                $Rates.$Currency | Add-Member $_ ([Double]($Rates.BTC.$_ / $Rates.BTC.$Currency)) -Force
            }        
        }

        $Currencies | ForEach-Object { 
            $Currency = $_
            $mCurrency = "m$($Currency)"
            $Rates | Add-Member $mCurrency ($Rates.$Currency | ConvertTo-Json | ConvertFrom-Json)
            $Rates.$mCurrency | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                $Rates.$mCurrency | Add-Member $_ ([Double]($Rates.$Currency.$_) / 1000) -Force
            }
        }

        $Rates | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object {
            $Currency = $_
            $Rates | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { $_ -in $Currencies} | ForEach-Object { 
                $mCurrency = "m$($_)"
                $Rates.$Currency | Add-Member $mCurrency ([Double]($Rates.$Currency.$_) * 1000)
            }
        }
        $Variables.Rates = $Rates
    }
    $Variables.RateFirstCurrency = $Variables.Rates.($Config.PayoutCurrency).($Config.Currency | Select-Object -Index 0)
}

Function Write-Message { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Message, 
        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info", "Verbose", "Debug")]
        [String]$Level = "Info"
    )

    Begin { }
    Process { 

        If ((-not $Config.LogToScreen) -or $Level -in $Config.LogToScreen) { 

            #Update status text box in GUI
            If ($Variables.LabelStatus) { 
                $Variables.LabelStatus.Lines += $Message
                $Variables.LabelStatus.SelectionStart = $Variables.LabelStatus.TextLength
                $Variables.LabelStatus.ScrollToCaret()
                $Variables.LabelStatus.Refresh()
            }

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
        }
        If ($Variables.LogFile) { 
            If ((-not $Config.LogToFile) -or $Level -in $Config.LogToFile) { 
                # Get mutex named NemosMinerWriteLog. Mutexes are shared across all threads and processes. 
                # This lets us ensure only one thread is trying to write to the file at a time. 
                $Mutex = New-Object System.Threading.Mutex($false, "NemosMinerWriteLog")

                $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                # Attempt to aquire mutex, waiting up to 1 second if necessary. If aquired, write to the log file and release mutex. Otherwise, display an error. 
                If ($Mutex.WaitOne(1000)) { 
                    "$Date $LevelText $Message" | Out-File -FilePath $Variables.LogFile -Append -Encoding UTF8
                    $Mutex.ReleaseMutex()
                }
                Else { 
                    Write-Error -Message "Log file is locked, unable to write message to $($Variables.LogFile)."
                }
            }
        }
    }
    End { }
}

Function Start-IdleMining { 
    # Function tracks how long the system has been idle and controls the paused state
    $IdleRunspace = [runspacefactory]::CreateRunspace()
    $IdleRunspace.Open()
    Get-Variable -Scope Global | ForEach-Object { 
        Try { 
            $IdleRunspace.SessionStateProxy.SetVariable($_.Name, $_.Value)
        }
        Catch { }
    }
    $IdleRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
    $PowerShell = [PowerShell]::Create()
    $PowerShell.Runspace = $IdleRunspace
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

            #Start transcript log
            If ($Config.Transcript -eq $true) { Start-Transcript ".\Logs\IdleMining.log" -Append -Force }

            $ProgressPreference = "SilentlyContinue"
            Write-Message "Started idle detection. $($Branding.ProductLabel) will start mining when the system is idle for more than $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" } )..."

            While ($true) { 
                $IdleSeconds = [Math]::Round(([PInvoke.Win32.UserInput]::IdleTime).TotalSeconds)

                #Pause if system has become active
                If ($IdleSeconds -lt $Config.IdleSec -and $Variables.CycleRunspace) { 
                    Write-Message "System active, mining is suspended until system is idle again for $($Config.IdleSec) second$(If ($Config.IdleSec -ne 1) { "s" } )..."
                    Stop-Mining
                }
                #Check if system has been idle long enough to unpause
                If ($IdleSeconds -ge $Config.IdleSec -and -not $Variables.CycleRunspace) { 
                    Write-Message "System was idle for $IdleSeconds seconds, start mining..."
                    Start-Mining
                }
                Start-Sleep -Seconds 1
            }
            Return
        }
    ) | Out-Null
    $PowerShell.BeginInvoke()

    $Variables.IdleRunspace = $IdleRunspace
    $Variables.IdleRunspace | Add-Member -Force @{ PowerShell = $PowerShell }
}

Function Stop-IdleMining { 

    If ($Variables.IdleRunspace) { 
        $Variables.IdleRunspace.Close()
        If ($Variables.IdleRunspace.PowerShell) { $Variables.IdleRunspace.PowerShell.Dispose() }
        $Variables.Remove("IdleRunspace")
        Write-Message "Stopped idle detection."
    }
}

Function Update-Monitoring { 
    # Updates a remote monitoring server, sending this worker's data and pulling data about other workers

    # Skip If server and user aren't filled out
    If (-not $Config.MonitoringServer) { Return }
    If (-not $Config.MonitoringUser) { Return }

    If ($Config.ReportToServer) { 
        $Version = "$($Variables.CurrentProduct) $($Variables.CurrentVersion.ToString())"
        $Status = If ($Variables.Paused) { "Paused" } Else { "Running" }
        $RunningMiners = $Variables.Miners | Where-Object { $_.Status -eq "Running" }
        # Add the associated object from $Variables.Miners since we need data from that too
        $RunningMiners | Foreach-Object { 
            $RunningMiner = $_
            $Miner = $Variables.Miners | Where-Object { $_.Name -eq $RunningMiner.Name -and $_.Path -eq $RunningMiner.Path -and $_.Arguments -eq $RunningMiner.Arguments }
        }

        # Build object with just the data we need to send, and make sure to use relative paths so we don't accidentally
        # reveal someone's windows username or other system information they might not want sent
        # For the ones that can be an array, comma separate them
        $Data = $RunningMiners | ForEach-Object { 
            $RunningMiner = $_
            [PSCustomObject]@{ 
                Name           = $RunningMiner.Name
                Path           = Resolve-Path -Relative $RunningMiner.Path
                Type           = $RunningMiner.Type -join ','
                Algorithm      = $RunningMiner.Algorithm -join ','
                Pool           = $RunningMiner.Workers.Pool.Name -join ','
                CurrentSpeed   = $RunningMiner.Speed_Live -join ','
                EstimatedSpeed = $RunningMiner.Workers.Speed -join ','
                Earning        = $RunningMiner.Earning
                Profit         = $RunningMiner.Profit
            }
        }
        $DataJSON = ConvertTo-Json @($Data)
        # Calculate total estimated profit
        $Profit = [String]([Math]::Round(($data | Measure-Object Profit -Sum).Sum, 8))

        # Send the request
        $Body = @{ user = $Config.MonitoringUser; worker = $Config.WorkerName; version = $Variables.CurrentVersion; status = $Status; profit = $Profit; data = $DataJSON }
        Try { 
            $Response = Invoke-RestMethod -Uri "$($Config.MonitoringServer)/api/report.php" -Method Post -Body $Body -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            Write-Message -Level VERBOSE "Reported status to monitoring server '$($Config.MonitoringServer)' [$($Response)]."
        }
        Catch { 
            Write-Message -Level WARN "Monitoring: Unable to send status to $($Config.MonitoringServer)."
        }
    }

    If ($Config.ShowWorkerStatus) { 
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
            Write-Message -Level VERBOSE "Updated status of workers for '$($Config.MonitoringUser)'."
        }
        Catch { 
            Write-Message -Level WARN "Monitoring: Unable to retrieve worker data from $($Config.MonitoringServer)."
        }
    }
}

Function Start-Mining { 

    If (Test-Path -PathType Leaf "$($Variables.MainPath)\Includes\Core.ps1") { 
        #Load algorithm list
        $Variables.Algorithms = Get-Content ".\Includes\Algorithms.txt" | ConvertFrom-Json
        #Load regions list
        $Variables.Regions = Get-Content ".\Includes\Regions.txt" | ConvertFrom-Json

        If (-not $Variables.CoreRunspace) { 
            $Variables.LastDonated = (Get-Date).AddDays(-1).AddHours(1)
            $Variables.Pools = $null
            $Variables.Miners = $null

            $CoreRunspace = [RunspaceFactory]::CreateRunspace()
            $CoreRunspace.Open()
            $CoreRunspace.SessionStateProxy.SetVariable('Config', $Config)
            $CoreRunspace.SessionStateProxy.SetVariable('Variables', $Variables)
            $CoreRunspace.SessionStateProxy.SetVariable('Stats', $Stats)
            $CoreRunspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)
            $PowerShell = [PowerShell]::Create()
            $PowerShell.Runspace = $CoreRunspace
            $PowerShell.AddScript("$($Variables.MainPath)\Includes\Core.ps1")
            $PowerShell.BeginInvoke()

            $Variables.CoreRunspace = $CoreRunspace
            $Variables.CoreRunspace | Add-Member -Force @{ PowerShell = $PowerShell }
        }
    }
    Else { 
        Write-Message -Level ERROR "Corrupt installation. File '$($Variables.MainPath)\Includes\Core.ps1' is missing."
    }
}

Function Stop-Mining { 
    $Variables.Miners | Where-Object { $_.Status -EQ "Running" } | ForEach-Object { 
        Stop-Process -Id $_.ProcessId -Force -ErrorAction Ignore
        $_.Status = "Idle"
        $_.Best = $false
        Write-Message "Stopped miner '$($_.Info)'."
    }

    If ($Variables.CoreRunspace) { 
        $Variables.CoreRunspace.Close()
        If ($Variables.CoreRunspace.PowerShell) { $Variables.CoreRunspace.PowerShell.Dispose() }
        $Variables.Remove("CoreRunspace")
        Write-Message "Stopped cycle."
    }
}

Function Update-Notifications ($Text) { 
    $LabelNotifications.Lines += $Text
    If ($LabelNotifications.Lines.Count -gt 20) { $LabelNotifications.Lines = $LabelNotifications.Lines[($LabelNotifications.Lines.count - 10)..$LabelNotifications.Lines.Count] }
    $LabelNotifications.SelectionStart = $Variables.LabelStatus.TextLength;
    $LabelNotifications.ScrollToCaret();
    $Variables.LabelStatus.Refresh | Out-Null
}

Function Read-Config { 
    Param(
        [Parameter(Mandatory = $false)]
        [Hashtable]$Parameters = @{ }
    )

    If ($Global:Config -isnot [Hashtable]) { 
        New-Variable Config ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
    }

    #Load the configuration
    $Variables.OldConfig = $Global:Config | ConvertTo-Json -Depth 10 | ConvertFrom-Json

    If (Test-Path -PathType Leaf $Variables.ConfigFile) { 
        $Config_Tmp = Get-Content $Variables.ConfigFile | ConvertFrom-Json -ErrorAction Ignore
        If ($Config_Tmp.PSObject.Properties.Count -eq 0 -or $Config_Tmp -isnot [PSCustomObject]) { 
            Copy-Item -Path $Variables.ConfigFile "$($Variables.ConfigFile).corrupt" -Force
            Write-Message -Level WARN "Configuration file '$($Variables.ConfigFile)' is corrupt."
            $Config.ConfigFileVersionCompatibility = $null
        }
        Else { 
            #Fix upper / lower case (Web GUI is case sensitive)
            $Config_Tmp | ForEach-Object { 
                $_.PSObject.Properties | Sort-Object Name | ForEach-Object { 
                    $PropertyName = $_.Name
                    If ($Variables.AvailableCommandLineParameters | Where-Object { $_ -eq $PropertyName }) { $PropertyName = $Variables.AvailableCommandLineParameters | Where-Object { $_ -eq $PropertyName } }
                    $Global:Config.$PropertyName = $_.Value
                }
            }
        }
        Remove-Variable Config_Tmp
    }
    Else { 
        Write-Message -Level WARN "No valid configuration file found."

        #Prepare new config
        $Variables.FreshConfig = $true
        If (Test-Path ".\Config\PoolsConfig-Recommended.json" -PathType Leaf) { 
            $Parameters | Add-Member @{ PoolName = @(Get-Content ".\Config\PoolsConfig-Recommended.json" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore | ForEach-Object { $_ | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $_ -ne "Default" } }) }
        }
        $Parameters.Keys | Sort-Object | ForEach-Object { 
            $Global:Config.$_ = $Parameters.$_
        }
        $Config.ConfigFileVersion = $Variables.CurrentVersion.ToString()
        Write-Message -Level WARN  "New configuration using default values has been created. Use the GUI to save the configuration, then start mining."
    }

    #Build pools configuations
    If (Test-Path $Variables.PoolsConfigFile -PathType Leaf) { 
        $PoolsConfig_Tmp = Get-Content $Variables.PoolsConfigFile | ConvertFrom-Json -ErrorAction Ignore
        If ($PoolsConfig_Tmp.PSObject.Properties.Count -eq 0 -or $PoolsConfig_Tmp -isnot [PSCustomObject]) { 
            Write-Message -Level WARN "Pools configuration file '$($Variables.PoolsConfigFile)' is corrupt."
        }
    }

    #Add pool config to config (in-memory only)
    $PoolsConfig = [Ordered]@{ }
    $Config.PoolName | ForEach-Object { 
        $PoolName = $_ -replace "24hr" -replace "Coins"
        $PoolConfig = [PSCustomObject]@{ }
        If ($PoolsConfig_Tmp.$PoolName) { $PoolConfig = $PoolsConfig_Tmp.$PoolName | ConvertTo-Json -ErrorAction Ignore | ConvertFrom-Json }
        If (-not "$PoolConfig") { #https://stackoverflow.com/questions/53181472/what-operator-should-be-used-to-detect-an-empty-psobject
            If ($PoolsConfig_Tmp.Default) { $PoolConfig = $PoolsConfig_Tmp.Default | ConvertTo-Json | ConvertFrom-Json }
        }
        If (-not $PoolConfig.PayoutCurrency) { $PoolConfig | Add-Member PayoutCurrency $Config.PayoutCurrency -Force }
        If (-not $PoolConfig.PricePenaltyFactor) { $PoolConfig | Add-Member PricePenaltyFactor $Config.PricePenaltyFactor -Force }
        If (-not $PoolConfig.WorkerName) { $PoolConfig | Add-Member WorkerName $Config.WorkerName -Force }
        Switch ($PoolName) { 
            "MPH" { 
                If (-not $PoolConfig.UserName) { $PoolConfig | Add-Member UserName $Config.MPHUserName -Force }
            }
            "NiceHash" { 
                If (-not $PoolConfig.Wallet) { $PoolConfig | Add-Member Wallet $Config.NiceHashWallet -Force }
                If (-not $PoolConfig.Wallet) { $PoolConfig | Add-Member Wallet $Config.Wallet -Force }
                $PoolConfig | Add-Member NiceHashWalletIsInternal $Config.NiceHashWalletIsInternal -ErrorAction Ignore
            }
            "ProHashing" { 
                If (-not $PoolConfig.UserName) { $PoolConfig | Add-Member UserName $Config.ProHashingUserName -Force }
            }
            Default { 
                If (-not $PoolConfig.Wallet) { $PoolConfig | Add-Member Wallet $Config.Wallet -Force }
            }
        }
        $PoolConfig.WorkerName = $PoolConfig.WorkerName -replace "^ID="
        $PoolsConfig.$PoolName = $PoolConfig
    }
    $Config.PoolsConfig = $PoolsConfig
}

Function Write-Config { 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ConfigFile
    )

    If ($Global:Config.ManualConfig) { Write-Message "Manual config mode - Not saving config"; Return }
    If ($Global:Config -is [Hashtable]) { 
        If (Test-Path $ConfigFile -PathType Leaf) {
            Copy-Item -Path $ConfigFile "$($ConfigFile).backup" -Force
        }
        ($Global:Config | Select-Object -Property * -ExcludeProperty PoolsConfig) | Get-SortedObject | ConvertTo-Json | Out-File $ConfigFile -Encoding UTF8 -Force
    }
}

Function Get-SortedObject { 
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Object]$Object
    )

    # Build an ordered hashtable of the property-value pairs.
    $SortedByProperties = [Ordered]@{ }
    Get-Member -Type NoteProperty -InputObject $Object | Sort-Object Name | ForEach-Object { 
        #Upper / lower case conversion (Web GUI is case sensitive)
        $PropertyName = $_.Name
        If ($Variables.AvailableCommandLineParameters | Where-Object { $_ -eq $PropertyName }) { $PropertyName = $Variables.AvailableCommandLineParameters | Where-Object { $_ -eq $PropertyName } }
        If ($Object.$PropertyName -is [PSCustomObject]) { 
            $SortedByProperties[$PropertyName] = Get-SortedObject $Object.$PropertyName
        }
        Else { 
            $SortedByProperties[$PropertyName] = $Object.$PropertyName
        }
    }
    $SortedByProperties
}

Function Set-Stat { 
    [CmdletBinding()]
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

        $ToleranceMin = $ToleranceMax = $Value

        If ($FaultDetection) { 
            $ToleranceMin = $Stat.Week * (1 - [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
            $ToleranceMax = $Stat.Week * (1 + [Math]::Min([Math]::Max($Stat.Week_Fluctuation * 2, 0.1), 0.9))
        }

        If ($ChangeDetection -and [Decimal]$Value -eq [Decimal]$Stat.Live) { $Updated = $Stat.Updated }

        If ($Value -lt $ToleranceMin -or $Value -gt $ToleranceMax) { 
            $Stat.ToleranceExceeded ++
        }
        Else { $Stat | Add-Member ToleranceExceeded ([UInt16]0) -Force }

        If ($Value -and $Stat.ToleranceExceeded -gt 0 -and $Stat.Week -gt 0 -and $Stat.ToleranceExceeded -lt $ToleranceExceeded) { 
            #Update immediately if stat value is 0
            If ($Name -match ".+_HashRate$") { 
                Write-Message -Level Warn "Failed saving hash rate ($($Name): $(($Value | ConvertTo-Hash) -replace '\s+', '')). It is outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) [Attempt $($Stat.ToleranceExceeded) of 3 until enforced update]."
            }
            ElseIf ($Name -match ".+_PowerUsage") { 
                Write-Message -Level Warn "Failed saving power usage ($($Name): $($Value.ToString("N2"))W). It is outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) [Attempt $($Stat.ToleranceExceeded) of 3 until enforced update]."
            }
        }
        Else { 
            If ($Value -eq 0 -or $Stat.ToleranceExceeded -eq $ToleranceExceeded) { 
                #Update immediately if stat value is 0
                If ($Value) { 
                    If ($Name -match ".+_HashRate$") { 
                        Write-Message -Level Warn "Saved hash rate ($($Name): $(($Value | ConvertTo-Hash) -replace '\s+', '')). It was forcefully updated because it was outside fault tolerance ($(($ToleranceMin | ConvertTo-Hash) -replace '\s+', ' ') to $(($ToleranceMax | ConvertTo-Hash) -replace '\s+', ' ')) for $($Stat.ToleranceExceeded) times in a row."
                    }
                    ElseIf ($Name -match ".+_PowerUsage$") { 
                        Write-Message -Level Warn "Saved power usage ($($Name): $($Value.ToString("N2"))W). It was forcefully updated because it was outside fault tolerance ($($ToleranceMin.ToString("N2"))W to $($ToleranceMax.ToString("N2"))W) for $($Stat.ToleranceExceeded) times in a row."
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
    Param(
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
    Param(
        [Parameter(Mandatory = $false)]
        [String[]]$Name = @($Global:Stats.Keys | Select-Object) + @(Get-ChildItem "Stats" -ErrorAction Ignore | Select-Object -ExpandProperty BaseName)
    )

    $Name | Sort-Object -Unique | ForEach-Object { 
       Remove-Item -Path "Stats\$_.txt" -Force -Confirm:$false -ErrorAction SilentlyContinue
        If ($Global:Stats.$_) { $Global:Stats.Remove($_) }
    }
}

Function Get-CommandPerDevice { 

    # filters the command to contain only parameter values for present devices
    # if a parameter has multiple values, only the values for the available devices are included
    # parameters with a single value are valid for all devices and remain untouched
    # excluded parameters are passed unmodified

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]$Command = "", 
        [Parameter(Mandatory = $false)]
        [String[]]$ExcludeParameters = "", 
        [Parameter(Mandatory = $false)]
        [Int[]]$DeviceIDs
    )

    $CommandPerDevice = ""

    " $($Command.TrimStart().TrimEnd())" -split "(?=\s+[-]{1,2})" | ForEach-Object { 
        $Token = $_
        $Prefix = ""
        $ParameterValueSeparator = ""
        $ValueSeparator = ""
        $Values = ""

        If ($Token -match "(?:^\s[-=]+)" <#supported prefix characters are listed in brackets [-=]#>) { 
            $Prefix = "$($Token -split $Matches[0] | Select-Object -Index 0)$($Matches[0])"
            $Token = $Token -split $Matches[0] | Select-Object -Last 1

            If ($Token -match "(?:[ =]+)" <#supported separators are listed in brackets [ =]#>) { 
                $ParameterValueSeparator = $Matches[0]
                $Parameter = $Token -split $ParameterValueSeparator | Select-Object -Index 0
                $Values = $Token.Substring(("$Parameter$($ParameterValueSeparator)").length)

                If ($Parameter -notin $ExcludeParameters -and $Values -match "(?:[,; ]{1})" <#supported separators are listed in brackets [,; ]#>) { 
                    $ValueSeparator = $Matches[0]
                    $RelevantValues = @()
                    $DeviceIDs | ForEach-Object { 
                        $RelevantValues += ($Values.Split($ValueSeparator) | Select-Object -Index $_)
                    }
                    $CommandPerDevice += "$Prefix$Parameter$ParameterValueSeparator$($RelevantValues -join $ValueSeparator)"
                }
                Else { $CommandPerDevice += "$Prefix$Parameter$ParameterValueSeparator$Values" }
            }
            Else { $CommandPerDevice += "$Prefix$Token" }
        }
        Else { $CommandPerDevice += $Token }
    }
    $CommandPerDevice
}

Function Get-ChildItemContent { 
    [CmdletBinding()]
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

    $DefaultPriority = ([System.Diagnostics.Process]::GetCurrentProcess()).PriorityClass
    If ($Priority) { ([System.Diagnostics.Process]::GetCurrentProcess()).PriorityClass = $Priority } Else { $Priority = $DefaultPriority }

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
                $Expression | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { 
                    $Expression.$_ = Invoke-ExpressionRecursive $Expression.$_
                }
            }
            Return $Expression
        }

        Get-ChildItem $Path -File -ErrorAction SilentlyContinue | ForEach-Object { 
            $Name = $_.BaseName
            $Content = @()
            If ($_.Extension -eq ".ps1") { 
                $Content = & { 
                    If ($Parameters.Count) { 
                        $Parameters.Keys | ForEach-Object { Set-Variable $_ $Parameters.$_ }
                        & $_.FullName @Parameters
                    }
                    Else { 
                        & $_.FullName
                    }
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
        $PowerShell = [PowerShell]::Create().AddScript($ScriptBlock)
        [Void]$PowerShell.AddArgument($Path)
        [Void]$PowerShell.AddArgument($Parameters)
        [Void]$PowerShell.AddArgument($Priority)

        $Job = $PowerShell.BeginInvoke()
        $PowerShell | Add-Member Job $Job

        Return $PowerShell
    }
    Else { 
        Return (& $ScriptBlock -Path $Path -Parameters $Parameters)
    }
}

Function Invoke-TcpRequest { 
     
    Param(
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
        $Client.SendTimeout = $Timeout * 1000
        $Client.ReceiveTimeout = $Timeout * 1000
        $Writer.AutoFlush = $true

        $Writer.WriteLine($Request)
        $Response = $Reader.ReadLine()
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

    If ($nExIds -ge 0x80000001) { 

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
        Features = $features.Keys.ForEach{ If ($features.$_) { $_ } }
    }
}

Function Get-Device { 
    [CmdletBinding()]
    Param(
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
                            Default { $Device_CIM.Manufacturer -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
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
                $Device.Model = (($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor) -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]'

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id++
                $Vendor_Id.($Device.Vendor)++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                $Type_Id.($Device.Type)++

                #Read CPU features
                $Device | Add-Member CpuFeatures ((Get-CpuId).Features | Sort-Object)

                #Add raw data
                $Device | Add-Member @{ 
                    CIM = $Device_CIM
                }
            }

            Get-CimInstance CIM_VideoController | ForEach-Object { 
                $Device_CIM = $_ | ConvertTo-Json | ConvertFrom-Json

                If ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { 
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
                                Default { $Device_CIM.AdapterCompatibility -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
                            }
                        )
                        Memory = [Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize'))
                    }
                }
                Else { 
                    #Add normalised values
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
                                Default { $Device_CIM.AdapterCompatibility -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
                            }
                        )
                        Memory = [Math]::Max(([UInt64]$Device_CIM.AdapterRAM), ([uInt64]$Device_Reg.'HardwareInformation.qwMemorySize'))
                    }
                }

                $Device | Add-Member @{ 
                    Id             = [Int]$Id
                    Type_Id        = [Int]$Type_Id.($Device.Type)
                    Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                    Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                }

                $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]'

                If (-not $Type_Vendor_Id.($Device.Type)) { 
                    $Type_Vendor_Id.($Device.Type) = @{ }
                }

                $Id++
                $Vendor_Id.($Device.Vendor)++
                $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                $Type_Id.($Device.Type)++

                #Add raw data
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

        #Get OpenCL data
        Try { 
            [OpenCl.Platform]::GetPlatformIDs() | ForEach-Object { 
                [OpenCl.Device]::GetDeviceIDs($_, [OpenCl.DeviceType]::All) | ForEach-Object { 
                    $Device_OpenCL = $_ | ConvertTo-Json | ConvertFrom-Json

                    #Add normalised values
                    $Device = [PSCustomObject]@{ 
                        Name   = $null
                        Model  = $Device_OpenCL.Name
                        Type   = $(
                            Switch -Regex ([String]$Device_OpenCL.Type) { 
                                "CPU" { "CPU" }
                                "GPU" { "GPU" }
                                Default { [String]$Device_OpenCL.Type -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
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
                                Default { [String]$Device_OpenCL.Vendor -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]' }
                            }
                        )
                        Memory = [UInt64]$Device_OpenCL.GlobalMemSize
                    }

                    $Device | Add-Member @{ 
                        Id             = [Int]$Id
                        Type_Id        = [Int]$Type_Id.($Device.Type)
                        Vendor_Id      = [Int]$Vendor_Id.($Device.Vendor)
                        Type_Vendor_Id = [Int]$Type_Vendor_Id.($Device.Type).($Device.Vendor)
                    }

                    $Device.Name = "$($Device.Type)#$('{0:D2}' -f $Device.Type_Id)"
                    $Device.Model = ((($Device.Model -split ' ' -replace 'Processor', 'CPU' -replace 'Graphics', 'GPU') -notmatch $Device.Type -notmatch $Device.Vendor -notmatch "$([UInt64]($Device.Memory/1GB))GB") + "$([UInt64]($Device.Memory/1GB))GB") -join ' ' -replace '\(R\)|\(TM\)|\(C\)|Series|GeForce' -replace '[^A-Z0-9]'

                    If ($Variables.Devices | Where-Object Type -EQ $Device.Type | Where-Object Bus -EQ $Device.Bus) { 
                        $Device = $Variables.Devices | Where-Object Type -EQ $Device.Type | Where-Object Bus -EQ $Device.Bus
                    }
                    ElseIf ($Device.Type -eq "GPU" -and ($Device.Vendor -eq "AMD" -or $Device.Vendor -eq "NVIDIA")) { 
                        $Variables.Devices += $Device

                        If (-not $Type_Vendor_Id.($Device.Type)) { 
                            $Type_Vendor_Id.($Device.Type) = @{ }
                        }
        
                        $Id++
                        $Vendor_Id.($Device.Vendor)++
                        $Type_Vendor_Id.($Device.Type).($Device.Vendor)++
                        $Type_Id.($Device.Type)++
                    }

                    #Add OpenCL specific data
                    $Device | Add-Member @{ 
                        Index                 = [Int]$Index
                        Type_Index            = [Int]$Type_Index.($Device.Type)
                        Vendor_Index          = [Int]$Vendor_Index.($Device.Vendor)
                        Type_Vendor_Index     = [Int]$Type_Vendor_Index.($Device.Type).($Device.Vendor)
                        PlatformId            = [Int]$PlatformId
                        PlatformId_Index      = [Int]$PlatformId_Index.($PlatformId)
                        Type_PlatformId_Index = [Int]$Type_PlatformId_Index.($Device.Type).($PlatformId)
                    }

                    #Add raw data
                    $Device | Add-Member @{ 
                        OpenCL = $Device_OpenCL
                    }

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

            $Variables.Devices | Where-Object Bus -Is [Int64] | Sort-Object Bus | ForEach-Object { 
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
        If (-not $Name -or ($Name_Devices | Where-Object { ($Device | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) -like ($_ | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) })) { 
            If (-not $ExcludeName -or -not ($ExcludeName_Devices | Where-Object { ($Device | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) -like ($_ | Select-Object ($_ | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name)) })) { 
                $Device
            }
        }
    }
}

Filter ConvertTo-Hash { 
    [CmdletBinding()]
    $Units = " kMGTPEZY " #k(ilo) in small letters, see https://en.wikipedia.org/wiki/Metric_prefix
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

    [CmdletBinding()]
    Param(
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

    # To get same numbering scheme regardless of value
    # Use $Offset to add/remove decimal places

    [CmdletBinding()]
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

function Start-SubProcess { 
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

    $EnvBlock | Select-Object | ForEach-Object { Set-Item -Path "Env:$($_ -split '=' | Select-Object -Index 0)" "$($_ -split '=' | Select-Object -Index 1)" -Force }

    $ScriptBlock = "Set-Location '$WorkingDirectory'; (Get-Process -Id `$PID).PriorityClass = '$(@{-2 = "Idle"; -1 = "BelowNormal"; 0 = "Normal"; 1 = "AboveNormal"; 2 = "High"; 3 = "RealTime"}[$Priority])'; "
    $ScriptBlock += "& '$FilePath'"
    If ($ArgumentList) { $ScriptBlock += " $ArgumentList" }
    $ScriptBlock += " *>&1"
    $ScriptBlock += " | Write-Output"
    If ($LogPath) { $ScriptBlock += " | Tee-Object '$LogPath'" }

    Start-Job ([ScriptBlock]::Create($ScriptBlock))
}

Function Invoke-CreateProcess {

    #Based on https://github.com/FuzzySecurity/PowerShell-Suite/blob/master/Invoke-CreateProcess.ps1

    Param (
        [Parameter(Mandatory = $true)]
        [String]$Binary,
        [Parameter(Mandatory = $false)]
        [String]$ArgumentList = $null,
        [Parameter(Mandatory = $false)]
        [String]$WorkingDirectory = "", 
        [Parameter(Mandatory = $false)]
        [ValidateRange(-2, 3)]
        [Int]$Priority = 0, #NORMAL
        [Parameter(Mandatory = $false)]
        [String[]]$EnvBlock = "",
        [Parameter(Mandatory = $false)]
        [String]$CreationFlags = 0x00000010, #CREATE_NEW_CONSOLE
        [Parameter(Mandatory = $false)]
        [String]$ShowMinerWindows = "minimized",
        [Parameter(Mandatory = $false)]
        [String]$StartF = 0x00000001 #STARTF_USESHOWWINDOW
    )

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

    $PriorityNames = [PSCustomObject]@{ -2 = "Idle"; -1 = "BelowNormal"; 0 = "Normal"; 1 = "AboveNormal"; 2 = "High"; 3 = "RealTime" }

    Switch ($ShowMinerWindows) {
        "hidden" { $ShowWindow = "0x0000" } #SW_HIDE
        "normal" { $ShowWindow = "0x0004" } #SW_SHOWNOACTIVATE
        Default  { $ShowWindow = "0x0007" } #SW_SHOWMINNOACTIVE
    }

    #Set local environment
    $EnvBlock | Select-Object | ForEach-Object { Set-Item -Path "Env:$($_ -split '=' | Select-Object -Index 0)" "$($_ -split '=' | Select-Object -Index 1)" -Force }

    #StartupInfo Struct
    $StartupInfo = New-Object STARTUPINFO
    $StartupInfo.dwFlags = $StartF # StartupInfo.dwFlag
    $StartupInfo.wShowWindow = $ShowWindow # StartupInfo.ShowWindow
    $StartupInfo.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($StartupInfo) # Struct Size

    #ProcessInfo Struct
    $ProcessInfo = New-Object PROCESS_INFORMATION

    #SECURITY_ATTRIBUTES Struct (Process & Thread)
    $SecAttr = New-Object SECURITY_ATTRIBUTES
    $SecAttr.Length = [System.Runtime.InteropServices.Marshal]::SizeOf($SecAttr)

    #CreateProcess --> lpCurrentDirectory
    If (-not $WorkingDirectory) { $WorkingDirectory = [IntPtr]::Zero }

    #Call CreateProcess
    [Kernel32]::CreateProcess($Binary, "$Binary $ArgumentList", [ref] $SecAttr, [ref] $SecAttr, $false, $CreationFlags, [IntPtr]::Zero, $WorkingDirectory, [ref] $StartupInfo, [ref] $ProcessInfo) | Out-Null

    $Process = Get-Process | Where-Object Id -EQ $ProcessInfo.dwProcessId
    If ($Process) { $Process.PriorityClass = $PriorityNames.$Priority }

    Return $Process
}

Function Start-SubProcessWithoutStealingFocus { 
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

    $PriorityNames = [PSCustomObject]@{ -2 = "Idle"; -1 = "BelowNormal"; 0 = "Normal"; 1 = "AboveNormal"; 2 = "High"; 3 = "RealTime" }

    $EnvBlock | Select-Object | ForEach-Object { Set-Item -Path "Env:$($_ -split '=' | Select-Object -Index 0)" "$($_ -split '=' | Select-Object -Index 1)" -Force }

    $Job = Start-Job -ArgumentList $PID, (Resolve-Path ".\Includes\CreateProcess.cs"), $FilePath, $ArgumentList, $WorkingDirectory { 
        Param($ControllerProcessID, $CreateProcessPath, $FilePath, $ArgumentList, $WorkingDirectory)

        $ControllerProcess = Get-Process -Id $ControllerProcessID
        If ($null -eq $ControllerProcess) { Return }

        #CreateProcess won't be usable inside this job if Add-Type is run outside the job
        Add-Type -Path $CreateProcessPath

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

        If ($WorkingDirectory -ne "") { $lpCurrentDirectory = $WorkingDirectory }
        Else { $lpCurrentDirectory = [IntPtr]::Zero }

        $lpStartupInfo = New-Object STARTUPINFO
        $lpStartupInfo.cb = [System.Runtime.InteropServices.Marshal]::SizeOf($lpStartupInfo)
        $lpStartupInfo.wShowWindow = [ShowWindow]::SW_SHOWMINNOACTIVE
        $lpStartupInfo.dwFlags = [STARTF]::STARTF_USESHOWWINDOW

        $lpProcessInformation = New-Object PROCESS_INFORMATION

        [Kernel32]::CreateProcess($lpApplicationName, $lpCommandLine, [ref] $lpProcessAttributes, [ref] $lpThreadAttributes, $bInheritHandles, $dwCreationFlags, $lpEnvironment, $lpCurrentDirectory, [ref] $lpStartupInfo, [ref] $lpProcessInformation)

        $Process = Get-Process -Id $lpProcessInformation.dwProcessId
        If ($null -eq $Process) { 
            [PSCustomObject]@{ ProcessId = $null }
            Return
        }

        [PSCustomObject]@{ProcessId = $Process.Id; ProcessHandle = $Process.Handle }

        $ControllerProcess.Handle | Out-Null
        $Process.Handle | Out-Null

        Do { If ($ControllerProcess.WaitForExit(1000)) { $Process.CloseMainWindow() | Out-Null } }
        While ($Process.HasExited -eq $false)
    }

    Do { Start-Sleep -MilliSeconds 50; $JobOutput = Receive-Job $Job }
    While ($null -eq $JobOutput)

    $Process = Get-Process | Where-Object Id -EQ $JobOutput.ProcessId
    If ($Process) { $Process.PriorityClass = $PriorityNames.$Priority }
    Return $Job
}

Function Expand-WebRequest { 
    [CmdletBinding()]
    Param(
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
    Param(
        [Parameter(Mandatory = $false)]
        [String]$Algorithm = ""
    )

    If (-not (Test-Path Variable:Global:Algorithms -ErrorAction SilentlyContinue)) {
        $Global:Algorithms = Get-Content ".\Includes\Algorithms.txt" | ConvertFrom-Json
    }

    $Algorithm = (Get-Culture).TextInfo.ToTitleCase(($Algorithm.ToLower() -replace "-", " " -replace "_", " " -replace "/", " ")) -replace " "

    If ($Global:Algorithms.$Algorithm) { $Global:Algorithms.$Algorithm }
    Else { $Algorithm }
}

Function Get-Region { 
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Region
    )

    If (-not (Test-Path Variable:Global:Regions -ErrorAction SilentlyContinue)) { 
        $Global:Regions = Get-Content ".\Includes\Regions.txt" | ConvertFrom-Json
    }

    $Region = (Get-Culture).TextInfo.ToTitleCase(($Region -replace "-", " " -replace "_", " ")) -replace " "

    If ($Global:Regions.$Region) { $Global:Regions.$Region }
    Else { $Region }
}

Function Initialize-Autoupdate { 
    # GitHub only supporting TLSv1.2 since feb 22 2018
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    Write-Message "Checking Autoupdate"
    Update-Notifications("Checking Auto Update")
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
            If ($Variables.MiningStatus -eq "Running") { $Config.autostart = $true }
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
                Return
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

            # Pre update specific actions if any
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

            # Remove any obsolete Optional miner file (ie. not in new version OptionalMiners)
            Get-ChildItem .\OptionalMiners\ | Where-Object { $_.name -notin (Get-ChildItem .\$UpdateFileName\OptionalMiners\).name } | ForEach-Object { Remove-Item -Recurse -Force $_.FullName }

            # Update Optional Miners to Miners if in use
            Get-ChildItem .\OptionalMiners\ | Where-Object { $_.name -in (Get-ChildItem .\Miners\).name } | ForEach-Object { Copy-Item -Force $_.FullName .\Miners\ }

            # Remove any obsolete miner file (ie. not in new version Miners or OptionalMiners)
            Get-ChildItem .\Miners\ | Where-Object { $_.name -notin (Get-ChildItem .\$UpdateFileName\Miners\).name -and $_.name -notin (Get-ChildItem .\$UpdateFileName\OptionalMiners\).name } | ForEach-Object { Remove-Item -Recurse -Force $_.FullName }

            # Post update specific actions if any
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
                    Return
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
