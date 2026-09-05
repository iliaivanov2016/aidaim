{******************************************************************************}
{                                                                              }
{ Parameters editors for both client and server                                }
{                                                                              }
{******************************************************************************}
unit ACRComMain;

interface

{$WARNINGS OFF}
{$HINTS OFF}
{$I ACRVer.inc}

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

     ACRCrypto,
     ACRCompression,
     ACRTypes,
{$IFNDEF SQLMEMTABLE}
     ACRTypesNetwork,
{$ENDIF}     
     ACRExcept,
     ACRConst,
 {$IFDEF DEBUG_LOG}
     ACRDebug,
 {$ENDIF}
     ACRMemory;       // UNIT ACRMemory MUST BE LAST !!!


type

  TCompressionAlgorithm = (caNone,caZLIB,caBZIP
{$IFDEF PPMD}
  ,caPPM
{$ENDIF}
{$IFDEF PPMDI}
  ,caPPMI
{$ENDIF}
  );

  TACRCryptoAlgorithm = (
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
TACRCryptoMode = (acmCTS,acmCBC,acmCFB,acmOFB,acmCFS,acmECB,acmCFB8,acmOFB8,acmCFS8);


{$IFNDEF SQLMEMTABLE}
////////////////////////////////////////////////////////////////////////////////
//
// TACRCryptoParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TACRCryptoParamsEditor = class (TPersistent)
   private
    FKeyInfo:         TACRCryptoKey;
    FInitVector:      array [0..ACR_MAX_VECTOR] of Byte;
    FInitVectorSize:  Word;
    FPassword:        AnsiString; // ACRDefaultPassword by default
    FCryptoAlgorithm: TACRCryptoAlgorithm;  // acr_Cipher_None by Default
    FCryptoMode:      TACRCryptoMode;  // acr_CTS by Default
    FUseInitVector:   Boolean; // False by default
   public
    constructor Create;
    destructor Destroy; override;
    procedure SetCryptoParams(Params: TACRCryptoParams);
    function GetCryptoParams: TACRCryptoParams;

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
    property CryptoAlgorithm: TACRCryptoAlgorithm read FCryptoAlgorithm write FCryptoAlgorithm;
    property CryptoMode:TACRCryptoMode read FCryptoMode write FCryptoMode;
    property KeySize: Integer read GetKeySize write SetKeySize;
    property Password: AnsiString read FPassword write FPassword;
    property UseInitVector: Boolean read FUseInitVector write FUseInitVector;
    property InitVectorSize: Word read FInitVectorSize write FInitVectorSize;
   end;// TACRCryptoParamsEditor


  TACRNetworkSettingsTCPEditor = class;
  TACRNetworkSettingsUDPEditor = class;

////////////////////////////////////////////////////////////////////////////////
//
// TACRNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TACRNetworkSettingsEditor = class (TPersistent)
   private
    FMaxThreadCount:           Integer;
    FDisconnectRetryCount:     Integer;
    FDisconnectDelay:          Integer;
    FCommandRetryCount:        Integer;
    FDefaultSettings:          TACRDefaultNetworkSettings;
   protected
    FTCP:                      TACRNetworkSettingsTCPEditor;
    FUDP:                      TACRNetworkSettingsUDPEditor;
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
    procedure CopySettingsToConnectParams(var ConnectParams: TACRConnectParams); virtual;
    procedure SetDefaultSettings(Value: TACRDefaultNetworkSettings); virtual;
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
    property RestoreDefaultSettings:   TACRDefaultNetworkSettings read FDefaultSettings write SetDefaultSettings;
{$IFDEF RELEASE_BUILD}
   public
{$ENDIF}
    property NetworkSettingsTCP: TACRNetworkSettingsTCPEditor read FTCP write	FTCP;
    property NetworkSettingsUDP: TACRNetworkSettingsUDPEditor read FUDP write	FUDP;
  end; // TACRNetworkSettingsEditor


////////////////////////////////////////////////////////////////////////////////
// TACRNetworkSettingsTCPEditor
////////////////////////////////////////////////////////////////////////////////
  TACRNetworkSettingsTCPEditor = class (TPersistent)
   private
    FOwner:                    TACRNetworkSettingsEditor;
    FLocalPort:                Cardinal;
    FPacketSize:               Cardinal;
   public
    constructor Create(Owner: TACRNetworkSettingsEditor);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure CopySettingsToConnectParams(var ConnectParams: TACRConnectParams); virtual;
   protected
    procedure SetLocalPort(Value: Cardinal);
    procedure SetPacketSize(Value: Cardinal);
   published
    property LocalPort: Cardinal read FLocalPort write SetLocalPort;
    property PacketSize: Cardinal read FPacketSize write SetPacketSize;
  end; // TACRNetworkSettingsTCPEditor


////////////////////////////////////////////////////////////////////////////////
// TACRNetworkSettingsUDPEditor
////////////////////////////////////////////////////////////////////////////////
  TACRNetworkSettingsUDPEditor = class (TPersistent)
   private
    FOwner:                    TACRNetworkSettingsEditor;
    FLocalPort:                Cardinal;
    FPacketSize:               Cardinal;
    FConnectionParamsTunning:  Boolean;
    FTestPacketCount:          Integer;
   public
    constructor Create(Owner: TACRNetworkSettingsEditor);
//    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure CopySettingsToConnectParams(var ConnectParams: TACRConnectParams); virtual;
    procedure SetDefaultSettings(Value: TACRDefaultNetworkSettings); virtual;
   protected
    procedure SetLocalPort(Value: Cardinal);
    procedure SetPacketSize(Value: Cardinal);
   published
    property LocalPort: Cardinal read FLocalPort write SetLocalPort;
    property PacketSize: Cardinal read FPacketSize write SetPacketSize;
    property ConnectionParamsTunning:  Boolean read FConnectionParamsTunning write FConnectionParamsTunning;
    property TestPacketCount:          Integer read FTestPacketCount write FTestPacketCount;
  end; // TACRNetworkSettingsUDPEditor


////////////////////////////////////////////////////////////////////////////////
//
// TACRConnectionParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TACRConnectionParamsEditor = class (TPersistent)
   private
    FLocalHost:             AnsiString;
    FDatabaseName:          AnsiString;
    FCompressionAlgorithm:  TCompressionAlgorithm;
    FCompressionMode:       Byte;
    FCryptoParamsEditor:    TACRCryptoParamsEditor;
//    FMinCacheSize:          Int64;
//    FMaxCacheSize:          Int64;
   protected
    FServerID:              Integer;
    FLocalPort:             Cardinal; // compatibility with old UDP only component
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function GetConnectParams: TACRConnectParams; virtual;
   published
    property LocalHost: AnsiString read FLocalHost write FLocalHost;
    property DatabaseName: AnsiString read FDatabaseName write FDatabaseName;
    property CompressionAlgorithm: TCompressionAlgorithm
              read FCompressionAlgorithm write FCompressionAlgorithm;
    property CompressionMode: Byte read FCompressionMode write FCompressionMode;
    property CryptoParams: TACRCryptoParamsEditor read FCryptoParamsEditor write FCryptoParamsEditor;
    property ServerID: Integer read FServerID write FServerID;
//    property MinCacheSize: Int64 read FMinCacheSize write FMinCacheSize;
//    property MaxCacheSize: Int64 read FMaxCacheSize write FMaxCacheSize;
  end;
{$ENDIF}


implementation

{$IFDEF CLIENT_SERVER_VERSION}
uses
  ACRConnection;
{$ENDIF}

{$IFNDEF SQLMEMTABLE}

////////////////////////////////////////////////////////////////////////////////
//
// TACRCryptoParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRCryptoParamsEditor.Create;
begin
  inherited;
  FPassword := ACRDefaultPassword;
  FKeyInfo.KeySize := ACR_MAX_KEY+1;
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
destructor TACRCryptoParamsEditor.Destroy;
begin
  FillChar(FKeyInfo,SizeOf(FKeyInfo),$00);
  FillChar(FInitVector,SizeOf(FInitVector),$00);
  ACRClearString(FPassword);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// set CryptoParams
//------------------------------------------------------------------------------
procedure TACRCryptoParamsEditor.SetCryptoParams(Params: TACRCryptoParams);
begin
  FUseInitVector := Params.UseInitVector;
  FKeyInfo := Params.KeyInfo;
  Move(Params.InitVector[0],FInitVector[0],MaxInitVectorSize);
  if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
  FPassword := Params.Password;
{$IFDEF ENCRYPTION_ON}
  case Params.CryptoAlgorithm of
    ACR_Cipher_None:          FCryptoAlgorithm := craNone;
    ACR_Cipher_Rijndael_128:  FCryptoAlgorithm := craRijndael_128;
    ACR_Cipher_Rijndael_256:  FCryptoAlgorithm := craRijndael_256;
    ACR_Cipher_Blowfish:      FCryptoAlgorithm := craBlowfish;
    ACR_Cipher_Twofish_128:   FCryptoAlgorithm := craTwofish_128;
    ACR_Cipher_Twofish_256:   FCryptoAlgorithm := craTwofish_256;
    ACR_Cipher_Square:        FCryptoAlgorithm := craSquare;
    ACR_Cipher_Des_Single_8:  FCryptoAlgorithm := craDES_Single_8;
    ACR_Cipher_Des_Double_8:  FCryptoAlgorithm := craDES_Double_8;
    ACR_Cipher_Des_Double_16: FCryptoAlgorithm := craDES_Double_16;
    ACR_Cipher_Des_Triple_8:  FCryptoAlgorithm := craDES_Triple_8;
    ACR_Cipher_Des_Triple_16: FCryptoAlgorithm := craDES_Triple_16;
    ACR_Cipher_Des_Triple_24: FCryptoAlgorithm := craDES_Triple_24;
  end;
  case Params.CryptoMode of
    ACR_Cipher_Mode_CTS:    FCryptoMode := acmCTS;
    ACR_Cipher_Mode_CBC:    FCryptoMode := acmCBC;
    ACR_Cipher_Mode_CFB:    FCryptoMode := acmCFB;
    ACR_Cipher_Mode_OFB:    FCryptoMode := acmOFB;
    ACR_Cipher_Mode_CFS:    FCryptoMode := acmCFS;
    ACR_Cipher_Mode_ECB:    FCryptoMode := acmECB;
    ACR_Cipher_Mode_CFB8:   FCryptoMode := acmCFB8;
    ACR_Cipher_Mode_OFB8:   FCryptoMode := acmOFB8;
    ACR_Cipher_Mode_CFS8:   FCryptoMode := acmCFS8;
  end;
{$ELSE}
  FCryptoAlgorithm := craNone;
  FCryptoMode := acmCTS;
{$ENDIF}
end; // SetCryptoParams


//------------------------------------------------------------------------------
// GetCryptoParams
//------------------------------------------------------------------------------
function TACRCryptoParamsEditor.GetCryptoParams: TACRCryptoParams;
begin
  Result.UseInitVector := FUseInitVector;
  Result.KeyInfo := FKeyInfo;
  Move(FInitVector[0],Result.InitVector[0],MaxInitVectorSize);
  Result.Password := FPassword;
{$IFDEF ENCRYPTION_ON}
  case FCryptoAlgorithm of
    craNone:               Result.CryptoAlgorithm := ACR_Cipher_None;
    craRijndael_128:       Result.CryptoAlgorithm := ACR_Cipher_Rijndael_128;
    craRijndael_256:       Result.CryptoAlgorithm := ACR_Cipher_Rijndael_256;
    craBlowfish:           Result.CryptoAlgorithm := ACR_Cipher_Blowfish;
    craTwofish_128:        Result.CryptoAlgorithm := ACR_Cipher_Twofish_128;
    craTwofish_256:        Result.CryptoAlgorithm := ACR_Cipher_Twofish_256;
    craSquare:             Result.CryptoAlgorithm := ACR_Cipher_Square;
    craDES_Single_8:       Result.CryptoAlgorithm := ACR_Cipher_Des_Single_8;
    craDES_Double_8:       Result.CryptoAlgorithm := ACR_Cipher_Des_Double_8;
    craDES_Double_16:      Result.CryptoAlgorithm := ACR_Cipher_Des_Double_16;
    craDES_Triple_8:       Result.CryptoAlgorithm := ACR_Cipher_Des_Triple_8;
    craDES_Triple_16:      Result.CryptoAlgorithm := ACR_Cipher_Des_Triple_16;
    craDES_Triple_24:      Result.CryptoAlgorithm := ACR_Cipher_Des_Triple_24;
  end;
  case FCryptoMode of
    acmCTS:   Result.CryptoMode := ACR_Cipher_Mode_CTS;
    acmCBC:   Result.CryptoMode := ACR_Cipher_Mode_CBC;
    acmCFB:   Result.CryptoMode := ACR_Cipher_Mode_CFB;
    acmOFB:   Result.CryptoMode := ACR_Cipher_Mode_OFB;
    acmCFS:   Result.CryptoMode := ACR_Cipher_Mode_CFS;
    acmECB:   Result.CryptoMode := ACR_Cipher_Mode_ECB;
    acmCFB8:  Result.CryptoMode := ACR_Cipher_Mode_CFB8;
    acmOFB8:  Result.CryptoMode := ACR_Cipher_Mode_OFB8;
    acmCFS8:  Result.CryptoMode := ACR_Cipher_Mode_CFS8;
  end;
{$ELSE}
  Result.CryptoAlgorithm := ACR_Cipher_None;
  Result.CryptoMode := ACR_Cipher_Mode_CTS;
{$ENDIF}
end;// GetCryptoParams


function TACRCryptoParamsEditor.GetInitVectorValue(Index: Integer): Byte;
begin
 if (Index < 0) or (Index >= MaxInitVectorSize) then
  raise EACRException.Create(10717,ErrorLInvalidVectorIndex,[Index,MaxInitVectorSize]);
 Result := FInitVector[Index];
end; // FInitVector


procedure TACRCryptoParamsEditor.SetInitVectorValue(Index: Integer; Value: Byte);
begin
 if (Index < 0) or (Index >= MaxInitVectorSize) then
  raise EACRException.Create(10718,ErrorLInvalidVectorIndex,[Index,MaxInitVectorSize]);
 FInitVector[Index] := Value;
 if (Index >= FInitVectorSize) then
  FInitVectorSize := Word(Index+1);
 FUseInitVector := True;
end; // SetInitVectorValue


function TACRCryptoParamsEditor.GetVectorSize: Integer;
begin
 Result := ACR_MAX_VECTOR+1;
end; // GetVectorSize


function TACRCryptoParamsEditor.GetKeySize: Integer;
begin
 Result := FKeyInfo.KeySize;
end; // GetVectorSize


procedure TACRCryptoParamsEditor.SetKeySize(Value: Integer);
begin
 if (Value < 0) or (Value > MaxKeySize) then
  raise EACRException.Create(10720,ErrorLInvalidKeySize,[Value,MaxKeySize]);
 FKeyInfo.KeySize := Value;
 if (Length(FPassword) > 0) then
  FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; // GetVectorSize


function TACRCryptoParamsEditor.GetKeyValue(Index: Integer): Byte;
begin
 if (Index < 0) or (Index >= KeySize) then
  raise EACRException.Create(10721,ErrorLInvalidKeyIndex,[Index,KeySize]);
 Result := FKeyInfo.Key[Index];
end;


procedure TACRCryptoParamsEditor.SetKeyValue(Index: Integer; Value: Byte);
begin
 if (Index < 0) or (Index >= KeySize) then
  raise EACRException.Create(10722,ErrorLInvalidKeyIndex,[Index,KeySize]);
 FKeyInfo.Key[Index] := Value;
 if (Length(FPassword) > 0) then
  FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; // SetKeyValue


function TACRCryptoParamsEditor.GetMaxKeySize: Integer;
begin
 Result := ACR_MAX_KEY+1;
end; // GetMaxKeySize


procedure TACRCryptoParamsEditor.SetKey(Key: Pointer; KeySize: Integer);
begin
 if (KeySize < 0) or (KeySize > MaxKeySize) then
  raise EACRException.Create(10719,ErrorLInvalidKeySize,[KeySize,MaxKeySize]);
 Move(Key^,FKeyInfo.Key[0],KeySize);
 FKeyInfo.KeySize := KeySize;
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; //SetKey


function TACRCryptoParamsEditor.GetKey: Pointer;
begin
 Result := @FKeyInfo.Key;
end; // GetKey


procedure TACRCryptoParamsEditor.MakeRandomKey(KeySize: Integer);
begin
 if (KeySize < 0) or (KeySize > MaxKeySize) then
  raise EACRException.Create(10723,ErrorLInvalidKeySize,[KeySize,MaxKeySize]);
 FKeyInfo.KeySize := KeySize;
 ACRGenerateRandomBuffer(@FKeyInfo.Key[0],KeySize);
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end;

procedure TACRCryptoParamsEditor.MakeRandomInitVector;
begin
  FInitVectorSize := MaxInitVectorSize;
  ACRGenerateRandomBuffer(@FInitVector[0],FInitVectorSize);
  FUseInitVector := True;
end;


procedure TACRCryptoParamsEditor.MakeRandomInitVector(VectorSize: Word);
begin
  if (VectorSize > MaxInitVectorSize) then
    raise EACRException.Create(11984,ErrorLInvalidVectorIndex,[VectorSize,MaxInitVectorSize]);
  ACRGenerateRandomBuffer(@FInitVector[0],VectorSize);
  FInitVectorSize := VectorSize;
  FUseInitVector := True;
end;


procedure TACRCryptoParamsEditor.SetInitVector(Vector: Pointer; VectorSize: Word);
begin
  if (VectorSize > GetVectorSize) then
    raise EACRException.Create(11985,ErrorLInvalidVectorIndex,[VectorSize,MaxInitVectorSize]);
  Move(Vector^, FInitVector[0], VectorSize);
  FInitVectorSize := VectorSize;
  FUseInitVector := True;
end; // SetInitVector


function TACRCryptoParamsEditor.GetInitVector: Pointer;
begin
  Result := @FInitVector;
end; // GetInitVector


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRCryptoParamsEditor.Assign(Source: TPersistent);
begin
 if (Source <> nil) then
  if (Source is TACRCryptoParamsEditor) then
   begin
     if (Length(FPassword) > 0) then
       FillChar(FPassword[1],Length(Password),$FF);
     FKeyInfo := TACRCryptoParamsEditor(Source).FKeyInfo;
     FInitVector := TACRCryptoParamsEditor(Source).FInitVector;
     FPassword := TACRCryptoParamsEditor(Source).FPassword;
     FCryptoAlgorithm := TACRCryptoParamsEditor(Source).CryptoAlgorithm;
     FCryptoMode := TACRCryptoParamsEditor(Source).CryptoMode;
     FUseInitVector := TACRCryptoParamsEditor(Source).FUseInitVector;
   end;
end; // Assign




////////////////////////////////////////////////////////////////////////////////
//
// TACRNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TACRNetworkSettingsEditor.Create;
begin
  inherited Create;
//  FTCP := nil;
//  FUDP := nil;
  FUDP := TACRNetworkSettingsUDPEditor.Create(Self);
  FTCP := TACRNetworkSettingsTCPEditor.Create(Self);
  FPacketSize := ACRDefaultPacketSize; // compatibility with old UDP only component
//  FConnectionParamsTunning := ACRConnectionParamsTunning;
//  FTestPacketCount := ACRTestPacketCount;
  FMaxThreadCount := ACRMaxThreadCount;
  FDisconnectRetryCount := ACRDisconnectRetryCount;
  FDisconnectDelay := ACRDisconnectDelay;
  FCommandRetryCount := ACRCommandRetryCount;
// client parameters on the server to configure clients
  FStartReceiveTimeOut := ACRStartReceiveTimeOut;
  FReceiveTimeOut := ACRReceiveTimeOut;
  FReceiveSleep := ACRReceiveSleep;
  FMinSendTimeOut := ACRMinSendTimeOut;
  FSendTimeOut := ACRSendTimeOut;
  FWaitForSendSleep := ACRWaitForSendSleep;
  FResendDelay := ACRResendDelay;
  FRequestDelay := ACRRequestDelay;
  FWaitForTimeOut := ACRWaitForTimeOut;
  FThreadsTerminateDelay := ACRThreadsTerminateDelay;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRNetworkSettingsEditor.Destroy;
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
procedure TACRNetworkSettingsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TACRNetworkSettingsEditor) then
    begin
      FMaxThreadCount := TACRNetworkSettingsEditor(Source).MaxThreadCount;
      FDisconnectRetryCount := TACRNetworkSettingsEditor(Source).DisconnectRetryCount;
      FDisconnectDelay := TACRNetworkSettingsEditor(Source).DisconnectDelay;
