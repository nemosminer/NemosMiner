using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = "https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.54/lolMiner_v1.54_Win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\lolminer.exe"
$DeviceEnumerator = "Bus"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = @("Autolykos2"); Type = "NVIDIA"; Fee = @(0.015); MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 45); ExcludeGPUArchitecture = @(); Arguments = " --algo AUTOLYKOS2" }
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
