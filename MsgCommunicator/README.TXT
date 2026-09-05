
MsgCommunicator for Delphi / C++ Builder: README
================================================

Please read this file carefully (especially the INSTALLATION chapter) 
before installing the program to your computer.


Contents
--------

  Program information
  Company information
  Description
  Package Contents 
  Specification
  Features and Benefits
  Installation
  Purchasing / Registration
  Copyright and licenses
  Warranty and guarantee
  Technical support


Program information
-------------------

Program Name:
  MsgCommunicator
License Types:
  Trial      (for evaluation only, without source code)
  Std        (for 1 developer, without source code)
  Pro        (for 1 developer, with source code)
  Team4      (for 4 developers, with source code)
  Team8      (for 8 developers, with source code)
  Enterprise (Enterprise License - for entire company, with source code)
Program Version:
  22.00
Program Release Date:
  10/21/2025
Program Purpose:
  MsgCommunicator is a Delphi / C++Builder SDK for the easy creation of 
  custom client/server instant messaging (IM) applications with 
  data compression, strong encryption and advanced networking technologies.
Target Environment:
  Delphi 4, 5, 6, 7, Delphi 2005, Delphi 2006, Delphi 2007 for Win32, Delphi 2009, Delphi 2010, XE, XE2, XE3, XE4, XE5, XE6, XE7, XE8, 10, 10.1, 10.2, 10.3, 10.4, 11, 11.1, 11.2, 11.3, 12.0, 12.1, 12.2, 12.3, 13 and 
  C++ Builder 4, 5, 6, C++ Builder 2006, C++ Builder 2007, C++ Builder 2009, C++ Builder 2010, XE, XE2, XE3, XE4, XE5, XE6, XE7, XE8, 10, 10.1, 10.2, 10.3, 10.4, 11, 11.1, 11.2, 11.3, 12.0, 12.1, 12.2, 12.3, 13 for Win 32 bit.


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

MsgCommunicator is a native Delphi / C++Builder software development kit 
which was specially designed for the easy creation of custom internet/intranet 
messenger systems like Mirabilis ICQ, AOL Instant Messenger (AIM), Jabber, etc. 
with data compression and strong encryption as well as with other advanced 
networking technologies.

MsgCommunicator includes methods, properties and events to exchange custom messages 
of different types like String, Stream and binary buffer with data compression and 
encryption capabilities.

But MsgCommunicator is not just the build-in OS API messages functions replacement 
with advanced compression, encryption, and network functionality; it provides 
methods and properties to work with other objects like Users Contact List, 
User Info, Users database at server, as well as User Goes On-line / Off-Line events 
and other functionality you need to build messenger.

MsgCommunicator allows sending/receiving very large objects with progress indicator 
support. Any number of files/streams can be sent/received simultaneously. 
Transmitting of files and streams takes no effect on the other command/message data 
exchange. These objects can be sent directly or thru server despite of their sizes 
which can be very large. MsgCommunicator enables you to customize network data 
transmission process for each file/stream independently.

MsgCommunicator is successfully tested with 100,000 simultaneous connections and 
high load messaging. Each server can theoretically handle up to 2^31 (over 2 
billions) concurrent connections on the single machine (really limited by 
hardware). MsgCommunicator is a ready solution for building corporative or public 
internet servers.


Package Contents 
----------------

MsgCommunicator contains MsgClient and MsgServer visual components, Reference Guide, 
client and server demo, License Agreement in License.txt file, History Of Changes 
in History.txt file and general information in ReadMe.txt file.


Specification
-------------

MsgCommunicator enables you to build custom messenger system as easily as it is 
possible: just place MsgClient component on the form, specify connection parameters 
(IP address and port of the server at least) and now you can send messages 
to any other client despite of is it on-line or not.

The MsgServer component allows you to build your own messages server 
to work at your internet server or in your private intranet.

Key features:

  - Client and Server visual components
  - Flexible custom messages: String, Stream and binary buffer
  - Messenger functionality to work with ContactList, UserInfo, Users Database, etc.
  - Wide variety of Client and Server events
  - 2 independent network channels for parallel work with commands and messages 
  - Strong encryption of network traffic: 12 algorithms with 4 modes and 2 different schemes
  - Network data compression: 3 algorithms with 9 modes for each
  - Native VCL, does not require any DLLs
  - Client and server demo, Reference Guide
  - Royalty free, unlimited number of connections
  - Full source code available

 
Features and Benefits
---------------------

Advanced Functionality

  - MsgServer component allows you to develop your own messages server to work at your internet server or in your private intranet.
  - MsgClient component enables you to build messenger client as easily as it is possible: just place on the form, specify connection parameters (IP address and port of the server at least) and now you can send messages to any other client despite of is it on-line or not.
  - MsgCommunicator includes methods, properties and events to exchange custom messages of different types like String, Stream and binary buffer.
  - MsgCommunicator provides advanced messenger functionality to work with ContactList, UserInfo, Users Database, etc.
  - Wide variety of Client and Server events, such as Before/After-Connect/Disconnect/ServerShutDown, OnUser-OnLine/OffLine; Before/After-ServerStart/ServerStop, etc., provides you full control of the work of Client or Server components and enables you to add new features easily.
  - Two independent network channels for parallel work with commands and messages. You have no needs to wait for finishing command/answer exchange between client and server if you need to send message. MsgCommunicator sends and receives commands and answers independently of messages to prevent temporary blocking of sending and receiving of messages.
  - Network data compression: 3 algorithms (ZLib, BZip, PPM) with 3 x 9 = 27 compression modes total. You can easily speed up network messages exchange by reducing the size of data needed to send. MsgCommunicator compresses/decompresses data on the fly. The compression routines used in the MsgCommunicator are much faster than most of popular archivers like WinZip, WinRar, etc. 

