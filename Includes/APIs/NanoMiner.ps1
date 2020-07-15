using module ..\Include.psm1

class NanoMiner : Miner { 
    [String]GetCommandLineParameters() { 
        If ($this.Arguments -match "^{.+}$") { 
            Return ($this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue).Commands
        }
        Else { 
            Return $this.Arguments
        }
    }

    CreateConfigFiles() { 
        $Parameters = $this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue

        Try { 
            $ConfigFile = "$(Split-Path $this.Path)\$($Parameters.ConfigFile.FileName)"

            #Write config files. Keep separate files, do not overwrite to preserve optional manual customization
            If (-not (Test-Path $ConfigFile -PathType Leaf)) { 
                $Parameters.ConfigFile.Content | Set-Content $ConfigFile -ErrorAction SilentlyContinue -Force
            }
        }
        Catch { 
            Write-Message -Level Error "Creating miner config files for '$($this.Info)' failed [Error: '$($Error | Select-Object -Index 0)']."
            Return
        }
    }

    [Object]UpdateMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/stats"
        $Response = ""

        Try { 
            If ($Global:PSVersionTable.PSVersion -ge [System.Version]("6.2.0")) { 
                $Response = Invoke-WebRequest $Request -TimeoutSec $Timeout -DisableKeepAlive -MaximumRetryCount 3 -RetryIntervalSec 1 -ErrorAction Stop
            }
            Else { 
                $Response = Invoke-WebRequest $Request -UseBasicParsing -TimeoutSec $Timeout -DisableKeepAlive -ErrorAction Stop
            }
            $Data = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = ""
        $HashRate_Value = [Double]0
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        $Data.Algorithms | ForEach-Object { $_ | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name } | Select-Object -Unique | ForEach-Object { 
            $HashRate_Name = [String]($this.Algorithm -match '^(' + [Regex]::Escape("$(Get-Algorithm $_)") + '(-.+|))$')[0]
            $HashRate_Value = [Double]($Data.Algorithms.$_.Total.Hashrate | Measure-Object -Sum).Sum

            If ($this.AllowedBadShareRatio) { 
                $Shares_Accepted = [Int64]($Data.Algorithms.$_.Total.Accepted | Measure-Object -Sum).Sum
                $Shares_Rejected = [Int64]($Data.Algorithms.$_.Total.Denied | Measure-Object -Sum).Sum
                $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $($Shares_Accepted + $Shares_Rejected)) }
            }

            If ($HashRate_Name) { 
                $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
            }
        }

        If ($this.ReadPowerusage) { 
            $PowerUsage = $this.GetPowerUsage()
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            $Sample = [PSCustomObject]@{ 
                Date       = (Get-Date).ToUniversalTime()
                HashRate   = $HashRate
                PowerUsage = $PowerUsage
                Shares     = $Shares
            }
            Return $Sample
        }
        Return $null
    }
}

