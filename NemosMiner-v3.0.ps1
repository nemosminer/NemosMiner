param(
    [Parameter(Mandatory = $false)]
    [String]$Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE", 
    [Parameter(Mandatory = $false)]
    [String]$UserName = "nemo", 
    [Parameter(Mandatory = $false)]
    [String]$WorkerName = "ID=NemosMiner-v3.0", 
    [Parameter(Mandatory = $false)]
    [Int]$API_ID = 0, 
    [Parameter(Mandatory = $false)]
    [String]$API_Key = "", 
    [Parameter(Mandatory = $false)]
    [Int]$Interval = 180, #seconds before between cycles after the first has passed 
    [Parameter(Mandatory = $false)]
    [Int]$FirstInterval = 30, #seconds of the first cycle of activated or started first time miner
    [Parameter(Mandatory = $false)]
    [Int]$StatsInterval = 300, #seconds of current active to gather hashrate if not gathered yet
    [Parameter(Mandatory = $false)]
    [String]$Location = "US", #europe/us/asia
    [Parameter(Mandatory = $false)]
    [Switch]$SSL = $false, 
    [Parameter(Mandatory = $false)]
    [Array]$Type = "nvidia", #AMD/NVIDIA/CPU
    [Parameter(Mandatory = $false)]
    [String]$SelGPUDSTM = "0 1",
    [Parameter(Mandatory = $false)]
    [String]$SelGPUCC = "0,1",
    [Parameter(Mandatory = $false)]
    [Array]$Algorithm = $null, #i.e. Ethash,Equihash,Cryptonight ect.
    [Parameter(Mandatory = $false)]
    [Array]$MinerName = $null, 
    [Parameter(Mandatory = $false)]
    [Array]$PoolName = $null, 
    [Parameter(Mandatory = $false)]
    [Array]$Currency = ("USD"), #i.e. GBP,USD,AUD,NZD ect.
    [Parameter(Mandatory = $false)]
    [Array]$Passwordcurrency = ("BTC"), #i.e. BTC,LTC,ZEC,ETH ect.
    [Parameter(Mandatory = $false)]
    [Int]$Donate = 5, #Minutes per Day
    [Parameter(Mandatory = $false)]
    [String]$Proxy = "", #i.e http://192.0.0.1:8080 
    [Parameter(Mandatory = $false)]
    [Int]$Delay = 1, #seconds before opening each miner
    [Parameter(Mandatory = $false)]
    [Int]$GPUCount = 1, # Number of GPU on the system
    [Parameter(Mandatory = $false)]
    [Int]$ActiveMinerGainPct = 5, # percent of advantage that active miner has over candidates in term of profit
    [Parameter(Mandatory = $false)]
    [Float]$MarginOfError = 0.4, # knowledge about the past wont help us to predict the future so don't pretend that Week_Fluctuation means something real
    [Parameter(Mandatory = $false)]
    [String]$UIStyle = "Full", # Light or Full. Defines level of info displayed
    [Parameter(Mandatory = $false)]
    [Bool]$TrackEarnings = $True, # Display earnings information
    [Parameter(Mandatory = $false)]
    [String]$ConfigFile = ".\Config\config.json"
)


. .\Include.ps1
. .\Core-v3.0.ps1

Function TimerCycle_Tick() {
    $LabelStatus.Text = ""
    $MainForm.Number += 1
    $timerCycle.Interval = $Config.Interval
    $MainForm.Text = $Variables.CurrentProduct + " " + $Variables.CurrentVersion + " Runtime " + ("{0:dd\ \d\a\y\s\ hh\:mm}" -f ((get-date) - $Variables.ScriptStartDate)) + " Path: " + (Split-Path $script:MyInvocation.MyCommand.Path)
    NPMCycle
    If (Test-Path ".\Logs\switching.log") {$log = Import-Csv ".\Logs\switching.log" | Select -Last 8}
    $SwitchingArray = [System.Collections.ArrayList]@($Log)
    $SwitchingDGV.DataSource = $SwitchingArray

    If ($Variables.Earnings -and $Config.TrackEarnings) {
        $DisplayEarnings = [System.Collections.ArrayList]@($Variables.Earnings.Values | select @(
                @{Name = "Pool"; Expression = {$_.Pool}},
                @{Name = "Trust Level"; Expression = {"{0:P0}" -f $_.TrustLevel}},
                @{Name = "Wallet"; Expression = {$_.Wallet}},
                @{Name = "Balance"; Expression = {$_.Balance}},
                @{Name = "BTC/D"; Expression = {"{0:N8}" -f ($_.AvgDailyGrowth)}},
                @{Name = "mBTC/D"; Expression = {"{0:N3}" -f ($_.AvgDailyGrowth * 1000)}},
                @{Name = "Estimated Pay Date"; Expression = {$_.EstimatedPayDate}},
                @{Name = "PaymentThreshold"; Expression = {$_.PaymentThreshold}}
            ) | Sort "BTC/D" -Descending)
        $EarningsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEarnings)
        $EarningsDGV.ClearSelection()
    }

    $DisplayEstimations = [System.Collections.ArrayList]@($Variables.Miners | Select @(
            @{Name = "Miner"; Expression = {$_.Name}},
            @{Name = "Algorithm"; Expression = {$_.HashRates.PSObject.Properties.Name}},
            @{Name = "Speed"; Expression = {$_.HashRates.PSObject.Properties.Value | ForEach {if ($_ -ne $null) {"$($_ | ConvertTo-Hash)/s"}else {"Benchmarking"}}}},
            @{Name = "mBTC/Day"; Expression = {$_.Profits.PSObject.Properties.Value * 1000 | ForEach {if ($_ -ne $null) {$_.ToString("N3")}else {"Benchmarking"}}}},
            @{Name = "BTC/Day"; Expression = {$_.Profits.PSObject.Properties.Value | ForEach {if ($_ -ne $null) {$_.ToString("N5")}else {"Benchmarking"}}}},
            @{Name = "BTC/GH/Day"; Expression = {$_.Pools.PSObject.Properties.Value.Price | ForEach {($_ * 1000000000).ToString("N5")}}},
            @{Name = "Pool"; Expression = {$_.Pools.PSObject.Properties.Value | ForEach {"$($_.Name)-$($_.Info)"}}}
        ) | sort "mBTC/Day" -Descending)
    $EstimationsDGV.DataSource = [System.Collections.ArrayList]@($DisplayEstimations)
    $EstimationsDGV.ClearSelection()

    $SwitchingDGV.ClearSelection()
	
    If ($Variables.Earnings.Values -ne $Null) {
        $LabelBTCD.Text = ("{0:N8}" -f ($Variables.Earnings.Values | measure -Property AvgDailyGrowth -Sum).sum) + " BTC/D   |   " + ("{0:N3}" -f (($Variables.Earnings.Values | measure -Property AvgDailyGrowth -Sum).sum * 1000)) + " mBTC/D"
    }
    else {
        $LabelBTCD.Text = "Waiting data from pools."
    }
	
    [Array] $processRunning = $Variables.ActiveMinerPrograms | Where { $_.Status -eq "Running" }
    If ($ProcessRunning -ne $null) {
        $LabelRunning.ForeColor = "Green"
        $processRunning = $processRunning | Sort {if ($_.Process -eq $null) {[DateTime]0}else {$_.Process.StartTime}} | Select -First (1)
        $LabelRunning.Text = "Mining $($processRunning.Algorithms) at $($processRunning.HashRate | ConvertTo-Hash)/s on $($processRunning.Arguments.Split(" ") | ?{$_ -match "stratum"})"
    }
    else {
        $LabelRunning.ForeColor = "Red"
        $LabelRunning.Text = "No miner running"
    }
    $LabelBTCPrice.text = If ($Variables.Rates.$Currency -gt 0) {"BTC/$($Config.Currency) $($Variables.Rates.($Config.Currency))"}
	
    $MainForm.Refresh
}
Function Form_Load {
    $MainForm.Text = "$($Variables.CurrentProduct) $($Variables.CurrentVersion)"
    $LabelBTCD.Text = "$($Variables.CurrentProduct) $($Variables.CurrentVersion)"
    $timerCycle.Interval = 1000
    $MainForm.Number = 0
    $timerCycle.Stop()
}

