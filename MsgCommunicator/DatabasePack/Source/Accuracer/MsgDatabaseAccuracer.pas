unit MsgDatabaseAccuracer;

interface

{$I MsgDBacrVer.inc}
{DEFINE DEBUG_DB_ACR}

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
ACRMain,
ACRComMain,
ACRLocalEngine,
ACRVariant,
ACRTypes,

{$IFDEF DEBUG_LOG}
ACRDebug,
{$ENDIF}

MsgCompression,
MsgExcept,
MsgComBase,
MsgCrypto,
MsgConst,
MsgTypes
;

 const MsgModuleVersion = 2.80;
 const MsgModuleVersionText = '';


type

////////////////////////////////////////////////////////////////////////////////
//
// TMsgDatabaseAccuracer
//
////////////////////////////////////////////////////////////////////////////////

 TMsgDatabaseAccuracer = class (TMsgDatabase)
  private
   FDatabase:   TACRDatabase;
   FUsersTable: TACRTable;
   FCounter:    Int64;
  protected
   function GetMainVersion: AnsiString; override;
   function GetModuleVersion: AnsiString; override;
   function GetTablesExists(HistoryOnly: Boolean): Boolean; override;
   procedure CreateTables(HistoryOnly: Boolean); override;
   procedure OpenDatabase; override;
   function CreateSessionDatabase: TACRDatabase;
   procedure StartTransaction(aDatabase: TACRDatabase);
   function ExtractUserInfo(Dataset: TDataset): TMsgUserInfo;
   function GetUserExists(const UserID: Cardinal): Boolean;
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
   property Database: TACRDatabase read FDatabase write FDatabase;
 end; // TMsgDatabaseAccuracer


////////////////////////////////////////////////////////////////////////////////
//
// TMsgTempTableAccuracer
//
////////////////////////////////////////////////////////////////////////////////


 TMsgTempTableAccuracer = class (TMsgTempTable)
  private
   FCompressionAlgorithm: TCompressionAlgorithm;
   FCompressionMode:      Byte;
   FBlockSize:            Integer;
  public
   constructor Create(AOwner: TComponent); override;
   procedure SaveDatasetToStream(Dataset: TDataset; Stream: TStream); override;
   procedure LoadDatasetFromStream(var Dataset: TDataset; Stream: TStream); override;
  published
   property CompressionAlgorithm: TCompressionAlgorithm read FCompressionAlgorithm write FCompressionAlgorithm;
   property CompressionMode: Byte read FCompressionMode write FCompressionMode;
   property BlockSize: Integer read FBlockSize write FBlockSize;
 end; // TMsgTempTable


 // convert dt to AnsiString constant using time stamp MM/DD/YYYY HH24:NN:SS
 function ConvertDateTimeTOString(dt: TDateTime): AnsiString;
 function GetDateFormat: AnsiString;

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
     MsgDECUtil, MsgCipher, Math;
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
// Result := 'MsgCommunicator Accuracer Database Module Trial Version - ';
end;

