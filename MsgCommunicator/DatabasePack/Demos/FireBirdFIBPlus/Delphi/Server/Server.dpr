program Server;

uses
//  ExceptionLog,
  Forms,
  uMain in 'uMain.pas' {fmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Server with MySQL: MsgCommunicator Demo. (c) 2004-2011 AidAim Software';
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
