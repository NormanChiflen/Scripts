echo. >> Check.txt
echo Server: %1 >> Check.txt
echo. >> Check.txt
sc \\%1 query fdsservice >> Check.txt
echo. >> Check.txt
echo ============================================================= >> Check.txt