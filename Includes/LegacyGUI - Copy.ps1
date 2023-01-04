<#
Copyright (c) 2018-2022 Nemo, MrPlus & UselessGuru

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
Version:        4.2.3.1
Version date:   04 January 2023
#>

[Void] [System.Reflection.Assembly]::LoadWithPartialName(“System.Windows.Forms”)
[Void] [System.Reflection.Assembly]::LoadWithPartialName(“System.Drawing”)

$LegacyGUIForm = New-Object System.Windows.Forms.Form
$LegacyGUIForm.Text = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version)"

$LegacyGUIForm.Icon = New-Object System.Drawing.Icon ("..\Data\NM.ICO")
$LegacyGUIForm.MinimumSize = [System.Drawing.Size]::new(756, 501) # best to keep under 800x600
$LegacyGUIForm.Text = $Variables.Branding.ProductLabel
$LegacyGUIForm.MaximizeBox = $true
$LegacyGUIForm.TopMost = $false
$LegacyGUIForm.FormWindowState

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

$ButtonStart = New-Object System.Windows.Forms.Button
$ButtonStart.Text = "Start mining"
$ButtonStart.Width = 100
$ButtonStart.Height = 30
$ButtonStart.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonStart.Visible = $true
$ButtonStart.Enabled = (-not $Config.Autostart)
$ButtonStart.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Running" -or $Variables.IdleRunspace -eq "Idle") { 
            $Variables.NewMiningStatus = "Running"
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $ButtonStart

$ButtonPause = New-Object System.Windows.Forms.Button
$ButtonPause.Text = "Pause mining"
$ButtonPause.Width = 100
$ButtonPause.Height = 30
$ButtonPause.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonPause.Visible = $true
$ButtonPause.Enabled = $Config.Autostart
$ButtonPause.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Paused") { 
            $Variables.NewMiningStatus = "Paused"
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $ButtonPause

$ButtonStop = New-Object System.Windows.Forms.Button
$ButtonStop.Text = "Stop mining"
$ButtonStop.Width = 100
$ButtonStop.Height = 30
$ButtonStop.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$ButtonStop.Visible = $true
$ButtonStop.Enabled = $Config.Autostart
$ButtonStop.Add_Click(
    { 
        If ($Variables.NewMiningStatus -ne "Idle") { 
            $Variables.NewMiningStatus = "Idle"
            $Variables.RestartCycle = $true
        }
    }
)
$LegacyGUIControls += $ButtonStop

$LabelCopyright = New-Object System.Windows.Forms.LinkLabel
$LabelCopyright.Size = New-Object System.Drawing.Size(350, 20)
$LabelCopyright.LinkColor = [System.Drawing.Color]::Blue
$LabelCopyright.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 9)
$LabelCopyright.ActiveLinkColor = [System.Drawing.Color]::Blue
$LabelCopyright.TextAlign = "MiddleRight"
$LabelCopyright.Text = "Copyright (c) 2018-$((Get-Date).Year) Nemo, MrPlus && UselessGuru"
$LabelCopyright.Add_Click({ Start-Process "https://github.com/Minerx117/NemosMiner/blob/master/LICENSE" })
$LegacyGUIControls += $LabelCopyright

$EditConfigLink = New-Object System.Windows.Forms.LinkLabel
$EditConfigLink.Size = New-Object System.Drawing.Size(150, 20)
$EditConfigLink.LinkColor = [System.Drawing.Color]::Blue
$EditConfigLink.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$EditConfigLink.ActiveLinkColor = [System.Drawing.Color]::Blue
$EditConfigLink.TextAlign = "MiddleLeft"
$EditConfigLink.Add_Click({ If ($EditConfigLink.Tag -eq "WebGUI") { Start-Process "http://localhost:$($Variables.APIRunspace.APIPort)/configedit.html" } Else { Edit-File $Variables.ConfigFile } })
$LegacyGUIControls += $EditConfigLink

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = [System.Drawing.Point]::new(10, 91)
$TabControl.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$TabControl.Name = "TabControl"
$TabControl.ShowToolTips = $true
$TabControl.Controls.AddRange(@($RunPage, $EarningsPage, $MinersPage, $PoolsPage, $RigMonitorPage, $SwitchingPage))
$TabControl.Add_SelectedIndexChanged({ Update-TabControl })
$LegacyGUIForm.Controls.Add($TabControl)

$LabelMiningStatus = New-Object System.Windows.Forms.Label
$LabelMiningStatus.AutoSize = $false
$LabelMiningStatus.Height = 30
$LabelMiningStatus.Location = [System.Drawing.Point]::new(10, 4)
$LabelMiningStatus.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 12)
$LabelMiningStatus.TextAlign = "MiddleLeft"
$LabelMiningStatus.ForeColor = [System.Drawing.Color]::Green
$LabelMiningStatus.BackColor = [System.Drawing.Color]::Transparent
$LabelMiningStatus.Visible = $true
$LabelMiningStatus.Text = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version)"
$LegacyGUIControls += $LabelMiningStatus

$TextBoxSummary = New-Object System.Windows.Forms.TextBox
$TextBoxSummary.Tag = ""
$TextBoxSummary.Lines = ""
$TextBoxSummary.AutoSize = $false
$TextBoxSummary.Height = 47
$TextBoxSummary.Location = [System.Drawing.Point]::new(12, 36)
$TextBoxSummary.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$TextBoxSummary.TextAlign = "MiddleLeft"
$TextBoxSummary.BorderStyle = 'None'
$TextBoxSummary.BackColor = [System.Drawing.SystemColors]::Control
$TextBoxSummary.Visible = $true
$TextBoxSummary.ReadOnly = $true
$TextBoxSummary.MultiLine = $true
$TextBoxSummary.ForeColor = [System.Drawing.Color]::Green
$TextBoxSummary.BackColor = [System.Drawing.Color]::Transparent
$LegacyGUIControls += $TextBoxSummary

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

# CheckBox Column for DataGridView
$CheckBoxColumn = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$CheckBoxColumn.HeaderText = ""
$CheckBoxColumn.ReadOnly = $false
$CheckBoxColumn.Name = "CheckBoxColumn"

# Run Page Controls
$RunPageControls = @()

$LabelLaunchedMiners = New-Object System.Windows.Forms.Label
$LabelLaunchedMiners.AutoSize = $false
$LabelLaunchedMiners.Width = 450
$LabelLaunchedMiners.Height = 16
$LabelLaunchedMiners.Location = [System.Drawing.Point]::new(2, 4)
$LabelLaunchedMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RunPageControls += $LabelLaunchedMiners

$LaunchedMinersDGV = New-Object System.Windows.Forms.DataGridView
$LaunchedMinersDGV.Name = "LaunchedMinersDGV"
$LaunchedMinersDGV.Location = [System.Drawing.Point]::new(2, 28)
$LaunchedMinersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$LaunchedMinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$LaunchedMinersDGV.AutoSizeColumnsMode = "Fill"
$LaunchedMinersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$LaunchedMinersDGV.RowHeadersVisible = $false
$LaunchedMinersDGV.AllowUserToAddRows = $false
$LaunchedMinersDGV.AllowUserToDeleteRows = $false
$LaunchedMinersDGV.AllowUserToOrderColumns = $true
$LaunchedMinersDGV.AllowUserToResizeColumns = $true
$LaunchedMinersDGV.AllowUserToResizeRows = $false
$LaunchedMinersDGV.ScrollBars = "None"
$LaunchedMinersDGV.ReadOnly = $true
$LaunchedMinersDGV.EnableHeadersVisualStyles = $false
$LaunchedMinersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$LaunchedMinersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$LaunchedMinersDGV.SelectionMode = "FullRowSelect"
$LaunchedMinersDGV.ContextMenuStrip = $ContextMenuStrip
$LaunchedMinersDGV.Add_MouseUP(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) { 
            $ContextMenuStrip.Enabled = [Boolean]$This.SelectedRows
            $ContextMenuStripItem5.Visible = $false
            $ContextMenuStripItem1.Text = "Re-Benchmark"
            $ContextMenuStripItem2.Text = "Re-measure power usage"
            $ContextMenuStripItem3.Text = "Mark as failed";
            $ContextMenuStripItem4.Text = "Disable"
        }
    }
)
$RunPageControls += $LaunchedMinersDGV

$LabelSystemLog = New-Object System.Windows.Forms.Label
$LabelSystemLog.AutoSize = $false
$LabelSystemLog.Width = 450
$LabelSystemLog.Height = 16
# $LabelSystemLog.Location = [System.Drawing.Point]::new(2, ($LabelLaunchedMiners.Height + $LaunchedMinersDGV.Height + 22))
$LabelSystemLog.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$LabelSystemLog.Text = "System Log"
$RunPageControls += $LabelSystemLog


$Variables.TextBoxSystemLog = New-Object System.Windows.Forms.TextBox
$Variables.TextBoxSystemLog.MultiLine = $true
$Variables.TextBoxSystemLog.Scrollbars = "Vertical"
$Variables.TextBoxSystemLog.WordWrap = $true
$Variables.TextBoxSystemLog.Text = ""
$Variables.TextBoxSystemLog.AutoSize = $true
$Variables.TextBoxSystemLog.ReadOnly = $true
$Variables.TextBoxSystemLog.MultiLine = $true
# $Variables.TextBoxSystemLog.Location = [System.Drawing.Point]::new(2, ($LabelLaunchedMiners.Height + $LaunchedMinersDGV.Height + $LabelSystemLog.Height + 28))
# $Variables.TextBoxSystemLog.Height = ($TabControl.Height - $LabelLaunchedMiners.Height - $LaunchedMinersDGV.Height - $LabelSystemLog.Height - 59)
$Variables.TextBoxSystemLog.Font = [System.Drawing.Font]::new("Consolas", 10)
$RunPageControls += $Variables.TextBoxSystemLog

