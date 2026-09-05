md ..\Client2
md ..\Client2\Data
md ..\Client3
md ..\Client3\Data
md ..\Client4
md ..\Client4\Data
md ..\Client5
md ..\Client5\Data
copy *.exe ..\Client2\*.*
copy Data\*.fdb ..\Client2\Data\*.fdb
copy Client2.ini ..\Client2\Client.ini
copy *.exe ..\Client3\*.*
copy Data\*.fdb ..\Client3\Data\*.fdb
copy Client3.ini ..\Client3\Client.ini
copy *.exe ..\Client4\*.*
copy Data\*.fdb ..\Client4\Data\*.fdb
copy Client4.ini ..\Client4\Client.ini
copy *.exe ..\Client5\*.*
copy Data\*.fdb ..\Client5\Data\*.fdb
copy Client5.ini ..\Client5\Client.ini