using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.15.8/t-rex-0.15.8-win-cuda10.0.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject]@{ 
#   "AstralHash"      = " --algo astralhash --intensity 23"
#   "Balloon"         = " --algo balloon --intensity 23" # No pool
#   "BCD"             = " --algo bcd --intensity 24"
#   "BitcoinInterest" = " --algo progpow --coin BCI --intensity 21" #Does not work
#   "Bitcore"         = " --algo bitcore --intensity 25" #Profit very small
#   "C11"             = " --algo c11 --intensity 24"
#   "Dedal"           = " --algo dedal --intensity 23"
#   "Geek"            = " --algo geek --intensity 23" #No pool
#   "Honeycomb"       = " --algo honeycomb --intensity 26"
    "JeongHash"       = " --algo jeonghash --intensity 23"
#   "KawPoW"          = " --algo kawpow" #ZealotEnemy-v2.6.2 is fastest
    "MTP"             = " --algo mtp --intensity 21"
    "PadiHash"        = " --algo padihash --intensity 23"
    "PawelHash"       = " --algo pawelhash --intensity 23"
#   "Polytimos"       = " --algo polytimos --intensity 25" #No pool
#   "ProgPoW"         = " --algo progpow --intensity 21" #Requires coin parameter
#   "Sha256t"         = " --algo sha256t --intensity 26" #No pool
#   "Sha256q"         = " --algo sha256q --intensity 23" #No pool
    "Sonoa"           = " --algo sonoa --intensity 23"
#   "Timetravel"      = " --algo timetravel --intensity 25" #No pool
#   "Tribus"          = " --algo tribus --intensity 23"
#   "Veil"            = " --algo x16rt --intensity 24"
    "X17"             = " --algo x17 --intensity 24"
    "X16s"            = " --algo x16s --intensity 24"
    "X16r"            = " --algo x16r --intensity 24"
    "X16rv2"          = " --algo x16rv2 --intensity 24"
#   "X16rt"           = " --algo x16rt --intensity 24" #Profit very small
    "X21s"            = " --algo x21s --intensity 23"
    "X22i"            = " --algo x22i --intensity 23" 
    "X25x"            = " --algo x25x --intensity 21"
}

$Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.$_.Host } | ForEach-Object {

            #Get commands for active miner devices
            #$Commands.$_ = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Type       = "NVIDIA"
                Path       = $Path
                Arguments  = ("$($Commands.$_) --url stratum+tcp://$($Pools.$_.Host):$($Pools.$_.Port) --user $($Pools.$_.User) --pass $($Pools.$_.Pass) --no-watchdog --gpu-report-interval 25 --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-bind-telnet 0 --quiet --retry-pause 1 --timeout 50000 --cpu-priority 4 --devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ' ')" -replace "\s+", " ").trim()
                Algorithm  = $_
                API        = "Trex"
                Port       = $MinerAPIPort
                URI        = $Uri
                Fee        = 0.01 #Dev fee
                MinerUri   = "http://localhost:$($MinerAPIPort)/trex"
            }
        }
    }
}
