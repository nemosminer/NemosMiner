using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\EthDcrMiner64.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v15.0/Claymoresethereumv15.0.7z"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@( 
    #Ethash -strap 1 -strap 2 -strap 3 -strap 4 -strap 5 -strap 6
#   [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.01)   ; MinMemGB = 4; Type = "AMD";    Command = " -strap 1 -platform 1 -y 1 -rxboost 1" } #Bminer-v16.2.12 is faster
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -strap 1 -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Decred") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -strap 1 -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Keccak") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -strap 1 -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Lbry")   ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -strap 1 -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Pascal") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -strap 1 -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Sia")    ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -strap 1 -platform 1 -y 1 -rxboost 1" }

#   [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.01);    MinMemGB = 4; Type = "NVIDIA"; Command = " -strap 1 -platform 2" } #ClaymoreDual_v15.0 is faster
#   [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -strap 1 -platform 2" } #PhoenixMiner-v5.1c is fastest
    [PSCustomObject]@{ Algorithm = @("Ethash", "Decred") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -strap 1 -platform 2" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Keccak") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -strap 1 -platform 2" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Lbry")   ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -strap 1 -platform 2" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Pascal") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -strap 1 -platform 2" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Sia")    ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -strap 1 -platform 2" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm[0]).Host -and (-not $_.Algorithm[1] -or $Pools.($_.Algorithm[1]).Host) }) { 

    $Intensities2 = [PSCustomObject]@{ 
        "Blake2s" = @(40, 60, 80)
        "Decred"  = @(20, 40, 70)
        "Keccak"  = @(20, 30, 40)
        "Lbry"    = @(60, 75, 90)
        "Pascal"  = @(20, 40, 60)
        "Sia"     = @(20, 40, 60, 80)
    }

    $Dcoin = @{
        "Blake2s" = " -dcoin blake2s"
        "Decred"  = " -dcoin dcr"
        "Keccak"  = " -dcoin keccak"
        "Lbry"    = " -dcoin lbc"
        "Pascal"  = " -dcoin pasc"
        "Sia"     = " -dcoin sc"
    }

    # Build command sets for intensities
    $Commands = $Commands | ForEach-Object { 
        $Command = $_ 
        If ($_.Algorithm[1]) { 
            $Intensities2.($_.Algorithm[1]) | Select-Object | ForEach-Object { 
                $Command | Add-Member Intensity2 ([Uint16]$_) -Force
                $Command | ConvertTo-Json | ConvertFrom-Json
            }
        }
        Else { 
            $Command
        }
    }

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | Sort-Object $DeviceEnumerator | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -eq $_.Type | ForEach-Object { $Algo = ($_.Algorithm[0]); $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object { 

                If ($Algo -eq "Ethash" -and $Pools.$Algo.Name -like "ZergPool*") { Return }
                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($Algo -eq "Ethash" -and $Pools.$Algo.Name -match "NiceHash*|MPH*") { $_.Command += " -esm 3" }

                    If ($Algo2 = $_.Algorithm[1]) { 

                        $_.Command += " -dpool $($Pools.$Algo2.Host):$($Pools.$Algo2.Port) -dwal $($Pools.$Algo2.User) -dpsw $($Pools.$Algo2.Pass)$($Dcoin.$Algo2)"
                        If ($_.Intensity2 -ge 0) { $_.Command += " -dcri $($_.Intensity2)" }

                        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($Algo2) + @($_.Intensity2) | Select-Object) -join '-'
                    }
                    Else {
                        $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'
                    }

                    #Optionally disable dev fee mining
                    If ($Config.DisableMinerFees) { 
                        $_.Command += " -nofee 1"
                        $_.Fee = @(0) * ($_.Algorithm | Select-Object).count
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("-epool $($Pools.$Algo.Host):$($Pools.$Algo.Port) -ewal $($Pools.$Algo.User) -epsw $($Pools.$Algo.Pass)$($_.Command) -dbg -1 -wd 0 -allpools 1 -allcoins 1 -mport -$MinerAPIPort -di $(($Miner_Devices | ForEach-Object { '{0:x}' -f ($_.$DeviceEnumerator) }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($Algo, $Algo2) | Select-Object
                        API        = "EthMiner"
                        Port       = $MinerAPIPort
                        URI        = $Uri
                        Fee        = $_.Fee # Dev fee
                        MinerUri   = "http://localhost:$($MinerAPIPort)"
                    }
                }
            }
        }
    }
}
