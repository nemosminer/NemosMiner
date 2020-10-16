using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\EthDcrMiner64.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v15.0/Claymoresethereumv15.0.7z"
$DeviceEnumerator = "Type_Vendor_Slot"

$Commands = [PSCustomObject[]]@( 
    [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.01)   ; MinMemGB = 4; Type = "AMD";    Command = " -platform 1 -y 1 -rxboost 1" } #Bminer-v16.3.1 & PhoenixMiner-v5.1c are faster
    [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -dcoin blake2s -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Decred") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -dcoin dcr -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Keccak") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -dcoin keccak -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Lbry")   ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -dcoin lbc -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Pascal") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -dcoin pasc -platform 1 -y 1 -rxboost 1" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Sia")    ; Fee = @(0.01, 0); MinMemGB = 4; Type = "AMD";    Command = " -dcoin sc -platform 1 -y 1 -rxboost 1" }

#   [PSCustomObject]@{ Algorithm = @("Ethash");            Fee = @(0.01);    MinMemGB = 4; Type = "NVIDIA"; Command = " -platform 2" } #PhoenixMiner-v5.1c is fastest
#   [PSCustomObject]@{ Algorithm = @("Ethash", "Blake2s"); Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -dcoin blake2s -platform 2" } #PhoenixMiner-v5.1c is fastest
    [PSCustomObject]@{ Algorithm = @("Ethash", "Decred") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -dcoin dcr -platform 2" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Keccak") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -dcoin keccak -platform 2" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Lbry")   ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -dcoin lbc -platform 2" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Pascal") ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -dcoin pasc -platform 2" }
    [PSCustomObject]@{ Algorithm = @("Ethash", "Sia")    ; Fee = @(0.01, 0); MinMemGB = 4; Type = "NVIDIA"; Command = " -dcoin sc -platform 2" }
)

If ($Commands = $Commands | Where-Object { ($Pools.($_.Algorithm[0]).Host -and -not $_.Algorithm[1]) -or ($Pools.($_.Algorithm[0]).Host -and $PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host) }) { 

    $Intensities2 = [PSCustomObject]@{ 
        "Blake2s" = @(10, 30, 50, 70)
        "Decred"  = @(10, 20, 30, 40)
        "Keccak"  = @(1, 3, 6, 9)
        "Lbry"    = @(10, 20, 30, 40)
        "Pascal"  = @(20, 40, 60)
        "Sia"     = @(20, 40, 60, 80)
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

    $Devices | Where-Object Type -in @("AMD", "NVIDIA") | Select-Object Type, Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Type -EQ $_.Type | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | Where-Object Type -EQ $_.Type | ForEach-Object { 

                If ($_.Algorithm[0] -eq "Ethash" -and $Pools.($_.Algorithm[0]).Name -match "^MPH*") { Return } #temp fix

                $Command = $_.Command 
                $MinMemGB = $_.MinMemGB

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) + @($_.Algorithm[1]) + @($_.Intensity2) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$Command = Get-CommandPerDevice -Command $Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($Pools.($_.Algorithm[0]).SSL) {
                        $Command =+ " -checkcert 0"
                        If ($_.Algorithm[0] -eq "Ethash" -and $Pools.($_.Algorithm[0]).Name -match "^NiceHash*|^MPH*") { 
                            $Command =+ " -esm 3"
                            $Protocol = "stratum+ssl://"
                        }
                        Else { 
                            $Protocol = "ssl://"
                        }
                    }
                    Else { 
                        If ($_.Algorithm[0] -eq "Ethash" -and $Pools.($_.Algorithm[0]).Name -match "^NiceHash*|^MPH*") { 
                            $Command =+ " -esm 3"
                            $Protocol = "stratum+tcp://"
                        }
                        Else { 
                            $Protocol = ""
                        }
                    }

                    If ($_.Algorithm[1]) { 

                        If (($Miner_Devices.Model | Sort-Object -unique) -join '' -match '^RadeonRX(5300|5500|5600|5700).*\d.*GB$|^GTX1660.*GB$') { Return } #No dual mining for Navi or GTX1660 cards

                        $Command += " -dpool $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Host):$($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Port) -dwal $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).User) -dpsw $($PoolsSecondaryAlgorithm.($_.Algorithm[1]).Pass)"
                        If ($_.Intensity2 -ge 0) { $Command += " -dcri $($_.Intensity2)" }
                    }

                    #Optionally disable dev fee mining
                    If ($Config.DisableMinerFees) { 
                        $Command += " -nofee 1"
                        $_.Fee = @(0) * ($_.Algorithm | Select-Object).count
                    }

                    [PSCustomObject]@{ 
                        Name       = $Miner_Name
                        DeviceName = $Miner_Devices.Name
                        Type       = $_.Type
                        Path       = $Path
                        Arguments  = ("-epool $Protocol$($Pools.($_.Algorithm[0]).Host):$($Pools.($_.Algorithm[0]).Port) -ewal $($Pools.($_.Algorithm[0]).User) -epsw $($Pools.($_.Algorithm[0]).Pass)$Command -dbg -1 -wd 0 -allpools 1 -allcoins 1 -mport -$MinerAPIPort -di $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm  = ($_.Algorithm[0], $_.Algorithm[1]) | Select-Object
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
