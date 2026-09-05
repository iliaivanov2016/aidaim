{*****************************************************************************

  Delphi Encryption Compendium (DEC Part I)
  Version 5.2, Part I, for Delphi 7 - 2009

  Remarks:          Freeware, Copyright must be included

  Original Author:  (c) 2006 Hagen Reddmann, HaReddmann [at] T-Online [dot] de
  Modifications:    (c) 2008 Arvid Winkelsdorf, info [at] digivendo [dot] de

  Last change:      02. November 2008

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

*****************************************************************************}

////////////////////////////////////////////////////////////////////////////////
//
// Updated to support x64 platform by AidAim Software in 2012, www.aidaim.com
//
////////////////////////////////////////////////////////////////////////////////


unit CPSDECCipher;

{$I CPSVer.Inc}
{$I VER.INC}

{$RANGECHECKS OFF}

interface

uses SysUtils, Classes, CPSDECUtil, CPSDECFmt;

{$I VER.INC}

type
  TCipher_Null         = class;  // Null cipher, does'nt encrypt, copying only
  TCipher_Blowfish     = class;
  TCipher_Twofish      = class;  {AES Round 2 Final Candidate}
  TCipher_Rijndael     = class;  {AES Round 2 Final Candidate}
  TCipher_Square       = class;
  TCipher_1DES         = class;  {Single DES  8 byte Blocksize,  8 byte Keysize  56 bits relevant}
  TCipher_2DES         = class;  {Triple DES  8 byte Blocksize, 16 byte Keysize 112 bits relevant}
  TCipher_3DES         = class;  {Triple DES  8 byte Blocksize, 24 byte Keysize 168 bits relevant}
  TCipher_2DDES        = class;  {Triple DES 16 byte Blocksize, 16 byte Keysize 112 bits relevant}
  TCipher_3DDES        = class;  {Triple DES 16 byte Blocksize, 24 byte Keysize 168 bits relevant}
  TCipher_3TDES        = class;  {Triple DES 24 byte Blocksize, 24 byte Keysize 168 bits relevant}

  TCipherContext = packed record
    KeySize: Integer;            // maximal key size in bytes
    BlockSize: Integer;          // mininmal block size in bytes, eg. 1 = Streamcipher
    BufferSize: Integer;         // internal buffersize in bytes
    UserSize: Integer;           // internal size in bytes of cipher dependend structures
    UserSave: Boolean;           
  end;

  TCipherState = (csNew, csInitialized, csEncode, csDecode, csPadded, csDone);
  TCipherStates = set of TCipherState;
{ TCipher.State represents the internal state of processing
  csNew         = cipher isn't initialized, .Init() must be called before en/decode
  csInitialized = cipher is initialized by .Init(), eg. Keysetup was processed
  csEncode      = Encodeing was started, and more chunks can be encoded, but not decoded
  csDecode      = Decodeing was started, and more chunks can be decoded, but not encoded
  csPadded      = trough En/Decodeing the messagechunks are padded, no more chunks can
                  be processed, the cipher is blocked.
  csDone        = Processing is finished and Cipher.Done was called. Now new En/Decoding
                  can be started without calling .Init() before. csDone is basicaly
                  identical to csInitialized, except Cipher.Buffer holds the encrypted
                  last state of Cipher.Feedback, thus Cipher.Buffer can be used as C-MAC.}

  TCipherMode = (cmCTSx, cmCBCx, cmCFB8, cmCFBx, cmOFB8, cmOFBx, cmCFS8, cmCFSx, cmECBx);
{ cmCTSx = double CBC, with CFS8 padding of truncated final block
  cmCBCx = Cipher Block Chainung, with CFB8 padding of truncated final block
  cmCFB8 = 8bit Cipher Feedback mode
  cmCFBx = CFB on Blocksize of Cipher
  cmOFB8 = 8bit Output Feedback mode
  cmOFBx = OFB on Blocksize bytes
  cmCFS8 = 8Bit CFS, double CFB
  cmCFSx = CFS on Blocksize bytes
  cmECBx = Electronic Code Book

  Modes cmCBCx, cmCTSx, cmCFBx, cmOFBx, cmCFSx, cmECBx working on Blocks of
  Cipher.BufferSize bytes, on Blockcipher that's equal to Cipher.BlockSize.
  
  Modes cmCFB8, cmOFB8, cmCFS8 work on 8 bit Feedback Shift Registers.

  Modes cmCTSx, cmCFSx, cmCFS8 are prohibitary modes developed by me. These modes
  works such as cmCBCx, cmCFBx, cmCFB8 but with double XOR'ing of the inputstream
  into Feedback register.

  Mode cmECBx need message padding to a multiple of Cipher.BlockSize and should
  be only used in 1byte Streamciphers.

  Modes cmCTSx, cmCBCx need no external padding, because internal the last truncated
  block is padded by cmCFS8 or cmCFB8. After padding these Mode can't be used to
  process more data. If it needed to process chunks of data then each chunk must
  be algined to Cipher.BufferSize bytes.

  Modes cmCFBx,cmCFB8,cmOFBx,cmOFB8,cmCFSx,cmCFS8 need no padding.

}
  TDECCipherCodeEvent = procedure(const Source; var Dest; DataSize: Integer) of object;

  TDECCipherClass = class of TDECCipher;

  TDECCipher = class(TDECObject)
  private
    FState: TCipherState;
    FMode: TCipherMode;
    FData: PByteArray;
    FDataSize: Integer;
    procedure SetMode(Value: TCipherMode);
  protected
    FBufferSize: Integer;
    FBufferIndex: Integer;
    FUserSize: Integer;
    FBuffer: PByteArray;
    FVector: PByteArray;
    FFeedback: PByteArray;
    FUser: Pointer;
    FUserSave: Pointer;
    procedure CheckState(States: TCipherStates);
    procedure DoInit(const Key; Size: Integer); virtual;
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); virtual;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); virtual;
  public
    constructor Create; override;
    destructor Destroy; override;

    class function Context: TCipherContext; virtual;

    procedure Init(const Key; Size: Integer; const IVector; IVectorSize: Integer; IFiller: Byte = $FF); overload;
    procedure Init(const Key: Binary; const IVector: Binary = ''; IFiller: Byte = $FF); overload;
    procedure Done;
    procedure Protect; virtual;

    procedure Encode(const Source; var Dest; DataSize: Integer);
    procedure Decode(const Source; var Dest; DataSize: Integer);

    function  EncodeBinary(const Source: Binary; Format: TDECFormatClass = nil): Binary;
    function  DecodeBinary(const Source: Binary; Format: TDECFormatClass = nil): Binary;
    procedure EncodeFile(const Source, Dest: String; const Progress: IDECProgress = nil);
    procedure DecodeFile(const Source, Dest: String; const Progress: IDECProgress = nil);
    procedure EncodeStream(const Source, Dest: TStream; const DataSize: Int64; const Progress: IDECProgress = nil);
    procedure DecodeStream(const Source, Dest: TStream; const DataSize: Int64; const Progress: IDECProgress = nil);

    function  CalcMAC(Format: TDECFormatClass = nil): Binary;

    property InitVectorSize: Integer read FBufferSize;
    property InitVector: PByteArray read FVector; // buffer size bytes
    property Feedback: PByteArray read FFeedback; // buffer size bytes

    property State: TCipherState read FState;
  published
    property Mode: TCipherMode read FMode write SetMode;
  end;

  TCipher_Null = class(TDECCipher)
  protected
    procedure DoInit(const Key; Size: Integer); override;
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;

  TCipher_Blowfish = class(TDECCipher)
  protected
    procedure DoInit(const Key; Size: Integer); override;
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;

  TCipher_Twofish = class(TDECCipher)
  protected
    procedure DoInit(const Key; Size: Integer); override;
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;

  TCipher_Rijndael = class(TDECCipher)
  private
    FRounds: Integer;
  protected
    procedure DoInit(const Key; Size: Integer); override;
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  published
    property Rounds: Integer read FRounds;
  end;

  TCipher_Square = class(TDECCipher)
  protected
    procedure DoInit(const Key; Size: Integer); override;
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;

  TCipher_1DES = class(TDECCipher)
  protected
    procedure DoInitKey(const Data: array of Byte; Key: PLongArray; Reverse: Boolean);
    procedure DoInit(const Key; Size: Integer); override;
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;

  TCipher_2DES = class(TCipher_1DES)
  protected
    procedure DoInit(const Key; Size: Integer); override;
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;

  TCipher_3DES = class(TCipher_1DES)
  protected
    procedure DoInit(const Key; Size: Integer); override;
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;

  TCipher_2DDES = class(TCipher_2DES)
  protected
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;

  TCipher_3DDES = class(TCipher_3DES)
  protected
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;

  TCipher_3TDES = class(TCipher_3DES)
  protected
    procedure DoEncode(Source, Dest: Pointer; Size: Integer); override;
    procedure DoDecode(Source, Dest: Pointer; Size: Integer); override;
  public
    class function Context: TCipherContext; override;
  end;


function  ValidCipher(CipherClass: TDECCipherClass = nil): TDECCipherClass;
function  CipherByName(const Name: String): TDECCipherClass;
function  CipherByIdentity(Identity: Cardinal): TDECCipherClass;
procedure SetDefaultCipherClass(CipherClass: TDECCipherClass = nil);

var
  StreamBufferSize: Integer = 8192;

implementation

uses CPSDECData;

resourcestring
  sAlreadyPadded        = 'Cipher has already been padded, cannot process message';
  sInvalidState         = 'Cipher is not in valid state for this action';
  sInvalidMessageLength = 'Message length for %s must be a multiple of %d bytes';
  sKeyMaterialToLarge   = 'Keymaterial is too large for use (Security Issue)';
  sIVMaterialToLarge    = 'Initvector is too large for use (Security Issue)';
  sInvalidMACMode       = 'Invalid Cipher mode to compute MAC';
  sCipherNoDefault      = 'No default cipher has been registered';

var
  FDefaultCipherClass: TDECCipherClass = nil;

function ValidCipher(CipherClass: TDECCipherClass): TDECCipherClass;
begin
  if CipherClass <> nil then Result := CipherClass
    else Result := FDefaultCipherClass;
  if Result = nil then raise EDECException.Create(sCipherNoDefault);
end;

function CipherByName(const Name: String): TDECCipherClass;
begin
  Result := TDECCipherClass(DECClassByName(Name, TDECCipher));
end;

function CipherByIdentity(Identity: Cardinal): TDECCipherClass;
begin
  Result := TDECCipherClass(DECClassByIdentity(Identity, TDECCipher));
end;

procedure SetDefaultCipherClass(CipherClass: TDECCipherClass);
begin
  if CipherClass <> nil then CipherClass.Register;
  FDefaultCipherClass := CipherClass;
end;

procedure TDECCipher.SetMode(Value: TCipherMode);
begin
  if Value <> FMode then
  begin
    if not (FState in [csNew, csInitialized, csDone]) then Done;
    FMode := Value;
  end;
end;

procedure TDECCipher.CheckState(States: TCipherStates);
var
  S: String;
begin
  if not (FState in States) then
  begin
    if FState = csPadded then S := sAlreadyPadded
      else S := sInvalidState;
    raise EDECException.Create(S);
  end;
end;

procedure TDECCipher.DoInit(const Key; Size: Integer);
begin
end;

procedure TDECCipher.DoEncode(Source, Dest: Pointer; Size: Integer);
begin
end;

procedure TDECCipher.DoDecode(Source, Dest: Pointer; Size: Integer);
begin
end;

constructor TDECCipher.Create;
var
  MustUserSaved: Boolean;
