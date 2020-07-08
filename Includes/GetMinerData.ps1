using module ".\Include.psm1"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [String]$MinerAPI,
    [Parameter(Mandatory = $true)]
    [String]$MinerJSON #Must be JSON, workaround for 'InvalidOperation: Unable to find type [Miner].'
)

#Load miner API file
. ".\Includes\APIs\$($MinerAPI).ps1"

$Miner = ($MinerJSON | ConvertFrom-Json) -as $MinerAPI
If ($Miner.Benchmark -eq $true -or $Miner.MeasurePowerUsage -eq $true) { $Interval = 2 } Else { $Interval = 5 }

Try { 
    While ($true) { 
        $NextLoop = (Get-Date).AddSeconds($Interval)
        $Miner.UpdateMinerData()
        While ((Get-Date) -lt $NextLoop) { Start-Sleep -Milliseconds 200 }
    }
}
Catch { 
    $Error
    Exit
}
