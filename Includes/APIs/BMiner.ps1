using module ..\Include.psm1

class BMiner : Miner { 
    [Object]UpdateMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/api/v1/status/solver"
        $Request2 = "http://localhost:$($this.Port)/api/v1/status/stratum"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If ($this.AllowedBadShareRatio) { 
            #Read stratum info from API
            Try { 
                $Data | Add-Member stratums (Invoke-RestMethod -Uri $Request2 -TimeoutSec $Timeout).stratums
            }
            Catch { 
                Return $null
            }
        }

        If (-not $Data.devices."0".solvers) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = ""
        $HashRate_Value = [Double]0
        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        [Int]$Index = 0

        $Data.devices."0".solvers | ForEach-Object { 
            $Index = $Data.devices."0".solvers.IndexOf($_)
            $HashRate_Name = [String]$this.Algorithm[$Index]
            $HashRate_Value = [Double](($Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Data.devices.$_.solvers[$Index] } ).speed_info.hash_rate | Measure-Object -Sum).Sum
            If (-not $HashRate_Value) { $HashRate_Value = [Double](($Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { $Data.devices.$_.solvers[$Index] } ).speed_info.solution_rate | Measure-Object -Sum).Sum}

            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
            If ($this.AllowedBadShareRatio) { 
                $Shares_Accepted = [Int64]$Data.stratums.($Data.stratums | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { (Get-Algorithm $_) -eq $HashRate_Name }).accepted_shares
                $Shares_Rejected = [Int64]$Data.stratums.($Data.stratums | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | Where-Object { (Get-Algorithm $_) -eq $HashRate_Name }).rejected_shares
                $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
            }
        }

        If ($this.CalculatePowerCost) { 
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
