{******************************************************************************}
{                                                                              }
{ Server component                                                             }
{                                                                              }
{******************************************************************************}
{$HINTS OFF}
{$WARNINGS OFF}
unit MsgServer;

interface

{$I MsgVer.inc}

uses Db, SysUtils, Classes, IniFiles,
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}

// MsgCommunicator units

{$IFDEF DEBUG_LOG}
     MsgDebug,
{$ENDIF}
{$IFNDEF D6H}
     FileCtrl,
{$ENDIF}
     MsgConnection,
     MsgExcept,
     MsgMemory,
     MsgCompression,
     MsgCrypto,
     MsgDatabase,
     MsgTypes,
     MsgComMain,
     MsgComBase,
     MsgCriticalSection,
     MsgConst;

const

  MSG_USERS_FILE = 'users.all';
  MSG_UCL_EXT = '.ucl';
  MSG_FILE_EXT = '.msg';
  MSG_USER_MESSAGES_EXT = '.ums';

  MSG_MAX_CARDINAL = 4294967295;

type

  TMsgClientInfo = packed record
   UserID:           Cardinal;
   Host:             ShortString;
   Port:             Integer;
   Application:      ShortString;
   SessionID:        TMsgSessionID;
  end; // TMsgClientInfo

  TMsgClientInfoArray = array of TMsgClientInfo;

  TMsgUserContacts = array of Cardinal;

  TMsgLargeObject = packed record
   ObjectID:        Cardinal;
   ObjectType:      TMsgMessageType;
   FileName:        AnsiString;
   FullSize:        Int64;
   Blocks:          Integer;
   BlockSize:       Integer;
   ToUserID:        Cardinal;
  end;
  PMsgLargeObject = ^TMsgLargeObject;

  TMsgServerSession = class;
  TMsgEvent = packed record
   FromUserID:       Cardinal;
   Session:          TMsgServerSession;
   EventType:        TMsgMessageType;
   LargeObject:      PMsgLargeObject;
  end;
  PMsgEvent = ^TMsgEvent;

  TMsgOnUserRegistered = procedure (const UserID: Cardinal) of object;
  TMsgOnUserInfoChanged = procedure (const UserID: Cardinal) of object;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TMsgServerNetworkSettingsEditor = class (TMsgNetworkSettingsEditor)
   private
    FServerReceiveTimeOut:              Integer;
    FServerReceiveSleep:                Integer;
    FMinServerSendTimeOut:              Integer;
    FServerSendTimeOut:                 Integer;
    FServerWaitForSendSleep:            Integer;
    FServerResendDelay:                 Integer;
    FServerRequestDelay:                Integer;
    FWaitForMessagesSend:               Integer;
    FWaitForServerSessionThreadTimeOut: Integer;
    FServerThreadsTerminateDelay:       Integer;
    FServerSessionTerminatorSleep:      Integer;
    FPingCount:                         Integer;
    FWaitForPingAnswer:                 Integer;
    FServerPingSleep:                   Integer;
    FPingClients:                       Boolean;
    FKeepConnection:                    Boolean;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure CopySettingsToConnectParams(var ConnectParams: TMsgConnectParams); override;
    procedure SetDefaultSettings(Value: TMsgDefaultNetworkSettings); override;
   published
    property ServerReceiveTimeOut:           Integer read FServerReceiveTimeOut write FServerReceiveTimeOut;
    property ServerReceiveSleep:             Integer read FServerReceiveSleep write FServerReceiveSleep;
    property MinServerSendTimeOut:           Integer read FMinServerSendTimeOut write FMinServerSendTimeOut;
    property ServerSendTimeOut:              Integer read FServerSendTimeOut write FServerSendTimeOut;
    property ServerWaitForSendSleep:         Integer read FServerWaitForSendSleep write FServerWaitForSendSleep;
    property ServerResendDelay:              Integer read FServerResendDelay write FServerResendDelay;
    property ServerRequestDelay:             Integer read FServerRequestDelay write FServerRequestDelay;
    property WaitForMessagesSend:            Integer read FWaitForMessagesSend write FWaitForMessagesSend;
    property WaitForServerSessionThreadTimeOut: Integer read FWaitForServerSessionThreadTimeOut write FWaitForServerSessionThreadTimeOut;
    property ServerThreadsTerminateDelay:    Integer read FServerThreadsTerminateDelay write FServerThreadsTerminateDelay;
    property ServerSessionTerminatorSleep:   Integer read FServerSessionTerminatorSleep write FServerSessionTerminatorSleep;
    property PingCount:                      Integer read FPingCount write FPingCount;
    property WaitForPingAnswer:              Integer read FWaitForPingAnswer write FWaitForPingAnswer;
    property ServerPingSleep:                Integer read FServerPingSleep write FServerPingSleep;
    property PingClients:                    Boolean read FPingClients write FPingClients;
    property KeepConnection:                 Boolean read FKeepConnection write FKeepConnection;
  end; // TMsgServerNetworkSettingsEditor



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerConnectParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerConnectParamsEditor = class (TMsgConnectionParamsEditor)
   private
    FNetworkSettings:           TMsgServerNetworkSettingsEditor;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function GetConnectParams: TMsgConnectParams; override;
{$IFDEF RELEASE_BUILD}
   public
{$ELSE}
   published
{$ENDIF}
    property NetworkSettings: TMsgServerNetworkSettingsEditor read FNetworkSettings write FNetworkSettings;
  end;


  TMsgServer = class;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSession
//
////////////////////////////////////////////////////////////////////////////////


  TMsgServerSession = class (TMsgNetworkSession)
   private
    FSkipLoadingContacts:       Boolean;
    FServerSession:             Pointer;
   public
    FCSect:                     TRTLCriticalSection;
   protected
    procedure SetLogged(value: boolean); override;
    procedure SetConnected(value: boolean); override;
   public
    // Back link to corresponding structure (PMsgSrvrSession) in ConnectionManager.Sessions
    procedure SetServerSession(value: Pointer);
    constructor Create(aServer: TComponent);
    destructor Destroy; override;
    // call OnError event handler
    procedure DoOnError(ErrorCode: Integer; NativeError: Integer = -1; ErrorMessage: AnsiString = ''); override;
    procedure DoCloseSessionOnNetworkError; override;
(*****************************************************************************)
(*  COMMANDS to execute                                                      *)
(*****************************************************************************)
   public
    // connect user to this server
    function ConnectUser: Boolean;
    // disconnect user from this server
    procedure DisconnectUser;
   protected
(*****************************************************************************)
(*  COMMANDS to send                                                         *)
(*****************************************************************************)
    // On-line, Off-line. InitLargeObject events
    function SendEvent(Event: PMsgEvent): Boolean;