Security

  - MsgCommunicator provides encryption of the network traffic using strong encryption algorithms. 
    You can use one of the best existing symmetric block ciphers 
    tested by the best cryptography experts to achieve 
    so fast speed and strong encryption as you need. 
  - Wide choice of encryption algotithms:
    - Rijndael, the Advanced Encryption Standard (AES) winner, 128 bit key 
    - Rijndael, 256 bit key 
    - Blowfish, 448 bit key 
    - Twofish, 128 bit key 
    - Twofish, 256 bit key 
    - Square 
    - Single DES  8 byte Blocksize,  8 byte Keysize  56 bits relevant 
    - Double DES  8 byte Blocksize, 16 byte Keysize 112 bits relevant 
    - Double DES 16 byte Blocksize, 16 byte Keysize 112 bits relevant 
    - Triple DES  8 byte Blocksize, 24 byte Keysize 168 bits relevant 
    - Triple DES 16 byte Blocksize, 24 byte Keysize 168 bits relevant 
    - Triple DES 24 byte Blocksize, 24 byte Keysize 168 bits relevant 
  - Four different encryption modes: CTS, CBC, CFB, OFB.
  - Two different encryption schemes. 
    You can use a password as well as an encryption key itself to protect your database.
  
  MsgCommunicator has the best encryption functionality among all known messenger systems.

Convenience

  - MsgCommunicator is specially designed for the easy development of custom client/server instant messaging (IM) systems like Mirabilis ICQ, AOL Instant Messenger (AIM), Jabber, etc. 
  - Client and Server visual components for fast and easy development.
  - Flexible custom message exchange functionality. SendMessage methods with different modes (String, Stream and binary buffer) and OnMessageReceived events for appropriate modes.
  - Messenger functionality to work with ContactList, UserInfo, Users Database etc. enable you to build your messenger easily and quickly. You have no needs to think on how to store client and server data because all necessary features are already released in Client and Server components.
  - Wide variety of Client and Server events: Before/After-Connect/Disconnect/ServerShutDown, OnUser-OnLine/OffLine; Before/After-ServerStart/ServerStop, etc. allows you to easily implement special functionality you need.
  - Server configuration file  to store server settings. When you start server for the first time, server settings are saved in .ini file and will be used under next server start. You can save and load settings at any time as well as freely edit configuration file by any text editor.
  - Native VCL, does not require any DLLs.
  - Full source code available to help you understand used technologies and give you possibility to change functionality or even to implement your original features.
  - Client and server demo with full source code allows you to easily start your development. 
  - All necessary documentation in Reference Guide.

Cost Effectiveness

  - Full messenger functionality in one SDK.
  - Build-in network traffic compression and encryption capabilities.
  - Full source code helps you to accelerate your development and to avoid superfluous outlay.
  - All commercial licenses are royalty free. You may develop any number of applications using this product without additional fees. 
  - Unlimited number of connections. Despite of other analogous products you can build your messenger system for any number of users without additional payments for user licenses.


Installation
------------

1) Make sure that all copies of Delphi (or C++ Builder) are currently 
   closed and not running on the target system. Also, if you are 
   replacing an existing version of MsgCommunicator, please remove all files 
   and the package of the prior version before running the new setup program.

2) Unpack zip archive containing MsgCommunicator into any directory. 

3) Run the INSTALL.EXE from this directory.

4) Follow on-screen instructions of step-by-step setup wizard to install 
   MsgCommunicator.

5) If after the installation MsgCommunicator components
   don't appear in Components Palette of the IDE, please follow the next
   instructions:

  * From the IDE, select 'Component | Install Packages...'.
  * Click the 'Add' button.
  * In the ..\MsgCommunicator\Lib\Delphi# (or ..\MsgCommunicator\Lib\C++ Builder#) directory,
    select the dclMsgComD#.BPL (or dclMsgComB#.BPL) file.
  * Click the 'OK' button to close the dialog. 
  * Finally, select 'Tools | Environment Options' from the main menu. From this dialog,
    select the 'Library' tab and insure that the
    ..\MsgCommunicator\Lib\Delphi# (or ..\MsgCommunicator\Lib\C++ Builder#) directory is
    included in the 'Library Path' line.

6) If you use C++ Builder 2006 add path to <INSTALL_DIR>\Lib\Delphi 2006 to
Environment Options - C++ Options - Paths and Directories - Search path
(that is 'Library path' in Delphi IDE configuration).


Purchasing / Registration
-------------------------

Visit our site https://aidaim.com to purchase the product.



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

  - MsgCommunicator version.
  - Where did you obtain MsgCommunicator (http or ftp site).
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
