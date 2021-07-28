using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nanominer.exe"
$Uri = "https://github.com/nanopool/nanominer/releases/download/v3.3.7/nanominer-windows-3.3.7-cuda11.zip"
$DeviceEnumerator = "Bus_Type_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";    Type = "AMD"; Fee = 0.05; MinMemGB = 3;  MinerSet = 0; WarmupTimes = @(0, 30);  Coin = "Autolykos" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Type = "AMD"; Fee = 0.05; MinMemGB = 16; MinerSet = 1; WarmupTimes = @(120, 0); Coin = "Cuckaroo30" }
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.01; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(120, 0); Coin = "Etchash" } # PhoenixMiner-v5.6d is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.01; MinMemGB = 5;  MinerSet = 1; WarmupTimes = @(120, 0); Coin = "Ethash" } # PhoenixMiner-v5.6d is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "AMD"; Fee = 0.01; MinMemGB = 2;  MinerSet = 1; WarmupTimes = @(120, 0); Coin = "Ethash" } # PhoenixMiner-v5.6d is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";        Type = "AMD"; Fee = 0.02; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(120, 0); Coin = "Kawpow" } # TeamRed-v0.8.4 is fastest
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "AMD"; Fee = 0.01; MinMemGB = 4;  MinerSet = 1; WarmupTimes = @(120, 0); Coin = "Ubqhash" } # PhoenixMiner-v5.6d is fastest

    [PSCustomObject]@{ Algorithm = "Randomx";   Type = "CPU"; Fee = 0.02; MinerSet = 0; WarmupTimes = @(0, 30); Coin = "Randomx" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "VerusHash"; Type = "CPU"; Fee = 0.02; MinerSet = 0; WarmupTimes = @(0, 30); Coin = "VerusHash" }

    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "NVIDIA"; Fee = 0.05; MinMemGB = 3; MinerSet = 0; WarmupTimes = @(0, 30); Coin = "Autolykos" }
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 30); Coin = "Etchash" } # PhoenixMiner-v5.6d is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01; MinMemGB = 5; MinerSet = 1; WarmupTimes = @(0, 30); Coin = "Ethash" } # PhoenixMiner-v5.6d is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 30); Coin = "Ethash" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; Fee = 0.02; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 30); Coin = "Kawpow" } # Trex-v0.21.5 is fastest
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.02; MinMemGB = 4; MinerSet = 1; WarmupTimes = @(0, 15); Coin = "Octopus" } # NBMiner-v38.1 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = 4; MinerSet = 1; WarmupTimes = @(0, 30); Coin = "Ubqhash" } # PhoenixMiner-v5.6d is fastest
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ForEach-Object { 

                $MinMemGB = $_.MinMemGB
                If ($Pools.($_.Algorithm).DAGSize -gt 0) { $MinMemGB = ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB } | Where-Object { $_.Type -ne "NVIDIA" -or [Double]($_.OpenCL.ComputeCapability) -gt 5.0 })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-'

                    $ConfigFileName = "$((@("Config") + @($_.Algorithm) + @($($Pools.($_.Algorithm).Name -replace "-Coins" -replace "24hr")) + @($Pools.($_.Algorithm).User) + @($Pools.($_.Algorithm).Pass) + @(($Miner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -EQ $Model).Count)x$Model($(($Miner_Devices | Sort-Object Name | Where-Object Model -EQ $Model).Name -join ';'))" } | Select-Object) -join '-') + @($MinerAPIPort) | Select-Object) -join '-').ini"
                    If ($Config.UseMinerTweaks -eq $true) { $ConfigFileName = $ConfigFileName -replace '\.ini$', '-memTweak.ini' }
                    $Arguments = [PSCustomObject]@{ 
                        ConfigFile = [PSCustomObject]@{ 
                            FileName = $ConfigFileName
                            Content  = "
; NemosMiner ($Miner_Name) autogenerated config file (c) NemosMiner.com
checkForUpdates=false
coreClocks=+0
memClocks=+0
memTweak=$(If ($Config.UseMinerTweaks -eq $true) { "2" } Else { "0" })
mport=0
noLog=true
powerLimits=0
rigName=$($Config.WorkerName)
rigPassword=$($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).Name -match "^ProHashing.*$" -and $_.Algorithm -eq "EthashLowMem") { ",1=$((($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" })
watchdog=false
webPort=$($MinerAPIPort)
useSSL=$($Pools.($_.Algorithm).SSL)

[$($_.Coin)]
devices=$(($Miner_Devices | Sort-Object Name -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')
pool1=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)
wallet=$($Pools.($_.Algorithm).User -split '\.' | Select-Object -Index 0)
$(If ($Pools.($_.Algorithm).DAGSize -gt 0) { "protocol=stratum" } )"
                        }
                        Commands   = "$ConfigFileName"
                    }

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name
                        DeviceName  = $Miner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = $Arguments | ConvertTo-Json -Depth 10 -Compress
                        Algorithm   = $_.Algorithm
                        API         = "NanoMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)/#/"
                        WarmupTimes = $_.WarmupTimes # First value: extra time (in seconds) until first hash rate sample is valid, second value: extra time (in seconds) until miner must send valid sample
                    }
                }
            }
        }
    }
}