(*****************************************************************************)
    function SendCommand(
                                Command: TMsgMessageType;
                                Buffer: PAnsiChar;
                                Size: Integer;
                                FromID: Cardinal = MSG_INVALID_USER_ID
                                        ): Integer;
    procedure ExecuteReceivedCommand(var Buffer: PAnsiChar; BufferSize: Integer);
    procedure ExecuteGetUserInfo(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteGetUserID(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteGetContacts(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteIsUserExisting(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteFindUserID(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteIsUserOnline(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteRegisterNewUser(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteUpdateUserInfo(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteAddUserToContacts(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteUpdateUserInContacts(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteRemoveUserFromContacts(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteFindUsers(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteFindMessages(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteLogon(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteLogoff(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    procedure ExecuteInitProgressRecv(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
    function InitProgressSend(ObjectType: TMsgMessageType;
                              ToUserID: Cardinal;
                              const FileName: AnsiString;
                              FullSize: Int64;
                              Blocks: Integer;
                              BlockSize: Integer;
                              var ObjectID: Cardinal
                              ): Integer; override;
    procedure AddInitEvent(UserID: Cardinal; LargeObject: PMsgLargeObject);
   public
    // receive data from network and move it to ReceivedCommandHeader and ReceivedCommandDataStream
    procedure ReceiveData(var Buffer: PAnsiChar; var BufferSize: Integer); override;
    // send buffer via established connection using connection manager
    procedure SendBuffer(Buffer: PAnsiChar; BufferSize: Integer; Code: Integer = MsgNewRequest); override;
    // receive custom message from client
    procedure ReceiveMessage(Buffer: PAnsiChar; BufferSize: Integer); override;
   protected
    // send custom message to client
    procedure SendMessage(Buffer: PAnsiChar; BufferSize: Integer);
    function GetClientInfo: TMsgClientInfo;
  end; // TMsgServerSession

  TMsgServerSessionsArray = array of PMsgSrvrSession;



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServer
//
////////////////////////////////////////////////////////////////////////////////

  TMsgServerEventsThread = class;

  TMsgServer = class (TMsgComponent)
   private
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
    RecvMsgCount:   Integer;
{$ENDIF}
    FDatabase:                      TMsgDatabase;
    FTempTable:                     TMsgTempTable;
    FMaxConnections:                Integer;
    FUsers:                         TMsgThreadList;
    FGuestID:                       Cardinal;
    FMinUserID:                     Cardinal;
    FUseConfigFile:                 Boolean;
    FConnectedUsers:                TMsgThreadIntArray;
    FConnectionParams:              TMsgServerConnectParamsEditor;
    FBeforeServerStart:             TNotifyEvent;
    FAfterServerStart:              TNotifyEvent;
    FBeforeServerStop:              TNotifyEvent;
    FAfterServerStop:               TNotifyEvent;
    FAfterConnect:                  TNotifyEvent;
    FAfterDisconnect:               TNotifyEvent;
    FBeforeConnect:                 TNotifyEvent;
    FBeforeDisconnect:              TNotifyEvent;
    FCurrentVersion:                AnsiString;
    FActive:                        Boolean;
    FConfigFileName:                AnsiString;
    FDataPath:                      AnsiString;
    FConnectionManager:             TMsgServerConnectionManager;
    FServerID:                      Integer;
    FStoreMessageHistory:           Boolean;
    FOnUserRegistered:              TMsgOnUserRegistered;
    FOnUserInfoChanged:             TMsgOnUserInfoChanged;
    FOnUserLogon:                   TMsgOnUserOnLine;
    FOnUserLogoff:                  TMsgOnUserOffLine;
    FCryptoParamsEditor:            TMsgCryptoParamsEditor;
    FEventsQueue:                   TMsgThreadList;
    FEventsThread:                  TMsgServerEventsThread;
   protected
//    procedure SetAllowFiles(Value: Boolean); override; // removed in 3.50
    function SendWithProgress(ToUserID: Cardinal;
                                        ObjectType: TMsgMessageType;
                                        const FileName: AnsiString;
                                        Stream: TStream;
                                        Blocks: Integer;
                                        BlockSize: Integer;
                                        Directly: Boolean): Integer; override;
    function GetNetworkSettings: TMsgServerNetworkSettingsEditor;
    function GetMaxConnections: Integer;
    procedure SetServerID(Value: Integer);
    function GetUserFileName(UserID: Cardinal): AnsiString;
    function GetLocalHost: AnsiString;
    function GetLocalPort: Integer;
    procedure StartServer;
    procedure StopServer;
   public
    function FindSessionWithUser(UserID: Cardinal; CheckLogged: Boolean = True): TMsgServerSession;
   protected
    function FindSessionsWithUser(UserID: Cardinal): TMsgServerSessionsArray;
    function FindSessionsWithUserInContacts(UserID: Cardinal): TMsgServerSessionsArray;
    procedure DoOnError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer = -1;
                       const ErrorMessage: AnsiString = ''
                       ); override;
   public
    procedure GetUserContacts(UserID: Cardinal; var Contacts: TMsgContactInfoArray);
    function GetUserContactCount(UserID: Cardinal): Integer;
    procedure GetLastLogged(
                              const UserID:     Cardinal;
                              out   LogonTime:  TDateTime;
                              out   LogoffTime: TDateTime
                          );
    // return true if UserID is in contact list of OwnerUserID
    function IsUserInContacts(UserID,OwnerUserID: Cardinal): Boolean;
    procedure AddUserToContacts(
                            Session:                  TMsgServerSession;
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  AnsiString = ''
                               );
    procedure UpdateUserInContacts(
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  AnsiString = ''
                               );
    procedure RemoveUserFromContacts(
                            Session:                  TMsgServerSession;
                            OwnerUserID:              Cardinal;
                            ContactUserID:            Cardinal
                            );
   protected
    procedure LoadUsers;
    procedure SaveUsers;
    procedure DeleteUsers;
    function ConnectSession(Session: TMsgServerSession): Boolean;
    procedure DisconnectSession(Session: TMsgServerSession);
    procedure AddUser(UserInfo: TMsgUserInfo; Password: AnsiString = '');
    procedure RemoveUser(const UserID: Cardinal);
    procedure DeleteContacts(const UserID: Cardinal);
    procedure ChangeUserInfo(const UserInfo: TMsgUserInfo; ChangePassword: Boolean; Password: AnsiString);
    function GetPasswordHeader(const UserID: Cardinal): TMsgCryptoHeader;
    function IsPasswordValid(const UserID: Cardinal; const Password: AnsiString): Boolean;
    procedure LogUser(Session: TMsgServerSession; Logged: Boolean);
   public
    procedure ClearAll;
    procedure InsertUser(const UserInfo: TMsgUserInfo; Password: AnsiString = '');
    procedure DeleteUser(const UserID: Cardinal);
    procedure UpdateUser(const UserInfo: TMsgUserInfo; ChangePassword: Boolean; Password: AnsiString = '');
    // disconnect registered user by UserID
    procedure DisconnectUser(const UserID: Cardinal);
    // disconnect client by Host:Port, guests as well
		procedure Disconnect(const Host: AnsiString; const Port: Integer); overload;
    // disconnect client by SessionID
		procedure Disconnect(const SessionID: Integer); overload;
    function IsUserExisting(const UserID: Cardinal): Boolean;
    function IsClientConnected(const Client: TMsgClientInfo): Boolean;
    function IsUserConnected(const UserID: Cardinal): Boolean;
    function IsUserLogged(const UserID: Cardinal): Boolean;
    function GetUserInfo(const UserID: Cardinal): TMsgUserInfo;
    function GetNewUserID: Cardinal;
    procedure LoadDefaultSettings;
    procedure LoadSettingsFromConfigFile;
    procedure SaveSettingsToConfigFile;
    procedure DoOnConnectionError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer;
                       const ErrorMessage: AnsiString
                       );
   protected
    procedure LoadServerSettings;
    function GetCurrentVersion: AnsiString;
    procedure SetActive(Value: Boolean);
    function GetSession(const Client: TMsgClientInfo): TMsgServerSession;
    // Send all the messages stored while the user was off-line
    procedure SendStoredMessagesFromDatabase(Session: TMsgServerSession);
    procedure SendStoredMessages(Session: TMsgServerSession);
    procedure ReceiveMessageToServer(MessageType: TMsgMessageType; SendingDate:  TDateTime; ServerSession: TMsgServerSession; Stream: TMsgMemoryStream);
    function SaveMessageForUser(UserID: Cardinal; Stream: TMsgMemoryStream): Integer;
    function SendMessageToUser(FromUserID, ToUserID: Cardinal; MessageType: TMsgMessageType; SendingDate:  TDateTime; Stream: TMsgMemoryStream): Integer;
    function SendMessageToUsers(
                                        FromUserID:     Cardinal;
                                        ToUserIDs,
                                        Results:        TMsgIntegerArray;
                                        MessageType:    TMsgMessageType;
                                        SendingDate:    TDateTime;
                                        Stream:         TMsgMemoryStream
                                          ): Integer;
    procedure ReceiveMessageToUser(UserID: Cardinal; MessageType: TMsgMessageType; SendingDate:  TDateTime; ServerSession: TMsgServerSession; Stream: TMsgMemoryStream);
    procedure ReceiveMessage(ServerSession: TMsgServerSession; Buffer: PAnsiChar; Size: Integer);
    function CompareUsers(
                      const UserInfo1: TMsgUserInfo;
                      const UserInfo2: TMsgUserInfo;
                      SortBy:          TMsgUserInfoArraySortBy;
                      Ascending:       Boolean): Integer;
    procedure SetDataPath(value: AnsiString);
   public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function UsersCount: Integer;
    function OnLineUsersCount: Integer;
    function GuestsCount: Integer;
    procedure GetUsers(
                       var Users: TMsgUserInfoArray;
                       const SortBy: TMsgUserInfoArraySortBy = msgusbNone;
                       const Ascending: Boolean = True
                      );
    procedure SortUsers(
                          var Users:        TMsgUserInfoArray;
                          const SortBy:     TMsgUserInfoArraySortBy;
                          const Ascending:  Boolean = True
                       );
    procedure GetClients(var Clients: TMsgClientInfoArray);
    // search for UserID by the UserName.
    function FindUserID(const UserName: AnsiString): Cardinal;
    // fills Users with user information records if some users were found
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
                    UserName:                     AnsiString = '';
                    FirstName:                    AnsiString = '';
                    LastName:                     AnsiString = '';
                    Organization:                 AnsiString = '';
                    Department:                   AnsiString = '';
                    Host:                         AnsiString = '';
                    Application:                  AnsiString = '';
                    SearchCondition:              AnsiString = ''; // SQL WHERE clause without word WHERE
                    // ORDER BY columns without ORDER BY words
                    // example: SenderID DESC, SendingDate ASC
                    SortBy:                       TMsgUserInfoArraySortBy = msgusbNone;
                    Ascending:                    Boolean = True;
                    OrderByClause:                AnsiString = ''
                       );
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
                        ): TDataset;
// send message to multiple addresses
    function SendMessageMultiple(ToUserIDs: TMsgIntegerArray; const Text: AnsiString; var Results: TMsgIntegerArray): Integer; overload;
    {$IFDEF D6H}
    function SendMessageMultiple(ToUserIDs: TMsgIntegerArray; const Text: WideString; var Results: TMsgIntegerArray): Integer; overload;
    {$ELSE}
    function SendMessageMultipleW(ToUserIDs: TMsgIntegerArray; const Text: WideString; var Results: TMsgIntegerArray): Integer; overload;
    {$ENDIF}
    function SendMessageMultiple(ToUserIDs: TMsgIntegerArray; Buffer: PAnsiChar; Size: Integer;
                                        var Results: TMsgIntegerArray;
                                        Directly: Boolean = True;
                                        MessageType: TMsgMessageType = aamtBinary
                          ): Integer; overload;
    function SendMessageMultiple(ToUserIDs: TMsgIntegerArray; Stream: TStream; var Results: TMsgIntegerArray): Integer; overload;
// send message
    function SendMessage(ToUserID: Cardinal; const Text: AnsiString): Integer; overload;
    {$IFDEF D6H}
    function SendMessage(ToUserID: Cardinal; const Text: WideString): Integer; overload;
    {$ELSE}
    function SendMessageW(ToUserID: Cardinal; const Text: WideString): Integer; overload;
    {$ENDIF}
    function SendMessage(ToUserID: Cardinal; Buffer: PAnsiChar; Size: Integer;
                                        Directly: Boolean = True;
                                        MessageType: TMsgMessageType = aamtBinary
                          ): Integer; overload;
    function SendMessage(ToUserID: Cardinal; Stream: TStream): Integer; overload;
    function SendCommand(
                                ToUserID: Cardinal;
                                Command:  Cardinal;
                                Buffer:   PAnsiChar;
                                Size:     Integer
                                        ): Integer;
   public
    property ConnectionManager: TMsgServerConnectionManager read FConnectionManager;
    property LocalHost: AnsiString read GetLocalHost;
    property LocalPort: Integer read GetLocalPort;
    property CryptoParams: TMsgCryptoParamsEditor read FCryptoParamsEditor write FCryptoParamsEditor;
    property NetworkSettings: TMsgServerNetworkSettingsEditor read GetNetworkSettings; // For compatibility with Accuracer Connection unit
   published
    property Database: TMsgDatabase read FDatabase write FDatabase;
    property TempTable: TMsgTempTable read FTempTable write FTempTable;
    property MaxConnections: Integer read GetMaxConnections write FMaxConnections;
    property Active: Boolean read FActive write SetActive;
    property CurrentVersion: AnsiString read GetCurrentVersion write FCurrentVersion;
    property ConfigFileName: AnsiString read FConfigFileName write FConfigFileName;
    property DataPath: AnsiString read FDataPath write SetDataPath;
    property ConnectionParams: TMsgServerConnectParamsEditor read FConnectionParams write FConnectionParams;

// Start/Stop
    property BeforeServerStart: TNotifyEvent read FBeforeServerStart write FBeforeServerStart;
    property AfterServerStart: TNotifyEvent read FAfterServerStart write FAfterServerStart;
    property BeforeServerStop: TNotifyEvent read FBeforeServerStop write FBeforeServerStop;
    property AfterServerStop: TNotifyEvent read FAfterServerStop write FAfterServerStop;

// Connect/Disconnect
    property AfterConnect: TNotifyEvent read FAfterConnect write FAfterConnect;
    property BeforeConnect: TNotifyEvent read FBeforeConnect write FBeforeConnect;
    property AfterDisconnect: TNotifyEvent read FAfterDisconnect write FAfterDisconnect;
    property BeforeDisconnect: TNotifyEvent read FBeforeDisconnect write FBeforeDisconnect;

    property ServerID: Integer read FServerID write SetServerID;
    property StoreMessageHistory: Boolean read FStoreMessageHistory write FStoreMessageHistory;

    property MinUserID: Cardinal read FMinUserID write FMinUserID;

    property UseConfigFile: Boolean read FUseConfigFile write FUseConfigFile;

// Server properties
    property OnUserRegistered: TMsgOnUserRegistered read FOnUserRegistered write FOnUserRegistered;
    property OnUserInfoChanged: TMsgOnUserInfoChanged read FOnUserInfoChanged write FOnUserInfoChanged;
    property OnUserLogon: TMsgOnUserOnLine read FOnUserLogon write FOnUserLogon;
    property OnUserLogoff: TMsgOnUserOffLine read FOnUserLogoff write FOnUserLogoff;

  end; // TMsgServer



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerEventsThread
//
////////////////////////////////////////////////////////////////////////////////


  TMsgServerEventsThread = class(TMsgThread)
  private
    FServer:                  TMsgServer;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
    procedure LogUser(Event: PMsgEvent);
    function InitLargeObject(Event: PMsgEvent): Boolean;

  public
    constructor Create(
                          Server:          TMsgServer
                       );
    destructor Destroy; override;
  public
  end;// TMsgServerEventsThread



  function InstallingService: Boolean;
  function InteractiveService: Boolean;

  procedure AbortServerMessage(Server: TMsgServer; ToUserID: Cardinal);

implementation

{$IFDEF TRIAL_VERSION}
uses
  MsgCommunicator, Math;
{$ENDIF}

procedure AbortServerMessage(Server: TMsgServer; ToUserID: Cardinal);
var
  ToSession:            TMsgServerSession;
begin
{$IFDEF LOG_ABORT_SERVER_MESSAGE}
aaWriteToLog('AbortServerMessage> start');
{$ENDIF}
  ToSession := Server.FindSessionWithUser(ToUserID);
  if ToSession <> nil then
   begin
{$IFDEF LOG_ABORT_BLOCK}
aaWriteToLog('TMsgSendLargeObjectThread.AbortBlock> SendMessage...');
{$ENDIF}
    Server.ConnectionManager.SendMessage(ToSession,nil,0,MsgMessageAbort);
   end;
{$IFDEF LOG_ABORT_SERVER_MESSAGE}
aaWriteToLog('AbortServerMessage> finish');
{$ENDIF}
end;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerNetworkSettingsEditor.Create;
begin
  inherited Create;
  FServerReceiveTimeOut := MsgServerReceiveTimeOut;
  FServerReceiveSleep := MsgServerReceiveSleep;
  FMinServerSendTimeOut := MsgMinServerSendTimeOut;
  FServerSendTimeOut := MsgServerSendTimeOut;
  FServerWaitForSendSleep := MsgServerWaitForSendSleep;
  FServerResendDelay := MsgServerResendDelay;
  FServerRequestDelay := MsgServerRequestDelay;
  FWaitForMessagesSend := MsgWaitForMessagesSend;
  FWaitForServerSessionThreadTimeOut := MsgWaitForServerSessionThreadTimeOut;
  FServerThreadsTerminateDelay := MsgServerThreadsTerminateDelay;
  FServerSessionTerminatorSleep := MsgServerSessionTerminatorSleep;
  FPingCount := MsgPingCount;
  FWaitForPingAnswer := MsgWaitForPingAnswer;
  FPingClients := MsgPingClients;
  FServerPingSleep := MsgServerPingSleep;
  FKeepConnection := MsgKeepConnection;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgServerNetworkSettingsEditor.Destroy;
begin
  inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TMsgServerNetworkSettingsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TMsgServerNetworkSettingsEditor) then
    begin
      inherited Assign(Source);
      FServerReceiveTimeOut := TMsgServerNetworkSettingsEditor(Source).ServerReceiveTimeOut;
      FServerReceiveSleep := TMsgServerNetworkSettingsEditor(Source).ServerReceiveSleep;
      FMinServerSendTimeOut := TMsgServerNetworkSettingsEditor(Source).MinServerSendTimeOut;
      FServerSendTimeOut := TMsgServerNetworkSettingsEditor(Source).ServerSendTimeOut;
      FServerWaitForSendSleep := TMsgServerNetworkSettingsEditor(Source).ServerWaitForSendSleep;
      FServerResendDelay := TMsgServerNetworkSettingsEditor(Source).ServerResendDelay;
      FServerRequestDelay := TMsgServerNetworkSettingsEditor(Source).ServerRequestDelay;
      FWaitForMessagesSend := TMsgServerNetworkSettingsEditor(Source).WaitForMessagesSend;
      FWaitForServerSessionThreadTimeOut := TMsgServerNetworkSettingsEditor(Source).WaitForServerSessionThreadTimeOut;
      FServerThreadsTerminateDelay := TMsgServerNetworkSettingsEditor(Source).ServerThreadsTerminateDelay;
      FServerSessionTerminatorSleep := TMsgServerNetworkSettingsEditor(Source).ServerSessionTerminatorSleep;
      FPingClients := TMsgServerNetworkSettingsEditor(Source).PingClients;
      FPingCount := TMsgServerNetworkSettingsEditor(Source).PingCount;
      FWaitForPingAnswer := TMsgServerNetworkSettingsEditor(Source).WaitForPingAnswer;
      FServerPingSleep := TMsgServerNetworkSettingsEditor(Source).ServerPingSleep;
      FKeepConnection := TMsgServerNetworkSettingsEditor(Source).KeepConnection;
    end;
end; // Assign


//------------------------------------------------------------------------------
// Copy ServerNetwork settings to ConnectParams
//------------------------------------------------------------------------------
procedure TMsgServerNetworkSettingsEditor.CopySettingsToConnectParams(var ConnectParams: TMsgConnectParams);
begin
  inherited CopySettingsToConnectParams(ConnectParams);
  ConnectParams.ServerReceiveTimeOut := FServerReceiveTimeOut;
  ConnectParams.ServerReceiveSleep := FServerReceiveSleep;
  ConnectParams.MinServerSendTimeOut := FMinServerSendTimeOut;
  ConnectParams.ServerSendTimeOut := FServerSendTimeOut;
  ConnectParams.ServerWaitForSendSleep := FServerWaitForSendSleep;
  ConnectParams.ServerResendDelay := FServerResendDelay;
  ConnectParams.ServerRequestDelay := FServerRequestDelay;
  ConnectParams.WaitForMessagesSend := FWaitForMessagesSend;
  ConnectParams.WaitForServerSessionThreadTimeOut := FWaitForServerSessionThreadTimeOut;
  ConnectParams.ServerThreadsTerminateDelay := FServerThreadsTerminateDelay;
  ConnectParams.ServerSessionTerminatorSleep := FServerSessionTerminatorSleep;
  ConnectParams.PingClients := FPingClients;
  ConnectParams.PingCount := FPingCount;
  ConnectParams.WaitForPingAnswer := FWaitForPingAnswer;
  ConnectParams.ServerPingSleep := FServerPingSleep;
  ConnectParams.KeepConnection := FKeepConnection;
end; // CopySettingsToConnectParams


//------------------------------------------------------------------------------
// SetDefaultSettings
//------------------------------------------------------------------------------
procedure TMsgServerNetworkSettingsEditor.SetDefaultSettings(Value: TMsgDefaultNetworkSettings);
begin
  if Value = RestoreDefaultSettings then
    Exit;
  case Value of
   msgLocal:
    begin
     FServerReceiveTimeOut := MsgLocalServerReceiveTimeOut;
     FServerReceiveSleep := MsgServerReceiveSleep;
     FMinServerSendTimeOut := MsgLocalMinServerSendTimeOut;
     FServerSendTimeOut := MsgLocalServerSendTimeOut;
     FServerWaitForSendSleep := MsgServerWaitForSendSleep;
     FServerResendDelay := MsgLocalServerResendDelay;
     FServerRequestDelay := MsgLocalServerRequestDelay;
     FWaitForMessagesSend := MsgLocalWaitForMessagesSend;
     FWaitForServerSessionThreadTimeOut := MsgWaitForServerSessionThreadTimeOut;
     FServerThreadsTerminateDelay := MsgServerThreadsTerminateDelay;
     FServerSessionTerminatorSleep := MsgServerSessionTerminatorSleep;
     FPingCount := MsgLocalPingCount;
     FWaitForPingAnswer := MsgLocalWaitForPingAnswer;
     FPingClients := MsgPingClients;
     FServerPingSleep := MsgServerPingSleep;
     FKeepConnection := MsgKeepConnection;
    end;
   msgLAN:
    begin
     FServerReceiveTimeOut := MsgServerReceiveTimeOut;
     FServerReceiveSleep := MsgServerReceiveSleep;
     FMinServerSendTimeOut := MsgMinServerSendTimeOut;
     FServerSendTimeOut := MsgServerSendTimeOut;
     FServerWaitForSendSleep := MsgServerWaitForSendSleep;
     FServerResendDelay := MsgServerResendDelay;
     FServerRequestDelay := MsgServerRequestDelay;
     FWaitForMessagesSend := MsgWaitForMessagesSend;
     FWaitForServerSessionThreadTimeOut := MsgWaitForServerSessionThreadTimeOut;
     FServerThreadsTerminateDelay := MsgServerThreadsTerminateDelay;
     FServerSessionTerminatorSleep := MsgServerSessionTerminatorSleep;
     FPingCount := MsgPingCount;
     FWaitForPingAnswer := MsgWaitForPingAnswer;
     FPingClients := MsgPingClients;
     FServerPingSleep := MsgServerPingSleep;
     FKeepConnection := MsgKeepConnection;
    end;
   msgWAN:
    begin
     FServerReceiveTimeOut := MsgWANServerReceiveTimeOut;
     FServerReceiveSleep := MsgServerReceiveSleep;
     FMinServerSendTimeOut := MsgWANMinServerSendTimeOut;
     FServerSendTimeOut := MsgWANServerSendTimeOut;
     FServerWaitForSendSleep := MsgServerWaitForSendSleep;
     FServerResendDelay := MsgWANServerResendDelay;
     FServerRequestDelay := MsgWANServerRequestDelay;
     FWaitForMessagesSend := MsgWANWaitForMessagesSend;
     FWaitForServerSessionThreadTimeOut := MsgWaitForServerSessionThreadTimeOut;
     FServerThreadsTerminateDelay := MsgServerThreadsTerminateDelay;
     FServerSessionTerminatorSleep := MsgServerSessionTerminatorSleep;
     FPingCount := MsgWANPingCount;
     FWaitForPingAnswer := MsgWANWaitForPingAnswer;
     FPingClients := MsgPingClients;
     FServerPingSleep := MsgServerPingSleep;
     FKeepConnection := MsgKeepConnection;
    end;
   msgModem:
    begin
     FServerReceiveTimeOut := MsgModemServerReceiveTimeOut;
     FServerReceiveSleep := MsgServerReceiveSleep;
     FMinServerSendTimeOut := MsgModemMinServerSendTimeOut;
     FServerSendTimeOut := MsgModemServerSendTimeOut;
     FServerWaitForSendSleep := MsgServerWaitForSendSleep;
     FServerResendDelay := MsgModemServerResendDelay;
     FServerRequestDelay := MsgModemServerRequestDelay;
     FWaitForMessagesSend := MsgModemWaitForMessagesSend;
     FWaitForServerSessionThreadTimeOut := MsgWaitForServerSessionThreadTimeOut;
     FServerThreadsTerminateDelay := MsgServerThreadsTerminateDelay;
     FServerSessionTerminatorSleep := MsgServerSessionTerminatorSleep;
     FPingCount := MsgModemPingCount;
     FWaitForPingAnswer := MsgModemWaitForPingAnswer;
     FPingClients := MsgPingClients;
     FServerPingSleep := MsgServerPingSleep;
     FKeepConnection := MsgKeepConnection;
    end;
  end;
  inherited SetDefaultSettings(Value);
end; // SetDefaultSettings



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerConnectParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TMsgServerConnectParamsEditor.Create;
begin
  inherited;
  LocalPort := MsgDefaultServerPort;
  FNetworkSettings := TMsgServerNetworkSettingsEditor.Create;
end;//Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgServerConnectParamsEditor.Destroy;
begin
  FNetworkSettings.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TMsgServerConnectParamsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TMsgConnectionParamsEditor) then
    begin
     inherited Assign(Source);
     FNetworkSettings.Assign(TMsgServerConnectParamsEditor(Source).NetworkSettings);
    end;
end; // Assign


//------------------------------------------------------------------------------
// return ConnectParams
//------------------------------------------------------------------------------
function TMsgServerConnectParamsEditor.GetConnectParams: TMsgConnectParams;
begin
  Result := inherited GetConnectParams;
  FNetworkSettings.CopySettingsToConnectParams(Result);
end; // GetConnectParams


////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerSession
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerSession.Create(aServer: TComponent);
begin
  InitializeCriticalSection(FCSect);
  inherited Create(aServer);
  FConnectParams := TMsgServer(FOwnerComponent).ConnectionParams.GetConnectParams;
  FLogged := False;
  FSkipLoadingContacts := False;
  FServerSession := nil;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgServerSession.Destroy;
var
  i:        Integer;
  Event:    PMsgEvent;
  Queue:    TMsgList;
begin
  Queue := TMsgServer(FOwnerComponent).FEventsQueue.LockList;
  try
   for i := Queue.Count-1 downto 0 do
    begin
     Event := Queue.Items[i];
     if Event.Session = Self then
       if Event.EventType <> MsgUserOffLine then
       if Event.EventType <> MsgInitLargeObject then
       if Event.EventType <> MsgAbortLargeObject then
        begin
         Dispose(Event);
         Queue.Delete(i);
        end;
    end;
  finally
   TMsgServer(FOwnerComponent).FEventsQueue.UnlockList;
  end;
  inherited Destroy;
  DeleteCriticalSection(FCSect);
end; // Destroy


//------------------------------------------------------------------------------
// call OnError event handler
//------------------------------------------------------------------------------
procedure TMsgServerSession.DoOnError(ErrorCode: Integer; NativeError: Integer = -1; ErrorMessage: AnsiString = '');
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error on server session!');
aaWriteToLog('------------------------------------------------------------------');
aaWriteToLog('SessionID='+IntToStr(Integer(self.SessionID)));
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
{$ENDIF}
  if (TMsgServer(FOwnerComponent) <> nil) then
   TMsgServer(FOwnerComponent).DoOnError(ErrorCode,NativeError,ErrorMessage);
end; // DoOnError


//------------------------------------------------------------------------------
// Send command error occured - session must be destroyed
//------------------------------------------------------------------------------
procedure TMsgServerSession.DoCloseSessionOnNetworkError;
begin
 {$IFDEF DEBUG_LOG_COMMUNICATION}
 aaWriteToLog('Server DoCloseSessionOnNetworkError starting, SessionID = '+IntToStr(SessionID));
 {$ENDIF}
  TMsgServer(FOwnerComponent).FConnectionManager.TerminateSession(self);
 {$IFDEF DEBUG_LOG_COMMUNICATION}
 aaWriteToLog('Server DoCloseSessionOnNetworkError finish, SessionID = '+IntToStr(SessionID));
 {$ENDIF}
end; // DoCloseSessionOnNetworkError


//------------------------------------------------------------------------------
// ConnectUser
//------------------------------------------------------------------------------
function TMsgServerSession.ConnectUser: Boolean;
begin
 try
  if (not Connected) then
   begin
    Result := TMsgServer(FOwnerComponent).ConnectSession(Self);
    if (Result) then
     FConnected := True;
   end
  else
   Result := True;
 except
  Result := False;
 end;
end; // ConnectUser


//------------------------------------------------------------------------------
// DisconnectUser
//------------------------------------------------------------------------------
procedure TMsgServerSession.DisconnectUser;
begin
  FConnected := False;
  Logged := False;
  TMsgServer(FOwnerComponent).DisconnectSession(Self);
end; // DisconnectUser


//------------------------------------------------------------------------------
// execute received command
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteReceivedCommand(var Buffer: PAnsiChar; BufferSize: Integer);
var
  ms:             TMsgMemoryStream;
  CommandHeader:  TMsgCommandHeader;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog(#13#10+'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');
aaWriteToLog('S> ServerSession is starting to execute a received command...');
aaWriteToLog('S> SessionID = '+IntToStr(SessionID)+', ServerID = '+IntToStr(TMsgServer(FOwnerComponent).ServerID)+#13#10+
             'S> Client UserID = '+IntToStr(Integer(FUserID))+#13#10+
             'S> Client Host = '+ConnectParams.RemoteHost+#13#10+
             'S> Client Port = '+IntToStr(ConnectParams.RemotePort)+#13#10
             );
aaWriteBufferToLog(Buffer,BufferSize);
aaWriteToLog('S> Execute Start Time = '+aaGetCurrentTimeAsString);
try
{$ENDIF}
  if (Buffer <> nil) and (BufferSize >= SizeOf(CommandHeader)) then
   begin
    ms := TMsgMemoryStream.Create(Buffer,BufferSize);
    try
      try
       Move(Buffer^,CommandHeader,SizeOf(CommandHeader));
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('S> CommandCode = '+IntToStr(CommandHeader.CommandCode));
{$ENDIF}
       CommandHeader.NativeError := 0;
       ms.Position := SizeOf(CommandHeader);
       if (not Logged) or (FUserID = MSG_INVALID_USER_ID) // guest
         then
         if (CommandHeader.CommandCode <> MsgLogon) then
           if (CommandHeader.CommandCode <> MsgRegisterNewUser) then
             if (CommandHeader.CommandCode <> MsgFindUsers) then
               if (CommandHeader.CommandCode <> MsgIsUserExisting) then
                 if (CommandHeader.CommandCode <> MsgFindUserID) then
                  begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('S> Command ignored, Logged = '+BoolToStr(Logged,True)+', FUserID = '+IntToStr(FUserID));
{$ENDIF}
                   Exit;
                  end;
       case CommandHeader.CommandCode of
        MsgGetUserInfo:            ExecuteGetUserInfo(CommandHeader,ms);
        MsgGetUserID:              ExecuteGetUserID(CommandHeader,ms);
        MsgGetContacts:            ExecuteGetContacts(CommandHeader,ms);
        MsgIsUserExisting:         ExecuteIsUserExisting(CommandHeader,ms);
        MsgIsUserOnline:           ExecuteIsUserOnline(CommandHeader,ms);
        MsgRegisterNewUser:        ExecuteRegisterNewUser(CommandHeader,ms);
        MsgUpdateUserInfo:         ExecuteUpdateUserInfo(CommandHeader,ms);
        MsgAddUserToContacts:      ExecuteAddUserToContacts(CommandHeader,ms);
        MsgUpdateUserInContacts:   ExecuteUpdateUserInContacts(CommandHeader,ms);
        MsgRemoveUserFromContacts: ExecuteRemoveUserFromContacts(CommandHeader,ms);
        MsgFindUserID:             ExecuteFindUserID(CommandHeader,ms);
        MsgFindUsers:              ExecuteFindUsers(CommandHeader,ms);
        MsgFindMessages:           ExecuteFindMessages(CommandHeader,ms);
        MsgLogon:                  ExecuteLogon(CommandHeader,ms);
        MsgLogoff:                 ExecuteLogoff(CommandHeader,ms);
        MsgInitProgressSend:       ExecuteInitProgressRecv(CommandHeader,ms);
       end;
      except
       // ignore invalid buffer
       on e: EMsgException do
        TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
       on e: Exception do
        TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
       else
        TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
      end;
    finally
      ms.Free;
    end;
   end
  else
   if (Buffer <> nil) then
     MemoryManager.FreeAndNilMem(Buffer);
{$IFDEF DEBUG_LOG_COMMUNICATION}
finally
 aaWriteToLog('S> Execute End Time = '+aaGetCurrentTimeAsString);
 aaWriteToLog('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+#13#10);
end;
{$ENDIF}
end; // ExecuteReceivedCommand


//------------------------------------------------------------------------------
// SetLogged
//------------------------------------------------------------------------------
procedure TMsgServerSession.SetLogged(value: boolean);
begin
 try
  if Logged = value then
    Exit;
  FLogged := value;
  if (value) then
   begin
   // load contact count for this user
    // Back link to corresponding structure (PMsgSrvrSession) in ConnectionManager.Sessions
    if (FServerSession = nil) then
     raise EMsgException.Create(11586,ErrorLInvalidPointer);
    PMsgSrvrSession(FServerSession)^.ContactCount := TMsgServer(FOwnerComponent).GetUserContactCount(FUserID);
   end;
  TMsgServer(FOwnerComponent).LogUser(Self, value);
 finally
  FSkipLoadingContacts := False;
 end;
end;// SetLogged


//------------------------------------------------------------------------------
// SetConnected
//------------------------------------------------------------------------------
procedure TMsgServerSession.SetConnected(value: boolean);
begin
  FConnected := value;
end;// SetConnected


//------------------------------------------------------------------------------
// Back link to corresponding structure (PMsgSrvrSession) in ConnectionManager.Sessions
//------------------------------------------------------------------------------
procedure TMsgServerSession.SetServerSession(value: Pointer);
begin
  FServerSession := value;
end; // SetServerSession


//------------------------------------------------------------------------------
// ExecuteLogon
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteLogon(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var UserID:   Cardinal;
    Password: AnsiString;
    Buffer:   PAnsiChar;
    Port:     Integer;
    Host,App: AnsiString;
begin
 CommandHeader.CommandResult := MSG_Error_Logon_InvalidParams;
 try
   LoadDataFromStream(UserID,SizeOf(UserID),Stream,40086);
   LoadStringFromStream(Password,Stream,40087);
   CommandHeader.CommandResult := MSG_Error_Logon_InternalServerError;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_Error_Logon_InternalServerError) then
  begin
   try
    if not (TMsgServer(FOwnerComponent).IsUserExisting(UserID)) then
     begin
      CommandHeader.CommandResult := MSG_Error_Logon_UserDoesNotExist;
      FUserID := MSG_INVALID_USER_ID;
     end
    else
     begin
      FUserID := UserID;
      if (TMsgServer(FOwnerComponent).FConnectedUsers.ItemCount > MsgMaxSingleUserConnections) then
        CommandHeader.CommandResult := MSG_Error_Logon_MaxConnectionsExceeded
      else
       begin
        if (TMsgServer(FOwnerComponent).IsUserLogged(UserID)) then
         begin
          CommandHeader.CommandResult := MSG_Error_Logon_UserAlreadyLogged;
         end
        else
         begin
          if not (TMsgServer(FOwnerComponent).IsPasswordValid(UserID,Password)) then
           begin
            CommandHeader.CommandResult := MSG_Error_Logon_InvalidPassword;
            Logged := False;
           end
          else
           begin
            CommandHeader.CommandResult := MSG_COMMAND_OK;
            Logged := True;
            Connected := True;
           end;
         end;
       end;
     end;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,40090);
 Buffer := Stream.Buffer;
 try
  SendBuffer(Buffer,Stream.Size);
 except
 end;
 if CommandHeader.CommandResult = MSG_COMMAND_OK then
  begin
    if (Assigned(TMsgServer(FOwnerComponent).FOnUserLogon)) then
     TMsgServer(FOwnerComponent).OnUserLogon(FUserID);
    try // Change user status
     if (TMsgServer(FOwnerComponent).FDatabase <> nil) then
      begin
        TMsgServer(FOwnerComponent).FConnectionManager.GetClientInfo(Self,Host,Port,App);
        TMsgServer(FOwnerComponent).FDatabase.ChangeUserStatus(False,FUserID,msgOnline,Host,Port,App);
      end;
     except
        TMsgServer(FOwnerComponent).DoOnError(40094,-1,ErrorRServerOnLineCannotChangeUserStatus+IntToStr(FUserID));
     end;
  end;
end; // ExecuteLogon


//------------------------------------------------------------------------------
// ExecuteLogoff
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteLogoff(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var UserID:   Cardinal;
    Password: AnsiString;
    Buffer:   PAnsiChar;
begin
 CommandHeader.CommandResult := MSG_Error_Logoff_InvalidParams;
 try
   LoadDataFromStream(UserID,SizeOf(UserID),Stream,40088);
   LoadStringFromStream(Password,Stream,40089);
   CommandHeader.CommandResult := MSG_Error_Logoff_InternalServerError;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_Error_Logoff_InternalServerError) then
  begin
   try
    if not (TMsgServer(FOwnerComponent).IsUserExisting(UserID)) then
     begin
      CommandHeader.CommandResult := MSG_Error_Logoff_UserDoesNotExist
     end
    else
     begin
      if not (TMsgServer(FOwnerComponent).IsUserLogged(UserID)) then
       begin
        CommandHeader.CommandResult := MSG_Error_Logoff_UserNotLogged;
       end
      else
       begin
        if not (TMsgServer(FOwnerComponent).IsPasswordValid(UserID,Password)) then
         begin
          CommandHeader.CommandResult := MSG_Error_Logoff_InvalidPassword;
         end
        else
         begin
          CommandHeader.CommandResult := MSG_COMMAND_OK;
          Logged := False;
         end;
       end;
     end;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,40091);
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
 if CommandHeader.CommandResult = MSG_COMMAND_OK then
  if (Assigned(TMsgServer(FOwnerComponent).FOnUserLogoff)) then
   TMsgServer(FOwnerComponent).OnUserLogoff(FUserID);
end; // ExecuteLogoff


//------------------------------------------------------------------------------
// InitProgressSend
//------------------------------------------------------------------------------
function TMsgServerSession.InitProgressSend(
                              ObjectType: TMsgMessageType;
                              ToUserID: Cardinal;
                              const FileName: AnsiString;
                              FullSize: Int64;
                              Blocks: Integer;
                              BlockSize: Integer;
                              var ObjectID: Cardinal
                              ): Integer;
var
  LargeObject:      PMsgLargeObject;
begin
  EnterCriticalSection(TMsgServer(FOwnerComponent).FCsect);
  if TMsgServer(FOwnerComponent).FObjectID = 0 then
    TMsgServer(FOwnerComponent).FObjectID := MSG_INVALID_ID;
  dec(TMsgServer(FOwnerComponent).FObjectID);
  ObjectID := TMsgServer(FOwnerComponent).FObjectID;
  LeaveCriticalSection(TMsgServer(FOwnerComponent).FCsect);
  Result := 0;
  New(LargeObject);
  LargeObject.ObjectID := ObjectID;
  LargeObject.ObjectType := ObjectType;
  LargeObject.FileName := FileName;
  LargeObject.FullSize := FullSize;
  LargeObject.Blocks := Blocks;
  LargeObject.BlockSize := BlockSize;
  LargeObject.ToUserID := ToUserID;
  AddInitEvent(TMsgServer(FOwnerComponent).ServerID,LargeObject);
  Result := MSG_COMMAND_OK;
end; // InitProgressSend


//------------------------------------------------------------------------------
// AddInitEvent
//------------------------------------------------------------------------------
procedure TMsgServerSession.AddInitEvent(UserID: Cardinal; LargeObject: PMsgLargeObject);
var
  InitEvent:        PMsgEvent;
begin
  New(InitEvent);
  InitEvent.FromUserID := UserID;
  InitEvent.Session := Self;
  InitEvent.EventType := MsgInitLargeObject;
  InitEvent.LargeObject := LargeObject;
  TMsgServer(FOwnerComponent).FEventsQueue.Add(InitEvent);
end; // AddInitEvent


//------------------------------------------------------------------------------
// ExecuteInitProgressRecv
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteInitProgressRecv(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var
  ObjectID:         Cardinal;
  Buffer:           PAnsiChar;
  ms:               TMsgMemoryStream;
  LargeObject:      PMsgLargeObject;
  RecvObject:       PMsgRecvObject;
begin
 ObjectID := MSG_INVALID_ID;
 if not TMsgServer(FOwnerComponent).AllowFiles then
  begin
   CommandHeader.CommandResult := MSG_Error_InitProgressRecv_ServerDeny;
  end
 else
  begin
   New(LargeObject);
   CommandHeader.CommandResult := MSG_Error_InitProgressRecv_InvalidParams;
   try
    LoadDataFromStream(Byte(LargeObject.ObjectType),SizeOf(LargeObject.ObjectType),Stream,40118);
    LoadDataFromStream(LargeObject.ToUserID,SizeOf(LargeObject.ToUserID),Stream,40119);
    if LargeObject.ObjectType = aamtsFile then
      LoadStringFromStream(LargeObject.Filename,Stream,40120)
    else
      LargeObject.FileName := '';
    LoadDataFromStream(LargeObject.FullSize,SizeOf(LargeObject.FullSize),Stream,40121);
    LoadDataFromStream(LargeObject.Blocks,SizeOf(LargeObject.Blocks),Stream,40122);
    LoadDataFromStream(LargeObject.BlockSize,SizeOf(LargeObject.BlockSize),Stream,40123);
    CommandHeader.CommandResult := MSG_COMMAND_OK;
   except
    on e: EMsgException do
     TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
    on e: Exception do
     TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
     TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
   if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
    begin
     try
      CommandHeader.CommandResult := MSG_Error_InitProgressRecv_Failed;
      EnterCriticalSection(TMsgServer(FOwnerComponent).FCSect);
      if ObjectID = 0 then
        ObjectID := MSG_INVALID_ID;
      dec(TMsgServer(FOwnerComponent).FObjectID);
      ObjectID := TMsgServer(FOwnerComponent).FObjectID;
      LeaveCriticalSection(TMsgServer(FOwnerComponent).FCSect);
      CommandHeader.CommandResult := MSG_COMMAND_OK;
     except
       on e: EMsgException do
        TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
       on e: Exception do
        TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
       else
        TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
     end;
    end;
  end; // AllowReceiveFiles
 // Send answer to sender
 ms := TMsgMemoryStream.Create;
 try
  SaveDataToStream(CommandHeader,SizeOf(CommandHeader),ms,40124);
  SaveDataToStream(ObjectID,SizeOf(ObjectID),ms,40125);
  Buffer := ms.Buffer;
  SendBuffer(Buffer,ms.Size);
 finally
  ms.Free;
 end;
 if (CommandHeader.CommandResult <> MSG_COMMAND_OK) then
  begin
   Dispose(LargeObject);
   Exit;
  end;
 LargeObject.ObjectID := ObjectID;
 if (LargeObject.ToUserID <> TMsgServer(FOwnerComponent).ServerID) then
  begin  // to client: save client event for transmition
   AddInitEvent(UserID,LargeObject);
  end
 else
  begin // to server: add to queue for receiving
   New(RecvObject);
   RecvObject.ObjectID := LargeObject.ObjectID;
   RecvObject.ObjectType := LargeObject.ObjectType;
   RecvObject.FileName := LargeObject.FileName;
   RecvObject.FullSize := LargeObject.FullSize;
   RecvObject.Blocks := LargeObject.Blocks;
   RecvObject.BlockSize := LargeObject.BlockSize;
   RecvObject.Directly := true;
   RecvObject.SendingDate := Now;
   TMsgServer(FOwnerComponent).FRecvQueue.Add(RecvObject);
 // Server event
   if TMsgServer(FOwnerComponent).AllowFiles then
    if LargeObject.ObjectType = aamtsFile then
     begin
      if (Assigned(TMsgServer(FOwnerComponent).OnReceiveFile)) then
        TMsgServer(FOwnerComponent).OnReceiveFile(FUserID,ObjectID,0,0,LargeObject.FileName,LargeObject.FullSize,LargeObject.BlockSize,-1,LargeObject.Blocks,true);
     end
    else
    if LargeObject.ObjectType = aamtsStream then
     begin
      if (Assigned(TMsgServer(FOwnerComponent).OnReceiveStream)) then
        TMsgServer(FOwnerComponent).OnReceiveStream(FUserID,ObjectID,0,0,LargeObject.FullSize,LargeObject.BlockSize,-1,LargeObject.Blocks,true);
     end;
   Dispose(LargeObject);
  end;
end; // ExecuteInitProgressRecv


//------------------------------------------------------------------------------
// get user info if user exists, otherwise return error code
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteGetUserInfo(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var UserID:   Cardinal;
    Buffer:   PAnsiChar;
    UserInfo: TMsgUserInfo;
begin
 CommandHeader.CommandResult := MSG_Error_GetUserInfo_InvalidParams;
 try
   LoadDataFromStream(UserID,SizeOf(UserID),Stream,11464);
   CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    CommandHeader.CommandResult := MSG_Error_GetUserInfo_UserDoesNotExist;
    UserInfo := TMsgServer(FOwnerComponent).GetUserInfo(UserID);
    if (UserInfo.UserID <> MSG_INVALID_USER_ID) then
     CommandHeader.CommandResult := MSG_COMMAND_OK;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
   SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11465);
   if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
    TMsgServer(FOwnerComponent).SaveUserInfoToStream(UserInfo,Stream);
  end
 else
   SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11466);
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
end; // ExecuteGetUserInfo


//------------------------------------------------------------------------------
// get user info if user exists, otherwise return error code
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteGetUserID(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var
    Buffer:   PAnsiChar;
begin
  CommandHeader.CommandResult := MSG_COMMAND_OK;
  Stream.Size := 0;
  Stream.Position := 0;
  SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11467);
  SaveDataToStream(FUserID,SizeOf(FUserID),Stream,11468);
  Buffer := Stream.Buffer;
  SendBuffer(Buffer,Stream.Size);
end; // ExecuteGetUserID


//------------------------------------------------------------------------------
// get contacts
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteGetContacts(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var
    Buffer:   PAnsiChar;
    Contacts: TMsgContactInfoArray;
    Queue:TMsgList;
begin
  CommandHeader.CommandResult := MSG_Error_GetContacts_Failed;
  try
   TMsgServer(FOwnerComponent).GetUserContacts(FUserID,Contacts);
   CommandHeader.CommandResult := MSG_COMMAND_OK;
  except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
  end;
  Stream.Size := 0;
  Stream.Position := 0;
  SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11469);
  if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
   begin
    TMsgServer(FOwnerComponent).SaveContactsToStream(Contacts,Stream);
   end;
  Buffer := Stream.Buffer;
  SendBuffer(Buffer,Stream.Size);
  TMsgServer(FOwnerComponent).SendStoredMessages(Self);
{
aaStartTime(time1);
  Queue := TMsgServer(FOwnerComponent).FEventsQueue.LockList;
aaStopTime(time1);
  try
aaStartTime(time7);
   Queue.Add(Buffer);
aaStopTime(time7);
aaStartTime(time8);
   Queue.Delete(0);
aaStopTime(time8);
  finally
aaStartTime(time9);
   TMsgServer(FOwnerComponent).FEventsQueue.UnlockList;
aaStopTime(time9);
  end;
}
end; // ExecuteGetContacts


//------------------------------------------------------------------------------
// return true if user exists
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteIsUserExisting(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var UserID:   Cardinal;
    Buffer:   PAnsiChar;
begin
 CommandHeader.CommandResult := MSG_Error_IsUserExisting_InvalidParams;
 try
   LoadDataFromStream(UserID,SizeOf(UserID),Stream,11476);
   CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    if (TMsgServer(FOwnerComponent).IsUserExisting(UserID)) then
     CommandHeader.CommandResult := MSG_COMMAND_RESULT_TRUE
    else
     CommandHeader.CommandResult := MSG_COMMAND_RESULT_FALSE;
   except
    CommandHeader.CommandResult := MSG_Error_IsUserExisting_Failed;
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11477);
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
end; // ExecuteIsUserExisting


//------------------------------------------------------------------------------
// ExecuteFindUserID
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteFindUserID(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var
  UserName: ShortString;
  UserID:   Cardinal;
  Buffer:   PAnsiChar;
begin
 CommandHeader.CommandResult := MSG_Error_FindUserID_InvalidParams;
 try
   LoadShortStringFromStream(UserName,Stream,40151);
   CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    UserID := TMsgServer(FOwnerComponent).FindUserID(UserName);
   except
    CommandHeader.CommandResult := MSG_Error_FindUserID_Failed;
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,40152);
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
   SaveDataToStream(UserID,SizeOf(UserID),Stream,40153);
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
end; // ExecuteFindUserID


//------------------------------------------------------------------------------
// return true if user is connected to server
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteIsUserOnline(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var UserID:   Cardinal;
    Buffer:   PAnsiChar;
begin
 CommandHeader.CommandResult := MSG_Error_IsUserOnline_InvalidParams;
 try
   LoadDataFromStream(UserID,SizeOf(UserID),Stream,11478);
   CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    if (TMsgServer(FOwnerComponent).IsUserConnected(UserID)) then
     CommandHeader.CommandResult := MSG_COMMAND_RESULT_TRUE
    else
     CommandHeader.CommandResult := MSG_COMMAND_RESULT_FALSE;
   except
    CommandHeader.CommandResult := MSG_Error_IsUserOnline_Failed;
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11479);
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
end; // ExecuteIsUserOnline


//------------------------------------------------------------------------------
// try to register new user and send error code if failed
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteRegisterNewUser(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var
    Buffer:   PAnsiChar;
    UserInfo: TMsgUserInfo;
    Password: ShortString;
    Logon:    Boolean;
begin
 CommandHeader.CommandResult := MSG_Error_RegisterNewUser_InvalidParams;
 try
   TMsgServer(FOwnerComponent).LoadUserInfoFromStream(UserInfo,Stream);
   LoadShortStringFromStream(Password,Stream,11481);
   LoadBooleanFromStream(Logon,Stream,40102);
   CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    CommandHeader.CommandResult := MSG_Error_RegisterNewUser_Failed;
    if (UserInfo.UserID = MSG_INVALID_USER_ID) then
     begin
      FUserID := TMsgServer(FOwnerComponent).GetNewUserID;
      UserInfo.UserID := FUserID; // temporary replace for AddUser
      TMsgServer(FOwnerComponent).AddUser(UserInfo,Password);
      UserInfo.UserID := MSG_INVALID_USER_ID; // restore as is to save UserID in answer
      FSkipLoadingContacts := Logon;
      Logged := Logon;
      CommandHeader.CommandResult := MSG_COMMAND_OK;
     end
    else
     begin
      if (TMsgServer(FOwnerComponent).IsUserExisting(UserInfo.UserID)) then
       begin
        CommandHeader.CommandResult := MSG_Error_RegisterNewUser_UserAlreadyExists;
       end
      else
       begin
        FUserID := UserInfo.UserID;
        TMsgServer(FOwnerComponent).AddUser(UserInfo,Password);
        FSkipLoadingContacts := Logon;
        Logged := Logon;
        CommandHeader.CommandResult := MSG_COMMAND_OK;
       end;
     end;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11484);
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
   if (UserInfo.UserID = MSG_INVALID_USER_ID) then
     SaveDataToStream(FUserID,SizeOf(UserInfo.UserID),Stream,40093);
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  if (Assigned(TMsgServer(FOwnerComponent).FOnUserRegistered)) then
   TMsgServer(FOwnerComponent).OnUserRegistered(FUserID);
end; // ExecuteRegisterNewUser


//------------------------------------------------------------------------------
// try to update user information and send error code if failed
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteUpdateUserInfo(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var
    Buffer:         PAnsiChar;
    UserInfo:       TMsgUserInfo;
    ChangePassword: Boolean;
    Password:       ShortString;
begin
 CommandHeader.CommandResult := MSG_Error_UpdateUserInfo_InvalidParams;
 try
   TMsgServer(FOwnerComponent).LoadUserInfoFromStream(UserInfo,Stream);
   LoadBooleanFromStream(ChangePassword,Stream,11486);
   LoadShortStringFromStream(Password,Stream,11487);
   UserInfo.UserID := FUserID;
   CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    CommandHeader.CommandResult := MSG_Error_UpdateUserInfo_Failed;
    if (not TMsgServer(FOwnerComponent).IsUserExisting(UserInfo.UserID)) then
      CommandHeader.CommandResult := MSG_Error_UpdateUserInfo_UserDoesNotExist
    else
     begin
      TMsgServer(FOwnerComponent).ChangeUserInfo(UserInfo,ChangePassword,Password);
      CommandHeader.CommandResult := MSG_COMMAND_OK;
     end;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11488);
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
end; // ExecuteUpdateUserInfo


//------------------------------------------------------------------------------
// add user to contacts
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteAddUserToContacts(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var UserID:             Cardinal;
    Buffer:             PAnsiChar;
    ContactCustomName:  ShortString;
    ContactNameSource:  TMsgContactNameSource;
    UserInfo:           TMsgUserInfo;
begin
 CommandHeader.CommandResult := MSG_Error_AddUserToContacts_InvalidParams;
 try
   LoadDataFromStream(UserID,SizeOf(UserID),Stream,11502);
   LoadDataFromStream(ContactNameSource,SizeOf(ContactNameSource),Stream,11503);
   LoadShortStringFromStream(ContactCustomName,Stream,11504);
   CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    CommandHeader.CommandResult := MSG_Error_AddUserToContacts_Failed;
    if (not TMsgServer(FOwnerComponent).IsUserExisting(UserID)) then
      CommandHeader.CommandResult := MSG_Error_AddUserToContacts_UserDoesNotExist
    else
     begin
      TMsgServer(FOwnerComponent).AddUserToContacts(Self,FUserID,UserID,ContactNameSource,ContactCustomName);
      CommandHeader.CommandResult := MSG_COMMAND_OK;
     end;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11505);
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   UserInfo := TMsgServer(FOwnerComponent).GetUserInfo(UserID);
   TMsgServer(FOwnerComponent).SaveUserInfoToStream(UserInfo,Stream);
  end;
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
end; // ExecuteAddUserToContacts


//------------------------------------------------------------------------------
// update user in contacts
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteUpdateUserInContacts(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var UserID:             Cardinal;
    Buffer:             PAnsiChar;
    ContactCustomName:  ShortString;
    ContactNameSource:  TMsgContactNameSource;
begin
 CommandHeader.CommandResult := MSG_Error_UpdateUserInContacts_InvalidParams;
 try
   LoadDataFromStream(UserID,SizeOf(UserID),Stream,11509);
   LoadDataFromStream(ContactNameSource,SizeOf(ContactNameSource),Stream,11510);
   LoadShortStringFromStream(ContactCustomName,Stream,11511);
   CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    CommandHeader.CommandResult := MSG_Error_UpdateUserInContacts_Failed;
    if (not TMsgServer(FOwnerComponent).IsUserExisting(UserID)) then
      CommandHeader.CommandResult := MSG_Error_UpdateUserInContacts_UserDoesNotExist
    else
     begin
      TMsgServer(FOwnerComponent).UpdateUserInContacts(FUserID,UserID,ContactNameSource,ContactCustomName);
      CommandHeader.CommandResult := MSG_COMMAND_OK;
     end;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11512);
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
end; // ExecuteUpdateUserInContacts


//------------------------------------------------------------------------------
// remove user from contacts
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteRemoveUserFromContacts(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var UserID:             Cardinal;
    Buffer:             PAnsiChar;
begin
 CommandHeader.CommandResult := MSG_Error_RemoveUserFromContacts_InvalidParams;
 try
   LoadDataFromStream(UserID,SizeOf(UserID),Stream,11514);
   CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    CommandHeader.CommandResult := MSG_Error_RemoveUserFromContacts_Failed;
    if (not TMsgServer(FOwnerComponent).IsUserExisting(UserID)) then
      CommandHeader.CommandResult := MSG_Error_RemoveUserFromContacts_UserDoesNotExist
    else
     begin
      TMsgServer(FOwnerComponent).RemoveUserFromContacts(Self,FUserID,UserID);
      CommandHeader.CommandResult := MSG_COMMAND_OK;
     end;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11515);
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
end; // ExecuteRemoveUserFromContacts


//------------------------------------------------------------------------------
// find users
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteFindUsers(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var
    Buffer:           PAnsiChar;
    Len,i:            Integer;
    Users:            TMsgUserInfoArray;
    UserNameComparison:      TMsgTextComparison;
    FirstNameComparison:     TMsgTextComparison;
    LastNameComparison:      TMsgTextComparison;
    OrganizationComparison:  TMsgTextComparison;
    DepartmentComparison:    TMsgTextComparison;
    ApplicationComparison:   TMsgTextComparison;
    HostComparison:          TMsgTextComparison;
    PortComparison:          TMsgIntegerComparison;
    Status:           TMsgUserStatus;
    UserID:           Cardinal;
    UserName:         AnsiString;
    FirstName:        AnsiString;
    LastName:         AnsiString;
    Organization:     AnsiString;
    Department:       AnsiString;
    Host:             AnsiString;
    Application:      AnsiString;
    SearchCondition:  AnsiString; // SQL WHERE clause without word WHERE
    SortBy:           TMsgUserInfoArraySortBy;
    Ascending:        Boolean;
    OrderByClause:    AnsiString;
begin
 CommandHeader.CommandResult := MSG_Error_FindUsers_InvalidParams;
 try
    // load
    LoadDataFromStream(UserNameComparison,SizeOf(UserNameComparison),Stream,11520);
    LoadDataFromStream(FirstNameComparison,SizeOf(FirstNameComparison),Stream,11521);
    LoadDataFromStream(LastNameComparison,SizeOf(LastNameComparison),Stream,11522);
    LoadDataFromStream(OrganizationComparison,SizeOf(OrganizationComparison),Stream,11523);
    LoadDataFromStream(DepartmentComparison,SizeOf(DepartmentComparison),Stream,11524);
    LoadDataFromStream(ApplicationComparison,SizeOf(ApplicationComparison),Stream,11525);
    LoadDataFromStream(HostComparison,SizeOf(HostComparison),Stream,11526);
    LoadDataFromStream(PortComparison,SizeOf(PortComparison),Stream,11527);
    LoadDataFromStream(Status,SizeOf(Status),Stream,11528);
    LoadDataFromStream(UserID,SizeOf(UserID),Stream,11529);
    LoadStringFromStream(UserName,Stream,11530);
    LoadStringFromStream(FirstName,Stream,11531);
    LoadStringFromStream(LastName,Stream,11532);
    LoadStringFromStream(Organization,Stream,11533);
    LoadStringFromStream(Department,Stream,11534);
    LoadStringFromStream(Host,Stream,11535);
    LoadStringFromStream(Application,Stream,11536);
    LoadStringFromStream(SearchCondition,Stream,11547);
    LoadDataFromStream(SortBy,SizeOf(SortBy),Stream,11540);
    LoadBooleanFromStream(Ascending,Stream,11541);
    LoadStringFromStream(OrderByClause,Stream,11542);
    CommandHeader.CommandResult := MSG_COMMAND_OK;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    CommandHeader.CommandResult := MSG_Error_FindUsers_Failed;
    if (TMsgServer(FOwnerComponent).Database = nil) then
      CommandHeader.CommandResult := MSG_Error_FindUsers_DatabaseIsNotAssigned
    else
     begin
      TMsgServer(FOwnerComponent).FindUsers(
                      Users,
                      UserNameComparison,FirstNameComparison,LastNameComparison,
                      OrganizationComparison,DepartmentComparison,
                      ApplicationComparison,HostComparison,PortComparison,
                      Status,UserID,
                      UserName,
                      FirstName,
                      LastName,
                      Organization,
                      Department,
                      Host,
                      Application,
                      SearchCondition,
                      SortBy,
                      Ascending,
                      OrderByClause
                      );
      CommandHeader.CommandResult := MSG_COMMAND_OK;
     end;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
  end;
 SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11519);
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   Len := Length(Users);
   SaveDataToStream(Len,SizeOf(Len),Stream,11544);
   for i := 0 to Len-1 do
    TMsgServer(FOwnerComponent).SaveUserInfoToStream(Users[i],Stream);
  end;
 Buffer := Stream.Buffer;
 SendBuffer(Buffer,Stream.Size);
end; // ExecuteFindUsers


//------------------------------------------------------------------------------
// find users
//------------------------------------------------------------------------------
procedure TMsgServerSession.ExecuteFindMessages(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var
    Buffer:           PAnsiChar;
    MessageTextComparison:         TMsgTextComparison;
    MessageUnicodeTextComparison:  TMsgTextComparison;
    SendingDate:                   TMsgDateComparison;
    DeliveryDate:                  TMsgDateComparison;
    SearchDelivered:               Boolean;
    Delivered:                     Boolean;
    MessageText:                   AnsiString; // text of the message
    MessageUnicodeText:            WideString; // unicode text of the message
    SenderID:                      Cardinal;
    RecipientID:                   Cardinal;
    MessageType:                   TMsgMessageType;
    MessageDataSize:               Integer; // size of MessageData
    OrderBySendingDate:            Boolean;
    // ORDER BY columns without ORDER BY statement
    // example: SenderID DESC, SendingDate ASC
    OrderByClause:                 AnsiString;
    Command:                       Cardinal; // no condition on command field if TMsgMessageType = aamtNone
    ds:                            TDataset;
begin
 ds := nil;
 CommandHeader.CommandResult := MSG_Error_FindMessages_InvalidParams;
 try
    // load
    LoadDataFromStream(MessageTextComparison,SizeOf(MessageTextComparison),Stream,11549);
    LoadDataFromStream(MessageUnicodeText,SizeOf(MessageUnicodeText),Stream,11550);
    LoadDataFromStream(SendingDate,SizeOf(SendingDate),Stream,11551);
    LoadDataFromStream(DeliveryDate,SizeOf(DeliveryDate),Stream,11552);
    LoadBooleanFromStream(SearchDelivered,Stream,11553);
    LoadBooleanFromStream(Delivered,Stream,11554);
    LoadStringFromStream(MessageText,Stream,11555);
    LoadWideStringFromStream(MessageUnicodeText,Stream,11556);
    LoadDataFromStream(SenderID,SizeOf(SenderID),Stream,11557);
    LoadDataFromStream(RecipientID,SizeOf(RecipientID),Stream,11558);
    LoadDataFromStream(MessageType,SizeOf(MessageType),Stream,11559);
    LoadDataFromStream(MessageDataSize,SizeOf(MessageDataSize),Stream,11560);
    LoadBooleanFromStream(OrderBySendingDate,Stream,11561);
    LoadStringFromStream(OrderByClause,Stream,11562);
    LoadDataFromStream(Command,SizeOf(Command),Stream,11563);
    CommandHeader.CommandResult := MSG_COMMAND_OK;
    if (SenderID = MSG_INVALID_USER_ID) and
       (RecipientID = MSG_INVALID_USER_ID) then
     CommandHeader.CommandResult := MSG_Error_FindMessages_SenderOrRecepientMustBeSpecified
    else
     begin
      if (SenderID <> MSG_INVALID_USER_ID) then
       SenderID := FUserID;
      if (RecipientID <> MSG_INVALID_USER_ID) then
       RecipientID := FUserID;
     end;
 except
   on e: EMsgException do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
   on e: Exception do
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
    TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
 end;
 Stream.Size := 0;
 Stream.Position := 0;
 if (TMsgServer(FOwnerComponent).TempTable = nil) then
   CommandHeader.CommandResult :=  MSG_Error_FindMessages_Server_TempTableIsNotAssigned;
 if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
  begin
   try
    CommandHeader.CommandResult := MSG_Error_FindMessages_Failed;
    if (TMsgServer(FOwnerComponent).Database = nil) then
      CommandHeader.CommandResult := MSG_Error_FindMessages_Server_DatabaseIsNotAssigned
    else
     begin
      ds := TMsgServer(FOwnerComponent).FindMessages(
                    MessageTextComparison,MessageUnicodeTextComparison,
                    SendingDate,DeliveryDate,SearchDelivered,Delivered,
                    MessageText,MessageUnicodeText,
                    SenderID,RecipientID,
                    MessageType, MessageDataSize,
                    OrderBySendingDate, OrderByClause, Command
                                 );
      CommandHeader.CommandResult := MSG_COMMAND_OK;
     end;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
  end;
 try
   SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11564);
   if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
    begin
     try
       TMsgServer(FOwnerComponent).FTempTable.SaveDatasetToStream(ds,Stream);
     except
       Stream.Size := 0;
       Stream.Position := 0;
       CommandHeader.CommandResult := MSG_Error_FindMessages_CannotSaveDatasetToStream;
       SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11565);
     end;
    end;
   Buffer := Stream.Buffer;
   SendBuffer(Buffer,Stream.Size);
 finally
   if (ds <> nil) then
    ds.Free;
 end;
end; // ExecuteFindMessages


//------------------------------------------------------------------------------
// receive data from network and move it to ReceivedCommandHeader and ReceivedCommandDataStream
//------------------------------------------------------------------------------
procedure TMsgServerSession.ReceiveData(var Buffer: PAnsiChar; var BufferSize: Integer);
begin
// Execute command
  ExecuteReceivedCommand(Buffer, BufferSize);
end; // ReceiveData


//------------------------------------------------------------------------------
// Send command
//------------------------------------------------------------------------------
function TMsgServerSession.SendCommand(
                                Command: TMsgMessageType;
                                Buffer: PAnsiChar;
                                Size: Integer;
                                FromID: Cardinal = MSG_INVALID_USER_ID
                                        ): Integer;
var
  ms:             TMsgMemoryStream;
  dt:             TDateTime;
  Pos:            Int64;
begin
  if FromID = MSG_INVALID_USER_ID then
    FromID := TMsgServer(FOwnerComponent).FServerID;
  ms := TMsgMemoryStream.Create();
  try
   Result := MSG_Error_SendCommand_SendFailed;
   try
     SaveDataToStream(FromID,SizeOf(FromID),ms,11573);
     SaveDataToStream(Command,SizeOf(Command),ms,11574);
     dt := Now;
     SaveDataToStream(dt,SizeOf(dt),ms,11398);
     Pos := ms.Position;
     SaveDataToStream(Size,SizeOf(Size),ms,11575);
     if (Size > 0) then
       SaveDataToStream(Buffer^,Size,ms,11576);
     SendMessage(ms.Buffer,ms.Size);
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(Result);
     Exit;
   end;
   Result := MSG_Error_SendCommand_SaveHistoryToDatabaseFailed;
   try
    if ((TMsgServer(FOwnerComponent) <> nil) and (Command = MsgCustomCommand)) then
     if (TMsgServer(FOwnerComponent).FDatabase <> nil) and (TMsgServer(FOwnerComponent).StoreMessageHistory) then
      begin
       ms.Position := Pos;
       TMsgServer(FOwnerComponent).SaveMessageToDatabase(TMsgServer(FOwnerComponent).FDatabase,TMsgServer(FOwnerComponent).FServerID,FUserID,Command,dt,True,Now,ms);
     end;
    Result := MSG_COMMAND_OK;
   except
     on e: EMsgException do
      TMsgServer(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgServer(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgServer(FOwnerComponent).DoOnError(Result);
     Exit;
   end;
  finally
   ms.Free;
  end;
end; // SendCommand


//------------------------------------------------------------------------------
// SendEvent
//------------------------------------------------------------------------------
function TMsgServerSession.SendEvent(Event: PMsgEvent): Boolean;
var
  buf:        PAnsiChar;
  ms:         TMsgMemoryStream;
begin
 if TMsgServer(FOwnerComponent).IsUserConnected(UserID) then
  case Event.EventType of
   MsgUserOnLine, MsgUserOffLine:
    begin
     buf := MemoryManager.GetMem(SizeOf(UserID));
     try
      Move(Event.FromUserID,buf^,SizeOf(UserID));
      SendCommand(Event.EventType, buf, SizeOf(Event.FromUserID));
     finally
      MemoryManager.FreeAndNilMem(buf);
     end;
    end; // MsgUserOnLine, MsgUserOffLine
   MsgInitLargeObject:
    begin
     ms := TMsgMemoryStream.Create;
     try
      SaveDataToStream(Event.LargeObject.ObjectID,SizeOf(Event.LargeObject.ObjectID),ms,40129);
      SaveDataToStream(Event.LargeObject.ObjectType,SizeOf(Event.LargeObject.ObjectType),ms,40130);
      if Event.LargeObject.ObjectType = aamtsFile then
        SaveStringToStream(Event.LargeObject.FileName,ms,40131);
      SaveDataToStream(Event.LargeObject.FullSize,SizeOf(Event.LargeObject.FullSize),ms,40132);
      SaveDataToStream(Event.LargeObject.Blocks,SizeOf(Event.LargeObject.Blocks),ms,40133);
      SaveDataToStream(Event.LargeObject.BlockSize,SizeOf(Event.LargeObject.BlockSize),ms,40134);
      buf := ms.Buffer;
      SendCommand(Event.EventType, buf, ms.Size, Event.FromUserID);
     finally
      ms.Free;
     end;
    end; // MsgInitLargeObject
  end; //case
end; // SendEvent


//------------------------------------------------------------------------------
// send buffer via established connection using connection manager
//------------------------------------------------------------------------------
procedure TMsgServerSession.SendBuffer(Buffer: PAnsiChar; BufferSize: Integer; Code: Integer);
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog(#13#10+'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');
aaWriteToLog('S> ServerSession is starting to send a reply...');
aaWriteToLog('S> SessionID = '+IntToStr(SessionID)+', ServerID = '+IntToStr(TMsgServer(FOwnerComponent).ServerID)+#13#10+
             'S> Client UserID = '+IntToStr(Integer(FUserID))+#13#10+
             'S> Client Host = '+ConnectParams.RemoteHost+#13#10+
             'S> Client Port = '+IntToStr(ConnectParams.RemotePort)+#13#10);
if (BufferSize >= SizeOf(TMsgCommandHeader)) then
 begin
  aaWriteToLog('S> CommandCode = '+IntToStr(PMsgCommandHeader(Buffer)^.CommandCode));
  aaWriteToLog('S> CommandResult = '+IntToStr(PMsgCommandHeader(Buffer)^.CommandResult));
  aaWriteToLog('S> NativeError = '+IntToStr(PMsgCommandHeader(Buffer)^.NativeError));
 end;
aaWriteBufferToLog(Buffer,BufferSize);
aaWriteToLog('S> Send Start Time = '+aaGetCurrentTimeAsString);
{$ENDIF}
  TMsgServer(FOwnerComponent).ConnectionManager.SendBuffer(TMsgComBaseSession(Self),Buffer,BufferSize,Code);
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('S> Send End Time = '+aaGetCurrentTimeAsString);
aaWriteToLog('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+#13#10);
{$ENDIF}
end; // SendBuffer


//------------------------------------------------------------------------------
// receive custom message from client
//------------------------------------------------------------------------------
procedure TMsgServerSession.ReceiveMessage(Buffer: PAnsiChar; BufferSize: Integer);
begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
EnterCriticalSection(TMsgServer(FOwnerComponent).FCSect);
inc(TMsgServer(FOwnerComponent).RecvMsgCount);
aaWriteToLog('TMsgServerSession.ReceiveMessage> Count = '+IntToStr(TMsgServer(FOwnerComponent).RecvMsgCount)+', From UserID = '+IntToStr(Self.FUserID));
LeaveCriticalSection(TMsgServer(FOwnerComponent).FCSect);
{$ENDIF}
  if (not Logged)
  or (UserID = MSG_INVALID_USER_ID)
  then
    Exit;
  try
    TMsgServer(FOwnerComponent).ReceiveMessage(Self,Buffer,BufferSize);
  except
  end;
end; // ReceiveMessage


//------------------------------------------------------------------------------
// send custom message
//------------------------------------------------------------------------------
procedure TMsgServerSession.SendMessage(Buffer: PAnsiChar; BufferSize: Integer);
begin
  try
   TMsgServer(FOwnerComponent).ConnectionManager.SendMessage(Self,Buffer,BufferSize);
  except
  end;
end; // SendMessage


//------------------------------------------------------------------------------
// return client info
//------------------------------------------------------------------------------
function TMsgServerSession.GetClientInfo: TMsgClientInfo;
var Host,Application: AnsiString;
    Port:             Integer;
begin
  TMsgServer(FOwnerComponent).ConnectionManager.GetClientInfo(Self,Host,Port,Application);
  Result.UserID := FUserID;
  Result.Host := Host;
  Result.Port := Port;
  Result.Application := Application;
  Result.SessionID := Self.SessionID;
end; // GetClientInfo



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServer
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// do on error
//------------------------------------------------------------------------------
procedure TMsgServer.DoOnError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer = -1;
                       const ErrorMessage: AnsiString = ''
                                 );
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error in server component:');
{$ENDIF}
  inherited DoOnError(ErrorCode,NativeError,ErrorMessage);
end; // DoOnError


//------------------------------------------------------------------------------
// FindSessionWithUser
//------------------------------------------------------------------------------
function TMsgServer.FindSessionWithUser(UserID: Cardinal;
                            CheckLogged: Boolean = True): TMsgServerSession;
var
  Sessions:         TMsgList;
  ServerSession:    PMsgSrvrSession;
  i:                Integer;
begin
  Result := nil;
  Sessions := ConnectionManager.FSessions.LockList;
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
     ServerSession := Sessions.Items[i];
     if ServerSession.Session.UserID = UserID then
      begin
       Result := TMsgServerSession(ServerSession.Session);
       break;
      end;
    end;
  finally
   ConnectionManager.FSessions.UnlockList;
  end;
  if CheckLogged then
    if not IsUserLogged(UserID) then
      Result := nil;
end; // FindSessionWithUser


//------------------------------------------------------------------------------
// FindSessionsWithUser
//------------------------------------------------------------------------------
function TMsgServer.FindSessionsWithUser(UserID: Cardinal): TMsgServerSessionsArray;
var
  Sessions:         TMsgList;
  ServerSession:    PMsgSrvrSession;
  i:                Integer;
begin
  SetLength(Result, 0);
  Sessions := ConnectionManager.FSessions.LockList;
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
     ServerSession := Sessions.Items[i];
     if ServerSession.Session.UserID = UserID then
      begin
       SetLength(Result, Length(Result)+1);
       Result[Length(Result)-1] := ServerSession;
      end;
    end;
  finally
   ConnectionManager.FSessions.UnlockList;
  end;
end; // FindSessionsWithUser


//------------------------------------------------------------------------------
// FindSessionsWithUserInContacts
//------------------------------------------------------------------------------
function TMsgServer.FindSessionsWithUserInContacts(UserID: Cardinal): TMsgServerSessionsArray;
var
  Sessions:         TMsgList;
  ServerSession:    PMsgSrvrSession;
  i,l:              Integer;
begin
  SetLength(Result, 0);
  if FConnectionManager = nil then
    Exit;
  if FConnectionManager.FSessions = nil then
    Exit;
  Sessions := ConnectionManager.FSessions.LockList;
  try
   l := Sessions.Count;
   SetLength(Result,l);
   l := 0;
   for i:=Sessions.Count-1 downto 0 do
    begin
     ServerSession := Sessions.Items[i];
     if (ServerSession.ContactCount > 0) then
      if (ServerSession.Session.UserID <> UserID) then
        begin
         if (IsUserInContacts(UserID,ServerSession.Session.UserID)) then
          begin
           Inc(l);
           Result[l-1] := ServerSession;
          end;
        end; // scanning contacts of found connected user
    end; // for
  finally
   ConnectionManager.FSessions.UnlockList;
   SetLength(Result,l);
  end;
end; // FindSessionsWithUserInContacts


//------------------------------------------------------------------------------
// GetUserContacts
//------------------------------------------------------------------------------
procedure TMsgServer.GetUserContacts(UserID: Cardinal; var Contacts: TMsgContactInfoArray);
var
  fs:             TMsgFileStream;
  FileName:       AnsiString;
  l:              Integer;
  ContactInfo:    TMsgContactInfo;
begin
  if (FDatabase <> nil) then
   FDatabase.GetUserContacts(UserID,Contacts)
  else
   begin
    FileName := DataPath+IntToStr(UserID)+MSG_UCL_EXT;
    if aaFileExists(PAnsiChar(FileName)) then
     begin
      fs := TMsgFileStream.Create(FileName, fmOpenRead + fmShareDenyWrite);
      try
      if fs.Size >= SizeOf(l) then
       begin
        LoadDataFromStream(l,SizeOf(l),fs,40146);
        SetLength(Contacts,l);
        l := 0;
         while fs.Position < fs.Size do
          begin
           LoadBaseContactInfoFromStream(ContactInfo,fs);
           ContactInfo.UserInfo := GetUserInfo(ContactInfo.UserInfo.UserID);
           if (ContactInfo.UserInfo.UserID <> MSG_INVALID_USER_ID) then
            begin
             Contacts[l] := ContactInfo;
             Inc(l);
            end;
          end;
         end
      else // size < 4
       begin
        SetLength(Contacts,0);
       end;
      finally
       fs.Free;
      end;
     end
    else // not aaFileExists
     begin
      SetLength(Contacts,0);
     end;
   end;
end;// GetUserContacts


//------------------------------------------------------------------------------
// returns number of user's contacts
//------------------------------------------------------------------------------
function TMsgServer.GetUserContactCount(UserID: Cardinal): Integer;
var
  FileName:       AnsiString;
  fs:             TMsgFileStream;
begin
 try
  if (FDatabase <> nil) then
   begin
     Result := FDatabase.GetUserContactCount(UserID);
   end
  else
   begin
    Result := 0;
    FileName := DataPath+IntToStr(UserID)+MSG_UCL_EXT;
    if aaFileExists(PAnsiChar(FileName)) then
     begin
      fs := TMsgFileStream.Create(FileName, fmOpenRead + fmShareDenyNone);
      try
        fs.Position := 0;
        LoadDataFromStream(Result,SizeOf(Result),fs,40147);
      finally
        fs.Free;
      end;
     end;
   end;
 except
  Result := 0;
 end;
end; // GetUserContactCount


//------------------------------------------------------------------------------
// return last logon and logoff times
//------------------------------------------------------------------------------
procedure TMsgServer.GetLastLogged(
                              const UserID:     Cardinal;
                              out   LogonTime:  TDateTime;
                              out   LogoffTime: TDateTime
                          );
begin
  if (FDatabase = nil) then
   raise EMsgException.Create(11615,ErrorLDatabaseIsNotAssigned)
  else
   FDatabase.GetLastLogged(UserID,LogonTime,LogoffTime);
end; // GetLastLogged


//------------------------------------------------------------------------------
// return true if UserID is in contact list of OwnerUserID
//------------------------------------------------------------------------------
function TMsgServer.IsUserInContacts(UserID,OwnerUserID: Cardinal): Boolean;
var
  Contacts: TMsgContactInfoArray;
  j:        Integer;
begin
  if (FDatabase <> nil) then
   begin
     Result := FDatabase.IsUserInContacts(UserID,OwnerUserID);
   end
  else
   begin
     Result := False;
     GetUserContacts(OwnerUserID,Contacts);
     try
       if (Length(Contacts) > 0) then
         for j := 0 to High(Contacts) do
          begin
           if (Contacts[j].UserInfo.UserID = UserID) then
            begin
             Result := True;
             break;
            end;
          end;
     finally
       SetLength(Contacts,0);
     end;
   end;
end; // IsUserInContacts


//------------------------------------------------------------------------------
// AddUserContacts
//------------------------------------------------------------------------------
procedure TMsgServer.AddUserToContacts(
                            Session:                  TMsgServerSession;
                            const OwnerUserID:        Cardinal;
                            const ContactUserID:      Cardinal;
                            const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                            const ContactCustomName:  AnsiString = ''
                                       );
var
  fs:           TMsgFileStream;
  FileName:     AnsiString;
  Contacts:     TMsgContactInfoArray;
  i,n:          Integer;
  ContactInfo:  TMsgContactInfo;
begin
  SetLength(Contacts,0);
  try
    GetUserContacts(OwnerUserID,Contacts);
    n := -1;
    for i := Low(Contacts) to High(Contacts) do
     if (Contacts[i].UserInfo.UserID = ContactUserID) then
      begin
       n := i;
       break;
      end;
    if (n < 0) then
     begin
      if (FDatabase <> nil) then // database mode
       begin
        FDatabase.AddUserToContacts(OwnerUserID,ContactUserID,ContactNameSource,ContactCustomName);
        Inc(PMsgSrvrSession(Session.FServerSession)^.ContactCount);
       end
      else
       begin
        FileName := DataPath+IntToStr(OwnerUserID)+MSG_UCL_EXT;
        if not (aaFileExists(PAnsiChar(FileName))) then
         begin
          fs := TMsgFileStream.Create(FileName, fmCreate);
          fs.Position := 0;
         end
        else
         begin
          fs := TMsgFileStream.Create(FileName, fmOpenWrite + fmShareDenyWrite);
          fs.Position := fs.Size;
         end;
         try
         if PMsgSrvrSession(Session.FServerSession)^.ContactCount = 0 then
           if fs.Position = 0 then
             SaveDataToStream(PMsgSrvrSession(Session.FServerSession)^.ContactCount,
                              SizeOf(Integer),fs,40148);
         ContactInfo.UserInfo.UserID := ContactUserID;
         ContactInfo.ContactNameSource := ContactNameSource;
         ContactInfo.ContactCustomName := ContactCustomName;
         SaveBaseContactInfoToStream(ContactInfo,fs);
         // update ContactCount value
         Inc(PMsgSrvrSession(Session.FServerSession)^.ContactCount);
         fs.Position := 0;
         SaveDataToStream(PMsgSrvrSession(Session.FServerSession)^.ContactCount,
                          SizeOf(Integer),fs,40148);
        finally
         fs.Free;
        end;
       end; // files mode
     end;
  finally
    SetLength(Contacts,0);
  end;
end;// AddUserContacts


//------------------------------------------------------------------------------
// update contact info
//------------------------------------------------------------------------------
procedure TMsgServer.UpdateUserInContacts(
                        const OwnerUserID:        Cardinal;
                        const ContactUserID:      Cardinal;
                        const ContactNameSource:  TMsgContactNameSource = mcnsUserName;
                        const ContactCustomName:  AnsiString = ''
                           );
var
  fs:           TMsgFileStream;
  FileName:     AnsiString;
  Contacts:     TMsgContactInfoArray;
  i,n:          Integer;
begin
  if (FDatabase <> nil) then
   FDatabase.UpdateUserInContacts(OwnerUserID,ContactUserID,ContactNameSource,ContactCustomName)
  else
   begin
    SetLength(Contacts,0);
    try
      GetUserContacts(OwnerUserID,Contacts);
      n := -1;
      for i := Low(Contacts) to High(Contacts) do
       if (Contacts[i].UserInfo.UserID = ContactUserID) then
        begin
         n := i;
         break;
        end;
      if (n >= 0) then
       begin
        FileName := DataPath+IntToStr(OwnerUserID)+MSG_UCL_EXT;
        if not (aaFileExists(PAnsiChar(FileName))) then
          fs := TMsgFileStream.Create(FileName, fmCreate)
        else
          fs := TMsgFileStream.Create(FileName, fmOpenWrite + fmShareDenyWrite);
        try
         fs.Size := 0;
         for i := Low(Contacts) to High(Contacts) do
          begin
           if (Contacts[i].UserInfo.UserID = ContactUserID) then
            begin
             Contacts[i].ContactNameSource := ContactNameSource;
             Contacts[i].ContactCustomName := ContactCustomName;
            end;
           SaveBaseContactInfoToStream(Contacts[i],fs);
          end;
        finally
         fs.Free;
        end;
       end;
    finally
      SetLength(Contacts,0);
    end;
   end; // no database
end; // UpdateUserInContacts


//------------------------------------------------------------------------------
// RemoveUserFromContacts
//------------------------------------------------------------------------------
procedure TMsgServer.RemoveUserFromContacts(
                            Session:                  TMsgServerSession;
                            OwnerUserID:              Cardinal;
                            ContactUserID:            Cardinal
                            );
var 
  fs:           TMsgFileStream; 
  FileName:     AnsiString;
  Contacts:     TMsgContactInfoArray; 
  i,n:          Integer; 
begin 
  if (FDatabase <> nil) then 
   FDatabase.RemoveUserFromContacts(OwnerUserID,ContactUserID) 
  else
   begin
    SetLength(Contacts,0); 
    try
      GetUserContacts(OwnerUserID,Contacts); 
      n := -1; 
      for i := Low(Contacts) to High(Contacts) do 
       if (Contacts[i].UserInfo.UserID = ContactUserID) then
        begin
         n := i; 
         break;
        end;
      if (n >= 0) then
       begin 
        for i := n+1 to High(Contacts) do 
         Contacts[i-1] := Contacts[i];
        SetLength(Contacts,Length(Contacts)-1); 
        FileName := DataPath+IntToStr(OwnerUserID)+MSG_UCL_EXT;
        if not (aaFileExists(PAnsiChar(FileName))) then
          fs := TMsgFileStream.Create(FileName, fmCreate) 
        else
          fs := TMsgFileStream.Create(FileName, fmOpenWrite + fmShareDenyWrite);
        try
         fs.Size := 0; 
         i := Length(Contacts);
         SaveDataToStream(i,SizeOf(i),fs,40149);
         for i := Low(Contacts) to High(Contacts) do
           SaveBaseContactInfoToStream(Contacts[i],fs); 
        finally 
         fs.Free;
        end; 
       end; 
    finally 
      SetLength(Contacts,0);
    end;
   end; // no database
  Dec(PMsgSrvrSession(Session.FServerSession)^.ContactCount);
end;// RemoveUserFromContacts 
 
	
//------------------------------------------------------------------------------ 
// LoadUsers
//------------------------------------------------------------------------------ 
procedure TMsgServer.LoadUsers; 
var
  fs:           TMsgFileStream;
  FileName:     AnsiString;
  UserInfo:     PMsgBaseUserInfo; 
begin 
 if (FDatabase = nil) then 
  begin 
    FileName := DataPath+MSG_USERS_FILE; 
    if aaFileExists(PAnsiChar(FileName)) then 
     begin 
      fs := TMsgFileStream.Create(FileName, fmOpenRead + fmShareDenyWrite); 
      try 
       while fs.Position < fs.Size do 
        begin 
         New(UserInfo);
         FillChar(UserInfo^,SizeOf(UserInfo^),$00);
//try
         LoadBaseUserInfoFromStream(UserInfo, fs); 
//except
//end;         
         FUsers.Add(UserInfo); 
        end; 
      finally 
       fs.Free; 
      end; 
     end; 
  end; 
end;// LoadUsers 
 
 
//------------------------------------------------------------------------------
// SaveUsers 
//------------------------------------------------------------------------------
procedure TMsgServer.SaveUsers; 
var 
  fs:           TMsgFileStream;
  FileName:     AnsiString;
  Users:        TMsgList;
  UserInfo:     PMsgBaseUserInfo; 
  i:            Integer;
  FileHandle:   Integer;
begin 
 if (FDatabase = nil) then 
  begin
    FileName := DataPath+MSG_USERS_FILE;
    if not (aaFileExists(PAnsiChar(FileName))) then 
     begin
        FileHandle := FileCreate(FileName); 
        if (FileHandle <> 0) then 
          FileClose(FileHandle);
     end; 
    // Save
    Users := FUsers.LockList;
    try 
     fs := TMsgFileStream.Create(FileName, fmOpenWrite + fmShareDenyWrite); 
     fs.Size := 0;
     try 
      for i := 0 to Users.Count-1 do
       begin 
        UserInfo := Users.Items[i]; 
        if (UserInfo <> nil) then // do not write guests
          SaveBaseUserInfoToStream(UserInfo, fs);
       end;
     finally
      fs.Free;
     end;
    finally
     FUsers.UnlockList; 
    end;
  end; 
end;// SaveUsers
	
	
//------------------------------------------------------------------------------ 
// GetUserInfo
//------------------------------------------------------------------------------ 
function TMsgServer.GetUserInfo(const UserID: Cardinal): TMsgUserInfo;
var
  Users:        TMsgList;
  UserInfo:     PMsgBaseUserInfo;
  i:            Integer;
  Host,App:     AnsiString;
begin
  FillChar(Result,SizeOf(Result),$00);
  Result.UserID := MSG_INVALID_USER_ID;
  if UserID = MSG_INVALID_USER_ID then
    Exit;
  if (FDatabase <> nil) then
   Result := FDatabase.GetUserInfo(UserID)
  else
   begin
    Users := FUsers.LockList;
    try
     for i:=Users.Count-1 downto 0 do
      begin
       UserInfo := Users.Items[i];
       if UserInfo <> nil then
        if UserInfo^.UserInfo.UserID = UserID then
         begin
          Result := UserInfo^.UserInfo;
          break;
         end;
      end;
    finally
      FUsers.UnlockList;
    end;
    if (Result.UserID = UserID) then
     begin
       if IsUserConnected(UserID) then
        begin
         Result.Status := msgOnLine;
         FConnectionManager.GetClientInfo(FindSessionWithUser(UserID,False), Host, Result.Port, App);
         Result.Host := Host;
         Result.Application := App;
        end
       else
        Result.Status := msgOffline;
     end;
   end;
end;// GetUserInfo


//------------------------------------------------------------------------------
// GetNewUserID
//------------------------------------------------------------------------------
function TMsgServer.GetNewUserID: Cardinal;
begin
  EnterCriticalSection(FCSect);
  Result := FGuestID;
  // Search for the next available ID
  repeat
   inc(FGuestID);
   if FGuestID = MSG_MAX_CARDINAL then
     FGuestID := MinUserID;
  until not IsUserExisting(FGuestID);
  LeaveCriticalSection(FCSect);
end;// GetNewUserID


//------------------------------------------------------------------------------
// IsUserLogged
//------------------------------------------------------------------------------
function TMsgServer.IsUserLogged(const UserID: Cardinal): Boolean;
var
  Users:        TMsgList;
  UserInfo:     PMsgBaseUserInfo;
  i:            Integer;
  Sessions:     TMsgSessionsArray;
begin
  Result := False;
  FConnectionManager.GetClientsList(Sessions);
  for i := 0 to Length(Sessions)-1 do
    if (TMsgServerSession(Sessions[i]).UserID = UserID) then
     if TMsgServerSession(Sessions[i]).Connected then
      if TMsgServerSession(Sessions[i]).Logged then
       begin
        Result := True;
        Exit;
       end;
end; // IsUserLogged


//------------------------------------------------------------------------------
// IsUserExisting
//------------------------------------------------------------------------------
function TMsgServer.IsUserExisting(const UserID: Cardinal): Boolean;
var
  Users:        TMsgList;
  UserInfo:     PMsgBaseUserInfo;
  i:            Integer;
begin
  if (UserID = MSG_INVALID_USER_ID) then
   begin
    Result := False;
    Exit;
   end;
  if (FDatabase <> nil) then
   Result := FDatabase.UserExists(UserID)
  else
   begin
    Result := False;
    Users := FUsers.LockList;
    try
     for i := Users.Count-1 downto 0 do
      begin
       UserInfo := Users.Items[i];
       if (UserInfo <> nil) then
        if (UserInfo.UserInfo.UserID = UserID) then
         begin
          Result := True;
          Exit;
         end;
      end;
    finally
     FUsers.UnlockList;
    end;
   end;
end; // IsUserExisting


//------------------------------------------------------------------------------
// InsertUser
//------------------------------------------------------------------------------
procedure TMsgServer.InsertUser(const UserInfo: TMsgUserInfo; Password: AnsiString = '');
begin
  AddUser(UserInfo,Password);
end;// InsertUser


//------------------------------------------------------------------------------
// AddUser
//------------------------------------------------------------------------------
procedure TMsgServer.AddUser(UserInfo: TMsgUserInfo; Password: AnsiString = '');
var
  fs:           TMsgFileStream;
  FileName:     AnsiString;
  Users:        TMsgList;
  lUserInfo:    PMsgBaseUserInfo;
  CryptoHeader: TMsgCryptoHeader;
begin
  CryptoHeader := GetCryptoHeaderForPassword(Password);
  UserInfo.Status := msgOffLine;
  if (FDatabase <> nil) then
   FDatabase.AddUser(UserInfo,CryptoHeader)
  else
   begin
    if (IsUserExisting(UserInfo.UserID)) then
     raise EMsgException.Create(11356,ErrorLUserAlreadyExists,[UserInfo.UserID]);
    New(lUserInfo);
    lUserInfo^.PasswordHeader := CryptoHeader;
    lUserInfo^.UserInfo := UserInfo;
    Users := FUsers.LockList;
    try
      Users.Add(lUserInfo);
      FileName := DataPath+MSG_USERS_FILE;
      if (not (aaFileExists(PAnsiChar(FileName)))) then
       fs := TMsgFileStream.Create(FileName, fmCreate)
      else
       fs := TMsgFileStream.Create(FileName, fmOpenWrite + fmShareExclusive);
      try
       fs.Position := fs.Size;
       SaveBaseUserInfoToStream(lUserInfo, fs);
      finally
       fs.Free;
      end;
    finally
     FUsers.UnlockList;
    end;
   end;
end;// AddUser


//------------------------------------------------------------------------------
// DeleteUser
//------------------------------------------------------------------------------
procedure TMsgServer.DeleteUser(const UserID: Cardinal);
begin
  RemoveUser(UserID);
end;// DeleteUser


//------------------------------------------------------------------------------
// RemoveUser
//------------------------------------------------------------------------------
procedure TMsgServer.RemoveUser(const UserID: Cardinal);
var
  Users:        TMsgList;
  lUserInfo:    PMsgBaseUserInfo;
  i:            Integer;
  Found:        Boolean;
begin
  if (FDatabase <> nil) then
   FDatabase.RemoveUser(UserID)
  else
   begin
    if (not IsUserExisting(UserID)) then
     raise EMsgException.Create(11357,ErrorLUserDoesNotExist,[UserID]);
    Found := False;
    Users := FUsers.LockList;
    try
     for i := Users.Count-1 downto 0 do
      begin
       lUserInfo := Users.Items[i];
       if (lUserInfo <> nil) then
        if (lUserInfo.UserInfo.UserID = UserID) then
         begin
          Dispose(lUserInfo);
          Users.Delete(i);
          Found := True;
          break;
         end;
      end;
    finally
     FUsers.UnlockList;
    end;
    if (Found) then
     begin
      SaveUsers;
      DeleteContacts(UserID);
     end;
   end;
end;// RemoveUser


//------------------------------------------------------------------------------
// DeleteContacts
//------------------------------------------------------------------------------
procedure TMsgServer.DeleteContacts(const UserID: Cardinal);
var
  FileName:     AnsiString;
begin
  if (FDatabase = nil) then
   begin
     FileName := DataPath+IntToStr(UserID)+MSG_UCL_EXT;
     SysUtils.DeleteFile(FileName);
   end;
end; // DeleteContacts


//------------------------------------------------------------------------------
// UpdateUser
//------------------------------------------------------------------------------
procedure TMsgServer.UpdateUser(const UserInfo: TMsgUserInfo; ChangePassword: Boolean; Password: AnsiString = '');
begin
  ChangeUserInfo(UserInfo,ChangePassword,Password);
end;// UpdateUser


//------------------------------------------------------------------------------
// DisconnectUser
//------------------------------------------------------------------------------
procedure TMsgServer.DisconnectUser(const UserID: Cardinal);
var
  Sessions:         TMsgServerSessionsArray;
  i:                Integer;
  Error:            AnsiString;
begin
  Sessions := FindSessionsWithUser(UserID);
  for i:=0 to Length(Sessions)-1 do
   if Sessions[i].Session <> nil then
     if Sessions[i].Session.FUserID = UserID then
      begin
       TMsgServerSession(Sessions[i].Session).DisconnectUser;
       try
        Error := Format(ErrorLServerCannotDisconnectUser,[UserID]);
        Sessions[i].Session.Connected := False;
        FConnectionManager.Disconnect(Sessions[i].Session);
       except
       // ignore invalid buffer
        on e: EMsgException do
         DoOnError(MSG_Error_ServerCannotDisconnectUser,e.NativeError,Error+' '+e.Message);
        else
         DoOnError(MSG_Error_ServerCannotDisconnectUser,-1,Error)
// Cannot disconnect the client with UserID=%d.
// Could be the client application was already abnormally terminated.
       end;
      end;
end; // DisconnectUser


//------------------------------------------------------------------------------
// disconnect client by Host:Port
//------------------------------------------------------------------------------
procedure TMsgServer.Disconnect(const Host: AnsiString; const Port: Integer);
begin
  ConnectionManager.DisconnectClient(Host, Port);
end; // Disconnect

//------------------------------------------------------------------------------
// disconnect client by SessionID
//------------------------------------------------------------------------------
procedure TMsgServer.Disconnect(const SessionID: Integer);
begin
  ConnectionManager.DisconnectClient(SessionID);
end; // Disconnect


//------------------------------------------------------------------------------
// ChangeUserInfo
//------------------------------------------------------------------------------
procedure TMsgServer.ChangeUserInfo(const UserInfo: TMsgUserInfo; ChangePassword: Boolean; Password: AnsiString);
var
  Users:        TMsgList;
  OldUserInfo:  PMsgBaseUserInfo;
  i:            Integer;
  ch:           TMsgCryptoHeader;
begin
  if (ChangePassword) then
    ch := GetCryptoHeaderForPassword(Password);
  if (FDatabase <> nil) then
   FDatabase.ChangeUserInfo(UserInfo,ChangePassword,ch)
  else
   begin
    if (not IsUserExisting(UserInfo.UserID)) then
     raise EMsgException.Create(11358,ErrorLUserDoesNotExist,[UserInfo.UserID]);
    Users := FUsers.LockList;
    try
     OldUserInfo := nil;
     for i := 0 to Users.Count-1 do
      if (PMsgBaseUserInfo(Users.Items[i])^.UserInfo.UserID = UserInfo.UserID) then
       begin
        OldUserInfo := Users.Items[i];
        break;
       end;
     if (OldUserInfo = nil) then
      raise EMsgException.Create(11344,ErrorLUserDoesNotExist,[UserInfo.UserID]);
     if (ChangePassword) then
      begin
       OldUserInfo^.UserInfo := UserInfo;
       OldUserInfo^.PasswordHeader := ch;
      end
     else
      begin
       OldUserInfo^.UserInfo := UserInfo;
      end;
    finally
     FUsers.UnlockList;
    end;
    SaveUsers;
   end;
  if (Assigned(FOnUserInfoChanged)) then
    OnUserInfoChanged(UserInfo.UserID);
end;// ChangeUserInfo


//------------------------------------------------------------------------------
// Get user info
//------------------------------------------------------------------------------
function TMsgServer.GetPasswordHeader(const UserID: Cardinal): TMsgCryptoHeader;
var
  Users:        TMsgList;
  UserInfo:     PMsgBaseUserInfo;
  i:            Integer;
begin
  FillChar(Result,SizeOf(Result),$00);
  if (FDatabase <> nil) then
   Result := FDatabase.GetPasswordHeader(UserID)
  else
   begin
    Users := FUsers.LockList;
    try
     for i:=Users.Count-1 downto 0 do
      begin
       UserInfo := Users.Items[i];
       if UserInfo <> nil then
        if UserInfo^.UserInfo.UserID = UserID then
         begin
          Result := UserInfo^.PasswordHeader;
          break;
         end;
      end;
    finally
     FUsers.UnlockList;
    end;
   end;
end; // GetPasswordHeader


//------------------------------------------------------------------------------
// Return true if password is OK
//------------------------------------------------------------------------------
function TMsgServer.IsPasswordValid(const UserID: Cardinal; const Password: AnsiString): Boolean;
var
    ci:       TMsgCryptoInfo;
    CryptoHeader: TMsgCryptoHeader;
begin
  if UserID = MSG_INVALID_USER_ID then
   begin
    Result := True;
    Exit;
   end;
  Result := False;
  try
    CryptoHeader := GetPasswordHeader(UserID);
  except
    Exit;
  end;
  ci.Password := Password;
  ci.UseInitVector := False;
  ci.CryptoAlgorithm := CryptoHeader.CryptoAlgorithm;
  ci.CryptoMode := CryptoHeader.CryptoMode;
  if (ci.CryptoAlgorithm = Msg_Cipher_None) then
   Result := True
  else
   Result := MsgIsKeyValid(CryptoHeader,ci);
end; // IsPasswordValid


//------------------------------------------------------------------------------
// start server
//------------------------------------------------------------------------------
procedure TMsgServer.StartServer;
var
  Users:        TMsgList;
  UserInfo:     PMsgBaseUserInfo;
  i:            Integer;
begin
  if (not FActive) then
   begin
    if (Assigned(FBeforeServerStart)) then
     FBeforeServerStart(Self);
    if (FDatabase <> nil) then
     begin
       Database.OpenOrCreateDatabase(False);
       Database.ChangeUserStatus(True,MSG_INVALID_USER_ID,msgOffLine);
     end
    else
     SetPath(FDataPath);
    LoadServerSettings;
    FGuestID := MinUserID;
    if (FDatabase = nil) then
     begin
      if not DirectoryExists(FDataPath) then
         ForceDirectories(FDataPath);
    LoadUsers;
    // set first ID for newcomers
    Users := FUsers.LockList;
    try
     for i:=0 to Users.Count-1 do
      begin
       UserInfo := Users.Items[i];
       if UserInfo <> nil then
       if UserInfo.UserInfo.UserID >= FGuestID then
         FGuestID := UserInfo.UserInfo.UserID + 1;
      end;
    finally
     FUsers.UnlockList;
    end;
     end;
    if FConnectionManager = nil then
      FConnectionManager := TMsgServerConnectionManager.Create(Self);
    FActive := True;
    if (Assigned(FAfterServerStart)) then
     FAfterServerStart(Self);
   end;
end; // StartServer


//------------------------------------------------------------------------------
// stop server
//------------------------------------------------------------------------------
procedure TMsgServer.StopServer;
begin
  if (FActive) then
   begin
    if (Assigned(FBeforeServerStop)) then
     FBeforeServerStop(Self);
    FActive := False;
    if (FConnectionManager <> nil) then
      FConnectionManager.Free; // calls DisconnectAll to save received messages
    FConnectionManager := nil;
    DeleteUsers;
    if (FDatabase <> nil) then
     FDatabase.CloseDatabase;
    FConnectedUsers.Lock;
    FConnectedUsers.SetSize(0);
    FConnectedUsers.Unlock;
    if (Assigned(FAfterServerStop)) then
     FAfterServerStop(Self);
   end;
end; // StopServer;


//------------------------------------------------------------------------------
// load default settings;
//------------------------------------------------------------------------------
procedure TMsgServer.LoadDefaultSettings;
begin
  if UseConfigFile then
   if (not aaFileExists(PAnsiChar(FConfigFileName))) then
    SaveSettingsToConfigFile;
end; // LoadDefaultSettings


//------------------------------------------------------------------------------
// load server settings from config file
//------------------------------------------------------------------------------
procedure TMsgServer.LoadSettingsFromConfigFile;
const NetworkCaption = 'Server Network Settings';
var IniFile:      TIniFile;
    FileName:     AnsiString;
    CryptoParams: TMsgCryptoParams;
    i:            Integer;
begin
  // ini file cannot be created without full path
  if (ExtractFilePath(FConfigFileName) <> '') then
   FileName := FConfigFileName
  else
   FileName := ExtractFilePath(ParamStr(0))+ FConfigFileName;
  IniFile := TIniFile.Create(FileName);
  try
 // connection params
    ConnectionParams.LocalHost := IniFile.ReadString('Server Connection Parameters','LocalHost',ConnectionParams.LocalHost);
    ConnectionParams.LocalPort := IniFile.ReadInteger('Server Connection Parameters','LocalPort',ConnectionParams.LocalPort);
    FServerID := IniFile.ReadInteger('Server Connection Parameters','ServerID',FServerID);
    // crypto parameters
    CryptoParams := FCryptoParamsEditor.GetCryptoParams;
    CryptoParams.CryptoAlgorithm := IniFile.ReadInteger('Server Crypto Parameters','CryptoAlgorithm',CryptoParams.CryptoAlgorithm);
    CryptoParams.CryptoMode := IniFile.ReadInteger('Server Crypto Parameters','CryptoMode',CryptoParams.CryptoMode);
    CryptoParams.Password := IniFile.ReadString('Server Crypto Parameters','Password',CryptoParams.Password);
    CryptoParams.UseInitVector := IniFile.ReadBool('Server Crypto Parameters','UseInitVector',CryptoParams.UseInitVector);
    if (CryptoParams.UseInitVector) then
      for i := 0 to High(CryptoParams.InitVector) do
       CryptoParams.InitVector[i] := IniFile.ReadInteger('Server Crypto Parameters','InitVector'+IntToStr(i),CryptoParams.InitVector[i]);
    if ((CryptoParams.Password = '') and (CryptoParams.CryptoAlgorithm <> msg_Cipher_None)) then
     begin
       CryptoParams.KeyInfo.KeySize := IniFile.ReadInteger('Server Crypto Parameters','KeySize',CryptoParams.KeyInfo.KeySize);
       for i := 0 to CryptoParams.KeyInfo.KeySize do
        CryptoParams.KeyInfo.Key[i] := IniFile.ReadInteger('Server Crypto Parameters','Key'+IntToStr(i),CryptoParams.KeyInfo.Key[i]);
     end;
    FCryptoParamsEditor.SetCryptoParams(CryptoParams);
    // network settings
    ConnectionParams.FNetworkSettings.PacketSize := IniFile.ReadInteger(NetworkCaption,'PacketSize',ConnectionParams.FNetworkSettings.PacketSize);
    ConnectionParams.FNetworkSettings.MaxThreadCount := IniFile.ReadInteger(NetworkCaption,'MaxThreadCount',ConnectionParams.FNetworkSettings.MaxThreadCount);
    ConnectionParams.FNetworkSettings.ConnectionParamsTunning := IniFile.ReadBool(NetworkCaption,'ConnectionParamsTunning',ConnectionParams.FNetworkSettings.ConnectionParamsTunning);
    ConnectionParams.FNetworkSettings.TestPacketCount := IniFile.ReadInteger(NetworkCaption,'TestPacketCount',ConnectionParams.FNetworkSettings.TestPacketCount);
    ConnectionParams.FNetworkSettings.MinServerSendTimeOut := IniFile.ReadInteger(NetworkCaption,'MinSendTimeOut',ConnectionParams.FNetworkSettings.MinServerSendTimeOut);
    ConnectionParams.FNetworkSettings.DisconnectRetryCount := IniFile.ReadInteger(NetworkCaption,'DisconnectRetryCount',ConnectionParams.FNetworkSettings.DisconnectRetryCount);
    ConnectionParams.FNetworkSettings.DisconnectDelay := IniFile.ReadInteger(NetworkCaption,'DisconnectDelay',ConnectionParams.FNetworkSettings.DisconnectDelay);
    ConnectionParams.FNetworkSettings.ServerReceiveTimeOut := IniFile.ReadInteger(NetworkCaption,'ServerReceiveTimeOut',ConnectionParams.FNetworkSettings.ServerReceiveTimeOut);
    ConnectionParams.FNetworkSettings.ServerReceiveSleep := IniFile.ReadInteger(NetworkCaption,'ServerReceiveSleep',ConnectionParams.FNetworkSettings.ServerReceiveSleep);
    ConnectionParams.FNetworkSettings.MinServerSendTimeOut := IniFile.ReadInteger(NetworkCaption,'MinServerSendTimeOut',ConnectionParams.FNetworkSettings.MinServerSendTimeOut);
    ConnectionParams.FNetworkSettings.ServerSendTimeOut := IniFile.ReadInteger(NetworkCaption,'ServerSendTimeOut',ConnectionParams.FNetworkSettings.ServerSendTimeOut);
    ConnectionParams.FNetworkSettings.ServerResendDelay := IniFile.ReadInteger(NetworkCaption,'ServerResendDelay',ConnectionParams.FNetworkSettings.ServerResendDelay);
    ConnectionParams.FNetworkSettings.ServerRequestDelay := IniFile.ReadInteger(NetworkCaption,'ServerRequestDelay',ConnectionParams.FNetworkSettings.ServerRequestDelay);
    ConnectionParams.FNetworkSettings.WaitForMessagesSend := IniFile.ReadInteger(NetworkCaption,'WaitForMessagesSend',ConnectionParams.FNetworkSettings.WaitForMessagesSend);
    ConnectionParams.FNetworkSettings.ServerThreadsTerminateDelay := IniFile.ReadInteger(NetworkCaption,'ServerThreadsTerminateDelay',ConnectionParams.FNetworkSettings.ServerThreadsTerminateDelay);
    ConnectionParams.FNetworkSettings.ServerSessionTerminatorSleep := IniFile.ReadInteger(NetworkCaption,'ServerSessionTerminatorSleep',ConnectionParams.FNetworkSettings.ServerSessionTerminatorSleep);
    ConnectionParams.FNetworkSettings.WaitForPingAnswer := IniFile.ReadInteger(NetworkCaption,'WaitForPingAnswer',ConnectionParams.FNetworkSettings.WaitForPingAnswer);
    ConnectionParams.FNetworkSettings.ServerPingSleep := IniFile.ReadInteger(NetworkCaption,'ServerPingSleep',ConnectionParams.FNetworkSettings.ServerPingSleep);
  finally
    IniFile.Free;
  end;
end; // LoadSettingsFromConfigFile


//------------------------------------------------------------------------------
// SaveSettingsToConfigFile
//------------------------------------------------------------------------------
procedure TMsgServer.SaveSettingsToConfigFile;
const NetworkCaption = 'Server Network Settings';
var IniFile:      TIniFile;
    i:            Integer;
    FileName:     AnsiString;
    CryptoParams: TMsgCryptoParams;
begin
  if (not UseConfigFile) then
   Exit;
  // ini file cannot be created without full path
  if (ExtractFilePath(FConfigFileName) <> '') then
   FileName := FConfigFileName
  else
   FileName := ExtractFilePath(ParamStr(0))+ FConfigFileName;
  if (aaFileExists(PAnsiChar(FileName))) then
   SysUtils.DeleteFile(FileName);
  IniFile := TIniFile.Create(FileName);
  try
 // connection params
    IniFile.WriteString('Server Connection Parameters','LocalHost',ConnectionParams.LocalHost);
    IniFile.WriteInteger('Server Connection Parameters','LocalPort',ConnectionParams.LocalPort);
    IniFile.WriteInteger('Server Connection Parameters','ServerID',ServerID);
    // crypto parameters
    CryptoParams := FCryptoParamsEditor.GetCryptoParams;
    IniFile.WriteInteger('Server Crypto Parameters','CryptoAlgorithm',CryptoParams.CryptoAlgorithm);
    IniFile.WriteInteger('Server Crypto Parameters','CryptoMode',CryptoParams.CryptoMode);
    IniFile.WriteString('Server Crypto Parameters','Password',CryptoParams.Password);
    IniFile.WriteBool('Server Crypto Parameters','UseInitVector',CryptoParams.UseInitVector);
    if (CryptoParams.UseInitVector) then
      for i := 0 to High(CryptoParams.InitVector) do
       IniFile.WriteInteger('Server Crypto Parameters','InitVector'+IntToStr(i),CryptoParams.InitVector[i]);
    if ((CryptoParams.Password = '') and (CryptoParams.CryptoAlgorithm <> msg_Cipher_None)) then
     begin
       IniFile.WriteInteger('Server Crypto Parameters','KeySize',CryptoParams.KeyInfo.KeySize);
       for i := 0 to CryptoParams.KeyInfo.KeySize do
        IniFile.WriteInteger('Server Crypto Parameters','Key'+IntToStr(i),CryptoParams.KeyInfo.Key[i]);
     end;
    // network settings
    IniFile.WriteInteger(NetworkCaption,'PacketSize',ConnectionParams.FNetworkSettings.PacketSize);
    IniFile.WriteInteger(NetworkCaption,'MaxThreadCount',ConnectionParams.FNetworkSettings.MaxThreadCount);
    IniFile.WriteBool(NetworkCaption,'ConnectionParamsTunning',ConnectionParams.FNetworkSettings.ConnectionParamsTunning);
    IniFile.WriteInteger(NetworkCaption,'TestPacketCount',ConnectionParams.FNetworkSettings.TestPacketCount);
    IniFile.WriteInteger(NetworkCaption,'MinSendTimeOut',ConnectionParams.FNetworkSettings.MinServerSendTimeOut);
    IniFile.WriteInteger(NetworkCaption,'DisconnectRetryCount',ConnectionParams.FNetworkSettings.DisconnectRetryCount);
    IniFile.WriteInteger(NetworkCaption,'DisconnectDelay',ConnectionParams.FNetworkSettings.DisconnectDelay);
    IniFile.WriteInteger(NetworkCaption,'ServerReceiveTimeOut',ConnectionParams.FNetworkSettings.ServerReceiveTimeOut);
    IniFile.WriteInteger(NetworkCaption,'ServerReceiveSleep',ConnectionParams.FNetworkSettings.ServerReceiveSleep);
    IniFile.WriteInteger(NetworkCaption,'MinServerSendTimeOut',ConnectionParams.FNetworkSettings.MinServerSendTimeOut);
    IniFile.WriteInteger(NetworkCaption,'ServerSendTimeOut',ConnectionParams.FNetworkSettings.ServerSendTimeOut);
    IniFile.WriteInteger(NetworkCaption,'ServerResendDelay',ConnectionParams.FNetworkSettings.ServerResendDelay);
    IniFile.WriteInteger(NetworkCaption,'ServerRequestDelay',ConnectionParams.FNetworkSettings.ServerRequestDelay);
    IniFile.WriteInteger(NetworkCaption,'WaitForMessagesSend',ConnectionParams.FNetworkSettings.WaitForMessagesSend);
    IniFile.WriteInteger(NetworkCaption,'ServerThreadsTerminateDelay',ConnectionParams.FNetworkSettings.ServerThreadsTerminateDelay);
    IniFile.WriteInteger(NetworkCaption,'ServerSessionTerminatorSleep',ConnectionParams.FNetworkSettings.ServerSessionTerminatorSleep);
    IniFile.WriteInteger(NetworkCaption,'WaitForPingAnswer',ConnectionParams.FNetworkSettings.WaitForPingAnswer);
    IniFile.WriteInteger(NetworkCaption,'ServerPingSleep',ConnectionParams.FNetworkSettings.ServerPingSleep);
    IniFile.UpdateFile;
    // connection params
    IniFile.WriteString('Server Connection Parameters','LocalHost',LocalHost);
    IniFile.WriteInteger('Server Connection Parameters','LocalPort',LocalPort);
    IniFile.WriteInteger('Server Connection Parameters','ServerID',ServerID);
    // crypto parameters
    CryptoParams := FCryptoParamsEditor.GetCryptoParams;
    IniFile.WriteInteger('Server Crypto Parameters','CryptoAlgorithm',CryptoParams.CryptoAlgorithm);
    IniFile.WriteInteger('Server Crypto Parameters','CryptoMode',CryptoParams.CryptoMode);
    IniFile.WriteString('Server Crypto Parameters','Password',CryptoParams.Password);
    IniFile.WriteBool('Server Crypto Parameters','UseInitVector',CryptoParams.UseInitVector);
    if (CryptoParams.UseInitVector) then
      for i := 0 to High(CryptoParams.InitVector) do
       IniFile.WriteInteger('Server Crypto Parameters','InitVector'+IntToStr(i),CryptoParams.InitVector[i]);
    if ((CryptoParams.Password = '') and (CryptoParams.CryptoAlgorithm <> msg_Cipher_None)) then
     begin
       IniFile.WriteInteger('Server Crypto Parameters','KeySize',CryptoParams.KeyInfo.KeySize);
       for i := 0 to CryptoParams.KeyInfo.KeySize do
        IniFile.WriteInteger('Server Crypto Parameters','Key'+IntToStr(i),CryptoParams.KeyInfo.Key[i]);
     end;
    // network settings
    IniFile.WriteInteger(NetworkCaption,'PacketSize',ConnectionParams.FNetworkSettings.PacketSize);
    IniFile.WriteInteger(NetworkCaption,'MaxThreadCount',ConnectionParams.FNetworkSettings.MaxThreadCount);
    IniFile.WriteBool(NetworkCaption,'ConnectionParamsTunning',ConnectionParams.FNetworkSettings.ConnectionParamsTunning);
    IniFile.WriteInteger(NetworkCaption,'TestPacketCount',ConnectionParams.FNetworkSettings.TestPacketCount);
    IniFile.WriteInteger(NetworkCaption,'MinSendTimeOut',ConnectionParams.FNetworkSettings.MinServerSendTimeOut);
    IniFile.WriteInteger(NetworkCaption,'DisconnectRetryCount',ConnectionParams.FNetworkSettings.DisconnectRetryCount);
    IniFile.WriteInteger(NetworkCaption,'DisconnectDelay',ConnectionParams.FNetworkSettings.DisconnectDelay);
    IniFile.WriteInteger(NetworkCaption,'ServerReceiveTimeOut',ConnectionParams.FNetworkSettings.ServerReceiveTimeOut);
    IniFile.WriteInteger(NetworkCaption,'ServerReceiveSleep',ConnectionParams.FNetworkSettings.ServerReceiveSleep);
    IniFile.WriteInteger(NetworkCaption,'MinServerSendTimeOut',ConnectionParams.FNetworkSettings.MinServerSendTimeOut);
    IniFile.WriteInteger(NetworkCaption,'ServerSendTimeOut',ConnectionParams.FNetworkSettings.ServerSendTimeOut);
    IniFile.WriteInteger(NetworkCaption,'ServerResendDelay',ConnectionParams.FNetworkSettings.ServerResendDelay);
    IniFile.WriteInteger(NetworkCaption,'ServerRequestDelay',ConnectionParams.FNetworkSettings.ServerRequestDelay);
    IniFile.WriteInteger(NetworkCaption,'WaitForMessagesSend',ConnectionParams.FNetworkSettings.WaitForMessagesSend);
    IniFile.WriteInteger(NetworkCaption,'ServerThreadsTerminateDelay',ConnectionParams.FNetworkSettings.ServerThreadsTerminateDelay);
    IniFile.WriteInteger(NetworkCaption,'ServerSessionTerminatorSleep',ConnectionParams.FNetworkSettings.ServerSessionTerminatorSleep);
    IniFile.WriteInteger(NetworkCaption,'WaitForPingAnswer',ConnectionParams.FNetworkSettings.WaitForPingAnswer);
    IniFile.WriteInteger(NetworkCaption,'ServerPingSleep',ConnectionParams.FNetworkSettings.ServerPingSleep);
    IniFile.UpdateFile;
  finally
    IniFile.Free;
  end;
end; // SaveSettingsToConfigFile


//------------------------------------------------------------------------------
// DoOnConnectionError
//------------------------------------------------------------------------------
procedure TMsgServer.DoOnConnectionError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer;
                       const ErrorMessage: AnsiString
                       );
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error in MsgConnection module. Session is not existing.');
aaWriteToLog('------------------------------------------------------------------');
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
aaWriteToLog('NativeError='+IntToStr(Integer(NativeError)));
aaWriteToLog('ErrorMessage:"'+ErrorMessage+'"');
aaWriteToLog('GetTickCount = '+IntToStr(aaGetTickCount));
aaWriteToLog('==================================================================');
{$ENDIF}
  DoOnError(ErrorCode,NativeError,ErrorMessage);
end; // DoOnConnectionError


//------------------------------------------------------------------------------
// load server settings from ini file or set them to default
//------------------------------------------------------------------------------
procedure TMsgServer.LoadServerSettings;
begin
  if (not aaFileExists(PAnsiChar(FConfigFileName))) then
   LoadDefaultSettings
  else
    if UseConfigFile then
     LoadSettingsFromConfigFile;
end; // LoadServerSettings


//------------------------------------------------------------------------------
// return current version
//------------------------------------------------------------------------------
function TMsgServer.GetCurrentVersion: AnsiString;
var c : Char;
begin
{$IFDEF D17H}
 c := FormatSettings.DecimalSeparator;
 try
   FormatSettings.DecimalSeparator := '.';
   Result := FloatToStrF(MsgVersion,ffFixed,3,2) + ' ' + MsgVersionText;
 finally
   FormatSettings.DecimalSeparator := c;
 end;
{$ELSE}
 c := DecimalSeparator;
 try
   DecimalSeparator := '.';
   Result := FloatToStrF(MsgVersion,ffFixed,3,2) + ' ' + MsgVersionText;
 finally
   DecimalSeparator := c;
 end;
{$ENDIF}
end; // GetCurrentVersion


//------------------------------------------------------------------------------
// active
//------------------------------------------------------------------------------
procedure TMsgServer.SetActive(Value: Boolean);
begin
 if (Value <> FActive) then
  begin
   if (Value) then
    StartServer
   else
    StopServer;
  end;
end; // SetActive


//------------------------------------------------------------------------------
// get client session
//------------------------------------------------------------------------------
function TMsgServer.GetSession(const Client: TMsgClientInfo): TMsgServerSession;
var ClientSessions: TMsgSessionsArray;
    i:              Integer;
begin
  Result := nil;
  FConnectionManager.GetClientsList(ClientSessions);
  if (Length(ClientSessions) > 0) then
   for i := Low(ClientSessions) to High(ClientSessions) do
    begin
     if ClientSessions[i].SessionID = Client.SessionID then
      begin
       Result := TMsgServerSession(ClientSessions[i]);
       break;
      end;
    end;
  ClientSessions := nil;
end; // GetSession


//------------------------------------------------------------------------------
// Send all the messages stored while the user was off-line
//------------------------------------------------------------------------------
procedure TMsgServer.SendStoredMessagesFromDatabase(Session: TMsgServerSession);
var ds:          TDataset;
    dateComp:    TMsgDateComparison;
    textComp:    TMsgTextComparison;
    MessageID:   Integer;
    ms:          TMsgMemoryStream;
    MessageType: TMsgMessageType;
begin
  dateComp.Comparison1 := mcmpopNone;
  dateComp.Comparison2 := mcmpopNone;
  try
    ds := FDatabase.FindMessages(textComp,textComp,
                               dateComp,dateComp,True,False,
                               '','',MSG_INVALID_USER_ID,Session.FUserID,
                               aamtNone,-1,True);
    if (ds = nil) then
     raise EMsgException.Create(11614,ErrorLInvalidPointer);
  except
   //
   on e: EMsgException do
    DoOnError(60073,e.NativeError,e.Message);
   on e: Exception do
    DoOnError(60073,-1,e.Message)
   else
    DoOnError(60073);
   Exit;
  end;
  try
    ds.First;
    while not ds.Eof do
     begin
      MessageID := FDatabase.GetMessageID(ds);
      MessageType := FDatabase.GetMessageType(ds);
      ms := TMsgMemoryStream.Create;
      try
        FDatabase.PrepareMessageForSending(ds,ms);
        try
         Session.SendMessage(ms.Buffer,ms.Size);
         if (FStoreMessageHistory) then
          begin
           if ((MessageType = aamtsFile) or (MessageType = aamtsStream)) then
            // delete stored file / stream parts
            FDatabase.DeleteMessage(MessageID)
           else
            FDatabase.SetMessageDeliveryDate(MessageID)
          end
         else
          FDatabase.DeleteMessage(MessageID);
        except
        end;
      finally
        ms.Free;
      end;
      ds.Next;
     end;
  finally
    ds.Free;
  end;
end; // SendStoredMessagesFromDatabase


//------------------------------------------------------------------------------
// Send all the messages stored while the user was off-line
//------------------------------------------------------------------------------
procedure TMsgServer.SendStoredMessages(Session: TMsgServerSession);
var
  len:             Integer;
  ms:              TMsgMemoryStream;
  fs, fs2:         TMsgFileStream;
  FileName,
  UserFileName:    AnsiString;
  AllSent,
  bOK:             Boolean;
begin
  if (FDatabase <> nil) then
   SendStoredMessagesFromDatabase(Session)
  else
   begin
    // Send then delete all the messages stored for this user
    UserFileName := GetUserFileName(Session.FUserID);
    if (aaFileExists(PAnsiChar(UserFileName))) then
     begin
      try
       fs := TMsgFileStream.Create(UserFileName, fmOpenRead + fmShareDenyWrite, 10000);
       AllSent := True;
      except
       AllSent := False;
      end;
      if (AllSent) then
       begin
         try
          while fs.Position < fs.Size do
           begin
            LoadDataFromStream(len,SizeOf(len), fs, 10262);
            SetLength(FileName,len);
            if (len > 0) then
             begin // send message
              LoadDataFromStream(PAnsiChar(@FileName[1])^, len, fs, 40066);
              if (aaFileExists(PAnsiChar(FileName))) then
               begin
                try
                 fs2 := TMsgFileStream.Create(FileName, fmOpenRead + fmShareDenyWrite);
                 bOK := True;
                except
                 bOK := False;
                end;
                if (bOK) then
                 begin
                  try
                    ms := TMsgMemoryStream.Create();
                    try
                     fs2.SaveToStream(ms);
                     try
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgServer.SendStoredMessages> FileName = '+FileName);
{$ENDIF}
                      ConnectionManager.SendMessage(Session, ms.Buffer, ms.Size);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgServer.SendStoredMessages> OK!');
{$ENDIF}
                      sleep(16); // to allow send event
                     except
                      on E: Exception do
                       begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgServer.SendStoredMessages> Not sent!');
{$ENDIF}
                        bOK := False;
                        AllSent := False;
                       end;
                     end;
                    finally
                     ms.Free;
                    end; // try
                  finally
                   fs2.Free;
                  end; // try
                  if (bOK) then
                   begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgServer.SendStoredMessages> Delete FileName = '+FileName);
{$ENDIF}
                    SysUtils.DeleteFile(FileName);
                   end;
                 end // file opened
                else
                 break;
              end;
            end; // send message
           end; // EOF of messages
         finally
          fs.Free;
         end;
        if (AllSent) then
         begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgServer.SendStoredMessages> Delete UserFileName = '+UserFileName);
{$ENDIF}
          SysUtils.DeleteFile(UserFileName);
         end;
       end; // file opened
     end; // aaFileExists
   end; // no database
end; // SendStoredMessages


//------------------------------------------------------------------------------
// receive message sent to server (command or message)
//------------------------------------------------------------------------------
procedure TMsgServer.ReceiveMessageToServer(
                                        MessageType:    TMsgMessageType;
                                        SendingDate:    TDateTime;
                                        ServerSession:  TMsgServerSession;
                                        Stream:         TMsgMemoryStream
                                          );
var
  ms1:          TMsgMemoryStream;
  Text:         AnsiString;
  UnicodeText:  WideString;
  len:          Integer;
  Buf:          PAnsiChar;
  StreamSize:   Int64;
  Command,
  FromUserID,
  ToUserID:     Cardinal;
  ToSession:    TMsgServerSession;
  fs:           TMsgFileStream;
  FileName,
  UserFileName: AnsiString;
  DeliveryDate: TDateTime;
  RecvObject:   PMsgRecvObject;
  BlockNo:      Integer;
  ObjectID:     Cardinal;
  found:        Boolean;
begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgServer.ReceiveMessageToServer> START');
{$ENDIF}
  DeliveryDate := Now;
  try
    if (FDatabase <> nil) and (FStoreMessageHistory) then
     SaveMessageToDatabase(FDatabase,ServerSession.FUserID,FServerID,MessageType,
                           SendingDate,
                           True,DeliveryDate,Stream);
  except
  end;
  case MessageType of
    aamtText:
     if (Assigned(FOnReceiveTextMessage)) then
      begin
        LoadStringFromStream(Text,Stream,10262);
        FOnReceiveTextMessage(ServerSession.UserID,SendingDate,DeliveryDate,Text);
      end;
    aamtUnicodeText:
     if (Assigned(FOnReceiveTextMessage)) then
      begin
        LoadWideStringFromStream(UnicodeText,Stream,11630);
        FOnReceiveUnicodeTextMessage(ServerSession.UserID,SendingDate,DeliveryDate,UnicodeText);
      end;
    aamtBinary:
     if (Assigned(FOnReceiveBinaryMessage)) then
      begin
        LoadDataFromStream(len,SizeOf(len),Stream,10264);
        if (len > 0) then
         begin
          Buf := MemoryManager.GetMem(len);
          try
            LoadDataFromStream(Buf^,len,Stream,10265);
            FOnReceiveBinaryMessage(ServerSession.UserID,SendingDate,DeliveryDate,Buf,len);
          finally
            MemoryManager.FreeAndNilMem(Buf);
          end;
         end
        else
         FOnReceiveBinaryMessage(ServerSession.UserID,SendingDate,DeliveryDate,nil,len);
      end;
    aamtStream:
     if (Assigned(FOnReceiveStreamMessage)) then
      begin
       ms1 := TMsgMemoryStream.Create;
       try
         LoadDataFromStream(StreamSize,SizeOf(StreamSize),Stream,10266);
         if (StreamSize > 0) then
          ms1.LoadFromStreamWithPosition(Stream,Stream.Position,StreamSize);
         FOnReceiveStreamMessage(ServerSession.UserID,SendingDate,DeliveryDate,ms1);
       finally
        ms1.Free;
       end;
      end;
     aamtsFile:
      begin
        RecvFileMsg(Stream,RecvObject,len,BlockNo,ObjectID,SendingDate);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> call event...');
aaWriteToLog('RecvObject = '+IntToStr(Integer(RecvObject)));
{$ENDIF}
       if (Assigned(FOnReceiveFile)) then //call event
        try
         if (RecvObject <> nil) then
         if (RecvObject.ObjectID > 0)
         then
           FOnReceiveFile(ServerSession.UserID,RecvObject.ObjectID,RecvObject.SendingDate,DeliveryDate,RecvObject.FileName,RecvObject.FullSize,RecvObject.BlockSize,BlockNo,RecvObject.Blocks,true)
         else
           FOnReceiveFile(ServerSession.UserID,ObjectID,SendingDate,DeliveryDate,'',-1,len,BlockNo,-1,true);
        except
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('ERROR: OnReceiveFile event handler exception');
{$ENDIF}
        end;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> event processed');
{$ENDIF}
      end; // aamtsFile
   else // Case - Command received
    begin
      if (MessageType > MsgHighestType)
      or (MessageType < MsgLowestType) then
        raise EMsgException.Create(40056, ErrorRUnknownMessageType);
      LoadDataFromStream(len,SizeOf(len),Stream,10270);
      if (len > 0) then
       begin
        case MessageType of
          MsgCustomCommand:
           begin
            LoadDataFromStream(Command, SizeOf(Command), Stream, 40061);
            len := len - SizeOf(Command);
            if (len > 0) then
             begin
              Buf := MemoryManager.GetMem(len);
              try
               LoadDataFromStream(Buf^, len, Stream, 40062);
               if (Assigned(FOnReceiveCommand)) then
                 FOnReceiveCommand(ServerSession.FUserID,Command,SendingDate,DeliveryDate,Buf,len);
              finally
                MemoryManager.FreeAndNilMem(Buf);
              end;
             end
            else
             if (Assigned(FOnReceiveCommand)) then
               FOnReceiveCommand(ServerSession.FUserID,Command,SendingDate,DeliveryDate,nil,0);
           end;
        else // case - client command
         begin
{ TODO :
What's this?
Why load data? }
{
          Buf := MemoryManager.GetMem(len);
          try
           LoadDataFromStream(Buf^,len,Stream,10271);
          finally
           MemoryManager.FreeAndNilMem(Buf);
          end;
}
         end; // else case
        end; // case
       end; // len>0
    end; // else case
  end; // case
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgServer.ReceiveMessageToServer> FINISH');
{$ENDIF}
end; // ReceiveMessageToServer


//------------------------------------------------------------------------------
// save message for off-line user
//------------------------------------------------------------------------------
function TMsgServer.SaveMessageForUser(UserID: Cardinal; Stream: TMsgMemoryStream): Integer;
var
  Buf:          PAnsiChar;
  fs:           TMsgFileStream;
  FileName,
  UserFileName: AnsiString;
  len:          Integer;
begin
     if (FDatabase = nil) then
      begin
       // save message to file
       repeat
        FileName := DataPath+IntToStr(UserID)+'-'+IntToStr(Random(MaxInt))+MSG_FILE_EXT;
       until not (aaFileExists(PAnsiChar(FileName)));
{$IFDEF LOG_SERVER_SAVE_MESSAGE}
aaWriteToLog('TMsgServer.SaveMessageForUser> FileName = '+FileName);
{$ENDIF}
       fs := TMsgFileStream.Create(FileName, fmCreate);
       try
        Buf := Stream.Buffer;
        SaveDataToStream(Buf^, Stream.Size, fs, 40064);
       finally
        fs.Free;
       end;
{$IFDEF LOG_SERVER_SAVE_MESSAGE}
aaWriteToLog('TMsgServer.SaveMessageForUser> Saved!');
{$ENDIF}
       // open user messages file
       UserFileName := GetUserFileName(UserID);
       if not (aaFileExists(PAnsiChar(UserFileName))) then
         fs := TMsgFileStream.Create(UserFileName, fmCreate)
       else
         fs := TMsgFileStream.Create(UserFileName, fmOpenWrite + fmShareDenyWrite, 10000);
       // add new message
       try
        fs.Position := fs.Size;
        len := Length(FileName);
        SaveDataToStream(len, SizeOf(len), fs, 40064);
        if len > 0 then
          SaveDataToStream(PAnsiChar(@FileName[1])^, Length(FileName), fs, 40064);
       finally
        fs.Free;
       end;
{$IFDEF LOG_SERVER_SAVE_MESSAGE}
aaWriteToLog('TMsgServer.SaveMessageForUser> UserFileName = '+UserFileName+' updated!');
{$ENDIF}
      end;
end; // SaveMessage


//------------------------------------------------------------------------------
// send message to user or save it in case off-line
//------------------------------------------------------------------------------
function TMsgServer.SendMessageToUsers(
                                        FromUserID:     Cardinal;
                                        ToUserIDs,
                                        Results:        TMsgIntegerArray;
                                        MessageType:    TMsgMessageType;
                                        SendingDate:    TDateTime;
                                        Stream:         TMsgMemoryStream
                                          ): Integer;
var
 i:     Integer;
begin
 try
  if Results.ItemCount <> ToUserIDs.ItemCount then
   begin
    Result := MSG_Error_SendMessage_BadResultArraySize;
    Exit;
   end;
 except
  Result := MSG_Error_SendMessage_BadResultArray;
  Exit;
 end;
 for i := 0 to (ToUserIDs.ItemCount - 1) do
  try
   Results.Items[i] := SendMessageToUser(FromUserID, Cardinal(ToUserIDs.Items[i]),
                                        MessageType, SendingDate, Stream);
  except
   Result := MSG_Error_SendMessageToUserFailed;
  end;
 Result := MSG_COMMAND_OK;
end; // SendMessageToUsers


//------------------------------------------------------------------------------
// send message to user or save it in case off-line
//------------------------------------------------------------------------------
function TMsgServer.SendMessageToUser(
                                        FromUserID,
                                        ToUserID:       Cardinal;
                                        MessageType:    TMsgMessageType;
                                        SendingDate:    TDateTime;
                                        Stream:         TMsgMemoryStream
                                          ): Integer;
var
  ToSession:    TMsgServerSession;
  MessageID:    Integer;
  StreamPos:    Int64;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  if (FDatabase <> nil) then
//  case of MessageType
  if (MessageType = aamtText)
  or (MessageType = aamtStream)
  or (MessageType = aamtBinary)
  then
   begin
    StreamPos := Stream.Position;
    Stream.Position := SizeOf(FServerID)+SizeOf(MessageType)+SizeOf(SendingDate);
    Result := MSG_Error_SendMessage_SaveHistoryToDatabaseFailed;
    MessageID := SaveMessageToDatabase(FDatabase,FromUserID,ToUserID,MessageType,
                          SendingDate,False,0,Stream);
    Stream.Position := StreamPos;
   end
  else
   begin
    try // save history
     MessageID := SaveMessageToDatabase(FDatabase,FromUserID,ToUserID,MessageType,
                          SendingDate,False,0,Stream);
    except
     on E: Exception do
       Result := MSG_Error_SendMessage_SaveHistoryToDatabaseFailed;
    end;
   end;
  if IsUserLogged(ToUserID) then
    begin // Recepient is on-line
     Result := MSG_Error_SendMessage_SessionNotFound;
     ToSession := FindSessionWithUser(ToUserID);
     if ToSession = nil then // Recepient is off-line
       SaveMessageForUser(ToUserID, Stream)
     else  // Recepient is on-line
      begin
       try // send message
        Result := MSG_Error_SendMessage_SendFailed;
        try
         ConnectionManager.SendMessage(ToSession,Stream.Buffer,Stream.Size);
{$IFDEF LOG_SERVER_MESSAGE_RESEND}
aaWriteToLog('TMsgServer.SendMessageToUser> SendMessage - 1 ok');
{$ENDIF}
        except
         on E: EMsgException do
          begin
           case e.NativeError of
            40078, 40073: // message sending failed by timeout
              if IsUserLogged(ToUserID) then
               begin
{
                if e.NativeError = 40078 then
                  AbortServerMessage(Self, ToSession.UserID);
}
{$IFDEF LOG_SERVER_MESSAGE_RESEND}
aaWriteToLog('TMsgServer.SendMessageToUser> SendMessage...');
{$ENDIF}
                ConnectionManager.SendMessage(ToSession,Stream.Buffer,Stream.Size);
{$IFDEF LOG_SERVER_MESSAGE_RESEND}
aaWriteToLog('TMsgServer.SendMessageToUser> SendMessage - OK!');
{$ENDIF}
               end
           else
            begin
{$IFDEF LOG_SERVER_MESSAGE_RESEND}
aaWriteToLog('TMsgServer.SendMessageToUser> unwaited exception!');
{$ENDIF}
             raise;
            end;
           end; // case
          end; // MsgException
        else // not MsgException
         begin
{$IFDEF LOG_SERVER_MESSAGE_RESEND}
aaWriteToLog('TMsgServer.SendMessageToUser> not MsgException!');
{$ENDIF}
          raise;
         end; 
        end;
        if (Result <> MSG_Error_SendMessage_SaveHistoryToDatabaseFailed) then
          Result := MSG_COMMAND_OK;
       except
        on E: Exception do
          SaveMessageForUser(ToUserID, Stream);
       end;
       try // save history
        if (FDatabase <> nil) then
         begin
          if (FStoreMessageHistory) then
           FDatabase.SetMessageDeliveryDate(MessageID)
          else
           FDatabase.DeleteMessage(MessageID);
         end;
       except
        on E: Exception do
          Result := MSG_Error_SendMessage_SaveHistoryToDatabaseFailed;
       end;
      end;
    end   // Recepient is on-line
   else  // Recepient is off-line
    begin
     Result := MSG_Error_SendMessage_NotLogged;
     SaveMessageForUser(ToUserID, Stream);
    end;
end;


//------------------------------------------------------------------------------
// receive message sent to user
//------------------------------------------------------------------------------
procedure TMsgServer.ReceiveMessageToUser(
                                        UserID:         Cardinal;
                                        MessageType:    TMsgMessageType;
                                        SendingDate:    TDateTime;
                                        ServerSession:  TMsgServerSession;
                                        Stream:         TMsgMemoryStream
                                          );

begin
  Move(ServerSession.FUserID, Stream.Buffer^, SizeOf(ServerSession.FUserID)); // replace ToUserID with FromUserID
  SendingDate := Now;
  Move(SendingDate,PAnsiChar(Stream.Buffer+SizeOf(ServerSession.FUserID)+SizeOf(MessageType))^,SizeOf(SendingDate));
  SendMessageToUser(ServerSession.FUserID, UserID, MessageType, SendingDate, Stream);
end; // ReceiveMessageToUser


//------------------------------------------------------------------------------
// receive custom message from client
//------------------------------------------------------------------------------
procedure TMsgServer.ReceiveMessage(ServerSession: TMsgServerSession; Buffer: PAnsiChar; Size: Integer);
var
  MessageType:  TMsgMessageType;
  ms:           TMsgMemoryStream;
  ToUserID:     Cardinal;
  SendingDate:  TDateTime;
begin
  ms := TMsgMemoryStream.Create(Buffer);
  try
   LoadDataFromStream(ToUserID,SizeOf(ToUserID),ms,40050);
   LoadDataFromStream(MessageType,SizeOf(MessageType),ms,10261);
   LoadDataFromStream(SendingDate,SizeOf(SendingDate),ms,11392);
   // ignore messages to guests
   if (ToUserID = MSG_INVALID_USER_ID) then
    Exit
   else
   if (ToUserID = FServerID) then
    begin
     // Message to Server
     ReceiveMessageToServer(MessageType,SendingDate,ServerSession,ms);
    end // Message to Server
   else
    begin // Message to other user
     ReceiveMessageToUser(ToUserID,MessageType,SendingDate,ServerSession,ms);
    end; // Message to other user
   finally
    ms.Free;
  end;
end; // ReceiveMessage


//------------------------------------------------------------------------------
// return 1 if (ascending) and (userinfo1 > userinfo2), -1 if < and 0 if equal
//------------------------------------------------------------------------------
function TMsgServer.CompareUsers(
                      const UserInfo1: TMsgUserInfo;
                      const UserInfo2: TMsgUserInfo;
                      SortBy:          TMsgUserInfoArraySortBy;
                      Ascending:       Boolean): Integer;
begin
  Result := -1;
  case SortBy of
   msgusbUserID:
    begin
     if (UserInfo1.UserID = UserInfo2.UserID) then
      Result := 0
     else
     if (UserInfo1.UserID > UserInfo2.UserID) then
      Result := 1;
    end;
   msgusbPort:
    begin
     if (UserInfo1.Port = UserInfo2.Port) then
      Result := 0
     else
     if (UserInfo1.Port > UserInfo2.Port) then
      Result := 1;
    end;
   msgusbUserName:
    begin
     Result := AnsiCompareStr(UserInfo1.UserName,UserInfo2.UserName);
    end;
   msgusbFirstName:
    begin
     Result := AnsiCompareStr(UserInfo1.FirstName,UserInfo2.FirstName);
    end;
   msgusbLastName:
    begin
     Result := AnsiCompareStr(UserInfo1.LastName,UserInfo2.LastName);
    end;
   msgusbHost:
    begin
     Result := AnsiCompareStr(UserInfo1.Host,UserInfo2.Host);
    end;
   msgusbApplication:
    begin
     Result := AnsiCompareStr(UserInfo1.Application,UserInfo2.Application);
    end;
   msgusbStatus:
    begin
     if (UserInfo1.Status = UserInfo2.Status) then
      Result := 0
     else
     if (UserInfo1.Status > UserInfo2.Status) then
      Result := 1;
    end
  else
   raise EMsgException.Create(11345,ErrorLInvalidSortType,[Integer(SortBy)]);
  end;
  if (Result < 0) then
    Result := -1;
  if (Result > 0) then
    Result := 1;
  if (Result <> 0) and (not Ascending) then
   Result := -Result;
end; // CompareUsers


//------------------------------------------------------------------------------
// SetDataPath
//------------------------------------------------------------------------------
procedure TMsgServer.SetDataPath(value: AnsiString);
begin
 if value <> FDataPath then
  FDataPath := value;
end; // SetDataPath


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TMsgServer.Create(AOwner: TComponent);
var
  Queue:    TMsgList;
begin
{$IFDEF DEBUG_LOG_SERVER_MESSAGE_RECEIVE}
  RecvMsgCount := 0;
{$ENDIF}
  FServerID := MsgDefaultServerID;
  FStoreMessageHistory := True;
  MinUserID := FServerID + 1;
  UseConfigFile := False;
  FConfigFileName := MsgDefaultServerConfigFileName;
  FActive := False;
  FConnectedUsers := TMsgThreadIntArray.Create();
  FConnectionManager := nil;
  FUsers := TMsgThreadList.Create;
  FEventsQueue := TMsgThreadList.Create;
  Queue := FEventsQueue.LockList;
  try
   Queue.Capacity := 128;
  finally
   FEventsQueue.UnlockList;
  end;
(*
aaInitTime;
aaInitTime(time1);
aaInitTime(time2);
aaInitTime(time3);
aaInitTime(time4);
{
aaInitTime(time5);
aaInitTime(time6);
aaInitTime(time7);
aaInitTime(time8);
aaInitTime(time9);
}
  Queue := FEventsQueue.LockList;
  try
   Queue.Add(PAnsiChar(slash));
   Queue.Delete(0);
  finally
   FEventsQueue.UnlockList;
  end;
*)
  FEventsThread := TMsgServerEventsThread.Create(self);
  {$IFDEF TRIAL_VERSION}
  FMaxConnections := MsgMaxSingleUserConnections;
  {$ENDIF}
  {$IFNDEF TRIAL_VERSION}
  FMaxConnections := MaxInt;
  {$ENDIF}
// create ConnectionParams Editor
  FConnectionParams := TMsgServerConnectParamsEditor.Create;
// create CryptoParamsEditor Editor
//  FCryptoParamsEditor := TMsgCryptoParamsEditor.Create;
  FCryptoParamsEditor := FConnectionParams.CryptoParams;
  inherited;
  FDataPath := ExtractFilePath(ParamStr(0));
  FDataPath :=  FDataPath + 'Data' + FSslash;
end; // Create


//------------------------------------------------------------------------------
// SendWithProgress
//------------------------------------------------------------------------------
function TMsgServer.SendWithProgress(
                                  ToUserID: Cardinal;
                                  ObjectType: TMsgMessageType;
                                  const FileName: AnsiString;
                                  Stream: TStream;
                                  Blocks: Integer;
                                  BlockSize: Integer;
                                  Directly: Boolean
                                  ): Integer;
var
  ServerSession:  TMsgServerSession;
  ObjectID:       Cardinal;
  dt:             TDateTime;
  SendObject:     PMsgSendObject;
begin
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - server SendWithProgress start');
{$ENDIF}
  PrepareToSendWithProgress(Stream.Size,Blocks,BlockSize);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - server PrepareToSendMessage...');
{$ENDIF}
  ServerSession := FindSessionWithUser(ToUserID);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - server InitProgressSend...');
{$ENDIF}
  if ServerSession = nil then
    Result := MSG_Error_SendMessage_SessionNotFound
  else
    Result := ServerSession.InitProgressSend(ObjectType,ToUserID,FileName,Stream.Size,Blocks,BlockSize,ObjectID);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - server Inited');
{$ENDIF}
  if (Result <> MSG_COMMAND_OK)
  or (ObjectID = MSG_INVALID_ID) then
    Exit;
// initialise sending
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - server initialise sending...');
{$ENDIF}
  AddNewSendObject(SendObject,ToUserID,ObjectID,ObjectType,FileName,Stream,
                   Blocks,BlockSize,Directly);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - server call event...');
{$ENDIF}
  CallSendEvent(ToUserID,ObjectID,ObjectType,FileName,Stream.Size,Blocks,BlockSize);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - server SendWithProgress finished!');
{$ENDIF}
end; // SendWithProgress


//------------------------------------------------------------------------------
// GetNetworkSettings
//------------------------------------------------------------------------------
function TMsgServer.GetNetworkSettings: TMsgServerNetworkSettingsEditor;
begin
  Result := FConnectionParams.FNetworkSettings;
end; // GetNetworkSettings


//------------------------------------------------------------------------------
// UsersCount
//------------------------------------------------------------------------------
function TMsgServer.UsersCount: Integer;
var
  RegisteredUsers:  TMsgList;
begin
  Result := -1;
  if (FDatabase <> nil) then
   Result := FDatabase.GetUsersCount
  else
   begin
    RegisteredUsers := FUsers.LockList;
    try
     Result := RegisteredUsers.Count;
    finally
     FUsers.UnLockList;
    end;
   end;
end; // UsersCount


//------------------------------------------------------------------------------
// OnLineUsersCount
//------------------------------------------------------------------------------
function TMsgServer.OnLineUsersCount: Integer;
{
var
  RegisteredUsers:  TMsgList;
  i:                Integer;
  BaseUserInfo:     PMsgBaseUserInfo;
}  
begin
  FConnectedUsers.Lock;
  try
    Result := FConnectedUsers.ItemCount;
  finally
    FConnectedUsers.Unlock;
  end;
{
  RegisteredUsers := FUsers.LockList;
  try
     for i:=0 to RegisteredUsers.Count-1 do
      begin
       BaseUserInfo := RegisteredUsers.Items[i];
       if BaseUserInfo <> nil then
        begin
         if IsUserConnected(BaseUserInfo^.UserInfo.UserID) then
           inc(Result);
        end;
      end;
  finally
  FUsers.UnLockList;
  end;
}
end; // OnLineUsersCount


//------------------------------------------------------------------------------
// GuestsCount
//------------------------------------------------------------------------------
function TMsgServer.GuestsCount: Integer;
var
  i:                Integer;
  Clients:          TMsgClientInfoArray;
begin
  Result := 0;
  GetClients(Clients);
  for i:=0 to Length(Clients)-1 do
    if Clients[i].UserID = MSG_INVALID_USER_ID then
      inc (Result);
end; // GuestsCount


//------------------------------------------------------------------------------
// get all users
//------------------------------------------------------------------------------
procedure TMsgServer.GetUsers(
                       var Users: TMsgUserInfoArray;
                       const SortBy: TMsgUserInfoArraySortBy = msgusbNone;
                       const Ascending: Boolean = True
                      );
var
  i:                Integer;
  RegisteredUsers:  TMsgList;
  UserInfo:         TMsgUserInfo;
  BaseUserInfo:     PMsgBaseUserInfo;
  Host, App:        AnsiString;
begin
  if (FDatabase <> nil) then
   FDatabase.GetUsers(Users,SortBy,Ascending)
  else
   begin
    RegisteredUsers := FUsers.LockList;
    try
     SetLength(Users, RegisteredUsers.Count);
     for i:=0 to RegisteredUsers.Count-1 do
      begin
       BaseUserInfo := RegisteredUsers.Items[i];
       if BaseUserInfo <> nil then
        begin
         UserInfo := BaseUserInfo^.UserInfo;
         if IsUserConnected(UserInfo.UserID) then
          begin
           UserInfo.Status := msgOnLine;
           FConnectionManager.GetClientInfo(FindSessionWithUser(UserInfo.UserID,False),
                                            Host, UserInfo.Port, App);
           UserInfo.Host := Host;
           UserInfo.Application := App;
          end
         else
          UserInfo.Status := msgOffline;
         Users[i] := UserInfo;
        end;
      end;
    finally
     FUsers.UnLockList;
    end;
    if (SortBy <> msgusbNone) then
     SortUsers(Users,SortBy,Ascending);
   end;
end;// GetUsers


//------------------------------------------------------------------------------
// sort users
//------------------------------------------------------------------------------
procedure TMsgServer.SortUsers(
                      var Users:        TMsgUserInfoArray;
                      const SortBy:     TMsgUserInfoArraySortBy;
                      const Ascending:  Boolean
                              );
var
 aLo, aHi, ItemCount: Integer;

 procedure QuickSort (
                    var iLo, iHi : Integer
                    );
  var
    Lo, Hi:  Integer;
    T, Mid:  TMsgUserInfo;
  begin
    Lo := iLo;
    Hi := iHi;
    Mid := Users[(Lo + Hi) shr 1];
    repeat
     while (CompareUsers(Users[Lo],Mid,SortBy,Ascending) < 0) and (Lo < iHi) do
      Inc(Lo);
     while (CompareUsers(Users[Hi],Mid,SortBy,Ascending) > 0) and (Hi > 0) do
       Dec(Hi);
      if (Lo <= Hi) then
       begin
        T := Users[Lo];
        Users[Lo] := Users[Hi];
        Users[Hi] := T;
        Inc(Lo);
        Dec(Hi);
       end;
    until (Lo > Hi);
    if (Hi > iLo) then
     begin
      // check infinite recurse
      if (iHi = Hi) then
       raise EMsgException.Create(11345,ErrorLErrorSoringRecordsByID,
        [Hi,Lo,iHi,iLo,ItemCount,Integer(SortBy),Integer(Ascending)]);
      QuickSort(iLo, Hi);
     end;
    if (Lo < iHi) then
      QuickSort(Lo, iHi);
  end; //QuickSort
begin
  ItemCount := Length(Users);
  if (ItemCount > 1) and (SortBy <> msgusbNone) then
   begin
    aLo := 0;
    aHi := ItemCount-1;
    QuickSort (aLo, aHi);
   end;
end; // SortUsers


//------------------------------------------------------------------------------
// GetLocalHost
//------------------------------------------------------------------------------
function TMsgServer.GetLocalHost: AnsiString;
begin
  Result := ''; // For compatibility with MsgCommunicator
end;// GetLocalHost


//------------------------------------------------------------------------------
// GetLocalPort
//------------------------------------------------------------------------------
function TMsgServer.GetLocalPort: Integer;
begin
  Result := ConnectionParams.LocalPort;
end; // GetLocalPort


//------------------------------------------------------------------------------
// return maximum number of connections
//------------------------------------------------------------------------------
function TMsgServer.GetMaxConnections: Integer;
begin
 {$IFDEF TRIAL_VERSION}
 Result := MsgMaxSingleUserConnections;
 {$ELSE}
 Result := FMaxConnections;
 {$ENDIF}
end; // GetMaxConnections


//------------------------------------------------------------------------------
// SetServerID
//------------------------------------------------------------------------------
procedure TMsgServer.SetServerID(Value: Integer);
var
  locActive:    Boolean;
  IniFile:      TIniFile;
  FileName:     AnsiString;
begin
  locActive := Active;
  Active := False;

  FServerID := Value;
  MinUserID := FServerID + 1;

// Save ServerID to INI file
  if UseConfigFile then
   begin
    if (ExtractFilePath(FConfigFileName) <> '') then
     FileName := FConfigFileName
    else
     FileName := ExtractFilePath(ParamStr(0))+ FConfigFileName;
    IniFile := TIniFile.Create(FileName);
    try
     IniFile.WriteInteger('Server Connection Parameters','ServerID',ServerID);
    finally
     IniFile.Free;
    end;
   end; // Save to config file

  Active := locActive;
end;// SetServerID


//------------------------------------------------------------------------------
// GetUserFileName
//------------------------------------------------------------------------------
function TMsgServer.GetUserFileName(UserID: Cardinal): AnsiString;
begin
  Result := DataPath+IntToStr(UserID)+MSG_USER_MESSAGES_EXT;
end; // GetUserFileName


//------------------------------------------------------------------------------
// DeleteUsers
//------------------------------------------------------------------------------
procedure TMsgServer.DeleteUsers;
var
  Users:      TMsgList;
  i:          Integer;
begin
  if (FDatabase = nil) then
   begin
    Users := FUsers.LockList;
    try
     for i:=Users.Count-1 downto 0 do
       Dispose(Users.Items[i]);
     Users.Clear;
    finally
     FUsers.UnlockList;
    end;
   end;
end; // DeleteUsers


//------------------------------------------------------------------------------
// ClearAll
//------------------------------------------------------------------------------
procedure TMsgServer.ClearAll;
var
lActive:      Boolean;
begin
  lActive := FActive;
 try
  FActive := False;
  if FConnectionManager <> nil then
    FConnectionManager.DisconnectAll(False);
  FConnectedUsers.Lock;
  try
   FConnectedUsers.SetSize(0);
  finally
   FConnectedUsers.Unlock;
  end;
  if (FDatabase <> nil) then
   begin
    if (not lActive) then
     FDatabase.OpenOrCreateDatabase(False);
    try
     FDatabase.ClearAll;
    finally
     if (not lActive) then
      FDatabase.CloseDatabase;
    end;
   end
  else
   begin
    DeleteUsers;
  // delete files
    SysUtils.DeleteFile(DataPath+MSG_USERS_FILE);
    DeleteFiles(DataPath,'*'+MSG_UCL_EXT);
    DeleteFiles(DataPath,'*'+MSG_FILE_EXT);
    DeleteFiles(DataPath,'*'+MSG_USER_MESSAGES_EXT);
   end;
 finally
  FActive := lActive;
 end;
end; // ClearAll


//------------------------------------------------------------------------------
// Connect session
//------------------------------------------------------------------------------
function TMsgServer.ConnectSession(Session: TMsgServerSession): Boolean;
begin
  Result := False;
  if Assigned(BeforeConnect) then
    BeforeConnect(Session);
  FConnectedUsers.Lock;
// Add new user
  try
   if (FConnectedUsers.ItemCount >= MaxConnections) then
    begin
     Session.FUserID := MSG_INVALID_USER_ID;
     Exit;
    end;
{
    if (Session.UserID = MSG_INVALID_USER_ID) // guest login
    // Check for UserID to exist
    or (FConnectedUsers.IsValueExists(Integer(Session.UserID)))
    then
      Session.FUserID := GetNewUserID;
}
   if IsUserExisting(Session.UserID) then // registered user
    begin
     if not(IsUserConnected(Session.UserID)) then
       FConnectedUsers.Add(Integer(Session.UserID));   // Save Connected status
    end
   else
     if Session.UserID <> MSG_INVALID_USER_ID then
       Session.FUserID := MSG_INVALID_USER_ID;
   Result := True;
  finally
   FConnectedUsers.Unlock;
  end;
// AfterConnect
  if Assigned(AfterConnect) then
    AfterConnect(Session);
end; // ConnectSession


//------------------------------------------------------------------------------
// LogUser
//------------------------------------------------------------------------------
procedure TMsgServer.LogUser(Session: TMsgServerSession; Logged: Boolean);
var
  LogEvent:    PMsgEvent;
begin
  FConnectedUsers.Lock;
  try
   if Logged then // Save Connected status
    FConnectedUsers.Add(Integer(Session.UserID))
   else
    FConnectedUsers.Remove(Integer(Session.UserID));   // Save Connected status
  finally
    FConnectedUsers.Unlock;
  end;
  New(LogEvent);
  LogEvent.FromUserID := Session.FUserID;
  LogEvent.Session := Session;
  if Logged then
    LogEvent.EventType := MsgUserOnLine
  else
    LogEvent.EventType := MsgUserOffLine;
  FEventsQueue.Add(LogEvent);
end;// LogUser


//------------------------------------------------------------------------------
// Disconnect session
//------------------------------------------------------------------------------
procedure TMsgServer.DisconnectSession(Session: TMsgServerSession);
var
  Sessions:        TMsgServerSessionsArray;
  i:               Integer;
begin
// BeforeDisconnect
  if Assigned(BeforeDisconnect) then
   BeforeDisconnect(Session);
// Check for UserID to exist in connected users
  if not (FConnectedUsers.IsValueExists(Integer(Session.UserID))) then
   begin
// Save disconnected status
    FConnectedUsers.Lock;
    try
      FConnectedUsers.Remove(Integer(Session.UserID));
    finally
      FConnectedUsers.Unlock;
    end;
{ removed since v.3.20 -- needs to have FGuestID in session to enable decrease FGuestID in server, disabled for now
// Is it the latest guest?
    if not IsUserExisting(Session.UserID) then
     begin
      EnterCriticalSection(FCSect);
      try
        if FGuestID = (Session.UserID+1) then  // needs to replace Session.UserID with Session.FGuestID
          Dec(FGuestID);
      finally
        LeaveCriticalSection(FCSect);
      end;
     end;
}
   end; // UserID was existing
// AfterDisconnect
  if Assigned(AfterDisconnect) then
    AfterDisconnect(Session);
end; // DisonnectSession


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TMsgServer.Destroy;
var
  i:          Integer;
  List:       TMsgList;
begin
  Active := False;
  FConnectionParams.Free;
  if (FConnectionManager <> nil) then
    FConnectionManager.Free;
  FConnectionManager := nil;
  DeleteUsers;
  FUsers.Free;
  FConnectedUsers.Free;

  FEventsThread.Terminate;
  sleep(100);
  if FEventsThread = nil then
   begin
    List := FEventsQueue.LockList;
    try
     for i:=List.Count-1 downto 0 do
      begin
       Dispose(List.Items[i]);
      end;
     List.Clear;
    finally
     FEventsQueue.UnLockList;
    end;
    FEventsQueue.Free;
   end;

  if not FConnectionManager.CloseThread(@FEventsThread,MsgServerError,ErrorREventsThread) then
    DoOnError(
                  MsgServerError,40521,
                  ErrorRServer+
                  ErrorRDestroy+
                  ErrorREventsThread
                  );
  inherited;
end; // Destroy

(*
//------------------------------------------------------------------------------
// SetAllowReceiveFiles
//------------------------------------------------------------------------------
procedure TMsgServer.SetAllowFiles(Value: Boolean);
begin
  FAllowFiles := Value;
end; // SetAllowReceiveFiles
*)


//------------------------------------------------------------------------------
// fills array with client info
//------------------------------------------------------------------------------
procedure TMsgServer.GetClients(var Clients: TMsgClientInfoArray);
var ClientSessions: TMsgSessionsArray;
    i,l:            Integer;
begin
  FConnectionManager.GetClientsList(ClientSessions);
  l := Length(ClientSessions);
  SetLength(Clients,l);
  if (l > 0) then
   for i := Low(ClientSessions) to High(ClientSessions) do
    Clients[i] := TMsgServerSession(ClientSessions[i]).GetClientInfo;
  ClientSessions := nil;
end; // GetClients


//------------------------------------------------------------------------------
// search for UserID by the UserName
//------------------------------------------------------------------------------
function TMsgServer.FindUserID(const UserName: AnsiString): Cardinal;
// returns first occurrence of UserID with this UserName or
// MSG_INVALID_USER_ID in case of not found
var
  Users:        TMsgList;
  UserInfo:     PMsgBaseUserInfo;
  i:            Integer;
begin
  Result := MSG_INVALID_USER_ID;
  if (FDatabase <> nil) then
   begin
    Result := FDatabase.FindUserID(UserName);
   end
  else
   begin
    Users := FUsers.LockList;
    try
     for i := Users.Count-1 downto 0 do
      begin
       UserInfo := Users.Items[i];
       if (UserInfo <> nil) then
        if (UserInfo.UserInfo.UserName = UserName) then
         begin
          Result := UserInfo.UserInfo.UserID;
          Exit;
         end;
      end;
    finally
     FUsers.UnlockList;
    end;
   end;
end; // FindUserID


//------------------------------------------------------------------------------
// fills Users with user information records if some users were found
//------------------------------------------------------------------------------
procedure TMsgServer.FindUsers(
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
                    UserName:                     AnsiString = '';
                    FirstName:                    AnsiString = '';
                    LastName:                     AnsiString = '';
                    Organization:                 AnsiString = '';
                    Department:                   AnsiString = '';
                    Host:                         AnsiString = '';
                    Application:                  AnsiString = '';
                    SearchCondition:              AnsiString = ''; // SQL WHERE clause without word WHERE
                    // ORDER BY columns without ORDER BY words
                    // example: SenderID DESC, SendingDate ASC
                    SortBy:                       TMsgUserInfoArraySortBy = msgusbNone;
                    Ascending:                    Boolean = True;
                    OrderByClause:                AnsiString = ''
                   );
begin
  SetLength(Users,0);
  if (FDatabase = nil) then
   raise EMsgException.Create(11543,ErrorLDatabaseIsNotAssigned);
  FDatabase.FindUsers(
                      Users,
                      UserNameComparison,FirstNameComparison,LastNameComparison,
                      OrganizationComparison,DepartmentComparison,
                      ApplicationComparison,HostComparison,PortComparison,
                      Status,UserID,
                      UserName,
                      FirstName,
                      LastName,
                      Organization,
                      Department,
                      Host,
                      Application,
                      SearchCondition,
                      SortBy,
                      Ascending,
                      OrderByClause
                      );
end; // FindUsers;


//------------------------------------------------------------------------------
// return new query object with found messages from MsgMessages table
//------------------------------------------------------------------------------
function TMsgServer.FindMessages(
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
                    ): TDataset;
begin
  if (FDatabase = nil) then
   raise EMsgException.Create(11566,ErrorLDatabaseIsNotAssigned);
  Result := FDatabase.FindMessages(
                    MessageTextComparison,MessageUnicodeTextComparison,
                    SendingDate,DeliveryDate,SearchDelivered,Delivered,
                    MessageText,MessageUnicodeText,
                    SenderID,RecipientID,
                    MessageType, MessageDataSize,
                    OrderBySendingDate, OrderByClause, Command
                                  );
end; // FindMessages


//------------------------------------------------------------------------------
// return ture if client is still connected to server
//------------------------------------------------------------------------------
function TMsgServer.IsClientConnected(const Client: TMsgClientInfo): Boolean;
begin
  Result := (GetSession(Client) <> nil);
end; // IsClientConnected


//------------------------------------------------------------------------------
// return ture if user is connected to server
//------------------------------------------------------------------------------
function TMsgServer.IsUserConnected(const UserID: Cardinal): Boolean;
begin
  FConnectedUsers.Lock;
  Result := FConnectedUsers.IsValueExists(Integer(UserID));
  FConnectedUsers.Unlock;
end; // IsClientConnected


//------------------------------------------------------------------------------
// Send text message
//------------------------------------------------------------------------------
function TMsgServer.SendMessageMultiple(ToUserIDs: TMsgIntegerArray;
                                        const Text: AnsiString;
                                        var Results: TMsgIntegerArray): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  dt:             TDateTime;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  MessageType := aamtText;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,40157);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,40158);
   dt := Now;
   SaveDataToStream(dt,SizeOf(dt),ms,40159);
   SaveStringToStream(Text,ms,40160);
   Result := SendMessageToUsers(FServerID,ToUserIDs,Results,MessageType,dt,ms);
  finally
   ms.Free;
  end;
  Result := MSG_COMMAND_OK;
end; // SendMessage


{$IFDEF D6H}
//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
function TMsgServer.SendMessageMultiple(ToUserIDs: TMsgIntegerArray;
                                        const Text: WideString;
                                        var Results: TMsgIntegerArray): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  dt:             TDateTime;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  MessageType := aamtUnicodeText;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,40161);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,40162);
   dt := Now;
   SaveDataToStream(dt,SizeOf(dt),ms,40163);
   SaveWideStringToStream(Text,ms,40164);
   Result := SendMessageToUsers(FServerID,ToUserIDs,Results,MessageType,dt,ms);
  finally
   ms.Free;
  end;
  Result := MSG_COMMAND_OK;
end; // SendMessage

{$ELSE}

//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
function TMsgServer.SendMessageMultipleW(ToUserIDs: TMsgIntegerArray;
                                         const Text: WideString;
                                         var Results: TMsgIntegerArray): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  dt:             TDateTime;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  MessageType := aamtUnicodeText;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,40165);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,40166);
   dt := Now;
   SaveDataToStream(dt,SizeOf(dt),ms,40167);
   SaveWideStringToStream(Text,ms,40168);
   Result := SendMessageToUsers(FServerID,ToUserIDs,Results,MessageType,dt,ms);
  finally
   ms.Free;
  end;
  Result := MSG_COMMAND_OK;
end; // SendMessageW

{$ENDIF}

//------------------------------------------------------------------------------
// Send binary message
//------------------------------------------------------------------------------
function TMsgServer.SendMessageMultiple(ToUserIDs: TMsgIntegerArray; Buffer: PAnsiChar; Size: Integer;
                                        var Results: TMsgIntegerArray;
                                        Directly: Boolean = True;
                                        MessageType: TMsgMessageType = aamtBinary
                                ): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  dt:             TDateTime;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,40169);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,40170);
   dt := Now;
   SaveDataToStream(dt,SizeOf(dt),ms,40171);
   SaveDataToStream(Size,SizeOf(Size),ms,40172);
   if (Size > 0) then
     SaveDataToStream(Buffer^,Size,ms,40173);
   Result := SendMessageToUsers(FServerID,ToUserIDs,Results,MessageType,dt,ms);
  finally
   ms.Free;
  end;
  Result := MSG_COMMAND_OK;
end; // SendMessage


//------------------------------------------------------------------------------
// Send stream
//------------------------------------------------------------------------------
function TMsgServer.SendMessageMultiple(ToUserIDs: TMsgIntegerArray;
                                        Stream: TStream;
                                        var Results: TMsgIntegerArray): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  dt:             TDateTime;
  Size:           Int64;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  MessageType := aamtStream;
  Size := Stream.Size;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,40174);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,40175);
   SaveDataToStream(dt,SizeOf(dt),ms,40176);
   SaveDataToStream(Size,SizeOf(Size),ms,40177);
   if (Size > 0) then
    begin
     if (Stream is TMsgStream) then
      TMsgStream(Stream).SaveToStream(ms)
     else
      ms.CopyFrom(Stream,Size);
    end;
   Result := SendMessageToUsers(FServerID,ToUserIDs,Results,MessageType,dt,ms);
  finally
   ms.Free;
  end;
  Result := MSG_COMMAND_OK;
end; // SendMessageMultiple


//------------------------------------------------------------------------------
// Send text message
//------------------------------------------------------------------------------
function TMsgServer.SendMessage(ToUserID: Cardinal; const Text: AnsiString): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  dt:             TDateTime;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  MessageType := aamtText;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,11577);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,11578);
   dt := Now;
   SaveDataToStream(dt,SizeOf(dt),ms,11579);
   SaveStringToStream(Text,ms,11254);
   Result := SendMessageToUser(FServerID,ToUserID,MessageType,dt,ms);
  finally
   ms.Free;
  end;
