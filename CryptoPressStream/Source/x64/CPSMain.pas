unit CPSMain;

{$I CPSVer.inc}

interface

uses
     SysUtils, Classes,
     Dialogs,
{$IFDEF MSWINDOWS}
     Windows,Controls,
{$ENDIF}
{$IFDEF LINUX}
     Libc,
     Messages,
     QForms,
{$ENDIF}

{$IFDEF D6H}
     Variants,
{$ENDIF}

{$IFDEF TRIAL_VERSION}
{$IFDEF MSWINDOWS}
 Registry,
 {$IFDEF ENCRYPTION_DEC5}
 CPSDECCipher,CPSDECHash,CPSDECUtil,
 {$ELSE}
 CPSCipher,
 {$ENDIF}
{$ENDIF}
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
//
//  CryptoPressStream units
//
////////////////////////////////////////////////////////////////////////////////


{$IFDEF LINUX}
     CPSLinux,
{$ENDIF}


{$IFDEF DEBUG_MEMCHECK}
     MemCheck,
{$ENDIF}
{$IFDEF D12H}
     CPS_d12h,
{$ENDIF}
     CPSCrypto,
{$IFDEF ENCRYPTION_DEC5}
     CPSDecFmt,
{$ELSE}
     CPSDecUtil,
{$ENDIF}
     CPSCompression,
     CPSCriticalSection,
     CPSExcept,
     CPSConst,
 {$IFDEF DEBUG_LOG}
     CPSDebug,
 {$ENDIF}
     CPSMemory;       // UNIT CPSMemory MUST BE LAST !!!

 // Names of CompressionAlgorithm
{$IFDEF X64_ON}
const CPSCompressionAlgorithmNames: array[0..3] of AnsiString = ('None', 'ZLIB', 'BZIP', 'PPMDI'); // ,'BZIP','PPM'
{$ELSE}
 {$IFDEF  PPMDI}
 const CPSCompressionAlgorithmNames: array[0..4] of AnsiString = ('None', 'ZLIB','BZIP','PPM', 'PPMDI');
 {$ELSE}
 const CPSCompressionAlgorithmNames: array[0..3] of AnsiString = ('None', 'ZLIB','BZIP','PPM');
 {$ENDIF}
{$ENDIF}
const CPSCompressionModeNames: array[0..8] of AnsiString = (
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9'
      );
const CPSCryptoAlgorithmNames: array[0..12] of AnsiString = (
      'None',
      'Rijndael 128',
      'Rijndael 256',
      'Blowfish',
      'Twofish 128',
      'Twofish 256',
      'Square',
      'DES Single 8',
      'DES Double 8',
      'DES Double 16',
      'DES Triple 8',
      'DES Triple 16',
      'DES Triple 24'
       );
{$IFDEF ENCRYPTION_DEC5}
const CPSCryptoModeNames: array[0..8] of AnsiString = ('CTS','CBC','CFB','OFB','CFS','ECB','CFB8','OFB8','CFS8');
{$ELSE}
const CPSCryptoModeNames: array[0..3] of AnsiString = ('CTS','CBC','CFB','OFB');
{$ENDIF}
{$IFDEF ENCRYPTION_DEC5}
const CPSStringFormatNames: array[0..5] of AnsiString = ('HEX UPPER','HEX lower','MIME64','XX','UU','Escape');
{$ELSE}
const CPSStringFormatNames: array[0..4] of AnsiString = ('HEX UPPER','HEX lower','MIME64','XX','UU');
{$ENDIF}


type

