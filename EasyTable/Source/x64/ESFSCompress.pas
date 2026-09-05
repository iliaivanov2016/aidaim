//==============================================================================
// Product name: ESingleFileSystem
// Unit ESFSCompress - compression routines on the basis of the ECL 1.1
// Copyright 2001 AidAim Software.
// Description:
//  Single file system.
// Version: 1.10
// Date: 11/30/2001
//==============================================================================
// ECL Supports 10 levels of compression:
//    - eclNone - no compression, data stores in its original form
//    - zlibFastest - ZLIB version 1.1.3, Mode 1, RAM = 64Kb
//    - zlibNormal - ZLIB version 1.1.3, Mode 5, RAM = 64Kb
//    - zlibMax - ZLIB version 1.1.3, Mode 9, RAM = 64Kb
//    - ppmFastest - PPMD v. G, MO = 3, RAM = 10 Mb
//    - ppmNormal - PPMD v. G, MO = 5, RAM = 25 Mb
//    - ppmMax - PPMD v. G, MO = 16, RAM = 50 Mb
//    - bzipFastest - BZIP 0.9.5d, Mode 2, RAM = 1,5 Mb
//    - bzipNormal - ZLIB 0.9.5d, Mode 6, RAM =  4,8 Mb
//    - bzipMax - ZLIB 0.9.5d, Mode 9, RAM = 7,2 Mb

// Note: all Fastest modes works with block sizes specified by BlockSizeForFastest
// Note: all Normal modes works with block sizes specified by BlockSizeForNormal
// Note: all Max modes works with block sizes specified by BlockSizeForMax


// ZLIB library (ZIP Deflate algorithm) provides these levels:
//    - zlibFastest - ZLIB version 1.1.3, Mode 1, RAM = 64Kb
//    - zlibNormal - ZLIB version 1.1.3, Mode 5, RAM = 64Kb
//    - zlibMax - ZLIB version 1.1.3, Mode 9, RAM = 64Kb
// Very fast compression / decompression, low compression rate