# Earnings Page Controls
$EarningsPageControls = @()

$EarningsChart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$EarningsChart.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240) #"#F0F0F0"
$EarningsChart.Location = [System.Drawing.Point]::new(-10, -5) 
$EarningsPageControls += $EarningsChart

$LabelEarnings = New-Object System.Windows.Forms.Label
$LabelEarnings.AutoSize = $false
$LabelEarnings.Width = 450
$LabelEarnings.Height = 16
$LabelEarnings.Location = [System.Drawing.Point]::new(2, 146)
$LabelEarnings.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$EarningsPageControls += $LabelEarnings

$EarningsDGV = New-Object System.Windows.Forms.DataGridView
$EarningsDGV.Name = "EarningsDGV"
$EarningsDGV.Location = [System.Drawing.Point]::new(2, 167)
$EarningsDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$EarningsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EarningsDGV.AutoSizeColumnsMode = "Fill"
$EarningsDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$EarningsDGV.RowHeadersVisible = $false
$EarningsDGV.AllowUserToAddRows = $false
$EarningsDGV.AllowUserToDeleteRows = $false
$EarningsDGV.AllowUserToOrderColumns = $true
$EarningsDGV.AllowUserToResizeColumns = $true
$EarningsDGV.AllowUserToResizeRows = $false
$EarningsDGV.ScrollBars = "None"
$EarningsDGV.ReadOnly = $true
$EarningsDGV.EnableHeadersVisualStyles = $false
$EarningsDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$EarningsDGV.Add_DataSourceChanged({ Form_Resize })
$EarningsPageControls += $EarningsDGV

# Miner page Controls
$MinersPageControls = @()

$RadioButtonMinersMostProfitable = New-Object System.Windows.Forms.RadioButton
$RadioButtonMinersMostProfitable.Tag = "/miners/best"
$RadioButtonMinersMostProfitable.Text = "Most Profitable Miners"
$RadioButtonMinersMostProfitable.AutoSize = $false
$RadioButtonMinersMostProfitable.Width = 140
$RadioButtonMinersMostProfitable.Height = 20
$RadioButtonMinersMostProfitable.Location = [System.Drawing.Point]::new(3, 4)
$RadioButtonMinersMostProfitable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 8)
$RadioButtonMinersMostProfitable.Checked = $true
$RadioButtonMinersMostProfitable.Add_Click({ Update-TabControl })

$RadioButtonMinersUnavailable = New-Object System.Windows.Forms.RadioButton
$RadioButtonMinersUnavailable.Tag = "/miners/unavailable"
$RadioButtonMinersUnavailable.Text = "Unavailable Miners"
$RadioButtonMinersUnavailable.AutoSize = $false
$RadioButtonMinersUnavailable.Width = 140
$RadioButtonMinersUnavailable.Height = 20
$RadioButtonMinersUnavailable.Location = [System.Drawing.Point]::new(150, 4)
$RadioButtonMinersUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 8)
$RadioButtonMinersUnavailable.Add_Click({ Update-TabControl })

$RadioButtonMiners = New-Object System.Windows.Forms.RadioButton
$RadioButtonMiners.Tag = "/Miners"
$RadioButtonMiners.Text = "All Miners"
$RadioButtonMiners.AutoSize = $false
$RadioButtonMiners.Width = 100
$RadioButtonMiners.Height = 20
$RadioButtonMiners.Location = [System.Drawing.Point]::new(280, 4)
$RadioButtonMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 8)
$RadioButtonMiners.Add_Click({ Update-TabControl })

$LabelMiners = New-Object System.Windows.Forms.Label
$LabelMiners.AutoSize = $false
$LabelMiners.Width = 450
$LabelMiners.Height = 18
$LabelMiners.Location = [System.Drawing.Point]::new(2, 4)
$LabelMiners.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$MinersPageControls += $LabelMiners

$MinersPanel = New-Object System.Windows.Forms.Panel
$MinersPanel.Height = 24
$MinersPanel.Location = [System.Drawing.Point]::new(0, 22)
$MinersPanel.Controls.Add($RadioButtonMiners)
$MinersPanel.Controls.Add($RadioButtonMinersUnavailable)
$MinersPanel.Controls.Add($RadioButtonMinersMostProfitable)
$MinersPageControls += $MinersPanel

$MinersDGV = New-Object System.Windows.Forms.DataGridView
$MinersDGV.Name = "MinersDGV"
$MinersDGV.Location = [System.Drawing.Point]::new(2, 50)
$MinersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$MinersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$MinersDGV.AutoSizeColumnsMode = "Fill"
$MinersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$MinersDGV.RowHeadersVisible = $false
$MinersDGV.ColumnHeadersVisible = $true
$MinersDGV.AllowUserToAddRows = $false
$MinersDGV.AllowUserToOrderColumns = $true
$MinersDGV.AllowUserToResizeColumns = $true
$MinersDGV.AllowUserToResizeRows = $false
$MinersDGV.ReadOnly = $true
$MinersDGV.EnableHeadersVisualStyles = $false
$MinersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$MinersDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$MinersDGV.SelectionMode = "FullRowSelect"
$MinersDGV.ContextMenuStrip = $ContextMenuStrip
$MinersDGV.Add_MouseUP(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) { 
            $ContextMenuStrip.Enabled = [Boolean]$This.SelectedRows
        }
    }
)
$MinersPageControls += $MinersDGV

# Pools page Controls
$PoolsPageControls = @()

$RadioButtonPoolsBest = New-Object System.Windows.Forms.RadioButton
$RadioButtonPoolsBest.Tag = ""
$RadioButtonPoolsBest.Text = "Best Pools"
$RadioButtonPoolsBest.AutoSize = $false
$RadioButtonPoolsBest.Width = 140
$RadioButtonPoolsBest.Height = 20
$RadioButtonPoolsBest.Location = [System.Drawing.Point]::new(3, 4)
$RadioButtonPoolsBest.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 8)
$RadioButtonPoolsBest.Checked = $true
$RadioButtonPoolsBest.Add_Click({ Update-TabControl })

$RadioButtonPoolsUnavailable = New-Object System.Windows.Forms.RadioButton
$RadioButtonPoolsUnavailable.Tag = ""
$RadioButtonPoolsUnavailable.Text = "Unavailable Pools"
$RadioButtonPoolsUnavailable.AutoSize = $false
$RadioButtonPoolsUnavailable.Width = 140
$RadioButtonPoolsUnavailable.Height = 20
$RadioButtonPoolsUnavailable.Location = [System.Drawing.Point]::new(106, 4)
$RadioButtonPoolsUnavailable.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 8)
$RadioButtonPoolsUnavailable.Add_Click({ Update-TabControl })

$RadioButtonPools = New-Object System.Windows.Forms.RadioButton
$RadioButtonPools.Tag = ""
$RadioButtonPools.Text = "All Pools"
$RadioButtonPools.AutoSize = $false
$RadioButtonPools.Width = 100
$RadioButtonPools.Height = 20
$RadioButtonPools.Location = [System.Drawing.Point]::new(250, 4)
$RadioButtonPools.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 8)
$RadioButtonPools.Add_Click({ Update-TabControl })

$LabelPools = New-Object System.Windows.Forms.Label
$LabelPools.AutoSize = $false
$LabelPools.Width = 450
$LabelPools.Height = 18
$LabelPools.Location = [System.Drawing.Point]::new(2, 4)
$LabelPools.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$PoolsPageControls += $LabelPools

$PoolsPanel = New-Object System.Windows.Forms.Panel
$PoolsPanel.Height = 24
$PoolsPanel.Location = [System.Drawing.Point]::new(0, 22)
$PoolsPanel.Controls.Add($RadioButtonPools)
$PoolsPanel.Controls.Add($RadioButtonPoolsUnavailable)
$PoolsPanel.Controls.Add($RadioButtonPoolsBest)
$PoolsPageControls += $PoolsPanel

$PoolsDGV = New-Object System.Windows.Forms.DataGridView
$PoolsDGV.Name = "PoolsDGV"
$PoolsDGV.Location = [System.Drawing.Point]::new(2, 50)
$PoolsDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$PoolsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$PoolsDGV.AutoSizeColumnsMode = "Fill"
$PoolsDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$PoolsDGV.RowHeadersVisible = $false
$PoolsDGV.ColumnHeadersVisible = $true
$PoolsDGV.AllowUserToAddRows = $false
$PoolsDGV.AllowUserToOrderColumns = $true
$PoolsDGV.AllowUserToResizeColumns = $true
$PoolsDGV.AllowUserToResizeRows = $false
$PoolsDGV.ReadOnly = $true
$PoolsDGV.EnableHeadersVisualStyles = $false
$PoolsDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$PoolsDGV.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.SystemColors]::MenuBar
$PoolsDGV.SelectionMode = "FullRowSelect"
$PoolsDGV.ContextMenuStrip = $ContextMenuStrip
$PoolsDGV.Add_MouseUP(
    { 
        If ($_.Button -eq [System.Windows.Forms.MouseButtons]::Right ) { 
            $ContextMenuStrip.Enabled = [Boolean]$This.SelectedRows
        }
    }
)
$PoolsPageControls += $PoolsDGV

