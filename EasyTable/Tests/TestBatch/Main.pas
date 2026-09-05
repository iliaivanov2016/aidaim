unit Main;

interface

{DEFINE MEM_CHECK}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, StdCtrls, ExtCtrls, EasyTable, Grids, DBGrids, DBCtrls, DBTables,
  Variants
  {$IFDEF MEM_CHECK}
  ,MemCheck
  {$ENDIF}
  ,Unit2;

type
  TMainForm = class(TForm)
    Info: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    TestDS: TEasyTable;
    EasyDatabase1: TEasyDatabase;
    procedure Button1Click(Sender: TObject);
    procedure TestDSCalcFields(DataSet: TDataSet);
    procedure testDSFilterRecord(DataSet: TDataSet; var Accept: Boolean);
  private
    { Private declarations }
    function CreateTable : String;
    function InsertRecord : String;
    function EditRecord : String;
    function DeleteRecord : String;
    function InsertEditNavigation : String;
    function CheckIndexes : String;
    function CreateIndexes : String;
    function UseIndexes : String;
    function InsertWhenIndexes : String;
    function DeleteIndexes : String;
    function Find(bUseIndexes : boolean) : String;
    function Locate : String;
    function RecNo : String;
    function Lookup : String;
    function ThreadTest: String;

  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.DFM}
//------------------------------------------------------------------------------
// execute all tests
//------------------------------------------------------------------------------
procedure TMainForm.Button1Click(Sender: TObject);
var
  log: string;
begin
{$IFDEF MEM_CHECK}
 MemChk;
{$ENDIF}
 DateSeparator := '.';
 // create table c:\temp\test.dat
 Info.Lines.Text := Info.Lines.Text+'Create table: ';
 Info.Lines.Text := Info.Lines.Text + CreateTable();
 Application.ProcessMessages;

 // open table
 Info.Lines.Text := Info.Lines.Text+'Open table: ';
 TestDS.Active := true;
 Info.Lines.Text := Info.Lines.Text+'Ok'+chr(13)+chr(10);
 Application.ProcessMessages;
 // insert record
 Info.Lines.Text := Info.Lines.Text+'Insert record: ';
 Info.Lines.Text := Info.Lines.Text + InsertRecord();
Application.ProcessMessages;

 // edit record
 Info.Lines.Text := Info.Lines.Text+'Edit record: ';
 Info.Lines.Text := Info.Lines.Text + EditRecord();
Application.ProcessMessages;

 // delete record
 Info.Lines.Text := Info.Lines.Text+'Delete record: ';
 Info.Lines.Text := Info.Lines.Text + DeleteRecord();
Application.ProcessMessages;

 // insert&navigation&edit record
 Info.Lines.Text := Info.Lines.Text+'Insert&Navigation&Edit: ';
 Info.Lines.Text := Info.Lines.Text + InsertEditNavigation();
Application.ProcessMessages;

 // create indexes
 TestDS.DeleteAllIndexes();
 Info.Lines.Text := Info.Lines.Text+'Delete all indexes: Ok'+#13#10;
 Application.ProcessMessages;

 Info.Lines.Text := Info.Lines.Text+'Insert&Navigation&Edit (w/o indexes): ';
 Info.Lines.Text := Info.Lines.Text + InsertEditNavigation();
Application.ProcessMessages;

 Info.Lines.Text := Info.Lines.Text+'Create indexes: ';
 Info.Lines.Text := Info.Lines.Text + CreateIndexes();
Application.ProcessMessages;

 // insert record
 Info.Lines.Text := Info.Lines.Text+'Insert record with indexes: ';
 Info.Lines.Text := Info.Lines.Text + InsertRecord();
Application.ProcessMessages;

 // use indexes
 Info.Lines.Text := Info.Lines.Text+'Use indexes: ';
 Info.Lines.Text := Info.Lines.Text + UseIndexes();
Application.ProcessMessages;

 // insert record
 Info.Lines.Text := Info.Lines.Text+'Insert record with indexes: ';
 Info.Lines.Text := Info.Lines.Text + InsertRecord();
Application.ProcessMessages;


 // edit record
 Info.Lines.Text := Info.Lines.Text+'Edit record with indexes: ';
 Info.Lines.Text := Info.Lines.Text + EditRecord();
Application.ProcessMessages;

 // delete record
 Info.Lines.Text := Info.Lines.Text+'Delete record with indexes: ';
 Info.Lines.Text := Info.Lines.Text + DeleteRecord();
