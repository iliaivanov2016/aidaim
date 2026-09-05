{******************************************************************************}
{                                                                              }
{ Parameters editors for both client and server                                } 
{                                                                              }
{******************************************************************************}

unit MsgComMain;

interface

{$I MsgVer.inc}

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

     MsgComBase,
     MsgCrypto,
     MsgCompression,
     MsgTypes,
     MsgExcept,
     MsgConst,
 {$IFDEF DEBUG_LOG}
     MsgDebug,
 {$ENDIF}
     MsgMemory;       // UNIT MsgMemory MUST BE LAST !!!

type

{$IFDEF LINUX}
  // Delphi7 Controls.pas
  TDate = type TDateTime;
  TTime = type TDateTime;
{$ENDIF}

  TMsgCompressionAlgorithm = (caNone,caZLIB,caBZIP,caPPM);

  TMsgCryptoAlgorithm = (
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
  TMsgCryptoMode = (acmCTS,acmCBC,acmCFB,acmOFB,acmCFS,acmECB,acmCFB8,acmOFB8,acmCFS8);


////////////////////////////////////////////////////////////////////////////////
//
// TMsgCryptoParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

  TMsgCryptoParamsEditor = class (TPersistent)
   private
    FKeyInfo:         TMsgCryptoKey;
    FInitVector:      array [0..Msg_MAX_VECTOR] of Byte;
    FInitVectorSize:  Word;
    FPassword:        AnsiString; // MsgDefaultPassword by default
    FCryptoAlgorithm: TMsgCryptoAlgorithm;  // msg_Cipher_None by Default
    FCryptoMode:      TMsgCryptoMode;  // msg_CTS by Default
    FUseInitVector:   Boolean; // False by default
   public
    constructor Create;
    destructor Destroy; override;
    procedure SetCryptoParams(Params: TMsgCryptoParams);
    function GetCryptoParams: TMsgCryptoParams;
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
    property CryptoAlgorithm: TMsgCryptoAlgorithm read FCryptoAlgorithm write FCryptoAlgorithm;
    property CryptoMode:TMsgCryptoMode read FCryptoMode write FCryptoMode;
    property KeySize: Integer read GetKeySize write SetKeySize;
    property Password: AnsiString read FPassword write FPassword;
    property UseInitVector: Boolean read FUseInitVector write FUseInitVector;
    property InitVectorSize: Word read FInitVectorSize write FInitVectorSize;
   end;// TMsgCryptoParamsEditor



////////////////////////////////////////////////////////////////////////////////
//
// TMsgNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TMsgNetworkSettingsEditor = class (TPersistent)
   private
    FPacketSize:               Integer;
    FMaxThreadCount:           Integer;
    FConnectionParamsTunning:  Boolean;
    FTestPacketCount:          Integer;
    FDisconnectRetryCount:     Integer;
    FDisconnectDelay:          Integer;
    FDefaultSettings:          TMsgDefaultNetworkSettings;
// client parameters, needed on the server to configure clients
   protected
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
    procedure SetPacketSize(Value: Integer);
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure CopySettingsToConnectParams(var ConnectParams: TMsgConnectParams); virtual;
    procedure SetDefaultSettings(Value: TMsgDefaultNetworkSettings); virtual;
   published
    property PacketSize:               Integer read FPacketSize write SetPacketSize;
    property MaxThreadCount:           Integer read FMaxThreadCount write FMaxThreadCount;
    property ConnectionParamsTunning:  Boolean read FConnectionParamsTunning write FConnectionParamsTunning;
    property TestPacketCount:          Integer read FTestPacketCount write FTestPacketCount;
    property DisconnectRetryCount:     Integer read FDisconnectRetryCount write FDisconnectRetryCount;
    property DisconnectDelay:          Integer read FDisconnectDelay write FDisconnectDelay;
    property RestoreDefaultSettings: TMsgDefaultNetworkSettings read FDefaultSettings write SetDefaultSettings;
// client settings, both for client and server
    property StartReceiveTimeOut:      Integer read FStartReceiveTimeOut write FStartReceiveTimeOut;
    property ReceiveTimeOut:           Integer read FReceiveTimeOut write FReceiveTimeOut;
    property ReceiveSleep:             Integer read FReceiveSleep write FReceiveSleep;
    property MinSendTimeOut:           Integer read FMinSendTimeOut write FMinSendTimeOut;
    property SendTimeOut:              Integer read FSendTimeOut write FSendTimeOut;
    property WaitForSendSleep:         Integer read FWaitForSendSleep write FWaitForSendSleep;
    property ResendDelay:              Integer read FResendDelay write FResendDelay;
    property RequestDelay:             Integer read FRequestDelay write FRequestDelay;
    property WaitForTimeOut:           Integer read FWaitForTimeOut write FWaitForTimeOut;
    property ThreadsTerminateDelay:    Integer read FThreadsTerminateDelay write FThreadsTerminateDelay;
  end; // TMsgNetworkSettingsEditor



////////////////////////////////////////////////////////////////////////////////
//
// TMsgConnectionParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

  TMsgConnectionParamsEditor = class (TPersistent)
   private
    FLocalHost:             AnsiString;
    FLocalPort:             Cardinal;
    FCryptoParamsEditor:    TMsgCryptoParamsEditor;
   protected
//    procedure SetResendRequestDelay(Value: Integer);
   public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function GetConnectParams: TMsgConnectParams; virtual;
    property ConnectParams: TMsgConnectParams read GetConnectParams;
   published
    property LocalHost: AnsiString read FLocalHost write FLocalHost;
    property LocalPort: Cardinal read FLocalPort write FLocalPort;
    property CryptoParams: TMsgCryptoParamsEditor read FCryptoParamsEditor write FCryptoParamsEditor;
  end;



////////////////////////////////////////////////////////////////////////////////
//
// Global functions
//
////////////////////////////////////////////////////////////////////////////////

 // compression algorithm
function ConverTMsgCompressionAlgorithmToMsgCompressionAlgorithm(
            CompressionAlgorithm: TMsgCompressionAlgorithm
          ): TMsgCompressionAlgorithm1;
 // compression algorithm
function ConverTMsgCompressionAlgorithm1ToCompressionAlgorithm(
            CompressionAlgorithm: TMsgCompressionAlgorithm1
          ): TMsgCompressionAlgorithm;

function aaFileExists(FileName: PAnsiChar): Boolean;
// checks if AnsiString matches pattern
function IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean = true): Boolean;
procedure DeleteFiles(Path, Mask: AnsiString);

