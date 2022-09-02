using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.55/lolMiner_v1.55_Win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\lolminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Autolykos2");             Type = "AMD"; Fee = @(0.015);      MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithm = @("BeamV3");                 Type = "AMD"; Fee = @(0.01);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();  Arguments = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");               Type = "AMD"; Fee = @(0.02);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29B");            Type = "AMD"; Fee = @(0.02);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();  Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29S");            Type = "AMD"; Fee = @(0.02);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();  Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo30CTX");          Type = "AMD"; Fee = @(0.025);      MinMemGB = 7.8;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();  Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithm = @("CuckarooD29");            Type = "AMD"; Fee = @(0.01);       MinMemGB = 4.0;                                   MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();  Arguments = " --algo C29D" } # TeamRedMiner-v0.10.2 is fastest, keep enabled because TeamRed does not support algo on Navi
    [PSCustomObject]@{ Algorithm = @("CuckarooM29");            Type = "AMD"; Fee = @(0.01);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();  Arguments = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");             Type = "AMD"; Fee = @(0.02);       MinMemGB = 4.0;                                   MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();  Arguments = " --algo C31" } # TeamRedMiner-v0.10.2 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");             Type = "AMD"; Fee = @(0.02);       MinMemGB = 4.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 60); ExcludeGPUArchitecture = @();  Arguments = " --algo C32" }
    [PSCustomObject]@{ Algorithm = @("Equihash1254");           Type = "AMD"; Fee = @(0.01);       MinMemGB = 3.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();  Arguments = " --coin ZEL" }
    [PSCustomObject]@{ Algorithm = @("Equihash1445");           Type = "AMD"; Fee = @(0.01);       MinMemGB = 3.0;                                   MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 30); ExcludeGPUArchitecture = @();  Arguments = " --coin $(If ($MinerPools[0].Equihash1445.Currency -in @("BTCZ", "BTG", "EXCC", "XSG")) { $MinerPools[0].Equihash1445.Currency } Else { "AUTO144_5" })" }
    [PSCustomObject]@{ Algorithm = @("Equihash1927");           Type = "AMD"; Fee = @(0.01);       MinMemGB = 3.0;                                   MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();  Arguments = " --coin $(If ($MinerPools[0].Equihash1927.Currency -in @("YEC", "ZCL", "ZER")) { $MinerPools[0].Equihash1927.Currency } Else { "AUTO192_7" })" }
    [PSCustomObject]@{ Algorithm = @("Equihash2109");           Type = "AMD"; Fee = @(0.01);       MinMemGB = 2.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); ExcludeGPUArchitecture = @();  Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = @("EtcHash");                Type = "AMD"; Fee = @(0.007);      MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake3");      Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo ETCHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Kaspa");       Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo ETCHASH --dualmode KASPADUAL" }
    [PSCustomObject]@{ Algorithm = @("Ethash");                 Type = "AMD"; Fee = @(0.007);      MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake3");       Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Kaspa");        Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo ETHASH --dualmode KASPADUAL" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");           Type = "AMD"; Fee = @(0.007);      MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Blake3"); Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Kaspa");  Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo ETHASH --dualmode KASPADUAL" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");                Type = "AMD"; Fee = @(0.007);      MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo UBQHASH" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake3");      Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo UBQHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Kaspa");       Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(60, 45); ExcludeGPUArchitecture = @();  Arguments = " --algo UBQHASH --dualmode KASPADUAL" }

