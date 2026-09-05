{******************************************************************************}
{                                                                              }
{ Base internal classes                                                        }
{                                                                              }
{******************************************************************************}

unit MsgComBase;

interface

{$I MsgVer.inc}

uses Classes, SysUtils,
{$IFDEF MSWINDOWS}
     Windows,
     Forms,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
     QForms,
{$ENDIF}
{$IFNDEF D6H}
     FileCtrl,
{$ENDIF}
     ShellApi,
// MsgCommunicator units

{$IFDEF DEBUG_LOG}
     MsgDebug,
{$ENDIF}
     MsgMemory,
     MsgCompression,
     MsgCriticalSection,
     MsgCrypto,
     MsgConst,
     MsgTypes,
     MsgExcept;


const

  MSG_INVALID_USER_ID = $FFFFFFFF; // 4294967295;
  MSG_INVALID_ID  = $FFFFFFFF;

type
//  TMsgComponent = class;
  TMsgComBaseSession = class;

  // msgOffline must be = 0, other must be > 0
  // for changeuserstatus optimization with database modules
  TMsgUserStatus = (msgOffLine, msgOnLine, msgConnecting, msgConnected, msgNone);

  TMsgUserInfo = packed record
   UserID:        Cardinal;
   UserName:      ShortString;
   FirstName:     ShortString;
   LastName:      ShortString;
   Organization:  ShortString;
   Department:    ShortString;
   Status:        TMsgUserStatus;
   Host:          ShortString;
   Port:          Integer;
   Application:   ShortString;
  end;
  PMsgUserInfo = ^TMsgUserInfo;

  TMsgBaseUserInfo = packed record
   UserInfo:        TMsgUserInfo;
   PasswordHeader:  TMsgCryptoHeader;
  end;
  PMsgBaseUserInfo = ^TMsgBaseUserInfo;

  TMsgContactInfo = packed record
   UserInfo:          TMsgUserInfo;
   ContactNameSource: TMsgContactNameSource;
   ContactCustomName: ShortString;
  end; // TMsgContactInfo
  PMsgContactInfo = ^TMsgContactInfo;

  TMsgUserInfoArray = array of TMsgUserInfo;
  TMsgContactInfoArray = array of TMsgContactInfo;
  // sort fields
  TMsgUserInfoArraySortBy = (msgusbNone,msgusbUserID,msgusbUserName,
    msgusbFirstName,msgusbLastName,msgusbStatus,msgusbHost,msgusbPort,msgusbApplication);

// Client/Server events

  TMsgOnUserOnLine = procedure (const UserID: Cardinal) of object;
  TMsgOnUserOffLine = procedure (const UserID: Cardinal) of object;

//  TMsgOnDisconnectUser = procedure of object;

  TMsgOnReceiveTextMessage = procedure (const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const Text: AnsiString)  of object;
  TMsgOnReceiveUnicodeTextMessage = procedure (const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const Text: WideString)  of object;
  TMsgOnReceiveBinaryMessage = procedure (const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; Buffer: PAnsiChar; Size: Integer) of object;
  TMsgOnReceiveStreamMessage = procedure (const FromUserID: Cardinal; const SendingDate,DeliveryDate: TDateTime; Stream: TStream) of object;

  TMsgOnReceiveCommand = procedure (const FromID, Command: Cardinal; const SendingDate,DeliveryDate: TDateTime; Buffer: PAnsiChar; Size: Integer) of object;

  TMsgOnReceiveFile = procedure (const FromUserID, FileID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const FileName: AnsiString; FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean) of object;
  TMsgOnReceiveStream = procedure (const FromUserID, StreamID: Cardinal; const SendingDate,DeliveryDate: TDateTime; FullSize: Int64; BlockSize, BlockNo, Blocks: Integer; Directly: Boolean) of object;

  TMsgOnFileReceived = procedure (const FromUserID, FileID: Cardinal; const SendingDate,DeliveryDate: TDateTime; const FileName: AnsiString; FullSize: Int64; Directly: Boolean) of object;
  TMsgOnStreamReceived = procedure (const FromUserID, StreamID: Cardinal; const SendingDate,DeliveryDate: TDateTime; FullSize: Int64; Directly: Boolean) of object;

  TMsgOnSaveMessage = procedure (
                        const SenderID:           Cardinal;
                        const RecipientID:        Cardinal;
                        const MessageType:        TMsgMessageType;
                        const SendingDate:        TDateTime;
                        const DeliveryDate:       TDateTime;
                        const MessageData:        PAnsiChar;
                        const MessageDataSize:    Integer;
                        var   MessageText:        AnsiString;
                        var   MessageUnicodeText: WideString;
                        const Command:            Cardinal
                      ) of object;

  TMsgOnSendFile = procedure (const ToUserID, FileID: Cardinal; const FileName: AnsiString; FullSize: Int64; BlockSize, BlockNo, Blocks: Integer) of object;
  TMsgOnSendStream = procedure (const ToUserID, StreamID: Cardinal; FullSize: Int64; BlockSize, BlockNo, Blocks: Integer) of object;

  TMsgSendObject = packed record
   ToUserID:        Cardinal;
   ObjectID:        Cardinal;
   ObjectType:      TMsgMessageType;
   Stream:          TStream;
   StreamPosition:  Integer;
   FileName:        AnsiString;
   CurrentBlock:    Integer;
   Blocks:          Integer;
   BlockSize:       Integer;
   Directly:        Boolean;
  end;
  PMsgSendObject = ^TMsgSendObject;

  TMsgRecvObject = packed record
   ObjectID:        Cardinal;
   ObjectType:      TMsgMessageType;
   FileName:        AnsiString;
   FullSize:        Int64;
   Blocks:          Integer;
   BlockSize:       Integer;
   Directly:        Boolean;
   SendingDate:     TDateTime;
  end;
  PMsgRecvObject = ^TMsgRecvObject;

  TMsgSendLargeObjectThread = class;

  TMsgOnError = procedure (
                       Sender:             TComponent;
                       const ErrorCode:    Integer;
                       const NativeError:  Integer;
                       const ErrorMessage: AnsiString
                     ) of object;



////////////////////////////////////////////////////////////////////////////////
//
// TMsgComponent
//
////////////////////////////////////////////////////////////////////////////////

 TMsgComponent = class (TComponent)
  protected
    FObjectID:                    Cardinal;
    FOnError:                     TMsgOnError;
    FSslash:                      AnsiChar;
// for large object receiving
    FAllowFiles:                  Boolean;
    FIncomingPath:                AnsiString;
// for large object sending/receiving with progress support
    FOnSendFileFailed,
    FOnSendFile:                  TMsgOnSendFile;
    FOnSendStreamFailed,
    FOnSendStream:                TMsgOnSendStream;
    FOnReceiveFile:               TMsgOnReceiveFile;
    FOnReceiveStream:             TMsgOnReceiveStream;
//    FOnFileReceived:              TMsgOnFileReceived;
//    FOnStreamReceived:            TMsgOnStreamReceived;
    FSendThread:                  TMsgSendLargeObjectThread;
    FSendQueue:                   TMsgThreadList;
    FRecvQueue:                   TMsgThreadList;
