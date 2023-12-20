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
Version:        5.0.2.4
Version date:   2023/12/20
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

While ($PoolConfig = $Config.PoolsConfig.$BrainName) { 

    $StartTime = [DateTime]::Now

    Try { 

        Write-Message -Level Debug "Brain '$BrainName': Start loop$(If ($Duration) { " (Previous loop duration: $Duration sec. / Avg. loop duration: $(($Durations | Measure-Object -Average | Select-Object -ExpandProperty Average)) sec.)" })"

        Do {
            Try { 
                If ($Config.PoolName -match "$($BrainName)Coins.*") { 
                    $Uri = $PoolConfig.PoolCurrenciesUri
                    # In case variant got changed to *Coins only keep algo data with currencies
                    $PoolObjects = $PoolObjects.Where({ $_.Currency })
                }
                Else { 
                    $Uri = $PoolConfig.PoolStatusUri
                    # In case variant got changed from *Coins only keep algo data without currencies
                    $PoolObjects = $PoolObjects.Where({ -not $_.Currency })
                }
                $APIdata = Invoke-RestMethod -Uri $Uri -Headers @{ "Cache-Control" = "no-cache" } -SkipCertificateCheck -TimeoutSec $PoolConfig.PoolAPITimeout

                $APICallFails = 0
            }
            Catch { 
                If ($APICallFails -lt $PoolConfig.PoolAPIAllowedFailureCount) { $APICallFails ++ }
                Start-Sleep -Seconds ([Math]::max(60, ($APICallFails * $PoolConfig.PoolAPIRetryInterval)))
            }
        } While (-not $APIdata.PSObject.Properties.Name)

        $Timestamp = ([DateTime]::Now).ToUniversalTime()

        $APIdata.PSObject.Properties.Name.Where({ $APIdata.$_.algo -eq "Token" -or $_ -like "*-*" }).ForEach({ $APIdata.PSObject.Properties.Remove($_) })
        $APIdata.PSObject.Properties.Name.Where({ $APIdata.$_.algo }).ForEach(
            { 
                $APIdata.$_ | Add-Member @{ Currency = If ($APIdata.$_.symbol) { $APIdata.$_.symbol } Else { "" } } -Force
                $APIdata.$_ | Add-Member @{ CoinName = If ($APIdata.$_.name) { $APIdata.$_.name } Else { "" } } -Force
                $APIdata.$_.PSObject.Properties.Remove("symbol")
                $APIdata.$_.PSObject.Properties.Remove("name")
            }
        )
        $APIdata.PSObject.Properties.Name.Where({ -not $APIdata.$_.algo }).ForEach(
            { 
                $APIdata.$_ | Add-Member @{ algo = $APIdata.$_.name }
                $APIdata.$_.PSObject.Properties.Remove("name")
            }
        )

        # Change last24: -> last24h: (Error in API?), numeric string to numbers, some values are null
        $APIdata = ($APIdata | ConvertTo-Json) -replace '_last24":', 'last24h":' -replace ': "(\d+\.?\d*)"', ': $1' -replace '": null', '": 0' | ConvertFrom-Json

        ForEach ($PoolName in $APIdata.PSObject.Properties.Name) { 
            $Algorithm_Norm = Get-Algorithm $APIdata.$PoolName.algo
            $Currency = [String]$APIdata.$PoolName.Currency
            If ($AlgoData.$Algo.actual_last24h_shared) { $AlgoData.$Algo.actual_last24h_shared /= 1000 }
            $BasePrice = If ($APIdata.$PoolName.actual_last24h_shared) { $APIdata.$PoolName.actual_last24h_shared } Else { $APIdata.$PoolName.estimate_last24h }

            # Add currency and coin name do database
            If ($APIdata.$PoolName.CoinName) { 
                Try { 
                    [Void](Add-CoinName -Algorithm $Algorithm_Norm -Currency $Currency -CoinName $APIdata.$PoolName.CoinName)
                }
                Catch { }
            }

            # Keep DAG data up to date
            If ($Algorithm_Norm -match $Variables.RegexAlgoHasDAG -and $APIdata.$PoolName.height -gt $Variables.DAGdata.Currency.$Currency.BlockHeight) { 
                If ($Variables.DAGdata.Currency) { 
                    $DAGdata = (Get-DAGData -BlockHeight $APIdata.$PoolName.height -Currency $PoolName -EpochReserve 2)
                    $DAGdata | Add-Member Date ([DateTime]::Now).ToUniversalTime()
                    $DAGdata | Add-Member Url $Uri
                    $Variables.DAGdata.Currency | Add-Member $PoolName $DAGdata -Force
                    $Variables.DAGdata.Updated | Add-Member $Uri ([DateTime]::Now).ToUniversalTime() -Force
                }
            }

            $APIdata.$PoolName | Add-Member Fees $Config.PoolsConfig.$BrainName.DefaultFee -Force
            $APIdata.$PoolName | Add-Member Updated $Timestamp -Force

            $PoolObjects += [PSCustomObject]@{
                actual_last24h      = $BasePrice
                Date                = $Timestamp
                estimate_current    = $APIdata.$PoolName.estimate_current
                estimate_last24h    = $APIdata.$PoolName.estimate_last24h
                Last24hDrift        = $APIdata.$PoolName.estimate_current - $BasePrice
                Last24hDriftPercent = If ($BasePrice -gt 0) { ($APIdata.$PoolName.estimate_current - $BasePrice) / $BasePrice } Else { 0 }
                Last24hDriftSign    = If ($APIdata.$PoolName.estimate_current -ge $BasePrice) { "Up" } Else { "Down" }
                Name                = $PoolName
            }
        }
        Remove-Variable BasePrice, Currency, DAGdata, PoolName -ErrorAction Ignore

        # Created here for performance optimization, minimize # of lookups
        $CurPoolObjects = $PoolObjects.Where({ $_.Date -eq $Timestamp })
        $SampleSizets = New-TimeSpan -Minutes $PoolConfig.BrainConfig.SampleSizeMinutes
        $SampleSizeHalfts = New-TimeSpan -Minutes ($PoolConfig.BrainConfig.SampleSizeMinutes / 2)
        $GroupAvgSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
        $GroupMedSampleSize = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
        $GroupAvgSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name, Last24hDriftSign | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
        $GroupMedSampleSizeHalf = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizeHalfts) }) | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDriftPercent } }
        $GroupMedSampleSizeNoPercent = $PoolObjects.Where({ $_.Date -ge ($Timestamp - $SampleSizets) }) | Group-Object Name | Select-Object Name, Count, @{Name = "Avg"; Expression = { ($_.Group.Last24hDriftPercent | Measure-Object -Average | Select-Object -ExpandProperty Average) } }, @{ Name = "Median"; Expression = { Get-Median $_.Group.Last24hDrift } }

        ForEach ($PoolName in (($PoolObjects.Name | Select-Object -Unique).Where({ $_ -in $APIdata.PSObject.Properties.Name }))) { 
            $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $PoolName + ", Up" }).Count - ($GroupAvgSampleSizeHalf | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $PoolName }).Count)) * [Math]::abs(($GroupMedSampleSizeHalf | Where-Object { $_.Name -eq $PoolName }).Median)
            $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | Where-Object { $_.Name -eq $PoolName + ", Up" }).Count - ($GroupAvgSampleSize | Where-Object { $_.Name -eq $Name + ", Down" }).Count) / (($GroupMedSampleSize | Where-Object { $_.Name -eq $PoolName }).Count)) * [Math]::abs(($GroupMedSampleSizeNoPercent | Where-Object { $_.Name -eq $PoolName }).Median)
            $Penalty = ($PenaltySampleSizeHalf * $PoolConfig.BrainConfig.SampleHalfPower + $PenaltySampleSizeNoPercent) / ($PoolConfig.BrainConfig.SampleHalfPower + 1)
            $Price = [Math]::max(0, [Double]($Penalty + $CurPoolObjects.Where({ $_.Name -eq $PoolName }).actual_last24h))
            $APIdata.$PoolName | Add-Member Plus_Price $Price -Force
        }
        Remove-Variable CurPoolObjects, GroupAvgSampleSize, GroupMedSampleSize, GroupAvgSampleSizeHalf, GroupMedSampleSizeHalf, GroupMedSampleSizeNoPercent, Penalty, PenaltySampleSizeHalf, PenaltySampleSizeNoPercent, PoolName, Price, SampleSizets, SampleSizeHalfts

        If ($PoolConfig.BrainConfig.UseTransferFile -or $Config.PoolsConfig.$BrainName.BrainDebug) { 
            ($APIdata | ConvertTo-Json).replace("NaN", 0) | Out-File -LiteralPath $BrainDataFile -Force -ErrorAction Ignore
        }

        $Variables.BrainData.Remove($BrainName)
        $Variables.BrainData.$BrainName = $APIdata
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

    Remove-Variable APIdata, Duration -ErrorAction Ignore

    While ($Timestamp -ge $Variables.MinerDataCollectedTimeStamp -or (([DateTime]::Now).ToUniversalTime().AddSeconds($DurationsAvg) -le $Variables.EndCycleTime -and ([DateTime]::Now).ToUniversalTime() -lt $Variables.EndCycleTime)) { 
        Start-Sleep -Seconds 1
    }

    $Error.Clear()
}