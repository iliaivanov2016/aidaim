{*******************************************************}
{                                                       }
{       Borland Delphi Supplemental Components          }
{       ZLIB Data Compression Interface Unit            }
{                                                       }
{       Copyright (c) 1997,99 Inprise Corporation       }
{                                                       }
{*******************************************************}
// ZLib 1.1.3 source files (http://www.info-zip.org/pub/infozip/zlib)

{ Modified for zlib 1.1.3 by Davide Moretti <dave@rimini.com }

{                                                            }
{ (09/20/99) Ryan Mills. <rmills@freenet.edmonton.ab.ca>     }
{ Further modified to be more compatible with the D5 version }
{ of the ZLIB component, integrating the speed enhancements  }
{ introduced by Borland.                                     }

unit ETblZLIB;

{$I ETblVer.inc}

{$I CompilerDefines.inc}

interface

uses Sysutils, Classes;

resourcestring
 sTargetBufferTooSmall = 'ZLib error: target buffer may be too small';
 sInvalidStreamOp = 'Invalid stream operation';


type
  TAlloc = function (AppData: Pointer; Items, Size: Integer): Pointer; register;
  TFree = procedure (AppData, Block: Pointer); register;

  // Internal structure.  Ignore.
  TZStreamRec = packed record
    next_in: PChar;       // next input byte
    avail_in: Integer;    // number of bytes available at next_in
    total_in: Integer;    // total nb of input bytes read so far

    next_out: PChar;      // next output byte should be put here
    avail_out: Integer;   // remaining free space at next_out
    total_out: Integer;   // total nb of bytes output so far

    msg: PChar;           // last error message, NULL if no error
    internal: Pointer;    // not visible by applications

    zalloc: TAlloc;       // used to allocate the internal state
    zfree: TFree;         // used to free the internal state
    AppData: Pointer;     // private data object passed to zalloc and zfree

    data_type: Integer;   //  best guess about the data type: ascii or binary
    adler: Integer;       // adler32 value of the uncompressed data
    reserved: Integer;    // reserved for future use
  end;


{ CompressBuf compresses data, buffer to buffer, in one call.
   In: InBuf = ptr to compressed data
       InBytes = number of bytes in InBuf
  Out: OutBuf = ptr to newly allocated buffer containing decompressed data
       OutBytes = number of bytes in OutBuf   }
procedure ZLIBCompressBuf(
                      const InBuf: Pointer; InBytes: Integer;
                      out OutBuf: Pointer; out OutBytes: Integer;
                      compMode: Byte = 1
                      );


{ DecompressBuf decompresses data, buffer to buffer, in one call.
   In: InBuf = ptr to compressed data
       InBytes = number of bytes in InBuf
       OutEstimate = zero, or est. size of the decompressed data
  Out: OutBuf = ptr to newly allocated buffer containing decompressed data
       OutBytes = number of bytes in OutBuf   }
procedure ZLIBDecompressBuf(const InBuf: Pointer; InBytes: Integer;
 OutEstimate: Integer; out OutBuf: Pointer; out OutBytes: Integer);

{ DecompressToUserBuf decompresses data, buffer to buffer, in one call.
   In: InBuf = ptr to compressed data
       InBytes = number of bytes in InBuf
  Out: OutBuf = ptr to user-allocated buffer to contain decompressed data
       BufSize = number of bytes in OutBuf   }
procedure DecompressToUserBuf(const InBuf: Pointer; InBytes: Integer;
  const OutBuf: Pointer; BufSize: Integer);

const
  zlib_version = '1.1.3';

type
  EZlibError = class(Exception);
  ECompressionError = class(EZlibError);
  EDecompressionError = class(EZlibError);

{$IFNDEF BCB4}
function adler32(adler: Cardinal; buf: PChar; len: Integer): Cardinal;
{$ENDIF}

implementation