// for messaging
    FOnSaveMessage:               TMsgOnSaveMessage;
    FOnReceiveTextMessage:        TMsgOnReceiveTextMessage;
    FOnReceiveUnicodeTextMessage: TMsgOnReceiveUnicodeTextMessage;
    FOnReceiveBinaryMessage:      TMsgOnReceiveBinaryMessage;
    FOnReceiveStreamMessage:      TMsgOnReceiveStreamMessage;
    FOnReceiveCommand:            TMsgOnReceiveCommand;
    FCSect:                       TRTLCriticalSection;
  protected
    procedure RecvFileMsg(
                                    ms: TMsgMemoryStream;
                                    out RecvObject: PMsgRecvObject;
                                    var len, BlockNo: Integer;
                                    var ObjectID: Cardinal;
                                    SendingDate: TDateTime
                                    );
    procedure RecvInitLOMsg(
                                      ms: TMsgMemoryStream;
                                      out RecvObject:   PMsgRecvObject
                                      );
    procedure DelTempFiles;
    procedure SetIncomingPath(value: AnsiString);
    procedure SetAllowFiles(Value: Boolean);
    procedure PrepareToSendWithProgress(
                                  Size: Int64;
                                  var Blocks: Integer;
                                  var BlockSize: Integer);
    procedure AddNewSendObject(
                                          SendObject:     PMsgSendObject;
                                          ToID, ObjectID: Cardinal;
                                          ObjectType: TMsgMessageType;
                                          const FileName: AnsiString;
                                          Stream: TStream;
                                          Blocks: Integer;
                                          BlockSize: Integer;
                                          Directly: Boolean
                                         );
    procedure CallSendEvent(
                                          ToID, ObjectID: Cardinal;
                                          ObjectType: TMsgMessageType;
                                          const FileName: AnsiString;
                                          Size: Integer;
                                          Blocks: Integer;
                                          BlockSize: Integer
                                         );
    function FreeSpaceOnDisk(DiskName: AnsiString = ''): Int64;
    procedure LoadBaseUserInfoFromStream(BaseUserInfo: PMsgBaseUserInfo; Stream: TStream);
    procedure SaveBaseUserInfoToStream(BaseUserInfo: PMsgBaseUserInfo; Stream: TStream);
    procedure LoadUserInfoFromStream(var UserInfo: TMsgUserInfo; Stream: TStream);
    procedure SaveUserInfoToStream(var UserInfo: TMsgUserInfo; Stream: TStream);
    procedure LoadContactInfoFromStream(var ContactInfo: TMsgContactInfo; Stream: TStream);
    procedure SaveContactInfoToStream(var ContactInfo: TMsgContactInfo; Stream: TStream);
    procedure LoadBaseContactInfoFromStream(var ContactInfo: TMsgContactInfo; Stream: TStream);
    procedure SaveBaseContactInfoToStream(var ContactInfo: TMsgContactInfo; Stream: TStream);
    procedure LoadContactsFromStream(var Contacts: TMsgContactInfoArray; Stream: TStream);
    procedure SaveContactsToStream(var Contacts: TMsgContactInfoArray; Stream: TStream);
    // save message to database and return MessageID
    function SaveMessageToDatabase(
                                    Database:     TComponent;
                                    SenderID:     Cardinal;
                                    RecipientID:  Cardinal;
                                    MessageType:  TMsgMessageType;
                                    SendingDate:  TDateTime;
                                    Delivered:    Boolean;
                                    DeliveryDate: TDateTime;
                                    Stream:       TMsgMemoryStream
                                   ): Integer;
    procedure DoOnError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer = -1;
                       const ErrorMessage: AnsiString = ''
                       ); virtual;
    function GetCurrentVersion: AnsiString;
    procedure SetCurrentVersion(value: AnsiString);
    function SetPath(value: AnsiString): AnsiString;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetContactDisplayName(const ContactInfo: TMsgContactInfo): AnsiString;
protected
    function SendWithProgress(ToUserID: Cardinal;
                                        ObjectType: TMsgMessageType;
                                        const FileName: AnsiString;
                                        Stream: TStream;
                                        Blocks: Integer;
                                        BlockSize: Integer;
                                        Directly: Boolean): Integer; virtual; abstract;
public
{
    function SendMessage(ToUserID: Cardinal; Buffer: PAnsiChar; Size: Integer;
                                        Directly: Boolean = True;
                                        MessageType: TMsgMessageType = aamtBinary
                         ): Integer; overload; virtual; abstract;
}
    function SendFile(ToUserID: Cardinal; const FileName: AnsiString;
                                        Blocks: Integer = 0;
                                        BlockSize: Integer = 0;
                                        Directly: Boolean = True): Integer;
    function ReceiveFile(FileID: Cardinal; const FileName: AnsiString; TimeOut: Integer = 0): Integer;

