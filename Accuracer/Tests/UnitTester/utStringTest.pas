unit utStringTest;

interface

{$I ACRVer.Inc}
{$I UTConfig.Inc}

uses uTestList, SysUtils, Db, DBClient, Windows,
Classes,
{$IFDEF D6H}
Variants,
{$ENDIF}
ACRMain, 
{$IFDEF ACR5H}
     ACRComMain,
{$ENDIF}
ACRPage,
ACRConst,
ACRConverts,
ACRVariant,
ACRExpressions,
ACRTypes
;

const MaxStringLength = 10000;

type
  TUnitTestStringTest = class(TUnitTest)
   private
    ACRDB:    TACRDatabase;
    ACRTable: TACRTable;
   private
    procedure CreateTable(InMemory, Temporary, CreateIndexes: Boolean);
    procedure PerformTest;
   public
    procedure TestStrings(InMemory, Temporary: Boolean);
    procedure TestChineseXPLikeBug;
    procedure TestBlack;
    procedure MainTest;
    procedure TestShort; override;
  end;

var
  UnitTestStringTest: TUnitTestStringTest;


implementation

function GenerateString(len: Integer): String;
var i,x : integer;
    s : string;
    c : char;
begin
 s := '';

 for i := 1 to len do
  begin
   x := Random(101);
   if ((x mod 2) =  0) then
    c := chr(65+(Random(260000000) mod 26))
   else
    c := chr(48+(Random(100000000) mod 10));

   s := s + c;
  end; //len
 result := s;
end; // GenerateString



procedure TUnitTestStringTest.PerformTest;
var
    s:    string;

 procedure CheckStringValue(ErrorCode: Integer);
 begin
  if (ACRTable.Fields[0].AsString <> s) then
   WriteToErrorLog('UnitTestStringTest error - field#0 has invalid value, error code = '+IntToStr(ErrorCode));
  if (ACRTable.Fields[1].AsString <> s) then
   WriteToErrorLog('UnitTestStringTest error - field#1 has invalid value, error code = '+IntToStr(ErrorCode));
  if (ACRTable.Fields[2].AsString <> s) then
   WriteToErrorLog('UnitTestStringTest error - field#2 has invalid value, error code = '+IntToStr(ErrorCode));
  if (ACRTable.Fields[3].AsString <> s) then
   WriteToErrorLog('UnitTestStringTest error - field#3 has invalid value, error code = '+IntToStr(ErrorCode));
 end;

begin
  ACRTable.Insert;
  ACRTable.Fields[0].AsString := '';
  ACRTable.Fields[1].AsString := '';
  ACRTable.Fields[2].AsString := '';
  ACRTable.Fields[3].AsString := '';
  ACRTable.Post;
  if (not ACRTable.Fields[0].IsNull) then
   WriteToErrorLog('UnitTestStringTest error - field#0 is not null');
  if (not ACRTable.Fields[1].IsNull) then
   WriteToErrorLog('UnitTestStringTest error - field#1 is not null');
  if (not ACRTable.Fields[2].IsNull) then
   WriteToErrorLog('UnitTestStringTest error - field#2 is not null');
  if (not ACRTable.Fields[3].IsNull) then
   WriteToErrorLog('UnitTestStringTest error - field#3 is not null');

  s := GenerateString(10);
  ACRTable.Insert;
  ACRTable.Fields[0].AsString := s;
  ACRTable.Fields[1].AsString := s;
  ACRTable.Fields[2].AsString := s;
  ACRTable.Fields[3].AsString := s;
  ACRTable.Post;
  CheckStringValue(1);

  s := GenerateString(MaxStringLength-1);
  ACRTable.Insert;
  ACRTable.Fields[0].AsString := s;
  ACRTable.Fields[1].AsString := s;
  ACRTable.Fields[2].AsString := s;
  ACRTable.Fields[3].AsString := s;
  ACRTable.Post;
  CheckStringValue(2);

  s := GenerateString(MaxStringLength);
  ACRTable.Insert;
  ACRTable.Fields[0].AsString := s;
  ACRTable.Fields[1].AsString := s;
  ACRTable.Fields[2].AsString := s;
  ACRTable.Fields[3].AsString := s;
  ACRTable.Post;
  CheckStringValue(3);

  s := GenerateString(MaxStringLength+1);
  ACRTable.Insert;
  ACRTable.Fields[0].AsString := s;
  ACRTable.Fields[1].AsString := s;
  ACRTable.Fields[2].AsString := s;
  ACRTable.Fields[3].AsString := s;
  ACRTable.Post;
  s := Copy(s,1,MaxStringLength);
  CheckStringValue(4);