{$IFDEF X64_ON}
  TCPSCompressionAlgorithm = (caNone,caZLIB,caBZIP,caPPMDI); // ,caBZIP,caPPM
{$ELSE}
 {$IFDEF  PPMDI}
  TCPSCompressionAlgorithm = (caNone,caZLIB,caBZIP,caPPM,caPPMDI);
 {$ELSE}
  TCPSCompressionAlgorithm = (caNone,caZLIB,caBZIP,caPPM);
 {$ENDIF}
{$ENDIF}
{$IFDEF ENCRYPTION_DEC5}
  TCPSStringFormat = (cpssfHEX,cpssfHEXL,cpssfMIME64,cpssfXX,cpssfUU,cpssfEscape);
{$ELSE}
  TCPSStringFormat = (cpssfHEX,cpssfHEXL,cpssfMIME64,cpssfXX,cpssfUU);
{$ENDIF}
  TCPSCryptoAlgorithm = (
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
{
const CPS_Cipher_Mode_CTS = 0;
const CPS_Cipher_Mode_CBC = 1;
const CPS_Cipher_Mode_CFB = 2;
const CPS_Cipher_Mode_OFB = 3;
const CPS_Cipher_Mode_CFS = 4;
const CPS_Cipher_Mode_ECB = 5;
const CPS_Cipher_Mode_CFB8 = 6;
const CPS_Cipher_Mode_OFB8 = 7;
const CPS_Cipher_Mode_CFS8 = 8;
}
{$IFDEF ENCRYPTION_DEC5}
  TCPSCryptoMode = (acmCTS,acmCBC,acmCFB,acmOFB,acmCFS,acmECB,acmCFB8,acmOFB8,acmCFS8);
{$ELSE}
  TCPSCryptoMode = (acmCTS,acmCBC,acmCFB,acmOFB);
{$ENDIF}
  TCPSOperation = (cpsopLoadFromStream,cpsopSaveToStream,
                   cpsopSetSize,cpsopRead,cpsopWrite,
                   cpsopCompressFile,cpsopDecompressFile,
                   cpsopNone
                   );
  TCPSProgressEvent = procedure (
                                      Sender:     TObject;
                                      Progress:   Double;
                                      Operation:  TCPSOperation;
                                      var Abort:  Boolean
                                   ) of object;
  TCPSBufferHeader = packed record
   CompressionAlgorithm:  Byte;
   CryptoAlgorithm:       Byte;
   CryptoMode:            Byte;
   CRC16:                 Word;
   UncompressedSize:      Integer;
  end; // 7 bytes

 TCPSStreamHeader = packed record
       Signature:             TCPSSignature; // signature
       BlockSize:             Integer; // block size
       NumBlocks:             Integer;  // number of blocks
       Version:               Single;   // version
       CompressionAlgorithm:  Byte; // compression level
       CompressionMode:       Byte; // compression mode
       HeaderSize:            Integer;	// size of additional header
       CryptoHeader:          TCPSCryptoHeader;
       Reserved:              array [0..3] of AnsiChar; // reserved
 end;

 TCPSHeader = packed record
       UncompressedSize: Cardinal; // packed block size
       CompressedSize:   Cardinal; // unpacked block size
       NextHeaderOffset: Cardinal; // offset from beginning of this header to
                                   // to next block header
       CRC16:            Word;     // check sum for this block page
 end;

 TCPSCacheItem = record
  Data:         PAnsiChar;
  BlockNumber:  Integer;
 end;

const
 CPSHeaderSize = sizeof(TCPSHeader); // size in bytes (16)
 CPSFileStreamHeaderSize = sizeof(TCPSStreamHeader); // size in bytes (16)

type


////////////////////////////////////////////////////////////////////////////////
//
// TCPSHeadersArray
//
////////////////////////////////////////////////////////////////////////////////


  TCPSHeadersArray = class
    private
     AllocBy:             integer;
     DeAllocBy:           integer;
     MaxAllocBy:          integer;
     AllocItemCount:      integer;
    public
     Items:               array of TCPSHeader;
     Positions:           array of Int64; // block positions
     ItemCount:           integer; // all files quantity (including deleted files)
    public
     constructor Create;
     destructor Destroy; override;
     procedure SetSize(newSize: integer);
     procedure AppendItem(value: TCPSHeader; pos: Int64);
  end; // TCPSHeadersArray


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCache
//
////////////////////////////////////////////////////////////////////////////////


  TCPSCache = class
   private
     FNumCachedBlocks: Integer; // number of cached blocks
     FCache:           array of TCPSCacheItem;
     FBlockSize:       Integer;
     FSecure:          Boolean;
    public
     constructor Create(NumCachedBlocks: Integer; BlockSize: Integer; Secure: Boolean);
     destructor Destroy; override;
     // return nil if not found
     function FindCachedBlock(BlockNumber: Integer): PAnsiChar;
     // reserves cache item for the block with specified number
     function GetNewBlock(BlockNumber: Integer): PAnsiChar;
     procedure Clear;
  end; // TCPSReadCache


////////////////////////////////////////////////////////////////////////////////
//
// TCPSStream
//
////////////////////////////////////////////////////////////////////////////////


  TCPSStream = class (TStream)
   private
    FCSection:          TRTLCriticalSection;
    FBlockSize:         Integer;
    FOnProgress:        TCPSProgressEvent; // progress for bulk operations
    FModified:          Boolean;
    FReadOnly:          Boolean;
    FManager:           TComponent;
   protected
    FAbort:             Boolean;
    FProgress:          Double;
    FOperation:         TCPSOperation;
    FProgressOperation: TCPSOperation;
   protected
    // on progress
    procedure DoOnProgress(Progress: Double; Operation: TCPSOperation; var Abort: Boolean); virtual;
    function GetEof: Boolean;
   public
    // lock
    procedure Lock; virtual;
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
    procedure LoadFromFile(const FileName: AnsiString); overload;
    procedure SaveToFile(const FileName: AnsiString); overload;
{$IFDEF D6H}
    procedure LoadFromFile(const FileName: WideString); overload;
    procedure SaveToFile(const FileName: WideString); overload;
{$ELSE}
    procedure LoadFromFile(const FileName: WideString; Dummy: ByteBool); overload;
    procedure SaveToFile(const FileName: WideString; Dummy: ByteBool); overload;
{$ENDIF}
    procedure SaveData(var Data; DataSize: Integer; ErrorCode: Integer = 0);
    procedure LoadData(var Data; DataSize: Integer; ErrorCode: Integer = 0);
    procedure SaveShortString(Value: ShortString; ErrorCode: Integer = 0);
    procedure LoadShortString(var Value: ShortString; ErrorCode: Integer = 0);
    procedure SaveAnsiString(Value: AnsiString; ErrorCode: Integer = 0);
    procedure LoadAnsiString(var Value: AnsiString; ErrorCode: Integer = 0);
    procedure SaveWideString(Value: WideString; ErrorCode: Integer = 0);
    procedure LoadWideString(var Value: WideString; ErrorCode: Integer = 0);
    procedure SaveString(Value: String; ErrorCode: Integer = 0);
    procedure LoadString(var Value: String; ErrorCode: Integer = 0);
    procedure SaveBoolean(Value: Boolean; ErrorCode: Integer = 0);
    procedure LoadBoolean(var Value: Boolean; ErrorCode: Integer = 0);
    procedure SaveInteger(Value: Integer; ErrorCode: Integer = 0);
    procedure LoadInteger(var Value: Integer; ErrorCode: Integer = 0);
    procedure SaveCardinal(Value: Cardinal; ErrorCode: Integer = 0);
    procedure LoadCardinal(var Value: Cardinal; ErrorCode: Integer = 0);
    procedure SaveInt64(Value: Int64; ErrorCode: Integer = 0);
    procedure LoadInt64(var Value: Int64; ErrorCode: Integer = 0);
   public
    property BlockSize: Integer read FBlockSize write FBlockSize;
    // Progress Event
    property OnProgress: TCPSProgressEvent read FOnProgress write FOnProgress;
    property Modified: Boolean read FModified write FModified;
    property ReadOnly: Boolean read FReadOnly write FReadOnly;
    property Manager: TComponent read FManager;
    property Operation: TCPSOperation read FOperation write FOperation;
    property ProgressOperation: TCPSOperation read FProgressOperation write FProgressOperation;
    property Eof: Boolean Read GetEof;
  end; // TCPSStream


////////////////////////////////////////////////////////////////////////////////
//
// TCPSAdvancedStream
//
////////////////////////////////////////////////////////////////////////////////


  TCPSAdvancedStream = class (TCPSStream)
   private
    FCompressionAlgorithm:  TCPSCompressionAlgorithm;
    FCompressionMode:       Byte;
    FCryptoParams:          TCPSCryptoParams;
    FTempDir:               WideString;
   protected
    function GetRatio: Double; virtual; abstract;
    function GetCompressedSize: Int64; virtual; abstract;
    function GetHeaderSize: Integer; virtual; abstract;
    function GetEncrypted: Boolean; virtual; abstract;
    function GetDirectAccessStream: TStream; virtual; abstract;
    // on progress
    procedure DoOnProgress(Progress: Double; Operation: TCPSOperation; var Abort: Boolean); override;
   public
    constructor Create(Manager: TComponent = nil; TempDir: WideString = ''); overload;
    destructor Destroy; override;
    procedure LoadHeader(Header: PAnsiChar); virtual; abstract;
    procedure ClearCache; virtual; abstract;
    procedure ChangeParameters(
                              NewCompressionAlgorithm: TCPSCompressionAlgorithm;
                              NewCompressionMode:      Byte;
                              NewCryptoParams:         TCPSCryptoParams
                            ); virtual; abstract;
    procedure Refresh; virtual; abstract;
   public
    property Ratio: Double read GetRatio;
    property CompressedSize: Int64 read GetCompressedSize;
    property CompressionAlgorithm: TCPSCompressionAlgorithm read FCompressionAlgorithm;
    property CompressionMode: Byte read FCompressionMode;
    property CryptoParams: TCPSCryptoParams read FCryptoParams;
    property Encrypted: Boolean read GetEncrypted;
    property HeaderSize: Integer read GetHeaderSize;
    property TempDir: WideString read FTempDir write FTempDir;
    property DirectAccessStream: TStream read GetDirectAccessStream;
  end; // TCPSAdvancedStream


////////////////////////////////////////////////////////////////////////////////
//
// TCPSMemoryStream
//
////////////////////////////////////////////////////////////////////////////////


  // class optimized for fast increasing the size of the data
  TCPSMemoryStream = class (TCPSStream)
   private
    FBuffer:            PAnsiChar;
    FPosition:          Int64;
    FSize:              Int64;   // size of the stream content
    FBufferSize:        Int64;   // actual size of the allocated buffer
    // set Size to 0 resets all realloc settings to default
    FFastReallocCount:  Integer; // number of optimized Realloc
                                 // before last real Realloc call
    FReallocDelta:      Int64; // size in bytes of last real Realloc call

   protected
    function GetMemory: Pointer;
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
    constructor Create(Manager: TComponent = nil);
    destructor Destroy; override;
   public
    property Buffer: PAnsiChar read FBuffer write FBuffer;
    property BufferSize: Int64 read FBufferSize write FBufferSize;
    property ReallocDelta: Int64 read FReallocDelta write SetReallocDelta;
    property FastReallocCount: Integer read FFastReallocCount write FFastReallocCount;
    property Memory: Pointer read GetMemory;
  end; // TCPSStream


////////////////////////////////////////////////////////////////////////////////
//
// TCPSFileStream
//
////////////////////////////////////////////////////////////////////////////////


  TCPSFileStream = class (TCPSStream)
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
    constructor Create(const FileName: AnsiString; Mode: Word; Manager: TComponent = nil); overload;
{$IFDEF D6H}
    constructor Create(const FileName: WideString; Mode: Word; Manager: TComponent = nil); overload;
{$ELSE}
    constructor Create(const FileName: WideString; Mode: Word; Dummy: ByteBool; Manager: TComponent = nil); overload;
{$ENDIF}
    destructor Destroy; override;
    procedure FlushFileBuffers;
   public
    property Handle: Integer read FHandle;
    property FileName: AnsiString read FFileName;
    property UnicodeFileName: WideString read FUnicodeFileName;
    property Mode: Word read FMode;
  end; // TCPSFileStream


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCryptoPressStream - stream supporing compression and encryption
//
////////////////////////////////////////////////////////////////////////////////


  TCPSCryptoPressStream = class (TCPSAdvancedStream)
   private
    FHeaders:               TCPSHeadersArray;
    FUncompressedSize:      Int64;
    FCurrentBlock:          Integer;
    FCurrentPosition:       Int64;
    FHeader:                TCPSStreamHeader;
    FOffestToHeader:        Int64;
    FOffsetToFirstBlock:    Int64;
    FBaseStream:            TStream;
    FFreeBaseStream:        Boolean;
    FCache:                 TCPSCache;
    FEncrypted:             Boolean;
    FCompressed:            Boolean;
    FTempStream:            TCPSStream;
    FLastBuffer:            PAnsiChar;
    FLastSize:              Integer;
    FMaxTempBufferSize:     Integer;
   protected
    function GetRatio: Double; override;
    function GetCompressedSize: Int64; override;
    function GetHeaderSize: Integer; override;
    function GetEncrypted: Boolean; override;
    function GetDirectAccessStream: TStream; override;
    // load all headers
    procedure LoadHeaders(LoadStreamHeader: Boolean);
    // create and write all headers for the new stream
    procedure CreateHeaders(Header: PAnsiChar; HeaderSize: Integer);
    // save stream header
    procedure SaveStreamHeader;
    procedure ClearTempBuffer;
    // load block from stream
    function LoadBlock(BlockNumber: Integer): PAnsiChar;
    // return false if compressed stream should start extending as new block have larger compressed size
    function SaveBlock(BlockNumber:    Integer;
                        Buffer:        PAnsiChar;
                        BufferSize:    Integer;
                        ForceRewrite:  Boolean = false
                       ): Boolean;
    function InternalSeek(Offset: Int64; Origin: Word): Int64;
    procedure DecreaseSize(const NewSize: Int64);
    procedure IncreaseSize(const NewSize: Int64);
    procedure InternalSetSize(const NewSize: Int64);
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
    constructor Create(
						           BaseStream:            TStream;
                       CryptoParams:          TCPSCryptoParams;
                       CreateNewStream:       Boolean = False;
                       FreeBaseStream:        Boolean = True;
                       // params used only for creating new stream
                       CompressionAlgorithm:  TCPSCompressionAlgorithm = caZLIB;
                       CompressionMode:       Byte = CPSDefaultCompressionMode;
                       BlockSize:             Integer = CPSDefaultBlockSize;
                       Header:                PAnsiChar = nil;
                       HeaderSize:            Integer = 0;
                       Manager:               TComponent = nil;
                       TempDir:               WideString = ''
                      ); overload;
    // destructor
    destructor Destroy; override;
    procedure LoadHeader(Header: PAnsiChar); override;
    procedure ClearCache; override;
    procedure ChangeParameters(
                              NewCompressionAlgorithm: TCPSCompressionAlgorithm;
                              NewCompressionMode:       Byte;
                              NewCryptoParams:          TCPSCryptoParams
                            ); override;
    procedure Refresh; override;
  end; // TCPSCryptoPressStream


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCryptoPressMemoryStream - memory stream based on TCPSCryptoPressStream
//
////////////////////////////////////////////////////////////////////////////////


  TCPSCryptoPressMemoryStream = class (TCPSAdvancedStream)
  private
   FCryptoPressStream:  TCPSCryptoPressStream;
  protected
    function GetMemory: Pointer;
    function GetMemorySize: Integer;
    function GetRatio: Double; override;
    function GetCompressedSize: Int64; override;
    function GetHeaderSize: Integer; override;
    function GetEncrypted: Boolean; override;
    function GetDirectAccessStream: TStream; override;
    function InternalSeek(Offset: Int64; Origin: Word): Int64;
    procedure InternalSetSize(const NewSize: Int64);
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
  public
    constructor Create; overload;
    constructor Create(
                       CryptoParams:          TCPSCryptoParams;
                       // params used only for creating new stream
                       CompressionAlgorithm:  TCPSCompressionAlgorithm = caZLIB;
                       CompressionMode:       Byte = CPSDefaultCompressionMode;
                       BlockSize:             Integer = CPSDefaultBlockSize;
                       Header:                PAnsiChar = nil;
                       HeaderSize:            Integer = 0;
                       Manager:               TComponent = nil;
                       TempDir:               WideString = ''
                      ); overload;
    // destructor
    destructor Destroy; override;
    procedure LoadHeader(Header: PAnsiChar); override;
    procedure ClearCache; override;
    procedure ChangeParameters(
                              NewCompressionAlgorithm: TCPSCompressionAlgorithm;
                              NewCompressionMode:      Byte;
                              NewCryptoParams:         TCPSCryptoParams
                            ); override;
    procedure Refresh; override;
   public
    property Memory: Pointer read GetMemory;
    property MemorySize: Integer read GetMemorySize;
  end; // TCPSCryptoPressMemoryStream


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCryptoPressFileStream - file stream based on TCPSCryptoPressStream
//
////////////////////////////////////////////////////////////////////////////////


  TCPSCryptoPressFileStream = class (TCPSAdvancedStream)
  private
   FCryptoPressStream:  TCPSCryptoPressStream;
  protected
    function GetHandle: Integer;
    function GetMode: Word;
    function GetFileName: AnsiString;
    function GetRatio: Double; override;
    function GetCompressedSize: Int64; override;
    function GetHeaderSize: Integer; override;
    function GetEncrypted: Boolean; override;
    function GetDirectAccessStream: TStream; override;
    function InternalSeek(Offset: Int64; Origin: Word): Int64;
    procedure InternalSetSize(const NewSize: Int64);
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
  public
    constructor Create(const FileName: AnsiString; Mode: Word); overload;
{$IFDEF D6H}
    constructor Create(const FileName: WideString; Mode: Word); overload;
{$ELSE}
    constructor Create(const FileName: WideString; Mode: Word; Dummy: ByteBool = False); overload;
{$ENDIF}
    constructor Create(
                       const FileName:        AnsiString;
                       Mode:                  Word;
                       CryptoParams:          TCPSCryptoParams;
                       // params used only for creating new stream
                       CompressionAlgorithm:  TCPSCompressionAlgorithm = caZLIB;
                       CompressionMode:       Byte = CPSDefaultCompressionMode;
                       BlockSize:             Integer = CPSDefaultBlockSize;
                       Header:                PAnsiChar = nil;
                       HeaderSize:            Integer = 0;
                       Manager:               TComponent = nil;
                       TempDir:               WideString = ''
                      ); overload;
{$IFDEF D6H}
    constructor Create(
                       const FileName:        WideString;
                       Mode:                  Word;
                       CryptoParams:          TCPSCryptoParams;
                       // params used only for creating new stream
                       CompressionAlgorithm:  TCPSCompressionAlgorithm = caZLIB;
                       CompressionMode:       Byte = CPSDefaultCompressionMode;
                       BlockSize:             Integer = CPSDefaultBlockSize;
                       Header:                PAnsiChar = nil;
                       HeaderSize:            Integer = 0;
                       Manager:               TComponent = nil;
                       TempDir:               WideString = ''
                      ); overload;
{$ELSE}
    constructor Create(
                       const FileName:        WideString;
                       Mode:                  Word;
                       Dummy:                 ByteBool;
                       CryptoParams:          TCPSCryptoParams;
                       // params used only for creating new stream
                       CompressionAlgorithm:  TCPSCompressionAlgorithm;
                       CompressionMode:       Byte = CPSDefaultCompressionMode;
                       BlockSize:             Integer = CPSDefaultBlockSize;
                       Header:                PAnsiChar = nil;
                       HeaderSize:            Integer = 0;
                       Manager:               TComponent = nil;
                       TempDir:               WideString = ''
                      ); overload;
{$ENDIF}
    // destructor
    destructor Destroy; override;
    procedure FlushFileBuffers;
    procedure LoadHeader(Header: PAnsiChar); override;
    procedure ClearCache; override;
    procedure ChangeParameters(
                              NewCompressionAlgorithm: TCPSCompressionAlgorithm;
                              NewCompressionMode:      Byte;
                              NewCryptoParams:         TCPSCryptoParams
                            ); override;
    procedure Refresh; override;
   public
    property Handle: Integer read GetHandle;
    property FileName: AnsiString read GetFileName;
    property Mode: Word read GetMode;
  end; // TCPSCryptoPressFileStream


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCryptoParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


  TCPSCryptoParamsEditor = class (TPersistent)
   private
    FKeyInfo:         TCPSCryptoKey;
    FInitVector:      array [0..CPS_MAX_VECTOR] of Byte;
    FInitVectorSize:  Word;
    FPassword:        AnsiString; // CPSDefaultPassword by default
    FCryptoAlgorithm: TCPSCryptoAlgorithm;  // CPS_Cipher_None by Default
    FCryptoMode:      TCPSCryptoMode;  // CPS_CTS by Default
    FUseInitVector:   Boolean; // False by default
   public
    constructor Create;
    destructor Destroy; override;
    procedure SetCryptoParams(Params: TCPSCryptoParams);
    function GetCryptoParams: TCPSCryptoParams;

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
    property CryptoAlgorithm: TCPSCryptoAlgorithm read FCryptoAlgorithm write FCryptoAlgorithm;
    property CryptoMode:TCPSCryptoMode read FCryptoMode write FCryptoMode;
    property KeySize: Integer read GetKeySize write SetKeySize;
    property Password: AnsiString read FPassword write FPassword;
    property UseInitVector: Boolean read FUseInitVector write FUseInitVector;
    property InitVectorSize: Word read FInitVectorSize write FInitVectorSize;
  end;// TCPSCryptoParamsEditor


////////////////////////////////////////////////////////////////////////////////
//
// TCPSManager
//
////////////////////////////////////////////////////////////////////////////////


  TCPSManager = class (TComponent)
   private
    FCSection:              TRTLCriticalSection;
    FCryptoParams:          TCPSCryptoParamsEditor;
    FCompressionAlgorithm:  TCPSCompressionAlgorithm;
    FCompressionMode:       Byte;
    FBlockSize:             Integer;
    FOnProgress:            TCPSProgressEvent;
    FStreams:               TThreadList;
    FNumCachedBlocks:       Integer; // number of cached blocks
    FMaxTempBufferSize:     Integer; // maximum amount of RAM for temporary stream
    FTempDir:               AnsiString;
    FTempDirUnicode:        WideString;
    FCurrentVersion:        AnsiString;
   protected
    procedure SetTempDir(Value: AnsiString);
    procedure SetTempDirUnicode(Value: WideString);
{$IFDEF D12H}
    function GetTempDirUnicodeAsString: String;
    procedure SetTempDirUnicodeAsString(Value: String);
{$ENDIF}
    procedure SetCompressionMode(Value: Byte);
    procedure SetBlockSize(Value: Integer);
    procedure SetNumCachedBlocks(Value: Integer);
    procedure SetMaxTempBufferSize(Value: Integer);
    function GetStream(Index: Integer): TStream;
    function GetCount: Integer;
    procedure DoProgressCompressFile(
                                      Sender:     TObject;
                                      Progress:   Double;
                                      Operation:  TCPSOperation;
                                      var Abort:  Boolean
                                   );
    procedure DoProgressDecompressFile(
                                      Sender:     TObject;
                                      Progress:   Double;
                                      Operation:  TCPSOperation;
                                      var Abort:  Boolean
                                   );
    function GetCurrentVersion: AnsiString;
   public
    constructor Create(AOwner: TComponent);  override;
    destructor Destroy; override;
    procedure Lock;
    procedure Unlock;
    procedure CompressBuffer(
                          InBuf:                  PAnsiChar;
                          InSize:                 Integer;
                          out OutBuf:             PAnsiChar;
                          out OutSize:            Integer;
                          SkipBufferHeader:       Boolean = False
                             );
    procedure DecompressBuffer(
                          InBuf:                  PAnsiChar;
                          InSize:                 Integer;
                          out OutBuf:             PAnsiChar;
                          out OutSize:            Integer;
                          SkipBufferHeader:       Boolean = False
                              );
    function CompressAnsiString(Source: AnsiString): AnsiString;
    function DecompressAnsiString(Source: AnsiString): AnsiString;
    function AnsiStringToFormat(Source: AnsiString; Format: TCPSStringFormat): AnsiString;
    function FormatToAnsiString(Source: AnsiString; Format: TCPSStringFormat): AnsiString;
    function WideStringToFormat(Source: WideString; Format: TCPSStringFormat): WideString;
    function FormatToWideString(Source: WideString; Format: TCPSStringFormat): WideString;
    function StringToFormat(Source: String; Format: TCPSStringFormat): String;
    function FormatToString(Source: String; Format: TCPSStringFormat): String;
    function BufferToFormat(Buffer: PAnsiChar; Size: Integer; Format: TCPSStringFormat): AnsiString;
    procedure FormatToBuffer(Source: AnsiString; Format: TCPSStringFormat; out Buffer: PAnsiChar; out Size: Integer);
    procedure CompressFile(SourceFileName: AnsiString; DestFileName: AnsiString);
    procedure DecompressFile(SourceFileName: AnsiString; DestFileName: AnsiString);
    function CreateMemoryStream: TCPSMemoryStream;
    function CreateFileStream(const FileName: AnsiString; Mode: Word): TCPSFileStream;
    function CreateCryptoPressStream(
                                      BaseStream:            TStream;
                                      CreateNewStream:       Boolean = False;
                                      FreeBaseStream:        Boolean = True;
                                      Header:                PAnsiChar = nil;
                                      HeaderSize:            Integer = 0
                                     ): TCPSCryptoPressStream;
    function CreateCryptoPressMemoryStream(
                                      Header:                PAnsiChar = nil;
                                      HeaderSize:            Integer = 0
                                     ): TCPSCryptoPressMemoryStream;
    function CreateCryptoPressFileStream(
                                      const FileName:        AnsiString;
                                      Mode:                  Word;
                                      Header:                PAnsiChar = nil;
                                      HeaderSize:            Integer = 0
                                     ): TCPSCryptoPressFileStream; overload;
{$IFDEF D6H}
    function CreateCryptoPressFileStream(
                                      const FileName:        WideString;
                                      Mode:                  Word;
                                      Header:                PAnsiChar = nil;
                                      HeaderSize:            Integer = 0
                                     ): TCPSCryptoPressFileStream; overload;
{$ELSE}
    function CreateCryptoPressFileStream(
                                      const FileName:        WideString;
                                      Mode:                  Word;
                                      Dummy:                 ByteBool;
                                      Header:                PAnsiChar = nil;
                                      HeaderSize:            Integer = 0
                                     ): TCPSCryptoPressFileStream; overload;
{$ENDIF}
    function IndexOf(Stream: TStream): Integer;
    procedure Clear;
    function Add(Stream: TStream): Integer;
    procedure Delete(Index: Integer);
    function Remove(Stream: TStream): Integer;
   public
    property Streams[Index: Integer]: TStream read GetStream;
    property Count: Integer read GetCount;
   published
    property CurrentVersion: AnsiString read GetCurrentVersion write FCurrentVersion;
    property CompressionAlgorithm: TCPSCompressionAlgorithm
              read FCompressionAlgorithm write FCompressionAlgorithm;
    property CompressionMode: Byte read FCompressionMode write SetCompressionMode;
    property BlockSize: Integer read FBlockSize write SetBlockSize;
    property NumCachedBlocks: Integer read FNumCachedBlocks write SetNumCachedBlocks;
    property MaxTempBufferSize: Integer read FMaxTempBufferSize write SetMaxTempBufferSize;
    property CryptoParams: TCPSCryptoParamsEditor read FCryptoParams write FCryptoParams;
    property OnProgress: TCPSProgressEvent read FOnProgress write FOnProgress;
    property TempDirAnsi: AnsiString read FTempDir write SetTempDir;
    property TempDirUnicode: WideString read FTempDirUnicode write SetTempDirUnicode;
{$IFDEF D12H}
// wide string
    property TempDir: String read GetTempDirUnicodeAsString write SetTempDirUnicodeAsString;
{$ELSE}
// ansi string
    property TempDir: String read FTempDir write SetTempDir;
{$ENDIF}
  end;// TCPSManager


function IsStreamCPSStream(BaseStream: TStream): Boolean;
function IsStreamEncryptedCPSStream(BaseStream: TStream): Boolean;
function CPSGetOffsetToStreamHeader(BaseStream: TStream): Int64;
{$IFDEF MSWINDOWS}
function CPSGetDefaultTempDir: WideString;
function CPSGetTempFileName(TempDir: WideString): WideString;
{$ELSE}
function CPSGetDefaultTempDir: AnsiString;
function CPSGetTempFileName(TempDir: AnsiString): AnsiString;
{$ENDIF}
{$IFDEF TRIAL_VERSION}

function CPStrcapt1: AnsiString;
function CPStrnm1: AnsiString;


function CPStrcapt: AnsiString;
function CPStrnm: AnsiString;
function CPStrgetencmsg(msg: AnsiString): AnsiString;
function CPStrgetdecmsg(msg: AnsiString): AnsiString;
procedure CPStrshnm;
{$ENDIF}

var
  IsDesignMode:          Boolean;

implementation

uses Math;


////////////////////////////////////////////////////////////////////////////////
//
// TCPSHeadersArray
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Construct array of specified size
//------------------------------------------------------------------------------
constructor TCPSHeadersArray.Create;
begin
 AllocBy := 100; // default alloc
 DeAllocBy := 100; // default alloc
 MaxAllocBy := 10000; // max alloc
 AllocItemCount := 0;
 ItemCount := 0;
 SetSize(0);
end; // Create


//------------------------------------------------------------------------------
// Destruct array (free mem)
//------------------------------------------------------------------------------
destructor TCPSHeadersArray.Destroy;
begin
 SetSize(0);
 inherited Destroy;
end;//Destroy;


//------------------------------------------------------------------------------
// Set length of array to specified size
//------------------------------------------------------------------------------
procedure TCPSHeadersArray.SetSize(newSize: integer);
begin
 if (newSize = 0) then
  begin
   ItemCount := 0;
   allocItemCount := 0;
   Items := nil;
   Positions := nil;
   Exit;
  end;

 if (newSize > allocItemCount) then
  begin
     AllocBy := AllocBy * 2;
     if (AllocBy > MaxAllocBy) then
      AllocBy := MaxAllocBy;
     if (allocItemCount + AllocBy > newSize) then
      allocItemCount := allocItemCount + AllocBy
     else
      allocItemCount := newSize;
     SetLength(Items,allocItemCount);
     SetLength(Positions,allocItemCount);
  end
 else
  if (newSize < ItemCount) then
   if (allocItemCount-newSize > deAllocBy) then
    begin
     deAllocBy := deAllocBy * 2;
     if (deAllocBy > MaxAllocBy) then
      deAllocBy := MaxAllocBy;
     SetLength(Items,newSize);
     SetLength(Positions,newSize);
     allocItemCount := newSize;
    end;
 ItemCount := newSize;
end;// SetSize


//------------------------------------------------------------------------------
// Insert an element into specified position
//------------------------------------------------------------------------------
procedure TCPSHeadersArray.AppendItem(value: TCPSHeader;  pos: Int64);
begin
 inc(ItemCount);
 SetSize(ItemCount);
 Items[ItemCount-1] := value;
 Positions[ItemCount-1] := pos;
end; // AppendItem


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCache
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TCPSCache.Create(NumCachedBlocks: Integer; BlockSize: Integer; Secure: Boolean);
var i: Integer;
begin
  FNumCachedBlocks := NumCachedBlocks;
  FSecure := Secure;
  SetLength(FCache,FNumCachedBlocks);
  FBlockSize := BlockSize;
  for i := 0 to FNumCachedBlocks - 1 do
   begin
    FCache[i].Data := MemoryManager.GetMem(FBlockSize);
    FCache[i].BlockNumber := -1;
   end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TCPSCache.Destroy;
var i: Integer;
begin
  for i := 0 to FNumCachedBlocks - 1 do
   begin
    if (FSecure) then
     FillChar(FCache[i].Data^,FBlockSize,$00);
    MemoryManager.FreeAndNilMem(FCache[i].Data);
   end;
  SetLength(FCache,0);
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// return nil if not found
//------------------------------------------------------------------------------
function TCPSCache.FindCachedBlock(BlockNumber: Integer): PAnsiChar;
var i: Integer;
begin
  Result := nil;
  for i := 0 to FNumCachedBlocks - 1 do
   if (FCache[i].BlockNumber = BlockNumber) then
    begin
     Result := FCache[i].Data;
     break;
    end;
end; // FindCachedBlock


//------------------------------------------------------------------------------
// reserves cache item for the block with specified number
//------------------------------------------------------------------------------
function TCPSCache.GetNewBlock(BlockNumber: Integer): PAnsiChar;
var i:    Integer;
    temp: TCPSCacheItem;
begin
  for i := 0 to FNumCachedBlocks - 1 do
   if (FCache[i].BlockNumber < 0) then
    begin
     FCache[i].BlockNumber := BlockNumber;
     Result := FCache[i].Data;
     Exit;
    end;
  if (FNumCachedBlocks > 1) then
   begin
    temp := FCache[FNumCachedBlocks-1];
    Move(FCache[0],FCache[1],(FNumCachedBlocks-1)*SizeOf(TCPSCacheItem));
    FCache[0] := temp;
   end;
 Result := FCache[0].Data;
 FCache[0].BlockNumber := BlockNumber;
end; // GetNewBlock


//------------------------------------------------------------------------------
// clear
//------------------------------------------------------------------------------
procedure TCPSCache.Clear;
var i: Integer;
begin
  for i := 0 to FNumCachedBlocks - 1 do
   begin
    FCache[i].BlockNumber := -1;
    if (FSecure) then
     FillChar(FCache[i].Data^,FBlockSize,$00);
   end;
end; // Clear


////////////////////////////////////////////////////////////////////////////////
//
// TCPSStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// on progress
//------------------------------------------------------------------------------
procedure TCPSStream.DoOnProgress(Progress: Double; Operation: TCPSOperation; var Abort: Boolean);
begin
  if Assigned(FOnProgress) then
   if ((FOperation = cpsopNone) or (FOperation = Operation)) then
    begin
     if (FProgressOperation = cpsopNone) then
      FOnProgress(Self,Progress,Operation,Abort)
     else
      FOnProgress(Self,Progress,FProgressOperation,Abort);
    end;
end; // on progress


//------------------------------------------------------------------------------
// return true if end of file reached
//------------------------------------------------------------------------------
function TCPSStream.GetEof: Boolean;
begin
  Result := (Position >= Size);
end; // GetEof


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TCPSStream.Lock;
begin
 CPSCriticalSection.EnterCriticalSection(FCSection);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TCPSStream.Unlock;
begin
  CPSCriticalSection.LeaveCriticalSection(FCSection);
end; // Unlock


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TCPSStream.Create;
begin
  FBlockSize := CPSDefaultBlockSize;
  FModified := False;
  FReadOnly := False;
  FManager := nil;
  FOperation := cpsopNone;
  FProgressOperation := cpsopNone;
  CPSCriticalSection.InitializeCriticalSection(FCSection);
end; // Create


//------------------------------------------------------------------------------
// destroy
//------------------------------------------------------------------------------
destructor TCPSStream.Destroy;
begin
  CPSCriticalSection.DeleteCriticalSection(FCSection);
  inherited Destroy;
end; // Destory


//------------------------------------------------------------------------------
// save all data to another stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveToStream(Stream: TStream);
var OutBytes,OldPos,OldPos1,InSize:	Int64;
    OutSize:					              Integer;
    Buf:            	              PAnsiChar;
    FProgress:      	              Extended;
    FProgressMax:   	              Extended;
    ReadBytes,WriteBytes:           Integer;
    Pos:                            Int64;
begin
 if (FBlockSize = 0) then
  raise ECPSException.Create(10000,ErrorLZeroBlockSizeIsNotAllowed);
 OldPos := Position;
 OldPos1 := Stream.Position;
 Position := 0;
 OutBytes := 0;
 FAbort := False;
 if (FOperation = cpsopNone) then
  begin
   FOperation := cpsopSaveToStream;
   FProgressOperation := cpsopSaveToStream;
  end;
 DoOnProgress(0,cpsopSaveToStream,FAbort);
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
      raise ECPSException.Create(10001,ErrorLCannotReadFromStream,
        [Pos,Self.Size,OutSize,ReadBytes]);

     Pos := Stream.Position;
     WriteBytes := Stream.Write(Buf^,OutSize);
     if (WriteBytes <> OutSize) then
      raise ECPSException.Create(10002,ErrorLCannotWriteToStream,
        [Pos,Stream.Size,OutSize,WriteBytes]);

     Inc(OutBytes,OutSize);
     FProgressMax := Size;
     FProgress := OutBytes;
     DoOnProgress(FProgress/FProgressMax*100.0,cpsopSaveToStream,FAbort);
    end;
 finally
   MemoryManager.FreeAndNilMem(Buf);
   Position := OldPos;
   Stream.Position := OldPos1;
   FOperation := cpsopNone;
   FProgressOperation := cpsopNone;
 end;
 if (not FAbort) then
  DoOnProgress(100.0,cpsopSaveToStream,FAbort);
end; // SaveToStream


//------------------------------------------------------------------------------
// load all data from another stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadFromStream(Stream: TStream);
begin
 LoadFromStreamWithPosition(Stream,0,Stream.Size);
end; // LoadFromStream


//------------------------------------------------------------------------------
// load from stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadFromStreamWithPosition(
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
  raise ECPSException.Create(10003,ErrorLZeroBlockSizeIsNotAllowed);
 OldPos := Position;
 OldPos1 := Stream.Position;
 Stream.Position := FromPosition;
 Size := 0;
 Position := 0;
 FAbort := False;
 if (FOperation = cpsopNone) then
  begin
   FOperation := cpsopLoadFromStream;
   FProgressOperation := cpsopLoadFromStream;
  end;
 DoOnProgress(0,cpsopLoadFromStream,FAbort);
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
      raise ECPSException.Create(10004,ErrorLCannotReadFromStream,
        [Pos,Stream.Size,OutSize,ReadBytes]);

     Pos := Self.Position;
     WriteBytes := Self.Write(Buf^,OutSize);
     if (WriteBytes <> OutSize) then
      raise ECPSException.Create(10005,ErrorLCannotWriteToStream,
        [Pos,Self.Size,OutSize,WriteBytes]);

     FProgressMax := Stream.Size;
     FProgress := Stream.Position;
     DoOnProgress(FProgress/FProgressMax*100.0,cpsopLoadFromStream,FAbort);
    end;
 finally
   MemoryManager.FreeAndNilMem(Buf);
   Position := OldPos;
   Stream.Position := OldPos1;
   FOperation := cpsopNone;
   FProgressOperation := cpsopNone;
 end;
 if (not FAbort) then
  DoOnProgress(100.0,cpsopLoadFromStream,FAbort);
end; // LoadFromStreamWithPosition


//------------------------------------------------------------------------------
// load all data from file
//------------------------------------------------------------------------------
procedure TCPSStream.LoadFromFile(const FileName: AnsiString);
var
  Stream: TCPSStream;
begin
  Stream := TCPSFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end; // LoadFromFile


//------------------------------------------------------------------------------
// save all data to file
//------------------------------------------------------------------------------
procedure TCPSStream.SaveToFile(const FileName: AnsiString);
var
  Stream: TCPSStream;
begin
  Stream := TCPSFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end; // SaveToFile


{$IFDEF D6H}
procedure TCPSStream.LoadFromFile(const FileName: WideString);
var
  Stream: TCPSStream;
begin
  Stream := TCPSFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end; // LoadFromFile


procedure TCPSStream.SaveToFile(const FileName: WideString);
var
  Stream: TCPSStream;
begin
  Stream := TCPSFileStream.Create(FileName, fmCreate);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end; // SaveToFile


{$ELSE}
procedure TCPSStream.LoadFromFile(const FileName: WideString; Dummy: ByteBool);
var
  Stream: TCPSStream;
begin
  Stream := TCPSFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite, Dummy);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end; // LoadFromFile


procedure TCPSStream.SaveToFile(const FileName: WideString; Dummy: ByteBool);
var
  Stream: TCPSStream;
