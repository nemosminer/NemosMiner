using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\lolminer.exe"
$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.16/lolMiner_v1.16a_Win64.zip"
$DeviceEnumerator = "Bus"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs 

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Beam";          Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; Command = " --algo BEAM-I" } #Algo is dead, needs pers
#   [PSCustomObject]@{ Algorithm = "BeamV2";        Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; Command = " --algo BEAM-II" } #Algo is dead
    [PSCustomObject]@{ Algorithm = "BeamV3";        Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo2948";  Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo CR29-48" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";   Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";   Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Type = "AMD"; Fee = 0.01;  MinMemGB = 7.8; Command = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29";   Type = "AMD"; Fee = 0.01;  MinMemGB = 4.0; Command = " --algo C29D" } #TeamRed-v0.7.18 is fastest, keep enabled because TeamRed does not support algo on Navi
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";    Type = "AMD"; Fee = 0.01;  MinMemGB = 4.0; Command = " --algo C31" } #TeamRed-v0.7.18 is fastest
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    Type = "AMD"; Fee = 0.01;  MinMemGB = 4.0; Command = " --algo C32" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";  Type = "AMD"; Fee = 0.01;  MinMemGB = 2.0; Command = " --coin AUTO144_5" }
#   [PSCustomObject]@{ Algorithm = "Equihash1927";  Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; Command = " --coin AUTO192_7" } #GMiner-v2.33 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash2109";  Type = "AMD"; Fee = 0.01;  MinMemGB = 2.0; Command = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = "EquihashBTG";   Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; Command = " --coin BTG" }
    [PSCustomObject]@{ Algorithm = "EquihashZEL";   Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; Command = " --coin ZCL" }
#   [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.007; MinMemGB = 4.0; Command = " --algo ETCHASH -coin ETC" } #Ethereum Classic starting with epoch 390, PhoenixMiner-v5.3b is faster
#   [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.007; MinMemGB = 4.0; Command = " --algo ETHASH" } #Bminer-v16.3.6 & PhoenixMiner-v5.3b are faster

#   [PSCustomObject]@{ Algorithm = "Beam";          Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; Command = " --algo BEAM-I" } #Algo is dead, needs pers
#   [PSCustomObject]@{ Algorithm = "BeamV2";        Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; Command = " --algo BEAM-II" } #Algo is dead
#   [PSCustomObject]@{ Algorithm = "BeamV3";        Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo BEAM-III" } #MiniZ-v1.6w2 is fastest
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo2948";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo CR29-48" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 8.0; Command = " --algo C30CTX" }
#   [PSCustomObject]@{ Algorithm = "CuckarooD29";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 4.0; Command = " --algo C29D" } #GMiner-v2.33 is fastest
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; Command = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";    Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 4.0; Command = " --algo C31" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 4.0; Command = " --algo C32" }
#   [PSCustomObject]@{ Algorithm = "Equihash1445";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 2.0; Command = " --coin AUTO144_5" } #MiniZ-v1.6w2 is fastest, but has 2% miner fee
#   [PSCustomObject]@{ Algorithm = "Equihash1927";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; Command = " --coin AUTO192_7" } #MiniZ-v1.6w2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "Equihash2109";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 2.0; Command = " --algo EQUI210_9" }
#   [PSCustomObject]@{ Algorithm = "EquihashBTG";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; Command = " --coin BTG" } #MiniZ-v1.6w2 is fastest, but has 2% miner fee
#   [PSCustomObject]@{ Algorithm = "EquihashZEL";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; Command = " --coin ZCL" } #MiniZ-v1.6w2 is fastest, but has 2% miner fee
#   [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "NVIDIA"; Fee = 0.007; MinMemGB = 4.0; Command = " --algo ETCHASH --coin ETC" } #Ethereum Classic starting with epoch 390, PhoenixMiner-v5.3b is faster
#   [PSCustomObject]@{ Algorithm = "Ethash";        Type = "NVIDIA"; Fee = 0.007; MinMemGB = 4.0; Command = " --algo ETHASH" } #TTMiner-v5.0.3 is fastest
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -eq $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | Where-Object { -not $Pools.($_.Algorithm).SSL } | ForEach-Object {

                $Command = $_.Command
                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -in @("EtcHash", "Ethash")) { 
                    $MinMemGB = ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB
                }

                If ($_.Algorithm -eq "Ethash") { 
                    If ($Pools.($_.Algorithm).Name -match "^NiceHash$|^MPH(|Coins)$") { 
                        $Command += " --ethstratum ETHV1"
                    }
                    Else { 
                        $Command += " --ethstratum ETHPROXY --worker $($Pools.($_.Algorithm).User -split '\.' | Select-Object -Last 1)"
                    }
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
                        Arguments       = ("$($Command) --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).pass)$(If ($Pools.($_.Algorithm).SSL) { " --tls on" } Else { " --tls off" } ) --log off --apiport $MinerAPIPort --devicesbypcie --shortstats=5 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0}:0' -f $_.$DeviceEnumerator }) -join ',')").trim()
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
