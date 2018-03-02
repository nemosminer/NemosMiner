REM Example 1.

REM set else=) else (
REM set endif=)
REM set greaterequal=GEQ

REM total number of nvidiagpu
REM set nvidiagpu=1
REM set /a timer = 3+%nvidiagpu%

echo prerun default file

REM check nvidia gpu if they are working
REM set /a gpu=0
REM :loop
REM for /F "tokens=*" %%p in ('"C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi" --id^=%gpu% --query-gpu^=memory.used --format^=csv^,noheader^,nounits') do set gpu_mem=%%p
REM echo.%gpu_mem% | findstr /C:"Unknown error">nul && (
REM echo %DATE% %TIME% %title% gpu %gpu%>> GPU_Lost.txt
REM NV_Inspector\nvidiaInspector.exe -restartDisplayDriver
REM increase when more GPUs are present
REM timeout %timer%
REM goto oc
REM )
REM echo.%gpu_mem% | findstr /C:"No device">nul && (
REM shutdown /r
REM )
REM set /a gpu+=1
REM if %gpu% %greaterequal% %nvidiagpu% %then%
REM goto oc
REM %else%
REM goto loop
REM %endif%

REM :oc

REM example 2.
REM Example clock settings using nvidiaInspector update nvidiaInspector.exe path accordingly or place it in prerun directory
REM !!! USE OC WITH CAUTION !!!
REM nvidiaInspector.exe -setBaseClockOffset:0,0,50 -setMemoryClockOffset:0,0,100 -setVoltageOffset:0,0,0 -setPowerTarget:0,75 -setTempTarget:0,0,92 