begin
  inherited Create;
  with Context do
  begin
    FBufferSize := BufferSize;
    FUserSize := UserSize;
    MustUserSaved := UserSave;
  end;
  FDataSize := FBufferSize * 3 + FUserSize;
  if MustUserSaved then Inc(FDataSize, FUserSize);
  ReallocMem(FData, FDataSize);
  FVector := @FData[0];
  FFeedback := @FVector[FBufferSize];
  FBuffer := @FFeedback[FBufferSize];
  FUser := @FBuffer[FBufferSize];
  if MustUserSaved then FUserSave := @PByteArray(FUser)[FUserSize]
    else FUserSave := nil;
  Protect;
end;

destructor TDECCipher.Destroy;
begin
  Protect;
  ReallocMem(FData, 0);
  FVector := nil;
  FFeedback := nil;
  FBuffer := nil;
  FUser := nil;
  FUserSave := nil;
  inherited Destroy;
end;

class function TDECCipher.Context: TCipherContext;
begin
 FillChar(Result,SizeOf(Result),$00);
end;

procedure TDECCipher.Init(const Key; Size: Integer; const IVector; IVectorSize: Integer; IFiller: Byte);
begin
  Protect;
// commented by Leo Martin, AidAim Software - crashes on simple ciphers that uses RIPE_MD_256 hash  
{
  if Size > Context.KeySize then
    raise EDECException.Create(sKeyMaterialToLarge);
  if IVectorSize > FBufferSize then
    raise EDECException.Create(sIVMaterialToLarge);
}

  DoInit(Key, Size);
  if FUserSave <> nil then
    Move(FUser^, FUserSave^, FUserSize);

  FillChar(FVector^, FBufferSize, IFiller);
  if IVectorSize = 0 then
  begin
    DoEncode(FVector, FVector, FBufferSize);
    if FUserSave <> nil then Move(FUserSave^, FUser^, FUserSize);
  end else Move(IVector, FVector^, IVectorSize);
  Move(FVector^, FFeedback^, FBufferSize);
  FState := csInitialized;
end;

procedure TDECCipher.Init(const Key: Binary; const IVector: Binary; IFiller: Byte);
begin
  Init(Key[1], Length(Key), IVector[1], Length(IVector), IFiller);
end;

procedure TDECCipher.Done;
begin
  if FState <> csDone then
  begin
    FState := csDone;
    FBufferIndex := 0;
    DoEncode(FFeedback, FBuffer, FBufferSize);
    Move(FVector^, FFeedback^, FBufferSize);
    if FUserSave <> nil then
      Move(FUserSave^, FUser^, FUserSize);
  end;
end;

procedure TDECCipher.Protect;
begin
  FState := csNew;
  ProtectBuffer(FData[0], FDataSize);
end;

procedure InvalidMessageLength(Cipher: TDECCipher);
begin
  with Cipher do
    raise EDECException.CreateFmt(sInvalidMessageLength,
      [IntToStr(Integer(FMode)), Context.BlockSize]);
end;

procedure TDECCipher.Encode(const Source; var Dest; DataSize: Integer);

  procedure EncodeECBx(S,D: PByteArray; Size: Integer);
  var
    I: Integer;
  begin
    if Context.BlockSize = 1 then
    begin
      DoEncode(S, D, Size);
      FState := csEncode;
    end else
    begin
      Dec(Size, FBufferSize);
      I := 0;
      while I <= Size do
      begin
        DoEncode(@S[I], @D[I], FBufferSize);
        Inc(I, FBufferSize);
      end;
      Dec(Size, I - FBufferSize);
      if Size > 0 then
        if Size mod Context.BlockSize = 0 then
        begin
          DoEncode(@S[I], @D[I], Size);
          FState := csEncode;
        end else
        begin
          FState := csPadded;
          InvalidMessageLength(Self);
        end;
    end;
  end;

  procedure EncodeCFB8(S,D: PByteArray; Size: Integer);
  // CFB-8
  var
    I: Integer;
  begin
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      Move(FFeedback[1], FFeedback[0], FBufferSize -1);
      D[I] := S[I] xor FBuffer[0];
      FFeedback[FBufferSize -1] := D[I];
      Inc(I);
    end;
    FState := csEncode;
  end;

  procedure EncodeOFB8(S,D: PByteArray; Size: Integer);
  var
    I: Integer;
  begin
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      Move(FFeedback[1], FFeedback[0], FBufferSize -1);
      FFeedback[FBufferSize -1] := FBuffer[0];
      D[I] := S[I] xor FBuffer[0];
      Inc(I);
    end;
    FState := csEncode;
  end;

  procedure EncodeCFS8(S,D: PByteArray; Size: Integer);
  // CFS-8, CTS as CFB
  var
    I: Integer;
  begin
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      D[I] := S[I] xor FBuffer[0];
      Move(FFeedback[1], FFeedback[0], FBufferSize -1);
      FFeedback[FBufferSize -1] := FFeedback[FBufferSize -1] xor D[I];
      Inc(I);
    end;
    FState := csEncode;
  end;

  procedure EncodeCFBx(S,D: PByteArray; Size: Integer);
  // CFB-BlockSize
  var
    I: Integer;
    F: PByteArray;
  begin
    FState := csEncode;
    if FBufferIndex > 0 then
    begin
      I := FBufferSize - FBufferIndex;
      if I > Size then I := Size;
      XORBuffers(S[0], FBuffer[FBufferIndex], I, D[0]);
      Move(D[0], FFeedback[FBufferIndex], I);
      Inc(FBufferIndex, I);
      if FBufferIndex < FBufferSize then Exit;
      Dec(Size, I);
      S := @S[I];
      D := @D[I];
      FBufferIndex := 0
    end;
    Dec(Size, FBufferSize);
    F := FFeedback;
    I := 0;
    while I < Size do
    begin
      DoEncode(F, FBuffer, FBufferSize);
      XORBuffers(S[I], FBuffer[0], FBufferSize, D[I]);
      F := @D[I];
      Inc(I, FBufferSize);
    end;
    if F <> FFeedback then
      Move(F^, FFeedback^, FBufferSize);
    Dec(Size, I - FBufferSize);
    if Size > 0 then
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      XORBuffers(S[I], FBuffer[0], Size, D[I]);
      Move(D[I], FFeedback[0], Size);
      FBufferIndex := Size;
    end;
  end;

  procedure EncodeOFBx(S,D: PByteArray; Size: Integer);
  // OFB-BlockSize
  var
    I: Integer;
  begin
    FState := csEncode;
    if FBufferIndex > 0 then
    begin
      I := FBufferSize - FBufferIndex;
      if I > Size then I := Size;
      XORBuffers(S[0], FFeedback[FBufferIndex], I, D[0]);
      Inc(FBufferIndex, I);
      if FBufferIndex < FBufferSize then Exit;
      Dec(Size, I);
      S := @S[I];
      D := @D[I];
      FBufferIndex := 0
    end;
    Dec(Size, FBufferSize);
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FFeedback, FBufferSize);
      XORBuffers(S[I], FFeedback[0], FBufferSize, D[I]);
      Inc(I, FBufferSize);
    end;
    Dec(Size, I - FBufferSize);
    if Size > 0 then
    begin
      DoEncode(FFeedback, FFeedback, FBufferSize);
      XORBuffers(S[I], FFeedback[0], Size, D[I]);
      FBufferIndex := Size;
    end;
  end;

  procedure EncodeCFSx(S,D: PByteArray; Size: Integer);
  // CFS-BlockSize
  var
    I: Integer;
  begin
    FState := csEncode;
    if FBufferIndex > 0 then
    begin
      I := FBufferSize - FBufferIndex;
      if I > Size then I := Size;
      XORBuffers(S[0], FBuffer[FBufferIndex], I, D[0]);
      XORBuffers(D[0], FFeedback[FBufferIndex], I, FFeedback[FBufferIndex]);
      Inc(FBufferIndex, I);
      if FBufferIndex < FBufferSize then Exit;
      Dec(Size, I);
      S := @S[I];
      D := @D[I];
      FBufferIndex := 0
    end;
    Dec(Size, FBufferSize);
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      XORBuffers(S[I], FBuffer[0], FBufferSize, D[I]);
      XORBuffers(D[I], FFeedback[0], FBufferSize, FFeedback[0]);
      Inc(I, FBufferSize);
    end;
    Dec(Size, I - FBufferSize);
    if Size > 0 then
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      XORBuffers(S[I], FBuffer[0], Size, D[I]);
      XORBuffers(D[I], FFeedback[0], Size, FFeedback[0]);
      FBufferIndex := Size;
    end;
  end;

  procedure EncodeCBCx(S,D: PByteArray; Size: Integer);
  var
    F: PByteArray;
    I: Integer;
  begin
    Dec(Size, FBufferSize);
    F := FFeedback;
    I := 0;
    while I <= Size do
    begin
      XORBuffers(S[I], F[0], FBufferSize, D[I]);
      F := @D[I];
      DoEncode(F, F, FBufferSize);
      Inc(I, FBufferSize);
    end;
    if F <> FFeedback then
      Move(F[0], FFeedback[0], FBufferSize);
    Dec(Size, I - FBufferSize);
    if Size > 0 then
    begin  // padding
      EncodeCFB8(@S[I], @D[I], Size);
      FState := csPadded;
    end else FState := csEncode;
  end;

  procedure EncodeCTSx(S,D: PByteArray; Size: Integer);
  var
    I: Integer;
  begin
    Dec(Size, FBufferSize);
    I := 0;
    while I <= Size do
    begin
      XORBuffers(S[I], FFeedback[0], FBufferSize, D[I]);
      DoEncode(@D[I], @D[I], FBufferSize);
      XORBuffers(D[I], FFeedback[0], FBufferSize, FFeedback[0]);
      Inc(I, FBufferSize);
     end;
     Dec(Size, I - FBufferSize);
     if Size > 0 then
     begin // padding
       EncodeCFS8(@S[I], @D[I], Size);
       FState := csPadded;
     end else FState := csEncode;
  end;

begin
  CheckState([csInitialized, csEncode, csDone]);
  case FMode of
    cmECBx: EncodeECBx(@Source, @Dest, DataSize);
    cmCBCx: EncodeCBCx(@Source, @Dest, DataSize);
    cmCTSx: EncodeCTSx(@Source, @Dest, DataSize);
    cmCFB8: EncodeCFB8(@Source, @Dest, DataSize);
    cmCFBx: EncodeCFBx(@Source, @Dest, DataSize);
    cmOFB8: EncodeOFB8(@Source, @Dest, DataSize);
    cmOFBx: EncodeOFBx(@Source, @Dest, DataSize);
    cmCFS8: EncodeCFS8(@Source, @Dest, DataSize);
    cmCFSx: EncodeCFSx(@Source, @Dest, DataSize);
  end;
end;