#   [PSCustomObject]@{ Algorithm = @("Autolykos2");             Type = "NVIDIA"; Fee = @(0.015);      MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " --algo AUTOLYKOS2" } #https://github.com/Lolliedieb/lolMiner-releases/issues/1692
    [PSCustomObject]@{ Algorithm = @("BeamV3");                 Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " --algo BEAM-III" } # NBMiner-v42.2 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");               Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29B");            Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29S");            Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo30CTX");          Type = "NVIDIA"; Fee = @(0.025);      MinMemGB = 8.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithm = @("CuckarooD29");            Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 4.0;                                   MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " --algo C29D" } # GMiner-v3.05 is fastest
    [PSCustomObject]@{ Algorithm = @("CuckarooM29");            Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 6.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");             Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 4.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 30); Arguments = " --algo C31" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");             Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 4.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 30); Arguments = " --algo C32" }
    [PSCustomObject]@{ Algorithm = @("Equihash1254");           Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 3.0;                                   MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " --coin ZEL" } # MiniZ-v1.8z3 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = @("Equihash1445");           Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 3.0;                                   MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 30); Arguments = " --coin $(If ($MinerPools[0].Equihash1445.Currency -in @("BTCZ", "BTG", "EXCC", "XSG")) { $MinerPools[0].Equihash1445.Currency } Else { "AUTO144_5" })" } # MiniZ-v1.8z3 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = @("Equihash1927");           Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 3.0;                                   MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 30); Arguments = " --coin $(If ($MinerPools[0].Equihash1927.Currency -in @("YEC", "ZCL", "ZER")) { $MinerPools[0].Equihash1927.Currency } Else { "AUTO192_7" })" } # MiniZ-v1.8z3 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = @("Equihash2109");           Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 2.0;                                   MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 30); Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = @("EtcHash");                Type = "NVIDIA"; Fee = @(0.007);      MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETCHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake3");      Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETCHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Kaspa");       Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETCHASH --dualmode KASPADUAL" }
    [PSCustomObject]@{ Algorithm = @("Ethash");                 Type = "NVIDIA"; Fee = @(0.007);      MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake3");       Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Kaspa");        Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode KASPADUAL" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");           Type = "NVIDIA"; Fee = @(0.007);      MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Blake3"); Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Kaspa");  Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode KASPADUAL" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");                Type = "NVIDIA"; Fee = @(0.007);      MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(60, 30); Arguments = " --algo UBQHASH" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake3");      Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(60, 30); Arguments = " --algo UBQHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Kaspa");       Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $MinerPools[0].UbqHash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(60, 30); Arguments = " --algo UBQHASH --dualmode KASPADUAL" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm[0]).PoolPorts -and (-not $_.Algorithm[1] -or $MinerPools[1].($_.Algorithm[1]).PoolPorts) }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -eq $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Select-Object | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            If ($_.Algorithm[0] -match "^Cuckaroo.*$|^Cuckoo.*$" -and ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0")) { $_.MinMemGB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB) | Where-Object { $_.Architecture -notin $ExcludeGPUArchitecture }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "coin") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator
                $_.Arguments += " --tls $(If ($MinerPools[0].($_.Algorithm[0]).PoolPorts[1]) { "on" } Else { "off" }) --pool $($MinerPools[0].($_.Algorithm[0]).Host):$(($MinerPools[0].($_.Algorithm[0]).PoolPorts | Select-Object -Last 1))"
                $_.Arguments += " --user $($MinerPools[0].($_.Algorithm[0]).User)$(If ($MinerPools[0].($_.Algorithm[0]).WorkerName) { ".$($MinerPools[0].($_.Algorithm[0]).WorkerName)" })"
                $_.Arguments += " --pass $($MinerPools[0].($_.Algorithm[0]).Pass)$(If ($MinerPools[0].($_.Algorithm[0]).BaseName -eq "ProHashing" -and $_.Algorithm[0] -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"

                If ($_.Algorithm[1]) { 
                    $_.Arguments += " --dualtls $(If ($MinerPools[1].($_.Algorithm[1]).SSL) { "on" } Else { "off" }) --dualpool $($MinerPools[1].($_.Algorithm[1]).Host):$($MinerPools[1].($_.Algorithm[1]).Port)"
                    $_.Arguments += " --dualuser $($MinerPools[1].($_.Algorithm[1]).User)$(If ($MinerPools[1].($_.Algorithm[1]).WorkerName) { ".$($MinerPools[1].($_.Algorithm[1]).WorkerName)" })"
                    $_.Arguments += " --dualpass $($MinerPools[1].($_.Algorithm[1]).Pass)$(If ($MinerPools[1].($_.Algorithm[1]).BaseName -eq "ProHashing" -and $_.Algorithm[1] -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                }

                If ($MinerPools[0].($_.Algorithm[0]).DAGsizeGB -gt 0) { 
                    If ($MinerPools[0].($_.Algorithm[0]).BaseName -in @("MiningPoolHub", "NiceHash")) { $_.Arguments += " --ethstratum ETHV1" }
                }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --log off --apiport $MinerAPIPort --shortstats 7 --longstats 30 --digits 6 --watchdog exit --dns-over-https 1 --devicesbypcie --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0}:0' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm[0], $_.Algorithm[1] | Select-Object)
                    API         = "lolMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
