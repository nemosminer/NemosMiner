using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccmineralexis78/releases/download/v1.5.2/ccmineralexis78.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject]@{ 
    "C11"       = " --algo c11 --intensity 22"
#   "Keccak"    = " --algo keccak --diff-multiplier 2 --intensity 29" #CcminerKlausT-v8.25 is fastest
#   "Lyra2RE2"  = " --algo lyra2v2" #Profit very small
#   "Neoscrypt" = " --algo neoscrypt --intensity 15.5" #CryptoDredge is fastest
#   "Skein"     = " --algo skein" #CcminerKlausT-v8.25 is fastest
    "Skein2"    = " --algo skein2 --intensity 31"
#   "Veltor"    = " --algo veltor --intensity 23" #No pool
#   "Whirlcoin" = " --algo whirlcoin" #No pool
#   "Whirlpool" = " --algo whirlpool" # No pool
#   "X11evo"    = " --algo x11evo --intensity 21" #No pool
    "X17"       = " --algo x17 --intensity 22.1"
}
$Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.$_.Host } | Where-Object { -not $Pools.$_.SSL } | ForEach-Object {

            #Get commands for active miner devices
            #$Commands.$_ = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Type       = "NVIDIA"
                Path       = $Path
                Arguments  = ("$($Commands.$_) --url stratum+tcp://$($Pools.$_.Host):$($Pools.$_.Port) --user $($Pools.$_.User) --pass $($Pools.$_.Pass) --retry-pause 1 --api-bind $MinerAPIPort --cuda-schedule 2 --devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ',')" -replace "\s+", " ").trim()
                Algorithm  = $_
                API        = "Ccminer"
                Port       = $MinerAPIPort
                URI        = $Uri
            }
        }
    }
}
