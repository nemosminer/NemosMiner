using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.42/lolMiner_v1.42_Win64.zip"
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\lolminer.exe"
$DeviceEnumerator = "Bus"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs 

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Autolykos2";    Type = "AMD"; Fee = 0.015; MinMemGB = 3.0; MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithm = "BeamV3";        Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo BEAM-III" }
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      Type = "AMD"; Fee = 0.02;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";   Type = "AMD"; Fee = 0.02;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";   Type = "AMD"; Fee = 0.02;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Type = "AMD"; Fee = 0.025; MinMemGB = 7.8; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29";   Type = "AMD"; Fee = 0.01;  MinMemGB = 4.0; MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --algo C29D" } # TeamRed-v0.8.6 is fastest, keep enabled because TeamRed does not support algo on Navi
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   Type = "AMD"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";    Type = "AMD"; Fee = 0.02;  MinMemGB = 4.0; MinerSet = 1; WarmupTimes = @(60, 60); Arguments = " --algo C31" } # TeamRed-v0.8.6 is fastest
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    Type = "AMD"; Fee = 0.02;  MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo C32" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";  Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(30, 20); Arguments = " --coin AUTO144_5" } # GMiner-v2.75 is fastest, but des not support Navi
    [PSCustomObject]@{ Algorithm = "Equihash1927";  Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --coin AUTO192_7" } # GMiner-v2.75 is fastest, but des not support Navi
    [PSCustomObject]@{ Algorithm = "Equihash2109";  Type = "AMD"; Fee = 0.01;  MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = "EquihashZEL";   Type = "AMD"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --coin ZEL" }
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "AMD"; Fee = 0.007; MinMemGB = 3.0; MinerSet = 2; WarmupTimes = @(45, 75); Arguments = " --algo ETCHASH" } # Ethereum Classic, PhoenixMiner-v5.9d is faster
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "AMD"; Fee = 0.007; MinMemGB = 5.0; MinerSet = 2; WarmupTimes = @(45, 75); Arguments = " --algo ETHASH" } # PhoenixMiner-v5.9d is faster
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "AMD"; Fee = 0.007; MinMemGB = 2.0; MinerSet = 2; WarmupTimes = @(45, 75); Arguments = " --algo ETHASH" } # PhoenixMiner-v5.9d is faster
    [PSCustomObject]@{ Algorithm = "SHA256ton";     Type = "AMD"; Fee = 0.01;  MinMemGB = 2.0; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo TON" }
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "AMD"; Fee = 0.007; MinMemGB = 2.0; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo UBQHASH" }

    [PSCustomObject]@{ Algorithm = "Autolykos2";    Type = "NVIDIA"; Fee = 0.015; MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(45, 45); Arguments = " --algo AUTOLYKOS2" }
    [PSCustomObject]@{ Algorithm = "BeamV3";        Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --algo BEAM-III" } # NBMiner-v39.5 is fastest
    [PSCustomObject]@{ Algorithm = "Cuckoo29";      Type = "NVIDIA"; Fee = 0.02;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(45, 45); Arguments = " --algo C29AE" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29B";   Type = "NVIDIA"; Fee = 0.02;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo CR29-40" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo29S";   Type = "NVIDIA"; Fee = 0.02;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo CR29-32" }
    [PSCustomObject]@{ Algorithm = "Cuckaroo30CTX"; Type = "NVIDIA"; Fee = 0.025; MinMemGB = 8.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C30CTX" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 4.0; MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --algo C29D" } # GMiner-v2.75 is fastest
    [PSCustomObject]@{ Algorithm = "CuckarooM29";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 6.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo C29M" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo31";    Type = "NVIDIA"; Fee = 0.02;  MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo C31" }
    [PSCustomObject]@{ Algorithm = "Cuckatoo32";    Type = "NVIDIA"; Fee = 0.02;  MinMemGB = 4.0; MinerSet = 0; WarmupTimes = @(60, 60); Arguments = " --algo C32" }
    [PSCustomObject]@{ Algorithm = "Equihash1445";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(30, 20); Arguments = " --coin AUTO144_5" } # MiniZ-v1.8y4rc2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "Equihash1927";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --coin AUTO192_7" } # MiniZ-v1.8y4rc2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "Equihash2109";  Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 2.0; MinerSet = 0; WarmupTimes = @(30, 45); Arguments = " --algo EQUI210_9" }
    [PSCustomObject]@{ Algorithm = "EquihashZEL";   Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 3.0; MinerSet = 1; WarmupTimes = @(30, 45); Arguments = " --coin ZEL" } # MiniZ-v1.8y4rc2 is fastest, but has 2% miner fee
    [PSCustomObject]@{ Algorithm = "EtcHash";       Type = "NVIDIA"; Fee = 0.007; MinMemGB = 3.0; MinerSet = 2; WarmupTimes = @(45, 75); Arguments = " --algo ETCHASH" } # Ethereum Classic, PhoenixMiner-v5.9d is faster
    [PSCustomObject]@{ Algorithm = "Ethash";        Type = "NVIDIA"; Fee = 0.007; MinMemGB = 5.0; MinerSet = 2; WarmupTimes = @(45, 75); Arguments = " --algo ETHASH" } # PhoenixMiner-v5.9d is faster
    [PSCustomObject]@{ Algorithm = "EthashLowMem";  Type = "NVIDIA"; Fee = 0.007; MinMemGB = 2.0; MinerSet = 2; WarmupTimes = @(45, 75); Arguments = " --algo ETHASH" } # PhoenixMiner-v5.9d is faster
    [PSCustomObject]@{ Algorithm = "SHA256ton";     Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 2.0; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo TON" }
    [PSCustomObject]@{ Algorithm = "UbqHash";       Type = "NVIDIA"; Fee = 0.007; MinMemGB = 2.0; MinerSet = 2; WarmupTimes = @(30, 60); Arguments = " --algo UBQHASH" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -eq $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB

            If ($Pools.($_.Algorithm).DAGSize -gt 0) { 
                $MinMemGB = ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum
                If ($Pools.($_.Algorithm).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --ethstratum ETHV1" }
            }
            If ($_.Algorithm -match "^Cuckaroo.*$|^Cuckoo.*$" -and ([System.Environment]::OSVersion.Version -ge [Version]"10.0.0.0")) { $MinMemGB += 1 }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "coin") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --pool $($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).pass)"

                If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { $_.Arguments += ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" }

                [PSCustomObject]@{ 
                    Name            = $Miner_Name
                    DeviceName      = $AvailableMiner_Devices.Name
                    Type            = $_.Type
                    Path            = $Path
                    Arguments       = ("$($_.Arguments)$(if ($_.Algorithm -ne "SHA256ton") { If ($Pools.($_.Algorithm).SSL) { " --tls on" } Else { " --tls off" } }) --log off --apiport $MinerAPIPort --shortstats 7 --longstats 30 --watchdog exit --dns-over-https 1 --devicesbypcie --devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0}:0' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm       = $_.Algorithm
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
