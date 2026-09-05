// This product requires the following products to be installed:
// - MsgCommunicator by AidAim Software, www.aidaim.com
// - DAC for mySQL by MicroOLAP Technologies LTD, www.microolap.com

// If you need to access server message history from client you should download
// SQLMemTable temporary table component and SQLMemTable itself from our web site:
// http://www.aidaim.com/products/download.php#MSG
// http://www.aidaim.com/products/download.php#sqlmemtable

{$WARNINGS OFF}
{$HINTS OFF}

unit MsgDatabaseMySQLDAC;

interface


{$I MsgDBmysqlDACVer.inc}

uses

{$IFDEF MSWINDOWS}
Windows,
{$ENDIF}
{$IFDEF LINUX}
Libc,
{$ENDIF}

Classes,SysUtils,

Db,
MsgDatabase,
mySQLDbTables,
mySQLDirectQuery,

{$IFDEF DEBUG_LOG}
MsgDebug,
{$ENDIF}

MsgCompression,
MsgExcept,
MsgComBase,
MsgConst,
MsgCrypto,
MsgTypes
;

 const MsgModuleVersion = 1.40;
 const MsgModuleVersionText = '';

// SQL script for creating all tables on server side (SQL syntax of MySQL)
// on client only MsgMessages table needed for storing local message history
{
DROP TABLE MsgUsers CASCADE;
CREATE TABLE `msgusers` (
  `ID` int(11) NOT NULL default '0',
  `UserName` varAnsiChar(255) default NULL,
  `FirstName` varAnsiChar(255) default NULL,
  `LastName` varAnsiChar(255) default NULL,
  `Organization` varAnsiChar(255) default NULL,
  `Department` varAnsiChar(255) default NULL,
  `Status` tinyint(3) unsigned default NULL,
  `LogonTime` datetime default NULL,
  `LogoffTime` datetime default NULL,
  `Host` varAnsiChar(255) default NULL,
  `Port` int(11) default NULL,
  `Application` varAnsiChar(255) default NULL,
  `CryptoHeader` blob,
  PRIMARY KEY  (`ID`),
  KEY `UserNameIndex` (`UserName`),
  KEY `FirstNameIndex` (`FirstName`),
  KEY `LastNameIndex` (`LastName`),
  KEY `OrganizationIndex` (`Organization`),
  KEY `DepartmentIndex` (`Department`),
  KEY `HostIndex` (`Host`),
  KEY `PortIndex` (`Port`),
  KEY `ApplicationIndex` (`Application`),
  KEY `StatusIndex` (`Status`)
) TYPE=MyISAM

DROP TABLE MsgContacts CASCADE;
CREATE TABLE `msgcontacts` (
  `OwnerID` int(11) NOT NULL default '0',
  `ContactID` int(11) NOT NULL default '0',
  `ContactNameSource` tinyint(3) unsigned default NULL,
  `ContactCustomName` varAnsiChar(255) default NULL,
  PRIMARY KEY  (`OwnerID`,`ContactID`),
  KEY `ContactIDIndex` (`ContactID`)
) TYPE=MyISAM;


DROP TABLE MsgMessages CASCADE;
CREATE TABLE `msgmessages` (
  `ID` int(11) NOT NULL auto_increment,
  `SenderID` int(11) default NULL,
  `RecipientID` int(11) default NULL,
  `Delivered` tinyint(3) unsigned default NULL,
  `DeliveryDate` datetime default NULL,
  `SendingDate` datetime default NULL,
  `MessageType` tinyint(3) unsigned default NULL,
  `Command` int(11) default NULL,
  `MessageDataSize` int(11) default NULL,
  `MessageData` longblob,
  `MessageText` longtext,
  PRIMARY KEY  (`ID`)
) TYPE=MyISAM
}

type


////////////////////////////////////////////////////////////////////////////////
//
// TMsgDatabaseMySQLDAC
//
////////////////////////////////////////////////////////////////////////////////

 TMsgDatabaseMySQLDAC = class (TMsgDatabase)
  private
   FDatabase:       TmySQLDatabase;
   FDelay:          Integer;
   FRetryCount:     Integer;
   FTableType:      AnsiString;
  protected
   function GetMainVersion: AnsiString; override;
   function GetModuleVersion: AnsiString; override;
   procedure SetDatabase(Value: TmySQLDatabase);
   function GetTablesExists(HistoryOnly: Boolean): Boolean; override;
   procedure CreateTables(HistoryOnly: Boolean); override;
   procedure OpenDatabase; override;
   function GetInsertUserSQL(Params: TParams; UserInfo: TMsgUserInfo; PasswordHeader: TMsgCryptoHeader): AnsiString;
   function GetUpdateUserSQL(Params: TParams; UserInfo: TMsgUserInfo; ChangePassword: Boolean; PasswordHeader: TMsgCryptoHeader): AnsiString;
   function ExtractUserInfo(Query: TmySQLDirectQuery): TMsgUserInfo;
   function CreateSessionDatabase: TmySQLDatabase;
  public
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   procedure CloseDatabase; override;
   procedure AddUser(UserInfo: TMsgUserInfo; PasswordHeader: TMsgCryptoHeader); override;
   procedure RemoveUser(const UserID: Cardinal); override;
   procedure ChangeUserInfo(UserInfo: TMsgUserInfo; ChangePassword: Boolean; PasswordHeader: TMsgCryptoHeader); override;
   procedure ChangeUserStatus(
                               const AllUsers:    Boolean;
                               const UserID:      Cardinal;
                               const Status:      TMsgUserStatus;
                               const Host:        AnsiString = '';
                               const Port:        Integer = 0;
                               const Application: AnsiString = ''
                             ); override;
   procedure GetLastLogged(
                              const UserID:     Cardinal;
                              out   LogonTime:  TDateTime;
                              out   LogoffTime: TDateTime
                          ); override;
   function GetUserInfo(const UserID: Cardinal): TMsgUserInfo; override;
   function GetUsersCount: Integer; override;
   function GetPasswordHeader(const UserID: Cardinal): TMsgCryptoHeader; override;
   function UserExists(const UserID: Cardinal): Boolean; override;
   procedure GetUsers(var Users: TMsgUserInfoArray; const SortBy: TMsgUserInfoArraySortBy; const Ascending: Boolean); override;
   procedure FindUsers(
                    var Users:                    TMsgUserInfoArray;
                    var UserNameComparison:       TMsgTextComparison;
                    var FirstNameComparison:      TMsgTextComparison;
                    var LastNameComparison:       TMsgTextComparison;
                    var OrganizationComparison:   TMsgTextComparison;
                    var DepartmentComparison:     TMsgTextComparison;
                    var ApplicationComparison:    TMsgTextComparison;
                    var HostComparison:           TMsgTextComparison;
                    var PortComparison:           TMsgIntegerComparison;
                    Status:                       TMsgUserStatus = msgNone;
                    UserID:                       Cardinal = MSG_INVALID_USER_ID;
                    UserName:                     ShortString = '';
                    FirstName:                    ShortString = '';
                    LastName:                     ShortString = '';
                    Organization:                 ShortString = '';
                    Department:                   ShortString = '';
                    Host:                         ShortString = '';
                    Application:                  ShortString = '';
                    SearchCondition:              AnsiString = ''; // SQL WHERE clause without word WHERE
                    // ORDER BY columns without ORDER BY words
                    // example: SenderID DESC, SendingDate ASC
                    SortBy:                       TMsgUserInfoArraySortBy = msgusbNone;
                    Ascending:                    Boolean = True;
                    OrderByClause:                AnsiString = ''
                       ); override;
   // search for UserID by the UserName
   function FindUserID(const UserName: AnsiString): Cardinal; override;
   procedure GetUserContacts(const UserID: Cardinal; var Contacts: TMsgContactInfoArray); override;
   function GetUserContactCount(UserID: Cardinal): Integer; override;
   // return true if UserID is in contact list of OwnerUserID
   function IsUserInContacts(UserID,OwnerUserID: Cardinal): Boolean; override;
   procedure AddUserToContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                              ); override;
   procedure UpdateUserInContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                              ); override;
   procedure RemoveUserFromContacts(const OwnerUserID: Cardinal; const ContactUserID: Cardinal); override;
   // saves message to database and returns MessageID
   function SaveMessage(
                         const Delivered:           Boolean; // for commands
                         const DeliveryDate:        TDateTime;
                         const SenderID,
                               RecipientID:         Cardinal;
                         const MessageType:         TMsgMessageType;
                         const SendingDate:         TDateTime;
                         const MessageData:         PAnsiChar; // binary o stream message data
                         const MessageDataSize:     Integer; // size of MessageData
                         const MessageText:         AnsiString; // text of the message
                         const MessageUnicodeText:  WideString; // unicode text of the message
                         const Command:             Cardinal = 0 // no command
                        ): Integer; override;
   procedure SetMessageDeliveryDate(MessageID: Integer); override;
   procedure DeleteMessage(MessageID: Integer); override;
   // return new query object with found messages from MsgMessages table
   function FindMessages(
                         const MessageTextComparison:         TMsgTextComparison;
                         const MessageUnicodeTextComparison:  TMsgTextComparison;
                         const SendingDate:                   TMsgDateComparison;
                         const DeliveryDate:                  TMsgDateComparison;
                         const SearchDelivered:               Boolean;
                         const Delivered:                     Boolean = True;
                         const MessageText:                   AnsiString = ''; // text of the message
                         const MessageUnicodeText:            WideString = ''; // unicode text of the message
                         const SenderID:                      Cardinal = MSG_INVALID_USER_ID;
                         const RecipientID:                   Cardinal = MSG_INVALID_USER_ID;
                         const MessageType:                   TMsgMessageType = aamtNone;
                         const MessageDataSize:               Integer = -1; // size of MessageData
                         const OrderBySendingDate:            Boolean = False;
                         const OrderByClause:                 AnsiString = '';
                         const Command:                       Cardinal = 0 // no command
                        ): TDataset; override;
  published
   property Database: TmySQLDatabase read FDatabase write SetDatabase;
   property Delay: Integer read FDelay write FDelay;
   property RetryCount: Integer read FRetryCount write FRetryCount;
   property TableType: AnsiString read FTableType write FTableType;
 end; // TMsgDatabaseMySQLDAC


 // convert dt to AnsiString constant using time stamp MM/DD/YYYY HH24:NN:SS
 function ConvertDateTimeTOString(dt: TDateTime): AnsiString;
 procedure FixTableNames(sl: TStringList);

