unit ACRStrUtils;

interface

{$I ACRVer.Inc}

uses SysUtils
{$IFNDEF D6H}
     ,ACRD4Routines
{$ENDIF}
{$IFDEF MSWINDOWS}
     ,Windows
{$ENDIF}
{$IFDEF LINUX}
     ,Libc
{$ENDIF}
     ;

type                        

  PACRCharTable = ^TACRCharTable;
  TACRCharTable = array[0..255] of AnsiChar;
  PACRByteTable = ^TACRByteTable;
  TACRByteTable = array[0..255] of Byte;

var
  ToUpperChars, ToLowerChars: TACRCharTable;
  OrderedChars: TACRByteTable;


{
  function StrComp(P1, P2: PAnsiChar): Integer; overload;
  function StrComp(P1, P2: PAnsiChar; OrderTable: PACRByteTable): Integer; overload;
  function StrCompL(P1, P2: PAnsiChar; MaxLen: Cardinal): Integer; overload;
  function StrCompL(P1, P2: PAnsiChar; MaxLen: Cardinal; OrderTable: PACRByteTable): Integer; overload;

  function StrIComp(P1, P2: PAnsiChar): Integer; overload;
  function StrIComp(P1, P2: PAnsiChar; OrderTable: PACRByteTable; UpperTable: TACRCharTable): Integer; overload;
  function StrICompL(P1, P2: PAnsiChar; MaxLen: Cardinal): Integer; overload;
  function StrICompL(P1, P2: PAnsiChar; MaxLen: Cardinal; OrderTable: PACRByteTable; UpperTable: TACRCharTable): Integer; overload;
}


(*
  procedure ChangeCaseCustom(Buffer: PAnsiChar; PTable: PACRCharTable); register;
  procedure ToLowerCase(Buffer: PAnsiChar); register;
  procedure ToUpperCase(Buffer: PAnsiChar); register;
*)
  function aaWideUpperCase(const S: WideString): WideString;
  function aaWideLowerCase(const S: WideString): WideString;
  function ACRCompareWideString(const s1,s2: WideString; CaseSensitive: Boolean = False): Integer;

implementation

(*
procedure ChangeCaseCustom(Buffer: PAnsiChar; PTable: PACRCharTable);
asm
        TEST    EAX, EAX                                   // Buffer = nil ?
        JE      @exit
        TEST    EDX, EDX                                   // Table = nil ?
        JE      @exit

@loop:  MOVZX   ECX, BYTE PTR [EAX]
        TEST    CL, CL                                     // End of AnsiString ?
        JE      @exit
        MOV     CL, BYTE PTR [EDX + ECX]
        MOV     BYTE PTR [EAX], CL
        INC     EAX
        JMP     @loop
@exit:
end;



procedure ToLowerCase(Buffer: PAnsiChar);
asm
        TEST    EAX, EAX                                   // Buffer = nil ?
        JE      @exit
@loop:  MOVZX   ECX, BYTE PTR [EAX]
        TEST    CL, CL                                     // End of AnsiString ?
        JE      @exit
        MOV     CL, BYTE PTR [ToLowerChars + ECX]
        MOV     BYTE PTR [EAX], CL
        INC     EAX
        JMP     @loop
@exit:
end;


procedure ToUpperCase(Buffer: PAnsiChar);
asm
        TEST    EAX, EAX                                   // Buffer = nil ?
        JE      @exit
@loop:  MOVZX   ECX, BYTE PTR [EAX]
        TEST    CL, CL                                     // End of AnsiString ?
        JE      @exit
        MOV     CL, BYTE PTR [ToUpperChars + ECX]
        MOV     BYTE PTR [EAX], CL
        INC     EAX
        JMP     @loop
@exit:
end;
*)


procedure InitOrderedChars;
var i,j: Integer;
  a1, a2: array[0..1] of Byte;
  p1, p2: PAnsiChar;
  n: Byte;
begin
  a1[1] := 0;
  a2[1] := 0;
  p1 := @a1;
  p2 := @a2;
  for i:=0 to 255 do
    begin
      n := 0;
      a1[0] := i;
      for j:=0 to 255 do
        begin
          a2[0] := j;
          if (AnsiStrLComp(p1, p2, 1) > 0) then
            Inc(n);
        end;
      OrderedChars[i] := n;
    end;
end;

function aaWideUpperCase(const S: WideString): WideString;
{$IFDEF D6H}
  begin
    Result := WideUpperCase(S);
  end;
{$ELSE}
  {$IFDEF MSWINDOWS}
  var
    Len: Integer;
  begin
    Len := Length(S);
    SetString(Result, PWideChar(S), Len);
    if Len > 0 then CharUpperBuffW(Pointer(Result), Len);
  end;
  {$ENDIF}
{$ENDIF}

function aaWideLowerCase(const S: WideString): WideString;
{$IFDEF D6H}
  begin
    Result := WideLowerCase(S);
  end;
{$ELSE}
  {$IFDEF MSWINDOWS}
  var
    Len: Integer;
  begin
    Len := Length(S);
    SetString(Result, PWideChar(S), Len);
    if Len > 0 then CharLowerBuffW(Pointer(Result), Len);
  end;
  {$ENDIF}
{$ENDIF}


//------------------------------------------------------------------------------
// return 0 if value1 = value2, 1 if value1 > value2, -1 if value1 < value2
//------------------------------------------------------------------------------
function ACRCompareWideString(const s1,s2: WideString; CaseSensitive: Boolean): Integer;
begin
 if (CaseSensitive) then
  Result := WideCompareStr(s1,s2)
 else
  Result := WideCompareText(s1,s2);
end; // ACRCompareWideString


var i: Integer;
initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRSecurity> initialization started');
{$ENDIF}

{$IFDEF MSWINDOWS}
  for i:=0 to 255 do
    ToUpperChars[i] := AnsiChar(chr(i));
  move(ToUpperChars, ToLowerChars, 256);
  CharUpperBuffA(PAnsiChar(@ToUpperChars), 256);
  CharLowerBuffA(PAnsiChar(@ToLowerChars), 256);
{$ENDIF}

{$IFDEF LINUX}
  for i:=0 to 255 do
   begin
    ToUpperChars[i] := AnsiChar(chr(toupper(i)));
    ToLowerChars[i] := AnsiChar(chr(tolower(i)));
   end;
{$ENDIF}

  InitOrderedChars;

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRSecurity> initialization finished');
{$ENDIF}

end.
