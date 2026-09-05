// If you need to access server message history from client you should download
// SQLMemTable temporary table component and SQLMemTable itself from our web site:
// http://www.aidaim.com/products/download.php#MSG
// http://www.aidaim.com/products/download.php#sqlmemtable

{$WARNINGS OFF}
{$HINTS OFF}

unit MsgDatabaseMySQL;

interface


{$I MsgDBmysqlVer.inc}

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
DBTables,

{$IFDEF DB_EXPRESS}
DBXpress, SqlExpr,
{$ENDIF}

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

 const MsgModuleVersion = 2.60;
 const MsgModuleVersionText = '';

// SQL script for creating all tables on server side (SQL syntax of mySQL)
// on client only MsgMessages table needed for storing local message history
{
CREATE TABLE `msgusers` (
  `ID` int(11) NOT NULL default '0',
  `UserName` varChar(255) default NULL,
  `FirstName` varChar(255) default NULL,
  `LastName` varChar(255) default NULL,
  `Organization` varChar(255) default NULL,
  `Department` varChar(255) default NULL,
  `Status` tinyint(3) unsigned default NULL,
  `LogonTime` datetime default NULL,
  `LogoffTime` datetime default NULL,
  `Host` varChar(255) default NULL,
  `Port` int(11) default NULL,
  `Application` varChar(255) default NULL,
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
  `ContactCustomName` varChar(255) default NULL,
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
// TMsgMySQLQuery
//
////////////////////////////////////////////////////////////////////////////////


  TMsgMySQLQuery = class (TComponent)
   private
    FNewSession:      Boolean;
    FDatabase:        TDatabase;
    FQuery:           TQuery;
    FSession:         TSession;
    FSQL:             AnsiString;
    FParams:          TParams;
{$IFDEF DB_EXPRESS}
    FSQLConnection:   TSQLConnection;
    FSQLQuery:        TSQLQuery;
    FTransactionDesc: TTransactionDesc;
{$ENDIF}
   protected
    function GetRequestLive: Boolean;
    procedure SetRequestLive(Value: Boolean);
    procedure SetSQLText(Value: AnsiString);
    procedure SetParamsList(Value: TParams);
    procedure Prepare;
    function ParamByName(const Value: AnsiString): TParam;
    function GetDataset: TDataset;
    function TableExists(const TableName: AnsiString): Boolean;
   public
    constructor Create(
                       AOwner:           TComponent;
                       CreateNewSession: Boolean = False
                       ); overload;
    destructor Destroy; override;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
    procedure ExecSQL;
   public
    property SQLText: AnsiString read FSQL write SetSQLText;
    property Params: TParams read FParams;
    property Dataset: TDataset read GetDataset;
    property RequestLive: Boolean read GetRequestLive write SetRequestLive;
  end; // TMsgMySQLQuery



////////////////////////////////////////////////////////////////////////////////
//
// TMsgDatabaseMySQL
//
////////////////////////////////////////////////////////////////////////////////

 TMsgDatabaseMySQL = class (TMsgDatabase)
  private
   FDatabase:       TDatabase;
{$IFDEF DB_EXPRESS}
   FSQLConnection:  TSQLConnection;
{$ENDIF}
   FDelay:          Integer;
   FRetryCount:     Integer;
   FTableType:      AnsiString;
   FNewSession:     Boolean;
  protected
   function GetMainVersion: AnsiString; override;
   function GetModuleVersion: AnsiString; override;
   procedure SetDatabase(Value: TDatabase);
{$IFDEF DB_EXPRESS}
   procedure SetSQLConnection(Value: TSQLConnection);
{$ENDIF}
   function GetTablesExists(HistoryOnly: Boolean): Boolean; override;
   procedure CreateTables(HistoryOnly: Boolean); override;
   procedure OpenDatabase; override;
   procedure GetInsertUserSQL(Query: TMsgMySQLQuery; UserInfo: TMsgUserInfo; PasswordHeader: TMsgCryptoHeader);
   procedure GetUpdateUserSQL(Query: TMsgMySQLQuery; UserInfo: TMsgUserInfo; ChangePassword: Boolean; PasswordHeader: TMsgCryptoHeader);
   function ExtractUserInfo(Dataset: TDataset): TMsgUserInfo;
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
   property Database: TDatabase read FDatabase write SetDatabase;
{$IFDEF DB_EXPRESS}
   property SQLConnection: TSQLConnection read FSQLConnection write SetSQLConnection;
{$ENDIF}
   property Delay: Integer read FDelay write FDelay;
   property RetryCount: Integer read FRetryCount write FRetryCount;
   property TableType: AnsiString read FTableType write FTableType;
 end; // TMsgDatabaseMySQL


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
     {$IFDEF DB_EXPRESS}
     DateUtils,
     {$ENDIF}
     {$IFDEF MSWINDOWS}
     Registry,
     {$ENDIF}
     MsgDECUtil, MsgCipher;
{$ELSE}
     {$IFDEF DB_EXPRESS}
      uses DateUtils;
     {$ENDIF}
{$ENDIF}


{$IFNDEF DB_EXPRESS}
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
// Result := 'MsgCommunicator MySQL Database Module Trial Version - ';
end;

function msgtrnm1: AnsiString;
begin
{
  Result :=
             'This is the trial version of MsgCommunicator MySQL Database Module by'#13+
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
 Result := 'BEDAEC896E0AB355805CD85A1A801CF72DE3030DC652D897BD44E906B7625ABEA5EE3099BF9418AC3C4881DFBCD2AF381946FFE96AE6';
end;

function msgtrnm: AnsiString;
begin
  Result :=
            '85342E20DE20E32E63B4D63D05BD5E020874B2B2E2B760F71FBF3643793892A888AEBAF9BA2EB69FFAD7DDD1E1D099BA78773B15294C3ADC33D3967BB401DCE479F066F780CFE1F260D51A1A0B6AEFF4DD'
           +'178C30549DE897E74D2A9D5B02BA605A8E8CF0AAB3EB0BEAB07A54421F3ECE7B5FFFEB81C1B7B858066D140B2645E0F3A3A419E9DD3DB908627B6C79A89E7A49AFD082858A4A16CFE72C99FE8AB3A16F31'
           +'1F6E469C5CF8FA14273570CA4E7FE43501B5CFD6F78A6F65A44A480ADDF2A0086BC4C90BF98CFEC495E109909B0D64B4639EBA0EF90AE79277162184F51563F9C44DB6CAED2CCF7658D3E9F3D6BA90D937'
           +'FBEFF82962D51EFADE3B2753C004A565561369F694716AA2FC892C627FEE0AA453010E8238E0EF910D0868F79E9FC09D86C5C40B47C1703F4FDFD5BB4B8AA3708B6C8F30166117458D8A4E359870FEE232'
           +'7CBFAA403D12AD38969BDEC0B58A3D6539C211CA555EC265C645FEB7C619D490172704B45D4B6B2E308C39D6E753A2897336A771A7B7C435C788EE9B69F845AF82F3A55646DF56E6E1C482BBBC3A49FD9F'
           +'EA4CCEE9C27FB0B807173D550485F888729109B8B941D3762C8668AC6CB30DB4F2B2C8C2009FAF580749194CE9C1AAA144EA0FBDCC6F421E1D415FDAECDAB77EE3D882A480FCD93B1EB7A9ED7098F1F093'
           +'0A339DA105E57C7CE3413741C848DB6AD993F2DD3AA152361268ABF0D9EA21511EA081906FFB7FCA6F023CB8C939823E99911D5FD13A83B95A7BD68CFB6CB592F2D114924386632B283E19B4D608198056069929BEFAA93DD1FC9D0898084830A0B8667CA17660A9865413106E92A9508C4DF4'
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
// TMsgMySQLQuery
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return request live
//------------------------------------------------------------------------------
function TMsgMySQLQuery.GetRequestLive: Boolean;
begin
 Result := False;
 if (FQuery <> nil) then
  Result := FQuery.RequestLive
 else
  begin
{$IFDEF DB_EXPRESS}
   if (FSQLQuery <> nil) then
    Result := False;
{$ENDIF}
  end;
end; // SetQuery


//------------------------------------------------------------------------------
// set request live
//------------------------------------------------------------------------------
procedure TMsgMySQLQuery.SetRequestLive(Value: Boolean);
begin
 if (FQuery <> nil) then
  FQuery.RequestLive := Value;
end; // SetQuery


//------------------------------------------------------------------------------
// Set query
//------------------------------------------------------------------------------
procedure TMsgMySQLQuery.SetSQLText(Value: AnsiString);
begin
 if (FQuery <> nil) then
  FQuery.SQL.Text := Value
 else
  begin
{$IFDEF DB_EXPRESS}
   if (FSQLQuery <> nil) then
    FSQLQuery.SQL.Text := Value;
{$ENDIF}
  end;
end; // SetSQLText


//------------------------------------------------------------------------------
// Set params
//------------------------------------------------------------------------------
procedure TMsgMySQLQuery.SetParamsList(Value: TParams);
begin
 if (FQuery <> nil) then
  FQuery.Params.AssignValues(Value)
 else
  begin
{$IFDEF DB_EXPRESS}
   if (FSQLQuery <> nil) then
    FSQLQuery.Params.AssignValues(Value);
{$ENDIF}
  end;
end; // SetParamsList


//------------------------------------------------------------------------------
// Prepare
//------------------------------------------------------------------------------
procedure TMsgMySQLQuery.Prepare;
begin
 if (FQuery <> nil) then
  FQuery.Prepare;
end; // Prepare


//------------------------------------------------------------------------------
// Get param by name
//------------------------------------------------------------------------------
function TMsgMySQLQuery.ParamByName(const Value: AnsiString): TParam;
begin
  if (FQuery <> nil) then
    Result := FQuery.ParamByName(Value)
  else
   begin
    Result := nil;
{$IFDEF DB_EXPRESS}
    if (FSQLQuery <> nil) then
     Result := FSQLQuery.ParamByName(Value);
{$ENDIF}
   end;
end; // ParamByName


//------------------------------------------------------------------------------
// return dataset
//------------------------------------------------------------------------------
function TMsgMySQLQuery.GetDataset: TDataset;
begin
  if (FQuery <> nil) then
    Result := FQuery
  else
   begin
    Result := nil;
{$IFDEF DB_EXPRESS}
    if (FSQLQuery <> nil) then
     Result := FSQLQuery;
{$ENDIF}
   end;
end; // GetDataset


//------------------------------------------------------------------------------
// return true if table exists
//------------------------------------------------------------------------------
function TMsgMySQLQuery.TableExists(const TableName: AnsiString): Boolean;
var sl: TStringList;
begin
  sl := TStringList.Create;
  try
    if (FDatabase <> nil) then
     begin
      {$IFDEF DB_EXPRESS}
      FDatabase.GetTableNames(sl,False);
      {$ELSE}
      if (FDatabase.Session <> nil) then
       FDatabase.Session.GetTableNames(FDatabase.DatabaseName,'',True,True,sl);
      {$ENDIF}
     end
    else
     begin
      Result := False;
  {$IFDEF DB_EXPRESS}
     try
      if (FSQLConnection <> nil) then
       FSQLConnection.GetTableNames(sl,False);
     except
     end;
  {$ENDIF}
     end;
    FixTableNames(sl);
    Result := (sl.IndexOf(TableName) >= 0);
  finally
    sl.Free;
  end;
end; // TableExists


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgMySQLQuery.Create(
                       AOwner:           TComponent;
                       CreateNewSession: Boolean = False
                       );
begin
  inherited Create(AOwner);
  FNewSession := CreateNewSession;
  FDatabase := nil;
  FSession := nil;
  FQuery := nil;
  {$IFDEF DB_EXPRESS}
  FSQLConnection := nil;
  FSQLQuery := nil;
  FParams := nil;
  FSQL := '';
  if (TMsgDatabaseMySQL(Owner).SQLConnection <> nil) then
   begin
    if (FNewSession) then
     begin
      FSQLConnection := TSQLConnection.Create(AOwner);
      FSQLConnection.ConnectionName := TMsgDatabaseMySQL(Owner).SQLConnection.ConnectionName;
      FSQLConnection.DriverName := TMsgDatabaseMySQL(Owner).SQLConnection.DriverName;
      FSQLConnection.GetDriverFunc := TMsgDatabaseMySQL(Owner).SQLConnection.GetDriverFunc;
      FSQLConnection.LibraryName := TMsgDatabaseMySQL(Owner).SQLConnection.LibraryName;
      FSQLConnection.VendorLib := TMsgDatabaseMySQL(Owner).SQLConnection.VendorLib;
      FSQLConnection.Params.Assign(TMsgDatabaseMySQL(Owner).SQLConnection.Params);
      FSQLConnection.LoginPrompt := TMsgDatabaseMySQL(Owner).SQLConnection.LoginPrompt;
     end
    else
     begin
      FSQLConnection := TMsgDatabaseMySQL(Owner).SQLConnection;
     end;
    FSQLQuery := TSQLQuery.Create(FSQLConnection);
    FSQLQuery.SQLConnection := FSQLConnection;
    FParams := FSQLQuery.Params;
    FSQL := FSQLQuery.SQL.Text;
   end;
  {$ENDIF}
  if (TMsgDatabaseMySQL(Owner).Database <> nil) then
   begin
    if (FNewSession) then
     begin
      FDatabase := TDatabase.Create(AOwner);
      try
       if (TMsgDatabaseMySQL(Owner).Database.Directory <> '') then
        FDatabase.Directory := TMsgDatabaseMySQL(Owner).Database.Directory;
      except
      end;
      FDatabase.DatabaseName := 'TempDB_'+IntToStr(Random(MaxInt));
      if (TMsgDatabaseMySQL(Owner).Database.AliasName <> '') then
       FDatabase.AliasName := TMsgDatabaseMySQL(Owner).Database.AliasName;
      if (TMsgDatabaseMySQL(Owner).Database.DriverName <> '') then
       FDatabase.DriverName := TMsgDatabaseMySQL(Owner).Database.DriverName;
      FDatabase.LoginPrompt := TMsgDatabaseMySQL(Owner).Database.LoginPrompt;
      FDatabase.Params.Assign(TMsgDatabaseMySQL(Owner).Database.Params);
      FSession := TSession.Create(AOwner);
      FSession.SessionName := 'MsgSession_'+IntToStr(Random(MaxInt));
      FDatabase.SessionName := FSession.SessionName;
      FDatabase.Open;
     end
    else
     begin
      FDatabase := TMsgDatabaseMySQL(Owner).Database;
     end;
    FQuery := TQuery.Create(FDatabase);
    FQuery.DatabaseName := FDatabase.DatabaseName;
    if (FNewSession) then
     FQuery.SessionName := FSession.SessionName;
    FParams := FQuery.Params;
    FSQL := FQuery.SQL.Text;
   end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgMySQLQuery.Destroy;
begin
  {$IFDEF DB_EXPRESS}
  if (FSQLConnection <> nil) then
   begin
    if (FSQLQuery <> nil) then
     FSQLQuery.Free;
    if (FNewSession) then
      FSQLConnection.Free;
    FSQLQuery := nil;
    FSQLConnection := nil;
   end;
  {$ENDIF}
  if (FDatabase <> nil) then
   begin
    if (FQuery <> nil) then
     begin
      FQuery.Free;
     end;
    if (FNewSession) then
     begin
      FDatabase.Free;
      FSession.Free;
     end;
    FQuery := nil;
    FDatabase := nil;
    FSession := nil;
    FSQL := '';
   end;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Start transaction
//------------------------------------------------------------------------------
procedure TMsgMySQLQuery.StartTransaction;
var bOK:            Boolean;
    InTransacation: Boolean;
begin
  bOK := False;
  while (not bOK) do
   begin
    if (FDatabase <> nil) then
     InTransacation := FDatabase.InTransaction
    else
     begin
{$IFDEF DB_EXPRESS}
      InTransacation := FSQLConnection.InTransaction;
      FTransactionDesc.TransactionID := 1;
      FTransactionDesc.IsolationLevel := xilREADCOMMITTED;
{$ELSE}
      InTransacation := False;
      break;
{$ENDIF}
     end;
    if (not InTransacation) then
     try
       if (FDatabase <> nil) then
        FDatabase.StartTransaction
       else
        begin
{$IFDEF DB_EXPRESS}
         FSQLConnection.StartTransaction(FTransactionDesc);
{$ENDIF}
        end;
       bOK := True;
     except
       bOK := False;
     end;
    if (not bOK) then
     Sleep(TMsgDatabaseMySQL(Owner).Delay);
   end;
end; // StartTransaction


//------------------------------------------------------------------------------
// Commit
//------------------------------------------------------------------------------
procedure TMsgMySQLQuery.Commit;
begin
  if (FDatabase <> nil) then
   FDatabase.Commit
  else
   begin
{$IFDEF DB_EXPRESS}
    FSQLConnection.Commit(FTransactionDesc);
{$ENDIF}
   end;
end; // Commit


//------------------------------------------------------------------------------
// Rollback
//------------------------------------------------------------------------------
procedure TMsgMySQLQuery.Rollback;
begin
  if (FDatabase <> nil) then
   FDatabase.Rollback
  else
   begin
{$IFDEF DB_EXPRESS}
    FSQLConnection.Rollback(FTransactionDesc);
{$ENDIF}
   end;
end; // Rollback


//------------------------------------------------------------------------------
// Execute SQL script
//------------------------------------------------------------------------------
procedure TMsgMySQLQuery.ExecSQL;
begin
  if (FDatabase <> nil) then
   FQuery.ExecSQL
  else
   begin
{$IFDEF DB_EXPRESS}
    FSQLQuery.ExecSQL;
{$ENDIF}
   end;
end; // ExecSQL


////////////////////////////////////////////////////////////////////////////////
//
// TMsgDatabaseMySQL
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return Version of the MsgCommunicator
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.GetMainVersion: AnsiString;
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
function TMsgDatabaseMySQL.GetModuleVersion: AnsiString;
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
procedure TMsgDatabaseMySQL.SetDatabase(Value: TDatabase);
begin
  FDatabase := Value;
{$IFDEF DB_EXPRESS}
  if (FDatabase <> nil) then
   FSQLConnection := nil;
{$ENDIF}
end; // SetDatabase


{$IFDEF DB_EXPRESS}
//------------------------------------------------------------------------------
// Set SQLConnection
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.SetSQLConnection(Value: TSQLConnection);
begin
  FSQLConnection := Value;
  if (FSQLConnection <> nil) then
   FDatabase := nil;
end; // SetSQLConnection
{$ENDIF}

//------------------------------------------------------------------------------
// Return true if all tables exists
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.GetTablesExists(HistoryOnly: Boolean): Boolean;
var sl: TStringList;
begin
  sl := TStringList.Create;
  try
   if (FDatabase <> nil) then
    {$IFDEF DB_EXPRESS}
    FDatabase.GetTableNames(sl,False);
    {$ELSE}
    if (FDatabase.Session <> nil) then
     FDatabase.Session.GetTableNames(FDatabase.DatabaseName,'',True,True,sl);
    {$ENDIF}
  {$IFDEF DB_EXPRESS}
    try
     if (FSQLConnection <> nil) then
      FSQLConnection.GetTableNames(sl,False);
    except
    end;
  {$ENDIF}
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
procedure TMsgDatabaseMySQL.CreateTables(HistoryOnly: Boolean);
var s:              AnsiString;
    FQuery:         TMsgMySQLQuery;
begin
  if (FDatabase = nil)
{$IFDEF DB_EXPRESS}
     and (FSQLConnection = nil)
{$ENDIF}
     then
   raise EMsgException.Create(11584,ErrorLMySQLDatabaseIsNotAssigned);
 FQuery := TMsgMySQLQuery.Create(Self,False);
 try
   if (not HistoryOnly) then
    begin
     if (FQuery.TableExists(UsersTableName)) then
      begin
       FQuery.SQLText := 'DROP TABLE '+UsersTableName+crlf;
       FQuery.ExecSQL;
      end;
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
     FQuery.SQLText := s;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX UserNameIndex ON '+UsersTableName+' (UserName)'+crlf;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX FirstNameIndex ON '+UsersTableName+' (FirstName)'+crlf;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX LastNameIndex ON '+UsersTableName+' (LastName)'+crlf;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX OrganizationIndex ON '+UsersTableName+' (Organization)'+crlf;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX DepartmentIndex ON '+UsersTableName+' (Department)'+crlf;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX HostIndex ON '+UsersTableName+' (Host)'+crlf;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX PortIndex ON '+UsersTableName+' (Port)'+crlf;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX ApplicationIndex ON '+UsersTableName+' (Application)'+crlf;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX StatusIndex ON '+UsersTableName+' (Status)';
     FQuery.ExecSQL;

     if (FQuery.TableExists(ContactsTableName)) then
      begin
       FQuery.SQLText :=  'DROP TABLE '+ContactsTableName;
       FQuery.ExecSQL;
      end;
     s := 'CREATE TABLE '+ContactsTableName + ' ('+crlf+
          // id in Users of the contact list owner
          'OwnerID Integer NOT NULL,'+crlf+
          // id in Users of the person in contact list
          'ContactID Integer NOT NULL,'+crlf+
          // source of the name: UserName, FirstName, LastName, FirstName LastName, Custom,  etc.
          'ContactNameSource TinyInt Unsigned,'+crlf+
          // contact custom name
          'ContactCustomName varChar(255),'+crlf+
          'PRIMARY KEY ContactsPK (OwnerID,ContactID)'+ crlf+
          ')'+crlf;
     FQuery.SQLText := s;
     FQuery.ExecSQL;
     FQuery.SQLText := 'CREATE INDEX ContactIDIndex ON '+ContactsTableName+' (ContactID)'+crlf;
     FQuery.ExecSQL;
    end;
   if (FQuery.TableExists(MessagesTableName)) then
    begin
     FQuery.SQLText := 'DROP TABLE '+MessagesTableName;
     FQuery.ExecSQL;
    end;
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
    FQuery.SQLText := s;
    FQuery.ExecSQL;
    FQuery.SQLText := 'ALTER TABLE '+MessagesTableName+' ADD INDEX SenderIDIndex (SenderID)';
    FQuery.ExecSQL;
    FQuery.SQLText := 'ALTER TABLE '+MessagesTableName+' ADD INDEX RecipientIDIndex (RecipientID)';
    FQuery.ExecSQL;

//    FQuery.SQLText := 'CREATE FULLTEXT INDEX MessageTextIndex ON '+ContactsTableName+' (MessageText)'+crlf;
//    FQuery.ExecSQL;
 finally
   FQuery.Free;
 end;
end; // CreateTables


//------------------------------------------------------------------------------
// OpenDatabase
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.OpenDatabase;
var    Query:         TMsgMySQLQuery;
       s:              AnsiString;
begin
  FCloseDB := False;
  if (FDatabase = nil)
{$IFDEF DB_EXPRESS}
     and (FSQLConnection = nil)
{$ENDIF}
     then
   raise EMsgException.Create(11585,ErrorLMySQLDatabaseIsNotAssigned);
 if (FDatabase <> nil) then
  if (not FDatabase.Connected) then
    begin
     FDatabase.Open;
     FCloseDB := True;
    end;
{$IFDEF DB_EXPRESS}
 if (FSQLConnection <> nil) then
  if (not FSQLConnection.Connected) then
    begin
     FSQLConnection.Open;
     FCloseDB := True;
    end;
{$ENDIF}
  if (GetTablesExists(false)) then
   begin
    Query := TMsgMySQLQuery.Create(Self,false);
    try
      Query.SQLText := 'SHOW CREATE TABLE '+UsersTableName;
      Query.Dataset.Open;
      Query.Dataset.First;
      if (not Query.Dataset.Eof) then
       begin
        s := LowerCase(Query.Dataset.Fields[1].AsString);
        if (Pos('logontime',s) = 0) then
         begin
          Query.Dataset.Close;
          Query.SQLText := 'ALTER TABLE '+UsersTableName+' ADD (LogonTime DateTime, LogoffTime DateTime)';
          Query.ExecSQL;
         end;
       end;
    finally
      Query.Free;
    end;
    Query := TMsgMySQLQuery.Create(Self,false);
    try
       Query.SQLText := 'SHOW CREATE TABLE '+MessagesTableName;
       Query.Dataset.Open;
       Query.Dataset.First;
       if (not Query.Dataset.Eof) then
        begin
         s := LowerCase(Query.Dataset.Fields[1].AsString);
         if (Pos('senderidindex',s) = 0) then
          begin
           Query.Dataset.Close;
           Query.SQLText := 'ALTER TABLE '+MessagesTableName+' ADD INDEX SenderIDIndex (SenderID)';
           Query.ExecSQL;
           Query.SQLText := 'ALTER TABLE '+MessagesTableName+' ADD INDEX RecipientIDIndex (RecipientID)';
           Query.ExecSQL;
          end;
        end;
    finally
       Query.Free;
    end;
   end;
end; // OpenDatabase


//------------------------------------------------------------------------------
// Create SQL script for adding user
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.GetInsertUserSQL(
                                Query:    TMsgMySQLQuery;
                                UserInfo: TMsgUserInfo;
                                PasswordHeader: TMsgCryptoHeader);
begin
 Query.SQLText := 'INSERT INTO '+UsersTableName+
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
 Query.Prepare;
 if (PasswordHeader.CryptoAlgorithm <> Msg_Cipher_None) then
  Query.ParamByName('P_CryptoHeader').SetBlobData(@PasswordHeader,SizeOf(PasswordHeader))
 else
  begin
   Query.ParamByName('P_CryptoHeader').Clear;
   Query.ParamByName('P_CryptoHeader').DataType := ftBlob;
  end;
end; // GetInsertToUsersSQL


//------------------------------------------------------------------------------
// Create SQL script for updating user info
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.GetUpdateUserSQL(
                      Query:          TMsgMySQLQuery;
                      UserInfo:       TMsgUserInfo;
                      ChangePassword: Boolean;
                      PasswordHeader: TMsgCryptoHeader);
var s: AnsiString;
begin
 if (ChangePassword) then
  s := 'CryptoHeader = :P_CryptoHeader'+crlf
 else
  s := '';
 Query.SQLText := 'UPDATE '+UsersTableName+' SET '+crlf+
           'UserName = '+AnsiQuotedStr(UserInfo.UserName,'''')+','+crlf+
           'FirstName = '+AnsiQuotedStr(UserInfo.FirstName,'''')+','+crlf+
           'LastName = '+AnsiQuotedStr(UserInfo.LastName,'''')+','+crlf+
           'Organization = '+AnsiQuotedStr(UserInfo.Organization,'''')+','+crlf+
           'Department = '+AnsiQuotedStr(UserInfo.Department,'''')+','+crlf+
           s+
           'WHERE ID = '+IntToStr(Integer(UserInfo.UserID));
 if (ChangePassword) then
  begin
   Query.Prepare;
   if (PasswordHeader.CryptoAlgorithm <> Msg_Cipher_None) then
    Query.ParamByName('P_CryptoHeader').SetBlobData(@PasswordHeader,SizeOf(PasswordHeader))
   else
    begin
     Query.ParamByName('P_CryptoHeader').Clear;
     Query.ParamByName('P_CryptoHeader').DataType := ftBlob;
    end;
  end;
end; // GetUpdateUserSQL


//------------------------------------------------------------------------------
// return user info
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.ExtractUserInfo(Dataset: TDataset): TMsgUserInfo;
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
// Create
//------------------------------------------------------------------------------
constructor TMsgDatabaseMySQL.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDelay := 1;
  FRetryCount := 1000;
  FTableType := 'MyISAM';
//  FNewSession := True;
  FNewSession := False;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgDatabaseMySQL.Destroy;
begin
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.CloseDatabase;
begin
  if (FCloseDB) then
   begin
    if (FDatabase <> nil) then
     FDatabase.Close;
    {$IFDEF DB_EXPRESS}
    if (FSQLConnection <> nil) then
     FSQLConnection.Close;
    {$ENDIF}
   end;
end; // CloseDatabase


//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.AddUser(UserInfo: TMsgUserInfo; PasswordHeader: TMsgCryptoHeader);
var
    Query:  TMsgMySQLQuery;
    bOK:    Boolean;
    cnt:    Integer;
begin
  if (UserInfo.UserID = MSG_INVALID_USER_ID) then
   raise EMsgException.Create(11365,ErrorLInvalidUserID,[UserInfo.UserID]);
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
    GetInsertUserSQL(Query,UserInfo,PasswordHeader);
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      Query.StartTransaction;
      if (UserExists(UserInfo.UserID)) then
       begin
         Query.Rollback;
         raise EMsgException.Create(11359,ErrorLUserAlreadyExists,[UserInfo.UserID]);
       end;
      try
       Query.ExecSQL;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11360,ErrorLAddUserTransactionFailed,
       [UserInfo.UserID,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
end; // AddUser


//------------------------------------------------------------------------------
// Close database
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.RemoveUser(const UserID: Cardinal);
var
    Query:  TMsgMySQLQuery;
    bOK:    Boolean;
    cnt:    Integer;
begin
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      Query.StartTransaction;
      if (not UserExists(UserID)) then
       begin
         Query.Rollback;
         raise EMsgException.Create(11361,ErrorLUserDoesNotExist,[UserID]);
       end;
      try
       Query.SQLText := 'DELETE FROM '+UsersTableName+' WHERE ID = '+IntToStr(Integer(UserID));
       Query.ExecSQL;
       Query.SQLText := 'DELETE FROM '+ContactsTableName+' WHERE (OwnerID = '+IntToStr(Integer(UserID))+
                         ') OR (ContactID = '+IntToStr(Integer(UserID))+')';
       Query.ExecSQL;
       Query.SQLText := 'DELETE FROM '+MessagesTableName+' WHERE (SenderID = '+IntToStr(Integer(UserID))+
                         ') OR (RecipientID = '+IntToStr(Integer(UserID))+')';
       Query.ExecSQL;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11362,ErrorLRemoveUserTransactionFailed,
       [UserID,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
end; // RemoveUser


//------------------------------------------------------------------------------
// change user info and optionally password
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.ChangeUserInfo(UserInfo: TMsgUserInfo; ChangePassword: Boolean; PasswordHeader: TMsgCryptoHeader);
var
    Query:  TMsgMySQLQuery;
    bOK:    Boolean;
    cnt:    Integer;
begin
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
    GetUpdateUserSQL(Query,UserInfo,ChangePassword,PasswordHeader);
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      Query.StartTransaction;
      if (not UserExists(UserInfo.UserID)) then
       begin
         Query.Rollback;
         raise EMsgException.Create(11363,ErrorLUserDoesNotExist,[UserInfo.UserID]);
       end;
      try
       Query.ExecSQL;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11364,ErrorLChangeUserInfoTransactionFailed,
       [UserInfo.UserID,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
end; // ChangeUserInfo


//------------------------------------------------------------------------------
// ChangeUserStatus
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.ChangeUserStatus(
                           const AllUsers:    Boolean;
                           const UserID:      Cardinal;
                           const Status:      TMsgUserStatus;
                           const Host:        AnsiString = '';
                           const Port:        Integer = 0;
                           const Application: AnsiString = ''
                          );
var
    Query:   TMsgMySQLQuery;
    bOK:     Boolean;
    cnt,i:   Integer;
    s,w,a,h: AnsiString;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>TMsgDatabaseMySQL.ChangeUserStatus - UserID = '+IntToStr(UserID)+', Status = '+IntToStr(Byte(Status)));
{$ENDIF}
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
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
    Query.SQLText := 'UPDATE '+UsersTableName+' SET '+crlf+
                      'Status = '+IntToStr(Byte(Status))+s+w;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      Query.StartTransaction;
      if (not AllUsers) then
       if (not UserExists(UserID)) then
        begin
         Query.Rollback;
         raise EMsgException.Create(11366,ErrorLUserDoesNotExist,[UserID]);
        end;
      try
       Query.ExecSQL;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11367,ErrorLChangeUserStatusTransactionFailed,
       [UserID,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('<TMsgDatabaseMySQL.ChangeUserStatus - UserID = '+IntToStr(UserID)+', Status = '+IntToStr(Byte(Status)));
{$ENDIF}
end; // ChangeUserStatus


//------------------------------------------------------------------------------
// GetLastLogged
//------------------------------------------------------------------------------
procedure TMsgDatabaseMYSQL.GetLastLogged(
                              const UserID:     Cardinal;
                              out   LogonTime:  TDateTime;
                              out   LogoffTime: TDateTime
                          );
var
    Query:  TMsgMYSQLQuery;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>TMsgDatabaseMYSQL.GetLastLogged - UserID = '+IntToStr(UserID));
{$ENDIF}
  Query := TMsgMYSQLQuery.Create(Self,False);
  try
    Query.RequestLive := True;
    Query.SQLText := 'SELECT * FROM '+UsersTableName+' WHERE ID = '+IntToStr(UserID);
    Query.Dataset.Open;
    Query.Dataset.First;
    if (not Query.Dataset.Eof) then
     begin
      LogonTime := Query.Dataset.FieldByName('LogonTime').AsDateTime;
      LogoffTime := Query.Dataset.FieldByName('LogoffTime').AsDateTime;
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


//------------------------------------------------------------------------------
// Get user info
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.GetUserInfo(const UserID: Cardinal): TMsgUserInfo;
var
    Query:  TMsgMySQLQuery;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>TMsgDatabaseMySQL.GetUserInfo - UserID = '+IntToStr(UserID));
{$ENDIF}
  Query := TMsgMySQLQuery.Create(Self,False);
  try
    Query.RequestLive := True;
    Query.SQLText := 'SELECT * FROM '+UsersTableName+' WHERE ID = '+IntToStr(UserID);
    Query.Dataset.Open;
    Query.Dataset.First;
    if (not Query.Dataset.Eof) then
     begin
      Result := ExtractUserInfo(Query.Dataset);
     end
    else
     Result.UserID := MSG_INVALID_USER_ID;
  finally
    Query.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('<TMsgDatabaseMySQL.GetUserInfo - UserID = '+IntToStr(UserID)+', UserInfo.UserID = '+IntToStr(Result.UserID));
{$ENDIF}
end; // GetUserInfo


//------------------------------------------------------------------------------
// return numbef of users
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.GetUsersCount: Integer;
var
    Query:  TMsgMySQLQuery;
begin
  Query := TMsgMySQLQuery.Create(Self,False);
  try
//    Query.RequestLive := True;
    Query.SQLText := 'SELECT COUNT(*) FROM '+UsersTableName;
    Query.Dataset.Open;
    Result := Query.Dataset.Fields[0].AsInteger;
  finally
    Query.Free;
  end;
end; // GetUsersCount


//------------------------------------------------------------------------------
// Return PasswordHeader
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.GetPasswordHeader(const UserID: Cardinal): TMsgCryptoHeader;
var 
    Query:  TMsgMySQLQuery;
    bs:     TStream;
begin
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('>MsgDatabaseAccuracer.GetPasswordHeader - UserID = '+IntToStr(UserID));
{$ENDIF}
  Query := TMsgMySQLQuery.Create(Self,False);
  try
    Query.RequestLive := True;
    Query.SQLText := 'SELECT * FROM '+UsersTableName+' WHERE ID = '+IntToStr(UserID);
    Query.Dataset.Open;
    Query.Dataset.First;
    if (not Query.Dataset.Eof) then
     begin
      if (query.Dataset.FieldByName('CryptoHeader').IsNull) then
       begin
        FillChar(Result,SizeOf(Result),0);
        Result.CryptoAlgorithm := Msg_Cipher_None;
       end
      else
       begin
        bs := query.Dataset.CreateBlobStream(Query.Dataset.FieldByName('CryptoHeader'),bmRead);
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
    Query.Free;
  end;
{$IFDEF DEBUG_DB_ACR}
aaWriteToLog('<TMsgDatabaseMySQL.GetPasswordHeader - UserID = '+IntToStr(UserID)+', UserInfo.UserID = '+IntToStr(Result.UserID));
{$ENDIF}
end; // GetPasswordHeader


//------------------------------------------------------------------------------
// Return true if user exists
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.UserExists(const UserID: Cardinal): Boolean;
var
    Query:  TMsgMySQLQuery;
begin
  Query := TMsgMySQLQuery.Create(Self,False);
  try
    Query.RequestLive := True;
    Query.SQLText := 'SELECT * FROM '+UsersTableName+' WHERE ID = '+IntToStr(Integer(UserID));
    Query.Dataset.Open;
    Query.Dataset.First;
    Result := (not Query.Dataset.Eof);
  finally
    Query.Free;
  end;
end; // UserExists


//------------------------------------------------------------------------------
// Get users
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.GetUsers(var Users: TMsgUserInfoArray; const SortBy: TMsgUserInfoArraySortBy; const Ascending: Boolean);
var 
    Query:  TMsgMySQLQuery;
    s,s1:   AnsiString;
    i:      Integer;
begin
  Query := TMsgMySQLQuery.Create(Self,False);
  try
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
    Query.RequestLive := True;
    Query.SQLText := 'SELECT * FROM '+UsersTableName+' '+s;
    Query.Dataset.Open;
    i := 0;
    SetLength(Users,i);
    Query.Dataset.First;
    while (not Query.Dataset.Eof) do
     begin
      Inc(i);
      SetLength(Users,i);
      Users[i-1] := ExtractUserInfo(Query.Dataset);
      Query.Dataset.Next;
     end;
  finally
    Query.Free;
  end;
end; // GetUsers


//------------------------------------------------------------------------------
// find users
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.FindUsers(
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
    Query:      TMsgMySQLQuery;
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
  Query := TMsgMySQLQuery.Create(Self,False);
  try
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

//    Query.RequestLive := True;
    Query.SQLText := 'SELECT * FROM '+UsersTableName+' '+condition+' '+s;
    Query.Dataset.Open;
    i := 0;
    SetLength(Users,i);
    Query.Dataset.First;
    while (not Query.Dataset.Eof) do
     begin
      Inc(i);
      SetLength(Users,i);
      Users[i-1] := ExtractUserInfo(Query.Dataset);
      Query.Dataset.Next;
     end;
  finally
    Query.Free;
  end;
end; // FindUsers


//------------------------------------------------------------------------------
// search for UserID by the UserName
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.FindUserID(const UserName: AnsiString): Cardinal;
var
    Query:  TMsgMySQLQuery;
    i:      Integer;
begin
  Result := MSG_INVALID_USER_ID;
  Query := TMsgMySQLQuery.Create(Self,False);
  try
    Query.RequestLive := False;
    Query.SQLText := 'SELECT u.id FROM '+
                      UsersTableName+' AS u '+
                      ' WHERE u.UserName = '+AnsiQuotedStr(UserName,'''');
    Query.Dataset.Open;
    Query.Dataset.First;
    if (not Query.Dataset.Eof) then
     Result := Cardinal(Query.Dataset.FieldByName('id').AsInteger);
  finally
    Query.Free;
  end;
end; // FindUserID


//------------------------------------------------------------------------------
// Get user contacts (array of UserID)
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.GetUserContacts(const UserID: Cardinal; var Contacts: TMsgContactInfoArray);
var
    Query:  TMsgMySQLQuery;
    i:      Integer;
begin
  Query := TMsgMySQLQuery.Create(Self,False);
  try
    Query.RequestLive := False;
    Query.SQLText := 'SELECT u.*, c.ContactNameSource,c.ContactCustomName FROM '+
                      UsersTableName+' AS u, '+
                      ContactsTableName+' AS c'+
                      ' WHERE (u.ID = c.ContactID) '
                      +' AND (c.OwnerID = '+
                      IntToStr(Integer(UserID))+')';
    Query.Dataset.Open;
    i := 0;
    SetLength(Contacts,i);
    Query.Dataset.First;
    while (not Query.Dataset.Eof) do
     begin
      Inc(i);
      SetLength(Contacts,i);
      Contacts[i-1].UserInfo := ExtractUserInfo(Query.Dataset);
      Contacts[i-1].ContactNameSource := TMsgContactNameSource(Query.Dataset.FieldByName('ContactNameSource').AsInteger);
      Contacts[i-1].ContactCustomName := Query.Dataset.FieldByName('ContactCustomName').AsString;
      Query.Dataset.Next;
     end;
  finally
    Query.Free;
  end;
end; // GetUserContacts


//------------------------------------------------------------------------------
// return number of User's contacts
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.GetUserContactCount(UserID: Cardinal): Integer;
var
    Query:  TMsgMySQLQuery;
begin
  Query := TMsgMySQLQuery.Create(Self,False);
  try
    Query.RequestLive := True;
    Query.SQLText := 'SELECT * FROM '+ContactsTableName+' WHERE OwnerID = '+IntToStr(Integer(UserID));
    Query.Dataset.Open;
    Result := Query.Dataset.RecordCount;
  finally
    Query.Free;
  end;
end; // GetUserContactCount


//------------------------------------------------------------------------------
// return true if UserID is in contact list of OwnerUserID
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.IsUserInContacts(UserID,OwnerUserID: Cardinal): Boolean;
var
    Query:  TMsgMySQLQuery;
begin
  Query := TMsgMySQLQuery.Create(Self,False);
  try
    Query.RequestLive := True;
    Query.SQLText := 'SELECT * FROM '+ContactsTableName+' WHERE (OwnerID = '
     +IntToStr(Integer(OwnerUserID))+
     ') AND (ContactID = '+IntToStr(Integer(UserID))+')';
    Query.Dataset.Open;
    Result := (Query.Dataset.RecordCount > 0);
  finally
    Query.Free;
  end;
end; // IsUserInContacts


//------------------------------------------------------------------------------
// Add user to contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.AddUserToContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                                                  );
var 
    Query:  TMsgMySQLQuery;
    bOK:    Boolean;
    cnt:    Integer;
begin
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
    Query.SQLText := 'INSERT INTO '+ContactsTableName+
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
      Query.StartTransaction;
      if (not UserExists(OwnerUserID)) then
       begin
         Query.Rollback;
         raise EMsgException.Create(11368,ErrorLUserDoesNotExist,[OwnerUserID]);
       end;
      if (not UserExists(ContactUserID)) then
       begin
         Query.Rollback;
         raise EMsgException.Create(11369,ErrorLUserDoesNotExist,[ContactUserID]);
       end;
      try
       Query.ExecSQL;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11370,ErrorLAddContactTransactionFailed,
       [OwnerUserID,ContactUserID,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
end; // AddUserToContacts


//------------------------------------------------------------------------------
// update user in contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.UpdateUserInContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  ShortString = ''
                                                  );
var 
    Query:  TMsgMySQLQuery;
    bOK:    Boolean;
    cnt:    Integer;
begin
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
    Query.SQLText := 'UPDATE '+ContactsTableName+' SET ContactNameSource = '+
                      IntToStr(Byte(ContactNameSource))+', ContactCustomName = '+
                      AnsiQuotedStr(ContactCustomName,'''')+crlf+
                      ' WHERE (OwnerID = '+IntToStr(Integer(OwnerUserID))+
                      ') AND (ContactID = '+IntToStr(Integer(ContactUserID))+')'+crlf;
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      Query.StartTransaction;
      if (not UserExists(OwnerUserID)) then
       begin
         Query.Rollback;
         raise EMsgException.Create(11490,ErrorLUserDoesNotExist,[OwnerUserID]);
       end;
      if (not UserExists(ContactUserID)) then
       begin
         Query.Rollback;
         raise EMsgException.Create(11491,ErrorLUserDoesNotExist,[ContactUserID]);
       end;
      try
       Query.ExecSQL;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11492,ErrorLUpdateContactTransactionFailed,
       [OwnerUserID,ContactUserID,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
end; // UpdateUserInContacts


//------------------------------------------------------------------------------
// Remove user from contact list of another user
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.RemoveUserFromContacts(
                                  const OwnerUserID: Cardinal;
                                  const ContactUserID: Cardinal);
var 
    Query:  TMsgMySQLQuery;
    bOK:    Boolean;
    cnt:    Integer;
begin
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      Query.StartTransaction;
      if (not UserExists(OwnerUserID)) then
       begin
         Query.Rollback;
         raise EMsgException.Create(11371,ErrorLUserDoesNotExist,[OwnerUserID]);
       end;
      if (not UserExists(ContactUserID)) then
       begin
         Query.Rollback;
         raise EMsgException.Create(11372,ErrorLUserDoesNotExist,[ContactUserID]);
       end;
      try
       Query.SQLText := 'DELETE FROM '+ContactsTableName+' WHERE (OwnerID = '+
                         IntToStr(Integer(OwnerUserID))+
                         ') AND (ContactID = '+IntToStr(Integer(ContactUserID))+')';
       Query.ExecSQL;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11373,ErrorLRemoveUserFromContactsTransactionFailed,
       [OwnerUserID,ContactUserID,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
end; // RemoveUserFromContacts


//------------------------------------------------------------------------------
// saves message to database and returns MessageID
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.SaveMessage(
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
    Query:  TMsgMySQLQuery;
    bOK:    Boolean;
    cnt:    Integer;
    s_del:  AnsiString;
    s_data: AnsiString;
    s_unicode: AnsiString;
    s_command: AnsiString;
    s_sending: AnsiString;
begin
  Result := -1;
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
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
    Query.SQLText := 'INSERT INTO '+MessagesTableName+
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
    Query.Prepare;
    if (MessageDataSize > 0) then
     begin
      Query.ParamByName('P_MessageData').DataType := ftBlob;
      Query.ParamByName('P_MessageData').SetBlobData(MessageData,MessageDataSize);
     end;
{
    if (MessageUnicodeText <> '') then
     begin
      Query.ParamByName('P_MessageUnicodeText').DataType := ftWideString;
      Query.ParamByName('P_MessageUnicodeText').Value := MessageUnicodeText;
     end;
}
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      Query.StartTransaction;
      try
       Query.ExecSQL;
       Query.SQLText := 'SELECT MAX(ID) FROM '+ MessagesTableName;
       Query.Dataset.Open;
       Result := Query.Dataset.Fields[0].AsInteger;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11379,ErrorLSaveMessageFailed,
       [SenderID,RecipientID,Byte(MessageType),MessageText,MessageDataSize,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
end; // SaveMessage


//------------------------------------------------------------------------------
// set message delivery date = CURRENT_TIMESTAMP and delivered = true
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.SetMessageDeliveryDate(MessageID: Integer);
var 
    Query:  TMsgMySQLQuery;
    bOK:    Boolean;
    cnt:    Integer;
begin
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
    Query.SQLText := 'UPDATE '+MessagesTableName+
                      ' SET Delivered = 1, DeliveryDate = CURRENT_TIMESTAMP'+
                      ' WHERE ID = '+IntToStr(MessageID);
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      Query.StartTransaction;
      try
       Query.ExecSQL;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11380,ErrorLSetMessageDeliveryDateFailed,
       [MessageID,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
end; // SetMessageDeliveryDate


//------------------------------------------------------------------------------
// delete message
//------------------------------------------------------------------------------
procedure TMsgDatabaseMySQL.DeleteMessage(MessageID: Integer);
var
    Query:  TMsgMySQLQuery;
    bOK:    Boolean;
    cnt:    Integer;
begin
  Query := TMsgMySQLQuery.Create(Self,FNewSession);
  try
    Query.SQLText := 'DELETE FROM '+MessagesTableName+
                      ' WHERE ID = '+IntToStr(MessageID);
    bOK := False;
    cnt := FRetryCount;
    while (not bOK) and (cnt >= 0) do
     begin
      Query.StartTransaction;
      try
       Query.ExecSQL;
       Query.Commit;
       bOK := True;
      except
       Query.Rollback;
       Dec(cnt);
      end;
     end;
    if (cnt < 0) then
     raise EMsgException.Create(11387,ErrorLDeleteMessageFailed,
       [MessageID,FRetryCount,FDelay]);
  finally
    Query.Free;
  end;
end; // DeleteMessage


//------------------------------------------------------------------------------
// return new query object with found messages from MsgMessages table
//------------------------------------------------------------------------------
function TMsgDatabaseMySQL.FindMessages(
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
    Query:  TMsgMySQLQuery;
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
  Query := TMsgMySQLQuery.Create(Self,False);
  Result := nil;
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
   Query.SQLText := 'SELECT * FROM '+MessagesTableName+orderby
  else
   Query.SQLText := 'SELECT * FROM '+MessagesTableName+' WHERE '+condition+orderby;
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
     Query.Dataset.Open;
     Result := Query.Dataset;
     Query.FQuery := nil;
     {$IFDEF DB_EXPRESS}
     Query.FSQLQuery := nil;
     {$ENDIF}
     bOK := True;
    except
     Dec(cnt);
    end;
   end;
  if (cnt < 0) then
   begin
    raise EMsgException.Create(11381,ErrorLFindMessageFailed,
     [Query.SQLText,FRetryCount,FDelay]);
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
aaWriteToLog('MsgDatabaseMySQL> initialization started');
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
aaWriteToLog('MsgDatabaseMySQL> initialization finished');
{$ENDIF}


end.