implementation

////////////////////////////////////////////////////////////////////////////////
//
// TMsgCryptoParamsEditor
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TMsgCryptoParamsEditor.Create;
begin
  inherited;
  FPassword := MsgDefaultPassword;
  FKeyInfo.KeySize := Msg_MAX_KEY+1;
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
destructor TMsgCryptoParamsEditor.Destroy;
begin
  FillChar(FKeyInfo,SizeOf(FKeyInfo),$00);
  FillChar(FInitVector,SizeOf(FInitVector),$00);
//  MsgClearString(FPassword);
  inherited;
end; // Destroy

//------------------------------------------------------------------------------
// set CryptoParams
//------------------------------------------------------------------------------
procedure TMsgCryptoParamsEditor.SetCryptoParams(Params: TMsgCryptoParams);
begin
  FUseInitVector := Params.UseInitVector;
  FKeyInfo := Params.KeyInfo;
  Move(Params.InitVector[0],FInitVector[0],MaxInitVectorSize);
  if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
  FPassword := Params.Password;
{$IFDEF ENCRYPTION_ON}
  case Params.CryptoAlgorithm of
    Msg_Cipher_None:          FCryptoAlgorithm := craNone;
    Msg_Cipher_Rijndael_128:  FCryptoAlgorithm := craRijndael_128;
    Msg_Cipher_Rijndael_256:  FCryptoAlgorithm := craRijndael_256;
    Msg_Cipher_Blowfish:      FCryptoAlgorithm := craBlowfish;
    Msg_Cipher_Twofish_128:   FCryptoAlgorithm := craTwofish_128;
    Msg_Cipher_Twofish_256:   FCryptoAlgorithm := craTwofish_256;
    Msg_Cipher_Square:        FCryptoAlgorithm := craSquare;
    Msg_Cipher_Des_Single_8:  FCryptoAlgorithm := craDES_Single_8;
    Msg_Cipher_Des_Double_8:  FCryptoAlgorithm := craDES_Double_8;
    Msg_Cipher_Des_Double_16: FCryptoAlgorithm := craDES_Double_16;
    Msg_Cipher_Des_Triple_8:  FCryptoAlgorithm := craDES_Triple_8;
    Msg_Cipher_Des_Triple_16: FCryptoAlgorithm := craDES_Triple_16;
    Msg_Cipher_Des_Triple_24: FCryptoAlgorithm := craDES_Triple_24;
  end;
  case Params.CryptoMode of
    Msg_Cipher_Mode_CTS:    FCryptoMode := acmCTS;
    Msg_Cipher_Mode_CBC:    FCryptoMode := acmCBC;
    Msg_Cipher_Mode_CFB:    FCryptoMode := acmCFB;
    Msg_Cipher_Mode_OFB:    FCryptoMode := acmOFB;
    Msg_Cipher_Mode_CFS:    FCryptoMode := acmCFS;
    Msg_Cipher_Mode_ECB:    FCryptoMode := acmECB;
    Msg_Cipher_Mode_CFB8:   FCryptoMode := acmCFB8;
    Msg_Cipher_Mode_OFB8:   FCryptoMode := acmOFB8;
    Msg_Cipher_Mode_CFS8:   FCryptoMode := acmCFS8;
  end;
{$ELSE}
  FCryptoAlgorithm := craNone;
  FCryptoMode := acmCTS;
{$ENDIF}
end; // SetCryptoParams


