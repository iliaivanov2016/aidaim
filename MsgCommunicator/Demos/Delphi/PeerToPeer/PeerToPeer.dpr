program PeerToPeer;

uses
  Forms,
  Main in 'Main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'PeerToPeer: MsgCommunicator Demo. (c) 2005 AidAim Software';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
