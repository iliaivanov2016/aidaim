{Copyright:      Hagen Reddmann  mailto:HaReddmann@AOL.COM
 Author:         Hagen Reddmann
 Remarks:        freeware, but this Copyright must be included
 known Problems: none
 Version:        3.0,  Part I from Delphi Encryption Compendium  ( DEC Part I)
                 Delphi 2-4, designed and testet under D3 & D4
 Description:    Include a Selection of various Cipher's (Encryption Algo)
                 impl. Algo:
                   Gost, Blowfish, IDEA, SAFER in 6 Types,
                   SAFER-K40  (konvetional), SAFER-SK40 (with Keyscheduling),
                   SAFER-K64, SAFER-SK64, SAFER-K128, SAFER-SK128,
                   TEA, TEAN (TEA extended), SCOP, Q128, 3Way,
                   Twofish, Shark, Square

 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}

//-----------------------------------------------------//
//                                                     //
//  Modified by AidAim Software, 2001                  //
//                                                     //
//-----------------------------------------------------//

unit ETblCipher;

{$I ETblVer.inc}

interface

{$I VER.INC}

uses SysUtils, Classes,ESFSDECUtil;

const {ErrorCode's for ECipherException}
  errGeneric        = 0;  {generic Error}
  errInvalidKey     = 1;  {Decode Key is not correct}
  errInvalidKeySize = 2;  {Size of the Key is too large}
  errNotInitialized = 3;  {Methods Init() or InitKey() were not called}
  errInvalidMACMode = 4;  {CalcMAC can't use cmECB, cmOFB}
  errCantCalc       = 5;

type
  ECipherException = class(Exception)
  public
    ErrorCode: Integer;
  end;

type


{all Cipher Classes in this Unit, a good Selection}
  TCipherMode = (cmCTS, cmCBC, cmCFB, cmOFB, cmECB, cmCTSMAC, cmCBCMAC, cmCFBMAC);
{ the Cipher Modes:
  cmCTS     Cipher Text Stealing, a Variant from cmCBC, but relaxes
            the restriction that the DataSize must be a mulitply from BufSize,
            this is the Defaultmode, fast and Bytewise
  cmCBC     Cipher Block Chaining
  cmCFB     K-bit Cipher Feedback, here is K = 8 -> 1 Byte
  cmOFB     K-bit Output Feedback, here is K = 8 -> 1 Byte
  cmECB *   Electronic Codebook, DataSize must be a multiply from BufSize

  cmCTSMAC  Build a Message Authentication Code in cmCTS Mode
  cmCBCMAC  Build a CBC-MAC
  cmCFBMAC  Build a CFB-MAC
}

  TCipherClass = class of TCipher;
//-------- from hash ------------
// hash
 {the Base-Class of all Hashs}
  THash = class(TProtection)
  protected
    class function TestVector: Pointer; virtual; {must override}
    procedure CodeInit(Action: TPAction); override; {TProtection Methods, You can use a Hash to En/Decode}
    procedure CodeDone(Action: TPAction); override; {TProtection Methods}
    procedure CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction); override; {TProtection Methods}
    procedure Protect(IsInit: Boolean); {calls any installed Protection}
  public
    destructor Destroy; override;
    procedure Init; virtual;
    procedure Calc(const Data; DataSize: Integer); virtual; {must override}
    procedure Done; virtual;
    function DigestKey: Pointer; virtual; {must override}
    function DigestStr(Format: Integer): AnsiString;

    class function DigestKeySize: Integer; virtual; {must override}
{$IFDEF VER_D4H} // new features from D4
    class function CalcBuffer(const Buffer; BufferSize: Integer; Protection: TProtection = nil; Format: Integer = fmtDEFAULT): AnsiString; overload;
    class function CalcStream(const Stream: TStream; StreamSize: Integer; Protection: TProtection = nil; Format: Integer = fmtDEFAULT): AnsiString; overload;
    class function CalcAnsiString(const Data: AnsiString; Protection: TProtection = nil; Format: Integer = fmtDEFAULT): AnsiString; overload;
    class function CalcFile(const FileName: AnsiString; Protection: TProtection = nil; Format: Integer = fmtDEFAULT): AnsiString; overload;
{$ELSE}
    class function CalcBuffer(const Buffer; BufferSize: Integer; Protection: TProtection; Format: Integer): AnsiString;
    class function CalcStream(const Stream: TStream; StreamSize: Integer; Protection: TProtection; Format: Integer): AnsiString;
    class function CalcAnsiString(const Data: AnsiString; Protection: TProtection; Format: Integer): AnsiString;
    class function CalcFile(const FileName: AnsiString; Protection: TProtection; Format: Integer): AnsiString;
{$ENDIF}    
{test the correct working}
    class function SelfTest: Boolean;
  end;
// HMAC's - Hash Message Authentication Code's
  TMAC = class(TProtection) // generic MAC, encrypt Password with any AProtection and XOR's with
  protected                 // the Initstate from the Hash (DigestKey)
    FPassword: AnsiString;      // final Digest is encrypted with AProtecion
    procedure Init(Hash: THash); virtual;    // Only used in all THash Descends
    procedure Done(Hash: THash); virtual;    // Only used in all THash Descends
  public
    constructor Create(const Password: AnsiString; AProtection: TProtection);
    destructor Destroy; override;
  end;

//-------- from hash end ------------

  THashClass = class of THash;

  TCipher = class(TProtection)
  private
    FMode: TCipherMode;
    FHash: THash;
    FHashClass: THashClass;
    FKeySize: Integer;
    FBufSize: Integer;
    FUserSize: Integer;
    FBuffer: Pointer;
    FVector: Pointer;
    FFeedback: Pointer;
    FUser: Pointer;
    FFlags: Integer;
    function GetHash: THash;
    procedure SetHashClass(Value: THashClass);
    procedure InternalCodeStream(Source, Dest: TStream; DataSize: Integer; Encode: Boolean);
    procedure InternalCodeFile(const Source, Dest: AnsiString; Encode: Boolean);
  protected
    function GetFlag(Index: Integer): Boolean;
    procedure SetFlag(Index: Integer; Value: Boolean); virtual;
{used in method Init()}
    procedure InitBegin(var Size: Integer);
    procedure InitEnd(IVector: Pointer); virtual;
{must override}
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); virtual;
    class function TestVector: Pointer; virtual;
{override TProtection Methods}
    procedure CodeInit(Action: TPAction); override;
    procedure CodeDone(Action: TPAction); override;
    procedure CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction); override;
{the encode function, must override}
    procedure Encode(Data: Pointer); virtual;
{the decode function, must override}
    procedure Decode(Data: Pointer); virtual;
{the individual Userdata and Buffer}
    property User: Pointer read FUser;
    property Buffer: Pointer read FBuffer;
    property UserSize: Integer read FUserSize;
  public
    constructor Create(const Password: AnsiString; AProtection: TProtection);
    destructor Destroy; override;
    class function MaxKeySize: Integer;
{performs a Test of correct work}
    class function SelfTest: Boolean;
{initialization form the Cipher}
    procedure Init(const Key; Size: Integer; IVector: Pointer); virtual;
    procedure InitKey(const Key: AnsiString; IVector: Pointer);
{reset the Feedbackregister with the actual IVector}
    procedure Done; virtual;
{protect the security Data's, Feedback, Buffer, Vector etc.}
    procedure Protect; virtual;

    procedure EncodeBuffer(const Source; var Dest; DataSize: Integer);
    procedure DecodeBuffer(const Source; var Dest; DataSize: Integer);
    function  EncodeAnsiString(const Source: AnsiString): AnsiString;
    function  DecodeAnsiString(const Source: AnsiString): AnsiString;
    procedure EncodeFile(const Source, Dest: AnsiString);
    procedure DecodeFile(const Source, Dest: AnsiString);
    procedure EncodeStream(const Source, Dest: TStream; DataSize: Integer);
    procedure DecodeStream(const Source, Dest: TStream; DataSize: Integer);

{calculate a MAC, Message Authentication Code, can be use in
 cmCBCMAC, cmCTSMAC, cmCFBMAC Modes -> Dest is not modified, or
 cmCBC, cmCTS, cmCFB Modes -> normal En/Decoding of Dest.}
    function CalcMAC(Format: Integer): AnsiString;

{the Cipher Mode = cmXXX}
    property Mode: TCipherMode read FMode write FMode;
{the Current Hash-Object, to build a Digest from InitKey()}
    property Hash: THash read GetHash;
{the Class of the Hash-Object}
    property HashClass: THashClass read FHashClass write SetHashClass;
{the maximal KeySize and BufSize (Size of Feedback, Buffer and Vector}
    property KeySize: Integer read FKeySize;
    property BufSize: Integer read FBufSize;

{Init() was called}
    property Initialized: Boolean index 1 read GetFlag write SetFlag;
{the actual IVector, BufSize Bytes long}
    property Vector: Pointer read FVector;
{the Feedback register, BufSize Bytes long}
    property Feedback: Pointer read FFeedback;
{the Key is set from InitKey() and the Hash.DigestKey^ include the encrypted Hash-Key}
    property HasHashKey: Boolean index 0 read GetFlag;
  end;

// now the Cipher's


function DefaultCipherClass: TCipherClass;
procedure SetDefaultCipherClass(CipherClass: TCipherClass);
procedure RaiseCipherException(const ErrorCode: Integer; const Msg: AnsiString);
function RegisterCipher(const ACipher: TCipherClass; const AName, ADescription: AnsiString): Boolean;
function UnregisterCipher(const ACipher: TCipherClass): Boolean;
function CipherList: TStrings;
procedure CipherNames(List: TStrings);
function GetCipherClass(const Name: AnsiString): TCipherClass;
function GetCipherName(CipherClass: TCipherClass): AnsiString;

const
  CheckCipherKeySize: Boolean = False;
{set to True raises Exception when Size of the Key is too large, (Method Init())
 otherwise will truncate the Key, default mode is False}

//------------ from cipher1 -----------
type
  TCipher_Rijndael = class(TCipher)
  private
    FRounds: Integer;
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  public
    procedure Init(const Key; Size: Integer; IVector: Pointer); override;
  end;
//------------ from cipher1 end -----------
//------------ from hash -----------
  THash_MD4 = class(THash)
  private
    FCount: LongWord;
    FBuffer: array[0..63] of Byte;
    FDigest: array[0..9] of LongWord;
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); virtual;
  public
    class function DigestKeySize: Integer; override;
    procedure Init; override;
    procedure Done; override;
    procedure Calc(const Data; DataSize: Integer); override;
    function DigestKey: Pointer; override;
  end;

  THash_RipeMD256 = class(THash_MD4)
  protected
    class function TestVector: Pointer; override;
    procedure Transform(Buffer: PIntArray); override;
  public
{DigestKey-Size 256 bit}
    class function DigestKeySize: Integer; override;
    procedure Init; override;
  end;

// check sum
  TChecksum = class(THash);

  THash_XOR32 = class(TChecksum)
  private
    FCRC: LongWord;
  protected
    class function TestVector: Pointer; override;
  public
    class function DigestKeySize: Integer; override;
    procedure Init; override;
    procedure Calc(const Data; DataSize: Integer); override;
    function DigestKey: Pointer; override;
  end;

  THash_CRC32 = class(THash_XOR32)
  private
  protected
    class function TestVector: Pointer; override;
  public
    procedure Init; override;
    procedure Calc(const Data; DataSize: Integer); override;
    procedure Done; override;
  end;
// general
function DefaultHashClass: THashClass;
procedure SetDefaultHashClass(HashClass: THashClass);
function RegisterHash(const AHash: THashClass; const AName, ADescription: AnsiString): Boolean;
function UnregisterHash(const AHash: THashClass): Boolean;
function HashList: TStrings;
procedure HashNames(List: TStrings);
function GetHashClass(const Name: AnsiString): THashClass;
function GetHashName(HashClass: THashClass): AnsiString;

//------------ from hash end -----------

implementation

uses ESFSDECConst, Windows;

{$I cipher1.inc}

const

  FDefaultHashClass: THashClass = THash_RipeMD256;
  FDefaultCipherClass : TCipherClass = TCipher_Rijndael;
  FCipherList         : TStringList  = nil;
  FHashList: TStringList = nil;

function DefaultCipherClass: TCipherClass;
begin
  Result := FDefaultCipherClass;
end;

procedure SetDefaultCipherClass(CipherClass: TCipherClass);
begin
  if CipherClass = nil then FDefaultCipherClass := TCipher_Rijndael
    else FDefaultCipherClass := CipherClass;
end;

procedure RaiseCipherException(const ErrorCode: Integer; const Msg: AnsiString);
var
  E: ECipherException;
begin
  E := ECipherException.Create(Msg);
  E.ErrorCode := ErrorCode;
  raise E;
end;

function RegisterCipher(const ACipher: TCipherClass; const AName, ADescription: AnsiString): Boolean;
var
  I: Integer;
  S: AnsiString;
begin
  Result := False;
  if ACipher = nil then Exit;
  S := Trim(AName);
  if S = '' then
  begin
    S := ACipher.ClassName;
    if S[1] = 'T' then Delete(S, 1, 1);
    I := Pos('_', S);
    if I > 0 then Delete(S, 1, I);
  end;
  S := S + '=' + ADescription;
  I := CipherList.IndexOfObject(Pointer(ACipher));
  if I < 0 then CipherList.AddObject(S, Pointer(ACipher))
    else CipherList[I] := S;
  Result := True;
end;

function UnregisterCipher(const ACipher: TCipherClass): Boolean;
var
  I: Integer;
begin
  Result := False;
  repeat
    I := CipherList.IndexOfObject(Pointer(ACipher));
    if I < 0 then Break;
    Result := True;
    CipherList.Delete(I);
  until False;
end;

function CipherList: TStrings;
begin
  if not IsObject(FCipherList, TStringList) then FCipherList := TStringList.Create;
  Result := FCipherList;
end;

procedure CipherNames(List: TStrings);
var
  I: Integer;
begin
  if not IsObject(List, TStrings) then Exit;
  for I := 0 to CipherList.Count-1 do
    List.AddObject(FCipherList.Names[I], FCipherList.Objects[I]);    
end;

function GetCipherClass(const Name: AnsiString): TCipherClass;
var
  I: Integer;
  N: AnsiString;
begin
  Result := nil;
  N := Name;
  I := Pos('_', N);
  if I > 0 then Delete(N, 1, I);
  for I := 0 to CipherList.Count-1 do
    if AnsiCompareText(N, GetShortClassName(TClass(FCipherList.Objects[I]))) = 0 then
    begin
      Result := TCipherClass(FCipherList.Objects[I]);
      Exit;
    end;
  I := FCipherList.IndexOfName(N);
  if I >= 0 then Result := TCipherClass(FCipherList.Objects[I]);
end;

function GetCipherName(CipherClass: TCipherClass): AnsiString;
var
  I: Integer;
begin
  I := CipherList.IndexOfObject(Pointer(CipherClass));
  if I >= 0 then Result := FCipherList.Names[I]
    else Result := GetShortClassName(CipherClass); 
end;

function TCipher.GetFlag(Index: Integer): Boolean;
begin
  Result := FFlags and (1 shl Index) <> 0;
end;

procedure TCipher.SetFlag(Index: Integer; Value: Boolean);
begin
  Index := 1 shl Index;
  if Value then FFlags := FFlags or Index
    else FFlags := FFlags and not Index;
end;

procedure TCipher.InitBegin(var Size: Integer);
begin
  Initialized := False;
  Protect;
  if Size < 0 then Size := 0;
  if Size > KeySize then
    if not CheckCipherKeySize then Size := KeySize
      else RaiseCipherException(errInvalidKeySize, Format(sInvalidKeySize, [ClassName, 0, KeySize]));
end;

procedure TCipher.InitEnd(IVector: Pointer);
begin
  if IVector = nil then Encode(Vector)
    else Move(IVector^, Vector^, BufSize);
  Move(Vector^, Feedback^, BufSize);
  Initialized := True;
end;

class procedure TCipher.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  ABufSize := 0;
  AKeySize := 0;
  AUserSize := 0;
end;

class function TCipher.TestVector: Pointer;
begin
  Result := GetTestVector;
end;

procedure TCipher.Encode(Data: Pointer);
begin
end;

procedure TCipher.Decode(Data: Pointer);
begin
end;

constructor TCipher.Create(const Password: AnsiString; AProtection: TProtection);
begin
  inherited Create(AProtection);
  FHashClass := DefaultHashClass;
  GetContext(FBufSize, FKeySize, FUserSize);
  GetMem(FVector, FBufSize);
  GetMem(FFeedback, FBufSize);
  GetMem(FBuffer, FBufSize);
  GetMem(FUser, FUserSize);
  Protect;
  if Password <> '' then InitKey(Password, nil);
end;

destructor TCipher.Destroy;
begin
  Protect;
  ReallocMem(FVector, 0);
  ReallocMem(FFeedback, 0);
  ReallocMem(FBuffer, 0);
  ReallocMem(FUser, 0);
  FHash.Release;
  FHash := nil;
  inherited Destroy;
end;

class function TCipher.MaxKeySize: Integer;
var
  Dummy: Integer;
begin
  GetContext(Dummy, Result, Dummy);
end;

class function TCipher.SelfTest: Boolean;
var
  Data: array[0..63] of AnsiChar;
  Key: AnsiString;
  SaveKeyCheck: Boolean;
begin
  Result       := InitTestIsOk; {have anonyme modified the testvectors ?}
{we will use the ClassName as Key :-)}
  Key          := ClassName;
  SaveKeyCheck := CheckCipherKeySize;
  with Self.Create('', nil) do
  try
    CheckCipherKeySize := False;
    Mode := cmCTS;
    Init(PAnsiChar(Key)^, Length(Key), nil);
    EncodeBuffer(GetTestVector^, Data, 32);
    Result := Result and (MemCompare(TestVector, @Data, 32) = 0);
    Done;
    DecodeBuffer(Data, Data, 32);
    Result := Result and (MemCompare(GetTestVector, @Data, 32) = 0);
  finally
    CheckCipherKeySize := SaveKeyCheck;
    Free;
  end;
  FillChar(Data, SizeOf(Data), 0);