{*******************************************************}
{                                                       }
{       Borland Delphi Supplemental Components          }
{       ZLIB Data Compression Interface Unit            }
{                                                       }
{       Copyright (c) 1997,99 Inprise Corporation       }
{                                                       }
{*******************************************************}
{ ZLib 1.1.3 source files http://www.info-zip.org/pub/infozip/zlib }

{ Modified for zlib 1.1.3 by Davide Moretti <dave@rimini.com }
{                                                            }
{ (09/20/99) Ryan Mills. <rmills@freenet.edmonton.ab.ca>     }
{ Further modified to be more compatible with the D5 version }
{ of the ZLIB component, integrating the speed enhancements  }
{ introduced by Borland.                                     }


// PPM algorithm (PPMD vasant G) provides next levels:
//    - ppmFastest - PPMD v. G, MO = 3, RAM = 10 Mb
//    - ppmNormal - PPMD v. G, MO = 5, RAM = 20 Mb
//    - ppmMax - PPMD v. G, MO = 16, RAM = 50 Mb
// slow compression / decompression, maximum compression rate
// provides best compression on texts and bitmaps.


//	PPMD algorithm by Dmitry Shkarin,
//      E-mail: shkarin@arstel.ru,
//      variant G,

// BZIP algorithm (BZIP is not compatible with ZIP) provides next levels:
//    - bzipFastest - BZIP 0.9.5d, Mode 2, RAM = 1,5 Mb
//    - bzipNormal - ZLIB 0.9.5d, Mode 6, RAM =  4,8 Mb
//    - bzipMax - ZLIB 0.9.5d, Mode 9, RAM = 7,2 Mb
// average compression speed / decompression much faster
// compression rate much better then ZLIb (ZIP) 
// better compression rate then PPM only on high-resolution photos
// text compression rate lower then PPM


// AUTHOR
// Julian Seward, jseward@acm.org.


// http://sourceware.cygnus.com/bzip2
// http://www.muraroa.demon.co.uk

// BZip2 unit by Edison Mera
// Version 1.01
// Edition 04-01-2000
// e-mail: edmera@yahoo.com
// web page:
// http://www.geocities.com/SiliconValley/Grid/3690/


unit ESFSCompress;

{$I ESFSVer.inc}

{$DEFINE ZLIB}
{$IFNDEF PPMDI}
 {$DEFINE PPMD}
{$ENDIF}
{$DEFINE BZIP}

{$IFNDEF ZLIB}
{$IFNDEF PPMD}
{$IFNDEF BZIP}
	WARNING! You have switched off all compression algorithms!
  If you do not need them, comment these strings and continue.
{$ENDIF}
{$ENDIF}
{$ENDIF}

interface

uses Sysutils, Classes,ESFSEngine
{$IFDEF ZLIB}
 {$IFDEF X64_ON}
 ,ESFSZlib_64
 {$ELSE}
 ,ESFSZlib
 {$ENDIF}
{$ENDIF}
{$IFDEF BZIP}
 {$IFDEF X64_ON}
 ,ESFSBZip2_64
 {$ELSE}
 ,ESFSBZip2
 {$ENDIF}
{$ENDIF}
{$IFDEF PPMDI}
,ESFSppmdi
{$ENDIF}
;


type
 TESFSCompressionLevel1 = (esfsNone, zlibFastest, zlibNormal, ppmNormal, ppmMax,
                         zlibMax, ppmFastest, bzipFastest, bzipNormal, bzipMax
{$IFDEF PPMDI}
,ppmiFastest,ppmiNormal,ppmiMax
{$ENDIF}
);

const
 PPM_MO: array [1..9] of Byte = (2,3,4, 5, 7, 8,10, 13, 16); // Model Order
 PPM_SA: array [1..9] of Byte = (2,3,7,16,30,30,45,100,100); // MBytes RAM

// compresses buffer
// returns true if successful
// outBuf - pointer to compressed data
// outSize - size of compressed data
function ESFSInternalCompressBuffer(inBuf  : PAnsiChar;
                          inSize : Integer;
                          out outBuf : PAnsiChar;
                          out outSize    : Integer;
                          compressionLevel : TESFSCompressionLevel1 = zlibFastest) : Boolean;

// decompresses buffer
// outSize should be set to estimated size or more(for allocating memory)
// returns true if successful
// outBuf - pointer to decompressed data
// outSize - size of decompressed data
function ESFSInternalDecompressBuffer(inBuf  : PAnsiChar;
                            inSize : Integer;
                            out outBuf : PAnsiChar;
                            out outSize: Integer;
                            compressionLevel : TESFSCompressionLevel1 = zlibFastest) : Boolean;

// determines best block size for compression level
function ESFSInternalGetBlockSize(compressionLevel: TESFSCompressionLevel1): Integer;

implementation

{$IFDEF PPMD}
{$L Ppmd.OBJ}
function PPMCompressBuffer(inBuf  : PAnsiChar;
                           inSize : Cardinal;
                           outBuf : PAnsiChar;
										       Max_Order:integer = 6;
                           SASize:integer = 10
                          ) : Cardinal; external;

function PPMDecompressBuffer(
                            inBuf  : PAnsiChar;
                            inSize : Cardinal;
                            outBuf : pAnsiChar
                            ) : Cardinal; external;
{$ENDIF}


//------------------------------------------------------------------------------
// compresses buffer
// returns true if successful
// outBuf - pointer to compressed data
// outSize - size of compressed data
//------------------------------------------------------------------------------
function ESFSInternalCompressBuffer(inBuf  : PAnsiChar;
                          inSize : Integer;
                          out outBuf : PAnsiChar;
                          out outSize    : Integer;
                          compressionLevel : TESFSCompressionLevel1 = zlibFastest) : Boolean;
var mo,sa,osz: Cardinal;
   CompressionMode: Byte;
begin
 result := false;
 if inSize = 0 then Exit;
 result := true;
 outSize := 0;
 case compressionLevel of
  esfsNone :
    begin
     try
      outSize := inSize;
      outBuf := AllocMem(outSize);
      Move (inbuf^,outBuf^,inSize);
     except
      result := false;
     end;
    end
{$IFDEF ZLIB}
;
  zlibFastest,zlibNormal,zlibMax:
   begin
    try
     if (compressionLevel = zlibFastest) then
	     ZLIBCompressBuf(InBuf,InSize,Outbuf,Integer(OutSize),1)
     else
     if (compressionLevel = zlibNormal) then
	     ZLIBCompressBuf(InBuf,InSize,Outbuf,Integer(OutSize),5)
     else
	     ZLIBCompressBuf(InBuf,InSize,Outbuf,Integer(OutSize),9);
    except
     result := false;
    end;
    if (outSize <= 0) then
     result := false;
   end
{$ENDIF}
{$IFDEF PPMD}
;
  ppmFastest,ppmNormal,ppmMax:
   begin
    try
     // some memory reserve for none-compressible data
     outSize := inSize + inSize div 20 + 50;
     outBuf := AllocMem(outSize);
     // setup variables
     if (compressionLevel = ppmFastest) then
      begin
       mo := PPM_FASTEST_MO;  // model order
       sa := PPM_FASTEST_SA; // size of the dictionary in MB
      end
     else
     if (compressionLevel = ppmNormal) then
      begin
       mo := PPM_NORMAL_MO;  // model order
       sa := PPM_NORMAL_SA; // size of the dictionary in MB
      end
     else
      begin
       mo := PPM_MAX_MO;  // model order
       sa := PPM_MAX_SA; // size of the dictionary in MB
      end;
     outSize := PPMCompressBuffer(inBuf,inSize,outBuf,mo,sa);
    except
     result := false;
    end;
    if (outSize <= 0) then
     result := false;
   end
{$ENDIF}
{$IFDEF PPMDI}
;
  ppmiFastest,ppmiNormal,ppmiMax:
   begin
    try
     // some memory reserve for none-compressible data
    if (compressionLevel = ppmiFastest) then
      CompressionMode:=0
    else
    if (compressionLevel = ppmiNormal) then
      CompressionMode:=5
     else
      CompressionMode:=9;
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
{$IFDEF BZIP}
;
  bzipMax,bzipNormal,bzipFastest:
   begin
    try
     if (compressionLevel = bzipFastest) then
      bzCompressBuf(InBuf,InSize,Outbuf,Integer(OutSize),2)
     else
     if (compressionLevel = bzipNormal) then
      bzCompressBuf(InBuf,InSize,Outbuf,Integer(OutSize),6)
     else
     if (compressionLevel = bzipMax) then
      bzCompressBuf(InBuf,InSize,Outbuf,Integer(OutSize),9);
    except
     result := false;
    end;
    if (outSize <= 0) then
     result := false;
   end
{$ENDIF}
  else
   result := false;
 end; //case compressionLevel
end; // ECLInternalCompressBuffer;


//------------------------------------------------------------------------------
// decompresses buffer
// outSize should be set to estimated size or more(for allocating memory)
// returns true if successful
// outBuf - pointer to decompressed data
// outSize - size of decompressed data
//------------------------------------------------------------------------------
function ESFSInternalDecompressBuffer(inBuf  : PAnsiChar;
                            inSize : Integer;
                            out outBuf : PAnsiChar;
                            out outSize: Integer;
                            compressionLevel : TESFSCompressionLevel1 = zlibFastest) : Boolean;
{$IFDEF ZLIB}
var si: Integer;
{$ENDIF}
var osz: Cardinal;
begin
 result := false;
 if outSize <= 0 then Exit;
 result := true;
 case compressionLevel of
  esfsNone :
    begin
     try
      outSize := inSize;
      outBuf := AllocMem(outSize);
      Move (inbuf^,outBuf^,inSize);
     except
      result := false;
     end;
    end
{$IFDEF ZLIB}
;
  zlibFastest,zlibNormal,zlibMax:
   begin
    try
     si := OutSize;
     ZLIBDecompressBuf(InBuf,InSize,OutSize,Outbuf,OutSize);
    except
     result := false;
    end;
    if (outSize = 0) then
     result := false;
   end
{$ENDIF}
{$IFDEF PPMD}
;
  ppmFastest,ppmNormal,ppmMax:
   begin
    try
     outBuf := AllocMem(outSize);
     outSize := PPMDecompressBuffer(inBuf,inSize,outBuf);
    except
     result := false;
    end;
    if (outSize <= 0) then
     result := false;
   end
{$ENDIF}
{$IFDEF PPMDI}
;
  ppmiFastest,ppmiNormal,ppmiMax:
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
{$IFDEF BZIP}
;
  bzipFastest,bzipNormal,bzipMax:
   begin
    try
      si := OutSize;
      bzDecompressBuf(InBuf,InSize,OutSize,Outbuf,OutSize);
    except
     result := false;
    end;
    if (outSize <= 0) then
     result := false;
   end
{$ENDIF}
  else
   result := false;
 end; //case compressionLevel
end; // ffsDeompressBuffer;



//------------------------------------------------------------------------------
// determines best block size for compression level
//------------------------------------------------------------------------------
function ESFSInternalGetBlockSize(compressionLevel: TESFSCompressionLevel1): Integer;
begin
 case compressionLevel of
  zlibFastest,ppmFastest,bzipFastest: result := BlockSizeForFastest;
  zlibNormal,ppmNormal,bzipNormal: result := BlockSizeForNormal;
  zlibMax,ppmMax,bzipMax: result := BlockSizeForMax
  else
   result := DefaultMaxBlockSize;
 end;
end;


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

end.





