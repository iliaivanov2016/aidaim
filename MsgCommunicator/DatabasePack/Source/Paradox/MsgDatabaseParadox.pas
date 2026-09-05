unit MsgDatabaseParadox;

interface

{$I MsgDBVer.inc}
{DEFINE DEBUG_DB_PARADOX}

uses

{$IFDEF MSWINDOWS}
Windows,
{$ENDIF}
{$IFDEF LINUX}
Libc,
{$ENDIF}

Classes,SysUtils,

Db,
DBTables,
MsgDatabase,

{$IFDEF DEBUG_LOG}
ACRDebug,
{$ENDIF}

MsgCompression,
MsgExcept,
MsgComBase,
MsgConst,
MsgTypes
;

 const MsgModuleVersion = 1.00;
 const MsgModuleVersionText = '';


type

////////////////////////////////////////////////////////////////////////////////
//
// TMsgDatabaseParadox
//
////////////////////////////////////////////////////////////////////////////////

 TMsgDatabaseParadox = class (TMsgDatabase)
  private
   FDatabase:   TDatabase;
   FUsersTable: TTable;
   FCounter:    Int64;
   FRetryCount: Integer;
   FDelay:      Integer;
  protected
   function GetMainVersion: String; override;
   function GetModuleVersion: String; override;
   function TableExists(TableName: String): Boolean;
   function GetTablesExists(HistoryOnly: Boolean): Boolean; override;
   procedure CreateTables(HistoryOnly: Boolean); override;
   procedure OpenDatabase; override;
   function CreateSessionDatabase: TDatabase;
   procedure StartTransaction(aDatabase: TDatabase);
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
                               const Host:        String = '';
                               const Port:        Integer = 0;
                               const Application: String = ''
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
                    SearchCondition:              String = ''; // SQL WHERE clause without word WHERE
                    // ORDER BY columns without ORDER BY words
                    // example: SenderID DESC, SendingDate ASC
                    SortBy:                       TMsgUserInfoArraySortBy = msgusbNone;
                    Ascending:                    Boolean = True;
                    OrderByClause:                String = ''
                       ); override;
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
                         const MessageData:         PChar; // binary o stream message data
                         const MessageDataSize:     Integer; // size of MessageData
                         const MessageText:         String; // text of the message
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
                         const MessageText:                   String = ''; // text of the message
                         const MessageUnicodeText:            WideString = ''; // unicode text of the message
                         const SenderID:                      Cardinal = MSG_INVALID_USER_ID;
                         const RecipientID:                   Cardinal = MSG_INVALID_USER_ID;
                         const MessageType:                   TMsgMessageType = aamtNone;
                         const MessageDataSize:               Integer = -1; // size of MessageData
                         const OrderBySendingDate:            Boolean = False;
                         const OrderByClause:                 String = '';
                         const Command:                       Cardinal = 0 // no command
                        ): TDataset; override;
  published
   property Delay: Integer read FDelay write FDelay;
   property RetryCount: Integer read FRetryCount write FRetryCount;
   property Database: TDatabase read FDatabase write FDatabase;
 end; // TMsgDatabaseParadox


 // convert dt to string constant using time stamp MM/DD/YYYY HH24:NN:SS
 function ConvertDateTimeToString(dt: TDateTime): String;

{$IFDEF TRIAL_VERSION}

 function msgtrcapt1: String;
 function msgtrnm1: String;

 function msgtrcapt: String;
 function msgtrnm: String;
 function msgtrgetencmsg(msg: string): String;
 function msgtrgetdecmsg(msg: string): String;
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

function msgtrcapt1: String;
begin
// Result := 'MsgCommunicator Paradox Database Module Trial Version - ';
end;

