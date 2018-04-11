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

Remove-Item ".\Wrapper\$Id.txt" -Force -ErrorAction Ignore

$Job = Start-Job -ArgumentList $FilePath, $ArgumentList, $WorkingDirectory {
    param($FilePath, $ArgumentList, $WorkingDirectory)
    if ($WorkingDirectory) {Set-Location $WorkingDirectory}
    if ($ArgumentList) {Invoke-Expression "& '$FilePath' $ArgumentList 2>&1"}
    else {Invoke-Expression "& '$FilePath' 2>&1"}
}

Write-Host "NemosMinerv3.1 Wrapper Started" -BackgroundColor Yellow -ForegroundColor Black

do {
    Start-Sleep 1

    $Job | Receive-Job | ForEach-Object {
        $Line = $_

        if (($Line -like "*total*" -or $Line -like "*accepted*" -or $Line -like ">*") -and $Line -like "*/s*") {
            $Words = $Line -split " "

            $matches = $null

            $HashRate = @()

            $Words -like "*/s*" | ForEach-Object {
                if ($Words[$Words.IndexOf($_)] -match "^((?:\d*\.)?\d+)(.*)$") {
                    $HashRate = [Decimal]$matches[1]
                    $HashRate_Unit = $matches[2]
                }
                else {
                    $HashRate = [Decimal]$Words[$Words.IndexOf($_) - 1]
                    $HashRate_Unit = $Words[$Words.IndexOf($_)]
                }

                switch -wildcard ($HashRate_Unit) {
                     "H/s*" {$HashRate *= [Math]::Pow(1000, 0)}
                     "h/s*" {$HashRate *= [Math]::Pow(1000, 0)}
                    "kh/s*" {$HashRate *= [Math]::Pow(1000, 1)}
                    "mh/s*" {$HashRate *= [Math]::Pow(1000, 2)}
                    "gh/s*" {$HashRate *= [Math]::Pow(1000, 3)}
                    "th/s*" {$HashRate *= [Math]::Pow(1000, 4)}
                    "ph/s*" {$HashRate *= [Math]::Pow(1000, 5)}
                }

                $HashRate | Set-Content ".\cryptonightV7Hashrate.txt" }
        }
        elseif (($Line -replace "\x1B\[[0-?]*[ -/]*[@-~]", "")) {Write-Host ($Line -replace "`n|`r", "")}
    }

    if (-not (Get-Process | Where-Object Id -EQ $ControllerProcessID)) {$Job | Stop-Job}
}
while ($Job.State -eq "Running")

Remove-Item ".\Wrapper\$Id.txt" -Force -ErrorAction Ignore