Function CheckBox_Click ($Control) {
    If ($Control.Checked) {[Array]$Config.($Control.Tag.Name) += $Control.Tag.Value} else {$Config.($Control.Tag.Name) = $Config.($Control.Tag.Name) | ? {$_ -ne $Control.Tag.Value}}
    $Config.($Control.Tag.Name) = $Config.($Control.Tag.Name) | select -Unique
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

If (Test-Path ".\Logs\switching.log") {$log = Import-Csv ".\Logs\switching.log" | Select -Last 8}
$SwitchingArray = [System.Collections.ArrayList]@($Log)

$MainForm = New-Object system.Windows.Forms.Form
$NPMIcon = New-Object system.drawing.icon (".\NPM.ICO")
$MainForm.Icon = $NPMIcon
$MainForm.ClientSize = '740,450' # best to keep under 800,600
$MainForm.text = "Form"
$MainForm.TopMost = $false
$MainForm.FormBorderStyle = 'Fixed3D'
$MainForm.MaximizeBox = $false

$MainForm.add_Shown( {
        # Check if new version is available
        Update-Status("Checking version")
        try {
            $Version = Invoke-WebRequest "http://nemosminer.x10host.com/version.json" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json
        }
        catch {$Version = Get-content ".\Config\version.json" | Convertfrom-json}
        If ($Version -ne $null) {$Version | ConvertTo-json | Out-File ".\Config\version.json"}
        If ($Version.Product -eq $Variables.CurrentProduct -and [Version]$version.Version -gt $Variables.CurrentVersion -and $Version.Update) {
            Update-Status("Version $($version.Version) available. (You are running $Variables.CurrentVersion)")
            $LabelNewVersion.ForeColor = "Green"
            $LabelNewVersion.Text = "Version $([Version]$version.Version) available"
        }
	
        # TimerCheckVersion
        $TimerCheckVersion = New-Object System.Windows.Forms.Timer
        $TimerCheckVersion.Enabled = $true
        $TimerCheckVersion.Interval = 1440 * 60 * 1000
        $TimerCheckVersion.Add_Tick( {
                Update-Status("Checking version")
                try {
                    $Version = Invoke-WebRequest "http://nemosminer.x10host.com/version.json" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json
                }
                catch {$Version = Get-content ".\Config\version.json" | Convertfrom-json}
                If ($Version -ne $null) {$Version | ConvertTo-json | Out-File ".\Config\version.json"}
                If ($Version.Product -eq $Variables.CurrentProduct -and [Version]$version.Version -gt $Variables.CurrentVersion -and $Version.Update) {
                    Update-Status("Version $($version.Version) available. (You are running $Variables.CurrentVersion)")
                    $LabelNewVersion.ForeColor = "Green"
                    $LabelNewVersion.Text = "Version $([Version]$version.Version) available"
                }
            })
        # Detects GPU count if 0 or Null in config
        If ($Config.GPUCount -eq $null -or $Config.GPUCount -lt 1) {
            If ($Config -eq $null) {$Config = [PSCustomObject]@{}
            }
            $Config | Add-Member -Force @{GPUCount = DetectGPUCount}
            $TBGPUCount.Text = $Config.GPUCount
            Write-Config -ConfigFile $ConfigFile -Config $Config
        }
        # Start on load if Autostart
        If ($Config.Autostart) {$ButtonStart.PerformClick()}
    })

$MainForm.Add_FormClosing( {
        Get-Job | Stop-Job | Remove-Job
        If ($Variables.ActiveMinerPrograms) {
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
                        Write-Host -ForegroundColor Yellow "closing miner"
                        Sleep 1
                        $_.Status = "Idle"
                    }
                }
            }
        }
    })

$Config = Load-Config -ConfigFile $ConfigFile

$Config | Add-Member -Force -MemberType ScriptProperty -Name "PoolsConfig" -Value {
    If (Test-Path ".\Config\PoolsConfig.json") {
        get-content ".\Config\PoolsConfig.json" | ConvertFrom-json
    }
    else {
        [PSCustomObject]@{default = [PSCustomObject]@{
                Wallet = "1QGADhdMRpp9Pk5u5zG1TrHKRrdK5R81TE"
                UserName = "nemo"
                WorkerName = "NemosMiner"
                PricePenaltyFactor = 1
            }
        }
    }
}

$MainForm | Add-Member -Name "Config" -Value $Config -MemberType NoteProperty -Force

