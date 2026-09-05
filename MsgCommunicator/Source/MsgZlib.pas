
// ZLib 1.1.4 (modified by AidAim to add 64-bit stream support)

{*******************************************************}
{                                                       }
{       Borland Delphi Supplemental Components          }
{       ZLIB Data Compression Interface Unit            }
{                                                       }
{       Copyright (c) 1997,99 Inprise Corporation       }
{                                                       }
{*******************************************************}

{ Modified for zlib 1.1.4 by Davide Moretti <dave@rimini.com }
{                                                            }
{ (09/20/99) Ryan Mills. <rmills@freenet.edmonton.ab.ca>     }
{ Further modified to be more compatible with the D5 version }
{ of the ZLIB component, integrating the speed enhancements  }
{ introduced by Borland.                                     }

unit MsgZlib;

{$I MsgVer.inc}
{$I CompilerDefines.inc}

interface

uses SysUtils, Classes;

resourcestring
 sTargetBufferTooSmall = 'ZLib error: target buffer may be too small';
 sInvalidStreamOp = 'Invalid stream operation';

{$IFDEF LINUX}
 const zlibso = 'libz.so.1.1.4';
{$ENDIF}

type
  TAlloc = function (AppData: Pointer; Items, Size: Integer): Pointer; register;
  TFree = procedure (AppData, Block: Pointer); register;

  // Internal structure.  Ignore.
  TZStreamRec = packed record
    next_in: PAnsiChar;       // next input byte
    avail_in: Integer;    // number of bytes available at next_in
{$IFDEF LINUX}
    total_in: Integer;//64;    // total nb of input bytes read so far
{$ENDIF}
{$IFDEF MSWINDOWS}
    total_in: Int64;    // total nb of input bytes read so far
{$ENDIF}

    next_out: PAnsiChar;      // next output byte should be put here
    avail_out: Integer;   // remaining free space at next_out
{$IFDEF LINUX}
    total_out: Integer;//not 64;   // total nb of bytes output so far
{$ENDIF}
{$IFDEF MSWINDOWS}
    total_out: Int64;   // total nb of bytes output so far
{$ENDIF}

    msg: PAnsiChar;           // last error message, NULL if no error
    internal: Pointer;    // not visible by applications

    zalloc: TAlloc;       // used to allocate the internal state
    zfree: TFree;         // used to free the internal state
    AppData: Pointer;     // private data object passed to zalloc and zfree

    data_type: Integer;   //  best guess about the data type: ascii or binary
{$IFDEF LINUX}
    adler: Integer;//not 64;       // adler32 value of the uncompressed data
    reserved: Integer;//not 64;    // reserved for future use
{$ENDIF}
{$IFDEF MSWINDOWS}
    adler: Integer;       // adler32 value of the uncompressed data
    reserved: Integer;    // reserved for future use
{$ENDIF}
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


const
  zlib_version = '1.1.4';

type
  EZlibError = class(Exception);
  ECompressionError = class(EZlibError);
  EDecompressionError = class(EZlibError);

{$IFNDEF BCB4}
 {$IFDEF MSWINDOWS}
function adler32(adler: Cardinal; buf: PAnsiChar; len: Integer): Cardinal;
 {$ENDIF}
{$ENDIF}

function CCheck(code: Integer): Integer;
function DCheck(code: Integer): Integer;

// deflate compresses data
function deflateInit2_(var strm: TZStreamRec;
			level, method, windowBits, memLevel, strategy: Integer;
		  version: PAnsiChar;
      stream_size: Integer): Integer;
{$IFDEF LINUX}
  cdecl; external zlibso name 'deflateInit2_';
{$ENDIF}
{$IFDEF MSWINDOWS}
  external;
{$ENDIF}

function deflateInit_(var strm: TZStreamRec; level: Integer; version: PAnsiChar;
  recsize: Integer): Integer;
{$IFDEF LINUX}
  cdecl; external zlibso name 'deflateInit_';
{$ENDIF}
{$IFDEF MSWINDOWS}
  external;
{$ENDIF}

function deflate(var strm: TZStreamRec; flush: Integer): Integer;
{$IFDEF LINUX}
  cdecl; external zlibso name 'deflate';
{$ENDIF}
{$IFDEF MSWINDOWS}
  external;
{$ENDIF}

function deflateEnd(var strm: TZStreamRec): Integer;
{$IFDEF LINUX}
  cdecl; external zlibso name 'deflateEnd';
{$ENDIF}
{$IFDEF MSWINDOWS}
  external;
{$ENDIF}

