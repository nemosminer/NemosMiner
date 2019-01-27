if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-EnergiMiner221\energiminer.exe"
$Uri = "https://nemosminer.com/data/optional/energiminer-2.2.1-Windows.7z"

$Commands = [PSCustomObject]@{
    #"nrghash" = "" #Nrghash (testing running/get-hasrate needs work)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "--cuda-devices $($Config.SelGPUDSTM) -U stratum://$($Pools.(Get-Algorithm($_)).User).$($Pools.(Get-Algorithm($_)).Pass)@nrghash.mine.zergpool.com:$($Pools.(Get-Algorithm($_)).Port)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".Day}
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
