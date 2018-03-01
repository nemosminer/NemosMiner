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

$args[0].GetEnumerator() | ForEach-Object { New-Variable -Name $_.Key -Value $_.Value }

If ($WorkingDirectory) {Set-Location $WorkingDirectory}

if (-not $APIUri) {
    try {
        $poolapi = Invoke-WebRequest "http://nemosminer.x10host.com/poolapiref.json" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json 
    }
    catch {  }
    if ($poolapi) {
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
        total_unpaid	= $BalanceData.total_unpaid
        total_paid   = $BalanceData.total_paid
        total_earned	= $BalanceData.$TotalJson
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
        balance               = $BalanceData.balance
        unsold                = $BalanceData.unsold
        total_unpaid          = $BalanceData.total_unpaid
        total_paid            = $BalanceData.total_paid
        total_earned          = $BalanceData.total_earned
        currency              = $BalanceData.currency
        GrowthSinceStart      = $BalanceObject.total_earned - $BalanceObjectS[0].total_earned
        Growth1               = $Growth1
        Growth6               = $Growth6
        Growth24              = $Growth24
        AvgHourlyGrowth       = $AvgBTCHour
        AvgDailyGrowth        = $AvgBTCHour * 24
        EstimatedEndDayGrowth = If ((($CurDate - ($BalanceObjectS[0].Date)).TotalHours) -ge 1) {($AvgBTCHour * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDate).Hours)} else {$Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $CurDate).Hours}
        EstimatedPayDate      = IF ($BalanceObject.balance -lt $PaymentThreshold) {If ($AvgBTCHour -gt 0) {$CurDate.AddHours(($PaymentThreshold - $BalanceObject.balance) / $AvgBTCHour)} Else {"Unknown"}} else {$CurDate}
        TrustLevel            = if (($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes -le 360) {($CurDate - ($BalanceObjectS[0].Date)).TotalMinutes / 360}else {1}
        PaymentThreshold      = $PaymentThreshold
    }
	
    $EarningsObject
	
    If ($BalanceObjectS.Count -gt 1) {$BalanceObjectS = $BalanceObjectS | ? {$_.Date -ge $CurDate.AddDays(-1).AddHours(-1)}}

    # Sleep until next update based on $Interval. Modulo $Interval.
    Sleep (60 * ($Interval - ((get-date).minute % $Interval)))
	
}