Application.ProcessMessages;

 // use indexes
 Info.Lines.Text := Info.Lines.Text+'Use indexes after delete: ';
 Info.Lines.Text := Info.Lines.Text + UseIndexes();
Application.ProcessMessages;

 // insert when index is used
 Info.Lines.Text := Info.Lines.Text+'Insert when indexes: ';
 Info.Lines.Text := Info.Lines.Text + InsertWhenIndexes();
Application.ProcessMessages;

 // use index after insertion
 Info.Lines.Text := Info.Lines.Text+'Use index after insert: ';
 Info.Lines.Text := Info.Lines.Text + UseIndexes();
Application.ProcessMessages;

 // check indexes
 Info.Lines.Text := Info.Lines.Text+'Checking indexes: ';
 Info.Lines.Text := Info.Lines.Text + CheckIndexes();
Application.ProcessMessages;

 // find with index
 Info.Lines.Text := Info.Lines.Text+'Find (with index): ';
 Info.Lines.Text := Info.Lines.Text + Find(true);
Application.ProcessMessages;

 // locate with index
 Info.Lines.Text := Info.Lines.Text+'Locate (with index): ';
 Info.Lines.Text := Info.Lines.Text + Locate;
Application.ProcessMessages;

 // recno with index
 Info.Lines.Text := Info.Lines.Text+'RecNo (with index): ';
 Info.Lines.Text := Info.Lines.Text + RecNo;
Application.ProcessMessages;

 // lookup with index
 Info.Lines.Text := Info.Lines.Text+'Lookup (with index): ';
 Info.Lines.Text := Info.Lines.Text + Lookup;
Application.ProcessMessages;

 // delete index
 Info.Lines.Text := Info.Lines.Text+'Delete indexes: ';
 Info.Lines.Text := Info.Lines.Text + DeleteIndexes();
Application.ProcessMessages;

 // find without index
 Info.Lines.Text := Info.Lines.Text+'Find (without index): ';
 Info.Lines.Text := Info.Lines.Text + Find(false);
Application.ProcessMessages;
 // create indexes
 Info.Lines.Text := Info.Lines.Text+'Create indexes: ';
 Info.Lines.Text := Info.Lines.Text + CreateIndexes();
Application.ProcessMessages;

 // use indexes
 Info.Lines.Text := Info.Lines.Text+'Use indexes: ';
 Info.Lines.Text := Info.Lines.Text + UseIndexes();
Application.ProcessMessages;

 // close table
 Info.Lines.Text := Info.Lines.Text+'Close table: ';
 TestDS.Active := false;
 Info.Lines.Text := Info.Lines.Text+'Ok'+chr(13)+chr(10);
Application.ProcessMessages;

 // re-open table
 Info.Lines.Text := Info.Lines.Text+'Re-open table: ';
 TestDS.Active := true;
 Info.Lines.Text := Info.Lines.Text+'Ok'+chr(13)+chr(10);
Application.ProcessMessages;

 // use indexes
 Info.Lines.Text := Info.Lines.Text+'Use indexes:';
 Info.Lines.Text := Info.Lines.Text + UseIndexes();
Application.ProcessMessages;

 // close table
 Info.Lines.Text := Info.Lines.Text+'Close table: ';
 TestDS.Active := false;
 Info.Lines.Text := Info.Lines.Text+'Ok'+chr(13)+chr(10);
Application.ProcessMessages;

 // RepairDatabase
 Info.Lines.Text := Info.Lines.Text+'Repair Database: ';
 EasyDatabase1.Connected := false;
 if (EasyDatabase1.RepairDatabase(log)) then
  Info.Lines.Text := Info.Lines.Text+'Ok:'+log+chr(13)+chr(10)
 else
  Info.Lines.Text := Info.Lines.Text+log+chr(13)+chr(10);
 Application.ProcessMessages;

 // RenameDatabase
 Info.Lines.Text := Info.Lines.Text+'Rename Database: ';
 EasyDatabase1.Connected := false;
 if (EasyDatabase1.RenameDatabase('test2.edb')) then
  Info.Lines.Text := Info.Lines.Text+'Ok'+chr(13)+chr(10)
 else
  Info.Lines.Text := Info.Lines.Text+'Error'+chr(13)+chr(10);
