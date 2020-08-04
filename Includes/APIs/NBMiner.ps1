using module ..\Include.psm1

class NBMiner : Miner { 
    [Object]UpdateMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = "http://localhost:$($this.Port)/api/v1/status"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0
        If ($Data.stratum.dual_mine) { 
            $HashRate_Name = [String](Get-Algorithm ($data.stratum.algorithm -split '_' | Select-Object -Index 0))
        }
        Else { 
            $HashRate_Name = [String](Get-Algorithm $data.stratum.algorithm)
        }
        $HashRate_Value = [Double]$Data.miner.total_hashrate_raw

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = [Int64]$Data.stratum.accepted_shares
            $Shares_Rejected = [Int64]$Data.stratum.rejected_shares
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $($Shares_Accepted + $Shares_Rejected)) }
        }

        If ($HashRate_Name) { 
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
        }

        If ($Data.stratum.dual_mine) { 
            $HashRate_Name = [String](Get-Algorithm ($data.stratum.algorithm -split '_' | Select-Object -Index 1))
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$Data.miner.total_hashrate2_raw }

            If ($this.AllowedBadShareRatio) { 
                $Shares_Accepted = [Int64]$Data.stratum.accepted_shares2
                $Shares_Rejected = [Int64]$Data.stratum.rejected_shares2
                $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $($Shares_Accepted + $Shares_Rejected)) }
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


