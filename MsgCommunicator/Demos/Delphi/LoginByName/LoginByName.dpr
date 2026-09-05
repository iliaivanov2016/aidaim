program LoginByName;

uses
  Forms,
  Main in 'Main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'LoginByName: MsgCommunicator Demo. (c) 2007 - 2011 AidAim Software';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
