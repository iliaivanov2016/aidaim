
EasyTable for Delphi / C++ Builder: README
==========================================

Please read this file carefully (especially the INSTALLATION chapter) 
before installing the program to your computer.


Contents
--------

  Program information
  Company information
  Description
  Specification
  Features and Benefits
  Installation
  Purchasing / Registration
  Copyright and licenses
  Warranty and guarantee
  Technical support
  Important note
  Other products recommended to use


Program information
-------------------

Program Name:
  EasyTable
License Types:
  Lite       (for 1 developer, without source code, no SQL, no sessions)
  Com        (for 1 developer, without source code)
  Pro        (for 1 developer, with source code)
  Team4      (for 4 developers, with source code)
  Team8      (for 8 developers, with source code)
  Enterprise (Enterprise License - for entire company, with source code)
Program Version:
  23.00
Program Release Date:
  10/21/2025
Program Purpose:
  EasyTable is a compact, fast and powerful BDE alternative providing 
  access to a database in a single file format. 
Target Environment:
  Delphi 4, 5, 6, 7, Delphi 2005, 2006, 2007, 2009, 2010, XE, XE2, XE3, XE4, XE5, XE6, XE7, XE8, 10, 10.1, 10.2, 10.3, 10.4, 11, 11.1, 11.2, 11.3, 12.0, 12.1, 12.2, 12.3, 13 and 
  C++ Builder 4, 5, 6, C++ Builder 2006, 2007, 2009, 2010, XE, XE2, XE3, XE4, XE5, XE6, XE7, XE8, 10, 10.1, 10.2, 10.3, 10.4, 11, 11.1, 11.2, 11.3, 12.0, 12.1, 12.2, 12.3, 13 for Win32/Win64.


Company information
-------------------

Company Name:
  AidAim Software
Contact E-mail Address:
  support@aidaim.com
Contact WWW URL:
  https://aidaim.com


Description
-----------


EasyTable is a compact SQL database engine for Delphi and C++ Builder designed 
to be used with small applications such as personal databases, notebooks, 
phone books, bookmarkers, etc., when using external drivers (such as 
standard Borland Database Engine) is pointless. 
EasyTable provides access to a database in its own format and can stores 
all the tables in a single database file. 

EasyTable does not require BDE and provides all the TTable's functions
such as Master/Detail relationship, Filtering, Searching, Sorting, Key, 
Range, BLOB fields, and has some advanced features such as data encryption, 
BLOB data compression, multi-indexes, table restructuring and repairing, 
shareable in memory capabilities, in-memory mode and others. It is fully 
compatible with all standard DB controls, allows using standard database 
operations, supports calculated and lookup fields as well as 
internationalization/localization an Unicode, provides data importing from 
and exporting to any data source, includes some utilities with sources 
(f.e. EasyTable Manager), comprehensive help and many demos.

EasyTable provides the following services:

  - SQL support 
  - All tables in a single database file
  - Master / detail relationship
  - Creating, renaming, emptying, deleting, restructuring and repairing tables
  - Creating, editing, deleting, navigating and searching for records
  - Creating and deleting multiple indexes
  - Calculated and lookup fields
  - Filtering support
  - Using BLOB fields with data compression ability
  - Table encryption, including both table data and BLOB data
  - Protecting data from unauthorized access by external tools (such as disk editors)
  - In-memory mode is also available to speed up the work with small tables
  - Importing from and exporting to any data source in fast and easy way
  - Internationalization/Localization and Unicode support

EasyTable does not require BDE or any external drivers and has small 
footprint. Its search performance is excellent and data access speed 
is extremely fast.


Specification
-------------

All the tables are stored in a single database file.
Data types: ftAutoInc, ftInteger, ftSmallInt, ftFloat, ftDateTime, ftDate,
            ftTime, ftBLOB, ftMemo, ftGraphic, 
            ftString (any fixed length string),
            ftCurrency, ftWord, ftBoolean, ftLargeInt, ftFmtMemo,
            ftBytes, ftBCD, ftWideString. 
Maximum records quantity: up to 2^32 (over 4 billions). 
Maximum fields per table: 2^31 (over 2 billions). 
Maximum indexes per table: 2^31 (over 2 billions). 
Maximum index fields per index: 2^31 (over 2 billions). 
Maximum field name's length: 253 characters.
Maximum index name's length: 253 characters.
BLOB fields block size: > 100 bytes, default 512. 
BLOB compression modes: None, Fastest, Default, Max. 
Table encryption: Rijndael with 256-bit key, CRC-32 protected. 
Search operators: <,>,=,<>,<=,>=, like, not like, is null, is not null, 
                  and, or, not, (). 
File types:
 - All tables in a single file (v.5.xx format):
        *.edb
 - Each table in several files (v.2.20 format):
        *.dat - table (all records and table header), 
        *.idx - indexes for table,
        *.bif - blob fields headers,
        *.bdf - blob data file.


Features and Benefits
---------------------