{ TODO -oRay : Implement it -  SendFile scheme #2 }
//    procedure SaveFile(FileID: Cardinal; const FileName: AnsiString; CallBackEventHandler: TMsgOnFileReceived);
    function SendStream(ToUserID: Cardinal;
                                        Stream: TStream;
                                        Blocks: Integer = 0;
                                        BlockSize: Integer = 0;
                                        Directly: Boolean = True): Integer;
{ TODO -oRay : Implement it -  SendStream }
//    function ReceiveStream(StreamID: Cardinal; Stream: TStream; TimeOut: Integer = 0): Integer;
{ TODO -oRay : Implement it -  SendStream scheme #2 }
//    procedure SaveStream(StreamID: Cardinal; CallBackEventHandler: TMsgOnStreamReceived);
  published
    property CurrentVersion: AnsiString read GetCurrentVersion write SetCurrentVersion;
    property OnSaveMessage: TMsgOnSaveMessage read FOnSaveMessage write FOnSaveMessage;
    property OnError: TMsgOnError read FOnError write FOnError;
    property AllowFiles: Boolean read FAllowFiles write SetAllowFiles default True;
    property IncomingPath: AnsiString read FIncomingPath write SetIncomingPath;
// OnReceive
    property OnReceiveTextMessage: TMsgOnReceiveTextMessage read FOnReceiveTextMessage write FOnReceiveTextMessage;
    property OnReceiveUnicodeTextMessage: TMsgOnReceiveUnicodeTextMessage read FOnReceiveUnicodeTextMessage write FOnReceiveUnicodeTextMessage;
    property OnReceiveBinaryMessage: TMsgOnReceiveBinaryMessage read FOnReceiveBinaryMessage write FOnReceiveBinaryMessage;
    property OnReceiveStreamMessage: TMsgOnReceiveStreamMessage read FOnReceiveStreamMessage write FOnReceiveStreamMessage;
    property OnReceiveCommand: TMsgOnReceiveCommand read FOnReceiveCommand write FOnReceiveCommand;
// OnReceive for large objects
    property OnReceiveFile: TMsgOnReceiveFile read FOnReceiveFile write FOnReceiveFile;
    property OnReceiveStream: TMsgOnReceiveStream read FOnReceiveStream write FOnReceiveStream;
{ TODO -oRay : Implement it -  scheme #2 }
//    property OnFileReceived: TMsgOnFileReceived read FOnFileReceived write FOnFileReceived;
//    property OnStreamReceived: TMsgOnStreamReceived read FOnStreamReceived write FOnStreamReceived;
// OnSend for large objects
    property OnSendFile: TMsgOnSendFile read FOnSendFile write FOnSendFile;
    property OnSendFileFailed: TMsgOnSendFile read FOnSendFileFailed write FOnSendFileFailed;
    property OnSendStream: TMsgOnSendStream read FOnSendStream write FOnSendStream;
    property OnSendStreamFailed: TMsgOnSendStream read FOnSendStreamFailed write FOnSendStreamFailed;
 end; // TMsgComponent



////////////////////////////////////////////////////////////////////////////////
//
// TMsgComBaseSession
//
////////////////////////////////////////////////////////////////////////////////

  TMsgComBaseSession = class (TObject)
   private
    FSessionID:                 TMsgSessionID;
   protected
    FConnected:                 Boolean;
   public
    FUserID:                    Cardinal;
    FConnectParams:             TMsgConnectParams;
   protected
    procedure SetConnected(value: boolean); virtual; abstract;
    // send custom message
    procedure SendMessage(Buffer: PAnsiChar; BufferSize: Integer); virtual; abstract;
   public
    // constructor
    constructor Create;
    // destructor
    destructor Destroy; override;
    procedure DoOnError(ErrorCode: Integer; NativeError: Integer = -1; ErrorMessage: AnsiString = ''); virtual; abstract;
    procedure DoCloseSessionOnNetworkError; virtual; abstract;
    procedure SaveCommandHeader(
                                Stream:         TStream;
                                CommandCode:    Integer;
                                CommandResult:  Integer = 0;
                                NativeError:    Integer = 0
                                );
    function ConnectUser(UserID: Cardinal; Host: AnsiString; Port: Integer):
                                          TMsgComBaseSession; virtual;
    function ConnectedUser(UserID: Cardinal; Host: AnsiString; Port: Integer): Boolean;
                                                              virtual;

{
(*****************************************************************************)
(*  COMMANDS                                                                 *)
(*****************************************************************************)
    // connect this client to server
    procedure Connect; virtual; abstract;
    // disconnect this client from server
    procedure Disconnect; virtual; abstract;
    // connect user to this client
    function ConnectUser(UserID: Cardinal): Boolean; virtual; abstract;
    // disconnect user from this client
    function DisconnectUser(UserID: Cardinal): Boolean; virtual; abstract;
    // determine if user exists at server
    function GetUserInfo(UserID: Cardinal): TMsgBaseUserInfo; virtual; abstract;
    // register new user at server
    function RegisterNewUser(UserInfo: TMsgBaseUserInfo): Boolean; virtual; abstract;
    // add user to Contacts list of this client
    function AddUserToMyContacts(UserID: Cardinal): Boolean; virtual; abstract;
    // remove user from Contacts list of this client
    function RemoveUserFromMyContacts(UserID: Cardinal): Boolean; virtual; abstract;
    // get list of Contacts of this client from server
    procedure GetMyContactsList; virtual; abstract;
(*****************************************************************************)
}
    // send buffer with command in it via established connection using connection manager
    procedure SendBuffer(Buffer: PAnsiChar; BufferSize: Integer; Code: Integer); virtual; abstract;
    // receive command
    procedure ReceiveData(var Buffer: PAnsiChar; var BufferSize: Integer); virtual; abstract;
    // receive custom message
    procedure ReceiveMessage(Buffer: PAnsiChar; BufferSize: Integer); virtual; abstract;
//    procedure OnDisconnect; virtual; abstract;
  public
    property SessionID: TMsgSessionID read FSessionID write FSessionID;
    property UserID: Cardinal read FUserID;
    property Connected: Boolean read FConnected write SetConnected;
    property ConnectParams: TMsgConnectParams read FConnectParams write FConnectParams;
  end; // TMsgComBaseSession


////////////////////////////////////////////////////////////////////////////////
//
// TMsgNetworkSession
//
////////////////////////////////////////////////////////////////////////////////

 TMsgNetworkSession = class(TMsgComBaseSession)
  public
   FOwnerComponent:         TMsgComponent;
  protected
   FLogged:                 Boolean;
   procedure SetLogged(value: boolean); virtual; abstract;
   function InitProgressSend(ObjectType: TMsgMessageType;
                              ToUserID: Cardinal;
                              const FileName: AnsiString;
                              FullSize: Int64;
                              Blocks: Integer;
                              BlockSize: Integer;
                              var ObjectID: Cardinal
                              ): Integer; virtual; abstract;
 public
   // constructor
   constructor Create(AOwner: TComponent);
   // destructor
   destructor Destroy; override;
  public
   property Logged: Boolean read FLogged write SetLogged;
 end; // TMsgNetworkSession



////////////////////////////////////////////////////////////////////////////////
//
// TMsgSendLargeObjectThread
//
////////////////////////////////////////////////////////////////////////////////

  TMsgSendLargeObjectThread = class(TMsgThread)
  private
    FOwnerComponent:                  TMsgComponent;
    Error:                    AnsiString;
  protected
    procedure Execute; override;
    function SendBlock(
                        SendObject:           PMsgSendObject;
                        Buffer:               PAnsiChar;
                        Size:                 Integer
                        ): Integer;
    procedure RemoveObject(SendObject: PMsgSendObject);
    procedure AbortBlock(SendObject: PMsgSendObject);
    procedure AbortObject(SendObject: PMsgSendObject);
  public
    constructor Create(
                        Owner:          TMsgComponent
                       );
    destructor Destroy; override;
  public
  end;// TMsgSendLargeObjectThread

implementation

uses
{$IFDEF SERVER_VERSION}
  MsgServer,
{$ENDIF}
{$IFDEF CLIENT_VERSION}
  MsgClient,
{$ENDIF}
  MsgComMain, MsgConnection, MsgDatabase;

////////////////////////////////////////////////////////////////////////////////
//
// TMsgComponent
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgComponent.Create(AOwner: TComponent);
var
  path:  AnsiString;
begin
  AllowFiles := True;
  FObjectID := MSG_INVALID_ID;
  path := ExtractFilePath(ParamStr(0));
  Move((PAnsiChar(path)+Length(path)-1)^, FSslash, 1);
  InitializeCriticalSection(FCSect);
  inherited;
  if (not IsDesignMode) then
   if (AOwner <> nil) then
    if (csDesigning in AOwner.ComponentState) then
      IsDesignMode := true;
end;// Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgComponent.Destroy;
begin
  DeleteCriticalSection(FCSect);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// SetPath
//------------------------------------------------------------------------------
function TMsgComponent.SetPath(value: AnsiString): AnsiString;
var
  AppPath:    AnsiString;
begin
  if (csDesigning in ComponentState) then
    Result := value
  else
   begin
    AppPath := ExtractFilePath(ParamStr(0));
    if pos('.'+FSslash,value) = 1 then // from application dir
      Result :=  AppPath + copy(value,3,length(value)-2)
    else
      Result := value;
    if not DirectoryExists(Result) then
      ForceDirectories(Result);
   end;
end;// SetPath


//------------------------------------------------------------------------------
// DelTempFiles
//------------------------------------------------------------------------------
procedure TMsgComponent.DelTempFiles;
var
//  errText: array [1..255] of Char;
//  pc: Pchar absolute errText;
  res: Boolean;
  SEInfo: TShellExecuteInfo;
begin
  FillChar(SEInfo, SizeOf(SEInfo), 0);
  SEInfo.cbSize := SizeOf(TShellExecuteInfo);
  with SEInfo do begin
    fMask := SEE_MASK_NOCLOSEPROCESS;
    Wnd := Application.Handle;
    lpFile := PChar('cmd');
    lpParameters := PChar('/c del "'+FIncomingPath+'"*.* /q');
    nShow := SW_HIDE;
  end;
  res := ShellExecuteEx(@SEInfo);
  if res then
    WaitForSingleObject(SEInfo.hProcess, INFINITE);
end;// DelTempFiles


//------------------------------------------------------------------------------
// SetIncomingPath
//------------------------------------------------------------------------------
procedure TMsgComponent.SetIncomingPath(value: AnsiString);
begin
  if value <> FIncomingPath then
   begin
    FIncomingPath := SetPath(value);
    if not DirectoryExists(FIncomingPath) then
      ForceDirectories(FIncomingPath);
   end;
end;// SetIncomingPath


//------------------------------------------------------------------------------
// SetAllowReceiveFiles
//------------------------------------------------------------------------------
procedure TMsgComponent.SetAllowFiles(Value: Boolean);
var
  List:             TMsgList;
  i:                Integer;
  StartTime:        Cardinal;
begin
  if FAllowFiles = Value then
    Exit;
  if Value then
   begin
    FSendQueue := TMsgThreadList.Create;
    FRecvQueue := TMsgThreadList.Create;
//    if FSendThread = nil then
//      FSendThread := TMsgSendLargeObjectThread.Create(self);
   end
  else
   begin
    List:=FSendQueue.LockList;
    try
     if FSendThread <> nil then
       FSendThread.Terminate;
     sleep(0);

  // wait for Terminate FSendThread
  StartTime := GetTickCount;
  repeat
   if (FSendThread=nil)
    then break
    else
     begin
      if (GetTickCount - StartTime) > MsgThreadsTerminateDelay then
       begin
{
        Error := 'send with progress thread';
        raise EMsgException.Create(40036, ErrorRThreadHangs,
        ['client session # '+IntToStr(ClientSession.Session.SessionID),
          Error]);
}
       end;
     end;
   sleep(0);
  until False;

     for i:=List.Count-1 downto 0 do
      begin
       Dispose(List.Items[i]);
       List.Delete(i);
      end;
    finally
     FSendQueue.UnLockList;
    end;
    FSendQueue.Free;

    List:=FRecvQueue.LockList;
    try
{
     if FRecvThread <> nil then
       FRecvThread.Terminate;
     sleep(0);
}
     for i:=List.Count-1 downto 0 do
      begin
       Dispose(List.Items[i]);
       List.Delete(i);
      end;
    finally
     FRecvQueue.UnLockList;
    end;
    FRecvQueue.Free;

    // Delete files

   end;
  FAllowFiles := Value;
end; // SetAllowReceiveFiles


//------------------------------------------------------------------------------
// AddNewSendObject
//------------------------------------------------------------------------------
procedure TMsgComponent.AddNewSendObject(
                                          SendObject:     PMsgSendObject;
                                          ToID, ObjectID: Cardinal;
                                          ObjectType: TMsgMessageType;
                                          const FileName: AnsiString;
                                          Stream: TStream;
                                          Blocks: Integer;
                                          BlockSize: Integer;
                                          Directly: Boolean
                                         );
begin
  if Stream.Size = 0 then
    Exit;
  New(SendObject);
  SendObject.ToUserID := ToID;
  SendObject.ObjectID := ObjectID;
  SendObject.Stream := Stream;
  SendObject.ObjectType := ObjectType;
  if ObjectType = aamtsFile then
    SendObject.FileName := FileName;
  if ObjectType = aamtsStream then
    SendObject.StreamPosition := Stream.Position;
  SendObject.CurrentBlock := 0;
  SendObject.Blocks := Blocks;
  SendObject.BlockSize := BlockSize;
  SendObject.Directly := Directly;
  FSendQueue.Add(SendObject);
  EnterCriticalSection(FCSect);
  try
   if FSendThread = nil then
     FSendThread := TMsgSendLargeObjectThread.Create(self);
  finally
   LeaveCriticalSection(FCSect);
  end;
end; // AddNewSendObject


//------------------------------------------------------------------------------
// CallSendEvent
//------------------------------------------------------------------------------
procedure TMsgComponent.CallSendEvent(
                                          ToID, ObjectID: Cardinal;
                                          ObjectType: TMsgMessageType;
                                          const FileName: AnsiString;
                                          Size: Integer;
                                          Blocks: Integer;
                                          BlockSize: Integer
                                         );
begin
  if ObjectType = aamtsFile then
    if Assigned(FOnSendFile) then
      FOnSendFile(ToID,ObjectID,FileName,Size,BlockSize,-1,Blocks)
  else
    if Assigned(FOnSendStream) then
      FOnSendStream(ToID,ObjectID,Size,BlockSize,-1,Blocks);
end; // CallSendEvent


//------------------------------------------------------------------------------
// PrepareToSendWithProgress
//------------------------------------------------------------------------------
procedure TMsgComponent.PrepareToSendWithProgress(
                                  Size: Int64;
                                  var Blocks: Integer;
                                  var BlockSize: Integer);
var
  MessageHeaderLen:   Integer;
begin
  MessageHeaderLen :=
                        // Packet Header
    SizeOf(TMsgPacketHeader)+
                        // Binary Message Header
    SizeOf(Cardinal)+           // ToUserID
    SizeOf(TMsgMessageType)+    // const aamtBinary
    SizeOf(TDateTime)+          // SendingTime
    SizeOf(Integer)+            // BufferSize
                        // Object parameters
    SizeOf(Cardinal)+           // ObjectID
    SizeOf(Integer);            // CurrentBlock
  if Blocks <= 0 then
   begin
    if BlockSize < (MsgMinPacketSize - MessageHeaderLen) then
      BlockSize := MsgDefaultPacketSize - MessageHeaderLen;
    Blocks := Size div BlockSize;
    if (Size mod BlockSize) <> 0 then
      inc(Blocks);
   end
  else
   begin
    BlockSize := Size div Blocks;
    BlockSize := BlockSize + MessageHeaderLen;
    if (Size mod Blocks) <> 0 then
      inc(BlockSize);
   end;
end;// PrepareToSendWithProgress


//------------------------------------------------------------------------------
// SendFile
//------------------------------------------------------------------------------
function TMsgComponent.SendFile(
                                  ToUserID: Cardinal;
                                  const FileName: AnsiString;
                                  Blocks: Integer = 0;
                                  BlockSize: Integer = 0;
                                  Directly: Boolean = True
                                  ): Integer;
var
  fs:     TMsgFileStream;
  i:      Integer;
  str:    AnsiString;
begin
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - send start');
{$ENDIF}
  fs := TMsgFileStream.Create(FileName,fmOpenRead + fmShareDenyWrite);
  i := LastDelimiter(FSslash, FileName);
  str := Copy(FileName,i+1,Length(FileName)-i);
  Result := SendWithProgress(ToUserID,aamtsFile,str,fs,Blocks,BlockSize,Directly);
end; // SendFile


//------------------------------------------------------------------------------
// RecvInitLOMsg
//------------------------------------------------------------------------------
procedure TMsgComponent.RecvInitLOMsg(
                                      ms: TMsgMemoryStream;
                                      out RecvObject:   PMsgRecvObject
                                      );
begin
 if AllowFiles then
  begin
   new(RecvObject);
   RecvObject.SendingDate := 0;
   LoadDataFromStream(RecvObject.ObjectID,SizeOf(RecvObject.ObjectID),ms,40114);
   LoadDataFromStream(RecvObject.ObjectType,SizeOf(RecvObject.ObjectType),ms,40115);
   if RecvObject.ObjectType = aamtsFile then
     LoadStringFromStream(RecvObject.FileName,ms,40127)
   else
     RecvObject.FileName := '';
   LoadDataFromStream(RecvObject.FullSize,SizeOf(RecvObject.FullSize),ms,40128);
   LoadDataFromStream(RecvObject.Blocks,SizeOf(RecvObject.Blocks),ms,40116);
   LoadDataFromStream(RecvObject.BlockSize,SizeOf(RecvObject.BlockSize),ms,40117);
  end;
end; // RecvInitLOMsg


//------------------------------------------------------------------------------
// RecvFileMsg
//------------------------------------------------------------------------------
procedure TMsgComponent.RecvFileMsg(
                                    ms: TMsgMemoryStream;
                                    out RecvObject: PMsgRecvObject;
                                    var len, BlockNo: Integer;
                                    var ObjectID: Cardinal;
                                    SendingDate:  TDateTime
                                    );
var
  fs:           TMsgFileStream;
  FileName:     AnsiString;
  i,
  FileHandle:   Integer;
  Queue:        TMsgList;
begin
RecvObject := nil;
if AllowFiles then
 begin
  LoadDataFromStream(len,SizeOf(len),ms,10270);
  LoadDataFromStream(ObjectID,SizeOf(ObjectID),ms,40110);
  LoadDataFromStream(BlockNo,SizeOf(BlockNo),ms,40111);
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> Received!');
aaWriteToLog(IntToStr(BlockNo)+'> ObjectID = '+IntToStr(ObjectID));
aaWriteToLog(IntToStr(BlockNo)+'> len = '+IntToStr(len));
{$ENDIF}
  len := len - SizeOf(ObjectID) - SizeOf(BlockNo);
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> len = '+IntToStr(len));
{$ENDIF}
  if (len > 0) then
   begin
     FileName := IncomingPath+IntToStr(ObjectID)+'-'+IntToStr(BlockNo)+MSG_BLOCK_EXT;
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> FileName = "'+FileName+'"');
{$ENDIF}
     if (FreeSpaceOnDisk > len) then
       if not aaFileExists(PAnsiChar(FileName)) then
        begin // save Buf
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> Create...');
{$ENDIF}
         FileHandle := FileCreate(FileName);
         if (FileHandle <> 0) then
           FileClose(FileHandle);
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> OpenWrite...');
{$ENDIF}
         fs := TMsgFileStream.Create(FileName, fmOpenWrite + fmShareExclusive,10000);
         try
          fs.Size := len;
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> Write...');
{$ENDIF}
          SaveDataToStream((ms.Buffer+ms.Position)^,len,fs,40113);
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> Saved!');
{$ENDIF}
         finally
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> CloseWrite...');
{$ENDIF}
          fs.Free;
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(BlockNo)+'> Closed!!!');
{$ENDIF}
         end;
         Queue := FRecvQueue.LockList;
         try
          for i:=0 to Queue.Count-1 do
           begin
            RecvObject := Queue.Items[i];
            if RecvObject.ObjectID = ObjectID then
             begin
              if RecvObject.SendingDate = 0 then
                RecvObject.SendingDate := SendingDate;
              break;
             end;
           end;
         finally
          FRecvQueue.UnlockList;
         end;
        end;   // save Buf
   end;
 end;
end; // RecvFileMsg


//------------------------------------------------------------------------------
// ReceiveFile
//------------------------------------------------------------------------------
function TMsgComponent.ReceiveFile(FileID: Cardinal; const FileName: AnsiString; TimeOut: Integer = 0): Integer;
var
  fsb,
  fs:             TMsgFileStream;
  Queue:          TMsgList;
  Delay,
  StartTime:      Cardinal;
  i:              Integer;
  RecvFile:       PMsgRecvObject;
  found:          Boolean;
  BlockFileName:  AnsiString;
  buf:            PAnsiChar;
  FileHandle:     Integer;
  SaveFileName:   AnsiString;
begin // ReceiveFile
  Result := MSG_Error_ReceiveFile_NotExists;
  found := false;
  Queue := FRecvQueue.LockList;
  try
   for i:=0 to Queue.Count-1 do
    begin
     RecvFile := Queue.Items[i];
     if RecvFile.ObjectID = FileID then
      begin
       found := true;
       break;
      end;
    end;
   if not found then
     Exit;
  finally
   FRecvQueue.UnlockList;
  end;

  Result := MSG_Error_ReceiveFile_DiskFull;
  if FreeSpaceOnDisk(FileName) < RecvFile.FullSize then
    Exit;

  Result := MSG_Error_ReceiveFile_FileExists;
  // make unique file name to allow receiving the same file more than once
  SaveFileName := FileName;
  i := 0;
  while i < MsgMaxFilesToSend do
    if not aaFileExists(PAnsiChar(SaveFileName)) then
      break
    else
     begin
      SaveFileName := SaveFileName + '-';
      inc(i);
     end;
  if aaFileExists(PAnsiChar(SaveFileName)) then
    Exit;

  Result := MSG_Error_ReceiveFile_CannotCreateFile;
  FileHandle := FileCreate(SaveFileName);
  if (FileHandle <> 0) then
    FileClose(FileHandle)
  else
    Exit;

{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(FileID)+'- > '+SaveFileName);
{$ENDIF}
  Result := 0;
  if RecvFile.FullSize > 0 then
   begin
    fs := TMsgFileStream.Create(SaveFileName, fmOpenWrite + fmShareDenyWrite);
    try
     fs.Size := RecvFile.FullSize;
     if TimeOut <= 0 then
       TimeOut := MAXINT;
     StartTime := GetTickCount;
     buf := MemoryManager.GetMem(RecvFile.BlockSize);
     try
      for i := 0 to RecvFile.Blocks - 1 do
       begin
        BlockFileName := IncomingPath+IntToStr(FileID)+'-'+IntToStr(i)+MSG_BLOCK_EXT;
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> BlockFileName="'+BlockFileName+'"');
  {$ENDIF}
        while not aaFileExists(PAnsiChar(BlockFileName)) do
         begin
          if (GetTickCount - StartTime) > TimeOut then
           begin
            Result := MSG_Error_ReceiveFile_TimeOut;
            Exit;
           end;
          sleep(1); // allow save block; needs 1 to avoid high CPU usage, but the best value for speed is 0
          Application.ProcessMessages; // for calling from form
         end;
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> OpenRead... ');
  {$ENDIF}
        Delay := 0;
        fsb := TMsgFileStream.Create(BlockFileName,fmOpenRead + fmShareDenyNone,10000); // fmOpenRead + fmShareDenyWrite
        while fsb.Size = 0 do
         begin
          fsb.Free;
          if (GetTickCount - StartTime) > TimeOut then
           begin
            Result := MSG_Error_ReceiveFile_TimeOut;
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> Wrong size, sleep time out!');
  {$ENDIF}
            Exit;
           end;
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> Wrong size, sleep to allow write: '+IntToStr(Delay));
  {$ENDIF}
          sleep(Delay);
          Delay := Delay * 10 + 1;
          fsb := TMsgFileStream.Create(BlockFileName,fmOpenRead + fmShareDenyNone,10000);
         end;
        try
         if (i+1) = RecvFile.Blocks then // last block length can be less
          begin
           if fsb.Size > RecvFile.BlockSize then
            begin
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> Wrong size = '+IntToStr(fsb.Size));
  {$ENDIF}
             Result := MSG_Error_ReceiveFile_BlockSize;
             Exit;
            end;
          end
         else // others must be equal to BlockSize
           if fsb.Size <> RecvFile.BlockSize then
            begin
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> Wrong size = '+IntToStr(fsb.Size));
  {$ENDIF}
             Result := MSG_Error_ReceiveFile_BlockSize;
             Exit;
            end;
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> Read...');
  {$ENDIF}
           fsb.ReadBuffer(buf^,fsb.Size);
           fs.WriteBuffer(buf^,fsb.Size);
           Result := Result + fsb.Size;
        finally
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> CloseRead...');
  {$ENDIF}
         fsb.Free;
        end;
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> Delete...');
  {$ENDIF}
        DeleteFileA(PAnsiChar(BlockFileName));
  {$IFDEF LOG_RECV_FILE}
  aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> Deleted!');
  {$ENDIF}
       end;
     finally
      MemoryManager.FreeAndNilMem(buf);
     end;
    finally
     fs.Free;
    end;
   end; // size>0
  if Result = RecvFile.FullSize then
   begin
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> Remove file from queue...');
{$ENDIF}
    Queue.Remove(RecvFile);
    RecvFile.ObjectID := 0; // object can be still in use
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> sleep...');
{$ENDIF}
    sleep(0);
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> dispose...');
{$ENDIF}
    Dispose(RecvFile);
{$IFDEF LOG_RECV_FILE}
aaWriteToLog(IntToStr(FileID)+'-'+IntToStr(i)+'> new...');
{$ENDIF}
   end;
end; // ReceiveFile

{
//------------------------------------------------------------------------------
// SaveFile
//------------------------------------------------------------------------------
procedure TMsgComponent.SaveFile(FileID: Cardinal; const FileName: AnsiString; CallBackEventHandler: TMsgOnFileReceived);
begin
end; // SaveFile
}

//------------------------------------------------------------------------------
// SendStream
//------------------------------------------------------------------------------
function TMsgComponent.SendStream(
                                  ToUserID: Cardinal;
                                  Stream: TStream;
                                  Blocks: Integer = 0;
                                  BlockSize: Integer = 0;
                                  Directly: Boolean = True
                                  ): Integer;
var
  str:            AnsiString;
begin
  str := '';
  Result := SendWithProgress(ToUserID,aamtsStream,str,Stream,Blocks,BlockSize,Directly);
end; // SendStream


//------------------------------------------------------------------------------
// FreeSpaceOnDisk
//------------------------------------------------------------------------------
function TMsgComponent.FreeSpaceOnDisk(DiskName: AnsiString = ''): Int64;
var
 drv: AnsiString;
 TotalSpace, FreeSpaceAvailable: Int64;
begin
  drv := ExtractFileDrive(DiskName) + #0;
  if drv <> ''#0 then
    GetDiskFreeSpaceEx(@drv[1], FreeSpaceAvailable, TotalSpace, nil)
  else
    GetDiskFreeSpaceEx(nil, FreeSpaceAvailable, TotalSpace, nil);
  Result := FreeSpaceAvailable;
//  Result := High(Int64);
end;// FreeSpaceOnDisk


//------------------------------------------------------------------------------
// load user info + password header
//------------------------------------------------------------------------------
procedure TMsgComponent.LoadBaseUserInfoFromStream(BaseUserInfo: PMsgBaseUserInfo; Stream: TStream);
begin
  LoadUserInfoFromStream(BaseUserInfo^.UserInfo,Stream);
  LoadDataFromStream(BaseUserInfo^.PasswordHeader,SizeOf(BaseUserInfo^.PasswordHeader),Stream,11457); 
end; // LoadBaseUserInfoFromStream
	
	
//------------------------------------------------------------------------------ 
// save user info + password header 
//------------------------------------------------------------------------------ 
procedure TMsgComponent.SaveBaseUserInfoToStream(BaseUserInfo: PMsgBaseUserInfo; Stream: TStream); 
begin 
  SaveUserInfoToStream(BaseUserInfo^.UserInfo,Stream); 
  SaveDataToStream(BaseUserInfo^.PasswordHeader,SizeOf(BaseUserInfo^.PasswordHeader),Stream,11456); 
end; // SaveBaseUserInfoToStream 
 
 
//------------------------------------------------------------------------------ 
// user info
//------------------------------------------------------------------------------
procedure TMsgComponent.LoadUserInfoFromStream(var UserInfo: TMsgUserInfo; Stream: TStream);
begin 
  LoadDataFromStream(UserInfo.UserID,SizeOf(UserInfo.UserID),Stream,11436);
  LoadShortStringFromStream(UserInfo.UserName,Stream,11437); 
  LoadShortStringFromStream(UserInfo.FirstName,Stream,11438); 
  LoadShortStringFromStream(UserInfo.LastName,Stream,11439); 
  LoadShortStringFromStream(UserInfo.Organization,Stream,11440); 
  LoadShortStringFromStream(UserInfo.Department,Stream,11441); 
  LoadDataFromStream(UserInfo.Status,SizeOf(UserInfo.Status),Stream,11442); 
  LoadShortStringFromStream(UserInfo.Host,Stream,11443); 
  LoadDataFromStream(UserInfo.Port,SizeOf(UserInfo.Port),Stream,11444); 
  LoadShortStringFromStream(UserInfo.Application,Stream,11445); 
end; // LoadUserInfoFromStream 
 
	
//------------------------------------------------------------------------------ 
// user info
//------------------------------------------------------------------------------ 
procedure TMsgComponent.SaveUserInfoToStream(var UserInfo: TMsgUserInfo; Stream: TStream); 
begin
  SaveDataToStream(UserInfo.UserID,SizeOf(UserInfo.UserID),Stream,11446);
  SaveShortStringToStream(UserInfo.UserName,Stream,11447);
  SaveShortStringToStream(UserInfo.FirstName,Stream,11448); 
  SaveShortStringToStream(UserInfo.LastName,Stream,11449);
  SaveShortStringToStream(UserInfo.Organization,Stream,11450);
  SaveShortStringToStream(UserInfo.Department,Stream,11451); 
  SaveDataToStream(UserInfo.Status,SizeOf(UserInfo.Status),Stream,11452); 
  SaveShortStringToStream(UserInfo.Host,Stream,11453);
  SaveDataToStream(UserInfo.Port,SizeOf(UserInfo.Port),Stream,11454);
  SaveShortStringToStream(UserInfo.Application,Stream,11455); 
end; // SaveUserInfoToStream
 
 
//------------------------------------------------------------------------------
// LoadContactInfoFromStream 
//------------------------------------------------------------------------------
procedure TMsgComponent.LoadContactInfoFromStream(var ContactInfo: TMsgContactInfo; Stream: TStream);
begin 
  LoadUserInfoFromStream(ContactInfo.UserInfo,Stream); 
  LoadDataFromStream(ContactInfo.ContactNameSource,SizeOf(ContactInfo.ContactNameSource),Stream,11460);
  LoadShortStringFromStream(ContactInfo.ContactCustomName,Stream,11461); 
end; // LoadContactInfoFromStream
 
 
//------------------------------------------------------------------------------
// SaveContactInfoToStream
//------------------------------------------------------------------------------
procedure TMsgComponent.SaveContactInfoToStream(var ContactInfo: TMsgContactInfo; Stream: TStream);
begin
  SaveUserInfoToStream(ContactInfo.UserInfo,Stream);
  SaveDataToStream(ContactInfo.ContactNameSource,SizeOf(ContactInfo.ContactNameSource),Stream,11458);
  SaveShortStringToStream(ContactInfo.ContactCustomName,Stream,11459); 
end; // SaveContactInfoToStream
 
	
//------------------------------------------------------------------------------
// LoadBaseContactInfoFromStream
//------------------------------------------------------------------------------ 
procedure TMsgComponent.LoadBaseContactInfoFromStream(var ContactInfo: TMsgContactInfo; Stream: TStream);
begin 
  LoadDataFromStream(ContactInfo.UserInfo.UserID,SizeOf(ContactInfo.UserInfo.UserID),Stream,11496);
  LoadDataFromStream(ContactInfo.ContactNameSource,SizeOf(ContactInfo.ContactNameSource),Stream,11497);
  LoadShortStringFromStream(ContactInfo.ContactCustomName,Stream,11498);
end; // LoadBaseContactInfoFromStream


//------------------------------------------------------------------------------
// SaveBaseContactInfoToStream
//------------------------------------------------------------------------------
procedure TMsgComponent.SaveBaseContactInfoToStream(var ContactInfo: TMsgContactInfo; Stream: TStream);
begin
  SaveDataToStream(ContactInfo.UserInfo.UserID,SizeOf(ContactInfo.UserInfo.UserID),Stream,11499);
  SaveDataToStream(ContactInfo.ContactNameSource,SizeOf(ContactInfo.ContactNameSource),Stream,11500);
  SaveShortStringToStream(ContactInfo.ContactCustomName,Stream,11501);
end; // SaveBaseContactInfoToStream


//------------------------------------------------------------------------------
// load contacts
//------------------------------------------------------------------------------
procedure TMsgComponent.LoadContactsFromStream(var Contacts: TMsgContactInfoArray; Stream: TStream);
var
    ContactCount,i: Integer;
begin
 LoadDataFromStream(ContactCount, SizeOf(ContactCount), Stream, 11376);
 SetLength(Contacts,ContactCount);
 for i := 0 to ContactCount-1 do
   LoadContactInfoFromStream(Contacts[i],Stream);
end; // LoadContactsFromStream


//------------------------------------------------------------------------------
// save contacts
//------------------------------------------------------------------------------
procedure TMsgComponent.SaveContactsToStream(var Contacts: TMsgContactInfoArray; Stream: TStream);
var
    ContactCount,i: Integer;
begin
 ContactCount := Length(Contacts);
 SaveDataToStream(ContactCount, SizeOf(ContactCount), Stream, 11470);
 for i := 0 to ContactCount-1 do
   SaveContactInfoToStream(Contacts[i],Stream);
end; // SaveContactsToStream


//------------------------------------------------------------------------------
// save message to database and return MessageID
//------------------------------------------------------------------------------
function TMsgComponent.SaveMessageToDatabase(
                                    Database:     TComponent;
                                    SenderID:     Cardinal;
                                    RecipientID:  Cardinal;
                                    MessageType:  TMsgMessageType;
                                    SendingDate:  TDateTime;
                                    Delivered:    Boolean;
                                    DeliveryDate: TDateTime;
                                    Stream:       TMsgMemoryStream
                                   ): Integer;
var MessageText:          AnsiString;
    MessageUnicodeText:   WideString;
    MessageData:          PAnsiChar;
    MessageDataSize, len: Integer;
    Pos:                  Int64;
    Command:              Cardinal;
begin
  Pos := Stream.Position;
  try
    MessageUnicodeText := '';
    MessageText := '';
    MessageData := nil;
    MessageDataSize := 0;
    if (MessageType = aamtText) then
     begin
      try
        LoadDataFromStream(len,SizeOf(len),Stream,11377);
        SetLength(MessageText,len);
        if (len > 0) then
         LoadDataFromStream(PAnsiChar(@MessageText[1])^,len,Stream,11378);
      except
      end;
     end
    else
    if (MessageType >= MsgLowestType) then
     begin
      Command := 0;
      try
        LoadDataFromStream(len,SizeOf(len),Stream,10270);
        if (len > 0) then
         begin
          case MessageType of
            MsgCustomCommand:
             begin
              LoadDataFromStream(Command, SizeOf(Command), Stream, 40061);
              MessageData := PAnsiChar(Stream.Buffer + Stream.Position);
              MessageDataSize := len - SizeOf(Command);
             end;
            else
             begin
              MessageData := PAnsiChar(Stream.Buffer + Stream.Position);
              MessageDataSize := len;
             end;
          end;
         end;
      except
      end;
     end // Command
    else
     begin
      MessageDataSize := Stream.Size - Stream.Position;
      if (MessageDataSize > 0) then
       MessageData := PAnsiChar(Stream.Buffer + Stream.Position);
     end; // binary or stream message
   if (MessageDataSize = 0) then
    MessageData := nil;
   try
    if (Assigned(FOnSaveMessage)) then
     FOnSaveMessage(SenderID,RecipientID,MessageType,
                    SendingDate,
                    DeliveryDate,
                    MessageData,MessageDataSize,
                    MessageText,MessageUnicodeText,Command);
   except
   end;
   Result := TMsgDatabase(Database).SaveMessage(Delivered,DeliveryDate,SenderID,RecipientID,MessageType,
                    SendingDate,
                    MessageData,MessageDataSize,
                    MessageText,MessageUnicodeText,Command);
  finally
    Stream.Position := Pos;
  end;
end; // SaveMessageToDatabase


//------------------------------------------------------------------------------
// do on error
//------------------------------------------------------------------------------
procedure TMsgComponent.DoOnError(
                       const ErrorCode:    Integer;
                       const NativeError:  Integer = -1;
                       const ErrorMessage: AnsiString = ''
                                 );
begin
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('------------------------------------------------------------------');
aaWriteToLog('ErrorCode='+IntToStr(Integer(ErrorCode)));
aaWriteToLog('NativeError='+IntToStr(Integer(NativeError)));
aaWriteToLog('ErrorMessage: "'+ErrorMessage+'"');
aaWriteToLog('GetTickCount = '+IntToStr(aaGetTickCount));
aaWriteToLog('==================================================================');
{$ENDIF}
  if (Assigned(FOnError)) then
   FOnError(Self,ErrorCode,NativeError,ErrorMessage);
end; // DoOnError


//------------------------------------------------------------------------------
// return current version
//------------------------------------------------------------------------------
function TMsgComponent.GetCurrentVersion: AnsiString;
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
// dummy for Object Inspector
//------------------------------------------------------------------------------
procedure TMsgComponent.SetCurrentVersion(value: AnsiString);
begin
end; // SetCurrentVersion


//------------------------------------------------------------------------------
// return contact display name
//------------------------------------------------------------------------------
function TMsgComponent.GetContactDisplayName(const ContactInfo: TMsgContactInfo): AnsiString;
begin
 case (ContactInfo.ContactNameSource) of
  mcnsUserName: Result := ContactInfo.UserInfo.UserName;
  mcnsFirstName: Result := ContactInfo.UserInfo.FirstName;
  mcnsLastName: Result := ContactInfo.UserInfo.LastName;
  mcnsFullName: Result := ContactInfo.UserInfo.FirstName + ' ' +ContactInfo.UserInfo.LastName;
  mcnsCustom: Result := ContactInfo.ContactCustomName
 else
  Result := '';
 end;
end; // GetContactDisplayName


////////////////////////////////////////////////////////////////////////////////
//
// TMsgComBaseSession
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgComBaseSession.Create;
begin
  inherited;
  FSessionID := INVALID_SESSION_ID;
  FUserID := MSG_INVALID_USER_ID;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgComBaseSession.Destroy;
begin
//  SetConnected(False);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// save command header
//------------------------------------------------------------------------------
procedure TMsgComBaseSession.SaveCommandHeader(
                                Stream:         TStream;
                                CommandCode:    Integer;
                                CommandResult:  Integer = 0;
                                NativeError:    Integer = 0
                                );
var CommandHeader: TMsgCommandHeader;
begin
  FillChar(CommandHeader,SizeOf(CommandHeader),$00);
  MsgGenerateRandomBuffer(@CommandHeader.RandomData,SizeOf(CommandHeader.RandomData));
  CommandHeader.CommandCode := CommandCode;
  CommandHeader.CommandResult := CommandResult;
  CommandHeader.NativeError := NativeError;
  SaveDataToStream(CommandHeader,SizeOf(CommandHeader),Stream,11462);
end; // SaveCommandHeader


function TMsgComBaseSession.ConnectUser(UserID: Cardinal; Host: AnsiString; Port: Integer):
                                      TMsgComBaseSession;
begin
end; // ConnectUser


function TMsgComBaseSession.ConnectedUser(UserID: Cardinal; Host: AnsiString; Port: Integer): Boolean;
begin
end; // ConnectedUser


////////////////////////////////////////////////////////////////////////////////
//
// TMsgNetworkSession
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgNetworkSession.Create;
begin
  inherited Create;
  FConnected := False;
  FOwnerComponent := TMsgComponent(AOwner);
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgNetworkSession.Destroy;
begin
  inherited Destroy;
end; // Destroy

// TMsgNetworkSession


////////////////////////////////////////////////////////////////////////////////
//
// TMsgSendLargeObjectThread
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgSendLargeObjectThread.Create(
                          Owner:          TMsgComponent
                                            );
begin
 try
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - START - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  FOwnerComponent := Owner;
  inherited Create(False);
  Priority := tpNormal;
  FreeOnTerminate := True;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - STARTED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - STARTED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))