const
  Z_NO_FLUSH      = 0;
  Z_PARTIAL_FLUSH = 1;
  Z_SYNC_FLUSH    = 2;
  Z_FULL_FLUSH    = 3;
  Z_FINISH        = 4;

  Z_OK            = 0;
  Z_STREAM_END    = 1;
  Z_NEED_DICT     = 2;
  Z_ERRNO         = (-1);
  Z_STREAM_ERROR  = (-2);
  Z_DATA_ERROR    = (-3);
  Z_MEM_ERROR     = (-4);
  Z_BUF_ERROR     = (-5);
  Z_VERSION_ERROR = (-6);

  Z_NO_COMPRESSION       =   0;
  Z_BEST_SPEED           =   1;
  Z_BEST_COMPRESSION     =   9;
  Z_DEFAULT_COMPRESSION  = (-1);

  Z_FILTERED            = 1;
  Z_HUFFMAN_ONLY        = 2;
  Z_DEFAULT_STRATEGY    = 0;

  Z_BINARY   = 0;
  Z_ASCII    = 1;
  Z_UNKNOWN  = 2;

  Z_DEFLATED = 8;

const
  Levels: array [0..3] of ShortInt =
    (Z_NO_COMPRESSION, Z_BEST_SPEED, Z_DEFAULT_COMPRESSION, Z_BEST_COMPRESSION);

  _z_errmsg: array[0..9] of PChar = (
    'need dictionary',      // Z_NEED_DICT      (2)
    'stream end',           // Z_STREAM_END     (1)
    '',                     // Z_OK             (0)
    'file error',           // Z_ERRNO          (-1)
    'stream error',         // Z_STREAM_ERROR   (-2)
    'data error',           // Z_DATA_ERROR     (-3)
    'insufficient memory',  // Z_MEM_ERROR      (-4)
    'buffer error',         // Z_BUF_ERROR      (-5)
    'incompatible version', // Z_VERSION_ERROR  (-6)
    ''
  );

{$L deflate.obj}
{$L inflate.obj}
{$L inftrees.obj}
{$L trees.obj}
{$L adler32.obj}
{$L infblock.obj}
{$L infcodes.obj}
{$L infutil.obj}
{$L inffast.obj}

procedure _tr_init; external;
procedure _tr_tally; external;
procedure _tr_flush_block; external;
procedure _tr_align; external;
procedure _tr_stored_block; external;
{$IFDEF BD5}
  function adler32; external;
{$ENDIF}
{$IFDEF BCB5}
  function adler32; external;
{$ELSE}
  {$IFDEF BD4}
    procedure adler32; external;
  {$ENDIF}
  {$IFDEF BCB4}
    procedure adler32; external;
  {$ENDIF}
{$ENDIF}
procedure inflate_blocks_new; external;
procedure inflate_blocks; external;
procedure inflate_blocks_reset; external;
procedure inflate_blocks_free; external;
procedure inflate_set_dictionary; external;
procedure inflate_trees_bits; external;
procedure inflate_trees_dynamic; external;
procedure inflate_trees_fixed; external;
//procedure inflate_trees_free; external;
procedure inflate_codes_new; external;
procedure inflate_codes; external;
procedure inflate_codes_free; external;
procedure _inflate_mask; external;
procedure inflate_flush; external;
procedure inflate_fast; external;

procedure _memset(P: Pointer; B: Byte; count: Integer); cdecl;
begin
  FillChar(P^, count, B);
end;

procedure _memcpy(dest, source: Pointer; count: Integer); cdecl;
begin
  Move(source^, dest^, count);
end;



// deflate compresses data
function deflateInit_(var strm: TZStreamRec; level: Integer; version: PChar;
  recsize: Integer): Integer; external;
function deflate(var strm: TZStreamRec; flush: Integer): Integer; external;
function deflateEnd(var strm: TZStreamRec): Integer; external;

// inflate decompresses data
function inflateInit_(var strm: TZStreamRec; version: PChar;
  recsize: Integer): Integer; external;
function inflate(var strm: TZStreamRec; flush: Integer): Integer; external;
function inflateEnd(var strm: TZStreamRec): Integer; external;
function inflateReset(var strm: TZStreamRec): Integer; external;


function zcAlloc(AppData: Pointer; Items, Size: Integer): Pointer; register;
begin
  Result := AllocMem(Items * Size);
end;

