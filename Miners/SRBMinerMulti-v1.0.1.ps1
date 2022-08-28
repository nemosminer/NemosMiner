using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { (($_.Type -eq "AMD" -and $_.Architecture -ne "Other") -or $_.OpenCL.ClVersion -ge "OpenCL C 2.0")})) { Return }

$Uri = "https://github.com/doktor83/SRBMiner-Multi/releases/download/1.0.1/SRBMiner-Multi-1-0-1-win64.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\SRBMiner-MULTI.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# Algorithm parameter values are case sensitive!
$Algorithms = [PSCustomObject[]]@( 
   [PSCustomObject]@{ Algorithm = @("Autolykos2", "HeavyHash");   Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Autolykos2.DAGSizeGB;   MemReserveGB = 0.42; MinerSet = 0; WarmupTimes = @(45, 30); ExcludePool = @(); Arguments = " --algorithm autolykos2 --algorithm heavyhash --gpu-dual-max-loss 5 --gpu-auto-tune 2" }
   [PSCustomObject]@{ Algorithm = @("EtcHash", "HeavyHash");      Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludePool = @(); Arguments = " --algorithm etchash --algorithm heavyhash --gpu-dual-max-loss 5 --gpu-auto-tune 2" }
   [PSCustomObject]@{ Algorithm = @("Ethash", "Heavyhash");       Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludePool = @(); Arguments = " --algorithm ethash --algorithm heavyhash --gpu-dual-max-loss 5 --gpu-auto-tune 2" }
   [PSCustomObject]@{ Algorithm = @("EthashLowMem", "HeavyHash"); Type = "AMD"; Fee = @(0.0065, 0.01); MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.42; MinerSet = 1; WarmupTimes = @(90, 75); ExcludePool = @(); Arguments = " --algorithm ethash --algorithm heavyhash --gpu-dual-max-loss 5 --gpu-auto-tune 2" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm[0]).AvailablePorts -and (-not $_.Algorithm[1] -or $MinerPools[1].($_.Algorithm[1]).AvailablePorts) }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } | Select-Object | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = $_.MinMemGB + $_.MemReserveGB

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.Type -eq "CPU" -or ($_.MemoryGB -gt $MinMemGB) }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) + @(If ($_.Algorithm[1]) { "$($_.Algorithm[0])&$($_.Algorithm[1])" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algorithm") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --pool $($MinerPools[0].($_.Algorithm[0]).Host):$($MinerPools[0].($_.Algorithm[0]).AvailablePorts | Select-Object -Last 1) --wallet $($MinerPools[0].($_.Algorithm[0]).User)"
                If ($MinerPools[0].($_.Algorithm[0]).WorkerName) { " --worker $($MinerPools[0].($_.Algorithm[0]).WorkerName)" }
                $_.Arguments += " --password $($MinerPools[0].($_.Algorithm[0]).Pass)$(If ($MinerPools[0].($_.Algorithm[0]).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"
                If ($MinerPools[0].($_.Algorithm[0]).AvailablePorts[1]) { $_.Arguments += " --tls true" }
                If ($MinerPools[0].($_.Algorithm[0]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm[0]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --nicehash true" }
                If ($MinerPools[0].($_.Algorithm[0]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm[0]).BaseName -eq "ProHashing") { $_.Arguments += " --esm 1" }

                If ($_.Algorithm[1]) { 
                    $_.Arguments += " --pool $($MinerPools[0].($_.Algorithm[1]).Host):$($MinerPools[0].($_.Algorithm[1]).AvailablePorts | Select-Object -Last 1) --wallet $($MinerPools[0].($_.Algorithm[1]).User)"
                    If ($MinerPools[0].($_.Algorithm[1]).WorkerName) { " --worker $($MinerPools[0].($_.Algorithm[1]).WorkerName)" }
                    $_.Arguments += " --password $($MinerPools[0].($_.Algorithm[1]).Pass)"
                    If ($MinerPools[0].($_.Algorithm[1]).AvailablePorts[1]) { $_.Arguments += " --tls true" }
                    If ($MinerPools[0].($_.Algorithm[1]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm[1]).BaseName -in @("MiningPoolHub", "NiceHash", "ProHashing")) { $_.Arguments += " --nicehash true" }
                    If ($MinerPools[0].($_.Algorithm[1]).DAGsizeGB -ne $null -and $MinerPools[0].($_.Algorithm[1]).BaseName -eq "ProHashing") { $_.Arguments += " --esm 1" }
                }

                If (($AvailableMiner_Devices.Type | Select-Object -Unique) -eq "CPU") { 
                    $_.Arguments += " --cpu-threads $($AvailableMiner_Devices.CIM.NumberOfLogicalProcessors -1) --disable-gpu"
                }
                Else { 
                    $_.Arguments += " --gpu-auto-tune 2 --gpu-id $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',') --disable-cpu"
                }

                $PrerequisitePath = ""
                $PrerequisiteURI = ""
                If ($_.Algorithm -eq "VertHash" -and -not (Test-Path -Path ".\Bin\$($Name)\VertHash.dat" -ErrorAction SilentlyContinue)) { 
                    If ((Get-Item -Path $Variables.VerthashDatPath).length -eq 1283457024) { 
                        If (Test-Path -Path .\Bin\$($Name) -PathType Container) { 
                            New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath | Out-Null
                        }
                    }
                    Else { 
                        $PrerequisitePath = $Variables.VerthashDatPath
                        $PrerequisiteURI = "https://github.com/Minerx117/miners/releases/download/Verthash.Dat/VertHash.dat"
                    }
                }

                [PSCustomObject]@{ 
                    Name             = $Miner_Name
                    DeviceNames      = $AvailableMiner_Devices.Name
                    Type             = $AvailableMiner_Devices.Type
                    Path             = $Path
                    Arguments        = ("$($_.Arguments) --disable-workers-ramp-up --api-rig-name $($Config.WorkerName) --api-enable --api-port $MinerAPIPort" -replace "\s+", " ").trim()
                    Algorithms       = @($_.Algorithm[0], $_.Algorithm[1] | Select-Object)
                    API              = "SRBMiner"
                    Port             = $MinerAPIPort
                    URI              = $Uri
                    Fee              = $_.Fee # Dev fee
                    MinerUri         = "http://localhost:$($MinerAPIPort)/stats"
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                }
            }
        }
    }
}
