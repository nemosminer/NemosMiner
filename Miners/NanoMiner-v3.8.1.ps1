If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -ne "NVIDIA" -or $_.OpenCL.DriverVersion -ge "455.23" })) { Return }

$Uri = "https://github.com/nanopool/nanominer/releases/download/v3.8.1/nanominer-windows-3.8.1.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\nanominer.exe"
$DeviceEnumerator = "Slot"

$Algorithms = [PSCustomObject[]]@(
  # [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Type = "AMD"; Fee = 0.025; MinMemGiB = 1.08; Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 10); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Autolykos") } # NBMiner-v42.3 is fastest
  # [PSCustomObject]@{ Algorithms = @("Autolykos2", "kHeavyHash");   Type = "AMD"; Fee = 0.025; MinMemGiB = 1.24; Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 10); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Autolykos", " -algo Kaspa") } # NBMiner-v42.3 is fastest
  # [PSCustomObject]@{ Algorithms = @("EtcHash");                    Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Etchash") } # PhoenixMiner-v6.2c is fastest
  # [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Etchash"," -algo Kaspa") } # PhoenixMiner-v6.2c is fastest
  # [PSCustomObject]@{ Algorithms = @("Ethash");                     Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash") } # PhoenixMiner-v6.2c is fastest
  # [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash"," -algo Kaspa") } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");               Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash") } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "kHeavyHash"); Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash"," -algo Kaspa") } # PhoenixMiner-v6.2c is fastest
  # [PSCustomObject]@{ Algorithms = @("EvrProgPow");                 Type = "AMD"; Fee = 0.02;  MinMemGiB = 1.08; Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Evrprogpow") }
  # [PSCustomObject]@{ Algorithms = @("FiroPow");                    Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo FiroPow") }
  # [PSCustomObject]@{ Algorithms = @("KawPow");                     Type = "AMD"; Fee = 0.02;  MinMemGiB = 1.08; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@("HashCryptos", "MiningDutch", "ProHashing"), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -algo KawPow") } # TeamRedMiner-v0.10.12 is fastest
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Type = "AMD"; Fee = 0.02;  MinMemGiB = 2;    Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Kaspa") }
  # [PSCustomObject]@{ Algorithms = @("UbqHash");                    Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ubqhash") } # PhoenixMiner-v6.2c is fastest
    [PSCustomObject]@{ Algorithms = @("VertHash");                   Type = "AMD"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100 -memTweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @(); Arguments = @(" -algo Verthash") }

#   [PSCustomObject]@{ Algorithms = @("Randomx");   Type = "CPU"; Fee = 0.02; Minerset = 3; WarmupTimes = @(45, 0); ExcludePools = @(@(), @()); Arguments = @(" -algo Randomx") } # ASIC
#   [PSCustomObject]@{ Algorithms = @("VerusHash"); Type = "CPU"; Fee = 0.02; Minerset = 2; WarmupTimes = @(45, 0); ExcludePools = @(@(), @()); Arguments = @(" -algo Verushash") } # https://github.com/nanopool/nanominer/issues/389

  # [PSCustomObject]@{ Algorithms = @("EtcHash");                    Type = "INTEL"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 45); ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Etchash") }
  # [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Type = "INTEL"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(45, 45); ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Etchash", " -algo Kaspa") }
  # [PSCustomObject]@{ Algorithms = @("Ethash");                     Type = "INTEL"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash") }
  # [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Type = "INTEL"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash", " -algo Kaspa") }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");               Type = "INTEL"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash") }
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "kHeavyHash"); Type = "INTEL"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ethash"," -algo Kaspa") }
  # [PSCustomObject]@{ Algorithms = @("EvrProgPow");                 Type = "INTEL"; Fee = 0.02;  MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Evrprogpow") }
  # [PSCustomObject]@{ Algorithms = @("KawPow");                     Type = "INTEL"; Fee = 0.02;  MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@("HashCryptos"), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -algo KawPow") } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Type = "INTEL"; Fee = 0.02;  MinMemGiB = 2;    Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Kaspa") }
  # [PSCustomObject]@{ Algorithms = @("Octopus");                    Type = "INTEL"; Fee = 0.02;  MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Octopus") } # NBMiner-v42.3 is faster
  # [PSCustomObject]@{ Algorithms = @("UbqHash");                    Type = "INTEL"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; WarmupTimes = @(75, 45); ExcludePools = @(@(), @());              ExcludeGPUArchitecture = @(); Arguments = @(" -algo Ubqhash") }

  # [PSCustomObject]@{ Algorithms = @("Autolykos2");                 Type = "NVIDIA"; Fee = 0.025; MinMemGiB = 1.08; Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @();        Arguments = @(" -algo Autolykos") } # Trex-v0.26.8 is fastest
  # [PSCustomObject]@{ Algorithms = @("Autolykos2", "kHeavyHash");   Type = "NVIDIA"; Fee = 0.025; MinMemGiB = 1.24; Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @();        Arguments = @(" -algo Autolykos", " -algo Kaspa") } # Trex-v0.26.8 is fastest
  # [PSCustomObject]@{ Algorithms = @("EtcHash");                    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @();        Arguments = @(" -algo Etchash") } # PhoenixMiner-v6.2c is fastest
  # [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");      Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @();        Arguments = @(" -algo Etchash", " -algo Kaspa") } # PhoenixMiner-v6.2c is fastest
  # [PSCustomObject]@{ Algorithms = @("Ethash");                     Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @("Other"); Arguments = @(" -algo Ethash") } # PhoenixMiner-v6.2c is fastest
  # [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");       Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @("Other"); Arguments = @(" -algo Ethash", " -algo Kaspa") } # PhoenixMiner-v6.2c is fastest
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem");               Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @("Other"); Arguments = @(" -algo Ethash") } # TTMiner-v5.0.3 is fastest
#   [PSCustomObject]@{ Algorithms = @("EthashLowMem", "kHeavyHash"); Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @("Other"); Arguments = @(" -algo Ethash", " -algo Kaspa") } # TTMiner-v5.0.3 is fastest
  # [PSCustomObject]@{ Algorithms = @("EvrProgPow");                 Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = 1.08; Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @();        Arguments = @(" -algo Evrprogpow") }
  # [PSCustomObject]@{ Algorithms = @("FiroPow");                    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @();        Arguments = @(" -algo FiroPow") }
  # [PSCustomObject]@{ Algorithms = @("KawPow");                     Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = 1.08; MinerSet = 0; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@("HashCryptos", "MiningDutch", "ProHashing"), @()); ExcludeGPUArchitecture = @();        Arguments = @(" -algo KawPow") } # Trex-v0.26.8 is fastest
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");                 Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = 2;    Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @();        Arguments = @(" -algo Kaspa") }
  # [PSCustomObject]@{ Algorithms = @("Octopus");                    Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = 1.08; Minerset = 2; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @();        Arguments = @(" -algo Octopus") } # NBMiner-v42.3 is faster
  # [PSCustomObject]@{ Algorithms = @("UbqHash");                    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 1; Tuning = " -coreClocks +20 -memClocks +100"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @());                                           ExcludeGPUArchitecture = @();        Arguments = @(" -algo Ubqhash") } # PhoenixMiner-v6.2c is fastest
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).PoolPorts -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).PoolPorts) }
$Algorithms = $Algorithms | Where-Object { $Config.SSL -ne "Always" -or ($MinerPools[0].($_.Algorithms[0]).SSLSelfSignedCertificate -eq $false -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).SSLSelfSignedCertificate -eq $false)) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0].($_.Algorithms[0]).BaseName -notin $_.ExcludePools[0] -and (-not $_.Algorithms[1] -or $MinerPools[1].($_.Algorithms[1]).BaseName -notin $_.ExcludePools[1]) }

