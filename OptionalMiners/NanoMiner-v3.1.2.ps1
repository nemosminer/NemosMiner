using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nanominer.exe"
$Uri = "https://github.com/nanopool/nanominer/releases/download/v3.1.2/nanominer-windows-3.1.2-cuda11.zip"
$DeviceEnumerator = "Type_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs 

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Type = "AMD"; Fee = 0.02; MinMemGB = 16; Coin = "Cuckaroo30" }
#   [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.01; MinMemGB = 4;  Coin = "Etchash" } #Ethereum Classic starting with epoch 390, PhoenixMiner-v5.3b is fastest
#   [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.01; MinMemGB = 4;  Coin = "Ethash" } #PhoenixMiner-v5.3b is fastest
#   [PSCustomObject]@{ Algorithm = "KawPoW";        Type = "AMD"; Fee = 0.02; MinMemGB = 3;  Coin = "Kawpow" } #TeamRed-v0.7.18 is fastest
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "AMD"; Fee = 0.01; MinMemGB = 4;  Coin = "Ubqhash" }

    [PSCustomObject]@{ Algorithm = "RandomHash2"; Type = "CPU"; Fee = 0;    Coin = "RandomHash2" }
#   [PSCustomObject]@{ Algorithm = "Randomx";     Type = "CPU"; Fee = 0.02; Coin = "RandomX" } #XmRig-v6.5.0 is fastest

#   [PSCustomObject]@{ Algorithm = "EtcHash"; Type = "NVIDIA"; Fee = 0.01; MinMemGB = 4; Coin = "Etchash" } #Ethereum Classic starting with epoch 390, PhoenixMiner-v5.3b is fastest
#   [PSCustomObject]@{ Algorithm = "Ethash";  Type = "NVIDIA"; Fee = 0.01; MinMemGB = 4; Coin = "Ethash" } #TTMiner-v6.1.0 is fastest
#   [PSCustomObject]@{ Algorithm = "KawPoW";  Type = "NVIDIA"; Fee = 0.01; MinMemGB = 3; Coin = "Kawpow" } #Trex-v0.19.1 is fastest
#   [PSCustomObject]@{ Algorithm = "Octopus"; Type = "NVIDIA"; Fee = 0.02; MinMemGB = 4; Coin = "Octopus" } #NBMiner-v34.4 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash"; Type = "NVIDIA"; Fee = 0.01; MinMemGB = 4; Coin = "Ubqhash" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object { $Algo = $_.Algorithm; $_ } | ForEach-Object { 

                If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -like "ZergPool*") { Return }

                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -in @("EtcHash", "Ethash")) { 
                    $MinMemGB = ($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.Type -eq "CPU" -or ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    $ConfigFileName = "$((@("Config") + @($_.Algorithm) + @($($Pools.($_.Algorithm).Name -replace "-Coins" -replace "24hr")) + @($Pools.($_.Algorithm).User) + @($Pools.($_.Algorithm).Pass) + @(($Miner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model($(($Miner_Devices | Sort-Object Name | Where-Object Model -eq $Model).Name -join ';'))" } | Select-Object) -join '-') + @($MinerAPIPort) | Select-Object) -join '-').ini"
                    $Arguments = [PSCustomObject]@{ 
                        ConfigFile = [PSCustomObject]@{ 
                        FileName = $ConfigFileName
                        Content  = "
    ; NemosMiner autogenerated config file (c) nemosminer.com
    checkForUpdates=false
    $(If (($SelectedDevices.Vendor | Select-Object -Unique) -eq "NVIDIA") { 
        "coreClocks=+0"
        "memClocks=+0"
    })
    $(If (($SelectedDevices.Vendor | Select-Object -Unique) -eq "AMD") { 
        "memTweak=0"
    })
    mport=0
    noLog=true
    rigName=$($Config.WorkerName)
    watchdog=false
    webPort=$($MinerAPIPort)
    useSSL=$($Pools.($_.Algorithm).SSL)
    [$($_.Coin)]
    devices=$(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')
    pool1=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)
    wallet=$($Pools.($_.Algorithm).User)"
                        }
                        Commands = "$ConfigFileName"
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = $Arguments
                        Algorithm  = $_.Algorithm
                        API        = "NanoMiner"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        Fee        = $_.Fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)/#/"
                    }
                }
            }
        }
    }
}