Application.ProcessMessages;

 // DeleteDatabase
 Info.Lines.Text := Info.Lines.Text+'Delete Database: ';
 EasyDatabase1.Connected := false;
 try
  EasyDatabase1.DeleteDatabase;
  if (not FileExists('s:\temp\test2.edb')) then
   Info.Lines.Text := Info.Lines.Text+'Ok:'+log+chr(13)+chr(10)
  else
   raise Exception.Create('');
 except
  Info.Lines.Text := Info.Lines.Text+'Error'+chr(13)+chr(10);
 end;
Application.ProcessMessages;

 // Thread-safety test
 Info.Lines.Text := Info.Lines.Text+'Multi-thread: ';
 EasyDatabase1.Connected := false;
 try
  Info.Lines.Text := Info.Lines.Text + ThreadTest();
 except
  Info.Lines.Text := Info.Lines.Text+'Error'+chr(13)+chr(10);
 end;
Application.ProcessMessages;

 Info.Lines.Text := Info.Lines.Text+chr(13)+chr(10);
end;

//------------------------------------------------------------------------------
// create table with 1 field of each type
//------------------------------------------------------------------------------
function TMainForm.CreateTable():string;
begin
 try
  EasyDatabase1.CreateDatabase;
  with TestDS do
	       begin
			with FieldDefs do
				begin
				Clear;
				Add('id',ftAutoInc,0,True);
				Add('BLOB_field',ftBlob,0,False);
				Add('int_field',ftInteger,0,false);
				Add('datetime_field',ftDateTime,0,False);
				Add('string_field',ftString,300,False);
				Add('float_field',ftFloat,0,False);
				Add('bool field',ftBoolean,0,False);
				Add('wide_string_field',ftWideString,10,False);
 				end;
			with IndexDefs do
				begin
				Clear;
				Add('id_index','id',[ixPrimary,ixUnique]);
				Add('intstring_index','int_field;string_field',[ixDescending,ixCaseInsensitive]);
				end;
				CreateTable;
 	       end;
 if (TestDS.Exists) then
  result := 'Ok'+chr(13)+chr(10)
 else
  result := 'after table created Exists=false'+chr(13)+chr(10);
 except
  result := 'Exception'+chr(13)+chr(10);
 end;
end;


//------------------------------------------------------------------------------
// insert 1 record
//------------------------------------------------------------------------------
function TMainForm.InsertRecord;
var stream : TStream;
    buf : PChar;
    size,i : integer;
    dt : TDateTime;
    recCount : integer;
begin
 recCount := TestDS.RecordCount;
 TestDS.Insert;
 TestDS.FieldByName('int_field').AsInteger := 10;
 TestDS.FieldByName('string_field').AsString := 'test string';
 TestDS.FieldByName('float_field').AsFloat := 1.1;
 TestDS.FieldByName('bool field').AsBoolean := true;
 TestDS.FieldByName('wide_string_field').AsString := '012345';
 dt := Now;
 TestDS.FieldByName('datetime_field').AsDateTime := dt;
 TestDS.Post;
 // BLOB
 try
 TestDS.Edit;

 stream := TestDS.CreateBlobStream(TestDS.FieldByName('blob_field'),bmReadwRITE);
 size := 1000;
 buf := AllocMem(size*sizeOf(integer));
 for i := 1 to size do
  pInteger(buf + (i-1)*sizeof(integer))^ := $7FFFFFFF;
 stream.Size := 0;
 stream.Seek(0,soFromBeginning);
 stream.WriteBuffer(buf^,size*sizeof(integer));
// TestDS.CloseBlob(TestDS.FieldByName('blob_field'));
 FreeMem(buf);

 TestDS.Post;
 stream.Free;
 except
  result := 'Update record with blob field'+chr(13)+chr(10);
  exit;
 end;

 if (TestDS.FieldByName('int_field').AsInteger <> 10) then
  result := result + 'int_field: read value != written value';
 if (TestDS.FieldByName('string_field').AsString <> 'test string') then
  result := result + 'string_field: read value != written value';
 if (abs(TestDS.FieldByName('float_field').AsFloat - 1.1) > 0.0001) then
  result := result + 'float_field: read value != written value';
 if (TestDS.FieldByName('datetime_field').AsDateTime <> dt) then
  result := result + 'datetime_field: read value != written value';

 if (TestDS.RecordCount <> recCount+1) then
  result := ' RecordCount was not changed ';

 if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;


//------------------------------------------------------------------------------
// edit record
//------------------------------------------------------------------------------
function TMainForm.EditRecord;
var stream : TStream;
    buf : PChar;
    size,i : integer;
    dt : TDateTime;
