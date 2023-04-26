<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           XmRig.ps1
Version:        4.3.4.3
Version date:   23 April 2023
#>

class XmRig : Miner { 
    [Void] CreateConfigFiles() { 
        $Parameters = $this.Arguments | ConvertFrom-Json -ErrorAction SilentlyContinue

        Try { 
            $ConfigFile = "$(Split-Path $this.Path)\$($Parameters.ConfigFile.FileName)"

            $ThreadsConfig = [PSCustomObject]@{ }
            $ThreadsConfigFile = "$(Split-Path $this.Path)\$($Parameters.ThreadsConfigFileName)"

            If ($Parameters.ConfigFile.Content.threads) { 
                #Write full config file, ignore possible hw change
                $Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
            }
            else { 
                #Check if we have a valid hw file for all installed hardware. If hardware / device order has changed we need to re-create the config files. 
                $ThreadsConfig = Get-Content $ThreadsConfigFile -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
                If ($ThreadsConfig.Count -lt 1) { 
                    If (Test-Path -Path "$(Split-Path $this.Path)\$($this.Algorithms[0] | Select-Object -First 1)-*.json" -PathType Leaf) { 
                        #Remove old config files, thread info is no longer valid
                        Write-Message -Level Warn "Hardware change detected. Deleting existing configuration files for miner '$($this.Info)'."
                        Remove-Item "$(Split-Path $this.Path)\ThreadsConfig-$($this.Algorithms[0] | Select-Object -First 1)-*.json" -Force -ErrorAction SilentlyContinue
                    }
                    #Temporarily start miner with pre-config file (without threads config). Miner will then update hw config file with threads info
                    $Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10 | Out-File -FilePath $ThreadsConfigFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                    $this.Process = Invoke-CreateProcess -BinaryPath $this.Path -ArgumentList $Parameters.HwDetectArguments -WorkingDirectory (Split-Path $this.Path) -MinerWindowStyle $this.MinerWindowStyle -Priority $this.ProcessPriority -EnvBlock $this.Environment -JobName $this.Info -LogFile $this.LogFile

                    If ($this.Process) { 
                        $this.ProcessId = [Int32]((Get-CIMInstance CIM_Process | Where-Object { $_.ExecutablePath -eq $this.Path -and $_.CommandLine -like "*$($this.Path)*$($Parameters.HwDetectArguments)*" }).ProcessId)
                        For ($WaitForThreadsConfig = 0; $WaitForThreadsConfig -le 60; $WaitForThreadsConfig ++) { 
                            If ($ThreadsConfig = @(Get-Content $ThreadsConfigFile -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue).threads) { 
                                If ($this.DeviceNames -like "GPU#*") { 
                                    ConvertTo-Json -InputObject @($ThreadsConfig | Sort-Object -Property Index -Unique) -Depth 10 | Out-File -FilePath $ThreadsConfigFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                                }
                                Else { 
                                    ConvertTo-Json -InputObject @($ThreadsConfig | Select-Object -Unique) -Depth 10 | Out-File -FilePath $ThreadsConfigFile -Force -Encoding -ErrorAction SilentlyContinue
                                }
                                Break
                            }
                            Start-Sleep -Milliseconds 500
                        }
                        Stop-Process -Id $this.ProcessId -Force
                        $this.Process = $null
                    }
                    Else { 
                        Write-Message -Level Error "Running temporary miner failed - cannot create threads config files for '$($this.Info)' [Error: '$($Error | Select-Object -First 1)']."
                        Return
                    }
                }

                If (-not ((Get-Content $ConfigFile -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue).threads)) { 
                    #Threads config in config file is invalid, retrieve from threads config file
                    $ThreadsConfig = Get-Content $ThreadsConfigFile | ConvertFrom-Json
                    If ($ThreadsConfig.Count -ge 1) { 
                        #Write config files. Overwrite because we need to add thread info
                        If ($this.DeviceNames -like "GPU#*") { 
                            $Parameters.ConfigFile.Content | Add-Member threads ([Array](($ThreadsConfig | Where-Object { $Parameters.Devices -contains $_.index })) * $Parameters.Threads) -Force
                        }
                        Else { 
                            #CPU thread config does not contain index information
                            $Parameters.ConfigFile.Content | Add-Member threads ([Array]($ThreadsConfig * $Parameters.Threads)) -Force
                        }
                        $Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigFile -Force -Encoding utf8NoBOM -ErrorAction SilentlyContinue
                    }
                    Else { 
                        Write-Message -Level Error "Error parsing threads config file - cannot create miner config files for '$($this.Info)' [Error: '$($Error | Select-Object -First 1)']."
                        Return
                    }
                }
            }
        }
        Catch { 
            Write-Message -Level Error "Creating miner config files for '$($this.Info)' failed [Error: '$($Error | Select-Object -First 1)']."
            Return
        }
    }

    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
        $PowerUsage = [Double]0

        $Request = "http://127.0.0.1:$($this.Port)/api.json"

        Try { 
            $Data = Invoke-RestMethod -Uri $Request -TimeoutSec $Timeout
        }
        Catch { 
            Return $null
        }

        If (-not $Data) { Return $null }

        $HashRate = [PSCustomObject]@{ }
        $HashRate_Name = [String]$this.Algorithms[0]
        $HashRate_Value = [Double]$Data.hashrate.total[0]
        If (-not $HashRate_Value) { $HashRate_Value = [Double]$Data.hashrate.total[1] } #fix
        If (-not $HashRate_Value) { $HashRate_Value = [Double]$Data.hashrate.total[2] } #fix
        $HashRate | Add-Member @{ $HashRate_Name = [Double]$HashRate_Value }

        $Shares = [PSCustomObject]@{ }
        $Shares_Accepted = [Int64]$Data.results.shares_good
        $Shares_Rejected = [Int64]($Data.results.shares_total - $Data.results.shares_good)
        $Shares_Invalid = [Int64]0
        $Shares | Add-Member @{ $HashRate_Name = @($Shares_Accepted, $Shares_Rejected, $Shares_Invalid, ($Shares_Accepted + $Shares_Rejected + $Shares_Invalid)) }

        If ($this.ReadPowerUsage) { 
            $PowerUsage = $this.GetPowerUsage()
        }

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            Return [PSCustomObject]@{ 
                Date       = (Get-Date).ToUniversalTime()
                HashRate   = $HashRate
                PowerUsage = $PowerUsage
                Shares     = $Shares
            }
        }
        Return $null
    }
}