unit uMain;

interface

{$IFDEF VER200}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

uses
  Windows, Messages, SysUtils,
//  Variants,
  Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Grids, DBGrids, DB,
  SQLMemMain, SQLMemTypes, SQLMemConst,
  DBCtrls, StdCtrls;

type
  TForm1 = class(TForm)
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    Panel1: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    Panel3: TPanel;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    bnLoadDB: TButton;
    bnSaveDB: TButton;
    bnClose: TButton;
    db: TSQLMemDatabase;
    tDept: TSQLMemTable;
    tEmp: TSQLMemTable;
    procedure FormCreate(Sender: TObject);
    procedure bnCloseClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure bnLoadDBClick(Sender: TObject);
    procedure bnSaveDBClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1:        TForm1;
  TempDir:      AnsiString;
  SaveFileName: AnsiString;

implementation

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
 TempDir := IncludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
 SaveFileName := TempDir+'memory_database.acr';
 db.InMemory := True;
 db.DatabaseName := 'MemDBLoadSave';
 db.CreateDatabase;
 db.Open;
 tEmp.DatabaseName := db.DatabaseName;
 tDept.DatabaseName := db.DatabaseName;
 tEmp.TableName := 'emp';
 tDept.TableName := 'dept';
 tDept.FieldDefs.Clear;
 tDept.AdvFieldDefs.Clear;
 tDept.AdvFieldDefs.Add('ID',aftAutoInc);
 tDept.AdvFieldDefs.Add('Name',aftChar,50);
 tDept.IndexDefs.Clear;
 tDept.IndexDefs.Add('PK','ID,Name',[ixPrimary]);
 tDept.ForeignKeyDefs.Clear;
 tDept.CreateTable;
 tDept.Open;

 tEmp.FieldDefs.Clear;
 tEmp.AdvFieldDefs.Clear;
 tEmp.AdvFieldDefs.Add('ID',aftAutoInc);
 tEmp.AdvFieldDefs.Add('Name',aftChar,50);
 tEmp.AdvFieldDefs.Add('Surname',aftChar,50);
 tEmp.AdvFieldDefs.Add('DeptID',aftInteger);
 tEmp.AdvFieldDefs.Add('DeptName',aftChar,50);
 tEmp.AdvFieldDefs.Find('DeptID').DefaultValue.AsInteger := -1;
 tEmp.AdvFieldDefs.Find('DeptName').DefaultValue.AsString := 'UNKNOWN DEPARTMENT';
 tEmp.IndexDefs.Clear;
 tEmp.IndexDefs.Add('PK','ID',[ixPrimary]);
 tEmp.IndexDefs.Add('FK','DeptID,DeptName',[]);
 tEmp.ForeignKeyDefs.Clear;
 tEmp.ForeignKeyDefs.Add('FK_DeptID','DeptID,DeptName','dept',
                         fkmtFull,fkaCascade,fkaCascade);
 tEmp.CreateTable;
 tEmp.Open;

 tDept.Insert;
 tDept.FieldByName('Name').AsString := 'Development Department';
 tDept.Post;
 tDept.Insert;
 tDept.FieldByName('Name').AsString := 'Technical Support Team';
 tDept.Post;
 tDept.Insert;
 tDept.FieldByName('Name').AsString := 'Sales Department';
 tDept.Post;
 tDept.Insert;
 tDept.FieldByName('ID').AsInteger := -1;
 tDept.FieldByName('Name').AsString := 'UNKNOWN DEPARTMENT';
 tDept.Post;

 tEmp.Insert;
 tEmp.FieldByName('Name').AsString := 'Leo';
 tEmp.FieldByName('Surname').AsString := 'Martin';
 tEmp.FieldByName('DeptID').AsInteger := 1;
 tEmp.FieldByName('DeptName').AsString := 'Development Department';
 tEmp.Post;

 tEmp.Insert;
 tEmp.FieldByName('Name').AsString := 'Richard';
 tEmp.FieldByName('Surname').AsString := 'Watson';
 tEmp.FieldByName('DeptID').AsInteger := 1;
 tEmp.FieldByName('DeptName').AsString := 'Development Department';
 tEmp.Post;

 tEmp.Insert;
 tEmp.FieldByName('Name').AsString := 'Garry';
 tEmp.FieldByName('Surname').AsString := 'Robinson';
 tEmp.FieldByName('DeptID').AsInteger := 1;
 tEmp.FieldByName('DeptName').AsString := 'Development Department';
 tEmp.Post;

 tEmp.Insert;
 tEmp.FieldByName('Name').AsString := 'Alex';
 tEmp.FieldByName('Surname').AsString := 'Lambert';
 tEmp.FieldByName('DeptID').AsInteger := 1;
 tEmp.FieldByName('DeptName').AsString := 'Development Department';
 tEmp.Post;

 tEmp.Insert;
 tEmp.FieldByName('Name').AsString := 'Fred';
 tEmp.FieldByName('Surname').AsString := 'Bolt';
 tEmp.FieldByName('DeptID').AsInteger := 1;
 tEmp.FieldByName('DeptName').AsString := 'Development Department';
 tEmp.Post;

 tEmp.Insert;
 tEmp.FieldByName('Name').AsString := 'Ray';
 tEmp.FieldByName('Surname').AsString := 'Lahoy';
 tEmp.FieldByName('DeptID').AsInteger := 2;
 tEmp.FieldByName('DeptName').AsString := 'Technical Support Team';
 tEmp.Post;

 tEmp.Insert;
 tEmp.FieldByName('Name').AsString := 'Ella';
 tEmp.FieldByName('Surname').AsString := 'Perelman';
 tEmp.FieldByName('DeptID').AsInteger := 3;
 tEmp.FieldByName('DeptName').AsString := 'Sales Department';
 tEmp.Post;

 tEmp.Insert;
 tEmp.FieldByName('Name').AsString := 'John';
 tEmp.FieldByName('Surname').AsString := 'Smith';
 tEmp.FieldByName('DeptID').AsInteger := 3;
 tEmp.FieldByName('DeptName').AsString := 'Sales Department';
 tEmp.Post;

 tEmp.IndexName := 'FK';
 tEmp.MasterSource := DataSource1;
 tEmp.MasterFields := 'ID;Name';
 tDept.First;
 bnSaveDBClick(Self);
end;

procedure TForm1.bnCloseClick(Sender: TObject);
begin
 Close();
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 db.Close();
 db.DeleteDatabase();
end;

procedure TForm1.bnLoadDBClick(Sender: TObject);
begin
  db.LoadDatabaseFromFile(SaveFileName);
  ShowMessage('DB loaded from: '+#13#10+SaveFileName);
end;

procedure TForm1.bnSaveDBClick(Sender: TObject);
begin
  db.SaveDatabaseToFile(SaveFileName,'',caZLIB,9,2*1024*1024);
  ShowMessage('DB saved to: '+#13#10+SaveFileName);
end;

end.
