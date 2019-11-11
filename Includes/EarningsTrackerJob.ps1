<#
Copyright (c) 2018 MrPlus
EarningsTrackerJob.ps1 Written by MrPlusGH https://github.com/MrPlusGH

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           EarningsTrackerJob.ps1
version:        3.8.1.3
version date:   12 November 2019
#>

# To start the job one could use the following
# $job = Start-Job -FilePath .\EarningTrackerJob.ps1 -ArgumentList $params
# Remove progress info from job.childjobs.Progress to avoid memory leak
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$args[0].GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value }

If ($WorkingDirectory) { Set-Location $WorkingDirectory }
# Start-Transcript ".\Logs\EarnTR.txt"
If (Test-Path ".\logs\EarningTrackerData.json") { $AllBalanceObjectS = Get-Content ".\logs\EarningTrackerData.json" | ConvertFrom-JSON } else { $AllBalanceObjectS = @() }

$BalanceObjectS = @()
$TrustLevel = 0
$StartTime = Get-Date
$LastAPIUpdateTime = Get-Date

while ($true) {

    #Read Config (ie. Pools to track)
    $EarningsTrackerConfig = Get-content ".\config\EarningTrackerConfig.json" | ConvertFrom-JSON
    $Interval = $EarningsTrackerConfig.PollInterval
    
    #Filter pools variants
    $TrackPools = (($EarningsTrackerConfig.pools | sort -Unique).replace("plus", "")).replace("24hr", "").replace("coins", "")

    # Get pools api ref
    If (-not $poolapi -or ($LastAPIUpdateTime -le (Get-Date).AddDays(-1))) {
        try {
            $poolapi = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/UpDateData/master/poolapiref.json" -TimeoutSec 15 -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json
        }
        catch { $poolapi = Get-content ".\Config\poolapiref.json" | Convertfrom-json }
        $LastAPIUpdateTime = Get-Date
    }
    else {
        $poolapi = Get-content ".\Config\poolapiref.json" | Convertfrom-json
    }

    #For each pool in config
    #Go loop
    foreach ($Pool in $TrackPools) {
        if ($poolapi -ne $null) {
            $poolapi | ConvertTo-json | Out-File ".\Config\poolapiref.json"
            If (($poolapi | ? { $_.Name -eq $pool }).EarnTrackSupport -eq "yes") {
                $APIUri = ($poolapi | ? { $_.Name -eq $pool }).WalletUri
                $PaymentThreshold = ($poolapi | ? { $_.Name -eq $pool }).PaymentThreshold
                $BalanceJson = ($poolapi | ? { $_.Name -eq $pool }).Balance
                $TotalJson = ($poolapi | ? { $_.Name -eq $pool }).Total

                $ConfName = if ($PoolsConfig.$Pool -ne $Null) { $Pool }else { "default" }
                $PoolConf = $PoolsConfig.$ConfName

                $Wallet =
                if ($Pool -eq "mph") {
                    $PoolConf.APIKey
                }
                else {
                    $PoolConf.Wallet
                }
                
                $CurDate = Get-Date
                # Write-host $Pool
                # Write-Host "$($APIUri)$($Wallet)"
                If ($Pool -eq "nicehashV2") {
                    try {
                        $TempBalanceData = Invoke-WebRequest ("$($APIUri)$($Wallet)/rigs") -TimeoutSec 15 -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json 
                    }
                    catch { }
                    [Double]$NHTotalBalance = [Double]($TempBalanceData.unpaidAmount) + [Double]($TempBalanceData.externalBalance)
                    $TempBalanceData | Add-Member -NotePropertyName $BalanceJson -NotePropertyValue $NHTotalBalance -Force
                    $TempBalanceData | Add-Member -NotePropertyName $TotalJson -NotePropertyValue $NHTotalBalance -Force
                }
                elseif ($Pool -eq "mph") {
                    try {
                        $TempBalanceData = ((((Invoke-WebRequest ("$($APIUri)$($Wallet)") -TimeoutSec 15 -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" }).content | ConvertFrom-Json).getuserallbalances).data | Where { $_.coin -eq "bitcoin" }) 
                    }
                    catch { }#.confirmed
                }
                else {
                    try {
                        $TempBalanceData = Invoke-WebRequest ("$($APIUri)$($Wallet)") -TimeoutSec 15 -UseBasicParsing -Headers @{"Cache-Control" = "no-cache" } | ConvertFrom-Json 
                    }
                    catch { }
                }
                If ($TempBalanceData.$TotalJson -gt 0) {
                    $BalanceData = $TempBalanceData
                    $AllBalanceObjectS += [PSCustomObject]@{
                        Pool         = $Pool
                        Date         = $CurDate
                        balance      = $BalanceData.$BalanceJson
                        unsold       = $BalanceData.unsold
                        total_unpaid = $BalanceData.total_unpaid
                        total_paid   = $BalanceData.total_paid
                        total_earned = $BalanceData.$TotalJson
                        currency     = $BalanceData.currency
                    }
                    $BalanceObjectS = $AllBalanceObjectS | ? { $_.Pool -eq $Pool }
                    $BalanceObject = $BalanceObjectS[$BalanceOjectS.Count - 1]
                    If ((($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes) -eq 0) { $CurDate = $CurDate.AddMinutes(1) }
                    


                    If ((($CurDate - ($BalanceObjectS[0].Date)).TotalDays) -ge 1) {
                        $Growth1 = $BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date -ge $CurDate.AddHours(-1) }).total_earned | measure -Minimum).Minimum
                        $Growth6 = $BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date -ge $CurDate.AddHours(-6) }).total_earned | measure -Minimum).Minimum
                        $Growth24 = $BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date -ge $CurDate.AddDays(-1) }).total_earned | measure -Minimum).Minimum
                    }
                    If ((($CurDate - ($BalanceObjectS[0].Date)).TotalDays) -lt 1) {
                        $Growth1 = $BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date -ge $CurDate.AddHours(-1) }).total_earned | measure -Minimum).Minimum
                        $Growth6 = $BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date -ge $CurDate.AddHours(-6) }).total_earned | measure -Minimum).Minimum
                        $Growth24 = (($BalanceObject.total_earned - $BalanceObjectS[0].total_earned) / ($CurDate - ($BalanceObjectS[0].Date)).TotalHours) * 24
                    }
                    If ((($CurDate - ($BalanceObjectS[0].Date)).TotalHours) -lt 6) {
                        $Growth1 = $BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date -ge $CurDate.AddHours(-1) }).total_earned | measure -Minimum).Minimum
                        $Growth6 = (($BalanceObject.total_earned - $BalanceObjectS[0].total_earned) / ($CurDate - ($BalanceObjectS[0].Date)).TotalHours) * 6
                    }
                    If ((($CurDate - ($BalanceObjectS[0].Date)).TotalHours) -lt 1) {
                        $Growth1 = (($BalanceObject.total_earned - $BalanceObjectS[0].total_earned) / ($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes) * 60
                    }
                    
                    $AvgBTCHour = If ((($CurDate - ($BalanceObjectS[0].Date)).TotalHours) -ge 1) { (($BalanceObject.total_earned - $BalanceObjectS[0].total_earned) / ($CurDate - ($BalanceObjectS[0].Date)).TotalHours) } else { $Growth1 }
                    $EarningsObject = [PSCustomObject]@{
                        Pool                  = $pool
                        Wallet                = $Wallet
                        Date                  = $CurDate
                        StartTime             = $BalanceObjectS[0].Date
                        balance               = $BalanceObject.balance
                        unsold                = $BalanceObject.unsold
                        total_unpaid          = $BalanceObject.total_unpaid
                        total_paid            = $BalanceObject.total_paid
                        total_earned          = $BalanceObject.total_earned
                        currency              = $BalanceObject.currency
                        GrowthSinceStart      = $BalanceObject.total_earned - $BalanceObjectS[0].total_earned
                        Growth1               = $Growth1
                        Growth6               = $Growth6
                        Growth24              = $Growth24
                        AvgHourlyGrowth       = $AvgBTCHour
                        BTCD                  = $AvgBTCHour * 24
                        EstimatedEndDayGrowth = If ((($CurDate - ($BalanceObjectS[0].Date)).TotalHours) -ge 1) { ($AvgBTCHour * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDate).Hours) } else { $Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDate).Hours }
                        EstimatedPayDate      = if ($PaymentThreshold) { IF ($BalanceObject.balance -lt $PaymentThreshold) { If ($AvgBTCHour -gt 0) { $CurDate.AddHours(($PaymentThreshold - $BalanceObject.balance) / $AvgBTCHour) } Else { "Unknown" } } else { "Next Payout !" } }else { "Unknown" }
                        TrustLevel            = if (($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes -le 360) { ($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes / 360 }else { 1 }
                        PaymentThreshold      = $PaymentThreshold
                        TotalHours            = ($CurDate - ($BalanceObjectS[0].Date)).TotalHours
                    }
                    
                    $EarningsObject
                    if ($EarningsTrackerConfig.EnableLog) { $EarningsObject | Export-Csv -NoTypeInformation -Append ".\Logs\EarningTrackerLog.csv" }

                    If (Test-Path ".\Logs\DailyEarnings.csv") {
                        $DailyEarnings = Import-Csv ".\Logs\DailyEarnings.csv" # Add filter on mw # days from config.
                        If ($DailyEarnings | ? { $_.Date -eq $CurDate.ToString("MM/dd/yyyy") -and $_.Pool -eq $Pool }) {
                            $DailyEarnings | select Date, Pool,
                            @{Name = "DailyEarnings"; Expression = {
                                    If ($_.Date -eq ($CurDate.ToString("MM/dd/yyyy")) -and $_.Pool -eq $Pool) {
                                        If ($_.PrePaimentDayValue -gt 0) {
                                            #Paiment occured
                                            ($_.PrePaimentDayValue - $_.FirstDayValue) + ($BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date.DayOfYear -eq $CurDate.DayOfYear }).total_earned | measure -minimum).minimum)
                                        }
                                        else {
                                            $BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date.DayOfYear -eq $CurDate.DayOfYear }).total_earned | measure -minimum).minimum
                                        }
                                    }
                                    else { $_.DailyEarnings } 
                                }
                            },
                            FirstDayDate,
                            FirstDayValue,
                            @{Name = "LastDayDate"; Expression = {
                                    If ($_.Date -eq ($CurDate.ToString("MM/dd/yyyy")) -and $_.Pool -eq $Pool) {
                                        $BalanceObject.Date
                                    }
                                    else { $_.LastDayDate } 
                                }
                            },
                            @{Name = "LastDayValue"; Expression = {
                                    If ($_.Date -eq ($CurDate.ToString("MM/dd/yyyy")) -and $_.Pool -eq $Pool) {
                                        $BalanceObject.total_earned
                                    }
                                    else { $_.LastDayValue } 
                                }
                            },
                            @{Name = "PrePaimentDayValue"; Expression = {
                                    If (($_.Date -eq ($CurDate.ToString("MM/dd/yyyy")) -and $_.Pool -eq $Pool) -and ($BalanceObject.total_earned -lt ($BalanceObjectS[$BalanceObjectS.Count - 2].total_earned / 2))) {
                                        $BalanceObjectS[$BalanceObjectS.Count - 2].total_earned
                                    }
                                    else { $_.PrePaimentDayValue } 
                                }
                            },
                            @{Name = "Balance"; Expression = {
                                    If ($_.Date -eq ($CurDate.ToString("MM/dd/yyyy")) -and $_.Pool -eq $Pool) {
                                        $BalanceObject.balance
                                    }
                                    else { $_.Balance } 
                                }
                            },
                            @{Name = "BTCD"; Expression = {
                                    If ($_.Date -eq ($CurDate.ToString("MM/dd/yyyy")) -and $_.Pool -eq $Pool) {
                                        $BalanceObject.Growth24
                                    }
                                    else { $_.BTCD } 
                                }
                            } | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation
                        }
                        else {
                            $DailyEarnings = [PSCustomObject]@{
                                Date               = $CurDate.ToString("MM/dd/yyyy")
                                Pool               = $Pool
                                DailyEarnings      = $BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date.DayOfYear -eq $CurDate.DayOfYear }).total_earned | measure -minimum).minimum
                                FirstDayDate       = $BalanceObject.Date
                                FirstDayValue      = $BalanceObject.total_earned
                                LastDayDate        = $BalanceObject.Date
                                LastDayValue       = $BalanceObject.total_earned
                                PrePaimentDayValue = 0
                                Balance            = $BalanceObject.Balance
                                BTCD               = $BalanceObject.Growth24
                            }
                            $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Append
                        }
                           
                    }
                    else {
                        $DailyEarnings = [PSCustomObject]@{
                            Date               = $CurDate.ToString("MM/dd/yyyy")
                            Pool               = $Pool
                            DailyEarnings      = $BalanceObject.total_earned - (($BalanceObjectS | ? { $_.Date.DayOfYear -eq $CurDate.DayOfYear }).total_earned | measure -minimum).minimum
                            FirstDayDate       = $BalanceObject.Date
                            FirstDayValue      = $BalanceObject.total_earned
                            LastDayDate        = $BalanceObject.Date
                            LastDayValue       = $BalanceObject.total_earned
                            PrePaimentDayValue = 0
                            Balance            = $BalanceObject.Balance
                            BTCD               = $BalanceObject.Growth24
                        }
                        $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation
                    }
                    rv DailyEarnings
                    
                    # Some pools do reset "Total" after payment (zpool)
                    # Results in showing bad negative earnings
                    # Detecting if current is more than 50% less than previous and reset history if so
                    If ($BalanceObject.total_earned -lt ($BalanceObjectS[$BalanceObjectS.Count - 2].total_earned / 2)) { $AllBalanceObjectS = $AllBalanceObjectS | ? { $_.Pool -ne $Pool }; $AllBalanceObjectS += $BalanceObject }
                    rv TempBalanceData
                } #else {$Pool | Out-Host} #else {return}
            }
        }
    }
        
    If ($AllBalanceObjectS.Count -gt 1) { $AllBalanceObjectS = $AllBalanceObjectS | ? { $_.Date -ge $CurDate.AddDays(-1).AddHours(-1) } }
    # Save data only at defined interval. Limit disk access
    If ((Get-Date) -gt $WriteAt) {
        $WriteAt = (Get-Date).AddMinutes($EarningsTrackerConfig.WriteEvery)
        if ($AllBalanceObjectS.Count -gt 1) { $AllBalanceObjectS | ConvertTo-JSON | Out-File ".\logs\EarningTrackerData.json" }
    }


    # Sleep until next update based on $Interval. Modulo $Interval.
    # Sleep (60*($Interval-((get-date).minute%$Interval))) # Changed to avoid pool API load.
    If (($EarningsObject.Date - $EarningsObject.StartTime).TotalMinutes -le 20) {
        Sleep (60 * ($Interval / 2))    
    }
    else {
        Sleep (60 * ($Interval))  
    }
        
}
