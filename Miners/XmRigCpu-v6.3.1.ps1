using module ..\Includes\Include.psm1

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"
$Path = ".\Bin\$($Name)\xmrig.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v6.3.1/XMRigv631.7z"
$DeviceEnumerator = "Type_Vendor_Index"

$Commands = [PSCustomObject[]]@(
    [PSCustomObject]@{ Algorithm = "Argon2Chukwa";         MinMemGB = 0.5;  Command = " --algo argon2/chukwa" } #Argon2id (Chukwa)
    [PSCustomObject]@{ Algorithm = "Argon2WRKZ";           MinMemGB = 0.25; Command = " --algo argon2/wrkz" } #Argon2id (WRKZ)
#   [PSCustomObject]@{ Algorithm = "AstroBWT";             MinMemGB = 0.02; Command = " --algo astrobwt" } #AstroBWT (Dero) #No pool
    [PSCustomObject]@{ Algorithm = "Cryptonight";          MinMemGB = 2;    Command = " --algo cn/0" } #CryptoNight (original)
    [PSCustomObject]@{ Algorithm = "CryptonightCcx";       MinMemGB = 2;    Command = " --algo cn/ccx" } #Conceal (CCX)
    [PSCustomObject]@{ Algorithm = "CryptonightDouble";    MinMemGB = 2;    Command = " --algo cn/double" } #CryptoNight variant 2 with double iterations
    [PSCustomObject]@{ Algorithm = "CryptonightFast";      MinMemGB = 2;    Command = " --algo cn/fast" } ##CryptoNight variant 1 with half iterations
    [PSCustomObject]@{ Algorithm = "CryptonightLite";      MinMemGB = 1;    Command = " --algo cn-lite/0" } #CryptoNight-Lite variant 0
    [PSCustomObject]@{ Algorithm = "CryptonightLiteV1";    MinMemGB = 1;    Command = " --algo cn-lite/1" } #CryptoNight-Lite variant 1
    [PSCustomObject]@{ Algorithm = "CryptonightHalf";      MinMemGB = 2;    Command = " --algo cn/half" } #CryptoNight variant 2 with half iterations
    [PSCustomObject]@{ Algorithm = "CryptonightHeavy";     MinMemGB = 4;    Command = " --algo cn-heavy/0" } #CryptoNight-Heavy
    [PSCustomObject]@{ Algorithm = "CryptonightHeavyTube"; MinMemGB = 4;    Command = " --algo cn-heavy/tube" } #CryptoNight-Heavy (modified)
#   [PSCustomObject]@{ Algorithm = "CryptonightPico";      MinMemGB = 0.25; Command = " --algo cn-pico" } #CryptoNight-Pico #No pool
#   [PSCustomObject]@{ Algorithm = "CryptonightPicoTlo";   MinMemGB = 0.25; Command = " --algo cn-pico/tlo" } #CryptoNight-Pico (Talleo) #No pool
    [PSCustomObject]@{ Algorithm = "CryptonightR";         MinMemGB = 2;    Command = " --algo cn/r" } #CryptoNightR (Monero's variant 4)
    [PSCustomObject]@{ Algorithm = "CryptonightRto";       MinMemGB = 2;    Command = " --algo cn/rto" } #CryptoNight variant 1 (modified)
    [PSCustomObject]@{ Algorithm = "CryptonightRwz";       MinMemGB = 2;    Command = " --algo cn/rwz" } #CryptoNight variant 2 with 3/4 iterations and reversed shuffle operation
    [PSCustomObject]@{ Algorithm = "CryptonightV1";        MinMemGB = 2;    Command = " --algo cn/1" } #CryptoNight variant 1
    [PSCustomObject]@{ Algorithm = "CryptonightV2";        MinMemGB = 2;    Command = " --algo cn/2" } #CryptoNight variant 2
    [PSCustomObject]@{ Algorithm = "CryptonightXao";       MinMemGB = 2;    Command = " --algo cn/xao" } #CryptoNight variant 0 (modified)
    [PSCustomObject]@{ Algorithm = "CryptonightXhvTube";   MinMemGB = 4;    Command = " --algo cn-heavy/xhv" } #CryptoNight-Heavy (modified)
    [PSCustomObject]@{ Algorithm = "CryptonightZls";       MinMemGB = 2;    Command = " --algo cn/zls" } #CryptoNight variant 2 with 3/4 iterations
    [PSCustomObject]@{ Algorithm = "Randomx";              MinMemGB = 2;    Command = " --algo rx/0" } #RandomX (Monero)
    [PSCustomObject]@{ Algorithm = "RandomxArq";           MinMemGB = 0.25; Command = " --algo rx/arq" } #RandomARQ (RandomX variant for ArQmA)
    [PSCustomObject]@{ Algorithm = "RandomxKeva";          MinMemGB = 1;    Command = " --algo rx/kev" } #RandomKEVA (RandomX variant for Keva)
    [PSCustomObject]@{ Algorithm = "RandomxLoki";          MinMemGB = 2;    Command = " --algo rx/loki" } #RandomXL (RandomX variant for Loki)
    [PSCustomObject]@{ Algorithm = "RandomxSfx";           MinMemGB = 2;    Command = " --algo rx/sfx" } #RandomSFX (RandomX variant for Safex)
    [PSCustomObject]@{ Algorithm = "RandomxWow";           MinMemGB = 1;    Command = " --algo rx/wow" } #RandomWOW (RandomX variant for Wownero)
)

