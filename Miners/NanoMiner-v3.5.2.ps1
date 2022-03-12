using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -ne "NVIDIA" -or $_.OpenCL.ComputeCapability -gt 5.0 })) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.0" } { "https://github.com/nanopool/nanominer/releases/download/v3.5.2/nanominer-windows-3.5.2-cuda11.zip"; Break }
    Default           { "https://github.com/nanopool/nanominer/releases/download/v3.5.2/nanominer-windows-3.5.2.zip" }
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nanominer.exe"
$DeviceEnumerator = "Bus_Type_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs 

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";    Type = "AMD"; Fee = 0.05; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(55, 20); Coin = "ERG" } # NBMiner-v40.1 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.01; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(55, 45); Coin = "ETC" } # PhoenixMiner-v6.0c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.01; MinMemGB = 5;  MinerSet = 1; WarmupTimes = @(55, 45); Coin = "ETH" } # PhoenixMiner-v6.0c is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "AMD"; Fee = 0.01; MinMemGB = 2;  MinerSet = 1; WarmupTimes = @(55, 45); Coin = "ETH" } # PhoenixMiner-v6.0c is fastest
    [PSCustomObject]@{ Algorithm = "FiroPoW";       Type = "AMD"; Fee = 0.01; MinMemGB = 5;  MinerSet = 1; WarmupTimes = @(55, 45); Coin = "FIRO" }
    [PSCustomObject]@{ Algorithm = "KawPoW";        Type = "AMD"; Fee = 0.02; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(75, 30); Coin = "RVN" } # TeamRedMiner-v0.9.4.1 is fastest
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "AMD"; Fee = 0.01; MinMemGB = 4;  MinerSet = 1; WarmupTimes = @(55, 45); Coin = "UBQ" } # PhoenixMiner-v6.0c is fastest
    [PSCustomObject]@{ Algorithm = "VertHash";      Type = "AMD"; Fee = 0.01; MinMemGB = 3;  MinerSet = 1; WarmupTimes = @(55, 0);  Coin = "VTC" } # SRBMinerMulti-v0.9.3 is fastest

    # [PSCustomObject]@{ Algorithm = "RandomX";   Type = "CPU"; Fee = 0.02; MinerSet = 1; WarmupTimes = @(45, 0); Coin = "XMR" } # Not profitable at all
    [PSCustomObject]@{ Algorithm = "VerusHash"; Type = "CPU"; Fee = 0.02; MinerSet = 0; WarmupTimes = @(45, 0); Coin = "VRSC" }

    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "NVIDIA"; Fee = 0.05; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(125, 0); Coin = "ERG" } # Trex-v0.25.8 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(55, 0);  Coin = "ETC" } # PhoenixMiner-v6.0c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01; MinMemGB = 5; MinerSet = 1; WarmupTimes = @(55, 0);  Coin = "ETH" } # PhoenixMiner-v6.0c is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01; MinMemGB = 2; MinerSet = 1; WarmupTimes = @(55, 0);  Coin = "ETH" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPoW";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = 5; MinerSet = 1; WarmupTimes = @(75, 0);  Coin = "FIRO" }
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; Fee = 0.02; MinMemGB = 3; MinerSet = 1; WarmupTimes = @(55, 0);  Coin = "RVN" } # Trex-v0.25.8 is fastest
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.02; MinMemGB = 6; MinerSet = 1; WarmupTimes = @(125, 0); Coin = "CFX" } # NBMiner-v40.1 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";      Type = "NVIDIA"; Fee = 0.01; MinMemGB = 4; MinerSet = 1; WarmupTimes = @(55, 0);  Coin = "UBQ" } # PhoenixMiner-v6.0c is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 
                If ($AvailableMiner_Devices.Type -eq "AMD" -and $_.Algorithm -in @("EtcHash", "Ethash", "EthashLowMem", "FiroPoW", "UbqHash") -and $AvailableMiner_Devices.OpenCL.Architecture -in @("gfx930", "gfx1010") -and $Variables.DriverVersion.CIM.AMD -ge "26.20.15015.1007") { Return } # Cannot build binaries for gfx930, gfx1010; https://github.com/nanopool/nanominer/issues/329
                If ($AvailableMiner_Devices.Type -eq "AMD" -and $_.Algorithm -eq "VertHash" -and $AvailableMiner_Devices.OpenCL.Architecture -in @("gfx1010") -and $Variables.DriverVersion.CIM.AMD -ge "26.20.15015.1007") { Return } # VertHash crashing on gfx1010

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                $ConfigFileName = [System.Web.HttpUtility]::UrlEncode("$((@("Config") + @($_.Algorithm) + @($(Get-PoolName $Pools.($_.Algorithm).Name)) + @($Pools.($_.Algorithm).User) + @($Pools.($_.Algorithm).Pass) + @(($AvailableMiner_Devices.Model | Sort-Object -Unique | Sort-Object Name | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model($(($AvailableMiner_Devices | Sort-Object Name | Where-Object Model -EQ $Model).Name -join ';'))" } | Select-Object) -join '-') + @($MinerAPIPort) | Select-Object) -join '-').ini")
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
rigPassword=$($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",1=$((($AvailableMiner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" })
watchdog=false
webPort=$($MinerAPIPort)
useSSL=$($Pools.($_.Algorithm).SSL)

coin=$($_.Coin)
devices=$(($AvailableMiner_Devices | Sort-Object Name -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')
pool1=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)
wallet=$($Pools.($_.Algorithm).User -split '\.' | Select-Object -First 1)
$(If ($Pools.($_.Algorithm).DAGSize -gt 0 -and $Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { "protocol=stratum" } )"
                    }
                }

                If ($_.Algorithm -eq "VertHash" -and ((Get-Item  ".\Bin\$($Name)\VertHash.dat" -ErrorAction Ignore).length -ne 1283457024)) { 
                    If (Test-Path ".\Cache\VertHash.dat" -ErrorAction Ignore) { 
                        New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target ".\Cache\VertHash.dat" -ErrorAction Ignore | Out-Null
                    }
                    Else { 
                        $_.WarmupTimes[0] += 600 # Allow 10 minutes to generate verthash.dat file
                    }
                }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
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
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
