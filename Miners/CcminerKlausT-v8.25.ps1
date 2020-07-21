using module ..\Includes\Include.psm1

$Path = ".\Bin\$($Name)\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccmineralexis78/releases/download/v1.5.1/ccminerAlexis78cuda75x64.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject]@{ 
    "C11"       = " --algo c11 --intensity 22" #X11evo; fix for default intensity
    "Keccak"    = " --algo keccak --diff-multiplier 2" #Keccak; fix for default intensity, difficulty x M
    "Lyra2v2"   = " --algo lyra2v2" #lyra2v2
#    "Neoscrypt" = " --algo neoscrypt --intensity 15.5" #NCryptoDredge is fastest
    "Skein"     = " --algo skein --intensity 31" #skein
    "Veltor"    = " --algo veltor --intensity 23" #Veltor; fix for default intensity
    "Whirlcoin" = " --algo whirlcoin" #WhirlCoin
    "Whirlpool" = " --algo whirlpool" #Whirlpool
    "X11evo"    = " --algo x11evo --intensity 21" #X11evo; fix for default intensity
    "X17"       = " --algo x17 --intensity 22" #x17; fix for default intensity
}

$Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($Miner_Devices = @($Devices | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

        $Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Where-Object { $Pools.$_.Host } | Where-Object { -not $Pools.$_.SSL } | ForEach-Object {

            #Get commands for active miner devices
            #$Commands.$_ = Get-CommandPerDevice -Command $Commands.$_ -ExcludeParameters @("algo", "timeout") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Path       = $Path
                Arguments  = ("$($Commands.$_) --url stratum+tcp://$($Pools.$_.Host):$($Pools.$_.Port) --user $($Pools.$_.User) --pass $($Pools.$_.Pass) --cpu-priority 4 --timeout 50000 --retry-pause 1 --api-bind $MinerAPIPort --devices $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ',')" -replace "\s+", " ").trim()
                Algorithm  = $_
                API        = "Ccminer"
                Port       = $MinerAPIPort
                URI        = $Uri
            }
        }
    }
}
