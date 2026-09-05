unit ACR_Asm2Delphi;

////////////////////////////////////////////////////////////////////////////////
//
// Updated to support x64 platform by AidAim Software in 2012, www.aidaim.com
//
////////////////////////////////////////////////////////////////////////////////

{$I ACRVer.Inc}
{$I VER.INC}

interface

type
  // CRC Definitions Structure
  PCRCDef = ^TCRCDef;
  TCRCDef = packed record              // don't reorder or change this structure
    Table: array[0..255] of Cardinal;  // Lookuptable, precomputed in CRCSetup
    CRC: Cardinal;                     // intermediate CRC
    Inverse: LongBool;                 // is this Polynomial a inverse function
    Shift: Cardinal;                   // Shift Value for CRCCode, more speed
    InitVector: Cardinal;              // Startvalue of CRC Computation
    FinalVector: Cardinal;             // final XOR Vector of computed CRC
    Mask: Cardinal;                    // precomputed AND Mask of computed CRC
    Bits: Cardinal;                    // Bitsize of CRC
    Polynomial: Cardinal;              // used Polynomial
  end;                                 // SizeOf(TCRCDef) = 1056 = 0420h

  // predefined Standard CRC Types
  TCRCType = (CRC_8, CRC_10, CRC_12, CRC_16, CRC_16CCITT, CRC_16XModem, CRC_24,
              CRC_32, CRC_32CCITT, CRC_32ZModem);
type
  TReadMethod = function(var Buffer; Count: LongInt): LongInt of object;

 type
    PByteArray = ^TByteArray;
    TByteArray = array[0..0] of byte;
    PWordArray = ^TWordArray;
    TWordArray = array[0..0] of word;


// initilaize CRC Definition with a custom Algorithm
function CRCSetup(var CRCDef: TCRCDef; Polynomial, Bits, InitVector, FinalVector: Cardinal; Inverse: LongBool): Boolean;

// process over Buffer with Size Bytes Length a CRC definied in CRCDef.
// Result is actual computed CRC with correction, same as CRCDone(),
// CRCDef.CRC holds the actual computed CRC, a second/more call to CRCCode
// computes than both/more buffers as one buffer.
function CRCCode(var CRCDef: TCRCDef; const Buffer; Size: Cardinal): Cardinal;
function CRCCodeEx(var CRCDef: TCRCDef; ReadMethod: TReadMethod;  Size: Cardinal): Cardinal;
function CRCDone(var CRCDef: TCRCDef): Cardinal; register;
function CRCInit(var CRCDef: TCRCDef; CRCType: TCRCType): Boolean; register;
// calculates a CRC over Buffer with Size Bytes Length, used Algo in CRCType, all is done in one Step
function CRCCalc(CRCType: TCRCType; const Buffer; Size: Cardinal): Cardinal;

// use a callback
function CRCCalcEx(CRCType: TCRCType; ReadMethod: TReadMethod; Size: Cardinal{$IFDEF VER_D4H} = $FFFFFFFF{$ENDIF}): Cardinal;

// predefined CRC16-Standard, call CRC := CRC16(0, Data, SizeOf(Data));
function CRC16_X64(CRC: Word; const Buffer; Size: Cardinal): Word;

// predefined CRC32-CCITT, call CRC := CRC32(0, Data, SizeOf(Data));
function CRC32_X64(CRC: Cardinal; const Buffer; Size: Cardinal): Cardinal;

function CRC16Init: Pointer;
function CRC32Init: Pointer;

implementation

function ROL(Value: LongWord; Shift: Integer): LongWord;
begin
  Result := ( Value shl Shift ) or ( Value shr (32 - Shift) )
end;
                              
function ROR(Value: LongWord; Shift: Integer): LongWord;
begin
  Result := ( Value shr Shift ) or ( Value shl (32 - Shift) );
end;

{$IFOPT R+} {$DEFINE RangeChecks_ON}    {$ENDIF}
{$IFOPT Q+} {$DEFINE OverflowChecks_ON} {$ENDIF}

