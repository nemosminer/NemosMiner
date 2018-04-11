param(
    [Parameter(Mandatory = $true)]
    [Int]$ControllerProcessID, 
    [Parameter(Mandatory = $true)]
    [String]$Id, 
    [Parameter(Mandatory = $true)]
    [String]$FilePath, 
    [Parameter(Mandatory = $false)]
    [String]$ArgumentList = "", 
    [Parameter(Mandatory = $false)]
    [String]$WorkingDirectory = ""
)

Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

. .\Include.ps1

$PowerShell = [PowerShell]::Create()
if ($WorkingDirectory -ne "") {$PowerShell.AddScript("Set-Location '$WorkingDirectory'") | Out-Null}
$Command = ". '$FilePath'"
if ($ArgumentList -ne "") {$Command += " $ArgumentList"}
$PowerShell.AddScript("$Command 2>&1 | Write-Verbose -Verbose") | Out-Null
$Result = $PowerShell.BeginInvoke()

Write-Host "NemosMinerv3.1 Wrapper Started" -BackgroundColor Yellow -ForegroundColor Black

do {
    Start-Sleep 1

    $PowerShell.Streams.Verbose.ReadAll() | ForEach-Object {
        $Line = $_

        if ($Line -like "*total speed:*" -or $Line -like "*accepted:*") {
            $Words = $Line -split " "
            $HashRate = [Decimal]$Words[$Words.IndexOf(($Words -like "*/s" | Select-Object -Last 1)) - 1]
            $HashRate | Set-Content ".\Wrapper_$Id.txt"
        }

        $Line
    }

    if ((Get-Process | Where-Object Id -EQ $ControllerProcessID) -eq $null) {$PowerShell.Stop() | Out-Null}
}
until($Result.IsCompleted)