+#13#10+'Exception: '+#13#10+e.Message);
{$ENDIF}
    if FOwnerComponent is TMsgClient then
      Error:=ErrorRClient
    else
    if FOwnerComponent is TMsgServer then
      Error:=ErrorRServer
    else
      Error:='';
    Error:=Error+
                  ErrorRSendThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRCreate+
                  E.Message;
    FOwnerComponent.DoOnError(
                  MsgClientSendThread,-1,
                  Error);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - Exception before destroy'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
    Destroy;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - Exception after destroy'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
   end;
 end;
end; // Create


//------------------------------------------------------------------------------
// Destroy;
//------------------------------------------------------------------------------
destructor TMsgSendLargeObjectThread.Destroy;
begin
 try
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - FINISH - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
  if FOwnerComponent.FSendThread <> nil then
    FOwnerComponent.FSendThread := nil;
  inherited Destroy;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))
+#13#10+'Exception: '+#13#10+e.Message);
{$ENDIF}
    if FOwnerComponent is TMsgClient then
      Error:=ErrorRClient
    else
    if FOwnerComponent is TMsgServer then
      Error:=ErrorRServer
    else
      Error:='';
    Error:=Error+
                  ErrorRSendThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRDestroy+
                  E.Message;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))
+#13#10+'before DoOnError');
{$ENDIF}
    FOwnerComponent.DoOnError(
                  MsgClientSendThread,-1,
                  Error);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))
