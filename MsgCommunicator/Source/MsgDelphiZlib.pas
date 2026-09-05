unit MsgDelphiZlib;

{$WARNINGS OFF}
{$J+}

{*********************************************************}
{* ZLib compression. This unit is provided as freeware   *}
{* and is written for 32-bit Delphi (D2 and higher).     *}
{*                                                       *}
{* As noted in the source, portions are copyrighted by   *}
{* the following parties:                                *}
{*   Copyright (C) 1995-98 Jean-loup Gailly & Mark Adler *}
{*   Copyright (c) 1998-00 Jacques Nomssi Nzali          *}
{*   Copyright (c) 2000-2001 David O. Martin             *}
{*********************************************************}

{------------------------------------------------------------------------------}
{ This unit builds on a pascal port of the zlib compression routines           }
{ by Jean-loup Gailly and Mark Adler. The original pascal port was             }
{ performed by Jacques Nomssi Nzali as contained in PasZLib which is based     }
{ on zlib 1.1.2. There are some errors in that port which have been fixed      }
{ in this version.                                                             }
{                                                                              }
{ Although most of the code in this unit is derivative, there are some         }
{ important changes (bug fixes). Nevertheless, this code is released as        }
{ freeware with the same permissions as granted by the preceding authors       }
{ (Gailly, Adler, Nzali):                                                      }
{                                                                              }
{   "This software is provided 'as-is', without any express or implied         }
{   warranty.  In no event will the authors be held liable for any damages     }
{   arising from the use of this software.                                     }
{                                                                              }
{   Permission is granted to anyone to use this software for any purpose,      }
{   including commercial applications, and to alter it and redistribute it     }
{   freely, subject to the following restrictions:                             }
{                                                                              }
{   1. The origin of this software must not be misrepresented; you must not    }
{      claim that you wrote the original software. If you use this software    }
{      in a product, an acknowledgment in the product documentation would be   }
{      appreciated but is not required.                                        }
{   2. Altered source versions must be plainly marked as such, and must not    }
{      be misrepresented as being the original software.                       }
{   3. This notice may not be removed or altered from any source               }
{      distribution."                                                          }
{                                                                              }
{ Please direct questions, comments, problems, or fixes regarding this unit    }
{ to domartin@aol.com.                                                         }
{                                                                              }
{ References:                                                                  }
{   ZLib homepage: http://www.info-zip.org/pub/infozip/zlib/                   }
{   PasZLib homepage: http://www.tu-chemnitz.de/~nomssi/paszlib.html           }
{                                                                              }
{ Version history:                                                             }
{   09/19/00  Version 1.0.                                                     }
{   10/30/00  Version 1.1. Removed Patch112 conditional directive (as in       }
{             zlib version 1.1.3 which removed the directive).                 }
{------------------------------------------------------------------------------}

{ Define the following (THREAD_SAFE) to ensure that this code is
  completely thread safe. If it is undefined, then, in extremely rare
  circumstances (failure to dynamically allocate some small arrays), the
  routines may not be thread safe. }

{$DEFINE THREAD_SAFE}

{ Delphi 2 and 3 define the cardinal type as a 31-bit integer that
  is stored in 32-bits. This can result in range check errors
  during compilation. To avoid this, in D2 and D3 we'll define
  cardinal as a longint. In D4 and higher, cardinal uses all
  32-bits so special measures are not required. }

{$IFDEF VER90}   { Delphi 2 }
  {$DEFINE Delphi2or3}
{$ENDIF}

{$IFDEF VER100}  { Delphi 3 }
  {$DEFINE Delphi2or3}
{$ENDIF}

interface

uses SysUtils;

const
  Version = '1.2';

{$IFDEF Delphi2or3}
type
  cardinal = longint;
{$ENDIF}

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ zutil.pas
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

type
  Bytef = byte;
  charf = byte;

  int = integer;
  intf = int;
  uInt = cardinal;
  uIntf = uInt;

  Long = longint;
  uLong = cardinal; { changed so that Delphi2+ all use cardinal--8/11/00 by DOM }
  uLongf = uLong;

  voidp = pointer;
  voidpf = voidp;
  pBytef = ^Bytef;
  pIntf = ^intf;
  puIntf = ^uIntf;
  puLong = ^uLongf;

  ptr2int = uInt;   { a pointer to integer casting is used to do pointer arithmetic }

const
  MaxMemBlock = MaxInt;

type
  zByteArray = array[0..(MaxMemBlock div SizeOf(Bytef)) - 1] of Bytef;
  pzByteArray = ^zByteArray;
  zIntfArray = array[0..(MaxMemBlock div SizeOf(Intf)) - 1] of Intf;
  pzIntfArray = ^zIntfArray;
  zuIntArray = array[0..(MaxMemBlock div SizeOf(uInt)) - 1] of uInt;
  PuIntArray = ^zuIntArray;
  uch = byte;
  uchf = uch;
  ush = word;
  ushf = ush;
  ulg = cardinal;   { changed from LongInt--8/11/00 by DOM }
  unsigned = uInt;
  pcharf = ^charf;
  puchf = ^uchf;
  pushf = ^ushf;
  zuchfArray = zByteArray;
  puchfArray = ^zuchfArray;
  zushfArray = array[0..(MaxMemBlock div SizeOf(ushf)) - 1] of ushf;
  pushfArray = ^zushfArray;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ zlib.h -- interface of the 'zlib' general purpose compression library
  Copyright (C) 1995-1998 Jean-loup Gailly and Mark Adler

  zlib.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

const
  MAX_MEM_LEVEL = 9;
  DEF_MEM_LEVEL = 8;
  MAX_WBITS = 15;
  DEF_WBITS = MAX_WBITS;

type
  pInflate_huft = ^inflate_huft;
  inflate_huft = record
    Exop,
    Bits: Byte;
    base: uInt;
  end;
  huft_field = array[0..(MaxMemBlock div SizeOf(inflate_huft)) - 1] of inflate_huft;
  huft_ptr = ^huft_field;
  ppInflate_huft = ^pInflate_huft;
  inflate_codes_mode = (
    START,
    LEN,
    LENEXT,
    DIST,
    DISTEXT,
    COPY,
    LIT,
    WASH,
    ZEND,
    BADCODE);
  pInflate_codes_state = ^inflate_codes_state;
  inflate_codes_state = record
    mode: inflate_codes_mode;
    len: uInt;
    sub: record
      case Byte of
        0: (code: record
            tree: pInflate_huft;
            need: uInt;
          end);
        1: (lit: uInt);
        2: (copy: record
            get: uInt;
            dist: uInt;
          end);
    end;
    lbits: Byte;
    dbits: Byte;
    ltree: pInflate_huft;
    dtree: pInflate_huft;
  end;
  check_func = function(check: uLong;
    buf: pBytef;
    len: uInt): uLong;
  inflate_block_mode =
    (ZTYPE,
    LENS,
    STORED,
    TABLE,
    BTREE,
    DTREE,
    CODES,
    DRY,
    BLKDONE,
    BLKBAD);
  pInflate_blocks_state = ^inflate_blocks_state;
  inflate_blocks_state = record
    mode: inflate_block_mode;
    sub: record
      case Byte of
        0: (left: uInt);
        1: (trees: record
            table: uInt;
            index: uInt;
            blens: PuIntArray;
            bb: uInt;
            tb: pInflate_huft;
          end);
        2: (decode: record
            tl: pInflate_huft;
            td: pInflate_huft;
            codes: pInflate_codes_state;
          end);
    end;
    last: boolean;
    bitk: uInt;
    bitb: uLong;
    hufts: huft_ptr;
    window: pBytef;
    zend: pBytef;
    read: pBytef;
    write: pBytef;
    checkfn: check_func;
    check: uLong;
  end;
  inflate_mode = (
    METHOD,
    FLAG,
    DICT4,
    DICT3,
    DICT2,
    DICT1,
    DICT0,
    BLOCKS,
    CHECK4,
    CHECK3,
    CHECK2,
    CHECK1,
    DONE,
    BAD);
  pInternal_state = ^internal_state;
  internal_state = record
    mode: inflate_mode;
    sub: record
      case byte of
        0: (method: uInt);
        1: (check: record
            was: uLong;
            need: uLong;
          end);
        2: (marker: uInt);
    end;
    nowrap: boolean;
    wbits: uInt;
    blocks: pInflate_blocks_state;
  end;
  alloc_func = function(opaque: voidpf; items: uInt; size: uInt): voidpf;
  free_func = procedure(opaque: voidpf; address: voidpf);
  z_streamp = ^z_stream;
  z_stream = record
    next_in: pBytef;
    avail_in: uInt;
    total_in: uLong;
    next_out: pBytef;
    avail_out: uInt;
    total_out: uLong;
    msg: string[255];
    state: pInternal_state;
    zalloc: alloc_func;
    zfree: free_func;
    opaque: voidpf;
    data_type: int;
    adler: uLong;
    reserved: uLong;
  end;

const
  Z_NO_FLUSH = 0;
  Z_PARTIAL_FLUSH = 1;
  Z_SYNC_FLUSH = 2;
  Z_FULL_FLUSH = 3;
  Z_FINISH = 4;

  Z_OK = 0;
  Z_STREAM_END = 1;
  Z_NEED_DICT = 2;
  Z_ERRNO = (-1);
  Z_STREAM_ERROR = (-2);
  Z_DATA_ERROR = (-3);
  Z_MEM_ERROR = (-4);
  Z_BUF_ERROR = (-5);
  Z_VERSION_ERROR = (-6);

  Z_NO_COMPRESSION = 0;
  Z_BEST_SPEED = 1;
  Z_BEST_COMPRESSION = 9;
  Z_DEFAULT_COMPRESSION = (-1);

  Z_FILTERED = 1;
  Z_HUFFMAN_ONLY = 2;
  Z_DEFAULT_STRATEGY = 0;

  Z_BINARY = 0;
  Z_ASCII = 1;
  Z_UNKNOWN = 2;

  Z_DEFLATED = 8;

  Z_NULL = nil;

  STORED_BLOCK = 0;
  STATIC_TREES = 1;
  DYN_TREES = 2;

  MIN_MATCH = 3;
  MAX_MATCH = 258;

  PRESET_DICT = $20;

function zlibVersion: string;
function zError(err: int): string;
function ZALLOC(var strm: z_stream; items: uInt; size: uInt): voidpf;
procedure ZFREE(var strm: z_stream; ptr: voidpf);
procedure TRY_FREE(var strm: z_stream; ptr: voidpf);
procedure DeAllocMem(var Buffer);

const
  ZLIB_VERSION: string[10] = '1.1.2';

const
  z_errbase = Z_NEED_DICT;
  z_errmsg: array[0..9] of string[21] =
   ('need dictionary',      { Z_NEED_DICT       2  }
    'stream end',           { Z_STREAM_END      1  }
    '',                     { Z_OK              0  }
    'file error',           { Z_ERRNO         (-1) }
    'stream error',         { Z_STREAM_ERROR  (-2) }
    'data error',           { Z_DATA_ERROR    (-3) }
    'insufficient memory',  { Z_MEM_ERROR     (-4) }
    'buffer error',         { Z_BUF_ERROR     (-5) }
    'incompatible version', { Z_VERSION_ERROR (-6) }
    '');

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ deflate.h -- internal compression state
  deflate.c -- compress data using the deflation algorithm
  Copyright (C) 1995-1996 Jean-loup Gailly.

  zdeflate.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

function deflateInit_(strm: z_streamp;
  level: int; const version: string; stream_size: int): int;
function deflateInit(var strm: z_stream; level: int): int;
function deflate(var strm: z_stream; flush: int): int;
function deflateEnd(var strm: z_stream): int;
function deflateInit2(var strm: z_stream;
  level: int; method: int; windowBits: int;
  memLevel: int; strategy: int): int;
function deflateSetDictionary(var strm: z_stream;
  dictionary: pBytef; dictLength: uint): int;
function deflateCopy(dest: z_streamp; source: z_streamp): int;
function deflateReset(var strm: z_stream): int;
function deflateParams(var strm: z_stream; level: int; strategy: int): int;

const
  deflate_copyright: string = ' deflate 1.1.2 Copyright 1995-1998 Jean-loup Gailly ';

{ If you use the zlib library in a product, an acknowledgment is welcome
  in the documentation of your product. If for some reason you cannot
  include such an acknowledgment, I would appreciate that you keep this
  copyright string in the executable of your product. }

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ inflate.c -- zlib interface to inflate modules
  Copyright (C) 1995-1998 Mark Adler

  zinflate.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

function inflateInit(var z: z_stream): int;
function inflateInit_(z: z_streamp;
  const version: string; stream_size: int): int;
function inflateInit2_(var z: z_stream;
  w: int; const version: string; stream_size: int): int;
function inflateInit2(var z: z_stream; windowBits: int): int;
function inflateEnd(var z: z_stream): int;
function inflateReset(var z: z_stream): int;
function inflate(var z: z_stream; f: int): int;
function inflateSetDictionary(var z: z_stream; dictionary: pBytef;
  dictLength: uInt): int;
function inflateSync(var z: z_stream): int;
function inflateSyncPoint(var z: z_stream): int;

const
  inflate_copyright = 'inflate 1.1.2 Copyright 1995-1998 Mark Adler';

{ If you use the zlib library in a product, an acknowledgment is welcome
  in the documentation of your product. If for some reason you cannot
  include such an acknowledgment, I would appreciate that you keep this
  copyright string in the executable of your product. }


procedure ZLIBCompressBuf(
  const inBuf: Pointer;     { input: pointer to source data }
        inBytes: Integer;   { input: # of bytes in inBuf }
    var outBuf: Pointer;    { output: pointer to newly allocated buffer with compressed data }
    var outBytes: Integer;
  const level: Integer     { input: compression level }
    ); { output: # of bytes in outBuf }
{ This routine compresses data. Level may vary from 0 to 9 (3 to 6 may
  be a reasonable trade-off between speed and compression).

  Compression levels:
    0 = no compression                 (Z_NO_COMPRESSION constant)
    1 = best speed                     (Z_BEST_SPEED constant)
    9 = best compression, but slowest  (Z_BEST_COMPRESSION constant) }

procedure ZLIBDecompressBuf(
  const inBuf: Pointer;     { input: pointer to compressed data }
        inBytes: Integer;   { input: # of bytes in inBuf }
    OutEstimate: Integer; // not needed
    var outBuf: Pointer;    { output: pointer to newly allocated buffer with decompressed data }
    var outBytes: Integer); { output: # of bytes in outBuf }
{ This routine decompresses data that was compressed with CompressBuf. Note
  that this works for all compression levels. }




implementation
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ zutil.pas
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

procedure zmemcpy(destp: pBytef; sourcep: pBytef; len: uInt);
begin
  Move(sourcep^, destp^, len);
end;

function zmemcmp(s1p, s2p: pBytef; len: uInt): int;
var
  j: uInt;
  source, dest: pBytef;
begin
  source := s1p;
  dest := s2p;
  for j := 0 to pred(len) do begin
    if (source^ <> dest^) then begin
      zmemcmp := 2 * Ord(source^ > dest^) - 1;
      exit;
    end;
    Inc(source);
    Inc(dest);
  end;
  zmemcmp := 0;
end;

procedure zmemzero(destp: pBytef; len: uInt);
begin
  FillChar(destp^, len, 0);
end;

procedure zcfree(opaque: voidpf; ptr: voidpf);
begin
  DeAllocMem(ptr);
end;

function zcalloc(opaque: voidpf; items: uInt; size: uInt): voidpf;
var
  p: voidpf;
  memsize: uLong;
begin
  try                                { Modified on 8/13/00 by DOM to return  }
    memsize := uLong(items) * size;  { a nil pointer rather than raise a     }
    GetMem(p, memsize);              { memory error exception (which could   }
    zcalloc := p;                    { cause problems such as skipping       }
  except                             { memory deallocation code)             }
    zcalloc := NIL;
  end;
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ zlib.h -- interface of the 'zlib' general purpose compression library
  Copyright (C) 1995-1998 Jean-loup Gailly and Mark Adler

  zlib.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

function zError(err: int): string;
begin
  zError := z_errmsg[Z_NEED_DICT - err];
end;

function zlibVersion: string;
begin
  zlibVersion := ZLIB_VERSION;
end;

function ZALLOC(var strm: z_stream; items: uInt; size: uInt): voidpf;
begin
  ZALLOC := strm.zalloc(strm.opaque, items, size);
end;

procedure ZFREE(var strm: z_stream; ptr: voidpf);
begin
  strm.zfree(strm.opaque, ptr);
end;

procedure TRY_FREE(var strm: z_stream; ptr: voidpf);
begin
  strm.zfree(strm.opaque, ptr);
end;

procedure DeAllocMem(var Buffer);
begin
   if (Pointer(Buffer) <> nil) then
      begin
      FreeMem(Pointer(Buffer));
      Pointer(Buffer):=nil;
      end;
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ types and macros common to blocks and codes
  Copyright (C) 1995-1998 Mark Adler

  infutil.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

function inflate_flush(var s: inflate_blocks_state;
  var z: z_stream; r: int): int;
var
  n: uInt;
  p: pBytef;
  q: pBytef;
begin
  p := z.next_out;
  q := s.read;
  if ptr2int(q) <= ptr2int(s.write) then
    n := uInt(ptr2int(s.write) - ptr2int(q))
  else
    n := uInt(ptr2int(s.zend) - ptr2int(q));
  if (n > z.avail_out) then
    n := z.avail_out;
  if (n <> 0) and (r = Z_BUF_ERROR) then
    r := Z_OK;
  Dec(z.avail_out, n);
  Inc(z.total_out, n);
  if Assigned(s.checkfn) then begin
    s.check := s.checkfn(s.check, q, n);
    z.adler := s.check;
  end;
  zmemcpy(p, q, n);
  Inc(p, n);
  Inc(q, n);
  if (q = s.zend) then begin
    q := s.window;
    if (s.write = s.zend) then s.write := s.window;
    n := uInt(ptr2int(s.write) - ptr2int(q));
    if (n > z.avail_out) then n := z.avail_out;
    if (n <> 0) and (r = Z_BUF_ERROR) then r := Z_OK;
    Dec(z.avail_out, n);
    Inc(z.total_out, n);
    if Assigned(s.checkfn) then begin
      s.check := s.checkfn(s.check, q, n);
      z.adler := s.check;
    end;
    zmemcpy(p, q, n);
    Inc(p, n);
    Inc(q, n);
  end;
  z.next_out := p;
  s.read := q;
  inflate_flush := r;
end;

const
  inflate_mask: array[0..17 - 1] of uInt = (
    $0000,
    $0001, $0003, $0007, $000F, $001F, $003F, $007F, $00FF,
    $01FF, $03FF, $07FF, $0FFF, $1FFF, $3FFF, $7FFF, $FFFF);

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ inffast.h and
  inffast.c -- process literals and length/distance pairs fast
  Copyright (C) 1995-1998 Mark Adler

  inffast.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

function inflate_fast(bl: uInt;
  bd: uInt; tl: pInflate_huft; td: pInflate_huft;
  var s: inflate_blocks_state; var z: z_stream): int;
var
  t: pInflate_huft;
  e: uInt;
  b: uLong;
  k: uInt;
  p: pBytef;
  n: uInt;
  q: pBytef;
  m: uInt;
  ml: uInt;
  md: uInt;
  c: uInt;
  d: uInt;
  r: pBytef;
begin
  p := z.next_in;
  n := z.avail_in;
  b := s.bitb;
  k := s.bitk;
  q := s.write;
  if ptr2int(q) < ptr2int(s.read) then
    m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
  else
    m := uInt(ptr2int(s.zend) - ptr2int(q));
  ml := inflate_mask[bl];
  md := inflate_mask[bd];
  repeat
    while (k < 20) do begin
      Dec(n);
      b := b or (uLong(p^) shl k);
      Inc(p);
      Inc(k, 8);
    end;
    t := @(huft_ptr(tl)^[uInt(b) and ml]);
    e := t^.exop;
    if (e = 0) then begin
      b := b shr t^.bits;
      Dec(k, t^.bits);
      q^ := Byte(t^.base);
      Inc(q);
      Dec(m);
      continue;
    end;
    repeat
      b := b shr t^.bits;
      Dec(k, t^.bits);
      if (e and 16 <> 0) then begin
        e := e and 15;
        c := t^.base + (uInt(b) and inflate_mask[e]);
        b := b shr e;
        Dec(k, e);
        while (k < 15) do begin
          Dec(n);
          b := b or (uLong(p^) shl k);
          Inc(p);
          Inc(k, 8);
        end;
        t := @huft_ptr(td)^[uInt(b) and md];
        e := t^.exop;
        repeat
          b := b shr t^.bits;
          Dec(k, t^.bits);
          if (e and 16 <> 0) then begin
            e := e and 15;
            while (k < e) do begin
              Dec(n);
              b := b or (uLong(p^) shl k);
              Inc(p);
              Inc(k, 8);
            end;
            d := t^.base + (uInt(b) and inflate_mask[e]);
            b := b shr e;
            Dec(k, e);
            Dec(m, c);
            if (uInt(ptr2int(q) - ptr2int(s.window)) >= d) then begin
              r := q;
              Dec(r, d);
              q^ := r^; Inc(q); Inc(r); Dec(c);
              q^ := r^; Inc(q); Inc(r); Dec(c);
            end
            else begin
              e := d - uInt(ptr2int(q) - ptr2int(s.window));
              r := s.zend;
              Dec(r, e);
              if (c > e) then begin
                Dec(c, e);
                repeat
                  q^ := r^;
                  Inc(q);
                  Inc(r);
                  Dec(e);
                until (e = 0);
                r := s.window;
              end;
            end;
            repeat
              q^ := r^;
              Inc(q);
              Inc(r);
              Dec(c);
            until (c = 0);
            break;
          end
          else if (e and 64 = 0) then begin
            Inc(t, t^.base + (uInt(b) and inflate_mask[e]));
            e := t^.exop;
          end
          else begin
            z.msg := 'invalid distance code';
            c := z.avail_in - n;
            if (k shr 3) < c then
              c := k shr 3;
            Inc(n, c);
            Dec(p, c);
            Dec(k, c shl 3);
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_fast := Z_DATA_ERROR;
            exit;
          end;
        until FALSE;
        break;
      end;
      if (e and 64 = 0) then begin
        Inc(t, t^.base + (uInt(b) and inflate_mask[e]));
        e := t^.exop;
        if (e = 0) then begin
          b := b shr t^.bits;
          Dec(k, t^.bits);
          q^ := Byte(t^.base);
          Inc(q);
          Dec(m);
          break;
        end;
      end
      else if (e and 32 <> 0) then begin
        c := z.avail_in - n;
        if (k shr 3) < c then
          c := k shr 3;
        Inc(n, c);
        Dec(p, c);
        Dec(k, c shl 3);
        s.bitb := b;
        s.bitk := k;
        z.avail_in := n;
        Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
        z.next_in := p;
        s.write := q;
        inflate_fast := Z_STREAM_END;
        exit;
      end
      else begin
        z.msg := 'invalid literal/length code';
        c := z.avail_in - n;
        if (k shr 3) < c then
          c := k shr 3;
        Inc(n, c);
        Dec(p, c);
        Dec(k, c shl 3);
        s.bitb := b;
        s.bitk := k;
        z.avail_in := n;
        Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
        z.next_in := p;
        s.write := q;
        inflate_fast := Z_DATA_ERROR;
        exit;
      end;
    until FALSE;
  until (m < 258) or (n < 10);
  c := z.avail_in - n;
  if (k shr 3) < c then c := k shr 3;
  Inc(n, c);
  Dec(p, c);
  Dec(k, c shl 3);
  s.bitb := b;
  s.bitk := k;
  z.avail_in := n;
  Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
  z.next_in := p;
  s.write := q;
  inflate_fast := Z_OK;
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ infcodes.c -- process literals and length/distance pairs
  Copyright (C) 1995-1998 Mark Adler

  infcodes.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

function inflate_codes_new(bl: uInt;
  bd: uInt; tl: pInflate_huft; td: pInflate_huft;
  var z: z_stream): pInflate_codes_state;
var
  c: pInflate_codes_state;
begin
  c := pInflate_codes_state(ZALLOC(z, 1, sizeof(inflate_codes_state)));
  if (c <> Z_NULL) then begin
    c^.mode := START;
    c^.lbits := Byte(bl);
    c^.dbits := Byte(bd);
    c^.ltree := tl;
    c^.dtree := td;
  end;
  inflate_codes_new := c;
end;

function inflate_codes(var s: inflate_blocks_state;
  var z: z_stream; r: int): int;
var
  j: uInt;
  t: pInflate_huft;
  e: uInt;
  b: uLong;
  k: uInt;
  p: pBytef;
  n: uInt;
  q: pBytef;
  m: uInt;
  f: pBytef;
  c: pInflate_codes_state;
begin
  c := s.sub.decode.codes;
  p := z.next_in;
  n := z.avail_in;
  b := s.bitb;
  k := s.bitk;
  q := s.write;
  if ptr2int(q) < ptr2int(s.read) then
    m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
  else
    m := uInt(ptr2int(s.zend) - ptr2int(q));
  while True do
    case (c^.mode) of
      START:
        begin
          if (m >= 258) and (n >= 10) then begin
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            r := inflate_fast(c^.lbits, c^.dbits, c^.ltree, c^.dtree, s, z);
            p := z.next_in;
            n := z.avail_in;
            b := s.bitb;
            k := s.bitk;
            q := s.write;
            if ptr2int(q) < ptr2int(s.read) then
              m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
            else
              m := uInt(ptr2int(s.zend) - ptr2int(q));
            if (r <> Z_OK) then begin
              if (r = Z_STREAM_END) then
                c^.mode := WASH
              else
                c^.mode := BADCODE;
              continue;
            end;
          end;
          c^.sub.code.need := c^.lbits;
          c^.sub.code.tree := c^.ltree;
          c^.mode := LEN;
        end;
      LEN:
        begin
          j := c^.sub.code.need;
          while (k < j) do begin
            if (n <> 0) then
              r := Z_OK
            else begin
              s.bitb := b;
              s.bitk := k;
              z.avail_in := n;
              Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
              z.next_in := p;
              s.write := q;
              inflate_codes := inflate_flush(s, z, r);
              exit;
            end;
            Dec(n);
            b := b or (uLong(p^) shl k);
            Inc(p);
            Inc(k, 8);
          end;
          t := c^.sub.code.tree;
          Inc(t, uInt(b) and inflate_mask[j]);
          b := b shr t^.bits;
          Dec(k, t^.bits);
          e := uInt(t^.exop);
          if (e = 0) then begin
            c^.sub.lit := t^.base;
            c^.mode := LIT;
            continue;
          end;
          if (e and 16 <> 0) then begin
            c^.sub.copy.get := e and 15;
            c^.len := t^.base;
            c^.mode := LENEXT;
            continue;
          end;
          if (e and 64 = 0) then begin
            c^.sub.code.need := e;
            c^.sub.code.tree := @huft_ptr(t)^[t^.base];
            continue;
          end;
          if (e and 32 <> 0) then begin
            c^.mode := WASH;
            continue;
          end;
          c^.mode := BADCODE;
          z.msg := 'invalid literal/length code';
          r := Z_DATA_ERROR;
          s.bitb := b;
          s.bitk := k;
          z.avail_in := n;
          Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
          z.next_in := p;
          s.write := q;
          inflate_codes := inflate_flush(s, z, r);
          exit;
        end;
      LENEXT:
        begin
          j := c^.sub.copy.get;
          while (k < j) do begin
            if (n <> 0) then
              r := Z_OK
            else begin
              s.bitb := b;
              s.bitk := k;
              z.avail_in := n;
              Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
              z.next_in := p;
              s.write := q;
              inflate_codes := inflate_flush(s, z, r);
              exit;
            end;
            Dec(n);
            b := b or (uLong(p^) shl k);
            Inc(p);
            Inc(k, 8);
          end;
          Inc(c^.len, uInt(b and inflate_mask[j]));
          b := b shr j;
          Dec(k, j);
          c^.sub.code.need := c^.dbits;
          c^.sub.code.tree := c^.dtree;
          c^.mode := DIST;
        end;
      DIST:
        begin
          j := c^.sub.code.need;
          while (k < j) do begin
            if (n <> 0) then
              r := Z_OK
            else begin
              s.bitb := b;
              s.bitk := k;
              z.avail_in := n;
              Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
              z.next_in := p;
              s.write := q;
              inflate_codes := inflate_flush(s, z, r);
              exit;
            end;
            Dec(n);
            b := b or (uLong(p^) shl k);
            Inc(p);
            Inc(k, 8);
          end;
          t := @huft_ptr(c^.sub.code.tree)^[uInt(b) and inflate_mask[j]];
          b := b shr t^.bits;
          Dec(k, t^.bits);
          e := uInt(t^.exop);
          if (e and 16 <> 0) then begin
            c^.sub.copy.get := e and 15;
            c^.sub.copy.dist := t^.base;
            c^.mode := DISTEXT;
            continue;
          end;
          if (e and 64 = 0) then begin
            c^.sub.code.need := e;
            c^.sub.code.tree := @huft_ptr(t)^[t^.base];
            continue;
          end;
          c^.mode := BADCODE;
          z.msg := 'invalid distance code';
          r := Z_DATA_ERROR;
          s.bitb := b;
          s.bitk := k;
          z.avail_in := n;
          Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
          z.next_in := p;
          s.write := q;
          inflate_codes := inflate_flush(s, z, r);
          exit;
        end;
      DISTEXT:
        begin
          j := c^.sub.copy.get;
          while (k < j) do begin
            if (n <> 0) then
              r := Z_OK
            else begin
              s.bitb := b;
              s.bitk := k;
              z.avail_in := n;
              Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
              z.next_in := p;
              s.write := q;
              inflate_codes := inflate_flush(s, z, r);
              exit;
            end;
            Dec(n);
            b := b or (uLong(p^) shl k);
            Inc(p);
            Inc(k, 8);
          end;
          Inc(c^.sub.copy.dist, uInt(b) and inflate_mask[j]);
          b := b shr j;
          Dec(k, j);
          c^.mode := COPY;
        end;
      COPY:
        begin
          f := q;
          Dec(f, c^.sub.copy.dist);
          if (uInt(ptr2int(q) - ptr2int(s.window)) < c^.sub.copy.dist) then begin
            f := s.zend;
            Dec(f, c^.sub.copy.dist - uInt(ptr2int(q) - ptr2int(s.window)));
          end;
          while (c^.len <> 0) do begin
            if (m = 0) then begin
              if (q = s.zend) and (s.read <> s.window) then begin
                q := s.window;
                if ptr2int(q) < ptr2int(s.read) then
                  m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
                else
                  m := uInt(ptr2int(s.zend) - ptr2int(q));
              end;
              if (m = 0) then begin
                s.write := q;
                r := inflate_flush(s, z, r);
                q := s.write;
                if ptr2int(q) < ptr2int(s.read) then
                  m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
                else
                  m := uInt(ptr2int(s.zend) - ptr2int(q));
                if (q = s.zend) and (s.read <> s.window) then begin
                  q := s.window;
                  if ptr2int(q) < ptr2int(s.read) then
                    m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
                  else
                    m := uInt(ptr2int(s.zend) - ptr2int(q));
                end;
                if (m = 0) then begin
                  s.bitb := b;
                  s.bitk := k;
                  z.avail_in := n;
                  Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
                  z.next_in := p;
                  s.write := q;
                  inflate_codes := inflate_flush(s, z, r);
                  exit;
                end;
              end;
            end;
            r := Z_OK;
            q^ := f^;
            Inc(q);
            Inc(f);
            Dec(m);
            if (f = s.zend) then
              f := s.window;
            Dec(c^.len);
          end;
          c^.mode := START;
        end;
      LIT:
        begin
          if (m = 0) then begin
            if (q = s.zend) and (s.read <> s.window) then begin
              q := s.window;
              if ptr2int(q) < ptr2int(s.read) then
                m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
              else
                m := uInt(ptr2int(s.zend) - ptr2int(q));
            end;
            if (m = 0) then begin
              s.write := q;
              r := inflate_flush(s, z, r);
              q := s.write;
              if ptr2int(q) < ptr2int(s.read) then
                m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
              else
                m := uInt(ptr2int(s.zend) - ptr2int(q));
              if (q = s.zend) and (s.read <> s.window) then begin
                q := s.window;
                if ptr2int(q) < ptr2int(s.read) then
                  m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
                else
                  m := uInt(ptr2int(s.zend) - ptr2int(q));
              end;
              if (m = 0) then begin
                s.bitb := b;
                s.bitk := k;
                z.avail_in := n;
                Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
                z.next_in := p;
                s.write := q;
                inflate_codes := inflate_flush(s, z, r);
                exit;
              end;
            end;
          end;
          r := Z_OK;
          q^ := c^.sub.lit;
          Inc(q);
          Dec(m);
          c^.mode := START;
        end;
      WASH:
        begin
          if (k > 7) then begin
            Dec(k, 8);
            Inc(n);
            Dec(p);
          end;
          s.write := q;
          r := inflate_flush(s, z, r);
          q := s.write;
          if ptr2int(q) < ptr2int(s.read) then
            m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
          else
            m := uInt(ptr2int(s.zend) - ptr2int(q));
          if (s.read <> s.write) then begin
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_codes := inflate_flush(s, z, r);
            exit;
          end;
          c^.mode := ZEND;
        end;
      ZEND:
        begin
          r := Z_STREAM_END;
          s.bitb := b;
          s.bitk := k;
          z.avail_in := n;
          Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
          z.next_in := p;
          s.write := q;
          inflate_codes := inflate_flush(s, z, r);
          exit;
        end;
      BADCODE:
        begin
          r := Z_DATA_ERROR;
          s.bitb := b;
          s.bitk := k;
          z.avail_in := n;
          Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
          z.next_in := p;
          s.write := q;
          inflate_codes := inflate_flush(s, z, r);
          exit;
        end;
    else
      begin
        r := Z_STREAM_ERROR;
        s.bitb := b;
        s.bitk := k;
        z.avail_in := n;
        Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
        z.next_in := p;
        s.write := q;
        inflate_codes := inflate_flush(s, z, r);
        exit;
      end;
    end;
  inflate_codes := Z_STREAM_ERROR;
end;

procedure inflate_codes_free(c: pInflate_codes_state;
  var z: z_stream);
begin
  ZFREE(z, c);
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ inftrees.h -- header to use inftrees.c
  inftrees.c -- generate Huffman trees for efficient decoding
  Copyright (C) 1995-1998 Mark Adler

  inftrees.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

const
  MANY = 1440;

const
  LENGTH_CODES = 29;
  LITERALS = 256;
  L_CODES = (LITERALS + 1 + LENGTH_CODES);
  D_CODES = 30;
  BL_CODES = 19;
  HEAP_SIZE = (2 * L_CODES + 1);
  MAX_BITS = 15;
  INIT_STATE = 42;
  BUSY_STATE = 113;
  FINISH_STATE = 666;

type
  ct_data_ptr = ^ct_data;
  ct_data = record
    fc: record
      case byte of
        0: (freq: ush);
        1: (code: ush);
    end;
    dl: record
      case byte of
        0: (dad: ush);
        1: (len: ush);
    end;
  end;
  ltree_type = array[0..HEAP_SIZE - 1] of ct_data;
  dtree_type = array[0..2 * D_CODES + 1 - 1] of ct_data;
  htree_type = array[0..2 * BL_CODES + 1 - 1] of ct_data;
  tree_type = array[0..(MaxMemBlock div SizeOf(ct_data)) - 1] of ct_data;
  tree_ptr = ^tree_type;
  ltree_ptr = ^ltree_type;
  dtree_ptr = ^dtree_type;
  htree_ptr = ^htree_type;
  static_tree_desc_ptr = ^static_tree_desc;
  static_tree_desc = record
    static_tree: tree_ptr;
    extra_bits: pzIntfArray;
    extra_base: int;
    elems: int;
    max_length: int;
  end;
  tree_desc_ptr = ^tree_desc;
  tree_desc = record
    dyn_tree: tree_ptr;
    max_code: int;
    stat_desc: static_tree_desc_ptr;
  end;
  Pos = ush;
  Posf = Pos; {FAR}
  IPos = uInt;
  pPosf = ^Posf;
  zPosfArray = array[0..(MaxMemBlock div SizeOf(Posf)) - 1] of Posf;
  pzPosfArray = ^zPosfArray;
  deflate_state_ptr = ^deflate_state;
  deflate_state = record
    strm: z_streamp;
    status: int;
    pending_buf: pzByteArray;
    pending_buf_size: ulg;
    pending_out: pBytef;
    pending: int;
    noheader: int;
    data_type: Byte;
    method: Byte;
    last_flush: int;
    w_size: uInt;
    w_bits: uInt;
    w_mask: uInt;
    window: pzByteArray;
    window_size: ulg;
    prev: pzPosfArray;
    head: pzPosfArray;
    ins_h: uInt;
    hash_size: uInt;
    hash_bits: uInt;
    hash_mask: uInt;
    hash_shift: uInt;
    block_start: long;
    match_length: uInt;
    prev_match: IPos;
    match_available: boolean;
    strstart: uInt;
    match_start: uInt;
    lookahead: uInt;
    prev_length: uInt;
    max_chain_length: uInt;
    level: int;
    strategy: int;
    good_match: uInt;
    nice_match: int;
    dyn_ltree: ltree_type;
    dyn_dtree: dtree_type;
    bl_tree: htree_type;
    l_desc: tree_desc;
    d_desc: tree_desc;
    bl_desc: tree_desc;
    bl_count: array[0..MAX_BITS + 1 - 1] of ush;
    heap: array[0..2 * L_CODES + 1 - 1] of int;
    heap_len: int;
    heap_max: int;
    depth: array[0..2 * L_CODES + 1 - 1] of uch;
    l_buf: puchfArray;
    lit_bufsize: uInt;
    last_lit: uInt;
    d_buf: pushfArray;
    opt_len: ulg;
    static_len: ulg;
    compressed_len: ulg;
    matches: uInt;
    last_eob_len: int;
    bi_buf: ush;
    bi_valid: int;
    case byte of
      0: (max_lazy_match: uInt);
      1: (max_insert_length: uInt);
  end;

const
  cplens: array[0..30] of uInt
  = (3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
    35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258, 0, 0);

  invalid_code = 112;

  cplext: array[0..30] of uInt
  = (0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
    3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0, invalid_code, invalid_code);

  cpdist: array[0..29] of uInt
  = (1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
    257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
    8193, 12289, 16385, 24577);

  cpdext: array[0..29] of uInt
  = (0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
    7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
    12, 12, 13, 13);

const
  BMAX = 15;

{$DEFINE USE_PTR}

function huft_build(var b: array of uIntf;
  n: uInt; s: uInt; const d: array of uIntf; const e: array of uIntf;
  t: ppInflate_huft; var m: uIntf; var hp: array of inflate_huft;
  var hn: uInt; var v: array of uIntf): int;
{ Given a list of code lengths and a maximum table size, make a set of
  tables to decode that set of codes.  Return Z_OK on success, Z_BUF_ERROR
  if the given code set is incomplete (the tables are still built in this
  case), Z_DATA_ERROR if the input is invalid (an over-subscribed set of
  lengths), or Z_MEM_ERROR if not enough memory. }
var
  a: uInt;
  c: array[0..BMAX] of uInt;
  f: uInt;
  g: int;
  h: int;
  i: uInt;
  j: uInt;
  k: Int;
  l: int;
  mask: uInt;
  p: ^uIntf;
  q: pInflate_huft;
  r: inflate_huft;
  u: array[0..BMAX - 1] of pInflate_huft;
  w: int;
  x: array[0..BMAX] of uInt;
{$IFDEF USE_PTR}
  xp: puIntf;
{$ELSE}
  xp: uInt;
{$ENDIF}
  y: int;
  z: uInt;
begin
  FillChar(c, SizeOf(c), 0);
  for i := 0 to n - 1 do
    Inc(c[b[i]]);
  if (c[0] = n) then begin
    t^ := pInflate_huft(nil);
    m := 0;
    huft_build := Z_OK;
    Exit;
  end;
  l := m;
  for j := 1 to BMAX do
    if (c[j] <> 0) then
      break;
  k := j;
  if (uInt(l) < j) then
    l := j;
  for i := BMAX downto 1 do
    if (c[i] <> 0) then
      break;
  g := i;
  if (uInt(l) > i) then
    l := i;
  m := l;
  y := 1 shl j;
  while (j < i) do begin
    Dec(y, c[j]);
    if (y < 0) then begin
      huft_build := Z_DATA_ERROR;
      exit;
    end;
    Inc(j);
    y := y shl 1
  end;
  Dec(y, c[i]);
  if (y < 0) then begin
    huft_build := Z_DATA_ERROR;
    exit;
  end;
  Inc(c[i], y);

{$IFDEF USE_PTR}
  x[1] := 0;
  j := 0;
  p := @c[1];
  xp := @x[2];
  dec(i);
  while (i > 0) do begin
    inc(j, p^);
    xp^ := j;
    inc(p);
    inc(xp);
    dec(i);
  end;
{$ELSE}
  x[1] := 0;
  j := 0;
  for i := 1 to g do begin
    x[i] := j;
    Inc(j, c[i]);
  end;
{$ENDIF}

  for i := 0 to n - 1 do begin
    j := b[i];
    if (j <> 0) then begin
      v[x[j]] := i;
      Inc(x[j]);
    end;
  end;
  n := x[g];
  i := 0;
  x[0] := 0;
  p := Addr(v);
  h := -1;
  w := -l;
  u[0] := pInflate_huft(nil);
  q := pInflate_huft(nil);
  z := 0;
  while (k <= g) do begin
    a := c[k];
    while (a <> 0) do begin
      Dec(a);
      while (k > w + l) do begin
        Inc(h);
        Inc(w, l);
        z := g - w;
        if (z > uInt(l)) then z := l;
        j := k - w;
        f := 1 shl j;
        if (f > a + 1) then begin
          Dec(f, a + 1);
{$IFDEF USE_PTR}
          xp := Addr(c[k]);
          if (j < z) then begin
            Inc(j);
            while (j < z) do begin
              f := f shl 1;
              Inc(xp);
              if (f <= xp^) then
                break;
              Dec(f, xp^);
              Inc(j);
            end;
          end;
{$ELSE}
          xp := k;
          if (j < z) then begin
            Inc(j);
            while (j < z) do begin
              f := f * 2;
              Inc(xp);
              if (f <= c[xp]) then Break;
              Dec(f, c[xp]);
              Inc(j);
            end;
          end;
{$ENDIF}
        end;
        z := 1 shl j;
        if (hn + z > MANY) then begin
          huft_build := Z_MEM_ERROR;
          exit;
        end;
        q := @hp[hn];
        u[h] := q;
        Inc(hn, z);
        if (h <> 0) then begin
          x[h] := i;
          r.bits := Byte(l);
          r.exop := Byte(j);
          j := i shr (w - l);
          r.base := (ptr2int(q) - ptr2int(u[h - 1])) div sizeof(q^) - j;
          huft_Ptr(u[h - 1])^[j] := r;
        end
        else
          t^ := q;
      end;
      r.bits := Byte(k - w);
      if ptr2int(p) >= ptr2int(@(v[n])) then
        r.exop := 128 + 64
      else
        if (p^ < s) then begin
          if (p^ < 256) then
            r.exop := 0
          else
            r.exop := 32 + 64;
          r.base := p^;
          Inc(p);
        end
        else begin
          r.exop := Byte(e[p^ - s] + 16 + 64);
          r.base := d[p^ - s];
          Inc(p);
        end;
      f := 1 shl (k - w);
      j := i shr w;
      while (j < z) do begin
        huft_Ptr(q)^[j] := r;
        Inc(j, f);
      end;
      j := 1 shl (k - 1);
      while (i and j) <> 0 do begin
        i := i xor j;
        j := j shr 1
      end;
      i := i xor j;
      mask := (1 shl w) - 1;
      while ((i and mask) <> x[h]) do begin
        Dec(h);
        Dec(w, l);
        mask := (1 shl w) - 1;
      end;
    end;
    Inc(k);
  end;

  { Return Z_BUF_ERROR if we were given an incomplete table }
  if (y <> 0) and (g <> 1) then
    huft_build := Z_BUF_ERROR
  else
    huft_build := Z_OK;
end;

function inflate_trees_bits(var c: array of uIntf;
  var bb: uIntf; var tb: pinflate_huft; var hp: array of Inflate_huft;
  var z: z_stream): int;
var
  r: int;
  hn: uInt;
  v: PuIntArray;
begin
  hn := 0;
  v := PuIntArray(ZALLOC(z, 19, sizeof(uInt)));
  if (v = Z_NULL) then begin
    inflate_trees_bits := Z_MEM_ERROR;
    exit;
  end;
  r := huft_build(c, 19, 19, cplens, cplext, @tb, bb, hp, hn, v^);
  if (r = Z_DATA_ERROR) then
    z.msg := 'oversubscribed dynamic bit lengths tree'
  else if (r = Z_BUF_ERROR) or (bb = 0) then begin
    z.msg := 'incomplete dynamic bit lengths tree';
    r := Z_DATA_ERROR;
  end;
  ZFREE(z, v);
  inflate_trees_bits := r;
end;

function inflate_trees_dynamic(nl: uInt;
  nd: uInt; var c: array of uIntf; var bl: uIntf; var bd: uIntf;
  var tl: pInflate_huft; var td: pInflate_huft; var hp: array of Inflate_huft;
  var z: z_stream): int;
var
  r: int;
  hn: uInt;
  v: PuIntArray;
begin
  hn := 0;
  v := PuIntArray(ZALLOC(z, 288, sizeof(uInt)));
  if (v = Z_NULL) then begin
    inflate_trees_dynamic := Z_MEM_ERROR;
    exit;
  end;
  r := huft_build(c, nl, 257, cplens, cplext, @tl, bl, hp, hn, v^);
  if (r <> Z_OK) or (bl = 0) then begin
    if (r = Z_DATA_ERROR) then
      z.msg := 'oversubscribed literal/length tree'
    else if (r <> Z_MEM_ERROR) then begin
      z.msg := 'incomplete literal/length tree';
      r := Z_DATA_ERROR;
    end;
    ZFREE(z, v);
    inflate_trees_dynamic := r;
    exit;
  end;
  r := huft_build(puIntArray(@c[nl])^, nd, 0, cpdist, cpdext, @td, bd, hp, hn, v^);
  if (r <> Z_OK) or ((bd = 0) and (nl > 257)) then begin
    if (r = Z_DATA_ERROR) then
      z.msg := 'oversubscribed literal/length tree'
    else if (r = Z_BUF_ERROR) then begin
      z.msg := 'incomplete literal/length tree';
      r := Z_DATA_ERROR;
    end
    else if (r <> Z_MEM_ERROR) then begin
      z.msg := 'empty distance tree with lengths';
      r := Z_DATA_ERROR;
    end;
    ZFREE(z, v);
    inflate_trees_dynamic := r;
    exit;
  end;
  ZFREE(z, v);
  inflate_trees_dynamic := Z_OK;
end;

{$IFDEF THREAD_SAFE}
  {$UNDEF BUILDFIXED}          { Use pre-built tables }
{$ELSE
  {$DEFINE BUILDFIXED}         { Build tables on first call to inflate_trees_fixed() }
{$ENDIF}

{$IFDEF BUILDFIXED}
const
  fixed_built: Boolean = False;
  FIXEDH = 544;

var
  fixed_mem: array[0..FIXEDH - 1] of inflate_huft;
  fixed_bl: uInt;
  fixed_bd: uInt;
  fixed_tl: pInflate_huft;
  fixed_td: pInflate_huft;

{$ELSE}
const
  fixed_bl: uInt  = 9;
  fixed_bd: uInt = 5;
  fixed_tl: array[0..512 - 1] of inflate_huft = (
    (Exop:96;Bits:7;base:256), (Exop:0;Bits:8;base:80), (Exop:0;Bits:8;base:16), (Exop:84;Bits:8;base:115),
    (Exop:82;Bits:7;base:31), (Exop:0;Bits:8;base:112), (Exop:0;Bits:8;base:48), (Exop:0;Bits:9;base:192),
    (Exop:80;Bits:7;base:10), (Exop:0;Bits:8;base:96), (Exop:0;Bits:8;base:32), (Exop:0;Bits:9;base:160),
    (Exop:0;Bits:8;base:0), (Exop:0;Bits:8;base:128), (Exop:0;Bits:8;base:64), (Exop:0;Bits:9;base:224),
    (Exop:80;Bits:7;base:6), (Exop:0;Bits:8;base:88), (Exop:0;Bits:8;base:24), (Exop:0;Bits:9;base:144),
    (Exop:83;Bits:7;base:59), (Exop:0;Bits:8;base:120), (Exop:0;Bits:8;base:56), (Exop:0;Bits:9;base:208),
    (Exop:81;Bits:7;base:17), (Exop:0;Bits:8;base:104), (Exop:0;Bits:8;base:40), (Exop:0;Bits:9;base:176),
    (Exop:0;Bits:8;base:8), (Exop:0;Bits:8;base:136), (Exop:0;Bits:8;base:72), (Exop:0;Bits:9;base:240),
    (Exop:80;Bits:7;base:4), (Exop:0;Bits:8;base:84), (Exop:0;Bits:8;base:20), (Exop:85;Bits:8;base:227),
    (Exop:83;Bits:7;base:43), (Exop:0;Bits:8;base:116), (Exop:0;Bits:8;base:52), (Exop:0;Bits:9;base:200),
    (Exop:81;Bits:7;base:13), (Exop:0;Bits:8;base:100), (Exop:0;Bits:8;base:36), (Exop:0;Bits:9;base:168),
    (Exop:0;Bits:8;base:4), (Exop:0;Bits:8;base:132), (Exop:0;Bits:8;base:68), (Exop:0;Bits:9;base:232),
    (Exop:80;Bits:7;base:8), (Exop:0;Bits:8;base:92), (Exop:0;Bits:8;base:28), (Exop:0;Bits:9;base:152),
    (Exop:84;Bits:7;base:83), (Exop:0;Bits:8;base:124), (Exop:0;Bits:8;base:60), (Exop:0;Bits:9;base:216),
    (Exop:82;Bits:7;base:23), (Exop:0;Bits:8;base:108), (Exop:0;Bits:8;base:44), (Exop:0;Bits:9;base:184),
    (Exop:0;Bits:8;base:12), (Exop:0;Bits:8;base:140), (Exop:0;Bits:8;base:76), (Exop:0;Bits:9;base:248),
    (Exop:80;Bits:7;base:3), (Exop:0;Bits:8;base:82), (Exop:0;Bits:8;base:18), (Exop:85;Bits:8;base:163),
    (Exop:83;Bits:7;base:35), (Exop:0;Bits:8;base:114), (Exop:0;Bits:8;base:50), (Exop:0;Bits:9;base:196),
    (Exop:81;Bits:7;base:11), (Exop:0;Bits:8;base:98), (Exop:0;Bits:8;base:34), (Exop:0;Bits:9;base:164),
    (Exop:0;Bits:8;base:2), (Exop:0;Bits:8;base:130), (Exop:0;Bits:8;base:66), (Exop:0;Bits:9;base:228),
    (Exop:80;Bits:7;base:7), (Exop:0;Bits:8;base:90), (Exop:0;Bits:8;base:26), (Exop:0;Bits:9;base:148),
    (Exop:84;Bits:7;base:67), (Exop:0;Bits:8;base:122), (Exop:0;Bits:8;base:58), (Exop:0;Bits:9;base:212),
    (Exop:82;Bits:7;base:19), (Exop:0;Bits:8;base:106), (Exop:0;Bits:8;base:42), (Exop:0;Bits:9;base:180),
    (Exop:0;Bits:8;base:10), (Exop:0;Bits:8;base:138), (Exop:0;Bits:8;base:74), (Exop:0;Bits:9;base:244),
    (Exop:80;Bits:7;base:5), (Exop:0;Bits:8;base:86), (Exop:0;Bits:8;base:22), (Exop:192;Bits:8;base:0),
    (Exop:83;Bits:7;base:51), (Exop:0;Bits:8;base:118), (Exop:0;Bits:8;base:54), (Exop:0;Bits:9;base:204),
    (Exop:81;Bits:7;base:15), (Exop:0;Bits:8;base:102), (Exop:0;Bits:8;base:38), (Exop:0;Bits:9;base:172),
    (Exop:0;Bits:8;base:6), (Exop:0;Bits:8;base:134), (Exop:0;Bits:8;base:70), (Exop:0;Bits:9;base:236),
    (Exop:80;Bits:7;base:9), (Exop:0;Bits:8;base:94), (Exop:0;Bits:8;base:30), (Exop:0;Bits:9;base:156),
    (Exop:84;Bits:7;base:99), (Exop:0;Bits:8;base:126), (Exop:0;Bits:8;base:62), (Exop:0;Bits:9;base:220),
    (Exop:82;Bits:7;base:27), (Exop:0;Bits:8;base:110), (Exop:0;Bits:8;base:46), (Exop:0;Bits:9;base:188),
    (Exop:0;Bits:8;base:14), (Exop:0;Bits:8;base:142), (Exop:0;Bits:8;base:78), (Exop:0;Bits:9;base:252),
    (Exop:96;Bits:7;base:256), (Exop:0;Bits:8;base:81), (Exop:0;Bits:8;base:17), (Exop:85;Bits:8;base:131),
    (Exop:82;Bits:7;base:31), (Exop:0;Bits:8;base:113), (Exop:0;Bits:8;base:49), (Exop:0;Bits:9;base:194),
    (Exop:80;Bits:7;base:10), (Exop:0;Bits:8;base:97), (Exop:0;Bits:8;base:33), (Exop:0;Bits:9;base:162),
    (Exop:0;Bits:8;base:1), (Exop:0;Bits:8;base:129), (Exop:0;Bits:8;base:65), (Exop:0;Bits:9;base:226),
    (Exop:80;Bits:7;base:6), (Exop:0;Bits:8;base:89), (Exop:0;Bits:8;base:25), (Exop:0;Bits:9;base:146),
    (Exop:83;Bits:7;base:59), (Exop:0;Bits:8;base:121), (Exop:0;Bits:8;base:57), (Exop:0;Bits:9;base:210),
    (Exop:81;Bits:7;base:17), (Exop:0;Bits:8;base:105), (Exop:0;Bits:8;base:41), (Exop:0;Bits:9;base:178),
    (Exop:0;Bits:8;base:9), (Exop:0;Bits:8;base:137), (Exop:0;Bits:8;base:73), (Exop:0;Bits:9;base:242),
    (Exop:80;Bits:7;base:4), (Exop:0;Bits:8;base:85), (Exop:0;Bits:8;base:21), (Exop:80;Bits:8;base:258),
    (Exop:83;Bits:7;base:43), (Exop:0;Bits:8;base:117), (Exop:0;Bits:8;base:53), (Exop:0;Bits:9;base:202),
    (Exop:81;Bits:7;base:13), (Exop:0;Bits:8;base:101), (Exop:0;Bits:8;base:37), (Exop:0;Bits:9;base:170),
    (Exop:0;Bits:8;base:5), (Exop:0;Bits:8;base:133), (Exop:0;Bits:8;base:69), (Exop:0;Bits:9;base:234),
    (Exop:80;Bits:7;base:8), (Exop:0;Bits:8;base:93), (Exop:0;Bits:8;base:29), (Exop:0;Bits:9;base:154),
    (Exop:84;Bits:7;base:83), (Exop:0;Bits:8;base:125), (Exop:0;Bits:8;base:61), (Exop:0;Bits:9;base:218),
    (Exop:82;Bits:7;base:23), (Exop:0;Bits:8;base:109), (Exop:0;Bits:8;base:45), (Exop:0;Bits:9;base:186),
    (Exop:0;Bits:8;base:13), (Exop:0;Bits:8;base:141), (Exop:0;Bits:8;base:77), (Exop:0;Bits:9;base:250),
    (Exop:80;Bits:7;base:3), (Exop:0;Bits:8;base:83), (Exop:0;Bits:8;base:19), (Exop:85;Bits:8;base:195),
    (Exop:83;Bits:7;base:35), (Exop:0;Bits:8;base:115), (Exop:0;Bits:8;base:51), (Exop:0;Bits:9;base:198),
    (Exop:81;Bits:7;base:11), (Exop:0;Bits:8;base:99), (Exop:0;Bits:8;base:35), (Exop:0;Bits:9;base:166),
    (Exop:0;Bits:8;base:3), (Exop:0;Bits:8;base:131), (Exop:0;Bits:8;base:67), (Exop:0;Bits:9;base:230),
    (Exop:80;Bits:7;base:7), (Exop:0;Bits:8;base:91), (Exop:0;Bits:8;base:27), (Exop:0;Bits:9;base:150),
    (Exop:84;Bits:7;base:67), (Exop:0;Bits:8;base:123), (Exop:0;Bits:8;base:59), (Exop:0;Bits:9;base:214),
    (Exop:82;Bits:7;base:19), (Exop:0;Bits:8;base:107), (Exop:0;Bits:8;base:43), (Exop:0;Bits:9;base:182),
    (Exop:0;Bits:8;base:11), (Exop:0;Bits:8;base:139), (Exop:0;Bits:8;base:75), (Exop:0;Bits:9;base:246),
    (Exop:80;Bits:7;base:5), (Exop:0;Bits:8;base:87), (Exop:0;Bits:8;base:23), (Exop:192;Bits:8;base:0),
    (Exop:83;Bits:7;base:51), (Exop:0;Bits:8;base:119), (Exop:0;Bits:8;base:55), (Exop:0;Bits:9;base:206),
    (Exop:81;Bits:7;base:15), (Exop:0;Bits:8;base:103), (Exop:0;Bits:8;base:39), (Exop:0;Bits:9;base:174),
    (Exop:0;Bits:8;base:7), (Exop:0;Bits:8;base:135), (Exop:0;Bits:8;base:71), (Exop:0;Bits:9;base:238),
    (Exop:80;Bits:7;base:9), (Exop:0;Bits:8;base:95), (Exop:0;Bits:8;base:31), (Exop:0;Bits:9;base:158),
    (Exop:84;Bits:7;base:99), (Exop:0;Bits:8;base:127), (Exop:0;Bits:8;base:63), (Exop:0;Bits:9;base:222),
    (Exop:82;Bits:7;base:27), (Exop:0;Bits:8;base:111), (Exop:0;Bits:8;base:47), (Exop:0;Bits:9;base:190),
    (Exop:0;Bits:8;base:15), (Exop:0;Bits:8;base:143), (Exop:0;Bits:8;base:79), (Exop:0;Bits:9;base:254),
    (Exop:96;Bits:7;base:256), (Exop:0;Bits:8;base:80), (Exop:0;Bits:8;base:16), (Exop:84;Bits:8;base:115),
    (Exop:82;Bits:7;base:31), (Exop:0;Bits:8;base:112), (Exop:0;Bits:8;base:48), (Exop:0;Bits:9;base:193),
    (Exop:80;Bits:7;base:10), (Exop:0;Bits:8;base:96), (Exop:0;Bits:8;base:32), (Exop:0;Bits:9;base:161),
    (Exop:0;Bits:8;base:0), (Exop:0;Bits:8;base:128), (Exop:0;Bits:8;base:64), (Exop:0;Bits:9;base:225),
    (Exop:80;Bits:7;base:6), (Exop:0;Bits:8;base:88), (Exop:0;Bits:8;base:24), (Exop:0;Bits:9;base:145),
    (Exop:83;Bits:7;base:59), (Exop:0;Bits:8;base:120), (Exop:0;Bits:8;base:56), (Exop:0;Bits:9;base:209),
    (Exop:81;Bits:7;base:17), (Exop:0;Bits:8;base:104), (Exop:0;Bits:8;base:40), (Exop:0;Bits:9;base:177),
    (Exop:0;Bits:8;base:8), (Exop:0;Bits:8;base:136), (Exop:0;Bits:8;base:72), (Exop:0;Bits:9;base:241),
    (Exop:80;Bits:7;base:4), (Exop:0;Bits:8;base:84), (Exop:0;Bits:8;base:20), (Exop:85;Bits:8;base:227),
    (Exop:83;Bits:7;base:43), (Exop:0;Bits:8;base:116), (Exop:0;Bits:8;base:52), (Exop:0;Bits:9;base:201),
    (Exop:81;Bits:7;base:13), (Exop:0;Bits:8;base:100), (Exop:0;Bits:8;base:36), (Exop:0;Bits:9;base:169),
    (Exop:0;Bits:8;base:4), (Exop:0;Bits:8;base:132), (Exop:0;Bits:8;base:68), (Exop:0;Bits:9;base:233),
    (Exop:80;Bits:7;base:8), (Exop:0;Bits:8;base:92), (Exop:0;Bits:8;base:28), (Exop:0;Bits:9;base:153),
    (Exop:84;Bits:7;base:83), (Exop:0;Bits:8;base:124), (Exop:0;Bits:8;base:60), (Exop:0;Bits:9;base:217),
    (Exop:82;Bits:7;base:23), (Exop:0;Bits:8;base:108), (Exop:0;Bits:8;base:44), (Exop:0;Bits:9;base:185),
    (Exop:0;Bits:8;base:12), (Exop:0;Bits:8;base:140), (Exop:0;Bits:8;base:76), (Exop:0;Bits:9;base:249),
    (Exop:80;Bits:7;base:3), (Exop:0;Bits:8;base:82), (Exop:0;Bits:8;base:18), (Exop:85;Bits:8;base:163),
    (Exop:83;Bits:7;base:35), (Exop:0;Bits:8;base:114), (Exop:0;Bits:8;base:50), (Exop:0;Bits:9;base:197),
    (Exop:81;Bits:7;base:11), (Exop:0;Bits:8;base:98), (Exop:0;Bits:8;base:34), (Exop:0;Bits:9;base:165),
    (Exop:0;Bits:8;base:2), (Exop:0;Bits:8;base:130), (Exop:0;Bits:8;base:66), (Exop:0;Bits:9;base:229),
    (Exop:80;Bits:7;base:7), (Exop:0;Bits:8;base:90), (Exop:0;Bits:8;base:26), (Exop:0;Bits:9;base:149),
    (Exop:84;Bits:7;base:67), (Exop:0;Bits:8;base:122), (Exop:0;Bits:8;base:58), (Exop:0;Bits:9;base:213),
    (Exop:82;Bits:7;base:19), (Exop:0;Bits:8;base:106), (Exop:0;Bits:8;base:42), (Exop:0;Bits:9;base:181),
    (Exop:0;Bits:8;base:10), (Exop:0;Bits:8;base:138), (Exop:0;Bits:8;base:74), (Exop:0;Bits:9;base:245),
    (Exop:80;Bits:7;base:5), (Exop:0;Bits:8;base:86), (Exop:0;Bits:8;base:22), (Exop:192;Bits:8;base:0),
    (Exop:83;Bits:7;base:51), (Exop:0;Bits:8;base:118), (Exop:0;Bits:8;base:54), (Exop:0;Bits:9;base:205),
    (Exop:81;Bits:7;base:15), (Exop:0;Bits:8;base:102), (Exop:0;Bits:8;base:38), (Exop:0;Bits:9;base:173),
    (Exop:0;Bits:8;base:6), (Exop:0;Bits:8;base:134), (Exop:0;Bits:8;base:70), (Exop:0;Bits:9;base:237),
    (Exop:80;Bits:7;base:9), (Exop:0;Bits:8;base:94), (Exop:0;Bits:8;base:30), (Exop:0;Bits:9;base:157),
    (Exop:84;Bits:7;base:99), (Exop:0;Bits:8;base:126), (Exop:0;Bits:8;base:62), (Exop:0;Bits:9;base:221),
    (Exop:82;Bits:7;base:27), (Exop:0;Bits:8;base:110), (Exop:0;Bits:8;base:46), (Exop:0;Bits:9;base:189),
    (Exop:0;Bits:8;base:14), (Exop:0;Bits:8;base:142), (Exop:0;Bits:8;base:78), (Exop:0;Bits:9;base:253),
    (Exop:96;Bits:7;base:256), (Exop:0;Bits:8;base:81), (Exop:0;Bits:8;base:17), (Exop:85;Bits:8;base:131),
    (Exop:82;Bits:7;base:31), (Exop:0;Bits:8;base:113), (Exop:0;Bits:8;base:49), (Exop:0;Bits:9;base:195),
    (Exop:80;Bits:7;base:10), (Exop:0;Bits:8;base:97), (Exop:0;Bits:8;base:33), (Exop:0;Bits:9;base:163),
    (Exop:0;Bits:8;base:1), (Exop:0;Bits:8;base:129), (Exop:0;Bits:8;base:65), (Exop:0;Bits:9;base:227),
    (Exop:80;Bits:7;base:6), (Exop:0;Bits:8;base:89), (Exop:0;Bits:8;base:25), (Exop:0;Bits:9;base:147),
    (Exop:83;Bits:7;base:59), (Exop:0;Bits:8;base:121), (Exop:0;Bits:8;base:57), (Exop:0;Bits:9;base:211),
    (Exop:81;Bits:7;base:17), (Exop:0;Bits:8;base:105), (Exop:0;Bits:8;base:41), (Exop:0;Bits:9;base:179),
    (Exop:0;Bits:8;base:9), (Exop:0;Bits:8;base:137), (Exop:0;Bits:8;base:73), (Exop:0;Bits:9;base:243),
    (Exop:80;Bits:7;base:4), (Exop:0;Bits:8;base:85), (Exop:0;Bits:8;base:21), (Exop:80;Bits:8;base:258),
    (Exop:83;Bits:7;base:43), (Exop:0;Bits:8;base:117), (Exop:0;Bits:8;base:53), (Exop:0;Bits:9;base:203),
    (Exop:81;Bits:7;base:13), (Exop:0;Bits:8;base:101), (Exop:0;Bits:8;base:37), (Exop:0;Bits:9;base:171),
    (Exop:0;Bits:8;base:5), (Exop:0;Bits:8;base:133), (Exop:0;Bits:8;base:69), (Exop:0;Bits:9;base:235),
    (Exop:80;Bits:7;base:8), (Exop:0;Bits:8;base:93), (Exop:0;Bits:8;base:29), (Exop:0;Bits:9;base:155),
    (Exop:84;Bits:7;base:83), (Exop:0;Bits:8;base:125), (Exop:0;Bits:8;base:61), (Exop:0;Bits:9;base:219),
    (Exop:82;Bits:7;base:23), (Exop:0;Bits:8;base:109), (Exop:0;Bits:8;base:45), (Exop:0;Bits:9;base:187),
    (Exop:0;Bits:8;base:13), (Exop:0;Bits:8;base:141), (Exop:0;Bits:8;base:77), (Exop:0;Bits:9;base:251),
    (Exop:80;Bits:7;base:3), (Exop:0;Bits:8;base:83), (Exop:0;Bits:8;base:19), (Exop:85;Bits:8;base:195),
    (Exop:83;Bits:7;base:35), (Exop:0;Bits:8;base:115), (Exop:0;Bits:8;base:51), (Exop:0;Bits:9;base:199),
    (Exop:81;Bits:7;base:11), (Exop:0;Bits:8;base:99), (Exop:0;Bits:8;base:35), (Exop:0;Bits:9;base:167),
    (Exop:0;Bits:8;base:3), (Exop:0;Bits:8;base:131), (Exop:0;Bits:8;base:67), (Exop:0;Bits:9;base:231),
    (Exop:80;Bits:7;base:7), (Exop:0;Bits:8;base:91), (Exop:0;Bits:8;base:27), (Exop:0;Bits:9;base:151),
    (Exop:84;Bits:7;base:67), (Exop:0;Bits:8;base:123), (Exop:0;Bits:8;base:59), (Exop:0;Bits:9;base:215),
    (Exop:82;Bits:7;base:19), (Exop:0;Bits:8;base:107), (Exop:0;Bits:8;base:43), (Exop:0;Bits:9;base:183),
    (Exop:0;Bits:8;base:11), (Exop:0;Bits:8;base:139), (Exop:0;Bits:8;base:75), (Exop:0;Bits:9;base:247),
    (Exop:80;Bits:7;base:5), (Exop:0;Bits:8;base:87), (Exop:0;Bits:8;base:23), (Exop:192;Bits:8;base:0),
    (Exop:83;Bits:7;base:51), (Exop:0;Bits:8;base:119), (Exop:0;Bits:8;base:55), (Exop:0;Bits:9;base:207),
    (Exop:81;Bits:7;base:15), (Exop:0;Bits:8;base:103), (Exop:0;Bits:8;base:39), (Exop:0;Bits:9;base:175),
    (Exop:0;Bits:8;base:7), (Exop:0;Bits:8;base:135), (Exop:0;Bits:8;base:71), (Exop:0;Bits:9;base:239),
    (Exop:80;Bits:7;base:9), (Exop:0;Bits:8;base:95), (Exop:0;Bits:8;base:31), (Exop:0;Bits:9;base:159),
    (Exop:84;Bits:7;base:99), (Exop:0;Bits:8;base:127), (Exop:0;Bits:8;base:63), (Exop:0;Bits:9;base:223),
    (Exop:82;Bits:7;base:27), (Exop:0;Bits:8;base:111), (Exop:0;Bits:8;base:47), (Exop:0;Bits:9;base:191),
    (Exop:0;Bits:8;base:15), (Exop:0;Bits:8;base:143), (Exop:0;Bits:8;base:79), (Exop:0;Bits:9;base:255)
  );
  fixed_td: array[0..32 - 1] of inflate_huft = (
    (Exop:80;Bits:5;base:1), (Exop:87;Bits:5;base:257), (Exop:83;Bits:5;base:17), (Exop:91;Bits:5;base:4097),
    (Exop:81;Bits:5;base:5), (Exop:89;Bits:5;base:1025), (Exop:85;Bits:5;base:65), (Exop:93;Bits:5;base:16385),
    (Exop:80;Bits:5;base:3), (Exop:88;Bits:5;base:513), (Exop:84;Bits:5;base:33), (Exop:92;Bits:5;base:8193),
    (Exop:82;Bits:5;base:9), (Exop:90;Bits:5;base:2049), (Exop:86;Bits:5;base:129), (Exop:192;Bits:5;base:24577),
    (Exop:80;Bits:5;base:2), (Exop:87;Bits:5;base:385), (Exop:83;Bits:5;base:25), (Exop:91;Bits:5;base:6145),
    (Exop:81;Bits:5;base:7), (Exop:89;Bits:5;base:1537), (Exop:85;Bits:5;base:97), (Exop:93;Bits:5;base:24577),
    (Exop:80;Bits:5;base:4), (Exop:88;Bits:5;base:769), (Exop:84;Bits:5;base:49), (Exop:92;Bits:5;base:12289),
    (Exop:82;Bits:5;base:13), (Exop:90;Bits:5;base:3073), (Exop:86;Bits:5;base:193), (Exop:192;Bits:5;base:24577)
  );
{$ENDIF}

function inflate_trees_fixed(var bl: uInt;
  var bd: uInt; var tl: pInflate_huft; var td: pInflate_huft; var z: z_stream): int;
{$IFNDEF BUILDFIXED}          { Use pre-built tables (completely thread-safe) }
begin
  bl := fixed_bl;
  bd := fixed_bd;
  tl := @fixed_tl;
  td := @fixed_td;
  inflate_trees_fixed := Z_OK;
end;
{$ELSE}                       { Build tables on first call. This is almost completely thread- }
type                          { safe, but can fail on the rare chance of an allocation error. }
  pFixed_table = ^fixed_table;
  fixed_table = array[0..288 - 1] of uIntf;
var
  k: int;
  c: pFixed_table;
  v: PuIntArray;
  f: uInt;
begin
  if not fixed_built then begin
    f := 0;
    c := pFixed_table(ZALLOC(z, 288, sizeof(uInt)));
    if (c = Z_NULL) then begin
      inflate_trees_fixed := Z_MEM_ERROR;
      exit;
    end;
    v := PuIntArray(ZALLOC(z, 288, sizeof(uInt)));
    if (v = Z_NULL) then begin
      ZFREE(z, c);
      inflate_trees_fixed := Z_MEM_ERROR;
      exit;
    end;
    for k := 0 to Pred(144) do c^[k] := 8;
    for k := 144 to Pred(256) do c^[k] := 9;
    for k := 256 to Pred(280) do c^[k] := 7;
    for k := 280 to Pred(288) do c^[k] := 8;
    fixed_bl := 9;
    huft_build(c^, 288, 257, cplens, cplext, @fixed_tl, fixed_bl, fixed_mem, f, v^);
    for k := 0 to Pred(30) do c^[k] := 5;
    fixed_bd := 5;
    huft_build(c^, 30, 0, cpdist, cpdext, @fixed_td, fixed_bd, fixed_mem, f, v^);
    ZFREE(z, v);
    ZFREE(z, c);
    fixed_built := True;
  end;
  bl := fixed_bl;
  bd := fixed_bd;
  tl := fixed_tl;
  td := fixed_td;
  inflate_trees_fixed := Z_OK;
end;
{$ENDIF}

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ infblock.h and
  infblock.c -- interpret and process block types to last block
  Copyright (C) 1995-1998 Mark Adler

  infblock.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

const
  border: array[0..18] of Word
  = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

procedure inflate_blocks_reset(var s: inflate_blocks_state;
  var z: z_stream; c: puLong);
begin
  if (c <> Z_NULL) then
    c^ := s.check;
  if (s.mode = BTREE) or (s.mode = DTREE) then
    ZFREE(z, s.sub.trees.blens);
  if (s.mode = CODES) then
    inflate_codes_free(s.sub.decode.codes, z);
  s.mode := ZTYPE;
  s.bitk := 0;
  s.bitb := 0;
  s.write := s.window;
  s.read := s.window;
  if Assigned(s.checkfn) then begin
    s.check := s.checkfn(uLong(0), pBytef(nil), 0);
    z.adler := s.check;
  end;
end;

function inflate_blocks_new(var z: z_stream;
  c: check_func; w: uInt): pInflate_blocks_state;
var
  s: pInflate_blocks_state;
begin
  s := pInflate_blocks_state(ZALLOC(z, 1, sizeof(inflate_blocks_state)));
  if (s = Z_NULL) then begin
    inflate_blocks_new := s;
    exit;
  end;
  s^.hufts := huft_ptr(ZALLOC(z, sizeof(inflate_huft), MANY));
  if (s^.hufts = Z_NULL) then begin
    ZFREE(z, s);
    inflate_blocks_new := Z_NULL;
    exit;
  end;
  s^.window := pBytef(ZALLOC(z, 1, w));
  if (s^.window = Z_NULL) then begin
    ZFREE(z, s^.hufts);
    ZFREE(z, s);
    inflate_blocks_new := Z_NULL;
    exit;
  end;
  s^.zend := s^.window;
  Inc(s^.zend, w);
  s^.checkfn := c;
  s^.mode := ZTYPE;
  inflate_blocks_reset(s^, z, Z_NULL);
  inflate_blocks_new := s;
end;

function inflate_blocks(var s: inflate_blocks_state;
  var z: z_stream; r: int): int;
label
  start_btree, start_dtree,
  start_blkdone, start_dry,
  start_codes;
var
  t: uInt;
  b: uLong;
  k: uInt;
  p: pBytef;
  n: uInt;
  q: pBytef;
  m: uInt;
  bl, bd: uInt;
  tl, td: pInflate_huft;
  h: pInflate_huft;
  i, j, c: uInt;
  cs: pInflate_codes_state;
begin
  p := z.next_in;
  n := z.avail_in;
  b := s.bitb;
  k := s.bitk;
  q := s.write;
  if ptr2int(q) < ptr2int(s.read) then
    m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
  else
    m := uInt(ptr2int(s.zend) - ptr2int(q));
  while True do
    case s.mode of
      ZTYPE:
        begin
          while (k < 3) do begin
            if (n <> 0) then
              r := Z_OK
            else begin
              s.bitb := b;
              s.bitk := k;
              z.avail_in := n;
              Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
              z.next_in := p;
              s.write := q;
              inflate_blocks := inflate_flush(s, z, r);
              exit;
            end;
            Dec(n);
            b := b or (uLong(p^) shl k);
            Inc(p);
            Inc(k, 8);
          end;
          t := uInt(b) and 7;
          s.last := boolean(t and 1);
          case (t shr 1) of
            0:
              begin
                b := b shr 3;
                Dec(k, 3);
                t := k and 7;
                b := b shr t;
                Dec(k, t);
                s.mode := LENS;
              end;
            1:
              begin
                inflate_trees_fixed(bl, bd, tl, td, z);
                s.sub.decode.codes := inflate_codes_new(bl, bd, tl, td, z);
                if (s.sub.decode.codes = Z_NULL) then begin
                  r := Z_MEM_ERROR;
                  s.bitb := b;
                  s.bitk := k;
                  z.avail_in := n;
                  Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
                  z.next_in := p;
                  s.write := q;
                  inflate_blocks := inflate_flush(s, z, r);
                  exit;
                end;
                b := b shr 3;
                Dec(k, 3);
                s.mode := CODES;
              end;
            2:
              begin
                b := b shr 3;
                Dec(k, 3);
                s.mode := TABLE;
              end;
            3:
              begin
                b := b shr 3;
                Dec(k, 3);
                s.mode := BLKBAD;
                z.msg := 'invalid block type';
                r := Z_DATA_ERROR;
                s.bitb := b;
                s.bitk := k;
                z.avail_in := n;
                Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
                z.next_in := p;
                s.write := q;
                inflate_blocks := inflate_flush(s, z, r);
                exit;
              end;
          end;
        end;
      LENS:
        begin
          while (k < 32) do begin
            if (n <> 0) then
              r := Z_OK
            else begin
              s.bitb := b;
              s.bitk := k;
              z.avail_in := n;
              Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
              z.next_in := p;
              s.write := q;
              inflate_blocks := inflate_flush(s, z, r);
              exit;
            end;
            Dec(n);
            b := b or (uLong(p^) shl k);
            Inc(p);
            Inc(k, 8);
          end;
          if (((not b) shr 16) and $FFFF) <> (b and $FFFF) then begin
            s.mode := BLKBAD;
            z.msg := 'invalid stored block lengths';
            r := Z_DATA_ERROR;
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_blocks := inflate_flush(s, z, r);
            exit;
          end;
          s.sub.left := uInt(b) and $FFFF;
          k := 0;
          b := 0;
          if s.sub.left <> 0 then
            s.mode := STORED
          else
            if s.last then
              s.mode := DRY
            else
              s.mode := ZTYPE;
        end;
      STORED:
        begin
          if (n = 0) then begin
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_blocks := inflate_flush(s, z, r);
            exit;
          end;
          if (m = 0) then begin
            if (q = s.zend) and (s.read <> s.window) then begin
              q := s.window;
              if ptr2int(q) < ptr2int(s.read) then
                m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
              else
                m := uInt(ptr2int(s.zend) - ptr2int(q));
            end;
            if (m = 0) then begin
              s.write := q;
              r := inflate_flush(s, z, r);
              q := s.write;
              if ptr2int(q) < ptr2int(s.read) then
                m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
              else
                m := uInt(ptr2int(s.zend) - ptr2int(q));

              if (q = s.zend) and (s.read <> s.window) then begin
                q := s.window;
                if ptr2int(q) < ptr2int(s.read) then
                  m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
                else
                  m := uInt(ptr2int(s.zend) - ptr2int(q));
              end;
              if (m = 0) then begin
                s.bitb := b;
                s.bitk := k;
                z.avail_in := n;
                Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
                z.next_in := p;
                s.write := q;
                inflate_blocks := inflate_flush(s, z, r);
                exit;
              end;
            end;
          end;
          r := Z_OK;
          t := s.sub.left;
          if (t > n) then
            t := n;
          if (t > m) then
            t := m;
          zmemcpy(q, p, t);
          Inc(p, t); Dec(n, t);
          Inc(q, t); Dec(m, t);
          Dec(s.sub.left, t);
          if (s.sub.left = 0) then begin
            if s.last then
              s.mode := DRY
            else
              s.mode := ZTYPE;
          end;
        end;
      TABLE:
        begin
          while (k < 14) do begin
            if (n <> 0) then
              r := Z_OK
            else begin
              s.bitb := b;
              s.bitk := k;
              z.avail_in := n;
              Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
              z.next_in := p;
              s.write := q;
              inflate_blocks := inflate_flush(s, z, r);
              exit;
            end;
            Dec(n);
            b := b or (uLong(p^) shl k);
            Inc(p);
            Inc(k, 8);
          end;
          t := uInt(b) and $3FFF;
          s.sub.trees.table := t;
          if ((t and $1F) > 29) or (((t shr 5) and $1F) > 29) then begin
            s.mode := BLKBAD;
            z.msg := 'too many length or distance symbols';
            r := Z_DATA_ERROR;
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_blocks := inflate_flush(s, z, r);
            exit;
          end;
          t := 258 + (t and $1F) + ((t shr 5) and $1F);
          s.sub.trees.blens := puIntArray(ZALLOC(z, t, sizeof(uInt)));
          if (s.sub.trees.blens = Z_NULL) then begin
            r := Z_MEM_ERROR;
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_blocks := inflate_flush(s, z, r);
            exit;
          end;
          b := b shr 14;
          Dec(k, 14);
          s.sub.trees.index := 0;
          s.mode := BTREE;
          goto start_btree;
        end;
      BTREE:
        begin
          start_btree:
          while (s.sub.trees.index < 4 + (s.sub.trees.table shr 10)) do begin
            while (k < 3) do begin
              if (n <> 0) then
                r := Z_OK
              else begin
                s.bitb := b;
                s.bitk := k;
                z.avail_in := n;
                Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
                z.next_in := p;
                s.write := q;
                inflate_blocks := inflate_flush(s, z, r);
                exit;
              end;
              Dec(n);
              b := b or (uLong(p^) shl k);
              Inc(p);
              Inc(k, 8);
            end;
            s.sub.trees.blens^[border[s.sub.trees.index]] := uInt(b) and 7;
            Inc(s.sub.trees.index);
            b := b shr 3;
            Dec(k, 3);
          end;
          while (s.sub.trees.index < 19) do begin
            s.sub.trees.blens^[border[s.sub.trees.index]] := 0;
            Inc(s.sub.trees.index);
          end;
          s.sub.trees.bb := 7;
          t := inflate_trees_bits(s.sub.trees.blens^, s.sub.trees.bb,
            s.sub.trees.tb, s.hufts^, z);
          if (t <> Z_OK) then begin
            ZFREE(z, s.sub.trees.blens);
            r := t;
            if (r = Z_DATA_ERROR) then
              s.mode := BLKBAD;
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_blocks := inflate_flush(s, z, r);
            exit;
          end;
          s.sub.trees.index := 0;
          s.mode := DTREE;
          goto start_dtree;
        end;
      DTREE:
        begin
          start_dtree:
          while TRUE do begin
            t := s.sub.trees.table;
            if not (s.sub.trees.index < 258 +
              (t and $1F) + ((t shr 5) and $1F)) then
              break;
            t := s.sub.trees.bb;
            while (k < t) do begin
              if (n <> 0) then
                r := Z_OK
              else begin
                s.bitb := b;
                s.bitk := k;
                z.avail_in := n;
                Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
                z.next_in := p;
                s.write := q;
                inflate_blocks := inflate_flush(s, z, r);
                exit;
              end;
              Dec(n);
              b := b or (uLong(p^) shl k);
              Inc(p);
              Inc(k, 8);
            end;
            h := s.sub.trees.tb;
            Inc(h, uInt(b) and inflate_mask[t]);
            t := h^.Bits;
            c := h^.Base;
            if (c < 16) then begin
              b := b shr t;
              Dec(k, t);
              s.sub.trees.blens^[s.sub.trees.index] := c;
              Inc(s.sub.trees.index);
            end
            else begin
              if c = 18 then begin
                i := 7;
                j := 11;
              end
              else begin
                i := c - 14;
                j := 3;
              end;
              while (k < t + i) do begin
                if (n <> 0) then
                  r := Z_OK
                else begin
                  s.bitb := b;
                  s.bitk := k;
                  z.avail_in := n;
                  Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
                  z.next_in := p;
                  s.write := q;
                  inflate_blocks := inflate_flush(s, z, r);
                  exit;
                end;
                Dec(n);
                b := b or (uLong(p^) shl k);
                Inc(p);
                Inc(k, 8);
              end;
              b := b shr t;
              Dec(k, t);
              Inc(j, uInt(b) and inflate_mask[i]);
              b := b shr i;
              Dec(k, i);
              i := s.sub.trees.index;
              t := s.sub.trees.table;
              if (i + j > 258 + (t and $1F) + ((t shr 5) and $1F)) or
                ((c = 16) and (i < 1)) then begin
                ZFREE(z, s.sub.trees.blens);
                s.mode := BLKBAD;
                z.msg := 'invalid bit length repeat';
                r := Z_DATA_ERROR;
                s.bitb := b;
                s.bitk := k;
                z.avail_in := n;
                Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
                z.next_in := p;
                s.write := q;
                inflate_blocks := inflate_flush(s, z, r);
                exit;
              end;
              if c = 16 then
                c := s.sub.trees.blens^[i - 1]
              else
                c := 0;
              repeat
                s.sub.trees.blens^[i] := c;
                Inc(i);
                Dec(j);
              until (j = 0);
              s.sub.trees.index := i;
            end;
          end;
          s.sub.trees.tb := Z_NULL;
          bl := 9;
          bd := 6;
          t := s.sub.trees.table;
          t := inflate_trees_dynamic(257 + (t and $1F),
            1 + ((t shr 5) and $1F),
            s.sub.trees.blens^, bl, bd, tl, td, s.hufts^, z);
          ZFREE(z, s.sub.trees.blens);
          if (t <> Z_OK) then begin
            if (t = uInt(Z_DATA_ERROR)) then
              s.mode := BLKBAD;
            r := t;
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_blocks := inflate_flush(s, z, r);
            exit;
          end;
          cs := inflate_codes_new(bl, bd, tl, td, z);
          if (cs = Z_NULL) then begin
            r := Z_MEM_ERROR;
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_blocks := inflate_flush(s, z, r);
            exit;
          end;
          s.sub.decode.codes := cs;
          s.mode := CODES;
          goto start_codes;
        end;
      CODES:
        begin
          start_codes:
          s.bitb := b;
          s.bitk := k;
          z.avail_in := n;
          Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
          z.next_in := p;
          s.write := q;
          r := inflate_codes(s, z, r);
          if (r <> Z_STREAM_END) then begin
            inflate_blocks := inflate_flush(s, z, r);
            exit;
          end;
          r := Z_OK;
          inflate_codes_free(s.sub.decode.codes, z);
          p := z.next_in;
          n := z.avail_in;
          b := s.bitb;
          k := s.bitk;
          q := s.write;
          if ptr2int(q) < ptr2int(s.read) then
            m := uInt(ptr2int(s.read) - ptr2int(q) - 1)
          else
            m := uInt(ptr2int(s.zend) - ptr2int(q));
          if (not s.last) then begin
            s.mode := ZTYPE;
            continue;
          end;
          s.mode := DRY;
          goto start_dry;
        end;
      DRY:
        begin
          start_dry:
          s.write := q;
          r := inflate_flush(s, z, r);
          q := s.write;
          if (s.read <> s.write) then begin
            s.bitb := b;
            s.bitk := k;
            z.avail_in := n;
            Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
            z.next_in := p;
            s.write := q;
            inflate_blocks := inflate_flush(s, z, r);
            exit;
          end;
          s.mode := BLKDONE;
          goto start_blkdone;
        end;
      BLKDONE:
        begin
          start_blkdone:
          r := Z_STREAM_END;
          s.bitb := b;
          s.bitk := k;
          z.avail_in := n;
          Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
          z.next_in := p;
          s.write := q;
          inflate_blocks := inflate_flush(s, z, r);
          exit;
        end;
      BLKBAD:
        begin
          r := Z_DATA_ERROR;
          s.bitb := b;
          s.bitk := k;
          z.avail_in := n;
          Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
          z.next_in := p;
          s.write := q;
          inflate_blocks := inflate_flush(s, z, r);
          exit;
        end;
    else
      begin
        r := Z_STREAM_ERROR;
        s.bitb := b;
        s.bitk := k;
        z.avail_in := n;
        Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
        z.next_in := p;
        s.write := q;
        inflate_blocks := inflate_flush(s, z, r);
        exit;
      end;
    end;
end;

function inflate_blocks_free(s: pInflate_blocks_state;
  var z: z_stream): int;
begin
  inflate_blocks_reset(s^, z, Z_NULL);
  ZFREE(z, s^.window);
  ZFREE(z, s^.hufts);
  ZFREE(z, s);
  inflate_blocks_free := Z_OK;
end;

procedure inflate_set_dictionary(var s: inflate_blocks_state;
  const d: array of byte; n: uInt);
begin
  zmemcpy(s.window, pBytef(@d), n);
  s.write := s.window;
  Inc(s.write, n);
  s.read := s.write;
end;

function inflate_blocks_sync_point(var s: inflate_blocks_state): int;
begin
  inflate_blocks_sync_point := int(s.mode = LENS);
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ trees.c -- output deflated data using Huffman coding
  Copyright (C) 1995-1998 Jean-loup Gailly

  trees.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

{$T-}

const
  DIST_CODE_LEN = 512;

const
  static_ltree: array[0..L_CODES + 2 - 1] of ct_data = (
    (fc: (freq: 12); dl: (len: 8)), (fc: (freq: 140); dl: (len: 8)), (fc: (freq: 76); dl: (len: 8)),
    (fc: (freq: 204); dl: (len: 8)), (fc: (freq: 44); dl: (len: 8)), (fc: (freq: 172); dl: (len: 8)),
    (fc: (freq: 108); dl: (len: 8)), (fc: (freq: 236); dl: (len: 8)), (fc: (freq: 28); dl: (len: 8)),
    (fc: (freq: 156); dl: (len: 8)), (fc: (freq: 92); dl: (len: 8)), (fc: (freq: 220); dl: (len: 8)),
    (fc: (freq: 60); dl: (len: 8)), (fc: (freq: 188); dl: (len: 8)), (fc: (freq: 124); dl: (len: 8)),
    (fc: (freq: 252); dl: (len: 8)), (fc: (freq: 2); dl: (len: 8)), (fc: (freq: 130); dl: (len: 8)),
    (fc: (freq: 66); dl: (len: 8)), (fc: (freq: 194); dl: (len: 8)), (fc: (freq: 34); dl: (len: 8)),
    (fc: (freq: 162); dl: (len: 8)), (fc: (freq: 98); dl: (len: 8)), (fc: (freq: 226); dl: (len: 8)),
    (fc: (freq: 18); dl: (len: 8)), (fc: (freq: 146); dl: (len: 8)), (fc: (freq: 82); dl: (len: 8)),
    (fc: (freq: 210); dl: (len: 8)), (fc: (freq: 50); dl: (len: 8)), (fc: (freq: 178); dl: (len: 8)),
    (fc: (freq: 114); dl: (len: 8)), (fc: (freq: 242); dl: (len: 8)), (fc: (freq: 10); dl: (len: 8)),
    (fc: (freq: 138); dl: (len: 8)), (fc: (freq: 74); dl: (len: 8)), (fc: (freq: 202); dl: (len: 8)),
    (fc: (freq: 42); dl: (len: 8)), (fc: (freq: 170); dl: (len: 8)), (fc: (freq: 106); dl: (len: 8)),
    (fc: (freq: 234); dl: (len: 8)), (fc: (freq: 26); dl: (len: 8)), (fc: (freq: 154); dl: (len: 8)),
    (fc: (freq: 90); dl: (len: 8)), (fc: (freq: 218); dl: (len: 8)), (fc: (freq: 58); dl: (len: 8)),
    (fc: (freq: 186); dl: (len: 8)), (fc: (freq: 122); dl: (len: 8)), (fc: (freq: 250); dl: (len: 8)),
    (fc: (freq: 6); dl: (len: 8)), (fc: (freq: 134); dl: (len: 8)), (fc: (freq: 70); dl: (len: 8)),
    (fc: (freq: 198); dl: (len: 8)), (fc: (freq: 38); dl: (len: 8)), (fc: (freq: 166); dl: (len: 8)),
    (fc: (freq: 102); dl: (len: 8)), (fc: (freq: 230); dl: (len: 8)), (fc: (freq: 22); dl: (len: 8)),
    (fc: (freq: 150); dl: (len: 8)), (fc: (freq: 86); dl: (len: 8)), (fc: (freq: 214); dl: (len: 8)),
    (fc: (freq: 54); dl: (len: 8)), (fc: (freq: 182); dl: (len: 8)), (fc: (freq: 118); dl: (len: 8)),
    (fc: (freq: 246); dl: (len: 8)), (fc: (freq: 14); dl: (len: 8)), (fc: (freq: 142); dl: (len: 8)),
    (fc: (freq: 78); dl: (len: 8)), (fc: (freq: 206); dl: (len: 8)), (fc: (freq: 46); dl: (len: 8)),
    (fc: (freq: 174); dl: (len: 8)), (fc: (freq: 110); dl: (len: 8)), (fc: (freq: 238); dl: (len: 8)),
    (fc: (freq: 30); dl: (len: 8)), (fc: (freq: 158); dl: (len: 8)), (fc: (freq: 94); dl: (len: 8)),
    (fc: (freq: 222); dl: (len: 8)), (fc: (freq: 62); dl: (len: 8)), (fc: (freq: 190); dl: (len: 8)),
    (fc: (freq: 126); dl: (len: 8)), (fc: (freq: 254); dl: (len: 8)), (fc: (freq: 1); dl: (len: 8)),
    (fc: (freq: 129); dl: (len: 8)), (fc: (freq: 65); dl: (len: 8)), (fc: (freq: 193); dl: (len: 8)),
    (fc: (freq: 33); dl: (len: 8)), (fc: (freq: 161); dl: (len: 8)), (fc: (freq: 97); dl: (len: 8)),
    (fc: (freq: 225); dl: (len: 8)), (fc: (freq: 17); dl: (len: 8)), (fc: (freq: 145); dl: (len: 8)),
    (fc: (freq: 81); dl: (len: 8)), (fc: (freq: 209); dl: (len: 8)), (fc: (freq: 49); dl: (len: 8)),
    (fc: (freq: 177); dl: (len: 8)), (fc: (freq: 113); dl: (len: 8)), (fc: (freq: 241); dl: (len: 8)),
    (fc: (freq: 9); dl: (len: 8)), (fc: (freq: 137); dl: (len: 8)), (fc: (freq: 73); dl: (len: 8)),
    (fc: (freq: 201); dl: (len: 8)), (fc: (freq: 41); dl: (len: 8)), (fc: (freq: 169); dl: (len: 8)),
    (fc: (freq: 105); dl: (len: 8)), (fc: (freq: 233); dl: (len: 8)), (fc: (freq: 25); dl: (len: 8)),
    (fc: (freq: 153); dl: (len: 8)), (fc: (freq: 89); dl: (len: 8)), (fc: (freq: 217); dl: (len: 8)),
    (fc: (freq: 57); dl: (len: 8)), (fc: (freq: 185); dl: (len: 8)), (fc: (freq: 121); dl: (len: 8)),
    (fc: (freq: 249); dl: (len: 8)), (fc: (freq: 5); dl: (len: 8)), (fc: (freq: 133); dl: (len: 8)),
    (fc: (freq: 69); dl: (len: 8)), (fc: (freq: 197); dl: (len: 8)), (fc: (freq: 37); dl: (len: 8)),
    (fc: (freq: 165); dl: (len: 8)), (fc: (freq: 101); dl: (len: 8)), (fc: (freq: 229); dl: (len: 8)),
    (fc: (freq: 21); dl: (len: 8)), (fc: (freq: 149); dl: (len: 8)), (fc: (freq: 85); dl: (len: 8)),
    (fc: (freq: 213); dl: (len: 8)), (fc: (freq: 53); dl: (len: 8)), (fc: (freq: 181); dl: (len: 8)),
    (fc: (freq: 117); dl: (len: 8)), (fc: (freq: 245); dl: (len: 8)), (fc: (freq: 13); dl: (len: 8)),
    (fc: (freq: 141); dl: (len: 8)), (fc: (freq: 77); dl: (len: 8)), (fc: (freq: 205); dl: (len: 8)),
    (fc: (freq: 45); dl: (len: 8)), (fc: (freq: 173); dl: (len: 8)), (fc: (freq: 109); dl: (len: 8)),
    (fc: (freq: 237); dl: (len: 8)), (fc: (freq: 29); dl: (len: 8)), (fc: (freq: 157); dl: (len: 8)),
    (fc: (freq: 93); dl: (len: 8)), (fc: (freq: 221); dl: (len: 8)), (fc: (freq: 61); dl: (len: 8)),
    (fc: (freq: 189); dl: (len: 8)), (fc: (freq: 125); dl: (len: 8)), (fc: (freq: 253); dl: (len: 8)),
    (fc: (freq: 19); dl: (len: 9)), (fc: (freq: 275); dl: (len: 9)), (fc: (freq: 147); dl: (len: 9)),
    (fc: (freq: 403); dl: (len: 9)), (fc: (freq: 83); dl: (len: 9)), (fc: (freq: 339); dl: (len: 9)),
    (fc: (freq: 211); dl: (len: 9)), (fc: (freq: 467); dl: (len: 9)), (fc: (freq: 51); dl: (len: 9)),
    (fc: (freq: 307); dl: (len: 9)), (fc: (freq: 179); dl: (len: 9)), (fc: (freq: 435); dl: (len: 9)),
    (fc: (freq: 115); dl: (len: 9)), (fc: (freq: 371); dl: (len: 9)), (fc: (freq: 243); dl: (len: 9)),
    (fc: (freq: 499); dl: (len: 9)), (fc: (freq: 11); dl: (len: 9)), (fc: (freq: 267); dl: (len: 9)),
    (fc: (freq: 139); dl: (len: 9)), (fc: (freq: 395); dl: (len: 9)), (fc: (freq: 75); dl: (len: 9)),
    (fc: (freq: 331); dl: (len: 9)), (fc: (freq: 203); dl: (len: 9)), (fc: (freq: 459); dl: (len: 9)),
    (fc: (freq: 43); dl: (len: 9)), (fc: (freq: 299); dl: (len: 9)), (fc: (freq: 171); dl: (len: 9)),
    (fc: (freq: 427); dl: (len: 9)), (fc: (freq: 107); dl: (len: 9)), (fc: (freq: 363); dl: (len: 9)),
    (fc: (freq: 235); dl: (len: 9)), (fc: (freq: 491); dl: (len: 9)), (fc: (freq: 27); dl: (len: 9)),
    (fc: (freq: 283); dl: (len: 9)), (fc: (freq: 155); dl: (len: 9)), (fc: (freq: 411); dl: (len: 9)),
    (fc: (freq: 91); dl: (len: 9)), (fc: (freq: 347); dl: (len: 9)), (fc: (freq: 219); dl: (len: 9)),
    (fc: (freq: 475); dl: (len: 9)), (fc: (freq: 59); dl: (len: 9)), (fc: (freq: 315); dl: (len: 9)),
    (fc: (freq: 187); dl: (len: 9)), (fc: (freq: 443); dl: (len: 9)), (fc: (freq: 123); dl: (len: 9)),
    (fc: (freq: 379); dl: (len: 9)), (fc: (freq: 251); dl: (len: 9)), (fc: (freq: 507); dl: (len: 9)),
    (fc: (freq: 7); dl: (len: 9)), (fc: (freq: 263); dl: (len: 9)), (fc: (freq: 135); dl: (len: 9)),
    (fc: (freq: 391); dl: (len: 9)), (fc: (freq: 71); dl: (len: 9)), (fc: (freq: 327); dl: (len: 9)),
    (fc: (freq: 199); dl: (len: 9)), (fc: (freq: 455); dl: (len: 9)), (fc: (freq: 39); dl: (len: 9)),
    (fc: (freq: 295); dl: (len: 9)), (fc: (freq: 167); dl: (len: 9)), (fc: (freq: 423); dl: (len: 9)),
    (fc: (freq: 103); dl: (len: 9)), (fc: (freq: 359); dl: (len: 9)), (fc: (freq: 231); dl: (len: 9)),
    (fc: (freq: 487); dl: (len: 9)), (fc: (freq: 23); dl: (len: 9)), (fc: (freq: 279); dl: (len: 9)),
    (fc: (freq: 151); dl: (len: 9)), (fc: (freq: 407); dl: (len: 9)), (fc: (freq: 87); dl: (len: 9)),
    (fc: (freq: 343); dl: (len: 9)), (fc: (freq: 215); dl: (len: 9)), (fc: (freq: 471); dl: (len: 9)),
    (fc: (freq: 55); dl: (len: 9)), (fc: (freq: 311); dl: (len: 9)), (fc: (freq: 183); dl: (len: 9)),
    (fc: (freq: 439); dl: (len: 9)), (fc: (freq: 119); dl: (len: 9)), (fc: (freq: 375); dl: (len: 9)),
    (fc: (freq: 247); dl: (len: 9)), (fc: (freq: 503); dl: (len: 9)), (fc: (freq: 15); dl: (len: 9)),
    (fc: (freq: 271); dl: (len: 9)), (fc: (freq: 143); dl: (len: 9)), (fc: (freq: 399); dl: (len: 9)),
    (fc: (freq: 79); dl: (len: 9)), (fc: (freq: 335); dl: (len: 9)), (fc: (freq: 207); dl: (len: 9)),
    (fc: (freq: 463); dl: (len: 9)), (fc: (freq: 47); dl: (len: 9)), (fc: (freq: 303); dl: (len: 9)),
    (fc: (freq: 175); dl: (len: 9)), (fc: (freq: 431); dl: (len: 9)), (fc: (freq: 111); dl: (len: 9)),
    (fc: (freq: 367); dl: (len: 9)), (fc: (freq: 239); dl: (len: 9)), (fc: (freq: 495); dl: (len: 9)),
    (fc: (freq: 31); dl: (len: 9)), (fc: (freq: 287); dl: (len: 9)), (fc: (freq: 159); dl: (len: 9)),
    (fc: (freq: 415); dl: (len: 9)), (fc: (freq: 95); dl: (len: 9)), (fc: (freq: 351); dl: (len: 9)),
    (fc: (freq: 223); dl: (len: 9)), (fc: (freq: 479); dl: (len: 9)), (fc: (freq: 63); dl: (len: 9)),
    (fc: (freq: 319); dl: (len: 9)), (fc: (freq: 191); dl: (len: 9)), (fc: (freq: 447); dl: (len: 9)),
    (fc: (freq: 127); dl: (len: 9)), (fc: (freq: 383); dl: (len: 9)), (fc: (freq: 255); dl: (len: 9)),
    (fc: (freq: 511); dl: (len: 9)), (fc: (freq: 0); dl: (len: 7)), (fc: (freq: 64); dl: (len: 7)),
    (fc: (freq: 32); dl: (len: 7)), (fc: (freq: 96); dl: (len: 7)), (fc: (freq: 16); dl: (len: 7)),
    (fc: (freq: 80); dl: (len: 7)), (fc: (freq: 48); dl: (len: 7)), (fc: (freq: 112); dl: (len: 7)),
    (fc: (freq: 8); dl: (len: 7)), (fc: (freq: 72); dl: (len: 7)), (fc: (freq: 40); dl: (len: 7)),
    (fc: (freq: 104); dl: (len: 7)), (fc: (freq: 24); dl: (len: 7)), (fc: (freq: 88); dl: (len: 7)),
    (fc: (freq: 56); dl: (len: 7)), (fc: (freq: 120); dl: (len: 7)), (fc: (freq: 4); dl: (len: 7)),
    (fc: (freq: 68); dl: (len: 7)), (fc: (freq: 36); dl: (len: 7)), (fc: (freq: 100); dl: (len: 7)),
    (fc: (freq: 20); dl: (len: 7)), (fc: (freq: 84); dl: (len: 7)), (fc: (freq: 52); dl: (len: 7)),
    (fc: (freq: 116); dl: (len: 7)), (fc: (freq: 3); dl: (len: 8)), (fc: (freq: 131); dl: (len: 8)),
    (fc: (freq: 67); dl: (len: 8)), (fc: (freq: 195); dl: (len: 8)), (fc: (freq: 35); dl: (len: 8)),
    (fc: (freq: 163); dl: (len: 8)), (fc: (freq: 99); dl: (len: 8)), (fc: (freq: 227); dl: (len: 8))
    );

  static_dtree: array[0..D_CODES - 1] of ct_data = (
    (fc: (freq: 0); dl: (len: 5)), (fc: (freq: 16); dl: (len: 5)), (fc: (freq: 8); dl: (len: 5)),
    (fc: (freq: 24); dl: (len: 5)), (fc: (freq: 4); dl: (len: 5)), (fc: (freq: 20); dl: (len: 5)),
    (fc: (freq: 12); dl: (len: 5)), (fc: (freq: 28); dl: (len: 5)), (fc: (freq: 2); dl: (len: 5)),
    (fc: (freq: 18); dl: (len: 5)), (fc: (freq: 10); dl: (len: 5)), (fc: (freq: 26); dl: (len: 5)),
    (fc: (freq: 6); dl: (len: 5)), (fc: (freq: 22); dl: (len: 5)), (fc: (freq: 14); dl: (len: 5)),
    (fc: (freq: 30); dl: (len: 5)), (fc: (freq: 1); dl: (len: 5)), (fc: (freq: 17); dl: (len: 5)),
    (fc: (freq: 9); dl: (len: 5)), (fc: (freq: 25); dl: (len: 5)), (fc: (freq: 5); dl: (len: 5)),
    (fc: (freq: 21); dl: (len: 5)), (fc: (freq: 13); dl: (len: 5)), (fc: (freq: 29); dl: (len: 5)),
    (fc: (freq: 3); dl: (len: 5)), (fc: (freq: 19); dl: (len: 5)), (fc: (freq: 11); dl: (len: 5)),
    (fc: (freq: 27); dl: (len: 5)), (fc: (freq: 7); dl: (len: 5)), (fc: (freq: 23); dl: (len: 5))
    );

  _dist_code: array[0..DIST_CODE_LEN - 1] of uch = (
    0, 1, 2, 3, 4, 4, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8,
    8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 10,
    10, 10, 10, 10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
    11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
    12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13,
    13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13,
    13, 13, 13, 13, 13, 13, 13, 13, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
    14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
    14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14,
    14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15, 15,
    15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
    15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15,
    15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 0, 0, 16, 17,
    18, 18, 19, 19, 20, 20, 20, 20, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22, 22, 22,
    23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
    24, 24, 24, 24, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
    26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
    26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27,
    27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    27, 27, 27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
    28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
    28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28,
    28, 28, 28, 28, 28, 28, 28, 28, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
    29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
    29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29,
    29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29
    );

  _length_code: array[0..MAX_MATCH - MIN_MATCH + 1 - 1] of uch = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 12, 12,
    13, 13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16,
    17, 17, 17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 19, 19, 19, 19,
    19, 19, 19, 19, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20,
    21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22,
    22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23,
    23, 23, 23, 23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
    24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
    25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25,
    25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26,
    26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26,
    26, 26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27,
    27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28
    );

  base_length: array[0..LENGTH_CODES - 1] of int = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 32, 40, 48, 56,
    64, 80, 96, 112, 128, 160, 192, 224, 0
    );

  base_dist: array[0..D_CODES - 1] of int = (
    0, 1, 2, 3, 4, 6, 8, 12, 16, 24,
    32, 48, 64, 96, 128, 192, 256, 384, 512, 768,
    1024, 1536, 2048, 3072, 4096, 6144, 8192, 12288, 16384, 24576
    );

const
  MAX_BL_BITS = 7;
  END_BLOCK = 256;
  REP_3_6 = 16;
  REPZ_3_10 = 17;
  REPZ_11_138 = 18;

const
  extra_lbits: array[0..LENGTH_CODES - 1] of int
  = (0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0);

const
  extra_dbits: array[0..D_CODES - 1] of int
  = (0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13);

const
  extra_blbits: array[0..BL_CODES - 1] of int
  = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 7);

const
  bl_order: array[0..BL_CODES - 1] of uch
  = (16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15);

const
  Buf_size = (8 * 2 * sizeof(char));

const
  static_l_desc: static_tree_desc =
  (static_tree: {tree_ptr}(@(static_ltree));
    extra_bits: {pzIntfArray}(@(extra_lbits));
    extra_base: LITERALS + 1;
    elems: L_CODES;
    max_length: MAX_BITS);

const
  static_d_desc: static_tree_desc =
  (static_tree: {tree_ptr}(@(static_dtree));
    extra_bits: {pzIntfArray}(@(extra_dbits));
    extra_base: 0;
    elems: D_CODES;
    max_length: MAX_BITS);

const
  static_bl_desc: static_tree_desc =
  (static_tree: {tree_ptr}(nil);
    extra_bits: {pzIntfArray}@(extra_blbits);
    extra_base: 0;
    elems: BL_CODES;
    max_length: MAX_BL_BITS);

procedure send_bits(var s: deflate_state;
  value: int; length: int);
begin
{$IFOPT Q+}{$Q-}{$DEFINE NoOverflowCheck}{$ENDIF}
{$IFOPT R+}{$R-}{$DEFINE NoRangeCheck}{$ENDIF}
  if (s.bi_valid > int(Buf_size) - length) then begin
    s.bi_buf := s.bi_buf or int(value shl s.bi_valid);
    s.pending_buf^[s.pending] := uch(s.bi_buf and $FF);
    Inc(s.pending);
    s.pending_buf^[s.pending] := uch(ush(s.bi_buf) shr 8); ;
    Inc(s.pending);
    s.bi_buf := ush(value) shr (Buf_size - s.bi_valid);
    Inc(s.bi_valid, length - Buf_size);
  end
  else begin
    s.bi_buf := s.bi_buf or int(value shl s.bi_valid);
    Inc(s.bi_valid, length);
  end;
{$IFDEF NoOverflowCheck}{$Q+}{$UNDEF NoOverflowCheck}{$ENDIF}
{$IFDEF NoRangeCheck}{$Q+}{$UNDEF NoRangeCheck}{$ENDIF}
end;

function bi_reverse(code: unsigned; len: int): unsigned;
var
  res: unsigned;
begin
  res := 0;
  repeat
    res := res or (code and 1);
    code := code shr 1;
    res := res shl 1;
    Dec(len);
  until (len <= 0);
  bi_reverse := res shr 1;
end;

procedure gen_codes(tree: tree_ptr;
  max_code: int; var bl_count: array of ushf);
var
  next_code: array[0..MAX_BITS + 1 - 1] of ush;
  code: ush;
  bits: int;
  n: int;
var
  len: int;
begin
  code := 0;
  for bits := 1 to MAX_BITS do begin
    code := ((code + bl_count[bits - 1]) shl 1);
    next_code[bits] := code;
  end;
  for n := 0 to max_code do begin
    len := tree^[n].dl.Len;
    if (len = 0) then continue;
    tree^[n].fc.Code := bi_reverse(next_code[len], len);
    Inc(next_code[len]);
  end;
end;

procedure tr_static_init;
begin
  {null}
end;

procedure init_block(var s: deflate_state);
var
  n: int;
begin
  for n := 0 to L_CODES - 1 do s.dyn_ltree[n].fc.Freq := 0;
  for n := 0 to D_CODES - 1 do s.dyn_dtree[n].fc.Freq := 0;
  for n := 0 to BL_CODES - 1 do s.bl_tree[n].fc.Freq := 0;
  s.dyn_ltree[END_BLOCK].fc.Freq := 1;
  s.static_len := Long(0);
  s.opt_len := Long(0);
  s.matches := 0;
  s.last_lit := 0;
end;

const
  SMALLEST = 1;

procedure _tr_init(var s: deflate_state);
begin
  tr_static_init;
  s.compressed_len := Long(0);
  s.l_desc.dyn_tree := tree_ptr(@s.dyn_ltree);
  s.l_desc.stat_desc := @static_l_desc;
  s.d_desc.dyn_tree := tree_ptr(@s.dyn_dtree);
  s.d_desc.stat_desc := @static_d_desc;
  s.bl_desc.dyn_tree := tree_ptr(@s.bl_tree);
  s.bl_desc.stat_desc := @static_bl_desc;
  s.bi_buf := 0;
  s.bi_valid := 0;
  s.last_eob_len := 8;
  init_block(s);
end;

procedure pqdownheap(var s: deflate_state;
  var tree: tree_type; k: int);
var
  v: int;
  j: int;
begin
  v := s.heap[k];
  j := k shl 1;
  while (j <= s.heap_len) do begin
    if (j < s.heap_len) and
      ((tree[s.heap[j + 1]].fc.Freq < tree[s.heap[j]].fc.Freq) or
      ((tree[s.heap[j + 1]].fc.Freq = tree[s.heap[j]].fc.Freq) and
      (s.depth[s.heap[j + 1]] <= s.depth[s.heap[j]]))) then
      Inc(j);
    if ((tree[v].fc.Freq < tree[s.heap[j]].fc.Freq) or
      ((tree[v].fc.Freq = tree[s.heap[j]].fc.Freq) and
      (s.depth[v] <= s.depth[s.heap[j]]))) then
      break;
    s.heap[k] := s.heap[j];
    k := j;
    j := j shl 1;
  end;
  s.heap[k] := v;
end;

procedure gen_bitlen(var s: deflate_state;
  var desc: tree_desc);
var
  tree: tree_ptr;
  max_code: int;
  stree: tree_ptr;
  extra: pzIntfArray;
  base: int;
  max_length: int;
  h: int;
  n, m: int;
  bits: int;
  xbits: int;
  f: ush;
  overflow: int;
begin
  tree := desc.dyn_tree;
  max_code := desc.max_code;
  stree := desc.stat_desc^.static_tree;
  extra := desc.stat_desc^.extra_bits;
  base := desc.stat_desc^.extra_base;
  max_length := desc.stat_desc^.max_length;
  overflow := 0;
  for bits := 0 to MAX_BITS do
    s.bl_count[bits] := 0;
  tree^[s.heap[s.heap_max]].dl.Len := 0;
  for h := s.heap_max + 1 to HEAP_SIZE - 1 do begin
    n := s.heap[h];
    bits := tree^[tree^[n].dl.Dad].dl.Len + 1;
    if (bits > max_length) then begin
      bits := max_length;
      Inc(overflow);
    end;
    tree^[n].dl.Len := ush(bits);
    if (n > max_code) then continue;
    Inc(s.bl_count[bits]);
    xbits := 0;
    if (n >= base) then
      xbits := extra^[n - base];
    f := tree^[n].fc.Freq;
    Inc(s.opt_len, ulg(f) * (bits + xbits));
    if (stree <> nil) then Inc(s.static_len, ulg(f) * (stree^[n].dl.Len + xbits));
  end;
  if (overflow = 0) then exit;
  repeat
    bits := max_length - 1;
    while (s.bl_count[bits] = 0) do Dec(bits);
    Dec(s.bl_count[bits]);
    Inc(s.bl_count[bits + 1], 2);
    Dec(s.bl_count[max_length]);
    Dec(overflow, 2);
  until (overflow <= 0);
  h := HEAP_SIZE; { Delphi3: compiler warning w/o this }
  for bits := max_length downto 1 do begin
    n := s.bl_count[bits];
    while (n <> 0) do begin
      Dec(h);
      m := s.heap[h];
      if (m > max_code) then continue;
      if (tree^[m].dl.Len <> unsigned(bits)) then begin
        Inc(s.opt_len, (long(bits) - long(tree^[m].dl.Len))
          * long(tree^[m].fc.Freq));
        tree^[m].dl.Len := ush(bits);
      end;
      Dec(n);
    end;
  end;
end;

procedure build_tree(var s: deflate_state;
  var desc: tree_desc);
var
  tree: tree_ptr;
  stree: tree_ptr;
  elems: int;
  n, m: int;
  max_code: int;
  node: int;
begin
  tree := desc.dyn_tree;
  stree := desc.stat_desc^.static_tree;
  elems := desc.stat_desc^.elems;
  max_code := -1;
  s.heap_len := 0;
  s.heap_max := HEAP_SIZE;
  for n := 0 to elems - 1 do begin
    if (tree^[n].fc.Freq <> 0) then begin
      max_code := n;
      Inc(s.heap_len);
      s.heap[s.heap_len] := n;
      s.depth[n] := 0;
    end
    else
      tree^[n].dl.Len := 0;
  end;
  while (s.heap_len < 2) do begin
    Inc(s.heap_len);
    if (max_code < 2) then begin
      Inc(max_code);
      s.heap[s.heap_len] := max_code;
      node := max_code;
    end
    else begin
      s.heap[s.heap_len] := 0;
      node := 0;
    end;
    tree^[node].fc.Freq := 1;
    s.depth[node] := 0;
    Dec(s.opt_len);
    if (stree <> nil) then Dec(s.static_len, stree^[node].dl.Len);
  end;
  desc.max_code := max_code;
  for n := s.heap_len div 2 downto 1 do pqdownheap(s, tree^, n);
  node := elems;
  repeat
    n := s.heap[SMALLEST];
    s.heap[SMALLEST] := s.heap[s.heap_len];
    Dec(s.heap_len);
    pqdownheap(s, tree^, SMALLEST);
    m := s.heap[SMALLEST];
    Dec(s.heap_max);
    s.heap[s.heap_max] := n;
    Dec(s.heap_max);
    s.heap[s.heap_max] := m;
    tree^[node].fc.Freq := tree^[n].fc.Freq + tree^[m].fc.Freq;
    if (s.depth[n] >= s.depth[m]) then
      s.depth[node] := uch(s.depth[n] + 1)
    else
      s.depth[node] := uch(s.depth[m] + 1);
    tree^[m].dl.Dad := ush(node);
    tree^[n].dl.Dad := ush(node);
    s.heap[SMALLEST] := node;
    Inc(node);
    pqdownheap(s, tree^, SMALLEST);
  until (s.heap_len < 2);
  Dec(s.heap_max);
  s.heap[s.heap_max] := s.heap[SMALLEST];
  gen_bitlen(s, desc);
  gen_codes(tree, max_code, s.bl_count);
end;

procedure scan_tree(var s: deflate_state;
  var tree: array of ct_data; max_code: int);
var
  n: int;
  prevlen: int;
  curlen: int;
  nextlen: int;
  count: int;
  max_count: int;
  min_count: int;
begin
  prevlen := -1;
  nextlen := tree[0].dl.Len;
  count := 0;
  max_count := 7;
  min_count := 4;
  if (nextlen = 0) then begin
    max_count := 138;
    min_count := 3;
  end;
  tree[max_code + 1].dl.Len := ush($FFFF);
  for n := 0 to max_code do begin
    curlen := nextlen;
    nextlen := tree[n + 1].dl.Len;
    Inc(count);
    if (count < max_count) and (curlen = nextlen) then
      continue
    else if (count < min_count) then
      Inc(s.bl_tree[curlen].fc.Freq, count)
    else if (curlen <> 0) then begin
      if (curlen <> prevlen) then
        Inc(s.bl_tree[curlen].fc.Freq);
      Inc(s.bl_tree[REP_3_6].fc.Freq);
    end
    else if (count <= 10) then
      Inc(s.bl_tree[REPZ_3_10].fc.Freq)
    else
      Inc(s.bl_tree[REPZ_11_138].fc.Freq);
    count := 0;
    prevlen := curlen;
    if (nextlen = 0) then begin
      max_count := 138;
      min_count := 3;
    end
    else if (curlen = nextlen) then begin
      max_count := 6;
      min_count := 3;
    end
    else begin
      max_count := 7;
      min_count := 4;
    end;
  end;
end;

procedure send_tree(var s: deflate_state;
  var tree: array of ct_data; max_code: int);
var
  n: int;
  prevlen: int;
  curlen: int;
  nextlen: int;
  count: int;
  max_count: int;
  min_count: int;
begin
  prevlen := -1;
  nextlen := tree[0].dl.Len;
  count := 0;
  max_count := 7;
  min_count := 4;
  if (nextlen = 0) then begin
    max_count := 138;
    min_count := 3;
  end;
  for n := 0 to max_code do begin
    curlen := nextlen;
    nextlen := tree[n + 1].dl.Len;
    Inc(count);
    if (count < max_count) and (curlen = nextlen) then
      continue
    else if (count < min_count) then begin
      repeat
        send_bits(s, s.bl_tree[curlen].fc.Code, s.bl_tree[curlen].dl.Len);
        Dec(count);
      until (count = 0);
    end
    else if (curlen <> 0) then begin
      if (curlen <> prevlen) then begin
        send_bits(s, s.bl_tree[curlen].fc.Code, s.bl_tree[curlen].dl.Len);
        Dec(count);
      end;
      send_bits(s, s.bl_tree[REP_3_6].fc.Code, s.bl_tree[REP_3_6].dl.Len);
      send_bits(s, count - 3, 2);
    end
    else if (count <= 10) then begin
      send_bits(s, s.bl_tree[REPZ_3_10].fc.Code, s.bl_tree[REPZ_3_10].dl.Len);
      send_bits(s, count - 3, 3);
    end
    else begin
      send_bits(s, s.bl_tree[REPZ_11_138].fc.Code, s.bl_tree[REPZ_11_138].dl.Len);
      send_bits(s, count - 11, 7);
    end;
    count := 0;
    prevlen := curlen;
    if (nextlen = 0) then begin
      max_count := 138;
      min_count := 3;
    end
    else if (curlen = nextlen) then begin
      max_count := 6;
      min_count := 3;
    end
    else begin
      max_count := 7;
      min_count := 4;
    end;
  end;
end;

function build_bl_tree(var s: deflate_state): int;
var
  max_blindex: int;
begin
  scan_tree(s, s.dyn_ltree, s.l_desc.max_code);
  scan_tree(s, s.dyn_dtree, s.d_desc.max_code);
  build_tree(s, s.bl_desc);
  for max_blindex := BL_CODES - 1 downto 3 do begin
    if (s.bl_tree[bl_order[max_blindex]].dl.Len <> 0) then
      break;
  end;
  Inc(s.opt_len, 3 * (max_blindex + 1) + 5 + 5 + 4);
  build_bl_tree := max_blindex;
end;

procedure send_all_trees(var s: deflate_state;
  lcodes: int; dcodes: int; blcodes: int);
var
  rank: int;
begin
  send_bits(s, lcodes - 257, 5);
  send_bits(s, dcodes - 1, 5);
  send_bits(s, blcodes - 4, 4);
  for rank := 0 to blcodes - 1 do
    send_bits(s, s.bl_tree[bl_order[rank]].dl.Len, 3);
  send_tree(s, s.dyn_ltree, lcodes - 1);
  send_tree(s, s.dyn_dtree, dcodes - 1);
end;

procedure bi_windup(var s: deflate_state);
begin
  if (s.bi_valid > 8) then begin
    s.pending_buf^[s.pending] := uch(s.bi_buf and $FF);
    Inc(s.pending);
    s.pending_buf^[s.pending] := uch(ush(s.bi_buf) shr 8); ;
    Inc(s.pending);
  end
  else if (s.bi_valid > 0) then begin
    s.pending_buf^[s.pending] := Byte(s.bi_buf);
    Inc(s.pending);
  end;
  s.bi_buf := 0;
  s.bi_valid := 0;
end;

procedure copy_block(var s: deflate_state;
  buf: pcharf; len: unsigned; header: boolean);
begin
  bi_windup(s);
  s.last_eob_len := 8;
  if (header) then begin
    s.pending_buf^[s.pending] := uch(ush(len) and $FF);
    Inc(s.pending);
    s.pending_buf^[s.pending] := uch(ush(len) shr 8); ;
    Inc(s.pending);
    s.pending_buf^[s.pending] := uch(ush(not len) and $FF);
    Inc(s.pending);
    s.pending_buf^[s.pending] := uch(ush(not len) shr 8); ;
    Inc(s.pending);
  end;
  while (len <> 0) do begin
    Dec(len);
    s.pending_buf^[s.pending] := buf^;
    Inc(buf);
    Inc(s.pending);
  end;
end;

procedure _tr_stored_block(var s: deflate_state;
  buf: pcharf; stored_len: ulg; eof: boolean);
begin
  send_bits(s, (STORED_BLOCK shl 1) + ord(eof), 3);
  s.compressed_len := (s.compressed_len + 3 + 7) and ulg(not Long(7));
  Inc(s.compressed_len, (stored_len + 4) shl 3);
  copy_block(s, buf, unsigned(stored_len), TRUE);
end;

procedure bi_flush(var s: deflate_state);
begin
  if (s.bi_valid = 16) then begin
    s.pending_buf^[s.pending] := uch(s.bi_buf and $FF);
    Inc(s.pending);
    s.pending_buf^[s.pending] := uch(ush(s.bi_buf) shr 8); ;
    Inc(s.pending);
    s.bi_buf := 0;
    s.bi_valid := 0;
  end
  else if (s.bi_valid >= 8) then begin
    s.pending_buf^[s.pending] := Byte(s.bi_buf);
    Inc(s.pending);
    s.bi_buf := s.bi_buf shr 8;
    Dec(s.bi_valid, 8);
  end;
end;

procedure _tr_align(var s: deflate_state);
begin
  send_bits(s, STATIC_TREES shl 1, 3);
  send_bits(s, static_ltree[END_BLOCK].fc.Code, static_ltree[END_BLOCK].dl.Len);
  Inc(s.compressed_len, Long(10));
  bi_flush(s);
  if (1 + s.last_eob_len + 10 - s.bi_valid < 9) then begin
    send_bits(s, STATIC_TREES shl 1, 3);
    send_bits(s, static_ltree[END_BLOCK].fc.Code, static_ltree[END_BLOCK].dl.Len);
    Inc(s.compressed_len, Long(10));
    bi_flush(s);
  end;
  s.last_eob_len := 7;
end;

procedure set_data_type(var s: deflate_state);
var
  n: int;
  ascii_freq: unsigned;
  bin_freq: unsigned;
begin
  n := 0;
  ascii_freq := 0;
  bin_freq := 0;
  while (n < 7) do begin
    Inc(bin_freq, s.dyn_ltree[n].fc.Freq);
    Inc(n);
  end;
  while (n < 128) do begin
    Inc(ascii_freq, s.dyn_ltree[n].fc.Freq);
    Inc(n);
  end;
  while (n < LITERALS) do begin
    Inc(bin_freq, s.dyn_ltree[n].fc.Freq);
    Inc(n);
  end;
  if (bin_freq > (ascii_freq shr 2)) then
    s.data_type := Byte(Z_BINARY)
  else
    s.data_type := Byte(Z_ASCII);
end;

procedure compress_block(var s: deflate_state;
  var ltree: array of ct_data;
  var dtree: array of ct_data);
var
  dist: unsigned;
  lc: int;
  lx: unsigned;
  code: unsigned;
  extra: int;
begin
  lx := 0;
  if (s.last_lit <> 0) then repeat
      dist := s.d_buf^[lx];
      lc := s.l_buf^[lx];
      Inc(lx);
      if (dist = 0) then
        send_bits(s, ltree[lc].fc.Code, ltree[lc].dl.Len)
      else begin
        code := _length_code[lc];
        send_bits(s, ltree[code + LITERALS + 1].fc.Code, ltree[code + LITERALS + 1].dl.Len);
        extra := extra_lbits[code];
        if (extra <> 0) then begin
          Dec(lc, base_length[code]);
          send_bits(s, lc, extra);
        end;
        Dec(dist);
        if (dist < 256) then
          code := _dist_code[dist]
        else
          code := _dist_code[256 + (dist shr 7)];
        send_bits(s, dtree[code].fc.Code, dtree[code].dl.Len);
        extra := extra_dbits[code];
        if (extra <> 0) then begin
          Dec(dist, base_dist[code]);
          send_bits(s, dist, extra);
        end;
      end;
    until (lx >= s.last_lit);
  send_bits(s, ltree[END_BLOCK].fc.Code, ltree[END_BLOCK].dl.Len);
  s.last_eob_len := ltree[END_BLOCK].dl.Len;
end;

function _tr_flush_block(var s: deflate_state;
  buf: pcharf; stored_len: ulg; eof: boolean): ulg;
var
  opt_lenb, static_lenb: ulg;
  max_blindex: int;
begin
  max_blindex := 0;
  if (s.level > 0) then begin
    if (s.data_type = Z_UNKNOWN) then set_data_type(s);
    build_tree(s, s.l_desc);
    build_tree(s, s.d_desc);
    max_blindex := build_bl_tree(s);
    opt_lenb := (s.opt_len + 3 + 7) shr 3;
    static_lenb := (s.static_len + 3 + 7) shr 3;
    if (static_lenb <= opt_lenb) then opt_lenb := static_lenb;
  end
  else begin
    static_lenb := stored_len + 5;
    opt_lenb := static_lenb;
  end;
  if (stored_len + 4 <= opt_lenb) and (buf <> pcharf(0)) then
    _tr_stored_block(s, buf, stored_len, eof)
  else if (static_lenb = opt_lenb) then begin
    send_bits(s, (STATIC_TREES shl 1) + ord(eof), 3);
    compress_block(s, static_ltree, static_dtree);
    Inc(s.compressed_len, 3 + s.static_len);
  end
  else begin
    send_bits(s, (DYN_TREES shl 1) + ord(eof), 3);
    send_all_trees(s, s.l_desc.max_code + 1, s.d_desc.max_code + 1,
      max_blindex + 1);
    compress_block(s, s.dyn_ltree, s.dyn_dtree);
    Inc(s.compressed_len, 3 + s.opt_len);
  end;
  init_block(s);
  if (eof) then begin
    bi_windup(s);
    Inc(s.compressed_len, 7);
  end;
  _tr_flush_block := s.compressed_len shr 3;
end;

function _tr_tally(var s: deflate_state;
  dist: unsigned; lc: unsigned): boolean;
var
  code: ush;
begin
  s.d_buf^[s.last_lit] := ush(dist);
  s.l_buf^[s.last_lit] := uch(lc);
  Inc(s.last_lit);
  if (dist = 0) then
    Inc(s.dyn_ltree[lc].fc.Freq)
  else begin
    Inc(s.matches);
    Dec(dist);
    if (dist) < 256 then
      code := _dist_code[dist]
    else
      code := _dist_code[256 + (dist shr 7)];
    Inc(s.dyn_ltree[_length_code[lc] + LITERALS + 1].fc.Freq);
    Inc(s.dyn_dtree[code].fc.Freq);
  end;
  _tr_tally := (s.last_lit = s.lit_bufsize - 1);
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ adler32.c -- compute the Adler-32 checksum of a data stream
  Copyright (C) 1995-1998 Mark Adler

  adler.pas -- Pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
  For conditions of distribution and use, see copyright notice in readme.txt
}

const
  BASE = uLong(65521); { largest prime smaller than 65536 }
{$IFNDEF Delphi2or3} { Delphi 4 or higher }
  NMAX = 5552; { original code with unsigned 32 bit integer }
  { NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^32-1 }
{$ELSE}              { Delphi 2 and 3 }
  NMAX = 3854; { code with signed 32 bit integer }
  { NMAX is the largest n such that 255n(n+1)/2 + (n+1)(BASE-1) <= 2^31-1 }
  { The penalty is the time loss in the extra MOD-calls. }
{$ENDIF}

function adler32(adler: uLong; buf: pBytef; len: uInt): uLong;
var
  s1, s2: uLong;
  k: int;
begin
  s1 := adler and $FFFF;
  s2 := (adler shr 16) and $FFFF;
  if not Assigned(buf) then begin
    adler32 := uLong(1);
    exit;
  end;
  while (len > 0) do begin
    if len < NMAX then
      k := len
    else
      k := NMAX;
    Dec(len, k);
    while (k > 0) do begin
      Inc(s1, buf^);
      Inc(s2, s1);
      Inc(buf);
      Dec(k);
    end;
    s1 := s1 mod BASE;
    s2 := s2 mod BASE;
  end;
  adler32 := (s2 shl 16) or s1;
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ Original: deflate.h -- internal compression state
            deflate.c -- compress data using the deflation algorithm
  Copyright (C) 1995-1996 Jean-loup Gailly.

  zdeflate.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

type
  block_state = (need_more, block_done, finish_started, finish_done);
  compress_func = function(var s: deflate_state; flush: int): block_state;

procedure fill_window(var s: deflate_state); forward;
function deflate_stored(var s: deflate_state; flush: int): block_state; far; forward;
function deflate_fast(var s: deflate_state; flush: int): block_state; far; forward;
function deflate_slow(var s: deflate_state; flush: int): block_state; far; forward;
procedure lm_init(var s: deflate_state); forward;
procedure putShortMSB(var s: deflate_state; b: uInt); forward;
procedure flush_pending(var strm: z_stream); forward;
function read_buf(strm: z_streamp; buf: pBytef; size: unsigned): int; forward;
function longest_match(var s: deflate_state; cur_match: IPos): uInt; forward;

const
  ZNIL = 0;
  TOO_FAR = 4096;
  MIN_LOOKAHEAD = (MAX_MATCH + MIN_MATCH + 1);

type
  config = record
    good_length: ush;
    max_lazy: ush;
    nice_length: ush;
    max_chain: ush;
    func: compress_func;
  end;

const
  configuration_table: array[0..10 - 1] of config = (
 {0}(good_length: 0; max_lazy: 0; nice_length: 0; max_chain: 0; func: deflate_stored),
 {1}(good_length: 4; max_lazy: 4; nice_length: 8; max_chain: 4; func: deflate_fast),
 {2}(good_length: 4; max_lazy: 5; nice_length: 16; max_chain: 8; func: deflate_fast),
 {3}(good_length: 4; max_lazy: 6; nice_length: 32; max_chain: 32; func: deflate_fast),

 {4}(good_length: 4; max_lazy: 4; nice_length: 16; max_chain: 16; func: deflate_slow),
 {5}(good_length: 8; max_lazy: 16; nice_length: 32; max_chain: 32; func: deflate_slow),
 {6}(good_length: 8; max_lazy: 16; nice_length: 128; max_chain: 128; func: deflate_slow),
 {7}(good_length: 8; max_lazy: 32; nice_length: 128; max_chain: 256; func: deflate_slow),
{8}(good_length: 32; max_lazy: 128; nice_length: 258; max_chain: 1024; func: deflate_slow),
{9}(good_length: 32; max_lazy: 258; nice_length: 258; max_chain: 4096; func: deflate_slow));

const
  EQUAL = 0;

procedure INSERT_STRING(var s: deflate_state;
  str: uInt; var match_head: IPos);
begin
  s.ins_h := ((s.ins_h shl s.hash_shift) xor
    (s.window^[(str) + (MIN_MATCH - 1)])) and s.hash_mask;
  match_head := s.head^[s.ins_h];
  s.prev^[(str) and s.w_mask] := match_head;
  s.head^[s.ins_h] := Pos(str);
end;

function deflateInit2_(var strm: z_stream;
  level: int; method: int; windowBits: int; memLevel: int; strategy: int;
  const version: string; stream_size: int): int;
var
  s: deflate_state_ptr;
  noheader: integer;
  overlay: pushfArray;
  d: integer;
begin
  noheader := 0;
  {
  if (version = '') or (version[1] <> ZLIB_VERSION[1]) or
    (stream_size <> sizeof(z_stream)) then begin
    deflateInit2_ := Z_VERSION_ERROR;
    exit;
  end;
  }
  strm.msg := '';
  if not Assigned(strm.zalloc) then begin
    strm.zalloc := zcalloc;
    strm.opaque := voidpf(0);
  end;
  if not Assigned(strm.zfree) then
    strm.zfree := zcfree;
  if (level = Z_DEFAULT_COMPRESSION) then
    level := 6;
  if (windowBits < 0) then begin
    noheader := 1;
    windowBits := -windowBits;
  end;
  if (memLevel < 1) or (memLevel > MAX_MEM_LEVEL) or (method <> Z_DEFLATED)
    or (windowBits < 8) or (windowBits > 15) or (level < 0)
    or (level > 9) or (strategy < 0) or (strategy > Z_HUFFMAN_ONLY) then begin
    deflateInit2_ := Z_STREAM_ERROR;
    exit;
  end;
  s := deflate_state_ptr(ZALLOC(strm, 1, sizeof(deflate_state)));
  if (s = Z_NULL) then begin
    deflateInit2_ := Z_MEM_ERROR;
    exit;
  end;
  strm.state := pInternal_state(s);
  s^.strm := @strm;
  s^.noheader := noheader;
  s^.w_bits := windowBits;
  s^.w_size := 1 shl s^.w_bits;
  s^.w_mask := s^.w_size - 1;
  s^.hash_bits := memLevel + 7;
  s^.hash_size := 1 shl s^.hash_bits;
  s^.hash_mask := s^.hash_size - 1;
  s^.hash_shift := ((s^.hash_bits + MIN_MATCH - 1) div MIN_MATCH);
  s^.window := pzByteArray(ZALLOC(strm, s^.w_size, 2 * sizeof(Byte)));
  s^.prev := pzPosfArray(ZALLOC(strm, s^.w_size, sizeof(Pos)));
  s^.head := pzPosfArray(ZALLOC(strm, s^.hash_size, sizeof(Pos)));
  s^.lit_bufsize := 1 shl (memLevel + 6);
  overlay := pushfArray(ZALLOC(strm, s^.lit_bufsize, sizeof(ush) + 2));
  s^.pending_buf := pzByteArray(overlay);
  s^.pending_buf_size := ulg(s^.lit_bufsize) * (sizeof(ush) + Long(2));
  if (s^.window = Z_NULL) or (s^.prev = Z_NULL) or (s^.head = Z_NULL)
    or (s^.pending_buf = Z_NULL) then begin
    strm.msg := z_errmsg[z_errbase - Z_MEM_ERROR];
    deflateEnd(strm);
    deflateInit2_ := Z_MEM_ERROR;
    exit;
  end;
  s^.d_buf := pushfArray(@overlay^[s^.lit_bufsize div sizeof(ush)]);
  s^.l_buf := puchfArray(@s^.pending_buf^[(1 + sizeof(ush)) * s^.lit_bufsize]);
  s^.level := level;
  s^.strategy := strategy;
  s^.method := Byte(method);
  deflateInit2_ := deflateReset(strm);
end;

function deflateInit2(var strm: z_stream;
  level: int; method: int; windowBits: int; memLevel: int; strategy: int): int;
begin
  deflateInit2 := deflateInit2_(strm, level, method, windowBits,
    memLevel, strategy, ZLIB_VERSION, sizeof(z_stream));
end;

function deflateInit_(strm: z_streamp;
  level: int; const version: string; stream_size: int): int;
begin
  if (strm = Z_NULL) then
    deflateInit_ := Z_STREAM_ERROR
  else
    deflateInit_ := deflateInit2_(strm^, level, Z_DEFLATED, MAX_WBITS,
      DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY, version, stream_size);
end;

function deflateInit(var strm: z_stream; level: int): int;
begin
  deflateInit := deflateInit2_(strm, level, Z_DEFLATED, MAX_WBITS,
    DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, sizeof(z_stream));
end;

function deflateSetDictionary(var strm: z_stream;
  dictionary: pBytef; dictLength: uInt): int;
var
  s: deflate_state_ptr;
  length: uInt;
  n: uInt;
  hash_head: IPos;
var
  MAX_DIST: uInt;
begin
  length := dictLength;
  hash_head := 0;
  if {(@strm  =  Z_NULL) or}
    (strm.state = Z_NULL) or (dictionary = Z_NULL)
    or (deflate_state_ptr(strm.state)^.status <> INIT_STATE) then
  begin
    deflateSetDictionary := Z_STREAM_ERROR;
    exit;
  end;
  s := deflate_state_ptr(strm.state);
  strm.adler := adler32(strm.adler, dictionary, dictLength);
  if (length < MIN_MATCH) then begin
    deflateSetDictionary := Z_OK;
    exit;
  end;
  MAX_DIST := (s^.w_size - MIN_LOOKAHEAD);
  if (length > MAX_DIST) then begin
    length := MAX_DIST;
    Inc(dictionary, dictLength - length);
  end;
  zmemcpy(pBytef(s^.window), dictionary, length);
  s^.strstart := length;
  s^.block_start := long(length);
  s^.ins_h := s^.window^[0];
  s^.ins_h := ((s^.ins_h shl s^.hash_shift) xor (s^.window^[1]))
    and s^.hash_mask;
  for n := 0 to length - MIN_MATCH do INSERT_STRING(s^, n, hash_head);
  deflateSetDictionary := Z_OK;
end;

function deflateReset(var strm: z_stream): int;
var
  s: deflate_state_ptr;
begin
  if {(@strm = Z_NULL) or}
    (strm.state = Z_NULL)
    or (not Assigned(strm.zalloc)) or (not Assigned(strm.zfree)) then begin
    deflateReset := Z_STREAM_ERROR;
    exit;
  end;
  strm.total_out := 0;
  strm.total_in := 0;
  strm.msg := '';
  strm.data_type := Z_UNKNOWN;
  s := deflate_state_ptr(strm.state);
  s^.pending := 0;
  s^.pending_out := pBytef(s^.pending_buf);
  if (s^.noheader < 0) then s^.noheader := 0;
  if s^.noheader <> 0 then
    s^.status := BUSY_STATE
  else
    s^.status := INIT_STATE;
  strm.adler := 1;
  s^.last_flush := Z_NO_FLUSH;
  _tr_init(s^);
  lm_init(s^);
  deflateReset := Z_OK;
end;

function deflateParams(var strm: z_stream; level: int; strategy: int): int;
var
  s: deflate_state_ptr;
  func: compress_func;
  err: int;
begin
  err := Z_OK;
  if {(@strm  =  Z_NULL) or}(strm.state = Z_NULL) then begin
    deflateParams := Z_STREAM_ERROR;
    exit;
  end;
  s := deflate_state_ptr(strm.state);
  if (level = Z_DEFAULT_COMPRESSION) then level := 6;
  if (level < 0) or (level > 9) or (strategy < 0) or (strategy > Z_HUFFMAN_ONLY) then begin
    deflateParams := Z_STREAM_ERROR;
    exit;
  end;
  func := configuration_table[s^.level].func;
  if (@func <> @configuration_table[level].func) and (strm.total_in <> 0) then
    err := deflate(strm, Z_PARTIAL_FLUSH);
  if (s^.level <> level) then begin
    s^.level := level;
    s^.max_lazy_match := configuration_table[level].max_lazy;
    s^.good_match := configuration_table[level].good_length;
    s^.nice_match := configuration_table[level].nice_length;
    s^.max_chain_length := configuration_table[level].max_chain;
  end;
  s^.strategy := strategy;
  deflateParams := err;
end;

procedure putShortMSB(var s: deflate_state; b: uInt);
begin
  s.pending_buf^[s.pending] := Byte(b shr 8);
  Inc(s.pending);
  s.pending_buf^[s.pending] := Byte(b and $FF);
  Inc(s.pending);
end;

procedure flush_pending(var strm: z_stream);
var
  len: unsigned;
  s: deflate_state_ptr;
begin
  s := deflate_state_ptr(strm.state);
  len := s^.pending;
  if (len > strm.avail_out) then len := strm.avail_out;
  if (len = 0) then exit;
  zmemcpy(strm.next_out, s^.pending_out, len);
  Inc(strm.next_out, len);
  Inc(s^.pending_out, len);
  Inc(strm.total_out, len);
  Dec(strm.avail_out, len);
  Dec(s^.pending, len);
  if (s^.pending = 0) then s^.pending_out := pBytef(s^.pending_buf);
end;

function deflate(var strm: z_stream; flush: int): int;
var
  old_flush: int;
  s: deflate_state_ptr;
  header: uInt;
  level_flags: uInt;
  bstate: block_state;
begin
  if {(@strm = Z_NULL) or}(strm.state = Z_NULL) or (flush > Z_FINISH) or (flush < 0) then begin
    deflate := Z_STREAM_ERROR;
    exit;
  end;
  s := deflate_state_ptr(strm.state);
  if (strm.next_out = Z_NULL) or
    ((strm.next_in = Z_NULL) and (strm.avail_in <> 0)) or
    ((s^.status = FINISH_STATE) and (flush <> Z_FINISH)) then begin
    strm.msg := z_errmsg[z_errbase - Z_STREAM_ERROR];
    deflate := Z_STREAM_ERROR;
    exit;
  end;
  if (strm.avail_out = 0) then begin
    strm.msg := z_errmsg[z_errbase - Z_BUF_ERROR];
    deflate := Z_BUF_ERROR;
    exit;
  end;
  s^.strm := @strm;
  old_flush := s^.last_flush;
  s^.last_flush := flush;
  if (s^.status = INIT_STATE) then begin
    header := (Z_DEFLATED + ((s^.w_bits - 8) shl 4)) shl 8;
    level_flags := (s^.level - 1) shr 1;
    if (level_flags > 3) then level_flags := 3;
    header := header or (level_flags shl 6);
    if (s^.strstart <> 0) then header := header or PRESET_DICT;
    Inc(header, 31 - (header mod 31));
    s^.status := BUSY_STATE;
    putShortMSB(s^, header);
    if (s^.strstart <> 0) then begin
      putShortMSB(s^, uInt(strm.adler shr 16));
      putShortMSB(s^, uInt(strm.adler and $FFFF));
    end;
    strm.adler := long(1);
  end;
  if (s^.pending <> 0) then begin
    flush_pending(strm);
    if (strm.avail_out = 0) then begin
      s^.last_flush := -1;
      deflate := Z_OK;
      exit;
    end;
  end
  else if (strm.avail_in = 0) and (flush <= old_flush) and (flush <> Z_FINISH) then begin
    strm.msg := z_errmsg[z_errbase - Z_BUF_ERROR];
    deflate := Z_BUF_ERROR;
    exit;
  end;
  if (s^.status = FINISH_STATE) and (strm.avail_in <> 0) then begin
    strm.msg := z_errmsg[z_errbase - Z_BUF_ERROR];
    deflate := Z_BUF_ERROR;
    exit;
  end;
  if (strm.avail_in <> 0) or (s^.lookahead <> 0)
    or ((flush <> Z_NO_FLUSH) and (s^.status <> FINISH_STATE)) then begin
    bstate := configuration_table[s^.level].func(s^, flush);
    if (bstate = finish_started) or (bstate = finish_done) then
      s^.status := FINISH_STATE;
    if (bstate = need_more) or (bstate = finish_started) then begin
      if (strm.avail_out = 0) then s^.last_flush := -1;
      deflate := Z_OK;
      exit;
    end;
    if (bstate = block_done) then begin
      if (flush = Z_PARTIAL_FLUSH) then
        _tr_align(s^)
      else begin
        _tr_stored_block(s^, pcharf(nil), Long(0), FALSE);
        if (flush = Z_FULL_FLUSH) then begin
          s^.head^[s^.hash_size - 1] := ZNIL;
          zmemzero(pBytef(s^.head), unsigned(s^.hash_size - 1) * sizeof(s^.head^[0]));
        end;
      end;
      flush_pending(strm);
      if (strm.avail_out = 0) then begin
        s^.last_flush := -1;
        deflate := Z_OK;
        exit;
      end;
    end;
  end;
  if (flush <> Z_FINISH) then begin
    deflate := Z_OK;
    exit;
  end;
  if (s^.noheader <> 0) then begin
    deflate := Z_STREAM_END;
    exit;
  end;
  putShortMSB(s^, uInt(strm.adler shr 16));
  putShortMSB(s^, uInt(strm.adler and $FFFF));
  flush_pending(strm);
  s^.noheader := -1;
  if s^.pending <> 0 then
    deflate := Z_OK
  else
    deflate := Z_STREAM_END;
end;

function deflateEnd(var strm: z_stream): int;
var
  status: int;
  s: deflate_state_ptr;
begin
  if {(@strm = Z_NULL) or}(strm.state = Z_NULL) then begin
    deflateEnd := Z_STREAM_ERROR;
    exit;
  end;
  s := deflate_state_ptr(strm.state);
  status := s^.status;
  if (status <> INIT_STATE) and (status <> BUSY_STATE) and
    (status <> FINISH_STATE) then begin
    deflateEnd := Z_STREAM_ERROR;
    exit;
  end;
  TRY_FREE(strm, s^.pending_buf);
  TRY_FREE(strm, s^.head);
  TRY_FREE(strm, s^.prev);
  TRY_FREE(strm, s^.window);
  ZFREE(strm, s);
  strm.state := Z_NULL;
  if status = BUSY_STATE then
    deflateEnd := Z_DATA_ERROR
  else
    deflateEnd := Z_OK;
end;

function deflateCopy(dest, source: z_streamp): int;
var
  ds: deflate_state_ptr;
  ss: deflate_state_ptr;
  overlay: pushfArray;
begin
  if (source = Z_NULL) or (dest = Z_NULL) or (source^.state = Z_NULL) then begin
    deflateCopy := Z_STREAM_ERROR;
    exit;
  end;
  ss := deflate_state_ptr(source^.state);
  dest^ := source^;
  ds := deflate_state_ptr(ZALLOC(dest^, 1, sizeof(deflate_state)));
  if (ds = Z_NULL) then begin
    deflateCopy := Z_MEM_ERROR;
    exit;
  end;
  dest^.state := pInternal_state(ds);
  ds^ := ss^;
  ds^.strm := dest;
  ds^.window := pzByteArray(ZALLOC(dest^, ds^.w_size, 2 * sizeof(Byte)));
  ds^.prev := pzPosfArray(ZALLOC(dest^, ds^.w_size, sizeof(Pos)));
  ds^.head := pzPosfArray(ZALLOC(dest^, ds^.hash_size, sizeof(Pos)));
  overlay := pushfArray(ZALLOC(dest^, ds^.lit_bufsize, sizeof(ush) + 2));
  ds^.pending_buf := pzByteArray(overlay);
  if (ds^.window = Z_NULL) or (ds^.prev = Z_NULL) or (ds^.head = Z_NULL)
    or (ds^.pending_buf = Z_NULL) then begin
    deflateEnd(dest^);
    deflateCopy := Z_MEM_ERROR;
    exit;
  end;
  zmemcpy(pBytef(ds^.window), pBytef(ss^.window), ds^.w_size * 2 * sizeof(Byte));
  zmemcpy(pBytef(ds^.prev), pBytef(ss^.prev), ds^.w_size * sizeof(Pos));
  zmemcpy(pBytef(ds^.head), pBytef(ss^.head), ds^.hash_size * sizeof(Pos));
  zmemcpy(pBytef(ds^.pending_buf), pBytef(ss^.pending_buf), uInt(ds^.pending_buf_size));
  ds^.pending_out := @ds^.pending_buf^[ptr2int(ss^.pending_out) - ptr2int(ss^.pending_buf)];
  ds^.d_buf := pushfArray(@overlay^[ds^.lit_bufsize div sizeof(ush)]);
  ds^.l_buf := puchfArray(@ds^.pending_buf^[(1 + sizeof(ush)) * ds^.lit_bufsize]);
  ds^.l_desc.dyn_tree := tree_ptr(@ds^.dyn_ltree);
  ds^.d_desc.dyn_tree := tree_ptr(@ds^.dyn_dtree);
  ds^.bl_desc.dyn_tree := tree_ptr(@ds^.bl_tree);
  deflateCopy := Z_OK;
end;

function read_buf(strm: z_streamp; buf: pBytef; size: unsigned): int;
var
  len: unsigned;
begin
  len := strm^.avail_in;
  if (len > size) then
    len := size;
  if (len = 0) then begin
    read_buf := 0;
    exit;
  end;
  Dec(strm^.avail_in, len);
  if deflate_state_ptr(strm^.state)^.noheader = 0 then begin
    strm^.adler := adler32(strm^.adler, strm^.next_in, len);
  end;
  zmemcpy(buf, strm^.next_in, len);
  Inc(strm^.next_in, len);
  Inc(strm^.total_in, len);
  read_buf := int(len);
end;

procedure lm_init(var s: deflate_state);
begin
  s.window_size := ulg(uLong(2) * s.w_size);
  s.head^[s.hash_size - 1] := ZNIL;
  zmemzero(pBytef(s.head), unsigned(s.hash_size - 1) * sizeof(s.head^[0]));
  s.max_lazy_match := configuration_table[s.level].max_lazy;
  s.good_match := configuration_table[s.level].good_length;
  s.nice_match := configuration_table[s.level].nice_length;
  s.max_chain_length := configuration_table[s.level].max_chain;
  s.strstart := 0;
  s.block_start := long(0);
  s.lookahead := 0;
  s.prev_length := MIN_MATCH - 1;
  s.match_length := MIN_MATCH - 1;
  s.match_available := FALSE;
  s.ins_h := 0;
end;

function longest_match(var s: deflate_state; cur_match: IPos): uInt;
label
  nextstep;
var
  chain_length: unsigned;
  scan: pBytef;
  match: pBytef;
  len: int;
  best_len: int;
  nice_match: int;
  limit: IPos;
  prev: pzPosfArray;
  wmask: uInt;
  strend: pBytef;
  scan_end1: Byte;
  scan_end: Byte;
var
  MAX_DIST: uInt;
begin
  chain_length := s.max_chain_length;
  scan := @(s.window^[s.strstart]);
  best_len := s.prev_length;
  nice_match := s.nice_match;
  MAX_DIST := s.w_size - MIN_LOOKAHEAD;
  if s.strstart > IPos(MAX_DIST) then
    limit := s.strstart - IPos(MAX_DIST)
  else
    limit := ZNIL;
  prev := s.prev;
  wmask := s.w_mask;
  strend := pBytef(@(s.window^[s.strstart + MAX_MATCH]));
{$IFOPT R+}{$R-}{$DEFINE NoRangeCheck}{$ENDIF}
  scan_end1 := pzByteArray(scan)^[best_len - 1];
{$IFDEF NoRangeCheck}{$R+}{$UNDEF NoRangeCheck}{$ENDIF}
  scan_end := pzByteArray(scan)^[best_len];
  if (s.prev_length >= s.good_match) then chain_length := chain_length shr 2;
  if (uInt(nice_match) > s.lookahead) then nice_match := s.lookahead;
  repeat
    match := @(s.window^[cur_match]);
{$IFOPT R+}{$R-}{$DEFINE NoRangeCheck}{$ENDIF}
    if (pzByteArray(match)^[best_len] <> scan_end) or
      (pzByteArray(match)^[best_len - 1] <> scan_end1) or
      (match^ <> scan^) then goto nextstep;
{$IFDEF NoRangeCheck}{$R+}{$UNDEF NoRangeCheck}{$ENDIF}
    Inc(match);
    if (match^ <> pzByteArray(scan)^[1]) then goto nextstep;
    Inc(scan, 2);
    Inc(match);
    repeat
      Inc(scan); Inc(match); if (scan^ <> match^) then break;
      Inc(scan); Inc(match); if (scan^ <> match^) then break;
      Inc(scan); Inc(match); if (scan^ <> match^) then break;
      Inc(scan); Inc(match); if (scan^ <> match^) then break;
      Inc(scan); Inc(match); if (scan^ <> match^) then break;
      Inc(scan); Inc(match); if (scan^ <> match^) then break;
      Inc(scan); Inc(match); if (scan^ <> match^) then break;
      Inc(scan); Inc(match); if (scan^ <> match^) then break;
    until (ptr2int(scan) >= ptr2int(strend));
    len := MAX_MATCH - int(ptr2int(strend) - ptr2int(scan));
    scan := strend;
    Dec(scan, MAX_MATCH);
    if (len > best_len) then begin
      s.match_start := cur_match;
      best_len := len;
      if (len >= nice_match) then break;
{$IFOPT R+}{$R-}{$DEFINE NoRangeCheck}{$ENDIF}
      scan_end1 := pzByteArray(scan)^[best_len - 1];
      scan_end := pzByteArray(scan)^[best_len];
{$IFDEF NoRangeCheck}{$R+}{$UNDEF NoRangeCheck}{$ENDIF}
    end;
    nextstep:
    cur_match := prev^[cur_match and wmask];
    Dec(chain_length);
  until (cur_match <= limit) or (chain_length = 0);
  if (uInt(best_len) <= s.lookahead) then
    longest_match := uInt(best_len)
  else
    longest_match := s.lookahead;
end;

procedure fill_window(var s: deflate_state);
var
  n, m: unsigned;
  p: pPosf;
  more: unsigned;
  wsize: uInt;
begin
  wsize := s.w_size;
  repeat
    more := unsigned(s.window_size - ulg(s.lookahead) - ulg(s.strstart));
    if (more = 0) and (s.strstart = 0) and (s.lookahead = 0) then
      more := wsize
    else
      if (more = unsigned(-1)) then
        Dec(more)
      else if (s.strstart >= wsize + (wsize - MIN_LOOKAHEAD)) then begin
        zmemcpy(pBytef(s.window), pBytef(@(s.window^[wsize])), unsigned(wsize));
        Dec(s.match_start, wsize);
        Dec(s.strstart, wsize);
        Dec(s.block_start, long(wsize));
        n := s.hash_size;
        p := @s.head^[n];
        repeat
          Dec(p);
          m := p^;
          if (m >= wsize) then
            p^ := Pos(m - wsize)
          else
            p^ := Pos(ZNIL);
          Dec(n);
        until (n = 0);
        n := wsize;
        p := @s.prev^[n];
        repeat
          Dec(p);
          m := p^;
          if (m >= wsize) then
            p^ := Pos(m - wsize)
          else
            p^ := Pos(ZNIL);
          Dec(n);
        until (n = 0);
        Inc(more, wsize);
      end;
    if (s.strm^.avail_in = 0) then exit;
    n := read_buf(s.strm, pBytef(@(s.window^[s.strstart + s.lookahead])), more);
    Inc(s.lookahead, n);
    if (s.lookahead >= MIN_MATCH) then begin
      s.ins_h := s.window^[s.strstart];
      s.ins_h := ((s.ins_h shl s.hash_shift) xor s.window^[s.strstart + 1]) and s.hash_mask;
    end;
  until (s.lookahead >= MIN_LOOKAHEAD) or (s.strm^.avail_in = 0);
end;

procedure FLUSH_BLOCK_ONLY(var s: deflate_state; eof: boolean);
begin
  if (s.block_start >= Long(0)) then
    _tr_flush_block(s, pcharf(@s.window^[unsigned(s.block_start)]),
      ulg(long(s.strstart) - s.block_start), eof)
  else
    _tr_flush_block(s, pcharf(Z_NULL),
      ulg(long(s.strstart) - s.block_start), eof);
  s.block_start := s.strstart;
  flush_pending(s.strm^);
end;

function deflate_stored(var s: deflate_state; flush: int): block_state;
var
  max_block_size: ulg;
  max_start: ulg;
begin
  max_block_size := $FFFF;
  if (max_block_size > s.pending_buf_size - 5) then
    max_block_size := s.pending_buf_size - 5;
  while TRUE do begin
    if (s.lookahead <= 1) then begin
      fill_window(s);
      if (s.lookahead = 0) and (flush = Z_NO_FLUSH) then begin
        deflate_stored := need_more;
        exit;
      end;
      if (s.lookahead = 0) then break;
    end;
    Inc(s.strstart, s.lookahead);
    s.lookahead := 0;
    max_start := s.block_start + max_block_size;
    if (s.strstart = 0) or (ulg(s.strstart) >= max_start) then begin
      s.lookahead := uInt(s.strstart - max_start);
      s.strstart := uInt(max_start);
      FLUSH_BLOCK_ONLY(s, FALSE);
      if (s.strm^.avail_out = 0) then begin
        deflate_stored := need_more;
        exit;
      end;
    end;
    if (s.strstart - uInt(s.block_start) >= s.w_size - MIN_LOOKAHEAD) then begin
      FLUSH_BLOCK_ONLY(s, FALSE);
      if (s.strm^.avail_out = 0) then begin
        deflate_stored := need_more;
        exit;
      end;
    end;
  end;
  FLUSH_BLOCK_ONLY(s, flush = Z_FINISH);
  if (s.strm^.avail_out = 0) then begin
    if flush = Z_FINISH then
      deflate_stored := finish_started
    else
      deflate_stored := need_more;
    exit;
  end;
  if flush = Z_FINISH then
    deflate_stored := finish_done
  else
    deflate_stored := block_done;
end;

function deflate_fast(var s: deflate_state; flush: int): block_state;
var
  hash_head: IPos;
  bflush: boolean;
begin
  hash_head := ZNIL;
  while TRUE do begin
    if (s.lookahead < MIN_LOOKAHEAD) then begin
      fill_window(s);
      if (s.lookahead < MIN_LOOKAHEAD) and (flush = Z_NO_FLUSH) then begin
        deflate_fast := need_more;
        exit;
      end;
      if (s.lookahead = 0) then break;
    end;
    if (s.lookahead >= MIN_MATCH) then INSERT_STRING(s, s.strstart, hash_head);
    if (hash_head <> ZNIL) and
      (s.strstart - hash_head <= (s.w_size - MIN_LOOKAHEAD)) then begin
      if (s.strategy <> Z_HUFFMAN_ONLY) then s.match_length := longest_match(s, hash_head);
    end;
    if (s.match_length >= MIN_MATCH) then begin
      bflush := _tr_tally(s, s.strstart - s.match_start,
        s.match_length - MIN_MATCH);
      Dec(s.lookahead, s.match_length);
      if (s.match_length <= s.max_insert_length)
        and (s.lookahead >= MIN_MATCH) then begin
        Dec(s.match_length);
        repeat
          Inc(s.strstart);
          INSERT_STRING(s, s.strstart, hash_head);
          Dec(s.match_length);
        until (s.match_length = 0);
        Inc(s.strstart);
      end
      else begin
        Inc(s.strstart, s.match_length);
        s.match_length := 0;
        s.ins_h := s.window^[s.strstart];
        s.ins_h := ((s.ins_h shl s.hash_shift) xor
          s.window^[s.strstart + 1]) and s.hash_mask;
      end;
    end
    else begin
      bflush := _tr_tally(s, 0, s.window^[s.strstart]);
      Dec(s.lookahead);
      Inc(s.strstart);
    end;
    if bflush then begin
      FLUSH_BLOCK_ONLY(s, FALSE);
      if (s.strm^.avail_out = 0) then begin
        deflate_fast := need_more;
        exit;
      end;
    end;
  end;
  FLUSH_BLOCK_ONLY(s, flush = Z_FINISH);
  if (s.strm^.avail_out = 0) then begin
    if flush = Z_FINISH then
      deflate_fast := finish_started
    else
      deflate_fast := need_more;
    exit;
  end;
  if flush = Z_FINISH then
    deflate_fast := finish_done
  else
    deflate_fast := block_done;
end;

function deflate_slow(var s: deflate_state; flush: int): block_state;
var
  hash_head: IPos;
  bflush: boolean;
var
  max_insert: uInt;
begin
  hash_head := ZNIL;
  while TRUE do begin
    if (s.lookahead < MIN_LOOKAHEAD) then begin
      fill_window(s);
      if (s.lookahead < MIN_LOOKAHEAD) and (flush = Z_NO_FLUSH) then begin
        deflate_slow := need_more;
        exit;
      end;
      if (s.lookahead = 0) then break;
    end;
    if (s.lookahead >= MIN_MATCH) then INSERT_STRING(s, s.strstart, hash_head);
    s.prev_length := s.match_length;
    s.prev_match := s.match_start;
    s.match_length := MIN_MATCH - 1;
    if (hash_head <> ZNIL) and (s.prev_length < s.max_lazy_match) and
      (s.strstart - hash_head <= (s.w_size - MIN_LOOKAHEAD)) then begin
      if (s.strategy <> Z_HUFFMAN_ONLY) then
        s.match_length := longest_match(s, hash_head);
      if (s.match_length <= 5) and ((s.strategy = Z_FILTERED) or
        ((s.match_length = MIN_MATCH) and
        (s.strstart - s.match_start > TOO_FAR))) then
        s.match_length := MIN_MATCH - 1;
    end;
    if (s.prev_length >= MIN_MATCH)
      and (s.match_length <= s.prev_length) then begin
      max_insert := s.strstart + s.lookahead - MIN_MATCH;
      bflush := _tr_tally(s, s.strstart - 1 - s.prev_match,
        s.prev_length - MIN_MATCH);
      Dec(s.lookahead, s.prev_length - 1);
      Dec(s.prev_length, 2);
      repeat
        Inc(s.strstart);
        if (s.strstart <= max_insert) then INSERT_STRING(s, s.strstart, hash_head);
        Dec(s.prev_length);
      until (s.prev_length = 0);
      s.match_available := FALSE;
      s.match_length := MIN_MATCH - 1;
      Inc(s.strstart);
      if (bflush) then begin
        FLUSH_BLOCK_ONLY(s, FALSE);
        if (s.strm^.avail_out = 0) then begin
          deflate_slow := need_more;
          exit;
        end;
      end;
    end
    else if (s.match_available) then begin
      bflush := _tr_tally(s, 0, s.window^[s.strstart - 1]);
      if bflush then FLUSH_BLOCK_ONLY(s, FALSE);
      Inc(s.strstart);
      Dec(s.lookahead);
      if (s.strm^.avail_out = 0) then begin
        deflate_slow := need_more;
        exit;
      end;
    end
    else begin
      s.match_available := TRUE;
      Inc(s.strstart);
      Dec(s.lookahead);
    end;
  end;
  if (s.match_available) then begin
    _tr_tally(s, 0, s.window^[s.strstart - 1]);
    s.match_available := FALSE;
  end;
  FLUSH_BLOCK_ONLY(s, flush = Z_FINISH);
  if (s.strm^.avail_out = 0) then begin
    if flush = Z_FINISH then
      deflate_slow := finish_started
    else
      deflate_slow := need_more;
    exit;
  end;
  if flush = Z_FINISH then
    deflate_slow := finish_done
  else
    deflate_slow := block_done;
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ crc32.c -- compute the CRC-32 of a data stream
  Copyright (C) 1995-1998 Mark Adler

  crc.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

const
  crc_table: array[0..256 - 1] of uLongf = (
    $00000000, $77073096, $EE0E612C, $990951BA, $076DC419,
    $706AF48F, $E963A535, $9E6495A3, $0EDB8832, $79DCB8A4,
    $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07,
    $90BF1D91, $1DB71064, $6AB020F2, $F3B97148, $84BE41DE,
    $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7, $136C9856,
    $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9,
    $FA0F3D63, $8D080DF5, $3B6E20C8, $4C69105E, $D56041E4,
    $A2677172, $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
    $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3,
    $45DF5C75, $DCD60DCF, $ABD13D59, $26D930AC, $51DE003A,
    $C8D75180, $BFD06116, $21B4F4B5, $56B3C423, $CFBA9599,
    $B8BDA50F, $2802B89E, $5F058808, $C60CD9B2, $B10BE924,
    $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D, $76DC4190,
    $01DB7106, $98D220BC, $EFD5102A, $71B18589, $06B6B51F,
    $9FBFE4A5, $E8B8D433, $7807C9A2, $0F00F934, $9609A88E,
    $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
    $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED,
    $1B01A57B, $8208F4C1, $F50FC457, $65B0D9C6, $12B7E950,
    $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49, $8CD37CF3,
    $FBD44C65, $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2,
    $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB, $4369E96A,
    $346ED9FC, $AD678846, $DA60B8D0, $44042D73, $33031DE5,
    $AA0A4C5F, $DD0D7CC9, $5005713C, $270241AA, $BE0B1010,
    $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F,
    $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4, $59B33D17,
    $2EB40D81, $B7BD5C3B, $C0BA6CAD, $EDB88320, $9ABFB3B6,
    $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615,
    $73DC1683, $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8,
    $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1, $F00F9344,
    $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB,
    $196C3671, $6E6B06E7, $FED41B76, $89D32BE0, $10DA7A5A,
    $67DD4ACC, $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
    $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252, $D1BB67F1,
    $A6BC5767, $3FB506DD, $48B2364B, $D80D2BDA, $AF0A1B4C,
    $36034AF6, $41047A60, $DF60EFC3, $A867DF55, $316E8EEF,
    $4669BE79, $CB61B38C, $BC66831A, $256FD2A0, $5268E236,
    $CC0C7795, $BB0B4703, $220216B9, $5505262F, $C5BA3BBE,
    $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31,
    $2CD99E8B, $5BDEAE1D, $9B64C2B0, $EC63F226, $756AA39C,
    $026D930A, $9C0906A9, $EB0E363F, $72076785, $05005713,
    $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B,
    $E5D5BE0D, $7CDCEFB7, $0BDBDF21, $86D3D2D4, $F1D4E242,
    $68DDB3F8, $1FDA836E, $81BE16CD, $F6B9265B, $6FB077E1,
    $18B74777, $88085AE6, $FF0F6A70, $66063BCA, $11010B5C,
    $8F659EFF, $F862AE69, $616BFFD3, $166CCF45, $A00AE278,
    $D70DD2EE, $4E048354, $3903B3C2, $A7672661, $D06016F7,
    $4969474D, $3E6E77DB, $AED16A4A, $D9D65ADC, $40DF0B66,
    $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
    $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6, $BAD03605,
    $CDD70693, $54DE5729, $23D967BF, $B3667A2E, $C4614AB8,
    $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B,
    $2D02EF8D);

function get_crc_table: puLong;
begin
  get_crc_table := puLong(@crc_table);
end;

function crc32(crc: uLong; buf: pBytef; len: uInt): uLong;
begin
  if (buf = Z_NULL) then
    crc32 := Long(0)
  else begin
    crc := crc xor uLong($FFFFFFFF);
    while (len >= 8) do begin
      crc := crc_table[(int(crc) xor buf^) and $FF] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(int(crc) xor buf^) and $FF] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(int(crc) xor buf^) and $FF] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(int(crc) xor buf^) and $FF] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(int(crc) xor buf^) and $FF] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(int(crc) xor buf^) and $FF] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(int(crc) xor buf^) and $FF] xor (crc shr 8);
      inc(buf);
      crc := crc_table[(int(crc) xor buf^) and $FF] xor (crc shr 8);
      inc(buf);
      Dec(len, 8);
    end;
    if (len <> 0) then
      repeat
        crc := crc_table[(int(crc) xor buf^) and $FF] xor (crc shr 8);
        inc(buf);
        Dec(len);
      until (len = 0);
    crc32 := crc xor uLong($FFFFFFFF);
  end;