function msgtrnm1: String;
begin
{
  Result :=
             'This is the trial version of MsgCommunicator Paradox Database Module by'#13+
             'AidAim Software (c) 2000-2007.'#13+
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

function msgtrcapt: String;
begin
 Result := 'BEDAEC896E0AB355805CD85A1A801CF757C7C47AA5F0C32EEBE0425BA16ED2F95206AAD76EE3D9434A8427568932CDAB7D78A01E83CF10C5E453';
end;

function msgtrnm: String;
begin
  Result :=
             '85342E20DE20E32E63B4D63D05BD5E020874B2B2E2B760F71FBF3643793892A888AEBAF9BA2EB69FFA3BC154AD8957F3B852DDAD57C148CB48C0F4B78FA38655F4348EAF2043A2645C4EE0'
            +'11701A2635728DF21792D4218916E4172C3EBDA90A275623E94E2D405CE45D1084F6E53A80F86D7A248B7152E3C8411022640925A4902B74DB2E1A18FCFBC81753ADC156400548C0FB5648'
            +'7568AE0212346B5BC78023CFBE82814FE49A23FEED635A8D4C138FF2FE4DAAE1108188314A35E300A54418899E1480291790679BE678B762CEED562C3D054EA5AE624DFB13B1562F91FA18'
            +'51930274AB50232D5CC1679F815E197FC9B972DDF84595FCA11B8A6F392FA59164489BC4203EFA633DF371F5298EA643359653506EB3393058BA27BD3A7630C052762BB9E59F41EACC23DC'
            +'801AC11C79C39C84C5CDDF356BEAC415B8652A0AA437CEDF8818F6E80FA7514463221957CA74C5DC6EFDA7C7193E211E1E32C61DED3DDE46A5682C16113305672011A4EAA3035B0EA2487F'
            +'6A7544C91DD90DC505F3F015CC5F12B0B984226B25283A7453B172FD98EC31A9EBA1F722D84AB4AF3B43E62958C54E659376ACD2B6DD25A45B99756F2CD68771C4FB4F9BF8BD84B10137DD'
            +'4DE99499C56F6C460D83E66DB549E7E995B135E478FBDBC8B39D002650808BAE1C1C803DB54A34474C554B730821C8DEE5124DE0485D43537DC0AEB450634684E8BA115CB261D610B844E1'
            +'0FBDF2A2E77B9886E6450A987003B840B8245710123E40E473A22667EE0EB847FC5DABCC9414CFBDD907FD81FFBF4744EC5AB77FDA8A7204CB507F4EB787BA6885462AE108FCF0751DDDC3DF1A611742'
            ;

end;

function msgtrgetencmsg(msg: string): String;
var cr: TCipher_Blowfish;
    s: string;
begin
 cr := TCipher_Blowfish.Create(MsgDefaultPassword,nil);
 s := cr.EncodeString(msg);
 cr.Free;
 Result := StrToFormat(PChar(@s[1]),Length(s),fmtHEX);
end;

function msgtrgetdecmsg(msg: string): String;
var cr: TCipher_Blowfish;
    s: string;
begin
 s := FormatToStr(PChar(@msg[1]),Length(msg),fmtHEX);
 cr := TCipher_Blowfish.Create(MsgDefaultPassword,nil);
 Result := cr.DecodeString(s);
 cr.Free;
end;

function msgtrgnm: String;
begin
 Result := msgtrgetdecmsg(msgtrnm);
end;

function msgtrgcapt: String;
var ds: char;
    vStr: string;
begin
  ds := DecimalSeparator;
  DecimalSeparator := '.';
  vStr := 'v.'+FormatFloat('0.00',MsgModuleVersion) + ' '+ MsgModuleVersionText;
  DecimalSeparator := ds;
  Result := msgtrgetdecmsg(msgtrcapt) + vStr;
end;

procedure msgtrshnm;
begin
{$IFDEF TRIAL_VERSION_WITHOUT_NAG_SCREEN}
 Exit;
{$ENDIF}
 MessageBox(0,PChar(msgtrgnm),PChar(msgtrgcapt),
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
// TMsgDatabaseParadox
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return Version of the MsgCommunicator
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.GetMainVersion: String;
var c : char;
begin
 c := DecimalSeparator;
 DecimalSeparator := '.';
 Result := FloatToStrF(MsgVersion,ffFixed,3,2) + ' ' + MsgVersionText;
 DecimalSeparator := c;
end; // GetMainVersion


//------------------------------------------------------------------------------
// return Version of this module
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.GetModuleVersion: String;
var c : char;
begin
 c := DecimalSeparator;
 DecimalSeparator := '.';
 Result := FloatToStrF(MsgModuleVersion,ffFixed,3,2) + ' ' + MsgModuleVersionText;
 DecimalSeparator := c;
end; // GetModuleVersion


//------------------------------------------------------------------------------
// Return true if table exists
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.TableExists(TableName: String): Boolean;
var sl: TStringList;
begin
  sl := TStringList.Create;
  try
   if (FDatabase <> nil) then
    {$IFDEF D6H}
    FDatabase.GetTableNames(sl,False);
    {$ELSE}
    if (FDatabase.Session <> nil) then
     FDatabase.Session.GetTableNames(FDatabase.DatabaseName,'',True,True,sl);
    {$ENDIF}
   Result := (sl.IndexOf(TableName) >= 0);
  finally
    sl.Free;
  end;
end; // TableExists


//------------------------------------------------------------------------------
// Return true if all tables exists
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.GetTablesExists(HistoryOnly: Boolean): Boolean;
var sl: TStringList;
begin
  sl := TStringList.Create;
  try
   if (FDatabase <> nil) then
    {$IFDEF D6H}
    FDatabase.GetTableNames(sl,False);
    {$ELSE}
    if (FDatabase.Session <> nil) then
     FDatabase.Session.GetTableNames(FDatabase.DatabaseName,'',True,True,sl);
    {$ENDIF}
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
procedure TMsgDatabaseParadox.CreateTables(HistoryOnly: Boolean);
var
    FQuery:         TQuery;
begin
 FQuery := TQuery.Create(nil);
 try
   FQuery.DatabaseName := FDatabase.DatabaseName;
   if (not HistoryOnly) then
    begin
     if (TableExists(UsersTableName)) then
      begin
       FQuery.SQL.Text := 'DROP TABLE '+UsersTableName+';'+crlf;
       FQuery.ExecSQL;
      end;
     FQuery.SQL.Text := 'CREATE TABLE '+UsersTableName + ' ('+crlf+
          // User unique ID
          'ID Integer, '+ crlf+
          'UserName Char(255),'+crlf+
          'FirstName Char(255),'+crlf+
          'LastName Char(255),'+crlf+
          'Organization Char(255),'+crlf+
          'Department Char(255),'+crlf+
          'Status SMALLINT,'+crlf+
          'Host Char(255),'+crlf+
          'Port Integer,'+crlf+
          'Application Char(255),'+crlf+
//          'CryptoHeader BYTES(255),'+crlf+
//          'CryptoHeader BLOB(1,2),'+crlf+
          'PRIMARY KEY (ID)'+ crlf+
          ');';
     FQuery.ExecSQL;
     FQuery.SQL.Text := 'CREATE INDEX UserNameIndex ON '+UsersTableName+' (UserName);';
     FQuery.ExecSQL;
     FQuery.SQL.Text := 'CREATE INDEX StatusIndex ON '+UsersTableName+' (Status);';
     FQuery.ExecSQL;
     if (TableExists(ContactsTableName)) then
      begin
       FQuery.SQL.Text := 'DROP TABLE '+ContactsTableName+';'+crlf;
       FQuery.ExecSQL;
      end;
     FQuery.SQL.Text := 'CREATE TABLE '+ContactsTableName + ' ('+crlf+
          // id in Users of the contact list owner
          'OwnerID Integer,'+crlf+
          // id in Users of the person in contact list
          'ContactID Integer,'+crlf+
          // source of the name: UserName, FirstName, LastName, FirstName LastName, Custom,  etc.
          'ContactNameSource SMALLINT,'+crlf+
          // contact custom name
          'ContactCustomName char(255),'+crlf+
          'PRIMARY KEY (OwnerID,ContactID)'+ crlf+
          ');';
     FQuery.ExecSQL;
     FQuery.SQL.Text :=  'CREATE INDEX ContactIDIndex ON '+ContactsTableName+' (ContactID);'+crlf;
     FQuery.ExecSQL;
    end;
   if (TableExists(MessagesTableName)) then
    begin
     FQuery.SQL.Text := 'DROP TABLE '+MessagesTableName+';'+crlf;
     FQuery.ExecSQL;
    end;
   FQuery.SQL.Text := 'CREATE TABLE '+MessagesTableName + ' ('+ crlf+
        // Message unique ID
        'ID AutoInc, '+ crlf+
        // Sender UserID
        'SenderID Integer, '+ crlf+
        // Recipient UserID
        'RecipientID Integer, '+ crlf+
        // Delivered or no
        'Delivered Boolean, '+ crlf+
        // Delivery date
        'DeliveryDate TIMESTAMP,'+ crlf+
        // Date of sending
        'SendingDate TIMESTAMP,'+ crlf+
        // message type: binary, stream, text, command
        'MessageType SMALLINT,'+ crlf+
        // if sent by SendCommand
        'Command Integer,'+ crlf+
        // size of data
        'MessageDataSize Integer,'+ crlf+
        // message data if not text message
        'MessageData BLOB(1,2),'+ crlf+
        // for text messages or for custom translation of binary messages
        'MessageText BLOB(1,1),'+ crlf+
        // for text messages or for custom translation of binary messages
        'MessageUnicodeText BLOB(1,2),'+ crlf+
        'PRIMARY KEY (ID)'+ crlf+
        ');';
    FQuery.ExecSQL;
    FUsersTable.Open;
    FUsersTable.IndexFieldNames := 'ID';
 finally
   FQuery.Free;
 end;
end; // CreateTables


//------------------------------------------------------------------------------
// OpenDatabase
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.OpenDatabase;
begin
//Exit;
  if (FDatabase = nil) then
   raise EMsgException.Create(11353,ErrorLDatabaseIsNotAssigned);
  if (not FDatabase.Connected) then
   begin
    FDatabase.Open;
    FCloseDB := True;
   end
  else
   FCloseDB := False;
  if (FUsersTable = nil) then
   FUsersTable := TTable.Create(nil);
  FUsersTable.DatabaseName := FDatabase.DatabaseName;
  FUsersTable.TableName := UsersTableName;
  if (FUsersTable.Exists) then
   begin
     FUsersTable.Open;
     FUsersTable.IndexFieldNames := 'ID';
   end;
end; // OpenDatabase


//------------------------------------------------------------------------------
// create session database
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.CreateSessionDatabase: TDatabase;
var ses: TSession;
begin
//  ses := TSession.Create(nil);
//  ses.AutoSessionName := False;
//  ses.SessionName := 'Session_'+IntToStr(FCounter);
  Result := TDatabase.Create(nil);
//  Result.SessionName := ses.SessionName;
  Result.DatabaseName := IntToStr(FCounter);;
  Result.TransIsolation := FDatabase.TransIsolation;
  //'DB_'+IntToStr(FCounter)+'_'+IntToStr(Integer(Result))
  if (FDatabase.DriverName <> '') then
    Result.DriverName := FDatabase.DriverName;
  Result.Open;
  if (FDatabase.Directory <> '') then
   Result.Directory := FDatabase.Directory;
  Inc(FCounter);
end; // CreateSessionDatabase


//------------------------------------------------------------------------------
// Start transaction
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.StartTransaction(aDatabase: TDatabase);
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
     Sleep(FDelay);
   end;
end; // StartTransaction


//------------------------------------------------------------------------------
// return user info
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.ExtractUserInfo(Dataset: TDataset): TMsgUserInfo;
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
function TMsgDatabaseParadox.GetUserExists(const UserID: Cardinal): Boolean;
begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.GetUsersExists, id = '+IntToStr(Integer(UserID)));
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
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.GetUsersExists, result = '+BoolToStr(Result,True));
{$ENDIF}
end; // GetUserExists


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgDatabaseParadox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCounter := 0;
  FDelay := 1;
  FRetryCount := 1000;
  FUsersTable := nil;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgDatabaseParadox.Destroy;
begin
  if (FUsersTable <> nil) then
   FUsersTable.Free;
  FUsersTable := nil;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.CloseDatabase;
begin
  if (FCloseDB) then
    FDatabase.Close;
end; // CloseDatabase


//------------------------------------------------------------------------------
// add user
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.AddUser(UserInfo: TMsgUserInfo; PasswordHeader: TMsgCryptoHeader);
var DB:     TDatabase;
    Table:  TTable;
    bOK:    Boolean;
    cnt:    Integer;
    bs:     TStream;
    ses:    TSession;
begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.AddUser');
{$ENDIF}
//Exit;
//aaIncCounter(counter2);
//aaWriteToLog('add user = '+IntToStr(aaGetCounter(counter2)));
  if (UserInfo.UserID = MSG_INVALID_USER_ID) then
   raise EMsgException.Create(11365,ErrorLInvalidUserID,[UserInfo.UserID]);
//  DB := CreateSessionDatabase;
  DB := FDatabase;
  ses := TSession.Create(nil);
  Table := TTable.Create(nil);
  try
    Ses.SessionName := 'Session_'+IntToStr(FCounter);
    Inc(FCounter);
//    db.Close;
//    db.SessionName := ses.SessionName;
//    db.Open;
//    db.Directory := FDatabase.Directory;
    Table.SessionName := ses.SessionName;
    Table.DatabaseName := FDatabase.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    bOK := False;
    cnt := FRetryCount;
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
{
       bs := Table.CreateBlobStream(Table.FieldByName('CryptoHeader'),bmWrite);
       try
         bs.WriteBuffer(PasswordHeader,SizeOf(PasswordHeader));
       finally
         bs.Free;
       end;
}
       Table.Post;
       DB.Commit;
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11360,ErrorLAddUserTransactionFailed,
       [UserInfo.UserID,FRetryCount,FDelay]);
  finally
    Table.Free;
//    Sessions.FindSession(DB.SessionName).Free;
    ses.Free;
//    DB.Free;
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.AddUser finished');
{$ENDIF}
{
aaWriteToLog(#13#10+
             'TMsgDatabaseParadox..AddUser: UserID = '+IntToStr(UserInfo.UserID)+#13#10+
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
procedure TMsgDatabaseParadox.RemoveUser(const UserID: Cardinal);
var DB:     TDatabase;
    uTable: TTable;
    cTable: TTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.RemoveUser, id = '+IntToStr(Integer(UserID)));
{$ENDIF}
  DB := CreateSessionDatabase;
  uTable := TTable.Create(nil);
  cTable := TTable.Create(nil);
  try
    DB.Open;
    uTable.DatabaseName := DB.DatabaseName;
    cTable.DatabaseName := DB.DatabaseName;
    uTable.TableName := UsersTableName;
    cTable.TableName := ContactsTableName;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
       uTable.Open;
       cTable.Open;
       uTable.IndexFieldNames := 'ID';
       if (not uTable.FindKey([Integer(UserID)])) then
        begin
          DB.Rollback;
          Exit;
        end;
       uTable.Delete;
       // delete user's contact list
       cTable.IndexFieldNames := 'OwnerID;ContactID';
       cTable.Filter := 'OwnerID = '+IntToStr(Integer(UserID));
       cTable.Filtered := True;
       cTable.First;
       while (not cTable.Eof) do
        begin
         cTable.Delete;
         cTable.First;
        end;
       cTable.Filtered := False;
       // delete user from other user's contact lists
       cTable.IndexName := 'ContactIDIndex';
       cTable.Filter := 'ContactID = '+IntToStr(Integer(UserID));
       cTable.Filtered := True;
       cTable.First;
       while (not cTable.Eof) do
        begin
         cTable.Delete;
         cTable.First;
        end;
       cTable.Filtered := False;

       DB.Commit;
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
  finally
    uTable.Free;
    cTable.Free;
    DB.Free;
    if (not bOK) and (cnt >= 0) then
     raise EMsgException.Create(11361,ErrorLUserDoesNotExist,[UserID]);
    if (not bOK) then
     raise EMsgException.Create(11362,ErrorLRemoveUserTransactionFailed,
       [UserID,FRetryCount,FDelay]);
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.RemoveUser finished');
{$ENDIF}
  end;
end; // RemoveUser


//------------------------------------------------------------------------------
// change user info and optionally password
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.ChangeUserInfo(UserInfo: TMsgUserInfo; ChangePassword: Boolean; PasswordHeader: TMsgCryptoHeader);
var DB:     TDatabase;
    Table:  TTable;
    bOK:    Boolean;
    cnt:    Integer;
    bs:     TStream;
begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.ChangeUserInfo');
{$ENDIF}
//Exit;
//aaIncCounter(counter2);
//aaWriteToLog('add user = '+IntToStr(aaGetCounter(counter2)));
  if (UserInfo.UserID = MSG_INVALID_USER_ID) then
   raise EMsgException.Create(11365,ErrorLInvalidUserID,[UserInfo.UserID]);
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
       Table.Open;
       Table.IndexFieldNames := 'ID';
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
           bs.WriteBuffer(PasswordHeader,SizeOf(PasswordHeader));
         finally
           bs.Free;
         end;
        end;
       Table.Post;
       DB.Commit;
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
       [UserInfo.UserID,FRetryCount,FDelay]);
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.ChangeUserInfo finished');
{$ENDIF}
  end;
end; // ChangeUserInfo


//------------------------------------------------------------------------------
// ChangeUserStatus
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.ChangeUserStatus(
                           const AllUsers:    Boolean;
                           const UserID:      Cardinal;
                           const Status:      TMsgUserStatus;
                           const Host:        String = '';
                           const Port:        Integer = 0;
                           const Application: String = ''
                          );

var DB:     TDatabase;
    Table:  TTable;
    bOK:    Boolean;
    cnt:    Integer;
    ses:    TSession;

procedure SetFields;
begin
 Table.Edit;
 Table.FieldByName('Status').AsInteger := Byte(Status);
 if (Status <> msgOffline) then
  begin
   Table.FieldByName('Application').AsString := Application;
   Table.FieldByName('Host').AsString := Host;
   Table.FieldByName('Port').AsInteger := Port;
  end;
 Table.Post;
end;


begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.ChangeUserStatus - UserID = '+IntToStr(Integer(UserID))
+', Status = '+IntToStr(Byte(Status))+', AllUsers = '+BoolToStr(AllUsers));
{$ENDIF}

//  DB := CreateSessionDatabase;
  DB := FDatabase;
  ses := TSession.Create(nil);
  Table := TTable.Create(nil);
  try
//    DB.Open;
    Ses.SessionName := 'Session_'+IntToStr(FCounter);
    Inc(FCounter);
//    db.Close;
//    db.SessionName := ses.SessionName;
//    db.Open;
//    db.Directory := FDatabase.Directory;
    Table.SessionName := ses.SessionName;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
       if (AllUsers) then
        begin
         Table.IndexName := 'StatusIndex';
         Table.Filtered := False;
         Table.Filter := 'Status > '+IntToStr(Integer(Status));
         Table.Filtered := True;
         Table.First;
         while not (Table.Eof) do
          begin
           SetFields;
           Table.Next;
          end;
        end
       else
        begin
         Table.IndexFieldNames := 'ID';
         if (not Table.FindKey([Integer(UserID)])) then
           begin
             DB.Rollback;
             Exit;
           end;
         SetFields;
        end;
       DB.Commit;
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
  finally
    Table.Free;
    ses.Free;
//    DB.Free;
    if (not bOK) then
     raise EMsgException.Create(11367,ErrorLChangeUserStatusTransactionFailed,
       [UserID,FRetryCount,FDelay]);
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog(IntToStr(aaGetTickCount));
aaWriteToLog('TMsgDatabaseParadox.ChangeUserStatus - UserID = '+IntToStr(Integer(UserID))
+', Status = '+IntToStr(Byte(Status))+', AllUsers = '+BoolToStr(AllUsers));
{$ENDIF}
  end;
end; // ChangeUserStatus


//------------------------------------------------------------------------------
// Get user info
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.GetUserInfo(const UserID: Cardinal): TMsgUserInfo;
var DB:     TDatabase;
    Table:  TTable;
begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.GetUserInfo - UserID = '+IntToStr(Integer(UserID)));
{$ENDIF}
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    Table.IndexFieldNames := 'ID';
    if (Table.FindKey([Integer(UserID)])) then
      Result := ExtractUserInfo(Table)
    else
      Result.UserID := MSG_INVALID_USER_ID;
  finally
    Table.Free;
    DB.Free;
  end;
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.GetUserInfo - UserID = '+IntToStr(Integer(UserID))+', UserInfo.UserID = '+IntToStr(Result.UserID));
{$ENDIF}
end; // GetUserInfo

//------------------------------------------------------------------------------
// returns users count
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.GetUsersCount: Integer;
begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.GetUsersCount');
{$ENDIF}
  Result := FUsersTable.RecordCount;
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.GetUsersCount, result = ' + IntToStr(Result));
{$ENDIF}
end; // GetUsersCount


//------------------------------------------------------------------------------
// Return PasswordHeader
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.GetPasswordHeader(const UserID: Cardinal): TMsgCryptoHeader;
var DB:     TDatabase;
    Table:  TTable;
    bs:     TStream;
begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('MsgDatabaseParadox.GetPasswordHeader - UserID = '+IntToStr(Integer(UserID)));
{$ENDIF}
//Result.CryptoAlgorithm := 0;
//Exit;
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := UsersTableName;
    Table.Open;
    Table.IndexFieldNames := 'ID';
    if (Table.FindKey([Integer(UserID)])) then
     begin
      bs := Table.CreateBlobStream(Table.FieldByName('CryptoHeader'),bmRead);
      try
        bs.ReadBuffer(Result,SizeOf(Result));
      finally
        bs.Free;
      end;
     end
    else
     raise EMsgException.Create(11401,ErrorLUserDoesNotExist,[UserID]);
  finally
    Table.Free;
    DB.Free;
  end;
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.GetPasswordHeader - UserID = '+IntToStr(Integer(UserID))+' ok');
{$ENDIF}
end; // GetPasswordHeader


//------------------------------------------------------------------------------
// Return true if user exists
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.UserExists(const UserID: Cardinal): Boolean;
begin
  Result := GetUserExists(UserID);
end; // UserExists


//------------------------------------------------------------------------------
// Get users
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.GetUsers(var Users: TMsgUserInfoArray; const SortBy: TMsgUserInfoArraySortBy; const Ascending: Boolean);
var DB:     TDatabase;
    Query:  TQuery;
    s,s1:   String;
    i:      Integer;
begin
  DB := CreateSessionDatabase;
  Query := TQuery.Create(nil);
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
procedure TMsgDatabaseParadox.FindUsers(
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
                    SearchCondition:              String = ''; // SQL WHERE clause without word WHERE
                    // ORDER BY columns without ORDER BY words
                    // example: SenderID DESC, SendingDate ASC
                    SortBy:                       TMsgUserInfoArraySortBy = msgusbNone;
                    Ascending:                    Boolean = True;
                    OrderByClause:                String = ''
                       );
var DB:         TDatabase;
    Query:      TQuery;
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
  DB := CreateSessionDatabase;
  Query := TQuery.Create(nil);
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
// Get user contacts (array of UserID)
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.GetUserContacts(const UserID: Cardinal; var Contacts: TMsgContactInfoArray);
var DB:     TDatabase;
    uTable: TTable;
    cTable: TTable;
    i:      Integer;
begin
  DB := CreateSessionDatabase;
  uTable := TTable.Create(nil);
  cTable := TTable.Create(nil);
  try
    DB.Open;
    uTable.DatabaseName := DB.DatabaseName;
    cTable.DatabaseName := DB.DatabaseName;
    uTable.TableName := UsersTableName;
    cTable.TableName := ContactsTableName;
    uTable.Open;
    cTable.Open;
    uTable.IndexFieldNames := 'ID';
    cTable.IndexFieldNames := 'OwnerID;ContactID';
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
function TMsgDatabaseParadox.GetUserContactCount(UserID: Cardinal): Integer;
var DB:     TDatabase;
    Table:  TTable;
begin
//Exit;
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.GetUserContactCount, id = '+IntToStr(Integer(UserID)));
{$ENDIF}
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
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
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.GetUserContactCount, result = '+IntToStr(Result));
{$ENDIF}
  end;
end; // GetUserContactCount


//------------------------------------------------------------------------------
// return true if UserID is in contact list of OwnerUserID
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.IsUserInContacts(UserID,OwnerUserID: Cardinal): Boolean;
var DB:     TDatabase;
    Table:  TTable;
begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.IsUserInContacts, UserID = '+IntToStr(Integer(UserID))
  +#13#10+'OwnerUserID = '+IntToStr(OwnerUserID));
{$ENDIF}
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := ContactsTableName;
    Table.Open;
    Table.IndexFieldNames := 'OwnerID;ContactID';
    Result := Table.FindKey([Integer(OwnerUserID),Integer(UserID)]);
  finally
    Table.Free;
    DB.Free;
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.IsUserInContacts, result = '+BoolToStr(Result,true));
{$ENDIF}
  end;
end; // IsUserInContacts


//------------------------------------------------------------------------------
// Add user to contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.AddUserToContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                                                  );
var DB:     TDatabase;
    Table:  TTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := ContactsTableName;
    Table.Open;
    bOK := False;
    cnt := FRetryCount;
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
       DB.Commit;
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11370,ErrorLAddContactTransactionFailed,
       [OwnerUserID,ContactUserID,FRetryCount,FDelay]);
  finally
    Table.Free;
    DB.Free;
  end;
