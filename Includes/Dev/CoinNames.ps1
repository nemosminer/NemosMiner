using module c:\Users\Stephan\Desktop\NemosMiner\Includes\Include.psm1

Set-Location c:\Users\Stephan\Desktop\NemosMiner\

$DB = c:\Users\Stephan\Desktop\NemosMiner\Includes\Dev\CoinsDB.json | ConvertFrom-Json

$AlgorithmCurrencies = [Ordered]@{ }
$CoinList = [Ordered]@{ }
$CoinDB = [PSCustomObject]@{ }
$CoinDB2 = @{ }
($Db | Get-Member -MemberType NoteProperty).Name | Sort-Object -Unique | ForEach-Object { 
    $Algorithm = Get-Algorithm $DB.$_.Algo
    $Currency = $_ -replace '-.+$'
    $CoinName = $DB.$_.Name -replace "cash$", "Cash" -replace "gold$", "Gold" -replace "coin$", "Coin" -replace "token$", "Token"
    $CoinList.$Currency = $CoinName
$Data = [PSCustomObject]@{ 
        "Algorithm" = $Algorithm
        "CoinName" = $CoinName
        "Currency" = $Currency
    }
    $CoinDB | Add-Member $_ $Data
}

ForEach ($Algorithm in (($CoinDB | Get-Member -MemberType NoteProperty).Name | ForEach-Object { $CoinDB.$_.Algorithms } | Sort-Object -Unique)) { 
    
    $Currencies = ($CoinDB | Get-Member -MemberType NoteProperty).Name | Where-Object { $CoinDB.$_.Algorithms -match $Algorithm }
    If ($Currencies.Count -eq 1) { 
        $AlgorithmCurrencies.$Algorithm = $Currencies
    }
}

$CoinList | ConvertTo-Json > c:\Users\Stephan\Desktop\NemosMiner\Includes\CoinNames.json
$AlgorithmCurrencies | ConvertTo-Json > c:\Users\Stephan\Desktop\NemosMiner\Includes\AlgorithmCurrency.json