// client parameters, needed on the server to configure clients
      FCommandRetryCount := TACRNetworkSettingsEditor(Source).CommandRetryCount;
      FStartReceiveTimeOut := TACRNetworkSettingsEditor(Source).StartReceiveTimeOut;
      FReceiveTimeOut := TACRNetworkSettingsEditor(Source).ReceiveTimeOut;
      FReceiveSleep := TACRNetworkSettingsEditor(Source).ReceiveSleep;
      FMinSendTimeOut := TACRNetworkSettingsEditor(Source).MinSendTimeOut;
      FSendTimeOut := TACRNetworkSettingsEditor(Source).SendTimeOut;
      FWaitForSendSleep := TACRNetworkSettingsEditor(Source).WaitForSendSleep;
      FResendDelay := TACRNetworkSettingsEditor(Source).ResendDelay;
      FRequestDelay := TACRNetworkSettingsEditor(Source).RequestDelay;
      FWaitForTimeOut := TACRNetworkSettingsEditor(Source).WaitForTimeOut;
      FThreadsTerminateDelay := TACRNetworkSettingsEditor(Source).ThreadsTerminateDelay;
    end;
end; // Assign


//------------------------------------------------------------------------------
// Copy network settings to ConnectParams
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsEditor.CopySettingsToConnectParams(var ConnectParams: TACRConnectParams);
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
procedure TACRNetworkSettingsEditor.SetDefaultSettings(Value: TACRDefaultNetworkSettings);
begin
  if Value = RestoreDefaultSettings then
    Exit;
  FMaxThreadCount := ACRMaxThreadCount;
  FStartReceiveTimeOut := ACRStartReceiveTimeOut;
  FReceiveTimeOut := ACRReceiveTimeOut;
  FReceiveSleep := ACRReceiveSleep;
  FMinSendTimeOut := ACRMinSendTimeOut;
  FSendTimeOut := ACRSendTimeOut;
  FWaitForSendSleep := ACRWaitForSendSleep;
  FWaitForTimeOut := ACRWaitForTimeOut;
  FThreadsTerminateDelay := ACRThreadsTerminateDelay;
  case Value of
   ACRLocal:
    begin
     FDisconnectRetryCount := ACRLocalDisconnectRetryCount;
     FDisconnectDelay := ACRLocalDisconnectDelay;
    end;
   ACRLAN:
    begin
     FDisconnectRetryCount := ACRDisconnectRetryCount;
     FDisconnectDelay := ACRDisconnectDelay;
    end;
   ACRWAN:
    begin
     FDisconnectRetryCount := ACRWANDisconnectRetryCount;
     FDisconnectDelay := ACRWANDisconnectDelay;
    end;
   ACRModem:
    begin
     FDisconnectRetryCount := ACRModemDisconnectRetryCount;
     FDisconnectDelay := ACRModemDisconnectDelay;
    end;
  end;
  if FUDP <> nil then
    FUDP.SetDefaultSettings(Value);
  FDefaultSettings := Value;