//------------------------------------------------------------------------------
// GetCryptoParams
//------------------------------------------------------------------------------
function TMsgCryptoParamsEditor.GetCryptoParams: TMsgCryptoParams;
begin
  Result.UseInitVector := FUseInitVector;
  Result.KeyInfo := FKeyInfo;
  Move(FInitVector[0],Result.InitVector[0],MaxInitVectorSize);
  Result.Password := FPassword;
{$IFDEF ENCRYPTION_ON}
  case FCryptoAlgorithm of
    craNone:               Result.CryptoAlgorithm := Msg_Cipher_None;
    craRijndael_128:       Result.CryptoAlgorithm := Msg_Cipher_Rijndael_128;
    craRijndael_256:       Result.CryptoAlgorithm := Msg_Cipher_Rijndael_256;
    craBlowfish:           Result.CryptoAlgorithm := Msg_Cipher_Blowfish;
    craTwofish_128:        Result.CryptoAlgorithm := Msg_Cipher_Twofish_128;
    craTwofish_256:        Result.CryptoAlgorithm := Msg_Cipher_Twofish_256;
    craSquare:             Result.CryptoAlgorithm := Msg_Cipher_Square;
    craDES_Single_8:       Result.CryptoAlgorithm := Msg_Cipher_Des_Single_8;
    craDES_Double_8:       Result.CryptoAlgorithm := Msg_Cipher_Des_Double_8;
    craDES_Double_16:      Result.CryptoAlgorithm := Msg_Cipher_Des_Double_16;
    craDES_Triple_8:       Result.CryptoAlgorithm := Msg_Cipher_Des_Triple_8;
    craDES_Triple_16:      Result.CryptoAlgorithm := Msg_Cipher_Des_Triple_16;
    craDES_Triple_24:      Result.CryptoAlgorithm := Msg_Cipher_Des_Triple_24;
  end;
  case FCryptoMode of
    acmCTS:   Result.CryptoMode := Msg_Cipher_Mode_CTS;
    acmCBC:   Result.CryptoMode := Msg_Cipher_Mode_CBC;
    acmCFB:   Result.CryptoMode := Msg_Cipher_Mode_CFB;
    acmOFB:   Result.CryptoMode := Msg_Cipher_Mode_OFB;
    acmCFS:   Result.CryptoMode := Msg_Cipher_Mode_CFS;
    acmECB:   Result.CryptoMode := Msg_Cipher_Mode_ECB;
    acmCFB8:  Result.CryptoMode := Msg_Cipher_Mode_CFB8;
    acmOFB8:  Result.CryptoMode := Msg_Cipher_Mode_OFB8;
    acmCFS8:  Result.CryptoMode := Msg_Cipher_Mode_CFS8;
  end;
{$ELSE}
  Result.CryptoAlgorithm := Msg_Cipher_None;
  Result.CryptoMode := Msg_Cipher_Mode_CTS;
{$ENDIF}
end;// GetCryptoParams