end;

procedure TCipher.Init(const Key; Size: Integer; IVector: Pointer);
begin
end;

procedure TCipher.InitKey(const Key: AnsiString; IVector: Pointer);
var
  I: Integer;
begin
  Hash.Init;
  Hash.Calc(PAnsiChar(Key)^, Length(Key));
  Hash.Done;
  I := Hash.DigestKeySize;
  if I > FKeySize then I := FKeySize; {generaly will truncate to large Keys}
  Init(Hash.DigestKey^, I, IVector);
  EncodeBuffer(Hash.DigestKey^, Hash.DigestKey^, Hash.DigestKeySize);
  Done;
  SetFlag(0, True);
end;

procedure TCipher.Done;
begin
  if MemCompare(FVector, FFeedback, FBufSize) = 0 then Exit;
  Move(FFeedback^, FBuffer^, FBufSize);
  Move(FVector^, FFeedback^, FBufSize);
end;

procedure TCipher.Protect;
begin
  SetFlag(0, False);
  Initialized := False;
// a Crypto Fanatican say: this is better !!
  FillChar(FVector^, FBufSize, $AA);
  FillChar(FFeedback^, FBufSize, $AA);
  FillChar(FBuffer^, FBufSize, $AA);
  FillChar(FUser^, FUserSize, $AA);

  FillChar(FVector^, FBufSize, $55);
  FillChar(FFeedback^, FBufSize, $55);
  FillChar(FBuffer^, FBufSize, $55);
  FillChar(FUser^, FUserSize, $55);

  FillChar(FVector^, FBufSize, $FF);
  FillChar(FFeedback^, FBufSize, $FF);
  FillChar(FBuffer^, FBufSize, 0);
  FillChar(FUser^, FUserSize, 0);
end;

function TCipher.GetHash: THash;
begin
  if not IsObject(FHash, THash) then
  begin
    if FHashClass = nil then FHashClass := DefaultHashClass;
    FHash := FHashClass.Create(nil);
    FHash.AddRef;
  end;
  Result := FHash;
end;