end;

{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}
{-----------------------------------------------------------------------------}

{ inflate.c -- zlib interface to inflate modules
  Copyright (C) 1995-1998 Mark Adler

  zinflate.pas -- pascal translation
  Copyright (C) 1998 by Jacques Nomssi Nzali
}

function inflateReset(var z: z_stream): int;
begin
  if (z.state = Z_NULL) then begin
    inflateReset := Z_STREAM_ERROR;
    exit;
  end;
  z.total_out := 0;
  z.total_in := 0;
  z.msg := '';
  if z.state^.nowrap then
    z.state^.mode := BLOCKS
  else
    z.state^.mode := METHOD;
  inflate_blocks_reset(z.state^.blocks^, z, Z_NULL);
  inflateReset := Z_OK;
end;

function inflateEnd(var z: z_stream): int;
begin
  if (z.state = Z_NULL) or not Assigned(z.zfree) then begin
    inflateEnd := Z_STREAM_ERROR;
    exit;
  end;
  if (z.state^.blocks <> Z_NULL) then inflate_blocks_free(z.state^.blocks, z);
  ZFREE(z, z.state);
  z.state := Z_NULL;
  inflateEnd := Z_OK;
end;

function inflateInit2_(var z: z_stream;
  w: int; const version: string; stream_size: int): int;
