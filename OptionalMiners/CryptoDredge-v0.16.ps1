using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\CryptoDredge.exe"
$Uri = "https://github.com/technobyl/CryptoDredge/releases/download/v0.16.0/CryptoDredge_0.16.0_cuda_10.0_windows.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
#   [PSCustomObject]@{ Algorithm = "Allium";    Fee = 0.01; MinMemGB = 2; Command = " --algo=allium --intensity 8" } # CryptoDredge v0.23 ist fastest
#   [PSCustomObject]@{ Algorithm = "Exosis";    Fee = 0.01; MinMemGB = 2; Command = " --algo=exosis --intensity 8" } # No pool
    [PSCustomObject]@{ Algorithm = "Dedal";     Fee = 0.01; MinMemGB = 2; Command = " --algo=dedal --intensity 8" }
#   [PSCustomObject]@{ Algorithm = "Hmq1725";   Fee = 0.01; MinMemGB = 2; Command = " --algo=hmq1725 --intensity 8" } # CryptoDredge v0.23 ist fastest
#   [PSCustomObject]@{ Algorithm = "NeoScrypt"; Fee = 0.01; MinMemGB = 2; Command = " --algo=neoscrypt --intensity 6 " } #Cryptodredge v0.23 is fastest
    [PSCustomObject]@{ Algorithm = "Phi";       Fee = 0.01; MinMemGB = 2; Command = " --algo=phi --intensity 8" }
    [PSCustomObject]@{ Algorithm = "Phi2";      Fee = 0.01; MinMemGB = 2; Command = " --algo=phi2 --intensity 8" }
#   [PSCustomObject]@{ Algorithm = "Pipe";      Fee = 0.01; MinMemGB = 2; Command = " --algo=pipe --intensity 8" } # No pool
)

$Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 
        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Commands | Where-Object { $Pools.($_.Algorithm).Host } | ForEach-Object {
            If ($_.Algorithm -eq "Phi2" -and $Pools.($_.Algorithm).Name -like "ZergPool*") { return }
            $MinMemGB = $_.MinMemGB

            If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 
                $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo", "intensity") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Type       = "NVIDIA"
                    Path       = $Path
                    Arguments  = ("$($_.Command) --url=stratum+tcp://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --timeout 180 --cpu-priority 4 --no-watchdog --retries 1 --retry-pause 1 --api-type ccminer-tcp --api-bind=127.0.0.1:$($MinerAPIPort) --device $(($Miner_Devices | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                    Algorithm  = $_.Algorithm
                    API        = "Ccminer"
                    Port       = $MinerAPIPort
                    Wrap       = $false
                    URI        = $Uri
                    Fee        = $_.Fee # Dev fee
                }
            }
        }
    }
}
