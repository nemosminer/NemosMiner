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

Remove-Item ".\Wrapper_.txt" -ErrorAction Ignore

$PowerShell = [PowerShell]::Create()
if ($WorkingDirectory -ne "") {$PowerShell.AddScript("Set-Location '$WorkingDirectory'") | Out-Null}
$Command = ". '$FilePath'"
if ($ArgumentList -ne "") {$Command += " $ArgumentList"}
$PowerShell.AddScript("$Command 2>&1 | Write-Verbose -Verbose") | Out-Null
$Result = $PowerShell.BeginInvoke()

Write-Host "NemosMinerv2.5.2 Wrapper Started" -BackgroundColor Yellow -ForegroundColor Black

do {
    Start-Sleep 1

    $PowerShell.Streams.Verbose.ReadAll() | ForEach-Object {
        $Line = $_

        if ($Line -like "*total speed:*" -or $Line -like "*accepted:*") {
            $Words = $Line -split " "
            $HashRate = [Decimal]$Words[$Words.IndexOf(($Words -like "*/s" | Select-Object -Last 1)) - 1]

            switch ($Words[$Words.IndexOf(($Words -like "*/s" | Select-Object -Last 1))]) {
                "kh/s" {$HashRate *= [Math]::Pow(1000, 1)}
                "mh/s" {$HashRate *= [Math]::Pow(1000, 2)}
                "gh/s" {$HashRate *= [Math]::Pow(1000, 3)}
                "th/s" {$HashRate *= [Math]::Pow(1000, 4)}
                "ph/s" {$HashRate *= [Math]::Pow(1000, 5)}
            }

            $HashRate | Set-Content ".\PalginNeoHashrate.txt"
        }
        elseif ($Line -like "*overall speed is*") {
            $Words = $Line -split " "
            $HashRate = [Decimal]($Words -like "*H/s*" -replace ',', '' -replace "[^0-9.]", '' | Select-Object -Last 1)

            switch ($Words -like "*H/s*" -replace "[0-9.,]", '' | Select-Object -Last 1) {
                "KH/s" {$HashRate *= [Math]::Pow(1000, 1)}
                "mH/s" {$HashRate *= [Math]::Pow(1000, 2)}
                "MH/s" {$HashRate *= [Math]::Pow(1000, 2)}
            }
            $HashRate = [int]$HashRate
            $HashRate | Set-Content ".\PalginNeoHashrate.txt"
        }

        $Line
    }

    if ((Get-Process | Where-Object Id -EQ $ControllerProcessID) -eq $null) {$PowerShell.Stop() | Out-Null}
}
until($Result.IsCompleted)

Remove-Item ".\Wrapper_.txt" -ErrorAction Ignore