function msgtrnm1: AnsiString;
begin
{
  Result :=
             'This is the trial version of MsgCommunicator Accuracer Database Module by'#13+
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
 Result := 'BEDAEC896E0AB355805CD85A1A801CF757C7C47AA5F0C32EEBE0425BA16ED2F95206AAD76EE3D9434A8427568932CDAB7D78A01E83CF10C5E453';
end;

function msgtrnm: AnsiString;
begin
  Result :=
            '85342E20DE20E32E63B4D63D05BD5E020874B2B2E2B760F71FBF3643793892A888AEBAF9BA2EB69FFA3BC154AD8957F3B852DDAD57C148CB48C0F4B78FA38655F4348EAF2043A2645C4EE011701A263572'
           +'8DF21792D4218916E4172C3EBDA90A9298744BAED25038D9EAE7379C3004E73778AF7305EE064ACFE29E111F2613B95A394B331B22F42A002402F58194EDE425A8C286479DBB0EF9A2E371DD7C9394E124'
           +'2618768AD327FA6FB8886328BD54731219F0BB9DF45CA3CBD981BFBFBCF1664AD484511FCAFCC3D3A3EECF9B820453DDF02C0723FA7273A82A2AB19510047C34A5A0BC935149CC0A59662FFFF4954C8ECA'
           +'B74E66DBD046848F295B6D1FF0304789A7CC1BE2E0ED7EDFBBA62006052D8357D9B8BBF8ECBF5564E5D2DBE67510655EA8197FF5936C6A3D761F55B302E37E9CF53CE7258D870D8129E5DE9FC7DDE038F8'
           +'A56D030899B66FE6E76374C9BCF64419658DB6351884B6C5B737D7BDDA10FB4BFF03AD858A2CFE5D8A54DA3E95E5DF6889DB68609177DC2B211B47CC5E9627E268F35A3B043009046CD5E00739A5261930'
           +'65D4C2B2141AE3A35BDBF3FC20CC44BD8BB59742FA9935978A6E7B99D5770F0C16216D4CCD358EA1D36C5FF67B939011DDFD94489ED6F9953D4C47A009480A600B323762A955659B1A61B2B9E7B5CB570A'
           +'B99C7CEAC0AC48E3D3540F50B2DF2AA79A85DCF534747B7741A97F86AE13D8284505ACC64067DC441157F71509D02C752C4AC54C69624576227F5753E5704031FD332703C80520DCD115E185A24FD1C55C6333D3D6FB520BCE0E051615DD4E5D6C691069960B0DAEF2B6432A6AE85872340D343F9CAD38'
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
// TMsgDatabaseAccuracer
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return Version of the MsgCommunicator
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.GetMainVersion: AnsiString;
var c : Char;
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
function TMsgDatabaseAccuracer.GetModuleVersion: AnsiString;
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
// Return true if all tables exists
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.GetTablesExists(HistoryOnly: Boolean): Boolean;
begin
  Result := FDatabase.TableExists(MessagesTableName);
  if (Result and (not HistoryOnly)) then
   begin
    Result := FDatabase.TableExists(UsersTableName);
    if (Result) then
     begin
      Result := FDatabase.TableExists(ContactsTableName);
     end;
   end;
end; // GetTablesExists


//------------------------------------------------------------------------------
// Create Tables
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.CreateTables(HistoryOnly: Boolean);
var s:              AnsiString;
    MemoBlobParams: AnsiString;
    DataBlobParams: AnsiString;
    FQuery:         TACRQuery;
begin
 FQuery := TACRQuery.Create(nil);
 try
   FQuery.DatabaseName := FDatabase.DatabaseName;
   MemoBlobParams := '';
   DataBlobParams := '';
   if (not HistoryOnly) then
    begin
     if (FDatabase.TableExists(UsersTableName)) then
      s := 'DROP TABLE '+UsersTableName+';'+crlf
     else
      s := '';
     s := s+'CREATE TABLE '+UsersTableName + ' ('+crlf+
          // User unique ID
          'ID Integer, '+ crlf+
          'UserName Char(255),'+crlf+
          'FirstName Char(255),'+crlf+
          'LastName Char(255),'+crlf+
          'Organization VarChar(255),'+crlf+
          'Department VarChar(255),'+crlf+
          'Status Byte,'+crlf+
          'LogonTime DateTime,'+crlf+
          'LogoffTime DateTime,'+crlf+
          'Host VarChar(255),'+crlf+
          'Port Integer,'+crlf+
          'Application VarChar(255),'+crlf+
          'CryptoHeader BLOB,'+crlf+
          'PRIMARY KEY UsersPK (ID)'+ crlf+
          ');'+crlf+
          'CREATE INDEX UserNameIndex ON '+UsersTableName+' (UserName);'+crlf+
          'CREATE INDEX UserNameNoCaseIndex ON '+UsersTableName+' (UserName NOCASE);'+crlf+
          'CREATE INDEX StatusIndex ON '+UsersTableName+' (Status);'+crlf+
          '';
     FQuery.SQL.Text := s;
     FQuery.ExecSQL;

     if (FDatabase.TableExists(ContactsTableName)) then
      s := 'DROP TABLE '+ContactsTableName+';'+crlf
     else
      s := '';
     s := s+'CREATE TABLE '+ContactsTableName + ' ('+crlf+
          // id in Users of the contact list owner
          'OwnerID Integer,'+crlf+
          // id in Users of the person in contact list
          'ContactID Integer,'+crlf+
          // source of the name: UserName, FirstName, LastName, FirstName LastName, Custom,  etc.
          'ContactNameSource Byte,'+crlf+
          // contact custom name
          'ContactCustomName VarChar(255),'+crlf+
          'PRIMARY KEY ContactsPK (OwnerID,ContactID)'+ crlf+
          ');'+crlf+
          'CREATE INDEX ContactIDIndex ON '+ContactsTableName+' (ContactID);'+crlf;
     FQuery.SQL.Text := s;
     FQuery.ExecSQL;
    end;
   if (FDatabase.TableExists(MessagesTableName)) then
    s := 'DROP TABLE '+MessagesTableName+';'+crlf
   else
    s := '';
   s := s+'CREATE TABLE '+MessagesTableName + ' ('+ crlf+
        // Message unique ID
        'ID AutoInc, '+ crlf+
        // Sender UserID
        'SenderID Integer, '+ crlf+
        // Recipient UserID
        'RecipientID Integer, '+ crlf+
        // Delivered or no
        'Delivered Boolean, '+ crlf+
        // Delivery date
        'DeliveryDate DateTime,'+ crlf+
        // Date of sending
        'SendingDate DateTime,'+ crlf+
        // message type: binary, stream, text, command
        'MessageType Byte,'+ crlf+
        // if sent by SendCommand
        'Command Integer,'+ crlf+
        // size of data
        'MessageDataSize Integer,'+ crlf+
        // message data if not text message
        'MessageData BLOB '+DataBlobParams+','+ crlf+
        // for text messages or for custom translation of binary messages
        'MessageText Memo '+MemoBlobParams+','+ crlf+
        // for text messages or for custom translation of binary messages
        'MessageUnicodeText WideMemo '+MemoBlobParams+','+ crlf+
        'PRIMARY KEY MessagesPK (ID)'+ crlf+
        ');'+crlf+
        'CREATE INDEX SenderIDIndex ON '+MessagesTableName+' (SenderID);'+crlf+
        'CREATE INDEX RecipientIDIndex ON '+MessagesTableName+' (RecipientID);'+crlf;
    FQuery.SQL.Text := s;
    FQuery.ExecSQL;
    if (not HistoryOnly) then
     begin
      FUsersTable.Open;
      FUsersTable.IndexName := 'UsersPK';
     end;
 finally
   FQuery.Free;
 end;
end; // CreateTables


//------------------------------------------------------------------------------
// OpenDatabase
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.OpenDatabase;
var s: AnsiString;
    mtable: TACRTable;
begin
//Exit;
  if (FDatabase = nil) then
   raise EMsgException.Create(11353,ErrorLDatabaseIsNotAssigned);
  if (not FDatabase.Connected) then
   begin
    if (not FDatabase.Exists) then
     FDatabase.CreateDatabase;
    FDatabase.Open;
    FCloseDB := True;
   end
  else
   FCloseDB := False;
  if (FUsersTable = nil) then
   FUsersTable := TACRTable.Create(nil);
  FUsersTable.DatabaseName := FDatabase.DatabaseName;
  FUsersTable.TableName := UsersTableName;
  if (FUsersTable.Exists) then
   begin
     FUsersTable.Open;
     FUsersTable.IndexName := 'UsersPK';
     if (FUsersTable.RestructureFieldDefs.Find('LogonTime') = nil) then
      begin
       FUsersTable.Close;
       try
         s := '';
         FUsersTable.RestructureFieldDefs.Add('LogonTime',aftDateTime);
         FUsersTable.RestructureFieldDefs.Add('LogoffTime',aftDateTime);
         FUsersTable.RestructureTable(s);
         if (s <> '') then
          raise EMsgException.Create(11617,ErrorLRestructureFailed,[UsersTableName,s]);
       finally
         FUsersTable.Open;
       end;
      end;
   end;
  mTable := TACRTable.Create(nil);
  try
    mTable.DatabaseName := FDatabase.DatabaseName;
    mTable.TableName := MessagesTableName;
    if (mtable.Exists) then
     begin
      mTable.Open;
      if (mTable.IndexDefs.IndexOf('SenderIDIndex') < 0) then
       begin
        mTable.Close;
        mTable.Exclusive := True;
        mtable.AddIndex('SenderIDIndex','SenderID',[]);
        mtable.AddIndex('RecipientIDIndex','RecipientID',[]);
       end;
     end;
  finally
    mTable.Free;
  end;
end; // OpenDatabase


//------------------------------------------------------------------------------
// create session database
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.CreateSessionDatabase: TACRDatabase;
begin
  Result := TACRDatabase.Create(nil);
  Inc(FCounter);
  Result.DatabaseName := 'DB_'+IntToStr(FCounter)+'_'+IntToStr(Integer(Result));
  Result.DatabaseFileName := FDatabase.DatabaseFileName;
  Result.LocalDatabase := FDatabase.LocalDatabase;
  Result.CryptoParams.Assign(FDatabase.CryptoParams);
  Result.LockParams.Assign(FDatabase.LockParams);
  Result.ConnectionParams.Assign(FDatabase.ConnectionParams);
  Result.Options.Assign(FDatabase.Options);
  Result.Exclusive := FDatabase.Exclusive;
end; // CreateSessionDatabase


//------------------------------------------------------------------------------
// Start transaction
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.StartTransaction(aDatabase: TACRDatabase);
var bOK: Boolean;
begin
  bOK := False;
  while (not bOK) do
   begin
    if (not aDatabase.InTransaction) then
     try
       aDatabase.StartTransaction;
       bOK := True;
     except
       bOK := False;
     end;
    if (not bOK) then
     Sleep(1);
   end;
end; // StartTransaction


//------------------------------------------------------------------------------
// return user info
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.ExtractUserInfo(Dataset: TDataset): TMsgUserInfo;
begin
  Result.UserID := Cardinal(Dataset.FieldByName('ID').AsInteger);
  Result.UserName := Dataset.FieldByName('UserName').AsString;
  Result.FirstName := Dataset.FieldByName('FirstName').AsString;
  Result.LastName := Dataset.FieldByName('LastName').AsString;
  Result.Organization := Dataset.FieldByName('Organization').AsString;
  Result.Department := Dataset.FieldByName('Department').AsString;
  Result.Status := TMsgUserStatus(Dataset.FieldByName('Status').AsInteger);
  Result.Host := Dataset.FieldByName('Host').AsString;
  Result.Application := Dataset.FieldByName('Application').AsString;
  Result.Port := Dataset.FieldByName('Port').AsInteger;
end; // ExtractUserInfo


//------------------------------------------------------------------------------
// GetUserExists
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.GetUserExists(const UserID: Cardinal): Boolean;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.GetUsersExists, id = '+IntToStr(Integer(UserID)));
{$ENDIF}
//Result := (UserID <= 100) and (UserID >= 1);
//Exit;
{
aaInitTime(time10);
aaInitTime(time1);
aaInitTime(time2);
aaInitTime(time3);
aaInitTime(time4);
aaInitTime(time5);
aaStartTime(time10);
aaIncCounter(counter3);
aaWriteToLog('user exists = '+IntToStr(aaGetCounter(counter3)));
 }
    Result := FUsersTable.FindKey([Integer(UserID)]);
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.GetUsersExists, result = '+BoolToStr(Result,True));
{$ENDIF}
end; // GetUserExists


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgDatabaseAccuracer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCounter := 0;
  FUsersTable := nil;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgDatabaseAccuracer.Destroy;
begin
  if (FUsersTable <> nil) then
   FUsersTable.Free;
  FUsersTable := nil;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.CloseDatabase;
begin
  if (FCloseDB) then
    FDatabase.Close;
end; // CloseDatabase


//------------------------------------------------------------------------------
// add user
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.AddUser(UserInfo: TMsgUserInfo; PasswordHeader: TMsgCryptoHeader);
var DB:     TACRDatabase;
    Table:  TACRTable;
    bOK:    Boolean;
    cnt:    Integer;
    bs:     TStream;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.AddUser');
{$ENDIF}
//Exit;
//aaIncCounter(counter2);
//aaWriteToLog('add user = '+IntToStr(aaGetCounter(counter2)));
  if (UserInfo.UserID = MSG_INVALID_USER_ID) then
   raise EMsgException.Create(11365,ErrorLInvalidUserID,[UserInfo.UserID]);
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    bOK := False;
    cnt := DB.LockParams.RetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
       Table.Insert;
       Table.FieldByName('ID').AsInteger := Integer(UserInfo.UserID);
       Table.FieldByName('UserName').AsString := UserInfo.UserName;
       Table.FieldByName('FirstName').AsString := UserInfo.FirstName;
       Table.FieldByName('LastName').AsString := UserInfo.LastName;
       Table.FieldByName('Organization').AsString := UserInfo.Organization;
       Table.FieldByName('Department').AsString := UserInfo.Department;
       Table.FieldByName('Application').AsString := UserInfo.Application;
       Table.FieldByName('Host').AsString := UserInfo.Host;
       Table.FieldByName('Port').AsInteger := UserInfo.Port;
       Table.FieldByName('Status').AsInteger := Byte(UserInfo.Status);
       if (PasswordHeader.CryptoAlgorithm <> Msg_Cipher_None) then
        begin
         bs := Table.CreateBlobStream(Table.FieldByName('CryptoHeader'),bmWrite);
         try
           bs.WriteBuffer(PasswordHeader,SizeOf(PasswordHeader));
         finally
           bs.Free;
         end;
        end;
       Table.Post;
       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11360,ErrorLAddUserTransactionFailed,
       [UserInfo.UserID,DB.LockParams.RetryCount,DB.LockParams.Delay]);
  finally
    Table.Free;
    DB.Free;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.AddUser finished');
{$ENDIF}
{
aaWriteToLog(#13#10+
             'TMsgDatabaseAccuracer..AddUser: UserID = '+IntToStr(UserInfo.UserID)+#13#10+
             'Full time = '+IntToStr(aaGetTime(time10))+#13#10+
             'time11 = '+IntToStr(aaGetTime(time11))+#13#10+
             'time12 = '+IntToStr(aaGetTime(time12))+#13#10+
             'time13 = '+IntToStr(aaGetTime(time13))+#13#10+
             'time14 = '+IntToStr(aaGetTime(time14))+#13#10+
             'time15 = '+IntToStr(aaGetTime(time15))+#13#10+
             'time16 = '+IntToStr(aaGetTime(time16))+#13#10+
             'time17 = '+IntToStr(aaGetTime(time17))+#13#10+
             'time18 = '+IntToStr(aaGetTime(time18))+#13#10+
             'time19 = '+IntToStr(aaGetTime(time19))+#13#10+
             'time20 = '+IntToStr(aaGetTime(time20))+#13#10
             );
}
  end;
