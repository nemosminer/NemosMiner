using module .\Includes\Include.psm1
using module .\Includes\Core.psm1

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
version:        3.8.1.3
version date:   07 February 2020
#>

param(
    [Parameter(Mandatory = $false)]
    [Double]$ActiveMinerGainPct = 21, # percent of advantage that active miner has over candidates in term of profit
    [Parameter(Mandatory = $false)]
    [String[]]$Algorithm = @(), #i.e. @("Ethash", "Equihash", "Cryptonight") etc.
    [Parameter(Mandatory = $false)]
    [Int]$API_ID = 0, 
    [Parameter(Mandatory = $false)]
    [String]$API_Key = "", 
    [Parameter(Mandatory = $false)]
    [Int]$APIPort = 3999,
    [Parameter(Mandatory = $false)]
    [Boolean]$Autoupdate = $true, # Autoupdate
    [Parameter(Mandatory = $false)]
    [String]$ConfigFile = ".\Config\config.json",
    [Parameter(Mandatory = $false)]
    [String[]]$Currency = @("USD"), #i.e. GBP,USD,AUD,NZD ect.
    [Parameter(Mandatory = $false)]
    [Int]$Delay = 1, #seconds before opening each miner
    [Parameter(Mandatory = $false)]
    [String[]]$DeviceName = @("GPU#01"), #Will replace old device selection, e.g. @("GPU#01") (t.b.d.)
    [Parameter(Mandatory = $false)]
    [Int]$Donate = 13, #Minutes per Day
    [Parameter(Mandatory = $false)]
    [String[]]$ExcludeDeviceName = @(), #Will replace old device selection, e.g. @("CPU#00", "GPU#02") (t.b.d.)
    [Parameter(Mandatory = $false)]
    [Int]$FirstInterval = 120, #seconds of the first cycle of activated or started first time miner
    [Parameter(Mandatory = $false)]
    [Int]$GPUCount = 1, # Number of GPU on the system
    [Parameter(Mandatory = $false)]
    [Double]$IdlePowerUsageW = 60, #Powerusage of idle system in Watt. Part of profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnoreMinerFee = $false, #If true, NM will ignore miner fee for earning & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePoolFee = $false, #If true NM will ignore pool fee for earning & profit calculation
    [Parameter(Mandatory = $false)]
    [Switch]$IgnorePowerCost = $false, #If true, NM will ignore power cost in best miner selection, instead miners with best earnings will be selected
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 240, #seconds before between cycles after the first has passed 
    [Parameter(Mandatory = $false)]
    [String]$Location = "US", #europe/us/asia
    [Parameter(Mandatory = $false)]
    [String[]]$LogLevel = @("Info", "Warning", "Error", "Verbose", "Debug"), #Log level detail, see Write-Message function
    [Parameter(Mandatory = $false)]
    [Double]$MarginOfError = 0, #0.4, # knowledge about the past won't help us to predict the future so don't pretend that Week_Fluctuation means something real
    [Parameter(Mandatory = $false)]
    [String[]]$MinerName = @(), 
    [Parameter(Mandatory = $false)]
    [Switch]$MeasurePowerUsage = $true, #If true, power usage will be read from miners, required for true profit calculation
    [Parameter(Mandatory = $false)]
    [Int]$MinMinHashRateSamples = 20, #Minimum number of hash rate samples required to store hash rate
    [Parameter(Mandatory = $false)]
    [Switch]$OpenFirewallPorts = $true, #If true, NemosMiner will open firewall ports for all miners (requires admin rights!)
    [Parameter(Mandatory = $false)]
    [String]$Passwordcurrency = "BTC", #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [String[]]$PoolName = @(), 
    [Parameter(Mandatory = $false)]
    [Hashtable]$PowerPricekWh = [Hashtable]@{"00:00" = 0.26; "12:00" = 0.3}, #Price of power per kW⋅h (in $Currency, e.g. CHF), valid from HH:mm (24hr format)
    [Parameter(Mandatory = $false)]
    [Double]$ProfitabilityThreshold = -99, #Minimum profit threshold, if profit is less than the configured value (in $Currency, e.g. CHF) mining will stop (except for benchmarking & power usage measuring)
    [Parameter(Mandatory = $false)]
    [String]$Proxy = "", #i.e http://192.0.0.1:8080 
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
    [String]$SelGPUCC = "0,1",
    [Parameter(Mandatory = $false)]
    [String]$SelGPUDSTM = "0 1",
    [Parameter(Mandatory = $false)]
    [Switch]$SSL = $false, 
    [Parameter(Mandatory = $false)]
    [Int]$StatsInterval = 270, #seconds of current active to gather hashrate if not gathered yet
    [Parameter(Mandatory = $false)]
    [Boolean]$TrackEarnings = $true, # Display earnings information
    [Parameter(Mandatory = $false)]
    [String[]]$Type = @("nvidia"), #AMD/NVIDIA/CPU
    [Parameter(Mandatory = $false)]
    [String]$UIStyle = "Light", # Light or Full. Defines level of info displayed
    [Parameter(Mandatory = $false)]
    [String]$UserName = "Nemo", 
    [Parameter(Mandatory = $false)]
    [String]$Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE", 
    [Parameter(Mandatory = $false)]
    [String]$WorkerName = "ID=NemosMiner-v3.8.1.3"
)

# Enable for debug only!
#$DebugLoop = $true
Set-Location (Split-Path $MyInvocation.MyCommand.Path)

@"
NemosMiner
Copyright (c) 2018-$((Get-Date).Year) Nemo and MrPlus
This is free software, and you are welcome to redistribute it
under certain conditions.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE

"@
Write-Host -F Yellow "Copyright and license notices must be preserved."
@"
"@

# Load Branding
$Branding = [PSCustomObject]@{ 
    LogoPath     = "https://raw.githubusercontent.com/Minerx117/UpDateData/master/NM.png"
    BrandName    = "NemosMiner"
    BrandWebSite = "https://nemosminer.com"
    ProductLabel = "NemosMiner"
}

#Initialize variables
New-Variable Config ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
New-Variable Variables ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
New-Variable Stats ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop

Get-Config -ConfigFile $ConfigFile

$Config | Add-Member -Force -MemberType ScriptProperty -Name "PoolsConfig" -Value { 
    If (Test-Path ".\Config\PoolsConfig.json" -PathType Leaf) { 
        Get-Content ".\Config\PoolsConfig.json" | ConvertFrom-json
    }
    Else { 
        [PSCustomObject]@{ default = [PSCustomObject]@{ 
                Wallet             = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"
                UserName           = "nemo"
                WorkerName         = "NemosMinerNoCfg"
                PricePenaltyFactor = 1
            }
        }
    }
}

#Add Default values if not in config file
$MyInvocation.MyCommand.Parameters.Keys | Where-Object { $_ -ne "ConfigFile" -and (Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue) } | Sort-Object | ForEach-Object { 
    $Config_Parameter = Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue
    If ($Config_Parameter -is [Switch]) { $Config_Parameter = [Boolean]$Config_Parameter }
    $Config | Add-Member @{ $_ = $(Get-Variable $_ -ValueOnly -ErrorAction SilentlyContinue) } -ErrorAction SilentlyContinue
#    $Config | Add-Member @{ $_ = "`$$_" } -ErrorAction Ignore
}

$Variables | Add-Member -Force @{ ConfigFile = $ConfigFile }
$Variables | Add-Member -Force @{ LogFile = ".\Logs\NemosMiner_$(Get-Date -Format "yyyy-MM-dd").txt" }
$Variables | Add-Member -Force -MemberType ScriptProperty -Name 'StatusText' -Value { $This._StatusText; $This._StatusText = @() } -SecondValue { If (-not $This._StatusText) { $This._StatusText = @() } ; $This._StatusText += $args[0]; $Variables | Add-Member -Force @{ RefreshNeeded = $true } }

Write-Message "Starting $($Branding.ProductLabel)® v$((Get-Content ".\Config\version.json" | ConvertFrom-Json).Version) © 2017-$((Get-Date).Year) Nemo and MrPlus"
Write-Message "Using configuration file ($([IO.Path]::GetFullPath($ConfigFile)))."

#Initialize API (for debug purposes)
If (Test-Path -Path .\Includes\API.psm1 -PathType Leaf) { 
    Import-Module .\Includes\API.psm1
    Start-APIServer -Port $APIPort
}

