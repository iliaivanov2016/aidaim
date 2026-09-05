unit Unit1;

interface

uses
  Windows, Messages, SysUtils,
  {$IFDEF VER140}
  Variants,
  {$ENDIF}
  Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, DB, ACRMain, ExtCtrls, DBCtrls, Grids, DBGrids, ACRConst;

type
  TfmMain = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    edDBName: TEdit;
    ACRDatabase1: TACRDatabase;
    ACRTable1: TACRTable;
    bnConnect: TButton;
    bnDisconnect: TButton;
    Label2: TLabel;
    edRemoteHost: TEdit;
    Label3: TLabel;
    edRemotePort: TEdit;
    Label4: TLabel;
    edLocalPort: TEdit;
    gbTables: TGroupBox;
    gbRecords: TGroupBox;
    lbTables: TListBox;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    procedure FormCreate(Sender: TObject);
    procedure bnConnectClick(Sender: TObject);
    procedure bnDisconnectClick(Sender: TObject);
    procedure lbTablesClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.FormCreate(Sender: TObject);
begin
 edDBName.Text := ACRDefaultDBName;
 edRemoteHost.Text := ACRDefaultHost;
 edRemotePort.Text := IntToStr(ACRDefaultServerPort);
 edLocalPort.Text := IntToStr(ACRDefaultClientPort);
 bnConnect.Enabled := True;
 bnDisconnect.Enabled := False;
end;

procedure TfmMain.bnConnectClick(Sender: TObject);
begin
 ACRDatabase1.Close;
 ACRDatabase1.ConnectionParams.DatabaseName := edDBName.Text;
 ACRDatabase1.ConnectionParams.RemoteHost := edRemoteHost.Text;
 ACRDatabase1.ConnectionParams.RemotePort := StrToInt(edRemotePort.Text);
 ACRDatabase1.ConnectionParams.LocalPort := StrToInt(edLocalPort.Text);
 try
   ACRDatabase1.Open;
 except
   on e: Exception do
    begin
     MessageDlg('Error connecting to a remote database server: '+#13#10+e.Message,mtError,[mbOK],0);
     ACRDatabase1.Close;
     Exit;
    end;
 end;
 try
   ACRDatabase1.GetTablesList(lbTables.Items);
   gbTables.Caption := ' Available tables: '+IntToStr(lbTables.Items.Count);
 except
   on e: Exception do
    begin
     MessageDlg('Error retrieving tables list: '+#13#10+e.Message,mtError,[mbOK],0);
     ACRDatabase1.Close;
     Exit;
    end;
 end;
 bnConnect.Enabled := False;
 bnDisconnect.Enabled := True;
end;

procedure TfmMain.bnDisconnectClick(Sender: TObject);
begin
 try
   ACRDatabase1.Close;
 except
   on e: Exception do
    begin
     MessageDlg('Error disconnecting from a remote database server: '+#13#10+e.Message,mtError,[mbOK],0);
     Exit;
    end;
 end;
 bnConnect.Enabled := True;
 bnDisconnect.Enabled := False;
 lbTables.Items.Clear;
 gbTables.Caption := ' Available tables: ';
 gbRecords.Caption := ' Record Count: '
end;

procedure TfmMain.lbTablesClick(Sender: TObject);
begin
 if (lbTables.ItemIndex >= 0) then
  begin
   ACRTable1.Close;
   ACRTable1.TableName := lbTables.Items[lbTables.ItemIndex];
   try
     ACRTable1.Open;
   except
   on e: Exception do
    begin
     MessageDlg('Error opening table '''+ACRTable1.TableName+ ''' from a remote database server: '+#13#10+e.Message,mtError,[mbOK],0);
     ACRTable1.Close;
     Exit;
    end;
   end;
   gbRecords.Caption := ' Record Count: '+IntToStr(ACRTable1.RecordCount);
  end;
end;
              
end.