procedure TCipher.SetHashClass(Value: THashClass);
begin
  if Value <> FHashClass then
  begin
    FHash.Release;
    FHash := nil;
    FHashClass := Value;
    if FHashClass = nil then FHashClass := DefaultHashClass;
  end;
end;

procedure TCipher.InternalCodeStream(Source, Dest: TStream; DataSize: Integer; Encode: Boolean);
const
  maxBufSize = 1024 * 4;
var
  Buf: PAnsiChar;
  SPos: Integer;
  DPos: Integer;
  Len: Integer;
  Proc: procedure(const Source; var Dest; DataSize: Integer) of object;
  Size: Integer;
begin
  if Source = nil then Exit;
  if Encode or (Mode in [cmCBCMAC, cmCTSMAC, cmCFBMAC]) then Proc := EncodeBuffer
    else Proc := DecodeBuffer;
  if Dest = nil then Dest := Source;
  if DataSize < 0 then
  begin
    DataSize := Source.Size;
    Source.Position := 0;
  end;
  Buf := nil;
  Size := DataSize;
  DoProgress(Self, 0, Size);
  try
    Buf    := AllocMem(maxBufSize);
    DPos   := Dest.Position;
    SPos   := Source.Position;
    if Mode in [cmCTSMAC, cmCBCMAC, cmCFBMAC] then
    begin
      while DataSize > 0 do
      begin
        Len := DataSize;
        if Len > maxBufSize then Len := maxBufSize;
        Len := Source.Read(Buf^, Len);
        if Len <= 0 then Break;
        Proc(Buf^, Buf^, Len);
        Dec(DataSize, Len);
        DoProgress(Self, Size - DataSize, Size);
      end;
    end else
      while DataSize > 0 do
      begin
        Source.Position := SPos;
        Len := DataSize;
        if Len > maxBufSize then Len := maxBufSize;
        Len := Source.Read(Buf^, Len);
        SPos := Source.Position;
        if Len <= 0 then Break;
        Proc(Buf^, Buf^, Len);
        Dest.Position := DPos;
        Dest.Write(Buf^, Len);
        DPos := Dest.Position;
        Dec(DataSize, Len);
        DoProgress(Self, Size - DataSize, Size);
      end;
  finally
    DoProgress(Self, 0, 0);
    ReallocMem(Buf, 0);
  end;
end;

procedure TCipher.InternalCodeFile(const Source, Dest: AnsiString; Encode: Boolean);
var
  S,D: TFileStream;
begin
  S := nil;
  D := nil;
  try
    if Mode in [cmCBCMAC, cmCTSMAC, cmCFBMAC] then
    begin
      S := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
      D := S;
    end else
      if (AnsiCompareText(Source, Dest) <> 0) and (Trim(Dest) <> '') then
      begin
        S := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
        D := TFileStream.Create(Dest, fmCreate);
      end else
      begin
        S := TFileStream.Create(Source, fmOpenReadWrite);
        D := S;
      end;
    InternalCodeStream(S, D, -1, Encode);
  finally
    S.Free;
    if S <> D then
    begin
{$IFDEF VER_D3H}
      D.Size := D.Position;
{$ENDIF}
      D.Free;
    end;
  end;
end;

procedure TCipher.EncodeStream(const Source, Dest: TStream; DataSize: Integer);
begin
  InternalCodeStream(Source, Dest, DataSize, True);
end;

procedure TCipher.DecodeStream(const Source, Dest: TStream; DataSize: Integer);
begin
  InternalCodeStream(Source, Dest, DataSize, False);
end;

procedure TCipher.EncodeFile(const Source, Dest: AnsiString);
begin
  InternalCodeFile(Source, Dest, True);
end;

procedure TCipher.DecodeFile(const Source, Dest: AnsiString);
begin
  InternalCodeFile(Source, Dest, False);
end;

function TCipher.EncodeAnsiString(const Source: AnsiString): AnsiString;
begin
  SetLength(Result, Length(Source));
  EncodeBuffer(PAnsiChar(Source)^, PAnsiChar(Result)^, Length(Source));
  if Mode in [cmCBCMAC, cmCTSMAC, cmCFBMAC] then Result := '';
end;

function TCipher.DecodeAnsiString(const Source: AnsiString): AnsiString;
begin
  SetLength(Result, Length(Source));
  DecodeBuffer(PAnsiChar(Source)^, PAnsiChar(Result)^, Length(Source));
  if Mode in [cmCBCMAC, cmCTSMAC, cmCFBMAC] then Result := '';
end;

procedure TCipher.EncodeBuffer(const Source; var Dest; DataSize: Integer);
var
  S,D,F: PByte;
