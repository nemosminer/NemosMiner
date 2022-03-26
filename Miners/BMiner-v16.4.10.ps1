using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://www.bminercontent.com/releases/bminer-lite-v16.4.10-1884bde-amd64.zip"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\bminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs 

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Ethash");                    Type = "AMD"; Fee = @(0.0065);    MinMemGB = ($Pools."Ethash".DAGSize + $DAGmemReserve) / 1GB;       MinerSet = 1; WarmupTimes = @(45, 30); ExcludePool = @(@(), @()); Protocol = @(" -uri ethproxy") }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");              Type = "AMD"; Fee = @(0.0065);    MinMemGB = ($Pools."EthashLowMem".DAGSize + $DAGmemReserve) / 1GB; MinerSet = 1; WarmupTimes = @(45, 30); ExcludePool = @(@(), @()); Protocol = @(" -uri ethproxy") }
    # [PSCustomObject]@{ Algorithm = @("Ethash", "Handshake");       Type = "AMD"; Fee = @(0.0065, 0); MinMemGB = ($Pools."Ethash".DAGSize + $DAGmemReserve) / 1GB;       MinerSet = 1; WarmupTimes = @(45, 30); ExcludePool = @(@(), @()); Protocol = @(" -uri ethproxy", " -uri2 handshake") } # Error flag -uri2: Unsupported scheme
    # [PSCustomObject]@{ Algorithm = @("EthashLowMem", "Handshake"); Type = "AMD"; Fee = @(0.0065, 0); MinMemGB = ($Pools."EthashLowMem".DAGSize + $DAGmemReserve) / 1GB; MinerSet = 1; WarmupTimes = @(45, 30); ExcludePool = @(@(), @()); Protocol = @(" -uri ethproxy", " -uri2 handshake") } # Error flag -uri2: Unsupported scheme

    [PSCustomObject]@{ Algorithm = @("BeamV3");        Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 5.0;                                                    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -uri beam") } # NBMiner-v40.1 is faster but has 2% fee
    [PSCustomObject]@{ Algorithm = @("Cuckaroo29bfc"); Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 8.0;                                                    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -uri bfc") }
    [PSCustomObject]@{ Algorithm = @("CuckarooM29");   Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 4.0;                                                    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -uri cuckaroo29m") }
    [PSCustomObject]@{ Algorithm = @("CuckarooZ29");   Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 6.0;                                                    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePool = @(@(), @());           Protocol = @(" -uri cuckaroo29z") } # GMiner-v2.90 is fastest
    [PSCustomObject]@{ Algorithm = @("Cuckatoo31");    Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0;                                                    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePool = @(@(), @());           Protocol = @(" -uri cuckatoo31") }
    [PSCustomObject]@{ Algorithm = @("Cuckatoo32");    Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 8.0;                                                    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -uri cuckatoo32") }
    [PSCustomObject]@{ Algorithm = @("Cuckoo29");      Type = "NVIDIA"; Fee = @(0.01);   MinMemGB = 6.0;                                                    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -uri aeternity") }
    [PSCustomObject]@{ Algorithm = @("Equihash1445");  Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 3.0;                                                    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -pers auto -uri equihash1445") } # MiniZ-v1.8x is fastest
    [PSCustomObject]@{ Algorithm = @("EquihashBTG");   Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 3.0;                                                    MinerSet = 1; WarmupTimes = @(45, 35); ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -uri zhash") }
    [PSCustomObject]@{ Algorithm = @("Ethash");        Type = "NVIDIA"; Fee = @(0.0065); MinMemGB = ($Pools."Ethash".DAGSize + $DAGmemReserve) / 1GB;       MinerSet = 1; WarmupTimes = @(45, 30); ExcludePool = @(@(), @());           Protocol = @(" -uri ethproxy") }
    [PSCustomObject]@{ Algorithm = @("EthashLowMem");  Type = "NVIDIA"; Fee = @(0.0065); MinMemGB = ($Pools."EthashLowMem".DAGSize + $DAGmemReserve) / 1GB; MinerSet = 1; WarmupTimes = @(45, 30); ExcludePool = @(@(), @());           Protocol = @(" -uri ethproxy") }
    # [PSCustomObject]@{ Algorithm = @("KawPoW");        Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = ($Pools."KawPoW".DAGSize + $DAGmemReserve) / 1GB;       MinerSet = 1; WarmupTimes = @(60, 30); ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -uri raven") } # Error
    [PSCustomObject]@{ Algorithm = @("Octopus");       Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 6.0;                                                    MinerSet = 1; WarmupTimes = @(45, 35); ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -uri conflux") } # NBMiner-v40.1 is faster is faster but has 2% fee
    [PSCustomObject]@{ Algorithm = @("Sero");          Type = "NVIDIA"; Fee = @(0.02);   MinMemGB = 2.0;                                                    MinerSet = 1; WarmupTimes = @(45, 0);  ExcludePool = @(@("Nicehash"), @()); Protocol = @(" -uri sero") }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm[0]).Host -and (-not $_.Algorithm[1] -or $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    # # Does not seem to make any difference for Handshake
    # # Intensities for 2. algorithm
    # $Intensities = [PSCustomObject]@{ 
    #     "Handshake" = @(0, 10, 30, 60, 100, 150, 210) # 0 = Auto-Intensity
    # }

    # # Build command sets for intensities
    # $Algorithms = $Algorithms | ForEach-Object { 
    #     $_.PsObject.Copy()
    #     $Arguments = ""
    #     ForEach ($Intensity in $Intensities.($_.Algorithm[1])) { 
    #         $_ | Add-Member Arguments " -dual-subsolver -1 -dual-intensity $Intensity" -Force
    #         $_ | Add-Member Intensity $Intensity -Force
    #         $_.PsObject.Copy()
    #     }
    # }

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) * 2 + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Where-Object { $Pools.($_.Algorithm[0]).BaseName -notin $_.ExcludePool[0] } | Where-Object { $Pools.($_.Algorithm[1]).BaseName -notin $_.ExcludePool[1] } | ConvertTo-Json -Depth 3 | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB

            $AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge $MinMemGB
            $AvailableMiner_Devices = $AvailableMiner_Devices | Where-Object { -not $_.CIM.MaxRefreshRate -or $_.MemoryGB - 0.5 -ge $MinMemGB } # Reserve 512 MB when GPU with connected monitor

            If ($_.Algorithm[1]) { $AvailableMiner_Devices = @($AvailableMiner_Devices | Where-Object { $_.Model -notmatch "^Radeon RX 5[0-9]{3}.*" }) } # Dual mining not supported on Navi

            If ($AvailableMiner_Devices) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) + @($_.Intensity) | Select-Object) -join '-' -replace ' '

                $Arguments = ""
                $Pass = "$($Pools.($_.Algorithm[0]).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { $Pass += ",l=$((($Miner_Devices.Memory | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" })"

                If ($Pools.($_.Algorithm[0]).DAGsize -ne $null -and $Pools.($_.Algorithm[0]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Protocol[0] = $_.Protocol[0] -replace "ethproxy", "ethstratum" }
                If ($Pools.($_.Algorithm[0]).SSL) { $_.Protocol[0] += "+ssl" }

                $Arguments += "$($_.Protocol[0])://$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm[0]).User)):$([System.Web.HttpUtility]::UrlEncode($Pass))@$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port)"

                If ($_.Algorithm[1]) { 
                    If ($PoolsSecondaryAlgorithm.($_.Algorithm[1]).SSL) { $_.Protocol[1] += "+ssl" }
                    $Arguments += "$($_.Protocol[1])://$([System.Web.HttpUtility]::UrlEncode($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User)):$([System.Web.HttpUtility]::UrlEncode($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass))@$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port)"
                }

                # Optionally disable dev fee mining
                If ($Config.DisableMinerFee) { 
                    $Arguments += " -nofee"

                    $_.Fee = @(0) * ($_.Algorithm | Select-Object).count
                }

                If ($_.Algorithm[1] -and (-not $_.Intensity)) { 
                    # Allow 75 seconds for auto-tuning
                    $_.WarmupTimes[1] += 75
                }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $_.Type
                    Path        = $Path
                    Arguments   = ("$Arguments -max-network-failures=0 -watchdog=false -api 127.0.0.1:$($MinerAPIPort) -devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { "$(If ($AvailableMiner_Devices.Vendor -eq "AMD") { "amd:" }){0:x}" -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm   = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
                    API         = "Bminer"
                    Port        = $MinerAPIPort
                    URI         = $URI
                    Fee         = $_.Fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
