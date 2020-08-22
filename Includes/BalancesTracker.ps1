using module .\Include.psm1

<#
Copyright (c) 2018 MrPlus
BalancesTrackerJob.ps1 Written by MrPlusGH https://github.com/MrPlusGH

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
File:           BalancesTrackerJob.ps1
version:        3.9.9.0
version date:   20 August 2020
#>

#Start the log
If ($Config.Transcript) { Start-Transcript -Path ".\Logs\BalancesTracker-$(Get-Date -Format "yyyy-MM-dd").log" -Append -Force | Out-Null }

(Get-Process -Id $PID).PriorityClass = "BelowNormal"

$TrustLevel = 0
$Variables.Earnings = [Ordered]@{ }
$LastAPIUpdateTime = (Get-Date).ToUniversalTime()

While ($true) { 
    If ($Config.BalancesTrackerPollInterval -gt 0) { 

        #Only on first run
        If (-not $Now) { 
            Write-Message "Balances Tracker started."
            # Read existing earning data
            If (Test-Path -Path ".\Logs\BalancesTrackerData.json" -PathType Leaf) { $AllBalanceObjects = @(Get-Content ".\logs\BalancesTrackerData.json" | ConvertFrom-Json) } Else { $AllBalanceObjects = @() }
            If (Test-Path -Path ".\Logs\DailyEarnings.csv" -PathType Leaf) { $DailyEarnings = @(Import-Csv ".\Logs\DailyEarnings.csv" -ErrorAction SilentlyContinue) } Else { $DailyEarnings = @() }
        }

        $Now = Get-Date
        $Date = $Now.ToString("yyyy-MM-dd")
        $CurDateUxFormat = ([DateTimeOffset]$Now.Date).ToUnixTimeMilliseconds()

        # Get pools api ref
        If (-not $PoolAPI -or ($LastAPIUpdateTime -le (Get-Date).ToUniversalTime().AddDays(-1))) { 
            Try { 
                $PoolAPI = Invoke-WebRequest "https://raw.githubusercontent.com/Minerx117/UpDateData/master/poolapidata.json" -TimeoutSec 15 -UseBasicParsing -Headers @{ "Cache-Control" = "no-cache" } | ConvertFrom-Json
                $LastAPIUpdateTime = $Now
                $PoolAPI | ConvertTo-Json | Out-File ".\Config\PoolApiData.json" -Force
            }
            Catch { 
                If (-not $PoolAPI) { $PoolAPI = Get-Content ".\Config\PoolApiData.json" | ConvertFrom-Json }
            }
        }

        #Filter pools variants
        $Pools = @(($Config.PoolName) -replace "24hr" -replace "coins") | Sort-Object -Unique

        #For each pool in config
        $PoolNamesToTrack = @((Compare-Object @($Pools) @(($PoolAPI | Where-Object EarnTrackSupport -EQ "yes").Name | Sort-Object -Unique) -IncludeEqual -ExcludeDifferent).InputObject)

        Write-Message "Requesting balances data ($(($PoolAPI.Name | Where-Object { $_ -in $PoolNamesToTrack }) -join ', '))."
        If ($PoolNamesToTrack) { 
        }

        $PoolAPI | Where-Object Name -in $PoolNamesToTrack | ForEach-Object {
            $Pool = $_.Name
            $APIUri = $_.WalletUri
            $PaymentThreshold = $_.PaymentThreshold
            $BalanceData = [PSCustomObject]@{ }
            $BalanceJson = $_.Balance
            $TotalJson = $_.Total
            $PoolAccountUri = $_.AccountUri

            Switch ($Pool) { 
                "MPH" { 
                    Try { 
                        $Wallet = $Config.MPHAPIKey
                        $BalanceData = (((Invoke-RestMethod -Uri "$APIUri$Wallet" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }).getuserallbalances).data | Where-Object { $_.coin -eq "bitcoin" })
                        $BalanceData | Add-Member Currency "BTC" -ErrorAction Ignore
                    }
                    Catch { }
                }
                "Nicehash2" { 
                #     $Request_Balance = [PSCustomObject]@{}

                #     If ($PoolConfig.NicehashAPIKey -and $PoolConfig.NicehashAPISecret -and $PoolConfig.NicehashOrganizationID) { 
                #         Try { 
                #             $Request_Balance = Invoke-NHRequest "/main/api/v2/accounting/account2/BTC/" $PoolConfig.NicehashAPIKey $PoolConfig.NicehashAPISecret $PoolConfig.NicehashOrganizationID
                #         }
                #         Catch { 
                #             If ($Error.Count) { $Error.RemoveAt(0) }
                #             Write-Message -Level Warn "Pool Accounts API ($Name) has failed."
                #         }
                #     }

                #     Function Get-MD5Hash { 
                #         [CmdletBinding()]
                #         Param(
                #             [Parameter(
                #                 Mandatory = $true,
                #                 Position = 0, 
                #                 ParameterSetName = '',
                #                 ValueFromPipeline = $true)]
                #                 [String]$Value
                #         )

                #         $MD5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
                #         $UTF8 = New-Object -TypeName System.Text.UTF8Encoding
                #         [System.BitConverter]::ToString($MD5.ComputeHash($UTF8.GetBytes($Value))).ToUpper() -replace '-'
                #     }

                #     Function Get-ReadableHex32 { 
                #         [CmdletBinding()]
                #         Param (
                #             [Parameter(Mandatory = $true)]
                #             [String]$Key
                #         )

                #         If ($Key.Length % 32) {
                #             $Key
                #         }
                #         Else {
                #             $s = ""
                #             For ($i=0; $i -lt $Key.Length; $i+=32) { 
                #                 $s = "$s$($Key.Substring($i, 8))-$($Key.Substring($i + 4, 4))-$($Key.Substring($i + 8, 4))-$($Key.Substring($i + 12, 4))-$($Key.Substring($i + 16, 12))"
                #             }
                #             $s
                #          }
                #      }

                #     Function Invoke-NHRequest {
                #         [CmdletBinding()]
                #         Param(
                #             [Parameter(Mandatory = $true)]
                #             [String]$Endpoint,
                #             [Parameter(Mandatory = $false)]
                #             [String]$Key,
                #             [Parameter(Mandatory = $false)]
                #             [String]$Secret,
                #             [Parameter(Mandatory = $false)]
                #             [String]$OrganizationId,
                #             [Parameter(Mandatory = $false)]
                #             [Hashtable]$Params = @{ },
                #             [Parameter(Mandatory = $false)]
                #             [String]$Method = "GET",
                #             [Parameter(Mandatory = $false)]
                #             [String]$Base = "https://api2.nicehash.com",
                #             [Parameter(Mandatory = $false)]
                #             [Int]$Timeout = 15,
                #             [Parameter(Mandatory = $false)]
                #             [Int]$Cache = 0,
                #             [Parameter(Mandatory = $false)]
                #             [Sitch]$ForceLocal
                #         )

                #         #autofix key/secret/organizationid
                #         If ($Key) {$Key = Get-ReadableHex32 $Key }
                #         If ($Secret) { $Secret = Get-ReadableHex32 $Secret }
                #         If ($OrganizationId) { $OrganizationId = Get-ReadableHex32 $OrganizationId }

                #         $KeyStr = Get-MD5Hash "$($Endpoint)$(Get-HashtableAsJson $Params)"
                #         If (-not (Test-Path Variable:Global:NHCache)) { $Global:NHCache = [Hashtable]@{} }
                #         If (-not $Cache -or -not $Global:NHCache[$KeyStr] -or -not $Global:NHCache[$KeyStr].request -or $Global:NHCache[$KeyStr].last -lt (Get-Date).ToUniversalTime().AddSeconds(-$Cache)) { 
                    
                #         $Remote = $false

                #         If (-not $ForceLocal -and $Session.Config.RunMode -eq "Client" -and $Session.Config.ServerName -and $Session.Config.ServerPort -and (Test-TcpServer $Session.Config.ServerName -Port $Session.Config.ServerPort -Timeout 1)) { 
                #                 $ServerBody = @{
                #                     Endpoint    = $Endpoint
                #                     Key         = $Key
                #                     Secret      = $Secret
                #                     Ogid        = $OrganizationId
                #                     Params      = $Params | ConvertTo-Json -Depth 10 -Compress
                #                     Method      = $Method
                #                     Base        = $Base
                #                     Timeout     = $Timeout
                #                     Machinename = $Session.MachineName
                #                     Workername  = $PoolConfig.Workername
                #                     MyIP        = $Session.MyIP
                #                 }
                #                 Try { 
                #                     $Result = Invoke-GetUrl "http://$($Session.Config.ServerName):$($Session.Config.ServerPort)/getnh" -Body $ServerBody -User $Session.Config.ServerUser -Password $Session.Config.ServerPassword -ForceLocal
                #                     If ($Result.Status) { 
                #                         $Request = $Result.Content
                #                         $Remote = $true
                #                     }
                #                 }
                #                 Catch { 
                #                     If ($Error.Count) { $Error.RemoveAt(0) }
                #                     Write-Message -Level Info "Nicehash server call: $($_.Exception.Message)"
                #                 }
                #             }
                #             If (-not $Remote -and $Key -and $Secret -and $OrganizationId) {
                #                 $Uuid = [string]([guid]::NewGuid())
                #                 $Timestamp = ([DateTimeOffset](Get-Date)).ToUnixTimeSeconds()
                #                 #$timestamp_nh = Invoke-GetUrl "$($base)/main/api/v2/time" -timeout $Timeout | Select-Object -ExpandProperty serverTime
                #                 #if ([Math]::Abs($timestamp_nh - $timestamp) -gt 3000) {$timestamp = $timestamp_nh}
                #                 $ParamStr = "$(($Params.Keys | ForEach-Object { "$($_) = $([System.Web.HttpUtility]::UrlEncode($params.$_))" }) -join '&')"
                #                 $Str = "$Key`0$Timestamp`0$Uuid`0`0$Organizationid`0`0$($Method.ToUpper())`0$Endpoint`0$(If ($Method -eq "GET") { $ParamStr } Else { "`0$($Params | ConvertTo-Json -Depth 10 -Compress)" })"
                #                 $Sha = [System.Security.Cryptography.KeyedHashAlgorithm]::Create("HMACSHA256")
                #                 $Sha.Key = [System.Text.Encoding]::UTF8.Getbytes($Secret)
                #                 $Sign = [System.BitConverter]::ToString($Sha.ComputeHash([System.Text.Encoding]::UTF8.Getbytes(${str})))
                #                 $Headers = [Hashtable]@{
                #                     'X-Time'            = $Timestamp
                #                     'X-Nonce'           = $Uuid
                #                     'X-Organization-Id' = $OrganizationId
                #                     'X-Auth'            = "$($Key):$(($Sign -replace '\-').ToLower())"
                #                     'Cache-Control'     = 'no-cache'
                #                 }
                #                 Try { 
                #                     $Body = Switch ($Method) {
                #                         "GET" {
                #                             If ($params.Count) { $Params } Else { $null }
                #                             Break
                #                         }
                #                         Default { $Params | ConvertTo-Json -Depth 10 }
                #                     }
                #                     $Request = Invoke-GetUrl "$Base$Endpoint" -Timeout $Timeout -Headers $Headers -Requestmethod $Method -Body $Body
                #                 }
                #                 Catch { 
                #                     If ($Error.Count) { $Error.RemoveAt(0) }
                #                     Write-Message -Level Info "Nicehash API call: $($_.Exception.Message)"
                #                 }
                #             }

                #             If (-not $Global:NHCache[$keystr] -or $Request) { 
                #                 $Global:NHCache[$keystr] = [PSCustomObject]@{ 
                #                     Last = (Get-Date).ToUniversalTime()
                #                     Request = $Request
                #                 }
                #             }
                #         }
                #         $Global:NHCache[$KeyStr].request
                #     }
                }
                "NiceHash" { 
                    # Try { 
                    #     $TempBalance = 0
                    #     $Wallet = If ($Config.PoolsConfig.$Pool.Wallet) { $Config.PoolsConfig.$Pool.Wallet } Else { $Config.Wallet }
                    #     $NicehashData = ((Invoke-RestMethod -Uri "$APIUri$Wallet/rigs/stats/unpaid/" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }).Data | Where-Object { $_[0] -gt $CurDateUxFormat } | Sort-Object { $_[0] } | Group-Object { $_[2] }).group
                    #     $NHTotalBalance = -$NicehashData[0][2]
                    #     $NicehashData | ForEach-Object {
                    #         #Nicehash continously transfers balances to wallet
                    #         If ($_[2] -gt $TempBalance) {
                    #             $TempBalance = $_[2]
                    #         }
                    #         Else { 
                    #             $NHTotalBalance += $TempBalance
                    #             $TempBalance = $_[2]
                    #         }
                    #     }
                    #     $NHTotalBalance += $TempBalance
                    #     $BalanceData | Add-Member -NotePropertyName $BalanceJson -NotePropertyValue $NHTotalBalance -Force
                    #     $BalanceData | Add-Member -NotePropertyName $TotalJson -NotePropertyValue $NHTotalBalance -Force
                    #     $BalanceData | Add-Member Currency "BTC" -ErrorAction Ignore
                    # }
                    # Catch { }
                }
                "ProHashing" { 
                    Try { 
                        $Wallet = $Config.ProHashingAPIKey
                        $BalanceData = ((Invoke-RestMethod -Uri "$APIUri$Wallet" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }).data.balances.BTC)
                        $BalanceData | Add-Member "total_unpaid" $BalanceData.Unpaid -Force
                        $BalanceData | Add-Member Currency "BTC" -ErrorAction Ignore
                    }
                    Catch { }
                }
                Default { 
                    Try { 
                        $Wallet = If ($Config.PoolsConfig.$Pool.Wallet) { $Config.PoolsConfig.$Pool.Wallet } Else { $Config.Wallet }
                        $PasswordCurrency = If ($Config.PoolsConfig.$Pool.PasswordCurrency) { $Config.PoolsConfig.$Pool.PasswordCurrency } Else { $Config.PasswordCurrency }
                        $BalanceData = Invoke-RestMethod -Uri "$APIUri$Wallet" -TimeoutSec 15 -Headers @{ "Cache-Control" = "no-cache" }
                        $PoolAccountUri = "$($PoolAccountUri -replace '\[currency\]', $PasswordCurrency)$Wallet"
                    }
                    Catch { }
                }
            }
            If ($BalanceData.$TotalJson -gt 0) { 
                $AllBalanceObjects += $BalanceObject = [PSCustomObject]@{ 
                    Pool         = $Pool
                    DateTime     = $Now
                    Balance      = $BalanceData.$BalanceJson
                    Unsold       = $BalanceData.unsold
                    Total_unpaid = $BalanceData.total_unpaid
                    Total_paid   = $BalanceData.total_paid
                    Total_earned = ($BalanceData.$BalanceJson, $BalanceData.$TotalJson | Measure-Object -Minimum).Minimum # Pool reduced balance!
                    Currency     = $BalanceData.Currency
                }

                $PoolBalanceObjects = @($AllBalanceObjects | Where-Object Pool -EQ $Pool | Sort-Object Date)

                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalMinutes) -eq 0) { $Now = $Now.AddMinutes(1) }

                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalDays) -ge 1) { 
                    $Growth1 = $BalanceObject.total_earned - (($PoolBalanceObjects | Where-Object { $_.Date -ge $Now.AddHours(-1) }).total_earned | Measure-Object -Minimum).Minimum
                    $Growth6 = $BalanceObject.total_earned - (($PoolBalanceObjects | Where-Object { $_.Date -ge $Now.AddHours(-6) }).total_earned | Measure-Object -Minimum).Minimum
                    $Growth24 = $BalanceObject.total_earned - (($PoolBalanceObjects | Where-Object { $_.Date -ge $Now.AddDays(-1) }).total_earned | Measure-Object -Minimum).Minimum
                }
                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalDays) -lt 1) { 
                    $Growth1 = $BalanceObject.total_earned - (($PoolBalanceObjects | Where-Object { $_.Date -ge $Now.AddHours(-1) }).total_earned | Measure-Object -Minimum).Minimum
                    $Growth6 = $BalanceObject.total_earned - (($PoolBalanceObjects | Where-Object { $_.Date -ge $Now.AddHours(-6) }).total_earned | Measure-Object -Minimum).Minimum
                    $Growth24 = (($BalanceObject.total_earned - $PoolBalanceObjects[0].total_earned) / ($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) * 24
                }
                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) -lt 6) { 
                    $Growth1 = $BalanceObject.total_earned - (($PoolBalanceObjects | Where-Object { $_.Date -ge $Now.AddHours(-1) }).total_earned | Measure-Object -Minimum).Minimum
                    $Growth6 = (($BalanceObject.total_earned - $PoolBalanceObjects[0].total_earned) / ($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) * 6
                }
                If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) -lt 1) { 
                    $Growth1 = (($BalanceObject.total_earned - $PoolBalanceObjects[0].total_earned) / ($Now - ($PoolBalanceObjects[0].DateTime)).TotalMinutes) * 60
                }

                $AvgBTCHour = If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) -ge 1) { (($BalanceObject.total_earned - $PoolBalanceObjects[0].total_earned) / ($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) } Else { $Growth1 }

                $Variables.Earnings.$Pool = [PSCustomObject]@{ 
                    Pool                  = $Pool
                    Wallet                = $Wallet
                    Uri                   = $PoolAccountUri
                    Date                  = $Date
                    StartTime             = $PoolBalanceObjects[0].DateTime.ToString("T")
                    Balance               = [Double]$BalanceObject.balance
                    Unsold                = [Double]$BalanceObject.unsold
                    Total_unpaid          = [Double]$BalanceObject.total_unpaid
                    Total_paid            = [Double]$BalanceObject.total_paid
                    Total_earned          = [Double]$BalanceObject.total_earned
                    Currency              = $BalanceObject.currency
                    GrowthSinceStart      = $BalanceObject.total_earned - $PoolBalanceObjects[0].total_earned
                    Growth1               = [Double]$Growth1
                    Growth6               = [Double]$Growth6
                    Growth24              = [Double]$Growth24
                    AvgHourlyGrowth       = [Double]$AvgBTCHour
                    BTCD                  = [Double]$AvgBTCHour * 24
                    EstimatedEndDayGrowth = If ((($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours) -ge 1) { [Double]($AvgBTCHour * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) } Else { [Double]($Growth1 * ((Get-Date -Hour 0 -Minute 00 -Second 00).AddDays(1).AddSeconds(-1) - $Now).Hours) }
                    EstimatedPayDate      = If ($PaymentThreshold) { If ($BalanceObject.balance -lt $PaymentThreshold) { If ($AvgBTCHour -gt 0) { $Now.AddHours(($PaymentThreshold - $BalanceObject.balance) / $AvgBTCHour) } Else { "Unknown" } } Else { "Next Payout !" } } Else { "Unknown" }
                    TrustLevel            = $((($Now - ($PoolBalanceObjects[0].DateTime)).TotalMinutes / 360), 1 | Measure-Object -Minimum).Minimum
                    PaymentThreshold      = [Double]$PaymentThreshold
                    TotalHours            = ($Now - ($PoolBalanceObjects[0].DateTime)).TotalHours
                    LastUpdated           = $Now
                }

                If ($BalancesTrackerConfig.EnableLog) { $Variables.Earnings.$Pool | Export-Csv -NoTypeInformation -Append ".\Logs\BalancesTrackerLog.csv" }

                If ($PoolDailyEarning = $DailyEarnings | Where-Object Pool -EQ $Pool | Where-Object Date -EQ $Date ) {
                    # pool may have reduced estimated balance, use new balance as start value to avoid negative values
                    $PoolDailyEarning.StartValue = ($PoolDailyEarning.StartValue, $BalanceObject.total_earned | Measure-Object -Minimum).Minimum
                    $PoolDailyEarning.DailyEarnings = $BalanceObject.total_earned - $PoolDailyEarning.StartValue
                    $PoolDailyEarning.EndTime = $Now.ToString("T")
                    $PoolDailyEarning.EndValue = $BalanceObject.total_earned
                    If ($BalanceObject.total_earned -lt ($PoolBalanceObjects[$PoolBalanceObjects.Count - 2].total_earned / 2)) { 
                        $PoolDailyEarning.PrePaymentDayValue = $PoolBalanceObjects[$PoolBalanceObjects.Count - 2].total_earned
                        If ($PoolDailyEarning.PrePaymentDayValue -gt 0) { 
                            #Payment occured
                            $PoolDailyEarning.DailyEarnings += $PoolDailyEarning.PrePaymentDayValue
                        }
                    }
                    $PoolDailyEarning.Balance = $BalanceObject.balance
                    $PoolDailyEarning.BTCD = $BalanceObject.Growth24

                    Remove-Variable PoolDailyEarning
                }
                Else { 
                    $DailyEarnings += [PSCustomObject]@{ 
                        Date               = $Date
                        Pool               = $Pool
                        DailyEarnings      = [Double]0
                        StartTime          = $Now.ToString("T")
                        StartValue         = [Double]$BalanceObject.total_earned
                        EndTime            = $Now.ToString("T")
                        EndValue           = [Double]$BalanceObject.total_earned
                        PrePaymentDayValue = [Double]0
                        Balance            = [Double]$BalanceObject.Balance
                        BTCD               = [Double]$BalanceObject.Growth24
                    }
                }
                Remove-Variable BalanceData
                Remove-Variable BalanceObject
            }
        }

        $DailyEarnings | Export-Csv ".\Logs\DailyEarnings.csv" -NoTypeInformation -Force

        #Write chart data file (used in Web GUI)
        $ChartData = $DailyEarnings | Sort-Object StartTime | Group-Object -Property Date | Select-Object -Last 30 # days

        #One dataset per pool
        $PoolData = [PSCustomObject]@{}
        $ChartData.Group.Pool | Sort-Object -Unique | ForEach-Object { 
            $PoolData | Add-Member @{ $_ = [Double[]]@() }
        }

        $CumulatedEarnings = [Double[]]@()
        #Fill dataset
        ForEach ($PoolDailyEarning in $ChartData) { 
            $CumulatedEarnings += ([Double]($PoolDailyEarning.Group | Measure-Object DailyEarnings -Sum).Sum)
            $PoolData | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Select-Object -ExpandProperty Name | ForEach-Object { 
                $PoolData.$_ += [Double]($PoolDailyEarning.Group | Where-Object Pool -EQ $_).DailyEarnings
            }
        }
        
        [PSCustomObject]@{
            CumulatedEarnings = $CumulatedEarnings #Dataset for cumulated earnings
            Currency = ($Config.Currency | Select-Object -Index 0)
            Labels = @(
                $ChartData.Group.Date | Sort-Object -Unique | ForEach-Object { 
                    [DateTime]::parseexact($_, "yyyy-MM-dd", $null).ToShortDateString()
                }
            )
            #Use dates for x-axis label
            Pools = $PoolData
        } | ConvertTo-Json | Out-File ".\Logs\EarningsChartData.json" -Encoding UTF8

        # Some pools do reset "Total" after payment (zpool)
        # Results in showing bad negative earnings
        # Detecting if current is more than 50% less than previous and reset history if so
        If ($BalanceObject -and $BalanceObject.total_earned -lt ($PoolBalanceObjects[$PoolBalanceObjects.Count - 2].total_earned / 2)) { 
            $AllBalanceObjects = $AllBalanceObjects | Where-Object { $_.Pool -ne $Pool }
            $AllBalanceObjects += $BalanceObject
        }

        #Keep only last 7 days
        If ($AllBalanceObjects.Count -gt 1) { $AllBalanceObjects = $AllBalanceObjects | Where-Object { $_.Date -ge $Now.AddDays(-7) } }
        If ($AllBalanceObjects.Count -ge 1) { $AllBalanceObjects | ConvertTo-Json | Out-File ".\Logs\BalancesTrackerData.json" }

    }

    # Sleep until next update (at least 3 minutes)
    Start-Sleep -Seconds (60 * (1, $Config.BalancesTrackerPollInterval | Measure-Object -Maximum).Maximum)
}

Write-Message "Balances Tracker stopped."
