using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { ($_.Type -eq "AMD" -and $_.OpenCL.ClVersion -ge "OpenCL C 1.2") -or $_.Type -eq"NVIDIA" })) { Return }

$Uri = "https://github.com/develsoftware/GMinerRelease/releases/download/2.89/gminer_2_89_windows64.zip"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\miner.exe"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs 

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Equihash1445");              Fee = @(0.02);  MinMemGB = 1.8; Type = "AMD"; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash144_5 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.46a is fastest
    [PSCustomObject]@{ Algorithm = @("Equihash2109");              Fee = @(0.02);  MinMemGB = 2.8; Type = "AMD"; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash210_9 --pers auto --cuda 0 --opencl 1" } # lolMiner-v1.46a is fastest
    [PSCustomObject]@{ Algorithm = @("EquihashBTG");               Fee = @(0.02);  MinMemGB = 3.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo equihash144_5 --pers BgoldPoW --cuda 0 --opencl 1" }
    [PSCustomObject]@{ Algorithm = @("EtcHash");                   Fee = @(0.01);  MinMemGB = 3.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo etchash --cuda 0 --opencl 1" } # PhoenixMiner-v6.0c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash");                    Fee = @(0.01);  MinMemGB = 5.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v6.0c may be faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = @("Ethash", "SHA256ton");       Fee = @(0.015); MinMemGB = 5.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo eth --dalgo ton --cuda 0 --opencl 1" } # 0 Hashrate on TON; https://github.com/develsoftware/GMinerRelease/issues/690
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");              Fee = @(0.01);  MinMemGB = 2.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo ethash --cuda 0 --opencl 1" } # PhoenixMiner-v6.0c may be faster, but I see lower speed at the pool
    # [PSCustomObject]@{ Algorithm = @("EthashLowMem", "SHA256ton"); Fee = @(0.015); MinMemGB = 2.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo eth --dalgo ton --cuda 0 --opencl 1" } # 0 Hashrate on TON; https://github.com/develsoftware/GMinerRelease/issues/690
    [PSCustomObject]@{ Algorithm = @("KawPoW");                    Fee = @(0.01);  MinMemGB = 4.0; Type = "AMD"; MinerSet = 0; WarmupTimes = @(30, 15); Arguments = " --algo kawpow --cuda 0 --opencl 1" }

    [PSCustomObject]@{ Algorithm = @("BeamV3");                    Fee = @(0.02);  MinMemGB = 3.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(30, 0);  Arguments = " --algo beamhashIII --cuda 1 --opencl 0" } # NBMiner-v40.1 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckaroo30CTX");             Fee = @(0.05);  MinMemGB = 8.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo cortex --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");                  Fee = @(0.02);  MinMemGB = 4.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(30, 0);  Arguments = " --algo cuckoo29 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("Equihash1254");              Fee = @(0.02);  MinMemGB = 3.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash125_4 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.8y4rc2 is fastest
    [PSCustomObject]@{ Algorithm = @("Equihash1445");              Fee = @(0.02);  MinMemGB = 2.1; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash144_5 --pers auto --cuda 1 --opencl 0" } # MiniZ-v1.8y4rc2 is fastest
    [PSCustomObject]@{ Algorithm = @("Equihash2109");              Fee = @(0.02);  MinMemGB = 1.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo equihash210_9 --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("EquihashBTG");               Fee = @(0.02);  MinMemGB = 3.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo equihash144_5 --pers BgoldPoW --cuda 1 --opencl 0" } # MiniZ-v1.8y4rc2 is fastest
    [PSCustomObject]@{ Algorithm = @("EtcHash");                   Fee = @(0.01);  MinMemGB = 3.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo etchash --cuda 1 --opencl 0" } # PhoenixMiner-v6.0c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash");                    Fee = @(0.01);  MinMemGB = 5.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo ethash --cuda 1 --opencl 0" } # PhoenixMiner-v6.0c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = @("Ethash", "SHA256ton");       Fee = @(0.015); MinMemGB = 5.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 0; WarmupTimes = @(45, 0);  Arguments = " --algo eth --dalgo ton --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");              Fee = @(0.01);  MinMemGB = 2.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo ethash --cuda 1 --opencl 0" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "SHA256ton"); Fee = @(0.015); MinMemGB = 2.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(30, 15); Arguments = " --algo eth --dalgo ton --cuda 1 --opencl 0" }
    [PSCustomObject]@{ Algorithm = @("KawPoW");                    Fee = @(0.01);  MinMemGB = 4.0; Type = "NVIDIA"; Tuning = " --mt 2"; MinerSet = 1; WarmupTimes = @(45, 0);  Arguments = " --algo kawpow --cuda 1 --opencl 0" } # XmRig-v6.16.3 is almost as fast but has no fee
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm[0]).Host -and (-not $_.Algorithm[1] -or $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = If ($Pools.($_.Algorithm[0]).DAGSize -gt 0) { ((($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            # Windows 10 requires more memory on some algos
            If ($_.Algorithm[0] -match "Cuckaroo*|Cuckoo*" -and [System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0") { $MinMemGB += 1 }

            $AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }

            If ($AvailableMiner_Devices) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "cuda", "opencl", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($_.Algorithm[0] -eq "SHA256ton") { 
                    If ($Pools.($_.Algorithm[0]).BaseName -eq "TonWhales") { 
                        $_.Arguments += " --server wss://$($Pools.($_.Algorithm[0]).Host)/stratum --user $($Pools.($_.Algorithm[0]).User) --worker $($Config.Workername)"
                    }
                    Else { 
                        $_.Arguments += " --server wss://$($Pools.($_.Algorithm[0]).Host) --user $($Pools.($_.Algorithm[0]).User) --worker $($Config.Workername)"
                    }
                }
                Else { 
                    $_.Arguments += " --server $($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) --user $($Pools.($_.Algorithm[0]).User) --pass $($Pools.($_.Algorithm[0]).Pass)$(If ($Pools.($_.Algorithm[0]).BaseName -eq "ProHashing" -and $_.Algorithm[0] -eq "EthashLowMem") { ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" })"
                    If ($Pools.($_.Algorithm[0]).DAGsize -ne $null -and $Pools.($_.Algorithm[0]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --proto stratum" }
                    If ($Pools.($_.Algorithm[0]).SSL) { $_.Arguments += " --ssl 1" }
                }

                If ($_.Algorithm[1]) { 
                    If ($_.Algorithm[1] -eq "SHA256ton") { 
                        If ($Pools.($_.Algorithm[1]).BaseName -eq "TonWhales") { 
                            $_.Arguments += " --dserver tcp.$($Pools.($_.Algorithm[1]).Host):$($Pools.($_.Algorithm[1]).Port) --duser $($Pools.($_.Algorithm[1]).User) --dworker $($Config.Workername)"
                        }
                        Else {  
                            $_.Arguments += " --dserver wss://$($Pools.($_.Algorithm[1]).Host) --duser $($Pools.($_.Algorithm[1]).User) --dworker $($Config.Workername)"
                        }
                    }
                    Else { 
                        $_.Arguments += " --dserver $($Pools.($_.Algorithm[1]).Host):$($Pools.($_.Algorithm[1]).Port) --duser $($Pools.($_.Algorithm[1]).User) --dpass $($Pools.($_.Algorithm[1]).Pass)"
                        If ($Pools.($_.Algorithm[1]).SSL) { $_.Arguments += " --dssl 1" }
                    }
                }

                # Apply tuning parameters
                If ($Config.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                # Contest ETH address (if ETH wallet is specified in config)
                # $_.Arguments += If ($Config.Wallets.ETH) { " --contest_wallet $($Config.Wallets.ETH)" } Else { " --contest_wallet 0x92e6F22C1493289e6AD2768E1F502Fc5b414a287" }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $_.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --api $MinerAPIPort --watchdog 0 --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithm   = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                    API         = "Gminer"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