procedure TDECCipher.Decode(const Source; var Dest; DataSize: Integer);

  procedure DecodeECBx(S,D: PByteArray; Size: Integer);
  var
    I: Integer;
  begin
    if Context.BlockSize = 1 then
    begin
      DoDecode(S, D, Size);
      FState := csDecode;
    end else
    begin
      Dec(Size, FBufferSize);
      I := 0;
      while I <= Size do
      begin
        DoDecode(@S[I], @D[I], FBufferSize);
        Inc(I, FBufferSize);
      end;
      Dec(Size, I - FBufferSize);
      if Size > 0 then
        if Size mod Context.BlockSize = 0 then
        begin
          DoDecode(@S[I], @D[I], Size);
          FState := csDecode;
        end else
        begin
          FState := csPadded;
          InvalidMessageLength(Self);
        end;
    end;
  end;

  procedure DecodeCFB8(S,D: PByteArray; Size: Integer);
  // CFB-8
  var
    I: Integer;
  begin
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      Move(FFeedback[1], FFeedback[0], FBufferSize -1);
      FFeedback[FBufferSize -1] := S[I];
      D[I] := S[I] xor FBuffer[0];
      Inc(I);
    end;
    FState := csDecode;
  end;

  procedure DecodeOFB8(S,D: PByteArray; Size: Integer);
  // same as EncodeOFB
  var
    I: Integer;
  begin
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      Move(FFeedback[1], FFeedback[0], FBufferSize -1);
      FFeedback[FBufferSize -1] := FBuffer[0];
      D[I] := S[I] xor FBuffer[0];
      Inc(I);
    end;
    FState := csDecode;
  end;

  procedure DecodeCFS8(S,D: PByteArray; Size: Integer);
  var
    I: Integer;
  begin
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      Move(FFeedback[1], FFeedback[0], FBufferSize -1);
      FFeedback[FBufferSize -1] := FFeedback[FBufferSize -1] xor S[I];
      D[I] := S[I] xor FBuffer[0];
      Inc(I);
    end;
    FState := csDecode;
  end;

  procedure DecodeCFBx(S,D: PByteArray; Size: Integer);
  // CFB-BlockSize
  var
    I: Integer;
    F: PByteArray;
  begin
    FState := csDecode;
    if FBufferIndex > 0 then
    begin // remain bytes of last decode
      I := FBufferSize - FBufferIndex;
      if I > Size then I := Size;
      Move(S[0], FFeedback[FBufferIndex], I);
      XORBuffers(S[0], FBuffer[FBufferIndex], I, D[0]);
      Inc(FBufferIndex, I);
      if FBufferIndex < FBufferSize then Exit;
      Dec(Size, I);
      S := @S[I];
      D := @D[I];
      FBufferIndex := 0
    end;
  // process chunks of FBufferSize bytes
    Dec(Size, FBufferSize);
    I := 0;
    if S <> D then
    begin
      F := FFeedback;
      while I < Size do
      begin
        DoEncode(F, FBuffer, FBufferSize);
        XORBuffers(S[I], FBuffer[0], FBufferSize, D[I]);
        F := @S[I];
        Inc(I, FBufferSize);
      end;
      if F <> FFeedback then
        Move(F^, FFeedback^, FBufferSize);
    end else
      while I < Size do
      begin
        DoEncode(FFeedback, FBuffer, FBufferSize);
        Move(S[I], FFeedback[0], FBufferSize);
        XORBuffers(S[I], FBuffer[0], FBufferSize, D[I]);
        Inc(I, FBufferSize);
      end;
    Dec(Size, I - FBufferSize);
    if Size > 0 then
    begin // remain bytes
      DoEncode(FFeedback, FBuffer, FBufferSize);
      Move(S[I], FFeedback[0], Size);
      XORBuffers(S[I], FBuffer[0], Size, D[I]);
      FBufferIndex := Size;
    end;
  end;

  procedure DecodeOFBx(S,D: PByteArray; Size: Integer);
  // OFB-BlockSize, same as EncodeOFBx
  var
    I: Integer;
  begin
    FState := csDecode;
    if FBufferIndex > 0 then
    begin
      I := FBufferSize - FBufferIndex;
      if I > Size then I := Size;
      XORBuffers(S[0], FFeedback[FBufferIndex], I, D[0]);
      Inc(FBufferIndex, I);
      if FBufferIndex < FBufferSize then Exit;
      Dec(Size, I);
      S := @S[I];
      D := @D[I];
      FBufferIndex := 0
    end;
    Dec(Size, FBufferSize);
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FFeedback, FBufferSize);
      XORBuffers(S[I], FFeedback[0], FBufferSize, D[I]);
      Inc(I, FBufferSize);
    end;
    Dec(Size, I - FBufferSize);
    if Size > 0 then
    begin
      DoEncode(FFeedback, FFeedback, FBufferSize);
      XORBuffers(S[I], FFeedback[0], Size, D[I]);
      FBufferIndex := Size;
    end;
  end;

  procedure DecodeCFSx(S,D: PByteArray; Size: Integer);
  // CFS-BlockSize
  var
    I: Integer;
  begin
    FState := csDecode;
    if FBufferIndex > 0 then
    begin // remain bytes of last decode
      I := FBufferSize - FBufferIndex;
      if I > Size then I := Size;
      XORBuffers(S[0], FFeedback[FBufferIndex], I, FFeedback[FBufferIndex]);
      XORBuffers(S[0], FBuffer[FBufferIndex], I, D[0]);
      Inc(FBufferIndex, I);
      if FBufferIndex < FBufferSize then Exit;
      Dec(Size, I);
      S := @S[I];
      D := @D[I];
      FBufferIndex := 0
    end;
  // process chunks of FBufferSize bytes
    Dec(Size, FBufferSize);
    I := 0;
    while I < Size do
    begin
      DoEncode(FFeedback, FBuffer, FBufferSize);
      XORBuffers(S[I], FFeedback[0], FBufferSize, FFeedback[0]);
      XORBuffers(S[I], FBuffer[0], FBufferSize, D[I]);
      Inc(I, FBufferSize);
    end;
    Dec(Size, I - FBufferSize);
    if Size > 0 then
    begin // remain bytes
      DoEncode(FFeedback, FBuffer, FBufferSize);
      XORBuffers(S[I], FFeedback[0], Size, FFeedback[0]);
      XORBuffers(S[I], FBuffer[0], Size, D[I]);
      FBufferIndex := Size;
    end;
  end;

  procedure DecodeCBCx(S,D: PByteArray; Size: Integer);
  var
    I: Integer;
    F,B,T: PByteArray;
  begin
    Dec(Size, FBufferSize);
    F := FFeedback;
    I := 0;
    if S = D then
    begin
      B := FBuffer;
      while I <= Size do
      begin
        Move(S[I], B[0], FBufferSize);
        DoDecode(@S[I], @S[I], FBufferSize);
        XORBuffers(S[I], F[0], FBufferSize, S[I]);
        T := F;
        F := B;
        B := T;
        Inc(I, FBufferSize);
      end;
    end else
      while I <= Size do
      begin
        DoDecode(@S[I], @D[I], FBufferSize);
        XORBuffers(F[0], D[I], FBufferSize, D[I]);
        F := @S[I];
        Inc(I, FBufferSize);
      end;
    if F <> FFeedback then
      Move(F[0], FFeedback[0], FBufferSize);
    Dec(Size, I - FBufferSize);
    if Size > 0 then
    begin
      DecodeCFB8(@S[I], @D[I], Size);
      FState := csPadded;
    end else FState := csDecode;
  end;

  procedure DecodeCTSx(S,D: PByteArray; Size: Integer);
  var
    I: Integer;
    F,B,T: PByteArray;
  begin
    Dec(Size, FBufferSize);
    F := FFeedback;
    B := FBuffer;
    I := 0;
    while I <= Size do
    begin
      XORBuffers(S[I], F[0], FBufferSize, B[0]);
      DoDecode(@S[I], @D[I], FBufferSize);
      XORBuffers(D[I], F[0], FBufferSize, D[I]);
      T := B;
      B := F;
      F := T;
      Inc(I, FBufferSize);
    end;
    if F <> FFeedback then
      Move(F[0], FFeedback[0], FBufferSize);
    Dec(Size, I - FBufferSize);
    if Size > 0 then
    begin
      DecodeCFS8(@S[I], @D[I], Size);
      FState := csPadded;
    end else FState := csDecode;
  end;

begin
  CheckState([csInitialized, csDecode, csDone]);
  case FMode of
    cmECBx: DecodeECBx(@Source, @Dest, DataSize);
    cmCBCx: DecodeCBCx(@Source, @Dest, DataSize);
    cmCTSx: DecodeCTSx(@Source, @Dest, DataSize);
    cmCFB8: DecodeCFB8(@Source, @Dest, DataSize);
    cmCFBx: DecodeCFBx(@Source, @Dest, DataSize);
    cmOFB8: DecodeOFB8(@Source, @Dest, DataSize);
    cmOFBx: DecodeOFBx(@Source, @Dest, DataSize);
    cmCFS8: DecodeCFS8(@Source, @Dest, DataSize);
    cmCFSx: DecodeCFSx(@Source, @Dest, DataSize);
  end;
end;

function TDECCipher.EncodeBinary(const Source: Binary; Format: TDECFormatClass): Binary;
begin
  SetLength(Result, Length(Source));
  Encode(Source[1], Result[1], Length(Source));
  Result := ValidFormat(Format).Encode(Result);
end;

function TDECCipher.DecodeBinary(const Source: Binary; Format: TDECFormatClass): Binary;
begin
  Result := ValidFormat(Format).Decode(Source);
  Decode(Result[1], Result[1], Length(Result));
end;

procedure DoCodeStream(Source,Dest: TStream; Size: Int64; BlockSize: Integer; const Proc: TDECCipherCodeEvent; const Progress: IDECProgress);
var
  Buffer: Binary;
  BufferSize,Bytes: Integer;
  Min,Max,Pos: Int64;
begin
  Pos := Source.Position;
  if Size < 0 then Size := Source.Size - Pos;
  Min := Pos;
  Max := Pos + Size;
  if Size > 0 then
  try
    if StreamBufferSize <= 0 then StreamBufferSize := 8192;
    BufferSize := StreamBufferSize mod BlockSize;
    if BufferSize = 0 then BufferSize := StreamBufferSize
      else BufferSize := StreamBufferSize + BlockSize - BufferSize;
    if Size > BufferSize then SetLength(Buffer, BufferSize)
      else SetLength(Buffer, Size);
    while Size > 0 do
    begin
      if Assigned(Progress) then Progress.Process(Min, Max, Pos);
      Bytes := BufferSize;
      if Bytes > Size then Bytes := Size;
      Source.ReadBuffer(Buffer[1], Bytes);
      Proc(Buffer[1], Buffer[1], Bytes);
      Dest.WriteBuffer(Buffer[1], Bytes);
      Dec(Size, Bytes);
      Inc(Pos, Bytes);
    end;
  finally
    ProtectBinary(Buffer);
    if Assigned(Progress) then Progress.Process(Min, Max, Max);
  end;
end;

procedure DoCodeFile(const Source,Dest: String; BlockSize: Integer; const Proc: TDECCipherCodeEvent; const Progress: IDECProgress);
var
  S,D: TStream;
begin
  S := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
  try
    D := TFileStream.Create(Dest, fmCreate);
    try
      DoCodeStream(S, D, S.Size, BlockSize, Proc, Progress);
    finally
      D.Free;
    end;
  finally
    S.Free;
  end;
end;

procedure TDECCipher.EncodeFile(const Source, Dest: String; const Progress: IDECProgress);
begin
  DoCodeFile(Source, Dest, Context.BlockSize, Encode, Progress);
end;

procedure TDECCipher.DecodeFile(const Source, Dest: String; const Progress: IDECProgress);
begin
  DoCodeFile(Source, Dest, Context.BlockSize, Decode, Progress);
end;

procedure TDECCipher.EncodeStream(const Source, Dest: TStream; const DataSize: Int64; const Progress: IDECProgress);
begin
  DoCodeStream(Source, Dest, DataSize, Context.BlockSize, Encode, Progress);
end;