{$IFDEF TRIAL_VERSION}

 function msgtrcapt1: AnsiString;
 function msgtrnm1: AnsiString;

 function msgtrcapt: AnsiString;
 function msgtrnm: AnsiString;
 function msgtrgetencmsg(msg: AnsiString): AnsiString;
 function msgtrgetdecmsg(msg: AnsiString): AnsiString;
 procedure msgtrshnm;
{$ENDIF}

implementation

{$IFDEF TRIAL_VERSION}
     uses
     {$IFDEF D6H}
     DateUtils,
     {$ENDIF}
     {$IFDEF MSWINDOWS}
     Registry,
     {$ENDIF}
     MsgDECUtil, MsgCipher;
{$ELSE}
     {$IFDEF D6H}
      uses DateUtils;
     {$ENDIF}
{$ENDIF}


{$IFNDEF D6H}
procedure DecodeDateTime(const AValue: TDateTime; out AYear, AMonth, ADay,
  AHour, AMinute, ASecond, AMilliSecond: Word);
begin
  DecodeDate(AValue, AYear, AMonth, ADay);
  DecodeTime(AValue, AHour, AMinute, ASecond, AMilliSecond);
end;
{$ENDIF}


{$IFDEF TRIAL_VERSION}

function msgtrcapt1: AnsiString;
begin
// Result := 'MsgCommunicator DAC for mySQL Database Module Trial Version - ';
end;

function msgtrnm1: AnsiString;
begin
{
  Result :=
             'This is the trial version of MsgCommunicator DAC for mySQL Database Module by'#13+
             'AidAim Software (c) 2000-2010.'#13+
             'Web site: http://www.aidaim.com'#13#13+

						 'This screen is created to remind you that your trial version is'#13+
             'provided to you for evaluation purposes only.'#13+
             'If you don''t want to see this screen any more, or if you intend'#13+
             'to create a commercial product, please, register and download'#13+
             'the appropriate version of this product at http://www.aidaim.com'#13+
             'Also visit our site for all the new versions of our products.'#13#13+
             'Should you have any questions or problems with our product,'#13+
             'be sure to contact us at support@aidaim.com';
}
end;

function msgtrcapt: AnsiString;
begin
 Result := 'BEDAEC896E0AB355805CD85A1A801CF75E908C0E2E560849642A339557E437E265F087C206A9EFC30A8A331E439370DA0E39D3771899A4E22FD2DB9A6560';
end;

function msgtrnm: AnsiString;
begin
  Result :=
             '85342E20DE20E32E63B4D63D05BD5E020874B2B2E2B760F71FBF3643793892A888AEBAF9BA2EB69FF81AFA46FD3A72019C1DCA61BEBD93DAF8FD4B92BE620C28D8E7BFA5C22F92A5188F55DCD3895139D1'
            +'038098C8D4ADFAE7D187BD493EEC245D7A8A831ADDD703B8A265B4F2DFD79EF8AF301D51F50993FDEEA2FE71C9E0E0BFE3CCC6C0A499975646D776F4FE19ABEBC01A1C5E610F4859F7B8CE9A398FC0979C'
            +'7ABEB821FC861C4A4A1746D48027FB6DEF148792189DFD346EAA9AF6DE109C4DB7D75017B332BDD411D614E3E6BDD6C9FD9A03FC7411DC85B14E433A708600CFFF4302617F384F4C0BFBA164F9A28CE4AD'
            +'B5FB8437F9579EBDA237F3A2A91E5FDFD770AAFF214FC3E47265CE80833DA597315406B4057A01D4B3084561EABFBF33A749B23EBFE90C5B5123D02BE59E5F3367ACC8B587216CF3B34235CCAC816A9BBB'
            +'564B27E0B43A9B88269D20838669C4B3859AD3B00720F2A659C3F717DA87296E487767019F4D3141C2F00746F0EC68AC03E1B6EF5831AC8DEB4D77EB24E74E1D57C924ECBA61F8ABD95343AA16AF2F2A0E'
            +'0D6536427247674FD7A92E29BDAC563ABA1484E60BFE0105BF174E481AD81E1C18D54557E622136AC05D60387DF6F28E0129990A16ACD49DB9CAD54F13346B4E7A14820808CAF8468F57EC8D6DB8B4F032'
            +'2C1CA40F001BBC60041606C647FE6176DDDE2574700354D4262869C9238FAB85217B78DC2DABC07607000F81E8C6CFD5DC2FF55AD8102A2F3AF48E0341E2A23EDFADCD2D9A9770DB12B72EED06B5520B31'
            +'7AD32EA97D38ED1977B5AC4F3FFAAEC71DBEBA88FFDF334F1B2B48E62216CD836168CC64C33E2E863F86'
           ;
end;

function msgtrgetencmsg(msg: AnsiString): AnsiString;
var cr: TCipher_Blowfish;
    s: AnsiString;
begin
 cr := TCipher_Blowfish.Create(MsgDefaultPassword,nil);
 s := cr.EncodeString(msg);
 cr.Free;
 Result := StrToFormat(PAnsiChar(@s[1]),Length(s),fmtHEX);
end;

function msgtrgetdecmsg(msg: AnsiString): AnsiString;
var cr: TCipher_Blowfish;
    s: AnsiString;
begin
 s := FormatToStr(PAnsiChar(@msg[1]),Length(msg),fmtHEX);
 cr := TCipher_Blowfish.Create(MsgDefaultPassword,nil);
 Result := cr.DecodeString(s);
 cr.Free;
end;

function msgtrgnm: AnsiString;
begin
 Result := msgtrgetdecmsg(msgtrnm);
end;

function msgtrgcapt: AnsiString;
var ds: Char;
    vStr: AnsiString;
begin
  ds := DecimalSeparator;
  try
    DecimalSeparator := '.';
    vStr := 'v.'+FormatFloat('0.00',MsgModuleVersion) + ' '+ MsgModuleVersionText;
  finally
    DecimalSeparator := ds;
  end;
  Result := msgtrgetdecmsg(msgtrcapt) + vStr;
end;

procedure msgtrshnm;
begin
{$IFDEF TRIAL_VERSION_WITHOUT_NAG_SCREEN}
 Exit;
{$ENDIF}
 MessageBoxA(0,PAnsiChar(msgtrgnm),PAnsiChar(msgtrgcapt),
{$IFDEF MSWINDOWS}
		 MB_OK+MB_ICONINFORMATION+MB_DEFBUTTON1
{$ENDIF}
{$IFDEF LINUX}
     [smbOK], smsInformation
{$ENDIF}
);
end;

