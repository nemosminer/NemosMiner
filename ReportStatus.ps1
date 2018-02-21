using module .\Include.ps1

param(
    [Parameter(Mandatory=$true)][String]$WorkerName,
    [Parameter(Mandatory=$true)][String]$Version,
    [Parameter(Mandatory=$true)]$ActiveMiners,
    [Parameter(Mandatory=$true)]$Miners,
    [Parameter(Mandatory=$true)]$MPHApiKey
)


# Format the miner values for reporting.  Set relative path so the server doesn't store anything personal (like your system username, if running from somewhere in your profile)
$minerreport = ConvertTo-Json @($ActiveMiners | Where-Object {$_.Activated -GT 0 -and $_.Status -eq "Running"} | Foreach-Object {
$ActiveMiner = $_
# Find the matching entry in $Miners, to get pool information. Perhaps there is a better way to do this?
$MatchingMiner = $Miners | Where-Object {$_.Name -eq $ActiveMiner.Name -and $_.Path -eq $ActiveMiner.Path -and $_.Arguments -eq $ActiveMiner.Arguments -and $_.Wrap -eq $ActiveMiner.Wrap -and $_.API -eq $ActiveMiner.API -and $_.Port -eq $ActiveMiner.Port}
# Create a custom object to convert to json. Type, Pool, CurrentSpeed and EstimatedSpeed are all forced to be arrays, since they sometimes have multiple values.
    [pscustomobject]@{
        Name           = $_.Name
        Miner          = "NemosMiner"
        Version        = $Version
        Path           = Resolve-Path -Relative $_.Path
        Type           = @($_.Type)
        Active         = "{0:dd} Days {0:hh} Hours {0:mm} Minutes" -f ((Get-Date) - $_.Process.StartTime)
        Algorithm      = @($_.Algorithm)
        Pool           = @($MatchingMiner.Pools.PsObject.Properties.Value.Name)
        CurrentSpeed   = @($_.Speed_Live)
        EstimatedSpeed = @($_.Speed)
        'BTC/day'      = $_.Profit
    }
})

$retries = 3
$retrycount = 0
$completed = $false

while (-not $completed) {
    try{
        Invoke-RestMethod -Uri "https://miningpoolhubstats.com/api/worker/$MPHApiKey" -TimeoutSec 10 -Method Post -Body @{workername = $WorkerName; miners = $minerreport; profit = $profit}
        $completed = $true
    } catch {
        if ($retrycount -ge $retries) {
            Write-Warning "Unable to post to monitoring URL..."
        } else {
            Write-Warning "Post to monitoring URL failed. Retrying in 5 seconds."
            Start-Sleep 5
            $retrycount++
        }
    }
}

