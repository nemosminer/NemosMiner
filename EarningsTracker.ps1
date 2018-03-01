param(
    [Parameter(Mandatory = $false)]
    [String]$Pool = "ahashpool", 
    [Parameter(Mandatory = $true)]
    [String]$Wallet = "", 
    [Parameter(Mandatory = $false)]
    [String]$APIUri, 
    [Parameter(Mandatory = $false)]
    [Float]$PaymentThreshold = 0.01, 
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 10,
    [Parameter(Mandatory = $false)]
    [String]$OutputFile = ".\Logs\" + $Pool + "balancetracking.csv",
    [Parameter(Mandatory = $false)]
    [Bool]$ShowText = $true,
    [Parameter(Mandatory = $false)]
    [Bool]$ShowRawData = $false
)

$Params = @{
    pool             = $pool
    Wallet           = $Wallet
    APIUri           = $APIUri
    PaymentThreshold = $PaymentThreshold
    Interval         = $Interval
    OutputFile       = $OutputFile
    WorkingDirectory = ".\"
}
$job = Start-Job -FilePath .\EarningsTrackerJob.ps1 -ArgumentList $Params


$BalanceObjectS = @()
# Only for debug
# $BalanceObjectS = Import-cliXml ".\EarningTrack.xml"

while ($true) {
	
    $EarnTrack = $job | Receive-Job

    If ($EarnTrack) {

        $EarningsObject = $EarnTrack[($EarnTrack.Count - 1)]
	
        cls
        If ($ShowText) {
            Write-Host "
Estimations and forecast
   Note that these are only estimations based on past data. Reality won't match ;)
   Last 1, 6 and 24 growth are estimated until we reach that runtime
"
        }
        Write-Host "+++++" $Wallet $Pool "Balance="$EarningsObject.balance ("{0:P0}" -f ($EarningsObject.balance / $EarningsObject.PaymentThreshold)) -B Blue -F White
        Write-Host "Growth since script start                  BTC =" ("{0:N8}" -f $EarningsObject.GrowthSinceStart) "| mBTC =" ("{0:N3}" -f ($EarningsObject.GrowthSinceStart * 1000))
        Write-Host "Last 01 hr growth                          BTC =" ("{0:N8}" -f $EarningsObject.Growth1) "| mBTC =" ("{0:N3}" -f ($EarningsObject.Growth1 * 1000))
        Write-Host "Last 06 hr growth                          BTC =" ("{0:N8}" -f $EarningsObject.Growth6) "| mBTC =" ("{0:N3}" -f ($EarningsObject.Growth6 * 1000))
        Write-Host "Last 24 hr growth                          BTC =" ("{0:N8}" -f $EarningsObject.Growth24) "| mBTC =" ("{0:N3}" -f ($EarningsObject.Growth24 * 1000))
        Write-Host "Average BTC/H                              BTC =" ("{0:N8}" -f $EarningsObject.AvgHourlyGrowth) "| mBTC =" ("{0:N3}" -f ($EarningsObject.AvgHourlyGrowth * 1000))
        Write-Host "Average BTC/D                              BTC =" ("{0:N8}" -f ($EarningsObject.AvgHourlyGrowth * 24)) "| mBTC =" ("{0:N3}" -f ($EarningsObject.AvgHourlyGrowth * 24 * 1000)) -F Green
        Write-Host "Estimated Growth to midnight               BTC =" ("{0:N8}" -f $EarningsObject.EstimatedEndDayGrowth)  "| mBTC =" ("{0:N3}" -f ($EarningsObject.EstimatedEndDayGrowth * 1000))
        Write-Host "Estimated Pay Date                        " $EarningsObject.EstimatedPayDate ">" $EarningsObject.PaymentThreshold "BTC" -F Green
        Write-Host "+++++" -F Blue
        Write-Host "Current estimates based on" ($EarningsObject.Date - $EarningsObject.StartTime) "time span | Trust Level" ("{0:P0}" -f $EarningsObject.TrustLevel)
        If ((($EarningsObject.Date - $EarningsObject.StartTime).TotalMinutes) -lt 60 -and $ShowText) {
            Write-Host "+++++" -F Blue
            Write-Host "Currently running with very few data. Please wait for accurate estimations"
            Write-Host "Estimates needs historical data. Innacurate results are perfectly normal at start."
            Write-Host "Will get stats as time goes."
        }
        If ($ShowRawData) {
            Write-Host "+++++" -F Blue
            Write-Host "Current data from pool" $Pool
            $EarningsObject | ft | out-host
        }
        Sleep (($Interval - 1) * 60)
    }	
}
