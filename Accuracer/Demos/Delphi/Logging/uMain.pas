unit uMain;

interface

uses
  Windows, Messages, SysUtils,
  {$IFDEF VER140}
  Variants,
  {$ENDIF}
  Classes, Graphics, Controls, Forms,
  Dialogs, DBCtrls, Grids, DBGrids, ACRMain, DB, StdCtrls, ComCtrls,
  ExtCtrls, ACRVariant;

type
  TfmMain = class(TForm)
    TestTable: TACRTable;
    ACRQuery1: TACRQuery;
    LogTable: TACRTable;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    GroupBox2: TGroupBox;
    DataSource1: TDataSource;
    ACRDatabase1: TACRDatabase;
    DBGridLog: TDBGrid;
    DBNavigator1: TDBNavigator;
    Button4: TButton;
    DBMemoSQL: TDBMemo;
    Splitter1: TSplitter;
    Button5: TButton;
    procedure Button3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ACRDatabase1AfterInsertRecord(Sender: TACRDataSet;
      const TableName: String; const FieldValues: TACRArrayOfTACRVariant);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure ACRDatabase1BeforeInsertRecord(Sender: TACRDataSet;
      const TableName: String; const FieldValues: TACRArrayOfTACRVariant;
      var Abort: Boolean);
    procedure ACRDatabase1AfterUpdateRecord(Sender: TACRDataSet;
      const TableName: String; const OldFieldValues,
      NewFieldValues: TACRArrayOfTACRVariant);
    procedure ACRDatabase1AfterDeleteRecord(Sender: TACRDataSet;
      const TableName: String; const FieldValues: TACRArrayOfTACRVariant);
    procedure ACRDatabase1AfterExecuteSQL(Sender: TACRQuery);
    procedure ACRDatabase1BeforeExecuteSQL(Sender: TACRQuery;
      var Abort: Boolean);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.Button3Click(Sender: TObject);
begin
 Close();
 Application.Terminate();
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
  ACRDatabase1.DatabaseFileName := ExtractFilePath(Application.ExeName)+'test.adb';
  if (not ACRDatabase1.Exists) then
   ACRDatabase1.CreateDatabase();
  ACRDatabase1.Open();
  if (not LogTable.Exists) then
   LogTable.CreateTable();
  LogTable.Open();
  if (not TestTable.Exists) then
   TestTable.CreateTable();
end;

procedure TfmMain.Button1Click(Sender: TObject);
begin
 if (not TestTable.Active) then
  TestTable.Open();
 TestTable.Insert();
 TestTable.FieldByName('ID').AsInteger := Random(MaxInt);
 TestTable.FieldByName('Str').AsString := 'Table Test!!! '+IntToStr(Random(MaxInt));
 TestTable.Post();
 TestTable.Edit();
 TestTable.FieldByName('ID').AsInteger := -TestTable.FieldByName('ID').AsInteger;
 TestTable.FieldByName('Str').AsString := 'Table Test - record updated!!! '+IntToStr(Random(MaxInt));
 TestTable.Post();
 TestTable.Delete();
 TestTable.Close();
end;

procedure TfmMain.ACRDatabase1AfterInsertRecord(Sender: TACRDataSet;
  const TableName: String; const FieldValues: TACRArrayOfTACRVariant);
var et: String;
begin
 if (AnsiUpperCase(TableName) = AnsiUpperCase(LogTable.TableName)) then
  Exit;
 if (Sender is TACRTable) then
  et := 'BY Table'
 else
  et := 'BY Query';
 LogTable.Insert();
 LogTable.FieldByName('EventTime').AsDateTime := Now;
 LogTable.FieldByName('EventType').AsString := 'Insert '+et;
 LogTable.FieldByName('TableName').AsString := TableName;
 LogTable.FieldByName('NewIDValue').AsInteger := FieldValues[0].AsInteger;
 LogTable.FieldByName('NewStrValue').AsString := FieldValues[1].AsString;
 LogTable.Post();
end;

