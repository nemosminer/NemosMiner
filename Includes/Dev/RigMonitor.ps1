using module .\Include.psm1

<#
Copyright (c) 2018 Nemos, MrPlus & UselessGuru
BalancesTrackerJob.ps1 Written by MrPlusGH https://github.com/MrPlusGH & UseLessGuru

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
Product:        NemosMiner
File:           RigMonitor.ps1
Version:        4.2.1.0
Version date:   02 September 2022
#>


# Start transcript log
If ($Config.Transcript) { Start-Transcript -Path ".\Logs\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_-$(Get-Date -Format "yyyy-MM-dd").log" -Append -Force | Out-Null }

(Get-Process -Id $PID).PriorityClass = "BelowNormal"

Write-Message -Level Info "Rig Monitor started."

While ($true) { 

    $Now = (Get-Date).ToLocalTime()

    If ($Config.RigMonitorPollInterval -and $Config.MonitoringUser -and $Config.MonitoringServer) { 

        If ($Variables.MiningStatus -ne "Running") { Update-MonitoringData }
        Read-MonitoringData
    }

    # Sleep until next update (at least 5 minute, maximum 60 minutes)
    While ((Get-Date).ToLocalTime() -le $Now.AddMinutes((60, (1, [Int]($Config.RigMonitorPollInterval) | Measure-Object -Maximum).Maximum | Measure-Object -Minimum).Minimum)) { Start-Sleep -Seconds 60 }
}

Write-Message -Level Info "Rig Monitor stopped."