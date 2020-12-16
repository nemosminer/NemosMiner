using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\z-enemy.exe"
$Uri = "https://github.com/zealot-rvn/z-enemy/releases/download/kawpow262/z-enemy-2.6.2-win-cuda10.1.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Aergo";  MinMemGB = 1; Command = " --algo aergo --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Xevan";  MinMemGB = 2; Command = " --algo xevan --intensity 22" }
    [PSCustomObject]@{ Algorithm = "Hex";    MinMemGB = 1; Command = " --algo hex --intensity 24" }
#   [PSCustomObject]@{ Algorithm = "KawPoW"; MinMemGB = 3; Command = " --algo kawpow --intensity 23" } # NBMiner-v34.5 is fastest but has optional 1% fee
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model | Sort-Object $DeviceEnumerator)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | ForEach-Object {
                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get commands for active miner devices
                    # $_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$($_.Command) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --api-bind 0 --api-bind-http $MinerAPIPort --retry-pause 1 --quiet --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "Trex"
                        Port       = $MinerAPIPort
                        Wrap       = $false
                        URI        = $Uri
                        Fee        = 0.01 # dev fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
