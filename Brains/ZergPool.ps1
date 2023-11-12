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
File:           \Brains\ZergPool.ps1
Version:        5.0.2.0
Version date:   2023/11/12
#>

using module ..\Includes\Include.psm1

# Start transcript log
If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$BrainName = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$CurrencyObjects = @()
$APICallFails = 0
$CurrenciesData = @()
$Durations = [TimeSpan[]]@()
$BrainDataFile = "$($PWD)\Data\BrainData_$($BrainName).json"

While ($PoolConfig = $Config.PoolsConfig.$BrainName) { 

    $StartTime = [DateTime]::Now

    Try { 

        Write-Message -Level Debug "Brain '$($BrainName)': Start loop$(If ($Duration) { " (Previous loop duration: $($Duration) sec. / Avg. loop duration: $(($Durations | Measure-Object -Average | Select-Object -ExpandProperty Average)) sec.)" })"

        Do {
            Try { 
                $CurrenciesData = Invoke-RestMethod -Uri $PoolConfig.PoolCurrenciesUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPITimeout
                $APICallFails = 0
            }
            Catch { 
                If ($APICallFails -lt 5) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * $PoolConfig.PoolAPIRetryInterval)))
            }
        } While (-not $CurrenciesData.PSObject.Properties.Name)

        $CurDate = ([DateTime]::Now).ToUniversalTime()

        $CurrenciesData.PSObject.Properties.Name | Where-Object { ($CurrenciesData.$_.noautotrade -and $CurrenciesData.$_.symbol -ne $PayoutCurreny) -or $CurrenciesData.$_.algo -eq "Token" -or $_ -like "*-*" } | ForEach-Object { $CurrenciesData.PSObject.Properties.Remove($_) }
        $CurrenciesData.PSObject.Properties.Name | Where-Object { $CurrenciesData.$_.algo } | ForEach-Object { 
            $CurrenciesData.$_ | Add-Member @{ Currency = If ($CurrenciesData.$_.symbol) { $CurrenciesData.$_.symbol } Else { $_ } } -Force
            $CurrenciesData.$_ | Add-Member @{ CoinName = If ($CurrenciesData.$_.name) { $CurrenciesData.$_.name } Else { $_ } } -Force
            $CurrenciesData.$_.PSObject.Properties.Remove("symbol")
            $CurrenciesData.$_.PSObject.Properties.Remove("name")
        }

        # Change last24: -> last24h: (Error in API?), numeric string to numbers, some values are null
        $CurrenciesData = ($CurrenciesData | ConvertTo-Json) -replace '_last24":', 'last24h":' -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

        ForEach ($Currency in $CurrenciesData.PSObject.Properties.Name) { 
            $CurrenciesData.$Currency.actual_last24h_shared = $CurrenciesData.$Currency.actual_last24h_shared / 1000
            $BasePrice = If ($CurrenciesData.$Currency.actual_last24h_shared) { $CurrenciesData.$Currency.actual_last24h_shared } Else { $CurrenciesData.$Currency.estimate_last24h }

            # Add coin name
            If ($CurrenciesData.$Currency.CoinName) { 
                Try { 
                    [Void](Add-CoinName -Algorithm $Currency -Currency $Currency -CoinName $CurrenciesData.$Currency.CoinName)
                }
                Catch { }
            }

            # Keep DAG data up to date
            If ($Currency -match $Variables.RegexAlgoHasDAG -and $CurrenciesData.$Currency.height -gt $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                If ($Variables.DAGdata.Currency) { 
                    $DAGdata = (Get-DAGData -Blockheight $CurrenciesData.$Currency.height -Currency $Currency -EpochReserve 2)
                    $DAGdata.Date = ([DateTime]::Now).ToUniversalTime()
                    $DAGdata.Url = $PoolConfig.PoolCurrenciesUri
                    $Variables.DAGdata.Currency[$Currency] = $DAGdata
                    $Variables.DAGdata.Updated[$PoolConfig.PoolCurrenciesUri] = ([DateTime]::Now).ToUniversalTime()
                }
            }

            $CurrenciesData.$Currency | Add-Member Fees $Config.PoolsConfig.$BrainName.DefaultFee -Force
            $CurrenciesData.$Currency | Add-Member Updated $CurDate -Force

            $CurrencyObjects += [PSCustomObject]@{
                actual_last24h      = $BasePrice
                Currency            = $Currency
                Date                = $CurDate
                estimate_current    = $CurrenciesData.$Currency.estimate_current
                estimate_last24h    = $CurrenciesData.$Currency.estimate_last24h
                Fees                = $CurrenciesData.$Currency.fees
                Hashrate            = $CurrenciesData.$Currency.hashrate
                hashrate_last24h    = $CurrenciesData.$Currency.hashrate_last24h_shared
                Last24hDrift        = $CurrenciesData.$Currency.estimate_current - $BasePrice
                Last24hDriftPercent = If ($BasePrice -gt 0) { ($CurrenciesData.$Currency.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                Last24hDriftSign    = If ($CurrenciesData.$Currency.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                Name                = $Currency
                Port                = $CurrenciesData.$Currency.port
                Workers             = $CurrenciesData.$Currency.Workers
            }
        }
        Remove-Variable BasePrice, BestCurrency, Currencies, Currency, DAGdata -ErrorAction Ignore

        # Created here for performance optimization, minimize # of lookups
        $CurAlgoObjects = $CurrencyObjects | Where-Object { $_.Date -eq $CurDate }
        $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
        $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
        $GroupAvgSampleSize = $CurrencyObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupMedSampleSize = $CurrencyObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupAvgSampleSizeHalf = $CurrencyObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupMedSampleSizeHalf = $CurrencyObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizeHalfts) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDriftPercent } }
        $GroupMedSampleSizeNoPercent = $CurrencyObjects | Where-Object { $_.Date -ge ($CurDate - $SampleSizets) } | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{Name = "Median"; Expression = { Get-Median $_.group.Last24hDrift } }

        ForEach ($Name in ($CurrencyObjects.Name | Select-Object -Unique)) { 
            Try { 
                $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Count)) * [Math]::abs(($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $Name }).Median)
                $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $Name }).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent | Where-Object { $_.Name -eq $Name }).Median)
                $Penalty = ($PenaltySampleSizeHalf * $PoolConfig.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($PoolConfig.BrainConfig.SampleHalfPower + 1)
                $Price = [Math]::max(0, [Double]($Penalty + ($CurAlgoObjects | Where-Object { $_.Name -eq $Name }).actual_last24h))
                $CurrenciesData.$Name | Add-Member Plus_Price $Price -Force
            }
            Catch { }
        }
        Remove-Variable CurAlgoObjects, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, Name, Penalty, Price, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, SampleSizets, SampleSizeHalfts

        If ($PoolConfig.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
            ($CurrenciesData | ConvertTo-Json).replace("NaN", 0) | Out-File -FilePath $BrainDataFile -Force -ErrorAction Ignore
        }

        $Variables.BrainData.Remove($BrainName)
        $Variables.BrainData.$BrainName = $CurrenciesData
        $Variables.Brains.$BrainName["Updated"] = $CurDate

        # Limit to only sample size + 10 minutes min history
        $CurrencyObjects = @($CurrencyObjects | Where-Object Date -GE $CurDate.AddMinutes( - ($PoolConfig.BrainConfig.SampleSizeMinutes + 10)))
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
    $DurationsAvg = ([Int]($Durations | Measure-Object -Average | Select-Object -ExpandProperty Average) + 3)

    Write-Message -Level Debug "Brain '$($BrainName)': End loop (Duration $($Duration) sec.); found $($Variables.BrainData.$BrainName.PSObject.Properties.Name.Count) valid pools."

    Remove-Variable CurrenciesData, Duration -ErrorAction Ignore

    While ($CurDate -ge $Variables.MinerDataCollectedTimeStamp -or (([DateTime]::Now).ToUniversalTime().AddSeconds($DurationsAvg) -lt $Variables.EndCycleTime -and ([DateTime]::Now).ToUniversalTime() -lt $Variables.EndCycleTime)) { 
        Start-Sleep -Seconds 1
    }

    $Error.Clear()
}