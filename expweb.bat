rem create output.dir
set OUTPUT_ROOT=%WORKSPACE%\bin
set BUILD_BRANCHTYPE=trunk
set BUILD_SEQUENCE=ci
set BUILD_VERSION=trunk
set P4_PATH=//www/expweb/trunk
set P4USER=svc.ewe.hudson
set P4CHARSET=utf8
set P4COMMANDCHARSET=utf8
set USE_64BITJDK=1
mkdir %OUTPUT_ROOT%
 
pushd src
call setenv.cmd
set OUTPUT_LIB=lib\ivy
set
p4 revert //...
p4 sync war/WEB-INF/classes/beancontexts/external/...
ant ivy-update-auto -Dtestng.threadcount=1
p4 revert //...
echo %ERRORLEVEL%
