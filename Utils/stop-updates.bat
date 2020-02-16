sc config wuauserv start= disabled
net stop wuauserv

sc config bits start= disabled
net stop bits

sc config dosvc start= disabled
net stop dosvc

pause
