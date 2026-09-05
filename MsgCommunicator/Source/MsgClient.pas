{******************************************************************************}
{                                                                              }
{ Client components                                                            }
{                                                                              }
{******************************************************************************}
{$HINTS OFF}
{$WARNINGS OFF}

unit MsgClient;

interface

{$I MsgVer.inc}

uses Db, SysUtils, Classes,
{$IFDEF MSWINDOWS}
     Windows,
     Forms,
     Dialogs,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
     QForms,
     QDialogs,
{$ENDIF}
{$IFDEF TRIAL_VERSION}
 {$IFDEF MSWINDOWS}
     Registry, MsgDECUtil, MsgCipher,
 {$ENDIF}
{$ENDIF}

//  MsgCommunicator units

     MsgCrypto,
     MsgCompression,
     MsgDatabase,
     MsgTypes,
     MsgExcept,
 {$IFDEF DEBUG_LOG}
     MsgDebug,
 {$ENDIF}
     MsgMemory,
     MsgCriticalSection,
     MsgConnection,
     MsgComBase,
     MsgComMain,
     MsgConst;


const

  MSG_BLOCK_EXT = '.blk';


type

  TMsgCompressionAlgorithm = (caNone,caZLIB,caBZIP,caPPM);

  TMsgClientSession = class;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TMsgClientNetworkSettingsEditor = class (TMsgNetworkSettingsEditor)
   private
    FConnectRetryCount:        Integer;
    FConnectDelay:             Integer;
    FUseServerSettings:        Boolean;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure CopySettingsToConnectParams(var ConnectParams: TMsgConnectParams); override;
    procedure SetDefaultSettings(Value: TMsgDefaultNetworkSettings); override;
   published
    property ConnectRetryCount:        Integer read FConnectRetryCount write FConnectRetryCount;
    property ConnectDelay:             Integer read FConnectDelay write FConnectDelay;
    property UseServerSettings:  Boolean read FUseServerSettings write FUseServerSettings;
  end; // TMsgClientNetworkSettingsEditor



////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientConnectParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

  TMsgClientConnectParamsEditor = class (TMsgConnectionParamsEditor)
   private
    FRemoteHost:                    AnsiString;
    FRemotePort:                    Cardinal;
    FCompressionAlgorithm:          TMsgCompressionAlgorithm;
    FCompressionMode:               Byte;
    FServerID:                      Cardinal;
    FNetworkSettings:               TMsgClientNetworkSettingsEditor;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function GetConnectParams: TMsgConnectParams; override;
   published
    property RemoteHost: AnsiString read FRemoteHost write FRemoteHost;
    property RemotePort: Cardinal read FRemotePort write FRemotePort;
    property CompressionAlgorithm: TMsgCompressionAlgorithm
              read FCompressionAlgorithm write FCompressionAlgorithm;
    property CompressionMode: Byte read FCompressionMode write FCompressionMode;
    property ServerID: Cardinal read FServerID write FServerID;
{$IFDEF RELEASE_BUILD}
   public
{$ELSE}
   published
{$ENDIF}
    property NetworkSettings: TMsgClientNetworkSettingsEditor read FNetworkSettings write FNetworkSettings;
  end;



////////////////////////////////////////////////////////////////////////////////
//
// TMsgClient
//
////////////////////////////////////////////////////////////////////////////////

 TMsgClient = class (TMsgComponent)
  private
    FDatabase:                TMsgDatabase;
    FTempTable:               TMsgTempTable;
    FUserID:                  Cardinal;
    FPassword:                AnsiString;
    FActive:                  Boolean;
    FAllowDirectly:           Boolean;
    FConnected:               Boolean;
    FConnectedDirectly:       Boolean;
    FContacts:                TMsgContactInfoArray;
    FSessions:                TMsgThreadList;
    FBeforeActive:            TNotifyEvent;
    FAfterActive:             TNotifyEvent;
    FAfterConnect:            TNotifyEvent;
    FAfterDisconnect:         TNotifyEvent;
    FAfterLogon:              TNotifyEvent;
    FAfterLogoff:             TNotifyEvent;
    FBeforeLogon:             TNotifyEvent;
    FBeforeLogoff:            TNotifyEvent;
    FBeforeConnect:           TNotifyEvent;
    FBeforeDisconnect:        TNotifyEvent;
    FOnServerShutdown:        TNotifyEvent;
    FKeepConnection:          Boolean;
    FConnectionParams:        TMsgClientConnectParamsEditor;
    FOnUserOnLine:            TMsgOnUserOnLine;
    FOnUserOffLine:           TMsgOnUserOffLine;
//    FOnDisconnectUser:        TMsgOnDisconnectUser;
    FStoreMessageHistory:     Boolean;
    FLogged:                  Boolean;
  protected
    procedure DoOnError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer = -1;
                       const ErrorMessage: AnsiString = ''
                       ); override;
    function SendWithProgress(ToUserID: Cardinal;
                                        ObjectType: TMsgMessageType;
                                        const FileName: AnsiString;
                                        Stream: TStream;
                                        Blocks: Integer;
                                        BlockSize: Integer;
                                        Directly: Boolean): Integer; override;
  public
    function PrepareToSendMessage(
                                  var ToID, ToUserID: Cardinal;
                                  var Directly: Boolean;
                                  var ClientSession: TMsgClientSession
                                  ): Integer;
  protected
    function NeedToResendMessage(
                                  ToID, ToUserID: Cardinal;
                                  Directly: Boolean;
                                  Error: Integer
                                  ): Boolean;
    procedure SetLogged(value: Boolean);
    function SessionsCount: Integer;
    procedure CheckConnected;
    procedure CheckDisconnected;
    // db connected?
    function GetConnected: Boolean;
    // keeps connection
    procedure SetKeepConnection(Value: Boolean);
    // connect / disconnect
    procedure SetActive(value: boolean);
    procedure SetConnected(value: boolean);
    function GetContact(Index: Integer): TMsgContactInfo;
    function GetContactCount: Integer;
    procedure ChangeUserStatus(const UserID: Cardinal; const Status: TMsgUserStatus);
    // for commands
    function FindSessionWithUser(UserID: Cardinal): TMsgClientSession;
    function FindSession(ToUserID: Cardinal; var Directly: Boolean): TMsgClientSession;
    // sends notification
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetUserID(Value: Cardinal);
    function CreateDirectSession(UserID: Cardinal; Host: AnsiString; Port: Integer): TMsgClientSession;
  public
    FDefaultSession:          TMsgClientSession;
    FDefaultServerSession:    TMsgClientSession;
  public
    // constructor
    constructor Create(AOwner: TComponent); override;
    // destructor
    destructor Destroy; override;
(*****************************************************************************)
(*  COMMANDS                                                                 *)
(*****************************************************************************)
    // connect this client to server
    procedure Connect;
    // connect this client to another client directly
    procedure ConnectDirectly(UserID: Cardinal; Host: AnsiString = ''; Port: Integer = 0);
    // disconnect this client from server
    procedure Disconnect;
    // disconnect another client connected directly
    procedure DisconnectDirectly(UserID: Cardinal);
    // disconnect this client from all servers and users
    procedure DisconnectAll;
    // server disconnected client session
    procedure OnDisconnect(Session: TMsgClientSession);
     // Login on the server
    function Logon(GetContactList: Boolean = True): Integer;
    // Logoff
    function Logoff: Integer;
    // determine if user is already registered at server
    function IsUserExisting(UserID: Cardinal): Integer;
    // determine if user is on-line now
    function IsUserOnLine(UserID: Cardinal): Integer;
    // return MSG_COMMAND_OK and UserInfo if user exists, otherwise return error code
    function GetUserInfo(UserID: Cardinal; var UserInfo: TMsgUserInfo): Integer;
    // register new user at server
    function RegisterNewUser(var UserInfo: TMsgUserInfo; Password: AnsiString = ''; Logon: Boolean = True): Integer;
    // change user details
    function UpdateUserInfo(var UserInfo: TMsgUserInfo; ChangePassword: Boolean; Password: AnsiString = ''): Integer;
    // add user to Contacts list of this client
    function AddUserToContacts(
                               UserID:            Cardinal;
                               ContactNameSource: TMsgContactNameSource = mcnsUserName;
                               ContactCustomName: AnsiString = ''
                              ): Integer;
    // update user in Contacts list of this client
    function UpdateUserInContacts(
                               UserID:            Cardinal;
                               ContactNameSource: TMsgContactNameSource = mcnsUserName;
                               ContactCustomName: AnsiString = ''
                              ): Integer;
    // remove user from Contacts list of this client
    function RemoveUserFromContacts(UserID: Cardinal): Integer;
    // get list of Contacts of this client
    function GetContacts: Integer;
    // search for UserID by the UserName.
    function FindUserID(const UserName: AnsiString; out UserID: Cardinal): Integer;
    // returns error code and fill Users if no error
    function FindUsers(
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
                       ): Integer;
    // returns error code and fill Users if no error
    function FindUsersCPP(
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
// C++ Builder linker bug - does not work SortBy  even with Byte, int, bool
//                    SortBy:                       TMsgUserInfoArraySortBy = msgusbNone;
                    x:                            Integer = Integer(msgusbNone);
                    Ascending:                    Boolean = True;
                    OrderByClause:                AnsiString = ''
                       ): Integer;
    // returns error code and fill ResultDataset if no error
    function FindMessages(
                         out ResultDataset:                 TDataset;
                         // if true - search in local history, otherwise - in server History
                         UseLocalHistory:                   Boolean;
                         var MessageTextComparison:         TMsgTextComparison;
                         var MessageUnicodeTextComparison:  TMsgTextComparison;
                         var SendingDate:                   TMsgDateComparison;
                         var DeliveryDate:                  TMsgDateComparison;
                         SearchDelivered:                   Boolean;
                         Delivered:                         Boolean = True;
                         MessageText:         AnsiString = ''; // text of the message
                         MessageUnicodeText:  WideString = ''; // unicode text of the message
                         SenderID:            Cardinal = MSG_INVALID_USER_ID;
                         RecipientID:         Cardinal = MSG_INVALID_USER_ID;
                         MessageType:         TMsgMessageType = aamtNone;
                         MessageDataSize:     Integer = -1; // size of MessageData
                         OrderBySendingDate:  Boolean = False;
                         // ORDER BY columns without ORDER BY statement
                         // example: SenderID DESC, SendingDate ASC
                         OrderByClause:       AnsiString = '';
                         Command:             Cardinal = 0 // no condition on command field if TMsgMessageType = aamtNone
                         ): Integer;
(*****************************************************************************)
    // receive custom message from server and call defined event
    procedure ReceiveMessage(Session: TMsgClientSession; Buffer: PAnsiChar; Size: Integer);
// send message to multiple addresses
    function SendMessageMultiple(ToUserIDs: TMsgIntegerArray; const Text: AnsiString;
                                 var Results: TMsgIntegerArray;
                                 Directly: Boolean = True): Integer; overload;
    {$IFDEF D6H}
    function SendMessageMultiple(ToUserIDs: TMsgIntegerArray; const Text: WideString;
                                 var Results: TMsgIntegerArray;
                                 Directly: Boolean = True): Integer; overload;
    {$ELSE}
    function SendMessageMultipleW(ToUserIDs: TMsgIntegerArray; const Text: WideString;
                                 var Results: TMsgIntegerArray;
                                 Directly: Boolean = True): Integer; overload;
    {$ENDIF}
    function SendMessageMultiple(ToUserIDs: TMsgIntegerArray; Buffer: PAnsiChar; Size: Integer;
                                 var Results: TMsgIntegerArray;
                                 Directly: Boolean = True): Integer; overload;
    function SendMessageMultiple(ToUserIDs: TMsgIntegerArray; Stream: TStream;
                                 var Results: TMsgIntegerArray;
                                 Directly: Boolean = True): Integer; overload;
// send message
    // send ANSI message
    function SendMessage(ToUserID: Cardinal; const Text: AnsiString;
                                        Directly: Boolean = True): Integer; overload;
    {$IFDEF D6H}
    // send unicode message
    function SendMessage(ToUserID: Cardinal; const Text: WideString;
                                        Directly: Boolean = True): Integer; overload;
    {$ELSE}
    // send unicode message
    function SendMessageW(ToUserID: Cardinal; const Text: WideString;
                                        Directly: Boolean = True): Integer; overload;
    {$ENDIF}
    function SendMessage(ToUserID: Cardinal; Buffer: PAnsiChar; Size: Integer;
                                        Directly: Boolean = True;
                                        MessageType: TMsgMessageType = aamtBinary
                                                          ): Integer; overload;
    function SendMessage(ToUserID: Cardinal; Stream: TStream;
                                        Directly: Boolean = True): Integer; overload;
    // send command
    function SendCommand(
                                Command: Cardinal;
                                Buffer: PAnsiChar;
                                Size: Integer
                                       ): Integer;
//    property KeepConnection: Boolean read FKeepConnection write SetKeepConnection default True;
  public
    property Contacts[Index: Integer]: TMsgContactInfo read GetContact;
    property ContactCount: Integer read GetContactCount;
  published
    property UserID: Cardinal read FUserID write SetUserID;
    property StoreMessageHistory: Boolean read FStoreMessageHistory write FStoreMessageHistory;
    property Password: AnsiString read FPassword write FPassword;
    property Active: Boolean read FActive write SetActive default False;
    property AllowDirectly: Boolean read FAllowDirectly write FAllowDirectly default True;
    property Connected: Boolean read GetConnected write SetConnected default False;
    property ConnectedDirectly: Boolean read FConnectedDirectly;
    property Logged: Boolean read FLogged write SetLogged;
    property ConnectionParams: TMsgClientConnectParamsEditor read FConnectionParams write FConnectionParams;
    property Database: TMsgDatabase read FDatabase write FDatabase;
    property TempTable: TMsgTempTable read FTempTable write FTempTable;

    property OnUserOnLine: TMsgOnUserOnLine read FOnUserOnLine write FOnUserOnLine;
    property OnUserOffLine: TMsgOnUserOffLine read FOnUserOffLine write FOnUserOffLine;

    property AfterConnect: TNotifyEvent read FAfterConnect write FAfterConnect;
    property BeforeConnect: TNotifyEvent read FBeforeConnect write FBeforeConnect;
    property AfterDisconnect: TNotifyEvent read FAfterDisconnect write FAfterDisconnect;
    property BeforeDisconnect: TNotifyEvent read FBeforeDisconnect write FBeforeDisconnect;
    property AfterLogon: TNotifyEvent read FAfterLogon write FAfterLogon;
    property BeforeLogon: TNotifyEvent read FBeforeLogon write FBeforeLogon;
    property AfterLogoff: TNotifyEvent read FAfterLogoff write FAfterLogoff;
    property BeforeLogoff: TNotifyEvent read FBeforeLogoff write FBeforeLogoff;
    property OnServerShutdown: TNotifyEvent read FOnServerShutdown write FOnServerShutdown;
    property AfterActive: TNotifyEvent read FAfterActive write FAfterActive;
    property BeforeActive: TNotifyEvent read FBeforeActive write FBeforeActive;
 end; // TMsgClient


////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientSession
//
////////////////////////////////////////////////////////////////////////////////

  TMsgOnClientUserOnLine = procedure (UserID: AnsiString) of object;
  TMsgOnClientUserOffLine = procedure (UserID: AnsiString) of object;

  TMsgOnClientDisconnectUser = procedure of object;

  TMsgOnClientReceiveMessage = procedure (Session: TMsgClientSession; Buffer: PAnsiChar; Size: Integer) of object;
// For future extensions
//  TMsgOnClientReceiveCommand = procedure (Buffer: PAnsiChar; Size: Integer) of object;

  TMsgClientSession = class (TMsgNetworkSession)
   private
    FDirect:                    Boolean;
    FRemoteUser:                PMsgUserInfo;
    FOnReceiveMessage:          TMsgOnClientReceiveMessage;
// For future extensions
//    FOnReceiveCommand:          TMsgOnClientReceiveCommand;
(*
    FOnUserOnLine:              TMsgOnClientUserOnLine;
    FOnUserOffLine:             TMsgOnClientUserOffLine;
*)
//    FOnDisconnectUser:          TMsgOnClientDisconnectUser;
    FAfterConnect:            TNotifyEvent;
    FAfterDisconnect:         TNotifyEvent;
    FBeforeConnect:           TNotifyEvent;
    FBeforeDisconnect:        TNotifyEvent;
    FOnServerShutdown:        TNotifyEvent;
   protected
    procedure SetConnected(value: boolean); override;
    procedure SetLogged(value: boolean); override;
    function GetMyUserID: Cardinal;
    function InitProgressSend(ObjectType: TMsgMessageType;
                              ToUserID: Cardinal;
                              const FileName: AnsiString;
                              FullSize: Int64;
                              Blocks: Integer;
                              BlockSize: Integer;
                              var ObjectID: Cardinal
                              ): Integer; override;
   public
    // constructor
    constructor Create(AOwner: TComponent);
    // destructor
    destructor Destroy; override;
    // call OnError event handler
    procedure DoOnError(ErrorCode: Integer; NativeError: Integer = -1; ErrorMessage: AnsiString = ''); override;
    procedure DoCloseSessionOnNetworkError; override;
