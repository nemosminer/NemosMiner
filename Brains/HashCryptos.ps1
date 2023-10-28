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
Version:        5.0.1.6
Version date:   2023/10/28
#>

using module ..\Includes\Include.psm1

# Start transcript log
If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$BrainName = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$AlgoObjects = @()
$APICallFails = 0
$Durations = [TimeSpan[]]@()
$BrainDataFile = "$($PWD)\Data\BrainData_$($BrainName).json"

$Headers = @{ "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8";"Cache-Control"="no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

While ($PoolConfig = $Config.PoolsConfig.$BrainName) { 

    $StartTime = [DateTime]::Now

    Try { 

        Write-Message -Level Debug "Brain '$($BrainName)': Start loop$(If ($Duration) { " (Previous loop duration: $($Duration) sec. / Avg. loop duration: $(($Durations | Measure-Object -Average | Select-Object -ExpandProperty Average)) sec.)" })"

        Do {
            Try { 
                $AlgoData = Invoke-RestMethod -Uri $PoolConfig.PoolStatusUri -Headers $Headers -UserAgent $UserAgent -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPITimeout
                $APICallFails = 0
            }
            Catch { 
            }
            If ($AlgoData.PSObject.Properties.Name.Count -lt 2) { 
                If ($APICallFails -lt 5) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * $PoolConfig.PoolAPIRetryInterval)))
            }
        } While ($AlgoData.PSObject.Properties.Name.Count -lt 2)

        $CurDate = ([DateTime]::Now).ToUniversalTime()

        # Change numeric string to numbers, some values are null
        $AlgoData = ($AlgoData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

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
                Hashrate            = $AlgoData.$Algo.hashrate
                hashrate_last24h    = $AlgoData.$Algo.hashrate_last24h
                Last24hDrift        = $AlgoData.$Algo.estimate_current - $BasePrice
                Last24hDriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                Last24hDriftSign    = If ($AlgoData.$Algo.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                Name                = $Algo
                Port                = $AlgoData.$Algo.port
                Workers             = $AlgoData.$Algo.workers
            }
        }
        Remove-Variable Algo, BasePrice -ErrorAction Ignore

        # Created here for performance optimization, minimize # of lookups
        $CurAlgoObjects = $AlgoObjects | Where-Object { $_.Date -eq $CurDate }
        $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
        $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
        $GroupAvgSampleSize = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupMedSampleSize = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupAvgSampleSizeHalf = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupMedSampleSizeHalf = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupMedSampleSizeNoPercent = $AlgoObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDrift } }

        ForEach ($Name in ($AlgoObjects.Name | Select-Object -Unique)) { 
            Try { 
                $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Count)) * [Math]::abs(($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Median)
                $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $Name }).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent | Where-Object { $_.Name -eq $Name }).Median)
                $Penalty = ($PenaltySampleSizeHalf * $PoolConfig.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($PoolConfig.BrainConfig.SampleHalfPower + 1)
                $Price = [Math]::max(0, [Double]($Penalty + ($CurAlgoObjects | Where-Object { $_.Name -eq $Name }).actual_last24h))
                $AlgoData.$Name | Add-Member Plus_Price $Price -Force
            }
            Catch { }
        }
        Remove-Variable CurAlgoObjects, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, Name, Penalty, Price, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, SampleSizets, SampleSizeHalfts

        $AlgoData.PSObject.Properties.Name | ForEach-Object { $AlgoData.$_ | Add-Member Updated $CurDate -Force }

        If ($PoolConfig.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
            ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -FilePath $BrainDataFile -Force -ErrorAction Ignore
        }

        $Variables.BrainData.Remove($BrainName)
        $Variables.BrainData.$BrainName = $AlgoData
        $Variables.Brains.$BrainName["Updated"] = $CurDate

        # Limit to only sample size + 10 minutes min history
        $AlgoObjects = @($AlgoObjects | Where-Object Date -GE $CurDate.AddMinutes( - ($PoolConfig.BrainConfig.SampleSizeMinutes + 10)))
    }
    Catch { 
        Write-Message -Level Error "Error in file $(($_.InvocationInfo.ScriptName -split "\\" | Select-Object -Last 2) -join "\") line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting brain..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Error.txt"
        $_.Exception | Format-List -Force >> "Logs\Error.txt"
        $_.InvocationInfo | Format-List -Force >> "Logs\Error.txt"
    }

    $Duration = ([DateTime]::Now - $StartTime).TotalSeconds
    $Durations += ($Duration, $Variables.Interval | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum)
    $Durations = @($Durations | Select-Object -Last 20)

    Write-Message -Level Debug "Brain '$($BrainName)': End loop (Duration $($Duration) sec.); Found $($AlgoData.PSObject.Properties.Name.Count) pools."

    Remove-Variable AlgoData, Duration -ErrorAction Ignore

    While ($CurDate -ge $Variables.MinerDataCollectedTimeStamp -or ([DateTime]::Now).ToUniversalTime().AddSeconds([Int]($Durations | Measure-Object -Average | Select-Object -ExpandProperty Average) + 3) -le $Variables.EndCycleTime) { 
        Start-Sleep -Seconds 1
    }

    $Error.Clear()
}