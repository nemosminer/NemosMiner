                    $Url = "https://api.minerstat.com/v2/coins?algo=Ethash"
                    $Response = Invoke-RestMethod -Uri $Url

                    If ($Response.code -eq 200) { 
                        If ($Response.info.blocks -gt $Variables.DAGdata.Currency.FIRO.BlockHeight) { 
                            $Variables.DAGdata.Currency.Remove($_)
                            $Variables.DAGdata.Currency.Add($_, [PSCustomObject]@{ 
                                BlockHeight = $Response.info.blocks
                                CoinName    = Get-CoinName "FIRO"
                                DAGsize     = Get-DAGSize -Block $Response.info.blocks -Currency "FIRO"
                                Epoch       = Get-Epoch -BlockHeight $Response.info.blocks -Currency "FIRO"
                            })
                            $Variables.DAGdata.Updated.FiroOrg = (Get-Date).ToUniversalTime()
                        }
                        Write-Message -Level Info "Loaded DAG data from '$Url'."
                    }