procedure TfmMain.Button2Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := 'INSERT INTO Test VALUES ('+IntToStr(Random(MaxInt))+', '+
                       AnsiQuotedStr('Query Test!!! '+IntToStr(Random(MaxInt)),'''')+
                       ');';
 ACRQuery1.ExecSQL();

 ACRQuery1.SQL.Text := 'UPDATE Test SET ID = -ID, Str = Str + "Updated By SQL!!!";';
 ACRQuery1.ExecSQL();

 ACRQuery1.SQL.Text := 'DELETE FROM Test WHERE Str LIKE "%Updated%";';
 ACRQuery1.ExecSQL();

 ACRQuery1.RequestLive := True;
 ACRQuery1.SQL.Text := 'SELECT * FROM Test';
 ACRQuery1.Open();
 ACRQuery1.InsertRecord([Random(MaxInt),'Insert By Live Query']);
 ACRQuery1.Edit();
 ACRQuery1.Fields[0].AsInteger := 0;
 ACRQuery1.Fields[1].AsString := 'Live edit by query!!!';
 ACRQuery1.Post();

 ACRQuery1.Delete();
 ACRQuery1.Close();
 ACRQuery1.RequestLive := False;
end;

procedure TfmMain.Button4Click(Sender: TObject);
begin
 if (not TestTable.Active) then
  TestTable.Open();
 TestTable.Insert();
 TestTable.FieldByName('ID').AsInteger := Random(MaxInt);
 TestTable.FieldByName('Str').AsString := 'Block';
 try
  TestTable.Post();
 except
  TestTable.Cancel();
  raise;
 end;
 TestTable.Close();
end;

procedure TfmMain.ACRDatabase1BeforeInsertRecord(Sender: TACRDataSet;
  const TableName: String; const FieldValues: TACRArrayOfTACRVariant;
  var Abort: Boolean);
begin
 if (AnsiUpperCase(TableName) = AnsiUpperCase(LogTable.TableName)) then
  Exit;
 Abort := (FieldValues[1].AsString = 'Block');
end;

procedure TfmMain.ACRDatabase1AfterUpdateRecord(Sender: TACRDataSet;
  const TableName: String; const OldFieldValues,
  NewFieldValues: TACRArrayOfTACRVariant);
var et: String;
begin
 if (AnsiUpperCase(TableName) = AnsiUpperCase(LogTable.TableName)) then
   Exit;
 if (Sender is TACRTable) then
  et := 'BY Table'
 else
  et := 'BY Query';
 LogTable.Insert();
 LogTable.FieldByName('EventTime').AsDateTime := Now;
 LogTable.FieldByName('EventType').AsString := 'Update '+et;
 LogTable.FieldByName('TableName').AsString := TableName;
 LogTable.FieldByName('NewIDValue').AsInteger := NewFieldValues[0].AsInteger;
 LogTable.FieldByName('NewStrValue').AsString := NewFieldValues[1].AsString;
 LogTable.FieldByName('IDValue').AsInteger := OldFieldValues[0].AsInteger;
 LogTable.FieldByName('StrValue').AsString := OldFieldValues[1].AsString;
 LogTable.Post();
end;

procedure TfmMain.ACRDatabase1AfterDeleteRecord(Sender: TACRDataSet;
  const TableName: String; const FieldValues: TACRArrayOfTACRVariant);
var et: String;
begin
 if (AnsiUpperCase(TableName) = AnsiUpperCase(LogTable.TableName)) then
   Exit;
 if (Sender is TACRTable) then
  et := 'BY Table'
 else
  et := 'BY Query';
 LogTable.Insert();
 LogTable.FieldByName('EventTime').AsDateTime := Now;
 LogTable.FieldByName('EventType').AsString := 'Delete '+et;
 LogTable.FieldByName('TableName').AsString := TableName;
 LogTable.FieldByName('IDValue').AsInteger := FieldValues[0].AsInteger;
 LogTable.FieldByName('StrValue').AsString := FieldValues[1].AsString;
 LogTable.Post();
end;

procedure TfmMain.ACRDatabase1AfterExecuteSQL(Sender: TACRQuery);
begin
 LogTable.Insert();
 LogTable.FieldByName('EventTime').AsDateTime := Now;
 LogTable.FieldByName('EventType').AsString := 'Execute SQL';
 LogTable.FieldByName('SQL').AsString := Sender.SQL.Text;
 LogTable.Post();
end;

procedure TfmMain.ACRDatabase1BeforeExecuteSQL(Sender: TACRQuery;
  var Abort: Boolean);
begin
 Abort := (Pos(AnsiUpperCase(LogTable.TableName),AnsiUpperCase(Sender.SQL.Text)) > 0);
end;

procedure TfmMain.Button5Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := 'SELECT * FROM Log';
 ACRQuery1.Open;
end;

end.
