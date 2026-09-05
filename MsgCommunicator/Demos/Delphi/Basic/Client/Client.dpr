program Client;

uses
  Forms,
  Main in 'Main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Client: MsgCommunicator Demo. (c) 2004 - 2011 AidAim Software';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
