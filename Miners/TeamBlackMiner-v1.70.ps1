using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object { $_.Type -eq "AMD" -or ($_.Type -eq "NVIDIA" -and $_.CUDAVersion -ge "11.7") })) { Return }

$Uri = "https://github.com/Minerx117/miners/releases/download/TeamBlackMiner/TeamBlackMiner_1_70_cuda_11_7.zip"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\TBMiner.exe"

$DeviceSelector = @{ AMD = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = @{ AMD = "Type_Vendor_Id"; NVIDIA = "Type_Vendor_Index" } # Device numeration seems to be mixed up with OpenCL

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "AMD"; Fee = 0.005; MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.41; ExcludePool = @(); MinerSet = 0; Tuning = ""; WarmupTimes = @(45, 0); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; Fee = 0.005; MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.41; ExcludePool = @(); MinerSet = 0; Tuning = ""; WarmupTimes = @(45, 0); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; Fee = 0.005; MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.41; ExcludePool = @(); MinerSet = 1; Tuning = ""; WarmupTimes = @(45, 0); Arguments = " --algo ethash"} # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "AMD"; Fee = 0.01;  MinMemGB = $MinerPools[0].KawPoW.DAGSizeGB;       MemReserveGB = 0;    ExcludePool = @(); MinerSet = 1; Tuning = ""; WarmupTimes = @(60, 0); Arguments = " --algo kawpow" }
    [PSCustomObject]@{ Algorithm = "VertHash";     Type = "AMD"; Fee = 0.01;  MinMemGB = 2.0;                                   MemReserveGB = 0;    ExcludePool = @(); MinerSet = 1; Tuning = ""; WarmupTimes = @(60, 0); Arguments = " --algo verthash" }

    [PSCustomObject]@{ Algorithm = "EtcHash";      Type = "NVIDIA"; Fee = 0.005; MinMemGB = $MinerPools[0].Etchash.DAGSizeGB;      MemReserveGB = 0.41; ExcludePool = @(); MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(45, 0); Arguments = " --algo etchash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; Fee = 0.005; MinMemGB = $MinerPools[0].Ethash.DAGSizeGB;       MemReserveGB = 0.41; ExcludePool = @(); MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(45, 0); Arguments = " --algo ethash" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; Fee = 0.005; MinMemGB = $MinerPools[0].EthashLowMem.DAGSizeGB; MemReserveGB = 0.41; ExcludePool = @(); MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 0); Arguments = " --algo ethash" } # TTMiner-v5.0.3 is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";       Type = "NVIDIA"; Fee = 0.01;  MinMemGB = $MinerPools[0].KawPoW.DAGSizeGB;       MemReserveGB = 0;    ExcludePool = @(); MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(60, 0); Arguments = " --algo kawpow" }
    [PSCustomObject]@{ Algorithm = "VertHash";     Type = "NVIDIA"; Fee = 0.01;  MinMemGB = 2.0;                                   MemReserveGB = 0;    ExcludePool = @(); MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(60, 0); Arguments = " --algo verthash" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Where-Object Type -in @($Algorithms.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object { $MinerPools[0].($_.Algorithm).BaseName -notin $_.ExcludePool } | Where-Object Type -EQ $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Arguments = $_.Arguments
                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "cl-devices", "cuda-devices", "tweak") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Arguments += " --hostname $($MinerPools[0].($_.Algorithm).Host) --wallet $($MinerPools[0].($_.Algorithm).User)"
                $Arguments += If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { " --ssl --ssl-port $($MinerPools[0].($_.Algorithm).PoolPorts[1])" } Else { " --port $($MinerPools[0].($_.Algorithm).PoolPorts[0])"}
                If ($MinerPools[0].($_.Algorithm).WorkerName) { $Arguments += " --worker-name $($MinerPools[0].($_.Algorithm).WorkerName)" }
                If ($MinerPools[0].($_.Algorithm).Pass) { $Arguments += " --server-passwd $($MinerPools[0].($_.Algorithm).Pass)$(If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })" }
                If ($MinerPools[0].($_.Algorithm).BaseName -eq "ProHashing") {  }
                # Apply tuning parameters
                If ($Variables.UseMinerTweaks -eq $true) { $Arguments += $_.Tuning }

                $PrerequisitePath = ""
                $PrerequisiteURI = ""
                If ($_.Algorithm -eq "VertHash" -and -not (Test-Path -Path ".\Bin\$($Name)\VertHash.dat" -ErrorAction SilentlyContinue)) { 
                    If ((Get-Item -Path $Variables.VerthashDatPath).length -eq 1283457024) { 
                        If (Test-Path -Path .\Bin\$($Name) -PathType Container) { 
                            [void](New-Item -ItemType HardLink -Path ".\Bin\$($Name)\VertHash.dat" -Target $Variables.VerthashDatPath)
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
                    Arguments        = ("$($Arguments) --api --api-port $MinerAPIPort$($DeviceSelector.($AvailableMiner_Devices.Type)) [$(($AvailableMiner_Devices.($DeviceEnumerator.($AvailableMiner_Devices.Type)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')]" -replace "\s+", " ").trim()
                    Algorithms       = @($_.Algorithm)
                    API              = "TeamBlackMiner"
                    Port             = $MinerAPIPort
                    URI              = $Uri
                    Fee              = $_.Fee
                    MinerUri         = "http://localhost:$($MinerAPIPort)/threads"
                    WarmupTimes      = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                    PrerequisitePath = $PrerequisitePath
                    PrerequisiteURI  = $PrerequisiteURI
                }
            }
        }
    }
}
