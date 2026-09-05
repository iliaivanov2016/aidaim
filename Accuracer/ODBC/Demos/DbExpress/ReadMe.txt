
DbExpress Demo for Accuracer ODBC Driver
========================================


Company information
-------------------

Company Name:
  AidAim Software
Contact E-mail Address:
  support@aidaim.com
Contact WWW URL:
  http://www.aidaim.com


How to run
----------

1) Use DSN named 'acr' pointed to "..\Data\test.adb".
   Detailed instruction on how to create a DSN you can find in "..\Test\ReadMe.txt".

2) Run OdbcExplor.exe -- Delphi Test program for Open Odbc DbExpress Driver.
   We tested Accuracer ODBC Driver with ODBC Explorer v.2.00, 2003-11-06.

3) Type 'acr' in DSN field, press 'Connect' button, then 'Open'. Enjoy!

Note, that 0 is not False for this version of Odbc DbExpress Driver.
I do not know what is the False for it...
So, it interprets any not NULL answer as True in Boolean fields.


Technical support
-----------------

If the problem persists, please, inform us about the following:

  - Accuracer ODBC Driver version.
  - Where did you obtain the product (http or ftp site).
  - Environmental information: your OS and Service Pack
  - DBMS which is used with the products
  - Description of your problem (as much information as possible to 
    retrieve the problem)
  - Attach a test database or (and) a project where the problem could be reproduced 
    (it helps us to solve your issue as soon as possible)
