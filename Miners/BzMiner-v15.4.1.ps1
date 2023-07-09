If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -ne "NVIDIA" -or $_.OpenCL.DriverVersion -ge "460.27.03" })) { Return }

$Uri = "https://github.com/bzminer/bzminer/releases/download/v15.4.1/bzminer_v15.4.1_windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\bzminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithms = @("Autolykos2"); Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ergo") }
    [PSCustomObject]@{ Algorithms = @("Blake3");     Type = "AMD"; Fee = 0.005; MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 10); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");    Type = "AMD"; Fee = 0.005; MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("Ethash");     Type = "AMD"; Fee = 0.005; MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ethash") }
    [PSCustomObject]@{ Algorithms = @("IronFish");   Type = "AMD"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ironfish") }
    [PSCustomObject]@{ Algorithms = @("KawPow");     Type = "AMD"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a rvn") }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash"); Type = "AMD"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a kaspa") }
    [PSCustomObject]@{ Algorithms = @("NexaPow");    Type = "AMD"; Fee = 0.02;  MinMemGiB = 3;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a nexa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace");  Type = "AMD"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a octa") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d"); Type = "AMD"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA256dt");   Type = "AMD"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a novo") }
    [PSCustomObject]@{ Algorithms = @("SHA3d");      Type = "AMD"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a kylacoin") }
    [PSCustomObject]@{ Algorithms = @("Skein2");     Type = "AMD"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a woodcoin") }

    [PSCustomObject]@{ Algorithms = @("EtcHash"); Type = "INTEL"; Fee = 0.005;  MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 25); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("Ethash");  Type = "INTEL"; Fee = 0.005;  MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ethash") }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");               Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ergo") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "kHeavyHash"); Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ergo", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "SHA512256d"); Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ergo", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Blake3");                   Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                  Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");        Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a etchash", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "IronFish");      Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a etchash", " --a2 ironfish") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a etchash", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA512256d");    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a etchash", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Ethash");                   Type = "NVIDIA"; Fee = 0.005; MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ethash") }
    [PSCustomObject]@{ Algorithms = @("EtHash", "Blake3");         Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ethash", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("EtHash", "IronFish");       Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ethash", " --a2 ironfish") }
    [PSCustomObject]@{ Algorithms = @("EtHash", "kHeavyHash");     Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ethash", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("EtHash", "SHA512256d");     Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ethash", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("IronFish");                 Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a ironfish") }
    [PSCustomObject]@{ Algorithms = @("KawPow");                   Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a rvn") }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");               Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a kaspa") }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                  Type = "NVIDIA"; Fee = 0.02;  MinMemGiB = 3;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a nexa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace");                Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a octa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "Blake3");      Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a octa", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "IronFish");    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a octa", " --a2 ironfish") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "kHeavyHash");  Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a octa", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "SHA512256d");  Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 40); ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a octa", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");               Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA256dt");                 Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a novo") }
    [PSCustomObject]@{ Algorithms = @("SHA3d");                    Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a kylacoin") }
    [PSCustomObject]@{ Algorithms = @("Skein2");                   Type = "NVIDIA"; Fee = 0.01;  MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludePools = @(@(), @()); ExcludeGPUArchitecture = @(); Arguments = @(" -a woodcoin") }
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

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -GE $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Arguments = "$($_.Arguments[0])"
                $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })$(If ($_.DualMiningIntensity -gt 0) { "-$($_.DualMiningIntensity)" })" -replace ' '

                If ($Algorithm1 -and -not $_.DualMiningIntensity) { 
                    # Allow extra time for auto tuning
                    $_.WarmupTimes[1] = 60
                }

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "cuda", "opencl", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                Switch ($MinerPools[0].($_.Algorithms[0]).Protocol) { 
                    "ethproxy"     { $Arguments += " -p ethproxy"; Break }
                    "ethstratum1"  { $Arguments += " -p ethstratum"; Break }
                    "ethstratum2"  { $Arguments += " -p ethstratum2"; Break }
                    "ethstratumnh" { $Arguments += " -p ethstratum"; Break }
                    Default        { $Arguments += " -p stratum"}
                }
                $Arguments += If ($MinerPools[0].($_.Algorithms[0]).PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                $Arguments += "$($MinerPools[0].($_.Algorithms[0]).Host):$($MinerPools[0].($_.Algorithms[0]).PoolPorts | Select-Object -Last 1)"
                $Arguments += " -w $($MinerPools[0].($_.Algorithms[0]).User)"
                $Arguments += " --pool_password $($MinerPools[0].($_.Algorithms[0]).Pass)$(If ($MinerPools[0].($_.Algorithms[0]).BaseName -eq "ProHashing" -and $_.Algorithms[0] -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[$Index].($_.Algorithms[0]).DAGSizeGiB))" })"
                $Arguments += " -r $($Config.WorkerName)"

                If ($_.Algorithms[1]) {
                    $Arguments += "$($_.Arguments[1])"
                    Switch ($MinerPools[1].($_.Algorithms[1]).Protocol) { 
                        "ethproxy"     { $Arguments += " --p2 ethproxy"; Break }
                        "ethstratum1"  { $Arguments += " --p2 ethstratum"; Break }
                        "ethstratum2"  { $Arguments += " --p2 ethstratum2"; Break }
                        "ethstratumnh" { $Arguments += " --p2 ethstratum"; Break }
                        Default        { $Arguments += " --p2 stratum" }
                    }
                    $Arguments += If ($MinerPools[1].($_.Algorithms[1]).PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                    $Arguments += "$($MinerPools[1].($_.Algorithms[1]).Host):$($MinerPools[1].($_.Algorithms[1]).PoolPorts | Select-Object -Last 1)"
                    $Arguments += " --w2 $($MinerPools[1].($_.Algorithms[1]).User)"
                    $Arguments += " --pool_password2 $($MinerPools[1].($_.Algorithms[1]).Pass)$(If ($MinerPools[1].($_.Algorithms[1]).BaseName -eq "ProHashing" -and $_.Algorithms[1] -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - ($_.MinMemGiB - $MinerPools[$Index].($_.Algorithms[1]).DAGSizeGiB))" })"
                    $Arguments += " --r2 $($Config.WorkerName)"
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Algorithms       = @($_.Algorithms | Select-Object)
                    API              = "BzMiner"
                    Arguments        = ("$Arguments --no_watchdog --http_enabled 1 --http_port $MinerAPIPort $(If ($Devices | Where-Object { $_.State -ne [DeviceState]::Unsupported } | Where-Object { $_.Type -in @("AMD", "INTEL", "NVIDIA") } | Where-Object { $_ -notin $AvailableMiner_Devices }) { "--disable $((($Devices | Where-Object { $_.State -ne [DeviceState]::Unsupported } | Where-Object { $_.Type -in @("AMD", "INTEL", "NVIDIA") } | Where-Object { $_ -notin $AvailableMiner_Devices }).$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0}:0' -f $_ }) -join ' ')" }) " -replace "\s+", " ").trim()
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Fee              = $_.Fee
                    MinerSet         = $_.MinerSet
                    MinerUri         = "http://127.0.0.1:$($MinerAPIPort)/status/"
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