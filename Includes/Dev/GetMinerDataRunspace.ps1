# Setup runspace to collect miner data in a separate thread
$Runspace = [RunspaceFactory]::CreateRunspace()
$Runspace.Name = "$($this.Name)_GetMinerData"
$Runspace.Open()

[Void]$Runspace.SessionStateProxy.Path.SetLocation($Variables.MainPath)

# $Runspace.SessionStateProxy.SetVariable('Miner', $this)
$Runspace.SessionStateProxy.SetVariable('Miner', $Miner)
# $Runspace.SessionStateProxy.SetVariable('Config', $Config)
# $Runspace.SessionStateProxy.SetVariable('Variables', $Variables)

$PowerShell = [PowerShell]::Create()
$PowerShell.Runspace = $Runspace
$PowerShell.AddScript(
    { 
        $ScriptBody = "using module .\Includes\Include.psm1"; $Script = [ScriptBlock]::Create($ScriptBody); . $Script

        $Data = [PSCustomObject]@{ }

        While ($true) { 
            $NextLoop = ([DateTime]::Now).AddSeconds($Miner.DataCollectInterval)
            Try { 
                "$($Miner.name) '$($Miner.DataCollectInterval)' 1" >> "$($Miner.Name)_Debug.txt"
                If ($Data = $Miner.GetMinerData()) { 
                    "$($Miner.name) '$($Miner.DataCollectInterval)' 2" >> "$($Miner.Name)_Debug.txt"
                    $Miner.LastSample = $Data
                    $Miner.Data += $Data
                    $Data | ConvertTo-Json >> "$($Miner.name)_Data.txt"
                }
            }
            Catch { 
                "$($Miner.name) '$($Miner.DataCollectInterval)' 3" >> "$($Miner.Name)_Debug.txt"
                $Error[0] >> "$($Miner.Name)_Debug.txt"
            }
            While (([DateTime]::Now) -lt $NextLoop) { Start-Sleep -Milliseconds 200 }
        }
    }
)

$AsyncObject = $PowerShell.BeginInvoke()
# $Miner.GetMinerDataRunspace = $Runspace
# $Miner.GetMinerDataPowerShell = $PowerShell

# $Miner.GetMinerDataRunspace | Add-Member -Force @{ 
#     AsyncObject = $AsyncObject
# }
