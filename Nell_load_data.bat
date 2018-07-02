::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::											Nell'Armonia - DM Load data file script								::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::																																						::
::	1. Settings & General definition																					::
::																																						::
::	2. EPMAutomate commands																										::
::	  2.1 Login 																															::
::	  2.2 Clear old file from inbox 																					::
::	  2.3 Load new file to inbox																							::
::	  2.4 BEFORE - cleardata on target PoV																		::
::	  2.5 Run data load																												::
::	  2.6 AFTER - currency conversion																					::
::	  2.7 AFTER - update Smart Push 'load year' sub var												::
::	  2.8 AFTER - smart push																									::
::	  2.9 LogOut																															::
::																																						::
::  3. Functions																															::
::	  3.1 getLoadYear --> retrieves the load year from flat file							::
::	  3.2 getDateTime --> timestamp for logs																	::
::																																						::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

@echo off


::::::::::::::::::::::::::::::::::::::::::::::
::	1. Settings & General definition				::
::::::::::::::::::::::::::::::::::::::::::::::


:: 1.1 Environment (env, data center (dc), domain, service url) ::
SET env=""
:: SET env="-test"
SET dc="PBCS_DATA_CENTER"
SET domain="PBCS_DOMAIN"
SET url=https://planning%env%-%domain%.pbcs.%dc%.oraclecloud.com

:: 1.2 EPM & Batch path ::
SET EPMAutomate="PATH_TO_EPM_FOLDER"
SET mainPath="PATH_TO_MAIN_BATCH_FOLDER"
SET batPath=%mainPath%"PATH_TO_BATCH_SUBFOLDER"

:: 1.3 admin user details ::
SET /p adminUser=<"D:\%mainPath%\ADMIN\Password\ADMIN_USER.txt"
SET /p adminPw="D:\%mainPath%\ADMIN\Password\ADMIN_PW.epw"

:: 1.4 Data management scope ::
SET LOCATION="DM_LOCATION_NAME"
SET sp="DM_START_PERIOD"
SET ep="DM_END_PERIOD"

:: 1.5 SmartPush ::
SET smartPush="SP_NAME"

:: 1.6 functions => get timestamp & format ::
set myDate=""
call:getDateTime myDate

:: 1.7 Batch Path ::
SET cloudPath="inbox/DM_FOLDER_NAME"
SET fileName="FILE_NAME"
SET cloudDataFile=%cloudPath%/%filesName%
SET localDataFile=%batPath%DATAFILES\%filesName%

:: 1.8 logs ::
SET logPath=%batPath%LOGS\
SET logFile=%logPath%Log_%LOCATION%_LoadData_%myDate%.txt
SET errFile=%logPath%Err_%LOCATION%_LoadData_%myDate%.txt
SET errMsg=%logPath%TempMsg.txt

:: 1.9 functions => get load year from flat file ::
SET year=""
SET loadYear=""
call:getLoadYear loadYear

SET prefix=FY
SET dYear=%year:~2,2%
SET loadYear=%prefix%%dYear%
SET payload=DM_YR=%loadYear%


::::::::::::::::::::::::::::::::::::::::::::::
::	2. EPMAutomate													::
::::::::::::::::::::::::::::::::::::::::::::::


:: 2.1 LogIn	::
call:getDateTime myDate
echo %myDate% - Starting data load for %LOCATION% for the year %loadYear%. Logging in to PBCS. > %logFile%
call %EPMAutomate% login %AdminUser% %adminPw% %url% %domain% >> %logFile%

:: 2.2 Clear old file from inbox ::
call:getDateTime myDate
echo %myDate% - delete existing file %fileName% from PBCS Inbox >> %logFile%
call %EPMAutomate% deletefile %cloudDataFile% >> %logFile%

:: 2.3 Load new file to inbox ::
call:getDateTime myDate
echo %myDate% - upload new file %fileName% to Cloud Inbox >> %logFile%
call %EPMAutomate% uploadfile %localDataFile% %cloudPath% >> %logFile%

:: 2.4 BEFORE rule (cleardata on target) ::
call:getDateTime myDate
echo %myDate% - run businessrule: "BR_1_BEFORE_DL" >> %logFile%
call %EPMAutomate% runbusinessrule BR_1_BEFORE_DL %payload% >> %logFile%

:: 2.5 Run data load ::
call:getDateTime myDate
echo %myDate% - Run Data Load Rule "DLR_NAME" >> %logFile%
call %EPMAutomate% rundatarule "DLR_NAME" %SP% %EP% REPLACE STORE_DATA  >> %logFile%

:: 2.6 AFTER - currency conversion ::
call:getDateTime myDate
echo %myDate% - run business rule "BR_2_AFTER_DL"  >> %logFile%
call %EPMAutomate% runbusinessrule BR_2_AFTER_DL %payload% >> %logFile%

:: 2.7 AFTER - update Smart Push 'load year' sub var ::
call:getDateTime myDate
echo %myDate% - set sub var SV_LOAD_Y = %loadYear% >> %logFile%
call %EPMAutomate% setsubstvars ALL SV_LOAD_Y=%loadYear% >> %logFile%

:: 2.8 AFTER - smart push ::
call:getDateTime myDate
echo %myDate% - Push to ASO  >> %logFile%
call %EPMAutomate% runplantypemap %MapRule% clearData=true >> %logFile%

:: 2.9 LogOut ::
call:getDateTime myDate
echo %myDate% - Data load for %LOCATION% ended successfully. Logging out of PBCS. >> %logFile%
call %EPMAutomate% logout >> %logFile%


::::::::::::::::::::::::::::::::::::::::::::::
::	3. FUNCTIONS (must be at end of file)		::
::::::::::::::::::::::::::::::::::::::::::::::


:: 3.1 getLoadYear ::
:getLoadYear
::    Returns the 'year' value from the second row of the flat file
::      tokens => position of the 'year' column in the flat file
::      skip=1 => skips first row (header row)
::      delims => file delimeter
FOR /F "tokens=3 skip=1 delims==," %%A IN (%localDataFile%) DO (
	SET year=%%A
	IF "%year%"=="" (
		:: IF %year% is not set, throw an error
		echo ERROR in the getLoadFunction --- year is not set
	) ELSE (
		:: ELSE continue running script
		GOTO :eof
	)
)
EXIT /b

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
