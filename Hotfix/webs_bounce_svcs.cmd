net stop gralog

IISRESET /ENABLE 

IISRESET /STOP /TIMEOUT:120 

net stop ablog
sleep 60

kill -f qslog

IISRESET /START

IISRESET /DISABLE

net start ablog
net start gralog