{$RANGECHECKS OFF} {$OVERFLOWCHECKS OFF}
// initilaize CRC Definition with a custom Algorithm
function CRCSetup(var CRCDef: TCRCDef; Polynomial, Bits, InitVector,
                        FinalVector: Cardinal; Inverse: LongBool): Boolean;
var
  i          : integer;
  _x         : cardinal;
  wValue     : cardinal;
  wOtherBits : byte;
begin
  CRCDef.Polynomial  := Polynomial;
  CRCDef.Bits        := Bits;
  CRCDef.CRC         := InitVector;
  CRCDef.InitVector  := InitVector;
  CRCDef.FinalVector := FinalVector;
  CRCDef.Inverse     := Inverse;

  CRCDef.Shift := Bits - 8;
  wOtherBits   := ( 32 - Bits ) and $FF;
  CRCDef.Mask  := -1 shr wOtherBits;

  if Inverse
    then
      begin //@@1:
        // Reversed-copy of rightmost |CRCDef.Bits| bits from |Polynomial|
        _x := 0;
        for i := 0 to Bits - 1 do
          begin
            _x := ( _x shl 1 ) + ( Polynomial and 1 );
            Polynomial := Polynomial shr 1;
          end;
        Polynomial := _x;

        for i := 255 downto 0 do
          begin
            _x := i;
            if _x and 1 <> 0 then _x := ( _x shr 1 ) xor Polynomial else _x := _x shr 1;
            if _x and 1 <> 0 then _x := ( _x shr 1 ) xor Polynomial else _x := _x shr 1;
            if _x and 1 <> 0 then _x := ( _x shr 1 ) xor Polynomial else _x := _x shr 1;
            if _x and 1 <> 0 then _x := ( _x shr 1 ) xor Polynomial else _x := _x shr 1;
            if _x and 1 <> 0 then _x := ( _x shr 1 ) xor Polynomial else _x := _x shr 1;
            if _x and 1 <> 0 then _x := ( _x shr 1 ) xor Polynomial else _x := _x shr 1;
            if _x and 1 <> 0 then _x := ( _x shr 1 ) xor Polynomial else _x := _x shr 1;
            if _x and 1 <> 0 then _x := ( _x shr 1 ) xor Polynomial else _x := _x shr 1;

            CRCDef.Table[i] := _x;
          end;
        Result := false; //!!? See @@27 and @@28
      end
    else
      begin //@@5:
        Polynomial := ROL( Polynomial and CRCDef.Mask, wOtherBits );

        for i := 255 downto 0 do
          begin
            _x := i shl 25;
            if _x and $80000000 <> 0 then _x := ( _x shl 1 ) xor Polynomial else _x := _x shl 1;
            if _x and $80000000 <> 0 then _x := ( _x shl 1 ) xor Polynomial else _x := _x shl 1;
            if _x and $80000000 <> 0 then _x := ( _x shl 1 ) xor Polynomial else _x := _x shl 1;
            if _x and $80000000 <> 0 then _x := ( _x shl 1 ) xor Polynomial else _x := _x shl 1;
            if _x and $80000000 <> 0 then _x := ( _x shl 1 ) xor Polynomial else _x := _x shl 1;
            if _x and $80000000 <> 0 then _x := ( _x shl 1 ) xor Polynomial else _x := _x shl 1;
            if _x and $80000000 <> 0 then _x := ( _x shl 1 ) xor Polynomial else _x := _x shl 1;
            if _x and $80000000 <> 0 then _x := ( _x shl 1 ) xor Polynomial else _x := _x shl 1;

            CRCDef.Table[i] := ROR( _x, wOtherBits );
          end;
        Result := CRCDef.Table[0] and $80000000 <> 0; //!!? See @@68:
      end;