end; // AddUserToContacts


//------------------------------------------------------------------------------
// update user in contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.UpdateUserInContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                                                  );
var DB:     TDatabase;
    Table:  TTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := ContactsTableName;
    Table.Open;
    Table.IndexFieldNames := 'OwnerID;ContactID';
    bOK := False;
    cnt := FRetryCount;
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
       DB.Commit;
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11492,ErrorLUpdateContactTransactionFailed,
       [OwnerUserID,ContactUserID,FRetryCount,FDelay]);
  finally
    Table.Free;
    DB.Free;
  end;
end; // UpdateUserInContacts


//------------------------------------------------------------------------------
// Remove user from contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.RemoveUserFromContacts(
                                  const OwnerUserID: Cardinal;
                                  const ContactUserID: Cardinal);
var DB:     TDatabase;
    Table:  TTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := ContactsTableName;
    Table.Open;
    Table.IndexName := 'ContactsPK';
    bOK := False;
    cnt := FRetryCount;
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
       DB.Commit;
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11373,ErrorLRemoveUserFromContactsTransactionFailed,
       [OwnerUserID,ContactUserID,FRetryCount,FDelay]);
   finally
    Table.Free;
    DB.Free;
  end;
end; // RemoveUserFromContacts


//------------------------------------------------------------------------------
// saves message to database and returns MessageID
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.SaveMessage(
                     const Delivered:           Boolean; // for commands
                     const DeliveryDate:        TDateTime;
                     const SenderID,
                           RecipientID:         Cardinal;
                     const MessageType:         TMsgMessageType;
                     const SendingDate:         TDateTime;
                     const MessageData:         PChar; // binary o stream message data
                     const MessageDataSize:     Integer; // size of MessageData
                     const MessageText:         String; // text of the message
                     const MessageUnicodeText:  WideString; // unicode text of the message
                     const Command:             Cardinal = 0 // no command
                    ): Integer;