// inflate decompresses data
function inflateInit_(var strm: TZStreamRec; version: PAnsiChar;
  recsize: Integer): Integer;
{$IFDEF LINUX}
  cdecl; external zlibso name 'inflateInit_';
{$ENDIF} 
{$IFDEF MSWINDOWS} 
  external;
{$ENDIF} 
 
function inflate(var strm: TZStreamRec; flush: Integer): Integer; 
{$IFDEF LINUX} 
  cdecl; external zlibso name 'inflate'; 
{$ENDIF}
{$IFDEF MSWINDOWS}
  external; 
{$ENDIF}
 
function inflateEnd(var strm: TZStreamRec): Integer; 
{$IFDEF LINUX} 
  cdecl; external zlibso name 'inflateEnd';
{$ENDIF}
{$IFDEF MSWINDOWS} 
  external;
{$ENDIF}
	
function inflateReset(var strm: TZStreamRec): Integer; 
{$IFDEF LINUX} 
  cdecl; external zlibso name 'inflateReset';
{$ENDIF} 
{$IFDEF MSWINDOWS}
  external;
{$ENDIF} 
	
function deflateReset(var strm: TZStreamRec): Integer;
{$IFDEF LINUX}
  cdecl; external zlibso name 'deflateReset'; 
{$ENDIF}
{$IFDEF MSWINDOWS}
  external;
{$ENDIF} 
 
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
	
implementation 
	
 
 
const 
  Levels: array [0..3] of ShortInt = 
    (Z_NO_COMPRESSION, Z_BEST_SPEED, Z_DEFAULT_COMPRESSION, Z_BEST_COMPRESSION); 
 
  _z_errmsg: array[0..9] of PAnsiChar = ( 
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
	
{$IFDEF MSWINDOWS} 
	
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

{$ENDIF}


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
    raise ECompressionError.Create('ZLib error '+IntToStr(code)+': '+_z_errmsg[2-code]); //!!
end;

function DCheck(code: Integer): Integer;
begin
  Result := code;
  if code < 0 then
    raise EDecompressionError.Create('ZLib error '+IntToStr(code)+': '+_z_errmsg[2-code]);  //!!
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
{$IFDEF MSWINDOWS}
  strm.zalloc := zcAlloc;
  strm.zfree := zcFree;
{$ENDIF}
  OutBytes := ((InBytes + (InBytes div 10) + 12) + 255) and not 255;
//  GetMem(OutBuf, OutBytes);
  OutBuf := AllocMem(OutBytes);
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
        strm.next_out := PAnsiChar(Integer(OutBuf) + (Integer(strm.next_out) - Integer(P)));
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
label m_exit;
var
  zstream: TZStreamRec;
  delta  : Integer;
  x:       Integer;
begin
  FillChar(zstream,SizeOf(TZStreamRec),0);

  delta := (InBytes + 255) and not 255;

  if outEstimate = 0 then outBytes := delta
  else outBytes := outEstimate;

  GetMem(outBuf,outBytes);

//  try
    zstream.next_in := inBuf;
    zstream.avail_in := InBytes;
    zstream.next_out := outBuf;
    zstream.avail_out := outBytes;

//    DCheck(InflateInit_(zstream,zlib_version,sizeof(zstream)));
    if (InflateInit_(zstream,zlib_version,sizeof(zstream)) < 0) then
     goto m_exit;

//    try
      while (True) do
      begin
//      DCheck(inflate(zstream,Z_NO_FLUSH)) <> Z_STREAM_END
        x := inflate(zstream,Z_NO_FLUSH);
        if (x < 0) then
         goto m_exit;

        if (x = Z_STREAM_END) then
         break;

        Inc(outBytes,delta);
        ReallocMem(outBuf,outBytes);

        zstream.next_out := PAnsiChar(Integer(outBuf) + zstream.total_out);
        zstream.avail_out := delta;
      end; // while
//    finally
//      DCheck(inflateEnd(zstream));
      if (inflateEnd(zstream) < 0) then
     goto m_exit;
//    end;

    ReallocMem(outBuf,zstream.total_out);
    outBytes := zstream.total_out;
  Exit;

m_exit:
// error
//  except
   if (outBuf <> nil) then
    FreeMem(outBuf);
    outBuf := nil;
   outBytes := 0;
//    raise;
//  end;
end;

end.





