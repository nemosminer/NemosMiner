If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -ne "NVIDIA" -or $_.OpenCL.DriverVersion -ge "410.48" })) { Return }

$Uri = "https://github.com/nanopool/nanominer/releases/download/v3.8.0/nanominer-windows-3.8.0.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nanominer.exe"
$DeviceEnumerator = "Slot"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";    Type = "AMD"; Fee = 0.025; MinMemGiB = $MinerPools[0].Autolykos2.DAGSizeGiB + 1.08;   Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 10); ExcludePool = @();                                           ExcludeGPUArchitecture = @(); Arguments = " -algo Autolykos" } # NBMiner-v42.3 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.01;  MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + 1.08;      Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePool = @();                                           ExcludeGPUArchitecture = @(); Arguments = " -algo Etchash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.01;  MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.08;       Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePool = @();                                           ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "AMD"; Fee = 0.01;  MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 1.08; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePool = @();                                           ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "EvrProgPow";    Type = "AMD"; Fee = 0.02;  MinMemGiB = $MinerPools[0].EvrProgPow.DAGSizeGiB + 1.08;   Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePool = @();                                           ExcludeGPUArchitecture = @(); Arguments = " -algo Evrprogpow" }
    [PSCustomObject]@{ Algorithm = "FiroPow";       Type = "AMD"; Fee = 0.01;  MinMemGiB = $MinerPools[0].FiroPow.DAGSizeGiB + 1.08;      Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePool = @();                                           ExcludeGPUArchitecture = @(); Arguments = " -algo FiroPow" }
    [PSCustomObject]@{ Algorithm = "KawPow";        Type = "AMD"; Fee = 0.02;  MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 1.08;       Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePool = @("HashCryptos", "MiningDutch", "ProHashing"); ExcludeGPUArchitecture = @(); Arguments = " -algo KawPow" } # TeamRedMiner-v0.10.12 is fastest
    [PSCustomObject]@{ Algorithm = "kHeavyHash";    Type = "AMD"; Fee = 0.02;  MinMemGiB = 2;                                             Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePool = @();                                           ExcludeGPUArchitecture = @(); Arguments = " -algo Kaspa" }
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "AMD"; Fee = 0.01;  MinMemGiB = $MinerPools[0].UbqHash.DAGSizeGiB + 1.08;      Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePool = @();                                           ExcludeGPUArchitecture = @(); Arguments = " -algo Ubqhash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "VertHash";      Type = "AMD"; Fee = 0.01;  MinMemGiB = 3;                                             Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePool = @();                                           ExcludeGPUArchitecture = @(); Arguments = " -algo Verthash" }