var DB:     TDatabase;
    Table:  TTable;
    bOK:    Boolean;
    cnt:    Integer;
    bs:     TStream;
begin
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.SaveMessage - SenderID = '+IntToStr(Integer(SenderID))+
', RecipientID = '+IntToStr(Integer(RecipientID)));
{$ENDIF}
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := MessagesTableName;
    Table.Open;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      StartTransaction(DB);
      try
{$IFDEF DEBUG_DB_PARADOX}
//aaWriteToLog('TMsgDatabaseParadox.SaveMessage '+'- SenderID = '+IntToStr(Integer(SenderID))+' - INSERT: '+#13#10+Query.SQL.Text);
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
//       if (MessageUnicodeText <> '') then
//        Table.SetWideMemoField(Table.FieldByName('MessageUnicodeText'),MessageUnicodeText);
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
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.SaveMessage '+'- SenderID = '+IntToStr(Integer(SenderID))+' - result = : '+IntToStr(Result));
{$ENDIF}
       DB.Commit;
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11379,ErrorLSaveMessageFailed,
       [SenderID,RecipientID,Byte(MessageType),MessageText,MessageDataSize,FRetryCount,FDelay]);
{$IFDEF DEBUG_DB_PARADOX}
aaWriteToLog('TMsgDatabaseParadox.SaveMessage - SenderID = '+IntToStr(Integer(SenderID)));
{$ENDIF}
  finally
    Table.Free;
    DB.Free;
  end;