Function Global:TimerUITick { 
    $TimerUI.Enabled = $false

    Set-Location $Variables.MainPath

    # If something (pause button, idle timer) has set the RestartCycle flag, stop and start mining to switch modes immediately
    If ($Variables.RestartCycle) { 
        $Variables.RestartCycle = $false
        Stop-Mining
        Start-Mining
        If ($Variables.Paused) { 
            $EarningsDGV.DataSource = [System.Collections.ArrayList]@()
            $RunningMinersDGV.DataSource = [System.Collections.ArrayList]@()
            $WorkersDGV.DataSource = [System.Collections.ArrayList]@()
            $LabelBTCD.ForeColor = [System.Drawing.Color]::Red
            $TimerUI.Stop
        }
    }

    If ($Variables.RefreshNeeded -and $Variables.Started -and -not $Variables.Paused) { 
        $LabelBTCD.ForeColor = [System.Drawing.Color]::Green
        Start-ChildJobs

        $Variables.EarningsTrackerJobs | Where-Object { $_.state -eq "Running" } | ForEach-Object { 
            $EarnTrack = $_ | Receive-Job
            If ($EarnTrack) { 
                $EarnTrack | Where-Object { $_.Pool -ne "" } | Sort-Object date, pool | Select-Object -Last ($EarnTrack.Pool | Sort-Object -Unique).Count | ForEach-Object { $Variables.Earnings.($_.Pool) = $_ }
                Remove-Variable EarnTrack
            }
        }

        If ((Compare-Object -ReferenceObject $CheckedListBoxPools.Items -DifferenceObject ((Get-ChildItem ".\Pools").BaseName | Sort-Object -Unique) | Where-Object { $_.SideIndicator -eq "=>" }).InputObject -gt 0) { 
            (Compare-Object -ReferenceObject $CheckedListBoxPools.Items -DifferenceObject ((Get-ChildItem ".\Pools").BaseName | Sort-Object -Unique) | Where-Object { $_.SideIndicator -eq "=>" }).InputObject | ForEach-Object { If ($_ -ne $null) { } $CheckedListBoxPools.Items.AddRange($_) }
            $Config.PoolName | ForEach-Object { $CheckedListBoxPools.SetItemChecked($CheckedListBoxPools.Items.IndexOf($_), $true) }
        }
        $Variables | Add-Member -Force @{ InCycle = $true }
        # $MainForm.Number +=1 
        $MainForm.Text = "$($Branding.ProductLabel) $($Variables.CurrentVersion) Runtime: {0:dd\ \d\a\y\s\ hh\ \h\r\s\ mm\ \m\i\n\s} Path: $(Split-Path $script:MyInvocation.MyCommand.Path)" -f ([TimeSpan]((Get-Date) - $Variables.ScriptStartDate))
        $host.UI.RawUI.WindowTitle = $MainForm.Text

        If ($Variables.EndLoop) { 
            CheckBoxSwitching_Click

            # Fixed memory leak to chart object not being properly disposed in 5.3.0
            # https://stackoverflow.com/questions/8466343/why-controls-do-not-want-to-get-removed

            If ((Test-Path ".\Logs\DailyEarnings.csv" -PathType Leaf) -and (Test-Path ".\Includes\Charting.ps1" -PathType Leaf)) { 
                $Chart1 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'Front7DaysEarnings' -Width 505 -Height 105"
                $Chart1.top = 54
                $Chart1.left = 0
                $RunPage.Controls.Add($Chart1)
                $Chart1.BringToFront()

                $Chart2 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'DayPoolSplit' -Width 200 -Height 105"
                $Chart2.top = 54
                $Chart2.left = 500
                $RunPage.Controls.Add($Chart2)
                $Chart2.BringToFront()

                $RunPage.Controls | Where-Object { ($_.GetType()).name -eq "Chart" -and $_ -ne $Chart1 -and $_ -ne $Chart2 } | ForEach-Object { $RunPage.Controls[$RunPage.Controls.IndexOf($_)].Dispose(); $RunPage.Controls.Remove($_) }
            }

            If ($Variables.Earnings -and $Config.TrackEarnings) { 
                $DisplayEarnings = [System.Collections.ArrayList]@($Variables.Earnings.Values | Select-Object @(
                    @{ Name = "Pool"; Expression = { $_.Pool } }, 
                    @{ Name = "Trust"; Expression = { "{0:P0}" -f $_.TrustLevel } }, 
                    @{ Name = "Balance"; Expression = { [decimal]$_.Balance } }, 
                    @{ Name = "BTC/D"; Expression = { "{0:N8}" -f ($_.BTCD) } }, 
                    @{ Name = "m$([char]0x20BF) in 1h"; Expression = { "{0:N6}" -f ($_.Growth1 * 1000 * 24) } }, 
                    @{ Name = "m$([char]0x20BF) in 6h"; Expression = { "{0:N6}" -f ($_.Growth6 * 1000 * 4) } }, 
                    @{ Name = "m$([char]0x20BF) in 24h"; Expression = { "{0:N6}" -f ($_.Growth24 * 1000) } }, 
                    @{ Name = "Est. Pay Date"; Expression = { If ($_.EstimatedPayDate -is 'DateTime') { $_.EstimatedPayDate.ToShortDateString() } Else { $_.EstimatedPayDate } } }, 
                    @{ Name = "PaymentThreshold"; Expression = { "$($_.PaymentThreshold) ($('{0:P0} ' -f $($_.Balance / $_.PaymentThreshold)))" } }
                    
                ) | Sort-Object "m$([char]0x20BF) in 1h", "m$([char]0x20BF) in 6h", "m$([char]0x20BF) in 24h" -Descending)
                $EarningsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEarnings)
                $EarningsDGV.ClearSelection()
            }

            If ($Variables.Miners) { 
                $DisplayEstimations = [System.Collections.ArrayList]@($Variables.Miners | Select-Object @(
                    @{ Name = "Miner"; Expression = { $_.Name } },
                    @{ Name = "Algorithm(s)"; Expression = { $_.HashRates.PSObject.Properties.Name -join ' & ' } }, 
                    @{ Name = "PowerUsage"; Expression = { "$($_.PowerUsage.ToString("N3")) W" } }, 
                    @{ Name = "Speed"; Expression = { ($_.HashRates.PSObject.Properties.Value | ForEach-Object { If ($_ -ne $null) { "$($_ | ConvertTo-Hash)/s" -replace '\s+', ' ' } Else { "Benchmarking" } }) -join ' & ' } }, 
                    @{ Name = "mBTC/Day"; Expression = { ($_.Earnings.PSObject.Properties.Value | ForEach-Object { If ($_ -ne $null) { ($_ * 1000).ToString("N3") } Else { "Unknown" } }) -join ' + ' } }, 
                    @{ Name = "$($Config.Currency | Select-Object -Index 0)/Day"; Expression = { ($_.Earnings.PSObject.Properties.Value | ForEach-Object { If ($_ -ne $null) { ($_ * ($Variables.Rates.($Config.Currency | Select-Object -Index 0))).ToString("N3") } Else { "Unknown" } }) -join ' + ' } }, 
                    @{ Name = "BTC/GH/Day"; Expression = { ($_.Pools.PSObject.Properties.Value.Price | ForEach-Object { ($_ * 1000000000).ToString("N5") }) -join ' + ' } }, 
                    @{ Name = "Pool(s)"; Expression = { ($_.Pools.PSObject.Properties.Value | ForEach-Object { (@($_.Name | Select-Object) + @($_.Coin | Select-Object)) -join '-' }) -join ' & ' } }
                ) | Sort-Object "mBTC/Day" -Descending)
                $EstimationsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEstimations)
            }
            $EstimationsDGV.ClearSelection()

            $SwitchingDGV.ClearSelection()

            If ($Variables.Workers -and $Config.ShowWorkerStatus) { 
                $DisplayWorkers = [System.Collections.ArrayList]@($Variables.Workers | Select-Object @(
                    @{ Name = "Worker"; Expression = { $_.worker } }, 
                    @{ Name = "Status"; Expression = { $_.status } }, 
                    @{ Name = "Last Seen"; Expression = { $_.timesincelastreport } }, 
                    @{ Name = "Version"; Expression = { $_.version } }, 
                    @{ Name = "Est. BTC/Day"; Expression = { [decimal]$_.profit } }, 
                    @{ Name = "Miner"; Expression = { $_.data.name -join ',' } }, 
                    @{ Name = "Pool"; Expression = { $_.data.pool -join ',' } }, 
                    @{ Name = "Algo(s)"; Expression = { $_.data.algorithm -join ',' } }, 
                    @{ Name = "Speed(s)"; Expression = { If ($_.data.currentspeed) { ($_.data.currentspeed | ConvertTo-Hash) -join ',' } Else { "" } } }, 
                    @{ Name = "Benchmark Speed"; Expression = { If ($_.data.estimatedspeed) { ($_.data.estimatedspeed | ConvertTo-Hash) -join ',' } Else { "" } } }
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
                $LabelMonitoringWorkers.text = "Worker Status - Updated $($Variables.WorkersLastUpdated.ToString())"
            }

            If ($Variables.ActiveMiners) { 
                $RunningMinersDGV.DataSource = [System.Collections.ArrayList]@($Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" } | Select-Object Type, @{ Name = "Algorithm(s)"; Expression = { $_.Pools.PSObject.Properties.Value.Algorithm -join "; " } }, Name, @{ Name = "HashRate(s)"; Expression = { "$($_.HashRates.PSObject.Properties.Value | ConvertTo-Hash)/s" -join "; " } }, @{ Name = "Active"; Expression = { "{0:%h}:{0:mm}:{0:ss}" -f $_.Active } }, @{ Name = "Total Active"; Expression = { "{0:%h}:{0:mm}:{0:ss}" -f $_.TotalActive } }, @{ Name = "Host(s)"; Expression = { (($_.Pools.PSObject.Properties.Value.Host | Select-Object -Unique) -join ';')} } | Sort-Object Type)
                $RunningMinersDGV.ClearSelection()
            
                [Array]$ProcessesRunning = $Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" }
                If ($ProcessesRunning -eq $null) { 
                    Write-Message "No miners running."
                }
            }
            $LabelBTCPrice.text = If ($Variables.Rates.$($Config.Currency | Select-Object -Index 0) -gt 0) { "1 BTC = $(($Variables.Rates.($Config.Currency | Select-Object -Index 0)).ToString('n')) $($Config.Currency | Select-Object -Index 0)" }
            $Variables | Add-Member -Force @{ InCycle = $false }

            If ($Variables.Earnings.Values -ne $null) { 
                $LabelBTCD.Text = "Avg: " + ("{0:N6}" -f ($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum) + " $([char]0x20BF)/D   |   " + ("{0:N3}" -f (($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000)) + " m$([char]0x20BF)/D"
                
                $LabelEarningsDetails.Lines = @()
                $TrendSign = Switch ([Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 1000 * 24), 3) - [Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth6 -Sum).sum * 1000 * 4), 3)) { 
                    { $_ -eq 0 } { "=" }
                    { $_ -gt 0 } { ">" }
                    { $_ -lt 0 } { "<" }
                }
                $LabelEarningsDetails.Lines += "Last  1h: " + ("{0:N3}" -f (($Variables.Earnings.Values | Measure-Object -Property Growth1 -Sum).sum * 1000 * 24)) + " m$([char]0x20BF)/D " + $TrendSign
                $TrendSign = Switch ([Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth6 -Sum).sum * 1000 * 4), 3) - [Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000), 3)) { 
                    { $_ -eq 0 } { "=" }
                    { $_ -gt 0 } { ">" }
                    { $_ -lt 0 } { "<" }
                }
                $LabelEarningsDetails.Lines += "Last  6h: " + ("{0:N3}" -f (($Variables.Earnings.Values | Measure-Object -Property Growth6 -Sum).sum * 1000 * 4)) + " m$([char]0x20BF)/D " + $TrendSign
                $TrendSign = Switch ([Math]::Round((($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000), 3) - [Math]::Round((($Variables.Earnings.Values | Measure-Object -Property BTCD -Sum).sum * 1000 * 0.96), 3)) { 
                    { $_ -eq 0 } { "=" }
                    { $_ -gt 0 } { ">" }
                    { $_ -lt 0 } { "<" }
                }
                $LabelEarningsDetails.Lines += "Last 24h: " + ("{0:N3}" -f (($Variables.Earnings.Values | Measure-Object -Property Growth24 -Sum).sum * 1000)) + " m$([char]0x20BF)/D " + $TrendSign
                Remove-Variable TrendSign
            }
            Else { 
                $LabelBTCD.Text = "Waiting data from pools."
                $LabelEarningsDetails.Lines = @()
            }

            $Variables | Add-Member -Force @{ CurrentProduct = (Get-Content .\Version.json | ConvertFrom-Json).Product }
            $Variables | Add-Member -Force @{ CurrentVersion = [Version](Get-Content .\Version.json | ConvertFrom-Json).Version }
            $Variables | Add-Member -Force @{ Autoupdated = (Get-Content .\Version.json | ConvertFrom-Json).Autoupdated.Value }
            If ((Get-Content .\Version.json | ConvertFrom-Json).Autoupdated -and $LabelNotifications.Lines[$LabelNotifications.Lines.Count - 1] -ne "Auto Updated on $($Variables.CurrentVersionAutoupdated)") { 
                $LabelNotifications.ForeColor = [System.Drawing.Color]::Green
                Update-Notifications("Running $($Variables.CurrentProduct) Version $([Version]$Variables.CurrentVersion)")
                Update-Notifications("Auto Updated on $($Variables.CurrentVersionAutoupdated)")
            }

            #Display mining information
            If ($host.UI.RawUI.Keyavailable) { 
                $KeyPressed = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp"); Start-Sleep -Milliseconds 300; $host.UI.RawUI.FlushInputBuffer()
                If ($KeyPressed.KeyDown) { 
                    Switch ($KeyPressed.Character) { 
                        "s" { If ($Config.UIStyle -eq "Light") { $Config.UIStyle = "Full" } Else { $Config.UIStyle = "Light" } }
                        "e" { $Config.TrackEarnings = -not $Config.TrackEarnings }
                    }
                }
            }
#            Clear-Host
            If ($Config.UIStyle -eq "Full" -and ([Array]$ProcessesIdle = $Variables.ActiveMiners | Where-Object { $_.Status -eq "Run Miners" })) { 
                Write-Host "Run Miners: " $ProcessesIdle.Count
                $ProcessesIdle | Sort-Object { If ($_.Process -eq $null) { (Get-Date) } Else { $_.Process.ExitTime } } | Format-Table -Wrap (
                    @{ Label = "Run"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } },
                    @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)" } }  
                ) | Out-Host
            }

            Write-Host "Exchange Rate: 1 BTC = $($Variables.Rates.($Config.Currency | Select-Object -Index 0).ToString('n')) $($Config.Currency | Select-Object -Index 0)"
            # Get and display earnings stats
            If ($Variables.Earnings -and $Config.TrackEarnings) { 
                $Variables.Earnings.Values | Sort-Object { $_.Pool } | ForEach-Object { 
                    Write-Host "+++++" $_.Wallet -B DarkBlue -F DarkGray -NoNewline; Write-Host " $($_.Pool)"
                    Write-Host "Trust Level:                $(($_.TrustLevel).ToString('P0'))" -NoNewline; Write-Host -F darkgray " (based on data from $(([DateTime]::parseexact($_.Date, (Get-Culture).DateTimeFormat.ShortDatePattern, $null) - [DateTime]$_.StartTime).ToString('%d\ \d\a\y\s\ hh\ \h\r\s\ mm\ \m\i\n\s')))"
                    Write-Host "Average mBTC/Hour:          $(($_.AvgHourlyGrowth * 1000).ToString('N6'))"
                    Write-Host "Average mBTC/Day:" -NoNewline; Write-Host "           $(($_.BTCD * 1000).ToString('N6'))" -F Yellow
                    Write-Host "Balance mBTC:               $(($_.Balance).ToString('N6')) ($(($_.Balance / $_.PaymentThreshold).ToString('P0')) of $(($_.PaymentThreshold).ToString('N3')) BTC payment threshold)"
                    Write-Host "Balance $($Config.Currency | Select-Object -Index 0):                $(($_.Balance * $Variables.Rates.($Config.Currency | Select-Object -Index 0)).ToString('N6')) ($(($_.Balance / $_.PaymentThreshold).ToString('P0')) of $(($_.PaymentThreshold * $Variables.Rates.($Config.Currency | Select-Object -Index 0)).ToString('n')) $($Config.Currency | Select-Object -Index 0) payment threshold)"
                    Write-Host "Estimated Pay Date:         $(if ($_.EstimatedPayDate -is [DateTime]) { ($_.EstimatedPayDate).ToShortDateString() } Else { "$($_.EstimatedPayDate)" })"
                }
            }

            If ($Variables.Miners | Where-Object { ($_.HashRates | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name) -eq $null }) { $Config.UIStyle = "Full" }

            #Display active miners list
            [System.Collections.ArrayList]$Miner_Table = @(
                @{ Label = "Miner"; Expression = { $_.Name } }, 
                @{ Label = "Algorithm(s)"; Expression = { $_.HashRates.PSObject.Properties.Name } }
            )
            If ($Config.ShowMinerFee -and ($Variables.Miners | Where-Object { $_.PSObject.Properties.Value.Fee })) { 
                $Miner_Table.AddRange(@(
                        @{ Label = "Fee"; Expression = { "{0:P2}" -f [Double]$_.Fee } }
                ))
            }
            $Miner_Table.AddRange(@(
                    @{ Label = "Speed(s)"; Expression = { $Miner = $_; ($_.HashRates.PSObject.Properties.Value | ForEach-Object { If ($_ -ne $null) { "$($_ | ConvertTo-Hash)/s" } Else { $(If ($Variables.ActiveMiners | Where-Object { $_.Path -eq $Miner.Path -and $_.Arguments -EQ $Miner.Arguments }) { "Benchmark in progress" } Else { "Benchmark pending" }) } }) }; Align = 'right' }
            ))
            If ($Config.ShowEarning) { 
                $Miner_Table.AddRange(@(
                        #Miner Earning
                        @{ Label = "Earning"; Expression = { If ($_.Earning -ne $null) { ConvertTo-LocalCurrency -Value ($_.Earning) -BTCRate ($Variables.Rates.($Config.Currency | Select-Object -Index 0)) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                ))
            }
            If ($Config.ShowEarningBias) { 
                $Miner_Table.AddRange(@(
                        #Miner EarningsBias
                        @{ Label = "EarningBias"; Expression = { If ($_.Earning_Bias -ne $null) { ConvertTo-LocalCurrency -Value ($_.Earning_Bias) -BTCRate ($Variables.Rates.($Config.Currency | Select-Object -Index 0)) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                ))
            }
            If ($Config.ShowPowerUsage) { 
                $Miner_Table.AddRange(@(
                        #Power Usage
                        @{ Label = "PowerUsage"; Expression = { $Miner = $_; if ($_.PowerUsage -ne $null) { "$($_.PowerUsage.ToString("N2")) W" } else { if ($Variables.ActiveMiners | Where-Object { $_.Path -eq $Miner.Path -and $_.Arguments -EQ $Miner.Arguments }) { "Measuring..." } else { "Unmeasured" } } }; Align = "right" }
                ))
            }
            If ($Config.ShowPowerCost -and ($Variables.Miners | Where-Object { $_.PowerCost })) { 
                $Miner_Table.AddRange(@(
                        #PowerCost
                        @{ Label = "PowerCost"; Expression = { If ($Variables.PowerPricekWh -eq 0) { (0).ToString("N$(Get-DigitsFromValue -Value $Variables.Rates.($Config.Currency | Select-Object -Index 0) -Offset 1)") } Else { If ($_.PowerUsage -ne $null) { "-$(ConvertTo-LocalCurrency -Value ($_.PowerCost) -BTCRate ($Variables.Rates.($Config.Currency | Select-Object -Index 0)) -Offset 1)" } Else { "Unknown" } } }; Align = "right" }
                ))
            }
            If ($Config.ShowProfit -and $Variables.PowerPricekWh) { 
                $Miner_Table.AddRange(@(
                        #Mining Profit
                        @{ Label = "Profit"; Expression = { If ($_.Profit -ne $null) { ConvertTo-LocalCurrency -Value ($_.Profit) -BTCRate ($Variables.Rates.($Config.Currency | Select-Object -Index 0)) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                ))
            }
            If ($Config.ShowProfitBias -and $Variables.PowerPricekWh) { 
                $Miner_Table.AddRange(@(
                        #Mining ProfitsBias
                        @{ Label = "ProfitBias"; Expression = { If ($_.Profit_Bias -ne $null) { ConvertTo-LocalCurrency -Value ($_.Profit_Bias) -BTCRate ($Variables.Rates.($Config.Currency | Select-Object -Index 0)) -Offset 1 } Else { "Unknown" } }; Align = "right" }
                ))
            }
            If ($Config.ShowAccuracy) { 
                $Miner_Table.AddRange(@(
                    @{ Label = "Accuracy"; Expression = { $_.Pools.PSObject.Properties.Value | ForEach-Object { "{0:P0}" -f [Double](1 - $_.MarginOfError) } }; Align = 'right' }
                ))
            }
            $Miner_Table.AddRange(@(
                    @{ Label = "Pool(s)"; Expression = { $_.Pools.PSObject.Properties.Value | ForEach-Object { $_.Name } } }
            ))
            If ($Config.ShowPoolFee -and ($Variables.Miners.Pools | Where-Object { $_.PSObject.Properties.Value.Fee })) { 
                #Show pool fees
                $Miner_Table.AddRange(@(
                        @{ Label = "Fee(s)"; Expression = { $_.Pools.PSObject.Properties.Value | ForEach-Object { "{0:P2}" -F [Double]$_.Fee } } }
                ))
            }
            If ($Variables.Miners.Pools | Where-Object { $_.PSObject.Properties.Value.Coin }) { 
                $Miner_Table.AddRange(@(
                        #Coin
                        @{ Label = "Coin(s)"; Expression = { $_.Pools.PSObject.Properties.Value.Coin | Foreach-Object { [String]$_ } } }
                ))
            }
            If ($Variables.Miners.Pools | Where-Object { $_.PSObject.Properties.Value.Info }) { 
                $Miner_Table.AddRange(@(
                        #Info
                        @{ Label = "Info(s)"; Expression = { $_.Pools.PSObject.Properties.Value.Info | Foreach-Object { [String]$_ } } }
                ))
            }
            $Variables.Miners | Group-Object -Property { $_.DeviceNames } | ForEach-Object { 
                $MinersDeviceGroup = @($_.Group)
                $MinersDeviceGroupNeedingBenchmark = @($MinersDeviceGroup | Where-Object { $_.HashRates.PSObject.Properties.Value -contains $null })
                $MinersDeviceGroupNeedingPowerUsageMeasurement = @($(if ($Config.MeasurePowerUsage) { @($MinersDeviceGroup | Where-Object PowerUsage -eq $null) }))
                $MinersDeviceGroup | Where-Object { 
                    $Config.ShowAllMiners -or <#List all miners#>

                    $_.Earning_Bias -ge ($MinersDeviceGroup.Earning_Bias | Sort-Object -Descending | Select-Object -Index 4) -or <#Always list at least the top 5 earning miners per device group#>
                    $_.Profit_Bias -ge ($MinersDeviceGroup.Profit_Bias | Sort-Object -Descending | Select-Object -Index 4) -or <#Always list at least the top 5 profit miners per device group#>

                    $_.Earning_Bias -ge (($MinersDeviceGroup.Earning_Bias | Sort-Object -Descending | Select-Object -Index 0) * 0.5) -or <#Always list the better 50% earning miners per device group#>
                    $_.Profit_Bias -ge (($MinersDeviceGroup.Profit_Bias | Sort-Object -Descending | Select-Object -Index 0) * 0.5) -or <#Always list the better 50% profit miners per device group#>

                    # $_.Earning -ge ($MinersDeviceGroup.Earning | Sort-Object -Descending | Select-Object -Index 4) -or <#Always list at least the top 5 earning miners per device group#>
                    # $_.Profit -ge ($MinersDeviceGroup.Profit | Sort-Object -Descending | Select-Object -Index 4) -or <#Always list at least the top 5 profit miners per device group#>

                    # $_.Earning -ge (($MinersDeviceGroup.Earning | Sort-Object -Descending | Select-Object -Index 0) * 0.5) -or <#Always list the better 50% earning miners per device group#>
                    # $_.Profit -ge (($MinersDeviceGroup.Profit | Sort-Object -Descending | Select-Object -Index 0) * 0.5) -or <#Always list the better 50% profit miners per device group#>

                    $MinersDeviceGroupNeedingBenchmark.Count -or <#List all miners when benchmarking#>
                    $MinersDeviceGroupNeedingPowerUsageMeasurement.Count <#List all miners when measuring power consumption#>

                } | Sort-Object DeviceNames, @{ Expression = $(If ($Config.IgnorePowerCost) { "Earning_Bias" } Else { "Profit_Bias" } ); Descending = $true }, @{ Expression = { $_.HashRates.PSObject.Properties.Name } } | Format-Table $Miner_Table -GroupBy @{ Name = "Device$(if (@($_).Count -ne 1) { "s" })"; Expression = { "$($_.DeviceNames -join ', ') [$(($Variables.ConfiguredDevices | Where-Object Name -eq $_.DeviceNames).Model -join ', ')]" } } | Out-Host

                #Display benchmarking progress
                if ($MinersDeviceGroupNeedingBenchmark) { 
                    Write-Message "Benchmarking for device$(If (($MinersDeviceGroup | Select-Object -Unique).Count -ne 1) { " group" } ) ($(($MinersDeviceGroup.DeviceNames | Select-Object -Unique ) -join '; ')) in progress: $($MinersDeviceGroupNeedingBenchmark.Count) miner$(If ($MinersDeviceGroupNeedingBenchmark.Count -gt 1){ 's' }) left to complete benchmark."
                }
                #Display power usage measurement progress
                if ($MinersDeviceGroupNeedingPowerUsageMeasurement) { 
                    Write-Message "Power usage measurement for device$(If (($MinersDeviceGroup | Select-Object -Unique).Count -ne 1) { " group" } ) ($(($MinersDeviceGroup.DeviceNames | Select-Object -Unique ) -join '; ')) in progress: $($MinersDeviceGroupNeedingPowerUsageMeasurement.Count) miner$(If ($MinersDeviceGroupNeedingPowerUsageMeasurement.Count -gt 1) { 's' }) left to complete measuring."
                }
            }
            Remove-Variable MinersDeviceGroup -ErrorAction SilentlyContinue
            Remove-Variable MinersDeviceGroupNeedingBenchmark -ErrorAction SilentlyContinue
            Remove-Variable MinersDeviceGroupNeedingPowerUsageMeasurement -ErrorAction SilentlyContinue
            Remove-Variable Miner_Table -ErrorAction SilentlyContinue

            If ($ProcessesRunning = @($Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" })) { 
                Write-Host "Running: $($ProcessesRunning.Count)" 
                $ProcessesRunning | Sort-Object { If ($_.Process -eq $null) { [DateTime]0 } Else { $_.Process.StartTime } } | Format-Table -Wrap (
                    @{ Label = "Speed"; Expression = { (($_.HashRates.Values | ForEach-Object { "$($_ | ConvertTo-Hash)/s" }) -join ' & ' ) -replace '\s+', ' ' }; Align = 'right' }, 
                    @{ Label = "PowerUsage"; Expression = { "$($_.PowerUsage.ToString("N3")) W" }; Align = 'right' }, 
                    @{ Label = "Active (this run)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $(If ($_.Process -eq $null) { 0 } Else { ((Get-Date) - $_.Process.StartTime) }) } }, 
                    @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f ($_.TotalActive + ((Get-Date) - $_.Process.StartTime) - $_.Active) } }, 
                    @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                    @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                ) | Out-Host
            }

            If ($Config.UIStyle -eq "Full") { 
                If ($ProcessesIdle = @($Variables.ActiveMiners | Where-Object { $_.Activated -and $_.Status -eq "Idle" })) { 
                    Write-Host "Previously Executed:"
                    $ProcessesIdle | Sort-Object { $_.Process.StartTime } -Descending | Select-Object -First ($Config.Type.Count * 3) | Format-Table -Wrap (
                        @{ Label = "Speed"; Expression = { (($_.HashRates.Values | ForEach-Object { "$($_ | ConvertTo-Hash)/s" }) -join ' & ' ) -replace '\s+', ' ' }; Align = 'right' }, 
                        @{ Label = "PowerUsage"; Expression = { "$($_.PowerUsage.ToString("N3")) W" }; Align = 'right' }, 
                        @{ Label = "Time since run"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $(If ($_.Process -eq $null) { 0 } Else { (Get-Date) - $_.Process.ExitTime }) } },
                        @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $_.TotalActive } }, 
                        @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                        @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                    ) | Out-Host
                }

                If ($ProcessesFailed = @($Variables.ActiveMiners | Where-Object { $_.Status -eq "Failed" })) { 
                    Write-Host -ForegroundColor Red "Failed: $($ProcessesFailed.Count)"
                    $ProcessesFailed | Sort-Object { If ($_.Process -eq $null) { [DateTime]0 } Else { $_.Process.StartTime } } | Format-Table -Wrap (
                        @{ Label = "Speed"; Expression = { (($_.HashRates.Values | ForEach-Object { "$($_ | ConvertTo-Hash)/s" }) -join ' & ' ) -replace '\s+', ' ' }; Align = 'right' }, 
                        @{ Label = "PowerUsage"; Expression = { "$($_.PowerUsage.ToString("N3")) W" }; Align = 'right' }, 
                        @{ Label = "Time since fail"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $(If ($_.Process -eq $null) { 0 } Else { (Get-Date) - $_.Process.ExitTime }) } },
                        @{ Label = "Active (total)"; Expression = { "{0:%h} hrs {0:mm} min {0:ss} sec" -f $_.TotalActive } }, 
                        @{ Label = "Cnt"; Expression = { Switch ($_.Activated) { 0 { "Never" } 1 { "Once" } Default { "$_" } } } }, 
                        @{ Label = "Command"; Expression = { "$($_.Path.TrimStart((Convert-Path ".\"))) $(Get-CommandLineParameters $_.Arguments)" } }
                    ) | Out-Host
                }
            }

            Write-Host "Profit, Earning & Power cost are in $($Config.Currency | Select-Object -Index 0)/day. Power cost: $($Config.Currency | Select-Object -Index 0) $(($Variables.PowerPricekWh).ToString("N$(Get-DigitsFromValue -Value $Variables.Rates.($Config.Currency | Select-Object -Index 0) -Offset 1)"))/kWh; Mining power cost: $($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value ($Variables.MiningCost) -BTCRate ($Variables.Rates.($Config.Currency | Select-Object -Index 0)) -Offset 1)/day; Base power cost: $($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value ($Variables.BasePowerCost) -BTCRate ($Variables.Rates.($Config.Currency | Select-Object -Index 0)) -Offset 1)/day."

            If ($Variables.MinersNeedingBenchmark.Count -eq 0 -and $Variables.MinersNeedingPowerUsageMeasurement.Count -eq 0) { 
                If ($Variables.MiningEarning -lt $Variables.MiningCost) { 
                    #Mining causes a loss
                    Write-Host "Mining is currently NOT profitable and causes a loss of $($Config.Currency | Select-Object -Index 0) $((($Variables.MiningEarning - $Variables.MiningCost - $Variables.BasePowerCost) * $Variables.Rates.($Config.Currency | Select-Object -Index 0)).ToString("N$(Get-DigitsFromValue -Value $Variables.Rates.($Config.Currency | Select-Object -Index 0) -Offset 1)"))/day."
                }
                If (($Variables.MiningEarning - $Variables.MiningCost) -lt $Config.ProfitabilityThreshold) { 
                    #Mining profit is below the configured threshold
                    Write-Message "Mining profit ($($Config.Currency | Select-Object -Index 0) $(ConvertTo-LocalCurrency -Value ($Variables.MiningEarning - $Variables.MiningCost) -BTCRate ($Variables.Rates.($Config.Currency | Select-Object -Index 0)) -Offset 1)) is below the configured threshold of $($Config.Currency | Select-Object -Index 0) $($Config.ProfitabilityThreshold.ToString("N$((Get-Culture).NumberFormat.CurrencyDecimalDigits)"))/day; mining is suspended until threshold is reached."
                }
            }
        
            Write-Host "--------------------------------------------------------------------------------"
            Write-Host -ForegroundColor Yellow "Last refresh: $((Get-Date).ToString('g'))   |   Next refresh: $((Get-Date).AddSeconds($Variables.TimeToSleep).ToString('g'))"
            #Write-Message $Variables.StatusText
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
            $MainForm.Number = $MainForm.Number + 1
            $TimerUI.Stop()
            TimerUITick
            If ($MainForm.Number -gt 6000) { 
                # Write-Host -B R "Releasing Timer"
                $MainForm.Number = 0
                # $TimerUI.Stop()
                $TimerUI.Remove_Tick( { TimerUITick })
                $TimerUI.Dispose()
                $TimerUI = New-Object System.Windows.Forms.Timer
                $TimerUI.Add_Tick( { TimerUITick })
                # $TimerUI.Start()
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
}

Function CheckedListBoxPools_Click ($Control) { 
    $Config | Add-Member -Force @{ $Control.Tag = $Control.CheckedItems }
    $EarningTrackerConfig = Get-Content ".\Config\EarningTrackerConfig.json" | ConvertFrom-JSON
    $EarningTrackerConfig | Add-Member -Force @{ "Pools" = ($Control.CheckedItems.Replace("24hr", "")).Replace("Plus", "") | Sort-Object -Unique }
    $EarningTrackerConfig | ConvertTo-Json | Out-File ".\Config\EarningTrackerConfig.json"
}

Function PrepareWriteConfig { 
    If ($Config.ManualConfig) {
        Write-Message "Manual config mode - Not saving config"
        Return
    }
    If ($Config -isnot [Hashtable]) { 
        New-Variable Config ([Hashtable]::Synchronized(@{ })) -Scope "Global" -Force -ErrorAction Stop
    }
    $Config | Add-Member -Force @{ $TBAddress.Tag = $TBAddress.Text }
    $Config | Add-Member -Force @{ $TBWorkerName.Tag = $TBWorkerName.Text }
    $ConfigPageControls | Where-Object { (($_.GetType()).Name -eq "CheckBox") } | ForEach-Object { $Config | Add-Member -Force @{ $_.Tag = $_.Checked } }
    $ConfigPageControls | Where-Object { (($_.GetType()).Name -eq "TextBox") } | ForEach-Object { $Config | Add-Member -Force @{ $_.Tag = $_.Text } }
    $ConfigPageControls | Where-Object { (($_.GetType()).Name -eq "TextBox") -and ($_.Tag -eq "GPUCount") } | ForEach-Object { 
        $Config | Add-Member -Force @{ $_.Tag = [Int]$_.Text }
        If ($CheckBoxDisableGPU0.checked -and [Int]$_.Text -gt 1) { $FirstGPU = 1 } Else { $FirstGPU = 0 }
        $Config | Add-Member -Force @{ SelGPUCC = (($FirstGPU..($_.Text - 1)) -join ",") }
        $Config | Add-Member -Force @{ SelGPUDSTM = (($FirstGPU..($_.Text - 1)) -join " ") }
    }
    $ConfigPageControls | Where-Object { (($_.GetType()).Name -eq "TextBox") -and ($_.Tag -eq "Algorithm") } | ForEach-Object { 
        $Config | Add-Member -Force @{ $_.Tag = @($_.Text -split ",") }
    }
    $ConfigPageControls | Where-Object { (($_.GetType()).Name -eq "TextBox") -and ($_.Tag -in @("Donate", "Interval", "ActiveMinerGainPct")) } | ForEach-Object { 
        $Config | Add-Member -Force @{ $_.Tag = [Int]$_.Text }
    }
    $Config | Add-Member -Force @{ $CheckedListBoxPools.Tag = $CheckedListBoxPools.CheckedItems }

    $MonitoringSettingsControls | Where-Object { (($_.GetType()).Name -eq "CheckBox") } | ForEach-Object { $Config | Add-Member -Force @{ $_.Tag = $_.Checked } }
    $MonitoringSettingsControls | Where-Object { (($_.GetType()).Name -eq "TextBox") } | ForEach-Object { $Config | Add-Member -Force @{ $_.Tag = $_.Text } }

    Write-Config -ConfigFile $ConfigFile
    Get-Config -ConfigFile $ConfigFile

    $MainForm.Refresh
    # [System.Windows.Forms.Messagebox]::show("Please restart NPlusMiner",'Config saved','ok','Information') | Out-Null
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$MainForm = New-Object System.Windows.Forms.Form
$NMIcon = New-Object system.drawing.icon ("$($PWD)\Includes\NM.ICO")
$MainForm.Icon = $NMIcon
$MainForm.ClientSize = [System.Drawing.Size]::new(740, 450) # best to keep under 800,600
$MainForm.text = "Form"
$MainForm.TopMost = $false
$MainForm.FormBorderStyle = 'Fixed3D'
$MainForm.MaximizeBox = $false

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
        # Detects GPU count If 0 or Null in config
        If ($Config.GPUCount -eq $null -or $Config.GPUCount -lt 1) { 
            If ($Config -eq $null) {
                $Config = [Hashtable]::Synchronized(@{ })
            }
            $Config | Add-Member -Force @{ GPUCount = Get-GPUCount }
            $TBGPUCount.Text = $Config.GPUCount
            PrepareWriteConfig
        }
        # Start on load if Autostart
        If ($Config.Autostart) { $ButtonStart.PerformClick() }
        If ($Config.StartGUIMinimized) { $MainForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized }
    }
)

$MainForm.Add_FormClosing(
    { 
        $TimerUI.Stop()
        Write-Message "Stopping jobs and miner"

        If ($Variables.EarningsTrackerJobs) { $Variables.EarningsTrackerJobs | ForEach-Object { $_ | Stop-Job | Remove-Job } }
        If ($Variables.BrainJobs) { $Variables.BrainJobs | ForEach-Object { $_ | Stop-Job | Remove-Job } }

        If ($Variables.ActiveMiners) { 
            $Variables.ActiveMiners | ForEach-Object { 
                [Array]$Filtered = ($BestMiners_Combo | Where-Object Path -EQ $_.Path | Where-Object Arguments -EQ $_.Arguments)
                If ($Filtered.Count -eq 0) { 
                    If ($_.Process -eq $null) { 
                        $_.Status = "Failed"
                    }
                    ElseIf ($_.Process.HasExited -eq $false) { 
                        $_.Active += (Get-Date) - $_.Process.StartTime
                        $_.Process.CloseMainWindow() | Out-Null
                        Start-Sleep 1
                        # simply "Kill with power"
                        Stop-Process $_.Process -Force | Out-Null
                        Write-Host -ForegroundColor Yellow "closing miner"
                        Start-Sleep 1
                        $_.Status = "Idle"
                    }
                }
            }
        }

        # $Result = $powershell.EndInvoke($Variables.CycleRunspaceHandle)
        If ($CycleRunspace) { $CycleRunspace.Close() }
        If ($powershell) { $powershell.Dispose() }

        If ($IdleRunspace) { $IdleRunspace.Close() }
        If ($IdlePowershell) { $IdlePowershell.Dispose() }
    }
)

$MainForm | Add-Member -Name "Config" -Value $Config -MemberType NoteProperty -Force

$SelGPUDSTM = $Config.SelGPUDSTM
$SelGPUCC = $Config.SelGPUCC
$MainForm | Add-Member -Name "Variables" -Value $Variables -MemberType NoteProperty -Force

$Variables | Add-Member -Force @{ CurrentProduct = (Get-Content .\Version.json | ConvertFrom-Json).Product }
$Variables | Add-Member -Force @{ CurrentVersion = [Version](Get-Content .\Version.json | ConvertFrom-Json).Version }
$Variables | Add-Member -Force @{ CurrentVersionAutoupdated = (Get-Content .\Version.json | ConvertFrom-Json).Autoupdated.Value }
$Variables.StatusText = "Idle"
$RunPage = New-Object System.Windows.Forms.TabPage
$RunPage.Text = "Run"
$SwitchingPage = New-Object System.Windows.Forms.TabPage
$SwitchingPage.Text = "Switching"
$ConfigPage = New-Object System.Windows.Forms.TabPage
$ConfigPage.Text = "Config"
$MonitoringPage = New-Object System.Windows.Forms.TabPage
$MonitoringPage.Text = "Monitoring"
$EstimationsPage = New-Object System.Windows.Forms.TabPage
$EstimationsPage.Text = "Benchmarks"

$TabControl = New-object System.Windows.Forms.TabControl
$TabControl.DataBindings.DefaultDataSourceUpdateMode = 0
$TabControl.Location = [System.Drawing.Point]::new(10, 91)
$TabControl.Name = "TabControl"
$TabControl.width = 720
$TabControl.height = 359
$TabControl.Controls.AddRange(@($RunPage, $SwitchingPage, $ConfigPage, $MonitoringPage, $EstimationsPage))

$TabControl_SelectedIndexChanged = {
    Switch ($TabControl.SelectedTab.Text) { 
        "Switching"  { CheckBoxSwitching_Click }
    }
}
$TabControl.Add_SelectedIndexChanged($TabControl_SelectedIndexChanged)

$MainForm.Controls.Add($TabControl)

# Form Controls
$MainFormControls = @()

# $Logo = [System.Drawing.Image]::Fromfile('.\config\logo.png')
$PictureBoxLogo = new-object Windows.Forms.PictureBox
$PictureBoxLogo.Width = 47 #$img.Size.Width
$PictureBoxLogo.Height = 47 #$img.Size.Height
# $PictureBoxLogo.Image = $Logo
$PictureBoxLogo.SizeMode = 1
$PictureBoxLogo.ImageLocation = $Branding.LogoPath
$MainFormControls += $PictureBoxLogo

$LabelEarningsDetails = New-Object System.Windows.Forms.TextBox
$LabelEarningsDetails.Tag = ""
$LabelEarningsDetails.MultiLine = $true
$LabelEarningsDetails.text = ""
$LabelEarningsDetails.AutoSize = $false
$LabelEarningsDetails.width = 200 #382
$LabelEarningsDetails.height = 47 #62
$LabelEarningsDetails.location = [System.Drawing.Point]::new(57, 2)
$LabelEarningsDetails.Font = [System.Drawing.Font]::new("Lucida Console", 10)
$LabelEarningsDetails.BorderStyle = 'None'
$LabelEarningsDetails.BackColor = [System.Drawing.SystemColors]::Control
$LabelEarningsDetails.ForeColor = [System.Drawing.Color]::Green
$LabelEarningsDetails.Visible = $true
# $TBNotifications.TextAlign                = "Right"
$MainFormControls += $LabelEarningsDetails

$LabelBTCD = New-Object System.Windows.Forms.Label
$LabelBTCD.text = "BTC/D"
$LabelBTCD.AutoSize = $false
$LabelBTCD.width = 473
$LabelBTCD.height = 35
$LabelBTCD.location = [System.Drawing.Point]::new(247, 2)
$LabelBTCD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 14)
$LabelBTCD.TextAlign = "MiddleRight"
$LabelBTCD.ForeColor = [System.Drawing.Color]::Green
$LabelBTCD.BackColor = [System.Drawing.Color]::Transparent
# $LabelBTCD.BorderStyle              = 'FixedSingle'
$MainFormControls += $LabelBTCD

$LabelBTCPrice = New-Object System.Windows.Forms.Label
$LabelBTCPrice.text = If ($Variables.Rates.$Currency -gt 0) { "BTC/$($Config.Currency | Select-Object -Index 0) $($Variables.Rates.$Currency)" }
$LabelBTCPrice.AutoSize = $false
$LabelBTCPrice.width = 400
$LabelBTCPrice.height = 20
$LabelBTCPrice.location = [System.Drawing.Point]::new(510, 39)
$LabelBTCPrice.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 8)
# $LabelBTCPrice.ForeColor              = "Gray"
$MainFormControls += $LabelBTCPrice

$ButtonPause = New-Object System.Windows.Forms.Button
$ButtonPause.text = "Pause"
$ButtonPause.width = 60
$ButtonPause.height = 30
$ButtonPause.location = [System.Drawing.Point]::new(610, 62)
$ButtonPause.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonPause.Visible = $false
$MainFormControls += $ButtonPause

$ButtonStart = New-Object System.Windows.Forms.Button
$ButtonStart.text = "Start"
$ButtonStart.width = 60
$ButtonStart.height = 30
$ButtonStart.location = [System.Drawing.Point]::new(670, 62)
$ButtonStart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MainFormControls += $ButtonStart

$LabelNotifications = New-Object System.Windows.Forms.TextBox
$LabelNotifications.Tag = ""
$LabelNotifications.MultiLine = $true
# $TBNotifications.Scrollbars             = "Vertical" 
$LabelNotifications.text = ""
$LabelNotifications.AutoSize = $false
$LabelNotifications.width = 280
$LabelNotifications.height = 18
$LabelNotifications.location = [System.Drawing.Point]::new(10, 49)
$LabelNotifications.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LabelNotifications.BorderStyle = 'None'
$LabelNotifications.BackColor = [System.Drawing.SystemColors]::Control
$LabelNotifications.Visible = $true
# $TBNotifications.TextAlign                = "Right"
$MainFormControls += $LabelNotifications

$LabelAddress = New-Object System.Windows.Forms.Label
$LabelAddress.text = "Wallet Address"
$LabelAddress.AutoSize = $false
$LabelAddress.width = 100
$LabelAddress.height = 20
$LabelAddress.location = [System.Drawing.Point]::new(10, 68)
$LabelAddress.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MainFormControls += $LabelAddress

$TBAddress = New-Object System.Windows.Forms.TextBox
$TBAddress.Tag = "Wallet"
$TBAddress.MultiLine = $false
# $TBAddress.Scrollbars             = "Vertical" 
$TBAddress.text = $Config.Wallet
$TBAddress.AutoSize = $false
$TBAddress.width = 280
$TBAddress.height = 20
$TBAddress.location = [System.Drawing.Point]::new(112, 68)
$TBAddress.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
# $TBAddress.TextAlign                = "Right"
$MainFormControls += $TBAddress

# Run Page Controls
$RunPageControls = @()

$Variables | Add-Member @{ LabelStatus = New-Object System.Windows.Forms.TextBox }
$Variables.LabelStatus.MultiLine = $true
$Variables.LabelStatus.Scrollbars = "Vertical" 
$Variables.LabelStatus.text = ""
$Variables.LabelStatus.AutoSize = $true
$Variables.LabelStatus.width = 712
$Variables.LabelStatus.height = 50
$Variables.LabelStatus.location = [System.Drawing.Point]::new(2, 2)
$Variables.LabelStatus.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)

$RunPageControls += $Variables.LabelStatus

If ((Test-Path ".\Logs\DailyEarnings.csv" -PathType Leaf) -and (Test-Path ".\Includes\Charting.ps1" -PathType Leaf)) { 

    $Chart1 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'Front7DaysEarnings' -Width 505 -Height 105"
    $Chart1.top = 54
    $Chart1.left = 2
    $RunPageControls += $Chart1

    $Chart2 = Invoke-Expression -Command ".\Includes\Charting.ps1 -Chart 'DayPoolSplit' -Width 200 -Height 105"
    $Chart2.top = 54
    $Chart2.left = 500
    $RunPageControls += $Chart2
}

$EarningsDGV = New-Object System.Windows.Forms.DataGridView
$EarningsDGV.width = 712
$EarningsDGV.height = 85
$EarningsDGV.location = [System.Drawing.Point]::new(2, 159)
$EarningsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EarningsDGV.AutoSizeColumnsMode = "Fill"
$EarningsDGV.RowHeadersVisible = $false
$RunPageControls += $EarningsDGV

$LabelGitHub = New-Object System.Windows.Forms.LinkLabel
# $LabelGitHub.Location           = New-Object System.Drawing.Size(415,39)
# $LabelGitHub.Size               = New-Object System.Drawing.Size(160,18)
$LabelGitHub.Location = New-Object System.Drawing.Size(600, 246)
$LabelGitHub.Size = New-Object System.Drawing.Size(160, 20)
$LabelGitHub.LinkColor = [System.Drawing.Color]::Blue
$LabelGitHub.ActiveLinkColor = [System.Drawing.Color]::Blue
$RunPageControls += $LabelGitHub

$LabelCopyright = New-Object System.Windows.Forms.LinkLabel
# $LabelCopyright.Location        = New-Object System.Drawing.Size(415,61)
# $LabelCopyright.Size            = New-Object System.Drawing.Size(200,20)
$LabelCopyright.Location = New-Object System.Drawing.Size(360, 246)
$LabelCopyright.Size = New-Object System.Drawing.Size(250, 14)
$LabelCopyright.LinkColor = [System.Drawing.Color]::Blue
$LabelCopyright.ActiveLinkColor = [System.Drawing.Color]::Blue
$LabelCopyright.Text = "Copyright (c) 2018-$((Get-Date).Year) Nemo and MrPlus"
$LabelCopyright.Add_Click( { [System.Diagnostics.Process]::start("https://github.com/Minerx117/NemosMiner/blob/master/LICENSE") })
$RunPageControls += $LabelCopyright

$LabelRunningMiners = New-Object System.Windows.Forms.Label
$LabelRunningMiners.text = "Running Miners"
$LabelRunningMiners.AutoSize = $false
$LabelRunningMiners.width = 200
$LabelRunningMiners.height = 20
$LabelRunningMiners.location = [System.Drawing.Point]::new(2, 246)
$LabelRunningMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RunPageControls += $LabelRunningMiners

$RunningMinersDGV = New-Object System.Windows.Forms.DataGridView
$RunningMinersDGV.width = 712
$RunningMinersDGV.height = 95
$RunningMinersDGV.location = [System.Drawing.Point]::new(2, 266)
$RunningMinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$RunningMinersDGV.AutoSizeColumnsMode = "Fill"
$RunningMinersDGV.RowHeadersVisible = $false
$RunPageControls += $RunningMinersDGV

# Switching Page Controls
$SwitchingPageControls = @()

$CheckShowSwitchingCPU = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingCPU.Tag = "CPU"
$CheckShowSwitchingCPU.text = "CPU"
$CheckShowSwitchingCPU.AutoSize = $false
$CheckShowSwitchingCPU.width = 60
$CheckShowSwitchingCPU.height = 20
$CheckShowSwitchingCPU.location = [System.Drawing.Point]::new(2, 2)
$CheckShowSwitchingCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingCPU.Checked = ("CPU" -in $Config.Type)
$SwitchingPageControls += $CheckShowSwitchingCPU
$CheckShowSwitchingCPU | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($This) }) }

