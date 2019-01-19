if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-zjazz12\zjazz_cuda.exe"
$Uri = "https://github.com/zjazz/zjazz_cuda_miner/releases/download/1.2/zjazz_cuda_win64_1.2.zip"

$Commands = [PSCustomObject]@{
    #"bitcash" = " -a bitcash" #Bitcash (testing)
    #"cuckoo"  = " -a bitcash " #Cuckoo (testing nlpool)
    #"x22i"    = " -a x22i" #SUQA (testing)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-d $($Config.SelGPUDSTM) --api-bind $($Variables.NVIDIAMinerAPITCPPort) -o stratum+tcp://$($Pools.(Get-Algorithm($_)).Host):$($Pools.(Get-Algorithm($_)).Port) -u $($Pools.(Get-Algorithm($_)).User) -p $($Pools.(Get-Algorithm($_)).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm($_)) = $Stats."$($Name)_$(Get-Algorithm($_))_HashRate".98} # substract 2% devfee
        API       = "ccminer"
        Port      = $Variables.NVIDIAMinerAPITCPPort #4068
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
    }
}