end; // SaveMessage


//------------------------------------------------------------------------------
// set message delivery date = CURRENT_TIMESTAMP and delivered = true
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.SetMessageDeliveryDate(MessageID: Integer);
var DB:     TDatabase;
    Table:  TTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := MessagesTableName;
    Table.IndexName := 'MessagesPK';
    bOK := False;
    cnt := FRetryCount;
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
       DB.Commit;
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11380,ErrorLSetMessageDeliveryDateFailed,
       [MessageID,FRetryCount,FDelay]);
  finally
    Table.Free;
    DB.Free;
  end;
end; // SetMessageDeliveryDate


//------------------------------------------------------------------------------
// delete message
//------------------------------------------------------------------------------
procedure TMsgDatabaseParadox.DeleteMessage(MessageID: Integer);
var DB:     TDatabase;
    Table:  TTable;
    bOK:    Boolean;
    cnt:    Integer;
begin
  DB := CreateSessionDatabase;
  Table := TTable.Create(nil);
  try
    DB.Open;
    Table.DatabaseName := DB.DatabaseName;
    Table.TableName := MessagesTableName;
    Table.IndexName := 'MessagesPK';
    bOK := False;
    cnt := FRetryCount;
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
       DB.Commit;
       bOK := True;
      except
       DB.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11387,ErrorLDeleteMessageFailed,
       [MessageID,FRetryCount,FDelay]);
  finally
    Table.Free;
    DB.Free;
  end;
