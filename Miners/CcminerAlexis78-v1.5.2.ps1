using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\ccminer.exe"
$Uri = "https://github.com/Minerx117/ccmineralexis78/releases/download/v1.5.2/ccmineralexis78.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "C11";       MinMemGB = 2; Command = " --algo c11 --intensity 22" }
#   [PSCustomObject]@{ Algorithm = "Keccak";    MinMemGB = 2; Command = " --algo keccak --diff-multiplier 2 --intensity 29" } #Profit very small
#   [PSCustomObject]@{ Algorithm = "Lyra2RE2";  MinMemGB = 2; Command = " --algo lyra2v2" } #Profit very small
#   [PSCustomObject]@{ Algorithm = "NeoScrypt"; MinMemGB = 2; Command = " --algo neoscrypt --intensity 15.5" } #CryptoDredge is fastest
#   [PSCustomObject]@{ Algorithm = "Skein";     MinMemGB = 2; Command = " --algo skein" } #Profit very small
    [PSCustomObject]@{ Algorithm = "Skein2";    MinMemGB = 2; Command = " --algo skein2 --intensity 31" }
    [PSCustomObject]@{ Algorithm = "Veltor";    MinMemGB = 2; Command = " --algo veltor --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Whirlcoin"; MinMemGB = 2; Command = " --algo whirlcoin" }
    [PSCustomObject]@{ Algorithm = "Whirlpool"; MinMemGB = 2; Command = " --algo whirlpool" }
    [PSCustomObject]@{ Algorithm = "X11evo";    MinMemGB = 2; Command = " --algo x11evo --intensity 21" }
    [PSCustomObject]@{ Algorithm = "X17";       MinMemGB = 2; Command = " --algo x17 --intensity 22.1" }
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
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "NVIDIA"
                        Path       = $Path
                        Arguments  = ("$($_.Command) --url stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --retry-pause 1 --api-bind $MinerAPIPort --cuda-schedule 2 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
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
