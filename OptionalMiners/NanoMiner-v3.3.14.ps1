using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nanominer.exe"
$Uri = "https://github.com/nanopool/nanominer/releases/download/v3.3.14/nanominer-windows-3.3.14-cuda11.zip"
$DeviceEnumerator = "Bus_Type_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";    Type = "AMD"; Fee = 0.05; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(20, 40); Coin = "ERG" } # NBMiner-v39.5 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.01; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(45, 40); Coin = "ETC" } # PhoenixMiner-v5.7b is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.01; MinMemGB = 5;  MinerSet = 1; WarmupTimes = @(45, 40); Coin = "ETH" } # PhoenixMiner-v5.7b is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "AMD"; Fee = 0.01; MinMemGB = 2;  MinerSet = 1; WarmupTimes = @(45, 40); Coin = "ETH" } # PhoenixMiner-v5.7b is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";        Type = "AMD"; Fee = 0.02; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(30, 40); Coin = "RVN" } # TeamRed-v0.8.6 is fastest
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "AMD"; Fee = 0.01; MinMemGB = 4;  MinerSet = 1; WarmupTimes = @(45, 40); Coin = "UBQ" } # PhoenixMiner-v5.7b is fastest
    [PSCustomObject]@{ Algorithm = "VertHash";      Type = "AMD"; Fee = 0.01; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(45, 40); Coin = "VTC" } # SRBMinerMulti-v0.8.0 is fastest

    [PSCustomObject]@{ Algorithm = "Randomx";   Type = "CPU"; Fee = 0.02; MinerSet = 1; WarmupTimes = @(0, 30); Coin = "XMR" } # XmRig-v6.12.2 is fastest
    [PSCustomObject]@{ Algorithm = "VerusHash"; Type = "CPU"; Fee = 0.02; MinerSet = 0; WarmupTimes = @(0, 30); Coin = "VRSC" }

    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "NVIDIA"; Fee = 0.05; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 120); Coin = "ERG" } # Trex-v0.24.5 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 40);  Coin = "ETC" } # PhoenixMiner-v5.7b is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01; MinMemGB = 5; MinerSet = 1; WarmupTimes = @(0, 40);  Coin = "ETH" } # PhoenixMiner-v5.7b is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(0, 40);  Coin = "ETH" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; Fee = 0.02; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(0, 40);  Coin = "RVN" } # Trex-v0.24.5 is fastest
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.02; MinMemGB = 4; MinerSet = 1; WarmupTimes = @(0, 40);  Coin = "CFX" } # NBMiner-v39.5 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = 4; MinerSet = 1; WarmupTimes = @(0, 40);  Coin = "UBQ" } # PhoenixMiner-v5.7b is fastest
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($Miner_Devices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

                $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

                If ($AvailableMiner_Devices = @($Miner_Devices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB } | Where-Object { $_.Type -ne "NVIDIA" -or [Double]($_.OpenCL.ComputeCapability) -gt 5.0 })) { 

                    $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-'

                    $ConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("Config") + @($_.Algorithm) + @($($Pools.($_.Algorithm).Name -replace "24hr$|Coins$|Plus$|CoinsPlus$")) + @($Pools.($_.Algorithm).User) + @($Pools.($_.Algorithm).Pass) + @(($AvailableMiner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model($(($AvailableMiner_Devices | Sort-Object Name | Where-Object Model -EQ $Model).Name -join ';'))" } | Select-Object) -join '-') + @($MinerAPIPort) | Select-Object) -join '-').ini")
                    If ($Config.UseMinerTweaks -eq $true) { $ConfigFileName = $ConfigFileName -replace '\.ini$', '-memTweak.ini' }
                    $Arguments = [PSCustomObject]@{ 
                        Arguments  = $ConfigFileName
                        ConfigFile = [PSCustomObject]@{ 
                            FileName = $ConfigFileName
                            Content  = "
; NemosMiner ($Miner_Name) autogenerated config file NemosMiner.com
checkForUpdates=false
coreClocks=+0
memClocks=+0
memTweak=$(If ($Config.UseMinerTweaks -eq $true) { "2" } Else { "0" })
mport=0
noLog=true
powerLimits=0
rigName=$($Config.WorkerName)
rigPassword=$($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).Name -match "^ProHashing.*$" -and $_.Algorithm -eq "EthashLowMem") { ",1=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" })
watchdog=false
webPort=$($MinerAPIPort)
useSSL=$($Pools.($_.Algorithm).SSL)

coin=$($_.Coin)
devices=$(($AvailableMiner_Devices | Sort-Object Name -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')
pool1=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)
wallet=$($Pools.($_.Algorithm).User -split '\.' | Select-Object -Index 0)
$(If ($Pools.($_.Algorithm).DAGSize -gt 0 -and $Pools.($_.Algorithm).Name -match "^MiningPoolHub(|Coins)$|^NiceHash$") { "protocol=stratum" } )"
                        }
                    }

                    If ($_.Algorithm -eq "VertHash" -and (-not (Get-Item ".\Bin\$($Name)\VertHash.dat" -ErrorAction Ignore).length -ne 1283457024)) { $_.WarmupTimes[1] += 600 } # Allow 10 minutes to generate verthash.dat file

                    [PSCustomObject]@{ 
                        Name        = $Miner_Name -replace " "
                        DeviceName  = $AvailableMiner_Devices.Name
                        Type        = $_.Type
                        Path        = $Path
                        Arguments   = $Arguments | ConvertTo-Json -Depth 10 -Compress
                        Algorithm   = $_.Algorithm
                        API         = "NanoMiner"
                        Port        = $MinerAPIPort
                        URI         = $Uri
                        Fee         = $_.Fee
                        MinerUri    = "http://localhost:$($MinerAPIPort)/#/"
                        WarmupTimes = $_.WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