begin
{
  if (version = '') or (version[1] <> ZLIB_VERSION[1]) or
    (stream_size <> sizeof(z_stream)) then begin
    inflateInit2_ := Z_VERSION_ERROR;
    exit;
  end;
}
  z.msg := '';
  if not Assigned(z.zalloc) then begin
    z.zalloc := zcalloc;
    z.opaque := voidpf(0);
  end;
  if not Assigned(z.zfree) then z.zfree := zcfree;
  z.state := pInternal_state(ZALLOC(z, 1, sizeof(internal_state)));
  if (z.state = Z_NULL) then begin
    inflateInit2_ := Z_MEM_ERROR;
    exit;
  end;
  z.state^.blocks := Z_NULL;
  z.state^.nowrap := FALSE;
  if (w < 0) then begin
    w := -w;
    z.state^.nowrap := TRUE;
  end;
  if (w < 8) or (w > 15) then begin
    inflateEnd(z);
    inflateInit2_ := Z_STREAM_ERROR;
    exit;
  end;
  z.state^.wbits := uInt(w);
  if z.state^.nowrap then
    z.state^.blocks := inflate_blocks_new(z, nil, uInt(1) shl w)
  else
    z.state^.blocks := inflate_blocks_new(z, adler32, uInt(1) shl w);
  if (z.state^.blocks = Z_NULL) then begin
    inflateEnd(z);
    inflateInit2_ := Z_MEM_ERROR;
    exit;
  end;
  inflateReset(z);
  inflateInit2_ := Z_OK;
