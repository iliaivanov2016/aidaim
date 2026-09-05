program MultipleMessages;

uses
  Forms,
  Main in 'Main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'MsgCommunicator: Multiple Messages Demo. (C) 2010 AidAim Software';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
