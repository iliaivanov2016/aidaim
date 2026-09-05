unit MsgCompression;

interface

{$I MsgVer.inc}

 {$DEFINE ZLIB}
{$IFNDEF X64_ON}
 {$DEFINE PPMD}
 {$DEFINE BZIP}
{$ENDIF}

uses
 SysUtils,Classes,
{$IFDEF D12H}
  Msg_d12h,
{$ENDIF}
{$IFDEF LINUX}
  Types,
  Libc,
{$ENDIF}
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}

// MsgCommunicator units

    {$IFDEF DEBUG_LOG}
     MsgDebug,
    {$ENDIF}

     MsgTypes,
     MsgMemory,
     MsgConst,
     MsgExcept
{$IFDEF ZLIB}
 {$IFDEF X64_ON}
     ,MsgDelphiZlib
 {$ELSE}
     ,MsgZlib
 {$ENDIF}
{$ENDIF}
{$IFDEF BZIP}

  {$IFDEF LINUX}
    ,MsgBzip2
  {$ENDIF}
  {$IFDEF MSWINDOWS}
    ,MsgBzip2D      
  {$ENDIF}
{$ENDIF}
;

type

 TMsgCompressionAlgorithm1 = (acaNone,acaZLIB,acaBZIP,acaPPM);
 // SQL Names of CompressionAlgorithm
const MsgCompressionAlgorithmNames:array[0..3] of AnsiString = ('NONE', 'ZLIB','BZIP','PPM');

type
 TMsgCompressionMode = Byte; // 0-9
 TMsgCompressionLevel = (aclNone,aclFastest,aclNormal,aclMaximum); // 0,1,5,9

 TMsgCompression = packed record
  CompressionAlgorithm: TMsgCompressionAlgorithm1;
  CompressionMode:      TMsgCompressionMode;
  CompressionLevel:     TMsgCompressionLevel;
 end;

var
 // block sizes for stream classes, LoadFromStream / SaveToStream
 DefaultTemporaryBlockSize: Integer = 100 * 1024;
 // size of maximum temporary stream that stores in memory
 DefaultTemporaryLimit: Integer = 1024 * 1024;
 DefaultMemoryBlockSize: Integer = 100 * 1024; // for memory stream
 DefaultFileBlockSize: Integer = 100 * 1024; // for memory stream
 DefaultBLOBBlockSize: Integer = 100 * 1024; // for BLOB stream
 BlockSizeForFastest: Integer = 512 * 1024; // 0.5 Mb for fastest modes
 BlockSizeForNormal: Integer = 1024 * 1024; // 1.0 Mb for normal modes
 BlockSizeForMax: Integer = 1536 * 1024; // 1.5 Mb for max modes

const

 PPM_MO: array [1..9] of Byte = (2,3,4, 5, 7, 8,10, 13, 16); // Model Order
 PPM_SA: array [1..9] of Byte = (2,3,7,16,22,25,40,100,100); // MBytes RAM

type
 // Events
 TMsgNoCancelProgressEvent = procedure(
                                        Sender:       TObject;
                                        PercentDone:  Double
                             		) of object;


////////////////////////////////////////////////////////////////////////////////
//
// TMsgStream
//
////////////////////////////////////////////////////////////////////////////////


  TMsgStream = class (TStream)
  private
    FCSect:             TRTLCriticalSection;
    FBlockSize:         Integer;
    FOnProgress:        TMsgNoCancelProgressEvent; // progress for bulk operations
    FModified:   Boolean;
   protected
    // on progress
    procedure DoOnProgress(Progress: Double);
   public
    // lock
    procedure Lock; virtual;
    // unlock
    procedure Unlock; virtual;
    constructor Create;
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStreamWithPosition(
                    Stream:       TStream;
                    FromPosition: Int64;
                    StreamSize:   Int64
                    );
    procedure LoadFromStream(Stream: TStream);
    procedure LoadFromFile(const FileName: AnsiString);
    procedure SaveToFile(const FileName: AnsiString);
   public
    property BlockSize: Integer read FBlockSize write FBlockSize;
    // Progress Event
    property OnProgress: TMsgNoCancelProgressEvent read FOnProgress write FOnProgress;
    property Modified: Boolean read FModified write FModified;
  end; // TMsgStream


////////////////////////////////////////////////////////////////////////////////
//
// TMsgMemoryStream
//
////////////////////////////////////////////////////////////////////////////////


  TMsgMemoryStream = class (TMsgStream)
   private
    FBuffer:        PAnsiChar;
    FBufferSize:    Integer;
    FPosition:      Integer;
   protected
    // sets new size of the stream
    procedure InternalSetSize(const NewSize: Int64);
    // seek
    function InternalSeek(NewPosition: Integer): Integer;
    // sets new size of the stream
    procedure SetSize(NewSize: Longint);
    {$IFDEF D6H}
      overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    procedure SetSize(const NewSize: Int64); overload; override;
    {$ENDIF}
   public
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint;
    {$IFDEF D6H}
            overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    {$ENDIF}
    constructor Create(Buffer: PAnsiChar = nil; BufferSize: Integer = -1);
    destructor Destroy; override;
   public
    property Buffer: PAnsiChar read FBuffer write FBuffer;
  end; // TMsgStream


////////////////////////////////////////////////////////////////////////////////
//
// TMsgFileStream
//
////////////////////////////////////////////////////////////////////////////////


  TMsgFileStream = class (TMsgStream)
   private
    FHandle:    Integer;
    FFileName:  AnsiString;
    FMode:      Word;
   protected
    // sets new size of the stream
    procedure InternalSetSize(const NewSize: Int64);
    // sets new size of the stream
    procedure SetSize(NewSize: Longint);
    {$IFDEF D6H}
      overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    // sets new size of the stream
    procedure SetSize(const NewSize: Int64); overload; override;
    {$ENDIF}
   public
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint;
    {$IFDEF D6H}
            overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    {$ENDIF}
    constructor Create(const FileName: AnsiString; Mode: Word; TryFor: Integer = -1);
    destructor Destroy; override;
   public
    property Handle: Integer read FHandle;
    property FileName: AnsiString read FFileName;
    property Mode: Word read FMode;
  end; // TMsgStream