$CheckShowSwitchingNVIDIA = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingNVIDIA.Tag = "NVIDIA"
$CheckShowSwitchingNVIDIA.text = "NVIDIA"
$CheckShowSwitchingNVIDIA.AutoSize = $false
$CheckShowSwitchingNVIDIA.width = 70
$CheckShowSwitchingNVIDIA.height = 20
$CheckShowSwitchingNVIDIA.location = [System.Drawing.Point]::new(62, 2)
$CheckShowSwitchingNVIDIA.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingNVIDIA.Checked = ("NVIDIA" -in $Config.Type)
$SwitchingPageControls += $CheckShowSwitchingNVIDIA
$CheckShowSwitchingNVIDIA | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($This) }) }

$CheckShowSwitchingAMD = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingAMD.Tag = "AMD"
$CheckShowSwitchingAMD.text = "AMD"
$CheckShowSwitchingAMD.AutoSize = $false
$CheckShowSwitchingAMD.width = 100
$CheckShowSwitchingAMD.height = 20
$CheckShowSwitchingAMD.location = [System.Drawing.Point]::new(137, 2)
$CheckShowSwitchingAMD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingAMD.Checked = ("AMD" -in $Config.Type)
$SwitchingPageControls += $CheckShowSwitchingAMD
$CheckShowSwitchingAMD | ForEach-Object { $_.Add_Click( { CheckBoxSwitching_Click($This) }) }

