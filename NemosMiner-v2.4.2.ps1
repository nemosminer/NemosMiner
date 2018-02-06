param(
    [Parameter(Mandatory=$false)]
    [String]$Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE", 
    [Parameter(Mandatory=$false)]
    [String]$UserName, 
    [Parameter(Mandatory=$false)]
    [String]$WorkerName = "ID=NemosMiner-v2.4.2", 
    [Parameter(Mandatory=$false)]
    [Int]$API_ID = 0, 
    [Parameter(Mandatory=$false)]
    [String]$API_Key = "", 
    [Parameter(Mandatory=$false)]
    [Int]$Interval = 15, #seconds before between cycles after the first has passed 
    [Parameter(Mandatory=$false)]
    [Int]$FirstInterval = 30, #seconds of the first cycle of activated or started first time miner
    [Parameter(Mandatory=$false)]
    [Int]$StatsInterval = 300, #seconds of current active to gather hashrate if not gathered yet
    [Parameter(Mandatory=$false)]
    [String]$Location = "US", #europe/us/asia
    [Parameter(Mandatory=$false)]
    [Switch]$SSL = $false, 
    [Parameter(Mandatory=$false)]
    [Array]$Type = "nvidia", #AMD/NVIDIA/CPU
    [Parameter(Mandatory=$false)]
    [String]$SelGPUDSTM = "0 1",
    [Parameter(Mandatory=$false)]
    [String]$SelGPUCC = "0,1",
    [Parameter(Mandatory=$false)]
    [Array]$Algorithm = $null, #i.e. Ethash,Equihash,Cryptonight ect.
    [Parameter(Mandatory=$false)]
    [Array]$MinerName = $null, 
    [Parameter(Mandatory=$false)]
    [Array]$PoolName = $null, 
    [Parameter(Mandatory=$false)]
    [Array]$Currency = ("USD"), #i.e. GBP,USD,AUD,NZD ect.
    [Parameter(Mandatory=$false)]
    [Array]$Passwordcurrency = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory=$false)]
    [Int]$Donate = 0, #Minutes per Day
    [Parameter(Mandatory=$false)]
    [String]$Proxy = "", #i.e http://192.0.0.1:8080 
    [Parameter(Mandatory=$false)]
    [Int]$Delay = 1, #seconds before opening each miner
    [Parameter(Mandatory=$false)]
    [Int]$ActiveMinerGainPct = 3, # percent of advantage that active miner has over candidates in term of profit
    [Parameter(Mandatory=$false)]
    [Float]$MarginOfError = 0.35 # knowledge about the past wont help us to predict the future so don't pretend that Week_Fluctuation means something real
)
Set-Location (Split-Path $script:MyInvocation.MyCommand.Path)
Get-ChildItem . -Recurse | Unblock-File
Write-host "INFO: Adding NemosMiner path to Windows Defender's exclusions.. (may show an error if Windows Defender is disabled)" -foregroundcolor "Yellow"
try{if((Get-MpPreference).ExclusionPath -notcontains (Convert-Path .)){Start-Process powershell -Verb runAs -ArgumentList "Add-MpPreference -ExclusionPath '$(Convert-Path .)'"}}catch{}
if($Proxy -eq ""){$PSDefaultParameterValues.Remove("*:Proxy")}
else{$PSDefaultParameterValues["*:Proxy"] = $Proxy}
. .\Include.ps1
$DecayStart = Get-Date
$DecayPeriod = 30 #seconds
$DecayBase = 1-0.1 #decimal percentage
$ActiveMinerPrograms = @()
#Start the log
Start-Transcript -Path ".\Logs\miner.log" -Append -Force
#Update stats with missing data and set to today's date/time
if(Test-Path "Stats"){Get-ChildItemContent "Stats" | ForEach {$Stat = Set-Stat $_.Name $_.Content.Week}}
#Set donation parameters
$LastDonated = (Get-Date).AddDays(-1).AddHours(1)
$WalletDonate = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"
$UserNameDonate = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"
$WorkerNameDonate = "NemosMiner-v2.4.2"
$WalletBackup = $Wallet
$UserNameBackup = $UserName
$WorkerNameBackup = $WorkerName
while($true)
{
    $DecayExponent = [int](((Get-Date)-$DecayStart).TotalSeconds/$DecayPeriod)
    #Activate or deactivate donation
    if((Get-Date).AddDays(-1).AddMinutes($Donate) -ge $LastDonated)
    {
        if ($Wallet) {$Wallet = $WalletDonate}
        if ($UserName) {$UserName = $UserNameDonate}
        if ($WorkerName) {$WorkerName = $WorkerNameDonate}
    }
    if((Get-Date).AddDays(-1) -ge $LastDonated)
    {
        $Wallet = $WalletBackup
        $UserName = $UserNameBackup
        $WorkerName = $WorkerNameBackup
        $LastDonated = Get-Date
    }
    Write-host "Loading BTC rate from 'api.coinbase.com'.." -foregroundcolor "Yellow"
    $Rates = Invoke-RestMethod "https://api.coinbase.com/v2/exchange-rates?currency=BTC" -UseBasicParsing | Select-Object -ExpandProperty data | Select-Object -ExpandProperty rates
    $Currency | Where-Object {$Rates.$_} | ForEach-Object {$Rates | Add-Member $_ ([Double]$Rates.$_) -Force}
    #Load the Stats
    $Stats = [PSCustomObject]@{}
    if(Test-Path "Stats"){Get-ChildItemContent "Stats" | ForEach {$Stats | Add-Member $_.Name $_.Content}}
    #Load information about the Pools
    Write-host "Loading pool stats.." -foregroundcolor "Yellow"
    $AllPools = if(Test-Path "Pools"){Get-ChildItemContent "Pools" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} | 
        Where Location -EQ $Location | 
        Where SSL -EQ $SSL | 
        Where {$PoolName.Count -eq 0 -or (Compare $PoolName $_.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}}
    if($AllPools.Count -eq 0){Write-host "Error contacting pool, retrying..`n" -foregroundcolor "Yellow" | Out-Host; sleep 15; continue}
    $Pools = [PSCustomObject]@{}
    $Pools_Comparison = [PSCustomObject]@{}
    $AllPools.Algorithm | Select -Unique | ForEach {$Pools | Add-Member $_ ($AllPools | Where Algorithm -EQ $_ | Sort Price -Descending | Select -First 1)}
    $AllPools.Algorithm | Select -Unique | ForEach {$Pools_Comparison | Add-Member $_ ($AllPools | Where Algorithm -EQ $_ | Sort StablePrice -Descending | Select -First 1)}
    #Load information about the Miners
    #Messy...?
    Write-host "Loading miners.." -foregroundcolor "Yellow"
    $Miners = if(Test-Path "Miners"){Get-ChildItemContent "Miners" | ForEach {$_.Content | Add-Member @{Name = $_.Name} -PassThru} | 
        Where {$Type.Count -eq 0 -or (Compare $Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} | 
        Where {$Algorithm.Count -eq 0 -or (Compare $Algorithm $_.HashRates.PSObject.Properties.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0} | 
        Where {$MinerName.Count -eq 0 -or (Compare $MinerName $_.Name -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}}
    $Miners = $Miners | ForEach {
        $Miner = $_
        if((Test-Path $Miner.Path) -eq $false)
        {
            Write-host "Downloading $($Miner.Name).." -foregroundcolor "Yellow"
            if((Split-Path $Miner.URI -Leaf) -eq (Split-Path $Miner.Path -Leaf))
            {
                New-Item (Split-Path $Miner.Path) -ItemType "Directory" | Out-Null
                Invoke-WebRequest $Miner.URI -OutFile $_.Path -UseBasicParsing
            }
            elseif(([IO.FileInfo](Split-Path $_.URI -Leaf)).Extension -eq '')
            {
                $Path_Old = Get-PSDrive -PSProvider FileSystem | ForEach {Get-ChildItem -Path $_.Root -Include (Split-Path $Miner.Path -Leaf) -Recurse -ErrorAction Ignore} | Sort LastWriteTimeUtc -Descending | Select -First 1
                $Path_New = $Miner.Path

                if($Path_Old -ne $null)
                {
                    if(Test-Path (Split-Path $Path_New)){(Split-Path $Path_New) | Remove-Item -Recurse -Force}
                    (Split-Path $Path_Old) | Copy-Item -Destination (Split-Path $Path_New) -Recurse -Force
                }
                else
                {
                    Write-Host -BackgroundColor Yellow -ForegroundColor Black "Cannot find $($Miner.Path) distributed at $($Miner.URI). "
                }
            }
            else
            {
                Expand-WebRequest $Miner.URI (Split-Path $Miner.Path)
            }
        }
        else
        {
            $Miner
        }
    }
    if($Miners.Count -eq 0){"No Miners!" | Out-Host; sleep $Interval; continue}
    $Miners | ForEach {
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
            $Miner_Profits | Add-Member $_ ([Double]$Miner.HashRates.$_*$Pools.$_.Price)
            $Miner_Profits_Comparison | Add-Member $_ ([Double]$Miner.HashRates.$_*$Pools_Comparison.$_.Price)
            $Miner_Profits_Bias | Add-Member $_ ([Double]$Miner.HashRates.$_*$Pools.$_.Price*(1-($MarginOfError*[Math]::Pow($DecayBase,$DecayExponent))))
        }
        $Miner_Profit = [Double]($Miner_Profits.PSObject.Properties.Value | Measure -Sum).Sum
        $Miner_Profit_Comparison = [Double]($Miner_Profits_Comparison.PSObject.Properties.Value | Measure -Sum).Sum
        $Miner_Profit_Bias = [Double]($Miner_Profits_Bias.PSObject.Properties.Value | Measure -Sum).Sum
        $Miner.HashRates | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
            if(-not [String]$Miner.HashRates.$_)
            {
                $Miner_HashRates.$_ = $null
                $Miner_Profits.$_ = $null
                $Miner_Profits_Comparison.$_ = $null
                $Miner_Profits_Bias.$_ = $null
                $Miner_Profit = $null
                $Miner_Profit_Comparison = $null
                $Miner_Profit_Bias = $null
            }
        }
        if($Miner_Types -eq $null){$Miner_Types = $Miners.Type | Select -Unique}
        if($Miner_Indexes -eq $null){$Miner_Indexes = $Miners.Index | Select -Unique}
        if($Miner_Types -eq $null){$Miner_Types = ""}
        if($Miner_Indexes -eq $null){$Miner_Indexes = 0}
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
    $Miners | ForEach {
        $Miner = $_
        $Miner_Devices = $Miner.Device | Select -Unique
        if($Miner_Devices -eq $null){$Miner_Devices = ($Miners | Where {(Compare $Miner.Type $_.Type -IncludeEqual -ExcludeDifferent | Measure).Count -gt 0}).Device | Select -Unique}
        if($Miner_Devices -eq $null){$Miner_Devices = $Miner.Type}
        $Miner | Add-Member Device $Miner_Devices -Force
    }
    #Don't penalize active miners. Miner could switch a little bit later and we will restore his bias in this case
    $ActiveMinerPrograms | Where { $_.Status -eq "Running" } | ForEach {$Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit * (1 + $ActiveMinerGainPct / 100)}}
    #Get most profitable miner combination i.e. AMD+NVIDIA+CPU
    $BestMiners = $Miners | Select Type,Index -Unique | ForEach {$Miner_GPU = $_; ($Miners | Where {(Compare $Miner_GPU.Type $_.Type | Measure).Count -eq 0 -and (Compare $Miner_GPU.Index $_.Index | Measure).Count -eq 0} | Sort -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Bias -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
    $BestDeviceMiners = $Miners | Select Device -Unique | ForEach {$Miner_GPU = $_; ($Miners | Where {(Compare $Miner_GPU.Device $_.Device | Measure).Count -eq 0} | Sort -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Bias -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
    $BestMiners_Comparison = $Miners | Select Type,Index -Unique | ForEach {$Miner_GPU = $_; ($Miners | Where {(Compare $Miner_GPU.Type $_.Type | Measure).Count -eq 0 -and (Compare $Miner_GPU.Index $_.Index | Measure).Count -eq 0} | Sort -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Comparison -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
    $BestDeviceMiners_Comparison = $Miners | Select Device -Unique | ForEach {$Miner_GPU = $_; ($Miners | Where {(Compare $Miner_GPU.Device $_.Device | Measure).Count -eq 0} | Sort -Descending {($_ | Where Profit -EQ $null | Measure).Count},{($_ | Measure Profit_Comparison -Sum).Sum},{($_ | Where Profit -NE 0 | Measure).Count} | Select -First 1)}
    $Miners_Type_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($Miners | Select Type -Unique) | Where{(Compare ($_.Combination | Select -ExpandProperty Type -Unique) ($_.Combination | Select -ExpandProperty Type) | Measure).Count -eq 0})
    $Miners_Index_Combos = @([PSCustomObject]@{Combination = @()}) + (Get-Combination ($Miners | Select Index -Unique) | Where{(Compare ($_.Combination | Select -ExpandProperty Index -Unique) ($_.Combination | Select -ExpandProperty Index) | Measure).Count -eq 0})
    $Miners_Device_Combos = (Get-Combination ($Miners | Select Device -Unique) | Where{(Compare ($_.Combination | Select -ExpandProperty Device -Unique) ($_.Combination | Select -ExpandProperty Device) | Measure).Count -eq 0})
    $BestMiners_Combos = $Miners_Type_Combos | ForEach {$Miner_Type_Combo = $_.Combination; $Miners_Index_Combos | ForEach {$Miner_Index_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Type_Combo | ForEach {$Miner_Type_Count = $_.Type.Count; [Regex]$Miner_Type_Regex = '^(' + (($_.Type | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $Miner_Index_Combo | ForEach {$Miner_Index_Count = $_.Index.Count; [Regex]$Miner_Index_Regex = '^(' + (($_.Index | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $BestMiners | Where {([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count}}}}}}
    $BestMiners_Combos += $Miners_Device_Combos | ForEach {$Miner_Device_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Device_Combo | ForEach {$Miner_Device_Count = $_.Device.Count; [Regex]$Miner_Device_Regex = '^(' + (($_.Device | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $BestDeviceMiners | Where {([Array]$_.Device -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $Miner_Device_Regex).Count -eq $Miner_Device_Count}}}}
    $BestMiners_Combos_Comparison = $Miners_Type_Combos | ForEach {$Miner_Type_Combo = $_.Combination; $Miners_Index_Combos | ForEach {$Miner_Index_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Type_Combo | ForEach {$Miner_Type_Count = $_.Type.Count; [Regex]$Miner_Type_Regex = '^(' + (($_.Type | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $Miner_Index_Combo | ForEach {$Miner_Index_Count = $_.Index.Count; [Regex]$Miner_Index_Regex = '^(' + (($_.Index | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $BestMiners_Comparison | Where {([Array]$_.Type -notmatch $Miner_Type_Regex).Count -eq 0 -and ([Array]$_.Index -notmatch $Miner_Index_Regex).Count -eq 0 -and ([Array]$_.Type -match $Miner_Type_Regex).Count -eq $Miner_Type_Count -and ([Array]$_.Index -match $Miner_Index_Regex).Count -eq $Miner_Index_Count}}}}}}
    $BestMiners_Combos_Comparison += $Miners_Device_Combos | ForEach {$Miner_Device_Combo = $_.Combination; [PSCustomObject]@{Combination = $Miner_Device_Combo | ForEach {$Miner_Device_Count = $_.Device.Count; [Regex]$Miner_Device_Regex = '^(' + (($_.Device | ForEach {[Regex]::Escape($_)}) -join '|') + ')$'; $BestDeviceMiners_Comparison | Where {([Array]$_.Device -notmatch $Miner_Device_Regex).Count -eq 0 -and ([Array]$_.Device -match $Miner_Device_Regex).Count -eq $Miner_Device_Count}}}}
    $BestMiners_Combo = $BestMiners_Combos | Sort -Descending {($_.Combination | Where Profit -EQ $null | Measure).Count},{($_.Combination | Measure Profit_Bias -Sum).Sum},{($_.Combination | Where Profit -NE 0 | Measure).Count} | Select -First 1 | Select -ExpandProperty Combination
    $BestMiners_Combo_Comparison = $BestMiners_Combos_Comparison | Sort -Descending {($_.Combination | Where Profit -EQ $null | Measure).Count},{($_.Combination | Measure Profit_Comparison -Sum).Sum},{($_.Combination | Where Profit -NE 0 | Measure).Count} | Select -First 1 | Select -ExpandProperty Combination
    #Add the most profitable miners to the active list
    $BestMiners_Combo | ForEach {
        if(($ActiveMinerPrograms | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments).Count -eq 0)
        {
            $ActiveMinerPrograms += [PSCustomObject]@{
                Name = $_.Name
                Path = $_.Path
                Arguments = $_.Arguments
                Wrap = $_.Wrap
                Process = $null
                API = $_.API
                Port = $_.Port
                Algorithms = $_.HashRates.PSObject.Properties.Name
                New = $false
                Active = [TimeSpan]0
                Activated = 0
                Status = "Idle"
                HashRate = 0
                Benchmarked = 0
                Hashrate_Gathered = ($_.HashRates.PSObject.Properties.Value -ne $null)
            }
        }
    }
    #Stop or start miners in the active list depending on if they are the most profitable
    # We have to stop processes first or the port would be busy
    $ActiveMinerPrograms | ForEach {
        [Array]$filtered = ($BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments)
        if($filtered.Count -eq 0)
        {
            if($_.Process -eq $null)
            {
                $_.Status = "Failed"
            }
            elseif($_.Process.HasExited -eq $false)
            {
            $_.Active += (Get-Date)-$_.Process.StartTime
               $_.Process.CloseMainWindow() | Out-Null
               Sleep 1
               # simply "Kill with power"
               Stop-Process $_.Process -Force | Out-Null
               Write-Host -ForegroundColor Yellow "closing current miner and switching"
               Sleep 1
               $_.Status = "Idle"
            }
            #Restore Bias for non-active miners
            $Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit_Bias_Orig}
        }
    }
    $newMiner = $false
    $CurrentMinerHashrate_Gathered =$false 
    $newMiner = $false
    $CurrentMinerHashrate_Gathered =$false 
    $ActiveMinerPrograms | ForEach {
        [Array]$filtered = ($BestMiners_Combo | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments)
        if($filtered.Count -gt 0)
        {
            if($_.Process -eq $null -or $_.Process.HasExited -ne $false)
            {
                Sleep $Delay #Wait to prevent BSOD
                $DecayStart = Get-Date
                $_.New = $true
                $_.Activated++
                if($_.Process -ne $null){$_.Active += $_.Process.ExitTime-$_.Process.StartTime}
                if($_.Wrap){$_.Process = Start-Process -FilePath "PowerShell" -ArgumentList "-executionpolicy bypass -command . '$(Convert-Path ".\Wrapper.ps1")' -ControllerProcessID $PID -Id '$($_.Port)' -FilePath '$($_.Path)' -ArgumentList '$($_.Arguments)' -WorkingDirectory '$(Split-Path $_.Path)'" -PassThru}
                else{$_.Process = Start-SubProcess -FilePath $_.Path -ArgumentList $_.Arguments -WorkingDirectory (Split-Path $_.Path)}
                if($_.Process -eq $null){$_.Status = "Failed"}
                else {
                    $_.Status = "Running"
                    $newMiner = $true
                    #Newely started miner should looks better than other in the first run too
                    $Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit * (1 + $ActiveMinerGainPct / 100)}
                    $newMiner = $true
                    #Newely started miner should looks better than other in the first run too
                    $Miners | Where Path -EQ $_.Path | Where Arguments -EQ $_.Arguments | ForEach {$_.Profit_Bias = $_.Profit * (1 + $ActiveMinerGainPct / 100)}
                }
            }
            $CurrentMinerHashrate_Gathered = $_.Hashrate_Gathered
        }
    }
    #Display mining information
    Clear-Host
    [Array] $processesIdle = $ActiveMinerPrograms | Where { $_.Status -eq "Idle" }
    if ($processesIdle.Count -gt 0) {
        Write-Host "Idle: " $processesIdle.Count
        $processesIdle | Sort {if($_.Process -eq $null){(Get-Date)}else{$_.Process.ExitTime}} | Format-Table -Wrap (
            @{Label = "Speed"; Expression={$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align='right'}, 
            @{Label = "Exited"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){(0)}else{(Get-Date) - $_.Process.ExitTime}) }},
            @{Label = "Active"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){$_.Active}else{if($_.Process.ExitTime -gt $_.Process.StartTime){($_.Active+($_.Process.ExitTime-$_.Process.StartTime))}else{($_.Active+((Get-Date)-$_.Process.StartTime))}})}}, 
            @{Label = "Cnt"; Expression={Switch($_.Activated){0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
            @{Label = "Command"; Expression={"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
        ) | Out-Host
    }
    Write-Host "1BTC = " $Rates.$Currency "$Currency"
    $Miners | Sort -Descending Type,Profit | Format-Table -GroupBy Type (
    @{Label = "Miner"; Expression={$_.Name}}, 
    @{Label = "Algorithm"; Expression={$_.HashRates.PSObject.Properties.Name}}, 
    @{Label = "Speed"; Expression={$_.HashRates.PSObject.Properties.Value | ForEach {if($_ -ne $null){"$($_ | ConvertTo-Hash)/s"}else{"Benchmarking"}}}; Align='right'}, 
    @{Label = "mBTC/Day"; Expression={$_.Profits.PSObject.Properties.Value*1000 | ForEach {if($_ -ne $null){$_.ToString("N3")}else{"Benchmarking"}}}; Align='right'}, 
    @{Label = "BTC/Day"; Expression={$_.Profits.PSObject.Properties.Value | ForEach {if($_ -ne $null){$_.ToString("N5")}else{"Benchmarking"}}}; Align='right'}, 
    @{Label = "$Currency/Day"; Expression={$_.Profits.PSObject.Properties.Value | ForEach {if($_ -ne $null){($_ * $Rates.$Currency).ToString("N3")}else{"Benchmarking"}}}; Align='right'}, 
    @{Label = "BTC/GH/Day"; Expression={$_.Pools.PSObject.Properties.Value.Price | ForEach {($_*1000000000).ToString("N5")}}; Align='right'},
    @{Label = "Pool"; Expression={$_.Pools.PSObject.Properties.Value | ForEach {"$($_.Name)-$($_.Info)"}}}
    ) | Out-Host
        #Display active miners list
    [Array] $processRunning = $ActiveMinerPrograms | Where { $_.Status -eq "Running" }
    Write-Host "Running:"
    $processRunning | Sort {if($_.Process -eq $null){[DateTime]0}else{$_.Process.StartTime}} | Select -First (1) | Format-Table -Wrap (
        @{Label = "Speed"; Expression={$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align='right'}, 
        @{Label = "Started"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){(0)}else{(Get-Date) - $_.Process.StartTime}) }},
        @{Label = "Active"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){$_.Active}else{if($_.Process.ExitTime -gt $_.Process.StartTime){($_.Active+($_.Process.ExitTime-$_.Process.StartTime))}else{($_.Active+((Get-Date)-$_.Process.StartTime))}})}}, 
        @{Label = "Cnt"; Expression={Switch($_.Activated){0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
        @{Label = "Command"; Expression={"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
    ) | Out-Host
    [Array] $processesFailed = $ActiveMinerPrograms | Where { $_.Status -eq "Failed" }
    if ($processesFailed.Count -gt 0) {
        Write-Host -ForegroundColor Red "Failed: " $processesFailed.Count
        $processesFailed | Sort {if($_.Process -eq $null){[DateTime]0}else{$_.Process.StartTime}} | Format-Table -Wrap (
            @{Label = "Speed"; Expression={$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align='right'}, 
            @{Label = "Exited"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){(0)}else{(Get-Date) - $_.Process.ExitTime}) }},
            @{Label = "Active"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){$_.Active}else{if($_.Process.ExitTime -gt $_.Process.StartTime){($_.Active+($_.Process.ExitTime-$_.Process.StartTime))}else{($_.Active+((Get-Date)-$_.Process.StartTime))}})}}, 
            @{Label = "Cnt"; Expression={Switch($_.Activated){0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
            @{Label = "Command"; Expression={"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
        ) | Out-Host
    }
    Write-Host "--------------------------------------------------------------------------------"
    Write-Host -ForegroundColor Yellow "Last Refresh: $(Get-Date)"
    #Do nothing for a few seconds as to not overload the APIs
    if ($newMiner -eq $true) {
        if ($Interval -ge $FirstInterval -and $Interval -ge $StatsInterval) { $timeToSleep = $Interval }
        else {
            if ($CurrentMinerHashrate_Gathered -eq $true) { $timeToSleep = $FirstInterval }
            else { $timeToSleep =  $StatsInterval }
        }
    } else {
        $timeToSleep = $Interval
    }
    Write-Host "Sleep" $timeToSleep "sec"
    Sleep $timeToSleep
    Write-Host "--------------------------------------------------------------------------------"
    #Display active miners list
    [Array] $processRunning = $ActiveMinerPrograms | Where { $_.Status -eq "Running" }
    Write-Host "Running:"
    $processRunning | Sort {if($_.Process -eq $null){[DateTime]0}else{$_.Process.StartTime}} | Select -First (1) | Format-Table -Wrap (
        @{Label = "Speed"; Expression={$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align='right'}, 
        @{Label = "Started"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){(0)}else{(Get-Date) - $_.Process.StartTime}) }},
        @{Label = "Active"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){$_.Active}else{if($_.Process.ExitTime -gt $_.Process.StartTime){($_.Active+($_.Process.ExitTime-$_.Process.StartTime))}else{($_.Active+((Get-Date)-$_.Process.StartTime))}})}}, 
        @{Label = "Cnt"; Expression={Switch($_.Activated){0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
        @{Label = "Command"; Expression={"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
    ) | Out-Host
    [Array] $processesFailed = $ActiveMinerPrograms | Where { $_.Status -eq "Failed" }
    if ($processesFailed.Count -gt 0) {
        Write-Host -ForegroundColor Red "Failed: " $processesFailed.Count
        $processesFailed | Sort {if($_.Process -eq $null){[DateTime]0}else{$_.Process.StartTime}} | Format-Table -Wrap (
            @{Label = "Speed"; Expression={$_.HashRate | ForEach {"$($_ | ConvertTo-Hash)/s"}}; Align='right'}, 
            @{Label = "Exited"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){(0)}else{(Get-Date) - $_.Process.ExitTime}) }},
            @{Label = "Active"; Expression={"{0:dd}:{0:hh}:{0:mm}" -f $(if($_.Process -eq $null){$_.Active}else{if($_.Process.ExitTime -gt $_.Process.StartTime){($_.Active+($_.Process.ExitTime-$_.Process.StartTime))}else{($_.Active+((Get-Date)-$_.Process.StartTime))}})}}, 
            @{Label = "Cnt"; Expression={Switch($_.Activated){0 {"Never"} 1 {"Once"} Default {"$_"}}}}, 
            @{Label = "Command"; Expression={"$($_.Path.TrimStart((Convert-Path ".\"))) $($_.Arguments)"}}
        ) | Out-Host
    }
    Write-Host "--------------------------------------------------------------------------------"
    Write-Host -ForegroundColor Yellow "Last Refresh: $(Get-Date)"
    #Do nothing for a few seconds as to not overload the APIs
    if ($newMiner -eq $true) {
        if ($Interval -ge $FirstInterval -and $Interval -ge $StatsInterval) { $timeToSleep = $Interval }
        else {
            if ($CurrentMinerHashrate_Gathered -eq $true) { $timeToSleep = $FirstInterval }
            else { $timeToSleep =  $StatsInterval }
        }
    } else {
    $timeToSleep = $Interval
    }
    Write-Host "Sleep" $timeToSleep "sec"
    Sleep $timeToSleep
    Write-Host "--------------------------------------------------------------------------------"
    #Save current hash rates
    $ActiveMinerPrograms | ForEach {
        if($_.Process -eq $null -or $_.Process.HasExited)
        {
            if($_.Status -eq "Running"){$_.Status = "Failed"}
        }
        else
        {
            # we don't want to store hashrates if we run less than $StatsInterval sec
            $WasActive = [math]::Round(((Get-Date)-$_.Process.StartTime).TotalSeconds)
            if ($WasActive -ge $StatsInterval) {
                $_.HashRate = 0
                $Miner_HashRates = $null
                if($_.New){$_.Benchmarked++}         
                $Miner_HashRates = Get-HashRate $_.API $_.Port ($_.New -and $_.Benchmarked -lt 3)
                $_.HashRate = $Miner_HashRates | Select -First $_.Algorithms.Count           
                if($Miner_HashRates.Count -ge $_.Algorithms.Count)
                {
                    for($i = 0; $i -lt $_.Algorithms.Count; $i++)
                    {
                        $Stat = Set-Stat -Name "$($_.Name)_$($_.Algorithms | Select -Index $i)_HashRate" -Value ($Miner_HashRates | Select -Index $i)
                    }
                    $_.New = $false
                    $_.Hashrate_Gathered = $true
                    Write-Host "Stats '"$_.Algorithms"' -> "($Miner_HashRates | ConvertTo-Hash)"after"$WasActive" sec"
                    Write-Host "--------------------------------------------------------------------------------"
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
}
#Stop the log
Stop-Transcript
