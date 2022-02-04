using module ..\Includes\Include.psm1

If (-not ($Devices = $Devices | Where-Object { $_.Type -eq "AMD" -or ($_.Type -eq "NVIDIA" -and $_.OpenCl.ComputeCapability -ge "5.0") })) { Return }

$Uri = Switch ($DriverVersion.CUDA) { 
    # { $_ -ge "11.6" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.39/TeamBlackMiner_1_39_cuda_11_6.7z" }
    { $_ -ge "11.5" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.49/TeamBlackMiner_1_49_cuda_11_5.7z" }
    # { $_ -ge "11.4" } { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.39/TeamBlackMiner_1_39_cuda_11_4.7z" }
    Default           { "https://github.com/sp-hash/TeamBlackMiner/releases/download/v1.49/TeamBlackMiner_1_49_cuda_11_4.7z" }
}
$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\TBMiner.exe"

# $DeviceEnumerator = "Type_Vendor_Id"
$DAGmemReserve = [Math]::Pow(2, 23) * 18 # Number of epochs
$DeviceSelector = @{ AMD = " --cl-devices"; NVIDIA = " --cuda-devices" }
$DeviceEnumerator = @{ AMD = "Type_Vendor_Id"; NVIDIA = "Type_Vendor_Index" } # Device numeration seems to be mixed up with OpenCL

$Algorithms = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "EtcHash";      Fee = 0.005; MinMemGB = 3.0; Type = "AMD"; MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); Arguments = " --algo etchash" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.005; MinMemGB = 5.0; Type = "AMD"; MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); Arguments = " --algo ethash" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.005; MinMemGB = 2.0; Type = "AMD"; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); Arguments = " --algo ethash"} # TTMiner-v5.0.3 is fastest
    # [PSCustomObject]@{ Algorithm = "VertHash";     Fee = 0.01;  MinMemGB = 4.0; Type = "AMD"; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 180); Arguments = " --algo vertcoin" }

    [PSCustomObject]@{ Algorithm = "EtcHash";      Fee = 0.005; MinMemGB = 3.0; Type = "NVIDIA"; MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); Arguments = " --algo etchash" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "Ethash";       Fee = 0.005; MinMemGB = 5.0; Type = "NVIDIA"; MinerSet = 0; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); Arguments = " --algo ethash" } # PhoenixMiner-v5.9d may be faster, but I see lower speed at the pool
    [PSCustomObject]@{ Algorithm = "EthashLowMem"; Fee = 0.005; MinMemGB = 2.0; Type = "NVIDIA"; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 30); Arguments = " --algo ethash" } # TTMiner-v5.0.3 is fastest
    # [PSCustomObject]@{ Algorithm = "VertHash";     Fee = 0.01;  MinMemGB = 4.0; Type = "NVIDIA"; MinerSet = 1; Tuning = " --tweak 2"; WarmupTimes = @(45, 180); Arguments = " --algo vertcoin" }
)

If ($Algorithms = $Algorithms | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -in @($Algorithms.Type) | Select-Object Type, Model -Unique | ForEach-Object { 

        $Miner_Devices = $Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model

        $MinerAPIPort = [UInt16]($Config.APIPort + ($Miner_Devices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $Algorithms | Where-Object Type -EQ $_.Type | ConvertTo-Json | ConvertFrom-Json | ForEach-Object { 

            $MinMemGB = If ($Pools.($_.Algorithm).DAGSize -gt 0) { ((($Pools.($_.Algorithm).DAGSize + $DAGmemReserve) / 1GB), $_.MinMemGB | Measure-Object -Maximum).Maximum } Else { $_.MinMemGB }

            If ($AvailableMiner_Devices = $Miner_Devices | Where-Object { $_.OpenCL.GlobalMemSize / 0.99GB -ge $MinMemGB }) { 

                $Miner_Name = (@($Name) + @($AvailableMiner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($AvailableMiner_Devices | Where-Object Model -EQ $Model).Count)x$Model" }) | Select-Object) -join '-' -replace ' '

                # Get arguments for available miner devices
                # $_.Arguments = Get-ArgumentsPerDevice -Arguments $_.Arguments -ExcludeArguments @("algo", "cl-devices", "cuda-devices", "tweak") -DeviceIDs $AvailableMiner_Devices.$DeviceEnumerator

                $_.Arguments += " --hostname $($Pools.($_.Algorithm).Host) --port $($Pools.($_.Algorithm).Port) --wallet $($Pools.($_.Algorithm).User -split '\.' | Select-Object -First 1) --worker-name $($Config.Workername) --server-passwd $($Pools.($_.Algorithm).Pass)"
                If ($Pools.($_.Algorithm).BaseName -match "^ProHashing$" -and $_.Algorithm -eq "EthashLowMem") { $_.Arguments += ",l=$((($Miner_Devices.OpenCL.GlobalMemSize | Measure-Object -Minimum).Minimum - $DAGmemReserve) / 1GB)" }

                If ($Pools.($_.Algorithm).SSL) { $_.Arguments += " --ssl" }

                If ($Config.UseMinerTweaks -eq $true -and $_.Type -eq "NVIDIA") { $_.Arguments += $_.Tuning }

                [PSCustomObject]@{ 
                    Name        = $Miner_Name
                    DeviceName  = $AvailableMiner_Devices.Name
                    Type        = $_.Type
                    Path        = $Path
                    Arguments   = ("$($_.Arguments) --api --api-port $MinerAPIPort$($DeviceSelector.($_.Type)) [$(($AvailableMiner_Devices.($DeviceEnumerator.($_.Type)) | Sort-Object -Unique | ForEach-Object { '{0:x}' -f $_ }) -join ',')]" -replace "\s+", " ").trim()
                    Algorithm   = $_.Algorithm
                    API         = "TeamBlackMiner"
                    Port        = $MinerAPIPort
                    URI         = $Uri
                    Fee         = $_.Fee
                    MinerUri    = "http://localhost:$($MinerAPIPort)/threads"
                    WarmupTimes = $_.WarmupTimes # First value: seconds until miner must send first sample, if no sample is received miner will be marked as failed; Second value: seconds until miner sends stable hashrates that will count for benchmarking
                }
            }
        }
    }
}