function TMsgCryptoParamsEditor.GetInitVectorValue(Index: Integer): Byte;
begin
 if (Index < 0) or (Index >= MaxInitVectorSize) then
  raise EMsgException.Create(10717,ErrorLInvalidVectorIndex,[Index,MaxInitVectorSize]);
 Result := FInitVector[Index];
end; // FInitVector


procedure TMsgCryptoParamsEditor.SetInitVectorValue(Index: Integer; Value: Byte);
begin
 if (Index < 0) or (Index >= MaxInitVectorSize) then
  raise EMsgException.Create(10718,ErrorLInvalidVectorIndex,[Index,MaxInitVectorSize]);
 FInitVector[Index] := Value;
 if (Index >= FInitVectorSize) then
  FInitVectorSize := Word(Index+1);
 FUseInitVector := True;
end; // SetInitVectorValue


function TMsgCryptoParamsEditor.GetVectorSize: Integer;
begin 
 Result := Msg_MAX_VECTOR+1; 
end; // GetVectorSize
 
 
function TMsgCryptoParamsEditor.GetKeySize: Integer; 
begin 
 Result := FKeyInfo.KeySize; 
end; // GetVectorSize
	
 
procedure TMsgCryptoParamsEditor.SetKeySize(Value: Integer);
begin 
 if (Value < 0) or (Value > MaxKeySize) then 
  raise EMsgException.Create(10720,ErrorLInvalidKeySize,[Value,MaxKeySize]); 
 FKeyInfo.KeySize := Value;
 if (Length(FPassword) > 0) then
  FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; // GetVectorSize 
	
	
function TMsgCryptoParamsEditor.GetKeyValue(Index: Integer): Byte;
begin 
 if (Index < 0) or (Index >= KeySize) then 
  raise EMsgException.Create(10721,ErrorLInvalidKeyIndex,[Index,KeySize]);
 Result := FKeyInfo.Key[Index]; 
end;
	
 
procedure TMsgCryptoParamsEditor.SetKeyValue(Index: Integer; Value: Byte);
begin
 if (Index < 0) or (Index >= KeySize) then
  raise EMsgException.Create(10722,ErrorLInvalidKeyIndex,[Index,KeySize]); 
 FKeyInfo.Key[Index] := Value;
 FPassword := '';
end; // SetKeyValue
 
 
function TMsgCryptoParamsEditor.GetMaxKeySize: Integer;
begin 
 Result := Msg_MAX_KEY+1; 
