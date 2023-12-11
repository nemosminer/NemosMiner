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
Version:        5.0.2.2
Version date:   2023/12/11
#>

using module ..\Includes\Include.psm1

# Start transcript log
If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$BrainName = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$PoolObjects = @()
$APICallFails = 0
$Durations = [TimeSpan[]]@()
$BrainDataFile = "$PWD\Data\BrainData_$BrainName.json"

$Headers = @{ "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8";"Cache-Control"="no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While ($PoolConfig = $Config.PoolsConfig.$BrainName) { 

    $StartTime = [DateTime]::Now

    Try { 

        Write-Message -Level Debug "Brain '$BrainName': Start loop$(If ($Duration) { " (Previous loop duration: $Duration sec. / Avg. loop duration: $(($Durations | Measure-Object -Average | Select-Object -ExpandProperty Average)) sec.)" })"

        Do {
            Try { 
                $AlgoData = Invoke-RestMethod -Uri $PoolConfig.PoolStatusUri -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPITimeout
                $APICallFails = 0
            }
            Catch { 
            }
            If ($AlgoData.PSObject.Properties.Name.Count -lt 2) { 
                If ($APICallFails -lt $PoolConfig.PoolAPIAllowedFailureCount) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * $PoolConfig.PoolAPIRetryInterval)))
            }
        } While ($AlgoData.PSObject.Properties.Name.Count -lt 2)

        $Timestamp = ([DateTime]::Now).ToUniversalTime()

        # Change numeric string to numbers, some values are null
        $AlgoData = ($AlgoData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

        ForEach ($Algo in $AlgoData.PSObject.Properties.Name) { 
            $BasePrice = If ($AlgoData.$Algo.actual_last24h) { $AlgoData.$Algo.actual_last24h } Else { $AlgoData.$Algo.estimate_last24h }

            $AlgoData.$Algo | Add-Member Updated $Timestamp -Force

            $PoolObjects += [PSCustomObject]@{ 
                actual_last24h      = $BasePrice
                Date                = $Timestamp
                estimate_current    = $AlgoData.$Algo.estimate_current
                estimate_last24h    = $AlgoData.$Algo.estimate_last24h
                Last24hDrift        = $AlgoData.$Algo.estimate_current - $BasePrice
                Last24hDriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                Last24hDriftSign    = If ($AlgoData.$Algo.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                Name                = $Algo
            }
        }
        Remove-Variable Algo, BasePrice -ErrorAction Ignore

        # Created here for performance optimization, minimize # of lookups
        $CurPoolObjects = $PoolObjects.Where({ $_.Date -eq $Timestamp })
        $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
        $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
        $GroupAvgSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
        $GroupMedSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
        $GroupAvgSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
        $GroupMedSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
        $GroupMedSampleSizeNoPercent = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDrift } }

        ForEach ($PoolName in (($PoolObjects.Name | Select-Object -Unique).Where({ $_ -in $AlgoData.PSObject.Properties.Name }))) { 
            $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $PoolName + ", Up" }).Count - ($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $PoolName }).Count)) * [Math]::abs(($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $PoolName }).Median)
            $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $PoolName + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $PoolName }).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent | Where-Object { $_.Name -eq $PoolName }).Median)
            $Penalty = ($PenaltySampleSizeHalf * $PoolConfig.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($PoolConfig.BrainConfig.SampleHalfPower + 1)
            $Price = [Math]::max(0, [Double]($Penalty + $CurPoolObjects.Where({ $_.Name -eq $PoolName }).actual_last24h))
            $AlgoData.$PoolName | Add-Member Plus_Price $Price -Force
        }
        Remove-Variable CurAlgoObjects, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PoolName, Price, SampleSizets, SampleSizeHalfts

        If ($PoolConfig.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
            ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
        }

        $Variables.BrainData.Remove($BrainName)
        $Variables.BrainData.$BrainName = $AlgoData
        $Variables.Brains.$BrainName["Updated"] = $Timestamp

        # Limit to only sample size + 10 minutes history
        $PoolObjects = @($PoolObjects.Where({ $_.Date -ge $Timestamp.AddMinutes( - ($PoolConfig.BrainConfig.SampleSizeMinutes + 10)) }))
    }
    Catch { 
        Write-Message -Level Error "Error in file $(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\") line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting brain..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Brain_$($BrainName)_Error.txt"
        $_.Exception | Format-List -Force >> "Logs\Brain_$($BrainName)_Error.txt"
        $_.InvocationInfo | Format-List -Force >> "Logs\Brain_$($BrainName)_Error.txt"
    }

    $Duration = ([DateTime]::Now - $StartTime).TotalSeconds
    $Durations += ($Duration, $Variables.Interval | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)
    $Durations = @($Durations | Select-Object -Last 20)
    $DurationsAvg = ([Int]($Durations | Measure-Object -Average | Select-Object -ExpandProperty Average) + 3)

    Write-Message -Level Debug "Brain '$BrainName': End loop (Duration $Duration sec.); found $($Variables.BrainData.$BrainName.PSObject.Properties.Name.Count) valid pools."

    Remove-Variable CurrenciesData, Duration -ErrorAction Ignore

    While ($Timestamp -ge $Variables.MinerDataCollectedTimeStamp -or (([DateTime]::Now).ToUniversalTime().AddSeconds($DurationsAvg) -le $Variables.EndCycleTime -and ([DateTime]::Now).ToUniversalTime() -lt $Variables.EndCycleTime)) { 
        Start-Sleep -Seconds 1
    }

    $Error.Clear()
}