$SelGPUDSTM = $Config.SelGPUDSTM
$SelGPUCC = $Config.SelGPUCC
$Variables = [PSCustomObject]@{}
$MainForm | Add-Member -Name "Variables" -Value $Variables -MemberType NoteProperty -Force
$Variables | Add-Member -Force @{CurrentProduct = "NemosMiner"}
$Variables | Add-Member -Force @{CurrentVersion = [Version]"3.0"}
$Variables | Add-Member -Force @{StatusText = "Idle"}

$TabControl = New-object System.Windows.Forms.TabControl
$RunPage = New-Object System.Windows.Forms.TabPage
$RunPage.Text = "Run"
$ConfigPage = New-Object System.Windows.Forms.TabPage
$ConfigPage.Text = "Config"
$EstimationsPage = New-Object System.Windows.Forms.TabPage
$EstimationsPage.Text = "Benchmarks"

$tabControl.DataBindings.DefaultDataSourceUpdateMode = 0
$tabControl.Location = New-Object System.Drawing.Point(10, 91)
$tabControl.Name = "tabControl"
$tabControl.width = 720
$tabControl.height = 359
$MainForm.Controls.Add($tabControl)
$TabControl.Controls.AddRange(@($RunPage, $ConfigPage, $EstimationsPage))

# Form Controls
$MainFormControls = @()

$LabelStatus = New-Object system.Windows.Forms.TextBox
$LabelStatus.MultiLine = $true
$LabelStatus.Scrollbars = "Vertical" 
$LabelStatus.text = ""
$LabelStatus.AutoSize = $true
$LabelStatus.width = 400
$LabelStatus.height = 50
$LabelStatus.location = New-Object System.Drawing.Point(10, 39)
$LabelStatus.Font = 'Microsoft Sans Serif,10'
$MainFormControls += $LabelStatus

$LabelRunning = New-Object system.Windows.Forms.Label
$LabelRunning.text = ""
$LabelRunning.AutoSize = $False
$LabelRunning.width = 360
$LabelRunning.height = 35
$LabelRunning.location = New-Object System.Drawing.Point(10, 2)
$LabelRunning.Font = 'Microsoft Sans Serif,10'
$LabelRunning.TextAlign = "MiddleLeft"
$LabelRunning.ForeColor = "Green"
$MainFormControls += $LabelRunning

$LabelBTCD = New-Object system.Windows.Forms.Label
$LabelBTCD.text = "BTC/D"
$LabelBTCD.AutoSize = $False
$LabelBTCD.width = 360
$LabelBTCD.height = 35
$LabelBTCD.location = New-Object System.Drawing.Point(370, 2)
$LabelBTCD.Font = 'Microsoft Sans Serif,14'
$LabelBTCD.TextAlign = "MiddleRight"
$LabelBTCD.ForeColor = "Green"
$MainFormControls += $LabelBTCD

$LabelBTCPrice = New-Object system.Windows.Forms.Label
$LabelBTCPrice.text = If ($Variables.Rates.$Currency -gt 0) {"BTC/$($Config.Currency) $($Variables.Rates.$Currency)"}
$LabelBTCPrice.AutoSize = $false
$LabelBTCPrice.width = 400
$LabelBTCPrice.height = 20
$LabelBTCPrice.location = New-Object System.Drawing.Point(630, 39)
$LabelBTCPrice.Font = 'Microsoft Sans Serif,8'
# $LabelBTCPrice.ForeColor				= "Gray"
$MainFormControls += $LabelBTCPrice

$ButtonStart = New-Object system.Windows.Forms.Button
$ButtonStart.text = "Start"
$ButtonStart.width = 60
$ButtonStart.height = 30
$ButtonStart.location = New-Object System.Drawing.Point(670, 62)
$ButtonStart.Font = 'Microsoft Sans Serif,10'
$MainFormControls += $ButtonStart

$LabelNewVersion = New-Object system.Windows.Forms.Label
$LabelNewVersion.text = If ($ConfigFile -ne ".\Config\config.json") {"Using: $($ConfigFile | Split-Path -Leaf)"}
$LabelNewVersion.AutoSize = $false
$LabelNewVersion.width = 200
$LabelNewVersion.height = 20
# $LabelNewVersion.location                 = New-Object System.Drawing.Point(200,91)
$LabelNewVersion.location = New-Object System.Drawing.Point(415, 39)
$LabelNewVersion.Font = 'Microsoft Sans Serif,10'
$LabelNewVersion.ForeColor = "Gray"
$MainFormControls += $LabelNewVersion

$LabelGitHub = New-Object System.Windows.Forms.LinkLabel
$LabelGitHub.Location = New-Object System.Drawing.Size(415, 62)
$LabelGitHub.Size = New-Object System.Drawing.Size(160, 20)
$LabelGitHub.LinkColor = "BLUE"
$LabelGitHub.ActiveLinkColor = "RED"
$LabelGitHub.Text = "NemosMiner on GitHub"
$LabelGitHub.add_Click( {[system.Diagnostics.Process]::start("https://github.com/nemosminer/NemosMiner-v3.0-windows/releases")})
$MainFormControls += $LabelGitHub

# Run Page Controls
$EarningsDGV = New-Object system.Windows.Forms.DataGridView
$EarningsDGV.width = 712
$EarningsDGV.height = 120
$EarningsDGV.location = New-Object System.Drawing.Point(2, 2)
$EarningsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EarningsDGV.AutoSizeColumnsMode = "Fill"
$EarningsDGV.RowHeadersVisible = $False


$SwitchingDGV = New-Object system.Windows.Forms.DataGridView
$SwitchingDGV.width = 712
$SwitchingDGV.height = 250
$SwitchingDGV.location = New-Object System.Drawing.Point(2, 124)
$SwitchingDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$SwitchingDGV.AutoSizeColumnsMode = "Fill"
$SwitchingDGV.RowHeadersVisible = $False
$SwitchingDGV.DataSource = $SwitchingArray

# Estimations Page Controls
$EstimationsDGV = New-Object system.Windows.Forms.DataGridView
$EstimationsDGV.width = 712
$EstimationsDGV.height = 350
$EstimationsDGV.location = New-Object System.Drawing.Point(2, 2)
$EstimationsDGV.DataBindings.DefaultDataSourceUpdateMode = 0
$EstimationsDGV.AutoSizeColumnsMode = "Fill"
$EstimationsDGV.RowHeadersVisible = $False

# Config Page Controls
$ConfigPageControls = @()
	