+#13#10+'after DoOnError');
{$ENDIF}
   end;
 end;
end;// Destroy;


//------------------------------------------------------------------------------
// SendBlock
//------------------------------------------------------------------------------
function TMsgSendLargeObjectThread.SendBlock(
                        SendObject:           PMsgSendObject;
                        Buffer:               PAnsiChar;
                        Size:                 Integer
                                              ): Integer;
begin
  if FOwnerComponent is TMsgClient then
    Result := TMsgClient(FOwnerComponent).SendMessage(SendObject.ToUserID,Buffer,Size,SendObject.Directly,SendObject.ObjectType)
  else
  if FOwnerComponent is TMsgServer then
    Result := TMsgServer(FOwnerComponent).SendMessage(SendObject.ToUserID,Buffer,Size,SendObject.Directly,SendObject.ObjectType)
  else
    raise EMsgException.Create(40154, ErrorRUnknownComponentType);
{$IFDEF LOG_SEND_FILE_TIMEOUT}
aaWriteToLog('TMsgSendLargeObjectThread.SendBlock> Result = '+IntToStr(Result));
{$ENDIF}
end; // SendBlock


//------------------------------------------------------------------------------
// RemoveObject
//------------------------------------------------------------------------------
procedure TMsgSendLargeObjectThread.RemoveObject(SendObject: PMsgSendObject);
var
  Queue:                TMsgList;
