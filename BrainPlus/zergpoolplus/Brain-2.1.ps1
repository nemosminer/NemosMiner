set-location ($args[0])
function Get-Trendline { 
    param ($data) 
    $n = $data.count 
    If ($n -le 1) {return 0}
    $sumX = 0 
    $sumX2 = 0 
    $sumXY = 0 
    $sumY = 0 
    for ($i = 1; $i -le $n; $i++) { 
        $sumX += $i 
        $sumX2 += ([Math]::Pow($i, 2)) 
        $sumXY += ($i) * ($data[$i - 1]) 
        $sumY += $data[$i - 1] 
    } 
    $b = [math]::Round(($sumXY - $sumX * $sumY / $n) / ($sumX2 - $sumX * $sumX / $n), 15)
    $a = [math]::Round($sumY / $n - $b * ($sumX / $n), 15)
    return @($a, $b) 
}

function Get-Median {
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Double[]]
        $Number
    )
    begin {
        $numberSeries += @()
    }
    process {
        $numberSeries += $number
    }
    end {
        $sortedNumbers = @($numberSeries | Sort-Object)
        if ($numberSeries.Count % 2) {
            $sortedNumbers[($sortedNumbers.Count / 2) - 1]
        }
        else {
            ($sortedNumbers[($sortedNumbers.Count / 2)] + $sortedNumbers[($sortedNumbers.Count / 2) - 1]) / 2
        }                        
    }
} 

$AlgoObject = @()
$MathObject = @()
$MathObjectFormated = @()
$TestDisplay = @()
$PrevTrend = 0