$LabelAddress = New-Object system.Windows.Forms.Label
$LabelAddress.text = "Wallet address"
$LabelAddress.AutoSize = $false
$LabelAddress.width = 120
$LabelAddress.height = 20
$LabelAddress.location = New-Object System.Drawing.Point(2, 2)
$LabelAddress.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelAddress

$TBAddress = New-Object system.Windows.Forms.TextBox
$TBAddress.Tag = "Wallet"
$TBAddress.MultiLine = $False
# $TBAddress.Scrollbars				= "Vertical" 
$TBAddress.text = $Config.Wallet
$TBAddress.AutoSize = $false
$TBAddress.width = 300
$TBAddress.height = 20
$TBAddress.location = New-Object System.Drawing.Point(122, 2)
$TBAddress.Font = 'Microsoft Sans Serif,10'
# $TBAddress.TextAlign                = "Right"
$ConfigPageControls += $TBAddress

$LabelUserName = New-Object system.Windows.Forms.Label
$LabelUserName.text = "MPH UserName"
$LabelUserName.AutoSize = $false
$LabelUserName.width = 120
$LabelUserName.height = 20
$LabelUserName.location = New-Object System.Drawing.Point(2, 24)
$LabelUserName.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelUserName

$TBUserName = New-Object system.Windows.Forms.TextBox
$TBUserName.Tag = "UserName"
$TBUserName.MultiLine = $False
# $TBUserName.Scrollbars				= "Vertical" 
$TBUserName.text = $Config.UserName
$TBUserName.AutoSize = $false
$TBUserName.width = 300
$TBUserName.height = 20
$TBUserName.location = New-Object System.Drawing.Point(122, 24)
$TBUserName.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBUserName

$LabelWorkerName = New-Object system.Windows.Forms.Label
$LabelWorkerName.text = "Worker Name"
$LabelWorkerName.AutoSize = $false
$LabelWorkerName.width = 120
$LabelWorkerName.height = 20
$LabelWorkerName.location = New-Object System.Drawing.Point(2, 46)
$LabelWorkerName.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelWorkerName

$TBWorkerName = New-Object system.Windows.Forms.TextBox
$TBWorkerName.Tag = "WorkerName"
$TBWorkerName.MultiLine = $False
# $TBWorkerName.Scrollbars				= "Vertical" 
$TBWorkerName.text = $Config.WorkerName
$TBWorkerName.AutoSize = $false
$TBWorkerName.width = 300
$TBWorkerName.height = 20
$TBWorkerName.location = New-Object System.Drawing.Point(122, 46)
$TBWorkerName.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBWorkerName

$LabelInterval = New-Object system.Windows.Forms.Label
$LabelInterval.text = "Interval"
$LabelInterval.AutoSize = $false
$LabelInterval.width = 120
$LabelInterval.height = 20
$LabelInterval.location = New-Object System.Drawing.Point(2, 68)
$LabelInterval.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelInterval

$TBInterval = New-Object system.Windows.Forms.TextBox
$TBInterval.Tag = "Interval"
$TBInterval.MultiLine = $False
# $TBWorkerName.Scrollbars				= "Vertical" 
$TBInterval.text = $Config.Interval
$TBInterval.AutoSize = $false
$TBInterval.width = 300
$TBInterval.height = 20
$TBInterval.location = New-Object System.Drawing.Point(122, 68)
$TBInterval.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBInterval

$LabelLocation = New-Object system.Windows.Forms.Label
$LabelLocation.text = "Location"
$LabelLocation.AutoSize = $false
$LabelLocation.width = 120
$LabelLocation.height = 20
$LabelLocation.location = New-Object System.Drawing.Point(2, 90)
$LabelLocation.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelLocation

$TBLocation = New-Object system.Windows.Forms.TextBox
$TBLocation.Tag = "Location"
$TBLocation.MultiLine = $False
# $TBLocation.Scrollbars				= "Vertical" 
$TBLocation.text = $Config.Location
$TBLocation.AutoSize = $false
$TBLocation.width = 300
$TBLocation.height = 20
$TBLocation.location = New-Object System.Drawing.Point(122, 90)
$TBLocation.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBLocation

$LabelGPUCount = New-Object system.Windows.Forms.Label
$LabelGPUCount.text = "GPU Count"
$LabelGPUCount.AutoSize = $false
$LabelGPUCount.width = 120
$LabelGPUCount.height = 20
$LabelGPUCount.location = New-Object System.Drawing.Point(2, 112)
$LabelGPUCount.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelGPUCount

$TBGPUCount = New-Object system.Windows.Forms.TextBox
$TBGPUCount.Tag = "GPUCount"
$TBGPUCount.MultiLine = $False
# $TBGPUCount.Scrollbars				= "Vertical" 
$TBGPUCount.text = $Config.GPUCount
$TBGPUCount.AutoSize = $false
$TBGPUCount.width = 50
$TBGPUCount.height = 20
$TBGPUCount.location = New-Object System.Drawing.Point(122, 112)
$TBGPUCount.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBGPUCount

$CheckBoxDisableGPU0 = New-Object system.Windows.Forms.CheckBox
$CheckBoxDisableGPU0.Tag = "DisableGPU0"
$CheckBoxDisableGPU0.text = "Disable GPU0"
$CheckBoxDisableGPU0.AutoSize = $false
$CheckBoxDisableGPU0.width = 140
$CheckBoxDisableGPU0.height = 20
$CheckBoxDisableGPU0.location = New-Object System.Drawing.Point(177, 112)
$CheckBoxDisableGPU0.Font = 'Microsoft Sans Serif,10'
$CheckBoxDisableGPU0.Checked =	$Config.DisableGPU0
$ConfigPageControls += $CheckBoxDisableGPU0
	
$ButtonDetectGPU = New-Object system.Windows.Forms.Button
$ButtonDetectGPU.text = "Detect GPU"
$ButtonDetectGPU.width = 100
$ButtonDetectGPU.height = 20
$ButtonDetectGPU.location = New-Object System.Drawing.Point(320, 112)
$ButtonDetectGPU.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $ButtonDetectGPU

$ButtonDetectGPU.Add_Click( {$TBGPUCount.text = DetectGPUCount})

$LabelAlgos = New-Object system.Windows.Forms.Label
$LabelAlgos.text = "Algorithm"
$LabelAlgos.AutoSize = $false
$LabelAlgos.width = 120
$LabelAlgos.height = 20
$LabelAlgos.location = New-Object System.Drawing.Point(2, 134)
$LabelAlgos.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelAlgos

