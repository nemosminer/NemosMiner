using module ..\Include.psm1

class lolMiner : Miner { 
    [Object]UpdateMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/summary"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = [String]$this.Algorithm[0]
        $HashRate_Unit = [Int64]1
        Switch ($Data.Session.Performance_Unit) { 
            "kh/s"  { $HashRate_Unit = [Math]::Pow(10,3) }
            "Mh/s"  { $HashRate_Unit = [Math]::Pow(10,6) }
            "GH/s"  { $HashRate_Unit = [Math]::Pow(10,9) }
            "TH/s"  { $HashRate_Unit = [Math]::Pow(10,12) }
            "PH/s"  { $HashRate_Unit = [Math]::Pow(10,15) }
            "EH/s"  { $HashRate_Unit = [Math]::Pow(10,18) }
            "ZH/s"  { $HashRate_Unit = [Math]::Pow(10,21) }
            "ZH/s"  { $HashRate_Unit = [Math]::Pow(10,24) }
            Default { $HashRate_Unit = 1 }
        }
        $HashRate_Value = [Double]($Data.Session.Performance_Summary * $HashRate_Unit)

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = [Int64]$Data.Session.Accepted
            $Shares_Rejected = [Int64]($Data.Session.Submitted - $Data.Session.Accepted)
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
        }

        If ($this.CalculatePowerCost) { 
            $PowerUsage = [Double]($Data.Session.TotalPower)
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
