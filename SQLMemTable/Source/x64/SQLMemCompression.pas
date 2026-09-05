unit SQLMemCompression;

interface

{$I SQLMemVer.inc}


uses
 SysUtils,Classes,
{$IFDEF LINUX}
  Types,
  Libc,
{$ENDIF}
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}

// SQLMemTable units

    {$IFDEF DEBUG_LOG}
     SQLMemDebug,
    {$ENDIF}

{$IFDEF D12H}
     SQLMem_d12h,
{$ENDIF}
{$IFNDEF SQLMEMTABLE}
     SQLMemCrypto,
{$ENDIF}
     SQLMemTypes,
     SQLMemCriticalSection,
     SQLMemConverts,
     SQLMemConst,
     SQLMemDECCRC,
     SQLMemExcept
{$IFDEF ZLIB}
 {$IFDEF X64_ON}
    ,SQLMemZlib_64
 {$ELSE}
    ,SQLMemZlib
 {$ENDIF}
{$ENDIF}
{$IFDEF BZIP}
  {$IFDEF LINUX}
    ,SQLMemBzip2
  {$ENDIF}
  {$IFDEF MSWINDOWS}
     {$IFDEF X64_ON}
     ,SQLMemBzip2_64
     {$ELSE}
     ,SQLMemBzip2D
     {$ENDIF}
  {$ENDIF}
{$ENDIF}
{$IFDEF PPMDI}
 ,SQLMemppmdi
{$ENDIF}

    ,SQLMemMemory  // last
;

type

TSQLMemCompressionAlgorithm = (
acaNone,acaZLIB,acaBZIP
{$IFNDEF X64_ON}
,acaPPM
{$ENDIF}
{$IFDEF PPMDI}
,acaPPMI
{$ENDIF}
);
// SQL Names of CompressionAlgorithm
{$IFNDEF X64_ON}
const SQLMemCompressionAlgorithmNames:array[0..4] of AnsiString = ('NONE', 'ZLIB','BZIP','PPM','PPMI');
{$ELSE}
const SQLMemCompressionAlgorithmNames:array[0..3] of AnsiString = ('NONE', 'ZLIB','BZIP','PPMI');
{$ENDIF}
const SQLMem_MAX_COMPRESSION_ALGORITHM = 3;
const SQLMem_MAX_COMPRESSION_MODE = 9;

type
 TSQLMemCompressionMode = Byte; // 0-9
 TSQLMemCompressionLevel = (aclNone,aclFastest,aclNormal,aclMaximum); // 0,1,5,9

 TSQLMemCompression = packed record
  CompressionAlgorithm: TSQLMemCompressionAlgorithm;
  CompressionMode:      TSQLMemCompressionMode;
  CompressionLevel:     TSQLMemCompressionLevel;
 end;

var
 // block sizes for stream classes, LoadFromStream / SaveToStream
 DefaultTemporaryBlockSize: Integer = 32 * 1024; // 32 Kb
 // size of maximum temporary stream that stores in memory
 DefaultTemporaryLimit: Integer = 1024 * 1024; // 1 MB
 DefaultMemoryBlockSize: Integer = 100 * 1024; // for memory stream
 DefaultFileBlockSize: Integer = 100 * 1024; // for memory stream
 DefaultBLOBBlockSize: Integer = 100 * 1024; // for BLOB stream
 BlockSizeForFastest: Integer = 512 * 1024; // 0.5 Mb for fastest modes
 BlockSizeForNormal: Integer = 1024 * 1024; // 1.0 Mb for normal modes
 BlockSizeForMax: Integer = 1536 * 1024; // 1.5 Mb for max modes

const

 PPM_MO: array [1..9] of Byte = (2,3,4, 5, 7, 8,10, 13, 16); // Model Order
 PPM_SA: array [1..9] of Byte = (2,3,7,16,30,30,45,100,100); // MBytes RAM

type
 // Events
 TSQLMemProgressEvent = procedure(
                                    Sender:       TObject;
                                    PercentDone:  Double;
                                    var Abort:    Boolean
                             		) of object;


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemStream
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemStream = class (TStream)
  private
    FThreadSync:        TSQLMemReadWriteThreadSync;
    FBlockSize:         Integer;
    FOnProgress:        TSQLMemProgressEvent; // progress for bulk operations
    FModified:          Boolean;
    FAbort:             Boolean;
   protected
    // on progress
    procedure DoOnProgress(Progress: Double);
   public
    // lock
    procedure Lock{(WriteMode: Boolean = true)}; virtual;
    // unlock
    procedure Unlock; virtual;
    constructor Create;
    destructor Destroy; override;
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromStreamWithPosition(
                    Stream:       TStream;
                    FromPosition: Int64;
                    StreamSize:   Int64
                    );
    procedure LoadFromStream(Stream: TStream);
    procedure LoadFromFile(const FileName: AnsiString);
    procedure SaveToFile(const FileName: AnsiString);
    procedure Reset;
   public
    property BlockSize: Integer read FBlockSize write FBlockSize;
    // Progress Event
    property OnProgress: TSQLMemProgressEvent read FOnProgress write FOnProgress;
    property Modified: Boolean read FModified write FModified;
  end; // TSQLMemStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryStream
//
////////////////////////////////////////////////////////////////////////////////


  // class optimized for fast increasing the size of the data
  TSQLMemMemoryStream = class (TSQLMemStream)
   private
    FBuffer:            PAnsiChar;
    FPosition:          Int64;
    FSize:              Int64;   // size of the stream content
    FBufferSize:        Int64;   // actual size of the allocated buffer
    // set Size to 0 resets all realloc settings to default
    FFastReallocCount:  Integer; // number of optimized Realloc
                                 // before last real Realloc call
    FReallocDelta:      Int64;   // size in bytes of last real Realloc call
    FDeltaSet:          Boolean; // if true SetApproximateSize was called
   protected
    // return maximum value of FReallocDelta
    function GetMaxDelta: Int64;
    // sets new realloc delta with range check
    procedure SetReallocDelta(const NewDelta: Int64);
    // sets new size of the stream
    procedure InternalSetSize(const NewSize: Int64);
    // seek
    function InternalSeek(NewPosition: Int64): Int64;
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
    // added in 4.98 for direct setting of the buffer
    procedure SetBuffer(aBuffer: PAnsiChar; aBufferSize: Integer);
    // added in 4.98 for pre-allocating buffer for saving data
    procedure SetApproximateSize(NewSize: Integer);
   public
    property Buffer: PAnsiChar read FBuffer{ write FBuffer};
    property BufferSize: Int64 read FBufferSize{ write FBufferSize};
    property StreamSize: Int64 read FSize{ write FSize};
    property ReallocDelta: Int64 read FReallocDelta{ write SetReallocDelta};
    property FastReallocCount: Integer read FFastReallocCount{ write FFastReallocCount};
  end; // TSQLMemMemoryStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemFileStream
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemFileStream = class (TSQLMemStream)
   private
    FHandle:          Integer;
    FFileName:        AnsiString;
    FUnicodeFileName: WideString;
    FMode:            Word;
    FAttrFlags:       DWORD;
   protected
    procedure ConvertFileModes(
                                        const Mode:     Word;
                                        out AccessMode: Cardinal;
                                        out ShareMode:  Cardinal;
                                        out CreateMode: Cardinal
                                       );
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
    constructor Create(const FileName: AnsiString; Mode: Word); overload;
{$IFDEF D6H}
    constructor Create(const FileName: WideString; Mode: Word); overload;
{$ELSE}
    constructor Create(const FileName: WideString; Mode: Word; Dummy: ByteBool); overload;
{$ENDIF}
    destructor Destroy; override;
    // fills the entire file with zero bytes
    procedure ZeroFill;
   public
    property Handle: Integer read FHandle;
    property FileName: AnsiString read FFileName;
    property UnicodeFileName: WideString read FUnicodeFileName;
    property Mode: Word read FMode;
  end; // TSQLMemFileStream


  TSQLMemTempFileStream = class (TSQLMemStream)
   private
    FFileStream:        TSQLMemFileStream;
    FCachedBlock:       PAnsiChar;
    FCachedBlockNo:     Int64;
    FCachedBytes:       Int64;
    FPosition:          Int64;
    FSize:              Int64;
    FWriteCacheBlockNo: Int64; // -1 if no blocks in write cache
{$IFNDEF SQLMEMTABLE}
    FCryptoInfo:      TSQLMemCryptoInfo;
    FTempBlock:       PAnsiChar;
{$ENDIF}
   protected
    procedure LoadBlock(BlockNo: Int64);
    procedure SaveBlock(BlockNo: Int64);
    procedure ClearCache;
    procedure WriteCachedBlock;
    procedure ExtendEncryptedStream(NewSize: Int64);
    procedure ShrinkEncryptedStream(NewSize: Int64);

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
   public
    constructor Create(Source: TSQLMemStream);
    destructor Destroy; override;
  end; // TSQLMemTempFileStream

