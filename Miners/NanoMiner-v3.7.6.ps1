If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -ne "NVIDIA" -or $_.OpenCL.DriverVersion -ge "410.48" })) { Return }

$Uri = Switch ($Variables.DriverVersion.OpenCL.NVIDIA ) { 
    { $_ -ge "455.23" } { "https://github.com/nanopool/nanominer/releases/download/v3.7.6/nanominer-windows-3.7.6-cuda11.zip"; Break }
    Default             { "https://github.com/nanopool/nanominer/releases/download/v3.7.6/nanominer-windows-3.7.6.zip" }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nanominer.exe"
$DeviceEnumerator = "Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";    Type = "AMD"; Fee = 0.025; MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB + 0.42;   Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 20); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Autolykos" } # NBMiner-v42.3 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0].EtcHash.DAGSizeGB + 0.42;      Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Etchash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.42; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "EvrProgPow";    Type = "AMD"; Fee = 0.02;  MinMemGB = $MinerPools[0].EvrProgPow.DAGSizeGB + 0.42;   Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Evrprogpow" }
    [PSCustomObject]@{ Algorithm = "FiroPow";       Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0].FiroPow.DAGSizeGB + 0.42;      Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 45); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo FiroPow" }
    [PSCustomObject]@{ Algorithm = "KawPow";        Type = "AMD"; Fee = 0.02;  MinMemGB = $MinerPools[0].KawPow.DAGSizeGB + 0.42;       Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(75, 30); ExcludePool = @("MiningDutch", "ProHashing"); ExcludeGPUArchitecture = @(); Arguments = " -algo KawPow" } # TeamRedMiner-v0.10.7 is fastest
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB + 0.42;      Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(75, 45); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Ubqhash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "VertHash";      Type = "AMD"; Fee = 0.01;  MinMemGB = 3;                                            Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(55, 0);  ExcludePool = @("ZPool");                     ExcludeGPUArchitecture = @(); Arguments = " -algo Verthash" } # SSL @ ZergPool is not supported

    [PSCustomObject]@{ Algorithm = "Randomx";   Type = "CPU"; Fee = 0.02; Minerset = 3; WarmupTimes = @(45, 0); Arguments = " -algo Randomx" } # ASIC
    [PSCustomObject]@{ Algorithm = "VerusHash"; Type = "CPU"; Fee = 0.02; Minerset = 2; WarmupTimes = @(45, 0); Arguments = " -algo Verushash" }

    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "NVIDIA"; Fee = 0.025; MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB + 0.42;   Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(125, 0); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Autolykos" } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0].EtcHash.DAGSizeGB + 0.42;      Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Etchash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.42; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "EvrProgPow";   Type = "NVIDIA"; Fee = 0.02;  MinMemGB = $MinerPools[0].EvrProgPow.DAGSizeGB + 0.42;   Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 45); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Evrprogpow" }
    [PSCustomObject]@{ Algorithm = "FiroPow";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0].FiroPow.DAGSizeGB + 0.42;      MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo FiroPow"}
    [PSCustomObject]@{ Algorithm = "KawPow";       Type = "NVIDIA"; Fee = 0.02;  MinMemGB = $MinerPools[0].KawPow.DAGSizeGB + 0.42;       MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(75, 0);  ExcludePool = @("MiningDutch", "ProHashing"); ExcludeGPUArchitecture = @(); Arguments = " -algo KawPow" } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.02;  MinMemGB = $MinerPools[0].Octopus.DAGSizeGB + 0.42;      Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(125, 0); ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Octopus" } # NBMiner-v42.3 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";      Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB + 0.42;      Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(55, 0);  ExcludePool = @();                            ExcludeGPUArchitecture = @(); Arguments = " -algo Ubqhash" } # PhoenixMiner-v6.2c is fastest

    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "INTEL"; Fee = 0.01;  MinMemGB = $MinerPools[0].EtcHash.DAGSizeGB + 0.42;      Minerset = 2; WarmupTimes = @(55, 45); ExcludePool = @(); ExcludeGPUArchitecture = @(); Arguments = " -algo Etchash" }
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "INTEL"; Fee = 0.01;  MinMemGB = $MinerPools[0].Ethash.DAGSizeGB + 0.42;       Minerset = 2; WarmupTimes = @(55, 0);  ExcludePool = @(); ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "INTEL"; Fee = 0.01;  MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB + 0.42; Minerset = 2; WarmupTimes = @(55, 0);  ExcludePool = @(); ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" }
    [PSCustomObject]@{ Algorithm = "EvrProgPow";   Type = "INTEL"; Fee = 0.02;  MinMemGB = $MinerPools[0].EvrProgPow.DAGSizeGB + 0.42;   Minerset = 2; WarmupTimes = @(55, 0);  ExcludePool = @(); ExcludeGPUArchitecture = @(); Arguments = " -algo Evrprogpow" }
    [PSCustomObject]@{ Algorithm = "KawPow";       Type = "INTEL"; Fee = 0.02;  MinMemGB = $MinerPools[0].KawPow.DAGSizeGB + 0.42;       Minerset = 2; WarmupTimes = @(75, 0);  ExcludePool = @(); ExcludeGPUArchitecture = @(); Arguments = " -algo KawPow" } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "INTEL"; Fee = 0.02;  MinMemGB = $MinerPools[0].Octopus.DAGSizeGB + 0.42;      Minerset = 2; WarmupTimes = @(125, 0); ExcludePool = @(); ExcludeGPUArchitecture = @(); Arguments = " -algo Octopus" } # NBMiner-v42.3 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";      Type = "INTEL"; Fee = 0.01;  MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB + 0.42;      Minerset = 2; WarmupTimes = @(75, 45); ExcludePool = @(); ExcludeGPUArchitecture = @(); Arguments = " -algo Ubqhash" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts } ) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } | ForEach-Object { 

            $Arguments = $_.Arguments
            $MinMemGB = $_.MinMemGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.MemoryGB -ge $MinMemGB } | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                If ($MinerPools[0].($_.Algorithm).PoolPorts[1] -and $_.Algorithm -ne "VertHash") { # https://github.com/nanopool/nanominer/issues/381
                    $Arguments += " -pool1 $($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[1])"
                    If ($MinerPools[0].($_.Algorithm).PoolPorts[0]) { $Arguments += " -pool2 $($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0])" }
                }
                Else { $Arguments += " -pool1 $($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) -useSSL false" }

                If (($MinerPools[0].($_.Algorithm).DAGsizeGB -gt 0 -or $_.Algorithm -in @("VertHash")) -and $MinerPools[0].($_.Algorithm).BaseName -in @("ZergPool", "Zpool")) { $Arguments += " -protocol JSON-RPC" }
                ElseIf ($MinerPools[0].($_.Algorithm).DAGsizeGB -gt 0) { $Arguments += " -protocol stratum" }

                $Arguments += " -wallet $($MinerPools[0].($_.Algorithm).User)"
                $Arguments += " -rigName '$(If ($MinerPools[0].($_.Algorithm).WorkerName) { "$($MinerPools[0].($_.Algorithm).WorkerName)" })'"
                $Arguments += " -rigPassword $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGB - $MinerPools[0].($_.Algorithm).DAGSizeGB))" })"
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " -rigName $($MinerPools[0].($_.Algorithm).WorkerName)" }
                $Arguments += " -mport 0 -webPort $MinerAPIPort -checkForUpdates false -noLog true -watchdog false"
                $Arguments += " -devices $(($AvailableMiner_Devices | Sort-Object Name -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')"

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $Arguments += $_.Tuning }

                If ($_.Algorithm -eq "VertHash") { 
                    If ((Get-Item -Path $Variables.VerthashDatPath).length -eq 1283457024) { 
                        New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath | Out-Null
                    }
                    Else { 
                        $PrerequisitePath = $Variables.VerthashDatPath
                        $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                    }
                }
                Else { 
                    $PrerequisitePath = ""
                    $PrerequisiteURI = ""
                }

                [PSCustomObject]@{ 
                    Algorithms       = @($_.Algorithm)
                    API              = "NanoMiner"
                    Arguments        = ($Arguments -replace "\s+", " ").trim()
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Fee              = $_.Fee
                    MinerSet         = $_.MinerSet
                    MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/#/"
                    Name             = $Miner_Name
                    Path             = $Path
                    Port             = $MinerAPIPort
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                    Type             = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                    URI              = $Uri
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