begin
  Stream := TCPSFileStream.Create(FileName, fmCreate, Dummy);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end; // SaveToFile
{$ENDIF}


//------------------------------------------------------------------------------
// save data to stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveData(var Data; DataSize: Integer; ErrorCode: Integer);
var OldPos:     Int64;
    WriteBytes: Integer;
begin
  try
    OldPos := Position;
    WriteBytes := Write(Data,DataSize);
  except
    on e: Exception do
     begin
      raise ECPSException.Create(ErrorCode,ErrorLCannotSaveData,
        [IntToHex(Integer(Self),8),Self.ClassName,OldPos,Size,DataSize,WriteBytes,e.Message]);
     end;
  end;
  if (WriteBytes <> DataSize) then
    raise ECPSException.Create(ErrorCode,ErrorLCannotSaveData,
      [IntToHex(Integer(Self),8),Self.ClassName,OldPos,Size,DataSize,WriteBytes,'']);
end; // SaveData


//------------------------------------------------------------------------------
// load data from stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadData(var Data; DataSize: Integer; ErrorCode: Integer);
var OldPos:    Int64;
    ReadBytes: Integer;
begin
 try
  OldPos := Position;
  ReadBytes := Read(Data,DataSize);
 except
    on e: Exception do
     begin
      raise ECPSException.Create(ErrorCode,ErrorLCannotLoadData,
        [IntToHex(Integer(Self),8),Self.ClassName,OldPos,Size,DataSize,ReadBytes,e.Message]);
     end;
 end;
 if (ReadBytes <> DataSize) then
   raise ECPSException.Create(ErrorCode,ErrorLCannotLoadData,
     [IntToHex(Integer(Self),8),Self.ClassName,OldPos,Size,DataSize,ReadBytes,'']);
end; // LoadData


//------------------------------------------------------------------------------
// save ShortString to stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveShortString(Value: ShortString; ErrorCode: Integer);
var l: Byte;
begin
  l := Length(Value);
  SaveData(l,SizeOf(l),ErrorCode);
  if (l > 0) then
   SaveData(Value[1],l,ErrorCode);
end; // SaveShortString


//------------------------------------------------------------------------------
// load ShortString from stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadShortString(var Value: ShortString; ErrorCode: Integer);
var l: Byte;
begin
  LoadData(l,SizeOf(l),ErrorCode);
  Value[0] := AnsiChar(l);
  if (l > 0) then
   LoadData(Value[1],l,ErrorCode);
end; // LoadShortString


//------------------------------------------------------------------------------
// save AnsiString to stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveAnsiString(Value: AnsiString; ErrorCode: Integer);
var l: Integer;
begin
  l := Length(Value);
  SaveData(l,SizeOf(l),ErrorCode);
  if (l > 0) then
   SaveData(Value[1],l,ErrorCode);
end; // SaveAnsiString


//------------------------------------------------------------------------------
// load AnsiString from stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadAnsiString(var Value: AnsiString; ErrorCode: Integer);
var l: Integer;
begin
  LoadData(l,SizeOf(l),ErrorCode);
  SetLength(Value,l);
  if (l > 0) then
   LoadData(Value[1],l,ErrorCode);
end; // LoadAnsiString


//------------------------------------------------------------------------------
// save WideString to stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveWideString(Value: WideString; ErrorCode: Integer);
var l: Integer;
begin
  l := Length(Value) * 2;
  SaveData(l,SizeOf(l),ErrorCode);
  if (l > 0) then
   SaveData(Value[1],l,ErrorCode);
end; // SaveWideString


//------------------------------------------------------------------------------
// load WideString from stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadWideString(var Value: WideString; ErrorCode: Integer);
var l: Integer;
begin
  LoadData(l,SizeOf(l),ErrorCode);
  SetLength(Value,(l div 2));
  if (l > 0) then
   LoadData(Value[1],l,ErrorCode);
end; // LoadWideString


//------------------------------------------------------------------------------
// save String to stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveString(Value: String; ErrorCode: Integer = 0);
begin
  {$IFDEF D12H}
  SaveWideString(WideString(Value),ErrorCode);
  {$ELSE}
  SaveAnsiString(AnsiString(Value),ErrorCode);
  {$ENDIF}
end; // SaveString


//------------------------------------------------------------------------------
// load String from stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadString(var Value: String; ErrorCode: Integer = 0);
{$IFDEF D12H}
var v: WideString;
{$ENDIF}
begin
  {$IFDEF D12H}
  LoadWideString(v,ErrorCode);
  Value := v;
  {$ELSE}
  LoadAnsiString(AnsiString(Value),ErrorCode);
  {$ENDIF}

end; // LoadString


//------------------------------------------------------------------------------
// save Boolean to stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveBoolean(Value: Boolean; ErrorCode: Integer);
var b: ByteBool;
begin
  b := Value;
  SaveData(b,SizeOf(b),ErrorCode);
end; // SaveBoolean


//------------------------------------------------------------------------------
// load Boolean from stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadBoolean(var Value: Boolean; ErrorCode: Integer);
var b: ByteBool;
begin
  LoadData(b,SizeOf(b),ErrorCode);
  Value := b;
end; // LoadBoolean


//------------------------------------------------------------------------------
// save Integer to Stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveInteger(Value: Integer; ErrorCode: Integer);
begin
  SaveData(Value,SizeOf(Value),ErrorCode);
end; // SaveInteger


//------------------------------------------------------------------------------
// load Integer from Stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadInteger(var Value: Integer; ErrorCode: Integer);
begin
  LoadData(Value,SizeOf(Value),ErrorCode);
end; // LoadInteger


//------------------------------------------------------------------------------
// save Cardinal to Stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveCardinal(Value: Cardinal; ErrorCode: Integer);
begin
  SaveData(Value,SizeOf(Value),ErrorCode);
end; // SaveCardinal


//------------------------------------------------------------------------------
// load Cardinal from Stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadCardinal(var Value: Cardinal; ErrorCode: Integer);
begin
  LoadData(Value,SizeOf(Value),ErrorCode);
end; // LoadCardinal


//------------------------------------------------------------------------------
// save Integer to Stream
//------------------------------------------------------------------------------
procedure TCPSStream.SaveInt64(Value: Int64; ErrorCode: Integer);
begin
  SaveData(Value,SizeOf(Value),ErrorCode);
end; // SaveInteger


//------------------------------------------------------------------------------
// load Integer from Stream
//------------------------------------------------------------------------------
procedure TCPSStream.LoadInt64(var Value: Int64; ErrorCode: Integer);
begin
  LoadData(Value,SizeOf(Value),ErrorCode);
end; // LoadInt64


////////////////////////////////////////////////////////////////////////////////
//
// TCPSAdvancedStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// DoOnProgress
//------------------------------------------------------------------------------
procedure TCPSAdvancedStream.DoOnProgress(Progress: Double; Operation: TCPSOperation; var Abort: Boolean);
begin
 if (not Assigned(FOnProgress)) then
  begin
   if (FManager <> nil) then
    if (Assigned(TCPSManager(FManager).OnProgress)) then
     TCPSManager(FManager).OnProgress(Self,Progress,Operation,Abort);
  end
 else
  inherited;
end; // DoOnProgress


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
constructor TCPSAdvancedStream.Create(Manager: TComponent; TempDir: WideString);
begin
  inherited Create;
  FManager := nil;
  FReadOnly := False;
  if (TempDir = '') then
   FTempDir := CPSGetDefaultTempDir
  else
   FTempDir := TempDir;
  if (Manager <> nil) then
   if (Manager is TCPSManager) then
    begin
     FManager := Manager;
     TCPSManager(FManager).Add(Self);
    end;
end; // Create


//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TCPSAdvancedStream.Destroy;
begin
  if (Length(FCryptoParams.Password) > 0) then
   begin
    FillChar(FCryptoParams.Password[1],Length(FCryptoParams.Password),$FF);
    FCryptoParams.Password := '';
   end;
  FillChar(FCryptoParams,SizeOf(FCryptoParams),$00);
  if (FManager <> nil) then
    TCPSManager(FManager).Remove(Self);
  inherited;
end; // Destory


////////////////////////////////////////////////////////////////////////////////
//
// TCPSMemoryStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return pointer to memory
//------------------------------------------------------------------------------
function TCPSMemoryStream.GetMemory: Pointer;
begin
  Result := FBuffer;
end; // GetMemory


//------------------------------------------------------------------------------
// return maximum value of FReallocDelta
//------------------------------------------------------------------------------
function TCPSMemoryStream.GetMaxDelta: Int64;
begin
  if (FBufferSize <= 0) then
   Result := 4
  else
  if (FBufferSize = 4) then
   Result := 1020
  else
   Result := CPSGetReallocDelta(FBufferSize);
end; // GetMaxDelta


//------------------------------------------------------------------------------
// sets new realloc delta with range check
//------------------------------------------------------------------------------
procedure TCPSMemoryStream.SetReallocDelta(const NewDelta: Int64);
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
procedure TCPSMemoryStream.InternalSetSize(const NewSize: Int64);
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
       if (CPS_ENCRYPTED_DB_USED) then
        FillChar(FBuffer^,FBufferSize,$00);
       MemoryManager.FreeAndNilMem(FBuffer);
      end;
     // reset all parameters
     FBufferSize := 0;
     FSize := 0;
     FReallocDelta := 0;
     FFastReallocCount := 0;
    end
   else
   if (FBufferSize = 0) then
    begin
     if (NewSize <= 1024) then
      FBufferSize := 1024
     else
      FBufferSize := NewSize;
     FBuffer := MemoryManager.GetMem(FBufferSize);
     FSize := NewSize;
     FFastReallocCount := 0;
    end
   else
    begin
     MaxDelta := GetMaxDelta;
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
function TCPSMemoryStream.InternalSeek(NewPosition: Int64): Int64;
begin
 FPosition := NewPosition;
 result := FPosition;
end; // InternalSeek


//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TCPSMemoryStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TCPSMemoryStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TCPSMemoryStream.Read(var Buffer; Count: Longint): Longint;
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
function TCPSMemoryStream.Write(const Buffer; Count: Longint): Longint;
begin
 if (FSize < FPosition + Int64(Count)) then
  InternalSetSize(FPosition + Count);
 Result := Count;
 System.Move(Buffer,PAnsiChar(FBuffer + FPosition)^,Count);
 Inc(FPosition,Count);
end; // Write


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
function TCPSMemoryStream.Seek(Offset: Longint; Origin: Word): Longint;
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
function TCPSMemoryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
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
constructor TCPSMemoryStream.Create(Manager: TComponent);
begin
 FBuffer := nil;
 FBufferSize := 0;
 FSize := 0;
 FReallocDelta := 0;
 FFastReallocCount := 0;
 FPosition := 0;
 inherited Create;
 if (Manager <> nil) then
  if (Manager is TCPSManager) then
   begin
    FManager := Manager;
    TCPSManager(FManager).Add(Self);
   end;
end; // Create


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
destructor TCPSMemoryStream.Destroy;
begin
 InternalSetSize(0);
 if (FManager <> nil) then
  TCPSManager(FManager).Remove(Self);
 inherited;
end; // Destroy