begin
 Queue := FOwnerComponent.FSendQueue.LockList;
 try
  if SendObject.ObjectType = aamtsFile then
    SendObject.Stream.Free
  else
  if SendObject.ObjectType = aamtsStream then
    SendObject.Stream.Position := SendObject.StreamPosition;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': remove...');
{$ENDIF}
  Queue.Remove(SendObject);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Dispose...');
{$ENDIF}
  Dispose(SendObject);
 finally
  FOwnerComponent.FSendQueue.UnlockList;
 end;
end;// RemoveObject


//------------------------------------------------------------------------------
// AbortBlock
//------------------------------------------------------------------------------
procedure TMsgSendLargeObjectThread.AbortObject(SendObject: PMsgSendObject);
begin
end; // AbortBlock


//------------------------------------------------------------------------------
// AbortBlock
//------------------------------------------------------------------------------
procedure TMsgSendLargeObjectThread.AbortBlock(SendObject: PMsgSendObject);
var
  ToID,
  ToUserID:             Cardinal;
  Directly:             Boolean;
  ClientSession:        TMsgClientSession;
begin
{$IFDEF LOG_ABORT_BLOCK}
aaWriteToLog('TMsgSendLargeObjectThread.AbortBlock> Start');
{$ENDIF}
 try
  if FOwnerComponent is TMsgClient then
   begin
    ToID := SendObject.ToUserID;
    ToUserID := SendObject.ToUserID;
    Directly := SendObject.Directly;
{$IFDEF LOG_ABORT_BLOCK}
aaWriteToLog('TMsgSendLargeObjectThread.AbortBlock> PrepareToSendMessage...');
{$ENDIF}
    if TMsgClient(FOwnerComponent).PrepareToSendMessage(ToID,ToUserID,Directly,ClientSession) = MSG_Error_SendMessage_SendFailed then
     begin
{$IFDEF LOG_ABORT_BLOCK}
aaWriteToLog('TMsgSendLargeObjectThread.AbortBlock> SendMessage...');
{$ENDIF}
      ClientConnectionManager.SendMessage(ClientSession,nil,0,MsgMessageAbort);
     end
   end
  else
  if FOwnerComponent is TMsgServer then
   begin
{$IFDEF LOG_ABORT_BLOCK}
aaWriteToLog('TMsgSendLargeObjectThread.AbortBlock> finish');
{$ENDIF}
    AbortServerMessage(TMsgServer(FOwnerComponent), SendObject.ToUserID);
   end
  else
    raise EMsgException.Create(40154, ErrorRUnknownComponentType);
{$IFDEF LOG_ABORT_BLOCK}
aaWriteToLog('TMsgSendLargeObjectThread.AbortBlock> finish');
{$ENDIF}
 except
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TMsgSendLargeObjectThread.AbortBlock> ERROR!!!');
{$ENDIF}
 end;
