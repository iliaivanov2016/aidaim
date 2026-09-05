del test.mdb
del /Q *.adb
copy 1.mdb test.mdb
del /Q *.tbl
del /Q *.edb
cd Paradox
call d.bat
cd ..\Dbisam
call d.bat
cd ..\Advantage
call d.bat

