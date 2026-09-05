unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ACRMain, Db, mySQLDbTables, DBCtrls, Grids, DBGrids, StdCtrls, ExtCtrls,
  Buttons;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    lbField1: TLabel;
    DBMemo1: TDBMemo;
    DBImage1: TDBImage;
    Panel2: TPanel;
    DBLabel2: TDBText;
    Panel4: TPanel;
    Panel5: TPanel;
    ConnectBtn: TBitBtn;
    btnExit: TBitBtn;
    ImportBtn: TBitBtn;
    RadioGroup1: TRadioGroup;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    DataSource1: TDataSource;
    Database1: TmySQLDatabase;
    Table1: TmySQLTable;
    dlgOpen1: TOpenDialog;
    dlgSave1: TSaveDialog;
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    procedure ImportBtnClick(Sender: TObject);
    procedure ConnectBtnClick(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses uConnect;

{$R *.DFM}

procedure TForm1.ImportBtnClick(Sender: TObject);
var
 s: string;
begin
 Table1.DisableControls;
 ACRTable1.DisableControls;

 if (not ACRDatabase1.Exists) then
  ACRDatabase1.CreateDatabase;
 ACRDatabase1.Open;
 ACRTable1.Close;
 s := '';
 ACRTable1.ImportTable(Table1,s);

 if (s = '') then
  ShowMessage('Data imported successfully')
 else
  ShowMessage('Data imported with errors: '+s);

 Table1.EnableControls;
 ACRTable1.EnableControls;
end;

procedure TForm1.ConnectBtnClick(Sender: TObject);
begin
  if (Database1.Connected) then
   begin
     ConnectBtn.Caption := 'Connect';
     Database1.Connected := false;
   end
  else
   if (ShowConnectDlg(Database1)) then
    try
     Database1.Connected := true;
     Screen.Cursor := crSQLWait;
     DataSource1.DataSet.Active := true;
     Screen.Cursor := crDefault;
     ConnectBtn.Caption := 'Disconnect';
    except
     ShowMessage('FishFact connection fault');
    end;
end;

procedure TForm1.RadioGroup1Click(Sender: TObject);
begin
 if (RadioGroup1.ItemIndex = 0) then
  begin
   DataSource1.DataSet := Table1;
   if (Table1.Exists) then
    Table1.Open;
  end
 else
  if (ACRDatabase1.Exists) then
   begin
    ACRDatabase1.Open;
    DataSource1.DataSet := ACRTable1;
    if (ACRTable1.Exists) then
     ACRTable1.Open;
   end;
end;

end.
