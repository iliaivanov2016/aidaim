unit utCompareDataValues;

interface

{$I UTConfig.Inc}

uses uTestList, SysUtils,
{$IFDEF MSWINDOWS}
     Windows,
{$ENDIF}
     ACRBaseEngine,
     ACRTypes,
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
     ACRMemory,
     ACRExcept,
     ACRConst,
     ACRConverts,
     ACRVariant;

type
  TUnitTestCompareDataValues = class(TUnitTest)
   public
    procedure TestShort; override;
   public
    procedure InternalTestInteger;
    procedure InternalTestCast;
    procedure InternalTestVariant;
    procedure StrCompare;
    procedure WStrCompare;
  end;

var
  UnitTestCompareDataValues: TUnitTestCompareDataValues;


implementation


{ TUnitTestCompareDataValues }
{$IFDEF ACR5H}
// Compare 2 values
function CompareValueBuffers(
                              Buffer1, Buffer2: Pointer;
                              BaseFieldType1, BaseFieldType2: TACRBaseFieldType;
                              IsField1Null: Boolean = false;
                              IsField2Null: Boolean = false;
                              PartialCompareLength: Integer = -1;
                              IgnoreCase: Boolean = false;
                              LocaleID: LCID = LOCALE_USER_DEFAULT
                            ): TACRCompareResult;
var
{$I ACR_cmp_buffers_var.inc}
begin
// params
    CMP_BUF_Buffer1 := Buffer1;
    CMP_BUF_Buffer2 := Buffer2;
    CMP_BUF_BaseFieldType1 := BaseFieldType1;
    CMP_BUF_BaseFieldType2 := BaseFieldType2;
    CMP_BUF_IsField1Null := IsField1Null;
    CMP_BUF_IsField2Null := IsField2Null;
    CMP_BUF_PartialCompareLength := PartialCompareLength;
    CMP_BUF_IgnoreCase := IgnoreCase;
{$IFDEF MSWINDOWS}
    CMP_BUF_LocaleID := LOCALE_USER_DEFAULT;
{$ENDIF}
    {$I ACR_cmp_buffers.inc}
    Result := CMP_BUF_Result;
end;

{$ENDIF}

procedure TUnitTestCompareDataValues.TestShort;
begin
    CheckAction(InternalTestInteger, 'Test Integer & Integer');
    CheckAction(InternalTestCast, 'Test Cast');
    CheckAction(InternalTestVariant, 'Test Variant');
    CheckAction(StrCompare, 'Test StrCompare');
    CheckAction(WStrCompare, 'Test WStrCompare');
end;

procedure TUnitTestCompareDataValues.InternalTestInteger;
var
  s8: Shortint;
  s16: Smallint;
  s32: Longint;
  s64: Int64;
  u8: Byte;
  u16: Word;
  u32: Longword;
  ss8: Shortint;
  ss16: Smallint;
  ss32: Longint;
  ss64: Int64;
  uu8: Byte;
  uu16: Word;
  uu32: Longword;

