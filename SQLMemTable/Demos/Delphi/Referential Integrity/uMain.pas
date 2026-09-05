unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, DBCtrls, Grids, DBGrids, StdCtrls, ComCtrls, DB,
  SQLMemTypes, SQLMemMain;

type
  TForm1 = class(TForm)
    dsDept: TDataSource;
    dsEmp: TDataSource;
    Panel1: TPanel;
    GroupBox1: TGroupBox;
    Panel2: TPanel;
    Button1: TButton;
    reSQL: TRichEdit;
    dbgDept: TDBGrid;
    DBNavigator3: TDBNavigator;
    Splitter1: TSplitter;
    GroupBox2: TGroupBox;
    DBNavigator2: TDBNavigator;
    dbgEmp: TDBGrid;
    bnExec: TButton;
    tDept: TSQLMemTable;
    tEmp: TSQLMemTable;
    SQLMemQuery1: TSQLMemQuery;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure bnExecClick(Sender: TObject);
    procedure tDeptAfterPost(DataSet: TDataSet);
    procedure tDeptAfterDelete(DataSet: TDataSet);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
 Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
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
 tEmp.ForeignKeyDefs.Clear;
 tEmp.ForeignKeyDefs.Add('FK_DeptID','DeptID,DeptName','Dept',
                         fkmtFull,fkaCascade,fkaCascade);
 tEmp.CreateTable;
 tEmp.Open;

 dbgDept.Columns[0].Width := 55;
 dbgDept.Columns[1].Width := 160;

 dbgEmp.Columns[0].Width := 55;
 dbgEmp.Columns[1].Width := 90;
 dbgEmp.Columns[2].Width := 90;
 dbgEmp.Columns[3].Width := 55;
 dbgEmp.Columns[4].Width := 150;

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


 tEmp.First;
 tDept.First;

 reSQL.Lines.Add('-- Dept table');
 reSQL.Lines.Add(tDept.ExportTableToSQL(True,True,True,False,True,False,False));

 reSQL.Lines.Add('-- Emp table');
 reSQL.Lines.Add(tEmp.ExportTableToSQL(True,True,True,False,True,False,False));
end;

procedure TForm1.bnExecClick(Sender: TObject);
begin
 tDept.Close;
 tEmp.Close;
 SQLMemQuery1.SQL.Text := reSQL.Text;
 try
  SQLMemQuery1.ExecSQL;
 finally
   tDept.Open;
   tEmp.Open;
   dbgDept.Columns[0].Width := 55;
   dbgDept.Columns[1].Width := 160;

   dbgEmp.Columns[0].Width := 55;
   dbgEmp.Columns[1].Width := 90;
   dbgEmp.Columns[2].Width := 90;
   dbgEmp.Columns[3].Width := 55;
   dbgEmp.Columns[4].Width := 150;
 end;
end;

procedure TForm1.tDeptAfterPost(DataSet: TDataSet);
begin
 tEmp.Refresh;
end;

procedure TForm1.tDeptAfterDelete(DataSet: TDataSet);
begin
 tEmp.Refresh;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 tDept.Close;
 tDept.DeleteConstraint('PK',True);
 tDept.Open;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
 reSQL.Clear;
 reSQL.Lines.Add('-- Dept table');
 reSQL.Lines.Add(tDept.ExportTableToSQL(True,True,True,False,True,False,False));

 reSQL.Lines.Add('-- Emp table');
 reSQL.Lines.Add(tEmp.ExportTableToSQL(True,True,True,False,True,False,False));

end;

end.
