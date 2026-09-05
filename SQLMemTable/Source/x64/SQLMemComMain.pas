{******************************************************************************}
{                                                                              }
{ Parameters editors for both client and server                                }
{                                                                              }
{******************************************************************************}
unit SQLMemComMain;

interface

{$WARNINGS OFF}
{$HINTS OFF}
{$I SQLMemVer.inc}

uses
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
{$ENDIF}
     SysUtils, Classes, IniFiles,

////////////////////////////////////////////////////////////////////////////////
//
//  MsgCommunicator units
//
////////////////////////////////////////////////////////////////////////////////

     SQLMemCrypto,
     SQLMemCompression,
     SQLMemTypes,
{$IFNDEF SQLMEMTABLE}
     SQLMemTypesNetwork,
{$ENDIF}     
     SQLMemExcept,
     SQLMemConst,
 {$IFDEF DEBUG_LOG}
     SQLMemDebug,
 {$ENDIF}
     SQLMemMemory;       // UNIT SQLMemMemory MUST BE LAST !!!


type

  TCompressionAlgorithm = (caNone,caZLIB,caBZIP
{$IFDEF PPMD}
  ,caPPM
{$ENDIF}
{$IFDEF PPMDI}
  ,caPPMI
{$ENDIF}
  );

  TSQLMemCryptoAlgorithm = (
                        craNone
{$IFDEF ENCRYPTION_ON}
                        ,
                        craRijndael_128,
                        craRijndael_256,
                        craBlowfish,
                        craTwofish_128,
                        craTwofish_256,
                        craSquare,
                        craDES_Single_8,
                        craDES_Double_8,
                        craDES_Double_16,
                        craDES_Triple_8,
                        craDES_Triple_16,
                        craDES_Triple_24
{$ENDIF}
                        );
TSQLMemCryptoMode = (acmCTS,acmCBC,acmCFB,acmOFB,acmCFS,acmECB,acmCFB8,acmOFB8,acmCFS8);


{$IFNDEF SQLMEMTABLE}
////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCryptoParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemCryptoParamsEditor = class (TPersistent)
   private
    FKeyInfo:         TSQLMemCryptoKey;
    FInitVector:      array [0..SQLMem_MAX_VECTOR] of Byte;
    FInitVectorSize:  Word;
    FPassword:        AnsiString; // SQLMemDefaultPassword by default
    FCryptoAlgorithm: TSQLMemCryptoAlgorithm;  // acr_Cipher_None by Default
    FCryptoMode:      TSQLMemCryptoMode;  // acr_CTS by Default
    FUseInitVector:   Boolean; // False by default
   public
    constructor Create;
    destructor Destroy; override;
    procedure SetCryptoParams(Params: TSQLMemCryptoParams);
    function GetCryptoParams: TSQLMemCryptoParams;

   protected
    function GetInitVectorValue(Index: Integer): Byte;
    procedure SetInitVectorValue(Index: Integer; Value: Byte);
    function GetVectorSize: Integer;

    function GetKeyValue(Index: Integer): Byte;
    procedure SetKeyValue(Index: Integer; Value: Byte);
    function GetKeySize: Integer;
    procedure SetKeySize(Value: Integer);
    function GetMaxKeySize: Integer;
   public
    procedure SetKey(Key: Pointer; KeySize: Integer);
    function GetKey: Pointer;
    procedure MakeRandomKey(KeySize: Integer);
    procedure MakeRandomInitVector; overload;
    procedure MakeRandomInitVector(VectorSize: Word); overload;

    procedure SetInitVector(Vector: Pointer; VectorSize: Word);
    function GetInitVector: Pointer;
    procedure Assign(Source: TPersistent); override;

   public
    property InitVector[Index: Integer]: Byte read GetInitVectorValue write SetInitVectorValue;
    property MaxInitVectorSize: Integer read GetVectorSize;

    property Key[Index: Integer]: Byte read GetKeyValue write SetKeyValue;
    property MaxKeySize: Integer read GetMaxKeySize;

   published
    property CryptoAlgorithm: TSQLMemCryptoAlgorithm read FCryptoAlgorithm write FCryptoAlgorithm;
    property CryptoMode:TSQLMemCryptoMode read FCryptoMode write FCryptoMode;
    property KeySize: Integer read GetKeySize write SetKeySize;
    property Password: AnsiString read FPassword write FPassword;
    property UseInitVector: Boolean read FUseInitVector write FUseInitVector;
    property InitVectorSize: Word read FInitVectorSize write FInitVectorSize;
   end;// TSQLMemCryptoParamsEditor


  TSQLMemNetworkSettingsTCPEditor = class;
  TSQLMemNetworkSettingsUDPEditor = class;

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemNetworkSettingsEditor = class (TPersistent)
   private
    FMaxThreadCount:           Integer;
    FDisconnectRetryCount:     Integer;
    FDisconnectDelay:          Integer;
    FCommandRetryCount:        Integer;
    FDefaultSettings:          TSQLMemDefaultNetworkSettings;
   protected
    FTCP:                      TSQLMemNetworkSettingsTCPEditor;
    FUDP:                      TSQLMemNetworkSettingsUDPEditor;
    FPacketSize:               Integer; // compatibility with old UDP only component