////////////////////////////////////////////////////////////////////////////////
//
// TMsgTemporaryStream
//
////////////////////////////////////////////////////////////////////////////////


  TMsgTemporaryStream = class (TMsgStream)
   private
    FMemoryLimit:        Integer;
    FMemoryStream:       TMsgMemoryStream;
    FFileStream:         TMsgFileStream;
    FFileName:           AnsiString;
    FInMemory:           Boolean;
   protected
    // sets new size of the stream
    procedure InternalSetSize(const NewSize: Int64);
    // sets new size of the stream
    procedure SetSize(NewSize: Longint);
    {$IFDEF D6H}
      overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    // sets new size of the stream
    procedure SetSize(const NewSize: Int64); overload; override;
    {$ENDIF}
   public
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint;
    {$IFDEF D6H}
            overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    {$ENDIF}
    constructor Create;
    destructor Destroy; override;
   public
    property FileStream: TMsgFileStream read FFileStream;
    property MemoryStream: TMsgMemoryStream read FMemoryStream;
    property FileName: AnsiString read FFileName;
    property InMemory: Boolean read FInMemory;
    property MemoryLimit: Integer read FMemoryLimit write FMemoryLimit;
  end; // TMsgTemporaryStream


 //------------------------------------------------------------------------------
 // compresses buffer
 // returns true if successful
 // outBuf - pointer to compressed data
 // outSize - size of compressed data
 //------------------------------------------------------------------------------
 function MsgInternalCompressBuffer(
                          CompressionAlgorithm:   TMsgCompressionAlgorithm1;
                          CompressionMode:        Byte;
                          InBuf:                  PAnsiChar;
                          InSize:                 Integer;
                          out OutBuf:             PAnsiChar;
                          out OutSize:            Integer
                          ): Boolean;

 // decompresse buffer
 // Outsize must be set to uncompressed size
 // return true if successful
 // OutBuf - pointer to compressed data
 // OutSize - size of compressed data
 function MsgInternalDecompressBuffer(
                          CompressionAlgorithm:   TMsgCompressionAlgorithm1;
                          InBuf:                  PAnsiChar;
                          InSize:                 Integer;
                          out OutBuf:             PAnsiChar;
                          var OutSize:            Integer
                          ): Boolean;

 function CRC32(CRC: LongWord; Data: Pointer; DataSize: LongWord): LongWord;
 procedure GetDefaultTempFileName;
 function GetTempFileName: AnsiString;
 procedure SaveDataToStream(var Data; DataSize: Integer; Stream: TStream; ErrorCode: Integer);
 procedure LoadDataFromStream(var Data; DataSize: Integer; Stream: TStream; ErrorCode: Integer);
 procedure SaveShortStringToStream(Value: ShortString; Stream: TStream; ErrorCode: Integer);
 procedure LoadShortStringFromStream(var Value: ShortString; Stream: TStream; ErrorCode: Integer);
 procedure SaveStringToStream(Value: AnsiString; Stream: TStream; ErrorCode: Integer);
 procedure LoadStringFromStream(var Value: AnsiString; Stream: TStream; ErrorCode: Integer);
 procedure SaveWideStringToStream(Value: WideString; Stream: TStream; ErrorCode: Integer);
 procedure LoadWideStringFromStream(var Value: WideString; Stream: TStream; ErrorCode: Integer);
 procedure SaveBooleanToStream(Value: Boolean; Stream: TStream; ErrorCode: Integer);
 procedure LoadBooleanFromStream(var Value: Boolean; Stream: TStream; ErrorCode: Integer);
{
 procedure SaveCryptoParamsToStream(var CryptoParams: TMsgCryptoParams; Stream: TStream; ErrorCode: Integer; DoNotSaveKeyAndPassword: Boolean = false);
 procedure LoadCryptoParamsFromStream(var CryptoParams: TMsgCryptoParams; Stream: TStream; ErrorCode: Integer; DoNotSaveKeyAndPassword: Boolean = false);
}
 procedure SetStreamPosition(Stream: TStream; NewPosition: Int64; ErrorCode: Integer);

 function GeTMsgCompressionAlgorithm(Name: AnsiString): TMsgCompressionAlgorithm1;

implementation

{$IFDEF PPMD}
 {$IFDEF LINUX}
const ppmso = 'libppmd.so.1.0.0';

function PPMCompressBuffer(inBuf  : PAnsiChar;
                           inSize : Cardinal;
                           outBuf : PAnsiChar;
										       Max_Order:integer;
                           SASize:integer
                          ) : Cardinal;
                          cdecl; external ppmso name 'PPMCompressBuffer__FPcUiT0ii';

function PPMDecompressBuffer(
                            inBuf  : PAnsiChar;
                            inSize : Cardinal;
                            outBuf : pAnsiChar
                            ) : Cardinal;
                            cdecl; external ppmso name 'PPMDecompressBuffer__FPcUiT0';
 {$ENDIF}
 {$IFDEF MSWINDOWS}
{$L ppmd.OBJ}
function PPMCompressBuffer(inBuf  : PAnsiChar;
                           inSize : Integer;
                           outBuf : PAnsiChar;
										       Max_Order:integer = 6;
                           SASize:integer = 10
                          ) : Integer; external;

function PPMDecompressBuffer(
                            inBuf  : PAnsiChar;
                            inSize : Integer;
                            outBuf : pAnsiChar
                            ) : Integer; external;
 {$ENDIF}
{$ENDIF}

procedure memset(P: Pointer; B: Byte; count: Integer); cdecl;
begin
  FillChar(P^, count, B);
end;

procedure memcpy(dest, source: Pointer; count: Integer); cdecl;
begin
  Move(source^, dest^, count);
end;


function aa_malloc(count : integer) : PAnsiChar;cdecl;
begin
 result := AllocMem(count);
end;

procedure aa_free(buffer : PAnsiChar);cdecl;
begin
 FreeMem(buffer);
end;


////////////////////////////////////////////////////////////////////////////////
//
// TMsgStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// on progress
//------------------------------------------------------------------------------
procedure TMsgStream.DoOnProgress(Progress: Double);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self,Progress);
end; // on progress


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TMsgStream.Lock;
begin
 EnterCriticalSection(FCSect);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TMsgStream.Unlock;
begin
  LeaveCriticalSection(FCSect);
end; // Unlock


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgStream.Create;
begin
 FBlockSize := DefaultMemoryBlockSize;
 FModified := False;
end; // Create


//------------------------------------------------------------------------------
// save all data to another stream
//------------------------------------------------------------------------------
procedure TMsgStream.SaveToStream(Stream: TStream);
var OutBytes,OldPos,OldPos1,InSize:	Int64;
    OutSize:					              Integer;
    Buf:            	              PAnsiChar;
    FProgress:      	              Extended;
    FProgressMax:   	              Extended;
    ReadBytes,WriteBytes:           Integer;
    Pos:                            Int64;
begin
 if (FBlockSize = 0) then
  raise EMsgException.Create(10418,ErrorLZeroBlockSizeIsNotAllowed);
 OldPos := Position;
 OldPos1 := Stream.Position;
 Position := 0;
 OutBytes := 0;
 DoOnProgress(0);
 InSize := Size;
 Buf := AllocMem(FBlockSize);
 while OutBytes < InSize do
  begin
   if (InSize - OutBytes > FBlockSize) then
    OutSize := FBlockSize
   else
    OutSize := Size - OutBytes;

   Pos := Self.Position;
   ReadBytes := Self.Read(Buf^,OutSize);
   if (ReadBytes <> OutSize) then
    raise EMsgException.Create(10146,ErrorLCannotReadFromStream,
      [Pos,Self.Size,OutSize,ReadBytes]);

   Pos := Stream.Position;
   WriteBytes := Stream.Write(Buf^,OutSize);
   if (WriteBytes <> OutSize) then
    raise EMsgException.Create(10147,ErrorLCannotWriteToStream,
      [Pos,Stream.Size,OutSize,WriteBytes]);

   Inc(OutBytes,OutSize);
   FProgressMax := Size;
   FProgress := OutBytes;
   DoOnProgress(FProgress/FProgressMax*100.0);
  end;
 FreeMem(Buf);
 Position := OldPos;
 Stream.Position := OldPos1;
 DoOnProgress(100.0);
