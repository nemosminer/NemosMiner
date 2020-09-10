using module ..\Include.psm1

class EthMiner : Miner { 
    [Object]UpdateMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0
        $Sample = [PSCustomObject]@{ }

        $Request = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
        $Response = ""

        Try { 
            $Response = Invoke-TcpRequest -Server "localhost" -Port $this.Port -Request $Request -Timeout $Timeout -ErrorAction Stop
            $Data = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        Catch { 
            Return $null
        }

        $HashRate = [PSCustomObject]@{ }
        $Shares = [PSCustomObject]@{ }

        $HashRate_Name = [String]($this.Algorithm[0])
        $HashRate_Value = [Double]($Data.result[2] -split ";")[0]
        If ($this.Algorithm -match '^(bitcoininterest(-.+|))$') { $HashRate_Value *= 1000 }
        If ($this.Algorithm -match '^(ethash(-.+|))$' -and $Data.result[0] -notmatch "^TT-Miner") { $HashRate_Value *= 1000 }
        If ($this.Algorithm -match '^(neoscrypt(-.+|))$') { $HashRate_Value *= 1000 }

        $Shares_Accepted = [Int64]0
        $Shares_Rejected = [Int64]0

        If ($this.AllowedBadShareRatio) { 
            $Shares_Accepted = [Int64]($Data.result[2] -split ";")[1]
            $Shares_Rejected = [Int64]($Data.result[2] -split ";")[2]
            If ((-not $Shares_Accepted -and $Shares_Rejected -ge 3) -or ($Shares_Accepted -and ($Shares_Rejected * $this.AllowedBadShareRatio -gt $Shares_Accepted))) { 
                $this.SetStatus([MinerStatus]::Failed)
            }
            $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
        }

        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        If ($this.Algorithm -ne $HashRate_Name) { 
            $HashRate_Name = [String]($this.Algorithm -ne $HashRate_Name)
            $HashRate_Value = [Double]($Data.result[4] -split ";")[0]
            If ($this.Algorithm -match '^(ethash(-.+|))$') { $HashRate_Value *= 1000 }
            If ($this.Algorithm -match '^(neoscrypt(-.+|))$') { $HashRate_Value *= 1000 }
            If ($this.Algorithm -match '^(bitcoininterest(-.+|))$') { $HashRate_Value *= 1000 }

            If ($this.AllowedBadShareRatio) { 
                $Shares_Accepted = [Int64]($Data.result[4] -split ";")[1]
                $Shares_Rejected = [Int64]($Data.result[4] -split ";")[2]
                $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, ($Shares_Accepted + $Shares_Rejected)) }
            }

            If ($HashRate_Name) { 
                $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }
            }
        }

        If ($this.CalculatePowerCost) { 
            If ($this.PowerUsageInAPI) { 
                $PowerUsage = [Double]$Data.result[9]
            }
            Else { 
                $PowerUsage = $this.GetPowerUsage()
            }
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