begin
  s8 := 123;
  ss8 := -12;
  if CompareValueBuffers(@s8, @ss8, bftSignedInt8, bftSignedInt8) <> cmprGreater then
    raise Exception.Create('s8 > compare error');
  if CompareValueBuffers(@ss8, @s8, bftSignedInt8, bftSignedInt8) <> cmprLower then
    raise Exception.Create('s8 < compare error');
  ss8 := s8;
  if CompareValueBuffers(@ss8, @s8, bftSignedInt8, bftSignedInt8) <> cmprEqual then
    raise Exception.Create('s8 = compare error');


  s16 := 123;
  ss16 := -12;
  if CompareValueBuffers(@s16, @ss16, bftSignedInt16, bftSignedInt16) <> cmprGreater then
    raise Exception.Create('s16 > compare error');
  if CompareValueBuffers(@ss16, @s16, bftSignedInt16, bftSignedInt16) <> cmprLower then
    raise Exception.Create('s16 < compare error');
  ss16 := s16;
  if CompareValueBuffers(@ss16, @s16, bftSignedInt16, bftSignedInt16) <> cmprEqual then
    raise Exception.Create('s16 = compare error');


  s32 := 123;
  ss32 := -12;
  if CompareValueBuffers(@s32, @ss32, bftSignedInt32, bftSignedInt32) <> cmprGreater then
    raise Exception.Create('s32 > compare error');
  if CompareValueBuffers(@ss32, @s32, bftSignedInt32, bftSignedInt32) <> cmprLower then
    raise Exception.Create('s32 < compare error');
  ss32 := s32;
  if CompareValueBuffers(@ss32, @s32, bftSignedInt32, bftSignedInt32) <> cmprEqual then
    raise Exception.Create('s32 = compare error');


  s64 := 123;
  ss64 := -12;
  if CompareValueBuffers(@s64, @ss64, bftSignedInt64, bftSignedInt64) <> cmprGreater then
    raise Exception.Create('s64 > compare error');
  if CompareValueBuffers(@ss64, @s64, bftSignedInt64, bftSignedInt64) <> cmprLower then
    raise Exception.Create('s64 < compare error');
  ss64 := s64;
  if CompareValueBuffers(@ss64, @s64, bftSignedInt64, bftSignedInt64) <> cmprEqual then
    raise Exception.Create('s64 = compare error');


  u8 := 254;
  uu8 := 123;
  if CompareValueBuffers(@u8, @uu8, bftUnSignedInt8, bftUnSignedInt8) <> cmprGreater then
    raise Exception.Create('u8 > compare error');
  if CompareValueBuffers(@uu8, @u8, bftUnSignedInt8, bftUnSignedInt8) <> cmprLower then
    raise Exception.Create('u8 < compare error');
  uu8 := u8;
  if CompareValueBuffers(@uu8, @u8, bftUnSignedInt8, bftUnSignedInt8) <> cmprEqual then
    raise Exception.Create('u8 = compare error');

  u16 := 254;
  uu16 := 123;
  if CompareValueBuffers(@u16, @uu16, bftUnSignedInt16, bftUnSignedInt16) <> cmprGreater then
    raise Exception.Create('u16 > compare error');
  if CompareValueBuffers(@uu16, @u16, bftUnSignedInt16, bftUnSignedInt16) <> cmprLower then
    raise Exception.Create('u16 < compare error');
  uu16 := u16;
  if CompareValueBuffers(@uu16, @u16, bftUnSignedInt16, bftUnSignedInt16) <> cmprEqual then
    raise Exception.Create('u16 = compare error');

  u32 := 254;
  uu32 := 123;
  if CompareValueBuffers(@u32, @uu32, bftUnSignedInt32, bftUnSignedInt32) <> cmprGreater then
    raise Exception.Create('u32 > compare error');
  if CompareValueBuffers(@uu32, @u32, bftUnSignedInt32, bftUnSignedInt32) <> cmprLower then
    raise Exception.Create('u32 < compare error');
  uu32 := u32;
  if CompareValueBuffers(@uu32, @u32, bftUnSignedInt32, bftUnSignedInt32) <> cmprEqual then
    raise Exception.Create('u32 = compare error');

end;

procedure TUnitTestCompareDataValues.InternalTestCast;
var
  s: String;
  i: Integer;
  p: Pointer;
begin
  s := '12345';
  p := CastToNewBuffer(s, bftVarchar, bftSignedInt32);
  i := pInteger(p)^;
  if (i <> 12345) then ;

  MemoryManager.FreeAndNilMem(p);
end;

procedure TUnitTestCompareDataValues.InternalTestVariant;
var
  v: TACRVariant;
  s: WideString;
  i: Integer;
