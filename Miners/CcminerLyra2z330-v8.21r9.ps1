using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccminer8.21r9-lyra2z330/releases/download/v3/ccminerlyra2z330v3.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";   MinMemGB = 2; Command = " --algo lyra2z330  --intensity 12.5 --statsavg 5" } #CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "Yescrypt";    MinMemGB = 2; Command = " --algo yescrypt  --intensity 15.2 --statsavg 5" }
#   [PSCustomObject]@{ Algorithm = "YescryptR16"; MinMemGB = 2; Command = " --algo yescryptr16 --intensity 13.4 --statsavg 5" } #CcminerLyraYesscrypt-v8.21r18v5 is fastest
#   [PSCustomObject]@{ Algorithm = "YescryptR32"; MinMemGB = 2; Command = " --algo yescryptr32 --intensity 12.55 --statsavg 5" } #CcminerLyraYesscrypt-v8.21r18v5 is fastest
    [PSCustomObject]@{ Algorithm = "YescryptR8";  MinMemGB = 2; Command = " --algo yescryptr8 --statsavg 5" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object { -not $Pools.($_.Algorithm).SSL } | ForEach-Object {

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo", "timeout") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$($_.Command) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --cpu-priority 4 --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "Ccminer"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                    }
                }
            }
        }
    }
}