(*****************************************************************************)
(*  COMMANDS to send                                                         *)
(*****************************************************************************)
    // connect this client to server
    procedure Connect;
    // connect this client to another one directly
    procedure ConnectDirectly;
    // disconnect this client from server
    procedure Disconnect;
    // Login on the server
    function Logon: Integer;
    // Logoff
    function Logoff: Integer;
    // return MSG_COMMAND_OK and UserInfo if user exists, otherwise return error code
    function GetUserInfo(UserID: Cardinal; var UserInfo: TMsgUserInfo): Integer;
    // get list of Contacts of this client from server
    function GetContacts(var Contacts: TMsgContactInfoArray): Integer;
    // determine if user is already registered at server
    function IsUserExisting(UserID: Cardinal): Integer;
    // determine if user is on-line now
    function IsUserOnLine(UserID: Cardinal): Integer;
    // register new user at server
    function RegisterNewUser(var UserInfo: TMsgUserInfo; Password: ShortString = ''; Logon: Boolean = True): Integer;
    // update user details
    function UpdateUserInfo(var UserInfo: TMsgUserInfo; ChangePassword: Boolean; Password: ShortString = ''): Integer;
    // add user to Contacts list of this client
    function AddUserToContacts(
                               UserID:            Cardinal;
                               var UserInfo:      TMsgUserInfo;
                               ContactNameSource: TMsgContactNameSource;
                               ContactCustomName: ShortString
                              ): Integer;
    // update user in Contacts list of this client
    function UpdateUserInContacts(
                               UserID:            Cardinal;
                               ContactNameSource: TMsgContactNameSource;
                               ContactCustomName: ShortString
                              ): Integer;
    // remove user from Contacts list of this client
    function RemoveUserFromContacts(UserID: Cardinal): Integer;
    // search for UserID by the UserName.
    function FindUserID(const UserName: ShortString; out UserID: Cardinal): Integer;
    function FindUsers(
                        var Users: TMsgUserInfoArray;
                        Stream:    TMsgMemoryStream
                       ): Integer;
    function FindMessages(
                        Stream:   TMsgMemoryStream;
                        out       ResultDataset: TDataset
                       ): Integer;
    function SendCommand(
                                Command: TMsgMessageType;
                                Buffer: PAnsiChar;
                                Size: Integer
                                        ): Integer;
(*****************************************************************************)
(*  COMMANDS to execute                                                      *)
(*****************************************************************************)
   protected
    function OnLineUser(UserID: Cardinal): Boolean;
    function OffLineUser(UserID: Cardinal): Boolean;
   public
    // connect user to this client
    function ConnectUser(UserID: Cardinal; Host: AnsiString; Port: Integer):
                                                   TMsgComBaseSession; override;
    function ConnectedUser(UserID: Cardinal; Host: AnsiString; Port: Integer): Boolean; override;
    // disconnect user from this client
    function DisconnectUser(UserID: Cardinal): Boolean;
    // send buffer with command in it via established connection using connection manager
    procedure SendBuffer(Buffer: PAnsiChar; BufferSize: Integer; Code: Integer = MsgNewRequest); override;
    // receive command answer
    procedure ReceiveData(var Buffer: PAnsiChar; var BufferSize: Integer); override;
    // execute received command
    procedure ExecuteReceivedCommand(var Buffer: PAnsiChar; BufferSize: Integer);
    // commands:
    procedure ExecuteInitProgressRecv(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
(*****************************************************************************)
//    function ConnectedUserMake(UserID: Cardinal; Host: AnsiString; Port: Integer): Boolean;
    procedure ChangeStatus(UserID: Cardinal; NewStatus: TMsgUserStatus);
//   public
//    procedure OnDisconnect; override;
   protected
    // send custom message
    procedure SendMessage(Buffer: PAnsiChar; BufferSize: Integer);
   public
    // receive custom message
    procedure ReceiveMessage(Buffer: PAnsiChar; BufferSize: Integer); override;
    procedure OnDisconnect; 
   public
    property Direct: Boolean read FDirect write FDirect; // Received from Sessons
    property RemoteUser: PMsgUserInfo read FRemoteUser write FRemoteUser; // Received from Sessons
   public
    property OnReceiveMessage: TMsgOnClientReceiveMessage read FOnReceiveMessage write FOnReceiveMessage;
// For future extensions
//    property OnReceiveCommand: TMsgOnClientReceiveCommand read FOnReceiveCommand write FOnReceiveCommand;
//    property OnDisconnectUser: TMsgOnClientDisconnectUser read FOnDisconnectUser write FOnDisconnectUser;
(*
    property OnUserOnLine: TMsgOnClientUserOnLine read FOnUserOnLine write FOnUserOnLine;
    property OnUserOffLine: TMsgOnClientUserOffLine read FOnUserOffLine write FOnUserOffLine;
*)
    property AfterConnect: TNotifyEvent read FAfterConnect write FAfterConnect;
    property BeforeConnect: TNotifyEvent read FBeforeConnect write FBeforeConnect;
    property AfterDisconnect: TNotifyEvent read FAfterDisconnect write FAfterDisconnect;
    property BeforeDisconnect: TNotifyEvent read FBeforeDisconnect write FBeforeDisconnect;
    property OnServerShutdown: TNotifyEvent read FOnServerShutdown write FOnServerShutdown;
  end; // TMsgClientSession



////////////////////////////////////////////////////////////////////////////////
//
// TMsgShowMessageThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgShowMessageThread = class(TMsgThread)
  private
    FText:            AnsiString;
  protected
    procedure Execute; override;
  public
    constructor Create(str: AnsiString);
    destructor Destroy; override;
  public
  end; // TMsgShowMessageThread



var
  ClientConnectionManager:  TMsgClientConnectionManager;
  CSect:                    TRTLCriticalSection;

implementation

uses
  Math
 {$IFDEF TRIAL_VERSION}
  , MsgCommunicator
 {$ENDIF}
  ;

var
  FCSect:                TRTLCriticalSection;
  Initialized:           Boolean;
  IsDesignMode:          Boolean;



////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgClientNetworkSettingsEditor.Create;
begin
  inherited Create;
  FConnectRetryCount := MsgConnectRetryCount;
  FConnectDelay := MsgConnectDelay;
  FUseServerSettings := True;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgClientNetworkSettingsEditor.Destroy;
begin
  inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TMsgClientNetworkSettingsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TMsgClientNetworkSettingsEditor) then
    begin
      inherited Assign(Source);
      FConnectRetryCount := TMsgClientNetworkSettingsEditor(Source).ConnectRetryCount;
      FConnectDelay := TMsgClientNetworkSettingsEditor(Source).ConnectDelay;
      FUseServerSettings := TMsgClientNetworkSettingsEditor(Source).UseServerSettings;
    end;
end; // Assign


//------------------------------------------------------------------------------
// Copy ClientNetwork settings to ConnectParams
//------------------------------------------------------------------------------
procedure TMsgClientNetworkSettingsEditor.CopySettingsToConnectParams(var ConnectParams: TMsgConnectParams);
begin
  inherited CopySettingsToConnectParams(ConnectParams);
  ConnectParams.ConnectRetryCount := FConnectRetryCount;
  ConnectParams.ConnectDelay := FConnectDelay;
  ConnectParams.UseServerSettings := FUseServerSettings;
end; // CopySettingsToConnectParams


//------------------------------------------------------------------------------
// SetDefaultSettings
//------------------------------------------------------------------------------
procedure TMsgClientNetworkSettingsEditor.SetDefaultSettings(Value: TMsgDefaultNetworkSettings);
begin
  if Value = RestoreDefaultSettings then
    Exit;
  case Value of
   msgLocal:
    begin
     FConnectRetryCount := MsgLocalConnectRetryCount;
     FConnectDelay := MsgLocalConnectDelay;
     FResendDelay := MsgLocalResendDelay;
     FRequestDelay := MsgLocalRequestDelay;
    end;
   msgLAN:
    begin
     FConnectRetryCount := MsgConnectRetryCount;
     FConnectDelay := MsgConnectDelay;
     FResendDelay := MsgResendDelay;
     FRequestDelay := MsgRequestDelay;
    end;
   msgWAN:
    begin
     FConnectRetryCount := MsgWANConnectRetryCount;
     FConnectDelay := MsgWANConnectDelay;
     FResendDelay := MsgWANResendDelay;
     FRequestDelay := MsgWANRequestDelay;
    end;
   msgModem:
    begin
     FConnectRetryCount := MsgModemConnectRetryCount;
     FConnectDelay := MsgConnectDelay;
     FResendDelay := MsgResendDelay;
     FRequestDelay := MsgRequestDelay;
    end;
  end;
  inherited SetDefaultSettings(Value);
end; // SetDefaultSettings



////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientConnectParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TMsgClientConnectParamsEditor.Create;
begin
  inherited;
  LocalPort := MsgDefaultClientPort;
  FServerID := MsgDefaultServerID;
  FRemoteHost := MsgDefaultHost;
  FRemotePort := MsgDefaultServerPort;
  FCompressionAlgorithm := caNone;
  FCompressionMode := 1;
  FNetworkSettings := TMsgClientNetworkSettingsEditor.Create;
end;//Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgClientConnectParamsEditor.Destroy;
begin
  FNetworkSettings.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TMsgClientConnectParamsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TMsgConnectionParamsEditor) then
    begin
     inherited Assign(Source);
     FServerID := TMsgClientConnectParamsEditor(Source).ServerID;
     FRemoteHost := TMsgClientConnectParamsEditor(Source).RemoteHost;
     FRemotePort := TMsgClientConnectParamsEditor(Source).RemotePort;
     FCompressionAlgorithm := TMsgClientConnectParamsEditor(Source).CompressionAlgorithm;
     FCompressionMode := TMsgClientConnectParamsEditor(Source).CompressionMode;
     FNetworkSettings.Assign(TMsgClientConnectParamsEditor(Source).NetworkSettings);
    end;
end; // Assign


//------------------------------------------------------------------------------
// return ConnectParams
//------------------------------------------------------------------------------
function TMsgClientConnectParamsEditor.GetConnectParams: TMsgConnectParams;
begin
  Result := inherited GetConnectParams;
  Result.CompressionAlgorithm := Byte(FCompressionAlgorithm);
  Result.CompressionMode := FCompressionMode;
  Result.RemoteHost := FRemoteHost;
  Result.RemotePort := FRemotePort;
  Result.ServerID := FServerID;
  FNetworkSettings.CopySettingsToConnectParams(Result);
end; // GetConnectParams


////////////////////////////////////////////////////////////////////////////////
//
//  TMsgClient
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// do on error
//------------------------------------------------------------------------------
procedure TMsgClient.DoOnError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer = -1;
                       const ErrorMessage: AnsiString = ''
                                 );
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error in client component:');
{$ENDIF}
  inherited DoOnError(ErrorCode,NativeError,ErrorMessage);
end; // DoOnError


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TMsgClient.Create(AOwner: TComponent);
begin
  FStoreMessageHistory := True;
  FConnected := False;
  FLogged := False;
  FPassword := '';
  SetLength(FContacts,0);
  FConnectedDirectly := False;
  FActive := False;
  AllowDirectly := True;
  
  FUserID := MSG_INVALID_USER_ID;
  FKeepConnection:=True;
  if (not IsDesignMode) then
   if (Aowner <> nil) then
    if (csDesigning in AOwner.ComponentState) then
     IsDesignMode := true;
// create ConnectionParams Editor
  FConnectionParams := TMsgClientConnectParamsEditor.Create;
// create Lists
  FSessions := TMsgThreadList.Create;
  FDefaultSession := nil;
  FDefaultServerSession := nil;
  FSendThread := nil;
  inherited;
  FIncomingPath := ExtractFilePath(ParamStr(0));
  FIncomingPath :=  FIncomingPath + 'Incoming' + FSslash;
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TMsgClient.Destroy;
var
  List:             TMsgList;
  Session:          TMsgComBaseSession;
  i:                Integer;
begin
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> START');
{$ENDIF}
  if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> Active := False...');
{$ENDIF}
  Active := False;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> DisconnectAll...');
{$ENDIF}
  DisconnectAll;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> AllowFiles := False...');
{$ENDIF}
  AllowFiles := False;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> free sessions...');
{$ENDIF}
  List:=FSessions.LockList;
  try
   for i:=List.Count-1 downto 0 do
    begin
     Session := List.Items[i];
     if Session <> nil then
       Session.Free;
    end;
  finally
   FSessions.UnLockList;
  end;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> FConnectionParams.Free...');
{$ENDIF}
  FConnectionParams.Free;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> FContacts...');
{$ENDIF}
  SetLength(FContacts,0);
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> FSessions.Free...');
{$ENDIF}
  FSessions.Free;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> inherited...');
{$ENDIF}
  inherited;
{$IFDEF LOG_CLIENT_MANAGER_DESTROY}
aaWriteToLog('TMsgClient.Destroy> FINISH');
{$ENDIF}
end; // Destroy


//------------------------------------------------------------------------------
// SetUserID
//------------------------------------------------------------------------------
procedure TMsgClient.SetUserID(Value: Cardinal);
begin
  if (FUserID = Value) or (Active) or (Logged) then
    Exit;
  FUserID := Value;
end; // SetUserID


//------------------------------------------------------------------------------
// connect to server
//------------------------------------------------------------------------------
procedure TMsgClient.Connect;
var
  bCatchException:  Boolean;
begin
  bCatchException := False;
{$IFDEF D6H}
  // fix: to enable open forms with incorrect properties
  if (csDesigning in ComponentState)
     and (not (csFreeNotification in ComponentState)) then
    bCatchException := True;
{$ENDIF}
 try
  EnterCSect(CSect);
  if ClientConnectionManager = nil then
    ClientConnectionManager := TMsgClientConnectionManager.Create;
  LeaveCSect(CSect);
  if (FDatabase <> nil) then
   Database.OpenOrCreateDatabase(True);
  if (FDefaultServerSession = nil) then
   begin
    // create default session
    FDefaultServerSession := TMsgClientSession.Create(Self);
    TMsgClientSession(FDefaultServerSession).OnReceiveMessage := ReceiveMessage;
    FSessions.Add(FDefaultServerSession);
   end;
  if (not (FDefaultServerSession.Connected)) then
   begin
    if Assigned(BeforeConnect) then
     BeforeConnect(Self);
     try
      FDefaultServerSession.Connect;
     finally
      FConnected := FDefaultServerSession.Connected;
      FUserID := FDefaultServerSession.FUserID;
      if Connected then
        ConnectionParams.LocalPort := FDefaultServerSession.ConnectParams.LocalPort;
      if Logged then
        GetContacts;
      if (AllowDirectly and Connected and Logged) then // must be logged to enable direct connections
        Active := True;
     end;
    if Assigned(AfterConnect) then
     AfterConnect(Self);
   end;
 except
   on e: Exception do
    if (csDesigning in ComponentState) then
      MessageDlg(e.Message,mtError,[mbOK],0)
    else
     if (not bCatchException) then
       raise;
 end;
end; // Connect


//------------------------------------------------------------------------------
// CreateDirectSession
//------------------------------------------------------------------------------
function TMsgClient.CreateDirectSession(UserID: Cardinal; Host: AnsiString; Port: Integer): TMsgClientSession;
var
    i:                Integer;
    UserInfo:         TMsgUserInfo;
    p:                PMsgUserInfo;
begin
  Result := TMsgClientSession.Create(Self);
  try
    Result.Direct := True;
    Result.FConnectParams.UseServerSettings := False;
    Result.OnReceiveMessage := ReceiveMessage;
    FSessions.Add(Result);
    Result.FConnectParams.ServerID := UserID; //MSG_INVALID_USER_ID;
    New(p);
    Result.RemoteUser := p;
    if (Host = '')
    or (Port = 0)
    then
     begin
      if not Connected then
        raise EMsgException.Create(40068, ErrorRNoServerConnection, [UserID, Host, Port]);
      i := GetUserInfo(UserID,UserInfo);
      if (i = MSG_Error_GetUserInfo_UserDoesNotExist) then
        raise EMsgException.Create(11471, ErrorLUserDoesNotExist, [UserID]);
      if (i <> MSG_COMMAND_OK) then
        raise EMsgException.Create(11472, ErrorLCannotGetUserInfo, [UserID,i]);
      if (UserInfo.Status = msgOffLine) then
        raise EMsgException.Create(11473, ErrorRNoServerConnection, [UserID, Host, Port]);
      Result.FConnectParams.RemoteHost := UserInfo.Host;
      Result.FConnectParams.RemotePort := UserInfo.Port;
      UserInfo.Status := msgConnecting;
      Result.RemoteUser^ := UserInfo;
{
      Contacts := TMsgList.Create;
      GetMyContactsList(Contacts);
      for i:=0 to Contacts.Count do
       begin
        pUserInfo := Contacts[i];
        if pUserInfo.UserID = UserID then
         begin
          if pUserInfo.Status = msgOffLine then
            raise EMsgException.Create(40068, ErrorRNoServerConnection, [UserID, Host, Port]);
          if (pUserInfo.Port=0)
          or (pUserInfo.Host='')
          then
           begin
            UserInfo := GetUserInfo(UserID,ErrorCode);
            pUserInfo.Host := UserInfo.Host;
            pUserInfo.Port := UserInfo.Port;
           end;
          Result.FConnectParams.RemoteHost := pUserInfo.Host;
          Result.FConnectParams.RemotePort := pUserInfo.Port;
          pUserInfo.Status := msgConnecting;
          Result.RemoteUser := pUserInfo^;
          break;
         end;
       end;
      Contacts.Free;
}
     end
    else
     begin
      Result.FConnectParams.RemoteHost := Host;
      Result.FConnectParams.RemotePort := Port;
      if Connected then
        GetUserInfo(UserID,UserInfo);
      UserInfo.UserID := UserID;
      UserInfo.Host := Host;
      UserInfo.Port := Port;
      UserInfo.Status := msgConnecting;
      Result.RemoteUser^ := UserInfo;
     end;
  except
    Result.Free;
    raise;
  end;
end;  // CreateDirectSession


