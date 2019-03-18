REM This file will run for any algo if AlgoName.bat does not exist
REM Place your code below and rename this file to default.bat

nvidiaInspector.exe -setBaseClockOffset:0,0,0 -setMemoryClockOffset:0,0,0 -setVoltageOffset:0,0,0 -setPowerTarget:0,60 -setTempTarget:0,0,85 
nvidiaInspector.exe -setBaseClockOffset:0,1,0 -setMemoryClockOffset:0,1,0 -setVoltageOffset:0,1,0 -setPowerTarget:1,60 -setTempTarget:0,1,85
nvidiaInspector.exe -setBaseClockOffset:0,2,0 -setMemoryClockOffset:0,2,0 -setVoltageOffset:0,2,0 -setPowerTarget:2,60 -setTempTarget:0,2,85
nvidiaInspector.exe -setBaseClockOffset:0,3,0 -setMemoryClockOffset:0,3,0 -setVoltageOffset:0,3,0 -setPowerTarget:3,60 -setTempTarget:0,3,85
nvidiaInspector.exe -setBaseClockOffset:0,4,0 -setMemoryClockOffset:0,4,0 -setVoltageOffset:0,4,0 -setPowerTarget:4,60 -setTempTarget:0,4,85
nvidiaInspector.exe -setBaseClockOffset:0,5,0 -setMemoryClockOffset:0,5,0 -setVoltageOffset:0,5,0 -setPowerTarget:5,60 -setTempTarget:0,5,85
 

