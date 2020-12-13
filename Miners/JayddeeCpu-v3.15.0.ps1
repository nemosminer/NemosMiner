using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\cpuminer-aes-sse42.exe" #Intel
$Uri = "https://github.com/JayDDee/cpuminer-opt/releases/download/v3.15.0/cpuminer-opt-3.15.0-windows.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Lyra2z330"; Command = " --algo lyra2z330" }
#   [PSCustomObject]@{ Algorithm = "m7m";       Command = " --algo sha3d" } #NosuchCpu-v3.8.8.1 is fastest
    [PSCustomObject]@{ Algorithm = "Sha3d";     Command = " --algo scrypt:2048" }
    [PSCustomObject]@{ Algorithm = "ScryptN11"; Command = " --algo m7m" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    If ($Miner_Devices = @($Devices | Where-Object Type -EQ "CPU")) { 
    
        If ($Miner_Devices.CpuFeatures -match "avx2")     { $Path = ".\Bin\$($Name)\cpuminer-Avx2.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "avx")  { $Path = ".\Bin\$($Name)\cpuminer-Avx.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "aes")  { $Path = ".\Bin\$($Name)\cpuminer-Aes-Sse42.exe" }
        ElseIf ($Miner_Devices.CpuFeatures -match "sse2") { $Path = ".\Bin\$($Name)\cpuminer-Sse2.exe" }
        Else { Return }

        $Miner_Devices | Select-Object Model -Unique | ForEach-Object { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)
            $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            $Commands | ForEach-Object {

                #Get commands for active miner devices
                #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).SSL) { $Protocol = "stratum+ssl" } Else { $Protocol = "stratum+tcp" }

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Type       = "CPU"
                    Path       = $Path
                    Arguments  = ("$($_.Command) --url $($Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --hash-meter --quiet --threads $($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --api-bind=$($MinerAPIPort)").trim()
                    Algorithm  = $_.Algorithm
                    API        = "Ccminer"
                    Port       = $MinerAPIPort
                    URI        = $Uri
                }
            }
        }
    }
}
