unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  EasyTable, Db, StdCtrls, Buttons, DBCtrls, Grids, DBGrids, ExtCtrls;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    EasyTable1: TEasyTable;
    EasyDatabase1: TEasyDatabase;
    DataSource1: TDataSource;
    GroupBox1: TGroupBox;
    Panel1: TPanel;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    Label2: TLabel;
    edPass: TEdit;
    DBNavigator1: TDBNavigator;
    btnCreate: TButton;
    btnOpen: TButton;
    btnSetPwd: TButton;
    btnDecrypt: TButton;
    btnClose: TButton;
    procedure bnCreateClick(Sender: TObject);
    procedure bnOpenClick(Sender: TObject);
    procedure bnSetClick(Sender: TObject);
    procedure btnDecryptClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.bnCreateClick(Sender: TObject);
begin
 EasyTable1.FieldDefs.Clear;
 EasyTable1.FieldDefs.Add('ID',ftAutoInc);
 EasyTable1.FieldDefs.Add('Name',ftString,100);
 EasyTable1.FieldDefs.Add('Surname',ftString,100);
 EasyTable1.FieldDefs.Add('Comments',ftMemo);
 EasyTable1.IndexDefs.Clear;
 EasyTable1.Password := edPass.Text;
 EasyTable1.Encrypted := true;
 EasyTable1.CreateTable;
 EasyTable1.Active := true;
end;

procedure TForm1.bnOpenClick(Sender: TObject);
var pass: string;
    f:		Boolean;
begin
 EasyTable1.Active := false;
 if (not EasyTable1.IsTableEncrypted) then
  begin
   try
    EasyTable1.Active := true;
   except
    EasyTable1.Active := false;
    Exit;
   end;
   Exit;
  end;
 pass := edPass.Text;
 f := false;
 repeat
   if (not InputQuery('Table "'+EasyTable1.TableName+'" authentification','Enter password: ', pass)) then
   		 break;
   EasyTable1.Password := pass;
  try
   EasyTable1.Active := true;
   f := true;
  except
   f := false;
   if (MessageDlg('Invalid password. Do you want to try again?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
    begin
     EasyTable1.Active := false;
     Exit;
    end;
  end;
 until f;
end;

procedure TForm1.bnSetClick(Sender: TObject);
var pass: string;
begin
 bnOpenClick(self);
 if (not EasyTable1.Active) then
  Exit;
 pass := EasyTable1.Password;
 if (InputQuery('Set new password for table "'+EasyTable1.TableName+'" authentification','Enter new password: ', pass)) then
 begin
  try
   EasyTable1.Active := false;
   // disable dbgrid drwaing while restructure table being processed
   EasyTable1.DisableControls;
	 EasyTable1.RestructureTable(true,pass,EasyTable1.BLOBBlockSize,EasyTable1.BLOBCompression);
   EasyTable1.Active := true;
   EasyTable1.EnableControls;
	 MessageDlg('New password was set successfully. Password = "'+pass+'"',
	  mtInformation,[mbOk],0);
  except
	 MessageDlg('Error restructuring table "'+EasyTable1.TableName+'". Origninal table restored.',
	  mtInformation,[mbOk],0);
  end;
 end;
end;

procedure TForm1.btnDecryptClick(Sender: TObject);
begin
 bnOpenClick(self);
 if (not EasyTable1.Active) then
  Exit;
 begin
  try
   EasyTable1.Active := false;
   // disable dbgrid drwaing while restructure table being processed
   EasyTable1.DisableControls;
	 EasyTable1.RestructureTable(false,'',EasyTable1.BLOBBlockSize,EasyTable1.BLOBCompression);
   EasyTable1.Active := true;
   EasyTable1.EnableControls;
	 MessageDlg('Password was removed successfully.', mtInformation,[mbOk],0);
  except
	 MessageDlg('Error restructuring table "'+EasyTable1.TableName+'". Origninal table restored.',
	  mtInformation,[mbOk],0);
  end;
 end;
end;

procedure TForm1.btnCloseClick(Sender: TObject);
begin
 EasyTable1.Active := False;
end;

end.
