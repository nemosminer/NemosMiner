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

do {
    Start-Sleep 1

    $PowerShell.Streams.Verbose.ReadAll() | ForEach-Object {
        $Line = $_

        if ($Line -like "*Total*") {
            $Words = $Line -split " "
            $HashRate = [Decimal]$Words[$Words.IndexOf(($Words -like "*/s" | Select-Object -First 1)) - 1]

            switch ($Words[$Words.IndexOf(($Words -like "*/s" | Select-Object -First 1))]) {
                "s/s" {$HashRate *= [Math]::Pow(1000, 0)}
                "ks/s" {$HashRate *= [Math]::Pow(1000, 1)}
                "ms/s" {$HashRate *= [Math]::Pow(1000, 2)}
                "gs/s" {$HashRate *= [Math]::Pow(1000, 3)}
                "ts/s" {$HashRate *= [Math]::Pow(1000, 4)}
                "ps/s" {$HashRate *= [Math]::Pow(1000, 5)}
            }

            $HashRate | Set-Content ".\Bminer.txt"
        }
        elseif ($Line -like "*Total*") {
            $Words = $Line -split " "
            $HashRate = [Decimal]($Words -like "*/s*" -replace ',', '' -replace "[^0-9.]", '' | Select-Object -First 1)

            switch ($Words -like "*S/s*" -replace "[0-9.,]", '' | Select-Object -First 1) {
                "S/s" {$HashRate *= [Math]::Pow(1000, 0)}
                "KS/s" {$HashRate *= [Math]::Pow(1000, 1)}
                "mS/s" {$HashRate *= [Math]::Pow(1000, 2)}
                "MS/s" {$HashRate *= [Math]::Pow(1000, 2)}
            }
            $HashRate = [int]$HashRate
            $HashRate | Set-Content ".\Bminer.txt"
        }
        elseif ($Line -like "*Average speed*") {
            $Words = $Line -split " "
            $HashRate = [Decimal]$Words[$Words.IndexOf(($Words -like "*/s" | Select-Object -Last 1)) - 1]

            switch ($Words[$Words.IndexOf(($Words -like "*/s" | Select-Object -Last 1))]) {
                
                "mh/s" {$HashRate *= [Math]::Pow(1000, 1)}
                "MH/s" {$HashRate *= [Math]::Pow(1000, 1)}
               
            }

            $HashRate | Set-Content ".\Bminer.txt"
        }
        elseif ($Line -like "*Average speed*") {
            $Words = $Line -split " "
            $HashRate = [Decimal]($Words -like "*/s*" -replace ',', '' -replace "[^0-9.]", '' | Select-Object -Last 1)

            switch ($Words -like "*/s*" -replace "[0-9.,]", '' | Select-Object -Last 1) {
              
                "mH/s" {$HashRate *= [Math]::Pow(1000, 1)}
                "MH/s" {$HashRate *= [Math]::Pow(1000, 1)}
             
            }
            $HashRate = [int]$HashRate
            $HashRate | Set-Content ".\Bminer.txt"
        }

        $Line
    }

    if ((Get-Process | Where-Object Id -EQ $ControllerProcessID) -eq $null) {$PowerShell.Stop() | Out-Null}
}
until($Result.IsCompleted)

Remove-Item ".\Wrapper_.txt" -ErrorAction Ignore