end; // DeleteMessage


//------------------------------------------------------------------------------
// return new query object with found messages from MsgMessages table
//------------------------------------------------------------------------------
function TMsgDatabaseParadox.FindMessages(
                         const MessageTextComparison:         TMsgTextComparison;
                         const MessageUnicodeTextComparison:  TMsgTextComparison;
                         const SendingDate:                   TMsgDateComparison;
                         const DeliveryDate:                  TMsgDateComparison;
                         const SearchDelivered:               Boolean;
                         const Delivered:                     Boolean = True;
                         // text of the message
                         const MessageText:                   String = '';
                         // unicode text of the message
                         const MessageUnicodeText:            WideString = '';
                         const SenderID:                      Cardinal = MSG_INVALID_USER_ID;
                         const RecipientID:                   Cardinal = MSG_INVALID_USER_ID;
                         const MessageType:                   TMsgMessageType = aamtNone;
                         // size of MessageData
                         const MessageDataSize:               Integer = -1;
                         const OrderBySendingDate:            Boolean = False;
                         const OrderByClause:                 String = '';
                         // no condition on command field if TMsgMessageType = aamtNone
                         const Command:                       Cardinal = 0
                        ): TDataset;
var
    Query:  TQuery;
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
     d_cond := ''''+ConvertDateTimeToString(DateComp.DateTime1)+'''';
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
     d_cond := ''''+ConvertDateTimeToString(DateComp.DateTime2)+'''';
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

  procedure AddCondition(newCondition: String);
  begin
   if (condition = '') then
    condition := newCondition
   else
    condition := condition + ' AND '+ newCondition;
  end; // AddCondition