//------------------------------------------------------------------------------
// connect to other client directly
//------------------------------------------------------------------------------
procedure TMsgClient.ConnectDirectly(UserID: Cardinal; Host: AnsiString = ''; Port: Integer = 0);
var
  Session:          TMsgClientSession;
  bCatchException:  Boolean;
  Error:            AnsiString;
begin
  bCatchException := False;
{$IFDEF D6H}
  // fix: to enable open forms with incorrect properties
  if (csDesigning in ComponentState)
     and (not (csFreeNotification in ComponentState)) then
    bCatchException := True;
{$ENDIF}
  Error := Format(ErrorLCannotConnectDirectly,[UserID,Host,Port]);
  if Active then
   begin
    try
     Session := FindSessionWithUser(UserID);
     if (Session = nil)
//  or (not Session.Direct)
     then
       Session := CreateDirectSession(UserID, Host, Port);
     Session.ConnectDirectly;
     if Session.Connected then
      begin
       Session.FRemoteUser.Status := msgConnected;
       FConnectedDirectly := True;
      end;
    except
     on e: EMsgException do
      begin
       DoOnError(MSG_Error_CannotConnectDirectly,e.NativeError,Error+' '+e.Message);
       if (csDesigning in ComponentState) then
        MessageDlg(Error,mtError,[mbOK],0)
       else
       if (not bCatchException) then
         raise;
     end
     else
      begin
       DoOnError(MSG_Error_CannotConnectDirectly,-1,Error);
       if (csDesigning in ComponentState) then
        MessageDlg(Error,mtError,[mbOK],0)
       else
       if (not bCatchException) then
         raise;
      end;
    end;
  end;
end; // ConnectDirectly


//------------------------------------------------------------------------------
// disconnect from server
//------------------------------------------------------------------------------
procedure TMsgClient.Disconnect;
begin
  if Connected then
   begin
    if Assigned(BeforeDisconnect) then
      BeforeDisconnect(Self);
    try
      ClientConnectionManager.Disconnect(FDefaultServerSession);
    except
    end;
    FDefaultServerSession.FConnected := False;
    FConnected := False;
    FDefaultServerSession.FLogged := False;
    FLogged := False;
    if Assigned(AfterDisconnect) then
      AfterDisconnect(Self);
   end;
end; // Disconnect


//------------------------------------------------------------------------------
// disconnect user
//------------------------------------------------------------------------------
procedure TMsgClient.DisconnectDirectly(UserID: Cardinal);
var
  Session:          TMsgClientSession;
begin
  try
  Session := FindSessionWithUser(UserID);
  if (Session <> nil) then
    Session.Free;
  except
  end;
end; // Disconnect


//------------------------------------------------------------------------------
// disconnect this client from all servers
//------------------------------------------------------------------------------
procedure TMsgClient.DisconnectAll;
var
  Sessions:         TMsgList;
  Session:          TMsgClientSession;
  i:                Integer;
  Error:            AnsiString;
begin
  if Assigned(BeforeDisconnect) then
    BeforeDisconnect(Self);
  Sessions:=FSessions.LockList;
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
     Session := Sessions.Items[i];
     if Session.Connected then
      begin
       try
        if (Session = FDefaultServerSession) then
         Error := Format(ErrorLClientCannotDisconnectSessionWithServer,[ConnectionParams.ServerID])
        else
         Error := Format(ErrorLClientCannotDisconnectSessionWithUser,[Session.UserID]);
        if Session <> FDefaultSession then // Do not stop active listener
         begin
          Session.FConnected := False;
          ClientConnectionManager.Disconnect(Session);
         end;
       except
         on e: EMsgException do
          DoOnError(MSG_Error_ClientCannotDisconnectSession,e.NativeError,Error+' '+e.Message);
         else
          DoOnError(MSG_Error_ClientCannotDisconnectSession,-1,Error);
       end;
      end;
    end;
  finally
   FSessions.UnLockList;
   FLogged := False;
   FConnected := False;
   FConnectedDirectly := False;
   if Assigned(AfterDisconnect) then
    AfterDisconnect(Self);
  end;
end; // DisconnectAll


//------------------------------------------------------------------------------
// Logon
//------------------------------------------------------------------------------
function TMsgClient.Logon(GetContactList: Boolean = True): Integer;
begin
  Result := MSG_Error_Logon_NotConnected;
  if (not Connected) then
   Exit;
  Result := FDefaultServerSession.Logon;
  SetLength(FContacts,0);
  if Logged then
   begin
    if AllowDirectly then
      if not Active then
        Active := True;
    if (GetContactList) then
      GetContacts;
   end;
end; // Logon


//------------------------------------------------------------------------------
// Logoff
//------------------------------------------------------------------------------
function TMsgClient.Logoff: Integer;
begin
  Result := FDefaultServerSession.Logoff;
  if Active then
    if not Logged then
      Active := False;
end; // Logoff


//------------------------------------------------------------------------------
// FindSessionWithUser
//------------------------------------------------------------------------------
function TMsgClient.FindSessionWithUser(UserID: Cardinal): TMsgClientSession;
var
  Sessions:         TMsgList;
  Session:          TMsgClientSession;
  i:                Integer;
begin
  Result := nil;
  Sessions:=FSessions.LockList;
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
     Session := Sessions.Items[i];
     if Session.Direct then
      if Session.RemoteUser <> nil then
       if Session.RemoteUser.UserID = UserID then
        begin
         Result := Session;
         Exit;
        end;
    end;
  finally
   FSessions.UnlockList;
  end;
end; // FindSessionWithUser


//------------------------------------------------------------------------------
// FindSession
//------------------------------------------------------------------------------
function TMsgClient.FindSession(ToUserID: Cardinal; var Directly: Boolean): TMsgClientSession;
var
  i:                Integer;
  Contacts:         TMsgList;
  IsOnLine:         Boolean;
  UserInfo:         TMsgUserInfo;
begin
  Result := nil;
  if Directly then
   begin
{
    if ConnectedDirectly then
      IsOnLine := True
    else
     begin
      // is user on-line now?
      IsOnLine := False;
      i := GetUserInfo(ToUserID,UserInfo);
      if (i = MSG_COMMAND_OK) then
       if (UserInfo.Status <> msgOffLine) then
        IsOnline := True;
      if (FDefaultServerSession = nil) then
       begin
        Result := FindSessionWithUser(ToUserID);
        if Result <> nil then
          IsOnLine := True;
       end;
     end;
    if not IsOnLine then // off-line
      Directly := False
    else // on-line
}
    if ToUserID = UserID then
      Directly := False  // added in v.4.20
    else
     begin
      Result := FindSessionWithUser(ToUserID);
      try
       if Result = nil then
        begin
         ConnectDirectly(ToUserID);
         Result := FindSessionWithUser(ToUserID);
        end;
       if Result <> nil then
         Result.Connected := True;
      except
       Directly := False;
       if Result <> nil then
        begin
         Result.Free;
         Result := nil;
        end;
      end;
      if Result = nil then
        Directly := False
      else
       if not Result.Connected then
        begin
         Directly := False;
         Result.Free;
         Result := nil;
        end;
     end;
   end;
  if not Directly then
   begin
    Result := TMsgClientSession(FDefaultServerSession);
    if (Result = nil) then
      raise EMsgException.Create(11251,ErrorLClientIsNotConnected);
    if not Result.Connected then
      EMsgException.Create(40042, ErrorRNotConnected);
   end;
end; // FindSession


//------------------------------------------------------------------------------
// sends notification
//------------------------------------------------------------------------------
procedure TMsgClient.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent,Operation);
{
  if (Operation = opRemove) and (AComponent = FSession) and
     (FSession <> MsgDefaultSession) then
    begin
      Disconnect;
      SessionName := '';
    end;
}
end;// Notification


//------------------------------------------------------------------------------
// SessionsCount
//------------------------------------------------------------------------------
function TMsgClient.SessionsCount: Integer;
var
  Sessions:         TMsgList;
begin
  Sessions:=FSessions.LockList;
  try
   Result := Sessions.Count;
  finally
   FSessions.UnLockList;
  end;
end; // SessionsCount


//------------------------------------------------------------------------------
// keep connection
//------------------------------------------------------------------------------
procedure TMsgClient.SetKeepConnection(Value: Boolean);
begin
  if FKeepConnection <> Value then
   begin
    FKeepConnection := Value;
    if not Value and (SessionsCount = 0) then
      Disconnect;
  end;
end;// SetKeepConnection


//------------------------------------------------------------------------------
// CheckConnected
//------------------------------------------------------------------------------
procedure TMsgClient.CheckConnected;
begin
  if (Connected) then
    EMsgException.Create(40043, ErrorRConnected);
end;// CheckConnected


//------------------------------------------------------------------------------
// CheckDisconnected
//------------------------------------------------------------------------------
procedure TMsgClient.CheckDisconnected;
begin
  if (not Connected) then
    EMsgException.Create(40042, ErrorRNotConnected);
end;// CheckDisconnected


//------------------------------------------------------------------------------
// connect / disconnect
//------------------------------------------------------------------------------
procedure TMsgClient.SetActive(value: boolean);
var
  bCatchException:  Boolean;
  ErrorActivate,Error: AnsiString;
  ErrorDeactivate:     AnsiString;
begin
  if Value = FActive then
    Exit;
  bCatchException := False;
  ErrorActivate := ErrorLClientCannotActivate;
  ErrorDeactivate := ErrorLClientCannotDeactivate;
{$IFDEF D6H}
  // fix: to enable open forms with incorrect properties
  if (csDesigning in ComponentState)
     and (not (csFreeNotification in ComponentState)) then
    bCatchException := True;
{$ENDIF}
 try
  if Assigned(BeforeActive) then
    BeforeActive(Self);
  try
   EnterCSect(CSect);
   if ClientConnectionManager = nil then
     ClientConnectionManager := TMsgClientConnectionManager.Create;
   LeaveCSect(CSect);
   if Value then
     begin
      if (FDefaultSession = nil) then
       begin
        FDefaultSession := TMsgClientSession.Create(Self);
        FSessions.Add(FDefaultSession);
       end;
      FDefaultSession.Direct := True;
  //    TMsgClientSession(FDefaultSession).OnReceiveMessage := ReceiveMessage; // allow sending message to non-connected client - security hole!!!
      FDefaultSession.FUserID := FUserID;
      FDefaultSession.ConnectParams := ConnectionParams.ConnectParams;
      ClientConnectionManager.Connect(FDefaultSession, true);
      ConnectionParams.LocalPort := FDefaultSession.ConnectParams.LocalPort;
      FDefaultSession.FConnected := True;
      if (FDatabase <> nil) then
       Database.OpenOrCreateDatabase(True);
      FActive := True;
     end
    else
     begin
      FActive := False;
      if (FDefaultSession <> nil) then
       begin
        // free default session
        FDefaultSession.FConnected := False;
        FSessions.Remove(FDefaultSession);
        ClientConnectionManager.Disconnect(FDefaultSession, true);
        FDefaultSession.Free;
        FDefaultSession := nil;
       end;
      if (not Connected) then
       if (FDatabase <> nil) then
        FDatabase.CloseDatabase;
     end;
  finally
   if Assigned(AfterActive) then
    AfterActive(Self);
  end;
 except
   on e: EMsgException do
    begin
     if (Value) then
      begin
       Error := ErrorActivate+' '+e.Message;
       DoOnError(MSG_Error_ClientCannotActivate,e.NativeError,Error);
      end
     else
      begin
       Error := ErrorDeactivate+' '+e.Message;
       DoOnError(MSG_Error_ClientCannotDeactivate,e.NativeError,Error);
      end;
     if (csDesigning in ComponentState) then
      MessageDlg(Error,mtError,[mbOK],0)
     else
      if (not bCatchException) then
       raise;
    end
   else
    begin
     if (Value) then
      begin
       Error := ErrorActivate;
       DoOnError(MSG_Error_ClientCannotActivate,-1,Error);
      end
     else
      begin
       Error := ErrorDeactivate;
       DoOnError(MSG_Error_ClientCannotDeactivate,-1,Error);
      end;
     if (csDesigning in ComponentState) then
      MessageDlg(Error,mtError,[mbOK],0)
     else
      if (not bCatchException) then
       raise;
    end;
 end;
end;//SetActive


//------------------------------------------------------------------------------
// db connected?
//------------------------------------------------------------------------------
function TMsgClient.GetConnected: Boolean;
begin
  Result := FConnected; //(FDefaultServerSession <> nil);
end;// GetConnected


//------------------------------------------------------------------------------
// connect / disconnect
//------------------------------------------------------------------------------
procedure TMsgClient.SetConnected(value: boolean);
begin
  if Value = FConnected then
    Exit;
  if Value then
    Connect
  else
    Disconnect;
end;//SetConnected


//------------------------------------------------------------------------------
// Logged on/off
//------------------------------------------------------------------------------
procedure TMsgClient.SetLogged(value: Boolean);
begin
  if Value = FLogged then
    Exit;
  if Value then
    Logon
  else
    Logoff;
end; // SetLogged

//------------------------------------------------------------------------------
// return contacts
//------------------------------------------------------------------------------
function TMsgClient.GetContact(Index: Integer): TMsgContactInfo;
begin
  if (Index >= 0) and (Index < Length(FContacts)) then
   Result := FContacts[Index]
  else
   begin
    FillChar(Result,SizeOf(Result),$00);
    Result.UserInfo.UserID := MSG_INVALID_USER_ID;
   end;
end; // GetContact


//------------------------------------------------------------------------------
// return contacts
//------------------------------------------------------------------------------
function TMsgClient.GetContactCount: Integer;
begin
  Result := Length(FContacts);
end; // GetContactCount


//------------------------------------------------------------------------------
// change user status
//------------------------------------------------------------------------------
procedure TMsgClient.ChangeUserStatus(const UserID: Cardinal; const Status: TMsgUserStatus);
var i: Integer;
begin
  for i := Low(FContacts) to High(FContacts) do
   if (FContacts[i].UserInfo.UserID = UserID) then
    FContacts[i].UserInfo.Status := Status;
end; // ChangeUserStatus


//------------------------------------------------------------------------------
// OnDisconnect
//------------------------------------------------------------------------------
procedure TMsgClient.OnDisconnect(Session: TMsgClientSession);
var
  Sessions:         TMsgList;
  lSession:         TMsgClientSession;
  i:                Integer;
  DirectFound,
  Found:            Boolean;
begin
// search for connected sessions
  DirectFound := False;
  Found := False;
  Sessions:=FSessions.LockList;
  try
   for i:=Sessions.Count-1 downto 0 do
    begin
     lSession := Sessions.Items[i];
     if lSession.Connected then
      begin
       if not lSession.Direct then
         Found := True
       else
         if lSession.SessionID <> INVALID_SESSION_ID then
           DirectFound := True;
      end;
    end;
  finally
   FSessions.UnlockList;
  end;
  if (not DirectFound) then
    FConnectedDirectly := False;
// update users' status in contact list
  if (Session = FDefaultServerSession) then
    for i:=Length(FContacts)-1 downto 0 do
      if FindSessionWithUser(FContacts[i].UserInfo.UserID) = nil then
        Session.OffLineUser(FContacts[i].UserInfo.UserID);
// event
  if (Session = FDefaultServerSession)
  or (not Found)
  then
   begin
    if Connected then
     begin
      FConnected := False;
      FLogged := False;
      if Assigned(FOnServerShutdown) then
        FOnServerShutdown(Self);
     end;
   end;
end; // OnDisconnect


//------------------------------------------------------------------------------
// determine if user exists at server
//------------------------------------------------------------------------------
function TMsgClient.IsUserExisting(UserID: Cardinal): Integer;
begin
  Result := MSG_Error_IsUserExisting_NotConnected;
  if (Connected) then
   Result := FDefaultServerSession.IsUserExisting(UserID);
end;// IsUserExisting


//------------------------------------------------------------------------------
// determine if user is on-line now
//------------------------------------------------------------------------------
function TMsgClient.IsUserOnLine(UserID: Cardinal): Integer;
begin
  Result := MSG_Error_IsUserOnline_NotLogged;
  if not Logged then
    Exit;
  Result := MSG_Error_IsUserOnline_NotConnected;
  if (Connected) then
   Result := FDefaultServerSession.IsUserOnLine(UserID);
end;// IsUserOnLine


//------------------------------------------------------------------------------
// return MSG_COMMAND_OK and UserInfo if user exists, otherwise return error code
//------------------------------------------------------------------------------
function TMsgClient.GetUserInfo(UserID: Cardinal; var UserInfo: TMsgUserInfo): Integer;
var
  Sessions:         TMsgList;
  Session:          TMsgClientSession;
  i:                Integer;
begin
  Result := MSG_Error_GetUserInfo_NotLogged;
  if not Logged then
    Exit;
  Result := MSG_Error_GetUserInfo_NotConnected;
  if (Connected) then
    Result := FDefaultServerSession.GetUserInfo(UserID,UserInfo)
  else
   begin // Peer-to-Peer
    Result := MSG_Error_GetUserInfo_UserDoesNotExist;
    Sessions:=FSessions.LockList;
    try
     for i:=0 to Sessions.Count-1 do
      begin
       Session := Sessions.Items[i];
       if Session.RemoteUser.UserID = UserID then
        begin
         UserInfo := Session.RemoteUser^;
         Result := MSG_COMMAND_OK;
         break;
        end;
      end;
    finally
     FSessions.UnlockList;
    end;
   end;
end;// GetUserInfo


//------------------------------------------------------------------------------
// register new user at server
//------------------------------------------------------------------------------
function TMsgClient.RegisterNewUser(var UserInfo: TMsgUserInfo; Password: AnsiString = ''; Logon: Boolean = True): Integer;
begin
  Result := MSG_Error_RegisterNewUser_NotConnected;
  if (Connected) then
    Result := FDefaultServerSession.RegisterNewUser(UserInfo,Password,Logon);
