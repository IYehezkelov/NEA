::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::               Nell'Armonia - launch PBCS process script                    ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::                                                                            ::
::  1. Settings & General definition                                          ::
::                                                                            ::
::	2. EPMAutomate commands                                                   ::
::	  2.1 Login                                                               ::
::	  2.2 Launch business rule/sc                                             ::
::	  2.3 push data to ASO                                                    ::
::	  2.4 Logout                                                              ::
::                                                                            ::
::  3. Functions                                                              ::
::	  3.1 getDateTime --> timestamp for logs                                  ::
::                                                                            ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off


::::::::::::::::::::::::::::::::::::::::::::::
::  1. Settings & General definition        ::
::::::::::::::::::::::::::::::::::::::::::::::


:: 1.1 Environment (env, data center (dc), domain, service url) ::
SET env=""
:: SET env="-test"
SET dc="DATA_CENTER"
SET domain="CLIENT_DOMAIN_NAME"
SET url=https://planning%env%-%domain%.pbcs.%dc%.oraclecloud.com
SET location=Israel

:: 1.1 EPM & Batch path ::
SET EPMAutomate="PATH_TO_EPMautomate_FOLDER"
SET mainPath="PATH_TO_MAIN_BATCH_FOLDER"
SET batPath=%mainPath%"PATH_TO_SPECIFIC_BATCH_FOLDER"

:: 1.2 admin user details ::
SET /p adminUser=<"D:\%mainPath%\ADMIN\Password\ADMIN_USER.txt"
SET /p adminPwPath="D:\%mainPath%\ADMIN\Password\ADMIN_PW.epw"

:: 1.3 SmartPush ::
SET sp1="SMART_PUSH_1"

:: 1.4 Timestamp & Format ::
set myDate=""
call:getDateTime myDate

:: 1.5 logs ::
SET logPath=%batPath%LOGS\
SET logFile=%logPath%Log_Allocation_FCST_%myDate%.txt
SET errFile=%logPath%Err_Allocation_FCST_%myDate%.txt
SET errMsg=%logPath%TempMsg.txt

:: 1.6 prompts - get data from user input ::
SET /p LBE_SCE=Please enter the last best estimate scenario (AOP / FCST):
SET /p LBE_VER=Please enter the last best estimate version (WV / V1 / V2 / V3 / VF):


::::::::::::::::::::::::::::::::::::::::::::::
::  2. EPMAutomate                          ::
::::::::::::::::::::::::::::::::::::::::::::::


:: 2.1 LogIn	::
call:getDateTime myDate
echo %myDate% - Initializing Forecast for %location%. Logging in to PBCS. > %logfile%
call %EPMAutomate% login %adminUser% %adminPwPath% %url% %domain% >> %logfile%

:: 2.2 Launch Allocation business Rule ::
call:getDateTime myDate
echo %myDate% - run Forecast INIT business rule "name_of_business rule" (%LBE_SCE% / %LBE_VER%) >> %logfile%
call %EPMAutomate% runbusinessrule "name_of_business_rule" LBE_SCE=%LBE_SCE% LBE_VER=%LBE_VER%  >> %logfile%

:: 2.3 Push the data to ASO ::
call:getDateTime myDate
echo %myDate% - Pushing Data to reporting Cube (ASO)  >> %logfile%
call %EPMAutomate% runplantypemap %sp1% clearData=true >> %logfile%

:: 2.4 LogOut ::
call:getDateTime myDate
echo %myDate% - Forecast Initialization for %location% ended successfully. Logging out of PBCS. >> %logfile%
call %EPMAutomate% logout >> %logfile%


::::::::::::::::::::::::::::::::::::::::::::::
::  3. FUNCTIONS (must be at end of file)   ::
::::::::::::::::::::::::::::::::::::::::::::::


:: 3.2 getDateTime ::
:getDateTime
:: returns a unique string based on a date-time format: "mm-dd-yy_hh-mm-ss" ::
SETLOCAL
  for /f "skip=1 tokens=2-4 delims=(-)" %%a in ('"echo.|date"') do (
    for /f "tokens=1-3 delims=/.- " %%A in ("%date:* =%") do (
        :: time format --> A = hours, B = minutes, C = seconds ::
      set %%a=%%A & set %%b=%%B & set %%c=%%C))
        :: date format --> yy = year, mm = month, dd = day
      set /a "yy=10000%yy% %%10000,mm=100%mm% %% 100,dd=100%dd% %% 100"

      for /f "tokens=1-4 delims=:. " %%A in ("%time: =0%" ) do (
          :: compose timestamp string ::
        set myDate=%mm%.%dd%.%yy%_%%A-%%B-%%C)
          :: IF timestamp value IS NOT null, set myDate = timestamp ::
          :: ELSE fail and echo "failed" ::
ENDLOCAL & IF "%~1" NEQ "" (set %~1=%myDate%) ELSE echo.Failure: %myDate% failed
exit /b

:eof
