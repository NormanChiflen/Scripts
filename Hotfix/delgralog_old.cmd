rem This script is to remove *.hpl files from c:\winnt\temp folder

net stop w3svc
net stop gralog
net stop ablog
sleep 3
kill -f inetinfo
sleep 3
kill -f inetinfo
sleep 3
kill -f qslog
net stop w3svc

cd c:\winnt\temp
del Purchase.hpl
del Search.hpl
del DeliverClick.hpl
del Exposure.hpl
del *.hpl

