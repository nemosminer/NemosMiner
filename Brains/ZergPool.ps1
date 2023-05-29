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
File:           ZergPool.ps1
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
$CurrenciesData = @()
$Durations = [System.Collections.Generic.List[Double]]@()
$PayoutCurrency = $Config.PoolsConfig.$BrainName.Wallets.Keys | Select-Object -First 1
$TransferFile = "$($PWD)\Data\BrainData_$($BrainName).json"

$ProgressPreference = "SilentlyContinue"

# Fix TLS Version erroring
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

While ($BrainConfig = $Config.PoolsConfig.$BrainName.BrainConfig) { 
    Try { 
        $StartTime = Get-Date

        Write-Message -Level Debug "Brain '$($BrainName)': Start loop$(If ($Duration) { " (Previous loop duration: $($Duration.TotalSeconds) sec. / Avg. loop duration: $(($Durations | Measure-Object -Average).Average))" })"

        Do {
            Try { 
                $CurrenciesData = Invoke-RestMethod -Uri $BrainConfig.PoolCurrenciesUri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $BrainConfig.PoolAPITimeout
                $CurrenciesData.PSObject.Properties.Name | Where-Object { $CurrenciesData.$_.noautotrade -and $CurrenciesData.$_.symbol -ne $PayoutCurreny } | ForEach-Object { $CurrenciesData.PSObject.Properties.Remove($_) }

                # Add currency and convert to array for easy sorting
                $CurrenciesArray = [System.Collections.Generic.List[PSCustomObject]]@()
                $CurrenciesData.PSObject.Properties.Name | Where-Object { $CurrenciesData.$_.algo } | ForEach-Object { 
                    $CurrenciesData.$_ | Add-Member @{ Currency = If ($CurrenciesData.$_.symbol) { $CurrenciesData.$_.symbol } Else { $_ } } -Force
                    $CurrenciesData.$_ | Add-Member @{ CoinName = If ($CurrenciesData.$_.name) { $CurrenciesData.$_.name } Else { $_ } } -Force
                    $CurrenciesData.$_.PSObject.Properties.Remove("symbol")
                    $CurrenciesData.$_.PSObject.Properties.Remove("name")
                    $CurrenciesArray.Add($CurrenciesData.$_)
                }

                $AlgoData = [PSCustomObject]@{ }
                $CurrenciesArray | Group-Object algo | ForEach-Object { 
                    $BestCurrency = ($_.Group | Sort-Object estimate_current -Descending | Select-Object -First 1)
                    $AlgoData | Add-Member $BestCurrency.algo $BestCurrency -Force
                }
                $APICallFails = 0
            }
            Catch { 
                $APICallFails ++
                Start-Sleep -Seconds ([Math]::max(300, ($APICallFails * $BrainConfig.PoolAPIRetryInterval)))
            }
        } While (-not $AlgoData)

        $CurDate = (Get-Date).ToUniversalTime()

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
                $Currency = If ($Currencies.Currency) { (($Currencies | Sort-Object Estimate)[-1].Currency).Trim() } Else { "" }
            }
            If ($Currency) { 
                # Add coin name
                If ($AlgoData.$Algo.CoinName) { 
                    Try { 
                        $AlgoData.$Algo | ConvertTo-Json >> $($BrainName).txt
                        "Add-CoinName -Algorithm $Algo -Currency $Currency -CoinName $($AlgoData.$Algo.CoinName)" >> $($BrainName).txt
                        Add-CoinName -Algorithm $Algo -Currency $Currency -CoinName $AlgoData.$Algo.CoinName
                    }
                    Catch { }
                }
                # Keep DAG data up to date
                If ($Algo -in $Variables.DagData.Algorithm.Keys -and $AlgoData.$Algo.height -gt $Variables.DAGData.Currency.$Currency.BlockHeight) { 
                    $Variables.DAGData.Currency.$Currency = (Get-DAGData -Blockheight $AlgoData.$Algo.height -Currency $Currency -EpochReserve 2)
                    $Variables.DAGData.Updated."$BrainName Brain" = (Get-Date).ToUniversalTime()
                }
            }
            $AlgoData.$Algo | Add-Member @{ Currency = $Currency } -Force
            $AlgoData.$Algo | Add-Member @{ Fees = $Config.PoolsConfig.$BrainName.DefaultFee } -Force

            $AlgoObject += [PSCustomObject]@{
                actual_last24h     = $BasePrice
                Currency           = $Currency
                Date               = $CurDate
                estimate_current   = $AlgoData.$Algo.estimate_current
                estimate_last24h   = $AlgoData.$Algo.estimate_last24h
                Fees               = $AlgoData.$Algo.fees
                Hashrate           = $AlgoData.$Algo.hashrate
                hashrate_last24h   = $AlgoData.$Algo.hashrate_last24h_shared
                Last24Drift        = $AlgoData.$Algo.estimate_current - $BasePrice
                Last24DriftPercent = If ($BasePrice -gt 0) { ($AlgoData.$Algo.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                Last24DriftSign    = If ($AlgoData.$Algo.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                Name               = $Algo
                Port               = $AlgoData.$Algo.port
                Workers            = $AlgoData.$Algo.Workers
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
                $AlgoData.$Name | Add-Member @{ Penalty = $Penalty } -Force
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

        Remove-Variable Algo, AlgoData, CurrenciesArray, CurrenciesData, Name -ErrorAction Ignore

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