////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryStream
//
////////////////////////////////////////////////////////////////////////////////


  TSQLMemTemporaryStream = class (TSQLMemStream)
   private
    FMemoryLimit:        Integer;
    FMemoryStream:       TSQLMemMemoryStream;
    FFileStream:         TSQLMemTempFileStream;
    FFileName:           WideString;
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
    property FileStream: TSQLMemTempFileStream read FFileStream;
    property MemoryStream: TSQLMemMemoryStream read FMemoryStream;
    property FileName: WideString read FFileName;
    property InMemory: Boolean read FInMemory;
    property MemoryLimit: Integer read FMemoryLimit write FMemoryLimit;
  end; // TSQLMemTemporaryStream


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCompressedBLOBStream
//
////////////////////////////////////////////////////////////////////////////////


  // SQLMemTable BLOB stream with optional compression
  // when compression algorithm <> acaNone Write allowed
  // only ot the end of stream
  TSQLMemCompressedBLOBStream = class (TSQLMemStream)
   private
    FRepair:                Boolean;
    FHeaders:               TSQLMemCompressedStreamBlockHeadersArray;
    FUncompressedSize:      Int64;
    FCompressedSize:        Int64;
    FStartPosition:         Int64;
    FCurrentHeader:         Integer;
    FPosition:              Int64;
    FCompressionMode:       TSQLMemCompressionMode;
    FCompressionAlgorithm:  TSQLMemCompressionAlgorithm;
    FCompressionRate:       Double;
    FCompressedStream:      TStream; // internal stream for storing compressed data
    FBLOBDescriptor:        TSQLMemBLOBDescriptor;
   private
    // returns block size for creating a compressed blob stream with specified compression level
    function InternalGetBlockSize(CompressionMode: Byte): Integer;
    // calculates rate
    procedure CalculateRate;
    // create
    procedure InternalCreate(ToCreate: Boolean);
    // load all headers
    procedure LoadHeaders;
    // prepares buffer for writing (compresses, fills header structure, calculates crc)
    procedure PrepareBufferForWriting(
                                      InBuf:        PAnsiChar;
                                      InSize:       Integer;
                                      var OutBuf:   PAnsiChar;
                                      var Header:   TSQLMemCompressedStreamBlockHeader
                                     );
    // load block from file, decompress it and checks crc
    procedure LoadBlock(
                        CurHeader:  Int64;
                        var OutBuf: PAnsiChar
                       );
    procedure InternalIncreaseSize(NewSize: Int64);
    procedure InternalDecreaseSize(NewSize: Int64);
    procedure InternalSetSize(NewSize: Int64);
    // internal seek
    function InternalSeek(NewPosition: Int64): Int64;
   protected
    // sets new size of the stream
    procedure SetSize(NewSize: Longint);
    {$IFDEF D6H}
      overload;
    {$ENDIF}
      override;
    {$IFDEF D6H}
    procedure SetSize(const NewSize: Int64); overload; override;
    {$ENDIF}
    // gets compressed size
    function GetCompressedSize: Int64;
    // returns compression rate (100.0 if there is no compression)
    function GetCompressionRate: Double;
   public
    // Create
    constructor Create(
						           Stream:                TStream;
                       BLOBDescriptor:        TSQLMemBLOBDescriptor;
                       ToCreate:              Boolean = false;
                       ToRepair:              Boolean = false
                      );
    // Destroy
    destructor Destroy; override;

    function Read(var Buffer; Count: Longint): Longint; override;
   private
    // write beyond EOF
    procedure InternalWriteBeyondEOF;
    // write block
    procedure InternalWriteBlock(InBuf: PAnsiChar; InSize: Integer);
    // write prepare
    procedure InternalWritePrepare(Count, Result: Integer);
   public
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint;
    {$IFDEF D6H}
     overload;
    {$ENDIF}
     override;
    {$IFDEF D6H}
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    {$ENDIF}

   public
    property CompressedStream: TStream read FCompressedStream;
    // compression rate
    property CompressionRate: Double read GetCompressionRate;
    // compression algorithm
    property CompressionAlgorithm: TSQLMemCompressionAlgorithm read FCompressionAlgorithm;
    // compression mode
    property CompressionMode: Byte read FCompressionMode;
    // compressed size
    property CompressedSize: Int64 read GetCompressedSize;
    property BLOBDescriptor: TSQLMemBLOBDescriptor read FBLOBDescriptor;
  end; // TSQLMemCompressedBLOBStream


 //------------------------------------------------------------------------------
 // compresses buffer
 // returns true if successful
 // outBuf - pointer to compressed data
 // outSize - size of compressed data
 //------------------------------------------------------------------------------
 function SQLMemInternalCompressBuffer(
                          CompressionAlgorithm:   TSQLMemCompressionAlgorithm;
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
 function SQLMemInternalDecompressBuffer(
                          CompressionAlgorithm:   TSQLMemCompressionAlgorithm;
                          InBuf:                  PAnsiChar;
                          InSize:                 Integer;
                          out OutBuf:             PAnsiChar;
                          var OutSize:            Integer
                          ): Boolean;

 function SQLMemGetDefaultTempDir: WideString;
 procedure GetDefaultTempFileName;
 function GetTempFileName: WideString;
 procedure SaveDataToStream(const Data; DataSize: Integer; Stream: TStream; ErrorCode: Integer);
 procedure LoadDataFromStream(var Data; DataSize: Integer; Stream: TStream; ErrorCode: Integer);
 procedure SaveAnsiStringToStream(const Value: AnsiString; Stream: TStream; ErrorCode: Integer);
 procedure LoadAnsiStringFromStream(var Value: AnsiString; Stream: TStream; ErrorCode: Integer);
 procedure SaveWideStringToStream(const Value: WideString; Stream: TStream; ErrorCode: Integer);
 procedure LoadWideStringFromStream(var Value: WideString; Stream: TStream; ErrorCode: Integer);
 procedure SaveBooleanToStream(const Value: boolean; Stream: TStream; ErrorCode: Integer);
 procedure LoadBooleanFromStream(var Value: Boolean; Stream: TStream; ErrorCode: Integer);
 procedure SaveCryptoParamsToStream(const CryptoParams: TSQLMemCryptoParams; Stream: TStream; ErrorCode: Integer; DoNotSaveKeyAndPassword: Boolean = false);
 procedure LoadCryptoParamsFromStream(var CryptoParams: TSQLMemCryptoParams; Stream: TStream; ErrorCode: Integer; DoNotSaveKeyAndPassword: Boolean = false);

 procedure SaveTStringListToStream(List: TStrings; Stream: TStream; ErrorCode: Integer);
 procedure LoadTStringListFromStream(List: TStrings; Stream: TStream; ErrorCode: Integer);
 procedure SaveTSQLMemWideStringListToStream(List: TSQLMemWideStringList; Stream: TStream; ErrorCode: Integer);
 procedure LoadTSQLMemWideStringListFromStream(List: TSQLMemWideStringList; Stream: TStream; ErrorCode: Integer);

 procedure SetStreamPosition(Stream: TStream; NewPosition: Int64; ErrorCode: Integer);

 function GetCompressionAlgorithm(Name: AnsiString): TSQLMemCompressionAlgorithm;
 function GetCompressionAlgorithmSQLName(CompressionAlgorithm: TSQLMemCompressionAlgorithm): AnsiString;
//------------------------------------------------------------------------------
// returns true if file exists
//------------------------------------------------------------------------------
 function SQLMemFileExistsAnsi(FileName: PAnsiChar): Boolean;
 function SQLMemFileExistsUnicode(FileName: PWideChar): Boolean;
 function SQLMemFileExists(FileNameA: PAnsiChar; FileNameW: PWideChar = nil): Boolean; overload;
 function SQLMemFileExists(FileNameA: AnsiString; FileNameW: WideString = ''): Boolean; overload;


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
// TSQLMemStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// on progress
//------------------------------------------------------------------------------
procedure TSQLMemStream.DoOnProgress(Progress: Double);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self,Progress,FAbort);
end; // on progress


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TSQLMemStream.Lock{(WriteMode: Boolean)};
begin
  FThreadSync.Lock(True);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TSQLMemStream.Unlock;
begin
  FThreadSync.Unlock;
end; // Unlock


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemStream.Create;
begin
 FThreadSync := TSQLMemReadWriteThreadSyncBySingleCriticalSection.Create;
 FBlockSize := DefaultMemoryBlockSize;
 FModified := False;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemStream.Destroy;
begin
  FThreadSync.Free;
  inherited Destroy;
end; // Destroy


//------------------------------------------------------------------------------
// save all data to another stream
//------------------------------------------------------------------------------
procedure TSQLMemStream.SaveToStream(Stream: TStream);
var OutBytes,OldPos,OldPos1,InSize:	Int64;
    OutSize:					              Integer;
    Buf:            	              PAnsiChar;
    FProgress:      	              Extended;
    FProgressMax:   	              Extended;
    ReadBytes,WriteBytes:           Integer;
    Pos:                            Int64;
begin
 if (FBlockSize = 0) then
  raise ESQLMemException.Create(10418,ErrorLZeroBlockSizeIsNotAllowed);
 OldPos := Position;
 OldPos1 := Stream.Position;
 Position := 0;
 OutBytes := 0;
 FAbort := False;
 DoOnProgress(0);
 InSize := Size;
 Buf := MemoryManager.GetMem(FBlockSize);
 try
   while ((not FAbort) and (OutBytes < InSize)) do
    begin
     if (InSize - OutBytes > FBlockSize) then
      OutSize := FBlockSize
     else
      OutSize := Size - OutBytes;

     Pos := Self.Position;
     ReadBytes := Self.Read(Buf^,OutSize);
     if (ReadBytes <> OutSize) then
      raise ESQLMemException.Create(10146,ErrorLCannotReadFromStream,
        [Pos,Self.Size,OutSize,ReadBytes]);

     Pos := Stream.Position;
     WriteBytes := Stream.Write(Buf^,OutSize);
     if (WriteBytes <> OutSize) then
      raise ESQLMemException.Create(10147,ErrorLCannotWriteToStream,
        [Pos,Stream.Size,OutSize,WriteBytes]);

     Inc(OutBytes,OutSize);
     FProgressMax := Size;
     FProgress := OutBytes;
     DoOnProgress(FProgress/FProgressMax*100.0);
    end;
 finally
   MemoryManager.FreeAndNilMem(Buf);
   Position := OldPos;
   Stream.Position := OldPos1;
 end;
 if (not FAbort) then
 DoOnProgress(100.0);
end; // SaveToStream


//------------------------------------------------------------------------------
// load all data from another stream
//------------------------------------------------------------------------------
procedure TSQLMemStream.LoadFromStream(Stream: TStream);
begin
 LoadFromStreamWithPosition(Stream,0,Stream.Size);