// client parameters, needed on the server to configure clients
    FStartReceiveTimeOut:      Integer;
    FReceiveTimeOut:           Integer;
    FReceiveSleep:             Integer;
    FMinSendTimeOut:           Integer;
    FSendTimeOut:              Integer;
    FWaitForSendSleep:         Integer;
    FResendDelay:              Integer;
    FRequestDelay:             Integer;
    FWaitForTimeOut:           Integer;
    FThreadsTerminateDelay:    Integer;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure CopySettingsToConnectParams(var ConnectParams: TSQLMemConnectParams); virtual;
    procedure SetDefaultSettings(Value: TSQLMemDefaultNetworkSettings); virtual;
   protected
    procedure SetPacketSize(Value: Integer); // compatibility with old UDP only component
    function GetPacketSize: Integer; // compatibility with old UDP only component
   public
    property PacketSize: Integer read GetPacketSize write SetPacketSize; // compatibility with old UDP only component
   published
    property MaxThreadCount:           Integer read FMaxThreadCount write FMaxThreadCount;
    property DisconnectRetryCount:     Integer read FDisconnectRetryCount write FDisconnectRetryCount;
    property DisconnectDelay:          Integer read FDisconnectDelay write FDisconnectDelay;
    property CommandRetryCount:        Integer read FCommandRetryCount write FCommandRetryCount;
// client parameters, needed on the server to configure clients
    property ReceiveTimeOut:           Integer read FReceiveTimeOut write FReceiveTimeOut;
    property ReceiveSleep:             Integer read FReceiveSleep write FReceiveSleep;
    property MinSendTimeOut:           Integer read FMinSendTimeOut write FMinSendTimeOut;
    property SendTimeOut:              Integer read FSendTimeOut write FSendTimeOut;
    property WaitForSendSleep:         Integer read FWaitForSendSleep write FWaitForSendSleep;
    property ResendDelay:              Integer read FResendDelay write FResendDelay;
    property RequestDelay:             Integer read FRequestDelay write FRequestDelay;
    property WaitForTimeOut:           Integer read FWaitForTimeOut write FWaitForTimeOut;
    property ThreadsTerminateDelay:    Integer read FThreadsTerminateDelay write FThreadsTerminateDelay;
    property StartReceiveTimeOut:      Integer read FStartReceiveTimeOut write FStartReceiveTimeOut;
    property RestoreDefaultSettings:   TSQLMemDefaultNetworkSettings read FDefaultSettings write SetDefaultSettings;
{$IFDEF RELEASE_BUILD}
   public
{$ENDIF}
    property NetworkSettingsTCP: TSQLMemNetworkSettingsTCPEditor read FTCP write	FTCP;
    property NetworkSettingsUDP: TSQLMemNetworkSettingsUDPEditor read FUDP write	FUDP;
  end; // TSQLMemNetworkSettingsEditor


////////////////////////////////////////////////////////////////////////////////
// TSQLMemNetworkSettingsTCPEditor
////////////////////////////////////////////////////////////////////////////////
  TSQLMemNetworkSettingsTCPEditor = class (TPersistent)
   private
    FOwner:                    TSQLMemNetworkSettingsEditor;
    FLocalPort:                Cardinal;
    FPacketSize:               Cardinal;
   public
    constructor Create(Owner: TSQLMemNetworkSettingsEditor);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure CopySettingsToConnectParams(var ConnectParams: TSQLMemConnectParams); virtual;
   protected
    procedure SetLocalPort(Value: Cardinal);
    procedure SetPacketSize(Value: Cardinal);
   published
    property LocalPort: Cardinal read FLocalPort write SetLocalPort;
    property PacketSize: Cardinal read FPacketSize write SetPacketSize;
  end; // TSQLMemNetworkSettingsTCPEditor


////////////////////////////////////////////////////////////////////////////////
// TSQLMemNetworkSettingsUDPEditor
////////////////////////////////////////////////////////////////////////////////
  TSQLMemNetworkSettingsUDPEditor = class (TPersistent)
   private
    FOwner:                    TSQLMemNetworkSettingsEditor;
    FLocalPort:                Cardinal;
    FPacketSize:               Cardinal;
    FConnectionParamsTunning:  Boolean;
    FTestPacketCount:          Integer;
   public
    constructor Create(Owner: TSQLMemNetworkSettingsEditor);