Compactness. 
  - Short compiled code with approximate size 450 Kbytes, no external 
    drivers (such as BDE) required. Especially designed for small 
    applications such as personal databases, notebooks, phone books, 
    bookmarkers, etc., but it works with huge data, too. 
  - Small database size. EasyTable will allow you store your data 
    compactly, due to its well-thought database maintenance, as well as 
    due to some special means, such as automatic BLOB headers compression. 
  - Fast BLOB data compression. Your large data fields will need the less 
    possible disk space. EasyTable compresses data on the fly. The data 
    packing/unpacking process is not appreciable compared to the disk 
    write/read process. The compression speed is essentially greater than 
    that of popular archivers such as zip, rar, arj, and so on. 
  - Automatic reducing of the database file size in case of deleting data from end of file
Rapidity. 
  - Fast search by indexes. Now EasyTable is one of the fastest existing 
    TTable replacement. EasyTable is even faster then many popular DB 
    engines created by world software industry leaders. 
  - High-speed I/O performance is achieved by means of using read-ahead
    and write buffering and special optimized algorithms. 
  - In-memory mode assigned to speeding up the working process in case 
    when all the data may be stored to Random Access Memory. 
  - Quick operations with strings. High strings comparison speed 
    (assembler library) and an advanced sorting algorithm are used. 
Functionality. 
  - Advanced search engine. Try our advanced substring search with 'like' 
    operator using wildcards '%' and '_'. EasyTable search engine also 
    supports 'is null' and 'is not null' searching operators. 
  - Single file format. All tables can be stored in a single database file 
    as well as each table in several files. 
  - Full multiple index support, i.e. numerous fields in a table may 
    comprise an index. EasyTable provides descending and ascending indexes, 
    case-sensitive and insensitive indexes for string fields. 
  - Shareable In Memory tables support for working with the same table 
    using several TEasyTable components at a time. 
Compatibility. 
  - All the necessary data types including BLOB fields' support. EasyTable 
    supports almost all TTable field data types and provides even more 
    power supporting string fields of any fixed length. 
  - Full compatibility with standard DB-aware visual controls such as 
    QuickReport, DBGrid, DBNavigator, DBImage, DBMemo, DBRichEdit and 
    others. 
  - Calculated and lookup fields may be used in the same to TTable way. 
  - Most of TTable functions support including Key and Range methods. 
Security. 
  - Table encryption is executed by Rijndael, the AES (American Encryption 
    Standard) winner, all table data is checked by means of CRC-32. 
    EasyTable protects your data in the best way. 
Reliability. 
  - The ability to repair the table data in case of a failure, which may 
    occur due to hardware failure or in case of the operating system 
    failure owing to another application's incorrect operating. 
  - Auto-rebuild of table indexes in case of corruption. 
  - EasyTable really works with very large databases (about millions 
    records). 
Convenience. 
  - Single file format. All tables can be stored in a single database file. 
  - TEasyDatabase component for working with several tables in a single 
    file in easy way. 
  - Table restructuring is being executed in the easiest way keeping all 
    the existing data and using especially designed means. 
  - Data importing from and exporting to any DataSource. EasyTable 
    provides you the simplest way to import and export tables by means of 
    using ImportTable and ExportTable methods. 
  - Internationalization / Localization support. All text search and 
    sorting functions use current system locale, so localizing your 
    program with EasyTable is a very simple task. 
  - Unicode support. All the text operations are working with multi-byte 
    encoding using ftWideString. 
  - Displaying progress during potentially slow operations with the table 
    data is supported. 
  - DBTransfer utility coming within delivery set of EasyTable will help 
    you to transfer your existing tables from database systems having BDE 
    driver, such as Access, Oracle, SQL Server tables to the EasyTable 
    database and vice versa. 
  - Converter utility is designed to convert tables of EasyTable v.2.20 
    format to v.3.00 single-file format. 
  - EasyTable Manager. This utility helps you in visual database 
    management. You may easily create and edit EasyTable databases as well 
    as any table you wish. Also it allows importing data from a file to a 
    BLOB field and exporting from a BLOB field to a file as well as 
    importing your table from and exporting to Paradox and DBase formats 
    or any other datasource. 
  - All utilities include all the sources. So you have good examples of 
    the EasyTable's work and they will help you in programming with 
    EasyTable. 
  - Examples of using. There are many demos for Delphi in EasyTable 
    delivery package now. 
  - Comprehensive help. EasyTable comes with full documentation on it 
    presented in EasyTable Developer's Guide and EasyTable Reference.


Installation
------------

1) Make sure that all copies of Delphi (or C++ Builder) are currently 
   closed and not running on the target system. Also, if you are 
   replacing an existing version of EasyTable, please remove all files and
   the package of the prior version before running the new setup program.

2) Unpack zip archive containing EasyTable into any directory. 

3) Run the INSTALL.EXE from this directory.

4) Follow on-screen instructions of step-by-step setup wizard to install 
   EasyTable.

