<#
Copyright (c) 2018-2020 Nemo, MrPlus & UselessGuru
Charting.ps1 File Written By MrPlusGH https://github.com/MrPlusGH & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:          NemosMiner
File:             Charting.ps1
version:          3.9.9.8
version date:     18 December 2020
#>

param(
    [Parameter(Mandatory = $true)]
    [String]$ChartType = "", 
    [Parameter(Mandatory = $true)]
    [String]$Width = 700, 
    [Parameter(Mandatory = $true)]
    [String]$Height = 85 
)

[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
$ScriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition

# Defined Charts list
# Front7DaysEarnings
# FrontDayEarningsPoolSplit
# DayPoolSplit

$Currency = If ("m$($Config.PayoutCurrency)" -in $Config.Currency) { "m$($Config.PayoutCurrency)" } Else { $Config.PayoutCurrency }

Switch ($ChartType) {
    "Front7DaysEarnings" {
        $Datasource = If (Test-Path ".\Logs\DailyEarnings.csv" ) { Import-Csv ".\logs\DailyEarnings.csv" | Where-Object { [DateTime]::parseexact($_.Date, "yyyy-MM-dd", $null) -le (Get-Date).AddDays(-1) } }
        $Datasource | ForEach-Object { $_.Date = [DateTime]::parseexact($_.Date, "yyyy-MM-dd", $null) }
        $RelevantDates = $Datasource.Date | Sort-Object -Unique | Select-Object -Last 7
        $Datasource = $Datasource | Where-Object { $_.Date -in $RelevantDates } | Select-Object *, @{ Name = "DaySum"; Expression = { $Date = $_.Date; (($Datasource | Where-Object { $_.Date -eq $Date }).DailyEarnings | Measure-Object -sum).sum } }

        $Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $Chart.Width = $Width
        $Chart.Height = $Height
        $Chart.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240) #"#F0F0F0"

        $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $ChartTitle.Text = ("Earnings Tracker: Earnings of the past 7 active days")
        $ChartTitle.Font = [System.Drawing.Font]::new("Arial", 10)
        $ChartTitle.Alignment = "TopCenter"
        $Chart.Titles.Add($ChartTitle)

        $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        $ChartArea.Name = "ChartArea1"
        $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(255, 32, 50, 50) #"#2B3232"
        $ChartArea.BackSecondaryColor = [System.Drawing.Color]::FromArgb(255, 119, 126, 126) #"#777E7E"
        $ChartArea.BackGradientStyle = 3
        $ChartArea.AxisX.labelStyle.Enabled = $false
        $ChartArea.AxisX.Enabled = 2
        $ChartArea.AxisX.MajorGrid.Enabled = $false
        $ChartArea.AxisY.MajorGrid.Enabled = $true
        $ChartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#FFFFFF"
        $ChartArea.AxisY.labelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
        $ChartArea.AxisY.Interval = [Math]::Round(($Datasource | Group-Object Date | ForEach-Object { ($_.group.DailyEarnings | Measure-Object -sum).sum } | Measure-Object -maximum).maximum * 1000 / 4, 3)
        $Chart.ChartAreas.Add($ChartArea)

        [void]$Chart.Series.Add("TotalEarning")
        $Chart.Series["TotalEarning"].ChartType = "Column"
        $Chart.Series["TotalEarning"].BorderWidth = 3
        $Chart.Series["TotalEarning"].ChartArea = "ChartArea1"
        $Chart.Series["TotalEarning"].Color = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"FFFFFF"
        $Chart.Series["TotalEarning"].label = "#VALY{N3}"
        $Chart.Series["TotalEarning"].ToolTip = "#VALX: #VALY $($Currency)"
        $Datasource | Select-Object Date, DaySum -Unique | ForEach-Object { $Chart.Series["TotalEarning"].Points.addxy( $_.Date.ToShortDateString() , ("{0:N5}" -f ([Decimal]$_.DaySum * $Variables.Rates.BTC.$Currency))) | Out-Null }
    }
    "Front7DaysEarningsWithPoolSplit" {
        $Datasource = If (Test-Path ".\Logs\DailyEarnings.csv" ) { Import-Csv ".\logs\DailyEarnings.csv" | Where-Object { [DateTime]::parseexact($_.Date, "yyyy-MM-dd", $null) -le (Get-Date).AddDays(-1) } }
        $Datasource | ForEach-Object { $_.Date = [DateTime]::parseexact($_.Date, "yyyy-MM-dd", $null) }
        $RelevantDates = $Datasource.Date | Sort-Object -Unique | Select-Object -Last 7
        $Datasource = $Datasource | Where-Object { $_.Date -in $RelevantDates } | Select-Object *, @{ Name = "DaySum"; Expression = { $Date = $_.Date; (($Datasource | Where-Object { $_.Date -eq $Date }).DailyEarnings | Measure-Object -sum).sum } }

        $Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $Chart.Width = $Width
        $Chart.Height = $Height
        $Chart.BackColor = [System.Drawing.Color]::FromArgb(0, 240, 240, 240) #"#F0F0F0"

        $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $ChartTitle.Text = ("Earnings Tracker: Earnings of the past 7 active days")
        $ChartTitle.Font = [System.Drawing.Font]::new("Arial", 10)
        $ChartTitle.Alignment = "TopCenter"
        $Chart.Titles.Add($ChartTitle)

        $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        $ChartArea.Name = "ChartArea1"
        $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(255, 32, 50, 50) #"#2B3232"
        $ChartArea.BackSecondaryColor = [System.Drawing.Color]::FromArgb(255, 119, 126, 126) #"#777E7E"
        $ChartArea.BackGradientStyle = 3
        $ChartArea.AxisX.labelStyle.Enabled = $false
        $ChartArea.AxisX.Enabled = 2
        $ChartArea.AxisX.MajorGrid.Enabled = $false
        $ChartArea.AxisY.MajorGrid.Enabled = $true
        $ChartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#FFFFFF"
        $ChartArea.AxisY.labelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
        $ChartArea.AxisY.Interval = [Math]::Round(($Datasource | Group-Object date | ForEach-Object { ($_.group.DailyEarnings | Measure-Object -sum).sum } | Measure-Object -maximum).maximum * $Variables.Rates.BTC.$Currency / 4, 3)
        $Chart.ChartAreas.Add($ChartArea)

        $Colors = @(255, 255, 255, 255) #"FFFFFF"

        ForEach ($Pool in ($Datasource.Pool | Sort-Object -unique)) {
            $Colors = (Get-NextColor -Colors $Colors -Factors -0, -10, -10, -10)

            [void]$Chart.Series.Add($Pool)
            $Chart.Series[$Pool].ChartType = "StackedColumn"
            $Chart.Series[$Pool].BorderWidth = 3
            $Chart.Series[$Pool].ChartArea = "ChartArea1"
            $Chart.Series[$Pool].Color = [System.Drawing.Color]::FromArgb($Colors[0], $Colors[1], $Colors[2], $Colors[3])
            $Chart.Series[$Pool].ToolTip = "#SERIESNAME: #VALY $($Currency)"
            $Datasource | Where-Object { $_.Pool -eq $Pool } | ForEach-Object { $Chart.Series[$Pool].Points.addxy( $_.Date.ToShortDateString() , ("{0:N3}" -f ([Decimal]$_.DailyEarnings * $Variables.Rates.BTC.$Currency))) | Out-Null }
        }

        [void]$Chart.Series.Add("Total")
        $Chart.Series["Total"].ChartType = "Column"
        $Chart.Series["Total"].BorderWidth = 3
        $Chart.Series["Total"].ChartArea = "ChartArea1"
        $Chart.Series["Total"].Color = [System.Drawing.Color]::FromArgb(255, 119, 126, 126) #"#777E7E"
        $Chart.Series["Total"].ToolTip = "#SERIESNAME: #VALY $($Currency)"
        $Datasource | Select-Object Date, DaySum -Unique | ForEach-Object { $Chart.Series[$Pool].Points.addxy( $_.Date , ("{0:N3}" -f ([Decimal]$_.DaySum * $Variables.Rates.BTC.$Currency))) | Out-Null }

        $Chart.Series | ForEach-Object { $_.CustomProperties = "DrawSideBySide=True" }
    }
    "DayPoolSplit" {
        $Datasource = If (Test-Path ".\logs\DailyEarnings.csv" ) { Import-Csv ".\logs\DailyEarnings.csv" | Where-Object { [DateTime]::parseexact($_.Date, "yyyy-MM-dd", $null) -eq (Get-Date).Date } }
        $Datasource = $Datasource | Where-Object { $_.DailyEarnings -gt 0 } | Sort-Object DailyEarnings -Descending

        $Chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
        $Chart.Width = $Width
        $Chart.Height = $Height
        $Chart.BackColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240) #"#F0F0F0"

        $ChartTitle = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $ChartTitle.Text = ("Todays earnings per pool")
        $ChartTitle.Font = [System.Drawing.Font]::new("Arial", 10)
        $ChartTitle.Alignment = "TopCenter"
        $Chart.Titles.Add($ChartTitle)

        $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        $ChartArea.Name = "ChartArea1"
        $ChartArea.BackColor = [System.Drawing.Color]::FromArgb(255, 32, 50, 50) #"#2B3232"
        $ChartArea.BackSecondaryColor = [System.Drawing.Color]::FromArgb(255, 119, 126, 126) #"#777E7E"
        $ChartArea.BackGradientStyle = 3
        $ChartArea.AxisX.LabelStyle.Enabled = $false
        $ChartArea.AxisX.Enabled = 2
        $ChartArea.AxisX.MajorGrid.Enabled = $false
        $ChartArea.AxisY.MajorGrid.Enabled = $true
        $ChartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255) #"#FFFFFF"
        $ChartArea.AxisY.LabelAutoFitStyle = $ChartArea.AxisY.labelAutoFitStyle - 4
        $ChartArea.AxisY.Interval = [Math]::Round(($Datasource | Group-Object date | ForEach-Object { ($_.group.DailyEarnings | Measure-Object -sum).sum } | Measure-Object -maximum).maximum * $Variables.Rates.BTC.$Currency / 4, 3)
        $Chart.ChartAreas.Add($ChartArea)

        $Colors = @(255, 255, 255, 255) #"FFFFFF"
        ForEach ($Pool in ($Datasource.Pool)) {
            $Colors = (Get-NextColor -Colors $Colors -Factors -0, -20, -20, -20)

            [void]$Chart.Series.Add($Pool)
            $Chart.Series[$Pool].ChartType = "StackedColumn"
            $Chart.Series[$Pool].BorderWidth = 1
            $Chart.Series[$Pool].BorderColor = [System.Drawing.Color]::FromArgb(255, 119, 126 ,126) #"#FFFFFF"
            $Chart.Series[$Pool].ChartArea = "ChartArea1"
            $Chart.Series[$Pool].Color = [System.Drawing.Color]::FromArgb($Colors[0], $Colors[1], $Colors[2], $Colors[3])
            $Chart.Series[$Pool].ToolTip = "#SERIESNAME: #VALY $($Currency)"
            $Datasource | Where-Object { $_.Pool -eq $Pool } | ForEach-Object { $Chart.Series[$Pool].Points.addxy( $_.Pool , ("{0:N3}" -f ([Decimal]$_.DailyEarnings * $Variables.Rates.BTC.$Currency))) | Out-Null }
        }
    }
}

$Chart