procedure TDECCipher.DecodeStream(const Source, Dest: TStream; const DataSize: Int64; const Progress: IDECProgress);
begin
  DoCodeStream(Source, Dest, DataSize, Context.BlockSize, Decode, Progress);
end;

function TDECCipher.CalcMAC(Format: TDECFormatClass): Binary;
begin
  Done;
  if FMode in [cmECBx] then raise EDECException.Create(sInvalidMACMode)
    else Result := ValidFormat(Format).Encode(FBuffer^, FBufferSize);
end;

// .TCipher_Null
class function TCipher_Null.Context: TCipherContext;
begin
  Result.KeySize := 0;
  Result.BlockSize := 1;
  Result.BufferSize := 32;
  Result.UserSize := 0;
  Result.UserSave := False;
end;

procedure TCipher_Null.DoInit(const Key; Size: Integer);
begin
end;

procedure TCipher_Null.DoEncode(Source, Dest: Pointer; Size: Integer);
begin
  if Source <> Dest then Move(Source^, Dest^, Size);
end;

procedure TCipher_Null.DoDecode(Source, Dest: Pointer; Size: Integer);
begin
  if Source <> Dest then Move(Source^, Dest^, Size);
end;

// .TCipher_Blowfish

{$IFDEF UseASM}
  {$IFDEF 486GE}
    {$DEFINE Blowfish_asm}
  {$ENDIF}
{$ENDIF}

type
  PBlowfish = ^TBlowfish;
  TBlowfish = array[0..3, 0..255] of Cardinal;

class function TCipher_Blowfish.Context: TCipherContext;
begin
  Result.KeySize := 56;
  Result.BufferSize := 8;
  Result.BlockSize := 8;
  Result.UserSize := SizeOf(Blowfish_Data) + SizeOf(Blowfish_Key);
  Result.UserSave := False;
end;

procedure TCipher_Blowfish.DoInit(const Key; Size: Integer);
var
  I,J: Integer;
  B: array[0..1] of Cardinal;
  K: PByteArray;
  P: PLongArray;
  S: PBlowfish;
begin
  K := @Key;
  S := FUser;
  P := Pointer(PAnsiChar(FUser) + SizeOf(Blowfish_Data));
  Move(Blowfish_Data, S^, SizeOf(Blowfish_Data));
  Move(Blowfish_Key, P^, Sizeof(Blowfish_Key));
  J := 0;
  if Size > 0 then
    for I := 0 to 17 do
    begin
      P[I] := P[I] xor (K[(J + 0) mod Size] shl 24 +
                        K[(J + 1) mod Size] shl 16 +
                        K[(J + 2) mod Size] shl  8 +
                        K[(J + 3) mod Size] shl  0);
      J := (J + 4) mod Size;
    end;
  FillChar(B, SizeOf(B), 0);
  for I := 0 to 8 do
  begin
    DoEncode(@B, @B, SizeOf(B));
    P[I * 2 + 0] := SwapLong(B[0]);
    P[I * 2 + 1] := SwapLong(B[1]);
  end;
  for I := 0 to 3 do
    for J := 0 to 127 do
    begin
      DoEncode(@B, @B, SizeOf(B));
      S[I, J * 2 + 0] := SwapLong(B[0]);
      S[I, J * 2 + 1] := SwapLong(B[1]);
    end;
  FillChar(B, SizeOf(B), 0);
end;

/// Save & set compiler options
{$IFOPT R+} {$DEFINE DoRangeChecks}    {$ENDIF} {$RANGECHECKS OFF}
{$IFOPT Q+} {$DEFINE DoOverflowChecks} {$ENDIF} {$OVERFLOWCHECKS OFF}

{$OVERFLOWCHECKS OFF} {$RANGECHECKS OFF}
procedure TCipher_Blowfish.DoEncode(Source, Dest: Pointer; Size: Integer);
{$IFDEF Blowfish_asm}  // specialy for CPU >= 486
// Source = EDX, Dest=ECX, Size on Stack
asm
        PUSH   EDI
        PUSH   ESI
        PUSH   EBX
        PUSH   EBP
        PUSH   ECX
        MOV    ESI,[EAX].TCipher_Blowfish.FUser
        MOV    EBX,[EDX + 0]     // A
        MOV    EBP,[EDX + 4]     // B
        BSWAP  EBX               // CPU >= 486
        BSWAP  EBP
        XOR    EBX,[ESI + 4 * 256 * 4]
        XOR    EDI,EDI
@@1:    MOV    EAX,EBX
        SHR    EBX,16
        MOVZX  ECX,BH
        AND    EBX,0FFh
        MOV    ECX,[ESI + ECX * 4 + 1024 * 0]
        MOV    EBX,[ESI + EBX * 4 + 1024 * 1]
        MOVZX  EDX,AH
        ADD    EBX,ECX
        MOVZX  ECX,AL
        MOV    EDX,[ESI + EDX * 4 + 1024 * 2]
        MOV    ECX,[ESI + ECX * 4 + 1024 * 3]
        XOR    EBX,EDX
        XOR    EBP,[ESI + 4 * 256 * 4 + 4 + EDI * 4]
        ADD    EBX,ECX
        INC    EDI
        XOR    EBX,EBP
        TEST   EDI,010h
        MOV    EBP,EAX
        JZ     @@1
        POP    EAX
        XOR    EBP,[ESI + 4 * 256 * 4 + 17 * 4]
        BSWAP  EBX
        BSWAP  EBP
        MOV    [EAX + 4],EBX
        MOV    [EAX + 0],EBP
        POP    EBP
        POP    EBX
        POP    ESI
        POP    EDI
end;
{$ELSE}
var
  I,A,B: Cardinal;
  P: PLongArray;
  D: PBlowfish;
begin
  Assert(Size = Context.BlockSize);

  D := FUser;
  P := Pointer(PAnsiChar(FUser) + SizeOf(Blowfish_Data));
  A := SwapLong(PLongArray(Source)[0]) xor P[0]; P := @P[1];
  B := SwapLong(PLongArray(Source)[1]);
  for I := 0 to 7 do
  begin
    B := B xor P[0] xor Cardinal(D[0, A shr 24        ] +
                         D[1, A shr 16 and $FF] xor
                         D[2, A shr  8 and $FF] +
                         D[3, A        and $FF]);

    A := A xor P[1] xor Cardinal(D[0, B shr 24        ] +
                         D[1, B shr 16 and $FF] xor
                         D[2, B shr  8 and $FF] +
                         D[3, B        and $FF]);
    P := @P[2];
  end;
  PLongArray(Dest)[0] := SwapLong(B xor P[0]);
  PLongArray(Dest)[1] := SwapLong(A);
end;
{$ENDIF}

procedure TCipher_Blowfish.DoDecode(Source, Dest: Pointer; Size: Integer);
{$IFDEF Blowfish_asm}
asm
        PUSH   EDI
        PUSH   ESI
        PUSH   EBX
        PUSH   EBP
        PUSH   ECX
        MOV    ESI,[EAX].TCipher_Blowfish.FUser
        MOV    EBX,[EDX + 0]     // A
        MOV    EBP,[EDX + 4]     // B
        BSWAP  EBX
        BSWAP  EBP
        XOR    EBX,[ESI + 4 * 256 * 4 + 17 * 4]
        MOV    EDI,16
@@1:    MOV    EAX,EBX
        SHR    EBX,16
        MOVZX  ECX,BH
        MOVZX  EDX,BL
        MOV    EBX,[ESI + ECX * 4 + 1024 * 0]
        MOV    EDX,[ESI + EDX * 4 + 1024 * 1]
        MOVZX  ECX,AH
        LEA    EBX,[EBX + EDX]
        MOVZX  EDX,AL
        MOV    ECX,[ESI + ECX * 4 + 1024 * 2]
        MOV    EDX,[ESI + EDX * 4 + 1024 * 3]
        XOR    EBX,ECX
        XOR    EBP,[ESI + 4 * 256 * 4 + EDI * 4]
        LEA    EBX,[EBX + EDX]
        XOR    EBX,EBP
        DEC    EDI
        MOV    EBP,EAX
        JNZ    @@1
        POP    EAX
        XOR    EBP,[ESI + 4 * 256 * 4]
        BSWAP  EBX
        BSWAP  EBP
        MOV    [EAX + 0],EBP
        MOV    [EAX + 4],EBX
        POP    EBP
        POP    EBX
        POP    ESI
        POP    EDI
end;
{$ELSE}
var
  I,A,B: Cardinal;
  P: PLongArray;
  D: PBlowfish;
begin
  Assert(Size = Context.BlockSize);

  D := FUser;
  P := Pointer(PAnsiChar(FUser) + SizeOf(Blowfish_Data) + SizeOf(Blowfish_Key) - SizeOf(Integer));
  A := SwapLong(PLongArray(Source)[0]) xor P[0];
  B := SwapLong(PLongArray(Source)[1]);
  for I := 0 to 7 do
  begin
    Dec(PCardinal(P), 2);
    B := B xor P[1] xor (D[0, A shr 24        ] +
                         D[1, A shr 16 and $FF] xor
                         D[2, A shr  8 and $FF] +
                         D[3, A        and $FF]);
    A := A xor P[0] xor (D[0, B shr 24        ] +
                         D[1, B shr 16 and $FF] xor
                         D[2, B shr  8 and $FF] +
                         D[3, B        and $FF]);
  end;
  Dec(PCardinal(P));
  PLongArray(Dest)[0] := SwapLong(B xor P[0]);
  PLongArray(Dest)[1] := SwapLong(A);
end;
{$ENDIF}


  /// Restore compiler options
  {$IFDEF DoRangeChecks}    {$RANGECHECKS ON}    {$UNDEF DoRangeChecks}    {$ENDIF}
  {$IFDEF DoOverflowChecks} {$OVERFLOWCHECKS ON} {$UNDEF DoOverflowChecks} {$ENDIF}

  /// Save & set compiler options
  {$IFOPT R+} {$DEFINE DoRangeChecks}    {$ENDIF} {$RANGECHECKS OFF}
  {$IFOPT Q+} {$DEFINE DoOverflowChecks} {$ENDIF} {$OVERFLOWCHECKS OFF}

  {$OVERFLOWCHECKS OFF} {$RANGECHECKS OFF}
// .TCipher_Twofish
type
  PTwofishBox = ^TTwofishBox;
  TTwofishBox = array[0..3, 0..255] of Cardinal;

  TLongRec = record
               case Integer of
                 0: (L: Cardinal);
                 1: (A,B,C,D: Byte);
             end;

class function TCipher_Twofish.Context: TCipherContext;
begin
  Result.KeySize := 32;
  Result.BufferSize := 16;
  Result.BlockSize := 16;
  Result.UserSize := 4256;
  Result.UserSave := False;
end;

