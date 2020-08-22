using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/5.9.0/XMRig590.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
#    [PSCustomObject]@{ Algorithm = "CryptonightGpu"; MinMemGB = 1; Type = "AMD"; Command = " --algo cn/gpu" } #XmrStak-v2.10.8 is fastest
#    [PSCustomObject]@{ Algorithm = "CryptonightGpu"; MinMemGB = 1; Type = "NVIDIA"; Command = " --algo cn/gpu" } #XmrStak-v2.10.8 is fastest
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 
                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    If ($_.Type -eq "AMD") { $_.Command += " --no-cpu --opencl --opencl-devices=$(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ' ')" }
                    ElseIf ($_.Type -eq "NVIDIA") { $_.Command += " --no-cpu --cuda --cuda-devices=$(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ' ')" }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("$($_.Command) $(If ($Pools.($_.Algorithm).Name -eq "NiceHash") { " --nicehash" } )$(If ($Pools.($_.Algorithm).SSL) { " --tls" } ) --url=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --keepalive --http-enabled --http-host=127.0.0.1 --http-port=$($MinerAPIPort) --api-worker-id=$($Config.WorkerName) --api-id=$($Miner_Name) --donate-level 0 --retries=90 --retry-pause=1" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "XmRig"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        WarmupTime = 60 #seconds
                        MinerUri   = "http://workers.xmrig.info/worker?url=$([System.Web.HTTPUtility]::UrlEncode("http://localhost:$($MinerAPIPort)"))?Authorization=Bearer $([System.Web.HTTPUtility]::UrlEncode($Miner_Name))"
                    }
                }
            }
        }
    }
}