end; // SetDefaultSettings

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsEditor.SetPacketSize(Value: Integer);
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
function TACRNetworkSettingsEditor.GetPacketSize: Integer;
begin
{$IFNDEF CLIENT_SERVER_VERSION}
Result := 0;
{$ELSE}
  Result := SizeOf(TACRPacketHeader); // emtpty packet by default, data size = 0
{$ENDIF}
  if FUDP <> nil then
    Result := FUDP.PacketSize
  else
  if FTCP <> nil then
    Result := FTCP.PacketSize;
end; // SetPacketSize

// TACRNetworkSettingsEditor



////////////////////////////////////////////////////////////////////////////////
//
// TACRNetworkSettingsTCPEditor
//
////////////////////////////////////////////////////////////////////////////////

constructor TACRNetworkSettingsTCPEditor.Create(Owner: TACRNetworkSettingsEditor);
begin
  FOwner := Owner;
  FPacketSize := ACRDefaultPacketSizeTCP;
  inherited Create;
end; // Create

destructor TACRNetworkSettingsTCPEditor.Destroy;
begin
  inherited Destroy;
end;

//------------------------------------------------------------------------------
// Copy network settings to ConnectParams
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsTCPEditor.CopySettingsToConnectParams(var ConnectParams: TACRConnectParams);
begin
  ConnectParams.PacketSize := FPacketSize;
  FOwner.FPacketSize := FPacketSize;