//    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure CopySettingsToConnectParams(var ConnectParams: TSQLMemConnectParams); virtual;
    procedure SetDefaultSettings(Value: TSQLMemDefaultNetworkSettings); virtual;
   protected
    procedure SetLocalPort(Value: Cardinal);
    procedure SetPacketSize(Value: Cardinal);
   published
    property LocalPort: Cardinal read FLocalPort write SetLocalPort;
    property PacketSize: Cardinal read FPacketSize write SetPacketSize;
    property ConnectionParamsTunning:  Boolean read FConnectionParamsTunning write FConnectionParamsTunning;
    property TestPacketCount:          Integer read FTestPacketCount write FTestPacketCount;
  end; // TSQLMemNetworkSettingsUDPEditor


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConnectionParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemConnectionParamsEditor = class (TPersistent)
   private
    FLocalHost:             AnsiString;
    FDatabaseName:          AnsiString;
    FCompressionAlgorithm:  TCompressionAlgorithm;
    FCompressionMode:       Byte;
    FCryptoParamsEditor:    TSQLMemCryptoParamsEditor;
//    FMinCacheSize:          Int64;
//    FMaxCacheSize:          Int64;
   protected
    FServerID:              Integer;
    FLocalPort:             Cardinal; // compatibility with old UDP only component
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function GetConnectParams: TSQLMemConnectParams; virtual;
   published
    property LocalHost: AnsiString read FLocalHost write FLocalHost;
    property DatabaseName: AnsiString read FDatabaseName write FDatabaseName;
    property CompressionAlgorithm: TCompressionAlgorithm
              read FCompressionAlgorithm write FCompressionAlgorithm;
    property CompressionMode: Byte read FCompressionMode write FCompressionMode;
    property CryptoParams: TSQLMemCryptoParamsEditor read FCryptoParamsEditor write FCryptoParamsEditor;
    property ServerID: Integer read FServerID write FServerID;
//    property MinCacheSize: Int64 read FMinCacheSize write FMinCacheSize;
//    property MaxCacheSize: Int64 read FMaxCacheSize write FMaxCacheSize;
  end;
{$ENDIF}


implementation

{$IFDEF CLIENT_SERVER_VERSION}
uses
  SQLMemConnection;
{$ENDIF}

{$IFNDEF SQLMEMTABLE}

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCryptoParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemCryptoParamsEditor.Create;
begin
  inherited;
  FPassword := SQLMemDefaultPassword;
  FKeyInfo.KeySize := SQLMem_MAX_KEY+1;
  FillChar(FInitVector,MaxInitVectorSize,$00);
  FillChar(FKeyInfo.Key,MaxKeySize,$00);
  FCryptoAlgorithm := craNone;
  FCryptoMode := acmCTS;
  FUseInitVector := False;
  FInitVectorSize := 0;
end;//Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemCryptoParamsEditor.Destroy;
begin
  FillChar(FKeyInfo,SizeOf(FKeyInfo),$00);
  FillChar(FInitVector,SizeOf(FInitVector),$00);
  SQLMemClearString(FPassword);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// set CryptoParams
//------------------------------------------------------------------------------
procedure TSQLMemCryptoParamsEditor.SetCryptoParams(Params: TSQLMemCryptoParams);
begin
  FUseInitVector := Params.UseInitVector;
  FKeyInfo := Params.KeyInfo;
  Move(Params.InitVector[0],FInitVector[0],MaxInitVectorSize);
  if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
  FPassword := Params.Password;
{$IFDEF ENCRYPTION_ON}
  case Params.CryptoAlgorithm of
    SQLMem_Cipher_None:          FCryptoAlgorithm := craNone;
    SQLMem_Cipher_Rijndael_128:  FCryptoAlgorithm := craRijndael_128;
    SQLMem_Cipher_Rijndael_256:  FCryptoAlgorithm := craRijndael_256;
    SQLMem_Cipher_Blowfish:      FCryptoAlgorithm := craBlowfish;
    SQLMem_Cipher_Twofish_128:   FCryptoAlgorithm := craTwofish_128;
    SQLMem_Cipher_Twofish_256:   FCryptoAlgorithm := craTwofish_256;
    SQLMem_Cipher_Square:        FCryptoAlgorithm := craSquare;
    SQLMem_Cipher_Des_Single_8:  FCryptoAlgorithm := craDES_Single_8;
    SQLMem_Cipher_Des_Double_8:  FCryptoAlgorithm := craDES_Double_8;
    SQLMem_Cipher_Des_Double_16: FCryptoAlgorithm := craDES_Double_16;
    SQLMem_Cipher_Des_Triple_8:  FCryptoAlgorithm := craDES_Triple_8;
    SQLMem_Cipher_Des_Triple_16: FCryptoAlgorithm := craDES_Triple_16;
    SQLMem_Cipher_Des_Triple_24: FCryptoAlgorithm := craDES_Triple_24;
  end;
  case Params.CryptoMode of
    SQLMem_Cipher_Mode_CTS:    FCryptoMode := acmCTS;
    SQLMem_Cipher_Mode_CBC:    FCryptoMode := acmCBC;
    SQLMem_Cipher_Mode_CFB:    FCryptoMode := acmCFB;
    SQLMem_Cipher_Mode_OFB:    FCryptoMode := acmOFB;
    SQLMem_Cipher_Mode_CFS:    FCryptoMode := acmCFS;
    SQLMem_Cipher_Mode_ECB:    FCryptoMode := acmECB;
    SQLMem_Cipher_Mode_CFB8:   FCryptoMode := acmCFB8;
    SQLMem_Cipher_Mode_OFB8:   FCryptoMode := acmOFB8;
    SQLMem_Cipher_Mode_CFS8:   FCryptoMode := acmCFS8;
  end;
{$ELSE}
  FCryptoAlgorithm := craNone;
  FCryptoMode := acmCTS;
{$ENDIF}
end; // SetCryptoParams


