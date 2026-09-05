program Server;

uses
  Forms,
  Main in 'Main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Server: MsgCommunicator Demo. (c) 2004 - 2008 AidAim Software';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