end; // SendMessage


{$IFDEF D6H}
//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
function TMsgServer.SendMessage(ToUserID: Cardinal; const Text: WideString): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  dt:             TDateTime;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  MessageType := aamtUnicodeText;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,11623);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,11624);
   dt := Now;
   SaveDataToStream(dt,SizeOf(dt),ms,11625);
   SaveWideStringToStream(Text,ms,11626);
   Result := SendMessageToUser(FServerID,ToUserID,MessageType,dt,ms);
  finally
   ms.Free;
  end;
end; // SendMessage
{$ELSE}
//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
function TMsgServer.SendMessageW(ToUserID: Cardinal; const Text: WideString): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  dt:             TDateTime;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  MessageType := aamtUnicodeText;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,11623);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,11624);
   dt := Now;
   SaveDataToStream(dt,SizeOf(dt),ms,11625);
   SaveWideStringToStream(Text,ms,11626);
   Result := SendMessageToUser(FServerID,ToUserID,MessageType,dt,ms);
  finally
   ms.Free;
  end;
end; // SendMessageW
{$ENDIF}

//------------------------------------------------------------------------------
// Send binary message
//------------------------------------------------------------------------------
function TMsgServer.SendMessage(ToUserID: Cardinal; Buffer: PAnsiChar; Size: Integer;
                                        Directly: Boolean = True;
                                        MessageType: TMsgMessageType = aamtBinary
                                ): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  dt:             TDateTime;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,11580);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,11256);
   dt := Now;
   SaveDataToStream(dt,SizeOf(dt),ms,11396);
   SaveDataToStream(Size,SizeOf(Size),ms,11257);
   if (Size > 0) then
     SaveDataToStream(Buffer^,Size,ms,11258);
   Result := SendMessageToUser(FServerID,ToUserID,MessageType,dt,ms);
  finally
   ms.Free;
  end;