//------------------------------------------------------------------------------
// GetCryptoParams
//------------------------------------------------------------------------------
function TSQLMemCryptoParamsEditor.GetCryptoParams: TSQLMemCryptoParams;
begin
  Result.UseInitVector := FUseInitVector;
  Result.KeyInfo := FKeyInfo;
  Move(FInitVector[0],Result.InitVector[0],MaxInitVectorSize);
  Result.Password := FPassword;
{$IFDEF ENCRYPTION_ON}
  case FCryptoAlgorithm of
    craNone:               Result.CryptoAlgorithm := SQLMem_Cipher_None;
    craRijndael_128:       Result.CryptoAlgorithm := SQLMem_Cipher_Rijndael_128;
    craRijndael_256:       Result.CryptoAlgorithm := SQLMem_Cipher_Rijndael_256;
    craBlowfish:           Result.CryptoAlgorithm := SQLMem_Cipher_Blowfish;
    craTwofish_128:        Result.CryptoAlgorithm := SQLMem_Cipher_Twofish_128;
    craTwofish_256:        Result.CryptoAlgorithm := SQLMem_Cipher_Twofish_256;
    craSquare:             Result.CryptoAlgorithm := SQLMem_Cipher_Square;
    craDES_Single_8:       Result.CryptoAlgorithm := SQLMem_Cipher_Des_Single_8;
    craDES_Double_8:       Result.CryptoAlgorithm := SQLMem_Cipher_Des_Double_8;
    craDES_Double_16:      Result.CryptoAlgorithm := SQLMem_Cipher_Des_Double_16;
    craDES_Triple_8:       Result.CryptoAlgorithm := SQLMem_Cipher_Des_Triple_8;
    craDES_Triple_16:      Result.CryptoAlgorithm := SQLMem_Cipher_Des_Triple_16;
    craDES_Triple_24:      Result.CryptoAlgorithm := SQLMem_Cipher_Des_Triple_24;
  end;
  case FCryptoMode of
    acmCTS:   Result.CryptoMode := SQLMem_Cipher_Mode_CTS;
    acmCBC:   Result.CryptoMode := SQLMem_Cipher_Mode_CBC;
    acmCFB:   Result.CryptoMode := SQLMem_Cipher_Mode_CFB;
    acmOFB:   Result.CryptoMode := SQLMem_Cipher_Mode_OFB;
    acmCFS:   Result.CryptoMode := SQLMem_Cipher_Mode_CFS;
    acmECB:   Result.CryptoMode := SQLMem_Cipher_Mode_ECB;
    acmCFB8:  Result.CryptoMode := SQLMem_Cipher_Mode_CFB8;
    acmOFB8:  Result.CryptoMode := SQLMem_Cipher_Mode_OFB8;
    acmCFS8:  Result.CryptoMode := SQLMem_Cipher_Mode_CFS8;
  end;
{$ELSE}
  Result.CryptoAlgorithm := SQLMem_Cipher_None;
  Result.CryptoMode := SQLMem_Cipher_Mode_CTS;
{$ENDIF}
end;// GetCryptoParams


function TSQLMemCryptoParamsEditor.GetInitVectorValue(Index: Integer): Byte;
begin
 if (Index < 0) or (Index >= MaxInitVectorSize) then
  raise ESQLMemException.Create(10717,ErrorLInvalidVectorIndex,[Index,MaxInitVectorSize]);
 Result := FInitVector[Index];
end; // FInitVector


