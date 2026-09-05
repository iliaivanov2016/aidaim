unit uMain;

interface

uses
  Windows, Messages, SysUtils,
//   Variants,
   Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, ACRMain, DB, DBCtrls, Grids,
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
    ACRDatabase1: TACRDatabase;
    ACRDatabase2: TACRDatabase;
    ACRQuery1: TACRQuery;
    ACRTable1: TACRTable;
    ACRTable2: TACRTable;
    ACRQuery2: TACRQuery;
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
    ACRQuery3: TACRQuery;
    Button8: TButton;
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
    procedure ShowTables(db: TACRDatabase);
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.bnExitClick(Sender: TObject);
begin
 Close;
end;

procedure TfmMain.ShowTables(db: TACRDatabase);
var lb: TListBox;
begin
 if (db = ACRDatabase1) then
  lb := lbTables1
 else
  lb := lbTables2;
 lb.Items.Clear;
 if (db = ACRDatabase1) then
  begin
    ACRDatabase1.GetTablesList(lb.Items);
    gbDB1.Caption := ' Database #1: '+IntToStr(lbTables1.Items.Count)+' tables ';
  end
 else
  begin
    ACRDatabase2.GetTablesList(lb.Items);
    gbDB2.Caption := ' Database #2: '+IntToStr(lbTables2.Items.Count)+' tables ';
  end;
end;

procedure TfmMain.Button1Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := 'CREATE DATABASE MEMORY MemDB1;'+#13#10+
                       'CREATE TABLE MEMORY MemDB1.Table1(id AutoInc, name char(20), PRIMARY KEY(id));'+#13#10+
                       'INSERT INTO MEMORY MemDB1.Table1(name) VALUES ("Leo Martin");'+#13#10+
                       'INSERT INTO MEMORY MemDB1.Table1(name) VALUES ("Ray Lahoy");'+#13#10+
                       'CREATE DATABASE MEMORY MemDB2;'+#13#10+
                       'CREATE TABLE MEMORY MemDB2.Table1(id AutoInc, name char(20), PRIMARY KEY(id));'+#13#10+
                       'INSERT INTO MEMORY MemDB2.Table1(name) VALUES ("Ella Perelman");'+#13#10+
                       'INSERT INTO MEMORY MemDB2.Table1(name) VALUES ("John Smith");'+#13#10+
                       'CREATE TABLE MEMORY MemDB2.Table2(id Integer, name char(20), PRIMARY KEY(id,name));'+#13#10
 ;
 reSQL.Text := ACRQuery1.SQL.Text;
 ACRQuery1.ExecSQL();
 ACRDatabase1.InMemory := True;
 ACRDatabase1.DatabaseName := 'MemDB1';
 ACRDatabase1.Open();
 ACRDatabase2.InMemory := True;
 ACRDatabase2.DatabaseName := 'MemDB2';
 ACRDatabase2.Open();
 ACRQuery1.DatabaseName := ACRDatabase1.DatabaseName;
 ACRTable1.DatabaseName := ACRDatabase1.DatabaseName;
 ACRQuery2.DatabaseName := ACRDatabase2.DatabaseName;
 ACRTable2.DatabaseName := ACRDatabase2.DatabaseName;
 Button1.Enabled := False;
 Button2.Enabled := True;
 Button3.Enabled := True;
 Button4.Enabled := True;
 Button5.Enabled := True;
 Button6.Enabled := True;
 Button7.Enabled := True;
 Button8.Enabled := True;
 ShowTables(ACRDatabase1);
 ShowTables(ACRDatabase2);
end;

procedure TfmMain.bnRunSQLClick(Sender: TObject);
begin
 ACRQuery3.SQL.Text := reSQL.Text;
 if (Pos('SELECT',AnsiUpperCase(ACRQuery3.SQL.Text)) > 0) then
  ACRQuery3.Open()
 else
  ACRQuery3.ExecSQL();
 DS1.DataSet := ACRQuery3;
 ShowTables(ACRDatabase1);
 ShowTables(ACRDatabase2);
end;

