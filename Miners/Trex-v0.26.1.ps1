using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.26.1/t-rex-0.26.1-win.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\t-rex.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Autolykos2");           Fee = @(0.02);       MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(45, 30);  Arguments = " --algo autolykos2 --intensity 25" }
    [PSCustomObject]@{ Algorithm = @("Blake3");               Fee = @(0.01);       MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(45, 0);   Arguments = " --algo blake3 --intensity 25" }
    [PSCustomObject]@{ Algorithm = @("EtcHash");              Fee = @(0.01);       MinMemGB = $Pools."EtcHash".DAGSizeGB;      MemReserveGB = 0.41; MinerSet = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo etchash --intensity 25" } # GMiner-v2.96 is fastest
    [PSCustomObject]@{ Algorithm = @("Ethash");               Fee = @(0.01);       MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.41; MinerSet = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --intensity 25" } # GMiner-v2.96 is fastest
    [PSCustomObject]@{ Algorithm = @("Ethash", "Autolykos2"); Fee = @(0.01, 0.02); MinMemGB = 8;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --dual-algo autolykos2 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake3");     Fee = @(0.01, 0.01); MinMemGB = $Pools."EtHash".DAGSizeGB;       MemReserveGB = 0.41; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --dual-algo blake3 --lhr-tune -1 --lhr-autotune-interval 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "FiroPoW");    Fee = @(0.01, 0.01); MinMemGB = 10;                              MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(255, 15); Arguments = " --algo ethash --dual-algo firopow --lhr-tune -1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "KawPoW");     Fee = @(0.01, 0.01); MinMemGB = 10;                              MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(255, 15); Arguments = " --algo ethash --dual-algo kawpow --lhr-tune -1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Octopus");    Fee = @(0.01, 0.02); MinMemGB = 8;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --dual-algo octopus --lhr-tune -1" }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");         Fee = @(0.01);       MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; MinerSet = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo ethash --intensity 25" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = @("FiroPoW");              Fee = @(0.01);       MinMemGB = 5;                               MemReserveGB = 0;    MinerSet = 1; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo firopow --intensity 25" }
    [PSCustomObject]@{ Algorithm = @("KawPoW");               Fee = @(0.01);       MinMemGB = $Pools."KawPoW".DAGSizeGB;       MemReserveGB = 0.41; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(45, 0);   Arguments = " --algo kawpow --intensity 25" } # XmRig-v6.17.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = @("MTP");                  Fee = @(0.01);       MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo mtp --intensity 21" }
    [PSCustomObject]@{ Algorithm = @("MTPTcr");               Fee = @(0.01);       MinMemGB = 3;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 15);  Arguments = " --algo mtp-tcr --intensity 21" }
    [PSCustomObject]@{ Algorithm = @("Multi");                Fee = @(0.01);       MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo multi --intensity 25" }
    [PSCustomObject]@{ Algorithm = @("Octopus");              Fee = @(0.02);       MinMemGB = 6.1;                             MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(60, 15);  Arguments = " --algo octopus" } # 6GB is not enough
    [PSCustomObject]@{ Algorithm = @("ProgPoW");              Fee = @(0.01);       MinMemGB = $Pools."ProgPoW".DAGSizeGB;      MemReserveGB = 0.41; MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo progpow" }
    [PSCustomObject]@{ Algorithm = @("Tensority");            Fee = @(0.01);       MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo tensority --intensity 25" }
    [PSCustomObject]@{ Algorithm = @("Veil");                 Fee = @(0.01);       MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo progpow-veil --intensity 24" }
    [PSCustomObject]@{ Algorithm = @("VeriBlock");            Fee = @(0.01);       MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo progpow-veriblock" }
    [PSCustomObject]@{ Algorithm = @("Zano");                 Fee = @(0.01);       MinMemGB = 2;                               MemReserveGB = 0;    MinerSet = 0; Tuning = " --mt 3"; WarmupTimes = @(30, 0);   Arguments = " --algo progpowz --intensity 25" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm[0]).Host -and (-not $_.Algorithm[1] -or $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) | Select-Object) -join '-' -replace ' '

                If ($AvailableMiner_Devices | Where-Object MemoryGB -le 2) { $_.Arguments = $_.Arguments -replace " --intensity [0-9\.]+" }

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "dual-algo") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --url $(If ($Pools.($_.Algorithm[0]).DAGsizeGB -ne $null -and $Pools.($_.Algorithm[0]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { "stratum2" } Else { "stratum" })$(If ($Pools.($_.Algorithm[0]).SSLe) { "+ssl://" } Else { "+tcp://" })$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)"
                #(ethash, kawpow, progpow) Worker name is not being passed for some mining pools
                # From now on the username (--user) for these algorithms is no longer parsed as <wallet_address>.<worker_name>
                $_.Arguments += " --user $(If ($Pools.($_.Algorithm[0]).DAGsizeGB -gt 0 -and ($Pools.($_.Algorithm[0]).User -split "\.").Count -eq 2 -and $Pools.($_.Algorithm[0]).BaseName -ne "MiningPoolHub") { "$($Pools.($_.Algorithm[0]).User -split "\." | Select-Object -First 1) --worker $($Pools.($_.Algorithm[0]).User -split "\." | Select-Object -Index 1)" } Else { "$($Pools.($_.Algorithm[0]).User)" })"
                $_.Arguments += " --pass $($Pools.($_.Algorithm[0]).Pass)$(If ($Pools.($_.Algorithm[0]).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$(((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB) * 1GB / 1000000000)" })"

                If ($_.Algorithm[0] -in @("ProgPoW", "Zano")) { 
                    If ($Pools.($_.Algorithm[0]).Currency -in @("SERO", "ZANO")) { 
                        $_.Arguments += " --coin $($Pools.($_.Algorithm[0]).Currency)"
                    }
                    Else { 
                        Return
                    }
                }

                If ($_.Algorithm[1]) { 
                    $_.Arguments += " --url2 $(If ($Pools.($_.Algorithm[1]).DAGsizeGB -ne $null -and $Pools.($_.Algorithm[1]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { "stratum2" } Else { "stratum" })$(If ($Pools.($_.Algorithm[1]).SSLe) { "+ssl://" } Else { "+tcp://" })$($Pools.($_.Algorithm[1]).Host):$($Pools.($_.Algorithm[1]).Port)"
                    #(ethash, kawpow, progpow) Worker name is not being passed for some mining pools
                    # From now on the username (--user) for these algorithms is no longer parsed as <wallet_address>.<worker_name>
                    $_.Arguments += " --user2 $(If ($Pools.($_.Algorithm[1]).DAGsizeGB -gt 0 -and ($Pools.($_.Algorithm[1]).User -split "\.").Count -eq 2 -and $Pools.($_.Algorithm[1]).BaseName -ne "MiningPoolHub") { "$($Pools.($_.Algorithm[1]).User -split "\." | Select-Object -First 1) --worker2 $($Pools.($_.Algorithm[1]).User -split "\." | Select-Object -Index 1)" } Else { "$($Pools.($_.Algorithm[1]).User)" })"
                    $_.Arguments += " --pass2 $($Pools.($_.Algorithm[1]).Pass)$(If ($Pools.($_.Algorithm[1]).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$(((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB) * 1GB / 1000000000)" })"
                }

                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $_.Arguments += $_.Tuning }

                If ($_.Arguments -notmatch "--kernel [0-9]") { $_.WarmupTimes[0] += 15 } # Allow extra seconds for kernel auto tuning

                [PSCustomObject]@{ 
                    Name            = $Miner_Name
                    DeviceName      = $AvailableMiner_Devices.Name
                    Type            = $AvailableMiner_Devices.Type
                    Path            = $Path
                    Arguments       = ("$($_.Arguments) --no-strict-ssl --no-watchdog --gpu-report-interval 5 --quiet --retry-pause 1 --timeout 50000 --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-read-only --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm       = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                    API             = "Trex"
                    Port            = $MinerAPIPort
                    URI             = $Uri
                    Fee             = $_.Fee # Dev fee
                    MinerUri        = "http://localhost:$($MinerAPIPort)/trex"
                    WarmupTimes     = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