#   [PSCustomObject]@{ Algorithm = "Randomx";   Type = "CPU"; Fee = 0.02; Minerset = 3; WarmupTimes = @(45, 0); Arguments = " -algo Randomx" } # ASIC
    [PSCustomObject]@{ Algorithm = "VerusHash"; Type = "CPU"; Fee = 0.02; Minerset = 2; WarmupTimes = @(45, 0); Arguments = " -algo Verushash" }

    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "INTEL"; Fee = 0.01;  MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + 1.08;      Minerset = 2; WarmupTimes = @(45, 45); ExcludePool = @();              ExcludeGPUArchitecture = @(); Arguments = " -algo Etchash" }
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "INTEL"; Fee = 0.01;  MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.08;       Minerset = 2; WarmupTimes = @(45, 0);  ExcludePool = @();              ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" }
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "INTEL"; Fee = 0.01;  MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 1.08; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePool = @();              ExcludeGPUArchitecture = @(); Arguments = " -algo Ethash" }
    [PSCustomObject]@{ Algorithm = "EvrProgPow";   Type = "INTEL"; Fee = 0.02;  MinMemGiB = $MinerPools[0].EvrProgPow.DAGSizeGiB + 1.08;   Minerset = 2; WarmupTimes = @(45, 0);  ExcludePool = @();              ExcludeGPUArchitecture = @(); Arguments = " -algo Evrprogpow" }
    [PSCustomObject]@{ Algorithm = "KawPow";       Type = "INTEL"; Fee = 0.02;  MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 1.08;       Minerset = 2; WarmupTimes = @(45, 0);  ExcludePool = @("HashCryptos"); ExcludeGPUArchitecture = @(); Arguments = " -algo KawPow" } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithm = "kHeavyHash";   Type = "INTEL"; Fee = 0.02;  MinMemGiB = 2;                                             Minerset = 2; WarmupTimes = @(45, 0);  ExcludePool = @();              ExcludeGPUArchitecture = @(); Arguments = " -algo Kaspa" }
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "INTEL"; Fee = 0.02;  MinMemGiB = $MinerPools[0].Octopus.DAGSizeGiB + 1.08;      Minerset = 2; WarmupTimes = @(45, 0);  ExcludePool = @();              ExcludeGPUArchitecture = @(); Arguments = " -algo Octopus" } # NBMiner-v42.3 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";      Type = "INTEL"; Fee = 0.01;  MinMemGiB = $MinerPools[0].UbqHash.DAGSizeGiB + 1.08;      Minerset = 2; WarmupTimes = @(75, 45); ExcludePool = @();              ExcludeGPUArchitecture = @(); Arguments = " -algo Ubqhash" }

    [PSCustomObject]@{ Algorithm = "Autolykos2";   Type = "NVIDIA"; Fee = 0.025; MinMemGiB = $MinerPools[0].Autolykos2.DAGSizeGiB + 1.08;   Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePool = @();                                           ExcludeGPUArchitecture = @();        Arguments = " -algo Autolykos" } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = $MinerPools[0].EtcHash.DAGSizeGiB + 1.08;      Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePool = @();                                           ExcludeGPUArchitecture = @();        Arguments = " -algo Etchash" } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = $MinerPools[0].Ethash.DAGSizeGiB + 1.08;       MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePool = @();                                           ExcludeGPUArchitecture = @("Other"); Arguments = " -algo Ethash" } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = $MinerPools[0].EthashLowMem.DAGSizeGiB + 1.08; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePool = @();                                           ExcludeGPUArchitecture = @("Other"); Arguments = " -algo Ethash" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "EvrProgPow";   Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = $MinerPools[0].EvrProgPow.DAGSizeGiB + 1.08;   Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePool = @();                                           ExcludeGPUArchitecture = @();        Arguments = " -algo Evrprogpow" }
    [PSCustomObject]@{ Algorithm = "FiroPow";      Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = $MinerPools[0].FiroPow.DAGSizeGiB + 1.08;      MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePool = @();                                           ExcludeGPUArchitecture = @();        Arguments = " -algo FiroPow"}
    [PSCustomObject]@{ Algorithm = "KawPow";       Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = $MinerPools[0].KawPow.DAGSizeGiB + 1.08;       MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePool = @("HashCryptos", "MiningDutch", "ProHashing"); ExcludeGPUArchitecture = @();        Arguments = " -algo KawPow" } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithm = "kHeavyHash";   Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = 2;                                             Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePool = @();                                           ExcludeGPUArchitecture = @();        Arguments = " -algo Kaspa" }
    [PSCustomObject]@{ Algorithm = "Octopus";      Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = $MinerPools[0].Octopus.DAGSizeGiB + 1.08;      Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePool = @();                                           ExcludeGPUArchitecture = @();        Arguments = " -algo Octopus" } # NBMiner-v42.3 is faster
    [PSCustomObject]@{ Algorithm = "UbqHash";      Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = $MinerPools[0].UbqHash.DAGSizeGiB + 1.08;      Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePool = @();                                           ExcludeGPUArchitecture = @();        Arguments = " -algo Ubqhash" } # PhoenixMiner-v6.2c is fastest
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }
$Algorithms = $Algorithms | Where-Object { $Config.SSL -ne "Always" -or $MinerPools[0].($_.Algorithm).SSLSelfSignedCertificate -eq $false }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } 

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $Arguments = $_.Arguments
            $MinMemGiB = $_.MinMemGiB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.MemoryGiB -ge $MinMemGiB } | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)" -replace ' '
                $WorkerName = If ($MinerPools[0].($_.Algorithm).WorkerName) { "$($MinerPools[0].($_.Algorithm).WorkerName)" } Else { $MinerPools[0].($_.Algorithm).User -split "\." | Select-Object -Last 1 }
                $Wallet = $MinerPools[0].($_.Algorithm).User -replace "\.$WorkerName"

                If ($MinerPools[0].($_.Algorithm).PoolPorts[1] -and $MinerPools[0].($_.Algorithm).SSLSelfSignedCertificate -eq $false) { 
                    $Arguments += " -pool1 $($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[1])"
                }
                Else { $Arguments += " -pool1 $($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts[0]) -useSSL false" }
                $Arguments += " -wallet $Wallet"
                $Arguments += " -rigName '$WorkerName'"
                $Arguments += " -rigPassword $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].($_.Algorithm).DAGSizeGiB))" })"
                $Arguments += " -mport 0 -webPort $MinerAPIPort -checkForUpdates false -noLog true -watchdog false"
                $Arguments += " -devices $(($AvailableMiner_Devices | Sort-Object Name -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')"

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                If ($_.Algorithm -eq "VertHash") { 
                    If ((Get-Item -Path $Variables.VerthashDatPath -ErrorAction Ignore).length -eq 1283457024) { 
                        If (-not (Get-Item -Path ".\Bin\$($Name)\VertHash.dat" -ErrorAction Ignore).length -eq 1283457024) { 
                            New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath -Force | Out-Null
                        }
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
                    Type             = $_.Type
                    URI              = $Uri
                    WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}