end;// RegisterNewUser


//------------------------------------------------------------------------------
// UpdateUserInfo
//------------------------------------------------------------------------------
function TMsgClient.UpdateUserInfo(var UserInfo: TMsgUserInfo; ChangePassword: Boolean; Password: AnsiString): Integer;
begin
  Result := MSG_Error_UpdateUserInfo_NotLogged;
  if not Logged then
    Exit;
  Result := MSG_Error_UpdateUserInfo_NotConnected;
  if (Connected) then
    Result := FDefaultServerSession.UpdateUserInfo(UserInfo,ChangePassword,Password);
end;// UpdateUserInfo


//------------------------------------------------------------------------------
// add user to Contacts list of this client
//------------------------------------------------------------------------------
function TMsgClient.AddUserToContacts(
                               UserID:            Cardinal;
                               ContactNameSource: TMsgContactNameSource;
                               ContactCustomName: AnsiString
                              ): Integer;
var i,n,h:    Integer;
    UserInfo: TMsgUserInfo;
begin
  Result := MSG_Error_AddUserToContacts_NotLogged;
  if not Logged then
    Exit;
  Result := MSG_Error_AddUserToContacts_NotConnected;
  if (Connected) then
    Result := FDefaultServerSession.AddUserToContacts(UserID,UserInfo,ContactNameSource,ContactCustomName);
  if (Result = MSG_COMMAND_OK) then
   begin
    i := Length(FContacts);
    SetLength(FContacts,i+1);
    FContacts[i].UserInfo := UserInfo;
    FContacts[i].ContactNameSource := ContactNameSource;
    FContacts[i].ContactCustomName := ContactCustomName;
   end;
end;// AddUserToContacts


//------------------------------------------------------------------------------
// update user in Contacts list of this client
//------------------------------------------------------------------------------
function TMsgClient.UpdateUserInContacts(
                           UserID:            Cardinal;
                           ContactNameSource: TMsgContactNameSource = mcnsUserName;
                           ContactCustomName: AnsiString = ''
                          ): Integer;
var i,n,h:    Integer;
begin
  Result := MSG_Error_UpdateUserInContacts_NotLogged;
  if not Logged then
    Exit;
  Result := MSG_Error_UpdateUserInContacts_NotConnected;
  if (Connected) then
    Result := FDefaultServerSession.UpdateUserInContacts(UserID,ContactNameSource,ContactCustomName);
  if (Result = MSG_COMMAND_OK) then
   begin
    n := -1;
    h := High(FContacts);
    for i := Low(FContacts) to h do
     if (FContacts[i].UserInfo.UserID = UserID) then
      begin
       n := i;
       break;
      end;
    if (n >= 0) then
     begin
      FContacts[n].ContactNameSource := ContactNameSource;
      FContacts[n].ContactCustomName := ContactCustomName;
     end;
   end;
end; // UpdateUserInContacts


//------------------------------------------------------------------------------
// remove user from Contacts list of this client
//------------------------------------------------------------------------------
function TMsgClient.RemoveUserFromContacts(UserID: Cardinal): Integer;
var i,n,h: Integer;
begin
  Result := MSG_Error_RemoveUserFromContacts_NotLogged;
  if not Logged then
    Exit;
  Result := MSG_Error_RemoveUserFromContacts_NotConnected;
  if (Connected) then
    Result := FDefaultServerSession.RemoveUserFromContacts(UserID);
  if (Result = MSG_COMMAND_OK) then
   begin
    n := -1;
    h := High(FContacts);
    for i := Low(FContacts) to h do
     if (FContacts[i].UserInfo.UserID = UserID) then
      begin
       n := i;
       break;
      end;
    if (n >= 0) then
     begin
      for i := n+1 to h do
       FContacts[i-1] := FContacts[i];
      SetLength(FContacts,h);
     end;
   end;
end;// RemoveUserFromContacts


//------------------------------------------------------------------------------
// get list of Contacts of this client from all servers
//------------------------------------------------------------------------------
function TMsgClient.GetContacts: Integer;
begin
  Result := MSG_Error_GetContacts_NotLoggeed;
  if not Logged then
    Exit;
  Result := MSG_Error_GetContacts_NotConnected;
  if (Connected) then
    Result := FDefaultServerSession.GetContacts(FContacts);
end;// GetContactsList


//------------------------------------------------------------------------------
// search for UserID by the UserName
//------------------------------------------------------------------------------
function TMsgClient.FindUserID(const UserName: AnsiString; out UserID: Cardinal): Integer;
// You must have unique UserNames -- use BeforeUserRegistered to block unwanted registrations.
// UserID = MSG_INVALID_USER_ID in case of not found
begin
  Result := MSG_Error_FindUserID_NotConnected;
  if (Connected) then
   Result := FDefaultServerSession.FindUserID(UserName, UserID);
end; // search for UserID by the UserName


//------------------------------------------------------------------------------
// find users
//------------------------------------------------------------------------------
function TMsgClient.FindUsers(
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
                   ): Integer;
var ms:    TMsgMemoryStream;
    len:   Integer;
    s:     ShortString;
begin
  Result := MSG_Error_FindUsers_NotConnected;
  if (Connected) then
   begin
    ms := TMsgMemoryStream.Create;
    try
      SaveDataToStream(UserNameComparison,SizeOf(UserNameComparison),ms,11403);
      SaveDataToStream(FirstNameComparison,SizeOf(FirstNameComparison),ms,11404);
      SaveDataToStream(LastNameComparison,SizeOf(LastNameComparison),ms,11405);
      SaveDataToStream(OrganizationComparison,SizeOf(OrganizationComparison),ms,11406);
      SaveDataToStream(DepartmentComparison,SizeOf(DepartmentComparison),ms,11407);
      SaveDataToStream(ApplicationComparison,SizeOf(ApplicationComparison),ms,11408);
      SaveDataToStream(HostComparison,SizeOf(HostComparison),ms,11409);
      SaveDataToStream(PortComparison,SizeOf(PortComparison),ms,11410);
      SaveDataToStream(Status,SizeOf(Status),ms,11411);
      SaveDataToStream(UserID,SizeOf(UserID),ms,11412);
      // C++ Builder ShortString bug fix - replaced to AnsiString in v.2.10
      SaveStringToStream(UserName,ms,11413);
      SaveStringToStream(FirstName,ms,11414);
      SaveStringToStream(LastName,ms,11415);
      SaveStringToStream(Organization,ms,11416);
      SaveStringToStream(Department,ms,11417);
      SaveStringToStream(Host,ms,11418);
      SaveStringToStream(Application,ms,11419);
      SaveStringToStream(SearchCondition,ms,11546);
      SaveDataToStream(SortBy,SizeOf(SortBy),ms,11537);
      SaveBooleanToStream(Ascending,ms,11538);
      SaveStringToStream(OrderByClause,ms,11539);
      Result := FDefaultServerSession.FindUsers(Users,ms);
    finally
      ms.Free;
    end;
   end;
end; // FindUsers


//------------------------------------------------------------------------------
// returns error code and fill Users if no error
//------------------------------------------------------------------------------
function TMsgClient.FindUsersCPP(
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
// C++ Builder linker bug - does not work SortBy  even with Byte, int, bool                    
//                    SortBy:                       TMsgUserInfoArraySortBy = msgusbNone;
                    x:                            Integer = Integer(msgusbNone);
                    Ascending:                    Boolean = True;
                    OrderByClause:                AnsiString = ''
                   ): Integer;
var ms:     TMsgMemoryStream;
    len:    Integer;
    s:      ShortString;
    SortBy: TMsgUserInfoArraySortBy;
begin
  SortBy := TMsgUserInfoArraySortBy(Byte(x));
  Result := MSG_Error_FindUsers_NotConnected;
  if (Connected) then
   begin
    ms := TMsgMemoryStream.Create;
    try
      SaveDataToStream(UserNameComparison,SizeOf(UserNameComparison),ms,11403);
      SaveDataToStream(FirstNameComparison,SizeOf(FirstNameComparison),ms,11404);
      SaveDataToStream(LastNameComparison,SizeOf(LastNameComparison),ms,11405);
      SaveDataToStream(OrganizationComparison,SizeOf(OrganizationComparison),ms,11406);
      SaveDataToStream(DepartmentComparison,SizeOf(DepartmentComparison),ms,11407);
      SaveDataToStream(ApplicationComparison,SizeOf(ApplicationComparison),ms,11408);
      SaveDataToStream(HostComparison,SizeOf(HostComparison),ms,11409);
      SaveDataToStream(PortComparison,SizeOf(PortComparison),ms,11410);
      SaveDataToStream(Status,SizeOf(Status),ms,11411);
      SaveDataToStream(UserID,SizeOf(UserID),ms,11412);
      // C++ Builder ShortString bug fix - replaced to AnsiString in v.2.10
      SaveStringToStream(UserName,ms,11413);
      SaveStringToStream(FirstName,ms,11414);
      SaveStringToStream(LastName,ms,11415);
      SaveStringToStream(Organization,ms,11416);
      SaveStringToStream(Department,ms,11417);
      SaveStringToStream(Host,ms,11418);
      SaveStringToStream(Application,ms,11419);
      SaveStringToStream(SearchCondition,ms,11546);
      SaveDataToStream(SortBy,SizeOf(SortBy),ms,11537);
      SaveBooleanToStream(Ascending,ms,11538);
      SaveStringToStream(OrderByClause,ms,11539);
      Result := FDefaultServerSession.FindUsers(Users,ms);
    finally
      ms.Free;
    end;
   end;
end; // FindUsers


//------------------------------------------------------------------------------
// find messages
//------------------------------------------------------------------------------
function TMsgClient.FindMessages(
                       out ResultDataset:                 TDataset;
                       // if true - search in local history, otherwise - in server History
                       UseLocalHistory:                   Boolean;
                       var MessageTextComparison:         TMsgTextComparison;
                       var MessageUnicodeTextComparison:  TMsgTextComparison;
                       var SendingDate:                   TMsgDateComparison;
                       var DeliveryDate:                  TMsgDateComparison;
                       SearchDelivered:                   Boolean;
                       Delivered:                         Boolean = True;
                       MessageText:         AnsiString = ''; // text of the message
                       MessageUnicodeText:  WideString = ''; // unicode text of the message
                       SenderID:            Cardinal = MSG_INVALID_USER_ID;
                       RecipientID:         Cardinal = MSG_INVALID_USER_ID;
                       MessageType:         TMsgMessageType = aamtNone;
                       MessageDataSize:     Integer = -1; // size of MessageData
                       OrderBySendingDate:  Boolean = False;
                       // ORDER BY columns without ORDER BY statement
                       // example: SenderID DESC, SendingDate ASC
                       OrderByClause:       AnsiString = '';
                       Command:             Cardinal = 0 // no condition on command field if TMsgMessageType = aamtNone
                     ): Integer;
var ms:         TMsgMemoryStream;
    Buffer:     PAnsiChar;
    BufferSize: Integer;
begin
  Result := MSG_Error_FindMessages_NotLogged;
  if not Logged then
    Exit;
  if (UseLocalHistory) then
   begin
    if (FDatabase = nil) then
     Result := MSG_Error_FindMessages_Client_DatabaseIsNotAssigned
    else
      try
       Result := MSG_Error_FindMessages_Failed;
       ResultDataset := FDatabase.FindMessages(
                      MessageTextComparison,MessageUnicodeTextComparison,
                      SendingDate,DeliveryDate,SearchDelivered,Delivered,
                      MessageText,MessageUnicodeText,SenderID,RecipientID,
                      MessageType,MessageDataSize,OrderBySendingDate,OrderByClause,Command
                       );
       Result := MSG_COMMAND_OK;
      except
       on e: EMsgException do
        DoOnError(Result,e.NativeError,e.Message);
       on e: Exception do
        DoOnError(Result,-1,e.Message)
       else
        DoOnError(Result);
      end;
   end // local history
  else
   begin
    if (not Connected) then
     Result := MSG_Error_FindMessages_NotConnected
    else
    if (FTempTable = nil) then
     Result := MSG_Error_FindMessages_Client_TempTableIsNotAssigned
    else
     begin
      ms := TMsgMemoryStream.Create;
      try
        SaveDataToStream(MessageTextComparison,SizeOf(MessageTextComparison),ms,11422);
        SaveDataToStream(MessageUnicodeText,SizeOf(MessageUnicodeText),ms,11423);
        SaveDataToStream(SendingDate,SizeOf(SendingDate),ms,11424);
        SaveDataToStream(DeliveryDate,SizeOf(DeliveryDate),ms,11425);
        SaveBooleanToStream(SearchDelivered,ms,11425);
        SaveBooleanToStream(Delivered,ms,11426);
        SaveStringToStream(MessageText,ms,11432);
        SaveWideStringToStream(MessageUnicodeText,ms,11433);
        SaveDataToStream(SenderID,SizeOf(SenderID),ms,11434);
        SaveDataToStream(RecipientID,SizeOf(RecipientID),ms,11435);
        SaveDataToStream(MessageType,SizeOf(MessageType),ms,11427);
        SaveDataToStream(MessageDataSize,SizeOf(MessageDataSize),ms,11428);
        SaveBooleanToStream(OrderBySendingDate,ms,11429);
        SaveStringToStream(OrderByClause,ms,11430);
        SaveDataToStream(Command,SizeOf(Command),ms,11431);
        Result := FDefaultServerSession.FindMessages(ms,ResultDataset);
      finally
        ms.Free;
      end;
     end;
   end; // server history
end; // FindMessages


//------------------------------------------------------------------------------
// receive custom message from server and call defined event
//------------------------------------------------------------------------------
procedure TMsgClient.ReceiveMessage(Session: TMsgClientSession; Buffer: PAnsiChar; Size: Integer);
{$IFDEF CLIENT_VERSION}
var MessageType:  TMsgMessageType;
    ms,ms1:       TMsgMemoryStream;
    FileName,
    Text:         AnsiString;
    UnicodeText:  WideString;
    FileHandle:   Integer;
    BlockNo,
    i,
    len:          Integer;
    Buf:          PAnsiChar;
    StreamSize:   Int64;
    ObjectID,
    Command,
    FromUserID:   Cardinal;
    SendingDate:  TDateTime;
    DeliveryDate: TDateTime;
    Queue:        TMsgList;
    Directly,
    found:        Boolean;
    RecvObject:   PMsgRecvObject;
{$ENDIF}
procedure Release;
begin
  ms.Buffer := nil;
  MemoryManager.FreeAndNilMem(Buffer);
  sleep(0);
