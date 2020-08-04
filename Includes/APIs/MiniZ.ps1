using module ..\Include.psm1

class MiniZ : Miner { 
    [Object]UpdateMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = '{ "id":"0", "method":"getstat" }'
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest "localhost" -Port $this.Port -Request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = [String]$this.Algorithm[0]
        $HashRate_Value = [Double]($Data.result.speed_sps | Measure-Object -Sum).Sum
        If (-not $HashRate_Value) { $HashRate_Value = [Double]($Data.result.sol_ps | Measure-Object -Sum).Sum } #fix

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = [Int64]($Data.result.accepted_shares | Measure-Object -Sum).Sum
            $Shares_Rejected = [Int64]($Data.result.rejected_shares | Measure-Object -Sum).Sum
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $($Shares_Accepted + $Shares_Rejected)) }
        }

        If ($HashRate_Name) { 
            $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
        }

        If ($this.ReadPowerusage) { 
            $PowerUsage = [Double]($Data.result.gpu_power_usage | Measure-Object -Sum).Sum 
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