end; // GetMaxKeySize 
	
	
procedure TMsgCryptoParamsEditor.SetKey(Key: Pointer; KeySize: Integer);
begin
 if (KeySize < 0) or (KeySize > MaxKeySize) then 
  raise EMsgException.Create(10719,ErrorLInvalidKeySize,[KeySize,MaxKeySize]); 
 Move(Key^,FKeyInfo.Key[0],KeySize);
 FKeyInfo.KeySize := KeySize; 
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; //SetKey 
 
	
function TMsgCryptoParamsEditor.GetKey: Pointer;
begin
 Result := @FKeyInfo.Key; 
end; // GetKey 
 
 
procedure TMsgCryptoParamsEditor.MakeRandomKey(KeySize: Integer); 
begin 
 if (KeySize < 0) or (KeySize > MaxKeySize) then 
  raise EMsgException.Create(10723,ErrorLInvalidKeySize,[KeySize,MaxKeySize]); 
 FKeyInfo.KeySize := KeySize; 
 MsgGenerateRandomBuffer(@FKeyInfo.Key[0],KeySize);
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end;

procedure TMsgCryptoParamsEditor.MakeRandomInitVector;
begin
 FInitVectorSize := MaxInitVectorSize;
 MsgGenerateRandomBuffer(@FInitVector[0],FInitVectorSize);
 FUseInitVector := True;
end;


procedure TMsgCryptoParamsEditor.MakeRandomInitVector(VectorSize: Word);
begin
  if (VectorSize > MaxInitVectorSize) then
    raise EMsgException.Create(11984,ErrorLInvalidVectorIndex,[VectorSize,MaxInitVectorSize]);
  MsgGenerateRandomBuffer(@FInitVector[0],VectorSize);
  FInitVectorSize := VectorSize;
  FUseInitVector := True;
end;


procedure TMsgCryptoParamsEditor.SetInitVector(Vector: Pointer; VectorSize: Word);
begin 
  if (VectorSize > GetVectorSize) then
    raise EMsgException.Create(11985,ErrorLInvalidVectorIndex,[VectorSize,MaxInitVectorSize]);
  Move(Vector^, FInitVector[0], VectorSize);
  FInitVectorSize := VectorSize;
  FUseInitVector := True;
end; // SetInitVector


function TMsgCryptoParamsEditor.GetInitVector: Pointer;
begin
  Result := @FInitVector;
end; // GetInitVector
 
 
//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TMsgCryptoParamsEditor.Assign(Source: TPersistent); 
begin
 if (Source <> nil) then
  if (Source is TMsgCryptoParamsEditor) then
   begin
     if (Length(FPassword) > 0) then
       FillChar(FPassword[1],Length(Password),$FF);
     FKeyInfo := TMsgCryptoParamsEditor(Source).FKeyInfo;
     FInitVector := TMsgCryptoParamsEditor(Source).FInitVector;
     FPassword := TMsgCryptoParamsEditor(Source).FPassword;
     FCryptoAlgorithm := TMsgCryptoParamsEditor(Source).CryptoAlgorithm;
     FCryptoMode := TMsgCryptoParamsEditor(Source).CryptoMode;
     FUseInitVector := TMsgCryptoParamsEditor(Source).FUseInitVector;
   end;
end; // Assign
 


////////////////////////////////////////////////////////////////////////////////
//
// TMsgNetworkSettingsEditor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set packet size
//------------------------------------------------------------------------------
procedure TMsgNetworkSettingsEditor.SetPacketSize(Value: Integer);
begin
  if (Value >= MsgMinPacketSize) and (Value <= MsgMaxPacketSize) then
   FPacketSize := Value;
end; // SetPacketSize
	
	
//------------------------------------------------------------------------------
// Create 
//------------------------------------------------------------------------------
constructor TMsgNetworkSettingsEditor.Create; 
begin
  inherited Create;
  FDefaultSettings := msgLAN;
  FPacketSize := MsgDefaultPacketSize;
  FMaxThreadCount := MsgMaxThreadCount;
  FConnectionParamsTunning := MsgConnectionParamsTunning;
  FTestPacketCount := MsgTestPacketCount;
  FDisconnectRetryCount := MsgDisconnectRetryCount;
  FDisconnectDelay := MsgDisconnectDelay;