end;
begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - start');
{$ENDIF}
  if (Session = FDefaultServerSession) then
   if not Logged then
    if Connected then
     begin
      DoOnError(MSG_Error_ReceiveMessage_NotLogged);
      Exit;
     end;
  {$IFDEF CLIENT_VERSION}
  DeliveryDate := Now;
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - TMsgMemoryStream.Create...');
{$ENDIF}
  ms := TMsgMemoryStream.Create(Buffer);
  try
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - Load...');
{$ENDIF}
    LoadDataFromStream(FromUserID,SizeOf(FromUserID),ms,40050);
    LoadDataFromStream(MessageType,SizeOf(MessageType),ms,10267);
    LoadDataFromStream(SendingDate,SizeOf(SendingDate),ms,11393);
    if (FromUserID <> ConnectionParams.ServerID) and (Session = FDefaultServerSession) then // come from server, but sender is not a server
      Directly := False
    else
      Directly := True;
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - Loaded');
{$ENDIF}
    if (FDatabase <> nil) and (FStoreMessageHistory) then
     SaveMessageToDatabase(FDatabase,FromUserID,FUserID,MessageType,SendingDate,True,DeliveryDate,ms);
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - Saved');
{$ENDIF}
    case MessageType of
     aamtText:
      if (Assigned(FOnReceiveTextMessage)) then
       begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - MessageType = aamtText');
{$ENDIF}
         LoadStringFromStream(Text,ms,10268);
         Release;
         FOnReceiveTextMessage(FromUserID,SendingDate,DeliveryDate,Text);
       end;
     aamtUnicodeText:
      if (Assigned(FOnReceiveUnicodeTextMessage)) then
       begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - MessageType = aamtUnicodeText');
{$ENDIF}
         LoadWideStringFromStream(UnicodeText,ms,11628);
         Release;
         FOnReceiveUnicodeTextMessage(FromUserID,SendingDate,DeliveryDate,UnicodeText);
       end;
     aamtBinary:
      if (Assigned(FOnReceiveBinaryMessage)) then
       begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - MessageType = aamtBinary');
{$ENDIF}
         LoadDataFromStream(len,SizeOf(len),ms,10270);
         if (len > 0) then
          begin
           Buf := MemoryManager.GetMem(len);
           try
             LoadDataFromStream(Buf^,len,ms,10271);
             Release;
             FOnReceiveBinaryMessage(FromUserID,SendingDate,DeliveryDate,Buf,len);
           finally
             MemoryManager.FreeAndNilMem(Buf);
           end;
          end
         else
          begin
           Release;
           FOnReceiveBinaryMessage(FromUserID,SendingDate,DeliveryDate,nil,len);
          end;
       end;
     aamtStream:
      if (Assigned(FOnReceiveStreamMessage)) then
       begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - MessageType = aamtStream');
{$ENDIF}
        ms1 := TMsgMemoryStream.Create;
        try
          LoadDataFromStream(StreamSize,SizeOf(StreamSize),ms,10272);
          if (StreamSize > 0) then
           ms1.LoadFromStreamWithPosition(ms,ms.Position,StreamSize);
          Release;
          FOnReceiveStreamMessage(FromUserID,SendingDate,DeliveryDate,ms1);
        finally
          ms1.Free;
        end;
       end;
     aamtsFile:
      begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - MessageType = aamtsFile');
{$ENDIF}
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - RecvFileMsg...');
{$ENDIF}
       RecvFileMsg(ms,RecvObject,len,BlockNo,ObjectID,SendingDate);
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog(IntToStr(BlockNo)+'> Release...');
{$ENDIF}
       Release;
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog(IntToStr(BlockNo)+'> call event...');
aaWriteToLog('RecvObject='+IntToStr(Integer(RecvObject)));
aaWriteToLog('RecvObject.ObjectID='+IntToStr(RecvObject.ObjectID));
{$ENDIF}
       if (Assigned(FOnReceiveFile)) then //call event
         if (RecvObject = nil) then
           FOnReceiveFile(FromUserID,ObjectID,SendingDate,DeliveryDate,'',-1,len,BlockNo,-1,Directly)
         else
         if (RecvObject.ObjectID > 0)
         then
           FOnReceiveFile(FromUserID,RecvObject.ObjectID,RecvObject.SendingDate,DeliveryDate,RecvObject.FileName,RecvObject.FullSize,RecvObject.BlockSize,BlockNo,RecvObject.Blocks,RecvObject.Directly)
         else
           FOnReceiveFile(FromUserID,ObjectID,SendingDate,DeliveryDate,'',-1,len,BlockNo,-1,Directly);
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog(IntToStr(BlockNo)+'> event processed');
{$ENDIF}
      end; // aamtsFile
    else // Case - Command received
      if (MessageType > MsgHighestType)
      or (MessageType < MsgLowestType) then
        raise EMsgException.Create(40056, ErrorRUnknownMessageType);
      LoadDataFromStream(len,SizeOf(len),ms,10270);
      if (len > 0) then
       begin
         case MessageType of
          MsgCustomCommand:
           begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - MessageType = MsgCustomCommand');
{$ENDIF}
            LoadDataFromStream(Command, SizeOf(Command), ms, 40061);
            len := len - SizeOf(Command);
            if (len > 0) then
             begin
              Buf := MemoryManager.GetMem(len);
              try
               LoadDataFromStream(Buf^, len, ms, 40062);
               Release;
               if (Assigned(FOnReceiveCommand)) then
                 FOnReceiveCommand(FromUserID,Command,SendingDate,DeliveryDate,Buf,len);
              finally
               MemoryManager.FreeAndNilMem(Buf);
              end
             end
            else
             if (Assigned(FOnReceiveCommand)) then
                 FOnReceiveCommand(FromUserID,Command,SendingDate,DeliveryDate,nil,0);
           end;
          MsgUserOnLine:
           begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - MessageType = MsgUserOnLine');
{$ENDIF}
            Buf := MemoryManager.GetMem(len);
            try
             LoadDataFromStream(Buf^,len,ms,10271);
             Release;
             Session.OnLineUser(Cardinal(Pointer(Buf)^));
            finally
             MemoryManager.FreeAndNilMem(Buf);
            end;
           end;
          MsgUserOffLine:
           begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - MessageType = MsgUserOffLine');
{$ENDIF}
            Buf := MemoryManager.GetMem(len);
            try
             LoadDataFromStream(Buf^,len,ms,10271);
             Release;
             if (FindSessionWithUser(Cardinal(Pointer(Buf)^)) = nil) then // added in v.4.51
               Session.OffLineUser(Cardinal(Pointer(Buf)^));
            finally
             MemoryManager.FreeAndNilMem(Buf);
            end;
           end;
          MsgInitLargeObject:
           begin
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - MessageType = MsgInitLargeObject');
{$ENDIF}
            RecvInitLOMsg(ms,RecvObject);
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - Recv - ok');
{$ENDIF}
            if AllowFiles then
             begin
               Release;
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - Released');
{$ENDIF}
               if Session = FDefaultServerSession then
                 RecvObject.Directly := False
               else
                 RecvObject.Directly := True;
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - Add...');
{$ENDIF}
               FRecvQueue.Add(RecvObject);
{$IFDEF LOG_CLIENT_RECEIVE_MESSAGE}
aaWriteToLog('TMsgClient.ReceiveMessage - call event...');
{$ENDIF}
               case RecvObject.ObjectType of
                aamtsFile:
                 if (Assigned(FOnReceiveFile)) then //call event
                  FOnReceiveFile(FromUserID,RecvObject.ObjectID,SendingDate,DeliveryDate,RecvObject.FileName,RecvObject.FullSize,RecvObject.BlockSize,-1,RecvObject.Blocks,RecvObject.Directly);
                aamtsStream:
                 if (Assigned(FOnReceiveStream)) then //call event
                   FOnReceiveStream(FromUserID,RecvObject.ObjectID,SendingDate,DeliveryDate,RecvObject.FullSize,RecvObject.BlockSize,-1,RecvObject.Blocks,RecvObject.Directly);
               end;
             end;
           end; // MsgInitLargeObject
         end; // case
       end;
    end; // Case
  finally
    ms.Free;
  end;
  {$ENDIF}
end; // ReceiveMessage


//------------------------------------------------------------------------------
// PrepareToSendMessage
//------------------------------------------------------------------------------
function TMsgClient.PrepareToSendMessage(
                                  var ToID, ToUserID: Cardinal;
                                  var Directly: Boolean;
                                  var ClientSession: TMsgClientSession
                                  ): Integer;
begin
  ClientSession := nil;
  if not Directly then
    if not Logged then
     begin
      Result := MSG_Error_SendMessage_NotLogged;
      Exit;
     end;
  if ToUserID = MSG_INVALID_USER_ID then
   begin
    Result := MSG_Error_SendMessage_ToGuest;
    Exit;
   end;
  Result := MSG_Error_SendMessage_SessionNotFound;
  ToID := ToUserID;
  try
   if ToUserID = ConnectionParams.ServerID then
    begin
     if not Connected then
       raise EMsgException.Create(40076, ErrorRSendMessageToServer, [ToID])
     else
       ClientSession := FDefaultServerSession;
    end
   else
    begin
     ClientSession := FindSession(ToUserID, Directly);
     if Directly then
       ToUserID := UserID;
    end;
  except
   on e: EMsgException do
    DoOnError(Result,e.NativeError,e.Message);
   on e: Exception do
    DoOnError(Result,-1,e.Message)
   else
    DoOnError(Result);
  end;
  if (ClientSession = nil) then
   begin
    Result := MSG_Error_SendMessage_SessionNotFound;
    Exit;
   end;
  Result := MSG_Error_SendMessage_SendFailed;
end;// PrepareToSendMessage


//------------------------------------------------------------------------------
// SendWithProgress
//------------------------------------------------------------------------------
function TMsgClient.SendWithProgress(
                                  ToUserID: Cardinal;
                                  ObjectType: TMsgMessageType;
                                  const FileName: AnsiString;
                                  Stream: TStream;
                                  Blocks: Integer;
                                  BlockSize: Integer;
                                  Directly: Boolean
                                  ): Integer;
var
  ClientSession:  TMsgClientSession;
  ObjectID,
  ToID:           Cardinal;
  dt:             TDateTime;
  SendObject:     PMsgSendObject;
  SendFileName:   AnsiString;
begin
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - client SendWithProgress start');
{$ENDIF}
  PrepareToSendWithProgress(Stream.Size,Blocks,BlockSize);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - client PrepareToSendMessage...');
{$ENDIF}
  Result := PrepareToSendMessage(ToID,ToUserID,Directly,ClientSession);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - client Prepared');
{$ENDIF}
  if Result <> MSG_Error_SendMessage_SendFailed then
    Exit;
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - client InitProgressSend...');
{$ENDIF}
  SendFileName := FileName;
  Result := ClientSession.InitProgressSend(ObjectType,ToUserID,SendFileName,Stream.Size,Blocks,BlockSize,ObjectID);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - client Inited');
{$ENDIF}
  if (Result <> MSG_COMMAND_OK)
  or (ObjectID = MSG_INVALID_ID) then
   begin
    if Directly then
     begin
      Directly := False;
      ToUserID := ToID;
      Result := PrepareToSendMessage(ToID,ToUserID,Directly,ClientSession);
      if Result <> MSG_Error_SendMessage_SendFailed then
        Exit;
      Result := ClientSession.InitProgressSend(ObjectType,ToUserID,SendFileName,Stream.Size,Blocks,BlockSize,ObjectID);
      if (Result <> MSG_COMMAND_OK)
      or (ObjectID = MSG_INVALID_ID) then
        Exit;
     end
    else
      Exit;
   end;
// initialise sending
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - client initialise sending...');
{$ENDIF}
  AddNewSendObject(SendObject,ToID,ObjectID,ObjectType,SendFileName,Stream,
                   Blocks,BlockSize,Directly);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - client call event...');
{$ENDIF}
  CallSendEvent(ToID,ObjectID,ObjectType,FileName,Stream.Size,Blocks,BlockSize);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - client SendWithProgress finished!');
{$ENDIF}
end; // SendWithProgress


//------------------------------------------------------------------------------
// NeedToResendMessage
//------------------------------------------------------------------------------
function TMsgClient.NeedToResendMessage(
                                  ToID, ToUserID: Cardinal;
                                  Directly: Boolean;
                                  Error: Integer
                                  ): Boolean;
begin
 Result := False;
 try
  if Error = MSG_Error_SendMessage_SendFailed then
   begin
    if ToUserID = ConnectionParams.ServerID then
      raise EMsgException.Create(40076, ErrorRSendMessageToServer, [ToID]);
    if not Connected then
      raise EMsgException.Create(40075, ErrorRSendMessageDirectly, [ToID])
    else
      if not Directly then
        raise EMsgException.Create(40074, ErrorRSendMessageThruServer, [ToID])
      else
        Result := True;
   end;
  except
    on e: EMsgException do
      DoOnError(Error,e.NativeError,e.Message);
  end;
end; // NeedToResendMessage