Function CheckBoxSwitching_Click { 
    $SwitchingDisplayTypes = @()
    $SwitchingPageControls | ForEach-Object { If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } }
    If (Test-Path ".\Logs\switching.log" -PathType Leaf) { $SwitchingArray = [System.Collections.ArrayList]@(Get-Content ".\Logs\switching.log" | ConvertFrom-Csv | Where-Object { $_.Date -gt (Get-Date).AddDays(-1).ToString() }) }
    $SwitchingDGV.DataSource = [System.Collections.ArrayList]($SwitchingArray | Where-Object { $_.Type -in $SwitchingDisplayTypes } | Sort-Object Date -Descending)
}

$SwitchingDGV = New-Object System.Windows.Forms.DataGridView
$SwitchingDGV.width = 712
$SwitchingDGV.height = 333
$SwitchingDGV.location = [System.Drawing.Point]::new(2, 22)
$SwitchingDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$SwitchingDGV.AutoSizeColumnsMode = "Fill"
$SwitchingDGV.RowHeadersVisible = $false
$SwitchingDGV.DataSource = $SwitchingArray
$SwitchingPageControls += $SwitchingDGV

# Estimations Page Controls
$EstimationsDGV = New-Object System.Windows.Forms.DataGridView
$EstimationsDGV.width = 712
$EstimationsDGV.height = 350
$EstimationsDGV.location = [System.Drawing.Point]::new(2, 2)
$EstimationsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EstimationsDGV.AutoSizeColumnsMode = "Fill"
$EstimationsDGV.RowHeadersVisible = $false
$EstimationsDGV.ColumnHeadersVisible = $true
#$EstimationsDGV.DataGridViewColumnHeaderCell()

