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

Remove-Item ".\energi.txt" -ErrorAction Ignore

$PowerShell = [PowerShell]::Create()
if ($WorkingDirectory -ne "") {$PowerShell.AddScript("Set-Location '$WorkingDirectory'") | Out-Null}
$Command = ". '$FilePath'"
if ($ArgumentList -ne "") {$Command += " $ArgumentList"}
$PowerShell.AddScript("$Command 2>&1 | Write-Verbose -Verbose") | Out-Null
$Result = $PowerShell.BeginInvoke()


do {
    Start-Sleep 1

    $PowerShell.Streams.Verbose.ReadAll() | ForEach-Object {
        $Line = $_

        if ($Line -like "*speed*") {
            $Words = $Line -split " "

            $matches = $null

            if ($Words[$Words.IndexOf(($Words -like "Mh/s" | Select-Object -First 1))] -match "^((?:\d*\.)?\d+)(.*)$") {
                $HashRate = [Decimal]$matches[1]
                $HashRate_Unit = $matches[2]
            }
            else {
                $HashRate = [Decimal]$Words[$Words.IndexOf(($Words -like "Mh/s" | Select-Object -First 1)) - 1]
                $HashRate_Unit = $Words[$Words.IndexOf(($Words -like "Mh/s" | Select-Object -First 1))]
            }

            switch ($HashRate_Unit) {
                "Mh/s" {$HashRate *= [Math]::Pow(1000, 2)}
         
            }

            $HashRate | ConvertTo-Json | Set-Content ".\energi.txt"
        }

        Write-Host $Line -NoNewline
    }

    if ((Get-Process | Where-Object Id -EQ $ControllerProcessID) -eq $null) {$PowerShell.Stop() | Out-Null}
}
until($Result.IsCompleted)

Remove-Item ".\energi.txt" -ErrorAction Ignore
