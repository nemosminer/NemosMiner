using module ..\Include.psm1

class BMiner : Miner { 
    [Object]UpdateMinerData () { 
        $Server = "localhost"
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/api/v1/status/solver"
        $Request2 = "http://$($Server):$($this.Port)/api/v1/status/stratum"
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
            Return $null
        }

        If ($this.AllowedBadShareRatio) { 
            #Read stratum info from API
            Try { 
                If ($Global:PSVersionTable.PSVersion -ge [System.Version]("6.2.0")) { 
                    $Data | Add-Member stratums (Invoke-WebRequest $Request2 -TimeoutSec $Timeout -DisableKeepAlive -MaximumRetryCount 3 -RetryIntervalSec 1 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop).stratums
                }
                Else { 
                    $Data | Add-Member stratums (Invoke-WebRequest $Request2 -TimeoutSec $Timeout -UseBasicParsing -DisableKeepAlive -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop).stratums
                }
            }
            Catch { 
                Return $null
            }
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = ""
        $HashRate_Value = [Double]0
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        $Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Data.devices.$_.solvers | ForEach-Object { $_.Algorithm } } | Select-Object -Unique | ForEach-Object { 
            If ( $_ -eq "equihash1445" -and $this.Algorithm -contains "EquihashBTG") { $HashRate_Name = "EquihashBTG" }
            ELse { $HashRate_Name = [String](Get-Algorithm $_) }
            $HashRate_Value = [Double]($Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Data.devices.$_.solvers } | Where-Object algorithm -EQ $_ | ForEach-Object { $_.speed_info.hash_rate } | Measure-Object -Sum).Sum
            If (-not $HashRate_Value) { $HashRate_Value = [Double]($Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Data.devices.$_.solvers } | Where-Object algorithm -EQ $_ | ForEach-Object { $_.speed_info.solution_rate } | Measure-Object -Sum).Sum }

            If ($this.AllowedBadShareRatio) { 
                $Shares_Accepted = [Int64]$Data.stratums.$_.accepted_shares
                $Shares_Rejected = [Int64]$Data.stratums.$_.rejected_shares
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