end;
{$IFDEF RangeChecks_ON}    {$RANGECHECKS ON}    {$UNDEF RangeChecks_ON}    {$ENDIF}
{$IFDEF OverflowChecks_ON} {$OVERFLOWCHECKS ON} {$UNDEF OverflowChecks_ON} {$ENDIF}
  //asm // initialize CRCDef according to the parameters, calculate the lookup table
  //       CMP   ECX,8
  //       JB    @@8
  //       PUSH  EBX
  //       PUSH  EDI
  //       PUSH  ESI
  //       MOV   [EAX].TCRCDef.Polynomial,EDX
  //       MOV   [EAX].TCRCDef.Bits,ECX
  //       MOV   EBX,InitVector
  //       MOV   EDI,FinalVector
  //       MOV   ESI,Inverse
  //       MOV   [EAX].TCRCDef.CRC,EBX
  //       MOV   [EAX].TCRCDef.InitVector,EBX
  //       MOV   [EAX].TCRCDef.FinalVector,EDI
  //       MOV   [EAX].TCRCDef.Inverse,ESI
  //       XOR   EDI,EDI
  //       LEA   EBX,[ECX - 8]
  //       SUB   ECX,32
  //       DEC   EDI
  //       NEG   ECX
  //       SHR   EDI,CL
  //       MOV   [EAX].TCRCDef.Shift,EBX
  //       MOV   [EAX].TCRCDef.Mask,EDI
  //       TEST  ESI,ESI
  //       JZ    @@5

  //       XOR   EBX,EBX
  //       MOV   ECX,[EAX].TCRCDef.Bits
  //@@1:   SHR   EDX,1
  //       ADC   EBX,EBX
  //       DEC   ECX
  //       JNZ   @@1
  //       NOP

  //       MOV   ECX,255
  //       NOP
  //@@20:  MOV   EDX,ECX
  //       SHR   EDX,1
  //       JNC   @@21
  //       XOR   EDX,EBX
  //@@21:  SHR   EDX,1
  //       JNC   @@22
  //       XOR   EDX,EBX
  //@@22:  SHR   EDX,1
  //       JNC   @@23
  //       XOR   EDX,EBX
  //@@23:  SHR   EDX,1
  //       JNC   @@24
  //       XOR   EDX,EBX
  //@@24:  SHR   EDX,1
  //       JNC   @@25
  //       XOR   EDX,EBX
  //@@25:  SHR   EDX,1
  //       JNC   @@26
  //       XOR   EDX,EBX
  //@@26:  SHR   EDX,1
  //       JNC   @@27
  //       XOR   EDX,EBX
  //@@27:  SHR   EDX,1
  //       JNC   @@28
  //       XOR   EDX,EBX
  //@@28:  MOV   [EAX + ECX * 4],EDX
  //       DEC   ECX
  //       JNL   @@20
  //       JMP   @@7

  //@@5:   AND   EDX,EDI     // Polynomial &= CRCDef.Mask
  //       ROL   EDX,CL

  //       MOV   EBX,255
  // // can be coded branchfree
  //@@60:  MOV   ESI,EBX
  //       SHL   ESI,25
  //       JNC   @@61
  //       XOR   ESI,EDX
  //@@61:  ADD   ESI,ESI
  //       JNC   @@62
  //       XOR   ESI,EDX
  //@@62:  ADD   ESI,ESI
  //       JNC   @@63
  //       XOR   ESI,EDX
  //@@63:  ADD   ESI,ESI
  //       JNC   @@64
  //       XOR   ESI,EDX
  //@@64:  ADD   ESI,ESI
  //       JNC   @@65
  //       XOR   ESI,EDX
  //@@65:  ADD   ESI,ESI
  //       JNC   @@66
  //       XOR   ESI,EDX
  //@@66:  ADD   ESI,ESI
  //       JNC   @@67
  //       XOR   ESI,EDX
  //@@67:  ADD   ESI,ESI
  //       JNC   @@68
  //       XOR   ESI,EDX
  //@@68:  ROR   ESI,CL
  //       MOV   [EAX + EBX * 4],ESI
  //       DEC   EBX
  //       JNL   @@60

  //@@7:   POP   ESI
  //       POP   EDI
  //       POP   EBX

  //@@8:   CMC
  //       SBB   EAX,EAX
  //       NEG   EAX          ; Result := boolean(CF)
  //end;

{$IFOPT R+} {$DEFINE RangeChecks_ON}    {$ENDIF}
{$IFOPT Q+} {$DEFINE OverflowChecks_ON} {$ENDIF}