If ($Algorithms) { 

    $Algorithms | Where-Object MinMemGiB | ForEach-Object { 
        $_.MinMemGiB += $MinerPools[0].($_.Algorithms[0]).DAGSizeGiB
    }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $MinMemGiB = $_.MinMemGiB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or $_.MemoryGiB -ge $MinMemGiB } | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Arguments = ""
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })" -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algorithm") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Index = 0
                ForEach ($Algorithm in $_.Algorithms) { 

                    $WorkerName = If ($MinerPools[$Index].$Algorithm.WorkerName) { "$($MinerPools[$Index].$Algorithm.WorkerName)" } Else { $MinerPools[$Index].$Algorithm.User -split "\." | Select-Object -Last 1 }

                    $Arguments += "$($_.Arguments[$Index])"
                    $Arguments += If ($MinerPools[$Index].$Algorithm.PoolPorts[1] -and $MinerPools[$Index].$Algorithm.SSLSelfSignedCertificate -eq $false) { " -pool1 $($MinerPools[$Index].$Algorithm.Host):$($MinerPools[$Index].$Algorithm.PoolPorts[1])" } Else { " -pool1 $($MinerPools[$Index].$Algorithm.Host):$($MinerPools[$Index].$Algorithm.PoolPorts[0]) -useSSL false" }
                    $Arguments += " -wallet $($MinerPools[$Index].$Algorithm.User -replace "\.$WorkerName")"
                    $Arguments += " -rigName '$WorkerName'"
                    $Arguments += " -rigPassword $($MinerPools[$Index].$Algorithm.Pass)$(If ($MinerPools[$Index].$Algorithm.BaseName -eq "ProHashing" -and $_.Algorithms[$Index] -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[0].$Algorithm.DAGSizeGiB))" })"

                    $Index ++
                }
                Remove-Variable Algorithm

                $Arguments += " -mport 0 -webPort $MinerAPIPort -checkForUpdates false -noLog true -watchdog false"
                $Arguments += " -devices $(($AvailableMiner_Devices | Sort-Object Name -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')"

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                If ($_.Algorithms[$Index] -eq "VertHash") { 
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
                    Algorithms       = @($_.Algorithms | Select-Object)
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