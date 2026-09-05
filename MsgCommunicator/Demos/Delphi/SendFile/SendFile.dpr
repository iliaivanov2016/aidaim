program SendFile;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'SendFile: MsgCommunicator Demo. (C) 2007-2009 AidAim Software';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