procedure TfmMain.lbTables1Click(Sender: TObject);
var n: Integer;
begin
 n := lbTables1.ItemIndex;
 if (n >= 0) then
  begin
   if (ACRQuery1.Active) then
    ACRQuery1.Close();
   if (ACRTable1.Active) then
    ACRTable1.Close();
   ACRTable1.TableName := lbTables1.Items[n];
   ACRTable1.Open();
   DS1.DataSet := ACRTable1;
  end;
end;

procedure TfmMain.lbTables2Click(Sender: TObject);
var n: Integer;
begin
 n := lbTables2.ItemIndex;
 if (n >= 0) then
  begin
   if (ACRQuery2.Active) then
    ACRQuery2.Close();
   if (ACRTable2.Active) then
    ACRTable2.Close();
   ACRTable2.TableName := lbTables2.Items[n];
   ACRTable2.Open();
   DS2.DataSet := ACRTable2;
  end;
end;

procedure TfmMain.Button2Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := 'SELECT * FROM MEMORY MemDB1.Table1 ORDER BY name';
 reSQL.Text := ACRQuery1.SQL.Text;
 ACRQuery1.Open();
 if (ACRTable1.Active) then
  ACRTable1.Close();
 DS1.DataSet := ACRQuery1;
end;

procedure TfmMain.Button3Click(Sender: TObject);
begin
 ACRQuery2.SQL.Text := 'SELECT * FROM MEMORY MemDB2.Table1 ORDER BY name DESC';
 reSQL.Text := ACRQuery2.SQL.Text;
 ACRQuery2.Open();
 if (ACRTable2.Active) then
  ACRTable2.Close();
 DS2.DataSet := ACRQuery2;
end;

procedure TfmMain.Button4Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := 'SELECT * INTO MEMORY MemDB2.Table3'
                       +#13#10+'FROM MEMORY MemDB1.Table1 as t11 INNER JOIN '
                       +#13#10+'MEMORY MemDB2.Table1 as t21 ON (t11.id = t21.id)'
                       +#13#10+'ORDER BY 2 DESC, 4 DESC';
 reSQL.Text := ACRQuery1.SQL.Text;
 ACRQuery1.Open();
 if (ACRTable1.Active) then
  ACRTable1.Close();
 DS1.DataSet := ACRQuery1;
 ShowTables(ACRDatabase1);
 ShowTables(ACRDatabase2);
end;

procedure TfmMain.Button8Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := 'INSERT INTO MEMORY MemDB2.Table2 '
                       +#13#10+' SELECT * FROM MEMORY MemDB1.Table1 UNION'
                       +#13#10+' SELECT * FROM MEMORY MemDB2.Table1;'
                       +#13#10+'SELECT * FROM MEMORY MemDB2.Table2'
                       +#13#10+'ORDER BY 2 DESC';
 reSQL.Text := ACRQuery1.SQL.Text;
 ACRQuery1.Open();
 if (ACRTable1.Active) then
  ACRTable1.Close();
 DS1.DataSet := ACRQuery1;
end;

procedure TfmMain.Button5Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := 'UPDATE MEMORY MemDB1.Table1 SET name = name + "!"';
 ACRQuery1.ExecSQL;
 if (ACRTable1.Active) then
  ACRTable1.Close();
 ACRTable1.TableName := 'Table1';
 ACRTable1.Open();
 DS1.DataSet := ACRTable1;
 ACRTable1.Refresh();
end;

procedure TfmMain.Button6Click(Sender: TObject);
begin
 ACRQuery1.SQL.Text := 'DELETE FROM MEMORY MemDB1.Table1';
 ACRQuery1.ExecSQL;
 if (ACRTable1.Active) then
  ACRTable1.Close();
 ACRTable1.TableName := 'Table1';
 ACRTable1.Open();
 DS1.DataSet := ACRTable1;
 ACRTable1.Refresh();
end;

procedure TfmMain.Button7Click(Sender: TObject);
begin
 ACRDatabase1.Close();
 ACRDatabase2.Close();
 ACRQuery1.SQL.Text := 'DROP DATABASE MEMORY MemDB1; DROP DATABASE MEMORY MemDB2;';
 reSQL.Text := ACRQuery1.SQL.Text;
 ACRQuery1.ExecSQL();
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
