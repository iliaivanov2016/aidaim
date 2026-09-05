unit SFSCipher1;

{$I SFSVer.inc}
{$I Ver.inc}

interface

uses SysUtils,
 {$IFDEF DEBUG_LOG}
     SFSDebug,
 {$ENDIF}
     SFSDECUtil, SFSCipher, SFSHash;

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

const
  TCipher_Rijndael_TestVector : array[0..31] of byte =
    ( $94,$6D,$2B,$5E,$E0,$AD,$1B,$5C,$A5,$23,$A5,$13,$95,$8B,$3D,$2D,$93,$87,$F3,$37,$45,$51,$F6,$58,$9B,$E7,$90,$1B,$36,$87,$F9,$A9 );

class function TCipher_Rijndael.TestVector: Pointer;
begin
  Result := @TCipher_Rijndael_TestVector;
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
 
const
  TCipher_1DES_TestVector : array[0..31] of byte =
    ( $AD,$69,$42,$BB,$F6,$68,$20,$4D,$53,$CD,$C7,$62,$13,$93,$98,$C0,$30,$0D,$85,$0B,$E2,$AA,$72,$09,$6F,$DB,$5F,$8E,$D3,$E4,$CF,$8A );

class function TCipher_1DES.TestVector: Pointer;
begin
  Result := @TCipher_1DES_TestVector;
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

const
  TCipher_2DES_TestVector : array[0..31] of byte =
    ( $66,$5C,$79,$27,$E9,$1C,$8B,$A0,$A9,$E4,$99,$5A,$15,$8C,$BD,$46,$5C,$9C,$75,$91,$3C,$38,$06,$9D,$75,$B4,$7E,$68,$E9,$47,$FD,$AB );

class function TCipher_2DES.TestVector: Pointer;
begin
  Result := @TCipher_2DES_TestVector;
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

const
  TCipher_3DES_TestVector : array[0..31] of byte =
    ( $07,$4C,$14,$F3,$E2,$2E,$08,$D9,$64,$BF,$6F,$82,$B5,$DF,$F0,$A2,$2F,$2D,$3B,$DB,$17,$DB,$25,$B6,$B5,$1E,$FA,$71,$37,$2F,$D1,$72 );

class function TCipher_3DES.TestVector: Pointer;
begin
  Result := @TCipher_3DES_TestVector;
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

const
  TCipher_2DDES_TestVector : array[0..31] of byte =
    ( $93,$6C,$F6,$43,$C6,$A7,$7F,$ED,$4D,$B4,$70,$4A,$E2,$A6,$06,$8B,$75,$13,$19,$AF,$E1,$82,$ED,$35,$4E,$13,$F6,$88,$A4,$6B,$33,$26 );

class function TCipher_2DDES.TestVector: Pointer;
begin
  Result := @TCipher_2DDES_TestVector;
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

const
  TCipher_3DDES_TestVector : array[0..31] of byte =
    ( $2F,$5A,$5E,$D4,$5E,$8A,$AA,$4E,$D2,$66,$59,$48,$1D,$E1,$95,$94,$2A,$9F,$CC,$1F,$4D,$E6,$14,$F0,$50,$04,$03,$64,$66,$9A,$77,$8E );

class function TCipher_3DDES.TestVector: Pointer;
begin
  Result := @TCipher_3DDES_TestVector;
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

const
  TCipher_3TDES_TestVector : array[0..31] of byte =
    ( $0B,$12,$E4,$8B,$D9,$CD,$08,$BF,$CA,$AE,$3E,$5F,$F6,$FE,$13,$CD,$3F,$70,$6E,$CD,$53,$56,$3F,$5A,$80,$0F,$1B,$1E,$FB,$9A,$57,$96 );

class function TCipher_3TDES.TestVector: Pointer;
begin
  Result := @TCipher_3TDES_TestVector;
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
aaWriteToLog('SFSCipher1> initialization started');
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
aaWriteToLog('SFSCipher1> initialization finished');
{$ENDIF}

end.