procedure TCipher_Twofish.DoInit(const Key; Size: Integer);
var
  BoxKey: array[0..3] of TLongRec;
  SubKey: PLongArray;
  Box: PTwofishBox;

  procedure SetupKey;

    function Encode(K0, K1: Integer): Integer;
    var
      R, I, J, G2, G3: Integer;
      B: byte;
    begin
      R := 0;
      for I := 0 to 1 do
      begin
        if I <> 0 then R := R xor K0 else R := R xor K1;
        for J := 0 to 3 do
        begin
          B := R shr 24;
          if B and $80 <> 0 then G2 := (B shl 1 xor $014D) and $FF
            else G2 := B shl 1 and $FF;
          if B and 1 <> 0 then G3 := (B shr 1 and $7F) xor $014D shr 1 xor G2
            else G3 := (B shr 1 and $7F) xor G2;
          R := R shl 8 xor G3 shl 24 xor G2 shl 16 xor G3 shl 8 xor B;
        end;
      end;
      Result := R;
    end;

    function F32(X: Integer; K: array of Integer): Integer;
    var
      A, B, C, D: Cardinal;
    begin
      A := X        and $FF;
      B := X shr  8 and $FF;
      C := X shr 16 and $FF;
      D := X shr 24;
      if Size = 32 then
      begin
        A := Twofish_8x8[1, A] xor K[3]        and $FF;
        B := Twofish_8x8[0, B] xor K[3] shr  8 and $FF;
        C := Twofish_8x8[0, C] xor K[3] shr 16 and $FF;
        D := Twofish_8x8[1, D] xor K[3] shr 24;
      end;
      if Size >= 24 then
      begin
        A := Twofish_8x8[1, A] xor K[2]        and $FF;
        B := Twofish_8x8[1, B] xor K[2] shr  8 and $FF;
        C := Twofish_8x8[0, C] xor K[2] shr 16 and $FF;
        D := Twofish_8x8[0, D] xor K[2] shr 24;
      end;
      A := Twofish_8x8[0, A] xor K[1]        and $FF;
      B := Twofish_8x8[1, B] xor K[1] shr  8 and $FF;
      C := Twofish_8x8[0, C] xor K[1] shr 16 and $FF;
      D := Twofish_8x8[1, D] xor K[1] shr 24;

      A := Twofish_8x8[0, A] xor K[0]        and $FF;
      B := Twofish_8x8[0, B] xor K[0] shr  8 and $FF;
      C := Twofish_8x8[1, C] xor K[0] shr 16 and $FF;
      D := Twofish_8x8[1, D] xor K[0] shr 24;

      Result := Twofish_Data[0, A] xor Twofish_Data[1, B] xor
                Twofish_Data[2, C] xor Twofish_Data[3, D];
    end;

  var
    I,J,A,B: Integer;
    E,O: array[0..3] of Integer;
    K: array[0..7] of Integer;
  begin
    FillChar(K, SizeOf(K), 0);
    Move(Key, K, Size);
    if Size <= 16 then Size := 16 else
      if Size <= 24 then Size := 24
        else Size := 32;
    J := Size shr 3 - 1;
    for I := 0 to J do
    begin
      E[I] := K[I shl 1];
      O[I] := K[I shl 1 + 1];
      BoxKey[J].L := Encode(E[I], O[I]);
      Dec(J);
    end;
    J := 0;
    for I := 0 to 19 do
    begin
      A := F32(J, E);
      B := F32(J + $01010101, O);
      B := B shl 8 or B shr 24;
      SubKey[I shl 1] := A + B;
      B := A + B shl 1;     // here buggy instead shr 1 it's correct shl 1
      SubKey[I shl 1 + 1] := B shl 9 or B shr 23;
      Inc(J, $02020202);
    end;
  end;

  procedure DoXOR(D, S: PLongArray; Value: Cardinal);
  var
    I: Cardinal;
  begin
    Value := (Value and $FF) * $01010101;
    for I := 0 to 63 do D[I] := S[I] xor Value;
  end;

  procedure SetupBox128;
  var
    L: array[0..255] of Byte;
    A,I: Integer;
  begin
    DoXOR(@L, @Twofish_8x8[0], BoxKey[1].L);
    A := BoxKey[0].A;
    for I := 0 to 255 do
      Box[0, I] := Twofish_Data[0, Twofish_8x8[0, L[I]] xor A];
    DoXOR(@L, @Twofish_8x8[1], BoxKey[1].L shr 8);
    A := BoxKey[0].B;
    for I := 0 to 255 do
      Box[1, I] := Twofish_Data[1, Twofish_8x8[0, L[I]] xor A];
    DoXOR(@L, @Twofish_8x8[0], BoxKey[1].L shr 16);
    A := BoxKey[0].C;
    for I := 0 to 255 do
      Box[2, I] := Twofish_Data[2, Twofish_8x8[1, L[I]] xor A];
    DoXOR(@L, @Twofish_8x8[1], BoxKey[1].L shr 24);
    A := BoxKey[0].D;
    for I := 0 to 255 do
      Box[3, I] := Twofish_Data[3, Twofish_8x8[1, L[I]] xor A];
  end;

  procedure SetupBox192;
  var
    L: array[0..255] of Byte;
    A,B,I: Integer;
  begin
    DoXOR(@L, @Twofish_8x8[1], BoxKey[2].L);
    A := BoxKey[0].A;
    B := BoxKey[1].A;
    for I := 0 to 255 do
      Box[0, I] := Twofish_Data[0, Twofish_8x8[0, Twofish_8x8[0, L[I]] xor B] xor A];
    DoXOR(@L, @Twofish_8x8[1], BoxKey[2].L shr 8);
    A := BoxKey[0].B;
    B := BoxKey[1].B;
    for I := 0 to 255 do
      Box[1, I] := Twofish_Data[1, Twofish_8x8[0, Twofish_8x8[1, L[I]] xor B] xor A];
    DoXOR(@L, @Twofish_8x8[0], BoxKey[2].L shr 16);
    A := BoxKey[0].C;
    B := BoxKey[1].C;
    for I := 0 to 255 do
      Box[2, I] := Twofish_Data[2, Twofish_8x8[1, Twofish_8x8[0, L[I]] xor B] xor A];
    DoXOR(@L ,@Twofish_8x8[0], BoxKey[2].L shr 24);
    A := BoxKey[0].D;
    B := BoxKey[1].D;
    for I := 0 to 255 do
      Box[3, I] := Twofish_Data[3, Twofish_8x8[1, Twofish_8x8[1, L[I]] xor B] xor A];
  end;

  procedure SetupBox256;
  var
    L: array[0..255] of Byte;
    K: array[0..255] of Byte;
    A,B,I: Integer;
  begin
    DoXOR(@K, @Twofish_8x8[1], BoxKey[3].L);
    for I := 0 to 255 do L[I] := Twofish_8x8[1, K[I]];
    DoXOR(@L, @L, BoxKey[2].L);
    A := BoxKey[0].A;
    B := BoxKey[1].A;
    for I := 0 to 255 do
      Box[0, I] := Twofish_Data[0, Twofish_8x8[0, Twofish_8x8[0, L[I]] xor B] xor A];
    DoXOR(@K, @Twofish_8x8[0], BoxKey[3].L shr 8);
    for I := 0 to 255 do L[I] := Twofish_8x8[1, K[I]];
    DoXOR(@L, @L, BoxKey[2].L shr 8);
    A := BoxKey[0].B;
    B := BoxKey[1].B;
    for I := 0 to 255 do
      Box[1, I] := Twofish_Data[1, Twofish_8x8[0, Twofish_8x8[1, L[I]] xor B] xor A];
    DoXOR(@K, @Twofish_8x8[0],BoxKey[3].L shr 16);
    for I := 0 to 255 do L[I] := Twofish_8x8[0, K[I]];
    DoXOR(@L, @L, BoxKey[2].L shr 16);
    A := BoxKey[0].C;
    B := BoxKey[1].C;
    for I := 0 to 255 do
      Box[2, I] := Twofish_Data[2, Twofish_8x8[1, Twofish_8x8[0, L[I]] xor B] xor A];
    DoXOR(@K, @Twofish_8x8[1], BoxKey[3].L shr 24);
    for I := 0 to 255 do L[I] := Twofish_8x8[0, K[I]];
    DoXOR(@L, @L, BoxKey[2].L shr 24);
    A := BoxKey[0].D;
    B := BoxKey[1].D;
    for I := 0 to 255 do
      Box[3, I] := Twofish_Data[3, Twofish_8x8[1, Twofish_8x8[1, L[I]] xor B] xor A];
  end;

begin
  SubKey := FUser;
  Box    := @SubKey[40];
  SetupKey;
  if Size = 16 then SetupBox128 else
    if Size = 24 then SetupBox192
      else SetupBox256;
end;

procedure TCipher_Twofish.DoEncode(Source, Dest: Pointer; Size: Integer);
var
  S: PLongArray;
  Box: PTwofishBox;
  I,X,Y: Cardinal;
  A,B,C,D: TLongRec;
begin
  Assert(Size = Context.BlockSize);

  S   := FUser;
  A.L := PLongArray(Source)[0] xor S[0];
  B.L := PLongArray(Source)[1] xor S[1];
  C.L := PLongArray(Source)[2] xor S[2];
  D.L := PLongArray(Source)[3] xor S[3];

  Box := @S[40];
  S   := @S[8];
  for I := 0 to 7 do
  begin
    X := Box[0, A.A] xor Box[1, A.B] xor Box[2, A.C] xor Box[3, A.D];
    Y := Box[1, B.A] xor Box[2, B.B] xor Box[3, B.C] xor Box[0, B.D];
    D.L := D.L shl 1 or D.L shr 31;
    C.L := C.L xor (X + Y       + S[0]);
    D.L := D.L xor (X + Y shl 1 + S[1]);
    C.L := C.L shr 1 or C.L shl 31;

    X := Box[0, C.A] xor Box[1, C.B] xor Box[2, C.C] xor Box[3, C.D];
    Y := Box[1, D.A] xor Box[2, D.B] xor Box[3, D.C] xor Box[0, D.D];
    B.L := B.L shl 1 or B.L shr 31;
    A.L := A.L xor (X + Y       + S[2]);
    B.L := B.L xor (X + Y shl 1 + S[3]);
    A.L := A.L shr 1 or A.L shl 31;

    S := @S[4];
  end;
  S := FUser;
  PLongArray(Dest)[0] := C.L xor S[4];
  PLongArray(Dest)[1] := D.L xor S[5];
  PLongArray(Dest)[2] := A.L xor S[6];
  PLongArray(Dest)[3] := B.L xor S[7];
end;

procedure TCipher_Twofish.DoDecode(Source, Dest: Pointer; Size: Integer);
var
  S: PLongArray;
  Box: PTwofishBox;
  I,X,Y: Cardinal;
  A,B,C,D: TLongRec;
begin
  Assert(Size = Context.BlockSize);

  S := FUser;
  Box := @S[40];
  C.L := PLongArray(Source)[0] xor S[4];
  D.L := PLongArray(Source)[1] xor S[5];
  A.L := PLongArray(Source)[2] xor S[6];
  B.L := PLongArray(Source)[3] xor S[7];
  S := @S[36];
  for I := 0 to 7 do
  begin
    X := Box[0, C.A] xor Box[1, C.B] xor Box[2, C.C] xor Box[3, C.D];
    Y := Box[0, D.D] xor Box[1, D.A] xor Box[2, D.B] xor Box[3, D.C];
    A.L := A.L shl 1 or A.L shr 31;
    B.L := B.L xor (X + Y shl 1 + S[3]);
    A.L := A.L xor (X + Y       + S[2]);
    B.L := B.L shr 1 or B.L shl 31;

    X := Box[0, A.A] xor Box[1, A.B] xor Box[2, A.C] xor Box[3, A.D];
    Y := Box[0, B.D] xor Box[1, B.A] xor Box[2, B.B] xor Box[3, B.C];
    C.L := C.L shl 1 or C.L shr 31;
    D.L := D.L xor (X + Y shl 1 + S[1]);
    C.L := C.L xor (X + Y       + S[0]);
    D.L := D.L shr 1 or D.L shl 31;

    Dec(PCardinal(S), 4);
  end;
  S := FUser;
  PLongArray(Dest)[0] := A.L xor S[0];
  PLongArray(Dest)[1] := B.L xor S[1];
  PLongArray(Dest)[2] := C.L xor S[2];
  PLongArray(Dest)[3] := D.L xor S[3];