begin
 TestDS.Edit;
 TestDS.FieldByName('int_field').AsInteger := 100;
 TestDS.FieldByName('string_field').AsString := 'test edit string';
 TestDS.FieldByName('float_field').AsFloat := 10.1;
 dt := StrToDateTime('01.01.2000');
 TestDS.FieldByName('datetime_field').AsDateTime := dt;
 TestDS.FieldByName('wide_string_field').AsString := '';
 TestDS.Post;
 // BLOB
 try
 TestDS.Edit;
 stream := TestDS.CreateBlobStream(TestDS.FieldByName('blob_field'),bmReadWrite);
 size := 1000;
 buf := AllocMem(size*sizeOf(integer));
 for i := 1 to size do
  pInteger(buf + (i-1)*sizeof(integer))^ := $7FFFFFFF;
 stream.Size := 0;
 stream.Seek(0,soFromBeginning);
 stream.WriteBuffer(buf^,size*sizeof(integer));
// TestDS.CloseBlob(TestDS.FieldByName('blob_field'));
 FreeMem(buf);
 TestDS.Post;
 stream.Free;
 except
  result := 'Exception while BLOB stream is being opened'+chr(13)+chr(10);
  exit;
 end;
 if (TestDS.FieldByName('int_field').AsInteger <> 100) then
  result := result + ' int_field: read value != written value ';
 if (TestDS.FieldByName('string_field').AsString <> 'test edit string') then
  result := result + ' string_field: read value != written value ';
 if (abs(TestDS.FieldByName('float_field').AsFloat - 10.1) > 0.0001) then
  result := result + ' float_field: read value != written value ';
 if (TestDS.FieldByName('datetime_field').AsDateTime <> dt) then
  result := result + ' datetime_field: read value != written value ';

 try
 stream := TestDS.CreateBlobStream(TestDS.FieldByName('blob_field'),bmReadWrite);
 if (stream.size <> 1000*sizeof(integer)) then
  result := result + 'blob_field: read size != written size';
// TestDS.CloseBlob(TestDS.FieldByName('blob_field'));
 stream.Free;
 except
  result := 'Exception while BLOB stream is being opened'+chr(13)+chr(10);
  exit;
 end;

 if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;


//------------------------------------------------------------------------------
// delete record
//------------------------------------------------------------------------------
function TMainForm.DeleteRecord;
var recCount : integer;
begin
 recCount := TestDS.RecordCount;
 TestDS.Delete;
 if (TestDS.RecordCount <> recCount-1) then
  result := ' RecordCount was not changed ';
 if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;


//------------------------------------------------------------------------------
// inserts & edit & navigation
//------------------------------------------------------------------------------
function TMainForm.InsertEditNavigation;
var stream : TStream;
 i : integer;
begin
 // insert some records
 InsertRecord;
 InsertRecord;
 InsertRecord;


 // edit second record
 TestDS.First;
 TestDS.Next;

 EditRecord;
 // insert 4th record
 InsertRecord;
 TestDs.First;
 // insert 5tf record
 i := TestDS.RecordCount;
 TestDS.Append;
 TestDS.Post;
 if (TestDS.RecordCount <> i+1) then
  result := ' RecordCount was not changed - append failed!';

 //delete 5th record
 TestDS.Delete;

 if (TestDS.RecordCount <> i) then
  result := ' RecordCount was not changed - delete failed!';

 TestDS.First;
 try
  stream := TestDS.CreateBlobStream(TestDS.FieldByName('blob_field'),bmReadWrite);
  if (stream.size <> 1000*sizeof(integer)) then
   result := result + 'blob_field: read size != written size';
//  TestDS.CloseBlob(TestDS.FieldByName('blob_field'));
  stream.Free;

 except
  result := 'Exception during opening BLOB stream'+chr(13)+chr(10);
  exit;
 end;
 // check append record
 TestDS.AppendRecord([nil,105,nil,nil,nil,nil]);

 TestDS.Delete;

 TestDS.First;
 TestDS.Next;
 try
  stream := TestDS.CreateBlobStream(TestDS.FieldByName('blob_field'),bmReadWrite);
  if (stream.size <> 1000*sizeof(integer)) then
   result := result + 'blob_field: read size != written size';
