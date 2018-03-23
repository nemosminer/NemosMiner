<#
This file is part of NemosMiner
Copyright (c) 2018 MrPlus

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

# param(
# [Parameter(Mandatory=$false)]
# [String]$Pool = "ahashpool", 
# [Parameter(Mandatory=$false)]
# [String]$Wallet = "", 
# [Parameter(Mandatory=$false)]
# [String]$APIUri, 
# [Parameter(Mandatory=$false)]
# [Float]$PaymentThreshold = 0.01, 
# [Parameter(Mandatory=$false)]
# [Int]$Interval = 10,
# [Parameter(Mandatory=$false)]
# [String]$OutputFile = ".\Logs\"+$Pool+"balancetracking.csv",
# [Parameter(Mandatory=$false)]
# [Bool]$ShowText = $true,
# [Parameter(Mandatory=$false)]
# [Bool]$ShowRawData = $true,
# [Parameter(Mandatory=$false)]
# [String]$WorkingDirectory = $true
# )
# To start the job one could use the following
# $job = Start-Job -FilePath .\EarningTrackerJob.ps1 -ArgumentList $params

# Set Process Priority
(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$args[0].GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value }
If ($WorkingDirectory) {Set-Location $WorkingDirectory}

sleep $StartDelay

if (-not $APIUri) {
    try {
        $poolapi = Invoke-WebRequest "http://nemosminer.x10host.com/poolapiref.json" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json
    }
    catch {$poolapi = Get-content ".\Config\poolapiref.json" | Convertfrom-json}
    if ($poolapi -ne $null) {
        $poolapi | ConvertTo-json | Out-File ".\Config\poolapiref.json"
        If (($poolapi | ? {$_.Name -eq $pool}).EarnTrackSupport -eq "yes") {
            $APIUri = ($poolapi | ? {$_.Name -eq $pool}).WalletUri
            $PaymentThreshold = ($poolapi | ? {$_.Name -eq $pool}).PaymentThreshold
            $BalanceJson = ($poolapi | ? {$_.Name -eq $pool}).Balance
            $TotalJson = ($poolapi | ? {$_.Name -eq $pool}).Total
        }
        else {return}
    }       
}

$BalanceObjectS = @()
$TrustLevel = 0

while ($true) {
    $CurDate = Get-Date
    If ($Pool -eq "nicehash") {
        try {
            $BalanceData = Invoke-WebRequest ($APIUri + $Wallet) -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
        }
        catch {  }
        if (-not $BalanceData.$BalanceJson) {$BalanceData | Add-Member -NotePropertyName $BalanceJson -NotePropertyValue ($BalanceData.result.Stats | measure -sum $BalanceJson).sum -Force}
        if (-not $BalanceData.$TotalJson) {$BalanceData | Add-Member -NotePropertyName $TotalJson -NotePropertyValue ($BalanceData.result.Stats | measure -sum $BalanceJson).sum -Force}
    }
    elseif ($Pool -eq "miningpoolhub") {
        try {
            $BalanceData = ((((Invoke-WebRequest ($APIUri + $Wallet) -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"}).content | ConvertFrom-Json).getuserallbalances).data | Where {$_.coin -eq "bitcoin"}) 
        }
        catch {  }#.confirmed
    }
    else {
        try {
            $TempBalanceData = Invoke-WebRequest ($APIUri + $Wallet) -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
        }
        catch {  }
    }
    If ($TempBalanceData.$BalanceJson) {$BalanceData = $TempBalanceData}

    $BalanceObjectS += [PSCustomObject]@{
        Date         = $CurDate
        balance      = $BalanceData.$BalanceJson
        unsold       = $BalanceData.unsold
        total_unpaid = $BalanceData.total_unpaid
        total_paid   = $BalanceData.total_paid
        total_earned = $BalanceData.$TotalJson
        currency     = $BalanceData.currency
    }
    $BalanceObject = $BalanceObjectS[$BalanceOjectS.Count - 1]
    If ((($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes) -eq 0) {$CurDate = $CurDate.AddMinutes(1)}
    $Growth1 = If ((($CurDate - ($BalanceObjectS[0].Date)).TotalHours) -ge 1) {$BalanceObject.total_earned - (($BalanceObjectS | ? {$_.Date -ge $CurDate.AddHours(-1)}).total_earned | measure -Minimum).Minimum} Else {(($BalanceObject.total_earned - $BalanceObjectS[0].total_earned) / ($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes) * 60}
    $Growth6 = If ((($CurDate - ($BalanceObjectS[0].Date)).TotalHours) -ge 6) {$BalanceObject.total_earned - (($BalanceObjectS | ? {$_.Date -ge $CurDate.AddHours(-6)}).total_earned | measure -Minimum).Minimum} Else {$Growth1 * 6}
    $Growth24 = If ((($CurDate - ($BalanceObjectS[0].Date)).TotalDays) -ge 1) {$BalanceObject.total_earned - (($BalanceObjectS | ? {$_.Date -ge $CurDate.AddDays(-1)}).total_earned | measure -Minimum).Minimum} Else {$Growth1 * 24}
    $AvgBTCHour = If ((($CurDate - ($BalanceObjectS[0].Date)).TotalHours) -ge 1) {(($BalanceObject.total_earned - $BalanceObjectS[0].total_earned) / ($CurDate - ($BalanceObjectS[0].Date)).TotalHours)} else {$Growth1}
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
        AvgDailyGrowth        = $AvgBTCHour * 24
        EstimatedEndDayGrowth = If ((($CurDate - ($BalanceObjectS[0].Date)).TotalHours) -ge 1) {($AvgBTCHour * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDate).Hours)} else {$Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDate).Hours}
        EstimatedPayDate      = if ($PaymentThreshold) {IF ($BalanceObject.balance -lt $PaymentThreshold) {If ($AvgBTCHour -gt 0) {$CurDate.AddHours(($PaymentThreshold - $BalanceObject.balance) / $AvgBTCHour)} Else {"Unknown"}} else {"Next Payout !"}}else {"Unknown"}
        TrustLevel            = if (($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes -le 360) {($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes / 360}else {1}
        PaymentThreshold      = $PaymentThreshold
    }
    
    $EarningsObject
    
    
    If ($BalanceObjectS.Count -gt 1) {$BalanceObjectS = $BalanceObjectS | ? {$_.Date -ge $CurDate.AddDays(-1).AddHours(-1)}}

    # Some pools do reset "Total" after payment (zpool)
    # Results in showing bad negative earnings
    # Detecting if current is more than 50% less than previous and reset history if so
    If ($BalanceObject.total_earned -lt ($BalanceObjectS[$BalanceObjectS.Count - 2].total_earned / 2)) {$BalanceObjectS = @(); $BalanceObjectS += $BalanceObject}

    # Sleep until next update based on $Interval. Modulo $Interval.
    # Sleep (60*($Interval-((get-date).minute%$Interval))) # Changed to avoid pool API load.
    If (($EarningsObject.Date - $EarningsObject.StartTime).TotalMinutes -le 20) {
        Sleep (60 * ($Interval / 2))    
    }
    else {
        Sleep (60 * ($Interval))  
    }
}

