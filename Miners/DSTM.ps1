. .\Include.ps1

$Path = ".\Bin\NVIDIA-DSTM\zm.exe"
$Uri = "https://github.com/nemosminer/DSTM-equihash-miner/releases/download/DSTM-0.5.8/zm_0.5.8_win.zip"

$Commands = [PSCustomObject]@{
    "equihash" = " -d $SelGPUDSTM" #Equihash
}
$Port = 2222
$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select -ExpandProperty Name | ForEach {
    [PSCustomObject]@{
        Type = "NVIDIA"
        Path = $Path
        Arguments = "--telemetry=127.0.0.1:$Port --server $($Pools.(Get-Algorithm($_)).Host) --port $($Pools.(Get-Algorithm($_)).Port) --user $($Pools.(Get-Algorithm($_)).User) --pass $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Live}
        API = "DSTM"
        Port = $Port
        Wrap = $false
        URI = $Uri    
    }
}
