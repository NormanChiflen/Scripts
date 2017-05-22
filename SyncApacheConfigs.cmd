@echo OFF

logevent -e 11684 -r "expweb5551-httpd ConfigSync" "Apache Config Sync Start"
e:
cd e:\apps\deploymenthome\expweb5551\appconfig\httpd_config
:: Sync P4 files
e:/apps/deploymenthome/expweb5551\bin\p4.exe  -p  karmalabproxy-perforce.sea.corp.expecn.com:1994 -u  svc.ewe.expweb -P  0GS4sG0C -C utf8 -Q utf8 -c CHELWBTSTB-01-expweb5551-appconfig sync ...

set expwebDURoot=e:/apps/deploymenthome/expweb5551
set apacheDURoot=e:/apps/deploymenthome/expweb5551\httpd
set httpdStatusPort=55515
set httpPort=55518
set httpsPort=55513
set ajpPort=55519

:: Restart gracefully which will start writing to new access and error log and remove the file lock.
e:\apps\thirdparty\apache-httpd\MSWin64\2.2.22-1\bin\httpd.exe -k restart -n expweb5551-httpd

logevent -e 11685 -r "expweb5551-httpd ConfigSync" "Apache Config Sync Complete"
