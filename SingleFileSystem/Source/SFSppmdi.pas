unit SFSppmdi;

{$I SFSVer.Inc}

{$ifdef FPC}
{$mode objfpc}{$H+}
{$endif}

interface

Uses SFSTypes, SFSCommon;

type

    TAllocFunc = function(Opaque: Pointer; Size: SizeInt): Pointer;
    TFreeFunc = procedure(Opaque: Pointer; Address: Pointer);

    PCoderAlloc = ^TCoderAlloc;
    TCoderAlloc = record
      AllocFunc: TAllocFunc;
      FreeFunc: TFreeFunc;
    end;

    PPpmdStream = ^TPpmdStream;
    TPpmdStream = record
      Buf: PAnsiChar;
      Pos: Cardinal;
      Avail: Cardinal;
      Alloc: TCoderAlloc;
    end;

    {$ifdef WIN32}
      function _PpmdCompress(InStrm: PPpmdStream; OutStrm: PPpmdStream; MaxOrder: Cardinal; SASize: Cardinal): Integer; cdecl;
      function _PpmdDecompress(InStrm: PPpmdStream; OutStrm: PPpmdStream): Integer; cdecl;
    {$else}
      function PpmdCompress(InStrm: PPpmdStream; OutStrm: PPpmdStream; MaxOrder: Cardinal; SASize: Cardinal): Integer; cdecl;
      function PpmdDecompress(InStrm: PPpmdStream; OutStrm: PPpmdStream): Integer; cdecl;
    {$endif}

    function PpmdCompressBuf(const InBuf: PAnsiChar; InSize: Cardinal; out OutBuf: PAnsiChar; out OutSize: Cardinal; MaxOrder: Cardinal = 6; SASize: Cardinal = 10): Integer;
    function PpmdDecompressBuf(const InBuf: PAnsiChar; InSize: Cardinal; out OutBuf: PAnsiChar; out OutSize: Cardinal): Integer;

implementation

const

    StreamStepSize = 102400;
    {$ifdef WIN32}
    _PPMD8_kExpEscape: array[0..15] of Byte = (25, 14, 9, 7, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2);
    {$else}
    PPMD8_kExpEscape: array[0..15] of Byte = (25, 14, 9, 7, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2);
    {$endif}

procedure _Dbg(const msg: PAnsiChar); cdecl;
begin
  WriteLn(msg);
end;

function {$ifdef WIN32}_memset{$else}memset{$endif}(p: Pointer; value: Integer; size: SizeInt): Pointer; cdecl; {$ifdef FPC} [public, alias: 'memset']; {$endif}
begin
     FillChar(p^, size, Byte(value));
     Result := p;
end;

{$include ppmdobjs.inc}

{$ifdef DCC}
  {$ifdef WIN32}
    procedure _Ppmd8_UpdateBin; external;
    procedure _Ppmd8_Update1; external;
    procedure _Ppmd8_Update1_0; external;
    procedure _Ppmd8_Update2; external;
    procedure _Ppmd8_MakeEscFreq; external;
  {$else}
    procedure Ppmd8_UpdateBin; external;
    procedure Ppmd8_Update1; external;
    procedure Ppmd8_Update1_0; external;
    procedure Ppmd8_Update2; external;
    procedure Ppmd8_MakeEscFreq; external;
  {$endif}
{$endif}

{$ifdef WIN32}
  function _PpmdCompress(InStrm: PPpmdStream; OutStrm: PPpmdStream; MaxOrder: Cardinal; SASize: Cardinal): Integer; cdecl; external;
  function _PpmdDecompress(InStrm: PPpmdStream; OutStrm: PPpmdStream): Integer; cdecl; external;
{$else}
  function PpmdCompress(InStrm: PPpmdStream; OutStrm: PPpmdStream; MaxOrder: Cardinal; SASize: Cardinal): Integer; cdecl; external;
  function PpmdDecompress(InStrm: PPpmdStream; OutStrm: PPpmdStream): Integer; cdecl; external;
{$endif}

function {$ifdef WIN32}_ReadStream{$else}ReadStream{$endif}(var Strm: TPpmdStream): Byte; cdecl; {$ifdef FPC} [public, alias: 'ReadStream']; {$endif}
begin
     Result := Byte(Strm.Buf[Strm.Pos]);
     Inc(Strm.Pos); Dec(Strm.Avail);
end;

procedure {$ifdef WIN32}_WriteStream{$else}WriteStream{$endif}(var Strm: TPpmdStream; Val: Byte); cdecl; {$ifdef FPC} [public, alias: 'WriteStream']; {$endif}
begin
     if Strm.Avail = 0 then
     begin
       ReallocMem(Strm.Buf, Strm.Pos + StreamStepSize);
       Strm.Avail := StreamStepSize;
     end;
     {$ifdef FPC}
     Strm.Buf[Strm.Pos] := Char(Val);
     {$else}
     Strm.Buf[Strm.Pos] := AnsiChar(Val);
     {$endif}
     Inc(Strm.Pos); Dec(Strm.Avail);
end;

function PpmdCompressBuf(const InBuf: PAnsiChar; InSize: Cardinal; out OutBuf: PAnsiChar; out OutSize: Cardinal; MaxOrder: Cardinal; SASize: Cardinal): Integer;
var
  InStrm, OutStrm: TPpmdStream;
begin
     InStrm.Buf := InBuf;
     InStrm.Pos := 0;
     InStrm.Avail := InSize;

     OutStrm.Buf := OutBuf;
     OutStrm.Pos := 0;
     OutStrm.Avail := OutSize;
     OutStrm.Alloc.AllocFunc := @SFSAlloc;
     OutStrm.Alloc.FreeFunc := @SFSFree;

     Result := {$ifdef WIN32}_PpmdCompress{$else}PpmdCompress{$endif}(@InStrm, @OutStrm, MaxOrder, SASize);
     ReallocMem(OutStrm.Buf, OutStrm.Pos);
     OutBuf := OutStrm.Buf;
     OutSize := OutStrm.Pos;
end;

function PpmdDecompressBuf(const InBuf: PAnsiChar; InSize: Cardinal; out OutBuf: PAnsiChar; out OutSize: Cardinal): Integer;
var
  InStrm, OutStrm : TPpmdStream;
begin
     InStrm.Buf := InBuf;
     InStrm.Pos := 0;
     InStrm.Avail := InSize;

     OutStrm.Buf := OutBuf;
     OutStrm.Pos := 0;
     OutStrm.Avail := OutSize;
     OutStrm.Alloc.AllocFunc := @SFSAlloc;
     OutStrm.Alloc.FreeFunc := @SFSFree;

     Result := {$ifdef WIN32}_PpmdDecompress{$else}PpmdDecompress{$endif}(@InStrm, @OutStrm);
     ReallocMem(OutStrm.Buf, OutStrm.Pos);
     OutBuf := OutStrm.Buf;
     OutSize := OutStrm.Pos;
end;



end.

