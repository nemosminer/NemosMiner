using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\nsfminer.exe"
$Uri = "https://github.com/no-fee-ethereum-mining/nsfminer/releases/download/v1.3.11/nsfminer_1.3.11-windows_10-cuda_11.2-opencl.zip"
$DeviceEnumerator = "Type_Vendor_Slot"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Ethash"; Type = "AMD";    MinerSet = 0; Arguments = " --opencl --devices" } # May need https://github.com/ethereum-mining/ethminer/issues/2001
    [PSCustomObject]@{ Algorithm = "Ethash"; Type = "NVIDIA"; MinerSet = 0; Arguments = " --cuda --devices" } # PhoenixMiner-v5.5c is fastest but has dev fee
)

$Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 
    If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

        $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

        $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object Type -eq $_.Type | Where-Object { $Pools.($_.Algorithm).Host } | ForEach-Object { 

            $MinMem = $Pools.($_.Algorithm).DAGSize + $DAGmemReserve

            If ($Miner_Devices = @($SelectedDevices | Where-Object { $_.OpenCL.GlobalMemSize -ge $MinMem })) {

                $Miner_Name = (@($Name) + @($SelectedDevices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                # Get arguments for active miner devices
                # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @() -DeviceIDs $Miner_Devices.$DeviceEnumerator

                If ($Pools.($_.Algorithm).Name -match "^NiceHash$|^MiningPoolHub(|Coins)$|^ZergPool(|Coins)") { $Protocol = "-P stratum2+tcp" }
                ElseIf ($Pools.($_.Algorithm).Name -like "HiveON*") { $Protocol = "-P stratum1+tcp" }
                Else { $Protocol = "-P stratum+tcp" }

                If ($Pools.($_.Algorithm).SSL) { $Protocol = $Protocol -replace "tcp", "ssl" }

                [PSCustomObject]@{ 
                    Name       = $Miner_Name
                    DeviceName = $Miner_Devices.Name
                    Type       = $_.Type
                    Path       = $Path
                    Arguments  = ("$($Protocol)://$([System.Web.HttpUtility]::UrlEncode($Pools.($_.Algorithm).User)):$($Pools.($_.Algorithm).Pass)@$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --api-port -$MinerAPIPort $($_.Arguments) $(($Miner_Devices | Sort-Object $DeviceEnumerator -Unique | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ' ')" -replace "\s+", " ").trim()
                    Algorithm  = $_.Algorithm
                    API        = "EthMiner"
                    Port       = $MinerAPIPort
                    Wrap       = $false
                    URI        = $Uri
                    MinerUri   = "http://localhost:$($MinerAPIPort)"
                    WarmupTime = 30 # Seconds, additional wait time until first data sample
                }
            }
        }
    }
}

