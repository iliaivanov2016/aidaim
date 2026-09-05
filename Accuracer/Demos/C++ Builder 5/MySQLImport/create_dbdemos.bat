@echo off
cls
echo --- Creating MySQL database DBDEMOS from DBDEMOS.SQL script ---
echo ---                                                         ---

if not exist dbdemos.sql goto file1_not_found

c:\mysql\bin\mysql <dbdemos.sql
goto CheckOK

:file1_not_found
echo ERROR: SQL script file DBDEMOS.SQL not found
if exist DBDEMOS.SQL.ZIP echo You should unzip the existing archive DBDEMOS.SQL.ZIP. Process aborted
goto end

:CheckOK
if errorlevel 1 goto level1

:level0
echo database DBDEMOS was created successfully
goto end

:level1
echo ERROR processing DBDEMOS.SQL script. Process aborted.

:end
pause