$TBAlgos = New-Object system.Windows.Forms.TextBox
$TBAlgos.Tag = "Algorithm"
$TBAlgos.MultiLine = $False
# $TBAlgos.Scrollbars				= "Vertical" 
$TBAlgos.text = $Config.Algorithm -Join ","
$TBAlgos.AutoSize = $false
$TBAlgos.width = 300
$TBAlgos.height = 20
$TBAlgos.location = New-Object System.Drawing.Point(122, 134)
$TBAlgos.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBAlgos

$LabelCurrency = New-Object system.Windows.Forms.Label
$LabelCurrency.text = "Currency"
$LabelCurrency.AutoSize = $false
$LabelCurrency.width = 120
$LabelCurrency.height = 20
$LabelCurrency.location = New-Object System.Drawing.Point(2, 156)
$LabelCurrency.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelCurrency

$TBCurrency = New-Object system.Windows.Forms.TextBox
$TBCurrency.Tag = "Currency"
$TBCurrency.MultiLine = $False
# $TBCurrency.Scrollbars				= "Vertical" 
$TBCurrency.text = $Config.Currency
$TBCurrency.AutoSize = $false
$TBCurrency.width = 300
$TBCurrency.height = 20
$TBCurrency.location = New-Object System.Drawing.Point(122, 156)
$TBCurrency.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBCurrency

$LabelPwdCurrency = New-Object system.Windows.Forms.Label
$LabelPwdCurrency.text = "Pwd Currency"
$LabelPwdCurrency.AutoSize = $false
$LabelPwdCurrency.width = 120
$LabelPwdCurrency.height = 20
$LabelPwdCurrency.location = New-Object System.Drawing.Point(2, 178)
$LabelPwdCurrency.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelPwdCurrency

$TBPwdCurrency = New-Object system.Windows.Forms.TextBox
$TBPwdCurrency.Tag = "Passwordcurrency"
$TBPwdCurrency.MultiLine = $False
# $TBPwdCurrency.Scrollbars				= "Vertical" 
$TBPwdCurrency.text = $Config.Passwordcurrency
$TBPwdCurrency.AutoSize = $false
$TBPwdCurrency.width = 300
$TBPwdCurrency.height = 20
$TBPwdCurrency.location = New-Object System.Drawing.Point(122, 178)
$TBPwdCurrency.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBPwdCurrency

$LabelDonate = New-Object system.Windows.Forms.Label
$LabelDonate.text = "Donate (min)"
$LabelDonate.AutoSize = $false
$LabelDonate.width = 120
$LabelDonate.height = 20
$LabelDonate.location = New-Object System.Drawing.Point(2, 200)
$LabelDonate.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelDonate

$TBDonate = New-Object system.Windows.Forms.TextBox
$TBDonate.Tag = "Donate"
$TBDonate.MultiLine = $False
# $TBDonate.Scrollbars				= "Vertical" 
$TBDonate.text = $Config.Donate
$TBDonate.AutoSize = $false
$TBDonate.width = 300
$TBDonate.height = 20
$TBDonate.location = New-Object System.Drawing.Point(122, 200)
$TBDonate.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBDonate

$LabelProxy = New-Object system.Windows.Forms.Label
$LabelProxy.text = "Proxy"
$LabelProxy.AutoSize = $false
$LabelProxy.width = 120
$LabelProxy.height = 20
$LabelProxy.location = New-Object System.Drawing.Point(2, 222)
$LabelProxy.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelProxy

$TBProxy = New-Object system.Windows.Forms.TextBox
$TBProxy.Tag = "Proxy"
$TBProxy.MultiLine = $False
# $TBProxy.Scrollbars				= "Vertical" 
$TBProxy.text = $Config.Proxy
$TBProxy.AutoSize = $false
$TBProxy.width = 300
$TBProxy.height = 20
$TBProxy.location = New-Object System.Drawing.Point(122, 222)
$TBProxy.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBProxy

$LabelActiveMinerGainPct = New-Object system.Windows.Forms.Label
$LabelActiveMinerGainPct.text = "ActiveMinerGain%"
$LabelActiveMinerGainPct.AutoSize = $false
$LabelActiveMinerGainPct.width = 120
$LabelActiveMinerGainPct.height = 20
$LabelActiveMinerGainPct.location = New-Object System.Drawing.Point(2, 244)
$LabelActiveMinerGainPct.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $LabelActiveMinerGainPct

$TBActiveMinerGainPct = New-Object system.Windows.Forms.TextBox
$TBActiveMinerGainPct.Tag = "ActiveMinerGainPct"
$TBActiveMinerGainPct.MultiLine = $False
# $TBActiveMinerGainPct.Scrollbars				= "Vertical" 
$TBActiveMinerGainPct.text = $Config.ActiveMinerGainPct
$TBActiveMinerGainPct.AutoSize = $false
$TBActiveMinerGainPct.width = 300
$TBActiveMinerGainPct.height = 20
$TBActiveMinerGainPct.location = New-Object System.Drawing.Point(122, 244)
$TBActiveMinerGainPct.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $TBActiveMinerGainPct

$CheckBoxAutostart = New-Object system.Windows.Forms.CheckBox
$CheckBoxAutostart.Tag = "Autostart"
$CheckBoxAutostart.text = "Autostart"
$CheckBoxAutostart.AutoSize = $false
$CheckBoxAutostart.width = 100
$CheckBoxAutostart.height = 20
$CheckBoxAutostart.location = New-Object System.Drawing.Point(432, 224)
$CheckBoxAutostart.Font = 'Microsoft Sans Serif,10'
$CheckBoxAutostart.Checked =	$Config.Autostart
$ConfigPageControls += $CheckBoxAutostart
	
$ButtonLoadDefaultPoolsAlgos = New-Object system.Windows.Forms.Button
$ButtonLoadDefaultPoolsAlgos.text = "Load default algos for selected pools"
$ButtonLoadDefaultPoolsAlgos.width = 100
$ButtonLoadDefaultPoolsAlgos.height = 50
$ButtonLoadDefaultPoolsAlgos.location = New-Object System.Drawing.Point(577, 259)
$ButtonLoadDefaultPoolsAlgos.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $ButtonLoadDefaultPoolsAlgos
	
