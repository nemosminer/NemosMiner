using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\cpuminer-sse42.exe"
$Uri = "https://github.com/rplant8/cpuminer-opt-rplant/releases/download/4.5.11/cpuminer-opt-win.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Lyra2z330";    Command = " --algo lyra2z330" } #JayddeeCpu-v3.14.3 is fastest
    [PSCustomObject]@{ Algorithm = "YespowerIots"; Command = " --algo yespoweriots" }
    [PSCustomObject]@{ Algorithm = "Yespower";     Command = " --algo yespower" }
    [PSCustomObject]@{ Algorithm = "YespowerR16";  Command = " --algo yespowerr16" }
#   [PSCustomObject]@{ Algorithm = "YescryptR8";   Command = " --algo yescryptr8" } #CcminerLyraYesscrypt-v8.21r18v5 is faster
    [PSCustomObject]@{ Algorithm = "YescryptR8g";  Command = " --algo yescryptr8g" }
    [PSCustomObject]@{ Algorithm = "Yescrypt";     Command = " --algo yescrypt" }
    [PSCustomObject]@{ Algorithm = "YescryptR32";  Command = " --algo yescryptr32" }
    [PSCustomObject]@{ Algorithm = "YespowerItc";  Command = " --algo yespoweritc" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 

        $Miner_Devices | Select-Object Model -Unique | ForEach-Object { 
            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $Commands | ForEach-Object {

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Type       = "CPU"
                    Path       = $Path
                    Arguments  = ("$($_.Command) --url $($Pools.($_.Algorithm).Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --cpu-affinity AAAA --quiet --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
                    Algorithm  = $_.Algorithm
                    API        = "Ccminer"
                    Port       = $MinerAPIPort
                    URI        = $Uri
                }
            }
        }
    }
}