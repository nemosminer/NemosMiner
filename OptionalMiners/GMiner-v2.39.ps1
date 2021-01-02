using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\miner.exe"
$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/2.39/gminer_2_39_windows64.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";         Fee = 0.02;   MinMemGB = 4.0; Type = "AMD"; Command = " --algo cuckaroo29b --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";         Fee = 0.02;   MinMemGB = 4.0; Type = "AMD"; Command = " --algo cuckaroo29s --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = "Equihash1254";        Fee = 0.02;   MinMemGB = 3.0; Type = "AMD"; Command = " --algo equihash125_4 --pers auto --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";        Fee = 0.02;   MinMemGB = 1.8; Type = "AMD"; Command = " --algo equihash144_5 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.17 is fastest
    [PSCustomObject]@{ Algorithm = "Equihash1927";        Fee = 0.02;   MinMemGB = 2.8; Type = "AMD"; Command = " --algo equihash192_7 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.17 is fastest
    [PSCustomObject]@{ Algorithm = "EquihashBTG";         Fee = 0.02;   MinMemGB = 3.0; Type = "AMD"; Command = " --algo 144_5 --pers BgoldPoW --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = "EtcHash";             Fee = 0.0065; MinMemGB = 3.0; Type = "AMD"; Command = " --algo etchash --cuda 0 --opencl 1" } # PhoenixMiner-v5.4c is maybe faster, bit I see lower sppeed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";              Fee = 0.0065; MinMemGB = 4.0; Type = "AMD"; Command = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v5.4c is maybe faster, bit I see lower sppeed at the pool

#   [PSCustomObject]@{ Algorithm = "BeamV3";              Fee = 0.02;   MinMemGB = 3.0; Type = "NVIDIA"; Command = " --algo beamhashIII --cuda 1 --opencl 0" } # NBMiner-v34.5 is fastest
    [PSCustomObject]@{ Algorithm = "Cuckaroo29bfc";       Fee = 0.03;   MinMemGB = 6.0; Type = "NVIDIA"; Command = " --algo bfc --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";         Fee = 0.04;   MinMemGB = 4.0; Type = "NVIDIA"; Command = " --algo cuckaroo29b --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";         Fee = 0.02;   MinMemGB = 4.0; Type = "NVIDIA"; Command = " --algo cuckaroo29s --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29";         Fee = 0.02;   MinMemGB = 4.0; Type = "NVIDIA"; Command = " --algo cuckarood29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29V";        Fee = 0.10;   MinMemGB = 4.0; Type = "NVIDIA"; Command = " --algo cuckarood29v --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "CuckarooZ29";         Fee = 0.03;   MinMemGB = 4.0; Type = "NVIDIA"; Command = " --algo cuckarooz29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX";       Fee = 0.05;   MinMemGB = 8.0; Type = "NVIDIA"; Command = " --algo C30CTX --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";          Fee = 0.02;   MinMemGB = 7.4; Type = "NVIDIA"; Command = " --algo cuckatoo31 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";          Fee = 0.02;   MinMemGB = 7.4; Type = "NVIDIA"; Command = " --algo cuckatoo32 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";            Fee = 0.02;   MinMemGB = 4.0; Type = "NVIDIA"; Command = " --algo cuckoo29 --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = "Equihash1254";        Fee = 0.02;   MinMemGB = 3.0; Type = "NVIDIA"; Command = " --algo equihash125_4 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.6x is fastest
#   [PSCustomObject]@{ Algorithm = "Equihash1445";        Fee = 0.02;   MinMemGB = 1.8; Type = "NVIDIA"; Command = " --algo equihash144_5 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.6x is fastest
#   [PSCustomObject]@{ Algorithm = "Equihash1927";        Fee = 0.02;   MinMemGB = 2.8; Type = "NVIDIA"; Command = " --algo equihash192_7 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.6x is fastest
    [PSCustomObject]@{ Algorithm = "Equihash2109";        Fee = 0.02;   MinMemGB = 1.0; Type = "NVIDIA"; Command = " --algo equihash210_9 --cuda 1 --opencl 0" }
#   [PSCustomObject]@{ Algorithm = "EquihashBTG";         Fee = 0.02;   MinMemGB = 3.0; Type = "NVIDIA"; Command = " --algo 144_5 --pers BgoldPoW --cuda 1 --opencl 0" } # MiniZ-v1.6x is fastest
   [PSCustomObject]@{ Algorithm = "EtcHash";             Fee = 0.0065; MinMemGB = 3.0; Type = "NVIDIA"; Command = " --algo etchash --cuda 1 --opencl 0" } # PhoenixMiner-v5.4c is fastest
   [PSCustomObject]@{ Algorithm = "Ethash";              Fee = 0.0065; MinMemGB = 4.0; Type = "NVIDIA"; Command = " --algo ethash --cuda 1 --opencl 0" } # PhoenixMiner-v5.4c is fastest
   [PSCustomObject]@{ Algorithm = "KawPoW";              Fee = 0.01;   MinMemGB = 4.0; Type = "NVIDIA"; Command = " --algo kawpow --cuda 1 --opencl 0" } # XmRig-v6.7.0 is almost as fast but has no fee
#   [PSCustomObject]@{ Algorithm = "Sero";                Fee = 0.02;   MinMemGB = 4.0; Type = "NVIDIA"; Command = " --algo sero --cuda 1 --opencl 0" } # Sero != ProgPoW on ZergPool
    [PSCustomObject]@{ Algorithm = "VeriBlock";           Fee = 0.02;   MinMemGB = 2.0; Type = "NVIDIA"; Command = " --algo VProgPoW --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = "ProgPoWZ";            Fee = 0.02;   MinMemGB = 2.0; Type = "NVIDIA"; Command = " --algo ProgPoWZ --cuda 1 --opencl 0" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object { 

                If ($_.Algorithm -eq "KawPoW" -and $Pools.($_.Algorithm).Name -match "^MPH(|Coins)$") { Return } # Temp fix (https://github.com/develsoftware/GMinerRelease/issues/113)

                If ($_.Algorithm -match "^Equihash*|^Cuckaroo29bfc$" -and (($SelectedDevices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$')) { Return } # Algo not supported on Navi

                $Command = $_.Command
                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -in @("EtcHash", "Ethash", "KawPoW")) { 
                    $MinMemGB = ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB
                }

                # Windows 10 requires more memory on some algos
                If ($_.Algorithm -match "Cuckaroo*|Cuckoo*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGB += 1 }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get commands for active miner devices
                    # $Command = Get-CommandPerDevice -Command $Command -ExcludeParameters @("algo", "pers", "proto") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $Command += " --server $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)"

                    If ($Pools.($_.Algorithm).SSL) { $Command += " --ssl true --ssl_verification false" }
                    If ($_.Algorithm -in @("EtcHash", "Ethash", "KawPoW") -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MPH(|Coins)$") { $Command += " --proto stratum" }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = $_.Type
                        Path            = $Path
                        Arguments       = ("$Command --api $($MinerAPIPort) --watchdog 0 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "Gminer"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee
                        MinerUri        = "http://localhost:$($MinerAPIPort)"
                        PowerUsageInAPI = $true
                    }
                }
            }
        }
    }
}
