@echo off
date /T
time /T
"C:\Program Files\Git\git-bash.exe" -c "ssh user@192.168.0.22 'sudo swap.sh %*  ' "


:loop

goto loop
