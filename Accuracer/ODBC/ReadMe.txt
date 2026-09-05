
Accuracer ODBC Driver: README
=============================

Please read this file carefully (especially the INSTALLATION chapter) 
before installing the program to your computer.


Contents
--------

  Program information
  Company information
  Description
  Specification
  Installation
  Purchasing / Registration
  Copyright and licenses
  Warranty and guarantee
  Technical support
  Important note


Program information
-------------------

Program Name:
  Accuracer ODBC Driver
License Types:
  Trial (for 1 developer, without source code) 
    Limitations:
    ------------
    This version allows up to two database multi-user connections and 
    up to five multi-thread single-user connections. 
    Trial version is intended for evaluation only! 
    To develop your application you must buy one or more of the following 
    commercial versions: 
  Std (for 1 developer, without source code)
  Team4 (for 4 developers, without source code)
  Team8 (for 8 developers, without source code)
  Enterprise (Enterprise License - for entire company, with source code)
Program Version:
  5.00
Program Release Date:
  02/27/2014
Program Purpose:
  Provides access to Accuracer databases according to ODBC v.2 specification.
Tested Environment:
  CodeGear Delphi 2009, C++Builder 2009 IDE (via BDE)
  php v.4 (See php demo supplied with the product)
  BDE (See Test demo supplied with the product) 
  Microsoft Visual C++.Net v.7.0 (See included DBFetch demo) 
  Microsoft Excel 2003
  Microsoft Excel 2002 SP-1 
  Microsoft Access 2002 SP-1 
  Microsoft Visual Studio .Net, Server Explorer 
  BusinessObjects Crystal Reports 11 
  DbExpress driver for ODBC, v.2.12. Tested using DBExpress Open ODBC Explorer, v.2.12


Company information
-------------------

Company Name:
  AidAim Software
Contact E-mail Address:
  support@aidaim.com
Contact WWW URL:
  http://www.aidaim.com


Description
----------
The Accuracer ODBC Driver provides read/write access to Accuracer database 
in accordance with Level1 interface conformance of ODBC v.2 specification.

Starting with v.2.00 Accuracer ODBC Driver works in client/server mode as 
well as in file-server mode it supported before.

In file-server mode Accuracer ODBC Driver requires a local or network path
to the database file. When you update or insert new data, be sure that the
database you work with is not opened in exclusive mode by another application
(for example, by AccuracerDatabaseServer utility).

In client/server mode you must specify connection parameters (such as network
address of the server). Be sure that the AccuracerDatabaseServer utility 
or your own server application was started and configured properly to work 
with the target database.

Starting with v.3.00 Accuracer ODBC Driver works with encrypted databases, 
as well as with Accuracer Database Server with network traffic compression 
and encryption.


Specification
-------------

The Accuracer ODBC Driver exhibit Level1 interface conformance. The features 
in the Core level also correspond to the features defined in the ISO CLI specification 
and to the nonoptional features defined in the X/Open CLI specification. 
The Accuracer ODBC Driver allows the application to do all of the following: 
- Allocate and free all types of handles, by calling SQLAllocConnect, SQLAllocEnv, SQLAllocStmt,
 and SQLFreeConnect, SQLFreeEnv, SQLFreeStmt.
- Use all forms of the SQLFreeStmt function.
- Gain access to the description (metadata) of result sets, by calling SQLColAttributes, 
SQLDescribeCol, SQLNumResultCols, and SQLRowCount. 
- Query the data dictionary, by calling the catalog functions SQLGetTypeInfo, 
SQLTables, and SQLColumns. 
- Establish connections, by calling SQLConnect and SQLDriverConnect. 
- Handle dynamic parameters, including arrays of parameters, in the input direction only, 
by calling SQLBindParameter. 
- Prepare and execute SQL statements by calling SQLPrepare and SQLExecute. 
Execute SQL statements, by calling SQLExecDirect. All these functions support 
SQL template and insert values binding by SQLBindParameter in it.
- Bind result set columns using row-wise binding as well as column-wise binding, 
by calling SQLBindCol. 
- Fetch one binding row of a result set data and scroll the cursor to the next row, 
in the forward direction only, by calling SQLFetch or by calling SQLExtendedFetch. 
- Use scrollable cursors, and thereby achieve access to a result set in methods 
other than forward-only, by calling SQLExtendedFetch with the following 
FetchOrientation arguments:  SQL_FETCH_NEXT, SQL_FETCH_FIRST, 
SQL_FETCH_LAST, SQL_FETCH_PRIOR, SQL_FETCH_ABSOLUTE, 
SQL_FETCH_RELATIVE. 
- Fetch one row of a result set or multiple rows using block cursors, by calling 
SQLExtendedFetch.
- Obtain an unbound column in parts, by calling SQLGetData. 
- Obtain current values of connection and statement attributes, by calling 
SQLGetConnectOption and SQLGetStmtOption, and set all attributes 
to their default values and set certain attributes to nondefault values 
by calling SQLSetConnectOption and SQLSetStmtOption. 
- Detect driver capabilities, by calling SQLGetFunctions and SQLGetInfo. 


Installation
------------

1) Unpack zip archive containing Accuracer ODBC Driver into the directory you like to install the 
Accuracer ODBC Driver. 

2) Run the SETUP.EXE file from this directory.

3) Click Install button to install the driver. Driver will be installed to the current dirrectory.
To uninstall the driver, click Uninstal buttun. To install new version of the driver you should
uninstall the previous one first. You must copy new version of the driver to the folder with 
current version then install new version from the same folder.


Purchasing / Registration
-------------------------

Visit our site http://www.aidaim.com to purchase or register the product.


Copyright and license
---------------------

See "license.txt" file.


Warranty and guarantee
----------------------

See "license.txt" file.


Technical support
-----------------

Before you contact us, please do the following:

  - Make sure you have performed all the required steps correctly. 
  - Look at the accompanying documentation.
  - Visit our Internet site at http://www.aidaim.com. It's a good chance 
    that you'll find the additional information and a newer version of our product there.

If the problem persists, please, inform us about the following:

  - Accuracer ODBC Driver version.
  - Where did you obtain the product (http or ftp site).
  - Environmental information: your OS and Service Pack
  - DBMS which is used with the products
  - Description of your problem (as much information as possible to 
    retrieve the problem)
  - Attach a test database or (and) a project where the problem could be reproduced 
    (it helps us to solve your issue as soon as possible)

Typically AidAim Software Support Team answer messages in 24 hours, but 
depending on singularity and difficulty of your question it may take a bit 
longer.

Should you have any ideas on improving the existing functions of this 
product after you have downloaded and used it, be easy to e-mail us. 
All registered users who buy this product may also send their offers 
to add new possibilities and/or to change the product's functions.
We consider any ideas and we may take them into account while creating 
new versions of our products.


Important note
--------------

This product, the software itself and accompanying documentation, is developed 
and delivered in accordance with international treaties.

Some countries restrict the exporting of software that uses strong encryption. If you will be
exporting software that uses this product by AidAim Software, we strongly advise you to find
out what your country's laws allow or restrict.
  