end;

function inflateInit2(var z: z_stream; windowBits: int): int;
begin
  inflateInit2 := inflateInit2_(z, windowBits, ZLIB_VERSION, sizeof(z_stream));
end;

function inflateInit(var z: z_stream): int;
begin
  inflateInit := inflateInit2_(z, DEF_WBITS, ZLIB_VERSION, sizeof(z_stream));
end;

function inflateInit_(z: z_streamp; const version: string; stream_size: int): int;
begin
  if (z = Z_NULL) then
    inflateInit_ := Z_STREAM_ERROR
  else
    inflateInit_ := inflateInit2_(z^, DEF_WBITS, version, stream_size);
end;

function inflate(var z: z_stream; f: int): int;
var
  r: int;
  b: uInt;
begin
  if (z.state = Z_NULL) or (z.next_in = Z_NULL) then begin
    inflate := Z_STREAM_ERROR;
    exit;
  end;
  if f = Z_FINISH then
    f := Z_BUF_ERROR
  else
    f := Z_OK;
  r := Z_BUF_ERROR;
  while True do
    case (z.state^.mode) of
      BLOCKS:
        begin
          r := inflate_blocks(z.state^.blocks^, z, r);
          if (r = Z_DATA_ERROR) then begin
            z.state^.mode := BAD;
            z.state^.sub.marker := 0;
            continue;
          end;
          if (r = Z_OK) then
            r := f;
          if (r <> Z_STREAM_END) then begin
            inflate := r;
            exit;
          end;
          r := f;
          inflate_blocks_reset(z.state^.blocks^, z, @z.state^.sub.check.was);
          if (z.state^.nowrap) then begin
            z.state^.mode := DONE;
            continue;
          end;
          z.state^.mode := CHECK4;
        end;
      CHECK4:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          r := f;
          Dec(z.avail_in);
          Inc(z.total_in);
          z.state^.sub.check.need := uLong(z.next_in^) shl 24;
          Inc(z.next_in);
          z.state^.mode := CHECK3;
        end;
      CHECK3:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          r := f;
          Dec(z.avail_in);
          Inc(z.total_in);
          Inc(z.state^.sub.check.need, uLong(z.next_in^) shl 16);
          Inc(z.next_in);
          z.state^.mode := CHECK2;
        end;
      CHECK2:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          r := f;
          Dec(z.avail_in);
          Inc(z.total_in);
          Inc(z.state^.sub.check.need, uLong(z.next_in^) shl 8);
          Inc(z.next_in);
          z.state^.mode := CHECK1;
        end;
      CHECK1:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          r := f;
          Dec(z.avail_in);
          Inc(z.total_in);
          Inc(z.state^.sub.check.need, uLong(z.next_in^));
          Inc(z.next_in);
          if (z.state^.sub.check.was <> z.state^.sub.check.need) then begin
            z.state^.mode := BAD;
            z.msg := 'incorrect data check';
            z.state^.sub.marker := 5;
            continue;
          end;
          z.state^.mode := DONE;
        end;
      DONE:
        begin
          inflate := Z_STREAM_END;
          exit;
        end;
      METHOD:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          r := f;
          Dec(z.avail_in);
          Inc(z.total_in);
          z.state^.sub.method := z.next_in^;
          Inc(z.next_in);
          if ((z.state^.sub.method and $0F) <> Z_DEFLATED) then begin
            z.state^.mode := BAD;
            z.msg := 'unknown compression method';
            z.state^.sub.marker := 5;
            continue;
          end;
          if ((z.state^.sub.method shr 4) + 8 > z.state^.wbits) then begin
            z.state^.mode := BAD;
            z.msg := 'invalid window size';
            z.state^.sub.marker := 5;
            continue;
          end;
          z.state^.mode := FLAG;
        end;
      FLAG:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          r := f;
          Dec(z.avail_in);
          Inc(z.total_in);
          b := z.next_in^;
          Inc(z.next_in);
          if (((z.state^.sub.method shl 8) + b) mod 31) <> 0 then begin
            z.state^.mode := BAD;
            z.msg := 'incorrect header check';
            z.state^.sub.marker := 5;
            continue;
          end;
          if ((b and PRESET_DICT) = 0) then begin
            z.state^.mode := BLOCKS;
            continue;
          end;
          z.state^.mode := DICT4;
        end;
      DICT4:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          r := f;
          Dec(z.avail_in);
          Inc(z.total_in);
          z.state^.sub.check.need := uLong(z.next_in^) shl 24;
          Inc(z.next_in);
          z.state^.mode := DICT3;
        end;
      DICT3:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          r := f;
          Dec(z.avail_in);
          Inc(z.total_in);
          Inc(z.state^.sub.check.need, uLong(z.next_in^) shl 16);
          Inc(z.next_in);
          z.state^.mode := DICT2;
        end;
      DICT2:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          r := f;
          Dec(z.avail_in);
          Inc(z.total_in);
          Inc(z.state^.sub.check.need, uLong(z.next_in^) shl 8);
          Inc(z.next_in);
          z.state^.mode := DICT1;
        end;
      DICT1:
        begin
          if (z.avail_in = 0) then begin
            inflate := r;
            exit;
          end;
          Dec(z.avail_in);
          Inc(z.total_in);
          Inc(z.state^.sub.check.need, uLong(z.next_in^));
          Inc(z.next_in);
          z.adler := z.state^.sub.check.need;
          z.state^.mode := DICT0;
          inflate := Z_NEED_DICT;
          exit;
        end;
      DICT0:
        begin
          z.state^.mode := BAD;
          z.msg := 'need dictionary';
          z.state^.sub.marker := 0;
          inflate := Z_STREAM_ERROR;
          exit;
        end;
      BAD:
        begin
          inflate := Z_DATA_ERROR;
          exit;
        end;
    else
      begin
        inflate := Z_STREAM_ERROR;
        exit;
      end;
    end;
