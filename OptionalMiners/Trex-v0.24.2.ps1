using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.24.2/t-rex-0.24.2-win.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Autolykos2");           Fee = @(0.02); MinMemGB = 3;        MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo autolykos2 --intensity 25" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Autolykos2"); Fee = @(0.01, 0.02); MinMemGB = 8;  MinerSet = 0; WarmupTimes = @(0, 45); Arguments = " --algo ethash --lhr-algo autolykos2 --lhr-tune -1" }
    [PSCustomObject]@{ Algorithm = @("EtcHash");              Fee = @(0.01); MinMemGB = 3;        MinerSet = 1; WarmupTimes = @(0, 45); Arguments = " --algo etchash --intensity 25" } # GMiner-v2.70 is fastest
    [PSCustomObject]@{ Algorithm = @("Ethash");               Fee = @(0.01); MinMemGB = 5;        MinerSet = 1; WarmupTimes = @(0, 45); Arguments = " --algo ethash --intensity 25" } # GMiner-v2.70 is fastest
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");         Fee = @(0.01); MinMemGB = 2;        MinerSet = 1; WarmupTimes = @(0, 45); Arguments = " --algo ethash --intensity 25" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = @("KawPoW");               Fee = @(0.01); MinMemGB = 3;        MinerSet = 0; WarmupTimes = @(0, 30); Arguments = " --algo kawpow --intensity 25" } # XmRig-v6.12.2 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = @("Ethash", "KawPoW");     Fee = @(0.01, 0.01); MinMemGB = 10; MinerSet = 0; WarmupTimes = @(0, 45); Arguments = " --algo ethash --lhr-algo kawpow --lhr-tune -1" }
    [PSCustomObject]@{ Algorithm = @("MTP");                  Fee = @(0.01); MinMemGB = 3;        MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo mtp --intensity 21" }
    [PSCustomObject]@{ Algorithm = @("MTPTcr");               Fee = @(0.01); MinMemGB = 3;        MinerSet = 0; WarmupTimes = @(0, 15); Arguments = " --algo mtp-tcr --intensity 21" }
    [PSCustomObject]@{ Algorithm = @("Multi");                Fee = @(0.01); MinMemGB = 2;        MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo multi --intensity 25" }
    [PSCustomObject]@{ Algorithm = @("Octopus");              Fee = @(0.02); MinMemGB = 5;        MinerSet = 0; WarmupTimes = @(0, 45); Arguments = " --algo octopus --intensity 25" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Octopus");    Fee = @(0.01, 0.02); MinMemGB = 8;  MinerSet = 0; WarmupTimes = @(0, 45); Arguments = " --algo ethash --lhr-algo octopus --lhr-tune -1" }
    [PSCustomObject]@{ Algorithm = @("ProgPoW");              Fee = @(0.01); MinMemGB = 2;        MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo progpow" }
    [PSCustomObject]@{ Algorithm = @("Tensority");            Fee = @(0.03); MinMemGB = 2;        MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo tensority --intensity 25" }
    [PSCustomObject]@{ Algorithm = @("Veil");                 Fee = @(0.01); MinMemGB = 2;        MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo progpow-veil --intensity 24" }
    [PSCustomObject]@{ Algorithm = @("VeriBlock");            Fee = @(0.01); MinMemGB = 2;        MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo progpow-veriblock" }
    [PSCustomObject]@{ Algorithm = @("Zano");                 Fee = @(0.01); MinMemGB = 2;        MinerSet = 0; WarmupTimes = @(0, 0);  Arguments = " --algo progpowz --intensity 25" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $AlgorithmDefinitions | ForEach-Object {

                $Arguments = $_.Arguments
                $MinMemGB = If ($Pools.($_.Algorithm[0]).DAGSize -gt 0 -and -not $_.Algorithm[1]) { ((($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }
                $WarmupTimes = $_.WarmupTimes.PsObject.Copy()

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    If ($Miner_Devices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -le 2 }) { $_.Arguments = $_.Arguments -replace " --intensity [0-9\.]+" }

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "lhr-algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($Pools.($_.Algorithm[0]).DAGsize -ne $null -and $Pools.($_.Algorithm[0]).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$") { 
                        $Stratum = "stratum2"
                    }
                    Else {
                        $Stratum = "stratum"
                    }
                    If ($Pools.($_.Algorithm[0]).SSL -eq $true) { $Stratum += "+ssl://" } Else { $Stratum += "+tcp://" }

                    If ($_.Algorithm -eq "ProgPoW" -or $_.Algorithm -eq "Zano" ) { 
                        If ($Pools.($_.Algorithm[0]).Currency -in @("SERO", "ZANO")) { 
                            $Coin = " --coin $($Pools.($_.Algorithm[0]).Currency)"
                        }
                        Else { 
                            $Coin = ""
                            Return
                        }
                    }

                    #(ethash, kawpow, progpow) Worker name is not being passed for some mining pools
                    # From now on the username (--user) for these algorithms is no longer parsed as <wallet_address>.<worker_name>
                    If ($Pools.($_.Algorithm[0]).DAGsize -gt 0 -and ($Pools.($_.Algorithm[0]).User -split "\.").Count -eq 2 -and $Pools.($_.Algorithm[0]).Name -notmatch "^MiningPoolHub*") { 
                        $User = " --user $($Pools.($_.Algorithm[0]).User -split "\." | Select-Object -Index 0) --worker $($Pools.($_.Algorithm[0]).User -split "\." | Select-Object -Index 1)"
                    }
                    Else { 
                        $User = " --user $($Pools.($_.Algorithm[0]).User)"
                    }

                    $Pass = " --pass $($Pools.($_.Algorithm[0]).Pass)"
                    If ($Pools.($_.Algorithm[0]).Name -match "^ProHashing.*$" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$((($SelectedDevices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum -$DAGmemReserve) / 1GB)" }
                    If ($Pools.($_.Algorithm[0]).Name -match "^MiningPoolHub*") { $WarmupTimes[1] += 15 } # Allow extra seconds for MPH because of long connect issue
                    If ($Arguments -notmatch "--kernel [0-9]") { $WarmupTimes[1] += 15 } # Allow extra seconds for kernel auto tuning

                    If ($_.Algorithm[1]) { 
                        $Arguments += " --url2 $(If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { "stratum+ssl://" } Else { "stratum+tcp://" })$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) --user2 $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) --pass2 $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass)"
                    }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name -replace " "
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$Arguments --url $Stratum$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)$User$Pass --no-strict-ssl$(If ($Variables.IsLocalAdmin -eq $true -and $Config.UseMinerTweaks -eq $true) { " --mt 3" }) $Coin --no-watchdog --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-read-only --gpu-report-interval 5 --quiet --retry-pause 1 --timeout 50000 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm       = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                        API             = "Trex"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee # Dev fee
                        MinerUri        = "http://localhost:$($MinerAPIPort)/trex"
                        WarmupTimes     = $WarmupTimes # First value: warmup time (in seconds) until miner sends stable hashrates that will count for benchmarking; second value: extra time (added to $Config.Warmuptimes[1] in seconds) until miner must send first sample, if no sample is received miner will be marked as failed
                    }
                }
            }
        }
    }
}