end; // LoadFromStream


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TSQLMemStream.LoadFromStreamWithPosition(
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
  raise ESQLMemException.Create(10419,ErrorLZeroBlockSizeIsNotAllowed);
 OldPos := Position;
 OldPos1 := Stream.Position;
 Stream.Position := FromPosition;
 Size := 0;
 Position := 0;
 FAbort := False;
 DoOnProgress(0);
 Buf := MemoryManager.GetMem(FBlockSize);
 try
   while ((not FAbort) and (Stream.Position < FromPosition + StreamSize)) do
    begin
     if ((FromPosition + StreamSize) - Stream.Position > FBlockSize) then
      OutSize := FBlockSize
     else
      OutSize := (FromPosition + StreamSize) - Stream.Position;

     Pos := Stream.Position;
     ReadBytes := Stream.Read(Buf^,OutSize);
     if (ReadBytes <> OutSize) then
      raise ESQLMemException.Create(10148,ErrorLCannotReadFromStream,
        [Pos,Stream.Size,OutSize,ReadBytes]);

     Pos := Self.Position;
     WriteBytes := Self.Write(Buf^,OutSize);
     if (WriteBytes <> OutSize) then
      raise ESQLMemException.Create(10149,ErrorLCannotWriteToStream,
        [Pos,Self.Size,OutSize,WriteBytes]);

     FProgressMax := Stream.Size;
     FProgress := Stream.Position;
     DoOnProgress(FProgress/FProgressMax*100.0);
    end;
 finally
   MemoryManager.FreeAndNilMem(Buf);
   Position := OldPos;
   Stream.Position := OldPos1;
 end;
 if (not FAbort) then
  DoOnProgress(100.0);
end; // LoadFromStreamWithPosition


//------------------------------------------------------------------------------
// load all data from file
//------------------------------------------------------------------------------
procedure TSQLMemStream.LoadFromFile(const FileName: AnsiString);
var
  Stream: TSQLMemStream;
begin
  Stream := TSQLMemFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end; // LoadFromFile


//------------------------------------------------------------------------------
// save all data to file
//------------------------------------------------------------------------------
procedure TSQLMemStream.SaveToFile(const FileName: AnsiString);
var
  Stream: TSQLMemStream;
begin
  Stream := TSQLMemFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end; // SaveToFile


//------------------------------------------------------------------------------
// reset data and stream pointer
//------------------------------------------------------------------------------
procedure TSQLMemStream.Reset;
begin
  Size := 0;
  Position := 0;
end; // Reset


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemMemoryStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return maximum value of FReallocDelta
//------------------------------------------------------------------------------
function TSQLMemMemoryStream.GetMaxDelta: Int64;
begin
  if (FBufferSize <= 0) then
   Result := 4
  else
  if (FBufferSize = 4) then
   Result := 1020
  else
   Result := SQLMemGetReallocDelta(FBufferSize);
end; // GetMaxDelta


//------------------------------------------------------------------------------
// sets new realloc delta with range check
//------------------------------------------------------------------------------
procedure TSQLMemMemoryStream.SetReallocDelta(const NewDelta: Int64);
var MaxDelta: Int64;
begin
  if (NewDelta <= 0) then
   FReallocDelta := 0
  else
   begin
    MaxDelta := GetMaxDelta;
    if (NewDelta > MaxDelta) then
     FReallocDelta := MaxDelta
    else
     FReallocDelta := NewDelta;
   end;
end; // NewDelta


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemMemoryStream.InternalSetSize(const NewSize: Int64);
var MaxDelta, Delta: Int64;
    m:               Byte;
begin
//aaWriteToLog(IntToStr(FBufferSize)+#9+IntToStr(FReallocDelta)+#9+IntToStr(FFastReallocCount)+#9+IntToStr(NewSize-FSize));
 if (NewSize <> FSize) then
  begin
   if (NewSize <= 0) then
    begin
     if (FBuffer <> nil) then
      begin
       if (SQLMem_ENCRYPTED_DB_USED) then
        FillChar(FBuffer^,FBufferSize,$00);
       MemoryManager.FreeAndNilMem(FBuffer);
      end;
     // reset all parameters
     FBufferSize := 0;
     FSize := 0;
     FFastReallocCount := 0;
     if (not FDeltaSet) then
       FReallocDelta := 0;
    end
   else
   if (FBufferSize = 0) then
    begin
     if (not FDeltaSet) then
      begin
       if (NewSize <= 1024) then
        FBufferSize := 1024
       else
        FBufferSize := NewSize;
      end
     else
      FBufferSize := FReallocDelta;
     FBuffer := MemoryManager.GetMem(FBufferSize);
     FSize := NewSize;
     FFastReallocCount := 0;
    end
   else
    begin
     if (not FDeltaSet) then
      MaxDelta := GetMaxDelta
     else
      MaxDelta := FReallocDelta;
     if (NewSize < FSize) then
      begin
       // shrink data
       if (FBufferSize - NewSize >= MaxDelta) then
        begin
          FBufferSize := NewSize;
          FFastReallocCount := 0;
          MemoryManager.ReallocMem(FBuffer,FBufferSize);
        end;
      end
     else
      begin
       // extend data
       if (NewSize <= FBufferSize) then
        begin
         // buffer is larger then needed - do not reallocate
         Inc(FFastReallocCount);
        end
       else
        begin
         // buffer is smaller then needed - must be reallocated
         Delta := NewSize - FBufferSize;
         FReallocDelta := MaxDelta;
         if (FReallocDelta < Delta) then
          FReallocDelta := Delta;
         FFastReallocCount := 0;
         FBufferSize := FBufferSize + FReallocDelta;
         m := FBufferSize mod 4;
         if (m > 0) then
          begin
           m := 4-m;
           Inc(FReallocDelta,m);
           Inc(FBufferSize,m);
          end;
         MemoryManager.ReallocMem(FBuffer,FBufferSize);
        end;
      end;
     FSize := NewSize;
    end;
   if (FPosition > FSize) then
    FPosition := FSize;
  end; // NewSize <> Size
end; // InternalSetSize


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TSQLMemMemoryStream.InternalSeek(NewPosition: Int64): Int64;
begin
 FPosition := NewPosition;
 result := FPosition;
end; // InternalSeek


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemMemoryStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemMemoryStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TSQLMemMemoryStream.Read(var Buffer; Count: Longint): Longint;
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
function TSQLMemMemoryStream.Write(const Buffer; Count: Longint): Longint;
begin
 if (FSize < FPosition + Int64(Count)) then
  InternalSetSize(FPosition + Count);
 Result := Count;
//if (FDeltaSet) then aaStartTime(time16);
 System.Move(Buffer,PAnsiChar(FBuffer + FPosition)^,Count);
//if (FDeltaSet) then aaStopTime(time16);
 Inc(FPosition,Count);
end; // Write


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TSQLMemMemoryStream.Seek(Offset: Longint; Origin: Word): Longint;
var NewPosition: Integer;
begin
 NewPosition := FPosition;
 case (Origin) of
  soFromBeginning:
    NewPosition := Offset;
  soFromCurrent:
    NewPosition := FPosition + Offset;
  soFromEnd:
    NewPosition := FSize + Offset;
 end;
 Result := InternalSeek(NewPosition);
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TSQLMemMemoryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
var NewPosition: Int64;
begin
 NewPosition := 0;
 case (Origin) of
  soBeginning:
    NewPosition := Offset;
  soCurrent:
    NewPosition := FPosition + Offset;
  soEnd:
    NewPosition := FSize + Offset;
 end;
 Result := InternalSeek(NewPosition);
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
constructor TSQLMemMemoryStream.Create(Buffer: PAnsiChar = nil; BufferSize: Integer = -1);
begin
 FBuffer := nil;
 FBufferSize := 0;
 FSize := 0;
 FReallocDelta := 0;
 FFastReallocCount := 0;
 if (Buffer <> nil) then
  begin
   FBuffer := Buffer;
   if BufferSize >= 0 then
     FBufferSize := BufferSize
   else
     FBufferSize := MemoryManager.GetMemoryBufferSize(Buffer);
   FSize := FBufferSize;
  end;
 FPosition := 0;
 FDeltaSet := False;
 inherited Create;
end; // Create


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
destructor TSQLMemMemoryStream.Destroy;
begin
  InternalSetSize(0);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// set new buffer from external source
// existing buffer already free
//------------------------------------------------------------------------------
procedure TSQLMemMemoryStream.SetBuffer(aBuffer: PAnsiChar; aBufferSize: Integer);
begin
  FPosition := 0;
  FSize := aBufferSize;
  FBufferSize := aBufferSize;
  if (not FDeltaSet) then
    FReallocDelta := 0;
  FFastReallocCount := 0;
  FBuffer := aBuffer;
end; // SetBuffer


//------------------------------------------------------------------------------
// added in 4.98 for pre-allocating buffer for saving data
//------------------------------------------------------------------------------
procedure TSQLMemMemoryStream.SetApproximateSize(NewSize: Integer);
begin
 if ((NewSize > FSize) and (NewSize > FBufferSize)) then
  begin
    FDeltaSet := True;
    FReallocDelta := NewSize;
    if (FReallocDelta <= 0) then
     FReallocDelta := NewSize;
  end;
end; // SetApproximateSize




////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemFileStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// convert open file mode to access mode and share mode
//------------------------------------------------------------------------------
procedure TSQLMemFileStream.ConvertFileModes(
                                    const Mode:     Word;
                                    out AccessMode: Cardinal;
                                    out ShareMode:  Cardinal;
                                    out CreateMode: Cardinal
                                   );
begin
  // access mode
  if ((Mode = fmCreate) or ((fmOpenReadWrite and Mode) <> 0)) then
   AccessMode := GENERIC_READ or GENERIC_WRITE
  else
  if ((Mode and fmOpenWrite) <> 0) then
   AccessMode := GENERIC_WRITE
  else
   AccessMode := GENERIC_READ;
  // share mode
  if ((Mode and fmShareExclusive) <> 0) then
   ShareMode := 0
  else
  if ((Mode and fmShareDenyWrite) <> 0) then
   ShareMode := FILE_SHARE_READ
  else
   ShareMode := FILE_SHARE_READ	or FILE_SHARE_WRITE;
  // create mode
  if (Mode = fmCreate) then
    CreateMode := CREATE_ALWAYS
  else
    CreateMode := OPEN_EXISTING;
end; // ConvertFileModes


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemFileStream.InternalSetSize(const NewSize: Int64);
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
     raise ESQLMemException.Create(40019, ErrorRCannotSetNewSize,
            [FHandle, Size, NewSize, SysErrorCode, SysErrorMessage(SysErrorCode)]);
   end;
 if ftruncate(FHandle, Position) = -1 then
   begin
     SysErrorCode := GetLastError;
     raise ESQLMemException.Create(40019, ErrorRCannotSetNewSize,
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
procedure TSQLMemFileStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemFileStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// read
//------------------------------------------------------------------------------
function TSQLMemFileStream.Read(var Buffer; Count: Longint): Longint;
begin
 Result := FileRead(FHandle, Buffer, Count);
 if (Result = -1) then
  Result := 0;
end; // SetSize


//------------------------------------------------------------------------------
// write
//------------------------------------------------------------------------------
function TSQLMemFileStream.Write(const Buffer; Count: Longint): Longint;
begin
 Result := FileWrite(FHandle, Buffer, Count);
 if (Result = -1) then
  Result := 0;
end; // SetSize


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TSQLMemFileStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 Result := FileSeek(FHandle, Offset, Origin);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TSQLMemFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 Result := FileSeek(FHandle, Offset, Ord(Origin));
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemFileStream.Create(const FileName: AnsiString; Mode: Word);
begin
 inherited Create;
 FBlockSize := DefaultFileBlockSize;
 FMode := Mode;
 FFileName := FileName;
 FUnicodeFileName := '';
 if (Mode = fmCreate) then
  begin
   FHandle := FileCreate(FileName);
   if (FHandle < 0) then
    raise ESQLMemException.Create(10104,ErrorLCannotCreateFile,[FileName]);
  end
 else
  begin
   FHandle := FileOpen(FileName,Mode);
   if (FHandle < 0) then
    raise ESQLMemException.Create(10105,ErrorLCannotOpenFile,[FileName,Mode]);
  end;
end; // Create


{$IFDEF D6H}
constructor TSQLMemFileStream.Create(const FileName: WideString; Mode: Word);
var ShareMode, AccessMode, CreateMode: Cardinal;
begin
 inherited Create;
 FBlockSize := DefaultFileBlockSize;
 FMode := Mode;
 FFileName := '';
 FUnicodeFileName := FileName;
 ConvertFileModes(Mode,AccessMode,ShareMode,CreateMode);
 FHandle := Integer(Windows.CreateFileW(
                                PWideChar(@FileName[1]),
                                AccessMode,
                                ShareMode,
                                nil,
                                CreateMode,
                                FAttrFlags,
                                0
                             ));

 if (FHandle = Integer(INVALID_HANDLE_VALUE)) then
  begin
   if (Mode = fmCreate) then
    raise ESQLMemException.Create(10104,ErrorLCannotCreateFile,[FileName])
   else
    raise ESQLMemException.Create(10105,ErrorLCannotOpenFile,[FileName,Mode]);
  end;
end; // Create
{$ELSE}
constructor TSQLMemFileStream.Create(const FileName: WideString; Mode: Word; Dummy: ByteBool);
var ShareMode, AccessMode, CreateMode: Cardinal;
begin
 inherited Create;
 FBlockSize := DefaultFileBlockSize;
 FMode := Mode;
 FFileName := '';
 FUnicodeFileName := FileName;
 ConvertFileModes(Mode,AccessMode,ShareMode,CreateMode);
 FHandle := Integer(Windows.CreateFileW(
                                PWideChar(@FileName[1]),
                                AccessMode,
                                ShareMode,
                                nil,
                                CreateMode,
                                FAttrFlags,
                                0
                             ));

 if (FHandle = Integer(INVALID_HANDLE_VALUE)) then
  begin
   if (Mode = fmCreate) then
    raise ESQLMemException.Create(10104,ErrorLCannotCreateFile,[FileName])
   else
    raise ESQLMemException.Create(10105,ErrorLCannotOpenFile,[FileName,Mode]);
  end;
end; // Create
{$ENDIF}


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemFileStream.Destroy;
begin
 if FHandle >= 0 then
  FileClose(FHandle);
 inherited;
end; // Destroy


//------------------------------------------------------------------------------
// fills the entire file with zero bytes
//------------------------------------------------------------------------------
procedure TSQLMemFileStream.ZeroFill;
const BufSize = 4096;
var sz,pos: Int64;
    buf:    PAnsiChar;
    n:      Integer;
begin
   buf := MemoryManager.AllocMem(BufSize);
   try
     sz := Size;
     pos := 0;
     Position := 0;
     while pos < sz do
      begin
       if (pos + BufSize < sz) then
        n := BufSize
       else
        n := sz - pos;
       Write(buf^,n);
       Inc(pos,n);
      end;
   finally
     MemoryManager.FreeAndNilMem(buf);
   end;
end; // ZeroFill


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTempFileStream
//
////////////////////////////////////////////////////////////////////////////////


{

   if (SQLMem_ENCRYPTED_DB_USED and (Count > 0)) then
    begin
     buf := MemoryManager.GetMem(Count);
     try
       Move(Buffer,buf^,Count);
       SQLMemEncryptBuffer(FCryptoInfo,buf,Count);
       Result := Stream.Write(Buf^,Count);
     finally
       MemoryManager.FreeAndNilMem(buf);
     end;
    end
   else
    Result := Stream.Write(Buffer,Count);

}

//------------------------------------------------------------------------------
// load block to cache
//------------------------------------------------------------------------------
procedure TSQLMemTempFileStream.LoadBlock(BlockNo: Int64);
var BytesRead, Count: Int64;
begin
 FFileStream.Position := BlockNo * FBlockSize;
 // empty block
 if (FSize < FFileStream.Position + 1) then
  begin
   ClearCache;
   FCachedBytes := 0;
  end
 else
  begin
   if (FFileStream.Position + FBlockSize > FSize) then
     Count := FSize - FFileStream.Position
   else
     Count := FBlockSize;
   BytesRead := FFileStream.Read(FCachedBlock^,Count);
   if (BytesRead <> Count) then
    raise ESQLMemException.Create(11697,ErrorLCannotReadFromStream,
      [FPosition,FSize,FBlockSize,BytesRead]);
   FCachedBytes := Count;
   {$IFNDEF SQLMEMTABLE}
   if (SQLMem_ENCRYPTED_DB_USED) then
    SQLMemDecryptBuffer(FCryptoInfo,FCachedBlock,Count);
   {$ENDIF}
  end;
 FCachedBlockNo := BlockNo;
end; // LoadBlock


//------------------------------------------------------------------------------
// save cached block to file
//------------------------------------------------------------------------------
procedure TSQLMemTempFileStream.SaveBlock(BlockNo: Int64);
var BytesWrite, Count: Int64;
begin
 Count := FCachedBytes;
 FFileStream.Position := BlockNo * FBlockSize;
 if (Count > 0) then
  begin
   {$IFNDEF SQLMEMTABLE}
   if (SQLMem_ENCRYPTED_DB_USED) then
    begin
      Move(FCachedBlock^,FTempBlock^,Count);
      SQLMemEncryptBuffer(FCryptoInfo,FTempBlock,Count);
    end;
   if (SQLMem_ENCRYPTED_DB_USED) then
     BytesWrite := FFileStream.Write(FTempBlock^,Count)
   else
     BytesWrite := FFileStream.Write(FCachedBlock^,Count);
   {$ELSE}
     BytesWrite := FFileStream.Write(FCachedBlock^,Count);
   {$ENDIF}
   if (BytesWrite <> Count) then
    raise ESQLMemException.Create(11698,ErrorLCannotWriteToStream,
      [FPosition,FSize,FBlockSize,BytesWrite]);
  end;
end; // SaveBlock


//------------------------------------------------------------------------------
// clear cache
//------------------------------------------------------------------------------
procedure TSQLMemTempFileStream.ClearCache;
begin
  FCachedBlockNo := -1;
  FillChar(FCachedBlock^,FBlockSize,$00);
end; // ClearCache


//------------------------------------------------------------------------------
// write cached block to file stream
//------------------------------------------------------------------------------
procedure TSQLMemTempFileStream.WriteCachedBlock;
begin
 if (FWriteCacheBlockNo >= 0) then
  begin
   SaveBlock(FWriteCacheBlockNo);
   FWriteCacheBlockNo := -1;
  end;
end; // WriteCachedBlock


//------------------------------------------------------------------------------
// extend encrypted stream (fill the added data with $00 bytes)
//------------------------------------------------------------------------------
procedure TSQLMemTempFileStream.ExtendEncryptedStream(NewSize: Int64);
var FirstBlock, LastBlock, BlockNo, LastPos: Int64;
begin
  FirstBlock := FSize div FBlockSize;
  LastBlock := NewSize div FBlockSize;
  LastPos := LastBlock * FBlockSize;
  if (NewSize > LastPos) then
   Inc(LastBlock);
  if (FCachedBlockNo <> FirstBlock) then
    LoadBlock(FirstBlock);
  BlockNo := FirstBlock;
  while (BlockNo < LastBlock) do
   begin
    FCachedBytes := FBlockSize;
    SaveBlock(BlockNo);
    Inc(BlockNo);
   end;
  FWriteCacheBlockNo := LastBlock;
  FCachedBytes := NewSize - LastPos;
  FSize := NewSize;
end; // ExtendEncryptedStream


//------------------------------------------------------------------------------
// shrink encrypted stream
//------------------------------------------------------------------------------
procedure TSQLMemTempFileStream.ShrinkEncryptedStream(NewSize: Int64);
var LastBlock, LastPos: Int64;
begin
  LastBlock := NewSize div FBlockSize;
  LastPos := LastBlock * FBlockSize;
  if (NewSize > LastPos) then
   begin
    if (FCachedBlockNo <> LastBlock) then
     LoadBlock(LastBlock);
    FCachedBytes := NewSize - LastPos;
    SaveBlock(LastBlock);
   end;
  FFileStream.Size := NewSize;
  FSize := NewSize;
end; // ShrinkEncryptedStream


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemTempFileStream.InternalSetSize(const NewSize: Int64);
begin
 WriteCachedBlock;
 if (NewSize <> FSize) then
  begin
   if (SQLMem_ENCRYPTED_DB_USED) then
    begin
     if (NewSize > FSize) then
      ExtendEncryptedStream(NewSize)
     else
      ShrinkEncryptedStream(NewSize);
    end
   else
    begin
     FFileStream.InternalSetSize(NewSize);
     FSize := FFileStream.Size;
    end;
  end;
end; // InternalSetSize


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemTempFileStream.SetSize(NewSize: Longint);
begin
  InternalSetSize(Int64(NewSize));
end; // SetSize


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
{$IFDEF D6H}
procedure TSQLMemTempFileStream.SetSize(const NewSize: Int64);
begin
  InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}

//------------------------------------------------------------------------------
// Read
//------------------------------------------------------------------------------
function TSQLMemTempFileStream.Read(var Buffer; Count: Longint): Longint;
var BlockNo, EndPos, BytesRead: Int64;
    Offset, BytesCount:         Integer;
begin
  Result := 0;
  WriteCachedBlock;
  // nothing to read
  if (FPosition >= FSize) then
   Exit;
  BlockNo := FPosition div FBlockSize;
  EndPos := FPosition + Count;
  while ((Result < Count) and (FPosition < FSize)) do
   begin
    if (Result = 0) then
      Offset := (FPosition - BlockNo * FBlockSize)
    else
      Offset := 0;
    if ((EndPos-FPosition) > (FBlockSize-Offset)) then
      BytesCount := FBlockSize - Offset
    else
      BytesCount := EndPos - FPosition;
    if (FCachedBlockNo <> BlockNo) then
     try
      LoadBlock(BlockNo);
     except
      Result := 0;
      Exit;
     end;
    try
      Move(PAnsiChar(FCachedBlock + Offset)^,
           PAnsiChar(PAnsiChar(@Buffer)+Result)^,BytesCount);
    except
      Exit;
    end;
    Inc(Result,BytesCount);
    Inc(FPosition,BytesCount);
    Inc(BlockNo);
   end;
end; // Read


//------------------------------------------------------------------------------
// Write
//------------------------------------------------------------------------------
function TSQLMemTempFileStream.Write(const Buffer; Count: Longint): Longint;
var StartBlockNo, EndBlockNo, BlockNo, StartPos, EndPos, BytesRead: Int64;
    Offset, BytesCount:         Integer;
begin
 Result := 0;
 try
    WriteCachedBlock;
    StartPos := FPosition;
    StartBlockNo := StartPos div FBlockSize;
    // check to extend the file, as current position is beyond EOF
    EndPos := FPosition + Count;
    EndBlockNo := EndPos div FBlockSize;
    if (EndPos < FSize) then
     InternalSetSize(EndPos);
    BlockNo := StartBlockNo;
    while (Result < Count) do
     begin
      if (Result = 0) then
        Offset := (FPosition - BlockNo * FBlockSize)
      else
        Offset := 0;
      if ((EndPos-FPosition) > (FBlockSize-Offset)) then
        BytesCount := FBlockSize - Offset
      else
        BytesCount := EndPos - FPosition;
      if (((BlockNo = StartBlockNo) or (BlockNo = EndBlockNo))
          and
          (FCachedBlockNo <> BlockNo)) then
       begin
         try
          LoadBlock(BlockNo);
         except
          Result := 0;
          Exit;
         end;
       end
      else
        FCachedBytes := 0;
      if (BytesCount <= 0) then
        Exit;
      try
        Move(PAnsiChar(PAnsiChar(@Buffer)+Result)^,
             PAnsiChar(FCachedBlock + Offset)^,BytesCount);
        if (FCachedBytes < BytesCount) then
         FCachedBytes := BytesCount;
        if (BlockNo < EndBlockNo) then
          SaveBlock(BlockNo);
      except
        Exit;
      end;
      Inc(Result,BytesCount);
      Inc(FPosition,BytesCount);
      Inc(BlockNo);
     end;
 finally
   if (Result = Count) then
    begin
     if (FSize < EndPos) then
      FSize := EndPos;
     FWriteCacheBlockNo := EndBlockNo;
    end;
 end;
end; // Write


//------------------------------------------------------------------------------
// Seek
//------------------------------------------------------------------------------
function TSQLMemTempFileStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 case (Origin) of
  soFromBeginning:
    FPosition := Offset;
  soFromCurrent:
    FPosition := FPosition + Int64(Offset);
  soFromEnd:
    FPosition := FSize + Int64(Offset);
 end;
 Result := FPosition;
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// Seek
//------------------------------------------------------------------------------
function TSQLMemTempFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 case (Origin) of
  soBeginning:
    FPosition := Offset;
  soCurrent:
    FPosition := FPosition + Offset;
  soEnd:
    FPosition := FSize + Offset;
 end;
 Result := FPosition;
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TSQLMemTempFileStream.Create(Source: TSQLMemStream);
begin
  FFileStream := TSQLMemFileStream.Create(GetTempFileName,fmCreate);
  FBlockSize := DefaultTemporaryBlockSize;
  FCachedBlock := MemoryManager.GetMem(FBlockSize);
  FCachedBlockNo := -1; // no block in the read cache
  FSize := 0;
  FCachedBytes := 0;
  FWriteCacheBlockNo := -1; // no block in the write cache
{$IFNDEF SQLMEMTABLE}
 if (SQLMem_ENCRYPTED_DB_USED) then
  begin
   FTempBlock := MemoryManager.GetMem(FBlockSize);
   // generate random key
   FCryptoInfo.KeyInfo.KeySize := SQLMem_MAX_KEY+1;
   SQLMemGenerateRandomBuffer(@FCryptoInfo.KeyInfo.Key[0],FCryptoInfo.KeyInfo.KeySize);
   FCryptoInfo.CryptoAlgorithm := SQLMem_Cipher_Blowfish;
   FCryptoInfo.CryptoMode := SQLMem_Cipher_Mode_CTS;
   FCryptoInfo.UseInitVector := false;
  end;
{$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TSQLMemTempFileStream.Destroy;
var FileName: WideString;
begin
  FileName := FFileStream.FFileName;
  FFileStream.Free;
  SysUtils.DeleteFile(FileName);
{$IFNDEF SQLMEMTABLE}
 if (SQLMem_ENCRYPTED_DB_USED) then
  begin
   MemoryManager.FreeAndNilMem(FTempBlock);
   FillChar(FCachedBlock^,FBlockSize,$00);
  end;
{$ENDIF}
  MemoryManager.FreeAndNilMem(FCachedBlock);
  inherited;
end; // Destroy


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemTemporaryStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryStream.InternalSetSize(const NewSize: Int64);
begin
 if (FInMemory) then
  begin
    if (NewSize <= FMemoryLimit) then
     FMemoryStream.Size := NewSize
    else
     begin
      FFileName := GetTempFileName;
      FFileStream := TSQLMemTempFileStream.Create(FMemoryStream);
      FMemoryStream.Free;
      FMemoryStream := nil;
      FInMemory := False;
      FFileStream.Size := NewSize;
     end
  end
 else
  FFileStream.Size := NewSize;
 if (Position > Size) then
  Position := Size;
end; // InternalSetSize


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TSQLMemTemporaryStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// read
//------------------------------------------------------------------------------
function TSQLMemTemporaryStream.Read(var Buffer; Count: Longint): Longint;
var Stream: TStream;
begin
 if (FInMemory) then
  Stream := FMemoryStream
 else
  Stream := FFileStream;
 Result := Stream.Read(Buffer,Count);
end; // Read


//------------------------------------------------------------------------------
// write
//------------------------------------------------------------------------------
function TSQLMemTemporaryStream.Write(const Buffer; Count: Longint): Longint;

var Stream:     TStream;
begin
 if (FInMemory) then
  Stream := FMemoryStream
 else
  Stream := FFileStream;
 Result := Stream.Write(Buffer,Count);
end; // Write


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TSQLMemTemporaryStream.Seek(Offset: Longint; Origin: Word): Longint;
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
function TSQLMemTemporaryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
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
constructor TSQLMemTemporaryStream.Create;
begin
 inherited Create;
 FBlockSize := DefaultTemporaryBlockSize;
 FMemoryLimit := DefaultTemporaryLimit;
 FFileName := '';
 FInMemory := True;
 FMemoryStream := TSQLMemMemoryStream.Create;
 FFileStream := nil;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemTemporaryStream.Destroy;
begin
 if (FMemoryStream <> nil) then
  FMemoryStream.Free;
 if (FFileStream <> nil) then
  FFileStream.Free;
 inherited;
end; // Destroy


////////////////////////////////////////////////////////////////////////////////
//
// TSQLMemCompressedBLOBStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// returns block size for creating a compressed blob stream with specified compression level
//------------------------------------------------------------------------------
function TSQLMemCompressedBLOBStream.InternalGetBlockSize(CompressionMode: Byte): Integer;
begin
 if (CompressionMode = 0) then
  Result := DefaultBLOBBlockSize
 else
 if (CompressionMode <= 3) then
  Result := BlockSizeForFastest
 else
 if (CompressionMode <= 6) then
  Result := BlockSizeForNormal
 else
  Result := BlockSizeForMax;
end; // InternalGetBlockSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.CalculateRate;
var i: 		Integer;
    f,f1:	Extended;
begin
 FCompressedSize := 0;
 if (FCompressionAlgorithm = acaNone) then
  begin
   FCompressedSize := FUncompressedSize;
   FCompressionRate := 0;
  end
 else
 if (FUncompressedSize <= 0) then
  begin
   FCompressedSize := FUncompressedSize;
   FCompressionRate := 0;
  end
 else
  begin
   for i := 0 to FHeaders.ItemCount-1 do
    Inc(FCompressedSize,FHeaders.Items[i].CompressedSize);
   f1 := FUncompressedSize;
   f := FCompressedSize;
   FCompressionRate := (1 - f / f1) * 100.0;
  end;
end; //CalculateRate


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.InternalCreate(ToCreate: Boolean);
begin
 // compression
 FHeaders := TSQLMemCompressedStreamBlockHeadersArray.Create;
 if (ToCreate) then
  begin
   if (FBLOBDescriptor.BlockSize = 0) then
    FBLOBDescriptor.BlockSize := InternalGetBlockSize(FCompressionMode);
   FBLOBDescriptor.NumBlocks := 0;
  end; // compression
 FBlockSize := FBLOBDescriptor.BlockSize;
 FUncompressedSize := 0;
 FCompressedSize := 0;
 LoadHeaders; // loading headers
 FCurrentHeader := 0;
 FPosition := 0;
end; // InternalCreate


//------------------------------------------------------------------------------
// load  block headers
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.LoadHeaders;
var CHeader:    TSQLMemCompressedStreamBlockHeader;
    Pos,NewPos: Int64;
    i,OldPos:   Int64;
begin
 FCompressedSize := 0;
 FUncompressedSize := 0;
 // always restore StartPosition as blob stream can be stored at the middle of the file
 if (FCompressedStream.Position <> FBLOBDescriptor.StartPosition) then
  raise ESQLMemException.Create(10080,ErrorLCannotSetPosition,
    [FBLOBDescriptor.StartPosition,FCompressedStream.Position,
     FCompressedStream.Size]);
 FHeaders.SetSize(0);

 i := 0;
 while (i < FBLOBDescriptor.NumBlocks) do
  begin
   // store position of the current block
   Pos := FCompressedStream.Position;
   // check if we can read block header from current position
   if (
       (FCompressedStream.Size - FCompressedStream.Position) <
       sizeof(TSQLMemCompressedStreamBlockHeader)
      ) then
    begin
     // stream too small
     if (FRepair) then
      begin
       // cut compressed file (end of file was cut)
       // repair this error
       FBLOBDescriptor.NumBlocks := i;
       FHeaders.SetSize(i);
       break;
      end
     else
      raise ESQLMemException.Create(10082,ErrorLStreamSizeTooSmall,
        [FCompressedStream.Size,
        FCompressedStream.Position + sizeof(TSQLMemCompressedStreamBlockHeader)]);
    end; // check if we can read block header from current position
   FCompressedStream.ReadBuffer(CHeader,sizeof(TSQLMemCompressedStreamBlockHeader));
   Inc(FUncompressedSize,CHeader.UncompressedSize);
   Inc(FCompressedSize,CHeader.CompressedSize);
   FHeaders.AppendItem(CHeader,Pos);
// Commented By Leo Martin - changed from absolute to relative offset
//   NewPos := CHeader.OffsetToNextHeader;
   NewPos := Pos + CHeader.OffsetToNextHeader;
   OldPos := FCompressedStream.Position;
   FCompressedStream.Position := NewPos;
   if (FCompressedStream.Position <> NewPos) then
    raise ESQLMemException.Create(10083,ErrorLCannotSetPosition,
      [NewPos,OldPos,FCompressedStream.Size]);
   Inc(i);
  end; //  while (i < FBLOBDescriptor.NumBlocks)
end; // LoadHeaders


//------------------------------------------------------------------------------
// prepare buffer for writing
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.PrepareBufferForWriting
                                     (
                                      InBuf:        PAnsiChar;
                                      InSize:       Integer;
                                      var OutBuf:   PAnsiChar;
                                      var Header:   TSQLMemCompressedStreamBlockHeader
                                     );
begin
  OutBuf := nil;
  Header.UncompressedSize := inSize;
  Header.Crc32 := SQLMem_CRC32(0,InBuf,InSize);
  if (not SQLMemInternalCompressBuffer(FCompressionAlgorithm,FCompressionMode,
          InBuf,InSize,OutBuf,Header.CompressedSize)) then
   begin
    if (OutBuf <> nil) then
     FreeMem(OutBuf);
    raise ESQLMemException.Create(10085,ErrorLCompressBufferFailed,
      [Byte(FCompressionAlgorithm),FCompressionMode,InSize,Header.CompressedSize]);
   end;
end; //PrepareBuffer;


//------------------------------------------------------------------------------
// load block from file, decompress it and checks crc
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.LoadBlock(
                                      CurHeader:  Int64;
                                      var OutBuf: PAnsiChar
                                            );

var UncompSize,CompSize:  Integer;
    BytesRead,CheckSum:   Cardinal;
    InBuf:                PAnsiChar;
begin
  CompSize := FHeaders.Items[curHeader].CompressedSize;
  InBuf := MemoryManager.GetMem(CompSize);
  try
   FCompressedStream.Position := FHeaders.Positions[CurHeader] +
    sizeof(TSQLMemCompressedStreamBlockHeader);

   BytesRead := FCompressedStream.Read(InBuf^,CompSize);
   if (BytesRead <> CompSize) then
    begin
     raise ESQLMemException.Create(10086,ErrorLCannotReadFromStream,
      [FHeaders.Positions[CurHeader] + sizeof(TSQLMemCompressedStreamBlockHeader),
      FCompressedStream.Size,CompSize,BytesRead]);
    end;

   UncompSize := FHeaders.Items[CurHeader].UncompressedSize;
   if (not SQLMemInternalDecompressBuffer(FCompressionalgorithm,
           InBuf,CompSize,OutBuf,UncompSize)) then
    begin
     // decompression error
     raise ESQLMemException.Create(10087,ErrorLDecompressBufferFailed,
      [Byte(FCompressionAlgorithm),CompSize,UncompSize]);
    end;
   if (FHeaders.Items[CurHeader].UncompressedSize <> UncompSize) then
    begin
     FreeMem(outBuf);
     OutBuf := nil;
     raise ESQLMemException.Create(10088,ErrorLDecompressBufferFailedInvalidSize,
      [UncompSize,FHeaders.Items[CurHeader].UncompressedSize]);
    end;
   // check crc
   CheckSum := SQLMem_CRC32(0,OutBuf,UncompSize);
   if (FHeaders.Items[CurHeader].Crc32 <> CheckSum) then
    begin
    // decompression crc error
     FreeMem(outBuf);
     OutBuf := nil;
     raise ESQLMemException.Create(10089,ErrorLDecompressBufferFailedInvalidCRC,
      [CheckSum,FHeaders.Items[CurHeader].Crc32]);
    end;
  finally
   MemoryManager.FreeAndNilMem(inBuf);
  end;
end; // LoadBlock


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.InternalIncreaseSize(NewSize: Int64);
var Buf:                  PAnsiChar;
    ExtensionSize,Count:  Int64;
    OldPos:               Int64;
    WriteBytes,WriteSize: Integer;
begin
 Position := FUncompressedSize;
 ExtensionSize := NewSize - FUncompressedSize;
 if (ExtensionSize <= 0) then
  raise ESQLMemException.Create(10098,ErrorLInvalidExtensionSize,
    [NewSize,FUncompressedSize,ExtensionSize]);
 Buf := MemoryManager.AllocMem(FBlockSize);
 try
  Count := 0;
  while (Count < ExtensionSize) do
   begin
    if ((ExtensionSize - Count) < FBlockSize) then
     WriteSize := ExtensionSize - Count
    else
     WriteSize := FBlockSize;
    OldPos := Self.Position;
    // write empty block
    WriteBytes := Self.Write(Buf^,WriteSize);
    if (WriteBytes <> WriteSize) then
      raise ESQLMemException.Create(10097,ErrorLCannotWriteToStream,
        [OldPos,Self.Size,WriteSize,WriteBytes]);
    Inc(Count,WriteSize);
   end; // while
 finally
  MemoryManager.FreeAndNilMem(Buf);
 end;
end; // InternalIncreaseSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.InternalDecreaseSize(NewSize: Int64);
var Buf,OutBuf:           PAnsiChar;
    ExtensionSize,OldPos: Int64;
    CurHdr,NumBlocks:     Int64;
    BytesWrite:           Integer;
begin
  CurHdr := NewSize div FBlockSize;
  NumBlocks := CurHdr;
  ExtensionSize := NewSize mod FBlockSize;
  OutBuf := nil;
  Buf := nil;
  try
    if (ExtensionSize > 0) then
     begin
      Inc(NumBlocks);
      LoadBlock(CurHdr,Buf);
      try
       PrepareBufferForWriting(Buf,ExtensionSize,OutBuf,FHeaders.Items[CurHdr]);
      finally
       if (Buf <> nil) then
        MemoryManager.FreeAndNilMem(Buf);
      end;
     end;
    FBLOBDescriptor.NumBlocks := NumBlocks;
    FHeaders.SetSize(NumBlocks);
    if (ExtensionSize > 0) then
     begin
      FCompressedStream.Size := FHeaders.Positions[CurHdr];
      if (FCompressedStream.Size <> FHeaders.Positions[CurHdr]) then
       raise ESQLMemException.Create(10093,ErrorLInvalidStreamSize,
        [FCompressedStream.Size,FHeaders.Positions[CurHdr]]);
      FCompressedStream.Position := FCompressedStream.Size;
      if (FCompressedStream.Position <> FCompressedStream.Size) then
       raise ESQLMemException.Create(10094,ErrorLCannotSetPosition,
        [FCompressedStream.Size,FCompressedStream.Position,
         FCompressedStream.Size]);
      FHeaders.Items[CurHdr].OffsetToNextHeader := FCompressedStream.Position +
        Int64(FHeaders.Items[CurHdr].CompressedSize) +
        sizeof(TSQLMemCompressedStreamBlockHeader);
      FHeaders.Positions[CurHdr] := FCompressedStream.Position;
      OldPos := FCompressedStream.Position;
      BytesWrite := FCompressedStream.Write(FHeaders.Items[curHdr],
          sizeof(TSQLMemCompressedStreamBlockHeader));
      if (BytesWrite <> sizeof(TSQLMemCompressedStreamBlockHeader)) then
       raise ESQLMemException.Create(10095,ErrorLWriteToStream,
        [OldPos,FCompressedStream.Size,sizeof(TSQLMemCompressedStreamBlockHeader),BytesWrite]);
      OldPos := FCompressedStream.Position;
      BytesWrite := FCompressedStream.Write(OutBuf^,FHeaders.Items[CurHdr].CompressedSize);
      if (BytesWrite <> sizeof(TSQLMemCompressedStreamBlockHeader)) then
       raise ESQLMemException.Create(10096,ErrorLWriteToStream,
        [OldPos,FCompressedStream.Size,sizeof(TSQLMemCompressedStreamBlockHeader),BytesWrite]);
     end;
  finally
   if (OutBuf <> nil) then
    MemoryManager.FreeAndNilMem(OutBuf);
  end;
end; // InternalDecreaseSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.InternalSetSize(NewSize: Int64);
begin
 if (FCompressionAlgorithm = acaNone) then
  begin
   FCompressedStream.Size := FStartPosition + NewSize;
  end
 else
 if (NewSize > FUncompressedSize) then
  begin
    // go to last block
    InternalIncreaseSize(NewSize);
  end // NewSize > FUncompressedSize
 else
 if (NewSize < FUncompressedSize) then
  begin
    InternalDecreaseSize(NewSize);
  end; // NewSize < FUncompressedSize
 FUncompressedSize := NewSize;
 FBLOBDescriptor.UncompressedSize := NewSize;
 CalculateRate;
 if (FPosition > FUncompressedSize) then
  Position := FUncompressedSize;
end; // InternalSetSize


//------------------------------------------------------------------------------
// internal seek
//------------------------------------------------------------------------------
function TSQLMemCompressedBLOBStream.InternalSeek(NewPosition: Int64): Int64;
begin
 if (FCompressionAlgorithm = acaNone) then
  begin
   FCompressedStream.Position := FStartPosition + NewPosition;
   Result := FCompressedStream.Position - FStartPosition;
   FPosition := Result;
  end // no compression
 else
  begin
   // compression
   FPosition := NewPosition;
   if (FPosition <= 0) then
    begin
     FPosition := 0;
     FCurrentHeader := 0;
    end
   else
    begin
     if (FUncompressedSize = 0) then
      FCurrentHeader := 0
     else
      FCurrentHeader := FHeaders.FindPosition(FPosition);
    end;
   Result := FPosition;
  end; // compression
end; // InternalSeek


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
{$IFDEF D6H}
procedure TSQLMemCompressedBLOBStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// gets compressed size
//------------------------------------------------------------------------------
function TSQLMemCompressedBLOBStream.GetCompressedSize: Int64;
begin
 Result := FCompressedStream.Size;
end; // GetCompressedSize


//------------------------------------------------------------------------------
// returns compression rate (100.0 if there is no compression)
//------------------------------------------------------------------------------
function TSQLMemCompressedBLOBStream.GetCompressionRate: Double;
begin
 CalculateRate;
 Result := FCompressionRate;
end; // GetCompressionRate


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TSQLMemCompressedBLOBStream.Create(
						           Stream:                TStream;
                       BLOBDescriptor:        TSQLMemBLOBDescriptor;
                       ToCreate:              Boolean = false;
                       ToRepair:              Boolean = false
                      );
begin
 inherited Create;
 FCompressedStream := Stream;
 FHeaders := nil;
 FRepair := ToRepair;
 FBLOBDescriptor := BLOBDescriptor;
 FCompressionAlgorithm := TSQLMemCompressionAlgorithm(
    FBLOBDescriptor.CompressionAlgorithm);
 FCompressionMode := FBLOBDescriptor.CompressionMode;
 FCompressedStream.Position := FBLOBDescriptor.StartPosition;
 if (FCompressedStream.Position <> FBLOBDescriptor.StartPosition) then
  raise ESQLMemException.Create(10103,ErrorLCannotSetPosition,
    [FBLOBDescriptor.StartPosition,FCompressedStream.Position,
    FCompressedStream.Size]);
 FBlockSize := BLOBDescriptor.BlockSize;
 FStartPosition := BLOBDescriptor.StartPosition;
 if (FCompressionAlgorithm = acaNone) then
  begin
   // no compression
   // try to set start position in source "compressed" stream
   if (FCompressedStream.Position <> FBLOBDescriptor.StartPosition) then
    raise ESQLMemException.Create(10079,ErrorLCannotSetPosition,
      [FBLOBDescriptor.StartPosition,FCompressedStream.Position,
       FCompressedStream.Size]);
   // default block size
   if (ToCreate) then
    begin
     // create new stream
     FCompressedSize := 0;
     FUncompressedSize := 0;
    end
   else
    begin
     // open existing stream
     FUncompressedSize := FBLOBDescriptor.UncompressedSize;
     FCompressedSize := FUncompressedSize;
     // check if stream size is too small
     if (not FRepair) then
      if (FCompressedStream.Size - FCompressedStream.Position <
          FUncompressedSize) then
        raise ESQLMemException.Create(10081,ErrorLStreamSizeTooSmall,
          [FCompressedStream.Size,
          (FUncompressedSize + FCompressedStream.Position)]);

    end;
  end // no compression
 else
  // create compressed stream, load headers
  InternalCreate(ToCreate);
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TSQLMemCompressedBLOBStream.Destroy;
begin
 if (FHeaders <> nil) then
  FHeaders.Free;
 FHeaders := nil;
 inherited;
end; // Destroy


//------------------------------------------------------------------------------
// read from compressed stream
//------------------------------------------------------------------------------
function TSQLMemCompressedBLOBStream.Read(var Buffer; Count: Longint): Longint;
var ReadSize:   Int64;
    OutBuf:     PAnsiChar;
begin
 if (FCompressionAlgorithm = acaNone) then
  begin
   Result := FCompressedStream.Read(Buffer,Count);
   FPosition := FCompressedStream.Position - FStartPosition;
  end // no compression
 else
  begin
   Result := 0;
   if ((Count > 0) and (FPosition >= 0) and (FPosition < FUncompressedSize)) then
    begin
     FCurrentHeader := FPosition div FBlockSize;
     while ((FPosition < FUncompressedSize) and (Result < Count)) do
      begin
       LoadBlock(FCurrentHeader,OutBuf);
       // read from current position to the end of the block
       ReadSize := FBlockSize -
        ((FPosition + FBlockSize) mod FBlockSize);
       // if we Result + ReadSize exceeds Count read only Count - Result
       if (Result + ReadSize > Count) then
        ReadSize := Count - Result;
       // reading only till EOF
       if (FPosition + ReadSize >= FUncompressedSize) then
        ReadSize := FUncompressedSize - FPosition;
       if (ReadSize <= 0) then
        raise ESQLMemException.Create(10090,
          ErrorLCannotReadFromStreamInvalidReadSize,[ReadSize]);
       // move data from decompressed buffer to Buffer
       Move(PAnsiChar(OutBuf + ((FPosition + FBlockSize) mod FBlockSize))^,
        PAnsiChar(PAnsiChar(@Buffer) + Result)^,ReadSize);
       FreeMem(OutBuf);
       Inc(Result,ReadSize);
       if (Result < Count) then
        Inc(FCurrentHeader);
       Inc(FPosition,ReadSize);
      end; // reading loop
    end; // FPosition < FUncompressedSize
  end; // compression
end; // Read


//------------------------------------------------------------------------------
// write beyond EOF
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.InternalWriteBeyondEOF;
var OldPos: Int64;
begin
 OldPos := FPosition;
 Self.Position := 0;
 Self.SetSize(OldPos);
 Self.Position := OldPos;
 if (Self.Position <> OldPos) then
  raise ESQLMemException.Create(10091,ErrorLCannotSetPosition,
    [OldPos,FPosition,FUncompressedSize]);
 if (FUncompressedSize <> OldPos) then
  raise ESQLMemException.Create(10092,ErrorLInvalidStreamSize,
    [FUncompressedSize,OldPos]);
end; // InternalWriteBeyondEOF


//------------------------------------------------------------------------------
// write block
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.InternalWriteBlock(InBuf: PAnsiChar; InSize: Integer);
var OutBuf:         PAnsiChar;
    WriteBytes:     Integer;
    OldPos:         Int64;
begin
  PrepareBufferForWriting(InBuf,InSize,OutBuf,
    FHeaders.Items[FCurrentHeader]);
  try
// Commented By Leo Martin - changed from absolute to relative offset
    FHeaders.Items[FCurrentHeader].OffsetToNextHeader :=
//      FHeaders.Positions[FCurrentHeader] +
        sizeof(TSQLMemCompressedStreamBlockHeader) +
        FHeaders.Items[FCurrentHeader].CompressedSize;

    FCompressedStream.Position := FHeaders.Positions[FCurrentHeader];
    if (FCompressedStream.Position <> FHeaders.Positions[FCurrentHeader]) then
     raise ESQLMemException.Create(10099,ErrorLCannotSetPosition,
      [FHeaders.Positions[FCurrentHeader],
        FCompressedStream.Position,FCompressedStream.Size]);

    OldPos := FCompressedStream.Position;
    WriteBytes := FCompressedStream.Write(FHeaders.Items[FCurrentHeader],
      sizeof(TSQLMemCompressedStreamBlockHeader));
    if (WriteBytes <> sizeof(TSQLMemCompressedStreamBlockHeader)) then
     raise ESQLMemException.Create(10100,ErrorLCannotWriteToStream,
      [OldPos,FCompressedStream.Size,sizeof(TSQLMemCompressedStreamBlockHeader),WriteBytes]);

    OldPos := FCompressedStream.Position;
    WriteBytes := FCompressedStream.Write(OutBuf^,
      FHeaders.Items[FCurrentHeader].CompressedSize);
    if (WriteBytes <> FHeaders.Items[FCurrentHeader].CompressedSize) then
     raise ESQLMemException.Create(10101,ErrorLCannotWriteToStream,
      [OldPos,FCompressedStream.Size,FHeaders.Items[FCurrentHeader].CompressedSize,WriteBytes]);
  finally
   if (OutBuf <> nil) then
    FreeMem(OutBuf);
  end;
end; // InternalWriteBlock


//------------------------------------------------------------------------------
// write prepare
//------------------------------------------------------------------------------
procedure TSQLMemCompressedBLOBStream.InternalWritePrepare(Count, Result: Integer);
var
    NumBlocks,NewPos: Int64;
begin
  // calculate start position and current header number for next block
  if (FHeaders.ItemCount = 0) then
   begin
    NewPos := FBLOBDescriptor.StartPosition;
    FCurrentHeader := 0;
   end
  else
   begin
// Commented By Leo Martin - changed from absolute to relative offset
//    NewPos := FHeaders.Items[FCurrentHeader].OffsetToNextHeader;
    NewPos := FHeaders.Positions[FCurrentHeader] +
      FHeaders.Items[FCurrentHeader].OffsetToNextHeader;
    FCurrentHeader := FHeaders.ItemCount;
   end;
  NumBlocks := (Count - Result) div FBlockSize;
  if (((Count - Result) mod FBlockSize) > 0) then
   Inc(NumBlocks);
  FHeaders.SetSize(FHeaders.ItemCount + NumBlocks);
  // set new position
  FCompressedStream.Position := NewPos;
  if (FCompressedStream.Position <> NewPos) then
   raise ESQLMemException.Create(10102,ErrorLCannotSetPosition,
    [NewPos,FCompressedStream.Position,FCompressedStream.Size]);
end; // InternalWritePrepare


//------------------------------------------------------------------------------
// write to compressed stream
//------------------------------------------------------------------------------
function TSQLMemCompressedBLOBStream.Write(const Buffer; Count: Longint): Longint;
var WriteSize:        Integer;
    InBuf,TempBuf:    PAnsiChar;
    Offset:           Integer;
begin
 Result := 0;
 if (FCompressionAlgorithm = acaNone) then
  begin
   Result := FCompressedStream.Write(Buffer,Count);
   FUncompressedSize := FCompressedStream.Size - FStartPosition;
   FPosition := FCompressedStream.Position - FStartPosition;
  end // no compression
 else
  if ((Count > 0) and (FPosition >= FUncompressedSize)) then
   begin
    // write beyond end of the file
    if (FPosition > FUncompressedSize) then
      InternalWriteBeyondEOF;
    if (FHeaders.ItemCount > 0) then
     FCurrentHeader := FHeaders.ItemCount-1
    else
     FCurrentHeader := 0;
    Offset := FPosition mod FBlockSize;
    // rewrite last block
    if (Offset > 0) then
     begin
      // load last block
      InBuf := MemoryManager.GetMem(FBlockSize);
      try
        LoadBlock(FCurrentHeader,TempBuf);
        try
         Move(TempBuf^,InBuf^,FHeaders.Items[FCurrentHeader].UncompressedSize);
        finally
         FreeMem(TempBuf);
        end;

        if (Count < (FBlockSize - Offset)) then
         WriteSize := Count
        else
         WriteSize := FBlockSize - Offset;
        Move(PAnsiChar(@Buffer)^,PAnsiChar(InBuf + Offset)^,WriteSize);
        InternalWriteBlock(InBuf,Offset + WriteSize);
        Inc(Result,WriteSize);
        Inc(FCurrentHeader);
      finally
       MemoryManager.FreeAndNilMem(InBuf);
      end;
     end; // Offset > 0
    InBuf := nil;
    if (Result < Count) then
     begin
      InBuf := MemoryManager.GetMem(FBlockSize);
      if (Offset > 0) and (FCurrentHeader > 0) then
        Dec(FCurrentHeader);
      InternalWritePrepare(Count,Result);
     end; // Result < Count
    try
     while (Result < Count) do
      begin
        if ((Count - Result) < FBlockSize) then
         WriteSize := Count - Result
        else
         WriteSize := FBlockSize;
        Move(PAnsiChar(PAnsiChar(@Buffer) + Result)^,PAnsiChar(InBuf)^,WriteSize);
        FHeaders.Positions[FCurrentHeader] := FCompressedStream.Position;
        InternalWriteBlock(InBuf,WriteSize);
        // write nex block;
        Inc(Result,WriteSize);
        Inc(FCurrentHeader);
      end;
    finally
     if (InBuf <> nil) then
      MemoryManager.FreeAndNilMem(InBuf);
    end;
    Inc(FUncompressedSize,Result);
    Inc(FPosition,Result);
    FBLOBDescriptor.NumBlocks := FHeaders.ItemCount;
   end; // compression
 FBLOBDescriptor.UncompressedSize := FUncompressedSize;
 CalculateRate;
end; // Write


//------------------------------------------------------------------------------
// seek in compressed stream
//------------------------------------------------------------------------------
function TSQLMemCompressedBLOBStream.Seek(Offset: Longint; Origin: Word): Longint;
var NewPosition: Int64;
begin
 NewPosition := FPosition;
 case (Origin) of
  soFromBeginning:
    NewPosition := Offset;
  soFromCurrent:
    NewPosition := Integer(FPosition) + Offset;
  soFromEnd:
    NewPosition := Integer(FUncompressedSize) + Offset;
  end;
 Result := InternalSeek(NewPosition);
end; // Seek


{$IFDEF D6H}
function TSQLMemCompressedBLOBStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
var NewPosition: Int64;
begin
 NewPosition := FPosition;
 case (Origin) of
  soBeginning:
    NewPosition := Offset;
  soCurrent:
    NewPosition := Integer(FPosition) + Offset;
  soEnd:
    NewPosition := Integer(FUncompressedSize) + Offset;
  end;
 Result := InternalSeek(NewPosition);
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// compresses buffer
// returns true if successful
// outBuf - pointer to compressed data
// outSize - size of compressed data
//------------------------------------------------------------------------------
function SQLMemInternalCompressBuffer(
                          CompressionAlgorithm:   TSQLMemCompressionAlgorithm;
                          CompressionMode:        Byte;
                          InBuf:                  PAnsiChar;
                          InSize:                 Integer;
                          out OutBuf:             PAnsiChar;
                          out OutSize:            Integer
                          ): Boolean;
var mo,sa,osz: Cardinal;
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
     ZLIBCompressBuf(InBuf,InSize,Outbuf,Integer(OutSize),CompressionMode);
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
     bzCompressBuf(InBuf,InSize,Outbuf,Integer(OutSize),CompressionMode)
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
{$IFDEF PPMDI}
  {$IFDEF ZLIB}
  ;
  {$ELSE}
    {$IFDEF ZLIB}
    ;
    {$ENDIF}
  {$ENDIF}
  acaPPMI:
   begin
    try
     // some memory reserve for none-compressible data
     mo := Cardinal(PPM_MO[CompressionMode]);
     sa := Cardinal(PPM_SA[CompressionMode]);
     osz := 0;
     outBuf := nil;
     PpmdCompressBuf(
                InBuf,InSize,OutBuf,osz,
                mo,
                sa
                );
     OutSize := Integer(osz);
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
end; // SQLMemInternalCompressBuffer;


//------------------------------------------------------------------------------
// decompresse buffer
// Outsize must be set to uncompressed size
// return true if successful
// OutBuf - pointer to compressed data
// OutSize - size of compressed data
//------------------------------------------------------------------------------
function SQLMemInternalDecompressBuffer(
                          CompressionAlgorithm:   TSQLMemCompressionAlgorithm;
                          InBuf:                  PAnsiChar;
                          InSize:                 Integer;
                          out OutBuf:             PAnsiChar;
                          var OutSize:            Integer
                          ): Boolean;
var osz: Cardinal;
begin
 Result := false;
 if ((CompressionAlgorithm = acaNone) or (InSize = 0)) then Exit;
 Result := true;
 case CompressionAlgorithm of
{$IFDEF ZLIB}
  acaZLIB:
   begin
    try
     ZLIBDecompressBuf(InBuf,InSize,OutSize,Outbuf,OutSize);
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
     bzDecompressBuf(InBuf,InSize,OutSize,Outbuf,OutSize);
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
{$IFDEF PPMDI}
  {$IFDEF ZLIB}
  ;
  {$ELSE}
    {$IFDEF ZLIB}
    ;
    {$ENDIF}
  {$ENDIF}
  acaPPMI:
   begin
    try
     osz := 0;
     OutBuf := nil;
     PpmdDecompressBuf(InBuf,Cardinal(InSize),OutBuf,osz);
     OutSize := Integer(osz);
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
end; // CPSInternalDecompressBuffer;


{$IFDEF MSWINDOWS}

//------------------------------------------------------------------------------
// Get temp directory
//------------------------------------------------------------------------------
function SQLMemGetDefaultTempDir: WideString;
var
  l:          Integer;
  TempPath :  array[0..MAX_PATH] of WideChar;
begin
 l := MAX_PATH+1;
 l := Windows.GetTempPathW(l,@TempPath[0]);
 SetLength(Result,l);
 Move(TempPath[0],Result[1],l*2);
end;// SQLMemGetDefaultTempDir


//------------------------------------------------------------------------------
// Get temp file name
//------------------------------------------------------------------------------
procedure GetDefaultTempFileName;
begin
  SQLMemDefaultTempDir := SQLMemGetDefaultTempDir;
end;// GetDefaultTempFileName


//------------------------------------------------------------------------------
// Get temp file name
//------------------------------------------------------------------------------
function GetTempFileName: WideString;
var
  TempPath : array[0..MAX_PATH] of WideChar;
  Prefix : array[0..3] of WideChar;
  lpTempName: array [0..MAX_PATH] of WideChar;
  l: Integer;
begin
  // get temp file name
  Prefix[0] := 'A';
  Prefix[1] := 'C';
  Prefix[2] := 'R';
  Prefix[3] := #0;
  FillChar(TempPath[0],Length(TempPath)*2,$00);
  l := GetStrLength(PAnsiChar(@SQLMemDefaultTempDir[1]),aftWideChar);
  Move(SQLMemDefaultTempDir[1],TempPath[0],l);
  FillChar(lpTempName[0],Length(lpTempName)*2,$00);
  Windows.GetTempFileNameW(@TempPath[0], @Prefix[0], 0, lpTempName);
  l := GetStrLength(PAnsiChar(@lpTempName[0]),aftWideChar) div 2;
  SetLength(Result,l);
  Move(lpTempName[0],Result[1],l*2);
  Result := lpTempName;
end;// GetTempFileName


{$ENDIF}

{$IFDEF LINUX}
//------------------------------------------------------------------------------
// Get temp file name
//------------------------------------------------------------------------------
procedure GetDefaultTempFileName;
begin
  SQLMemDefaultTempDir := '/tmp/';
end;// GetDefaultTempFileName


function GetTempFileName: AnsiString;
var
  Template : array[0..MAX_PATH] of AnsiChar;
  lpTempName: array [0..MAX_PATH] of AnsiChar;
  TempFileName : PAnsiChar;
  s: AnsiString;
begin
  // get temp file name
  s := SQLMemDefaultTempDir+'SQLMemXXXXXX';
  StrPCopy(Template, s);
//  TempFileName := AllocMem(MAX_PATH);
  TempFileName := mktemp(Template);
  if TempFileName = nil then
    raise ESQLMemException.Create(40018,ErrorRCannotGetTempFileName);
  Move(TempFileName^,lpTempName,MAX_PATH);
//  Free(TempFileName);
  Result := lpTempName;
end;// GetTempFileName
{$ENDIF}


//------------------------------------------------------------------------------
// save data
//------------------------------------------------------------------------------
procedure SaveDataToStream(const Data; DataSize: Integer; Stream: TStream; ErrorCode: Integer);
var OldPos:     Int64;
    WriteBytes: Integer;
begin
  OldPos := Stream.Position;
  WriteBytes := Stream.Write(Data,DataSize);
  if (WriteBytes <> DataSize) then
    raise ESQLMemException.Create(ErrorCode,ErrorLCannotWriteToStream,
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
    raise ESQLMemException.Create(ErrorCode,ErrorLCannotReadFromStream,
      [OldPos,Stream.Size,DataSize,ReadBytes]);
end; // LoadDataFromStream


//------------------------------------------------------------------------------
// save Ansi String
//------------------------------------------------------------------------------
procedure SaveAnsiStringToStream(const Value: AnsiString; Stream: TStream; ErrorCode: Integer);
var l: Integer;
begin
  l := Length(Value);
  SaveDataToStream(l,SizeOf(l),Stream,ErrorCode);
  if (l > 0) then
   SaveDataToStream(Value[1],l,Stream,ErrorCode);
end; // SaveAnsiStringToStream


//------------------------------------------------------------------------------
// load Ansi String
//------------------------------------------------------------------------------
procedure LoadAnsiStringFromStream(var Value: AnsiString; Stream: TStream; ErrorCode: Integer);
var l: Integer;
begin
  LoadDataFromStream(l,SizeOf(l),Stream,ErrorCode);
  SetLength(Value,l);
  if (l > 0) then
   LoadDataFromStream(Value[1],l,Stream,ErrorCode);
end; // LoadAnsiStringFromStream


//------------------------------------------------------------------------------
// save Unicode String
//------------------------------------------------------------------------------
procedure SaveWideStringToStream(const Value: WideString; Stream: TStream; ErrorCode: Integer);
var l: Integer;
begin
  l := Length(Value) * 2;
  SaveDataToStream(l,SizeOf(l),Stream,ErrorCode);
  if (l > 0) then
   SaveDataToStream(Value[1],l,Stream,ErrorCode);
end; // SaveWideStringToStream


//------------------------------------------------------------------------------
// load Unicode String
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
// save Boolean
//------------------------------------------------------------------------------
procedure SaveBooleanToStream(const Value: Boolean; Stream: TStream; ErrorCode: Integer);
var b: ByteBool;
begin
  b := Value;
  SaveDataToStream(b,SizeOf(b),Stream,ErrorCode);
end; // SaveBooleanToStream


//------------------------------------------------------------------------------
// load Boolean
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
procedure SaveCryptoParamsToStream(const CryptoParams:      TSQLMemCryptoParams;
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
    if (Len > 0) then
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
    raise ESQLMemException.Create(ErrorCode,ErrorLCannotSaveCryptoParams,[e.Message]);
 end;
end; // SaveCryptoParamsToStream


//------------------------------------------------------------------------------
// load CryptoParams record from stream
//------------------------------------------------------------------------------
procedure LoadCryptoParamsFromStream(var CryptoParams:        TSQLMemCryptoParams;
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
    if (Len > 0) then
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
    raise ESQLMemException.Create(ErrorCode,ErrorLCannotLoadCryptoParams,[e.Message]);
 end;
end; // LoadCryptoParamsFromStream


procedure SaveTStringListToStream(List: TStrings; Stream: TStream; ErrorCode: Integer);
var i,count: Integer;
    s:       WideString;
begin
  if (List = nil) then
   count := 0
  else
   count := List.Count;
  SaveDataToStream(count,SizeOf(count),Stream,ErrorCode);
  if (count > 0) then
   begin
    for i := 0 to count-1 do
     begin
      s := List.Strings[i];
      SaveWideStringToStream(s,Stream,ErrorCode);
     end;
   end;
end; // SaveTStringListToStream


procedure LoadTStringListFromStream(List: TStrings; Stream: TStream; ErrorCode: Integer);
var i,count: Integer;
    s:       WideString;
begin
  LoadDataFromStream(count,SizeOf(count),Stream,ErrorCode);
  if (List <> nil) then
   begin
    List.Clear;
    if (count > 0) then
     begin
      for i := 0 to count-1 do
       begin
        LoadWideStringFromStream(s,Stream,ErrorCode);
        List.Add(s);
       end;
     end;
   end;
end; // LoadTStringListFromStream


procedure SaveTSQLMemWideStringListToStream(List: TSQLMemWideStringList; Stream: TStream; ErrorCode: Integer);
var i,count: Integer;
    s:       WideString;
begin
  if (List = nil) then
   count := 0
  else
   count := List.Count;
  SaveDataToStream(count,SizeOf(count),Stream,ErrorCode);
  if (count > 0) then
   begin
    for i := 0 to count-1 do
     begin
      s := List.Strings[i];
      SaveWideStringToStream(s,Stream,ErrorCode);
     end;
   end;
end; // SaveTSQLMemWideStringListToStream


procedure LoadTSQLMemWideStringListFromStream(List: TSQLMemWideStringList; Stream: TStream; ErrorCode: Integer);
var i,count: Integer;
    s:       WideString;
begin
  LoadDataFromStream(count,SizeOf(count),Stream,ErrorCode);
  if (List <> nil) then
   begin
    List.SetSize(count);
    if (count > 0) then
     begin
      for i := 0 to count-1 do
       begin
        LoadWideStringFromStream(s,Stream,ErrorCode);
        List.Strings[i] := s;
       end;
     end;
   end;
end; // LoadTSQLMemWideStringListFromStream


//------------------------------------------------------------------------------
// set stream position
//------------------------------------------------------------------------------
procedure SetStreamPosition(Stream: TStream; NewPosition: Int64; ErrorCode: Integer);
var OldPos: Int64;
begin
 OldPos := Stream.Position;
 Stream.Position := NewPosition;
 if (Stream.Position <> NewPosition) then
  raise ESQLMemException.Create(ErrorCode,ErrorLCannotSetPosition,
    [NewPosition,OldPos,Stream.Size]);
end; // SetStreamPosition


//------------------------------------------------------------------------------
// Return CompressionAlgorithm by its Name
//------------------------------------------------------------------------------
function GetCompressionAlgorithm(Name: AnsiString): TSQLMemCompressionAlgorithm;
var i: Integer;
begin
  Result := acaNone;
  Name := AnsiUpperCase(Name);
  for i:=0 to High(SQLMemCompressionAlgorithmNames) do
    if (SQLMemCompressionAlgorithmNames[i] = Name) then
      begin
        Result := TSQLMemCompressionAlgorithm(i);
        Exit;
      end;
end;//GetCompressionAlgorithm


//------------------------------------------------------------------------------
// Return CompressionAlgorithm SQL Name
//------------------------------------------------------------------------------
function GetCompressionAlgorithmSQLName(CompressionAlgorithm: TSQLMemCompressionAlgorithm): AnsiString;
begin
  Result := SQLMemCompressionAlgorithmNames[Integer(CompressionAlgorithm)];
end; // GetCompressionAlgorithmSQLName

{$IFNDEF D12H}
// from Delphi 2009 SysUtils.pas
function SQLMemFastFileExists(const FileName: WideString): Boolean;
{$IFDEF MSWINDOWS}

  function ExistsLockedOrShared(const Filename: WideString): Boolean;
  var
    FindData: TWin32FindDataW;
    LHandle: THandle;
  begin
    { Either the file is locked/share_exclusive or we got an access denied }
    LHandle := FindFirstFileW(PWideChar(Filename), FindData);
    if LHandle <> INVALID_HANDLE_VALUE then
    begin
      Windows.FindClose(LHandle);
      Result := FindData.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY = 0;
    end
    else
      Result := False;
  end;

var
  Code: Integer;
  LastError: Cardinal;
begin
  Code := Integer(GetFileAttributesW(PWideChar(FileName)));
  if Code <> -1 then
    Result := (FILE_ATTRIBUTE_DIRECTORY and Code = 0)
  else
  begin
    LastError := GetLastError;
    Result := (LastError <> ERROR_FILE_NOT_FOUND) and
      (LastError <> ERROR_PATH_NOT_FOUND) and
      (LastError <> ERROR_INVALID_NAME) and ExistsLockedOrShared(Filename);
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := euidaccess(PWideChar(FileName), F_OK) = 0;
end;
{$ENDIF}
{$ENDIF} // under D12H (BDS 2009)


//------------------------------------------------------------------------------
// return true if file exists
//------------------------------------------------------------------------------
function SQLMemFileExistsAnsi(FileName: PAnsiChar): Boolean;
begin
// fixed in v.5 to speed up file access on network drive under Windows
//Result := true;
  Result := SysUtils.FileExists(AnsiString(FileName));
end; // aaFileExists




//------------------------------------------------------------------------------
// return true if file exists
//------------------------------------------------------------------------------
function SQLMemFileExistsUnicode(FileName: PWideChar): Boolean;
{$IFNDEF D12H}
{$IFNDEF LINUX}
var h: THandle;
{$ENDIF}
{$ENDIF}
begin
//Result := true;
//Exit;
{$IFDEF LINUX}
 Result := SysUtils.FileExists(WideString(FileName));
{$ENDIF}
{$IFDEF MSWINDOWS}
{$IFDEF D12H}
 Result := SysUtils.FileExists(WideString(FileName));
{$ELSE}
 Result := SQLMemFastFileExists(FileName);
{
  h := CreateFileW(FileName, GENERIC_READ,
      FILE_SHARE_WRITE or FILE_SHARE_READ, nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0);
  Result := (h <> INVALID_HANDLE_VALUE);
  if (h <> INVALID_HANDLE_VALUE) then
   Windows.CloseHandle(h);
}   
{$ENDIF}
{$ENDIF}
end; // aaFileExists


//------------------------------------------------------------------------------
// return true if file exists
//------------------------------------------------------------------------------
function SQLMemFileExists(FileNameA: PAnsiChar; FileNameW: PWideChar = nil): Boolean;
begin
 if (FileNameW = nil) then
  Result := SQLMemFileExistsAnsi(FileNameA)
 else
  Result := SQLMemFileExistsUnicode(FileNameW);
end;


//------------------------------------------------------------------------------
// return true if file exists
//------------------------------------------------------------------------------
function SQLMemFileExists(FileNameA: AnsiString; FileNameW: WideString = ''): Boolean; overload;
begin
 Result := False;
 if (FileNameW <> '') then
   Result := SQLMemFileExists(nil,@FileNameW[1])
 else
 if (FileNameA <> '') then
   Result := SQLMemFileExists(@FileNameA[1],nil);
end;


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('SQLMemCompression> initialized');
{$ENDIF}
  GetDefaultTempFileName;
  SQLMemMemoryIncUseCount;

finalization

  SQLMemMemoryDecUseCount;


end.

