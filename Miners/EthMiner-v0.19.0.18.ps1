using module ..\Includes\Include.psm1

If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -in @("AMD", "NVIDIA"))) { Return }

$Uri = Switch ($Variables.DriverVersion.CUDA) { 
    { $_ -ge "11.6" } { "https://github.com/Minerx117/miners/releases/download/EthMiner/ethminer-0.19.0-18-cuda11.6-windows-vs2019-amd64.zip"; Break }
    { $_ -ge "10.0" } { "https://github.com/Minerx117/miners/releases/download/EthMiner/ethminer-0.19.0-18-cuda10.0-windows-amd64.zip"; Break }
    { $_ -ge "9.2" }  { "https://github.com/Minerx117/miners/releases/download/EthMiner/ethminer-0.19.0-18-cuda9.1-windows-amd64.zip"; Break }
    Default { Return }
}
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\ethminer.exe"
$DeviceEnumerator = "Type_Vendor_Slot"

# AMD miners may need https://github.com/ethereum-mining/ethminer/issues/2001
# NVIDIA Enable Hardware-Accelerated GPU Scheduling

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "AMD"; MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.41; ExcludePool = @("ZergPool"); MinerSet = 0.29; WarmupTimes = @(45, 0); Arguments = " --opencl --opencl-devices" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "AMD"; MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; ExcludePool = @("ZergPool"); MinerSet = 0.28; WarmupTimes = @(45, 0); Arguments = " --opencl --opencl-devices" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool

    [PSCustomObject]@{ Algorithm = "Ethash";       Type = "NVIDIA"; MinMemGB = $Pools."Ethash".DAGSizeGB;       MemReserveGB = 0.41; ExcludePool = @("ZergPool"); MinerSet = 0.29; WarmupTimes = @(45, 0); Arguments = " --cuda --cuda-devices" } # PhoenixMiner-v6.2c is fastest but has dev fee
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Type = "NVIDIA"; MinMemGB = $Pools."EthashLowMem".DAGSizeGB; MemReserveGB = 0.41; ExcludePool = @("ZergPool"); MinerSet = 0.28; WarmupTimes = @(45, 0); Arguments = " --cuda --cuda-devices" } # PhoenixMiner-v6.2c may be faster, but I see lower speed at the pool
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object { $Pools.($_.Algorithm).BaseName -notin $_.ExcludePool } | Where-Object Type -eq $_.Type | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGB -ge ($_.MinMemGB + $_.MemReserveGB)) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @() -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Pass = "$($Pools.($_.Algorithm).Pass)$(If ($Pools.($_.Algorithm).BaseName -eq "ProHashing" -and $_.Algorithm -eq "EthashLowMem") { ",l=$((($AvailableMiner_Devices.Memory | Measure-Object -Minimum).Minimum) / 1GB - $_.MemReserveGB)" })"

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceNames = $AvailableMiner_Devices.Name
                    Type        = $AvailableMiner_Devices.Type
                    Path        = $Path
                    Arguments   = (" --pool stratum$(If ($Pools.($_.Algorithm).SSL) { "+ssl" })://$([System.Web.HttpUtility]::UrlEncode("$($Pools.($_.Algorithm).User)$(If ($Pools.($_.Algorithm).WorkerName) { ".$($Pools.($_.Algorithm).WorkerName)" })")):$([System.Web.HttpUtility]::UrlEncode($Pass))@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --exit --api-port -$MinerAPIPort $($_.Arguments) $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    MinerUri    = "http://localhost:$($MinerAPIPort)"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