// both lient and server
  FStartReceiveTimeOut := MsgStartReceiveTimeOut;
  FReceiveTimeOut := MsgReceiveTimeOut;
  FReceiveSleep := MsgReceiveSleep;
  FMinSendTimeOut := MsgMinSendTimeOut;
  FSendTimeOut := MsgSendTimeOut;
  FWaitForSendSleep := MsgWaitForSendSleep;
  FResendDelay := MsgResendDelay;
  FRequestDelay := MsgRequestDelay;
  FWaitForTimeOut := MsgWaitForTimeOut;
  FThreadsTerminateDelay := MsgThreadsTerminateDelay;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgNetworkSettingsEditor.Destroy;
begin
  inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TMsgNetworkSettingsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TMsgNetworkSettingsEditor) then
    begin
      FDefaultSettings := TMsgNetworkSettingsEditor(Source).RestoreDefaultSettings;
      FPacketSize := TMsgNetworkSettingsEditor(Source).PacketSize;
      FMaxThreadCount := TMsgNetworkSettingsEditor(Source).MaxThreadCount;
      FConnectionParamsTunning := TMsgNetworkSettingsEditor(Source).ConnectionParamsTunning;
      FTestPacketCount := TMsgNetworkSettingsEditor(Source).TestPacketCount;
      FDisconnectRetryCount := TMsgNetworkSettingsEditor(Source).DisconnectRetryCount;
      FDisconnectDelay := TMsgNetworkSettingsEditor(Source).DisconnectDelay;
      FThreadsTerminateDelay := TMsgNetworkSettingsEditor(Source).ThreadsTerminateDelay;
// client settings, both for client and server
      FStartReceiveTimeOut := TMsgNetworkSettingsEditor(Source).StartReceiveTimeOut;
      FReceiveTimeOut := TMsgNetworkSettingsEditor(Source).ReceiveTimeOut;
      FReceiveSleep := TMsgNetworkSettingsEditor(Source).ReceiveSleep;
      FMinSendTimeOut := TMsgNetworkSettingsEditor(Source).MinSendTimeOut;
      FSendTimeOut := TMsgNetworkSettingsEditor(Source).SendTimeOut;
      FWaitForSendSleep := TMsgNetworkSettingsEditor(Source).WaitForSendSleep;
      FResendDelay := TMsgNetworkSettingsEditor(Source).ResendDelay;
      FRequestDelay := TMsgNetworkSettingsEditor(Source).RequestDelay;
      FWaitForTimeOut := TMsgNetworkSettingsEditor(Source).WaitForTimeOut;
    end;
end; // Assign


//------------------------------------------------------------------------------
// Copy network settings to ConnectParams
//------------------------------------------------------------------------------
procedure TMsgNetworkSettingsEditor.CopySettingsToConnectParams(var ConnectParams: TMsgConnectParams);
begin
  ConnectParams.PacketSize := FPacketSize;
  ConnectParams.MaxThreadCount := FMaxThreadCount;
  ConnectParams.ConnectionParamsTunning := FConnectionParamsTunning;
  ConnectParams.TestPacketCount := FTestPacketCount;
  ConnectParams.DisconnectRetryCount := FDisconnectRetryCount;
  ConnectParams.DisconnectDelay := FDisconnectDelay;