{$RANGECHECKS OFF} {$OVERFLOWCHECKS OFF}
// process over Buffer with Size Bytes Length a CRC definied in CRCDef.
// Result is actual computed CRC with correction, same as CRCDone(),
// CRCDef.CRC holds the actual computed CRC, a second/more call to CRCCode
// computes than both/more buffers as one buffer.
function CRCCode(var CRCDef: TCRCDef; const Buffer; Size: Cardinal): Cardinal;
var
  wBuffer : TByteArray absolute Buffer;
  i : integer;
begin
  Result := CRCDef.CRC;
  if ( Size > 0 ) and ( @Buffer <> nil )
    then
      begin
        if CRCDef.Inverse
          then
            for i := 0 to Size - 1 do
              CRCDef.CRC := CRCDef.Table[ byte( CRCDef.CRC shr CRCDef.Shift ) xor wBuffer[i] ] xor ( CRCDef.CRC shl 8 )
          else
            for i := 0 to Size - 1 do
              CRCDef.CRC := CRCDef.Table[ byte( CRCDef.CRC )                  xor wBuffer[i] ] xor ( CRCDef.CRC shr 8 );

        Result := ( CRCDef.CRC xor CRCDef.FinalVector ) and CRCDef.Mask;
      end;
end;
{$IFDEF RangeChecks_ON}    {$RANGECHECKS ON}    {$UNDEF RangeChecks_ON}    {$ENDIF}
{$IFDEF OverflowChecks_ON} {$OVERFLOWCHECKS ON} {$UNDEF OverflowChecks_ON} {$ENDIF}
//asm // do the CRC computation
//       JECXZ @@5
//       TEST  EDX,EDX
//       JZ    @@5
//       PUSH  ESI
//       PUSH  EBX
//       MOV   ESI,EAX
//       CMP   [EAX].TCRCDef.Inverse,0
//       MOV   EAX,[ESI].TCRCDef.CRC
//       JZ    @@2
//       XOR   EBX,EBX
//@@1:   MOV   BL,[EDX]
//       XOR   BL,AL
//       SHR   EAX,8
//       INC   EDX
//       XOR   EAX,[ESI + EBX * 4]
//       DEC   ECX
//       JNZ   @@1
//       JMP   @@4
//@@2:   PUSH  EDI
//       MOV   EBX,EAX            // EBX := CRCDef.CRC
//       MOV   EDI,ECX            // EDI := Size
//       MOV   ECX,[ESI].TCRCDef.Shift
//@@3:   SHR   EBX,CL
//       SHL   EAX,8
//       XOR   BL,[EDX]
//       INC   EDX
//       MOVZX EBX,BL
//       XOR   EAX,[ESI + EBX * 4]
//       DEC   EDI
//       MOV   EBX,EAX
//       JNZ   @@3
//       POP   EDI
//@@4:   MOV   [ESI].TCRCDef.CRC,EAX
//       XOR   EAX,[ESI].TCRCDef.FinalVector
//       AND   EAX,[ESI].TCRCDef.Mask
//       POP   EBX
//       POP   ESI
//       RET
//@@5:   MOV   EAX,[EAX].TCRCDef.CRC
//end;

function CRCCodeEx(var CRCDef: TCRCDef; ReadMethod: TReadMethod;  Size: Cardinal): Cardinal;
var
  Buffer: array[0..1023] of Char;
  Count: LongInt;
begin
  repeat
    if Size > SizeOf(Buffer) then
      Count := SizeOf(Buffer)
    else
      Count := Size;
    Count := ReadMethod(Buffer, Count);
    Result := CRCCode(CRCDef, Buffer, Count);
    Dec(Size, Count);
  until (Size = 0) or (Count = 0);
end;

function CRCInit(var CRCDef: TCRCDef; CRCType: TCRCType): Boolean; register;
type
  PCRCTab = ^TCRCTab;
  TCRCTab = array[TCRCType] of packed record
    Poly,Bits,Init,FInit: int64;//Cardinal;
    Inverse: int64;//LongBool;
  end;