end; // SaveToStream


//------------------------------------------------------------------------------
// load all data from another stream
//------------------------------------------------------------------------------
procedure TMsgStream.LoadFromStream(Stream: TStream);
begin
 LoadFromStreamWithPosition(Stream,0,Stream.Size);
end; // LoadFromStream


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TMsgStream.LoadFromStreamWithPosition(
                    Stream:       TStream;
                    FromPosition: Int64;
                    StreamSize:   Int64
                    );
var OldPos,OldPos1:	                Int64;
    OutSize:					              Integer;
    Buf:            	              PAnsiChar;
    FProgress:      	              Extended;
    FProgressMax:   	              Extended;
    ReadBytes,WriteBytes:           Integer;
    Pos:                            Int64;
begin
 if (FBlockSize = 0) then
  raise EMsgException.Create(10419,ErrorLZeroBlockSizeIsNotAllowed);
 OldPos := Position;
 OldPos1 := Stream.Position;
 Stream.Position := FromPosition;
 Size := 0;
 Position := 0;
 DoOnProgress(0);
 Buf := AllocMem(FBlockSize);
 while (Stream.Position < FromPosition + StreamSize) do
  begin
   if ((FromPosition + StreamSize) - Stream.Position > FBlockSize) then
    OutSize := FBlockSize
   else
    OutSize := (FromPosition + StreamSize) - Stream.Position;

   Pos := Stream.Position;
   ReadBytes := Stream.Read(Buf^,OutSize);
   if (ReadBytes <> OutSize) then
    raise EMsgException.Create(10148,ErrorLCannotReadFromStream,
      [Pos,Stream.Size,OutSize,ReadBytes]);

   Pos := Self.Position;
   WriteBytes := Self.Write(Buf^,OutSize);
   if (WriteBytes <> OutSize) then
    raise EMsgException.Create(10149,ErrorLCannotWriteToStream,
      [Pos,Self.Size,OutSize,WriteBytes]);

   FProgressMax := Stream.Size;
   FProgress := Stream.Position;
   DoOnProgress(FProgress/FProgressMax*100.0);
  end;
 FreeMem(buf);
 Position := OldPos;
 Stream.Position := OldPos1;
 DoOnProgress(100.0);
end;


//------------------------------------------------------------------------------
// load all data from file
//------------------------------------------------------------------------------
procedure TMsgStream.LoadFromFile(const FileName: AnsiString);
var
  Stream: TMsgStream;
begin
  Stream := TMsgFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end; // LoadFromFile


//------------------------------------------------------------------------------
// save all data to file
//------------------------------------------------------------------------------
procedure TMsgStream.SaveToFile(const FileName: AnsiString);
var
  Stream: TMsgStream;
begin
  Stream := TMsgFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end; // SaveToFile


////////////////////////////////////////////////////////////////////////////////
//
// TMsgMemoryStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TMsgMemoryStream.InternalSetSize(const NewSize: Int64);
begin
 if (NewSize <= 0) then
  begin
   FBufferSize := 0;
   if (FBuffer <> nil) then
     MemoryManager.FreeAndNilMem(FBuffer);
  end
 else
 if (FBufferSize = 0) then
  begin
   FBuffer := MemoryManager.GetMem(NewSize);
   FBufferSize := NewSize;
  end
 else
  begin
   FBufferSize := NewSize;
   MemoryManager.ReallocMem(FBuffer,FBufferSize);
  end;
 if (FPosition > FBufferSize) then
  FPosition := FBufferSize; 
end; // InternalSetSize


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TMsgMemoryStream.InternalSeek(NewPosition: Integer): Integer;
begin
 FPosition := NewPosition;
 result := FPosition;
end; // InternalSeek


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TMsgMemoryStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TMsgMemoryStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TMsgMemoryStream.Read(var Buffer; Count: Longint): Longint;
var NewCount: Integer;
begin
 Result := 0;
 if ((FPosition < FBufferSize) and (Count > 0)) then
  begin
   // count more than size of the buffer minus position
   if (Count > FBufferSize - FPosition) then
    NewCount := FBufferSize - FPosition
   else
    NewCount := Count;
   Move(PAnsiChar(FBuffer + FPosition)^,Buffer,NewCount);
   Result := NewCount;
   Inc(FPosition,NewCount);
  end;
end; // Read


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TMsgMemoryStream.Write(const Buffer; Count: Longint): Longint;
begin
 if (FBufferSize < FPosition + Count) then
  InternalSetSize(FPosition + Count);
 Result := Count;
 System.Move(Buffer,PAnsiChar(FBuffer + FPosition)^,Count);
 Inc(FPosition,Count);
end; // Write


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TMsgMemoryStream.Seek(Offset: Longint; Origin: Word): Longint;
var NewPosition: Integer;
begin
 NewPosition := FPosition;
 case (Origin) of
  soFromBeginning:
    NewPosition := Offset;
  soFromCurrent:
    NewPosition := Integer(FPosition) + Offset;
  soFromEnd:
    NewPosition := Integer(FBufferSize) + Offset;
 end;
 Result := InternalSeek(NewPosition);
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TMsgMemoryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
var NewPosition: Integer;
begin
 NewPosition := 0;
 case (Origin) of
  soBeginning:
    NewPosition := Offset;
  soCurrent:
    NewPosition := FPosition + Offset;
  soEnd:
    NewPosition := FBufferSize + Offset;
 end;
 Result := InternalSeek(NewPosition);
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
constructor TMsgMemoryStream.Create(Buffer: PAnsiChar = nil; BufferSize: Integer = -1);
begin
 FBuffer := nil;
 FBufferSize := 0;
 if (Buffer <> nil) then
  begin
   FBuffer := Buffer;
   if BufferSize >= 0 then
     FBufferSize := BufferSize
   else
     FBufferSize := MemoryManager.GetMemoryBufferSize(Buffer);
  end;
 FPosition := 0; 
 inherited Create; 
end; // Create
 
 
//------------------------------------------------------------------------------ 
// set size of compressed stream 
//------------------------------------------------------------------------------ 
destructor TMsgMemoryStream.Destroy;
begin
 InternalSetSize(0); 
 inherited;
end; // Destroy 
 
 
////////////////////////////////////////////////////////////////////////////////
//
// TMsgFileStream 
//
////////////////////////////////////////////////////////////////////////////////
	
 
//------------------------------------------------------------------------------ 
// sets new size of the stream
//------------------------------------------------------------------------------ 
procedure TMsgFileStream.InternalSetSize(const NewSize: Int64);
var OldPos: Int64;
{$IFDEF LINUX} 
  SysErrorCode: DWORD;
{$ENDIF}
begin
 OldPos := Position; 
 Position := NewSize;
{$IFDEF MSWINDOWS}
 Win32Check(SetEndOfFile(FHandle));
{$ENDIF} 
{$IFDEF LINUX} 
 if (lseek64(FHandle, NewSize, SEEK_SET) <> NewSize) then
   begin 
     SysErrorCode := GetLastError; 
     raise EMsgException.Create(40019, ErrorRCannotSetNewSize, 
            [FHandle, Size, NewSize, SysErrorCode, SysErrorMessage(SysErrorCode)]);
   end;
 if ftruncate(FHandle, Position) = -1 then
   begin
     SysErrorCode := GetLastError; 
     raise EMsgException.Create(40019, ErrorRCannotSetNewSize, 
            [FHandle, Size, NewSize, SysErrorCode, SysErrorMessage(SysErrorCode)]);
   end; 
{$ENDIF}
 if (OldPos > NewSize) then 
  Position := NewSize 
 else
  Position := OldPos;