////////////////////////////////////////////////////////////////////////////////
//
// TCPSFileStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// convert open file mode to access mode and share mode
//------------------------------------------------------------------------------
procedure TCPSFileStream.ConvertFileModes(
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
procedure TCPSFileStream.InternalSetSize(const NewSize: Int64);
var OldPos: Int64;
{$IFDEF LINUX}
  SysErrorCode: DWORD;
{$ENDIF}
begin
 if (FReadOnly) then
  raise ECPSException.Create(10092,ErrorLReadOnly);
 OldPos := Position;
 Position := NewSize;
{$IFDEF MSWINDOWS}
 Win32Check(SetEndOfFile(FHandle));
{$ENDIF}
{$IFDEF LINUX}
 if (lseek64(FHandle, NewSize, SEEK_SET) <> NewSize) then
   begin
     SysErrorCode := GetLastError;
     raise ECPSException.Create(10006, ErrorLCannotSetNewSize,
            [FHandle, Size, NewSize, SysErrorCode, SysErrorMessage(SysErrorCode)]);
   end;
 if ftruncate(FHandle, Position) = -1 then
   begin
     SysErrorCode := GetLastError;
     raise ECPSException.Create(10007, ErrorLCannotSetNewSize,
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
procedure TCPSFileStream.SetSize(NewSize: Longint);
begin
 InternalSetSize(NewSize);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// sets new size of the stream
//------------------------------------------------------------------------------
procedure TCPSFileStream.SetSize(const NewSize: Int64);
begin
 InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// read
//------------------------------------------------------------------------------
function TCPSFileStream.Read(var Buffer; Count: Longint): Longint;
begin
 Result := FileRead(FHandle, Buffer, Count);
 if (Result = -1) then
  Result := 0;
end; // SetSize


//------------------------------------------------------------------------------
// write
//------------------------------------------------------------------------------
function TCPSFileStream.Write(const Buffer; Count: Longint): Longint;
begin
 if (FReadOnly) then
  raise ECPSException.Create(10093,ErrorLReadOnly);
 Result := FileWrite(FHandle, Buffer, Count);
 if (Result = -1) then
  Result := 0;
end; // SetSize


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TCPSFileStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
 Result := FileSeek(FHandle, Offset, Origin);
end; // SetSize


{$IFDEF D6H}
//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TCPSFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 Result := FileSeek(FHandle, Offset, Ord(Origin));
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TCPSFileStream.Create(const FileName: AnsiString; Mode: Word; Manager: TComponent);
var ShareMode, AccessMode, CreateMode: Cardinal;
begin
 FManager := nil;
 FBlockSize := CPSDefaultBlockSize;
 FMode := Mode;
 FFileName := FileName;
 FUnicodeFileName := WideString(FileName);
 ConvertFileModes(Mode,AccessMode,ShareMode,CreateMode);
 FHandle := Integer(Windows.CreateFileA(
                                PAnsiChar(FileName),
                                AccessMode,
                                ShareMode,
                                nil,
                                CreateMode,
                                FAttrFlags,
                                0
                             ));

 if (FHandle = Integer(INVALID_HANDLE_VALUE)) then
  raise ECPSException.Create(10099,ErrorLCannotCreateFile,[FileName,Mode,GetLastError()]);
 inherited Create;
 if (Manager <> nil) then
  if (Manager is TCPSManager) then
   begin
    FManager := Manager;
    TCPSManager(FManager).Add(Self);
   end;
end; // Create

{$IFDEF D6H}
//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TCPSFileStream.Create(const FileName: WideString; Mode: Word; Manager: TComponent);
var ShareMode, AccessMode, CreateMode: Cardinal;
begin
 FManager := nil;
 FBlockSize := CPSDefaultBlockSize;
 FMode := Mode;
 FUnicodeFileName := FileName;
 FFileName := AnsiString(FileName);
 ConvertFileModes(Mode,AccessMode,ShareMode,CreateMode);
 FHandle := Integer(Windows.CreateFileW(
                                PWideChar(FileName),
                                AccessMode,
                                ShareMode,
                                nil,
                                CreateMode,
                                FAttrFlags,
                                0
                             ));

 if (FHandle = Integer(INVALID_HANDLE_VALUE)) then
  raise ECPSException.Create(10008,ErrorLCannotCreateFile,[FileName,Mode,GetLastError()]);
 inherited Create;
 if (Manager <> nil) then
  if (Manager is TCPSManager) then
   begin
    FManager := Manager;
    TCPSManager(FManager).Add(Self);
   end;
end; // Create
{$ELSE}
//------------------------------------------------------------------------------
// Create
//------------------------------------------------------------------------------
constructor TCPSFileStream.Create(const FileName: WideString; Mode: Word; Dummy: ByteBool; Manager: TComponent);
var ShareMode, AccessMode, CreateMode: Cardinal;
begin
 FManager := nil;
 FBlockSize := CPSDefaultBlockSize;
 FMode := Mode;
 FUnicodeFileName := FileName;
 FFileName := AnsiString(FileName);
 ConvertFileModes(Mode,AccessMode,ShareMode,CreateMode);
 FHandle := Integer(Windows.CreateFileW(
                                PWideChar(FileName),
                                AccessMode,
                                ShareMode,
                                nil,
                                CreateMode,
                                FAttrFlags,
                                0
                             ));

 if (FHandle = Integer(INVALID_HANDLE_VALUE)) then
  raise ECPSException.Create(10008,ErrorLCannotCreateFile,[FileName,Mode,GetLastError()]);
 inherited Create;
 if (Manager <> nil) then
  if (Manager is TCPSManager) then
   begin
    FManager := Manager;
    TCPSManager(FManager).Add(Self);
   end;
end; // Create
{$ENDIF}

//------------------------------------------------------------------------------
// Destroy
//------------------------------------------------------------------------------
destructor TCPSFileStream.Destroy;
begin
 if (FHandle <> Integer(INVALID_HANDLE_VALUE)) then
  CloseHandle(FHandle);
 if (FManager <> nil) then
  TCPSManager(FManager).Remove(Self);
 inherited;
end; // Destroy


//------------------------------------------------------------------------------
// flush OS file buffers
//------------------------------------------------------------------------------
procedure TCPSFileStream.FlushFileBuffers;
var
  SysErrorCode: DWORD;
begin
 if (FHandle <> Integer(INVALID_HANDLE_VALUE)) then
  begin
    {$IFDEF MSWINDOWS}
      if (not Windows.FlushFileBuffers(FHandle)) then
    {$ENDIF}
    {$IFDEF LINUX}
    // There is no need to flush buffers because the only low-level input and output
    // functions that operate on file descriptors are used.
    // If open with O_SYNC:
      if (Libc.fsync(FHandle) = -1) then
    {$ENDIF}
        begin
          SysErrorCode := GetLastError;
          raise ECPSException.Create(10040, ErrorLFlushFileBuffers,
                           [FFileName,  SysErrorCode, SysErrorMessage(SysErrorCode)]);
        end;
  end;
end; // FlushFileBuffers


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCryptoPressStream - stream supporing compression and encryption
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// Get ratio
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.GetRatio: Double;
var FCompressedSize:        Int64;
begin
  FCompressedSize := GetCompressedSize;
  if ((FCompressionAlgorithm = caNone) or
      (FUncompressedSize = 0) or
      (FUncompressedSize <= FCompressedSize)) then
   Result := 0
  else
   begin
    Result := (FUncompressedSize - FCompressedSize);
    Result := Result / FUncompressedSize * 100.0;
   end;
end; // GetRatio


//------------------------------------------------------------------------------
// Get compressed size
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.GetCompressedSize: Int64;
begin
  Result := FBaseStream.Size - FOffestToHeader;
end; // GetCompressedSize


//------------------------------------------------------------------------------
// Get header size
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.GetHeaderSize: Integer;
begin
  Result := FHeader.HeaderSize;
end; // GetHeaderSize


//------------------------------------------------------------------------------
// Return true if stream is encrypted
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.GetEncrypted: Boolean;
begin
  Result := FEncrypted;
end; // GetEncrypted


//------------------------------------------------------------------------------
// return direct access stream
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.GetDirectAccessStream: TStream;
begin
  Result := FBaseStream;
end; // GetDirectAccessStream


//------------------------------------------------------------------------------
// load  block FHeaders
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.LoadHeaders(LoadStreamHeader: Boolean);
var cHeader:  TCPSHeader;
    pos:      Int64;
    i:        Integer;
begin
  Lock;
  try
    if (LoadStreamHeader) then
     begin
      FOffestToHeader := CPSGetOffsetToStreamHeader(FBaseStream);
      if (FOffestToHeader < 0) then
       raise ECPSException.Create(10046,ErrorLInvalidStream);
      FBaseStream.Position := FOffestToHeader;
      LoadDataFromStream(FHeader,SizeOf(FHeader),FBaseStream,10047);
      FCompressionAlgorithm := TCPSCompressionAlgorithm(FHeader.CompressionAlgorithm);
      FCompressionMode := FHeader.CompressionMode;
      FCryptoParams.CryptoAlgorithm := FHeader.CryptoHeader.CryptoAlgorithm;
      FCryptoParams.CryptoMode := FHeader.CryptoHeader.CryptoMode;
      FBlockSize := FHeader.BlockSize;
      FCompressed := (FCompressionAlgorithm <> caNone);
      FEncrypted := (FCryptoParams.CryptoAlgorithm <> CPS_Cipher_None);
      if (FHeader.Signature = CPSSignaturev1) and (FEncrypted) then
       raise ECPSException.Create(10098,ErrorLCannotDecryptCPS1Data);
      if (FCryptoParams.CryptoAlgorithm <> CPS_Cipher_None) then
       begin
        if (not CPSIsKeyValid(FHeader.CryptoHeader,FCryptoParams)) then
         raise ECPSException.Create(10048,ErrorLInvalidCryptoKeyInfo);
       end;
      FOffsetToFirstBlock := FBaseStream.Position + FHeader.HeaderSize;
     end;
    FBaseStream.Position := FOffsetToFirstBlock;
    FHeaders.SetSize(0);
    if (FCompressionAlgorithm = caNone) then
     FUncompressedSize := FBaseStream.Size - FOffsetToFirstBlock
    else
     begin
       FUncompressedSize := 0;
       for i := 0 to FHeader.NumBlocks-1 do
        begin
         if (FBaseStream.Size - FBaseStream.Position < CPSHeaderSize) then
          begin
           // cut compressed file (end of file was cut)
           // repair this error
           FBaseStream.Size := FBaseStream.Position;
           FHeader.NumBlocks := i;
           FHeaders.SetSize(i);
           SaveStreamHeader;
           break;
          end;
         pos := FBaseStream.Position;
         LoadDataFromStream(cHeader,SizeOf(cHeader),FBaseStream,10049);
         Inc(FUncompressedSize,cHeader.UncompressedSize);
         FHeaders.AppendItem(cHeader,pos);
         FBaseStream.Position := FBaseStream.Position + CHeader.NextHeaderOffset;
        end;
     end;
  finally
    Unlock;
  end;
end; //LoadHeaders


//------------------------------------------------------------------------------
// create and write all headers for the new stream
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.CreateHeaders(Header: PAnsiChar; HeaderSize: Integer);
var Buffer: PAnsiChar;
begin
 FHeader.Signature := CPSSignature;
 FHeader.BlockSize := FBlockSize;
 FHeader.NumBlocks := 0;
 FHeader.Version := CPSVersion;
 FHeader.CompressionAlgorithm := Byte(FCompressionAlgorithm);
 FHeader.CompressionMode := FCompressionMode;
 FHeader.HeaderSize := HeaderSize;
 FHeader.CryptoHeader := CPSCreateCryptoHeader(FCryptoParams);
 SaveStreamHeader;
 if (HeaderSize > 0) then
  begin
   if (FCryptoParams.CryptoAlgorithm = CPS_Cipher_None) then
    SaveDataToStream(Header^,HeaderSize,FBaseStream,10042)
   else
    begin
     Buffer := MemoryManager.GetMem(HeaderSize);
     try
       Move(Header^,Buffer^,HeaderSize);
       CPSEncryptBuffer(FCryptoParams,Buffer,HeaderSize);
       SaveDataToStream(Buffer^,HeaderSize,FBaseStream,10050);
     finally
       MemoryManager.FreeAndNilMem(Buffer);
     end;
    end; // encrypted header
  end;
 FModified := False;
 FUncompressedSize := 0;
 FOffsetToFirstBlock := FBaseStream.Position;
end; // CreateHeaders


//------------------------------------------------------------------------------
// save stream header
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.SaveStreamHeader;
begin
  FBaseStream.Position := FOffestToHeader;
  SaveDataToStream(FHeader,SizeOf(FHeader),FBaseStream,10041);
end; //SaveHeader


//------------------------------------------------------------------------------
// clear temp buffer
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.ClearTempBuffer;
var FileName: AnsiString;
begin
 if (FTempStream <> nil) then
  begin
   if (FTempStream is TCPSFileStream) then
    FileName := TCPSFileStream(FTempStream).FileName
   else
    FileName := '';
   FTempStream.Free;
   if (FileName <> '') then
    SysUtils.DeleteFile(FileName);
  end;
 FTempStream := nil;
 if (FLastBuffer <> nil) then
  begin
   CPSFreeMem(FLastBuffer);
   FLastBuffer := nil;
  end;
end;


//------------------------------------------------------------------------------
// load block from stream
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.LoadBlock(BlockNumber: Integer): PAnsiChar;
var
   Size, inSize, outSize: Integer;
   inBuf,
   outBuf:                PAnsiChar;
begin
  Result := FCache.FindCachedBlock(BlockNumber);
  if (Result = nil) then
   begin
    Result := FCache.GetNewBlock(BlockNumber);
    if (Result = nil) then
     raise ECPSException.Create(10052,ErrorLNilPointer);
    if (BlockNumber = (FUncompressedSize div FBlockSize)) then
     Size := FUncompressedSize - Int64(BlockNumber) * Int64(FBlockSize)
    else
     Size := FBlockSize;
    if (not FCompressed) then
     begin
      FBaseStream.Position := FOffsetToFirstBlock + BlockNumber * FBlockSize;
      LoadDataFromStream(Result^,Size,FBaseStream,10051);
      if (FEncrypted) then
       CPSDecryptBuffer(FCryptoParams,Result,Size);
     end // not compressed
    else
     begin
      FCurrentBlock := BlockNumber;
      if ((FCurrentBlock < 0) or (FCurrentBlock >= FHeaders.ItemCount)) then
       raise ECPSException.Create(10057,ErrorLInvalidBlockNumber,[FCurrentBlock,FHeaders.ItemCount]);
      FBaseStream.Position := FHeaders.Positions[FCurrentBlock]+SizeOf(TCPSHeader);
      inSize := FHeaders.Items[FCurrentBlock].CompressedSize;
      outSize := FHeaders.Items[FCurrentBlock].UncompressedSize;
      if (outSize > FBlockSize) then
       raise ECPSException.Create(10053,ErrorLInvalidOutSize,[outSize,FBlockSize]);
      inBuf := MemoryManager.GetMem(inSize);
      try
        LoadDataFromStream(inBuf^,inSize,FBaseStream,10054);
        if (FEncrypted) then
         begin
//if (BlockNumber<=0) then aaWriteBufferToLog(inBuf,inSize,'load.enc');
          CPSDecryptBuffer(FCryptoParams,inBuf,inSize);
//if (BlockNumber<=0) then aaWriteBufferToLog(inBuf,InSize,'load.dec');
          if (CPSCountCRC16(0,inBuf,inSize) <> FHeaders.Items[FCurrentBlock].CRC16) then
           raise ECPSException.Create(10056,ErrorLInvalidCryptoKeyInfo);
         end;
        CPSInternalDecompressBuffer(TCPSCompressionAlgorithm1(FCompressionAlgorithm),
                                    inBuf,inSize,outBuf,outSize);
        if (outBuf = nil) then
         raise ECPSException.Create(10055,ErrorLNilPointer);
      finally
        MemoryManager.FreeAndNilMem(inBuf);
      end;
      Move(outBuf^,Result^,outSize);
      CPSFreeMem(outBuf);
     end; // compressed
   end;
end; // LoadBlock


//------------------------------------------------------------------------------
// return false if compressed stream should start extending as new block have larger compressed size
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.SaveBlock(BlockNumber:    Integer;
                        Buffer:        PAnsiChar;
                        BufferSize:    Integer;
                        ForceRewrite:  Boolean = false
                       ): Boolean;
var
    outBuf:  PAnsiChar;
    outSize: Integer;
begin
 Result := True;
 if (BufferSize <= 0) then
  raise ECPSException.Create(10061,ErrorLInvalidBufferSize,[BufferSize]);
 if ((BlockNumber < 0) or (BlockNumber > FHeader.NumBlocks)) then
  raise ECPSException.Create(10062,ErrorLInvalidBlockNumber,[BlockNumber,FHeader.NumBlocks]);
 if (not FCompressed) then
  begin
   if (BlockNumber = FHeader.NumBlocks) then
    Inc(FHeader.NumBlocks);
   FBaseStream.Position := FOffsetToFirstBlock + Int64(BlockNumber) * Int64(FBlockSize);
   if (not FEncrypted) then
    begin
     SaveDataToStream(Buffer^,BufferSize,FBaseStream,10058);
    end // not encrypted
   else
    begin
     outBuf := MemoryManager.GetMem(BufferSize);
     try
       Move(Buffer^,outBuf^,BufferSize);
//if (BlockNumber<=0) then aaWriteBufferToLog(OutBuf,BufferSize,'save.src');
       CPSEncryptBuffer(FCryptoParams,outBuf,BufferSize);
//if (BlockNumber<=0) then aaWriteBufferToLog(OutBuf,BufferSize,'save.enc');
       SaveDataToStream(outBuf^,BufferSize,FBaseStream,10060);
     finally
       MemoryManager.FreeAndNilMem(outBuf);
     end;
    end; // encrypted
  end // not compressed stream
 else
  begin
   CPSInternalCompressBuffer(TCPSCompressionAlgorithm1(FCompressionAlgorithm),
                             FCompressionMode,
                             Buffer,BufferSize,
                             outBuf,outSize);
   try
     if (outBuf = nil) then
      raise ECPSException.Create(10064,ErrorLNilPointer);
     if (not ForceRewrite) then
      if (BlockNumber < FHeaders.ItemCount-1) then
       if (outSize > FHeaders.Items[BlockNumber].NextHeaderOffset) then
        begin
         Result := False;
         ClearTempBuffer;
         FLastBuffer := outBuf;
         FLastSize := outSize;
        end;
     if (Result) then
      begin
       if (BlockNumber >= FHeaders.ItemCount) then
        begin
         FHeaders.SetSize(BlockNumber+1);
         Inc(FHeader.NumBlocks);
         if (BlockNumber = 0) then
          FHeaders.Positions[BlockNumber] := FOffsetToFirstBlock
         else
          FHeaders.Positions[BlockNumber] := FHeaders.Positions[BlockNumber-1] +
            SizeOf(TCPSHeader) + FHeaders.Items[BlockNumber-1].CompressedSize;
         FHeaders.Items[BlockNumber].NextHeaderOffset := outSize;
        end;
       if (ForceRewrite) then
        FHeaders.Items[BlockNumber].NextHeaderOffset := outSize;
       if (FEncrypted) then
        begin
         FHeaders.Items[BlockNumber].CRC16 := CPSCountCRC16(0,outBuf,outSize);
//if (BlockNumber<=0) then aaWriteBufferToLog(OutBuf,OutSize,'save.src');
         CPSEncryptBuffer(FCryptoParams,outBuf,outSize);
//if (BlockNumber<=0) then aaWriteBufferToLog(OutBuf,OutSize,'save.enc');
        end;
       FHeaders.Items[BlockNumber].UncompressedSize := BufferSize;
       FHeaders.Items[BlockNumber].CompressedSize := outSize;
       FBaseStream.Position := FHeaders.Positions[BlockNumber];
       SaveDataToStream(FHeaders.Items[BlockNumber],SizeOf(TCPSHeader),FBaseStream,10067);
       SaveDataToStream(outBuf^,outSize,FBaseStream,10068);
      end;
   finally
    if (Result) then
     CPSFreeMem(outBuf);
   end;
  end; // compressed stream
end; // SaveBlock


//------------------------------------------------------------------------------
// seek in compressed stream
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.InternalSeek(Offset: Int64; Origin: Word): Int64;
begin
 case Origin of
  soFromBeginning: FCurrentPosition := Offset;
  soFromEnd: FCurrentPosition := FUncompressedSize + Offset;
  soFromCurrent: Inc(FCurrentPosition,Offset);
 end;
 if (FCurrentPosition < 0) then
  FCurrentPosition := 0;
 Result := FCurrentPosition;
end; // InternalSeek


//------------------------------------------------------------------------------
// decrease size of compressed stream
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.DecreaseSize(const NewSize: Int64);
var NewBlockNumber: Integer;
    NewBlockSize:   Integer;
    BlockData:      PAnsiChar;
begin
  FHeader.NumBlocks := NewSize div FBlockSize +
                      Integer((NewSize mod FBlockSize) > 0);
  NewBlockNumber := FHeader.NumBlocks-1;
  NewBlockSize := NewSize mod FBlockSize;
  if (NewBlockSize > 0) then
   begin
    BlockData := LoadBlock(NewBlockNumber);
    if (FCompressed) then
     begin
      FHeaders.SetSize(FHeader.NumBlocks);
      if (FHeader.NumBlocks <= 0) then
       FBaseStream.Size := FOffsetToFirstBlock
      else
       FBaseStream.Size := FHeaders.Positions[NewBlockNumber];
     end
    else
     begin
      FBaseStream.Size := FOffsetToFirstBlock + NewSize;
     end;
    SaveBlock(NewBlockNumber,BlockData,NewBlockSize);
   end
  else
   begin
    if (FCompressed) then
     begin
      FHeaders.SetSize(FHeader.NumBlocks);
      if (FHeaders.Items[NewBlockNumber].NextHeaderOffset <>
          FHeaders.Items[NewBlockNumber].CompressedSize) then
       begin
        FHeaders.Items[NewBlockNumber].NextHeaderOffset :=
          FHeaders.Items[NewBlockNumber].CompressedSize;
        FBaseStream.Position := FHeaders.Positions[NewBlockNumber];
        SaveDataToStream(FHeaders.Items[NewBlockNumber],SizeOf(TCPSHeader),FBaseStream,10069);
       end;
      FBaseStream.Size := FHeaders.Positions[NewBlockNumber] + SizeOf(TCPSHeader)+ 
                            FHeaders.Items[NewBlockNumber].CompressedSize;
     end // compressed
    else
      FBaseStream.Size := FOffsetToFirstBlock + NewSize;
   end;
  FUncompressedSize := NewSize;
end; // DecreaseSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.IncreaseSize(const NewSize: Int64);
var CurrentBlockSize,i:    Integer;
    BlockData:             PAnsiChar;
    OldBlockNo,NewBlockNo: Integer;
begin
  OldBlockNo := FHeader.NumBlocks - 1;
  if ((FUncompressedSize mod FBlockSize) > 0) then
   begin
    BlockData := LoadBlock(OldBlockNo);
    if (NewSize >= (Int64(FHeader.NumBlocks) * Int64(FBlockSize))) then
      CurrentBlockSize := FBlockSize
    else
      CurrentBlockSize := NewSize mod FBlockSize;
    SaveBlock(OldBlockNo,BlockData,CurrentBlockSize);
    FUncompressedSize := Int64(FHeader.NumBlocks - 1) * Int64(FBlockSize) + CurrentBlockSize;
   end; // Change size of the last block
  NewBlockNo := NewSize div FBlockSize + Integer((NewSize mod FBlockSize) > 0)-1;
  if (NewBlockNo > OldBlockNo) then
   begin
    BlockData := MemoryManager.AllocMem(FBlockSize);
    try
      i := OldBlockNo + 1;
      while ((not FAbort) and (i <= NewBlockNo)) do
       begin
        if ((i < NewBlockNo) or ((NewSize mod FBlockSize) = 0)) then
          CurrentBlockSize := FBlockSize
        else
          CurrentBlockSize := NewSize mod FBlockSize;
        SaveBlock(i,BlockData,CurrentBlockSize);
        Inc(FUncompressedSize,CurrentBlockSize);
        FProgress := i-OldBlockNo;
        FProgress := FProgress / (NewBlockNo - OldBlockNo) * 100.0;
        DoOnProgress(FProgress,cpsopSetSize,FAbort);
        Inc(i);
       end;
    finally
      MemoryManager.FreeAndNilMem(BlockData);
    end;
   end;
end; // IncreaseSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.InternalSetSize(const NewSize: Int64);
begin
 Lock;
 try
   if (FReadOnly) then
    raise ECPSException.Create(10070,ErrorLReadOnly);
   if (NewSize = FUncompressedSize) then
    Exit;
   FModified := True; 
   FAbort := False;
   DoOnProgress(0,cpsopSetSize,FAbort);
   if ((NewSize = 0) or ((not FCompressed) and (not FEncrypted))) then
    begin
      FUncompressedSize := NewSize;
      FBaseStream.Size := FOffsetToFirstBlock + FUncompressedSize;
      if (FCompressed) and (NewSize = 0) then
       FHeaders.SetSize(0);
    end
   else
    begin
      if (NewSize < FUncompressedSize) then
       DecreaseSize(NewSize)
      else
       IncreaseSize(NewSize);
    end;
   if (FCurrentPosition > FUncompressedSize) then
    FCurrentPosition := FUncompressedSize;
   FHeader.NumBlocks := FUncompressedSize div FBlockSize +
                        Integer((FUncompressedSize mod FBlockSize) > 0);
   if ((FCompressed) and (FHeader.NumBlocks <> FHeaders.ItemCount)) then
    raise ECPSException.Create(10063,ErrorLInvalidBlockNumber,[FHeader.NumBlocks,FHeaders.ItemCount]);
   SaveStreamHeader;
   DoOnProgress(100,cpsopSetSize,FAbort);
 finally
   Unlock;
 end;
end; // InternalSetSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.SetSize(NewSize: Longint);
begin
  InternalSetSize(NewSize);
end; // SetSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
{$IFDEF D6H}
procedure TCPSCryptoPressStream.SetSize(const NewSize: Int64);
begin
  InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// read from compressed stream
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.Read(var Buffer; Count: Longint): Longint;
var BlockData:               PAnsiChar;
    StartOffset,
    CurrentBlockSize,
    CopySize:                Integer;
begin
  Lock;
  try
    Result := 0;
    if ((FCurrentPosition >= FUncompressedSize) or (Count <= 0)) then
     Exit;
    if (FCurrentPosition < FUncompressedSize) then
     FCurrentBlock := FCurrentPosition div FBlockSize;
    StartOffset := FCurrentPosition mod FBlockSize;
    FAbort := False;
    DoOnProgress(0,cpsopRead,FAbort);
    while ((not FAbort) and (Result < Count) and (FCurrentPosition < FUncompressedSize)) do
     begin
      BlockData := LoadBlock(FCurrentBlock);
      if (Int64(FCurrentBlock+1) * Int64(FBlockSize) >= FUncompressedSize) then
       CurrentBlockSize := FUncompressedSize - Int64(FCurrentBlock) * Int64(FBlockSize)
      else
       CurrentBlockSize := FBlockSize;
      CopySize := CurrentBlockSize - StartOffset;
      if (CopySize > (Count - Result)) then
       CopySize := Count - Result;
      if (CopySize <= 0) then
       break;
      Move(PAnsiChar(BlockData+StartOffset)^,PAnsiChar(PAnsiChar(@Buffer)+Result)^,CopySize);
      if (StartOffset > 0) then
       StartOffset := 0;
      Inc(Result,CopySize);
      Inc(FCurrentPosition,CopySize);
      Inc(FCurrentBlock);
      FProgress := Result;
      FProgress := FProgress * 100.0 / Count;
      DoOnProgress(FProgress,cpsopRead,FAbort);
     end;
    if (Result = Count) then
     DoOnProgress(100,cpsopRead,FAbort);
  finally
    Unlock;
  end;
end; // Read


//------------------------------------------------------------------------------
// write to compressed stream
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.Write(const Buffer; Count: Longint): Longint;
var BlockData:               PAnsiChar;
    StartOffset,
    CurrentBlockSize,
    CopySize:                Integer;
    RewriteEnd,
    ForceRewrite,
    Res, b:                  Boolean;
    FirstWriteBlockNo:       Integer;
    LastWriteBlockNo:        Integer;
    LastWriteBlockData:      PAnsiChar;
    NewSize,LastPosition:    Int64;
    MaxSize:                 Integer;

 procedure InitializeRewriteEnd;
 var TempSize: Int64;
     i:        Integer;
     TempBuf:  PAnsiChar;
 begin
  if (not FCompressed) then
   raise ECPSException.Create(10074,ErrorLNotCompressedStream);
  if (FLastBuffer = nil) then
   raise ECPSException.Create(10078,ErrorLNilPointer);
  if (LastWriteBlockNo >= FHeaders.ItemCount) then
   raise ECPSException.Create(10075,ErrorLInvalidLastBlockNo,[LastWriteBlockNo,FHeaders.ItemCount]);
  RewriteEnd := True;
  TempSize := 0;
  MaxSize := -1;
  for i := LastWriteBlockNo+1 to FHeaders.ItemCount - 1 do
   begin
    Inc(TempSize,FHeaders.Items[i].CompressedSize);
    if (MaxSize < 0) or (MaxSize < FHeaders.Items[i].CompressedSize) then
     MaxSize := FHeaders.Items[i].CompressedSize;
   end;
  if (TempSize > FMaxTempBufferSize) then
   FTempStream := TCPSFileStream.Create(CPSGetTempFileName(FTempDir),fmCreate)
  else
   FTempStream := TCPSMemoryStream.Create;
  if (MaxSize <= 0) then
   raise ECPSException.Create(10073,ErrorLInvalidMaxSize,[MaxSize,LastWriteBlockNo,FHeaders.ItemCount]);
  TempBuf := MemoryManager.GetMem(MaxSize);
  try
    for i := LastWriteBlockNo+1 to FHeaders.ItemCount - 1 do
     begin
      FBaseStream.Position := FHeaders.Positions[i] + SizeOf(TCPSHeader);
      LoadDataFromStream(TempBuf^,FHeaders.Items[i].CompressedSize,FBaseStream,10076);
      SaveDataToStream(TempBuf^,FHeaders.Items[i].CompressedSize,FTempStream,10077);
     end;
  finally
    MemoryManager.FreeAndNilMem(TempBuf);
  end;
  if ((LastPosition mod FBlockSize) > 0) then
   begin
    // load last block data - for partial rewriting
    BlockData := LoadBlock(LastWriteBlockNo);
    LastWriteBlockData := MemoryManager.GetMem(FBlockSize);
    Move(BlockData^,LastWriteBlockData^,FBlockSize);
   end;

  // save current block
  FHeaders.Items[FCurrentBlock].UncompressedSize := CurrentBlockSize;
  FHeaders.Items[FCurrentBlock].CompressedSize := FLastSize;
  FHeaders.Items[FCurrentBlock].NextHeaderOffset := FLastSize;
  if (FEncrypted) then
    begin
     FHeaders.Items[FCurrentBlock].CRC16 := CPSCountCRC16(0,FLastBuffer,FLastSize);
     CPSEncryptBuffer(FCryptoParams,FLastBuffer,FLastSize);
    end;
  FBaseStream.Position := FHeaders.Positions[FCurrentBlock];
  SaveDataToStream(FHeaders.Items[FCurrentBlock],SizeOf(TCPSHeader),FBaseStream,10079);
  SaveDataToStream(FLastBuffer^,FLastSize,FBaseStream,10080);
  CPSFreeMem(FLastBuffer);
  FLastBuffer := nil;
 end; // InitializeRewriteEnd

 procedure FinalizeRewriteEnd;
 var
     TempSize,i: Integer;
     TempBuf:    PAnsiChar;
 begin
  ClearCache;
  if (LastWriteBlockData <> nil) then
   begin
    CopySize := Count - Result;
    Move(PAnsiChar(PAnsiChar(@Buffer)+Result)^,PAnsiChar(LastWriteBlockData+StartOffset)^,CopySize);
    FHeaders.Positions[LastWriteBlockNo] := FBaseStream.Position;
    SaveBlock(LastWriteBlockNo,LastWriteBlockData,FBlockSize,True);
    Inc(FCurrentPosition,CopySize);
   end;
  TempBuf := MemoryManager.GetMem(MaxSize);
  try
    FTempStream.Position := 0;
    for i := LastWriteBlockNo+1 to FHeaders.ItemCount - 1 do
     begin
      TempSize := FHeaders.Items[i].CompressedSize;
      FHeaders.Items[i].NextHeaderOffset := TempSize;
      LoadDataFromStream(TempBuf^,TempSize,FTempStream,10081);
      FHeaders.Positions[i] := FBaseStream.Position;
      SaveDataToStream(FHeaders.Items[i],SizeOf(TCPSHeader),FBaseStream,10082);
      SaveDataToStream(TempBuf^,TempSize,FBaseStream,10083);
     end;
  finally
    MemoryManager.FreeAndNilMem(TempBuf);
  end;
 end; // FinalizeRewriteEnd

begin
  if (FReadOnly) then
    raise ECPSException.Create(10071,ErrorLReadOnly);
  FModified := True;
  RewriteEnd := False;
  LastWriteBlockData := nil;
  Lock;
  try
    Result := 0;
    if (Count <= 0) then
     Exit;
    LastPosition := FCurrentPosition + Int64(Count);
    ForceRewrite := (LastPosition >= FUncompressedSize);
    if (FCurrentPosition > FUncompressedSize) then
      InternalSetSize(FCurrentPosition);
    // set size was cancelled
    if (FCurrentPosition > FUncompressedSize) then
     Exit;
    NewSize := FUncompressedSize;
    if (LastPosition > FUncompressedSize) then
     NewSize := LastPosition;
    FCurrentBlock := FCurrentPosition div FBlockSize;
    FirstWriteBlockNo := FCurrentBlock;
    LastWriteBlockNo := (LastPosition-1) div FBlockSize;
    StartOffset := FCurrentPosition mod FBlockSize;
    FAbort := False;
    DoOnProgress(0,cpsopWrite,FAbort);
    while (Result < Count) do
     begin
      if (not RewriteEnd) then
       if (FAbort) then
        break;
      if ((FCurrentBlock = LastWriteBlockNo) and (RewriteEnd) and (LastWriteBlockData <> nil)) then
       begin
        break;
       end;
      if (FCurrentBlock <> LastWriteBlockNo) then
       begin
        CurrentBlockSize := FBlockSize;
        CopySize := FBlockSize - StartOffset;
       end
      else
       begin
        if (FCurrentBlock = NewSize div FBlockSize) then
         CurrentBlockSize := NewSize mod FBlockSize
        else
         CurrentBlockSize := FBlockSize;
        CopySize := Count - Result;
       end;
      b := (not ForceRewrite) and ((StartOffset > 0) or
           ((StartOffset + (Count - Result)) < CurrentBlockSize));
      if ((FCurrentBlock < FHeader.NumBlocks) and
          ((FCurrentBlock = FirstWriteBlockNo) or
          (b and (FCurrentBlock = LastWriteBlockNo)))) then
       BlockData := LoadBlock(FCurrentBlock)
      else
       // get new block from cache
       BlockData := FCache.GetNewBlock(FCurrentBlock);
      if (CopySize <= 0) then
       break;
      Move(PAnsiChar(PAnsiChar(@Buffer)+Result)^,PAnsiChar(BlockData+StartOffset)^,CopySize);
      // clear end of new block
      if (((StartOffset+CopySize) <  FBlockSize) and (FCurrentBlock >= FHeader.NumBlocks)) then
       FillChar(PAnsiChar(BlockData+CopySize+StartOffset)^,FBlockSize - CopySize - StartOffset,$00);
      if (RewriteEnd) then
       if (FCurrentBlock > 0) then
        FHeaders.Positions[FCurrentBlock] :=
         FHeaders.Positions[FCurrentBlock-1] + SizeOf(TCPSHeader) +
         FHeaders.Items[FCurrentBlock-1].NextHeaderOffset;
      if ((FCurrentBlock > FirstWriteBlockNo) and
          (RewriteEnd or ForceRewrite) and
          FCompressed) then
       FHeaders.Positions[FCurrentBlock] := FHeaders.Positions[FCurrentBlock-1] +
                                            SizeOf(TCPSHeader) +
                                            FHeaders.Items[FCurrentBlock-1].NextHeaderOffset;
      Res := SaveBlock(FCurrentBlock,BlockData,CurrentBlockSize,RewriteEnd or ForceRewrite);
      if ((not RewriteEnd) and (not Res)) then
       InitializeRewriteEnd;
      if (StartOffset > 0) then
       StartOffset := 0;
      Inc(Result,CopySize);
      Inc(FCurrentPosition,CopySize);
      Inc(FCurrentBlock);
      FProgress := Result;
      FProgress := FProgress * 100.0 / Count;
      DoOnProgress(FProgress,cpsopWrite,FAbort);
     end;
    if (RewriteEnd) then
     begin
      FinalizeRewriteEnd;
      Result := Count;
     end;
    SaveStreamHeader;
    if (Result = Count) then
     begin
      FUncompressedSize := NewSize;
      DoOnProgress(100,cpsopWrite,FAbort);
     end;
  finally
    if (RewriteEnd) then
      ClearTempBuffer;
    if (LastWriteBlockData <> nil) then
     MemoryManager.FreeAndNilMem(LastWriteBlockData);
    Unlock;
  end;
end; // Write


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result := InternalSeek(Offset,Origin);
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TCPSCryptoPressStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := InternalSeek(Offset,Word(Origin));
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TCPSCryptoPressStream.Create(
                   BaseStream:            TStream;
                   CryptoParams:          TCPSCryptoParams;
                   CreateNewStream:       Boolean;
                   FreeBaseStream:        Boolean;
                   // params used only for creating new stream
                   CompressionAlgorithm:  TCPSCompressionAlgorithm;
                   CompressionMode:       Byte;
                   BlockSize:             Integer;
                   Header:                PAnsiChar;
                   HeaderSize:            Integer;
                   Manager:               TComponent;
                   TempDir:               WideString
                  );
var num: Integer;
begin
  inherited Create(Manager,TempDir);
  FModified := False;
  FTempStream := nil;
  FLastBuffer := nil;
  FFreeBaseStream := FreeBaseStream;
  FBaseStream := BaseStream;
  FCryptoParams := CryptoParams;
  if (CreateNewStream and (HeaderSize > 0) and (Header = nil)) then
   raise ECPSException.Create(10043,ErrorLNilPointer);
  if (FManager <> nil) then
   FMaxTempBufferSize := TCPSManager(FManager).MaxTempBufferSize
  else
   FMaxTempBufferSize := CPSDefaultMaxTempBufferSize;
  if (FManager <> nil) then
   num := TCPSManager(FManager).NumCachedBlocks
  else
   num := CPSDefaultNumCachedBlocks;
  FHeaders := TCPSHeadersArray.Create;
  try
    if (CreateNewStream) then
     begin
       FCompressionAlgorithm := CompressionAlgorithm;
       FCompressionMode := CompressionMode;
       FBlockSize := BlockSize;
       FOffestToHeader := FBaseStream.Position;
       CreateHeaders(Header,HeaderSize);
     end
    else
     begin
       LoadHeaders(True);
     end;
  except
    FHeaders.Free;
    FHeaders := nil;
    raise;
  end;
  FCurrentPosition := 0;
  FCache := TCPSCache.Create(num,FBlockSize,FEncrypted);
  FCompressed := (FCompressionAlgorithm <> caNone);
  FEncrypted := (FCryptoParams.CryptoAlgorithm <> CPS_Cipher_None);
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TCPSCryptoPressStream.Destroy;
begin
  if (FHeaders <> nil) then
   FHeaders.Free;
  ClearTempBuffer;
  FCache.Free;
  if (FFreeBaseStream) then
   FBaseStream.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// load header
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.LoadHeader(Header: PAnsiChar);
begin
  if (Header = nil) then
   raise ECPSException.Create(10065,ErrorLNilPointer);
  FBaseStream.Position := FOffestToHeader + SizeOf(FHeader);
  LoadDataFromStream(Header^,FHeader.HeaderSize,FBaseStream,10066);
  if (FEncrypted) then
    CPSDecryptBuffer(FCryptoParams,Header,FHeader.HeaderSize);
end; // LoadHeader


//------------------------------------------------------------------------------
// clear cache
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.ClearCache;
begin
  FCache.Clear;
end; // ClearCache


//------------------------------------------------------------------------------
// change parameters
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.ChangeParameters(
                          NewCompressionAlgorithm: TCPSCompressionAlgorithm;
                          NewCompressionMode:       Byte;
                          NewCryptoParams:          TCPSCryptoParams
                        );
begin
  raise ECPSException.Create(10084,ErrorLOperationIsNotSupported);
end; // ChangeParameters


//------------------------------------------------------------------------------
// refresh stream - reload headers
//------------------------------------------------------------------------------
procedure TCPSCryptoPressStream.Refresh;
begin
  ClearCache;
  LoadHeaders(True);
  FModified := False;
end; // Refresh


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCryptoPressMemoryStream - memory stream based on TCPSCryptoPressStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return pointer to memory
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.GetMemory: Pointer;
begin
  Result := TCPSMemoryStream(FCryptoPressStream.DirectAccessStream).Memory;
end; // GetMemory


//------------------------------------------------------------------------------
// get memory size
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.GetMemorySize: Integer;
begin
  Result := TCPSMemoryStream(FCryptoPressStream.DirectAccessStream).Size;
end; // GetMemorySize


//------------------------------------------------------------------------------
// Get ratio
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.GetRatio: Double;
begin
  Result := FCryptoPressStream.Ratio;
end; // GetRatio


//------------------------------------------------------------------------------
// Get compressed size
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.GetCompressedSize: Int64;
begin
  Result := FCryptoPressStream.CompressedSize;
end; // GetCompressedSize


//------------------------------------------------------------------------------
// Get header size
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.GetHeaderSize: Integer;
begin
  Result := FCryptoPressStream.HeaderSize;
end; // GetHeaderSize


//------------------------------------------------------------------------------
// Return true if stream is encrypted
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.GetEncrypted: Boolean;
begin
  Result := FCryptoPressStream.Encrypted;
end; // GetEncrypted


//------------------------------------------------------------------------------
// return direct access stream
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.GetDirectAccessStream: TStream;
begin
  Result := FCryptoPressStream.DirectAccessStream;
end; // GetDirectAccessStream


//------------------------------------------------------------------------------
// seek in compressed stream
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.InternalSeek(Offset: Int64; Origin: Word): Int64;
begin
 Result := FCryptoPressStream.InternalSeek(Offset,Origin);
end; // InternalSeek


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TCPSCryptoPressMemoryStream.InternalSetSize(const NewSize: Int64);
begin
 Lock;
 try
   if (FReadOnly) then
    raise ECPSException.Create(10086,ErrorLReadOnly);
   FCryptoPressStream.OnProgress := FOnProgress;
   FCryptoPressStream.Operation := FOperation;
   FCryptoPressStream.ProgressOperation := FProgressOperation;
   FCryptoPressStream.Size := NewSize;
 finally
   Unlock;
 end;
end; // InternalSetSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TCPSCryptoPressMemoryStream.SetSize(NewSize: Longint);
begin
  InternalSetSize(NewSize);
end; // SetSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
{$IFDEF D6H}
procedure TCPSCryptoPressMemoryStream.SetSize(const NewSize: Int64);
begin
  InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// read from compressed stream
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.Read(var Buffer; Count: Longint): Longint;
begin
  Lock;
  try
    FCryptoPressStream.OnProgress := FOnProgress;
    FCryptoPressStream.Operation := FOperation;
    FCryptoPressStream.ProgressOperation := FProgressOperation;
    Result := FCryptoPressStream.Read(Buffer,Count);
  finally
    Unlock;
  end;
end; // Read


//------------------------------------------------------------------------------
// write to compressed stream
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.Write(const Buffer; Count: Longint): Longint;
begin
  Lock;
  try
    FCryptoPressStream.OnProgress := FOnProgress;
    FCryptoPressStream.Operation := FOperation;
    FCryptoPressStream.ProgressOperation := FProgressOperation;
    Result := FCryptoPressStream.Write(Buffer,Count);
  finally
    Unlock;
  end;
end; // Write


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result := InternalSeek(Offset,Origin);
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TCPSCryptoPressMemoryStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := InternalSeek(Offset,Word(Origin));
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TCPSCryptoPressMemoryStream.Create;
begin
  FCryptoParams.CryptoAlgorithm := CPS_Cipher_None;
  Create(FCryptoParams,caNone,0);
end; // Create


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TCPSCryptoPressMemoryStream.Create(
                       CryptoParams:          TCPSCryptoParams;
                       // params used only for creating new stream
                       CompressionAlgorithm:  TCPSCompressionAlgorithm;
                       CompressionMode:       Byte;
                       BlockSize:             Integer;
                       Header:                PAnsiChar;
                       HeaderSize:            Integer;
                       Manager:               TComponent;
                       TempDir:               WideString
                  );
var ms: TCPSMemoryStream;
begin
  inherited Create(Manager,TempDir);
  FModified := False;
  FBlockSize := BlockSize;
  FCryptoParams := CryptoParams;
  ms := TCPSMemoryStream.Create;
  FCryptoPressStream := TCPSCryptoPressStream.Create(ms,CryptoParams,True,True,
                                                     CompressionAlgorithm,
                                                     CompressionMode,
                                                     BlockSize,
                                                     Header,HeaderSize,
                                                     Manager,TempDir);
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TCPSCryptoPressMemoryStream.Destroy;
begin
  FCryptoPressStream.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// load header
//------------------------------------------------------------------------------
procedure TCPSCryptoPressMemoryStream.LoadHeader(Header: PAnsiChar);
begin
  if (Header = nil) then
   raise ECPSException.Create(10085,ErrorLNilPointer);
  FCryptoPressStream.LoadHeader(Header);
end; // LoadHeader


//------------------------------------------------------------------------------
// clear cache
//------------------------------------------------------------------------------
procedure TCPSCryptoPressMemoryStream.ClearCache;
begin
  FCryptoPressStream.ClearCache;
end; // ClearCache


//------------------------------------------------------------------------------
// change parameters
//------------------------------------------------------------------------------
procedure TCPSCryptoPressMemoryStream.ChangeParameters(
                          NewCompressionAlgorithm: TCPSCompressionAlgorithm;
                          NewCompressionMode:      Byte;
                          NewCryptoParams:         TCPSCryptoParams
                        );
var newMS:       TCPSMemoryStream;
    newCS:       TCPSCryptoPressStream;
    aHeader:     PAnsiChar;
    aHeaderSize: Integer;
begin
  aHeader := nil;
  aHeaderSize := FCryptoPressStream.HeaderSize;
  if (aHeaderSize > 0) then
   begin
    aHeader := MemoryManager.GetMem(aHeaderSize);
    FCryptoPressStream.LoadHeader(aHeader);
   end;
  try
    newMS := TCPSMemoryStream.Create;
    newCS := TCPSCryptoPressStream.Create(newMS,NewCryptoParams,True,True,
                                          NewCompressionAlgorithm,
                                          NewCompressionMode,
                                          BlockSize,
                                          aHeader,aHeaderSize,
                                          FManager,FTempDir);
    SaveToStream(newCS);
    FCryptoPressStream.Free;
    FCryptoPressStream := newCS;
    FCompressionAlgorithm := NewCompressionAlgorithm;
    FCryptoParams := NewCryptoParams;
    FCompressionMode := NewCompressionMode;
  finally
   if (aHeader <> nil) then
    MemoryManager.FreeAndNilMem(aHeader);
  end;
end; // ChangeParameters


//------------------------------------------------------------------------------
// refresh stream - reload headers
//------------------------------------------------------------------------------
procedure TCPSCryptoPressMemoryStream.Refresh;
begin
  FCryptoPressStream.Refresh;
end; // Refresh


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCryptoPressFileStream - file stream based on TCPSCryptoPressStream
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// return handle
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.GetHandle: Integer;
begin
  Result := TCPSFileStream(FCryptoPressStream.DirectAccessStream).Handle;
end; // GetHandle


//------------------------------------------------------------------------------
// return mode
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.GetMode: Word;
begin
  Result := TCPSFileStream(FCryptoPressStream.DirectAccessStream).Mode;
end; // GetMode


//------------------------------------------------------------------------------
// return file name
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.GetFileName: AnsiString;
begin
  Result := TCPSFileStream(FCryptoPressStream.DirectAccessStream).FileName;
end; // GetFileName


//------------------------------------------------------------------------------
// Get ratio
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.GetRatio: Double;
begin
  Result := FCryptoPressStream.Ratio;
end; // GetRatio


//------------------------------------------------------------------------------
// Get compressed size
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.GetCompressedSize: Int64;
begin
  Result := FCryptoPressStream.CompressedSize;
end; // GetCompressedSize


//------------------------------------------------------------------------------
// Get header size
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.GetHeaderSize: Integer;
begin
  Result := FCryptoPressStream.HeaderSize;
end; // GetHeaderSize


//------------------------------------------------------------------------------
// Return true if stream is encrypted
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.GetEncrypted: Boolean;
begin
  Result := FCryptoPressStream.Encrypted;
end; // GetEncrypted


//------------------------------------------------------------------------------
// return direct access stream
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.GetDirectAccessStream: TStream;
begin
  Result := FCryptoPressStream.DirectAccessStream;
end; // GetDirectAccessStream


//------------------------------------------------------------------------------
// seek in compressed stream
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.InternalSeek(Offset: Int64; Origin: Word): Int64;
begin
 Result := FCryptoPressStream.InternalSeek(Offset,Origin);
end; // InternalSeek


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TCPSCryptoPressFileStream.InternalSetSize(const NewSize: Int64);
begin
 Lock;
 try
   if (FReadOnly) then
    raise ECPSException.Create(10086,ErrorLReadOnly);
   FCryptoPressStream.OnProgress := FOnProgress;
   FCryptoPressStream.Operation := FOperation;
   FCryptoPressStream.ProgressOperation := FProgressOperation;
   FCryptoPressStream.Size := NewSize;
 finally
   Unlock;
 end;
end; // InternalSetSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
procedure TCPSCryptoPressFileStream.SetSize(NewSize: Longint);
begin
  InternalSetSize(NewSize);
end; // SetSize


//------------------------------------------------------------------------------
// set size of compressed stream
//------------------------------------------------------------------------------
{$IFDEF D6H}
procedure TCPSCryptoPressFileStream.SetSize(const NewSize: Int64);
begin
  InternalSetSize(NewSize);
end; // SetSize
{$ENDIF}


//------------------------------------------------------------------------------
// read from compressed stream
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.Read(var Buffer; Count: Longint): Longint;
begin
  Lock;
  try
    FCryptoPressStream.OnProgress := FOnProgress;
    FCryptoPressStream.Operation := FOperation;
    FCryptoPressStream.ProgressOperation := FProgressOperation;
    Result := FCryptoPressStream.Read(Buffer,Count);
  finally
    Unlock;
  end;
end; // Read


//------------------------------------------------------------------------------
// write to compressed stream
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.Write(const Buffer; Count: Longint): Longint;
begin
  Lock;
  try
    FCryptoPressStream.OnProgress := FOnProgress;
    FCryptoPressStream.Operation := FOperation;
    FCryptoPressStream.ProgressOperation := FProgressOperation;
    Result := FCryptoPressStream.Write(Buffer,Count);
  finally
    Unlock;
  end;
end; // Write


//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.Seek(Offset: Longint; Origin: Word): Longint;
begin
  Result := InternalSeek(Offset,Origin);
end; // Seek


{$IFDEF D6H}
//------------------------------------------------------------------------------
// seek
//------------------------------------------------------------------------------
function TCPSCryptoPressFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := InternalSeek(Offset,Word(Origin));
end; // Seek
{$ENDIF}


//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TCPSCryptoPressFileStream.Create(const FileName: AnsiString; Mode: Word);
begin
  FCryptoParams.CryptoAlgorithm := CPS_Cipher_None;
  Create(FileName,Mode,FCryptoParams,caNone,0);
end; // Create


{$IFDEF D6H}
//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TCPSCryptoPressFileStream.Create(const FileName: WideString; Mode: Word);
begin
  FCryptoParams.CryptoAlgorithm := CPS_Cipher_None;
  Create(FileName,Mode,FCryptoParams,caNone,0);
end; // Create
{$ELSE}
//------------------------------------------------------------------------------
// create
//------------------------------------------------------------------------------
constructor TCPSCryptoPressFileStream.Create(const FileName: WideString; Mode: Word; Dummy: ByteBool);
begin
  FCryptoParams.CryptoAlgorithm := CPS_Cipher_None;
  Create(FileName,Mode,FCryptoParams,caNone,0);
end; // Create
{$ENDIF}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TCPSCryptoPressFileStream.Create(
                       const FileName:        AnsiString;
                       Mode:                  Word;
                       CryptoParams:          TCPSCryptoParams;
                       // params used only for creating new stream
                       CompressionAlgorithm:  TCPSCompressionAlgorithm;
                       CompressionMode:       Byte;
                       BlockSize:             Integer;
                       Header:                PAnsiChar;
                       HeaderSize:            Integer;
                       Manager:               TComponent;
                       TempDir:               WideString
                  );
var fs: TCPSFileStream;
    CreateNew: Boolean;
begin
  inherited Create(Manager,TempDir);
  CreateNew := (Mode = fmCreate);
  FModified := False;
  FBlockSize := BlockSize;
  FCryptoParams := CryptoParams;
  fs := TCPSFileStream.Create(FileName,Mode);
  FCryptoPressStream := TCPSCryptoPressStream.Create(fs,CryptoParams,CreateNew,True,
                                                     CompressionAlgorithm,
                                                     CompressionMode,
                                                     BlockSize,
                                                     Header,HeaderSize,
                                                     Manager,TempDir);
end; // Create


{$IFDEF D6H}
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TCPSCryptoPressFileStream.Create(
                       const FileName:        WideString;
                       Mode:                  Word;
                       CryptoParams:          TCPSCryptoParams;
                       // params used only for creating new stream
                       CompressionAlgorithm:  TCPSCompressionAlgorithm;
                       CompressionMode:       Byte;
                       BlockSize:             Integer;
                       Header:                PAnsiChar;
                       HeaderSize:            Integer;
                       Manager:               TComponent;
                       TempDir:               WideString
                  );
var fs: TCPSFileStream;
    CreateNew: Boolean;
begin
  inherited Create(Manager,TempDir);
  CreateNew := (Mode = fmCreate);
  FModified := False;
  FBlockSize := BlockSize;
  FCryptoParams := CryptoParams;
  fs := TCPSFileStream.Create(FileName,Mode);
  FCryptoPressStream := TCPSCryptoPressStream.Create(fs,CryptoParams,CreateNew,True,
                                                     CompressionAlgorithm,
                                                     CompressionMode,
                                                     BlockSize,
                                                     Header,HeaderSize,
                                                     Manager,TempDir);
end; // Create
{$ELSE}
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TCPSCryptoPressFileStream.Create(
                       const FileName:        WideString;
                       Mode:                  Word;
                       Dummy:                 ByteBool;
                       CryptoParams:          TCPSCryptoParams;
                       // params used only for creating new stream
                       CompressionAlgorithm:  TCPSCompressionAlgorithm;
                       CompressionMode:       Byte;
                       BlockSize:             Integer;
                       Header:                PAnsiChar;
                       HeaderSize:            Integer;
                       Manager:               TComponent;
                       TempDir:               WideString
                  );
var fs: TCPSFileStream;
    CreateNew: Boolean;
begin
  inherited Create(Manager,TempDir);
  CreateNew := (Mode = fmCreate);
  FModified := False;
  FBlockSize := BlockSize;
  FCryptoParams := CryptoParams;
  fs := TCPSFileStream.Create(FileName,Mode,Dummy);
  FCryptoPressStream := TCPSCryptoPressStream.Create(fs,CryptoParams,CreateNew,True,
                                                     CompressionAlgorithm,
                                                     CompressionMode,
                                                     BlockSize,
                                                     Header,HeaderSize,
                                                     Manager,TempDir);
end; // Create
{$ENDIF}

//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TCPSCryptoPressFileStream.Destroy;
begin
  FCryptoPressStream.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// FlushFileBuffers
//------------------------------------------------------------------------------
procedure TCPSCryptoPressFileStream.FlushFileBuffers;
begin
  FCryptoPressStream.ClearCache;
  TCPSFileStream(FCryptoPressStream.DirectAccessStream).FlushFileBuffers;
end; // FlushFileBuffers


//------------------------------------------------------------------------------
// load header
//------------------------------------------------------------------------------
procedure TCPSCryptoPressFileStream.LoadHeader(Header: PAnsiChar);
begin
  if (Header = nil) then
   raise ECPSException.Create(10087,ErrorLNilPointer);
  FCryptoPressStream.LoadHeader(Header);
end; // LoadHeader


//------------------------------------------------------------------------------
// clear cache
//------------------------------------------------------------------------------
procedure TCPSCryptoPressFileStream.ClearCache;
begin
  FCryptoPressStream.ClearCache;
end; // ClearCache


//------------------------------------------------------------------------------
// change parameters
//------------------------------------------------------------------------------
procedure TCPSCryptoPressFileStream.ChangeParameters(
                          NewCompressionAlgorithm: TCPSCompressionAlgorithm;
                          NewCompressionMode:      Byte;
                          NewCryptoParams:         TCPSCryptoParams
                        );
var newFS:       TCPSFileStream;
    newCS:       TCPSCryptoPressStream;
    aHeader:     PAnsiChar;
    aHeaderSize: Integer;
    TempName:    AnsiString;
    OldName:     AnsiString;
    newMode:     Word;
begin
  aHeader := nil;
  aHeaderSize := FCryptoPressStream.HeaderSize;
  if (aHeaderSize > 0) then
   begin
    aHeader := MemoryManager.GetMem(aHeaderSize);
    FCryptoPressStream.LoadHeader(aHeader);
   end;
  try
    newMode := GetMode;
    oldName := GetFileName;
    repeat
     TempName := 'CPS'+IntToStr(Random(MaxInt));
    until (not FileExists(ExtractFilePath(oldName)+TempName));
    if (newMode = fmCreate) then
     newMode := fmOpenReadWrite or fmShareExclusive;
    newFS := TCPSFileStream.Create(ExtractFilePath(oldName)+TempName,fmCreate);
    newCS := TCPSCryptoPressStream.Create(newFS,NewCryptoParams,True,True,
                                          NewCompressionAlgorithm,
                                          NewCompressionMode,
                                          BlockSize,
                                          aHeader,aHeaderSize,
                                          FManager,FTempDir);
    SaveToStream(newCS);
    newCS.Free;
    FCryptoPressStream.Free;
    if (not SysUtils.DeleteFile(oldName)) then
     raise ECPSException.Create(10088,ErrorLCannotDeleteFile,[oldName]);
    if (not SysUtils.RenameFile(ExtractFilePath(oldName)+TempName,oldName)) then
     raise ECPSException.Create(10089,ErrorLCannotRenameFile,[ExtractFilePath(oldName)+TempName,oldName]);
    newFS := TCPSFileStream.Create(oldName,newMode);
    FCryptoPressStream := TCPSCryptoPressStream.Create(newFS,NewCryptoParams,False,True);
    FCompressionAlgorithm := NewCompressionAlgorithm;
    FCryptoParams := NewCryptoParams;
    FCompressionMode := NewCompressionMode;
  finally
   if (aHeader <> nil) then
    MemoryManager.FreeAndNilMem(aHeader);
  end;
end; // ChangeParameters


//------------------------------------------------------------------------------
// refresh stream - reload headers
//------------------------------------------------------------------------------
procedure TCPSCryptoPressFileStream.Refresh;
begin
  FCryptoPressStream.Refresh;
end; // Refresh


////////////////////////////////////////////////////////////////////////////////
//
// TCPSCryptoParamsEditor
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TCPSCryptoParamsEditor.Create;
begin
  inherited;
  FPassword := CPSDefaultPassword;
  FKeyInfo.KeySize := CPS_MAX_KEY+1;
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
destructor TCPSCryptoParamsEditor.Destroy;
begin
  FillChar(FKeyInfo,SizeOf(FKeyInfo),$00);
  FillChar(FInitVector,SizeOf(FInitVector),$00);
  if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
  FPassword := '';
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// set CryptoParams
//------------------------------------------------------------------------------
procedure TCPSCryptoParamsEditor.SetCryptoParams(Params: TCPSCryptoParams);
begin
  FUseInitVector := Params.UseInitVector;
  FKeyInfo := Params.KeyInfo;
  Move(Params.InitVector[0],FInitVector[0],MaxInitVectorSize);
  if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
  FPassword := Params.Password;
{$IFDEF ENCRYPTION_ON}
  case Params.CryptoAlgorithm of
    CPS_Cipher_None:          FCryptoAlgorithm := craNone;
    CPS_Cipher_Rijndael_128:  FCryptoAlgorithm := craRijndael_128;
    CPS_Cipher_Rijndael_256:  FCryptoAlgorithm := craRijndael_256;
    CPS_Cipher_Blowfish:      FCryptoAlgorithm := craBlowfish;
    CPS_Cipher_Twofish_128:   FCryptoAlgorithm := craTwofish_128;
    CPS_Cipher_Twofish_256:   FCryptoAlgorithm := craTwofish_256;
    CPS_Cipher_Square:        FCryptoAlgorithm := craSquare;
    CPS_Cipher_Des_Single_8:  FCryptoAlgorithm := craDES_Single_8;
    CPS_Cipher_Des_Double_8:  FCryptoAlgorithm := craDES_Double_8;
    CPS_Cipher_Des_Double_16: FCryptoAlgorithm := craDES_Double_16;
    CPS_Cipher_Des_Triple_8:  FCryptoAlgorithm := craDES_Triple_8;
    CPS_Cipher_Des_Triple_16: FCryptoAlgorithm := craDES_Triple_16;
    CPS_Cipher_Des_Triple_24: FCryptoAlgorithm := craDES_Triple_24;
  end;
  case Params.CryptoMode of
    CPS_Cipher_Mode_CTS:    FCryptoMode := acmCTS;
    CPS_Cipher_Mode_CBC:    FCryptoMode := acmCBC;
    CPS_Cipher_Mode_CFB:    FCryptoMode := acmCFB;
    CPS_Cipher_Mode_OFB:    FCryptoMode := acmOFB;
{$IFDEF ENCRYPTION_DEC5}
    CPS_Cipher_Mode_CFS:    FCryptoMode := acmCFS;
    CPS_Cipher_Mode_ECB:    FCryptoMode := acmECB;
    CPS_Cipher_Mode_CFB8:   FCryptoMode := acmCFB8;
    CPS_Cipher_Mode_OFB8:   FCryptoMode := acmOFB8;
    CPS_Cipher_Mode_CFS8:   FCryptoMode := acmCFS8;
{$ENDIF}
  end;
{$ELSE}
FCryptoAlgorithm := craNone;
FCryptoMode := acmCTS;
{$ENDIF}
end; // SetCryptoParams


//------------------------------------------------------------------------------
// GetCryptoParams
//------------------------------------------------------------------------------
function TCPSCryptoParamsEditor.GetCryptoParams: TCPSCryptoParams;
begin
  Result.UseInitVector := FUseInitVector;
  Result.KeyInfo := FKeyInfo;
  Move(FInitVector[0],Result.InitVector[0],FInitVectorSize);
  Result.InitVectorSize := FInitVectorSize;
  Result.Password := FPassword;
{$IFDEF ENCRYPTION_ON}
  case FCryptoAlgorithm of
    craNone:               Result.CryptoAlgorithm := CPS_Cipher_None;
    craRijndael_128:       Result.CryptoAlgorithm := CPS_Cipher_Rijndael_128;
    craRijndael_256:       Result.CryptoAlgorithm := CPS_Cipher_Rijndael_256;
    craBlowfish:           Result.CryptoAlgorithm := CPS_Cipher_Blowfish;
    craTwofish_128:        Result.CryptoAlgorithm := CPS_Cipher_Twofish_128;
    craTwofish_256:        Result.CryptoAlgorithm := CPS_Cipher_Twofish_256;
    craSquare:             Result.CryptoAlgorithm := CPS_Cipher_Square;
    craDES_Single_8:       Result.CryptoAlgorithm := CPS_Cipher_Des_Single_8;
    craDES_Double_8:       Result.CryptoAlgorithm := CPS_Cipher_Des_Double_8;
    craDES_Double_16:      Result.CryptoAlgorithm := CPS_Cipher_Des_Double_16;
    craDES_Triple_8:       Result.CryptoAlgorithm := CPS_Cipher_Des_Triple_8;
    craDES_Triple_16:      Result.CryptoAlgorithm := CPS_Cipher_Des_Triple_16;
    craDES_Triple_24:      Result.CryptoAlgorithm := CPS_Cipher_Des_Triple_24;
  end;
  case FCryptoMode of
    acmCTS:   Result.CryptoMode := CPS_Cipher_Mode_CTS;
    acmCBC:   Result.CryptoMode := CPS_Cipher_Mode_CBC;
    acmCFB:   Result.CryptoMode := CPS_Cipher_Mode_CFB;
    acmOFB:   Result.CryptoMode := CPS_Cipher_Mode_OFB;
    acmCFS:   Result.CryptoMode := CPS_Cipher_Mode_CFS;
    acmECB:   Result.CryptoMode := CPS_Cipher_Mode_ECB;
    acmCFB8:  Result.CryptoMode := CPS_Cipher_Mode_CFB8;
    acmOFB8:  Result.CryptoMode := CPS_Cipher_Mode_OFB8;
    acmCFS8:  Result.CryptoMode := CPS_Cipher_Mode_CFS8;
  end;
{$ELSE}
Result.CryptoAlgorithm := CPS_Cipher_None;
Result.CryptoMode := CPS_Cipher_Mode_CTS;
{$ENDIF}
end;// GetCryptoParams


function TCPSCryptoParamsEditor.GetInitVectorValue(Index: Integer): Byte;
begin
 if (Index < 0) or (Index >= MaxInitVectorSize) then
  raise ECPSException.Create(10010,ErrorLInvalidVectorIndex,[Index,MaxInitVectorSize]);
 Result := FInitVector[Index];
end; // FInitVector


procedure TCPSCryptoParamsEditor.SetInitVectorValue(Index: Integer; Value: Byte);
begin
 if (Index < 0) or (Index >= MaxInitVectorSize) then
  raise ECPSException.Create(10011,ErrorLInvalidVectorIndex,[Index,MaxInitVectorSize]);
 FInitVector[Index] := Value;
 if (Index >= FInitVectorSize) then
  FInitVectorSize := Word(Index+1);
 FUseInitVector := True;
end; // SetInitVectorValue


function TCPSCryptoParamsEditor.GetVectorSize: Integer;
begin
 Result := CPS_MAX_VECTOR+1;
end; // GetVectorSize


function TCPSCryptoParamsEditor.GetKeySize: Integer;
begin
 Result := FKeyInfo.KeySize;
end; // GetVectorSize


procedure TCPSCryptoParamsEditor.SetKeySize(Value: Integer);
begin
 if (Value < 0) or (Value > MaxKeySize) then
  raise ECPSException.Create(10012,ErrorLInvalidKeySize,[Value,MaxKeySize]);
 FKeyInfo.KeySize := Value;
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; // GetVectorSize


function TCPSCryptoParamsEditor.GetKeyValue(Index: Integer): Byte;
begin
 if (Index < 0) or (Index >= KeySize) then
  raise ECPSException.Create(10013,ErrorLInvalidKeyIndex,[Index,KeySize]);
 Result := FKeyInfo.Key[Index];
end;


procedure TCPSCryptoParamsEditor.SetKeyValue(Index: Integer; Value: Byte);
begin
 if (Index < 0) or (Index >= KeySize) then
  raise ECPSException.Create(10014,ErrorLInvalidKeyIndex,[Index,KeySize]);
 FKeyInfo.Key[Index] := Value;
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; // SetKeyValue


function TCPSCryptoParamsEditor.GetMaxKeySize: Integer;
begin
 Result := CPS_MAX_KEY+1;
end; // GetMaxKeySize


procedure TCPSCryptoParamsEditor.SetKey(Key: Pointer; KeySize: Integer);
begin
 if (KeySize < 0) or (KeySize > MaxKeySize) then
  raise ECPSException.Create(10015,ErrorLInvalidKeySize,[KeySize,MaxKeySize]);
 Move(Key^,FKeyInfo.Key[0],KeySize);
 FKeyInfo.KeySize := KeySize;
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end; //SetKey


function TCPSCryptoParamsEditor.GetKey: Pointer;
begin
 Result := @FKeyInfo.Key;
end; // GetKey


procedure TCPSCryptoParamsEditor.MakeRandomKey(KeySize: Integer);
begin
 if (KeySize < 0) or (KeySize > MaxKeySize) then
  raise ECPSException.Create(10016,ErrorLInvalidKeySize,[KeySize,MaxKeySize]);
 FKeyInfo.KeySize := KeySize;
 CPSGenerateRandomBuffer(@FKeyInfo.Key[0],KeySize);
 if (Length(FPassword) > 0) then
   FillChar(FPassword[1],Length(Password),$FF);
 FPassword := '';
end;


procedure TCPSCryptoParamsEditor.MakeRandomInitVector;
begin
  FInitVectorSize := MaxInitVectorSize;
  CPSGenerateRandomBuffer(@FInitVector[0],FInitVectorSize);
  FUseInitVector := True;
end;


procedure TCPSCryptoParamsEditor.MakeRandomInitVector(VectorSize: Word);
begin
  if (VectorSize > MaxInitVectorSize) then
    raise ECPSException.Create(10095,ErrorLInvalidVectorIndex,[VectorSize,MaxInitVectorSize]);
  CPSGenerateRandomBuffer(@FInitVector[0],VectorSize);
  FInitVectorSize := VectorSize;
  FUseInitVector := True;
end;


procedure TCPSCryptoParamsEditor.SetInitVector(Vector: Pointer; VectorSize: Word);
begin
  if (VectorSize > GetVectorSize) then
    raise ECPSException.Create(10094,ErrorLInvalidVectorIndex,[VectorSize,MaxInitVectorSize]);
  Move(Vector^, FInitVector[0], VectorSize);
  FInitVectorSize := VectorSize;
  FUseInitVector := True;
end; // SetInitVector


function TCPSCryptoParamsEditor.GetInitVector: Pointer;
begin
  Result := @FInitVector;
end; // GetInitVector


//------------------------------------------------------------------------------
// Assign
//------------------------------------------------------------------------------
procedure TCPSCryptoParamsEditor.Assign(Source: TPersistent);
begin
 if (Length(FPassword) > 0) then
  FillChar(FPassword[1],Length(Password),$FF);
 FKeyInfo := TCPSCryptoParamsEditor(Source).FKeyInfo;
 FInitVector := TCPSCryptoParamsEditor(Source).FInitVector;
 FInitVectorSize := TCPSCryptoParamsEditor(Source).FInitVectorSize;
 FPassword := TCPSCryptoParamsEditor(Source).FPassword;
 FCryptoAlgorithm := TCPSCryptoParamsEditor(Source).CryptoAlgorithm;
 FCryptoMode := TCPSCryptoParamsEditor(Source).CryptoMode;
 FUseInitVector := TCPSCryptoParamsEditor(Source).FUseInitVector;
end; // Assign


////////////////////////////////////////////////////////////////////////////////
//
// TCPSManager
//
////////////////////////////////////////////////////////////////////////////////


//------------------------------------------------------------------------------
// set Ansi TempDir
//------------------------------------------------------------------------------
procedure TCPSManager.SetTempDir(Value: AnsiString);
begin
  FTempDir := Value;
  FTempDirUnicode := WideString(Value);
end; // SetTempDir


//------------------------------------------------------------------------------
// set Unicode TempDir
//------------------------------------------------------------------------------
procedure TCPSManager.SetTempDirUnicode(Value: WideString);
begin
  FTempDirUnicode := Value;
  FTempDir := AnsiString(Value);
end; // SetTempDirUnicode


{$IFDEF D12H}
//------------------------------------------------------------------------------
// get Unicode temp dir
//------------------------------------------------------------------------------
function TCPSManager.GetTempDirUnicodeAsString: String;
begin
  Result := String(FTempDirUnicode);
end;

//------------------------------------------------------------------------------
// set Unicode temp dir
//------------------------------------------------------------------------------
procedure TCPSManager.SetTempDirUnicodeAsString(Value: String);
begin
  FTempDirUnicode := WideString(Value);
end; // SetTempDirUnicodeAsString
{$ENDIF}


//------------------------------------------------------------------------------
// set mode
//------------------------------------------------------------------------------
procedure TCPSManager.SetCompressionMode(Value: Byte);
begin
  if (FCompressionAlgorithm = caNone) then
   FCompressionMode := 0
  else
   if ((Value >= CPSMinCompressionMode) and (Value <= CPSMaxCompressionMode)) then
    FCompressionMode := Value;
end; // SetCompressionMode


//------------------------------------------------------------------------------
// set block size
//------------------------------------------------------------------------------
procedure TCPSManager.SetBlockSize(Value: Integer);
begin
  if (Value >= CPSMinBlockSize) then
   FBlockSize := Value;
end; // SetBlockSize


//------------------------------------------------------------------------------
// Set number of cached blocks
//------------------------------------------------------------------------------
procedure TCPSManager.SetNumCachedBlocks(Value: Integer);
begin
  if (Value >= CPSMinNumCachedBlocks) then
   FNumCachedBlocks := Value;
end; // SetNumCachedBlocks


//------------------------------------------------------------------------------
// Set number of cached blocks
//------------------------------------------------------------------------------
procedure TCPSManager.SetMaxTempBufferSize(Value: Integer);
begin
  if (Value >= CPSMinMaxTempBufferSize) then
   FMaxTempBufferSize := Value;
end; // SetNumCachedBlocks


//------------------------------------------------------------------------------
// Get Stream
//------------------------------------------------------------------------------
function TCPSManager.GetStream(Index: Integer): TStream;
var
  List: TList;
begin
  List := FStreams.LockList;
  try
    if ((Index < 0) or (Index >= List.Count)) then
     Result := nil
    else
     Result := List.Items[Index];
  finally
    FStreams.UnlockList;
  end;
end; // GetStream


//------------------------------------------------------------------------------
// Get streams count
//------------------------------------------------------------------------------
function TCPSManager.GetCount: Integer;
var
  List: TList;
begin
  List := FStreams.LockList;
  try
    Result := List.Count;
  finally
    FStreams.UnlockList;
  end;
end; // GetCount


//------------------------------------------------------------------------------
// compress file
//------------------------------------------------------------------------------
procedure TCPSManager.DoProgressCompressFile(
                                  Sender:     TObject;
                                  Progress:   Double;
                                  Operation:  TCPSOperation;
                                  var Abort:  Boolean
                               );
begin
  if (Assigned(FOnProgress)) then
   FOnProgress(Self,Progress,cpsopCompressFile,Abort);
end; // DoProgressCompressFile


//------------------------------------------------------------------------------
// decompress file
//------------------------------------------------------------------------------
procedure TCPSManager.DoProgressDecompressFile(
                                  Sender:     TObject;
                                  Progress:   Double;
                                  Operation:  TCPSOperation;
                                  var Abort:  Boolean
                               );
begin
  if (Assigned(FOnProgress)) then
   FOnProgress(Self,Progress,cpsopDecompressFile,Abort);
end; // DoProgressDecompressFile


//------------------------------------------------------------------------------
// current version
//------------------------------------------------------------------------------
function TCPSManager.GetCurrentVersion: AnsiString;
var c: Char;
begin
{$IFDEF D17H}
 c := FormatSettings.DecimalSeparator;
 FormatSettings.DecimalSeparator := '.';
 try
  Result := FloatToStrF(CPSVersion,ffFixed,3,2) + ' ' + CPSVersionText;
 finally
  FormatSettings.DecimalSeparator := c;
 end;
{$ELSE}
 c := DecimalSeparator;
 DecimalSeparator := '.';
 try
  Result := FloatToStrF(CPSVersion,ffFixed,3,2) + ' ' + CPSVersionText;
 finally
  DecimalSeparator := c;
 end;
{$ENDIF}
end; // GetCurrentVersion


//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
constructor TCPSManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  CPSCriticalSection.InitializeCriticalSection(FCSection);
  FStreams := TThreadList.Create;
  {$IFDEF D5H}
  FStreams.Duplicates := dupAccept;
  {$ENDIF}
  if (not IsDesignMode) then
   if (AOwner <> nil) then
    if (csDesigning in AOwner.ComponentState) then
     begin
      IsDesignMode := True;
     end;
  FCryptoParams := TCPSCryptoParamsEditor.Create;
  FCompressionAlgorithm := caZLIB;
  FCompressionMode := CPSDefaultCompressionMode;
  FBlockSize := CPSDefaultBlockSize;
  FNumCachedBlocks := CPSDefaultNumCachedBlocks;
  FMaxTempBufferSize := CPSDefaultMaxTempBufferSize;
  FTempDirUnicode := CPSGetDefaultTempDir;
  FTempDir := AnsiString(FTempDirUnicode);
  {$IFDEF TRIAL_VERSION}
  if (IsDesignMode) then
   CPStrshnm;
  {$ENDIF}
end; // Create


//------------------------------------------------------------------------------
// destructor
//------------------------------------------------------------------------------
destructor TCPSManager.Destroy;
var
  List:   TList;
  stream: TStream;
begin
  List := FStreams.LockList;
  try
    while (List.Count > 0) do
     begin
      stream := List.Items[0];
      if (stream <> nil) then
       begin
        List.Remove(stream);
        stream.Free;
       end;
     end;
  finally
    FStreams.UnlockList;
  end;

  FStreams.Free;
  CPSCriticalSection.DeleteCriticalSection(FCSection);
  FCryptoParams.Free;
  inherited;
end; // Destroy


//------------------------------------------------------------------------------
// lock
//------------------------------------------------------------------------------
procedure TCPSManager.Lock;
begin
  CPSCriticalSection.EnterCriticalSection(FCSection);
end; // Lock


//------------------------------------------------------------------------------
// unlock
//------------------------------------------------------------------------------
procedure TCPSManager.Unlock;
begin
  CPSCriticalSection.LeaveCriticalSection(FCSection);
end; // Unlock


//------------------------------------------------------------------------------
// compress buffer
//------------------------------------------------------------------------------
procedure TCPSManager.CompressBuffer(
                      InBuf:                  PAnsiChar;
                      InSize:                 Integer;
                      out OutBuf:             PAnsiChar;
                      out OutSize:            Integer;
                      SkipBufferHeader:       Boolean
                         );
var CryptoInfo:   TCPSCryptoParams;
    BufferHeader: TCPSBufferHeader;
    CompBuf:      PAnsiChar;
    CompSize:     Integer;
begin
 Lock;
 try
   if ((InBuf = nil) or (InSize <= 0)) then
    raise ECPSException.Create(10038,ErrorLNilPointer);
   if (not SkipBufferHeader) then
    begin
     BufferHeader.CompressionAlgorithm := Byte(FCompressionAlgorithm);
     BufferHeader.CryptoAlgorithm := Byte(FCryptoParams.CryptoAlgorithm);
     BufferHeader.CryptoMode := Byte(FCryptoParams.CryptoMode);
    end;
   if (FCompressionAlgorithm <> caNone) then
    begin
     if (SkipBufferHeader) then
      begin
       CPSInternalCompressBuffer(TCPSCompressionAlgorithm1(Byte(FCompressionAlgorithm)),
                                 FCompressionMode,InBuf,InSize,OutBuf,OutSize);
      end // no header
     else
      begin
       CPSInternalCompressBuffer(TCPSCompressionAlgorithm1(Byte(FCompressionAlgorithm)),
                                 FCompressionMode,InBuf,InSize,CompBuf,CompSize);
       try
         BufferHeader.UncompressedSize := InSize;
         OutSize := SizeOf(BufferHeader)+CompSize;
         GetMem(OutBuf,OutSize);
         if (FCryptoParams.CryptoAlgorithm <> craNone) then
           BufferHeader.CRC16 := CPSCountCRC16(0,CompBuf,CompSize);
         Move(BufferHeader,OutBuf^,SizeOf(BufferHeader));
         Move(CompBuf^,PAnsiChar(OutBuf+SizeOf(BufferHeader))^,CompSize);
       finally
         CPSFreeMem(CompBuf);
       end;
      end;
    end // compression
   else
    begin
     if (SkipBufferHeader) then
      begin
       OutSize := InSize;
       GetMem(OutBuf,OutSize);
       Move(InBuf^,OutBuf^,OutSize);
      end
     else
      begin
       OutSize := SizeOf(BufferHeader)+InSize;
       GetMem(OutBuf,OutSize);
       if (FCryptoParams.CryptoAlgorithm <> craNone) then
         BufferHeader.CRC16 := CPSCountCRC16(0,InBuf,InSize);
       BufferHeader.UncompressedSize := InSize;
       Move(BufferHeader,OutBuf^,SizeOf(BufferHeader));
       Move(InBuf^,PAnsiChar(OutBuf+SizeOf(BufferHeader))^,InSize);
      end;
    end; // no compression
   if (FCryptoParams.CryptoAlgorithm <> craNone) then
    begin
     CryptoInfo := FCryptoParams.GetCryptoParams;
     if (SkipBufferHeader) then
      CPSEncryptBuffer(CryptoInfo,OutBuf,OutSize)
     else
      CPSEncryptBuffer(CryptoInfo,PAnsiChar(OutBuf+SizeOf(BufferHeader)),OutSize-SizeOf(BufferHeader));
    end
 finally
   Unlock;
 end;
end; // CompressBuffer


//------------------------------------------------------------------------------
// decompress buffer
//------------------------------------------------------------------------------
procedure TCPSManager.DecompressBuffer(
                      InBuf:                  PAnsiChar;
                      InSize:                 Integer;
                      out OutBuf:             PAnsiChar;
                      out OutSize:            Integer;
                      SkipBufferHeader:       Boolean
                          );
var CryptoInfo:   TCPSCryptoParams;
    BufferHeader: TCPSBufferHeader;
    CompBuf:      PAnsiChar;
    CompSize:     Integer;
begin
 Lock;
 try
   OutBuf := nil;
   if (SkipBufferHeader) then
    begin
     if ((InBuf = nil) or (InSize <= 0)) then
      raise ECPSException.Create(10097,ErrorLNilPointer);
     if (FCryptoParams.CryptoAlgorithm <> craNone) then
      begin
       GetMem(CompBuf,InSize);
       Move(InBuf^,CompBuf^,InSize);
       CryptoInfo := FCryptoParams.GetCryptoParams;
       try
         CPSDecryptBuffer(CryptoInfo,CompBuf,InSize);
       except
         FreeMem(CompBuf);
         raise;
       end;
       if (FCompressionAlgorithm <> caNone) then
        begin
         try
          CPSInternalDecompressBuffer(TCPSCompressionAlgorithm1(FCompressionAlgorithm),
                                   CompBuf,
                                   InSize,
                                   OutBuf,OutSize);
         except
           FreeMem(CompBuf);
           raise;
         end;
        end // compression and encryption
       else
        begin
         OutBuf := CompBuf;
         OutSize := InSize;
        end; // encryption and no compression
      end // encryption
     else
      begin
       if (FCompressionAlgorithm <> caNone) then
        begin
         CPSInternalDecompressBuffer(TCPSCompressionAlgorithm1(BufferHeader.CompressionAlgorithm),
                                     InBuf,
                                     InSize,
                                     OutBuf,OutSize);
        end // compression
       else
        begin
         OutSize := InSize;
         GetMem(OutBuf,OutSize);
         Move(InBuf^,OutBuf^,InSize);
        end;
      end; // no encryption
    end // no buffer header
   else
    begin
     if ((InBuf = nil) or (InSize <= SizeOf(BufferHeader))) then
      raise ECPSException.Create(10039,ErrorLNilPointer);
     CompSize := InSize-SizeOf(BufferHeader);
     GetMem(CompBuf,CompSize);
     Move(InBuf^,BufferHeader,SizeOf(BufferHeader));
     Move(PAnsiChar(InBuf+SizeOf(BufferHeader))^,CompBuf^,CompSize);
     if (BufferHeader.CryptoAlgorithm <> Byte(craNone)) then
      begin
       CryptoInfo := FCryptoParams.GetCryptoParams;
       CryptoInfo.CryptoAlgorithm := BufferHeader.CryptoAlgorithm;
       CryptoInfo.CryptoMode := BufferHeader.CryptoMode;
       CPSDecryptBuffer(CryptoInfo,CompBuf,CompSize);
       if (BufferHeader.CRC16 <> CPSCountCRC16(0,CompBuf,CompSize)) then
        begin
         FreeMem(CompBuf);
         raise ECPSException.Create(10040,ErrorLInvalidCryptoKeyInfo);
        end;
      end;
     if (BufferHeader.CompressionAlgorithm <> Byte(caNone)) then
      begin
       OutSize := BufferHeader.UncompressedSize;
       try
         CPSInternalDecompressBuffer(TCPSCompressionAlgorithm1(BufferHeader.CompressionAlgorithm),
                                     CompBuf,
                                     CompSize,
                                     OutBuf,OutSize);
       finally
         FreeMem(CompBuf);
       end;
      end
     else
      begin
       OutSize := CompSize;
       OutBuf := CompBuf;
      end; // no compression
    end; // buffer header
 finally
   Unlock;
 end;
end; // DecompressBuffer


//------------------------------------------------------------------------------
// compress AnsiString
//------------------------------------------------------------------------------
function TCPSManager.CompressAnsiString(Source: AnsiString): AnsiString;
var OutBuf:  PAnsiChar;
    OutSize: Integer;
begin
  Lock;
  try
    CompressBuffer(PAnsiChar(Source),Length(Source),OutBuf,OutSize);
    SetLength(Result,OutSize);
    Move(OutBuf^,PAnsiChar(Result)^,OutSize);
    FreeMem(OutBuf);
  finally
    Unlock;
  end;
end; // CompressAnsiString


//------------------------------------------------------------------------------
// decompress AnsiString
//------------------------------------------------------------------------------
function TCPSManager.DecompressAnsiString(Source: AnsiString): AnsiString;
var OutBuf:  PAnsiChar;
    OutSize: Integer;
begin
  Lock;
  try
    DecompressBuffer(PAnsiChar(Source),Length(Source),OutBuf,OutSize);
    SetLength(Result,OutSize);
    Move(OutBuf^,PAnsiChar(Result)^,OutSize);
    FreeMem(OutBuf);
  finally
    Unlock;
  end;
end; // DecompressAnsiString


//------------------------------------------------------------------------------
// StringToFormat
//------------------------------------------------------------------------------
function TCPSManager.AnsiStringToFormat(Source: AnsiString; Format: TCPSStringFormat): AnsiString;
{$IFDEF ENCRYPTION_DEC5}
var fm: TDECFormat;
{$ENDIF}
begin
 {$IFDEF ENCRYPTION_DEC5}
 case Format of
  cpssfHEX:
    begin
     fm := TFormat_HEX.Create;
     try
       Result := fm.Encode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
  cpssfHEXL:
    begin
     fm := TFormat_HEXL.Create;
     try
       Result := fm.Encode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
  cpssfMIME64:
    begin
     fm := TFormat_MIME64.Create;
     try
       Result := fm.Encode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
  cpssfXX:
    begin
     fm := TFormat_XX.Create;
     try
       Result := fm.Encode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
  cpssfUU:
    begin
     fm := TFormat_UU.Create;
     try
       Result := fm.Encode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
 end;
 {$ELSE}
 case Format of
  cpssfHEX: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtHEX);
  cpssfHEXL: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtHEXL);
  cpssfMIME64: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtMIME64);
  cpssfXX: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtXX);
  cpssfUU: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtUU);
 end;
 {$ENDIF}