procedure TSQLMemCryptoParamsEditor.SetInitVectorValue(Index: Integer; Value: Byte);
begin
 if (Index < 0) or (Index >= MaxInitVectorSize) then
  raise ESQLMemException.Create(10718,ErrorLInvalidVectorIndex,[Index,MaxInitVectorSize]);
 FInitVector[Index] := Value;
 if (Index >= FInitVectorSize) then
  FInitVectorSize := Word(Index+1);
 FUseInitVector := True;
end; // SetInitVectorValue


function TSQLMemCryptoParamsEditor.GetVectorSize: Integer;
begin
 Result := SQLMem_MAX_VECTOR+1;
end; // GetVectorSize


function TSQLMemCryptoParamsEditor.GetKeySize: Integer;
begin
 Result := FKeyInfo.KeySize;
end; // GetVectorSize


procedure TSQLMemCryptoParamsEditor.SetKeySize(Value: Integer);
begin
 if (Value < 0) or (Value > MaxKeySize) then
  raise ESQLMemException.Create(10720,ErrorLInvalidKeySize,[Value,MaxKeySize]);
 FKeyInfo.KeySize := Value;
 if (Length(FPassword) > 0) then
  FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; // GetVectorSize


function TSQLMemCryptoParamsEditor.GetKeyValue(Index: Integer): Byte;
begin
 if (Index < 0) or (Index >= KeySize) then
  raise ESQLMemException.Create(10721,ErrorLInvalidKeyIndex,[Index,KeySize]);
 Result := FKeyInfo.Key[Index];
end;


procedure TSQLMemCryptoParamsEditor.SetKeyValue(Index: Integer; Value: Byte);
begin
 if (Index < 0) or (Index >= KeySize) then
  raise ESQLMemException.Create(10722,ErrorLInvalidKeyIndex,[Index,KeySize]);
 FKeyInfo.Key[Index] := Value;
 if (Length(FPassword) > 0) then
  FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; // SetKeyValue


function TSQLMemCryptoParamsEditor.GetMaxKeySize: Integer;
begin
 Result := SQLMem_MAX_KEY+1;
end; // GetMaxKeySize


procedure TSQLMemCryptoParamsEditor.SetKey(Key: Pointer; KeySize: Integer);
begin
 if (KeySize < 0) or (KeySize > MaxKeySize) then
  raise ESQLMemException.Create(10719,ErrorLInvalidKeySize,[KeySize,MaxKeySize]);
 Move(Key^,FKeyInfo.Key[0],KeySize);
 FKeyInfo.KeySize := KeySize;
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; //SetKey


function TSQLMemCryptoParamsEditor.GetKey: Pointer;
begin
 Result := @FKeyInfo.Key;
end; // GetKey


procedure TSQLMemCryptoParamsEditor.MakeRandomKey(KeySize: Integer);
begin
 if (KeySize < 0) or (KeySize > MaxKeySize) then
  raise ESQLMemException.Create(10723,ErrorLInvalidKeySize,[KeySize,MaxKeySize]);
 FKeyInfo.KeySize := KeySize;
 SQLMemGenerateRandomBuffer(@FKeyInfo.Key[0],KeySize);
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end;

procedure TSQLMemCryptoParamsEditor.MakeRandomInitVector;
begin
  FInitVectorSize := MaxInitVectorSize;
  SQLMemGenerateRandomBuffer(@FInitVector[0],FInitVectorSize);
  FUseInitVector := True;
end;


procedure TSQLMemCryptoParamsEditor.MakeRandomInitVector(VectorSize: Word);
begin
  if (VectorSize > MaxInitVectorSize) then
    raise ESQLMemException.Create(11984,ErrorLInvalidVectorIndex,[VectorSize,MaxInitVectorSize]);
  SQLMemGenerateRandomBuffer(@FInitVector[0],VectorSize);
  FInitVectorSize := VectorSize;
  FUseInitVector := True;
end;


procedure TSQLMemCryptoParamsEditor.SetInitVector(Vector: Pointer; VectorSize: Word);
begin
  if (VectorSize > GetVectorSize) then
    raise ESQLMemException.Create(11985,ErrorLInvalidVectorIndex,[VectorSize,MaxInitVectorSize]);
  Move(Vector^, FInitVector[0], VectorSize);
  FInitVectorSize := VectorSize;
  FUseInitVector := True;
end; // SetInitVector


function TSQLMemCryptoParamsEditor.GetInitVector: Pointer;
begin
  Result := @FInitVector;
