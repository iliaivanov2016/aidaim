unit uMain;

interface

uses
  Windows, Messages, SysUtils,
//   Variants,
   Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, SQLMemMain, DB, DBCtrls, Grids,
  DBGrids;

type
  TfmMain = class(TForm)
    Panel1: TPanel;
    gbDB1: TGroupBox;
    Splitter1: TSplitter;
    gbDB2: TGroupBox;
    Panel2: TPanel;
    reSQL: TRichEdit;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    bnExit: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    lbTables1: TListBox;
    Splitter2: TSplitter;
    DS1: TDataSource;
    DS2: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    lbTables2: TListBox;
    Splitter3: TSplitter;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    bnRunSQL: TButton;
    Button8: TButton;
    SQLMemDatabase1: TSQLMemDatabase;
    SQLMemDatabase2: TSQLMemDatabase;
    SQLMemQuery1: TSQLMemQuery;
    SQLMemTable1: TSQLMemTable;
    SQLMemQuery2: TSQLMemQuery;
    SQLMemTable2: TSQLMemTable;
    SQLMemQuery3: TSQLMemQuery;
    procedure bnExitClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure bnRunSQLClick(Sender: TObject);
    procedure lbTables1Click(Sender: TObject);
    procedure lbTables2Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ShowTables(db: TSQLMemDatabase);
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.bnExitClick(Sender: TObject);
begin
 Close;
end;

procedure TfmMain.ShowTables(db: TSQLMemDatabase);
var lb: TListBox;
begin
 if (db = SQLMemDatabase1) then
  lb := lbTables1
 else
  lb := lbTables2;
 lb.Items.Clear;
 if (db = SQLMemDatabase1) then
  begin
    SQLMemDatabase1.GetTablesList(lb.Items);
    gbDB1.Caption := ' Database #1: '+IntToStr(lbTables1.Items.Count)+' tables ';
  end
 else
  begin
    SQLMemDatabase2.GetTablesList(lb.Items);
    gbDB2.Caption := ' Database #2: '+IntToStr(lbTables2.Items.Count)+' tables ';
  end;
end;

procedure TfmMain.Button1Click(Sender: TObject);
begin
 SQLMemQuery1.SQL.Text := 'CREATE DATABASE MEMORY MemDB1;'+#13#10+
                       'CREATE TABLE MEMORY MemDB1.Table1(id AutoInc, name char(20), PRIMARY KEY(id));'+#13#10+
                       'INSERT INTO MEMORY MemDB1.Table1(name) VALUES ("Leo Martin");'+#13#10+
                       'INSERT INTO MEMORY MemDB1.Table1(name) VALUES ("Ray Lahoy");'+#13#10+
                       'CREATE DATABASE MEMORY MemDB2;'+#13#10+
                       'CREATE TABLE MEMORY MemDB2.Table1(id AutoInc, name char(20), PRIMARY KEY(id));'+#13#10+
                       'INSERT INTO MEMORY MemDB2.Table1(name) VALUES ("Ella Perelman");'+#13#10+
                       'INSERT INTO MEMORY MemDB2.Table1(name) VALUES ("John Smith");'+#13#10+
                       'CREATE TABLE MEMORY MemDB2.Table2(id Integer, name char(20), PRIMARY KEY(id,name));'+#13#10
 ;
 reSQL.Text := SQLMemQuery1.SQL.Text;
 SQLMemQuery1.ExecSQL();
 SQLMemDatabase1.InMemory := True;
 SQLMemDatabase1.DatabaseName := 'MemDB1';
 SQLMemDatabase1.Open();
 SQLMemDatabase2.InMemory := True;
 SQLMemDatabase2.DatabaseName := 'MemDB2';
 SQLMemDatabase2.Open();
 SQLMemQuery1.DatabaseName := SQLMemDatabase1.DatabaseName;
 SQLMemTable1.DatabaseName := SQLMemDatabase1.DatabaseName;
 SQLMemQuery2.DatabaseName := SQLMemDatabase2.DatabaseName;
 SQLMemTable2.DatabaseName := SQLMemDatabase2.DatabaseName;
 Button1.Enabled := False;
 Button2.Enabled := True;
 Button3.Enabled := True;
 Button4.Enabled := True;
 Button5.Enabled := True;
 Button6.Enabled := True;
 Button7.Enabled := True;
 Button8.Enabled := True;
 ShowTables(SQLMemDatabase1);
 ShowTables(SQLMemDatabase2);
end;

procedure TfmMain.bnRunSQLClick(Sender: TObject);
begin
 SQLMemQuery3.SQL.Text := reSQL.Text;
 if (Pos('SELECT',AnsiUpperCase(SQLMemQuery3.SQL.Text)) > 0) then
  SQLMemQuery3.Open()
 else
  SQLMemQuery3.ExecSQL();
 DS1.DataSet := SQLMemQuery3;
 ShowTables(SQLMemDatabase1);
 ShowTables(SQLMemDatabase2);
end;

