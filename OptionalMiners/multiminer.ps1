if (!(IsLoaded(".\Include.ps1"))) {. .\Include.ps1; RegisterLoaded(".\Include.ps1")}

$Path = ".\Bin\NVIDIA-multiminer1001201\cpuminer-aes-sse42.exe"
$Uri = "https://github.com/bogdanadnan/multiminer/releases/download/v1.0.0/multiminer_v1.0.0_12.01.2019.zip"

$Commands = [PSCustomObject]@{
    #"argon2d-dyn" = " --use-gpu CUDA --gpu-batchsize=1024 -t 2 -a argon2d250" #argon2d-dyn (testing)
}

$Name = (Get-Item $script:MyInvocation.MyCommand.Path).BaseName

$Commands | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | ForEach-Object {
    [PSCustomObject]@{
        Type      = "NVIDIA"
        Path      = $Path
        Arguments = "-o stratum+tcp://$($Pools.(Get-Algorithm $_).Host):$($Pools.(Get-Algorithm $_).Port) -u $($Pools.(Get-Algorithm $_).User) -p $($Pools.(Get-Algorithm $_).Pass)$($Commands.$_)"
        HashRates = [PSCustomObject]@{(Get-Algorithm $_) = $Stats."$($Name)_$(Get-Algorithm $_)_HashRate".Day}
        API       = "Ccminer"
        Port      = $Variables.CPUMinerAPITCPPort
        Wrap      = $false
        URI       = $Uri
        User      = $Pools.(Get-Algorithm($_)).User
        Host      = $Pools.(Get-Algorithm $_).Host
        Coin      = $Pools.(Get-Algorithm $_).Coin
    }
}