$ButtonLoadDefaultPoolsAlgos.Add_Click( {
        try {
            $PoolsAlgos = Invoke-WebRequest "http://nemosminer.x10host.com/PoolsAlgos.json" -UseBasicParsing -Headers @{"Cache-Control" = "no-cache"} | ConvertFrom-Json; $PoolsAlgos | ConvertTo-json | Out-File ".\Config\PoolsAlgos.json" 
        }
        catch { $PoolsAlgos = Get-content ".\Config\PoolsAlgos.json" | Convertfrom-json}
        If ($PoolsAlgos) {
            $PoolsAlgos = $PoolsAlgos.PSObject.Properties | ? {$_.Name -in $Config.PoolName}
            $PoolsAlgos = $PoolsAlgos.Value | sort -Unique
            $TBAlgos.text = $PoolsAlgos -Join ","
        }
    })
	
$ButtonWriteConfig = New-Object system.Windows.Forms.Button
$ButtonWriteConfig.text = "Save Config"
$ButtonWriteConfig.width = 100
$ButtonWriteConfig.height = 30
$ButtonWriteConfig.location = New-Object System.Drawing.Point(577, 224)
$ButtonWriteConfig.Font = 'Microsoft Sans Serif,10'
$ConfigPageControls += $ButtonWriteConfig

$ButtonWriteConfig.Add_Click( {
        If ($Config -eq $null) {$Config = [PSCustomObject]@{}
        }
        $ConfigPageControls | ? {(($_.gettype()).Name -eq "CheckBox")} | foreach {$Config | Add-Member -Force @{$_.Tag = $_.Checked}}
        $ConfigPageControls | ? {(($_.gettype()).Name -eq "TextBox")} | foreach {$Config | Add-Member -Force @{$_.Tag = $_.Text}}
        $ConfigPageControls | ? {(($_.gettype()).Name -eq "TextBox") -and ($_.Tag -eq "GPUCount")} | foreach {
            $Config | Add-Member -Force @{$_.Tag = [Int]$_.Text}
            If ($CheckBoxDisableGPU0.checked -and [Int]$_.Text -gt 1) {$FirstGPU = 1}else {$FirstGPU = 0}
            $Config | Add-Member -Force @{SelGPUCC = (($FirstGPU..($_.Text - 1)) -join ",")}
            $Config | Add-Member -Force @{SelGPUDSTM = (($FirstGPU..($_.Text - 1)) -join " ")}
        }
        $ConfigPageControls | ? {(($_.gettype()).Name -eq "TextBox") -and ($_.Tag -eq "Algorithm")} | foreach {
            $Config | Add-Member -Force @{$_.Tag = @($_.Text -split ",")}
        }
        $ConfigPageControls | ? {(($_.gettype()).Name -eq "TextBox") -and ($_.Tag -in @("Donate", "Interval", "ActiveMinerGainPct"))} | foreach {
            $Config | Add-Member -Force @{$_.Tag = [Int]$_.Text}
        }
        Write-Config -ConfigFile $ConfigFile -Config $Config
        $MainForm.Refresh
        # [windows.forms.messagebox]::show("Please restart NPlusMiner",'Config saved','ok','Information') | out-null
    }
)
	
# ***
$GroupboxPools = New-Object system.Windows.Forms.Groupbox
$GroupboxPools.height = 220
$GroupboxPools.width = 250
$GroupboxPools.text = "Pools"
$GroupboxPools.location = New-Object System.Drawing.Point(427, 2)
$ConfigPageControls += $GroupboxPools
$GroupboxPoolsControls = @()
	
$CheckBoxAhashpool = New-Object system.Windows.Forms.CheckBox
$CheckBoxAhashpool.Tag = @{name = "PoolName"; Value = "ahashpool"}
$CheckBoxAhashpool.text = "ahashpool"
$CheckBoxAhashpool.AutoSize = $false
$CheckBoxAhashpool.width = 100
$CheckBoxAhashpool.height = 20
$CheckBoxAhashpool.location = New-Object System.Drawing.Point(5, 15)
$CheckBoxAhashpool.Font = 'Microsoft Sans Serif,10'
$CheckBoxAhashpool.Checked =	$Config.PoolName -contains "ahashpool"
$GroupboxPoolsControls += $CheckBoxAhashpool
	
$CheckBoxAhashpoolplus = New-Object system.Windows.Forms.CheckBox
$CheckBoxAhashpoolplus.Tag = @{name = "PoolName"; Value = "ahashpoolplus"}
$CheckBoxAhashpoolplus.text = "Plus"
$CheckBoxAhashpoolplus.AutoSize = $false
$CheckBoxAhashpoolplus.width = 60
$CheckBoxAhashpoolplus.height = 20
$CheckBoxAhashpoolplus.location = New-Object System.Drawing.Point(110, 15)
$CheckBoxAhashpoolplus.Font = 'Microsoft Sans Serif,10'
$CheckBoxAhashpoolplus.Checked =	$Config.PoolName -contains "ahashpoolplus"
$GroupboxPoolsControls += $CheckBoxAhashpoolplus
	
$CheckBoxAhashpool24hr = New-Object system.Windows.Forms.CheckBox
$CheckBoxAhashpool24hr.Tag = @{name = "PoolName"; Value = "ahashpool24hr"}
$CheckBoxAhashpool24hr.text = "24hr"
$CheckBoxAhashpool24hr.AutoSize = $false
$CheckBoxAhashpool24hr.width = 60
$CheckBoxAhashpool24hr.height = 20
$CheckBoxAhashpool24hr.location = New-Object System.Drawing.Point(175, 15)
$CheckBoxAhashpool24hr.Font = 'Microsoft Sans Serif,10'
$CheckBoxAhashpool24hr.Checked =	$Config.PoolName -contains "ahashpool24hr"
$GroupboxPoolsControls += $CheckBoxAhashpool24hr
	
$CheckBoxBlazepool = New-Object system.Windows.Forms.CheckBox
$CheckBoxBlazepool.Tag = @{name = "PoolName"; Value = "blazepool"}
$CheckBoxBlazepool.text = "blazepool"
$CheckBoxBlazepool.AutoSize = $false
$CheckBoxBlazepool.width = 100
$CheckBoxBlazepool.height = 20
$CheckBoxBlazepool.location = New-Object System.Drawing.Point(5, 37)
$CheckBoxBlazepool.Font = 'Microsoft Sans Serif,10'
$CheckBoxBlazepool.Checked =	$Config.PoolName -contains "blazepool"
$GroupboxPoolsControls += $CheckBoxBlazepool

