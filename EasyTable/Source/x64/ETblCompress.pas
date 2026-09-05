//==============================================================================
//
//              Easy compression routines
//
//             Copyright 2000-2001 AidAim Software.
//
//==============================================================================

{$I ETblVer.inc}

unit ETblCompress;

interface
uses sysutils, EasyTable
{$IFDEF X64_ON}
,ESFSZlib_64
{$ELSE}
, ETblZLIB
{$ENDIF}
;

function aaCompressBuffer(inBuf  : PAnsiChar;
                          inSize : Integer;
                          out outBuf : PAnsiChar;
                          out outSize    : Integer;
                          compressionLevel : TCompressionLevel = clFastest) : Boolean;

function aaDecompressBuffer(inBuf  : PAnsiChar;
                            inSize : Integer;
                            out outBuf : PAnsiChar;
                            out outSize    : Integer;
                            compressionLevel : TCompressionLevel = clFastest) : Boolean;

{$IFNDEF X64_ON}
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

implementation
//------------------------------------------------------------------------------
// compresses buffer
// returns true if successful
// outBuf - pointer to compressed data
// outSize - size of compressed data
//------------------------------------------------------------------------------
function aaCompressBuffer(inBuf  : PAnsiChar;
                          inSize : Integer;
                          out outBuf : PAnsiChar;
                          out outSize    : Integer;
                          compressionLevel : TCompressionLevel = clFastest) : Boolean;
var si,so,count,blockSize : Integer;
    mo,sa : integer;
begin
 if (inBuf = nil) then
  raise Exception.Create('aaCompressBuffer - inBuf = nil');
 result := true;
 outSize := 0;
 case compressionLevel of
  clNone :
    begin
     try
      Move (inbuf^,outBuf,inSize);
      outSize := inSize;
     except
      result := false;
     end;
    end;
  clFastest :
   begin
    try
{
     outSize := inSize + inSize div 64 + 16 + 3;
     outBuf := AllocMem(outSize);
     outSize := LZOCompressBuffer(inBuf,Cardinal(inSize),outBuf);
}
     {$IFDEF X64_ON}
     ZLIBCompressBuf(inbuf,insize,outbuf,outsize,1);
     {$ELSE}
     ZLIBCompressBuf(inbuf,insize,Pointer(outbuf),outsize,1);
     {$ENDIF}
    except
     result := false;
    end;
    if (outSize <= 0) then
     result := false;
   end;
  clDefault,clMax :
   begin
    try
{$IFDEF X64_ON}
    if (compressionLevel = clDefault) then
     ZLIBCompressBuf(inbuf,insize,outbuf,outsize,6)
    else
     ZLIBCompressBuf(inbuf,insize,outbuf,outsize,9);
{$ELSE}

     // some memory reserve for not-compressible data
     outSize := inSize + inSize div 20 + 50;
     outBuf := AllocMem(outSize);
     // setup variables
     if (compressionLevel = clDefault) then
      begin
       blockSize := 800*1024; // block size in bytes
       mo := 5;  // model order
       sa := 20; // size of the dictionary in MB
      end
     else
      begin
       blockSize := 1600*1024; // block size in bytes
       mo := 16;  // model order
       sa := 50; // size of the dictionary in MB
      end;
     count := 0;
     outSize := 0;
     // compression loop
     while count < inSize do
      begin
       if (inSize - count >= blockSize) then
        si := blockSize
       else
        si := insize - count;
       inc(outSize,sizeof(so));
       so := PPMCompressBuffer(pAnsiChar(inBuf+count),si,pAnsiChar(outBuf+outSize),mo,sa);
       // compressed block size
       Move(so,pAnsiChar(outBuf+outSize - sizeof(so))^,sizeof(so));
       inc(count,si);
       inc(outSize,so);
      end;
{$ENDIF}
    except
     result := false;
    end;
    if (outSize <= 0) then
     result := false;
   end
  else
   result := false;
 end; //case compressionLevel
end; // aaCompressBuffer;


//------------------------------------------------------------------------------
// decompresses buffer
// outSize should be set to estimated size or more(for allocating memory)
// returns true if successful
// outBuf - pointer to decompressed data
// outSize - size of decompressed data
//------------------------------------------------------------------------------
function aaDecompressBuffer(inBuf  : PAnsiChar;
                            inSize : Integer;
                            out outBuf : PAnsiChar;
                            out outSize: Integer;
                            compressionLevel : TCompressionLevel = clFastest) : Boolean;
var si,so,count : Integer;
begin
 result := false;
 if outSize = 0 then Exit;
 result := true;
 case compressionLevel of
  clNone : result := false;
  clFastest :
   begin
    try
     {$IFDEF X64_ON}
     ZLIBDecompressBuf(inbuf,insize,outSize,outbuf,outsize);
     {$ELSE}
     ZLIBDecompressBuf(inbuf,insize,outSize,Pointer(outbuf),outsize);
     {$ENDIF}
    except
     result := false;
    end;
    if (outSize = 0) then
     result := false;
   end;
  clDefault,clMax :
   begin
    try
{$IFDEF X64_ON}
     ZLIBDecompressBuf(inbuf,insize,outSize,outbuf,outsize);
{$ELSE}
     outBuf := AllocMem(outSize);
     count := 0;
     outSize := 0;
     // decompression loop
     while count < inSize do
      begin
       Move(pAnsiChar(inBuf+count)^,si,sizeof(si));
       inc(count,sizeof(si));
       so := PPMDecompressBuffer(pAnsiChar(inBuf+count),si,pAnsiChar(outBuf+outSize));
       inc(count,si);
       inc(outSize,so);
      end;
{$ENDIF}
    except
     result := false;
    end;
    if (outSize <= 0) then
     result := false;
   end;
 end; //case compressionLevel
end; // aaDeompressBuffer;


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

{$IFNDEF X64_ON}

{$L Ppmd.OBJ}

{$ENDIF}

end.










































