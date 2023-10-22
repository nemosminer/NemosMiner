<#
Copyright (c) 2018-2023 Nemo, MrPlus & UselessGuru

NemosMiner is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

NemosMiner is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
#>

<#
Product:        NemosMiner
Version:        5.0.1.5
Version date:   2023/10/22
#>

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -in @("AMD", "INTEL") -or ($_.OpenCL.ComputeCapability -ge "5.0" -and $_.OpenCL.DriverVersion -ge "460.27.03" ) })) { Return }

$URI = "https://bzminer.com/downloads/bzminer_v17.0.1b1_windows.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\bzminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = @(
    # https://github.com/bzminer/bzminer/issues/279???
    [PSCustomObject]@{ Algorithms = @("Autolykos2");         Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a ergo") }
    [PSCustomObject]@{ Algorithms = @("Blake3");             Type = "AMD"; Fee = @(0.005);      MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 10); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");            Type = "AMD"; Fee = @(0.005);      MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("GCN4"); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("Ethash");             Type = "AMD"; Fee = @(0.005);      MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("GCN4"); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a ethash") }
    [PSCustomObject]@{ Algorithms = @("Ethash3B");           Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @("GCN4"); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rethereum") }
    [PSCustomObject]@{ Algorithms = @("Ethash3B", "Blake3"); Type = "AMD"; Fee = @(0.01, 0.01); MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @("GCN4"); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rethereum", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("IronFish");           Type = "AMD"; Fee = @(0.01);       MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@("Nicehash"), @()); Arguments = @(" -a ironfish") }# https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("KawPow");             Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1.08; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @("GCN4"); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rvn") } # https://github.com/bzminer/bzminer/issues/264
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");         Type = "AMD"; Fee = @(0.01);       MinMemGiB = 2;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a kaspa") }
    [PSCustomObject]@{ Algorithms = @("NexaPow");            Type = "AMD"; Fee = @(0.02);       MinMemGiB = 3;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a nexa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace");          Type = "AMD"; Fee = @(0.01);       MinMemGiB = 3;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a octa") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");         Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA256dt");           Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a novo") }
    [PSCustomObject]@{ Algorithms = @("SHA3d");              Type = "AMD"; Fee = @(0.01);       MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a kylacoin") }
    [PSCustomObject]@{ Algorithms = @("Skein2");             Type = "AMD"; Fee = @(0.01);       MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @();       ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a woodcoin") }

    [PSCustomObject]@{ Algorithms = @("Blake3");     Type = "INTEL"; Fee = @(0.005); MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");    Type = "INTEL"; Fee = @(0.005); MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 25); ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("Ethash");     Type = "INTEL"; Fee = @(0.005); MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a ethash") }
    [PSCustomObject]@{ Algorithms = @("Ethash3B");   Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rethereum") }
    [PSCustomObject]@{ Algorithms = @("IronFish");   Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@("Nicehash"), @()); Arguments = @(" -a ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("KawPow");     Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a rvn") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d"); Type = "INTEL"; Fee = @(0.01);  MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = ""; ExcludePools = @(@(), @());           Arguments = @(" -a radiant") }

    [PSCustomObject]@{ Algorithms = @("Autolykos2");               Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a ergo") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "kHeavyHash"); Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @("ProHashing")); Arguments = @(" -a ergo", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("Autolykos2", "SHA512256d"); Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a ergo", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Blake3");                   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash");                  Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.08; Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a etchash") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "Blake3");        Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a etchash", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "IronFish");      Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @("Nicehash"));   Arguments = @(" -a etchash", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("EtcHash", "kHeavyHash");    Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @("ProHashing")); Arguments = @(" -a etchash", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("EtcHash", "SHA512256d");    Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a etchash", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Ethash");                   Type = "NVIDIA"; Fee = @(0.005, 0.005); MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a ethash") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "Blake3");         Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a ethash", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "IronFish");       Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @("Nicehash"));   Arguments = @(" -a ethash", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("Ethash", "kHeavyHash");     Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a ethash", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("Ethash", "SHA512256d");     Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a ethash", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("Ethash3B");                 Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 20); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a rethereum") }
    [PSCustomObject]@{ Algorithms = @("Ethash3B", "Blake3");       Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.24; Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a rethereum", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("IronFish");                 Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@("Nicehash"), @());   Arguments = @(" -a ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("KawPow");                   Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1.08; MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a rvn") }
    [PSCustomObject]@{ Algorithms = @("kHeavyHash");               Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 2;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a kaspa") }
    [PSCustomObject]@{ Algorithms = @("NexaPow");                  Type = "NVIDIA"; Fee = @(0.02, 0.01);   MinMemGiB = 3;    MinerSet = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a nexa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace");                Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a octa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "Blake3");      Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a octa", " --a2 alph") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "IronFish");    Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @("Nicehash"));   Arguments = @(" -a octa", " --a2 ironfish") } # https://github.com/bzminer/bzminer/issues/260
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "kHeavyHash");  Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a octa", " --a2 kaspa") }
    [PSCustomObject]@{ Algorithms = @("OctaSpace", "SHA512256d");  Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 3;    Minerset = 2; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 60); ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @("ProHashing")); Arguments = @(" -a octa", " --a2 radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA512256d");               Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a radiant") }
    [PSCustomObject]@{ Algorithms = @("SHA256dt");                 Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a novo") }
    [PSCustomObject]@{ Algorithms = @("SHA3d");                    Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 1;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "^MX[1|2]\d+"; ExcludePools = @(@(), @());             Arguments = @(" -a kylacoin") }
    [PSCustomObject]@{ Algorithms = @("Skein2");                   Type = "NVIDIA"; Fee = @(0.01, 0.01);   MinMemGiB = 2;    Minerset = 1; Tuning = " --oc_mem_tweak 2"; WarmupTimes = @(45, 0);  ExcludeGPUArchitecture = @(); ExcludeGPUModel = "";            ExcludePools = @(@(), @());             Arguments = @(" -a woodcoin") }
)

$Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet
$Algorithms | Where-Object { -not $_.Algorithms[1] } | ForEach-Object { $_.Algorithms += "" }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]] } | Where-Object { $_.Algorithms[1] -eq "" -or $MinerPools[1][$_.Algorithms[1]] }
$Algorithms = $Algorithms | Where-Object { $Config.SSL -ne "Always" -or ($MinerPools[0][$_.Algorithms[0]].SSLSelfSignedCertificate -eq $false -and (-not $_.Algorithms[1] -or $MinerPools[1][$_.Algorithms[1]].SSLSelfSignedCertificate -ne $true)) }
$Algorithms = $Algorithms | Where-Object { $MinerPools[0][$_.Algorithms[0]].BaseName -notin $_.ExcludePools[0] }
$Algorithms = $Algorithms | Where-Object { $MinerPools[1][$_.Algorithms[1]].BaseName -notin $_.ExcludePools[1] }

If ($Algorithms) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model
        $MinerAPIPort = $Config.APIPort + ($Miner_Devices.Id | Sort-Object -Top 1) + 1

        $Algorithms | Where-Object Type -EQ $_.Type | ForEach-Object { 

            $ExcludePools = $_.ExcludePools
            ForEach ($Pool0 in ($MinerPools[0][$_.Algorithms[0]] | Where-Object BaseName -notin $_.ExcludePools[0] | Where-Object { $_."Ethash".Epoch -eq $null -or $_."Ethash".Epoch -gt 0 } | Where-Object { $Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true })) { 
                ForEach ($Pool1 in ($MinerPools[1][$_.Algorithms[1]] | Where-Object BaseName -notin $_.ExcludePools[1] | Where-Object { $Config.SSL -ne "Always" -or $_.SSLSelfSignedCertificate -ne $true })) { 

                    $MinMemGiB = $_.MinMemGiB + $Pool0.DAGSizeGiB + $Pool1.DAGSizeGiB
                    $AvailableMiner_Devices = If ($_.ExcludeGPUModel) { $Miner_Devices | Where-Object Model -notmatch $_.ExcludeGPUModel } Else { $Miner_Devices }
                    If ($AvailableMiner_Devices = $AvailableMiner_Devices | Where-Object MemoryGiB -GE $MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                        $Miner_Name = "$($Name)-$($AvailableMiner_Devices.Count)x$($AvailableMiner_Devices.Model | Select-Object -Unique)$(If ($_.Algorithms[1]) { "-$($_.Algorithms[0])&$($_.Algorithms[1])" })"

                        $Arguments = $_.Arguments[0]
                        Switch ($Pool0.Protocol) { 
                            "ethproxy"     { $Arguments += " -p ethproxy" }
                            "ethstratum1"  { $Arguments += " -p ethstratum" }
                            "ethstratum2"  { $Arguments += " -p ethstratum2" }
                            "ethstratumnh" { $Arguments += " -p ethstratum" }
                            Default        { $Arguments += " -p stratum"}
                        }
                        $Arguments += If ($Pool0.PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                        $Arguments += "$($Pool0.Host):$($Pool0.PoolPorts | Select-Object -Last 1)"
                        $Arguments += " -w $($Pool0.User)"
                        $Arguments += " --pool_password $($Pool0.Pass)"
                        $Arguments += " -r $($Config.WorkerName)"

                        If ($_.Algorithms[1]) {
                            $Arguments += $_.Arguments[1]
                            Switch ($Pool1.Protocol) { 
                                "ethproxy"     { $Arguments += " --p2 ethproxy" }
                                "ethstratum1"  { $Arguments += " --p2 ethstratum" }
                                "ethstratum2"  { $Arguments += " --p2 ethstratum2" }
                                "ethstratumnh" { $Arguments += " --p2 ethstratum" }
                                Default        { $Arguments += " --p2 stratum" }
                            }
                            $Arguments += If ($Pool1.PoolPorts[1]) { "+ssl://" } Else { "+tcp://" }
                            $Arguments += "$($Pool1.Host):$($Pool1.PoolPorts | Select-Object -Last 1)"
                            $Arguments += " --w2 $($Pool1.User)"
                            $Arguments += " --pool_password2 $($Pool1.Pass)"
                            $Arguments += " --r2 $($Config.WorkerName)"
                        }

                        # Apply tuning parameters
                        If ($Variables.UseMinerTweaks) { $Arguments += $_.Tuning }

                        [PSCustomObject]@{ 
                            API              = "BzMiner"
                            Arguments        = "$Arguments --nc 1 --no_watchdog --http_enabled 1 --http_port $MinerAPIPort --enable $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0}:0' -f $_ }) -join ' ')"
                            DeviceNames      = $AvailableMiner_Devices.Name
                            Fee              = $_.Fee # Dev fee
                            MinerSet         = $_.MinerSet
                            MinerUri         = "http://127.0.0.1:$($MinerAPIPort)"
                            Name             = $Miner_Name
                            Path             = $Path
                            Port             = $MinerAPIPort
                            PrerequisitePath = $PrerequisitePath
                            PrerequisiteURI  = $PrerequisiteURI
                            Type             = $_.Type
                            URI              = $Uri
                            WarmupTimes      = $_.WarmupTimes # First value: Seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                            Workers          = @($Pool0, $Pool1 | Where-Object { $_ } | ForEach-Object { @{ Pool = $_ } })
                        }
                    }
                }
            }
        }
    }
}