//  TestDS.CloseBlob(TestDS.FieldByName('blob_field'));
  stream.Free;
 except
  result := 'Exception during opening BLOB stream'+chr(13)+chr(10);
  exit;
 end;


 if (TestDS.RecordCount <> i) then
  result := ' RecordCount was not changed - appendrecord failed!';


 // check second record values
 TestDS.First;
 TestDS.Next;
 if (TestDS.FieldByName('int_field').AsInteger <> 100) then
  result := result + ' int_field: read value != written value ';
 if (TestDS.FieldByName('string_field').AsString <> 'test edit string') then
  result := result + ' string_field: read value != written value ';
 if (abs(TestDS.FieldByName('float_field').AsFloat - 10.1) > 0.0001) then
  result := result + ' float_field: read value != written value ';

 try
  stream := TestDS.CreateBlobStream(TestDS.FieldByName('blob_field'),bmReadWrite);
  if (stream.size <> 1000*sizeof(integer)) then
   result := result + 'blob_field: read size != written size';
//  TestDS.CloseBlob(TestDS.FieldByName('blob_field'));
  stream.Free;
 except
  result := 'Exception during opening BLOB stream'+chr(13)+chr(10);
  exit;
 end;

 if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;


//------------------------------------------------------------------------------
// create indexes
//------------------------------------------------------------------------------
function TMainForm.CheckIndexes;
var i,code : integer;
begin
 result := '';
 for i := 0 to testDS.IndexDefs.Count-1 do
  begin
   code := testDS.CheckIndex(i);
    if (code >= 0) then
     begin
      result := result + 'Index "'+
        testDS.IndexDefs.Items[i].Name+'" is invalid, error code = '+
          inttostr(code)+'; ';

     end;
  end;
 if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;


//------------------------------------------------------------------------------
// create indexes
//------------------------------------------------------------------------------
function TMainForm.CreateIndexes;
var options : TIndexOptions;
begin
 options := [];
 TestDS.AddIndex('index1','int_field;string_field',options);

 options := [ixDescending, ixCaseInSensitive];
 TestDS.AddIndex('index2','string_field',options);

 options := [ixDescending];
 TestDS.AddIndex('index3','datetime_field',options);

 try
  options := [];
  TestDS.AddIndex('index4','int_field;datetime_field;string_field',options,'int_field;datetime_field','string_field');
 except
  result := ' AddIndex (5 params) raised exception'+chr(13)+chr(10);
  exit;
 end;

 options := [ixPrimary];
 TestDS.AddIndex('index5','id',options);

 result := 'Ok'+chr(13)+chr(10);
end;


//------------------------------------------------------------------------------
// use indexes
//------------------------------------------------------------------------------
function TMainForm.UseIndexes;
var prevStr : string;
    prevInt : integer;
    prevDT : TDateTime;
begin
 // int-up, string - up     lowercase field names
 TestDS.IndexFieldNames := 'int_field;string_field';
 // check records order
 TestDS.First;
 prevInt := TestDS.FieldByName('int_field').AsInteger;
 prevStr := TestDS.FieldByName('string_field').AsString;
 TestDS.Next;
 while (not TestDS.Eof) do
  begin
   if (TestDS.FieldByName('int_field').AsInteger < prevInt) then
   begin
    result := result + ' index1 (used IndexFieldNames, lowercase): wrong order ';
    break;
   end;
   if (TestDS.FieldByName('int_field').AsInteger = prevInt) then
    if (TestDS.FieldByName('string_field').AsString < prevStr) then
     begin
      result := result + ' index1 (used IndexFieldNames, lowercase): wrong order ';
      break;
     end;
   TestDS.Next;
  end;

 // int-up, string - up  uppercase field names
 TestDS.IndexFieldNames := 'INT_FIELD;STRING_FIELD';
 // check records order
 TestDS.First;
 prevInt := TestDS.FieldByName('int_field').AsInteger;
 prevStr := TestDS.FieldByName('string_field').AsString;
 TestDS.Next;
 while (not TestDS.Eof) do
  begin
   if (TestDS.FieldByName('int_field').AsInteger < prevInt) then
   begin
    result := result + ' index1 (used IndexFieldNames, uppercase): wrong order ';
    break;
   end;
   if (TestDS.FieldByName('int_field').AsInteger = prevInt) then
    if (TestDS.FieldByName('string_field').AsString < prevStr) then
     begin
      result := result + ' index1 (used IndexFieldNames, uppercase): wrong order ';
      break;
     end;
   TestDS.Next;
  end;

 // string - down, caseInsensitive
 TestDS.IndexName := 'index2';
 // check records order
 TestDS.First;
 prevStr := TestDS.FieldByName('string_field').AsString;
 TestDS.Next;
 while (not TestDS.Eof) do
  begin
    if (AnsiLowerCase(TestDS.FieldByName('string_field').AsString) > AnsiLowerCase(prevStr)) then
     begin
      result := result + ' index2: wrong order ';
      break;
     end;
   TestDS.Next;
  end;

 // datetime - down
 TestDS.IndexName := 'index3';
 // check records order
 TestDS.First;
 prevDT := TestDS.FieldByName('datetime_field').AsDateTime;
 TestDS.Next;
 while (not TestDS.Eof) do
  begin
    if (TestDS.FieldByName('datetime_field').AsDateTime > prevDT+StrToDateTime('00:00:02')) then
     begin
      result := result + ' index3: wrong order ';
      break;
     end;
   prevDT := TestDS.FieldByName('datetime_field').AsDateTime;
   TestDS.Next;
  end;

 // id - up - ixPrimary
 TestDS.IndexName := 'index5';
 // check records order
 TestDS.First;
 prevInt := TestDS.FieldByName('id').AsInteger;
 TestDS.Next;
 while (not TestDS.Eof) do
  begin
   if (TestDS.FieldByName('id').AsInteger < prevInt) then
   begin
    result := result + ' index5 (used IndexName): wrong order ';
    break;
   end;
   TestDS.Next;
  end;

  if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;