end; // StringToFormat


//------------------------------------------------------------------------------
// FormatToAnsiString
//------------------------------------------------------------------------------
function TCPSManager.FormatToAnsiString(Source: AnsiString; Format: TCPSStringFormat): AnsiString;
{$IFDEF ENCRYPTION_DEC5}
var fm: TDECFormat;
{$ENDIF}
begin
 {$IFDEF ENCRYPTION_DEC5}
 case Format of
  cpssfHEX:
    begin
     fm := TFormat_HEX.Create;
     try
       Result := fm.Decode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
  cpssfHEXL:
    begin
     fm := TFormat_HEXL.Create;
     try
       Result := fm.Decode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
  cpssfMIME64:
    begin
     fm := TFormat_MIME64.Create;
     try
       Result := fm.Decode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
  cpssfXX:
    begin
     fm := TFormat_XX.Create;
     try
       Result := fm.Decode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
  cpssfUU:
    begin
     fm := TFormat_UU.Create;
     try
       Result := fm.Decode(Source[1],Length(Source));
     finally
       fm.Free;
     end;
    end;
 end;
 {$ELSE}
 case Format of
  cpssfHEX: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtHEX);
  cpssfHEXL: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtHEXL);
  cpssfMIME64: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtMIME64);
  cpssfXX: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtXX);
  cpssfUU: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtUU);
 end;
 {$ENDIF}
