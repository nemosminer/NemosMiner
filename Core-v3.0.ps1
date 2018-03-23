<#
This file is part of NemosMiner
Copyright (c) 2018 Nemo
Copyright (c) 2018 MrPlus

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

Function InitApplication {
    . .\include.ps1
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)

    $Variables | Add-Member -Force @{ScriptStartDate = (Get-Date)}
    # GitHub Supporting only TLSv1.2 on feb 22 2018
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    Get-ChildItem . -Recurse | Unblock-File
    Update-Status("INFO: Adding NemosMiner path to Windows Defender's exclusions.. (may show an error if Windows Defender is disabled)")
    try {if ((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)) {Start-Process powershell -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath '$(Convert-Path .)'"}}catch {}
    if ($Proxy -eq "") {$PSDefaultParameterValues.Remove("*:Proxy")}
    else {$PSDefaultParameterValues["*:Proxy"] = $Proxy}
    Update-Status("Initializing Variables...")
    $Variables | Add-Member -Force @{DecayStart = Get-Date}
    $Variables | Add-Member -Force @{DecayPeriod = 120} #seconds
    $Variables | Add-Member -Force @{DecayBase = 1 - 0.1} #decimal percentage
    $Variables | Add-Member -Force @{ActiveMinerPrograms = @()}
    $Variables | Add-Member -Force @{Miners = @()}
    #Start the log
    Start-Transcript -Path ".\Logs\miner.log" -Append -Force
    #Update stats with missing data and set to today's date/time
    if (Test-Path "Stats") {Get-ChildItemContent "Stats" | ForEach {$Stat = Set-Stat $_.Name $_.Content.Week}}
    #Set donation parameters
    #Randomly sets donation minutes per day between (0,(3..8)) minutes if set to less than 3
    $Variables | Add-Member -Force @{DonateRandom = [PSCustomObject]@{}}
    $Variables | Add-Member -Force @{LastDonated = (Get-Date).AddDays(-1).AddHours(1)}
    If ($Config.Donate -lt 3) {$Config.Donate = (0, (3..8)) | Get-Random}
    $Variables | Add-Member -Force @{WalletBackup = $Config.Wallet}
    $Variables | Add-Member -Force @{UserNameBackup = $Config.UserName}
    $Variables | Add-Member -Force @{WorkerNameBackup = $Config.WorkerName}
    $Variables | Add-Member -Force @{EarningsPool = ""}
    # Will need rework
    Update-Status("Finding available TCP Port")
    $Variables | Add-Member -Force @{MinerAPITCPPort = Get-FreeTcpPort}
    Update-Status("Miners API Port: $($Variables.MinerAPITCPPort)")
    # Starts Brains if necessary
    Update-Status("Starting Brains for Plus...")
    $Variables | Add-Member -Force @{BrainJobs = @()}
    $Config.PoolName | foreach {
        $BrainPath = (Split-Path $script:MyInvocation.MyCommand.Path) + "\BrainPlus\" + $_
        # $BrainPath = ".\BrainPlus\"+$_
        $BrainName = (".\BrainPlus\" + $_ + "\BrainPlus-2.2.ps1")
        if (Test-Path $BrainName) {
            $Variables.BrainJobs += Start-Job -FilePath $BrainName -ArgumentList @($BrainPath)
        }
    }
    # Starts Earnings Tracker Job
    Update-Status("Starting Earnings Tracker...")
    $Variables | Add-Member -Force @{EarningsTrackerJobs = @()}
    $Variables | Add-Member -Force @{Earnings = @{}}
    $StartDelay = 0
    if ($Config.TrackEarnings) {
        $Config.PoolName | sort | foreach {
            $Params = @{
                pool             = $_
                Wallet           =
                if ($_ -eq "miningpoolhub") {
                    if ($Config.PoolsConfig.$_) {$Config.PoolsConfig.$_.APIKey}else {$Config.PoolsConfig.default.APIKey}
                }
                else {
                    if ($Config.PoolsConfig.$_) {$Config.PoolsConfig.$_.Wallet}else {$Config.PoolsConfig.default.Wallet}
                }
                Interval         = 10
                WorkingDirectory = (Split-Path $script:MyInvocation.MyCommand.Path)
                StartDelay       = $StartDelay
            }
            $Variables.EarningsTrackerJobs += Start-Job -FilePath .\EarningsTrackerJob.ps1 -ArgumentList $Params
            # Delay Start when several instances to avoid conflicts.
            $StartDelay = $StartDelay + 10
        }
    }
    $Location = $Config.Location
}

Function NPMCycle {
    . .\include.ps1
    $timerCycle.Enabled = $False

    Update-Status("Starting Cycle")
    Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
    $host.UI.RawUI.WindowTitle = $Variables.CurrentProduct + " " + $Variables.CurrentVersion + " Runtime " + ("{0:dd\ \d\a\y\s\ hh\:mm}" -f ((get-date) - $Variables.ScriptStartDate)) + " Path: " + (Split-Path $script:MyInvocation.MyCommand.Path)
    $DecayExponent = [int](((Get-Date) - $Variables.DecayStart).TotalSeconds / $Variables.DecayPeriod)

    # Ensure we get the hashrate for running miners prior looking for best miner
    $Variables.ActiveMinerPrograms | ForEach {
        if ($_.Process -eq $null -or $_.Process.HasExited) {
            if ($_.Status -eq "Running") {$_.Status = "Failed"}
        }
        else {
            # we don't want to store hashrates if we run less than $Config.StatsInterval sec
            $WasActive = [math]::Round(((Get-Date) - $_.Process.StartTime).TotalSeconds)
            if ($WasActive -ge $Config.StatsInterval) {
                $_.HashRate = 0
                $Miner_HashRates = $null
                if ($_.New) {$_.Benchmarked++}         
                $Miner_HashRates = Get-HashRate $_.API $_.Port ($_.New -and $_.Benchmarked -lt 3)
                $_.HashRate = $Miner_HashRates | Select -First $_.Algorithms.Count           
                if ($Miner_HashRates.Count -ge $_.Algorithms.Count) {
                    for ($i = 0; $i -lt $_.Algorithms.Count; $i++) {
                        $Stat = Set-Stat -Name "$($_.Name)_$($_.Algorithms | Select -Index $i)_HashRate" -Value ($Miner_HashRates | Select -Index $i)
                    }
                    $_.New = $false
                    $_.Hashrate_Gathered = $true
                    Write-Host "Stats '"$_.Algorithms"' -> "($Miner_HashRates | ConvertTo-Hash)"after"$WasActive" sec"
                }
            }
        }
    }

    #Activate or deactivate donation
    if ((Get-Date).AddDays(-1).AddMinutes($Config.Donate) -ge $Variables.LastDonated -and $Variables.DonateRandom.wallet -eq $Null) {
        # Get donation addresses randomly from agreed devs list
        # This will fairly distribute donations to Devs
        # Devs list and wallets is publicly available at: http://nemosminer.x10host.com/devlist.json 
        try {$Donation = Invoke-WebRequest "http://nemosminer.x10host.com/devlist.json" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json
        }
        catch {$Donation = @([PSCustomObject]@{Name = "mrplus"; Wallet = "134bw4oTorEJUUVFhokDQDfNqTs7rBMNYy"; UserName = "mrplus"}, [PSCustomObject]@{Name = "nemo"; Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"; UserName = "nemo"})
        }
        if ($Donation -ne $null) {
            $Variables.DonateRandom = $Donation | Get-Random
            $Config | Add-Member -Force @{PoolsConfig = [PSCustomObject]@{default = [PSCustomObject]@{Wallet = $Variables.DonateRandom.Wallet; UserName = $Variables.DonateRandom.UserName; WorkerName = "NPlusMiner"; PricePenaltyFactor = 1}}}
        }
    }
    if ((Get-Date).AddDays(-1) -ge $Variables.LastDonated -and $Variables.DonateRandom.Wallet -ne $Null) {
        $Config | Add-Member -Force -MemberType ScriptProperty -Name "PoolsConfig" -Value {
            If (Test-Path ".\Config\PoolsConfig.json") {
                get-content ".\Config\PoolsConfig.json" | ConvertFrom-json
            }
            else {
                [PSCustomObject]@{default = [PSCustomObject]@{
                        Wallet      = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"
                        UserName    = "nemo"
                        WorkerName  = "NemosMinerNoCfg"
                        PoolPenalty = 1
                    }
                }
            }
        }
        $Variables.LastDonated = Get-Date
        $Variables.DonateRandom = [PSCustomObject]@{}
    }
    Update-Status("Loading $($Config.Passwordcurrency) rate from 'api.coinbase.com'..")
    $Rates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=$($Config.Passwordcurrency)" -UseBasicParsing | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates
    $Config.Currency | Where-Object {$Rates.$_} | ForEach-Object {$Rates | Add-Member $_ ([Double]$Rates.$_) -Force}
    $Variables | Add-Member -Force @{Rates = $Rates}
    #Load the Stats
    $Stats = [PSCustomObject]@{}
    if (Test-Path "Stats") {Get-ChildItemContent "Stats" | ForEach {$Stats | Add-Member $_.Name $_.Content}}
    #Load information about the Pools
    Update-Status("Loading pool stats..")
    $PoolFilter = @()
    $Config.PoolName | foreach {$PoolFilter += ($_ += ".*")}
    $AllPools = if (Test-Path "Pools") {Get-ChildItemContent "Pools" -Include $PoolFilter | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} | 
            # Use location as preference and not the only one
        # Where Location -EQ $Config.Location | 
        Where SSL -EQ $Config.SSL | 
            Where {$Config.PoolName.Count -eq 0 -or (Compare $Config.PoolName $_.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}
    }
    # Use location as preference and not the only one
    Update-Status("Computing pool stats..")
    $AllPools = ($AllPools | ? {$_.location -eq $Config.Location}) + ($AllPools | ? {$_.name -notin ($AllPools | ? {$_.location -eq $Config.Location}).Name})
    if ($AllPools.Count -eq 0) {Update-Status("Error contacting pool, retrying.."); $timerCycle.Interval = 15000 ; $timerCycle.Start() ; return}
    $Pools = [PSCustomObject]@{}
    $Pools_Comparison = [PSCustomObject]@{}
    $AllPools.Algorithm | Sort -Unique | ForEach {
        $Pools | Add-Member $_ ($AllPools | Where Algorithm -EQ $_ | Sort Price -Descending | Select -First 1)
        $Pools_Comparison | Add-Member $_ ($AllPools | Where Algorithm -EQ $_ | Sort StablePrice -Descending | Select -First 1)
    }
    # $AllPools.Algorithm | Select -Unique | ForEach {$Pools_Comparison | Add-Member $_ ($AllPools | Where Algorithm -EQ $_ | Sort StablePrice -Descending | Select -First 1)}
    #Load information about the Miners
    #Messy...?
    Update-Status("Loading miners..")
    $Variables.Miners = if (Test-Path "Miners") {Get-ChildItemContent "Miners" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} | 
            Where {$Config.Type.Count -eq 0 -or (Compare $Config.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} | 
            Where {$Config.Algorithm.Count -eq 0 -or (Compare $Config.Algorithm $_.HashRates.PSObject.Properties.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} | 
            Where {$Config.MinerName.Count -eq 0 -or (Compare $Config.MinerName $_.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}
    }
    $Variables.Miners = $Variables.Miners | ForEach {
        $Miner = $_
        if ((Test-Path $Miner.Path) -eq $false) {
            Update-Status("Downloading $($Miner.Name)..")
            if ((Split-Path $Miner.URI -Leaf) -eq (Split-Path $Miner.Path -Leaf)) {
                New-Item (Split-Path $Miner.Path) -ItemType "Directory" | Out-Null
                Invoke-WebRequest $Miner.URI -OutFile $_.Path -UseBasicParsing
            }
            elseif (([IO.FileInfo](Split-Path $_.URI -Leaf)).Extension -eq '') {
                $Path_Old = Get-PSDrive -PSProvider FileSystem | ForEach {Get-ChildItem -Path $_.Root -Include (Split-Path $Miner.Path -Leaf) -Recurse -ErrorAction Ignore} | Sort LastWriteTimeUtc -Descending | Select -First 1
                $Path_New = $Miner.Path

                if ($Path_Old -ne $null) {
                    if (Test-Path (Split-Path $Path_New)) {(Split-Path $Path_New) | Remove-Item -Recurse -Force}
                    (Split-Path $Path_Old) | Copy-Item -Destination (Split-Path $Path_New) -Recurse -Force
                }
                else {
                    Update-Status("Cannot find $($Miner.Path) distributed at $($Miner.URI). ")
                }
            }
            else {
                Expand-WebRequest $Miner.URI (Split-Path $Miner.Path)
            }
        }
        else {
            $Miner
        }
    }
    Update-Status("Comparing miners and pools..")
    if ($Variables.Miners.Count -eq 0) {Update-Status("No Miners!")}#; sleep $Config.Interval; continue}
    $Variables.Miners | ForEach {
        $Miner = $_
        $Miner_HashRates = [PSCustomObject]@{}
        $Miner_Pools = [PSCustomObject]@{}
        $Miner_Pools_Comparison = [PSCustomObject]@{}
        $Miner_Profits = [PSCustomObject]@{}
        $Miner_Profits_Comparison = [PSCustomObject]@{}
        $Miner_Profits_Bias = [PSCustomObject]@{}
        $Miner_Types = $Miner.Type | Select -Unique
        $Miner_Indexes = $Miner.Index | Select -Unique
        $Miner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
            $Miner_HashRates | Add-Member $_ ([Double]$Miner.HashRates.$_)
            $Miner_Pools | Add-Member $_ ([PSCustomObject]$Pools.$_)
            $Miner_Pools_Comparison | Add-Member $_ ([PSCustomObject]$Pools_Comparison.$_)
            $Miner_Profits | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.Price)
            $Miner_Profits_Comparison | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools_Comparison.$_.Price)
            $Miner_Profits_Bias | Add-Member $_ ([Double]$Miner.HashRates.$_ * $Pools.$_.Price * (1 - ($Config.MarginOfError * [Math]::Pow($Variables.DecayBase, $DecayExponent))))
        }
        $Miner_Profit = [Double]($Miner_Profits.PSObject.Properties.Value | Measure -Sum).Sum
        $Miner_Profit_Comparison = [Double]($Miner_Profits_Comparison.PSObject.Properties.Value | Measure -Sum).Sum
        $Miner_Profit_Bias = [Double]($Miner_Profits_Bias.PSObject.Properties.Value | Measure -Sum).Sum
        $Miner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
            if (-not [String]$Miner.HashRates.$_) {
                $Miner_HashRates.$_ = $null
                $Miner_Profits.$_ = $null
                $Miner_Profits_Comparison.$_ = $null
                $Miner_Profits_Bias.$_ = $null
                $Miner_Profit = $null
                $Miner_Profit_Comparison = $null
                $Miner_Profit_Bias = $null
            }
        }
        if ($Miner_Types -eq $null) {$Miner_Types = $Variables.Miners.Type | Select -Unique}
        if ($Miner_Indexes -eq $null) {$Miner_Indexes = $Variables.Miners.Index | Select -Unique}
        if ($Miner_Types -eq $null) {$Miner_Types = ""}
        if ($Miner_Indexes -eq $null) {$Miner_Indexes = 0}
        $Miner.HashRates = $Miner_HashRates
        $Miner | Add-Member Pools $Miner_Pools
        $Miner | Add-Member Profits $Miner_Profits
        $Miner | Add-Member Profits_Comparison $Miner_Profits_Comparison
        $Miner | Add-Member Profits_Bias $Miner_Profits_Bias
        $Miner | Add-Member Profit $Miner_Profit
        $Miner | Add-Member Profit_Comparison $Miner_Profit_Comparison
        $Miner | Add-Member Profit_Bias $Miner_Profit_Bias
        $Miner | Add-Member Profit_Bias_Orig $Miner_Profit_Bias
        $Miner | Add-Member Type $Miner_Types -Force
        $Miner | Add-Member Index $Miner_Indexes -Force
        $Miner.Path = Convert-Path $Miner.Path
    }
    $Variables.Miners | ForEach {
        $Miner = $_ 
        $Miner_Devices = $Miner.Device | Select -Unique
        if ($Miner_Devices -eq $null) {$Miner_Devices = ($Variables.Miners | Where {(Compare $Miner.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}).Device | Select -Unique}
        if ($Miner_Devices -eq $null) {$Miner_Devices = $Miner.Type}
        $Miner | Add-Member Device $Miner_Devices -Force
    }
    # Remove miners when no estimation info from pools. Avoids mining when algo down at pool or benchmarking for ever
    $Variables.Miners = $Variables.Miners | ? {$_.Pools.PSObject.Properties.Value.Price -ne $null}

    #Don't penalize active miners. Miner could switch a little bit later and we will restore his bias in this case
    $Variables.ActiveMinerPrograms | Where { $_.Status -eq "Running" } | ForEach {$Variables.Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit * (1 + $Config.ActiveMinerGainPct / 100)}}
    #Get most profitable miner combination i.e. AMD+NVIDIA+CPU
    $BestMiners = $Variables.Miners | Select Type, Index -Unique | ForEach {$Miner_GPU = $_; ($Variables.Miners | Where {(Compare $Miner_GPU.Type $_.Type | Measure).Count -eq 0 -and (Compare $Miner_GPU.Index $_.Index | Measure).Count -eq 0} | Sort -Descending {($_ | Where Profit -EQ $null | Measure).Count}, {($_ | Measure Profit_Bias -Sum).Sum}, {($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
    $BestDeviceMiners = $Variables.Miners | Select Device -Unique | ForEach {$Miner_GPU = $_; ($Variables.Miners | Where {(Compare $Miner_GPU.Device $_.Device | Measure).Count -eq 0} | Sort -Descending {($_ | Where Profit -EQ $null | Measure).Count}, {($_ | Measure Profit_Bias -Sum).Sum}, {($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
    $BestMiners_Comparison = $Variables.Miners | Select Type, Index -Unique | ForEach {$Miner_GPU = $_; ($Variables.Miners | Where {(Compare $Miner_GPU.Type $_.Type | Measure).Count -eq 0 -and (Compare $Miner_GPU.Index $_.Index | Measure).Count -eq 0} | Sort -Descending {($_ | Where Profit -EQ $null | Measure).Count}, {($_ | Measure Profit_Comparison -Sum).Sum}, {($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
    $BestDeviceMiners_Comparison = $Variables.Miners | Select Device -Unique | ForEach {$Miner_GPU = $_; ($Variables.Miners | Where {(Compare $Miner_GPU.Device $_.Device | Measure).Count -eq 0} | Sort -Descending {($_ | Where Profit -EQ $null | Measure).Count}, {($_ | Measure Profit_Comparison -Sum).Sum}, {($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
    $Miners_Type_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($Variables.Miners | Select Type -Unique) | Where {(Compare ($_.Combination | Select -ExpandProperty Type -Unique) ($_.Combination | Select -ExpandProperty Type) | Measure).Count -eq 0})
    $Miners_Index_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($Variables.Miners | Select Index -Unique) | Where {(Compare ($_.Combination | Select -ExpandProperty Index -Unique) ($_.Combination | Select -ExpandProperty Index) | Measure).Count -eq 0})
    $Miners_Device_Combos = (Get-Combination ($Variables.Miners | Select Device -Unique) | Where {(Compare ($_.Combination | Select -ExpandProperty Device -Unique) ($_.Combination | Select -ExpandProperty Device) | Measure).Count -eq 0})
    $BestMiners_Combos = $Miners_Type_Combos | ForEach {$Miner_Type_Combo = $_.Combination; $Miners_Index_Combos | ForEach {$Miner_Index_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Type_Combo | ForEach {$Miner_Type_Count = $_.Type.Count; [Regex]$Miner_Type_Regex = '^(' + (($_.Type | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $Miner_Index_Combo | ForEach {$Miner_Index_Count = $_.Index.Count; [Regex]$Miner_Index_Regex = '^(' + (($_.Index | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $BestMiners | Where {([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count}}}}}}
    $BestMiners_Combos += $Miners_Device_Combos | ForEach {$Miner_Device_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Device_Combo | ForEach {$Miner_Device_Count = $_.Device.Count; [Regex]$Miner_Device_Regex = '^(' + (($_.Device | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $BestDeviceMiners | Where {([Array]$_.Device -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $Miner_Device_Regex).Count -eq $Miner_Device_Count}}}}
    $BestMiners_Combos_Comparison = $Miners_Type_Combos | ForEach {$Miner_Type_Combo = $_.Combination; $Miners_Index_Combos | ForEach {$Miner_Index_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Type_Combo | ForEach {$Miner_Type_Count = $_.Type.Count; [Regex]$Miner_Type_Regex = '^(' + (($_.Type | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $Miner_Index_Combo | ForEach {$Miner_Index_Count = $_.Index.Count; [Regex]$Miner_Index_Regex = '^(' + (($_.Index | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $BestMiners_Comparison | Where {([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count}}}}}}
    $BestMiners_Combos_Comparison += $Miners_Device_Combos | ForEach {$Miner_Device_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Device_Combo | ForEach {$Miner_Device_Count = $_.Device.Count; [Regex]$Miner_Device_Regex = '^(' + (($_.Device | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $BestDeviceMiners_Comparison | Where {([Array]$_.Device -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $Miner_Device_Regex).Count -eq $Miner_Device_Count}}}}
    $BestMiners_Combo = $BestMiners_Combos | Sort -Descending {($_.Combination | Where Profit -EQ $null | Measure).Count}, {($_.Combination | Measure Profit_Bias -Sum).Sum}, {($_.Combination | Where Profit -NE 0 | Measure).Count} | Select -First 1 | Select -ExpandProperty Combination
    $BestMiners_Combo_Comparison = $BestMiners_Combos_Comparison | Sort -Descending {($_.Combination | Where Profit -EQ $null | Measure).Count}, {($_.Combination | Measure Profit_Comparison -Sum).Sum}, {($_.Combination | Where Profit -NE 0 | Measure).Count} | Select -First 1 | Select -ExpandProperty Combination
    #Add the most profitable miners to the active list
    $BestMiners_Combo | ForEach {
        if (($Variables.ActiveMinerPrograms | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments).Count -eq 0) {
            $Variables.ActiveMinerPrograms += [PSCustomObject]@{
                Name              = $_.Name
                Path              = $_.Path
                Arguments         = $_.Arguments
                Wrap              = $_.Wrap
                Process           = $null
                API               = $_.API
                Port              = $_.Port
                Algorithms        = $_.HashRates.PSObject.Properties.Name
                New               = $false
                Active            = [TimeSpan]0
                Activated         = 0
                Status            = "Idle"
                HashRate          = 0
                Benchmarked       = 0
                Hashrate_Gathered = ($_.HashRates.PSObject.Properties.Value -ne $null)
                User              = $_.User
            }
        }
    }
    #Stop or start miners in the active list depending on if they are the most profitable
    # We have to stop processes first or the port would be busy
    $Variables.ActiveMinerPrograms | ForEach {
        [Array]$filtered = ($BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments)
        if ($filtered.Count -eq 0) {
            if ($_.Process -eq $null) {
                $_.Status = "Failed"
            }
            elseif ($_.Process.HasExited -eq $false) {
                $_.Active += (Get-Date) - $_.Process.StartTime
                $_.Process.CloseMainWindow() | Out-Null
                Sleep 1
                # simply "Kill with power"
                Stop-Process $_.Process -Force | Out-Null
                Update-Status("closing current miner and switching")
                Sleep 1
                $_.Status = "Idle"
            }
            #Restore Bias for non-active miners
            $Variables.Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit_Bias_Orig}
        }
    }
    $newMiner = $false
    $CurrentMinerHashrate_Gathered = $false 
    $newMiner = $false
    $CurrentMinerHashrate_Gathered = $false 
    $Variables.ActiveMinerPrograms | ForEach {
        [Array]$filtered = ($BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments)
        if ($filtered.Count -gt 0) {
            if ($_.Process -eq $null -or $_.Process.HasExited -ne $false) {
                # Log switching information to .\log\swicthing.log
                [pscustomobject]@{date = (get-date); algo = $_.Algorithms; wallet = $_.User; username = $Config.UserName; Stratum = ($_.Arguments.Split(" ") | ? {$_ -like "*.*:*"})} | export-csv .\Logs\switching.log -Append -NoTypeInformation
                    
                # Launch prerun if exists
                $PrerunName = ".\Prerun\" + $_.Algorithms + ".bat"
                $DefaultPrerunName = ".\Prerun\default.bat"
                If (Test-Path $PrerunName) {
                    Update-Status("Launching Prerun: $PrerunName")
                    Start-Process $PrerunName -WorkingDirectory ".\Prerun" -WindowStyle hidden
                    Sleep 2
                }
                else {
                    If (Test-Path $DefaultPrerunName) {
                        Write-Host -F Yellow "Launching Prerun: " $DefaultPrerunName
                        Update-Status("Launching Prerun: $DefaultPrerunName")
                        Start-Process $DefaultPrerunName -WorkingDirectory ".\Prerun" -WindowStyle hidden
                        Sleep 2
                    }
                }

                Sleep $Config.Delay #Wait to prevent BSOD
                Update-Status("Starting miner")
                $Variables.DecayStart = Get-Date
                $_.New = $true
                $_.Activated++
                if ($_.Process -ne $null) {$_.Active += $_.Process.ExitTime - $_.Process.StartTime}
                if ($_.Wrap) {$_.Process = Start-Process -FilePath "PowerShell" -ArgumentList "-executionpolicy bypass -command . '$(Convert-Path ".\Wrapper.ps1")' -ControllerProcessID $PID -Id '$($_.Port)' -FilePath '$($_.Path)' -ArgumentList '$($_.Arguments)' -WorkingDirectory '$(Split-Path $_.Path)'" -PassThru}
                else {$_.Process = Start-SubProcess -FilePath $_.Path -ArgumentList $_.Arguments -WorkingDirectory (Split-Path $_.Path)}
                if ($_.Process -eq $null) {$_.Status = "Failed"}
                else {
                    $_.Status = "Running"
                    $newMiner = $true
                    #Newely started miner should looks better than other in the first run too
                    $Variables.Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit * (1 + $Config.ActiveMinerGainPct / 100)}
                    $newMiner = $true
                    #Newely started miner should looks better than other in the first run too
                    $Variables.Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit * (1 + $Config.ActiveMinerGainPct / 100)}
                }
            }
            $CurrentMinerHashrate_Gathered = $_.Hashrate_Gathered
        }
    }
    #Display mining information
    if ($host.UI.RawUI.KeyAvailable) {
        $KeyPressed = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp"); sleep -Milliseconds 300; $host.UI.RawUI.FlushInputBuffer()
        If ($KeyPressed.KeyDown) {
            Switch ($KeyPressed.Character) {
                "s" {if ($Config.UIStyle -eq "Light") {$Config.UIStyle = "Full"}else {$Config.UIStyle = "Light"}}
                "e" {$Config.TrackEarnings = -not $Config.TrackEarnings}
            }
        }
    }
    Clear-Host
    [Array] $processesIdle = $Variables.ActiveMinerPrograms | Where { $_.Status -eq "Idle" }
    IF ($Config.UIStyle -eq "Full") {
        if ($processesIdle.Count -gt 0) {
            Write-Host "Idle: " $processesIdle.Count
            $processesIdle | Sort {if ($_.Process -eq $null) {(Get-Date)}else {$_.Process.ExitTime}} | Format-Table -Wrap (
                @{Label = "Speed"; Expression = {$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align = 'right'}, 
                @{Label = "Exited"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {(0)}else {(Get-Date) - $_.Process.ExitTime}) }},
                @{Label = "Active"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {$_.Active}else {if ($_.Process.ExitTime -gt $_.Process.StartTime) {($_.Active + ($_.Process.ExitTime - $_.Process.StartTime))}else {($_.Active + ((Get-Date) - $_.Process.StartTime))}})}}, 
                @{Label = "Cnt"; Expression = {Switch ($_.Activated) {0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
                @{Label = "Command"; Expression = {"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
            ) | Out-Host
        }
    }
    Write-Host "      1$($Config.Passwordcurrency) = $($Variables.Rates.($Config.Currency)) $($Config.Currency)"
    # Get and display earnings stats
    $Variables.EarningsTrackerJobs | ? {$_.state -eq "Running"} | foreach {
        $EarnTrack = $_ | Receive-Job
        If ($EarnTrack) {
            $Variables.EarningsPool = (($EarnTrack[($EarnTrack.Count - 1)]).Pool)
            # $Variables.Earnings.$Variables.EarningsPool = $EarnTrack[($EarnTrack.Count - 1)]
            $Variables.Earnings.(($EarnTrack[($EarnTrack.Count - 1)]).Pool) = $EarnTrack[($EarnTrack.Count - 1)]
        }
    }
    If ($Variables.Earnings -and $Config.TrackEarnings) {
        # $Variables.Earnings.Values | select Pool,Wallet,Balance,AvgDailyGrowth,EstimatedPayDate,TrustLevel | ft *
        $Variables.Earnings.Values | foreach {
            Write-Host "+++++" $_.Wallet -B DarkBlue -F DarkGray -NoNewline; Write-Host " " $_.pool "Balance="$_.balance ("{0:P0}" -f ($_.balance / $_.PaymentThreshold))
            Write-Host "Trust Level                     " ("{0:P0}" -f $_.TrustLevel) -NoNewline; Write-Host -F darkgray " Avg based on [" ("{0:dd\ \d\a\y\s\ hh\:mm}" -f ($_.Date - $_.StartTime))"]"
            Write-Host "Average BTC/H                    BTC =" ("{0:N8}" -f $_.AvgHourlyGrowth) "| mBTC =" ("{0:N3}" -f ($_.AvgHourlyGrowth * 1000))
            Write-Host "Average BTC/D" -NoNewline; Write-Host "                    BTC =" ("{0:N8}" -f ($_.AvgDailyGrowth)) "| mBTC =" ("{0:N3}" -f ($_.AvgDailyGrowth * 1000)) -F Yellow
            Write-Host "Estimated Pay Date              " $_.EstimatedPayDate ">" $_.PaymentThreshold "BTC"
            # Write-Host "+++++" -F Blue
        }
    }
    Write-Host "+++++" -F Blue
    if ($Variables.Miners | ? {$_.HashRates.PSObject.Properties.Value -eq $null}) {$Config.UIStyle = "Full"}
    IF ($Config.UIStyle -eq "Full") {

        $Variables.Miners | Sort -Descending Type, Profit | Format-Table -GroupBy Type (
            @{Label = "Miner"; Expression = {$_.Name}}, 
            @{Label = "Algorithm"; Expression = {$_.HashRates.PSObject.Properties.Name}}, 
            @{Label = "Speed"; Expression = {$_.HashRates.PSObject.Properties.Value | ForEach {if ($_ -ne $null) {"$($_ | ConvertTo-Hash)/s"}else {"Benchmarking"}}}; Align = 'right'}, 
            @{Label = "mBTC/Day"; Expression = {$_.Profits.PSObject.Properties.Value * 1000 | ForEach {if ($_ -ne $null) {$_.ToString("N3")}else {"Benchmarking"}}}; Align = 'right'}, 
            @{Label = "BTC/Day"; Expression = {$_.Profits.PSObject.Properties.Value | ForEach {if ($_ -ne $null) {$_.ToString("N5")}else {"Benchmarking"}}}; Align = 'right'}, 
            @{Label = "$($Config.Currency)/Day"; Expression = {$_.Profits.PSObject.Properties.Value | ForEach {if ($_ -ne $null) {($_ * $Variables.Rates.($Config.Currency)).ToString("N3")}else {"Benchmarking"}}}; Align = 'right'}, 
            @{Label = "BTC/GH/Day"; Expression = {$_.Pools.PSObject.Properties.Value.Price | ForEach {($_ * 1000000000).ToString("N5")}}; Align = 'right'},
            @{Label = "Pool"; Expression = {$_.Pools.PSObject.Properties.Value | ForEach {"$($_.Name)-$($_.Info)"}}}
        ) | Out-Host
        #Display active miners list
        [Array] $processRunning = $Variables.ActiveMinerPrograms | Where { $_.Status -eq "Running" }
        Write-Host "Running:"
        $processRunning | Sort {if ($_.Process -eq $null) {[DateTime]0}else {$_.Process.StartTime}} | Select -First (1) | Format-Table -Wrap (
            @{Label = "Speed"; Expression = {$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align = 'right'}, 
            @{Label = "Started"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {(0)}else {(Get-Date) - $_.Process.StartTime}) }},
            @{Label = "Active"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {$_.Active}else {if ($_.Process.ExitTime -gt $_.Process.StartTime) {($_.Active + ($_.Process.ExitTime - $_.Process.StartTime))}else {($_.Active + ((Get-Date) - $_.Process.StartTime))}})}}, 
            @{Label = "Cnt"; Expression = {Switch ($_.Activated) {0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
            @{Label = "Command"; Expression = {"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
        ) | Out-Host
        [Array] $processesFailed = $Variables.ActiveMinerPrograms | Where { $_.Status -eq "Failed" }
        if ($processesFailed.Count -gt 0) {
            Write-Host -ForegroundColor Red "Failed: " $processesFailed.Count
            $processesFailed | Sort {if ($_.Process -eq $null) {[DateTime]0}else {$_.Process.StartTime}} | Format-Table -Wrap (
                @{Label = "Speed"; Expression = {$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align = 'right'}, 
                @{Label = "Exited"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {(0)}else {(Get-Date) - $_.Process.ExitTime}) }},
                @{Label = "Active"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {$_.Active}else {if ($_.Process.ExitTime -gt $_.Process.StartTime) {($_.Active + ($_.Process.ExitTime - $_.Process.StartTime))}else {($_.Active + ((Get-Date) - $_.Process.StartTime))}})}}, 
                @{Label = "Cnt"; Expression = {Switch ($_.Activated) {0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
                @{Label = "Command"; Expression = {"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
            ) | Out-Host
        }
        Write-Host "--------------------------------------------------------------------------------"
        
    }
    else {
        [Array] $processRunning = $Variables.ActiveMinerPrograms | Where { $_.Status -eq "Running" }
        Write-Host "Running:"
        $processRunning | Sort {if ($_.Process -eq $null) {[DateTime]0}else {$_.Process.StartTime}} | Select -First (1) | Format-Table -Wrap (
            @{Label = "Speed"; Expression = {$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align = 'right'}, 
            @{Label = "Started"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {(0)}else {(Get-Date) - $_.Process.StartTime}) }},
            @{Label = "Active"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {$_.Active}else {if ($_.Process.ExitTime -gt $_.Process.StartTime) {($_.Active + ($_.Process.ExitTime - $_.Process.StartTime))}else {($_.Active + ((Get-Date) - $_.Process.StartTime))}})}}, 
            @{Label = "Cnt"; Expression = {Switch ($_.Activated) {0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
            @{Label = "Command"; Expression = {"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
        ) | Out-Host
        Write-Host "--------------------------------------------------------------------------------"
    }
    Write-Host -ForegroundColor Yellow "Last Refresh: $(Get-Date)"
    #Do nothing for a few seconds as to not overload the APIs
    if ($newMiner -eq $true) {
        if ($Config.Interval -ge $Config.FirstInterval -and $Config.Interval -ge $Config.StatsInterval) { $timeToSleep = $Config.Interval }
        else {
            if ($CurrentMinerHashrate_Gathered -eq $true) { $timeToSleep = $Config.FirstInterval }
            else { $timeToSleep = $Config.StatsInterval }
        }
    }
    else {
        $timeToSleep = $Config.Interval
    }
    # IF ($Config.UIStyle -eq "Full"){Write-Host "Sleep" ($timeToSleep) "sec"} else {Write-Host "Sleep" ($timeToSleep*2) "sec"}
        
    # Sleep $timeToSleep
    $timerCycle.Interval = $timeToSleep * 1000
    Write-Host "--------------------------------------------------------------------------------"
    IF ($Config.UIStyle -eq "Full") {
        #Display active miners list
        [Array] $processRunning = $Variables.ActiveMinerPrograms | Where { $_.Status -eq "Running" }
        Write-Host "Running:"
        $processRunning | Sort {if ($_.Process -eq $null) {[DateTime]0}else {$_.Process.StartTime}} | Select -First (1) | Format-Table -Wrap (
            @{Label = "Speed"; Expression = {$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align = 'right'}, 
            @{Label = "Started"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {(0)}else {(Get-Date) - $_.Process.StartTime}) }},
            @{Label = "Active"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {$_.Active}else {if ($_.Process.ExitTime -gt $_.Process.StartTime) {($_.Active + ($_.Process.ExitTime - $_.Process.StartTime))}else {($_.Active + ((Get-Date) - $_.Process.StartTime))}})}}, 
            @{Label = "Cnt"; Expression = {Switch ($_.Activated) {0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
            @{Label = "Command"; Expression = {"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
        ) | Out-Host
        [Array] $processesFailed = $Variables.ActiveMinerPrograms | Where { $_.Status -eq "Failed" }
        if ($processesFailed.Count -gt 0) {
            Write-Host -ForegroundColor Red "Failed: " $processesFailed.Count
            $processesFailed | Sort {if ($_.Process -eq $null) {[DateTime]0}else {$_.Process.StartTime}} | Format-Table -Wrap (
                @{Label = "Speed"; Expression = {$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align = 'right'}, 
                @{Label = "Exited"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {(0)}else {(Get-Date) - $_.Process.ExitTime}) }},
                @{Label = "Active"; Expression = {"{0:dd}:{0:hh}:{0:mm}" -f $(if ($_.Process -eq $null) {$_.Active}else {if ($_.Process.ExitTime -gt $_.Process.StartTime) {($_.Active + ($_.Process.ExitTime - $_.Process.StartTime))}else {($_.Active + ((Get-Date) - $_.Process.StartTime))}})}}, 
                @{Label = "Cnt"; Expression = {Switch ($_.Activated) {0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
                @{Label = "Command"; Expression = {"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
            ) | Out-Host
        }
        Write-Host "--------------------------------------------------------------------------------"
    }
    #Do nothing for a few seconds as to not overload the APIs
    if ($newMiner -eq $true) {
        if ($Config.Interval -ge $Config.FirstInterval -and $Config.Interval -ge $Config.StatsInterval) { $timeToSleep = $Config.Interval }
        else {
            if ($CurrentMinerHashrate_Gathered -eq $true) { $timeToSleep = $Config.FirstInterval }
            else { $timeToSleep = $Config.StatsInterval }
        }
    }
    else {
        $timeToSleep = $Config.Interval
    }
    $timerCycle.Interval = $timeToSleep * 1000
    #Save current hash rates
    $Variables.ActiveMinerPrograms | ForEach {
        if ($_.Process -eq $null -or $_.Process.HasExited) {
            if ($_.Status -eq "Running") {$_.Status = "Failed"}
        }
        else {
            # we don't want to store hashrates if we run less than $Config.StatsInterval sec
            $WasActive = [math]::Round(((Get-Date) - $_.Process.StartTime).TotalSeconds)
            if ($WasActive -ge $Config.StatsInterval) {
                $_.HashRate = 0
                $Miner_HashRates = $null
                if ($_.New) {$_.Benchmarked++}         
                $Miner_HashRates = Get-HashRate $_.API $_.Port ($_.New -and $_.Benchmarked -lt 3)
                $_.HashRate = $Miner_HashRates | Select -First $_.Algorithms.Count           
                if ($Miner_HashRates.Count -ge $_.Algorithms.Count) {
                    for ($i = 0; $i -lt $_.Algorithms.Count; $i++) {
                        $Stat = Set-Stat -Name "$($_.Name)_$($_.Algorithms | Select -Index $i)_HashRate" -Value ($Miner_HashRates | Select -Index $i)
                    }
                    $_.New = $false
                    $_.Hashrate_Gathered = $true
                    Write-Host "Stats '"$_.Algorithms"' -> "($Miner_HashRates | ConvertTo-Hash)"after"$WasActive" sec"
                }
            }
        }
        #Benchmark timeout
        #        if($_.Benchmarked -ge 6 -or ($_.Benchmarked -ge 2 -and $_.Activated -ge 2))
        #        {
        #            for($i = 0; $i -lt $_.Algorithms.Count; $i++)
        #            {
        #                if((Get-Stat "$($_.Name)_$($_.Algorithms | Select -Index $i)_HashRate") -eq $null)
        #                {
        #                    $Stat = Set-Stat -Name "$($_.Name)_$($_.Algorithms | Select -Index $i)_HashRate" -Value 0
        #                }
        #            }
        #        }
    }
    # }
    Update-Status("Sleeping $($timeToSleep)")
    $timerCycle.Start()
}
#Stop the log
# Stop-Transcript
