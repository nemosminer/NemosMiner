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
File:           \Includes\MinerAPIs\FireIce.ps1
Version:        5.0.2.1
Version date:   2023/12/09
#>

Class Fireice : Miner { 
    [Void]CreateConfigFiles() { 
        Try { 
            $Parameters = $this.Arguments | ConvertFrom-Json -ErrorAction Ignore
            $ConfigFile = "$(Split-Path $this.Path)\$($Parameters.ConfigFile.FileName)"
            $PoolFile = "$(Split-Path $this.Path)\$($Parameters.PoolFile.FileName)"
            $PlatformThreadsConfigFile = "$(Split-Path $this.Path)\$($Parameters.PlatformThreadsConfigFileName)"
            $MinerThreadsConfigFile = "$(Split-Path $this.Path)\$($Parameters.MinerThreadsConfigFileName)"
            $ThreadsConfig = ""

            # Write pool config file, overwrite every time
            ($Parameters.PoolFile.Content | ConvertTo-Json -Depth 10) -replace '^{' -replace '}$', ',' | Out-File -LiteralPath $PoolFile -Force -ErrorAction Ignore
            # Write config file, keep existing file to preserve user custom config
            If (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) { ($Parameters.ConfigFile.Content | ConvertTo-Json -Depth 10) -replace '^{' -replace '}$' | Out-File -LiteralPath $ConfigFile -Force -ErrorAction Ignore}

            # Check if we have a valid hw file for all installed hardware. If hardware / device order has changed we need to re-create the config files. 
            If (-not (Test-Path -LiteralPath $PlatformThreadsConfigFile -PathType Leaf)) { 
                If (Test-Path -LiteralPath "$(Split-Path $this.Path)\$MinerThreadsConfigFile" -PathType Leaf) { 
                    # Remove old config files, thread info is no longer valid
                    Write-Message -Level Warn "Hardware change detected. Deleting existing configuration files for miner $($this.Info)'."
                    Remove-Item -Path "$(Split-Path $this.Path)\$MinerThreadsConfigFile" -Force -ErrorAction Ignore
                }

                # Temporarily start miner with empty thread conf file. The miner will then create a hw config file with default threads info for all platform hardware
                $this.ProcessJob = Invoke-CreateProcess -BinaryPath $this.Path -ArgumentList $Parameters.HwDetectArguments -WorkingDirectory (Split-Path $this.Path) -WindowStyle $this.WindowStyle -EnvBlock $this.Environment -JobName $this.Info -LogFile $this.LogFile

                # Sometimes the process cannot be found instantly
                $Loops = 100
                Do { 
                    If ($this.ProcessId = ($this.ProcessJob | Receive-Job | Select-Object -ExpandProperty ProcessId)) { 
                        If (Test-Path -LiteralPath $PlatformThreadsConfigFile -PathType Leaf) { 
                            # Read hw config created by miner
                            $ThreadsConfig = (Get-Content -Path $PlatformThreadsConfigFile) -replace '^\s*//.*' | Out-String
                            # Set bfactor to 11 (default is 6 which makes PC unusable)
                            $ThreadsConfig = $ThreadsConfig -replace '"bfactor"\s*:\s*\d,', '"bfactor" : 11,'
                            # Reformat to proper json
                            $ThreadsConfigJson = "{$($ThreadsConfig -replace '\/\*.*' -replace '\*\/' -replace '\*.+' -replace '\s' -replace ',\},]', '}]' -replace ',\},\{', '},{' -replace '},]', '}]' -replace ',$')}" | ConvertFrom-Json
                            # Keep one instance per gpu config
                            $ThreadsConfigJson | Add-Member gpu_threads_conf ($ThreadsConfigJson.gpu_threads_conf | Sort-Object -Property Index -Unique) -Force
                            # Write json file
                            $ThreadsConfigJson | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $PlatformThreadsConfigFile -Force -ErrorAction Ignore
                            Break
                        }
                    }
                    $Loops --
                    Start-Sleep -Milliseconds 50
                } While ($Loops -gt 0)
                Remove-Variable Loops

                If (Test-Path -LiteralPath $PlatformThreadsConfigFile -PathType Leaf) {
                    If ($this.Process) { 
                        $this.Process.CloseMainWindow()
                        $this.Process = $null
                    }

                    If ($this.ProcessId) { 
                        If (Get-Process -Id $this.ProcessId -ErrorAction Ignore) { Stop-Process -Id $this.ProcessId -Force -ErrorAction Ignore }
                        $this.ProcessId = $null
                    }
                }
                Else { 
                    Write-Message -Level Error "Running temporary miner failed - cannot create threads config file '$($this.Info)' [Error: '$($Error | Select-Object -First 1)']."
                    Return
                }
            }
            If (-not (Test-Path $MinerThreadsConfigFile -PathType Leaf)) { 
                # Retrieve hw config from platform config file
                $ThreadsConfigJson = Get-Content -Path $PlatformThreadsConfigFile | ConvertFrom-Json -ErrorAction Ignore
                # Filter index for current cards and apply threads
                $ThreadsConfigJson | Add-Member gpu_threads_conf ([Array]($ThreadsConfigJson.gpu_threads_conf | Where-Object { $Parameters.Devices -contains $_.Index }) * $Parameters.Threads) -Force
                # Create correct numer of CPU threads
                $ThreadsConfigJson | Add-Member cpu_threads_conf ([Array]$ThreadsConfigJson.cpu_threads_conf * $Parameters.Threads) -Force
                # Write config file
                ($ThreadsConfigJson | ConvertTo-Json -Depth 10) -replace '^{' -replace '}$' | Out-File -LiteralPath $MinerThreadsConfigFile -Force -ErrorAction Ignore
            }
        }
        catch { 
            Write-Message -Level Error "Creating miner config files for '$($this.Info)' failed [Error: '$($Error | Select-Object -First 1)']."
            Return
        }
    }

    [Object]GetMinerData () { 
        $Timeout = 5 #seconds
        $Data = [PSCustomObject]@{ }
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

        $PowerConsumption = [Double]0

        If ($HashRate.PSObject.Properties.Value -gt 0) { 
            If ($this.ReadPowerConsumption) { 
                $PowerConsumption = $this.GetPowerConsumption()
            }

            Return [PSCustomObject]@{ 
                Date             = ([DateTime]::Now).ToUniversalTime()
                HashRate         = $HashRate
                PowerConsumption = $PowerConsumption
                Shares           = $Shares
            }
        }
        Return $null
    }
}