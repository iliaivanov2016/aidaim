program mySQLImport;

uses
  Forms,
  uMain in 'uMain.pas' {Form1},
  uConnect in 'uConnect.pas' {ConnectDlg};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TConnectDlg, ConnectDlg);
  Application.Run;
end.
