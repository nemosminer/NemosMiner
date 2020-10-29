using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\lolminer.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.11/lolMiner_v1.11_Win64.zip"
$DeviceEnumerator = "Bus"
$EthashMemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs 

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Beam";          MinMemGB = 3.0; Type = "AMD"; Fee = 0.01;  Command = " --algo BEAM-I" } #Algo is dead
#   [PSCustomObject]@{ Algorithm = "BeamV2";        MinMemGB = 3.0; Type = "AMD"; Fee = 0.01;  Command = " --algo BEAM-II" } #Algo is dead
    [PSCustomObject]@{ Algorithm = "BeamV3";        MinMemGB = 6.0; Type = "AMD"; Fee = 0.01;  Command = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      MinMemGB = 6.0; Type = "AMD"; Fee = 0.02;  Command = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo2948";  MinMemGB = 6.0; Type = "AMD"; Fee = 0.02;  Command = " --algo CR29-48" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";   MinMemGB = 6.0; Type = "AMD"; Fee = 0.02;  Command = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";   MinMemGB = 6.0; Type = "AMD"; Fee = 0.02;  Command = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; MinMemGB = 7.8; Type = "AMD"; Fee = 0.025; Command = " --algo C30CTX" }
#   [PSCustomObject]@{ Algorithm = "CuckarooD29";   MinMemGB = 4.0; Type = "AMD"; Fee = 0.02;  Command = " --algo C29D" } #TeamRed-v0.7.16b is fastest
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   MinMemGB = 6.0; Type = "AMD"; Fee = 0.02;  Command = " --algo C29M" }
#   [PSCustomObject]@{ Algorithm = "Cuckatoo31";    MinMemGB = 4.0; Type = "AMD"; Fee = 0.02;  Command = " --algo C31" } #TeamRed-v0.7.16b is fastest
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    MinMemGB = 4.0; Type = "AMD"; Fee = 0.02;  Command = " --algo C32" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";  MinMemGB = 2.0; Type = "AMD"; Fee = 0.01;  Command = " --coin AUTO144_5" }
#   [PSCustomObject]@{ Algorithm = "Equihash1927";  MinMemGB = 3.0; Type = "AMD"; Fee = 0.01;  Command = " --coin AUTO192_7" } #GMiner-v2.29 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash2109";  MinMemGB = 2.0; Type = "AMD"; Fee = 0.01;  Command = " --algo EQUI210_9" }
#   [PSCustomObject]@{ Algorithm = "EquihashBTG";   MinMemGB = 3.0; Type = "AMD"; Fee = 0.01;  Command = " --coin BTG" } #MiniZ-v1.6w is fastest
    [PSCustomObject]@{ Algorithm = "EquihashZCL";   MinMemGB = 3.0; Type = "AMD"; Fee = 0.01;  Command = " --coin ZCL" }
#   [PSCustomObject]@{ Algorithm = "Ethash";        MinMemGB = 4.0; Type = "AMD"; Fee = 0.07;  Command = " --algo ETHASH" } #Bminer-v16.3.1 & PhoenixMiner-v5.1c are faster

#   [PSCustomObject]@{ Algorithm = "Beam";          MinMemGB = 3.0; Type = "NVIDIA"; Fee = 0.01;  Command = " --algo BEAM-I" } #Algo is dead
#   [PSCustomObject]@{ Algorithm = "BeamV2";        MinMemGB = 3.0; Type = "NVIDIA"; Fee = 0.01;  Command = " --algo BEAM-II" } #Algo is dead
#   [PSCustomObject]@{ Algorithm = "BeamV3";        MinMemGB = 6.0; Type = "NVIDIA"; Fee = 0.01;  Command = " --algo BEAM-III" } #MiniZ-v1.6w is fastest
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      MinMemGB = 6.0; Type = "NVIDIA"; Fee = 0.02;  Command = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo2948";  MinMemGB = 6.0; Type = "NVIDIA"; Fee = 0.02;  Command = " --algo CR29-48" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";   MinMemGB = 6.0; Type = "NVIDIA"; Fee = 0.02;  Command = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";   MinMemGB = 6.0; Type = "NVIDIA"; Fee = 0.02;  Command = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; MinMemGB = 8.0; Type = "NVIDIA"; Fee = 0.025; Command = " --algo C30CTX" }
#   [PSCustomObject]@{ Algorithm = "CuckarooD29";   MinMemGB = 4.0; Type = "NVIDIA"; Fee = 0.02; Command = " --algo C29D" } #GMiner-v2.29 is fastest
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   MinMemGB = 6.0; Type = "NVIDIA"; Fee = 0.02; Command = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";    MinMemGB = 4.0; Type = "NVIDIA"; Fee = 0.02; Command = " --algo C31" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    MinMemGB = 4.0; Type = "NVIDIA"; Fee = 0.02; Command = " --algo C32" }
#   [PSCustomObject]@{ Algorithm = "Equihash1445";  MinMemGB = 2.0; Type = "NVIDIA"; Fee = 0.01; Command = " --coin AUTO144_5" } #MiniZ-v1.6w is fastest, but has 2% miner fee
#   [PSCustomObject]@{ Algorithm = "Equihash1927";  MinMemGB = 3.0; Type = "NVIDIA"; Fee = 0.01; Command = " --coin AUTO192_7" } #MiniZ-v1.6w is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "Equihash2109";  MinMemGB = 2.0; Type = "NVIDIA"; Fee = 0.01; Command = " --algo EQUI210_9" }
#   [PSCustomObject]@{ Algorithm = "EquihashBTG";   MinMemGB = 3.0; Type = "NVIDIA"; Fee = 0.01; Command = " --coin BTG" } #MiniZ-v1.6w is fastest, but has 2% miner fee
#   [PSCustomObject]@{ Algorithm = "EquihashZCL";   MinMemGB = 3.0; Type = "NVIDIA"; Fee = 0.01;  Command = " --coin ZCL" } #MiniZ-v1.6w is fastest, but has 2% miner fee
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -eq $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | Where-Object { -not $Pools.($_.Algorithm).SSL } | ForEach-Object {

                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -eq "Ethash") { 
                    $MinMemGB = ($Pools.($_.Algorithm).EthashDAGSize + $EthashMemReserve) / 1GB
                }

                If ($_.Algorithm -match "Cuckaroo*|Cuckoo*" -and ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0")) { $MinMemGB += 1 }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo", "coin") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = $_.Type
                        Path            = $Path
                        Arguments       = ("$($_.Command) --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).pass)$(If ($Pools.($_.Algorithm).SSL) { " --tls on" } Else { " --tls off" } ) --log off --apiport $MinerAPIPort --devicesbypcie --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}:0' -f $_.$DeviceEnumerator }) -join ',')").trim()
                        Algorithm       = $_.Algorithm
                        API             = "lolMiner"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee
                        WarmupTime      = 45 #seconds
                        PowerUsageInAPI = $true
                    }
                }
            }
        }
    }
}