While ($true) {
    #Get-Config{
    If (Test-Path ".\BrainConfig.xml") {
        $Config = Import-Clixml ".\BrainConfig.xml"
        $SampleSizeMinutes = $Config.SampleSizeMinutes
        $TrendSpanSizeMinutes = $Config.TrendSpanSizeMinutes
        $SampleHalfPower = $Config.SampleHalfPower
        $ManualPriceFactor = $Config.ManualPriceFactor
        $Interval = $Config.Interval
        $LogDataPath = $Config.LogDataPath
        $TransferFile = $Config.TransferFile
        $EnableLog = $Config.EnableLog
        $PoolName = $Config.PoolName
        $PoolStatusUri = $Config.PoolStatusUri
    }
    else {return}
    $CurDate = Get-Date
    $RetryInterval = 0
    try {$AlgoData = Invoke-WebRequest $PoolStatusUri -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json
    }
    catch {$RetryInterval = $Interval}
    Foreach ($Algo in ($AlgoData | gm -MemberType NoteProperty).Name) {
        $AlgoObject += [PSCustomObject]@{
            Date               = $CurDate
            Name               = $AlgoData.($Algo).name
            Port               = $AlgoData.($Algo).port
            coins              = $AlgoData.($Algo).coins
            Fees               = $AlgoData.($Algo).Fees
            Hashrate           = $AlgoData.($Algo).Hashrate
            Workers            = $AlgoData.($Algo).Workers
            estimate_current   = $AlgoData.($Algo).estimate_current -as [Decimal]
            estimate_last24h   = $AlgoData.($Algo).estimate_last24h
            actual_last24h     = $AlgoData.($Algo).actual_last24h / 1000
            hashrate_last24h   = $AlgoData.($Algo).hashrate_last24h
            Last24Drift        = $AlgoData.($Algo).estimate_current - ($AlgoData.($Algo).actual_last24h / 1000)
            Last24DriftSign    = If ($AlgoData.($Algo).estimate_current - ($AlgoData.($Algo).actual_last24h / 1000) -ge 0) {"Up"} else {"Down"}
            Last24DriftPercent	= if ($AlgoData.($Algo).actual_last24h -gt 0) {($AlgoData.($Algo).estimate_current - ($AlgoData.($Algo).actual_last24h / 1000)) / ($AlgoData.($Algo).actual_last24h / 1000)} else {0}
            FirstDate          = ($AlgoObject[0]).Date
            TimeSpan           = If ($AlgoObject.Date -ne $null) {(New-TimeSpan -Start ($AlgoObject[0]).Date -End $CurDate).TotalMinutes}
        }
    }

    # Created here for performance optimisation, minimize # of lookups
    $FirstAlgoObject = $AlgoObject[0] # | ? {$_.date -eq ($AlgoObject.Date | measure -Minimum).Minimum}
    $CurAlgoObject = $AlgoObject | ? {$_.date -eq $CurDate}

    Foreach ($Name in ($AlgoObject.Name | Select -Unique)) {
        $TrendSpanSizets = New-TimeSpan -Minutes $TrendSpanSizeMinutes
        $SampleSizets = New-TimeSpan -Minutes $SampleSizeMinutes
        $SampleSizeHalfts = New-TimeSpan -Minutes ($SampleSizeMinutes / 2)
        $GroupAvgSampleSize = $AlgoObject | ? {$_.Date -ge ($CurDate - $SampleSizets)} | group Name, Last24DriftSign | select Name, Count, @{Name = "Avg"; Expression = {($_.group.Last24DriftPercent | measure -Average).Average}}, @{Name = "Median"; Expression = {Get-Median $_.group.Last24DriftPercent}}
        $GroupMedSampleSize = $AlgoObject | ? {$_.Date -ge ($CurDate - $SampleSizets)} | group Name | select Name, Count, @{Name = "Avg"; Expression = {($_.group.Last24DriftPercent | measure -Average).Average}}, @{Name = "Median"; Expression = {Get-Median $_.group.Last24DriftPercent}}
        $GroupAvgSampleSizeHalf = $AlgoObject | ? {$_.Date -ge ($CurDate - $SampleSizeHalfts)} | group Name, Last24DriftSign | select Name, Count, @{Name = "Avg"; Expression = {($_.group.Last24DriftPercent | measure -Average).Average}}, @{Name = "Median"; Expression = {Get-Median $_.group.Last24DriftPercent}}
        $GroupMedSampleSizeHalf = $AlgoObject | ? {$_.Date -ge ($CurDate - $SampleSizeHalfts)} | group Name | select Name, Count, @{Name = "Avg"; Expression = {($_.group.Last24DriftPercent | measure -Average).Average}}, @{Name = "Median"; Expression = {Get-Median $_.group.Last24DriftPercent}}
        $GroupMedSampleSizeNoPercent = $AlgoObject | ? {$_.Date -ge ($CurDate - $SampleSizets)} | group Name | select Name, Count, @{Name = "Avg"; Expression = {($_.group.Last24DriftPercent | measure -Average).Average}}, @{Name = "Median"; Expression = {Get-Median $_.group.Last24Drift}}
        $PenaltySampleSize = ((($GroupAvgSampleSize | ? {$_.Name -eq $Name + ", Up"}).Count - ($GroupAvgSampleSize | ? {$_.Name -eq $Name + ", Down"}).Count) / (($GroupMedSampleSize | ? {$_.Name -eq $Name}).Count)) * [math]::abs(($GroupMedSampleSize | ? {$_.Name -eq $Name}).Median)
        $PenaltySampleSizeHalf = ((($GroupAvgSampleSizeHalf | ? {$_.Name -eq $Name + ", Up"}).Count - ($GroupAvgSampleSizeHalf | ? {$_.Name -eq $Name + ", Down"}).Count) / (($GroupMedSampleSizeHalf | ? {$_.Name -eq $Name}).Count)) * [math]::abs(($GroupMedSampleSizeHalf | ? {$_.Name -eq $Name}).Median)
        $PenaltySampleSizeNoPercent = ((($GroupAvgSampleSize | ? {$_.Name -eq $Name + ", Up"}).Count - ($GroupAvgSampleSize | ? {$_.Name -eq $Name + ", Down"}).Count) / (($GroupMedSampleSize | ? {$_.Name -eq $Name}).Count)) * [math]::abs(($GroupMedSampleSizeNoPercent | ? {$_.Name -eq $Name}).Median)
        $Penalty = ($PenaltySampleSizeHalf * $SampleHalfPower + $PenaltySampleSizeNoPercent) / ($SampleHalfPower + 1)
        $LiveTrend = ((Get-Trendline ($AlgoObjects | ? {$_.Name -eq $Name}).estimate_current)[1])
        $Price = ($Penalty) + ($CurAlgoObject | ? {$_.Name -eq $Name}).actual_last24h

        $MathObject += [PSCustomObject]@{
            Name         = $Name
            DriftAvg     = (($CurAlgoObject | ? {$_.Name -eq $Name}).Last24DriftPercent | measure -Average).Average
            TimeSpan     = ($CurAlgoObject | ? {$_.Name -eq $Name}).TimeSpan
            UpDriftAvg   = ($GroupAvgSampleSize | ? {$_.Name -eq $Name + ", Up"}).Avg
            DownDriftAvg = ($GroupAvgSampleSize | ? {$_.Name -eq $Name + ", Down"}).Avg
            Penalty      = $Penalty
            PlusPrice    = $Price
            CurrentLive  = ($CurAlgoObject | ? {$_.Name -eq $Name}).estimate_current
            Current24hr  = ($CurAlgoObject | ? {$_.Name -eq $Name}).actual_last24h
            Date         = $CurDate
            LiveTrend    = $LiveTrend
        }
        $AlgoData.($Name).actual_last24h = $Price * 1000
    }
    if ($EnableLog) {$MathObject | Export-Csv -NoTypeInformation -Append $LogDataPath}
    ($AlgoData | ConvertTo-Json).replace("NaN", 0) | Set-Content $TransferFile

    # Limit to only 120 min history
    $AlgoObject = $AlgoObject | ? {$_.Date -ge $CurDate.AddDays(-1).AddHours(-1)}
    (($GroupMedSampleSize | ? {$_.Name -eq $Name}).Count)

    $MathObject = @()
    Sleep ($Interval + $RetryInterval - (Get-Date).Second)
}