end; // AddUser


//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.RemoveUser(const UserID: Cardinal);
var DB:     TACRDatabase;
    uTable: TACRTable;
    cTable: TACRTable;
    mTable: TACRTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.RemoveUser, id = '+IntToStr(Integer(UserID)));
{$ENDIF}
  DB := CreateSessionDatabase;
  bOK := False;
  cnt := DB.LockParams.RetryCount;
  uTable := TACRTable.Create(nil);
  cTable := TACRTable.Create(nil);
  mTable := TACRTable.Create(nil);
  try
    DB.Open;
    uTable.DatabaseName := DB.DatabaseName;
    cTable.DatabaseName := DB.DatabaseName;
    mTable.DatabaseName := DB.DatabaseName;
    uTable.TableName := UsersTableName;
    cTable.TableName := ContactsTableName;
    mTable.TableName := MessagesTableName;
    uTable.Open;
    cTable.Open;
    mTable.Open;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
       uTable.IndexName := 'UsersPK';
       if (not uTable.FindKey([Integer(UserID)])) then
        begin
          DB.Rollback;
          Exit;
        end;
       uTable.Delete;
       // delete user's contact list
       cTable.IndexName := 'ContactsPK';
       cTable.Filter := 'OwnerID = '+IntToStr(Integer(UserID));
       cTable.Filtered := True;
       if (cTable.RecordCount > 0) then
        cTable.DeleteVisibleRecords;
       cTable.Filtered := False;
       // delete user from other user's contact lists
       cTable.IndexName := 'ContactIDIndex';
       cTable.Filter := 'ContactID = '+IntToStr(Integer(UserID));
       cTable.Filtered := True;
       if (cTable.RecordCount > 0) then
        cTable.DeleteVisibleRecords;
       cTable.Filtered := False;

       // delete user's messages
       mTable.IndexName := 'SenderIDIndex';
       mTable.Filter := 'SenderID = '+IntToStr(Integer(UserID));
       mTable.Filtered := True;
       if (mTable.RecordCount > 0) then
        mTable.DeleteVisibleRecords;
       mTable.Filtered := False;

       mTable.IndexName := 'RecipientIDIndex';
       mTable.Filter := 'RecipientID = '+IntToStr(Integer(UserID));
       mTable.Filtered := True;
       if (mTable.RecordCount > 0) then
        mTable.DeleteVisibleRecords;
       mTable.Filtered := False;

       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
  finally
    uTable.Free;
    cTable.Free;
    mTable.Free;
    DB.Free;
    if (not bOK) and (cnt >= 0) then
     raise EMsgException.Create(11361,ErrorLUserDoesNotExist,[UserID]);
    if (not bOK) then
     raise EMsgException.Create(11362,ErrorLRemoveUserTransactionFailed,
       [UserID,DB.LockParams.RetryCount,DB.LockParams.Delay]);
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.RemoveUser finished');
{$ENDIF}
  end;