begin
  v := TACRVariant.Create(bftSignedInt32);
  try
    v.AsWideString := '123';
    v.DataType := bftDouble;
    //v.DataType := bftSignedInt8;
    v.AsShortint := 123;
    v.AsSmallint := 123;
    v.AsInteger := 123;
    v.AsInt64 := 123;
    v.AsByte := 123;
    v.AsWord := 123;
    v.AsCardinal := 123;
    v.AsSingle := 123;
    v.AsDouble := 123;
    v.AsExtended := 123;
    v.AsWideString := '123';
    v.AsCurrency := 123;
    v.AsString := '123';
    i := v.AsShortint;
    s := IntToStr(i) + v.AsWideString;
    s := v.AsWideString;
    if s <> '123' then
      raise Exception.Create('Variant Error. s=''' + s + '''');
  finally
    v.Free;
  end;
end;

procedure TUnitTestCompareDataValues.StrCompare;
var
   s1, s2: String;
   cmpRes: TACRCompareResult;
begin
  s1 := 'A';
  s2 := 'b';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar);
  if (cmpRes <> cmprLower) then
    WriteToErrorLog('CompareString: ''A'' < ''b'' case sensitive error');

  s1 := 'b';
  s2 := 'A';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareString: ''b'' > ''A'' case sensitive error');

  s1 := 'A';
  s2 := 'a';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar,
                                false, false, -1, true);
  if (cmpRes <> cmprEqual) then
    WriteToErrorLog('CompareString: ''A'' = ''a'' case insensitive error');

  s1 := 'A';
  s2 := 'a';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareString: ''A'' > ''a'' case sensitive error');

  s1 := 'B';
  s2 := 'a';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareString: ''B'' > ''a'' case sensitive error');

  s1 := 'B';
  s2 := 'a';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar,
                                false, false, -1, true);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareString: ''B'' > ''a'' case insensitive error');

  s1 := 'ABBA';
  s2 := 'aBaObAb';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar,
                                false, false, 2, true);
  if (cmpRes <> cmprEqual) then
    WriteToErrorLog('CompareString: ''ABBA'' = ''aBaObAb'' case insensitive 2 characters - error');

  s1 := 'ABBA';
  s2 := 'aBaObAb';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar,
                                false, false, 2);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareString: ''ABBA'' > ''aBaObAb'' case sensitive 2 characters - error');

  s1 := 'AAAA';
  s2 := 'aaaaaa';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar,
                                false, false, 6, true);
  if (cmpRes <> cmprLower) then
    WriteToErrorLog('CompareString: ''AAAA'' < ''aaaaaa'' case insensitive  6 characters - error');

  s1 := 'AAAA';
  s2 := 'aaaaaa';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftVarchar, bftVarchar,
                                false, false, 6);
  if (cmpRes <> cmprLower) then
    WriteToErrorLog('CompareString: ''AAAA'' < ''aaaaaa'' case sensitive 6 characters - error');

end;

procedure TUnitTestCompareDataValues.WStrCompare;
var
   s1, s2: WideString;
   cmpRes: TACRCompareResult;
begin
  s1 := 'A';
  s2 := 'b';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWidechar, bftWidechar);
  if (cmpRes <> cmprLower) then
    WriteToErrorLog('CompareWideString: ''A'' < ''b'' case sensitive error');

  s1 := 'b';
  s2 := 'A';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWideVarchar, bftWideVarchar);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareWideString: ''b'' > ''A'' case sensitive error');

  s1 := 'A';
  s2 := 'a';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWideVarchar, bftWideVarchar,
                                false, false, -1, true);
  if (cmpRes <> cmprEqual) then
    WriteToErrorLog('CompareWideString: ''A'' = ''a'' case insensitive error');

  s1 := 'A';
  s2 := 'a';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWideVarchar, bftWideVarchar);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareWideString: ''A'' > ''a'' case sensitive error');

  s1 := 'B';
  s2 := 'a';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWideVarchar, bftWideVarchar);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareWideString: ''B'' > ''a'' case sensitive error');

  s1 := 'B';
  s2 := 'a';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWideVarchar, bftWideVarchar,
                                false, false, -1, true);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareWideString: ''B'' > ''a'' case insensitive error');

  s1 := 'ABBA';
  s2 := 'aBaObAb';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWidechar, bftWidechar,
                                false, false, 2, true);
  if (cmpRes <> cmprEqual) then
    WriteToErrorLog('CompareWideString: ''ABBA'' = ''aBaObAb'' case insensitive 2 characters - error');

  s1 := 'ABBA';
  s2 := 'aBaObAb';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWideVarchar, bftWideVarchar,
                                false, false, 2);
  if (cmpRes <> cmprGreater) then
    WriteToErrorLog('CompareWideString: ''ABBA'' > ''aBaObAb'' case sensitive 2 characters - error');

// Windows bugs in WideString 
{
  s1 := 'AAAA';
  s2 := 'aaaaaa';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWidechar, bftWidechar,
                                false, false, 6, true);
  if (cmpRes <> cmprLower) then
    WriteToErrorLog('CompareWideString: ''AAAA'' < ''aaaaaa'' case insensitive  6 characters - error');

  s1 := 'AAAA';
  s2 := 'aaaaaa';
  cmpRes := CompareValueBuffers(PChar(s1), PChar(s2), bftWideVarchar, bftWideVarchar,
                                false, false, 6);
  if (cmpRes <> cmprLower) then
    WriteToErrorLog('CompareWideString: ''AAAA'' < ''aaaaaa'' case sensitive 6 characters - error');
}
end;

initialization
  UnitTestCompareDataValues := TUnitTestCompareDataValues.Create(UnitTestList);

finalization
  UnitTestCompareDataValues.Free;

end.
