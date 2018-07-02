::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::                   Nell'Armonia - Admin username & password                 ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::                                                                            ::
::  1. Settings & General definition                                          ::
::                                                                            ::
::  2. EPMAutomate commands                                                   ::
::    2.1 prompt user for Admin credentials                                   ::
::    2.2 Encrypt password and save UN and PW                                 ::
::                                                                            ::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::::::::::::::::::::::::::::::::::::::::::::::
::  1. Settings & General definition        ::
::::::::::::::::::::::::::::::::::::::::::::::


:: EPMAutomate & ADMIN folder path
SET EPMAutomate="PATH_TO_EPMautomate_FOLDER"
SET mainPath="PATH_TO_MAIN_BATCH_FOLDER"
SET adminPath=%mainPath%\ADMIN

:: EPMautomate url and domain (cloud)
SET env=""
SET dc="DATA_CENTER"
SET domain="CLIENT_DOMAIN_NAME"
SET url=https://planning%env%-%domain%.pbcs.%dc%.oraclecloud.com


::::::::::::::::::::::::::::::::::::::::::::::
::  2. EPMAutomate                          ::
::::::::::::::::::::::::::::::::::::::::::::::


:: 2.1 Admin credentials (prompt)
SET /p user="Please Enter your PBCS User (admin role only!): ""
ECHO user = %user%
SET /p password="Please Enter your PBCS password (admin role only!): "
ECHO password = %password%

:: 2.2 save Admin user to file
ECHO %user% > D:\%adminPath%\Password\ADMIN_USER.txt

:: create encrypted PW file
CALL %EPMAutomate% encrypt %password% %user% D:\%adminPath%\Password\ADMIN_PW.epw
