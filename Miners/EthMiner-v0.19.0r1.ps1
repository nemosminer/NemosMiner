using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ethminer.exe"
$Uri = "https://github.com/Minerx117/ethminer/releases/download/v0.19.0-r1/ethminer-0.19.0cuda10.0.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Ethash"; MinMemGB = 4; Type = "AMD";    Command = " --opencl --opencl-devices" } #PhoenixMiner is fastest
#   [PSCustomObject]@{ Algorithm = "Ethash"; MinMemGB = 4; Type = "NVIDIA"; Command = " --cuda --cuda-devices" } #PhoenixMiner is fastest
)

$Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($SelectedDevices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $Commands | Where-Object Type -eq $_.Type | Where-Object { $Pools.($_.Algorithm).Host } | ForEach-Object { 
            $MinMemGB = $_.MinMemGB

            If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @() -DeviceIDs $Miner_Devices.$DeviceEnumerator

                $Protocol = "stratum$(If ($Pools.($_.Algorithm).Name -match "MPH*|NiceHash*") { "2" })$(If ($Pools.($_.Algorithm).SSL) { "+ssl" } Else { "+tcp" })://"

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Type       = $_.Type
                    Path       = $Path
                    Arguments  = ("-P $Protocol$(If ($Pools.($_.Algorithm).Name -like "MPH*") { $($Pools.($_.Algorithm).User -replace "\.", "%2e") } Else { $($Pools.($_.Algorithm).User) }):$($Pools.($_.Algorithm).Pass)@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --farm-recheck 5000 --farm-retries 40 --work-timeout 50000 --response-timeout 360 --api-port -$MinerAPIPort $($_.Command) $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithm  = $_.Algorithm
                    API        = "EthMiner"
                    Port       = $MinerAPIPort
                    Wrap       = $false
                    URI        = $Uri
                    MinerUri   = "http://localhost:$($MinerAPIPort)"
                }
            }
        }
    }
}