end; // StringToFormat


//------------------------------------------------------------------------------
// WideString -> format
//------------------------------------------------------------------------------
function TCPSManager.WideStringToFormat(Source: WideString; Format: TCPSStringFormat): WideString;
{$IFDEF ENCRYPTION_DEC5}
var fm: TDECFormat;
{$ENDIF}
begin
 {$IFDEF ENCRYPTION_DEC5}
 case Format of
  cpssfHEX:
    begin
     fm := TFormat_HEX.Create;
     try
       Result := fm.Encode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
  cpssfHEXL:
    begin
     fm := TFormat_HEXL.Create;
     try
       Result := fm.Encode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
  cpssfMIME64:
    begin
     fm := TFormat_MIME64.Create;
     try
       Result := fm.Encode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
  cpssfXX:
    begin
     fm := TFormat_XX.Create;
     try
       Result := fm.Encode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
  cpssfUU:
    begin
     fm := TFormat_UU.Create;
     try
       Result := fm.Encode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
 end;
 {$ELSE}
 case Format of
  cpssfHEX: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtHEX);
  cpssfHEXL: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtHEXL);
  cpssfMIME64: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtMIME64);
  cpssfXX: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtXX);
  cpssfUU: Result := CPSDecUtil.StrToFormat(PAnsiChar(Source),Length(Source),fmtUU);
 end;
 {$ENDIF}