# Monitoring Page Controls
$RigMonitorPageControls = @()

$LabelWorkers = New-Object System.Windows.Forms.Label
$LabelWorkers.AutoSize = $false
$LabelWorkers.Width = 450
$LabelWorkers.Height = 18
$LabelWorkers.Location = [System.Drawing.Point]::new(2, 4)
$LabelWorkers.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$RigMonitorPageControls += $LabelWorkers

$WorkersDGV = New-Object System.Windows.Forms.DataGridView
$WorkersDGV.Location = [System.Drawing.Point]::new(2, 26)
$WorkersDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$WorkersDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$WorkersDGV.AutoSizeColumnsMode = "Fill"
$WorkersDGV.ColumnHeadersHeightSizeMode = "AutoSize"
$WorkersDGV.AutoSizeRowsMode = "AllCells"
$WorkersDGV.DefaultCellStyle= @{ WrapMode = "True" }
$WorkersDGV.RowHeadersVisible = $false
$WorkersDGV.AllowUserToAddRows = $false
$WorkersDGV.ColumnHeadersVisible = $true
$WorkersDGV.AllowUserToOrderColumns = $true
$WorkersDGV.AllowUserToResizeColumns = $true
$WorkersDGV.AllowUserToResizeRows = $true
$WorkersDGV.ReadOnly = $true
$WorkersDGV.EnableHeadersVisualStyles = $false
$WorkersDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$RigMonitorPageControls += $WorkersDGV

# Switching Page Controls
$SwitchingPageControls = @()

