unit ESFSZlib_64;

{$INCLUDE ESFSConfig.inc}

interface

Uses Classes, SysUtils, ESFSCommon;

const
  ZLib_Version: PAnsiChar = '1.2.7';

type

  EZLibError = class(Exception);
  ECompressionError = class(EZLibError);
  EDecompressionError = class(EZLibError);

  PZStreamRec = ^TZStreamRec;
  TZStreamRec = record
    next_in: PAnsiChar;
    avail_in: Cardinal;
    total_in: Cardinal;
    next_out: PAnsiChar;
    avail_out:  Cardinal;
    total_out: Cardinal;
    msg: PAnsiChar;
    internal: Pointer;
    zalloc : TAlloc;
    zfree: TFree;
    AppData: Pointer;
    data_type: Cardinal;
    adler : Cardinal;
    reserved: Cardinal;
  end;

function deflateInit_(var Strm : TZStreamRec; Level: Integer; Version: PAnsiChar; RecSize: Integer): Integer; cdecl;
function Deflate(var Strm: TZStreamRec; Flush: Integer): Integer; cdecl;
function InflateInit_(var Strm: TZStreamRec; const Version: PAnsiChar; RecSize: Integer): Integer; cdecl;
function Inflate(var Strm: TZStreamRec; Flush: Integer): Integer; cdecl;

function InflateInit(var Strm: TZStreamRec):Integer;
function DeflateInit(var Strm: TZStreamRec; ComprLevel: Integer):Integer;
procedure ZlibCompressBuf(const InBuf: PAnsiChar; InBytes: Integer; out OutBuf: PAnsiChar; out OutBytes: Integer; ComprMode: Byte = 1);
procedure ZlibDecompressBuf(const InBuf: PAnsiChar; InBytes: Integer; OutEstimate: Integer; out OutBuf: PAnsiChar; out OutBytes: Integer);

const
  Z_NO_FLUSH = 0;
  Z_PARTIAL_FLUSH = 1;
  Z_SYNC_FLUSH = 2;
  Z_FULL_FLUSH = 3;
  Z_FINISH = 4;

  Z_OK = 0;
  Z_STREAM_END = 1;
  Z_NEED_DICT = 2;
  Z_ERRNO = -1;
  Z_STREAM_ERROR = -2;
  Z_DATA_ERROR = -3;
  Z_MEM_ERROR = -4;
  Z_BUF_ERROR = -5;
  Z_VERSION_ERROR = -6;

  Z_NO_COMPRESSION = 0;
  Z_BEST_SPEED = 1;
  Z_BEST_COMPRESSION = 9;
  Z_DEFAULT_COMPRESSION = -1;

  Z_FILTERED = 1;
  Z_HUFFMAN_ONLY = 2;
  Z_DEFAULT_STRATEGY = 0;

  Z_BINARY = 0;
  Z_ASCII = 1;
  Z_UNKNOWN = 2;

  Z_DEFLATED = 8;

implementation

const
  z_errmsg : array[0..9] of PAnsiChar = (
    'need dictionary',
    'stream end',
    '',
    'file error',
    'stream error',
    'data error',
    'insufficient memory',
    'buffer error',
    'incompatible version',
    ''
  );

function CCheck(Code : Integer): Integer;
begin
  Result := Code;
  if Code < 0 then
  begin
    raise ECompressionError.Create(Format('ZLib error %d: %s',[Code, z_errmsg[2-Code]]));
  end;
end;

function DCheck(Code : Integer): Integer;
begin
  Result := Code;
  if Code < 0 then
    raise EDecompressionError.Create(Format('ZLib error %d: %s',[Code, z_errmsg[2-Code]]));
end;

{$IFDEF STATIC}
{$IFDEF MSWINDOWS}
{$LINK .\zlib\adler32.obj}
{$LINK .\zlib\inflate.obj}
{$LINK .\zlib\inffast.obj}
{$LINK .\zlib\inftrees.obj}
{$LINK .\zlib\crc32.obj}
{$LINK .\zlib\deflate.obj}
{$LINK .\zlib\trees.obj}
{$ENDIF}
{$ENDIF}

{$IFDEF STATIC}
procedure _tr_init; cdecl; external;
procedure _tr_tally; cdecl; external;
procedure _tr_flush_block; cdecl; external;
function adler32(adler: Cardinal; Buf: PAnsiChar; Len: Int32): UInt32;cdecl; external;
function deflateInit_(var Strm : TZStreamRec; Level: Integer; Version: PAnsiChar; RecSize: Integer): Integer; cdecl; external;
function Deflate(var Strm: TZStreamRec; Flush: Integer): Integer; cdecl; external;
function deflateEnd(var strm: TZStreamRec): Int32; cdecl; external;
function InflateInit_(var Strm: TZStreamRec; const Version: PAnsiChar; RecSize: Integer): Integer; cdecl; external;
function Inflate(var Strm: TZStreamRec; Flush: Integer): Integer; cdecl; external;
function InflateEnd(var Strm: TZStreamRec): Integer; cdecl;external;
procedure inflate_fast; cdecl; external;
procedure inflate_table; cdecl; external;
{$ENDIF}

