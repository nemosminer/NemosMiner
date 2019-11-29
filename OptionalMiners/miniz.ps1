if (!(IsLoaded(".\Includes\include.ps1"))) { . .\Includes\include.ps1; RegisterLoaded(".\Includes\include.ps1") }

$Path = ".\Bin\NVIDIA-miniZ15s\miniZ.exe"
$Uri = "https://github.com/Minerx117/miner-binaries/releases/download/v1.5s/miniZ_v1.5s_cuda10_win-x64.zip"
$Commands = [PSCustomObject]@{
    "beamv2"       = " --par=beam --pers auto " #Beamv2
    "equihash-btg" = " --algo 144,5 --pers BgoldPoW " # Equihash-btg MPH (fastest)
    "equihash-zcl" = " --par=192,7 --pers ZcashPoW" # Equihash-ZCL MPH
    "equihash125"  = " --par=125,4 --oc1 " #Equihash125
    "equihash144"  = " --algo 144,5 --pers auto --oc1 " #Equihash144 (fastest)
    "equihash192"  = " --algo 192,7 --pers auto --oc1 " #Equihash192 (fastest)
    "zhash"        = " --algo 144,5 --pers auto " #Zhash (fastest)
    # "beam"         = " --algo 150,5 --pers auto" #Beam
    # "equihash96"   = " --algo 96,5  --pers auto --oc1 " #Equihash96 (ewbf faster)
}

$Name = "$(Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName)"

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object { $Algo = Get-Algorithm $_; $_ } | Where-Object { $Pools.$Algo.Host } | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cleanjobs --jobtimeout=900 --retries=99 --retrydelay=1 --stat-int 60 --nonvml --latency --nocolor --extra --tempunits C -cd $($Config.SelGPUDSTM) --telemetry $($Variables.NVIDIAMinerAPITCPPort) --url $($Pools.$Algo.User)@$($Pools.$Algo.Host):$($Pools.$Algo.Port) --pass $($Pools.$Algo.Pass)$($Commands.$_)" #--oc1 --oc2 --f11=0
        HashRates = [PSCustomObject]@{ $Algo = $Stats."$($Name)_$($Algo)_HashRate".Day * .98 } # substract 2% devfee
        API       = "miniZ"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri    
        User      = $Pools.$Algo.User
        Host      = $Pools.$Algo.Host
        Coin      = $Pools.$Algo.Coin
    }
}
