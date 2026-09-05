{Copyright:      Hagen Reddmann  mailto:HaReddmann@AOL.COM
 Author:         Hagen Reddmann
 Remarks:        freeware, but this Copyright must be included
 known Problems: none
 Version:        3.0,  Part I from Delphi Encryption Compendium  ( DEC Part I)
                 Delphi 2-4, designed and testet under D3 & D4
 Description:    Include a Selection of various Cipher's (Encryption Algo)
                 impl. Algo:
                   Cast128, Cast256, Mars, Misty 1, RC2, RC4, RC5, RC6,
                   FROG, Rijndael, Skipjack, Single DES, Double DES,
                   Triple DES, Double DES 16byte Plain, Triple DES 16,
                   Triple DES 24, DESX, NewDES, Diamond II,
                   Diamond II Lite, Sapphire II

 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ''AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
}
unit ACRCipher1;

{$I ACRVer.inc}
{$I Ver.inc}

interface

uses SysUtils,
 {$IFDEF DEBUG_LOG}
     ACRDebug,
 {$ENDIF}
     ACRDECUtil, ACRCipher, ACRHash;

type
  TCipher_Rijndael     = class;
  TCipher_1DES         = class;  {Single DES  8 byte Blocksize,  8 byte Keysize  56 bits relevant}
  TCipher_2DES         = class;  {Double DES  8 byte Blocksize, 16 byte Keysize 112 bits relevant}
  TCipher_3DES         = class;  {Triple DES  8 byte Blocksize, 24 byte Keysize 168 bits relevant}
  TCipher_2DDES        = class;  {Double DES 16 byte Blocksize, 16 byte Keysize 112 bits relevant}
  TCipher_3DDES        = class;  {Triple DES 16 byte Blocksize, 24 byte Keysize 168 bits relevant}
  TCipher_3TDES        = class;  {Triple DES 24 byte Blocksize, 24 byte Keysize 168 bits relevant}

  TCipher_Rijndael = class(TCipher)
  private
    FRounds: Integer;
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  public
    procedure Init(const Key; Size: Integer; IVector: Pointer); override;
  end;
  TCipher_1DES = class(TCipher)
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
    procedure MakeKey(const Data: array of Byte; Key: PInteger; Reverse: Boolean);
  public
    procedure Init(const Key; Size: Integer; IVector: Pointer); override;
  end;

  TCipher_2DES = class(TCipher_1DES)
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  public
    procedure Init(const Key; Size: Integer; IVector: Pointer); override;
  end;

  TCipher_3DES = class(TCipher_1DES)
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  public
    procedure Init(const Key; Size: Integer; IVector: Pointer); override;
  end;

  TCipher_2DDES = class(TCipher_2DES)
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  end;

  TCipher_3DDES = class(TCipher_3DES)
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  end;

  TCipher_3TDES = class(TCipher_3DES)
  protected
    class procedure GetContext(var ABufSize, AKeySize, AUserSize: Integer); override;
    class function TestVector: Pointer; override;
    procedure Encode(Data: Pointer); override;
    procedure Decode(Data: Pointer); override;
  end;



implementation

{$I cipher1.inc}

type
  PCipherRec = ^TCipherRec;
  TCipherRec = packed record
                  case Integer of
                    0: (X: array[0..7] of Byte);
                    1: (A, B: LongWord);
                end;


