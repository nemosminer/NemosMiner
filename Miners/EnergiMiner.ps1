if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-EnergiMiner221\energiminer.exe"
$Uri = "https://nemosminer.com/data/optional/energiminer-2.2.1-Windows.7z"

$Commands = [PSCustomObject]@{
    #"nrghash" = "" #Nrghash (fastest) enabled on ZergPool (runs in wrapper as no current working API, investigating no hash pool side)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    $Algo = Get-Algorithm($_)
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--response-timeout 10 --cuda-parallel-hash 8 --cuda-block-size 256 --cuda-devices $($Config.SelGPUDSTM) -U stratum://$($Pools.($Algo).User):$($Pools.($Algo).Pass.ToString().replace(',','%2C'))@nrghash.mine.zergpool.com:$($Pools.($Algo).Port)"
        HashRates = [PSCustomObject]@{($Algo) = $Stats."$($Name)_$($Algo)_HashRate".Day}
        API       = "wrapper"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $true
        URI       = $Uri
        User      = $Pools.($Algo).User
        Host      = $Pools.($Algo).Host
        Coin      = $Pools.($Algo).Coin
    }
}
