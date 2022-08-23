using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -ne "NVIDIA" -or $_.OpenCL.DriverVersion -ge "410.48" })) { Return }

$Uri = Switch ($Variables.DriverVersion.OpenCL.NVIDIA ) { 
    { $_ -ge "455.23" } { "https://github.com/nanopool/nanominer/releases/download/v3.6.8/nanominer-windows-3.6.8-cuda11.zip"; Break }
    Default             { "https://github.com/nanopool/nanominer/releases/download/v3.6.8/nanominer-windows-3.6.8.zip" }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nanominer.exe"
$DeviceEnumerator = "Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";    Type = "AMD"; Fee = 0.025; MinMemGB = $MinerPools[0]."Autolykos2".DAGSizeGB;   MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 20); ExcludeGPUArchitecture = @();                Coin = "ERG" } # NBMiner-v42.2 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0]."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @();                Coin = "ETC" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0]."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @();                Coin = "ETH" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0]."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @();                Coin = "ETH" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "FiroPoW";       Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0]."FiroPoW".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); ExcludeGPUArchitecture = @();                Coin = "FIRO" }
    [PSCustomObject]@{ Algorithm = "KawPoW";        Type = "AMD"; Fee = 0.02;  MinMemGB = $MinerPools[0]."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(75, 30); ExcludeGPUArchitecture = @();                Coin = "RVN" } # TeamRedMiner-v0.10.2 is fastest
    [PSCustomObject]@{ Algorithm = "Octopus";       Type = "AMD"; Fee = 0.02;  MinMemGB = 6;                                       MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(125, 0); ExcludeGPUArchitecture = @("CGN4", "Other"); Coin = "CFX" } # NBMiner-v42.2 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0]."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(75, 45); ExcludeGPUArchitecture = @();                Coin = "UBQ" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "VertHash";      Type = "AMD"; Fee = 0.01;  MinMemGB = 3;                                       MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 0);  ExcludeGPUArchitecture = @();                Coin = "VTC" } # SRBMinerMulti-v1.0.2 is fastest

    # [PSCustomObject]@{ Algorithm = "RandomX";   Type = "CPU"; Fee = 0.02; MinerSet = 1; WarmupTimes = @(45, 0); Coin = "XMR" } # Not profitable at all
    [PSCustomObject]@{ Algorithm = "VerusHash"; Type = "CPU"; Fee = 0.02; MinerSet = 0; WarmupTimes = @(45, 0); Coin = "VRSC" }

    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "NVIDIA"; Fee = 0.025; MinMemGB = $MinerPools[0]."Autolykos2".DAGSizeGB;   MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(125, 0); Coin = "ERG" } # Trex-v0.26.5 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0]."EtcHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "ETC" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0]."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "ETH" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0]."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "ETH" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "FiroPoW";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0]."FiroPoW".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "FIRO" }
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; Fee = 0.02;  MinMemGB = $MinerPools[0]."KawPoW".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(75, 0);  Coin = "RVN" } # Trex-v0.26.5 is fastest
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.02;  MinMemGB = 6;                                       MemReserveGB = 0;    MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(125, 0); Coin = "CFX" } # NBMiner-v42.2 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0]."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  Coin = "UBQ" } # PhoenixMiner-v6.2c is fastest
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).Host } | Where-Object { -not $MinerPools[0].($_.Algorithm).SSL }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Select-Object | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB + $_.MemReserveGB
            $ExcludeGPUArchitecture = $_.ExcludeGPUArchitecture

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.MemoryGB -ge $MinMemGB } | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }) { 

                If ($AvailableMiner_Devices.Type -eq "NVIDIA" -and $AvailableMiner_Devices.Model -match "^GTX 1660 SUPER 6GB$" -and $_.Algorithm -match "^KawPoW$|^Octopus$") { Return } # 0 hashrate

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                $Arguments = " -coin $($_.Coin)"
                If (($MinerPools[0].($_.Algorithm).DAGsizeGB -gt 0 -or $_.Algorithm -in @("FiroPoW")) -and $MinerPools[0].($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash")) { $Arguments += " -protocol stratum" }
                $Arguments += " -pool1 $($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).Port)"
                $Arguments += " -wallet $($MinerPools[0].($_.Algorithm).User)"
                $Arguments += " -rigName '$(If ($MinerPools[0].($_.Algorithm).WorkerName) { "$($MinerPools[0].($_.Algorithm).WorkerName)" })'"
                $Arguments += " -rigPassword $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " -rigName $($MinerPools[0].($_.Algorithm).WorkerName)" }
                $Arguments += " -useSSL $("$($MinerPools[0].($_.Algorithm).SSL)".toLower())"
                $Arguments += " -mport 0 -webPort $MinerAPIPort -checkForUpdates false -noLog true -watchdog false"
                $Arguments += " -devices $(($AvailableMiner_Devices | Sort-Object Name -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')"

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                $PrerequisitePath = ""
                $PrerequisiteURI = ""
                If ($_.Algorithm -eq "VertHash" -and -not (Test-Path -Path ".\Bin\$($Name)\VertHash.dat" -ErrorAction SilentlyContinue)) { 
                    If ((Get-Item -Path $Variables.VerthashDatPath).length -eq 1283457024) { 
                        If (Test-Path -Path .\Bin\$($Name) -PathType Container) { 
                            If (Test-Path -Path .\Bin\$($Name) -PathType Container) { 
                                New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath | Out-Null
                            }
                        }
                    }
                    Else { 
                        $PrerequisitePath = $Variables.VerthashDatPath
                        $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                    }
                }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ($Arguments -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    API         = "NanoMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)/#/"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                }
            }
        }
    }
}