end; // test

procedure TUnitTestStringTest.CreateTable(InMemory, Temporary, CreateIndexes: Boolean);
begin
 ACRTable.Close;
 if (InMemory) then
  begin
   ACRTable.InMemory := True;
   ACRTable.Temporary := False;
  end // memory
 else
 if (Temporary) then
  begin
   ACRTable.InMemory := False;
   ACRTable.Temporary := True;
  end // temp
 else
  begin
   ACRTable.InMemory := False;
   ACRTable.Temporary := False;
   ACRTable.DatabaseName := ACRDB.DatabaseName;
  end; // disk
 if (ACRTable.Exists) then
  ACRTable.DeleteTable;

 ACRTable.FieldDefs.Clear;
 ACRTable.AdvFieldDefs.Clear;

 ACRTable.AdvFieldDefs.Add('FixedChar',aftChar,MaxStringLength);
 ACRTable.AdvFieldDefs.Add('FixedWideChar',aftWideChar,MaxStringLength);
 ACRTable.AdvFieldDefs.Add('Varchar',aftString,MaxStringLength);
 ACRTable.AdvFieldDefs.Add('WideVarchar',aftWideString,MaxStringLength);
 ACRTable.AdvFieldDefs.Items[ACRTable.AdvFieldDefs.Count-1].BLOBCompressionAlgorithm := caZLIB;
 ACRTable.AdvFieldDefs.Items[ACRTable.AdvFieldDefs.Count-1].BLOBCompressionMode := 9;


 ACRTable.IndexDefs.Clear;
 if (CreateIndexes) then
  begin
   ACRTable.IndexDefs.Add('index0','FixedChar',[]);
   ACRTable.IndexDefs.Add('index1','FixedWideChar',[]);
   ACRTable.IndexDefs.Add('index2','Varchar',[]);
   ACRTable.IndexDefs.Add('index3','WideVarchar',[]);
  end; // create indexes
 ACRTable.CreateTable;
 ACRTable.Open;
 if (ACRTable.FieldDefs[0].Size <> MaxStringLength) then
   WriteToErrorLog('UnitTestStringTest error - field#0 has invalid length');
 if (ACRTable.FieldDefs[1].Size <> MaxStringLength) then
   WriteToErrorLog('UnitTestStringTest error - field#1 has invalid length');
 if (ACRTable.FieldDefs[2].Size <> MaxStringLength) then
   WriteToErrorLog('UnitTestStringTest error - field#2 has invalid length');
 if (ACRTable.FieldDefs[3].Size <> MaxStringLength) then
   WriteToErrorLog('UnitTestStringTest error - field#3 has invalid length');

 if (ACRTable.Fields[1].DataSize <> 4) then
   WriteToErrorLog('UnitTestStringTest error - field#1 has invalid data size');
 if (ACRTable.Fields[3].DataSize <> 4) then
   WriteToErrorLog('UnitTestStringTest error - field#3 has invalid data size');
end;

procedure TUnitTestStringTest.TestStrings(InMemory, Temporary: Boolean);
begin

 ACRTable.IndexName := '';
 CreateTable(InMemory,Temporary,False);
 PerformTest;

 CreateTable(InMemory,Temporary,True);
 ACRTable.IndexName := 'index0';
 PerformTest;


 CreateTable(InMemory,Temporary,True);
 ACRTable.IndexName := 'index1';
 PerformTest;

 CreateTable(InMemory,Temporary,True);
 ACRTable.IndexName := 'index2';
 PerformTest;

 CreateTable(InMemory,Temporary,True);
 ACRTable.IndexName := 'index3';
 PerformTest;
end;

procedure TUnitTestStringTest.TestChineseXPLikeBug;
const BasePattern = #$A7#$F5;
const Pattern = '%'+BasePattern+'%';
const RecOK1 = #$A7#$F5#$C3#$C4#$AE#$76;
const RecOK2 = #$B9#$71#$AA#$F7#$A7#$F5#$B0#$F6#$AA#$51;
const RecNotOK1 = #$AF#$CE#$A4#$70#$A4#$40;
const RecNotOK2 = #$B6#$C0#$A4#$6A#$A5#$50;
const Capt = 'TestChineseXPLikeBug - ';
const RecWideOK1 = #$DC#$80#$BD#$80;
const BaseWidePattern = RecWideOK1;
const WidePattern = '%'+RecWideOK1+'%';


function GetComparisonResult(s,p: AnsiString): String;
var tmp1, tmp2: array [0..1] of AnsiChar;
    n,i,k:      Integer;