end;

function inflateSetDictionary(var z: z_stream;
  dictionary: pBytef; dictLength: uInt): int;
var
  length: uInt;
begin
  length := dictLength;
  if (z.state = Z_NULL) or (z.state^.mode <> DICT0) then begin
    inflateSetDictionary := Z_STREAM_ERROR;
    exit;
  end;
  if (adler32(Long(1), dictionary, dictLength) <> z.adler) then begin
    inflateSetDictionary := Z_DATA_ERROR;
    exit;
  end;
  z.adler := Long(1);
  if (length >= (uInt(1) shl z.state^.wbits)) then begin
    length := (1 shl z.state^.wbits) - 1;
    Inc(dictionary, dictLength - length);
  end;
  inflate_set_dictionary(z.state^.blocks^, dictionary^, length);
  z.state^.mode := BLOCKS;
  inflateSetDictionary := Z_OK;
end;

function inflateSync(var z: z_stream): int;
const
  mark: packed array[0..3] of byte = (0, 0, $FF, $FF);
var
  n: uInt;
  p: pBytef;
  m: uInt;
  r, w: uLong;
begin
  if (z.state = Z_NULL) then begin
    inflateSync := Z_STREAM_ERROR;
    exit;
  end;
  if (z.state^.mode <> BAD) then begin
    z.state^.mode := BAD;
    z.state^.sub.marker := 0;
  end;
  n := z.avail_in;
  if (n = 0) then begin
    inflateSync := Z_BUF_ERROR;
    exit;
  end;
  p := z.next_in;
  m := z.state^.sub.marker;
  while (n <> 0) and (m < 4) do begin
    if (p^ = mark[m]) then
      Inc(m)
    else if (p^ <> 0) then
      m := 0
    else
      m := 4 - m;
    Inc(p);
    Dec(n);
  end;
  Inc(z.total_in, ptr2int(p) - ptr2int(z.next_in));
  z.next_in := p;
  z.avail_in := n;
  z.state^.sub.marker := m;
  if (m <> 4) then begin
    inflateSync := Z_DATA_ERROR;
    exit;
  end;
  r := z.total_in;
  w := z.total_out;
  inflateReset(z);
  z.total_in := r;
  z.total_out := w;
  z.state^.mode := BLOCKS;
  inflateSync := Z_OK;
