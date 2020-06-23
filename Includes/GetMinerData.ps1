using module .\Include.psm1

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [PSCustomObject]$Miner
)

$ProgressPreference = "SilentlyContinue"

$API = [String]$Miner.API
$Port = [UInt16]$Miner.Port
$Server = "localhost"
$Timeout = [Int16]45 #Seconds
$DeviceName = [String[]]$Miner.DeviceName
$Algorithms = [String[]]$Miner.Algorithm

$RegistryHive = "HKCU:\Software\HWiNFO64\VSB"

Try { 
    While ($Algorithms) { 

        If ($Miner.Benchmark -eq $true -or $Miner.MeasurePowerUsage -eq $true) { Start-Sleep -Seconds 0 } Else { Start-Sleep -Seconds 2 }

        [Double]$HashRate_Value = 0
        [Double]$HashRateDual_Value = 0
        [Double]$PowerUsage_Value = 0
        [Double[]]$PowerUsage = @()

        If ($Miner.ReadPowerUsage) {
            #read power usage
            If ((Test-Path $RegistryHive) -and $DeviceName) { 
                $RegistryData = Get-ItemProperty $RegistryHive
                $RegistryData.PSObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @($DeviceName | Select-Object) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                    $PowerUsage_Value = [Double]($RegistryData.($_.Name -replace "Label", "Value") -split ' ' | Select-Object -Index 0)
                    If ($PowerUsage_Value -gt 0) { $PowerUsage += $PowerUsage_Value }
                }
            }
        }

        Switch ($Miner.API) { 
            "bminer" { 
                $Request = Invoke-HTTPRequest $Server $Port "/api/v1/status/solver" $Timeout
                If ($Request) { 
                    $Data = $Request.content | ConvertFrom-Json 
                    $Data.devices | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                        If ($Data.devices.$_.solvers[0].speed_info.hash_rate) { $HashRate_Value += [Double]$Data.devices.$_.solvers[0].speed_info.hash_rate }
                        Else { $HashRate_Value += [Double]$Data.devices.$_.solvers[0].speed_info.solution_rate }
                        If ($Data.devices.$_.solvers[1].speed_info.hash_rate) { $HashRateDual_Value += [Double]$Data.devices.$_.solvers[1].speed_info.hash_rate }
                        Else { $HashRateDual_Value += [Double]$Data.devices.$_.solvers[1].speed_info.solution_rate }
                    }
                }
            }

            "castxmr" { 
                $Request = Invoke-HTTPRequest $Server $Port "" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json 
                    $HashRate_Value = [Double]($Data.devices.hash_rate | Measure-Object -Sum).Sum / 1000
                }
            }

            "ccminer" { 
                $Request = Invoke-TcpRequest $Server $Port "summary" $Timeout
                If ($Request) { 
                    $Data = $Request -split ";" | ConvertFrom-StringData
                    $HashRate_Value = If ([Double]$Data.KHS -ne 0 -or [Double]$Data.ACC -ne 0) { [Double]$Data.KHS * 1000 }
                }
            }

            "claymore" { 
                $Request = Invoke-HTTPRequest $Server $Port "" $Timeout
                If ($Request) { 
                    $Data = $Request.Content.Substring($Request.Content.IndexOf("{ "), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{ ") + 1) | ConvertFrom-Json
                    $HashRate_Value = [Double]$Data.result[2].Split(";")[0] * 1000
                    $HashRateDual_Value = [Double]$Data.result[4].Split(";")[0] * 1000
                }
            }

            "claymorev2" { 
                $Request = Invoke-HTTPRequest $Server $Port "" $Timeout
                If ($Request -ne "" -and $Request -ne $null) { 
                    $Data = $Request.Content.Substring($Request.Content.IndexOf("{ "), $Request.Content.LastIndexOf("}") - $Request.Content.IndexOf("{ ") + 1) | ConvertFrom-Json
                    $HashRate_Value = [Double]$Data.result[2].Split(";")[0] 
                }
            }

            "dtsm" { 
                $Request = Invoke-TcpRequest $Server $Port "empty" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json | Select-Object  -ExpandProperty result 
                    $HashRate_Value = [Double](($Data.sol_ps) | Measure-Object -Sum).Sum 
                }
            }

            "ethminer" { 
                $Parameters = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json -Compress
                $Request = Invoke-TcpRequest $Server $Port $Parameters $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.result[2] -split ';')[0]) * 1000
                }
            }

            "ewbf" { 
                $Message = @{ id = 1; method = "getstat" } | ConvertTo-Json -Compress
                $Request = Invoke-TcpRequest $Server $Port $message $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.result.speed_sps) | Measure-Object -Sum).Sum
                }
            }

            "fireice" { 
                $Request = Invoke-HTTPRequest $Server $Port "/h" $Timeout
                If ($Request) { 
                    $Data = $Request.Content -split "</tr>" -match "total*" -split "<td>" -replace "<[^>]*>", ""
                    $HashRate_Value = $Data[1]
                    If (-not $HashRate_Value) { $HashRate_Value = $Data[2] }
                    If (-not $HashRate_Value) { $HashRate_Value = $Data[3] }
                }
            }

            "gminer" { 
                $Request = Invoke-HTTPRequest $Server $Port "/stat" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]($Data.devices.speed | Measure-Object -Sum).Sum
                    $HashRateDual_Value = [Double]($Data.devices.speed2 | Measure-Object -Sum).Sum
                }
            }

            "gminerdual" { 
                $Request = Invoke-HTTPRequest $Server $Port "/stat" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]($Data.devices.speed2 | Measure-Object -Sum).Sum
                    $HashRateDual_Value = [Double]($Data.devices.speed | Measure-Object -Sum).Sum
                }
            }

            "grinpro" { 
                $Request = Invoke-HTTPRequest $Server $Port "/api/status" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.workers.graphsPerSecond) | Measure-Object -Sum).Sum
                }
            }

            "lol" { 
                $Request = Invoke-HTTPRequest $Server $Port "/summary" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]$data.Session.Performance_Summary
                }
            }

            "miniz" { 
                $Message = '{ "id":"0", "method":"getstat"}'
                $Request = Invoke-TcpRequest $Server $Port $message $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.result.speed_sps) | Measure-Object -Sum).Sum
                }
            }

            "nanominer" { 
                $Request = Invoke-HTTPRequest $Server $Port "/stat" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $Data.Statistics.Devices | ForEach-Object { 
                        $DeviceData = $_
                        Switch ($DeviceData.Hashrates[0].unit) { 
                            "KH/s"  { $HashRate_Value += [Double]($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 1)) }
                            "MH/s"  { $HashRate_Value += [Double]($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 2)) }
                            "GH/s"  { $HashRate_Value += [Double]($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 3)) }
                            "TH/s"  { $HashRate_Value += [Double]($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 4)) }
                            "PH/s"  { $HashRate_Value += [Double]($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 5)) }
                            default { $HashRate_Value += [Double]($DeviceData.Hashrates[0].Hashrate * [Math]::Pow(1000, 0)) }
                        }
                    }
                }
            }

            "nbminer" { 
                $Request = Invoke-HTTPRequest $Server $Port "/api/v1/status" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    If ($Algorithms.Count -eq 2) { 
                        $HashRate_Value = [Double]$Data.miner.total_hashrate2_raw
                        $HashRateDual_Value = [Double]$Data.miner.total_hashrate_raw
                    }
                    Else { 
                        $HashRate_Value = [Double]$Data.miner.total_hashrate_raw
                    }
                }
            }

            "nheq" { 
                $Request = Invoke-TcpRequest $Server $Port "status" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]$Data.result.speed_ips * 1000000
                }
            }

            "palgin" { 
                $Request = Invoke-TcpRequest $Server $Port  "summary" $Timeout
                If ($Request) { 
                    $Data = $Request -split ";"
                    $HashRate_Value = [Double]($Data[5] -split '=')[1] * 1000
                }
            }

            "prospector" { 
                $Request = Invoke-HTTPRequest $Server $Port "/api/v0/hashrates" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double]($Data.rate | Measure-Object -Sum).sum
                }
            }

            "srb" { 
                $Request = Invoke-HTTPRequest $Server $Port "" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = @(
                        [Double]$Data.HashRate_total_now
                        [Double]$Data.HashRate_total_5min
                    ) | Where-Object { $_ -gt 0 } | Select-Object -First 1
                }
            }

            "ttminer" { 
                $Parameters = @{ id = 1; jsonrpc = "2.0"; method = "miner_getstat1" } | ConvertTo-Json  -Compress
                $Request = Invoke-TcpRequest $Server $Port $Parameters $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json
                    $HashRate_Value = [Double](($Data.result[2] -split ';')[0]) #* 1000
                }
            }

            "xgminer" { 
                $Message = @{ command = "summary"; parameter = "" } | ConvertTo-Json -Compress
                $Request = Invoke-TcpRequest $Server $Port $Message $Timeout

                If ($Request) { 
                    $Data = $Request.Substring($Request.IndexOf("{ "), $Request.LastIndexOf("}") - $Request.IndexOf("{ ") + 1) -replace " ", "_" | ConvertFrom-Json

                    $HashRate_Value = If ($Data.SUMMARY.HS_5s -ne $null) { [Double]$Data.SUMMARY.HS_5s * [math]::Pow(1000, 0) }
                    ElseIf ($Data.SUMMARY.KHS_5s) { [Double]$Data.SUMMARY.KHS_5s * [Math]::Pow(1000, 1) }
                    ElseIf ($Data.SUMMARY.MHS_5s) { [Double]$Data.SUMMARY.MHS_5s * [Math]::Pow(1000, 2) }
                    ElseIf ($Data.SUMMARY.GHS_5s) { [Double]$Data.SUMMARY.GHS_5s * [Math]::Pow(1000, 3) }
                    ElseIf ($Data.SUMMARY.THS_5s) { [Double]$Data.SUMMARY.THS_5s * [Math]::Pow(1000, 4) }
                    ElseIf ($Data.SUMMARY.PHS_5s) { [Double]$Data.SUMMARY.PHS_5s * [Math]::Pow(1000, 5) }
                    ElseIf ($Data.SUMMARY.HS_30s) { [Double]$Data.SUMMARY.HS_30s * [Math]::Pow(1000, 0) }
                    ElseIf ($Data.SUMMARY.KHS_30s) { [Double]$Data.SUMMARY.KHS_30s * [Math]::Pow(1000, 1) }
                    ElseIf ($Data.SUMMARY.MHS_30s) { [Double]$Data.SUMMARY.MHS_30s * [Math]::Pow(1000, 2) }
                    ElseIf ($Data.SUMMARY.GHS_30s) { [Double]$Data.SUMMARY.GHS_30s * [Math]::Pow(1000, 3) }
                    ElseIf ($Data.SUMMARY.THS_30s) { [Double]$Data.SUMMARY.THS_30s * [Math]::Pow(1000, 4) }
                    ElseIf ($Data.SUMMARY.PHS_30s) { [Double]$Data.SUMMARY.PHS_30s * [Math]::Pow(1000, 5) }
                    ElseIf ($Data.SUMMARY.HS_av) { [Double]$Data.SUMMARY.HS_av * [Math]::Pow(1000, 0) }
                    ElseIf ($Data.SUMMARY.KHS_av) { [Double]$Data.SUMMARY.KHS_av * [Math]::Pow(1000, 1) }
                    ElseIf ($Data.SUMMARY.MHS_av) { [Double]$Data.SUMMARY.MHS_av * [Math]::Pow(1000, 2) }
                    ElseIf ($Data.SUMMARY.GHS_av) { [Double]$Data.SUMMARY.GHS_av * [Math]::Pow(1000, 3) }
                    ElseIf ($Data.SUMMARY.THS_av) { [Double]$Data.SUMMARY.THS_av * [Math]::Pow(1000, 4) }
                    ElseIf ($Data.SUMMARY.PHS_av) { [Double]$Data.SUMMARY.PHS_av * [Math]::Pow(1000, 5) }
                }
            }

            "xmrig" { 
                $Request = Invoke-HTTPRequest $Server $Port "/api.json" $Timeout
                If ($Request) { 
                    $Data = $Request | ConvertFrom-Json 
                    $HashRate_Value = [Double]$Data.hashrate.total[0]
                }
            }

            "wrapper" { 
                $HashRate_Value = ""
                $wrpath = ".\Logs\energi.txt"
                $HashRate_Value = If (Test-Path -Path $wrpath -PathType Leaf ) { 
                    Get-Content $wrpath
                    $HashRate_Value = ($HashRate_Value-split ',')[0]
                    If (-not $HashRate_Value) { $HashRate_Value = ($HashRate_Value-split '.')[0] }

                }
                Else { $HashRate_Value = 0 }
            }

            "zjazz" { 
                $Request = Invoke-TcpRequest $Server $Port  "summary" $Timeout
                If ($Request) { 
                    $Data = $Request -split ";" | ConvertFrom-StringData -ErrorAction Stop
                    $HashRate_Value = [Double]$Data.KHS * 2000000 #Temp fix for nlpool wrong hashrate
                }
            }
        } #end Switch

        If ($Miner.ReadPowerUsage) {
            #read power usage
            If ((Test-Path $RegistryHive) -and $DeviceName) { 
                $RegistryData = Get-ItemProperty $RegistryHive
                $RegistryData.PSObject.Properties | Where-Object { $_.Name -match "^Label[0-9]+$" -and (Compare-Object @($_.Value -split ' ' | Select-Object) @($DeviceName | Select-Object) -IncludeEqual -ExcludeDifferent) } | ForEach-Object { 
                    $PowerUsage_Value = [Double]($RegistryData.($_.Name -replace "Label", "Value") -split ' ' | Select-Object -Index 0)
                    If ($PowerUsage_Value -gt 0) { $PowerUsage += $PowerUsage_Value }
                }
            }
        }

        $HashRate = [PSCustomObject]@{}
        $HashRate | Add-Member @{ $Algorithms[0] = $HashRate_Value }
        If ($Algorithms.Count -eq 2) { 
            $HashRate | Add-Member @{ $Algorithms[1] = $HashRateDual_Value }
        }

        If (($HashRate.PSObject.Properties.Value | Measure-Object -Sum).Sum -gt 0) { 
            [PSCustomObject]@{
                Date       = (Get-Date).ToUniversalTime()
                HashRate   = $HashRate
                #Shares     = $Shares
                PowerUsage = ($PowerUsage | Measure-Object -Average).Average
            }
        }
    }
}
Catch { 
    $Error
    Exit
}