//------------------------------------------------------------------------------
// send message to multiple addresses
//------------------------------------------------------------------------------
function TMsgClient.SendMessageMultiple(ToUserIDs: TMsgIntegerArray;
                                        const Text: AnsiString;
                                        var Results: TMsgIntegerArray;
                                        Directly: Boolean = True
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
   Results.Items[i] := SendMessage(Cardinal(ToUserIDs.Items[i]),Text,Directly);
  except
   Result := MSG_Error_SendMessageToUserFailed;
  end;
 Result := MSG_COMMAND_OK;
end; // SendMessageToUsers

    {$IFDEF D6H}

function TMsgClient.SendMessageMultiple(ToUserIDs: TMsgIntegerArray;
                                        const Text: WideString;
                                        var Results: TMsgIntegerArray;
                                        Directly: Boolean = True
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
   Results.Items[i] := SendMessage(Cardinal(ToUserIDs.Items[i]),Text,Directly);
  except
   Result := MSG_Error_SendMessageToUserFailed;
  end;
 Result := MSG_COMMAND_OK;
end; // SendMessageToUsers

    {$ELSE}

function TMsgClient.SendMessageMultipleW(ToUserIDs: TMsgIntegerArray;
                                        const Text: WideString;
                                        var Results: TMsgIntegerArray;
                                        Directly: Boolean = True
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
   Results.Items[i] := SendMessage(Cardinal(ToUserIDs.Items[i]),Text,Directly);
  except
   Result := MSG_Error_SendMessageToUserFailed;
  end;
 Result := MSG_COMMAND_OK;
end; // SendMessageToUsers

    {$ENDIF}

function TMsgClient.SendMessageMultiple(ToUserIDs: TMsgIntegerArray; Buffer: PAnsiChar; Size: Integer;
                                        var Results: TMsgIntegerArray;
                                        Directly: Boolean = True
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
   Results.Items[i] := SendMessage(Cardinal(ToUserIDs.Items[i]),
                                   Buffer, Size, Directly);
  except
   Result := MSG_Error_SendMessageToUserFailed;
  end;
 Result := MSG_COMMAND_OK;
end; // SendMessageToUsers


function TMsgClient.SendMessageMultiple(ToUserIDs: TMsgIntegerArray; Stream: TStream;
                                        var Results: TMsgIntegerArray;
                                        Directly: Boolean = True
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
   Results.Items[i] := SendMessage(Cardinal(ToUserIDs.Items[i]),
                                   Stream, Directly);
  except
   Result := MSG_Error_SendMessageToUserFailed;
  end;
 Result := MSG_COMMAND_OK;
end; // SendMessageToUsers


//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
function TMsgClient.SendMessage(
                                  ToUserID: Cardinal;
                                  const Text: AnsiString;
                                  Directly: Boolean = True
                                  ): Integer;
var
  ClientSession:  TMsgClientSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  ToID:           Cardinal;
  dt:             TDateTime;
  Pos:            Int64;
begin
  Result := PrepareToSendMessage(ToID,ToUserID,Directly,ClientSession);
  if Result <> MSG_Error_SendMessage_SendFailed then
    Exit;
  MessageType := aamtText;
  ms := TMsgMemoryStream.Create();
  try
   try // Prepare buffer then Send
     SaveDataToStream(ToUserID,SizeOf(ToUserID),ms,40050);
     SaveDataToStream(MessageType,SizeOf(MessageType),ms,11273);
     dt := Now;
     SaveDataToStream(dt,SizeOf(dt),ms,11388);
     Pos := ms.Position;
     SaveStringToStream(Text,ms,11274);
     ClientSession.SendMessage(ms.Buffer,ms.Size);
     Result := MSG_Error_SendMessage_SaveHistoryToDatabaseFailed;
   except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else
      DoOnError(Result);
   end;
   if Result = MSG_Error_SendMessage_SaveHistoryToDatabaseFailed then
    try // Save History To Database
     if (FDatabase <> nil) and (FStoreMessageHistory) then
      begin
       ms.Position := Pos;
       SaveMessageToDatabase(FDatabase,FUserID,ToUserID,MessageType,dt,False,0,ms);
      end;
     Result := MSG_COMMAND_OK;
    except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else
      DoOnError(Result);
    end;
  finally
    ms.Free;
  end;
  if NeedToResendMessage(ToID,ToUserID,Directly,Result) then
    SendMessage(ToID, AnsiString(Text), False);
end; // SendMessage


{$IFDEF D6H}
//------------------------------------------------------------------------------
// send unicode message
//------------------------------------------------------------------------------
function TMsgClient.SendMessage(ToUserID: Cardinal; const Text: WideString;
                                    Directly: Boolean = True): Integer;
var
  ClientSession:  TMsgClientSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  ToID:           Cardinal;
  dt:             TDateTime;
  Pos:            Int64;
begin
  Result := PrepareToSendMessage(ToID,ToUserID,Directly,ClientSession);
  if Result <> MSG_Error_SendMessage_SendFailed then
    Exit;
  MessageType := aamtUnicodeText;
  ms := TMsgMemoryStream.Create();
  try
   try // Prepare buffer then Send
     SaveDataToStream(ToUserID,SizeOf(ToUserID),ms,11618);
     SaveDataToStream(MessageType,SizeOf(MessageType),ms,11619);
     dt := Now;
     SaveDataToStream(dt,SizeOf(dt),ms,11620);
     Pos := ms.Position;
     SaveWideStringToStream(Text,ms,11621);
     ClientSession.SendMessage(ms.Buffer,ms.Size);
     Result := MSG_Error_SendMessage_SaveHistoryToDatabaseFailed;
   except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else
      DoOnError(Result);
   end;
   if Result = MSG_Error_SendMessage_SaveHistoryToDatabaseFailed then
    try // Save History To Database
     if (FDatabase <> nil) and (FStoreMessageHistory) then
      begin
       ms.Position := Pos;
       SaveMessageToDatabase(FDatabase,FUserID,ToUserID,MessageType,dt,False,0,ms); 
      end; 
     Result := MSG_COMMAND_OK;
    except 
     on e: EMsgException do 
      DoOnError(Result,e.NativeError,e.Message); 
     on e: Exception do
      DoOnError(Result,-1,e.Message) 
     else
      DoOnError(Result);
    end; 
  finally
    ms.Free; 
  end; 
  if NeedToResendMessage(ToID,ToUserID,Directly,Result) then 
    SendMessage(ToID, WideString(Text), False);
end; // SendMessage
{$ELSE} 
//------------------------------------------------------------------------------
// send unicode message
//------------------------------------------------------------------------------
function TMsgClient.SendMessageW(ToUserID: Cardinal; const Text: WideString; 
                                    Directly: Boolean = True): Integer; 
var
  ClientSession:  TMsgClientSession; 
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  ToID:           Cardinal;
  dt:             TDateTime;
  Pos:            Int64;
begin
  Result := PrepareToSendMessage(ToID,ToUserID,Directly,ClientSession);
  if Result <> MSG_Error_SendMessage_SendFailed then
    Exit;
  MessageType := aamtUnicodeText;
  ms := TMsgMemoryStream.Create();
  try
   try // Prepare buffer then Send
     SaveDataToStream(ToUserID,SizeOf(ToUserID),ms,11618);
     SaveDataToStream(MessageType,SizeOf(MessageType),ms,11619);
     dt := Now;
     SaveDataToStream(dt,SizeOf(dt),ms,11620);
     Pos := ms.Position;
     SaveWideStringToStream(Text,ms,11621);
     ClientSession.SendMessage(ms.Buffer,ms.Size);
     Result := MSG_Error_SendMessage_SaveHistoryToDatabaseFailed;
   except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else
      DoOnError(Result);
   end;
   if Result = MSG_Error_SendMessage_SaveHistoryToDatabaseFailed then
    try // Save History To Database
     if (FDatabase <> nil) and (FStoreMessageHistory) then
      begin
       ms.Position := Pos;
       SaveMessageToDatabase(FDatabase,FUserID,ToUserID,MessageType,dt,False,0,ms);
      end;
     Result := MSG_COMMAND_OK;
    except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else
      DoOnError(Result);
    end;
  finally
    ms.Free;
  end;
  if NeedToResendMessage(ToID,ToUserID,Directly,Result) then
    SendMessageW(ToID, WideString(Text), False);
end; // SendMessageW
{$ENDIF}



//------------------------------------------------------------------------------
// send message 
//------------------------------------------------------------------------------ 
function TMsgClient.SendMessage(ToUserID: Cardinal; Buffer: PAnsiChar; Size: Integer;
                                  Directly: Boolean = True;
                                  MessageType: TMsgMessageType = aamtBinary
                                  ): Integer; 
var
  ClientSession:  TMsgClientSession;
  ms:             TMsgMemoryStream; 
  dt:             TDateTime; 
  Pos:            Int64;
  ToID:           Cardinal;
begin 
  Result := PrepareToSendMessage(ToID,ToUserID,Directly,ClientSession);
  if Result <> MSG_Error_SendMessage_SendFailed then 
    Exit; 
  ms := TMsgMemoryStream.Create();
  try 
   try // Prepare buffer then Send
     SaveDataToStream(ToUserID,SizeOf(ToUserID),ms,11567);
     SaveDataToStream(MessageType,SizeOf(MessageType),ms,11276); 
     dt := Now; 
     SaveDataToStream(dt,SizeOf(dt),ms,11389);
     Pos := ms.Position; 
     SaveDataToStream(Size,SizeOf(Size),ms,11277);
     if (Size > 0) then 
       SaveDataToStream(Buffer^,Size,ms,11278); 
     ClientSession.SendMessage(ms.Buffer,ms.Size);
     Result := MSG_Error_SendMessage_SaveHistoryToDatabaseFailed;
   except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else 
      DoOnError(Result);
      Exit; 
   end;
   if Result = MSG_Error_SendMessage_SaveHistoryToDatabaseFailed then
    try // Save History To Database
     if (FDatabase <> nil) and (FStoreMessageHistory) then 
      begin
       ms.Position := Pos; 
       SaveMessageToDatabase(FDatabase,FUserID,ToUserID,MessageType,dt,False,0,ms);
      end;
     Result := MSG_COMMAND_OK;
    except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else
      DoOnError(Result);
    end;
  finally
    ms.Free;
  end;
  if NeedToResendMessage(ToID,ToUserID,Directly,Result) then
    SendMessage(ToID, Buffer, Size, False);
end; // SendMessage


//------------------------------------------------------------------------------
// send message
//------------------------------------------------------------------------------
function TMsgClient.SendMessage(ToUserID: Cardinal; Stream: TStream;
                                  Directly: Boolean = True
                                  ): Integer;
var
  ClientSession:  TMsgClientSession;
  ms:             TMsgMemoryStream;
  MessageType:    TMsgMessageType;
  Size:           Int64;
  dt:             TDateTime;
  Pos:            Int64;
  ToID:           Cardinal;
begin
  Result := PrepareToSendMessage(ToID,ToUserID,Directly,ClientSession);
  if Result <> MSG_Error_SendMessage_SendFailed then
    Exit;
  MessageType := aamtStream;
  Size := Stream.Size;
  ms := TMsgMemoryStream.Create();
  try
   try // Prepare buffer then Send
     SaveDataToStream(ToUserID,SizeOf(ToUserID),ms,11568);
     SaveDataToStream(MessageType,SizeOf(MessageType),ms,11279);
     dt := Now;
     SaveDataToStream(dt,SizeOf(dt),ms,11390);
     Pos := ms.Position;
     SaveDataToStream(Size,SizeOf(Size),ms,11280);
     if (Size > 0) then
      begin
       if (Stream is TMsgStream) then
        TMsgStream(Stream).SaveToStream(ms)
       else
        ms.CopyFrom(Stream,Size);
      end;
     ClientSession.SendMessage(ms.Buffer,ms.Size);
     Result := MSG_Error_SendMessage_SaveHistoryToDatabaseFailed;
   except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else
      DoOnError(Result);
      Exit;
   end;
   if Result = MSG_Error_SendMessage_SaveHistoryToDatabaseFailed then
    try // Save History To Database
     if (FDatabase <> nil) and (FStoreMessageHistory) then
      begin
       ms.Position := Pos;
       SaveMessageToDatabase(FDatabase,FUserID,ToUserID,MessageType,dt,False,0,ms);
      end;
     Result := MSG_COMMAND_OK;
    except
     on e: EMsgException do
      DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      DoOnError(Result,-1,e.Message)
     else
      DoOnError(Result);
    end;
  finally
    ms.Free;
  end;
  if NeedToResendMessage(ToID,ToUserID,Directly,Result) then
    SendMessage(ToID, Stream, False);
end; // SendMessage


//------------------------------------------------------------------------------
// SendCommand
//------------------------------------------------------------------------------
function TMsgClient.SendCommand(Command: Cardinal;
                                Buffer: PAnsiChar;
                                Size: Integer
                                        ): Integer;
var
  Buf:            PAnsiChar;
  BufSize:        Integer;
begin
  if not Logged then
   begin
    Result := MSG_Error_SendCommand_NotLogged;
    Exit;
   end;
  Result := MSG_Error_SendCommand_NotConnected;
  if (Connected) then
   begin
    BufSize := Size + SizeOf(Command);
    Buf := MemoryManager.GetMem(BufSize);
    try
      Move(Command, Buf^, SizeOf(Command));
      Move(Buffer^, (Buf+SizeOf(Command))^, Size);
      Result := FDefaultServerSession.SendCommand(MsgCustomCommand, Buf, BufSize);
    finally
      MemoryManager.FreeAndNilMem(Buf);
    end;
   end;
end; // SendCommand



////////////////////////////////////////////////////////////////////////////////
//
// TMsgClientSession
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgClientSession.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FConnected := False;
  FUserID := TMsgClient(FOwnerComponent).FUserID;
  FConnectParams := TMsgClient(FOwnerComponent).ConnectionParams.GetConnectParams;
  FDirect := False;
  FRemoteUser := nil;
end; // Create


//------------------------------------------------------------------------------
// Destory
//------------------------------------------------------------------------------
destructor TMsgClientSession.Destroy;
begin
  TMsgClient(FOwnerComponent).FSessions.Remove(Self);
  if Connected then
    Disconnect;
  if (FRemoteUser <> nil) then
   Dispose(FRemoteUser);
  FRemoteUser := nil; 
  inherited;
end; // Destory


//------------------------------------------------------------------------------
// call OnError event handler
//------------------------------------------------------------------------------
procedure TMsgClientSession.DoOnError(ErrorCode: Integer; NativeError: Integer = -1; ErrorMessage: AnsiString = '');
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('==================================================================');
aaWriteToLog('Error on client session!');
aaWriteToLog('------------------------------------------------------------------');
aaWriteToLog('SessionID='+IntToStr(Integer(self.SessionID)));
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
{$ENDIF}
  if (TMsgClient(FOwnerComponent) <> nil) then
    TMsgClient(FOwnerComponent).DoOnError(ErrorCode,NativeError,ErrorMessage);
end; // DoOnError


//------------------------------------------------------------------------------
// Send command error occured - session must be destroyed
//------------------------------------------------------------------------------
procedure TMsgClientSession.DoCloseSessionOnNetworkError;
begin
 {$IFDEF DEBUG_LOG_COMMUNICATION}
 aaWriteToLog('Client DoCloseSessionOnNetworkError starting, SessionID = '+IntToStr(SessionID));
 {$ENDIF}
  if (TMsgClient(FOwnerComponent) <> nil) then
    TMsgClient(FOwnerComponent).DoOnError(0,0,'Unknown network error occurs in client session: SessionID = '+IntToStr(SessionID));
(*
  if (TMsgClient(FOwnerComponent) <> nil) then
    TMsgClient(FOwnerComponent).FConnectionManager.TerminateSession(self);
 {$IFDEF DEBUG_LOG_COMMUNICATION}
 aaWriteToLog('Client DoCloseSessionOnNetworkError finish, SessionID = '+IntToStr(FSessionID));
 {$ENDIF}
*)
end; // DoCloseSessionOnNetworkError


//------------------------------------------------------------------------------
// connect / disconnect
//------------------------------------------------------------------------------
procedure TMsgClientSession.SetConnected(value: boolean);
begin
  if Value = FConnected then
    Exit;
  if Value then
    Connect
  else
    Disconnect;
end;//SetConnected


//------------------------------------------------------------------------------
// SetLogged
//------------------------------------------------------------------------------
procedure TMsgClientSession.SetLogged(value: boolean);
begin
  if Value = FLogged then
    Exit;
  if Value then
    Logon
  else
    Logoff;
end;// SetLogged


//------------------------------------------------------------------------------
// Logon
//------------------------------------------------------------------------------
function TMsgClientSession.Logon: Integer;
var
  Session:          TMsgComBaseSession;
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  if (not Logged) then
   begin
    Result := MSG_Error_Logon_NotConnected;
    if (Connected) then
     begin
      if Assigned(TMsgClient(FOwnerComponent).BeforeLogon) then
        TMsgClient(FOwnerComponent).BeforeLogon(Self);
      Result := MSG_Error_Logon_SendCommandFailed;
      try
       ms := TMsgMemoryStream.Create;
       try
         SaveCommandHeader(ms,MsgLogon);
         SaveDataToStream(TMsgClient(FOwnerComponent).FUserID,SizeOf(UserID),ms,40082);
         SaveStringToStream(TMsgClient(FOwnerComponent).FPassword,ms,40083);
         Buffer := ms.Buffer;
         SendBuffer(Buffer,ms.Size);
       finally
         ms.Free;
       end;
      except // Send
       on e: EMsgException do
        TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
       on e: Exception do
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
       else
        TMsgClient(FOwnerComponent).DoOnError(Result);
       Exit;
      end;
      Result := MSG_Error_Logon_ReceiveResultFailed;
      try
       ReceiveData(Buffer,BufferSize);
       Result := MSG_Error_Logon_InvalidServerReply;
       if (Buffer = nil)
       or (BufferSize <> (SizeOf(TMsgCommandHeader) )) then
        begin
         if (Buffer <> nil) then
           MemoryManager.FreeAndNilMem(Buffer);
         TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in Logon');
        end
       else
        begin
         try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
          if (Result = MSG_Error_Logon_MaxConnectionsExceeded) then
           begin
            FConnected := False;
{$IFDEF TRIAL_VERSION}
            TMsgShowMessageThread.Create(
              'Cannot connect to the server # '+IntToStr(Self.ConnectParams.ServerID)+'.'#13+
{$IFDEF MSWINDOWS}#10+{$ENDIF}
              'This is a trial version.'#13+
{$IFDEF MSWINDOWS}#10+{$ENDIF}
              'The number of concurrent connections is limited by '+IntToStr(MsgMaxSingleUserConnections)+'.'#13+
{$IFDEF MSWINDOWS}#10+{$ENDIF}
              #13+
{$IFDEF MSWINDOWS}#10+{$ENDIF}
              'Please contact AidAim Software to buy full version.'#13+
{$IFDEF MSWINDOWS}#10+{$ENDIF}
              'Web-site: http://www.aidaim.com'#13+
{$IFDEF MSWINDOWS}#10+{$ENDIF}
              'E-mail: sales@aidaim.com'
                  );
            sleep(0);
{$ENDIF TRIAL_VERSION}
            if Assigned(FOnServerShutdown) then
              FOnServerShutdown(Self);
           end;
          if (Result = MSG_COMMAND_OK) then
           begin
            FLogged := True;
            TMsgClient(FOwnerComponent).FLogged := True;
           end
          else
            TMsgClient(FOwnerComponent).DoOnError(Result,PMsgCommandHeader(Buffer)^.NativeError);
          finally
           MemoryManager.FreeAndNilMem(Buffer);
          end;
        end;
      except // Receive
       on e: EMsgException do
        TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
       on e: Exception do
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
       else
        TMsgClient(FOwnerComponent).DoOnError(Result);
       Exit;
      end;
    if Assigned(TMsgClient(FOwnerComponent).AfterLogon) then
      TMsgClient(FOwnerComponent).AfterLogon(Self);
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
   end;
end;// Logon


//------------------------------------------------------------------------------
// Logoff
//------------------------------------------------------------------------------
function TMsgClientSession.Logoff: Integer;
var
  Session:          TMsgComBaseSession;
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  if Logged then
   begin
    Result := MSG_Error_Logoff_NotConnected;
    if (Connected) then
     begin
      if Assigned(TMsgClient(FOwnerComponent).BeforeLogoff) then
        TMsgClient(FOwnerComponent).BeforeLogoff(Self);
      Result := MSG_Error_Logoff_SendCommandFailed;
      try
       ms := TMsgMemoryStream.Create;
       try
         SaveCommandHeader(ms,MsgLogoff);
         SaveDataToStream(TMsgClient(FOwnerComponent).FUserID,SizeOf(UserID),ms,40084);
         SaveStringToStream(TMsgClient(FOwnerComponent).FPassword,ms,40085);
         Buffer := ms.Buffer;
         SendBuffer(Buffer,ms.Size);
       finally
         ms.Free;
       end;
      except // Send
       on e: EMsgException do
        TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
       on e: Exception do
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
       else
        TMsgClient(FOwnerComponent).DoOnError(Result);
       Exit;
      end;
      Result := MSG_Error_Logoff_ReceiveResultFailed;
      try
       ReceiveData(Buffer,BufferSize);
       Result := MSG_Error_Logoff_InvalidServerReply;
       if (Buffer = nil)
       or (BufferSize < (SizeOf(TMsgCommandHeader) )) then
        begin
         if (Buffer <> nil) then
           MemoryManager.FreeAndNilMem(Buffer);
         TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in Logoff');
        end
       else
        begin
         try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
          if (Result = MSG_COMMAND_OK) then
           begin
            FLogged := False;
            TMsgClient(FOwnerComponent).FLogged := False;
           end
          else
            TMsgClient(FOwnerComponent).DoOnError(Result,PMsgCommandHeader(Buffer)^.NativeError);
          finally
           MemoryManager.FreeAndNilMem(Buffer);
          end;
        end;
      except // Receive
       on e: EMsgException do
        TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
       on e: Exception do
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
       else
        TMsgClient(FOwnerComponent).DoOnError(Result);
       Exit;
      end;
    if Assigned(TMsgClient(FOwnerComponent).AfterLogoff) then
      TMsgClient(FOwnerComponent).AfterLogoff(Self);
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
   end;
end;// Logoff


//------------------------------------------------------------------------------
// GetMyUserID
//------------------------------------------------------------------------------
function TMsgClientSession.GetMyUserID: Cardinal;
var
  Session:          TMsgComBaseSession;
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := FUserID;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgGetUserID);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    try
      ReceiveData(Buffer,BufferSize);
      if (PMsgCommandHeader(Buffer)^.CommandResult = MSG_COMMAND_OK) then
        Move(PAnsiChar(Buffer+SizeOf(TMsgCommandHeader))^,Result,SizeOf(Result))
      else
        TMsgClient(FOwnerComponent).DoOnError(Result,PMsgCommandHeader(Buffer)^.NativeError);
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
    end;
end; // GetMyUserID


//------------------------------------------------------------------------------
// connect
//------------------------------------------------------------------------------
procedure TMsgClientSession.Connect;
var
  res:      Integer;
  lUserID:  Cardinal;
begin
  if (not Connected)
  then
   begin
    if Assigned(BeforeConnect) then
      BeforeConnect(Self);
    FUserID := TMsgClient(FOwnerComponent).FUserID;
    ConnectParams := TMsgClient(FOwnerComponent).ConnectionParams.ConnectParams;
    ClientConnectionManager.Connect(Self);
    if (Self = TMsgClient(FOwnerComponent).FDefaultSession)
    or (Self = TMsgClient(FOwnerComponent).FDefaultServerSession)
    then
      TMsgClient(FOwnerComponent).ConnectionParams.LocalPort := Self.FConnectParams.LocalPort;
    FConnected := True;
    if UserID <> MSG_INVALID_USER_ID then
     begin
      res := Logon;
      if not Logged then
       begin
        lUserID := FUserID;
        FUserID := MSG_INVALID_USER_ID;
        TMsgClient(FOwnerComponent).FUserID := MSG_INVALID_USER_ID;
        raise EMsgException.Create(40100, ErrorRCannotConnectUser, [lUserID, res]);
       end;
     end;
    if Assigned(AfterConnect) then
      AfterConnect(Self);
   end;
end; // Connect


//------------------------------------------------------------------------------
// ConnectDirectly
//------------------------------------------------------------------------------
procedure TMsgClientSession.ConnectDirectly;
begin
  if (not Connected)
  then
   begin
    if Assigned(BeforeConnect) then
      BeforeConnect(Self);
    ClientConnectionManager.Connect(Self);
    FConnected := True;
    if Assigned(AfterConnect) then
      AfterConnect(Self);
   end;
end; // ConnectDirectly


//------------------------------------------------------------------------------
// Disconnect
//------------------------------------------------------------------------------
procedure TMsgClientSession.Disconnect;
var
  bCatchException:  Boolean;
begin
  if Connected then
   begin
    if Assigned(BeforeDisconnect) then
      BeforeDisconnect(Self);
    bCatchException := False;
{$IFDEF D6H}
    // fix: to enable open forms with incorrect properties
    if (csDesigning in TMsgClient(FOwnerComponent).ComponentState)
    and (not (csFreeNotification in TMsgClient(FOwnerComponent).ComponentState))
    then
      bCatchException := True;
{$ENDIF}
    try
     ClientConnectionManager.Disconnect(Self, Direct);
    except
     on e: Exception do
      if (csDesigning in TMsgClient(FOwnerComponent).ComponentState) then
        MessageDlg(e.Message,mtError,[mbOK],0)
      else
       if (not bCatchException) then
         raise;
    end;
    FConnected := False;
    if Direct then
      if (Assigned(TMsgClient(FOwnerComponent).FOnUserOffLine)) then
        TMsgClient(FOwnerComponent).FOnUserOffLine(UserID);
    if Assigned(AfterDisconnect) then
      AfterDisconnect(Self);
   end;
end; // Disconnect


//------------------------------------------------------------------------------
// return MSG_COMMAND_OK and UserInfo if user exists, otherwise return error code
//------------------------------------------------------------------------------
function TMsgClientSession.GetUserInfo(UserID: Cardinal; var UserInfo: TMsgUserInfo): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  FillChar(UserInfo,SizeOf(UserInfo),$00);
  UserInfo.UserID := MSG_INVALID_USER_ID;
  Result := MSG_Error_GetUserInfo_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_GetUserInfo_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgGetUserInfo);
       SaveDataToStream(UserID,SizeOf(UserID),ms,11463);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_GetUserInfo_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_GetUserInfo_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < (SizeOf(TMsgCommandHeader) )) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in GetUserInfo');
       end
      else
       begin
        try
          if (PMsgCommandHeader(Buffer)^.CommandResult = MSG_COMMAND_OK) then
           begin
            ms := TMsgMemoryStream.Create(Buffer,BufferSize);
            try
              ms.Position := SizeOf(TMsgCommandHeader);
              TMsgClient(FOwnerComponent).LoadUserInfoFromStream(UserInfo,ms);
              Result := MSG_COMMAND_OK;
            finally
              ms.Buffer := nil;
              ms.Free;
            end;

//            Move(PAnsiChar(Buffer+SizeOf(TMsgCommandHeader))^,UserInfo,SizeOf(UserInfo));
           end
          else
           begin
            Result := PMsgCommandHeader(Buffer)^.CommandResult;
            if (Result <> MSG_Error_GetUserInfo_UserDoesNotExist) then
             TMsgClient(FOwnerComponent).DoOnError(Result,PMsgCommandHeader(Buffer)^.NativeError);
           end;
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // GetUserInfo


//------------------------------------------------------------------------------
// get list of Contacts of this client from server
//------------------------------------------------------------------------------
function TMsgClientSession.GetContacts(var Contacts: TMsgContactInfoArray): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := MSG_Error_GetContacts_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_GetContacts_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgGetContacts);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_GetContacts_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_GetContacts_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < SizeOf(TMsgCommandHeader)) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in GetContacts');
       end
      else
       begin
        ms := TMsgMemoryStream.Create(Buffer,BufferSize);
        try
          if (PMsgCommandHeader(Buffer)^.CommandResult = MSG_COMMAND_OK) then
           begin
            ms.Position := SizeOf(TMsgCommandHeader);
            // load contact list
            TMsgClient(FOwnerComponent).LoadContactsFromStream(Contacts,ms);
            Result := MSG_COMMAND_OK;
           end
          else
           begin
            Result := PMsgCommandHeader(Buffer)^.CommandResult;
            TMsgClient(FOwnerComponent).DoOnError(Result,PMsgCommandHeader(Buffer)^.NativeError);
           end;
        finally
          ms.Free;
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // GetContacts