const
  CRCTab : array[0..49] of int64 = (
   // Polynom   Bits InitVec    FinitVec   Inverse
      $000000D1,  8, $00000000, $00000000, -1,   // CRC_8  GSM/ERR
      $00000233, 10, $00000000, $00000000, -1,   // CRC_10 ATM/OAM Cell
      $0000080F, 12, $00000000, $00000000, -1,   // CRC_12
      $00008005, 16, $00000000, $00000000, -1,   // CRC_16 ARC,IBM
      $00001021, 16, $00001D0F, $00000000,  0,   // CRC_16 CCITT ITU
      $00008408, 16, $00000000, $00000000, -1,   // CRC_16 XModem
      $00864CFB, 24, $00B704CE, $00000000,  0,   // CRC_24
      $9DB11213, 32, $FFFFFFFF, $FFFFFFFF, -1,   // CRC_32
      $04C11DB7, 32, $FFFFFFFF, $FFFFFFFF, -1,   // CRC_32CCITT
      $04C11DB7, 32, $FFFFFFFF, $00000000, -1    // CRC_32ZModem
  );
//  // some other CRC's, not all yet verfied
//  // DD    $00000007,  8, $00000000, $00000000, -1   // CRC_8  ATM/HEC
//  // DD    $00000007,  8, $00000000, $00000000,  0   // CRC_8 the SMBus Working Group
//  // DD    $00004599, 15, $00000000, $00000000, -1   // CRC_15 CANBus
//  // DD    $00001021, 16, $00000000, $00000000,  0   // CRC_16ZModem
//  // DD    $00001021, 16, $0000FFFF, $00000000,  0   // CRC_16 CCITT British Aerospace
//  // DD    $00004003, 16, $00000000, $00000000, -1   // CRC_16 reversed
//  // DD    $00001005, 16, $00000000, $00000000, -1   // CRC_16 X25
//  // DD    $00000053, 16, $00000000, $00000000, -1   // BasicCard 16Bit CRC (sparse poly for Crypto MCU)
//  // DD    $000000C5, 32, $00000000, $00000000, -1   // BasicCard 32Bit CRC

begin
  with PCRCTab(@CRCTab)[CRCType] do
    Result := CRCSetup(CRCDef, Poly, Bits, Init, FInit, LongBool( Inverse ));
end;

function CRCDone(var CRCDef: TCRCDef): Cardinal; //register;
begin // finalize CRCDef after a computation
    Result     := ( CRCDef.FinalVector xor CRCDef.CRC ) and CRCDef.Mask;
    CRCDef.CRC := CRCDef.InitVector;
end;
//asm // finalize CRCDef after a computation
//       MOV   EDX,[EAX].TCRCDef.CRC
//       MOV   ECX,[EAX].TCRCDef.InitVector
//       XOR   EDX,[EAX].TCRCDef.FinalVector
//       MOV   [EAX].TCRCDef.CRC,ECX
//       AND   EDX,[EAX].TCRCDef.Mask
//       MOV   EAX,EDX
//end;

function CRCCalc(CRCType: TCRCType; const Buffer; Size: Cardinal): Cardinal;
// inplace calculation
var
  CRC: TCRCDef;
begin
  CRCInit(CRC, CRCType);
  Result := CRCCode(CRC, Buffer, Size);
end;

function CRCCalcEx(CRCType: TCRCType; ReadMethod: TReadMethod; Size: Cardinal): Cardinal;
var
  CRC: TCRCDef;
begin
  CRCInit(CRC, CRCType);
  Result := CRCCodeEx(CRC, ReadMethod, Size);
end;

// predefined CRC16-Standard, call CRC := CRC16(0, Data, SizeOf(Data));
var
  FCRC16: PCRCDef = nil;
  FCRC32: PCRCDef = nil;

function CRC16Init: Pointer;
begin
  GetMem(FCRC16, SizeOf(TCRCDef));
  CRCInit(FCRC16^, CRC_16);
  Result := FCRC16;
end;

{$IFOPT R+} {$DEFINE RangeChecks_ON}    {$ENDIF}
{$IFOPT Q+} {$DEFINE OverflowChecks_ON} {$ENDIF}

{$RANGECHECKS OFF} {$OVERFLOWCHECKS OFF}
function CRC16_X64(CRC: Word; const Buffer; Size: Cardinal): Word;
var
  wBuffer : TByteArray absolute Buffer;
  i : integer;
