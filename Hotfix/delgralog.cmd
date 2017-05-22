net stop gralog

IISRESET /ENABLE 

IISRESET /STOP /TIMEOUT:120 

net stop ablog
sleep 60

kill -f ablog
kill -f gralog

cd c:\winnt\temp
del Purchase.hpl
del Search.hpl
del DeliverClick.hpl
del Exposure.hpl
del *.hpl

IISRESET /DISABLE