procedure TfmMain.lbTables1Click(Sender: TObject);
var n: Integer;
begin
 n := lbTables1.ItemIndex;
 if (n >= 0) then
  begin
   if (SQLMemQuery1.Active) then
    SQLMemQuery1.Close();
   if (SQLMemTable1.Active) then
    SQLMemTable1.Close();
   SQLMemTable1.TableName := lbTables1.Items[n];
   SQLMemTable1.Open();
   DS1.DataSet := SQLMemTable1;
  end;
end;

procedure TfmMain.lbTables2Click(Sender: TObject);
var n: Integer;
begin
 n := lbTables2.ItemIndex;
 if (n >= 0) then
  begin
   if (SQLMemQuery2.Active) then
    SQLMemQuery2.Close();
   if (SQLMemTable2.Active) then
    SQLMemTable2.Close();
   SQLMemTable2.TableName := lbTables2.Items[n];
   SQLMemTable2.Open();
   DS2.DataSet := SQLMemTable2;
  end;
end;

procedure TfmMain.Button2Click(Sender: TObject);
begin
 SQLMemQuery1.SQL.Text := 'SELECT * FROM MEMORY MemDB1.Table1 ORDER BY name';
 reSQL.Text := SQLMemQuery1.SQL.Text;
 SQLMemQuery1.Open();
 if (SQLMemTable1.Active) then
  SQLMemTable1.Close();
 DS1.DataSet := SQLMemQuery1;
end;

procedure TfmMain.Button3Click(Sender: TObject);
begin
 SQLMemQuery2.SQL.Text := 'SELECT * FROM MEMORY MemDB2.Table1 ORDER BY name DESC';
 reSQL.Text := SQLMemQuery2.SQL.Text;
 SQLMemQuery2.Open();
 if (SQLMemTable2.Active) then
  SQLMemTable2.Close();
 DS2.DataSet := SQLMemQuery2;
end;

procedure TfmMain.Button4Click(Sender: TObject);
begin
 SQLMemQuery1.SQL.Text := 'SELECT * INTO MEMORY MemDB2.Table3'
                       +#13#10+'FROM MEMORY MemDB1.Table1 as t11 INNER JOIN '
                       +#13#10+'MEMORY MemDB2.Table1 as t21 ON (t11.id = t21.id)'
                       +#13#10+'ORDER BY 2 DESC, 4 DESC';
 reSQL.Text := SQLMemQuery1.SQL.Text;
 SQLMemQuery1.Open();
 if (SQLMemTable1.Active) then
  SQLMemTable1.Close();
 DS1.DataSet := SQLMemQuery1;
 ShowTables(SQLMemDatabase1);
 ShowTables(SQLMemDatabase2);
end;

procedure TfmMain.Button8Click(Sender: TObject);
begin
 SQLMemQuery1.SQL.Text := 'INSERT INTO MEMORY MemDB2.Table2 '
                       +#13#10+' SELECT * FROM MEMORY MemDB1.Table1 UNION'
                       +#13#10+' SELECT * FROM MEMORY MemDB2.Table1;'
                       +#13#10+'SELECT * FROM MEMORY MemDB2.Table2'
                       +#13#10+'ORDER BY 2 DESC';
 reSQL.Text := SQLMemQuery1.SQL.Text;
 SQLMemQuery1.Open();
 if (SQLMemTable1.Active) then
  SQLMemTable1.Close();
 DS1.DataSet := SQLMemQuery1;
end;

procedure TfmMain.Button5Click(Sender: TObject);
begin
 SQLMemQuery1.SQL.Text := 'UPDATE MEMORY MemDB1.Table1 SET name = name + "!"';
 SQLMemQuery1.ExecSQL;
 if (SQLMemTable1.Active) then
  SQLMemTable1.Close();
 SQLMemTable1.TableName := 'Table1';
 SQLMemTable1.Open();
 DS1.DataSet := SQLMemTable1;
 SQLMemTable1.Refresh();
end;

procedure TfmMain.Button6Click(Sender: TObject);
begin
 SQLMemQuery1.SQL.Text := 'DELETE FROM MEMORY MemDB1.Table1';
 SQLMemQuery1.ExecSQL;
 if (SQLMemTable1.Active) then
  SQLMemTable1.Close();
 SQLMemTable1.TableName := 'Table1';
 SQLMemTable1.Open();
 DS1.DataSet := SQLMemTable1;
 SQLMemTable1.Refresh();
end;

procedure TfmMain.Button7Click(Sender: TObject);
begin
 SQLMemDatabase1.Close();
 SQLMemDatabase2.Close();
 SQLMemQuery1.SQL.Text := 'DROP DATABASE MEMORY MemDB1; DROP DATABASE MEMORY MemDB2;';
 reSQL.Text := SQLMemQuery1.SQL.Text;
 SQLMemQuery1.ExecSQL();
 Button1.Enabled := True;
 Button2.Enabled := False;
 Button3.Enabled := False;
 Button4.Enabled := False;
 Button5.Enabled := False;
 Button6.Enabled := False;
 Button7.Enabled := False;
 Button8.Enabled := False;
 lbTables1.Items.Clear;
 lbTables2.Items.Clear;
 gbDB1.Caption := ' Database #1: ';
 gbDB2.Caption := ' Database #2: ';
end;

end.
