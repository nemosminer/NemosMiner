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
File:           MiningDutch.ps1
Version:        4.3.4.9
Version date:   21 May 2023
#>

using module ..\Includes\Include.psm1

$Global:ProgressPreference = "Ignore"
$Global:InformationPreference = "Ignore"

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$BrainName = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$AlgoObject = @()
$APICallFails = 0
$Durations = [System.Collections.Generic.List[Double]]@()
$TransferFile = "$($PWD)\Data\BrainData_$($BrainName).json"

$Headers = @{ "Accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8";"Cache-Control"="no-cache" }
$Useragent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36"

$ProgressPreference = "SilentlyContinue"

# Fix TLS Version erroring
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

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
                $APICallFails ++
                Start-Sleep -Seconds ([Math]::max(300, ($APICallFails * $BrainConfig.PoolAPIRetryInterval)))
            }
        } While (-not $AlgoData -or $AlgoData.message)

        $CurDate = (Get-Date).ToUniversalTime()

        # Change numeric string to numbers, some values are null
        $AlgoData = ($AlgoData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json
        $CurrenciesData = ($CurrenciesData | ConvertTo-Json) -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

        ForEach ($Algo in $AlgoData.PSObject.Properties.Name) { 
            $BasePrice = If ($AlgoData.$Algo.actual_last24h) { $AlgoData.$Algo.actual_last24h } Else { $AlgoData.$Algo.estimate_last24h }

            $AlgoObject += [PSCustomObject]@{ 
                actual_last24h     = $BasePrice
                Currency           = ""
                Date               = $CurDate
                estimate_current   = $AlgoData.$Algo.estimate_current
                estimate_last24h   = $AlgoData.$Algo.estimate_last24h
                Fees               = $AlgoData.$Algo.fees
                Hashrate           = $AlgoData.$Algo.hashrate
                hashrate_last24h   = $AlgoData.$Algo.hashrate_last24h
                Last24Drift        = $AlgoData.$Algo.estimate_current - $BasePrice
                Last24DriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                Last24DriftSign    = If ($AlgoData.$Algo.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                Name               = $Algo
                Port               = $AlgoData.$Algo.port
                Workers            = $AlgoData.$Algo.workers
            }
        }

        # Created here for performance optimization, minimize # of lookups
        $CurAlgoObject = $AlgoObject | Where-Object { $_.date -eq $CurDate }
        $SampleSizets = New-TimeSpan -Minutes $BrainConfig.SampleSizeMinutes
        $SampleSizeHalfts = New-TimeSpan -Minutes ($BrainConfig.SampleSizeMinutes / 2)
        $GroupAvgSampleSize = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name, Last24DriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
        $GroupMedSampleSize = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
        $GroupAvgSampleSizeHalf = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name, Last24DriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
        $GroupMedSampleSizeHalf = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24DriftPercent } }
        $GroupMedSampleSizeNoPercent = $AlgoObject | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24DriftPercent | Measure-Object -Average).Average } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24Drift } }

        ForEach ($Name in ($AlgoObject.Name | Select-Object -Unique)) { 
            Try { 
                $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Median)
                $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $Name }).Count)) * [math]::abs(($GroupMedSampleSizeNoPercent | Where-Object { $_.Name -eq $Name }).Median)
                $Penalty = ($PenaltySampleSizeHalf * $BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($BrainConfig.SampleHalfPower + 1)
                $Price = [math]::max(0, [Double]($Penalty + ($CurAlgoObject | Where-Object { $_.Name -eq $Name }).actual_last24h))
                $AlgoData.$Name | Add-Member @{ Plus_Price = $Price } -Force
            }
            Catch { }
        }

        $AlgoData.PSObject.Properties.Name | ForEach-Object { $AlgoData.$_ | Add-Member Updated $CurDate -Force }

        If ($BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
            ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Out-File -FilePath $TransferFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
        }
        $Variables.BrainData | Add-Member $BrainName $AlgoData -Force
        $Variables.Brains.$BrainName."Updated" = $CurDate

        # Limit to only sample size + 10 minutes min history
        $AlgoObject = @($AlgoObject | Where-Object { $_.Date -ge $CurDate.AddMinutes(-($BrainConfig.SampleSizeMinutes + 10)) })

        If ($Config.PoolsConfig.$BrainName.BrainDebug) { 
            Write-Message -Level Debug ("Brain '$($BrainName)': AlgoObject size {0:n0} Bytes" -f ($AlgoObject | ConvertTo-Json -Compress).length)
            Write-Message -Level Debug "Brain '$($BrainName)': $(Get-MemoryUsage)"
        }

        $Duration = (Get-Date) - $StartTime
        $Durations.Add($Duration.TotalSeconds)
        $Durations = [System.Collections.Generic.List[Double]]@($Durations | Select-Object -Last 100)

        Remove-Variable Algo, AlgoData, Name -ErrorAction Ignore

        $Error.Clear()
        [System.GC]::GetTotalMemory($true) | Out-Null

        Write-Message -Level Debug "Brain '$($BrainName)': $(Get-MemoryUsage)"
        Write-Message -Level Debug "Brain '$($BrainName)': End loop (Duration $($Duration.TotalSeconds) sec.)"
    }
    Catch { 
        Write-Message -Level Error "Error in file $(($_.InvocationInfo.ScriptName -Split "\\" | Select-Object -Last 2) -join "\") line $($_.InvocationInfo.ScriptLineNumber) detected. Restarting brain..."
        "$(Get-Date -Format "yyyy-MM-dd_HH:mm:ss")" >> "Logs\Error.txt"
        $_.Exception | Format-List -Force >> "Logs\Error.txt"
        $_.InvocationInfo | Format-List -Force >> "Logs\Error.txt"
    }
    While ($CurDate -ge $Variables.PoolDataCollectedTimeStamp -or (Get-Date).ToUniversalTime().AddSeconds([Int]($Durations | Measure-Object -Average).Average + 3) -le $Variables.EndCycleTime) { 
        Start-Sleep -Seconds 1
    }
}