end;

function inflateSyncPoint(var z: z_stream): int;
begin
  if (z.state = Z_NULL) or (z.state^.blocks = Z_NULL) then begin
    inflateSyncPoint := Z_STREAM_ERROR;
    exit;
  end;
  inflateSyncPoint := inflate_blocks_sync_point(z.state^.blocks^);
end;



{----------------------------------------------------------}
{ The CompressBuf and DecompressBuf routines that were     }
{ shipped with Delphi 3-5 are based on zlib 1.0.4 and are  }
{ not compatible with zlib 1.1.2. The following are        }
{ rewritten versions of CompressBuf and DecompressBuf that }
{ take into account the differences between zlib 1.0.4 and }
{ 1.1.2. Testing has shown this version is significantly   }
{ faster than the zlib code distributed with Delphi 5.     }
{                                                          }
{ Copyright (c) 1997 Borland International                 }
{ Copyright (c) 2000-2001 David O. Martin                  }
{----------------------------------------------------------}

procedure ZLIBCompressBuf(
  const inBuf: Pointer;     { input: pointer to source data }
        inBytes: Integer;   { input: # of bytes in inBuf }
    var outBuf: Pointer;    { output: pointer to newly allocated buffer with compressed data }
    var outBytes: Integer;
  const level: Integer     { input: compression level }
    ); { output: # of bytes in outBuf }
{ This routine compresses data. Level may vary from 0 to 9 (3 to 6 may
  be a reasonable trade-off between speed and compression).

  Compression levels:
    0 = no compression                 (Z_NO_COMPRESSION constant)
    1 = best speed                     (Z_BEST_SPEED constant)
    9 = best compression, but slowest  (Z_BEST_COMPRESSION constant) }

  function Check(code: Integer): Integer;
  begin
    Result := code;
    if (code < 0) then
      raise Exception.Create('Compression error: '+z_errmsg[2-code]);
  end;

var
  strm: z_stream;
begin
  FillChar(strm, sizeof(strm), 0);
  outBytes := ((inBytes + (inBytes div 10) + 12) + 255) and not 255;
  GetMem(outBuf, outBytes);
  try
    strm.next_in := inBuf;
    strm.avail_in := inBytes;
    strm.next_out := outBuf;
    strm.avail_out := outBytes;
    Check(deflateInit(strm, level));
    try
      while Check(deflate(strm, Z_FINISH)) <> Z_STREAM_END do begin
        Inc(outBytes, 256);
        ReallocMem(outBuf, outBytes);
        strm.next_out := pBytef(Integer(outBuf) + strm.total_out);
        strm.avail_out := 256;
      end;
    finally
      Check(deflateEnd(strm));
    end;
    ReallocMem(outBuf, strm.total_out);
    outBytes := strm.total_out;
  except
    DeAllocMem(outBuf);
    raise;
  end;
end;

procedure ZLIBDecompressBuf(
  const inBuf: Pointer;     { input: pointer to compressed data }
        inBytes: Integer;   { input: # of bytes in inBuf }
    OutEstimate: Integer; // not needed
    var outBuf: Pointer;    { output: pointer to newly allocated buffer with decompressed data }
    var outBytes: Integer); { output: # of bytes in outBuf }
{ This routine decompresses data that was compressed with CompressBuf. }

  function Check(code: Integer): Integer;
  begin
    Result := code;
    if (code < 0) then
      raise Exception.Create('Decompression error: '+z_errmsg[2-code]);
  end;

var
  strm: z_stream;
  bufInc: Integer;
begin
  FillChar(strm, sizeof(strm), 0);
  bufInc := (inBytes + 255) and not 255;
  outBytes := bufInc;
  GetMem(outBuf, outBytes);
  try
    strm.next_in := inBuf;
    strm.avail_in := inBytes;
    strm.next_out := outBuf;
    strm.avail_out := outBytes;
    Check(inflateInit(strm));
    try
      while Check(inflate(strm, Z_NO_FLUSH)) <> Z_STREAM_END do begin
        Inc(outBytes, bufInc);
        ReallocMem(outBuf, outBytes);
        strm.next_out := pBytef(Integer(outBuf) + strm.total_out);
        strm.avail_out := bufInc;
      end;
    finally
      Check(inflateEnd(strm));
    end;
    ReallocMem(outBuf, strm.total_out);
    outBytes := strm.total_out;
  except
    DeAllocMem(outBuf);
    raise;
  end;
end;
end.