end; // GetInitVector


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemCryptoParamsEditor.Assign(Source: TPersistent);
begin
 if (Source <> nil) then
  if (Source is TSQLMemCryptoParamsEditor) then
   begin
     if (Length(FPassword) > 0) then
       FillChar(FPassword[1],Length(Password),$FF);
     FKeyInfo := TSQLMemCryptoParamsEditor(Source).FKeyInfo;
     FInitVector := TSQLMemCryptoParamsEditor(Source).FInitVector;
     FPassword := TSQLMemCryptoParamsEditor(Source).FPassword;
     FCryptoAlgorithm := TSQLMemCryptoParamsEditor(Source).CryptoAlgorithm;
     FCryptoMode := TSQLMemCryptoParamsEditor(Source).CryptoMode;
     FUseInitVector := TSQLMemCryptoParamsEditor(Source).FUseInitVector;
   end;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemNetworkSettingsEditor.Create;
begin
  inherited Create;
//  FTCP := nil;
//  FUDP := nil;
  FUDP := TSQLMemNetworkSettingsUDPEditor.Create(Self);
  FTCP := TSQLMemNetworkSettingsTCPEditor.Create(Self);
  FPacketSize := SQLMemDefaultPacketSize; // compatibility with old UDP only component
//  FConnectionParamsTunning := SQLMemConnectionParamsTunning;
//  FTestPacketCount := SQLMemTestPacketCount;
  FMaxThreadCount := SQLMemMaxThreadCount;
  FDisconnectRetryCount := SQLMemDisconnectRetryCount;
  FDisconnectDelay := SQLMemDisconnectDelay;
  FCommandRetryCount := SQLMemCommandRetryCount;
// client parameters on the server to configure clients
  FStartReceiveTimeOut := SQLMemStartReceiveTimeOut;
  FReceiveTimeOut := SQLMemReceiveTimeOut;
  FReceiveSleep := SQLMemReceiveSleep;
  FMinSendTimeOut := SQLMemMinSendTimeOut;
  FSendTimeOut := SQLMemSendTimeOut;
  FWaitForSendSleep := SQLMemWaitForSendSleep;
  FResendDelay := SQLMemResendDelay;
  FRequestDelay := SQLMemRequestDelay;
  FWaitForTimeOut := SQLMemWaitForTimeOut;
  FThreadsTerminateDelay := SQLMemThreadsTerminateDelay;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemNetworkSettingsEditor.Destroy;
begin
  if (FUDP <> nil) then
   try
    FreeAndNil(FUDP);
   except
   end;
  if (FTCP <> nil) then
   try
    FreeAndNil(FTCP);
   except
   end;
  inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TSQLMemNetworkSettingsEditor) then
    begin
      FMaxThreadCount := TSQLMemNetworkSettingsEditor(Source).MaxThreadCount;
      FDisconnectRetryCount := TSQLMemNetworkSettingsEditor(Source).DisconnectRetryCount;
      FDisconnectDelay := TSQLMemNetworkSettingsEditor(Source).DisconnectDelay;
// client parameters, needed on the server to configure clients
      FCommandRetryCount := TSQLMemNetworkSettingsEditor(Source).CommandRetryCount;
      FStartReceiveTimeOut := TSQLMemNetworkSettingsEditor(Source).StartReceiveTimeOut;
      FReceiveTimeOut := TSQLMemNetworkSettingsEditor(Source).ReceiveTimeOut;
      FReceiveSleep := TSQLMemNetworkSettingsEditor(Source).ReceiveSleep;
      FMinSendTimeOut := TSQLMemNetworkSettingsEditor(Source).MinSendTimeOut;
      FSendTimeOut := TSQLMemNetworkSettingsEditor(Source).SendTimeOut;
      FWaitForSendSleep := TSQLMemNetworkSettingsEditor(Source).WaitForSendSleep;
      FResendDelay := TSQLMemNetworkSettingsEditor(Source).ResendDelay;
      FRequestDelay := TSQLMemNetworkSettingsEditor(Source).RequestDelay;
      FWaitForTimeOut := TSQLMemNetworkSettingsEditor(Source).WaitForTimeOut;
      FThreadsTerminateDelay := TSQLMemNetworkSettingsEditor(Source).ThreadsTerminateDelay;
    end;
end; // Assign


//------------------------------------------------------------------------------
// Copy network settings to ConnectParams
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsEditor.CopySettingsToConnectParams(var ConnectParams: TSQLMemConnectParams);
begin
  ConnectParams.PacketSize := PacketSize;
  ConnectParams.MaxThreadCount := FMaxThreadCount;
  ConnectParams.DisconnectRetryCount := FDisconnectRetryCount;
  ConnectParams.DisconnectDelay := FDisconnectDelay;
  ConnectParams.CommandRetryCount := FCommandRetryCount;