end;
  /// Restore compiler options
  {$IFDEF DoRangeChecks}    {$RANGECHECKS ON}    {$UNDEF DoRangeChecks}    {$ENDIF}
  {$IFDEF DoOverflowChecks} {$OVERFLOWCHECKS ON} {$UNDEF DoOverflowChecks} {$ENDIF}

// .TCipher_Rijndael
const
{don't change this}
  Rijndael_Blocks =  4;
  Rijndael_Rounds = 14;

class function TCipher_Rijndael.Context: TCipherContext;
begin
  Result.KeySize := 32;
  Result.BlockSize := Rijndael_Blocks * 4;
  Result.BufferSize := Rijndael_Blocks * 4;
  Result.UserSize := (Rijndael_Rounds + 1) * Rijndael_Blocks * SizeOf(Cardinal) * 2;
  Result.UserSave := False;
end;

procedure TCipher_Rijndael.DoInit(const Key; Size: Integer);
{  old Rijndael keyshedulling

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
      while (J < FRounds -6) and (R <= FRounds) do
      begin
        while (J < FRounds -6) and (T < Rijndael_Blocks) do
        begin
          PLongArray(FUser)[R * Rijndael_Blocks + T] := K[J];
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
    D: PCardinal;
  begin
    D := Pointer(PAnsiChar(FUser) + FUserSize shr 1);
    Move(FUser^, D^, FUserSize shr 1);
    Inc(D, 4);
    for I := 0 to FRounds * 4 - 5 do
    begin
      D^ :=  Rijndael_Key[D^ and $FF] xor
            (Rijndael_Key[D^ shr  8 and $FF] shl  8 or Rijndael_Key[D^ shr  8 and $FF] shr 24) xor
            (Rijndael_Key[D^ shr 16 and $FF] shl 16 or Rijndael_Key[D^ shr 16 and $FF] shr 16) xor
            (Rijndael_Key[D^ shr 24]         shl 24 or Rijndael_Key[D^ shr 24]          shr 8);
      Inc(D);
    end;
  end; }

// new AES conform Keyshedulling
  
  procedure BuildEncodeKey;
  const
    RCon: array[0..9] of Cardinal = ($01,$02,$04,$08,$10,$20,$40,$80,$1b,$36);
  var
    I: Integer;
    T: Cardinal;
    P: PLongArray;
  begin
    P := FUser;
    if Size <= 16 then
    begin
      for I := 0 to 9 do
      begin
        T := P[3];
        P[4] := Rijndael_S[0, T shr  8 and $FF]        xor
                Rijndael_S[0, T shr 16 and $FF] shl  8 xor
                Rijndael_S[0, T shr 24        ] shl 16 xor
                Rijndael_S[0, T        and $FF] shl 24 xor P[0] xor RCon[I];
        P[5] := P[1] xor P[4];
        P[6] := P[2] xor P[5];
        P[7] := P[3] xor P[6];
        P    := @P[4];
      end;
    end else
      if Size <= 24 then
      begin
        for I := 0 to 7 do
        begin
          T := P[5];
          P[6] := Rijndael_S[0, T shr  8 and $FF]        xor
                  Rijndael_S[0, T shr 16 and $FF] shl  8 xor
                  Rijndael_S[0, T shr 24        ] shl 16 xor
                  Rijndael_S[0, T        and $FF] shl 24 xor P[0] xor RCon[I];
          P[7] := P[1] xor P[6];
          P[8] := P[2] xor P[7];
          P[9] := P[3] xor P[8];
          if I = 7 then Break;
          P[10] := P[4] xor P[9];
          P[11] := P[5] xor P[10];
          P     := @P[6];
        end;
      end else
      begin
        for I :=0 to 6 do
        begin
          T := P[7];
          P[8] := Rijndael_S[0, T shr  8 and $FF]        xor
                  Rijndael_S[0, T shr 16 and $FF] shl  8 xor
                  Rijndael_S[0, T shr 24        ] shl 16 xor
                  Rijndael_S[0, T        and $FF] shl 24 xor P[0] xor RCon[I];
          P[9] := P[1] xor P[8];
          P[10] := P[2] xor P[9];
          P[11] := P[3] xor P[10];
          if I = 6 then Break;
          T := P[11];
          P[12] := Rijndael_S[0, T        and $FF]        xor
                   Rijndael_S[0, T shr  8 and $FF] shl  8 xor
                   Rijndael_S[0, T shr 16 and $FF] shl 16 xor
                   Rijndael_S[0, T shr 24        ] shl 24 xor P[4];
          P[13] := P[5] xor P[12];
          P[14] := P[6] xor P[13];
          P[15] := P[7] xor P[14];
          P     := @P[8];
        end;
      end;
  end;


  procedure BuildDecodeKey;
  var
    P: PCardinal;
    I: Integer;
  begin
    P := Pointer(PAnsiChar(FUser) + FUserSize shr 1);
    Move(FUser^, P^, FUserSize shr 1);
    Inc(P, 4);
    for I := 0 to FRounds * 4 -5 do
    begin
      P^ := Rijndael_T[4, Rijndael_S[0, P^        and $FF]] xor
            Rijndael_T[5, Rijndael_S[0, P^ shr  8 and $FF]] xor
            Rijndael_T[6, Rijndael_S[0, P^ shr 16 and $FF]] xor
            Rijndael_T[7, Rijndael_S[0, P^ shr 24        ]];
      Inc(P);
    end;
  end;


begin
  if Size <= 16 then FRounds := 10 else
    if Size <= 24 then FRounds := 12
      else FRounds := 14;
  FillChar(FUser^, 32, 0);       
  Move(Key, FUser^, Size);
  BuildEncodeKey;
  BuildDecodeKey;
end;

procedure TCipher_Rijndael.DoEncode(Source, Dest: Pointer; Size: Integer);
var
  P: PLongArray;
  I: Integer;
  A2,B2,C2,D2: Cardinal;
  A1,B1,C1,D1: Cardinal;
begin
  Assert(Size = Context.BlockSize);
  P  := FUser;
  A1 := PLongArray(Source)[0];
  B1 := PLongArray(Source)[1];
  C1 := PLongArray(Source)[2];
  D1 := PLongArray(Source)[3];
  for I := 2 to FRounds do
  begin
    A2 := A1 xor P[0];
    B2 := B1 xor P[1];
    C2 := C1 xor P[2];
    D2 := D1 xor P[3];

    A1 := Rijndael_T[0, A2        and $FF] xor
          Rijndael_T[1, B2 shr  8 and $FF] xor
          Rijndael_T[2, C2 shr 16 and $FF] xor
          Rijndael_T[3, D2 shr 24        ];
    B1 := Rijndael_T[0, B2        and $FF] xor
          Rijndael_T[1, C2 shr  8 and $FF] xor
          Rijndael_T[2, D2 shr 16 and $FF] xor
          Rijndael_T[3, A2 shr 24        ];
    C1 := Rijndael_T[0, C2        and $FF] xor
          Rijndael_T[1, D2 shr  8 and $FF] xor
          Rijndael_T[2, A2 shr 16 and $FF] xor
          Rijndael_T[3, B2 shr 24        ];
    D1 := Rijndael_T[0, D2        and $FF] xor
          Rijndael_T[1, A2 shr  8 and $FF] xor
          Rijndael_T[2, B2 shr 16 and $FF] xor
          Rijndael_T[3, C2 shr 24        ];

    P := @P[4];
  end;

  A2 := A1 xor P[0];
  B2 := B1 xor P[1];
  C2 := C1 xor P[2];
  D2 := D1 xor P[3];

  PLongArray(Dest)[0] := (Rijndael_S[0, A2        and $FF]        or
                          Rijndael_S[0, B2 shr  8 and $FF] shl  8 or
                          Rijndael_S[0, C2 shr 16 and $FF] shl 16 or
                          Rijndael_S[0, D2 shr 24        ] shl 24)     xor P[4];
  PLongArray(Dest)[1] := (Rijndael_S[0, B2        and $FF]        or
                          Rijndael_S[0, C2 shr  8 and $FF] shl  8 or
                          Rijndael_S[0, D2 shr 16 and $FF] shl 16 or
                          Rijndael_S[0, A2 shr 24        ] shl 24)     xor P[5];
  PLongArray(Dest)[2] := (Rijndael_S[0, C2        and $FF]        or
                          Rijndael_S[0, D2 shr  8 and $FF] shl  8 or
                          Rijndael_S[0, A2 shr 16 and $FF] shl 16 or
                          Rijndael_S[0, B2 shr 24        ] shl 24)     xor P[6];
  PLongArray(Dest)[3] := (Rijndael_S[0, D2        and $FF]        or
                          Rijndael_S[0, A2 shr  8 and $FF] shl  8 or
                          Rijndael_S[0, B2 shr 16 and $FF] shl 16 or
                          Rijndael_S[0, C2 shr 24        ] shl 24)     xor P[7];
end;

procedure TCipher_Rijndael.DoDecode(Source, Dest: Pointer; Size: Integer);
var
  P: PLongArray;
  I: Integer;
  A2,B2,C2,D2: Cardinal;
  A1,B1,C1,D1: Cardinal;
begin
  Assert(Size = Context.BlockSize);

  P  := Pointer(PAnsiChar(FUser) + FUserSize shr 1 + FRounds * 16);
  A1 := PLongArray(Source)[0];
  B1 := PLongArray(Source)[1];
  C1 := PLongArray(Source)[2];
  D1 := PLongArray(Source)[3];

  for I := 2 to FRounds do
  begin
    A2 := A1 xor P[0];
    B2 := B1 xor P[1];
    C2 := C1 xor P[2];
    D2 := D1 xor P[3];

    A1 := Rijndael_T[4, A2        and $FF] xor
          Rijndael_T[5, D2 shr  8 and $FF] xor
          Rijndael_T[6, C2 shr 16 and $FF] xor
          Rijndael_T[7, B2 shr 24        ];
    B1 := Rijndael_T[4, B2        and $FF] xor
          Rijndael_T[5, A2 shr  8 and $FF] xor
          Rijndael_T[6, D2 shr 16 and $FF] xor
          Rijndael_T[7, C2 shr 24        ];
    C1 := Rijndael_T[4, C2        and $FF] xor
          Rijndael_T[5, B2 shr  8 and $FF] xor
          Rijndael_T[6, A2 shr 16 and $FF] xor
          Rijndael_T[7, D2 shr 24        ];
    D1 := Rijndael_T[4, D2        and $FF] xor
          Rijndael_T[5, C2 shr  8 and $FF] xor
          Rijndael_T[6, B2 shr 16 and $FF] xor
          Rijndael_T[7, A2 shr 24        ];

    Dec(PCardinal(P), 4);
  end;

  A2 := A1 xor P[0];
  B2 := B1 xor P[1];
  C2 := C1 xor P[2];
  D2 := D1 xor P[3];

  Dec(PCardinal(P), 4);

  PLongArray(Dest)[0] := (Rijndael_S[1, A2        and $FF]        or
                          Rijndael_S[1, D2 shr  8 and $FF] shl  8 or
                          Rijndael_S[1, C2 shr 16 and $FF] shl 16 or
                          Rijndael_S[1, B2 shr 24]         shl 24)    xor P[0];
  PLongArray(Dest)[1] := (Rijndael_S[1, B2        and $FF]        or
                          Rijndael_S[1, A2 shr  8 and $FF] shl  8 or
                          Rijndael_S[1, D2 shr 16 and $FF] shl 16 or
                          Rijndael_S[1, C2 shr 24]         shl 24)    xor P[1];
  PLongArray(Dest)[2] := (Rijndael_S[1, C2        and $FF]        or
                          Rijndael_S[1, B2 shr  8 and $FF] shl  8 or
                          Rijndael_S[1, A2 shr 16 and $FF] shl 16 or
                          Rijndael_S[1, D2 shr 24]         shl 24)    xor P[2];
  PLongArray(Dest)[3] := (Rijndael_S[1, D2        and $FF]        or
                          Rijndael_S[1, C2 shr  8 and $FF] shl  8 or
                          Rijndael_S[1, B2 shr 16 and $FF] shl 16 or
                          Rijndael_S[1, A2 shr 24]         shl 24)    xor P[3];
end;

// .TCipher_Square
class function TCipher_Square.Context: TCipherContext;
begin
  Result.KeySize := 16;
  Result.BlockSize := 16;
  Result.BufferSize := 16;
  Result.UserSize := 9 * 4 * 2 * SizeOf(Cardinal);
  Result.UserSave := False;
end;

procedure TCipher_Square.DoInit(const Key; Size: Integer);
type
  PSquare_Key = ^TSquare_Key;
  TSquare_Key = array[0..8, 0..3] of Cardinal;
var
  E,D: PSquare_Key;
  S,T,R: Cardinal;
  I,J: Integer;
begin
  E := FUser;
  D := FUser; Inc(D);
  Move(Key, E^, Size);
  for I := 1 to 8 do
  begin
    T := E[I -1, 3];
    T := T shr 8 or T shl 24;
    E[I, 0] := E[I -1, 0] xor T xor 1 shl (I - 1);
    E[I, 1] := E[I -1, 1] xor E[I, 0];
    E[I, 2] := E[I -1, 2] xor E[I, 1];
    E[I, 3] := E[I -1, 3] xor E[I, 2];

    D[8 -I, 0] := E[I, 0];
    D[8 -I, 1] := E[I, 1];
    D[8 -I, 2] := E[I, 2];
    D[8 -I, 3] := E[I, 3];

    for J := 0 to 3 do
    begin
      R := E[I -1, J];
      S := Square_PHI[R and $FF];
      T := Square_PHI[R shr  8 and $FF];
      T := T shl 8 or T shr 24;
      S := S xor T;
      T := Square_PHI[R shr 16 and $FF];
      T := T shl 16 or T shr 16;
      S := S xor T;
      T := Square_PHI[R shr 24];
      T := T shl 24 or T shr 8;
      S := S xor T;
      E[I -1, J] := S;
    end;
  end;
  D[8] := E[0];
end;

procedure TCipher_Square.DoEncode(Source, Dest: Pointer; Size: Integer);
var
  Key: PLongArray;
  A,B,C,D: Cardinal;
  AA,BB,CC: Cardinal;
  I: Integer;
begin
  Key := FUser;
  A := PLongArray(Source)[0] xor Key[0];
  B := PLongArray(Source)[1] xor Key[1];
  C := PLongArray(Source)[2] xor Key[2];
  D := PLongArray(Source)[3] xor Key[3];
  Key := @Key[4];
  for I := 0 to 6 do
  begin
    AA := Square_TE[0, A        and $FF] xor
          Square_TE[1, B        and $FF] xor
          Square_TE[2, C        and $FF] xor
          Square_TE[3, D        and $FF] xor Key[0];
    BB := Square_TE[0, A shr  8 and $FF] xor
          Square_TE[1, B shr  8 and $FF] xor
          Square_TE[2, C shr  8 and $FF] xor
          Square_TE[3, D shr  8 and $FF] xor Key[1];
    CC := Square_TE[0, A shr 16 and $FF] xor
          Square_TE[1, B shr 16 and $FF] xor
          Square_TE[2, C shr 16 and $FF] xor
          Square_TE[3, D shr 16 and $FF] xor Key[2];
    D  := Square_TE[0, A shr 24        ] xor
          Square_TE[1, B shr 24        ] xor
          Square_TE[2, C shr 24        ] xor
          Square_TE[3, D shr 24        ] xor Key[3];

    A := AA; B := BB; C := CC;

    Key := @Key[4];
  end;

  PLongArray(Dest)[0] := Cardinal(Square_SE[A        and $FF])        xor
                         Cardinal(Square_SE[B        and $FF]) shl  8 xor
                         Cardinal(Square_SE[C        and $FF]) shl 16 xor
                         Cardinal(Square_SE[D        and $FF]) shl 24 xor Key[0];
  PLongArray(Dest)[1] := Cardinal(Square_SE[A shr  8 and $FF])        xor
                         Cardinal(Square_SE[B shr  8 and $FF]) shl  8 xor
                         Cardinal(Square_SE[C shr  8 and $FF]) shl 16 xor
                         Cardinal(Square_SE[D shr  8 and $FF]) shl 24 xor Key[1];
  PLongArray(Dest)[2] := Cardinal(Square_SE[A shr 16 and $FF])        xor
                         Cardinal(Square_SE[B shr 16 and $FF]) shl  8 xor
                         Cardinal(Square_SE[C shr 16 and $FF]) shl 16 xor
                         Cardinal(Square_SE[D shr 16 and $FF]) shl 24 xor Key[2];
  PLongArray(Dest)[3] := Cardinal(Square_SE[A shr 24        ])        xor
                         Cardinal(Square_SE[B shr 24        ]) shl  8 xor
                         Cardinal(Square_SE[C shr 24        ]) shl 16 xor
                         Cardinal(Square_SE[D shr 24        ]) shl 24 xor Key[3];
end;

procedure TCipher_Square.DoDecode(Source, Dest: Pointer; Size: Integer);
var
  Key: PLongArray;
  A,B,C,D: Cardinal;
  AA,BB,CC: Cardinal;
  I: Integer;
begin
  Key := @PLongArray(FUser)[9 * 4];
  A := PLongArray(Source)[0] xor Key[0];
  B := PLongArray(Source)[1] xor Key[1];
  C := PLongArray(Source)[2] xor Key[2];
  D := PLongArray(Source)[3] xor Key[3];
  Key := @Key[4];
  for I := 0 to 6 do
  begin
    AA := Square_TD[0, A        and $FF] xor
          Square_TD[1, B        and $FF] xor
          Square_TD[2, C        and $FF] xor
          Square_TD[3, D        and $FF] xor Key[0];
    BB := Square_TD[0, A shr  8 and $FF] xor
          Square_TD[1, B shr  8 and $FF] xor
          Square_TD[2, C shr  8 and $FF] xor
          Square_TD[3, D shr  8 and $FF] xor Key[1];
    CC := Square_TD[0, A shr 16 and $FF] xor
          Square_TD[1, B shr 16 and $FF] xor
          Square_TD[2, C shr 16 and $FF] xor
          Square_TD[3, D shr 16 and $FF] xor Key[2];
    D  := Square_TD[0, A shr 24        ] xor
          Square_TD[1, B shr 24        ] xor
          Square_TD[2, C shr 24        ] xor
          Square_TD[3, D shr 24        ] xor Key[3];

    A := AA; B := BB; C := CC;
    Key := @Key[4];
  end;

  PLongArray(Dest)[0] := Cardinal(Square_SD[A        and $FF])        xor
                         Cardinal(Square_SD[B        and $FF]) shl  8 xor
                         Cardinal(Square_SD[C        and $FF]) shl 16 xor
                         Cardinal(Square_SD[D        and $FF]) shl 24 xor Key[0];
  PLongArray(Dest)[1] := Cardinal(Square_SD[A shr  8 and $FF])        xor
                         Cardinal(Square_SD[B shr  8 and $FF]) shl  8 xor
                         Cardinal(Square_SD[C shr  8 and $FF]) shl 16 xor
                         Cardinal(Square_SD[D shr  8 and $FF]) shl 24 xor Key[1];
  PLongArray(Dest)[2] := Cardinal(Square_SD[A shr 16 and $FF])        xor
                         Cardinal(Square_SD[B shr 16 and $FF]) shl  8 xor
                         Cardinal(Square_SD[C shr 16 and $FF]) shl 16 xor
                         Cardinal(Square_SD[D shr 16 and $FF]) shl 24 xor Key[2];
  PLongArray(Dest)[3] := Cardinal(Square_SD[A shr 24        ])        xor
                         Cardinal(Square_SD[B shr 24        ]) shl  8 xor
                         Cardinal(Square_SD[C shr 24        ]) shl 16 xor
                         Cardinal(Square_SD[D shr 24        ]) shl 24 xor Key[3];
end;

// .DES
procedure DES_Func(Source, Dest, Key: PLongArray);
var
  L,R,X,Y,I: Cardinal;
begin
  L := SwapLong(Source[0]);
  R := SwapLong(Source[1]);

  X := (L shr  4 xor R) and $0F0F0F0F; R := R xor X; L := L xor X shl  4;
  X := (L shr 16 xor R) and $0000FFFF; R := R xor X; L := L xor X shl 16;
  X := (R shr  2 xor L) and $33333333; L := L xor X; R := R xor X shl  2;
  X := (R shr  8 xor L) and $00FF00FF; L := L xor X; R := R xor X shl  8;

  R := R shl 1 or R shr 31;
  X := (L xor R) and $AAAAAAAA;
  R := R xor X;
  L := L xor X;
  L := L shl 1 or L shr 31;

  for I := 0 to 7 do
  begin
    X := (R shl 28 or R shr 4) xor Key[0];
    Y := R xor Key[1];
    L := L xor (DES_Data[0, X        and $3F] or DES_Data[1, X shr  8 and $3F] or
                DES_Data[2, X shr 16 and $3F] or DES_Data[3, X shr 24 and $3F] or
                DES_Data[4, Y        and $3F] or DES_Data[5, Y shr  8 and $3F] or
                DES_Data[6, Y shr 16 and $3F] or DES_Data[7, Y shr 24 and $3F]);

    X := (L shl 28 or L shr 4) xor Key[2];
    Y := L xor Key[3];
    R := R xor (DES_Data[0, X        and $3F] or DES_Data[1, X shr  8 and $3F] or
                DES_Data[2, X shr 16 and $3F] or DES_Data[3, X shr 24 and $3F] or
                DES_Data[4, Y        and $3F] or DES_Data[5, Y shr  8 and $3F] or
                DES_Data[6, Y shr 16 and $3F] or DES_Data[7, Y shr 24 and $3F]);
    Key := @Key[4];            
  end;

  R := R shl 31 or R shr 1;
  X := (L xor R) and $AAAAAAAA;
  R := R xor X;
  L := L xor X;
  L := L shl 31 or L shr 1;

  X := (L shr  8 xor R) and $00FF00FF; R := R xor X; L := L xor X shl  8;
  X := (L shr  2 xor R) and $33333333; R := R xor X; L := L xor X shl  2;
  X := (R shr 16 xor L) and $0000FFFF; L := L xor X; R := R xor X shl 16;
  X := (R shr  4 xor L) and $0F0F0F0F; L := L xor X; R := R xor X shl  4;

  Dest[0] := SwapLong(R);
  Dest[1] := SwapLong(L);
end;

// .TCipher_1DES
class function TCipher_1DES.Context: TCipherContext;
begin
  Result.KeySize := 8;
  Result.BlockSize := 8;
  Result.BufferSize := 8;
  Result.UserSize := 32 * 4 * 2;
  Result.UserSave := False;
end;

procedure TCipher_1DES.DoInitKey(const Data: array of Byte; Key: PLongArray; Reverse: Boolean);
const
  ROT: array[0..15] of Byte = (1,2,4,6,8,10,12,14,15,17,19,21,23,25,27,28);
var
  I,J,L,M,N: Cardinal;
  PC_M,PC_R: array[0..55] of Byte;
  K: array[0..31] of Cardinal;
begin
  FillChar(K, SizeOf(K), 0);
  for I := 0 to 55 do
    if Data[DES_PC1[I] shr 3] and ($80 shr (DES_PC1[I] and $07)) <> 0 then PC_M[I] := 1
      else PC_M[I] := 0;
  for I := 0 to 15 do
  begin
    if Reverse then M := (15 - I) shl 1
      else M := I shl 1;
    N := M + 1;
    for J := 0 to 27 do
    begin
      L := J + ROT[I];
      if L < 28 then PC_R[J] := PC_M[L] else PC_R[J] := PC_M[L - 28];
    end;
    for J := 28 to 55 do
    begin
      L := J + ROT[I];
      if L < 56 then PC_R[J] := PC_M[L] else PC_R[J] := PC_M[L - 28];
    end;
    L := $1000000;
    for J := 0 to 23 do
    begin
      L := L shr 1;
      if PC_R[DES_PC2[J     ]] <> 0 then K[M] := K[M] or L;
      if PC_R[DES_PC2[J + 24]] <> 0 then K[N] := K[N] or L;
    end;
  end;
  for I := 0 to 15 do
  begin
    M := I shl 1;
    N := M + 1;
    Key[0] := K[M] and $00FC0000 shl  6 or
              K[M] and $00000FC0 shl 10 or
              K[N] and $00FC0000 shr 10 or
              K[N] and $00000FC0 shr  6;
    Key[1] := K[M] and $0003F000 shl 12 or
              K[M] and $0000003F shl 16 or
              K[N] and $0003F000 shr  4 or
              K[N] and $0000003F;
    Key := @Key[2];
  end;
  ProtectBuffer(K, SizeOf(K));
  ProtectBuffer(PC_M, SizeOf(PC_M));
  ProtectBuffer(PC_R, SizeOf(PC_R));
end;

procedure TCipher_1DES.DoInit(const Key; Size: Integer);
var
  K: array[0..7] of Byte;
begin
  FillChar(K, SizeOf(K), 0);
// modified by Leo Martin, AidAim Software - crashes on simple ciphers that uses RIPE_MD_256 hash
  if (Size > SizeOf(K)) then
   Move(Key, K, SizeOf(K))
  else
   Move(Key, K, Size);
  DoInitKey(K, FUser, False);
  DoInitKey(K, @PLongArray(FUser)[32], True);
  ProtectBuffer(K, SizeOf(K));
end;

procedure TCipher_1DES.DoEncode(Source, Dest: Pointer; Size: Integer);
begin
  Assert(Size = Context.BufferSize);
  DES_Func(Source, Dest, FUser);
end;

procedure TCipher_1DES.DoDecode(Source, Dest: Pointer; Size: Integer);
begin
  Assert(Size = Context.BufferSize);
  DES_Func(Source,Dest, @PLongArray(FUser)[32]);
end;

// .TCipher_2DES
class function TCipher_2DES.Context: TCipherContext;
begin
  Result.KeySize := 16;
  Result.BlockSize := 8;
  Result.BufferSize := 8;
  Result.UserSize := 32 * 4 * 2 * 2;
  Result.UserSave := False;
end;

procedure TCipher_2DES.DoInit(const Key; Size: Integer);
var
  K: array[0..15] of Byte;
  P: PLongArray;
begin
  FillChar(K, SizeOf(K), 0);
// modified by Leo Martin, AidAim Software - crashes on simple ciphers that uses RIPE_MD_256 hash
// modified by Leo Martin, AidAim Software - crashes on simple ciphers that uses RIPE_MD_256 hash
  if (Size > SizeOf(K)) then
   Move(Key, K, SizeOf(K))
  else
   Move(Key, K, Size);
  P := FUser;
  DoInitKey(K[0], @P[ 0], False);
  DoInitKey(K[8], @P[32], True);
  DoInitKey(K[0], @P[64], True);
  DoInitKey(K[8], @P[96], False);
  ProtectBuffer(K, SizeOf(K));
end;

procedure TCipher_2DES.DoEncode(Source, Dest: Pointer; Size: Integer);
begin
  Assert(Size = Context.BufferSize);
  DES_Func(Source, Dest, FUser);
  DES_Func(Source, Dest, @PLongArray(FUser)[32]);
  DES_Func(Source, Dest, FUser);
end;

procedure TCipher_2DES.DoDecode(Source, Dest: Pointer; Size: Integer);
begin
  Assert(Size = Context.BufferSize);
  DES_Func(Source, Dest, @PLongArray(FUser)[64]);
  DES_Func(Source, Dest, @PLongArray(FUser)[96]);
  DES_Func(Source, Dest, @PLongArray(FUser)[64]);
end;

// .TCipher_3DES
class function TCipher_3DES.Context: TCipherContext;
begin
  Result.KeySize := 24;
  Result.BlockSize := 8;
  Result.BufferSize := 8;
  Result.UserSize := 32 * 4 * 2 * 3;
  Result.UserSave := False;
end;

procedure TCipher_3DES.DoInit(const Key; Size: Integer);
var
  K: array[0..23] of Byte;
  P: PLongArray;
begin
  FillChar(K, SizeOf(K), 0);
// modified by Leo Martin, AidAim Software - crashes on simple ciphers that uses RIPE_MD_256 hash
  if (Size > SizeOf(K)) then
   Move(Key, K, SizeOf(K))
  else
   Move(Key, K, Size);
  P := FUser;
  DoInitKey(K[ 0], @P[  0], False);
  DoInitKey(K[ 8], @P[ 32], True);
  DoInitKey(K[16], @P[ 64], False);
  DoInitKey(K[16], @P[ 96], True);
  DoInitKey(K[ 8], @P[128], False);
  DoInitKey(K[ 0], @P[160], True);
  ProtectBuffer(K, SizeOf(K));
end;

procedure TCipher_3DES.DoEncode(Source, Dest: Pointer; Size: Integer);
begin
  Assert(Size = Context.BufferSize);
  DES_Func(Source, Dest, @PLongArray(FUser)[ 0]);
  DES_Func(Source, Dest, @PLongArray(FUser)[32]);
  DES_Func(Source, Dest, @PLongArray(FUser)[64]);
end;

procedure TCipher_3DES.DoDecode(Source, Dest: Pointer; Size: Integer);
begin
  Assert(Size = Context.BufferSize);
  DES_Func(Source, Dest, @PLongArray(FUser)[96]);
  DES_Func(Source, Dest, @PLongArray(FUser)[128]);
  DES_Func(Source, Dest, @PLongArray(FUser)[160]);
end;

// .TCipher_2DDES
class function TCipher_2DDES.Context: TCipherContext;
begin
  Result := inherited Context;
  Result.BlockSize := 16;
  Result.BufferSize := 16;
end;

procedure TCipher_2DDES.DoEncode(Source, Dest: Pointer; Size: Integer);
var
  T: Cardinal;
  S: PLongArray absolute Source;
  D: PLongArray absolute Dest;
begin
  Assert(Size = Context.BufferSize);

  DES_Func(@S[0], @D[0], FUser);
  DES_Func(@S[2], @D[2], FUser);
  T := D[1]; D[1] := D[2]; D[2] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[32]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[32]);
  T := D[1]; D[1] := D[2]; D[2] := T;
  DES_Func(@D[0], @D[0], FUser);
  DES_Func(@D[2], @D[2], FUser);