//------------------------------------------------------------------------------
// inserts when index used
//------------------------------------------------------------------------------
function TMainForm.InsertWhenIndexes;
begin

 TestDS.Insert;
 TestDS.FieldByName('int_field').AsInteger := 10;
 TestDS.FieldByName('string_field').AsString := 'aaa';
 TestDS.FieldByName('float_field').AsFloat := 1.1;
 TestDS.FieldByName('datetime_field').AsDateTime := Now;
 TestDS.Post;

 TestDS.Insert;
 TestDS.FieldByName('int_field').AsInteger := 10;
 TestDS.FieldByName('string_field').AsString := 'bbb';
 TestDS.FieldByName('float_field').AsFloat := 1.1;
 TestDS.FieldByName('datetime_field').AsDateTime := Now;
 TestDS.Post;

 TestDS.Insert;
 TestDS.FieldByName('int_field').AsInteger := 1;
 TestDS.FieldByName('string_field').AsString := 'test string';
 TestDS.FieldByName('float_field').AsFloat := 1.1;
 TestDS.FieldByName('datetime_field').AsDateTime := Now;
 TestDS.Post;

 if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;

//------------------------------------------------------------------------------
// delete indexes
//------------------------------------------------------------------------------
function TMainForm.DeleteIndexes;
begin
  TestDS.DeleteAllIndexes;
// TestDS.DeleteIndex('index1');
// TestDS.DeleteIndex('index2');
// TestDS.DeleteIndex('index3');
// TestDS.DeleteIndex('index4');
 result := 'Ok'+chr(13)+chr(10);
end;


//------------------------------------------------------------------------------
// find
//------------------------------------------------------------------------------
function TMainForm.Find;
var dt : TDateTime;
    i,j : integer;
begin
 // delete all records
  TestDS.Active := false;
 try
  TestDS.EmptyTable;
 except
  result := 'EmptyTable() raised an exception'+chr(13)+chr(10);
  exit;
 end;
 TestDS.Active := true;
 if (TestDS.RecordCount > 0) then
  begin
   result := 'EmptyTable() did not delete all records'+chr(13)+chr(10);
   exit;
  end;

 if (bUseIndexes) then
  TestDS.IndexName := 'index2';

 dt := StrToDateTime('01.01.2001 00:10:10');
 TestDS.Insert;
 TestDS.FieldByName('int_field').AsInteger := 10;
 TestDS.FieldByName('string_field').AsString := 'aaa';
 TestDS.FieldByName('float_field').AsFloat := 1.1;
 TestDS.FieldByName('datetime_field').AsDateTime := dt;
 TestDS.FieldByName('bool field').AsBoolean := true;
 TestDS.Post;

 TestDS.Insert;
 TestDS.FieldByName('int_field').AsInteger := 10;
 TestDS.FieldByName('string_field').AsString := 'bbb';
 TestDS.FieldByName('float_field').AsFloat := 1.1;
 TestDS.FieldByName('datetime_field').AsDateTime := dt;
 TestDS.FieldByName('bool field').AsBoolean := true;
 TestDS.Post;

 TestDS.Insert;
 TestDS.FieldByName('int_field').AsInteger := 100;
 TestDS.FieldByName('string_field').AsString := 'aaa';
