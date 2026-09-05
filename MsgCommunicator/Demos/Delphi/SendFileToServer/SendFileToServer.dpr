program SendFileToServer;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'SendFileToServer: MsgCommunicator Demo. (C) 2009 AidAim Software';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