// client parameters, needed on the server to configure clients
//  ConnectParams.CommandRetryCount := FCommandRetryCount;
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
procedure TMsgNetworkSettingsEditor.SetDefaultSettings(Value: TMsgDefaultNetworkSettings);
begin
  if Value = RestoreDefaultSettings then
    Exit;
  FMaxThreadCount := MsgMaxThreadCount;
  FConnectionParamsTunning := MsgConnectionParamsTunning;
  FTestPacketCount := MsgTestPacketCount;
  FStartReceiveTimeOut := MsgStartReceiveTimeOut;
  FReceiveTimeOut := MsgReceiveTimeOut;
  FReceiveSleep := MsgReceiveSleep;
  FMinSendTimeOut := MsgMinSendTimeOut;
  FSendTimeOut := MsgSendTimeOut;
  FWaitForSendSleep := MsgWaitForSendSleep;
  FWaitForTimeOut := MsgWaitForTimeOut;
  FThreadsTerminateDelay := MsgThreadsTerminateDelay;
  case Value of
   msgLocal:
    begin
     FPacketSize := MsgLocalDefaultPacketSize;
     FDisconnectRetryCount := MsgLocalDisconnectRetryCount;
     FDisconnectDelay := MsgLocalDisconnectDelay;
    end;
   msgLAN:
    begin
     FPacketSize := MsgDefaultPacketSize;
     FDisconnectRetryCount := MsgDisconnectRetryCount;
     FDisconnectDelay := MsgDisconnectDelay;
    end;
   msgWAN:
    begin
     FPacketSize := MsgWANDefaultPacketSize;
     FDisconnectRetryCount := MsgWANDisconnectRetryCount;
     FDisconnectDelay := MsgWANDisconnectDelay;
    end;
   msgModem:
    begin
     FPacketSize := MsgModemDefaultPacketSize;
     FDisconnectRetryCount := MsgModemDisconnectRetryCount;
     FDisconnectDelay := MsgModemDisconnectDelay;
    end;
  end;
  FDefaultSettings := Value;
end; // SetDefaultSettings

// TMsgNetworkSettingsEditor



////////////////////////////////////////////////////////////////////////////////
//
// TMsgConnectionParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TMsgConnectionParamsEditor.Create;
begin
  inherited;
  FCryptoParamsEditor := TMsgCryptoParamsEditor.Create;
  FLocalPort := MsgDefaultClientPort;
  FLocalHost := MsgDefaultServerHost;
end;//Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgConnectionParamsEditor.Destroy;
begin
  FCryptoParamsEditor.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TMsgConnectionParamsEditor.Assign(Source: TPersistent);
begin
  if (Source <> nil) then
   if (Source is TMsgConnectionParamsEditor) then
    begin
      FLocalPort := TMsgConnectionParamsEditor(Source).LocalPort;
      FLocalHost := TMsgConnectionParamsEditor(Source).LocalHost;
      FCryptoParamsEditor.Assign(TMsgConnectionParamsEditor(Source).CryptoParams);
    end;
end; // Assign


//------------------------------------------------------------------------------
// return ConnectParams
//------------------------------------------------------------------------------
function TMsgConnectionParamsEditor.GetConnectParams: TMsgConnectParams;
begin
  Result.CryptoInfo := FCryptoParamsEditor.GetCryptoParams;
  Result.LocalHost := FLocalHost;
  Result.LocalPort := FLocalPort;
  Result.ServerID := Integer(MSG_INVALID_USER_ID);  // -1;  // invalid value
end; // GetConnectParams




////////////////////////////////////////////////////////////////////////////////
//
// Global functions
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// compression algorithm
//------------------------------------------------------------------------------
function ConverTMsgCompressionAlgorithmToMsgCompressionAlgorithm(
    CompressionAlgorithm: TMsgCompressionAlgorithm
          ): TMsgCompressionAlgorithm1;
begin
 Result := acaNone;
 case (CompressionAlgorithm) of
  caZLIB: Result := acaZLIB;
  caBZIP: Result := acaBZIP;
  caPPM: Result := acaPPM;
 end;
end; // ConverTMsgCompressionAlgorithmToMsgCompressionAlgorithm


//------------------------------------------------------------------------------
// compression algorithm
//------------------------------------------------------------------------------
function ConverTMsgCompressionAlgorithm1ToCompressionAlgorithm(
            CompressionAlgorithm: TMsgCompressionAlgorithm1
          ): TMsgCompressionAlgorithm;