end; // SendMessage


//------------------------------------------------------------------------------
// Send stream
//------------------------------------------------------------------------------
function TMsgServer.SendMessage(ToUserID: Cardinal; Stream: TStream): Integer;
var
  Session:        TMsgServerSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  dt:             TDateTime;
  Size:           Int64;
begin
  Result := MSG_Error_SendMessage_InternalDataError;
  MessageType := aamtStream;
  Size := Stream.Size;
  ms := TMsgMemoryStream.Create();
  try
   SaveDataToStream(FServerID,SizeOf(FServerID),ms,11581);
   SaveDataToStream(MessageType,SizeOf(MessageType),ms,11259);
   SaveDataToStream(dt,SizeOf(dt),ms,11397);
   SaveDataToStream(Size,SizeOf(Size),ms,11260);
   if (Size > 0) then
    begin
     if (Stream is TMsgStream) then
      TMsgStream(Stream).SaveToStream(ms)
     else
      ms.CopyFrom(Stream,Size);
    end;
   Result := SendMessageToUser(FServerID,ToUserID,MessageType,dt,ms);
  finally
   ms.Free;
  end;
end; // SendMessage


//------------------------------------------------------------------------------
// SendCommand
//------------------------------------------------------------------------------
function TMsgServer.SendCommand(
                                ToUserID: Cardinal;
                                Command:  Cardinal;
                                Buffer:   PAnsiChar;
                                Size:     Integer
                                        ): Integer;
