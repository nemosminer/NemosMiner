If (-not ($Devices = $Variables.EnabledDevices | Where-Object Type -EQ "NVIDIA")) { Return }

$Uri = "https://github.com/EvrmoreOrg/evrprogpowminer/releases/download/v1.3.0-a66d921b/evrprogpowminer-windows64-v1p3p0-a66d921b.7z"
$Name = (Get-Item $MyInvocation.MyCommand.Path).BaseName
$Path = ".\Bin\$($Name)\evrprogpowminer.exe"
$DeviceEnumerator = "Type_Vendor_Index"

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EvrProgPow"; MinMemGiB = $MinerPools[0].EvrProgPow.DAGSizeGiB + 0.77; Minerset = 2; WarmupTimes = @(75, 10); ExcludePool = @(); Arguments = "" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $MinerPools[0].($_.Algorithm).PoolPorts }) { 

    $Devices | Select-Object Model -Unique | ForEach-Object { 

        $Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | ForEach-Object { 

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object MemoryGiB -ge $_.MinMemGiB | Where-Object Architecture -notin $_.ExcludeGPUArchitecture) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $Arguments = Get-ArgumentsPerDevice -Arguments $Arguments -ExcludeArguments @("algo", "pers", "proto") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $Protocol = Switch ($MinerPools[0].($_.Algorithm).Protocol) { 
                    "ethproxy"     { "stratum1" }
                    "ethstratum"   { "stratum1" }
                    "ethstratum1"  { "stratum2" }
                    "ethstratum2"  { "stratum2" }
                    Default        { "stratum" }
                }
                $Protocol += If ($MinerPools[0].($_.Algorithm).PoolPorts[1]) { "+tls" } Else { "+tcp" }
                [PSCustomObject]@{ 
                    Algorithms  = @($_.Algorithm)
                    API         = "EthMiner"
                    Arguments   = ("--pool $($Protocol)://$([System.Web.HttpUtility]::UrlEncode("$($MinerPools[0].($_.Algorithm).User)$(If ($MinerPools[0].($_.Algorithm).WorkerName) { ".$($MinerPools[0].($_.Algorithm).WorkerName)" })")):$([System.Web.HttpUtility]::UrlEncode($($MinerPools[0].($_.Algorithm).Pass)))@$($MinerPools[0].($_.Algorithm).Host):$($MinerPools[0].($_.Algorithm).PoolPorts | Select-Object -Last 1) --farm-recheck 10000 --farm-retries 40 --work-timeout 100000 --response-timeout 720 --api-port -$($MinerAPIPort) --cuda --cuda-devices $(($AvailableMiner_Devices.$DeviceEnumerator | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')" -replace "\s+", " ").trim()
                    DeviceNames = $AvailableMiner_Devices.Name
                    EnvVars     = @("SSL_NOVERIFY=TRUE")
                    MinerSet     = $_.MinerSet
                    Name        = $Miner_Name
                    Path        = $Path
                    Port        = $MinerAPIPort
                    Type        = ($AvailableMiner_Devices.Type | Select-Object -Unique)
                    URI         = $Uri
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: Seconds from first sample until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}

$Error.Clear()