end; // CopySettingsToConnectParams

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsTCPEditor.SetPacketSize(Value: Cardinal);
begin
  if (Value >= ACRMinPacketSize) and (Value <= ACRMaxPacketSizeTCP) then
   begin
    FPacketSize := Value;
    FOwner.FPacketSize := Value;
   end;
end; // SetPacketSize

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsTCPEditor.SetLocalPort(Value: Cardinal);
begin
  if FLocalPort = Value then
    Exit;
// { TODO -oAlex : implement work }
  FLocalPort := Value;
end; // SetLocalPort

//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsTCPEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TACRNetworkSettingsEditor) then
    begin
      FPacketSize := TACRNetworkSettingsTCPEditor(Source).PacketSize;
      FOwner.FPacketSize := FPacketSize;
    end;
end; // Assign

// TACRNetworkSettingsTCPEditor



////////////////////////////////////////////////////////////////////////////////
//
// TACRNetworkSettingsUDPEditor
//
////////////////////////////////////////////////////////////////////////////////

constructor TACRNetworkSettingsUDPEditor.Create(Owner: TACRNetworkSettingsEditor);
begin
  FOwner := Owner;
  FPacketSize := ACRDefaultPacketSize;
  FConnectionParamsTunning := ACRConnectionParamsTunning;
  FTestPacketCount := ACRTestPacketCount;
  inherited Create;
