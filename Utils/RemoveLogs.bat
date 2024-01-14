@echo off
cd /d %~dp0
set /p execute=This process will delete all unnecessary log files created by the miners and NemosMiner to free up space. Are you sure you want to continue? [Y/N]
IF /I "%execute%"=="Y" (
	cd .\Bin
	for /f "delims=" %%F in ('dir /b /s "*.log"') do @del "%%F"
	cd ..\Logs
	for /f "delims=" %%F in ('dir /b /s "*.log"') do @del "%%F"
	cd ..
	ECHO All existing log files have been successfully deleted. 
	PAUSE
)
