using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\cpuminer.exe" 
$Uri = "https://github.com/fireworm71/veriumMiner/releases/download/v1.4/cpuminer_1.4_windows_x64_O2_GCC7.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "ScryptN2"; Command = "" } #Empty command
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        $Miner_Devices | Select-Object Model -Unique | ForEach-Object { 
            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $Commands | ForEach-Object {

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Type       = "CPU"
                    Path       = $Path
                    Arguments  = ("$($_.Command) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --retry-pause 1 --api-bind $MinerAPIPort" -replace "\s+", " ").trim()
                    Algorithm  = $_.Algorithm
                    API        = "Ccminer"
                    Port       = $MinerAPIPort
                    URI        = $Uri
                    WarmupTime = 90 #seconds
                }
            }
        }
    }
}