If ($SelectedDevices = @($Devices | Where-Object Type -EQ "CPU")) { 
    $MinerAPIPort = [UInt16]($Config.APIPort + ($SelectedDevices | Sort-Object Id | Select-Object -First 1 -ExpandProperty Id) + 1)

    $Commands | Where-Object { $Pools.($_.Algorithm).Host } | ForEach-Object {
        $MinMemGB = $_.MinMemGB
        If ($Miner_Devices = @($SelectedDevices | Where-Object { (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB -ge $MinMemGB })) {  
            $Miner_Name = (@($Name) + @($Miner_Devices.Model | Sort-Object -Unique | ForEach-Object { $Model = $_; "$(@($Miner_Devices | Where-Object Model -eq $Model).Count)x$Model" }) | Select-Object) -join '-'

            #Get commands for active miner devices
            #$_.Command = Get-CommandPerDevice -Command $_.Command -ExcludeParameters @("algo") -DeviceIDs $Miner_Devices.$DeviceEnumerator

            [PSCustomObject]@{ 
                Name       = $Miner_Name
                DeviceName = $Miner_Devices.Name
                Type       = "CPU"
                Path       = $Path
                Arguments  = ("$($_.Command)$(If ($Pools.($_.Algorithm).Name -eq "NiceHash") { " --nicehash" } ) $(If ($Pools.($_.Algorithm).SSL) { " --tls" } ) --url=$($Pools.($_.Algorithm).Host):$($Pools.($_.Algorithm).Port) --user=$($Pools.($_.Algorithm).User) --pass=$($Pools.($_.Algorithm).Pass) --threads=$($Miner_Devices.CIM.NumberOfLogicalProcessors -1) --keepalive --http-enabled --http-host=127.0.0.1  --http-port=$($MinerAPIPort) --api-worker-id=$($Config.WorkerName) --api-id=$($Miner_Name) --donate-level 0 --retries=90 --retry-pause=1" -replace "\s+", " ").trim()
                Algorithm  = $_.Algorithm
                API        = "XMRig"
                Port       = $MinerAPIPort
                URI        = $Uri
                WarmupTime = 60 #seconds
                MinerUri   = "http://workers.xmrig.info/worker?url=$([System.Web.HTTPUtility]::UrlEncode("http://localhost:$($MinerAPIPort)"))"
            }
        }
    }
}
