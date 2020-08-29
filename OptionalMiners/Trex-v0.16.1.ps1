using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.16.1/t-rex-0.16.1-win-cuda10.0.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstralHash";      MinMemGB = 2; Command = " --algo astralhash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Balloon";         MinMemGB = 2; Command = " --algo balloon --intensity 23" }
    [PSCustomObject]@{ Algorithm = "BCD";             MinMemGB = 2; Command = " --algo bcd --intensity 24" }
#   [PSCustomObject]@{ Algorithm = "BitcoinInterest"; MinMemGB = 2; Command = " --algo progpow --coin BCI --intensity 21" } #Does not work
#   [PSCustomObject]@{ Algorithm = "Bitcore";         MinMemGB = 2; Command = " --algo bitcore --intensity 25" } #Profit very small
    [PSCustomObject]@{ Algorithm = "C11";             MinMemGB = 2; Command = " --algo c11 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "Dedal";           MinMemGB = 2; Command = " --algo dedal --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Geek";            MinMemGB = 2; Command = " --algo geek --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Honeycomb";       MinMemGB = 2; Command = " --algo honeycomb --intensity 26" }
    [PSCustomObject]@{ Algorithm = "JeongHash";       MinMemGB = 2; Command = " --algo jeonghash --intensity 23" }
#   [PSCustomObject]@{ Algorithm = "KawPoW";          MinMemGB = 2; Command = " --algo kawpow" } 
#   [PSCustomObject]@{ Algorithm = "MTP";             MinMemGB = 2; Command = " --algo mtp --intensity 21" } 
    [PSCustomObject]@{ Algorithm = "PadiHash";        MinMemGB = 2; Command = " --algo padihash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "PawelHash";       MinMemGB = 2; Command = " --algo pawelhash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Polytimos";       MinMemGB = 2; Command = " --algo polytimos --intensity 25" }
#   [PSCustomObject]@{ Algorithm = "ProgPoW";         MinMemGB = 2; Command = " --algo progpow --intensity 21 --mt 2" } #Coin parameter required, no pool
    [PSCustomObject]@{ Algorithm = "Sha256t";         MinMemGB = 2; Command = " --algo sha256t --intensity 26" }
    [PSCustomObject]@{ Algorithm = "Sha256q";         MinMemGB = 2; Command = " --algo sha256q --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Sonoa";           MinMemGB = 2; Command = " --algo sonoa --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Timetravel";      MinMemGB = 2; Command = " --algo timetravel --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Tribus";          MinMemGB = 2; Command = " --algo tribus --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Veil";            MinMemGB = 2; Command = " --algo x16rt --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X17";             MinMemGB = 2; Command = " --algo x17 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16s";            MinMemGB = 2; Command = " --algo x16s --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16r";            MinMemGB = 2; Command = " --algo x16r --intensity 24" }
#   [PSCustomObject]@{ Algorithm = "X16rv2";          MinMemGB = 2; Command = " --algo x16rv2 --intensity 24" } #Profit very small
#   [PSCustomObject]@{ Algorithm = "X16rt";           MinMemGB = 2; Command = " --algo x16rt --intensity 24" } #Profit very small
    [PSCustomObject]@{ Algorithm = "X21s";            MinMemGB = 2; Command = " --algo x21s --intensity 23" }
    [PSCustomObject]@{ Algorithm = "X22i";            MinMemGB = 2; Command = " --algo x22i --intensity 23" }
    [PSCustomObject]@{ Algorithm = "X25x";            MinMemGB = 2; Command = " --algo x25x --intensity 21" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$($_.Command) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)$(if ($Variables.IsLocalAdmin -eq $true) { " --mt 2" }) --no-watchdog --gpu-report-interval 25 --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-bind-telnet 0 --quiet --retry-pause 1 --timeout 50000 --cpu-priority 4 --devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "Trex"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        Fee        = 0.01 #Dev fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)/trex"
                    }
                }
            }
        }
    }
}