end; // RemoveUser


//------------------------------------------------------------------------------
// change user info and optionally password
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.ChangeUserInfo(UserInfo: TMsgUserInfo; ChangePassword: Boolean; PasswordHeader: TMsgCryptoHeader);
var DB:     TACRDatabase;
    Table:  TACRTable;
    bOK:    Boolean;
    cnt:    Integer;
    bs:     TStream;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.ChangeUserInfo');
{$ENDIF}
//Exit;
//aaIncCounter(counter2);
//aaWriteToLog('add user = '+IntToStr(aaGetCounter(counter2)));
  if (UserInfo.UserID = MSG_INVALID_USER_ID) then
   raise EMsgException.Create(11365,ErrorLInvalidUserID,[UserInfo.UserID]);
  DB := CreateSessionDatabase;
  bOK := False;
  cnt := DB.LockParams.RetryCount;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    Table.IndexName := 'UsersPK';
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
       if (not Table.FindKey([Integer(UserInfo.UserID)])) then
         begin
           DB.Rollback;
           Exit;
         end;
       Table.Edit;
       Table.FieldByName('UserName').AsString := UserInfo.UserName;
       Table.FieldByName('FirstName').AsString := UserInfo.FirstName;
       Table.FieldByName('LastName').AsString := UserInfo.LastName;
       Table.FieldByName('Organization').AsString := UserInfo.Organization;
       Table.FieldByName('Department').AsString := UserInfo.Department;
       Table.FieldByName('Application').AsString := UserInfo.Application;
       Table.FieldByName('Host').AsString := UserInfo.Host;
       Table.FieldByName('Port').AsInteger := UserInfo.Port;
       Table.FieldByName('Status').AsInteger := Byte(UserInfo.Status);
       if (ChangePassword) then
        begin
         bs := Table.CreateBlobStream(Table.FieldByName('CryptoHeader'),bmWrite);
         try
          if (PasswordHeader.CryptoAlgorithm <> Msg_Cipher_None) then
           bs.WriteBuffer(PasswordHeader,SizeOf(PasswordHeader));
         finally
          bs.Free;
         end;
        end;
       Table.Post;
       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
  finally
    Table.Free;
    DB.Free;
    if (not bOK) and (cnt >= 0) then
     raise EMsgException.Create(11363,ErrorLUserDoesNotExist,[UserInfo.UserID]);
    if (not bOK) then
     raise EMsgException.Create(11364,ErrorLChangeUserInfoTransactionFailed,
       [UserInfo.UserID,DB.LockParams.RetryCount,DB.LockParams.Delay]);
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.ChangeUserInfo finished');
{$ENDIF}
  end;
end; // ChangeUserInfo


//------------------------------------------------------------------------------
// ChangeUserStatus
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.ChangeUserStatus(
                           const AllUsers:    Boolean;
                           const UserID:      Cardinal;
                           const Status:      TMsgUserStatus;
                           const Host:        AnsiString = '';
                           const Port:        Integer = 0;
                           const Application: AnsiString = ''
                          );

var DB:       TACRDatabase;
    Table:    TACRTable;
    bOK:      Boolean;
    cnt:      Integer;
    fields:   TACRWideStringList;
    values:   array of TACRVariant;

procedure SetFields;
begin
 Table.Edit;
 Table.FieldByName('Status').AsInteger := Byte(Status);
 if (Status = msgOffline) then
   Table.FieldByName('LogoffTime').AsDateTime := Now;
 if (Status = msgOnline) then
   Table.FieldByName('LogonTime').AsDateTime := Now;
 if (Status <> msgOffline) then
  begin
   Table.FieldByName('Application').AsString := Application;
   Table.FieldByName('Host').AsString := Host;
   Table.FieldByName('Port').AsInteger := Port;
  end;
 Table.Post;
end;


begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.ChangeUserStatus - UserID = '+IntToStr(Integer(UserID))
+', Status = '+IntToStr(Byte(Status))+', AllUsers = '+BoolToStr(AllUsers));
{$ENDIF}
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  bOK := False;
  cnt := DB.LockParams.RetryCount;
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    Table.IndexName := 'StatusIndex';
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
       if (AllUsers) then
        begin
         // set status of all users to MsgOffline
         Table.Filter := 'Status <> '+IntToStr(Integer(Status));
         Table.Filtered := True;
         Table.First;
         if (not Table.Eof) then
          begin
           fields := TACRWideStringList.Create;
           fields.Add('Status');
           SetLength(values,1);
           values[0] := TACRVariant.Create;
           try
            values[0].AsByte := Byte(Status);
            Table.UpdateVisibleRecords(fields,values);
           finally
            fields.Free;
            values[0].Free;
            values := nil;
           end;
          end;
{
         while not (Table.Eof) do
          begin
           SetFields;
           Table.Next;
          end;
}
        end
       else
        begin
         Table.IndexName := 'UsersPK';
         if (not Table.FindKey([Integer(UserID)])) then
           begin
             DB.Rollback;
             Exit;
           end;
         SetFields;
        end;
       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
  finally
    Table.Free;
    DB.Free;
    if (not bOK) then
     raise EMsgException.Create(11367,ErrorLChangeUserStatusTransactionFailed,
       [UserID,DB.LockParams.RetryCount,DB.LockParams.Delay]);
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseAccuracer.ChangeUserStatus - UserID = '+IntToStr(Integer(UserID))
+', Status = '+IntToStr(Byte(Status))+', AllUsers = '+BoolToStr(AllUsers));
{$ENDIF}
  end;
end; // ChangeUserStatus


//------------------------------------------------------------------------------
// GetLastLogged
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.GetLastLogged(
                              const UserID:     Cardinal;
                              out   LogonTime:  TDateTime;
                              out   LogoffTime: TDateTime
                          );