begin
  tmp1[0]:=#0;
  tmp1[1]:=#0;
  tmp2[0]:=#0;
  tmp2[1]:=#0;
  n := Length(s)-1;
  Result := '';
  if (Length(p) >= 2) then
    for i := 1 to n do
     begin
      tmp1[0] := s[i];
      tmp2[0] := p[1];
      k := Windows.CompareStringA(1024,4096,tmp1,1,tmp2,1);
      Result := Result + tmp1[0]+#9+tmp2[0]+#9+IntToStr(k)+#13#10;
      tmp1[0] := s[i];
      tmp2[0] := p[2];
      k := Windows.CompareStringA(1024,4096,tmp1,1,tmp2,1);
      Result := Result + tmp1[0]+#9+tmp2[0]+#9+IntToStr(k)+#13#10+'-----------------------------------------------------'+#13#10;
     end;
end;

var t: TACRTable;
    q: TACRQuery;
    res: Boolean;
    v,v1: TACRVariant;
    s: String;
    fs: TFileStream;
begin
 t := TACRTable.Create(nil);
 v := TACRVariant.Create;
 v1 := TACRVariant.Create;
 q := TACRQuery.Create(nil);
 try
   t.InMemory := True;
   q.InMemory := True;
   t.TableName := 'test';
   t.AdvFieldDefs.Add('id',aftAutoInc);
   t.AdvFieldDefs.Add('str',aftChar,50);
   t.AdvFieldDefs.Add('wstr',aftWideChar,50);
   t.CreateTable;
   t.Open;
   t.Insert; t.Fields[1].AsString := RecOK1; t.Fields[2].Value := RecWideOK1; t.Post;
   t.Insert; t.Fields[1].AsString := RecOK2; t.Post;
   t.Insert; t.Fields[1].AsString := RecNotOK1; t.Post;
   t.Insert; t.Fields[1].AsString := RecNotOK2; t.Post;

   v.Clear;
   v1.Clear;
   v.AsString := RecOK1;
   v1.AsString := Pattern;
   res := IsStrMatchPattern(v.pData,v1.pData,False);
   if (res) then
    WriteToProcessLog(Capt+'test #1 OK')
   else
    WriteToErrorLog(Capt+'test #1 Error');

   v.Clear;
   v1.Clear;
   v.AsString := RecOK2;
   v1.AsString := Pattern;
   res := IsStrMatchPattern(v.pData,v1.pData,False);
   if (res) then
    WriteToProcessLog(Capt+'test #2 OK')
   else
    WriteToErrorLog(Capt+'test #2 Error');

   v.Clear;
   v1.Clear;
   v.AsString := RecNotOK1;
   v1.AsString := Pattern;
   res := IsStrMatchPattern(v.pData,v1.pData,False);
   if (not res) then
    WriteToProcessLog(Capt+'test #3 OK')
   else
    WriteToErrorLog(Capt+'test #3 Error');

   v.Clear;
   v1.Clear;
   v.AsString := RecNotOK2;
   v1.AsString := Pattern;
   res := IsStrMatchPattern(v.pData,v1.pData,False);
   if (not res) then
    WriteToProcessLog(Capt+'test #4 OK')
   else
    WriteToErrorLog(Capt+'test #4 Error');

   t.Filtered := False;
   t.Filter := 'str LIKE "'+Pattern+'"';
   t.Filtered := True;
   if (t.RecordCount = 2) then
    WriteToProcessLog(Capt+'test #5 OK')
   else
    WriteToErrorLog(Capt+'test #5 Error');

   t.Filtered := False;
   t.Filter := 'str = "'+RecOK1+'"';
   t.Filtered := True;
   if (t.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #51 OK')
   else
    WriteToErrorLog(Capt+'test #51 Error');
   if (t.FieldByName('str').Value <> RecOK1) then
    WriteToErrorLog(Capt+'test #51 Error #2');

   v.Clear;
   v1.Clear;
   v.AsWideString := RecWideOK1;
   v1.AsWideString := WidePattern;
   res := IsStrMatchPattern(v.pData,v1.pData,False);
   if (res) then
    WriteToProcessLog(Capt+'test #6 OK')
   else
    WriteToErrorLog(Capt+'test #6 Error');
{
fs := TFileStream.Create('RecWideOK1.txt',fmCreate);
fs.Size := 0;
fs.WriteBuffer(PChar(@RecWideOK1[1])^,Length(RecWideOK1));
fs.Free;
}
{
fs := TFileStream.Create('v.txt',fmCreate);
fs.Size := 0;
fs.WriteBuffer(v.pData^,v.DataSize);
fs.Free;
}
{
fs := TFileStream.Create('v1.txt',fmCreate);
fs.Size := 0;
fs.WriteBuffer(v1.pData^,v1.DataSize);
fs.Free;
}
   res := IsWideStrMatchPattern(PWideChar(v.pData),PWideChar(v1.pData),False);
   if (res) then
    WriteToProcessLog(Capt+'test #7 OK')
   else
    WriteToErrorLog(Capt+'test #7 Error');

   t.Filtered := False;
   t.Filter := 'wstr = "'+BaseWidePattern+'"';
   t.Filtered := True;
   if (t.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #8 OK')
   else
    WriteToErrorLog(Capt+'test #8 Error');
   if (t.FieldByName('wstr').Value <> RecWideOK1) then
    WriteToErrorLog(Capt+'test #8 Error #2');

   q.SQL.Text := 'SELECT * FROM '+t.TableName+#13#10+'WHERE wstr = :p0';
   q.ParamByName('p0').DataType := ftWideString;
   q.Params[0].Value := BaseWidePattern;
   q.Open;
   if (q.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #9 OK')
   else
    WriteToErrorLog(Capt+'test #9 Error');
   if (q.FieldByName('wstr').Value <> RecWideOK1) then
    WriteToErrorLog(Capt+'test #9 Error #2');
   q.Close;

   q.SQL.Text := 'SELECT * FROM '+t.TableName+#13#10+'WHERE wstr LIKE :p0';
   q.ParamByName('p0').DataType := ftWideString;
   q.Params[0].Value := WidePattern;
   q.Open;
   if (q.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #10 OK')
   else
    WriteToErrorLog(Capt+'test #10 Error');
   if (q.FieldByName('wstr').Value <> RecWideOK1) then
    WriteToErrorLog(Capt+'test #10 Error #2');
   q.Close;

   q.SQL.Text := 'SELECT * FROM '+t.TableName+#13#10+'WHERE wstr = '''+BaseWidePattern +'''';
   q.Open;
   if (q.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #11 OK')
   else
    WriteToErrorLog(Capt+'test #11 Error');
   if (q.FieldByName('wstr').Value <> RecWideOK1) then
    WriteToErrorLog(Capt+'test #11 Error #2');
   q.Close;

   // Let's create index!
   q.SQL.Text := 'CREATE INDEX idx1 ON '+t.TableName+'(wstr);'+
                 'CREATE INDEX idx2 ON '+t.TableName+'(str)';
   q.ExecSQL;

   t.Filtered := False;
   t.Filter := 'str LIKE "'+Pattern+'"';
   t.Filtered := True;
   if (t.RecordCount = 2) then
    WriteToProcessLog(Capt+'test #12 OK')
   else
    WriteToErrorLog(Capt+'test #12 Error');

   t.Filtered := False;
   t.Filter := 'str = "'+RecOK1+'"';
   t.Filtered := True;
   if (t.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #13 OK')
   else
    WriteToErrorLog(Capt+'test #13 Error');
   if (t.FieldByName('str').Value <> RecOK1) then
    WriteToErrorLog(Capt+'test #13 Error #2');

   t.Filtered := False;
   t.Filter := 'wstr = "'+BaseWidePattern+'"';
   t.Filtered := True;
   if (t.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #14 OK')
   else
    WriteToErrorLog(Capt+'test #14 Error');
   if (t.FieldByName('wstr').Value <> RecWideOK1) then
    WriteToErrorLog(Capt+'test #14 Error #2');

   q.SQL.Text := 'SELECT * FROM '+t.TableName+#13#10+'WHERE wstr = :p0';
   q.ParamByName('p0').DataType := ftWideString;
   q.Params[0].Value := BaseWidePattern;
   q.Open;
   if (q.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #15 OK')
   else
    WriteToErrorLog(Capt+'test #15 Error');
   if (q.FieldByName('wstr').Value <> RecWideOK1) then
    WriteToErrorLog(Capt+'test #15 Error #2');
   q.Close;

   q.SQL.Text := 'SELECT * FROM '+t.TableName+#13#10+'WHERE wstr LIKE :p0';
   q.ParamByName('p0').DataType := ftWideString;
   q.Params[0].Value := WidePattern;
   q.Open;
   if (q.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #16 OK')
   else
    WriteToErrorLog(Capt+'test #16 Error');
   if (q.FieldByName('wstr').Value <> RecWideOK1) then
    WriteToErrorLog(Capt+'test #16 Error #2');
   q.Close;

   q.SQL.Text := 'SELECT * FROM '+t.TableName+#13#10+'WHERE wstr = '''+BaseWidePattern +'''';
   q.Open;
   if (q.RecordCount = 1) then
    WriteToProcessLog(Capt+'test #17 OK')
   else
    WriteToErrorLog(Capt+'test #17 Error');
   if (q.FieldByName('wstr').Value <> RecWideOK1) then
    WriteToErrorLog(Capt+'test #17 Error #2');
   q.Close;
{
   s := GetComparisonResult(RecNotOK1,BasePattern);
   fs := TFileStream.Create('RecNotOK1.txt',fmCreate);
   fs.Size := 0;
   if (Length(s) > 0) then
     fs.WriteBuffer(PChar(@s[1])^,Length(s));
   fs.Free;

   s := GetComparisonResult(RecNotOK2,BasePattern);
   fs := TFileStream.Create('RecNotOK2.txt',fmCreate);
   fs.Size := 0;
   if (Length(s) > 0) then
     fs.WriteBuffer(PChar(@s[1])^,Length(s));
   fs.Free;
}
 finally
   q.Free;
   v.Free;
   v1.Free;
   t.Close;
   t.DeleteTable(True);
   t.Free;
 end;
end;

procedure TUnitTestStringTest.TestBlack;
var ACRTable1: TACRTable;
begin
 ACRTable1 := TACRTable.Create(nil);
 try
  ACRTable1.InMemory := True;
  with ACRTable1.AdvFieldDefs do
    begin
     Clear;
     Add('Name',aftWideString,30,False);
     Add('Info',aftWideMemo,0,False);
    end;
  ACRTable1.TableName := 'TestBlack';  
  ACRTable1.CreateTable;
  ACRTable1.Open;
{$IFDEF D12H}
// will not work in Delphi 7
  ACRTable1.AppendRecord(['Bill Clinton','']);
  ACRTable1.AppendRecord(['George Bush',WideString('Stayed 8 years.')]);
  ACRTable1.AppendRecord(['Barack Obama',WideString('First black president')]);
{$ELSE}
  ACRTable1.Append;
  ACRTable1.Fields[0].Value := WideString('Bill Clinton');
  ACRTable1.Post;
  ACRTable1.Append;
  ACRTable1.Fields[0].Value := WideString('George Bush');
  ACRTable1.SetWideMemoField(ACRTable1.Fields[1],WideString('Stayed 8 years.'));
  ACRTable1.Post;
  ACRTable1.Append;
  ACRTable1.Fields[0].Value := WideString('Barack Obama');
  ACRTable1.SetWideMemoField(ACRTable1.Fields[1],WideString('First black president'));
  ACRTable1.Post;
{$ENDIF}

  ACRTable1.filtered := false;
  ACRTable1.filter := 'info like ''%black%''';
  ACRTable1.filtered := true;
  ACRTable1.first;
  if (ACRTable1.RecordCount = 1) and
     (ACRTable1.FieldValues['Name'] = 'Barack Obama') then
   WriteToProcessLog('TUnitTestStringTest.TestBlack - OK')
  else
   WriteToErrorLog('TUnitTestStringTest.TestBlack - error')
 finally
  ACRTable1.Close;
  ACRTable1.DeleteTable(True);
  ACRTable1.Free;
 end;
end; // Black


procedure TUnitTestStringTest.MainTest;
begin
 ACRDefaultMemoryPageSize := MaxStringLength * 4 + 4 + ACRMaxIndexHeaderSize;
 ACRDefaultTemporaryPageSize := ACRDefaultMemoryPageSize;
 ACRDB := TACRDatabase.Create(nil);
 ACRTable := TACRTable.Create(nil);
 try
  ACRDB.Options.PageSize := ACRDefaultMemoryPageSize;
  ACRDB.DatabaseName := 'TestDB';
  ACRDB.DatabaseFileName := TempDir + 'test_string.adb';
  ACRTable.TableName := 'test';
  ACRDB.CreateDatabase;
  ACRDB.Open;

  TestStrings(False,False);
  TestStrings(True,False);
  TestStrings(False,True);

  ACRDB.Close;
  ACRDB.DeleteDatabase;
 finally
  ACRDB.Free;
  ACRTable.Free;
 end;

end;


procedure TUnitTestStringTest.TestShort;
begin
 CheckAction(TestBlack, 'Test Black: LIKE filter "%black%"');
 CheckAction(TestChineseXPLikeBug, 'Test Chinese WinXP LIKE comparison bug');
 CheckAction(MainTest, 'Main test of string test');
end;


initialization
  UnitTestStringTest := TUnitTestStringTest.Create(UnitTestList);

finalization
  UnitTestStringTest.Free;
end.