# Config Page Controls
$ConfigPageControls = @()

$LabelWorkerName = New-Object System.Windows.Forms.Label
$LabelWorkerName.text = "Worker Name"
$LabelWorkerName.AutoSize = $false
$LabelWorkerName.width = 120
$LabelWorkerName.height = 20
$LabelWorkerName.location = [System.Drawing.Point]::new(2, 2)
$LabelWorkerName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelWorkerName

$TBWorkerName = New-Object System.Windows.Forms.TextBox
$TBWorkerName.Tag = "WorkerName"
$TBWorkerName.MultiLine = $false
# $TBWorkerName.Scrollbars              = "Vertical" 
$TBWorkerName.text = $Config.WorkerName
$TBWorkerName.AutoSize = $false
$TBWorkerName.width = 300
$TBWorkerName.height = 20
$TBWorkerName.location = [System.Drawing.Point]::new(122, 2)
$TBWorkerName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBWorkerName

$LabelUserName = New-Object System.Windows.Forms.Label
$LabelUserName.text = "MPH UserName"
$LabelUserName.AutoSize = $false
$LabelUserName.width = 120
$LabelUserName.height = 20
$LabelUserName.location = [System.Drawing.Point]::new(2, 24)
$LabelUserName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelUserName

$TBUserName = New-Object System.Windows.Forms.TextBox
$TBUserName.Tag = "UserName"
$TBUserName.MultiLine = $false
# $TBUserName.Scrollbars                = "Vertical" 
$TBUserName.text = $Config.UserName
$TBUserName.AutoSize = $false
$TBUserName.width = 300
$TBUserName.height = 20
$TBUserName.location = [System.Drawing.Point]::new(122, 24)
$TBUserName.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBUserName

$LabelInterval = New-Object System.Windows.Forms.Label
$LabelInterval.text = "Interval"
$LabelInterval.AutoSize = $false
$LabelInterval.width = 120
$LabelInterval.height = 20
$LabelInterval.location = [System.Drawing.Point]::new(2, 46)
$LabelInterval.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelInterval

$TBInterval = New-Object System.Windows.Forms.TextBox
$TBInterval.Tag = "Interval"
$TBInterval.MultiLine = $false
# $TBWorkerName.Scrollbars              = "Vertical" 
$TBInterval.text = $Config.Interval
$TBInterval.AutoSize = $false
$TBInterval.width = 300
$TBInterval.height = 20
$TBInterval.location = [System.Drawing.Point]::new(122, 46)
$TBInterval.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBInterval

$LabelLocation = New-Object System.Windows.Forms.Label
$LabelLocation.text = "Location"
$LabelLocation.AutoSize = $false
$LabelLocation.width = 120
$LabelLocation.height = 20
$LabelLocation.location = [System.Drawing.Point]::new(2, 68)
$LabelLocation.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelLocation

$TBLocation = New-Object System.Windows.Forms.TextBox
$TBLocation.Tag = "Location"
$TBLocation.MultiLine = $false
# $TBLocation.Scrollbars                = "Vertical" 
$TBLocation.text = $Config.Location
$TBLocation.AutoSize = $false
$TBLocation.width = 300
$TBLocation.height = 20
$TBLocation.location = [System.Drawing.Point]::new(122, 68)
$TBLocation.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBLocation

$LabelGPUCount = New-Object System.Windows.Forms.Label
$LabelGPUCount.text = "GPU Count"
$LabelGPUCount.AutoSize = $false
$LabelGPUCount.width = 120
$LabelGPUCount.height = 20
$LabelGPUCount.location = [System.Drawing.Point]::new(2, 90)
$LabelGPUCount.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelGPUCount

$TBGPUCount = New-Object System.Windows.Forms.TextBox
$TBGPUCount.Tag = "GPUCount"
$TBGPUCount.MultiLine = $false
# $TBGPUCount.Scrollbars                = "Vertical" 
$TBGPUCount.text = $Config.GPUCount
$TBGPUCount.AutoSize = $false
$TBGPUCount.width = 50
$TBGPUCount.height = 20
$TBGPUCount.location = [System.Drawing.Point]::new(122, 90)
$TBGPUCount.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBGPUCount

$CheckBoxDisableGPU0 = New-Object System.Windows.Forms.CheckBox
$CheckBoxDisableGPU0.Tag = "DisableGPU0"
$CheckBoxDisableGPU0.text = "Disable GPU0"
$CheckBoxDisableGPU0.AutoSize = $false
$CheckBoxDisableGPU0.width = 140
$CheckBoxDisableGPU0.height = 20
$CheckBoxDisableGPU0.location = [System.Drawing.Point]::new(177, 90)
$CheckBoxDisableGPU0.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxDisableGPU0.Checked = $Config.DisableGPU0
$ConfigPageControls += $CheckBoxDisableGPU0
    
$ButtonDetectGPU = New-Object System.Windows.Forms.Button
$ButtonDetectGPU.text = "Detect GPU"
$ButtonDetectGPU.width = 100
$ButtonDetectGPU.height = 20
$ButtonDetectGPU.location = [System.Drawing.Point]::new(320, 90)
$ButtonDetectGPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $ButtonDetectGPU

$ButtonDetectGPU.Add_Click( { $TBGPUCount.text = Get-GPUCount })

$LabelAlgos = New-Object System.Windows.Forms.Label
$LabelAlgos.text = "Algorithm"
$LabelAlgos.AutoSize = $false
$LabelAlgos.width = 120
$LabelAlgos.height = 20
$LabelAlgos.location = [System.Drawing.Point]::new(2, 112)
$LabelAlgos.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelAlgos

$TBAlgos = New-Object System.Windows.Forms.TextBox
$TBAlgos.Tag = "Algorithm"
$TBAlgos.MultiLine = $false
# $TBAlgos.Scrollbars               = "Vertical" 
$TBAlgos.text = $Config.Algorithm -Join ","
$TBAlgos.AutoSize = $false
$TBAlgos.width = 300
$TBAlgos.height = 20
$TBAlgos.location = [System.Drawing.Point]::new(122, 112)
$TBAlgos.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBAlgos

$LabelCurrency = New-Object System.Windows.Forms.Label
$LabelCurrency.text = "Currency"
$LabelCurrency.AutoSize = $false
$LabelCurrency.width = 120
$LabelCurrency.height = 20
$LabelCurrency.location = [System.Drawing.Point]::new(2, 134)
$LabelCurrency.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelCurrency

$TBCurrency = New-Object System.Windows.Forms.TextBox
$TBCurrency.Tag = "Currency"
$TBCurrency.MultiLine = $false
# $TBCurrency.Scrollbars                = "Vertical" 
$TBCurrency.text = $Config.Currency
$TBCurrency.AutoSize = $false
$TBCurrency.width = 300
$TBCurrency.height = 20
$TBCurrency.location = [System.Drawing.Point]::new(122, 134)
$TBCurrency.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBCurrency

$LabelPwdCurrency = New-Object System.Windows.Forms.Label
$LabelPwdCurrency.text = "Pwd Currency"
$LabelPwdCurrency.AutoSize = $false
$LabelPwdCurrency.width = 120
$LabelPwdCurrency.height = 20
$LabelPwdCurrency.location = [System.Drawing.Point]::new(2, 156)
$LabelPwdCurrency.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelPwdCurrency

$TBPwdCurrency = New-Object System.Windows.Forms.TextBox
$TBPwdCurrency.Tag = "Passwordcurrency"
$TBPwdCurrency.MultiLine = $false
# $TBPwdCurrency.Scrollbars             = "Vertical" 
$TBPwdCurrency.text = $Config.Passwordcurrency
$TBPwdCurrency.AutoSize = $false
$TBPwdCurrency.width = 300
$TBPwdCurrency.height = 20
$TBPwdCurrency.location = [System.Drawing.Point]::new(122, 156)
$TBPwdCurrency.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBPwdCurrency

$LabelDonate = New-Object System.Windows.Forms.Label
$LabelDonate.text = "Donate"
$LabelDonate.AutoSize = $false
$LabelDonate.width = 120
$LabelDonate.height = 20
$LabelDonate.location = [System.Drawing.Point]::new(2, 178)
$LabelDonate.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelDonate

$TBDonate = New-Object System.Windows.Forms.TextBox
$TBDonate.Tag = "Donate"
$TBDonate.MultiLine = $false
# $TBDonate.Scrollbars              = "Vertical" 
$TBDonate.text = $Config.Donate
$TBDonate.AutoSize = $false
$TBDonate.width = 300
$TBDonate.height = 20
$TBDonate.location = [System.Drawing.Point]::new(122, 178)
$TBDonate.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBDonate

$LabelProxy = New-Object System.Windows.Forms.Label
$LabelProxy.text = "Proxy"
$LabelProxy.AutoSize = $false
$LabelProxy.width = 120
$LabelProxy.height = 20
$LabelProxy.location = [System.Drawing.Point]::new(2, 178)
$LabelProxy.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelProxy

$TBProxy = New-Object System.Windows.Forms.TextBox
$TBProxy.Tag = "Proxy"
$TBProxy.MultiLine = $false
# $TBProxy.Scrollbars               = "Vertical" 
$TBProxy.text = $Config.Proxy
$TBProxy.AutoSize = $false
$TBProxy.width = 300
$TBProxy.height = 20
$TBProxy.location = [System.Drawing.Point]::new(122, 178)    
$TBProxy.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBProxy

$LabelActiveMinerGainPct = New-Object System.Windows.Forms.Label
$LabelActiveMinerGainPct.text = "ActiveMinerGain%"
$LabelActiveMinerGainPct.AutoSize = $false
$LabelActiveMinerGainPct.width = 120
$LabelActiveMinerGainPct.height = 20
$LabelActiveMinerGainPct.location = [System.Drawing.Point]::new(2, 202)
$LabelActiveMinerGainPct.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelActiveMinerGainPct

$TBActiveMinerGainPct = New-Object System.Windows.Forms.TextBox
$TBActiveMinerGainPct.Tag = "ActiveMinerGainPct"
$TBActiveMinerGainPct.MultiLine = $false
# $TBActiveMinerGainPct.Scrollbars              = "Vertical" 
$TBActiveMinerGainPct.text = $Config.ActiveMinerGainPct
$TBActiveMinerGainPct.AutoSize = $false
$TBActiveMinerGainPct.width = 300
$TBActiveMinerGainPct.height = 20
$TBActiveMinerGainPct.location = [System.Drawing.Point]::new(122, 202)
$TBActiveMinerGainPct.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBActiveMinerGainPct

$LabelMPHAPIKey = New-Object System.Windows.Forms.Label
$LabelMPHAPIKey.text = "MPH API Key"
$LabelMPHAPIKey.AutoSize = $false
$LabelMPHAPIKey.width = 120
$LabelMPHAPIKey.height = 20
$LabelMPHAPIKey.location = [System.Drawing.Point]::new(2, 224)
$LabelMPHAPIKey.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelMPHAPIKey

$TBMPHAPIKey = New-Object System.Windows.Forms.TextBox
$TBMPHAPIKey.Tag = "APIKEY"
$TBMPHAPIKey.MultiLine = $false
$TBMPHAPIKey.text = $Config.APIKEY
$TBMPHAPIKey.AutoSize = $false
$TBMPHAPIKey.width = 300
$TBMPHAPIKey.height = 20
$TBMPHAPIKey.location = [System.Drawing.Point]::new(122, 224)
$TBMPHAPIKey.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $TBMPHAPIKey

$LabelMinersTypes = New-Object System.Windows.Forms.Label
$LabelMinersTypes.text = "Miners Types"
$LabelMinersTypes.AutoSize = $false
$LabelMinersTypes.width = 120
$LabelMinersTypes.height = 20
$LabelMinersTypes.location = [System.Drawing.Point]::new(2, 246)
$LabelMinersTypes.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelMinersTypes

$CheckBoxMinerTypeCPU = New-Object System.Windows.Forms.CheckBox
$CheckBoxMinerTypeCPU.Tag = "TypeCPU"
$CheckBoxMinerTypeCPU.text = "CPU"
$CheckBoxMinerTypeCPU.AutoSize = $false
$CheckBoxMinerTypeCPU.width = 60
$CheckBoxMinerTypeCPU.height = 20
$CheckBoxMinerTypeCPU.location = [System.Drawing.Point]::new(124, 246)
$CheckBoxMinerTypeCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxMinerTypeCPU.Checked = ($CheckBoxMinerTypeCPU.text -in $Config.Type)
$ConfigPageControls += $CheckBoxMinerTypeCPU

