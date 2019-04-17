::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::                  Nell'Armonia - DM Load data file script                   ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::                                                                            ::
::  1. Settings & General definition                                          ::
::                                                                            ::
::  2. EPMAutomate commands                                                   ::
::    2.1 Login                                                               ::
::    2.2 Download artifact snapshot (backup) from PBCS                       ::
::    2.3 Rename backup file with current date                                ::
::    2.4 log out of PBCS				                                      ::
::  3. Functions                                                              ::
::    3.1  getDateTime --> timestamp for logs                                 ::
::                                                                            ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off

::::::::::::::::::::::::::::::::::::::::::::::
::  1. Settings & General definition        ::
::::::::::::::::::::::::::::::::::::::::::::::


:: 1.1 Environment (env, data center (dc), domain, service url) ::
SET env=""
::SET env="-test"
SET dc="DATA_CENTER"
SET domain="CLIENT_DOMAIN"
SET url=https://planning%env%-%domain%.pbcs.%dc%.oraclecloud.com

echo this is the URL %url%

:: 1.2 EPM & Batch path ::
SET EPMAutomate="PATH_TO_EPMautomate_FOLDER"  rem example - C:\Oracle\EPM Automate\bin\epmautomate.bat
SET mainPath="PATH_TO_MAIN_BATCH_FOLDER"
SET adminPath=%mainPath%\ADMIN\Password\
SET batPath=%mainPath%\PATH_TO_SPECIFIC_BATCH_FOLDER
SET logpath=%mainPath%\Logs
SET backupfolder=%mainPath%\Backup
SET myDate=Date

 
:: 1.3 admin user details ::
SET /p adminUser=<%adminPath%ADMIN_USER.txt
SET adminPw=%adminPath%ADMIN_PW.epw

echo admin user is set to %adminUser%

::::::::::::::::::::::::::::::::::::::::::::::
::  2. EPMAutomate                          ::
::::::::::::::::::::::::::::::::::::::::::::::

echo starting EPMautomate calls

:: 2.1 LogIn ::

echo Starting daily backup of PBCS instance. Logging in to PBCS.
call %EPMAutomate% login %AdminUser% %adminPw% %url% %domain%

echo Logged in to PBCS

:: 2.2 Download backup from cloud ::
echo Downloading daily artifat snapshot from PBCS.
call %EPMAutomate% downloadfile "Artifact Snapshot"


:: 2.3 Rename to current date ::
echo Renamimg backup to current date
call %EPMAutomate% downloadfile "Artifact Snapshot"
Ren "Artifact Snapshot.zip" Backup_crystalBall_%myDate


:: 2.4 LogOut ::
echo Daily backup is finished. Logging out of PBCS...
call %EPMAutomate% logout 

echo Daily backup process is finished. please review LOG for details

::::::::::::::::::::::::::::::::::::::::::::::
::  3. FUNCTIONS (must be at end of file)   ::
::::::::::::::::::::::::::::::::::::::::::::::

:: 3.1 getDateTime ::
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

