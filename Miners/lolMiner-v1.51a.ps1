using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.51a/lolMiner_v1.51a_Win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\lolminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Autolykos2");                Type = "AMD"; Fee = @(0.015);      MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithm = @("Blake3");                    Type = "AMD"; Fee = @(0.015);      MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --algo ALEPHIUM" }
    [PSCustomObject]@{ Algorithm = @("BeamV3");                    Type = "AMD"; Fee = @(0.01);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");                  Type = "AMD"; Fee = @(0.02);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29B");               Type = "AMD"; Fee = @(0.02);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29S");               Type = "AMD"; Fee = @(0.02);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo30CTX");             Type = "AMD"; Fee = @(0.025);      MinMemGB = 7.8;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithm = @("CuckarooD29");               Type = "AMD"; Fee = @(0.01);       MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --algo C29D" } # TeamRedMiner-v0.10.0 is fastest, keep enabled because TeamRed does not support algo on Navi
    [PSCustomObject]@{ Algorithm = @("CuckarooM29");               Type = "AMD"; Fee = @(0.01);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");                Type = "AMD"; Fee = @(0.02);       MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(60, 60); Arguments = " --algo C31" } # TeamRedMiner-v0.10.0 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");                Type = "AMD"; Fee = @(0.02);       MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo C32" }
    [PSCustomObject]@{ Algorithm = @("Equihash1445");              Type = "AMD"; Fee = @(0.01);       MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 30); Arguments = " --coin AUTO144_5" } # GMiner-v2.98 is fastest, but des not support Navi
    [PSCustomObject]@{ Algorithm = @("Equihash1927");              Type = "AMD"; Fee = @(0.01);       MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --coin AUTO192_7" } # GMiner-v2.98 is fastest, but des not support Navi
    [PSCustomObject]@{ Algorithm = @("Equihash2109");              Type = "AMD"; Fee = @(0.01);       MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = @("Equihash1254");              Type = "AMD"; Fee = @(0.01);       MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --coin ZEL" }
    [PSCustomObject]@{ Algorithm = @("EtcHash");                   Type = "AMD"; Fee = @(0.007);      MinMemGB = $Pools."Etchash".DAGSizeGB;      MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETCHASH" } # Ethereum Classic, PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake3");         Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $Pools."Etchash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETCHASH --dualmode ALEPHDUAL" } # Ethereum Classic, PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EtcHash", "SHA256ton");      Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $Pools."Etchash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETCHASH --dualmode TONDUAL" } # Ethereum Classic, PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("Ethash");                    Type = "AMD"; Fee = @(0.007);      MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake3");          Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "SHA256ton");       Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode TONDUAL" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");              Type = "AMD"; Fee = @(0.007);      MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Blake3");    Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "SHA256ton"); Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode TONDUAL" }
    [PSCustomObject]@{ Algorithm = @("SHA256ton");                 Type = "AMD"; Fee = @(0.01);       MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(15, 30); Arguments = " --algo TON" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");                   Type = "AMD"; Fee = @(0.007);      MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo UBQHASH" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake3");         Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo UBQHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "SHA256ton");      Type = "AMD"; Fee = @(0.01, 0.01); MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo UBQHASH --dualmode TONDUAL" }

    [PSCustomObject]@{ Algorithm = @("Autolykos2");                Type = "NVIDIA"; Fee = @(0.015);      MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithm = @("Blake3");                    Type = "NVIDIA"; Fee = @(0.015);      MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " --algo ALEPHIUM" }
    [PSCustomObject]@{ Algorithm = @("BeamV3");                    Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --algo BEAM-III" } # NBMiner-v42.2 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");                  Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29B");               Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29S");               Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = @("Cuckaroo30CTX");             Type = "NVIDIA"; Fee = @(0.025);      MinMemGB = 8.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithm = @("CuckarooD29");               Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --algo C29D" } # GMiner-v2.98 is fastest
    [PSCustomObject]@{ Algorithm = @("CuckarooM29");               Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 6.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");                Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 30); Arguments = " --algo C31" }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");                Type = "NVIDIA"; Fee = @(0.02);       MinMemGB = 4.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(60, 30); Arguments = " --algo C32" }
    [PSCustomObject]@{ Algorithm = @("Equihash1445");              Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 30); Arguments = " --coin AUTO144_5" } # MiniZ-v1.8z2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = @("Equihash1927");              Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --coin AUTO192_7" } # MiniZ-v1.8z2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = @("Equihash2109");              Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 2.0;                             MemReserveGB = 0;    MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = @("Equihash1254");              Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --coin ZEL" } # MiniZ-v1.8z2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = @("EtcHash");                   Type = "NVIDIA"; Fee = @(0.007);      MinMemGB = $Pools."Etchash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETCHASH" } # Ethereum Classic, PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EtcHash", "Blake3");         Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $Pools."Etchash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETCHASH --dualmode ALEPHDUAL" } # Ethereum Classic, PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EtcHash", "SHA256ton");      Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $Pools."Etchash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETCHASH --dualmode TONDUAL" } # Ethereum Classic, PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("Ethash");                    Type = "NVIDIA"; Fee = @(0.007);      MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake3");          Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "SHA256ton");       Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode TONDUAL" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");              Type = "NVIDIA"; Fee = @(0.007);      MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH" } # PhoenixMiner-v6.2c is faster
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Blake3");    Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem", "SHA256ton"); Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(45, 45); Arguments = " --algo ETHASH --dualmode TONDUAL" }
    [PSCustomObject]@{ Algorithm = @("SHA256ton");                 Type = "NVIDIA"; Fee = @(0.01);       MinMemGB = 3.0;                             MemReserveGB = 0;    MinerSet = 2; WarmupTimes = @(15, 30); Arguments = " --algo TON" }
    [PSCustomObject]@{ Algorithm = @("UbqHash");                   Type = "NVIDIA"; Fee = @(0.007);      MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo UBQHASH" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "Blake3");         Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo UBQHASH --dualmode ALEPHDUAL" }
    [PSCustomObject]@{ Algorithm = @("UbqHash", "SHA256ton");      Type = "NVIDIA"; Fee = @(0.01, 0.01); MinMemGB = $Pools."UbqHash".DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo UBQHASH --dualmode TONDUAL" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm[0]).Host -and (-not $_.Algorithm[1] -or $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -eq $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            If ($Pools.($_.Algorithm[0]).DAGsizeGB -gt 0) { 
                If ($Pools.($_.Algorithm[0]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --ethstratum ETHV1" }
            }
            If ($_.Algorithm[0] -match "^Cuckaroo.*$|^Cuckoo.*$" -and ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0")) { $_.MinMemGB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "coin") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                If ($_.Algorithm[0] -eq "SHA256ton") { 
                    If ($Pools.($_.Algorithm[0]).BaseName -eq "TonWhales") { 
                        $_.Arguments += " --pool wss://stratum.$($Pools.($_.Algorithm[0]).Host)/stratum"
                    }
                    Else { 
                        $_.Arguments += " --pool wss://$($Pools.($_.Algorithm[0]).Host)"
                    }
                }
                Else { 
                    $_.Arguments += "$(If ($Pools.($_.Algorithm[0]).SSL) { " --tls on" } Else { " --tls off" }) --pool $($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)"
                }
                $_.Arguments += " --user $($Pools.($_.Algorithm[0]).User) --pass $($Pools.($_.Algorithm[0]).pass)$(If ($Pools.($_.Algorithm[0]).BaseName -eq "ProHashing" -and $_.Algorithm[0] -eq "EthashLowMem") { ",l=$(((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB) * 1GB / 1000000000)" })"


                If ($_.Algorithm[1]) { 
                    If ($_.Algorithm[1] -eq "SHA256ton") { 
                        If ($Pools.($_.Algorithm[1]).BaseName -eq "TonWhales") { 
                            $_.Arguments += " --dualpool wss://stratum.$($Pools.($_.Algorithm[1]).Host)/stratum --dualuser $($Pools.($_.Algorithm[1]).User) --dualpass $($Pools.($_.Algorithm[1]).pass)"
                        }
                        Else { 
                            $_.Arguments += " --dualpool wss://$($Pools.($_.Algorithm[1]).Host) --dualuser $($Pools.($_.Algorithm[1]).User) --dualpass $($Pools.($_.Algorithm[1]).pass)"
                        }
                    }
                    Else { 
                        $_.Arguments += "$(If ($Pools.($_.Algorithm[0]).SSL) { " --dualtls on" } Else { " --dualtls off" }) --dualpool $($Pools.($_.Algorithm[1]).Host):$($Pools.($_.Algorithm[1]).Port) --dualuser $($Pools.($_.Algorithm[1]).User) --dualpass $($Pools.($_.Algorithm[1]).pass)"
                    }
                }

                [PSCustomObject]@{ 
                    Name            = $Miner_Name
                    DeviceNames    = $AvailableMiner_Devices.Name
                    Type            = $AvailableMiner_Devices.Type
                    Path            = $Path
                    Arguments       = ("$($_.Arguments) --log off --apiport $MinerAPIPort --shortstats 7 --longstats 30 --digits 6 --watchdog exit --dns-over-https 1 --devicesbypcie --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0}:0' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm       = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                    API             = "lolMiner"
                    Port            = $MinerAPIPort
                    URI             = $Uri
                    Fee             = $_.Fee
                    WarmupTimes     = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
