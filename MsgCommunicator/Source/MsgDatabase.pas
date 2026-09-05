unit MsgDatabase;

interface


{$I MsgVer.inc}

uses

 DB,Classes,SysUtils,

MsgExcept,
MsgComBase,
MsgConst,
MsgCompression,
MsgTypes
;

// SQL script for creating all tables on server side (SQL syntax of Accuracer)
// on client only MsgMessages table needed for storing local message history
// SIGNEDINT32 = INTEGER
// UNSIGNEDINT8 = BYTE
// AUTOINC = INTEGER auto-increment counter 
{
DROP TABLE MsgUsers CASCADE;
CREATE TABLE MsgUsers (
	ID SIGNEDINT32,
	UserName AnsiChar (255),
	FirstName AnsiChar (255),
	LastName AnsiChar (255),
	Organization AnsiChar (255),
	Department AnsiChar (255),
	Status UNSIGNEDINT8,
	Host AnsiChar (255),
	Port SIGNEDINT32,
	Application AnsiChar (255),
	CryptoHeader BLOB BLOBBLOCKSIZE 102400 BLOBCOMPRESSIONALGORITHM NONE BLOBCOMPRESSIONMODE 0,
PRIMARY KEY UsersPK (ID)
);

DROP TABLE MsgContacts CASCADE;
CREATE TABLE MsgContacts (
	OwnerID SIGNEDINT32,
	ContactID SIGNEDINT32,
	ContactNameSource UNSIGNEDINT8,
	ContactCustomName AnsiString (255),
PRIMARY KEY ContactsPK (OwnerID, ContactID)
);

DROP TABLE MsgMessages CASCADE;
CREATE TABLE MsgMessages (
	ID  AUTOINC (AUTOINC INITIALVALUE 0 INCREMENT 1 NOMINVALUE NOMAXVALUE NOCYCLED),
	SenderID SIGNEDINT32,
	RecipientID SIGNEDINT32,
	Delivered LOGICAL,
	DeliveryDate DATETIME,
	SendingDate DATETIME,
	MessageType UNSIGNEDINT8,
	Command SIGNEDINT32,
	MessageDataSize SIGNEDINT32,
	MessageData BLOB BLOBBLOCKSIZE 102400 BLOBCOMPRESSIONALGORITHM NONE BLOBCOMPRESSIONMODE 0,
	MessageText MEMO BLOBBLOCKSIZE 102400 BLOBCOMPRESSIONALGORITHM NONE BLOBCOMPRESSIONMODE 0,
	MessageUnicodeText WIDEMEMO BLOBBLOCKSIZE 102400 BLOBCOMPRESSIONALGORITHM NONE BLOBCOMPRESSIONMODE 0,
PRIMARY KEY MessagesPK (ID)
);

}



type

