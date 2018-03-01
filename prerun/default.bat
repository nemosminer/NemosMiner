REM This file will run for any algo if algo.bat does not exist
REM Place your code below

set else=) else (
set endif=)
set greaterequal=GEQ

REM total number of nvidiagpu
set nvidiagpu=1

echo prerun default file

REM check nvidia gpu if they are working
set /a gpu=0
:loop
for /F %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=%gpu% --query-gpu^=memory.used --format^=csv^,noheader^,nounits') do set gpu_mem=%%p
echo.%gpu_mem% | findstr /C:"Unknown">nul && (
echo %DATE% %TIME% %title% gpu %gpu%>> GPU_Lost.txt
NV_Inspector\nvidiaInspector.exe -restartDisplayDriver
REM increase when more GPUs are present
timeout 4
goto oc
)
set /a gpu+=1
if %gpu% %greaterequal% %nvidiagpu% %then%
goto oc
%else%
goto loop
%endif%

:oc
REM Example clock settings using nvidiaInspector update nvidiaInspector.exe path accordingly or place it in prerun directory
REM !!! USE OC WITH CAUTION !!!
REM nvidiaInspector.exe -setBaseClockOffset:0,0,50 -setMemoryClockOffset:0,0,100 -setVoltageOffset:0,0,0 -setPowerTarget:0,75 -setTempTarget:0,0,92 

