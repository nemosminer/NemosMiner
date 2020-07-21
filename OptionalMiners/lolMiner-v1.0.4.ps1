using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\lolminer.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.04/lolMiner_v1.04_Win64.zip"
$DeviceEnumerator = "Type_Slot"

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Beam";          MinMemGB = 2.75; Type = "AMD"   ; Fee = "0.01";  Command = " --algo BEAM-I" }
#   [PSCustomObject]@{ Algorithm = "BeamV2";        MinMemGB = 4.0;  Type = "AMD"   ; Fee = "0.01";  Command = " --algo BEAM-II" }
    [PSCustomObject]@{ Algorithm = "BeamV3";        MinMemGB = 6.0;  Type = "AMD"   ; Fee = "0.01";  Command = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; MinMemGB = 8.0;  Type = "AMD"   ; Fee = "0.025"; Command = " --algo C30CTX" }
#   [PSCustomObject]@{ Algorithm = "CuckarooD29";   MinMemGB = 4.0;  Type = "AMD"   ; Fee = "0.02";  Command = " --algo C29D" } #Does not work
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   MinMemGB = 6.0;  Type = "AMD"   ; Fee = "0.02";  Command = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";    MinMemGB = 4.0;  Type = "AMD"   ; Fee = "0.02";  Command = " --algo C31" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    MinMemGB = 4.0;  Type = "AMD"   ; Fee = "0.02";  Command = " --algo C32" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";  MinMemGB = 1.85; Type = "AMD"   ; Fee = "0.01";  Command = " --coin AUTO144_5" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";  MinMemGB = 3.0;  Type = "AMD"   ; Fee = "0.01";  Command = " --coin AUTO192_7" }
    [PSCustomObject]@{ Algorithm = "Equihash2109";  MinMemGB = 2.0;  Type = "AMD"   ; Fee = "0.01";  Command = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";   MinMemGB = 3.0;  Type = "AMD"   ; Fee = "0.01";  Command = " --coin BTG" }
    [PSCustomObject]@{ Algorithm = "EquihashZCL";   MinMemGB = 3.0;  Type = "AMD"   ; Fee = "0.01";  Command = " --coin ZEL" }
#   [PSCustomObject]@{ Algorithm = "Beam";          MinMemGB = 2.75; Type = "NVIDIA"; Fee = "0.01";  Command = " --algo BEAM-I" }
#   [PSCustomObject]@{ Algorithm = "BeamV2";        MinMemGB = 4.0;  Type = "NVIDIA"; Fee = "0.01";  Command = " --algo BEAM-II" }
    [PSCustomObject]@{ Algorithm = "BeamV3";        MinMemGB = 6.0;  Type = "NVIDIA"; Fee = "0.01";  Command = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; MinMemGB = 8.0;  Type = "NVIDIA"; Fee = "0.025"; Command = " --algo C30CTX" }
#   [PSCustomObject]@{ Algorithm = "CuckarooD29";   MinMemGB = 4.0;  Type = "NVIDIA"; Fee = "0.02";  Command = " --algo C29D" } #Does not work
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   MinMemGB = 6.0;  Type = "NVIDIA"; Fee = "0.02";  Command = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";    MinMemGB = 4.0;  Type = "NVIDIA"; Fee = "0.02";  Command = " --algo C31" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    MinMemGB = 4.0;  Type = "NVIDIA"; Fee = "0.02";  Command = " --algo C32" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";  MinMemGB = 1.85; Type = "NVIDIA"; Fee = "0.01";  Command = " --coin AUTO144_5" }
    [PSCustomObject]@{ Algorithm = "Equihash1927";  MinMemGB = 3.0;  Type = "NVIDIA"; Fee = "0.01";  Command = " --coin AUTO192_7" }
    [PSCustomObject]@{ Algorithm = "Equihash2109";  MinMemGB = 2.0;  Type = "NVIDIA"; Fee = "0.01";  Command = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";   MinMemGB = 3.0;  Type = "NVIDIA"; Fee = "0.01";  Command = " --coin BTG" }
    [PSCustomObject]@{ Algorithm = "EquihashZCL";   MinMemGB = 3.0;  Type = "NVIDIA"; Fee = "0.01";  Command = " --coin ZEL" }
)

$Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -eq $_.Type | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object Type -eq $_.Type | Where-Object { $Pools.($_.Algorithm).Host } | Where-Object { -not $Pools.($_.Algorithm).SSL } | ForEach-Object {
            If ($_.Algorithm -match "Cuckaroo*|Cuckoo*" -and ([System.Version]$PSVersionTable.BuildVersion -ge "10.0.0.0")) { $MinMemGB += 1 }
            $MinMemGB = $_.MinMemGB

            If ($Miner_Devices = @($SelectedDevices | Where-Object { ([math]::Round((10 * $_.OpenCL.GlobalMemSize / 1GB), 0) / 10) -ge $MinMemGB })) { 
                $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo", "coin") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Path       = $Path
                    Arguments  = ("$($_.Command) --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).pass) --apiport $MinerAPIPort --devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')").trim()
                    Algorithm  = $_.Algorithm
                    API        = "lolMiner"
                    Port       = $MinerAPIPort
                    URI        = $Uri
                    Fee        = $_.Fee
                    WarmupTime = 45 #seconds
                }
            }
        }
    }
}
