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
    DBNavigator1: TDBNavigator;
    btnCreate: TButton;
    btnOpen: TButton;
    btnSetPwd: TButton;
    btnDecrypt: TButton;
    btnClose: TButton;
    lbPass: TLabel;
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
var pass: string;
begin
 EasyDatabase1.Connected := false;
 if (not InputQuery('Database "'+EasyDatabase1.DatabaseName+'" authentification','Enter password for new database: ', pass)) then
	 exit;
 EasyDatabase1.Password := pass;
 EasyDatabase1.CreateDatabase;
 lbPass.Caption := pass;

 EasyTable1.FieldDefs.Clear;
 EasyTable1.FieldDefs.Add('ID',ftAutoInc);
 EasyTable1.FieldDefs.Add('Name',ftString,100);
 EasyTable1.FieldDefs.Add('Surname',ftString,100);
 EasyTable1.FieldDefs.Add('Comments',ftMemo);
 EasyTable1.IndexDefs.Clear;
 EasyTable1.CreateTable;

 EasyTable1.Active := true;
end;

procedure TForm1.bnOpenClick(Sender: TObject);
var pass: string;
    f:		Boolean;
begin
 EasyDatabase1.Connected := false;
 pass := lbPass.Caption;
 f := false;
 if (EasyDatabase1.Encrypted) then
  repeat
   if (not InputQuery('Database "'+EasyDatabase1.DatabaseName+'" authentification','Enter current password: ', pass)) then
   		 break;
   lbPass.Caption := pass;
   EasyDatabase1.Password := pass;
   try
    EasyDatabase1.Connected := true;
    f := true;
   except
    f := false;
    if (MessageDlg('Invalid password. Do you want to try again?',mtConfirmation,[mbYes,mbNo],0) <> mrYes) then
     begin
      EasyDatabase1.Connected := false;
      Exit;
     end;
   end;
  until f
 else
  begin
    EasyDatabase1.Connected := true;
    f := true;
  end;
 EasyTable1.Active := f;
end;

procedure TForm1.bnSetClick(Sender: TObject);
var pass: string;
begin
 if (not EasyDatabase1.Connected) then
  bnOpenClick(self);
 if (not EasyDatabase1.Connected) then
  Exit;
 pass := EasyDatabase1.Password;
 if (InputQuery('Set new password for database "'+EasyDatabase1.DatabaseName+'" authentification','Enter new password: ', pass)) then
 begin
  try
   EasyDatabase1.Connected := false;
	 EasyDatabase1.ChangeEncryption(pass);
   EasyTable1.Active := true;
   lbPass.Caption := EasyDatabase1.Password;
	 MessageDlg('New password was set successfully. Password = "'+pass+'"',
	  mtInformation,[mbOk],0);
  except
	 MessageDlg('Error on changing password "'+EasyDatabase1.DatabaseName+'". Origninal database restored.',
	  mtInformation,[mbOk],0);
  end;
 end;
end;

procedure TForm1.btnDecryptClick(Sender: TObject);
var pass: string;
begin
 if (not EasyDatabase1.Connected) then
  bnOpenClick(self);
 if (not EasyDatabase1.Connected) then
  Exit;
 pass := EasyDatabase1.Password;
 try
   EasyDatabase1.Connected := false;
	 EasyDatabase1.ChangeEncryption('');
   EasyTable1.Active := true;
   lbPass.Caption := EasyDatabase1.Password;
 except
	 MessageDlg('Error on decrypting "'+EasyDatabase1.DatabaseName+'". Origninal database restored.',
	  mtInformation,[mbOk],0);
 end;
end;

procedure TForm1.btnCloseClick(Sender: TObject);
begin
 EasyDatabase1.Connected := False;
end;

end.
