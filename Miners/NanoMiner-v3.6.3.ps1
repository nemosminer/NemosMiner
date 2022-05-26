using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -ne "NVIDIA" -or $_.OpenCL.ComputeCapability -gt 5.0 })) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.0" } { "https://github.com/nanopool/nanominer/releases/download/v3.6.3/nanominer-windows-3.6.3-cuda11.zip"; Break }
    Default           { "https://github.com/nanopool/nanominer/releases/download/v3.6.3/nanominer-windows-3.6.3.zip" }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nanominer.exe"
$DeviceEnumerator = "Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";    Type = "AMD"; Fee = 0.025; MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 20); Coin = "ERG" } # NBMiner-v42.2 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.01;  MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); Coin = "ETC" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.01;  MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); Coin = "ETH" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "AMD"; Fee = 0.01;  MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); Coin = "ETH" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "FiroPoW";       Type = "AMD"; Fee = 0.01;  MinMemGB = 5;                               MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); Coin = "FIRO" }
    [PSCustomObject]@{ Algorithm = "KawPoW";        Type = "AMD"; Fee = 0.02;  MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(75, 30); Coin = "RVN" } # TeamRedMiner-v0.10.0 is fastest
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "AMD"; Fee = 0.01;  MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(75, 45); Coin = "UBQ" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "VertHash";      Type = "AMD"; Fee = 0.01;  MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 0);  Coin = "VTC" } # SRBMinerMulti-v0.9.5 is fastest

    # [PSCustomObject]@{ Algorithm = "RandomX";   Type = "CPU"; Fee = 0.02; MinerSet = 1; WarmupTimes = @(45, 0); Coin = "XMR" } # Not profitable at all
    [PSCustomObject]@{ Algorithm = "VerusHash"; Type = "CPU"; Fee = 0.02; MinerSet = 0; WarmupTimes = @(45, 0); Coin = "VRSC" }

    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "NVIDIA"; Fee = 0.025; MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(125, 0); Coin = "ERG" } # Trex-v0.26.4 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "ETC" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "ETH" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "ETH" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPoW";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 5;                               MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "FIRO" }
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; Fee = 0.02;  MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(75, 0);  Coin = "RVN" } # Trex-v0.26.4 is fastest
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.02;  MinMemGB = 6;                               MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(125, 0); Coin = "CFX" } # NBMiner-v42.2 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "UBQ" } # PhoenixMiner-v6.2c is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).SSL -eq $false }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB + $_.MemReserveGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.MemoryGB -ge $MinMemGB }) { 

                If ($AvailableMiner_Devices.Type -eq "NVIDIA" -and $AvailableMiner_Devices.Model -match "^GTX 1660 SUPER 6GB$" -and $_.Algorithm -eq "Octopus") { Return } # 0 hashrate

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                $Arguments = "-mport 0 -webPort $MinerAPIPort -checkForUpdates false -noLog true -watchdog false"
                $Arguments += " -useSSL $("$($Pools.($_.Algorithm).SSL)".toLower())"
                $Arguments += " -rigName $($Config.WorkerName) -rigPassword $($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$(((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB) * 1GB / 1000000000)" })"
                $Arguments += " -devices $(($AvailableMiner_Devices | Sort-Object Name -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')"

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                $Arguments += " -coin $($_.Coin) -pool1 $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) -wallet $($Pools.($_.Algorithm).User -split '\.' | Select-Object -First 1)$(If (($Pools.($_.Algorithm).DAGsizeGB -gt 0 -or $_.Algorithm -in @("FiroPoW")) -and $Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash")) { " -protocol stratum" } )"

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
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = $Arguments
                    Algorithm   = ($_.Algorithm -replace "\s+", " ").trim()
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