end; // WideStringToFormat


//------------------------------------------------------------------------------
// format -> WideString
//------------------------------------------------------------------------------
function TCPSManager.FormatToWideString(Source: WideString; Format: TCPSStringFormat): WideString;
{$IFDEF ENCRYPTION_DEC5}
var fm: TDECFormat;
{$ENDIF}
begin
 {$IFDEF ENCRYPTION_DEC5}
 case Format of
  cpssfHEX:
    begin
     fm := TFormat_HEX.Create;
     try
       Result := fm.Decode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
  cpssfHEXL:
    begin
     fm := TFormat_HEXL.Create;
     try
       Result := fm.Decode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
  cpssfMIME64:
    begin
     fm := TFormat_MIME64.Create;
     try
       Result := fm.Decode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
  cpssfXX:
    begin
     fm := TFormat_XX.Create;
     try
       Result := fm.Decode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
  cpssfUU:
    begin
     fm := TFormat_UU.Create;
     try
       Result := fm.Decode(Source[1],Length(Source)*2);
     finally
       fm.Free;
     end;
    end;
 end;
 {$ELSE}
 case Format of
  cpssfHEX: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtHEX);
  cpssfHEXL: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtHEXL);
  cpssfMIME64: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtMIME64);
  cpssfXX: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtXX);
  cpssfUU: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtUU);
 end;
 {$ENDIF}
end; // FormatToWideString


//------------------------------------------------------------------------------
// string -> format
//------------------------------------------------------------------------------
function TCPSManager.StringToFormat(Source: String; Format: TCPSStringFormat): String;
begin
{$IFDEF D12H}
  Result := WideStringToFormat(Source,Format);
{$ELSE}
  Result := AnsiStringToFormat(Source,Format);
{$ENDIF}
end; // StringToFormat


//------------------------------------------------------------------------------
// format -> string
//------------------------------------------------------------------------------
function TCPSManager.FormatToString(Source: String; Format: TCPSStringFormat): String;
begin
{$IFDEF D12H}
  Result := FormatToWideString(Source,Format);
{$ELSE}
  Result := FormatToAnsiString(Source,Format);
{$ENDIF}
end; // FormatToString


//------------------------------------------------------------------------------
// buffer to format
//------------------------------------------------------------------------------
function TCPSManager.BufferToFormat(Buffer: PAnsiChar; Size: Integer; Format: TCPSStringFormat): AnsiString;
{$IFDEF ENCRYPTION_DEC5}
var fmt: TDECFormat;
{$ENDIF}
begin
 {$IFDEF ENCRYPTION_DEC5}
 case Format of
  cpssfHEX:
   begin
    fmt := TFormat_HEX.Create;
    try
      Result := fmt.Encode(Buffer^,Size);
    finally
      fmt.Free;
    end;
   end;
  cpssfHEXL:
   begin
    fmt := TFormat_HEXL.Create;
    try
      Result := fmt.Encode(Buffer^,Size);
    finally
      fmt.Free;
    end;
   end;
  cpssfMIME64:
   begin
    fmt := TFormat_MIME64.Create;
    try
      Result := fmt.Encode(Buffer^,Size);
    finally
      fmt.Free;
    end;
   end;
  cpssfXX:
   begin
    fmt := TFormat_XX.Create;
    try
      Result := fmt.Encode(Buffer^,Size);
    finally
      fmt.Free;
    end;
   end;
  cpssfUU:
   begin
    fmt := TFormat_UU.Create;
    try
      Result := fmt.Encode(Buffer^,Size);
    finally
      fmt.Free;
    end;
   end;
  cpssfEscape:
   begin
    fmt := TFormat_ESCAPE.Create;
    try
      Result := fmt.Encode(Buffer^,Size);
    finally
      fmt.Free;
    end;
   end;
 end;
 {$ELSE}
 case Format of
  cpssfHEX: Result := CPSDecUtil.StrToFormat(Buffer,Size,fmtHEX);
  cpssfHEXL: Result := CPSDecUtil.StrToFormat(Buffer,Size,fmtHEXL);
  cpssfMIME64: Result := CPSDecUtil.StrToFormat(Buffer,Size,fmtMIME64);
  cpssfXX: Result := CPSDecUtil.StrToFormat(Buffer,Size,fmtXX);
  cpssfUU: Result := CPSDecUtil.StrToFormat(Buffer,Size,fmtUU);
 end;
 {$ENDIF}
end; // BufferToFormat


//------------------------------------------------------------------------------
// format to buffer
//------------------------------------------------------------------------------
procedure TCPSManager.FormatToBuffer(Source: AnsiString; Format: TCPSStringFormat; out Buffer: PAnsiChar; out Size: Integer);
var Result: AnsiString;
{$IFDEF ENCRYPTION_DEC5}
    fmt:    TDECFormat;
{$ENDIF}
begin
 {$IFDEF ENCRYPTION_DEC5}
 case Format of
  cpssfHEX:
   begin
    fmt := TFormat_HEX.Create;
    try
      Result := fmt.Decode(Source);
    finally
      fmt.Free;
    end;
   end;
  cpssfHEXL:
   begin
    fmt := TFormat_HEXL.Create;
    try
      Result := fmt.Decode(Source);
    finally
      fmt.Free;
    end;
   end;
  cpssfMIME64:
   begin
    fmt := TFormat_MIME64.Create;
    try
      Result := fmt.Decode(Source);
    finally
      fmt.Free;
    end;
   end;
  cpssfXX:
   begin
    fmt := TFormat_XX.Create;
    try
      Result := fmt.Decode(Source);
    finally
      fmt.Free;
    end;
   end;
  cpssfUU:
   begin
    fmt := TFormat_UU.Create;
    try
      Result := fmt.Decode(Source);
    finally
      fmt.Free;
    end;
   end;
  cpssfEscape:
   begin
    fmt := TFormat_ESCAPE.Create;
    try
      Result := fmt.Decode(Source);
    finally
      fmt.Free;
    end;
   end;
 end;
 {$ELSE}
 case Format of
  cpssfHEX: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtHEX);
  cpssfHEXL: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtHEXL);
  cpssfMIME64: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtMIME64);
  cpssfXX: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtXX);
  cpssfUU: Result := CPSDecUtil.FormatToStr(PAnsiChar(Source),Length(Source),fmtUU);
 end;
 {$ENDIF}
 Size := Length(Result);
 GetMem(Buffer,Size);
 Move(PAnsiChar(Result)^,Buffer^,Size);
end; // FormatToBuffer


//------------------------------------------------------------------------------
// CompressFile
//------------------------------------------------------------------------------
procedure TCPSManager.CompressFile(SourceFileName: AnsiString; DestFileName: AnsiString);
var
    fs: TCPSCryptoPressFileStream;
begin
  fs := CreateCryptoPressFileStream(DestFileName,fmCreate);
  try
    fs.Operation := cpsopLoadFromStream;
    fs.ProgressOperation := cpsopCompressFile;
    fs.OnProgress := DoProgressCompressFile;
    fs.LoadFromFile(SourceFileName);
  finally
    fs.Free;
  end;
end; // CompressFile


//------------------------------------------------------------------------------
// DecompressFile
//------------------------------------------------------------------------------
procedure TCPSManager.DecompressFile(SourceFileName: AnsiString; DestFileName: AnsiString);
var
    fs: TCPSCryptoPressFileStream;
