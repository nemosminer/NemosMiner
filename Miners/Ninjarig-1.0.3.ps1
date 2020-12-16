using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ninjarig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v1.0.3/ninjarig_v1.0.3.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Chukwa"; Command = " -a argon2/chukwa" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) {

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $Commands | ForEach-Object {

                # Get commands for active miner devices
                # $_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).Name -match "NiceHash*|MPH*") { $Commands.$_ += " --nicehash" } 

                $Commands | ForEach-Object { 
                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$($_.Command) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)$($Commands.$_) --keepalive --api-port=$MinerAPIPort --donate-level 0 -R 1 --use-gpu=CUDA -t $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "XmRig"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
