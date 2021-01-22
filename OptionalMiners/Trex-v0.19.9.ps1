using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\t-rex.exe"
$PathCUDA10 = ".\Bin\$($Name)\t-rex_CUDA10.exe"
$PathCUDA11 = ".\Bin\$($Name)\t-rex_CUDA11.exe"
$Uri = "https://github.com/Minerx117/miners/releases/download/T-Rex/t-rex-0.19.9-win.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$DAGmemReserve = [Math]::Pow(2, 23) * 17 # Number of epochs 

$AlgorithmDefinitions = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstralHash"; Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo astralhash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Balloon";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo balloon --intensity 23" }
    [PSCustomObject]@{ Algorithm = "BCD";        Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo bcd --intensity 24" }
    [PSCustomObject]@{ Algorithm = "Bitcore";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo bitcore --intensity 25" }
    [PSCustomObject]@{ Algorithm = "C11";        Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo c11 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "Dedal";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo dedal --intensity 23" }
    [PSCustomObject]@{ Algorithm = "EtcHash";    Fee = 0.01; MinMemGB = 4; MinerSet = 1; Arguments = " --algo etchash --intensity 24" } # GMiner-v2.42 is fastest
    [PSCustomObject]@{ Algorithm = "Ethash";     Fee = 0.01; MinMemGB = 4; MinerSet = 1; Arguments = " --algo ethash --intensity 24" } # GMiner-v2.42 is fastest
    [PSCustomObject]@{ Algorithm = "Geek";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo geek --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Hmq1725";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo hmq1725 --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Honeycomb";  Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo honeycomb --intensity 25" }
    [PSCustomObject]@{ Algorithm = "JeongHash";  Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo jeonghash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "KawPoW";     Fee = 0.01; MinMemGB = 3; MinerSet = 0; Arguments = " --algo kawpow --intensity 25" } # XmRig-v6.7.0 is almost as fast but has no fee
    [PSCustomObject]@{ Algorithm = "Lyra2Z";     Fee = 0.01; MinMemGB = 3; MinerSet = 0; Arguments = " --algo lyra2z --intensity 24.75" }
    [PSCustomObject]@{ Algorithm = "MegaBtx";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo megabtx --intensity 25" }
    [PSCustomObject]@{ Algorithm = "MegaMec";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo megamec --intensity 25" }
    [PSCustomObject]@{ Algorithm = "MTP";        Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo mtp --intensity 21" }
    [PSCustomObject]@{ Algorithm = "MTPTcr";     Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo mtp-tcr --intensity 21" }
    [PSCustomObject]@{ Algorithm = "Multi";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo multi --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Octopus";    Fee = 0.02; MinMemGB = 5; MinerSet = 0; Arguments = " --algo octopus --intensity 25" }
    [PSCustomObject]@{ Algorithm = "PadiHash";   Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo padihash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "PawelHash";  Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo pawelhash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Phi";        Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo phi --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Polytimos";  Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo polytimos --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Sha256t";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo sha256t --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Sha256q";    Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo sha256q --intensity 23" }
    [PSCustomObject]@{ Algorithm = "SkunkHash";  Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo skunk --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Sonoa";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo sonoa --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Tensority";  Fee = 0.03; MinMemGB = 2; MinerSet = 0; Arguments = " --algo tensority --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Timetravel"; Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo timetravel --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Tribus";     Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo tribus --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Veil";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo progpow-veil --intensity 24" }
    [PSCustomObject]@{ Algorithm = "VeriBlock";  Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo progpow-veriblock" }
    [PSCustomObject]@{ Algorithm = "X11r";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x11r --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16r";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x16r --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16rt";      Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x16rt --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16rv2";     Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x16rv2 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16s";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x16s --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X17";        Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x17 --intensity 23" }
    [PSCustomObject]@{ Algorithm = "X22i";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x22i --intensity 23" }
    [PSCustomObject]@{ Algorithm = "X21s";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x21s --intensity 23" }
    [PSCustomObject]@{ Algorithm = "X25x";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x25x --intensity 21" }
    [PSCustomObject]@{ Algorithm = "X33";        Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo x33 --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Zano";       Fee = 0.01; MinMemGB = 2; MinerSet = 0; Arguments = " --algo progpowz --intensity 25" }
)

If ($AlgorithmDefinitions = $AlgorithmDefinitions | Where-Object MinerSet -LE $Config.MinerSet | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            #according to user reports Octopus on 16 and 20 series cards is faster with CUDA 10.0 than CUDA 11.1
            If ($_Algorithm -eq "Octopus" -and ($SelectedDevices.OpenCL.ComputeCapability | Measure-Object -Minimum).Minimum -lt 8.6) { 
                $Path = $PathCUDA10
            }
            Else { 
                #RTX 3x series
                $Path = $PathCUDA11
            }

            $AlgorithmDefinitions | ForEach-Object {

                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -in @("EtcHash", "Ethash", "KawPoW")) { 
                    $MinMemGB = (3GB, ($Pools.($_.Algorithm[0]).DAGSize + $DAGmemReserve) | Measure-Object -Maximum).Maximum / 1GB # Minimum 3GB required
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    # Get arguments for active miner devices
                    # $_.Arguments= Get-ArgumentsPerDevice -Command $_.Arguments-ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($_.Algorithm -eq "Ethash" -and $Pools.($_.Algorithm).Name -match "^NiceHash$|^MPH(|Coins)$") { 
                        $Stratum = "stratum2"
                    }
                    Else {
                        $Stratum = "stratum"
                    }
                    If ($Pools.($_.Algorithm).SSL -eq $true) { $Stratum += "+ssl://" } Else { $Stratum += "+tcp://" }

                    If ($_.Algorithm -eq "ProgPoW") { 
                        If ($Pools.($_.Algorithm).Currency -in @("SERO", "ZANO")) { 
                            $Coin = " --coin $($Pools.($_.Algorithm).Currency)"
                        }
                        Else { 
                            $Coin = ""
                            Return
                        }
                    }

                    #(ethash, kawpow, progpow) Worker name is not being passed for some mining pools
                    # From now on the username (-u) for these algorithms is no longer parsed as <wallet_address>.<worker_name>
                    If ($_.Algorithm -in @("Ethash", "KawPow", "ProgPoW") -and ($Pools.($_.Algorithm).User -split "\.").Count -eq 2) { 
                        $User = " --user $($Pools.($_.Algorithm).User) --worker $($Pools.($_.Algorithm).User -split "\." | Select-Object -Index 1)"
                    }
                    Else { 
                        $User = " --user $($Pools.($_.Algorithm).User)"
                    }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$($_.Arguments) --url $Stratum$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port)$User --pass $($Pools.($_.Algorithm).Pass) --no-strict-ssl$(If ($Variables.IsLocalAdmin -eq $true) { " --mt 3" })$Coin --no-watchdog --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-bind-telnet 0 --api-read-only --gpu-report-interval 5 --quiet --retry-pause 1 --timeout 50000 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "Trex"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee # Dev fee
                        MinerUri        = "http://localhost:$($MinerAPIPort)/trex"
                        PowerUsageInAPI = $true
                    }
                }
            }
        }
    }
}