end;

procedure TCipher_2DDES.DoDecode(Source, Dest: Pointer; Size: Integer);
var
  T: Cardinal;
  S: PLongArray absolute Source;
  D: PLongArray absolute Dest;
begin
  Assert(Size = Context.BufferSize);

  DES_Func(@S[0], @D[0], @PLongArray(FUser)[64]);
  DES_Func(@S[2], @D[2], @PLongArray(FUser)[64]);
  T := D[1]; D[1] := D[2]; D[2] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[96]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[96]);
  T := D[1]; D[1] := D[2]; D[2] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[64]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[64]);
end;

// .TCipher_3DDES
class function TCipher_3DDES.Context: TCipherContext;
begin
  Result := inherited Context;
  Result.BlockSize := 16;
  Result.BufferSize := 16;
end;

procedure TCipher_3DDES.DoEncode(Source, Dest: Pointer; Size: Integer);
var
  T: Cardinal;
  S: PLongArray absolute Source;
  D: PLongArray absolute Dest;
begin
  Assert(Size = Context.BufferSize);

  DES_Func(@S[0], @D[0], FUser);
  DES_Func(@S[2], @D[2], FUser);
  T := D[1]; D[1] := D[2]; D[2] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[32]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[32]);
  T := D[1]; D[1] := D[2]; D[2] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[64]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[64]);