end; // Create

//------------------------------------------------------------------------------
// Copy network settings to ConnectParams
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsUDPEditor.CopySettingsToConnectParams(var ConnectParams: TACRConnectParams);
begin
  ConnectParams.PacketSize := FPacketSize;
  FOwner.FPacketSize := FPacketSize;
  ConnectParams.ConnectionParamsTunning := FConnectionParamsTunning;
  ConnectParams.TestPacketCount := FTestPacketCount;
end; // CopySettingsToConnectParams

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsUDPEditor.SetPacketSize(Value: Cardinal);
begin
  if (Value >= ACRMinPacketSize) and (Value <= ACRMaxPacketSize) then
   begin
    FPacketSize := Value;
    FOwner.FPacketSize := Value;
   end;
end; // SetPacketSize

//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsUDPEditor.SetLocalPort(Value: Cardinal);
begin
  if FLocalPort = Value then
    Exit;
// { TODO -oAlex : implement work 2}
  FLocalPort := Value;
end; // SetLocalPort

//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsUDPEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TACRNetworkSettingsEditor) then
    begin
      FPacketSize := TACRNetworkSettingsUDPEditor(Source).PacketSize;
      FOwner.FPacketSize := FPacketSize;
      FConnectionParamsTunning := TACRNetworkSettingsUDPEditor(Source).ConnectionParamsTunning;
      FTestPacketCount := TACRNetworkSettingsUDPEditor(Source).TestPacketCount;
    end;
