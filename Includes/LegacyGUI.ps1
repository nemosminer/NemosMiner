<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           LegacyGUI.psm1
Version:        4.3.4.8
Version date:   21 May 2023
#>

# [Void] [System.Windows.Forms.Application]::EnableVisualStyles()
[Void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[Void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
[Void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

#--- For High DPI, Call SetProcessDPIAware(need P/Invoke) and EnableVisualStyles ---
Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
public class ProcessDPI {
    [DllImport("user32.dll", SetLastError=true)]
    public static extern bool SetProcessDPIAware(); 
}
'@
$null = [ProcessDPI]::SetProcessDPIAware()
[System.Windows.Forms.Application]::EnableVisualStyles()

Function CheckBoxSwitching_Click { 

    $LegacyGUIForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    $SwitchingDisplayTypes = @()
    $SwitchingPageControls | ForEach-Object { If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } }
    If (Test-Path -Path ".\Logs\SwitchingLog.csv" -PathType Leaf) { 
        $SwitchingLogLabel.Text = "Switching Log - Updated $((Get-ChildItem -Path ".\Logs\SwitchingLog.csv").LastWriteTime.ToString())"

        $SwitchingDGV.DataSource = Get-Content ".\Logs\SwitchingLog.csv" | ConvertFrom-Csv | Where-Object { $_.Type -in $SwitchingDisplayTypes } | Select-Object -Last 1000 | ForEach-Object { $_.Datetime = (Get-Date $_.DateTime).ToString("G"); $_ } | Select-Object @("DateTime", "Action", "Name", "Pools", "Algorithms", "Accounts", "Cycle", "Duration", "DeviceNames", "Type") | Out-DataTable
        If ($SwitchingDGV.Columns) { 
            $SwitchingDGV.Columns[0].FillWeight = 50
            $SwitchingDGV.Columns[1].FillWeight = 50
            $SwitchingDGV.Columns[2].FillWeight = 90; $SwitchingDGV.Columns[2].HeaderText = "Miner"
            $SwitchingDGV.Columns[3].FillWeight = 60 + ($SwitchingDGV.MinersBest_Combo | ForEach-Object { $_.Pools.Count } | Measure-Object -Maximum).Maximum * 40; $SwitchingDGV.Columns[3].HeaderText = "Pool(s)"
            $SwitchingDGV.Columns[4].FillWeight = 50 + ($SwitchingDGV.MinersBest_Combo | ForEach-Object { $_.Algorithms.Count } | Measure-Object -Maximum).Maximum * 25; $SwitchingDGV.Columns[4].HeaderText = "Algorithm(s)"
            $SwitchingDGV.Columns[5].FillWeight = 90 + ($SwitchingDGV.MinersBest_Combo | ForEach-Object { $_.Accounts.Count } | Measure-Object -Maximum).Maximum * 50; $SwitchingDGV.Columns[5].HeaderText = "Account(s)"
            $SwitchingDGV.Columns[6].FillWeight = 30; $SwitchingDGV.Columns[6].HeaderText = "Cycles"; $SwitchingDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $SwitchingDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
            $SwitchingDGV.Columns[7].FillWeight = 35; $SwitchingDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $SwitchingDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
            $SwitchingDGV.Columns[8].FillWeight = 30 + ($SwitchingDGV.MinersBest_Combo | ForEach-Object { $_.DeviceNames.Count } | Measure-Object -Maximum).Maximum * 15; $SwitchingDGV.Columns[8].HeaderText = "Device(s)"
            $SwitchingDGV.Columns[9].FillWeight = 30
        }

        Colorize_SwitchingLog

        $SwitchingDGV.ClearSelection()
    }
    Else { $SwitchingLogLabel.Text = "Switching Log - no data" }

    $SwitchingLogClearButton.Enabled = [Boolean]$SwitchingDGV.Columns

    $LegacyGUIForm.Cursor = [System.Windows.Forms.Cursors]::Normal
}

Function Set-DataGridViewDoubleBuffer {
    Param (
        [Parameter(Mandatory = $true)][System.Windows.Forms.DataGridView]$Grid,
        [Parameter(Mandatory = $true)][Boolean]$Enabled
    )

    $Type = $Grid.GetType();
    $PropInfo = $Type.GetProperty("DoubleBuffered", ("Instance", "NonPublic"))
    $PropInfo.SetValue($Grid, $Enabled, $null)
}

Function Colorize_Miners { 
    If ($Config.UseColorForMinerStatus) { 
        ForEach ($Row in $MinersDGV.Rows) { 
            $Row.DefaultCellStyle.Backcolor = Switch -RegEx ($Row.DataBoundItem.Status) { 
                "^Benchmarking|^Measuring" { [System.Drawing.Color]::FromArgb(255, 250, 230, 212); Break }
                "^Disabled"                { [System.Drawing.Color]::FromArgb(255, 255, 243, 231); Break }
                "^Failed"                  { [System.Drawing.Color]::FromArgb(255, 255, 230, 230); Break }
                "^Idle"                    { [System.Drawing.Color]::FromArgb(255, 230, 248, 252); Break }
                "^Mining"                  { [System.Drawing.Color]::FromArgb(255, 232, 250, 232); Break }
                "^Stopping"                { [System.Drawing.Color]::FromArgb(255, 245, 255, 245); Break }
                "^Unavailable"             { [System.Drawing.Color]::FromArgb(255, 254, 245, 220); Break }
                "^Warming"                 { [System.Drawing.Color]::FromArgb(255, 253, 246, 241); Break }
                Default                    { [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
            }
        }
    }
}

Function Colorize_SwitchingLog { 
    If ($Config.UseColorForMinerStatus) { 
        ForEach ($Row in $SwitchingDGV.Rows) { 
            $Row.DefaultCellStyle.Backcolor = Switch ($Row.DataBoundItem.Action) { 
                "Failed"   { [System.Drawing.Color]::FromArgb(255, 255, 230, 230); Break }
                "Stopped"  { [System.Drawing.Color]::FromArgb(255, 230, 248, 252); Break }
                "Launched" { [System.Drawing.Color]::FromArgb(255, 232, 250, 232); Break }
                Default    { [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
            }
        }
        Remove-Variable Row
    }
}

Function Colorize_Workers { 
    If ($Config.UseColorForMinerStatus) { 
        ForEach ($Row in $WorkersDGV.Rows) { 
            $Row.DefaultCellStyle.Backcolor = Switch ($Row.DataBoundItem.Status) { 
                "Offline" { [System.Drawing.Color]::FromArgb(255, 255, 230, 230); Break }
                "Paused"  { [System.Drawing.Color]::FromArgb(255, 255, 241, 195); Break }
                "Running" { [System.Drawing.Color]::FromArgb(255, 232, 250, 232); Break }
                Default   { [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
            }
        }
    }
}

Function Update-TabControl { 

    $LegacyGUIForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    # Keep only 100 lines, more lines impact performance
    $SelectionLength = $Variables.TextBoxSystemLog.SelectionLength
    $SelectionStart = $Variables.TextBoxSystemLog.SelectionStart
    $TextLength = $Variables.TextBoxSystemLog.TextLength
    $Variables.TextBoxSystemLog.Lines = $Variables.TextBoxSystemLog.Lines | Select-Object -Last 100
    $SelectionStart = $SelectionStart - $TextLength + $Variables.TextBoxSystemLog.TextLength
    If ($SelectionStart -gt 0) { 
        $Variables.TextBoxSystemLog.Select($SelectionStart, $SelectionLength)
    }

    Switch ($TabControl.SelectedTab.Text) { 
        "Run" { 
            $ContextMenuStripItem1.Text = "Re-Benchmark"
            $ContextMenuStripItem1.Visible = $true
            $ContextMenuStripItem2.Text = "Re-Measure Power Usage"
            $ContextMenuStripItem2.Visible = $true
            $ContextMenuStripItem3.Text = "Mark as failed"
            $ContextMenuStripItem3.Visible = $true
            $ContextMenuStripItem4.Text = "Disable"
            $ContextMenuStripItem4.Visible = $true
            $ContextMenuStripItem5.Visible = $false

            If ($Variables.MinersBest_Combo) { 

                If (-not ($ContextMenuStrip.Visible -and $ContextMenuStrip.Enabled)) { 
                    $LaunchedMinersLabel.Text = "Launched Miners - Updated $((Get-Date).ToString())"

                    $LaunchedMinersDGV.BeginInit()
                    $LaunchedMinersDGV.ClearSelection()
                    $LaunchedMinersDGV.DataSource = $Variables.MinersBest_Combo | Select-Object @(
                        @{ Name = "Device(s)"; Expression = { $_.DeviceNames -join "; " } }
                        @{ Name = "Miner"; Expression = { $_.Name } }
                        @{ Name = "Status"; Expression = { $_.StatusMessage -replace " \{.+", "" } }, 
                        @{ Name = "Earning`n$($Config.Currency)/day"; Expression = { If (-not [Double]::IsNaN($_.Earning)) {"{0:n$($Config.DecimalsMax)}" -f ($_.Earning * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }
                        @{ Name = "Power Cost`n$($Config.Currency)/day"; Expression = { If ($Variables.CalculatePowerCost -and -not [Double]::IsNaN($_.PowerCost)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }
                        @{ Name = "Profit`n$($Config.Currency)/day"; Expression = { If ($Variables.CalculatePowerCost -and -not [Double]::IsNaN($_.Profit)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }
                        @{ Name = "Power Usage"; Expression = { If (-not $_.MeasurePowerUsage) { If ([Double]::IsNaN($_.PowerUsage)) { "n/a" } Else { "$($_.PowerUsage.ToString("N2")) W"} } Else { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } } }
                        @{ Name = "Algorithm(s)"; Expression = { $_.Algorithms -join ' & ' } }, 
                        @{ Name = "Pool(s)"; Expression = { $_.WorkersRunning.Pool.Name -join ' & ' } }
                        @{ Name = "Hashrate(s)"; Expression = { If (-not $_.Benchmark) { ($_.Workers | ForEach-Object { "$($_.Hashrate | ConvertTo-Hash)/s" -replace "\s+", " " }) -join " & " } Else { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } } }
                        @{ Name = "Running Time`n(hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [math]::floor(((Get-Date).ToUniversalTime() - $_.BeginTime).TotalDays * 24), ((Get-Date).ToUniversalTime() - $_.BeginTime) } }
                        @{ Name = "Total active`n(hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [math]::floor($_.TotalMiningDuration.TotalDays * 24), $_.TotalMiningDuration } }
                        If ($RadioButtonPoolsUnavailable.checked) { @{ Name = "Reason"; Expression = { $_.Reasons -join ', ' } } }
                    ) | Sort-Object "Device(s)" | Out-DataTable
                    If ($LaunchedMinersDGV.Columns) { 
                        $LaunchedMinersDGV.Columns[0].FillWeight = 30 + ($Variables.MinersBest_Combo | ForEach-Object { $_.DeviceNames.Count } | Measure-Object -Maximum).Maximum * 20
                        $LaunchedMinersDGV.Columns[1].FillWeight = 160
                        $LaunchedMinersDGV.Columns[2].FillWeight = 60
                        $LaunchedMinersDGV.Columns[3].FillWeight = 55; $LaunchedMinersDGV.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $LaunchedMinersDGV.Columns[4].FillWeight = 55; $LaunchedMinersDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[4].Visible = $Variables.CalculatePowerCost
                        $LaunchedMinersDGV.Columns[5].FillWeight = 55; $LaunchedMinersDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[5].Visible = $Variables.CalculatePowerCost
                        $LaunchedMinersDGV.Columns[6].FillWeight = 55; $LaunchedMinersDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[6].Visible = $Variables.CalculatePowerCost
                        $LaunchedMinersDGV.Columns[7].FillWeight = 70 + ($Variables.MinersBest_Combo | ForEach-Object { $_.Workers.Count } | Measure-Object -Maximum).Maximum * 35
                        $LaunchedMinersDGV.Columns[8].FillWeight = 50 + ($Variables.MinersBest_Combo | ForEach-Object { $_.Workers.Count } | Measure-Object -Maximum).Maximum * 25
                        $LaunchedMinersDGV.Columns[9].FillWeight = 50 + ($Variables.MinersBest_Combo | ForEach-Object { $_.Workers.Count } | Measure-Object -Maximum).Maximum * 25; $LaunchedMinersDGV.Columns[9].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"
                        $LaunchedMinersDGV.Columns[10].FillWeight = 65; $LaunchedMinersDGV.Columns[10].DefaultCellStyle.Alignment = "MiddleRight";  $LaunchedMinersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                        $LaunchedMinersDGV.Columns[11].FillWeight = 65; $LaunchedMinersDGV.Columns[11].DefaultCellStyle.Alignment = "MiddleRight";  $LaunchedMinersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
                    }
                    If ($Config.UseColorForMinerStatus) { 
                        ForEach ($Row in $LaunchedMinersDGV.Rows) { 
                            $Row.DefaultCellStyle.Backcolor = Switch -RegEx ($Row.DataBoundItem.Status) { 
                                "^Benchmarking|^Measuring" { [System.Drawing.Color]::FromArgb(255, 250, 230, 212); Break }
                                "^Disabled"                { [System.Drawing.Color]::FromArgb(255, 255, 243, 231); Break }
                                "^Failed"                  { [System.Drawing.Color]::FromArgb(255, 255, 230, 230); Break }
                                "^Idle"                    { [System.Drawing.Color]::FromArgb(255, 230, 248, 252); Break }
                                "^Mining"                  { [System.Drawing.Color]::FromArgb(255, 232, 250, 232); Break }
                                "^Stopping"                { [System.Drawing.Color]::FromArgb(255, 245, 255, 245); Break }
                                "^Unavailable"             { [System.Drawing.Color]::FromArgb(255, 254, 245, 220); Break }
                                "^Warming"                 { [System.Drawing.Color]::FromArgb(255, 253, 246, 241); Break }
                                Default                    { [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
                            }
                        }
                        Remove-Variable Row
                    }
                    Form_Resize # To fully show lauched miners gridview
                    $LaunchedMinersDGV.EndInit()
                }
            }
            Else { 
                $LaunchedMinersDGV.DataSource = @()
                $LaunchedMinersLabel.Text = "No miners running."
            }
            Break
        }
        "Earnings" { 

            Function Get-NextColor { 
                Param(
                    [Parameter(Mandatory = $true)]
                    [Byte[]]$Color, 
                    [Parameter(Mandatory = $true)]
                    [Int[]]$Factors
                )

                # Apply change Factor
                0..($Color.Count - 1) | ForEach-Object { 
                    $Color[$_] = [math]::Abs(($Color[$_] + $Factors[$_]) % 192)
                }
                $Color
            }

            If (Test-Path -Path ".\Data\EarningsChartData.json" -PathType Leaf) { 
                Try { 
                    $Datasource = Get-Content -Path ".\Data\EarningsChartData.json" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore

                    $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
                    $ChartTitle.Alignment = "TopCenter"
                    $ChartTitle.Font = [System.Drawing.Font]::new("Arial", 10)
                    $ChartTitle.Text = "Earnings of the past $($DataSource.Labels.Count) active days"
                    $EarningsChart.Titles.Clear()
                    $EarningsChart.Titles.Add($ChartTitle)

                    $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
                    $ChartArea.AxisX.Enabled = 0
                    $ChartArea.AxisX.Interval = 1
                    $ChartArea.AxisY.IsMarginVisible = $false
                    $ChartArea.AxisY.LabelAutoFitStyle = 16
                    $ChartArea.AxisX.LabelStyle.Enabled = $true
                    $ChartArea.AxisX.Maximum = $Datasource.Labels.Count + 1
                    $ChartArea.AxisX.Minimum = 0
                    $ChartArea.AxisX.IsMarginVisible = $false
                    $ChartArea.AxisX.MajorGrid.Enabled = $false
                    $ChartArea.AxisY.Interval = [Math]::Ceiling(($Datasource.DaySum | Measure-Object -Maximum).Maximum / 4)
                    $ChartArea.AxisY.LabelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
                    $ChartArea.AxisY.MajorGrid.Enabled = $true
                    $ChartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#FFFFFF"
                    $ChartArea.AxisY.Title = $Config.Currency
                    $ChartArea.AxisY.ToolTip = "Total Earnings per day"
                    $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#2B3232" 
                    $ChartArea.BackGradientStyle = 3
                    $ChartArea.BackSecondaryColor = [System.Drawing.Color]::FromArgb(255, 224, 224, 224) #"#777E7E"

                    $EarningsChart.ChartAreas.Clear()
                    $EarningsChart.ChartAreas.Add($ChartArea)
                    $EarningsChart.Series.Clear()

                    $Color = @(255, 255, 255, 255) #"FFFFFF"

                    $DaySum = @(0) * $DataSource.Labels.Count
                    $ToolTip = $DataSource.Labels.Clone()

                    ForEach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 

                        $Color = (Get-NextColor -Color $Color -Factors -0, -20, -20, -20)

                        $EarningsChart.Series.Add($Pool)
                        $EarningsChart.Series[$Pool].ChartType = "StackedColumn"
                        $EarningsChart.Series[$Pool].BorderWidth = 3
                        $EarningsChart.Series[$Pool].Color = [System.Drawing.Color]::FromArgb($Color[0], $Color[1], $Color[2], $Color[3])

                        $I = 0
                        $Datasource.Earnings.$Pool | ForEach-Object { 
                            $_ *= $Variables.Rates.BTC.($Config.Currency)
                            $EarningsChart.Series[$Pool].Points.addxy(0, "{0:N$($Variables.Digits)}" -f $_) | Out-Null
                            $Daysum[$I] += $_
                            If ($_) { 
                                $ToolTip[$I] = "$($ToolTip[$I])`n$($Pool): {0:N$($Config.DecimalsMax)} $($Config.Currency)" -f $_
                            }
                            $I ++
                        }
                    }
                    Remove-Variable Pool

                    $I = 0
                    $DataSource.Labels | ForEach-Object { 
                        $ChartArea.AxisX.CustomLabels.Add($I +0.5, $I + 1.5, " $_ ")
                        $ChartArea.AxisX.CustomLabels[$I].ToolTip = "$($ToolTip[$I])`nTotal: {0:N$($Config.DecimalsMax)} $($Config.Currency)" -f $Daysum[$I]
                        ForEach ($Pool in ($DataSource.Earnings.PSObject.Properties.Name)) { 
                            If ($Datasource.Earnings.$Pool[$I]) { 
                                $EarningsChart.Series[$Pool].Points[$I].ToolTip = "$($ToolTip[$I])`nTotal: {0:N$($Config.DecimalsMax)} $($Config.Currency)" -f $Daysum[$I]
                            }
                        }
                        $I ++
                    }

                    $ChartArea.AxisY.Maximum = ($DaySum | Measure-Object -Maximum).Maximum * 1.05
                }
                Catch {}
            }
            If ($Config.BalancesTrackerPollInterval -gt 0) { 
                If ($Variables.Balances) { 
                    $BalancesLabel.Text = "Balances data - Updated $(($Variables.Balances.Values.LastUpdated | Sort-Object | Select-Object -Last 1).ToLocalTime().ToString())"

                    $BalancesDGV.BeginInit()
                    $BalancesDGV.ClearSelection()
                    $Currency = If ($Config.BalancesShowInMainCurrency) { $Config.Currency } Else { $_.Currency}
                    $BalancesDGV.DataSource = $Variables.Balances.Values | Select-Object @(
                        @{ Name = "Currency"; Expression = { $_.Currency } }, 
                        @{ Name = "Pool [Currency]"; Expression = { "$($_.Pool) [$($_.Currency)]" } }, 
                        @{ Name = "Balance ($($Config.Currency))"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Balance * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "Avg. $($Config.Currency)/day"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.AvgDailyGrowth * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "$($Config.Currency) in 1h"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth1 * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "$($Config.Currency) in 6h"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth6 * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "$($Config.Currency) in 24h"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth24 * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                        @{ Name = "Projected Paydate"; Expression = { If ($_.ProjectedPayDate -is [DateTime]) { $_.ProjectedPayDate.ToShortDateString() } Else { $_.ProjectedPayDate } } }, 
                        @{ Name = "Payout Threshold"; Expression = { If ($_.PayoutThresholdCurrency -eq "BTC" -and $Config.UsemBTC) { $PayoutThresholdCurrency = "mBTC"; $mBTCfactor = 1000 } Else { $PayoutThresholdCurrency = $_.PayoutThresholdCurrency; $mBTCfactor = 1 }; "{0:P2} of {1} {2} " -f ($_.Balance / $_.PayoutThreshold * $Variables.Rates.($_.Currency).($_.PayoutThresholdCurrency)), ($_.PayoutThreshold * $mBTCfactor), $PayoutThresholdCurrency } }
                    ) | Sort-Object Pool | Out-DataTable
                    If ($BalancesDGV.Columns) { 
                        $BalancesDGV.Columns[0].Visible = $False
                        $BalancesDGV.Columns[1].FillWeight = 140 
                        $BalancesDGV.Columns[2].FillWeight = 90; $BalancesDGV.Columns[2].DefaultCellStyle.Alignment = "MiddleRight"; $BalancesDGV.Columns[2].HeaderCell.Style.Alignment = "MiddleRight"
                        $BalancesDGV.Columns[3].FillWeight = 90; $BalancesDGV.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"; $BalancesDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $BalancesDGV.Columns[4].FillWeight = 75; $BalancesDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $BalancesDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $BalancesDGV.Columns[5].FillWeight = 75; $BalancesDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $BalancesDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                        $BalancesDGV.Columns[6].FillWeight = 75; $BalancesDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $BalancesDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
                        $BalancesDGV.Columns[7].FillWeight = 80
                        $BalancesDGV.Columns[8].FillWeight = 100
                    }
                    $BalancesDGV.Rows | ForEach-Object { 
                        $_.Cells[2].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[2].Value * $Variables.Rates.($Config.Currency).($_.Cells[0].Value))
                        $_.Cells[3].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[3].Value * $Variables.Rates.($Config.Currency).($_.Cells[0].Value))
                        $_.Cells[4].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[4].Value * $Variables.Rates.($Config.Currency).($_.Cells[0].Value))
                        $_.Cells[5].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[5].Value * $Variables.Rates.($Config.Currency).($_.Cells[0].Value))
                        $_.Cells[6].ToolTipText = "$($_.Cells[0].Value) {0:n$($Config.DecimalsMax)}" -f ([Double]$_.Cells[6].Value * $Variables.Rates.($Config.Currency).($_.Cells[0].Value))
                    }
                    Form_Resize # To fully show lauched miners gridview
                    $BalancesDGV.EndInit()
                }
                Else { 
                    $BalancesLabel.Text = "Waiting for balances data..."
                }
            }
            Else { 
                $BalancesLabel.Text = "BalanceTracker is disabled (Configuration item 'BalancesTrackerPollInterval' -eq 0)"
            }
            Break
        }
        "Miners" { 
            $ContextMenuStripItem1.Text = "Re-Benchmark"
            $ContextMenuStripItem1.Visible = $true
            $ContextMenuStripItem2.Text = "Re-Measure Power Usage"
            $ContextMenuStripItem2.Visible = $true
            $ContextMenuStripItem3.Text = "Mark as failed"
            $ContextMenuStripItem4.Visible = (-not $RadioButtonMinersUnavailable.Checked)
            $ContextMenuStripItem4.Text = "Disable"
            $ContextMenuStripItem4.Visible = (-not $RadioButtonMinersUnavailable.Checked)
            $ContextMenuStripItem5.Text = "Remove Watchdog Timer"
            $ContextMenuStripItem5.Visible = -not $RadioButtonMinersBest.Checked

            If ($Variables.Miners) { 
                $MinersLabel.Text = "Miner data read from stats - Updated $((Get-Date).ToString())"

                If (-not ($ContextMenuStrip.Visible -and $ContextMenuStrip.Enabled)) { 

                    If ($RadioButtonMinersBest.checked) { $DataSource = $Variables.MinersMostProfitable }
                    ElseIf ($RadioButtonMinersUnavailable.checked) { $DataSource = $Variables.Miners | Where-Object { -not $_.Available } }
                    Else { $DataSource = $Variables.Miners }

                    $MinersDGV.BeginInit()
                    $MinersDGV.ClearSelection()
                    $MinersDGV.DataSource = $DataSource | Select-Object @(
                        @{ Name = "Best"; Expression = { $_.Best } }, 
                        @{ Name = "Miner"; Expression = { $_.Name } }, 
                        @{ Name = "Device(s)"; Expression = { $_.DeviceNames -join ', ' } }, 
                        @{ Name = "Status"; Expression = { If ($_.StatusMessage) { $_.StatusMessage -replace " \{.+", "" } Else { $_.Status } } }, 
                        @{ Name = "Earning`n$($Config.Currency)/day"; Expression = { If (-not [Double]::IsNaN($_.Earning)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Earning * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }, 
                        @{ Name = "Power Cost`n$($Config.Currency)/day"; Expression = { If (-not [Double]::IsNaN($_.PowerCost)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }, 
                        @{ Name = "Profit`n$($Config.Currency)/day"; Expression = { If ($Variables.CalculatePowerCost -and -not [Double]::IsNaN($_.Profit)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }, 
                        @{ Name = "Power Usage"; Expression = { If (-not $_.MeasurePowerUsage) { If ([Double]::IsNaN($_.PowerUsage)) { "n/a" } Else { "$($_.PowerUsage.ToString("N2")) W"} } Else { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } } }
                        @{ Name = "Algorithm(s)"; Expression = { $_.Algorithms -join ' & ' } }, 
                        @{ Name = "Pool(s)"; Expression = { $_.Workers.Pool.Name -join ' & ' } }, 
                        @{ Name = "Hashrate(s)"; Expression = { If (-not $_.Benchmark) { ($_.Workers | ForEach-Object { "$($_.Hashrate | ConvertTo-Hash)/s" -replace "\s+", " " }) -join " & " } Else { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } } }
                        If ($RadioButtonMinersUnavailable.checked -or $RadioButtonMiners.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ', '} } }
                    ) | Sort-Object @{ Expression = { $_.Best }; Descending = $true }, "Device(s)", Miner | Out-DataTable
                    If ($MinersDGV.Columns) { 
                        $MinersDGV.Columns[0].Visible = $False
                        $MinersDGV.Columns[1].FillWeight = 160
                        $MinersDGV.Columns[2].FillWeight = 25 + ($DataSource | ForEach-Object { $_.DeviceNames.Count } | Measure-Object -Maximum).Maximum * 25
                        $MinersDGV.Columns[3].FillWeight = 50
                        $MinersDGV.Columns[4].FillWeight = 55; $MinersDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $MinersDGV.Columns[5].FillWeight = 60; $MinersDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"; $MinersDGV.Columns[5].Visible = $Variables.CalculatePowerCost
                        $MinersDGV.Columns[6].FillWeight = 55; $MinersDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"; $MinersDGV.Columns[6].Visible = $Variables.CalculatePowerCost
                        $MinersDGV.Columns[7].FillWeight = 55; $MinersDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"; $MinersDGV.Columns[7].Visible = $Variables.CalculatePowerCost
                        $MinersDGV.Columns[8].FillWeight = 60  + ($DataSource | ForEach-Object { $_.Workers.Count } | Measure-Object -Maximum).Maximum * 30
                        $MinersDGV.Columns[9].FillWeight = 60  + ($DataSource | ForEach-Object { $_.Workers.Count } | Measure-Object -Maximum).Maximum * 30
                        $MinersDGV.Columns[10].FillWeight = 50 + ($DataSource | ForEach-Object { $_.Workers.Count } | Measure-Object -Maximum).Maximum * 25; $MinersDGV.Columns[10].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                    }
                    Colorize_Miners
                    $MinersDGV.EndInit()
                }
            }
            Else { $MinersLabel.Text = "Waiting for data..." }
            Break
        }
        "Pools" { 
            $ContextMenuStripItem1.Visible = $false
            $ContextMenuStripItem2.Visible = $false
            $ContextMenuStripItem3.Text = "Reset Pool Stat Data"
            $ContextMenuStripItem3.Visible = $true
            $ContextMenuStripItem4.Text = "Remove Watchdog Timer"
            $ContextMenuStripItem4.Visible = (-not $RadioButtonPoolsBest.Checked)
            $ContextMenuStripItem5.Visible = $false

            If ($Variables.Pools) { 
                $PoolsLabel.Text = "Pool data read from stats - Updated $((Get-Date).ToString())"

                If (-not ($ContextMenuStrip.Visible -and $ContextMenuStrip.Enabled)) { 

                    If ($RadioButtonPoolsBest.checked) { $DataSource = $Variables.PoolsBest }
                    ElseIf ($RadioButtonPoolsUnavailable.checked) { $DataSource = $Variables.Pools | Where-Object { -not $_.Available } }
                    Else { $DataSource = $Variables.Pools }

                    If ($Config.UsemBTC) { 
                        $Factor = 1000
                        $Unit = "mBTC"
                     }
                     Else { 
                        $Factor = 1
                        $Unit = "BTC"
                    }

                    $PoolsDGV.BeginInit()
                    $PoolsDGV.ClearSelection()
                    $PoolsDGV.DataSource = $DataSource | Select-Object @(
                        @{ Name = "Algorithm"; Expression = { $_.Algorithm } }
                        @{ Name = "Coin Name"; Expression = { $_.CoinName } }
                        @{ Name = "Currency"; Expression = { $_.Currency } }
                        @{ Name = "$Unit/GH/Day`n(Biased)"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Price_Bias * [Math]::Pow(1024, 3) * $Factor) } }
                        @{ Name = "Accuracy"; Expression = { "{0:p2}" -f $_.Accuracy } }
                        @{ Name = "Pool Name"; Expression = { $_.Name } }
                        @{ Name = "Host"; Expression = { $_.Host } }
                        @{ Name = "Port"; Expression = { "$(If ($_.Port) { $_.Port } Else { "-" })" } }
                        @{ Name = "PortSSL"; Expression = { "$(If ($_.PortSSL) { $_.PortSSL } Else { "-" })" } }
                        @{ Name = "Earnings`nAdjustment`nFactor"; Expression = { $_.EarningsAdjustmentFactor } }
                        @{ Name = "Fee"; Expression = { "{0:p2}" -f $_.Fee } }
                        If ($RadioButtonPoolsUnavailable.checked -or $RadioButtonPools.checked) { @{ Name = "Reason(s)"; Expression = { $_.Reasons -join ', '} } }
                    ) | Sort-Object Algorithm | Out-DataTable
                    If ($PoolsDGV.Columns) { 
                        $PoolsDGV.Columns[0].FillWeight = 80
                        $PoolsDGV.Columns[1].FillWeight = 70
                        $PoolsDGV.Columns[2].FillWeight = 40
                        $PoolsDGV.Columns[3].FillWeight = 55; $PoolsDGV.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[4].FillWeight = 45; $PoolsDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[5].FillWeight = 80
                        $PoolsDGV.Columns[6].FillWeight = 140
                        $PoolsDGV.Columns[7].FillWeight = 40; $PoolsDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[8].FillWeight = 40; $PoolsDGV.Columns[8].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[9].FillWeight = 50; $PoolsDGV.Columns[9].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[10].FillWeight = 40; $PoolsDGV.Columns[10].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                    }
                    $PoolsDGV.EndInit()
                }
            }
            Else { 
                $PoolsLabel.Text = "Waiting for data..."
            }
            Break
        }
        "Rig Monitor" { 
            $WorkersDGV.Visible = $Config.ShowWorkerStatus

            If ($Config.ShowWorkerStatus) { 

                Read-MonitoringData | Out-Null

                If ($Variables.Workers) { 
                    $WorkersLabel.Text = "Worker Status - Updated $($Variables.WorkersLastUpdated.ToString())"

                    $nl = "`n" # Must use variable, cannot join with '`n' directly

                    $WorkersDGV.BeginInit()
                    $WorkersDGV.ClearSelection()
                    $WorkersDGV.DataSource = $Variables.Workers | Select-Object @(
                        @{ Name = "Worker"; Expression = { $_.worker } }, 
                        @{ Name = "Status"; Expression = { $_.status } }, 
                        @{ Name = "Last seen"; Expression = { (Get-TimeSince $_.date) } }, 
                        @{ Name = "Version"; Expression = { $_.version } }, 
                        @{ Name = "Currency"; Expression = { ForEach-Object { $_.data.Currency | Select-Object -Unique } } }, 
                        @{ Name = "Estimated Earning/day"; Expression = { If ($null -ne $_.Data) { "{0:n$($Config.DecimalsMax)}" -f (($_.Data.Earning | Where-Object { -not [Double]::IsNaN($_) } | Measure-Object -Sum).Sum * $Variables.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } }, 
                        @{ Name = "Estimated Profit/day"; Expression = { If ($null -ne $_.Data) { " {0:n$($Config.DecimalsMax)}" -f (($_.Data.Profit | Where-Object { -not [Double]::IsNaN($_) } | Measure-Object -Sum).Sum * $Variables.Rates.BTC.($_.data.Currency | Select-Object -Unique)) } } }, 
                        @{ Name = "Miner(s)"; Expression = { $_.data.Name -join $nl } }, 
                        @{ Name = "Pool(s)"; Expression = { ($_.data | ForEach-Object { $_.Pool -split "," -join " & " }) -join $nl } }, 
                        @{ Name = "Algorithm(s)"; Expression = { ($_.data | ForEach-Object { $_.Algorithm -split "," -join " & " }) -join $nl } }, 
                        @{ Name = "Live Hashrate(s)"; Expression = { ($_.data | ForEach-Object { ($_.CurrentSpeed | ForEach-Object { If ([Double]::IsNaN($_)) { "n/a" } Else { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } }) -join " & " }) -join $nl } }, 
                        @{ Name = "Benchmark Hashrate(s)"; Expression = { ($_.data | ForEach-Object { ($_.EstimatedSpeed | ForEach-Object { If ([Double]::IsNaN($_)) { "n/a" } Else { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " } }) -join " & " }) -join $nl } }
                    ) | Sort-Object "Worker" | Out-DataTable
                    If ($WorkersDGV.Columns) { 
                        $WorkersDGV.Columns[0].FillWeight = 70
                        $WorkersDGV.Columns[1].FillWeight = 60
                        $WorkersDGV.Columns[2].FillWeight = 80
                        $WorkersDGV.Columns[3].FillWeight = 70
                        $WorkersDGV.Columns[4].FillWeight = 40
                        $WorkersDGV.Columns[5].FillWeight = 65; $WorkersDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $WorkersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                        $WorkersDGV.Columns[6].FillWeight = 65; $WorkersDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $WorkersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
                        $WorkersDGV.Columns[7].FillWeight = 150
                        $WorkersDGV.Columns[8].FillWeight = 95
                        $WorkersDGV.Columns[9].FillWeight = 75
                        $WorkersDGV.Columns[10].FillWeight = 65; $WorkersDGV.Columns[10].DefaultCellStyle.Alignment = "MiddleRight"; $WorkersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                        $WorkersDGV.Columns[11].FillWeight = 65; $WorkersDGV.Columns[11].DefaultCellStyle.Alignment = "MiddleRight"; $WorkersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
                    }
                    Colorize_Workers
                    $WorkersDGV.EndInit()
                }
                Else { $WorkersLabel.Text = "Worker Status - no workers" }
            }
            Else { 
                $WorkersLabel.Text = "Worker status reporting is disabled (Configuration item 'ShowWorkerStatus' -eq `$false)"
            }
            Break
        }
        "Switching Log" { 
            $CheckShowSwitchingCPU.Enabled = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Type -EQ "CPU")
            $CheckShowSwitchingAMD.Enabled = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Type -EQ "GPU" | Where-Object Vendor -EQ "AMD")
            $CheckShowSwitchingINTEL.Enabled = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Type -EQ "GPU" | Where-Object Vendor -EQ "INTEL")
            $CheckShowSwitchingNVIDIA.Enabled = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Type -EQ "GPU" | Where-Object Vendor -EQ "NVIDIA")

            If (-not $CheckShowSwitchingCPU.Enabled) { $CheckShowSwitchingCPU.Checked = $false }
            If (-not $CheckShowSwitchingAMD.Enabled) { $CheckShowSwitchingAMD.Checked = $false }
            If (-not $CheckShowSwitchingINTEL.Enabled) { $CheckShowSwitchingINTEL.Checked = $false }
            If (-not $CheckShowSwitchingNVIDIA.Enabled) { $CheckShowSwitchingNVIDIA.Checked = $false }

            CheckBoxSwitching_Click
            Break
        }
        "Watchdog Timers" { 
            $WatchdogTimersRemoveButton.Visible = $Config.Watchdog
            $WatchdogTimersDGV.Visible = $Config.Watchdog

            If ($Config.Watchdog) { 
                If ($Variables.WatchdogTimers) { 
                    $WatchdogTimersLabel.Text = "Watchdog Timers - Updated $((Get-Date).ToString())"

                    $WatchdogTimersDGV.BeginInit()
                    $WatchdogTimersDGV.ClearSelection()
                    $WatchdogTimersDGV.DataSource = $Variables.WatchdogTimers | Sort-Object MinerName, Kicked | Select-Object @(
                        @{ Name = "Name"; Expression = { $_.MinerName } }, 
                        @{ Name = "Algorithms"; Expression = { $_.Algorithm } }, 
                        @{ Name = "Pool Name"; Expression = { $_.PoolName } }, 
                        @{ Name = "Region"; Expression = { $_.PoolRegion } }, 
                        @{ Name = "Device(s)"; Expression = { $_.DeviceNames -join ', '} }, 
                        @{ Name = "Last Updated"; Expression = { (Get-TimeSince $_.Kicked.ToLocalTime()) } }
                    ) | Out-DataTable
                    If ($WatchdogTimersDGV.Columns) { 
                        $WatchdogTimersDGV.Columns[0].FillWeight = 120
                        $WatchdogTimersDGV.Columns[1].FillWeight = 100
                        $WatchdogTimersDGV.Columns[2].FillWeight = 100
                        $WatchdogTimersDGV.Columns[3].FillWeight = 60
                        $WatchdogTimersDGV.Columns[4].FillWeight = 30 + ($Variables.WatchdogTimers | ForEach-Object { $_.DeviceNames.Count } | Measure-Object -Maximum).Maximum * 20
                        $WatchdogTimersDGV.Columns[5].FillWeight = 100
                    }
                    $WatchdogTimersDGV.EndInit()
                }
                Else { $WatchdogTimersLabel.Text = "Watchdog Timers - no data" }
            }
            Else { 
                $WatchdogTimersLabel.Text = "Watchdog is disabled (Configuration item 'Watchdog' -eq `$false)"
            }

            $WatchdogTimersRemoveButton.Enabled = [Boolean]$WatchdogTimersDGV.Rows
        }
    }

    $LegacyGUIForm.Cursor = [System.Windows.Forms.Cursors]::Normal
}

Function Form_Resize { 
    If ($LegacyGUIForm.Height -lt $LegacyGUIForm.MinimumSize.Height -or $LegacyGUIForm.Width -lt $LegacyGUIForm.MinimumSize.Width ) { Return } # Sometimes $LegacyGUIForm is smalle than minimum (Why?)
    Try { 
        $TabControl.Width = $LegacyGUIForm.Width - 40
        $TabControl.Height = $LegacyGUIForm.Height - $MiningStatusLabel.Height - $MiningSummaryLabel.Height - $EditConfigLink.Height - 72

        $ButtonStart.Location = [System.Drawing.Point]::new(($LegacyGUIForm.Width - $ButtonStop.Width - $ButtonPause.Width - $ButtonStart.Width - 60), 6)
        $ButtonPause.Location = [System.Drawing.Point]::new(($LegacyGUIForm.Width - $ButtonStop.Width - $ButtonPause.Width - 50), 6)
        $ButtonStop.Location =  [System.Drawing.Point]::new(($LegacyGUIForm.Width - $ButtonStop.Width - 40), 6)

        $MiningSummaryLabel.Width = $Variables.TextBoxSystemLog.Width = $LaunchedMinersDGV.Width = $EarningsChart.Width = $BalancesDGV.Width = $MinersPanel.Width = $MinersDGV.Width = $PoolsPanel.Width = $PoolsDGV.Width = $WorkersDGV.Width = $SwitchingDGV.Width = $WatchdogTimersDGV.Width = $TabControl.Width - 26

        If ($Config.BalancesTrackerPollInterval -gt 0 -and $BalancesDGV.Rows.Count -gt 0) { 
            $BalancesDGVHeight = ($BalancesDGV.Rows.Height | Measure-Object -Sum).Sum + $BalancesDGV.ColumnHeadersHeight
            If ($BalancesDGVHeight -gt $TabControl.Height / 2) { 
                $EarningsChart.Height = $TabControl.Height / 2
                $BalancesDGV.ScrollBars = "Vertical"
                $BalancesLabel.Location = [System.Drawing.Point]::new(8, ($TabControl.Height / 2 - 10))
            }
            Else { 
                $EarningsChart.Height = $TabControl.Height - $BalancesDGVHeight - 46
                $BalancesDGV.ScrollBars = "None"
                $BalancesLabel.Location = [System.Drawing.Point]::new(8, ($EarningsChart.Bottom - 20))
            }
        }
        Else { 
            $BalancesDGV.ScrollBars = "None"
            $BalancesLabel.Location = [System.Drawing.Point]::new(8, ($TabControl.Height - $BalancesLabel.Height - 50))
            $EarningsChart.Height = $BalancesLabel.Top + 36
        }
        $BalancesDGV.Location = [System.Drawing.Point]::new(10, $BalancesLabel.Bottom)
        $BalancesDGV.Height = $TabControl.Height - $BalancesLabel.Bottom - 48

        $LaunchedMinersDGV.Height = $LaunchedMinersDGV.RowTemplate.Height * $Variables.MinersBest_Combo.Count + $LaunchedMinersDGV.ColumnHeadersHeight
        If ($LaunchedMinersDGV.Height -gt $TabControl.Height / 2) { 
            $LaunchedMinersDGV.Height = $TabControl.Height / 2
            $LaunchedMinersDGV.ScrollBars = "Vertical"
        }
        Else { 
            $LaunchedMinersDGV.ScrollBars = "None"
        }

        $SystemLogLabel.Location = [System.Drawing.Point]::new(8, ($LaunchedMinersLabel.Height + $LaunchedMinersDGV.Height + 25))
        $Variables.TextBoxSystemLog.Location = [System.Drawing.Point]::new(8, ($LaunchedMinersLabel.Height + $LaunchedMinersDGV.Height + $SystemLogLabel.Height + 24))
        $Variables.TextBoxSystemLog.Height = ($TabControl.Height - $LaunchedMinersLabel.Height - $LaunchedMinersDGV.Height - $SystemLogLabel.Height - 68)
        If (-not $Variables.TextBoxSystemLog.SelectionLength) { 
            $Variables.TextBoxSystemLog.ScrollToCaret()
        }

        $MinersDGV.Height = $TabControl.Height - $MinersLabel.Height - $MinersPanel.Height - 61

        $PoolsDGV.Height = $TabControl.Height - $PoolsLabel.Height - $PoolsPanel.Height - 61

        $WorkersDGV.Height = $TabControl.Height - $WorkersLabel.Height - 58

        $SwitchingDGV.Height = $TabControl.Height - $SwitchingLogLabel.Height - $SwitchingLogClearButton.Height - 64

        $WatchdogTimersDGV.Height = $TabControl.Height - $WatchdogTimersLabel.Height - $WatchdogTimersRemoveButton.Height - 64

        $EditConfigLink.Location = [System.Drawing.Point]::new(10, ($LegacyGUIForm.Height - $EditConfigLink.Height - 58))
        $CopyrightLabel.Location = [System.Drawing.Point]::new(($TabControl.Width - $CopyrightLabel.Width + 6), ($LegacyGUIForm.Height - $EditConfigLink.Height - 58))
    }
    Catch { 
        Start-Sleep 0
    }
}

$Tooltip = New-Object System.Windows.Forms.ToolTip

$LegacyGUIForm = New-Object System.Windows.Forms.Form
#--- For High DPI, First Call SuspendLayout(),After that, Set AutoScaleDimensions, AutoScaleMode ---
# SuspendLayout() is Very important to correctly size and position all controls!
$LegacyGUIForm.SuspendLayout()
$LegacyGUIForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$LegacyGUIForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::DPI
$LegacyGUIForm.Icon = New-Object System.Drawing.Icon ("$($Variables.MainPath)\Data\NM.ICO")
$LegacyGUIForm.MaximizeBox = $true
$LegacyGUIForm.MinimumSize = [System.Drawing.Size]::new(800, 600) # best to keep under 800x600
$LegacyGUIForm.Text = $Variables.Branding.ProductLabel
$LegacyGUIForm.TopMost = $false

# Form Controls
$LegacyGUIControls = @()

$RunPage = New-Object System.Windows.Forms.TabPage
$RunPage.Text = "Run"
$RunPage.ToolTipText = "Information about the currently running system"
$EarningsPage = New-Object System.Windows.Forms.TabPage
$EarningsPage.Text = "Earnings"
$EarningsPage.ToolTipText = "Information about the calculated earnings / profit"
$MinersPage = New-Object System.Windows.Forms.TabPage
$MinersPage.Text = "Miners"
$MinersPage.ToolTipText = "Miner data collected in the last cycle"
$PoolsPage = New-Object System.Windows.Forms.TabPage
$PoolsPage.Text = "Pools"
$PoolsPage.ToolTipText = "Pool data collected in the last cycle"
$RigMonitorPage = New-Object System.Windows.Forms.TabPage
$RigMonitorPage.Text = "Rig Monitor"
$RigMonitorPage.ToolTipText = "Consolidated overview of all known mining rigs"
$SwitchingPage = New-Object System.Windows.Forms.TabPage
$SwitchingPage.Text = "Switching Log"
$SwitchingPage.ToolTipText = "List of the previously launched miners"
$WatchdogTimersPage = New-Object System.Windows.Forms.TabPage
$WatchdogTimersPage.Text = "Watchdog Timers"
$WatchdogTimersPage.ToolTipText = "List of all watchdog timers"

$MiningStatusLabel = New-Object System.Windows.Forms.Label
$MiningStatusLabel.AutoSize = $false
$MiningStatusLabel.BackColor = [System.Drawing.Color]::Transparent
$MiningStatusLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$MiningStatusLabel.ForeColor = [System.Drawing.Color]::Black
$MiningStatusLabel.Height = 20
$MiningStatusLabel.Location = [System.Drawing.Point]::new(6, 10)
$MiningStatusLabel.Text = "$($Variables.Branding.ProductLabel)"
$MiningStatusLabel.TextAlign = "MiddleLeft"
$MiningStatusLabel.Visible = $true
$MiningStatusLabel.Width = 360
$LegacyGUIControls += $MiningStatusLabel

$MiningSummaryLabel = New-Object System.Windows.Forms.Label
$MiningSummaryLabel.AutoSize = $false
$MiningSummaryLabel.BackColor = [System.Drawing.Color]::Transparent
$MiningSummaryLabel.BorderStyle = 'None'
$MiningSummaryLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MiningSummaryLabel.ForeColor = [System.Drawing.Color]::Black
$MiningSummaryLabel.Height = 80
$MiningSummaryLabel.Location = [System.Drawing.Point]::new(6, $MiningStatusLabel.Bottom)
$MiningSummaryLabel.Tag = ""
$MiningSummaryLabel.TextAlign = "MiddleLeft"
$MiningSummaryLabel.Visible = $true
$LegacyGUIControls += $MiningSummaryLabel
$Variables.TextBoxSystemLog
$Tooltip.SetToolTip($MiningSummaryLabel, "Color legend:`nBlack: Mining is idle`nGreen: Mining is profitable`nRed: Mining NOT profitable")

$ButtonStart = New-Object System.Windows.Forms.Button
$ButtonStart.Enabled = (-not $Config.Autostart)
$ButtonStart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonStart.Height = 24
$ButtonStart.Text = "Start mining"
$ButtonStart.Visible = $true
$ButtonStart.Width = 100
$ButtonStart.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace -eq "Idle") { 
            $Variables.NewMiningStatus = "Running"
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $ButtonStart
$Tooltip.SetToolTip($ButtonStart, "Start the mining process.")

$ButtonPause = New-Object System.Windows.Forms.Button
$ButtonPause.Enabled = $Config.Autostart
$ButtonPause.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonPause.Height = 24
$ButtonPause.Text = "Pause mining"
$ButtonPause.Visible = $true
$ButtonPause.Width = 100
$ButtonPause.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Paused") { 
            $Variables.NewMiningStatus = "Paused"
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $ButtonPause
$Tooltip.SetToolTip($ButtonPause, "Pause mining processes.`nBackground processes remain running.")

$ButtonStop = New-Object System.Windows.Forms.Button
$ButtonStop.Enabled = $Config.Autostart
$ButtonStop.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonStop.Height = 24
$ButtonStop.Text = "Stop mining"
$ButtonStop.Visible = $true
$ButtonStop.Width = 100
$ButtonStop.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Idle") { 
            $Variables.NewMiningStatus = "Idle"
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $ButtonStop
$Tooltip.SetToolTip($ButtonStop, "Stop mining processes.`nBackground processes will also stop.")

$EditConfigLink = New-Object System.Windows.Forms.LinkLabel
$EditConfigLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$EditConfigLink.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$EditConfigLink.LinkColor = [System.Drawing.Color]::Blue
$EditConfigLink.Location = [System.Drawing.Point]::new(10, ($LegacyGUIForm.Bottom - 26))
$EditConfigLink.TextAlign = "MiddleLeft"
$EditConfigLink.Size = New-Object System.Drawing.Size(380, 26)
$EditConfigLink.Add_Click({ If ($EditConfigLink.Tag -eq "WebGUI") { Start-Process "http://localhost:$($Variables.APIRunspace.APIPort)/configedit.html" } Else { Edit-File $Variables.ConfigFile } })
$LegacyGUIControls += $EditConfigLink
$Tooltip.SetToolTip($EditConfigLink, "Click to the edit configuration")

$CopyrightLabel = New-Object System.Windows.Forms.LinkLabel
$CopyrightLabel.ActiveLinkColor = [System.Drawing.Color]::Blue
$CopyrightLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CopyrightLabel.Location = [System.Drawing.Point]::new(10, ($LegacyGUIForm.Bottom - 26))
$CopyrightLabel.LinkColor = [System.Drawing.Color]::Blue
$CopyrightLabel.Size = New-Object System.Drawing.Size(380, 26)
$CopyrightLabel.Text = "Copyright (c) 2018-$((Get-Date).Year) Nemo, MrPlus && UselessGuru"
$CopyrightLabel.TextAlign = "MiddleRight"
$CopyrightLabel.Add_Click({ Start-Process "https://github.com/Minerx117/NemosMiner/blob/master/LICENSE" })
$LegacyGUIControls += $CopyrightLabel
$Tooltip.SetToolTip($CopyrightLabel, "Click to go to the $($Variables.Branding.ProductLabel) Github page")

# Miner context menu items
$ContextMenuStrip = New-Object System.Windows.Forms.ContextMenuStrip
$ContextMenuStrip.Enabled = $false
[System.Windows.Forms.ToolStripItem]$ContextMenuStripItem1 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$ContextMenuStrip.Items.Add($ContextMenuStripItem1)

[System.Windows.Forms.ToolStripItem]$ContextMenuStripItem2 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$ContextMenuStrip.Items.Add($ContextMenuStripItem2)

[System.Windows.Forms.ToolStripItem]$ContextMenuStripItem3 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$ContextMenuStrip.Items.Add($ContextMenuStripItem3)

[System.Windows.Forms.ToolStripItem]$ContextMenuStripItem4 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$ContextMenuStrip.Items.Add($ContextMenuStripItem4)

[System.Windows.Forms.ToolStripItem]$ContextMenuStripItem5 = New-Object System.Windows.Forms.ToolStripMenuItem
[Void]$ContextMenuStrip.Items.Add($ContextMenuStripItem5)

$ContextMenuStrip.Add_ItemClicked(
    { 
        $Data = @()

        If ($This.SourceControl.Name -match "LaunchedMinersDGV|MinersDGV") { 

            Switch ($_.ClickedItem.Text) { 
                "Re-Benchmark" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        If ($This.SourceControl.Name -eq "LaunchedMinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value
                            $SelectedMinerAlgorithms = @($_.Cells[7].Value -split " & ")
                        }
                        ElseIf ($This.SourceControl.Name -eq "MinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value
                            $SelectedMinerAlgorithms = @($_.Cells[8].Value -split " & ")
                        }
                        $Variables.Miners | Where-Object Name -EQ $SelectedMinerName | Where-Object { [String]$_.Algorithms -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                            If ($_.Earning -eq 0) { $_.Available = $true }
                            $_.Earning_Accuracy = [Double]::NaN
                            $_.Activated = 0 # To allow 3 attempts
                            $_.Disabled = $false
                            $_.Benchmark = $true
                            $_.Restart = $true
                            $Data += "$($_.Name) ($($_.Algorithms -join " & "))"
                            ForEach ($Worker in $_.Workers) { 
                                Remove-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                $Worker.Hashrate = [Double]::NaN
                            }
                            Remove-Variable Worker
                            # Also clear power usage
                            Remove-Stat -Name "$($_.Name)$(If ($_.Algorithms.Count -eq 1) { "_$($_.Algorithms[1])" })_PowerUsage"
                            $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN

                            $_.Reasons = @($_.Reasons | Where-Object { $_ -ne "Disabled by user" })
                            $_.Reasons = @($_.Reasons | Where-Object { $_ -ne "0 H/s Stat file" })
                            $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Unreal profit data *" })
                            If (-not $_.Reasons) { $_.Available = $true }
                            If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        Write-Message -Level Verbose "GUI: Re-benchmark triggered for $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                        $Data += "`n`n$(If ($Data.Count -eq 1) { "The miner" } Else { "$($Data.Count) miners" }) will re-benchmark."
                        Update-TabControl
                    }
                    Break
                }
                "Re-Measure Power Usage" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        If ($This.SourceControl.Name -eq "LaunchedMinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value
                            $SelectedMinerAlgorithms = @($_.Cells[7].Value -split " & ")
                        }
                        ElseIf ($This.SourceControl.Name -eq "MinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value
                            $SelectedMinerAlgorithms = @($_.Cells[8].Value -split " & ")
                        }
                        $Variables.Miners | Where-Object Name -EQ $SelectedMinerName | Where-Object { [String]$_.Algorithms -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                            If ($_.Earning -eq 0) { $_.Available = $true }
                            If ($Variables.CalculatePowerCost) { 
                                $_.MeasurePowerUsage = $true
                                $_.Activated = 0 # To allow 3 attempts
                            }
                            $_.PowerUsage = [Double]::NaN
                            $Stat_Name = "$($_.Name)$(If ($_.Algorithms.Count -eq 1) { "_$($_.Algorithms)" })"
                            $Data += "$Stat_Name`n"
                            Remove-Stat -Name "$($Stat_Name)_PowerUsage"
                            $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                            If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        Write-Message -Level Verbose "GUI: Re-measure power usage triggered for $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                        $Data += "`n`n$(If ($Data.Count -eq 1) { "The miner" } Else { "$($Data.Count) miners" }) will re-measure power usage."
                        Update-TabControl
                    }
                    Break
                }
                "Mark as failed" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        If ($This.SourceControl.Name -eq "LaunchedMinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value
                            $SelectedMinerAlgorithms = @($_.Cells[7].Value -split " & ")
                        }
                        ElseIf ($This.SourceControl.Name -eq "MinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value
                            $SelectedMinerAlgorithms = @($_.Cells[8].Value -split " & ")
                        }
                        $Variables.Miners | Where-Object Name -EQ $SelectedMinerName | Where-Object { [String]$_.Algorithms -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                            If ($Parameters.Value -le 0 -and $Parameters.Type -eq "Hashrate") { $_.Available = $false; $_.Disabled = $true }
                            $Data += "$($_.Name) ($($_.Algorithms -join " & "))"
                            ForEach ($Algorithm in $_.Algorithms) { 
                                $Stat_Name = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                                If ($Parameters.Value -eq 0) { # Miner failed
                                    Remove-Stat -Name $Stat_Name
                                    $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = $_.Earning_Accuracy = [Double]::NaN
                                    $_.Available = $false
                                    $_.Disabled = $false
                                    $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Disabled by user" })
                                    If ($_.Reasons -notcontains "0 H/s Stat file" ) { $_.Reasons.Add("0 H/s Stat file") }
                                    $_.Status = [MinerStatus]::Failed
                                    Set-Stat -Name $Stat_Name -Value $Parameters.Value -FaultDetection $false | Out-Null
                                }
                            }
                            Remove-Variable Algorithm
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        Write-Message -Level Verbose "GUI: Marked $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" }) as failed."
                        $Data += "`n`n$(If ($Data.Count -eq 1) { "The miner is" } Else { "$($Data.Count) miners are " }) marked as failed."
                        Update-TabControl
                    }
                    Break
                }
                "Disable" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        If ($This.SourceControl.Name -eq "LaunchedMinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value
                            $SelectedMinerAlgorithms = @($_.Cells[7].Value -split " & ")
                        }
                        ElseIf ($This.SourceControl.Name -eq "MinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value
                            $SelectedMinerAlgorithms = @($_.Cells[8].Value -split " & ")
                        }
                        $Variables.Miners | Where-Object Name -eq $SelectedMinerName | Where-Object { [String]$_.Algorithms -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                            $Data += "$($_.Name) ($($_.Algorithms -join " & "))"
                            ForEach ($Worker in $_.Workers) { 
                                Disable-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                $Worker.Hashrate = [Double]::NaN
                            }
                            Remove-Variable Worker
                            $_.Disabled = $true
                            $_.Reasons.Add("Disabled by user")
                            $_.Reasons = $_.Reasons | Sort-Object -Unique
                            $_.Available = $false
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        Write-Message -Level Verbose "GUI: Disabled $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                        $Data += "`n`n$(If ($Data.Count -eq 1) { "The miner is" } Else { "$($Data.Count) miners are " }) disabled."
                        Update-TabControl
                    }
                    Break
                }
                "Remove Watchdog Timer" { 
                    If ($This.SourceControl.Name -eq "MinersDGV") { 
                        $This.SourceControl.SelectedRows | ForEach-Object { 
                            $SelectedMinerName = $_.Cells[1].Value
                            $SelectedMinerAlgorithms = @($_.Cells[8].Value -split " & ")
                        }
                        If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -EQ $SelectedMinerName | Where-Object { $_.Algorithm -in $SelectedMinerAlgorithms })) {
                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })
                            ForEach ($WatchdogTimer in $WatchdogTimers) { 
                                $Data += "$($WatchdogTimer.MinerName) {$($WatchdogTimer.Algorithm -join ', ')}"
                                # Update miner
                                $Variables.Miners | Where-Object Name -EQ $electedMinerName | Where-Object { [String]$_.Algorithm -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                                    $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Miner suspended by watchdog *" })
                                    If (-not $_.Reasons) { $_.Available = $true }
                                }
                            }
                            Remove-Variable WatchdogTimer
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($WatchdogTimers) { 
                        $Data = $Data | Sort-Object -Unique
                        $Message = "$($Data.Count) miner $(If ($Data.Count -eq 1) { "watchdog timer" } Else { "watchdog timers" }) removed."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data += "`n`n$Message"
                    }
                    Else { 
                        $Data = "No matching watchdog timers found."
                    }
                    Break
                }
            }
        }
        ElseIf ($This.SourceControl.Name -match "PoolsDGV") { 
            Switch ($_.ClickedItem.Text) { 
                "Reset Pool Stat Data" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        $SelectedPoolName = $_.Cells[5].Value
                        $SelectedPoolAlgorithm = $_.Cells[0].Value
                        $Variables.Pools | Where-Object Name -EQ $SelectedPoolName | Where-Object Algorithm -EQ $SelectedPoolAlgorithm | ForEach-Object { 
                            $Stat_Name = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                            $Data += "$($Stat_Name)"
                            Remove-Stat -Name "$($Stat_Name)_Profit"
                            $_.Reasons = [String[]]@()
                            $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                            $_.Available = $true
                            $_.Disabled = $false
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Data = $Data | Sort-Object -Unique
                        $Message = "Pool stats for $($Data.Count) $(If ($Data.Count -eq 1) { "pool" } Else { "pools" }) reset."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data += "`n`n$Message"
                        Update-TabControl
                    }
                    Break
                }
                "Remove Watchdog Timer" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        $SelectedPoolName = $_.Cells[5].Value
                        $SelectedPoolAlgorithm = $_.Cells[0].Value
                        If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object PoolName -EQ $SelectedPoolName | Where-Object Algorithm -EQ $SelectedPoolAlgorithm )) {
                            # Remove Watchdog timers
                            $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $_ -notin $WatchdogTimers })
                            ForEach ($WatchdogTimer in $WatchdogTimers) { 
                                $Data += "$($WatchdogTimer.PoolName) {$($WatchdogTimer.Algorithm -join ', ')}"
                                # Update pools
                                $Variables.Pools | Where-Object Name -EQ $SelectedPoolName | Where-Object Algorithm -EQ $SelectedPoolAlgorithm | ForEach-Object { 
                                    $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Algorithm@Pool suspended by watchdog" })
                                    $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Pool suspended by watchdog*" })
                                    If (-not $_.Reasons) { $_.Available = $true }
                                }
                            }
                            Remove-Variable WatchdogTimer
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($WatchdogTimers) { 
                        $Data = $Data | Sort-Object -Unique
                        $Message = "$($Data.Count) miner $(If ($Data.Count -eq 1) { "watchdog timer" } Else { "watchdog timers" }) removed."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data += "`n`n$Message"
                    }
                    Else { 
                        $Data = "No matching watchdog timers found."
                    }
                    Break
                }
            }
        }

        If ($Data.Count -ge 1) { [Void][System.Windows.Forms.MessageBox]::Show([String]$Data, "$($Variables.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK) }
    }
)

# CheckBox Column for DataGridView
$CheckBoxColumn = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$CheckBoxColumn.HeaderText = ""
$CheckBoxColumn.Name = "CheckBoxColumn"
$CheckBoxColumn.ReadOnly = $false

# Run Page Controls
$RunPageControls = @()

$LaunchedMinersLabel = New-Object System.Windows.Forms.Label
$LaunchedMinersLabel.AutoSize = $false
$LaunchedMinersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LaunchedMinersLabel.Height = 20
$LaunchedMinersLabel.Location = [System.Drawing.Point]::new(6, 6)
$LaunchedMinersLabel.Width = 600
$RunPageControls += $LaunchedMinersLabel

$LaunchedMinersDGV = New-Object System.Windows.Forms.DataGridView
$LaunchedMinersDGV.AllowUserToAddRows = $false
$LaunchedMinersDGV.AllowUserToDeleteRows = $false
$LaunchedMinersDGV.AllowUserToOrderColumns = $true
$LaunchedMinersDGV.AllowUserToResizeColumns = $true
$LaunchedMinersDGV.AllowUserToResizeRows = $false
$LaunchedMinersDGV.AutoSizeColumnsMode = "Fill"
$LaunchedMinersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LaunchedMinersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LaunchedMinersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LaunchedMinersDGV.ContextMenuStrip = $ContextMenuStrip
$LaunchedMinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LaunchedMinersDGV.EnableHeadersVisualStyles = $false
$LaunchedMinersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LaunchedMinersDGV.Height = 0
$LaunchedMinersDGV.Location = [System.Drawing.Point]::new(6, ($LaunchedMinersLabel.Height + 6))
$LaunchedMinersDGV.Name = "LaunchedMinersDGV"
$LaunchedMinersDGV.ReadOnly = $true
$LaunchedMinersDGV.RowHeadersVisible = $false
$LaunchedMinersDGV.ScrollBars = "None"
$LaunchedMinersDGV.SelectionMode = "FullRowSelect"
$LaunchedMinersDGV.Add_MouseUP(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right) { 
            $ContextMenuStrip.Enabled = [Boolean]$This.SelectedRows
        }
    }
)
$LaunchedMinersDGV.Add_Sorted(
    { Colorize_Miners }
)
Set-DataGridViewDoubleBuffer -Grid $LaunchedMinersDGV -Enabled $true
$RunPageControls += $LaunchedMinersDGV

$SystemLogLabel = New-Object System.Windows.Forms.Label
$SystemLogLabel.AutoSize = $false
$SystemLogLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$SystemLogLabel.Height = 20
$SystemLogLabel.Text = "System Log"
$SystemLogLabel.Width = 600
$RunPageControls += $SystemLogLabel

$Variables.TextBoxSystemLog = New-Object System.Windows.Forms.TextBox
$Variables.TextBoxSystemLog.AutoSize = $true
$Variables.TextBoxSystemLog.Font = [System.Drawing.Font]::new("Consolas", 9)
$Variables.TextBoxSystemLog.MultiLine = $true
$Variables.TextBoxSystemLog.ReadOnly = $true
$Variables.TextBoxSystemLog.Scrollbars = "Vertical"
$Variables.TextBoxSystemLog.Text = ""
$Variables.TextBoxSystemLog.WordWrap = $true
$RunPageControls += $Variables.TextBoxSystemLog
$Tooltip.SetToolTip($Variables.TextBoxSystemLog, "These are the last 100 lines of the system log")

# Earnings Page Controls
$EarningsPageControls = @()

$EarningsChart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$EarningsChart.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240)
$EarningsChart.Location = [System.Drawing.Point]::new(-10, -5)
$EarningsPageControls += $EarningsChart

$BalancesLabel = New-Object System.Windows.Forms.Label
$BalancesLabel.AutoSize = $false
$BalancesLabel.BringToFront()
$BalancesLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$BalancesLabel.Height = 20
$BalancesLabel.Width = 600
$EarningsPageControls += $BalancesLabel

$BalancesDGV = New-Object System.Windows.Forms.DataGridView
$BalancesDGV.AllowUserToAddRows = $false
$BalancesDGV.AllowUserToDeleteRows = $false
$BalancesDGV.AllowUserToOrderColumns = $true
$BalancesDGV.AllowUserToResizeColumns = $true
$BalancesDGV.AllowUserToResizeRows = $false
$BalancesDGV.AutoSizeColumnsMode = "Fill"
$BalancesDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$BalancesDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$BalancesDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$BalancesDGV.EnableHeadersVisualStyles = $false
$BalancesDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$BalancesDGV.Height = 0
$BalancesDGV.Location = [System.Drawing.Point]::new(8, 187)
$BalancesDGV.Name = "EarningsDGV"
$BalancesDGV.ReadOnly = $true
$BalancesDGV.RowHeadersVisible = $false
$BalancesDGV.ScrollBars = "None"
Set-DataGridViewDoubleBuffer -Grid $BalancesDGV -Enabled $true
$EarningsPageControls += $BalancesDGV

# Miner page Controls
$MinersPageControls = @()

$RadioButtonMinersBest = New-Object System.Windows.Forms.RadioButton
$RadioButtonMinersBest.AutoSize = $false
$RadioButtonMinersBest.Checked = $true
$RadioButtonMinersBest.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RadioButtonMinersBest.Height = 22
$RadioButtonMinersBest.Location = [System.Drawing.Point]::new(0, 0)
$RadioButtonMinersBest.Text = "Best Miners"
$RadioButtonMinersBest.Width = 110
$RadioButtonMinersBest.Add_Click({ Update-TabControl })
$Tooltip.SetToolTip($RadioButtonMinersBest, "These are the best miners per algorithm and device.")

$RadioButtonMinersUnavailable = New-Object System.Windows.Forms.RadioButton
$RadioButtonMinersUnavailable.AutoSize = $false
$RadioButtonMinersUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RadioButtonMinersUnavailable.Height = 22
$RadioButtonMinersUnavailable.Location = [System.Drawing.Point]::new($RadioButtonMinersBest.Width, 0)
$RadioButtonMinersUnavailable.Text = "Unavailable Miners"
$RadioButtonMinersUnavailable.Width = 154
$RadioButtonMinersUnavailable.Add_Click({ Update-TabControl })
$Tooltip.SetToolTip($RadioButtonMinersUnavailable, "These are all unavailable miners.`nThe column 'Reason(s)' shows the filter criteria(s) that made the miner unavailable.")

$RadioButtonMiners = New-Object System.Windows.Forms.RadioButton
$RadioButtonMiners.AutoSize = $false
$RadioButtonMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RadioButtonMiners.Height = 22
$RadioButtonMiners.Location = [System.Drawing.Point]::new(($RadioButtonMinersBest.Width + $RadioButtonMinersUnavailable.Width), 0)
$RadioButtonMiners.Text = "All Miners"
$RadioButtonMiners.Width = 100
$RadioButtonMiners.Add_Click({ Update-TabControl })
$Tooltip.SetToolTip($RadioButtonMiners, "These are all miners.`nNote: NemosMiner will only create miners for algorithms that have at least one available pool.")

$MinersLabel = New-Object System.Windows.Forms.Label
$MinersLabel.AutoSize = $false
$MinersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MinersLabel.Height = 20
$MinersLabel.Location = [System.Drawing.Point]::new(6, 6)
$MinersLabel.Width = 600
$MinersPageControls += $MinersLabel

$MinersPanel = New-Object System.Windows.Forms.Panel
$MinersPanel.Height = 22
$MinersPanel.Location = [System.Drawing.Point]::new(8, ($MinersLabel.Height + 6))
$MinersPanel.Controls.Add($RadioButtonMiners)
$MinersPanel.Controls.Add($RadioButtonMinersUnavailable)
$MinersPanel.Controls.Add($RadioButtonMinersBest)
$MinersPageControls += $MinersPanel

$MinersDGV = New-Object System.Windows.Forms.DataGridView
$MinersDGV.AllowUserToAddRows = $false
$MinersDGV.AllowUserToOrderColumns = $true
$MinersDGV.AllowUserToResizeColumns = $true
$MinersDGV.AllowUserToResizeRows = $false
$MinersDGV.AutoSizeColumnsMode = "Fill"
$MinersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$MinersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$MinersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$MinersDGV.ColumnHeadersVisible = $true
$MinersDGV.ContextMenuStrip = $ContextMenuStrip
$MinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$MinersDGV.EnableHeadersVisualStyles = $false
$MinersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$MinersDGV.Location = [System.Drawing.Point]::new(6, ($MinersLabel.Height + $MinersPanel.Height + 10))
$MinersDGV.Name = "MinersDGV"
$MinersDGV.ReadOnly = $true
$MinersDGV.RowHeadersVisible = $false
$MinersDGV.SelectionMode = "FullRowSelect"
$MinersDGV.Add_MouseUP(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) { 
            $ContextMenuStrip.Enabled = [Boolean]$This.SelectedRows
        }
    }
)
$MinersDGV.Add_Sorted(
    { Colorize_Miners }
)
Set-DataGridViewDoubleBuffer -Grid $MinersDGV -Enabled $true
$MinersPageControls += $MinersDGV

# Pools page Controls
$PoolsPageControls = @()

$RadioButtonPoolsBest = New-Object System.Windows.Forms.RadioButton
$RadioButtonPoolsBest.AutoSize = $false
$RadioButtonPoolsBest.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RadioButtonPoolsBest.Height = 22
$RadioButtonPoolsBest.Location = [System.Drawing.Point]::new(0, 0)
$RadioButtonPoolsBest.Tag = ""
$RadioButtonPoolsBest.Text = "Best Pools"
$RadioButtonPoolsBest.Width = 100
$RadioButtonPoolsBest.Checked = $true
$RadioButtonPoolsBest.Add_Click({ Update-TabControl })
$Tooltip.SetToolTip($RadioButtonPoolsBest, "This is the list of the best paying pool for each algorithm.")

$RadioButtonPoolsUnavailable = New-Object System.Windows.Forms.RadioButton
$RadioButtonPoolsUnavailable.AutoSize = $false
$RadioButtonPoolsUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RadioButtonPoolsUnavailable.Height = 22
$RadioButtonPoolsUnavailable.Location = [System.Drawing.Point]::new($RadioButtonPoolsBest.Width, 0)
$RadioButtonPoolsUnavailable.Tag = ""
$RadioButtonPoolsUnavailable.Text = "Unavailable Pools"
$RadioButtonPoolsUnavailable.Width = 150
$RadioButtonPoolsUnavailable.Add_Click({ Update-TabControl })
$Tooltip.SetToolTip($RadioButtonPoolsUnavailable, "This is the pool data of all unavailable pools.`nThe column 'Reason(s)' shows the filter criteria(s) that made the pool unavailable.")

$RadioButtonPools = New-Object System.Windows.Forms.RadioButton
$RadioButtonPools.AutoSize = $false
$RadioButtonPools.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RadioButtonPools.Height = 22
$RadioButtonPools.Location = [System.Drawing.Point]::new(($RadioButtonPoolsBest.Width + $RadioButtonPoolsUnavailable.Width), 0)
$RadioButtonPools.Tag = ""
$RadioButtonPools.Text = "All Pools"
$RadioButtonPools.Width = 100
$RadioButtonPools.Add_Click({ Update-TabControl })
$Tooltip.SetToolTip($RadioButtonPools, "This is the pool data of all configured pools.")

$PoolsLabel = New-Object System.Windows.Forms.Label
$PoolsLabel.AutoSize = $false
$PoolsLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$PoolsLabel.Location = [System.Drawing.Point]::new(6, 6)
$PoolsLabel.Height = 20
$PoolsLabel.Width = 600
$PoolsPageControls += $PoolsLabel

$PoolsPanel = New-Object System.Windows.Forms.Panel
$PoolsPanel.Height = 22
$PoolsPanel.Location = [System.Drawing.Point]::new(8, ($PoolsLabel.Height + 6))
$PoolsPanel.Controls.Add($RadioButtonPools)
$PoolsPanel.Controls.Add($RadioButtonPoolsUnavailable)
$PoolsPanel.Controls.Add($RadioButtonPoolsBest)
$PoolsPageControls += $PoolsPanel

$PoolsDGV = New-Object System.Windows.Forms.DataGridView
$PoolsDGV.AllowUserToAddRows = $false
$PoolsDGV.AllowUserToOrderColumns = $true
$PoolsDGV.AllowUserToResizeColumns = $true
$PoolsDGV.AllowUserToResizeRows = $false
$PoolsDGV.AutoSizeColumnsMode = "Fill"
$PoolsDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$PoolsDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$PoolsDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$PoolsDGV.ColumnHeadersVisible = $true
$PoolsDGV.ContextMenuStrip = $ContextMenuStrip
$PoolsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$PoolsDGV.EnableHeadersVisualStyles = $false
$PoolsDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$PoolsDGV.Location = [System.Drawing.Point]::new(6, ($PoolsLabel.Height + $PoolsPanel.Height + 10))
$PoolsDGV.Name = "PoolsDGV"
$PoolsDGV.ReadOnly = $true
$PoolsDGV.RowHeadersVisible = $false
$PoolsDGV.SelectionMode = "FullRowSelect"
$PoolsDGV.Add_MouseUP(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) { 
            $ContextMenuStrip.Enabled = [Boolean]$This.SelectedRows
        }
    }
)
Set-DataGridViewDoubleBuffer -Grid $PoolsDGV -Enabled $true
$PoolsPageControls += $PoolsDGV

# Monitoring Page Controls
$RigMonitorPageControls = @()

$WorkersLabel = New-Object System.Windows.Forms.Label
$WorkersLabel.AutoSize = $false
$WorkersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$WorkersLabel.Height = 20
$WorkersLabel.Location = [System.Drawing.Point]::new(6, 6)
$WorkersLabel.Width = 600
$RigMonitorPageControls += $WorkersLabel

$WorkersDGV = New-Object System.Windows.Forms.DataGridView
$WorkersDGV.AllowUserToAddRows = $false
$WorkersDGV.AllowUserToOrderColumns = $true
$WorkersDGV.AllowUserToResizeColumns = $true
$WorkersDGV.AllowUserToResizeRows = $false
$WorkersDGV.AutoSizeColumnsMode = "Fill"
$WorkersDGV.AutoSizeRowsMode = "AllCells"
$WorkersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$WorkersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$WorkersDGV.ColumnHeadersVisible = $true
$WorkersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$WorkersDGV.DefaultCellStyle.WrapMode = "True"
$WorkersDGV.EnableHeadersVisualStyles = $false
$WorkersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$WorkersDGV.Location = [System.Drawing.Point]::new(6, ($WorkersLabel.Height + 8))
$WorkersDGV.ReadOnly = $true
$WorkersDGV.RowHeadersVisible = $false
$WorkersDGV.Add_Sorted(
    { Colorize_Workers }
)
Set-DataGridViewDoubleBuffer -Grid $WorkersDGV -Enabled $true
$RigMonitorPageControls += $WorkersDGV

# Switching Page Controls
$SwitchingPageControls = @()

$SwitchingLogLabel = New-Object System.Windows.Forms.Label
$SwitchingLogLabel.AutoSize = $false
$SwitchingLogLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$SwitchingLogLabel.Height = 20
$SwitchingLogLabel.Location = [System.Drawing.Point]::new(6, 6)
$SwitchingLogLabel.Width = 600
$SwitchingPageControls += $SwitchingLogLabel

$SwitchingLogClearButton = New-Object System.Windows.Forms.Button
$SwitchingLogClearButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$SwitchingLogClearButton.Height = 24
$SwitchingLogClearButton.Location = [System.Drawing.Point]::new(6, ($SwitchingLogLabel.Height + 8))
$SwitchingLogClearButton.Text = "Clear Switching Log"
$SwitchingLogClearButton.Visible = $true
$SwitchingLogClearButton.Width = 160
$SwitchingLogClearButton.Add_Click(
    { 
        Get-ChildItem -Path ".\Logs\switchinglog.csv" -File | Remove-Item -Force
        $SwitchingDGV.DataSource = $null
        $Data = "Switching log '.\Logs\switchinglog.csv' cleared."
        Write-Message -Level Verbose "GUI: $Data"
        $SwitchingLogClearButton.Enabled = $false
        [Void][System.Windows.Forms.MessageBox]::Show($Data, "$($Variables.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK)
    }
)
$SwitchingPageControls += $SwitchingLogClearButton
$Tooltip.SetToolTip($SwitchingLogClearButton, "This will clear the switching log '.\Logs\switchinglog.csv'")

$CheckShowSwitchingCPU = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingCPU.AutoSize = $false
$CheckShowSwitchingCPU.Checked = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "CPU#*")
$CheckShowSwitchingCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingCPU.Height = 20
$CheckShowSwitchingCPU.Location = [System.Drawing.Point]::new(($SwitchingLogClearButton.Width + 40), ($SwitchingLogLabel.Height + 10))
$CheckShowSwitchingCPU.Tag = "CPU"
$CheckShowSwitchingCPU.Text = "CPU"
$CheckShowSwitchingCPU.Width = 70
$SwitchingPageControls += $CheckShowSwitchingCPU
$CheckShowSwitchingCPU | ForEach-Object { $_.Add_Click({ CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingAMD = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingAMD.AutoSize = $false
$CheckShowSwitchingAMD.Checked = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "GPU#*" | Where-Object Vendor -EQ "AMD")
$CheckShowSwitchingAMD.Height = 20
$CheckShowSwitchingAMD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingAMD.Location = [System.Drawing.Point]::new(($SwitchingLogClearButton.Width + 40 + $CheckShowSwitchingCPU.Width), ($SwitchingLogLabel.Height + 10))
$CheckShowSwitchingAMD.Tag = "AMD"
$CheckShowSwitchingAMD.Text = "AMD"
$CheckShowSwitchingAMD.Width = 70
$SwitchingPageControls += $CheckShowSwitchingAMD
$CheckShowSwitchingAMD | ForEach-Object { $_.Add_Click({ CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingINTEL = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingINTEL.AutoSize = $false
$CheckShowSwitchingINTEL.Checked = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "GPU#*" | Where-Object Vendor -EQ "INTEL")
$CheckShowSwitchingINTEL.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingINTEL.Height = 20
$CheckShowSwitchingINTEL.Location = [System.Drawing.Point]::new(($SwitchingLogClearButton.Width + 40 + $CheckShowSwitchingCPU.Width + $CheckShowSwitchingAMD.Width), ($SwitchingLogLabel.Height + 10))
$CheckShowSwitchingINTEL.Tag = "INTEL"
$CheckShowSwitchingINTEL.Text = "INTEL"
$CheckShowSwitchingINTEL.Width = 77
$SwitchingPageControls += $CheckShowSwitchingINTEL
$CheckShowSwitchingINTEL | ForEach-Object { $_.Add_Click({ CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingNVIDIA = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingNVIDIA.AutoSize = $false
$CheckShowSwitchingNVIDIA.Checked = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "GPU#*" | Where-Object Vendor -EQ "NVIDIA")
$CheckShowSwitchingNVIDIA.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingNVIDIA.Height = 20
$CheckShowSwitchingNVIDIA.Location = [System.Drawing.Point]::new(($SwitchingLogClearButton.Width + 40 + $CheckShowSwitchingCPU.Width + $CheckShowSwitchingAMD.Width + $CheckShowSwitchingINTEL.Width), ($SwitchingLogLabel.Height + 10))
$CheckShowSwitchingNVIDIA.Tag = "NVIDIA"
$CheckShowSwitchingNVIDIA.Text = "NVIDIA"
$CheckShowSwitchingNVIDIA.Width = 80
$SwitchingPageControls += $CheckShowSwitchingNVIDIA
$CheckShowSwitchingNVIDIA | ForEach-Object { $_.Add_Click({ CheckBoxSwitching_Click($this) }) }

$SwitchingDGV = New-Object System.Windows.Forms.DataGridView
$SwitchingDGV.AllowUserToAddRows = $false
$SwitchingDGV.AllowUserToOrderColumns = $true
$SwitchingDGV.AllowUserToResizeColumns = $true
$SwitchingDGV.AllowUserToResizeRows = $false
$SwitchingDGV.AutoSizeColumnsMode = "Fill"
$SwitchingDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$SwitchingDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$SwitchingDGV.ColumnHeadersVisible = $true
$SwitchingDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$SwitchingDGV.EnableHeadersVisualStyles = $false
$SwitchingDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$SwitchingDGV.Location = [System.Drawing.Point]::new(6, ($SwitchingLogLabel.Height + $SwitchingLogClearButton.Height + 12))
$SwitchingDGV.Name = "SwitchingDGV"
$SwitchingDGV.ReadOnly = $true
$SwitchingDGV.RowHeadersVisible = $false
$SwitchingDGV.Add_Sorted(
    { Colorize_SwitchingLog }
)
Set-DataGridViewDoubleBuffer -Grid $SwitchingDGV -Enabled $true
$SwitchingPageControls += $SwitchingDGV

# Watchdog Page Controls
$WatchdogTimersPageControls = @()

$WatchdogTimersLabel = New-Object System.Windows.Forms.Label
$WatchdogTimersLabel.AutoSize = $false
$WatchdogTimersLabel.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$WatchdogTimersLabel.Height = 20
$WatchdogTimersLabel.Location = [System.Drawing.Point]::new(6, 6)
$WatchdogTimersLabel.Width = 600
$WatchdogTimersPageControls += $WatchdogTimersLabel

$WatchdogTimersRemoveButton = New-Object System.Windows.Forms.Button
$WatchdogTimersRemoveButton.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$WatchdogTimersRemoveButton.Height = 24
$WatchdogTimersRemoveButton.Location = [System.Drawing.Point]::new(6, ($WatchdogTimersLabel.Height + 8))
$WatchdogTimersRemoveButton.Text = "Remove all Watchdog Timers"
$WatchdogTimersRemoveButton.Visible = $true
$WatchdogTimersRemoveButton.Width = 220
$WatchdogTimersRemoveButton.Add_Click(
    { 
        $Variables.WatchDogTimers = @()
        $WatchdogTimersDGV.DataSource = $null
        $Variables.Miners | ForEach-Object { $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Miner suspended by watchdog *" }); $_ } | Where-Object { -not $_.Reasons } | ForEach-Object { $_.Available = $true }
        $Variables.Pools | ForEach-Object { $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "*Pool suspended by watchdog" }); $_ } | Where-Object { -not $_.Reasons } | ForEach-Object { $_.Available = $true }
        Write-Message -Level Verbose "GUI: All watchdog timers reset."
        $WatchdogTimersRemoveButton.Enabled = $false
        [Void][System.Windows.Forms.MessageBox]::Show("Watchdog timers will be recreated in next cycle.", "$($Variables.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK)
    }
)
$WatchdogTimersPageControls += $WatchdogTimersRemoveButton
$Tooltip.SetToolTip($WatchdogTimersRemoveButton, "This will remove all watchdog timers.`nWatchdog timers will be recreated in next cycle.")

$WatchdogTimersDGV = New-Object System.Windows.Forms.DataGridView
$WatchdogTimersDGV.AllowUserToAddRows = $false
$WatchdogTimersDGV.AllowUserToOrderColumns = $true
$WatchdogTimersDGV.AllowUserToResizeColumns = $true
$WatchdogTimersDGV.AllowUserToResizeRows = $false
$WatchdogTimersDGV.AutoSizeColumnsMode = "Fill"
$WatchdogTimersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$WatchdogTimersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$WatchdogTimersDGV.ColumnHeadersVisible = $true
$WatchdogTimersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$WatchdogTimersDGV.EnableHeadersVisualStyles = $false
$WatchdogTimersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$WatchdogTimersDGV.Location = [System.Drawing.Point]::new(6, ($WatchdogTimersLabel.Height + $WatchdogTimersRemoveButton.Height + 12))
$WatchdogTimersDGV.Name = "WatchdogTimersDGV"
$WatchdogTimersDGV.ReadOnly = $true
$WatchdogTimersDGV.RowHeadersVisible = $false
Set-DataGridViewDoubleBuffer -Grid $WatchdogTimersDGV -Enabled $true
$WatchdogTimersPageControls += $WatchdogTimersDGV

$LegacyGUIForm.Controls.AddRange(@($LegacyGUIControls))
$RunPage.Controls.AddRange(@($RunPageControls))
$EarningsPage.Controls.AddRange(@($EarningsPageControls))
$MinersPage.Controls.AddRange(@($MinersPageControls))
$PoolsPage.Controls.AddRange(@($PoolsPageControls))
$RigMonitorPage.Controls.AddRange(@($RigMonitorPageControls))
$SwitchingPage.Controls.AddRange(@($SwitchingPageControls))
$WatchdogTimersPage.Controls.AddRange(@($WatchdogTimersPageControls))

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$TabControl.Location = [System.Drawing.Point]::new(6, $MiningSummaryLabel.Bottom)
$TabControl.Name = "TabControl"
$TabControl.ShowToolTips = $true
$TabControl.Height = 0
$TabControl.Width = 0
$TabControl.Controls.AddRange(@($RunPage, $EarningsPage, $MinersPage, $PoolsPage, $RigMonitorPage, $SwitchingPage, $WatchdogTimersPage))
$TabControl.Add_Click({ Update-TabControl })

$LegacyGUIForm.Controls.Add($TabControl)
$LegacyGUIForm.ResumeLayout()
$LegacyGUIForm.Add_Load(
    { 
         If (Test-Path -Path ".\Config\WindowSettings.json" -PathType Leaf) { 
            $WindowSettings = Get-Content -Path ".\Config\WindowSettings.json" | ConvertFrom-Json -AsHashtable
            # Restore window size
            If ($WindowSettings.Width -gt $LegacyGUIForm.MinimumSize.Width) { $LegacyGUIForm.Width = $WindowSettings.Width }
            If ($WindowSettings.Height -gt $LegacyGUIForm.MinimumSize.Height) { $LegacyGUIForm.Height = $WindowSettings.Height }
            If ($WindowSettings.Top -gt 0) { $LegacyGUIForm.Top = $WindowSettings.Top }
            If ($WindowSettings.Left -gt 0) { $LegacyGUIForm.Left = $WindowSettings.Left }
        }

        $Global:LegacyGUIFormWindowState = If ($Config.LegacyGUIStartMinimized) { [System.Windows.Forms.FormWindowState]::Minimized } Else { [System.Windows.Forms.FormWindowState]::Normal }
        $LegacyGUIForm.Add_ResizeEnd({ Form_Resize })
        $LegacyGUIForm.Add_SizeChanged(
            { 
                If ($this.WindowState -ne $Global:LegacyGUIFormWindowState) { 
                    $Global:LegacyGUIFormWindowState = $this.WindowState
                    Form_Resize
                }
            }
        )
        Form_Resize

        $TimerUI = New-Object System.Windows.Forms.Timer
        $TimerUI.Interval = 100
        $TimerUI.Add_Tick(
            { 
                If ($Variables.APIRunspace) { 
                    If ($EditConfigLink.Tag -ne "WebGUI") { 
                        $EditConfigLink.Tag = "WebGUI"
                        $EditConfigLink.Text = "Edit configuration in the Web GUI"
                    }
                }
                ElseIf ($EditConfigLink.Tag -ne "Edit-File") { 
                    $EditConfigLink.Tag = "Edit-File"
                    $EditConfigLink.Text = "Edit configuration file '$($Variables.ConfigFile)' in notepad"
                }
                [Void](MainLoop)
            }
        )
        $TimerUI.Start()
    }
)

$LegacyGUIForm.Add_FormClosing(
    {
        If ($Config.LegacyGUI) { 
            $MsgBoxInput = [System.Windows.Forms.MessageBox]::Show("Do you want to shut down $($Variables.Branding.ProductLabel)?", "$($Variables.Branding.ProductLabel)", [System.Windows.Forms.MessageBoxButtons]::YesNo)

            If ($MsgBoxInput -eq "Yes") {
                Write-Message -Level Info "Shutting down $($Variables.Branding.ProductLabel)..."
                $Variables.NewMiningStatus = "Idle"

                Stop-Mining
                Stop-IdleDetection
                Stop-Brain
                Stop-BalancesTracker

                If ($LegacyGUIForm.DesktopBounds.Width -ge 0) { 
                    # Save window settings
                    $LegacyGUIForm.DesktopBounds | ConvertTo-Json | Out-File -FilePath ".\Config\WindowSettings.json" -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                }

                Write-Message -Level Info "$($Variables.Branding.ProductLabel) has shut down."
                Stop-Process $PID -Force
            }
            Else { 
                $_.Cancel = $true
            }
        }
    }
)