end;// AbortBlock


//------------------------------------------------------------------------------
// Execute
//------------------------------------------------------------------------------
procedure TMsgSendLargeObjectThread.Execute;
var
  SendObject:           PMsgSendObject;
  Queue:                TMsgList;
  ErrCode,
  i:                    Integer;
  buf,
  Buffer:               PAnsiChar;
  SleepTime,
  Size:                 Integer;
  TimeOut,
  StartTime:            DWORD;
begin
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> Start');
{$ENDIF}
  ErrCode := -1;
 try // except
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - EXECUTE - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
try // thread finish log
{$ENDIF}
  i := 0;
  SleepTime := 0;
  repeat
   sleep(SleepTime);
   if Terminated then
    begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - EXECUTE - Terminated! - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
     Exit;
    end;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - EXECUTE - 1 - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
aaWriteToLog('FOwnerComponent = '+IntToHex(Integer(FOwnerComponent),8));
aaWriteToLog('FOwnerComponent.FSendQueue = '+IntToHex(Integer(FOwnerComponent.FSendQueue),8));
{$ENDIF}
   Queue := FOwnerComponent.FSendQueue.LockList;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('SendLargeObjectThread - EXECUTE - 2 - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
{$ENDIF}
   try
    if Queue.Count = 0 then
     begin
      SleepTime := 1;
      Continue;
     end;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Queue.Count = '+IntToStr(Queue.Count));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': old i = '+IntToStr(i));
{$ENDIF}
    if i >= Queue.Count then
      i := 0;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': new i = '+IntToStr(i));
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Get object...');
{$ENDIF}
    SendObject := Queue.Items[i];
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Got');
{$ENDIF}
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> got SendObject, block # '+IntToStr(SendObject.CurrentBlock));
{$ENDIF}
   finally
    FOwnerComponent.FSendQueue.UnlockList;
   end;