$CheckBoxBlazepoolplus = New-Object system.Windows.Forms.CheckBox
$CheckBoxBlazepoolplus.Tag = @{name = "PoolName"; Value = "blazepoolPlus"}
$CheckBoxBlazepoolplus.text = "Plus"
$CheckBoxBlazepoolplus.AutoSize = $false
$CheckBoxBlazepoolplus.width = 60
$CheckBoxBlazepoolplus.height = 20
$CheckBoxBlazepoolplus.location = New-Object System.Drawing.Point(110, 37)
$CheckBoxBlazepoolplus.Font = 'Microsoft Sans Serif,10'
$CheckBoxBlazepoolplus.Checked =	$Config.PoolName -contains "blazepoolPlus"
$GroupboxPoolsControls += $CheckBoxBlazepoolplus
	
$CheckBoxBlazepool24hr = New-Object system.Windows.Forms.CheckBox
$CheckBoxBlazepool24hr.Tag = @{name = "PoolName"; Value = "blazepool24hr"}
$CheckBoxBlazepool24hr.text = "24hr"
$CheckBoxBlazepool24hr.AutoSize = $false
$CheckBoxBlazepool24hr.width = 60
$CheckBoxBlazepool24hr.height = 20
$CheckBoxBlazepool24hr.location = New-Object System.Drawing.Point(175, 37)
$CheckBoxBlazepool24hr.Font = 'Microsoft Sans Serif,10'
$CheckBoxBlazepool24hr.Checked =	$Config.PoolName -contains "blazepool24hr"
$GroupboxPoolsControls += $CheckBoxBlazepool24hr

	
$CheckBoxHashRefinery = New-Object system.Windows.Forms.CheckBox
$CheckBoxHashRefinery.Tag = @{name = "PoolName"; Value = "hashrefinery"}
$CheckBoxHashRefinery.text = "hashrefinery"
$CheckBoxHashRefinery.AutoSize = $false
$CheckBoxHashRefinery.width = 100
$CheckBoxHashRefinery.height = 20
$CheckBoxHashRefinery.location = New-Object System.Drawing.Point(5, 59)
$CheckBoxHashRefinery.Font = 'Microsoft Sans Serif,10'
$CheckBoxHashRefinery.Checked =	$Config.PoolName -contains "hashrefinery"
$GroupboxPoolsControls += $CheckBoxHashRefinery
	
$CheckBoxMineMoney = New-Object system.Windows.Forms.CheckBox
$CheckBoxMineMoney.Tag = @{name = "PoolName"; Value = "minemoney"}
$CheckBoxMineMoney.text = "minemoney"
$CheckBoxMineMoney.AutoSize = $false
$CheckBoxMineMoney.width = 100
$CheckBoxMineMoney.height = 20
$CheckBoxMineMoney.location = New-Object System.Drawing.Point(5, 81)
$CheckBoxMineMoney.Font = 'Microsoft Sans Serif,10'
$CheckBoxMineMoney.Checked =	$Config.PoolName -contains "minemoney"
$GroupboxPoolsControls += $CheckBoxMineMoney
	
$CheckBoxMPH = New-Object system.Windows.Forms.CheckBox
$CheckBoxMPH.Tag = @{name = "PoolName"; Value = "miningpoolhub"}
$CheckBoxMPH.text = "miningpoolhub"
$CheckBoxMPH.AutoSize = $false
$CheckBoxMPH.width = 100
$CheckBoxMPH.height = 20
$CheckBoxMPH.location = New-Object System.Drawing.Point(5, 103)
$CheckBoxMPH.Font = 'Microsoft Sans Serif,10'
$CheckBoxMPH.Checked =	$Config.PoolName -contains "miningpoolhub"
$GroupboxPoolsControls += $CheckBoxMPH
	
$CheckBoxNH = New-Object system.Windows.Forms.CheckBox
$CheckBoxNH.Tag = @{name = "PoolName"; Value = "nicehash"}
$CheckBoxNH.text = "nicehash"
$CheckBoxNH.AutoSize = $false
$CheckBoxNH.width = 100
$CheckBoxNH.height = 20
$CheckBoxNH.location = New-Object System.Drawing.Point(5, 125)
$CheckBoxNH.Font = 'Microsoft Sans Serif,10'
$CheckBoxNH.Checked =	$Config.PoolName -contains "nicehash"
$GroupboxPoolsControls += $CheckBoxNH
	
$CheckBoxPhiphipool = New-Object system.Windows.Forms.CheckBox
$CheckBoxPhiphipool.Tag = @{name = "PoolName"; Value = "phiphipool"}
$CheckBoxPhiphipool.text = "phiphipool"
$CheckBoxPhiphipool.AutoSize = $false
$CheckBoxPhiphipool.width = 100
$CheckBoxPhiphipool.height = 20
$CheckBoxPhiphipool.location = New-Object System.Drawing.Point(5, 147)
$CheckBoxPhiphipool.Font = 'Microsoft Sans Serif,10'
$CheckBoxPhiphipool.Checked =	$Config.PoolName -contains "phiphipool"
$GroupboxPoolsControls += $CheckBoxPhiphipool

$CheckBoxPhiphipoolplus = New-Object system.Windows.Forms.CheckBox
$CheckBoxPhiphipoolplus.Tag = @{name = "PoolName"; Value = "phiphipoolplus"}
$CheckBoxPhiphipoolplus.text = "Plus"
$CheckBoxPhiphipoolplus.AutoSize = $false
$CheckBoxPhiphipoolplus.width = 60
$CheckBoxPhiphipoolplus.height = 20
$CheckBoxPhiphipoolplus.location = New-Object System.Drawing.Point(110, 147)
$CheckBoxPhiphipoolplus.Font = 'Microsoft Sans Serif,10'
$CheckBoxPhiphipoolplus.Checked =	$Config.PoolName -contains "phiphipoolplus"
$GroupboxPoolsControls += $CheckBoxPhiphipoolplus
	