begin
 Result := caNone;
 case (CompressionAlgorithm) of
  acaZLIB: Result := caZLIB;
  acaBZIP: Result := caBZIP;
  acaPPM: Result := caPPM;
 end;
end; // ConverTMsgCompressionAlgorithm1ToCompressionAlgorithm


//------------------------------------------------------------------------------
// returns true if file exists
//------------------------------------------------------------------------------
function aaFileExists(FileName: PAnsiChar): Boolean;
var h: THandle;
begin
  h := CreateFileA(FileName, GENERIC_READ,
      FILE_SHARE_WRITE or FILE_SHARE_READ, nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0);
  Result := (h <> INVALID_HANDLE_VALUE);
  if (h <> INVALID_HANDLE_VALUE) then
   FileClose(h);
end; // aaFileExists


//------------------------------------------------------------------------------
// checks if AnsiString matches pattern
//------------------------------------------------------------------------------
function IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean = true): Boolean;
var i : integer;
    delta : byte;
begin
  if (StrComp(PatternPtr,WildCardAnyFile) = 0) then
       begin
         Result:=True;
         exit;
       end;
  repeat
      if (StrComp(PatternPtr,WildCardMultipleChar) = 0) then
       begin
         Result:=True;
         exit;
       end
      else if (StrPtr^=#0) and (PatternPtr^ <> #0) then
       begin
         Result:=False;
         exit;
       end
      else if (StrPtr^=#0) then
       begin
         Result:=True;
         exit;
       end
      else
         begin
           case PatternPtr^ of
            WildCardMultipleChar:
               begin
                for i:=0 to Length(StrPtr)-1 do
                 begin
                  if IsStrMatchPattern(StrPtr+i,PatternPtr+1,bIgnoreCase) then
                   begin
                    Result := True;
                    exit;
                   end;
                 end;
                Result := False;
                exit;
               end;
            WildCardSingleChar:
               begin
                inc(StrPtr);
                inc(PatternPtr);
               end;
            else
               begin
                delta := byte(abs(byte(StrPtr^)-byte(PatternPtr^)));
//                if (delta=0) or
//                   (delta=byte(abs(byte('A')-byte('a')))) and (bIgnoreCase) then
                if (delta = 0) or
                   ((delta = byte(abs(byte('A') - byte('a')))) and
                   (bIgnoreCase) and
                   ((byte(StrPtr^) and (byte(PatternPtr^)) >=byte('A')))) then
                 begin
                  inc(StrPtr);
                  inc(PatternPtr);
                 end
                else
                 begin
                  Result:=False;
                  exit;
                 end;
               end;
           end; // case
         end; // non-simple cases
  until false;
end;//IsStrMatchPattern


procedure DeleteFiles(Path, Mask: AnsiString);
var
    sr: TSearchRec;
{$IFDEF D12H}
    s:  AnsiString;
{$ENDIF}
begin
  if (SysUtils.FindFirst(Path+Mask,faAnyFile,sr) = 0) then
   begin
    repeat
{$IFDEF D12H}
     s := sr.Name;
{$ENDIF}
     if ((sr.Name = '..') or (sr.Name = '.')) then
      continue;
{$IFDEF D12H}
       if (IsStrMatchPattern(pAnsiChar(s),pAnsiChar(Mask),true)) then
{$ELSE}
       if (IsStrMatchPattern(pAnsiChar(sr.Name),pAnsiChar(Mask),true)) then
{$ENDIF}
        if ((sr.Attr and faDirectory) = 0) then
          SysUtils.DeleteFile(Path+sr.Name);
    until (SysUtils.FindNext(sr) <> 0);
   end;
  SysUtils.FindClose(sr);
end; // DeleteFiles

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgComMain> initialization started');
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgComMain> initialization finished');
{$ENDIF}

end.