function DeflateInit(var Strm: TZStreamRec; ComprLevel: Integer):Integer;
begin
  Result := DeflateInit_(Strm, ComprLevel, Zlib_Version, Sizeof(TZStreamRec));
end;

function InflateInit(var Strm: TZStreamRec):Integer;
begin
  Result := InflateInit_(Strm, Zlib_Version, SizeOf(TZStreamRec));
end;

procedure memset(P: Pointer; B: Byte; Count: Integer); cdecl;
begin
  FillChar(P^, Count, B);
end;

procedure memcpy(Dest, Source: Pointer; Count: Integer); cdecl;
begin
  ESFSMemcpy(Dest, Source, Count);
end;

function zcAlloc(Data: Pointer; Items, Size: Integer):Pointer; cdecl;
begin
  Result := ESFSAlloc(nil, Items*Size);
end;

procedure zcFree(Data, Block: Pointer); register;
begin
  FreeMem(Block);
end;

procedure ZlibCompressBuf(const InBuf: PAnsiChar; InBytes: Integer; out OutBuf: PAnsiChar; out OutBytes: Integer; ComprMode: Byte = 1);
const
  BufInc: Integer = 256;
var
  Strm: TZStreamRec;
  P: PAnsiChar;
begin
  FillChar(Strm, sizeof(TZStreamRec), 0);
  {$IFDEF MSWINDOWS}
  strm.zalloc := @zcAlloc;
  strm.zfree := @zcFree;
  {$ENDIF}
  OutBytes := ((InBytes + (InBytes div 10) + 12) + 255) and not 255;
  OutBuf := AllocMem(OutBytes);
  try
    strm.next_in := InBuf;
    strm.avail_in := InBytes;
    strm.next_out := OutBuf;
    strm.avail_out := OutBytes;
    CCheck(DeflateInit(Strm, ComprMode));
    while CCheck(Deflate(Strm, Z_FINISH)) <> Z_STREAM_END do
    begin
      P := OutBuf;
      Inc(OutBytes, BufInc);
      ReallocMem(OutBuf, OutBytes);
      {$IFDEF WIN64}
        strm.next_out := OutBuf + strm.total_out;
      {$ELSE}
        strm.next_out := PAnsiChar(Integer(OutBuf) + strm.total_out);
      {$ENDIF}
      strm.avail_out := BufInc;
    end;
    CCheck(DeflateEnd(Strm));
    OutBytes := strm.total_out;
    ReallocMem(OutBuf, OutBytes);
  except
    FreeMem(OutBuf);
  end;
end;

procedure ZlibDecompressBuf(const InBuf: PAnsiChar; InBytes: Integer; OutEstimate: Integer; out OutBuf: PAnsiChar; out OutBytes: Integer);
var
  Strm : TZStreamRec;
  Delta: Integer;
  Err: Integer;
begin
  FillChar(Strm, SizeOf(TZStreamRec), #0);

  Delta := (InBytes + 255) and not 255;
  if OutEstimate = 0 then
    OutBytes := Delta
  else
    OutBytes := OutEstimate;

  OutBuf := AllocMem(OutBytes);

  try
    DCheck(InflateInit(Strm));

    Strm.next_in := InBuf;
    Strm.avail_in := InBytes;

    Strm.next_out := OutBuf;
    Strm.avail_out := OutBytes;

    while True do
    begin

      Err := Inflate(Strm, Z_NO_FLUSH);
      if Err = Z_STREAM_END then
        break;
      DCheck(Err);

      Inc(OutBytes, Delta);
      ReallocMem(OutBuf, OutBytes);
      {$IFDEF WIN64}
        Strm.next_out := OutBuf + Strm.total_out;
      {$ELSE}
        Strm.next_out := PAnsiChar(Integer(OutBuf) + Strm.total_out);
      {$ENDIF}
      Strm.avail_out := Delta;

    end;
    Err := DCheck(InflateEnd(Strm));
    OutBytes := Strm.total_out;
    ReallocMem(OutBuf, OutBytes);
  except
    FreeMem(OutBuf);
    OutBuf := nil;
    OutBytes := 0;
    raise;
  end;

end;


end.
