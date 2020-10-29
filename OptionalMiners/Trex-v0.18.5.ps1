using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\t-rex.exe"
$Uri = "https://github.com/trexminer/T-Rex/releases/download/0.18.5/t-rex-0.18.5-win-cuda11.1.zip"
$DeviceEnumerator = "Type_Vendor_Index"
$EthashMemReserve = [Math]::Pow(2, 23) * 17 #Number of epochs 

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "AstralHash"; MinMemGB = 2; Fee = 0.01; Command = " --algo astralhash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Balloon";    MinMemGB = 2; Fee = 0.01; Command = " --algo balloon --intensity 23" }
    [PSCustomObject]@{ Algorithm = "BCD";        MinMemGB = 2; Fee = 0.01; Command = " --algo bcd --intensity 24" }
    [PSCustomObject]@{ Algorithm = "Bitcore";    MinMemGB = 2; Fee = 0.01; Command = " --algo bitcore --intensity 25" }
    [PSCustomObject]@{ Algorithm = "C11";        MinMemGB = 2; Fee = 0.01; Command = " --algo c11 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "Dedal";      MinMemGB = 2; Fee = 0.01; Command = " --algo dedal --intensity 23" }
#   [PSCustomObject]@{ Algorithm = "Ethash";     MinMemGB = 4; Fee = 0.01; Command = " --algo ethash" } #PhoenixMiner-v5.1c is fastest
    [PSCustomObject]@{ Algorithm = "Geek";       MinMemGB = 2; Fee = 0.01; Command = " --algo geek --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Honeycomb";  MinMemGB = 2; Fee = 0.01; Command = " --algo honeycomb --intensity 26" }
    [PSCustomObject]@{ Algorithm = "JeongHash";  MinMemGB = 2; Fee = 0.01; Command = " --algo jeonghash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "KawPoW";     MinMemGB = 3; Fee = 0.01; Command = " --algo kawpow" } #NBMiner-v32.1 is fastest but has optional 1% fee
    [PSCustomObject]@{ Algorithm = "MegaBtx";    MinMemGB = 2; Fee = 0.01; Command = " --algo megabtx" }
    [PSCustomObject]@{ Algorithm = "MTP";        MinMemGB = 2; Fee = 0.01; Command = " --algo mtp --intensity 21" }
    [PSCustomObject]@{ Algorithm = "PadiHash";   MinMemGB = 2; Fee = 0.01; Command = " --algo padihash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "PawelHash";  MinMemGB = 2; Fee = 0.01; Command = " --algo pawelhash --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Polytimos";  MinMemGB = 2; Fee = 0.01; Command = " --algo polytimos --intensity 25" }
    [PSCustomObject]@{ Algorithm = "ProgPoW";    MinMemGB = 2; Fee = 0.01; Command = " --algo progpow --intensity 21 --mt 2" } #Sero, Zano
    [PSCustomObject]@{ Algorithm = "Sha256t";    MinMemGB = 2; Fee = 0.01; Command = " --algo sha256t --intensity 26" }
    [PSCustomObject]@{ Algorithm = "Sha256q";    MinMemGB = 2; Fee = 0.01; Command = " --algo sha256q --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Sonoa";      MinMemGB = 2; Fee = 0.01; Command = " --algo sonoa --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Tensority";  MinMemGB = 2; Fee = 0.03; Command = " --algo tensority" }
    [PSCustomObject]@{ Algorithm = "Timetravel"; MinMemGB = 2; Fee = 0.01; Command = " --algo timetravel --intensity 25" }
    [PSCustomObject]@{ Algorithm = "Tribus";     MinMemGB = 2; Fee = 0.01; Command = " --algo tribus --intensity 23" }
    [PSCustomObject]@{ Algorithm = "Veil";       MinMemGB = 2; Fee = 0.01; Command = " --algo x16rt --intensity 24" }
    [PSCustomObject]@{ Algorithm = "VeriBlock";  MinMemGB = 2; Fee = 0.01; Command = " --algo progpow-veriblock" }
    [PSCustomObject]@{ Algorithm = "X17";        MinMemGB = 2; Fee = 0.01; Command = " --algo x17 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16s";       MinMemGB = 2; Fee = 0.01; Command = " --algo x16s --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16r";       MinMemGB = 2; Fee = 0.01; Command = " --algo x16r --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16rv2";     MinMemGB = 2; Fee = 0.01; Command = " --algo x16rv2 --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X16rt";      MinMemGB = 2; Fee = 0.01; Command = " --algo x16rt --intensity 24" }
    [PSCustomObject]@{ Algorithm = "X21s";       MinMemGB = 2; Fee = 0.01; Command = " --algo x21s --intensity 23" }
    [PSCustomObject]@{ Algorithm = "X22i";       MinMemGB = 2; Fee = 0.01; Command = " --algo x22i --intensity 23" }
    [PSCustomObject]@{ Algorithm = "X25x";       MinMemGB = 2; Fee = 0.01; Command = " --algo x25x --intensity 21" }
    [PSCustomObject]@{ Algorithm = "X33";        MinMemGB = 2; Fee = 0.01; Command = " --algo x33" }
    [PSCustomObject]@{ Algorithm = "Zano";       MinMemGB = 2; Fee = 0.01; Command = " --algo progpowz" }
)

If ($Commands = $Commands | Where-Object { $Pools.($_.Algorithm).Host }) { 

    $Devices | Where-Object Type -EQ "NVIDIA" | Select-Object Model -Unique | ForEach-Object { 

        If ($SelectedDevices = @($Devices | Where-Object Model -EQ $_.Model)) { 

            $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

            $Commands | ForEach-Object {

                $MinMemGB = $_.MinMemGB
                If ($_.Algorithm -eq "Ethash") { 
                    $MinMemGB = ($Pools.($_.Algorithm).EthashDAGSize + $EthashMemReserve) / 1GB
                }

                If ($Miner_Devices = @($SelectedDevices | Where-Object { ($_.OpenCL.GlobalMemSize / 1GB) -ge $MinMemGB })) { 

                    $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

                    #Get commands for active miner devices
                    #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

                    If ($Pools.($_.Algorithm).Name -match "^NiceHash*|^MPH*") { 
                        $Stratum = "stratum2"
                    }
                    Else {
                        $Stratum = "stratum"
                    }
                    If ($Pools.($_.Algorithm).SSL -eq $true) { $Stratum += "+ssl://" } Else { $Stratum += "+tcp://" }

                    If ($_.Algorithm -eq "ProgPoW") { 
                        If ($Pools.($_.Algorithm).Currency -in @("SERO", "ZANO")) { 
                            $Coin = " -coin $($Pools.($_.Algorithm).Currency)"
                        }
                        Else { 
                            $Coin = ""
                            Return
                        }
                    }

                    [PSCustomObject]@{ 
                        Name            = $Miner_Name
                        DeviceName      = $Miner_Devices.Name
                        Type            = "NVIDIA"
                        Path            = $Path
                        Arguments       = ("$($_.Command) --url $Stratum$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user $($Pools.($_.Algorithm).User) --pass $($Pools.($_.Algorithm).Pass)$(If ($Variables.IsLocalAdmin -eq $true) { " --mt 3" })$Coin --no-watchdog --gpu-report-interval 1 --api-bind-http 127.0.0.1:$($MinerAPIPort) --api-bind-telnet 0 --quiet --retry-pause 1 --timeout 50000 --cpu-priority 4 --devices $(($Miner_Devices | Sort-Object $DeviceEnumerator | ForEach-Object { '{0:x}' -f $_.$DeviceEnumerator }) -join ',')" -replace "\s+", " ").trim()
                        Algorithm       = $_.Algorithm
                        API             = "Trex"
                        Port            = $MinerAPIPort
                        URI             = $Uri
                        Fee             = $_.Fee #Dev fee
                        MinerUri        = "http://localhost:$($MinerAPIPort)/trex"
                        PowerUsageInAPI = $true
                    }
                }
            }
        }
    }
}
