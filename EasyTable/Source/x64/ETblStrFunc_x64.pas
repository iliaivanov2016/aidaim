/////////////////////////////////////////////////////
//                                                 //
//   QStrings 6.03.420      ( general release )    //
//                                                 //
//   Quick AnsiString manipulation library             //
//                                                 //
//   Copyright (C) 2000,2001 Andrew N. Driazgov    //
//   e-mail: andrey@asp.tstu.ru                    //
//                                                 //
//   Portions (C) 2000, Sergey G. Shcherbakov      //
//   e-mail: mover@mail.ru, mover@rada.gov.ua      //
//                                                 //
//   Last updated: January 7, 2001                 //
//                                                 //
/////////////////////////////////////////////////////

//-----------------------------------------------------//
//                                                     //
//  Modified by AidAim Software, 2002-2012                  //
//                                                     //
//-----------------------------------------------------//
{$I ETblVer.inc}

unit ETblStrFunc_x64;

interface

uses Windows, SysUtils;

const WildCardMultipleChar = '%';
const WildCardSingleChar = '_';

function IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean): Boolean;
function IsWideStrMatchPattern(StrPtr: PWideChar; PatternPtr: PWideChar; bIgnoreCase:boolean): Boolean;

function Q_AnsiPCompStr(P1, P2: PAnsiChar): Integer;
function Q_AnsiCompStrL(P1, P2: PAnsiChar; MaxL: Cardinal): Integer;
function Q_AnsiPCompText(P1, P2: PAnsiChar): Integer;
function Q_AnsiCompTextL(P1, P2: PAnsiChar; MaxL: Cardinal): Integer;

function Q_PCompStr(P1, P2: PAnsiChar): Integer;
function Q_CompStrL(const S1, S2: AnsiString; MaxL: Cardinal): Integer;
function Q_PCompText(P1, P2: PAnsiChar): Integer;
function Q_CompTextL(const S1, S2: AnsiString; MaxL: Cardinal): Integer;

function Q_PStrToAnsi(P: PAnsiChar): PAnsiChar;
function Q_PStrToOem(P: PAnsiChar): PAnsiChar;


var
  ToUpperChars,ToLowerChars: array[0..255] of AnsiChar;
  ToOemChars,ToAnsiChars: array[0..255] of AnsiChar;