begin
  if not Initialized then
    RaiseCipherException(errNotInitialized, Format(sNotInitialized, [ClassName]));
  S := @Source;
  D := @Dest;
  case FMode of
    cmECB:
      begin
        if S <> D then Move(S^, D^, DataSize);
        while DataSize >= FBufSize do
        begin
          Encode(D);
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if DataSize > 0 then
        begin
          Move(D^, FBuffer^, DataSize);
          Encode(FBuffer);
          Move(FBuffer^, D^, DataSize);
        end;
      end;
    cmCTS:
      begin
        while DataSize >= FBufSize do
        begin
          XORBuffers(S, FFeedback, FBufSize, D);
          Encode(D);
          XORBuffers(D, FFeedback, FBufSize, FFeedback);
          Inc(S, FBufSize);
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(S, FBuffer, DataSize, D);
          XORBuffers(FBuffer, FFeedback, FBufSize, FFeedback);
        end;
      end;
    cmCBC:
      begin
        F := FFeedback;
        while DataSize >= FBufSize do
        begin
          XORBuffers(S, F, FBufSize, D);
          Encode(D);
          F := D;
          Inc(S, FBufSize);
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        Move(F^, FFeedback^, FBufSize);
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(S, FBuffer, DataSize, D);
          XORBuffers(FBuffer, FFeedback, FBufSize, FFeedback);
        end;
      end;
    cmCFB:
      while DataSize > 0 do
      begin
        Move(FFeedback^, FBuffer^, FBufSize);
        Encode(FBuffer);
        D^ := S^ xor PByte(FBuffer)^;
        Move(PByteArray(FFeedback)[1], FFeedback^, FBufSize-1);
        PByteArray(FFeedback)[FBufSize-1] := D^;
        Inc(D);
        Inc(S);
        Dec(DataSize);
      end;
    cmOFB:
      while DataSize > 0 do
      begin
        Move(FFeedback^, FBuffer^, FBufSize);
        Encode(FBuffer);
        D^ := S^ xor PByte(FBuffer)^;
        Move(PByteArray(FFeedback)[1], FFeedback^, FBufSize-1);
        PByteArray(FFeedback)[FBufSize-1] := PByte(FBuffer)^;
        Inc(D);
        Inc(S);
        Dec(DataSize);
      end;
    cmCTSMAC:
      begin
        while DataSize >= FBufSize do
        begin
          XORBuffers(S, FFeedback, FBufSize, FBuffer);
          Encode(FBuffer);
          XORBuffers(FBuffer, FFeedback, FBufSize, FFeedback);
          Inc(S, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(FBuffer, FFeedback, FBufSize, FFeedback);
        end;
      end;
    cmCBCMAC:
      begin
        while DataSize >= FBufSize do
        begin
          XORBuffers(S, FFeedback, FBufSize, FBuffer);
          Encode(FBuffer);
          Move(FBuffer^, FFeedback^, FBufSize);
          Inc(S, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(FBuffer, FFeedback, FBufSize, FFeedback);
        end;
      end;
    cmCFBMAC:
      while DataSize > 0 do
      begin
        Move(FFeedback^, FBuffer^, FBufSize);
        Encode(FBuffer);
        Move(PByteArray(FFeedback)[1], FFeedback^, FBufSize-1);
        PByteArray(FFeedback)[FBufSize-1] := S^ xor PByte(FBuffer)^;
        Inc(S);
        Dec(DataSize);
      end;
  end;
end;

procedure TCipher.DecodeBuffer(const Source; var Dest; DataSize: Integer);
var
  S,D,F,B: PByte;
begin
  if not Initialized then
    RaiseCipherException(errNotInitialized, Format(sNotInitialized, [ClassName]));
  S := @Source;
  D := @Dest;
  case FMode of
    cmECB:
      begin
        if S <> D then Move(S^, D^, DataSize);
        while DataSize >= FBufSize do
        begin
          Decode(D);
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if DataSize > 0 then
        begin
          Move(D^, FBuffer^, DataSize);
          Encode(FBuffer);
          Move(FBuffer^, D^, DataSize);
        end;
      end;
    cmCTS:
      begin
        if S <> D then Move(S^, D^, DataSize);
        F := FFeedback;
        B := FBuffer;
        while DataSize >= FBufSize do
        begin
          XORBuffers(D, F, FBufSize, B);
          Decode(D);
          XORBuffers(D, F, FBufSize, D);
          S := B;
          B := F;
          F := S;
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if F <> FFeedback then Move(F^, FFeedback^, FBufSize);
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(FBuffer, D, DataSize, D);
          XORBuffers(FBuffer, FFeedback, FBufSize, FFeedback);
        end;
      end;
    cmCBC:
      begin
        if S <> D then Move(S^, D^, DataSize);
        F := FFeedback;
        B := FBuffer;
        while DataSize >= FBufSize do
        begin
          Move(D^, B^, FBufSize);
          Decode(D);
          XORBuffers(F, D, FBufSize, D);
          S := B;
          B := F;
          F := S;
          Inc(D, FBufSize);
          Dec(DataSize, FBufSize);
        end;
        if F <> FFeedback then Move(F^, FFeedback^, FBufSize);
        if DataSize > 0 then
        begin
          Move(FFeedback^, FBuffer^, FBufSize);
          Encode(FBuffer);
          XORBuffers(D, FBuffer, DataSize, D);
          XORBuffers(FBuffer, FFeedback, FBufSize, FFeedback);
        end;
      end;
    cmCFB:
      while DataSize > 0 do
      begin
        Move(FFeedback^, FBuffer^, FBufSize);
        Encode(FBuffer);
        Move(PByteArray(FFeedback)[1], FFeedback^, FBufSize-1);
        PByteArray(FFeedback)[FBufSize-1] := S^;
        D^ := S^ xor PByte(FBuffer)^;
        Inc(D);
        Inc(S);
        Dec(DataSize);
      end;
    cmOFB:
      while DataSize > 0 do
      begin
        Move(FFeedback^, FBuffer^, FBufSize);
        Encode(FBuffer);
        D^ := S^ xor PByte(FBuffer)^;
        Move(PByteArray(FFeedback)[1], FFeedback^, FBufSize-1);
        PByteArray(FFeedback)[FBufSize-1] := PByte(FBuffer)^;
        Inc(D);
        Inc(S);
        Dec(DataSize);
      end;
    cmCTSMAC, cmCBCMAC, cmCFBMAC:
      begin
        EncodeBuffer(Source, Dest, DataSize);
        Exit;
      end;
  end;
end;

procedure TCipher.CodeInit(Action: TPAction);
begin
  if not Initialized then
    RaiseCipherException(errNotInitialized, Format(sNotInitialized, [ClassName]));
{  if (Mode in [cmCBCMAC, cmCTSMAC, cmCFBMAC]) <> (Action = paCalc) then
    RaiseCipherException(errCantCalc, Format(sCantCalc, [ClassName]));}
  if Action <> paCalc then
    if Action <> paWipe then Done
      else RndXORBuffer(RndTimeSeed, FFeedback^, FBufSize);
  inherited CodeInit(Action);
end;

procedure TCipher.CodeDone(Action: TPAction);
begin
  inherited CodeDone(Action);
  if Action <> paCalc then
    if Action <> paWipe then Done
      else RndXORBuffer(RndTimeSeed, FFeedback^, FBufSize);
end;

procedure TCipher.CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction);
begin
  if Action = paDecode then
  begin
    if Action in Actions then
      DecodeBuffer(Buffer, Buffer, BufferSize);
    inherited CodeBuf(Buffer, BufferSize, Action);
  end else
  begin
    inherited CodeBuf(Buffer, BufferSize, Action);
    if Action in Actions then
      EncodeBuffer(Buffer, Buffer, BufferSize);
  end;
end;

function TCipher.CalcMAC(Format: Integer): AnsiString;
var
  B: PByteArray;
begin
  if Mode in [cmECB, cmOFB] then
    RaiseCipherException(errInvalidMACMode, sInvalidMACMode);
  Done;
  B := AllocMem(FBufSize); 
  try 
    Move(FBuffer^, B^, FBufSize);
    EncodeBuffer(B^, B^, FBufSize); 
    SetLength(Result, FBufSize);
    Move(FFeedback^, PAnsiChar(Result)^, FBufSize);
    if Protection <> nil then Result := Protection.CodeAnsiString(Result, paScramble, Format) 
      else Result := StrToFormat(PAnsiChar(Result), Length(Result), Format);
  finally 
    ReallocMem(B, 0);
    Done; 
  end;
end; 
 
 
type
  PCipherRec = ^TCipherRec;
  TCipherRec = packed record
                  case Integer of 
                    0: (X: array[0..7] of Byte); 
                    1: (A, B: LongWord); 
                end;
 
	
	
	
// ------- from cipher1 ----------------- 
const
{don't change this}
  Rijndael_Blocks =  4;
  Rijndael_Rounds = 14;
	
class procedure TCipher_Rijndael.GetContext(var ABufSize, AKeySize, AUserSize: Integer); 
begin
  ABufSize := Rijndael_Blocks * 4;
  AKeySize := 32;
  AUserSize := (Rijndael_Rounds + 1) * Rijndael_Blocks * SizeOf(Integer) * 2;
end; 
	
const
  TCipher_Rijndael_TestVector : array[0..31] of byte =
    ( $94,$6D,$2B,$5E,$E0,$AD,$1B,$5C,$A5,$23,$A5,$13,$95,$8B,$3D,$2D,$93,$87,$F3,$37,$45,$51,$F6,$58,$9B,$E7,$90,$1B,$36,$87,$F9,$A9 );

class function TCipher_Rijndael.TestVector: Pointer;
begin
  Result := @TCipher_Rijndael_TestVector;
end;

procedure TCipher_Rijndael.Encode(Data: Pointer); 
var 
  P,K: PInteger;
  I,A,B,C,D: Integer;
begin
  P := User; 
  K := Data;
  for I := 2 to FRounds do 
  begin 
    A := K^ xor P^;                             Inc(P); Inc(K);
    B := K^ xor P^;                             Inc(P); Inc(K); 
    C := K^ xor P^;                             Inc(P); Inc(K);
    D := K^ xor P^;                             Inc(P); 
 
    K^ := Rijndael_T[0, D and $FF]        xor 
          Rijndael_T[1, A shr  8 and $FF] xor 
          Rijndael_T[2, B shr 16 and $FF] xor
          Rijndael_T[3, C shr 24];                      Dec(K);
    K^ := Rijndael_T[0, C and $FF]        xor 
          Rijndael_T[1, D shr  8 and $FF] xor
          Rijndael_T[2, A shr 16 and $FF] xor 
          Rijndael_T[3, B shr 24];                      Dec(K);
    K^ := Rijndael_T[0, B and $FF]        xor 
          Rijndael_T[1, C shr  8 and $FF] xor 
          Rijndael_T[2, D shr 16 and $FF] xor
          Rijndael_T[3, A shr 24];                      Dec(K);
    K^ := Rijndael_T[0, A and $FF]        xor
          Rijndael_T[1, B shr  8 and $FF] xor 
          Rijndael_T[2, C shr 16 and $FF] xor
          Rijndael_T[3, D shr 24];
  end; 
 
  A := K^ xor P^;                                       Inc(P); Inc(K); 
  B := K^ xor P^;                                       Inc(P); Inc(K);
  C := K^ xor P^;                                       Inc(P); Inc(K);
  D := K^ xor P^;                                       Inc(P);
	
  K^ := Rijndael_S[0, D and $FF]               or 
        Rijndael_S[0, A shr  8 and $FF] shl  8 or
        Rijndael_S[0, B shr 16 and $FF] shl 16 or 
        Rijndael_S[0, C shr 24]         shl 24;                 Dec(K); 
  K^ := Rijndael_S[0, C and $FF]               or 
        Rijndael_S[0, D shr  8 and $FF] shl  8 or
        Rijndael_S[0, A shr 16 and $FF] shl 16 or 
        Rijndael_S[0, B shr 24]         shl 24;                 Dec(K); 
  K^ := Rijndael_S[0, B and $FF]               or
        Rijndael_S[0, C shr  8 and $FF] shl  8 or 
        Rijndael_S[0, D shr 16 and $FF] shl 16 or
        Rijndael_S[0, A shr 24]         shl 24;                 Dec(K);
  K^ := Rijndael_S[0, A and $FF]               or
        Rijndael_S[0, B shr  8 and $FF] shl  8 or
        Rijndael_S[0, C shr 16 and $FF] shl 16 or
        Rijndael_S[0, D shr 24]         shl 24;
 
  for I := 1 to Rijndael_Blocks do 
  begin 
    K^ := K^ xor P^; 
    Inc(P);
    Inc(K);
  end;
end; 
 
procedure TCipher_Rijndael.Decode(Data: Pointer); 
var 
  P,K: PInteger;
  I,A,B,C,D: Integer; 
begin
  P := Pointer(PAnsiChar(User) + UserSize shr 1); 
  Inc(P, FRounds * 4 +3);
  K := Pointer(PAnsiChar(Data) + 12);
  for I := 2 to FRounds do
  begin
    D := K^ xor P^;                             Dec(P); Dec(K);
    C := K^ xor P^;                             Dec(P); Dec(K);
    B := K^ xor P^;                             Dec(P); Dec(K);
    A := K^ xor P^;                             Dec(P);

    K^ := Rijndael_T[4, A and $FF]        xor
          Rijndael_T[5, D shr  8 and $FF] xor
          Rijndael_T[6, C shr 16 and $FF] xor
          Rijndael_T[7, B shr 24];                      Inc(K);
    K^ := Rijndael_T[4, B and $FF]        xor
          Rijndael_T[5, A shr  8 and $FF] xor
          Rijndael_T[6, D shr 16 and $FF] xor
          Rijndael_T[7, C shr 24];                      Inc(K);
    K^ := Rijndael_T[4, C and $FF]        xor
          Rijndael_T[5, B shr  8 and $FF] xor
          Rijndael_T[6, A shr 16 and $FF] xor
          Rijndael_T[7, D shr 24];                      Inc(K);
    K^ := Rijndael_T[4, D and $FF]        xor
          Rijndael_T[5, C shr  8 and $FF] xor
          Rijndael_T[6, B shr 16 and $FF] xor
          Rijndael_T[7, A shr 24];
  end;

  D := K^ xor P^;                                       Dec(P); Dec(K);
  C := K^ xor P^;                                       Dec(P); Dec(K);
  B := K^ xor P^;                                       Dec(P); Dec(K);
  A := K^ xor P^;                                       Dec(P);

  K^ := Rijndael_S[1, A and $FF]               or
        Rijndael_S[1, D shr  8 and $FF] shl  8 or
        Rijndael_S[1, C shr 16 and $FF] shl 16 or
        Rijndael_S[1, B shr 24]         shl 24;                 Inc(K);
  K^ := Rijndael_S[1, B and $FF]               or
        Rijndael_S[1, A shr  8 and $FF] shl  8 or
        Rijndael_S[1, D shr 16 and $FF] shl 16 or
        Rijndael_S[1, C shr 24]         shl 24;                 Inc(K);
  K^ := Rijndael_S[1, C and $FF]               or
        Rijndael_S[1, B shr  8 and $FF] shl  8 or
        Rijndael_S[1, A shr 16 and $FF] shl 16 or
        Rijndael_S[1, D shr 24]         shl 24;                 Inc(K);
  K^ := Rijndael_S[1, D and $FF]               or
        Rijndael_S[1, C shr  8 and $FF] shl  8 or
        Rijndael_S[1, B shr 16 and $FF] shl 16 or
        Rijndael_S[1, A shr 24]         shl 24;

  for I := 0 to 3 do
  begin
    K^ := K^ xor P^;
    Dec(P);
    Dec(K);
  end;
end;

procedure TCipher_Rijndael.Init(const Key; Size: Integer; IVector: Pointer);
var
  K: array[0..7] of Integer;

  procedure BuildEncodeKey;
  const
    RND_Data: array[0..29] of Byte = (
      $01,$02,$04,$08,$10,$20,$40,$80,$1B,$36,$6C,$D8,$AB,$4D,$9A,
      $2F,$5E,$BC,$63,$C6,$97,$35,$6A,$D4,$B3,$7D,$FA,$EF,$C5,$91);
  var
    T,R: Integer;

    procedure NextRounds;
    var
      J: Integer;
    begin
      J := 0;
      while (J < FRounds-6) and (R <= FRounds) do
      begin
        while (J < FRounds-6) and (T < Rijndael_Blocks) do
        begin
          PIntArray(User)[R * Rijndael_Blocks + T] := K[J];
          Inc(J);
          Inc(T);
        end;
        if T = Rijndael_Blocks then
        begin
          T := 0;
          Inc(R);
        end;
      end;
    end;

  var
    RND: PByte;
    B: PByte;
    I: Integer;
  begin
    R := 0;
    T := 0;
    RND := @RND_Data;
    NextRounds;
    while R <= FRounds do
    begin
      B  := @K;
      B^ := B^ xor Rijndael_S[0, K[FRounds -7] shr  8 and $FF] xor RND^; Inc(B);
      B^ := B^ xor Rijndael_S[0, K[FRounds -7] shr 16 and $FF];          Inc(B);
      B^ := B^ xor Rijndael_S[0, K[FRounds -7] shr 24];                  Inc(B);
      B^ := B^ xor Rijndael_S[0, K[FRounds -7] and $FF];
      Inc(RND);
      if FRounds = 14 then
      begin
        for I := 1 to 7 do K[I] := K[I] xor K[I -1];
        B  := @K[4];
        B^ := B^ xor Rijndael_S[0, K[3] and $FF];         Inc(B);
        B^ := B^ xor Rijndael_S[0, K[3] shr  8 and $FF];  Inc(B);
        B^ := B^ xor Rijndael_S[0, K[3] shr 16 and $FF];  Inc(B);
        B^ := B^ xor Rijndael_S[0, K[3] shr 24];
        for I := 5 to 7 do K[I] := K[I] xor K[I -1];
      end else
        for I := 1 to FRounds -7 do K[I] := K[I] xor K[I -1];
      NextRounds;
    end;
  end;

  procedure BuildDecodeKey;
  var
    I: Integer;
    D: PInteger;
  begin
    D := Pointer(PAnsiChar(User) + UserSize shr 1);
    Move(User^, D^, UserSize shr 1);
    Inc(D, 4);
    for I := 0 to FRounds * 4 - 5 do
    begin
      D^ :=     Rijndael_Key[D^ and $FF] xor
            ROL(Rijndael_Key[D^ shr  8 and $FF],  8) xor
            ROL(Rijndael_Key[D^ shr 16 and $FF], 16) xor
            ROL(Rijndael_Key[D^ shr 24],         24);
      Inc(D);
    end;
  end;

begin
  InitBegin(Size);
  if Size <= 16 then FRounds := 10 else
    if Size <= 24 then FRounds := 12 else FRounds := 14;
  FillChar(K, SizeOf(K), 0);
  Move(Key, K, Size);
  BuildEncodeKey;
  BuildDecodeKey;
  FillChar(K, SizeOf(K), 0);
  InitEnd(IVector);
end;
//------- from cipher1 end ----------------

//------------ from hash -----------
// hash message digest 4
const
  THash_MD4_TestVector : array[0..15] of byte =
    ( $25,$EA,$BF,$CC,$8C,$C9,$6F,$D9,$2D,$CF,$7E,$BD,$7F,$87,$7C,$7C );

class function THash_MD4.TestVector: Pointer; assembler;
begin
  Result := @THash_MD4_TestVector;
end;

procedure THash_MD4.Transform(Buffer: PIntArray);
{calculate the Digest, fast}
var
  A, B, C, D: LongWord;
begin
  A := FDigest[0];
  B := FDigest[1];
  C := FDigest[2];
  D := FDigest[3];

  Inc(A, Buffer[ 0] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 1] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[ 2] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[ 3] + (C and D or not C and A)); B := B shl 19 or B shr 13;
  Inc(A, Buffer[ 4] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 5] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[ 6] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[ 7] + (C and D or not C and A)); B := B shl 19 or B shr 13;
  Inc(A, Buffer[ 8] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 9] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[10] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[11] + (C and D or not C and A)); B := B shl 19 or B shr 13;
  Inc(A, Buffer[12] + (B and C or not B and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[13] + (A and B or not A and C)); D := D shl  7 or D shr 25;
  Inc(C, Buffer[14] + (D and A or not D and B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[15] + (C and D or not C and A)); B := B shl 19 or B shr 13;

  Inc(A, Buffer[ 0] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 4] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[ 8] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[12] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;
  Inc(A, Buffer[ 1] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 5] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[ 9] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[13] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;
  Inc(A, Buffer[ 2] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 6] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[10] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[14] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;
  Inc(A, Buffer[ 3] + $5A827999 + (B and C or B and D or C and D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 7] + $5A827999 + (A and B or A and C or B and C)); D := D shl  5 or D shr 27;
  Inc(C, Buffer[11] + $5A827999 + (D and A or D and B or A and B)); C := C shl  9 or C shr 23;
  Inc(B, Buffer[15] + $5A827999 + (C and D or C and A or D and A)); B := B shl 13 or B shr 19;

  Inc(A, Buffer[ 0] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 8] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 4] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[12] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;
  Inc(A, Buffer[ 2] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[10] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 6] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[14] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;
  Inc(A, Buffer[ 1] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[ 9] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 5] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[13] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;
  Inc(A, Buffer[ 3] + $6ED9EBA1 + (B xor C xor D)); A := A shl  3 or A shr 29;
  Inc(D, Buffer[11] + $6ED9EBA1 + (A xor B xor C)); D := D shl  9 or D shr 23;
  Inc(C, Buffer[ 7] + $6ED9EBA1 + (D xor A xor B)); C := C shl 11 or C shr 21;
  Inc(B, Buffer[15] + $6ED9EBA1 + (C xor D xor A)); B := B shl 15 or B shr 17;

  Inc(FDigest[0], A);
  Inc(FDigest[1], B);
  Inc(FDigest[2], C);
  Inc(FDigest[3], D);
end;

class function THash_MD4.DigestKeySize: Integer;
begin
  Result := 16;
end;

function THash_MD4.DigestKey: Pointer;
begin
  Result := @FDigest;
end;

procedure THash_MD4.Init;
begin
  FillChar(FBuffer, SizeOf(FBuffer), 0);
{all Descend from MD4 (MD4, SHA1, RipeMD128, RipeMD160, RipeMD256) use this Init-Key}
  FDigest[0] := $67452301;
  FDigest[1] := $EFCDAB89;
  FDigest[2] := $98BADCFE;
  FDigest[3] := $10325476;
  FDigest[4] := $C3D2E1F0;
{for RMD320}
  FDigest[5] := $76543210;
  FDigest[6] := $FEDCBA98;
  FDigest[7] := $89ABCDEF;
  FDigest[8] := $01234567;
  FDigest[9] := $3C2D1E0F;
  FCount := 0;
  Protect(True);
end;

procedure THash_MD4.Done;
var
  I: Integer;
  S: Comp;
begin
  I := FCount and $3F;
  FBuffer[I] := $80;
  Inc(I);
  if I > 64 - 8 then
  begin
    FillChar(FBuffer[I], 64 - I, 0);
    Transform(@FBuffer);
    I := 0;
  end;
  FillChar(FBuffer[I], 64 - I, 0);
  S := FCount * 8;
  Move(S, FBuffer[64 - 8], SizeOf(S));
  Transform(@FBuffer);
  FillChar(FBuffer, SizeOf(FBuffer), 0);
  Protect(False);
end;

procedure THash_MD4.Calc(const Data; DataSize: Integer);
var
  Index: Integer;
  P: PAnsiChar;
begin
  if DataSize <= 0 then Exit;
  Index := FCount and $3F;
  Inc(FCount, DataSize);
  if Index > 0 then
  begin
    if DataSize < 64 - Index then
    begin
      Move(Data, FBuffer[Index], DataSize);
      Exit;
    end;
    Move(Data, FBuffer[Index], 64 - Index);
    Transform(@FBuffer);
    Index := 64 - Index;
    Dec(DataSize, Index);
  end;
  P := @TByteArray(Data)[Index];
  Inc(Index, DataSize and not $3F);
  while DataSize >= 64 do
  begin
    Transform(Pointer(P));
    Inc(P, 64);
    Dec(DataSize, 64);
  end;
  Move(TByteArray(Data)[Index], FBuffer, DataSize);
end;
// ripe 256
const
  THash_RipeMD256_TestVector : array[0..31] of byte =
    ( $C3,$B1,$D7,$AC,$A8,$9A,$47,$7A,$38,$D3,$6D,$39,$EF,$00,$FB,$45,$FC,$4E,$C3,$1A,$71,$21,$DB,$9E,$1C,$76,$C5,$DE,$99,$88,$18,$C2 );

class function THash_RipeMD256.TestVector: Pointer;
begin
  Result := @THash_RipeMD256_TestVector;
end;

procedure THash_RipeMD256.Transform(Buffer: PIntArray);
var
  A1, B1, C1, D1: LongWord;
  A2, B2, C2, D2: LongWord;
  T: LongWord;
begin
  A1 := FDigest[0];
  B1 := FDigest[1];
  C1 := FDigest[2];
  D1 := FDigest[3];
  A2 := FDigest[4];
  B2 := FDigest[5];
  C2 := FDigest[6];
  D2 := FDigest[7];

  Inc(A1, B1 xor C1 xor D1 + Buffer[ 0]); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 1]); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 2]); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 3]); B1 := B1 shl 12 or B1 shr 20;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 4]); A1 := A1 shl  5 or A1 shr 27;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 5]); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, D1 xor A1 xor B1 + Buffer[ 6]); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 xor D1 xor A1 + Buffer[ 7]); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 xor C1 xor D1 + Buffer[ 8]); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 xor B1 xor C1 + Buffer[ 9]); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, D1 xor A1 xor B1 + Buffer[10]); C1 := C1 shl 14 or C1 shr 18;
  Inc(B1, C1 xor D1 xor A1 + Buffer[11]); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 xor C1 xor D1 + Buffer[12]); A1 := A1 shl  6 or A1 shr 26;
  Inc(D1, A1 xor B1 xor C1 + Buffer[13]); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 xor A1 xor B1 + Buffer[14]); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 xor D1 xor A1 + Buffer[15]); B1 := B1 shl  8 or B1 shr 24;

  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[ 5] + $50A28BE6); A2 := A2 shl  8 or A2 shr 24;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[14] + $50A28BE6); D2 := D2 shl  9 or D2 shr 23;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[ 7] + $50A28BE6); C2 := C2 shl  9 or C2 shr 23;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[ 0] + $50A28BE6); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[ 9] + $50A28BE6); A2 := A2 shl 13 or A2 shr 19;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[ 2] + $50A28BE6); D2 := D2 shl 15 or D2 shr 17;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[11] + $50A28BE6); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[ 4] + $50A28BE6); B2 := B2 shl  5 or B2 shr 27;
  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[13] + $50A28BE6); A2 := A2 shl  7 or A2 shr 25;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[ 6] + $50A28BE6); D2 := D2 shl  7 or D2 shr 25;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[15] + $50A28BE6); C2 := C2 shl  8 or C2 shr 24;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[ 8] + $50A28BE6); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 and D2 or C2 and not D2 + Buffer[ 1] + $50A28BE6); A2 := A2 shl 14 or A2 shr 18;
  Inc(D2, A2 and C2 or B2 and not C2 + Buffer[10] + $50A28BE6); D2 := D2 shl 14 or D2 shr 18;
  Inc(C2, D2 and B2 or A2 and not B2 + Buffer[ 3] + $50A28BE6); C2 := C2 shl 12 or C2 shr 20;
  Inc(B2, C2 and A2 or D2 and not A2 + Buffer[12] + $50A28BE6); B2 := B2 shl  6 or B2 shr 26;

  T := A1; A1 := A2; A2 := T;

  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 7] + $5A827999); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 4] + $5A827999); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[13] + $5A827999); C1 := C1 shl  8 or C1 shr 24;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 1] + $5A827999); B1 := B1 shl 13 or B1 shr 19;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[10] + $5A827999); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 6] + $5A827999); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[15] + $5A827999); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 3] + $5A827999); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[12] + $5A827999); A1 := A1 shl  7 or A1 shr 25;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[ 0] + $5A827999); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[ 9] + $5A827999); C1 := C1 shl 15 or C1 shr 17;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 5] + $5A827999); B1 := B1 shl  9 or B1 shr 23;
  Inc(A1, B1 and C1 or not B1 and D1 + Buffer[ 2] + $5A827999); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and B1 or not A1 and C1 + Buffer[14] + $5A827999); D1 := D1 shl  7 or D1 shr 25;
  Inc(C1, D1 and A1 or not D1 and B1 + Buffer[11] + $5A827999); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, C1 and D1 or not C1 and A1 + Buffer[ 8] + $5A827999); B1 := B1 shl 12 or B1 shr 20;

  Inc(A2, (B2 or not C2) xor D2 + Buffer[ 6] + $5C4DD124); A2 := A2 shl  9 or A2 shr 23;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[11] + $5C4DD124); D2 := D2 shl 13 or D2 shr 19;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 3] + $5C4DD124); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[ 7] + $5C4DD124); B2 := B2 shl  7 or B2 shr 25;
  Inc(A2, (B2 or not C2) xor D2 + Buffer[ 0] + $5C4DD124); A2 := A2 shl 12 or A2 shr 20;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[13] + $5C4DD124); D2 := D2 shl  8 or D2 shr 24;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 5] + $5C4DD124); C2 := C2 shl  9 or C2 shr 23;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[10] + $5C4DD124); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, (B2 or not C2) xor D2 + Buffer[14] + $5C4DD124); A2 := A2 shl  7 or A2 shr 25;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[15] + $5C4DD124); D2 := D2 shl  7 or D2 shr 25;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 8] + $5C4DD124); C2 := C2 shl 12 or C2 shr 20;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[12] + $5C4DD124); B2 := B2 shl  7 or B2 shr 25;
  Inc(A2, (B2 or not C2) xor D2 + Buffer[ 4] + $5C4DD124); A2 := A2 shl  6 or A2 shr 26;
  Inc(D2, (A2 or not B2) xor C2 + Buffer[ 9] + $5C4DD124); D2 := D2 shl 15 or D2 shr 17;
  Inc(C2, (D2 or not A2) xor B2 + Buffer[ 1] + $5C4DD124); C2 := C2 shl 13 or C2 shr 19;
  Inc(B2, (C2 or not D2) xor A2 + Buffer[ 2] + $5C4DD124); B2 := B2 shl 11 or B2 shr 21;

  T := B1; B1 := B2; B2 := T;

  Inc(A1, (B1 or not C1) xor D1 + Buffer[ 3] + $6ED9EBA1); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[10] + $6ED9EBA1); D1 := D1 shl 13 or D1 shr 19;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[14] + $6ED9EBA1); C1 := C1 shl  6 or C1 shr 26;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[ 4] + $6ED9EBA1); B1 := B1 shl  7 or B1 shr 25;
  Inc(A1, (B1 or not C1) xor D1 + Buffer[ 9] + $6ED9EBA1); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[15] + $6ED9EBA1); D1 := D1 shl  9 or D1 shr 23;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[ 8] + $6ED9EBA1); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[ 1] + $6ED9EBA1); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, (B1 or not C1) xor D1 + Buffer[ 2] + $6ED9EBA1); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[ 7] + $6ED9EBA1); D1 := D1 shl  8 or D1 shr 24;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[ 0] + $6ED9EBA1); C1 := C1 shl 13 or C1 shr 19;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[ 6] + $6ED9EBA1); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, (B1 or not C1) xor D1 + Buffer[13] + $6ED9EBA1); A1 := A1 shl  5 or A1 shr 27;
  Inc(D1, (A1 or not B1) xor C1 + Buffer[11] + $6ED9EBA1); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, (D1 or not A1) xor B1 + Buffer[ 5] + $6ED9EBA1); C1 := C1 shl  7 or C1 shr 25;
  Inc(B1, (C1 or not D1) xor A1 + Buffer[12] + $6ED9EBA1); B1 := B1 shl  5 or B1 shr 27;

  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[15] + $6D703EF3); A2 := A2 shl  9 or A2 shr 23;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[ 5] + $6D703EF3); D2 := D2 shl  7 or D2 shr 25;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[ 1] + $6D703EF3); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[ 3] + $6D703EF3); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[ 7] + $6D703EF3); A2 := A2 shl  8 or A2 shr 24;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[14] + $6D703EF3); D2 := D2 shl  6 or D2 shr 26;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[ 6] + $6D703EF3); C2 := C2 shl  6 or C2 shr 26;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[ 9] + $6D703EF3); B2 := B2 shl 14 or B2 shr 18;
  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[11] + $6D703EF3); A2 := A2 shl 12 or A2 shr 20;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[ 8] + $6D703EF3); D2 := D2 shl 13 or D2 shr 19;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[12] + $6D703EF3); C2 := C2 shl  5 or C2 shr 27;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[ 2] + $6D703EF3); B2 := B2 shl 14 or B2 shr 18;
  Inc(A2, B2 and C2 or not B2 and D2 + Buffer[10] + $6D703EF3); A2 := A2 shl 13 or A2 shr 19;
  Inc(D2, A2 and B2 or not A2 and C2 + Buffer[ 0] + $6D703EF3); D2 := D2 shl 13 or D2 shr 19;
  Inc(C2, D2 and A2 or not D2 and B2 + Buffer[ 4] + $6D703EF3); C2 := C2 shl  7 or C2 shr 25;
  Inc(B2, C2 and D2 or not C2 and A2 + Buffer[13] + $6D703EF3); B2 := B2 shl  5 or B2 shr 27;

  T := C1; C1 := C2; C2 := T;

  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 1] + $8F1BBCDC); A1 := A1 shl 11 or A1 shr 21;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 9] + $8F1BBCDC); D1 := D1 shl 12 or D1 shr 20;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[11] + $8F1BBCDC); C1 := C1 shl 14 or C1 shr 18;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[10] + $8F1BBCDC); B1 := B1 shl 15 or B1 shr 17;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[ 0] + $8F1BBCDC); A1 := A1 shl 14 or A1 shr 18;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 8] + $8F1BBCDC); D1 := D1 shl 15 or D1 shr 17;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[12] + $8F1BBCDC); C1 := C1 shl  9 or C1 shr 23;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 4] + $8F1BBCDC); B1 := B1 shl  8 or B1 shr 24;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[13] + $8F1BBCDC); A1 := A1 shl  9 or A1 shr 23;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 3] + $8F1BBCDC); D1 := D1 shl 14 or D1 shr 18;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 7] + $8F1BBCDC); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[15] + $8F1BBCDC); B1 := B1 shl  6 or B1 shr 26;
  Inc(A1, B1 and D1 or C1 and not D1 + Buffer[14] + $8F1BBCDC); A1 := A1 shl  8 or A1 shr 24;
  Inc(D1, A1 and C1 or B1 and not C1 + Buffer[ 5] + $8F1BBCDC); D1 := D1 shl  6 or D1 shr 26;
  Inc(C1, D1 and B1 or A1 and not B1 + Buffer[ 6] + $8F1BBCDC); C1 := C1 shl  5 or C1 shr 27;
  Inc(B1, C1 and A1 or D1 and not A1 + Buffer[ 2] + $8F1BBCDC); B1 := B1 shl 12 or B1 shr 20;

  Inc(A2, B2 xor C2 xor D2 + Buffer[ 8]); A2 := A2 shl 15 or A2 shr 17;
  Inc(D2, A2 xor B2 xor C2 + Buffer[ 6]); D2 := D2 shl  5 or D2 shr 27;
  Inc(C2, D2 xor A2 xor B2 + Buffer[ 4]); C2 := C2 shl  8 or C2 shr 24;
  Inc(B2, C2 xor D2 xor A2 + Buffer[ 1]); B2 := B2 shl 11 or B2 shr 21;
  Inc(A2, B2 xor C2 xor D2 + Buffer[ 3]); A2 := A2 shl 14 or A2 shr 18;
  Inc(D2, A2 xor B2 xor C2 + Buffer[11]); D2 := D2 shl 14 or D2 shr 18;
  Inc(C2, D2 xor A2 xor B2 + Buffer[15]); C2 := C2 shl  6 or C2 shr 26;
  Inc(B2, C2 xor D2 xor A2 + Buffer[ 0]); B2 := B2 shl 14 or B2 shr 18;
  Inc(A2, B2 xor C2 xor D2 + Buffer[ 5]); A2 := A2 shl  6 or A2 shr 26;
  Inc(D2, A2 xor B2 xor C2 + Buffer[12]); D2 := D2 shl  9 or D2 shr 23;
  Inc(C2, D2 xor A2 xor B2 + Buffer[ 2]); C2 := C2 shl 12 or C2 shr 20;
  Inc(B2, C2 xor D2 xor A2 + Buffer[13]); B2 := B2 shl  9 or B2 shr 23;
  Inc(A2, B2 xor C2 xor D2 + Buffer[ 9]); A2 := A2 shl 12 or A2 shr 20;
  Inc(D2, A2 xor B2 xor C2 + Buffer[ 7]); D2 := D2 shl  5 or D2 shr 27;
  Inc(C2, D2 xor A2 xor B2 + Buffer[10]); C2 := C2 shl 15 or C2 shr 17;
  Inc(B2, C2 xor D2 xor A2 + Buffer[14]); B2 := B2 shl  8 or B2 shr 24;

  T := D1; D1 := D2; D2 := T;

  Inc(FDigest[0], A1);
  Inc(FDigest[1], B1);
  Inc(FDigest[2], C1);
  Inc(FDigest[3], D1);
  Inc(FDigest[4], A2);
  Inc(FDigest[5], B2);
  Inc(FDigest[6], C2);
  Inc(FDigest[7], D2);