const
{don't change this}
  Rijndael_Blocks =  4;
  Rijndael_Rounds = 14;

class procedure TCipher_Rijndael.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  ABufSize := Rijndael_Blocks * 4;
  AKeySize := 32;
  AUserSize := (Rijndael_Rounds + 1) * Rijndael_Blocks * SizeOf(Integer) * 2;
end;

class function TCipher_Rijndael.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    094h,06Dh,02Bh,05Eh,0E0h,0ADh,01Bh,05Ch
         DB    0A5h,023h,0A5h,013h,095h,08Bh,03Dh,02Dh
         DB    093h,087h,0F3h,037h,045h,051h,0F6h,058h
         DB    09Bh,0E7h,090h,01Bh,036h,087h,0F9h,0A9h
end;

procedure TCipher_Rijndael.Encode(Data: Pointer);
var
  P,K: PInteger;
  I,A,B,C,D: Integer;
begin
  P := User;
  K := Data;
  for I := 2 to FRounds do
  begin
    A := K^ xor P^;                             Inc(P); Inc(K);
    B := K^ xor P^;                             Inc(P); Inc(K);
    C := K^ xor P^;                             Inc(P); Inc(K);
    D := K^ xor P^;                             Inc(P);

    K^ := Rijndael_T[0, D and $FF]        xor
          Rijndael_T[1, A shr  8 and $FF] xor
          Rijndael_T[2, B shr 16 and $FF] xor
          Rijndael_T[3, C shr 24];                      Dec(K);
    K^ := Rijndael_T[0, C and $FF]        xor
          Rijndael_T[1, D shr  8 and $FF] xor
          Rijndael_T[2, A shr 16 and $FF] xor
          Rijndael_T[3, B shr 24];                      Dec(K);
    K^ := Rijndael_T[0, B and $FF]        xor
          Rijndael_T[1, C shr  8 and $FF] xor
          Rijndael_T[2, D shr 16 and $FF] xor
          Rijndael_T[3, A shr 24];                      Dec(K);
    K^ := Rijndael_T[0, A and $FF]        xor
          Rijndael_T[1, B shr  8 and $FF] xor
          Rijndael_T[2, C shr 16 and $FF] xor
          Rijndael_T[3, D shr 24];
  end;

  A := K^ xor P^;                                       Inc(P); Inc(K);
  B := K^ xor P^;                                       Inc(P); Inc(K);
  C := K^ xor P^;                                       Inc(P); Inc(K);
  D := K^ xor P^;                                       Inc(P);

  K^ := Rijndael_S[0, D and $FF]               or
        Rijndael_S[0, A shr  8 and $FF] shl  8 or
        Rijndael_S[0, B shr 16 and $FF] shl 16 or
        Rijndael_S[0, C shr 24]         shl 24;                 Dec(K);
  K^ := Rijndael_S[0, C and $FF]               or
        Rijndael_S[0, D shr  8 and $FF] shl  8 or
        Rijndael_S[0, A shr 16 and $FF] shl 16 or
        Rijndael_S[0, B shr 24]         shl 24;                 Dec(K);
  K^ := Rijndael_S[0, B and $FF]               or
        Rijndael_S[0, C shr  8 and $FF] shl  8 or
        Rijndael_S[0, D shr 16 and $FF] shl 16 or
        Rijndael_S[0, A shr 24]         shl 24;                 Dec(K);
  K^ := Rijndael_S[0, A and $FF]               or
        Rijndael_S[0, B shr  8 and $FF] shl  8 or
        Rijndael_S[0, C shr 16 and $FF] shl 16 or
        Rijndael_S[0, D shr 24]         shl 24;

  for I := 1 to Rijndael_Blocks do
  begin
    K^ := K^ xor P^;
    Inc(P);
    Inc(K);
  end;
end;

procedure TCipher_Rijndael.Decode(Data: Pointer);
var
  P,K: PInteger;
  I,A,B,C,D: Integer;
begin
  P := Pointer(PAnsiChar(User) + UserSize shr 1);
  Inc(P, FRounds * 4 +3);
  K := Pointer(PAnsiChar(Data) + 12);
  for I := 2 to FRounds do
  begin
    D := K^ xor P^;                             Dec(P); Dec(K);
    C := K^ xor P^;                             Dec(P); Dec(K);
    B := K^ xor P^;                             Dec(P); Dec(K);
    A := K^ xor P^;                             Dec(P);

    K^ := Rijndael_T[4, A and $FF]        xor
          Rijndael_T[5, D shr  8 and $FF] xor
          Rijndael_T[6, C shr 16 and $FF] xor
          Rijndael_T[7, B shr 24];                      Inc(K);
    K^ := Rijndael_T[4, B and $FF]        xor
          Rijndael_T[5, A shr  8 and $FF] xor
          Rijndael_T[6, D shr 16 and $FF] xor
          Rijndael_T[7, C shr 24];                      Inc(K);
    K^ := Rijndael_T[4, C and $FF]        xor
          Rijndael_T[5, B shr  8 and $FF] xor
          Rijndael_T[6, A shr 16 and $FF] xor
          Rijndael_T[7, D shr 24];                      Inc(K);
    K^ := Rijndael_T[4, D and $FF]        xor
          Rijndael_T[5, C shr  8 and $FF] xor
          Rijndael_T[6, B shr 16 and $FF] xor
          Rijndael_T[7, A shr 24];
  end;

  D := K^ xor P^;                                       Dec(P); Dec(K);
  C := K^ xor P^;                                       Dec(P); Dec(K);
  B := K^ xor P^;                                       Dec(P); Dec(K);
  A := K^ xor P^;                                       Dec(P);

  K^ := Rijndael_S[1, A and $FF]               or
        Rijndael_S[1, D shr  8 and $FF] shl  8 or
        Rijndael_S[1, C shr 16 and $FF] shl 16 or
        Rijndael_S[1, B shr 24]         shl 24;                 Inc(K);
  K^ := Rijndael_S[1, B and $FF]               or
        Rijndael_S[1, A shr  8 and $FF] shl  8 or
        Rijndael_S[1, D shr 16 and $FF] shl 16 or
        Rijndael_S[1, C shr 24]         shl 24;                 Inc(K);
  K^ := Rijndael_S[1, C and $FF]               or
        Rijndael_S[1, B shr  8 and $FF] shl  8 or
        Rijndael_S[1, A shr 16 and $FF] shl 16 or
        Rijndael_S[1, D shr 24]         shl 24;                 Inc(K);
  K^ := Rijndael_S[1, D and $FF]               or
        Rijndael_S[1, C shr  8 and $FF] shl  8 or
        Rijndael_S[1, B shr 16 and $FF] shl 16 or
        Rijndael_S[1, A shr 24]         shl 24;

  for I := 0 to 3 do
  begin
    K^ := K^ xor P^;
    Dec(P);
    Dec(K);
  end;
end;

procedure TCipher_Rijndael.Init(const Key; Size: Integer; IVector: Pointer);
var
  K: array[0..7] of Integer;

  procedure BuildEncodeKey;
  const
    RND_Data: array[0..29] of Byte = (
      $01,$02,$04,$08,$10,$20,$40,$80,$1B,$36,$6C,$D8,$AB,$4D,$9A,
      $2F,$5E,$BC,$63,$C6,$97,$35,$6A,$D4,$B3,$7D,$FA,$EF,$C5,$91);
  var
    T,R: Integer;

    procedure NextRounds;
    var
      J: Integer;
    begin
      J := 0;
      while (J < FRounds-6) and (R <= FRounds) do
      begin
        while (J < FRounds-6) and (T < Rijndael_Blocks) do
        begin
          PIntArray(User)[R * Rijndael_Blocks + T] := K[J];
          Inc(J);
          Inc(T);
        end;
        if T = Rijndael_Blocks then
        begin
          T := 0;
          Inc(R);
        end;
      end;
    end;

  var
    RND: PByte;
    B: PByte;
    I: Integer;
  begin
    R := 0;
    T := 0;
    RND := @RND_Data;
    NextRounds;
    while R <= FRounds do
    begin
      B  := @K;
      B^ := B^ xor Rijndael_S[0, K[FRounds -7] shr  8 and $FF] xor RND^; Inc(B);
      B^ := B^ xor Rijndael_S[0, K[FRounds -7] shr 16 and $FF];          Inc(B);
      B^ := B^ xor Rijndael_S[0, K[FRounds -7] shr 24];                  Inc(B);
      B^ := B^ xor Rijndael_S[0, K[FRounds -7] and $FF];
      Inc(RND);
      if FRounds = 14 then
      begin
        for I := 1 to 7 do K[I] := K[I] xor K[I -1];
        B  := @K[4];
        B^ := B^ xor Rijndael_S[0, K[3] and $FF];         Inc(B);
        B^ := B^ xor Rijndael_S[0, K[3] shr  8 and $FF];  Inc(B);
        B^ := B^ xor Rijndael_S[0, K[3] shr 16 and $FF];  Inc(B);
        B^ := B^ xor Rijndael_S[0, K[3] shr 24];
        for I := 5 to 7 do K[I] := K[I] xor K[I -1];
      end else
        for I := 1 to FRounds -7 do K[I] := K[I] xor K[I -1];
      NextRounds;
    end;
  end;

  procedure BuildDecodeKey;
  var
    I: Integer;
    D: PInteger;
  begin
    D := Pointer(PAnsiChar(User) + UserSize shr 1);
    Move(User^, D^, UserSize shr 1);
    Inc(D, 4);
    for I := 0 to FRounds * 4 - 5 do
    begin
      D^ :=     Rijndael_Key[D^ and $FF] xor
            ROL(Rijndael_Key[D^ shr  8 and $FF],  8) xor
            ROL(Rijndael_Key[D^ shr 16 and $FF], 16) xor
            ROL(Rijndael_Key[D^ shr 24],         24);
      Inc(D);
    end;
  end;

begin
  InitBegin(Size);
  if Size <= 16 then FRounds := 10 else
    if Size <= 24 then FRounds := 12 else FRounds := 14;
  FillChar(K, SizeOf(K), 0);
  Move(Key, K, Size);
  BuildEncodeKey;
  BuildDecodeKey;
  FillChar(K, SizeOf(K), 0);
  InitEnd(IVector);
end;
{DES}
procedure DES_Func(Data: PIntArray; Key: PInteger); register;
var
  L,R,X,Y,I: LongWord;
begin
  L := SwapInteger(Data[0]);
  R := SwapInteger(Data[1]);

  X := (L shr  4 xor R) and $0F0F0F0F; R := R xor X; L := L xor X shl  4;
  X := (L shr 16 xor R) and $0000FFFF; R := R xor X; L := L xor X shl 16;
  X := (R shr  2 xor L) and $33333333; L := L xor X; R := R xor X shl  2;
  X := (R shr  8 xor L) and $00FF00FF; L := L xor X; R := R xor X shl  8;

  R := R shl 1 or R shr 31;
  X := (L xor R) and $AAAAAAAA;
  R := R xor X;
  L := L xor X;
  L := L shl 1 or L shr 31;

  for I := 0 to 7 do
  begin
    X := (R shl 28 or R shr 4) xor Key^; Inc(Key);
    Y := R xor Key^;                     Inc(Key);
    L := L xor (DES_Data[0, X        and $3F] or DES_Data[1, X shr  8 and $3F] or
                DES_Data[2, X shr 16 and $3F] or DES_Data[3, X shr 24 and $3F] or
                DES_Data[4, Y        and $3F] or DES_Data[5, Y shr  8 and $3F] or
                DES_Data[6, Y shr 16 and $3F] or DES_Data[7, Y shr 24 and $3F]);

    X := (L shl 28 or L shr 4) xor Key^; Inc(Key);
    Y := L xor Key^;                     Inc(Key);
    R := R xor (DES_Data[0, X        and $3F] or DES_Data[1, X shr  8 and $3F] or
                DES_Data[2, X shr 16 and $3F] or DES_Data[3, X shr 24 and $3F] or
                DES_Data[4, Y        and $3F] or DES_Data[5, Y shr  8 and $3F] or
                DES_Data[6, Y shr 16 and $3F] or DES_Data[7, Y shr 24 and $3F]);
  end;

  R := R shl 31 or R shr 1;
  X := (L xor R) and $AAAAAAAA;
  R := R xor X;
  L := L xor X;
  L := L shl 31 or L shr 1;

  X := (L shr  8 xor R) and $00FF00FF; R := R xor X; L := L xor X shl  8;
  X := (L shr  2 xor R) and $33333333; R := R xor X; L := L xor X shl  2;
  X := (R shr 16 xor L) and $0000FFFF; L := L xor X; R := R xor X shl 16;
  X := (R shr  4 xor L) and $0F0F0F0F; L := L xor X; R := R xor X shl  4;

  Data[0] := SwapInteger(R);
  Data[1] := SwapInteger(L);
end;

class procedure TCipher_1DES.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  ABufSize := 8;
  AKeySize := 8;
  AUserSize := 32 * 4 * 2;
end;

class function TCipher_1DES.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    0ADh,069h,042h,0BBh,0F6h,068h,020h,04Dh
         DB    053h,0CDh,0C7h,062h,013h,093h,098h,0C0h
         DB    030h,00Dh,085h,00Bh,0E2h,0AAh,072h,009h
         DB    06Fh,0DBh,05Fh,08Eh,0D3h,0E4h,0CFh,08Ah
end;

procedure TCipher_1DES.Encode(Data: Pointer);
begin
  DES_Func(Data, User);
end;

procedure TCipher_1DES.Decode(Data: Pointer);
begin
  DES_Func(Data, @PIntArray(User)[32]);
end;

procedure TCipher_1DES.MakeKey(const Data: array of Byte; Key: PInteger; Reverse: Boolean);
const
  ROT: array[0..15] of Byte = (1,2,4,6,8,10,12,14,15,17,19,21,23,25,27,28);
var
  I,J,L,M,N: LongWord;
  PC_M, PC_R: array[0..55] of Byte;
  K: array[0..31] of LongWord;
begin
  FillChar(K, SizeOf(K), 0);
  for I := 0 to 55 do
    if Data[DES_PC1[I] shr 3] and ($80 shr (DES_PC1[I] and $07)) <> 0 then PC_M[I] := 1
      else PC_M[I] := 0;
  for I := 0 to 15 do
  begin
    if Reverse then M := (15 - I) shl 1 else M := I shl 1;
    N := M + 1;
    for J := 0 to 27 do
    begin
      L := J + ROT[I];
      if L < 28 then PC_R[J] := PC_M[L] else PC_R[J] := PC_M[L - 28];
    end;
    for J := 28 to 55 do
    begin
      L := J + ROT[I];
      if L < 56 then PC_R[J] := PC_M[L] else PC_R[J] := PC_M[L - 28];
    end;
    L := $1000000;
    for J := 0 to 23 do
    begin
      L := L shr 1;
      if PC_R[DES_PC2[J     ]] <> 0 then K[M] := K[M] or L;
      if PC_R[DES_PC2[J + 24]] <> 0 then K[N] := K[N] or L;
    end;
  end;
  for I := 0 to 15 do
  begin
    M := I shl 1; N := M + 1;
    Key^ := K[M] and $00FC0000 shl  6 or
            K[M] and $00000FC0 shl 10 or
            K[N] and $00FC0000 shr 10 or
            K[N] and $00000FC0 shr  6;
    Inc(Key);
    Key^ := K[M] and $0003F000 shl 12 or
            K[M] and $0000003F shl 16 or
            K[N] and $0003F000 shr  4 or
            K[N] and $0000003F;
    Inc(Key);
  end;
end;

procedure TCipher_1DES.Init(const Key; Size: Integer; IVector: Pointer);
var
  K: array[0..7] of Byte;
begin
  InitBegin(Size);
  FillChar(K, SizeOf(K), 0);
  Move(Key, K, Size);
  MakeKey(K, User, False);
  MakeKey(K, @PIntArray(User)[32], True);
  FillChar(K, SizeOf(K), 0);
  InitEnd(IVector);
end;

class procedure TCipher_2DES.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  ABufSize := 8;
  AKeySize := 16;
  AUserSize := 32 * 4 * 2 * 2;
end;

class function TCipher_2DES.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    066h,05Ch,079h,027h,0E9h,01Ch,08Bh,0A0h
         DB    0A9h,0E4h,099h,05Ah,015h,08Ch,0BDh,046h
         DB    05Ch,09Ch,075h,091h,03Ch,038h,006h,09Dh
         DB    075h,0B4h,07Eh,068h,0E9h,047h,0FDh,0ABh
end;

procedure TCipher_2DES.Encode(Data: Pointer);
begin
  DES_Func(Data, User);
  DES_Func(Data, @PIntArray(User)[32]);
  DES_Func(Data, User);
end;

procedure TCipher_2DES.Decode(Data: Pointer);
begin
  DES_Func(Data, @PIntArray(User)[64]);
  DES_Func(Data, @PIntArray(User)[96]);
  DES_Func(Data, @PIntArray(User)[64]);
end;

procedure TCipher_2DES.Init(const Key; Size: Integer; IVector: Pointer);
var
  K: array[0..15] of Byte;
  P: PInteger;
begin
  InitBegin(Size);
  FillChar(K, SizeOf(K), 0);
  Move(Key, K, Size);
  P := User;
  MakeKey(K[0], P, False); Inc(P, 32);
  MakeKey(K[8], P, True);  Inc(P, 32);
  MakeKey(K[0], P, True);  Inc(P, 32);
  MakeKey(K[8], P, False);
  FillChar(K, SizeOf(K), 0);
  InitEnd(IVector);
end;

class procedure TCipher_3DES.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  ABufSize := 8;
  AKeySize := 24;
  AUserSize := 32 * 4 * 2 * 3;
end;

class function TCipher_3DES.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    007h,04Ch,014h,0F3h,0E2h,02Eh,008h,0D9h
         DB    064h,0BFh,06Fh,082h,0B5h,0DFh,0F0h,0A2h
         DB    02Fh,02Dh,03Bh,0DBh,017h,0DBh,025h,0B6h
         DB    0B5h,01Eh,0FAh,071h,037h,02Fh,0D1h,072h
end;

procedure TCipher_3DES.Encode(Data: Pointer);
begin
  DES_Func(Data, User);
  DES_Func(Data, @PIntArray(User)[32]);
  DES_Func(Data, @PIntArray(User)[64]);
end;

procedure TCipher_3DES.Decode(Data: Pointer);
begin
  DES_Func(Data, @PIntArray(User)[96]);
  DES_Func(Data, @PIntArray(User)[128]);
  DES_Func(Data, @PIntArray(User)[160]);
end;

procedure TCipher_3DES.Init(const Key; Size: Integer; IVector: Pointer);
var
  K: array[0..23] of Byte;
  P: PInteger;
begin
  InitBegin(Size);
  FillChar(K, SizeOf(K), 0);
  Move(Key, K, Size);
  P := User;
  MakeKey(K[ 0], P, False); Inc(P, 32);
  MakeKey(K[ 8], P, True);  Inc(P, 32);
  MakeKey(K[16], P, False); Inc(P, 32);
  MakeKey(K[16], P, True);  Inc(P, 32);
  MakeKey(K[ 8], P, False); Inc(P, 32);
  MakeKey(K[ 0], P, True);
  FillChar(K, SizeOf(K), 0);
  InitEnd(IVector);
end;

class procedure TCipher_2DDES.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  inherited GetContext(ABufSize, AKeySize, AUserSize);
  ABufSize := 16;
end;

class function TCipher_2DDES.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    093h,06Ch,0F6h,043h,0C6h,0A7h,07Fh,0EDh
         DB    04Dh,0B4h,070h,04Ah,0E2h,0A6h,006h,08Bh
         DB    075h,013h,019h,0AFh,0E1h,082h,0EDh,035h
         DB    04Eh,013h,0F6h,088h,0A4h,06Bh,033h,026h
end;

procedure TCipher_2DDES.Encode(Data: Pointer);
var
  T: Integer;
begin
  DES_Func(Data, User);
  DES_Func(@PIntArray(Data)[2], User);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  DES_Func(Data, @PIntArray(User)[32]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[32]);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  DES_Func(Data, User);
  DES_Func(@PIntArray(Data)[2], User);
end;

procedure TCipher_2DDES.Decode(Data: Pointer);
var
  T: Integer;
begin
  DES_Func(Data, @PIntArray(User)[64]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[64]);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  DES_Func(Data, @PIntArray(User)[96]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[96]);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  DES_Func(Data,  @PIntArray(User)[64]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[64]);
end;

class procedure TCipher_3DDES.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  inherited GetContext(ABufSize, AKeySize, AUserSize);
  ABufSize := 16;
end;

class function TCipher_3DDES.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    02Fh,05Ah,05Eh,0D4h,05Eh,08Ah,0AAh,04Eh
         DB    0D2h,066h,059h,048h,01Dh,0E1h,095h,094h
         DB    02Ah,09Fh,0CCh,01Fh,04Dh,0E6h,014h,0F0h
         DB    050h,004h,003h,064h,066h,09Ah,077h,08Eh
end;

procedure TCipher_3DDES.Encode(Data: Pointer);
var
  T: Integer;
begin
  DES_Func(Data, User);
  DES_Func(@PIntArray(Data)[2], User);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  DES_Func(Data, @PIntArray(User)[32]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[32]);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  DES_Func(Data,  @PIntArray(User)[64]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[64]);
end;

procedure TCipher_3DDES.Decode(Data: Pointer);
var
  T: Integer;
begin
  DES_Func(Data, @PIntArray(User)[96]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[96]);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  DES_Func(Data, @PIntArray(User)[128]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[128]);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  DES_Func(Data,  @PIntArray(User)[160]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[160]);
end;

class procedure TCipher_3TDES.GetContext(var ABufSize, AKeySize, AUserSize: Integer);
begin
  inherited GetContext(ABufSize, AKeySize, AUserSize);
  ABufSize := 24;
end;

class function TCipher_3TDES.TestVector: Pointer;
asm
         MOV   EAX,OFFSET @Vector
         RET
@Vector: DB    00Bh,012h,0E4h,08Bh,0D9h,0CDh,008h,0BFh
         DB    0CAh,0AEh,03Eh,05Fh,0F6h,0FEh,013h,0CDh
         DB    03Fh,070h,06Eh,0CDh,053h,056h,03Fh,05Ah
         DB    080h,00Fh,01Bh,01Eh,0FBh,09Ah,057h,096h
end;

procedure TCipher_3TDES.Encode(Data: Pointer);
var
  T: Integer;
begin
  DES_Func(@PIntArray(Data)[0], User);
  DES_Func(@PIntArray(Data)[2], User);
  DES_Func(@PIntArray(Data)[4], User);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  T := PIntArray(Data)[3]; PIntArray(Data)[3] := PIntArray(Data)[4]; PIntArray(Data)[3] := T;
  DES_Func(@PIntArray(Data)[0], @PIntArray(User)[32]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[32]);
  DES_Func(@PIntArray(Data)[4], @PIntArray(User)[32]);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  T := PIntArray(Data)[3]; PIntArray(Data)[3] := PIntArray(Data)[4]; PIntArray(Data)[3] := T;
  DES_Func(@PIntArray(Data)[0], @PIntArray(User)[64]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[64]);
  DES_Func(@PIntArray(Data)[4], @PIntArray(User)[64]);
end;

procedure TCipher_3TDES.Decode(Data: Pointer);
var
  T: Integer;
begin
  DES_Func(@PIntArray(Data)[0], @PIntArray(User)[96]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[96]);
  DES_Func(@PIntArray(Data)[4], @PIntArray(User)[96]);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  T := PIntArray(Data)[3]; PIntArray(Data)[3] := PIntArray(Data)[4]; PIntArray(Data)[3] := T;
  DES_Func(@PIntArray(Data)[0], @PIntArray(User)[128]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[128]);
  DES_Func(@PIntArray(Data)[4], @PIntArray(User)[128]);
  T := PIntArray(Data)[1]; PIntArray(Data)[1] := PIntArray(Data)[2]; PIntArray(Data)[2] := T;
  T := PIntArray(Data)[3]; PIntArray(Data)[3] := PIntArray(Data)[4]; PIntArray(Data)[3] := T;
  DES_Func(@PIntArray(Data)[0], @PIntArray(User)[160]);
  DES_Func(@PIntArray(Data)[2], @PIntArray(User)[160]);
  DES_Func(@PIntArray(Data)[4], @PIntArray(User)[160]);
end;


initialization

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRCipher1> initialization started');
{$ENDIF}

{$IFNDEF ManualRegisterClasses}
  RegisterCipher(TCipher_1DES, 'DES Single 8byte', '');
  RegisterCipher(TCipher_2DES, 'DES Double 8byte', '');
  RegisterCipher(TCipher_2DDES, 'DES Double 16byte', '');
  RegisterCipher(TCipher_3DES, 'DES Triple 8byte', '');
  RegisterCipher(TCipher_3DDES, 'DES Triple 16byte', '');
  RegisterCipher(TCipher_3TDES, 'DES Triple 24byte', '');
  RegisterCipher(TCipher_Rijndael, '', '');
{$ENDIF}

{$IFDEF DEBUG_LOG_INIT}
aaWriteToLog('ACRCipher1> initialization finished');
{$ENDIF}

end.