//--- Turkish support ---
  TurkishToAnsiChars: array [0..255] of AnsiChar=
  (#0,#2,#3,#4,#5,#6,#7,#8,#9,#10,#11,#12,#13,#14,#15,
   #16,#17,#18,#19,#20,#21,#22,#23,#24,#25,#26,#27,#28,#29,#30,#31,
   #32,#1,#33,#34,#35,#36,#37,#38,#39,#40,#41,#42,#43,#44,#45,#46,#47,
   #48,#49,#50,#51,#52,#53,#54,#55,#56,#57,#58,#59,#60,#61,#62,#63,#64,
   #72,#82,#84,#88,#94,#100,#102,#106,#112,#120,#122,#124,#126,#129,
   #136,#144,#146,#148,#150,#155,#160,#167,#169,#171,#174,#176,#177,
   #178,#179,#180,#181,#182,#65,#81,#83,#87,#89,#99,#101,#105,#117,#119,
   #121,#123,#125,#127,#131,#143,#145,#147,#149,#154,#156,#166,#168,#170,
   #172,#175,#183,#184,#185,#186,#187,#248,#249,#188,#189,#190,#191,#192,
   #193,#194,#195,#196,#197,#198,#250,#251,#252,#253,#199,#200,#201,#202,
   #203,#204,#205,#206,#207,#208,#209,#210,#254,#255,#211,#212,#213,#214,
   #215,#216,#217,#218,#219,#220,#221,#222,#223,#224,#225,#226,#227,#228,
   #229,#230,#231,#232,#233,#234,#235,#236,#237,#238,#239,#240,#241,#242,
   #243,#74,#76,#75,#77,#80,#73,#78,#86,#98,#95,#96,#97,#116,#113,#114,#115,
   #104,#130,#139,#137,#138,#140,#142,#244,#245,#163,#161,#162,#165,#118,#153,
   #151,#67,#69,#68,#70,#79,#66,#71,#85,#93,#90,#91,#92,#111,#110,#109,#108,
   #103,#128,#133,#132,#134,#135,#141,#246,#247,#158,#159,#157,#164,#107,#152,#173);
  TurkishToUpperChars: array [0..255] of AnsiChar=
  (#0,#1,#2,#3,#4,#5,#6,#7,#8,#9,#10,#11,#12,#13,#14,#15,
   #16,#17,#18,#19,#20,#21,#22,#23,#24,#25,#26,#27,#28,#29,#30,#31,#0,
   #33,#34,#35,#36,#37,#38,#39,#40,#41,#42,#43,#44,#45,#46,#47,#48,#49,
   #50,#51,#52,#53,#54,#55,#56,#57,#58,#59,#60,#61,#62,#63,#64,#65,#66,
   #67,#68,#69,#70,#71,#72,#73,#74,#75,#76,#77,#78,#79,#80,#81,#82,#83,
   #84,#85,#86,#87,#88,#89,#90,#91,#92,#93,#94,#95,#96,#65,#66,#67,#68,
   #69,#70,#71,#72,#221,#74,#75,#76,#77,#78,#79,#80,#81,#82,#83,#84,#85,
   #86,#87,#88,#89,#90,#123,#124,#125,#126,#127,#128,#129,#130,#131,#132,
   #133,#134,#135,#136,#137,#138,#139,#140,#141,#142,#143,#144,#145,#146,
   #147,#148,#149,#150,#151,#152,#153,#154,#155,#156,#157,#158,#159,#160,
   #161,#162,#163,#164,#165,#166,#167,#168,#169,#170,#171,#172,#173,#174,
   #175,#176,#177,#178,#179,#180,#181,#182,#183,#184,#185,#186,#187,#188,
   #189,#190,#191,#192,#193,#194,#195,#196,#197,#198,#199,#200,#201,#202,
   #203,#204,#205,#206,#207,#208,#209,#210,#211,#212,#213,#214,#215,#216,
   #217,#218,#219,#220,#221,#222,#223,#192,#193,#194,#195,#196,#197,#198,
   #199,#200,#201,#202,#203,#204,#205,#206,#207,#208,#209,#210,#211,#212,
   #213,#214,#247,#248,#217,#218,#219,#220,#73,#222,#255);
  TurkishToLowerChars: array [0..255] of AnsiChar=
  (#32,#1,#2,#3,#4,#5,#6,#7,#8,#9,#10,#11,#12,#13,#14,#15,#16,#17,#18,#19,
   #20,#21,#22,#23,#24,#25,#26,#27,#28,#29,#30,#31,#32,#33,#34,#35,#36,#37,
   #38,#39,#40,#41,#42,#43,#44,#45,#46,#47,#48,#49,#50,#51,#52,#53,#54,#55,
   #56,#57,#58,#59,#60,#61,#62,#63,#64,#97,#98,#99,#100,#101,#102,#103,#104,
   #253,#106,#107,#108,#109,#110,#111,#112,#113,#114,#115,#116,#117,#118,#119,
   #120,#121,#122,#91,#92,#93,#94,#95,#96,#97,#98,#99,#100,#101,#102,#103,#104,
   #105,#106,#107,#108,#109,#110,#111,#112,#113,#114,#115,#116,#117,#118,#119,
   #120,#121,#122,#123,#124,#125,#126,#127,#128,#129,#130,#131,#132,#133,#134,
   #135,#136,#137,#138,#139,#140,#141,#142,#143,#144,#145,#146,#147,#148,#149,
   #150,#151,#152,#153,#154,#155,#156,#157,#158,#159,#160,#161,#162,#163,#164,
   #165,#166,#167,#168,#169,#170,#171,#172,#173,#174,#175,#176,#177,#178,#179,
   #180,#181,#182,#183,#184,#185,#186,#187,#188,#189,#190,#191,#224,#225,#226,
   #227,#228,#229,#230,#231,#232,#233,#234,#235,#236,#237,#238,#239,#240,#241,
   #242,#243,#244,#245,#246,#215,#216,#249,#250,#251,#252,#105,#254,#223,#224,
   #225,#226,#227,#228,#229,#230,#231,#232,#233,#234,#235,#236,#237,#238,#239,
   #240,#241,#242,#243,#244,#245,#246,#247,#248,#249,#250,#251,#252,#253,#254,#255);

implementation

var
   p1,p2: PAnsiChar;
   i,j,n: byte;
   bCodePagesInitialized: boolean;
   LCID: Integer;

function IsStrMatchPattern(StrPtr: PAnsiChar; PatternPtr: PAnsiChar; bIgnoreCase:boolean): Boolean;
var i : integer;
    bEQ: Boolean;
    tmp1, tmp2: array [0..1] of AnsiChar;
begin
  tmp1[0]:=#0;tmp1[1]:=#0;
  tmp2[0]:=#0;tmp2[1]:=#0;
  repeat
      if (StrComp(PatternPtr,WildCardMultipleChar)=0) then
       begin
         Result:=True;
         exit;
       end
      else if (StrPtr^=#0) and (PatternPtr^ <> #0) then
       begin
         Result:=False;
         exit;
       end
      else if (StrPtr^=#0) then
       begin
         Result:=True;
         exit;
       end
      else
         begin
           case PatternPtr^ of
            WildCardMultipleChar:
               begin
                for i:=0 to Length(StrPtr) -1 do
                 begin
                  if IsStrMatchPattern(StrPtr+i,PatternPtr+1,bIgnoreCase) then
                   begin
                    Result := True;
                    exit;
                   end;
                 end;
                Result := False;
                exit;
               end;
            WildCardSingleChar:
               begin
                inc(StrPtr);
                inc(PatternPtr);
               end;
            else
               begin
                tmp1[0] := StrPtr^;
                tmp2[0] := PatternPtr^;
                if (bIgnoreCase) then
                 bEQ := (Q_AnsiCompTextL(tmp1, tmp2, 1) = 0)
                else
                 bEQ := (Q_AnsiCompStrL(tmp1, tmp2, 1) = 0);
                if (bEQ) then
                 begin
                  inc(StrPtr);
                  inc(PatternPtr);
                 end
                else
                 begin
                  Result:=False;
                  exit;
                 end;
               end;
           end; // case
         end; // non-simple cases
  until false;
end;// IsStrMatchPattern


//------------------------------------------------------------------------------
// Like '%_' compare for WideStr_ng
//------------------------------------------------------------------------------
function IsWideStrMatchPattern(StrPtr: PWideChar; PatternPtr: PWideChar; bIgnoreCase:boolean): Boolean;
var i: integer;
    bOk: boolean;
begin
  repeat
      if (Windows.CompareStringW(LOCALE_USER_DEFAULT,
                        NORM_IGNORECASE + SORT_STRINGSORT,
                        PatternPtr,
                        Length(PatternPtr),
                        WideChar(WildCardMultipleChar),
                        1)-2 = 0) then
       begin
         Result:=True;
         exit;
       end
      else if (StrPtr^=#0) and (PatternPtr^ <> #0) then
       begin
         Result:=False;
         exit;
       end
      else if (StrPtr^=#0) then
       begin
         Result:=True;
         exit;
       end
      else
         begin
           case PatternPtr^ of
            WildCardMultipleChar:
               begin
                for i:=0 to Length(StrPtr)-1 do
                 begin
                  if IsWideStrMatchPattern(StrPtr+i,PatternPtr+1,bIgnoreCase) then
                   begin
                    Result := True;
                    exit;
                   end;
                 end;
                Result := False;
                exit;
               end;
            WildCardSingleChar:
               begin
                inc(StrPtr);
                inc(PatternPtr);
               end;
            else
               begin
                bOk := false;
                if bIgnoreCase then
                 begin
                  if (Windows.CompareStringW(LOCALE_USER_DEFAULT,
                        NORM_IGNORECASE + SORT_STRINGSORT,
                        PatternPtr, 1, StrPtr,1)-2 = 0) then
                   bOk := true;
                 end
                else
                 begin
                  if (Windows.CompareStringW(LOCALE_USER_DEFAULT,
                        SORT_STRINGSORT,
                        PatternPtr, 1, StrPtr,1)-2 = 0) then
                   bOk := true;
                 end;

                if (bOk) then
                 begin
                  inc(StrPtr);
                  inc(PatternPtr);
                 end
                else
                 begin
                  Result:=False;
                  exit;
                 end;
               end;
           end; // case
         end; // non-simple cases
  until false;
end;// IsWideStrMatchPattern



function Q_PCompStr(P1, P2: PAnsiChar): Integer;
begin
  Result := 0;
  if P1 = nil
    then
      begin
        if ( P2 <> nil ) and ( P2[0] <> #0 )
          then Result := -1;
      end
    else
      if P2 <> nil
        then
          begin
            i := 0;
            while true do
              begin
                Result := byte( P1[i] ) - byte( P2[i] );
                if ( Result <> 0 ) or ( P1[i] = #0 )
                  then exit;
                inc( i );
              end;
          end
        else Result := 1;
end;
//asm
//        TEST    EAX,EAX
//        JE      @@2
//        TEST    EDX,EDX
//        JE      @@3
//        PUSH    EAX
//        MOVZX   EAX,BYTE PTR [EAX]
//        MOVZX   ECX,BYTE PTR [EDX]
//        SUB     EAX,ECX
//        JE      @@m
//        POP     ECX
//        RET
//@@m:    POP     EAX
//        INC     EAX
//        INC     EDX
//@@0:    TEST    CL,CL
//        JE      @@5
//        MOV     CL,BYTE PTR [EAX]
//        MOV     CH,BYTE PTR [EDX]
//        CMP     CL,CH
//        JNE     @@ne
//        TEST    CL,CL
//        JE      @@5
//        MOV     CL,BYTE PTR [EAX+1]
//        MOV     CH,BYTE PTR [EDX+1]
//        CMP     CL,CH
//        JNE     @@ne
//        TEST    CL,CL
//        JE      @@5
//        MOV     CL,BYTE PTR [EAX+2]
//        MOV     CH,BYTE PTR [EDX+2]
//        CMP     CL,CH
//        JNE     @@ne
//        TEST    CL,CL
//        JE      @@5
//        MOV     CL,BYTE PTR [EAX+3]
//        MOV     CH,BYTE PTR [EDX+3]
//        ADD     EAX,4
//        ADD     EDX,4
//        CMP     CL,CH
//        JE      @@0
//@@ne:   MOVZX   EAX,CL
//        MOVZX   EDX,CH
//        SUB     EAX,EDX
//        RET
//@@2:    TEST    EDX,EDX
//        JE      @@7
//        MOV     CH,BYTE PTR [EDX]
//        TEST    CH,CH 
//        JE      @@7
//        NOT     EAX
//        RET
//@@3:    MOV     CL,BYTE PTR [EAX]
//        TEST    CL,CL
//        JE      @@5 
//        MOV     EAX,1
//        RET
//@@5:    XOR     EAX,EAX
//@@7:
//end;

function Q_CompStrL(const S1, S2: AnsiString; MaxL: Cardinal): Integer;
begin
  Result := 0;
  if MaxL > 0
    then exit;

  if P1 = nil
    then
      begin
        if ( P2 <> nil ) and ( P2[0] <> #0 )
          then Result := -1;
      end
    else
      if P2 <> nil
        then
          begin
            i := 0;
            while i < MaxL do
              begin
                Result := byte( P1[i] ) - byte( P2[i] );
                if ( Result <> 0 ) or ( P1[i] = #0 )
                  then exit;
                inc( i );
              end;
          end
        else Result := 1;
end;
//asm
//        TEST    ECX,ECX
//        JE      @@1
//        TEST    EAX,EAX
//        JE      @@2
//        TEST    EDX,EDX
//        JE      @@3
//        PUSH    EBX 
//        PUSH    ESI
//        MOV     EBX,[EAX-4] 
//        MOV     ESI,[EDX-4] 
//        SUB     EBX,ESI
//        JG      @@w1
//        ADD     ESI,EBX
//@@w1:   CMP     ECX,ESI 
//        JA      @@fc
//@@dn:   POP     ESI
//@@lp:   DEC     ECX 
//        JS      @@zq
//        MOV     BL,BYTE PTR [EAX] 
//        MOV     BH,BYTE PTR [EDX]
//        CMP     BL,BH
//        JNE     @@ne 
//        DEC     ECX 
//        JS      @@zq 
//        MOV     BL,BYTE PTR [EAX+1]
//        MOV     BH,BYTE PTR [EDX+1]
//        CMP     BL,BH 
//        JNE     @@ne
//        DEC     ECX 
//        JS      @@zq
//        MOV     BL,BYTE PTR [EAX+2]
//        MOV     BH,BYTE PTR [EDX+2] 
//        CMP     BL,BH
//        JNE     @@ne
//        DEC     ECX
//        JS      @@zq
//        MOV     BL,BYTE PTR [EAX+3]
//        MOV     BH,BYTE PTR [EDX+3]
//        ADD     EAX,4 
//        ADD     EDX,4 
//        CMP     BL,BH 
//        JE      @@lp
//@@ne:   MOVZX   EAX,BL
//        MOVZX   EDX,BH
//        SUB     EAX,EDX
//        POP     EBX 
//        RET
//@@fc:   LEA     ECX,[ESI+1] 
//        JMP     @@dn 
//@@1:    XOR     EAX,EAX 
//        RET
//@@2:    TEST    EDX,EDX
//        JE      @@7 
//        MOV     CH,BYTE PTR [EDX]
//        TEST    CH,CH 
//        JE      @@7
//        NOT     EAX
//        RET
//@@3:    MOV     CL,BYTE PTR [EAX]
//        TEST    CL,CL
//        JE      @@5
//        MOV     EAX,1 
//        RET 
//@@zq:   POP     EBX 
//@@5:    XOR     EAX,EAX 
//@@7:
//end;


function Q_PCompText(P1, P2: PAnsiChar): Integer;
begin
  Result := 0;
  if P1 = nil
    then
      begin
        if ( P2 <> nil ) and ( ToUpperChars[ byte( P2[0] ) ] <> #0 )
          then Result := -1;
      end
    else
      if P2 <> nil
        then
          begin
            i := 0;
            while true do
              begin
                Result := byte( ToUpperChars[ byte( P1[i] ) ] ) - byte( ToUpperChars[ byte( P2[i] ) ] );
                if ( Result <> 0 ) or ( P1[i] = #0 )
                  then exit;
                inc( i );
              end;
          end
        else Result := 1;
end;
//asm
//        TEST    EAX,EAX
//        JE      @@2
//        TEST    EDX,EDX
//        JE      @@3
//        PUSH    ESI 
//        PUSH    EDI
//        MOV     ESI,EAX
//        MOV     EDI,EDX
//        JMP     @@1
//@@0:    TEST    AL,AL
//        JE      @@4
//        INC     ESI
//        INC     EDI
//@@1:    MOVZX   EAX,BYTE PTR [ESI]
//        MOVZX   EDX,BYTE PTR [EDI]
//        CMP     AL,DL
//        JE      @@0
//        MOV     AL,BYTE PTR [EAX+ToUpperChars]
//        MOV     DL,BYTE PTR [EDX+ToUpperChars]
//        CMP     AL,DL
//        JE      @@0
//        MOVZX   EAX,AL
//        MOVZX   EDX,DL
//        SUB     EAX,EDX
//        POP     EDI
//        POP     ESI
//        RET
//@@2:    TEST    EDX,EDX
//        JE      @@7
//        MOV     CH,BYTE PTR [EDX]
//        TEST    CH,CH
//        JE      @@7
//        NOT     EAX
//        RET
//@@3:    MOV     CL,BYTE PTR [EAX]
//        TEST    CL,CL
//        JE      @@5
//        MOV     EAX,1
//        RET
//@@4:    POP     EDI
//        POP     ESI
//@@5:    XOR     EAX,EAX
//@@7:
//end;

function Q_CompTextL(const S1, S2: AnsiString; MaxL: Cardinal): Integer;
begin
  Result := 0;
  if MaxL > 0
    then exit;

  if P1 = nil
    then
      begin
        if ( P2 <> nil ) and ( ToUpperChars[ byte( P2[0] ) ] <> #0 )
          then Result := -1;
      end
    else
      if P2 <> nil
        then
          begin
            i := 0;
            while i < MaxL do
              begin
                Result := byte( ToUpperChars[ byte( P1[i] ) ] ) - byte( ToUpperChars[ byte( P2[i] ) ] );
                if ( Result <> 0 ) or ( P1[i] = #0 )
                  then exit;
                inc( i );
              end;
          end
        else Result := 1;
end;
//asm
//        TEST    ECX,ECX
//        JE      @@5
//        TEST    EAX,EAX
//        JE      @@2
//        TEST    EDX,EDX
//        JE      @@3
//        PUSH    ESI
//        PUSH    EDI
//        MOV     ESI,[EAX-4]
//        MOV     EDI,[EDX-4]
//        SUB     ESI,EDI
//        JG      @@w1
//        ADD     EDI,ESI
//@@w1:   CMP     ECX,EDI
//        JA      @@fc
//@@dn:   MOV     ESI,EAX
//        MOV     EDI,EDX
//@@lp:   DEC     ECX
//        JS      @@zq
//        MOVZX   EAX,BYTE PTR [ESI]
//        MOVZX   EDX,BYTE PTR [EDI]
//        INC     ESI
//        INC     EDI
//        CMP     AL,DL
//        JE      @@lp
//        MOV     AL,BYTE PTR [EAX+ToUpperChars]
//        MOV     DL,BYTE PTR [EDX+ToUpperChars]
//        CMP     AL,DL
//        JE      @@lp
//@@ne:   MOVZX   EAX,AL
//        MOVZX   EDX,DL
//        SUB     EAX,EDX
//        POP     EDI
//        POP     ESI
//        RET
//@@fc:   LEA     ECX,[EDI+1]
//        JMP     @@dn
//@@2:    TEST    EDX,EDX
//        JE      @@7
//        MOV     CH,BYTE PTR [EDX]
//        TEST    CH,CH
//        JE      @@7
//        NOT     EAX
//        RET
//@@3:    MOV     CL,BYTE PTR [EAX]
//        TEST    CL,CL
//        JE      @@5
//        MOV     EAX,1
//        RET
//@@zq:   POP     EDI
//        POP     ESI
//@@5:    XOR     EAX,EAX
//@@7:
//end;

procedure Int256Chars(P: Pointer);
var
  wP : pchar absolute P;
begin
  for i := 0 to 255 do
    wP[i] := char(i);
end;
//asm
//        MOV     ECX,8
//        MOV     EDX,$03020100
//@@lp:   MOV     [EAX],EDX
//        ADD     EDX,$04040404
//        MOV     [EAX+4],EDX
//        ADD     EDX,$04040404
//        MOV     [EAX+8],EDX
//        ADD     EDX,$04040404
//        MOV     [EAX+12],EDX
//        ADD     EDX,$04040404
//        MOV     [EAX+16],EDX
//        ADD     EDX,$04040404
//        MOV     [EAX+20],EDX
//        ADD     EDX,$04040404
//        MOV     [EAX+24],EDX
//        ADD     EDX,$04040404
//        MOV     [EAX+28],EDX
//        ADD     EDX,$04040404
//        ADD     EAX,32
//        DEC     ECX
//        JNE     @@lp
//end;

function Q_PStrToAnsi(P: PAnsiChar): PAnsiChar;
begin
  Result := P;
  if Result <> nil
    then
      while P[0] <> #0 do
        begin
          P[0] := ToAnsiChars[ byte( P[0] ) ];
          inc( P );
        end;
end;
//asm
//        TEST    EAX,EAX
//        JE      @@2
//        PUSH    EAX
//        JMP     @@1
//@@0:    MOV     CL,BYTE PTR [EDX+ToAnsiChars]
//        MOV     BYTE PTR [EAX],CL
//        INC     EAX
//@@1:    MOVZX   EDX,BYTE PTR [EAX]
//        TEST    DL,DL
//        JNE     @@0
//        POP     EAX
//@@2:
//end;

function Q_PStrToOem(P: PAnsiChar): PAnsiChar;
begin
  Result := P;
  if Result <> nil
    then
      while P[0] <> #0 do
        begin
          P[0] := ToOemChars[ byte( P[0] ) ];
          inc( P );
        end;
end;
//asm
//        TEST    EAX,EAX
//        JE      @@2
//        PUSH    EAX
//        JMP     @@1
//@@0:    MOV     CL,BYTE PTR [EDX+ToOemChars]
//        MOV     BYTE PTR [EAX],CL
//        INC     EAX
//@@1:    MOVZX   EDX,BYTE PTR [EAX]
//        TEST    DL,DL
//        JNE     @@0
//        POP     EAX
//@@2:
//end;

function Q_AnsiPCompStr(P1, P2: PAnsiChar): Integer;
begin
 if (bCodePagesInitialized) then
  begin
   Q_PStrToAnsi(P1);
   Q_PStrToAnsi(P2);
   result := Q_PCompStr(P1, P2);
   Q_PStrToOem(P1);
   Q_PStrToOem(P2);
  end
 else
   result := AnsiStrComp(P1, P2);
end;

function Q_AnsiCompStrL(P1, P2: PAnsiChar; MaxL: Cardinal): Integer;
begin
 if (bCodePagesInitialized) then
  begin
   Q_PStrToAnsi(P1);
   Q_PStrToAnsi(P2);
   result := Q_CompStrL(P1, P2, MaxL);
   Q_PStrToOem(P1);
   Q_PStrToOem(P2);
  end
 else
   result := AnsiStrLComp(P1, P2, MaxL);
end;

function Q_AnsiPCompText(P1, P2: PAnsiChar): Integer;
begin
 if (bCodePagesInitialized) then
  begin
   Q_PStrToAnsi(P1);
   Q_PStrToAnsi(P2);
   result := Q_PCompText(P1, P2);
   Q_PStrToOem(P1);
   Q_PStrToOem(P2);
  end
 else
   result := AnsiStrIComp(P1, P2);
end;

function Q_AnsiCompTextL(P1, P2: PAnsiChar; MaxL: Cardinal): Integer;
begin
 if (bCodePagesInitialized) then
  begin
   Q_PStrToAnsi(P1);
   Q_PStrToAnsi(P2);
   result := Q_CompTextL(P1, P2, MaxL);
   Q_PStrToOem(P1);
   Q_PStrToOem(P2);
  end
 else
   result := AnsiStrLIComp(P1, P2, MaxL);
end;

initialization
  LCID := GetUserDefaultLCID;

  // ToAnsiChars
  p1 := AllocMem(2);
  p2 := AllocMem(2);
  // turkish?
  if (LCID <> 1055) then
   for i:=0 to 255 do
    begin
     n := 0;
     p1^ := AnsiChar(chr(i));
     for j:=0 to 255 do
      begin
       p2^ := AnsiChar(chr(j));
       if (AnsiStrLComp(p2,p1,1) < 0) then
        inc(n);
      end;
     ToAnsiChars[i] := AnsiChar(chr(n));
    end
  else
  // Turkish charset
  for i:=0 to 255 do
    ToAnsiChars[i] := TurkishToAnsiChars[i];

  // ToOemChars
  for i:=0 to 255 do
   ToOemChars[byte(ToAnsiChars[i])] := AnsiChar(chr(i));
  // check is table valid
  for i:=0 to 255 do
   begin
    bCodePagesInitialized := false;
    for j:=0 to 255 do
     if (ToAnsiChars[j] = AnsiChar(chr(i))) then
      begin
       bCodePagesInitialized := true;
       break;
      end;
    if (not bCodePagesInitialized) then
     break;
   end;
  if (not bCodePagesInitialized) then
   begin
    Int256Chars(@ToUpperChars);
    CharToOemBuffA(PAnsiChar(@ToUpperChars), PAnsiChar(@ToOemChars),256);
    OemToCharBuffA(PAnsiChar(@ToUpperChars),PAnsiChar(@ToAnsiChars),256);
    Int256Chars(@ToLowerChars);
    CharUpperBuffA(PAnsiChar(@ToUpperChars),256);
    CharLowerBuffA(PAnsiChar(@ToLowerChars),256);
   end
  else
   begin
    for i:=0 to 255 do
     begin
      p1^ := AnsiChar(chr(i));
      // Turkish charset?
      if (LCID <> 1055) then
       CharUpperBuffA(p1,1)
      else
       p1^ := TurkishToUpperChars[byte(p1^)];
      ToUpperChars[byte(ToAnsiChars[i])] := ToAnsiChars[byte(p1^)];
      p1^ := AnsiChar(chr(i));
      // Turkish charset?
      if (LCID <> 1055) then
       CharLowerBuffA(p1,1)
      else
       p1^ := TurkishToLowerChars[byte(p1^)];
      ToLowerChars[byte(ToAnsiChars[i])] := ToAnsiChars[byte(p1^)];
     end;
   end;
  FreeMem(p1);
  FreeMem(p2);
end.