end; // Assign

//------------------------------------------------------------------------------
// SetDefaultSettings
//------------------------------------------------------------------------------
procedure TACRNetworkSettingsUDPEditor.SetDefaultSettings(Value: TACRDefaultNetworkSettings);
begin
  case Value of
   ACRLocal:
    begin
     FPacketSize := ACRLocalDefaultPacketSize;
    end;
   ACRLAN:
    begin
     FPacketSize := ACRDefaultPacketSize;
    end;
   ACRWAN:
    begin
     FPacketSize := ACRWANDefaultPacketSize;
    end;
   ACRModem:
    begin
     FPacketSize := ACRModemDefaultPacketSize;
    end;
  end;
end; // SetDefaultSettings

// TACRNetworkSettingsUDPEditor



////////////////////////////////////////////////////////////////////////////////
//
// TACRConnectionParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TACRConnectionParamsEditor.Create;
begin
  inherited;
  FCryptoParamsEditor := TACRCryptoParamsEditor.Create;
  FLocalHost := ACRDefaultServerHost;
  FDatabaseName := ACRDefaultDBName;
end;//Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TACRConnectionParamsEditor.Destroy;
begin
  FCryptoParamsEditor.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TACRConnectionParamsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TACRConnectionParamsEditor) then
    begin
      FLocalHost := TACRConnectionParamsEditor(Source).LocalHost;
      FDatabaseName := TACRConnectionParamsEditor(Source).DatabaseName;
      FCryptoParamsEditor.Assign(TACRConnectionParamsEditor(Source).CryptoParams);
    end;
end; // Assign


//------------------------------------------------------------------------------
// return ConnectParams
//------------------------------------------------------------------------------
function TACRConnectionParamsEditor.GetConnectParams: TACRConnectParams;
begin
// from MsgCommuncator:
  Result.CryptoInfo := FCryptoParamsEditor.GetCryptoParams;
  Result.LocalHost := FLocalHost;
  Result.ServerID := -1;  // invalid value
{
// Accuracer code:
  Result.CompressionAlgorithm := Byte(ConvertCompressionAlgorithmToACRCompressionAlgorithm(FCompressionAlgorithm));
  Result.CompressionMode := FCompressionMode;
  Result.CryptoInfo := FCryptoParamsEditor.GetCryptoParams;
  Result.LocalPort := FLocalPort;
  Result.ServerID := ServerID;
}
end; // GetConnectParams

{$ENDIF}

initialization

  ACRMemoryIncUseCount;

finalization

  ACRMemoryDecUseCount;


end.
