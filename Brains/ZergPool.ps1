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
Version:        5.0.1.1
Version date:   2023/10/07
#>

using module ..\Includes\Include.psm1

# Start transcript log
If ($Config.Transcript) { Start-Transcript -Path ".\Debug\$((Get-Item $MyInvocation.MyCommand.Path).BaseName)-Transcript_$(Get-Date -Format "yyyy-MM-dd_HH-mm-ss").log" }

# Set Process priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$BrainName = (Get-Item $MyInvocation.MyCommand.Path).BaseName

$AlgoObjects = @()
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
                $CurrenciesData.PSObject.Properties.Name | Where-Object { $CurrenciesData.$_.noautotrade -and $CurrenciesData.$_.symbol -ne $PayoutCurreny } | ForEach-Object { $CurrenciesData.PSObject.Properties.Remove($_) }

                # Add currency and convert to array for easy sorting
                $CurrenciesArray = @()
                $CurrenciesData.PSObject.Properties.Name | Where-Object { $CurrenciesData.$_.algo } | ForEach-Object { 
                    $CurrenciesData.$_ | Add-Member @{ Currency = If ($CurrenciesData.$_.symbol) { $CurrenciesData.$_.symbol } Else { $_ } } -Force
                    $CurrenciesData.$_ | Add-Member @{ CoinName = If ($CurrenciesData.$_.name) { $CurrenciesData.$_.name } Else { $_ } } -Force
                    $CurrenciesData.$_.PSObject.Properties.Remove("symbol")
                    $CurrenciesData.$_.PSObject.Properties.Remove("name")
                    $CurrenciesArray += $CurrenciesData.$_
                }

                $AlgoData = [PSCustomObject]@{ }
                $CurrenciesArray | Group-Object algo | ForEach-Object { 
                    $BestCurrency = ($_.Group | Sort-Object estimate_current -Descending | Select-Object -First 1)
                    $AlgoData | Add-Member $BestCurrency.algo $BestCurrency -Force
                }
                $APICallFails = 0
            }
            Catch { 
                If ($APICallFails -lt 5) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * $PoolConfig.PoolAPIRetryInterval)))
            }
        } While (-not $AlgoData)

        $CurDate = ([DateTime]::Now).ToUniversalTime()

        # Change last24: -> last24h: (Error in API?), numeric string to numbers, some values are null
        $AlgoData = ($AlgoData | ConvertTo-Json) -replace '_last24":', 'last24h":' -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

        ForEach ($Algo in $AlgoData.PSObject.Properties.Name) { 
            $AlgoData.$Algo.actual_last24h_shared = $AlgoData.$Algo.actual_last24h_shared / 1000
            $BasePrice = If ($AlgoData.$Algo.actual_last24h_shared) { $AlgoData.$Algo.actual_last24h_shared } Else { $AlgoData.$Algo.estimate_last24h }

            If ($AlgoData.$Algo.currency) { 
                $Currency = $AlgoData.$Algo.currency
            }
            Else { 
                $Currencies = @($CurrenciesData.PSObject.Properties.Name | Where-Object { $CurrenciesData.$_.algo -eq $Algo } | ForEach-Object { $CurrenciesData.$_ })
                $Currency = If ($Currencies.Currency) { (($Currencies | Sort-Object Estimate)[-1].Currency) -replace ' \s+' } Else { "" }
            }
            If ($Currency) { 
                # Add coin name
                If ($AlgoData.$Algo.CoinName) { 
                    Try { 
                        [Void](Add-CoinName -Algorithm $Algo -Currency $Currency -CoinName $AlgoData.$Algo.CoinName)
                    }
                    Catch { }
                }
                # Keep DAG data up to date
                If ($Algo -match $Variables.RegexAlgoHasDAG -and $AlgoData.$Algo.height -gt $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                    If ($Variables.DAGdata.Currency) { 
                        $DAGdata = (Get-DAGData -Blockheight $AlgoData.$Algo.height -Currency $Currency -EpochReserve 2)
                        $DAGdata.Date = ([DateTime]::Now).ToUniversalTime()
                        $DAGdata.Url = $PoolConfig.PoolCurrenciesUri
                        $Variables.DAGdata.Currency[$Currency] = $DAGdata
                        $Variables.DAGdata.Updated[$PoolConfig.PoolCurrenciesUri] = ([DateTime]::Now).ToUniversalTime()
                    }
                }
            }

            $AlgoData.$Algo | Add-Member Currency $Currency -Force
            $AlgoData.$Algo | Add-Member Fees $Config.PoolsConfig.$BrainName.DefaultFee -Force
            $AlgoData.$Algo | Add-Member Updated $CurDate -Force

            $AlgoObjects += [PSCustomObject]@{
                actual_last24h      = $BasePrice
                Currency            = $Currency
                Date                = $CurDate
                estimate_current    = $AlgoData.$Algo.estimate_current
                estimate_last24h    = $AlgoData.$Algo.estimate_last24h
                Fees                = $AlgoData.$Algo.fees
                Hashrate            = $AlgoData.$Algo.hashrate
                hashrate_last24h    = $AlgoData.$Algo.hashrate_last24h_shared
                Last24hDrift        = $AlgoData.$Algo.estimate_current - $BasePrice
                Last24hDriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                Last24hDriftSign    = If ($AlgoData.$Algo.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                Name                = $Algo
                Port                = $AlgoData.$Algo.port
                Workers             = $AlgoData.$Algo.Workers
            }
        }
        Remove-Variable Algo, BasePrice, BestCurrency, Currencies, CurrenciesArray, CurrenciesData, Currency, DAGdata -ErrorAction Ignore

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

    While ($CurDate -ge $Variables.PoolDataCollectedTimeStamp -or ([DateTime]::Now).ToUniversalTime().AddSeconds([Int]($Durations | Measure-Object -Average | Select-Object -ExpandProperty Average) + 3) -le $Variables.EndCycleTime) { 
        Start-Sleep -Seconds 1
    }

    $Error.Clear()
}