//------------------------------------------------------------------------------
// determine if user is already registered at server
//------------------------------------------------------------------------------
function TMsgClientSession.IsUserExisting(UserID: Cardinal): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := MSG_Error_IsUserExisting_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_IsUserExisting_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgIsUserExisting);
       SaveDataToStream(UserID,SizeOf(UserID),ms,11474);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_IsUserExisting_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_IsUserExisting_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < (SizeOf(TMsgCommandHeader))) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in IsUserExisting');
       end
      else
       begin
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // IsUserExisting


//------------------------------------------------------------------------------
// search for UserID by the UserName.
//------------------------------------------------------------------------------
function TMsgClientSession.FindUserID(const UserName: ShortString; out UserID: Cardinal): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := MSG_Error_FindUserID_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_FindUserID_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgFindUserID);
       SaveShortStringToStream(UserName,ms,40150);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_FindUserID_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_FindUserID_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < (SizeOf(TMsgCommandHeader))) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in FindUserID');
       end
      else
       begin
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
          if Result = MSG_COMMAND_OK then
            Move((Buffer+SizeOf(TMsgCommandHeader))^,UserID,SizeOf(UserID))
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // FindUserID


//------------------------------------------------------------------------------
// determine if user is on-line now
//------------------------------------------------------------------------------
function TMsgClientSession.IsUserOnLine(UserID: Cardinal): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := MSG_Error_IsUserOnline_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_IsUserOnline_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgIsUserOnline);
       SaveDataToStream(UserID,SizeOf(UserID),ms,11475);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_IsUserOnline_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_IsUserOnline_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < SizeOf(TMsgCommandHeader)) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in IsUserOnLine');
       end
      else
       begin
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // IsUserOnLine


//------------------------------------------------------------------------------
// register new user at server
//------------------------------------------------------------------------------
function TMsgClientSession.RegisterNewUser(var UserInfo: TMsgUserInfo;
                                           Password: ShortString = '';
                                           Logon: Boolean = True): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := MSG_Error_RegisterNewUser_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_RegisterNewUser_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgRegisterNewUser);
       TMsgClient(FOwnerComponent).SaveUserInfoToStream(UserInfo,ms);
       SaveShortStringToStream(Password,ms,11480);
       SaveBooleanToStream(Logon,ms,40101);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_RegisterNewUser_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_RegisterNewUser_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < SizeOf(TMsgCommandHeader)) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in RegisterNewUser');
       end
      else
       begin
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
          if Result = MSG_COMMAND_OK then
           begin
            if UserInfo.UserID = MSG_INVALID_USER_ID then
              Move((Buffer+SizeOf(TMsgCommandHeader))^,FUserID,SizeOf(FUserID))
            else
              FUserID := UserInfo.UserID;
            if Logon then
             begin
              TMsgClient(FOwnerComponent).FUserID := FUserID;
              if TMsgClient(FOwnerComponent).FDefaultSession <> nil then
                TMsgClient(FOwnerComponent).FDefaultSession.FUserID := FUserID;
              TMsgClient(FOwnerComponent).Active := True;
             end;
            FLogged := Logon;
            TMsgClient(FOwnerComponent).FLogged := Logon;
           end;
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // RegisterNewUser


//------------------------------------------------------------------------------
// register new user at server
//------------------------------------------------------------------------------
function TMsgClientSession.UpdateUserInfo(var UserInfo: TMsgUserInfo; ChangePassword: Boolean; Password: ShortString = ''): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := MSG_Error_UpdateUserInfo_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_UpdateUserInfo_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgUpdateUserInfo);
       TMsgClient(FOwnerComponent).SaveUserInfoToStream(UserInfo,ms);
       SaveBooleanToStream(ChangePassword,ms,11482);
       SaveShortStringToStream(Password,ms,11483);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_UpdateUserInfo_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_UpdateUserInfo_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < SizeOf(TMsgCommandHeader)) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in UpdateUserInfo');
       end
      else
       begin
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // UpdateUserInfo


//------------------------------------------------------------------------------
// add user to Contacts list of this client
//------------------------------------------------------------------------------
function TMsgClientSession.AddUserToContacts(
                               UserID:            Cardinal;
                               var UserInfo:      TMsgUserInfo;
                               ContactNameSource: TMsgContactNameSource;
                               ContactCustomName: ShortString
                              ): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := MSG_Error_AddUserToContacts_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_AddUserToContacts_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgAddUserToContacts);
       SaveDataToStream(UserID,SizeOf(UserID),ms,11493);
       SaveDataToStream(ContactNameSource,SizeOf(ContactNameSource),ms,11494);
       SaveShortStringToStream(ContactCustomName,ms,11495);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_AddUserToContacts_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_AddUserToContacts_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < SizeOf(TMsgCommandHeader)) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in AddUserToContacts');
       end
      else
       begin
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
          if (Result = MSG_COMMAND_OK) then
           begin
            if (BufferSize < SizeOf(TMsgCommandHeader)) then
              Result := MSG_Error_AddUserToContacts_InvalidServerReply
            else
             begin
              ms := TMsgMemoryStream.Create(Buffer,BufferSize);
              try
               try
                ms.Position := SizeOf(TMsgCommandHeader);
                TMsgClient(FOwnerComponent).LoadUserInfoFromStream(UserInfo,ms);
               except
                Result := MSG_Error_AddUserToContacts_InvalidServerReply;
                raise;
               end;
              finally
                ms.Buffer := nil;
                ms.Free;
              end;
             end;
           end;
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // AddUserToContacts


//------------------------------------------------------------------------------
// update user in Contacts list of this client
//------------------------------------------------------------------------------
function TMsgClientSession.UpdateUserInContacts(
                           UserID:            Cardinal;
                           ContactNameSource: TMsgContactNameSource;
                           ContactCustomName: ShortString
                          ): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := MSG_Error_UpdateUserInContacts_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_UpdateUserInContacts_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgUpdateUserInContacts);
       SaveDataToStream(UserID,SizeOf(UserID),ms,11506);
       SaveDataToStream(ContactNameSource,SizeOf(ContactNameSource),ms,11507);
       SaveShortStringToStream(ContactCustomName,ms,11508);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_UpdateUserInContacts_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_UpdateUserInContacts_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < SizeOf(TMsgCommandHeader)) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in UpdateUserInContacts');
       end
      else
       begin
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // UpdateUserInContacts


//------------------------------------------------------------------------------
// remove user from Contacts list of this client
//------------------------------------------------------------------------------
function TMsgClientSession.RemoveUserFromContacts(UserID: Cardinal): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
begin
  Result := MSG_Error_RemoveUserFromContacts_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_RemoveUserFromContacts_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgRemoveUserFromContacts);
       SaveDataToStream(UserID,SizeOf(UserID),ms,11513);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_RemoveUserFromContacts_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_RemoveUserFromContacts_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < SizeOf(TMsgCommandHeader)) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in RemoveUserFromContacts');
       end
      else
       begin
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // RemoveUserFromContacts


//------------------------------------------------------------------------------
// find users
//------------------------------------------------------------------------------
function TMsgClientSession.FindUsers(
                    var Users: TMsgUserInfoArray;
                    Stream:    TMsgMemoryStream
                   ): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize,Len,i: Integer;
begin
  Result := MSG_Error_FindUsers_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_FindUsers_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgFindUsers);
       SaveDataToStream(Stream.Buffer^,Stream.Size,ms,11516);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_FindUsers_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_FindUsers_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < SizeOf(TMsgCommandHeader)) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in FindUsers');
       end
      else
       begin
        ms := TMsgMemoryStream.Create(Buffer,BufferSize);
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
          ms.Position := SizeOf(TMsgCommandHeader);
          if (Result = MSG_COMMAND_OK) then
           begin
            try
              LoadDataFromStream(Len,SizeOf(Len),ms,11517);
              SetLength(Users,Len);
              for i := 0 to Len-1 do
               TMsgClient(FOwnerComponent).LoadUserInfoFromStream(Users[i],ms);
            except
              Result := MSG_Error_FindUsers_InvalidServerReply;
            end;
           end;
        finally
          ms.Free;
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // FindUsers


//------------------------------------------------------------------------------
// find messages
//------------------------------------------------------------------------------
function TMsgClientSession.FindMessages(
                        Stream:   TMsgMemoryStream;
                        out       ResultDataset: TDataset
                       ): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize,Len:   Integer;
begin
  Result := MSG_Error_FindMessages_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_FindMessages_SendCommandFailed;
    try
     ms := TMsgMemoryStream.Create;
     try
       SaveCommandHeader(ms,MsgFindMessages);
       SaveDataToStream(Stream.Buffer^,Stream.Size,ms,11548);
       Buffer := ms.Buffer;
       SendBuffer(Buffer,ms.Size);
     finally
       ms.Free;
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_FindMessages_ReceiveResultFailed;
    try
      ReceiveData(Buffer,BufferSize);
      Result := MSG_Error_FindMessages_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize < SizeOf(TMsgCommandHeader)) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in FindMessages');
       end
      else
       begin
        ms := TMsgMemoryStream.Create(Buffer,BufferSize);
        try
          Result := PMsgCommandHeader(Buffer)^.CommandResult;
          ms.Position := SizeOf(TMsgCommandHeader);
          if (Result = MSG_COMMAND_OK) then
           begin
            try
              TMsgClient(FOwnerComponent).TempTable.LoadDatasetFromStream(ResultDataset,ms);
            except
              Result := MSG_Error_FindMessages_CannotLoadDatasetFromStream;
              if (ResultDataset <> nil) then
               begin
                ResultDataset.Free;
                ResultDataset := nil;
               end;
            end;
           end;
        finally
          ms.Free;
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
end; // FindMessages


//------------------------------------------------------------------------------
// connect user to this client
//------------------------------------------------------------------------------
function TMsgClientSession.ConnectUser(UserID: Cardinal; Host: AnsiString; Port: Integer): TMsgComBaseSession;
begin
  Result := nil;
  Result := TMsgClient(FOwnerComponent).FindSessionWithUser(UserID);
  if (Result = nil)
  or (not TMsgClientSession(Result).Direct)
  or (not TMsgClientSession(Result).RemoteUser.UserID <> UserID)
  then // Create direct session
   begin
    Result := TMsgClient(FOwnerComponent).CreateDirectSession(UserID, Host, Port);
    if Result = nil then
      Exit; // Error!
    if not Result.ConnectedUser(UserID, Host, Port) then
     begin
      Result := nil;
      Exit; // Error!
     end;
   end
  else
    if not Result.ConnectedUser(UserID, Host, Port) then
      Result := nil;
end;// ConnectUser


//------------------------------------------------------------------------------
// connect user to this client
//------------------------------------------------------------------------------
function TMsgClientSession.ConnectedUser(UserID: Cardinal; Host: AnsiString; Port: Integer): Boolean;
begin
  Result := False;
  if (not TMsgClient(FOwnerComponent).Active)
  or (not TMsgClient(FOwnerComponent).AllowDirectly)
  then
    Exit;
  if RemoteUser.UserID <> UserID then
    Exit; // Error!
  if RemoteUser.Status <> msgConnecting then
    Exit; // Error!
  FRemoteUser.Status := msgConnected;
  FRemoteUser.Host := Host;
  FRemoteUser.Port := Port;
  FConnected := True;
  if not TMsgClient(FOwnerComponent).ConnectedDirectly then
    if Self.Connected then
      TMsgClient(FOwnerComponent).FConnectedDirectly := True;
  if Direct then
    if not(TMsgClient(FOwnerComponent).FConnected) then // peer-to-peer mode
      if (Assigned(TMsgClient(FOwnerComponent).FOnUserOnLine)) then
        TMsgClient(FOwnerComponent).FOnUserOnLine(UserID);
  Result := True;
end;// ConnectedUser


//------------------------------------------------------------------------------
// disconnect user from this client
//------------------------------------------------------------------------------
function TMsgClientSession.DisconnectUser(UserID: Cardinal): Boolean;
var
  Session:          TMsgClientSession;
begin
  Result := False;
  Session := TMsgClient(FOwnerComponent).FindSessionWithUser(UserID);
  if (Session <> nil) then
  if (Session.Direct)
  then
   begin
    TMsgClient(FOwnerComponent).FSessions.Remove(Session);
    Session.Free;
   end;
end;// DisconnectUser


