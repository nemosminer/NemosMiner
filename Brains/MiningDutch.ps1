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
File:           \Brains\MiningDutch.ps1
Version:        4.3.6.0
Version date:   31 July 2023
#>

using module ..\Includes\Include.psm1

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$BrainName = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$AlgoObjects = @()
$APICallFails = 0
$Durations = [TimeSpan[]]@()
$BrainDataFile = "$($PWD)\Data\BrainData_$($BrainName).json"

$Headers = @{ "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8";"Cache-Control"="no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While ($BrainConfig = $Config.PoolsConfig.$BrainName.BrainConfig) { 
    Try { 
        $StartTime = Get-Date

        Write-Message -Level Debug "Brain '$($BrainName)': Start loop$(If ($Duration) { " (Previous loop duration: $($Duration.TotalSeconds) sec. / Avg. loop duration: $(($Durations | Measure-Object -Average).Average))" })"

        Do {
            Try { 
                $AlgoData = Invoke-RestMethod -Uri $BrainConfig.PoolStatusUri -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -TimeoutSec $BrainConfig.PoolAPITimeout
                If ($AlgoData.message) { # Only 1 request every 10 seconds allowed
                    $APICallFails ++
                    Start-Sleep -Seconds $BrainConfig.PoolAPIRetryInterval
                }
                Else { 
                    $APICallFails = 0
                }
            }
            Catch { 
                If ($APICallFails -lt 5) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * $BrainConfig.PoolAPIRetryInterval)))
            }
        } While (-not $AlgoData -or $AlgoData.message)

        $CurDate = (Get-Date).ToUniversalTime()

        # Change numeric string to numbers, some values are null
        $AlgoData = ($AlgoData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json
        $CurrenciesData = ($CurrenciesData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

        ForEach ($Algo in $AlgoData.PSObject.Properties.Name) { 
            $BasePrice = If ($AlgoData.$Algo.actual_last24h) { $AlgoData.$Algo.actual_last24h } Else { $AlgoData.$Algo.estimate_last24h }

            $AlgoData.$Algo | Add-Member Updated $CurDate -Force

            $AlgoObjects += [PSCustomObject]@{ 
                actual_last24h      = $BasePrice
                Currency            = ""
                Date                = $CurDate
                estimate_current    = $AlgoData.$Algo.estimate_current
                estimate_last24h    = $AlgoData.$Algo.estimate_last24h
                Fees                = $AlgoData.$Algo.fees
                Last24hDrift        = $AlgoData.$Algo.estimate_current - $BasePrice
                Last24hDriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                Last24hDriftSign    = If ($AlgoData.$Algo.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                Name                = $Algo
                Port                = $AlgoData.$Algo.port
                Workers             = $AlgoData.$Algo.workers
            }
        }

        # Created here for performance optimization, minimize # of lookups
        $CurAlgoObjects = $AlgoObjects | Where-Object { $_.Date -eq $CurDate }
        $SampleSizets = New-TimeSpan -Minutes $BrainConfig.SampleSizeMinutes
        $SampleSizeHalfts = New-TimeSpan -Minutes ($BrainConfig.SampleSizeMinutes / 2)
        $GroupAvgSampleSize = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupMedSampleSize = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupAvgSampleSizeHalf = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupMedSampleSizeHalf = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupMedSampleSizeNoPercent = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDrift } }

        ForEach ($Name in ($AlgoObjects.Name | Select-Object -Unique)) { 
            Try { 
                $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Count)) * [Math]::abs(($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Median)
                $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $Name }).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent | Where-Object { $_.Name -eq $Name }).Median)
                $Penalty = ($PenaltySampleSizeHalf * $BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($BrainConfig.SampleHalfPower + 1)
                $Price = [Math]::max(0, [Double]($Penalty + ($CurAlgoObjects | Where-Object { $_.Name -eq $Name }).actual_last24h))
                $AlgoData.$Name | Add-Member Plus_Price $Price -Force
            }
            Catch { }
        }

        If ($BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
            ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -FilePath $BrainDataFile -Force -Encoding utf8NoBOM  -ErrorAction Ignore
        }

        $Variables.BrainData.$BrainName = $AlgoData
        $Variables.Brains.$BrainName["Updated"] = $CurDate

        # Limit to only sample size + 10 minutes min history
        $AlgoObjects = @($AlgoObjects | Where-Object Date -GE $CurDate.AddMinutes( - ($BrainConfig.SampleSizeMinutes + 10)))

        $Duration = ((Get-Date) - $StartTime).TotalSeconds
        $Durations += ($Duration, $Variables.Interval | Measure-Object -Minimum).Minimum
        $Durations = @($Durations | Select-Object -Last 20)

        Remove-Variable Algo, AlgoData, Name -ErrorAction Ignore
    }
    Catch { 
        Write-Message -Level Error "Error in file $(($_.InvocationInfo.ScriptName -Split "\\" | Select-Object -Last 2) -join "\") line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting brain..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Error.txt"
        $_.Exception | Format-List -Force >> "Logs\Error.txt"
        $_.InvocationInfo | Format-List -Force >> "Logs\Error.txt"
    }

    $Error.Clear()
    #[System.GC]::Collect()

    Write-Message -Level Debug "Brain '$($BrainName)': End loop (Duration $($Duration.TotalSeconds) sec.)"

    While ($CurDate -ge $Variables.PoolDataCollectedTimeStamp -or (Get-Date).ToUniversalTime().AddSeconds([Int]($Durations | Measure-Object -Average).Average + 3) -le $Variables.EndCycleTime) { 
        Start-Sleep -Seconds 1
    }
}