end;

class function THash_RipeMD256.DigestKeySize: Integer;
begin
  Result := 32;
end;

procedure THash_RipeMD256.Init;
begin
  FillChar(FBuffer, SizeOf(FBuffer), 0);
  FDigest[0] := $67452301;
  FDigest[1] := $EFCDAB89;
  FDigest[2] := $98BADCFE;
  FDigest[3] := $10325476;
  FDigest[4] := $76543210;
  FDigest[5] := $FEDCBA98;
  FDigest[6] := $89ABCDEF;
  FDigest[7] := $01234567;
  FDigest[8] := $01234567;
  FDigest[9] := $3C2D1E0F;
  FCount := 0;
  Protect(True);
end;

function DefaultHashClass: THashClass;
begin
  Result := FDefaultHashClass;
end;

procedure SetDefaultHashClass(HashClass: THashClass);
begin
  if HashClass = nil then FDefaultHashClass := THash_RipeMD256
    else FDefaultHashClass := HashClass;
end;

function RegisterHash(const AHash: THashClass; const AName, ADescription: AnsiString): Boolean;
var
  I: Integer;
  S: AnsiString;
begin
  Result := False;
  if AHash = nil then Exit;
  S := Trim(AName);
  if S = '' then
  begin
    S := AHash.ClassName;
    if S[1] = 'T' then Delete(S, 1, 1);
    I := Pos('_', S);
    if I > 0 then Delete(S, 1, I);
  end;
  S := S + '=' + ADescription;
  I := HashList.IndexOfObject(Pointer(AHash));
  if I < 0 then HashList.AddObject(S, Pointer(AHash))
    else HashList[I] := S;
  Result := True;
