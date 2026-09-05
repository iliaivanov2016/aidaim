unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Db, ExtCtrls, DBCtrls, Grids, DBGrids, ACRMain;

type
  TForm1 = class(TForm)
    ACRDatabase1: TACRDatabase;
    ACRQuery1: TACRQuery;
    ACRTable1: TACRTable;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DBGrid2: TDBGrid;
    DBNavigator2: TDBNavigator;
    DataSource1: TDataSource;
    DataSource2: TDataSource;
    bnClose: TButton;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    ACRQuery2: TACRQuery;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure bnCloseClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.bnCloseClick(Sender: TObject);
begin
 Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 ACRDatabase1.Close;
 if (not ACRDatabase1.Exists) then
  begin
   ACRDatabase1.CreateDatabase;
   ACRTable1.FieldDefs.Clear;
   ACRTable1.FieldDefs.Add('ID',ftAutoInc,0,False);
   ACRTable1.FieldDefs.Add('Name',ftFixedChar,25,False);
   ACRTable1.IndexDefs.Clear;
   ACRTable1.IndexDefs.Add('idxName','Name',[ixUnique]);
   ACRTable1.CreateTable;
  end;
 ACRDatabase1.Open;
 ACRTable1.Open;
 ACRQuery1.SQL.Text := 'SELECT * FROM '+ACRTable1.TableName;
 ACRQuery1.Open;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  ACRDatabase1.StartTransaction;
  try
    ACRTable1.Insert;
    ACRTable1.FieldByName('Name').AsString := 'aaa_'+
      ACRTable1.FieldByName('ID').AsString;
    ACRTable1.Post;
    ACRTable1.Insert;
    ACRTable1.FieldByName('Name').AsString := 'bbb_'+
      ACRTable1.FieldByName('ID').AsString;
    ACRTable1.Post;
    ACRDatabase1.Commit(True);
    ShowMessage('Transaction committed');
  except
    ACRDatabase1.Rollback;
    ACRTable1.Refresh;
    ShowMessage('Error during the transaction, Rollback called');
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  ACRDatabase1.StartTransaction;
  try
    ACRTable1.Insert;
    ACRTable1.FieldByName('Name').AsString := 'test';
    ACRTable1.Post;
    ACRTable1.Insert;
    ACRTable1.FieldByName('Name').AsString := 'test';
    // this will raise an exception due to violation of the unique index on field Name
    ACRTable1.Post;
    ACRDatabase1.Commit(True);
    ShowMessage('Transaction committed');
  except
    ACRTable1.Cancel;
    ACRDatabase1.Rollback;
    ACRTable1.Refresh;
    ShowMessage('Error during the transaction, Rollback called');
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  ACRQuery1.Close;
  ACRQuery2.SQL.Clear;
  ACRQuery2.SQL.Add('START TRANSACTION;');
  ACRQuery2.SQL.Add('INSERT INTO TEST (NAME) VALUES(''sql_insert1'');');
  ACRQuery2.SQL.Add('INSERT INTO TEST (NAME) VALUES(''sql_insert2'');');
  ACRQuery2.SQL.Add('COMMIT;');
  try
    ACRQuery2.ExecSQL;
    ShowMessage('Transaction committed');
  except
    ACRQuery2.SQL.Text := 'ROLLBACK';
    ACRQuery2.ExecSQL;
    ACRQuery1.Refresh;
    ShowMessage('Error during the transaction, Rollback called');
  end;
  ACRQuery1.Open;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  ACRQuery1.Close;
  ACRQuery2.SQL.Clear;
  ACRQuery2.SQL.Add('START TRANSACTION;');
  ACRQuery2.SQL.Add('INSERT INTO TEST (NAME) VALUES(''sql_insert3'');');
  ACRQuery2.SQL.Add('INSERT INTO TEST (NAME) VALUES(''sql_insert3'');');
  ACRQuery2.SQL.Add('COMMIT;');
  try
    ACRQuery2.ExecSQL;
    ShowMessage('Transaction committed');
  except
    ACRQuery2.SQL.Text := 'ROLLBACK';
    ACRQuery2.ExecSQL;
    ShowMessage('Error during the transaction, Rollback called');
  end;
  ACRQuery1.Open;
end;

end.
