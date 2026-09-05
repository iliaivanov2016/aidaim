program CustomCommands;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Custom Commands: MsgCommunicator Demo. (c) 2004 - 2005 AidAim Software';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