end;

function UnregisterHash(const AHash: THashClass): Boolean;
var
  I: Integer;
begin
  Result := False;
  repeat
    I := HashList.IndexOfObject(Pointer(AHash));
    if I < 0 then Break;
    Result := True;
    HashList.Delete(I);
  until False;
end;

function HashList: TStrings;
begin
  if not IsObject(FHashList, TStringList) then FHashList := TStringList.Create;
  Result := FHashList;
end;

procedure HashNames(List: TStrings);
var
  I: Integer;
begin
  if not IsObject(List, TStrings) then Exit;
  for I := 0 to HashList.Count-1 do
    List.AddObject(FHashList.Names[I], FHashList.Objects[I]);
end;

function GetHashClass(const Name: AnsiString): THashClass;
var
  I: Integer;
  N: AnsiString;
begin
  Result := nil;
  N := Name;
  I := Pos('_', N);
  if I > 0 then Delete(N, 1, I);
  for I := 0 to HashList.Count-1 do
    if AnsiCompareText(N, GetShortClassName(TClass(FHashList.Objects[I]))) = 0 then
    begin
      Result := THashClass(FHashList.Objects[I]);
      Exit;
    end;
  I := FHashList.IndexOfName(N);
  if I >= 0 then Result := THashClass(FHashList.Objects[I]);