// client parameters, needed on the server to configure clients
  ConnectParams.CommandRetryCount := FCommandRetryCount;
  ConnectParams.StartReceiveTimeOut := FStartReceiveTimeOut;
  ConnectParams.ReceiveTimeOut := FReceiveTimeOut;
  ConnectParams.ReceiveSleep := FReceiveSleep;
  ConnectParams.MinSendTimeOut := FMinSendTimeOut;
  ConnectParams.SendTimeOut := FSendTimeOut;
  ConnectParams.WaitForSendSleep := FWaitForSendSleep;
  ConnectParams.ResendDelay := FResendDelay;
  ConnectParams.RequestDelay := FRequestDelay;
  ConnectParams.WaitForTimeOut := FWaitForTimeOut;
  ConnectParams.ThreadsTerminateDelay := FThreadsTerminateDelay;
end; // CopySettingsToConnectParams


//------------------------------------------------------------------------------
// SetDefaultSettings
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsEditor.SetDefaultSettings(Value: TSQLMemDefaultNetworkSettings);
begin
  if Value = RestoreDefaultSettings then
    Exit;
  FMaxThreadCount := SQLMemMaxThreadCount;
  FStartReceiveTimeOut := SQLMemStartReceiveTimeOut;
  FReceiveTimeOut := SQLMemReceiveTimeOut;
  FReceiveSleep := SQLMemReceiveSleep;
  FMinSendTimeOut := SQLMemMinSendTimeOut;
  FSendTimeOut := SQLMemSendTimeOut;
  FWaitForSendSleep := SQLMemWaitForSendSleep;
  FWaitForTimeOut := SQLMemWaitForTimeOut;
  FThreadsTerminateDelay := SQLMemThreadsTerminateDelay;
  case Value of
   SQLMemLocal:
    begin
     FDisconnectRetryCount := SQLMemLocalDisconnectRetryCount;
     FDisconnectDelay := SQLMemLocalDisconnectDelay;
    end;
   SQLMemLAN:
    begin
     FDisconnectRetryCount := SQLMemDisconnectRetryCount;
     FDisconnectDelay := SQLMemDisconnectDelay;
    end;
   SQLMemWAN:
    begin
     FDisconnectRetryCount := SQLMemWANDisconnectRetryCount;
     FDisconnectDelay := SQLMemWANDisconnectDelay;
    end;
   SQLMemModem:
    begin
     FDisconnectRetryCount := SQLMemModemDisconnectRetryCount;
     FDisconnectDelay := SQLMemModemDisconnectDelay;
    end;
  end;
  if FUDP <> nil then
    FUDP.SetDefaultSettings(Value);
  FDefaultSettings := Value;
end; // SetDefaultSettings

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsEditor.SetPacketSize(Value: Integer);
begin
  if FUDP <> nil then
    FUDP.PacketSize := Value
  else
  if FTCP <> nil then
    FTCP.PacketSize := Value;
end; // SetPacketSize

//------------------------------------------------------------------------------
// get packet size
//------------------------------------------------------------------------------
function TSQLMemNetworkSettingsEditor.GetPacketSize: Integer;
begin
{$IFNDEF CLIENT_SERVER_VERSION}
Result := 0;
{$ELSE}
  Result := SizeOf(TSQLMemPacketHeader); // emtpty packet by default, data size = 0
{$ENDIF}
  if FUDP <> nil then
    Result := FUDP.PacketSize
  else
  if FTCP <> nil then
    Result := FTCP.PacketSize;
end; // SetPacketSize

// TSQLMemNetworkSettingsEditor



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemNetworkSettingsTCPEditor
//
////////////////////////////////////////////////////////////////////////////////

constructor TSQLMemNetworkSettingsTCPEditor.Create(Owner: TSQLMemNetworkSettingsEditor);
begin
  FOwner := Owner;
  FPacketSize := SQLMemDefaultPacketSizeTCP;
  inherited Create;
end; // Create

destructor TSQLMemNetworkSettingsTCPEditor.Destroy;
begin
  inherited Destroy;
end;

//------------------------------------------------------------------------------
// Copy network settings to ConnectParams
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsTCPEditor.CopySettingsToConnectParams(var ConnectParams: TSQLMemConnectParams);
begin
  ConnectParams.PacketSize := FPacketSize;
  FOwner.FPacketSize := FPacketSize;
end; // CopySettingsToConnectParams

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsTCPEditor.SetPacketSize(Value: Cardinal);
begin
  if (Value >= SQLMemMinPacketSize) and (Value <= SQLMemMaxPacketSizeTCP) then
   begin
    FPacketSize := Value;
    FOwner.FPacketSize := Value;
   end;
end; // SetPacketSize

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsTCPEditor.SetLocalPort(Value: Cardinal);
begin
  if FLocalPort = Value then
    Exit;
// { TODO -oAlex : implement work }
  FLocalPort := Value;
end; // SetLocalPort