var
  Session:        TMsgServerSession;
  Buf:            PAnsiChar;
  BufSize:        Integer;
begin
  Result := MSG_Error_SendCommand_NotConnected;
  try
    Session := FindSessionWithUser(ToUserID);
  except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else
      DoOnError(Result);
     Exit;
  end;
  if (Session <> nil) then
   begin
    BufSize := Size + SizeOf(Command);
    Buf := MemoryManager.GetMem(BufSize);
    try
     Move(Command, Buf^, SizeOf(Command));
     Move(Buffer^, (Buf+SizeOf(Command))^, Size);
     Result := Session.SendCommand(MsgCustomCommand, Buf, BufSize);
    finally
     MemoryManager.FreeAndNilMem(Buf);
    end;
   end;
end;// SendCommand

// TMsgServer



////////////////////////////////////////////////////////////////////////////////
//
// TMsgServerEventsThread
//
////////////////////////////////////////////////////////////////////////////////



//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgServerEventsThread.Create(
                          Server:          TMsgServer
                                            );
begin
 try
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog('SERVER EVENTS THREAD - START - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  FServer := Server;
  inherited Create(False);
  Priority := tpNormal; // tpLowest;
  FreeOnTerminate := True;
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog('SERVER EVENTS THREAD - STARTED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerEventsThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    FServer.DoOnError(
                  MsgServerEventsThread,-1,
                  Error);
    Destroy;
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgServerEventsThread.Destroy;
begin
 try
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog('SERVER EVENTS THREAD - FINISH - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}

  if FServer.FEventsThread <> nil then
    FServer.FEventsThread := nil;

  inherited Destroy;
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog('SERVER EVENTS THREAD - FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerEventsThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
    FServer.DoOnError(
                  MsgServerEventsThread,-1,
                  Error);
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgServerEventsThread.Execute;
var
  Event:                PMsgEvent;
  Queue:                TMsgList;
  Success:              Boolean;
begin
 try
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog('SERVER EVENTS THREAD - EXECUTE - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
try
{$ENDIF}
  repeat
   sleep(1);
   if Terminated then
    begin
{$IFDEF DEBUG_LOG_EVENTS}
//aaWriteToLog('SERVER EVENTS THREAD - EXECUTE - Lock Sessions... - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
     Exit;
    end;
   Queue := FServer.FEventsQueue.LockList;
   try
    if Queue.Count = 0 then
     begin
      Continue;
     end;
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Queue.Count = '+IntToStr(Queue.Count));
{$ENDIF}
    Event := Queue.Items[0];
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': new Event');
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Session = '+IntToStr(Integer(Event.Session)));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Process FromUserID = '+IntToStr(Event.FromUserID)+', EventType = '+IntToStr(Integer(Event.EventType)));
{$ENDIF}
   finally
    FServer.FEventsQueue.UnlockList;
   end;

{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': unlocked');
{$ENDIF}

   Success := False;
     case Event.EventType of
      MsgUserOnLine, MsgUserOffLine:
       begin
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': LogUser');
{$ENDIF}
        try
         if FServer.IsUserExisting(Event.FromUserID) then
           LogUser(Event)
         else
          begin
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': log event from not existing user!');
{$ENDIF}
          end;
        finally
         Success := True; // delete processed event in any case -- no needs to resend to off-line users
        end;
       end;
      MsgInitLargeObject:
       begin
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': InitLargeObject');
{$ENDIF}
        if ((FServer.ServerID = Event.FromUserID) // object from server
         or FServer.IsUserExisting(Event.FromUserID)) then // object from existing user
           Success := InitLargeObject(Event) // needs to resend to off-line user
         else
          begin
           Success := True; // delete event of not existing user
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': log event from not existing user!');
{$ENDIF}
          end;
       end;
     end;

   if Success then
    begin
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Process UserID = '+IntToStr(Event.FromUserID)+', Success!');
{$ENDIF}
     Queue := FServer.FEventsQueue.LockList;
     try
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': dispose...');
{$ENDIF}
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': delete...');
{$ENDIF}
      if Queue.Count > 0 then
       begin
        Dispose(Event);
        Queue.Delete(0);
       end;
     finally
      FServer.FEventsQueue.UnlockList;
     end;
    end
   else // not success - move to the end of queue
    begin
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': not success - move to the end of queue');
{$ENDIF}
     Queue := FServer.FEventsQueue.LockList;
     try
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': delete...');
{$ENDIF}
      if Queue.Count > 0 then
       begin
        Queue.Delete(0);
{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': add');
{$ENDIF}
        Queue.Add(Event);
       end;
     finally
      FServer.FEventsQueue.UnlockList;
     end;
    end;

