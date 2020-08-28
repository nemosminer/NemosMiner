using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\teamredminer.exe"
$Uri = "https://github.com/todxx/teamredminer/releases/download/0.7.9/teamredminer-v0.7.9-win.zip"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Chukwa";               Fee = 0.025; MinMemGB = 2.0; Command = " --algo=trtl_chukwa" }
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cn_conceal --rig_id $($Config.WorkerName)" }
#   [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cn_heavy --rig_id $($Config.WorkerName)" } #XmRigGpu-v6.3.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightHaven";     Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cn_haven --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cn_saber --rig_id $($Config.WorkerName)" }
#   [PSCustomObject]@{ Algorithm = "CryptonightR";         Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cnr --rig_id $($Config.WorkerName)" } #XmRigGpu-v6.3.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cnv8 --rig_id $($Config.WorkerName)" }
#   [PSCustomObject]@{ Algorithm = "CryptonightDouble";    Fee = 0.025; MinMemGB = 4.0; Command = " --algo=cnv8_dbl --rig_id $($Config.WorkerName)" } #XmRigGpu-v6.3.0 is fastest
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cnv8_half -rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightTurtle";    Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cnv8_trtl --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cnv8_rwz --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CryptonightUpx";       Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cnv8_upx2 --rig_id $($Config.WorkerName)" }
    [PSCustomObject]@{ Algorithm = "CuckarooD29";          Fee = 0.025; MinMemGB = 2.1; Command = " --algo=cuckarood29_grin" } #2GB is not enough
#   [PSCustomObject]@{ Algorithm = "Cuckatoo31";           Fee = 0.025; MinMemGB = 2.0; Command = " --algo=cuckatoo31_grin" } #lolMiner-v1.0.6 is fastest
#   [PSCustomObject]@{ Algorithm = "Ethash";               Fee = 0.025; MinMemGB = 4.0; Command = " --algo=ethash" } #PhoenixMiner is fastest
    [PSCustomObject]@{ Algorithm = "KawPoW";               Fee = 0.02;  MinMemGB = 2.0; Command = " --algo=kawpow" } #Wildrig-v0.25.2 is fastest
    [PSCustomObject]@{ Algorithm = "Lyra2RE3";             Fee = 0.025; MinMemGB = 2.0; Command = " --algo=lyra2rev3" }
    [PSCustomObject]@{ Algorithm = "Lyra2z";               Fee = 0.03;  MinMemGB = 2.0; Command = " --algo=lyra2z" }
    [PSCustomObject]@{ Algorithm = "MTP";                  Fee = 0.025; MinMemGB = 4.0; Command = " --algo=mtp" }
    [PSCustomObject]@{ Algorithm = "Nimiq";                Fee = 0.025; MinMemGB = 4.0; Command = " --algo=nimiq" }
    [PSCustomObject]@{ Algorithm = "Phi2";                 Fee = 0.03;  MinMemGB = 2.0; Command = " --algo=phi2" }
    [PSCustomObject]@{ Algorithm = "X16r";                 Fee = 0.025; MinMemGB = 4.0; Command = " --algo=x16r" }
    [PSCustomObject]@{ Algorithm = "X16rv2";               Fee = 0.025; MinMemGB = 4.0; Command = " --algo=x16rv2" }
    [PSCustomObject]@{ Algorithm = "X16s";                 Fee = 0.025; MinMemGB = 2.0; Command = " --algo=x16s" }
#   [PSCustomObject]@{ Algorithm = "X16rt";                Fee = 0.025; MinMemGB = 2.0; Command = " --algo=x16rt " } #Profit very small
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "AMD" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | ForEach-Object {

                If ($_.Algorithm -eq "KawPoW" -and $Pools.($_.Algorithm).Name -match "MPH*") { Return }

                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) {

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo", "autotune") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    $WarmupTime = 45

                    If ($_.Algorithm -like "Cryptonight*") { 
                        $WarmupTime = 90
                        $_.Command += " --auto_tune=NONE"
                    }
                    ElseIf ($_.Algorithm -eq "Ethash") { 
                        $WarmupTime = 60
                        If ($Pools.($_.Algorithm).Name -match "NiceHash*|MPH*") { $_.Command += " --eth_stratum_mode=nicehash" }
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = "AMD"
                        Path       = $Path
                        Arguments  = ("$($_.Command) --url $($Pools.($_.Algorithm).Protocol)://$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass) --watchdog_disable --no_gpu_monitor --init_style=3 --pool_no_ensub --platform $($Miner_Devices.PlatformId | Sort-Object -Unique) --api_listen=127.0.0.1:$MinerAPIPort --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:d}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = $_.Algorithm
                        API        = "Xgminer"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        Fee        = $_.Fee
                        WarmupTime = $WarmupTime #seconds
                    }
                }
            }
        }
    }
}