$CheckBoxMinerTypeCPU.Add_Click(
    { 
        If ($This.checked -and $This.Text -notin $Config.Type) { 
            [Array]$Config.Type += $This.Text
            # If ($Variables."$($This.Text)MinerAPITCPPort" -eq $null){ 
            If ($Variables."$($This.Text)MinerAPITCPPort" -eq $null -or ($Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" -and $_.Type -eq $This.Text }) -eq $null) { 
                # Find available TCP Ports
                $StartPort = 4068
                Write-Message "Finding available TCP Port for $($This.Text)"
                $Port = Get-FreeTcpPort($StartPort)
                $Variables | Add-Member -Force @{ "$($This.Text)MinerAPITCPPort" = $Port }
                Write-Message "Miners API Port: $($Port)"
                $StartPort = $Port + 1
            }
        }
        Else { $Config.Type = @($Config.Type | Where-Object { $_ -ne $This.Text }) }
    }
)

$CheckBoxMinerTypeNVIDIA = New-Object System.Windows.Forms.CheckBox
$CheckBoxMinerTypeNVIDIA.Tag = "TypeNVIDIA"
$CheckBoxMinerTypeNVIDIA.text = "NVIDIA"
$CheckBoxMinerTypeNVIDIA.AutoSize = $false
$CheckBoxMinerTypeNVIDIA.width = 70
$CheckBoxMinerTypeNVIDIA.height = 20
$CheckBoxMinerTypeNVIDIA.location = [System.Drawing.Point]::new(186, 246)
$CheckBoxMinerTypeNVIDIA.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxMinerTypeNVIDIA.Checked = ($CheckBoxMinerTypeNVIDIA.text -in $Config.Type)
$ConfigPageControls += $CheckBoxMinerTypeNVIDIA

$CheckBoxMinerTypeNVIDIA.Add_Click(
    { 
        If ($This.checked -and $This.Text -notin $Config.Type) { 
            [Array]$Config.Type += $This.Text
            If ($Variables."$($This.Text)MinerAPITCPPort" -eq $null -or ($Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" -and $_.Type -eq $This.Text }) -eq $null) { 
                # Find available TCP Ports
                $StartPort = 4068
                Write-Message "Finding available TCP Port for $($This.Text)"
                $Port = Get-FreeTcpPort($StartPort)
                $Variables | Add-Member -Force @{ "$($This.Text)MinerAPITCPPort" = $Port }
                Write-Message "Miners API Port: $($Port)"
                $StartPort = $Port + 1
            }
        }
        Else { $Config.Type = @($Config.Type | Where-Object { $_ -ne $This.Text }) }
    }
)

$CheckBoxMinerTypeAMD = New-Object System.Windows.Forms.CheckBox
$CheckBoxMinerTypeAMD.Tag = "TypeAMD"
$CheckBoxMinerTypeAMD.text = "AMD"
$CheckBoxMinerTypeAMD.AutoSize = $false
$CheckBoxMinerTypeAMD.width = 60
$CheckBoxMinerTypeAMD.height = 20
$CheckBoxMinerTypeAMD.location = [System.Drawing.Point]::new(261, 246)
$CheckBoxMinerTypeAMD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxMinerTypeAMD.Checked = ($CheckBoxMinerTypeAMD.text -in $Config.Type)
$ConfigPageControls += $CheckBoxMinerTypeAMD

$CheckBoxMinerTypeAMD.Add_Click( 
    { 
        If ($This.checked -and $This.Text -notin $Config.Type) { 
            [Array]$Config.Type += $This.Text
            If ($Variables."$($This.Text)MinerAPITCPPort" -eq $null -or ($Variables.ActiveMiners | Where-Object { $_.Status -eq "Running" -and $_.Type -eq $This.Text }) -eq $null) { 
                # Find available TCP Ports
                $StartPort = 4068
                Write-Message "Finding available TCP Port for $($This.Text)"
                $Port = Get-FreeTcpPort($StartPort)
                $Variables | Add-Member -Force @{ "$($This.Text)MinerAPITCPPort" = $Port }
                Write-Message "Miners API Port: $($Port)"
                $StartPort = $Port + 1
            }
        }
        Else { $Config.Type = @($Config.Type | Where-Object { $_ -ne $This.Text }) }
    }
)

$CheckBoxAutostart = New-Object System.Windows.Forms.CheckBox
$CheckBoxAutostart.Tag = "Autostart"
$CheckBoxAutostart.text = "Auto Start"
$CheckBoxAutostart.AutoSize = $false
$CheckBoxAutostart.width = 100
$CheckBoxAutostart.height = 20
$CheckBoxAutostart.location = [System.Drawing.Point]::new(560, 2)
$CheckBoxAutostart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxAutostart.Checked = $Config.Autostart
$ConfigPageControls += $CheckBoxAutostart

$CheckBoxAutoStart.Add_Click(
    { 
        # Disable CheckBoxStartPaused and mine when idle when Auto Start is unchecked
        If ($CheckBoxAutoStart.Checked) { 
            $CheckBoxStartPaused.Enabled = $true
            $CheckBoxMineWhenIdle.Enabled = $true
            $TBIdleSec.Enabled = $true
        }
        Else { 
            $CheckBoxStartPaused.Checked = $false
            $CheckBoxStartPaused.Enabled = $false
            $CheckBoxMineWhenIdle.Checked = $false
            $CheckBoxMineWhenIdle.Enabled = $false
            $TBIdleSec.Enabled = $false
        }
    }
)

$CheckBoxStartPaused = New-Object System.Windows.Forms.CheckBox
$CheckBoxStartPaused.Tag = "StartPaused"
$CheckBoxStartPaused.text = "Pause on Auto Start"
$CheckBoxStartPaused.AutoSize = $false
$CheckBoxStartPaused.width = 160
$CheckBoxStartPaused.height = 20
$CheckBoxStartPaused.location = [System.Drawing.Point]::new(560, 24)
$CheckBoxStartPaused.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxStartPaused.Checked = $Config.StartPaused
$CheckBoxStartPaused.Enabled = $CheckBoxAutoStart.Checked
$ConfigPageControls += $CheckBoxStartPaused

$CheckBoxMineWhenIdle = New-Object System.Windows.Forms.CheckBox
$CheckBoxMineWhenIdle.Tag = "MineWhenIdle"
$CheckBoxMineWhenIdle.text = "Mine only when idle"
$CheckBoxMineWhenIdle.AutoSize = $false
$CheckBoxMineWhenIdle.width = 160
$CheckBoxMineWhenIdle.height = 20
$CheckBoxMineWhenIdle.location = [System.Drawing.Point]::new(560, 46)
$CheckBoxMineWhenIdle.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxMineWhenIdle.Checked = $Config.MineWhenIdle
$CheckBoxMineWhenIdle.Enabled = $CheckBoxAutoStart.Checked
$ConfigPageControls += $CheckBoxMineWhenIdle

$TBIdleSec = New-Object System.Windows.Forms.TextBox
$TBIdleSec.Tag = "IdleSec"
$TBIdleSec.MultiLine = $false
$TBIdleSec.text = If ($Config.IdleSec -gt 1) { $Config.IdleSec } Else { 120 }
$TBIdleSec.AutoSize = $false
$TBIdleSec.width = 50
$TBIdleSec.height = 20
$TBIdleSec.location = [System.Drawing.Point]::new(580, 68)
$TBIdleSec.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$TBIdleSec.Enabled = $CheckBoxAutoStart.Checked
$ConfigPageControls += $TBIdleSec

$LabelIdleSec = New-Object System.Windows.Forms.Label
$LabelIdleSec.text = "seconds"
$LabelIdleSec.AutoSize = $false
$LabelIdleSec.width = 60
$LabelIdleSec.height = 20
$LabelIdleSec.location = [System.Drawing.Point]::new(630, 68)
$LabelIdleSec.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $LabelIdleSec

$CheckBoxEarningTrackerLogs = New-Object System.Windows.Forms.CheckBox
$CheckBoxEarningTrackerLogs.Tag = "EnableEarningsTrackerLogs"
$CheckBoxEarningTrackerLogs.text = "Earnings Tracker Logs"
$CheckBoxEarningTrackerLogs.AutoSize = $false
$CheckBoxEarningTrackerLogs.width = 160
$CheckBoxEarningTrackerLogs.height = 20
$CheckBoxEarningTrackerLogs.location = [System.Drawing.Point]::new(560, 90)
$CheckBoxEarningTrackerLogs.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxEarningTrackerLogs.Checked = $Config.EnableEarningsTrackerLogs
$ConfigPageControls += $CheckBoxEarningTrackerLogs

$CheckBoxGUIMinimized = New-Object System.Windows.Forms.CheckBox
$CheckBoxGUIMinimized.Tag = "StartGUIMinimized"
$CheckBoxGUIMinimized.text = "Start UI minimized"
$CheckBoxGUIMinimized.AutoSize = $false
$CheckBoxGUIMinimized.width = 160
$CheckBoxGUIMinimized.height = 20
$CheckBoxGUIMinimized.location = [System.Drawing.Point]::new(560, 112)
$CheckBoxGUIMinimized.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxGUIMinimized.Checked = $Config.StartGUIMinimized
$ConfigPageControls += $CheckBoxGUIMinimized

$CheckBoxAutoupdate = New-Object System.Windows.Forms.CheckBox
$CheckBoxAutoupdate.Tag = "Autoupdate"
$CheckBoxAutoupdate.text = "Auto Update"
$CheckBoxAutoupdate.AutoSize = $true
$CheckBoxAutoupdate.width = 100
$CheckBoxAutoupdate.height = 20
$CheckBoxAutoupdate.location = [System.Drawing.Point]::new(560, 134)
$CheckBoxAutoupdate.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxAutoupdate.Checked = $Config.Autoupdate
# $CheckBoxAutoupdate.Enabled               =   $false
$ConfigPageControls += $CheckBoxAutoupdate

$CheckBoxIncludeRegularMiners = New-Object System.Windows.Forms.CheckBox
$CheckBoxIncludeRegularMiners.Tag = "IncludeRegularMiners"
$CheckBoxIncludeRegularMiners.text = "Regular Miners"
$CheckBoxIncludeRegularMiners.AutoSize = $false
$CheckBoxIncludeRegularMiners.width = 160
$CheckBoxIncludeRegularMiners.height = 20
$CheckBoxIncludeRegularMiners.location = [System.Drawing.Point]::new(560, 156)
$CheckBoxIncludeRegularMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxIncludeRegularMiners.Checked = $Config.IncludeRegularMiners
$ConfigPageControls += $CheckBoxIncludeRegularMiners

$CheckBoxIncludeOptionalMiners = New-Object System.Windows.Forms.CheckBox
$CheckBoxIncludeOptionalMiners.Tag = "IncludeOptionalMiners"
$CheckBoxIncludeOptionalMiners.text = "Optional Miners"
$CheckBoxIncludeOptionalMiners.AutoSize = $false
$CheckBoxIncludeOptionalMiners.width = 160
$CheckBoxIncludeOptionalMiners.height = 20
$CheckBoxIncludeOptionalMiners.location = [System.Drawing.Point]::new(560, 178)
$CheckBoxIncludeOptionalMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxIncludeOptionalMiners.Checked = $Config.IncludeOptionalMiners
$ConfigPageControls += $CheckBoxIncludeOptionalMiners

$CheckBoxConsole = New-Object System.Windows.Forms.CheckBox
$CheckBoxConsole.Tag = "HideConsole"
$CheckBoxConsole.text = "Hide Console"
$CheckBoxConsole.AutoSize = $false
$CheckBoxConsole.width = 160
$CheckBoxConsole.height = 20
$CheckBoxConsole.location = [System.Drawing.Point]::new(560, 200)
$CheckBoxConsole.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxConsole.Checked = $Config.HideConsole
$ConfigPageControls += $CheckBoxConsole

$ButtonLoadDefaultPoolsAlgos = New-Object System.Windows.Forms.Button
$ButtonLoadDefaultPoolsAlgos.text = "Load default algos for selected pools"
$ButtonLoadDefaultPoolsAlgos.width = 250
$ButtonLoadDefaultPoolsAlgos.height = 30
$ButtonLoadDefaultPoolsAlgos.location = [System.Drawing.Point]::new(358, 300)
$ButtonLoadDefaultPoolsAlgos.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $ButtonLoadDefaultPoolsAlgos

$ButtonLoadDefaultPoolsAlgos.Add_Click(
    { 
        Try { 
            $PoolsAlgos = Invoke-WebRequest "https://nemosminer.com/data/PoolsAlgos.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json; $PoolsAlgos | ConvertTo-Json | Out-File ".\Config\PoolsAlgos.json" 
        }
        Catch { $PoolsAlgos = Get-Content ".\Config\PoolsAlgos.json" | ConvertFrom-Json }
        If ($PoolsAlgos) { 
            $PoolsAlgos = $PoolsAlgos.PSObject.Properties | Where-Object { $_.Name -in $Config.PoolName }
            $PoolsAlgos = $PoolsAlgos.Value | Sort-Object -Unique
            $TBAlgos.text = $PoolsAlgos -Join ","
        }
    }
)

$ButtonWriteConfig = New-Object System.Windows.Forms.Button
$ButtonWriteConfig.text = "Save Config"
$ButtonWriteConfig.width = 100
$ButtonWriteConfig.height = 30
$ButtonWriteConfig.location = [System.Drawing.Point]::new(610, 300)
$ButtonWriteConfig.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ConfigPageControls += $ButtonWriteConfig

$ButtonWriteConfig.Add_Click( { PrepareWriteConfig })

$LabelPoolsSelect = New-Object System.Windows.Forms.Label
$LabelPoolsSelect.text = "Do not select multiple variants of the same pool"
$LabelPoolsSelect.AutoSize = $false
$LabelPoolsSelect.width = 130
$LabelPoolsSelect.height = 50
$LabelPoolsSelect.location = [System.Drawing.Point]::new(427, 2)
$LabelPoolsSelect.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LabelPoolsSelect.TextAlign = 'MiddleCenter'
$LabelPoolsSelect.BorderStyle = 'FixedSingle'
$ConfigPageControls += $LabelPoolsSelect

$CheckedListBoxPools = New-Object System.Windows.Forms.CheckedListBox
$CheckedListBoxPools.Tag = "PoolName"
$CheckedListBoxPools.height = 240
$CheckedListBoxPools.width = 130
$CheckedListBoxPools.text = "Pools"
$CheckedListBoxPools.location = [System.Drawing.Point]::new(427, 54)
$CheckedListBoxPools.CheckOnClick = $true
$CheckedListBoxPools.BackColor = [System.Drawing.SystemColors]::Control
$CheckedListBoxPools.Items.Clear()
$CheckedListBoxPools.Items.AddRange(((Get-ChildItem ".\Pools").BaseName | Sort-Object -Unique))
$CheckedListBoxPools.Add_SelectedIndexChanged( { CheckedListBoxPools_Click($This) })
$Config.PoolName | Where-Object { $_ -in $CheckedListBoxPools.Items } | ForEach-Object { $CheckedListBoxPools.SetItemChecked($CheckedListBoxPools.Items.IndexOf($_), $true) }

$ConfigPageControls += $CheckedListBoxPools

# Monitoring Page Controls
$MonitoringPageControls = @()
$MonitoringSettingsControls = @()

$LabelMonitoringWorkers = New-Object System.Windows.Forms.Label
$LabelMonitoringWorkers.text = "Worker Status"
$LabelMonitoringWorkers.AutoSize = $false
$LabelMonitoringWorkers.width = 710
$LabelMonitoringWorkers.height = 20
$LabelMonitoringWorkers.location = [System.Drawing.Point]::new(2, 4)
$LabelMonitoringWorkers.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringPageControls += $LabelMonitoringWorkers

$WorkersDGV = New-Object System.Windows.Forms.DataGridView
$WorkersDGV.width = 710
$WorkersDGV.height = 244
$WorkersDGV.location = [System.Drawing.Point]::new(2, 24)
$WorkersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$WorkersDGV.AutoSizeColumnsMode = "AllCells"
$WorkersDGV.RowHeadersVisible = $false
$MonitoringPageControls += $WorkersDGV

$GroupMonitoringSettings = New-Object System.Windows.Forms.GroupBox
$GroupMonitoringSettings.Height = 60
$GroupMonitoringSettings.Width = 710
$GroupMonitoringSettings.Text = "Monitoring Settings"
$GroupMonitoringSettings.Location = [System.Drawing.Point]::new(1, 272)
$MonitoringPageControls += $GroupMonitoringSettings

$LabelMonitoringServer = New-Object System.Windows.Forms.Label
$LabelMonitoringServer.text = "Server"
$LabelMonitoringServer.AutoSize = $false
$LabelMonitoringServer.width = 60
$LabelMonitoringServer.height = 20
$LabelMonitoringServer.location = [System.Drawing.Point]::new(2, 15)
$LabelMonitoringServer.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $LabelMonitoringServer

$TBMonitoringServer = New-Object System.Windows.Forms.TextBox
$TBMonitoringServer.Tag = "MonitoringServer"
$TBMonitoringServer.MultiLine = $false
$TBMonitoringServer.text = $Config.MonitoringServer
$TBMonitoringServer.AutoSize = $false
$TBMonitoringServer.width = 260
$TBMonitoringServer.height = 20
$TBMonitoringServer.location = [System.Drawing.Point]::new(62, 15)
$TBMonitoringServer.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $TBMonitoringServer

$CheckBoxReportToServer = New-Object System.Windows.Forms.CheckBox
$CheckBoxReportToServer.Tag = "ReportToServer"
$CheckBoxReportToServer.text = "Report to server"
$CheckBoxReportToServer.AutoSize = $false
$CheckBoxReportToServer.width = 130
$CheckBoxReportToServer.height = 20
$CheckBoxReportToServer.location = [System.Drawing.Point]::new(324, 15)
$CheckBoxReportToServer.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxReportToServer.Checked = $Config.ReportToServer
$MonitoringSettingsControls += $CheckBoxReportToServer

$CheckBoxShowWorkerStatus = New-Object System.Windows.Forms.CheckBox
$CheckBoxShowWorkerStatus.Tag = "ShowWorkerStatus"
$CheckBoxShowWorkerStatus.text = "Show other workers"
$CheckBoxShowWorkerStatus.AutoSize = $false
$CheckBoxShowWorkerStatus.width = 145
$CheckBoxShowWorkerStatus.height = 20
$CheckBoxShowWorkerStatus.location = [System.Drawing.Point]::new(456, 15)
$CheckBoxShowWorkerStatus.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckBoxShowWorkerStatus.Checked = $Config.ShowWorkerStatus
$MonitoringSettingsControls += $CheckBoxShowWorkerStatus

$LabelMonitoringUser = New-Object System.Windows.Forms.Label
$LabelMonitoringUser.text = "User ID"
$LabelMonitoringUser.AutoSize = $false
$LabelMonitoringUser.width = 60
$LabelMonitoringUser.height = 20
$LabelMonitoringUser.location = [System.Drawing.Point]::new(2, 37)
$LabelMonitoringUser.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $LabelMonitoringUser

$TBMonitoringUser = New-Object System.Windows.Forms.TextBox
$TBMonitoringUser.Tag = "MonitoringUser"
$TBMonitoringUser.MultiLine = $false
$TBMonitoringUser.text = $Config.MonitoringUser
$TBMonitoringUser.AutoSize = $false
$TBMonitoringUser.width = 260
$TBMonitoringUser.height = 20
$TBMonitoringUser.location = [System.Drawing.Point]::new(62, 37)
$TBMonitoringUser.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $TBMonitoringUser

$ButtonGenerateMonitoringUser = New-Object System.Windows.Forms.Button
$ButtonGenerateMonitoringUser.text = "Generate New User ID"
$ButtonGenerateMonitoringUser.width = 160
$ButtonGenerateMonitoringUser.height = 20
$ButtonGenerateMonitoringUser.location = [System.Drawing.Point]::new(324, 37)
$ButtonGenerateMonitoringUser.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonGenerateMonitoringUser.Enabled = ($TBMonitoringUser.text -eq "")
$MonitoringSettingsControls += $ButtonGenerateMonitoringUser

$ButtonGenerateMonitoringUser.Add_Click( { $TBMonitoringUser.text = [GUID]::NewGuid() })
# Only enable the generate button when user is blank.
$TBMonitoringUser.Add_TextChanged( { $ButtonGenerateMonitoringUser.Enabled = ($TBMonitoringUser.text -eq "") })

$ButtonMonitoringWriteConfig = New-Object System.Windows.Forms.Button
$ButtonMonitoringWriteConfig.text = "Save Config"
$ButtonMonitoringWriteConfig.width = 100
$ButtonMonitoringWriteConfig.height = 30
$ButtonMonitoringWriteConfig.location = [System.Drawing.Point]::new(600, 15)
$ButtonMonitoringWriteConfig.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MonitoringSettingsControls += $ButtonMonitoringWriteConfig
$ButtonMonitoringWriteConfig.Add_Click( { PrepareWriteConfig })

$MainForm | Add-Member -Name number -Value 0 -MemberType NoteProperty

$TimerUI = New-Object System.Windows.Forms.Timer
# $TimerUI.Add_Tick({ TimerUI_Tick})

$TimerUI.Enabled = $false

$ButtonPause.Add_Click(
    { 
        If (-not $Variables.Paused) { 
            Write-Message "Stopping miners"
            $Variables.Paused = $true

            # Stop and start mining to immediately switch to paused state without waiting for current NMCycle to finish
            $Variables.RestartCycle = $true

            $ButtonPause.Text = "Mine"
            Write-Message "Mining paused. BrainPlus and Earning tracker running."
            $LabelBTCD.Text = "Mining Paused | $($Branding.ProductLabel) $($Variables.CurrentVersion)"
            # $TimerUI.Stop()
        }
        Else { 
            $Variables.Paused = $false
            $ButtonPause.Text = "Pause"
            $Variables | Add-Member -Force @{ LastDonated = (Get-Date).AddDays(-1).AddHours(1) }
            $TimerUI.Start()

            # Stop and start mining to immediately switch to unpaused state without waiting for current sleep to finish
            $Variables.RestartCycle = $true
        }
    }
)

$ButtonStart.Add_Click(
    { 
        If ($Variables.Started) { 
            $ButtonPause.Visible = $false
            Write-Message "Stopping cycle"
            $Variables.Started = $false
            Write-Message "Stopping jobs and miner"

            $Variables.EarningsTrackerJobs | ForEach-Object { $_ | Stop-Job -PassThru | Remove-Job }
            $Variables.EarningsTrackerJobs = @()
            $Variables.BrainJobs | ForEach-Object { $_ | Stop-Job -PassThru | Remove-Job }
            $Variables.BrainJobs = @()

            Stop-Mining

            # Stop idle tracking
            If ($IdleRunspace) { $IdleRunspace.Close() }
            If ($IdlePowershell) { $IdlePowershell.Dispose() }

            $LabelBTCD.Text = "Stopped | $($Branding.ProductLabel) $($Variables.CurrentVersion)"
            Write-Message "Idle"
            $ButtonStart.Text = "Start"
            # $TimerUI.Interval = 1000
            $TimerUI.Stop()
        }
        Else { 
            PrepareWriteConfig
            $ButtonStart.Text = "Stop"
            Initialize-Application
            $Variables | Add-Member -Force @{ MainPath = (Split-Path $script:MyInvocation.MyCommand.Path) }

            Start-IdleTracking

            If ($Config.MineWhenIdle) { 
                # Disable the pause button - pausing controlled by idle timer
                $Variables.Paused = $true
                $ButtonPause.Visible = $false
            }
            Else { 
                $ButtonPause.Visible = $true
            }
            $TimerUI.Start()

While ($DebugLoop) {
    Start-Transcript -Path ".\Logs\CoreCyle-$((Get-Date).ToString('yyyyMMdd')).log" -Append -Force
    Start-NPMCycle #Added temporary, set a trace point.
}

            Start-Mining

            $Variables.Started = $true
        }
    }
)

$ShowWindow = Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);' -Name Win32ShowWindowAsync -Namespace Win32Functions -PassThru
$ParentPID = (Get-CimInstance -Class Win32_Process -Filter "ProcessID = $pid").ParentProcessId
$ConsoleHandle = (Get-Process -Id $ParentPID).MainWindowHandle
$ConsoleHandle = (Get-Process -Id $pid).MainWindowHandle

$MainForm.Controls.AddRange($MainFormControls)
$RunPage.Controls.AddRange(@($RunPageControls))
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
# $TimerUI.Add_Tick({ TimerUI_Tick})

[Void]$MainForm.ShowDialog()
