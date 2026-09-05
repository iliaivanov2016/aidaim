unit uConnect;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, mySQLDbTables;

type
  TConnectDlg = class(TForm)
    Bevel1: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    DBUserID: TEdit;
    DBPasswd: TEdit;
    DBName: TEdit;
    DBHost: TEdit;
    DBPort: TEdit;
    OkBtn: TButton;
    CancelBtn: TButton;
  public
    Database: TmySQLDatabase;
  public
    procedure GetDatabaseProperty(Db:TmySQLDatabase);
    procedure SetDatabaseProperty(Db:TmySQLDatabase);
    function Edit: Boolean;
  end;

var
  ConnectDlg: TConnectDlg;

function ShowConnectDlg(Db:TmySQLDatabase):boolean;

implementation

{$R *.DFM}

function ShowConnectDlg(Db:TmySQLDatabase):boolean;
var
 res: boolean;
begin
 ConnectDlg :=  TConnectDlg.Create(Application);
 ConnectDlg.Database := Db;
 res := ConnectDlg.Edit;
 ConnectDlg.Free;
 ShowConnectDlg := res;
end;

function TConnectDlg.Edit: Boolean;
var
 res: boolean;
begin
  GetDatabaseProperty(Database);
  res := false;
  if (ShowModal = mrOk) then
   begin
    SetDatabaseProperty(Database);
    res := true;
   end;
 Edit := res;
end;

procedure TConnectDlg.GetDatabaseProperty(Db:TmySQLDatabase);
begin
  DBName.Text := Db.DatabaseName;
  DBUserID.Text := Db.UserName;
  DBPasswd.Text := Db.UserPassword;
  DBHost.Text := Db.Host;
  DBPort.Text := IntToStr(Db.Port);
end;

procedure TConnectDlg.SetDatabaseProperty(Db:TmySQLDatabase);
begin
  Db.DatabaseName := DBName.Text;
  Db.UserName := DBUserID.Text;
  Db.UserPassword := DBPasswd.Text;
  Db.Host := DBHost.Text;
  Db.Port := StrToInt(DBPort.Text);
end;

end.