procedure zcFree(AppData, Block: Pointer); register;
begin
  FreeMem(Block);
end;

function CCheck(code: Integer): Integer;
begin
  Result := code;
  if code < 0 then
    raise ECompressionError.Create('error'); //!!
end;

function DCheck(code: Integer): Integer;
begin
  Result := code;
  if code < 0 then
    raise EDecompressionError.Create('error');  //!!
end;

procedure ZLIBCompressBuf(const InBuf: Pointer; InBytes: Integer;
                      out OutBuf: Pointer; out OutBytes: Integer;
                      compMode: Byte = 1
                      );
var
  strm: TZStreamRec;
  P: Pointer;
begin
  FillChar(strm, sizeof(strm), 0);
//  strm.zalloc := zlibAllocMem;
//  strm.zfree := zlibFreeMem;
  OutBytes := ((InBytes + (InBytes div 10) + 12) + 255) and not 255;
  GetMem(OutBuf, OutBytes);
  try
    strm.next_in := InBuf;
    strm.avail_in := InBytes;
    strm.next_out := OutBuf;
    strm.avail_out := OutBytes;
    CCheck(deflateInit_(strm, compMode, zlib_version, sizeof(strm)));
    try
      while CCheck(deflate(strm, Z_FINISH)) <> Z_STREAM_END do
      begin
        P := OutBuf;
        Inc(OutBytes, 256);
        ReallocMem(OutBuf, OutBytes);
        strm.next_out := PChar(Integer(OutBuf) + (Integer(strm.next_out) - Integer(P)));
        strm.avail_out := 256;
      end;
    finally
      CCheck(deflateEnd(strm));
    end;
    ReallocMem(OutBuf, strm.total_out);
    OutBytes := strm.total_out;
  except
    FreeMem(OutBuf);
    raise
  end;
end;


procedure ZLIBDecompressBuf(const InBuf: Pointer; InBytes: Integer;
  OutEstimate: Integer; out OutBuf: Pointer; out OutBytes: Integer);
var
  zstream: TZStreamRec;
  delta  : Integer;
begin
  FillChar(zstream,SizeOf(TZStreamRec),0);

  delta := (InBytes + 255) and not 255;

  if outEstimate = 0 then outBytes := delta
  else outBytes := outEstimate;

  GetMem(outBuf,outBytes);

  try
    zstream.next_in := inBuf;
    zstream.avail_in := InBytes;
    zstream.next_out := outBuf;
    zstream.avail_out := outBytes;

    DCheck(InflateInit_(zstream,zlib_version,sizeof(zstream)));

    try
      while DCheck(inflate(zstream,Z_NO_FLUSH)) <> Z_STREAM_END do
      begin
        Inc(outBytes,delta);
        ReallocMem(outBuf,outBytes);

        zstream.next_out := PChar(Integer(outBuf) + zstream.total_out);
        zstream.avail_out := delta;
      end;
    finally
      DCheck(inflateEnd(zstream));
    end;

    ReallocMem(outBuf,zstream.total_out);
    outBytes := zstream.total_out;
  except
    FreeMem(outBuf);
    raise;
  end;
end;

procedure DecompressToUserBuf(const InBuf: Pointer; InBytes: Integer;
  const OutBuf: Pointer; BufSize: Integer);
var
  strm: TZStreamRec;
begin
  FillChar(strm, sizeof(strm), 0);
//  strm.zalloc := zlibAllocMem;
//  strm.zfree := zlibFreeMem;
  strm.next_in := InBuf;
  strm.avail_in := InBytes;
  strm.next_out := OutBuf;
  strm.avail_out := BufSize;
  DCheck(inflateInit_(strm, zlib_version, sizeof(strm)));
  try
    if DCheck(inflate(strm, Z_FINISH)) <> Z_STREAM_END then
    {$IFDEF BD5}
      raise EZlibError.CreateRes(@sTargetBufferTooSmall);
    {$ELSE}
      {$IFDEF BD4}
        raise EZlibError.Create(sTargetBufferTooSmall);
      {$ENDIF}
    {$ENDIF}
  finally
    DCheck(inflateEnd(strm));
  end;
end;


end.