end;

function GetHashName(HashClass: THashClass): AnsiString;
var
  I: Integer;
begin
  I := HashList.IndexOfObject(Pointer(HashClass));
  if I >= 0 then Result := FHashList.Names[I]
    else Result := GetShortClassName(HashClass);
end;

destructor THash.Destroy;
begin
  FillChar(DigestKey^, DigestKeySize, 0);
  inherited Destroy;
end;

procedure THash.Init;
begin
  Protect(True);
end;

procedure THash.Calc(const Data; DataSize: Integer);
begin
end;

procedure THash.Protect(IsInit: Boolean);
begin
  if Protection <> nil then
    if IsObject(Protection, TMAC) then
    begin
      with TMAC(Protection) do
        if IsInit then Init(Self) else Done(Self);
    end else
      if not IsInit then
        Protection.CodeBuffer(DigestKey^, DigestKeySize, paScramble);
end;

procedure THash.Done;
begin
  Protect(False);
end;

function THash.DigestKey: Pointer;
begin
  Result := GetTestVector;
end;

class function THash.DigestKeySize: Integer;
begin
  Result := 0;
end;

function THash.DigestStr(Format: Integer): AnsiString;
begin
  Result := StrToFormat(DigestKey, DigestKeySize, Format);
end;

class function THash.TestVector: Pointer;
begin
  Result := GetTestVector;
end;

class function THash.CalcStream(const Stream: TStream; StreamSize: Integer; Protection: TProtection; Format: Integer): AnsiString;
const
  maxBufSize = 1024 * 4;  {Buffersize for File, Stream-Access}
var
  Buf: Pointer;
  BufSize: Integer;
  Size: Integer;
  Hash: THash;
begin
  Hash := Create(Protection);
  with Hash do
  try
    Buf := AllocMem(maxBufSize);
    Init;
    if StreamSize < 0 then
 {if Size < 0 then reset the Position, otherwise, calc with the specific
  Size and from the aktual Position in the Stream}
    begin
      Stream.Position := 0;
      StreamSize := Stream.Size;
    end;
    Size := StreamSize;
    DoProgress(Hash, 0, Size);
    repeat
      BufSize := StreamSize;
      if BufSize > maxBufSize then BufSize := maxBufSize;
      BufSize := Stream.Read(Buf^, BufSize);
      if BufSize <= 0 then Break;
      Calc(Buf^, BufSize);
      Dec(StreamSize, BufSize);
      DoProgress(Hash, Size - StreamSize, Size);
    until BufSize <= 0;
    Done;
    Result := StrToFormat(DigestKey, DigestKeySize, Format);
  finally
    DoProgress(Hash, 0, 0);
    Free;
    ReallocMem(Buf, 0);
  end;
end;

class function THash.CalcAnsiString(const Data: AnsiString; Protection: TProtection; Format: Integer): AnsiString;
begin
  with Create(Protection) do
  try
    Init;
    Calc(PAnsiChar(Data)^, Length(Data));
    Done;
    Result := StrToFormat(DigestKey, DigestKeySize, Format);
  finally
    Free;
  end;
end;

class function THash.CalcFile(const FileName: AnsiString; Protection: TProtection; Format: Integer): AnsiString;
var
  S: TFileStream;
begin
  S := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Result := CalcStream(S, S.Size, Protection, Format);
  finally
    S.Free;
  end;
end;

class function THash.CalcBuffer(const Buffer; BufferSize: Integer; Protection: TProtection; Format: Integer): AnsiString;
begin
  with Create(Protection) do {create an Object from my Classtype}
  try
    Init;
    Calc(Buffer, BufferSize);
    Done;
    Result := StrToFormat(DigestKey, DigestKeySize, Format);
  finally
    Free; {destroy it}
  end;
end;

class function THash.SelfTest: Boolean;
var
  Test: AnsiString;
begin
  Test := CalcBuffer(GetTestVector^, 32, nil, fmtCOPY);
  Result := InitTestIsOk and (MemCompare(PAnsiChar(Test), TestVector, Length(Test)) = 0);
end;

procedure THash.CodeInit(Action: TPAction);
begin
  Init;
  if Action = paWipe then RndXORBuffer(RndTimeSeed, DigestKey^, DigestKeySize);
  inherited CodeInit(Action);
end;

procedure THash.CodeDone(Action: TPAction);
begin
  inherited CodeDone(Action);
  if (Action <> paCalc) then Init else Done;
end;

procedure THash.CodeBuf(var Buffer; const BufferSize: Integer; Action: TPAction);
var
  BPtr: PByte;
  CSize,DSize,BSize: Integer;
begin
  if Action <> paDecode then inherited CodeBuf(Buffer, BufferSize, Action);
  if Action in Actions then
  begin
    BPtr := @Buffer;
    if BPtr = nil then Exit;
    DSize := DigestKeySize;
    CSize := BufferSize;
    if Action = paCalc then
    begin
      Calc(Buffer, BufferSize);
    end else
    begin
      if Action in [paScramble, paWipe] then
      begin
        while CSize > 0 do
        begin
          BSize := CSize;
          if BSize > DSize then BSize := DSize;
          Calc(BPtr^, BSize);
          Done;
          Move(DigestKey^, BPtr^, BSize);
          Dec(CSize, BSize);
          Inc(BPtr, BSize);
        end;
      end else
        while CSize > 0 do
        begin
          BSize := DSize;
          if BSize > CSize then BSize := CSize;
          Calc(DigestKey^, DSize);
          Done;
          XORBuffers(DigestKey, BPtr, BSize, BPtr);
          Dec(CSize, BSize);
          Inc(BPtr, BSize);
        end;
    end;
  end;
  if Action = paDecode then
    inherited CodeBuf(Buffer, BufferSize, Action);