end;

procedure TCipher_3DDES.DoDecode(Source, Dest: Pointer; Size: Integer);
var
  T: Cardinal;
  S: PLongArray absolute Source;
  D: PLongArray absolute Dest;
begin
  Assert(Size = Context.BufferSize);

  DES_Func(@S[0], @D[0], @PLongArray(FUser)[96]);
  DES_Func(@S[2], @D[2], @PLongArray(FUser)[96]);
  T := D[1]; D[1] := D[2]; D[2] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[128]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[128]);
  T := D[1]; D[1] := D[2]; D[2] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[160]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[160]);
end;


// .TCipher_3TDES
class function TCipher_3TDES.Context: TCipherContext;
begin
  Result := inherited Context;
  Result.BlockSize := 24;
  Result.BufferSize := 24;
end;

procedure TCipher_3TDES.DoEncode(Source, Dest: Pointer; Size: Integer);
var
  T: Cardinal;
  S: PLongArray absolute Source;
  D: PLongArray absolute Dest;
begin
  Assert(Size = Context.BufferSize);
  
  DES_Func(@S[0], @D[0], FUser);
  DES_Func(@S[2], @D[2], FUser);
  DES_Func(@S[4], @D[4], FUser);
  T := D[1]; D[1] := D[2]; D[2] := T;
  T := D[3]; D[3] := D[4]; D[4] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[32]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[32]);
  DES_Func(@D[4], @D[4], @PLongArray(FUser)[32]);
  T := D[1]; D[1] := D[2]; D[2] := T;
  T := D[3]; D[3] := D[4]; D[4] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[64]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[64]);
  DES_Func(@D[4], @D[4], @PLongArray(FUser)[64]);
end;

procedure TCipher_3TDES.DoDecode(Source, Dest: Pointer; Size: Integer);
var
  T: Cardinal;
  S: PLongArray absolute Source;
  D: PLongArray absolute Dest;
begin
  Assert(Size = Context.BufferSize);

  DES_Func(@S[0], @D[0], @PLongArray(FUser)[96]);
  DES_Func(@S[2], @D[2], @PLongArray(FUser)[96]);
  DES_Func(@S[4], @D[4], @PLongArray(FUser)[96]);
  T := D[1]; D[1] := D[2]; D[2] := T;
  T := D[3]; D[3] := D[4]; D[4] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[128]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[128]);
  DES_Func(@D[4], @D[4], @PLongArray(FUser)[128]);
  T := D[1]; D[1] := D[2]; D[2] := T;
  T := D[3]; D[3] := D[4]; D[4] := T;
  DES_Func(@D[0], @D[0], @PLongArray(FUser)[160]);
  DES_Func(@D[2], @D[2], @PLongArray(FUser)[160]);
  DES_Func(@D[4], @D[4], @PLongArray(FUser)[160]);
end;

end.