var DB:     TACRDatabase;
    Table:  TACRTable;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>TMsgDatabaseAccuracer.GetLastLogged - UserID = '+IntToStr(UserID));
{$ENDIF}
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    Table.IndexName := 'UsersPK';
    if (Table.FindKey([Integer(UserID)])) then
     begin
      LogonTime := Table.FieldByName('LogonTime').AsDateTime;
      LogoffTime := Table.FieldByName('LogoffTime').AsDateTime;
     end
    else
     raise EMsgException.Create(11616,ErrorLUserDoesNotExist,[UserID]);
  finally
    Table.Free;
    DB.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('<TMsgDatabaseAccuracer.GetLastLogged - UserID = '+IntToStr(UserID));
{$ENDIF}
end; // GetLastLogged



//------------------------------------------------------------------------------
// Get user info
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.GetUserInfo(const UserID: Cardinal): TMsgUserInfo;
var DB:     TACRDatabase;
    Table:  TACRTable;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.GetUserInfo - UserID = '+IntToStr(Integer(UserID)));
{$ENDIF}
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    Table.IndexName := 'UsersPK';
    if (Table.FindKey([Integer(UserID)])) then
      Result := ExtractUserInfo(Table)
    else
      Result.UserID := MSG_INVALID_USER_ID;
  finally
    Table.Free;
    DB.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.GetUserInfo - UserID = '+IntToStr(Integer(UserID))+', UserInfo.UserID = '+IntToStr(Result.UserID));
{$ENDIF}
end; // GetUserInfo

//------------------------------------------------------------------------------
// returns users count
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.GetUsersCount: Integer;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.GetUsersCount');
{$ENDIF}
  Result := FUsersTable.RecordCount;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.GetUsersCount, result = ' + IntToStr(Result));
{$ENDIF}
end; // GetUsersCount


//------------------------------------------------------------------------------
// Return PasswordHeader
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.GetPasswordHeader(const UserID: Cardinal): TMsgCryptoHeader;
var DB:     TACRDatabase;
    Table:  TACRTable;
    bs:     TStream;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('MsgDatabaseAccuracer.GetPasswordHeader - UserID = '+IntToStr(Integer(UserID)));
{$ENDIF}
//Result.CryptoAlgorithm := 0;
//Exit;
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    Table.IndexFieldNames := 'ID';
    if (Table.FindKey([Integer(UserID)])) then
     begin
      if (Table.FieldByName('CryptoHeader').IsNull) then
       begin
        FillChar(Result,SizeOf(Result),0);
        Result.CryptoAlgorithm := Msg_Cipher_None;
       end
      else
       begin
        bs := Table.CreateBlobStream(Table.FieldByName('CryptoHeader'),bmRead);
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
    Table.Free;
    DB.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.GetPasswordHeader - UserID = '+IntToStr(Integer(UserID))+' ok');
{$ENDIF}
end; // GetPasswordHeader


//------------------------------------------------------------------------------
// Return true if user exists
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.UserExists(const UserID: Cardinal): Boolean;
begin
  Result := GetUserExists(UserID);
end; // UserExists


//------------------------------------------------------------------------------
// Get users
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.GetUsers(var Users: TMsgUserInfoArray; const SortBy: TMsgUserInfoArraySortBy; const Ascending: Boolean);
var DB:     TACRDatabase;
    Query:  TACRQuery;
    s,s1:   String;
    i:      Integer;
begin
  DB := CreateSessionDatabase;
  Query := TACRQuery.Create(nil);
  try
    DB.Open;
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
    Query.DatabaseName := DB.DatabaseName;
    Query.RequestLive := True;
    Query.SQL.Text := 'SELECT * FROM '+UsersTableName+' '+s;
    Query.Open;
    SetLength(Users,Query.RecordCount);
    Query.First;
    i := 0;
    while (i < Length(Users)) and (not Query.Eof) do
     begin
      Users[i] := ExtractUserInfo(Query);
      Query.Next;
      Inc(i);
     end;
  finally
    Query.Free;
    DB.Free;
  end;
end; // GetUsers