// TestDS.FieldByName('float_field').AsFloat := 1.1;
 TestDS.FieldByName('datetime_field').AsDateTime := dt+StrToTime('00:00:01');
 TestDS.FieldByName('bool field').AsBoolean := false;
 TestDS.Post;

 TestDS.Insert;
 TestDS.FieldByName('int_field').AsInteger := 0;
 TestDS.FieldByName('string_field').AsString := 'bbaabb';
 TestDS.FieldByName('float_field').AsFloat := 1.1;
 TestDS.FieldByName('datetime_field').AsDateTime := dt+StrToTime('00:00:01');
 TestDS.Post;

 with TestDS do
  begin
   // id
   Filter := 'id = '+inttostr(TestDS.LastAutoIncValue-1);
   FilterOptions := [];
   if (not FindFirst) then
    result := result + Filter+': first not found ';
   if (FindNext) then
    result := result + Filter+': second found ';
   // id test for correct database
   if (bUseIndexes) then
    IndexName := 'index5';
   Filter := 'id > 0';
   FilterOptions := [];
   if (not FindFirst) then
    result := result + Filter+': first not found ';
   i := recNo;
   if (not FindLast) then
    result := result + Filter+': last not found ';
   j := recNo;
   if (j - i <= 0) then
    result := result + Filter+': j - i < 0. First = '+inttostr(i)+
      ', Last = '+inttostr(j);
   if (j - i <> RecordCount-1) then
    result := result + Filter+': j - i <> RecordCount-1. First = '+inttostr(i)+
      ', Last = '+inttostr(j)+', RecordCount = '+inttostr(RecordCount) ;


   // null
   Filter := '(float_field is null) and (int_field is not null)';
   FilterOptions := [];
   if (not FindFirst) then
    result := result + Filter+': first not found ';
   if (FindNext) then
    result := result + Filter+': second found ';

   // int
   Filter := 'int_field = 10 and (string_field="aaa" or string_field="bbb")';
   FilterOptions := [];
   if (not FindFirst) then
    result := result + ' int_field = 10: first not found ';
   if (not FindNext) then
    result := result + ' int_field = 10: 2nd not found ';
   if (FindNext) then
    result := result + ' int_field = 10: 3rd found ';

   // int
   Filter := 'string_field=''bbb'' and int_field = 10';
   FilterOptions := [];
   if (not FindFirst) then
    result := result + ' int_field = 10 and string_field="bbb": first not found ';

   Filter := 'int_field >= 100';
   if (not FindFirst) then
    result := result + ' int_field >= 100: first not found ';
   if (FindNext) then
    result := result + ' int_field >= 100: 2nd found ';

   // string
   Filter := 'string_field='+AnsiQuotedStr('AAA','''');
   FilterOptions := [foCaseInsensitive];
   if (not FindFirst) then
    result := result + ' string_field = AAA: first not found ';
   if (not FindNext) then
    result := result + ' string_field = AAA: 2nd not found ';

   Filter := 'string_field='+AnsiQuotedStr('aaa','''');
   FilterOptions := [];
   if (not FindFirst) then
    result := result + ' string_field = aaa: first not found ';

   Filter := 'string_field='+AnsiQuotedStr('AAA','''');
   FilterOptions := [];
   if (FindFirst) then
    result := result + ' case sensitive: string_field = AAA: first found ';

   Filter := 'string_field like '+AnsiQuotedStr('%_A%','''');
   FilterOptions := [foCaseInsensitive];
   if (not FindFirst) then
    result := result + ' string_field like AA: first not found ';
   if (not FindNext) then
    result := result + ' string_field like AA: 2nd not found ';
   if (not FindNext) then
    result := result + ' string_field like AA: 3rd not found ';
   Filter := 'string_field like '+AnsiQuotedStr('%AAA%','''');
   FilterOptions := [];
   if (FindFirst) then
    result := result + ' case sensitive:  string_field like AAA: first found ';

   // bool
   Filter := '[bool field]=true';
//   FilterOptions := [foCaseInsensitive];
   if (not FindFirst) then
    result := result + ' bool field = true: first not found ';
   if (not FindNext) then
    result := result + ' bool field = true: 2nd not found ';
   if (FindNext) then
    result := result + ' bool field = true: 3rd found ';

   // datetime
   Filter := 'datetime_field="'+DateTimeToStr(dt)+'"';
   FilterOptions := [];
   if (not FindFirst) then
     result := result + ', datetime_field = dt: first not found ';
   if (not FindNext) then
    result := result + ', datetime_field = dt: 2nd not found ';
   if (FindNext) then
    result := result + ', datetime_field = dt: 3rd found ';
//ShowMessage(testds.filter);
   Filter := 'datetime_field>'''+DateTimeToStr(dt)+'''';
   if (not FindFirst) then
    result := result + ', datetime_field > dt: first not found ';
   if (not FindNext) then
    result := result + ', datetime_field > dt: 2nd not found ';
   if (FindNext) then
    result := result + ', datetime_field > dt: 3rd found ';
  end;
 if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;

//------------------------------------------------------------------------------
// Test Locate() method
//------------------------------------------------------------------------------
function TMainForm.Locate : String;
var v : variant;
    fields1 : String;
    options : TLocateOptions;
begin
 with TestDS do
  begin
   // int
   First;
   fields1 := 'int_field';
   v := 10;
   if (not Locate(fields1,v,options)) then
    result := result + ' int_field = 10: first not found; ';
   // string
   First;
   fields1 := 'string_field';
   v := 'bbb';
   if (not Locate(fields1,v,options)) then
    result := result + ' string_field = "bbb": first not found; ';
   // int, string
   First;
   options := [loCaseInsensitive, loPartialKey];
   fields1 := 'int_field,string_field';
   v := VarArrayCreate([0, 1], varVariant);
   v[0] := 10;
   v[1] := 'bbb';
//debugFlag := true;
   if (not Locate(fields1,v,options)) then
    result := result + '# int_field = 10, string_field="bbb": first not found; ';
//debugFlag := false;
   // datetime
   First;
   fields1 := 'datetime_field';
   v := StrToDateTime('01.01.2001 00:10:10');
   if (not Locate(fields1,v,options)) then
    result := result + ' datetime_field: first not found; ';
  end;
 if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;

//------------------------------------------------------------------------------
// Test RecNo property
//------------------------------------------------------------------------------
function TMainForm.RecNo : String;
var oldRecNo: Cardinal;
begin
 with TestDS do
  begin
   First;
   Next;
   oldRecNo := RecNo;
   RecNo := RecordCount;
   if (RecNo <> RecordCount) then
    result := result + ' RecNo does not moves to last record ';
   RecNo := 1;
   if (RecNo <> 1) then
    result := result + ' RecNo does not moves to first record ';
   RecNo := oldRecNo;
   if (RecNo <> oldRecNo) then
    result := result + ' RecNo does not moves to specified record ';
  end;
 if (result = '') then
  result := result + 'Ok';
end; // RecNo


//------------------------------------------------------------------------------
// Test Lookup() method
//------------------------------------------------------------------------------
function TMainForm.Lookup : String;
var v : variant;
    fields1 : String;
    fields2 : String;
begin
 with TestDS do
  begin
   // int
   Last;
   fields1 := 'int_field';
   fields2 := 'string_field';
   v := 0;
   v := Lookup(fields1,v,fields2);
   if (VarType(v) = varBoolean) then
    begin
     if (v = false) then
      result := result + ' int_field = 10: first not found; '
    end
   else
    if (v = 'bbb') then
     result := result + ' result field: string_field = "bbb"; ';
   if (RecNo <> 4) then
    result := result + ' int_field = 10: record pointer moved; ';
  end;
 if (result = '') then
  result := result + 'Ok';

 result := result+chr(13)+chr(10);
end;

procedure TMainForm.TestDSCalcFields(DataSet: TDataSet);
begin
 TestDS.FieldByName('calc1').AsInteger := TestDS.FieldByName('int_field').AsInteger * 2;
end;

procedure TMainForm.testDSFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
// Accept := TestDS.fieldByName('int_field').asInteger = 10;
end;

function TMainForm.ThreadTest: String;
var
 t1: TestThread1;
 i: integer;
begin

 try
  for i:=0 to 100 do
   t1 := TestThread1.Create(False);
  Result := 'Ok';
 except
  on E: Exception do
   begin
    Result := E.Message;
   end;
 end;

end;

end.