end;

procedure TMAC.Init(Hash: THash);
var
  Key: AnsiString;
begin
  if Length(FPassword) > 0 then
  begin
    Key := Hash.CalcAnsiString(FPassword, Protection, fmtCOPY);
    XORBuffers(Hash.DigestKey, PAnsiChar(Key), Length(Key), Hash.DigestKey);
    FillChar(PAnsiChar(Key)^, Length(Key), $AA);
    FillChar(PAnsiChar(Key)^, Length(Key), $55);
    FillChar(PAnsiChar(Key)^, Length(Key), 0);
  end;
end;

procedure TMAC.Done(Hash: THash);
begin
  if Protection <> nil then
    Protection.CodeBuffer(Hash.DigestKey^, Hash.DigestKeySize, paScramble);
end;

constructor TMAC.Create(const Password: AnsiString; AProtection: TProtection);
begin
  inherited Create(AProtection);
  SetLength(FPassword, Length(Password));
  Move(PAnsiChar(Password)^, PAnsiChar(FPassword)^, Length(Password));
end;

destructor TMAC.Destroy;
var
  I: Integer;
begin
  I := Length(FPassword);
  if I > 0 then
  begin
    FillChar(PAnsiChar(FPassword)^, I, $AA);
    FillChar(PAnsiChar(FPassword)^, I, $55);
    FillChar(PAnsiChar(FPassword)^, I, 0);
  end;
  FPassword := '';
  inherited Destroy;
end;
// check sum


class function THash_XOR32.DigestKeySize: Integer;
begin
  Result := 4;
end;

procedure THash_XOR32.Init;
begin
  FCRC := 0;
  Protect(True);
end;


{$IFDEF X64_ON}
const
  TXOR32_TestVector : array[0..3] of byte =
    ( $8d,$AD,$89,$7f);

class function THash_XOR32.TestVector: Pointer;
begin
Result := @TXOR32_TestVector;

{asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    08Dh,0ADh,089h,07Fh
end;}
end;

procedure THash_XOR32.Calc(const Data; DataSize: Integer);
{
assembler; register;
asm

         TEST    ECX,ECX
         JLE     @Exit
         PUSH    EAX
         MOV     EAX,[EAX].THash_XOR32.FCRC
         TEST    ECX,1
         JE      @@1
         XOR     AX,[EDX]
         INC     EDX
@@1:     SHR     ECX,1
         JECXZ   @@3
@@2:     ROL     EAX,5
         XOR     AX,[EDX]
         ADD     EDX,2
         DEC     ECX
         JNZ     @@2
@@3:     POP     EDX
         MOV     [EDX].THash_XOR32.FCRC,EAX
@Exit:}
var v:longWord;
var input: ^Byte;
begin
if DataSize>0 then
begin
     input:=Pointer(@Data);
     v:=  FCRC;
     if (DataSize and 1) <> 0 then
     begin
          v:= v XOR  input^;
          inc(Input);
          v:= v XOR  (input^ shl 8);
     end;
     DataSize :=  DataSize  div 2;
     if DataSize > 0 then
     begin
          repeat
          v:= (v shl 5) OR (v shr 27);
          v:= v xor  input^;

          //    1000 1001 1010 1101
          //0001 0001 0011 0101 1010 0000


          inc(Input);
          v:= v XOR  (input^ shl 8);
          inc(Input);
          dec(DataSize);
          until  DataSize = 0;

     end;
     FCRC := v;
end;
end;
{$ELSE}
class function THash_XOR32.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    08Dh,0ADh,089h,07Fh
end;

procedure THash_XOR32.Calc(const Data; DataSize: Integer); assembler; register;
asm
         TEST    ECX,ECX
         JLE     @Exit
         PUSH    EAX
         MOV     EAX,[EAX].THash_XOR32.FCRC
         TEST    ECX,1
         JE      @@1
         XOR     AX,[EDX]
         INC     EDX
@@1:     SHR     ECX,1
         JECXZ   @@3
@@2:     ROL     EAX,5
         XOR     AX,[EDX]
         ADD     EDX,2
         DEC     ECX
         JNZ     @@2
@@3:     POP     EDX
         MOV     [EDX].THash_XOR32.FCRC,EAX
@Exit:
end;
{$ENDIF}

function THash_XOR32.DigestKey: Pointer;
begin
  Result := @FCRC;
end;
procedure THash_CRC32.Init;
begin
  FCRC := $FFFFFFFF;
  Protect(True);
end;

{$IFDEF X64_ON}
const
  TCRC32_TestVector : array[0..3] of byte =
    ( $58,$EE,$1F,$31);


class function THash_CRC32.TestVector: Pointer;

begin

     Result :=  @TCRC32_TestVector;
{asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    058h,0EEh,01Fh,031h}
end;

procedure THash_CRC32.Calc(const Data; DataSize: Integer);
{
assembler; register;
asm
         PUSH   EAX
         MOV    EAX,[EAX].THash_CRC32.FCRC
        // CALL   CRC32
         POP    EDX
         MOV    [EDX].THash_CRC32.FCRC,EAX}
begin
  FCRC:=CRC32(FCRC,Pointer(@Data),Datasize);
end;
{$ELSE}

class function THash_CRC32.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    058h,0EEh,01Fh,031h
end;


procedure THash_CRC32.Calc(const Data; DataSize: Integer); assembler; register;
asm
         PUSH   EAX
         MOV    EAX,[EAX].THash_CRC32.FCRC
         CALL   CRC32
         POP    EDX
         MOV    [EDX].THash_CRC32.FCRC,EAX
end;
{$ENDIF}

procedure THash_CRC32.Done;
begin
  FCRC := not FCRC;
  Protect(False);
end;


//------------ from hash end -----------

{$IFDEF UseASM}
 {$IFDEF MSWINDOWS}
  {$IFNDEF 486GE}  // no Support for <= CPU 386

{ Ok, follow a BAD BAD dirty Trick, BUT realy realistic and correct

  The Problem:
    I will use for CPU's >= 486 the BSWAP Mnemonic to speedup Blowfish more.
    ( BSWAP swaps the Byteorder from a 32bit Word A,B,C,D to D,C,B,A and back
      and is the fastes Solution, but only for >= 486 CPU)
    I must wrote two assembler optimated function, one for >= 486
    and one for <= 386. -> En/Decode() and En/Decode386().

  The normal Solution:
    See in Hash.pas the SwapInteger proc. We can define a private
    procedural Field in TCipher_Blowfish that contains a pointer to the CPU
    depended code procedure.
    i.E. an implementation:
     TCipher_Blowfish.Encode()
     begin
       FProc(Data);
     end;
   The Program must make a call to the virtual Method Encode() and
   a second call to FProc(Data), and in the Init() or Constructor must
   we initialize these FProc Field.

 The Dirty Solution:
   A virtual Method, and ONLY a virtual Method, is identicaly to a
   private Field in the Object Class.
   This Class Definition is stored in the Code Segment.
   Now, we modifying, when CPU <= 386, these Field, from the Classdefinition
   in the Code Segment !!!, and save a new Methodaddress, the Address from
   TCipher_Blowfish.Encode386 etc.
   This changes have Effect to all TCipher_Blowfish Instances,
   but not descending Classes from TCipher_Blowfish :-)
   This Trick work's theoretical with BP5? upto D4.

 Ok, You say many expense for a little speed more !?
   YES, but have You this here known ? NO ?, but now.
}

procedure FindVirtualMethodAndChange(AClass: TClass; MethodAddr, NewAddress: Pointer);
// MethodAddr must explicit exists
type
  PPointer = ^Pointer;
const
  PageSize = SizeOf(Pointer);
var
  Table: PPointer;
  SaveFlag: DWORD;
begin
  Table := PPointer(AClass);
  while Table^ <> MethodAddr do Inc(Table);
  if VirtualProtect(Table, PageSize, PAGE_EXECUTE_READWRITE, @SaveFlag) then
  try
    Table^ := NewAddress;
  finally
    VirtualProtect(Table, PageSize, SaveFlag, @SaveFlag);
  end;
end;
  {$ENDIF}
 {$ENDIF}
{$ENDIF}

{$IFDEF VER_D3H}
procedure ModuleUnload(Module: Integer);
var
  I: Integer;
begin
  if IsObject(FCipherList, TStringList) then
    for I := FCipherList.Count-1 downto 0 do
      if Integer(FindClassHInstance(TClass(FCipherList.Objects[I]))) = Module then
        FCipherList.Delete(I);
end;
{$ENDIF}


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgCipher> initialization started');
{$ENDIF}

{$IFDEF UseASM}
 {$IFDEF MSWINDOWS}
  {$IFNDEF 486GE}  // no Support for <= CPU 386
{
  if CPUType <= 3 then  // CPU <= 386
  begin
    FindVirtualMethodAndChange(TCipher_Blowfish, @TCipher_Blowfish.Encode,
                                                 @TCipher_Blowfish.Encode386);
    FindVirtualMethodAndChange(TCipher_Blowfish, @TCipher_Blowfish.Decode,
                                                 @TCipher_Blowfish.Decode386);
  end;
}
  {$ENDIF}
 {$ENDIF}
{$ENDIF}
{$IFDEF VER_D3H}
{$IFDEF D16H}
//
{$ELSE}
  AddModuleUnloadProc(ModuleUnload);
{$ENDIF}
{$ENDIF}
{$IFNDEF ManualRegisterClasses}
//  RegisterCipher(TCipher_Blowfish, '', '');
//  RegisterCipher(TCipher_Square, '', '');
//  RegisterCipher(TCipher_Twofish, '', '');
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgCipher> initialization finished');
{$ENDIF}

finalization
{$IFDEF VER_D3H}
{$IFDEF D16H}
//
{$ELSE}
  RemoveModuleUnloadProc(ModuleUnload);
{$ENDIF}
{$ENDIF}
  FCipherList.Free;
  FCipherList := nil;
end.