$CheckShowSwitchingCPU = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingCPU.Tag = "CPU"
$CheckShowSwitchingCPU.Text = "CPU"
$CheckShowSwitchingCPU.AutoSize = $false
$CheckShowSwitchingCPU.Width = 70
$CheckShowSwitchingCPU.Height = 20
$CheckShowSwitchingCPU.Location = [System.Drawing.Point]::new(2, 4)
$CheckShowSwitchingCPU.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingCPU.Checked = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "CPU#*")
$SwitchingPageControls += $CheckShowSwitchingCPU
$CheckShowSwitchingCPU | ForEach-Object { $_.Add_Click({ CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingAMD = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingAMD.Tag = "AMD"
$CheckShowSwitchingAMD.Text = "AMD"
$CheckShowSwitchingAMD.AutoSize = $false
$CheckShowSwitchingAMD.Width = 70
$CheckShowSwitchingAMD.Height = 20
$CheckShowSwitchingAMD.Location = [System.Drawing.Point]::new(72, 4)
$CheckShowSwitchingAMD.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingAMD.Checked = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "GPU#*" | Where-Object Vendor -EQ "AMD")
$SwitchingPageControls += $CheckShowSwitchingAMD
$CheckShowSwitchingAMD | ForEach-Object { $_.Add_Click({ CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingINTEL = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingINTEL.Tag = "INTEL"
$CheckShowSwitchingINTEL.Text = "INTEL"
$CheckShowSwitchingINTEL.AutoSize = $false
$CheckShowSwitchingINTEL.Width = 70
$CheckShowSwitchingINTEL.Height = 20
$CheckShowSwitchingINTEL.Location = [System.Drawing.Point]::new(142, 4)
$CheckShowSwitchingINTEL.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingINTEL.Checked = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "GPU#*" | Where-Object Vendor -EQ "INTEL")
$SwitchingPageControls += $CheckShowSwitchingINTEL
$CheckShowSwitchingINTEL | ForEach-Object { $_.Add_Click({ CheckBoxSwitching_Click($this) }) }

$CheckShowSwitchingNVIDIA = New-Object System.Windows.Forms.CheckBox
$CheckShowSwitchingNVIDIA.Tag = "NVIDIA"
$CheckShowSwitchingNVIDIA.Text = "NVIDIA"
$CheckShowSwitchingNVIDIA.AutoSize = $false
$CheckShowSwitchingNVIDIA.Width = 70
$CheckShowSwitchingNVIDIA.Height = 20
$CheckShowSwitchingNVIDIA.Location = [System.Drawing.Point]::new(212, 4)
$CheckShowSwitchingNVIDIA.Font = [System.Drawing.Font]::new("Microsoft Sans Serif", 10)
$CheckShowSwitchingNVIDIA.Checked = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "GPU#*" | Where-Object Vendor -EQ "NVIDIA")
$SwitchingPageControls += $CheckShowSwitchingNVIDIA
$CheckShowSwitchingNVIDIA | ForEach-Object { $_.Add_Click({ CheckBoxSwitching_Click($this) }) }

Function CheckBoxSwitching_Click { 
    $SwitchingDisplayTypes = @()
    $SwitchingPageControls | ForEach-Object { If ($_.Checked) { $SwitchingDisplayTypes += $_.Tag } }
    If (Test-Path -Path ".\Logs\SwitchingLog.csv" -PathType Leaf) { 
        $SwitchingDGV.DataSource = Get-Content ".\Logs\SwitchingLog.csv" | ConvertFrom-Csv | Where-Object { $_.Type -in $SwitchingDisplayTypes } | Select-Object -Last 1000 | ForEach-Object { $_.Datetime = (Get-Date $_.DateTime).ToString("G"); $_ } | Select-Object @("DateTime", "Action", "Name", "Pools", "Algorithms", "Accounts", "Duration", "DeviceNames", "Type") | Out-DataTable
        If ($SwitchingDGV.Columns) { 
            $SwitchingDGV.Columns[0].FillWeight = 80
            $SwitchingDGV.Columns[1].FillWeight = 50
            $SwitchingDGV.Columns[2].FillWeight = 150
            $SwitchingDGV.Columns[3].FillWeight = 90
            $SwitchingDGV.Columns[4].FillWeight = 65
            $SwitchingDGV.Columns[5].FillWeight = 80
        }
        If ($SwitchingDGV.Columns[8]) { 
            $SwitchingDGV.Columns[0].HeaderText = "Date & Time"
            $SwitchingDGV.Columns[6].HeaderText = "Running Time"
            $SwitchingDGV.Columns[6].FillWeight = 50
            $SwitchingDGV.Columns[7].FillWeight = 55
            $SwitchingDGV.Columns[8].FillWeight = 50
        }
        $SwitchingDGV.ClearSelection()
    }
}

$SwitchingDGV = New-Object System.Windows.Forms.DataGridView
$SwitchingDGV.Name = "SwitchingDGV"
$SwitchingDGV.Location = [System.Drawing.Point]::new(2, 28)
$SwitchingDGV.Font = [System.Drawing.Font]::new("Segoe UI", 9)
$SwitchingDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$SwitchingDGV.AutoSizeColumnsMode = "Fill"
$SwitchingDGV.RowHeadersVisible = $false
$SwitchingDGV.ColumnHeadersVisible = $true
$SwitchingDGV.AllowUserToAddRows = $false
$SwitchingDGV.AllowUserToOrderColumns = $true
$SwitchingDGV.AllowUserToResizeColumns = $true
$SwitchingDGV.AllowUserToResizeRows = $false
$SwitchingDGV.ReadOnly = $true
$SwitchingDGV.EnableHeadersVisualStyles = $false
$SwitchingDGV.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.SystemColors]::MenuBar
$SwitchingPageControls += $SwitchingDGV

$LegacyGUIForm.Controls.AddRange(@($LegacyGUIControls))
$RunPage.Controls.AddRange(@($RunPageControls))
$EarningsPage.Controls.AddRange(@($EarningsPageControls))
$MinersPage.Controls.AddRange(@($MinersPageControls))
$PoolsPage.Controls.AddRange(@($PoolsPageControls))
$RigMonitorPage.Controls.AddRange(@($RigMonitorPageControls))
$SwitchingPage.Controls.AddRange(@($SwitchingPageControls))

Function Update-TabControl { 

    $LegacyGUIForm.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    # Keep only 100 lines, more lines impact performance
    $SelectionLength = $Variables.TextBoxSystemLog.SelectionLength
    $SelectionStart = $Variables.TextBoxSystemLog.SelectionStart
    $TextLength = $Variables.TextBoxSystemLog.TextLength
    $Variables.TextBoxSystemLog.Lines = @($Variables.TextBoxSystemLog.Lines | Select-Object -Last 100)
    $Variables.TextBoxSystemLog.SelectionStart = $SelectionStart - $TextLength + $Variables.TextBoxSystemLog.TextLength
    If ($Variables.TextBoxSystemLog.SelectionStart -gt 0) { 
        $Variables.TextBoxSystemLog.SelectionLength = $SelectionLength
    }

    Switch ($TabControl.SelectedTab.Text) { 
        "Run" { 
            $ContextMenuStripItem1.Text = "Re-Benchmark"
            $ContextMenuStripItem2.Text = "Re-measure power usage"
            $ContextMenuStripItem3.Text = "Mark as failed"
            $ContextMenuStripItem4.Text = "Disable"
            $ContextMenuStripItem5.Text = "Remove Watchdog"
            $ContextMenuStripItem4.Visible = $true
            $ContextMenuStripItem5.Visible = $False

            If ($Variables.TextBoxSystemLog.SelectionLength) { 
                $Variables.TextBoxSystemLog.Select()
            }
            Else { 
                $Variables.TextBoxSystemLog.SelectionStart = $Variables.TextBoxSystemLog.TextLength
                $Variables.TextBoxSystemLog.ScrollToCaret()
                $Variables.TextBoxSystemLog.Refresh()
            }

            If ($Variables.MinersBest_Combo) { 

                If (-not ($ContextMenuStrip.Visible -and $ContextMenuStrip.Enabled)) { 

                    $LaunchedMinersDGV.DataSource = $Variables.MinersBest_Combo | Select-Object @(
                        @{ Name = "Device(s)"; Expression = { $_.DeviceNames -join "; " } }
                        @{ Name = "Miner"; Expression = { "$($_.Name) $($_.Info)" } }
                        @{ Name = "Account(s)"; Expression = { ($_.Workers.Pool.User | Select-Object -Unique | ForEach-Object { $_ -split '\.' | Select-Object -First 1 } | Select-Object -Unique) -join ' & ' } }
                        @{ Name = "Earning $($Config.Currency)/day"; Expression = { If (-not [Double]::IsNaN($_.Earning)) {"{0:n$($Config.DecimalsMax)}" -f ($_.Earning * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }
                        @{ Name = "Power cost $($Config.Currency)/day"; Expression = { If ($Variables.CalculatePowerCost -and -not [Double]::IsNaN($_.PowerCost)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }
                        @{ Name = "Profit $($Config.Currency)/day"; Expression = { If ($Variables.CalculatePowerCost -and -not [Double]::IsNaN($_.Profit)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }
                        @{ Name = "Power usage"; Expression = { If (-not $_.MeasurePowerUsage) { If ([Double]::IsNaN($_.PowerUsage)) { "n/a" } Else { "$($_.PowerUsage.ToString("N2")) W"} } Else { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } } }
                        @{ Name = "Pool(s)"; Expression = { ($_.WorkersRunning.Pool | ForEach-Object { (@(@($_.Name | Select-Object) + @($_.Coin | Select-Object))) -join '-' }) -join ' & ' } }
                        @{ Name = "Hashrate(s)"; Expression = { If (-not $_.Benchmark) { ($_.Workers | ForEach-Object { "$($_.Hashrate | ConvertTo-Hash)/s" }) -join " & " } Else { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } } }
                        @{ Name = "Active (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [math]::floor(((Get-Date).ToUniversalTime() - $_.BeginTime).TotalDays * 24), ((Get-Date).ToUniversalTime() - $_.BeginTime) } }
                        @{ Name = "Total active (hhh:mm:ss)"; Expression = { "{0}:{1:mm}:{1:ss}" -f [math]::floor($_.TotalMiningDuration.TotalDays * 24), $_.TotalMiningDuration } }
                        If ($RadioButtonPoolsUnavailable.checked) { @{ Name = "Reason"; Expression = { $_.Reasons -join ', ' } } }
                        ) | Sort-Object "Device(s)" | Out-DataTable

                    If ($LaunchedMinersDGV.Columns) { 
                        $LaunchedMinersDGV.Columns[0].FillWeight = 75
                        $LaunchedMinersDGV.Columns[1].FillWeight = 225
                        $LaunchedMinersDGV.Columns[2].FillWeight = 150
                        $LaunchedMinersDGV.Columns[3].FillWeight = 50; $LaunchedMinersDGV.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $LaunchedMinersDGV.Columns[4].FillWeight = 50; $LaunchedMinersDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $LaunchedMinersDGV.Columns[5].FillWeight = 50; $LaunchedMinersDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                        $LaunchedMinersDGV.Columns[6].FillWeight = 50; $LaunchedMinersDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
                        $LaunchedMinersDGV.Columns[7].FillWeight = 100
                        $LaunchedMinersDGV.Columns[8].FillWeight = 75; $LaunchedMinersDGV.Columns[8].DefaultCellStyle.Alignment = "MiddleRight"; $LaunchedMinersDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"
                        $LaunchedMinersDGV.Columns[9].FillWeight = 65
                        $LaunchedMinersDGV.Columns[10].FillWeight = 65
                    }

                    $LaunchedMinersDGV.Columns[4].Visible = $Variables.CalculatePowerCost
                    $LaunchedMinersDGV.Columns[5].Visible = $Variables.CalculatePowerCost
                    $LaunchedMinersDGV.Columns[6].Visible = $Variables.CalculatePowerCost

                    $LaunchedMinersDGV.ClearSelection()

                    $LabelLaunchedMiners.Text = "Launched Miners - Updated $((Get-Date).ToString())"
                    Form_Resize # To fully show lauched miners gridview
                }
            }
            Else { 
                $LabelLaunchedMiners.Text = "Waiting for data..."
            }
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
                    $Color[$_] = [math]::Abs(($Color[$_] + $Factors[$_]) % 256)
                }
                $Color
            }

            If (Test-Path -Path ".\Data\EarningsChartData.json" -PathType Leaf) { 

                $Datasource = Get-Content -Path ".\Data\EarningsChartData.json" -ErrorAction Ignore | ConvertFrom-Json -ErrorAction Ignore

                $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
                $ChartTitle.Text = "Earnings of the past $($DataSource.Labels.Count) active days"
                $ChartTitle.Font = [System.Drawing.Font]::new("Arial", 10)
                $ChartTitle.Alignment = "TopCenter"
                $EarningsChart.Titles.Clear()
                $EarningsChart.Titles.Add($ChartTitle)

                $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
                $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#2B3232" 
                $ChartArea.BackSecondaryColor = [System.Drawing.Color]::FromArgb(255, 180, 180, 180) #"#777E7E"
                $ChartArea.BackGradientStyle = 3
                $ChartArea.AxisX.LabelStyle.Enabled = $true
                $ChartArea.AxisX.Enabled = 0
                $ChartArea.AxisX.Minimum = 0
                $ChartArea.AxisX.Maximum = $Datasource.Labels.Count + 1
                $ChartArea.AxisX.Interval = 1
                $ChartArea.AxisY.LabelAutoFitStyle = 16
                $ChartArea.AxisX.IsMarginVisible = $false
                $ChartArea.AxisX.MajorGrid.Enabled = $false
                $ChartArea.AxisY.MajorGrid.Enabled = $true
                $ChartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#FFFFFF"
                $ChartArea.AxisY.IsMarginVisible = $false
                $ChartArea.AxisY.LabelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
                $ChartArea.AxisY.Interval = [Math]::Ceiling(($Datasource.DaySum | Measure-Object -Maximum).Maximum / 4)
                $ChartArea.AxisY.Title = $Config.Currency
                $ChartArea.AxisY.ToolTip = "Total Earnings per day"

                $EarningsChart.ChartAreas.Clear()
                $EarningsChart.ChartAreas.Add($ChartArea)
                $EarningsChart.Series.Clear()

                $Color = @(255, 255, 255, 255) #"FFFFFF"
                $EarningsChart.BringToFront()

                $DaySum = @(0) * $DataSource.Labels.Count
                $ToolTip = $DataSource.Labels | ConvertTo-Json | ConvertFrom-Json

                ForEach ($Pool in $DataSource.Earnings.PSObject.Properties.Name) { 

                    $Color = (Get-NextColor -Color $Color -Factors -0, -20, -20, -20)
                    $I = 0

                    $EarningsChart.Series.Add($Pool)
                    $EarningsChart.Series[$Pool].ChartArea = "ChartArea"
                    $EarningsChart.Series[$Pool].ChartType = "StackedColumn"
                    $EarningsChart.Series[$Pool].BorderWidth = 3
                    $EarningsChart.Series[$Pool].Legend = $Pool
                    $EarningsChart.Series[$Pool].Color = [System.Drawing.Color]::FromArgb($Color[0], $Color[1], $Color[2], $Color[3])

                    $Datasource.Earnings.$Pool | ForEach-Object { 
                        $_ *= $Variables.Rates.BTC.($Config.Currency)
                        $EarningsChart.Series[$Pool].Points.addxy(0, "{0:N$($Variables.Digits)}" -f $_) | Out-Null
                        $Daysum[$I] += $_
                        If ($_) { 
                            $ToolTip[$I] = "$($ToolTip[$I])`n$($Pool): {0:N$($Config.DecimalsMax)} $($Config.Currency)" -f $_
                        }
                        $I++
                    }
                }

                $I = 0
                $ChartArea.AxisX.CustomLabels.Clear()
                $DataSource.Labels | ForEach-Object { 
                    $ChartArea.AxisX.CustomLabels.Add($I +0.5, $I + 1.5, " $_ ")
                    ForEach ($Pool in ($DataSource.Earnings.PSObject.Properties.Name)) { 
                        If ($Datasource.Earnings.$Pool[$I]) { 
                            $EarningsChart.Series[$Pool].Points[$I].ToolTip = "$($ToolTip[$I])`nTotal: {0:N$($Config.DecimalsMax)} $($Config.Currency)" -f $Daysum[$I]
                        }
                    }
                    $I++
                }

                $ChartArea.AxisY.Maximum = ($DaySum | Measure-Object -Maximum).Maximum * 1.05
            }

            If ($Variables.Balances) { 
                $EarningsDGV.DataSource = $Variables.Balances.Values | Select-Object @(
                    @{ Name = "Pool"; Expression = { "$($_.Pool) [$($_.Currency)]" } }, 
                    @{ Name = "Balance ($($Config.Currency))"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Balance * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                    @{ Name = "Avg. $($Config.Currency)/day"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.AvgDailyGrowth * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                    @{ Name = "$($Config.Currency) in 1h"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth1 * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                    @{ Name = "$($Config.Currency) in 6h"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth6 * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                    @{ Name = "$($Config.Currency) in 24h"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ($_.Growth24 * $Variables.Rates.($_.Currency).($Config.Currency)) } }, 
                    @{ Name = "Projected paydate"; Expression = { If ($_.ProjectedPayDate -is [DateTime]) { $_.ProjectedPayDate.ToShortDateString() } Else { $_.ProjectedPayDate } } }, 
                    @{ Name = "Payout threshold"; Expression = { If ($_.Currency -eq "BTC" -and $Config.UsemBTC) { $Currency = "mBTC"; $mBTCfactor = 1000 } Else { $Currency = $_.Currency; $mBTCfactor = 1 }; "{0:P2} of {1} {2} " -f ($_.Balance / $_.PayoutThreshold), ($_.PayoutThreshold * $mBTCfactor), $Currency } }
                ) | Sort-Object Pool | Out-DataTable

                $EarningsDGV.ClearSelection()

                If ($EarningsDGV.Columns) { 
                    $EarningsDGV.Columns[0].FillWeight = 140
                    $EarningsDGV.Columns[1].FillWeight = 90; $EarningsDGV.Columns[1].DefaultCellStyle.Alignment = "MiddleRight"; $EarningsDGV.Columns[1].HeaderCell.Style.Alignment = "MiddleRight"
                    $EarningsDGV.Columns[2].FillWeight = 90; $EarningsDGV.Columns[2].DefaultCellStyle.Alignment = "MiddleRight"; $EarningsDGV.Columns[2].HeaderCell.Style.Alignment = "MiddleRight"
                    $EarningsDGV.Columns[3].FillWeight = 75; $EarningsDGV.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"; $EarningsDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                    $EarningsDGV.Columns[4].FillWeight = 75; $EarningsDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $EarningsDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                    $EarningsDGV.Columns[5].FillWeight = 75; $EarningsDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $EarningsDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                    $EarningsDGV.Columns[6].FillWeight = 80
                    $EarningsDGV.Columns[7].FillWeight = 100
                }

                $LabelEarnings.Text = "Earnings statistics per pool - Updated $((Get-ChildItem -Path ".\Data\DailyEarnings.csv").LastWriteTime.ToString())"
            }
            Else { $LabelEarnings.Text = "Waiting for data..." }
        }
        "Miners" { 
            $ContextMenuStripItem1.Text = "Re-Benchmark"
            $ContextMenuStripItem2.Text = "Re-measure power usage"
            $ContextMenuStripItem3.Text = "Mark as failed"
            $ContextMenuStripItem4.Text = "Disable"
            $ContextMenuStripItem5.Text = "Remove Watchdog"
            $ContextMenuStripItem4.Visible = $true
            $ContextMenuStripItem5.Visible = $RadioButtonMinersUnavailable.Checked

            If ($Variables.Miners) { 
                If (-not ($ContextMenuStrip.Visible -and $ContextMenuStrip.Enabled)) { 

                    If ($RadioButtonMinersMostProfitable.checked) { $DataSource = $Variables.MinersMostProfitable }
                    ElseIf ($RadioButtonMinersUnavailable.checked) { $DataSource = $Variables.Miners | Where-Object { -not $_.Available } }
                    Else { $DataSource = $Variables.Miners }

                    $SortBy = If ($Variables.CalculatePowerCost -and -not $Config.IgnorePowerCost) { "Profit" } Else {"Earning" }
                    $MinersDGV.DataSource = $DataSource | Select-Object @(
                        @{ Name = "Miner"; Expression = { $_.Name } }, 
                        @{ Name = "Device(s)"; Expression = { $_.DeviceNames -join ', ' } }, 
                        @{ Name = "Earning $($Config.Currency)/day"; Expression = { If (-not [Double]::IsNaN($_.Earning)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Earning * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }, 
                        @{ Name = "Power cost $($Config.Currency)/day"; Expression = { If (-not [Double]::IsNaN($_.PowerCost)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Powercost * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }, 
                        @{ Name = "Profit $($Config.Currency)/day"; Expression = { If ($Variables.CalculatePowerCost -and -not [Double]::IsNaN($_.Profit)) { "{0:n$($Config.DecimalsMax)}" -f ($_.Profit * $Variables.Rates.BTC.($Config.Currency)) } Else { "n/a" } } }, 
                        @{ Name = "Power usage"; Expression = { If (-not $_.MeasurePowerUsage) { If ([Double]::IsNaN($_.PowerUsage)) { "n/a" } Else { "$($_.PowerUsage.ToString("N2")) W"} } Else { If ($_.Status -eq "Running") { "Measuring..." } Else { "Unmeasured" } } } }
                        @{ Name = "Power usage"; Expression = { If ($_.MeasurePowerUsage) { "Measuring" } Else { "$($_.PowerUsage.ToString("N2")) W" } } }, 
                        @{ Name = "Algorithm(s)"; Expression = { $_.Algorithms -join ' & ' } }, 
                        @{ Name = "Pool(s)"; Expression = { ($_.Workers.Pool | ForEach-Object { (@(@($_.Name | Select-Object) + @($_.Coin | Select-Object))) -join '-' }) -join ' & ' } }, 
                        @{ Name = "Hashrate(s)"; Expression = { If (-not $_.Benchmark) { ($_.Workers | ForEach-Object { "$($_.Hashrate | ConvertTo-Hash)/s" }) -join " & " } Else { If ($_.Status -eq "Running") { "Benchmarking..." } Else { "Benchmark pending" } } } }
                        If ($RadioButtonMinersUnavailable.checked -or $RadioButtonMiners.checked) { @{ Name = "Reason"; Expression = { $_.Reasons -join ', '} } }
                    ) | Sort-Object "$SortBy $($Config.Currency)/day" -Descending | Out-DataTable

                    If ($MinersDGV.Columns) { 
                        $MinersDGV.Columns[0].FillWeight = 200
                        $MinersDGV.Columns[1].FillWeight = 80
                        $MinersDGV.Columns[2].FillWeight = 55; $MinersDGV.Columns[2].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[2].HeaderCell.Style.Alignment = "MiddleRight"
                        $MinersDGV.Columns[3].FillWeight = 55; $MinersDGV.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $MinersDGV.Columns[4].FillWeight = 55; $MinersDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $MinersDGV.Columns[5].FillWeight = 55; $MinersDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                        $MinersDGV.Columns[6].FillWeight = 90
                        $MinersDGV.Columns[7].FillWeight = 125
                        $MinersDGV.Columns[8].FillWeight = 80; $MinersDGV.Columns[8].DefaultCellStyle.Alignment = "MiddleRight"; $MinersDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"
                    }

                    $MinersDGV.Columns[3].Visible = $Variables.CalculatePowerCost
                    $MinersDGV.Columns[4].Visible = $Variables.CalculatePowerCost
                    $MinersDGV.Columns[5].Visible = $Variables.CalculatePowerCost

                    $MinersDGV.ClearSelection()

                    $LabelMiners.Text = "Miner data read from stats - Updated $((Get-Date).ToString())"
                }
            }
            Else { $LabelMiners.Text = "Waiting for data..." }
        }
        "Pools" { 
            $ContextMenuStripItem5.Visible = $false
            $ContextMenuStripItem1.Text = "Enable Algorithm @ Pool"
            $ContextMenuStripItem2.Text = "Disable Algorithm @ Pool"
            $ContextMenuStripItem3.Text = "Reset Pool Stat Data"
            $ContextMenuStripItem4.Text = "Remove Watchdog"
            $ContextMenuStripItem4.Visible = (-not $RadioButtonPoolsBest.Checked)
            $ContextMenuStripItem5.Visible = $false

            If ($Variables.Pools) { 

                If (-not ($ContextMenuStrip.Visible -and $ContextMenuStrip.Enabled)) { 

                    If ($RadioButtonPoolsBest.checked) { $DataSource = $Variables.PoolsBest }
                    ElseIf ($RadioButtonPoolsUnavailable.checked) { $DataSource = $Variables.Pools | Where-Object { -not $_.Available } }
                    Else { $DataSource = $Variables.Pools }

                    $PoolsDGV.DataSource = $DataSource | Select-Object @(
                        @{ Name = "Algorithm"; Expression = { $_.Algorithm } }
                        @{ Name = "Coin Name"; Expression = { $_.CoinName } }
                        @{ Name = "Currency"; Expression = { $_.Currency } }
                        @{ Name = "BTC/GH/Day`n(Biased)"; Expression = { "{0:n15}" -f $_.Price_Bias } }
                        @{ Name = "Accuracy"; Expression = { "{0:p2}" -f $_.Accuracy } }
                        @{ Name = "Pool Name"; Expression = { $_.Name } }
                        @{ Name = "Host"; Expression = { $_.Host } }
                        @{ Name = "Port"; Expression = { "$(If ($_.Port) { $_.Port } Else { "-" })" } }
                        @{ Name = "PortSSL"; Expression = { "$(If ($_.PortSSL) { $_.PortSSL } Else { "-" })" } }
                        @{ Name = "Earnings`nAdjustment`nFactor"; Expression = { $_.EarningsAdjustmentFactor } }
                        @{ Name = "Fee"; Expression = { "{0:p2}" -f $_.Fee } }
                        If ($RadioButtonPoolsUnavailable.checked -or $RadioButtonPools.checked) { @{ Name = "Reason"; Expression = { $_.Reasons -join ', '} } }
                    ) | Sort-Object Algorithm | Out-DataTable

                    If ($PoolsDGV.Columns) { 
                        $PoolsDGV.Columns[0].FillWeight = 100
                        $PoolsDGV.Columns[1].FillWeight = 90
                        $PoolsDGV.Columns[2].FillWeight = 60
                        $PoolsDGV.Columns[3].FillWeight = 90; $PoolsDGV.Columns[3].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[3].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[4].FillWeight = 60; $PoolsDGV.Columns[4].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[4].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[5].FillWeight = 100
                        $PoolsDGV.Columns[6].FillWeight = 200
                        $PoolsDGV.Columns[7].FillWeight = 60; $PoolsDGV.Columns[7].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[7].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[8].FillWeight = 60; $PoolsDGV.Columns[8].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[8].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[9].FillWeight = 60; $PoolsDGV.Columns[9].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[9].HeaderCell.Style.Alignment = "MiddleRight"
                        $PoolsDGV.Columns[10].FillWeight = 60; $PoolsDGV.Columns[10].DefaultCellStyle.Alignment = "MiddleRight"; $PoolsDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                    }

                    $PoolsDGV.ClearSelection()

                    $LabelPools.Text = "Pool data read from stats - Updated $((Get-Date).ToString())"
                }
            }
            Else { 
                $LabelPools.Text = "Waiting for data..."
            }
        }
        "Rig Monitor" { 

            Read-MonitoringData | Out-Null

            If ($Variables.Workers) { 
                $Variables.Workers | ForEach-Object { 
                    $TimeSinceLastReport = New-TimeSpan -Start $_.date -End (Get-Date)
                    # Show friendly time since last report in seconds, minutes, hours and days
                    $TimeSinceLastReportText = ""
                    If ($TimeSinceLastReport.Days -ge 1) { $TimeSinceLastReportText += " {0:n0} day$(If ($TimeSinceLastReport.Days -ne 1) { "s" })" -f $TimeSinceLastReport.Days }
                    If ($TimeSinceLastReport.Hours -ge 1) { $TimeSinceLastReportText += " {0:n0} hour$(If ($TimeSinceLastReport.Hours -ne 1) { "s" })" -f $TimeSinceLastReport.Hours }
                    If ($TimeSinceLastReport.Minutes -ge 1) { $TimeSinceLastReportText += " {0:n0} minute$(If ($TimeSinceLastReport.Minutes -ne 1) { "s" })" -f $TimeSinceLastReport.Minutes }
                    If ($TimeSinceLastReport.Seconds -ge 1) { $TimeSinceLastReportText += " {0:n0} second$(If ($TimeSinceLastReport.Seconds -ne 1) { "s" })" -f $TimeSinceLastReport.Seconds }
                    If ($TimeSinceLastReportText) { $_ | Add-Member -Force @{ TimeSinceLastReportText = "$($TimeSinceLastReportText.trim()) ago" } }
                    Else  { $_ | Add-Member -Force @{ TimeSinceLastReportText = "just now" } }
                }

                $nl = "`n" # Must use variable, cannot join with '`n' directly
                $WorkersDGV.DataSource = $Variables.Workers | Select-Object @(
                    @{ Name = "Worker"; Expression = { $_.worker } }, 
                    @{ Name = "Status"; Expression = { $_.status } }, 
                    @{ Name = "Last seen"; Expression = { $_.TimeSinceLastReportText } }, 
                    @{ Name = "Version"; Expression = { $_.version } }, 
                    @{ Name = "Currency"; Expression = { [String]$Config.Currency } }, 
                    @{ Name = "Estimated Earning/day"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ([Decimal](($_.Data.Earning | Measure-Object -Sum).Sum) * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } }, 
                    @{ Name = "Estimated Profit/day"; Expression = { "{0:n$($Config.DecimalsMax)}" -f ([Decimal](($_.Data.Profit | Measure-Object -Sum).Sum) * $Variables.Rates.BTC.($_.Data.Currency | Select-Object -Unique)) } }, 
                    @{ Name = "Miner(s)"; Expression = { $_.data.Name -join $nl } }, 
                    @{ Name = "Pool(s)"; Expression = { ($_.data | ForEach-Object { $_.Pool -join " & " }) -join $nl } }, 
                    @{ Name = "Algorithm(s)"; Expression = { ($_.data | ForEach-Object { $_.Algorithm -split "," -join " & " }) -join $nl } }, 
                    @{ Name = "Live Hashrate(s)"; Expression = { ($_.data | ForEach-Object { ($_.CurrentSpeed | ForEach-Object { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " }) -join " & " }) -join $nl } }, 
                    @{ Name = "Benchmark Hashrate(s)"; Expression = { ($_.data | ForEach-Object { ($_.EstimatedSpeed | ForEach-Object { "$($_ | ConvertTo-Hash)/s" -replace "\s+", " " }) -join " & " }) -join $nl } }
                ) | Sort-Object "Worker" | Out-DataTable

                # Set row color
                ForEach ($Row in $WorkersDGV.Rows) { 
                    $Row.DefaultCellStyle.Backcolor = Switch ($Row.DataBoundItem.Status) { 
                        "Offline" { [System.Drawing.Color]::FromArgb(255, 255, 230, 230) }
                        "Paused"  { [System.Drawing.Color]::FromArgb(255, 255, 241, 195) }
                        "Running" { [System.Drawing.Color]::FromArgb(255, 232, 250, 232) }
                        Default   { [System.Drawing.Color]::FromArgb(255, 255, 255, 255) }
                    }
                }

                If ($WorkersDGV.Columns) { 
                    $WorkersDGV.Columns[0].FillWeight = 70
                    $WorkersDGV.Columns[1].FillWeight = 40
                    $WorkersDGV.Columns[2].FillWeight = 80
                    $WorkersDGV.Columns[3].FillWeight = 70
                    $WorkersDGV.Columns[4].FillWeight = 40
                    $WorkersDGV.Columns[5].FillWeight = 65; $WorkersDGV.Columns[5].DefaultCellStyle.Alignment = "MiddleRight"; $WorkersDGV.Columns[5].HeaderCell.Style.Alignment = "MiddleRight"
                    $WorkersDGV.Columns[6].FillWeight = 65; $WorkersDGV.Columns[6].DefaultCellStyle.Alignment = "MiddleRight"; $WorkersDGV.Columns[6].HeaderCell.Style.Alignment = "MiddleRight"
                    $WorkersDGV.Columns[7].FillWeight = 175
                    $WorkersDGV.Columns[8].FillWeight = 95
                    $WorkersDGV.Columns[9].FillWeight = 75
                    $WorkersDGV.Columns[10].FillWeight = 65; $WorkersDGV.Columns[10].DefaultCellStyle.Alignment = "MiddleRight"; $WorkersDGV.Columns[10].HeaderCell.Style.Alignment = "MiddleRight"
                    $WorkersDGV.Columns[11].FillWeight = 65; $WorkersDGV.Columns[11].DefaultCellStyle.Alignment = "MiddleRight"; $WorkersDGV.Columns[11].HeaderCell.Style.Alignment = "MiddleRight"
                }

                $WorkersDGV.ClearSelection()

                $LabelWorkers.Text = "Worker Status - Updated $($Variables.WorkersLastUpdated.ToString())"
            }
            Else { $LabelWorkers.Text = "Worker Status - no workers" }
        }
        "Switching Log" { 
            $CheckShowSwitchingCPU.Enabled = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "CPU#*")
            $CheckShowSwitchingAMD.Enabled = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "GPU#*" | Where-Object Vendor -EQ "AMD")
            $CheckShowSwitchingINTEL.Enabled = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "GPU#*" | Where-Object Vendor -EQ "INTEL")
            $CheckShowSwitchingNVIDIA.Enabled = [Boolean]($Variables.Devices | Where-Object { $_.State -NE [DeviceState]::Unsupported } | Where-Object Name -NotIn $Config.ExcludeDeviceName | Where-Object Name -Like "GPU#*" | Where-Object Vendor -EQ "NVIDIA")

            If (-not $CheckShowSwitchingCPU.Enabled) { $CheckShowSwitchingCPU.Checked = $false }
            If (-not $CheckShowSwitchingAMD.Enabled) { $CheckShowSwitchingAMD.Checked = $false }
            If (-not $CheckShowSwitchingINTEL.Enabled) { $CheckShowSwitchingINTEL.Checked = $false }
            If (-not $CheckShowSwitchingNVIDIA.Enabled) { $CheckShowSwitchingNVIDIA.Checked = $false }

            CheckBoxSwitching_Click
        }
    }

    $LegacyGUIForm.Cursor = [System.Windows.Forms.Cursors]::Normal
}

$LegacyGUIForm.Add_SizeChanged({ Form_Resize })

Function Form_Resize { 

    $TabControl.Width = $LegacyGUIForm.Width - 33
    $TabControl.Height = $LegacyGUIForm.Height - 159

    $LabelMiningStatus.Width = $LegacyGUIForm.Width - 345

    $ButtonStart.Location = [System.Drawing.Point]::new($LegacyGUIForm.Width - 325, 7)
    $ButtonPause.Location = [System.Drawing.Point]::new($LegacyGUIForm.Width - 225, 7)
    $ButtonStop.Location = [System.Drawing.Point]::new($LegacyGUIForm.Width - 125, 7)

    $TextBoxSummary.Width = $Variables.TextBoxSystemLog.Width = $EditConfigLink.Width = $LaunchedMinersDGV.Width = $PoolsDGV.Width= $MinersDGV.Width = $EarningsDGV.Width = $SwitchingDGV.Width = $WorkersDGV.Width  = $TabControl.Width - 13

    $LaunchedMinersDGV.Height = $LaunchedMinersDGV.RowTemplate.Height * $Variables.MinersBest_Combo.Count + $LaunchedMinersDGV.ColumnHeadersHeight
    If ($LaunchedMinersDGV.Height -gt $TabControl.Height / 2) { 
        $LaunchedMinersDGV.Height = $TabControl.Height / 2
        $LaunchedMinersDGV.ScrollBars = "Vertical"
    }
    Else { 
        $LaunchedMinersDGV.ScrollBars = "None"
    }

    $LabelSystemLog.Location = [System.Drawing.Point]::new(2, ($LabelLaunchedMiners.Height + $LaunchedMinersDGV.Height + 22))
    $Variables.TextBoxSystemLog.Location = [System.Drawing.Point]::new(2, ($LabelLaunchedMiners.Height + $LaunchedMinersDGV.Height + $LabelSystemLog.Height + 28))
    $Variables.TextBoxSystemLog.Height = ($TabControl.Height - $LabelLaunchedMiners.Height - $LaunchedMinersDGV.Height - $LabelSystemLog.Height - 59)

    $PoolsPanel.Width = $TabControl.Width - 12
    $PoolsDGV.Height = $TabControl.Height - $PoolsPanel.Height - 57

    $MinersPanel.Width = $TabControl.Width - 12
    $MinersDGV.Height = $TabControl.Height - $MinersPanel.Height - 57

    $WorkersDGV.Height = $TabControl.Height - 59

    If ($LegacyGUIForm.Width -gt 722) { 
        $EarningsChart.Width = ($TabControl.Width - 10)
    }

    $EarningsDGV.Height = ($EarningsDGV.Rows.Height | Measure-Object -Sum).Sum + $EarningsDGV.ColumnHeadersHeight
    If ($EarningsDGV.Height -gt $TabControl.Height / 2) { 
        $EarningsDGV.Height = $TabControl.Height / 2
        $EarningsDGV.ScrollBars = "Vertical"
    }
    Else { 
        $EarningsDGV.ScrollBars = "None"
    }
    $EarningsChart.Height = (($TabControl.Height - $LabelEarnings.Height - $EarningsDGV.Height - 29), 0 | Measure-Object -Maximum).Maximum
    $LabelEarnings.Location = [System.Drawing.Point]::new(2, ($EarningsChart.Height - 7))
    $EarningsDGV.Location = [System.Drawing.Point]::new(2, ($EarningsChart.Height + $LabelEarnings.Height - 2))

    $SwitchingDGV.Height = $TabControl.Height - 59

    $EditConfigLink.Location = [System.Drawing.Point]::new(10, $LegacyGUIForm.Height - 66)
    $LabelCopyright.Location = [System.Drawing.Point]::new(($LegacyGUIForm.Width - 375), $LegacyGUIForm.Height - 66)
}

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

        If ($Config.LegacyGUIStartMinimized) { $LegacyGUIForm.WindowState = [System.Windows.Forms.FormWindowState]::Minimized }

        Switch ($Variables.NewMiningStatus) { 
            "Idle" { 
                $LabelMiningStatus.Text = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version) is stopped"
                $LabelMiningStatus.ForeColor = [System.Drawing.Color]::Red
                $ButtonPause.Enabled = $true
                $ButtonStart.Enabled = $true
                $ButtonStop.Enabled = $false
            }
            "Paused" { 
                $LabelMiningStatus.Text = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version) is paused"
                $LabelMiningStatus.ForeColor = [System.Drawing.Color]::Blue
                $ButtonPause.Enabled = $false
                $ButtonStart.Enabled = $true
                $ButtonStop.Enabled = $true
            }
            "Running" { 
                $LabelMiningStatus.Text = "$($Variables.Branding.ProductLabel) $($Variables.Branding.Version) is running"
                $LabelMiningStatus.ForeColor = [System.Drawing.Color]::Green
                $ButtonPause.Enabled = $true
                $ButtonStart.Enabled = $false
                $ButtonStop.Enabled = $true
            }
        }

        $TimerUI = New-Object System.Windows.Forms.Timer
        $TimerUI.Interval = 250
        $TimerUI.Add_Tick(
            { 
                If ($Variables.APIRunspace ) { 
                    $EditConfigLink.Tag = "WebGUI"
                    $EditConfigLink.Text = "Edit configuration in the Web GUI"
                }
                Else { 
                    $EditConfigLink.Tag = "Edit-File"
                    $EditConfigLink.Text = "Edit configuration file '$($Variables.ConfigFile)' in notepad."
                }
                MainLoop
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

$ContextMenuStrip.Add_ItemClicked(
    { 
        $Data = @()

        If ($This.SourceControl.Name -match "LaunchedMinersDGV|MinersDGV") { 

            Switch ($_.ClickedItem.Text) { 
                "Re-Benchmark" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        If ($This.SourceControl.Name -eq "LaunchedMinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value -split " " | Select-Object -index 0
                            $SelectedMinerAlgorithms = @(($_.Cells[1].Value -split " {" | Select-Object -Index 1) -split " & " -replace "{", "" -replace "@.+", "")
                        }
                        ElseIf ($This.SourceControl.Name -eq "MinersDGV") { 
                            $SelectedMinerName = $_.Cells[0].Value
                            $SelectedMinerAlgorithms = @($_.Cells[6].Value -split " & ")
                        }
                        $Variables.Miners | Where-Object { $_.Name -EQ $SelectedMinerName } | Where-Object { [String]$_.Algorithms -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                            If ($_.Earning -eq 0) { $_.Available = $true }
                            $_.Earning_Accuracy = [Double]::NaN
                            $_.Activated = 0 # To allow 3 attempts
                            $_.Disabled = $false
                            $_.Benchmark = $true
                            $_.Restart = $true
                            $Data += "`n$($_.Name) ($($_.Algorithms -join " & "))"
                            ForEach ($Worker in $_.Workers) { 
                                Remove-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                $Worker.Hashrate = [Double]::NaN
                            }
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
                        Write-Message -Level Verbose "GUI: Re-benchmark triggered for $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                        $Data += "`n`n$(If ($Data.Count -eq 1) { "The miner" } Else { "$($Data.Count) miners" }) will re-benchmark."
                        Update-TabControl
                    }
                }
                "Re-measure power usage" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        If ($This.SourceControl.Name -eq "LaunchedMinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value -split " " | Select-Object -index 0
                            $SelectedMinerAlgorithms = @(($_.Cells[1].Value -split " {" | Select-Object -Index 1) -split " & " -replace "{", "" -replace "@.+", "")
                        }
                        ElseIf ($This.SourceControl.Name -eq "MinersDGV") { 
                            $SelectedMinerName = $_.Cells[0].Value
                            $SelectedMinerAlgorithms = @($_.Cells[6].Value -split " & ")
                        }
                        $Variables.Miners | Where-Object { $_.Name -EQ $SelectedMinerName } | Where-Object { [String]$_.Algorithms -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                            If ($_.Earning -eq 0) { $_.Available = $true }
                            If ($Variables.CalculatePowerCost) { 
                                $_.MeasurePowerUsage = $true
                                $_.Activated = 0 # To allow 3 attempts
                            }
                            $_.PowerUsage = [Double]::NaN
                            $Stat_Name = "$($_.Name)$(If ($_.Algorithms.Count -eq 1) { "_$($_.Algorithms)" })"
                            $Data += "`n$Stat_Name"
                            Remove-Stat -Name "$($Stat_Name)_PowerUsage"
                            $_.PowerUsage = $_.PowerCost = $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = [Double]::NaN
                            If ($_.Status -eq "Disabled") { $_.Status = "Idle" }
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        Write-Message -Level Verbose "GUI: Re-measure power usage triggered for $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                        $Data += "`n`n$(If ($Data.Count -eq 1) { "The miner" } Else { "$($Data.Count) miners" }) will re-measure power usage."
                        Update-TabControl
                    }
                }
                "Mark as failed" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        If ($This.SourceControl.Name -eq "LaunchedMinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value -split " " | Select-Object -index 0
                            $SelectedMinerAlgorithms = @(($_.Cells[1].Value -split " {" | Select-Object -index 1) -split " & " -replace "{", "" -replace "@.+", "")
                        }
                        ElseIf ($This.SourceControl.Name -eq "MinersDGV") { 
                            $SelectedMinerName = $SelectedMiner.Cells[0].Value
                            $SelectedMinerAlgorithms = @($SelectedMiner.Cells[6].Value -split " & ")
                        }
                        $Variables.Miners | Where-Object { $_.Name -EQ $SelectedMinerName } | Where-Object { [String]$_.Algorithms -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                            If ($Parameters.Value -le 0 -and $Parameters.Type -eq "Hashrate") { $_.Available = $false; $_.Disabled = $true }
                            $Data += "`n$($_.Name) ($($_.Algorithms -join " & "))"
                            ForEach ($Algorithm in $_.Algorithms) { 
                                $Stat_Name = "$($_.Name)_$($Algorithm)_$($Parameters.Type)"
                                If ($Parameters.Value -eq 0) { # Miner failed
                                    Remove-Stat -Name $Stat_Name
                                    $_.Profit = $_.Profit_Bias = $_.Earning = $_.Earning_Bias = $_.Earning_Accuracy = [Double]::NaN
                                    $_.Available = $false
                                    $_.Disabled = $false
                                    $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Disabled by user" })
                                    If ($_.Reasons -notcontains "0 H/s Stat file" ) { $_.Reasons += "0 H/s Stat file" }
                                    $_.Status = [MinerStatus]::Failed
                                    Set-Stat -Name $Stat_Name -Value $Parameters.Value -FaultDetection $false | Out-Null
                                }
                            }
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        Write-Message -Level Verbose "GUI: Marked $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" }) as failed."
                        $Data += "`n`n$(If ($Data.Count -eq 1) { "The miner is" } Else { "$($Data.Count) miners are " }) marked as failed."
                        Update-TabControl
                    }
                }
                "Disable" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        If ($This.SourceControl.Name -eq "LaunchedMinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value -split " " | Select-Object -index 0
                            $SelectedMinerAlgorithms = @(($_.Cells[1].Value -split " {" | Select-Object -index 1) -split " & " -replace "{", "" -replace "@.+", "")
                        }
                        ElseIf ($This.SourceControl.Name -eq "MinersDGV") { 
                            $SelectedMinerName = $SelectedMiner.Cells[0].Value
                            $SelectedMinerAlgorithms = @($SelectedMiner.Cells[6].Value -split " & ")
                        }
                        $Variables.Miners | Where-Object { $_.Name -EQ $SelectedMinerName } | Where-Object { [String]$_.Algorithms -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                            $Data += "`n$($_.Name) ($($_.Algorithms -join " & "))"
                            ForEach ($Worker in $_.Workers) { 
                                Disable-Stat -Name "$($_.Name)_$($Worker.Pool.Algorithm)_Hashrate"
                                $Worker.Hashrate = [Double]::NaN
                            }
                            $_.Disabled = $true
                            $_.Reasons += "Disabled by user"
                            $_.Reasons = $_.Reasons | Sort-Object -Unique
                            $_.Available = $false
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        Write-Message -Level Verbose "GUI: Disabled $($Data.Count) $(If ($Data.Count -eq 1) { "miner" } Else { "miners" })."
                        $Data += "`n`n$(If ($Data.Count -eq 1) { "The miner is" } Else { "$($Data.Count) miners are " }) disabled."
                        Update-TabControl
                    }
                }
                "Remove Watchdog" { 
                    $Counter = 0
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        If ($This.SourceControl.Name -eq "LaunchedMinersDGV") { 
                            $SelectedMinerName = $_.Cells[1].Value -split " " | Select-Object -index 0
                            $SelectedMinerAlgorithms = @(($_.Cells[1].Value -split " {" | Select-Object -index 1) -split " & " -replace "{", "" -replace "@.+", "")
                        }
                        ElseIf ($This.SourceControl.Name -eq "MinersDGV") { 
                            $SelectedMinerName = $_.Cells[0].Value
                            $SelectedMinerAlgorithms = @($_.Cells[6].Value -split " & ")
                        }
                        If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -EQ $SelectedMinerName | Where-Object { $_.Algorithm -in $SelectedMinerAlgorithms })) {
                            ForEach ($WatchdogTimer in $WatchdogTimers) { 
                                # Remove Watchdog timers
                                $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $Watchdog -notin $WatchdogTimers })
                                $Data += "`n$($WatchdogTimer.MinerName) {$($WatchdogTimer.Algorithm -join ', ')}"
                                # Update miner
                                $Variables.Miners | Where-Object Name -EQ $electedMinerName | Where-Object { [String]$_.Algorithm -eq [String]$SelectedMinerAlgorithms } | ForEach-Object { 
                                    $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Miner suspended by watchdog *" })
                                    If (-not $_.Reasons) { $_.Available = $true }
                                }
                            }
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($WatchdogTimers) { 
                        $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "watchdog timer" } Else { "watchdog timers" }) removed."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data += "`n`n$Message"
                    }
                    Else { 
                        $Data = "No matching watchdog timers found."
                    }
                }
            }
        }
        ElseIf ($This.SourceControl.Name -match "PoolsDGV") { 
            Switch ($_.ClickedItem.Text) { 
                "Enable Algorithm @ Pool" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        $SelectedPoolName = $_.Cells[5].Value
                        $SelectedPoolAlgorithm = $_.Cells[0].Value
                        $Variables.Pools | Where-Object Name -EQ $SelectedPoolName | Where-Object Algorithm -EQ $SelectedPoolAlgorithm | ForEach-Object { 
                            $Stat_Name = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                            $Data += "`n$($Stat_Name)"
                            Enable-Stat -Name "$($Stat_Name)_Profit"
                            $_.Disabled = $false
                            $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Disabled by user" } | Sort-Object -Unique)
                            If (-not $_.Reasons) { $_.Available = $true }
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "Pool" } Else { "pools" }) enabled."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data += "`n`n$Message"
                        Update-TabControl
                    }
                }
                "Disable Algorithm @ Pool" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        $SelectedPoolName = $_.Cells[5].Value
                        $SelectedPoolAlgorithm = $_.Cells[0].Value
                        $Variables.Pools | Where-Object Name -EQ $SelectedPoolName | Where-Object Algorithm -EQ $SelectedPoolAlgorithm | ForEach-Object { 
                            $Stat_Name = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                            $Data += "`n$($Stat_Name)"
                            Disable-Stat -Name "$($Stat_Name)_Profit"
                            $_.Disabled = $false
                            $_.Reasons += "Disabled by user"
                            $_.Reasons = $_.Reasons | Sort-Object -Unique
                            $_.Available = $false
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "Pool" } Else { "pools" }) disabled."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data += "`n`n$Message"
                        Update-TabControl
                    }
                }
                "Reset Pool Stat Data" { 
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        $SelectedPoolName = $_.Cells[5].Value
                        $SelectedPoolAlgorithm = $_.Cells[0].Value
                        $Variables.Pools | Where-Object Name -EQ $SelectedPoolName | Where-Object Algorithm -EQ $SelectedPoolAlgorithm | ForEach-Object { 
                            $Stat_Name = "$($_.Name)_$($_.Algorithm)$(If ($_.Currency) { "-$($_.Currency)" })"
                            $Data += "`n$($Stat_Name)"
                            Remove-Stat -Name "$($Stat_Name)_Profit"
                            $_.Reasons = [String[]]@()
                            $_.Price = $_.Price_Bias = $_.StablePrice = $_.Accuracy = [Double]::Nan
                            $_.Available = $true
                            $_.Disabled = $false
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($Data) { 
                        $Message = "Reset pool stats for $($Data.Count) $(If ($Data.Count -eq 1) { "pool" } Else { "pools" })."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data += "`n`n$Message"
                        Update-TabControl
                    }
                }
                "Remove Watchdog" { 
                    $Counter = 0
                    $This.SourceControl.SelectedRows | ForEach-Object { 
                        $SelectedPoolName = $_.Cells[5].Value
                        $SelectedPoolAlgorithm = $_.Cells[0].Value
                        If ($WatchdogTimers = @($Variables.WatchdogTimers | Where-Object MinerName -EQ $SelectedPoolName | Where-Object Algorithm -EQ $SelectedPoolAlgorithm )) {
                            ForEach ($WatchdogTimer in $WatchdogTimers) { 
                                # Remove Watchdog timers
                                $Variables.WatchdogTimers = @($Variables.WatchdogTimers | Where-Object { $Watchdog -notin $WatchdogTimers })
                                $Data += "`n$($WatchdogTimer.PoolName) {$($WatchdogTimer.Algorithm -join ', ')}"
                                # Update pool
                                $Variables.Pools | Where-Object Name -EQ $SelectedPoolName | Where-Object Algorithm -EQ $SelectedPoolAlgorithm | ForEach-Object { 
                                    $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Algorithm@Pool suspended by watchdog" })
                                    $_.Reasons = @($_.Reasons | Where-Object { $_ -notlike "Pool suspended by watchdog*" })
                                    If (-not $_.Reasons) { $_.Available = $true }
                                }
                            }
                        }
                    }
                    $ContextMenuStrip.Visible = $false
                    If ($WatchdogTimers) { 
                        $Message = "$($Data.Count) $(If ($Data.Count -eq 1) { "watchdog timer" } Else { "watchdog timers" }) removed."
                        Write-Message -Level Verbose "GUI: $Message"
                        $Data += "`n`n$Message"
                    }
                    Else { 
                        $Data = "No matching watchdog timers found."
                    }
                }
            }
        }

        If ($Data.Count -ge 1) { [Void] [System.Windows.Forms.MessageBox]::Show([String]$Data, "$($Variables.Branding.ProductLabel) $($_.ClickedItem.Text)", [System.Windows.Forms.MessageBoxButtons]::OK) }
    }
)