{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
// TMsgDatabaseMySQLDAC
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return Version of the MsgCommunicator
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.GetMainVersion: AnsiString;
var c: Char;
begin
 c := DecimalSeparator;
 try
   DecimalSeparator := '.';
   Result := FloatToStrF(MsgVersion,ffFixed,3,2) + ' ' + MsgVersionText;
 finally
   DecimalSeparator := c;
 end;
end; // GetMainVersion


//------------------------------------------------------------------------------
// return Version of this module
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.GetModuleVersion: AnsiString;
var c : Char;
begin
 c := DecimalSeparator;
 try
   DecimalSeparator := '.';
   Result := FloatToStrF(MsgModuleVersion,ffFixed,3,2) + ' ' + MsgModuleVersionText;
 finally
   DecimalSeparator := c;
 end;
end; // GetModuleVersion


//------------------------------------------------------------------------------
// Set Database
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.SetDatabase(Value: TMySQLDatabase);
begin
  FDatabase := Value;
end; // SetDatabase


//------------------------------------------------------------------------------
// Return true if all tables exists
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.GetTablesExists(HistoryOnly: Boolean): Boolean;
var sl: TStringList;
begin
  sl := TStringList.Create;
  try
   if (FDatabase <> nil) then
    FDatabase.GetTableNames('',sl);
   FixTableNames(sl);
   Result := (sl.IndexOf(MessagesTableName) >= 0);
   if (Result and (not HistoryOnly)) then
     begin
      Result := (sl.IndexOf(UsersTableName) >= 0);
      if (Result) then
        Result := (sl.IndexOf(ContactsTableName) >= 0);
     end;
  finally
    sl.Free;
  end;
end; // GetTablesExists


//------------------------------------------------------------------------------
// Create Tables
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.CreateTables(HistoryOnly: Boolean);
var s:              AnsiString;
    sl:             TStringList;
begin
 if (FDatabase = nil) then
   raise EMsgException.Create(11584,ErrorLMySQLDatabaseIsNotAssigned);
 sl := TStringList.Create;
 try
   FDatabase.GetTableNames('',sl);
   FixTableNames(sl);
   if (not HistoryOnly) then
    begin
     if ((sl.IndexOf(UsersTableName) >= 0)) then
       FDatabase.Execute('DROP TABLE '+UsersTableName+crlf,nil,false);
     s := 'CREATE TABLE '+UsersTableName + ' ('+crlf+
          // User unique ID
          'ID Integer NOT NULL, '+ crlf+
          'UserName Char(255),'+crlf+
          'FirstName Char(255),'+crlf+
          'LastName Char(255),'+crlf+
          'Organization Char(255),'+crlf+
          'Department Char(255),'+crlf+
          'Status TinyInt Unsigned,'+crlf+
          'LogonTime DateTime,'+crlf+
          'LogoffTime DateTime,'+crlf+
          'Host Char(255),'+crlf+
          'Port Integer,'+crlf+
          'Application Char(255),'+crlf+
          'CryptoHeader BLOB,'+crlf+
          'PRIMARY KEY UsersPK (ID)'+ crlf+
          ') Type='+FTableType+crlf;
     FDatabase.Execute(s,nil,false);
     FDatabase.Execute('CREATE INDEX UserNameIndex ON '+UsersTableName+' (UserName)',nil,false);
     FDatabase.Execute('CREATE INDEX FirstNameIndex ON '+UsersTableName+' (FirstName)',nil,false);
     FDatabase.Execute('CREATE INDEX LastNameIndex ON '+UsersTableName+' (LastName)',nil,false);
     FDatabase.Execute('CREATE INDEX OrganizationIndex ON '+UsersTableName+' (Organization)',nil,false);
     FDatabase.Execute('CREATE INDEX DepartmentIndex ON '+UsersTableName+' (Department)',nil,false);
     FDatabase.Execute('CREATE INDEX HostIndex ON '+UsersTableName+' (Host)',nil,false);
     FDatabase.Execute('CREATE INDEX PortIndex ON '+UsersTableName+' (Port)',nil,false);
     FDatabase.Execute('CREATE INDEX ApplicationIndex ON '+UsersTableName+' (Application)',nil,false);
     FDatabase.Execute('CREATE INDEX StatusIndex ON '+UsersTableName+' (Status)',nil,false);

     if ((sl.IndexOf(ContactsTableName) >= 0)) then
       FDatabase.Execute('DROP TABLE '+ContactsTableName,nil,false);
     s := 'CREATE TABLE '+ContactsTableName + ' ('+crlf+
          // id in Users of the contact list owner
          'OwnerID Integer NOT NULL,'+crlf+
          // id in Users of the person in contact list
          'ContactID Integer NOT NULL,'+crlf+
          // source of the name: UserName, FirstName, LastName, FirstName LastName, Custom,  etc.
          'ContactNameSource TinyInt Unsigned,'+crlf+
          // contact custom name
          'ContactCustomName VarChar(255),'+crlf+
          'PRIMARY KEY ContactsPK (OwnerID,ContactID)'+ crlf+
          ')'+crlf;
     FDatabase.Execute(s,nil,false);
     FDatabase.Execute('CREATE INDEX ContactIDIndex ON '+ContactsTableName+' (ContactID)',nil,false)
    end; // not history only
   // messages table
   if ((sl.IndexOf(MessagesTableName) >= 0)) then
     FDatabase.Execute('DROP TABLE '+MessagesTableName,nil,false);
   s := 'CREATE TABLE '+MessagesTableName + ' ('+ crlf+
        // Message unique ID
        'ID Integer AUTO_INCREMENT NOT NULL, '+ crlf+
        // Sender UserID
        'SenderID Integer, '+ crlf+
        // Recipient UserID
        'RecipientID Integer, '+ crlf+
        // Delivered or no
        'Delivered TinyInt Unsigned, '+ crlf+
        // Delivery date
        'DeliveryDate DateTime,'+ crlf+
        // Date of sending
        'SendingDate DateTime,'+ crlf+
        // message type: binary, stream, text, command
        'MessageType TinyInt Unsigned,'+ crlf+
        // if sent by SendCommand
        'Command Integer,'+ crlf+
        // size of data
        'MessageDataSize Integer,'+ crlf+
        // message data if not text message
        'MessageData LONGBLOB,'+ crlf+
        // for text messages or for custom translation of binary messages
        'MessageText LONGTEXT,'+ crlf+
        // for text messages or for custom translation of binary messages
//        'MessageUnicodeText WideMemo '+MemoBlobParams+','+ crlf+
        'PRIMARY KEY MessagesPK (ID)'+ crlf+
         ')'+crlf;
     FDatabase.Execute(s,nil,false);
     FDatabase.Execute('ALTER TABLE '+MessagesTableName+' ADD INDEX SenderIDIndex (SenderID)',nil,false);
     FDatabase.Execute('ALTER TABLE '+MessagesTableName+' ADD INDEX RecipientIDIndex (RecipientID)',nil,false);
  finally
    sl.Free;
  end;
//  'CREATE FULLTEXT INDEX MessageTextIndex ON '+ContactsTableName+' (MessageText)'+crlf;
end; // CreateTables


//------------------------------------------------------------------------------
// OpenDatabase
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.OpenDatabase;
var
    s:     AnsiString;
    Query: TmySQLDirectQuery;
begin
  FCloseDB := False;
  if (FDatabase = nil) then
   raise EMsgException.Create(11585,ErrorLMySQLDatabaseIsNotAssigned);
 if (FDatabase <> nil) then
  if (not FDatabase.Connected) then
    begin
     FDatabase.Open;
     FCloseDB := True;
    end;
  if (GetTablesExists(false)) then
   begin
    Query := TmySQLDirectQuery.Create(nil);
    try
      Query.Database := FDatabase;
      Query.SQL.Text := 'SHOW CREATE TABLE '+UsersTableName;
      Query.Open;
      if (not Query.Eof) then
       begin
        s := LowerCase(Query.FieldValues[1]);
        if (s <> '') then
         if (Pos('logontime',s) = 0) then
          FDatabase.Execute('ALTER TABLE '+UsersTableName+
                        ' ADD (LogonTime DateTime, LogoffTime DateTime)',nil,false);
       end;
      Query.Close;
      Query.SQL.Text := 'SHOW CREATE TABLE '+MessagesTableName;
      Query.Open;
      if (not Query.Eof) then
       begin
        s := LowerCase(Query.FieldValues[1]);
        if (Pos('senderidindex',s) = 0) then
         begin
          FDatabase.Execute('ALTER TABLE '+MessagesTableName+' ADD INDEX SenderIDIndex (SenderID)',nil,false);
          FDatabase.Execute('ALTER TABLE '+MessagesTableName+' ADD INDEX RecipientIDIndex (RecipientID)',nil,false);
         end;
       end;
    finally
      Query.free;
    end;
   end;
end; // OpenDatabase


//------------------------------------------------------------------------------
// Create SQL script for adding user
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.GetInsertUserSQL(
                  Params:         TParams;
                  UserInfo:       TMsgUserInfo;
                  PasswordHeader: TMsgCryptoHeader
                                              ): AnsiString;
var Param: TParam;
begin
 Result := 'INSERT INTO '+UsersTableName+
           ' (ID,UserName,FirstName,LastName,Organization,Department,'+
           'Status,CryptoHeader) '+
           ' VALUES ('+crlf+
           IntToStr(Integer(UserInfo.UserID))+','+crlf+
           AnsiQuotedStr(UserInfo.UserName,'''')+','+crlf+
           AnsiQuotedStr(UserInfo.FirstName,'''')+','+crlf+
           AnsiQuotedStr(UserInfo.LastName,'''')+','+crlf+
           AnsiQuotedStr(UserInfo.Organization,'''')+','+crlf+
           AnsiQuotedStr(UserInfo.Department,'''')+','+crlf+
           IntToStr(Byte(UserInfo.Status))+','+crlf+
           ':P_CryptoHeader'+crlf+
           ')';
 Param := TParam.Create(Params);
 Param.Name := 'P_CryptoHeader';
 if (PasswordHeader.CryptoAlgorithm <> Msg_Cipher_None) then
  Param.SetBlobData(@PasswordHeader,SizeOf(PasswordHeader))
 else
  begin
   Param.Clear;
   Param.DataType := ftBlob;
  end;
end; // GetInsertToUsersSQL


//------------------------------------------------------------------------------
// Create SQL script for updating user info
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.GetUpdateUserSQL(
                    Params:         TParams;
                    UserInfo:       TMsgUserInfo;
                    ChangePassword: Boolean;
                    PasswordHeader: TMsgCryptoHeader
                                              ): AnsiString;
var s: AnsiString;
    Param: TParam;
begin
 if (ChangePassword) then
  begin
   s := 'CryptoHeader = :P_CryptoHeader'+crlf;
   Param := TParam.Create(Params);
   Param.Name := 'P_CryptoHeader';
   if (PasswordHeader.CryptoAlgorithm <> Msg_Cipher_None) then
    Param.SetBlobData(@PasswordHeader,SizeOf(PasswordHeader))
   else
    begin
     Param.Clear;
     Param.DataType := ftBlob;
    end;
  end
 else
  s := '';
 Result := 'UPDATE '+UsersTableName+' SET '+crlf+
           'UserName = '+AnsiQuotedStr(UserInfo.UserName,'''')+','+crlf+
           'FirstName = '+AnsiQuotedStr(UserInfo.FirstName,'''')+','+crlf+
           'LastName = '+AnsiQuotedStr(UserInfo.LastName,'''')+','+crlf+
           'Organization = '+AnsiQuotedStr(UserInfo.Organization,'''')+','+crlf+
           'Department = '+AnsiQuotedStr(UserInfo.Department,'''')+','+crlf+
           s+
           'WHERE ID = '+IntToStr(Integer(UserInfo.UserID));
end; // GetUpdateUserSQL


//------------------------------------------------------------------------------
// return user info
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.ExtractUserInfo(Query: TmySQLDirectQuery): TMsgUserInfo;
begin
  Result.UserID := Cardinal(StrToIntDef(Query.FieldValueByFieldName('ID'),Integer(MSG_INVALID_USER_ID)));
  Result.UserName := Query.FieldValueByFieldName('UserName');
  Result.FirstName := Query.FieldValueByFieldName('FirstName');
  Result.LastName := Query.FieldValueByFieldName('LastName');
  Result.Organization := Query.FieldValueByFieldName('Organization');
  Result.Department := Query.FieldValueByFieldName('Department');
  Result.Status := TMsgUserStatus(StrToIntDef(Query.FieldValueByFieldName('Status'),0));
  Result.Host := Query.FieldValueByFieldName('Host');
  Result.Application := Query.FieldValueByFieldName('Application');
  Result.Port := StrToIntDef(Query.FieldValueByFieldName('Port'),0);
end; // ExtractUserInfo


//------------------------------------------------------------------------------
// create session database
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.CreateSessionDatabase: TmySQLDatabase;
begin
  Result := TmySQLDatabase.Create(nil);
  Result.Host := FDatabase.Host; //setting connection params
  Result.UserName := FDatabase.UserName;
  Result.UserPassword := FDatabase.UserPassword;
  Result.DatabaseName := FDatabase.DatabaseName;
  Result.Port := FDatabase.Port;
  Result.LoginPrompt := false;
end; // CreateSessionDatabase


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgDatabaseMySQLDAC.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDelay := 1;
  FRetryCount := 1000;
  FTableType := 'MyISAM';
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgDatabaseMySQLDAC.Destroy;
begin
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.CloseDatabase;
begin
  if (FCloseDB) then
   begin
    if (FDatabase <> nil) then
     FDatabase.Close;
   end;
end; // CloseDatabase


//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.AddUser(UserInfo: TMsgUserInfo; PasswordHeader: TMsgCryptoHeader);
var
    db:     TMySQLDatabase;
    params: TParams;
    bOK:    Boolean;
    cnt:    Integer;
    s:      AnsiString;
begin
  if (UserInfo.UserID = MSG_INVALID_USER_ID) then
   raise EMsgException.Create(11365,ErrorLInvalidUserID,[UserInfo.UserID]);
  if (UserExists(UserInfo.UserID)) then
   raise EMsgException.Create(11359,ErrorLUserAlreadyExists,[UserInfo.UserID]);
  db := CreateSessionDatabase;
  params := TParams.Create;
  try
    db.Open;
    s := GetInsertUserSQL(params,UserInfo,PasswordHeader);
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute(s,params,false);
       if (db.InTransaction) then
        db.Commit;
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11360,ErrorLAddUserTransactionFailed,
       [UserInfo.UserID,FRetryCount,FDelay]);
  finally
    db.Free;
    params.free;
  end;
end; // AddUser


//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.RemoveUser(const UserID: Cardinal);
var
    db:     TMySQLDatabase;
    bOK:    Boolean;
    cnt:    Integer;
begin
  if (not UserExists(UserID)) then
    raise EMsgException.Create(11361,ErrorLUserDoesNotExist,[UserID]);
  db := CreateSessionDatabase;
  try
    db.Open;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute('DELETE FROM '+UsersTableName+' WHERE ID = '+IntToStr(Integer(UserID))
                  ,nil,false);
       db.Execute('DELETE FROM '+ContactsTableName+' WHERE (OwnerID = '+IntToStr(Integer(UserID))+
                         ') OR (ContactID = '+IntToStr(Integer(UserID))+')'
                  ,nil,false);
       db.Execute('DELETE FROM '+MessagesTableName+' WHERE (SenderID = '+IntToStr(Integer(UserID))+
                         ') OR (RecipientID = '+IntToStr(Integer(UserID))+')'
                  ,nil,false);
       if (db.InTransaction) then
        db.Commit;
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11362,ErrorLRemoveUserTransactionFailed,
       [UserID,FRetryCount,FDelay]);
  finally
    db.Free;
  end;
end; // RemoveUser


//------------------------------------------------------------------------------
// change user info and optionally password
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.ChangeUserInfo(UserInfo: TMsgUserInfo; ChangePassword: Boolean; PasswordHeader: TMsgCryptoHeader);
var
    db:     TMySQLDatabase;
    params: TParams;
    bOK:    Boolean;
    cnt:    Integer;
    s:      AnsiString;
begin
  if (not UserExists(UserInfo.UserID)) then
    raise EMsgException.Create(11363,ErrorLUserDoesNotExist,[UserInfo.UserID]);
  db := CreateSessionDatabase;
  params := TParams.Create;
  try
    db.Open;
    s := GetUpdateUserSQL(params,UserInfo,ChangePassword,PasswordHeader);
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute(s,params,false);
       if (db.InTransaction) then
        db.Commit;
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11364,ErrorLChangeUserInfoTransactionFailed,
       [UserInfo.UserID,FRetryCount,FDelay]);
  finally
    db.Free;
    params.free;
  end;
end; // ChangeUserInfo


//------------------------------------------------------------------------------
// ChangeUserStatus
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.ChangeUserStatus(
                           const AllUsers:    Boolean;
                           const UserID:      Cardinal;
                           const Status:      TMsgUserStatus;
                           const Host:        AnsiString = '';
                           const Port:        Integer = 0;
                           const Application: AnsiString = ''
                          );
var
    db:       TMySQLDatabase;
    bOK:      Boolean;
    cnt,i:    Integer;
    s,w,a,h:  AnsiString;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>TMsgDatabaseMySQLDAC.ChangeUserStatus - UserID = '+IntToStr(UserID)+', Status = '+IntToStr(Byte(Status)));
{$ENDIF}
  if (not AllUsers) then
   if (not UserExists(UserID)) then
     raise EMsgException.Create(11366,ErrorLUserDoesNotExist,[UserID]);
  db := CreateSessionDatabase;
  try
    db.Open;
    if (Status = msgOffline) then
     begin
      s := crlf+', LogoffTime = NOW()'+crlf;
     end
    else
     begin
      if (Application <> '') then
       a := StringReplace(Application,'\','\\',[rfReplaceAll])
      else
       a:= '';
      if (Host <> '') then
       h := StringReplace(Host,'\','\\',[rfReplaceAll])
      else
       h:= '';
      s := ','+crlf+
          'Host = '+AnsiQuotedStr(h,'''')+','+crlf+
          'Port = '+IntToStr(Port)+','+crlf+
          'Application = '+AnsiQuotedStr(a,'''');
      if (Status = msgOnline) then
        s := s + crlf+', LogonTime = NOW()'+crlf;
{ TODO : application bug fix }
     for i := 1 to Length(s) do
      if s[i] = #0 then
       s[i] := ' ';
     end;
    if (AllUsers) then
     w := 'WHERE status <> '+IntToStr(Byte(Status))
    else
     w := 'WHERE ID = '+IntToStr(Integer(UserID));
    s := 'UPDATE '+UsersTableName+' SET '+crlf+
                      'Status = '+IntToStr(Byte(Status))+s+w;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute(s,nil,false);
       if (db.InTransaction) then
        db.Commit;
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11367,ErrorLChangeUserStatusTransactionFailed,
       [UserID,FRetryCount,FDelay]);
  finally
    db.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('<TMsgDatabaseMySQLDAC.ChangeUserStatus - UserID = '+IntToStr(UserID)+', Status = '+IntToStr(Byte(Status)));
{$ENDIF}
end; // ChangeUserStatus

{ TODO -oLeo : OPTIMIZE IT !!! }
//------------------------------------------------------------------------------
// GetLastLogged
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.GetLastLogged(
                              const UserID:     Cardinal;
                              out   LogonTime:  TDateTime;
                              out   LogoffTime: TDateTime
                          );
var
    Query: TmySQLQuery;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>TMsgDatabaseMySQLDAC.GetLastLogged - UserID = '+IntToStr(UserID));
{$ENDIF}
  Query := TmySQLQuery.Create(nil);
  try
    Query.Database := FDatabase;
    Query.RequestLive := True;
    Query.SQL.Text := 'SELECT LogonTime,LogoffTime FROM '+UsersTableName+' WHERE ID = '+IntToStr(UserID);
    Query.Open;
    Query.First;
    if (not Query.Eof) then
     begin
      LogonTime := Query.FieldByName('LogonTime').AsDateTime;
      LogoffTime := Query.FieldByName('LogoffTime').AsDateTime;
     end
    else
     raise EMsgException.Create(11616,ErrorLUserDoesNotExist,[UserID]);
  finally
    Query.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('<TMsgDatabaseMYSQL.GetLastLogged - UserID = '+IntToStr(UserID));
{$ENDIF}
end; // GetLastLogged
(*
procedure TMsgDatabaseMySQLDAC.GetLastLogged(
                              const UserID:     Cardinal;
                              out   LogonTime:  TDateTime;
                              out   LogoffTime: TDateTime
                          );
var Query: TmySQLDirectQuery;
    FormatSettings: TFormatSettings;
//    y,m,d,h,n,s: Word;
//    dt: TDateTime;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>TMsgDatabaseMySQLDAC.GetLastLogged - UserID = '+IntToStr(UserID));
{$ENDIF}
  Query := TmySQLDirectQuery.Create(nil);
  try
    Query.Database := FDatabase;
    Query.SQL.Text := 'SELECT LogonTime,LogoffTime FROM '+UsersTableName+' WHERE ID = '+IntToStr(UserID);
    Query.Open;
    if (not Query.Eof) then
     begin
      FormatSettings.DateSeparator := '-';
      FormatSettings.TimeSeparator := ':';
      FormatSettings.ShortDateFormat := 'yyyy-mm-dd';
      FormatSettings.LongDateFormat := FormatSettings.ShortDateFormat;
      FormatSettings.ShortTimeFormat := 'hh:nn:ss';
      FormatSettings.LongTimeFormat := FormatSettings.ShortTimeFormat;
      LogonTime := StrToDateTime(Query.FieldValues[0],FormatSettings);
      LogoffTime := StrToDateTime(Query.FieldValues[1],FormatSettings);
     end
    else
     raise EMsgException.Create(11616,ErrorLUserDoesNotExist,[UserID]);
  finally
    Query.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('<TMsgDatabaseMYSQL.GetLastLogged - UserID = '+IntToStr(UserID));
{$ENDIF}
end; // GetLastLogged
*)

//------------------------------------------------------------------------------
// Get user info
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.GetUserInfo(const UserID: Cardinal): TMsgUserInfo;
var Query: TmySQLDirectQuery;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>TMsgDatabaseMySQLDAC.GetUserInfo - UserID = '+IntToStr(UserID));
{$ENDIF}
  Query := TmySQLDirectQuery.Create(nil);
  try
    Query.Database := FDatabase;
    Query.SQL.Text := 'SELECT * FROM '+UsersTableName+' WHERE ID = '+IntToStr(UserID);
    Query.Open;
    if (not Query.Eof) then
     begin
      Result := ExtractUserInfo(Query);
     end
    else
     Result.UserID := MSG_INVALID_USER_ID;
  finally
    Query.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('<TMsgDatabaseMySQLDAC.GetUserInfo - UserID = '+IntToStr(UserID)+', UserInfo.UserID = '+IntToStr(Result.UserID));
{$ENDIF}
end; // GetUserInfo


//------------------------------------------------------------------------------
// return numbef of users
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.GetUsersCount: Integer;
begin
  Result := FDatabase.SelectIntegerDef('SELECT COUNT(*) FROM '+UsersTableName,0,0);
end; // GetUsersCount


//------------------------------------------------------------------------------
// Return PasswordHeader
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.GetPasswordHeader(const UserID: Cardinal): TMsgCryptoHeader;
var 
    table:  TmySQLTable;
    bs:     TStream;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>MsgDatabaseAccuracer.GetPasswordHeader - UserID = '+IntToStr(UserID));
{$ENDIF}
  table := TmySQLTable.Create(nil);
  try
    table.Database := FDatabase;
    table.TableName := UsersTableName;
    table.Open;
    table.IndexFieldNames := 'ID';
    if (table.FindKey([Integer(UserID)])) then
     begin
      if (table.FieldByName('CryptoHeader').IsNull) then
       begin
        FillChar(Result,SizeOf(Result),0);
        Result.CryptoAlgorithm := Msg_Cipher_None;
       end
      else
       begin
        bs := table.CreateBlobStream(table.FieldByName('CryptoHeader'),bmRead);
        try
          bs.ReadBuffer(Result,SizeOf(Result));
        finally
          bs.Free;
        end;
       end;
     end
    else
     raise EMsgException.Create(11401,ErrorLUserDoesNotExist,[UserID]);
  finally
    table.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('<TMsgDatabaseMySQLDAC.GetPasswordHeader - UserID = '+IntToStr(UserID)+', UserInfo.UserID = '+IntToStr(Result.UserID));
{$ENDIF}
end; // GetPasswordHeader


//------------------------------------------------------------------------------
// Return true if user exists
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.UserExists(const UserID: Cardinal): Boolean;
var
    i:    Integer;
begin
  i := FDatabase.SelectIntegerDef(
    'SELECT COUNT(*) FROM '+UsersTableName+' WHERE ID = '+IntToStr(Integer(UserID)),0,0);
  Result := (i >= 1);
end; // UserExists


//------------------------------------------------------------------------------
// Get users
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.GetUsers(var Users: TMsgUserInfoArray; const SortBy: TMsgUserInfoArraySortBy; const Ascending: Boolean);
var
    Query:  TmySQLDirectQuery;
    s,s1:   AnsiString;
    i:      Integer;
begin
  Query := TmySQLDirectQuery.Create(nil);
  try
    Query.Database := FDatabase;
    if (Ascending) then
     s1 := ' ASC'
    else
     s1 := ' DESC';
    case SortBy of
    msgusbUserID: s := 'ORDER BY ID'+s1;
    msgusbUserName: s := 'ORDER BY UserName'+s1;
    msgusbFirstName: s := 'ORDER BY FirstName'+s1;
    msgusbLastName: s := 'ORDER BY LastName'+s1;
    msgusbStatus: s := 'ORDER BY Status'+s1;
    msgusbHost: s := 'ORDER BY Host'+s1;
    msgusbPort: s := 'ORDER BY Port'+s1;
    msgusbApplication: s := 'ORDER BY Application'+s1;
    else
     s := '';
    end;
    Query.SQL.Text := 'SELECT * FROM '+UsersTableName+' '+s;
    Query.Open;
    i := 0;
    SetLength(Users,i);
    Query.First;
    while (not Query.Eof) do
     begin
      Inc(i);
      SetLength(Users,i);
      Users[i-1] := ExtractUserInfo(Query);
      Query.Next;
     end;
  finally
    Query.Free;
  end;
end; // GetUsers


//------------------------------------------------------------------------------
// find users
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.FindUsers(
                    var Users:                    TMsgUserInfoArray;
                    var UserNameComparison:       TMsgTextComparison;
                    var FirstNameComparison:      TMsgTextComparison;
                    var LastNameComparison:       TMsgTextComparison;
                    var OrganizationComparison:   TMsgTextComparison;
                    var DepartmentComparison:     TMsgTextComparison;
                    var ApplicationComparison:    TMsgTextComparison;
                    var HostComparison:           TMsgTextComparison;
                    var PortComparison:           TMsgIntegerComparison;
                    Status:                       TMsgUserStatus = msgNone;
                    UserID:                       Cardinal = MSG_INVALID_USER_ID;
                    UserName:                     ShortString = '';
                    FirstName:                    ShortString = '';
                    LastName:                     ShortString = '';
                    Organization:                 ShortString = '';
                    Department:                   ShortString = '';
                    Host:                         ShortString = '';
                    Application:                  ShortString = '';
                    SearchCondition:              AnsiString = ''; // SQL WHERE clause without word WHERE
                    // ORDER BY columns without ORDER BY words
                    // example: SenderID DESC, SendingDate ASC
                    SortBy:                       TMsgUserInfoArraySortBy = msgusbNone;
                    Ascending:                    Boolean = True;
                    OrderByClause:                AnsiString = ''
                       );
var
    Query:      TmySQLDirectQuery;
    s,s1:       AnsiString;
    i:          Integer;
    condition:  AnsiString;

  function AddCondition(condition, newCondition: AnsiString): AnsiString;
  begin
   if (newCondition <> '') then
    begin
     if (condition = '') then
      Result := newCondition
     else
      Result := condition + ' AND '+ newCondition;
    end
   else
    Result := condition;
  end; // AddCondition

 function GetCondition: AnsiString;
 var
      condition_UserName:         AnsiString;
      condition_FirstName:        AnsiString;
      condition_LastName:         AnsiString;
      condition_Organization:     AnsiString;
      condition_Department:       AnsiString;
      condition_Host:             AnsiString;
      condition_Application:      AnsiString;
      condition_Port:             AnsiString;
      condition_Status:           AnsiString;
      condition_UserID:           AnsiString;

 begin
  Result := SearchCondition;
  if (Result = '') then
   begin
    condition_UserName := '';
    condition_FirstName := '';
    condition_LastName := '';
    condition_Organization := '';
    condition_Department := '';
    condition_Host := '';
    condition_Port := '';
    condition_Application := '';
    condition_Status := '';
    condition_UserID := '';
    if (UserName <> '') then
      case UserNameComparison.Comparison of
       mscmpExact:
        begin
         if (UserNameComparison.CaseInsensitive) then
          condition_UserName := '(UPPER(UserName) = '+
                               AnsiQuotedStr(AnsiUpperCase(UserName),'''')+')'
         else
          condition_UserName := '(UserName = '+
                               AnsiQuotedStr(UserName,'''')+')';
        end;
       mscmpStarts:
        begin
         if (UserNameComparison.CaseInsensitive) then
          condition_UserName := '(UPPER(UserName) LIKE '+
                               AnsiQuotedStr(AnsiUpperCase(UserName)+'%','''')+')'
         else
          condition_UserName := '(UserName LIKE '+
                               AnsiQuotedStr(UserName+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (UserNameComparison.CaseInsensitive) then
          condition_UserName := '(UPPER(UserName) LIKE '+
                               AnsiQuotedStr('%'+AnsiUpperCase(UserName)+'%','''')+')'
         else
          condition_UserName := '(UserName LIKE '+
                               AnsiQuotedStr('%'+UserName+'%','''')+')';
        end;
      end; // UserName
    if (FirstName <> '') then
      case FirstNameComparison.Comparison of
       mscmpExact:
        begin
         if (FirstNameComparison.CaseInsensitive) then
          condition_FirstName := '(UPPER(FirstName) = '+
                               AnsiQuotedStr(AnsiUpperCase(FirstName),'''')+')'
         else
          condition_FirstName := '(FirstName = '+
                               AnsiQuotedStr(FirstName,'''')+')';
        end;
       mscmpStarts:
        begin
         if (FirstNameComparison.CaseInsensitive) then
          condition_FirstName := '(UPPER(FirstName) LIKE '+
                               AnsiQuotedStr(AnsiUpperCase(FirstName)+'%','''')+')'
         else
          condition_FirstName := '(FirstName LIKE '+
                               AnsiQuotedStr(FirstName+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (FirstNameComparison.CaseInsensitive) then
          condition_FirstName := '(UPPER(FirstName) LIKE '+
                               AnsiQuotedStr('%'+AnsiUpperCase(FirstName)+'%','''')+')'
         else
          condition_FirstName := '(FirstName LIKE '+
                               AnsiQuotedStr('%'+FirstName+'%','''')+')';
        end;
      end; // FirstName
    if (LastName <> '') then
      case LastNameComparison.Comparison of
       mscmpExact:
        begin
         if (LastNameComparison.CaseInsensitive) then
          condition_LastName := '(UPPER(LastName) = '+
                               AnsiQuotedStr(AnsiUpperCase(LastName),'''')+')'
         else
          condition_LastName := '(LastName = '+
                               AnsiQuotedStr(LastName,'''')+')';
        end;
       mscmpStarts:
        begin
         if (LastNameComparison.CaseInsensitive) then
          condition_LastName := '(UPPER(LastName) LIKE '+
                               AnsiQuotedStr(AnsiUpperCase(LastName)+'%','''')+')'
         else
          condition_LastName := '(LastName LIKE '+
                               AnsiQuotedStr(LastName+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (LastNameComparison.CaseInsensitive) then
          condition_LastName := '(UPPER(LastName) LIKE '+
                               AnsiQuotedStr('%'+AnsiUpperCase(LastName)+'%','''')+')'
         else
          condition_LastName := '(LastName LIKE '+
                               AnsiQuotedStr('%'+LastName+'%','''')+')';
        end;
      end; // LastName
    if (Organization <> '') then
      case OrganizationComparison.Comparison of
       mscmpExact:
        begin
         if (OrganizationComparison.CaseInsensitive) then
          condition_Organization := '(UPPER(Organization) = '+
                               AnsiQuotedStr(AnsiUpperCase(Organization),'''')+')'
         else
          condition_Organization := '(Organization = '+
                               AnsiQuotedStr(Organization,'''')+')';
        end;
       mscmpStarts:
        begin
         if (OrganizationComparison.CaseInsensitive) then
          condition_Organization := '(UPPER(Organization) LIKE '+
                               AnsiQuotedStr(AnsiUpperCase(Organization)+'%','''')+')'
         else
          condition_Organization := '(Organization LIKE '+
                               AnsiQuotedStr(Organization+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (OrganizationComparison.CaseInsensitive) then
          condition_Organization := '(UPPER(Organization) LIKE '+
                               AnsiQuotedStr('%'+AnsiUpperCase(Organization)+'%','''')+')'
         else
          condition_Organization := '(Organization LIKE '+
                               AnsiQuotedStr('%'+Organization+'%','''')+')';
        end;
      end; // Organization
    if (Department <> '') then
      case DepartmentComparison.Comparison of
       mscmpExact:
        begin
         if (DepartmentComparison.CaseInsensitive) then
          condition_Department := '(UPPER(Department) = '+
                               AnsiQuotedStr(AnsiUpperCase(Department),'''')+')'
         else
          condition_Department := '(Department = '+
                               AnsiQuotedStr(Department,'''')+')';
        end;
       mscmpStarts:
        begin
         if (DepartmentComparison.CaseInsensitive) then
          condition_Department := '(UPPER(Department) LIKE '+
                               AnsiQuotedStr(AnsiUpperCase(Department)+'%','''')+')'
         else
          condition_Department := '(Department LIKE '+
                               AnsiQuotedStr(Department+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (DepartmentComparison.CaseInsensitive) then
          condition_Department := '(UPPER(Department) LIKE '+
                               AnsiQuotedStr('%'+AnsiUpperCase(Department)+'%','''')+')'
         else
          condition_Department := '(Department LIKE '+
                               AnsiQuotedStr('%'+Department+'%','''')+')';
        end;
      end; // Department
    if (Host <> '') then
      case HostComparison.Comparison of
       mscmpExact:
        begin
         if (HostComparison.CaseInsensitive) then
          condition_Host := '(UPPER(Host) = '+
                               AnsiQuotedStr(AnsiUpperCase(Host),'''')+')'
         else
          condition_Host := '(Host = '+
                               AnsiQuotedStr(Host,'''')+')';
        end;
       mscmpStarts:
        begin
         if (HostComparison.CaseInsensitive) then
          condition_Host := '(UPPER(Host) LIKE '+
                               AnsiQuotedStr(AnsiUpperCase(Host)+'%','''')+')'
         else
          condition_Host := '(Host LIKE '+
                               AnsiQuotedStr(Host+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (HostComparison.CaseInsensitive) then
          condition_Host := '(UPPER(Host) LIKE '+
                               AnsiQuotedStr('%'+AnsiUpperCase(Host)+'%','''')+')'
         else
          condition_Host := '(Host LIKE '+
                               AnsiQuotedStr('%'+Host+'%','''')+')';
        end;
      end; // Host
    if (Application <> '') then
      case ApplicationComparison.Comparison of
       mscmpExact:
        begin
         if (ApplicationComparison.CaseInsensitive) then
          condition_Application := '(UPPER(Application) = '+
                               AnsiQuotedStr(AnsiUpperCase(Application),'''')+')'
         else
          condition_Application := '(Application = '+
                               AnsiQuotedStr(Application,'''')+')';
        end;
       mscmpStarts:
        begin
         if (ApplicationComparison.CaseInsensitive) then
          condition_Application := '(UPPER(Application) LIKE '+
                               AnsiQuotedStr(AnsiUpperCase(Application)+'%','''')+')'
         else
          condition_Application := '(Application LIKE '+
                               AnsiQuotedStr(Application+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (ApplicationComparison.CaseInsensitive) then
          condition_Application := '(UPPER(Application) LIKE '+
                               AnsiQuotedStr('%'+AnsiUpperCase(Application)+'%','''')+')'
         else
          condition_Application := '(Application LIKE '+
                               AnsiQuotedStr('%'+Application+'%','''')+')';
        end;
      end; // Application
    if (UserID <> MSG_INVALID_USER_ID) then
     condition_UserID := '(ID = '+IntToStr(Integer(UserID))+')';
    if (Status <> msgNone) then
     condition_Status := '(Status = '+IntToStr(Byte(Status))+')';
    if (PortComparison.Comparison1 <> mcmpopNone) then
      begin
       condition_Port := '(Port ';
       case PortComparison.Comparison1 of
        mcmpopEqual:  condition_Port := condition_Port + ' = ';
        mcmpopGreater:  condition_Port := condition_Port + ' > ';
        mcmpopLower:  condition_Port := condition_Port + ' < ';
        mcmpopNotEqual:  condition_Port := condition_Port + ' <> ';
        mcmpopGreaterEqual:  condition_Port := condition_Port + ' >= ';
        mcmpopLowerEqual:  condition_Port := condition_Port + ' <= ';
       end;
       condition_Port := condition_Port+IntToStr(PortComparison.Value1)+')';
      end;
    if (PortComparison.Comparison2 <> mcmpopNone) then
      begin
       if (condition_Port = '') then
        condition_Port := '(Port '
       else
        condition_Port := condition_Port + ' AND (Port ';
       case PortComparison.Comparison2 of
        mcmpopEqual:  condition_Port := condition_Port + ' = ';
        mcmpopGreater:  condition_Port := condition_Port + ' > ';
        mcmpopLower:  condition_Port := condition_Port + ' < ';
        mcmpopNotEqual:  condition_Port := condition_Port + ' <> ';
        mcmpopGreaterEqual:  condition_Port := condition_Port + ' >= ';
        mcmpopLowerEqual:  condition_Port := condition_Port + ' <= ';
       end;
       condition_Port := condition_Port+IntToStr(PortComparison.Value2)+')';
      end;
    Result := AddCondition(Result,condition_UserName);
    Result := AddCondition(Result,condition_FirstName);
    Result := AddCondition(Result,condition_LastName);
    Result := AddCondition(Result,condition_Organization);
    Result := AddCondition(Result,condition_Department);
    Result := AddCondition(Result,condition_Host);
    Result := AddCondition(Result,condition_Port);
    Result := AddCondition(Result,condition_Application);
    Result := AddCondition(Result,condition_UserID);
    Result := AddCondition(Result,condition_Status);
   end; // SearchCondition is empty - check all conditions
  if (Result <> '') then
   Result := 'WHERE '+Result;
 end; // GetCondition

begin
  Query := TmySQLDirectQuery.Create(nil);
  try
    Query.Database := FDatabase;
    if (Ascending) then
     s1 := ' ASC'
    else
     s1 := ' DESC';
    case SortBy of
    msgusbUserID: s := 'ORDER BY ID'+s1;
    msgusbUserName: s := 'ORDER BY UserName'+s1;
    msgusbFirstName: s := 'ORDER BY FirstName'+s1;
    msgusbLastName: s := 'ORDER BY LastName'+s1;
    msgusbStatus: s := 'ORDER BY Status'+s1;
    msgusbHost: s := 'ORDER BY Host'+s1;
    msgusbPort: s := 'ORDER BY Port'+s1;
    msgusbApplication: s := 'ORDER BY Application'+s1;
    else
     s := '';
    end;
    if (OrderByClause <> '') then
     s := OrderByClause;
    condition := GetCondition;

    Query.SQL.Text := 'SELECT * FROM '+UsersTableName+' '+condition+' '+s;
    Query.Open;
    i := 0;
    SetLength(Users,i);
    Query.First;
    while (not Query.Eof) do
     begin
      Inc(i);
      SetLength(Users,i);
      Users[i-1] := ExtractUserInfo(Query);
      Query.Next;
     end;
  finally
    Query.Free;
  end;
end; // FindUsers


//------------------------------------------------------------------------------
// search for UserID by the UserName
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.FindUserID(const UserName: AnsiString): Cardinal;
begin
  Result := Cardinal(
                     FDatabase.SelectIntegerDef(
                      'SELECT u.id FROM '+
                      UsersTableName+' AS u '+
                      ' WHERE u.UserName = '+AnsiQuotedStr(UserName,''''),
                     Integer(MSG_INVALID_USER_ID),0));
end; // FindUserID


//------------------------------------------------------------------------------
// Get user contacts (array of UserID)
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.GetUserContacts(const UserID: Cardinal; var Contacts: TMsgContactInfoArray);
var
    Query:  TmySQLDirectQuery;
    i:      Integer;
begin
  Query := TmySQLDirectQuery.Create(nil);
  try
    Query.Database := FDatabase;
    Query.SQL.Text := 'SELECT u.*, c.ContactNameSource,c.ContactCustomName FROM '+
                      UsersTableName+' AS u, '+
                      ContactsTableName+' AS c'+
                      ' WHERE (u.ID = c.ContactID) '
                      +' AND (c.OwnerID = '+
                      IntToStr(Integer(UserID))+')';
    Query.Open;
    i := 0;
    SetLength(Contacts,i);
    Query.First;
    while (not Query.Eof) do
     begin
      Inc(i);
      SetLength(Contacts,i);
      Contacts[i-1].UserInfo := ExtractUserInfo(Query);
      Contacts[i-1].ContactNameSource := TMsgContactNameSource(StrToIntDef(Query.FieldValueByFieldName('ContactNameSource'),0));
      Contacts[i-1].ContactCustomName := Query.FieldValueByFieldName('ContactCustomName');
      Query.Next;
     end;
  finally
    Query.Free;
  end;
end; // GetUserContacts


//------------------------------------------------------------------------------
// return number of User's contacts
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.GetUserContactCount(UserID: Cardinal): Integer;
begin
  Result := FDatabase.SelectIntegerDef(
            'SELECT COUNT(*) FROM '+ContactsTableName+' WHERE OwnerID = '+IntToStr(Integer(UserID)),0,0);
end; // GetUserContactCount


//------------------------------------------------------------------------------
// return true if UserID is in contact list of OwnerUserID
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.IsUserInContacts(UserID,OwnerUserID: Cardinal): Boolean;
begin
  Result := (FDatabase.SelectIntegerDef(
              'SELECT * FROM '+ContactsTableName+' WHERE (OwnerID = '
              +IntToStr(Integer(OwnerUserID))+
              ') AND (ContactID = '+IntToStr(Integer(UserID))+')'
              ,0,0) > 0);
end; // IsUserInContacts


//------------------------------------------------------------------------------
// Add user to contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.AddUserToContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                                                  );
var
    db:     TMySQLDatabase;
    bOK:    Boolean;
    cnt:    Integer;
    s:      AnsiString;
begin
  if (not UserExists(OwnerUserID)) then
     raise EMsgException.Create(11368,ErrorLUserDoesNotExist,[OwnerUserID]);
  if (not UserExists(ContactUserID)) then
     raise EMsgException.Create(11369,ErrorLUserDoesNotExist,[ContactUserID]);
  db := CreateSessionDatabase;
  try
    db.Open;
    s := 'INSERT INTO '+ContactsTableName+
                      ' (OwnerID,ContactID,ContactNameSource,ContactCustomName) VALUES ('+crlf+
                      IntToStr(Integer(OwnerUserID))+','+crlf+
                      IntToStr(Integer(ContactUserID))+','+crlf+
                      IntToStr(Byte(ContactNameSource))+','+crlf+
                      AnsiQuotedStr(ContactCustomName,'''')+crlf+
                      ')'+crlf;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute(s,nil,false);
       if (db.InTransaction) then
        db.Commit;
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11370,ErrorLAddContactTransactionFailed,
       [OwnerUserID,ContactUserID,FRetryCount,FDelay]);
  finally
    db.Free;
  end;
end; // AddUserToContacts


//------------------------------------------------------------------------------
// update user in contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.UpdateUserInContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                                                  );
var
    db:     TMySQLDatabase;
    bOK:    Boolean;
    cnt:    Integer;
    s:      AnsiString;
begin
  if (not UserExists(OwnerUserID)) then
     raise EMsgException.Create(11490,ErrorLUserDoesNotExist,[OwnerUserID]);
  if (not UserExists(ContactUserID)) then
     raise EMsgException.Create(11491,ErrorLUserDoesNotExist,[ContactUserID]);
  db := CreateSessionDatabase;
  try
    db.Open;
    s := 'UPDATE '+ContactsTableName+' SET ContactNameSource = '+
                      IntToStr(Byte(ContactNameSource))+', ContactCustomName = '+
                      AnsiQuotedStr(ContactCustomName,'''')+crlf+
                      ' WHERE (OwnerID = '+IntToStr(Integer(OwnerUserID))+
                      ') AND (ContactID = '+IntToStr(Integer(ContactUserID))+')'+crlf;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute(s,nil,false);
       if (db.InTransaction) then
        db.Commit;
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11492,ErrorLUpdateContactTransactionFailed,
       [OwnerUserID,ContactUserID,FRetryCount,FDelay]);
  finally
    db.Free;
  end;
end; // UpdateUserInContacts


//------------------------------------------------------------------------------
// Remove user from contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.RemoveUserFromContacts(
                                  const OwnerUserID: Cardinal;
                                  const ContactUserID: Cardinal);
var
    db:     TMySQLDatabase;
    bOK:    Boolean;
    cnt:    Integer;
    s:      AnsiString;
begin
  if (not UserExists(OwnerUserID)) then
     raise EMsgException.Create(11371,ErrorLUserDoesNotExist,[OwnerUserID]);
  if (not UserExists(ContactUserID)) then
     raise EMsgException.Create(11372,ErrorLUserDoesNotExist,[ContactUserID]);
  db := CreateSessionDatabase;
  try
    db.Open;
    s :='DELETE FROM '+ContactsTableName+' WHERE (OwnerID = '+
                         IntToStr(Integer(OwnerUserID))+
                         ') AND (ContactID = '+IntToStr(Integer(ContactUserID))+')';
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute(s,nil,false);
       if (db.InTransaction) then
        db.Commit;
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11373,ErrorLRemoveUserFromContactsTransactionFailed,
       [OwnerUserID,ContactUserID,FRetryCount,FDelay]);
  finally
    db.Free;
  end;
end; // RemoveUserFromContacts


//------------------------------------------------------------------------------
// saves message to database and returns MessageID
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.SaveMessage(
                     const Delivered:           Boolean; // for commands
                     const DeliveryDate:        TDateTime;
                     const SenderID,
                           RecipientID:         Cardinal;
                     const MessageType:         TMsgMessageType;
                     const SendingDate:         TDateTime;
                     const MessageData:         PAnsiChar; // binary o stream message data
                     const MessageDataSize:     Integer; // size of MessageData
                     const MessageText:         AnsiString; // text of the message
                     const MessageUnicodeText:  WideString; // unicode text of the message
                     const Command:             Cardinal = 0 // no command
                    ): Integer;

var
    db:     TMySQLDatabase;
    params: TParams;
    param:  TParam;
    bOK:    Boolean;
    cnt:    Integer;
    s:      AnsiString;
    s_del:  AnsiString;
    s_data: AnsiString;
    s_unicode: AnsiString;
    s_command: AnsiString;
    s_sending: AnsiString;
begin
  Result := -1;
  db := CreateSessionDatabase;
  params := TParams.Create;
  try
    db.Open;
    if (Delivered) then
     s_del := '1,'+crlf+''''+ConvertDateTimeTOString(DeliveryDate)+ ''','+crlf
    else
     s_del := '0,'+crlf+'NULL,'+crlf;
    if (MessageDataSize = 0) then
     s_data := 'NULL,'+crlf
    else
     s_data := ':P_MessageData,'+crlf;
    if (MessageUnicodeText = '') then
     s_unicode := 'NULL'+crlf
    else
     s_unicode := ':P_MessageUnicodeText'+crlf;
    if (MessageType >= MsgLowestType) then
     s_command := IntToStr(Integer(Command))+','+crlf
    else
     s_command := 'NULL,'+crlf;
    s_sending := ''''+ConvertDateTimeTOString(SendingDate)+''','+crlf;
    s := 'INSERT INTO '+MessagesTableName+
                      ' (SenderID, RecipientID, SendingDate, Delivered, DeliveryDate,'+crlf+
                      ' MessageType, Command, MessageDataSize, MessageData,'+
                      ' MessageText) VALUES ('+crlf+
//                      ' MessageText, MessageUnicodeText) VALUES ('+crlf+
                      IntToStr(Integer(SenderID))+','+crlf+
                      IntToStr(Integer(RecipientID))+','+crlf+
                      s_sending+crlf+
                      s_del+
                      IntToStr(Byte(MessageType))+','+crlf+
                      s_command+
                      IntToStr(Integer(MessageDataSize))+','+crlf+
                      s_data+
                      AnsiQuotedStr(MessageText,'''')+crlf+
//                      s_unicode+
                      ')';
    if (MessageDataSize > 0) then
     begin
      param := TParam.Create(params);
      param.Name := 'P_MessageData';
      param.DataType := ftBlob;
      param.SetBlobData(MessageData,MessageDataSize);
     end;
{
    if (MessageUnicodeText <> '') then
     begin
      param := TParam.Create(params);
      param.Name := 'P_MessageUnicodeText';
      param.DataType := ftBlob;
      param.DataType := ftWideString;
      param.Value := MessageUnicodeText;
     end;
}
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute(s,params,false);
       Result := db.SelectIntegerDef('SELECT LAST_INSERT_ID()',-1,0);
       if (db.InTransaction) then
        db.Commit;
//       Result := db.SelectIntegerDef('SELECT MAX(ID) FROM '+ MessagesTableName,-1,0);
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11379,ErrorLSaveMessageFailed,
       [SenderID,RecipientID,Byte(MessageType),MessageText,MessageDataSize,FRetryCount,FDelay]);
  finally
    db.Free;
    params.free;
  end;
end; // SaveMessage


//------------------------------------------------------------------------------
// set message delivery date = CURRENT_TIMESTAMP and delivered = true
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.SetMessageDeliveryDate(MessageID: Integer);
var
    db:     TMySQLDatabase;
    bOK:    Boolean;
    cnt:    Integer;
    s:      AnsiString;
begin
  db := CreateSessionDatabase;
  try
    db.Open;
    s := 'UPDATE '+MessagesTableName+
                      ' SET Delivered = 1, DeliveryDate = CURRENT_TIMESTAMP'+
                      ' WHERE ID = '+IntToStr(MessageID);
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute(s,nil,false);
       if (db.InTransaction) then
        db.Commit;
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11380,ErrorLSetMessageDeliveryDateFailed,
       [MessageID,FRetryCount,FDelay]);
  finally
    db.Free;
  end;
end; // SetMessageDeliveryDate


//------------------------------------------------------------------------------
// delete message
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQLDAC.DeleteMessage(MessageID: Integer);
var
    db:     TMySQLDatabase;
    bOK:    Boolean;
    cnt:    Integer;
    s:      AnsiString;
begin
  db := CreateSessionDatabase;
  try
    db.Open;
    s := 'DELETE FROM '+MessagesTableName+
                      ' WHERE ID = '+IntToStr(MessageID);
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      if (not db.InTransaction) then
       db.StartTransaction;
      try
       db.Execute(s,nil,false);
       if (db.InTransaction) then
        db.Commit;
       bOK := True;
      except
       if (db.InTransaction) then
        db.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11387,ErrorLDeleteMessageFailed,
       [MessageID,FRetryCount,FDelay]);
  finally
    db.Free;
  end;
end; // DeleteMessage


//------------------------------------------------------------------------------
// return new query object with found messages from MsgMessages table
//------------------------------------------------------------------------------
function TMsgDatabaseMySQLDAC.FindMessages(
                         const MessageTextComparison:         TMsgTextComparison;
                         const MessageUnicodeTextComparison:  TMsgTextComparison;
                         const SendingDate:                   TMsgDateComparison;
                         const DeliveryDate:                  TMsgDateComparison;
                         const SearchDelivered:               Boolean;
                         const Delivered:                     Boolean = True;
                         // text of the message
                         const MessageText:                   AnsiString = '';
                         // unicode text of the message
                         const MessageUnicodeText:            WideString = '';
                         const SenderID:                      Cardinal = MSG_INVALID_USER_ID;
                         const RecipientID:                   Cardinal = MSG_INVALID_USER_ID;
                         const MessageType:                   TMsgMessageType = aamtNone;
                         // size of MessageData
                         const MessageDataSize:               Integer = -1;
                         const OrderBySendingDate:            Boolean = False;
                         const OrderByClause:                 AnsiString = '';
                         // no condition on command field if TMsgMessageType = aamtNone
                         const Command:                       Cardinal = 0
                        ): TDataset;
var

    Query:  TmySQLQuery;

    bOK:    Boolean;
    cnt:    Integer;
    condition:                AnsiString;
    condition_MessageText:         AnsiString;
    condition_MessageUnicodeText:  AnsiString;
    condition_MessageDataSize:     AnsiString;
    condition_MessageType:         AnsiString;
    condition_MessageCommand:      AnsiString;
    condition_SenderID:            AnsiString;
    condition_RecipientID:         AnsiString;
    condition_Delivered:           AnsiString;
    condition_SendingDate:         AnsiString;
    condition_DeliveryDate:        AnsiString;
    orderby:                       AnsiString;

  function MakeDateCondition(DateComp: TMsgDateComparison; Name: AnsiString): AnsiString;
  var  d_cond:         AnsiString;
  begin
   Result := '';
   if (DateComp.Comparison1 <> mcmpopNone) then
    begin
     d_cond := ''''+ConvertDateTimeTOString(DateComp.DateTime1)+'''';
     Result := Result + '('+Name;
     case DateComp.Comparison1 of
      mcmpopEqual:  Result := Result + ' = ';
      mcmpopGreater:  Result := Result + ' > ';
      mcmpopLower:  Result := Result + ' < ';
      mcmpopNotEqual:  Result := Result + ' <> ';
      mcmpopGreaterEqual:  Result := Result + ' >= ';
      mcmpopLowerEqual:  Result := Result + ' <= ';
     end;
     Result := Result + d_cond+')';
    end;
   if (DateComp.Comparison2 <> mcmpopNone) then
    begin
     if (DateComp.Comparison1 <> mcmpopNone) then
      Result := '('+Result+' AND ('+Name
     else
      Result := '('+Name;
     d_cond := ''''+ConvertDateTimeTOString(DateComp.DateTime2)+'''';
     case DateComp.Comparison2 of
      mcmpopEqual:  Result := Result + ' = ';
      mcmpopGreater:  Result := Result + ' > ';
      mcmpopLower:  Result := Result + ' < ';
      mcmpopNotEqual:  Result := Result + ' <> ';
      mcmpopGreaterEqual:  Result := Result + ' >= ';
      mcmpopLowerEqual:  Result := Result + ' <= ';
     end;
     Result := Result + d_cond+')';
     if (DateComp.Comparison1 <> mcmpopNone) then
      Result := Result + ')';
    end;
  end; // MakeDateCondition

  procedure AddCondition(newCondition: AnsiString);
  begin
   if (condition = '') then
    condition := newCondition
   else
    condition := condition + ' AND '+ newCondition;
  end; // AddCondition

begin
  Query := TmySQLQuery.Create(nil);
  Query.Database := FDatabase;
  Result := Query;
  condition := '';
  if (not SearchDelivered) then
   condition_Delivered := ''
  else
   begin
    if (Delivered) then
     condition_Delivered := '(Delivered > 0)'
    else
     condition_Delivered := '(Delivered = 0)';
   end;
  if (DeliveryDate.Comparison1 = mcmpopNone) and (DeliveryDate.Comparison2 = mcmpopNone) then
   condition_DeliveryDate := ''
  else
   condition_DeliveryDate := MakeDateCondition(DeliveryDate,'DeliveryDate');
  if (SendingDate.Comparison1 = mcmpopNone) and (SendingDate.Comparison2 = mcmpopNone) then
   condition_SendingDate := ''
  else
   condition_SendingDate := MakeDateCondition(SendingDate,'SendingDate');
  if (Command <> 0) or ((MessageType <= MsgHighestType) and (MessageType >= MsgLowestType)) then
   condition_MessageCommand := '(Command = '+IntToStr(Integer(Command))+')'
  else
   condition_MessageCommand := '';
  if (MessageType <> aamtNone) then
   condition_MessageType := '(MessageType = '+IntToStr(Byte(MessageType))+')'
  else
   condition_MessageType := '';
  if (MessageDataSize > -1) then
   condition_MessageDataSize := '(MessageDataSize = '+IntToStr(MessageDataSize)+')'
  else
   condition_MessageDataSize := '';
  if (SenderID <> MSG_INVALID_USER_ID) then
   condition_SenderID := '(SenderID = '+IntToStr(SenderID)+')'
  else
   condition_SenderID := '';
  if (RecipientID <> MSG_INVALID_USER_ID) then
   condition_RecipientID := '(RecipientID = '+IntToStr(RecipientID)+')'
  else
   condition_RecipientID := '';
  if (MessageText = '') then
   condition_MessageText := ''
  else
   begin
    case MessageTextComparison.Comparison of
     mscmpExact:
      begin
       if (MessageTextComparison.CaseInsensitive) then
        condition_MessageText := '(UPPER(MessageText) = '+
                             AnsiQuotedStr(AnsiUpperCase(MessageText),'''')+')'
       else
        condition_MessageText := '(MessageText = '+
                             AnsiQuotedStr(MessageText,'''')+')';
      end;
     mscmpStarts:
      begin
       if (MessageTextComparison.CaseInsensitive) then
        condition_MessageText := '(UPPER(MessageText) LIKE '+
                             AnsiQuotedStr(AnsiUpperCase(MessageText)+'%','''')+')'
       else
        condition_MessageText := '(MessageText LIKE '+
                             AnsiQuotedStr(MessageText+'%','''')+')';
      end;
     mscmpContains:
      begin
       if (MessageTextComparison.CaseInsensitive) then
        condition_MessageText := '(UPPER(MessageText) LIKE '+
                             AnsiQuotedStr('%'+AnsiUpperCase(MessageText)+'%','''')+')'
       else
        condition_MessageText := '(MessageText LIKE '+
                             AnsiQuotedStr('%'+MessageText+'%','''')+')';
      end;
    end; // case
   end; // MessageText
//  if (MessageUnicodeText = '') then
   condition_MessageUnicodeText := '';
{
  else
   begin
    case MessageUnicodeTextComparison.Comparison of
     mscmpExact:
      begin
       if (MessageUnicodeTextComparison.CaseInsensitive) then
        condition_MessageUnicodeText := '(UPPER(MessageUnicodeText) = UPPER(:P_MessageUnicodeText))'
       else
        condition_MessageUnicodeText := '(MessageUnicodeText = :P_MessageUnicodeText)';
      end;
     mscmpStarts:
      begin
       if (MessageUnicodeTextComparison.CaseInsensitive) then
        condition_MessageUnicodeText := '(UPPER(MessageUnicodeText) LIKE UPPER(:P_MessageUnicodeText)+''%'')'
       else
        condition_MessageUnicodeText := '(MessageUnicodeText LIKE :P_MessageUnicodeText+''%'')';
      end;
     mscmpContains:
      begin
       if (MessageUnicodeTextComparison.CaseInsensitive) then
        condition_MessageUnicodeText := '(UPPER(MessageUnicodeText) LIKE ''%''+UPPER(:P_MessageUnicodeText)+''%'')'
       else
        condition_MessageUnicodeText := '(MessageUnicodeText LIKE ''%''+:P_MessageUnicodeText+''%'')';
      end;
    end; // case
   end; // MessageUnicodeText
}
  if (SenderID = RecipientID) and (SenderID <> MSG_INVALID_USER_ID) then
   begin
    condition_SenderID := '('+condition_SenderID+' OR '+condition_RecipientID+')';
    AddCondition(condition_SenderID);
   end
  else
   begin
    if (condition_SenderID <> '') then
      AddCondition(condition_SenderID);
    if (condition_RecipientID <> '') then
      AddCondition(condition_RecipientID);
   end;
  if (condition_Delivered <> '') then
    AddCondition(condition_Delivered);
  if (condition_DeliveryDate <> '') then
    AddCondition(condition_DeliveryDate);
  if (condition_SendingDate <> '') then
    AddCondition(condition_SendingDate);
  if (condition_MessageCommand <> '') then
    AddCondition(condition_MessageCommand);
  if (condition_MessageType <> '') then
    AddCondition(condition_MessageType);
  if (condition_MessageDataSize <> '') then
    AddCondition(condition_MessageDataSize);
  if (condition_MessageText <> '') then
    AddCondition(condition_MessageText);
  if (condition_MessageUnicodeText <> '') then
    AddCondition(condition_MessageUnicodeText);
  orderby := '';
  if (OrderBySendingDate) then
   orderby := ' ORDER BY SendingDate ASC'
  else
   if (OrderByClause <> '') then
    orderby := ' ORDER BY '+OrderByClause;
  if (condition = '') then
   Query.SQL.Text := 'SELECT * FROM '+MessagesTableName+orderby
  else
   Query.SQL.Text := 'SELECT * FROM '+MessagesTableName+' WHERE '+condition+orderby;
  if (condition_MessageUnicodeText <> '') then
   begin
    Query.Prepare;
    Query.ParamByName('P_MessageUnicodeText').DataType := ftWideString;
    Query.ParamByName('P_MessageUnicodeText').Value := MessageUnicodeText;
   end;

  bOK := False;
  cnt := FRetryCount;
  while (not bOK) and (cnt >= 0) do
   begin
    try
     Query.Open;
     bOK := True;
    except
     Dec(cnt);
    end;
   end;
  if (cnt < 0) then
   begin
    raise EMsgException.Create(11381,ErrorLFindMessageFailed,
     [Query.SQL.Text,FRetryCount,FDelay]);
   end;
end; // FindMessages


//------------------------------------------------------------------------------
// convert dt to quoted AnsiString using time stamp MM/DD/YYYY HH24:NN:SS
//------------------------------------------------------------------------------
function ConvertDateTimeTOString(dt: TDateTime): AnsiString;
var d,m,y,h,n,s,z: Word;
begin
 DecodeDateTime(dt,y,m,d,h,n,s,z);
 Result := Format('%4.4u-%2.2u-%2.2u %2.2u:%2.2u:%2.2u',[y,m,d,h,n,s]);
end; // ConvertDateTimeTOString


//------------------------------------------------------------------------------
// fix table names
//------------------------------------------------------------------------------
procedure FixTableNames(sl: TStringList);
var i,l : Integer;
    s:    AnsiString;
begin
  for i := 0 to sl.Count-1 do
   begin
    s := sl.Strings[i];
    if (s[1] = '`') then
     begin
      l := Length(s);
      if (l > 2) then
       begin
        s := Copy(s,2,l-2);
        sl.Strings[i] := s;
       end;
     end;
   end;
end; // FixTableNames


{$IFDEF TRIAL_VERSION}

//------------------------------------------------------------------------------
// callback function to enumerate all open windows
//------------------------------------------------------------------------------
Function MsgWindowCallback(WHandle : HWnd; Var Parm : Pointer) : Boolean;
          stdcall;
{This function is called once for each window}
 Var MyString : PAnsiChar;
begin

    {Window text}
    MyString := Allocmem(255);
    GetWindowTextA(WHandle,MyString,255);
    TStringList(Parm).Add(MyString);
    FreeMem(MyString,255);
    Result := True; {Everything's okay. Continue to enumerate windows}
end;


var i: integer;
    WindowLst: TStringList;
    IsIDERunning: boolean;
    IsDelphiOrBuilderInstalled: boolean;
 {$IFDEF MSWINDOWS}
    Reg: TRegistry;
 {$ENDIF}
{$ENDIF}


initialization
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgDatabaseMySQLDAC> initialization started');
{$ENDIF}

  {$IFDEF DEBUG_MEMCHECK}
  MemChk;
  {$ENDIF}

{$IFDEF TRIAL_VERSION}
{$IFDEF MSWINDOWS}

  WindowLst := TStringList.Create;
  EnumWindows(@MsgWindowCallback,Longint(@WindowLst));
  // IDE detection
  IsIDERunning := false;
  for i:=0 to WindowLst.Count-1 do
    if ((Pos('Delphi',WindowLst[i]) = 1) or
        (Pos('Borland',WindowLst[i]) > 0) or
        (Pos('CodeGear',WindowLst[i]) > 0) or
        (Pos('Highlander',WindowLst[i]) > 0) or
        (Pos('C++Builder',WindowLst[i]) = 1)) then
      begin
       IsIDERunning := true;
       break;
      end;
  // Delphi/Builder installation detection
  Reg:=TRegistry.Create;
  Reg.RootKey := HKEY_CURRENT_USER;
  if ((Reg.KeyExists('\Software\Borland\Delphi')) or
      (Reg.KeyExists('\Software\Borland\BDS')) or
      (Reg.KeyExists('\Software\Borland\C++Builder'))) then
    IsDelphiOrBuilderInstalled := true
  else
    IsDelphiOrBuilderInstalled := false;
  Reg.Free;
  // nag screen
  if ((not IsIDERunning) or (not IsDelphiOrBuilderInstalled)) then
     begin
      msgtrshnm;
     end;
   WindowLst.Free;
{$ENDIF}
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgDatabaseMySQLDAC> initialization finished');
{$ENDIF}


end.