//------------------------------------------------------------------------------
// send buffer with command in it via established connection using connection manager
//------------------------------------------------------------------------------
procedure TMsgClientSession.SendBuffer(Buffer: PAnsiChar; BufferSize: Integer; Code: Integer);
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog(#13#10+'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');
aaWriteToLog('C> ClientSession is starting to send a command or buffer...');
aaWriteToLog('C> SessionID = '+IntToStr(SessionID)+', ServerID = '+IntToStr(ConnectParams.ServerID)+#13#10+
             'C> Client UserID = '+IntToStr(Integer(FUserID))+#13#10+
             'C> Server Host = '+ConnectParams.RemoteHost+#13#10+
             'C> Server Port = '+IntToStr(ConnectParams.RemotePort)+#13#10);
if (BufferSize >= SizeOf(TMsgCommandHeader)) then
 begin
  aaWriteToLog('C> CommandCode = '+IntToStr(PMsgCommandHeader(Buffer)^.CommandCode));
  aaWriteToLog('C> CommandResult = '+IntToStr(PMsgCommandHeader(Buffer)^.CommandResult));
  aaWriteToLog('C> NativeError = '+IntToStr(PMsgCommandHeader(Buffer)^.NativeError));
 end;
aaWriteBufferToLog(Buffer,BufferSize);
aaWriteToLog('C> Send Start Time = '+aaGetCurrentTimeAsString);
{$ENDIF}
  ClientConnectionManager.SendBuffer(Self,Buffer,BufferSize,Code);
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteBufferToLog(Buffer,BufferSize);
aaWriteToLog('C> Send End Time = '+aaGetCurrentTimeAsString);
aaWriteToLog('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+#13#10);
{$ENDIF}
end; // SendBuffer


//------------------------------------------------------------------------------
// receive command's answer
//------------------------------------------------------------------------------
procedure TMsgClientSession.ReceiveData(var Buffer: PAnsiChar; var BufferSize: Integer);
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog(#13#10+'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');
aaWriteToLog('C> ClientSession is starting to receive a reply...');
aaWriteToLog('C> SessionID = '+IntToStr(SessionID)+', ServerID = '+IntToStr(ConnectParams.ServerID)+#13#10+
             'C> Client UserID = '+IntToStr(Integer(FUserID))+#13#10+
             'C> Server Host = '+ConnectParams.RemoteHost+#13#10+
             'C> Server Port = '+IntToStr(ConnectParams.RemotePort)+#13#10);
aaWriteToLog('C> Receive Start Time = '+aaGetCurrentTimeAsString);
{$ENDIF}
  ClientConnectionManager.ReceiveBuffer(Self,Buffer,BufferSize);
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog('C> Receive End Time = '+aaGetCurrentTimeAsString);
aaWriteBufferToLog(Buffer,BufferSize);
if (BufferSize >= SizeOf(TMsgCommandHeader)) then
 begin
  aaWriteToLog('C> CommandCode = '+IntToStr(PMsgCommandHeader(Buffer)^.CommandCode));
  aaWriteToLog('C> CommandResult = '+IntToStr(PMsgCommandHeader(Buffer)^.CommandResult));
  aaWriteToLog('C> NativeError = '+IntToStr(PMsgCommandHeader(Buffer)^.NativeError));
 end;
aaWriteToLog('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^'+#13#10);
{$ENDIF}
end; // ReceiveData


//------------------------------------------------------------------------------
// execute received command
//------------------------------------------------------------------------------
procedure TMsgClientSession.ExecuteReceivedCommand(var Buffer: PAnsiChar; BufferSize: Integer);
var
  ms:             TMsgMemoryStream;
  CommandHeader:  TMsgCommandHeader;
begin
{$IFDEF DEBUG_LOG_COMMUNICATION}
aaWriteToLog(#13#10+'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv');
aaWriteToLog('S> ServerSession is starting to execute a received command...');
aaWriteToLog('S> SessionID = '+IntToStr(SessionID)+', ServerID = '+IntToStr(TMsgClient(FOwnerComponent).ConnectionParams.ServerID)+#13#10+
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
       case CommandHeader.CommandCode of
        MsgInitProgressSend:       ExecuteInitProgressRecv(CommandHeader,ms);
       end;
      except
       // ignore invalid buffer
       on e: EMsgException do
        TMsgClient(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
       on e: Exception do
        TMsgClient(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
       else
        TMsgClient(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
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
// ExecuteInitProgressRecv
//------------------------------------------------------------------------------
procedure TMsgClientSession.ExecuteInitProgressRecv(var CommandHeader: TMsgCommandHeader; Stream: TMsgMemoryStream);
var
  ObjectID,
  FromUserID:       Cardinal;
  Buffer:           PAnsiChar;
  ms:               TMsgMemoryStream;
  RecvObject:       PMsgRecvObject;
  dt:               TDateTime;
begin
 ObjectID := MSG_INVALID_ID;
 if not TMsgClient(FOwnerComponent).AllowFiles then
  begin
   CommandHeader.CommandResult := MSG_Error_InitProgressRecvClnt_Deny;
  end
 else
  begin
   New(RecvObject);
   RecvObject.SendingDate := 0;
   CommandHeader.CommandResult := MSG_Error_InitProgressRecvClnt_InvalidParams;
   try
    LoadDataFromStream(Byte(RecvObject.ObjectType),SizeOf(RecvObject.ObjectType),Stream,40138);
    LoadDataFromStream(FromUserID,SizeOf(FromUserID),Stream,40139);
    if RecvObject.ObjectType = aamtsFile then
      LoadStringFromStream(RecvObject.Filename,Stream,40140)
    else
      RecvObject.FileName := '';
    LoadDataFromStream(RecvObject.FullSize,SizeOf(RecvObject.FullSize),Stream,40141);
    LoadDataFromStream(RecvObject.Blocks,SizeOf(RecvObject.Blocks),Stream,40142);
    LoadDataFromStream(RecvObject.BlockSize,SizeOf(RecvObject.BlockSize),Stream,40143);
    CommandHeader.CommandResult := MSG_COMMAND_OK;
   except
    on e: EMsgException do
     TMsgClient(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
    on e: Exception do
     TMsgClient(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
   else
     TMsgClient(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
   end;
   if FromUserID<>Self.RemoteUser.UserID then
     CommandHeader.CommandResult := MSG_Error_InitProgressRecvClnt_UserIDMismatch;
   if (CommandHeader.CommandResult = MSG_COMMAND_OK) then
    begin
     try
      CommandHeader.CommandResult := MSG_Error_InitProgressRecvClnt_Failed;
//      EnterCriticalSection(TMsgClient(FOwnerComponent).FCSect);
      if TMsgClient(FOwnerComponent).FObjectID = MSG_INVALID_ID then
        TMsgClient(FOwnerComponent).FObjectID := 0;
      inc(TMsgClient(FOwnerComponent).FObjectID);
      ObjectID := TMsgClient(FOwnerComponent).FObjectID;
//      LeaveCriticalSection(TMsgClient(FOwnerComponent).FCSect);
      CommandHeader.CommandResult := MSG_COMMAND_OK;
     except
       on e: EMsgException do
        TMsgClient(FOwnerComponent).DoOnError(CommandHeader.CommandResult,e.NativeError,e.Message);
       on e: Exception do
        TMsgClient(FOwnerComponent).DoOnError(CommandHeader.CommandResult,-1,e.Message)
       else
        TMsgClient(FOwnerComponent).DoOnError(CommandHeader.CommandResult);
     end;
    end;
  end; // AllowReceiveFiles
 // Send answer to sender
 ms := TMsgMemoryStream.Create;
 try
  SaveDataToStream(CommandHeader,SizeOf(CommandHeader),ms,40144);
  SaveDataToStream(ObjectID,SizeOf(ObjectID),ms,40145);
  Buffer := ms.Buffer;
  SendBuffer(Buffer,ms.Size);
 finally
  ms.Free;
 end;
 if (CommandHeader.CommandResult <> MSG_COMMAND_OK) then
  begin
   Dispose(RecvObject);
   Exit;
  end;
 if TMsgClient(FOwnerComponent).AllowFiles then
  begin
    // add object to queue
    RecvObject.ObjectID := ObjectID;
    TMsgClient(FOwnerComponent).FRecvQueue.Add(RecvObject);
    dt := Now;
    // Client event
    if RecvObject.ObjectType = aamtsFile then
     begin
      if (Assigned(TMsgClient(FOwnerComponent).OnReceiveFile)) then
        TMsgClient(FOwnerComponent).OnReceiveFile(FUserID,ObjectID,dt,dt,RecvObject.FileName,RecvObject.FullSize,RecvObject.BlockSize,-1,RecvObject.Blocks,False);
     end
    else
    if RecvObject.ObjectType = aamtsStream then
     begin
      if (Assigned(TMsgClient(FOwnerComponent).OnReceiveStream)) then
        TMsgClient(FOwnerComponent).OnReceiveStream(FUserID,ObjectID,dt,dt,RecvObject.FullSize,RecvObject.BlockSize,-1,RecvObject.Blocks,False);
     end;
  end;
end; // ExecuteInitProgressRecv


//------------------------------------------------------------------------------
// returns ID, or MS_INVALID_ID
//------------------------------------------------------------------------------
function TMsgClientSession.InitProgressSend(
                              ObjectType: TMsgMessageType;
                              ToUserID: Cardinal;
                              const FileName: AnsiString;
                              FullSize: Int64;
                              Blocks: Integer;
                              BlockSize: Integer;
                              var ObjectID: Cardinal
                                            ): Integer;
var
  ms:               TMsgMemoryStream;
  Buffer:           PAnsiChar;
  BufferSize:       Integer;
  i:                Integer;
begin
  Result := MSG_Error_InitProgressSend_NotConnected;
  if (Connected) then
   begin
    Result := MSG_Error_InitProgressSend_SendCommandFailed;
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - InitProgressSend> ms');
{$ENDIF}
    try
     ms := TMsgMemoryStream.Create;
     try
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - InitProgressSend> save...');
{$ENDIF}
       SaveCommandHeader(ms,MsgInitProgressSend);
       SaveDataToStream(Byte(ObjectType),SizeOf(ObjectType),ms,40104);
       SaveDataToStream(ToUserID,SizeOf(ToUserID),ms,40105);
       if ObjectType = aamtsFile then
         SaveStringToStream(Filename,ms,40106);
       SaveDataToStream(FullSize,SizeOf(FullSize),ms,40107);
       SaveDataToStream(Blocks,SizeOf(Blocks),ms,40108);
       SaveDataToStream(BlockSize,SizeOf(BlockSize),ms,40109);
       Buffer := ms.Buffer;
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - InitProgressSend> SendBuffer');
{$ENDIF}
       SendBuffer(Buffer,ms.Size,MsgInitProgressSend);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - InitProgressSend> Sent!');
{$ENDIF}
     finally
       ms.Free;
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - InitProgressSend> ms freed');
{$ENDIF}
     end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_InitProgressSend_ReceiveResultFailed;
    try
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - InitProgressSend> ReceiveData...');
{$ENDIF}
      ReceiveData(Buffer,BufferSize);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - InitProgressSend> Received');
{$ENDIF}
      Result := MSG_Error_InitProgressSend_InvalidServerReply;
      if (Buffer = nil) or
         (BufferSize <> (SizeOf(TMsgCommandHeader)+SizeOf(Result))) then
       begin
        if (Buffer <> nil) then
         MemoryManager.FreeAndNilMem(Buffer);
        TMsgClient(FOwnerComponent).DoOnError(Result,-1,'Invalid server reply in InitProgressSend');
       end
      else
       begin
        try
          move((Buffer+SizeOf(TMsgCommandHeader))^, ObjectID, SizeOf(ObjectID));
          Result := MSG_COMMAND_OK;
        finally
          MemoryManager.FreeAndNilMem(Buffer);
        end;
       end;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
   end // Connected
  else
   TMsgClient(FOwnerComponent).DoOnError(Result);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - InitProgressSend> finished');
{$ENDIF}
end; // InitProgressSend


//------------------------------------------------------------------------------
// ChangeStatus
//------------------------------------------------------------------------------
procedure TMsgClientSession.ChangeStatus(UserID: Cardinal; NewStatus: TMsgUserStatus);
begin
  TMsgClient(FOwnerComponent).ChangeUserStatus(UserID,NewStatus);
end; // ChangeStatus


//------------------------------------------------------------------------------
// OnLineUser
//------------------------------------------------------------------------------
function TMsgClientSession.OnLineUser(UserID: Cardinal): Boolean;
begin
  ChangeStatus(UserID, msgOnLine);
  if (Assigned(TMsgClient(FOwnerComponent).FOnUserOnLine)) then
    TMsgClient(FOwnerComponent).FOnUserOnLine(UserID);
end; // OnLineUser


//------------------------------------------------------------------------------
// OffLineUser
//------------------------------------------------------------------------------
function TMsgClientSession.OffLineUser(UserID: Cardinal): Boolean;
begin
  ChangeStatus(UserID, msgOffLine);
  if (Assigned(TMsgClient(FOwnerComponent).FOnUserOffLine)) then
    TMsgClient(FOwnerComponent).FOnUserOffLine(UserID);
end; // OffLineUser


//------------------------------------------------------------------------------
// Send command
//------------------------------------------------------------------------------
function TMsgClientSession.SendCommand(
                                Command: TMsgMessageType;
                                Buffer: PAnsiChar;
                                Size: Integer
                                        ): Integer;
var
  ms:             TMsgMemoryStream;
  ServerID:       Integer;
  dt:             TDateTime;
  Pos:            Int64;
begin
  Result := MSG_Error_SendCommand_SendFailed;
  ms := TMsgMemoryStream.Create();
  try
    try
     ServerID := ConnectParams.ServerID;
     SaveDataToStream(ServerID,SizeOf(ServerID),ms,11569);
     SaveDataToStream(Command,SizeOf(Command),ms,11570);
     dt := Now;
     SaveDataToStream(dt,SizeOf(dt),ms,11391);
     Pos := ms.Position;
     SaveDataToStream(Size,SizeOf(Size),ms,11571);
     if (Size > 0) then
       SaveDataToStream(Buffer^,Size,ms,11572);
     SendMessage(ms.Buffer,ms.Size);
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
    Result := MSG_Error_SendCommand_SaveHistoryToDatabaseFailed;
    try
     if (TMsgClient(FOwnerComponent) <> nil) then
      if (TMsgClient(FOwnerComponent).FDatabase <> nil) and (TMsgClient(FOwnerComponent).StoreMessageHistory) then
       begin
        ms.Position := Pos;
        TMsgClient(FOwnerComponent).SaveMessageToDatabase(TMsgClient(FOwnerComponent).FDatabase,TMsgClient(FOwnerComponent).UserID,ServerID,Command,dt,True,Now,ms);
       end;
     Result := MSG_COMMAND_OK;
    except
     on e: EMsgException do
      TMsgClient(FOwnerComponent).DoOnError(Result,e.NativeError,e.Message);
     on e: Exception do
      TMsgClient(FOwnerComponent).DoOnError(Result,-1,e.Message)
     else
      TMsgClient(FOwnerComponent).DoOnError(Result);
     Exit;
    end;
  finally
   ms.Free;
  end;
end; // SendCommand


//------------------------------------------------------------------------------
// send custom message
//------------------------------------------------------------------------------
procedure TMsgClientSession.SendMessage(Buffer: PAnsiChar; BufferSize: Integer);
begin
  ClientConnectionManager.SendMessage(Self,Buffer,BufferSize);
end; // SendMessage


//------------------------------------------------------------------------------
// receive custom message from client
//------------------------------------------------------------------------------
procedure TMsgClientSession.ReceiveMessage(Buffer: PAnsiChar; BufferSize: Integer);
begin
  TMsgClient(FOwnerComponent).ReceiveMessage(Self, Buffer, BufferSize);
end; // ReceiveMessage


//------------------------------------------------------------------------------
// OnDisconnect
//------------------------------------------------------------------------------
procedure TMsgClientSession.OnDisconnect;
var
  UserInfo:       PMsgUserInfo;
  Contacts,
  Sessions:       TMsgList;
  Session:        TMsgClientSession;
  i, j:           Integer;
  Found:          Boolean;
begin
  Self.FConnected := False;
  Self.FLogged := False;
  if not Direct then
   begin
    if Assigned(FOnServerShutdown) then
      FOnServerShutdown(Self);
{
    Contacts := ContactsList.LockList;
    try
     for j:=0 to Contacts.Count-1 do
      begin
       UserInfo := Contacts.Items[j];
       if TMsgClient(FOwnerComponent).FindSessionWithUser(UserInfo.UserID)=nil then
         UserInfo.Status := MsgOffLine;
      end;
     if Assigned(FOnServerShutdown) then
       FOnServerShutdown(Self);
    finally
     ContactsList.UnlockList;
    end;
}
   end;
  TMsgClient(FOwnerComponent).OnDisconnect(Self);
  if not TMsgClient(FOwnerComponent).Connected then // no connection with server
    if Direct then              // remote client closed connection
     begin
      // search for other opened direct sessions
      Found := False;
      Sessions := TMsgClient(FOwnerComponent).FSessions.LockList;
      try
       for i:=0 to Sessions.Count-1 do
        begin
         Session := Sessions.Items[i];
         if Session.Direct then
           if Session<>TMsgClient(FOwnerComponent).FDefaultSession then
             if Session<>Self then
               if Session.Connected then
                begin
                 Found := True;
                 break;
                end;
        end;
      finally
       TMsgClient(FOwnerComponent).FSessions.UnlockList;
      end;
      if not Found then
        TMsgClient(FOwnerComponent).FConnectedDirectly := False
      else
       begin
        // search for other direct session with remote client
        Found := False;
        Sessions := TMsgClient(FOwnerComponent).FSessions.LockList;
        try
         for i:=0 to Sessions.Count-1 do
          begin
           Session := Sessions.Items[i];
           if Session.Direct then               // direct session
             if Session<>Self then                        // other, not the same
               if Session.Connected then                             // connected
                 if Session.RemoteUser <> nil then
                 if Session.RemoteUser.UserID = Self.RemoteUser.UserID then // to the same remote client
                  begin
                   Found := True;
                   break;
                  end;
          end;
        finally
         TMsgClient(FOwnerComponent).FSessions.UnlockList;
        end;
       end;
      if not Found then
        if TMsgClient(FOwnerComponent).FDefaultServerSession <> nil then
          TMsgClient(FOwnerComponent).FDefaultServerSession.OffLineUser(RemoteUser.UserID);
     end; // Direct
end; // OnDisconnect

// TMsgClientSession



////////////////////////////////////////////////////////////////////////////////
//
// TMsgShowMessageThread
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgShowMessageThread.Create(str: AnsiString);
begin
  FText := str;
  sleep (100);  // to avoid hungs in event handler
  inherited Create(False);
  Priority := tpNormal;
  FreeOnTerminate := True;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgShowMessageThread.Destroy;
begin
  inherited Destroy;
end;// Destroy;


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgShowMessageThread.Execute;
begin
  ShowMessage(FText);
end;

// TMsgShowMessageThread



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
aaWriteToLog('MsgClient> initializing...');
{$ENDIF}

  ClientConnectionManager := nil;

 InitCSect(CSect);

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
        (Pos('Embarcadero',WindowLst[i]) > 0) or
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
      (Reg.KeyExists('\Software\Codegear\BDS')) or
      (Reg.KeyExists('\Software\Embarcadero\BDS')) or
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
aaWriteToLog('MsgClient> initialized');
{$ENDIF}

finalization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgClient> finalizing...');
{$ENDIF}
 EnterCSect(CSect);
 if (ClientConnectionManager <> nil) then
  begin
   ClientConnectionManager.Free;
   ClientConnectionManager := nil;
  end;
 LeaveCSect(CSect);
 DeleteCSect(CSect);
 IsDesignMode := False;
{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgClient> finalized');
{$ENDIF}

end.