//------------------------------------------------------------------------------
// find users
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.FindUsers(
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
var DB:         TACRDatabase;
    Query:      TACRQuery;
    s,s1:       String;
    i:          Integer;
    condition:  String;

  function AddCondition(condition, newCondition: String): String;
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

 function GetCondition: String;
 var
      condition_UserName:         String;
      condition_FirstName:        String;
      condition_LastName:         String;
      condition_Organization:     String;
      condition_Department:       String;
      condition_Host:             String;
      condition_Application:      String;
      condition_Port:             String;
      condition_Status:           String;
      condition_UserID:           String;

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
                               AnsiQuotedStr(UpperCase(UserName),'''')+')'
         else
          condition_UserName := '(UserName = '+
                               AnsiQuotedStr(UserName,'''')+')';
        end;
       mscmpStarts:
        begin
         if (UserNameComparison.CaseInsensitive) then
          condition_UserName := '(UPPER(UserName) LIKE '+
                               AnsiQuotedStr(UpperCase(UserName)+'%','''')+')'
         else
          condition_UserName := '(UserName LIKE '+
                               AnsiQuotedStr(UserName+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (UserNameComparison.CaseInsensitive) then
          condition_UserName := '(UPPER(UserName) LIKE '+
                               AnsiQuotedStr('%'+UpperCase(UserName)+'%','''')+')'
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
                               AnsiQuotedStr(UpperCase(FirstName),'''')+')'
         else
          condition_FirstName := '(FirstName = '+
                               AnsiQuotedStr(FirstName,'''')+')';
        end;
       mscmpStarts:
        begin
         if (FirstNameComparison.CaseInsensitive) then
          condition_FirstName := '(UPPER(FirstName) LIKE '+
                               AnsiQuotedStr(UpperCase(FirstName)+'%','''')+')'
         else
          condition_FirstName := '(FirstName LIKE '+
                               AnsiQuotedStr(FirstName+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (FirstNameComparison.CaseInsensitive) then
          condition_FirstName := '(UPPER(FirstName) LIKE '+
                               AnsiQuotedStr('%'+UpperCase(FirstName)+'%','''')+')'
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
                               AnsiQuotedStr(UpperCase(LastName),'''')+')'
         else
          condition_LastName := '(LastName = '+
                               AnsiQuotedStr(LastName,'''')+')';
        end;
       mscmpStarts:
        begin
         if (LastNameComparison.CaseInsensitive) then
          condition_LastName := '(UPPER(LastName) LIKE '+
                               AnsiQuotedStr(UpperCase(LastName)+'%','''')+')'
         else
          condition_LastName := '(LastName LIKE '+
                               AnsiQuotedStr(LastName+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (LastNameComparison.CaseInsensitive) then
          condition_LastName := '(UPPER(LastName) LIKE '+
                               AnsiQuotedStr('%'+UpperCase(LastName)+'%','''')+')'
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
                               AnsiQuotedStr(UpperCase(Organization),'''')+')'
         else
          condition_Organization := '(Organization = '+
                               AnsiQuotedStr(Organization,'''')+')';
        end;
       mscmpStarts:
        begin
         if (OrganizationComparison.CaseInsensitive) then
          condition_Organization := '(UPPER(Organization) LIKE '+
                               AnsiQuotedStr(UpperCase(Organization)+'%','''')+')'
         else
          condition_Organization := '(Organization LIKE '+
                               AnsiQuotedStr(Organization+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (OrganizationComparison.CaseInsensitive) then
          condition_Organization := '(UPPER(Organization) LIKE '+
                               AnsiQuotedStr('%'+UpperCase(Organization)+'%','''')+')'
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
                               AnsiQuotedStr(UpperCase(Department),'''')+')'
         else
          condition_Department := '(Department = '+
                               AnsiQuotedStr(Department,'''')+')';
        end;
       mscmpStarts:
        begin
         if (DepartmentComparison.CaseInsensitive) then
          condition_Department := '(UPPER(Department) LIKE '+
                               AnsiQuotedStr(UpperCase(Department)+'%','''')+')'
         else
          condition_Department := '(Department LIKE '+
                               AnsiQuotedStr(Department+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (DepartmentComparison.CaseInsensitive) then
          condition_Department := '(UPPER(Department) LIKE '+
                               AnsiQuotedStr('%'+UpperCase(Department)+'%','''')+')'
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
                               AnsiQuotedStr(UpperCase(Host),'''')+')'
         else
          condition_Host := '(Host = '+
                               AnsiQuotedStr(Host,'''')+')';
        end;
       mscmpStarts:
        begin
         if (HostComparison.CaseInsensitive) then
          condition_Host := '(UPPER(Host) LIKE '+
                               AnsiQuotedStr(UpperCase(Host)+'%','''')+')'
         else
          condition_Host := '(Host LIKE '+
                               AnsiQuotedStr(Host+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (HostComparison.CaseInsensitive) then
          condition_Host := '(UPPER(Host) LIKE '+
                               AnsiQuotedStr('%'+UpperCase(Host)+'%','''')+')'
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
                               AnsiQuotedStr(UpperCase(Application),'''')+')'
         else
          condition_Application := '(Application = '+
                               AnsiQuotedStr(Application,'''')+')';
        end;
       mscmpStarts:
        begin
         if (ApplicationComparison.CaseInsensitive) then
          condition_Application := '(UPPER(Application) LIKE '+
                               AnsiQuotedStr(UpperCase(Application)+'%','''')+')'
         else
          condition_Application := '(Application LIKE '+
                               AnsiQuotedStr(Application+'%','''')+')';
        end;
       mscmpContains:
        begin
         if (ApplicationComparison.CaseInsensitive) then
          condition_Application := '(UPPER(Application) LIKE '+
                               AnsiQuotedStr('%'+UpperCase(Application)+'%','''')+')'
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
  DB := CreateSessionDatabase;
  Query := TACRQuery.Create(nil);
  try
    DB.Open;
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

    Query.DatabaseName := DB.DatabaseName;
    Query.RequestLive := True;
    Query.SQL.Text := 'SELECT * FROM '+UsersTableName+' '+condition+' '+s;
    Query.Open;
    SetLength(Users,Query.RecordCount);
    Query.First;
    i := 0;
    while (i < Length(Users)) and (not Query.Eof) do
     begin
      Users[i] := ExtractUserInfo(Query);
      Query.Next;
      Inc(i);
     end;
  finally
    Query.Free;
    DB.Free;
  end;
end; // FindUsers


//------------------------------------------------------------------------------
// search for UserID by the UserName
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.FindUserID(const UserName: AnsiString): Cardinal;
var DB:     TACRDatabase;
    uTable: TACRTable;
begin
  DB := CreateSessionDatabase;
  uTable := TACRTable.Create(nil);
  try
    DB.Open;
    uTable.DatabaseName := DB.DatabaseName;
    uTable.TableName := UsersTableName;
    uTable.Open;
    uTable.IndexName := 'UserNameIndex';
    Result := MSG_INVALID_USER_ID;
    if (uTable.FindKey([UserName])) then
     Result := Cardinal(uTable.FieldByName('id').AsInteger);
  finally
    uTable.Free;
    DB.Free;
  end;
end; // FindUserID


//------------------------------------------------------------------------------
// Get user contacts (array of UserID)
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.GetUserContacts(const UserID: Cardinal; var Contacts: TMsgContactInfoArray);
var DB:     TACRDatabase;
    uTable: TACRTable;
    cTable: TACRTable;
    i:      Integer;
begin
  DB := CreateSessionDatabase;
  uTable := TACRTable.Create(nil);
  cTable := TACRTable.Create(nil);
  try
    DB.Open;
    uTable.DatabaseName := DB.DatabaseName;
    cTable.DatabaseName := DB.DatabaseName;
    uTable.TableName := UsersTableName;
    cTable.TableName := ContactsTableName;
    uTable.Open;
    cTable.Open;
    uTable.IndexName := 'UsersPK';
    cTable.IndexName := 'ContactsPK';
    cTable.Filter := 'OwnerID = '+IntToStr(Integer(UserID));
    cTable.Filtered := True;
    cTable.First;
    SetLength(Contacts,cTable.RecordCount);
    i := 0;
    while not (cTable.Eof) do
     begin
      Contacts[i].ContactNameSource := TMsgContactNameSource(cTable.FieldByName('ContactNameSource').AsInteger);
      Contacts[i].ContactCustomName := cTable.FieldByName('ContactCustomName').AsString;
      if (uTable.FindKey([cTable.FieldByName('ContactID').AsInteger])) then
       Contacts[i].UserInfo := ExtractUserInfo(uTable);
      cTable.Next;
      Inc(i);
     end;
  finally
    uTable.Free;
    cTable.Free;
    DB.Free;
  end;
end; // GetUserContacts


//------------------------------------------------------------------------------
// return number of contacts for user with id = UserID
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.GetUserContactCount(UserID: Cardinal): Integer;
var DB:     TACRDatabase;
    Table:  TACRTable;
begin
//Exit;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.GetUserContactCount, id = '+IntToStr(Integer(UserID)));
{$ENDIF}
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := ContactsTableName;
    Table.Open;
    Table.Filter := 'OwnerID = '+IntToStr(Integer(UserID));
    Table.Filtered := True;
    Result := Table.RecordCount;
  finally
    Table.Free;
    DB.Free;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.GetUserContactCount, result = '+IntToStr(Result));
{$ENDIF}
  end;
end; // GetUserContactCount


//------------------------------------------------------------------------------
// return true if UserID is in contact list of OwnerUserID
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.IsUserInContacts(UserID,OwnerUserID: Cardinal): Boolean;
var DB:     TACRDatabase;
    Table:  TACRTable;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.IsUserInContacts, UserID = '+IntToStr(Integer(UserID))
  +#13#10+'OwnerUserID = '+IntToStr(OwnerUserID));
{$ENDIF}
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := ContactsTableName;
    Table.Open;
    Table.IndexName := 'ContactsPK';
    Result := Table.FindKey([Integer(OwnerUserID),Integer(UserID)]);
  finally
    Table.Free;
    DB.Free;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.IsUserInContacts, result = '+BoolToStr(Result,true));
{$ENDIF}
  end;
end; // IsUserInContacts


//------------------------------------------------------------------------------
// Add user to contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.AddUserToContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                                                  );
var DB:     TACRDatabase;
    Table:  TACRTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := ContactsTableName;
    Table.Open;
    bOK := False;
    cnt := DB.LockParams.RetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      if (not UserExists(OwnerUserID)) then
       begin
         DB.Rollback;
         raise EMsgException.Create(11368,ErrorLUserDoesNotExist,[OwnerUserID]);
       end;
      if (not UserExists(ContactUserID)) then
       begin
         DB.Rollback;
         raise EMsgException.Create(11369,ErrorLUserDoesNotExist,[ContactUserID]);
       end;
      try
       Table.Insert;
       Table.FieldByName('OwnerID').AsInteger := Integer(OwnerUserID);
       Table.FieldByName('ContactID').AsInteger := Integer(ContactUserID);
       Table.FieldByName('ContactNameSource').AsInteger := Byte(ContactNameSource);
       Table.FieldByName('ContactCustomName').AsString := ContactCustomName;
       Table.Post;
       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11370,ErrorLAddContactTransactionFailed,
       [OwnerUserID,ContactUserID,DB.LockParams.RetryCount,DB.LockParams.Delay]);
  finally
    Table.Free;
    DB.Free;
  end;
end; // AddUserToContacts


//------------------------------------------------------------------------------
// update user in contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.UpdateUserInContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                                                  );
var DB:     TACRDatabase;
    Table:  TACRTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := ContactsTableName;
    Table.Open;
    Table.IndexName := 'ContactsPK';
    bOK := False;
    cnt := DB.LockParams.RetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      if (not Table.FindKey([Integer(OwnerUserID),Integer(ContactUserID)])) then
       begin
         DB.Rollback;
         raise EMsgException.Create(11490,ErrorLUsersContactDoesNotExist,[OwnerUserID,ContactUserID]);
       end;
      try
       Table.Edit;
       Table.FieldByName('ContactNameSource').AsInteger := Byte(ContactNameSource);
       Table.FieldByName('ContactCustomName').AsString := ContactCustomName;
       Table.Post;
       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11492,ErrorLUpdateContactTransactionFailed,
       [OwnerUserID,ContactUserID,DB.LockParams.RetryCount,DB.LockParams.Delay]);
  finally
    Table.Free;
    DB.Free;
  end;
end; // UpdateUserInContacts


//------------------------------------------------------------------------------
// Remove user from contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.RemoveUserFromContacts(
                                  const OwnerUserID: Cardinal;
                                  const ContactUserID: Cardinal);
var DB:     TACRDatabase;
    Table:  TACRTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := ContactsTableName;
    Table.Open;
    Table.IndexName := 'ContactsPK';
    bOK := False;
    cnt := DB.LockParams.RetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      if (not Table.FindKey([Integer(OwnerUserID),Integer(ContactUserID)])) then
       begin
         DB.Rollback;
         raise EMsgException.Create(11372,ErrorLUsersContactDoesNotExist,[OwnerUserID,ContactUserID]);
       end;
      try
       Table.Delete;
       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11373,ErrorLRemoveUserFromContactsTransactionFailed,
       [OwnerUserID,ContactUserID,DB.LockParams.RetryCount,DB.LockParams.Delay]);
   finally
    Table.Free;
    DB.Free;
  end;
end; // RemoveUserFromContacts


//------------------------------------------------------------------------------
// saves message to database and returns MessageID
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.SaveMessage(
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

var DB:     TACRDatabase;
    Table:  TACRTable;
    bOK:    Boolean;
    cnt:    Integer;
    bs:     TStream;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.SaveMessage - SenderID = '+IntToStr(Integer(SenderID))+
', RecipientID = '+IntToStr(Integer(RecipientID)));
{$ENDIF}
  Result := -1;
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := MessagesTableName;
    Table.Open;
    bOK := False;
    cnt := DB.LockParams.RetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
{$IFDEF DEBUG_DB_ACR}
//aaWriteToLog('TMsgDatabaseAccuracer.SaveMessage '+'- SenderID = '+IntToStr(Integer(SenderID))+' - INSERT: '+#13#10+Query.SQL.Text);
{$ENDIF}
       Table.Insert;
       Table.FieldByName('SenderID').AsInteger := Integer(SenderID);
       Table.FieldByName('RecipientID').AsInteger := Integer(RecipientID);
       Table.FieldByName('SendingDate').AsDateTime := SendingDate;
       Table.FieldByName('Delivered').AsBoolean := Delivered;
       if (Delivered) then
         Table.FieldByName('DeliveryDate').AsDateTime := DeliveryDate;
       Table.FieldByName('MessageType').AsInteger := Byte(MessageType);
       if (MessageType >= MsgLowestType) then
        Table.FieldByName('Command').AsInteger := Integer(Command);
       Table.FieldByName('MessageDataSize').AsInteger := MessageDataSize;
       if (MessageUnicodeText <> '') then
        Table.SetWideMemoField(Table.FieldByName('MessageUnicodeText'),MessageUnicodeText);
       if (MessageText <> '') then
        Table.FieldByName('MessageText').AsString := MessageText;
       if (MessageDataSize > 0) and (MessageData <> nil) then
        begin
         bs := Table.CreateBlobStream(Table.FieldByName('MessageData'),bmWrite);
         try
          bs.WriteBuffer(MessageData^,MessageDataSize);
         finally
          bs.Free;
         end;
        end;
//        TBlobField(Table.FieldByName('MessageData')).SetData(MessageData,False);
       Table.Post;
       Result := Table.FieldByName('ID').AsInteger;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.SaveMessage '+'- SenderID = '+IntToStr(Integer(SenderID))+' - result = : '+IntToStr(Result));
{$ENDIF}
       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11379,ErrorLSaveMessageFailed,
       [SenderID,RecipientID,Byte(MessageType),MessageText,MessageDataSize,DB.LockParams.RetryCount,DB.LockParams.Delay]);
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('TMsgDatabaseAccuracer.SaveMessage - SenderID = '+IntToStr(Integer(SenderID)));
{$ENDIF}
  finally
    Table.Free;
    DB.Free;
  end;
end; // SaveMessage


//------------------------------------------------------------------------------
// set message delivery date = CURRENT_TIMESTAMP and delivered = true
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.SetMessageDeliveryDate(MessageID: Integer);
var DB:     TACRDatabase;
    Table:  TACRTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := MessagesTableName;
    Table.Open;
    Table.IndexName := 'MessagesPK';
    bOK := False;
    cnt := DB.LockParams.RetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
       if (not Table.FindKey([MessageID])) then
        begin
         DB.Rollback;
         Exit;
        end;
       Table.Edit;
       Table.FieldByName('Delivered').AsBoolean := True;
       Table.FieldByName('DeliveryDate').AsDateTime := Now;
       Table.Post;
       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11380,ErrorLSetMessageDeliveryDateFailed,
       [MessageID,DB.LockParams.RetryCount,DB.LockParams.Delay]);
  finally
    Table.Free;
    DB.Free;
  end;
end; // SetMessageDeliveryDate


//------------------------------------------------------------------------------
// delete message
//------------------------------------------------------------------------------
procedure TMsgDatabaseAccuracer.DeleteMessage(MessageID: Integer);
var DB:     TACRDatabase;
    Table:  TACRTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TACRTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := MessagesTableName;
    Table.Open;
    Table.IndexName := 'MessagesPK';
    bOK := False;
    cnt := DB.LockParams.RetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
       if (not Table.FindKey([MessageID])) then
        begin
         DB.Rollback;
         Exit;
        end
       else
        Table.Delete;
       DB.Commit(False);
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11387,ErrorLDeleteMessageFailed,
       [MessageID,DB.LockParams.RetryCount,DB.LockParams.Delay]);
  finally
    Table.Free;
    DB.Free;
  end;
end; // DeleteMessage


//------------------------------------------------------------------------------
// return new query object with found messages from MsgMessages table
//------------------------------------------------------------------------------
function TMsgDatabaseAccuracer.FindMessages(
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
    Query:  TACRQuery;
    bOK:    Boolean;
    cnt:    Integer;
    condition:                String;
    condition_MessageText:         String;
    condition_MessageUnicodeText:  String;
    condition_MessageDataSize:     String;
    condition_MessageType:         String;
    condition_MessageCommand:      String;
    condition_SenderID:            String;
    condition_RecipientID:         String;
    condition_Delivered:           String;
    condition_SendingDate:         String;
    condition_DeliveryDate:        String;
    orderby:                       String;

  function MakeDateCondition(DateComp: TMsgDateComparison; Name: String): String;
  var  d_cond:         String;
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
     Result := Result + 'TODATE('+d_cond+','''+GetDateFormat+'''))';
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
     Result := Result + 'TODATE('+d_cond+','''+GetDateFormat+'''))';
     if (DateComp.Comparison1 <> mcmpopNone) then
      Result := Result + ')';
    end;
  end; // MakeDateCondition

  procedure AddCondition(newCondition: String);
  begin
   if (condition = '') then
    condition := newCondition
   else
    condition := condition + ' AND '+ newCondition;
  end; // AddCondition

begin
  Query := TACRQuery.Create(nil);
  Result := Query;
  Query.DatabaseName := FDatabase.DatabaseName;
  condition := '';
  if (not SearchDelivered) then
   condition_Delivered := ''
  else
   begin
    if (Delivered) then
     condition_Delivered := '(Delivered = TRUE)'
    else
     condition_Delivered := '(Delivered = FALSE)';
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
                             AnsiQuotedStr(UpperCase(MessageText),'''')+')'
       else
        condition_MessageText := '(MessageText = '+
                             AnsiQuotedStr(MessageText,'''')+')';
      end;
     mscmpStarts:
      begin
       if (MessageTextComparison.CaseInsensitive) then
        condition_MessageText := '(UPPER(MessageText) LIKE '+
                             AnsiQuotedStr(UpperCase(MessageText)+'%','''')+')'
       else
        condition_MessageText := '(MessageText LIKE '+
                             AnsiQuotedStr(MessageText+'%','''')+')';
      end;
     mscmpContains:
      begin
       if (MessageTextComparison.CaseInsensitive) then
        condition_MessageText := '(UPPER(MessageText) LIKE '+
                             AnsiQuotedStr('%'+UpperCase(MessageText)+'%','''')+')'
       else
        condition_MessageText := '(MessageText LIKE '+
                             AnsiQuotedStr('%'+MessageText+'%','''')+')';
      end;
    end; // case
   end; // MessageText
  if (MessageUnicodeText = '') then
   condition_MessageUnicodeText := ''
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
  Query.RequestLive := False;
  bOK := False;
  cnt := FDatabase.LockParams.RetryCount;
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
   raise EMsgException.Create(11381,ErrorLFindMessageFailed,
     [Query.SQL.Text,FDatabase.LockParams.RetryCount,FDatabase.LockParams.Delay]);
end; // FindMessages


////////////////////////////////////////////////////////////////////////////////
//
// TMsgTempTableAccuracer
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgTempTableAccuracer.Create(AOwner: TComponent);
begin
  inherited;
  FCompressionAlgorithm := caNone;
  FCompressionMode := 0;
  FBlockSize := DefaultMemoryBlockSize;
end; // Create;


//------------------------------------------------------------------------------
// SaveDatasetToStream
//------------------------------------------------------------------------------
procedure TMsgTempTableAccuracer.SaveDatasetToStream(Dataset: TDataset; Stream: TStream);
begin
  if (Dataset is TACRDataset) then
   TACRLocalCursor(TACRDataset(Dataset).Handle).SaveTableToStream(
    Stream,ConvertCompressionAlgorithmToACRCompressionAlgorithm(FCompressionAlgorithm),FCompressionMode,FBlockSize)
  else
   raise EMsgException.Create(11582,ErrorLNotAccuracerDataset);
end; // SaveDatasetToStream


//------------------------------------------------------------------------------
// LoadDatasetFromStream
//------------------------------------------------------------------------------
procedure TMsgTempTableAccuracer.LoadDatasetFromStream(var Dataset: TDataset; Stream: TStream);
var table: TACRTable;
begin
  Dataset := nil;
  table := TACRTable.Create(nil);
  Dataset := table;
  table.Temporary := True;
  table.LoadTableFromStream(Stream);
  table.Open;
end; // LoadDatasetFromStream


//------------------------------------------------------------------------------
// convert dt to quoted String using time stamp MM/DD/YYYY HH24:NN:SS
//------------------------------------------------------------------------------
function ConvertDateTimeTOString(dt: TDateTime): AnsiString;
var d,m,y,h,n,s,z: Word;
begin
 DecodeDateTime(dt,y,m,d,h,n,s,z);
 Result := Format('%2.2u/%2.2u/%4.4u %2.2u:%2.2u:%2.2u.%2.2u',[m,d,y,h,n,s,z]);
end; // ConvertDateTimeTOString


//------------------------------------------------------------------------------
// return conversion date format
//------------------------------------------------------------------------------
function GetDateFormat: AnsiString;
begin
  Result := 'MM/DD/YYYY HH24:NN:SS.ZZZ';
end; // ConvertDateTimeTOString

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
aaWriteToLog('MsgDatabaseAccuracer> initialization started');
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
aaWriteToLog('MsgDatabaseAccuracer> initialization finished');
{$ENDIF}


end.