begin
  Query := TQuery.Create(nil);
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
   raise EMsgException.Create(11381,ErrorLFindMessageFailed,
     [Query.SQL.Text,FRetryCount,FDelay]);
end; // FindMessages


//------------------------------------------------------------------------------
// convert dt to quoted string using time stamp MM/DD/YYYY HH24:NN:SS
//------------------------------------------------------------------------------
function ConvertDateTimeToString(dt: TDateTime): String;
//var d,m,y,h,n,s,z: Word;
begin
  Result := DateTimeToStr(dt);
// DecodeDateTime(dt,y,m,d,h,n,s,z);
// Result := Format('%4.4u-%2.2u-%2.2u %2.2u:%2.2u:%2.2u',[y,m,d,h,n,s]);
end; // ConvertDateTimeToString


{$IFDEF TRIAL_VERSION}

//------------------------------------------------------------------------------
// callback function to enumerate all open windows
//------------------------------------------------------------------------------
Function MsgWindowCallback(WHandle : HWnd; Var Parm : Pointer) : Boolean;
          stdcall;
{This function is called once for each window}
 Var MyString : PChar;
begin

    {Window text}
    MyString := Allocmem(255);
    GetWindowText(WHandle,MyString,255);
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
aaWriteToLog('MsgDatabaseParadox> initialization started');
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
        (Pos('Borland Developer Studio',WindowLst[i]) > 0) or
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
aaWriteToLog('MsgDatabaseParadox> initialization finished');
{$ENDIF}


end.