end; // InternalSetSize
 
 
//------------------------------------------------------------------------------ 
// sets new size of the stream 
//------------------------------------------------------------------------------ 
procedure TMsgFileStream.SetSize(NewSize: Longint); 
begin 
 InternalSetSize(NewSize); 
end; // SetSize 
 
 
{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------ 
procedure TMsgFileStream.SetSize(const NewSize: Int64);
begin 
 InternalSetSize(NewSize); 
end; // SetSize 
{$ENDIF} 
 
 
//------------------------------------------------------------------------------ 
// read 
//------------------------------------------------------------------------------ 
function TMsgFileStream.Read(var Buffer; Count: Longint): Longint; 
begin 
 Result := FileRead(FHandle, Buffer, Count);
 if (Result = -1) then 
  Result := 0;
end; // SetSize 
 
	
//------------------------------------------------------------------------------
// write
//------------------------------------------------------------------------------ 
function TMsgFileStream.Write(const Buffer; Count: Longint): Longint;
begin
 Result := FileWrite(FHandle, Buffer, Count); 
 if (Result = -1) then 
  Result := 0;
end; // SetSize
 
	
//------------------------------------------------------------------------------ 
// seek 
//------------------------------------------------------------------------------
function TMsgFileStream.Seek(Offset: Longint; Origin: Word): Longint; 
begin
 Result := FileSeek(FHandle, Offset, Origin);
end; // SetSize 
 
	
{$IFDEF D6H} 
//------------------------------------------------------------------------------
// seek 
//------------------------------------------------------------------------------ 
function TMsgFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 Result := FileSeek(FHandle, Offset, Ord(Origin));
end; // Seek
{$ENDIF}
	
	
//------------------------------------------------------------------------------ 
// Create
//------------------------------------------------------------------------------ 
constructor TMsgFileStream.Create(const FileName: AnsiString; Mode: Word; TryFor: Integer = -1);
var
 StartTime:    Cardinal;
begin 
 FBlockSize := DefaultFileBlockSize;
 FMode := Mode; 
 FFileName := FileName;
 if (Mode = fmCreate) then
  begin
   FHandle := FileCreate(FileName);
   if (FHandle < 0) then
    raise EMsgException.Create(10104,ErrorLCannotCreateFile,[FileName]);
  end
 else
  begin
   if (TryFor >= 0) then
    begin
     StartTime := GetTickCount;
     while ((GetTickCount-StartTime) < TryFor) do
      begin
       FHandle := FileOpen(FileName,Mode);
       if (FHandle >= 0) then
         Exit;
      end;
    end
   else
     FHandle := FileOpen(FileName,Mode);
   if (FHandle < 0) then
    raise EMsgException.Create(10105,ErrorLCannotOpenFile,[FileName,Mode]);
  end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgFileStream.Destroy;
begin
 if FHandle >= 0 then
  FileClose(FHandle);
 inherited;
end; // Destroy




////////////////////////////////////////////////////////////////////////////////
//
// TMsgTemporaryStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TMsgTemporaryStream.InternalSetSize(const NewSize: Int64);
begin
 if (FInMemory) then
  FMemoryStream.Size := NewSize
 else
  FFileStream.Size := NewSize;
end; // InternalSetSize


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TMsgTemporaryStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TMsgTemporaryStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// read
//------------------------------------------------------------------------------
function TMsgTemporaryStream.Read(var Buffer; Count: Longint): Longint;
begin
 if (FInMemory) then
  Result := FMemoryStream.Read(Buffer,Count)
 else
  Result := FFileStream.Read(Buffer,Count);
end; // Read


//------------------------------------------------------------------------------
// write
//------------------------------------------------------------------------------
function TMsgTemporaryStream.Write(const Buffer; Count: Longint): Longint;
begin
 if (FInMemory) then
  begin
    if (FMemoryStream.Size + Int64(Count) <= FMemoryLimit) then
     Result := FMemoryStream.Write(Buffer,Count)
    else
     begin
      FFileName := GetTempFileName;
      FFileStream := TMsgFileStream.Create(FFileName,fmCreate);
      FFileStream.LoadFromStream(FMemoryStream);
      FFileStream.Position := FMemoryStream.Position;
      FMemoryStream.Free;
      FMemoryStream := nil;
      FInMemory := false;
      Result := FFileStream.Write(Buffer,Count);
     end;
  end
 else
  begin
    Result := FFileStream.Write(Buffer,Count);
  end;
end; // Write


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TMsgTemporaryStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 if (FInMemory) then
  Result := FMemoryStream.Seek(Offset,Origin)
 else
  Result := FFileStream.Seek(Offset,Origin);
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TMsgTemporaryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 if (FInMemory) then
  Result := FMemoryStream.Seek(Offset,Origin)
 else
  Result := FFileStream.Seek(Offset,Origin);
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TMsgTemporaryStream.Create;
begin
 FBlockSize := DefaultTemporaryBlockSize;
 FMemoryLimit := DefaultTemporaryLimit;
 FFileName := '';
 FInMemory := True;
 FMemoryStream := TMsgMemoryStream.Create;
 FFileStream := nil;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TMsgTemporaryStream.Destroy;
begin
 if (FMemoryStream <> nil) then
  FMemoryStream.Free;
 if (FFileStream <> nil) then
  begin
   FFileStream.Free;
   SysUtils.DeleteFile(FFileName);
  end;
 inherited;
end; // Destroy


//------------------------------------------------------------------------------
// compresses buffer
// returns true if successful
// outBuf - pointer to compressed data
// outSize - size of compressed data
//------------------------------------------------------------------------------
function MsgInternalCompressBuffer(
                          CompressionAlgorithm:   TMsgCompressionAlgorithm1;
                          CompressionMode:        Byte;
                          InBuf:                  PAnsiChar;
                          InSize:                 Integer;
                          out OutBuf:             PAnsiChar;
                          out OutSize:            Integer
                          ): Boolean;
begin
 Result := false;
 OutSize := 0;
 // empty buffer cannot be compressed
 // none compression is not allowed
 if ((CompressionAlgorithm = acaNone) or (InSize = 0)) then Exit;
 Result := true;
 case CompressionAlgorithm of
{$IFDEF ZLIB}
  acaZLIB:
   begin
    try
     ZLIBCompressBuf(InBuf,InSize,Pointer(Outbuf),Integer(OutSize),CompressionMode);
    except
     Result := false;
    end;
    if (OutSize <= 0) then
     Result := false;
   end
{$ENDIF}
{$IFDEF BZIP}
  {$IFDEF ZLIB}
  ;
  {$ENDIF}
  acaBZIP:
   begin
    try
     bzCompressBuf(InBuf,InSize,Pointer(Outbuf),Integer(OutSize),CompressionMode)
    except
     Result := false;
    end;
    if (OutSize <= 0) then
     Result := false;
   end
{$ENDIF}
{$IFDEF PPMD}
  {$IFDEF ZLIB}
  ;
  {$ELSE}
    {$IFDEF ZLIB}
    ;
    {$ENDIF}
  {$ENDIF}
  acaPPM:
   begin
    try
     // some memory reserve for none-compressible data
     OutSize := InSize + InSize div 20 + 50;
     OutBuf := AllocMem(OutSize);
     OutSize := PPMCompressBuffer(
                InBuf,InSize,OutBuf,
                PPM_MO[CompressionMode],
                PPM_SA[CompressionMode]
                );
    except
     Result := false;
    end;
    if (OutSize <= 0) then
     Result := false;
   end
{$ENDIF}
;
  else
   Result := false;
 end; // case compression ?????????
end; // MsgInternalCompressBuffer;


//------------------------------------------------------------------------------
// decompresse buffer
// Outsize must be set to uncompressed size
// return true if successful
// OutBuf - pointer to compressed data
// OutSize - size of compressed data
//------------------------------------------------------------------------------
function MsgInternalDecompressBuffer(
                          CompressionAlgorithm:   TMsgCompressionAlgorithm1;
                          InBuf:                  PAnsiChar;
                          InSize:                 Integer;
                          out OutBuf:             PAnsiChar;
                          var OutSize:            Integer
                          ): Boolean;
begin
 Result := false;
 if ((CompressionAlgorithm = acaNone) or (InSize = 0)) then Exit;
 Result := true;
 case CompressionAlgorithm of
{$IFDEF ZLIB}
  acaZLIB:
   begin
    try
     ZLIBDecompressBuf(InBuf,InSize,OutSize,Pointer(Outbuf),Integer(OutSize));
    except
     Result := false;
    end;
    if (OutSize <= 0) then
     Result := false;
   end
{$ENDIF}
{$IFDEF BZIP}
  {$IFDEF ZLIB}
  ;
  {$ENDIF}
  acaBZIP:
   begin
    try
     bzDecompressBuf(InBuf,InSize,OutSize,Pointer(Outbuf),Integer(OutSize));
    except
     Result := false;
    end;
    if (OutSize <= 0) then
     Result := false;
   end
{$ENDIF}
{$IFDEF PPMD}
  {$IFDEF ZLIB}
  ;
  {$ELSE}
    {$IFDEF ZLIB}
    ;
    {$ENDIF}
  {$ENDIF}
  acaPPM:
   begin
    try
     OutBuf := AllocMem(OutSize);
     OutSize := PPMDecompressBuffer(InBuf,InSize,OutBuf);
    except
     Result := false;
    end;
    if (OutSize <= 0) then
     Result := false;
   end
{$ENDIF}
;
  else
   Result := false;
 end; //case compression algorithm
end; // MsgInternalDecompressBuffer;

{$IFDEF X64_ON}
const
  CRC32_Table : array[0..267] of dword = (
    $000000000,$077073096,$0EE0E612C,$0990951BA,$0076DC419,$0706AF48F,$0E963A535,$09E6495A3,$00EDB8832,$079DCB8A4,
    $0E0D5E91E,$097D2D988,$009B64C2B,$07EB17CBD,$0E7B82D07,$090BF1D91,$01DB71064,$06AB020F2,$0F3B97148,$084BE41DE,
    $01ADAD47D,$06DDDE4EB,$0F4D4B551,$083D385C7,$0136C9856,$0646BA8C0,$0FD62F97A,$08A65C9EC,$014015C4F,$063066CD9,
    $0FA0F3D63,$08D080DF5,$03B6E20C8,$04C69105E,$0D56041E4,$0A2677172,$03C03E4D1,$04B04D447,$0D20D85FD,$0A50AB56B,
    $035B5A8FA,$042B2986C,$0DBBBC9D6,$0ACBCF940,$032D86CE3,$045DF5C75,$0DCD60DCF,$0ABD13D59,$026D930AC,$051DE003A,
    $0C8D75180,$0BFD06116,$021B4F4B5,$056B3C423,$0CFBA9599,$0B8BDA50F,$02802B89E,$05F058808,$0C60CD9B2,$0B10BE924,
    $02F6F7C87,$058684C11,$0C1611DAB,$0B6662D3D,$076DC4190,$001DB7106,$098D220BC,$0EFD5102A,$071B18589,$006B6B51F,
    $09FBFE4A5,$0E8B8D433,$07807C9A2,$00F00F934,$09609A88E,$0E10E9818,$07F6A0DBB,$0086D3D2D,$091646C97,$0E6635C01,
    $06B6B51F4,$01C6C6162,$0856530D8,$0F262004E,$06C0695ED,$01B01A57B,$08208F4C1,$0F50FC457,$065B0D9C6,$012B7E950,
    $08BBEB8EA,$0FCB9887C,$062DD1DDF,$015DA2D49,$08CD37CF3,$0FBD44C65,$04DB26158,$03AB551CE,$0A3BC0074,$0D4BB30E2,
    $04ADFA541,$03DD895D7,$0A4D1C46D,$0D3D6F4FB,$04369E96A,$0346ED9FC,$0AD678846,$0DA60B8D0,$044042D73,$033031DE5,
    $0AA0A4C5F,$0DD0D7CC9,$05005713C,$0270241AA,$0BE0B1010,$0C90C2086,$05768B525,$0206F85B3,$0B966D409,$0CE61E49F,
    $05EDEF90E,$029D9C998,$0B0D09822,$0C7D7A8B4,$059B33D17,$02EB40D81,$0B7BD5C3B,$0C0BA6CAD,$0EDB88320,$09ABFB3B6,
    $003B6E20C,$074B1D29A,$0EAD54739,$09DD277AF,$004DB2615,$073DC1683,$0E3630B12,$094643B84,$00D6D6A3E,$07A6A5AA8,
    $0E40ECF0B,$09309FF9D,$00A00AE27,$07D079EB1,$0F00F9344,$08708A3D2,$01E01F268,$06906C2FE,$0F762575D,$0806567CB,
    $0196C3671,$06E6B06E7,$0FED41B76,$089D32BE0,$010DA7A5A,$067DD4ACC,$0F9B9DF6F,$08EBEEFF9,$017B7BE43,$060B08ED5,
    $0D6D6A3E8,$0A1D1937E,$038D8C2C4,$04FDFF252,$0D1BB67F1,$0A6BC5767,$03FB506DD,$048B2364B,$0D80D2BDA,$0AF0A1B4C,
    $036034AF6,$041047A60,$0DF60EFC3,$0A867DF55,$0316E8EEF,$04669BE79,$0CB61B38C,$0BC66831A,$0256FD2A0,$05268E236,
    $0CC0C7795,$0BB0B4703,$0220216B9,$05505262F,$0C5BA3BBE,$0B2BD0B28,$02BB45A92,$05CB36A04,$0C2D7FFA7,$0B5D0CF31,
    $02CD99E8B,$05BDEAE1D,$09B64C2B0,$0EC63F226,$0756AA39C,$0026D930A,$09C0906A9,$0EB0E363F,$072076785,$005005713,
    $095BF4A82,$0E2B87A14,$07BB12BAE,$00CB61B38,$092D28E9B,$0E5D5BE0D,$07CDCEFB7,$00BDBDF21,$086D3D2D4,$0F1D4E242,
    $068DDB3F8,$01FDA836E,$081BE16CD,$0F6B9265B,$06FB077E1,$018B74777,$088085AE6,$0FF0F6A70,$066063BCA,$011010B5C,
    $08F659EFF,$0F862AE69,$0616BFFD3,$0166CCF45,$0A00AE278,$0D70DD2EE,$04E048354,$03903B3C2,$0A7672661,$0D06016F7,
    $04969474D,$03E6E77DB,$0AED16A4A,$0D9D65ADC,$040DF0B66,$037D83BF0,$0A9BCAE53,$0DEBB9EC5,$047B2CF7F,$030B5FFE9,
    $0BDBDF21C,$0CABAC28A,$053B39330,$024B4A3A6,$0BAD03605,$0CDD70693,$054DE5729,$023D967BF,$0B3667A2E,$0C4614AB8,
    $05D681B02,$02A6F2B94,$0B40BBE37,$0C30C8EA1,$05A05DF1B,$02D02EF8D,$074726F50,$0736E6F69,$0706F4320,$067697279,
    $028207468,$031202963,$020393939,$048207962,$06E656761,$064655220,$06E616D64,$06FBBA36E
  );

function CRC32(CRC: LongWord; Data: Pointer; DataSize: LongWord): LongWord;  register;
var
  wData : PByteArray absolute Data;
  i     : integer;
begin
  if ( Data <> nil ) and ( DataSize > 0 )
    then
      begin
        {CRC := not CRC;}
        for i := 0 to DataSize - 1 do
          CRC := CRC32_Table[ wData[i] xor byte(CRC) ] xor ( CRC shr 8 );
      end;
  Result := {not} CRC;
end;
{$ELSE}
//------------------------------------------------------------------------------
// CRC32
//------------------------------------------------------------------------------
function CRC32(CRC: LongWord; Data: Pointer; DataSize: LongWord): LongWord; assembler;
asm
         AND    EDX,EDX
         JZ     @Exit
         AND    ECX,ECX
         JLE    @Exit
         PUSH   EBX
         PUSH   EDI
         XOR    EBX,EBX
         LEA    EDI,CS:[OFFSET @CRC32]
@Start:  MOV    BL,AL
         SHR    EAX,8
         XOR    BL,[EDX]
         XOR    EAX,[EDI + EBX * 4]
         INC    EDX
         DEC    ECX
         JNZ    @Start
         POP    EDI
         POP    EBX
@Exit:   RET
         DB 0, 0, 0, 0, 0 // Align Table
@CRC32:  DD 000000000h, 077073096h, 0EE0E612Ch, 0990951BAh
         DD 0076DC419h, 0706AF48Fh, 0E963A535h, 09E6495A3h
         DD 00EDB8832h, 079DCB8A4h, 0E0D5E91Eh, 097D2D988h
         DD 009B64C2Bh, 07EB17CBDh, 0E7B82D07h, 090BF1D91h
         DD 01DB71064h, 06AB020F2h, 0F3B97148h, 084BE41DEh
         DD 01ADAD47Dh, 06DDDE4EBh, 0F4D4B551h, 083D385C7h
         DD 0136C9856h, 0646BA8C0h, 0FD62F97Ah, 08A65C9ECh
         DD 014015C4Fh, 063066CD9h, 0FA0F3D63h, 08D080DF5h
         DD 03B6E20C8h, 04C69105Eh, 0D56041E4h, 0A2677172h
         DD 03C03E4D1h, 04B04D447h, 0D20D85FDh, 0A50AB56Bh
         DD 035B5A8FAh, 042B2986Ch, 0DBBBC9D6h, 0ACBCF940h
         DD 032D86CE3h, 045DF5C75h, 0DCD60DCFh, 0ABD13D59h
         DD 026D930ACh, 051DE003Ah, 0C8D75180h, 0BFD06116h
         DD 021B4F4B5h, 056B3C423h, 0CFBA9599h, 0B8BDA50Fh
         DD 02802B89Eh, 05F058808h, 0C60CD9B2h, 0B10BE924h
         DD 02F6F7C87h, 058684C11h, 0C1611DABh, 0B6662D3Dh
         DD 076DC4190h, 001DB7106h, 098D220BCh, 0EFD5102Ah
         DD 071B18589h, 006B6B51Fh, 09FBFE4A5h, 0E8B8D433h
         DD 07807C9A2h, 00F00F934h, 09609A88Eh, 0E10E9818h
         DD 07F6A0DBBh, 0086D3D2Dh, 091646C97h, 0E6635C01h
         DD 06B6B51F4h, 01C6C6162h, 0856530D8h, 0F262004Eh
         DD 06C0695EDh, 01B01A57Bh, 08208F4C1h, 0F50FC457h
         DD 065B0D9C6h, 012B7E950h, 08BBEB8EAh, 0FCB9887Ch
         DD 062DD1DDFh, 015DA2D49h, 08CD37CF3h, 0FBD44C65h
         DD 04DB26158h, 03AB551CEh, 0A3BC0074h, 0D4BB30E2h
         DD 04ADFA541h, 03DD895D7h, 0A4D1C46Dh, 0D3D6F4FBh
         DD 04369E96Ah, 0346ED9FCh, 0AD678846h, 0DA60B8D0h
         DD 044042D73h, 033031DE5h, 0AA0A4C5Fh, 0DD0D7CC9h
         DD 05005713Ch, 0270241AAh, 0BE0B1010h, 0C90C2086h
         DD 05768B525h, 0206F85B3h, 0B966D409h, 0CE61E49Fh
         DD 05EDEF90Eh, 029D9C998h, 0B0D09822h, 0C7D7A8B4h
         DD 059B33D17h, 02EB40D81h, 0B7BD5C3Bh, 0C0BA6CADh
         DD 0EDB88320h, 09ABFB3B6h, 003B6E20Ch, 074B1D29Ah
         DD 0EAD54739h, 09DD277AFh, 004DB2615h, 073DC1683h
         DD 0E3630B12h, 094643B84h, 00D6D6A3Eh, 07A6A5AA8h
         DD 0E40ECF0Bh, 09309FF9Dh, 00A00AE27h, 07D079EB1h
         DD 0F00F9344h, 08708A3D2h, 01E01F268h, 06906C2FEh
         DD 0F762575Dh, 0806567CBh, 0196C3671h, 06E6B06E7h
         DD 0FED41B76h, 089D32BE0h, 010DA7A5Ah, 067DD4ACCh
         DD 0F9B9DF6Fh, 08EBEEFF9h, 017B7BE43h, 060B08ED5h
         DD 0D6D6A3E8h, 0A1D1937Eh, 038D8C2C4h, 04FDFF252h
         DD 0D1BB67F1h, 0A6BC5767h, 03FB506DDh, 048B2364Bh
         DD 0D80D2BDAh, 0AF0A1B4Ch, 036034AF6h, 041047A60h
         DD 0DF60EFC3h, 0A867DF55h, 0316E8EEFh, 04669BE79h
         DD 0CB61B38Ch, 0BC66831Ah, 0256FD2A0h, 05268E236h
         DD 0CC0C7795h, 0BB0B4703h, 0220216B9h, 05505262Fh
         DD 0C5BA3BBEh, 0B2BD0B28h, 02BB45A92h, 05CB36A04h
         DD 0C2D7FFA7h, 0B5D0CF31h, 02CD99E8Bh, 05BDEAE1Dh
         DD 09B64C2B0h, 0EC63F226h, 0756AA39Ch, 0026D930Ah
         DD 09C0906A9h, 0EB0E363Fh, 072076785h, 005005713h
         DD 095BF4A82h, 0E2B87A14h, 07BB12BAEh, 00CB61B38h
         DD 092D28E9Bh, 0E5D5BE0Dh, 07CDCEFB7h, 00BDBDF21h
         DD 086D3D2D4h, 0F1D4E242h, 068DDB3F8h, 01FDA836Eh
         DD 081BE16CDh, 0F6B9265Bh, 06FB077E1h, 018B74777h
         DD 088085AE6h, 0FF0F6A70h, 066063BCAh, 011010B5Ch
         DD 08F659EFFh, 0F862AE69h, 0616BFFD3h, 0166CCF45h
         DD 0A00AE278h, 0D70DD2EEh, 04E048354h, 03903B3C2h
         DD 0A7672661h, 0D06016F7h, 04969474Dh, 03E6E77DBh
         DD 0AED16A4Ah, 0D9D65ADCh, 040DF0B66h, 037D83BF0h
         DD 0A9BCAE53h, 0DEBB9EC5h, 047B2CF7Fh, 030B5FFE9h
         DD 0BDBDF21Ch, 0CABAC28Ah, 053B39330h, 024B4A3A6h
         DD 0BAD03605h, 0CDD70693h, 054DE5729h, 023D967BFh
         DD 0B3667A2Eh, 0C4614AB8h, 05D681B02h, 02A6F2B94h
         DD 0B40BBE37h, 0C30C8EA1h, 05A05DF1Bh, 02D02EF8Dh
         DD 074726F50h, 0736E6F69h, 0706F4320h, 067697279h
         DD 028207468h, 031202963h, 020393939h, 048207962h
         DD 06E656761h, 064655220h, 06E616D64h, 06FBBA36Eh
end; // CRC32
{$ENDIF}


{$IFDEF MSWINDOWS}
//------------------------------------------------------------------------------
// Get temp file name
//------------------------------------------------------------------------------
procedure GetDefaultTempFileName;
var
  TempPath : array[0..255] of AnsiChar;
  l:          Integer;
begin
  // get temp file name
  Windows.GetTempPathA(255, @TempPath);
  l := {$IFDEF D12H}aaStrLen({$ELSE}StrLen({$ENDIF}@TempPath[0]);
  SetLength(MsgDefaultTempDir,l);
  Move(TempPath[0],MsgDefaultTempDir[1],l);
end;// GetDefaultTempFileName


//------------------------------------------------------------------------------
// Get temp file name
//------------------------------------------------------------------------------
function GetTempFileName: AnsiString;
var
  TempPath : array[0..255] of AnsiChar;
  Prefix : array[0..10] of AnsiChar;
  lpTempName: array [0..MAX_PATH] of AnsiChar;
begin
  // get temp file name
  StrPCopy(Prefix, 'Msg');
  FillChar(TempPath[0],Length(TempPath),$00);
  Move(MsgDefaultTempDir[1],TempPath[0],Length(MsgDefaultTempDir));
  Windows.GetTempFileNameA(@TempPath, @Prefix, 0, lpTempName);
  Result := lpTempName;
end;// GetTempFileName
{$ENDIF}

{$IFDEF LINUX}
//------------------------------------------------------------------------------
// Get temp file name
//------------------------------------------------------------------------------
procedure GetDefaultTempFileName;
begin
  MsgDefaultTempDir := '/tmp/';
end;// GetDefaultTempFileName


function GetTempFileName: AnsiString;
var
  Template : array[0..MAX_PATH] of AnsiChar;
  lpTempName: array [0..MAX_PATH] of AnsiChar;
  TempFileName : PAnsiChar;
  s: AnsiString;
begin
  // get temp file name
  s := MsgDefaultTempDir+'MsgXXXXXX';
  StrPCopy(Template, s);
//  TempFileName := AllocMem(MAX_PATH);
  TempFileName := mktemp(Template);
  if TempFileName = nil then
    raise EMsgException.Create(40018,ErrorRCannotGetTempFileName);
  Move(TempFileName^,lpTempName,MAX_PATH);
//  Free(TempFileName);
  Result := lpTempName;
end;// GetTempFileName
{$ENDIF}


//------------------------------------------------------------------------------
// save data
//------------------------------------------------------------------------------
procedure SaveDataToStream(var Data; DataSize: Integer; Stream: TStream; ErrorCode: Integer);
var OldPos:     Int64;
    WriteBytes: Integer;
begin
  OldPos := Stream.Position;
  WriteBytes := Stream.Write(Data,DataSize);
  if (WriteBytes <> DataSize) then
    raise EMsgException.Create(ErrorCode,ErrorLCannotWriteToStream,
      [OldPos,Stream.Size,DataSize,WriteBytes]);
end; // SaveDataToStream


//------------------------------------------------------------------------------
// load data
//------------------------------------------------------------------------------
procedure LoadDataFromStream(var Data; DataSize: Integer; Stream: TStream; ErrorCode: Integer);
var OldPos:    Int64;
    ReadBytes: Integer;
begin
  OldPos := Stream.Position;
  ReadBytes := Stream.Read(Data,DataSize);
  if (ReadBytes <> DataSize) then
    raise EMsgException.Create(ErrorCode,ErrorLCannotReadFromStream,
      [OldPos,Stream.Size,DataSize,ReadBytes]);
end; // LoadDataFromStream


//------------------------------------------------------------------------------
// save short AnsiString to stream
//------------------------------------------------------------------------------
procedure SaveShortStringToStream(Value: ShortString; Stream: TStream; ErrorCode: Integer);
var l: Byte;
begin
  l := Ord(Value[0]);
  SaveDataToStream(l,SizeOf(l),Stream,ErrorCode);
  if (l > 0) then
   SaveDataToStream(Value[1],l,Stream,ErrorCode);
end; // SaveShortStringToStream


//------------------------------------------------------------------------------
// load short AnsiString from stream
//------------------------------------------------------------------------------
procedure LoadShortStringFromStream(var Value: ShortString; Stream: TStream; ErrorCode: Integer);
var l: Byte;
begin
  LoadDataFromStream(l,SizeOf(l),Stream,ErrorCode);
  Value[0] := AnsiChar(l);
  if (l > 0) then
   LoadDataFromStream(Value[1],l,Stream,ErrorCode);
end; // LoadShortStringFromStream


//------------------------------------------------------------------------------
// save AnsiString to stream
//------------------------------------------------------------------------------
procedure SaveStringToStream(Value: AnsiString; Stream: TStream; ErrorCode: Integer);
var l: Integer;
begin
  l := Length(Value);
  SaveDataToStream(l,SizeOf(l),Stream,ErrorCode);
  if (l > 0) then
   SaveDataToStream(Value[1],l,Stream,ErrorCode);
end; // SaveStringToStream


//------------------------------------------------------------------------------
// load AnsiString from stream
//------------------------------------------------------------------------------
procedure LoadStringFromStream(var Value: AnsiString; Stream: TStream; ErrorCode: Integer);
var l: Integer;
begin
  LoadDataFromStream(l,SizeOf(l),Stream,ErrorCode);
  SetLength(Value,l);
  if (l > 0) then
   LoadDataFromStream(Value[1],l,Stream,ErrorCode);
end; // LoadStringFromStream


//------------------------------------------------------------------------------
// save WideString to stream
//------------------------------------------------------------------------------
procedure SaveWideStringToStream(Value: WideString; Stream: TStream; ErrorCode: Integer);
var l: Integer;
begin
  l := Length(Value) * 2;
  SaveDataToStream(l,SizeOf(l),Stream,ErrorCode);
  if (l > 0) then
   SaveDataToStream(Value[1],l,Stream,ErrorCode);
end; // SaveWideStringToStream


//------------------------------------------------------------------------------
// load WideString from stream
//------------------------------------------------------------------------------
procedure LoadWideStringFromStream(var Value: WideString; Stream: TStream; ErrorCode: Integer);
var l: Integer;
begin
  LoadDataFromStream(l,SizeOf(l),Stream,ErrorCode);
  SetLength(Value,(l div 2));
  if (l > 0) then
   LoadDataFromStream(Value[1],l,Stream,ErrorCode);
end; // LoadWideStringFromStream


//------------------------------------------------------------------------------
// save Boolean to stream
//------------------------------------------------------------------------------
procedure SaveBooleanToStream(Value: Boolean; Stream: TStream; ErrorCode: Integer);
var b: ByteBool;
begin
  b := Value;
  SaveDataToStream(b,SizeOf(b),Stream,ErrorCode);
end; // SaveBooleanToStream


//------------------------------------------------------------------------------
// load Boolean from stream
//------------------------------------------------------------------------------
procedure LoadBooleanFromStream(var Value: Boolean; Stream: TStream; ErrorCode: Integer);
var b: ByteBool;
begin
  LoadDataFromStream(b,SizeOf(b),Stream,ErrorCode);
  Value := b;
end; // LoadBooleanFromStream


//------------------------------------------------------------------------------
// save CryptoParams record to stream
//------------------------------------------------------------------------------
{
procedure SaveCryptoParamsToStream(var CryptoParams:        TMsgCryptoParams;
                                   Stream:                  TStream;
                                   ErrorCode:               Integer;
                                   DoNotSaveKeyAndPassword: Boolean = false);
var Len: Integer;
    b:   ByteBool;
begin
 try
  if (not DoNotSaveKeyAndPassword) then
   begin
    Len := Length(CryptoParams.Password);
    SaveDataToStream(Len,SizeOf(Len),Stream,11151);
    SaveDataToStream(PAnsiChar(@CryptoParams.Password[1])^,Len,Stream,11152);
    SaveDataToStream(CryptoParams.KeyInfo,SizeOf(CryptoParams.KeyInfo),Stream,11153);
   end;
  SaveDataToStream(CryptoParams.InitVector,SizeOf(CryptoParams.InitVector),Stream,11154);
  SaveDataToStream(CryptoParams.CryptoAlgorithm,SizeOf(CryptoParams.CryptoAlgorithm),Stream,11155);
  SaveDataToStream(CryptoParams.CryptoMode,SizeOf(CryptoParams.CryptoMode),Stream,11156);
  b := CryptoParams.UseInitVector;
  SaveDataToStream(b,SizeOf(b),Stream,11157);
 except
   on e: Exception do
    raise EMsgException.Create(ErrorCode,ErrorLCannotSaveCryptoParams,[e.Message]);
 end;
end; // SaveCryptoParamsToStream


//------------------------------------------------------------------------------
// load CryptoParams record from stream
//------------------------------------------------------------------------------
procedure LoadCryptoParamsFromStream(var CryptoParams:        TMsgCryptoParams;
                                     Stream:                  TStream;
                                     ErrorCode:               Integer;
                                     DoNotSaveKeyAndPassword: Boolean = false);
var Len: Integer;
    b:   ByteBool;
begin
 try
  if (not DoNotSaveKeyAndPassword) then
   begin
    LoadDataFromStream(Len,SizeOf(Len),Stream,11158);
    SetLength(CryptoParams.Password,Len);
    LoadDataFromStream(PAnsiChar(@CryptoParams.Password[1])^,Len,Stream,11159);
    LoadDataFromStream(CryptoParams.KeyInfo,SizeOf(CryptoParams.KeyInfo),Stream,11160);
   end;
  LoadDataFromStream(CryptoParams.InitVector,SizeOf(CryptoParams.InitVector),Stream,11161);
  LoadDataFromStream(CryptoParams.CryptoAlgorithm,SizeOf(CryptoParams.CryptoAlgorithm),Stream,11162);
  LoadDataFromStream(CryptoParams.CryptoMode,SizeOf(CryptoParams.CryptoMode),Stream,11163);
  LoadDataFromStream(b,SizeOf(b),Stream,11164);
  CryptoParams.UseInitVector := b;
 except
   on e: Exception do
    raise EMsgException.Create(ErrorCode,ErrorLCannotLoadCryptoParams,[e.Message]);
 end;
end; // LoadCryptoParamsFromStream
}

//------------------------------------------------------------------------------
// set stream position
//------------------------------------------------------------------------------
procedure SetStreamPosition(Stream: TStream; NewPosition: Int64; ErrorCode: Integer);
var OldPos: Int64;
begin
 OldPos := Stream.Position;
 Stream.Position := NewPosition;
 if (Stream.Position <> NewPosition) then
  raise EMsgException.Create(ErrorCode,ErrorLCannotSetPosition,
    [NewPosition,OldPos,Stream.Size]);
end; // SetStreamPosition


//------------------------------------------------------------------------------
// Return CompressionAlgorithm by its Name
//------------------------------------------------------------------------------
function GeTMsgCompressionAlgorithm(Name: AnsiString): TMsgCompressionAlgorithm1;
var i: Integer;
begin
  Result := acaNone;
  Name := AnsiUpperCase(Name);
  for i:=0 to High(MsgCompressionAlgorithmNames) do
    if (MsgCompressionAlgorithmNames[i] = Name) then
      begin
        Result := TMsgCompressionAlgorithm1(i);
        Exit;
      end;
end;//GeTMsgCompressionAlgorithm

initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('MsgCompression> initialized');
{$ENDIF}
 GetDefaultTempFileName;

end.