5) If after the installation EasyTable components
   don't appear in Components Palette of the IDE, please follow the next
   instructions:

  * From the IDE, select 'Component | Install Packages...'.
  * Click the 'Add' button.
  * In the ..\EasyTable\Lib\Delphi# (or ..\EasyTable\Lib\C++ Builder#) directory,
    select the dclEasyTableD#.BPL (or dclEasyTableB#.BPL) file.
  * Click the 'OK' button to close the dialog. 
  * Finally, select 'Tools | Environment Options' from the main menu. From this dialog,
    select the 'Library' tab and insure that the
    ..\EasyTable\Lib\Delphi# (or ..\EasyTable\Lib\C++ Builder#) directory is
    included in the 'Library Path' line.

6) If you use C++ Builder 2006 (or 2007) add path to <INSTALL_DIR>\Lib\Delphi and C++ Builder 2006 (2007)
to Environment Options\C++ Options\Paths and Directories\Library pah.


Purchasing / Registration
-------------------------

Visit our site https://aidaim.com to purchase or register the product.


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
  - Look at the Help files and Demos: it may already contain an answer to
    your question. A lot of people ask us something like "how do I:", 
    though the complete information is there.
  - Visit our Internet site at https://aidaim.com. It's a good chance 
    that you'll find the newer version of our product there.

If the problem persists, please, inform us about the following:

  - EasyTable version.
  - EasyTable Serial Number (if you're a registered user).
  - Where did you obtain EasyTable (http or ftp site).
  - Compiler information: Delphi or C++ Builder, Version, Edition, Service 
    Pack
  - Environmental information: your OS and Service Pack
  - Description of your problem (as much information as possible to 
    retrieve the problem).
  - Attach a test project where the problem could be reproduced (it helps 
    us to solve your issue as soon as possible)

  - EasyTable version
  - Compiler information: Delphi or C++ Builder, Version, Edition, Service 
    Pack
  - Environmental information: your OS and Service Pack
  - Description of your problem (as much information as possible to 
    retrieve the problem).
  - Attach a test project where the problem could be reproduced (it helps 
    us to solve your issue as soon as possible)

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


Other products AidAim Software recommended
-------------------------------------------

All the products in this chapter are fully compatible with EasyTable and 
recommended to work with our product. 

AidAim Software had tested all these products released by our partner 
companies for complete compatibility with EasyTable. In its turn, all the 
partner companies have carried out similar testing of the compatibility
of EasyTable with their own products. 

All the companies whose products present here are technology partners of 
AidAim Software. It means that both partner companies guarantee the 
correct joint work of the products. In case of encountering bugs in the 
time of joint work and owing to it, the partners incur the obligation to 
resolve such problems for their clients for FREE.


                         FastReport Software
                         -------------------
Advanced report generators for Delphi and Kylix.
Web Site: http://www.fast-report.com

FastReport VCL
--------------
FastReport VCL is reporting tool component for Borland Delphi 2-6 and 
Borland C++Builder 3-5. It consists of report engine, designer and 
preview. Some FastReport possibilities are really unique. The generator 
allows you to create tables, queries and databases in run-time. Built-in 
dialog designer allows you creation of dialog forms (they can be used for 
asking some parameters before printing a report). You also able to use 
built-in Pascal-like interpreter to do rather complex data processing. 
In spite of power of FastReport, its code is quite small. Probably 
FastReport is leader in correlation of functionality/size. The FastReport 
kernel (without designer) adds to your program the small footprint (less 
than QR3), but its functionality is like in ReportBuilder's one.

FastReport CLX edition
----------------------
FastReport CLX edition is powerfull of FastReport for Borland Delphi 6 and 
Borland Kylix 1-2 for Linux. It use new CLX-library. Do you want to create 
reports for Linux as well as for Windows? Use FastReport CLX edition!

FastReport VCL lite
-----------------------
FreeWare version of FastReport.


	                      9Rays.Net
                              ---------
9Rays.Net - Flexible and powerful Delphi/C++ Builder/ActiveX trees, 
grids and editors.
Web Site: http://www.9rays.net

DBFlyTreeView Suite
-------------------
Add grid and treeview functionality with a single component. DBFlyTreeView 
is a fully customizable, data-bound grid and tree view component that 
allows you to add huge arrays of nodes. OLE drag-and-drop is supported and 
the component is customizable at both design-time and runtime. 
DBFlyTreeView supports custom colors, fonts, and alignment for each cell, 
and you can even create scrollable background wallpapers without creating 
huge bitmaps.
Included: RapidTree, FlyTreeView, PropertiesTree, DBFlyTreeView controls.

DBFlyTreeViewPro Suite
----------------------
Enable your Delphi and C++Builder applications to display and browse 
hierarchical, table, and list data. DBFlyTreeViewPro Suite is a set of VCL 
components that are a direct descendent from FlyTreeViewPro. It supports 
more than 40 types of in place editors plus your custom format. It is 
data-aware and allows you to draw any array of cells directly to a 
printer, Metafile, or Bitmap canvas.
Included: RapidTree, IsPlugeditor, FlyTreeViewPro, PropertiesTreePro, 
DBFlyTreeViewPro controls.