////////////////////////////////////////////////////////////////////////////////
//
// TMsgDatabase
//
////////////////////////////////////////////////////////////////////////////////

 TMsgDatabase = class (TComponent)
  private
   FUsersTableName:    AnsiString;
   FMessagesTableName: AnsiString;
   FContactsTableName: AnsiString;
   FParent:            TComponent;
  protected
   FCloseDB: Boolean;
   function GetMainVersion: AnsiString; virtual;
   function GetModuleVersion: AnsiString; virtual;
   procedure SetVersion(Value: AnsiString);
   function GetTablesExists(HistoryOnly: Boolean): Boolean; virtual; abstract;
   procedure CreateTables(HistoryOnly: Boolean); virtual; abstract;
   procedure OpenDatabase; virtual; abstract;
  public
   constructor Create(AOwner: TComponent); override;
   destructor Destroy; override;
   procedure OpenOrCreateDatabase(HistoryOnly: Boolean); virtual;
   procedure ClearAll; virtual;
   procedure CloseDatabase; virtual; abstract;
   procedure AddUser(UserInfo: TMsgUserInfo; PasswordHeader: TMsgCryptoHeader); virtual; abstract;
   procedure RemoveUser(const UserID: Cardinal); virtual; abstract;
   procedure ChangeUserInfo(UserInfo: TMsgUserInfo; ChangePassword: Boolean; PasswordHeader: TMsgCryptoHeader); virtual; abstract;
   procedure ChangeUserStatus(
                              const AllUsers: Boolean;
                              const UserID:   Cardinal;
                              const Status:   TMsgUserStatus;
                              const Host: AnsiString = '';
                              const Port: Integer = 0;
                              const Application: AnsiString = ''
                              ); virtual; abstract;
   procedure GetLastLogged(
                              const UserID:     Cardinal;
                              out   LogonTime:  TDateTime;
                              out   LogoffTime: TDateTime
                          ); virtual; abstract;
   function GetPasswordHeader(const UserID: Cardinal): TMsgCryptoHeader; virtual; abstract;
   function GetUserInfo(const UserID: Cardinal): TMsgUserInfo; virtual; abstract;
   function GetUsersCount: Integer; virtual; abstract;
   function UserExists(const UserID: Cardinal): Boolean; virtual; abstract;
   procedure GetUsers(var Users: TMsgUserInfoArray; const SortBy: TMsgUserInfoArraySortBy; const Ascending: Boolean); virtual; abstract;
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
                       ); virtual; abstract;
   // search for UserID by the UserName
   function FindUserID(const UserName: AnsiString): Cardinal; virtual; abstract;
   procedure GetUserContacts(const UserID: Cardinal; var Contacts: TMsgContactInfoArray); virtual; abstract;
   function GetUserContactCount(UserID: Cardinal): Integer; virtual; abstract;
   // return true if UserID is in contact list of OwnerUserID
   function IsUserInContacts(UserID,OwnerUserID: Cardinal): Boolean;virtual; abstract;
   procedure AddUserToContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal; 
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName; 
                            const ContactCustomName:  ShortString = ''
                               ); virtual; abstract; 
   procedure UpdateUserInContacts( 
                            const OwnerUserID:        Cardinal; 
                            const ContactUserID:      Cardinal; 
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName; 
                            const ContactCustomName:  ShortString = ''
                               ); virtual; abstract;
   procedure RemoveUserFromContacts(const OwnerUserID: Cardinal; const ContactUserID: Cardinal); virtual; abstract; 
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
                        ): Integer; virtual; abstract; 
   procedure SetMessageDeliveryDate(MessageID: Integer); virtual; abstract;
   procedure DeleteMessage(MessageID: Integer); virtual; abstract;
   // return new query object with found messages from MsgMessages table 
   function FindMessages(
                         const MessageTextComparison:         TMsgTextComparison;
                         const MessageUnicodeTextComparison:  TMsgTextComparison;
                         const SendingDate:                   TMsgDateComparison; 
                         const DeliveryDate:                  TMsgDateComparison;
                         const SearchDelivered:               Boolean;
                         const Delivered:                     Boolean = True;
                         const MessageText:         AnsiString = ''; // text of the message 
                         const MessageUnicodeText:  WideString = ''; // unicode text of the message 
                         const SenderID:            Cardinal = MSG_INVALID_USER_ID;
                         const RecipientID:         Cardinal = MSG_INVALID_USER_ID; 
                         const MessageType:         TMsgMessageType = aamtNone; 
                         const MessageDataSize:     Integer = -1; // size of MessageData 
                         const OrderBySendingDate:  Boolean = False;
                         // ORDER BY columns without ORDER BY statement
                         // example: SenderID DESC, SendingDate ASC
                         const OrderByClause:       AnsiString = '';
                         const Command:             Cardinal = 0 // no condition on command field if TMsgMessageType = aamtNone 
                        ): TDataset; virtual; abstract; 
   // get message ID of the current record in ds - messages table or query based on messages table
   function GetMessageID(ds: TDataset): Integer; virtual; 
   function GetMessageType(ds: TDataset): TMsgMessageType; virtual;
   // extract message from the current record in ds - messages table or query based on messages table 
   // and prepare it for sending to client - move message buffer to Stream 
   procedure PrepareMessageForSending(ds: TDataset; Stream: TStream); virtual;
  published
   property UsersTableName: AnsiString read FUsersTableName write FUsersTableName;
   property MessagesTableName: AnsiString read FMessagesTableName write FMessagesTableName; 
   property ContactsTableName: AnsiString read FContactsTableName write FContactsTableName; 
   property ModuleVersion: AnsiString read GetModuleVersion write SetVersion; 
   property MsgCommunicatorVersion: AnsiString read GetMainVersion write SetVersion; 
 end; // TMsgDatabase 
 
 
 
//////////////////////////////////////////////////////////////////////////////// 
// 
// TMsgTempTable 
//
////////////////////////////////////////////////////////////////////////////////
	
 TMsgTempTable = class (TComponent) 
 private
   FParent:            TComponent; 
  public 
   constructor Create(AOwner: TComponent); override; 
   destructor Destroy; override; 
   procedure SaveDatasetToStream(Dataset: TDataset; Stream: TStream); virtual; abstract; 
   procedure LoadDatasetFromStream(var Dataset: TDataset; Stream: TStream); virtual; abstract; 
 end; // TMsgTempTable 
 
 
procedure ClearMsgDatabaseReference(Database: TComponent; Parent: TComponent); 
procedure ClearMsgTempTableReference(TempTable: TComponent; Parent: TComponent); 
	
implementation 
	
uses MsgServer; 
 
	
procedure ClearMsgDatabaseReference(Database: TComponent; Parent: TComponent);
var i: Integer;
begin 
  if (Parent <> nil) then
   for i := 0 to Parent.ComponentCount-1 do
    if (Parent.Components[i] is TMsgServer) then 
     if (TMsgServer(Parent.Components[i]).Database = Database) then 
      TMsgServer(Parent.Components[i]).Database := nil;
end;
 
	
procedure ClearMsgTempTableReference(TempTable: TComponent; Parent: TComponent); 
var i: Integer; 
begin
  if (Parent <> nil) then 
   for i := 0 to Parent.ComponentCount-1 do
    if (Parent.Components[i] is TMsgServer) then
     if (TMsgServer(Parent.Components[i]).TempTable = TempTable) then 
      TMsgServer(Parent.Components[i]).TempTable := nil; 