begin
  if FCRC16 = nil
    then CRC16Init;
  for i := 0 to Size - 1 do
    CRC := FCRC16.Table[ byte(CRC) xor wBuffer[i] ] xor ( CRC shr 8 );
  Result := CRC;
end;
{$IFDEF RangeChecks_ON}    {$RANGECHECKS ON}    {$UNDEF RangeChecks_ON}    {$ENDIF}
{$IFDEF OverflowChecks_ON} {$OVERFLOWCHECKS ON} {$UNDEF OverflowChecks_ON} {$ENDIF}
//asm
//       JECXZ @@2
//       PUSH  EDI
//       PUSH  ESI
//       MOV   EDI,ECX
//{$IFDEF PIC}
//       MOV   ESI,[EBX].FCRC16
//{$ELSE}
//       MOV   ESI,FCRC16
//{$ENDIF}
//       XOR   ECX,ECX
//       TEST  ESI,ESI
//       JZ    @@3
//@@1:   MOV   CL,[EDX]
//       XOR   CL,AL
//       SHR   EAX,8
//       INC   EDX
//       XOR   EAX,[ESI + ECX * 4]
//       DEC   EDI
//       JNZ   @@1
//       POP   ESI
//       POP   EDI
//@@2:   RET
//@@3:   PUSH  EAX
//       PUSH  EDX
//       CALL  CRC16Init
//       MOV   ESI,EAX
//       XOR   ECX,ECX
//       POP   EDX
//       POP   EAX
//       JMP   @@1
//end;

function CRC32Init: Pointer;
begin
  GetMem(FCRC32, SizeOf(TCRCDef));
  CRCInit(FCRC32^, CRC_32CCITT);
  Result := FCRC32;
end;

{$IFOPT R+} {$DEFINE RangeChecks_ON}    {$ENDIF}
{$IFOPT Q+} {$DEFINE OverflowChecks_ON} {$ENDIF}

{$RANGECHECKS OFF} {$OVERFLOWCHECKS OFF}
// predefined CRC32-CCITT, call CRC := CRC32(0, Data, SizeOf(Data));
function CRC32_X64(CRC: Cardinal; const Buffer; Size: Cardinal): Cardinal;
var
  wBuffer : TByteArray absolute Buffer;
  i : integer;
begin
  if FCRC32 = nil
    then CRC32Init;

  Result := not CRC;
  for i := 0 to Size - 1 do
    Result := FCRC32.Table[ byte(Result) xor wBuffer[i] ] xor ( Result shr 8 );
  Result := not Result;
end;
{$IFDEF RangeChecks_ON}    {$RANGECHECKS ON}    {$UNDEF RangeChecks_ON}    {$ENDIF}
{$IFDEF OverflowChecks_ON} {$OVERFLOWCHECKS ON} {$UNDEF OverflowChecks_ON} {$ENDIF}
//asm
//       JECXZ @@2
//       PUSH  EDI
//       PUSH  ESI
//       NOT   EAX                    // inverse Input CRC
//       MOV   EDI,ECX
//{$IFDEF PIC}
//       MOV   ESI,[EBX].FCRC32
//{$ELSE}
//       MOV   ESI,FCRC32
//{$ENDIF}
//       XOR   ECX,ECX
//       TEST  ESI,ESI
//       JZ    @@3
//@@1:   MOV   CL,[EDX]
//       XOR   CL,AL
//       SHR   EAX,8
//       INC   EDX
//       XOR   EAX,[ESI + ECX * 4]
//       DEC   EDI
//       JNZ   @@1
//       NOT   EAX                    // inverse Output CRC
//       POP   ESI
//       POP   EDI
//@@2:   RET
//@@3:   PUSH  EAX
//       PUSH  EDX
//       CALL  CRC32Init
//       MOV   ESI,EAX
//       XOR   ECX,ECX
//       POP   EDX
//       POP   EAX
//       JMP   @@1
//end;

procedure CRCInitThreadSafe;
begin
  CRC16Init;
  CRC32Init;
end;

initialization


finalization
  if FCRC16 <> nil then FreeMem(FCRC16);
  if FCRC32 <> nil then FreeMem(FCRC32);

end.