//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsTCPEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TSQLMemNetworkSettingsEditor) then
    begin
      FPacketSize := TSQLMemNetworkSettingsTCPEditor(Source).PacketSize;
      FOwner.FPacketSize := FPacketSize;
    end;
end; // Assign

// TSQLMemNetworkSettingsTCPEditor



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemNetworkSettingsUDPEditor
//
////////////////////////////////////////////////////////////////////////////////

constructor TSQLMemNetworkSettingsUDPEditor.Create(Owner: TSQLMemNetworkSettingsEditor);
begin
  FOwner := Owner;
  FPacketSize := SQLMemDefaultPacketSize;
  FConnectionParamsTunning := SQLMemConnectionParamsTunning;
  FTestPacketCount := SQLMemTestPacketCount;
  inherited Create;
end; // Create

//------------------------------------------------------------------------------
// Copy network settings to ConnectParams
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsUDPEditor.CopySettingsToConnectParams(var ConnectParams: TSQLMemConnectParams);
begin
  ConnectParams.PacketSize := FPacketSize;
  FOwner.FPacketSize := FPacketSize;
  ConnectParams.ConnectionParamsTunning := FConnectionParamsTunning;
  ConnectParams.TestPacketCount := FTestPacketCount;
end; // CopySettingsToConnectParams

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsUDPEditor.SetPacketSize(Value: Cardinal);
begin
  if (Value >= SQLMemMinPacketSize) and (Value <= SQLMemMaxPacketSize) then
   begin
    FPacketSize := Value;
    FOwner.FPacketSize := Value;
   end;
end; // SetPacketSize

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsUDPEditor.SetLocalPort(Value: Cardinal);
begin
  if FLocalPort = Value then
    Exit;
// { TODO -oAlex : implement work 2}
  FLocalPort := Value;
end; // SetLocalPort

//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsUDPEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TSQLMemNetworkSettingsEditor) then
    begin
      FPacketSize := TSQLMemNetworkSettingsUDPEditor(Source).PacketSize;
      FOwner.FPacketSize := FPacketSize;
      FConnectionParamsTunning := TSQLMemNetworkSettingsUDPEditor(Source).ConnectionParamsTunning;
      FTestPacketCount := TSQLMemNetworkSettingsUDPEditor(Source).TestPacketCount;
    end;
end; // Assign

//------------------------------------------------------------------------------
// SetDefaultSettings
//------------------------------------------------------------------------------
procedure TSQLMemNetworkSettingsUDPEditor.SetDefaultSettings(Value: TSQLMemDefaultNetworkSettings);
begin
  case Value of
   SQLMemLocal:
    begin
     FPacketSize := SQLMemLocalDefaultPacketSize;
    end;
   SQLMemLAN:
    begin
     FPacketSize := SQLMemDefaultPacketSize;
    end;
   SQLMemWAN:
    begin
     FPacketSize := SQLMemWANDefaultPacketSize;
    end;
   SQLMemModem:
    begin
     FPacketSize := SQLMemModemDefaultPacketSize;
    end;
  end;
end; // SetDefaultSettings

// TSQLMemNetworkSettingsUDPEditor



////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemConnectionParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemConnectionParamsEditor.Create;
begin
  inherited;
  FCryptoParamsEditor := TSQLMemCryptoParamsEditor.Create;
  FLocalHost := SQLMemDefaultServerHost;
  FDatabaseName := SQLMemDefaultDBName;
end;//Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemConnectionParamsEditor.Destroy;
begin
  FCryptoParamsEditor.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TSQLMemConnectionParamsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TSQLMemConnectionParamsEditor) then
    begin
      FLocalHost := TSQLMemConnectionParamsEditor(Source).LocalHost;
      FDatabaseName := TSQLMemConnectionParamsEditor(Source).DatabaseName;
      FCryptoParamsEditor.Assign(TSQLMemConnectionParamsEditor(Source).CryptoParams);
    end;
end; // Assign


//------------------------------------------------------------------------------
// return ConnectParams
//------------------------------------------------------------------------------
function TSQLMemConnectionParamsEditor.GetConnectParams: TSQLMemConnectParams;
begin
// from MsgCommuncator:
  Result.CryptoInfo := FCryptoParamsEditor.GetCryptoParams;
  Result.LocalHost := FLocalHost;
  Result.ServerID := -1;  // invalid value
{
// SQLMemTable code:
  Result.CompressionAlgorithm := Byte(ConvertCompressionAlgorithmToSQLMemCompressionAlgorithm(FCompressionAlgorithm));
  Result.CompressionMode := FCompressionMode;
  Result.CryptoInfo := FCryptoParamsEditor.GetCryptoParams;
  Result.LocalPort := FLocalPort;
  Result.ServerID := ServerID;
}
end; // GetConnectParams

{$ENDIF}

initialization

  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.
