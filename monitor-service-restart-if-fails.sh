hostgroup servers www.example.com
watch servers
service http
interval 5m
monitor http.monitor
period wd {Sun-Sat}
alertevery 1h
alert mail.alert webmaster@example.com

http://www.tuxradar.com/answers/353