$CheckBoxPhiphipool24hr = New-Object system.Windows.Forms.CheckBox
$CheckBoxPhiphipool24hr.Tag = @{name = "PoolName"; Value = "phiphipool24hr"}
$CheckBoxPhiphipool24hr.text = "24hr"
$CheckBoxPhiphipool24hr.AutoSize = $false
$CheckBoxPhiphipool24hr.width = 60
$CheckBoxPhiphipool24hr.height = 20
$CheckBoxPhiphipool24hr.location = New-Object System.Drawing.Point(175, 147)
$CheckBoxPhiphipool24hr.Font = 'Microsoft Sans Serif,10'
$CheckBoxPhiphipool24hr.Checked =	$Config.PoolName -contains "phiphipool24hr"
$GroupboxPoolsControls += $CheckBoxPhiphipool24hr

$CheckBoxZergpool = New-Object system.Windows.Forms.CheckBox
$CheckBoxZergpool.Tag = @{name = "PoolName"; Value = "zergpool"}
$CheckBoxZergpool.text = "zergpool"
$CheckBoxZergpool.AutoSize = $false
$CheckBoxZergpool.width = 100
$CheckBoxZergpool.height = 20
$CheckBoxZergpool.location = New-Object System.Drawing.Point(5, 169)
$CheckBoxZergpool.Font = 'Microsoft Sans Serif,10'
$CheckBoxZergpool.Checked =	$Config.PoolName -contains "zergpool"
$GroupboxPoolsControls += $CheckBoxZergpool

$CheckBoxZergpoolplus = New-Object system.Windows.Forms.CheckBox
$CheckBoxZergpoolplus.Tag = @{name = "PoolName"; Value = "zergpoolplus"}
$CheckBoxZergpoolplus.text = "Plus"
$CheckBoxZergpoolplus.AutoSize = $false
$CheckBoxZergpoolplus.width = 60
$CheckBoxZergpoolplus.height = 20
$CheckBoxZergpoolplus.location = New-Object System.Drawing.Point(110, 169)
$CheckBoxZergpoolplus.Font = 'Microsoft Sans Serif,10'
$CheckBoxZergpoolplus.Checked =	$Config.PoolName -contains "zergpoolplus"
$GroupboxPoolsControls += $CheckBoxZergpoolplus
	
$CheckBoxZergpool24hr = New-Object system.Windows.Forms.CheckBox
$CheckBoxZergpool24hr.Tag = @{name = "PoolName"; Value = "zergpool24hr"}
$CheckBoxZergpool24hr.text = "24hr"
$CheckBoxZergpool24hr.AutoSize = $false
$CheckBoxZergpool24hr.width = 60
$CheckBoxZergpool24hr.height = 20
$CheckBoxZergpool24hr.location = New-Object System.Drawing.Point(175, 169)
$CheckBoxZergpool24hr.Font = 'Microsoft Sans Serif,10'
$CheckBoxZergpool24hr.Checked =	$Config.PoolName -contains "zergpool24hr"
$GroupboxPoolsControls += $CheckBoxZergpool24hr
	
$CheckBoxZpool = New-Object system.Windows.Forms.CheckBox
$CheckBoxZpool.Tag = @{name = "PoolName"; Value = "zpool"}
$CheckBoxZpool.text = "zpool"
$CheckBoxZpool.AutoSize = $false
$CheckBoxZpool.width = 100
$CheckBoxZpool.height = 20
$CheckBoxZpool.location = New-Object System.Drawing.Point(5, 191)
$CheckBoxZpool.Font = 'Microsoft Sans Serif,10'
$CheckBoxZpool.Checked =	$Config.PoolName -contains "zpool"
$GroupboxPoolsControls += $CheckBoxZpool

$CheckBoxZpoolplus = New-Object system.Windows.Forms.CheckBox
$CheckBoxZpoolplus.Tag = @{name = "PoolName"; Value = "zpoolplus"}
$CheckBoxZpoolplus.text = "Plus"
$CheckBoxZpoolplus.AutoSize = $false
$CheckBoxZpoolplus.width = 60
$CheckBoxZpoolplus.height = 20
$CheckBoxZpoolplus.location = New-Object System.Drawing.Point(110, 191)
$CheckBoxZpoolplus.Font = 'Microsoft Sans Serif,10'
$CheckBoxZpoolplus.Checked =	$Config.PoolName -contains "zpoolplus"
$GroupboxPoolsControls += $CheckBoxZpoolplus
	
$CheckBoxZpool24hr = New-Object system.Windows.Forms.CheckBox
$CheckBoxZpool24hr.Tag = @{name = "PoolName"; Value = "zpool24hr"}
$CheckBoxZpool24hr.text = "24hr"
$CheckBoxZpool24hr.AutoSize = $false
$CheckBoxZpool24hr.width = 60
$CheckBoxZpool24hr.height = 20
$CheckBoxZpool24hr.location = New-Object System.Drawing.Point(175, 191)
$CheckBoxZpool24hr.Font = 'Microsoft Sans Serif,10'
$CheckBoxZpool24hr.Checked =	$Config.PoolName -contains "zpool24hr"
$GroupboxPoolsControls += $CheckBoxZpool24hr
	
$GroupboxPools.controls.AddRange($GroupboxPoolsControls)
$GroupboxPoolsControls | foreach {$_.Add_Click( {CheckBox_Click($This)})}

$MainForm | Add-Member -Name number -Value 0 -MemberType NoteProperty

$timerCycle = New-Object System.Windows.Forms.Timer
$timerCycle.Enabled = $false
$ButtonStart.Add_Click( {
        If ($timerCycle.Enabled) {
            Update-Status("Stopping cycle")
            $timerCycle.Stop()
            Update-Status("Stopping jobs and miner")
            Get-Job | Stop-Job | Remove-Job
            If ($Variables.ActiveMinerPrograms) {
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
                            Write-Host -ForegroundColor Yellow "closing miner"
                            Sleep 1
                            $_.Status = "Idle"
                        }
                    }
                }
            }
            $LabelBTCD.Text = "$($Variables.CurrentProduct) $($Variables.CurrentVersion)"
            $LabelRunning.Text = "Idle"
            $ButtonStart.Text = "Start"
            $timerCycle.Interval = 1000
        }
        else {
            $ButtonStart.Text = "Stop"
            InitApplication
            $timerCycle.Start()
        }
    })

$MainForm.controls.AddRange($MainFormControls)
$RunPage.controls.AddRange(@($EarningsDGV, $SwitchingDGV))
$EstimationsPage.Controls.AddRange(@($EstimationsDGV))
$ConfigPage.controls.AddRange($ConfigPageControls)

$MainForm.Add_Load( {Form_Load})
$timerCycle.Add_Tick( {TimerCycle_Tick})

[void]$MainForm.ShowDialog()