{$IFDEF DEBUG_LOG_EVENTS}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Next step');
{$ENDIF}
  until False;
{$IFDEF DEBUG_LOG_EVENTS}
finally
aaWriteToLog('SERVER EVENTS THREAD - EXECUTE FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
end;
{$ENDIF}
 except
  on E: Exception do
   begin
    Error:=
                  ErrorRServer+ErrorRServerEventsThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    FServer.DoOnError(
                  MsgServerEventsThread,-1,
                  Error);
   end;
 end;
end;// Execute


//------------------------------------------------------------------------------
// InitLargeObject
//------------------------------------------------------------------------------
function TMsgServerEventsThread.InitLargeObject(Event: PMsgEvent): Boolean;
var
  Session:         TMsgServerSession;
  ErrCode:         Integer;
  ErrMessage:      AnsiString;
begin
  Result := False;
  try // Save event to database
   if (FServer.FDatabase <> nil) then
    begin
//     TMsgServer(FOwnerComponent).FConnectionManager.GetClientInfo(Event.Session,Host,Port,App);
//     TMsgServer(FOwnerComponent).FDatabase.ChangeUserStatus(False,Event.FromUserID,msgOnline,Host,Port,App);
    end;
  except
//   TMsgServer(FOwnerComponent).DoOnError(40094,-1,ErrorRServerOnLineCannotChangeUserStatus+IntToStr(Event.FromUserID));
  end;
  try // Send event
   ErrCode := -1;
   ErrMessage := '';
   Session := FServer.FindSessionWithUser(Event.LargeObject.ToUserID);
   ErrCode := 40095;
   if Session <> nil then
     if FServer.ConnectionManager.FNetwork <> nil then
       if PMsgSrvrSession(Session).MsgControlCode <> MsgTerminate then
         try
          TMsgServerSession(Session).SendEvent(Event);
          Result := True;
         except
          ErrMessage := IntToStr(Event.FromUserID);
          raise;
         end;
  except
  end;
end; // InitLargeObject


//------------------------------------------------------------------------------
// LogUser
//------------------------------------------------------------------------------
procedure TMsgServerEventsThread.LogUser(Event: PMsgEvent);
var
  Sessions:        TMsgServerSessionsArray;
  ErrCode,
  l,i,Port:        Integer;
  ErrMessage,
  Host,App:        AnsiString;
begin
  try // Change user status
   if (FServer.FDatabase <> nil) then
    begin
     case Event.EventType of
      MsgUserOffLine:
        FServer.FDatabase.ChangeUserStatus(False,Event.FromUserID,msgOffLine);
      MsgUserOnLine:
       begin
// moved to TMsgServerSession.ExecuteLogon
//        TMsgServer(FOwnerComponent).FConnectionManager.GetClientInfo(Event.Session,Host,Port,App);
//        TMsgServer(FOwnerComponent).FDatabase.ChangeUserStatus(False,Event.FromUserID,msgOnline,Host,Port,App);
       end;
     else
       FServer.DoOnError(40126,-1,ErrorRServerUnknownCannotChangeUserStatus+IntToStr(Event.FromUserID)+ErrorRServerUnknownCannotChangeUserStatus+IntToStr(Integer(Event.EventType)));
     end;
    end;
   except
     case Event.EventType of
      MsgUserOffLine:
       FServer.DoOnError(40097,-1,ErrorRServerOffLineCannotChangeUserStatus+IntToStr(Event.FromUserID));
// moved to TMsgServerSession.ExecuteLogon
//      MsgUserOnLine:
//       TMsgServer(FOwnerComponent).DoOnError(40094,-1,ErrorRServerOnLineCannotChangeUserStatus+IntToStr(Event.FromUserID));
     end;
   end;
  try // Send off-line event to all on-line user who have this user in their contacts lists
   ErrCode := -1;
   ErrMessage := '';
   Sessions := FServer.FindSessionsWithUserInContacts(Event.FromUserID);
   ErrCode := 40095;
   l := Length(Sessions);
   for i:=0 to l-1 do
     if Sessions[i].Session <> nil then
      if FServer.ConnectionManager.FNetwork <> nil then
        if Sessions[i].MsgControlCode <> MsgTerminate then
         try
          TMsgServerSession(Sessions[i].Session).SendEvent(Event);
         except
          ErrMessage := ErrorRServerOnLine + IntToStr(TMsgServerSession(Sessions[i].Session).UserID);
          raise;
         end;
  except
   on e: Exception do
    case Event.EventType of
     MsgUserOffLine:
       FServer.DoOnError(40098,ErrCode,ErrorRServerOffLineCannotSendOffLineEvent+IntToStr(Event.FromUserID)+
         ', length = '+IntToStr(l)+
         #13#10+ErrMessage+#13#10+e.Message);
     MsgUserOnLine:
       FServer.DoOnError(40096,ErrCode,ErrorRServerOnLineCannotSendOnLineEvent+IntToStr(Event.FromUserID)+
         ', length = '+IntToStr(l)+
         #13#10+ErrMessage+#13#10+e.Message);
    end;
  end;
end;// LogUser


// TMsgServerEventsThread



////////////////////////////////////////////////////////////////////////////////
//
// General functions
//
////////////////////////////////////////////////////////////////////////////////


function InstallingService: Boolean;
begin
 Result := FindCmdLineSwitch('INSTALL',['-','\','/'],True) or
           FindCmdLineSwitch('UNINSTALL',['-','\','/'],True);
end;

function InteractiveService: Boolean;
begin
 Result := (not FindCmdLineSwitch('NOINTERACT',['-','\','/'],True));
end;


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgServer> initialized');
{$ENDIF}

end.
