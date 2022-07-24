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
File:           BlockMasters.ps1
Version:        4.0.2.4
Version date:   24 July 2022
#>

using module .\Includes\Include.psm1

param(
    [Parameter(Mandatory = $true)]
    [String]$BrainName,
    [Parameter(Mandatory = $true)]
    [String]$PoolVariant,
    [Parameter(Mandatory = $true)]
    [PSCustomObject]$Config
)

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$AlgoObject = @()
$APICallFails = 0
$CurrenciesData = @()
$TransferFile = "$($PWD)\Data\BrainData_$($BrainName).json"

$ProgressPreference = "SilentlyContinue"

# Fix TLS Version erroring
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

While ($Config) { 

    $CurDate = (Get-Date).ToUniversalTime()
    $RetryInterval = 0

    Do {
        Try { 
            If (-not $AlgoData) { $AlgoData = Invoke-RestMethod -Uri $Config.PoolstatusUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck }
            If (-not $CurrenciesData) { $CurrenciesData = Invoke-RestMethod -Uri $Config.PoolCurrenciesUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck }
            $APICallFails = 0
        }
        Catch { 
            $APICallFails++
            $RetryInterval = $Config.Interval * [math]::max(0, $APICallFails - $Config.AllowedAPIFailureCount)
            Start-Sleep -Seconds ($APICallFails * $Config.APIRetryInterval)
        }
    } While (-not ($AlgoData -and $CurrenciesData))

    ($CurrenciesData | Get-Member -MemberType NoteProperty).Name | ForEach-Object { $CurrenciesData.$_ | Add-Member -Force @{Symbol = If ($CurrenciesData.$_.Symbol) { $CurrenciesData.$_.Symbol -replace "-.+" } Else { $_ -replace "-.+"} } }

    ForEach ($Algo in (($AlgoData | Get-Member -MemberType NoteProperty).Name)) { 
        $Currencies = @(($CurrenciesData | Get-Member -MemberType NoteProperty).Name | Where-Object { $CurrenciesData.$_.algo -eq $Algo } | ForEach-Object { $CurrenciesData.$_ })
        $Currency = If ($Currencies.Symbol) { ($Currencies | Sort-Object Estimate)[-1].Symbol } Else { "" }
        $AlgoData.$Algo | Add-Member @{ Currency = $Currency.Trim() }

        $AlgoData.$Algo.estimate_last24h = [Double]$AlgoData.$Algo.estimate_last24h
        If ($AlgoData.$Algo.actual_last24h) { $AlgoData.$Algo.actual_last24h = [Double]($AlgoData.$Algo.actual_last24h / 1000) }
        $BasePrice = If ($AlgoData.$Algo.actual_last24h) { [Double]$AlgoData.$Algo.actual_last24h } Else { [Double]$AlgoData.$Algo.estimate_last24h }
        $AlgoData.$Algo.estimate_current = [math]::max(0, [Double]($AlgoData.$Algo.estimate_current * ( 1 - ($Config.PerAPIFailPercentPenalty * [math]::max(0, $APICallFails - $Config.AllowedAPIFailureCount) / 100))))
        $AlgoObject += [PSCustomObject]@{ 
            Date               = $CurDate
            Name               = $AlgoData.$Algo.name
            Port               = $AlgoData.$Algo.port
            coins              = $AlgoData.$Algo.coins
            Fees               = $AlgoData.$Algo.Fees
            Hashrate           = $AlgoData.$Algo.Hashrate
            Workers            = $AlgoData.$Algo.Workers
            estimate_current   = $AlgoData.$Algo.estimate_current -as [Double]
            estimate_last24h   = $AlgoData.$Algo.estimate_last24h
            actual_last24h     = $BasePrice
            hashrate_last24h   = $AlgoData.$Algo.hashrate_last24h
            Last24Drift        = $AlgoData.$Algo.estimate_current - $BasePrice
            Last24DriftSign    = If (($AlgoData.$Algo.estimate_current - $BasePrice) -ge 0) { "Up" } Else { "Down" }
            Last24DriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
            FirstDate          = $AlgoObject[0].Date
            TimeSpan           = If ($null -ne $AlgoObject.Date) { (New-TimeSpan -Start ($AlgoObject[0]).Date -End $CurDate).TotalMinutes }
        }
    }

    # Created here For performance optimization, minimize # of lookups
    $CurAlgoObject = $AlgoObject | Where-Object { $_.date -eq $CurDate }
    $SampleSizets = New-TimeSpan -Minutes $Config.SampleSizeMinutes
    $SampleSizeHalfts = New-TimeSpan -Minutes ($Config.SampleSizeMinutes / 2)
    $GroupAvgSampleSize = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name, Last24DriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupMedSampleSize = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupAvgSampleSizeHalf = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name, Last24DriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupMedSampleSizeHalf = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
    $GroupMedSampleSizeNoPercent = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24Drift } }

    ForEach ($Name in ($AlgoObject.Name | Select-Object -Unique)) { 
        $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Median)
        $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeNoPercent | Where-Object { $_.Name -eq $Name }).Median)
        $Penalty = ($PenaltySampleSizeHalf * $Config.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($Config.SampleHalfPower + 1)
        $Price = [math]::max( 0, [Double](($Penalty) + ($CurAlgoObject | Where-Object { $_.Name -eq $Name }).actual_last24h) )
        If ($Config.UseFullTrust) { 
            If ( $Penalty -gt 0 ) { 
                $Price = [Math]::max([Double]$Price, [Double]($CurAlgoObject | Where-Object { $_.Name -eq $Name }).estimate_current)
            }
            Else { 
                $Price = [Math]::min([Double]$Price, [Double]($CurAlgoObject | Where-Object { $_.Name -eq $Name }).estimate_current)
            }
        }
        $AlgoData.($Name) | Add-Member -Force @{ Plus_Price = $Price }
    }

    ($AlgoData | Get-Member -MemberType NoteProperty).Name | ForEach-Object { 
        If ([Double]($AlgoData.$_.actual_last24h) -gt 0) { 
            $AlgoData.$_ | Add-Member Updated $CurDate -Force
        }
        Else { 
            $AlgoData.PSObject.Properties.Remove($_)
        }
    }
    ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -FilePath $TransferFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue

    # Limit to only sample size + 10 minutes min history
    $AlgoObject = $AlgoObject | Where-Object { $_.Date -ge $CurDate.AddMinutes(-($Config.SampleSizeMinutes + 10)) }

    Remove-Variable AlgoData, CurrenciesData

    Start-Sleep -Seconds $Config.Interval
}
