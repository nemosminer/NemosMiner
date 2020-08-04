using module ..\Include.psm1

class Cast : Miner { 
    [Object]UpdateMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = [String]$this.Algorithm[0]
        $HashRate_Value = [Double]($Data.devices.hash_rate | Measure-Object -Sum).Sum / 1000

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = [Int64]$Data.shares.num_accepted
            $Shares_Rejected = [Int64]($Data.shares.num_rejected + $Data.shares.num_rejected + $Data.shares.num_network_fail + $Data.shares.num_outdated)
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $($Shares_Accepted + $Shares_Rejected)) }
        }

        If ($HashRate_Name) { 
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
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