end;
 
	
//////////////////////////////////////////////////////////////////////////////// 
// 
// TMsgDatabase
//
////////////////////////////////////////////////////////////////////////////////
	
	
//------------------------------------------------------------------------------
// return Version of the MsgCommunicator
//------------------------------------------------------------------------------ 
function TMsgDatabase.GetMainVersion: AnsiString;
begin 
 Result := 'Unknown version';
end; // GetMainVersion
	
 
//------------------------------------------------------------------------------
// return Version of this module 
//------------------------------------------------------------------------------
function TMsgDatabase.GetModuleVersion: AnsiString;
begin
 Result := 'Unknown version';
end; // GetModuleVersion


//------------------------------------------------------------------------------
// do nothing
//------------------------------------------------------------------------------
procedure TMsgDatabase.SetVersion(Value: AnsiString);
begin
// do nothing
end; // SetVersion


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgDatabase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FParent := AOwner;
  FUsersTableName := 'MsgUsers';
  FMessagesTableName := 'MsgMessages';
  FContactsTableName := 'MsgContacts';
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgDatabase.Destroy;
begin
  if (FParent <> nil) then
   if (csDesigning in ComponentState) then
     ClearMsgDatabaseReference(Self,FParent);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Open database and create tables if necessary
//------------------------------------------------------------------------------
procedure TMsgDatabase.OpenOrCreateDatabase(HistoryOnly: Boolean);
begin
  OpenDatabase;
  if (not GetTablesExists(HistoryOnly)) then
   CreateTables(HistoryOnly);
end; // OpenOrCreateDatabase


//------------------------------------------------------------------------------
// clear all tables
//------------------------------------------------------------------------------
procedure TMsgDatabase.ClearAll;
begin
  CreateTables(False);
end; // ClearAll


//------------------------------------------------------------------------------
// get message ID of the current record in ds - messages table or query based on messages table
//------------------------------------------------------------------------------
function TMsgDatabase.GetMessageID(ds: TDataset): Integer;
begin
  Result := ds.FieldByName('ID').AsInteger;
end; // GetMessageID


//------------------------------------------------------------------------------
// get message type of the current record in ds - messages table or query based on messages table
//------------------------------------------------------------------------------
function TMsgDatabase.GetMessageType(ds: TDataset): TMsgMessageType;
begin
  Result := TMsgMessageType(ds.FieldByName('MessageType').AsInteger);
end; // GetMessageType


//------------------------------------------------------------------------------
// extract message from the current record in ds - messages table or query based on messages table
// and prepare it for sending to client - move message buffer to Stream
//------------------------------------------------------------------------------
procedure TMsgDatabase.PrepareMessageForSending(ds: TDataset; Stream: TStream);
var MessageType:        TMsgMessageType;
    MessageDataSize:    Integer;
    len:                Integer;
    Command:            Integer;
    s:                  AnsiString;
    SenderID:           Cardinal;
    bs:                 TStream;
    SendingDate:        TDateTime;
begin
  MessageType := TMsgMessageType(ds.FieldByName('MessageType').AsInteger);
  MessageDataSize := ds.FieldByName('MessageDataSize').AsInteger;
  SenderID := Cardinal(ds.FieldByName('SenderID').AsInteger);
  SendingDate := ds.FieldByName('SendingDate').AsDateTime;
  SaveDataToStream(SenderID,SizeOf(SenderID),Stream,11382);
  SaveDataToStream(MessageType,SizeOf(MessageType),Stream,11383);
  SaveDataToStream(SendingDate,SizeOf(SendingDate),Stream,11394);
  case MessageType of
   aamtText:
    begin
     s := ds.FieldByName('MessageText').AsString;
     len := Length(s);
     SaveDataToStream(len,SizeOf(len),Stream,11384);
     if (len > 0) then
       SaveDataToStream(PAnsiChar(@s[1])^,len,Stream,11385);
    end
   else
    begin
     if (MessageType = MsgCustomCommand) then
      begin
       Command := ds.FieldByName('Command').AsInteger;
       SaveDataToStream(Command,SizeOf(Command),Stream,11386);
      end;
     if (MessageDataSize > 0) then
      begin
       bs := ds.CreateBlobStream(ds.FieldByName('MessageData'),bmRead);
       try
         Stream.Size := Stream.Position + MessageDataSize;
         Stream.CopyFrom(bs,MessageDataSize);
       finally
         bs.Free;
       end;
      end;
    end;
  end;
end; // PrepareMessageForSending


////////////////////////////////////////////////////////////////////////////////
//
// TMsgTempTable
//
////////////////////////////////////////////////////////////////////////////////


constructor TMsgTempTable.Create(AOwner: TComponent);
begin
  inherited;
  FParent := AOwner;
end;


destructor TMsgTempTable.Destroy;
begin
  if (FParent <> nil) then
   if (csDesigning in ComponentState) then
     ClearMsgTempTableReference(Self,FParent);
  inherited;
end;

end.
