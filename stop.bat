@echo off

C:\Windows\System32\schtasks.exe /end /TN "Miner_Nemos"
timeout 1
C:\Windows\System32\Taskkill /f /im powershell.exe
timeout 1

C:\Windows\System32\Taskkill /f /im ccminer-alexis.exe
C:\Windows\System32\Taskkill /f /im ccminer_x86.exe
C:\Windows\System32\Taskkill /f /im ccminer.exe
C:\Windows\System32\Taskkill /f /im ccminer.exe
C:\Windows\System32\Taskkill /f /im ccminer.exe 
C:\Windows\System32\Taskkill /f /im ccminer.exe 