// Send block
   Size := SendObject.BlockSize+SizeOf(SendObject.ObjectID)+SizeOf(SendObject.CurrentBlock);
   Buffer := MemoryManager.GetMem(Size);
   try
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> Move1...');
{$ENDIF}
    Move(SendObject.ObjectID,Buffer^,SizeOf(SendObject.ObjectID));
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> Move2...');
{$ENDIF}
    Move(SendObject.CurrentBlock,(Buffer+SizeOf(SendObject.ObjectID))^,SizeOf(SendObject.CurrentBlock));
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> buf...');
{$ENDIF}
    buf := PAnsiChar(Integer(Buffer)+SizeOf(SendObject.ObjectID)+SizeOf(SendObject.CurrentBlock));
    Size := SendObject.Stream.Read(buf^,SendObject.BlockSize)
           +SizeOf(SendObject.ObjectID)+SizeOf(SendObject.CurrentBlock);
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> SendMessage...');
{$ENDIF}
    TimeOut := MsgBlockSendingTimeOut;
    StartTime := GetTickCount;
{$IFDEF LOG_SEND_FILE_TIMEOUT}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> TimeOut = '+IntToStr(TimeOut));
aaWriteToLog('TMsgSendLargeObjectThread.Execute> StartTime = '+IntToStr(StartTime));
{$ENDIF}
    while TimeOut > (GetTickCount - StartTime) do
     begin
{$IFDEF LOG_SEND_FILE_TIMEOUT}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> SendBlock...');
{$ENDIF}
      ErrCode := SendBlock(SendObject,Buffer,Size);
      case ErrCode of
        MSG_Error_SendMessage_NotLogged,
        MSG_Error_SendMessage_ToGuest,
        MSG_Error_SendMessage_SessionNotFound,
        MSG_Error_SendMessage_InternalDataError,
        MSG_COMMAND_OK:
         begin
{$IFDEF LOG_SEND_FILE_TIMEOUT}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> SendBlock Rsult = '+IntToStr(ErrCode));
{$ENDIF}
          break;
         end;
       end; // case
{$IFDEF LOG_SEND_FILE_TIMEOUT}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> SendBlock failed - sleep '+IntToStr(MsgBlockSendDelay));
{$ENDIF}
      sleep(MsgBlockSendDelay);
     end;
    if TimeOut < (GetTickCount - StartTime) then
     begin
{$IFDEF LOG_SEND_FILE_TIMEOUT}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> TimeOut!');
{$ENDIF}
      try
{$IFDEF LOG_ABORT_BLOCK}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> event');
{$ENDIF}
       case SendObject.ObjectType of
       aamtsFile:
         if Assigned(FOwnerComponent.FOnSendFile) then
           FOwnerComponent.FOnSendFileFailed(SendObject.ToUserID,SendObject.ObjectID,SendObject.FileName,SendObject.Stream.Size,SendObject.BlockSize,SendObject.CurrentBlock-1,SendObject.Blocks);
       aamtsStream:
         if Assigned(FOwnerComponent.FOnSendStreamFailed) then
           FOwnerComponent.FOnSendStreamFailed(SendObject.ToUserID,SendObject.ObjectID,SendObject.Stream.Size,SendObject.BlockSize,SendObject.CurrentBlock-1,SendObject.Blocks);
       end; // case
      except
{$IFDEF DEBUG_ONERROR}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> event ERROR!!!');
{$ENDIF}
      end;
{$IFDEF LOG_ABORT_BLOCK}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> AbortObject...');
{$ENDIF}
       AbortObject(SendObject);
{$IFDEF LOG_ABORT_BLOCK}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> RemoveObject...');
{$ENDIF}
       RemoveObject(SendObject);
       continue;
     end;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('TMsgSendLargeObjectThread.Execute> sent!');
{$ENDIF}
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> Sent!');
{$ENDIF}
    inc(SendObject.CurrentBlock);
   finally // block sending
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': free Buffer...');
{$ENDIF}
    MemoryManager.FreeAndNilMem(Buffer);
   end;
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Call event handler...');
{$ENDIF}
  try
   try
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> call event...');
{$ENDIF}
   case SendObject.ObjectType of
   aamtsFile:
     if Assigned(FOwnerComponent.FOnSendFile) then
       FOwnerComponent.FOnSendFile(SendObject.ToUserID,SendObject.ObjectID,SendObject.FileName,SendObject.Stream.Size,SendObject.BlockSize,SendObject.CurrentBlock-1,SendObject.Blocks);
   aamtsStream:
     if Assigned(FOwnerComponent.FOnSendStream) then
       FOwnerComponent.FOnSendStream(SendObject.ToUserID,SendObject.ObjectID,SendObject.Stream.Size,SendObject.BlockSize,SendObject.CurrentBlock-1,SendObject.Blocks);
   end; // case
{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> event returned');
{$ENDIF}
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': Event handler finished');
{$ENDIF}
   finally
     if SendObject.Stream.Position = SendObject.Stream.Size then // sent
       RemoveObject(SendObject);
   end; // finally
  except
    ErrCode := 40137;
    raise;
  end;

{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog(IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+': i = '+IntToStr(i));
{$ENDIF}
   inc(i);

{$IFDEF DEBUG_LOG_SEND_FILE_TIME}
aaWriteToLog(IntToStr(GetTickCount)+' - TMsgSendLargeObjectThread.Execute> Next block');
{$ENDIF}
   SleepTime := 0;
  until False;
{$IFDEF DEBUG_LOG_SEND_FILE}
finally
aaWriteToLog('Client send THREAD - EXECUTE FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle)));
end;
{$ENDIF}
 except
  on E: Exception do
   begin
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('Client send THREAD - EXECUTE FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))
+#13#10+'Exception: '+#13#10+e.Message);
{$ENDIF}
    if FOwnerComponent is TMsgClient then
      Error:=ErrorRClient
    else
    if FOwnerComponent is TMsgServer then
      Error:=ErrorRServer
    else
      Error:='';
    Error:=
                  ErrorRSendThread+
                  IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))+
                  ErrorRExecute+
                  E.Message;
    if (ErrCode = 40137) then
      Error := Error + ' - Error in event handler.';
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('Client send THREAD - EXECUTE FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))
+#13#10+'Before DoOnError');
{$ENDIF}
    FOwnerComponent.DoOnError(
                  MsgClientSendThread,ErrCode,
                  Error);
{$IFDEF DEBUG_LOG_SEND_FILE}
aaWriteToLog('Client send THREAD - EXECUTE FINISHED - THREAD #'+IntToStr(Integer(self.ThreadID))+'/'+IntToStr(Integer(self.Handle))
+#13#10+'After DoOnError');
{$ENDIF}
//    ErrCode := -1;
   end;
 end;
end;// Execute

// TMsgSendLargeObjectThread


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgComBase> initialized');
{$ENDIF}

end.

