@echo off
call C:\Tools\Mining\Nemos\stop.bat

C:\Windows\System32\Taskkill /f /im tail.exe

timeout 1
del C:\Tools\Mining\Nemos\Logs\miner.log
timeout 1

call C:\Tools\Mining\Nemos\start.bat