begin
  fs := CreateCryptoPressFileStream(SourceFileName,fmOpenRead or fmShareDenyWrite);
  try
    fs.Operation := cpsopSaveToStream;
    fs.ProgressOperation := cpsopDecompressFile;
    fs.OnProgress := DoProgressDecompressFile;
    fs.ReadOnly := True;
    fs.SaveToFile(DestFileName);
  finally
    fs.Free;
  end;
end; // DecompressFile


//------------------------------------------------------------------------------
// create TCPSMemoryStream
//------------------------------------------------------------------------------
function TCPSManager.CreateMemoryStream: TCPSMemoryStream;
begin
  Result := TCPSMemoryStream.Create(Self);
end; // CreateMemoryStream


//------------------------------------------------------------------------------
// create TCPSFileStream
//------------------------------------------------------------------------------
function TCPSManager.CreateFileStream(const FileName: AnsiString; Mode: Word): TCPSFileStream;
begin
  Result := TCPSFileStream.Create(FileName,Mode,Self);
end; // CreateFileStream


//------------------------------------------------------------------------------
// Create compressed or encrypted stream
//------------------------------------------------------------------------------
function TCPSManager.CreateCryptoPressStream(
                                  BaseStream:             TStream;
                                  CreateNewStream:        Boolean;
                                  FreeBaseStream:         Boolean;
                                  Header:                 PAnsiChar;
                                  HeaderSize:             Integer
                                 ): TCPSCryptoPressStream;
begin
  Result := TCPSCryptoPressStream.Create(BaseStream,
                                         FCryptoParams.GetCryptoParams,
                                         CreateNewStream,
                                         FreeBaseStream,
                                         FCompressionAlgorithm,
                                         FCompressionMode,
                                         FBlockSize,
                                         Header,
                                         HeaderSize,
                                         Self,
                                         FTempDir);
end; // CreateCryptoPressStream


//------------------------------------------------------------------------------
// CreateCryptoPressMemoryStream
//------------------------------------------------------------------------------
function TCPSManager.CreateCryptoPressMemoryStream(
                                  Header:                PAnsiChar = nil;
                                  HeaderSize:            Integer = 0
                                 ): TCPSCryptoPressMemoryStream;
begin
  Result := TCPSCryptoPressMemoryStream.Create(
                                         FCryptoParams.GetCryptoParams,
                                         FCompressionAlgorithm,
                                         FCompressionMode,
                                         FBlockSize,
                                         Header,
                                         HeaderSize,
                                         Self,
                                         FTempDir);
end; // CreateCryptoPressMemoryStream


//------------------------------------------------------------------------------
// CreateCryptoPressFileStream
//------------------------------------------------------------------------------
function TCPSManager.CreateCryptoPressFileStream(
                                  const FileName:        AnsiString;
                                  Mode:                  Word;
                                  Header:                PAnsiChar = nil;
                                  HeaderSize:            Integer = 0
                                 ): TCPSCryptoPressFileStream;
begin
  Result := TCPSCryptoPressFileStream.Create(
                                         FileName,
                                         Mode,
                                         FCryptoParams.GetCryptoParams,
                                         FCompressionAlgorithm,
                                         FCompressionMode,
                                         FBlockSize,
                                         Header,
                                         HeaderSize,
                                         Self,
                                         FTempDir);
end; // CreateCryptoPressFileStream

{$IFDEF D6H}
//------------------------------------------------------------------------------
// CreateCryptoPressFileStream
//------------------------------------------------------------------------------
function TCPSManager.CreateCryptoPressFileStream(
                                  const FileName:        WideString;
                                  Mode:                  Word;
                                  Header:                PAnsiChar = nil;
                                  HeaderSize:            Integer = 0
                                 ): TCPSCryptoPressFileStream;
begin
  Result := TCPSCryptoPressFileStream.Create(
                                         FileName,
                                         Mode,
                                         FCryptoParams.GetCryptoParams,
                                         FCompressionAlgorithm,
                                         FCompressionMode,
                                         FBlockSize,
                                         Header,
                                         HeaderSize,
                                         Self,
                                         FTempDir);
end; // CreateCryptoPressFileStream
{$ELSE}
//------------------------------------------------------------------------------
// CreateCryptoPressFileStream
//------------------------------------------------------------------------------
function TCPSManager.CreateCryptoPressFileStream(
                                  const FileName:        WideString;
                                  Mode:                  Word;
                                  Dummy:                 ByteBool;
                                  Header:                PAnsiChar = nil;
                                  HeaderSize:            Integer = 0
                                 ): TCPSCryptoPressFileStream;
begin
  Result := TCPSCryptoPressFileStream.Create(
                                         FileName,
                                         Mode,
                                         False, // dummy
                                         FCryptoParams.GetCryptoParams,
                                         FCompressionAlgorithm,
                                         FCompressionMode,
                                         FBlockSize,
                                         Header,
                                         HeaderSize,
                                         Self,
                                         FTempDir);
end; // CreateCryptoPressFileStream
{$ENDIF}

//------------------------------------------------------------------------------
// IndexOf
//------------------------------------------------------------------------------
function TCPSManager.IndexOf(Stream: TStream): Integer;
var
  List: TList;
begin
  List := FStreams.LockList;
  try
    Result := List.IndexOf(Stream);
  finally
    FStreams.UnlockList;
  end;
end; // IndexOf


//------------------------------------------------------------------------------
// Clear
//------------------------------------------------------------------------------
procedure TCPSManager.Clear;
var
  List: TList;
begin
  List := FStreams.LockList;
  try
    List.Clear;
  finally
    FStreams.UnlockList;
  end;
end; // Clear


//------------------------------------------------------------------------------
// Add
//------------------------------------------------------------------------------
function TCPSManager.Add(Stream: TStream): Integer;
var
  List: TList;
begin
  if (not (Stream is TStream)) then
   begin
    Result := -1;
    Exit;
   end;
  List := FStreams.LockList;
  try
    Result := List.Add(Stream);
  finally
    FStreams.UnlockList;
  end;
end; // Add


//------------------------------------------------------------------------------
// Delete
//------------------------------------------------------------------------------
procedure TCPSManager.Delete(Index: Integer);
var
  List: TList;
begin
  List := FStreams.LockList;
  try
    List.Delete(Index);
  finally
    FStreams.UnlockList;
  end;
end; // Delete


//------------------------------------------------------------------------------
// Remove
//------------------------------------------------------------------------------
function TCPSManager.Remove(Stream: TStream): Integer;
var
  List: TList;
begin
  List := FStreams.LockList;
  try
    Result := List.IndexOf(Stream);
    if (Result >= 0) then
     List.Delete(Result);
  finally
    FStreams.UnlockList;
  end;
end; // Remove


//------------------------------------------------------------------------------
// return true if valid stream header found
//------------------------------------------------------------------------------
function IsStreamCPSStream(BaseStream: TStream): Boolean;
var oldPos: Int64;
begin
  oldPos := BaseStream.Position;
  try
    Result := (CPSGetOffsetToStreamHeader(BaseStream) >= 0);
  finally
    BaseStream.Position := oldPos;
  end;
end; // IsStreamCPSStream


//------------------------------------------------------------------------------
// return true of db header is valid
//------------------------------------------------------------------------------
function IsStreamEncryptedCPSStream(BaseStream: TStream): Boolean;
var TempHeader: TCPSStreamHeader;
    Pos,oldPos:     Int64;
begin
  Result := False;
  oldPos := BaseStream.Position;
  try
    Pos := CPSGetOffsetToStreamHeader(BaseStream);
    if (Pos >= 0) then
     begin
      LoadDataFromStream(TempHeader,SizeOf(TempHeader),BaseStream,10100);
      Result := (TempHeader.CryptoHeader.CryptoAlgorithm <> CPS_Cipher_None);
     end;
  finally
    BaseStream.Position := oldPos;
  end;
end; // IsStreamEncryptedCPSStream


//------------------------------------------------------------------------------
// return true of stream header is valid
//------------------------------------------------------------------------------
function IsStreamHeaderValid(BaseStream: TStream; Offset: Int64): Boolean;
var TempHeader: TCPSStreamHeader;
    oldPos:     Int64;
begin
  Result := False;
  oldPos := BaseStream.Position;
  try
    if ((Offset + Int64(SizeOf(TempHeader))) <= BaseStream.Size) then
     begin
      BaseStream.Position := Offset;
      LoadDataFromStream(TempHeader,SizeOf(TempHeader),BaseStream,10044);
      if (TempHeader.Signature = CPSSignaturev1) or (TempHeader.Signature = CPSSignature) then
       if ((TempHeader.Version >= CPSMinVersion) and (TempHeader.Version < CPSMaxVersion)) then
        Result := True;
     end;
  finally
    BaseStream.Position := oldPos;
  end;
end; // IsHeaderValid


//------------------------------------------------------------------------------
// return offset from beginning of the BaseStream to Header's signature, or -1 if no signature inthe file
//------------------------------------------------------------------------------
function CPSGetOffsetToStreamHeader(BaseStream: TStream): Int64;
const BufSize = $FFFF;
var
    size,offset,pos,
    oldPos,i,j,k:	  Int64;
    buf:		        PAnsiChar;
    sgn:      		  TCPSSignature;

begin
 Result := -1;
 sgn := CPSSignature;
 if (IsStreamHeaderValid(BaseStream,0)) then
  begin
   Result := 0;
   Exit;
  end;
 buf := MemoryManager.GetMem(BufSize);
 oldPos := BaseStream.Position;
 try
   offset := 0;
   BaseStream.Position := offset;
   // find local file header for first file in archive
   while BaseStream.Position < BaseStream.Size do
    begin
     pos := BaseStream.Position;
     if (BaseStream.Size - BaseStream.Position > BufSize) then
      size := BufSize
     else
      size := BaseStream.Size - BaseStream.Position;

     LoadDataFromStream(Buf^,size,BaseStream,10045);
     // find local file header signature
     i := 0;
     k := -1;
     while (i < size) do
      begin
       k := -1;
       if (PAnsiChar(Buf+i)^ = sgn[0]) then
        begin
         j := 1;
         while j <= 3 do
          begin
           if ((i + j) >= size) then break;
           if (pAnsiChar(Buf + i + j)^ <> sgn[j]) then break;
           inc(j);
           // signature found
           if (j > 3) then
             k := i;
          end; // check signature
         if (k >= 0) then
          if (IsStreamHeaderValid(BaseStream,pos+k)) then
          // local file header for first file in archive found!
           break
          else
           k := -1;
        end; // signature found
       inc(i);
      end; // end of searching local header
     // stub size = difference between supposed offset for header
     // and real one
     if (k >= 0) then
      begin
       Result := k+pos-offset;
       break;
      end;
    end;
 finally
   MemoryManager.FreeAndNilMem(buf);
   BaseStream.Position := oldPos;
 end;
end; // GetOffsetToHeader


{$IFDEF MSWINDOWS}
function GetStrLength(Buffer: PAnsiChar): Integer;
var i: Integer;
begin
  begin
    i := 0;
    Result := 0;
    while (Buffer <> nil) do
     begin
      if (PAnsiChar(Buffer+i)^ = #0) then
        if (PAnsiChar(Buffer+i+1)^ = #0) then
         begin
          Result := i;
          break;
         end;
      Inc(i);
      Inc(i);
     end;
  end
end; // GetStrLength


//------------------------------------------------------------------------------
// Get temp directory
//------------------------------------------------------------------------------
function CPSGetDefaultTempDir: WideString;
var
  l:          Integer;
  TempPath :  array[0..MAX_PATH] of WideChar;
begin
 l := MAX_PATH+1;
 l := Windows.GetTempPathW(l,@TempPath[0]);
 SetLength(Result,l);
 Move(TempPath[0],Result[1],l*2);
end;// GetDefaultTempDir


//------------------------------------------------------------------------------
// Get temp file name
//------------------------------------------------------------------------------
function CPSGetTempFileName(TempDir: WideString): WideString;
var
  TempPath : array[0..MAX_PATH] of WideChar;
  Prefix : array[0..3] of WideChar;
  lpTempName: array [0..MAX_PATH] of WideChar;
  l: Integer;
begin
  // get temp file name
  Prefix[0] := 'C';
  Prefix[1] := 'P';
  Prefix[2] := 'S';
  Prefix[3] := #0;
  FillChar(TempPath[0],Length(TempPath)*2,$00);
  l := GetStrLength(PAnsiChar(@TempDir[1]));
  Move(TempDir[1],TempPath[0],l);
  FillChar(lpTempName[0],Length(lpTempName)*2,$00);
  Windows.GetTempFileNameW(@TempPath[0], @Prefix[0], 0, lpTempName);
  l := GetStrLength(PAnsiChar(@lpTempName[0])) div 2;
  SetLength(Result,l);
  Move(lpTempName[0],Result[1],l*2);
  Result := lpTempName;
end;// GetTempFileName


{$ENDIF}

{$IFDEF LINUX}
//------------------------------------------------------------------------------
// Get temp directory
//------------------------------------------------------------------------------
function CPSGetDefaultTempDir: AnsiString;
begin
  Result := '/tmp/';
end;// GetDefaultTempFileName


//------------------------------------------------------------------------------
// Get temp file name
//------------------------------------------------------------------------------
function CPSGetTempFileName(TempDir: AnsiString): AnsiString;
var
  Template : array[0..MAX_PATH] of AnsiChar;
  lpTempName: array [0..MAX_PATH] of AnsiChar;
  TempFileName : PAnsiChar;
  s: AnsiString;
begin
  // get temp file name
  s := TempDir+'CPSXXXXXX';
  StrPCopy(Template, s);
//  TempFileName := AllocMem(MAX_PATH);
  TempFileName := mktemp(Template);
  if TempFileName = nil then
    raise ECPSException.Create(10072,ErrorLCannotGetTempFileName);
  Move(TempFileName^,lpTempName,MAX_PATH);
//  Free(TempFileName);
  Result := lpTempName;
end;// GetTempFileName
{$ENDIF}


{$IFDEF TRIAL_VERSION}

function CPStrcapt1: AnsiString;
begin
 Result := 'CryptoPressStream Trial Version - ';
end;

function CPStrnm1: AnsiString;
begin

  Result :=
             'This is the trial version of CryptoPressStream by'#13+
             'AidAim Software (c) 2000-2013.'#13+
             'Web site: http://www.aidaim.com'#13#13+

             'Limitations of this trial version: '#13+
             '- nag screen when IDE is not running.'#13#13+

						 'This screen is created to remind you that your trial version is'#13+
             'provided to you for evaluation purposes only.'#13+
             'If you don''t want to see this screen any more, or if you intend'#13+
             'to create a commercial product, please, register and download'#13+
             'the appropriate version of this product at http://www.aidaim.com'#13+
             'Also visit our site for all the new versions of our products.'#13#13+
             'Should you have any questions or problems with our product,'#13+
             'be sure to contact us at support@aidaim.com';

end;


function CPStrcapt: AnsiString;
begin
 Result := '56574873A73CEC0EDA09031FD8A1C14CFCCBDC566CDF62DBA5E28536DBF64ADA8C1B';
end;

function CPStrnm: AnsiString;
begin
  Result :=  'E014907DE91B25BC620EFFF2D51F5D0F0AEE4489140A8E9273D1340BE6FE206DA5A82067F434D039EA28FF5221B5499AB0CD9CE6101902716B06B9B314BBB98F5CA61437694FDAB9FDC559'
            +'58D58FDC9C17EF9A76315922859EB966D845D40C05D23325F1F77B41E1D297EEA57869C47723007464A6320B9E60E4BF276157BB733EC530AE6F8261AB18A050F36F7EB83E4BB680599559'
            +'51721BECAB880515B1922FFE711B67D254D0DDDBB3C87E642839F1066FAC7D3746E6E3CBC6781DB7F485D6FDB23EBFF9DD0A93C444CE0670E99270284D3363750555496744FCFE9CDE27BD'
            +'DD0B8582B3206CADE7512599626B1DBC65A132F45F078E7F728E3D8FC81ED370CA3048E072AE823D2722759A89007E1C764D4597618C1C88D62C97DDF4B75C3F84F1CCEEF3D9B31ADF8695'
            +'85DE4A11BBB19BA86F3C8B51673C86BD59D753708250D63661599F2C7D854E8C101CC1F8EE4D5185C697C1624759A0BDD414C00312954448C6D0B6C5B1BB56D66A657F9D58AB8C4229DAD4'
            +'76B0001B473B456A269579FA4E95797D9860D475496F6E73C7B651FD992F7456EC3D806906AC127352D7397F72250A347DECEEC471D6CE8FDDCB5D72EAB39F8422B3A86B9FF992DAAF5863'
            +'399D8675F180B101CE75A3C8F9607C42A5452EDC9C6F185E5699367A73DDD8A24C243D4BAFBCDF8A05B18E7254723E18C4482005E5D969C44694ACE8B098E266113934DD21997877806A14'
            +'E081083DE356266CBF487E51A4B4CF6619DD4A285C4CD1DCEB31993E53C88465BE88684EB2491ED44E4CE8A76E58AF24788009461A14AE5763241EE55BFABE12EA710530D4976E43C49170'
            +'2D39A82B074FBF44A7D0E4466721EB256A712102E61EFB19EF99515EEDAC559384204B7A0EB23FEC3C8BB8EE38EF904D27E98D04056306AA'
            ;
end;

function CPStrgetencmsg(msg: AnsiString): AnsiString;
var cr: TCipher_Blowfish;
{$IFDEF ENCRYPTION_DEC5}
    hs: THash_RipeMD256;
    s:  Binary;
{$ELSE}
    s: AnsiString;
{$ENDIF}
begin
{$IFDEF ENCRYPTION_DEC5}
 cr := TCipher_Blowfish.Create;
 hs := THash_RipeMD256.Create;
 s := hs.CalcBinary(CPSDefaultPassword);
 cr.Init(s);
 ProtectBinary(s);
 Result := cr.EncodeBinary(msg,TFormat_HEX);
 cr.Free;
{$ELSE}
 cr := TCipher_Blowfish.Create(CPSDefaultPassword,nil);
 s := cr.EncodeAnsiString(msg);
 cr.Free;
 Result := StrToFormat(PAnsiChar(@s[1]),Length(s),fmtHEX);
{$ENDIF}
end;

function CPStrgetdecmsg(msg: AnsiString): AnsiString;
var cr: TCipher_Blowfish;
{$IFDEF ENCRYPTION_DEC5}
    hs: THash_RipeMD256;
    s:  Binary;
{$ELSE}
    s: AnsiString;
{$ENDIF}
begin
{$IFDEF ENCRYPTION_DEC5}
 cr := TCipher_Blowfish.Create;
 hs := THash_RipeMD256.Create;
 s := hs.CalcBinary(CPSDefaultPassword);
 cr.Init(s);
 ProtectBinary(s);
 Result := cr.DecodeBinary(msg,TFormat_HEX);
 cr.Free;
{$ELSE}
 s := FormatToStr(PAnsiChar(@msg[1]),Length(msg),fmtHEX);
 cr := TCipher_Blowfish.Create(CPSDefaultPassword,nil);
 Result := cr.DecodeAnsiString(s);
 cr.Free;
{$ENDIF}
end;

function CPStrgnm: AnsiString;
begin
 Result := CPStrgetdecmsg(CPStrnm);
end;

function CPStrgcapt: AnsiString;
var ds:   Char;
    vStr: AnsiString;
begin
{$IFDEF D17H}
  ds := FormatSettings.DecimalSeparator;
  try
    FormatSettings.DecimalSeparator := '.';
    vStr := 'v.'+FormatFloat('0.00',CPSVersion) + ' '+ CPSVersionText;
  finally
    FormatSettings.DecimalSeparator := ds;
    Result := CPStrgetdecmsg(CPStrcapt) + vStr;
  end;
{$ELSE}
  ds := DecimalSeparator;
  try
    DecimalSeparator := '.';
    vStr := 'v.'+FormatFloat('0.00',CPSVersion) + ' '+ CPSVersionText;
  finally
    DecimalSeparator := ds;
    Result := CPStrgetdecmsg(CPStrcapt) + vStr;
  end;
{$ENDIF}
end;

procedure CPStrshnm;
begin
{$IFDEF TRIAL_VERSION_WITHOUT_NAG_SCREEN}
 Exit;
{$ENDIF}
 MessageBoxA(0,PAnsiChar(CPStrgnm),PAnsiChar(CPStrgcapt),
{$IFDEF MSWINDOWS}
		 MB_OK+MB_ICONINFORMATION+MB_DEFBUTTON1
{$ENDIF}
{$IFDEF LINUX}
     [smbOK], smsInformation
{$ENDIF}
);
end;

//------------------------------------------------------------------------------
// callback function to enumerate all open windows
//------------------------------------------------------------------------------
Function CPSWindowCallback(WHandle : HWnd; Var Parm : Pointer) : Boolean;
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
{$ENDIF}

{$IFDEF TRIAL_VERSION}
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
aaWriteToLog('CPSMain initialization');
{$ENDIF}


{$IFDEF TRIAL_VERSION}
{$IFDEF MSWINDOWS}
  WindowLst := TStringList.Create;
  EnumWindows(@CPSWindowCallback,Longint(@WindowLst));
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
      (Reg.KeyExists('\Software\CodeGear\BDS')) or
      (Reg.KeyExists('\Software\Embarcadero\BDS')) or
      (Reg.KeyExists('\Software\Borland\C++Builder'))) then
    IsDelphiOrBuilderInstalled := true
  else
    IsDelphiOrBuilderInstalled := false;
  Reg.Free;
  // nag screen
  if ((not IsIDERunning) or (not IsDelphiOrBuilderInstalled)) then
     begin
      CPStrshnm;
     end;
   WindowLst.Free;
{$ENDIF}
{$ENDIF}
  IsDesignMode := False;


end.
