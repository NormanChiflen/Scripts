@echo off
pause

SETLOCAL ENABLEDELAYEDEXPANSION
for %%a in (DirectedBuilds,ContinuousIntegration,ReleaseCandidate,Release) do (

    set buildpath=%%a

    set AirBuildPath=F:\!buildpath!\depot\agtexpe\products\air
    set AirDeprepsPath=F:\depreps\!buildpath!\depot.agtexpe.products.air
    for /f %%i in ('dir /b /ad !AirDeprepsPath!') do (
        if not exist !AirBuildPath!\%%i (
            echo Removing !AirDeprepsPath!\%%i...
            rd /s /q !AirDeprepsPath!\%%i
        )
    )

    set BFSBuildPath=F:\!buildpath!\depot\bfsexpe\products\air
    set BFSDeprepsPath=F:\depreps\!buildpath!\depot.bfsexpe.products.air
    for /f %%i in ('dir /b /ad !BFSDeprepsPath!') do (
        if not exist !BFSBuildPath!\%%i (
            echo Removing !BFSDeprepsPath!\%%i...
            rd /s /q !BFSDeprepsPath!\%%i
        )
    )

    set DSAPIBuildPath=F:\!buildpath!\depot\st2\products\DSAPI
    set DSAPIDeprepsPath=F:\depreps\!buildpath!\depot.st2.products.DSAPI
    for /f %%i in ('dir /b /ad !DSAPIDeprepsPath!') do (
        if not exist !DSAPIBuildPath!\%%i (
            echo Removing !DSAPIDeprepsPath!\%%i...
            rd /s /q !DSAPIDeprepsPath!\%%i
        )
    )

)
ENDLOCAL
