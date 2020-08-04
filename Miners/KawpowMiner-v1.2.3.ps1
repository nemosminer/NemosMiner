using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\kawpowminer.exe"
$Uri = "https://github.com/RavenCommunity/kawpowminer/releases/download/1.2.3/kawpowminer-windows-1.2.3.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject]@{ 
#   "KawPoW" = "" #Wildrig 0.25.2 is fastest
}

$Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.$_.Host } | ForEach-Object {

            #Get commands for active miner devices
            #$Commands.$_ = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo", "pers", "proto") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Type       = "NVIDIA"
                Path       = $Path
                Arguments  = ("--pool stratum$(If ($Pool.$_.SSL) { "s" } )+tcp://$([System.Web.HttpUtility]::UrlEncode($Pools.$_.User)):$([System.Web.HttpUtility]::UrlEncode($Pools.$_.Pass))@$($Pools.$_.Host):$($Pools.$_.Port) --farm-recheck 10000 --farm-retries 40 --work-timeout 100000 --response-timeout 720 --api-port -$($MinerAPIPort) --cuda --cuda-devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ',')" -replace "\s+", " ").trim()
                Algorithm  = $_
                API        = "EthMiner"
                Port       = $MinerAPIPort
                URI        = $Uri
            }
        }
    }
}
